extends Control
## WarehouseCrystalVaultPanel (DEPOSITS.md)
##
## Tela própria (nunca popup) — adaptada nesta etapa às caixas já
## desenhadas na arte (warehouse_crystal_vault.png, 1024x1536, mesmo
## template de moldura do Observatório: título + 4 caixas à esquerda +
## 4 à direita + 3 na base + 1 barra larga na base). Regiões calibradas
## por varredura de pixel (cor das caixas escuras, ver relatório da
## tarefa) — nenhum painel genérico translúcido cobrindo a arte
## (layout provisório da etapa anterior, removido).
##
## Mostra o estado ATUAL do armazenamento: Nível do Depósito,
## Capacidade por Recurso (compartilhada pelos 3 — DEPOSITS.md: "os
## três compartilham mesmo nível, mesma capacidade, mesma progressão")
## e, pra cada um dos 3 Recursos, quantidade/capacidade + percentual de
## ocupação. Usa exatamente 8 das 12 caixas da moldura — a Capacidade é
## a MESMA pros 3 Recursos, então só é mostrada uma vez (repeti-la 3x
## seria ruído, não informação nova); as 3 caixas da base e a barra
## larga ficam vazias/reservadas nesta etapa (pedido explícito: "Se
## determinados espaços da arte não possuem atualmente uma função
## dinâmica correspondente, deixá-los vazios. NÃO inventar funções
## apenas para preencher espaço.").
##
## Somente leitura — nenhuma transferência acontece aqui (essa lógica
## vive só em warehouse_supply_chain_panel.gd/SupplyChainResolver,
## nunca duplicada). Fonte de dados: Kingdom.raw_resources/
## Kingdom.deposito_level + Deposits.storage_capacity() — nenhum valor
## duplicado ou recalculado aqui.

const CRYSTAL_VAULT_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/warehouse_crystal_vault.png")
const CRYSTAL_VAULT_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Regiões calibradas por varredura de pixel (caixas escuras teal-verde
## desta arte especificamente — cor diferente da azul-marinho do
## Observatório, ver relatório da tarefa) sobre
## warehouse_crystal_vault.png (1024x1536).
const LEFT_1_NIVEL: Rect2 = Rect2(0.0332, 0.3424, 0.0879, 0.0397)
const LEFT_2_CAPACIDADE: Rect2 = Rect2(0.0342, 0.4010, 0.0869, 0.0384)
const LEFT_3_FERRO_QTD: Rect2 = Rect2(0.0332, 0.4577, 0.0879, 0.0384)
const LEFT_4_FERRO_PCT: Rect2 = Rect2(0.0342, 0.5143, 0.0869, 0.0384)
const RIGHT_1_CRISTAIS_QTD: Rect2 = Rect2(0.8789, 0.3424, 0.0869, 0.0397)
const RIGHT_2_CRISTAIS_PCT: Rect2 = Rect2(0.8799, 0.4010, 0.0859, 0.0378)
const RIGHT_3_ESSENCIA_QTD: Rect2 = Rect2(0.8809, 0.4577, 0.0840, 0.0378)
const RIGHT_4_ESSENCIA_PCT: Rect2 = Rect2(0.8799, 0.5143, 0.0850, 0.0384)

## Reservadas pra uma etapa futura — nenhum Control criado a partir
## delas nesta tarefa (nenhum dado adicional disponível pra preenchê-las
## sem inventar conteúdo).
const BOTTOM_BOX_1: Rect2 = Rect2(0.1152, 0.7148, 0.1914, 0.0612)
const BOTTOM_BOX_2: Rect2 = Rect2(0.3770, 0.7148, 0.2461, 0.0612)
const BOTTOM_BOX_3: Rect2 = Rect2(0.6943, 0.7148, 0.1895, 0.0612)
const WIDE_BAR: Rect2 = Rect2(0.2813, 0.8105, 0.4385, 0.0482)


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[WarehouseCrystalVaultPanel] Pronto.")


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
	aspect.ratio = CRYSTAL_VAULT_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = CRYSTAL_VAULT_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	var level: int = kingdom.deposito_level
	var capacity: int = Deposits.storage_capacity(level)

	_box_label(texture_rect, LEFT_1_NIVEL, "Nível do Depósito\n%d" % level, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_2_CAPACIDADE, "Capacidade por Recurso\n%d" % capacity, 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_3_FERRO_QTD, "Ferro Negro\n%d / %d" % [kingdom.get_raw_resource("ferro_negro"), capacity], 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_4_FERRO_PCT, "Ferro Negro\n%.1f%% ocupado" % _percent(kingdom.get_raw_resource("ferro_negro"), capacity), 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_1_CRISTAIS_QTD, "Cristais Arcanos\n%d / %d" % [kingdom.get_raw_resource("cristais_arcanos"), capacity], 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_2_CRISTAIS_PCT, "Cristais Arcanos\n%.1f%% ocupado" % _percent(kingdom.get_raw_resource("cristais_arcanos"), capacity), 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_3_ESSENCIA_QTD, "Essência Vital\n%d / %d" % [kingdom.get_raw_resource("essencia_vital"), capacity], 11, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_4_ESSENCIA_PCT, "Essência Vital\n%.1f%% ocupado" % _percent(kingdom.get_raw_resource("essencia_vital"), capacity), 11, HUD_TEXT_COLOR)

	# --- Voltar para o Depósito — esta arte (ao contrário da nova
	# Supply Chain) não desenha nenhum elemento de navegação próprio;
	# mesmo chip Cinzel já usado em Biblioteca/Observatório/Bestiário
	# pra esse caso (nunca autowrap ligado — ver correção da etapa
	# anterior). ---
	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para o Depósito"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_gui_input, CONNECT_DEFERRED)
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
	label.add_theme_constant_override("outline_size", 4)
	chip.add_child(label)

	return {"container": chip, "label": label}


func _percent(amount: int, capacity: int) -> float:
	return (float(amount) / float(capacity) * 100.0) if capacity > 0 else 0.0


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


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/panels/deposito_panel.tscn")
