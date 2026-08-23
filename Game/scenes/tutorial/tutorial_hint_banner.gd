class_name TutorialHintBanner
extends PanelContainer
## TutorialHintBanner (TUT-001)
##
## Banner curto e não-bloqueante, reutilizado pelas poucas telas reais
## que compõem o tutorial mínimo do loop principal (Cidade, Exércitos,
## PvE) — mesmo espírito do painel contextual já usado em CityPanel
## (texto curto + botão "Continuar"), nunca um Popup/modal: some sozinho
## ao ser dispensado e nunca desabilita os controles da tela por baixo
## (ocupa só a faixa superior, sem cobrir o resto da tela).
##
## Árvore em código, sem cena própria — mesmo padrão de todos os outros
## painéis do projeto. Quem instancia chama setup(...) e conecta
## "continue_pressed" ANTES de add_child() (mesmo padrão de configuração
## pré-árvore já usado por ArmyEditorPanel.formation_count/existing_army).

signal continue_pressed


func setup(title_text: String, body_text: String, step_text: String) -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 24
	offset_right = -24
	offset_top = 12
	offset_bottom = 12  # altura real vem do tamanho mínimo do conteúdo (Godot nunca encolhe abaixo disso), não deste valor

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var title_label := Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_label)

	var step_label := Label.new()
	step_label.text = step_text
	header_row.add_child(step_label)

	var body_label := Label.new()
	body_label.text = body_text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(body_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(button_row)

	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.pressed.connect(_on_continue_pressed, CONNECT_DEFERRED)
	button_row.add_child(continue_button)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
