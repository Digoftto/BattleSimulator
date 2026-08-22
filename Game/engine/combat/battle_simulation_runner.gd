class_name BattleSimulationRunner
extends RefCounted
## BattleSimulationRunner (F-028)
##
## Primitiva mínima e nova: dado um conjunto de pares de Exército já
## montados (por quem chama), roda uma batalha seedada por par e
## devolve um BattleResult por batalha — "executar N batalhas, fornecer
## seeds, coletar resultados, retornar coleção" (F-028 §12).
##
## NÃO substitui BalanceSimulator/WinRateSimulator/RegionalGenerationRunner/
## RegionalCategoryGenerationRunner/MiningEfficiencyEstimator. Cada um
## desses já gera os Exércitos de forma diferente a cada iteração —
## exatamente a parte que varia entre eles, e que continua sendo
## responsabilidade de cada um. Esta classe cobre apenas a parte que já
## era idêntica em todos: "rodar uma batalha com seed e devolver um
## resultado estruturado" (CombatEngine.run_battle() + BattleResult).
## Migrá-los para usar esta classe é possível numa etapa futura, mas
## exigiria tocar em 5 arquivos existentes só por uniformidade de
## código — fora do escopo do F-028 (ver relatório final, seção 9).

## "army_pairs": Array de Dictionary {"army_a": Army, "army_b": Army,
## "formation_label_a": String (opcional), "formation_label_b": String
## (opcional)}.
## "base_seed_value": seed da primeira batalha; cada batalha seguinte
## usa base_seed_value + índice — determinística e reproduzível como
## lote inteiro a partir de uma única seed-base, sem precisar armazenar
## uma lista de seeds separada.
## "collect_events": quando true, cada batalha ganha seu próprio
## BattleEventCollector (nunca compartilhado entre batalhas), e
## BattleResult.total_damage_by_side/total_healing_by_side/
## total_shield_absorbed_by_side vêm preenchidos.
static func run_batch(
	army_pairs: Array,
	base_seed_value: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	game_mode: String = "pve",
	collect_events: bool = false
) -> Array[BattleResult]:
	var results: Array[BattleResult] = []

	for i in range(army_pairs.size()):
		var pair: Dictionary = army_pairs[i]
		var battle_seed_value: int = base_seed_value + i
		results.append(_run_one(pair, battle_seed_value, battlefields, abilities_by_name, unit_traits, game_mode, collect_events))

	return results


## F-029: mesmo formato de "army_pairs" de run_batch(), mas a seed de
## cada batalha vem de "config.seed_for_battle(i)" (SimulationConfig,
## F-029 §3/§4) em vez de sempre "base_seed_value + índice" — permite
## SeedMode.FIXED (todas as batalhas com a MESMA seed, útil quando só a
## composição sorteada deve variar entre batalhas — ver
## SimulationConfig). "config.game_mode" e "config.collect_events"
## também vêm da configuração, para nunca precisar repassar os mesmos 6
## parâmetros duas vezes (run_batch() continua existindo, sem mudanças,
## para quem só precisa da forma mais simples e direta).
static func run_series(
	army_pairs: Array,
	config: SimulationConfig,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> Array[BattleResult]:
	var results: Array[BattleResult] = []

	for i in range(army_pairs.size()):
		var pair: Dictionary = army_pairs[i]
		var battle_seed_value: int = config.seed_for_battle(i)
		results.append(_run_one(pair, battle_seed_value, battlefields, abilities_by_name, unit_traits, config.game_mode, config.collect_events))

	return results


static func _run_one(
	pair: Dictionary,
	battle_seed_value: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	game_mode: String,
	collect_events: bool
) -> BattleResult:
	var state: CombatState = CombatEngine.initialize(
		pair["army_a"], pair["army_b"], battlefields, abilities_by_name, unit_traits, game_mode, battle_seed_value
	)

	# F-029: a Formação de PARTIDA precisa ser capturada AQUI — depois de
	# initialize() (posições já atribuídas por _place_army()) mas ANTES
	# de run() (que pode mover unidades a cada turno, COMBAT_RULES.md
	# 5.2) — ver BattleResult.unit_snapshots_by_side.
	var starting_roster: Dictionary = _snapshot_starting_roster(state)

	var collector: BattleEventCollector = null
	if collect_events:
		collector = BattleEventCollector.new()
		collector.attach(state.event_bus)

	CombatEngine.run(state)

	return BattleResult.from_state(
		state, collector, starting_roster,
		pair.get("formation_label_a", ""), pair.get("formation_label_b", "")
	)


## side (0/1) -> Array[Dictionary] {"card_name", "position", "card_class"}
## — a Formação de partida de cada lado, uma entrada por pelotão vivo
## no início da batalha (sempre 9, mas nunca presumido aqui).
static func _snapshot_starting_roster(state: CombatState) -> Dictionary:
	var roster: Dictionary = {0: [], 1: []}
	for unit: CombatUnit in state.units:
		if not roster.has(unit.side):
			roster[unit.side] = []
		roster[unit.side].append({
			"card_name": unit.card.card_name if unit.card != null else "",
			"position": unit.position,
			"card_class": unit.card.card_class if unit.card != null else "",
		})
	return roster


# ---------------------------------------------------------------------------
# F-029 §5/§6: construtores de "army_pairs" para as 3 modalidades — a
# ÚNICA diferença entre elas é COMO os pares são montados; run_batch()/
# run_series() acima não sabem nem precisam saber qual modalidade
# produziu o Array que receberam. Cada construtor reaproveita
# EnemyArmyGenerator/CommanderGenerator por completo (F-028) — nenhum
# segundo sistema de geração, como pedido no §6.
# ---------------------------------------------------------------------------

## F-029 §5C — Fixed vs Fixed: os mesmos dois Exércitos repetidos em
## "count" pares. Cada batalha individual ainda tem sua própria seed
## (via run_batch()/run_series()) — só a composição dos dois lados não
## varia entre batalhas. Base direta do futuro Campo de Prova (§5,
## nota) e de "Army A vs Army B" (§17).
static func build_fixed_vs_fixed_pairs(
	army_a: Army,
	army_b: Army,
	count: int,
	formation_label_a: String = "",
	formation_label_b: String = ""
) -> Array:
	var pairs: Array = []
	for i in range(count):
		pairs.append({
			"army_a": army_a, "army_b": army_b,
			"formation_label_a": formation_label_a, "formation_label_b": formation_label_b,
		})
	return pairs


## F-029 §5B — Fixed vs Random: lado A fixo, lado B gerado por
## EnemyArmyGenerator uma vez por batalha, a partir de um único
## RandomNumberGenerator consumido sequencialmente ao longo de toda a
## série (mesmo padrão do "full chain" do F-028) — reproduzível como
## série inteira a partir de "generation_base_seed_value", que é
## deliberadamente INDEPENDENTE da seed de combate de cada batalha
## (SimulationConfig.base_seed_value/seed_for_battle(), usada por
## run_series() para o CombatState de cada batalha) — duas fontes de
## aleatoriedade distintas e sem contaminação cruzada (RNG de geração
## de Exército vs. RNG de combate), exatamente como já é o caso em
## CombatState.rng vs. o "rng" que EnemyArmyGenerator recebe.
static func build_fixed_vs_random_pairs(
	fixed_army: Army,
	count: int,
	generation_base_seed_value: int,
	category: EnemyArmyEntry.Category,
	territory_faction: String,
	region: int,
	all_cards: Array[CardResource],
	season_config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	id_prefix: String,
	force_comum_tier1: bool = false,
	fixed_formation_label: String = ""
) -> Array:
	var pairs: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_base_seed_value

	for i in range(count):
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			category, territory_faction, region, all_cards, season_config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			id_prefix, i, force_comum_tier1, rng
		)
		var generated_army := Army.new()
		generated_army.commander = entry.commander
		generated_army.cards = entry.cards
		pairs.append({"army_a": fixed_army, "army_b": generated_army, "formation_label_a": fixed_formation_label})

	return pairs


## F-029 §5A — Random vs Random: os dois lados gerados por
## EnemyArmyGenerator, a partir do MESMO RandomNumberGenerator (lado A
## consumido antes do lado B, a cada iteração) — mesma lógica de
## build_fixed_vs_random_pairs() acima, aplicada aos dois lados.
static func build_random_vs_random_pairs(
	count: int,
	generation_base_seed_value: int,
	category: EnemyArmyEntry.Category,
	territory_faction_a: String,
	territory_faction_b: String,
	region: int,
	all_cards: Array[CardResource],
	season_config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	id_prefix: String,
	force_comum_tier1: bool = false
) -> Array:
	var pairs: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_base_seed_value

	for i in range(count):
		var entry_a: EnemyArmyEntry = EnemyArmyGenerator.generate(
			category, territory_faction_a, region, all_cards, season_config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			"%s_a" % id_prefix, i, force_comum_tier1, rng
		)
		var entry_b: EnemyArmyEntry = EnemyArmyGenerator.generate(
			category, territory_faction_b, region, all_cards, season_config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			"%s_b" % id_prefix, i, force_comum_tier1, rng
		)
		var army_a := Army.new()
		army_a.commander = entry_a.commander
		army_a.cards = entry_a.cards
		var army_b := Army.new()
		army_b.commander = entry_b.commander
		army_b.cards = entry_b.cards
		pairs.append({"army_a": army_a, "army_b": army_b})

	return pairs


## F-029 §18 — "coração do futuro Campo de Prova": recebe um Army REAL
## (do jogador) e simula contra N adversários gerados (Fixed vs
## Random). O jogador não tem acesso a isto nesta etapa (§18) — é só a
## API. §19: a diferença entre isto e um futuro PvE/PvP está inteiramente
## em QUEM chama e com quais parâmetros de geração (Território/Região/
## Categoria) — este método em si não distingue PvE de Campo de Prova.
static func simulate_player_army_vs_generated(
	player_army: Army,
	config: SimulationConfig,
	generation_base_seed_value: int,
	category: EnemyArmyEntry.Category,
	territory_faction: String,
	region: int,
	all_cards: Array[CardResource],
	season_config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	id_prefix: String = "sim_player_vs_generated"
) -> SimulationReport:
	var pairs: Array = build_fixed_vs_random_pairs(
		player_army, config.simulation_count, generation_base_seed_value,
		category, territory_faction, region, all_cards, season_config,
		commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
		id_prefix
	)
	var results: Array[BattleResult] = run_series(pairs, config, battlefields, abilities_by_name, unit_traits)
	return SimulationReport.build(results)
