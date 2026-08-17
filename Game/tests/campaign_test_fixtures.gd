class_name CampaignTestFixtures
extends RefCounted
## CampaignTestFixtures
##
## Moldes de Exército/Carta/Catálogo reutilizados pelos testes de
## Campanha em bootstrap.gd. Extraído porque o mesmo padrão de
## construção se repetia dezenas de vezes ali, deixando o arquivo
## grande demais para manter com facilidade — nenhum teste mudou de
## comportamento com esta extração, só o lugar onde o molde mora.
##
## Todos os métodos são static — classe pura, sem estado.


static func build_campaign_test_card(card_name_value: String, atk: int, hp: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.card_class = "Corpo a Corpo"
	card.faction = "Império"
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = 0
	return card


## "Dummy": imortal (HP altíssimo) e inofensivo (ATK 0) — usado como
## preenchimento inerte nos testes de retry, para que o resultado da
## batalha dependa exclusivamente da posição do "Campeão".
static func build_dummy_cards(count: int, prefix: String) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for i in range(count):
		result.append(build_campaign_test_card("%s%d" % [prefix, i], 0, 999999))
	return result


## Monta uma disposição de 9 cartas com o "Campeão" (ATK 250, HP 200) na
## posição indicada e 8 "Dummies" inofensivos nas demais — verificado
## empiricamente (simulação Python equivalente) que o Campeão na
## Posição 1 vence o inimigo de teste (build_campaign_enemy_army), e em
## qualquer outra posição resulta em empate por limite de turnos.
static func build_champion_formation(champion_position: int) -> Array[CardResource]:
	var champion: CardResource = build_campaign_test_card("Campeão", 250, 200)
	var dummies: Array[CardResource] = build_dummy_cards(8, "Dummy")
	var cards: Array[CardResource] = []
	var dummy_index: int = 0
	for position in range(1, 10):
		if position == champion_position:
			cards.append(champion)
		else:
			cards.append(dummies[dummy_index])
			dummy_index += 1
	return cards


## Exército de teste cujas Formações têm o "Campeão" nas posições
## indicadas por "formation_positions" (Dictionary: nome da Formação ->
## posição). Formações não mencionadas usam a disposição padrão.
static func build_campaign_test_army(formation_positions: Dictionary) -> Army:
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Campanha)"
	commander.faction = "Império"

	var army := Army.new()
	army.commander = commander
	army.cards = build_champion_formation(9)  # disposição padrão irrelevante para estes testes

	for formation_name: String in formation_positions:
		army.formations[formation_name] = build_champion_formation(formation_positions[formation_name])

	return army


## Exército inimigo fixo dos testes de retry: 1 "Guard" (ATK 120, HP 100)
## na posição 1 + 8 "Walls" imortais e inofensivos.
static func build_campaign_enemy_army() -> Army:
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Inimigo (Teste de Campanha)"
	commander.faction = "Natureza"

	var army := Army.new()
	army.commander = commander
	var cards: Array[CardResource] = [build_campaign_test_card("Guard", 120, 100)]
	cards.append_array(build_dummy_cards(8, "Wall"))
	army.cards = cards
	return army


## Monta um SeasonCatalog mínimo de teste contendo apenas o Exército
## inimigo fixo dos testes de Campanha, cadastrado nas 4 categorias e
## disponível na Região 1 — suficiente para exercitar a seleção real
## via EnemyArmySelector sem depender do Pipeline completo.
static func build_test_season_catalog(faction: String, enemy_army: Army) -> SeasonCatalog:
	var entry := EnemyArmyEntry.new()
	entry.id = "TESTE_INIMIGO_FIXO"
	entry.army_name = enemy_army.commander.commander_name
	entry.faction = faction
	entry.cards = enemy_army.cards
	entry.commander = enemy_army.commander
	entry.region_min = 1
	entry.region_max = 1
	entry.win_rate = 0.5

	var catalog := SeasonCatalog.new("Season-Teste")
	var entries: Array[EnemyArmyEntry] = [entry]
	for category: EnemyArmyEntry.Category in [
		EnemyArmyEntry.Category.NORMAL, EnemyArmyEntry.Category.CHEFE_NORMAL,
		EnemyArmyEntry.Category.CHEFE_REGIONAL, EnemyArmyEntry.Category.CHEFE_DE_MINA
	]:
		catalog.add_entries(faction, category, entries)
	return catalog


## Carta transitória usada nos testes de CampaignSynergyCalculator —
## só o Tier III importa, o resto é irrelevante para esse cálculo.
static func build_synergy_test_card(tier_3_ability_name: String) -> CardResource:
	var card := CardResource.new()
	card.tier_3_ability_name = tier_3_ability_name
	return card
