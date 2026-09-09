class_name TestArmyEditorUxAuditFindings
extends RefCounted
## TestArmyEditorUxAuditFindings (Auditoria FASE 22.1/22.2)
##
## Cobre 3 achados corrigidos na auditoria de UX do Editor de Exército,
## nenhum deles regra de jogo nova — só leitura/exibição do que já
## existe:
##
## A) Afinidade nunca aparecia no Editor — _build_affinity_section()
##    agora existe e deve bater exatamente com Affinity.calculate_points()
##    (engine/combat/affinity.gd), nunca duplicar essa conta.
## B) Custo de Soldo por carta desaparecia ao selecionar a carta, e nunca
##    aparecia nos slots da Formação — _make_soldo_badge() agora aparece
##    nos dois lugares, sempre com Soldo.cost_for_rarity() real.
## C) Posições 1/5/9 nunca eram explicadas — _position_special_note()
##    só para essas 3 posições, com o texto exato das regras
##    confirmadas em COMBAT_RULES.md (nunca uma vantagem inventada).

static func _collect_label_texts(node: Node, out: Array[String]) -> void:
	if node is Label:
		out.append((node as Label).text)
	for child: Node in node.get_children():
		_collect_label_texts(child, out)


static func _build_starter_army() -> Army:
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	return army


static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria 22.1/22.2] Validando Afinidade, Soldo persistente e Posições especiais no Editor...")

	_test_a_affinity_section_matches_real_calculator(ctx)
	_test_b_soldo_badge_present_in_list_and_formation_slots(ctx)
	_test_c_position_special_note_only_for_1_5_9(ctx)
	_test_d_pelotao_tab_tooltip_explains_why_disabled(ctx)
	_test_e_persistent_help_button_and_popup(ctx)

	return true


static func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for child: Node in node.get_children():
		var found: Button = _find_button_with_text(child, text)
		if found != null:
			return found
	return null


## D: correção FASE 22 (continuação — Parte 4): a aba "Pelotão"
## desabilitada (sem Comandante escolhido ainda) precisa explicar O
## PORQUÊ via tooltip — nunca deixar o jogador só descobrir por conta
## própria que precisa escolher um Comandante primeiro.
static func _test_d_pelotao_tab_tooltip_explains_why_disabled(ctx: TestRunner.Context) -> void:
	var panel_no_commander := ArmyEditorPanel.new()
	var container_no_commander := Control.new()
	panel_no_commander._build_top_tabs_area(container_no_commander)
	var pelotao_button_disabled: Button = _find_button_with_text(container_no_commander, "Pelotão")

	print("  [D1] Sem Comandante selecionado, aba Pelotão desabilitada com tooltip explicando o motivo? disabled=%s tooltip='%s'" % [str(pelotao_button_disabled.disabled), pelotao_button_disabled.tooltip_text])
	ctx.check(pelotao_button_disabled.disabled, "[D1] Sem Comandante selecionado, a aba Pelotão deve continuar desabilitada (regra preexistente)")
	ctx.check(pelotao_button_disabled.tooltip_text != "", "[D2] A aba Pelotão desabilitada deve ter um tooltip explicando por que (achado real: antes não explicava nada)")
	container_no_commander.free()
	panel_no_commander.free()


## E: FASE 22.5 — achado real (registrado no controle temporário da
## Fase 22): só existiam tooltips pontuais, nenhum ponto de ajuda
## PERSISTENTE/descobrível sem passar o mouse por acaso. Confirma que o
## botão "(?) Ajuda" existe na barra de título e que o popup mostra
## exatamente os títulos de _help_entries() (nunca uma lista paralela
## reescrita neste teste).
static func _test_e_persistent_help_button_and_popup(ctx: TestRunner.Context) -> void:
	var panel := ArmyEditorPanel.new()
	var container := Control.new()
	panel._build_help_button(container)

	var button_labels: Array[String] = []
	_collect_label_texts(container, button_labels)
	print("  [E1] Botão de ajuda persistente presente na barra de título? textos: %s" % str(button_labels))
	ctx.check(button_labels.has("(?) Ajuda"), "[E1] Deve existir um botão de ajuda persistente com o texto '(?) Ajuda'")

	panel._show_help_popup()
	var popup_labels: Array[String] = []
	_collect_label_texts(panel, popup_labels)
	var entries: Array[Dictionary] = panel._help_entries()
	print("  [E2] Popup de ajuda aberto mostra os %d conceito(s) esperados? títulos no popup: %s" % [entries.size(), str(popup_labels)])
	for entry: Dictionary in entries:
		ctx.check(popup_labels.has(entry["title"]), "[E2] O popup de ajuda deve mostrar o título '%s'" % entry["title"])

	panel._hide_help_popup()
	print("  [E3] Fechar o popup limpa a referência interna? _help_popup=%s" % str(panel._help_popup))
	ctx.check(panel._help_popup == null, "[E3] Fechar o popup de ajuda deve limpar a referência (_help_popup)")

	container.free()
	panel.free()

	var army: Army = _build_starter_army()
	var panel_with_commander := ArmyEditorPanel.new()
	panel_with_commander._selected_commander = army.commander
	var container_with_commander := Control.new()
	panel_with_commander._build_top_tabs_area(container_with_commander)
	var pelotao_button_enabled: Button = _find_button_with_text(container_with_commander, "Pelotão")

	print("  [D3] Com Comandante selecionado, aba Pelotão habilitada? disabled=%s" % str(pelotao_button_enabled.disabled))
	ctx.check(not pelotao_button_enabled.disabled, "[D3] Com Comandante selecionado, a aba Pelotão deve estar habilitada (regra preexistente)")
	container_with_commander.free()
	panel_with_commander.free()


## A: _build_affinity_section() nunca recalcula Afinidade por conta
## própria — o valor exibido tem que ser IDÊNTICO ao de Affinity.
## calculate_points()/highest_active_level(), a mesma classe usada pelo
## Motor de Combate (AFFINITY.md).
static func _test_a_affinity_section_matches_real_calculator(ctx: TestRunner.Context) -> void:
	var army: Army = _build_starter_army()

	var panel := ArmyEditorPanel.new()
	panel._selected_commander = army.commander
	panel._selected_cards = army.cards.duplicate()

	var container := Control.new()
	var rendered: bool = panel._build_affinity_section(container)
	ctx.check(rendered, "[A1] Com Comandante e 9 Cartas selecionadas, _build_affinity_section() deve desenhar algo (retornar true)")

	var texts: Array[String] = []
	_collect_label_texts(container, texts)
	var full_text: String = "\n".join(texts)

	var faction: String = army.commander.faction
	var expected_points: int = Affinity.calculate_points(faction, army.cards, army.commander)
	var expected_level: int = Affinity.highest_active_level(expected_points)
	var expected_level_text: String = "Nível %d ativo" % expected_level if expected_level > 0 else "Nenhum Nível ativo"

	# Correção FASE 22.2 (revisão visual): cada Facção vira um bloco com
	# 3 linhas próprias (nome, pontos, Nível) — nunca mais uma única
	# linha corrida "Facção — N pontos (Nível X)".
	print("  [A2] Bloco da Facção exibido (nome/pontos/Nível) bate com Affinity.calculate_points() real? %s / %s / %s" % [
		str(texts.has(faction.to_upper())), str(texts.has("%d ponto(s) de Afinidade" % expected_points)), str(texts.has(expected_level_text))
	])
	ctx.check(texts.has(faction.to_upper()), "[A2a] O nome da Facção deve aparecer em destaque próprio")
	ctx.check(texts.has("%d ponto(s) de Afinidade" % expected_points), "[A2b] Os pontos exibidos devem ser exatamente Affinity.calculate_points(), nunca uma conta paralela")
	ctx.check(texts.has(expected_level_text), "[A2c] O Nível ativo exibido deve ser exatamente Affinity.highest_active_level(), nunca uma conta paralela")
	ctx.check(expected_points > 0, "[A3] Pré-condição do teste: a composição Starter (Comandante + 9 Cartas da mesma Facção) deve gerar Pontos de Afinidade > 0")

	# Correção FASE 22: a seção também precisa mostrar a CONSEQUÊNCIA de
	# cada Nível ativo (nunca só o número) — lida de Affinity.
	# active_effects()/GameDatabase.affinity_levels, o mesmo catálogo
	# cujo texto já bate com o que affinity_runtime.gd aplica de verdade
	# (nunca uma tabela nova/paralela criada por este teste ou pelo painel).
	var expected_effects: Array[AffinityLevelResource] = Affinity.active_effects(faction, expected_points, GameDatabase.affinity_levels)
	ctx.check(not expected_effects.is_empty(), "[A4] Pré-condição do teste: a composição Starter deve ativar pelo menos 1 Nível de Afinidade com efeito descritivo no catálogo real")
	for effect: AffinityLevelResource in expected_effects:
		var expected_effect_line: String = "✓ %s" % effect.effect_description
		print("  [A5] Consequência do Nível %d exibida ('%s')? %s" % [effect.level, expected_effect_line, str(texts.has(expected_effect_line))])
		ctx.check(texts.has(expected_effect_line), "[A5] A consequência real do Nível %d (Affinity.active_effects()/GameDatabase.affinity_levels) deve aparecer no texto do Editor, nunca só o número do Nível" % effect.level)

	container.free()
	panel.free()

	# A4: sem nenhuma Carta/Comandante selecionado, a seção não desenha
	# nada (nunca uma "Facção: 0 pontos" vazia e sem sentido).
	var empty_panel := ArmyEditorPanel.new()
	var empty_container := Control.new()
	var rendered_empty: bool = empty_panel._build_affinity_section(empty_container)
	print("  [A4] Sem Comandante/Cartas, _build_affinity_section() não desenha nada? %s" % str(not rendered_empty))
	ctx.check(not rendered_empty, "[A4] Sem nenhuma Carta/Comandante selecionado, _build_affinity_section() deve retornar false e não desenhar nada")
	empty_container.free()
	empty_panel.free()


## B: o custo de Soldo/Energia deve continuar visível tanto na linha
## compacta da Biblioteca (_build_compact_card_row(), correção FASE
## 22.3 — substituiu a grade de cartas completas da Biblioteca) quanto
## nos slots já preenchidos da Formação (_build_formation_slot(),
## _make_composition_footer()) — achado real original: a legenda antiga
## sumia ao selecionar a carta, e a Formação nunca mostrou custo nenhum.
static func _test_b_soldo_badge_present_in_list_and_formation_slots(ctx: TestRunner.Context) -> void:
	var army: Army = _build_starter_army()
	var card: CardResource = army.cards[0]
	var expected_cost_text: String = str(Soldo.cost_for_rarity(card.rarity))
	var expected_energy_text: String = str(EnergyArmy.card_energy(card.tier))

	var panel := ArmyEditorPanel.new()
	panel._selected_commander = army.commander
	panel._selected_cards = [card]

	var list_slot: Control = panel._build_compact_card_row(card)
	var list_texts: Array[String] = []
	_collect_label_texts(list_slot, list_texts)
	print("  [B1] Barra com Soldo (%s) e Energia (%s) presente no slot da lista mesmo com a carta JÁ selecionada? %s / %s" % [expected_cost_text, expected_energy_text, str(list_texts.has(expected_cost_text)), str(list_texts.has(expected_energy_text))])
	ctx.check(list_texts.has(expected_cost_text), "[B1] O custo de Soldo (Soldo.cost_for_rarity()) deve continuar visível no slot da lista mesmo quando a legenda de estado muda para 'Selecionada' (achado real: antes desaparecia)")
	ctx.check(list_texts.has(expected_energy_text), "[B1b] A Energia da carta (EnergyArmy.card_energy()) deve aparecer na mesma barra, ao lado do Soldo")
	list_slot.free()

	var formation_cards: Array[CardResource] = [card, null, null, null, null, null, null, null, null]
	var formation_slot: Control = panel._build_formation_slot(formation_cards, 0)
	var formation_texts: Array[String] = []
	_collect_label_texts(formation_slot, formation_texts)
	print("  [B2] Barra com Soldo (%s) e Energia (%s) presente no slot da Formação (nunca existia antes)? %s / %s" % [expected_cost_text, expected_energy_text, str(formation_texts.has(expected_cost_text)), str(formation_texts.has(expected_energy_text))])
	ctx.check(formation_texts.has(expected_cost_text), "[B2] O custo de Soldo deve aparecer também nos slots já preenchidos da Formação 3x3, não só na lista")
	ctx.check(formation_texts.has(expected_energy_text), "[B2b] A Energia também deve aparecer nos slots preenchidos da Formação")
	formation_slot.free()

	# B3: um slot VAZIO da Formação reserva a mesma altura de rodapé
	# (mesmo padrão visual, sem valores) — nunca deixa um vão desalinhado
	# no grid quando comparado a um slot preenchido ao lado.
	var empty_formation_cards: Array[CardResource] = [null, null, null, null, null, null, null, null, null]
	var empty_formation_slot: Control = panel._build_formation_slot(empty_formation_cards, 1)
	ctx.check(empty_formation_slot is VBoxContainer, "[B3] Um slot vazio da Formação também deve vir embrulhado (VBoxContainer) com espaço reservado para o rodapé, igual a um slot preenchido")
	empty_formation_slot.free()

	panel.free()


## C: nota de posição especial existe exatamente para 1, 5 e 9 — nunca
## para as outras 6 — e cada uma cita a regra correta e diferente das
## demais (nenhum texto genérico reaproveitado entre posições).
static func _test_c_position_special_note_only_for_1_5_9(ctx: TestRunner.Context) -> void:
	var panel := ArmyEditorPanel.new()

	for position: int in [2, 3, 4, 6, 7, 8]:
		var note: String = panel._position_special_note(position)
		ctx.check(note == "", "[C1] Posição %d não tem regra especial documentada — _position_special_note() deve retornar vazio (obtido: '%s')" % [position, note])

	var note_1: String = panel._position_special_note(1)
	var note_5: String = panel._position_special_note(5)
	var note_9: String = panel._position_special_note(9)

	print("  [C2] Posições 1/5/9 têm nota própria e não-vazia? %s / %s / %s" % [str(note_1 != ""), str(note_5 != ""), str(note_9 != "")])
	ctx.check(note_1 != "" and note_5 != "" and note_9 != "", "[C2] Posições 1, 5 e 9 devem ter uma nota especial não-vazia cada")

	ctx.check(note_1.contains("+50%") and note_1.contains("Ataque") and note_1.contains("Escudo"), "[C3] Posição 1: a nota deve citar o bônus real de +50%% de Ataque (Corpo a Corpo) e Escudo Base (Barreira), COMBAT_RULES.md 6.1/6.2")
	ctx.check(note_5.contains("Reorganização") and note_5.contains("avançando"), "[C4] Posição 5: a nota deve citar a Penalidade de Reorganização (COMBAT_RULES.md 5.2.2), condicional a CHEGAR ali avançando — nunca afirmar que começar ali já penaliza")
	ctx.check(note_9.contains("Máquina de Guerra"), "[C5] Posição 9: a nota deve citar a obrigatoriedade da Máquina de Guerra (COMBAT_RULES.md 6.6)")

	var all_notes: Array[String] = [note_1, note_5, note_9]
	ctx.check(all_notes[0] != all_notes[1] and all_notes[1] != all_notes[2] and all_notes[0] != all_notes[2], "[C6] As 3 notas devem ser distintas entre si (nenhum texto genérico reaproveitado)")

	panel.free()
