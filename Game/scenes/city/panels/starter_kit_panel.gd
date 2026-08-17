class_name StarterKitPanel
extends Control
## StarterKitPanel (COMMAND_CENTER_RECRUITMENT.md, "Kit Inicial do
## Reino")
##
## Mostrado uma única vez, antes de qualquer outro conteúdo da Cidade
## — 3 opções (uma por Facção), o jogador escolhe uma, as outras duas
## são descartadas. Emite "kit_chosen" quando a escolha é efetivada,
## pra quem instanciou (CityPanel) saber que pode seguir para a tela
## normal.
##
## Conectar "kit_chosen" por MÉTODO NOMEADO, nunca lambda — lambdas do
## GDScript capturam variáveis locais por valor, nunca alcançam de
## volta o estado do objeto (confirmado com execução real, ver aviso
## em army_editor_panel.gd).

signal kit_chosen

var _root_vbox: VBoxContainer
var _options: Array[Dictionary] = []


func _ready() -> void:
	_options = StarterKitResolver.generate_options(GameDatabase.cards)
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
	title.text = "Escolha seu Comandante inicial"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Você recebe uma destas 3 opções — uma por Facção. As outras duas são descartadas e nunca mais aparecem."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(subtitle)

	for option: Dictionary in _options:
		_build_option_panel(option)


func _build_option_panel(option: Dictionary) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)

	var panel := PanelContainer.new()
	_root_vbox.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var commander: CommanderResource = option["commander"]
	var header := Label.new()
	header.text = "%s | Comandante: %s (Recruta, sem Doutrina)" % [option["faction"], commander.commander_name]
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	var card_names: Array[String] = []
	for card: CardResource in option["cards"]:
		card_names.append(card.card_name)
	var cards_label := Label.new()
	cards_label.text = "Exército: %s" % ", ".join(card_names)
	cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(cards_label)

	var choose_button := Button.new()
	choose_button.text = "Escolher %s" % option["faction"]
	choose_button.pressed.connect(_on_choose_pressed.bind(option), CONNECT_DEFERRED)
	vbox.add_child(choose_button)


func _on_choose_pressed(option: Dictionary) -> void:
	StarterKitResolver.choose_option(KingdomState.kingdom, option, GameClock.now_unix())
	kit_chosen.emit()
