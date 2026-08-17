extends Control
## TreinamentoPanel (COMMAND_CENTER_UI.md, "Janela: Treinamento")
##
## Resumo (Vagas, Média Diária, bônus do Legado I) + lista de
## Comandantes em Treinamento (tempo restante, XP do ciclo, progresso
## até a próxima Patente) + envio de Comandantes da Reserva. Mesmo
## padrão do ComandantesPanel: árvore construída em código, sem estado
## próprio, reconstruída inteira a cada ação.

const TRAINING_CYCLE_SECONDS: int = 10 * 24 * 3600  # CommanderTrainingResolver.TRAINING_CYCLE_DAYS

var _root_vbox: VBoxContainer
var _resumo_label: Label
var _em_treinamento_container: VBoxContainer
var _enviar_container: VBoxContainer


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	refresh()
	print("[TreinamentoPanel] Pronto. Comandantes em Treinamento: %d" % _em_treinamento_container.get_child_count())


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
	_root_vbox.custom_minimum_size = Vector2(600, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Treinamento"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	# --- Resumo ---
	var resumo_panel := PanelContainer.new()
	_root_vbox.add_child(resumo_panel)
	var resumo_vbox := VBoxContainer.new()
	resumo_panel.add_child(resumo_vbox)
	_resumo_label = Label.new()
	resumo_vbox.add_child(_resumo_label)

	# --- Em Treinamento ---
	_add_section_title("Em Treinamento")
	_em_treinamento_container = VBoxContainer.new()
	_root_vbox.add_child(_em_treinamento_container)

	# --- Enviar da Reserva ---
	_add_section_title("Enviar da Reserva")
	_enviar_container = VBoxContainer.new()
	_root_vbox.add_child(_enviar_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())

	var slots_used: int = 0
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state == CommanderResource.AdministrativeState.TRAINING:
			slots_used += 1
	var slots_cap: int = CommandCenterProgress.effective_training_slots(kingdom)

	_resumo_label.text = "Vagas de Treinamento: %d / %d    |    Média Diária de XP (último dia): %d    |    Bônus do Legado I: +%.1f pp" % [
		slots_used, slots_cap, kingdom.last_daily_average_xp, kingdom.legacy_i_xp_bonus_percent
	]

	_refresh_em_treinamento(kingdom)
	_refresh_enviar(kingdom)


func _refresh_em_treinamento(kingdom: Kingdom) -> void:
	_clear_children(_em_treinamento_container)
	var now: int = GameClock.now_unix()

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.TRAINING:
			continue

		var row := HBoxContainer.new()
		_em_treinamento_container.add_child(row)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var remaining_seconds: int = maxi(0, TRAINING_CYCLE_SECONDS - (now - commander.training_cycle_started_unix))
		var remaining_days: float = remaining_seconds / 86400.0
		var progress_text: String = _promotion_progress_text(commander.accumulated_xp)

		var label := Label.new()
		label.text = "%s | %s | Faltam ~%.1f dias | XP do ciclo: %d | %s" % [
			commander.commander_name, patente, remaining_days, commander.training_accumulated_xp, progress_text
		]
		label.custom_minimum_size = Vector2(600, 0)
		row.add_child(label)

		var cancel_button := Button.new()
		cancel_button.text = "Cancelar Treinamento"
		cancel_button.pressed.connect(_on_cancel_training_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(cancel_button)

	if _em_treinamento_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante em Treinamento."
		_em_treinamento_container.add_child(empty_label)


func _refresh_enviar(kingdom: Kingdom) -> void:
	_clear_children(_enviar_container)

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
			continue

		var row := HBoxContainer.new()
		_enviar_container.add_child(row)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var label := Label.new()
		label.text = "%s | %s | %s" % [commander.commander_name, patente, commander.faction]
		label.custom_minimum_size = Vector2(400, 0)
		row.add_child(label)

		var button := Button.new()
		button.text = "Enviar para Treinamento"
		button.pressed.connect(_on_send_to_training_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(button)

	if _enviar_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante na Reserva pra enviar."
		_enviar_container.add_child(empty_label)


## "Faltam X XP pra Patente Y" — ou "Patente máxima já alcançada" no
## topo da hierarquia (Lorde-Comandante).
func _promotion_progress_text(accumulated_xp: int) -> String:
	var thresholds: Array[Dictionary] = CommanderCareer.PATENTE_THRESHOLDS
	for i in range(thresholds.size()):
		if accumulated_xp < thresholds[i]["xp"]:
			var missing: int = thresholds[i]["xp"] - accumulated_xp
			return "Faltam %d XP para %s" % [missing, thresholds[i]["patente"]]
	return "Patente máxima já alcançada"


func _clear_children(container: Node) -> void:
	# Remoção IMEDIATA (não queue_free): esta tela reconstrói a árvore
	# inteira sincronamente a cada refresh() — queue_free() só remove no
	# fim do frame, o que deixaria nós antigos e novos coexistindo até lá
	# (encontrado num teste que checava se algo tinha sumido da lista).
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_cancel_training_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_reserve(KingdomState.kingdom, commander)
	refresh()


func _on_send_to_training_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_training(KingdomState.kingdom, commander, GameClock.now_unix())
	refresh()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
