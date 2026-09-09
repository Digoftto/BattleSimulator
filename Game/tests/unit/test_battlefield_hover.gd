class_name TestBattlefieldHover
extends RefCounted
## TestBattlefieldHover (FASE 10-11, 2026-09-04; reescopado na FASE 12)
##
## FASE 12 — reescopo explícito do usuário: "sinais luminosos nos
## hotspots" NUNCA se referia ao Battlefield — o brilho (antes
## battle_hotspot_glow.gd) foi REMOVIDO por completo do Campo de Prova
## nesta tarefa (agora vive só na Cidade, ver test_city_hotspot_glow.gd
## e hotspot_glow.gd). Este arquivo substitui test_hover_hotspot_glow.gd
## (Fase 10/11, inteiramente sobre o glow do Battlefield, removido) e
## cobre os itens 1-6 dos "TESTES DE LÓGICA" desta tarefa que ainda são
## sobre o Battlefield: nenhum glow criado/apresentado nos slots (1),
## hotspots continuam funcionando (2, já coberto em profundidade por
## test_battle_hover_preview.gd — checagem leve aqui), hover continua
## funcionando (3, idem), popup permanece no canto superior esquerdo
## (4, idem, checagem leve aqui), popup ~75% do tamanho anterior (5,
## NOVO), dados dinâmicos corretos (6, idem, checagem leve aqui).
## Mantém também a checagem estrutural de mouse_filter de BattleCardView
## (causa raiz da Fase 10) e a regressão de Battle Art continuar IGNORE.

const ReplayCollectorScript = preload("res://engine/combat/combat_replay_collector.gd")
const ReplayViewScript = preload("res://scenes/combat/combat_replay_view.gd")
const BattleCardViewScript = preload("res://engine/presentation/battle_card_view.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[FASE 12] Validando que o Battlefield NÃO tem mais glow, hover/popup continuam corretos, popup ~75% do tamanho anterior...")
	_test_1_battlefield_nao_cria_glow(ctx)
	_test_2_hotspots_continuam_funcionando(ctx)
	_test_3_hover_continua_funcionando(ctx)
	_test_4_popup_permanece_no_canto_superior_esquerdo(ctx)
	_test_5_popup_aproximadamente_75_porcento_do_tamanho_anterior(ctx)
	_test_6_dados_dinamicos_continuam_corretos(ctx)
	_test_7_battle_card_view_internals_sao_ignore(ctx)
	_test_8_battle_art_continua_ignore(ctx)
	return true


static func _card(name_value: String, card_class: String, atk: int = 50, hp: int = 100, esc: int = 20) -> CardResource:
	return TestMovementRules._build_combat_card(name_value, card_class, atk, hp, esc)


static func _new_view() -> Control:
	var view = ReplayViewScript.new()
	view._build_static_structure()
	return view


## TESTE 1 (o ponto central desta tarefa): NENHUM dos 18 slots reais do
## Battlefield cria ou apresenta um HotspotGlow — "Battlefield: hotspot
## lógico = SIM | BattleCardView hover = SIM | glow luminoso = NÃO"
## (pedido explícito, textual).
static func _test_1_battlefield_nao_cria_glow(ctx: TestRunner.Context) -> void:
	var view = _new_view()
	var total: int = 0
	var with_glow: int = 0
	for side in [0, 1]:
		for position in range(1, 10):
			var key: int = side * 10 + position
			total += 1
			var widgets: Dictionary = view._position_widgets.get(key, {})
			if widgets.has("glow"):
				with_glow += 1

	print("  [1] Dos %d slots reais do Battlefield, quantos têm 'glow' registrado? %d (esperado 0)" % [total, with_glow])
	ctx.check(with_glow == 0, "[1] Nenhum dos 18 slots do Battlefield pode ter um HotspotGlow — o brilho foi removido do Campo de Prova nesta tarefa")
	ctx.check(total == 18, "[1] Pré-condição: os 18 slots reais devem existir")

	view.free()


## TESTE 2 (regressão leve — cobertura profunda em test_battle_hover_preview.gd):
## o hotspot lógico (BattleCardView compacta) continua recebendo mouse
## normalmente, sem o glow.
static func _test_2_hotspots_continuam_funcionando(ctx: TestRunner.Context) -> void:
	var unit := CombatUnit.new(_card("Hotspot-Continua", "Corpo a Corpo"), 0, 1)
	var state := CombatState.new()
	state.units = [unit]
	var collector := ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.combat_state = state
	view.replay_collector = collector
	view._apply_initial_board()

	var widget = view._position_widgets[0 * 10 + 1]["view"]
	print("  [2] O widget do slot continua com mouse_filter=STOP (hotspot lógico intacto)? %s" % str(widget.mouse_filter == Control.MOUSE_FILTER_STOP))
	ctx.check(widget.mouse_filter == Control.MOUSE_FILTER_STOP, "[2] O hotspot lógico (BattleCardView compacta) deve continuar recebendo mouse normalmente, sem o glow")

	view.free()


## TESTE 3 (regressão leve): hover continua abrindo o popup com os
## dados reais da unidade.
static func _test_3_hover_continua_funcionando(ctx: TestRunner.Context) -> void:
	var unit := CombatUnit.new(_card("Hover-Continua", "Corpo a Corpo", 50, 88, 15), 0, 1)
	var state := CombatState.new()
	state.units = [unit]
	var collector := ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.combat_state = state
	view.replay_collector = collector
	view._apply_initial_board()

	view._on_card_mouse_entered(0 * 10 + 1)
	print("  [3] Hover abre o popup com a carta/HP corretos? visível=%s HP=%d (esperado 88)" % [str(view._hover_preview_wrapper.visible), view._hover_preview._hp_label.text.to_int()])
	ctx.check(view._hover_preview_wrapper.visible, "[3] Hover deve continuar abrindo o popup normalmente")
	ctx.check(view._hover_preview._hp_label.text.to_int() == 88, "[3] O popup deve continuar mostrando o HP real da unidade")

	view.free()


## TESTE 4 (regressão leve — cobertura profunda em
## test_battle_hover_preview.gd Teste 13): popup ancorado no canto
## superior esquerdo.
static func _test_4_popup_permanece_no_canto_superior_esquerdo(ctx: TestRunner.Context) -> void:
	var view = _new_view()
	print("  [4] Popup ancorado em (0,0)? left=%s top=%s" % [str(view._hover_preview_wrapper.anchor_left), str(view._hover_preview_wrapper.anchor_top)])
	ctx.check(view._hover_preview_wrapper.anchor_left == 0.0, "[4] O popup deve continuar ancorado no canto superior esquerdo (anchor_left=0)")
	ctx.check(view._hover_preview_wrapper.anchor_top == 0.0, "[4] O popup deve continuar ancorado no canto superior esquerdo (anchor_top=0)")
	view.free()


## TESTE 5 (NOVO — o ponto central da correção de tamanho): o popup
## deve medir ~75% do tamanho anterior (240px de largura -> 180px).
static func _test_5_popup_aproximadamente_75_porcento_do_tamanho_anterior(ctx: TestRunner.Context) -> void:
	var view = _new_view()
	var previous_width_px: float = 240.0
	var expected_width_px: float = previous_width_px * 0.75
	var actual_width_px: float = view.HOVER_PREVIEW_WIDTH_PX
	var ratio: float = actual_width_px / previous_width_px

	print("  [5] Largura anterior=%.1fpx | nova largura=%.1fpx | razão=%.3f (alvo ~0.75, faixa aceita 0.70-0.80)" % [previous_width_px, actual_width_px, ratio])
	ctx.check(is_equal_approx(actual_width_px, expected_width_px), "[5] A largura do popup deve ser exatamente 75%% da anterior (240px -> 180px)")
	ctx.check(ratio >= 0.70 and ratio <= 0.80, "[5] A razão nova/anterior deve cair entre 70%% e 80%%, conforme pedido")

	# Proporção preservada: a altura do wrapper é sempre largura /
	# CARD_ASPECT_RATIO (mesma fórmula de sempre, nunca alterada) —
	# garante que a carta nunca fica deformada, só menor como um todo.
	var expected_height_px: float = actual_width_px / BattleCardViewScript.CARD_ASPECT_RATIO
	var actual_height_px: float = view._hover_preview_wrapper.custom_minimum_size.y
	print("  [5] Altura esperada (proporção preservada)=%.2fpx | altura real do wrapper=%.2fpx" % [expected_height_px, actual_height_px])
	ctx.check(is_equal_approx(actual_height_px, expected_height_px), "[5] A altura do popup deve escalar na MESMA proporção (CARD_ASPECT_RATIO) — nunca deformar a carta")

	view.free()


## TESTE 6 (regressão leve — cobertura profunda em test_battle_hover_preview.gd):
## dados dinâmicos (HP) continuam corretos após um evento real.
static func _test_6_dados_dinamicos_continuam_corretos(ctx: TestRunner.Context) -> void:
	var attacker := CombatUnit.new(_card("F12-Atacante", "Corpo a Corpo", 50, 100, 0), 0, 1)
	var target := CombatUnit.new(_card("F12-Alvo", "Corpo a Corpo", 40, 100, 20), 1, 1)
	var state := CombatState.new()
	state.units = [attacker, target]
	var collector := ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.combat_state = state
	view.replay_collector = collector
	view._apply_initial_board()

	target.current_hp = 61
	var attack_ctx := CombatContext.new()
	attack_ctx.state = state
	attack_ctx.turn = 1
	attack_ctx.side = attacker.side
	attack_ctx.attacker = attacker
	attack_ctx.target = target
	attack_ctx.damage_dealt = 39
	attack_ctx.damage_absorbed_by_shield = 0
	attack_ctx.damage_applied_to_hp = 39
	state.event_bus.publish(CombatEventType.Type.AFTER_ATTACK, attack_ctx)
	view._apply_replay_event(collector.replay_events[0])

	view._on_card_mouse_entered(1 * 10 + 1)
	print("  [6] Após dano real, popup mostra HP=%d (esperado 61)" % view._hover_preview._hp_label.text.to_int())
	ctx.check(view._hover_preview._hp_label.text.to_int() == 61, "[6] Dados dinâmicos (HP) devem continuar corretos após a remoção do glow")

	view.free()


## TESTE 7 (causa raiz da Fase 10, regressão): todo elemento interno de
## BattleCardView continua IGNORE.
static func _test_7_battle_card_view_internals_sao_ignore(ctx: TestRunner.Context) -> void:
	var view = BattleCardViewScript.new()
	view.set_card(_card("Hotspot-Fix", "Corpo a Corpo"))

	ctx.check(view.portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[7] portrait (TextureRect) continua IGNORE")
	var aspect: Control = view.get_child(0)
	ctx.check(aspect.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[7] aspect continua IGNORE")
	var card_body: Control = aspect.get_child(0)
	ctx.check(card_body.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[7] card_body continua IGNORE")

	var label_count: int = 0
	var ignore_count: int = 0
	for child: Node in card_body.get_children():
		if child is Label:
			label_count += 1
			if child.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				ignore_count += 1
	print("  [7] Labels internos (%d) todos IGNORE? %d/%d" % [label_count, ignore_count, label_count])
	ctx.check(label_count > 0 and ignore_count == label_count, "[7] Todos os Labels internos continuam IGNORE")


## TESTE 8 (regressão): Battle Art continua IGNORE — nunca tocado nesta
## correção.
static func _test_8_battle_art_continua_ignore(ctx: TestRunner.Context) -> void:
	var layer = preload("res://engine/presentation/battle_unit_art_layer.gd").new()
	layer._ready()
	print("  [8] BattleUnitArtLayer continua mouse_filter=IGNORE? %s" % str(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE))
	ctx.check(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[8] Battle Art (camada raiz) nunca pode interferir no input")
