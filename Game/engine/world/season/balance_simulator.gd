class_name BalanceSimulator
extends RefCounted
## BalanceSimulator (OBSERVATORY.md, "Meta Aleatório")
##
## Roda muitas batalhas Exército-vs-Exército com composições
## aleatórias, usando EXATAMENTE EnemyArmyGenerator.build_composition()
## para montar os dois lados — o mesmo gerador já usado pra Exércitos
## inimigos de PvE (mesmas regras de Soldo, mesma regra de 6 cartas da
## Facção principal + 3 de uma Secundária), só que aqui as Facções de
## cada lado também são sorteadas (nenhum dos dois lados é fixo), pra
## cobrir toda a "meta" de combinações possíveis.
##
## ATENÇÃO DE PERFORMANCE (mesmo aviso já registrado em
## MiningCycleResolver.gd e minas_panel.gd): cada batalha é uma
## simulação real de CombatEngine — 10.000 séries (a referência oficial
## de OBSERVATORY.md) demora bastante. Escalas menores (centenas) são
## adequadas pra testes rápidos; a escala oficial pertence à execução
## via ferramenta externa (tools/), nunca dentro do boot do jogo.

const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]


static func run(
	config: BalanceSimulationConfig,
	all_cards: Array[CardResource],
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> BalanceReport:
	var report := BalanceReport.new()
	report.label = config.label
	report.series_count = config.series_count
	report.seed_value = config.seed_value
	report.generated_at_unix = GameClock.now_unix()

	var rng := RandomNumberGenerator.new()
	rng.seed = config.seed_value

	for i in range(config.series_count):
		var cards_a: Array[CardResource] = _build_random_composition(all_cards, rng)
		var cards_b: Array[CardResource] = _build_random_composition(all_cards, rng)

		var army_a := Army.new()
		army_a.commander = _bare_commander()
		army_a.cards = cards_a
		var army_b := Army.new()
		army_b.commander = _bare_commander()
		army_b.cards = cards_b

		var state: CombatState = CombatEngine.run_battle(army_a, army_b, battlefields, abilities_by_name, unit_traits)

		report.total_battles += 1
		if state.winner_side == 0:
			report.side_a_wins += 1
		elif state.winner_side == 1:
			report.side_b_wins += 1
		else:
			report.draws += 1

		_tally(report, cards_a, state.winner_side == 0)
		_tally(report, cards_b, state.winner_side == 1)

	return report


static func _build_random_composition(all_cards: Array[CardResource], rng: RandomNumberGenerator) -> Array[CardResource]:
	var main_faction: String = FACTIONS[rng.randi() % FACTIONS.size()]
	return EnemyArmyGenerator.build_composition(main_faction, all_cards, 1, Soldo.cap_for_patente("Recruta"))


## Comandante "Recruta" vazio — só pra satisfazer o teto de Soldo que
## Army.is_ready_for_battle() exige (build_composition() já garante
## respeitar o teto de 18, o mesmo teto de um Recruta — ver comentário
## em enemy_army_generator.gd). Sem Doutrina Militar: irrelevante pra
## fins de estatística de carta/posição, que é o que este simulador mede.
static func _bare_commander() -> CommanderResource:
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Simulação"
	return commander


static func _tally(report: BalanceReport, cards: Array[CardResource], won: bool) -> void:
	for i in range(cards.size()):
		var card: CardResource = cards[i]
		var position: int = i + 1

		if not report.card_stats.has(card.card_name):
			report.card_stats[card.card_name] = {"appearances": 0, "wins": 0}
		report.card_stats[card.card_name]["appearances"] += 1
		if won:
			report.card_stats[card.card_name]["wins"] += 1

		if not report.position_stats.has(position):
			report.position_stats[position] = {"appearances": 0, "wins": 0}
		report.position_stats[position]["appearances"] += 1
		if won:
			report.position_stats[position]["wins"] += 1
