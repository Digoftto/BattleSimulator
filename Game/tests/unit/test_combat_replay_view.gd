class_name TestCombatReplayView
extends RefCounted
## TestCombatReplayView (F-046)
##
## Valida a infraestrutura mínima de Combate Visual (CombatReplayCollector
## + CombatReplayView) com uma batalha real, executada de ponta a ponta
## por CombatEngine — sem alterar CombatEngine, sem alterar nenhuma
## regra. O teste mais importante aqui: o tabuleiro reconstruído pelo
## replay (percorrendo replay_events evento a evento) precisa bater
## EXATAMENTE com o CombatState final real do motor — prova de que a
## camada visual nunca diverge do que o motor realmente produziu.
##
## NUNCA usa await/timers (CombatReplayView._play_replay() é assíncrono
## de propósito, pra dar ritmo humano à reprodução) — TestRunner.run()
## chama cada teste via Callable.call() SEM await (test_runner.gd:102),
## então uma função de teste com await retornaria antes de "return true"
## e seria contada como falso ERROR. Por isso este teste chama
## _apply_replay_event() diretamente, em loop síncrono, pulando
## inteiramente o timer de ritmo — exercita 100% da lógica de
## atualização de estado/tabuleiro sem depender de SceneTree/tempo real.

static func _build_test_armies() -> Array[Army]:
	var option_a: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army_a := Army.new()
	army_a.commander = option_a["commander"]
	army_a.cards = (option_a["cards"] as Array[CardResource]).duplicate()

	var option_b: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[1]
	var army_b := Army.new()
	army_b.commander = option_b["commander"]
	army_b.cards = (option_b["cards"] as Array[CardResource]).duplicate()

	return [army_a, army_b]


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-046] Validando CombatReplayCollector/CombatReplayView com uma batalha real...")
	_test_replay_matches_real_combat_state(ctx)
	return true


static func _test_replay_matches_real_combat_state(ctx: TestRunner.Context) -> void:
	var armies: Array[Army] = _build_test_armies()
	var army_a: Army = armies[0]
	var army_b: Army = armies[1]

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 4242)

	# F-046: preload() em vez do identificador global "CombatReplayCollector"
	# — mesmo motivo já documentado em test_army_editor_formation_flow.gd:
	# um class_name novo só entra no cache global de classes quando o
	# Editor do Godot escaneia o projeto, o que nunca acontece numa
	# execução --headless. preload() resolve pelo caminho do arquivo,
	# nunca depende desse cache.
	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	print("  [A] Snapshot inicial capturou as 18 unidades (9+9)? %s (%d capturadas)" % [str(collector.initial_board.size() == 18), collector.initial_board.size()])
	ctx.check(collector.initial_board.size() == 18, "[A] snapshot_initial_board() deve capturar exatamente 9+9 = 18 unidades, uma por posição de cada Exército")

	CombatEngine.run(state)

	print("  [B] O replay capturou algum evento durante uma batalha real de %d turnos? %s (%d eventos)" % [state.turn, str(not collector.replay_events.is_empty()), collector.replay_events.size()])
	ctx.check(not collector.replay_events.is_empty(), "[B] Uma batalha real (não bloqueada por Restrição de Campo de Batalha) deve produzir ao menos 1 evento de replay")

	# F-046: preload() em vez de "CombatReplayView" — mesmo motivo do
	# collector acima.
	var view = preload("res://scenes/combat/combat_replay_view.gd").new()
	view.combat_state = state
	view.replay_collector = collector
	view._build_static_structure()
	view._apply_initial_board()

	for event: Dictionary in collector.replay_events:
		view._apply_replay_event(event)

	# O teste central: o tabuleiro reconstruído pelo replay (evento a
	# evento, sem nenhum acesso direto a "state") precisa bater
	# EXATAMENTE com o CombatState FINAL real, unidade por unidade —
	# prova de que a camada visual nunca diverge do motor.
	var all_positions_match: bool = true
	var checked_positions: int = 0
	for side in [0, 1]:
		for position in range(1, 10):
			var real_unit: CombatUnit = state.unit_at(side, position)
			var key: int = side * 10 + position
			var live_entry: Variant = view._live_board.get(key, null)

			if real_unit == null or not real_unit.is_alive:
				if live_entry != null and live_entry["alive"]:
					all_positions_match = false
					print("  [C] MISMATCH (Lado %d, Posição %d): replay mostra vivo, CombatState real não tem unidade viva ali" % [side, position])
				continue

			checked_positions += 1
			if live_entry == null:
				all_positions_match = false
				print("  [C] MISMATCH (Lado %d, Posição %d): CombatState real tem '%s' viva, replay não tem nada" % [side, position, real_unit.card.card_name])
				continue
			if live_entry["card_name"] != real_unit.card.card_name or not live_entry["alive"]:
				all_positions_match = false
				print("  [C] MISMATCH (Lado %d, Posição %d): replay tem '%s'/alive=%s, CombatState real tem '%s'/alive=true" % [
					side, position, live_entry["card_name"], str(live_entry["alive"]), real_unit.card.card_name
				])
				continue
			if live_entry["hp"] != real_unit.current_hp or live_entry["esc"] != real_unit.current_esc:
				all_positions_match = false
				print("  [C] MISMATCH (Lado %d, Posição %d, %s): replay HP/ESC %d/%d, CombatState real %d/%d" % [
					side, position, real_unit.card.card_name, live_entry["hp"], live_entry["esc"], real_unit.current_hp, real_unit.current_esc
				])

	print("  [C] Tabuleiro reconstruído pelo replay bate exatamente com o CombatState final real (%d posições com unidade viva verificadas)? %s" % [checked_positions, str(all_positions_match)])
	ctx.check(all_positions_match, "[C] O tabuleiro reconstruído por CombatReplayView, percorrendo só replay_events, deve bater exatamente (nome/HP/ESC/vivo-ou-morto) com o CombatState final real do CombatEngine, posição por posição")

	view._show_result()
	var expected_result_visible: bool = view._result_label.visible and view._continue_button.visible and not view._skip_button.visible
	print("  [D] Banner de Resultado (Vitória/Derrota/Empate) e botão Continuar aparecem ao final? %s (texto: '%s')" % [str(expected_result_visible), view._result_label.text])
	ctx.check(expected_result_visible, "[D] Ao final do replay, o banner de Resultado deve ficar visível junto do botão Continuar, e o botão Pular deve sumir")

	# ART-001: o Battlefield real da batalha (sorteado por CombatEngine.initialize(),
	# nunca escolhido por esta camada) deve aparecer como fundo.
	print("  [E] O fundo do Campo de Batalha real (%s) apareceu como textura no CombatReplayView? %s" % [
		state.battlefield.battlefield_name if state.battlefield != null else "<nulo>", str(view._battlefield_texture_rect.texture != null)
	])
	ctx.check(view._battlefield_texture_rect.texture != null, "[E] CombatReplayView deve carregar a arte do Campo de Batalha real da batalha (nunca inventar um Campo próprio)")

	# ART-001: toda posição com unidade VIVA precisa ter um retrato real
	# carregado — nunca ficar só no texto (a informação principal agora
	# é a arte, texto é apoio).
	var all_alive_have_portrait: bool = true
	var alive_checked: int = 0
	for key: int in view._live_board.keys():
		if view._live_board[key]["alive"]:
			alive_checked += 1
			var widgets: Dictionary = view._position_widgets.get(key, {})
			if widgets.is_empty() or widgets["portrait"].texture == null:
				all_alive_have_portrait = false
	print("  [F] Toda posição com unidade viva ao final (%d verificadas) tem um retrato real carregado, não só texto? %s" % [alive_checked, str(all_alive_have_portrait)])
	ctx.check(alive_checked > 0, "[F] Pré-condição: a batalha real precisa terminar com ao menos 1 unidade viva pra este teste fazer sentido")
	ctx.check(all_alive_have_portrait, "[F] Toda posição com unidade viva deve mostrar o retrato real da carta (CardArtCatalog), nunca só o texto de apoio")

	view.free()
