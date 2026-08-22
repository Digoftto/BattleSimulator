extends Control
## CommandCenterPanel (F-017, COMMAND_CENTER_UI.md)
##
## Submenu de navegação do Centro de Comando — a Cidade encaminha para
## cá em vez de listar Comandantes/Exércitos/Treinamento/Legado/PvE/
## PvP/Minas como irmãos soltos. Nenhuma lógica de gameplay nova: só
## encaminha para as 7 cenas já existentes, mesmo padrão de navegação
## (change_scene_to_file) já usado em toda a árvore de telas do jogo.

const PANEL_SCENES: Dictionary = {
	"Comandantes": "res://scenes/command_center/panels/comandantes_panel.tscn",
	"Exércitos": "res://scenes/city/panels/exercitos_panel.tscn",
	"Treinamento": "res://scenes/command_center/panels/treinamento_panel.tscn",
	"Legado": "res://scenes/command_center/panels/legado_panel.tscn",
	"PvE": "res://scenes/command_center/panels/pve_panel.tscn",
	"PvP": "res://scenes/command_center/panels/pvp_panel.tscn",
	"Minas": "res://scenes/command_center/panels/minas_panel.tscn",
}


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root_vbox := VBoxContainer.new()
	root_vbox.custom_minimum_size = Vector2(600, 0)
	root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(root_vbox)

	var title := Label.new()
	title.text = "Centro de Comando"
	title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	root_vbox.add_child(back_button)

	var nav_title := Label.new()
	nav_title.text = "Ir para:"
	root_vbox.add_child(nav_title)
	var nav_row := HBoxContainer.new()
	root_vbox.add_child(nav_row)
	for panel_name: String in PANEL_SCENES:
		var button := Button.new()
		button.text = panel_name
		button.pressed.connect(_on_navigate_pressed.bind(panel_name), CONNECT_DEFERRED)
		nav_row.add_child(button)


func _on_navigate_pressed(panel_name: String) -> void:
	get_tree().change_scene_to_file.call_deferred(PANEL_SCENES[panel_name])


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
