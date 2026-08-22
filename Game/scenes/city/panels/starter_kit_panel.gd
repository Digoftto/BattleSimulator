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
## F-030: usa INICIALIZAÇÃO.png (arte oficial do MVP) como composição
## visual — mesmo padrão já estabelecido em CityPanel/City.png (F-023/
## F-025): AspectRatioContainer + TextureRect (STRETCH_SCALE +
## EXPAND_IGNORE_SIZE) preservando a proporção 1536x1024, com 3
## hitboxes invisíveis ancoradas por fração sobre os botões "Escolher
## X" já desenhados na própria imagem.
##
## A arte é composição visual, NUNCA fonte de dados (F-030 §3): o
## roster de cada Facção mostrado na imagem é texto fixo, dado
## conferido carta-a-carta contra o catálogo real e mantido
## EXATAMENTE igual ao StarterKitResolver.STARTER_ROSTER_CARD_NAMES
## (fonte canônica) por um teste de regressão dedicado
## (test_starter_kit_faction_composition.gd) — se algum dia esse
## roster mudar no código sem a arte ser re-exportada, o teste falha
## alto em vez de a tela mentir silenciosamente pro jogador. Nenhum
## texto de carta é lido da imagem nem gerado dinamicamente aqui.
##
## Conectar "kit_chosen" por MÉTODO NOMEADO, nunca lambda — lambdas do
## GDScript capturam variáveis locais por valor, nunca alcançam de
## volta o estado do objeto (confirmado com execução real, ver aviso
## em army_editor_panel.gd).

signal kit_chosen

## Cópia byte-idêntica de Assets/MVP/INICIALIZAÇÃO.png trazida para
## dentro da árvore do projeto (mesmo motivo de Game/assets/art/City.png,
## F-025: preload() via res:// funciona também numa build exportada,
## nunca depende de caminho absoluto do sistema de arquivos).
const STARTER_TEXTURE: Texture2D = preload("res://assets/art/INICIALIZAÇÃO.png")
const STARTER_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

## Fração (0.0-1.0) do retângulo dos 3 botões "Escolher X" já
## desenhados na imagem, na ordem em que aparecem
## (StarterKitResolver.FACTIONS) — calibrado por inspeção direta da
## imagem, mesmo método já usado em CityPanel.BUILDING_REGIONS
## (F-022/F-023).
const CHOICE_BUTTON_REGIONS: Array[Rect2] = [
	Rect2(0.049, 0.870, 0.283, 0.060),  # Império
	Rect2(0.367, 0.870, 0.283, 0.060),  # Natureza
	Rect2(0.657, 0.870, 0.283, 0.060),  # Mortos-Vivos
]

var _options: Array[Dictionary] = []


func _ready() -> void:
	_options = StarterKitResolver.generate_options(GameDatabase.cards)
	_build_static_structure()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var image_area := Control.new()
	image_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(image_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = STARTER_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	image_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = STARTER_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	for i in range(_options.size()):
		texture_rect.add_child(_build_hitbox(i, _options[i]))


func _build_hitbox(index: int, option: Dictionary) -> Control:
	var rect: Rect2 = CHOICE_BUTTON_REGIONS[index]

	var hitbox := Control.new()
	hitbox.name = "Hitbox_%s" % option["faction"]
	hitbox.anchor_left = rect.position.x
	hitbox.anchor_top = rect.position.y
	hitbox.anchor_right = rect.position.x + rect.size.x
	hitbox.anchor_bottom = rect.position.y + rect.size.y
	hitbox.offset_left = 0
	hitbox.offset_top = 0
	hitbox.offset_right = 0
	hitbox.offset_bottom = 0
	hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hitbox.tooltip_text = "Escolher %s" % option["faction"]
	hitbox.gui_input.connect(_on_hitbox_gui_input.bind(option))
	return hitbox


func _on_hitbox_gui_input(event: InputEvent, option: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_choose_pressed(option)


func _on_choose_pressed(option: Dictionary) -> void:
	StarterKitResolver.choose_option(KingdomState.kingdom, option, GameClock.now_unix())
	kit_chosen.emit()
