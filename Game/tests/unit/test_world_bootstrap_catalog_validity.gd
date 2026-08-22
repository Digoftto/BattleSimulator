class_name TestWorldBootstrapCatalogValidity
extends RefCounted
## TestWorldBootstrapCatalogValidity (F-009)
##
## Regressão para o achado da F-005/F-006: um Catálogo salvo em disco
## por uma versão anterior de SimulationReportService (antes da
## correção da F-006) pode conter EnemyArmyEntry cujo Comandante perdeu
## accumulated_xp/Doutrina no round-trip — reprovando
## Army.is_ready_for_battle() e travando CombatEngine em tempo real. A
## F-009 adicionou WorldBootstrap._catalog_is_valid() — reaproveitando
## exatamente a mesma checagem que CombatEngine já exige de qualquer
## Exército, sem introduzir nenhum mecanismo de validação novo — pra
## que WorldBootstrap.ensure_world_loaded() nunca confie num Catálogo
## que contenha um Exército inválido.
##
## Não toca em Game/reports/season_catalog.json nem em WorldDatabase —
## constrói os cenários (válido e inválido) inteiramente em memória,
## reproduzindo a mesma assinatura exata do achado da F-005 (Soldo=20,
## válido sob o teto de Major/24, inválido sob o teto de Recruta/18).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-009] Validando WorldBootstrap._catalog_is_valid()...")

	# --- Cenário 1: Catálogo inteiramente válido ---
	var valid_catalog := SeasonCatalog.new("teste_f009_valido")
	var valid_config := SeasonConfig.new()
	valid_config.seed_value = 1
	var valid_entries: Array[EnemyArmyEntry] = []
	for i in range(5):
		valid_entries.append(EnemyArmyGenerator.generate(
			EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, valid_config,
			GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
			GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f009_valido", i
		))
	valid_catalog.add_entries("Império", EnemyArmyEntry.Category.NORMAL, valid_entries)

	var valid_result: bool = WorldBootstrap._catalog_is_valid(valid_catalog)
	print("  Catálogo com 5 Exércitos gerados de verdade (sem round-trip) -> válido? %s (esperado: true)" % str(valid_result))
	ctx.check(valid_result, "Um Catálogo com Exércitos gerados de verdade em memória deve ser considerado válido")

	# --- Cenário 2: Catálogo com exatamente a assinatura do achado da F-005 (commander sem XP) ---
	var invalid_catalog := SeasonCatalog.new("teste_f009_invalido")
	var broken_commander := CommanderResource.new()
	broken_commander.commander_name = "Comandante Técnico (Império)"
	broken_commander.faction = "Império"
	broken_commander.accumulated_xp = 0  # equivalente a um round-trip que perdeu o XP -> Patente "Recruta", teto 18

	var broken_cards: Array[CardResource] = []
	var rarities: Array[String] = ["Comum", "Comum", "Rara", "Rara", "Rara", "Rara", "Rara", "Épica", "Épica"]  # Soldo total = 20
	for i in range(9):
		var card := CardResource.new()
		card.card_name = "Carta de Teste F-009 %d" % i
		card.faction = "Império"
		card.card_class = "Corpo a Corpo"
		card.rarity = rarities[i]
		card.tier = 1
		broken_cards.append(card)

	var broken_entry := EnemyArmyEntry.new()
	broken_entry.id = "teste_f009_invalido_00000"
	broken_entry.faction = "Império"
	broken_entry.category = EnemyArmyEntry.Category.NORMAL
	broken_entry.commander = broken_commander
	broken_entry.cards = broken_cards
	invalid_catalog.add_entries("Império", EnemyArmyEntry.Category.NORMAL, [broken_entry])

	var invalid_result: bool = WorldBootstrap._catalog_is_valid(invalid_catalog)
	print("  Catálogo com 1 Exército reprovando Army.is_ready_for_battle() (Soldo=20, Recruta/teto 18) -> válido? %s (esperado: false)" % str(invalid_result))
	ctx.check(not invalid_result, "Um Catálogo com pelo menos 1 Exército inválido deve ser rejeitado inteiro")

	# --- Cenário 3: Catálogo com um Exército sem Comandante ---
	var no_commander_catalog := SeasonCatalog.new("teste_f009_sem_comandante")
	var no_commander_entry := EnemyArmyEntry.new()
	no_commander_entry.id = "teste_f009_sem_comandante_00000"
	no_commander_entry.faction = "Império"
	no_commander_entry.category = EnemyArmyEntry.Category.NORMAL
	no_commander_entry.commander = null
	no_commander_entry.cards = broken_cards
	no_commander_catalog.add_entries("Império", EnemyArmyEntry.Category.NORMAL, [no_commander_entry])

	var no_commander_result: bool = WorldBootstrap._catalog_is_valid(no_commander_catalog)
	print("  Catálogo com 1 Exército sem Comandante -> válido? %s (esperado: false, sem travar em assert)" % str(no_commander_result))
	ctx.check(not no_commander_result, "Um Catálogo com um Exército sem Comandante deve ser rejeitado, sem travar")

	return true
