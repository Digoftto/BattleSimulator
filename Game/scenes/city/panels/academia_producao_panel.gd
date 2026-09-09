extends Control
## AcademiaProducaoPanel (ACADEMY.md, "Salão dos Artífices")
##
## Tela própria (nunca popup) — usa EXCLUSIVAMENTE academia_artifice.png
## (arte-template FINAL, 1536x1024, painéis em branco dedicados: Lista
## de Cartas/Artífices/Fila de Tarefas não têm molduras internas
## pré-desenhadas — a lista rolável real é construída inteira dentro
## de cada painel). Todas as regiões abaixo foram calibradas por
## detecção de cor (varredura da borda dourada característica das
## caixas da arte) — ver relatório da tarefa. ESCOPO DESTA TAREFA:
## somente este arquivo — academia_aprimoramento_panel.gd (Salão dos
## Metamorfos) não foi tocado.
##
## NENHUMA regra de Produção foi reescrita: toda a lógica usa
## exclusivamente AcademyResolver/AcademyEconomy, igual antes.
##
## Arte real das Cartas: reaproveita CardArtCatalog/BattleCardView — o
## MESMO sistema já usado pela Biblioteca/Bestiário (nunca uma segunda
## fonte de dados) — mas só para UM slot por vez (Carta Selecionada e
## Preview). A Lista de Cartas é uma lista de SELEÇÃO por nome (sem
## BattleCardView/thumbnail nas linhas — ver _populate_lista_cartas
## para o porquê, também a causa da lentidão de entrada corrigida
## nesta etapa); clicar na Carta Selecionada abre uma visão ampliada
## temporária (overlay sobre a própria tela, nunca uma tela nova) que
## fecha ao clicar fora.
##
## Dropdowns de Tipo/Raridade: o tema PADRÃO do OptionButton do Godot
## (fundo cinza do sistema) foi substituído por um tema próprio da
## Academia no popup (fundo escuro, borda dourada, fonte Cinzel) — ver
## _themed_popup_menu().

const ACADEMIA_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/academia_artifice.png")
const ACADEMIA_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0
const ACADEMIA_HUB_SCENE: String = "res://scenes/city/panels/academia_panel.tscn"

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## --- Regiões recalibradas por varredura de cor PIXEL A PIXEL sobre
## academia_artifice.png (1536x1024) — cada Rect2 abaixo foi obtida
## detectando a borda dourada/o preenchimento azul-marinho real de
## cada caixa desenhada na arte (nunca "no olho"), ver relatório da
## tarefa "AJUSTE — SALÃO DOS ARTÍFICES". Os valores anteriores tinham
## sido calibrados sobre uma versão diferente da arte e ficaram
## dessincronizados após a atualização do PNG (algumas caixas
## deslocadas em até ~70px / 7% da altura da imagem). ---
const CLOSE_BUTTON: Rect2 = Rect2(0.9570, 0.0137, 0.0345, 0.0518)

const FACCAO_ICON_CENTERS_X: Array[float] = [0.0540, 0.1191, 0.1855, 0.2516]
const FACCAO_ICON_Y: float = 0.2930
const FACCAO_ICON_SIZE: float = 0.0500
## Diâmetro REAL do símbolo circular na arte — medido por detecção de
## cor do anel dourado de cada ícone (~66,5px, um círculo verdadeiro
## em pixels da imagem-fonte 1536x1024) — menor que FACCAO_ICON_SIZE
## de propósito: o hotspot clicável é levemente maior que o símbolo
## (área de clique mais confortável), mas o CÍRCULO DE SELEÇÃO precisa
## acompanhar o diâmetro real do símbolo, não a área de clique.
##
## Duas constantes (largura/altura), nunca uma só: a imagem-fonte NÃO
## é quadrada (1536x1024, proporção 3:2) — um mesmo valor fracionário
## aplicado às duas dimensões (como FACCAO_ICON_SIZE faz pro hotspot,
## onde a forma exata não importa) produziria uma ELIPSE, não um
## círculo, porque a fração X é relativa a 1536 e a fração Y é
## relativa a 1024. 66,5px reais vira frações diferentes em cada eixo.
const FACCAO_RING_WIDTH: float = 0.0433
const FACCAO_RING_HEIGHT: float = 0.0649
const FACCAO_VALUES: Array[String] = ["Império", "Natureza", "Mortos-Vivos", "(todas)"]

const TIPO_DROPDOWN: Rect2 = Rect2(0.0098, 0.3594, 0.1361, 0.0410)
const RARIDADE_DROPDOWN: Rect2 = Rect2(0.1608, 0.3594, 0.1270, 0.0410)
const SEARCH_BOX: Rect2 = Rect2(0.0098, 0.4092, 0.2891, 0.0400)

## Painel em branco — a lista rolável real vive inteira dentro dele.
const LISTA_CARTAS_REGION: Rect2 = Rect2(0.0130, 0.5068, 0.2845, 0.3311)

const CARD_SLOT: Rect2 = Rect2(0.3073, 0.2559, 0.1172, 0.1914)
const CARTA_NOME_BOX: Rect2 = Rect2(0.4401, 0.2783, 0.1882, 0.0361)
const CARTA_FACCAO_BOX: Rect2 = Rect2(0.4401, 0.3467, 0.1882, 0.0342)
const CARTA_TIPO_BOX: Rect2 = Rect2(0.4401, 0.4150, 0.1882, 0.0342)

const QUANTIDADE_MINUS: Rect2 = Rect2(0.3490, 0.5225, 0.0365, 0.0498)
const QUANTIDADE_VALUE: Rect2 = Rect2(0.4023, 0.5283, 0.1569, 0.0420)
const QUANTIDADE_PLUS: Rect2 = Rect2(0.5749, 0.5225, 0.0371, 0.0479)

const ESTRATEGIA_APROVEITAR_RADIO: Rect2 = Rect2(0.3249, 0.6465, 0.0215, 0.0322)
const ESTRATEGIA_PRESERVAR_RADIO: Rect2 = Rect2(0.4733, 0.6465, 0.0215, 0.0322)

const PREVIEW_SLOT: Rect2 = Rect2(0.3197, 0.7471, 0.0371, 0.0791)
const PREVIEW_RESULTADO_BOX: Rect2 = Rect2(0.3646, 0.7822, 0.0742, 0.0352)
const CUSTO_FRAGMENTO_BOX: Rect2 = Rect2(0.4733, 0.7832, 0.0658, 0.0342)
const TEMPO_PRODUCAO_BOX: Rect2 = Rect2(0.5807, 0.7832, 0.0625, 0.0342)

## Painéis inteiros em branco — mesma lógica da Lista de Cartas.
const ARTIFICES_REGION: Rect2 = Rect2(0.6628, 0.2383, 0.3223, 0.3379)
const FILA_REGION: Rect2 = Rect2(0.6628, 0.6240, 0.3223, 0.2129)

const FRAGMENTOS_BOXES: Array[Rect2] = [
	Rect2(0.0840, 0.9121, 0.0762, 0.0410),
	Rect2(0.2311, 0.9121, 0.0801, 0.0410),
	Rect2(0.3822, 0.9121, 0.0885, 0.0410),
]
const FRAGMENTOS_FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

const PRODUZIR_BUTTON: Rect2 = Rect2(0.5098, 0.8613, 0.4740, 0.1025)

## Valores reais dos filtros (dropdown lista TODOS, sem limite de ícone).
const TIPO_VALUES: Array[String] = ["(todas)", "Corpo a Corpo", "À Distância", "Mago", "Suporte", "Barreira", "Máquina de Guerra"]
const RARIDADE_VALUES: Array[String] = ["(todas)", "Comum", "Rara", "Épica", "Lendária"]

## Mensagem visível quando Produzir/Melhorar Fila é rejeitado.
var _action_status_text: String = ""

var _selected_produce_card: CardResource = null
var _produce_quantity: int = 1
var _preserve_inventory: bool = false

var _produce_filter_faction: String = "(todas)"
var _produce_filter_class: String = "(todas)"
var _produce_filter_rarity: String = "(todas)"
var _produce_search_text: String = ""

var _filtered_produce_cards: Array[CardResource] = []
var _lista_cartas_container: VBoxContainer = null

## Visão ampliada temporária da Carta Selecionada (overlay sobre a
## própria tela — nunca uma tela nova). Fecha ao clicar fora.
var _card_zoom_open: bool = false


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[AcademiaProducaoPanel] Pronto. Nível: %d | Artífices: %d" % [
		KingdomState.kingdom.academy_level, KingdomState.kingdom.academy_artifices.size()
	])


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.sync_academy_masters()
	GameRuntime.sync(kingdom, GameClock.now_unix())

	_refresh_filtered_cards()

	_clear_children(self)
	_build_structure(kingdom)


## queue_free(), não free(): quase todo hotspot desta tela (ícones de
## Facção, moldura da Carta Selecionada, +/- de Quantidade, rádios de
## Estratégia, linhas da Lista, botão Produzir, backdrop da carta
## ampliada) chama refresh() de dentro do PRÓPRIO handler de
## "gui_input" — ou seja, quando refresh() -> _clear_children(self)
## roda, o Control que ainda está no meio da emissão do seu próprio
## sinal "gui_input" (mais acima nesta mesma call stack) é um dos
## Nodes sendo limpos aqui. free() destrói o objeto na hora e quebra
## essa emissão em andamento ("Object was freed or unreferenced while
## a signal is being emitted", ver debugger). queue_free() adia a
## destruição real pro fim do frame — o Node continua válido até a
## call stack do sinal atual desenrolar — enquanto remove_child()
## continua acontecendo na hora (evita qualquer visual duplicado com a
## árvore nova que _build_structure() cria em seguida).
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _build_structure(kingdom: Kingdom) -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = ACADEMIA_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ACADEMIA_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_close_button(texture_rect)
	_build_faccao_filter(texture_rect)
	_build_dropdown_filters(texture_rect)
	_build_search_box(texture_rect)
	_build_lista_cartas(texture_rect)
	_build_carta_selecionada(texture_rect)
	_build_quantidade(texture_rect)
	_build_estrategia(texture_rect)

	var preview_result: Dictionary = {}
	if _selected_produce_card != null:
		preview_result = AcademyResolver.preview_production(
			kingdom, _selected_produce_card.card_name, _produce_quantity, _preserve_inventory
		)
	_build_preview(texture_rect, preview_result)

	_build_artifices(texture_rect, kingdom)
	_build_fila(texture_rect, kingdom)
	_build_fragmentos_disponiveis(texture_rect, kingdom)
	_build_produzir_button(texture_rect)

	if _action_status_text != "":
		var status_label := Label.new()
		status_label.text = _action_status_text
		_anchor_control(status_label, Rect2(0.010, 0.985, 0.960, 0.014))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		status_label.clip_text = true
		status_label.add_theme_font_override("font", HUD_FONT)
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", HUD_ERROR_COLOR)
		status_label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
		status_label.add_theme_constant_override("outline_size", 2)
		texture_rect.add_child(status_label)

	if _card_zoom_open and _selected_produce_card != null:
		_build_card_zoom_overlay(_selected_produce_card)


## --- Filtro de Facção (único com correspondência 1:1 exata com
## ícones na arte: 4 ícones = "(todas)" + 3 Facções reais). ---
func _build_faccao_filter(parent: Control) -> void:
	for i in range(FACCAO_ICON_CENTERS_X.size()):
		var value: String = FACCAO_VALUES[i]
		var center_x: float = FACCAO_ICON_CENTERS_X[i]
		var rect := Rect2(center_x - FACCAO_ICON_SIZE / 2.0, FACCAO_ICON_Y, FACCAO_ICON_SIZE, FACCAO_ICON_SIZE)
		var hotspot := _make_hotspot(rect)
		hotspot.gui_input.connect(_on_faccao_gui_input.bind(value))
		parent.add_child(hotspot)
		if _produce_filter_faction == value and value != "(todas)":
			# Mesmo CENTRO do hotspot, mas tamanho/proporção próprios
			# (FACCAO_RING_WIDTH/HEIGHT, o diâmetro real do símbolo em
			# cada eixo) — nunca o rect do hotspot, que é de propósito
			# um pouco maior pra dar folga de clique.
			var ring_rect := Rect2(
				center_x - FACCAO_RING_WIDTH / 2.0,
				FACCAO_ICON_Y + (FACCAO_ICON_SIZE - FACCAO_RING_HEIGHT) / 2.0,
				FACCAO_RING_WIDTH, FACCAO_RING_HEIGHT
			)
			_build_selection_ring(parent, ring_rect)


func _build_selection_ring(parent: Control, rect: Rect2) -> void:
	var ring := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = HUD_ACCENT_SELECTED
	# Godot limita corner_radius ao mínimo entre o valor pedido e a
	# metade do lado da caixa — um valor bem acima de qualquer tamanho
	# real do anel (em qualquer resolução, já que a tela inteira escala
	# via AspectRatioContainer) sempre vira um círculo perfeito, nunca
	# um quadrado arredondado (era 30px fixo antes, menor que o raio
	# real do ícone na maioria das resoluções — por isso o anel parecia
	# "desalinhado": não acompanhava a curva do símbolo).
	const RING_CORNER_RADIUS: int = 999
	style.corner_radius_top_left = RING_CORNER_RADIUS
	style.corner_radius_top_right = RING_CORNER_RADIUS
	style.corner_radius_bottom_left = RING_CORNER_RADIUS
	style.corner_radius_bottom_right = RING_CORNER_RADIUS
	ring.add_theme_stylebox_override("panel", style)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_control(ring, rect)
	parent.add_child(ring)


func _on_faccao_gui_input(event: InputEvent, value: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_produce_filter_faction = "(todas)" if _produce_filter_faction == value else value
		refresh()


## --- Filtros de Tipo/Raridade — a arte já desenha os dois como
## dropdown (moldura + seta "▾"); um OptionButton real ancorado por
## cima lista TODOS os valores reais. Fundo nativo zerado (a moldura
## visível é só a da arte) e o POPUP (a lista que abre ao clicar) usa
## um tema próprio da Academia — nunca o cinza padrão do Godot. ---
func _build_dropdown_filters(parent: Control) -> void:
	var tipo_option := _make_transparent_option_button(TIPO_DROPDOWN)
	for value: String in TIPO_VALUES:
		tipo_option.add_item(value)
	tipo_option.selected = TIPO_VALUES.find(_produce_filter_class)
	tipo_option.item_selected.connect(_on_tipo_selected, CONNECT_DEFERRED)
	parent.add_child(tipo_option)
	_theme_option_popup(tipo_option)

	var raridade_option := _make_transparent_option_button(RARIDADE_DROPDOWN)
	for value: String in RARIDADE_VALUES:
		raridade_option.add_item(value)
	raridade_option.selected = RARIDADE_VALUES.find(_produce_filter_rarity)
	raridade_option.item_selected.connect(_on_raridade_selected, CONNECT_DEFERRED)
	parent.add_child(raridade_option)
	_theme_option_popup(raridade_option)


func _on_tipo_selected(index: int) -> void:
	_produce_filter_class = TIPO_VALUES[index]
	refresh()


func _on_raridade_selected(index: int) -> void:
	_produce_filter_rarity = RARIDADE_VALUES[index]
	refresh()


func _build_search_box(parent: Control) -> void:
	var line_edit := LineEdit.new()
	line_edit.text = _produce_search_text
	_anchor_control(line_edit, SEARCH_BOX)
	var empty_style := StyleBoxEmpty.new()
	empty_style.content_margin_left = 34.0
	line_edit.add_theme_stylebox_override("normal", empty_style)
	line_edit.add_theme_stylebox_override("focus", empty_style)
	line_edit.add_theme_font_override("font", HUD_FONT)
	line_edit.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	line_edit.text_changed.connect(_on_search_text_changed, CONNECT_DEFERRED)
	parent.add_child(line_edit)


func _on_search_text_changed(new_text: String) -> void:
	_produce_search_text = new_text
	_refresh_filtered_cards()
	_rebuild_lista_cartas_only()


## Reconstrói só a lista de Cartas (evita perder o foco/cursor do
## LineEdit de busca a cada tecla digitada).
func _rebuild_lista_cartas_only() -> void:
	if _lista_cartas_container == null:
		return
	_clear_children(_lista_cartas_container)
	_populate_lista_cartas()


func _refresh_filtered_cards() -> void:
	_filtered_produce_cards.clear()
	var search_lower: String = _produce_search_text.to_lower()

	for card: CardResource in GameDatabase.cards:
		if _produce_filter_faction != "(todas)" and card.faction != _produce_filter_faction:
			continue
		if _produce_filter_class != "(todas)" and card.card_class != _produce_filter_class:
			continue
		if _produce_filter_rarity != "(todas)" and card.rarity != _produce_filter_rarity:
			continue
		if search_lower != "" and not card.card_name.to_lower().contains(search_lower):
			continue
		_filtered_produce_cards.append(card)

	if not _filtered_produce_cards.has(_selected_produce_card):
		_selected_produce_card = _filtered_produce_cards[0] if not _filtered_produce_cards.is_empty() else null


## O painel "LISTA DE CARTAS" é uma moldura vazia na arte — a lista
## rolável inteira é construída aqui dentro. Cada linha mostra só o
## NOME da carta (sem BattleCardView/arte) — a lista é uma lista de
## SELEÇÃO (como um menu), não uma grade de miniaturas; a arte real em
## alta definição só é renderizada uma vez, para a Carta Selecionada
## (ver _build_carta_selecionada) e para a Preview. Isso também é o
## que resolve a lentidão de entrada nesta tela: antes, cada linha
## instanciava um BattleCardView completo (CardArtCatalog.cropped_texture_for
## -> load() síncrono de disco por textura, na primeira vez que cada
## carta aparece — o mesmo custo dominante já medido e documentado na
## Biblioteca/Bestiário, ~2s pras 39 texturas), então abrir esta tela
## carregava até 39-40 texturas de carta só pra preencher a lista.
func _build_lista_cartas(parent: Control) -> void:
	var region := Control.new()
	_anchor_control(region, LISTA_CARTAS_REGION)
	parent.add_child(region)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	region.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	_lista_cartas_container = VBoxContainer.new()
	_lista_cartas_container.add_theme_constant_override("separation", 3)
	scroll.add_child(_lista_cartas_container)
	# ScrollContainer NUNCA estica o filho direto pra sua própria largura
	# (confirmado empiricamente, inclusive após frames reais processados)
	# — mesmo com scroll horizontal desabilitado, ele só dá ao filho o
	# tamanho MÍNIMO que o filho já pediria sozinho; desabilitar um eixo
	# só tira a scrollbar/o pan daquele eixo, nunca estica o conteúdo.
	# Como cada linha usa Label.clip_text=true (min width ~0, de
	# propósito, pra truncar em vez de vazar), o VBoxContainer colapsava
	# pra ~27px (só o ponto de raridade + margens) — o nome ficava com
	# ~1px de largura, invisível (confirmado via diagnóstico headless: a
	# linha via caixa continuava 27px mesmo com size_flags EXPAND, que
	# só tem efeito dentro de um BoxContainer pai, nunca dentro de um
	# ScrollContainer). A correção real é forçar a LARGURA MÍNIMA do
	# VBoxContainer pra acompanhar a largura real disponível do scroll
	# (scroll.size.x já responde certo a resize, porque region/margin
	# são dimensionados por âncora/Container normalmente — só o
	# VBoxContainer dentro do ScrollContainer não seguia isso sozinho).
	scroll.resized.connect(_on_lista_cartas_scroll_resized.bind(scroll))
	_on_lista_cartas_scroll_resized(scroll)

	# População da lista é SEPARADA do ajuste de largura, e acontece
	# exatamente 1 vez aqui — nunca dentro de _on_lista_cartas_scroll_resized()
	# (que dispara mais de uma vez por reconstrução conforme o layout
	# real estabiliza; populá-la ali empilhava linhas duplicadas a cada
	# disparo, sem nunca limpar antes).
	_populate_lista_cartas()


## Só ajusta a largura mínima — NUNCA repopula. "resized" dispara mais
## de uma vez por reconstrução (o layout leva alguns frames reais pra
## estabilizar o tamanho final do ScrollContainer — nunca acontece só
## uma vez); chamar _populate_lista_cartas() aqui empilhava um novo
## conjunto de linhas em cima das já existentes a cada disparo, sem
## nunca limpar antes — causa raiz confirmada da duplicação de cartas
## na lista (2x, 3x... dependendo de quantos "resized" disparassem
## antes do layout estabilizar). As linhas já criadas não precisam ser
## recriadas quando a largura muda — o Godot já reflui o conteúdo
## existente sozinho.
func _on_lista_cartas_scroll_resized(scroll: ScrollContainer) -> void:
	if _lista_cartas_container == null or not is_instance_valid(_lista_cartas_container):
		return
	_lista_cartas_container.custom_minimum_size.x = scroll.size.x


## Cor de raridade só como pequeno indicador (ponto) ao lado do nome —
## nunca uma segunda fonte de dado (a String de raridade real continua
## vindo só de CardResource.rarity, aqui só mapeada pra uma cor de UI).
const RARITY_DOT_COLORS: Dictionary = {
	"Comum": Color(0.72, 0.72, 0.70),
	"Rara": Color(0.45, 0.70, 0.95),
	"Épica": Color(0.68, 0.45, 0.90),
	"Lendária": Color(0.95, 0.75, 0.30),
}


func _populate_lista_cartas() -> void:
	const ROW_HEIGHT: float = 26.0

	for card: CardResource in _filtered_produce_cards:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var style := StyleBoxFlat.new()
		var selected: bool = card == _selected_produce_card
		style.bg_color = Color(0.95, 0.80, 0.35, 0.20) if selected else Color(1, 1, 1, 0.04)
		style.border_width_left = 1
		style.border_width_bottom = 1
		style.border_color = HUD_ACCENT_SELECTED if selected else Color(1, 1, 1, 0.10)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		style.content_margin_left = 8.0
		style.content_margin_right = 6.0
		row.add_theme_stylebox_override("panel", style)
		row.gui_input.connect(_on_lista_card_gui_input.bind(card))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(hbox)

		var dot := ColorRect.new()
		dot.color = RARITY_DOT_COLORS.get(card.rarity, HUD_MUTED_COLOR)
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(dot)

		var label := Label.new()
		label.text = card.card_name
		label.add_theme_font_override("font", HUD_FONT)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", HUD_ACCENT_SELECTED if selected else HUD_TEXT_COLOR)
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		_lista_cartas_container.add_child(row)

	if _filtered_produce_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhuma carta encontrada."
		empty_label.add_theme_font_override("font", HUD_FONT)
		empty_label.add_theme_color_override("font_color", HUD_MUTED_COLOR)
		_lista_cartas_container.add_child(empty_label)


func _on_lista_card_gui_input(event: InputEvent, card: CardResource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_produce_card = card
		refresh()


## Carta Selecionada: a moldura já existe na arte (CARD_SLOT) — só a
## arte REAL da carta entra dentro dela (nunca uma segunda moldura).
## Clicar na carta abre a visão ampliada (overlay temporário).
func _build_carta_selecionada(parent: Control) -> void:
	if _selected_produce_card == null:
		return
	var card: CardResource = _selected_produce_card

	var slot := Control.new()
	_anchor_control(slot, CARD_SLOT)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_carta_selecionada_gui_input)
	parent.add_child(slot)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(false)

	_value_label(parent, CARTA_NOME_BOX, card.card_name, 13, HUD_TEXT_COLOR)
	_value_label(parent, CARTA_FACCAO_BOX, card.faction, 13, HUD_TEXT_COLOR)
	_value_label(parent, CARTA_TIPO_BOX, card.card_class, 13, HUD_TEXT_COLOR)


func _on_carta_selecionada_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = true
		refresh()


## Visão ampliada temporária (overlay sobre a própria tela, nunca uma
## tela nova) — fecha ao clicar fora (backdrop) ou de novo na carta.
## Proporção real da carta preservada (BattleCardView.CARD_ASPECT_RATIO,
## nunca deformada).
func _build_card_zoom_overlay(card: CardResource) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_card_zoom_backdrop_gui_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var viewport_size: Vector2 = get_viewport_rect().size
	var enlarged_height: float = viewport_size.y * 0.75
	var enlarged_width: float = enlarged_height * BattleCardView.CARD_ASPECT_RATIO
	if enlarged_width > viewport_size.x * 0.6:
		enlarged_width = viewport_size.x * 0.6
		enlarged_height = enlarged_width / BattleCardView.CARD_ASPECT_RATIO

	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(enlarged_width, enlarged_height)
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	card_slot.gui_input.connect(_on_card_zoom_card_gui_input)
	center.add_child(card_slot)

	var enlarged_view := BattleCardView.new()
	enlarged_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	enlarged_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(enlarged_view)
	enlarged_view.set_card(card)
	enlarged_view.set_stats(card.atk, card.hp, card.esc)
	enlarged_view.set_compact(false)


func _on_card_zoom_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = false
		refresh()


## Clicar na própria carta ampliada também fecha (evita o jogador
## precisar "acertar" a borda fina do backdrop).
func _on_card_zoom_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = false
		refresh()


func _build_quantidade(parent: Control) -> void:
	var minus_hotspot := _make_hotspot(QUANTIDADE_MINUS)
	minus_hotspot.gui_input.connect(_on_quantidade_delta_gui_input.bind(-1))
	parent.add_child(minus_hotspot)

	_value_label(parent, QUANTIDADE_VALUE, str(_produce_quantity), 15, HUD_TEXT_COLOR)

	var plus_hotspot := _make_hotspot(QUANTIDADE_PLUS)
	plus_hotspot.gui_input.connect(_on_quantidade_delta_gui_input.bind(1))
	parent.add_child(plus_hotspot)


func _on_quantidade_delta_gui_input(event: InputEvent, delta: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_produce_quantity = clampi(_produce_quantity + delta, 1, 20)
		refresh()


func _build_estrategia(parent: Control) -> void:
	var aproveitar_hotspot := _make_hotspot(ESTRATEGIA_APROVEITAR_RADIO)
	aproveitar_hotspot.gui_input.connect(_on_estrategia_gui_input.bind(false))
	parent.add_child(aproveitar_hotspot)
	if not _preserve_inventory:
		_build_selection_dot(parent, ESTRATEGIA_APROVEITAR_RADIO)

	var preservar_hotspot := _make_hotspot(ESTRATEGIA_PRESERVAR_RADIO)
	preservar_hotspot.gui_input.connect(_on_estrategia_gui_input.bind(true))
	parent.add_child(preservar_hotspot)
	if _preserve_inventory:
		_build_selection_dot(parent, ESTRATEGIA_PRESERVAR_RADIO)


func _build_selection_dot(parent: Control, rect: Rect2) -> void:
	var dot := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = HUD_ACCENT_SELECTED
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	dot.add_theme_stylebox_override("panel", style)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inset: Rect2 = Rect2(rect.position.x + rect.size.x * 0.25, rect.position.y + rect.size.y * 0.25, rect.size.x * 0.50, rect.size.y * 0.50)
	_anchor_control(dot, inset)
	parent.add_child(dot)


func _on_estrategia_gui_input(event: InputEvent, preserve: bool) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_preserve_inventory = preserve
		refresh()


## --- Preview da Produção (recalculado automaticamente, sem botão
## "Prever" — a arte não desenha um). ---
func _build_preview(parent: Control, preview_result: Dictionary) -> void:
	if preview_result.is_empty():
		return

	if not preview_result["valid"]:
		_value_label(parent, PREVIEW_RESULTADO_BOX, "Previsão inválida: %s" % preview_result["reason"], 11, HUD_ERROR_COLOR)
		return

	var produce_summary: String = ""
	for card_name: String in preview_result["new_cards_to_produce"]:
		produce_summary += "%s x%d " % [card_name, preview_result["new_cards_to_produce"][card_name]]
	if produce_summary == "":
		produce_summary = "reaproveitado do inventário"
	_value_label(parent, PREVIEW_RESULTADO_BOX, produce_summary.strip_edges(), 11, HUD_TEXT_COLOR)

	var cost_color: Color = HUD_ACCENT_SELECTED if not preview_result["affordable"] else HUD_TEXT_COLOR
	_value_label(parent, CUSTO_FRAGMENTO_BOX, "%s: %d" % [preview_result["faction"], preview_result["total_fragment_cost"]], 12, cost_color)

	_value_label(parent, TEMPO_PRODUCAO_BOX, "%ds" % int(preview_result["sequential_time_seconds"]), 12, HUD_TEXT_COLOR)


func _build_artifices(parent: Control, kingdom: Kingdom) -> void:
	var region := Control.new()
	_anchor_control(region, ARTIFICES_REGION)
	parent.add_child(region)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	region.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var masters: Array[AcademyMaster] = kingdom.academy_artifices

	for i in range(masters.size()):
		var master: AcademyMaster = masters[i]
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 22)
		list.add_child(row)

		var task: AcademyTask = master.current_task()
		var status_text: String
		if task == null:
			status_text = "Artífice %d — Ocioso" % (i + 1)
		elif not task.has_started():
			status_text = "Artífice %d — Na fila" % (i + 1)
		else:
			var remaining: int = maxi(0, task.end_unix - GameClock.now_unix())
			status_text = "Artífice %d — %s x%d (~%ds)" % [i + 1, task.target_card_name, task.quantity, remaining]

		var label := Label.new()
		label.text = status_text
		label.add_theme_font_override("font", HUD_FONT)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
		label.clip_text = true
		label.custom_minimum_size = Vector2(1, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var upgrade_button := Button.new()
		upgrade_button.text = "Fila %d/%d ⬆" % [master.queue.size(), master.queue_capacity]
		upgrade_button.tooltip_text = "Melhorar Fila"
		upgrade_button.add_theme_font_size_override("font_size", 10)
		_style_academia_button(upgrade_button)
		upgrade_button.pressed.connect(_on_upgrade_master_queue_pressed.bind(master), CONNECT_DEFERRED)
		row.add_child(upgrade_button)

	if masters.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum Artífice disponível."
		empty_label.add_theme_font_override("font", HUD_FONT)
		empty_label.add_theme_color_override("font_color", HUD_MUTED_COLOR)
		list.add_child(empty_label)


func _build_fila(parent: Control, kingdom: Kingdom) -> void:
	var region := Control.new()
	_anchor_control(region, FILA_REGION)
	parent.add_child(region)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	region.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for master: AcademyMaster in kingdom.academy_artifices:
		for task: AcademyTask in master.queue:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 22)
			list.add_child(row)

			var label := Label.new()
			label.text = "%s x%d (%s)" % [task.target_card_name, task.quantity, "iniciada" if task.has_started() else "na fila"]
			label.add_theme_font_override("font", HUD_FONT)
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
			label.clip_text = true
			label.custom_minimum_size = Vector2(1, 0)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)

			var cancel_button := Button.new()
			cancel_button.text = "X"
			_style_academia_button(cancel_button)
			cancel_button.disabled = task.has_started()
			cancel_button.pressed.connect(_on_cancel_task_pressed.bind(master, task), CONNECT_DEFERRED)
			row.add_child(cancel_button)

	if list.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma tarefa na fila."
		empty_label.add_theme_font_override("font", HUD_FONT)
		empty_label.add_theme_color_override("font_color", HUD_MUTED_COLOR)
		list.add_child(empty_label)


func _build_fragmentos_disponiveis(parent: Control, kingdom: Kingdom) -> void:
	for i in range(FRAGMENTOS_FACTIONS.size()):
		var faction: String = FRAGMENTOS_FACTIONS[i]
		_value_label(parent, FRAGMENTOS_BOXES[i], str(kingdom.get_fragment(faction)), 13, HUD_TEXT_COLOR)


func _build_produzir_button(parent: Control) -> void:
	var hotspot := _make_hotspot(PRODUZIR_BUTTON)
	hotspot.gui_input.connect(_on_produce_gui_input)
	parent.add_child(hotspot)


func _build_close_button(parent: Control) -> void:
	var hotspot := _make_hotspot(CLOSE_BUTTON)
	hotspot.gui_input.connect(_on_back_gui_input)
	parent.add_child(hotspot)


func _on_produce_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _selected_produce_card == null:
		return
	var result: Dictionary = AcademyResolver.request_production(
		KingdomState.kingdom, _selected_produce_card.card_name, _produce_quantity, GameClock.now_unix(), _preserve_inventory
	)
	if not result["success"]:
		print("[AcademiaProducaoPanel] Produzir falhou: %s" % result["reason"])
		_action_status_text = "Não foi possível produzir: %s" % result["reason"]
	else:
		_action_status_text = ""
	refresh()


func _on_upgrade_master_queue_pressed(master: AcademyMaster) -> void:
	var result: Dictionary = AcademyResolver.upgrade_queue_capacity(KingdomState.kingdom, master)
	if not result["success"]:
		print("[AcademiaProducaoPanel] Melhorar Fila falhou: %s" % result["reason"])
		_action_status_text = "Não foi possível melhorar a Fila: %s" % result["reason"]
	else:
		_action_status_text = ""
	refresh()


func _on_cancel_task_pressed(master: AcademyMaster, task: AcademyTask) -> void:
	AcademyResolver.cancel_task(KingdomState.kingdom, master, task)
	refresh()


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(ACADEMIA_HUB_SCENE)


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _make_hotspot(rect: Rect2) -> Control:
	var hotspot := Control.new()
	_anchor_control(hotspot, rect)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return hotspot


func _anchor_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


## OptionButton com fundo/borda nativos zerados — a arte já desenha a
## moldura do dropdown (retângulo + seta "▾"); sem isso o tema padrão
## do Godot desenharia um segundo painel cinza por cima dela.
func _make_transparent_option_button(rect: Rect2) -> OptionButton:
	var option := OptionButton.new()
	_anchor_control(option, rect)
	option.clip_text = true
	# A arte desenha a caixa de Tipo/Raridade com o valor centralizado
	# (a seta "▾" já é desenhada separadamente pelo próprio OptionButton,
	# sempre colada na borda direita DESTE Control — nunca invade a
	# caixa vizinha, já que cada OptionButton está ancorado exatamente
	# ao próprio Rect2, sem sobreposição entre TIPO_DROPDOWN e
	# RARIDADE_DROPDOWN). Sem isto, o alinhamento padrão (esquerda)
	# deixava "(todas)" colado na borda esquerda, com um vão grande até
	# a seta na borda direita — o que lia visualmente como se a seta
	# pertencesse à caixa seguinte.
	option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty_style := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		option.add_theme_stylebox_override(state, empty_style)
	option.add_theme_font_override("font", HUD_FONT)
	option.add_theme_font_size_override("font_size", 13)
	option.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	return option


## Tema do POPUP (a lista que abre ao clicar no dropdown) — fundo
## escuro, borda dourada e fonte Cinzel da Academia, nunca o cinza
## padrão do sistema/Godot.
func _theme_option_popup(option: OptionButton) -> void:
	var popup: PopupMenu = option.get_popup()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.08, 0.97)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = HUD_ACCENT
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	popup.add_theme_stylebox_override("panel", panel_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.28)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	popup.add_theme_stylebox_override("hover", hover_style)

	popup.add_theme_font_override("font", HUD_FONT)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	popup.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	popup.add_theme_color_override("font_separator_color", HUD_ACCENT)
	popup.add_theme_constant_override("item_start_padding", 6)
	popup.add_theme_constant_override("item_end_padding", 6)
	popup.add_theme_constant_override("v_separation", 6)


## Scrollbar dourada da Academia — mesmo padrão já usado na Biblioteca/
## Bestiário (_style_scrollbar), nunca a barra cinza padrão do Godot.
func _style_scrollbar(scroll: ScrollContainer) -> void:
	var v_scroll: VScrollBar = scroll.get_v_scroll_bar()
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	grabber_style.corner_radius_top_left = 4
	grabber_style.corner_radius_top_right = 4
	grabber_style.corner_radius_bottom_left = 4
	grabber_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("grabber", grabber_style)
	var grabber_hover_style: StyleBoxFlat = grabber_style.duplicate()
	grabber_hover_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.9)
	v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover_style)
	v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_hover_style)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	track_style.corner_radius_top_left = 4
	track_style.corner_radius_top_right = 4
	track_style.corner_radius_bottom_left = 4
	track_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("scroll", track_style)


## Reveste um Button nativo (Melhorar Fila / Cancelar) com o mesmo
## vocabulário visual da Academia (fundo escuro, borda dourada, fonte
## Cinzel) — nunca o cinza padrão do Godot, que destoaria da arte.
func _style_academia_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	button.add_theme_color_override("font_disabled_color", HUD_MUTED_COLOR)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 6.0
	normal_style.content_margin_right = 6.0
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.22)
	hover_style.border_color = HUD_ACCENT_SELECTED
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _value_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	_anchor_control(label, rect)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
