extends Control
## AcademiaPanel (ACADEMY.md)
##
## Produzir uma Carta (Comum direto por Fragmento, ou Rara+ via cadeia
## automática de receita — os dois pelo mesmo botão, AcademyResolver
## decide sozinho qual caminho usar), Aprimorar manualmente (merge de
## 3 cópias Livres do mesmo Tier), Mestres (fila, tarefa atual, tempo
## restante, melhorar capacidade em PG), e a Fila de Tarefas completa
## com cancelamento. Mesmo padrão das demais janelas: árvore em
## código, sem estado próprio, reconstruída a cada ação.

var _root_vbox: VBoxContainer
var _resumo_label: Label
var _mestres_container: VBoxContainer
var _fila_container: VBoxContainer
var _preview_label: Label

var _selected_produce_card: CardResource = null
var _produce_quantity: int = 1
var _preserve_inventory: bool = false

## Filtros de produção — reduzem a lista de Cartas do dropdown "Carta:"
## conforme o jogador escolhe. "(todas)" desliga o filtro específico.
var _produce_filter_faction: String = "(todas)"
var _produce_filter_class: String = "(todas)"
var _produce_filter_rarity: String = "(todas)"

## Lista filtrada atual — o índice do OptionButton indexa AQUI, nunca
## direto em GameDatabase.cards, já que os filtros mudam o conjunto.
var _filtered_produce_cards: Array[CardResource] = []
var _produce_card_option: OptionButton = null

var _selected_upgrade_card_name: String = ""
var _selected_upgrade_tier: int = 1


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	refresh()
	print("[AcademiaPanel] Pronto. Nível: %d | Artífices: %d | Metamorfos: %d" % [
		KingdomState.kingdom.academy_level, KingdomState.kingdom.academy_artifices.size(), KingdomState.kingdom.academy_metamorfos.size()
	])


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(750, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Academia"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	_add_section_title("Resumo")
	_resumo_label = Label.new()
	_root_vbox.add_child(_resumo_label)

	_add_section_title("Mestres")
	_mestres_container = VBoxContainer.new()
	_mestres_container.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(_mestres_container)

	_add_section_title("Produzir uma Carta")
	_build_produce_section()

	_add_section_title("Aprimorar Manualmente (3 cópias -> 1 do Tier seguinte)")
	_build_upgrade_section()

	_add_section_title("Fila de Tarefas")
	_fila_container = VBoxContainer.new()
	_fila_container.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(_fila_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


const PRODUCE_FACTIONS: Array[String] = ["(todas)", "Império", "Natureza", "Mortos-Vivos"]
const PRODUCE_CLASSES: Array[String] = ["(todas)", "Corpo a Corpo", "À Distância", "Mago", "Suporte", "Barreira", "Máquina de Guerra"]
const PRODUCE_RARITIES: Array[String] = ["(todas)", "Comum", "Rara", "Épica", "Lendária"]


func _build_produce_section() -> void:
	var filters_row := HBoxContainer.new()
	_root_vbox.add_child(filters_row)

	var faction_option := OptionButton.new()
	for faction: String in PRODUCE_FACTIONS:
		faction_option.add_item(faction)
	faction_option.selected = PRODUCE_FACTIONS.find(_produce_filter_faction)
	faction_option.item_selected.connect(_on_produce_filter_faction_selected.bind(faction_option), CONNECT_DEFERRED)
	filters_row.add_child(faction_option)

	var class_option := OptionButton.new()
	for card_class: String in PRODUCE_CLASSES:
		class_option.add_item(card_class)
	class_option.selected = PRODUCE_CLASSES.find(_produce_filter_class)
	class_option.item_selected.connect(_on_produce_filter_class_selected.bind(class_option), CONNECT_DEFERRED)
	filters_row.add_child(class_option)

	var rarity_option := OptionButton.new()
	for rarity: String in PRODUCE_RARITIES:
		rarity_option.add_item(rarity)
	rarity_option.selected = PRODUCE_RARITIES.find(_produce_filter_rarity)
	rarity_option.item_selected.connect(_on_produce_filter_rarity_selected.bind(rarity_option), CONNECT_DEFERRED)
	filters_row.add_child(rarity_option)

	var card_row := HBoxContainer.new()
	_root_vbox.add_child(card_row)
	var card_label := Label.new()
	card_label.text = "Carta:"
	card_row.add_child(card_label)
	_produce_card_option = OptionButton.new()
	_refresh_produce_card_options()
	_produce_card_option.item_selected.connect(_on_produce_card_selected, CONNECT_DEFERRED)
	card_row.add_child(_produce_card_option)

	var quantity_row := HBoxContainer.new()
	_root_vbox.add_child(quantity_row)
	var quantity_label := Label.new()
	quantity_label.text = "Quantidade:"
	quantity_row.add_child(quantity_label)
	var quantity_spin := SpinBox.new()
	quantity_spin.min_value = 1
	quantity_spin.max_value = 20
	quantity_spin.value = 1
	quantity_spin.value_changed.connect(_on_produce_quantity_changed, CONNECT_DEFERRED)
	quantity_row.add_child(quantity_spin)

	var preserve_check := CheckBox.new()
	preserve_check.text = "Preservar Inventário (não reaproveitar cópias já existentes)"
	preserve_check.toggled.connect(_on_preserve_inventory_toggled, CONNECT_DEFERRED)
	_root_vbox.add_child(preserve_check)

	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(_preview_label)

	var action_row := HBoxContainer.new()
	_root_vbox.add_child(action_row)
	var preview_button := Button.new()
	preview_button.text = "Prever"
	preview_button.pressed.connect(_on_preview_pressed, CONNECT_DEFERRED)
	action_row.add_child(preview_button)
	var produce_button := Button.new()
	produce_button.text = "Produzir"
	produce_button.pressed.connect(_on_produce_pressed, CONNECT_DEFERRED)
	action_row.add_child(produce_button)


func _build_upgrade_section() -> void:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)
	var label := Label.new()
	label.text = "Escolha uma carta e Tier que você possui, com pelo menos 3 cópias Livres:"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(400, 0)
	row.add_child(label)

	var owned_option := OptionButton.new()
	var owned_groups: Dictionary = _group_owned_cards_by_name_and_tier()
	var keys: Array = owned_groups.keys()
	for i in range(keys.size()):
		var key: Array = keys[i]  # [card_name, tier]
		var count: int = owned_groups[key]
		owned_option.add_item("%s (Tier %d) — %d Livre(s)" % [key[0], key[1], count], i)
	if not keys.is_empty():
		_selected_upgrade_card_name = keys[0][0]
		_selected_upgrade_tier = keys[0][1]
	owned_option.item_selected.connect(_on_upgrade_card_selected.bind(keys), CONNECT_DEFERRED)
	row.add_child(owned_option)

	var upgrade_button := Button.new()
	upgrade_button.text = "Aprimorar"
	upgrade_button.pressed.connect(_on_upgrade_pressed, CONNECT_DEFERRED)
	row.add_child(upgrade_button)


## Agrupa as cartas Livres do Reino por (nome, Tier) — só entradas com
## 3 ou mais cópias aparecem (mínimo pra sequer tentar Aprimorar), e
## nunca Tier 5 (não existe Tier 6 pra evoluir).
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


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.sync_academy_masters()
	GameRuntime.sync(kingdom, GameClock.now_unix())

	# Reconstrói tudo primeiro (as opções de Produzir/Aprimorar mudam a
	# cada ação — mais simples reconstruir do que atualizar
	# incrementalmente) — só DEPOIS preenche os textos que dependem do
	# estado atual, senão _build_static_structure() sobrescreveria com
	# Labels novos e vazios.
	_clear_children(self)
	_build_static_structure()

	var fragment_lines: Array[String] = []
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		fragment_lines.append("%s: %d" % [faction, kingdom.get_fragment(faction)])
	_resumo_label.text = "Nível da Academia: %d | Redução de Tempo: %.1f%%\nFragmentos — %s" % [
		kingdom.academy_level, AcademyEconomy.time_reduction(kingdom.academy_level) * 100.0, " | ".join(fragment_lines)
	]

	_refresh_mestres(kingdom)
	_refresh_fila(kingdom)


func _refresh_mestres(kingdom: Kingdom) -> void:
	_clear_children(_mestres_container)
	_build_master_rows(kingdom, kingdom.academy_artifices, "Artífice")
	_build_master_rows(kingdom, kingdom.academy_metamorfos, "Metamorfo")


func _build_master_rows(kingdom: Kingdom, masters: Array[AcademyMaster], label_prefix: String) -> void:
	for i in range(masters.size()):
		var master: AcademyMaster = masters[i]
		var row := HBoxContainer.new()
		_mestres_container.add_child(row)

		var task: AcademyTask = master.current_task()
		var status_text: String
		if task == null:
			status_text = "Ocioso"
		elif not task.has_started():
			status_text = "Na fila, aguardando"
		else:
			var remaining: int = maxi(0, task.end_unix - GameClock.now_unix())
			status_text = "%s x%d — ~%ds restantes" % [task.target_card_name, task.quantity, remaining]

		var label := Label.new()
		label.text = "%s %d — Fila: %d/%d — %s" % [label_prefix, i + 1, master.queue.size(), master.queue_capacity, status_text]
		label.custom_minimum_size = Vector2(500, 0)
		row.add_child(label)

		var upgrade_button := Button.new()
		upgrade_button.text = "Melhorar Fila"
		upgrade_button.pressed.connect(_on_upgrade_master_queue_pressed.bind(master), CONNECT_DEFERRED)
		row.add_child(upgrade_button)


func _refresh_fila(kingdom: Kingdom) -> void:
	_clear_children(_fila_container)

	for master: AcademyMaster in kingdom.academy_artifices + kingdom.academy_metamorfos:
		for task: AcademyTask in master.queue:
			var row := HBoxContainer.new()
			_fila_container.add_child(row)

			var label := Label.new()
			label.text = "%s x%d (%s)" % [task.target_card_name, task.quantity, "iniciada" if task.has_started() else "na fila"]
			label.custom_minimum_size = Vector2(400, 0)
			row.add_child(label)

			var cancel_button := Button.new()
			cancel_button.text = "Cancelar"
			cancel_button.disabled = task.has_started()
			cancel_button.pressed.connect(_on_cancel_task_pressed.bind(master, task), CONNECT_DEFERRED)
			row.add_child(cancel_button)

	if _fila_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma tarefa na fila."
		_fila_container.add_child(empty_label)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")


## Reconstrói a lista de Cartas conforme os filtros ativos — chamado
## na montagem inicial e sempre que qualquer filtro muda.
func _refresh_produce_card_options() -> void:
	_filtered_produce_cards.clear()
	_produce_card_option.clear()

	for card: CardResource in GameDatabase.cards:
		if _produce_filter_faction != "(todas)" and card.faction != _produce_filter_faction:
			continue
		if _produce_filter_class != "(todas)" and card.card_class != _produce_filter_class:
			continue
		if _produce_filter_rarity != "(todas)" and card.rarity != _produce_filter_rarity:
			continue
		_filtered_produce_cards.append(card)
		var recipe_text: String = "Fragmento" if card.recipe_ingredients.is_empty() else "Receita: %s" % ", ".join(card.recipe_ingredients)
		_produce_card_option.add_item("%s (%s, %s)" % [card.card_name, card.rarity, recipe_text])

	if _filtered_produce_cards.has(_selected_produce_card):
		_produce_card_option.selected = _filtered_produce_cards.find(_selected_produce_card)
	elif not _filtered_produce_cards.is_empty():
		_selected_produce_card = _filtered_produce_cards[0]
		_produce_card_option.selected = 0
	else:
		_selected_produce_card = null
	if _preview_label != null:
		_preview_label.text = ""


func _on_produce_filter_faction_selected(index: int, option: OptionButton) -> void:
	_produce_filter_faction = option.get_item_text(index)
	_refresh_produce_card_options()


func _on_produce_filter_class_selected(index: int, option: OptionButton) -> void:
	_produce_filter_class = option.get_item_text(index)
	_refresh_produce_card_options()


func _on_produce_filter_rarity_selected(index: int, option: OptionButton) -> void:
	_produce_filter_rarity = option.get_item_text(index)
	_refresh_produce_card_options()


func _on_produce_card_selected(index: int) -> void:
	_selected_produce_card = _filtered_produce_cards[index]
	_preview_label.text = ""


func _on_produce_quantity_changed(value: float) -> void:
	_produce_quantity = int(value)


func _on_preserve_inventory_toggled(pressed: bool) -> void:
	_preserve_inventory = pressed


func _on_preview_pressed() -> void:
	if _selected_produce_card == null:
		return
	var result: Dictionary = AcademyResolver.preview_production(
		KingdomState.kingdom, _selected_produce_card.card_name, _produce_quantity, _preserve_inventory
	)
	if not result["valid"]:
		_preview_label.text = "Previsão inválida: %s" % result["reason"]
		return

	var produce_lines: Array[String] = []
	for card_name: String in result["new_cards_to_produce"]:
		produce_lines.append("%s x%d" % [card_name, result["new_cards_to_produce"][card_name]])

	_preview_label.text = "Custo em Fragmentos (%s): %d | Pagável? %s\nA produzir: %s\nReaproveitado do inventário: %s\nTempo sequencial estimado: %ds" % [
		result["faction"], result["total_fragment_cost"], str(result["affordable"]),
		", ".join(produce_lines) if not produce_lines.is_empty() else "nada (tudo reaproveitado)",
		", ".join(result["existing_cards_to_reuse"]) if not result["existing_cards_to_reuse"].is_empty() else "nada",
		result["sequential_time_seconds"]
	]


func _on_produce_pressed() -> void:
	if _selected_produce_card == null:
		return
	var result: Dictionary = AcademyResolver.request_production(
		KingdomState.kingdom, _selected_produce_card.card_name, _produce_quantity, GameClock.now_unix(), _preserve_inventory
	)
	if not result["success"]:
		print("[AcademiaPanel] Produzir falhou: %s" % result["reason"])
	refresh()


func _on_upgrade_card_selected(index: int, keys: Array) -> void:
	var key: Array = keys[index]
	_selected_upgrade_card_name = key[0]
	_selected_upgrade_tier = key[1]


func _on_upgrade_pressed() -> void:
	if _selected_upgrade_card_name == "":
		return
	var result: Dictionary = AcademyResolver.request_upgrade(
		KingdomState.kingdom, _selected_upgrade_card_name, _selected_upgrade_tier, 1, GameClock.now_unix()
	)
	if not result["success"]:
		print("[AcademiaPanel] Aprimorar falhou: %s" % result["reason"])
	refresh()


func _on_upgrade_master_queue_pressed(master: AcademyMaster) -> void:
	var result: Dictionary = AcademyResolver.upgrade_queue_capacity(KingdomState.kingdom, master)
	if not result["success"]:
		print("[AcademiaPanel] Melhorar Fila falhou: %s" % result["reason"])
	refresh()


func _on_cancel_task_pressed(master: AcademyMaster, task: AcademyTask) -> void:
	AcademyResolver.cancel_task(KingdomState.kingdom, master, task)
	refresh()
