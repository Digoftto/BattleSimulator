extends Control
## ObservatorioPanel (OBSERVATORY.md)
##
## HUB VISUAL do Observatório — mesmo princípio arquitetural já usado
## na Biblioteca (biblioteca_panel.gd): "A ARTE É A INTERFACE".
## Observatory.png preenche a tela inteira (AspectRatioContainer
## STRETCH_COVER, mesmo padrão de CityPanel/CapitalPanel/
## BibliotecaPanel); nenhuma barra, label ou painel permanente é
## desenhado por cima — só 4 hotspots INVISÍVEIS sobre elementos já
## presentes na própria arte, cada um levando a uma das 4 áreas do
## Observatório.
##
## Correspondência visual dos 4 hotspots (inspeção direta de
## Observatory.png, 1672x941):
## - OVERVIEW: a grande mesa circular iluminada no centro da sala (mapa-
##   relevo do Reino sobre um pedestal de múltiplos anéis) — a estrutura
##   mais central e grandiosa da cena.
## - CELESTIAL FORECAST: o grande aparato astronômico (esfera armilar
##   dourada) no fundo, sob a janela em arco central.
## - ASTRAL RESEARCH: a grande mesa com diorama de exércitos em miniatura
##   (peças azuis/marrons sobre um tabuleiro), no canto inferior
##   esquerdo — a "estação de pesquisa" mais distinta à esquerda.
## - CELESTIAL CHARTS: a grande mesa coberta de mapas/documentos/livros
##   abertos, no canto inferior direito.
## Os 4 Rect2 foram calibrados por inspeção visual direta (crops
## dedicados, ver relatório da tarefa) com margem entre si — nenhuma
## sobreposição.
##
## Cada tela interna é reaproveitada de bestiario_panel.tscn/
## biblioteca_panel.tscn no MESMO padrão (nunca popup, nunca cena
## modal) — troca de cena completa via change_scene_to_file, com botão
## "Voltar para o Observatório" em cada uma.

const OBSERVATORY_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/observatory_v1.png")
const OBSERVATORY_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const OVERVIEW_SCENE_PATH: String = "res://scenes/city/panels/observatory_overview_panel.tscn"
const ASTRAL_RESEARCH_SCENE_PATH: String = "res://scenes/city/panels/astral_research_panel.tscn"
const CELESTIAL_CHARTS_SCENE_PATH: String = "res://scenes/city/panels/celestial_charts_panel.tscn"
const CELESTIAL_FORECAST_SCENE_PATH: String = "res://scenes/city/panels/celestial_forecast_panel.tscn"

## Mesa circular central (mapa-relevo iluminado).
const OVERVIEW_HOTSPOT_RECT: Rect2 = Rect2(0.32, 0.36, 0.34, 0.34)
## Esfera armilar dourada, fundo/centro-superior.
const CELESTIAL_FORECAST_HOTSPOT_RECT: Rect2 = Rect2(0.38, 0.02, 0.24, 0.29)
## Mesa com diorama de exércitos em miniatura, canto inferior esquerdo.
const ASTRAL_RESEARCH_HOTSPOT_RECT: Rect2 = Rect2(0.02, 0.42, 0.24, 0.29)
## Mesa coberta de mapas/documentos, canto inferior direito.
const CELESTIAL_CHARTS_HOTSPOT_RECT: Rect2 = Rect2(0.74, 0.42, 0.24, 0.29)

var _hover_name_container: Control
var _hover_name_label: Label

## FASE 12: node_name -> HotspotGlow — sinal luminoso discreto sobre
## cada hotspot desta tela (mesmo componente já usado na Cidade, ver
## city_panel.gd).
var _hotspot_glows: Dictionary = {}


func _ready() -> void:
	_build_static_structure()
	print("[ObservatorioPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var observatory_area := Control.new()
	observatory_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	observatory_area.clip_contents = true
	add_child(observatory_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = OBSERVATORY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	observatory_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = OBSERVATORY_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- 4 hotspots invisíveis, cada um sobre o elemento visual
	# correspondente já presente na arte (ver docstring do topo). ---
	_build_hotspot(texture_rect, "Hotspot_Overview", OVERVIEW_HOTSPOT_RECT, "Visão Geral", OVERVIEW_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_AstralResearch", ASTRAL_RESEARCH_HOTSPOT_RECT, "Investigação Astral", ASTRAL_RESEARCH_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_CelestialCharts", CELESTIAL_CHARTS_HOTSPOT_RECT, "Cartas Celestiais", CELESTIAL_CHARTS_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_CelestialForecast", CELESTIAL_FORECAST_HOTSPOT_RECT, "Previsões Celestiais", CELESTIAL_FORECAST_SCENE_PATH)

	# --- Chip de hover (mesmo padrão Cinzel já usado na Biblioteca —
	# só aparece ao passar o mouse sobre um hotspot). ---
	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Voltar para a Cidade (mesmo chip/padrão da Biblioteca). ---
	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para a Cidade"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_chip_gui_input)
	add_child(back_container)


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


## Cria um Control invisível sobre `rect` (fração da arte), com hover
## (chip Cinzel) e clique — mesmo padrão de biblioteca_panel.gd. Todas
## as 4 telas internas já existem nesta implementação, então
## `scene_path` sempre resolve; o guard de existência é mantido mesmo
## assim (mesma robustez de biblioteca_panel.gd, nunca quebra se um
## caminho mudar).
func _build_hotspot(parent: Control, node_name: String, rect: Rect2, hover_text: String, scene_path: String) -> void:
	# FASE 12: sinal luminoso discreto — mesma fábrica reutilizável da
	# Cidade (hotspot_glow.gd), mesma região fracionária já calibrada.
	_hotspot_glows[node_name] = preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(parent, rect)

	var hotspot := Control.new()
	hotspot.name = node_name
	hotspot.anchor_left = rect.position.x
	hotspot.anchor_top = rect.position.y
	hotspot.anchor_right = rect.position.x + rect.size.x
	hotspot.anchor_bottom = rect.position.y + rect.size.y
	hotspot.offset_left = 0.0
	hotspot.offset_top = 0.0
	hotspot.offset_right = 0.0
	hotspot.offset_bottom = 0.0
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.gui_input.connect(_on_hotspot_gui_input.bind(scene_path))
	hotspot.mouse_entered.connect(_on_hotspot_mouse_entered.bind(hotspot, hover_text, node_name))
	hotspot.mouse_exited.connect(_on_hotspot_mouse_exited.bind(node_name))
	parent.add_child(hotspot)


func _on_hotspot_gui_input(event: InputEvent, scene_path: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file.call_deferred(scene_path)
		else:
			print("[ObservatorioPanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


func _on_hotspot_mouse_entered(hotspot: Control, hover_text: String, node_name: String = "") -> void:
	if _hotspot_glows.has(node_name):
		_hotspot_glows[node_name].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.HOVER)
	_hover_name_label.text = hover_text
	var chip_size: Vector2 = _hover_name_container.get_combined_minimum_size()
	_hover_name_container.size = chip_size

	var hotspot_rect: Rect2 = hotspot.get_global_rect()
	var x: float = hotspot_rect.position.x + hotspot_rect.size.x / 2.0 - chip_size.x / 2.0
	var y: float = hotspot_rect.position.y + hotspot_rect.size.y / 2.0 - chip_size.y / 2.0

	_hover_name_container.global_position = Vector2(x, y)
	_hover_name_container.visible = true


func _on_hotspot_mouse_exited(node_name: String = "") -> void:
	if _hotspot_glows.has(node_name):
		_hotspot_glows[node_name].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.AVAILABLE)
	_hover_name_container.visible = false


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
