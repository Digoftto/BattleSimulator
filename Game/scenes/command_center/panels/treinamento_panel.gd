extends Control
## TreinamentoPanel (COMMAND_CENTER_UI.md, "Janela: Treinamento")
##
## Resumo (Vagas, Média Diária, bônus do Legado I) + lista de
## Comandantes em Treinamento (tempo restante, XP do ciclo, progresso
## até a próxima Patente) + envio de Comandantes da Reserva. Mesmo
## padrão das demais janelas: árvore construída em código, sem estado
## próprio, reconstruída inteira a cada ação. Nenhuma regra de
## Treinamento foi alterada nesta etapa, só a apresentação.
##
## ETAPA 2 DE INTEGRAÇÃO VISUAL: primeira vez que esta tela ganha
## qualquer tratamento visual — antes era só ColorRect + Labels/Buttons
## nativos do Godot, sem nenhuma tipografia própria. Usa a nova moldura
## padrão do CdC ("Caixa de texto centro de comando.png", mesma de
## comandantes_panel.gd/exercitos_panel.gd/legado_panel.gd).
##
## Nenhum asset temático de "treino/instrução" existe no projeto (ver
## auditoria de assets da etapa anterior) — a identidade de "sala de
## instrução militar" vem inteiramente de composição Godot (barras de
## progresso, divisórias, hierarquia tipográfica), nunca de uma imagem
## nova. `Battle Planning.png` explicitamente NÃO foi usado aqui
## (decisão do pedido desta etapa).
##
## ETAPA 3 (direção de layout aprovada): barra do Ciclo de Treinamento
## mais alta/proeminente (era um traço fino de 10px) + uma 2ª barra real
## de progresso de Patente (era só o texto cru de
## CommanderCareer.xp_progress_text()) + retrato do Comandante em cada
## linha (mesmo mapeamento cosmético determinístico de
## comandantes_panel.gd/exercitos_panel.gd, duplicado localmente).

const FRAME_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/command_center_window_frame.png")
const FRAME_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const TITLE_RECT: Rect2 = Rect2(0.27, 0.14, 0.46, 0.06)
const CLOSE_BUTTON_RECT: Rect2 = Rect2(0.85, 0.12, 0.08, 0.12)
const INTERIOR_RECT: Rect2 = Rect2(0.095, 0.242, 0.809, 0.586)

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 3
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)

const TRAINING_CYCLE_SECONDS: int = 10 * 24 * 3600  # CommanderTrainingResolver.TRAINING_CYCLE_DAYS

const PORTRAIT_IMPERIO_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_1.png")
const PORTRAIT_IMPERIO_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_2.png")
const PORTRAIT_NATUREZA_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_1.png")
const PORTRAIT_NATUREZA_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_2.png")
const PORTRAIT_MORTOS_VIVOS_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_1.png")
const PORTRAIT_MORTOS_VIVOS_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_2.png")

var _em_treinamento_container: VBoxContainer
var _enviar_container: VBoxContainer


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[TreinamentoPanel] Pronto.")


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

	_build_title(texture_rect, "TREINAMENTO")
	_build_close_button(texture_rect)
	_build_interior(texture_rect)


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


func _build_interior(parent: Control) -> void:
	var area := _anchor_new_control(parent, INTERIOR_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	area.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	_build_resumo_bar(root_vbox)
	root_vbox.add_child(_make_separator())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	_build_em_treinamento_column(columns)
	columns.add_child(_make_vertical_separator())
	_build_enviar_column(columns)


func _build_resumo_bar(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var slots_used: int = 0
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state == CommanderResource.AdministrativeState.TRAINING:
			slots_used += 1
	var slots_cap: int = CommandCenterProgress.effective_training_slots(kingdom)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	parent.add_child(hbox)

	hbox.add_child(_make_stat_chip("Vagas de Treinamento", "%d / %d" % [slots_used, slots_cap]))
	hbox.add_child(_make_stat_chip("Média Diária de XP", str(kingdom.last_daily_average_xp)))
	hbox.add_child(_make_stat_chip("Bônus do Legado I", "+%.1f pp" % kingdom.legacy_i_xp_bonus_percent))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)


func _build_em_treinamento_column(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.55
	parent.add_child(vbox)

	vbox.add_child(_make_label("Em Treinamento", 15, HUD_ACCENT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_em_treinamento_container = VBoxContainer.new()
	_em_treinamento_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_em_treinamento_container)

	_refresh_em_treinamento()


func _refresh_em_treinamento() -> void:
	_clear_children(_em_treinamento_container)
	var kingdom: Kingdom = KingdomState.kingdom
	var now: int = GameClock.now_unix()

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.TRAINING:
			continue

		var card := _make_card_panel()
		_em_treinamento_container.add_child(card)
		var outer_row := HBoxContainer.new()
		outer_row.add_theme_constant_override("separation", 8)
		card.add_child(outer_row)

		outer_row.add_child(_make_avatar(commander, 52.0))

		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer_row.add_child(column)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var elapsed: int = now - commander.training_cycle_started_unix
		var remaining_seconds: int = maxi(0, TRAINING_CYCLE_SECONDS - elapsed)
		var remaining_days: float = remaining_seconds / 86400.0
		var cycle_progress: float = clampf(float(elapsed) / float(TRAINING_CYCLE_SECONDS), 0.0, 1.0)

		var header_row := HBoxContainer.new()
		column.add_child(header_row)
		var name_label := _make_label("%s | %s" % [commander.commander_name, patente], 12, HUD_TEXT_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(name_label)
		header_row.add_child(_make_label("Faltam ~%.1f dias" % remaining_days, 11, HUD_MUTED_COLOR))

		column.add_child(_make_progress_bar(cycle_progress, "Ciclo de Treinamento"))
		column.add_child(_make_body_label("XP do ciclo: %d" % commander.training_accumulated_xp))
		column.add_child(_make_progress_bar(_patente_progress_ratio(commander.accumulated_xp), CommanderCareer.xp_progress_text(commander.accumulated_xp)))

		var cancel_button := _make_small_button("Cancelar Treinamento")
		cancel_button.pressed.connect(_on_cancel_training_pressed.bind(commander), CONNECT_DEFERRED)
		column.add_child(cancel_button)

	if _em_treinamento_container.get_child_count() == 0:
		_em_treinamento_container.add_child(_make_body_label("Nenhum Comandante em Treinamento."))


func _build_enviar_column(parent: Control) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.45
	parent.add_child(vbox)

	vbox.add_child(_make_label("Enviar da Reserva", 15, HUD_ACCENT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_enviar_container = VBoxContainer.new()
	_enviar_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_enviar_container)

	_refresh_enviar()


func _refresh_enviar() -> void:
	_clear_children(_enviar_container)
	var kingdom: Kingdom = KingdomState.kingdom

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
			continue

		var card := _make_card_panel()
		_enviar_container.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		row.add_child(_make_avatar(commander, 36.0))

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var label := _make_body_label("%s | %s | %s" % [commander.commander_name, patente, commander.faction])
		row.add_child(label)

		var button := _make_small_button("Enviar")
		button.pressed.connect(_on_send_to_training_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(button)

	if _enviar_container.get_child_count() == 0:
		_enviar_container.add_child(_make_body_label("Nenhum Comandante na Reserva pra enviar."))


## Fração 0..1 do progresso de XP até a próxima Patente (mesma Tabela
## Oficial de CommanderCareer.xp_progress_text() — nunca reinventa os
## limiares). 1.0 quando já na Patente máxima (Lorde-Comandante).
func _patente_progress_ratio(accumulated_xp: int) -> float:
	var thresholds: Array[Dictionary] = CommanderCareer.PATENTE_THRESHOLDS
	for i in range(thresholds.size() - 1):
		if accumulated_xp < thresholds[i + 1]["xp"]:
			var floor_xp: int = thresholds[i]["xp"]
			var ceiling_xp: int = thresholds[i + 1]["xp"]
			return clampf(float(accumulated_xp - floor_xp) / float(ceiling_xp - floor_xp), 0.0, 1.0)
	return 1.0


## --- Retratos (cosméticos, determinísticos — mesmo mapeamento de
## comandantes_panel.gd/exercitos_panel.gd, duplicado localmente). ---

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


func _make_avatar(commander: CommanderResource, size: float) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(size, size)
	slot.clip_contents = true

	var texture: Texture2D = _portrait_for(commander)
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
	border_style.border_width_left = 1
	border_style.border_width_right = 1
	border_style.border_width_top = 1
	border_style.border_width_bottom = 1
	border_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.7)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)

	return slot


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_cancel_training_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_reserve(KingdomState.kingdom, commander)
	refresh()


func _on_send_to_training_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_training(KingdomState.kingdom, commander, GameClock.now_unix())
	refresh()


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


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_body_label(text: String) -> Label:
	var label := _make_label(text, 11, HUD_TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _make_vertical_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(1, 0)
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


func _make_stat_chip(title_text: String, value_text: String) -> Control:
	var card := _make_card_panel()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.add_child(_make_centered_label(title_text, 10, HUD_MUTED_COLOR))
	vbox.add_child(_make_centered_label(value_text, 14, HUD_TEXT_COLOR))
	return card


## Barra de progresso temática (dourado sobre navy) — substitui o
## "Faltam X dias" cru por um indicador visual real, sem exigir
## nenhuma arte nova (só StyleBoxFlat, mesmo espírito de "identidade
## militar construída em Godot" pedido nesta etapa).
func _make_progress_bar(ratio: float, label_text: String) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var caption := _make_label(label_text, 10, HUD_MUTED_COLOR)
	container.add_child(caption)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = ratio
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HUD_ACCENT_SELECTED
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)

	container.add_child(bar)
	return container


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 11)
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
	normal_style.content_margin_left = 6.0
	normal_style.content_margin_right = 6.0
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
