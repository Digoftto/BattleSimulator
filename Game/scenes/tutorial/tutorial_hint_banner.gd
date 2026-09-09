class_name TutorialHintBanner
extends Control
## TutorialHintBanner (TUT-001)
##
## Caixa curta e não-bloqueante, reutilizada pelas poucas telas reais
## que compõem o tutorial mínimo do loop principal (Cidade, Exércitos,
## PvE) — texto curto + botão "Continuar", nunca um Popup/modal: some
## sozinha ao ser dispensada e nunca desabilita os controles da tela
## por baixo (ocupa só uma faixa perto do topo, sem cobrir o resto da
## tela).
##
## Moldura visual: Assets/MVP/Construções/"Caixa de texto Tutorial.png"
## (cópia byte-idêntica em Game/assets/art/tutorial_frame.png — mesmo
## motivo de todo asset externo trazido pro projeto: preload() via
## res:// funciona também numa build exportada). AspectRatioContainer
## (STRETCH_FIT, nunca corta a arte, sempre visível por inteiro — ver
## FRAME_ASPECT_RATIO) preserva a proporção 1774x887 da moldura em
## qualquer resolução; o texto/botão ficam dentro da área "segura"
## calibrada por inspeção de pixels (INTERIOR_RECT — fração do
## preenchimento azul-marinho interno da própria arte, evitando a
## moldura dourada/colunas/banners/cantos).
##
## Árvore em código, sem cena própria — mesmo padrão de todos os outros
## painéis do projeto. Quem instancia chama setup(...) e conecta
## "continue_pressed" ANTES de add_child() (mesmo padrão de configuração
## pré-árvore já usado por ArmyEditorPanel.formation_count/existing_army).

signal continue_pressed

const FRAME_TEXTURE: Texture2D = preload("res://assets/art/tutorial_frame.png")
const FRAME_IMAGE_SIZE: Vector2 = Vector2(1774.0, 887.0)
const FRAME_ASPECT_RATIO: float = 1774.0 / 887.0

## Área interna segura pro texto (fração da imagem 1774x887), calibrada
## por detecção do preenchimento azul-marinho sólido da própria arte
## (mesmo método já usado nos pop-ups da Capital) + uma margem extra de
## ~2% em cada borda pra nunca encostar nos cantos arredondados da
## moldura dourada.
const INTERIOR_RECT: Rect2 = Rect2(0.1045, 0.2703, 0.7932, 0.5012)

## Teto de altura (px) da caixa — determina, junto de FRAME_ASPECT_RATIO,
## a largura máxima (2x isso). Abaixo desse teto a caixa preenche a
## largura disponível da tela (menos as margens); acima, o
## AspectRatioContainer(STRETCH_FIT) simplesmente centraliza a moldura
## no tamanho máximo, sem nunca distorcer a proporção.
const FRAME_HEIGHT_BUDGET: float = 420.0

## Mesmo arquivo de fonte já incorporado ao projeto (Cinzel-SemiBold —
## ver capital_panel.gd/city_panel.gd) — texto sobre uma moldura
## ornamentada precisa do mesmo contorno/sombra já usados nesses outros
## lugares pra continuar legível contra o preenchimento azul-marinho da
## arte (a caixa antiga usava a fonte padrão do Godot sobre um painel
## neutro; a arte nova exige o mesmo tratamento tipográfico já
## padronizado no resto do jogo — pedido §7, "deve parecer que sempre
## pertenceu à interface").
const HINT_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HINT_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HINT_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HINT_OUTLINE_SIZE: int = 4
const HINT_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HINT_SHADOW_OFFSET: int = 2

const TITLE_FONT_SIZE: int = 18
const STEP_FONT_SIZE: int = 13
const BODY_FONT_SIZE: int = 15

var _frame_area: Control
var _body_label: Label


func setup(title_text: String, body_text: String, step_text: String) -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 24
	offset_right = -24
	offset_top = 12
	offset_bottom = 12 + FRAME_HEIGHT_BUDGET
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_frame_area = Control.new()
	_frame_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = FRAME_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_area.add_child(aspect)

	var frame_texture_rect := TextureRect.new()
	frame_texture_rect.texture = FRAME_TEXTURE
	frame_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(frame_texture_rect)

	var interior := Control.new()
	interior.anchor_left = INTERIOR_RECT.position.x
	interior.anchor_top = INTERIOR_RECT.position.y
	interior.anchor_right = INTERIOR_RECT.position.x + INTERIOR_RECT.size.x
	interior.anchor_bottom = INTERIOR_RECT.position.y + INTERIOR_RECT.size.y
	interior.offset_left = 0.0
	interior.offset_top = 0.0
	interior.offset_right = 0.0
	interior.offset_bottom = 0.0
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_texture_rect.add_child(interior)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_row)

	var title_label := _make_hint_label(title_text, TITLE_FONT_SIZE)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_label)

	var step_label := _make_hint_label(step_text, STEP_FONT_SIZE)
	header_row.add_child(step_label)

	_body_label = _make_hint_label(body_text, BODY_FONT_SIZE)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(button_row)

	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.pressed.connect(_on_continue_pressed, CONNECT_DEFERRED)
	button_row.add_child(continue_button)


func _make_hint_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HINT_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", HINT_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HINT_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HINT_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HINT_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HINT_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HINT_SHADOW_OFFSET)
	return label


func _on_continue_pressed() -> void:
	continue_pressed.emit()
