extends Control
## WorldMapGatePanel (WORLD_MAP_GATE.md)
##
## HUB VISUAL do World Map Gate — mesmo princípio arquitetural de
## Academia/Centro de Comando ("A ARTE É A INTERFACE"):
## world_map_gate.png preenche a tela inteira (AspectRatioContainer
## STRETCH_COVER); só hotspots INVISÍVEIS sobre elementos já presentes
## na própria arte. Localização própria da Cidade (CITY.md) — alcançada
## direto pelo hitbox do portão em city_panel.gd, nunca mais através do
## Centro de Comando.
##
## Correspondência visual dos 3 hotspots (inspeção direta de
## world_map_gate.png, 1672x941 — ver relatório da tarefa):
## - PvE: mesa circular central com relevo de terreno — elemento mais
##   prominente da sala, tema de "expedição/exploração" mais direto.
## - PvP: bancada esquerda com mapa de parede emoldurado.
## - MINAS: bancada direita com mapa de parede emoldurado.
##
## **Ressalva registrada:** as duas bancadas laterais (PvP/Minas) são
## visualmente quase idênticas em composição (mesa + mapa emoldurado
## na parede) — não há uma diferença temática clara entre elas na
## arte. A atribuição esquerda=PvP/direita=Minas é uma escolha
## razoável, não uma correspondência confirmada; pode ser invertida
## sem custo depois de inspeção direta no editor, caso o dono do
## projeto veja uma leitura melhor.
##
## Nenhuma cena de PvE/PvP/Minas foi duplicada ou alterada — apenas
## reaproveitadas (pve_panel.tscn/pvp_panel.tscn/minas_panel.tscn, sem
## mudança de caminho de arquivo).

const WORLD_MAP_GATE_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/world_map_gate.png")
const WORLD_MAP_GATE_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const PVE_SCENE_PATH: String = "res://scenes/command_center/panels/pve_panel.tscn"
const PVP_SCENE_PATH: String = "res://scenes/command_center/panels/pvp_panel.tscn"
const MINAS_SCENE_PATH: String = "res://scenes/command_center/panels/minas_panel.tscn"

## Mesa circular central com relevo de terreno.
const PVE_HOTSPOT_RECT: Rect2 = Rect2(0.337, 0.410, 0.331, 0.421)
## Bancada esquerda com mapa de parede emoldurado.
const PVP_HOTSPOT_RECT: Rect2 = Rect2(0.0, 0.158, 0.195, 0.263)
## Bancada direita com mapa de parede emoldurado.
const MINAS_HOTSPOT_RECT: Rect2 = Rect2(0.787, 0.158, 0.213, 0.263)

var _hover_name_container: Control
var _hover_name_label: Label

## FASE 12: node_name -> HotspotGlow — sinal luminoso discreto sobre
## cada hotspot desta tela (mesmo componente já usado na Cidade, ver
## city_panel.gd).
var _hotspot_glows: Dictionary = {}


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	_build_static_structure()
	print("[WorldMapGatePanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var gate_area := Control.new()
	gate_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	gate_area.clip_contents = true
	add_child(gate_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = WORLD_MAP_GATE_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	gate_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = WORLD_MAP_GATE_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_hotspot(texture_rect, "Hotspot_PvE", PVE_HOTSPOT_RECT, "PvE", PVE_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_PvP", PVP_HOTSPOT_RECT, "PvP", PVP_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Minas", MINAS_HOTSPOT_RECT, "Minas", MINAS_SCENE_PATH)

	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para a Cidade"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_to_city_pressed)
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
			print("[WorldMapGatePanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


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


func _on_back_to_city_pressed(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
