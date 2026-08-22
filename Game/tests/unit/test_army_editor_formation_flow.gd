class_name TestArmyEditorFormationFlow
extends RefCounted
## TestArmyEditorFormationFlow (F-045)
##
## F-044 identificou que army_editor_panel.gd (a UI real de edição de
## Formação) não tinha nenhuma suíte própria — só o modelo de dados
## subjacente (Army.formations/get_formation()) era testado. Este
## arquivo fecha essa lacuna chamando os MÉTODOS REAIS do painel
## diretamente (mesmo padrão já usado em todo o projeto para métodos
## prefixados com "_" — GDScript não impõe private de verdade), sem
## precisar instanciar a cena na SceneTree: nenhum método chamado aqui
## (_build_static_structure/_start_formation_edit_mode/
## _on_slot_card_selected/_on_concluir_pressed/_on_formation_tab_pressed)
## referencia get_tree() — só _ready() em si referencia KingdomState.is_initialized,
## e este teste chama os métodos na mesma ordem que _ready() chamaria,
## pulando apenas essa checagem (o Autoload KingdomState já está
## disponível independente de estar na árvore).
##
## Objetivo central (pedido explícito do F-045): confirmar que a
## Formação realmente aplicada por _on_concluir_pressed() é EXATAMENTE
## a que chega ao CombatEngine — não apenas que o modelo de dados
## Army.formations está correto isoladamente (isso já era testado).

static func _names(cards: Array[CardResource]) -> Array[String]:
	var result: Array[String] = []
	for card: CardResource in cards:
		result.append(card.card_name)
	return result


## Exército real de 9 cartas distintas (roster oficial do Starter
## Império, via StarterKitResolver — nunca cartas inventadas), sem
## tocar KingdomState.kingdom.armies (o Editor só precisa do objeto
## Army em si, nunca precisa estar "no" Reino pra ser editado aqui).
static func _build_test_army() -> Army:
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	return army


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-045] Validando army_editor_panel.gd com execução real dos métodos do painel...")

	_test_a_swap_and_save_updates_army_cards(ctx)
	_test_b_formation_switch_isolated_between_tabs(ctx)
	_test_c_saved_formation_reaches_combat_engine(ctx)
	_test_d_reopening_editor_recovers_saved_formations(ctx)

	return true


## A: abrir o Editor num Exército existente, trocar a posição de duas
## cartas (mesmo método que o dropdown de posição chama de verdade) e
## confirmar que "Confirmar Exército" grava isso em army.cards.
static func _test_a_swap_and_save_updates_army_cards(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = false
	panel._build_static_structure()
	panel._start_formation_edit_mode()

	print("  [A1] Formação 'α' inicial = ordem atual de army.cards? %s" % str(_names(panel._formation_cards["α"]) == original_order))
	ctx.check(_names(panel._formation_cards["α"]) == original_order, "[A1] Ao abrir o Editor num Exército existente, a Formação α deve começar exatamente com a ordem atual de army.cards")

	# Troca a Posição 1 (índice 0) pela Posição 9 (índice 8) — mesmo
	# método que o OptionButton de cada slot chama de verdade.
	panel._on_slot_card_selected(8, 0)
	var expected_after_swap: Array[String] = original_order.duplicate()
	var tmp: String = expected_after_swap[0]
	expected_after_swap[0] = expected_after_swap[8]
	expected_after_swap[8] = tmp

	print("  [A2] Após trocar Posição 1 <-> 9: %s (esperado: %s)" % [str(_names(panel._formation_cards["α"])), str(expected_after_swap)])
	ctx.check(_names(panel._formation_cards["α"]) == expected_after_swap, "[A2] Trocar de posição via _on_slot_card_selected() deve atualizar _formation_cards corretamente (swap completo, sem duplicar nem perder carta)")

	panel._on_concluir_pressed()
	print("  [A3] Após 'Confirmar Exército', army.cards reflete a troca? %s" % str(_names(army.cards) == expected_after_swap))
	ctx.check(_names(army.cards) == expected_after_swap, "[A3] _on_concluir_pressed() deve gravar a Formação α editada de volta em army.cards")
	panel.free()


## B: com 5 Formações habilitadas (caso real do PvE), editar a
## Formação "β" não pode afetar "α", e vice-versa.
static func _test_b_formation_switch_isolated_between_tabs(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = false
	panel.formation_count = 5
	panel._build_static_structure()
	panel._start_formation_edit_mode()

	panel._on_formation_tab_pressed("β")
	ctx.check(panel._current_formation == "β", "[B1] Trocar de aba deve atualizar _current_formation")
	panel._on_slot_card_selected(4, 1)  # troca Posição 2 <-> 5 SÓ em β

	var alpha_untouched: bool = _names(panel._formation_cards["α"]) == original_order
	print("  [B1] Editando 'β' -> 'α' permanece intocada? %s" % str(alpha_untouched))
	ctx.check(alpha_untouched, "[B1] Editar a Formação β não deve alterar a Formação α (são cópias independentes)")

	panel._on_formation_tab_pressed("α")
	var alpha_still_original: bool = _names(panel._formation_cards["α"]) == original_order
	ctx.check(alpha_still_original, "[B2] Voltar para a aba 'α' deve mostrar a Formação α original, sem vestígio da edição feita em β")

	panel._on_concluir_pressed()
	var beta_saved: bool = army.formations.has("β") and _names(army.formations["β"]) != original_order
	print("  [B3] army.formations['β'] foi salva com a troca, e army.cards (α) permanece a original? %s / %s" % [str(beta_saved), str(_names(army.cards) == original_order)])
	ctx.check(beta_saved, "[B3] A troca feita em β deve ser salva em army.formations['β']")
	ctx.check(_names(army.cards) == original_order, "[B3] army.cards (Formação α) não deve ser afetada por uma edição feita só em β")
	panel.free()


## C — O TESTE MAIS IMPORTANTE DESTA SUÍTE: a Formação salva pelo
## Editor precisa ser EXATAMENTE a que chega ao CombatEngine, posição
## por posição, numa batalha real executada de ponta a ponta.
static func _test_c_saved_formation_reaches_combat_engine(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()
	var original_order: Array[String] = _names(army.cards)

	var panel := ArmyEditorPanel.new()
	panel.existing_army = army
	panel.editing_composition = false
	panel._build_static_structure()
	panel._start_formation_edit_mode()

	# Uma sequência de trocas não-trivial, para não coincidir por acaso
	# com a ordem original em nenhuma posição.
	panel._on_slot_card_selected(8, 0)  # 1 <-> 9
	panel._on_slot_card_selected(6, 1)  # 2 <-> 7
	panel._on_slot_card_selected(4, 2)  # 3 <-> 5
	var expected_order: Array[String] = _names(panel._formation_cards["α"])
	panel._on_concluir_pressed()

	# Exército inimigo qualquer, real e válido (Starter Natureza), só
	# para completar os dois lados exigidos por CombatEngine.initialize().
	var enemy_option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[1]
	var enemy_army := Army.new()
	enemy_army.commander = enemy_option["commander"]
	enemy_army.cards = (enemy_option["cards"] as Array[CardResource]).duplicate()

	var state: CombatState = CombatEngine.initialize(army, enemy_army, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 42)

	var all_positions_match: bool = true
	for i in range(9):
		var position: int = i + 1
		var unit: CombatUnit = state.unit_at(0, position)
		var actual_name: String = unit.card.card_name if unit != null else "<vazio>"
		if actual_name != expected_order[i]:
			all_positions_match = false
			print("  [C] MISMATCH na Posição %d: CombatEngine tem '%s', Editor salvou '%s'" % [position, actual_name, expected_order[i]])

	print("  [C] Todas as 9 posições no CombatEngine correspondem exatamente à Formação salva pelo Editor? %s" % str(all_positions_match))
	ctx.check(all_positions_match, "[C] A Formação exatamente como o jogador a deixou no Editor (após as trocas e 'Confirmar Exército') deve corresponder posição-por-posição ao que CombatEngine.initialize() realmente usa em combate")
	panel.free()


## D: reabrir o Editor no MESMO Exército (já com α e β salvas por um
## uso anterior) deve recuperar essas Formações, não resetar para a
## ordem original.
static func _test_d_reopening_editor_recovers_saved_formations(ctx: TestRunner.Context) -> void:
	var army: Army = _build_test_army()

	var panel1 := ArmyEditorPanel.new()
	panel1.existing_army = army
	panel1.editing_composition = false
	panel1.formation_count = 5
	panel1._build_static_structure()
	panel1._start_formation_edit_mode()
	panel1._on_slot_card_selected(8, 0)  # edita α
	panel1._on_formation_tab_pressed("β")
	panel1._on_slot_card_selected(4, 1)  # edita β
	var saved_alpha: Array[String] = _names(panel1._formation_cards["α"])
	var saved_beta: Array[String] = _names(panel1._formation_cards["β"])
	panel1._on_concluir_pressed()

	# Reabre um Editor NOVO no mesmo Exército — simula o jogador saindo
	# e voltando à tela de edição depois.
	var panel2 := ArmyEditorPanel.new()
	panel2.existing_army = army
	panel2.editing_composition = false
	panel2.formation_count = 5
	panel2._build_static_structure()
	panel2._start_formation_edit_mode()

	var alpha_recovered: bool = _names(panel2._formation_cards["α"]) == saved_alpha
	var beta_recovered: bool = _names(panel2._formation_cards["β"]) == saved_beta
	print("  [D] Reabrir o Editor recupera α salva? %s | recupera β salva? %s" % [str(alpha_recovered), str(beta_recovered)])
	ctx.check(alpha_recovered, "[D] Reabrir o Editor no mesmo Exército deve recuperar a Formação α salva anteriormente, não resetar")
	ctx.check(beta_recovered, "[D] Reabrir o Editor no mesmo Exército deve recuperar a Formação β salva anteriormente, não resetar")
	panel1.free()
	panel2.free()
