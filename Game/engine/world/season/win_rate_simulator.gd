class_name WinRateSimulator
extends RefCounted
## WinRateSimulator
##
## Calcula o WR (taxa de vitória) de um EnemyArmyEntry, simulando-o
## repetidamente contra o benchmark fixo da Temporada. Utiliza
## exclusivamente CombatEngine.run_battle() (caixa-preta, sem nenhuma
## alteração nele).


static func calculate(
	entry: EnemyArmyEntry,
	benchmark: Array[Army],
	simulations: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> float:
	if benchmark.is_empty() or simulations <= 0:
		return 0.0

	var candidate_army := Army.new()
	candidate_army.commander = entry.commander
	candidate_army.cards = entry.cards

	var wins: int = 0
	for i in range(simulations):
		var opponent: Army = benchmark[i % benchmark.size()]

		if not candidate_army.is_ready_for_battle() or not opponent.is_ready_for_battle():
			continue

		var state: CombatState = CombatEngine.run_battle(
			candidate_army, opponent, battlefields, abilities_by_name, unit_traits
		)
		if state.winner_side == 0:
			wins += 1

	return float(wins) / float(simulations)
