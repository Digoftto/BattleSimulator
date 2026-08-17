class_name GameRuntime
extends RefCounted
## GameRuntime
##
## O primeiro fluxo real e completo do jogo: Reino (Kingdom) -> Temporada
## (WorldDatabase/Season) -> Território/Trilha -> Expedição -> primeira
## Fase (Combate). Não decide regras nem reimplementa nada — apenas
## conecta, na ordem em que o jogador realmente vive, os agregados e
## serviços já implementados em Sprints anteriores.
##
## GameRuntime é o ponto de entrada; ExpeditionRuntime continua sendo
## quem sabe resolver uma Fase, PhaseResolver quem sabe fazer o retry,
## CombatEngine quem sabe resolver um combate. Nenhuma dessas
## responsabilidades é duplicada aqui.
##
## Escopo desta Sprint: apenas iniciar uma Expedição a partir do Reino e
## da Temporada ativa, e deixá-la pronta para a primeira tentativa de
## Fase. O primeiro Loop de Gameplay completo (incluindo Recrutamento de
## Comandante Regional e sua persistência no Reino) é a Sprint seguinte.
##
## sync() (Sprint "Coordenador de Tempo Real"): ponto único de entrada
## para sincronizar tudo no Reino que depende da passagem de tempo real
## (GameClock). Não decide nenhuma regra nova — apenas chama, na ordem,
## os sistemas que já sabem se sincronizar sozinhos. Cresce por
## composição: cada sistema futuro baseado em tempo real (Minas, Centro
## de Recrutamento, etc.) ganha sua própria chamada aqui somente quando
## a Sprint correspondente for implementada — nunca antes.


## Cria uma nova Expedição no Reino, a partir da Temporada e do
## Território informados, e tenta registrá-la via Kingdom.start_expedition()
## — a única fonte de verdade da validação de Exército travado (ARMY.md,
## "Trava de Edição por Modo de Jogo"); este método nunca duplica essa
## regra, apenas propaga o resultado. Falha explicitamente (assert) se a
## Temporada ou o Território não existirem no WorldDatabase — nunca
## inventa ou improvisa um substituto.
##
## Retorna {"success": bool, "reason": String, "expedition": ExpeditionRuntime}.
## "expedition" é sempre a instância construída, mesmo quando "success"
## é false, para que quem chama possa inspecioná-la se precisar — mas
## nunca fica registrada em kingdom.active_expeditions nesse caso, e a
## Energia dos Exércitos nunca é inicializada (resetada pra cheia)
## quando a Expedição é rejeitada: fazer isso incondicionalmente
## corromperia a Energia de um Exército que já pertence a outra
## Expedição em andamento — por isso a inicialização de Energia só roda
## DEPOIS de o registro ser aceito.
static func start_new_expedition(
	kingdom: Kingdom,
	season_id: String,
	territory_id: String,
	squad: Squad,
	expedition_seed: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> Dictionary:
	var season: Season = WorldDatabase.get_season(season_id)
	assert(season != null, "GameRuntime: Temporada '%s' não registrada em WorldDatabase." % season_id)

	var territory: Territory = season.get_territory(territory_id)
	assert(territory != null, "GameRuntime: Território '%s' não existe na Temporada '%s'." % [territory_id, season_id])

	var trilha: Trilha = season.get_trilha(territory_id)
	assert(trilha != null, "GameRuntime: Trilha do Território '%s' não encontrada." % territory_id)

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, season.enemy_catalog,
		kingdom.regional_commander_registry, expedition_seed,
		battlefields, abilities_by_name, unit_traits
	)

	var result: Dictionary = kingdom.start_expedition(expedition)
	if not result["success"]:
		return {"success": false, "reason": result["reason"], "expedition": expedition}

	# Energia pertence ao Exército, nunca ao Reino (ENERGY.md) — mas sua
	# Energia Máxima depende do nível do Núcleo do Reino, que Army não
	# consulta sozinho. Este é o único ponto que conhece Kingdom e
	# Campanha ao mesmo tempo; a Patente do Comandante já é resolvida
	# internamente por Army (commander_patente()/energy_total()).
	for army: Army in squad.armies:
		army.initialize_energy(kingdom.energy_nucleus_level)

	return {"success": true, "reason": "", "expedition": expedition}


## Sincroniza todos os sistemas do Reino que dependem da passagem do
## tempo real, a partir de "now_unix" (GameClock.now_unix(), fornecido
## por quem chama — GameRuntime nunca lê o relógio sozinho, mesma regra
## de todo o projeto). Deve ser chamado por qualquer tela/fluxo que
## abra o Reino, antes de exibir seu estado — hoje: Painel de
## Recrutamento (purga ofertas expiradas), Exércitos (recuperação de
## Energia), Minas (crédito de produção horária + liberação da
## Guarnição quando o Ciclo termina), Academia (conclusão de tarefas de
## Artífices/Metamorfos), Treinamento (Média Diária de XP, conclusão
## de Ciclos de Treinamento) e Centro de Recrutamento (geração de
## novos Candidatos nos Slots). Idempotente: chamar várias vezes
## seguidas sem tempo adicional não produz efeito colateral extra.
## Threads usadas pelos blocos de fundo da Estimativa de Eficiência
## (MINES.md) — bem menos que o bloco de conquista (que usa mais
## threads de propósito, coberto pela cena de conquista), pra pesar
## pouco na máquina do jogador enquanto ele já está jogando normal.
const BACKGROUND_EFFICIENCY_THREAD_COUNT: int = 2


static func sync(kingdom: Kingdom, now_unix: int) -> void:
	RecruitmentResolver.purge_expired_offers(kingdom, now_unix)

	for army: Army in kingdom.armies:
		# ARMY.md: recalcula a Energia Máxima sempre que a composição
		# muda — inclui Tier de uma carta já dentro do Exército sendo
		# aprimorado na Academia (a mesma CardResource, referência
		# compartilhada). Nunca reseta a Energia atual, só ajusta o
		# teto (ver Army.recalculate_max_energy()). Isso nunca concede
		# Energia de graça (só abaixa o teto se necessário), por isso
		# roda incondicionalmente, mesmo pra um Exército travado abaixo.
		army.recalculate_max_energy(kingdom.energy_nucleus_level)

		# ENERGY.md, "Locais de Recuperação": só recupera na Cidade ou
		# em Acampamentos, nunca durante o avanço idle ativo de uma
		# Expedição nem em combate. Reaproveita o mesmo predicado de
		# is_army_locked_for_editing() (ARMY.md, "Trava de Edição") —
		# nenhum estado novo. Enquanto travado, apenas avança o relógio
		# de sincronização sem conceder pontos: sem isso, o tempo
		# decorrido durante a marcha ficaria acumulado e seria pago de
		# uma vez (retroativamente) assim que o Exército destravasse.
		if kingdom.is_army_locked_for_editing(army)["locked"]:
			army.last_energy_sync_unix = now_unix
		else:
			army.sync_energy_recovery(now_unix, kingdom.energy_nucleus_level)

	for mina: Mina in kingdom.all_mines():
		MiningProductionResolver.credit(mina, kingdom, now_unix)
		# Renovação Automática (MINES.md, "Renovação"): reinicia o Ciclo
		# sozinho enquanto o modo estiver ligado, houver Guarnição e o
		# Ciclo já tiver terminado — em loop, pra recuperar corretamente
		# mesmo que o jogador tenha ficado offline por vários Ciclos
		# seguidos (mesmo padrão de catch-up já usado em outros
		# sistemas baseados em tempo real deste projeto).
		while mina.auto_renew_enabled and mina.guarnicao_army != null \
			and mina.cycle_started_unix != 0 and not mina.is_cycle_active(now_unix):
			mina.start_cycle(now_unix, mina.cycle_efficiency)
			MiningProductionResolver.credit(mina, kingdom, now_unix)
		MineGuarnicaoResolver.release_if_cycle_ended(mina, now_unix)

		# Estimativa Incremental de Eficiência (MINES.md, "Cálculo
		# Incremental por Amostragem"): avança os blocos de fundo — 1
		# thread a menos que o de conquista, de propósito (2 threads),
		# pra pesar pouco na máquina enquanto o jogador já está
		# jogando normal. Nunca dispara um bloco novo em cima de um já
		# em andamento (poll primeiro).
		# DESLIGADO TEMPORARIAMENTE (2026) — o cálculo de Eficiência em
		# segundo plano (WorkerThreadPool) ainda tem um bug de
		# threading não resolvido ("Invalid Task ID"), e por sync()
		# ser chamado por praticamente toda tela do jogo, o problema
		# estava vazando pra lugares sem nenhuma relação com Minas
		# (crash relatado em PvE/Editor de Exército). Reativar só
		# depois de confirmar a correção de verdade — ver conversa
		# registrada sobre paralelização de MiningEfficiencyEstimator.
		# if mina.cycle_started_unix != 0 and not mina.efficiency_permutation_order.is_empty() and not MiningCycleResolver.is_estimation_complete(mina):
		# 	if MiningCycleResolver.poll_pending_block(mina):
		# 		mina.cycle_efficiency = MiningCycleResolver.current_efficiency(mina)
		# 	if mina.efficiency_pending_task_ids.is_empty() and mina.guarnicao_army != null:
		# 		MiningCycleResolver.start_next_block_async(
		# 			mina, mina.guarnicao_army.commander, mina.guarnicao_army.cards, mina.reference_commander,
		# 			GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits,
		# 			BACKGROUND_EFFICIENCY_THREAD_COUNT
		# 		)

	AcademyResolver.sync(kingdom, now_unix)
	CommanderTrainingResolver.sync(kingdom, now_unix)
	RecruitmentCenterResolver.sync(kingdom, now_unix)
