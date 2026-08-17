class_name RegionalGenerationRunner
extends RefCounted
## RegionalGenerationRunner
##
## Roda o experimento acordado: pra UMA Região, constrói o Benchmark
## Regional (20 Exércitos), gera "heuristic_count + random_count"
## candidatos de "Fases Normais" (sem Comandante narrativo, respeitando
## a Restrição de Patente/Tier/Soldo da Região), calcula o Win Rate de
## cada um contra o Benchmark, e registra qual modo de posicionamento
## foi usado — heurística de bom senso ou aleatório de verdade — pra
## comparar as duas distribuições depois.
##
## ATENÇÃO DE PERFORMANCE (mesmo aviso já registrado em outros lugares
## deste projeto): 30.000 candidatos × N simulações cada é trabalho
## real de CombatEngine — em escala de produção (milhares de
## simulações por candidato) isso demora muito. Rode em escala
## reduzida pra testar rápido; a escala real pertence à ferramenta
## externa, nunca ao boot do jogo.


static func run(
	territory_faction: String,
	region: int,
	all_cards: Array[CardResource],
	heuristic_count: int,
	random_count: int,
	simulations_per_candidate: int,
	seed_value: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> RegionalGenerationReport:
	var benchmark: Array[Army] = RegionalBenchmark.build(territory_faction, region, all_cards, seed_value)

	var soldo_cap: int = EnemyArmyGenerator.REGION_SOLDO_CAP[region]

	var report := RegionalGenerationReport.new()
	report.territory_faction = territory_faction
	report.region = region
	report.category_label = "fases_normais"
	report.benchmark_size = benchmark.size()
	report.simulations_per_candidate = simulations_per_candidate
	report.seed_value = seed_value
	report.generated_at_unix = GameClock.now_unix()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1  # diferente da seed do Benchmark, pra não correlacionar posicionamento aleatório com a composição do Benchmark

	var total_candidates: int = heuristic_count + random_count
	for i in range(total_candidates):
		var use_heuristic: bool = i < heuristic_count

		var cards: Array[CardResource] = EnemyArmyGenerator.build_composition(territory_faction, all_cards, region, soldo_cap)
		var positioned_cards: Array[CardResource] = (
			ArmyPositioningHeuristic.apply_heuristic(cards) if use_heuristic
			else ArmyPositioningHeuristic.apply_random(cards, rng)
		)

		var candidate_army := Army.new()
		candidate_army.commander = _bare_commander(territory_faction, region)
		candidate_army.cards = positioned_cards

		var wins: int = 0
		for s in range(simulations_per_candidate):
			var opponent: Army = benchmark[s % benchmark.size()]
			var state: CombatState = CombatEngine.run_battle(candidate_army, opponent, battlefields, abilities_by_name, unit_traits)
			if state.winner_side == 0:
				wins += 1

		var win_rate: float = float(wins) / float(simulations_per_candidate) if simulations_per_candidate > 0 else 0.0
		report.candidate_results.append({
			"win_rate": win_rate,
			"positioning": "heuristic" if use_heuristic else "random",
		})

	return report


## Mesmo "Comandante técnico" de EnemyArmyGenerator._build_commander()
## pra Fases Normais — sem Doutrina, só existe pra Army.commander_patente()
## nunca falhar durante o combate real.
static func _bare_commander(territory_faction: String, region: int) -> CommanderResource:
	var patente_options: Array = EnemyArmyGenerator.REGION_PATENTE_OPTIONS[region]
	var commander := CommanderResource.new()
	commander.commander_name = ""
	commander.faction = territory_faction
	commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
		func(entry: Dictionary) -> bool: return entry["patente"] == patente_options[-1]
	)[0]["xp"]
	return commander
