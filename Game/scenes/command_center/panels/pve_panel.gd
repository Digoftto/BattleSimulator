extends Control
## PvEPanel (COMMAND_CENTER_UI.md, "Janela: PvE") — F-020
##
## Duas telas, mesma árvore em código sem estado próprio (padrão do
## projeto): SELECTION (escolher Território/Facção, montar o Squad,
## listar Expedições ativas) e TRILHA_MAP (mapa espacial de uma
## Expedição — nós de Fase virtualizados numa janela ao redor da Fase
## atual, progressão automática, Acampamento e Mina como overlays).
##
## Progressão automática (F-020, decisão 9): a Expedição avança sozinha
## via ExpeditionTickResolver, chamado dentro de GameRuntime.sync()
## (já chamado no início de refresh()). Este painel nunca decide QUANDO
## uma tentativa acontece — só observa o resultado e, enquanto a tela
## TRILHA_MAP está visível, chama refresh() periodicamente (Timer de
## exibição, não uma segunda economia de tempo) para que o avanço
## automático fique visível sem exigir ação do jogador.

enum ScreenState { SELECTION, TRILHA_MAP }

var _screen_state: ScreenState = ScreenState.SELECTION

# --- Tela SELECTION ---
var _root_vbox: VBoxContainer
var _expedicoes_container: VBoxContainer
var _new_expedition_territories: Array[Territory] = []
var _new_expedition_territory: Territory = null
var _pending_squad_armies: Array[Army] = []
var _army_editor_overlay: ArmyEditorPanel = null
var _nova_expedicao_status_label: Label
var _existing_armies_container: VBoxContainer
var _nova_expedicao_iniciar_button: Button
var _nova_expedicao_trilha_art: TextureRect

# --- Tela TRILHA_MAP ---
var _map_root: Control = null
var _map_header_title: Label = null
var _map_header_fase: Label = null
var _map_header_status: Label = null
var _map_header_energy_caption: Label = null
var _map_header_energy_bar: ProgressBar = null
var _map_backdrop: TextureRect = null
var _map_area_inner: Control = null
var _map_nodes_container: Control = null
var _prev_segment_button: Button = null
var _next_segment_button: Button = null
var _battle_window: PanelContainer = null
var _battle_window_vbox: VBoxContainer = null
var _active_expedition: ExpeditionRuntime = null

## F-021: a Trilha vira páginas fixas de SEGMENT_SIZE Fases (nunca mais
## uma janela deslizante) — cada página distribui seus nós ao longo da
## MESMA curva real extraída da arte (TrilhaPathLayout), reaproveitada a
## cada página (ver auditoria da Fase 20.3, item H — a arte tem só
## ~25-33 nós fixos por Região, que tem até 3.000 Fases reais; não há
## como mapear 1:1 sem inventar dados). Sempre um múltiplo de
## SEGMENT_SIZE + 1 (Fase 1, 26, 51, ...).
var _map_segment_start_fase: int = 1

var _camp_overlay: Control = null
var _mine_overlay: Control = null
var _tick_timer: Timer = null

## Auditoria pré-pré-alfa (item #17, Replay de Fases PvE): true enquanto
## um CombatReplayView de "REVER" está na árvore, aguardando
## replay_finished — nunca guardado num Control próprio como
## _camp_overlay/_mine_overlay porque a própria CombatReplayView já se
## remove sozinha (view.queue_free() em _on_fase_replay_pressed()); só
## serve pra impedir abrir um 2º REVER por cima do primeiro.
var _replay_view_active: bool = false

## Baseline do tamanho de history_log por Expedição — usado só para
## detectar "uma tentativa automática acabou de acontecer" (o gatilho do
## banner do tutorial TUT-001 Passo 4, que antes dependia do clique
## manual em "Tentar Fase Atual").
var _last_history_log_size: Dictionary = {}  # ExpeditionRuntime -> int

const SEGMENT_SIZE: int = 25
const NODE_SIZE: int = 44
const CAMP_NODE_WIDTH: int = 96
const MINE_MARKER_SIZE: int = 28
const MAP_POLL_INTERVAL_SECONDS: float = 3.0
## Todos os 9 assets de Trilha (ART-003) são 1536x1024 — usado para
## calcular a posição de crop real de STRETCH_KEEP_ASPECT_COVERED e
## posicionar os nós exatamente sobre o caminho pintado, em qualquer
## resolução de tela (F-021, item 18).
const TRILHA_ART_NATIVE_SIZE: Vector2 = Vector2(1536.0, 1024.0)

## Mesmo padrão de identidade visual já usado em toda a Cidade/Command
## Center (minas_panel.gd, city_panel.gd) — replicado aqui, não
## compartilhado (nenhuma classe de estilo comum existe no projeto).
const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_WARNING_COLOR: Color = Color(1.0, 0.75, 0.55)
const HUD_VICTORY_COLOR: Color = Color(0.5, 0.85, 0.5)


var _loading_label: Label = null

## F-047: -1.0 = usa o ritmo humano padrão do CombatReplayView (0.6s
## por evento). Testes automatizados setam 0.0 aqui, pra reproduzir a
## batalha real instantaneamente. Só usado hoje pela Conquista de Mina
## (única ação que ainda dispara combate por clique direto do jogador —
## a marcha pela Trilha em si é automática, sem replay animado por
## tentativa, ver docstring do topo).
var replay_speed_override: float = -1.0

## TUT-001: referência ao banner de dica atualmente na tela (Passo 3 ou
## Passo 4 — nunca os dois ao mesmo tempo).
var _tutorial_banner = null


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
	_maybe_show_tutorial_hint()
	print("[PvEPanel] Pronto. Expedições ativas: %d" % KingdomState.kingdom.active_expeditions.size())


func _exit_tree() -> void:
	_stop_tick_timer()


## TUT-001, Passo 3/4 (PvE): mostrado uma única vez, no passo certo do
## tutorial mínimo — mesma trava dupla já usada em
## CityPanel/ExercitosPanel._maybe_show_tutorial_hint(). Nunca bloqueia
## a montagem do Squad/navegação por baixo.
func _maybe_show_tutorial_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_concluido") or kingdom.tutorial_step != Kingdom.TUTORIAL_STEP_PVE:
		return

	_free_tutorial_banner()
	_tutorial_banner = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	_tutorial_banner.setup(
		"Sua Primeira Expedição",
		"Escolha um Território, adicione seu Exército ao Squad com 'Usar no Squad' e clique em 'Iniciar Expedição'. A partir daí a marcha pela Trilha acontece sozinha — acompanhe o mapa.",
		"Passo 3 de 4"
	)
	_tutorial_banner.continue_pressed.connect(_on_tutorial_hint_continue, CONNECT_DEFERRED)
	add_child(_tutorial_banner)


func _on_tutorial_hint_continue() -> void:
	KingdomState.kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_POS_COMBATE
	_free_tutorial_banner()


func _free_tutorial_banner() -> void:
	if _tutorial_banner != null:
		_tutorial_banner.queue_free()
		_tutorial_banner = null


## TUT-001, Passo 4/4. Antes disparado pelo clique manual em "Tentar
## Fase Atual"; agora a marcha é automática, então quem chama este
## método é _refresh_trilha_map() ao detectar que history_log cresceu
## desde o refresh() anterior (ver _last_history_log_size).
func _maybe_show_post_combat_tutorial_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var step: int = kingdom.tutorial_step
	if kingdom.has_progress_flag("tutorial_concluido") \
		or (step != Kingdom.TUTORIAL_STEP_PVE and step != Kingdom.TUTORIAL_STEP_POS_COMBATE):
		return

	_free_tutorial_banner()
	_tutorial_banner = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	_tutorial_banner.setup(
		"Primeira Batalha Concluída",
		"O mapa acima mostra o que aconteceu e, em caso de vitória, a recompensa (Fragmentos) já creditada ao seu Reino. Volte para a Cidade quando quiser — o resto do Reino já está liberado para você explorar.",
		"Passo 4 de 4"
	)
	_tutorial_banner.continue_pressed.connect(_on_post_combat_tutorial_hint_continue, CONNECT_DEFERRED)
	add_child(_tutorial_banner)


func _on_post_combat_tutorial_hint_continue() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_CONCLUIDO
	kingdom.set_progress_flag("tutorial_concluido")
	_free_tutorial_banner()


func _show_loading_indicator() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.name = "LoadingBackground"
	add_child(background)

	_loading_label = Label.new()
	_loading_label.text = "Carregando o Mundo... (só na primeira vez — pode levar alguns segundos)"
	_loading_label.set_anchors_preset(Control.PRESET_CENTER)
	_loading_label.add_theme_font_size_override("font_size", 20)
	add_child(_loading_label)


func _hide_loading_indicator() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_loading_label = null


# ------------------------------------------------------------------
# Estrutura estática — SELECTION
# ------------------------------------------------------------------

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
	title.text = "PvE — Escolha sua Expedição"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para o World Map Gate"
	back_button.pressed.connect(_on_back_to_command_center_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	var expedicoes_title := Label.new()
	expedicoes_title.text = "Expedições Ativas"
	expedicoes_title.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(expedicoes_title)

	_expedicoes_container = VBoxContainer.new()
	_expedicoes_container.add_theme_constant_override("separation", 8)
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
	territory_label.text = "Território/Facção:"
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

	# ART-003: prévia real da Trilha (Região I — toda Expedição nova
	# começa nela) do Território selecionado. Some (visible=false) se a
	# Facção não tiver arte integrada.
	_nova_expedicao_trilha_art = TextureRect.new()
	_nova_expedicao_trilha_art.custom_minimum_size = Vector2(0, 160)
	_nova_expedicao_trilha_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nova_expedicao_trilha_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_root_vbox.add_child(_nova_expedicao_trilha_art)

	_nova_expedicao_status_label = Label.new()
	_root_vbox.add_child(_nova_expedicao_status_label)

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

	_build_map_static_structure()


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
## Formações. Reaproveitado tanto pela montagem de Squad em SELECTION
## quanto pelo overlay de Acampamento em TRILHA_MAP — screen-agnóstico.
func _on_edit_formations_pressed(army: Army) -> void:
	if _army_editor_overlay != null:
		return
	_army_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_army_editor_overlay.existing_army = army
	_army_editor_overlay.army_ready.connect(_on_edit_formations_army_ready, CONNECT_DEFERRED)
	_army_editor_overlay.cancelled.connect(_on_new_expedition_army_editor_cancelled, CONNECT_DEFERRED)
	add_child(_army_editor_overlay)


func _on_edit_formations_army_ready(_army: Army) -> void:
	call_deferred("_finish_new_expedition_army", null)


func _on_use_existing_army_pressed(army: Army) -> void:
	_pending_squad_armies.append(army)
	refresh()


# ------------------------------------------------------------------
# refresh() — despacha por tela
# ------------------------------------------------------------------

func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	# F-020: aqui é onde ExpeditionTickResolver (dentro de GameRuntime.sync())
	# pode disparar no máximo 1 tentativa automática por Expedição ativa.
	GameRuntime.sync(kingdom, GameClock.now_unix())

	match _screen_state:
		ScreenState.SELECTION:
			_refresh_selection()
		ScreenState.TRILHA_MAP:
			_refresh_trilha_map()


func _refresh_selection() -> void:
	_root_vbox.get_parent().visible = true
	_map_root.visible = false

	var kingdom: Kingdom = KingdomState.kingdom
	_clear_children(_expedicoes_container)
	_refresh_nova_expedicao_status()
	_refresh_existing_armies_list()

	for expedition: ExpeditionRuntime in kingdom.active_expeditions:
		var row := PanelContainer.new()
		_expedicoes_container.add_child(row)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)

		var info_label := Label.new()
		info_label.text = "%s | Fase %d de %d | %s" % [
			expedition.territory.id, expedition.current_fase, expedition.trilha.total_fases(), _status_name(expedition.status)
		]
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_label)

		if expedition.status == ExpeditionRuntime.Status.EM_ANDAMENTO:
			var view_button := Button.new()
			view_button.text = "Ver Trilha"
			view_button.pressed.connect(_on_view_expedition_pressed.bind(expedition), CONNECT_DEFERRED)
			hbox.add_child(view_button)

	if _expedicoes_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma Expedição em andamento. Use 'Iniciar Nova Expedição' abaixo para montar um Squad e partir."
		_expedicoes_container.add_child(empty_label)


func _on_view_expedition_pressed(expedition: ExpeditionRuntime) -> void:
	_active_expedition = expedition
	_map_segment_start_fase = _segment_start_for_fase(expedition.current_fase)
	_last_history_log_size[expedition] = expedition.history_log.size()
	_screen_state = ScreenState.TRILHA_MAP
	_start_tick_timer()
	refresh()
	_maybe_show_energy_contextual_hint(expedition)


## F-021.5 (dica contextual, independente da sequência linear TUT-001):
## primeira vez que o jogador vê o mapa de uma Expedição real, explica a
## barra de Energia (F-021.4) — nunca disparada enquanto outra dica
## (_tutorial_banner) já ocupa o mesmo espaço, nunca reaberta depois de
## dispensada (progress_flag própria, independente de tutorial_step).
func _maybe_show_energy_contextual_hint(expedition: ExpeditionRuntime) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_hint_energia_visto") or _tutorial_banner != null:
		return
	if expedition.squad.active_army() == null:
		return

	_tutorial_banner = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	_tutorial_banner.setup(
		"Energia",
		"A barra 'ENERGIA' no topo mostra quanto seu Exército ainda pode marchar (passe o mouse para ver o número exato). Quando ela esgota, a Expedição para e retorna ao último Acampamento — a Energia só se recupera lá ou na Cidade, nunca durante a marcha.",
		"Dica"
	)
	_tutorial_banner.continue_pressed.connect(_on_energy_hint_continue, CONNECT_DEFERRED)
	add_child(_tutorial_banner)


func _on_energy_hint_continue() -> void:
	KingdomState.kingdom.set_progress_flag("tutorial_hint_energia_visto")
	_free_tutorial_banner()


func _on_back_to_selection_pressed() -> void:
	_stop_tick_timer()
	_active_expedition = null
	_screen_state = ScreenState.SELECTION
	refresh()


## F-021 (herdado): retorna o nome cru do enum como texto legível.
func _status_name(status: ExpeditionRuntime.Status) -> String:
	match status:
		ExpeditionRuntime.Status.EM_ANDAMENTO:
			return "Em andamento"
		ExpeditionRuntime.Status.CONCLUIDA:
			return "Concluída"
		ExpeditionRuntime.Status.ENCERRADA:
			return "Encerrada"
		_:
			return ExpeditionRuntime.Status.keys()[status]


## F-021.4: única função que escreve na barra/legenda de Energia do
## header — lê SEMPRE expedition.squad.active_army() (fonte real, nunca
## copiada/duplicada). ENERGY.md, "Interface": barra de fadiga sempre
## visível, valor numérico "atual/máximo" só em hover (tooltip nativo).
## Sem Exército ativo (Squad esgotado — não deveria acontecer entre
## Tentativas, PhaseResolver sempre reinicia o Squad, mas defensivo
## nunca custa nada): esconde a linha inteira, nunca mostra um valor
## inventado.
func _refresh_energy_row(expedition: ExpeditionRuntime) -> void:
	var squad: Squad = expedition.squad
	var army: Army = squad.active_army()
	# Squad.active_army() retorna null num estado transitório real: logo
	# após uma derrota que esgota o Squad inteiro (Squad.is_exhausted()),
	# antes da PRÓXIMA tentativa reiniciá-lo do zero (docstring de
	# attempt_current_fase()). Sem este fallback, a barra desapareceria
	# exatamente no momento em que o pedido F-021.4 exige o oposto
	# (Energia esgotada precisa ficar MAIS clara, nunca some da tela) —
	# mostra o último Exército real do Squad (nunca um valor inventado).
	if army == null and not squad.armies.is_empty():
		army = squad.armies[mini(squad.active_index, squad.armies.size() - 1)]
	if army == null or army.max_energy <= 0:
		_map_header_energy_caption.visible = false
		_map_header_energy_bar.visible = false
		return

	_map_header_energy_caption.visible = true
	_map_header_energy_bar.visible = true

	var commander_name: String = army.commander.commander_name if army.commander != null else "sem Comandante"
	var exhausted: bool = army.current_energy <= 0
	var ratio: float = clampf(float(army.current_energy) / float(army.max_energy), 0.0, 1.0)

	_map_header_energy_bar.value = ratio
	_map_header_energy_bar.tooltip_text = "%d / %d" % [army.current_energy, army.max_energy]

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HUD_WARNING_COLOR if (exhausted or ratio <= 0.2) else HUD_ACCENT
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_map_header_energy_bar.add_theme_stylebox_override("fill", fill_style)

	if exhausted:
		_map_header_energy_caption.text = "ENERGIA — %s (%s) — ESGOTADA, aguardando decisão no Acampamento" % [army.army_name, commander_name]
		_style_plain(_map_header_energy_caption, 11, HUD_WARNING_COLOR)
	else:
		_map_header_energy_caption.text = "ENERGIA — %s (%s)" % [army.army_name, commander_name]
		_style_plain(_map_header_energy_caption, 11, HUD_MUTED_COLOR)


# ------------------------------------------------------------------
# Estrutura estática — TRILHA_MAP
# ------------------------------------------------------------------

func _build_map_static_structure() -> void:
	_map_root = Control.new()
	_map_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_root.visible = false
	add_child(_map_root)

	var map_background := ColorRect.new()
	map_background.color = Color(0.10, 0.10, 0.13)
	map_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_root.add_child(map_background)

	var map_vbox := VBoxContainer.new()
	map_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_vbox.add_theme_constant_override("separation", 8)
	map_vbox.offset_left = 16
	map_vbox.offset_right = -16
	map_vbox.offset_top = 12
	map_vbox.offset_bottom = -12
	_map_root.add_child(map_vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	map_vbox.add_child(top_row)

	var back_to_selection_button := Button.new()
	back_to_selection_button.text = "<- Território/Região"
	_style_button(back_to_selection_button)
	back_to_selection_button.pressed.connect(_on_back_to_selection_pressed, CONNECT_DEFERRED)
	top_row.add_child(back_to_selection_button)

	var back_to_gate_button := Button.new()
	back_to_gate_button.text = "<- World Map Gate"
	_style_button(back_to_gate_button)
	back_to_gate_button.pressed.connect(_on_back_to_command_center_pressed, CONNECT_DEFERRED)
	top_row.add_child(back_to_gate_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var center_button := Button.new()
	center_button.text = "Centralizar na Fase Atual"
	_style_button(center_button)
	center_button.pressed.connect(_on_center_map_pressed, CONNECT_DEFERRED)
	top_row.add_child(center_button)

	# --- Cabeçalho: Facção/Região em destaque, Fase atual, estado real ---
	var header_card := PanelContainer.new()
	header_card.add_theme_stylebox_override("panel", _card_style())
	map_vbox.add_child(header_card)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 2)
	header_card.add_child(header_vbox)

	_map_header_title = Label.new()
	_style_plain(_map_header_title, 20, HUD_TEXT_COLOR)
	header_vbox.add_child(_map_header_title)

	_map_header_fase = Label.new()
	_style_plain(_map_header_fase, 15, HUD_ACCENT)
	header_vbox.add_child(_map_header_fase)

	_map_header_status = Label.new()
	_style_plain(_map_header_status, 12, HUD_MUTED_COLOR)
	_map_header_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	header_vbox.add_child(_map_header_status)

	# --- F-021.4: Energia do Exército ativo da Expedição, sempre visível
	# durante a navegação normal (ENERGY.md, "Interface" — barra de
	# fadiga, valor numérico só em hover). Fonte real única:
	# expedition.squad.active_army().current_energy/max_energy — nunca
	# um valor calculado/copiado aqui (ver _refresh_energy_row()). ---
	var energy_row := VBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 2)
	header_vbox.add_child(energy_row)

	_map_header_energy_caption = Label.new()
	_style_plain(_map_header_energy_caption, 11, HUD_MUTED_COLOR)
	_map_header_energy_caption.autowrap_mode = TextServer.AUTOWRAP_WORD
	energy_row.add_child(_map_header_energy_caption)

	_map_header_energy_bar = ProgressBar.new()
	_map_header_energy_bar.min_value = 0.0
	_map_header_energy_bar.max_value = 1.0
	_map_header_energy_bar.step = 0.0  # sem isto, Range arredonda .value pro múltiplo de 0.01 mais próximo (default), perdendo precisão real do preenchimento.
	_map_header_energy_bar.show_percentage = false
	_map_header_energy_bar.custom_minimum_size = Vector2(0, 14)
	_map_header_energy_bar.mouse_filter = Control.MOUSE_FILTER_STOP  # necessário para o tooltip nativo (hover) responder.

	var energy_bg_style := StyleBoxFlat.new()
	energy_bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	energy_bg_style.corner_radius_top_left = 4
	energy_bg_style.corner_radius_top_right = 4
	energy_bg_style.corner_radius_bottom_left = 4
	energy_bg_style.corner_radius_bottom_right = 4
	_map_header_energy_bar.add_theme_stylebox_override("background", energy_bg_style)
	energy_row.add_child(_map_header_energy_bar)

	# --- Área do mapa: fundo decorativo real da Trilha (ART-003) + nós
	# de Fase posicionados sobre o próprio caminho pintado (F-021,
	# TrilhaPathLayout) — nunca repetido/tileado (F-020, decisão 1). ---
	var map_area := PanelContainer.new()
	map_area.add_theme_stylebox_override("panel", _card_style())
	map_area.custom_minimum_size = Vector2(0, 260)
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_vbox.add_child(map_area)

	var map_area_row := HBoxContainer.new()
	map_area_row.add_theme_constant_override("separation", 4)
	map_area.add_child(map_area_row)

	_prev_segment_button = _build_segment_arrow_button("<")
	_prev_segment_button.pressed.connect(_on_segment_prev_pressed, CONNECT_DEFERRED)
	map_area_row.add_child(_prev_segment_button)

	_map_area_inner = Control.new()
	_map_area_inner.clip_contents = true
	_map_area_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_area_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area_row.add_child(_map_area_inner)

	_map_backdrop = TextureRect.new()
	_map_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area_inner.add_child(_map_backdrop)

	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.22)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area_inner.add_child(scrim)

	# Container de posicionamento livre (Control puro, nunca um
	# Container de fluxo) — cada nó fica em .position, calculada sobre a
	# curva real da Trilha (F-021, item 1/2 do critério de aceitação).
	_map_nodes_container = Control.new()
	_map_nodes_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_nodes_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_area_inner.add_child(_map_nodes_container)

	_next_segment_button = _build_segment_arrow_button(">")
	_next_segment_button.pressed.connect(_on_segment_next_pressed, CONNECT_DEFERRED)
	map_area_row.add_child(_next_segment_button)

	# Janela de batalha (hover sobre Fase vencida) — filha direta de
	# _map_root (nunca dentro de _map_nodes_container, que é limpo/
	# reconstruído a cada refresh()) — F-021, itens 7/8.
	_battle_window = PanelContainer.new()
	_battle_window.visible = false
	_battle_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle_window.custom_minimum_size = Vector2(300, 0)
	_battle_window.add_theme_stylebox_override("panel", _card_style())
	_battle_window_vbox = VBoxContainer.new()
	_battle_window_vbox.add_theme_constant_override("separation", 4)
	_battle_window_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle_window.add_child(_battle_window_vbox)
	_map_root.add_child(_battle_window)


## Seta de navegação de segmento com identidade própria (nunca um
## Button Godot padrão sem tratamento) — F-021, item 4.
func _build_segment_arrow_button(glyph: String) -> Button:
	var button := Button.new()
	button.text = glyph
	button.custom_minimum_size = Vector2(36, 0)
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", HUD_ACCENT)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.12)
	normal_style.set_border_width_all(1)
	normal_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.6)
	normal_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.25)
	button.add_theme_stylebox_override("hover", hover_style)
	var disabled_style: StyleBoxFlat = normal_style.duplicate()
	disabled_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.05)
	disabled_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.2)
	button.add_theme_stylebox_override("disabled", disabled_style)
	return button


## Botões utilitários (voltar/centralizar) recebem o mesmo tratamento de
## fonte/cor do resto da tela, mesmo sem a moldura das setas de
## segmento (elas competiriam com a identidade das setas de navegação).
func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)


## Moldura dourada translúcida — mesmo padrão já usado em toda a Cidade/
## Command Center (minas_panel.gd::_card_style()).
func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.08)
	style.set_border_width_all(1)
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


## Texto dentro de um painel opaco (mesmo princípio de minas_panel.gd —
## contorno/sombra só fazem sentido sobre arte variável, nunca aqui).
func _style_plain(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


## Janela modal opaca (Acampamento/Mina) — fundo escuro sólido + moldura
## dourada, mesma identidade dos cards do mapa, mas opaca o bastante
## para ler texto sobre o backdrop escurecido do overlay.
func _modal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.07, 0.97)
	style.set_border_width_all(2)
	style.border_color = HUD_ACCENT
	style.set_corner_radius_all(8)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style


func _start_tick_timer() -> void:
	if _tick_timer == null:
		_tick_timer = Timer.new()
		_tick_timer.wait_time = MAP_POLL_INTERVAL_SECONDS
		_tick_timer.timeout.connect(refresh, CONNECT_DEFERRED)
		add_child(_tick_timer)
	# Timer.start() exige que o próprio nó já esteja dentro de uma
	# SceneTree ativa — nunca o caso quando o painel é exercitado fora
	# dela (mesmo padrão de teste de test_minas_panel_ui.gd). Em jogo
	# real o painel sempre está na árvore quando isto roda.
	if is_inside_tree():
		_tick_timer.start()


func _stop_tick_timer() -> void:
	if _tick_timer != null:
		_tick_timer.stop()


func _on_center_map_pressed() -> void:
	if _active_expedition != null:
		_map_segment_start_fase = _segment_start_for_fase(_active_expedition.current_fase)
	refresh()


## Primeira Fase da página de SEGMENT_SIZE que contém "fase" (sempre
## Fase 1, 26, 51, ... para SEGMENT_SIZE=25).
func _segment_start_for_fase(fase: int) -> int:
	return ((fase - 1) / SEGMENT_SIZE) * SEGMENT_SIZE + 1


func _on_segment_next_pressed() -> void:
	if _active_expedition == null:
		return
	var last_segment_start: int = _segment_start_for_fase(_active_expedition.trilha.total_fases())
	_map_segment_start_fase = mini(_map_segment_start_fase + SEGMENT_SIZE, last_segment_start)
	refresh()


func _on_segment_prev_pressed() -> void:
	_map_segment_start_fase = maxi(1, _map_segment_start_fase - SEGMENT_SIZE)
	refresh()


func _refresh_trilha_map() -> void:
	_map_root.visible = true
	_root_vbox.get_parent().visible = false

	if _active_expedition == null or not KingdomState.kingdom.active_expeditions.has(_active_expedition):
		_on_back_to_selection_pressed()
		return
	var expedition: ExpeditionRuntime = _active_expedition

	var previous_log_size: int = _last_history_log_size.get(expedition, expedition.history_log.size())
	if expedition.history_log.size() > previous_log_size:
		_maybe_show_post_combat_tutorial_hint()
	_last_history_log_size[expedition] = expedition.history_log.size()

	var total_fases: int = expedition.trilha.total_fases()
	var last_event: String = expedition.history_log[-1] if not expedition.history_log.is_empty() else ""

	_map_header_title.text = "%s — %s" % [expedition.territory.faction.to_upper(), expedition.territory.id]
	_map_header_fase.text = "REGIÃO %s | FASE %d DE %d" % [
		_region_roman(expedition.trilha.region_for_fase(expedition.current_fase)), expedition.current_fase, total_fases
	]
	_map_header_status.text = "%s — %s" % [_status_name(expedition.status), last_event]
	_refresh_energy_row(expedition)

	var region: int = expedition.trilha.region_for_fase(_map_segment_start_fase)
	_map_backdrop.texture = preload("res://engine/presentation/pve_art_catalog.gd").trilha_texture_for(expedition.territory.faction, region)
	_map_backdrop.visible = _map_backdrop.texture != null

	_clear_children(_map_nodes_container)

	var mines: Array[Mina] = []
	if KingdomState.kingdom.territory_mines.has(expedition.territory.id):
		mines = KingdomState.kingdom.territory_mines[expedition.territory.id]

	var segment_end: int = mini(total_fases, _map_segment_start_fase + SEGMENT_SIZE - 1)
	var count: int = segment_end - _map_segment_start_fase + 1

	# F-021, item H: a curva é a MESMA a cada página (recorte real da
	# arte, ver TrilhaPathLayout) — só os números de Fase mudam.
	var waypoints: Array[Vector2] = TrilhaPathLayout.waypoints_for(expedition.territory.faction, region)
	var points: Array[Vector2] = TrilhaPathLayout.evenly_spaced_points(waypoints, count)

	var area_size: Vector2 = _effective_map_area_size()

	for i in range(count):
		var fase: int = _map_segment_start_fase + i
		var state: Dictionary = _node_state_for_fase(expedition, fase)
		var anchor: Vector2 = _fraction_to_local(points[i] if i < points.size() else Vector2(0.5, 0.5), area_size)

		var node: Control = _build_fase_node(expedition, state)
		node.position = _clamped_top_left(anchor, node.custom_minimum_size, area_size)
		_map_nodes_container.add_child(node)
		var node_center: Vector2 = node.position + node.custom_minimum_size * 0.5

		var mina_here: Mina = null
		for mina: Mina in mines:
			if mina.adjacent_fase == fase:
				mina_here = mina
				break
		if mina_here != null:
			var mine_marker: Control = _build_mine_slot(expedition, mina_here)
			# F-021, decisão 3: a Mina NUNCA substitui o nó da Fase na
			# mesma posição (PvE.md — ramificação lateral opcional) —
			# desenhada deslocada, ligada por um traço fino.
			var mine_anchor: Vector2 = node_center + Vector2(0, NODE_SIZE * 0.95)
			var mine_top_left: Vector2 = _clamped_top_left(mine_anchor, mine_marker.custom_minimum_size, area_size)
			_map_nodes_container.add_child(_build_branch_stub(node_center, mine_top_left + mine_marker.custom_minimum_size * 0.5))
			mine_marker.position = mine_top_left
			_map_nodes_container.add_child(mine_marker)

	_prev_segment_button.disabled = _map_segment_start_fase <= 1
	_next_segment_button.disabled = segment_end >= total_fases


func _region_roman(region: int) -> String:
	match region:
		1: return "I"
		2: return "II"
		3: return "III"
		_: return str(region)


## Converte uma fração relativa (0.0-1.0 do asset 1536x1024) na posição
## LOCAL real dentro de _map_area_inner, replicando o crop de
## STRETCH_KEEP_ASPECT_COVERED — sem isto, os nós desalinhariam do
## caminho pintado sempre que a proporção da tela não fosse 1536:1024
## (F-021, item 18 — responsividade).
## Tamanho mínimo plausível de layout — abaixo disto, _map_area_inner
## ainda não recebeu um tamanho real do Container pai (ex: a PRIMEIRA
## sincronização logo depois de _map_root.visible virar true, antes do
## Godot processar um frame de layout — confirmado com screenshot real:
## um tamanho zero nesse primeiro refresh() colapsava todos os nós no
## mesmo canto após o clamp). Calculado UMA VEZ por refresh() e reusado
## tanto por _fraction_to_local() quanto por _clamped_top_left() — as
## duas precisam do MESMO tamanho corrigido, nunca um lendo o valor cru
## e o outro um valor já corrigido.
const MIN_PLAUSIBLE_AREA_SIZE: float = 50.0


func _effective_map_area_size() -> Vector2:
	var control_size: Vector2 = _map_area_inner.size
	if control_size.x >= MIN_PLAUSIBLE_AREA_SIZE and control_size.y >= MIN_PLAUSIBLE_AREA_SIZE:
		return control_size
	# Sem tamanho de layout confiável ainda (ex: painel testado fora da
	# SceneTree, mesmo padrão de test_minas_panel_ui.gd — nunca chama
	# get_viewport_rect() sem viewport, pra não travar) — cai para o
	# tamanho do viewport como aproximação segura.
	var viewport: Viewport = get_viewport()
	return viewport.get_visible_rect().size if viewport != null else TRILHA_ART_NATIVE_SIZE


func _fraction_to_local(frac: Vector2, control_size: Vector2) -> Vector2:
	var cover_scale: float = maxf(control_size.x / TRILHA_ART_NATIVE_SIZE.x, control_size.y / TRILHA_ART_NATIVE_SIZE.y)
	var scaled_size: Vector2 = TRILHA_ART_NATIVE_SIZE * cover_scale
	var offset: Vector2 = (control_size - scaled_size) * 0.5
	return offset + Vector2(frac.x * scaled_size.x, frac.y * scaled_size.y)


## Converte um centro desejado + tamanho do nó no canto superior-esquerdo
## real, garantindo que o nó nunca ultrapasse os limites da área do
## mapa — sem isto, nós largos (Acampamento) perto da borda da curva
## (fração x próxima de 0.0/1.0) ficariam parcialmente cortados pelo
## clip_contents da área (confirmado com screenshot real, F-021, item 18).
func _clamped_top_left(center: Vector2, node_size: Vector2, area_size: Vector2) -> Vector2:
	var half: Vector2 = node_size * 0.5
	var max_x: float = maxf(half.x, area_size.x - half.x)
	var max_y: float = maxf(half.y, area_size.y - half.y)
	var clamped_center := Vector2(
		clampf(center.x, half.x, max_x),
		clampf(center.y, half.y, max_y)
	)
	return clamped_center - half


func _node_state_for_fase(expedition: ExpeditionRuntime, fase: int) -> Dictionary:
	return {
		"fase": fase,
		"category": preload("res://engine/presentation/pve_art_catalog.gd").fase_category_for_fase_number(expedition.trilha, fase),
		"is_current": fase == expedition.current_fase,
		"is_passed": fase < expedition.current_fase,
		"history": expedition.fase_history.get(fase, null),
	}


## Nó de Fase posicionado livremente sobre a curva (F-021, itens 1-3):
## menor que antes, com borda/brilho/opacidade indicando o estado real
## (vencida = borda+selo verde, atual = borda dourada + escala maior,
## bloqueada = opacidade reduzida), usando os assets reais de categoria
## já integrados (PvEArtCatalog).
func _build_fase_node(expedition: ExpeditionRuntime, state: Dictionary) -> Control:
	var fase: int = state["fase"]
	var category: String = state["category"]
	var is_camp: bool = category == "acampamento"
	var is_current: bool = state["is_current"]
	var is_passed: bool = state["is_passed"]

	var node := PanelContainer.new()
	var node_size: Vector2 = Vector2(CAMP_NODE_WIDTH, NODE_SIZE) if is_camp else Vector2(NODE_SIZE, NODE_SIZE)
	if is_current:
		node_size *= 1.3
	node.custom_minimum_size = node_size
	node.size = node_size

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8 if is_camp else int(node_size.y * 0.5))
	var border_width: int = 2
	if category == "chefe_regional":
		border_width = 4
	elif category == "chefe_normal":
		border_width = 3

	if is_current:
		style.bg_color = Color(0.24, 0.20, 0.10, 0.9)
		style.border_color = Color(1.0, 0.85, 0.3)
		border_width += 2
	elif is_passed:
		style.bg_color = Color(0.10, 0.20, 0.10, 0.75)
		style.border_color = HUD_VICTORY_COLOR
	else:
		style.bg_color = Color(0.12, 0.12, 0.15, 0.55)
		style.border_color = Color(0.4, 0.4, 0.45)
	style.set_border_width_all(border_width)
	node.add_theme_stylebox_override("panel", style)
	node.modulate = Color(1, 1, 1, 1) if (is_current or is_passed) else Color(0.55, 0.55, 0.58, 0.55)

	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.mouse_entered.connect(_on_fase_node_mouse_entered.bind(state), CONNECT_DEFERRED)
	node.mouse_exited.connect(_on_fase_node_mouse_exited, CONNECT_DEFERRED)

	# Control simples (não-Container) como único filho do PanelContainer
	# — permite um selo de vitória com âncora própria sem o
	# PanelContainer forçar todos os filhos a preencherem o mesmo retângulo.
	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(content)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, node_size.y * 0.55)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = preload("res://engine/presentation/pve_art_catalog.gd").fase_icon_texture_for(expedition.territory.faction, category)
	icon.visible = icon.texture != null
	vbox.add_child(icon)

	var label := Label.new()
	label.text = str(fase)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_plain(label, 10, HUD_TEXT_COLOR)
	vbox.add_child(label)

	if is_passed:
		var check := Label.new()
		check.text = "✓"
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_style_plain(check, 12, HUD_VICTORY_COLOR)
		check.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		check.position += Vector2(-3, 1)
		content.add_child(check)

	if is_camp:
		# F-020, decisão 8: clicável a partir do momento em que a
		# Expedição alcança (ou já passou d)a Fase — abre a
		# administração do Acampamento (Squad/Editor de Exército).
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		node.gui_input.connect(_on_camp_node_gui_input.bind(expedition, fase), CONNECT_DEFERRED)
	else:
		# Auditoria pré-pré-alfa (item #17, Replay de Fases PvE, vitória
		# E derrota): NUNCA condicionado a "is_passed" — depois de uma
		# derrota total, current_fase volta ao último Acampamento
		# (ExpeditionRuntime.attempt_current_fase()), o que pode fazer
		# uma Fase já vencida (com histórico e replay reais) virar
		# "is_current" de novo, nunca mais "is_passed". O REVER precisa
		# continuar disponível mesmo assim — depende só de
		# fase_history[fase] de fato ter um "replay_id" (save anterior a
		# esta funcionalidade, ou replay já expurgado pelo limite de
		# armazenamento, nunca tem) — nunca abre um REVER pra um replay
		# que não existe mais.
		var history: Variant = state["history"]
		if history != null and (history as Dictionary).has("replay_id"):
			node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			node.gui_input.connect(_on_fase_node_gui_input.bind(expedition, (history as Dictionary)["replay_id"]), CONNECT_DEFERRED)

	return node


## Traço fino ligando o nó de Fase ao marcador de Mina lateral — nunca
## desenha um segundo caminho, só uma indicação curta de ramificação.
func _build_branch_stub(from: Vector2, to: Vector2) -> Control:
	var stub := Control.new()
	var top_left: Vector2 = Vector2(minf(from.x, to.x), minf(from.y, to.y))
	var size: Vector2 = (to - from).abs()
	size.x = maxf(size.x, 2.0)
	stub.position = top_left
	stub.size = size
	stub.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var line := Line2D.new()
	line.add_point(from - top_left)
	line.add_point(to - top_left)
	line.width = 2.0
	line.default_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.7)
	stub.add_child(line)
	return stub


func _on_camp_node_gui_input(event: InputEvent, expedition: ExpeditionRuntime, fase: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if fase > expedition.current_fase:
			return
		_open_camp_overlay(expedition)


func _on_fase_node_gui_input(event: InputEvent, expedition: ExpeditionRuntime, replay_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_fase_replay_pressed(expedition, replay_id)


## Auditoria pré-pré-alfa (item #17, Replay de Fases PvE — vitórias e
## derrotas): abre a MESMA CombatReplayView já usada por
## _play_battle_replays() (Conquista de Mina) — nunca um segundo
## visualizador. O par {state, collector} vem de
## BattleReplayRecord.from_persisted_dict(), reconstruído por NOME
## (GameDatabase.get_card()/get_battlefield()) a partir do que foi
## realmente gravado — nunca uma re-simulação de CombatEngine (Silêncio
## usa RNG não-seedada, tornar isso não-confiável é justamente por que
## este item existe).
func _on_fase_replay_pressed(expedition: ExpeditionRuntime, replay_id: String) -> void:
	if _camp_overlay != null or _mine_overlay != null or _army_editor_overlay != null or _replay_view_active:
		return
	var record: Dictionary = KingdomState.kingdom.battle_replays.get(replay_id, {})
	if record.is_empty():
		# Save antigo/replay já expurgado pelo limite de armazenamento
		# entre o momento do hover e o clique — degrada silenciosamente
		# (o hint só aparece quando replay_id existia ao abrir o balão).
		return

	_replay_view_active = true
	_stop_tick_timer()

	var reconstructed: Dictionary = preload("res://engine/combat/battle_replay_record.gd").from_persisted_dict(record)
	var view = load("res://scenes/combat/combat_replay_view.tscn").instantiate()
	view.combat_state = reconstructed["state"]
	view.replay_collector = reconstructed["collector"]
	view.player_side = reconstructed["player_side"]
	if replay_speed_override >= 0.0:
		view.DELAY_BETWEEN_EVENTS_SECONDS = replay_speed_override
		view.auto_continue_when_finished = true
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	await view.replay_finished
	view.queue_free()

	_replay_view_active = false
	if _screen_state == ScreenState.TRILHA_MAP:
		_start_tick_timer()
	refresh()


## Marcador de Mina (F-020, decisão 5, preservada na Fase 20.3): nenhum
## asset dedicado existe — reaproveita o ícone real do recurso que a
## Mina produz (ART-005), numa moldura circular pequena que o distingue
## de um nó de Fase comum. A arte completa (MineArtCatalog) só aparece
## no overlay, nunca aqui.
func _build_mine_slot(expedition: ExpeditionRuntime, mina: Mina) -> Control:
	var slot := Control.new()
	var size := Vector2(MINE_MARKER_SIZE, MINE_MARKER_SIZE)
	slot.custom_minimum_size = size
	slot.size = size

	var marker_panel := Panel.new()
	marker_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	marker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color(0.15, 0.12, 0.05, 0.9)
	marker_style.set_border_width_all(2)
	marker_style.border_color = HUD_ACCENT
	marker_style.set_corner_radius_all(int(MINE_MARKER_SIZE * 0.5))
	marker_panel.add_theme_stylebox_override("panel", marker_style)
	slot.add_child(marker_panel)

	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_right = -4
	icon.offset_top = 4
	icon.offset_bottom = -4
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = preload("res://engine/presentation/resource_art_catalog.gd").texture_for(MineEconomy.resource_for_faction(mina.faction))
	icon.modulate.a = 0.5 if mina.conquered else 1.0
	slot.add_child(icon)

	var button := Button.new()
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_mine_node_pressed.bind(expedition, mina), CONNECT_DEFERRED)
	slot.add_child(button)

	return slot


# ------------------------------------------------------------------
# Janela de batalha (hover sobre Fase vencida) — F-021, itens 7/8/9/10/11
# ------------------------------------------------------------------

func _on_fase_node_mouse_entered(state: Dictionary) -> void:
	var history: Variant = state["history"]
	if history == null:
		_battle_window.visible = false
		return

	for child in _battle_window_vbox.get_children():
		_battle_window_vbox.remove_child(child)
		child.free()

	var title := Label.new()
	title.text = "FASE %d" % int(state["fase"])
	_style_plain(title, 16, HUD_TEXT_COLOR)
	_battle_window_vbox.add_child(title)

	var victory: bool = bool(history.get("victory", false))
	var result_label := Label.new()
	if victory:
		result_label.text = "VITÓRIA"
		_style_plain(result_label, 13, HUD_VICTORY_COLOR)
	else:
		var reason_text: String = "DERROTA EM COMBATE" if String(history.get("defeat_reason", "")) == "COMBAT_LOSS" else "ENERGIA ESGOTADA"
		result_label.text = reason_text
		_style_plain(result_label, 13, HUD_WARNING_COLOR)
	_battle_window_vbox.add_child(result_label)

	_battle_window_vbox.add_child(_make_gold_separator())

	var enemy_title := Label.new()
	enemy_title.text = "INIMIGO"
	_style_plain(enemy_title, 12, HUD_ACCENT)
	_battle_window_vbox.add_child(enemy_title)

	var enemy_name := Label.new()
	enemy_name.text = "%s (%s)" % [history.get("enemy_name", ""), history.get("enemy_faction", "")]
	enemy_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_plain(enemy_name, 13, HUD_TEXT_COLOR)
	_battle_window_vbox.add_child(enemy_name)

	var commander_name: String = String(history.get("commander_name", ""))
	if commander_name != "":
		var commander_label := Label.new()
		commander_label.text = "Comandante: %s" % commander_name
		_style_plain(commander_label, 12, HUD_MUTED_COLOR)
		_battle_window_vbox.add_child(commander_label)

	# F-021, item 10/11: só aparece quando o dado real existe — Fases
	# vencidas ANTES desta versão não têm esses campos (degrada
	# graciosamente, nunca inventa a composição).
	var enemy_cards: Array = history.get("enemy_formation_card_names", [])
	if not enemy_cards.is_empty():
		_battle_window_vbox.add_child(_build_formation_grid(enemy_cards))

	if victory:
		var player_army_name: String = String(history.get("player_army_name", ""))
		var player_cards: Array = history.get("player_formation_card_names", [])
		if player_army_name != "" or not player_cards.is_empty():
			_battle_window_vbox.add_child(_make_gold_separator())

			var player_title := Label.new()
			player_title.text = "SEU EXÉRCITO"
			_style_plain(player_title, 12, HUD_ACCENT)
			_battle_window_vbox.add_child(player_title)

			if player_army_name != "":
				var player_label := Label.new()
				player_label.text = "%s — Formação %s" % [player_army_name, String(history.get("player_formation_name", ""))]
				_style_plain(player_label, 13, HUD_TEXT_COLOR)
				_battle_window_vbox.add_child(player_label)

			if not player_cards.is_empty():
				_battle_window_vbox.add_child(_build_formation_grid(player_cards))

	# Auditoria pré-pré-alfa (item #17): só um texto informativo dentro
	# do balão — nunca clicável (_battle_window_vbox usa
	# MOUSE_FILTER_IGNORE de propósito, ver docstring da seção). O clique
	# de verdade acontece no próprio nó pequeno da Fase, já sob o cursor
	# (node.gui_input, ligado em _build_fase_node() apenas quando existe
	# um replay_id persistido).
	if history.has("replay_id"):
		_battle_window_vbox.add_child(_make_gold_separator())
		var rever_hint := Label.new()
		rever_hint.text = "[REVER] Clique nesta Fase para assistir à batalha novamente."
		rever_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		_style_plain(rever_hint, 11, HUD_ACCENT)
		_battle_window_vbox.add_child(rever_hint)

	_battle_window.visible = true
	# Deferido: o tamanho real do painel só fica correto depois que o
	# GridContainer/VBox processam os filhos recém-adicionados.
	call_deferred("_position_battle_window")


func _position_battle_window() -> void:
	if not _battle_window.visible:
		return
	var mouse_pos: Vector2 = _map_root.get_local_mouse_position()
	var target: Vector2 = mouse_pos + Vector2(18, 18)

	# F-021, item 18: nunca cobre o cabeçalho — usa os limites da ÁREA
	# DO MAPA (_map_area_inner), não da tela inteira. Numa tela baixa
	# (ex: 1152x648), uma janela alta empurrada por um clamp contra o
	# tamanho total da tela acabaria cobrindo o cabeçalho de Território/
	# Fase — confirmado visualmente com screenshot real.
	var area_top_left: Vector2 = _map_area_inner.global_position - _map_root.global_position
	var area_size: Vector2 = _map_area_inner.size
	var min_pos: Vector2 = area_top_left
	var max_pos: Vector2 = area_top_left + area_size - _battle_window.size
	max_pos.x = maxf(max_pos.x, min_pos.x)
	max_pos.y = maxf(max_pos.y, min_pos.y)

	target.x = clampf(target.x, min_pos.x, max_pos.x)
	target.y = clampf(target.y, min_pos.y, max_pos.y)
	_battle_window.position = target


func _on_fase_node_mouse_exited() -> void:
	_battle_window.visible = false


func _make_gold_separator() -> HSeparator:
	var separator := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.5)
	separator.add_theme_stylebox_override("separator", style)
	return separator


## Grade 3x3 real (F-021, item 8) — mesmo padrão de
## exercitos_panel.gd::_build_formation_grid() (somente-leitura, sem
## drag-and-drop), mas a partir de NOMES de carta persistidos (não
## referências CardResource — fase_history guarda dado plano),
## resolvidos de volta via GameDatabase.get_card(). Posição vazia (nome
## "" ou carta não encontrada) mostra só o número da posição — nunca
## uma carta inventada.
const FORMATION_VISUAL_ORDER: Array[int] = [0, 1, 2, 5, 4, 3, 6, 7, 8]
const FORMATION_CARD_WIDTH: float = 32.0


func _build_formation_grid(card_names: Array) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)

	for position_index: int in FORMATION_VISUAL_ORDER:
		var card_name: String = String(card_names[position_index]) if position_index < card_names.size() else ""
		grid.add_child(_build_formation_card_slot(card_name, position_index + 1))

	return grid


func _build_formation_card_slot(card_name: String, position_number: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(FORMATION_CARD_WIDTH, FORMATION_CARD_WIDTH / BattleCardView.CARD_ASPECT_RATIO)

	var card: CardResource = GameDatabase.get_card(card_name) if card_name != "" else null
	if card == null:
		var placeholder := Panel.new()
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		var placeholder_style := StyleBoxFlat.new()
		placeholder_style.bg_color = Color(0, 0, 0, 0.25)
		placeholder_style.set_border_width_all(1)
		placeholder_style.border_color = Color(HUD_MUTED_COLOR.r, HUD_MUTED_COLOR.g, HUD_MUTED_COLOR.b, 0.5)
		placeholder_style.set_corner_radius_all(3)
		placeholder.add_theme_stylebox_override("panel", placeholder_style)
		slot.add_child(placeholder)

		var position_label := Label.new()
		position_label.text = str(position_number)
		position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		position_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_style_plain(position_label, 10, HUD_MUTED_COLOR)
		slot.add_child(position_label)
		return slot

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(true)
	_force_ignore_mouse_recursive(card_view)

	return slot


## BattleCardView monta Controls internos sem mouse_filter próprio
## (herdam MOUSE_FILTER_STOP) — sem isto, a grade (puramente decorativa
## aqui, sem clique) poderia interceptar eventos indevidamente dentro da
## janela de batalha. Mesmo motivo já documentado em exercitos_panel.gd.
func _force_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_force_ignore_mouse_recursive(child)


# ------------------------------------------------------------------
# Overlay de Acampamento (F-020, decisões 8/20)
# ------------------------------------------------------------------

func _open_camp_overlay(expedition: ExpeditionRuntime) -> void:
	if _camp_overlay != null or _army_editor_overlay != null:
		return
	_stop_tick_timer()
	_camp_overlay = _build_camp_overlay(expedition)
	add_child(_camp_overlay)


## F-021.5 (dica contextual, reutilizável): um pequeno bloco
## dispensável — nunca a moldura ornamentada de TutorialHintBanner
## (achado real: colidia visualmente com a janela centralizada do
## Acampamento/Mina em telas baixas, 1152x648, confirmado por
## screenshot real). Usa só os estilos já existentes deste painel
## (_card_style()/_style_plain()/_style_button()) — nenhuma identidade
## visual nova. Retorna null quando a flag já foi marcada (quem chama
## simplesmente não adiciona nada, nunca um espaço vazio reservado).
func _build_inline_hint(body_text: String, flag_name: String) -> Control:
	if KingdomState.kingdom.has_progress_flag(flag_name):
		return null

	var box := PanelContainer.new()
	box.name = "InlineHint"
	box.add_theme_stylebox_override("panel", _card_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	var label := Label.new()
	label.text = body_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_plain(label, 12, HUD_ACCENT)
	row.add_child(label)

	var dismiss_button := Button.new()
	dismiss_button.text = "Entendi"
	_style_button(dismiss_button)
	dismiss_button.pressed.connect(_on_inline_hint_dismissed.bind(flag_name, box), CONNECT_DEFERRED)
	row.add_child(dismiss_button)

	return box


func _on_inline_hint_dismissed(flag_name: String, box: Control) -> void:
	KingdomState.kingdom.set_progress_flag(flag_name)
	box.queue_free()


func _build_camp_overlay(expedition: ExpeditionRuntime) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(560, 0)
	window.add_theme_stylebox_override("panel", _modal_style())
	center.add_child(window)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	window.add_child(vbox)

	var camp_hint: Control = _build_inline_hint(
		"Aqui a marcha para: você escolhe Continuar (com a Energia atual) ou Parar (aguardar Energia plena) a cada Acampamento, e pode reorganizar a Formação antes de seguir.",
		"tutorial_hint_acampamento_visto"
	)
	if camp_hint != null:
		vbox.add_child(camp_hint)

	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 140)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = preload("res://engine/presentation/pve_art_catalog.gd").fase_icon_texture_for(expedition.territory.faction, "acampamento")
	art.visible = art.texture != null
	vbox.add_child(art)

	var title := Label.new()
	title.text = "ACAMPAMENTO — FASE %d" % expedition.last_acampamento_fase
	_style_plain(title, 18, HUD_TEXT_COLOR)
	vbox.add_child(title)

	_build_squad_rows(vbox, expedition)
	_build_camp_decision_section(vbox, expedition)

	var close_button := Button.new()
	close_button.text = "Fechar"
	_style_button(close_button)
	close_button.pressed.connect(_on_camp_overlay_close_pressed, CONNECT_DEFERRED)
	vbox.add_child(close_button)

	return overlay


## Energia (do Exército Ativo do Squad) + a decisão real do Acampamento
## (auditoria pré-pré-alfa, ExpeditionRuntime.CampState) — nunca preenche
## Energia sozinho, nunca apresenta os 2 botões numa parada obrigatória
## (FORCED_UNTIL_FULL) ou já resolvida por escolha (RESTING_UNTIL_FULL).
func _build_camp_decision_section(vbox: VBoxContainer, expedition: ExpeditionRuntime) -> void:
	var active_army: Army = expedition.squad.armies[expedition.squad.active_index]

	var energy_label := Label.new()
	energy_label.text = "Energia: %d / %d" % [active_army.current_energy, active_army.max_energy]
	_style_plain(energy_label, 14, HUD_TEXT_COLOR)
	vbox.add_child(energy_label)

	match expedition.camp_state:
		ExpeditionRuntime.CampState.AWAITING_DECISION:
			var continue_button := Button.new()
			continue_button.text = "Continuar Expedição"
			_style_button(continue_button)
			continue_button.pressed.connect(_on_camp_continue_pressed.bind(expedition), CONNECT_DEFERRED)
			vbox.add_child(continue_button)
			var continue_caption := Label.new()
			continue_caption.text = "Continua imediatamente com a Energia atual — não espera chegar a 100%."
			continue_caption.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(continue_caption, 11, HUD_MUTED_COLOR)
			vbox.add_child(continue_caption)

			var stop_button := Button.new()
			stop_button.text = "Parar Expedição"
			_style_button(stop_button)
			stop_button.pressed.connect(_on_camp_stop_pressed.bind(expedition), CONNECT_DEFERRED)
			vbox.add_child(stop_button)
			var stop_caption := Label.new()
			stop_caption.text = "Aguarda a Energia chegar a 100% antes de continuar."
			stop_caption.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(stop_caption, 11, HUD_MUTED_COLOR)
			vbox.add_child(stop_caption)

		ExpeditionRuntime.CampState.RESTING_UNTIL_FULL:
			var resting_label := Label.new()
			resting_label.text = "Você optou por permanecer em repouso. A Expedição continuará automaticamente assim que a Energia atingir o máximo."
			resting_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(resting_label, 12, HUD_MUTED_COLOR)
			vbox.add_child(resting_label)

		ExpeditionRuntime.CampState.FORCED_UNTIL_FULL:
			var forced_label := Label.new()
			forced_label.text = "Você precisa recuperar sua Energia antes de continuar."
			forced_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(forced_label, 12, HUD_WARNING_COLOR)
			vbox.add_child(forced_label)

		ExpeditionRuntime.CampState.NONE:
			var resolved_label := Label.new()
			resolved_label.text = "Este Acampamento já foi resolvido — a Expedição já seguiu adiante."
			resolved_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			_style_plain(resolved_label, 12, HUD_MUTED_COLOR)
			vbox.add_child(resolved_label)


## Squad do Acampamento — reordenação só editável enquanto a Expedição
## está de fato parada (is_waiting_at_acampamento, qualquer CampState);
## "Editar Formações" sempre disponível (mesmo Editor de Exército de
## sempre, nunca duplicado).
func _build_squad_rows(vbox: VBoxContainer, expedition: ExpeditionRuntime) -> void:
	var squad_title := Label.new()
	squad_title.text = "SQUAD (ORDEM DE SUBSTITUIÇÃO)"
	_style_plain(squad_title, 12, HUD_ACCENT)
	vbox.add_child(squad_title)

	var can_reorder: bool = expedition.is_waiting_at_acampamento

	for i in range(expedition.squad.armies.size()):
		var army: Army = expedition.squad.armies[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var marker: String = "-> " if i == expedition.squad.active_index else "   "
		var display_name: String = army.army_name if army.army_name != "" else "Exército %d" % (i + 1)
		var label := Label.new()
		label.text = "%s%d. %s | Energia: %d/%d" % [marker, i + 1, display_name, army.current_energy, army.max_energy]
		label.custom_minimum_size = Vector2(260, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_style_plain(label, 13, HUD_TEXT_COLOR)
		row.add_child(label)

		var up_button := Button.new()
		up_button.text = "▲"
		_style_button(up_button)
		up_button.disabled = not can_reorder or i == 0
		up_button.pressed.connect(_on_move_army_pressed.bind(expedition, i, -1), CONNECT_DEFERRED)
		row.add_child(up_button)

		var down_button := Button.new()
		down_button.text = "▼"
		_style_button(down_button)
		down_button.disabled = not can_reorder or i == expedition.squad.armies.size() - 1
		down_button.pressed.connect(_on_move_army_pressed.bind(expedition, i, 1), CONNECT_DEFERRED)
		row.add_child(down_button)

		var edit_button := Button.new()
		edit_button.text = "Editar Formações"
		_style_button(edit_button)
		edit_button.disabled = _army_editor_overlay != null
		edit_button.pressed.connect(_on_edit_formations_pressed.bind(army), CONNECT_DEFERRED)
		row.add_child(edit_button)


func _on_move_army_pressed(expedition: ExpeditionRuntime, index: int, direction: int) -> void:
	var target: int = index + direction
	if target < 0 or target >= expedition.squad.armies.size():
		return
	var armies: Array[Army] = expedition.squad.armies
	var temp: Army = armies[index]
	armies[index] = armies[target]
	armies[target] = temp
	_rebuild_camp_overlay_if_open(expedition)
	refresh()


func _rebuild_camp_overlay_if_open(expedition: ExpeditionRuntime) -> void:
	if _camp_overlay == null:
		return
	remove_child(_camp_overlay)
	_camp_overlay.free()
	_camp_overlay = _build_camp_overlay(expedition)
	add_child(_camp_overlay)


func _on_camp_continue_pressed(expedition: ExpeditionRuntime) -> void:
	expedition.choose_continue_immediately()
	_close_camp_overlay()


func _on_camp_stop_pressed(expedition: ExpeditionRuntime) -> void:
	expedition.choose_stop_and_rest()
	_rebuild_camp_overlay_if_open(expedition)


func _on_camp_overlay_close_pressed() -> void:
	_close_camp_overlay()


func _close_camp_overlay() -> void:
	if _camp_overlay != null:
		remove_child(_camp_overlay)
		_camp_overlay.free()
		_camp_overlay = null
	if _screen_state == ScreenState.TRILHA_MAP:
		_start_tick_timer()
	refresh()


# ------------------------------------------------------------------
# Overlay de Mina (F-020, decisões 5/11/12)
# ------------------------------------------------------------------

func _on_mine_node_pressed(expedition: ExpeditionRuntime, mina: Mina) -> void:
	if _mine_overlay != null or _army_editor_overlay != null:
		return
	_stop_tick_timer()
	_mine_overlay = _build_mine_overlay(expedition, mina)
	add_child(_mine_overlay)


func _build_mine_overlay(expedition: ExpeditionRuntime, mina: Mina) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(480, 0)
	window.add_theme_stylebox_override("panel", _modal_style())
	center.add_child(window)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	window.add_child(vbox)

	var mina_hint: Control = _build_inline_hint(
		"Minas nas Trilhas produzem Recursos continuamente depois de conquistadas. Vença a formação defensora, depois designe uma Guarnição (tela de Minas, na Cidade) para começar a produção — nunca consomem Energia.",
		"tutorial_hint_mina_visto"
	)
	if mina_hint != null:
		vbox.add_child(mina_hint)

	# Arte completa da Mina (MineArtCatalog) — só aparece AQUI, nunca no
	# marcador do mapa (F-020, decisão 5).
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(0, 200)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = preload("res://engine/presentation/mine_art_catalog.gd").texture_for(mina)
	art.visible = art.texture != null
	vbox.add_child(art)

	var title := Label.new()
	title.text = "MINA DE %s — FASE %d" % [MineEconomy.resource_for_faction(mina.faction).to_upper(), mina.adjacent_fase]
	_style_plain(title, 18, HUD_TEXT_COLOR)
	vbox.add_child(title)

	var info := Label.new()
	if mina.conquered:
		info.text = "Conquistada. Nível Estrutural: %d." % mina.structure_level
	else:
		info.text = "Não conquistada. Região %s." % _region_roman(mina.region)
	_style_plain(info, 13, HUD_MUTED_COLOR)
	vbox.add_child(info)

	var status_label := Label.new()
	status_label.visible = false
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_plain(status_label, 12, HUD_WARNING_COLOR)
	vbox.add_child(status_label)

	if not mina.conquered:
		# F-020, decisão 12: proximidade checada AQUI (orquestração/UI),
		# nunca dentro de MineConquestResolver.
		var can_conquer: bool = expedition.current_fase >= mina.adjacent_fase
		var conquer_button := Button.new()
		conquer_button.text = "Conquistar"
		_style_button(conquer_button)
		conquer_button.disabled = not can_conquer
		if not can_conquer:
			status_label.visible = true
			status_label.text = "É preciso alcançar a Fase %d da Trilha antes de tentar conquistar esta Mina." % mina.adjacent_fase
		conquer_button.pressed.connect(_on_conquistar_mina_pressed.bind(expedition, mina), CONNECT_DEFERRED)
		vbox.add_child(conquer_button)

	var close_button := Button.new()
	close_button.text = "Fechar"
	_style_button(close_button)
	close_button.pressed.connect(_on_mine_overlay_close_pressed, CONNECT_DEFERRED)
	vbox.add_child(close_button)

	return overlay


## F-020, decisão 11: conquista real, mesmo combate/resolver usados em
## teste — nenhuma lógica duplicada aqui. expedition_seed reutilizado
## (já determinístico por Expedição, mesma fonte usada por
## EnemyArmySelector) — decisão 13.
func _on_conquistar_mina_pressed(expedition: ExpeditionRuntime, mina: Mina) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var result: PhaseResult = MineConquestResolver.attempt_conquest(
		mina, expedition.trilha, expedition.squad, expedition.season_catalog, expedition.territory.faction,
		expedition.expedition_seed, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	if result != null:
		await _play_battle_replays(result.battle_replays)
	_close_mine_overlay()


func _on_mine_overlay_close_pressed() -> void:
	_close_mine_overlay()


func _close_mine_overlay() -> void:
	if _mine_overlay != null:
		remove_child(_mine_overlay)
		_mine_overlay.free()
		_mine_overlay = null
	if _screen_state == ScreenState.TRILHA_MAP:
		_start_tick_timer()
	refresh()


# ------------------------------------------------------------------
# Utilidades
# ------------------------------------------------------------------

## O overlay do Editor de Exército NUNCA é tocado aqui — mesmo motivo já
## documentado em exercitos_panel.gd: qualquer refresh() enquanto o
## Editor está aberto por cima tentaria liberá-lo no meio da própria
## execução dele. _camp_overlay/_mine_overlay nunca precisam do mesmo
## guard porque são filhos diretos do painel (self), nunca de um
## container limpo por _clear_children().
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		if child == _army_editor_overlay:
			continue
		container.remove_child(child)
		child.free()


## F-047: reproduz visualmente cada combate REAL disputado (result.battle_replays).
## Hoje só acionado pela Conquista de Mina (única ação que ainda dispara
## combate por clique direto do jogador) — a marcha automática pela
## Trilha não reproduz replay animado por tentativa (ver docstring do
## topo).
func _play_battle_replays(battle_replays: Array) -> void:
	for entry: Dictionary in battle_replays:
		var view = load("res://scenes/combat/combat_replay_view.tscn").instantiate()
		view.combat_state = entry["state"]
		view.replay_collector = entry["collector"]
		view.player_side = 0
		if replay_speed_override >= 0.0:
			view.DELAY_BETWEEN_EVENTS_SECONDS = replay_speed_override
			view.auto_continue_when_finished = true
		view.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(view)
		await view.replay_finished
		view.queue_free()


func _refresh_nova_expedicao_status() -> void:
	if _new_expedition_territory == null:
		_nova_expedicao_status_label.text = "Nenhum Território disponível (Mundo ainda não carregou)."
		_nova_expedicao_iniciar_button.disabled = true
		_nova_expedicao_trilha_art.visible = false
		return

	var required: int = Squad.required_size(KingdomState.kingdom.get_territory_completion_count(_new_expedition_territory.id))
	_nova_expedicao_status_label.text = "Squad necessário: %d Exército(s) | Adicionados: %d/%d" % [
		required, _pending_squad_armies.size(), required
	]
	_nova_expedicao_iniciar_button.disabled = _pending_squad_armies.size() != required

	_nova_expedicao_trilha_art.texture = preload("res://engine/presentation/pve_art_catalog.gd").trilha_texture_for(_new_expedition_territory.faction, 1)
	_nova_expedicao_trilha_art.visible = _nova_expedicao_trilha_art.texture != null


func _on_new_expedition_territory_selected(index: int) -> void:
	_new_expedition_territory = _new_expedition_territories[index]
	_pending_squad_armies.clear()
	_refresh_nova_expedicao_status()


func _on_add_army_to_new_expedition_pressed() -> void:
	if _army_editor_overlay != null:
		return

	_army_editor_overlay = load("res://scenes/army/army_editor_panel.tscn").instantiate() as ArmyEditorPanel
	_army_editor_overlay.formation_count = 5
	_army_editor_overlay.army_ready.connect(_on_new_expedition_army_ready)
	_army_editor_overlay.cancelled.connect(_on_new_expedition_army_editor_cancelled)
	add_child(_army_editor_overlay)


func _on_new_expedition_army_ready(army: Army) -> void:
	_pending_squad_armies.append(army)
	call_deferred("_finish_new_expedition_army", army)


func _finish_new_expedition_army(_army: Army) -> void:
	if _army_editor_overlay != null:
		remove_child(_army_editor_overlay)
		_army_editor_overlay.queue_free()
		_army_editor_overlay = null
	if _active_expedition != null:
		_rebuild_camp_overlay_if_open(_active_expedition)
	refresh()


func _on_new_expedition_army_editor_cancelled() -> void:
	call_deferred("_finish_new_expedition_army", null)


## F-020: início da Expedição passa a usar GameRuntime.start_new_expedition()
## em vez de construir ExpeditionRuntime + Kingdom.start_expedition()
## direto — ganha de graça a geração real das Minas Regionais e a
## inicialização de Energia, sem duplicar essa lógica aqui.
func _on_start_new_expedition_pressed() -> void:
	if _new_expedition_territory == null:
		return

	var kingdom: Kingdom = KingdomState.kingdom
	var required: int = Squad.required_size(kingdom.get_territory_completion_count(_new_expedition_territory.id))
	if _pending_squad_armies.size() != required:
		return

	var season: Season = WorldDatabase.get_current_season()
	var squad := Squad.new(_pending_squad_armies.duplicate())

	var result: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season.season_id, _new_expedition_territory.id, squad, GameClock.now_unix(),
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	if not result["success"]:
		_nova_expedicao_status_label.text = "Não foi possível iniciar: %s" % result["reason"]
		return

	_pending_squad_armies.clear()

	var expedition: ExpeditionRuntime = result["expedition"]
	_active_expedition = expedition
	_map_segment_start_fase = 1
	_last_history_log_size[expedition] = expedition.history_log.size()
	_screen_state = ScreenState.TRILHA_MAP
	_start_tick_timer()
	refresh()


func _on_back_to_command_center_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/world_map_gate/world_map_gate_panel.tscn")
