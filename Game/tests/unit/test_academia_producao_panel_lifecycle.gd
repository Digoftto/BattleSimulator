class_name TestAcademiaProducaoPanelLifecycle
extends RefCounted
## TestAcademiaProducaoPanelLifecycle
##
## Fecha uma lacuna de teste real: academia_producao_panel.gd
## reconstrói TODA a própria árvore de Controls a cada interação
## (refresh() -> _clear_children(self) -> _build_structure()), e quase
## todo hotspot da tela (ícones de Facção, moldura da Carta
## Selecionada, +/- de Quantidade, rádios de Estratégia, linhas da
## Lista de Cartas, botão Produzir, backdrop/carta da visão ampliada)
## chama refresh() de DENTRO do próprio handler de "gui_input" — ou
## seja, o Control ainda está no meio da emissão do próprio sinal
## quando _clear_children() roda em cima dele. _clear_children() usava
## free() (destruição imediata) em vez de queue_free() (destruição
## adiada pro fim do frame), o que produzia em runtime real:
## "Object was freed or unreferenced while a signal is being emitted."
##
## Este teste reproduz o caminho REAL (emit_signal("gui_input", ...)
## num Control dinâmico de verdade, não uma chamada direta ao método
## handler — chamar o handler direto pula por completo a bookkeeping
## de Signal::emit() do Godot, que é exatamente o mecanismo que
## detecta/reporta esse erro) para cada hotspot não-deferred da tela,
## em sequência, incluindo abrir/fechar a visão ampliada e trocar a
## Carta Selecionada várias vezes — e confirma que o painel continua
## funcional (sem travar, com o estado esperado) depois de todo o
## ciclo. Precisa do painel DENTRO da SceneTree real (diferente do
## padrão "só .new() e chama método" de outros testes de painel do
## projeto, ex. test_army_editor_formation_flow.gd) porque o bug é
## sobre timing de Signal::emit() em cima da árvore viva, não sobre
## lógica de dados pura — e a visão ampliada usa get_viewport_rect(),
## que exige um Viewport real.
##
## O ERRO em si é impresso pelo Godot direto no stderr (ERR_PRINT do
## engine, não uma exceção/sinal capturável em GDScript) — por isso a
## confirmação "0 ocorrências" desta suíte é feita por fora, lendo a
## saída bruta de "godot --headless ... -- --test=validate_..." (ver
## relatório da tarefa), não por uma asserção dentro deste arquivo.
## O que ESTE arquivo garante via ctx.check() é a sobrevivência
## funcional real: seleção, quantidade, estratégia e zoom continuam
## corretos depois do ciclo completo de reconstrução.

const PANEL_SCRIPT: Script = preload("res://scenes/city/panels/academia_producao_panel.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[Lifecycle] Validando reconstrução de UI do Salão dos Artífices sob emissão real de sinal (gui_input)...")
	_test_full_interaction_cycle_survives_signal_emission(ctx)
	return true


static func _click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	control.emit_signal("gui_input", event)


## Localiza o hotspot dinâmico cujo Rect2 de âncora bate com "rect" —
## em vez de indexar por posição na lista de filhos, que muda conforme
## anéis/pontos de seleção condicionais são ou não adicionados.
static func _find_by_rect(container: Node, rect: Rect2) -> Control:
	for child in container.get_children():
		if child is Control:
			var c: Control = child
			if is_equal_approx(c.anchor_left, rect.position.x) \
				and is_equal_approx(c.anchor_top, rect.position.y) \
				and is_equal_approx(c.anchor_right, rect.position.x + rect.size.x) \
				and is_equal_approx(c.anchor_bottom, rect.position.y + rect.size.y):
				return c
	return null


static func _texture_rect(panel: Control) -> Control:
	var aspect: Control = panel.get_child(1)
	return aspect.get_child(0)


## Estrutura de cada linha: PanelContainer(row) -> HBoxContainer -> [dot, Label].
## Usado pra confirmar que o NOME real da carta chegou até o Label —
## não só que a linha existe (a regressão original: o Label existia,
## mas ficava com ~1px de largura porque o VBoxContainer pai colapsava
## dentro do ScrollContainer, ver academia_producao_panel.gd).
static func _row_label(row: Control) -> Label:
	for child in row.get_children():
		if child is HBoxContainer:
			for gc in child.get_children():
				if gc is Label:
					return gc
	return null


## O backdrop da visão ampliada é adicionado direto em "panel" (não em
## texture_rect) — só existe quando _card_zoom_open == true. Distingue
## do ColorRect de fundo comum (sempre presente, sem "gui_input"
## conectado) checando a conexão real do sinal, nunca mouse_filter
## sozinho (o fundo comum também usa MOUSE_FILTER_STOP, o default de
## Control).
static func _find_zoom_backdrop(panel: Control) -> ColorRect:
	for child in panel.get_children():
		if child is ColorRect and child.get_signal_connection_list("gui_input").size() > 0:
			return child
	return null


static func _test_full_interaction_cycle_survives_signal_emission(ctx: TestRunner.Context) -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	print("  [0] GameDatabase.cards não está vazio? %s (%d cartas)" % [str(not GameDatabase.cards.is_empty()), GameDatabase.cards.size()])
	ctx.check(not GameDatabase.cards.is_empty(), "[0] Pré-condição: precisa de ao menos 1 carta pra exercitar a Lista/Carta Selecionada")
	if GameDatabase.cards.is_empty():
		return

	# Usa tree.current_scene (o próprio Node test_main), nunca tree.root
	# diretamente: tree.root ainda está "bloqueado" nesta janela — este
	# teste roda dentro do _ready() de test_main.gd, que por sua vez
	# está aninhado dentro da PRÓPRIA chamada tree.root.add_child(test_main)
	# feita pelo boot do engine ao carregar a cena principal; chamar
	# tree.root.add_child() de novo aqui reentraria nessa mesma chamada
	# e falharia ("Parent node is busy setting up children"). Isso é só
	# uma restrição deste ambiente de teste headless — não existe no
	# jogo real (a tela é sempre adicionada por change_scene_to_file,
	# nunca durante o _ready() de outro Node em processo de entrar na
	# árvore).
	var tree: SceneTree = Engine.get_main_loop()
	var panel: Control = PANEL_SCRIPT.new()
	tree.current_scene.add_child(panel)
	panel.refresh()

	# [A] Facção — hotspot não-deferred, handler chama refresh() cheio.
	var texture_rect: Control = _texture_rect(panel)
	var faccao0_rect := Rect2(
		panel.FACCAO_ICON_CENTERS_X[0] - panel.FACCAO_ICON_SIZE / 2.0, panel.FACCAO_ICON_Y,
		panel.FACCAO_ICON_SIZE, panel.FACCAO_ICON_SIZE
	)
	var faccao_hotspot: Control = _find_by_rect(texture_rect, faccao0_rect)
	print("  [A] Hotspot de Facção[0] encontrado? %s" % str(faccao_hotspot != null))
	ctx.check(faccao_hotspot != null, "[A] O hotspot da 1a Facção deve existir na árvore recém-construída")
	if faccao_hotspot != null:
		_click(faccao_hotspot)
	print("  [A] Sobreviveu ao clique de Facção (refresh() disparado de dentro do próprio gui_input)? %s | filtro agora = '%s'" % [str(is_instance_valid(panel)), panel._produce_filter_faction])
	ctx.check(is_instance_valid(panel) and panel._produce_filter_faction == panel.FACCAO_VALUES[0], "[A] Clicar num ícone de Facção deve sobreviver à reconstrução total e aplicar o filtro")

	# [B] Carta Selecionada — abrir e fechar a visão ampliada (2 hotspots
	# não-deferred adicionais: a própria moldura, depois o backdrop).
	texture_rect = _texture_rect(panel)
	var card_slot: Control = _find_by_rect(texture_rect, panel.CARD_SLOT)
	print("  [B1] Hotspot da Carta Selecionada encontrado? %s" % str(card_slot != null))
	ctx.check(card_slot != null, "[B1] A moldura da Carta Selecionada deve existir (há ao menos 1 carta filtrada)")
	if card_slot != null:
		_click(card_slot)
	print("  [B2] Sobreviveu ao clique na Carta Selecionada e abriu a visão ampliada? %s | zoom_open = %s" % [str(is_instance_valid(panel)), str(panel._card_zoom_open)])
	ctx.check(is_instance_valid(panel) and panel._card_zoom_open, "[B2] Clicar na Carta Selecionada deve sobreviver à reconstrução e abrir a visão ampliada")

	var backdrop: ColorRect = _find_zoom_backdrop(panel)
	print("  [B3] Backdrop da visão ampliada encontrado? %s" % str(backdrop != null))
	ctx.check(backdrop != null, "[B3] Com zoom_open = true, o backdrop overlay deve existir como filho direto do painel")
	if backdrop != null:
		_click(backdrop)
	print("  [B4] Sobreviveu ao clique fora (backdrop) e fechou a visão ampliada? %s | zoom_open = %s" % [str(is_instance_valid(panel)), str(panel._card_zoom_open)])
	ctx.check(is_instance_valid(panel) and not panel._card_zoom_open, "[B4] Clicar no backdrop deve sobreviver à reconstrução e fechar a visão ampliada")

	# [C] Quantidade — dois hotspots não-deferred, +1/-1 cada.
	texture_rect = _texture_rect(panel)
	var plus_hotspot: Control = _find_by_rect(texture_rect, panel.QUANTIDADE_PLUS)
	ctx.check(plus_hotspot != null, "[C1] O hotspot '+' de Quantidade deve existir")
	if plus_hotspot != null:
		_click(plus_hotspot)
	var qty_after_plus: int = panel._produce_quantity
	print("  [C1] Sobreviveu ao clique em '+'? %s | quantidade = %d" % [str(is_instance_valid(panel)), qty_after_plus])
	ctx.check(is_instance_valid(panel) and qty_after_plus == 2, "[C1] '+' deve sobreviver à reconstrução e incrementar a quantidade (1 -> 2)")

	texture_rect = _texture_rect(panel)
	var minus_hotspot: Control = _find_by_rect(texture_rect, panel.QUANTIDADE_MINUS)
	ctx.check(minus_hotspot != null, "[C2] O hotspot '-' de Quantidade deve existir")
	if minus_hotspot != null:
		_click(minus_hotspot)
	print("  [C2] Sobreviveu ao clique em '-'? %s | quantidade = %d" % [str(is_instance_valid(panel)), panel._produce_quantity])
	ctx.check(is_instance_valid(panel) and panel._produce_quantity == 1, "[C2] '-' deve sobreviver à reconstrução e decrementar a quantidade (2 -> 1)")

	# [D] Estratégia — alterna pra "Preservar Inventário".
	texture_rect = _texture_rect(panel)
	var preservar_hotspot: Control = _find_by_rect(texture_rect, panel.ESTRATEGIA_PRESERVAR_RADIO)
	ctx.check(preservar_hotspot != null, "[D] O rádio 'Preservar Inventário' deve existir")
	if preservar_hotspot != null:
		_click(preservar_hotspot)
	print("  [D] Sobreviveu ao clique em Estratégia? %s | preserve_inventory = %s" % [str(is_instance_valid(panel)), str(panel._preserve_inventory)])
	ctx.check(is_instance_valid(panel) and panel._preserve_inventory, "[D] Trocar Estratégia deve sobreviver à reconstrução e atualizar o modo")

	# [E] Lista de Cartas — seleciona 3 linhas diferentes em sequência
	# (cada clique reconstrói a árvore inteira enquanto a PRÓPRIA linha
	# ainda está emitindo "gui_input" — o caso mais direto do bug
	# original).
	var previously_selected: Array[String] = []
	for i in range(min(3, GameDatabase.cards.size())):
		var rows: Array[Node] = panel._lista_cartas_container.get_children()
		if rows.is_empty():
			break
		var row: Control = rows[i % rows.size()]
		var row_label: Label = _row_label(row)
		var label_text_before_click: String = row_label.text if row_label != null else "<sem Label>"
		_click(row)
		var selected_name: String = panel._selected_produce_card.card_name if panel._selected_produce_card != null else "<null>"
		previously_selected.append(selected_name)
		print("  [E%d] Sobreviveu à seleção da linha %d da Lista? %s | Label da linha clicada = '%s' | carta selecionada agora = '%s'" % [i, i, str(is_instance_valid(panel)), label_text_before_click, selected_name])
		ctx.check(is_instance_valid(panel) and panel._selected_produce_card != null, "[E%d] Selecionar uma linha da Lista deve sobreviver à reconstrução total (a própria linha clicada é destruída e recriada no meio da emissão do seu gui_input)" % i)
		ctx.check(row_label != null and row_label.text == selected_name, "[E%d] O Label da linha clicada deve conter o NOME REAL da carta (não vazio, não um placeholder) e bater com a carta que a seleção aplicou" % i)

	# [F] Produzir Carta — último hotspot não-deferred da tela.
	texture_rect = _texture_rect(panel)
	var produzir_hotspot: Control = _find_by_rect(texture_rect, panel.PRODUZIR_BUTTON)
	ctx.check(produzir_hotspot != null, "[F] O hotspot 'Produzir Carta' deve existir")
	if produzir_hotspot != null:
		_click(produzir_hotspot)
	print("  [F] Sobreviveu ao clique em 'Produzir Carta'? %s" % str(is_instance_valid(panel)))
	ctx.check(is_instance_valid(panel), "[F] Clicar em 'Produzir Carta' (sucesso ou falha de validação) deve sobreviver à reconstrução")

	# [H] Dropdowns de Tipo/Raridade — texto centralizado (não a asserção
	# de layout em si, que depende de um frame real processado e não é
	# possível dentro do TestRunner síncrono — ver relatório da tarefa;
	# aqui confirma-se a PROPRIEDADE que causa a centralização, e que as
	# duas caixas não se sobrepõem).
	texture_rect = _texture_rect(panel)
	var tipo_option: OptionButton = null
	var raridade_option: OptionButton = null
	for child in texture_rect.get_children():
		if child is OptionButton:
			var c: Control = child
			if is_equal_approx(c.anchor_left, panel.TIPO_DROPDOWN.position.x):
				tipo_option = child
			elif is_equal_approx(c.anchor_left, panel.RARIDADE_DROPDOWN.position.x):
				raridade_option = child
	ctx.check(tipo_option != null and raridade_option != null, "[H1] Os OptionButton de Tipo e Raridade devem existir na árvore")
	if tipo_option != null and raridade_option != null:
		print("  [H2] Tipo.alignment = %d | Raridade.alignment = %d (esperado: %d = HORIZONTAL_ALIGNMENT_CENTER)" % [tipo_option.alignment, raridade_option.alignment, HORIZONTAL_ALIGNMENT_CENTER])
		ctx.check(tipo_option.alignment == HORIZONTAL_ALIGNMENT_CENTER, "[H2] O texto do dropdown Tipo deve estar centralizado (HORIZONTAL_ALIGNMENT_CENTER), não colado à esquerda")
		ctx.check(raridade_option.alignment == HORIZONTAL_ALIGNMENT_CENTER, "[H2] O texto do dropdown Raridade deve estar centralizado (HORIZONTAL_ALIGNMENT_CENTER), não colado à esquerda")
		var tipo_right: float = panel.TIPO_DROPDOWN.position.x + panel.TIPO_DROPDOWN.size.x
		var raridade_left: float = panel.RARIDADE_DROPDOWN.position.x
		print("  [H3] Borda direita de Tipo (%.4f) fica antes da borda esquerda de Raridade (%.4f)? %s" % [tipo_right, raridade_left, str(tipo_right <= raridade_left)])
		ctx.check(tipo_right <= raridade_left, "[H3] As caixas de Tipo e Raridade não podem se sobrepor — a seta de um nunca pode cair dentro da área do outro")

	# [I] "resized" do ScrollContainer da Lista pode disparar MAIS de uma
	# vez por reconstrução em runtime real (o layout leva alguns frames
	# pra estabilizar) — dispará-lo aqui manualmente, várias vezes,
	# reproduz exatamente isso. _on_lista_cartas_scroll_resized() nunca
	# pode repopular a lista (regressão real já confirmada: cada disparo
	# empilhava outra cópia das linhas em cima das existentes, sem
	# limpar antes — "BALISTA IMPERIAL" x3, etc.).
	var scroll: ScrollContainer = panel._lista_cartas_container.get_parent()
	var expected_rows: int = panel._filtered_produce_cards.size()
	for i in range(5):
		scroll.emit_signal("resized")
	var rows_after: int = panel._lista_cartas_container.get_child_count()
	print("  [I] linhas após 5 disparos extras de 'resized' no ScrollContainer: %d (esperado: %d, igual a antes)" % [rows_after, expected_rows])
	ctx.check(rows_after == expected_rows, "[I] Disparar 'resized' do ScrollContainer da Lista várias vezes NUNCA pode duplicar linhas — só deve ajustar a largura mínima, nunca repopular")

	# [G] Sair e voltar a entrar (nova instância, mesmo padrão de troca
	# de cena real) — confirma que o ciclo completo acima não deixou o
	# painel num estado do qual uma segunda entrada não se recupera.
	tree.current_scene.remove_child(panel)
	panel.queue_free()

	var panel2: Control = PANEL_SCRIPT.new()
	tree.current_scene.add_child(panel2)
	panel2.refresh()
	print("  [G] Uma segunda instância (nova entrada na tela) constrói normalmente? %s | linhas na lista = %d" % [str(is_instance_valid(panel2)), panel2._lista_cartas_container.get_children().size()])
	ctx.check(is_instance_valid(panel2) and panel2._lista_cartas_container.get_children().size() == panel2._filtered_produce_cards.size(), "[G] Reentrar na tela (nova instância) deve construir a Lista com exatamente 1 linha por carta filtrada, sem herdar nada da instância anterior")
	tree.current_scene.remove_child(panel2)
	panel2.queue_free()
