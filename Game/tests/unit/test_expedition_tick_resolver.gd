class_name TestExpeditionTickResolver
extends RefCounted
## TestExpeditionTickResolver (F-020, decisões 9/10)
##
## ExpeditionTickResolver dispara no máximo 1 tentativa automática por
## chamada de sync(), gateada por um intervalo de ~60s, SEM catch-up —
## mesmo após uma lacuna de horas, só 1 tentativa dispara por vez
## (decisão 10: a Expedição fica pausada enquanto o jogo está fechado,
## nunca acumula tentativas).

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

	# 3) sync() depois de uma lacuna de HORAS -> exatamente 1 tentativa
	# nova, nunca uma rajada de várias (decisão 10, sem catch-up).
	var much_later: int = now + (6 * 3600)
	ExpeditionTickResolver.sync(kingdom, much_later)
	print("  sync() após 6h de lacuna -> exatamente 1 tentativa nova (Fase 2 -> 3, nunca mais)? %s | last_tick_unix == much_later? %s (esperado: true, true)" % [
		str(expedition.current_fase == 3), str(expedition.last_tick_unix == much_later)
	])
	ctx.check(expedition.current_fase == 3, "sync() após uma lacuna de horas deve disparar exatamente 1 tentativa nova (obtido: Fase %d)" % expedition.current_fase)
	ctx.check(expedition.last_tick_unix == much_later, "sync() deve atualizar last_tick_unix para o 'now' mais recente, sem processar cada minuto intermediário (obtido: %d)" % expedition.last_tick_unix)

	# Confirma que uma 2ª sync() no MESMO instante não dispara outra
	# tentativa — prova que não há acúmulo/rajada.
	ExpeditionTickResolver.sync(kingdom, much_later)
	print("  2ª sync() no mesmo instante -> nenhuma tentativa extra (Fase permanece 3)? %s (esperado: true)" % str(expedition.current_fase == 3))
	ctx.check(expedition.current_fase == 3, "sync() repetida no mesmo instante não deve disparar tentativa extra")

	return true
