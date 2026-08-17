extends Control
## LegadoPanel (COMMAND_CENTER_UI.md, "Janela: Legado")
##
## Resumo Administrativo + Aposentar um Comandante (Legado
## Administrativo) + Grande Legado Militar + Hall dos Comandantes.
## Mesmo padrão das demais janelas: árvore em código, sem estado
## próprio, reconstruída inteira a cada ação.
##
## Grande Legado Militar aqui é simplificado: não existe ainda um
## Editor de Exército na UI (peça em aberto, fora do escopo desta
## janela) — em vez de montar um Exército na tela, listamos os
## Exércitos já existentes no Reino e deixamos o próprio
## LegacyResolver validar e reportar o motivo se algum requisito não
## bater, ao tentar.

var _root_vbox: VBoxContainer
var _resumo_label: Label
var _aposentar_container: VBoxContainer
var _doutrina_label: Label
var _grande_legado_container: VBoxContainer
var _hall_container: VBoxContainer

var _legado_v_destino_by_commander: Dictionary = {}  # instance_id -> "xp"/"resources"/"fragments"
var _attribute_choice_by_army: Dictionary = {}  # army (referência) -> "escudo"/"vida"/"ataque"


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	refresh()
	print("[LegadoPanel] Pronto. Comandantes elegíveis pra aposentar: %d | Hall: %d" % [
		_aposentar_container.get_child_count(), KingdomState.kingdom.commander_hall().size()
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
	_root_vbox.custom_minimum_size = Vector2(700, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Legado"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	# --- Resumo Administrativo ---
	var resumo_panel := PanelContainer.new()
	_root_vbox.add_child(resumo_panel)
	var resumo_vbox := VBoxContainer.new()
	resumo_panel.add_child(resumo_vbox)
	_resumo_label = Label.new()
	resumo_vbox.add_child(_resumo_label)

	# --- Aposentar um Comandante ---
	_add_section_title("Aposentar um Comandante (Legado Administrativo)")
	_aposentar_container = VBoxContainer.new()
	_root_vbox.add_child(_aposentar_container)

	# --- Grande Legado Militar ---
	_add_section_title("Grande Legado Militar")
	_doutrina_label = Label.new()
	_root_vbox.add_child(_doutrina_label)
	_grande_legado_container = VBoxContainer.new()
	_root_vbox.add_child(_grande_legado_container)

	# --- Hall dos Comandantes ---
	_add_section_title("Hall dos Comandantes")
	_hall_container = VBoxContainer.new()
	_root_vbox.add_child(_hall_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom

	_resumo_label.text = ("Total aposentados (Legado Administrativo): %d\n" +
		"Bônus de XP de Treinamento (Legado I): +%.1f pp\n" +
		"Bônus permanente acumulado (Legado V): XP +%.2f%% | Recursos +%.2f%% | Fragmentos +%.2f%%") % [
		kingdom.legacy_administrative_retirees, kingdom.legacy_i_xp_bonus_percent,
		kingdom.legacy_v_bonus_xp, kingdom.legacy_v_bonus_resources, kingdom.legacy_v_bonus_fragments
	]

	_refresh_aposentar(kingdom)
	_refresh_grande_legado(kingdom)
	_refresh_hall(kingdom)


func _refresh_aposentar(kingdom: Kingdom) -> void:
	_clear_children(_aposentar_container)

	for commander: CommanderResource in kingdom.commanders:
		var state: CommanderResource.AdministrativeState = commander.administrative_state
		if state != CommanderResource.AdministrativeState.RESERVE and state != CommanderResource.AdministrativeState.ACTIVE:
			continue

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		if not LegacyResolver.meets_patente(patente, LegacyResolver.PATENTE_MIN_LEGADO_I):
			continue  # abaixo do mínimo do Legado I: não elegível, nem aparece na lista

		var row := HBoxContainer.new()
		_aposentar_container.add_child(row)

		var label := Label.new()
		label.text = "%s | %s | %s" % [commander.commander_name, patente, commander.faction]
		label.custom_minimum_size = Vector2(350, 0)
		row.add_child(label)

		var destino_option := OptionButton.new()
		destino_option.add_item("Destino do Legado V: XP", 0)
		destino_option.add_item("Destino do Legado V: Recursos", 1)
		destino_option.add_item("Destino do Legado V: Fragmentos", 2)
		var destino_map: Array[String] = ["xp", "resources", "fragments"]
		var saved_destino: String = _legado_v_destino_by_commander.get(commander.instance_id, "xp")
		destino_option.selected = destino_map.find(saved_destino)
		destino_option.item_selected.connect(_on_legado_v_destino_selected.bind(commander, destino_map), CONNECT_DEFERRED)
		row.add_child(destino_option)

		var button := Button.new()
		button.text = "Aposentar (Legado Administrativo)"
		button.pressed.connect(_on_retire_administrative_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(button)

	if _aposentar_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante elegível (precisa estar na Reserva ou Ativo)."
		_aposentar_container.add_child(empty_label)


func _refresh_grande_legado(kingdom: Kingdom) -> void:
	if kingdom.command_center_level < LegacyResolver.GRANDE_LEGADO_CDC_LEVEL:
		_doutrina_label.text = "Bloqueado — exige Centro de Comando Nível %d (atual: %d)." % [
			LegacyResolver.GRANDE_LEGADO_CDC_LEVEL, kingdom.command_center_level
		]
		_doutrina_label.visible = true
		_clear_children(_grande_legado_container)
		return

	_doutrina_label.visible = true
	var doctrine_lines: Array[String] = []
	for faction: String in LegacyResolver.DOCTRINE_LIMITS:
		kingdom.ensure_military_doctrine(faction)
		var d: Dictionary = kingdom.military_doctrine[faction]
		var limits: Dictionary = LegacyResolver.DOCTRINE_LIMITS[faction]
		doctrine_lines.append("%s — Escudo %d/%d | Vida %d/%d | Ataque %d/%d | Grandes Legados: %d" % [
			faction, d["escudo"], limits["escudo"], d["vida"], limits["vida"], d["ataque"], limits["ataque"], d["grandes_legados"]
		])
	_doutrina_label.text = "\n".join(doctrine_lines)

	_clear_children(_grande_legado_container)
	for army: Army in kingdom.armies:
		if army.commander == null:
			continue

		var row := HBoxContainer.new()
		_grande_legado_container.add_child(row)

		var patente: String = CommanderCareer.patente_for_xp(army.commander.accumulated_xp)
		var label := Label.new()
		label.text = "Exército de %s (%s, %s)" % [army.commander.commander_name, patente, army.commander.faction]
		label.custom_minimum_size = Vector2(350, 0)
		row.add_child(label)

		var attribute_option := OptionButton.new()
		attribute_option.add_item("Atributo: Escudo", 0)
		attribute_option.add_item("Atributo: Vida", 1)
		attribute_option.add_item("Atributo: Ataque", 2)
		var attribute_map: Array[String] = ["escudo", "vida", "ataque"]
		var saved_attribute: String = _attribute_choice_by_army.get(army, "escudo")
		attribute_option.selected = attribute_map.find(saved_attribute)
		attribute_option.item_selected.connect(_on_attribute_choice_selected.bind(army, attribute_map), CONNECT_DEFERRED)
		row.add_child(attribute_option)

		var button := Button.new()
		button.text = "Criar Grande Legado Militar"
		button.pressed.connect(_on_create_grande_legado_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(button)

	if _grande_legado_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Exército no Reino no momento."
		_grande_legado_container.add_child(empty_label)


func _refresh_hall(kingdom: Kingdom) -> void:
	_clear_children(_hall_container)

	for commander: CommanderResource in kingdom.commander_hall():
		var label := Label.new()
		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		label.text = "%s | Patente Final: %s | Facção: %s | Tipo: %s | Benefício: %s" % [
			commander.commander_name, patente, commander.faction, commander.retirement_type, commander.retirement_benefit
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_hall_container.add_child(label)

	if _hall_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante aposentado ainda."
		_hall_container.add_child(empty_label)


func _clear_children(container: Node) -> void:
	# Remoção IMEDIATA (não queue_free): esta tela reconstrói a árvore
	# inteira sincronamente a cada refresh() — queue_free() só remove no
	# fim do frame, o que deixaria nós antigos e novos coexistindo até lá
	# (encontrado num teste que checava se algo tinha sumido da lista).
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_legado_v_destino_selected(index: int, commander: CommanderResource, destino_map: Array[String]) -> void:
	_legado_v_destino_by_commander[commander.instance_id] = destino_map[index]


func _on_attribute_choice_selected(index: int, army: Army, attribute_map: Array[String]) -> void:
	_attribute_choice_by_army[army] = attribute_map[index]


func _on_retire_administrative_pressed(commander: CommanderResource) -> void:
	var destino: String = _legado_v_destino_by_commander.get(commander.instance_id, "xp")
	var result: Dictionary = LegacyResolver.retire_administrative(KingdomState.kingdom, commander, GameClock.now_unix(), destino)
	if not result["success"]:
		print("[LegadoPanel] Aposentadoria (Legado Administrativo) falhou: %s" % result["reason"])
	refresh()


func _on_create_grande_legado_pressed(army: Army) -> void:
	var attribute_choice: String = _attribute_choice_by_army.get(army, "escudo")
	var result: Dictionary = LegacyResolver.create_grande_legado_militar(
		KingdomState.kingdom, army.commander, army, GameClock.now_unix(), attribute_choice
	)
	if not result["success"]:
		print("[LegadoPanel] Grande Legado Militar falhou: %s" % result["reason"])
	refresh()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
