extends Control
## CelestialChartsPanel (OBSERVATORY.md — Rankings/Comparações: TOP 10
## WR, BOTTOM 10 WR, Performance das Formações)
##
## Tela própria (nunca popup). Mesmo template retrato de
## observatory_overview_panel.gd (ver docstring lá para a justificativa
## de STRETCH_FIT) — código duplicado localmente, nunca importado.
##
## Fonte de dados real: SimulationReportService.load_balance_report()
## -> BalanceReport.cards_sorted_by_win_rate() (já existe no projeto).
## Nenhum valor de OBSERVATORY.md foi copiado pro código — os números
## exibidos vêm sempre do relatório carregado em tempo real (pedido
## §8: "NÃO duplicar valores diretamente no código se já houver uma
## fonte de dados do projeto").
##
## Top 10/Bottom 10 não cabem numa única caixa pequena do template (a
## coluna de 4 caixas foi calibrada pra ~1 linha curta cada, não 10
## linhas). Em vez de forçar 10 linhas numa caixa de ~1 linha (ilegível)
## ou inventar um painel novo fora do template, a lista usa a UNIÃO das
## 4 caixas da coluna esquerda/direita (LEFT_COLUMN_RECT/
## RIGHT_COLUMN_RECT) — ainda a mesma região que a própria arte já
## reserva pra conteúdo lateral, só sem fatiar entre as 4 sub-caixas.
##
## "Performance das Formações" e "Comparações de Cartas" (pedido) não
## têm fonte de dados de Formação no projeto — ficam marcadas como
## pendência.

const CHARTS_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/observatory_celestial_charts.png")
const CHARTS_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Mesmo template/calibração de observatory_overview_panel.gd. As
## colunas mescladas cobrem exatamente o topo da 1ª caixa até a base da
## 4ª caixa de cada lado (união das 4 sub-caixas, ver docstring).
const LEFT_COLUMN_RECT: Rect2 = Rect2(0.0371, 0.3809, 0.0899, 0.2005)
const RIGHT_COLUMN_RECT: Rect2 = Rect2(0.8730, 0.3809, 0.0908, 0.2005)
const BOTTOM_BOX_1: Rect2 = Rect2(0.1191, 0.7181, 0.1943, 0.0638)
const WIDE_BAR: Rect2 = Rect2(0.2500, 0.8158, 0.4990, 0.0475)

## Zona de Equilíbrio (OBSERVATORY.md, "Validação Fase 3B") — limites
## documentados, não inventados: 35%-65%. Aplicados aqui em cima dos
## dados REAIS do relatório carregado (nunca reafirmando os números
## históricos do próprio .md como se fossem o resultado atual).
const BALANCE_ZONE_LOWER: float = 0.35
const BALANCE_ZONE_UPPER: float = 0.65


func _ready() -> void:
	refresh()
	print("[CelestialChartsPanel] Pronto.")


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
	aspect.ratio = CHARTS_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = CHARTS_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var report: BalanceReport = SimulationReportService.load_balance_report()

	if report == null:
		_box_label(texture_rect, WIDE_BAR, "Nenhum relatório de balanceamento carregado ainda.", 12, HUD_MUTED_COLOR)
	else:
		var ranked: Array[String] = report.cards_sorted_by_win_rate()
		_box_label(texture_rect, LEFT_COLUMN_RECT, _format_ranking("TOP 10 WR", ranked, report, true), 9, HUD_TEXT_COLOR, VERTICAL_ALIGNMENT_TOP)
		_box_label(texture_rect, RIGHT_COLUMN_RECT, _format_ranking("BOTTOM 10 WR", ranked, report, false), 9, HUD_TEXT_COLOR, VERTICAL_ALIGNMENT_TOP)
		_box_label(texture_rect, BOTTOM_BOX_1, "Performance das Formações\n(pendência — sem dado de Formação)", 10, HUD_MUTED_COLOR)
		_box_label(texture_rect, WIDE_BAR, _format_balance_zone(ranked, report), 11, HUD_TEXT_COLOR)

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


func _format_ranking(title: String, ranked: Array[String], report: BalanceReport, top: bool) -> String:
	var slice: Array[String] = []
	if top:
		slice = ranked.slice(0, 10)
	else:
		var start: int = maxi(0, ranked.size() - 10)
		slice = ranked.slice(start, ranked.size())
		slice.reverse()

	var lines: Array[String] = [title]
	for i in range(slice.size()):
		var name: String = slice[i]
		lines.append("%d. %s %.1f%%" % [i + 1, name, report.card_win_rate(name) * 100.0])
	return "\n".join(lines)


## Zona de Equilíbrio (35%-65%, OBSERVATORY.md) aplicada aos dados REAIS
## do relatório carregado — nunca reafirma os números históricos do
## .md, só reaproveita o LIMIAR documentado.
func _format_balance_zone(ranked: Array[String], report: BalanceReport) -> String:
	var offenders: Array[String] = []
	for name: String in ranked:
		var wr: float = report.card_win_rate(name)
		if wr < BALANCE_ZONE_LOWER or wr > BALANCE_ZONE_UPPER:
			offenders.append(name)

	if offenders.is_empty():
		return "Zona de Equilíbrio (%.0f%%–%.0f%%): todas as %d cartas dentro do limite." % [
			BALANCE_ZONE_LOWER * 100.0, BALANCE_ZONE_UPPER * 100.0, ranked.size()
		]
	return "Zona de Equilíbrio (%.0f%%–%.0f%%): %d carta(s) fora do limite." % [
		BALANCE_ZONE_LOWER * 100.0, BALANCE_ZONE_UPPER * 100.0, offenders.size()
	]


func _box_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color, valign: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER) -> void:
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
	label.vertical_alignment = valign
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
