extends Control
## BibliotecaPanel (LIBRARY.md)
##
## Enciclopédia de Cartas: filtros, lista, página de detalhe (Cabeçalho,
## Coleção, Atributos por Tier, Habilidades, Origem/Receita,
## Relacionamentos, Favoritos), Comparação, Estatísticas da Biblioteca.
## Mesmo padrão das demais janelas: árvore em código, sem estado
## próprio, reconstruída a cada ação.
##
## LACUNAS DE CONTEÚDO (não de regra — nada aqui foi inventado):
## - "Lore" (LIBRARY.md §3): fonte seria LIBRARY_CONTENT.md, mas
##   database/library_content/ está vazia — nenhum texto de lore
##   existe ainda no projeto. Mostra "Lore não disponível ainda."
## - "Arte Conceitual" (LIBRARY.md §2): nenhuma arte existe ainda
##   (produção artística em paralelo, fora do escopo desta janela).
## - "Velocidade" e "Alcance" (LIBRARY.md §5, "Atributos Base"):
##   CardResource nunca teve esses campos — o motor de combate
##   implementado usa só HP/Ataque/Defesa (ESC) o jogo inteiro,
##   confirmado em COMBAT_CORE.md. Não mostrado, por não existir.
## - "Árvore de Evolução Visual" (LIBRARY.md §10): mostrada como lista
##   em texto (Produzida a partir de / Utilizada em), não como grafo
##   visual — mesma limitação de sempre (motor sem renderização daqui).

var _root_vbox: VBoxContainer
var _stats_label: Label
var _list_container: VBoxContainer
var _detail_container: VBoxContainer
var _compare_container: VBoxContainer

var _filter_faction: String = "(todas)"
var _filter_rarity: String = "(todas)"
var _filter_owned_only: bool = false
var _filter_favorites_only: bool = false

var _selected_card_name: String = ""
var _compare_card_name_a: String = ""
var _compare_card_name_b: String = ""


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	refresh()
	print("[BibliotecaPanel] Pronto. Cartas no catálogo: %d" % GameDatabase.cards.size())


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
	_root_vbox.custom_minimum_size = Vector2(800, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Biblioteca"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	_add_section_title("Estatísticas da Coleção")
	_stats_label = Label.new()
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(_stats_label)

	_add_section_title("Filtros")
	_build_filters()

	_add_section_title("Cartas")
	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 4)
	_root_vbox.add_child(_list_container)

	_add_section_title("Detalhe")
	_detail_container = VBoxContainer.new()
	_root_vbox.add_child(_detail_container)

	_add_section_title("Comparação")
	_compare_container = VBoxContainer.new()
	_root_vbox.add_child(_compare_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


func _build_filters() -> void:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)

	var faction_option := OptionButton.new()
	faction_option.add_item("(todas)")
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		faction_option.add_item(faction)
	faction_option.item_selected.connect(_on_faction_filter_selected.bind(faction_option), CONNECT_DEFERRED)
	row.add_child(faction_option)

	var rarity_option := OptionButton.new()
	rarity_option.add_item("(todas)")
	for rarity: String in ["Comum", "Rara", "Épica", "Lendária"]:
		rarity_option.add_item(rarity)
	rarity_option.item_selected.connect(_on_rarity_filter_selected.bind(rarity_option), CONNECT_DEFERRED)
	row.add_child(rarity_option)

	var owned_check := CheckBox.new()
	owned_check.text = "Só Possuídas"
	owned_check.toggled.connect(_on_owned_only_toggled, CONNECT_DEFERRED)
	row.add_child(owned_check)

	var favorites_check := CheckBox.new()
	favorites_check.text = "Só Favoritas"
	favorites_check.toggled.connect(_on_favorites_only_toggled, CONNECT_DEFERRED)
	row.add_child(favorites_check)


func refresh() -> void:
	_clear_children(self)
	_build_static_structure()

	var kingdom: Kingdom = KingdomState.kingdom
	_refresh_stats(kingdom)
	_refresh_list(kingdom)
	_refresh_detail(kingdom)
	_refresh_compare(kingdom)


func _owned_card_names(kingdom: Kingdom) -> Dictionary:
	var owned: Dictionary = {}
	for card: CardResource in kingdom.cards:
		owned[card.card_name] = true
	return owned


func _max_tier_owned(kingdom: Kingdom, card_name: String) -> int:
	var max_tier: int = 0
	for card: CardResource in kingdom.cards:
		if card.card_name == card_name:
			max_tier = maxi(max_tier, card.tier)
	return max_tier


func _refresh_stats(kingdom: Kingdom) -> void:
	var owned: Dictionary = _owned_card_names(kingdom)
	var total: int = GameDatabase.cards.size()
	var unlocked: int = owned.size()
	var percent: float = (float(unlocked) / float(total) * 100.0) if total > 0 else 0.0

	var by_faction: Dictionary = {}
	var by_rarity: Dictionary = {}
	var by_tier: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for card: CardResource in kingdom.cards:
		by_faction[card.faction] = by_faction.get(card.faction, 0) + 1
		by_rarity[card.rarity] = by_rarity.get(card.rarity, 0) + 1
		by_tier[card.tier] = by_tier.get(card.tier, 0) + 1

	var faction_lines: Array[String] = []
	for faction: String in by_faction:
		faction_lines.append("%s: %d" % [faction, by_faction[faction]])
	var rarity_lines: Array[String] = []
	for rarity: String in by_rarity:
		rarity_lines.append("%s: %d" % [rarity, by_rarity[rarity]])

	_stats_label.text = "Coleção: %d/%d cartas desbloqueadas (%.1f%%)\nPor Facção: %s\nPor Raridade: %s\nPor Tier — I: %d | II: %d | III: %d | IV: %d | V: %d" % [
		unlocked, total, percent, ", ".join(faction_lines), ", ".join(rarity_lines),
		by_tier[1], by_tier[2], by_tier[3], by_tier[4], by_tier[5]
	]


func _filtered_cards() -> Array[CardResource]:
	var kingdom: Kingdom = KingdomState.kingdom
	var owned: Dictionary = _owned_card_names(kingdom)
	var result: Array[CardResource] = []

	for card: CardResource in GameDatabase.cards:
		if _filter_faction != "(todas)" and card.faction != _filter_faction:
			continue
		if _filter_rarity != "(todas)" and card.rarity != _filter_rarity:
			continue
		if _filter_owned_only and not owned.has(card.card_name):
			continue
		if _filter_favorites_only and not kingdom.is_favorite_card(card.card_name):
			continue
		result.append(card)

	return result


func _refresh_list(kingdom: Kingdom) -> void:
	_clear_children(_list_container)
	var owned: Dictionary = _owned_card_names(kingdom)

	for card: CardResource in _filtered_cards():
		var row := HBoxContainer.new()
		_list_container.add_child(row)

		var indicators: Array[String] = []
		if owned.has(card.card_name):
			indicators.append("Possuída")
		else:
			indicators.append("Não Possuída")
		if kingdom.is_favorite_card(card.card_name):
			indicators.append("★ Favorita")
		if kingdom.is_new_card(card.card_name):
			indicators.append("Nova")
		if _max_tier_owned(kingdom, card.card_name) == 5:
			indicators.append("Tier Máximo")

		var button := Button.new()
		button.text = "%s (%s, %s) — %s" % [card.card_name, card.rarity, card.faction, ", ".join(indicators)]
		button.pressed.connect(_on_card_selected.bind(card.card_name), CONNECT_DEFERRED)
		row.add_child(button)

	if _list_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma carta corresponde aos filtros."
		_list_container.add_child(empty_label)


func _refresh_detail(kingdom: Kingdom) -> void:
	_clear_children(_detail_container)

	if _selected_card_name == "":
		var empty_label := Label.new()
		empty_label.text = "Selecione uma carta na lista acima para ver o detalhe."
		_detail_container.add_child(empty_label)
		return

	kingdom.clear_new_card_flag(_selected_card_name)

	var template: CardResource = GameDatabase.get_card(_selected_card_name)
	if template == null:
		return

	# --- Cabeçalho ---
	var header := Label.new()
	header.text = "%s | %s | %s | %s | Custo de Soldo: %d" % [
		template.card_name, template.faction, template.card_class, template.rarity, Soldo.cost_for_rarity(template.rarity)
	]
	header.add_theme_font_size_override("font_size", 16)
	_detail_container.add_child(header)

	# --- Favoritar ---
	var favorite_button := Button.new()
	favorite_button.text = "Desfavoritar" if kingdom.is_favorite_card(_selected_card_name) else "Favoritar"
	favorite_button.pressed.connect(_on_toggle_favorite_pressed, CONNECT_DEFERRED)
	_detail_container.add_child(favorite_button)

	# --- Lore ---
	var lore_label := Label.new()
	lore_label.text = "Lore não disponível ainda."
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_container.add_child(lore_label)

	# --- Informações de Coleção ---
	var owned_copies: Array[CardResource] = []
	for card: CardResource in kingdom.cards:
		if card.card_name == _selected_card_name:
			owned_copies.append(card)
	var by_tier_count: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for card: CardResource in owned_copies:
		by_tier_count[card.tier] += 1
	var collection_label := Label.new()
	collection_label.text = "Status: %s | Total: %d | Por Tier — I: %d, II: %d, III: %d, IV: %d, V: %d | Maior Tier: %d" % [
		"Possuída" if not owned_copies.is_empty() else "Não Possuída", owned_copies.size(),
		by_tier_count[1], by_tier_count[2], by_tier_count[3], by_tier_count[4], by_tier_count[5],
		_max_tier_owned(kingdom, _selected_card_name)
	]
	_detail_container.add_child(collection_label)

	# --- Atributos por Tier (I a V) ---
	var progression_title := Label.new()
	progression_title.text = "Progressão por Tier:"
	_detail_container.add_child(progression_title)
	var current: CardResource = template.duplicate()
	current.tier = 1
	for tier in range(1, 6):
		var line := Label.new()
		var ability_text: String = CardProgression.unlocked_ability_name(current)
		line.text = "Tier %d — HP: %d | ATK: %d | Defesa: %d%s" % [
			tier, current.hp, current.atk, current.esc,
			(" | Desbloqueia: %s" % ability_text) if ability_text != "" else ""
		]
		_detail_container.add_child(line)
		if tier < 5:
			current = CardProgression.advance_tier(current)

	# --- Origem e Receita ---
	var origin_label := Label.new()
	if template.recipe_ingredients.is_empty():
		origin_label.text = "Origem: Produzida diretamente na Academia através de Fragmentos."
	else:
		origin_label.text = "Origem: Receita — %s" % ", ".join(template.recipe_ingredients)
	_detail_container.add_child(origin_label)

	# --- Utilizada nas seguintes Receitas ---
	var used_in: Array[String] = []
	for card: CardResource in GameDatabase.cards:
		if card.recipe_ingredients.has(_selected_card_name):
			used_in.append(card.card_name)
	var used_in_label := Label.new()
	used_in_label.text = "Utilizada nas Receitas de: %s" % (", ".join(used_in) if not used_in.is_empty() else "nenhuma")
	used_in_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_container.add_child(used_in_label)

	# --- Mesmo Grupo ---
	var same_group: Array[String] = []
	for card: CardResource in GameDatabase.cards:
		if card.card_name != template.card_name and card.faction == template.faction and card.rarity == template.rarity and card.card_class == template.card_class:
			same_group.append(card.card_name)
	var group_label := Label.new()
	group_label.text = "Mesmo Grupo (Facção + Raridade + Classe): %s" % (", ".join(same_group) if not same_group.is_empty() else "nenhuma")
	group_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_container.add_child(group_label)

	# --- Comparação: atalhos ---
	var compare_row := HBoxContainer.new()
	_detail_container.add_child(compare_row)
	var set_a_button := Button.new()
	set_a_button.text = "Definir como Carta A da Comparação"
	set_a_button.pressed.connect(_on_set_compare_a_pressed, CONNECT_DEFERRED)
	compare_row.add_child(set_a_button)
	var set_b_button := Button.new()
	set_b_button.text = "Definir como Carta B da Comparação"
	set_b_button.pressed.connect(_on_set_compare_b_pressed, CONNECT_DEFERRED)
	compare_row.add_child(set_b_button)


func _refresh_compare(kingdom: Kingdom) -> void:
	_clear_children(_compare_container)

	if _compare_card_name_a == "" or _compare_card_name_b == "":
		var empty_label := Label.new()
		empty_label.text = "Escolha 2 cartas (\"Definir como Carta A/B\" no Detalhe) para comparar lado a lado."
		_compare_container.add_child(empty_label)
		return

	var card_a: CardResource = GameDatabase.get_card(_compare_card_name_a)
	var card_b: CardResource = GameDatabase.get_card(_compare_card_name_b)

	var row := HBoxContainer.new()
	_compare_container.add_child(row)
	for card: CardResource in [card_a, card_b]:
		var column := VBoxContainer.new()
		row.add_child(column)
		var label := Label.new()
		label.text = "%s\n%s | %s | %s\nHP: %d | ATK: %d | Defesa: %d\nCusto de Soldo: %d\nHabilidade Tier I: %s\nOrigem: %s" % [
			card.card_name, card.faction, card.rarity, card.card_class,
			card.hp, card.atk, card.esc, Soldo.cost_for_rarity(card.rarity),
			card.tier_1_trait_name if card.tier_1_trait_name != "" else "(nenhuma)",
			("Fragmentos" if card.recipe_ingredients.is_empty() else ", ".join(card.recipe_ingredients))
		]
		column.add_child(label)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")


func _on_faction_filter_selected(index: int, option: OptionButton) -> void:
	_filter_faction = option.get_item_text(index)
	refresh()


func _on_rarity_filter_selected(index: int, option: OptionButton) -> void:
	_filter_rarity = option.get_item_text(index)
	refresh()


func _on_owned_only_toggled(pressed: bool) -> void:
	_filter_owned_only = pressed
	refresh()


func _on_favorites_only_toggled(pressed: bool) -> void:
	_filter_favorites_only = pressed
	refresh()


func _on_card_selected(card_name: String) -> void:
	_selected_card_name = card_name
	refresh()


func _on_toggle_favorite_pressed() -> void:
	KingdomState.kingdom.toggle_favorite_card(_selected_card_name)
	refresh()


func _on_set_compare_a_pressed() -> void:
	_compare_card_name_a = _selected_card_name
	refresh()


func _on_set_compare_b_pressed() -> void:
	_compare_card_name_b = _selected_card_name
	refresh()
