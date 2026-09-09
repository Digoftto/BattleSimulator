extends RefCounted
## TestReplayVisualIdentity (correção de replay visual, 2026-09-02)
##
## Regressão para dois problemas encontrados no teste real da batalha:
##
## 1) Unidade morta ficava "fantasma" no Battlefield — CombatReplayView
##    marcava alive=false sem nunca remover a entrada de _live_board, e
##    o slot nunca recaía no ramo de "vazio" (view.clear()).
## 2) _apply_move_event() localizava a unidade de ORIGEM buscando por
##    card_name no mesmo lado — ambíguo quando duas unidades do mesmo
##    lado compartilham o mesmo nome de carta.
##
## Não altera CombatEngine/CombatState/regras de combate — usa as
## mesmas funções estáticas já exercitadas diretamente por
## test_movement_rules.gd/test_movement_sequence_compaction.gd
## (CombatEngine._movement_phase()) sobre um CombatState montado à mão,
## e publica um evento UNIT_DIED manualmente (mesmo formato exato que
## CombatEngine._death_resolution_phase() publica) para testar
## exclusivamente a camada de replay/apresentação, sem depender de
## _check_elimination_victory()/turnos completos, que não são o alvo
## desta suíte.

const ReplayCollectorScript = preload("res://engine/combat/combat_replay_collector.gd")
const ReplayViewScript = preload("res://scenes/combat/combat_replay_view.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[Replay Visual] Validando identidade única (unit_id), morte e movimento multi-passo no replay...")
	_test_duplicate_card_name_move_and_death(ctx)
	_test_multi_step_movement_both_sides(ctx)
	_test_death_frees_slot_for_cascading_movement(ctx)
	return true


static func _card(name_value: String) -> CardResource:
	return TestMovementRules._build_combat_card(name_value, "Corpo a Corpo", 50, 50, 10)


static func _new_view():
	var view = ReplayViewScript.new()
	view._build_static_structure()
	return view


static func _publish_death(state: CombatState, unit: CombatUnit) -> void:
	unit.is_alive = false
	unit.current_hp = 0
	var death_ctx := CombatContext.new()
	death_ctx.state = state
	death_ctx.turn = state.turn
	death_ctx.attacker = unit
	death_ctx.side = unit.side
	death_ctx.position = unit.position
	state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)


## Cenário do pedido (seção 6): duas unidades do MESMO lado com o MESMO
## card_name ("Duplicado"). unit_a fica bloqueada (Bloqueador na frente),
## unit_b tem espaço livre e avança. Depois unit_a morre.
## Esperado: só unit_b se move; unit_a desaparece ao morrer; unit_b
## permanece intacta.
static func _test_duplicate_card_name_move_and_death(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var blocker := CombatUnit.new(_card("Bloqueador"), 0, 1)
	var unit_a := CombatUnit.new(_card("Duplicado"), 0, 2)
	var unit_b := CombatUnit.new(_card("Duplicado"), 0, 4)
	state.units = [blocker, unit_a, unit_b]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	CombatEngine._movement_phase(state)

	print("  [1] Nomes duplicados: unit_a ficou bloqueada na Posição 2 (esperado: true)? %s" % str(unit_a.position == 2))
	ctx.check(unit_a.position == 2, "[1] unit_a (bloqueada por 'Bloqueador' na Posição 1) deve permanecer na Posição 2")
	print("  [1] Nomes duplicados: unit_b avançou da Posição 4 para a Posição 3 (esperado: true)? %s (obtido: %d)" % [str(unit_b.position == 3), unit_b.position])
	ctx.check(unit_b.position == 3, "[1] unit_b deve avançar da Posição 4 até a Posição 3 (obtido: %d)" % unit_b.position)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()
	for event: Dictionary in collector.replay_events:
		view._apply_replay_event(event)

	var slot_a: int = 0 * 10 + 2
	var slot_b_new: int = 0 * 10 + 3
	var slot_b_old: int = 0 * 10 + 4

	print("  [2] Replay: unit_a (não se moveu) continua no slot 2 com o unit_id correto? %s" % str(
		view._unit_id_to_slot.get(unit_a.get_instance_id(), -1) == slot_a
	))
	ctx.check(view._unit_id_to_slot.get(unit_a.get_instance_id(), -1) == slot_a, "[2] unit_a não deve ser afetada pelo movimento de unit_b, mesmo com o mesmo card_name")

	print("  [2] Replay: unit_b (moveu) está agora no slot 3 com o unit_id correto? %s" % str(
		view._unit_id_to_slot.get(unit_b.get_instance_id(), -1) == slot_b_new
	))
	ctx.check(view._unit_id_to_slot.get(unit_b.get_instance_id(), -1) == slot_b_new, "[2] unit_b deve ser localizada pelo unit_id no slot novo (Posição 3), não pelo card_name")

	print("  [2] Replay: slot antigo de unit_b (4) ficou vazio (sem widget fantasma)? %s" % str(not view._live_board.has(slot_b_old)))
	ctx.check(not view._live_board.has(slot_b_old), "[2] O slot de origem de unit_b deve ficar vazio depois do movimento")

	# unit_a morre — deve desaparecer do tabuleiro; unit_b não deve ser afetada.
	_publish_death(state, unit_a)
	view._apply_replay_event(collector.replay_events[collector.replay_events.size() - 1])

	print("  [3] Morte: unit_a some do tabuleiro visual (slot 2 vazio)? %s" % str(not view._live_board.has(slot_a)))
	ctx.check(not view._live_board.has(slot_a), "[3] unit_a deve deixar de ocupar visualmente o slot 2 depois de morrer (nunca 'carta fantasma' escurecida)")
	ctx.check(not view._unit_id_to_slot.has(unit_a.get_instance_id()), "[3] unit_a não deve mais aparecer no índice unit_id->slot depois de morrer")

	print("  [3] Morte: unit_b permanece correta no slot 3 (não afetada pela morte de unit_a, mesmo card_name)? %s" % str(
		view._live_board.get(slot_b_new, {}).get("unit_id") == unit_b.get_instance_id()
	))
	ctx.check(view._live_board.get(slot_b_new, {}).get("unit_id") == unit_b.get_instance_id(), "[3] unit_b deve continuar correta no slot 3 depois da morte de unit_a")

	view.free()


## Cenário do pedido (seções 7/8): uma unidade em CADA lado atravessa
## várias posições numa única Fase de Movimento (9 -> ... -> 3). Cada
## UNIT_MOVED precisa carregar o MESMO unit_id, e nenhum slot
## intermediário pode ficar com um widget fantasma.
static func _test_multi_step_movement_both_sides(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()

	var fix_0_1 := CombatUnit.new(_card("Fix-0-1"), 0, 1)
	var fix_0_2 := CombatUnit.new(_card("Fix-0-2"), 0, 2)
	var mover_0 := CombatUnit.new(_card("Mover-0"), 0, 9)

	var fix_1_1 := CombatUnit.new(_card("Fix-1-1"), 1, 1)
	var fix_1_2 := CombatUnit.new(_card("Fix-1-2"), 1, 2)
	var mover_1 := CombatUnit.new(_card("Mover-1"), 1, 9)

	state.units = [fix_0_1, fix_0_2, mover_0, fix_1_1, fix_1_2, mover_1]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	CombatEngine._movement_phase(state)

	print("  [4] Side 0: Mover-0 atravessou 9 -> 3 numa única Fase (esperado: true)? %s (obtido: %d)" % [str(mover_0.position == 3), mover_0.position])
	ctx.check(mover_0.position == 3, "[4] Mover-0 (Side 0) deve avançar de 9 até 3, parado pelo bloqueador fixo na Posição 2 (obtido: %d)" % mover_0.position)
	print("  [4] Side 1: Mover-1 atravessou 9 -> 3 numa única Fase (esperado: true)? %s (obtido: %d)" % [str(mover_1.position == 3), mover_1.position])
	ctx.check(mover_1.position == 3, "[4] Mover-1 (Side 1) deve avançar de 9 até 3, independentemente do Side 0 (obtido: %d)" % mover_1.position)

	var move_events_side_0: Array = collector.replay_events.filter(func(e): return e["kind"] == "move" and e["side"] == 0)
	var move_events_side_1: Array = collector.replay_events.filter(func(e): return e["kind"] == "move" and e["side"] == 1)

	print("  [5] Side 0 produziu 6 eventos UNIT_MOVED (9->8->7->6->5->4->3), todos com o MESMO unit_id? %s (%d eventos)" % [
		str(move_events_side_0.size() == 6), move_events_side_0.size()
	])
	ctx.check(move_events_side_0.size() == 6, "[5] Mover-0 deve gerar exatamente 6 eventos UNIT_MOVED (um por passo, 9->3)")
	var side_0_to_positions: Array = move_events_side_0.map(func(e): return e["to_position"])
	ctx.check(side_0_to_positions == [8, 7, 6, 5, 4, 3], "[5] Side 0: to_position deve seguir a ordem exata 8,7,6,5,4,3 (obtido: %s)" % str(side_0_to_positions))
	var side_0_unit_ids: Array = move_events_side_0.map(func(e): return e["unit_id"])
	ctx.check(side_0_unit_ids.all(func(id): return id == mover_0.get_instance_id()), "[5] Todos os eventos UNIT_MOVED do Side 0 devem carregar o unit_id de Mover-0, nunca variar entre passos")

	print("  [5] Side 1 produziu 6 eventos UNIT_MOVED, todos com o MESMO unit_id? %s (%d eventos)" % [
		str(move_events_side_1.size() == 6), move_events_side_1.size()
	])
	ctx.check(move_events_side_1.size() == 6, "[5] Mover-1 deve gerar exatamente 6 eventos UNIT_MOVED (um por passo, 9->3)")
	var side_1_unit_ids: Array = move_events_side_1.map(func(e): return e["unit_id"])
	ctx.check(side_1_unit_ids.all(func(id): return id == mover_1.get_instance_id()), "[5] Todos os eventos UNIT_MOVED do Side 1 devem carregar o unit_id de Mover-1, nunca variar entre passos")

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()
	for event: Dictionary in collector.replay_events:
		view._apply_replay_event(event)

	# Nenhum slot intermediário (4-9) pode ter sobrado com widget fantasma.
	var ghost_found: bool = false
	for side in [0, 1]:
		for position in [4, 5, 6, 7, 8, 9]:
			if view._live_board.has(side * 10 + position):
				ghost_found = true
	print("  [6] Nenhum slot intermediário (4-9, dos dois lados) ficou com widget fantasma? %s" % str(not ghost_found))
	ctx.check(not ghost_found, "[6] Movimento multi-passo não deve deixar nenhum slot intermediário ocupado")

	ctx.check(view._unit_id_to_slot.get(mover_0.get_instance_id(), -1) == 0 * 10 + 3, "[6] Mover-0 deve estar indexado exatamente no slot final (Side 0, Posição 3)")
	ctx.check(view._unit_id_to_slot.get(mover_1.get_instance_id(), -1) == 1 * 10 + 3, "[6] Mover-1 deve estar indexado exatamente no slot final (Side 1, Posição 3)")

	# Nenhuma unidade duplicada: exatamente 1 entrada em _live_board por unit_id de mover.
	var mover_0_entries: int = 0
	var mover_1_entries: int = 0
	for entry: Dictionary in view._live_board.values():
		if entry.get("unit_id") == mover_0.get_instance_id():
			mover_0_entries += 1
		if entry.get("unit_id") == mover_1.get_instance_id():
			mover_1_entries += 1
	print("  [6] Mover-0 aparece em exatamente 1 slot (sem duplicação)? %s | Mover-1? %s" % [str(mover_0_entries == 1), str(mover_1_entries == 1)])
	ctx.check(mover_0_entries == 1, "[6] Mover-0 não deve aparecer duplicado em mais de um slot visual")
	ctx.check(mover_1_entries == 1, "[6] Mover-1 não deve aparecer duplicado em mais de um slot visual")

	view.free()


## Cenário do pedido (seção 9): A morre, B ocupa a posição liberada, C
## ocupa a posição liberada por B — tudo dentro da mesma Fase de
## Movimento seguinte à morte.
static func _test_death_frees_slot_for_cascading_movement(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	# "Cascata-Fix" na Posição 1: sem ela, a compactação da fila única
	# (COMBAT_RULES.md 5.2.1, já validada por
	# test_movement_sequence_compaction.gd) levaria B e C até as
	# Posições 1/2 — comportamento correto do motor, mas não o cenário
	# pedido aqui (B fica exatamente na posição de A, C fica exatamente
	# na posição antiga de B). A Posição 1 é a única genuinamente fixa
	# nesta sequência (nunca tem "frente"), por isso ancora o teste.
	var fix := CombatUnit.new(_card("Cascata-Fix"), 0, 1)
	var unit_a := CombatUnit.new(_card("Cascata-A"), 0, 2)
	var unit_b := CombatUnit.new(_card("Cascata-B"), 0, 3)
	var unit_c := CombatUnit.new(_card("Cascata-C"), 0, 4)
	state.units = [fix, unit_a, unit_b, unit_c]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	# A morre (evento aplicado imediatamente, como qualquer outro).
	_publish_death(state, unit_a)
	view._apply_replay_event(collector.replay_events[collector.replay_events.size() - 1])

	print("  [7] Morte+Movimento: A desaparece do tabuleiro visual assim que morre? %s" % str(not view._live_board.has(0 * 10 + 2)))
	ctx.check(not view._live_board.has(0 * 10 + 2), "[7] A deve desaparecer do slot 2 imediatamente após a morte")

	# Fase de Movimento seguinte: B (3->2) e C (4->3) cascateiam na posição liberada por A.
	CombatEngine._movement_phase(state)
	print("  [7] B ocupou a posição liberada por A (esperado: 2)? %s (obtido: %d)" % [str(unit_b.position == 2), unit_b.position])
	ctx.check(unit_b.position == 2, "[7] B deve avançar para a Posição 2, liberada pela morte de A (obtido: %d)" % unit_b.position)
	print("  [7] C ocupou a posição liberada por B (esperado: 3)? %s (obtido: %d)" % [str(unit_c.position == 3), unit_c.position])
	ctx.check(unit_c.position == 3, "[7] C deve avançar para a Posição 3, liberada por B (obtido: %d)" % unit_c.position)

	for event: Dictionary in collector.replay_events:
		if event["kind"] == "move":
			view._apply_replay_event(event)

	print("  [8] Replay final: slot 2 tem B, slot 3 tem C, nenhum slot com A, nenhuma duplicação? %s" % str(
		view._live_board.get(0 * 10 + 2, {}).get("unit_id") == unit_b.get_instance_id()
		and view._live_board.get(0 * 10 + 3, {}).get("unit_id") == unit_c.get_instance_id()
		and not view._live_board.has(0 * 10 + 4)
	))
	ctx.check(view._live_board.get(0 * 10 + 2, {}).get("unit_id") == unit_b.get_instance_id(), "[8] B deve estar corretamente no slot 2 depois do replay completo")
	ctx.check(view._live_board.get(0 * 10 + 3, {}).get("unit_id") == unit_c.get_instance_id(), "[8] C deve estar corretamente no slot 3 depois do replay completo")
	ctx.check(not view._live_board.has(0 * 10 + 4), "[8] O slot de origem de C (4) deve ficar vazio depois do replay completo")
	ctx.check(not view._unit_id_to_slot.has(unit_a.get_instance_id()), "[8] A não deve deixar nenhum rastro no índice unit_id->slot depois do replay completo")

	view.free()
