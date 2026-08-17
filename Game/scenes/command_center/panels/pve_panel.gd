extends Control
## PvEPanel (COMMAND_CENTER_UI.md, "Janela: PvE")
##
## Lista as Expedições ativas do Reino (kingdom.active_expeditions) —
## Squad (Exércitos, Energia, Ordem de Substituição), Fase atual,
## decisão de Acampamento. Mesmo padrão das demais janelas: árvore em
## código, sem estado próprio, reconstruída a cada ação.
##
## Também permite iniciar uma Expedição nova: escolher Território/Trilha,
## montar um Squad usando o Editor de Exército comum (aberto como
## overlay — ver _on_add_army_to_new_expedition_pressed()) e iniciar a
## Expedição de verdade via Kingdom.start_expedition() (COMMAND_CENTER_UI.md,
## "Montagem e Edição do Squad").

var _root_vbox: VBoxContainer
var _expedicoes_container: VBoxContainer

var _new_expedition_territories: Array[Territory] = []
var _new_expedition_territory: Territory = null
var _pending_squad_armies: Array[Army] = []
var _army_editor_overlay: ArmyEditorPanel = null
var _nova_expedicao_status_label: Label
var _existing_armies_container: VBoxContainer
var _nova_expedicao_iniciar_button: Button


var _loading_label: Label = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_show_loading_indicator()
	await get_tree().process_frame
	await get_tree().process_frame

	WorldBootstrap.ensure_world_loaded()
	_hide_loading_indicator()

	_build_static_structure()
	refresh()
	print("[PvEPanel] Pronto. Expedições ativas: %d" % KingdomState.kingdom.active_expeditions.size())


func _show_loading_indicator() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.name = "LoadingBackground"
	add_child(background)

	_loading_label = Label.new()
	_loading_label.text = "Carregando o Mundo... (só na primeira vez — gera o conteúdo da Temporada)"
	_loading_label.set_anchors_preset(Control.PRESET_CENTER)
	_loading_label.add_theme_font_size_override("font_size", 20)
	add_child(_loading_label)


func _hide_loading_indicator() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_loading_label = null


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
	title.text = "PvE"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	_expedicoes_container = VBoxContainer.new()
	_expedicoes_container.add_theme_constant_override("separation", 16)
	_root_vbox.add_child(_expedicoes_container)

	# --- Iniciar Nova Expedição ---
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var nova_title := Label.new()
	nova_title.text = "Iniciar Nova Expedição"
	nova_title.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(nova_title)

	var territory_row := HBoxContainer.new()
	_root_vbox.add_child(territory_row)
	var territory_label := Label.new()
	territory_label.text = "Território:"
	territory_row.add_child(territory_label)
	var territory_option := OptionButton.new()
	var season: Season = WorldDatabase.get_current_season()
	if season != null:
		_new_expedition_territories = []
		for territory: Territory in season.territories.values():
			_new_expedition_territories.append(territory)
		for i in range(_new_expedition_territories.size()):
			territory_option.add_item(_new_expedition_territories[i].id, i)
		if not _new_expedition_territories.is_empty():
			_new_expedition_territory = _new_expedition_territories[0]
	territory_option.item_selected.connect(_on_new_expedition_territory_selected, CONNECT_DEFERRED)
	territory_row.add_child(territory_option)

	_nova_expedicao_status_label = Label.new()
	_root_vbox.add_child(_nova_expedicao_status_label)

	# Exércitos já formados (Kit Inicial, "Exércitos" na Cidade, etc.)
	# — sem isso, uma vez que o único Comandante do jogador já lidera
	# um Exército existente, não sobrava ninguém livre pra montar um
	# novo aqui, e a tela ficava vazia sem explicação.
	_existing_armies_container = VBoxContainer.new()
	_root_vbox.add_child(_existing_armies_container)

	var nova_action_row := HBoxContainer.new()
	_root_vbox.add_child(nova_action_row)
	var add_army_button := Button.new()
	add_army_button.text = "Criar Novo Exército pro Squad"
	add_army_button.disabled = _army_editor_overlay != null
	add_army_button.pressed.connect(_on_add_army_to_new_expedition_pressed, CONNECT_DEFERRED)
	nova_action_row.add_child(add_army_button)

	_nova_expedicao_iniciar_button = Button.new()
	_nova_expedicao_iniciar_button.text = "Iniciar Expedição"
	_nova_expedicao_iniciar_button.pressed.connect(_on_start_new_expedition_pressed, CONNECT_DEFERRED)
	nova_action_row.add_child(_nova_expedicao_iniciar_button)

	_refresh_existing_armies_list()


## Lista os Exércitos já formados que ainda não foram adicionados ao
## Squad pendente — "Usar" adiciona direto, sem passar pelo Editor.
func _refresh_existing_armies_list() -> void:
	_clear_children(_existing_armies_container)

	var eligible_armies: Array[Army] = []
	for army: Army in KingdomState.kingdom.armies:
		if not _pending_squad_armies.has(army):
			eligible_armies.append(army)

	if eligible_armies.is_empty():
		return

	var label := Label.new()
	label.text = "Exércitos já formados (Editor > Exércitos, na Cidade):"
	_existing_armies_container.add_child(label)

	for army: Army in eligible_armies:
		var row := HBoxContainer.new()
		_existing_armies_container.add_child(row)

		var card_names: Array[String] = []
		for card: CardResource in army.cards:
			card_names.append(card.card_name)
		var army_label := Label.new()
		army_label.text = "%s | %s" % [
			army.commander.commander_name if army.commander != null else "(sem Comandante)", ", ".join(card_names)
		]
		army_label.custom_minimum_size = Vector2(500, 0)
		army_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(army_label)

		# ARMY.md, "Trava de Edição por Modo de Jogo": um Exército já
		# comprometido em outra Expedição (ou Guarnição de Mina) em
		# andamento não pode ser designado a uma Expedição nova — mesmo
		# predicado e mesmo padrão de UI já usados em exercitos_panel.gd.
		var lock: Dictionary = KingdomState.kingdom.is_army_locked_for_editing(army)

		var use_button := Button.new()
		use_button.text = "Usar no Squad" if not lock["locked"] else "Usar no Squad (travado: %s)" % lock["reason"]
		use_button.disabled = _army_editor_overlay != null or lock["locked"]
		use_button.pressed.connect(_on_use_existing_army_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(use_button)

		var edit_formations_button := Button.new()
		edit_formations_button.text = "Editar Formações"
		edit_formations_button.disabled = _army_editor_overlay != null
		edit_formations_button.pressed.connect(_on_edit_formations_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(edit_formations_button)


## ARMY.md, "Arquétipos de Formação": abre o Editor direto na Fase de
## Formações (α já existe, β-ε já foram geradas na criação do
## Exército) — nunca a Fase 1, já que Comandante e Cartas não mudam
## aqui, só a Formação.
func _on_edit_formations_pressed(army: Army) -> void:
	if _army_editor_overlay != null:
		return
	_army_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_army_editor_overlay.existing_army = army
	_army_editor_overlay.army_ready.connect(_on_edit_formations_army_ready, CONNECT_DEFERRED)
	_army_editor_overlay.cancelled.connect(_on_new_expedition_army_editor_cancelled, CONNECT_DEFERRED)
	add_child(_army_editor_overlay)


## Diferente de _on_new_expedition_army_ready: editar Formações de um
## Exército já existente NUNCA deve adicioná-lo ao Squad pendente
## sozinho — o jogador ainda escolhe isso separadamente, com "Usar no
## Squad".
func _on_edit_formations_army_ready(_army: Army) -> void:
	call_deferred("_finish_new_expedition_army", null)


func _on_use_existing_army_pressed(army: Army) -> void:
	_pending_squad_armies.append(army)
	refresh()


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())
	_clear_children(_expedicoes_container)
	_refresh_nova_expedicao_status()
	_refresh_existing_armies_list()

	for expedition: ExpeditionRuntime in kingdom.active_expeditions:
		var panel := PanelContainer.new()
		_expedicoes_container.add_child(panel)
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)

		var header := Label.new()
		header.text = "Território: %s | Fase %d de %d | Status: %s" % [
			expedition.territory.id, expedition.current_fase, expedition.trilha.total_fases(), _status_name(expedition.status)
		]
		header.add_theme_font_size_override("font_size", 16)
		vbox.add_child(header)

		_build_squad_rows(vbox, expedition)

		if expedition.is_waiting_at_acampamento:
			var wait_label := Label.new()
			wait_label.text = "Aguardando decisão no Acampamento (Fase %d)." % expedition.current_fase
			vbox.add_child(wait_label)

			var resume_button := Button.new()
			resume_button.text = "Continuar"
			resume_button.pressed.connect(_on_resume_pressed.bind(expedition), CONNECT_DEFERRED)
			vbox.add_child(resume_button)
		elif expedition.status == ExpeditionRuntime.Status.EM_ANDAMENTO:
			var attempt_button := Button.new()
			attempt_button.text = "Tentar Fase Atual"
			attempt_button.pressed.connect(_on_attempt_fase_pressed.bind(expedition), CONNECT_DEFERRED)
			vbox.add_child(attempt_button)
		else:
			var ended_label := Label.new()
			ended_label.text = "Expedição encerrada."
			vbox.add_child(ended_label)

	if _expedicoes_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma Expedição em andamento. Use 'Iniciar Nova Expedição' abaixo para montar um Squad e partir."
		_expedicoes_container.add_child(empty_label)


func _build_squad_rows(vbox: VBoxContainer, expedition: ExpeditionRuntime) -> void:
	var squad_title := Label.new()
	squad_title.text = "Squad (Ordem de Substituição — editável só na Cidade/Acampamento):"
	vbox.add_child(squad_title)

	var can_reorder: bool = expedition.is_waiting_at_acampamento

	for i in range(expedition.squad.armies.size()):
		var army: Army = expedition.squad.armies[i]
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var marker: String = "-> " if i == expedition.squad.active_index else "   "
		var label := Label.new()
		label.text = "%s%d. %s | Energia: %d/%d" % [marker, i + 1, army.army_name, army.current_energy, army.max_energy]
		label.custom_minimum_size = Vector2(400, 0)
		row.add_child(label)

		var up_button := Button.new()
		up_button.text = "▲"
		up_button.disabled = not can_reorder or i == 0
		up_button.pressed.connect(_on_move_army_pressed.bind(expedition, i, -1), CONNECT_DEFERRED)
		row.add_child(up_button)

		var down_button := Button.new()
		down_button.text = "▼"
		down_button.disabled = not can_reorder or i == expedition.squad.armies.size() - 1
		down_button.pressed.connect(_on_move_army_pressed.bind(expedition, i, 1), CONNECT_DEFERRED)
		row.add_child(down_button)


## O overlay do Editor de Exército NUNCA é tocado aqui — mesmo motivo
## já documentado em exercitos_panel.gd: qualquer ação que chame
## refresh() enquanto o Editor está aberto por cima (ex: "Usar no
## Squad" numa Fileira, já que o overlay não bloqueia o resto da
## tela) tentaria liberar o Editor no meio da própria execução dele.
func _clear_children(container: Node) -> void:
	# Remoção IMEDIATA (não queue_free) — mesmo motivo já documentado
	# nos outros painéis: evita nós antigos e novos coexistindo até o
	# fim do frame.
	for child in container.get_children():
		if child == _army_editor_overlay:
			continue
		container.remove_child(child)
		child.free()


func _status_name(status: ExpeditionRuntime.Status) -> String:
	return ExpeditionRuntime.Status.keys()[status]


func _on_attempt_fase_pressed(expedition: ExpeditionRuntime) -> void:
	expedition.attempt_current_fase()
	refresh()


func _on_resume_pressed(expedition: ExpeditionRuntime) -> void:
	expedition.resume_from_acampamento()
	refresh()


func _on_move_army_pressed(expedition: ExpeditionRuntime, index: int, direction: int) -> void:
	var target: int = index + direction
	if target < 0 or target >= expedition.squad.armies.size():
		return
	var armies: Array[Army] = expedition.squad.armies
	var temp: Army = armies[index]
	armies[index] = armies[target]
	armies[target] = temp
	refresh()


func _refresh_nova_expedicao_status() -> void:
	if _new_expedition_territory == null:
		_nova_expedicao_status_label.text = "Nenhum Território disponível (Mundo ainda não carregou)."
		_nova_expedicao_iniciar_button.disabled = true
		return

	var required: int = Squad.required_size(KingdomState.kingdom.get_territory_completion_count(_new_expedition_territory.id))
	_nova_expedicao_status_label.text = "Squad necessário: %d Exército(s) | Adicionados: %d/%d" % [
		required, _pending_squad_armies.size(), required
	]
	_nova_expedicao_iniciar_button.disabled = _pending_squad_armies.size() != required


func _on_new_expedition_territory_selected(index: int) -> void:
	_new_expedition_territory = _new_expedition_territories[index]
	_pending_squad_armies.clear()
	_refresh_nova_expedicao_status()


## Abre o Editor de Exército como um "overlay" (filho direto desta
## cena, sem trocar de cena) — mais simples e robusto do que passar
## dados entre duas cenas separadas. formation_count=5 porque PvE
## exige as 5 Formações (α a ε), conforme COMMAND_CENTER_UI.md.
func _on_add_army_to_new_expedition_pressed() -> void:
	if _army_editor_overlay != null:
		return  # já tem um Editor aberto

	_army_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_army_editor_overlay.formation_count = 5
	_army_editor_overlay.army_ready.connect(_on_new_expedition_army_ready)
	_army_editor_overlay.cancelled.connect(_on_new_expedition_army_editor_cancelled)
	add_child(_army_editor_overlay)


## Conectado por MÉTODO NOMEADO, não lambda — lambdas do GDScript
## capturam variáveis locais por valor, nunca alcançam de volta o
## estado do objeto (ver aviso em army_editor_panel.gd).
## Adiado por inteiro (não só o queue_free) — mesmo motivo de
## exercitos_panel.gd: o overlay ainda está em execução quando este
## sinal chega até aqui.
func _on_new_expedition_army_ready(army: Army) -> void:
	_pending_squad_armies.append(army)
	call_deferred("_finish_new_expedition_army", army)


func _finish_new_expedition_army(_army: Army) -> void:
	if _army_editor_overlay != null:
		remove_child(_army_editor_overlay)
		_army_editor_overlay.queue_free()
		_army_editor_overlay = null
	refresh()


func _on_new_expedition_army_editor_cancelled() -> void:
	call_deferred("_finish_new_expedition_army", null)


func _on_start_new_expedition_pressed() -> void:
	if _new_expedition_territory == null:
		return

	var kingdom: Kingdom = KingdomState.kingdom
	var required: int = Squad.required_size(kingdom.get_territory_completion_count(_new_expedition_territory.id))
	if _pending_squad_armies.size() != required:
		return

	var season: Season = WorldDatabase.get_current_season()
	var trilha: Trilha = season.get_trilha(_new_expedition_territory.id)

	var squad := Squad.new(_pending_squad_armies.duplicate())
	var expedition := ExpeditionRuntime.new(
		squad, trilha, _new_expedition_territory, season.enemy_catalog, kingdom.regional_commander_registry,
		GameClock.now_unix(), GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	# Kingdom.start_expedition() é o ponto central de entrada — nunca
	# mutar kingdom.active_expeditions direto daqui (ARMY.md, "Trava de
	# Edição por Modo de Jogo": rejeita Exércitos já travados em outra
	# Expedição/Guarnição em andamento). A UI já filtra esses Exércitos em
	# _refresh_existing_armies_list(), mas o domínio nunca confia só nisso.
	var result: Dictionary = kingdom.start_expedition(expedition)
	if not result["success"]:
		_nova_expedicao_status_label.text = "Não foi possível iniciar: %s" % result["reason"]
		return

	_pending_squad_armies.clear()
	refresh()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
