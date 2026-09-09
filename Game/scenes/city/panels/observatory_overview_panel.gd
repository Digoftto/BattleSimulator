extends Control
## ObservatoryOverviewPanel (OBSERVATORY.md — "RESUMO DA SIMULAÇÃO")
##
## Tela própria (nunca popup) — mesmo padrão arquitetural de sempre
## (imagem real dentro de AspectRatioContainer, hotspots/labels
## invisíveis por cima). Esta arte (OBSERVATORY-Observatory Overview.png,
## 1024x1536) é um template RETRATO com título + 4 caixas à esquerda +
## 4 à direita + 3 na base + 1 barra larga na base — mesmo estilo do
## Códice do Reino/Arquivo do Lore/Atlas do Mundo, por isso usa
## STRETCH_FIT (centralizado, letterboxed), NÃO STRETCH_COVER (esse é
## só para os HUBs de tela cheia como Observatory.png/Library-V1.png —
## ver CLAUDE.md §10 e o padrão já usado por capital_panel.gd nos
## pop-ups de mesmo estilo de arte).
##
## Fonte de dados: SimulationReportService.load_balance_report() (já
## existente no projeto, usado antes por uma versão anterior e mais
## simples deste painel) — nenhuma fonte nova criada, nenhum valor
## inventado. Campos SEM correspondente real no BalanceReport (Turnos
## Médios/Série, Integridade Individual, Consistência Global,
## Distribuição dos Placares, Performance das Formações, Auditoria de
## Limites) ficam com "—" ou uma nota de pendência, nunca um valor
## fabricado (pedido explícito §6/§17).

const OVERVIEW_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/observatory_overview.png")
const OVERVIEW_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Regiões calibradas por varredura de pixel (caixas escuras + barra
## azul) sobre OBSERVATORY-Observatory Overview.png, 1024x1536 — mesmo
## template reaproveitado pelas 4 telas do Observatório (ver relatório
## da tarefa).
const LEFT_BOX_1: Rect2 = Rect2(0.0371, 0.3809, 0.0899, 0.0358)
const LEFT_BOX_2: Rect2 = Rect2(0.0371, 0.4362, 0.0899, 0.0358)
const LEFT_BOX_3: Rect2 = Rect2(0.0371, 0.4909, 0.0899, 0.0358)
const LEFT_BOX_4: Rect2 = Rect2(0.0371, 0.5455, 0.0899, 0.0358)
const RIGHT_BOX_1: Rect2 = Rect2(0.8730, 0.3809, 0.0908, 0.0358)
const RIGHT_BOX_2: Rect2 = Rect2(0.8730, 0.4362, 0.0908, 0.0358)
const RIGHT_BOX_3: Rect2 = Rect2(0.8730, 0.4909, 0.0908, 0.0358)
const RIGHT_BOX_4: Rect2 = Rect2(0.8730, 0.5455, 0.0908, 0.0358)
const BOTTOM_BOX_1: Rect2 = Rect2(0.1191, 0.7181, 0.1943, 0.0638)
const BOTTOM_BOX_2: Rect2 = Rect2(0.3809, 0.7181, 0.2393, 0.0638)
const BOTTOM_BOX_3: Rect2 = Rect2(0.6885, 0.7181, 0.1914, 0.0638)
const WIDE_BAR: Rect2 = Rect2(0.2500, 0.8158, 0.4990, 0.0475)


func _ready() -> void:
	refresh()
	print("[ObservatoryOverviewPanel] Pronto.")


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
	aspect.ratio = OVERVIEW_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = OVERVIEW_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var report: BalanceReport = SimulationReportService.load_balance_report()

	if report == null:
		_box_label(texture_rect, WIDE_BAR, "Nenhum relatório de balanceamento carregado ainda.", 12, HUD_MUTED_COLOR)
	else:
		_box_label(texture_rect, LEFT_BOX_1, "Séries Simuladas\n%d" % report.series_count, 10, HUD_TEXT_COLOR)
		_box_label(texture_rect, LEFT_BOX_2, "Confrontos Individuais\n%d" % report.total_battles, 10, HUD_TEXT_COLOR)
		_box_label(texture_rect, LEFT_BOX_3, "Turnos Médios/Série\n— (pendência)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, LEFT_BOX_4, "Vitórias A\n%.1f%%" % (report.side_a_win_rate() * 100.0), 10, HUD_TEXT_COLOR)
		_box_label(texture_rect, RIGHT_BOX_1, "Vitórias B\n%.1f%%" % (report.side_b_win_rate() * 100.0), 10, HUD_TEXT_COLOR)
		_box_label(texture_rect, RIGHT_BOX_2, "Empates\n%d" % report.draws, 10, HUD_TEXT_COLOR)
		_box_label(texture_rect, RIGHT_BOX_3, "Integridade Individual\n— (pendência)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, RIGHT_BOX_4, "Consistência Global\n— (pendência)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, BOTTOM_BOX_1, "Distribuição dos Placares\n(pendência — sem dado por série)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, BOTTOM_BOX_2, "Performance das Formações\n(pendência — sem dado de Formação)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, BOTTOM_BOX_3, "Auditoria de Limites\n(pendência)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, WIDE_BAR, "\"%s\" — %d batalhas (%d séries)" % [report.label, report.total_battles, report.series_count], 12, HUD_TEXT_COLOR)

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
