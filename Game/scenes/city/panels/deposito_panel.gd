extends Control
## DepositoPanel (DEPOSITS.md)
##
## HUB VISUAL do Depósito — mesmo princípio arquitetural já usado na
## Biblioteca/Observatório (biblioteca_panel.gd/observatorio_panel.gd):
## "A ARTE É A INTERFACE". warehouse.png preenche a tela inteira
## (AspectRatioContainer STRETCH_COVER); nenhuma barra, label ou painel
## permanente é desenhado por cima — só 4 hotspots INVISÍVEIS sobre
## elementos já presentes na própria arte.
##
## Correspondência visual dos 4 hotspots (inspeção direta de
## warehouse.png, 1672x941):
## - CRYSTAL VAULT: as estantes de cristais azuis brilhantes à direita
##   — correspondência direta com o nome/tema (Cristais Arcanos).
## - SUPPLY CHAIN: a área à esquerda com o guincho/talha suspensa por
##   correntes sobre pilhas de caixas — imagem de logística/movimentação
##   de carga, o elemento mais claramente ligado a "transferência".
## - KINGDOM INVENTORY: a mesa central com mapas/documentos/registros
##   abertos — uma mesa de balanço/inventário, não de movimentação.
## - WAREHOUSE UPGRADE: o pátio elevado ao fundo/centro-superior, com
##   os terrários de Essência Vital sobre um estrado — a estrutura mais
##   grandiosa/elevada da sala (mesmo raciocínio já usado no
##   Observatório: o elemento mais "central e grandioso" representa a
##   evolução do próprio sistema).
## Os 4 Rect2 foram calibrados por inspeção visual direta (crops
## dedicados, ver relatório da tarefa) com margem entre si — nenhuma
## sobreposição.
##
## Cada tela interna é reaproveitada no MESMO padrão de sempre (nunca
## popup, nunca cena modal) — troca de cena completa via
## change_scene_to_file, com botão "Voltar para o Depósito" em cada uma.

const WAREHOUSE_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/warehouse_v1.png")
const WAREHOUSE_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const CRYSTAL_VAULT_SCENE_PATH: String = "res://scenes/city/panels/warehouse_crystal_vault_panel.tscn"
const KINGDOM_INVENTORY_SCENE_PATH: String = "res://scenes/city/panels/warehouse_kingdom_inventory_panel.tscn"
const SUPPLY_CHAIN_SCENE_PATH: String = "res://scenes/city/panels/warehouse_supply_chain_panel.tscn"
const WAREHOUSE_UPGRADE_SCENE_PATH: String = "res://scenes/city/panels/warehouse_upgrade_panel.tscn"

## Estantes de cristais azuis, lado direito.
const CRYSTAL_VAULT_HOTSPOT_RECT: Rect2 = Rect2(0.65, 0.16, 0.32, 0.46)
## Guincho/talha sobre pilhas de caixas, lado esquerdo.
const SUPPLY_CHAIN_HOTSPOT_RECT: Rect2 = Rect2(0.02, 0.16, 0.32, 0.46)
## Mesa central de mapas/registros.
const KINGDOM_INVENTORY_HOTSPOT_RECT: Rect2 = Rect2(0.38, 0.35, 0.24, 0.27)
## Pátio elevado com terrários, fundo/centro-superior.
const WAREHOUSE_UPGRADE_HOTSPOT_RECT: Rect2 = Rect2(0.37, 0.02, 0.26, 0.27)

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
	print("[DepositoPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var warehouse_area := Control.new()
	warehouse_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	warehouse_area.clip_contents = true
	add_child(warehouse_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = WAREHOUSE_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	warehouse_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = WAREHOUSE_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- 4 hotspots invisíveis, cada um sobre o elemento visual
	# correspondente já presente na arte (ver docstring do topo). ---
	_build_hotspot(texture_rect, "Hotspot_CrystalVault", CRYSTAL_VAULT_HOTSPOT_RECT, "Crystal Vault", CRYSTAL_VAULT_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_KingdomInventory", KINGDOM_INVENTORY_HOTSPOT_RECT, "Kingdom Inventory", KINGDOM_INVENTORY_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_SupplyChain", SUPPLY_CHAIN_HOTSPOT_RECT, "Supply Chain", SUPPLY_CHAIN_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_WarehouseUpgrade", WAREHOUSE_UPGRADE_HOTSPOT_RECT, "Warehouse Upgrade", WAREHOUSE_UPGRADE_SCENE_PATH)

	# --- Chip de hover (mesmo padrão Cinzel já usado na Biblioteca/
	# Observatório — só aparece ao passar o mouse sobre um hotspot). ---
	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Voltar para a Cidade (mesmo chip/padrão da Biblioteca/
	# Observatório). ---
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
			print("[DepositoPanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


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
