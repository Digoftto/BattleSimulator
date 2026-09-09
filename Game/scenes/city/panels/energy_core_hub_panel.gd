extends Control
## EnergyCoreHubPanel (ENERGY_NUCLEUS.md)
##
## HUB VISUAL do Núcleo de Energia — mesmo princípio arquitetural já
## usado no Observatório/Biblioteca/Depósito (observatorio_panel.gd):
## "A ARTE É A INTERFACE". `energy core.png` preenche a tela inteira
## (AspectRatioContainer STRETCH_COVER, mesmo padrão de CityPanel/
## ObservatorioPanel); nenhuma barra, label ou painel permanente é
## desenhado por cima — só UM hotspot INVISÍVEL sobre o reator central
## já presente na própria arte.
##
## Escopo desta etapa (pedido explícito): esta tela tem uma única
## função — abrir a janela de evolução do Núcleo
## (energy_core_panel.tscn, já implementada e validada, NÃO
## modificada por este arquivo). Energy Distribution, Crystal
## Processing, Power Network e qualquer outro sistema do Núcleo
## seguem fora do MVP atual — nenhum hotspot foi criado para eles.
##
## Correspondência visual do hotspot (inspeção direta de
## energy core.png, 1672x941, ver relatório da tarefa): a estrutura
## circular elevada de anéis dourados com o cristal azul brilhante no
## centro da sala — o elemento dominante e mais central da cena.
## Retângulo calibrado por grade de pixels (crops dedicados), cobrindo
## a plataforma octogonal completa (anéis + cristal) sem alcançar as
## bancadas/maquinário decorativos das laterais nem o altar ao fundo.
const ENERGY_CORE_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/nucleo_de_energia.png")
const ENERGY_CORE_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const EVOLUTION_WINDOW_SCENE: String = "res://scenes/city/panels/energy_core_panel.tscn"

## Reator central (anéis dourados + cristal azul), calibrado sobre
## energy core.png (1672x941) — ver docstring acima.
const CENTRAL_REACTOR_HOTSPOT_RECT: Rect2 = Rect2(0.334928, 0.286929, 0.352871, 0.414453)

var _hover_name_container: Control
var _hover_name_label: Label

## FASE 12: sinal luminoso discreto sobre o reator central (mesmo
## componente já usado na Cidade, ver city_panel.gd) — só 1 hotspot
## nesta tela, então uma única referência basta (sem Dictionary).
var _hotspot_glow = null


func _ready() -> void:
	_build_static_structure()
	print("[EnergyCoreHubPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var hub_area := Control.new()
	hub_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	hub_area.clip_contents = true
	add_child(hub_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = ENERGY_CORE_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	hub_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ENERGY_CORE_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- Hotspot único sobre o reator central (pedido explícito: nada
	# de tela inteira, nada de área genérica, nada de múltiplos
	# hotspots). ---
	_build_hotspot(texture_rect, "Hotspot_NucleoReator", CENTRAL_REACTOR_HOTSPOT_RECT, "Núcleo de Energia")

	# --- Chip de hover (mesmo padrão Cinzel já usado no Observatório). ---
	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Voltar para a Cidade (mesmo chip/padrão do Observatório). ---
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
## (chip Cinzel) e clique — mesmo padrão de observatorio_panel.gd.
func _build_hotspot(parent: Control, node_name: String, rect: Rect2, hover_text: String) -> void:
	# FASE 12: sinal luminoso discreto — mesma fábrica reutilizável da
	# Cidade (hotspot_glow.gd), mesma região fracionária já calibrada.
	_hotspot_glow = preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(parent, rect)

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
	hotspot.gui_input.connect(_on_hotspot_gui_input)
	hotspot.mouse_entered.connect(_on_hotspot_mouse_entered.bind(hotspot, hover_text))
	hotspot.mouse_exited.connect(_on_hotspot_mouse_exited)
	parent.add_child(hotspot)


func _on_hotspot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(EVOLUTION_WINDOW_SCENE)


func _on_hotspot_mouse_entered(hotspot: Control, hover_text: String) -> void:
	if _hotspot_glow != null:
		_hotspot_glow.set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.HOVER)
	_hover_name_label.text = hover_text
	var chip_size: Vector2 = _hover_name_container.get_combined_minimum_size()
	_hover_name_container.size = chip_size

	var hotspot_rect: Rect2 = hotspot.get_global_rect()
	var x: float = hotspot_rect.position.x + hotspot_rect.size.x / 2.0 - chip_size.x / 2.0
	var y: float = hotspot_rect.position.y + hotspot_rect.size.y / 2.0 - chip_size.y / 2.0

	_hover_name_container.global_position = Vector2(x, y)
	_hover_name_container.visible = true


func _on_hotspot_mouse_exited() -> void:
	if _hotspot_glow != null:
		_hotspot_glow.set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.AVAILABLE)
	_hover_name_container.visible = false


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
