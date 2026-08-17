extends Control
## PvPPanel (COMMAND_CENTER_UI.md, "Janela: PvP")
##
## Bronze (informativo — quaisquer Exércitos Ativos, sem registro
## formal) e configuração do Plano de Campanha (mapeamento dos 9
## Campos Especiais, Defesa Preferencial, Ordem de Ataque). Mesmo
## padrão das demais janelas: árvore em código, sem estado próprio,
## reconstruída a cada ação.
##
## ESCOPO DESTA ENTREGA — ver PlanoCampanhaResolver.gd pro detalhe
## completo: sem Ligas/Divisões/Pontos de Liga, sem Matchmaking, sem
## sorteio de Campo de Batalha. Só a criação e configuração do Plano
## de Campanha, que é tudo que já está fechado o suficiente pra
## implementar sem inventar regra nova.

var _root_vbox: VBoxContainer
var _bronze_container: VBoxContainer
var _planos_container: VBoxContainer

var _selected_for_new_plano: Array[Army] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	refresh()
	print("[PvPPanel] Pronto. Planos de Campanha: %d" % KingdomState.kingdom.planos_campanha.size())


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
	title.text = "PvP"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	var scope_note := Label.new()
	scope_note.text = "Ligas/Divisões/Pontos de Liga e sorteio de Campo já são reais. Sem Matchmaking de verdade (depende de servidor) — os botões de 'Simular Resultado' aplicam a pontuação sem um adversário real."
	scope_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(scope_note)

	_add_section_title("Liga Bronze (qualquer Exército Ativo, independente)")
	_bronze_container = VBoxContainer.new()
	_root_vbox.add_child(_bronze_container)

	_add_section_title("Planos de Campanha (Prata / Ouro / Diamante)")
	_planos_container = VBoxContainer.new()
	_planos_container.add_theme_constant_override("separation", 16)
	_root_vbox.add_child(_planos_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	_refresh_bronze(kingdom)
	_refresh_planos(kingdom)


func _active_armies(kingdom: Kingdom) -> Array[Army]:
	var result: Array[Army] = []
	for army: Army in kingdom.armies:
		if army.commander != null and army.commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE:
			result.append(army)
	return result


func _refresh_bronze(kingdom: Kingdom) -> void:
	_clear_children(_bronze_container)

	for army: Army in _active_armies(kingdom):
		var commander: CommanderResource = army.commander
		var row := VBoxContainer.new()
		_bronze_container.add_child(row)

		var info_row := HBoxContainer.new()
		row.add_child(info_row)
		var label := Label.new()
		if commander.bronze_divisao == "":
			label.text = "%s | Comandante: %s | Não inscrito na Liga Bronze" % [army.army_name, commander.commander_name]
		else:
			label.text = "%s | Comandante: %s | Divisão %s | %d PL" % [army.army_name, commander.commander_name, commander.bronze_divisao, commander.bronze_pl]
		label.custom_minimum_size = Vector2(450, 0)
		info_row.add_child(label)

		if commander.bronze_divisao == "":
			var inscrever_button := Button.new()
			inscrever_button.text = "Inscrever na Liga Bronze"
			inscrever_button.pressed.connect(_on_inscrever_bronze_pressed.bind(commander), CONNECT_DEFERRED)
			info_row.add_child(inscrever_button)
		else:
			var action_row := HBoxContainer.new()
			row.add_child(action_row)
			var sim_label := Label.new()
			sim_label.text = "Simular Resultado:"
			action_row.add_child(sim_label)
			for result_name: String in ["Vitória", "Derrota", "Empate"]:
				var button := Button.new()
				button.text = result_name
				button.pressed.connect(_on_simulate_bronze_result_pressed.bind(commander, result_name), CONNECT_DEFERRED)
				action_row.add_child(button)

	if _bronze_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Exército Ativo no momento."
		_bronze_container.add_child(empty_label)


func _refresh_planos(kingdom: Kingdom) -> void:
	_clear_children(_planos_container)

	# --- Criar novo Plano ---
	var create_panel := PanelContainer.new()
	_planos_container.add_child(create_panel)
	var create_vbox := VBoxContainer.new()
	create_panel.add_child(create_vbox)
	var create_title := Label.new()
	create_title.text = "Criar Plano de Campanha (escolha até 3 Exércitos Ativos):"
	create_vbox.add_child(create_title)

	for army: Army in _active_armies(kingdom):
		var check := CheckBox.new()
		check.text = "%s (%s)" % [army.army_name, army.commander.commander_name]
		check.button_pressed = _selected_for_new_plano.has(army)
		check.toggled.connect(_on_army_checkbox_toggled.bind(army), CONNECT_DEFERRED)
		create_vbox.add_child(check)

	var create_button := Button.new()
	create_button.text = "Criar Plano de Campanha"
	create_button.pressed.connect(_on_create_plano_pressed, CONNECT_DEFERRED)
	create_vbox.add_child(create_button)

	# --- Planos existentes ---
	for plano: PlanoCampanha in kingdom.planos_campanha:
		_build_plano_panel(plano)


func _build_plano_panel(plano: PlanoCampanha) -> void:
	var panel := PanelContainer.new()
	_planos_container.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var names: Array[String] = []
	for army: Army in plano.armies:
		names.append(army.army_name)
	var header := Label.new()
	header.text = "Plano: %s" % ", ".join(names)
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	# --- Ranking ---
	var ranking_row := HBoxContainer.new()
	vbox.add_child(ranking_row)
	if plano.liga == "":
		var liga_label := Label.new()
		liga_label.text = "Não inscrito em nenhuma Liga."
		ranking_row.add_child(liga_label)
		for liga_name: String in ["Prata", "Ouro", "Diamante"]:
			var inscrever_button := Button.new()
			inscrever_button.text = "Inscrever na %s" % liga_name
			inscrever_button.pressed.connect(_on_inscrever_plano_pressed.bind(plano, liga_name), CONNECT_DEFERRED)
			ranking_row.add_child(inscrever_button)
	else:
		var ranking_label := Label.new()
		ranking_label.text = "Liga %s | Divisão %s | %d PL" % [plano.liga, plano.divisao, plano.pl]
		ranking_row.add_child(ranking_label)

		var sortear_button := Button.new()
		sortear_button.text = "Sortear Campo de Batalha (Ataque)"
		sortear_button.pressed.connect(_on_sortear_ataque_pressed.bind(plano), CONNECT_DEFERRED)
		vbox.add_child(sortear_button)

		var sim_row := HBoxContainer.new()
		vbox.add_child(sim_row)
		var sim_label := Label.new()
		sim_label.text = "Simular Resultado como Atacante:"
		sim_row.add_child(sim_label)
		for result_name: String in ["Vitória", "Derrota", "Empate"]:
			var button := Button.new()
			button.text = result_name
			button.pressed.connect(_on_simulate_plano_result_pressed.bind(plano, result_name), CONNECT_DEFERRED)
			sim_row.add_child(button)

	# Defesa Preferencial (Campo Aberto).
	var defesa_row := HBoxContainer.new()
	vbox.add_child(defesa_row)
	var defesa_label := Label.new()
	defesa_label.text = "Defesa Preferencial (Campo Aberto):"
	defesa_row.add_child(defesa_label)
	var defesa_option := OptionButton.new()
	defesa_option.add_item("(nenhum)", -1)
	for i in range(plano.armies.size()):
		defesa_option.add_item(plano.armies[i].army_name, i)
	defesa_option.selected = plano.defesa_preferencial_index + 1
	defesa_option.item_selected.connect(_on_defesa_preferencial_selected.bind(plano), CONNECT_DEFERRED)
	defesa_row.add_child(defesa_option)

	# Ordem de Ataque.
	var ordem_title := Label.new()
	ordem_title.text = "Ordem de Ataque (desempate só no Campo Aberto):"
	vbox.add_child(ordem_title)
	for pos in range(plano.ordem_de_ataque.size()):
		var army_index: int = plano.ordem_de_ataque[pos]
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var label := Label.new()
		label.text = "%d. %s" % [pos + 1, plano.armies[army_index].army_name]
		label.custom_minimum_size = Vector2(250, 0)
		row.add_child(label)
		var up_button := Button.new()
		up_button.text = "▲"
		up_button.disabled = pos == 0
		up_button.pressed.connect(_on_move_ordem_pressed.bind(plano, pos, -1), CONNECT_DEFERRED)
		row.add_child(up_button)
		var down_button := Button.new()
		down_button.text = "▼"
		down_button.disabled = pos == plano.ordem_de_ataque.size() - 1
		down_button.pressed.connect(_on_move_ordem_pressed.bind(plano, pos, 1), CONNECT_DEFERRED)
		row.add_child(down_button)

	# Mapeamento dos 9 Campos Especiais.
	var mapping_title := Label.new()
	mapping_title.text = "Mapeamento dos Campos Especiais:"
	vbox.add_child(mapping_title)
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category == "Padrão":
			continue
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var label := Label.new()
		label.text = "%s (%s):" % [battlefield.battlefield_name, battlefield.category]
		label.custom_minimum_size = Vector2(300, 0)
		row.add_child(label)
		var option := OptionButton.new()
		option.add_item("(não mapeado)", -1)
		for i in range(plano.armies.size()):
			option.add_item(plano.armies[i].army_name, i)
		var current: int = plano.battlefield_mapping.get(battlefield.battlefield_name, -1)
		option.selected = current + 1
		option.item_selected.connect(_on_battlefield_mapping_selected.bind(plano, battlefield), CONNECT_DEFERRED)
		row.add_child(option)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_army_checkbox_toggled(pressed: bool, army: Army) -> void:
	if pressed:
		if not _selected_for_new_plano.has(army) and _selected_for_new_plano.size() < PlanoCampanhaResolver.MAX_ARMIES:
			_selected_for_new_plano.append(army)
	else:
		_selected_for_new_plano.erase(army)


func _on_create_plano_pressed() -> void:
	if _selected_for_new_plano.is_empty():
		return
	var result: Dictionary = PlanoCampanhaResolver.create(_selected_for_new_plano.duplicate())
	if result["success"]:
		KingdomState.kingdom.planos_campanha.append(result["plano"])
		_selected_for_new_plano.clear()
	else:
		print("[PvPPanel] Criar Plano de Campanha falhou: %s" % result["reason"])
	refresh()


func _on_defesa_preferencial_selected(index: int, plano: PlanoCampanha) -> void:
	var army_index: int = index - 1
	if army_index < 0:
		plano.defesa_preferencial_index = -1
		return
	PlanoCampanhaResolver.set_defesa_preferencial(plano, army_index)
	refresh()


func _on_move_ordem_pressed(plano: PlanoCampanha, position: int, direction: int) -> void:
	var target: int = position + direction
	if target < 0 or target >= plano.ordem_de_ataque.size():
		return
	var new_order: Array[int] = plano.ordem_de_ataque.duplicate()
	var temp: int = new_order[position]
	new_order[position] = new_order[target]
	new_order[target] = temp
	PlanoCampanhaResolver.set_ordem_de_ataque(plano, new_order)
	refresh()


func _on_battlefield_mapping_selected(index: int, plano: PlanoCampanha, battlefield: BattlefieldResource) -> void:
	var army_index: int = index - 1
	if army_index < 0:
		plano.battlefield_mapping.erase(battlefield.battlefield_name)
		return
	PlanoCampanhaResolver.map_battlefield(plano, battlefield, army_index)
	refresh()


func _on_inscrever_bronze_pressed(commander: CommanderResource) -> void:
	commander.bronze_divisao = RankingResolver.initial_division()
	commander.bronze_pl = 0
	refresh()


func _on_simulate_bronze_result_pressed(commander: CommanderResource, result_name: String) -> void:
	var result: RankingResolver.Result = _result_from_name(result_name)
	# Bronze não distingue Ataque/Defesa (RANKING.md, "Isenções do
	# Modelo") — usa sempre a tabela de Atacante.
	var outcome: Dictionary = RankingResolver.apply_result(commander.bronze_pl, commander.bronze_divisao, RankingResolver.Role.ATACANTE, result)
	commander.bronze_pl = outcome["pl"]
	commander.bronze_divisao = outcome["division"]
	refresh()


func _on_inscrever_plano_pressed(plano: PlanoCampanha, liga_name: String) -> void:
	plano.liga = liga_name
	plano.divisao = RankingResolver.initial_division()
	plano.pl = 0
	refresh()


func _on_simulate_plano_result_pressed(plano: PlanoCampanha, result_name: String) -> void:
	var result: RankingResolver.Result = _result_from_name(result_name)
	var outcome: Dictionary = RankingResolver.apply_result(plano.pl, plano.divisao, RankingResolver.Role.ATACANTE, result)
	plano.pl = outcome["pl"]
	plano.divisao = outcome["division"]
	refresh()


func _on_sortear_ataque_pressed(plano: PlanoCampanha) -> void:
	var result: Dictionary = PlanoCampanhaResolver.select_attack(plano, GameDatabase.battlefields, _rng)
	if not result["success"]:
		print("[PvPPanel] Sortear Campo falhou: %s" % result["reason"])
	else:
		print("[PvPPanel] Campo sorteado: %s | Exército atacante: %s" % [result["battlefield"].battlefield_name, result["army"].army_name])
	refresh()


func _result_from_name(result_name: String) -> RankingResolver.Result:
	match result_name:
		"Vitória":
			return RankingResolver.Result.VITORIA
		"Derrota":
			return RankingResolver.Result.DERROTA
		_:
			return RankingResolver.Result.EMPATE


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
