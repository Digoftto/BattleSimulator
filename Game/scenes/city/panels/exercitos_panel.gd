extends Control
## ExercitosPanel (ARMY.md)
##
## Gerenciamento direto dos Exércitos do Reino — lista os já formados
## (com Desfazer), e "Criar Novo Exército" abre o Editor de verdade
## (painel visual 3x3, `army_editor_panel.tscn`) como overlay. Faltava
## um jeito de chegar nessa tela diretamente pela Cidade — antes só
## era alcançável de dentro do fluxo de "Iniciar Nova Expedição" do
## PvE, sem acesso geral pra editar Exércitos fora desse contexto.

var _root_vbox: VBoxContainer
var _armies_container: VBoxContainer
var _editor_overlay: ArmyEditorPanel = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[ExercitosPanel] Pronto. Exércitos no Reino: %d" % KingdomState.kingdom.armies.size())


func refresh() -> void:
	GameRuntime.sync(KingdomState.kingdom, GameClock.now_unix())
	_clear_children(self)
	_build_static_structure()


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
	title.text = "Exércitos"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	var create_button := Button.new()
	create_button.text = "Criar Novo Exército"
	create_button.disabled = _editor_overlay != null
	create_button.pressed.connect(_on_create_army_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(create_button)

	var separator := HSeparator.new()
	_root_vbox.add_child(separator)

	_armies_container = VBoxContainer.new()
	_armies_container.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(_armies_container)
	_refresh_armies_list()


func _refresh_armies_list() -> void:
	_clear_children(_armies_container)

	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.armies.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum Exército formado ainda."
		_armies_container.add_child(empty_label)
		return

	for army: Army in kingdom.armies:
		var row := HBoxContainer.new()
		_armies_container.add_child(row)

		var card_names: Array[String] = []
		for card: CardResource in army.cards:
			card_names.append(card.card_name)

		var label := Label.new()
		label.text = "%s | %s" % [
			army.commander.commander_name if army.commander != null else "(sem Comandante)",
			", ".join(card_names)
		]
		label.custom_minimum_size = Vector2(550, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(label)

		var lock: Dictionary = KingdomState.kingdom.is_army_locked_for_editing(army)
		var edit_button := Button.new()
		edit_button.text = "Editar Exército" if not lock["locked"] else "Editar Exército (travado: %s)" % lock["reason"]
		edit_button.disabled = _editor_overlay != null or lock["locked"]
		edit_button.pressed.connect(_on_edit_army_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(edit_button)

		var disband_button := Button.new()
		disband_button.text = "Desfazer" if not lock["locked"] else "Desfazer (travado: %s)" % lock["reason"]
		disband_button.disabled = _editor_overlay != null or lock["locked"]
		disband_button.pressed.connect(_on_disband_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(disband_button)


## O overlay do Editor de Exército NUNCA é tocado aqui — sua liberação
## é sempre gerenciada pelos métodos próprios (_finish_army_creation),
## nunca por essa limpeza genérica. Sem essa exceção, qualquer ação
## que chame refresh() enquanto o Editor está aberto por cima (ex:
## "Desfazer" numa Fileira, já que o overlay não bloqueia o resto da
## tela) tentaria liberar o Editor no meio da própria execução dele —
## erro real encontrado testando: "Object was freed or unreferenced
## while a signal is being emitted from it".
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		if child == _editor_overlay:
			continue
		container.remove_child(child)
		child.free()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")


func _on_create_army_pressed() -> void:
	if _editor_overlay != null:
		return

	_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_editor_overlay.formation_count = 1
	_editor_overlay.army_ready.connect(_on_army_ready)
	_editor_overlay.cancelled.connect(_on_army_editor_cancelled)
	add_child(_editor_overlay)


## Abre o Editor já na Fase 1, pré-preenchido com o Comandante e as
## Cartas atuais do Exército — permite trocar a composição de verdade
## (não só as Formações, isso já existia em "Editar Formações" no PvE).
func _on_edit_army_pressed(army: Army) -> void:
	if _editor_overlay != null:
		return

	_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_editor_overlay.existing_army = army
	_editor_overlay.editing_composition = true
	_editor_overlay.formation_count = 5
	_editor_overlay.army_ready.connect(_on_army_ready)
	_editor_overlay.cancelled.connect(_on_army_editor_cancelled)
	add_child(_editor_overlay)


## Conectado por MÉTODO NOMEADO, nunca lambda — lambdas do GDScript
## capturam variáveis locais por valor, nunca alcançam de volta o
## estado do objeto (mesmo aviso já registrado em army_editor_panel.gd).
## Adiado por inteiro (não só o queue_free) — o overlay ainda está no
## meio da própria execução (_on_montar_pressed -> army_ready.emit())
## quando este sinal chega até aqui; remove_child()/refresh() também
## precisam esperar esse frame terminar, não só a liberação em si.
func _on_army_ready(_army: Army) -> void:
	call_deferred("_finish_army_creation")


func _finish_army_creation() -> void:
	if _editor_overlay != null:
		remove_child(_editor_overlay)
		_editor_overlay.queue_free()
		_editor_overlay = null
	refresh()


func _on_disband_pressed(army: Army) -> void:
	KingdomState.kingdom.disband_army(army)
	refresh()


func _on_army_editor_cancelled() -> void:
	call_deferred("_finish_army_creation")
