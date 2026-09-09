extends Control
## AcademiaAprimoramentoPanel (ACADEMY.md, "Salão dos Metamorfos")
##
## Tela própria (nunca popup) — usa EXCLUSIVAMENTE academia_metamorfo.png
## (arte-template FINAL, 1024x1536, desenhada depois da auditoria:
## painéis em branco dedicados — "Carta Selecionada", "Resultado do
## Aprimoramento", "Metamorfos", "Consumo → Resultado", "Fila de
## Tarefas" — sem molduras internas pré-desenhadas, e um bloco "Fila do
## Metamorfo Selecionado" + "Melhorar Fila" já fisicamente ligado à
## lista de Metamorfos). Todas as regiões abaixo foram calibradas por
## detecção de cor (borda dourada característica das caixas da arte) —
## ver relatório da tarefa.
##
## NENHUMA regra de Aprimoramento foi reescrita: continua usando
## exclusivamente AcademyResolver.request_upgrade()/
## upgrade_queue_capacity()/cancel_task() — 3 cópias Livres do mesmo
## nome/Tier -> 1 cópia do Tier seguinte (ACADEMY.md), sem alteração.
##
## Diferenças desta versão em relação à anterior (arte antiga):
## - Painel "Carta Selecionada" não tem mais um OptionButton solto num
##   canto vazio — a arte reserva o painel inteiro para essa função; o
##   dropdown de seleção fica no topo do próprio painel, com Nome/Tier
##   Atual/Cópias Livres abaixo, tudo dentro do mesmo espaço dedicado.
## - "Capacidade da Fila" fica dentro do bloco "Fila do Metamorfo
##   Selecionado", fisicamente ligado à lista de Metamorfos — deixa
##   explícito que o valor é do Metamorfo atualmente selecionado
##   (_selected_master_index), não um valor solto sem dono.
## - Fila de Tarefas não tem coluna "Metamorfo" (não existe retrato por
##   Mestre na fila — era decorativo sem dado real na arte antiga,
##   removido na nova).
## - "Necessário: 3" e os 3 slots abaixo permanecem 100% decorativos —
##   não há asset de portrait de carta no sistema (CardResource não tem
##   campo de textura), então nada dinâmico é escrito ali.

const ACADEMIA_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/academia_metamorfo.png")
const ACADEMIA_IMAGE_ASPECT_RATIO: float = 1024.0 / 1536.0
const ACADEMIA_HUB_SCENE: String = "res://scenes/city/panels/academia_panel.tscn"

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)

## --- Regiões calibradas por detecção de cor (borda dourada) sobre
## academia_metamorfo.png (1024x1536) — ver relatório da tarefa. ---
const CLOSE_BUTTON: Rect2 = Rect2(0.850, 0.050, 0.149, 0.070)

## Painel em branco — dropdown de seleção + Nome/Tier Atual/Cópias
## Livres, tudo construído aqui dentro (sem elemento fixo por baixo).
const CARTA_SELECIONADA_REGION: Rect2 = Rect2(0.018, 0.229, 0.324, 0.171)
const CARTA_SELECT_OPTION: Rect2 = Rect2(0.032, 0.238, 0.296, 0.038)
const CARTA_NOME_BOX: Rect2 = Rect2(0.032, 0.288, 0.296, 0.030)
const CARTA_TIER_ATUAL_BOX: Rect2 = Rect2(0.032, 0.325, 0.296, 0.030)
const CARTA_COPIAS_LIVRES_BOX: Rect2 = Rect2(0.032, 0.362, 0.296, 0.030)

## Painel em branco — "Carta Atual/Resultante" + Tier→Tier, sem
## molduras internas pré-desenhadas.
const RESULTADO_REGION: Rect2 = Rect2(0.352, 0.229, 0.327, 0.211)

## Painel em branco — Consumo → Resultado.
const CONSUMO_REGION: Rect2 = Rect2(0.352, 0.474, 0.327, 0.091)

## Painel em branco — lista rolável real de Metamorfos.
const METAMORFOS_REGION: Rect2 = Rect2(0.680, 0.229, 0.301, 0.240)

## "Fila do Metamorfo Selecionado" — capacidade do Mestre selecionado
## (texto colocado no espaço vazio à esquerda do botão, já que a arte
## não desenha uma caixa "X/Y" própria) + botão Melhorar Fila (a arte
## já desenha o botão inteiro, só o hotspot é transparente por cima).
const CAPACIDADE_FILA_BOX: Rect2 = Rect2(0.680, 0.505, 0.100, 0.034)
const MELHORAR_FILA_BUTTON: Rect2 = Rect2(0.7920, 0.5046, 0.1875, 0.0345)

## Painel em branco — cabeçalho de colunas já fixo na arte
## (# | Carta | Tier Atual | → | Tier Resultante |
## Progresso/Tempo Restante | Ações); corpo 100% dinâmico.
const FILA_REGION: Rect2 = Rect2(0.005, 0.599, 0.989, 0.251)
const FILA_COL_CARTA_X: Rect2 = Rect2(0.130, 0.0, 0.169, 0.0)
const FILA_COL_TIER_ATUAL_X: Rect2 = Rect2(0.300, 0.0, 0.119, 0.0)
const FILA_COL_ARROW_X: Rect2 = Rect2(0.420, 0.0, 0.049, 0.0)
const FILA_COL_TIER_RESULT_X: Rect2 = Rect2(0.470, 0.0, 0.148, 0.0)
const FILA_COL_PROGRESSO_X: Rect2 = Rect2(0.619, 0.0, 0.199, 0.0)
const FILA_COL_ACOES_X: Rect2 = Rect2(0.850, 0.0, 0.098, 0.0)

const APRIMORAR_BUTTON: Rect2 = Rect2(0.1494, 0.8496, 0.6992, 0.0547)

var _action_status_text: String = ""

var _selected_upgrade_card_name: String = ""
var _selected_upgrade_tier: int = 1
var _selected_master_index: int = 0

## keys[i] = [card_name, tier], na mesma ordem do OptionButton.
var _owned_group_keys: Array = []


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[AcademiaAprimoramentoPanel] Pronto. Nível: %d | Metamorfos: %d" % [
		KingdomState.kingdom.academy_level, KingdomState.kingdom.academy_metamorfos.size()
	])


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.sync_academy_masters()
	GameRuntime.sync(kingdom, GameClock.now_unix())

	if _selected_master_index >= kingdom.academy_metamorfos.size():
		_selected_master_index = 0

	_clear_children(self)
	_build_structure(kingdom)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _build_structure(kingdom: Kingdom) -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = ACADEMIA_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ACADEMIA_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_close_button(texture_rect)
	_build_carta_selecionada(texture_rect)
	_build_resultado(texture_rect)
	_build_consumo_resultado(texture_rect)
	_build_metamorfos(texture_rect, kingdom)
	_build_fila(texture_rect, kingdom)
	_build_aprimorar_button(texture_rect)

	if _action_status_text != "":
		var status_label := Label.new()
		status_label.text = _action_status_text
		_anchor_control(status_label, Rect2(0.018, 0.858, 0.964, 0.020))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		status_label.clip_text = true
		status_label.add_theme_font_override("font", HUD_FONT)
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", HUD_ERROR_COLOR)
		status_label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
		status_label.add_theme_constant_override("outline_size", 2)
		texture_rect.add_child(status_label)


## Agrupa as cartas Livres do Reino por (nome, Tier) — só entradas com
## 3+ cópias aparecem, nunca Tier 5. Idêntico ao critério anterior.
func _group_owned_cards_by_name_and_tier() -> Dictionary:
	var counts: Dictionary = {}
	for card: CardResource in KingdomState.kingdom.cards:
		if card.ownership_status != CardResource.OwnershipStatus.LIVRE or card.tier >= 5:
			continue
		var key: Array = [card.card_name, card.tier]
		counts[key] = counts.get(key, 0) + 1

	var result: Dictionary = {}
	for key: Array in counts:
		if counts[key] >= 3:
			result[key] = counts[key]
	return result


func _build_carta_selecionada(parent: Control) -> void:
	var owned_groups: Dictionary = _group_owned_cards_by_name_and_tier()
	_owned_group_keys = owned_groups.keys()

	var option := OptionButton.new()
	_anchor_control(option, CARTA_SELECT_OPTION)
	for i in range(_owned_group_keys.size()):
		var key: Array = _owned_group_keys[i]
		option.add_item("%s (Tier %d) — %d Livre(s)" % [key[0], key[1], owned_groups[key]], i)

	if _selected_upgrade_card_name == "" or not _owned_group_keys.has([_selected_upgrade_card_name, _selected_upgrade_tier]):
		if not _owned_group_keys.is_empty():
			_selected_upgrade_card_name = _owned_group_keys[0][0]
			_selected_upgrade_tier = _owned_group_keys[0][1]
		else:
			_selected_upgrade_card_name = ""

	var current_index: int = _owned_group_keys.find([_selected_upgrade_card_name, _selected_upgrade_tier])
	if current_index >= 0:
		option.selected = current_index
	option.item_selected.connect(_on_upgrade_card_selected, CONNECT_DEFERRED)
	parent.add_child(option)

	if _selected_upgrade_card_name == "":
		_value_label(parent, CARTA_NOME_BOX, "Nenhuma carta com 3+ cópias Livres", 11, HUD_MUTED_COLOR)
		return

	var copies: int = owned_groups.get([_selected_upgrade_card_name, _selected_upgrade_tier], 0)
	_value_label(parent, CARTA_NOME_BOX, "Nome: %s" % _selected_upgrade_card_name, 12, HUD_TEXT_COLOR)
	_value_label(parent, CARTA_TIER_ATUAL_BOX, "Tier Atual: %d" % _selected_upgrade_tier, 12, HUD_TEXT_COLOR)
	_value_label(parent, CARTA_COPIAS_LIVRES_BOX, "Cópias Livres: %d" % copies, 12, HUD_TEXT_COLOR)


func _on_upgrade_card_selected(index: int) -> void:
	var key: Array = _owned_group_keys[index]
	_selected_upgrade_card_name = key[0]
	_selected_upgrade_tier = key[1]
	refresh()


func _build_resultado(parent: Control) -> void:
	if _selected_upgrade_card_name == "":
		return
	var region := Control.new()
	_anchor_control(region, RESULTADO_REGION)
	parent.add_child(region)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	region.add_child(vbox)

	var current_label := Label.new()
	current_label.text = "Carta Atual: %s (Tier %d)" % [_selected_upgrade_card_name, _selected_upgrade_tier]
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain_label(current_label, 13, HUD_TEXT_COLOR)
	vbox.add_child(current_label)

	var arrow_label := Label.new()
	arrow_label.text = "▼"
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain_label(arrow_label, 16, HUD_ACCENT_SELECTED)
	vbox.add_child(arrow_label)

	var next_label := Label.new()
	next_label.text = "Carta Resultante: %s (Tier %d)" % [_selected_upgrade_card_name, _selected_upgrade_tier + 1]
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain_label(next_label, 13, HUD_ACCENT_SELECTED)
	vbox.add_child(next_label)


func _build_consumo_resultado(parent: Control) -> void:
	if _selected_upgrade_card_name == "":
		return
	var region := Control.new()
	_anchor_control(region, CONSUMO_REGION)
	parent.add_child(region)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	region.add_child(vbox)

	var consumo_label := Label.new()
	consumo_label.text = "Consumo: 3x %s" % _selected_upgrade_card_name
	consumo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain_label(consumo_label, 12, HUD_TEXT_COLOR)
	vbox.add_child(consumo_label)

	var resultado_label := Label.new()
	resultado_label.text = "Resultado: 1x %s" % _selected_upgrade_card_name
	resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain_label(resultado_label, 12, HUD_ACCENT_SELECTED)
	vbox.add_child(resultado_label)


## Painel "METAMORFOS" também é moldura vazia — lista rolável real
## construída inteira aqui dentro. Cada linha é clicável (seleciona o
## Metamorfo cuja Fila aparece no bloco "Fila do Metamorfo Selecionado").
func _build_metamorfos(parent: Control, kingdom: Kingdom) -> void:
	var region := Control.new()
	_anchor_control(region, METAMORFOS_REGION)
	parent.add_child(region)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	region.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var masters: Array[AcademyMaster] = kingdom.academy_metamorfos

	for i in range(masters.size()):
		var master: AcademyMaster = masters[i]
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 30)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.gui_input.connect(_on_master_row_gui_input.bind(i))

		var style := StyleBoxFlat.new()
		var selected: bool = i == _selected_master_index
		style.bg_color = Color(0.95, 0.80, 0.35, 0.18) if selected else Color(1, 1, 1, 0.04)
		style.border_width_left = 1
		style.border_width_bottom = 1
		style.border_color = HUD_ACCENT_SELECTED if selected else Color(1, 1, 1, 0.10)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		style.content_margin_left = 8.0
		row.add_theme_stylebox_override("panel", style)

		var task: AcademyTask = master.current_task()
		var status_text: String
		if task == null:
			status_text = "Metamorfo %d — Ocioso" % (i + 1)
		elif not task.has_started():
			status_text = "Metamorfo %d — Na fila" % (i + 1)
		else:
			var remaining: int = maxi(0, task.end_unix - GameClock.now_unix())
			status_text = "Metamorfo %d — %s (~%ds)" % [i + 1, task.target_card_name, remaining]

		var label := Label.new()
		label.text = status_text
		label.add_theme_font_override("font", HUD_FONT)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
		label.clip_text = true
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

		list.add_child(row)

	if masters.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum Metamorfo disponível."
		empty_label.add_theme_color_override("font_color", HUD_MUTED_COLOR)
		list.add_child(empty_label)
		return

	var selected_master: AcademyMaster = masters[_selected_master_index]
	_value_label(parent, CAPACIDADE_FILA_BOX, "%d/%d" % [selected_master.queue.size(), selected_master.queue_capacity], 13, HUD_TEXT_COLOR)

	var upgrade_hotspot := _make_hotspot(MELHORAR_FILA_BUTTON)
	upgrade_hotspot.gui_input.connect(_on_upgrade_master_queue_gui_input.bind(selected_master))
	parent.add_child(upgrade_hotspot)


func _on_master_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_master_index = index
		refresh()


func _on_upgrade_master_queue_gui_input(event: InputEvent, master: AcademyMaster) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var result: Dictionary = AcademyResolver.upgrade_queue_capacity(KingdomState.kingdom, master)
	if not result["success"]:
		print("[AcademiaAprimoramentoPanel] Melhorar Fila falhou: %s" % result["reason"])
		_action_status_text = "Não foi possível melhorar a Fila: %s" % result["reason"]
	else:
		_action_status_text = ""
	refresh()


## Painel "FILA DE TAREFAS" — cabeçalho de colunas já fixo na arte
## (inclusive a seta "→"); corpo 100% dinâmico, cada linha ancorada
## pelas mesmas frações X do cabeçalho.
func _build_fila(parent: Control, kingdom: Kingdom) -> void:
	var region := Control.new()
	_anchor_control(region, FILA_REGION)
	parent.add_child(region)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	region.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for master: AcademyMaster in kingdom.academy_metamorfos:
		for task: AcademyTask in master.queue:
			var row := Control.new()
			row.custom_minimum_size = Vector2(0, 24)
			list.add_child(row)

			_row_label(row, FILA_COL_CARTA_X, task.target_card_name, 11, HUD_TEXT_COLOR)
			_row_label(row, FILA_COL_TIER_ATUAL_X, str(task.target_tier - 1), 11, HUD_TEXT_COLOR)
			_row_label(row, FILA_COL_ARROW_X, "→", 11, HUD_MUTED_COLOR)
			_row_label(row, FILA_COL_TIER_RESULT_X, str(task.target_tier), 11, HUD_ACCENT_SELECTED)

			var progress_text: String = "na fila"
			if task.has_started():
				progress_text = "~%ds" % maxi(0, task.end_unix - GameClock.now_unix())
			_row_label(row, FILA_COL_PROGRESSO_X, progress_text, 10, HUD_TEXT_COLOR)

			var cancel_hotspot := Control.new()
			cancel_hotspot.anchor_left = FILA_COL_ACOES_X.position.x
			cancel_hotspot.anchor_right = FILA_COL_ACOES_X.position.x + FILA_COL_ACOES_X.size.x
			cancel_hotspot.anchor_top = 0.0
			cancel_hotspot.anchor_bottom = 1.0
			cancel_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if not task.has_started() else Control.MOUSE_FILTER_IGNORE
			cancel_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			cancel_hotspot.gui_input.connect(_on_cancel_task_gui_input.bind(master, task))
			row.add_child(cancel_hotspot)

			var cancel_label := Label.new()
			cancel_label.text = "X" if not task.has_started() else "—"
			cancel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cancel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cancel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cancel_label.anchor_left = FILA_COL_ACOES_X.position.x
			cancel_label.anchor_right = FILA_COL_ACOES_X.position.x + FILA_COL_ACOES_X.size.x
			cancel_label.anchor_top = 0.0
			cancel_label.anchor_bottom = 1.0
			cancel_label.add_theme_font_override("font", HUD_FONT)
			cancel_label.add_theme_font_size_override("font_size", 11)
			cancel_label.add_theme_color_override("font_color", HUD_ERROR_COLOR if not task.has_started() else HUD_MUTED_COLOR)
			row.add_child(cancel_label)

	if list.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma tarefa na fila."
		empty_label.add_theme_color_override("font_color", HUD_MUTED_COLOR)
		list.add_child(empty_label)


func _on_cancel_task_gui_input(event: InputEvent, master: AcademyMaster, task: AcademyTask) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AcademyResolver.cancel_task(KingdomState.kingdom, master, task)
		refresh()


func _build_aprimorar_button(parent: Control) -> void:
	var hotspot := _make_hotspot(APRIMORAR_BUTTON)
	hotspot.gui_input.connect(_on_upgrade_gui_input)
	parent.add_child(hotspot)


func _on_upgrade_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _selected_upgrade_card_name == "":
		return
	var result: Dictionary = AcademyResolver.request_upgrade(
		KingdomState.kingdom, _selected_upgrade_card_name, _selected_upgrade_tier, 1, GameClock.now_unix()
	)
	if not result["success"]:
		print("[AcademiaAprimoramentoPanel] Aprimorar falhou: %s" % result["reason"])
		_action_status_text = "Não foi possível aprimorar: %s" % result["reason"]
	else:
		_action_status_text = ""
	refresh()


func _build_close_button(parent: Control) -> void:
	var hotspot := _make_hotspot(CLOSE_BUTTON)
	hotspot.gui_input.connect(_on_back_gui_input)
	parent.add_child(hotspot)


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(ACADEMIA_HUB_SCENE)


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _make_hotspot(rect: Rect2) -> Control:
	var hotspot := Control.new()
	_anchor_control(hotspot, rect)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return hotspot


func _anchor_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _style_plain_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)


## Rótulo ancorado por fração X relativa à LINHA (Control simples, não
## à textura inteira) — usado pelas linhas da Fila de Tarefas.
func _row_label(row: Control, x_rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.anchor_left = x_rect.position.x
	label.anchor_right = x_rect.position.x + x_rect.size.x
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_plain_label(label, font_size, color)
	row.add_child(label)


func _value_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	_anchor_control(label, rect)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_plain_label(label, font_size, color)
	parent.add_child(label)
