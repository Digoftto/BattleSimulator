class_name TestKingdomGenerateTerritoryMinesViaExpeditionStart
extends RefCounted
## TestKingdomGenerateTerritoryMinesViaExpeditionStart (F-020, decisão 11)
##
## GameRuntime.start_new_expedition() agora chama
## Kingdom.generate_territory_mines() de verdade (antes só testes
## chamavam, confirmado por auditoria anterior) — confirma que 5 Minas
## Regionais são geradas ao iniciar uma Expedição, e que uma segunda
## Expedição no MESMO Território nunca regenera/reseeda (idempotente
## por territory_id, mesmo com um seed diferente).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-020] Validando geração real de Minas Regionais ao iniciar Expedição...")

	var season_id: String = "Season-Teste-Minas-Expedicao"
	var territory := Territory.new("Territorio-Minas-Expedicao", "Império")
	var trilha := Trilha.new(territory.id)
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var season := Season.new(season_id)
	season.add_territory(territory, trilha)
	season.enemy_catalog = catalog
	WorldDatabase.register_season(season)

	var kingdom := Kingdom.new()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(1)
	kingdom.armies.append(army)
	var squad := Squad.new([army])

	ctx.check(not kingdom.territory_mines.has(territory.id), "Pré-condição: territory_mines não deve ter nada para este Território ainda")

	var result: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season_id, territory.id, squad, 904,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	ctx.check(result["success"], "Pré-condição do teste: início da Expedição deve ter sucesso (motivo: '%s')" % result["reason"])

	var mines_after: Array[Mina] = kingdom.territory_mines.get(territory.id, [])
	print("  Ao iniciar a Expedição -> kingdom.territory_mines[territory_id] tem 5 Minas geradas? %s (%d, esperado: 5)" % [
		str(mines_after.size() == 5), mines_after.size()
	])
	ctx.check(mines_after.size() == 5, "Iniciar uma Expedição deve gerar exatamente 5 Minas Regionais para o Território (obtido: %d)" % mines_after.size())

	var first_mine_adjacent_fase: int = mines_after[0].adjacent_fase

	# 2ª Expedição no MESMO Território (2º Exército, sem travar o 1º),
	# com seed DIFERENTE de propósito — nunca deve regenerar/reseedar as
	# Minas já existentes.
	var army_2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_2.initialize_energy(1)
	kingdom.armies.append(army_2)
	var squad_2 := Squad.new([army_2])
	GameRuntime.start_new_expedition(
		kingdom, season_id, territory.id, squad_2, 999999,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	var mines_after_second: Array[Mina] = kingdom.territory_mines.get(territory.id, [])
	print("  2ª Expedição no mesmo Território (seed diferente) -> Minas permanecem as mesmas (nunca regeneradas)? %s | mesma 1ª Fase adjacente (%d -> %d)? %s (esperado: true, true)" % [
		str(mines_after_second.size() == 5), first_mine_adjacent_fase, mines_after_second[0].adjacent_fase, str(mines_after_second[0].adjacent_fase == first_mine_adjacent_fase)
	])
	ctx.check(mines_after_second.size() == 5, "Uma 2ª Expedição no mesmo Território não pode duplicar/alterar a quantidade de Minas")
	ctx.check(mines_after_second[0].adjacent_fase == first_mine_adjacent_fase, "Uma 2ª Expedição (com seed diferente) nunca deve regenerar/reseedar Minas já existentes (idempotente por territory_id)")

	return true
