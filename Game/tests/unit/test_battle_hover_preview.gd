class_name TestBattleHoverPreview
extends RefCounted
## TestBattleHoverPreview (FASE 9, 2026-09-04)
##
## Valida o popup de hover GRANDE do Battlefield (CombatReplayView —
## infraestrutura ART-007-v2 já existente, apenas reposicionada nesta
## tarefa: era ancorada num canto fixo, agora acompanha o pelotão real
## via _visual_center_frac(), com posicionamento "inteligente" simples
## de 2 eixos pra nunca sair da tela) — SEM regra de combate nova,
## sempre reaproveitando BattleCardView (nunca um sistema paralelo de
## cartas). Cobre exatamente os 12 itens do pedido: identidade correta
## (1), duas unidades com o mesmo card_name nunca se confundem (2),
## unit_id sobrevive a um movimento (3), HP/ESC dinâmicos refletidos
## (4/5), cura atualiza a leitura (6), morte nunca deixa hover órfão
## (7), Battle Art continua existindo (8), Soldo/Energia nunca
## aparecem — estruturalmente, via has_method() (9/10), dados
## estáticos (Tier/Classe/Tipo) corretos (11), e uma batalha real
## completa sem nenhuma referência órfã (12). Mais 1 teste adicional
## (13) do próprio posicionamento por quadrante, a única lógica nova
## desta tarefa.

const ReplayCollectorScript = preload("res://engine/combat/combat_replay_collector.gd")
const ReplayViewScript = preload("res://scenes/combat/combat_replay_view.gd")
const BattleCardViewScript = preload("res://engine/presentation/battle_card_view.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[FASE 9] Validando o popup de hover grande (BattleCardView completa) do Battlefield...")
	_test_1_hover_identifica_unidade_correta(ctx)
	_test_2_duas_unidades_mesmo_card_name_nao_confundem(ctx)
	_test_3_unidade_movida_continua_identificada_por_unit_id(ctx)
	_test_4_hp_dinamico_refletido(ctx)
	_test_5_esc_dinamico_refletido(ctx)
	_test_6_cura_atualiza_informacao_mostrada(ctx)
	_test_7_unidade_morta_nao_deixa_hover_orfao(ctx)
	_test_8_battle_art_continua_existindo(ctx)
	_test_9_soldo_nao_aparece(ctx)
	_test_10_energia_nao_aparece(ctx)
	_test_11_dados_estaticos_corretos(ctx)
	_test_12_replay_completo_sem_referencias_orfas(ctx)
	_test_13_popup_tem_posicao_fixa_no_canto_superior_esquerdo(ctx)
	return true


static func _card(name_value: String, card_class: String, atk: int = 50, hp: int = 100, esc: int = 20) -> CardResource:
	var card: CardResource = TestMovementRules._build_combat_card(name_value, card_class, atk, hp, esc)
	card.card_type = "Terrestre"
	card.tier = 3
	return card


static func _new_view() -> Control:
	var view = ReplayViewScript.new()
	view._build_static_structure()
	return view


## Monta um CombatState simples (2 unidades distintas), um Collector
## já ligado ao event_bus dele e uma View com o board inicial aplicado
## — reutilizado por quase todos os testes abaixo (nenhuma batalha real
## precisa rodar pra validar hover: os eventos relevantes são
## publicados manualmente, no mesmo formato REAL que CombatEngine
## publica, via o próprio event_bus do CombatState).
static func _build_scenario(units: Array[CombatUnit]) -> Dictionary:
	var state := CombatState.new()
	state.units = units

	var collector := ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.combat_state = state
	view.replay_collector = collector
	view._apply_initial_board()

	return {"state": state, "collector": collector, "view": view}


static func _attack_context(state: CombatState, turn: int, attacker: CombatUnit, target: CombatUnit, dmg: int) -> CombatContext:
	var context := CombatContext.new()
	context.state = state
	context.turn = turn
	context.side = attacker.side
	context.attacker = attacker
	context.target = target
	context.damage_dealt = dmg
	context.damage_absorbed_by_shield = 0
	context.damage_applied_to_hp = dmg
	return context


static func _heal_context(state: CombatState, turn: int, healer: CombatUnit, target: CombatUnit, amount: int) -> CombatContext:
	var context := CombatContext.new()
	context.state = state
	context.turn = turn
	context.side = healer.side
	context.attacker = healer
	context.target = target
	context.position = healer.position
	context.heal_amount = amount
	return context


static func _death_context(state: CombatState, turn: int, unit: CombatUnit) -> CombatContext:
	var context := CombatContext.new()
	context.state = state
	context.turn = turn
	context.attacker = unit
	return context


## TESTE 1: hover sobre o slot correto mostra a carta e os stats REAIS
## daquela unidade — nunca uma cópia estática de catálogo.
static func _test_1_hover_identifica_unidade_correta(ctx: TestRunner.Context) -> void:
	var a := CombatUnit.new(_card("Hover-A", "Corpo a Corpo", 50, 100, 20), 0, 1)
	var b := CombatUnit.new(_card("Hover-B", "À Distância", 40, 80, 5), 0, 2)
	var scenario: Dictionary = _build_scenario([a, b])
	var view = scenario["view"]

	view._on_card_mouse_entered(0 * 10 + 1)

	print("  [1] Hover na Posição 1 mostra a carta correta (Hover-A)? %s | HP=%d ESC=%d (esperado: 100, 20)" % [
		str(view._hover_preview._card == a.card), view._hover_preview._hp_label.text.to_int(), view._hover_preview._esc_label.text.to_int()
	])
	ctx.check(view._hover_preview_wrapper.visible, "[1] O popup de hover deve ficar visível ao entrar no slot")
	ctx.check(view._hover_preview._card == a.card, "[1] O popup deve mostrar exatamente a CardResource da unidade sob o cursor (Hover-A), nunca outra")
	ctx.check(view._hover_preview._hp_label.text.to_int() == 100, "[1] HP mostrado deve ser o HP real da unidade (100)")
	ctx.check(view._hover_preview._esc_label.text.to_int() == 20, "[1] ESC mostrado deve ser o ESC real da unidade (20)")

	view.free()


## TESTE 2: duas unidades com o MESMO card_name (comum em Exércitos
## inimigos gerados) precisam permanecer 100% distinguíveis pelo hover
## — cada slot mostra os stats da SUA PRÓPRIA unidade, nunca uma
## confundida com a outra.
static func _test_2_duas_unidades_mesmo_card_name_nao_confundem(ctx: TestRunner.Context) -> void:
	var card_x := _card("Duplicada", "Corpo a Corpo", 30, 90, 10)
	var card_y := _card("Duplicada", "Corpo a Corpo", 30, 45, 10)
	var x := CombatUnit.new(card_x, 0, 1)
	var y := CombatUnit.new(card_y, 0, 2)
	var scenario: Dictionary = _build_scenario([x, y])
	var view = scenario["view"]

	view._on_card_mouse_entered(0 * 10 + 1)
	var hp_at_slot_1: int = view._hover_preview._hp_label.text.to_int()
	view._on_card_mouse_exited(0 * 10 + 1)
	view._on_card_mouse_entered(0 * 10 + 2)
	var hp_at_slot_2: int = view._hover_preview._hp_label.text.to_int()

	print("  [2] card_name idêntico em 2 unidades — Posição 1 mostra HP=%d (esperado 90), Posição 2 mostra HP=%d (esperado 45)" % [hp_at_slot_1, hp_at_slot_2])
	ctx.check(hp_at_slot_1 == 90, "[2] A Posição 1 deve mostrar o HP da SUA unidade (90), mesmo com card_name duplicado")
	ctx.check(hp_at_slot_2 == 45, "[2] A Posição 2 deve mostrar o HP da SUA unidade (45), nunca herdar o valor da Posição 1")

	view.free()


## TESTE 3: depois de um MOVE real, a mesma unidade (mesmo unit_id)
## continua sendo identificada corretamente na sua NOVA posição — a
## posição de ORIGEM deixa de responder ao hover (slot vazio).
static func _test_3_unidade_movida_continua_identificada_por_unit_id(ctx: TestRunner.Context) -> void:
	var mover := CombatUnit.new(_card("Hover-Movida", "À Distância", 35, 70, 15), 0, 6)
	var scenario: Dictionary = _build_scenario([mover])
	var state: CombatState = scenario["state"]
	var view = scenario["view"]

	mover.position = 4  # simula o motor movendo a unidade (6 -> 4)
	var move_ctx := CombatContext.new()
	move_ctx.state = state
	move_ctx.turn = 1
	move_ctx.attacker = mover
	state.event_bus.publish(CombatEventType.Type.UNIT_MOVED, move_ctx)

	view._apply_replay_event(scenario["collector"].replay_events[0])

	view._on_card_mouse_entered(0 * 10 + 4)
	print("  [3] Após mover 6->4, hover na NOVA posição (4) mostra a mesma unidade (mesmo unit_id)? %s" % str(view._hover_preview._card == mover.card))
	ctx.check(view._hover_preview_wrapper.visible, "[3] O popup deve aparecer ao passar o cursor sobre a NOVA posição da unidade movida"
	)
	ctx.check(view._hover_preview._card == mover.card, "[3] O popup na nova posição deve mostrar a mesma unidade que se moveu")

	view._on_card_mouse_exited(0 * 10 + 4)
	view._on_card_mouse_entered(0 * 10 + 6)
	print("  [3] A posição de ORIGEM (6), agora vazia, não deve mais acionar o hover: %s" % str(not view._hover_preview_wrapper.visible))
	ctx.check(not view._hover_preview_wrapper.visible, "[3] A posição de origem (agora vazia) nunca deve continuar mostrando o popup")

	view.free()


## TESTE 4/5: um evento AFTER_ATTACK real (o mesmo publicado por
## CombatEngine) precisa atualizar HP e ESC mostrados no popup — nunca
## os valores estáticos da carta de catálogo.
static func _test_4_hp_dinamico_refletido(ctx: TestRunner.Context) -> void:
	var attacker := CombatUnit.new(_card("Hover-Atacante", "Corpo a Corpo", 50, 100, 0), 0, 1)
	var target := CombatUnit.new(_card("Hover-Alvo", "Corpo a Corpo", 40, 100, 20), 1, 1)
	var scenario: Dictionary = _build_scenario([attacker, target])
	var state: CombatState = scenario["state"]
	var view = scenario["view"]

	target.current_hp = 63
	var attack_ctx := _attack_context(state, 1, attacker, target, 37)
	state.event_bus.publish(CombatEventType.Type.AFTER_ATTACK, attack_ctx)
	view._apply_replay_event(scenario["collector"].replay_events[0])

	view._on_card_mouse_entered(1 * 10 + 1)
	print("  [4] Após dano real (100->63), o popup de hover mostra HP=%d (esperado 63)" % view._hover_preview._hp_label.text.to_int())
	ctx.check(view._hover_preview._hp_label.text.to_int() == 63, "[4] O popup deve refletir o HP ATUAL (63) após o ataque, nunca o HP máximo original (100)")

	view.free()


static func _test_5_esc_dinamico_refletido(ctx: TestRunner.Context) -> void:
	var attacker := CombatUnit.new(_card("Hover-Atacante-2", "Corpo a Corpo", 50, 100, 0), 0, 1)
	var target := CombatUnit.new(_card("Hover-Alvo-2", "Corpo a Corpo", 40, 100, 20), 1, 1)
	var scenario: Dictionary = _build_scenario([attacker, target])
	var state: CombatState = scenario["state"]
	var view = scenario["view"]

	target.current_esc = 5
	var attack_ctx := _attack_context(state, 1, attacker, target, 15)
	state.event_bus.publish(CombatEventType.Type.AFTER_ATTACK, attack_ctx)
	view._apply_replay_event(scenario["collector"].replay_events[0])

	view._on_card_mouse_entered(1 * 10 + 1)
	print("  [5] Após dano real no Escudo (20->5), o popup de hover mostra ESC=%d (esperado 5)" % view._hover_preview._esc_label.text.to_int())
	ctx.check(view._hover_preview._esc_label.text.to_int() == 5, "[5] O popup deve refletir o ESC ATUAL (5) após o ataque")

	view.free()


## TESTE 6: um evento AFTER_HEAL_PERFORMED real precisa atualizar o HP
## mostrado — nunca ficar preso no valor anterior à cura.
static func _test_6_cura_atualiza_informacao_mostrada(ctx: TestRunner.Context) -> void:
	var healer := CombatUnit.new(_card("Hover-Curandeiro", "Suporte", 20, 90, 10), 0, 5)
	var target := CombatUnit.new(_card("Hover-Curado", "Corpo a Corpo", 50, 100, 0), 0, 1)
	var scenario: Dictionary = _build_scenario([healer, target])
	var state: CombatState = scenario["state"]
	var view = scenario["view"]

	target.current_hp = 72  # dano anterior
	var heal_ctx := _heal_context(state, 1, healer, target, 13)
	target.current_hp = 85  # cura aplicada (72 + 13)
	state.event_bus.publish(CombatEventType.Type.AFTER_HEAL_PERFORMED, heal_ctx)
	view._apply_replay_event(scenario["collector"].replay_events[0])

	view._on_card_mouse_entered(0 * 10 + 1)
	print("  [6] Após cura real (72->85), o popup de hover mostra HP=%d (esperado 85, nunca 72 nem 100)" % view._hover_preview._hp_label.text.to_int())
	ctx.check(view._hover_preview._hp_label.text.to_int() == 85, "[6] O popup deve refletir o HP pós-cura (85), nunca o valor anterior à cura")

	view.free()


## TESTE 7: se a unidade sob o cursor morre, o popup precisa
## desaparecer imediatamente — nunca deixar uma carta "órfã" (de uma
## unidade que não existe mais) visível na tela.
static func _test_7_unidade_morta_nao_deixa_hover_orfao(ctx: TestRunner.Context) -> void:
	var victim := CombatUnit.new(_card("Hover-Vitima", "Corpo a Corpo", 50, 10, 0), 0, 1)
	var scenario: Dictionary = _build_scenario([victim])
	var state: CombatState = scenario["state"]
	var view = scenario["view"]

	view._on_card_mouse_entered(0 * 10 + 1)
	ctx.check(view._hover_preview_wrapper.visible, "[7] Pré-condição: o popup deve estar visível antes da morte")

	var death_ctx := _death_context(state, 1, victim)
	state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)
	view._apply_replay_event(scenario["collector"].replay_events[0])

	print("  [7] Após a morte da unidade sob o cursor, o popup de hover some? %s | _hover_key resetado? %s" % [str(not view._hover_preview_wrapper.visible), str(view._hover_key == -1)])
	ctx.check(not view._hover_preview_wrapper.visible, "[7] O popup de hover NUNCA pode continuar visível para uma unidade que acabou de morrer")
	ctx.check(view._hover_key == -1, "[7] _hover_key deve ser resetado (-1) — nenhuma referência órfã ao slot antigo")

	view.free()


## TESTE 8: a mudança de posicionamento do popup de hover (FASE 9) é
## puramente aditiva — a camada de Battle Art continua registrando e
## rastreando as unidades normalmente, sem nenhuma regressão.
static func _test_8_battle_art_continua_existindo(ctx: TestRunner.Context) -> void:
	var unit := CombatUnit.new(_card("Arqueiro Imperial", "À Distância", 40, 90, 70), 0, 1)
	var scenario: Dictionary = _build_scenario([unit])
	var view = scenario["view"]

	print("  [8] BattleUnitArtLayer continua rastreando a unidade normalmente após o hover? %s" % str(view._unit_art_layer.has_unit(unit.get_instance_id())))
	ctx.check(view._unit_art_layer.has_unit(unit.get_instance_id()), "[8] A camada de Battle Art deve continuar registrando a unidade — o hover é puramente aditivo, nunca substitui ou remove Battle Art")

	view.free()


## TESTE 9/10: Soldo e Energia NUNCA são desenhados pelo popup de hover
## — checagem ESTRUTURAL (a API pública de BattleCardView simplesmente
## não tem esses conceitos), não uma inspeção de texto renderizado.
static func _test_9_soldo_nao_aparece(ctx: TestRunner.Context) -> void:
	print("  [9] BattleCardView não expõe nenhum método relacionado a Soldo? %s" % str(not BattleCardViewScript.new().has_method("set_soldo")))
	ctx.check(not BattleCardViewScript.new().has_method("set_soldo"), "[9] BattleCardView (base do popup de hover) nunca deve expor Soldo")


static func _test_10_energia_nao_aparece(ctx: TestRunner.Context) -> void:
	print("  [10] BattleCardView não expõe nenhum método relacionado a Energia? %s" % str(not BattleCardViewScript.new().has_method("set_energy")))
	ctx.check(not BattleCardViewScript.new().has_method("set_energy"), "[10] BattleCardView (base do popup de hover) nunca deve expor Energia")


## TESTE 11: os dados ESTÁTICOS (Tier/Classe/Tipo) mostrados pelo popup
## são os dados reais da carta — nada inventado, nada de placeholder.
static func _test_11_dados_estaticos_corretos(ctx: TestRunner.Context) -> void:
	var card := _card("Hover-Estatico", "Mago", 60, 80, 10)
	card.tier = 4
	var unit := CombatUnit.new(card, 0, 1)
	var scenario: Dictionary = _build_scenario([unit])
	var view = scenario["view"]

	view._on_card_mouse_entered(0 * 10 + 1)
	print("  [11] Tier mostrado: '%s' (esperado 'T4') | Tipo/Classe mostrado: '%s' (esperado conter 'Mago')" % [view._hover_preview._tier_label.text, view._hover_preview._type_class_label.text])
	ctx.check(view._hover_preview._tier_label.text == "T4", "[11] O Tier mostrado no popup deve ser o Tier real da carta (T4)")
	ctx.check(view._hover_preview._type_class_label.text.contains("Mago"), "[11] A Classe mostrada no popup deve ser a Classe real da carta (Mago)")

	view.free()


## TESTE 12: uma batalha real completa (várias mortes/movimentos) não
## pode deixar NENHUMA referência órfã — nem em _unit_id_to_slot, nem
## um popup de hover preso numa unidade que já não existe mais.
static func _test_12_replay_completo_sem_referencias_orfas(ctx: TestRunner.Context) -> void:
	var army_a := Army.new()
	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Fase 9)"
	commander_a.accumulated_xp = 10000000
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = []
	for i in range(9):
		cards_a.append(_card("F9-A-%d" % (i + 1), "Corpo a Corpo", 25, 45, 5))
	army_a.cards = cards_a

	var army_b := Army.new()
	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Fase 9)"
	commander_b.accumulated_xp = 10000000
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_card("F9-B-%d" % (i + 1), "Corpo a Corpo", 25, 45, 5))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 90909)
	var collector := ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)
	CombatEngine.run(state)

	var view = _new_view()
	view.combat_state = state
	view.replay_collector = collector
	view._apply_initial_board()
	for event: Dictionary in collector.replay_events:
		view._apply_replay_event(event)
		# Simula um jogador passeando o cursor por CADA evento aplicado —
		# se alguma referência ficasse órfã, este loop a exporia.
		var side: int = event.get("side", 0)
		var pos: int = event.get("position", event.get("target_position", event.get("to_position", 1)))
		view._on_card_mouse_entered(side * 10 + pos)

	var eliminated_ids: Array = state.eliminated_units.map(func(u: CombatUnit) -> int: return u.get_instance_id())
	var orphan_slots: Array = view._unit_id_to_slot.keys().filter(func(uid: int) -> bool: return uid in eliminated_ids)

	print("  [12] Batalha real completa (%d eventos, %d eliminados) — nenhum unit_id eliminado permanece em _unit_id_to_slot: %s" % [collector.replay_events.size(), eliminated_ids.size(), str(orphan_slots.is_empty())])
	ctx.check(orphan_slots.is_empty(), "[12] Nenhuma unidade eliminada pode permanecer referenciada em _unit_id_to_slot após o replay completo")

	if view._hover_key != -1:
		var still_alive: bool = not (view._unit_id_to_slot.get(view._hover_key, -1) == -1) or true
		print("  [12] _hover_key final (%d) ainda aponta pra um slot ocupado válido (não travado num fantasma)? %s" % [view._hover_key, str(view._live_board.has(view._hover_key))])
		ctx.check(view._live_board.has(view._hover_key), "[12] Se o popup terminar visível, precisa ser sobre um slot que realmente existe em _live_board")

	view.free()


## TESTE 13 (FASE 11 — reescrito): o popup NÃO depende mais da posição
## do pelotão — fica sempre ancorado no canto superior esquerdo da
## tela (anchors 0,0,0,0 + margem fixa), independente de QUAL side/
## position estiver sob o cursor. Hover em 2 posições bem distantes uma
## da outra deve produzir EXATAMENTE o mesmo retângulo de popup.
static func _test_13_popup_tem_posicao_fixa_no_canto_superior_esquerdo(ctx: TestRunner.Context) -> void:
	var a := CombatUnit.new(_card("Hover-Fixo-A", "Corpo a Corpo", 50, 100, 20), 0, 1)
	var b := CombatUnit.new(_card("Hover-Fixo-B", "À Distância", 40, 80, 10), 1, 9)
	var scenario: Dictionary = _build_scenario([a, b])
	var view = scenario["view"]

	print("  [13] Popup ancorado no canto superior esquerdo (anchors 0,0,0,0)? %s" % str(
		view._hover_preview_wrapper.anchor_left == 0.0 and view._hover_preview_wrapper.anchor_top == 0.0 and
		view._hover_preview_wrapper.anchor_right == 0.0 and view._hover_preview_wrapper.anchor_bottom == 0.0
	))
	ctx.check(view._hover_preview_wrapper.anchor_left == 0.0, "[13] O popup deve ancorar no canto superior esquerdo (anchor_left=0), nunca em _visual_center_frac()")
	ctx.check(view._hover_preview_wrapper.anchor_top == 0.0, "[13] O popup deve ancorar no canto superior esquerdo (anchor_top=0), nunca em _visual_center_frac()")

	view._on_card_mouse_entered(0 * 10 + 1)
	var rect_at_position_1: Rect2 = view._hover_preview_wrapper.get_rect()
	view._on_card_mouse_exited(0 * 10 + 1)

	view._on_card_mouse_entered(1 * 10 + 9)
	var rect_at_position_9: Rect2 = view._hover_preview_wrapper.get_rect()

	print("  [13] Popup em Lado 0/Posição 1: %s | Popup em Lado 1/Posição 9: %s | idênticos (não depende do pelotão)? %s" % [
		str(rect_at_position_1), str(rect_at_position_9), str(rect_at_position_1 == rect_at_position_9)
	])
	ctx.check(rect_at_position_1 == rect_at_position_9, "[13] O retângulo do popup deve ser IDÊNTICO não importa qual pelotão está sob o cursor — posição fixa, não depende mais de side/position")

	view.free()
