extends Control
## AcademiaPanel (ACADEMY.md)
##
## HUB VISUAL da Academia — mesmo princípio arquitetural do Depósito/
## Biblioteca/Observatório ("A ARTE É A INTERFACE"): academia_v1.png
## preenche a tela inteira (AspectRatioContainer STRETCH_COVER);
## nenhuma barra, label ou painel permanente é desenhado por cima — só
## 3 hotspots INVISÍVEIS sobre elementos já presentes na própria arte.
##
## Correspondência visual dos 3 hotspots (inspeção direta de
## academia_v1.png, 1672x941, com varredura de grade normalizada — ver
## relatório da tarefa):
## - PRODUÇÃO: fileiras de bancadas com ferramentas/plantas e brilho
##   azul, lado esquerdo — Salão dos Artífices (ACADEMY.md).
## - APRIMORAMENTO: plataformas circulares em degraus com reatores de
##   cristal, lado direito — Salão dos Metamorfos (ACADEMY.md).
## - EVOLUÇÃO: pequeno modelo de castelo sobre um pedestal/mesa,
##   centro-frente — única correspondência visual plausível para
##   "evoluir a construção" (mesmo raciocínio já usado no Depósito:
##   elemento mais isolado/dedicado, aqui literalmente uma miniatura do
##   prédio). InstitutionalConstructionResolver.evolve(ACADEMIA).
##
## O grande cristal central e as estantes ao fundo permanecem
## decorativos — nenhum sistema real corresponde a eles isoladamente
## (decisão confirmada com o dono do projeto: Mestres/Fila ficam
## embutidos nas telas de Produção/Aprimoramento, sem hotspot próprio;
## e a "Biblioteca" já é um prédio separado da Cidade, biblioteca_panel.tscn
## — as estantes aqui não duplicam aquele sistema).
##
## Nenhuma mecânica especulativa de Fundation/ACADEMY_INTERACTION_LAYOUT.md
## (Research Core, Technology Tree, Knowledge Archive, forja de
## equipamentos) foi implementada — não existe suporte real no código
## para nenhuma delas (ver relatório da auditoria).
##
## Cada tela interna é reaproveitada no MESMO padrão de sempre (nunca
## popup, nunca cena modal) — troca de cena completa via
## change_scene_to_file, com botão "Voltar para a Academia" em cada uma.

const ACADEMIA_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/academia_v1.png")
const ACADEMIA_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const PRODUCAO_SCENE_PATH: String = "res://scenes/city/panels/academia_producao_panel.tscn"
const APRIMORAMENTO_SCENE_PATH: String = "res://scenes/city/panels/academia_aprimoramento_panel.tscn"
const EVOLUCAO_SCENE_PATH: String = "res://scenes/city/panels/academia_evolucao_panel.tscn"

## Fileiras de bancadas dos Artífices, lado esquerdo.
const PRODUCAO_HOTSPOT_RECT: Rect2 = Rect2(0.0, 0.29, 0.40, 0.62)
## Plataformas circulares dos Metamorfos, lado direito.
const APRIMORAMENTO_HOTSPOT_RECT: Rect2 = Rect2(0.60, 0.27, 0.38, 0.69)
## Modelo do castelo sobre o pedestal, centro-frente.
const EVOLUCAO_HOTSPOT_RECT: Rect2 = Rect2(0.42, 0.71, 0.165, 0.22)

var _hover_name_container: Control
var _hover_name_label: Label

## FASE 15: node_name (mesmo nome já passado a _build_hotspot()) ->
## HotspotGlow — AcademiaPanel nunca recebeu o sinal luminoso da Fase 12
## (auditoria desta tarefa: _build_hotspot() abaixo nunca chamou
## HotspotGlow.attach_to_region(), ao contrário de biblioteca_panel.gd/
## observatorio_panel.gd/etc., que já usam o mesmo componente desde a
## Fase 12/13). Mesmo padrão de biblioteca_panel.gd::_hotspot_glows.
var _hotspot_glows: Dictionary = {}


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	_build_static_structure()
	print("[AcademiaPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var academia_area := Control.new()
	academia_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	academia_area.clip_contents = true
	add_child(academia_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = ACADEMIA_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	academia_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ACADEMIA_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- 3 hotspots invisíveis, cada um sobre o elemento visual
	# correspondente já presente na arte (ver docstring do topo). ---
	_build_hotspot(texture_rect, "Hotspot_Producao", PRODUCAO_HOTSPOT_RECT, "Salão dos Artífices — Produção", PRODUCAO_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Aprimoramento", APRIMORAMENTO_HOTSPOT_RECT, "Salão dos Metamorfos — Aprimoramento", APRIMORAMENTO_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Evolucao", EVOLUCAO_HOTSPOT_RECT, "Evolução da Academia", EVOLUCAO_SCENE_PATH)

	# --- Chip de hover (mesmo padrão Cinzel já usado no Depósito/
	# Biblioteca/Observatório — só aparece ao passar o mouse sobre um
	# hotspot). ---
	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Voltar para a Cidade (mesmo chip/padrão do Depósito/
	# Biblioteca/Observatório). ---
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


func _build_hotspot(parent: Control, node_name: String, rect: Rect2, hover_text: String, scene_path: String) -> void:
	# FASE 15: sinal luminoso — mesma fábrica reutilizável já usada em
	# biblioteca_panel.gd/observatorio_panel.gd/etc. (hotspot_glow.gd),
	# mesma região fracionária já calibrada (rect), nenhuma coordenada
	# nova.
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
			print("[AcademiaPanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


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
