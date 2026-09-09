class_name TestFaseHistoryFormationData
extends RefCounted
## TestFaseHistoryFormationData (F-021, itens 9/10 do pedido)
##
## fase_history agora persiste a composição real das duas Formações no
## instante da vitória — nomes de carta reais (nunca inventados), nunca
## presentes numa derrota (não existe "Formação vencedora" nesse caso).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021] Validando dados de Formação em fase_history...")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.army_name = "Exército Teste Formação"
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var territory := Territory.new("Territorio-Teste-Formacao", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 950,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	expedition.attempt_current_fase()  # vence a Fase 1
	var history: Dictionary = expedition.fase_history.get(1, {})

	print("  Vitória -> fase_history[1] tem player_army_name real ('%s')? %s" % [
		history.get("player_army_name", ""), str(history.get("player_army_name", "") == "Exército Teste Formação")
	])
	ctx.check(history.get("player_army_name", "") == "Exército Teste Formação", "player_army_name deve ser o nome real do Exército vencedor")
	ctx.check(history.get("player_formation_name", "") == "α", "player_formation_name deve ser a Formação real que venceu (obtido: '%s')" % history.get("player_formation_name", ""))

	var player_cards: Array = history.get("player_formation_card_names", [])
	print("  player_formation_card_names tem 9 posições reais? %s (%d)" % [str(player_cards.size() == 9), player_cards.size()])
	ctx.check(player_cards.size() == 9, "player_formation_card_names deve ter as 9 posições da Formação real (obtido: %d)" % player_cards.size())
	ctx.check(String(player_cards[0]) == winning_army.get_formation("α")[0].card_name, "A carta na Posição 1 deve ser exatamente a carta real da Formação vencedora (nunca inventada)")

	var enemy_cards: Array = history.get("enemy_formation_card_names", [])
	print("  enemy_formation_card_names tem 9 posições reais? %s (%d)" % [str(enemy_cards.size() == 9), enemy_cards.size()])
	ctx.check(enemy_cards.size() == 9, "enemy_formation_card_names deve ter as 9 posições do Exército inimigo real (obtido: %d)" % enemy_cards.size())
	ctx.check(String(enemy_cards[0]) == enemy.cards[0].card_name, "A carta inimiga na Posição 1 deve ser exatamente a carta real do EnemyArmyEntry")

	ctx.check(String(history.get("enemy_commander_faction", "")) == enemy.commander.faction, "enemy_commander_faction deve ser a Facção real do Comandante inimigo")

	# Derrota: nunca inventa "Formação vencedora" (não existe uma).
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	losing_army.initialize_energy(1)
	var losing_squad := Squad.new([losing_army])
	var expedition_2 := ExpeditionRuntime.new(
		losing_squad, trilha, territory, catalog, registry, 951,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	# Fase 51: comum, não-Acampamento (mesma escolha de test_expedition_runtime.gd — Fase 50 é Acampamento e não dispara combate desde F-020, decisão 8).
	expedition_2.current_fase = 51
	expedition_2.attempt_current_fase()
	var defeat_history: Dictionary = expedition_2.fase_history.get(51, {})

	print("  Derrota -> fase_history NÃO tem player_formation_card_names (nenhuma Formação venceu)? %s" % str(not defeat_history.has("player_formation_card_names")))
	ctx.check(not defeat_history.has("player_formation_card_names"), "Uma derrota nunca deve gravar dados de Formação vencedora — não existe uma")
	ctx.check(not defeat_history.get("victory", true), "O registro de derrota deve ter victory == false")
	ctx.check(defeat_history.get("enemy_formation_card_names", []).size() == 9, "A Formação inimiga real ainda deve ser registrada mesmo numa derrota")

	return true
