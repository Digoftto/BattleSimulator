extends Control
## LegadoPanel (COMMAND_CENTER_UI.md, "Janela: Legado")
##
## Resumo Administrativo + Aposentar um Comandante (Legado
## Administrativo) + Grande Legado Militar + Hall dos Comandantes.
## Mesmo padrão das demais janelas: árvore em código, sem estado
## próprio (exceto qual destino/atributo cada linha tem selecionado),
## reconstruída inteira a cada ação. Nenhuma regra de Legado foi
## alterada nesta etapa, só a apresentação.
##
## ETAPA 2 DE INTEGRAÇÃO VISUAL: troca da antiga arte "Veteran Records"
## (fundo completo, 2 colunas fixas) pela nova moldura padrão do CdC —
## área interna livre reorganizada em 3 colunas iguais (Aposentar |
## Grande Legado Militar | Hall), todas visíveis ao mesmo tempo, sem
## precisar de aba pra nenhuma das três.
##
## ETAPA 3 (direção de layout aprovada): as 3 colunas iguais davam ao
## Hall — o registro permanente e "memorial" dos Comandantes
## aposentados — o mesmo peso visual que 2 formulários de ação
## operacional (Aposentar, Grande Legado). Discordância explícita
## corrigida: agora são 2 colunas — Aposentar + Grande Legado Militar
## empilhados numa coluna estreita à esquerda (ambos formulários de
## ação, cabem bem empilhados) e o Hall dos Comandantes ocupa uma
## coluna larga à direita, com retrato do Comandante em cada entrada
## (mesmo mapeamento cosmético determinístico das demais janelas do
## CdC) reforçando a leitura de "galeria/memorial", não só texto.
##
## Grande Legado Militar continua simplificado: não existe ainda um
## Editor de Exército embutido nesta tela — listamos os Exércitos já
## existentes e deixamos o próprio LegacyResolver validar/reportar.

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
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)

const PORTRAIT_IMPERIO_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_1.png")
const PORTRAIT_IMPERIO_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_2.png")
const PORTRAIT_NATUREZA_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_1.png")
const PORTRAIT_NATUREZA_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_2.png")
const PORTRAIT_MORTOS_VIVOS_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_1.png")
const PORTRAIT_MORTOS_VIVOS_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_2.png")

var _aposentar_container: VBoxContainer
var _hall_container: VBoxContainer
var _grande_legado_container: VBoxContainer
var _doutrina_label: Label
var _action_status_label: Label

var _legado_v_destino_by_commander: Dictionary = {}  # instance_id -> "xp"/"resources"/"fragments"
var _attribute_choice_by_army: Dictionary = {}  # army (referência) -> "escudo"/"vida"/"ataque"


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[LegadoPanel] Pronto. Comandantes elegíveis pra aposentar: %d | Hall: %d" % [
		_aposentar_container.get_child_count() if _aposentar_container != null else 0, KingdomState.kingdom.commander_hall().size()
	])


func refresh() -> void:
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

	_build_title(texture_rect, "LEGADO")
	_build_close_button(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	_build_interior(texture_rect, kingdom)


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


func _build_interior(parent: Control, kingdom: Kingdom) -> void:
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

	_build_resumo_bar(root_vbox, kingdom)
	root_vbox.add_child(_make_separator())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	_build_acoes_column(columns, kingdom)
	columns.add_child(_make_vertical_separator())
	_build_hall_column(columns, kingdom)


## Coluna estreita à esquerda: Aposentar (topo) + Grande Legado Militar
## (embaixo) empilhados — os 2 formulários de ação operacional, menos
## peso visual que o Hall (ver docstring do topo).
func _build_acoes_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.40
	parent.add_child(vbox)

	_build_aposentar_column(vbox, kingdom)
	vbox.add_child(_make_separator())
	_build_grande_legado_column(vbox, kingdom)


func _build_resumo_bar(parent: Control, kingdom: Kingdom) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	parent.add_child(hbox)

	hbox.add_child(_make_stat_chip("Total Aposentados", str(kingdom.legacy_administrative_retirees)))
	hbox.add_child(_make_stat_chip("Legado I (Treinamento)", "+%.1f pp" % kingdom.legacy_i_xp_bonus_percent))
	hbox.add_child(_make_stat_chip("Legado V", "XP+%.2f%% Rec+%.2f%% Frag+%.2f%%" % [
		kingdom.legacy_v_bonus_xp, kingdom.legacy_v_bonus_resources, kingdom.legacy_v_bonus_fragments
	]))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	_action_status_label = _make_label("", 11, HUD_ERROR_COLOR)
	hbox.add_child(_action_status_label)


func _build_aposentar_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)

	vbox.add_child(_make_label("Aposentar (Legado Administrativo)", 14, HUD_ACCENT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_aposentar_container = VBoxContainer.new()
	_aposentar_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_aposentar_container)

	_refresh_aposentar(kingdom)


func _refresh_aposentar(kingdom: Kingdom) -> void:
	_clear_children(_aposentar_container)

	for commander: CommanderResource in kingdom.commanders:
		var state: CommanderResource.AdministrativeState = commander.administrative_state
		if state != CommanderResource.AdministrativeState.RESERVE and state != CommanderResource.AdministrativeState.ACTIVE:
			continue

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		if not LegacyResolver.meets_patente(patente, LegacyResolver.PATENTE_MIN_LEGADO_I):
			continue

		var card := _make_card_panel()
		_aposentar_container.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)

		column.add_child(_make_body_label("%s | %s | %s" % [commander.commander_name, patente, commander.faction]))

		var destino_option := OptionButton.new()
		destino_option.add_theme_font_size_override("font_size", 10)
		destino_option.add_item("Legado V: XP", 0)
		destino_option.add_item("Legado V: Recursos", 1)
		destino_option.add_item("Legado V: Fragmentos", 2)
		var destino_map: Array[String] = ["xp", "resources", "fragments"]
		var saved_destino: String = _legado_v_destino_by_commander.get(commander.instance_id, "xp")
		destino_option.selected = destino_map.find(saved_destino)
		destino_option.item_selected.connect(_on_legado_v_destino_selected.bind(commander, destino_map), CONNECT_DEFERRED)
		column.add_child(destino_option)

		var button := _make_small_button("Aposentar")
		button.pressed.connect(_on_retire_administrative_pressed.bind(commander), CONNECT_DEFERRED)
		column.add_child(button)

	if _aposentar_container.get_child_count() == 0:
		_aposentar_container.add_child(_make_body_label("Nenhum Comandante elegível (Reserva ou Ativo, Patente mínima Capitão)."))


func _build_grande_legado_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)

	vbox.add_child(_make_label("Grande Legado Militar", 14, HUD_ACCENT))

	_doutrina_label = _make_body_label("")
	vbox.add_child(_doutrina_label)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_grande_legado_container = VBoxContainer.new()
	_grande_legado_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_grande_legado_container)

	_refresh_grande_legado(kingdom)


func _refresh_grande_legado(kingdom: Kingdom) -> void:
	if kingdom.command_center_level < LegacyResolver.GRANDE_LEGADO_CDC_LEVEL:
		_doutrina_label.text = "Bloqueado — exige Centro de Comando Nível %d (atual: %d)." % [
			LegacyResolver.GRANDE_LEGADO_CDC_LEVEL, kingdom.command_center_level
		]
		_clear_children(_grande_legado_container)
		return

	var doctrine_lines: Array[String] = []
	for faction: String in LegacyResolver.DOCTRINE_LIMITS:
		kingdom.ensure_military_doctrine(faction)
		var d: Dictionary = kingdom.military_doctrine[faction]
		var limits: Dictionary = LegacyResolver.DOCTRINE_LIMITS[faction]
		doctrine_lines.append("%s — Escudo %d/%d | Vida %d/%d | Ataque %d/%d" % [
			faction, d["escudo"], limits["escudo"], d["vida"], limits["vida"], d["ataque"], limits["ataque"]
		])
	_doutrina_label.text = "\n".join(doctrine_lines)

	_clear_children(_grande_legado_container)
	for army: Army in kingdom.armies:
		if army.commander == null:
			continue

		var card := _make_card_panel()
		_grande_legado_container.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)

		var patente: String = CommanderCareer.patente_for_xp(army.commander.accumulated_xp)
		column.add_child(_make_body_label("%s (%s, %s)" % [army.commander.commander_name, patente, army.commander.faction]))

		var attribute_option := OptionButton.new()
		attribute_option.add_theme_font_size_override("font_size", 10)
		attribute_option.add_item("Escudo", 0)
		attribute_option.add_item("Vida", 1)
		attribute_option.add_item("Ataque", 2)
		var attribute_map: Array[String] = ["escudo", "vida", "ataque"]
		var saved_attribute: String = _attribute_choice_by_army.get(army, "escudo")
		attribute_option.selected = attribute_map.find(saved_attribute)
		attribute_option.item_selected.connect(_on_attribute_choice_selected.bind(army, attribute_map), CONNECT_DEFERRED)
		column.add_child(attribute_option)

		var button := _make_small_button("Criar Grande Legado")
		button.pressed.connect(_on_create_grande_legado_pressed.bind(army), CONNECT_DEFERRED)
		column.add_child(button)

	if _grande_legado_container.get_child_count() == 0:
		_grande_legado_container.add_child(_make_body_label("Nenhum Exército no Reino no momento."))


func _build_hall_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.60
	parent.add_child(vbox)

	vbox.add_child(_make_label("Hall dos Comandantes", 14, HUD_ACCENT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_hall_container = VBoxContainer.new()
	_hall_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_hall_container)

	_refresh_hall(kingdom)


## Cada Comandante aposentado vira um "quadro" no memorial — moldura
## própria + retrato, não só uma linha de texto (ver docstring do
## topo: o Hall ganha o peso visual que antes ficava dividido igual
## entre as 3 colunas).
func _refresh_hall(kingdom: Kingdom) -> void:
	_clear_children(_hall_container)

	for commander: CommanderResource in kingdom.commander_hall():
		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)

		var frame := _make_hall_frame_panel()
		_hall_container.add_child(frame)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		frame.add_child(row)

		row.add_child(_make_avatar(commander, 56.0))

		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)

		column.add_child(_make_label("%s | %s | %s" % [commander.commander_name, patente, commander.faction], 12, HUD_ACCENT))
		column.add_child(_make_body_label("Tipo: %s | %s" % [commander.retirement_type, commander.retirement_benefit]))

	if _hall_container.get_child_count() == 0:
		_hall_container.add_child(_make_body_label("Nenhum Comandante aposentado ainda."))


## Moldura mais ornamentada que o `_make_card_panel()` padrão (borda
## dourada mais grossa) — reforça o tom de "memorial permanente" das
## demais listas de ação operacional desta mesma janela.
func _make_hall_frame_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.10)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.55)
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


## --- Retratos (cosméticos, determinísticos — mesmo mapeamento das
## demais janelas do CdC, duplicado localmente). ---

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
	border_style.border_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.7)
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


func _on_legado_v_destino_selected(index: int, commander: CommanderResource, destino_map: Array[String]) -> void:
	_legado_v_destino_by_commander[commander.instance_id] = destino_map[index]


func _on_attribute_choice_selected(index: int, army: Army, attribute_map: Array[String]) -> void:
	_attribute_choice_by_army[army] = attribute_map[index]


func _legado_failure_message(reason: String) -> String:
	match reason:
		"invalid_state":
			return "Não foi possível concluir: o Comandante não está num estado válido para esta ação."
		"army_still_assigned":
			return "Não foi possível aposentar: o Comandante ainda está à frente de um Exército — desvincule-o primeiro."
		"below_minimum_patente":
			return "Não foi possível aposentar: o Comandante ainda não atingiu a Patente mínima exigida."
		"missing_legado_v_destino":
			return "Escolha um destino (XP, Recursos ou Fragmentos) para o bônus do Legado V antes de aposentar."
		"cdc_level_too_low":
			return "O Nível do Centro de Comando ainda não permite criar um Grande Legado Militar."
		"below_max_patente":
			return "O Comandante ainda não atingiu a Patente máxima exigida para um Grande Legado Militar."
		"soldo_not_fully_used":
			return "O Exército precisa usar todo o Soldo disponível para criar um Grande Legado Militar."
		"army_incomplete":
			return "O Exército precisa estar com a Formação completa para criar um Grande Legado Militar."
		"cards_not_max_tier":
			return "Todas as Cartas do Exército precisam estar no Tier máximo para criar um Grande Legado Militar."
		"faction_mismatch":
			return "A Facção do Exército não corresponde à exigida para este Grande Legado Militar."
		"invalid_attribute_choice":
			return "Escolha um atributo válido para o Grande Legado Militar."
		_:
			return "Não foi possível concluir (%s)." % reason


func _on_retire_administrative_pressed(commander: CommanderResource) -> void:
	var destino: String = _legado_v_destino_by_commander.get(commander.instance_id, "xp")
	var result: Dictionary = LegacyResolver.retire_administrative(KingdomState.kingdom, commander, GameClock.now_unix(), destino)
	if not result["success"]:
		print("[LegadoPanel] Aposentadoria (Legado Administrativo) falhou: %s" % result["reason"])
		_action_status_label.text = _legado_failure_message(result["reason"])
	else:
		_action_status_label.text = ""
	refresh()


func _on_create_grande_legado_pressed(army: Army) -> void:
	var attribute_choice: String = _attribute_choice_by_army.get(army, "escudo")
	var result: Dictionary = LegacyResolver.create_grande_legado_militar(
		KingdomState.kingdom, army.commander, army, GameClock.now_unix(), attribute_choice
	)
	if not result["success"]:
		print("[LegadoPanel] Grande Legado Militar falhou: %s" % result["reason"])
		_action_status_label.text = _legado_failure_message(result["reason"])
	else:
		_action_status_label.text = ""
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
	vbox.add_child(_make_centered_label(value_text, 12, HUD_TEXT_COLOR))
	return card


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
