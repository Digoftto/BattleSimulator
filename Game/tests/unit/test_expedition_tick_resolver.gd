class_name TestExpeditionTickResolver
extends RefCounted
## TestExpeditionTickResolver (F-020, decisão 9; catch-up: auditoria
## pré-pré-alfa, reverte F-020/decisão 10 por decisão explícita do dono
## do projeto)
##
## ExpeditionTickResolver dispara uma tentativa automática por chamada de
## sync() a cada ~60s efetivamente decorrido, COM catch-up: uma lacuna de
## horas (jogo fechado) processa múltiplas tentativas em sequência —
## nunca apenas 1 — até que Energia se esgote, a Trilha termine, um
## Acampamento passe a aguardar ordem manual, ou o tempo decorrido se
## esgote (o que ocorrer primeiro). Usa relógio injetável (parâmetro
## `now_unix`), nunca espera real.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-020] Validando ExpeditionTickResolver (ritmo automático, sem catch-up)...")

	var kingdom := Kingdom.new()
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	# Sempre vence (Campeão na posição 1) — evita que a Expedição entre
	# em "aguardando Acampamento" e simplifica a contagem de tentativas.
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(1)
	var squad := Squad.new([army])

	var territory := Territory.new("Territorio-Teste-Tick", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 902,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	kingdom.active_expeditions.append(expedition)

	var now: int = 1700000000

	# 1) 1ª sync(): last_tick_unix == 0 -> tenta imediatamente.
	ExpeditionTickResolver.sync(kingdom, now)
	print("  1ª sync() -> tentou imediatamente (Fase avançou)? %s | last_tick_unix atualizado? %s (esperado: true, true)" % [
		str(expedition.current_fase == 2), str(expedition.last_tick_unix == now)
	])
	ctx.check(expedition.current_fase == 2, "A 1ª sync() deve disparar 1 tentativa imediatamente (last_tick_unix == 0)")
	ctx.check(expedition.last_tick_unix == now, "A 1ª sync() deve atualizar last_tick_unix para 'now' (obtido: %d)" % expedition.last_tick_unix)

	# 2) 2ª sync(), 10s depois (< 60s) -> não deve disparar nova tentativa.
	ExpeditionTickResolver.sync(kingdom, now + 10)
	print("  sync() 10s depois -> nenhuma nova tentativa (Fase permanece 2)? %s (esperado: true)" % str(expedition.current_fase == 2))
	ctx.check(expedition.current_fase == 2, "sync() antes de 60s não deve disparar nova tentativa")
	ctx.check(expedition.last_tick_unix == now, "sync() antes de 60s não deve avançar last_tick_unix (obtido: %d, esperado: %d)" % [expedition.last_tick_unix, now])

	# 3) sync() depois de uma lacuna de HORAS -> CATCH-UP: múltiplas
	# tentativas processadas em sequência (nunca apenas 1), até um motivo
	# real de parada já existente no motor (Energia esgotada, Acampamento
	# aguardando ordem, Trilha concluída) ou até o tempo decorrido
	# acabar — o que ocorrer primeiro. Nada aqui INVENTA quantas Fases
	# deveriam ocorrer: o resultado é lido do motor real (PhaseResolver/
	# ExpeditionRuntime), nunca hard-coded a partir de suposição.
	var fase_before_gap: int = expedition.current_fase
	var energy_before_gap: int = army.current_energy
	var much_later: int = now + (6 * 3600)
	ExpeditionTickResolver.sync(kingdom, much_later)

	var fases_advanced: int = expedition.current_fase - fase_before_gap
	var energy_consumed: int = energy_before_gap - army.current_energy
	var stopped_for_real_reason: bool = (
		expedition.status != ExpeditionRuntime.Status.EM_ANDAMENTO
		or expedition.is_waiting_at_acampamento
		or (much_later - expedition.last_tick_unix) < ExpeditionTickResolver.TICK_INTERVAL_SECONDS
	)
	print("  sync() após 6h de lacuna -> Fases avançadas: %d (esperado: > 1, prova de catch-up) | Energia consumida: %d | parou por motivo real (Energia/Acampamento/Trilha/tempo esgotado)? %s" % [
		fases_advanced, energy_consumed, stopped_for_real_reason
	])
	ctx.check(fases_advanced > 1, "Uma lacuna de 6h deve processar MAIS de 1 Fase (catch-up real, não apenas 1 tentativa) — obtido: %d Fase(s)" % fases_advanced)
	ctx.check(energy_consumed > 0, "O catch-up deve consumir Energia real via PhaseResolver (ENERGY_COST_PER_ATTEMPT), nunca sem custo")
	ctx.check(stopped_for_real_reason, "O catch-up deve parar por um motivo real já existente no motor (Energia esgotada, Acampamento aguardando ordem, Trilha concluída) ou por falta de tempo decorrido — nunca continuar indefinidamente nem parar sem motivo")
	ctx.check((expedition.last_tick_unix - now) % ExpeditionTickResolver.TICK_INTERVAL_SECONDS == 0, "last_tick_unix deve avançar em passos exatos de TICK_INTERVAL_SECONDS (nunca pular direto para 'now', perdendo o tempo intermediário) — obtido resto: %d" % ((expedition.last_tick_unix - now) % ExpeditionTickResolver.TICK_INTERVAL_SECONDS))

	# Confirma que uma 2ª sync() no MESMO instante não dispara outra
	# tentativa — prova que não há acúmulo/rajada além do tempo realmente
	# decorrido (idempotência).
	var fase_after_first_catchup: int = expedition.current_fase
	ExpeditionTickResolver.sync(kingdom, much_later)
	print("  2ª sync() no mesmo instante -> nenhuma tentativa extra (Fase permanece %d)? %s (esperado: true)" % [fase_after_first_catchup, expedition.current_fase == fase_after_first_catchup])
	ctx.check(expedition.current_fase == fase_after_first_catchup, "sync() repetida no mesmo instante não deve disparar tentativa extra além do tempo já processado")

	return true
