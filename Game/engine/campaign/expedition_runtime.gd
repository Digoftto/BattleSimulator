class_name ExpeditionRuntime
extends RefCounted
## ExpeditionRuntime
##
## Controla uma Expedição ativa (PvE.md): mantém a Fase atual, o último
## Acampamento e o Squad. A partir da Sprint 32, resolve sozinho quem é
## o Exército inimigo de cada Fase — consultando Trilha (tipo de Fase,
## Região), Territory (Facção) e SeasonCatalog/EnemyArmySelector
## (Exército concreto) — sem que quem chama attempt_current_fase()
## precise saber quem é o inimigo. Não contém nenhuma lógica de
## Combate — delega inteiramente a PhaseResolver.

enum Status { EM_ANDAMENTO, CONCLUIDA, ENCERRADA }

## preload() por caminho (nunca o identificador global "BattleReplayRecord"
## direto) — mesmo motivo já documentado em comandantes_panel.gd: um
## class_name recém-criado só entra no cache global de classes do Godot
## depois de o projeto ser reaberto/rescaneado pelo Editor, o que nunca
## acontece numa execução --headless.
const BattleReplayRecordScript = preload("res://engine/combat/battle_replay_record.gd")

## Política de Acampamento (PvE.md, "Política de Acampamento") —
## configurada previamente pelo jogador, define o comportamento da
## Expedição ao alcançar um Acampamento.
enum AcampamentoPolicy {
	AGUARDAR_ORDEM,               # a marcha para até decisão manual do jogador
	SEGUIR_AUTOMATICO,             # continua imediatamente, independente da Energia
	AGUARDAR_RECUPERACAO_TOTAL,    # sempre recupera 100% da Energia antes de continuar
	AGUARDAR_LIMITE,               # continua se acima do limite; senão, recupera 100%
}

var squad: Squad
var trilha: Trilha
var territory: Territory
var season_catalog: SeasonCatalog
var regional_commander_registry: RegionalCommanderRegistry
var expedition_seed: int

var current_fase: int = 1
var last_acampamento_fase: int = 1
var status: Status = Status.EM_ANDAMENTO

## Política de Acampamento ativa e, quando aplicável (AGUARDAR_LIMITE),
## o limite percentual configurado pelo jogador (0.0 a 1.0).
var acampamento_policy: AcampamentoPolicy = AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL
var energy_recovery_threshold_percent: float = 0.4

## True quando a Expedição está parada em um Acampamento por qualquer
## motivo (ver CampState abaixo) — nunca avança sozinha enquanto true.
var is_waiting_at_acampamento: bool = false

## Estado da decisão no Acampamento atual (auditoria pré-pré-alfa,
## decisão explícita do dono do projeto: a escolha Continuar/Parar
## acontece de novo em CADA Acampamento — nunca uma configuração
## permanente da Expedição; AcampamentoPolicy acima permanece intacta
## e testada isoladamente, mas o jogo real não a consulta mais — ver
## establish_acampamento_and_await_decision() abaixo).
##
## NONE: não está aguardando nada no momento.
## AWAITING_DECISION: chegada normal a um Acampamento — aguarda o
##   jogador escolher CONTINUAR (segue com a Energia atual, nunca a
##   recupera) ou PARAR (passa a RESTING_UNTIL_FULL). Nunca se resolve
##   sozinho, não importa quanta Energia o Squad já tenha.
## RESTING_UNTIL_FULL: jogador escolheu PARAR — aguarda Energia real
##   (Army.sync_energy_recovery(), nunca uma fórmula nova) atingir o
##   máximo em TODOS os Exércitos do Squad; sem opção de mudar de ideia
##   antes disso (PvE.md, "Decisão Estratégica no Acampamento": "não
##   continua enquanto Energia < Energia máxima").
## FORCED_UNTIL_FULL: parada obrigatória após o Squad inteiro ser
##   incapacitado (PhaseResult.DefeatReason.COMBAT_LOSS ou
##   ENERGY_EXHAUSTED, PvE.md §"Hierarquia de Substituição") — nunca
##   apresenta escolha, mesmo comportamento de espera de
##   RESTING_UNTIL_FULL.
##
## Ambos RESTING_UNTIL_FULL e FORCED_UNTIL_FULL são liberados
## automaticamente assim que o Squad estiver plenamente recuperado —
## ver ExpeditionTickResolver/try_release_camp_wait_if_fully_rested().
enum CampState { NONE, AWAITING_DECISION, RESTING_UNTIL_FULL, FORCED_UNTIL_FULL }
var camp_state: CampState = CampState.NONE

var _battlefields: Array[BattlefieldResource]
var _abilities_by_name: Dictionary
var _unit_traits: Array[UnitTraitResource]

## Registro textual estrutural (mesma convenção de CombatState.battle_log).
var history_log: Array[String] = []

## Instante Unix da última tentativa automática desta Expedição (F-020,
## Ritmo da Expedição). 0 = nunca tentou automaticamente ainda — a
## primeira sincronização tenta imediatamente. Lido/escrito
## exclusivamente por ExpeditionTickResolver.sync().
var last_tick_unix: int = 0

## Histórico persistente por Fase (F-020, Parte 5/14; F-021 acrescenta
## formação real): Fase (int) -> {"enemy_id", "enemy_name",
## "enemy_faction", "commander_name", "category", "victory",
## "defeat_reason", "attempts", "enemy_commander_faction",
## "enemy_formation_card_names" (Array[String], 9 posições, "" onde
## vazio), "player_army_name", "player_formation_name",
## "player_formation_card_names" (Array[String], 9 posições — só
## presente em vitória, já que só há uma única Formação vencedora por
## Tentativa)}. Dado extraído e plano — nomes de carta (String), nunca
## referências a CardResource/EnemyArmyEntry/PhaseResult — sobrevive a
## save/load e permite reconstruir a UI (hover sobre Fase já disputada,
## incluindo a composição real de quem lutou) sem depender do log
## textual. Sobrescrito a cada nova tentativa da mesma Fase (sempre
## reflete o resultado mais recente).
var fase_history: Dictionary = {}


func _init(
	p_squad: Squad,
	p_trilha: Trilha,
	p_territory: Territory,
	p_season_catalog: SeasonCatalog,
	p_regional_commander_registry: RegionalCommanderRegistry,
	p_expedition_seed: int,
	p_battlefields: Array[BattlefieldResource],
	p_abilities_by_name: Dictionary,
	p_unit_traits: Array[UnitTraitResource]
) -> void:
	squad = p_squad
	trilha = p_trilha
	territory = p_territory
	season_catalog = p_season_catalog
	regional_commander_registry = p_regional_commander_registry
	expedition_seed = p_expedition_seed
	_battlefields = p_battlefields
	_abilities_by_name = p_abilities_by_name
	_unit_traits = p_unit_traits
	history_log.append("Expedição iniciada. Fase 1 de %d. Território: %s (%s)." % [
		trilha.total_fases(), territory.id, territory.faction
	])


## Tipo da Fase atual: "regional", "normal" ou "comum". Já reflete a
## Prioridade entre Chefes definida em PvE.md (Trilha.chefe_type).
func current_fase_type() -> String:
	var chefe: String = trilha.chefe_type(current_fase)
	if chefe != "":
		return chefe
	return "comum"


## True se a Fase atual é um Acampamento oficial (já gerado pela Trilha,
## respeitando prioridade e reinício de contagem).
func current_fase_is_acampamento() -> bool:
	return trilha.is_acampamento(current_fase)


## Resolve automaticamente o Exército inimigo da Fase atual (via
## Trilha + Territory + EnemyArmySelector/SeasonCatalog) e tenta a
## Fase. Estabelece Acampamento automaticamente quando a Fase
## conquistada for uma; avança para a próxima Fase em caso de vitória;
## retorna ao último Acampamento em caso de derrota total do Squad.
## Retorna o PhaseResult da tentativa, ou null se: a Expedição não
## estiver em andamento; estiver aguardando ordem no Acampamento; a Fase
## atual for um Acampamento comum resolvido sem combate (decisão 8); ou
## não houver Exército compatível no Catálogo.
func attempt_current_fase() -> PhaseResult:
	if status != Status.EM_ANDAMENTO:
		return null

	if is_waiting_at_acampamento:
		history_log.append("Expedição aguardando ordem do jogador no Acampamento (Fase %d) — nenhuma tentativa realizada." % current_fase)
		return null

	# F-020, decisão 8: Acampamento comum é parada pura — não exige
	# combate para se estabelecer. Um Acampamento que coincide com um
	# Chefe Regional (chefe_type != "") NUNCA cai aqui: continua exigindo
	# a vitória do Chefe, e estabelecer o Acampamento ali é efeito
	# colateral dessa vitória (was_acampamento ->
	# establish_acampamento_and_await_decision(), abaixo).
	if current_fase_is_acampamento() and trilha.chefe_type(current_fase) == "":
		return _arrive_at_camp_without_combat()

	var category: EnemyArmyEntry.Category = _entry_category_for_current_fase()
	var region: int = trilha.region_for_fase(current_fase)

	var entry: EnemyArmyEntry = EnemyArmySelector.select(
		season_catalog, territory.faction, category, region,
		current_fase, expedition_seed, regional_commander_registry
	)

	if entry == null:
		history_log.append("Fase %d: nenhum Exército inimigo compatível no Catálogo (Facção %s, Categoria %s, Região %d)." % [
			current_fase, territory.faction, EnemyArmyEntry.Category.keys()[category], region
		])
		return null

	var result: PhaseResult = PhaseResolver.resolve(
		squad, entry, _battlefields, _abilities_by_name, _unit_traits, "PvE — Fase %d (%s)" % [current_fase, territory.id], "pve"
	)

	_record_fase_history(current_fase, entry, result)

	if result.victory:
		var fase_type: String = current_fase_type()
		var was_acampamento: bool = current_fase_is_acampamento()
		var kingdom: Kingdom = KingdomState.kingdom

		# RESOURCES.md §4 / RewardResolver: credita Fragmentos de
		# verdade ao Reino por cada Pelotão Original inimigo destruído
		# na Fase vencida — RewardResolver já existia, testado,
		# correto, mas nunca era chamado fora dos meus testes.
		var fragments_earned: int = RewardResolver.resolve(result, kingdom, SeasonConfig.new())

		# FORMULAS.md ("XP da Conta") / AccountXPResolver: nenhuma das
		# duas nunca era chamada fora dos meus testes — vitória de PvE
		# nunca dava XP de Conta de verdade.
		if fase_type == "comum":
			AccountXPResolver.grant_pve_fase_comum(kingdom)
		else:
			AccountXPResolver.grant_pve_chefe(kingdom)

		# XP.md / CommanderCareer.xp_for_pve_victory() +
		# CommanderTrainingResolver.record_combat_xp(): o próprio
		# comentário do resolver já avisava que isso nunca tinha sido
		# ligado dentro de ExpeditionRuntime.
		var winning_army: Army = squad.armies[result.winning_army_index]
		if winning_army.commander != null:
			CommanderTrainingResolver.record_combat_xp(
				kingdom, winning_army.commander, CommanderCareer.xp_for_pve_victory(), GameClock.now_unix()
			)

		if fragments_earned > 0:
			var breakdown_parts: Array[String] = []
			for faction: String in result.enemy_pelotoes_destroyed_by_faction:
				breakdown_parts.append("%d de %s" % [result.enemy_pelotoes_destroyed_by_faction[faction], faction])
			history_log.append("Fase %d (%s) vencida contra %s (Exército %d, Formação %s, %d tentativa(s)) — %d Fragmentos creditados (%s Pelotões destruídos)." % [
				current_fase, fase_type, entry.id, result.winning_army_index + 1, result.winning_formation, result.attempts, fragments_earned, ", ".join(breakdown_parts)
			])
		else:
			history_log.append("Fase %d (%s) vencida contra %s (Exército %d, Formação %s, %d tentativa(s))." % [
				current_fase, fase_type, entry.id, result.winning_army_index + 1, result.winning_formation, result.attempts
			])

		if was_acampamento:
			establish_acampamento_and_await_decision()

		current_fase += 1
		if current_fase > trilha.total_fases():
			status = Status.CONCLUIDA
			history_log.append("Trilha concluída na Fase %d." % (current_fase - 1))
	else:
		history_log.append("Fase %d não conquistada contra %s (%d tentativas) — retornando ao Acampamento (Fase %d)." % [
			current_fase, entry.id, result.attempts, last_acampamento_fase
		])
		current_fase = last_acampamento_fase
		# Bug real relatado: sem isso, o Exército ficava "travado" (Em
		# Expedição, sem editar nem recuperar Energia) mesmo já tendo
		# "voltado" pro Acampamento (ou Cidade, se nenhum Acampamento
		# real tivesse sido alcançado ainda — last_acampamento_fase
		# começa em 1, equivalente à Cidade). Kingdom.is_army_locked_for_editing()
		# e o recálculo de Energia (Army.sync_energy_recovery) dependem
		# desta flag pra saber que o Exército está seguro.
		is_waiting_at_acampamento = true
		# Auditoria pré-pré-alfa: parada OBRIGATÓRIA (Squad inteiro
		# incapacitado — derrota em combate OU Energia esgotada, PvE.md
		# §"Hierarquia de Substituição") nunca apresenta a escolha
		# Continuar/Parar — só a espera por Energia plena.
		camp_state = CampState.FORCED_UNTIL_FULL
		# Nenhum estado de "Formação esgotada" persiste entre Tentativas de
		# Fase (PhaseResolver.resolve sempre reinicia o Squad do zero) —
		# a restauração de todas as Formações já ocorre naturalmente.

	return result


## Estabelece um Acampamento comum (não coincidente com Chefe Regional)
## sem exigir combate — F-020, decisão 8. Espelha deliberadamente o
## idioma já usado no ramo de vitória logo acima
## (establish_acampamento_and_await_decision() seguido de incremento
## incondicional de current_fase), para que resume_from_acampamento()
## nunca reencontre esta mesma Fase depois de "Continuar" (current_fase
## já avançou antes do jogador ver a parada).
func _arrive_at_camp_without_combat() -> PhaseResult:
	history_log.append("Fase %d: Acampamento — estabelecido sem combate." % current_fase)
	establish_acampamento_and_await_decision()
	current_fase += 1
	if current_fase > trilha.total_fases():
		status = Status.CONCLUIDA
		history_log.append("Trilha concluída na Fase %d." % (current_fase - 1))
	return null


## Grava um registro plano (nunca referências a objetos) do resultado
## desta tentativa em fase_history, para vitória E derrota — F-020,
## Parte 5/14 (hover sobre Fase já disputada). F-021: também captura a
## composição real das duas Formações no INSTANTE da vitória (nomes de
## carta, nunca referência) — squad.armies[i].get_formation() é mutável
## depois (o jogador pode reeditar a Formação no Acampamento), então
## precisa ser fotografado agora, não recalculado depois. Sobrescreve
## qualquer registro anterior da mesma Fase.
##
## Auditoria pré-pré-alfa (item #17): também persiste o REPLAY real
## desta tentativa (BattleReplayRecord, Kingdom.record_battle_replay())
## — vitória e derrota igualmente, nunca filtrado por result.victory.
## Usa result.battle_replays[-1] (a ÚLTIMA tentativa de Formação real
## desta resolução — a que efetivamente decidiu a Fase, vitória ou
## esgotamento do Squad) como o replay representativo; nunca re-simula
## nada, só embrulha o {"state","collector"} que PhaseResolver já
## produziu de verdade. RESULTADO (victory/defeat_reason, já gravado
## acima) e REPLAY (o que aconteceu) são dados distintos, gravados
## juntos aqui mas nunca fundidos: fase_history[fase] só GANHA um
## "replay_id" apontando pro registro real em kingdom.battle_replays,
## nunca duplica o conteúdo do replay dentro de fase_history.
func _record_fase_history(fase: int, entry: EnemyArmyEntry, result: PhaseResult) -> void:
	var data: Dictionary = {
		"enemy_id": entry.id,
		"enemy_name": entry.army_name,
		"enemy_faction": entry.faction,
		"commander_name": entry.commander.commander_name if entry.commander != null else "",
		"enemy_commander_faction": entry.commander.faction if entry.commander != null else "",
		"category": EnemyArmyEntry.Category.keys()[entry.category],
		"victory": result.victory,
		"defeat_reason": PhaseResult.DefeatReason.keys()[result.defeat_reason],
		"attempts": result.attempts,
		"enemy_formation_card_names": _card_names_for(entry.cards),
	}

	if result.victory:
		var winning_army: Army = squad.armies[result.winning_army_index]
		data["player_army_name"] = winning_army.army_name
		data["player_formation_name"] = result.winning_formation
		data["player_formation_card_names"] = _card_names_for(winning_army.get_formation(result.winning_formation))

	# Sem nenhuma tentativa real (ex: todas as Formações bloqueadas pela
	# Doutrina do Comandante antes de qualquer combate) — nada a
	# reproduzir, nunca inventa um replay vazio.
	if not result.battle_replays.is_empty():
		var kingdom: Kingdom = KingdomState.kingdom
		var replay_id: String = kingdom.generate_replay_id()
		var metadata: Dictionary = {
			"replay_id": replay_id,
			"fase": fase,
			"territory_id": territory.id,
			"victory": result.victory,
			"created_unix": GameClock.now_unix(),
			"player_side": 0,  # PvE: attempt_army sempre é side 0 em CombatEngine.initialize() (PhaseResolver.resolve()).
		}
		var record: Dictionary = BattleReplayRecordScript.to_persistable_dict(result.battle_replays[-1], metadata)
		kingdom.record_battle_replay(record)
		data["replay_id"] = replay_id

	fase_history[fase] = data


## Nomes reais das cartas de uma Formação, na mesma ordem posicional
## (índice 0 = Posição 1 .. índice 8 = Posição 9, COMBAT_RULES.md) —
## "" para uma posição sem carta (nunca inventado).
func _card_names_for(cards: Array[CardResource]) -> Array[String]:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name if card != null else "")
	return names


## Categoria de Exército Inimigo correspondente ao tipo da Fase atual
## (Prioridade entre Chefes já resolvida por Trilha.chefe_type).
func _entry_category_for_current_fase() -> EnemyArmyEntry.Category:
	match trilha.chefe_type(current_fase):
		"regional":
			return EnemyArmyEntry.Category.CHEFE_REGIONAL
		"normal":
			return EnemyArmyEntry.Category.CHEFE_NORMAL
		_:
			return EnemyArmyEntry.Category.NORMAL


## Estabelece a Fase atual como um novo Acampamento (checkpoint
## permanente) e aplica a Política de Acampamento configurada.
##
## MECANISMO ANTIGO (F-020), preservado intacto e ainda testado
## isoladamente por test_acampamento_policies.gd — desde a auditoria
## pré-pré-alfa (decisão explícita do dono do projeto: a escolha deixou
## de ser uma configuração feita uma vez para toda a Expedição e passou
## a ser uma decisão real repetida em CADA Acampamento, ver CampState),
## nenhum fluxo real de jogo chama mais este método diretamente — os 2
## pontos reais de chegada a um Acampamento (attempt_current_fase(),
## _arrive_at_camp_without_combat()) chamam
## establish_acampamento_and_await_decision() abaixo. Nada foi deletado
## para não quebrar o teste existente; a Política simplesmente não é
## mais consultada pelo jogo real.
func establish_acampamento() -> void:
	last_acampamento_fase = current_fase
	history_log.append("Acampamento estabelecido na Fase %d." % current_fase)
	_apply_acampamento_policy()


## Estabelece a Fase atual como um novo Acampamento (checkpoint
## permanente) — SEMPRE aguarda uma decisão real do jogador
## (AWAITING_DECISION), nunca resolve sozinho (auditoria pré-pré-alfa,
## decisão explícita do dono do projeto: PvE.md, "Decisão Estratégica
## no Acampamento" — "Ao atingir... um Acampamento, o jogador pode:
## Continuar Imediatamente... ou Permanecer em Repouso"). Chamado pelos
## 2 pontos reais de chegada a um Acampamento, no lugar de
## establish_acampamento() (preservado acima, intocado, só para
## test_acampamento_policies.gd).
func establish_acampamento_and_await_decision() -> void:
	last_acampamento_fase = current_fase
	history_log.append("Acampamento estabelecido na Fase %d." % current_fase)
	is_waiting_at_acampamento = true
	camp_state = CampState.AWAITING_DECISION
	history_log.append("Aguardando decisão do jogador: Continuar ou Parar.")


func _apply_acampamento_policy() -> void:
	match acampamento_policy:
		AcampamentoPolicy.SEGUIR_AUTOMATICO:
			history_log.append("Política 'Seguir Automaticamente' — a marcha continua sem recuperar Energia.")

		AcampamentoPolicy.AGUARDAR_ORDEM:
			is_waiting_at_acampamento = true
			history_log.append("Política 'Aguardar Ordem' — Expedição parada até decisão manual do jogador.")

		AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL:
			_recover_squad_energy()
			history_log.append("Política 'Aguardar Recuperação Total' — todos os Exércitos do Squad recuperaram 100%% de Energia.")

		AcampamentoPolicy.AGUARDAR_LIMITE:
			if _squad_all_above_threshold(energy_recovery_threshold_percent):
				history_log.append("Política 'Aguardar Limite' — Energia acima do limite configurado (%d%%); a marcha continua sem recuperar." % int(energy_recovery_threshold_percent * 100))
			else:
				_recover_squad_energy()
				history_log.append("Política 'Aguardar Limite' — Energia abaixo do limite configurado (%d%%); recuperação total realizada." % int(energy_recovery_threshold_percent * 100))


## Ordem manual do jogador para continuar a partir de um Acampamento
## onde a Expedição estava parada (política AGUARDAR_ORDEM, mecanismo
## ANTIGO — ver nota em establish_acampamento()). Preservado intacto e
## ainda testado isoladamente por test_acampamento_policies.gd; o jogo
## real não chama mais este método — usa choose_continue_immediately()
## abaixo. Recupera a Energia do Squad antes de liberar a marcha — o
## repouso que justificava a espera já aconteceu.
func resume_from_acampamento() -> void:
	if not is_waiting_at_acampamento:
		return
	_recover_squad_energy()
	is_waiting_at_acampamento = false
	history_log.append("Jogador ordenou a continuação a partir do Acampamento (Fase %d) — Energia recuperada." % current_fase)


## Decisão do jogador de CONTINUAR imediatamente a partir de um
## Acampamento (auditoria pré-pré-alfa) — só válida a partir de
## AWAITING_DECISION, nunca de RESTING_UNTIL_FULL/FORCED_UNTIL_FULL
## (essas exigem Energia plena antes de qualquer avanço, sem opção de
## ignorar a espera). NUNCA recupera Energia — "utiliza a Energia
## disponível naquele momento; não espera chegar a 100%" — segue com o
## valor atual, seja ele qual for. Chamado pelo fluxo real do jogo, no
## lugar de resume_from_acampamento() (preservado acima, intocado, só
## para test_acampamento_policies.gd).
func choose_continue_immediately() -> void:
	if camp_state != CampState.AWAITING_DECISION:
		return
	is_waiting_at_acampamento = false
	camp_state = CampState.NONE
	history_log.append("Jogador escolheu Continuar a partir do Acampamento (Fase %d) — Energia mantida no valor atual (sem recuperação instantânea)." % current_fase)


## Decisão do jogador de PARAR e permanecer em repouso (auditoria
## pré-pré-alfa) — só válida a partir de AWAITING_DECISION. Nunca
## recupera Energia diretamente: apenas transiciona para
## RESTING_UNTIL_FULL, onde a recuperação real e contínua já acontece
## sozinha (Kingdom.is_army_locked_for_editing() já desbloqueia o
## Exército para Army.sync_energy_recovery() enquanto
## is_waiting_at_acampamento for true — nenhuma lógica nova); a marcha
## só é liberada de volta quando o Squad atingir Energia plena, nunca
## por uma 2ª chamada a este método.
func choose_stop_and_rest() -> void:
	if camp_state != CampState.AWAITING_DECISION:
		return
	camp_state = CampState.RESTING_UNTIL_FULL
	history_log.append("Jogador escolheu Parar e permanecer em repouso no Acampamento (Fase %d) até Energia plena." % current_fase)


## Chamado a cada ExpeditionTickResolver.sync(), independente do
## intervalo de 60s entre tentativas de Fase (checar Energia não é uma
## "tentativa") — libera RESTING_UNTIL_FULL/FORCED_UNTIL_FULL
## automaticamente assim que TODOS os Exércitos do Squad atingirem
## Energia máxima, usando a MESMA recuperação real por tempo decorrido
## já existente (Army.sync_energy_recovery(), nunca uma fórmula nova).
## AWAITING_DECISION nunca é afetado (guardado abaixo) — só uma ação
## explícita do jogador (resume_from_acampamento()/choose_stop_and_rest())
## sai desse estado, não importa quanta Energia haja.
## Retorna true se a marcha foi liberada agora nesta chamada — quem
## chama pode então tentar a próxima Fase na mesma passagem de sync(),
## sem esperar a chamada seguinte.
func try_release_camp_wait_if_fully_rested(now_unix: int, energy_nucleus_level: int) -> bool:
	if camp_state != CampState.RESTING_UNTIL_FULL and camp_state != CampState.FORCED_UNTIL_FULL:
		return false

	for army: Army in squad.armies:
		army.sync_energy_recovery(now_unix, energy_nucleus_level)

	if not _squad_all_above_threshold(1.0):
		return false

	history_log.append("Energia plena recuperada no Acampamento (Fase %d) — marcha liberada automaticamente." % current_fase)
	is_waiting_at_acampamento = false
	camp_state = CampState.NONE
	return true


func _recover_squad_energy() -> void:
	for army: Army in squad.armies:
		army.recover_energy_full()


## True se todos os Exércitos do Squad estão com Energia acima (ou
## igual) ao limite percentual informado (0.0 a 1.0).
func _squad_all_above_threshold(threshold_percent: float) -> bool:
	for army: Army in squad.armies:
		if army.max_energy <= 0:
			continue
		var ratio: float = float(army.current_energy) / float(army.max_energy)
		if ratio < threshold_percent:
			return false
	return true


## Encerra a Expedição por decisão do jogador (uma das 4 formas de
## encerramento previstas em PvE.md).
func end_expedition() -> void:
	status = Status.ENCERRADA
	history_log.append("Expedição encerrada por decisão do jogador na Fase %d." % current_fase)
