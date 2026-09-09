class_name ArmyEditorPanel
extends Control
## ArmyEditorPanel (COMMAND_CENTER_UI.md, "motor de geração de exército
## comum")
##
## RECONSTRUÇÃO (pedido explícito): de um formulário puro (OptionButton
## de Comandante + CheckBox por Carta + dropdown de posição) para um
## "Montador de Exército" visual — moldura "Caixa de texto centro de
## comando_exercito.png" (mesma arte/geometria de exercitos_panel.gd,
## medida por pixel naquela etapa, reaproveitada aqui sem remedir),
## abas COMANDANTE/PELOTÃO na faixa superior, lista/grade com arte real
## + filtros reais na área grande esquerda, e Comandante + Formação 3x3
## (Drag-and-Drop nativo do Godot) sempre visível na coluna direita.
##
## CONTRATO PRESERVADO (bootstrap.gd chama estes campos/métodos
## DIRETO, sem passar pela UI — auditado antes de reescrever, ver
## relatório da tarefa): formation_count, existing_army,
## editing_composition, _commander_option (só .visible), _formations_section
## (só .visible), _formation_cards (Dictionary String -> Array[CardResource]),
## _current_formation, _selected_commander, _selected_cards, _army,
## sinais army_ready/cancelled, e os métodos _on_card_toggled(pressed,card),
## _on_montar_pressed(), _on_slot_card_selected(new_card_index,slot_index),
## _on_concluir_pressed(), _on_cancel_pressed() — todos com o MESMO corpo
## funcional de antes (Kingdom.form_army/re_form_army/disband_army nunca
## tocados). Tudo o mais (_cards_container, _soldo_label, _montar_button,
## _slots_grid, _formation_tabs_row, _concluir_button da versão anterior)
## não é testado por nome — foi livremente redesenhado.
##
## _commander_option agora é o Control que envolve a FAIXA SUPERIOR
## (abas) + a ÁREA GRANDE ESQUERDA (filtros + lista/grade) inteiras —
## escondê-lo (.visible=false) esconde a escolha de Comandante/Cartas
## por completo, exatamente como o modo "só editar Formação" precisa.
## _formations_section agora é a COLUNA DIREITA (retrato+dados do
## Comandante, Soldo do Exército, e a Formação 3x3) — sempre construído
## visível (nenhum teste espera .visible=false nela em nenhum momento).
##
## GAP ENCONTRADO (auditoria desta etapa, ver relatório): não existia
## nenhum componente de Drag-and-Drop em lugar nenhum do projeto.
## Resolvido com os métodos NATIVOS do Godot Control
## (_get_drag_data/_can_drop_data/_drop_data), encapsulados em
## ArmyCardSlot (res://scenes/army/army_card_slot.gd) — uma classe
## puramente mecânica, sem nenhuma regra de Exército/Carta embutida.
##
## Posicionamento ANTES de "Montar"/"Salvar Alterações" é só rascunho
## de UI local (_phase1_slots, 9 posições, nunca chega ao Kingdom).
## "Montar"/"Salvar Alterações" continua sendo a ÚNICA ação que de fato
## grava no Reino (Kingdom.form_army()/re_form_army(), EXATAMENTE como
## antes — nunca chamado a cada arrasto). O rascunho só decide a ORDEM
## inicial de "α" (_formation_cards["α"]) no momento do commit — nunca
## os objetos CardResource passados a form_army()/re_form_army(), que
## continuam sendo _selected_cards.duplicate(), byte-a-byte como antes.
##
## Layout de posição (COMBAT_RULES.md, "Campo de Batalha") — nunca
## alterado:
## Linha 1 (Frente): [1] [2] [3]
## Linha 2 (Meio):   [6] [5] [4]
## Linha 3 (Fundo):  [7] [8] [9]

signal army_ready(army: Army)
signal cancelled

## ATENÇÃO AO CONECTAR "army_ready": lambdas do GDScript capturam
## variáveis locais POR VALOR, não por referência — conecte a um MÉTODO
## nomeado, nunca a uma lambda que tenta escrever numa variável local
## externa (confirmado com execução real, ver bootstrap.gd).

## Configurar ANTES de _ready() rodar. 1 = só a posição base (PvP,
## Minas). 5 = PvE (Formações α a ε).
var formation_count: int = 1

const POSITION_LAYOUT: Array[int] = [1, 2, 3, 6, 5, 4, 7, 8, 9]  # ordem visual, valor = nº da posição
const FORMATION_NAMES: Array[String] = ["α", "β", "γ", "δ", "ε"]

## Definido ANTES de add_child() por quem chama, quando o objetivo é
## editar as Formações de um Exército JÁ EXISTENTE.
var existing_army: Army = null

## Definido junto com "existing_army", ANTES de add_child(), quando o
## objetivo é editar a COMPOSIÇÃO (Comandante e/ou Cartas), não só as
## Formações.
var editing_composition: bool = false

## Campo de Prova (CAMPO_DE_PROVA.md): quando true, "Montar Exército"/
## "Salvar Alterações" NUNCA chama Kingdom.form_army()/re_form_army() —
## constrói um Army solto (nunca em Kingdom.armies) e o entrega via
## army_ready, sem tocar ownership/inventário do jogador. "Cancelar"
## também nunca chama Kingdom.disband_army() nesse modo (nada foi
## registrado no Reino pra desfazer). Setar ANTES de add_child(), mesmo
## padrão de existing_army/editing_composition — nunca durante uso.
var sandbox_mode: bool = false

## Pool de Cartas/Comandantes a oferecer quando sandbox_mode == true.
## [] (padrão) usa o catálogo completo do jogo (GameDatabase), sempre
## .duplicate() antes de exibir; um Array não-vazio o substitui (ex:
## Kingdom.cards do próprio jogador, pra "editar meu Exército para o
## Campo de Prova" sem tocar ownership real, mas ainda restrito ao que
## o jogador de fato possui). Nunca lido quando sandbox_mode == false.
var sandbox_card_pool: Array[CardResource] = []
var sandbox_commander_pool: Array[CommanderResource] = []

## Cache do catálogo completo duplicado — construído uma vez por sessão
## do Editor (nunca recriado a cada refresh), só quando sandbox_mode ==
## true e nenhum pool explícito foi fornecido.
var _cached_sandbox_catalog_cards: Array[CardResource] = []
var _cached_sandbox_catalog_commanders: Array[CommanderResource] = []

## --- Contrato (nomes preservados, ver docstring do topo) ---
var _commander_option: Control = null
var _formations_section: Control = null
var _formation_cards: Dictionary = {}  # nome ("α".."ε") -> Array[CardResource] (9 posições)
var _current_formation: String = "α"

var _eligible_commanders: Array[CommanderResource] = []
var _selected_commander: CommanderResource = null
var _selected_cards: Array[CardResource] = []  # ordem de escolha = posição base 1..9 (fallback)

var _army: Army = null

## BUG REAL CONFIRMADO (auditoria desta etapa): toda ação (selecionar
## Carta, arrastar, filtrar, trocar Comandante) chama _refresh_all(),
## que sempre cria um ScrollContainer NOVO do zero — nunca reaproveita
## o existente. Um ScrollContainer novo sempre nasce com
## scroll_vertical=0, então CADA ação devolvia o jogador ao topo da
## lista/grade, mesmo que a ação em si não tivesse relação nenhuma com
## rolagem. Corrigido guardando a posição do ScrollContainer ATUAL
## antes de destruí-lo (_refresh_all()/_rebuild_detail_content()) e
## reaplicando no NOVO logo depois de construído — via call_deferred,
## porque a extensão rolável (scroll_vertical máximo) só fica correta
## depois que o Godot processa o layout do conteúdo recém-adicionado
## (mesma cautela de timing já usada no resto desta tela).
var _list_scroll: ScrollContainer = null
var _list_scroll_position: int = 0
var _detail_scroll: ScrollContainer = null
var _detail_scroll_position: int = 0
var _help_popup: Control = null

## --- Estado novo (livre, não testado por bootstrap.gd) ---
var _mode: String = "comandante"  # "comandante" | "pelotao"

## Rascunho de posicionamento da Fase 1 (antes de Montar/Salvar) — 9
## posições, null = vazia. Mantido em sincronia por _on_card_toggled()
## quando chamado pela UI; se algo escrever _selected_cards direto
## (bootstrap.gd faz isso em alguns testes) ele fica desatualizado de
## propósito, e _resolved_alpha_order() detecta isso e cai de volta em
## _selected_cards.duplicate() — nunca quebra o contrato antigo.
var _phase1_slots: Array[CardResource] = [null, null, null, null, null, null, null, null, null]

## Mensagem do último "Criar Exército Aleatório" — só preenchida quando
## a geração FALHA (nenhuma composição válida encontrada); limpa em
## qualquer geração bem-sucedida ou interação manual subsequente.
var _random_army_message: String = ""

var _filter_cmd_faction: String = "(todas)"
var _filter_cmd_patente: String = "(qualquer)"
var _filter_cmd_soldo_min: String = "(qualquer)"

var _filter_card_faction: String = "(todas)"
var _filter_card_class: String = "(todas)"
var _filter_card_rarity: String = "(todas)"
var _filter_card_tier: String = "(todos)"

const FACCAO_VALUES: Array[String] = ["(todas)", "Império", "Natureza", "Mortos-Vivos"]
## Mesmo vocabulário de CardResource.card_class já usado em
## bestiario_panel.gd/academia_producao_panel.gd — nunca uma segunda
## taxonomia inventada.
const CLASSE_VALUES: Array[String] = ["(todas)", "Corpo a Corpo", "À Distância", "Mago", "Suporte", "Barreira", "Máquina de Guerra"]
const RARIDADE_VALUES: Array[String] = ["(todas)", "Comum", "Rara", "Épica", "Lendária"]
const TIER_VALUES: Array[String] = ["(todos)", "1", "2", "3", "4", "5"]

## --- Identidade visual (mesma moldura/paleta do Centro de Comando —
## mesmo arquivo/geometria já medida por pixel em exercitos_panel.gd). ---
const FRAME_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/command_center_army_window_frame.png")
const FRAME_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const TITLE_RECT: Rect2 = Rect2(0.318, 0.133, 0.364, 0.061)
const CLOSE_BUTTON_RECT: Rect2 = Rect2(0.859, 0.117, 0.072, 0.103)
## FASE 22.5 — vão livre entre o título (termina em 0.682) e o botão
## fechar (começa em 0.859): único botão de ajuda PERSISTENTE da tela
## (os "(?)" pontuais de Soldo/Afinidade continuam existindo — este é
## só um ponto de entrada visível sem precisar descobrir por acaso).
const HELP_BUTTON_RECT: Rect2 = Rect2(0.740, 0.133, 0.075, 0.061)

## FASE 22.3 — REDESENHO CONCEITUAL (pedido explícito): a coluna ESQUERDA
## LARGA da moldura (antes TOP_RECT+LIST_RECT: abas + filtros/lista de
## seleção) agora hospeda "EXÉRCITO/FORMAÇÃO" — o elemento dominante da
## tela (Comandante compacto, Formação 3x3 GRANDE, Soldo/Afinidade,
## ações). A coluna DIREITA ESTREITA (antes DETAIL_RECT: Comandante +
## Formação) agora hospeda a "Biblioteca de Pelotões/Comandantes" —
## deliberadamente compacta (linhas de texto, nunca cartas completas;
## hover mostra a carta real via _build_card_tooltip(), já existente).
## Nenhuma geometria da MOLDURA em si mudou (mesmo PNG, mesmas 2 colunas
## visuais já existentes, mesmas larguras) — só qual conteúdo lógico
## ocupa qual coluna. ARMY_RECT funde a altura de TOP_RECT+LIST_RECT
## (0.242 a 0.827) na mesma largura larga de antes (0.572) — a Formação
## já não precisa mais dividir espaço com abas/filtros de seleção.
const ARMY_RECT: Rect2 = Rect2(0.086, 0.242, 0.572, 0.585)           # coluna esquerda larga: Comandante + Formação + Soldo/Afinidade + ações
const LIBRARY_TABS_RECT: Rect2 = Rect2(0.674, 0.242, 0.241, 0.060)   # coluna direita estreita: abas Comandante/Pelotão
const LIBRARY_RECT: Rect2 = Rect2(0.674, 0.302, 0.241, 0.525)        # coluna direita estreita: filtros + lista compacta

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 3
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)

const PORTRAIT_IMPERIO_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_1.png")
const PORTRAIT_IMPERIO_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_2.png")
const PORTRAIT_NATUREZA_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_1.png")
const PORTRAIT_NATUREZA_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_2.png")
const PORTRAIT_MORTOS_VIVOS_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_1.png")
const PORTRAIT_MORTOS_VIVOS_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_2.png")

## Correção FASE 22.3 (item A.6/A.7 — Formação como elemento DOMINANTE):
## a Formação vivia na antiga coluna estreita (DETAIL_RECT, ~234px) —
## 70px por carta já era o limite prático ali. Agora vive na coluna
## larga (ARMY_RECT, ~556px) — aumentada pra realmente dominar a tela,
## como pedido, mantendo espaço de sobra pra Soldo/Energia/Afinidade e
## ações abaixo. COMMANDER_PORTRAIT_SIZE reduzido (era 84): o Comandante
## agora é deliberadamente compacto/secundário à Formação (item A.9).
const FORMATION_CARD_WIDTH: float = 130.0
const COMMANDER_PORTRAIT_SIZE: float = 60.0


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	# Aquece o cache de textura das Cartas em segundo plano (mesmo
	# padrão de biblioteca_panel.gd/bestiario_panel.gd/exercitos_panel.gd)
	# — a lista/grade do modo Pelotão e a Formação usam BattleCardView/
	# CardArtCatalog, diferente da versão anterior (só texto).
	CardArtCatalog.preload_all(GameDatabase.cards)

	_build_static_structure()
	# Correção FASE 22.2 (achado real via screenshot, não só leitura de
	# código): _formations_section/_commander_option são Controls comuns
	# ancorados por FRAÇÃO dentro de texture_rect, que só assume seu
	# tamanho real (972x648 em 1152x648, por causa do AspectRatioContainer
	# letterboxed) depois de pelo menos 1 passada de layout do Godot. Sem
	# este frame de espera, _build_detail_area()/_build_top_tabs_area()
	# resolviam DETAIL_RECT/TOP_RECT/LIST_RECT contra o tamanho ainda não
	# corrigido de texture_rect (o viewport inteiro, 1152x648) — o
	# Control resultante (`area`) NUNCA se recalculava depois, mesmo após
	# texture_rect assumir o tamanho certo (confirmado via prints de
	# depuração: `area` ficava parado em ~0.241×1152px, quase o dobro da
	# largura real pretendida, e ainda incorretamente posicionado —
	# causa raiz do texto cortado na coluna direita, ex.: "COMANDANTE"
	# virando "COMANDAN"). Esperar 1 frame aqui, antes de qualquer
	# _build_detail_area()/_build_top_tabs_area(), garante que
	# texture_rect já processou o layout do AspectRatioContainer.
	for i in range(3):
		await get_tree().process_frame
	if existing_army != null and editing_composition:
		_selected_commander = existing_army.commander
		_selected_cards = existing_army.cards.duplicate()
		# F-021.1.1: sem isto a grade (_current_grid_source() lê
		# _phase1_slots enquanto _army == null, ou seja, durante toda a
		# edição pré-commit) mostrava as 9 posições vazias mesmo com a
		# Formação real intacta em _selected_cards/existing_army.cards —
		# bug puramente visual (salvar já recaía em _selected_cards via
		# _resolved_alpha_order()), nunca perda de dado.
		_phase1_slots = existing_army.cards.duplicate()
		_refresh_all()
	elif existing_army != null:
		_start_formation_edit_mode()
	else:
		_refresh_all()


## ARMY.md: todo Exército já existente já tem as 5 Formações. Aqui só
## carrega esse estado já existente pra edição — nunca gera nada novo.
## _commander_option fica invisível (nada a escolher); _formations_section
## sozinho mostra Comandante + Formação, com as abas α-ε se
## formation_count>1.
func _start_formation_edit_mode() -> void:
	_army = existing_army
	_selected_commander = existing_army.commander
	_selected_cards = existing_army.cards.duplicate()
	formation_count = 5  # sempre permite editar as 5, mesmo que o Exército tenha nascido de um fluxo de 1 Formação só

	_commander_option.visible = false

	_formation_cards["α"] = existing_army.cards.duplicate()
	for i in range(1, formation_count):
		var formation_name: String = FORMATION_NAMES[i]
		_formation_cards[formation_name] = existing_army.formations[formation_name].duplicate() if existing_army.formations.has(formation_name) else existing_army.cards.duplicate()

	_current_formation = "α"
	_rebuild_detail_content()


## --- Estrutura estática (moldura + as duas regiões alternáveis). ---

func _build_static_structure() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var window_area := Control.new()
	window_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	window_area.clip_contents = true
	add_child(window_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = FRAME_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	window_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = FRAME_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_title(texture_rect, "Editar Exército" if existing_army != null else "Editor de Exército")
	_build_close_button(texture_rect)
	_build_help_button(texture_rect)

	# _commander_option: faixa superior (abas) + área grande esquerda
	# (filtros + lista/grade), como UM SÓ Control — visible=false
	# esconde as duas de uma vez (contrato do modo "só Formação").
	# BUG REAL CONFIRMADO (auditoria desta etapa): estes dois wrappers
	# cobrem o retângulo INTEIRO da moldura (0,0,1,1) só para que um
	# único .visible os escondesse juntos — mas com MOUSE_FILTER_PASS
	# (usado antes aqui) cada um ainda participa do hit-test do Godot em
	# QUALQUER ponto da tela, inclusive por cima do botão X e um por
	# cima do outro (_formations_section é adicionado depois, logo fica
	# na frente de _commander_option inteiro). Na prática isso bloqueava
	# cliques em toda a janela, não só numa borda. MOUSE_FILTER_IGNORE
	# torna os dois wrappers inteiramente transparentes ao mouse — só os
	# filhos ancorados (TOP_RECT/LIST_RECT/DETAIL_RECT, cada um com seu
	# próprio MOUSE_FILTER_STOP local, mesmo padrão de exercitos_panel.gd/
	# comandantes_panel.gd) continuam capturando clique.
	_commander_option = _anchor_new_control(texture_rect, Rect2(0, 0, 1, 1))
	_commander_option.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_tabs_area(_commander_option)
	_build_selection_area(_commander_option)

	# _formations_section: coluna direita — sempre construído visível.
	_formations_section = _anchor_new_control(texture_rect, Rect2(0, 0, 1, 1))
	_formations_section.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_title(parent: Control, text: String) -> void:
	var area := _anchor_new_control(parent, TITLE_RECT)
	var label := _make_centered_label(text, 18, HUD_ACCENT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area.add_child(label)


func _build_close_button(parent: Control) -> void:
	var hotspot := _anchor_new_control(parent, CLOSE_BUTTON_RECT)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.gui_input.connect(_on_close_button_gui_input)


func _on_close_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()


## FASE 22.5 — ponto de entrada de ajuda PERSISTENTE (achado 22.1: só
## existiam tooltips pontuais, nada visível sem passar o mouse por
## acaso em cima). O popup é deliberadamente curto — 1-2 linhas por
## conceito, nunca reescrevendo a regra completa (isso já existe nos
## "(?)" de SOLDO DO EXÉRCITO/AFINIDADE, nos tooltips de posição 1/5/9 e
## nas dicas de PG/Fragmentos de city_panel.gd — este popup só aponta
## pra onde cada explicação completa já mora, pra nunca duplicar texto
## e criar uma segunda fonte de verdade que possa divergir).
func _build_help_button(parent: Control) -> void:
	var hotspot := _anchor_new_control(parent, HELP_BUTTON_RECT)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var label := _make_centered_label("(?) Ajuda", 11, HUD_ACCENT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotspot.add_child(label)
	hotspot.gui_input.connect(_on_help_button_gui_input)


func _on_help_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_help_popup()


func _show_help_popup() -> void:
	if _help_popup != null:
		return

	var overlay := _anchor_new_control(self, Rect2(0, 0, 1, 1))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_help_overlay_gui_input)
	_help_popup = overlay

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)

	var box_area := _anchor_new_control(overlay, Rect2(0.28, 0.16, 0.44, 0.68))
	box_area.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := _make_card_panel()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	box_area.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_centered_label("AJUDA — CONCEITOS", 14, HUD_ACCENT))
	vbox.add_child(_make_separator())

	for entry: Dictionary in _help_entries():
		vbox.add_child(_make_centered_label(entry["title"], 11, HUD_TEXT_COLOR))
		vbox.add_child(_make_detail_wrap_label(entry["body"], 10, HUD_MUTED_COLOR, true))

	var close_hotspot := _anchor_new_control(box_area, Rect2(0.88, 0.02, 0.10, 0.06))
	close_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	close_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var close_label := _make_centered_label("X", 14, HUD_ACCENT)
	close_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_hotspot.add_child(close_label)
	close_hotspot.gui_input.connect(_on_help_popup_close_gui_input)


## Textos-fonte (nunca reescritos aqui, só resumidos em 1 frase e
## apontando pra explicação completa já existente na tela ou em
## city_panel.gd): PG/Fragmentos vêm literalmente de
## city_panel.gd:_maybe_show_economy_hints() (GENERATION_POINTS.md/
## RESOURCES.md); Soldo/Afinidade apontam pros próprios cabeçalhos "(?)"
## desta tela (_build_soldo_panel/_build_affinity_section); Formação e
## Máquina de Guerra apontam pros tooltips reais de
## _position_special_note() (COMBAT_RULES.md 6.1/6.2/5.2.2/6.6).
func _help_entries() -> Array[Dictionary]:
	return [
		{"title": "Pontos de Geração (PG)", "body": "PG é um recurso único do Reino, ganho a cada vez que sua Conta sobe de Nível. Usado para evoluir Minas, Depósito, Centro de Comando e Academia."},
		{"title": "Fragmentos", "body": "Obtidos destruindo Pelotões inimigos em combate, específicos de cada Facção. Usados na Academia para produzir novas Cartas."},
		{"title": "Soldo", "body": "Orçamento de manutenção do Exército — veja o (?) ao lado de \"SOLDO DO EXÉRCITO\" abaixo para o teto por Patente."},
		{"title": "Afinidade", "body": "Bônus de Facção acumulado pelos Pelotões escalados — veja o (?) ao lado de \"AFINIDADE\" abaixo para os níveis e efeitos."},
		{"title": "Formação — posições especiais", "body": "As posições 1, 5 e 9 têm regras próprias (bônus de linha de frente, penalidade de reorganização, Máquina de Guerra) — passe o mouse sobre elas na grade da Formação para ver cada regra."},
	]


func _on_help_popup_close_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_help_popup()


func _on_help_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_help_popup()


func _hide_help_popup() -> void:
	if _help_popup == null:
		return
	_help_popup.get_parent().remove_child(_help_popup)
	_help_popup.free()
	_help_popup = null


## Reconstrói as duas regiões alternáveis inteiras — mesmo padrão de
## reconstrução total já usado no resto do projeto (nenhum estado de
## Control é preservado entre chamadas, só as variáveis desta classe) —
## exceto a posição de rolagem da lista/grade, guardada e reaplicada
## (ver docstring de _list_scroll).
func _refresh_all() -> void:
	if _list_scroll != null:
		_list_scroll_position = _list_scroll.scroll_vertical
	if _commander_option != null:
		_clear_children(_commander_option)
		_build_top_tabs_area(_commander_option)
		_build_selection_area(_commander_option)
	_rebuild_detail_content()


func _rebuild_detail_content() -> void:
	if _detail_scroll != null:
		_detail_scroll_position = _detail_scroll.scroll_vertical
	if _formations_section == null:
		return
	_clear_children(_formations_section)
	_build_detail_area(_formations_section)


## --- Faixa superior da Biblioteca (coluna direita estreita): abas
## COMANDANTE / PELOTÃO. ---
## Correção FASE 22.3 (item A.9/A.10): "Criar Exército Aleatório" saiu
## daqui — competia visualmente com as abas e reforçava a sensação de
## "3 modos independentes". Virou ação secundária dentro de
## _build_action_buttons(), na coluna do Exército/Formação (pedido
## explícito, item A.10). O Comandante precisa ser escolhido primeiro
## (regra já existente) — a aba PELOTÃO fica desabilitada até
## _selected_commander != null.
func _build_top_tabs_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, LIBRARY_TABS_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.add_child(center)

	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 10)
	center.add_child(tabs_hbox)

	var commander_tab := _make_tab_button("Comandante", _mode == "comandante", 100.0)
	commander_tab.pressed.connect(_on_mode_tab_pressed.bind("comandante"), CONNECT_DEFERRED)
	tabs_hbox.add_child(commander_tab)

	var pelotao_tab := _make_tab_button("Pelotão", _mode == "pelotao", 100.0)
	pelotao_tab.disabled = _selected_commander == null
	# Correção FASE 22 (continuação — Parte 4): a aba desabilitada por si
	# só não explicava O PORQUÊ pro jogador novo. Tooltip nativo simples
	# (Control.tooltip_text — mesma técnica já usada pelos "(?)" de
	# Soldo/Afinidade), nunca um redesenho da estrutura de abas em si
	# (avaliada e considerada funcionalmente correta: sequência já
	# reforçada pelo disabled, seleção já visível no cabeçalho do
	# Exército, resultado já atualiza em tempo real).
	if pelotao_tab.disabled:
		pelotao_tab.tooltip_text = "Escolha um Comandante primeiro — o Pelotão faz parte do Exército dele."
	pelotao_tab.pressed.connect(_on_mode_tab_pressed.bind("pelotao"), CONNECT_DEFERRED)
	tabs_hbox.add_child(pelotao_tab)


func _on_mode_tab_pressed(mode: String) -> void:
	if mode == "pelotao" and _selected_commander == null:
		return
	if mode != _mode:
		_list_scroll_position = 0  # lista de Comandantes e grade de Cartas são conteúdos diferentes — preservar rolagem entre as duas não faz sentido
	_mode = mode
	_refresh_all()


## --- "Criar Exército Aleatório" ---
##
## AUDITORIA (antes de implementar, pedido explícito): a única
## "heurística de composição automática" real do projeto é
## EnemyArmyGenerator (engine/world/season/enemy_army_generator.gd) —
## usada pra gerar Exércitos INIMIGOS de PvE/PvP. Ela NÃO serve pra
## reuso direto aqui: monta um CommanderResource TÉCNICO/PROCEDURAL
## novo (nunca um Comandante real do jogador) e distribui as 9 Cartas
## numa proporção fixa de Facção do Território (6+3) que não existe no
## contexto do Editor (o jogador escolhe livremente do seu próprio
## acervo, sem "território"). O que É diretamente reaproveitável, e
## reaproveitado aqui:
##   - a TÉCNICA de amostragem da própria EnemyArmyGenerator
##     (build_composition()/_pick_unique_by_name()): embaralhar o pool,
##     preencher gananciosamente respeitando Unicidade de Nome, testar
##     o Soldo total contra o teto, tentar de novo com outro embaralhamento
##     se estourar — nunca "9 cartas aleatórias sem checar nada";
##   - Soldo.cap_for_patente()/Soldo.total_for_composition()/
##     Soldo.cost_for_rarity() (SOLDO.md, SSoT real, nunca recalculado);
##   - a mesma checagem de Unicidade de Composição usada por
##     _on_card_toggled();
##   - a mesma checagem de posse (_card_is_owned_elsewhere(),
##     _eligible_commanders_filtered_ignoring_filters()) já usada no
##     resto desta tela — nunca uma 2ª regra de disponibilidade;
##   - ArmyFormationArchetypes.generate_all() (a heurística REAL de
##     POSICIONAMENTO tático, já usada por Kingdom.form_army() pra
##     gerar β-γ-δ-ε) — usada aqui só pra dar à prévia (_phase1_slots)
##     um arranjo tático sensato (Formação δ, Equilibrada) em vez de
##     ordem arbitrária, antes mesmo de "Montar Exército" rodar.
##
## Restrição/Requisito da Doutrina do Comandante sorteado: não existe
## nenhuma regra de "restrição/requisito de Doutrina afeta ELEGIBILIDADE
## do Comandante pra liderar um Exército" em ARMY.md/COMMANDERS.md hoje
## (Doutrina se aplica em Combate, via CommanderDoctrineRuntime — nunca
## bloqueia formar o Exército em si). Não inventei essa checagem.
##
## Nunca forma/salva o Exército de verdade (Kingdom.form_army() só roda
## se o jogador clicar "Montar Exército"/"Salvar Alterações" depois,
## revisando o resultado como qualquer composição escolhida manualmente).
## Teto de tentativas: ver ArmyRandomComposer.MAX_ATTEMPTS (extraída
## nesta etapa, Campo de Prova).


func _on_random_army_pressed() -> void:
	if _army != null:
		return

	var kingdom: Kingdom = KingdomState.kingdom
	var eligible_commanders: Array[CommanderResource] = _eligible_commanders_filtered_ignoring_filters(kingdom)
	if eligible_commanders.is_empty():
		_random_army_message = "NÃO FOI POSSÍVEL ENCONTRAR UMA COMPOSIÇÃO VÁLIDA: nenhum Comandante Ativo e livre no Reino. Recrute/promova um em \"Comandantes\" primeiro."
		_refresh_all()
		return

	var pool: Array[CardResource] = _random_selectable_cards(kingdom)
	if pool.size() < 9:
		_random_army_message = "NÃO FOI POSSÍVEL ENCONTRAR UMA COMPOSIÇÃO VÁLIDA: só existem %d Carta(s) livre(s) no Reino — são necessárias 9 com Nomes distintos." % pool.size()
		_refresh_all()
		return

	var shuffled_commanders: Array[CommanderResource] = eligible_commanders.duplicate()
	shuffled_commanders.shuffle()

	for commander: CommanderResource in shuffled_commanders:
		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var cap: int = Soldo.cap_for_patente(patente)
		var composition: Array[CardResource] = _random_valid_composition(pool, cap)
		if composition.is_empty():
			continue

		_random_army_message = ""
		_selected_commander = commander
		_selected_cards = composition
		var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(composition)
		var balanced: Array[CardResource] = archetypes.get("δ", composition)
		_phase1_slots = balanced.duplicate()
		_mode = "pelotao"
		_refresh_all()
		return

	_random_army_message = "NÃO FOI POSSÍVEL ENCONTRAR UMA COMPOSIÇÃO VÁLIDA: nenhum Comandante elegível tem Soldo suficiente pra cobrir 9 Cartas livres e distintas do Reino."
	_refresh_all()


## Mesmo filtro de disponibilidade real de sempre (_card_is_owned_elsewhere,
## já usado pela lista/grade do Pelotão) — nunca uma 2ª regra de posse.
func _random_selectable_cards(kingdom: Kingdom) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in _effective_card_pool(kingdom):
		if _card_is_owned_elsewhere(card):
			continue
		result.append(card)
	return result


## Resolve de qual pool este Editor lê Cartas/Comandantes: o Reino do
## jogador (comportamento normal, inalterado) ou o pool de sandbox do
## Campo de Prova (sandbox_mode == true) — explícito
## (sandbox_card_pool/sandbox_commander_pool) ou, na ausência de um,
## o catálogo completo do jogo (GameDatabase), duplicado uma única vez
## por sessão do Editor. Único ponto que decide a origem — as demais
## funções de elegibilidade/filtro continuam exatamente as mesmas,
## nenhuma regra duplicada.
func _effective_card_pool(kingdom: Kingdom) -> Array[CardResource]:
	if not sandbox_mode:
		return kingdom.cards
	if not sandbox_card_pool.is_empty():
		return sandbox_card_pool
	if _cached_sandbox_catalog_cards.is_empty():
		for template: CardResource in GameDatabase.cards:
			_cached_sandbox_catalog_cards.append(template.duplicate())
	return _cached_sandbox_catalog_cards


## Catálogo real de Comandantes hoje é quase inexistente (1 template
## estático — Game/database/commanders_pool/) porque Comandantes de
## verdade são gerados, nunca escolhidos de uma lista (mesma auditoria
## já registrada em test_army_factory.gd). O pool padrão de sandbox
## reflete isso: o único template real (ativado/boostado se necessário)
## mais alguns gerados via CommanderGenerator (TestArmyFactory,
## mesma técnica de EnemyArmyGenerator._build_commander()), cobrindo
## uma faixa de Patentes pra dar variedade real de escolha.
func _effective_commander_pool(kingdom: Kingdom) -> Array[CommanderResource]:
	if not sandbox_mode:
		return kingdom.commanders
	if not sandbox_commander_pool.is_empty():
		return sandbox_commander_pool
	if _cached_sandbox_catalog_commanders.is_empty():
		for template: CommanderResource in GameDatabase.commanders:
			var copy: CommanderResource = template.duplicate()
			copy.administrative_state = CommanderResource.AdministrativeState.ACTIVE
			if copy.accumulated_xp <= 0:
				copy.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS[-1]["xp"]
			_cached_sandbox_catalog_commanders.append(copy)
		for patente: String in ["Capitão", "Major", "Coronel", "General", "Marechal", "Lorde-Comandante"]:
			_cached_sandbox_catalog_commanders.append(TestArmyFactory.generate_commander(patente))
	return _cached_sandbox_catalog_commanders


## Extraída para engine/army/army_random_composer.gd (ArmyRandomComposer)
## nesta etapa (Campo de Prova, CAMPO_DE_PROVA.md) — reaproveitada dali
## agora, nunca duplicada, pra também servir a "Formação Aleatória" do
## Campo de Prova sem reimplementar a heurística. Mesmo corpo de antes.
func _random_valid_composition(pool: Array[CardResource], soldo_cap: int) -> Array[CardResource]:
	return ArmyRandomComposer.random_valid_composition(pool, soldo_cap)


## --- Biblioteca (coluna direita estreita): filtros + lista compacta,
## conforme a aba ativa. ---
func _build_selection_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, LIBRARY_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	area.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	if _mode == "comandante":
		_build_commander_filters(vbox)
	else:
		_build_card_filters(vbox)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)
	_list_scroll = scroll
	# call_deferred: a extensão rolável máxima só fica correta depois do
	# Godot processar o layout do conteúdo montado logo abaixo (mesma
	# cautela de timing de sempre nesta tela) — setar na hora clamparia
	# pra 0 sempre que o conteúdo ainda não tivesse sido medido.
	scroll.call_deferred("set", "scroll_vertical", _list_scroll_position)

	if _mode == "comandante":
		_build_commander_list(scroll)
	else:
		_build_card_grid(scroll)


## --- Modo Comandante ---

## Correção FASE 22.3: filtros lado a lado (HBoxContainer) cabiam na
## antiga área grande (~556px); a Biblioteca agora é a coluna estreita
## (~218px úteis) — cada filtro passou a ocupar sua própria linha
## (empilhados), nunca mais 2-3 lado a lado.
func _build_commander_filters(parent: Control) -> void:
	parent.add_child(_make_label("Filtros de Comandantes", 11, HUD_ACCENT))

	var faction_option := _styled_option_button(FACCAO_VALUES, _filter_cmd_faction)
	faction_option.item_selected.connect(_on_cmd_faction_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Facção", faction_option))

	var patente_values: Array[String] = _patente_filter_values()
	var patente_option := _styled_option_button(patente_values, _filter_cmd_patente)
	patente_option.item_selected.connect(_on_cmd_patente_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Patente", patente_option))

	var soldo_values: Array[String] = _soldo_min_filter_values()
	var soldo_option := _styled_option_button(soldo_values, _filter_cmd_soldo_min)
	soldo_option.item_selected.connect(_on_cmd_soldo_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Soldo mínimo", soldo_option))


## Cada filtro sempre com uma legenda curta em cima (nunca uma caixa
## sem identificação) — o jogador precisa ler "isto filtra Facção" sem
## adivinhar. Legenda não-wrap (curta, uma palavra/duas) — mesma defesa
## contra texto verticalizado já usada em todo o resto da tela.
func _build_labeled_filter(caption: String, option_button: OptionButton) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_make_label(caption.to_upper(), 9, HUD_MUTED_COLOR))
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(option_button)
	return column


func _on_cmd_faction_selected(index: int) -> void:
	_filter_cmd_faction = FACCAO_VALUES[index]
	_refresh_all()


func _on_cmd_patente_selected(index: int) -> void:
	_filter_cmd_patente = _patente_filter_values()[index]
	_refresh_all()


func _on_cmd_soldo_selected(index: int) -> void:
	_filter_cmd_soldo_min = _soldo_min_filter_values()[index]
	_refresh_all()


## Fonte real: CommanderCareer.PATENTE_THRESHOLDS (XP.md) — nunca uma
## segunda lista de Patentes inventada.
func _patente_filter_values() -> Array[String]:
	var values: Array[String] = ["(qualquer)"]
	for entry: Dictionary in CommanderCareer.PATENTE_THRESHOLDS:
		values.append(entry["patente"])
	return values


## "Soldo mínimo": filtra pelo teto de Soldo (Soldo.CAP_BY_PATENTE) que
## a Patente do Comandante concede — útil pra achar Comandantes cujo
## orçamento já cobre uma composição de Cartas em mente, sem o jogador
## precisar decorar qual Patente equivale a qual teto.
func _soldo_min_filter_values() -> Array[String]:
	var values: Array[String] = ["(qualquer)"]
	for entry: Dictionary in CommanderCareer.PATENTE_THRESHOLDS:
		values.append(str(Soldo.cap_for_patente(entry["patente"])))
	return values


## Elegibilidade REAL de base (ARMY.md/COMMANDERS.md), sem nenhum dos 3
## filtros cosméticos por cima — mesmo predicado da versão anterior
## (OptionButton): Ativo, e (Livre OU já é o Comandante deste Exército
## sendo editado). Extraído à parte pra _build_commander_list() poder
## diagnosticar "não existe ninguém elegível de verdade" vs "os filtros
## esconderam alguém que existe", em vez de uma mensagem genérica.
func _eligible_commanders_filtered_ignoring_filters(kingdom: Kingdom) -> Array[CommanderResource]:
	var result: Array[CommanderResource] = []
	for commander: CommanderResource in _effective_commander_pool(kingdom):
		var is_this_armys_own_commander: bool = editing_composition and existing_army != null and commander == existing_army.commander
		if commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
			continue
		if commander.ownership_status != CommanderResource.OwnershipStatus.LIVRE and not is_this_armys_own_commander:
			continue
		result.append(commander)
	return result


func _eligible_commanders_filtered(kingdom: Kingdom) -> Array[CommanderResource]:
	var result: Array[CommanderResource] = []
	for commander: CommanderResource in _eligible_commanders_filtered_ignoring_filters(kingdom):
		if _filter_cmd_faction != "(todas)" and commander.faction != _filter_cmd_faction:
			continue
		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		if _filter_cmd_patente != "(qualquer)" and patente != _filter_cmd_patente:
			continue
		if _filter_cmd_soldo_min != "(qualquer)" and Soldo.cap_for_patente(patente) < int(_filter_cmd_soldo_min):
			continue
		result.append(commander)
	return result


func _build_commander_list(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	_eligible_commanders = _eligible_commanders_filtered(kingdom)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)

	if _eligible_commanders.is_empty():
		# Diagnóstico real (pedido explícito: nunca aceitar a mensagem
		# genérica como explicação) — distingue "os filtros escondem
		# alguém que existe" de "não existe NINGUÉM Ativo e Livre no
		# Reino ainda" (ex: Kit Inicial — o único Comandante já nasce
		# ACTIVE, mas EM_EXERCITO liderando o Exército inicial; formar
		# um 2º Exército exige recrutar/promover outro Comandante
		# primeiro, em Comandantes — não é bug, é a regra real).
		if _eligible_commanders_filtered_ignoring_filters(kingdom).is_empty():
			vbox.add_child(_make_body_label("Nenhum Comandante Ativo e livre no Reino ainda. Recrute e promova um Comandante em \"Comandantes\" antes de montar outro Exército."))
		else:
			vbox.add_child(_make_body_label("Nenhum Comandante Ativo disponível com estes filtros."))
		return

	# Pré-seleciona o 1º elegível na primeira renderização (nenhum
	# Comandante escolhido ainda) — antes de montar as fileiras, pra já
	# nascerem com o destaque de seleção correto.
	if _selected_commander == null:
		_selected_commander = _eligible_commanders[0]

	for commander: CommanderResource in _eligible_commanders:
		vbox.add_child(_build_commander_row(commander))


## Correção FASE 22.3: esta linha rendeirzava na antiga coluna larga
## (~556px); agora renderiza na Biblioteca estreita (~218px úteis) —
## retrato reduzido, texto em linhas mais curtas (nunca mais uma única
## linha "Patente | Facção | Soldo" sem quebra, que ultrapassava a
## largura disponível e arrastava a coluna inteira, mesma causa raiz já
## corrigida na coluna de Exército/Formação).
func _build_commander_row(commander: CommanderResource) -> Control:
	var is_selected: bool = commander == _selected_commander
	var panel := _make_list_row_panel(is_selected)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_commander_row_gui_input.bind(commander), CONNECT_DEFERRED)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	row.add_child(_make_portrait(_portrait_for(commander), 34.0))

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	var name_label := _make_label(commander.commander_name, 11, HUD_ACCENT_SELECTED if is_selected else HUD_TEXT_COLOR)
	name_label.clip_text = true
	column.add_child(name_label)
	var patente_label := _make_label("%s • %s" % [patente, commander.faction], 8, HUD_MUTED_COLOR)
	patente_label.clip_text = true
	column.add_child(patente_label)

	var is_own: bool = editing_composition and existing_army != null and commander == existing_army.commander
	var estado_text: String = "Liderando" if is_own else "Disponível"
	column.add_child(_make_label(estado_text, 8, HUD_ACCENT))

	return panel


func _on_commander_row_gui_input(event: InputEvent, commander: CommanderResource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_commander_selected_real(commander)


func _on_commander_selected_real(commander: CommanderResource) -> void:
	if commander == _selected_commander:
		return
	_selected_commander = commander
	_random_army_message = ""
	_refresh_all()


## --- Modo Pelotão ---

## Correção FASE 22.3: mesmo ajuste de _build_commander_filters() — os
## 4 filtros empilhados (1 por linha), nunca mais 2x2 lado a lado
## (a Biblioteca agora é a coluna estreita, ~218px úteis).
func _build_card_filters(parent: Control) -> void:
	parent.add_child(_make_label("Filtros de Cartas", 11, HUD_ACCENT))

	var faction_option := _styled_option_button(FACCAO_VALUES, _filter_card_faction)
	faction_option.item_selected.connect(_on_card_faction_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Facção", faction_option))

	var classe_option := _styled_option_button(CLASSE_VALUES, _filter_card_class)
	classe_option.item_selected.connect(_on_card_class_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Classe", classe_option))

	var raridade_option := _styled_option_button(RARIDADE_VALUES, _filter_card_rarity)
	raridade_option.item_selected.connect(_on_card_rarity_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Raridade", raridade_option))

	var tier_option := _styled_option_button(TIER_VALUES, _filter_card_tier)
	tier_option.item_selected.connect(_on_card_tier_selected, CONNECT_DEFERRED)
	parent.add_child(_build_labeled_filter("Tier", tier_option))


func _on_card_faction_selected(index: int) -> void:
	_filter_card_faction = FACCAO_VALUES[index]
	_refresh_all()


func _on_card_class_selected(index: int) -> void:
	_filter_card_class = CLASSE_VALUES[index]
	_refresh_all()


func _on_card_rarity_selected(index: int) -> void:
	_filter_card_rarity = RARIDADE_VALUES[index]
	_refresh_all()


func _on_card_tier_selected(index: int) -> void:
	_filter_card_tier = TIER_VALUES[index]
	_refresh_all()


## BUG REAL CONFIRMADO (auditoria desta etapa): esta função excluía da
## lista qualquer Carta que não estivesse LIVRE — mas num Reino que só
## acabou de sair do Kit Inicial, as ÚNICAS Cartas que existem já
## nasceram EM_EXERCITO (StarterKitResolver.choose_option() forma o
## Exército inicial na hora, kingdom.gd:form_army() marca as 9 Cartas
## como EM_EXERCITO no mesmo instante) — resultado: a grade de "Criar
## Novo Exército" ficava sempre vazia mesmo com Cartas de verdade no
## Reino, porque elas TODAS já pertenciam a outro Exército. Rastreei
## Kingdom.cards -> CardResource.ownership_status -> este filtro -> a
## grade, e a causa era exatamente esta linha.
##
## Correção (só apresentação, nenhuma regra mudou): agora só os 4
## filtros cosméticos (Facção/Classe/Raridade/Tier) decidem o que
## aparece na grade. A disponibilidade REAL (LIVRE, ou já é desta
## Formação sendo editada, ou já foi escolhida agora) virou
## _card_is_owned_elsewhere()/_card_owner_army_display_name() — usadas
## só pra desenhar a Carta BLOQUEADA (esmaecida, com o motivo real e o
## Exército dono escritos) em vez de escondê-la, como o pedido
## explicitamente autorizou.
func _filtered_available_cards(kingdom: Kingdom) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in _effective_card_pool(kingdom):
		if _filter_card_faction != "(todas)" and card.faction != _filter_card_faction:
			continue
		if _filter_card_class != "(todas)" and card.card_class != _filter_card_class:
			continue
		if _filter_card_rarity != "(todas)" and card.rarity != _filter_card_rarity:
			continue
		if _filter_card_tier != "(todos)" and card.tier != int(_filter_card_tier):
			continue
		result.append(card)
	return result


## True quando a Carta está indisponível pra ESTE Exército (LIVRE, já
## pertence à composição sendo editada, ou já foi escolhida agora,
## contam como disponível) — mesma regra de posse de sempre (ARMY.md/
## CARD.md), só que agora usada pra EXPLICAR em vez de esconder.
func _card_is_owned_elsewhere(card: CardResource) -> bool:
	var is_this_armys_own_card: bool = editing_composition and existing_army != null and existing_army.cards.has(card)
	return card.ownership_status != CardResource.OwnershipStatus.LIVRE and not is_this_armys_own_card and not _selected_cards.has(card)


## Localiza QUAL Exército real possui esta Carta — sem tabela paralela:
## percorre Kingdom.armies (mesma fonte de exercitos_panel.gd) e checa
## Army.cards.has(card) diretamente. Nome exibido usa a MESMA convenção
## já usada lá ("army.army_name" com fallback "Exército %d" pela
## posição em kingdom.armies) — nunca um nome inventado. Nunca aponta
## pro próprio Exército sendo editado (esse não conta como "outro").
func _card_owner_army_display_name(card: CardResource) -> String:
	var kingdom: Kingdom = KingdomState.kingdom
	for i in range(kingdom.armies.size()):
		var army: Army = kingdom.armies[i]
		if editing_composition and existing_army != null and army == existing_army:
			continue
		if army.cards.has(card):
			return army.army_name if army.army_name != "" else "Exército %d" % (i + 1)
	return ""


## Correção FASE 22.3 (itens A.3/A.4/A.5 — Biblioteca compacta): a
## Biblioteca agora é a coluna estreita, e o pedido explícito foi "não
## transformar a biblioteca de volta numa grade de cartas". Trocado
## GridContainer (4 colunas de cartas completas) por uma lista vertical
## de 1 coluna (_build_compact_card_row()) — nome + Tier + Energia/Soldo
## em texto, nunca a arte completa (BattleCardView). A carta REAL só
## aparece no hover (_build_card_tooltip(), já existente, reaproveitado
## sem duplicação — item A.4).
func _build_card_grid(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var cards: Array[CardResource] = _filtered_available_cards(kingdom)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(list)

	if cards.is_empty():
		if kingdom.cards.is_empty():
			parent.add_child(_make_body_label("O Reino ainda não possui nenhuma Carta."))
		else:
			parent.add_child(_make_body_label("Nenhuma Carta do Reino combina com estes filtros."))
		return

	for card: CardResource in cards:
		list.add_child(_build_compact_card_row(card))


## Linha compacta de Pelotão (substitui o antigo _build_list_card_slot()
## de carta completa). Mesma lógica de bloqueio/seleção de sempre —
## nunca duplicada — só a apresentação virou texto.
func _build_compact_card_row(card: CardResource) -> Control:
	var is_selected: bool = _selected_cards.has(card)
	var owned_elsewhere: bool = not is_selected and _card_is_owned_elsewhere(card)
	var already_has_same_name: bool = false
	if not is_selected and not owned_elsewhere:
		for selected: CardResource in _selected_cards:
			if selected.card_name == card.card_name:
				already_has_same_name = true
	var army_full: bool = not is_selected and not owned_elsewhere and not already_has_same_name and _selected_cards.size() >= 9
	var over_soldo: bool = not is_selected and not owned_elsewhere and not already_has_same_name and not army_full and not _card_fits_soldo(card)
	var blocked: bool = not is_selected and (owned_elsewhere or already_has_same_name or army_full or over_soldo)

	var row := ArmyCardSlot.new()
	row.custom_minimum_size = Vector2(0, 44.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.10, 0.9) if not is_selected else Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.18)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = HUD_ACCENT_SELECTED if is_selected else Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", style)
	row.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6.0
	vbox.offset_right = -6.0
	vbox.offset_top = 3.0
	vbox.offset_bottom = -3.0
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(vbox)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_row)
	var name_label := _make_label(card.card_name.to_upper(), 10, HUD_MUTED_COLOR if blocked else HUD_TEXT_COLOR)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	name_row.add_child(_make_label("T%d" % card.tier, 10, HUD_ACCENT))

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 6)
	status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(status_row)
	# Correção: "EN"/"SD" e o número em Labels SEPARADOS (nunca uma
	# string combinada) — mesmo padrão de _make_composition_footer(),
	# consistente entre Biblioteca e Formação.
	status_row.add_child(_make_label("EN", 8, HUD_MUTED_COLOR))
	status_row.add_child(_make_label(str(EnergyArmy.card_energy(card.tier)), 8, Color(0.75, 0.85, 1.0)))
	status_row.add_child(_make_label("SD", 8, HUD_MUTED_COLOR))
	status_row.add_child(_make_label(str(Soldo.cost_for_rarity(card.rarity)), 8, HUD_ACCENT_SELECTED))

	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status_spacer)

	# "Em outro Exército" mostra o nome REAL do Exército dono
	# (Army.cards.has(card) -> Army.army_name, nunca uma tabela de posse
	# paralela) — o motivo precisa ficar legível sem abrir o tooltip
	# (pedido explícito, mantido da versão anterior desta tela).
	var status_text: String = ""
	var status_color: Color = HUD_MUTED_COLOR
	if is_selected:
		status_text = "Selecionada"
		status_color = HUD_ACCENT_SELECTED
	elif owned_elsewhere:
		var owner_name: String = _card_owner_army_display_name(card)
		status_text = "Em outro Exército (%s)" % owner_name if owner_name != "" else "Em outro Exército"
		status_color = HUD_ERROR_COLOR
	elif already_has_same_name:
		status_text = "Nome já usado"
		status_color = HUD_ERROR_COLOR
	elif army_full:
		status_text = "Exército completo"
		status_color = HUD_ERROR_COLOR
	elif over_soldo:
		status_text = "Sem Soldo"
		status_color = HUD_ERROR_COLOR
	if status_text != "":
		var status_label := _make_label(status_text, 8, status_color)
		status_label.clip_text = true
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_row.add_child(status_label)

	row.set_tooltip_builder(func() -> Control: return _build_card_tooltip(card))

	if not blocked or is_selected:
		row.gui_input.connect(_on_list_card_gui_input.bind(card), CONNECT_DEFERRED)
		row.drag_data_builder = func() -> Variant: return {"source": "list", "card": card}
		row.drag_preview_builder = func() -> Control: return _build_drag_preview(card)

	return row


## CAUSA-RAIZ do Drag-and-Drop não iniciar (auditoria desta etapa):
## este handler reagia em event.pressed (mouse PARA BAIXO) e chamava
## _refresh_all(), que reconstrói a árvore inteira e LIBERA (.free())
## este mesmíssimo ArmyCardSlot — exatamente o Control que o Godot
## acabou de registrar como possível origem de um arrasto. Ele nunca
## sobrevivia até o próximo frame de movimento do mouse pra Godot
## conseguir detectar o arrasto e chamar _get_drag_data(). Clique
## isolado (aperta e solta sem mover) parecia funcionar porque o efeito
## desejado (selecionar a Carta) já tinha acontecido antes do usuário
## notar. Corrigido reagindo em "solto" (not event.pressed), o mesmo
## padrão que Button já usa — só confirma o clique se NENHUM arrasto
## consumiu o evento de soltar antes (Godot entrega esse "solto" como
## _drop_data no alvo, nunca como gui_input na origem, quando um
## arrasto de verdade estava em andamento).
func _on_list_card_gui_input(event: InputEvent, card: CardResource) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_list_card_clicked(card)


func _on_list_card_clicked(card: CardResource) -> void:
	if _army != null:
		return  # composição travada depois de Montar/Salvar
	if _selected_cards.has(card):
		_on_card_toggled(false, card)
	else:
		_on_card_toggled(true, card)


func _card_fits_soldo(card: CardResource) -> bool:
	if _selected_commander == null:
		return false
	var patente: String = CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp)
	var cap: int = Soldo.cap_for_patente(patente)
	return Soldo.total_for_composition(_selected_cards) + Soldo.cost_for_rarity(card.rarity) <= cap


## --- Coluna direita: Comandante + Soldo do Exército + Formação 3x3. ---

## --- Exército/Formação (coluna esquerda larga) — elemento dominante
## da tela (FASE 22.3, item A.6/A.7). ---
## Correção FASE 22.3 (achado real via screenshot): a moldura tem uma
## linha decorativa dourada horizontal BAKED-IN na própria arte
## (command_center_army_window_frame.png), na fronteira exata onde
## ficava a antiga TOP_RECT (faixa de abas) — sempre existiu, mas nunca
## aparecia por cima de texto porque nada rolava por baixo dela antes.
## Ao fundir TOP_RECT+LIST_RECT num único scroll contínuo, conteúdo real
## (ex.: texto de Afinidade) passou a rolar por baixo dessa linha fixa,
## cortando o texto visualmente. Corrigido reservando essa mesma faixa
## como cabeçalho ESTÁTICO (só o retrato do Comandante, nunca rolável —
## reflete a intenção original da própria arte) e iniciando o
## ScrollContainer exatamente abaixo da linha, nunca por cima dela.
## 0.174 (fração exata da antiga TOP_RECT) deixava a 1ª linha do scroll
## tocando a linha decorativa; +0.03 de folga extra evita a sobreposição
## residual confirmada por screenshot.
const ARMY_HEADER_FRACTION: float = 0.205

func _build_detail_area(parent: Control) -> void:
	var area := _anchor_new_control(parent, ARMY_RECT)

	var header_area := _anchor_new_control(area, Rect2(0, 0, 1, ARMY_HEADER_FRACTION))
	var header_margin := MarginContainer.new()
	header_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_margin.add_theme_constant_override("margin_left", 6)
	header_margin.add_theme_constant_override("margin_right", 10)
	header_area.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header_margin.add_child(header_row)
	if _selected_commander != null:
		header_row.add_child(_make_portrait(_portrait_for(_selected_commander), COMMANDER_PORTRAIT_SIZE))
		var header_name_col := VBoxContainer.new()
		header_name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header_row.add_child(header_name_col)
		header_name_col.add_child(_make_label(_selected_commander.commander_name, 15, HUD_TEXT_COLOR))
		# "Função" é dado real (nunca inventado): ou já lidera o Exército
		# sendo editado, ou está livre formando um novo.
		var funcao_text: String = "Formando um novo Exército"
		if editing_composition and existing_army != null:
			var army_label: String = existing_army.army_name if existing_army.army_name != "" else "este Exército"
			funcao_text = "Liderando %s" % army_label
		header_name_col.add_child(_make_label("%s • %s" % [_selected_commander.faction, funcao_text], 9, HUD_MUTED_COLOR))
		var patente: String = CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp)
		header_name_col.add_child(_make_label("Patente: %s" % patente, 10, HUD_ACCENT_SELECTED))
	else:
		header_row.add_child(_make_centered_label("NENHUM COMANDANTE SELECIONADO", 11, HUD_MUTED_COLOR))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var scroll_area := _anchor_new_control(area, Rect2(0, ARMY_HEADER_FRACTION, 1, 1.0 - ARMY_HEADER_FRACTION))
	scroll_area.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(scroll)
	_style_scrollbar(scroll)
	_detail_scroll = scroll
	# call_deferred de propósito (ver docstring de _list_scroll) — o
	# conteúdo desta área ainda vai ser montado pelo resto desta função
	# (inclusive nos "return" antecipados abaixo), mas isso não importa:
	# o valor só é aplicado de verdade depois que o Godot processa o
	# layout inteiro deste frame.
	scroll.call_deferred("set", "scroll_vertical", _detail_scroll_position)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	if _random_army_message != "":
		vbox.add_child(_make_detail_wrap_label(_random_army_message, 11, HUD_ERROR_COLOR, false))
		vbox.add_child(_make_separator())

	if _selected_commander == null:
		vbox.add_child(_make_centered_label("ESCOLHA UM COMANDANTE", 12, HUD_ACCENT))
		vbox.add_child(_make_detail_wrap_label("Selecione um Comandante na Biblioteca, à direita, ou monte um Exército aleatoriamente nas ações abaixo.", 10, HUD_TEXT_COLOR, false))
		return

	# Hierarquia (reordenada — achado real da revalidação visual final da
	# FASE 22, pendência já registrada desde a Auditoria 22.1: com
	# Afinidade em 2+ Facções ativas, o bloco Soldo+Afinidade empurrava a
	# Formação pra fora da área visível sem rolar, contradizendo o
	# objetivo explícito do redesenho 22.3 de a Formação ser o elemento
	# DOMINANTE da coluna). Agora: QUAL a Doutrina -> QUAL Exército está
	# sendo montado (Formação, sempre visível primeiro) -> QUANTO pode
	# gastar/Afinidade (detalhe de apoio, abaixo). O Comandante em si
	# (QUEM) já está no cabeçalho estático acima, nunca duplicado aqui.
	if _selected_commander.doctrine != null:
		_build_doctrine_section(vbox)
		vbox.add_child(_make_separator())
	_build_formation_area(vbox)
	vbox.add_child(_make_separator())
	_build_soldo_panel(vbox)
	_build_affinity_section(vbox)
	vbox.add_child(_make_separator())
	_build_action_buttons(vbox)


## Cada campo da Doutrina como par LEGENDA (pequena, muda) + VALOR
## (maior, legível) — nunca mais "Restrição: X" tudo numa frase só. O
## "Bônus" (doctrine.value_description() — SSoT real, nunca calculado
## de novo aqui) ganha destaque de cor pra nunca mais passar
## despercebido: antes desta correção ele nem aparecia nesta tela.
func _build_doctrine_section(parent: Control) -> void:
	var doctrine: CommanderDoctrine = _selected_commander.doctrine
	parent.add_child(_make_centered_label("DOUTRINA", 12, HUD_ACCENT))

	_build_doctrine_field(parent, "Restrição", doctrine.restriction_description())
	_build_doctrine_field(parent, "Requisito", doctrine.requirement_description())

	var target_text: String = doctrine.target.description
	if doctrine.target.value != "":
		target_text += " (%s)" % doctrine.target.value
	_build_doctrine_field(parent, "Alvo", target_text)
	_build_doctrine_field(parent, "Efeito", doctrine.effect.description)
	_build_doctrine_field(parent, "Bônus", doctrine.value_description(), HUD_ACCENT_SELECTED, 14)


func _build_doctrine_field(parent: Control, caption: String, value_text: String, value_color: Color = HUD_TEXT_COLOR, font_size: int = 11) -> void:
	parent.add_child(_make_label(caption.to_upper(), 9, HUD_MUTED_COLOR))
	parent.add_child(_make_detail_wrap_label(value_text, font_size, value_color, false))


## Ajuda contextual mínima (correção FASE 22.2, item 22.2.11): título de
## seção + um pequeno indicador "(?)" com tooltip nativo do Godot
## (Control.tooltip_text — mais simples que o tooltip customizado usado
## pelas Cartas, suficiente pra uma frase curta). Nunca duplica
## documentação nem inventa números — cada texto descreve só o que já
## está confirmado em SOLDO.md/AFFINITY.md.
func _build_section_header_with_help(parent: Control, title: String, help_text: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	row.add_child(_make_label(title, 12, HUD_ACCENT))

	var info := _make_label("(?)", 10, HUD_MUTED_COLOR)
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info.mouse_default_cursor_shape = Control.CURSOR_HELP
	info.tooltip_text = help_text
	row.add_child(info)


func _build_soldo_panel(parent: Control) -> void:
	_build_section_header_with_help(parent, "SOLDO DO EXÉRCITO", "Soldo é o orçamento de manutenção do Exército. Cada Carta custa Soldo conforme sua Raridade; o Comandante tem um teto de Soldo que cresce com a Patente. A soma do custo das 9 Cartas nunca pode passar do teto.")

	var patente: String = CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp)
	var cap: int = Soldo.cap_for_patente(patente)
	var used: int = Soldo.total_for_composition(_selected_cards)
	var available: int = cap - used

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var center := CenterContainer.new()
	center.add_child(row)
	parent.add_child(center)

	row.add_child(_make_stat_chip("Utilizado", str(used)))
	row.add_child(_make_stat_chip("Máximo", str(cap)))
	row.add_child(_make_stat_chip("Disponível", str(maxi(available, 0)), HUD_ERROR_COLOR if available < 0 else HUD_TEXT_COLOR))

	parent.add_child(_make_centered_label("Cartas: %d / 9" % _selected_cards.size(), 11, HUD_ACCENT_SELECTED if _selected_cards.size() == 9 else HUD_MUTED_COLOR))


## Auditoria FASE 22.1, achado A: Afinidade nunca aparecia no Editor —
## jogador só descobria o efeito mais relevante de composição por
## Facção dentro do próprio combate. Reaproveita Affinity.
## calculate_points()/highest_active_level() (engine/combat/affinity.gd,
## AFFINITY.md) — lógica pura já compartilhada com o Motor de Combate,
## nunca recalculada ou duplicada aqui. Mostra só Facções realmente
## presentes na composição atual (Cartas selecionadas + Comandante),
## nunca as 3 Facções fixas do jogo. Retorna false (nada desenhado)
## quando ainda não há nenhuma Carta/Comandante — chamador decide se
## desenha o separador seguinte.
func _build_affinity_section(parent: Control) -> bool:
	var factions_present: Array[String] = []
	for card: CardResource in _selected_cards:
		if not factions_present.has(card.faction):
			factions_present.append(card.faction)
	if _selected_commander != null and not factions_present.has(_selected_commander.faction):
		factions_present.append(_selected_commander.faction)

	if factions_present.is_empty():
		return false

	_build_section_header_with_help(parent, "AFINIDADE", "Cada Pelotão (e o Comandante, se da mesma Facção) concede 1 ponto de Afinidade à sua Facção. Ao atingir certos totais, a Facção ativa Níveis de Afinidade cumulativos, cada um com um efeito real em combate.")

	# Correção FASE 22.2 (revisão visual): 1 bloco visualmente distinto
	# por Facção (título da Facção em destaque, depois pontos/Nível numa
	# linha própria, depois cada consequência com "✓"), separado das
	# demais Facções por _make_separator() — nunca mais uma única linha
	# corrida "Facção — N pontos (Nível X)". A consequência real
	# continua vindo de Affinity.active_effects() lendo
	# GameDatabase.affinity_levels — o MESMO catálogo (.tres em
	# res://database/affinity/) cujo texto já bate exatamente com a
	# lógica aplicada de verdade em affinity_runtime.gd (conferido: o
	# texto de Afinidade II do Império aqui é literalmente o mesmo "20%
	# menos dano" que affinity_runtime.gd aplica). Nunca uma tabela nova,
	# nunca um resumo inventado — cada Nível cumulativo ativo
	# (AFFINITY.md, "Progressão Cumulativa") gera sua própria linha,
	# nunca só o Nível mais alto.
	for i in range(factions_present.size()):
		var faction: String = factions_present[i]
		var points: int = Affinity.calculate_points(faction, _selected_cards, _selected_commander)
		var level: int = Affinity.highest_active_level(points)
		var level_text: String = "Nível %d ativo" % level if level > 0 else "Nenhum Nível ativo"

		parent.add_child(_make_centered_label(faction.to_upper(), 12, HUD_TEXT_COLOR))
		parent.add_child(_make_centered_label("%d ponto(s) de Afinidade" % points, 10, HUD_MUTED_COLOR))
		parent.add_child(_make_centered_label(level_text, 11, HUD_ACCENT_SELECTED if level > 0 else HUD_MUTED_COLOR))

		var effects: Array[AffinityLevelResource] = Affinity.active_effects(faction, points, GameDatabase.affinity_levels)
		for effect: AffinityLevelResource in effects:
			parent.add_child(_make_detail_wrap_label("✓ %s" % effect.effect_description, 10, HUD_TEXT_COLOR, false))

		if i < factions_present.size() - 1:
			parent.add_child(_make_separator())

	return true


func _build_formation_area(parent: Control) -> void:
	parent.add_child(_make_centered_label("FORMAÇÃO DE COMBATE", 12, HUD_ACCENT))
	# Correção FASE 22.2 (revisão de UX): uma única linha "passe o mouse"
	# fazia o jogador descobrir 1/5/9 só por acaso. Legenda curta e
	# persistente (nunca um texto longo) nomeia as 3 posições — o texto
	# completo de cada regra (nunca inventado) continua só no tooltip de
	# _position_special_note(). O contorno dourado nos 3 slots
	# (_build_formation_slot()) reforça visualmente o mesmo destaque sem
	# depender de hover.
	# Correção FASE 22.2 (achado real via screenshot + rastreamento de
	# vbox.get_combined_minimum_size(), ver docstring de
	# _make_detail_wrap_label()): 3 posições lado a lado numa
	# HBoxContainer, mais o texto "wrap=true" sem largura explícita,
	# causavam o bug de quebra letra-por-letra do Godot (Label
	# autowrap numa VBoxContainer recém-criada, ainda sem largura
	# resolvida) — inflava a altura mínima da seção em milhares de
	# pixels e arrastava a largura de toda a coluna junto (causa raiz
	# real do texto cortado em toda a coluna, ex.: "COMANDANTE" virando
	# "COMANDAN"). Empilhado verticalmente, cada item usando
	# _make_detail_wrap_label() (wrap + largura explícita, mesma técnica
	# já usada por _make_tooltip_label() nos tooltips das Cartas).
	for position_number: int in [1, 5, 9]:
		parent.add_child(_make_detail_wrap_label("%d — %s" % [position_number, _position_short_label(position_number)], 9, HUD_ACCENT))
	parent.add_child(_make_detail_wrap_label("Passe o mouse sobre uma posição especial para ver a regra completa.", 8, HUD_MUTED_COLOR))

	if formation_count > 1 and _army != null:
		var tabs_center := CenterContainer.new()
		parent.add_child(tabs_center)
		var tabs_row := HBoxContainer.new()
		tabs_row.add_theme_constant_override("separation", 4)
		tabs_center.add_child(tabs_row)
		for formation_name: String in FORMATION_NAMES.slice(0, formation_count):
			var tab_button := _make_tab_button(formation_name, formation_name == _current_formation, 38.0)
			tab_button.pressed.connect(_on_formation_tab_pressed.bind(formation_name), CONNECT_DEFERRED)
			tabs_row.add_child(tab_button)

	var grid_center := CenterContainer.new()
	parent.add_child(grid_center)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid_center.add_child(grid)

	var current_cards: Array[CardResource] = _current_grid_source()
	for visual_index: int in [0, 1, 2, 5, 4, 3, 6, 7, 8]:
		grid.add_child(_build_formation_slot(current_cards, visual_index))


func _on_formation_tab_pressed(formation_name: String) -> void:
	_current_formation = formation_name
	_rebuild_detail_content()


func _current_grid_source() -> Array[CardResource]:
	if _army != null:
		return _formation_cards[_current_formation]
	return _phase1_slots


func _build_formation_slot(current_cards: Array[CardResource], slot_index: int) -> Control:
	var position_number: int = slot_index + 1
	var card: CardResource = current_cards[slot_index]

	var slot := ArmyCardSlot.new()
	slot.custom_minimum_size = Vector2(FORMATION_CARD_WIDTH, FORMATION_CARD_WIDTH / BattleCardView.CARD_ASPECT_RATIO)
	slot.can_drop_checker = func(data: Variant) -> bool: return _can_drop_on_slot(data, slot_index)
	slot.drop_handler = func(data: Variant) -> void: _handle_drop_on_slot(data, slot_index)

	# Correção FASE 22.2: destaque visual PERSISTENTE das posições 1/5/9
	# (nunca só descobrível por hover, pedido explícito) — contorno mais
	# grosso e na cor de destaque do HUD, preenchido ou vazio.
	var is_special_position: bool = _position_special_note(position_number) != ""

	if card == null:
		var placeholder := Panel.new()
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var placeholder_style := StyleBoxFlat.new()
		placeholder_style.bg_color = Color(0, 0, 0, 0.25)
		placeholder_style.border_width_left = 2 if is_special_position else 1
		placeholder_style.border_width_right = 2 if is_special_position else 1
		placeholder_style.border_width_top = 2 if is_special_position else 1
		placeholder_style.border_width_bottom = 2 if is_special_position else 1
		placeholder_style.border_color = HUD_ACCENT if is_special_position else Color(HUD_MUTED_COLOR.r, HUD_MUTED_COLOR.g, HUD_MUTED_COLOR.b, 0.5)
		placeholder_style.corner_radius_top_left = 4
		placeholder_style.corner_radius_top_right = 4
		placeholder_style.corner_radius_bottom_left = 4
		placeholder_style.corner_radius_bottom_right = 4
		placeholder.add_theme_stylebox_override("panel", placeholder_style)
		slot.add_child(placeholder)

		var position_label := _make_centered_label(str(position_number), 11, HUD_MUTED_COLOR)
		position_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		position_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(position_label)
		# Auditoria FASE 22.1, achado C: mesmo vazia, uma posição especial
		# (1/5/9) já pode ser explicada — o jogador não precisa esperar
		# ocupá-la para entender por que ela é diferente.
		if _position_special_note(position_number) != "":
			slot.set_tooltip_builder(func() -> Control: return _build_position_hint_tooltip(position_number))
		# Correção FASE 22: mesmo vazio, o slot reserva a mesma altura de
		# rodapé que um slot preenchido — sem isso, o GridContainer
		# esticava cada linha pelo cell mais alto (com rodapé) e deixava
		# um vão vazio desalinhado embaixo dos slots ainda sem carta.
		return _wrap_formation_slot(slot, null)

	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_formation_slot_gui_input.bind(slot_index), CONNECT_DEFERRED)
	slot.set_tooltip_builder(func() -> Control: return _build_card_tooltip(card, position_number))
	slot.drag_data_builder = func() -> Variant: return {"source": "slot", "slot_index": slot_index}
	slot.drag_preview_builder = func() -> Control: return _build_drag_preview(card)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(true)
	_force_ignore_mouse_recursive(card_view)

	if is_special_position:
		var special_border := Panel.new()
		special_border.set_anchors_preset(Control.PRESET_FULL_RECT)
		special_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var special_border_style := StyleBoxFlat.new()
		special_border_style.bg_color = Color(0, 0, 0, 0)
		special_border_style.border_width_left = 2
		special_border_style.border_width_right = 2
		special_border_style.border_width_top = 2
		special_border_style.border_width_bottom = 2
		special_border_style.border_color = HUD_ACCENT
		special_border_style.corner_radius_top_left = 4
		special_border_style.corner_radius_top_right = 4
		special_border_style.corner_radius_bottom_left = 4
		special_border_style.corner_radius_bottom_right = 4
		special_border.add_theme_stylebox_override("panel", special_border_style)
		slot.add_child(special_border)

	return _wrap_formation_slot(slot, card)


## Correção FASE 22: anexa a barra de Energia/Soldo (_make_composition_footer)
## logo abaixo do ArmyCardSlot real, sempre na mesma altura reservada
## (com carta ou não) — "slot" continua sendo o alvo de clique/Drag-and-
## Drop/tooltip, nunca substituído; o wrapper existe só para o layout.
func _wrap_formation_slot(slot: ArmyCardSlot, card: CardResource) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.add_child(slot)
	if card != null:
		wrapper.add_child(_make_composition_footer(card))
	else:
		wrapper.add_child(_make_empty_composition_footer())
	return wrapper


## Mesma altura/estilo de _make_composition_footer(), sem valores — só
## para o slot vazio ocupar exatamente a mesma altura de um slot
## preenchido (ver _wrap_formation_slot()).
func _make_empty_composition_footer() -> Control:
	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 20.0)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.5)
	style.border_width_top = 1
	style.border_color = Color(HUD_MUTED_COLOR.r, HUD_MUTED_COLOR.g, HUD_MUTED_COLOR.b, 0.4)
	footer.add_theme_stylebox_override("panel", style)
	return footer


## Mesma causa-raiz de _on_list_card_gui_input (ver docstring lá) —
## reage em "solto", nunca em "pressionado", pro Drag-and-Drop entre
## posições da Formação ter a chance de iniciar.
func _on_formation_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_formation_slot_clicked(slot_index)


## Clicar (sem arrastar) numa posição ocupada da Fase 1 remove aquela
## Carta do Exército (mesma ação de clicar nela na lista) — depois de
## Montar/Salvar a composição está travada, só o arrasto reposiciona.
func _on_formation_slot_clicked(slot_index: int) -> void:
	if _army != null:
		return
	var card: CardResource = _phase1_slots[slot_index]
	if card == null:
		return
	_on_card_toggled(false, card)
	_phase1_slots[slot_index] = null
	_refresh_all()


## --- Drag-and-Drop: só compõe operações REAIS já existentes
## (_on_card_toggled para adicionar/remover da composição,
## _on_slot_card_selected para trocar posições dentro dos 9 já
## escolhidos) — nunca uma regra nova. ---

## Junto com _place_in_first_empty_phase1_slot() e o Gate de Suporte
## abaixo, reaproveita as MESMAS duas regras estruturais (nunca uma nova
## cópia): Máquina de Guerra só na Posição 9 (índice 8 — COMBAT_RULES.md
## 6.6, mesma convenção de CombatEngine._place_army()/
## ArmyFormationArchetypes._extract_machine()) e Suporte nunca na Posição
## 5 (COMBAT_RULES.md 6.5, via Army.would_have_support_at_position_5() —
## o mesmo método que a Engine usa, nunca reimplementado aqui).
func _can_drop_on_slot(data: Variant, slot_index: int) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("source"):
		return false

	if _army != null:
		# Pós-Montar/Salvar: composição travada, só reposicionar entre
		# slots da MESMA Formação (COMBAT_RULES.md, "Formações") — ainda
		# sujeito às duas regras estruturais acima, válidas em toda
		# Formação (α/β/γ/δ/ε), não só na escolha inicial.
		if data["source"] != "slot":
			return false
		var from_index: int = data["slot_index"]
		if from_index == slot_index:
			return true
		var current_cards: Array[CardResource] = _formation_cards[_current_formation]
		var card_a: CardResource = current_cards[from_index]
		var card_b: CardResource = current_cards[slot_index]
		if (card_a != null and card_a.card_class == "Máquina de Guerra") or (card_b != null and card_b.card_class == "Máquina de Guerra"):
			return false
		var projected_formation: Array[CardResource] = current_cards.duplicate()
		projected_formation[slot_index] = card_a
		projected_formation[from_index] = card_b
		return not _would_result_in_support_at_position_5(projected_formation)

	if data["source"] == "slot":
		var from_index: int = data["slot_index"]
		if from_index == slot_index:
			return true
		var card_a: CardResource = _phase1_slots[from_index]
		var card_b: CardResource = _phase1_slots[slot_index]
		if (card_a != null and card_a.card_class == "Máquina de Guerra") or (card_b != null and card_b.card_class == "Máquina de Guerra"):
			return false  # Posição 9 é reservada, não se abre mão dela num swap
		var projected_slots: Array[CardResource] = _phase1_slots.duplicate()
		projected_slots[slot_index] = card_a
		projected_slots[from_index] = card_b
		return not _would_result_in_support_at_position_5(projected_slots)

	var card: CardResource = data.get("card")
	if card == null:
		return false

	if card.card_class == "Máquina de Guerra" and slot_index != 8:
		return false  # Máquina de Guerra só pode ocupar a Posição 9
	var occupant: CardResource = _phase1_slots[slot_index]
	if slot_index == 8 and occupant != null and occupant.card_class == "Máquina de Guerra" and card.card_class != "Máquina de Guerra":
		return false  # não desaloja a Máquina da Posição 9 por uma carta comum

	if _selected_cards.has(card):
		var from_index: int = _phase1_slots.find(card)
		var projected_slots2: Array[CardResource] = _phase1_slots.duplicate()
		projected_slots2[slot_index] = card
		if from_index != -1 and from_index != slot_index:
			projected_slots2[from_index] = occupant
		return not _would_result_in_support_at_position_5(projected_slots2)  # já escolhida -> mover pra outro slot

	var projected: Array[CardResource] = _selected_cards.duplicate()
	if occupant != null:
		projected.erase(occupant)

	for selected: CardResource in projected:
		if selected.card_name == card.card_name:
			return false  # ARMY.md, "Unicidade de Composição"
	if projected.size() >= 9:
		return false

	if _selected_commander != null:
		var patente: String = CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp)
		var cap: int = Soldo.cap_for_patente(patente)
		if Soldo.total_for_composition(projected) + Soldo.cost_for_rarity(card.rarity) > cap:
			return false  # SOLDO.md, teto de Soldo da Patente

	var projected_slots3: Array[CardResource] = _phase1_slots.duplicate()
	projected_slots3[slot_index] = card
	if _would_result_in_support_at_position_5(projected_slots3):
		return false

	return true


## Monta o Array candidato (ignorando slots ainda vazios, preservando
## ordem) e delega pro MESMO método que Army/CombatEngine usam pra decidir
## Posição 5 — nunca uma segunda cópia da regra (COMBAT_RULES.md 6.5).
func _would_result_in_support_at_position_5(candidate_slots: Array[CardResource]) -> bool:
	var filled: Array[CardResource] = []
	for card: CardResource in candidate_slots:
		if card != null:
			filled.append(card)
	return Army.would_have_support_at_position_5(filled)


func _handle_drop_on_slot(data: Variant, slot_index: int) -> void:
	if _army != null:
		if data["source"] == "slot":
			var from_index: int = data["slot_index"]
			if from_index != slot_index:
				_on_slot_card_selected(from_index, slot_index)
		_rebuild_detail_content()
		return

	if data["source"] == "slot":
		var from_index: int = data["slot_index"]
		if from_index != slot_index:
			var temp: CardResource = _phase1_slots[slot_index]
			_phase1_slots[slot_index] = _phase1_slots[from_index]
			_phase1_slots[from_index] = temp
		_refresh_all()
		return

	var card: CardResource = data["card"]
	if _selected_cards.has(card):
		var from_index: int = _phase1_slots.find(card)
		if from_index != -1 and from_index != slot_index:
			var temp2: CardResource = _phase1_slots[slot_index]
			_phase1_slots[slot_index] = card
			_phase1_slots[from_index] = temp2
		elif from_index == -1:
			_phase1_slots[slot_index] = card
		_refresh_all()
		return

	var occupant: CardResource = _phase1_slots[slot_index]
	if occupant != null:
		_on_card_toggled(false, occupant)
	_on_card_toggled(true, card)
	_phase1_slots[slot_index] = card
	_refresh_all()


## GAP ARQUITETURAL CORRIGIDO NESTA ETAPA — mais crítico que o pedido
## original: CombatEngine._place_army() (chamado ao iniciar QUALQUER
## batalha) extrai a PRIMEIRA carta de Classe "Máquina de Guerra" de
## Army.cards e a força pra Posição 9 incondicionalmente, deslocando
## todas as cartas seguintes — INDEPENDENTE de onde ela estivesse no
## Array (COMBAT_RULES.md 6.6, confirmado lendo combat_engine.gd:157-176
## e army_formation_archetypes.gd:143-150, mesma convenção nos dois).
## O Editor, porém, deixava o jogador arrastar uma Máquina de Guerra pra
## QUALQUER slot da grade 3x3 e gravava exatamente essa ordem em
## Army.cards — a tela mostrava uma formação que a batalha nunca
## respeitaria de verdade (a Máquina "pularia" pra Posição 9 e tudo
## depois dela deslizaria uma posição, na cara do jogador, parecendo um
## "bug de movimento" sem ligação nenhuma com a Fase de Avanço real).
## Corrigido na origem certa (Editor, sem tocar CombatEngine/Army): a
## Máquina de Guerra agora só pode existir no slot 8 (Posição 9) — nunca
## uma segunda regra de posicionamento, só a MESMA já usada pelo motor.
func _place_in_first_empty_phase1_slot(card: CardResource) -> void:
	# "e slot 8 ainda não é Máquina": ARMY.md só proíbe repetir NOME, não
	# Classe — uma 2ª Máquina de Guerra (nome diferente) é tratada pelo
	# próprio CombatEngine._place_army() como carta comum (só a PRIMEIRA
	# encontrada é especial). Sem esta guarda, duas Máquinas disputando o
	# slot 8 recursariam infinitamente uma tentando deslocar a outra.
	var slot_8_is_machine: bool = _phase1_slots[8] != null and _phase1_slots[8].card_class == "Máquina de Guerra"
	if card.card_class == "Máquina de Guerra" and not slot_8_is_machine:
		var displaced: CardResource = _phase1_slots[8]
		_phase1_slots[8] = card
		if displaced != null:
			_place_in_first_empty_phase1_slot(displaced)
		return

	# GAP idêntico ao da Máquina, mas pro clique (COMBAT_RULES.md 6.5): sem
	# esta guarda, escolher Cartas na ordem "certa" podia deixar a Posição
	# 5 (índice 4) como primeira vaga livre bem na hora de clicar num
	# Suporte, violando a regra sem passar por nenhum arrasto — o mesmo
	# Array/regra de _can_drop_on_slot(), nunca uma checagem nova. Só entra
	# no índice 4 se ele for a ÚNICA vaga restante (nesse caso, o Gate
	# final em _build_action_buttons barra "Montar Exército" até o jogador
	# resolver arrastando — arrasto já sabe corrigir isso).
	if card.card_class == "Suporte" and _phase1_slots[4] == null:
		for i in range(9):
			if i == 4:
				continue
			if _phase1_slots[i] == null:
				_phase1_slots[i] = card
				return
		_phase1_slots[4] = card
		return

	for i in range(9):
		if _phase1_slots[i] == null:
			_phase1_slots[i] = card
			return


func _remove_from_phase1_slots(card: CardResource) -> void:
	for i in range(9):
		if _phase1_slots[i] == card:
			_phase1_slots[i] = null
			return


## --- Prévia ampliada (hover) — MUDANÇA DE UX (pedido explícito):
## nunca mais uma ficha textual numa caixa preta. Agora é a CARTA REAL
## ampliada — mesmo BattleCardView/CardArtCatalog/CardResource usados
## em qualquer outro lugar do jogo, em modo NÃO-compacto (arte real +
## Tier/Tipo+Classe/ATK/ESC/HP desenhados por cima, exatamente como
## BattleCardView já faz — Nome/Facção/Raridade/texto de Habilidade já
## vêm na própria arte, nunca redesenhados). Característica/Habilidade
## III/V/Receita continuam abaixo da carta como legenda curta — são os
## únicos campos reais que a arte estática NUNCA desenha (Tier é
## mutável por cópia; a Habilidade só é desbloqueada em Tiers mais
## altos, então a arte de uma carta Tier I nunca a mostra) — nunca uma
## 2ª ficha textual competindo com a arte, só o complemento que falta.
##
## Hover nativo do Godot (_make_custom_tooltip via ArmyCardSlot) nunca
## atrapalha Clique/Drag-and-Drop — o próprio motor suspende o tooltip
## assim que um arrasto começa, e independente disso.
##
## Responsivo (nunca uma altura/largura fixa): a carta ampliada usa uma
## fração da viewport (largura E altura, o menor dos dois, preservando
## a proporção real de BattleCardView.CARD_ASPECT_RATIO — nunca
## distorce nem corta). A legenda abaixo mede a própria altura natural
## (mesma técnica já usada antes: medir só depois de cada Label já ter
## largura própria, nunca depender do ancestral) e só ganha um teto de
## viewport se o conteúdo for excepcionalmente longo.
const _PREVIEW_MAX_WIDTH: float = 220.0
const _PREVIEW_CAPTION_MAX_HEIGHT_FRACTION: float = 0.35


## Auditoria FASE 22.1, achado C: Posições 1/5/9 nunca eram explicadas.
## Texto sempre extraído de regra já confirmada em COMBAT_RULES.md —
## nunca uma vantagem inventada. Posição 1: bônus estrutural universal
## por Classe (6.1/6.2, independente de qual arquétipo de Formação está
## ativo). Posição 5: Penalidade de Reorganização (5.2.2) só se aplica a
## quem CHEGA ali avançando em combate, nunca a quem já começa
## posicionado ali — o texto é deliberadamente condicional, nunca afirma
## que a Carta nesta posição "sofre" a penalidade agora. Posição 9:
## posicionamento inicial obrigatório da Máquina de Guerra (6.6).
## Rótulo curto para a legenda persistente (_build_formation_area()) —
## resumo do mesmo texto de _position_special_note(), nunca uma regra
## diferente. Vazio para posições sem regra especial.
func _position_short_label(position_number: int) -> String:
	match position_number:
		1:
			return "Linha de Frente"
		5:
			return "Reorganização"
		9:
			return "Máquina de Guerra"
		_:
			return ""


func _position_special_note(position_number: int) -> String:
	match position_number:
		1:
			return "Posição 1 — Linha de Frente: pelotões de Classe Corpo a Corpo recebem aqui +50% de Ataque; pelotões de Classe Barreira recebem +50% de Escudo Base."
		5:
			return "Posição 5 — Centro: um pelotão que CHEGAR aqui avançando durante a batalha entra em Reorganização e não pode agir naquele turno. Não se aplica a quem já começa a batalha nesta posição."
		9:
			return "Posição 9 — Retaguarda: toda Máquina de Guerra deve começar obrigatoriamente aqui. Depois do início do combate, ela se movimenta normalmente."
		_:
			return ""


## Tooltip só de texto para uma posição especial ainda VAZIA — mesmo
## painel/fonte do resto do Editor, sem a Carta (que ainda não existe
## nesse slot). Nunca chamado para posições sem regra especial.
func _build_position_hint_tooltip(position_number: int) -> Control:
	var panel := _make_card_panel()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	vbox.add_child(_make_tooltip_label(_position_special_note(position_number), 10, HUD_TEXT_COLOR, 200.0, false))
	return panel


func _build_card_tooltip(card: CardResource, position_number: int = 0) -> Control:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width_by_viewport_w: float = viewport_size.x * 0.22
	var width_by_viewport_h: float = viewport_size.y * 0.5 * BattleCardView.CARD_ASPECT_RATIO
	var card_width: float = minf(_PREVIEW_MAX_WIDTH, minf(width_by_viewport_w, width_by_viewport_h))

	var panel := _make_card_panel()

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 4)
	panel.add_child(outer_vbox)

	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(card_width, card_width / BattleCardView.CARD_ASPECT_RATIO)
	outer_vbox.add_child(card_slot)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(false)  # arte real + Tier/Tipo+Classe/ATK/ESC/HP, nunca uma 2ª versão simplificada
	_force_ignore_mouse_recursive(card_view)

	# Correção FASE 22, item 6 (Carta ampliada/hover): mesma barra de
	# Energia/Soldo da lista/Formação, mesma hierarquia estrutural —
	# nunca uma versão conceitualmente diferente da carta ampliada.
	outer_vbox.add_child(_make_composition_footer(card))

	var caption_vbox := VBoxContainer.new()
	caption_vbox.add_theme_constant_override("separation", 3)
	caption_vbox.custom_minimum_size.x = card_width

	# Auditoria FASE 22.1, achado C — nota da posição especial (1/5/9),
	# só quando esta Carta está de fato numa Formação (position_number >
	# 0; a lista de seleção nunca passa isso, card_width é reaproveitado
	# como largura da legenda, mesma técnica do resto desta função).
	var position_note: String = _position_special_note(position_number)
	if position_note != "":
		caption_vbox.add_child(_make_tooltip_label(position_note, 10, HUD_ACCENT_SELECTED, card_width, false))

	# Auditoria FASE 22.1, achado D — explicação progressiva da Máquina
	# de Guerra: só aparece quando o jogador já a possui/seleciona (nunca
	# antes, nunca poluindo cartas de outras Classes). COMBAT_RULES.md 6.6.
	if card.card_class == "Máquina de Guerra":
		caption_vbox.add_child(_make_tooltip_label("Máquina de Guerra: deve começar a batalha na Posição 9. Depois disso, movimenta-se normalmente e age conforme seu comportamento único (ver descrição acima).", 9, HUD_TEXT_COLOR, card_width, false))

	if card.tier_1_trait_name != "":
		caption_vbox.add_child(_make_tooltip_label("Característica: %s" % card.tier_1_trait_name, 10, HUD_ACCENT, card_width, false))
		var trait_entry: UnitTraitResource = GameDatabase.traits_by_name.get(card.tier_1_trait_name)
		if trait_entry != null and trait_entry.base_effect_description != "":
			caption_vbox.add_child(_make_tooltip_label(trait_entry.base_effect_description, 9, HUD_TEXT_COLOR, card_width, false))

	var ability_slots: Array = [
		["Habilidade (Tier III)", card.tier_3_ability_name],
		["Habilidade (Tier V)", card.tier_5_ability_name],
	]
	for slot: Array in ability_slots:
		var ability_name: String = slot[1]
		if ability_name == "":
			continue
		caption_vbox.add_child(_make_tooltip_label("%s: %s" % [slot[0], ability_name], 10, HUD_ACCENT, card_width, false))
		var ability: AbilityResource = GameDatabase.abilities_by_name.get(ability_name)
		if ability != null and ability.effect_description != "":
			caption_vbox.add_child(_make_tooltip_label(ability.effect_description, 9, HUD_TEXT_COLOR, card_width, false))

	if not card.recipe_ingredients.is_empty():
		caption_vbox.add_child(_make_tooltip_label("Receita: %s" % ", ".join(card.recipe_ingredients), 9, HUD_MUTED_COLOR, card_width, false))

	if caption_vbox.get_child_count() > 0:
		outer_vbox.add_child(_make_separator())
		# Mesma técnica de antes: só mede depois de cada Label já ter
		# largura própria — nunca depende do ancestral ainda não
		# resolvido (causa raiz do painel gigantesco já corrigida).
		var natural_caption_height: float = caption_vbox.get_combined_minimum_size().y
		var caption_scroll := ScrollContainer.new()
		caption_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		caption_scroll.custom_minimum_size = Vector2(card_width, minf(natural_caption_height, viewport_size.y * _PREVIEW_CAPTION_MAX_HEIGHT_FRACTION))
		outer_vbox.add_child(caption_scroll)
		caption_scroll.add_child(caption_vbox)

	return panel


## Legenda complementar (nunca a carta inteira) — largura própria
## explícita, mesma defesa de sempre contra o Label quebrar linha antes
## do ancestral ter largura resolvida.
func _make_tooltip_label(text: String, font_size: int, color: Color, width: float, centered: bool = true) -> Label:
	var label := _make_label(text, font_size, color, true)
	label.custom_minimum_size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	return label


func _build_drag_preview(card: CardResource) -> Control:
	var preview_width: float = 64.0
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(preview_width, preview_width / BattleCardView.CARD_ASPECT_RATIO)
	slot.modulate = Color(1, 1, 1, 0.85)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(true)
	_force_ignore_mouse_recursive(card_view)
	return slot


## --- Botões de ação. ---

## Correção FASE 22.2 (achado real via rastreamento de tamanho mínimo):
## "Cancelar" + "Confirmar Exército"/"Salvar Alterações" lado a lado
## (HBoxContainer) empurravam a largura mínima da coluna (~265px) além
## do orçamento real (~218px úteis) — textos de botão não quebram linha
## de forma legível, então a correção é empilhar verticalmente
## (VBoxContainer) em vez de forçar lado a lado numa coluna estreita.
func _build_action_buttons(parent: Control) -> void:
	parent.add_child(_make_centered_label("AÇÕES", 12, HUD_ACCENT))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(col)

	# Correção FASE 22.3 (item A.9/A.10): "Criar Exército Aleatório" saiu
	# da faixa de abas (competia visualmente com Comandante/Pelotão) e
	# virou ação SECUNDÁRIA aqui, junto de Cancelar/Salvar — nunca mais
	# competindo pela atenção com a Formação. Mesma condição de sempre:
	# só faz sentido antes de "Montar"/"Salvar" já ter travado a
	# composição (_army == null).
	if _army == null:
		var random_button := _make_small_button("Montar Aleatoriamente")
		random_button.pressed.connect(_on_random_army_pressed, CONNECT_DEFERRED)
		col.add_child(random_button)

	var cancel_button := _make_small_button("Cancelar")
	cancel_button.pressed.connect(_on_cancel_pressed, CONNECT_DEFERRED)
	col.add_child(cancel_button)

	if _army == null:
		var commit_text: String = "Salvar Alterações" if (editing_composition and existing_army != null) else "Montar Exército"
		var commit_button := _make_primary_button(commit_text)
		# BUG REAL CONFIRMADO (auditoria desta etapa, seção "Bugs do
		# Comandante"): trocar de Comandante DEPOIS de já ter escolhido 9
		# Cartas nunca revalidava o Soldo contra o teto do novo Comandante
		# — as Cartas continuavam marcadas "Selecionada" (o bloqueio por
		# Soldo só se aplica a Cartas AINDA NÃO escolhidas) e este botão só
		# checava a CONTAGEM (== 9), nunca o Soldo. Kingdom.form_army()
		# também não valida Soldo (só ownership/estado — confirmado lendo
		# kingdom.gd) — nada mais no sistema impediria formar um Exército
		# acima do teto. Corrigido aqui, no mesmo lugar que já bloqueia por
		# contagem — nenhuma regra de Soldo nova, só a checagem que faltava
		# no gate final.
		var over_budget: bool = _selected_commander != null and Soldo.total_for_composition(_selected_cards) > Soldo.cap_for_patente(CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp))
		# Rede de segurança final (COMBAT_RULES.md 6.5) — na prática nunca
		# deveria disparar, já que _can_drop_on_slot()/
		# _place_in_first_empty_phase1_slot() impedem esse estado em toda
		# via de entrada; mantido aqui só como último Gate antes de
		# Kingdom.form_army()/re_form_army(), reaproveitando o mesmo
		# Array que de fato vira Army.cards (_resolved_alpha_order()).
		var invalid_support: bool = Army.would_have_support_at_position_5(_resolved_alpha_order())
		commit_button.disabled = _selected_commander == null or _selected_cards.size() != 9 or over_budget or invalid_support
		commit_button.pressed.connect(_on_montar_pressed, CONNECT_DEFERRED)
		col.add_child(commit_button)
	else:
		var confirm_button := _make_primary_button("Confirmar Exército")
		confirm_button.pressed.connect(_on_concluir_pressed, CONNECT_DEFERRED)
		col.add_child(confirm_button)


## --- Contrato preservado: mesma lógica funcional de antes,
## byte-a-byte, só a reconstrução visual no fim de cada função mudou. ---

## ARMY.md, "Unicidade de Composição": nunca duas Cartas com o mesmo
## Nome no Exército, independente do Tier.
func _on_card_toggled(pressed: bool, card: CardResource) -> void:
	_random_army_message = ""
	if pressed:
		var already_has_same_name: bool = false
		for selected: CardResource in _selected_cards:
			if selected != card and selected.card_name == card.card_name:
				already_has_same_name = true
		if not _selected_cards.has(card) and _selected_cards.size() < 9 and not already_has_same_name:
			_selected_cards.append(card)
			_place_in_first_empty_phase1_slot(card)
	else:
		_selected_cards.erase(card)
		_remove_from_phase1_slots(card)
	_refresh_all()


func _on_montar_pressed() -> void:
	if _selected_commander == null or _selected_cards.size() != 9:
		return

	if sandbox_mode:
		# Campo de Prova: nunca toca Kingdom.form_army()/re_form_army() —
		# reaproveita "existing_army" como o mesmo objeto (se houver, ex:
		# reabrindo o Editor sobre um Army de teste já gerado) ou cria um
		# Army solto, nunca registrado em Kingdom.armies.
		_army = existing_army if existing_army != null else Army.new()
		_army.commander = _selected_commander
		_army.cards = _selected_cards.duplicate()
	elif editing_composition and existing_army != null:
		KingdomState.kingdom.re_form_army(existing_army, _selected_commander, _selected_cards.duplicate())
		_army = existing_army
	else:
		_army = KingdomState.kingdom.form_army(_selected_commander, _selected_cards.duplicate())

	# "α" usa o posicionamento que o jogador já arrastou na Fase 1
	# (_phase1_slots) quando ele existe e bate com _selected_cards;
	# cai de volta pra _selected_cards.duplicate() (comportamento
	# original) quando _phase1_slots não foi tocado — ver
	# _resolved_alpha_order().
	_formation_cards["α"] = _resolved_alpha_order()
	for i in range(1, formation_count):
		var formation_name: String = FORMATION_NAMES[i]
		_formation_cards[formation_name] = _army.formations[formation_name] if _army.formations.has(formation_name) else _selected_cards.duplicate()

	_current_formation = "α"
	# Composição travada a partir daqui — some a escolha de Comandante/
	# Cartas (mesmo estado visual de _start_formation_edit_mode()), só a
	# Formação continua editável. Sem isto, clicar num Comandante/Carta
	# diferente na lista ainda visível reescreveria _selected_commander/
	# _selected_cards sem nunca re-executar Kingdom.form_army()/
	# re_form_army() — o Exército já formado ficaria dessincronizado do
	# que a tela mostra.
	_commander_option.visible = false
	_refresh_all()


func _resolved_alpha_order() -> Array[CardResource]:
	var filled: Array[CardResource] = []
	for card: CardResource in _phase1_slots:
		if card != null:
			filled.append(card)
	if filled.size() == _selected_cards.size():
		var matches: bool = true
		for card: CardResource in _selected_cards:
			if not filled.has(card):
				matches = false
				break
		if matches:
			return filled
	return _selected_cards.duplicate()


## Troca (swap) o conteúdo de "slot_index" com quem estiver atualmente
## na posição escolhida — nunca deixa a Formação num estado inválido.
func _on_slot_card_selected(new_card_index: int, slot_index: int) -> void:
	var current_cards: Array[CardResource] = _formation_cards[_current_formation]
	var temp: CardResource = current_cards[slot_index]
	current_cards[slot_index] = current_cards[new_card_index]
	current_cards[new_card_index] = temp


func _on_concluir_pressed() -> void:
	_army.cards = _formation_cards["α"]
	for formation_name: String in _formation_cards:
		if formation_name == "α":
			continue
		_army.formations[formation_name] = _formation_cards[formation_name]
	army_ready.emit(_army)


func _on_cancel_pressed() -> void:
	if _army != null and existing_army == null and not sandbox_mode:
		KingdomState.kingdom.disband_army(_army)
	cancelled.emit()


## --- Retratos (cosméticos, determinísticos — mesmo mapeamento de
## exercitos_panel.gd/comandantes_panel.gd, duplicado localmente). ---

func _portrait_for(commander: CommanderResource) -> Texture2D:
	if commander == null:
		return null
	var variant: int = absi(commander.commander_name.hash()) % 2
	match commander.faction:
		"Império":
			return PORTRAIT_IMPERIO_1 if variant == 0 else PORTRAIT_IMPERIO_2
		"Natureza":
			return PORTRAIT_NATUREZA_1 if variant == 0 else PORTRAIT_NATUREZA_2
		"Mortos-Vivos":
			return PORTRAIT_MORTOS_VIVOS_1 if variant == 0 else PORTRAIT_MORTOS_VIVOS_2
		_:
			return null


func _make_portrait(texture: Texture2D, size: float) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(size, size)
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(rect)

	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 2
	border_style.border_width_right = 2
	border_style.border_width_top = 2
	border_style.border_width_bottom = 2
	border_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.8)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)

	return slot


func _force_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_force_ignore_mouse_recursive(child)


## Correção FASE 22.2 — causa raiz REAL do texto cortado em toda a
## coluna direita (achado via screenshot + rastreamento de
## vbox.get_combined_minimum_size(), nunca só leitura de código): wrap=true
## sozinho (mesmo com SIZE_EXPAND_FILL) não bastava porque a VBoxContainer
## da coluna direita é reconstruída do zero a cada refresh
## (_clear_children + _build_detail_area), e o Label é adicionado e tem
## seu tamanho mínimo calculado ANTES da primeira passada de layout do
## Godot resolver a largura real do container recém-criado — o mesmo bug
## de "quebra letra-por-letra" já documentado no topo de _make_label(),
## só que none aqui pra textos REALMENTE longos (efeitos de Afinidade,
## legenda de posições) o efeito é catastrófico: um texto de ~60
## caracteres virava ~60 linhas de 1 letra, inflando a altura mínima da
## seção em milhares de pixels e arrastando a largura de toda a coluna
## junto (confirmado: passou de ~218px pra 466px exatamente ao adicionar
## a seção de Afinidade). _make_tooltip_label() já evitava isso dando um
## custom_minimum_size.x EXPLÍCITO (nunca dependendo só de
## SIZE_EXPAND_FILL) — mesma técnica aplicada aqui pra qualquer texto
## longo da coluna direita. 200px = largura útil real da coluna (~218px)
## menos uma margem de segurança.
func _make_detail_wrap_label(text: String, font_size: int, color: Color, centered: bool = true) -> Label:
	var label := _make_label(text, font_size, color, true)
	label.custom_minimum_size.x = 200.0
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _anchor_new_control(parent: Control, rect: Rect2) -> Control:
	var control := Control.new()
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.clip_contents = true
	parent.add_child(control)
	return control


## wrap=false por padrão (evita o bug de texto verticalizado do Godot —
## Label com AUTOWRAP_WORD_SMART dentro de um Container ainda sem
## largura resolvida na primeira passada de layout quebra
## letra-por-letra). Só texto realmente longo (via _make_body_label)
## usa wrap=true.
func _make_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	# Correção FASE 22.2 (achado real via screenshot — texto cortado na
	# coluna direita, "COMANDAN"/"SOLDO DO" etc.): wrap=true sozinho não
	# bastava. Sem SIZE_EXPAND_FILL, o Label mantém como "mínimo" a
	# largura do texto NÃO quebrado — se maior que a coluna (DETAIL_RECT,
	# ~234px em 1152×648), essa largura vira o mínimo de toda a
	# VBoxContainer pai, empurrando o conteúdo pra fora da área visível
	# (cortado pelo clip_contents do ancestral). Alguns call sites já
	# faziam essa atribuição manualmente (_make_body_label, o value_label
	# de Doutrina) — agora é automática pra qualquer wrap=true, corrige
	# todos os sites de uma vez (nenhuma regra de jogo tocada).
	if wrap:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := _make_label(text, font_size, color, wrap)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_body_label(text: String) -> Label:
	var label := _make_label(text, 10, HUD_TEXT_COLOR, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _make_card_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.08, 0.97)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_list_row_panel(selected: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.16)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = HUD_ACCENT_SELECTED
	else:
		style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.05)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Correção FASE 22 (revisão pós-22.1, revisão manual no Godot): o selo
## externo flutuante de Soldo (versão anterior desta função) não
## funcionava visualmente — um elemento solto por cima da carta, não
## parte dela. Substituído por uma barra estrutural anexada logo abaixo
## da própria carta (pedido explícito: Energia à esquerda, Soldo à
## direita), nunca mais uma etiqueta solta.
##
## CONFLITO DE DOCUMENTAÇÃO REGISTRADO (não resolvido silenciosamente):
## Fundation/CARD_LAYOUT_BIBLE.md, "I. Identificação Superior", reserva
## Energia/Soldo pra região SUPERIOR da carta ("elementos condicionais"
## que "não alteram a geometria"), nunca a barra inferior (que já é
## Ataque/Escudo/HP, "V — Barra Inferior"). O pedido desta correção pede
## explicitamente a barra INFERIOR. Resolvido a favor da decisão atual
## do usuário (PROJECT_INDEX.md, "Autoridade": decisão explícita do
## usuário no contexto atual > documento Foundation) — implementado como
## uma barra ANEXADA fora de BattleCardView (nunca dentro dela), pra
## nunca arriscar a calibração por pixel de ATK/ESC/HP que o próprio
## docstring de battle_card_view.gd protege. CARD_LAYOUT_BIBLE.md fica
## desatualizado quanto a este ponto — registrado no relatório, não
## corrigido ainda (fase em revisão, sem commit).
##
## Nunca recalcula Energia/Soldo — sempre EnergyArmy.card_energy()/
## Soldo.cost_for_rarity(), as mesmas fontes já usadas no resto do
## Editor (ENERGY.md/SOLDO.md).
func _make_composition_footer(card: CardResource) -> Control:
	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 20.0)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.92)
	style.border_width_top = 1
	style.border_color = HUD_ACCENT
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	footer.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	footer.add_child(row)

	var energy_box := HBoxContainer.new()
	energy_box.add_theme_constant_override("separation", 3)
	row.add_child(energy_box)
	energy_box.add_child(_make_label("EN", 8, HUD_MUTED_COLOR))
	energy_box.add_child(_make_label(str(EnergyArmy.card_energy(card.tier)), 10, Color(0.75, 0.85, 1.0)))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var soldo_box := HBoxContainer.new()
	soldo_box.add_theme_constant_override("separation", 3)
	row.add_child(soldo_box)
	soldo_box.add_child(_make_label(str(Soldo.cost_for_rarity(card.rarity)), 10, HUD_ACCENT_SELECTED))
	soldo_box.add_child(_make_label("SD", 8, HUD_MUTED_COLOR))

	_force_ignore_mouse_recursive(footer)
	return footer


func _make_stat_chip(title_text: String, value_text: String, value_color: Color = HUD_TEXT_COLOR) -> Control:
	var card := _make_card_panel()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.add_child(_make_centered_label(title_text, 9, HUD_MUTED_COLOR))
	vbox.add_child(_make_centered_label(value_text, 13, value_color))
	return card


## Correção FASE 22.2 (causa raiz REAL do texto cortado na coluna
## direita — achado via rastreamento de vbox.get_combined_minimum_size(),
## nunca só leitura de código): as 5 abas de Formação (α-ε) usavam a
## MESMA largura fixa das abas Comandante/Pelotão (90px) — 5×90px+
## separação = 466px, quase o DOBRO da largura útil real da coluna
## direita (~218px). Godot impõe o tamanho mínimo do conteúdo como piso,
## mesmo sobre uma âncora fracionária — isso forçava TODA a coluna
## DETAIL_RECT a crescer além do próprio limite e vazar pelo clip do
## frame externo. min_width agora é parâmetro (default 90, preserva as
## 2 abas do topo Comandante/Pelotão) — as abas de Formação (só uma
## letra grega cada) passam min_width menor.
func _make_tab_button(text: String, active: bool, min_width: float = 90.0) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 13)
	button.custom_minimum_size = Vector2(min_width, 34)
	button.toggle_mode = true
	button.button_pressed = active
	_style_office_button(button)
	if active:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.28)
		active_style.border_width_left = 2
		active_style.border_width_right = 2
		active_style.border_width_top = 2
		active_style.border_width_bottom = 2
		active_style.border_color = HUD_ACCENT_SELECTED
		active_style.corner_radius_top_left = 4
		active_style.corner_radius_top_right = 4
		active_style.corner_radius_bottom_left = 4
		active_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", active_style)
		button.add_theme_stylebox_override("pressed", active_style)
		button.add_theme_stylebox_override("hover", active_style)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 34)
	_style_office_button(button)
	return button


func _make_primary_button(text: String) -> Button:
	var button := _make_small_button(text)
	button.add_theme_font_size_override("font_size", 13)

	var accent_style := StyleBoxFlat.new()
	accent_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.20)
	accent_style.border_width_left = 2
	accent_style.border_width_right = 2
	accent_style.border_width_top = 2
	accent_style.border_width_bottom = 2
	accent_style.border_color = HUD_ACCENT_SELECTED
	accent_style.corner_radius_top_left = 4
	accent_style.corner_radius_top_right = 4
	accent_style.corner_radius_bottom_left = 4
	accent_style.corner_radius_bottom_right = 4
	accent_style.content_margin_left = 14.0
	accent_style.content_margin_right = 14.0
	button.add_theme_stylebox_override("normal", accent_style)
	button.add_theme_stylebox_override("disabled", accent_style)
	return button


func _style_office_button(button: Button) -> void:
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
	normal_style.content_margin_left = 10.0
	normal_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.22)
	hover_style.border_color = HUD_ACCENT_SELECTED
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _styled_option_button(values: Array[String], current: String) -> OptionButton:
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", 11)
	option.add_theme_font_override("font", HUD_FONT)
	for value: String in values:
		option.add_item(value)
	var current_index: int = values.find(current)
	option.selected = current_index if current_index != -1 else 0
	return option


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
