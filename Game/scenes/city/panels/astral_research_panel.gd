extends Control
## AstralResearchPanel (OBSERVATORY.md — escopo: cartas, facções,
## formações, exércitos, minas)
##
## Tela própria (nunca popup). Mesmo template retrato de
## observatory_overview_panel.gd (ver docstring lá para a justificativa
## de STRETCH_FIT) — código duplicado localmente, nunca importado
## entre painéis (mesma regra de sempre deste projeto).
##
## Fontes de dados reais reaproveitadas (nenhuma nova criada):
## - GameDatabase.cards — catálogo de Cartas (39) e suas Facções.
## - Kingdom.armies / Kingdom.all_mines() — Exércitos/Minas do Reino do
##   jogador atual (KingdomState.kingdom).
## - SimulationReportService.load_balance_report() — cartas com Win
##   Rate já analisado, se houver relatório gerado.
## "Formações" (ALPHA/BETA/GAMMA/DELTA/EPSILON de OBSERVATORY.md) não
## tem nenhuma fonte de dados viva no projeto — fica marcado como
## pendência, não inventado (pedido §7/§17).

const RESEARCH_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/observatory_astral_research.png")
const RESEARCH_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Mesmo template/calibração de observatory_overview_panel.gd (as 4
## artes do Observatório compartilham a mesma moldura 1024x1536).
const LEFT_BOX_1: Rect2 = Rect2(0.0371, 0.3809, 0.0899, 0.0358)
const LEFT_BOX_2: Rect2 = Rect2(0.0371, 0.4362, 0.0899, 0.0358)
const LEFT_BOX_3: Rect2 = Rect2(0.0371, 0.4909, 0.0899, 0.0358)
const LEFT_BOX_4: Rect2 = Rect2(0.0371, 0.5455, 0.0899, 0.0358)
const RIGHT_BOX_1: Rect2 = Rect2(0.8730, 0.3809, 0.0908, 0.0358)
const RIGHT_BOX_2: Rect2 = Rect2(0.8730, 0.4362, 0.0908, 0.0358)
const BOTTOM_BOX_1: Rect2 = Rect2(0.1191, 0.7181, 0.1943, 0.0638)


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[AstralResearchPanel] Pronto.")


func refresh() -> void:
	_clear_children(self)
	_build_structure()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _build_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = RESEARCH_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = RESEARCH_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	var faction_counts: Dictionary = _count_cards_by_faction()
	var report: BalanceReport = SimulationReportService.load_balance_report()

	_box_label(texture_rect, LEFT_BOX_1, "Cartas no Catálogo\n%d" % GameDatabase.cards.size(), 10, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_BOX_2, "Facções\nImpério %d | Natureza %d | M.Vivos %d" % [
		faction_counts.get("Império", 0), faction_counts.get("Natureza", 0), faction_counts.get("Mortos-Vivos", 0)
	], 9, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_BOX_3, "Formações\n— (pendência)", 10, HUD_MUTED_COLOR)
	_box_label(texture_rect, LEFT_BOX_4, "Exércitos no Reino\n%d" % kingdom.armies.size(), 10, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_BOX_1, "Minas Ativas\n%d" % kingdom.all_mines().size(), 10, HUD_TEXT_COLOR)
	if report != null:
		_box_label(texture_rect, RIGHT_BOX_2, "Cartas Analisadas\n%d (relatório)" % report.card_stats.size(), 9, HUD_TEXT_COLOR)
	else:
		_box_label(texture_rect, RIGHT_BOX_2, "Cartas Analisadas\n— (sem relatório)", 9, HUD_MUTED_COLOR)
	_box_label(texture_rect, BOTTOM_BOX_1, "Análise por Formação/Exército/Mina\n(pendência — estrutura preparada)", 10, HUD_MUTED_COLOR)

	# --- Voltar para o Observatório ---
	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para o Observatório"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_chip_gui_input)
	add_child(back_container)


func _count_cards_by_faction() -> Dictionary:
	var counts: Dictionary = {}
	for card: CardResource in GameDatabase.cards:
		counts[card.faction] = counts.get(card.faction, 0) + 1
	return counts


func _box_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.anchor_left = rect.position.x
	label.anchor_top = rect.position.y
	label.anchor_right = rect.position.x + rect.size.x
	label.anchor_bottom = rect.position.y + rect.size.y
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)


func _build_chip() -> Dictionary:
	var chip := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.10)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	chip.add_child(label)

	return {"container": chip, "label": label}


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/panels/observatorio_panel.tscn")
