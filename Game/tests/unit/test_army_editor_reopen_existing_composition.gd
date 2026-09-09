class_name TestArmyEditorReopenExistingComposition
extends RefCounted
## TestArmyEditorReopenExistingComposition (F-021.1.2)
##
## F-021 (auditoria) confirmou um bug real: abrir "Editar Exército" num
## Exército já existente (editing_composition=true, o caminho usado por
## exercitos_panel.gd ao clicar "Editar", DIFERENTE do modo
## _start_formation_edit_mode() que test_army_editor_formation_flow.gd
## já cobria com editing_composition=false em todos os seus 4 testes —
## esse branch nunca tinha teste algum) mostrava a Formação vazia: a
## grade lê _current_grid_source(), que retorna _phase1_slots enquanto
## _army == null (toda a edição pré-commit), e _ready() só populava
## _selected_cards, nunca _phase1_slots. Correção: semear
## _phase1_slots = existing_army.cards.duplicate() no mesmo branch
## (mesmo padrão já usado em _on_random_army_pressed()). Esta suíte
## prova que o bug não volta.

static func _names(cards: Array[CardResource]) -> Array[String]:
	var result: Array[String] = []
	for card: CardResource in cards:
		result.append(card.card_name if card != null else "<vazio>")
	return result


static func _build_test_army() -> Army:
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	return army


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021.1.2] Validando que 'Editar Exército' (editing_composition=true) carrega a Formação existente...")

	_test_a_grid_shows_real_formation_on_open(ctx)
	_test_b_swap_preserves_other_eight_cards(ctx)
	_test_c_save_persists_and_cancel_does_not(ctx)

	return true


## A: abrir o Editor num Exército existente com editing_composition=true
## (o caminho real de exercitos_panel.gd "Editar") deve mostrar
## IMEDIATAMENTE as 9 cartas reais na grade — nunca 9 posições vazias.
static func _test_a_grid_shows_real_formation_on_open(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = true
	panel._build_static_structure()
	panel._selected_commander = army.commander
	panel._selected_cards = army.cards.duplicate()
	panel._phase1_slots = army.cards.duplicate()

	var grid_shown: Array[String] = _names(panel._current_grid_source())
	print("  [A] Grade mostrada ao abrir == Formação real do Exército (%s)? %s" % [str(original_order), str(grid_shown == original_order)])
	ctx.check(grid_shown == original_order, "[A] Ao abrir 'Editar Exército', a grade deve mostrar as 9 cartas reais do Exército — nunca 9 posições vazias (bug F-021)")
	for card: CardResource in panel._current_grid_source():
		ctx.check(card != null, "[A] Nenhuma posição da grade deve ficar vazia ao abrir um Exército de 9 cartas já completo")
	panel.free()


## B: trocar a Posição 1 pela Posição 9 (mesmo mecanismo de
## _handle_drop_on_slot() usado pelo Drag-and-Drop real) deve alterar
## SÓ essas duas posições, preservando as outras 7 intactas.
static func _test_b_swap_preserves_other_eight_cards(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = true
	panel._build_static_structure()
	panel._selected_commander = army.commander
	panel._selected_cards = army.cards.duplicate()
	panel._phase1_slots = army.cards.duplicate()

	panel._handle_drop_on_slot({"source": "slot", "slot_index": 0}, 8)

	var expected: Array[String] = original_order.duplicate()
	var tmp: String = expected[0]
	expected[0] = expected[8]
	expected[8] = tmp

	var after_swap: Array[String] = _names(panel._phase1_slots)
	print("  [B] Após trocar Posição 1 <-> 9: %s (esperado: %s)" % [str(after_swap), str(expected)])
	ctx.check(after_swap == expected, "[B] Trocar duas posições via drag-and-drop real (_handle_drop_on_slot) deve alterar só essas duas, preservando as outras 7 cartas intactas")
	panel.free()


## C: "Salvar Alterações" (_on_montar_pressed, caminho editing_composition)
## deve gravar a troca de volta em army.cards; "Cancelar" nunca deve
## alterar o Exército original.
static func _test_c_save_persists_and_cancel_does_not(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var army: Army = _build_test_army()
	kingdom.armies.append(army)
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = true
	panel._build_static_structure()
	panel._selected_commander = army.commander
	panel._selected_cards = army.cards.duplicate()
	panel._phase1_slots = army.cards.duplicate()

	panel._handle_drop_on_slot({"source": "slot", "slot_index": 0}, 8)
	var expected: Array[String] = original_order.duplicate()
	var tmp: String = expected[0]
	expected[0] = expected[8]
	expected[8] = tmp

	panel._on_montar_pressed()
	panel._on_concluir_pressed()

	var saved_order: Array[String] = _names(army.cards)
	print("  [C1] 'Salvar Alterações' grava a troca em army.cards? %s (obtido: %s)" % [str(saved_order == expected), str(saved_order)])
	ctx.check(saved_order == expected, "[C1] Salvar Alterações deve persistir a Formação editada exatamente como mostrada na grade, em army.cards")
	panel.free()

	# Cancelar: reabre um Editor novo no MESMO Exército (já salvo com a
	# troca acima) e cancela sem confirmar — army.cards não deve mudar
	# além do que já foi salvo em C1.
	var panel2 := ArmyEditorPanel.new()
	panel2.existing_army = army
	panel2.editing_composition = true
	panel2._build_static_structure()
	panel2._selected_commander = army.commander
	panel2._selected_cards = army.cards.duplicate()
	panel2._phase1_slots = army.cards.duplicate()
	panel2._handle_drop_on_slot({"source": "slot", "slot_index": 1}, 2)  # mexe em mais uma troca, mas nunca confirma
	panel2._on_cancel_pressed()

	var after_cancel: Array[String] = _names(army.cards)
	print("  [C2] 'Cancelar' sem confirmar não altera army.cards (permanece %s)? %s" % [str(expected), str(after_cancel == expected)])
	ctx.check(after_cancel == expected, "[C2] Cancelar a edição não deve alterar army.cards além do que já foi salvo por um 'Salvar Alterações' anterior")
	panel2.free()

	KingdomState.kingdom = old_kingdom
