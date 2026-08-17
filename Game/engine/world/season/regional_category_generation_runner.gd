class_name RegionalCategoryGenerationRunner
extends RefCounted
## RegionalCategoryGenerationRunner
##
## Gera N candidatos de uma categoria COM Comandante (Chefes Normais,
## Chefes Regionais, Chefe de Mina) pra uma Região específica, sempre
## com a heurística de posicionamento (decisão confirmada — sem
## repetir o experimento heurística-vs-aleatório pra cada categoria; a
## conclusão de Fases Normais vale pra todas), avaliando cada um contra
## o Benchmark Regional daquela mesma Região/Território. Reaproveita
## EnemyArmyGenerator.generate() por completo — incluindo Patente por
## Região e, pra Chefe Regional/Mina, o piso de Rarity Score
## ("Comandante Exclusivo de Campanha").
##
## Retorna o mesmo RegionalGenerationReport das Fases Normais, só que
## toda entrada fica marcada "heuristic" (não existe modo aleatório
## aqui) — win_rates_for("random") sempre vem vazio, de propósito.

static func run(
	category: EnemyArmyEntry.Category,
	territory_faction: String,
	region: int,
	all_cards: Array[CardResource],
	config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	candidate_count: int,
	simulations_per_candidate: int,
	seed_value: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> RegionalGenerationReport:
	var benchmark: Array[Army] = RegionalBenchmark.build(territory_faction, region, all_cards, seed_value)

	var report := RegionalGenerationReport.new()
	report.territory_faction = territory_faction
	report.region = region
	report.category_label = EnemyArmyEntry.Category.keys()[category].to_lower()
	report.benchmark_size = benchmark.size()
	report.simulations_per_candidate = simulations_per_candidate
	report.seed_value = seed_value
	report.generated_at_unix = GameClock.now_unix()

	var id_prefix: String = "%s_%s_r%d" % [territory_faction, EnemyArmyEntry.Category.keys()[category], region]

	for i in range(candidate_count):
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			category, territory_faction, region, all_cards, config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			id_prefix, i
		)

		var candidate_army := Army.new()
		candidate_army.commander = entry.commander
		candidate_army.cards = entry.cards  # já posicionado pela heurística, dentro de generate()

		var wins: int = 0
		for s in range(simulations_per_candidate):
			var opponent: Army = benchmark[s % benchmark.size()]
			var state: CombatState = CombatEngine.run_battle(candidate_army, opponent, battlefields, abilities_by_name, unit_traits)
			if state.winner_side == 0:
				wins += 1

		var win_rate: float = float(wins) / float(simulations_per_candidate) if simulations_per_candidate > 0 else 0.0
		report.candidate_results.append({"win_rate": win_rate, "positioning": "heuristic"})

	return report
