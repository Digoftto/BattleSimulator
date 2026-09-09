extends Control
## MinasPanel (WORLD_MAP_GATE.md, "Janela: Minas")
##
## Registro administrativo das Minas do Reino — não gerencia conquista
## (isso é PvE). Mesmo padrão das demais janelas: árvore em código, sem
## estado próprio, reconstruída a cada ação.
##
## FASE 17 — reestruturação funcional em 2 seções (Minas Principais x
## Minas Regionais Conquistadas). FASE 18 — reformulação exclusivamente
## VISUAL da mesma estrutura (nenhum dado/regra mudou nesta fase):
##
## Auditoria da Fase 18 encontrou a causa raiz do resultado "genérico"
## da Fase 17: HUD_OUTLINE_COLOR/HUD_SHADOW_COLOR (o tratamento usado em
## TODA tela do projeto para texto pousado diretamente sobre arte
## variável — ver city_panel.gd, faixa de HUD superior) tinha sido
## aplicado indiscriminadamente a TODO texto de minas_panel.gd,
## inclusive dentro de painéis já opacos — contorno grosso sobre fundo
## já escuro só reduz nitidez, nunca ajuda. Comparando com
## city_panel.gd::_update_contextual_panel() (o card "Abrir/Evoluir" de
## um prédio, que fica dentro de um PanelContainer opaco): ali
## name_label/info_label usam SÓ font_size, nenhum contorno/sombra — a
## regra real do projeto é "contorno/sombra SÓ sobre arte; texto dentro
## de um painel opaco usa tipografia limpa". Esta fase separa os dois
## casos: _style_over_art() (nome da Mina sobreposto à própria arte) x
## _style_plain() (todo o resto — título da tela, rótulos, valores,
## dados dos cards).
##
## 1. MINAS PRINCIPAIS: as 3 Minas Básicas (kingdom.initial_mines,
##    sempre exatamente 3 — DL_MINES.md, "Minas Principais": "existe
##    apenas uma de cada Fundamento"), com arte real grande
##    (MineArtCatalog) e identidade nomeada (INITIAL_MINE_NAMES, direto
##    de DL_MINES.md — nenhum nome inventado). Grid responsivo (mesma
##    técnica de recálculo de colunas por resize já usada no Bestiário),
##    nunca mais de 3 colunas (só existem 3 Minas Básicas).
##
## 2. MINAS REGIONAIS CONQUISTADAS: registro administrativo (SEM arte —
##    decisão explícita do pedido: "a arte da Mina Regional deve
##    permanecer no local físico da Mina nas trilhas do World Map... a
##    Cidade não deve duplicar essa representação visual") das Minas
##    Regionais (kingdom.territory_mines) que já têm mina.conquered ==
##    true. Auditoria da Fase 17 confirmou que NENHUM fluxo de jogo real
##    hoje chama MineConquestResolver.attempt_conquest() nem
##    Kingdom.generate_territory_mines() (só testes o fazem) — portanto
##    esta seção fica vazia numa partida normal (ver
##    _build_empty_regional_state(), um estado vazio estilizado, nunca
##    15 posições fictícias); nunca gera Mina, nunca cria linha
##    fictícia, só reflete territory_mines como ele realmente está.
##
## Botão "IR PARA MINA" (Minas Regionais): estrutura pronta, ver
## _on_ir_para_mina_pressed() — permanece desabilitado até existir uma
## tela real de localização/detalhe de Mina (nenhuma existe hoje;
## auditoria da Fase 17 não encontrou mapa espacial nem mecanismo de
## foco/navegação por Território em nenhuma tela do projeto). Nenhum
## destino provisório/falso foi criado.
##
## FASE 19 — dois ajustes de acabamento sobre a Fase 18 (layout intacto):
##
## 1. CAUSA RAIZ da "Mina de Ferro Negro aparecendo preta": mina_art
##    nunca setava `expand_mode`. O padrão do Godot (EXPAND_KEEP_SIZE)
##    faz o Control tratar as dimensões NATIVAS da textura (1536x1024
##    pra Ferro Negro, 1402x1122 pras outras duas) como seu tamanho
##    MÍNIMO — e Control sempre garante `size >= tamanho mínimo`, mesmo
##    quando as âncoras dizem "preencha o pai" (PRESET_FULL_RECT). Como
##    art_stack tem `clip_contents = true`, o resultado é que só o canto
##    SUPERIOR ESQUERDO da imagem NATIVA (sem o corte/escala pretendido
##    por STRETCH_KEEP_ASPECT_COVERED) fica visível. Ferro Negro tem
##    canal alpha real (cutout) e esse canto específico calha de cair
##    numa região transparente — daí a área preta/vazia. As outras duas
##    são fotos "sangradas" sem transparência: o mesmo bug já as afeta
##    (corte errado, sem passar pelo STRETCH_KEEP_ASPECT_COVERED de
##    verdade), só que como não têm alpha, qualquer pedaço mostra
##    conteúdo real e "parece" certo. Confirmado por inspeção direta dos
##    3 PNGs (dimensões, canal alpha, bbox do conteúdo opaco) e por
##    simulação exata da matemática de STRETCH_KEEP_ASPECT_COVERED da
##    Godot — nunca pelo MineArtCatalog (caminho/carregamento
##    confirmados corretos pros 3 recursos) nem pelos PNGs em si (alpha
##    é um cutout legítimo). Correção mínima: `expand_mode =
##    TextureRect.EXPAND_IGNORE_SIZE` (mesmo padrão já usado em
##    academia_producao_panel.gd pro TextureRect de fundo) — faz Godot
##    ignorar o tamanho nativo da textura pra fins de tamanho mínimo, o
##    STRETCH_KEEP_ASPECT_COVERED finalmente escala+corta pro tamanho
##    real do card, nas 3 Minas.
##
## 2. Clique numa Mina Principal abre uma janela de detalhe (overlay
##    sobre a própria tela, nunca cena nova) com o asset COMPLETO (sem
##    corte: STRETCH_KEEP_ASPECT_CENTERED numa caixa dimensionada pela
##    proporção real da textura) + nome + Produção — nenhum dado
##    administrativo. Mesmo padrão de overlay/backdrop já usado em
##    academia_producao_panel.gd (_build_card_zoom_overlay): cascata de
##    `mouse_filter = MOUSE_FILTER_IGNORE` nos elementos puramente
##    visuais do card (art_stack/mina_art/name_label/vbox/stats_box/
##    separadores/stat blocks) pra o clique borbulhar até o
##    PanelContainer do card (STOP + gui_input, CONNECT_DEFERRED — mesmo
##    padrão já usado em todo o resto deste arquivo) sem quebrar os
##    botões reais (Ativar etc., que continuam consumindo o próprio
##    clique antes de borbulhar). Só Minas Principais — Minas Regionais
##    seguem sem modal, sem arte, exatamente como na Fase 17/18.

const INITIAL_MINE_NAMES: Dictionary = {
	"Império": "Mina de Ferro Negro",
	"Natureza": "Fonte de Essência Vital",
	"Mortos-Vivos": "Mina de Cristais Arcanos",
}

## MINES.md, "Estrutura Permanente das Trilhas" — associação fixa,
## permanente e documentada entre Facção e número da Trilha. Usado só
## pra exibir "Trilha N" no registro Regional (dado real, não
## inventado) — nunca usado por nenhuma regra de jogo.
const TRILHA_NUMBER_BY_FACTION: Dictionary = {
	"Império": 1,
	"Natureza": 2,
	"Mortos-Vivos": 3,
}

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
## Mesmo tom de aviso já usado em city_panel.gd::_evolve_status_label —
## reaproveitado aqui pro status de "Designar Guarnição" falhou, nunca
## uma cor nova.
const HUD_WARNING_COLOR: Color = Color(1.0, 0.75, 0.55)

const PRINCIPAL_CARD_MIN_WIDTH: float = 250.0
const PRINCIPAL_CARD_ART_HEIGHT: float = 190.0
const PRINCIPAL_CARD_MAX_COLUMNS: int = 3  # nunca mais que isso: só existem 3 Minas Básicas.

var _root_vbox: VBoxContainer
var _principais_grid: GridContainer
var _regionais_container: VBoxContainer

## FASE 19: Mina Principal cujo modal de detalhe está aberto (null =
## fechado). Só Minas Principais abrem modal — nunca setado por um
## card Regional.
var _mina_detail: Mina = null
var _mina_detail_overlay: Control = null

var _selected_army_by_mina: Dictionary = {}  # mina -> Army

## F-047 (F-019 do TECHNICAL_BACKLOG.md): mensagem visível quando
## Designar Guarnição é rejeitado — antes só existia um print() no
## console, o clique parecia não fazer nada. Por Mina (não um único
## Label global), mesmo motivo de _selected_army_by_mina: pode haver
## várias Minas na tela ao mesmo tempo.
var _mina_status_text: Dictionary = {}  # mina -> String

## F-021.5: dica contextual de Guarnição (singleton — ver
## _maybe_show_guarnicao_contextual_hint()).
var _guarnicao_hint: Control = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	refresh()
	print("[MinasPanel] Pronto. Minas conquistadas: %d" % _count_conquered(KingdomState.kingdom))


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	# FASE 18: MarginContainer em vez de uma largura mínima fixa (700px,
	# Fase 17) — a tela agora flui com a largura real da janela (testado
	# conceitualmente em 1152x648/1366x768/1920x1080, ver relatório),
	# só com uma margem lateral confortável, mesmo espírito de
	# respiro/margem já usado nos popups da Capital.
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	_root_vbox = VBoxContainer.new()
	_root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(_root_vbox)

	# FASE 18: título com a mesma assinatura das demais telas (Cinzel +
	# HUD_ACCENT) — antes era uma Label branca no tema padrão do Godot,
	# a única tela do projeto sem nenhuma identidade dourada no título.
	var title := Label.new()
	title.text = "Minas"
	_style_plain(title, 30, HUD_ACCENT)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para o World Map Gate"
	back_button.pressed.connect(_on_back_to_command_center_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	# --- MINAS PRINCIPAIS: grid responsivo (mesma técnica de
	# recálculo de colunas por resize já usada no Bestiário) — nunca
	# mais de PRINCIPAL_CARD_MAX_COLUMNS (só existem 3 Minas Básicas,
	# DL_MINES.md). ---
	var principais_title := Label.new()
	principais_title.text = "Minas Principais"
	_style_plain(principais_title, 16, HUD_ACCENT)
	_root_vbox.add_child(principais_title)

	_principais_grid = GridContainer.new()
	_principais_grid.columns = PRINCIPAL_CARD_MAX_COLUMNS
	_principais_grid.add_theme_constant_override("h_separation", 16)
	_principais_grid.add_theme_constant_override("v_separation", 16)
	_root_vbox.add_child(_principais_grid)

	resized.connect(_update_principais_columns)
	_update_principais_columns.call_deferred()

	# --- MINAS REGIONAIS CONQUISTADAS: registro administrativo, sem
	# arte (ver docstring do topo) — lista vertical, cresce
	# automaticamente conforme o Reino conquista Minas Regionais reais;
	# o ScrollContainer que já envolve toda a tela cobre a rolagem, sem
	# precisar de um segundo ScrollContainer aninhado. ---
	var regionais_title := Label.new()
	regionais_title.text = "Minas Regionais Conquistadas"
	_style_plain(regionais_title, 16, HUD_ACCENT)
	_root_vbox.add_child(regionais_title)

	_regionais_container = VBoxContainer.new()
	_regionais_container.add_theme_constant_override("separation", 12)
	_root_vbox.add_child(_regionais_container)


## Recalculado a cada resize (nunca fixo) — mesma técnica já usada em
## bestiario_panel.gd/biblioteca_panel.gd. Limitado a
## PRINCIPAL_CARD_MAX_COLUMNS: mais colunas que Minas Básicas existentes
## só deixaria espaço vazio no grid.
func _update_principais_columns() -> void:
	if _principais_grid == null:
		return
	var available_width: float = size.x - 64.0  # margens laterais (32px cada lado)
	var columns: int = maxi(1, int(available_width / (PRINCIPAL_CARD_MIN_WIDTH + 16.0)))
	_principais_grid.columns = mini(columns, PRINCIPAL_CARD_MAX_COLUMNS)


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())
	var now: int = GameClock.now_unix()

	_refresh_principais(kingdom, now)
	_refresh_regionais(kingdom, now)
	_refresh_mina_detail_modal()


## MINAS PRINCIPAIS — kingdom.initial_mines é criado por
## Kingdom.create_initial_mines() já conquistado (MINES.md, "Mina
## Inicial (Bootstrap)": disponível desde o início da conta) — sempre
## exatamente 3, nunca filtra por mina.conquered (seria sempre true).
func _refresh_principais(kingdom: Kingdom, now: int) -> void:
	_clear_children(_principais_grid)
	for mina: Mina in kingdom.initial_mines:
		_principais_grid.add_child(_build_principal_card(kingdom, mina, now))


## Card "janela de gerenciamento" da Mina Básica — arte grande como
## protagonista (STRETCH_KEEP_ASPECT_COVERED + clip_contents, nunca
## deforma as 3 imagens de proporções diferentes), nome como overlay
## sobre a própria arte (com um scrim escuro por baixo pra garantir
## contraste nas 3 artes — Ferro Negro já tem vinheta própria, Essência
## Vital/Cristais Arcanos são paisagens "sangradas" sem vinheta; o scrim
## cobre os dois casos sem depender da cor/brilho específico de cada
## imagem), separadores dourados dividindo Identidade -> Dados -> Ação
## (mesmo princípio pedido: nunca um parágrafo de texto solto).
func _build_principal_card(kingdom: Kingdom, mina: Mina, now: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(PRINCIPAL_CARD_MIN_WIDTH, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _card_style())
	# FASE 19: card inteiro é clicável -> abre o modal de detalhe. STOP +
	# gui_input (CONNECT_DEFERRED, mesmo padrão de todo o resto deste
	# arquivo) no PanelContainer; os elementos puramente visuais dentro
	# dele (vbox, art_stack, separadores, stat blocks) usam
	# MOUSE_FILTER_IGNORE pra deixar o clique borbulhar até aqui — os
	# botões reais (Ativar etc.) continuam consumindo o próprio clique
	# antes disso, sem mudança de comportamento.
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_principal_card_gui_input.bind(mina), CONNECT_DEFERRED)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	vbox.add_child(_build_art_with_name_overlay(mina))
	vbox.add_child(_build_gold_separator())

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_box)
	stats_box.add_child(_build_stat_block("Nível Estrutural", str(mina.structure_level)))
	_add_common_stats(stats_box, kingdom, mina, now)

	var actions := _build_actions_section(kingdom, mina, now)
	if actions != null:
		vbox.add_child(_build_gold_separator())
		vbox.add_child(actions)

	# F-020: seção SEMPRE desenhada, independente do gate de
	# _build_actions_section() (que retorna null pra sempre depois de
	# "Ativar", já que o Ciclo de Mina Inicial nunca expira) — Evolução
	# de Nível Estrutural não depende do estado do Ciclo.
	vbox.add_child(_build_gold_separator())
	vbox.add_child(_build_evoluir_section(kingdom, mina))

	return card


## Arte real (protagonista) + nome da Mina sobreposto na faixa inferior
## — único lugar desta tela onde contorno/sombra (_style_over_art())
## faz sentido, porque é o único texto que fica diretamente sobre uma
## imagem variável (ver docstring do topo sobre a distinção Fase 18).
func _build_art_with_name_overlay(mina: Mina) -> Control:
	var art_stack := Control.new()
	art_stack.custom_minimum_size = Vector2(0, PRINCIPAL_CARD_ART_HEIGHT)
	art_stack.clip_contents = true
	art_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: deixa o clique borbulhar até o card.

	var mina_art := TextureRect.new()
	mina_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	# FASE 19 (causa raiz do bug "Ferro Negro preto" — ver docstring do
	# topo): sem isto, Godot usa o tamanho NATIVO da textura como
	# mínimo do Control, o que vence as âncoras de FULL_RECT e faz
	# STRETCH_KEEP_ASPECT_COVERED nunca escalar/cortar de verdade — só
	# o canto superior esquerdo da imagem original fica visível dentro
	# do clip_contents do art_stack.
	mina_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mina_art.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: idem art_stack.
	mina_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mina_art.texture = preload("res://engine/presentation/mine_art_catalog.gd").texture_for(mina)
	mina_art.visible = mina_art.texture != null
	art_stack.add_child(mina_art)

	# Scrim: garante contraste do nome contra QUALQUER uma das 3 artes
	# (não presume que uma configuração que funciona numa vai funcionar
	# nas outras duas — pedido explícito da Fase 18).
	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.anchor_left = 0.0
	scrim.anchor_right = 1.0
	scrim.anchor_top = 0.55
	scrim.anchor_bottom = 1.0
	scrim.offset_left = 0.0
	scrim.offset_right = 0.0
	scrim.offset_top = 0.0
	scrim.offset_bottom = 0.0
	art_stack.add_child(scrim)

	var name_label := Label.new()
	name_label.text = INITIAL_MINE_NAMES.get(mina.faction, "Mina")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.anchor_left = 0.0
	name_label.anchor_right = 1.0
	name_label.anchor_top = 1.0
	name_label.anchor_bottom = 1.0
	name_label.offset_left = 8.0
	name_label.offset_right = -8.0
	name_label.offset_top = -40.0
	name_label.offset_bottom = -8.0
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: idem art_stack.
	_style_over_art(name_label, 15, HUD_TEXT_COLOR)
	art_stack.add_child(name_label)

	return art_stack


## MINAS REGIONAIS CONQUISTADAS — kingdom.territory_mines (dict
## territory_id -> Array[Mina]) é a única fonte real (Fase 17: nenhum
## fluxo de jogo popula isso hoje fora de testes — ver docstring do
## topo). Nunca chama Kingdom.generate_territory_mines() aqui: essa
## seção só reflete o que já existe, nunca cria Mina nova como efeito
## colateral de abrir a tela.
func _refresh_regionais(kingdom: Kingdom, now: int) -> void:
	_clear_children(_regionais_container)

	var any_conquered := false
	var any_needs_guarnicao := false
	for territory_id: String in kingdom.territory_mines:
		for mina: Mina in kingdom.territory_mines[territory_id]:
			if not mina.conquered:
				continue
			any_conquered = true
			if mina.guarnicao_army == null:
				any_needs_guarnicao = true
			_regionais_container.add_child(_build_regional_card(kingdom, territory_id, mina, now))

	if not any_conquered:
		_regionais_container.add_child(_build_empty_regional_state())

	_maybe_show_guarnicao_contextual_hint(any_needs_guarnicao)


## F-021.5 (dica contextual, independente da sequência linear TUT-001):
## primeira vez que existe uma Mina Regional conquistada ainda sem
## Guarnição designada — explica o que ela faz e por que é obrigatória
## (MINES.md, "Após a Conquista"). Singleton (_guarnicao_hint) porque
## refresh() reconstrói só _regionais_container, não a tela inteira —
## sem isso, cada refresh() adicionaria uma cópia nova.
func _maybe_show_guarnicao_contextual_hint(any_needs_guarnicao: bool) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if not any_needs_guarnicao or kingdom.has_progress_flag("tutorial_hint_guarnicao_visto") or _guarnicao_hint != null:
		return

	_guarnicao_hint = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	_guarnicao_hint.setup(
		"Guarnição da Mina",
		"Toda Mina Regional conquistada precisa de uma Guarnição — um Exército seu designado para defendê-la. A Eficiência dela contra o defensor original define quanto a Mina produz durante o Ciclo de Mineração. Escolha um Exército disponível abaixo e clique 'Designar Guarnição'.",
		"Dica"
	)
	_guarnicao_hint.continue_pressed.connect(_on_guarnicao_hint_continue, CONNECT_DEFERRED)
	add_child(_guarnicao_hint)


func _on_guarnicao_hint_continue() -> void:
	KingdomState.kingdom.set_progress_flag("tutorial_hint_guarnicao_visto")
	_guarnicao_hint.queue_free()
	_guarnicao_hint = null


## Estado vazio estilizado (nunca 15 posições fictícias, nunca uma
## Label solta perdida na tela) — mesma moldura dourada dos demais
## cards, só com um texto real de status em vez de dado de Mina.
func _build_empty_regional_state() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var line1 := Label.new()
	line1.text = "Nenhuma Mina Regional conquistada ainda."
	line1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain(line1, 14, HUD_TEXT_COLOR)
	vbox.add_child(line1)

	var line2 := Label.new()
	line2.text = "Elas aparecerão aqui automaticamente conforme forem conquistadas."
	line2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain(line2, 12, HUD_MUTED_COLOR)
	vbox.add_child(line2)

	return panel


## Registro administrativo — SEM arte (regra explícita da Fase 18: a
## arte da Mina Regional pertence ao local físico dela na Trilha, nunca
## duplicada aqui). Mesma moldura dourada dos cards Principais, pra
## soar como parte da mesma tela, mas o conteúdo é só dado (rótulo em
## cima, valor embaixo), nunca uma miniatura.
func _build_regional_card(kingdom: Kingdom, territory_id: String, mina: Mina, now: int) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var trilha_number: int = TRILHA_NUMBER_BY_FACTION.get(mina.faction, 0)
	var header_label := Label.new()
	header_label.text = "Região %d · Trilha %d (%s)" % [mina.region, trilha_number, mina.faction]
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_plain(header_label, 15, HUD_ACCENT)
	header_row.add_child(header_label)

	# FASE 17/18: "IR PARA MINA" — estrutura/contrato prontos, sem
	# destino falso (ver docstring do topo e _on_ir_para_mina_pressed()).
	# Desabilitado até existir uma implementação real de navegação.
	var ir_para_mina_button := Button.new()
	ir_para_mina_button.text = "Ir para Mina"
	ir_para_mina_button.disabled = true
	ir_para_mina_button.tooltip_text = "Navegação até a localização física da Mina ainda não implementada."
	ir_para_mina_button.pressed.connect(_on_ir_para_mina_pressed.bind(territory_id, mina), CONNECT_DEFERRED)
	header_row.add_child(ir_para_mina_button)

	vbox.add_child(_build_gold_separator())

	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 20)
	vbox.add_child(identity_row)
	identity_row.add_child(_build_stat_block("Recurso", MineEconomy.resource_for_faction(mina.faction).capitalize()))
	identity_row.add_child(_build_stat_block("Fase", str(mina.adjacent_fase)))
	identity_row.add_child(_build_stat_block("Nível Estrutural", str(mina.structure_level)))

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_box)
	_add_common_stats(stats_box, kingdom, mina, now)

	var actions := _build_actions_section(kingdom, mina, now)
	if actions != null:
		vbox.add_child(_build_gold_separator())
		vbox.add_child(actions)

	# F-021.3.1: Evolução de Nível Estrutural generalizada — a mesma
	# seção que já existia só para a Mina Inicial (ver
	# _build_principal_card()), agora também para Minas Regionais
	# conquistadas. Sempre desenhada, independente do estado do Ciclo
	# (mesma razão de lá: evolução não depende de Guarnição/Ciclo ativo).
	vbox.add_child(_build_gold_separator())
	vbox.add_child(_build_evoluir_section(kingdom, mina))

	return card


## Dados dinâmicos compartilhados por qualquer Mina (Principal ou
## Regional) — Ciclo/Eficiência, Guarnição, Renovação — como blocos
## rótulo/valor (nunca um parágrafo de texto solto). Extraído desde a
## Fase 17 pra nunca duplicar esta lógica entre os dois tipos de card;
## a Fase 18 só muda COMO cada dado é apresentado, nunca o valor em si
## (mesmos cálculos/objetos de sempre).
func _add_common_stats(stats_box: VBoxContainer, kingdom: Kingdom, mina: Mina, now: int) -> void:
	stats_box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: deixa o clique borbulhar até o card (Principal).
	var cycle: Dictionary = _cycle_state_parts(mina, now)
	stats_box.add_child(_build_stat_block("Estado do Ciclo", cycle["estado"]))
	if cycle["detalhe"] != "":
		stats_box.add_child(_build_stat_block("Produção / Eficiência", cycle["detalhe"]))

	if not mina.is_initial_mine():
		var guarnicao_text: String
		if mina.guarnicao_army != null:
			var commander_name: String = mina.guarnicao_army.commander.commander_name if mina.guarnicao_army.commander != null else "sem Comandante"
			guarnicao_text = "%s (%s)" % [mina.guarnicao_army.army_name, commander_name]
		else:
			guarnicao_text = "Nenhuma designada."
		stats_box.add_child(_build_stat_block("Guarnição", guarnicao_text))

		var renew_row := HBoxContainer.new()
		stats_box.add_child(renew_row)
		var renew_check := CheckBox.new()
		renew_check.text = "Renovação Automática"
		renew_check.button_pressed = mina.auto_renew_enabled
		renew_check.toggled.connect(_on_auto_renew_toggled.bind(mina), CONNECT_DEFERRED)
		renew_row.add_child(renew_check)


## Traduz o estado do Ciclo em duas partes (estado principal + detalhe
## de produção/eficiência) — MESMOS valores/textos calculados desde a
## Fase 16, só separados em dois campos em vez de uma única frase unida
## por "|" (mudança puramente de apresentação, pedido explícito da
## Fase 18: "Não usar texto solto em sequência... RÓTULO / valor").
func _cycle_state_parts(mina: Mina, now: int) -> Dictionary:
	if not mina.is_cycle_active(now):
		return {"estado": "Nenhum Ciclo ativo.", "detalhe": ""}

	if mina.is_initial_mine():
		# MINES.md, "Mina Inicial (Bootstrap)": produção contínua pra
		# sempre, sem prazo — nunca "faltam Xh". Eficiência sempre 100%
		# (sem Guarnição/simulação) é informação redundante — mostra a
		# geração/hora real em vez disso (FORMULAS.md, "Produção das
		# Minas").
		return {
			"estado": "Produzindo continuamente",
			"detalhe": _producao_text_for_initial_mine(mina),
		}

	var remaining_hours: float = (mina.cycle_started_unix + Mina.CYCLE_DURATION_SECONDS - now) / 3600.0
	var estado: String = "Ciclo ativo — faltam ~%.1fh" % remaining_hours
	var detalhe: String
	if mina.cycle_efficiency < 0.0:
		detalhe = "Eficiência: calculando o primeiro bloco..."
	elif not MiningCycleResolver.has_high_confidence(mina):
		detalhe = "Eficiência: %.1f%% (ainda se ajustando — bloco %d/%d)" % [
			mina.cycle_efficiency * 100.0, mina.efficiency_blocks_completed, MiningCycleResolver.HIGH_CONFIDENCE_BLOCKS
		]
	else:
		detalhe = "Eficiência: %.1f%%" % (mina.cycle_efficiency * 100.0)
	return {"estado": estado, "detalhe": detalhe}


## FASE 19: única fonte do texto de Produção de uma Mina Inicial — usada
## tanto no card (_cycle_state_parts) quanto na janela de detalhe
## (_build_mina_detail_modal), nunca duas fórmulas/strings diferentes.
## MineEconomy.base_production_for_mina() já é independente de
## is_cycle_active() (é a taxa base pelo Nível Estrutural, FORMULAS.md
## "Produção das Minas") — por isso a janela de detalhe pode mostrar a
## Produção real mesmo antes do jogador clicar "Ativar".
func _producao_text_for_initial_mine(mina: Mina) -> String:
	var resource_name: String = MineEconomy.resource_for_faction(mina.faction)
	var production_per_hour: int = MineEconomy.base_production_for_mina(mina)
	return "%d de %s por hora" % [production_per_hour, resource_name]


## Linha de ação (Ativar / Designar Guarnição + Iniciar Ciclo) —
## MESMOS botões/handlers desde a Fase 16, só isolados numa função
## própria pra serem reutilizados sem duplicar entre os dois tipos de
## card. Retorna null quando não há ação disponível (Ciclo já ativo) —
## quem chama decide se desenha o separador antes dela.
func _build_actions_section(kingdom: Kingdom, mina: Mina, now: int) -> Control:
	if mina.is_cycle_active(now):
		return null

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	container.add_child(action_row)

	if mina.is_initial_mine():
		# MINES.md, "Mina Inicial (Bootstrap)": "Não exige exército
		# defensor ou Guarnição da Mina" — só precisa ser ativada. Sem
		# simulação de 362.880 combinações (não existe Guarnição nem
		# Formação de Referência pra comparar) — sempre 100% de
		# eficiência.
		var activate_button := Button.new()
		activate_button.text = "Ativar"
		activate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		activate_button.pressed.connect(_on_activate_initial_mine_pressed.bind(mina), CONNECT_DEFERRED)
		action_row.add_child(activate_button)
	else:
		var available_armies: Array[Army] = []
		for army: Army in kingdom.armies:
			if army.availability == Army.Availability.AVAILABLE:
				available_armies.append(army)

		var army_option := OptionButton.new()
		army_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		army_option.add_item("(escolha um Exército)", -1)
		for i in range(available_armies.size()):
			army_option.add_item(available_armies[i].army_name, i)
		var selected: Army = _selected_army_by_mina.get(mina, null)
		if selected != null and available_armies.has(selected):
			army_option.selected = available_armies.find(selected) + 1
		army_option.item_selected.connect(_on_army_selected.bind(mina, available_armies), CONNECT_DEFERRED)
		action_row.add_child(army_option)

		var assign_button := Button.new()
		assign_button.text = "Designar Guarnição"
		assign_button.pressed.connect(_on_assign_guarnicao_pressed.bind(mina), CONNECT_DEFERRED)
		action_row.add_child(assign_button)

		var start_button := Button.new()
		start_button.text = "Iniciar Ciclo"
		start_button.disabled = mina.guarnicao_army == null
		start_button.pressed.connect(_on_start_cycle_pressed.bind(mina), CONNECT_DEFERRED)
		action_row.add_child(start_button)

		if _mina_status_text.get(mina, "") != "":
			var status_label := Label.new()
			status_label.text = _mina_status_text[mina]
			status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(status_label, 12, HUD_WARNING_COLOR)
			container.add_child(status_label)

	return container


## F-020, generalizado em F-021.3.1: seção "Evoluir" — SEMPRE desenhada
## (ver _build_principal_card()/_build_regional_card()), nunca gated
## pelo Ciclo (diferente de _build_actions_section()). Vale para
## qualquer Mina (Inicial ou Regional); usa exclusivamente
## MineEvolutionResolver.evolve() (que por sua vez usa só
## MineEconomy.upgrade_cost_pg()/MineEconomy.region_for_mina()/
## Kingdom.spend_generation_points()/Mina.increment_structure_level() —
## nenhuma fórmula nova). Mostra Produção Atual e Próxima Produção
## (MineEconomy.base_production_per_hour(), mesma fonte que
## _producao_text_for_initial_mine()/_cycle_state_parts() já usam) —
## só a Mina Inicial tem teto de Nível (MINES.md); Regionais nunca
## mostram "máximo atingido".
func _build_evoluir_section(kingdom: Kingdom, mina: Mina) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var region: MineEconomy.Region = MineEconomy.region_for_mina(mina)
	var at_cap: bool = mina.is_initial_mine() and mina.structure_level >= MineEvolutionResolver.INITIAL_MINE_MAX_LEVEL
	var next_level: int = mina.structure_level + 1
	var current_production: int = MineEconomy.base_production_per_hour(region, mina.structure_level)
	var resource_name: String = MineEconomy.resource_for_faction(mina.faction).capitalize()

	var info_label := Label.new()
	if at_cap:
		info_label.text = "Produção atual: %d %s/h. Nível Estrutural máximo atingido (%d)." % [
			current_production, resource_name, MineEvolutionResolver.INITIAL_MINE_MAX_LEVEL
		]
	else:
		var next_production: int = MineEconomy.base_production_per_hour(region, next_level)
		var cost: int = MineEconomy.upgrade_cost_pg(region, next_level)
		info_label.text = "Produção atual: %d %s/h. Evoluir para o Nível %d (%d %s/h) — Custo: %d PG" % [
			current_production, resource_name, next_level, next_production, resource_name, cost
		]
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_plain(info_label, 12, HUD_MUTED_COLOR)
	container.add_child(info_label)

	var evoluir_button := Button.new()
	evoluir_button.text = "Evoluir"
	evoluir_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evoluir_button.disabled = at_cap
	evoluir_button.pressed.connect(_on_evoluir_mina_pressed.bind(mina), CONNECT_DEFERRED)
	container.add_child(evoluir_button)

	if _mina_status_text.get(mina, "") != "":
		var status_label := Label.new()
		status_label.text = _mina_status_text[mina]
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_style_plain(status_label, 12, HUD_WARNING_COLOR)
		container.add_child(status_label)

	return container


## Bloco "rótulo em cima (pequeno, discreto) + valor embaixo (mais
## destaque)" — a unidade básica de apresentação de dado desta tela
## (pedido explícito da Fase 18: "Não usar texto solto em sequência").
## Nunca usa contorno/sombra — fica sempre dentro do corpo opaco do
## card (ver docstring do topo).
func _build_stat_block(label_text: String, value_text: String) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 1)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: deixa o clique borbulhar até o card (Principal).

	var caption := Label.new()
	caption.text = label_text.to_upper()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_plain(caption, 11, HUD_MUTED_COLOR)
	block.add_child(caption)

	var value := Label.new()
	value.text = value_text
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_plain(value, 14, HUD_TEXT_COLOR)
	block.add_child(value)

	return block


## Separador dourado discreto — divide Identidade -> Dados -> Ação
## dentro de um card, reaproveitando o próprio HSeparator do Godot
## (nenhum componente novo), só tingido com a cor de destaque já usada
## em toda a tela.
func _build_gold_separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE  # FASE 19: deixa o clique borbulhar até o card (Principal).
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	separator.add_theme_stylebox_override("separator", style)
	return separator


## Moldura dourada translúcida — mesmo padrão de borda fina + cantos
## arredondados + fundo quase transparente já usado em toda a Cidade
## (_build_hud_chip()/_build_chip() de city_panel.gd/biblioteca_panel.gd
## etc.), só com margens maiores por se tratar de um card, não um chip
## pequeno.
func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.08)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


## FASE 18: texto dentro de um painel OPACO (título da tela, rótulos,
## valores, qualquer dado dos cards) — Cinzel + cor, SEM contorno/
## sombra. Contorno/sombra existem pra combater um fundo imprevisível
## (arte variável); dentro de um card com fundo próprio, só reduzem
## nitidez (ver docstring do topo, causa raiz identificada na
## auditoria).
func _style_plain(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


## FASE 18: texto pousado DIRETAMENTE sobre a arte da Mina (só o nome
## na faixa inferior do card Principal, ver _build_art_with_name_overlay())
## — aqui sim o contorno/sombra faz sentido, mesmo tratamento que toda
## outra tela do projeto já usa pra texto sobre arte.
func _style_over_art(label: Label, font_size: int, color: Color) -> void:
	_style_plain(label, font_size, color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)


func _count_conquered(kingdom: Kingdom) -> int:
	var count: int = 0
	for mina: Mina in kingdom.all_mines():
		if mina.conquered:
			count += 1
	return count


func _clear_children(container: Node) -> void:
	# Remoção IMEDIATA (não queue_free) — mesmo motivo já documentado
	# nos outros painéis: evita nós antigos e novos coexistindo até o
	# fim do frame.
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_auto_renew_toggled(enabled: bool, mina: Mina) -> void:
	mina.auto_renew_enabled = enabled
	refresh()


func _on_army_selected(index: int, mina: Mina, available_armies: Array[Army]) -> void:
	if index <= 0:
		_selected_army_by_mina.erase(mina)
		return
	_selected_army_by_mina[mina] = available_armies[index - 1]


## F-047 (F-019): traduz o "reason" técnico de MineGuarnicaoResolver.assign()
## (ver docstring do próprio Resolver) pra uma frase que o jogador
## entende — nunca o código cru ("cycle_active" etc.) na tela.
func _guarnicao_failure_message(reason: String) -> String:
	match reason:
		"not_conquered":
			return "Não foi possível designar Guarnição: esta Mina ainda não foi conquistada."
		"cycle_active":
			return "Não foi possível designar Guarnição: já existe um Ciclo de Mineração ativo nesta Mina."
		"army_unavailable":
			return "Não foi possível designar Guarnição: o Exército escolhido já está ocupado em outra função (combate, recuperação, ou já é Guarnição de outra Mina)."
		_:
			return "Não foi possível designar Guarnição (%s)." % reason


func _on_assign_guarnicao_pressed(mina: Mina) -> void:
	var army: Army = _selected_army_by_mina.get(mina, null)
	if army == null:
		return
	var result: Dictionary = MineGuarnicaoResolver.assign(mina, army, GameClock.now_unix())
	if not result["success"]:
		print("[MinasPanel] Designar Guarnição falhou: %s" % result["reason"])
		_mina_status_text[mina] = _guarnicao_failure_message(result["reason"])
	else:
		_mina_status_text.erase(mina)
	refresh()


## Roda o cálculo REAL de Eficiência — agora incremental (MINES.md,
## "Cálculo Incremental por Amostragem"): dispara o 1º bloco com mais
## threads (mais rápido, coberto pela cena de conquista no fluxo real)
## e retorna na hora, sem travar a tela. Os blocos seguintes avançam
## sozinhos em segundo plano, via GameRuntime.sync() (menos threads,
## pra pesar pouco na máquina enquanto o jogador já está jogando).
const FIRST_BLOCK_THREAD_COUNT: int = 8

## F-003 (reativado): se a Guarnição atual tem exatamente a mesma
## configuração relevante para combate (Comandante + XP + as 9 cartas,
## na mesma ordem, com o mesmo Tier/atributos) que a Eficiência já
## congelada de um Ciclo anterior desta Mina, reaproveita esse valor
## direto — nunca recalcula à toa (MINES.md, "Reaproveitamento de
## Eficiência"). Caso contrário, inicia uma estimativa nova de verdade:
## dispara o 1º bloco com mais threads (coberto pela cena de conquista
## no fluxo real) e retorna na hora, sem travar a tela — os blocos
## seguintes avançam sozinhos em segundo plano via GameRuntime.sync().
func _on_start_cycle_pressed(mina: Mina) -> void:
	if mina.guarnicao_army == null:
		return

	if MiningCycleResolver.garrison_signature_matches(mina, mina.guarnicao_army):
		mina.start_cycle(GameClock.now_unix(), mina.cycle_efficiency)
		refresh()
		return

	MiningCycleResolver.start_estimation(mina, GameClock.now_unix())
	mina.start_cycle(GameClock.now_unix(), -1.0)
	MiningCycleResolver.start_next_block_async(
		mina, mina.guarnicao_army.commander, mina.guarnicao_army.cards, mina.reference_commander,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits,
		FIRST_BLOCK_THREAD_COUNT
	)
	refresh()


## Mantém a tela viva sozinha enquanto algum bloco estiver em
## andamento — sem isso, o jogador só veria "calculando..." atualizar
## se reabrisse a tela manualmente. Checagem leve (a cada meio
## segundo, não todo frame) — só chama refresh() quando há
## efetivamente algo em andamento, pra não gastar processamento à toa.
var _process_accumulator: float = 0.0

func _process(delta: float) -> void:
	if is_queued_for_deletion():
		return  # evita sobreposição com outra instância desta tela ainda viva no mesmo frame (queue_free() só remove de verdade no fim do frame)

	var kingdom: Kingdom = KingdomState.kingdom
	var has_pending: bool = false
	for mina: Mina in kingdom.all_mines():
		if not mina.efficiency_pending_task_ids.is_empty():
			has_pending = true
			break
	if not has_pending:
		return

	_process_accumulator += delta
	if _process_accumulator < 0.5:
		return
	_process_accumulator = 0.0

	GameRuntime.sync(kingdom, GameClock.now_unix())
	refresh()


## Mina Inicial: ativa direto, sempre 100% de eficiência — sem
## Guarnição, sem simulação (MINES.md, "Mina Inicial (Bootstrap)").
func _on_activate_initial_mine_pressed(mina: Mina) -> void:
	mina.start_cycle(GameClock.now_unix(), 1.0)
	refresh()


## F-020, generalizado em F-021.3.1: Evoluir Nível Estrutural de
## qualquer Mina (Inicial ou Regional). Nenhuma regra nova — só chama
## MineEvolutionResolver.evolve() (custo/gasto/incremento já
## existentes) e traduz uma eventual falha pra mensagem legível.
func _on_evoluir_mina_pressed(mina: Mina) -> void:
	var result: Dictionary = MineEvolutionResolver.evolve(KingdomState.kingdom, mina)
	if result["success"]:
		_mina_status_text.erase(mina)
	else:
		_mina_status_text[mina] = _evoluir_failure_message(result["reason"])
	refresh()


## Traduz a "reason" de MineEvolutionResolver.evolve() (ver docstring do
## próprio Resolver) pra uma frase que o jogador entende — nunca o
## código cru na tela.
func _evoluir_failure_message(reason: String) -> String:
	match reason:
		"max_level":
			return "Nível Estrutural máximo já atingido."
		"insufficient_pg":
			return "Pontos de Geração insuficientes para esta evolução."
		_:
			return "Não foi possível evoluir (%s)." % reason


## FASE 19: clique em qualquer ponto não-interativo de um card Principal
## abre o modal de detalhe dessa Mina. Nunca conectado em card Regional.
func _on_principal_card_gui_input(event: InputEvent, mina: Mina) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_mina_detail = mina
		refresh()


## Reconstrói o overlay do modal de detalhe (nunca acumula: sempre
## remove o anterior antes de decidir se cria um novo) — chamado a cada
## refresh(), mesmo padrão de "árvore em código, reconstruída a cada
## ação" do resto do arquivo.
func _refresh_mina_detail_modal() -> void:
	if _mina_detail_overlay != null:
		remove_child(_mina_detail_overlay)
		_mina_detail_overlay.free()
		_mina_detail_overlay = null
	if _mina_detail != null:
		_mina_detail_overlay = _build_mina_detail_modal(_mina_detail)
		add_child(_mina_detail_overlay)


## Janela de detalhe (FASE 19) — overlay sobre a própria tela (nunca uma
## cena nova, nunca navegação), só para Minas Principais. Mostra
## SOMENTE nome + asset completo (MineArtCatalog, sem corte:
## STRETCH_KEEP_ASPECT_CENTERED numa caixa dimensionada pela proporção
## real da textura, nunca deformada) + Produção — nenhum dado
## administrativo (nível estrutural, ciclo, guarnição, eficiência etc.
## permanecem só no card). Mesmo padrão de overlay/backdrop já usado em
## academia_producao_panel.gd::_build_card_zoom_overlay(): backdrop
## escuro (fecha ao clicar fora) + CenterContainer (MOUSE_FILTER_IGNORE)
## + moldura dourada já existente (_card_style()) — nenhum estilo novo.
func _build_mina_detail_modal(mina: Mina) -> Control:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_mina_detail_backdrop_gui_input, CONNECT_DEFERRED)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var texture: Texture2D = preload("res://engine/presentation/mine_art_catalog.gd").texture_for(mina)
	var tex_size: Vector2 = texture.get_size() if texture != null else Vector2(4.0, 3.0)
	var aspect: float = tex_size.x / tex_size.y if tex_size.y > 0.0 else 1.0

	# Proporção real da textura preservada — nunca um tamanho fixo igual
	# pras 3 Minas (Ferro Negro é 1536x1024, as outras duas 1402x1122).
	# get_viewport_rect() exige estar na SceneTree (não é o caso nos
	# testes nativos, que instanciam o painel sem add_child) — fallback
	# pra uma resolução de referência evita um erro de engine à toa.
	var viewport_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(1280.0, 720.0)
	var image_height: float = viewport_size.y * 0.5
	var image_width: float = image_height * aspect
	var max_width: float = viewport_size.x * 0.7
	if image_width > max_width:
		image_width = max_width
		image_height = image_width / aspect

	var modal_box := PanelContainer.new()
	modal_box.custom_minimum_size = Vector2(image_width, 0)
	modal_box.add_theme_stylebox_override("panel", _card_style())
	center.add_child(modal_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	modal_box.add_child(vbox)

	var title := Label.new()
	title.text = INITIAL_MINE_NAMES.get(mina.faction, "Mina").to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_plain(title, 20, HUD_ACCENT)
	vbox.add_child(title)

	var image_box := Control.new()
	image_box.custom_minimum_size = Vector2(image_width, image_height)
	vbox.add_child(image_box)

	var image_rect := TextureRect.new()
	image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Mesma causa raiz do card (ver docstring do topo): sem
	# EXPAND_IGNORE_SIZE, o Control seria forçado ao tamanho NATIVO da
	# textura em vez do tamanho calculado acima pela proporção real.
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_rect.texture = texture
	image_rect.visible = texture != null
	image_box.add_child(image_rect)

	vbox.add_child(_build_gold_separator())
	vbox.add_child(_build_stat_block("Produção", _producao_text_for_initial_mine(mina)))

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(close_row)
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.pressed.connect(_on_mina_detail_close_pressed, CONNECT_DEFERRED)
	close_row.add_child(close_button)

	return backdrop


func _on_mina_detail_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_mina_detail = null
		refresh()


func _on_mina_detail_close_pressed() -> void:
	_mina_detail = null
	refresh()


## FASE 17: ponto de integração único e isolado para "IR PARA MINA"
## (Minas Regionais). Auditoria confirmou que não existe hoje nenhuma
## tela de mapa espacial nem de detalhe/localização de Mina, e que
## nenhum fluxo de jogo real consegue conquistar uma Mina Regional
## (MineConquestResolver.attempt_conquest() só é chamado em testes) —
## não há destino real para navegar. Por isso este corpo permanece
## vazio de propósito: nenhuma tela inventada, nenhum destino
## provisório. O botão que dispara isto fica desabilitado (ver
## _build_regional_card()) até que uma implementação real exista aqui —
## quando existir, deve navegar usando "territory_id" + a própria
## "mina" (nunca o nome textual) como identificador, já que Mina não
## possui um ID próprio (o par territory_id + mina.adjacent_fase é o
## identificador real, ver docstring do topo).
func _on_ir_para_mina_pressed(territory_id: String, mina: Mina) -> void:
	pass


func _on_back_to_command_center_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/world_map_gate/world_map_gate_panel.tscn")
