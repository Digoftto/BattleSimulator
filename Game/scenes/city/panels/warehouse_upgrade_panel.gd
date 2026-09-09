extends Control
## WarehouseUpgradePanel (DEPOSITS.md)
##
## Tela própria (nunca popup) — adaptada nesta etapa às caixas já
## desenhadas na arte (warehouse_upgrade.png, 1024x1536, mesmo template
## de moldura do Observatório/Crystal Vault/Kingdom Inventory: título +
## 4 caixas à esquerda + 4 à direita + 3 na base + 1 barra larga na
## base). Regiões calibradas por varredura de pixel (ver relatório da
## tarefa) — nenhum painel genérico translúcido cobrindo a arte
## (layout provisório da etapa anterior, removido).
##
## A barra larga azul (WIDE_BAR_ACTION), já desenhada como um botão
## grande, funciona como a área de AÇÃO principal: mostra "EVOLUIR
## DEPÓSITO" (1 hotspot) fora do modo de confirmação, ou "CANCELAR" +
## "CONFIRMAR" (2 hotspots, metade esquerda/direita da mesma barra)
## durante a confirmação — nunca uma segunda barra nova desenhada.
##
## Evolução do PRÓPRIO Depósito — paga EXCLUSIVAMENTE em Pontos de
## Geração (PG); nunca em Ferro Negro, Cristais Arcanos ou Essência
## Vital (DEPOSITS.md, "Filosofia dos Depósitos"). Reaproveita
## CityResolver.evolve_deposit() (engine/city/city_resolver.gd, já
## existente) pra executar a evolução em si — nenhuma segunda
## implementação da regra. Custo/capacidade vêm de
## Deposits.upgrade_cost_pg()/storage_capacity() (engine/city/deposits.gd)
## — nenhum valor duplicado do FORMULAS.md aqui. Teto da Capital
## verificado via Capital.can_building_evolve() — mesma função já
## usada por InstitutionalConstructionResolver/CityResolver, nunca
## reimplementada.
##
## Confirmação em 2 passos (pedido explícito): clicar em "EVOLUIR
## DEPÓSITO" não executa a evolução na hora — só alterna pra um estado
## de confirmação DENTRO da mesma tela (nunca popup/Window modal).
## Cancelar não altera nenhum estado do Reino.

const WAREHOUSE_UPGRADE_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/warehouse_upgrade.png")
const WAREHOUSE_UPGRADE_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.60, 0.60, 0.58)
const HUD_WARNING_COLOR: Color = Color(0.85, 0.55, 0.45)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Regiões calibradas por varredura de pixel sobre
## warehouse_upgrade.png (1024x1536).
const LEFT_1_NIVEL_ATUAL: Rect2 = Rect2(0.0371, 0.3379, 0.0820, 0.0371)
const LEFT_2_PROXIMO_NIVEL: Rect2 = Rect2(0.0371, 0.3939, 0.0830, 0.0371)
const LEFT_3_CAPACIDADE_ATUAL: Rect2 = Rect2(0.0361, 0.4492, 0.0840, 0.0378)
const LEFT_4_CAPACIDADE_APOS: Rect2 = Rect2(0.0371, 0.5059, 0.0840, 0.0384)
const RIGHT_1_CUSTO_PG: Rect2 = Rect2(0.8848, 0.3385, 0.0781, 0.0365)
const RIGHT_2_PG_DISPONIVEL: Rect2 = Rect2(0.8838, 0.3939, 0.0801, 0.0371)
const BOTTOM_2_STATUS: Rect2 = Rect2(0.3770, 0.6992, 0.2461, 0.0625)
const WIDE_BAR_ACTION: Rect2 = Rect2(0.2842, 0.7956, 0.4316, 0.0456)

var _pending_confirmation: bool = false
var _last_result_message: String = ""


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[WarehouseUpgradePanel] Pronto.")


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
	aspect.ratio = WAREHOUSE_UPGRADE_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = WAREHOUSE_UPGRADE_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = kingdom.deposito_level
	var next_level: int = current_level + 1
	var current_capacity: int = Deposits.storage_capacity(current_level)
	var next_capacity: int = Deposits.storage_capacity(next_level)
	var pg_cost: int = Deposits.upgrade_cost_pg(next_level)
	var pg_available: int = kingdom.generation_points
	var blocked: bool = not _can_upgrade_deposit(kingdom)

	_box_label(texture_rect, LEFT_1_NIVEL_ATUAL, "Nível Atual\n%d" % current_level, 12, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_2_PROXIMO_NIVEL, "Próximo Nível\n%d" % next_level, 12, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_3_CAPACIDADE_ATUAL, "Capacidade Atual\n%d" % current_capacity, 12, HUD_TEXT_COLOR)
	_box_label(texture_rect, LEFT_4_CAPACIDADE_APOS, "Capacidade Após\n%d" % next_capacity, 12, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_1_CUSTO_PG, "Custo em PG\n%d" % pg_cost, 12, HUD_TEXT_COLOR)
	_box_label(texture_rect, RIGHT_2_PG_DISPONIVEL, "PG Disponível\n%d" % pg_available, 12, HUD_TEXT_COLOR)

	_build_status_area(texture_rect, blocked, pg_cost, pg_available)
	_build_action_area(texture_rect, blocked, pg_cost, pg_available)

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


func _build_status_area(parent: Control, blocked: bool, pg_cost: int, pg_available: int) -> void:
	var text: String = ""
	var color: Color = HUD_TEXT_COLOR
	if _pending_confirmation:
		text = "Confirmar evolução do Depósito?\nPG necessários: %d | PG disponíveis: %d" % [pg_cost, pg_available]
	elif _last_result_message != "":
		text = _last_result_message
		color = HUD_MUTED_COLOR
	elif blocked:
		text = "Bloqueado: o Depósito não pode ultrapassar o nível da Capital."
		color = HUD_WARNING_COLOR

	if text != "":
		_box_label(parent, BOTTOM_2_STATUS, text, 10, color, true)


func _build_action_area(parent: Control, blocked: bool, pg_cost: int, pg_available: int) -> void:
	if _pending_confirmation:
		var half_width: float = WIDE_BAR_ACTION.size.x / 2.0
		var cancel_rect := Rect2(WIDE_BAR_ACTION.position.x, WIDE_BAR_ACTION.position.y, half_width, WIDE_BAR_ACTION.size.y)
		var confirm_rect := Rect2(WIDE_BAR_ACTION.position.x + half_width, WIDE_BAR_ACTION.position.y, half_width, WIDE_BAR_ACTION.size.y)

		var cancel_hotspot := _make_hotspot(cancel_rect)
		cancel_hotspot.gui_input.connect(_on_cancel_gui_input, CONNECT_DEFERRED)
		parent.add_child(cancel_hotspot)
		_box_label(parent, cancel_rect, "CANCELAR", 13, HUD_TEXT_COLOR, false)

		var confirm_hotspot := _make_hotspot(confirm_rect)
		confirm_hotspot.gui_input.connect(_on_confirm_gui_input, CONNECT_DEFERRED)
		parent.add_child(confirm_hotspot)
		_box_label(parent, confirm_rect, "CONFIRMAR", 13, HUD_TEXT_COLOR, false)
	else:
		var can_evolve: bool = not blocked and pg_available >= pg_cost
		var evolve_hotspot := _make_hotspot(WIDE_BAR_ACTION)
		if can_evolve:
			evolve_hotspot.gui_input.connect(_on_evolve_gui_input, CONNECT_DEFERRED)
		else:
			evolve_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(evolve_hotspot)
		_box_label(parent, WIDE_BAR_ACTION, "EVOLUIR DEPÓSITO", 14, HUD_TEXT_COLOR if can_evolve else HUD_MUTED_COLOR, false)


func _on_evolve_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_confirmation = true
		_last_result_message = ""
		refresh()


func _on_cancel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_confirmation = false
		refresh()


func _on_confirm_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var result: Dictionary = _upgrade_deposit()
		_pending_confirmation = false
		if result["success"]:
			_last_result_message = "Depósito evoluído com sucesso."
		else:
			# Mesmo padrão já usado por capital_panel.gd/city_panel.gd
			# ("Não foi possível evoluir: %s" % reason) — nunca uma
			# mensagem nova inventada pra este bloqueio.
			_last_result_message = "Não foi possível evoluir: %s" % result["reason"]
		refresh()


## --- Helpers (pedido explícito — separação entre apresentação e
## lógica econômica). ---

func _can_upgrade_deposit(kingdom: Kingdom) -> bool:
	return Capital.can_building_evolve(kingdom.deposito_level, kingdom.capital_level)


func _upgrade_deposit() -> Dictionary:
	return CityResolver.evolve_deposit(KingdomState.kingdom)


func _make_hotspot(rect: Rect2) -> Control:
	var hotspot := Control.new()
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
	return hotspot


func _box_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color, multiline: bool = false) -> void:
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
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if multiline else TextServer.AUTOWRAP_OFF
	label.clip_text = not multiline
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
