extends Control
## ExercitosPanel (ARMY.md)
##
## ETAPA 5 (reestruturação de layout, pedido explícito do usuário):
## troca da moldura genérica do CdC por uma moldura dedicada
## ("Caixa de texto centro de comando_exercito.png"), que já desenha
## na própria arte 3 áreas funcionais (linhas douradas divisórias):
## um resumo no topo-esquerda, uma lista abaixo dele à esquerda, e uma
## coluna cheia à direita. A tela agora é mestre-detalhe:
##
##   ESQUERDA (RESUMO + LISTA): "quais Exércitos existem e o que posso
##   fazer com eles?" — lista só texto (nome, Comandante, Unidades por
##   Nome, Estado, Ações Editar/Desfazer), NUNCA miniaturas de Carta
##   nem retrato do Comandante aqui.
##
##   DIREITA (DETALHE): "como o Exército selecionado está formado e
##   quem o comanda?" — retrato+dados do Comandante e a Formação 3x3
##   real (BattleCardView, cartas grandes) do Exército clicado na
##   lista à esquerda. Nunca uma janela nova — sempre a mesma tela.
##
## As frações de TITLE_RECT/CLOSE_BUTTON_RECT/SUMMARY_RECT/LIST_RECT/
## DETAIL_RECT foram medidas diretamente nos pixels da arte (1536x1024)
## — linhas douradas divisórias e cantos do retângulo interno — não são
## um chute visual.
##
## Removido nesta etapa (decisão explícita do usuário, não uma
## interpretação livre): os estados "Ativo/Reserva/Treinamento" e as
## ações "Ativar/Reservar/Treinar" não existem em ARMY.md nem no
## código (Kingdom.is_army_locked_for_editing() só modela Livre/
## Travado, com o motivo real de trava — "Em Expedição"/"Guarnição de
## Mina"); "Treinamento" já é um sistema real, mas de Comandante
## (COMMAND_CENTER_TRAINING.md/treinamento_panel.gd), não de Exército.
## Por pedido do usuário, as únicas ações desta etapa são Editar
## (abre o Editor de Exército já existente) e Desfazer (desmancha só
## a associação daquele Exército — Cartas/Comandante/CardResources
## nunca são apagados, só voltam a LIVRE via Kingdom.disband_army(),
## regra já existente, nenhuma nova).
##
## Posicionamento das 9 Cartas na Formação: NUNCA uma ordem nova.
## Reutiliza exatamente o mesmo algoritmo de CombatEngine._place_army()
## (COMBAT_RULES.md 6.6 — Máquina de Guerra sempre na Posição 9, as
## demais ocupam 1-8 na ordem em que aparecem em army.cards) via
## _position_map_for_army() — leitura pura duplicada localmente (a
## função do motor é privada/estática e monta CombatUnit atado a um
## "side" de batalha, que não interessa a uma tela de apresentação).
## O arranjo espacial 3x3 (qual célula mostra qual Posição) reaproveita
## a mesma ordem visual (FORMATION_VISUAL_ORDER) já usada por
## army_editor_panel.gd (POSITION_LAYOUT) e comandantes_panel.gd.
##
## Clicar em qualquer Carta ou no retrato do Comandante (coluna da
## direita) abre um overlay ampliado sobre esta mesma tela, reaproveitando
## exatamente o padrão de bestiario_panel.gd (_card_zoom_open) — nenhum
## dado inventado, só os campos/índices reais (CardResource,
## GameDatabase.traits_by_name/abilities_by_name,
## AcademyResolver.preview_production, CommanderCareer,
## CommanderDoctrine).
##
## CardArtCatalog.preload_all() aquece o cache de textura no _ready()
## (mesmo padrão de biblioteca_panel.gd/bestiario_panel.gd).

const FRAME_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/command_center_army_window_frame.png")
const FRAME_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

## Frações medidas nos pixels da arte (1536x1024): cantos do pill do
## título, do círculo do X, do retângulo interno e das duas linhas
## douradas divisórias (vertical em x≈1023px, horizontal em y≈360px
## dentro da coluna esquerda).
const TITLE_RECT: Rect2 = Rect2(0.318, 0.133, 0.364, 0.061)
const CLOSE_BUTTON_RECT: Rect2 = Rect2(0.859, 0.117, 0.072, 0.103)
const SUMMARY_RECT: Rect2 = Rect2(0.086, 0.242, 0.572, 0.102)
const LIST_RECT: Rect2 = Rect2(0.086, 0.362, 0.572, 0.465)
const DETAIL_RECT: Rect2 = Rect2(0.674, 0.242, 0.241, 0.585)

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 3
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)

const PORTRAIT_IMPERIO_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_1.png")
const PORTRAIT_IMPERIO_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_2.png")
const PORTRAIT_NATUREZA_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_1.png")
const PORTRAIT_NATUREZA_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_2.png")
const PORTRAIT_MORTOS_VIVOS_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_1.png")
const PORTRAIT_MORTOS_VIVOS_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_2.png")

## Coluna da direita é bem mais estreita que o antigo painel de largura
## cheia — dimensões reduzidas para caber 3 colunas confortavelmente
## sem virar ícone minúsculo (o mínimo proibido, 34px, continua muito
## menor que isto).
const FORMATION_CARD_WIDTH: float = 70.0
const COMMANDER_PORTRAIT_SIZE: float = 88.0

## Mesma ordem visual (índice 0-based de Posição 1-9) de
## army_editor_panel.gd (POSITION_LAYOUT) e comandantes_panel.gd —
## nunca uma disposição espacial nova.
const FORMATION_VISUAL_ORDER: Array[int] = [0, 1, 2, 5, 4, 3, 6, 7, 8]

var _armies_container: VBoxContainer
var _editor_overlay: ArmyEditorPanel = null

## Exército atualmente mostrado na coluna de Detalhe (direita). Nunca
## persiste um Exército que já saiu de kingdom.armies (Desfazer, etc.)
## — _build_detail_area() sempre revalida antes de usar.
var _selected_army: Army = null

## Overlay ampliado (Carta OU Comandante, nunca os dois ao mesmo tempo)
## — reconstruído a cada refresh() como parte de _build_static_structure(),
## mesmo padrão de bestiario_panel.gd (_card_zoom_open).
var _zoom_card: CardResource = null
var _zoom_commander: CommanderResource = null
var _zoom_commander_army: Army = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	# Aquece o cache de textura das Cartas em segundo plano (mesmo
	# padrão de biblioteca_panel.gd/bestiario_panel.gd) — a Formação 3x3
	# usa BattleCardView/CardArtCatalog.
	CardArtCatalog.preload_all(GameDatabase.cards)
	refresh()
	_maybe_show_tutorial_hint()
	print("[ExercitosPanel] Pronto. Exércitos no Reino: %d" % KingdomState.kingdom.armies.size())


func _maybe_show_tutorial_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_concluido") or kingdom.tutorial_step != Kingdom.TUTORIAL_STEP_EXERCITO:
		return

	var banner = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	banner.setup(
		"Seu Exército",
		"Comandante + 9 Cartas, já montados no Kit Inicial. Selecione o Exército na lista para ver a Formação; 'Editar' muda a composição. Volte à Cidade, abra o World Map Gate e entre no PvE para partir para sua primeira batalha.",
		"Passo 2 de 4"
	)
	banner.continue_pressed.connect(_on_tutorial_hint_continue.bind(banner), CONNECT_DEFERRED)
	add_child(banner)


func _on_tutorial_hint_continue(banner: Control) -> void:
	KingdomState.kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_PVE
	banner.queue_free()


## F-021.5 (dica contextual, independente da sequência linear TUT-001):
## primeira vez que o jogador visualiza a Formação real de um Exército
## (grade 3x3 renderizada em _build_detail_pane()). Só depois que a
## dica linear "Seu Exército" (Passo 2) já foi dispensada ou o tutorial
## principal já terminou — nunca duas dicas competindo pelo mesmo
## espaço ao mesmo tempo.
func _maybe_show_formacao_contextual_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_hint_formacao_visto"):
		return
	if kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_EXERCITO and not kingdom.has_progress_flag("tutorial_concluido"):
		return

	var hint = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	hint.setup(
		"Formação de Combate",
		"A grade acima é a Formação: cada posição afeta o combate (linha de frente, meio, retaguarda). Clique numa Carta para ver seus dados, ou use 'Editar' para reorganizar antes de partir para o PvE.",
		"Dica"
	)
	hint.continue_pressed.connect(_on_formacao_hint_continue.bind(hint), CONNECT_DEFERRED)
	add_child(hint)


func _on_formacao_hint_continue(hint: Control) -> void:
	KingdomState.kingdom.set_progress_flag("tutorial_hint_formacao_visto")
	hint.queue_free()


func refresh() -> void:
	GameRuntime.sync(KingdomState.kingdom, GameClock.now_unix())
	_clear_children(self)
	_build_static_structure()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var window_area := Control.new()
	window_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	window_area.clip_contents = true
	add_child(window_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = FRAME_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	window_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = FRAME_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_title(texture_rect, "EXÉRCITOS")
	_build_close_button(texture_rect)
	_build_summary_area(texture_rect)
	_build_list_area(texture_rect)
	_build_detail_area(texture_rect)

	# --- Visão ampliada (overlay sobre esta mesma tela) — construída
	# por último, sempre por cima de tudo, mesmo padrão de
	# bestiario_panel.gd (_card_zoom_open). ---
	if _zoom_card != null:
		_build_card_zoom_overlay(_zoom_card)
	elif _zoom_commander != null:
		_build_commander_zoom_overlay(_zoom_commander, _zoom_commander_army)


func _build_title(parent: Control, text: String) -> void:
	var area := _anchor_new_control(parent, TITLE_RECT)
	var label := _make_centered_label(text, 20, HUD_ACCENT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area.add_child(label)


func _build_close_button(parent: Control) -> void:
	var hotspot := _anchor_new_control(parent, CLOSE_BUTTON_RECT)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.gui_input.connect(_on_close_button_gui_input)


func _on_close_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/command_center/command_center_panel.tscn")


## --- Área 1 (topo-esquerda): Resumo dos Exércitos — Total/Livres/
## Travados, calculados a partir de kingdom.armies e do mesmo predicado
## real de trava (Kingdom.is_army_locked_for_editing()) já usado pela
## lista abaixo. Nenhum número fictício. ---
func _build_summary_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, SUMMARY_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	area.add_child(margin)

	# Alignment fica no padrão BEGIN (nunca CENTER/END) — combinado com
	# AUTOWRAP_WORD_SMART, ALIGNMENT_CENTER num BoxContainer é a causa
	# raiz confirmada do bug de texto verticalizado ("T/O/T/A/L") desta
	# faixa: força os Labels a negociar uma largura antes do Container
	# pai ter resolvido a própria, e eles colapsam pra 1 caractere por
	# linha. Resolvido em duas frentes (aqui + _make_label(wrap=false
	# por padrão) — nenhuma das duas sozinha é garantia suficiente pra
	# nunca mais acontecer em qualquer canto desta tela).
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var kingdom: Kingdom = KingdomState.kingdom
	var total: int = kingdom.armies.size()
	var locked_count: int = 0
	for army: Army in kingdom.armies:
		if kingdom.is_army_locked_for_editing(army)["locked"]:
			locked_count += 1
	var free_count: int = total - locked_count

	hbox.add_child(_make_stat_chip("Total", str(total)))
	hbox.add_child(_make_stat_chip("Livres", str(free_count)))
	hbox.add_child(_make_stat_chip("Travados", str(locked_count)))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# "Criar Novo Exército" é a ação principal da janela — precisa ficar
	# na faixa superior, sempre visível, nunca dentro da lista rolável
	# à esquerda (onde só some de vista com mais Exércitos formados).
	var create_button := _make_primary_button("Criar Novo Exército")
	create_button.disabled = _editor_overlay != null
	create_button.pressed.connect(_on_create_army_pressed, CONNECT_DEFERRED)
	hbox.add_child(create_button)


## --- Área 2 (embaixo-esquerda): Lista administrativa dos Exércitos —
## só texto (nome, Comandante, Unidades por Nome, Estado, Ações). NUNCA
## miniaturas/retratos aqui — essas informações visuais pertencem
## exclusivamente à coluna de Detalhe (direita), depois de selecionado. ---
func _build_list_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, LIST_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	area.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	_armies_container = VBoxContainer.new()
	_armies_container.add_theme_constant_override("separation", 8)
	_armies_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_armies_container)

	_refresh_armies_list()


func _refresh_armies_list() -> void:
	_clear_children(_armies_container)

	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.armies.is_empty():
		_armies_container.add_child(_make_body_label("Nenhum Exército formado ainda."))
		return

	for i in range(kingdom.armies.size()):
		_armies_container.add_child(_build_army_row(kingdom.armies[i], kingdom, i))


## Uma fileira da lista: bloco inteiro clicável (seleciona o Exército
## pra coluna de Detalhe), com Editar/Desfazer como Controls próprios
## por cima — cliques nos botões nunca chegam ao gui_input da fileira
## porque Button já consome o evento sozinho (mesmo raciocínio já usado
## por _build_formation_card_slot/_build_commander_hotspot nesta tela).
func _build_army_row(army: Army, kingdom: Kingdom, index: int) -> Control:
	var is_selected: bool = army == _selected_army
	var panel := _make_list_row_panel(is_selected)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_army_row_gui_input.bind(army), CONNECT_DEFERRED)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var display_name: String = army.army_name if army.army_name != "" else "Exército %d" % (index + 1)
	var lock: Dictionary = kingdom.is_army_locked_for_editing(army)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	var name_label := _make_label(display_name.to_upper(), 14, HUD_ACCENT_SELECTED if is_selected else HUD_ACCENT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var estado_text: String = "Travado" if lock["locked"] else "Livre"
	var estado_color: Color = HUD_ERROR_COLOR if lock["locked"] else HUD_ACCENT
	header.add_child(_make_label(estado_text, 11, estado_color))

	var patente: String = CommanderCareer.patente_for_xp(army.commander.accumulated_xp) if army.commander != null else ""
	var commander_text: String = "Comandante: %s (%s)" % [army.commander.commander_name, patente] if army.commander != null else "Comandante: (sem Comandante)"
	vbox.add_child(_make_body_label(commander_text))

	if lock["locked"]:
		vbox.add_child(_make_label("Motivo: %s" % lock["reason"], 10, HUD_MUTED_COLOR, true))

	var card_names: Array[String] = []
	for card: CardResource in army.cards:
		card_names.append(card.card_name)
	var units_text: String = "Unidades: %s" % " • ".join(card_names) if not card_names.is_empty() else "Unidades: (nenhuma)"
	vbox.add_child(_make_body_label(units_text))

	var actions_row := HBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 8)
	actions_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(actions_row)

	var edit_button := _make_small_button("Editar")
	edit_button.disabled = _editor_overlay != null or lock["locked"]
	edit_button.pressed.connect(_on_edit_army_pressed.bind(army), CONNECT_DEFERRED)
	actions_row.add_child(edit_button)

	var disband_button := _make_small_button("Desfazer")
	disband_button.disabled = _editor_overlay != null or lock["locked"]
	disband_button.pressed.connect(_on_disband_pressed.bind(army), CONNECT_DEFERRED)
	actions_row.add_child(disband_button)

	return panel


func _on_army_row_gui_input(event: InputEvent, army: Army) -> void:
	if _editor_overlay != null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_army = army
		refresh()


## --- Área 3 (coluna direita): Detalhe do Exército selecionado —
## Comandante (retrato + Nome/Patente/Soldo/Doutrina) e a Formação de
## Combate 3x3 real, nessa ordem (COMANDANTE > FORMAÇÃO, mesma
## hierarquia do pedido). Três estados possíveis: Reino sem nenhum
## Exército, Reino com Exércitos mas nenhum selecionado, e Exército
## selecionado. ---
func _build_detail_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, DETAIL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	area.add_child(margin)

	var kingdom: Kingdom = KingdomState.kingdom

	if kingdom.armies.is_empty():
		_build_detail_message(margin, "NENHUM EXÉRCITO FORMADO", "Crie um novo Exército para organizar suas forças. Use \"Criar Novo Exército\", no topo da janela.")
		return

	if _selected_army == null or not kingdom.armies.has(_selected_army):
		_build_detail_message(margin, "SELECIONE UM EXÉRCITO", "Selecione um Exército na lista à esquerda para visualizar seu Comandante e sua Formação de Combate.")
		return

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_build_detail_commander_section(vbox, _selected_army)

	vbox.add_child(_make_separator())
	vbox.add_child(_make_centered_label("Formação de Combate", 12, HUD_ACCENT))

	var grid_center := CenterContainer.new()
	grid_center.add_child(_build_formation_grid(_selected_army))
	vbox.add_child(grid_center)

	_maybe_show_formacao_contextual_hint()


func _build_detail_message(parent: Control, title_text: String, body_text: String) -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	center.add_child(vbox)

	vbox.add_child(_make_centered_label(title_text, 13, HUD_ACCENT))
	var hint := _make_body_label(body_text)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.custom_minimum_size = Vector2(190, 0)
	vbox.add_child(hint)


## Retrato (hotspot clicável — abre a ficha completa do Comandante) +
## Nome/Patente/Soldo do Exército/Doutrina, empilhados verticalmente
## (a coluna de Detalhe é estreita demais para "retrato ao lado do
## texto" sem quebrar a legibilidade da Doutrina — adaptação de leitura
## explicitamente permitida quando o layout proposto não cabe no espaço
## real, priorizando legibilidade). Soldo mostrado é o do EXÉRCITO
## (ARMY.md: "O Comandante não possui custo próprio de Soldo" — Soldo
## Total é sempre da composição de Cartas, Army.soldo_total()), nunca
## um valor de Comandante inventado.
func _build_detail_commander_section(parent: Control, army: Army) -> void:
	var portrait_center := CenterContainer.new()
	parent.add_child(portrait_center)
	portrait_center.add_child(_build_commander_hotspot(army))

	var commander: CommanderResource = army.commander
	if commander == null:
		parent.add_child(_make_centered_label("(sem Comandante)", 12, HUD_MUTED_COLOR))
		return

	parent.add_child(_make_centered_label(commander.commander_name, 14, HUD_TEXT_COLOR))
	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	parent.add_child(_make_centered_label("Patente: %s" % patente, 11, HUD_ACCENT))
	parent.add_child(_make_centered_label("Soldo do Exército: %d" % army.soldo_total(), 11, HUD_TEXT_COLOR))

	if commander.doctrine != null:
		parent.add_child(_make_separator())
		parent.add_child(_make_centered_label("Doutrina", 12, HUD_ACCENT))
		parent.add_child(_make_body_label("Restrição: %s" % commander.doctrine.restriction_description()))
		parent.add_child(_make_body_label("Requisito: %s" % commander.doctrine.requirement_description()))

		var target_text: String = commander.doctrine.target.description
		if commander.doctrine.target.value != "":
			target_text += " (%s)" % commander.doctrine.target.value
		parent.add_child(_make_body_label("Alvo: %s" % target_text))
		parent.add_child(_make_body_label("Efeito: %s" % commander.doctrine.effect.description))
		parent.add_child(_make_body_label("Valor: %s" % commander.doctrine.value_description()))


## Grade 3x3 real da Formação, cada uma um hotspot completo que abre a
## visão ampliada ao clicar.
func _build_formation_grid(army: Army) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)

	var positions: Array[CardResource] = _position_map_for_army(army.cards)
	for position_index: int in FORMATION_VISUAL_ORDER:
		grid.add_child(_build_formation_card_slot(positions[position_index], position_index + 1))

	return grid


## Mesmo algoritmo de posicionamento inicial do motor de Combate
## (CombatEngine._place_army(), COMBAT_RULES.md 6.6): Máquina de Guerra
## sempre na Posição 9; as demais Cartas ocupam as Posições 1-8 na
## ordem em que aparecem em "cards" — replicado aqui como leitura pura
## (a função do motor é privada/estática e monta CombatUnit atado a um
## "side" de batalha, que não interessa a uma tela de apresentação).
## Retorna um Array de 9 posições (índice 0 = Posição 1); null onde
## não houver Carta correspondente.
func _position_map_for_army(cards: Array[CardResource]) -> Array[CardResource]:
	var positions: Array[CardResource] = [null, null, null, null, null, null, null, null, null]
	var remaining_positions: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	var machine_card: CardResource = null
	var other_cards: Array[CardResource] = []

	for card_resource: CardResource in cards:
		if card_resource.card_class == "Máquina de Guerra" and machine_card == null:
			machine_card = card_resource
		else:
			other_cards.append(card_resource)

	if machine_card != null:
		positions[8] = machine_card
		remaining_positions.erase(9)

	for i in range(other_cards.size()):
		positions[remaining_positions[i] - 1] = other_cards[i]

	return positions


func _build_formation_card_slot(card_resource: CardResource, position_number: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(FORMATION_CARD_WIDTH, FORMATION_CARD_WIDTH / BattleCardView.CARD_ASPECT_RATIO)

	if card_resource == null:
		var placeholder := Panel.new()
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		var placeholder_style := StyleBoxFlat.new()
		placeholder_style.bg_color = Color(0, 0, 0, 0.25)
		placeholder_style.border_width_left = 1
		placeholder_style.border_width_right = 1
		placeholder_style.border_width_top = 1
		placeholder_style.border_width_bottom = 1
		placeholder_style.border_color = Color(HUD_MUTED_COLOR.r, HUD_MUTED_COLOR.g, HUD_MUTED_COLOR.b, 0.5)
		placeholder_style.corner_radius_top_left = 4
		placeholder_style.corner_radius_top_right = 4
		placeholder_style.corner_radius_bottom_left = 4
		placeholder_style.corner_radius_bottom_right = 4
		placeholder.add_theme_stylebox_override("panel", placeholder_style)
		slot.add_child(placeholder)

		var position_label := _make_centered_label(str(position_number), 11, HUD_MUTED_COLOR)
		position_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(position_label)
		return slot

	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_formation_card_gui_input.bind(card_resource), CONNECT_DEFERRED)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_view)
	card_view.set_card(card_resource)
	card_view.set_stats(card_resource.atk, card_resource.hp, card_resource.esc)
	card_view.set_compact(true)
	_force_ignore_mouse_recursive(card_view)

	return slot


## BattleCardView monta internamente Controls sem mouse_filter próprio
## (herdam MOUSE_FILTER_STOP do Control base) — sem isto, a carta
## capturaria o clique antes do `slot` pai (mesma causa raiz já
## documentada e corrigida em bestiario_panel.gd).
func _force_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_force_ignore_mouse_recursive(child)


func _on_formation_card_gui_input(event: InputEvent, card_resource: CardResource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_zoom_card = card_resource
		_zoom_commander = null
		_zoom_commander_army = null
		refresh()


## --- Retrato do Comandante: hotspot completo (não só um ponto central). ---

func _build_commander_hotspot(army: Army) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(COMMANDER_PORTRAIT_SIZE, COMMANDER_PORTRAIT_SIZE)
	slot.clip_contents = true

	var texture: Texture2D = _portrait_for(army.commander)
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(rect)

	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 2
	border_style.border_width_right = 2
	border_style.border_width_top = 2
	border_style.border_width_bottom = 2
	border_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.8)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)

	if army.commander != null:
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.gui_input.connect(_on_commander_hotspot_gui_input.bind(army), CONNECT_DEFERRED)

	return slot


func _portrait_for(commander: CommanderResource) -> Texture2D:
	if commander == null:
		return null
	var variant: int = absi(commander.commander_name.hash()) % 2
	match commander.faction:
		"Império":
			return PORTRAIT_IMPERIO_1 if variant == 0 else PORTRAIT_IMPERIO_2
		"Natureza":
			return PORTRAIT_NATUREZA_1 if variant == 0 else PORTRAIT_NATUREZA_2
		"Mortos-Vivos":
			return PORTRAIT_MORTOS_VIVOS_1 if variant == 0 else PORTRAIT_MORTOS_VIVOS_2
		_:
			return null


func _on_commander_hotspot_gui_input(event: InputEvent, army: Army) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_zoom_commander = army.commander
		_zoom_commander_army = army
		_zoom_card = null
		refresh()


## --- Overlay ampliado da Carta (arte grande + ficha completa) —
## mesmo padrão/campos de bestiario_panel.gd (_build_card_zoom_overlay/
## _build_detail_area), duplicado localmente (nunca importado). ---

func _build_card_zoom_overlay(card_resource: CardResource) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_zoom_backdrop_gui_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var panel := _make_card_panel()
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, minf(560.0, get_viewport_rect().size.y * 0.8))
	panel.add_child(scroll)
	_style_scrollbar(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.custom_minimum_size = Vector2(300, 0)
	scroll.add_child(vbox)

	var enlarged_width: float = 170.0
	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(enlarged_width, enlarged_width / BattleCardView.CARD_ASPECT_RATIO)
	card_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	card_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_slot.gui_input.connect(_on_zoom_close_gui_input)
	vbox.add_child(card_slot)

	var enlarged_view := BattleCardView.new()
	enlarged_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	enlarged_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(enlarged_view)
	enlarged_view.set_card(card_resource)
	enlarged_view.set_stats(card_resource.atk, card_resource.hp, card_resource.esc)
	enlarged_view.set_compact(false)

	vbox.add_child(_make_centered_label(card_resource.card_name, 16, HUD_TEXT_COLOR, true))

	var identity_text: String = "%s — %s" % [card_resource.faction, card_resource.card_class]
	if card_resource.card_type != "":
		identity_text += " (%s)" % card_resource.card_type
	vbox.add_child(_make_centered_label(identity_text, 12, HUD_ACCENT, true))
	vbox.add_child(_make_centered_label("%s — Tier %d" % [card_resource.rarity, card_resource.tier], 12, HUD_TEXT_COLOR))
	vbox.add_child(_make_centered_label("ATK %d   HP %d   ESC %d" % [card_resource.atk, card_resource.hp, card_resource.esc], 12, HUD_TEXT_COLOR))

	# Característica de Unidade (Tier I) — ABILITIES.md é a autoridade;
	# nome + descrição real via GameDatabase.traits_by_name (mesmo
	# índice usado pelo motor de Combate), nunca texto inventado.
	if card_resource.tier_1_trait_name != "":
		vbox.add_child(_make_separator())
		vbox.add_child(_make_centered_label("Característica: %s" % card_resource.tier_1_trait_name, 12, HUD_ACCENT, true))
		var trait_entry: UnitTraitResource = GameDatabase.traits_by_name.get(card_resource.tier_1_trait_name)
		if trait_entry != null and trait_entry.base_effect_description != "":
			vbox.add_child(_make_body_label(trait_entry.base_effect_description))

	# Habilidades (Tier III/V) — mesmo índice GameDatabase.abilities_by_name.
	var ability_slots: Array = [
		["Habilidade (Tier III)", card_resource.tier_3_ability_name],
		["Habilidade (Tier V)", card_resource.tier_5_ability_name],
	]
	for slot: Array in ability_slots:
		var slot_label: String = slot[0]
		var ability_name: String = slot[1]
		if ability_name == "":
			continue
		vbox.add_child(_make_separator())
		vbox.add_child(_make_centered_label("%s: %s" % [slot_label, ability_name], 12, HUD_ACCENT, true))
		var ability: AbilityResource = GameDatabase.abilities_by_name.get(ability_name)
		if ability != null and ability.effect_description != "":
			vbox.add_child(_make_body_label(ability.effect_description))

	vbox.add_child(_make_separator())
	_build_recipe_section(vbox, card_resource, KingdomState.kingdom)


## Receita real — mesma função que bestiario_panel.gd/
## academia_producao_panel.gd já usam pra prever a Produção
## (AcademyResolver.preview_production), só leitura, nenhum recálculo
## manual, nenhum dado inventado.
func _build_recipe_section(vbox: VBoxContainer, template: CardResource, kingdom: Kingdom) -> void:
	vbox.add_child(_make_centered_label("Receita", 13, HUD_ACCENT))

	if template.recipe_ingredients.is_empty():
		vbox.add_child(_make_centered_label("Produzida direto por Fragmentos.", 11, HUD_MUTED_COLOR))

	var preview: Dictionary = AcademyResolver.preview_production(kingdom, template.card_name, 1, true)
	if not preview["valid"]:
		return

	var produce_counts: Dictionary = preview["new_cards_to_produce"]
	for ingredient_name: String in produce_counts:
		if ingredient_name == template.card_name:
			continue
		vbox.add_child(_build_ingredient_row(ingredient_name, produce_counts[ingredient_name]))

	if preview["total_fragment_cost"] > 0:
		vbox.add_child(_make_centered_label(
			"Fragmento (%s): × %d" % [preview["faction"], preview["total_fragment_cost"]],
			11, HUD_TEXT_COLOR
		))


func _build_ingredient_row(card_name: String, quantity: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var ingredient_template: CardResource = GameDatabase.get_card(card_name)
	if ingredient_template != null:
		var thumb_width: float = 32.0
		var thumb_slot := Control.new()
		thumb_slot.custom_minimum_size = Vector2(thumb_width, thumb_width / BattleCardView.CARD_ASPECT_RATIO)
		row.add_child(thumb_slot)

		var thumb_view := BattleCardView.new()
		thumb_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb_slot.add_child(thumb_view)
		thumb_view.set_card(ingredient_template)
		thumb_view.set_stats(ingredient_template.atk, ingredient_template.hp, ingredient_template.esc)
		thumb_view.set_compact(true)

	var name_label := _make_body_label(card_name)
	row.add_child(name_label)

	var quantity_label := _make_label("× %d" % quantity, 11, HUD_ACCENT)
	quantity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(quantity_label)

	return row


## --- Overlay ampliado do Comandante — mesmos dados/métodos já usados
## em comandantes_panel.gd (CommanderCareer, CommanderDoctrine),
## duplicado localmente. ---

func _build_commander_zoom_overlay(commander: CommanderResource, army: Army) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_zoom_backdrop_gui_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var panel := _make_card_panel()
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, minf(560.0, get_viewport_rect().size.y * 0.8))
	panel.add_child(scroll)
	_style_scrollbar(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.custom_minimum_size = Vector2(320, 0)
	scroll.add_child(vbox)

	var portrait_size: float = 150.0
	var portrait_slot := Control.new()
	portrait_slot.custom_minimum_size = Vector2(portrait_size, portrait_size)
	portrait_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_slot.clip_contents = true
	portrait_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	portrait_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	portrait_slot.gui_input.connect(_on_zoom_close_gui_input)
	vbox.add_child(portrait_slot)

	var texture: Texture2D = _portrait_for(commander)
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_slot.add_child(rect)

	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	vbox.add_child(_make_centered_label("%s | %s" % [commander.commander_name, patente], 16, HUD_TEXT_COLOR, true))
	vbox.add_child(_make_centered_label(commander.faction, 12, HUD_ACCENT))

	vbox.add_child(_make_separator())
	vbox.add_child(_make_centered_label("V:%d E:%d D:%d | WR: %.0f%%" % [
		commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0
	], 12, HUD_TEXT_COLOR))
	vbox.add_child(_make_centered_label(CommanderCareer.xp_progress_text(commander.accumulated_xp), 11, HUD_MUTED_COLOR, true))

	var display_name: String = army.army_name if army != null and army.army_name != "" else "este Exército"
	vbox.add_child(_make_centered_label("Função atual: Liderando %s" % display_name, 11, HUD_TEXT_COLOR, true))

	if commander.doctrine != null:
		vbox.add_child(_make_separator())
		vbox.add_child(_make_centered_label("Doutrina", 13, HUD_ACCENT))
		vbox.add_child(_make_body_label("Restrição: %s" % commander.doctrine.restriction_description()))
		vbox.add_child(_make_body_label("Requisito: %s" % commander.doctrine.requirement_description()))

		var target_text: String = commander.doctrine.target.description
		if commander.doctrine.target.value != "":
			target_text += " (%s)" % commander.doctrine.target.value
		vbox.add_child(_make_body_label("Alvo: %s" % target_text))
		vbox.add_child(_make_body_label("Efeito: %s" % commander.doctrine.effect.description))
		vbox.add_child(_make_body_label("Valor: %s" % commander.doctrine.value_description()))


func _on_zoom_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_zoom_card = null
		_zoom_commander = null
		_zoom_commander_army = null
		refresh()


## Clicar na própria Carta/retrato ampliado também fecha (evita
## precisar acertar o backdrop) — mesmo padrão de bestiario_panel.gd.
func _on_zoom_close_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_zoom_card = null
		_zoom_commander = null
		_zoom_commander_army = null
		refresh()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		if child == _editor_overlay:
			continue
		container.remove_child(child)
		child.free()


func _on_create_army_pressed() -> void:
	if _editor_overlay != null:
		return

	_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_editor_overlay.formation_count = 1
	_editor_overlay.army_ready.connect(_on_army_ready)
	_editor_overlay.cancelled.connect(_on_army_editor_cancelled)
	add_child(_editor_overlay)


func _on_edit_army_pressed(army: Army) -> void:
	if _editor_overlay != null:
		return

	_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_editor_overlay.existing_army = army
	_editor_overlay.editing_composition = true
	_editor_overlay.formation_count = 5
	_editor_overlay.army_ready.connect(_on_army_ready)
	_editor_overlay.cancelled.connect(_on_army_editor_cancelled)
	add_child(_editor_overlay)


func _on_army_ready(_army: Army) -> void:
	# Seleciona o Exército recém-criado/editado — a coluna de Detalhe já
	# mostra o resultado assim que o overlay do Editor fechar, sem
	# exigir um segundo clique na lista.
	_selected_army = _army
	call_deferred("_finish_army_creation")


func _finish_army_creation() -> void:
	if _editor_overlay != null:
		remove_child(_editor_overlay)
		_editor_overlay.queue_free()
		_editor_overlay = null
	refresh()


func _on_disband_pressed(army: Army) -> void:
	KingdomState.kingdom.disband_army(army)
	if _selected_army == army:
		_selected_army = null
	refresh()


func _on_army_editor_cancelled() -> void:
	call_deferred("_finish_army_creation")


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _anchor_new_control(parent: Control, rect: Rect2) -> Control:
	var control := Control.new()
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.clip_contents = true
	parent.add_child(control)
	return control


## "wrap" é false por padrão: texto curto de título/rótulo/valor NUNCA
## deve quebrar linha (evita o bug clássico do Godot em que um Label
## com AUTOWRAP_WORD_SMART, dentro de um Container ainda sem largura
## resolvida na primeira passada de layout, quebra letra-por-letra —
## foi exatamente o que produziu "T/O/T/A/L" verticalizado no resumo).
## Só texto longo de verdade (Doutrina, Unidades, ficha de Carta dentro
## dos overlays ampliados, que já têm largura mínima explícita) deve
## passar wrap=true.
func _make_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := _make_label(text, font_size, color, wrap)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_body_label(text: String) -> Label:
	var label := _make_label(text, 11, HUD_TEXT_COLOR, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _make_card_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.08)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Moldura de uma fileira da lista. Variante "selecionada" (borda mais
## grossa/dourada clara + fundo levemente mais claro) deixa óbvio qual
## Exército está sendo mostrado na coluna de Detalhe.
func _make_list_row_panel(selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.16)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = HUD_ACCENT_SELECTED
	else:
		style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.05)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_stat_chip(title_text: String, value_text: String) -> Control:
	var card := _make_card_panel()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.add_child(_make_centered_label(title_text, 10, HUD_MUTED_COLOR))
	vbox.add_child(_make_centered_label(value_text, 14, HUD_TEXT_COLOR))
	return card


## Botão de ação principal da faixa superior ("Criar Novo Exército") —
## mais alto/destacado que _make_small_button, com borda dourada clara
## acesa (HUD_ACCENT_SELECTED) pra se diferenciar visualmente de
## Editar/Desfazer (ações secundárias por Exército, na lista).
func _make_primary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(0, 40)
	_style_office_button(button)

	var accent_style := StyleBoxFlat.new()
	accent_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.20)
	accent_style.border_width_left = 2
	accent_style.border_width_right = 2
	accent_style.border_width_top = 2
	accent_style.border_width_bottom = 2
	accent_style.border_color = HUD_ACCENT_SELECTED
	accent_style.corner_radius_top_left = 4
	accent_style.corner_radius_top_right = 4
	accent_style.corner_radius_bottom_left = 4
	accent_style.corner_radius_bottom_right = 4
	accent_style.content_margin_left = 16.0
	accent_style.content_margin_right = 16.0
	# Só "normal"/"disabled" — hover/pressed/focus continuam os de
	# _style_office_button() (já realçados com HUD_ACCENT_SELECTED),
	# preservando o feedback de interação em vez de anular tudo com um
	# estilo estático único.
	button.add_theme_stylebox_override("normal", accent_style)
	button.add_theme_stylebox_override("disabled", accent_style)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 32)
	_style_office_button(button)
	return button


func _style_office_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	button.add_theme_color_override("font_disabled_color", HUD_MUTED_COLOR)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 10.0
	normal_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.22)
	hover_style.border_color = HUD_ACCENT_SELECTED
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var v_scroll: VScrollBar = scroll.get_v_scroll_bar()
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	grabber_style.corner_radius_top_left = 4
	grabber_style.corner_radius_top_right = 4
	grabber_style.corner_radius_bottom_left = 4
	grabber_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("grabber", grabber_style)
	var grabber_hover_style: StyleBoxFlat = grabber_style.duplicate()
	grabber_hover_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.9)
	v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover_style)
	v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_hover_style)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	track_style.corner_radius_top_left = 4
	track_style.corner_radius_top_right = 4
	track_style.corner_radius_bottom_left = 4
	track_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("scroll", track_style)
