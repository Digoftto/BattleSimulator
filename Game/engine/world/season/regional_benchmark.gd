class_name RegionalBenchmark
extends RefCounted
## RegionalBenchmark
##
## Banco de referência (20 Exércitos) construído especificamente pra
## UMA Região — respeita a Restrição de Patente/Tier/Soldo daquela
## Região (PvE.md item 3), metade dos 20 garantidamente COM Máquina de
## Guerra, metade garantidamente SEM (decisão explícita do dono do
## projeto), e sempre posicionado pela heurística (nunca aleatório —
## o Benchmark é a referência fixa de comparação, precisa representar
## Exércitos "bem jogados").
##
## Diferente do SeasonBenchmark genérico (usado por SeasonPipeline.run(),
## a Temporada completa) — este é específico do experimento/geração
## por Região.

const BENCHMARK_SIZE: int = 20
const MACHINE_CLASS: String = "Máquina de Guerra"


static func build(territory_faction: String, region: int, all_cards: Array[CardResource], seed_value: int) -> Array[Army]:
	seed(seed_value)

	var soldo_cap: int = EnemyArmyGenerator.REGION_SOLDO_CAP[region]
	var tier_range: Array = EnemyArmyGenerator.REGION_TIER_RANGE[region]
	var half: int = BENCHMARK_SIZE / 2

	var result: Array[Army] = []
	for i in range(BENCHMARK_SIZE):
		var include_machine: bool = i < half
		var cards: Array[CardResource] = _build_composition_with_machine_control(
			territory_faction, all_cards, region, soldo_cap, tier_range, include_machine
		)

		var army := Army.new()
		var commander := CommanderResource.new()
		commander.commander_name = "Benchmark Regional %d" % i
		commander.faction = territory_faction
		# A composição foi montada respeitando soldo_cap (o teto da
		# Região) — o Comandante precisa de uma Patente cujo próprio
		# teto (SOLDO.md) seja pelo menos esse valor, senão
		# Army.is_ready_for_battle() falha na hora do combate mesmo a
		# composição estando correta pra Região.
		var patente_options: Array = EnemyArmyGenerator.REGION_PATENTE_OPTIONS[region]
		commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
			func(entry: Dictionary) -> bool: return entry["patente"] == patente_options[-1]
		)[0]["xp"]
		army.commander = commander
		army.cards = ArmyPositioningHeuristic.apply_heuristic(cards)

		result.append(army)

	return result


static func _build_composition_with_machine_control(
	territory_faction: String, all_cards: Array[CardResource], region: int, soldo_cap: int, tier_range: Array, include_machine: bool
) -> Array[CardResource]:
	var pool: Array[CardResource] = all_cards
	if not include_machine:
		pool = all_cards.filter(func(c: CardResource) -> bool: return c.card_class != MACHINE_CLASS)

	var composition: Array[CardResource] = EnemyArmyGenerator.build_composition(territory_faction, pool, region, soldo_cap)

	if not include_machine:
		return composition

	var already_has_machine: bool = false
	for card: CardResource in composition:
		if card.card_class == MACHINE_CLASS:
			already_has_machine = true
			break
	if already_has_machine:
		return composition

	var machine_template: CardResource = null
	for card: CardResource in all_cards:
		if card.faction == territory_faction and card.card_class == MACHINE_CLASS:
			machine_template = card
			break
	if machine_template == null:
		return composition  # Facção sem Máquina de Guerra no catálogo — segue sem, não deveria acontecer dado FACTION_DESIGN.md.

	# Troca a 1ª carta da Facção do Território (posições 0-5, sempre
	# territoriais por construção) pela Máquina de Guerra, se couber
	# no teto de Soldo — raro não caber, já que MdG costuma ser barata.
	var replace_index: int = 0
	for i in range(6):
		if composition[i].faction == territory_faction:
			replace_index = i
			break

	var machine_copy: CardResource = machine_template.duplicate()
	machine_copy.tier = tier_range[0] if tier_range[0] == tier_range[1] else (tier_range[0] + (randi() % (tier_range[1] - tier_range[0] + 1)))

	var candidate: Array[CardResource] = composition.duplicate()
	candidate[replace_index] = machine_copy
	if Soldo.total_for_composition(candidate) <= soldo_cap:
		return candidate

	return composition  # não coube — segue sem MdG neste Exército específico.
