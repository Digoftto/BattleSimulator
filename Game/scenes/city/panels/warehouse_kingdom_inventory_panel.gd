extends Control
## WarehouseKingdomInventoryPanel (DEPOSITS.md)
##
## Tela própria (nunca popup) — adaptada nesta etapa às caixas já
## desenhadas na arte (warehouse_kingdom_inventory.png, 1024x1536,
## mesmo template de moldura do Observatório/Crystal Vault: título + 4
## caixas à esquerda + 4 à direita + 3 na base + 1 barra larga na
## base). Regiões calibradas por varredura de pixel (ver relatório da
## tarefa) — nenhum painel genérico translúcido cobrindo a arte
## (layout provisório da etapa anterior, removido).
##
## Visão CONSOLIDADA dos Recursos de Construção: pra cada um dos 3
## Recursos, separa claramente o que está no Depósito
## (Kingdom.raw_resources) do que já foi reservado antecipadamente nas
## construções (Kingdom.building_reserved_resources — Reserva
## Antecipada de Evolução, DEPOSITS.md) e o total. Usa 3 das 4 colunas
## de caixas laterais (esquerda=Ferro Negro, direita=Cristais Arcanos)
## + as 3 caixas da base (Essência Vital) — 9 valores reais, um por
## caixa, mais o Total Geral do Reino na barra larga. A 4ª caixa de
## cada coluna lateral fica vazia/reservada (só 3 valores por Recurso:
## Depósito/Reservado/Total).
##
## Somente informativa (pedido explícito: "NÃO criar uma mecânica nova
## de transferência nesta tela... Não duplicar a lógica da Supply
## Chain") — nenhum botão de transferência aqui, só leitura.
##
## Fonte de dados: Kingdom.raw_resources / Kingdom.building_reserved_resources
## (via InstitutionalConstructionResolver.building_key() pros nomes das
## 4 construções elegíveis) — nenhum dado novo, nenhuma soma
## recalculada em outro lugar.

const KINGDOM_INVENTORY_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/warehouse_kingdom_inventory.png")
const KINGDOM_INVENTORY_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const ELIGIBLE_BUILDINGS: Array[InstitutionalConstructionConfig.Building] = [
	InstitutionalConstructionConfig.Building.CAPITAL,
	InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO,
	InstitutionalConstructionConfig.Building.ACADEMIA,
	InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA,
]

## Regiões calibradas por varredura de pixel sobre
## warehouse_kingdom_inventory.png (1024x1536).
const LEFT_1_FERRO_DEPOSITO: Rect2 = Rect2(0.0332, 0.3372, 0.0889, 0.0391)
const LEFT_2_FERRO_RESERVADO: Rect2 = Rect2(0.0332, 0.3945, 0.0889, 0.0397)
const LEFT_3_FERRO_TOTAL: Rect2 = Rect2(0.0332, 0.4512, 0.0879, 0.0391)
const RIGHT_1_CRISTAIS_DEPOSITO: Rect2 = Rect2(0.8779, 0.3372, 0.0898, 0.0391)
const RIGHT_2_CRISTAIS_RESERVADO: Rect2 = Rect2(0.8789, 0.3945, 0.0879, 0.0397)
const RIGHT_3_CRISTAIS_TOTAL: Rect2 = Rect2(0.8799, 0.4518, 0.0869, 0.0378)
const BOTTOM_1_ESSENCIA_DEPOSITO: Rect2 = Rect2(0.1143, 0.6992, 0.1924, 0.0658)
const BOTTOM_2_ESSENCIA_RESERVADO: Rect2 = Rect2(0.3750, 0.6992, 0.2500, 0.0658)
const BOTTOM_3_ESSENCIA_TOTAL: Rect2 = Rect2(0.6934, 0.6992, 0.1924, 0.0658)
const WIDE_BAR_TOTAL_GERAL: Rect2 = Rect2(0.2803, 0.7988, 0.4395, 0.0430)


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[WarehouseKingdomInventoryPanel] Pronto.")


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
	aspect.ratio = KINGDOM_INVENTORY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = KINGDOM_INVENTORY_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	var ferro_deposito: int = kingdom.get_raw_resource("ferro_negro")
	var ferro_reservado: int = _total_reserved(kingdom, "ferro_negro")
	var cristais_deposito: int = kingdom.get_raw_resource("cristais_arcanos")
	var cristais_reservado: int = _total_reserved(kingdom, "cristais_arcanos")
	var essencia_deposito: int = kingdom.get_raw_resource("essencia_vital")
	var essencia_reservado: int = _total_reserved(kingdom, "essencia_vital")

	_box_label(texture_rect, LEFT_1_FERRO_DEPOSITO, "Ferro Negro\nNo Depósito: %d" % ferro_deposito, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_2_FERRO_RESERVADO, "Ferro Negro\nReservado: %d" % ferro_reservado, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_3_FERRO_TOTAL, "Ferro Negro\nTotal: %d" % (ferro_deposito + ferro_reservado), 11, HUD_TEXT_COLOR)

	_box_label(texture_rect, RIGHT_1_CRISTAIS_DEPOSITO, "Cristais Arcanos\nNo Depósito: %d" % cristais_deposito, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_2_CRISTAIS_RESERVADO, "Cristais Arcanos\nReservado: %d" % cristais_reservado, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_3_CRISTAIS_TOTAL, "Cristais Arcanos\nTotal: %d" % (cristais_deposito + cristais_reservado), 11, HUD_TEXT_COLOR)

	_box_label(texture_rect, BOTTOM_1_ESSENCIA_DEPOSITO, "Essência Vital\nNo Depósito: %d" % essencia_deposito, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, BOTTOM_2_ESSENCIA_RESERVADO, "Essência Vital\nReservado: %d" % essencia_reservado, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, BOTTOM_3_ESSENCIA_TOTAL, "Essência Vital\nTotal: %d" % (essencia_deposito + essencia_reservado), 11, HUD_TEXT_COLOR)

	var grand_total: int = ferro_deposito + ferro_reservado + cristais_deposito + cristais_reservado + essencia_deposito + essencia_reservado
	_box_label(texture_rect, WIDE_BAR_TOTAL_GERAL, "Total Geral do Reino (3 Recursos): %d" % grand_total, 13, HUD_TEXT_COLOR)

	# --- Voltar para o Depósito — esta arte não desenha nenhum
	# elemento de navegação próprio; mesmo chip Cinzel já usado em
	# Biblioteca/Observatório/Bestiário (autowrap sempre OFF). ---
	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para o Depósito"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_chip_gui_input, CONNECT_DEFERRED)
	add_child(back_container)


func _total_reserved(kingdom: Kingdom, resource: String) -> int:
	var total: int = 0
	for building: InstitutionalConstructionConfig.Building in ELIGIBLE_BUILDINGS:
		var key: String = InstitutionalConstructionResolver.building_key(building)
		total += kingdom.get_building_reserved(key, resource)
	return total


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
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	label.add_theme_constant_override("outline_size", 4)
	chip.add_child(label)

	return {"container": chip, "label": label}


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/panels/deposito_panel.tscn")
