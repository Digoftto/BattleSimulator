extends Node
## check_starter_affinity.gd (F-036)
##
## Diagnóstico read-only: roda os 3 Starter Armies REAIS (StarterKitResolver
## + CARD_CATALOG.md via GameDatabase, nunca dados sintéticos) através de
## CombatEngine.initialize() e imprime os Pontos/Nível de Afinidade
## efetivamente calculados por AffinityRuntime, mais uma amostra de
## atributos (ESC/HP) antes e depois do bônus de Nível I — a evidência
## pedida no F-036, item 2 ("Confirmar os pontos e níveis efetivamente
## calculados. Confirmar os bônus efetivamente aplicados.").
##
## NÃO altera nenhum dado de produção: não chama StarterKitResolver.
## choose_option(), não toca Kingdom/save, não modifica Starter rosters
## nem formação. Uso: godot --headless --path Game --script
## res://tools/debug/check_starter_affinity.gd

func _ready() -> void:
	print("=== F-036: Afinidade dos 3 Starter Armies reais (StarterKitResolver) ===")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_check_option(option)

	_run_fixed_vs_fixed_sanity_check(options)

	get_tree().quit()


## F-036, item 7: sanity check — 1 batalha Fixed x Fixed por confronto
## entre os 3 Starter Armies REAIS, agora com Afinidade realmente ativa.
## Apenas leitura/observação: não altera roster, formação nem Starter Kit.
func _run_fixed_vs_fixed_sanity_check(options: Array[Dictionary]) -> void:
	print("\n=== F-036: Sanity check Fixed x Fixed (1 batalha por confronto, seed fixa) ===")
	var by_faction: Dictionary = {}
	for option: Dictionary in options:
		by_faction[option["faction"]] = option

	var matchups: Array = [
		["Império", "Natureza"],
		["Império", "Mortos-Vivos"],
		["Natureza", "Mortos-Vivos"],
	]

	for matchup: Array in matchups:
		var option_a: Dictionary = by_faction[matchup[0]]
		var option_b: Dictionary = by_faction[matchup[1]]

		var army_a := Army.new()
		army_a.commander = option_a["commander"]
		army_a.cards = option_a["cards"].duplicate()

		var army_b := Army.new()
		army_b.commander = option_b["commander"]
		army_b.cards = option_b["cards"].duplicate()

		var state: CombatState = CombatEngine.run_battle(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 42)

		var winner_text: String = "empate" if state.winner_side == -1 else matchup[state.winner_side]
		print("  %s x %s -> vencedor: %s | motivo: %s | turnos: %d | Campo: %s" % [
			matchup[0], matchup[1], winner_text, state.end_reason, state.turn, state.battlefield.battlefield_name
		])
		print("    Pontos finais (Lado 0, %s): %s | Nível: %s" % [matchup[0], str(state.affinity_points.get(0, {})), str(state.affinity_levels.get(0, {}))])
		print("    Pontos finais (Lado 1, %s): %s | Nível: %s" % [matchup[1], str(state.affinity_points.get(1, {})), str(state.affinity_levels.get(1, {}))])


func _check_option(option: Dictionary) -> void:
	var faction: String = option["faction"]
	var commander: CommanderResource = option["commander"]
	var cards: Array[CardResource] = option["cards"]

	print("\n--- Starter: %s ---" % faction)
	var card_names: Array[String] = []
	for card: CardResource in cards:
		card_names.append("%s (%s)" % [card.card_name, card.faction])
	print("  Cartas (9): %s" % ", ".join(card_names))
	print("  Comandante: %s | Facção: %s" % [commander.commander_name, commander.faction])

	# Espelho (mesmo Starter dos dois lados) apenas para satisfazer a
	# assinatura de CombatEngine.initialize() (precisa de 2 Exércitos) —
	# não afeta o cálculo de Afinidade do Lado 0, que é o único inspecionado.
	var army_a := Army.new()
	army_a.commander = commander
	army_a.cards = cards.duplicate()

	var mirror_commander := CommanderResource.new()
	mirror_commander.commander_name = commander.commander_name
	mirror_commander.faction = commander.faction
	var army_b := Army.new()
	army_b.commander = mirror_commander
	army_b.cards = cards.duplicate()

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 1)

	print("  Pontos de Afinidade (Lado 0) por Facção: %s" % str(state.affinity_points.get(0, {})))
	print("  Nível de Afinidade (Lado 0) por Facção: %s" % str(state.affinity_levels.get(0, {})))

	for unit: CombatUnit in state.units_of_side(0, true):
		var base_esc: int = unit.card.esc
		var base_hp: int = unit.card.hp
		var esc_delta: int = unit.current_esc - base_esc
		var hp_delta: int = unit.current_hp - base_hp
		var note: String = ""
		if esc_delta != 0:
			note += " [ESC base %d -> %d, delta %+d]" % [base_esc, unit.current_esc, esc_delta]
		if hp_delta != 0:
			note += " [HP base %d -> %d, delta %+d]" % [base_hp, unit.current_hp, hp_delta]
		if note != "":
			print("    %s (%s, pos %d):%s" % [unit.card.card_name, unit.card.faction, unit.position, note])
