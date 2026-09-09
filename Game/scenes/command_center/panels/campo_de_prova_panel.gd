class_name CampoDeProvaPanel
extends Control
## CampoDeProvaPanel (CAMPO_DE_PROVA.md)
##
## Reestruturação (2026-09-01): a versão original desta tela só cobria
## "Confronto entre Exércitos" (CAMPO_DE_PROVA.md, seção homônima) —
## literalmente "o jogador seleciona DOIS Exércitos válidos PRÓPRIOS".
## Isso foi substituído por dois modos (decisão explícita do dono do
## projeto — CAMPO_DE_PROVA.md ainda não descreve "Modo Real"/"Modo
## Simulado", reportado como documentação pendente, não reescrita aqui
## em silêncio):
##
## MODO REAL: um lado é obrigatoriamente um Army REAL do jogador
## (kingdom.armies); o outro é um Army DE TESTE, nunca precisa pertencer
## ao jogador. Os DOIS lados são editáveis (Army Editor em modo sandbox)
## — editar o lado do jogador aqui NUNCA altera o Army salvo real (ver
## _edited_player_army).
## MODO SIMULADO: os dois lados são Army DE TESTE, editáveis livremente,
## nenhum precisa pertencer ao jogador.
##
## "Exército válido" = Army.is_ready_for_battle() (ARMY.md) nos dois
## lados — nunca "pertencer ao jogador". Pertencimento só é exigido para
## o lado "Seu Exército" no Modo Real (a IDENTIDADE do Army de origem,
## não a composição temporária editada para o teste).
##
## Edição (Army Editor, engine/army/army_editor_panel.gd, sandbox_mode):
## reaproveita INTEGRALMENTE o Editor de Exército existente (seleção de
## Comandante, grade de Cartas, filtros, formação 3x3, drag-and-drop,
## validação de Soldo/Suporte/Máquina de Guerra) — nenhuma segunda
## implementação de montagem. sandbox_mode faz "Montar/Salvar" construir
## um Army solto em vez de chamar Kingdom.form_army()/re_form_army(), e
## "Cancelar" nunca chamar Kingdom.disband_army() — nada é registrado ou
## alterado em Kingdom.armies/cards/commanders/ownership em NENHUM
## momento desta tela.
##
## Army de teste "do zero" (botão "Formação Aleatória"): TestArmyFactory
## (Comandante procedural + catálogo completo). Army de teste do lado do
## jogador ("Formação Aleatória" na coluna "Seu Exército"): mesma
## heurística (ArmyRandomComposer + ArmyFormationArchetypes), mas restrita
## às Cartas do PRÓPRIO Reino (kingdom.cards, duplicadas) com o Comandante
## real selecionado — nunca conteúdo que o jogador não possui nesse lado
## específico.
##
## Motor de combate: inalterado — CombatEngine.initialize()+run() com
## CombatReplayCollector anexado ANTES de run(), mesmo padrão de
## phase_resolver.gd (PvE); "game_mode" = "pve" (nenhum modo
## "campo_de_prova" existe no motor). Nenhuma regra de combate foi
## tocada nesta etapa.
##
## Correção de ciclo de vida (2026-09-01): _run_prova() causava "Object
## is locked and can't be freed" porque _clear_children() (chamado por
## refresh() logo após a Prova terminar) tentava free() a própria
## CombatReplayView ainda "locked" — o await de replay_finished retoma
## de forma SÍNCRONA dentro da própria emissão do sinal (Button
## "Continuar" -> _on_continue_pressed -> replay_finished.emit()), então
## qualquer free() imediato ali colide com esse emissor ainda em
## andamento. Corrigido com o MESMO padrão já usado (e comprovado) por
## exercitos_panel.gd::_finish_army_creation() para fechar o overlay do
## Army Editor pelo mesmo motivo: remove_child() + queue_free() +
## reconstrução da UI, tudo dentro de um call_deferred() — nunca
## síncrono na pilha de chamada do sinal que disparou o fechamento. Ver
## _finish_prova_view()/_finish_army_editor().

const ARMY_EDITOR_SCENE_PATH: String = "res://scenes/army/army_editor_panel.tscn"
const COMBAT_REPLAY_VIEW_SCENE_PATH: String = "res://scenes/combat/combat_replay_view.tscn"

const FRAME_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/command_center_window_frame.png")
const FRAME_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const TITLE_RECT: Rect2 = Rect2(0.27, 0.14, 0.46, 0.06)
const CLOSE_BUTTON_RECT: Rect2 = Rect2(0.85, 0.12, 0.08, 0.12)
const INTERIOR_RECT: Rect2 = Rect2(0.075, 0.242, 0.85, 0.586)

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.95, 0.95, 0.93)
## Aumentado de (0.62,0.62,0.60) — pedido explícito de mais contraste
## pro texto "muted" (informações de estado/descrições auxiliares),
## sem deixar de ser visualmente subordinado a HUD_TEXT_COLOR/HUD_ACCENT.
const HUD_MUTED_COLOR: Color = Color(0.74, 0.74, 0.72)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 3
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.78, 0.68, 0.48)
const HUD_ACCENT_SELECTED: Color = Color(0.97, 0.83, 0.38)

## Hierarquia tipográfica explícita (pedido: "não aumentar tudo
## indiscriminadamente" — prioridade Títulos > nomes de Exército >
## Comandante > Cartas > estado > descrições auxiliares).
const FONT_SIZE_TITLE: int = 22
const FONT_SIZE_SECTION: int = 16      # "SEU EXÉRCITO", "MODO REAL", "Campo de Batalha"
const FONT_SIZE_COMMANDER: int = 15
const FONT_SIZE_CARD: int = 13
const FONT_SIZE_STATE: int = 13        # mensagens de validade/estado ("Formação incompleta...")
const FONT_SIZE_AUX: int = 12          # descrições auxiliares (isenção de Energia, nota de Insights)

var _view_mode: String = "config"  # "config" | "relatorio"
var _mode: String = "real"  # "real" | "simulado" — CAMPO_DE_PROVA.md, "Modo Real"/"Modo Simulado"

## Modo Real: índice do Army PRÓPRIO (kingdom.armies) escolhido como
## IDENTIDADE do lado "Seu Exército" — persistido aqui porque
## _army_a_option é reconstruído do zero a cada refresh().
var _selected_player_army_index: int = 0

## Composição TEMPORÁRIA do lado do jogador, editada para este teste
## (Army Editor em sandbox_mode) — nunca o Army real, nunca escrito de
## volta nele. null até o jogador abrir "Editar Formação" ou "Formação
## Aleatória" nesse lado; enquanto null, o Army real selecionado
## (kingdom.armies[_selected_player_army_index]) é usado como está.
var _edited_player_army: Army = null

var _army_a_option: OptionButton
var _battlefield_option: OptionButton
var _iniciar_button: Button

## Army de teste de cada lado — nunca pertence ao Reino, nunca é
## persistido; null até "Formação Aleatória"/"Editar Exército" ser usado.
## Modo Real usa só _test_army_b (lado "Exército de Teste"); Modo
## Simulado usa os dois.
var _test_army_a: Army = null
var _test_army_b: Army = null

## Overlay ativo do Army Editor (sandbox_mode), se houver — só um por
## vez (mesmo padrão de exercitos_panel.gd::_editor_overlay).
var _editor_overlay: Control = null
var _editor_target: String = ""  # "player" | "a" | "b"

var _last_army_a: Army = null
var _last_army_b: Army = null
var _last_battlefield: BattlefieldResource = null
var _last_seed: int = 0
var _last_state: CombatState = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	_maybe_show_tutorial_hint()
	print("[CampoDeProvaPanel] Pronto.")


## F-021.5 (dica contextual, independente da sequência linear TUT-001):
## primeira vez que o jogador abre o Campo de Prova. Mesmo padrão de
## exercitos_panel.gd/pve_panel.gd (progress_flag própria, banner
## dispensável, nunca reaberto).
func _maybe_show_tutorial_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_hint_campo_de_prova_visto"):
		return

	var hint = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	hint.setup(
		"Campo de Prova",
		"Teste seu Exército contra outra composição num combate real, sem gastar Energia nem afetar seu Reino. Escolha o Modo Real (seu Exército de verdade) ou Simulado (dois Exércitos de teste) e veja o resultado.",
		"Dica"
	)
	hint.continue_pressed.connect(_on_tutorial_hint_continue.bind(hint), CONNECT_DEFERRED)
	add_child(hint)


func _on_tutorial_hint_continue(hint: Control) -> void:
	KingdomState.kingdom.set_progress_flag("tutorial_hint_campo_de_prova_visto")
	hint.queue_free()


func refresh() -> void:
	_clear_children(self)
	_build_static_structure()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

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

	_build_title(texture_rect, "CAMPO DE PROVA")
	_build_close_button(texture_rect)

	if _view_mode == "config":
		_build_config_interior(texture_rect)
	else:
		_build_relatorio_interior(texture_rect)


func _build_title(parent: Control, text: String) -> void:
	var area := _anchor_new_control(parent, TITLE_RECT)
	var label := _make_centered_label(text, FONT_SIZE_TITLE, HUD_ACCENT)
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
		get_tree().change_scene_to_file.call_deferred("res://scenes/command_center/command_center_panel.tscn")


## --- Configuração: Modo Real / Modo Simulado (CAMPO_DE_PROVA.md). ---
func _build_config_interior(parent: Control) -> void:
	var area := _anchor_new_control(parent, INTERIOR_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	area.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root_vbox)

	_build_mode_toggle(root_vbox)
	root_vbox.add_child(_make_separator())

	var kingdom: Kingdom = KingdomState.kingdom

	if _mode == "real" and kingdom.armies.is_empty():
		root_vbox.add_child(_make_centered_label(
			"Você precisa de pelo menos 1 Exército formado (o seu) para usar o Modo Real do Campo de Prova.\nUse o Modo Simulado para testar sem nenhum Exército próprio.",
			FONT_SIZE_STATE, HUD_MUTED_COLOR
		))
		return

	_selected_player_army_index = clampi(_selected_player_army_index, 0, maxi(kingdom.armies.size() - 1, 0))

	var armies_row := HBoxContainer.new()
	armies_row.add_theme_constant_override("separation", 30)
	armies_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.add_child(armies_row)

	if _mode == "real":
		_build_player_army_column(armies_row, kingdom)
	else:
		_build_test_army_column(armies_row, "EXÉRCITO A", "a")

	armies_row.add_child(_make_centered_label("vs", FONT_SIZE_SECTION, HUD_MUTED_COLOR))

	_build_test_army_column(armies_row, "EXÉRCITO DE TESTE" if _mode == "real" else "EXÉRCITO B", "b")

	root_vbox.add_child(_make_centered_label("Campo de Batalha", FONT_SIZE_SECTION, HUD_TEXT_COLOR))
	var battlefield_names: Array[String] = []
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		battlefield_names.append(battlefield.battlefield_name)
	_battlefield_option = _make_option_button(battlefield_names)
	_battlefield_option.selected = 0
	_battlefield_option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.add_child(_battlefield_option)

	root_vbox.add_child(_make_separator())

	root_vbox.add_child(_make_centered_label(
		"Sem consumo de Energia. Sem recompensas. Sem alteração permanente.",
		FONT_SIZE_AUX, HUD_MUTED_COLOR
	))

	_iniciar_button = Button.new()
	_iniciar_button.text = "Iniciar Prova"
	_iniciar_button.custom_minimum_size = Vector2(230, 42)
	_iniciar_button.add_theme_font_size_override("font_size", FONT_SIZE_SECTION)
	_iniciar_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_office_button(_iniciar_button)
	_iniciar_button.disabled = not _configuration_is_valid(kingdom)
	_iniciar_button.pressed.connect(_on_iniciar_prova_pressed, CONNECT_DEFERRED)
	root_vbox.add_child(_iniciar_button)


func _build_mode_toggle(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(row)

	var real_button := Button.new()
	real_button.text = "MODO REAL"
	real_button.custom_minimum_size = Vector2(160, 36)
	real_button.add_theme_font_size_override("font_size", FONT_SIZE_SECTION)
	_style_office_button(real_button)
	if _mode == "real":
		real_button.add_theme_color_override("font_color", HUD_ACCENT_SELECTED)
	real_button.pressed.connect(_on_mode_selected.bind("real"), CONNECT_DEFERRED)
	row.add_child(real_button)

	var sim_button := Button.new()
	sim_button.text = "MODO SIMULADO"
	sim_button.custom_minimum_size = Vector2(160, 36)
	sim_button.add_theme_font_size_override("font_size", FONT_SIZE_SECTION)
	_style_office_button(sim_button)
	if _mode == "simulado":
		sim_button.add_theme_color_override("font_color", HUD_ACCENT_SELECTED)
	sim_button.pressed.connect(_on_mode_selected.bind("simulado"), CONNECT_DEFERRED)
	row.add_child(sim_button)


## Trocar de modo descarta qualquer composição temporária já preparada
## em qualquer lado — evita carregar, por engano, uma composição de um
## Modo pro outro sem o jogador perceber.
func _on_mode_selected(mode: String) -> void:
	if _mode == mode:
		return
	_mode = mode
	_edited_player_army = null
	_test_army_a = null
	_test_army_b = null
	refresh()


## Modo Real, lado "Seu Exército" — a IDENTIDADE é obrigatoriamente um
## Army PRÓPRIO (kingdom.armies); a COMPOSIÇÃO usada na prova pode ser
## editada livremente (_edited_player_army), sem nunca escrever de volta
## no Army real.
func _build_player_army_column(parent: Control, kingdom: Kingdom) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(260, 0)
	parent.add_child(column)
	column.add_child(_make_centered_label("SEU EXÉRCITO", FONT_SIZE_SECTION, HUD_TEXT_COLOR))

	var army_names: Array[String] = []
	for army: Army in kingdom.armies:
		var commander_name: String = army.commander.commander_name if army.commander != null else "(sem Comandante)"
		army_names.append(commander_name)
	_army_a_option = _make_option_button(army_names)
	_army_a_option.selected = _selected_player_army_index
	# CONNECT_DEFERRED: o handler chama refresh(), que _clear_children()/
	# free() este próprio OptionButton — liberá-lo ainda dentro da sua
	# própria emissão de item_selected quebraria o sinal em andamento
	# (mesma causa-raiz corrigida em _run_prova(), ver docstring do topo).
	_army_a_option.item_selected.connect(_on_player_army_selected, CONNECT_DEFERRED)
	column.add_child(_army_a_option)

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 8)
	buttons_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(buttons_row)

	var edit_button := Button.new()
	edit_button.text = "Editar Formação"
	edit_button.custom_minimum_size = Vector2(150, 34)
	_style_office_button(edit_button)
	edit_button.pressed.connect(_open_army_editor.bind("player"), CONNECT_DEFERRED)
	buttons_row.add_child(edit_button)

	var random_button := Button.new()
	random_button.text = "Formação Aleatória"
	random_button.custom_minimum_size = Vector2(150, 34)
	_style_office_button(random_button)
	random_button.pressed.connect(_on_player_formacao_aleatoria_pressed, CONNECT_DEFERRED)
	buttons_row.add_child(random_button)

	if _edited_player_army != null:
		var reset_button := Button.new()
		reset_button.text = "Restaurar Original"
		reset_button.custom_minimum_size = Vector2(150, 34)
		_style_office_button(reset_button)
		reset_button.pressed.connect(_on_player_army_reset_pressed, CONNECT_DEFERRED)
		column.add_child(reset_button)

	column.add_child(_build_formation_preview(_effective_player_army(kingdom)))


func _on_player_army_selected(index: int) -> void:
	_selected_player_army_index = index
	_edited_player_army = null  # nova identidade de origem — descarta qualquer edição do Army anterior
	refresh()


func _on_player_army_reset_pressed() -> void:
	_edited_player_army = null
	refresh()


## Reaproveita ArmyRandomComposer/ArmyFormationArchetypes (mesma
## heurística de TestArmyFactory), mas restrita às Cartas do PRÓPRIO
## Reino (kingdom.cards) e ao Comandante real já selecionado — o lado do
## jogador nunca ganha conteúdo que ele não possui por esta via
## ("dentro das regras permitidas pelo Campo de Prova").
func _on_player_formacao_aleatoria_pressed() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var real_army: Army = kingdom.armies[_selected_player_army_index]
	if real_army.commander == null:
		return

	var commander_copy: CommanderResource = real_army.commander.duplicate()
	var soldo_cap: int = Soldo.cap_for_patente(CommanderCareer.patente_for_xp(commander_copy.accumulated_xp))

	var pool: Array[CardResource] = []
	for card: CardResource in kingdom.cards:
		pool.append(card.duplicate())
	var composition: Array[CardResource] = ArmyRandomComposer.random_valid_composition(pool, soldo_cap)

	var army := Army.new()
	army.commander = commander_copy
	army.army_name = real_army.army_name
	if not composition.is_empty():
		var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(composition)
		army.cards = archetypes.get("δ", composition)

	_edited_player_army = army
	refresh()


## O Army realmente usado nesta sessão do Campo de Prova pro lado do
## jogador: a edição temporária, se houver, senão o Army real como está.
func _effective_player_army(kingdom: Kingdom) -> Army:
	if _edited_player_army != null:
		return _edited_player_army
	return kingdom.armies[_selected_player_army_index]


## Modo Real (lado B) e Modo Simulado (os dois lados) — Army DE TESTE,
## nunca precisa pertencer ao jogador. "slot" é "a" ou "b".
func _build_test_army_column(parent: Control, title: String, slot: String) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.custom_minimum_size = Vector2(260, 0)
	parent.add_child(column)
	column.add_child(_make_centered_label(title, FONT_SIZE_SECTION, HUD_TEXT_COLOR))

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 8)
	buttons_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(buttons_row)

	var edit_button := Button.new()
	edit_button.text = "Editar Exército"
	edit_button.custom_minimum_size = Vector2(150, 34)
	_style_office_button(edit_button)
	edit_button.pressed.connect(_open_army_editor.bind(slot), CONNECT_DEFERRED)
	buttons_row.add_child(edit_button)

	var random_button := Button.new()
	random_button.text = "Formação Aleatória"
	random_button.custom_minimum_size = Vector2(150, 34)
	_style_office_button(random_button)
	random_button.pressed.connect(_on_formacao_aleatoria_pressed.bind(slot), CONNECT_DEFERRED)
	buttons_row.add_child(random_button)

	var test_army: Army = _test_army_a if slot == "a" else _test_army_b
	if test_army == null:
		column.add_child(_make_centered_label("Nenhuma composição gerada ainda.", FONT_SIZE_STATE, HUD_MUTED_COLOR))
	else:
		column.add_child(_build_formation_preview(test_army))


## TestArmyFactory reaproveita ArmyRandomComposer (extraída de
## army_editor_panel.gd) e ArmyFormationArchetypes — nenhuma heurística
## nova (ver engine/army/test_army_factory.gd).
func _on_formacao_aleatoria_pressed(slot: String) -> void:
	var army: Army = TestArmyFactory.generate_random_army()
	if slot == "a":
		_test_army_a = army
	else:
		_test_army_b = army
	refresh()


## --- Army Editor em sandbox_mode — reaproveita a montagem/edição real,
## nunca uma segunda implementação (ver army_editor_panel.gd,
## sandbox_mode/sandbox_card_pool/sandbox_commander_pool). ---

## "target": "player" (Modo Real, lado do jogador — restrito às Cartas/
## Comandante do próprio Reino) | "a" | "b" (Army de teste — catálogo
## completo). Só um overlay por vez.
func _open_army_editor(target: String) -> void:
	if _editor_overlay != null:
		return

	var editor = load(ARMY_EDITOR_SCENE_PATH).instantiate()
	editor.sandbox_mode = true
	editor.formation_count = 1

	if target == "player":
		var kingdom: Kingdom = KingdomState.kingdom
		var source: Army = _effective_player_army(kingdom)

		var commander_copy: CommanderResource = source.commander.duplicate() if source.commander != null else null
		var card_copies: Array[CardResource] = []
		for card: CardResource in source.cards:
			card_copies.append(card.duplicate())

		var temp_army := Army.new()
		temp_army.commander = commander_copy
		temp_army.cards = card_copies
		temp_army.army_name = source.army_name

		# Pool de sandbox restrito ao próprio Reino — inclui os mesmos
		# objetos (commander_copy/card_copies) já usados em temp_army,
		# pra _card_is_owned_elsewhere()/_eligible_commanders_filtered...()
		# do Editor reconhecerem por identidade "isto já está
		# selecionado", exatamente como reconheceriam um Army real sendo
		# editado — nenhuma checagem nova, mesmo predicado de sempre.
		#
		# Exclusão dos demais Comandantes/Cartas do Reino por NOME (não
		# por identidade de objeto): "source" pode já ser
		# _edited_player_army de uma edição anterior — nesse caso seus
		# Comandante/Cartas já são cópias, nunca == aos objetos reais de
		# kingdom.commanders/kingdom.cards, e uma exclusão por identidade
		# deixaria cada um deles listado duas vezes (a cópia selecionada
		# + o original do Reino, tratado como "ainda disponível").
		var sandbox_commanders: Array[CommanderResource] = []
		if commander_copy != null:
			sandbox_commanders.append(commander_copy)
		for other: CommanderResource in kingdom.commanders:
			if commander_copy == null or other.commander_name != commander_copy.commander_name:
				sandbox_commanders.append(other.duplicate())

		var source_card_names: Array[String] = []
		for card: CardResource in source.cards:
			source_card_names.append(card.card_name)

		var sandbox_cards: Array[CardResource] = card_copies.duplicate()
		for card: CardResource in kingdom.cards:
			if not source_card_names.has(card.card_name):
				sandbox_cards.append(card.duplicate())

		editor.existing_army = temp_army
		editor.editing_composition = true
		editor.sandbox_commander_pool = sandbox_commanders
		editor.sandbox_card_pool = sandbox_cards
	else:
		var existing_test_army: Army = _test_army_a if target == "a" else _test_army_b
		if existing_test_army != null:
			editor.existing_army = existing_test_army
			editor.editing_composition = true
		# sandbox_card_pool/sandbox_commander_pool ficam [] -> catálogo
		# completo do jogo (mesmo padrão de TestArmyFactory).

	_editor_target = target
	editor.army_ready.connect(_on_army_editor_ready)
	editor.cancelled.connect(_on_army_editor_cancelled)
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(editor)
	_editor_overlay = editor


func _on_army_editor_ready(army: Army) -> void:
	if _editor_target == "player":
		_edited_player_army = army
	elif _editor_target == "a":
		_test_army_a = army
	else:
		_test_army_b = army
	call_deferred("_finish_army_editor")


func _on_army_editor_cancelled() -> void:
	call_deferred("_finish_army_editor")


## Mesmo padrão comprovado de exercitos_panel.gd::_finish_army_creation()
## — remove_child()+queue_free() do overlay, tudo dentro do
## call_deferred() já agendado pelos handlers acima, nunca síncrono
## dentro da emissão de army_ready/cancelled do próprio overlay.
func _finish_army_editor() -> void:
	if _editor_overlay != null:
		remove_child(_editor_overlay)
		_editor_overlay.queue_free()
		_editor_overlay = null
	_editor_target = ""
	refresh()


## Lista simples de Comandante + 9 Cartas — sem BattleCardView/arte nova
## nesta etapa. Sinaliza claramente uma composição incompleta/acima do
## teto de Soldo em vez de exibir uma prévia parcial enganosa.
func _build_formation_preview(army: Army) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size = Vector2(260, 0)
	var commander_text: String = army.commander.commander_name if army.commander != null else "(sem Comandante)"
	box.add_child(_make_centered_label(commander_text, FONT_SIZE_COMMANDER, HUD_ACCENT))
	if not army.is_ready_for_battle():
		box.add_child(_make_centered_label("Formação incompleta ou acima do teto de Soldo.", FONT_SIZE_STATE, HUD_MUTED_COLOR))
		return box
	for card: CardResource in army.cards:
		box.add_child(_make_centered_label("%s (T%d)" % [card.card_name, card.tier], FONT_SIZE_CARD, HUD_TEXT_COLOR))
	return box


## "Exército válido" = Army.is_ready_for_battle() (ARMY.md) nos dois
## lados — nunca "pertencer ao jogador". Pertencimento só é exigido para
## a IDENTIDADE do lado "Seu Exército" no Modo Real (kingdom.armies já
## garante isso por construção); a composição efetivamente usada
## (_effective_player_army()) pode ser a editada temporariamente.
func _configuration_is_valid(kingdom: Kingdom) -> bool:
	if _mode == "real":
		if kingdom.armies.is_empty():
			return false
		var player_army: Army = _effective_player_army(kingdom)
		return player_army.is_ready_for_battle() and _test_army_b != null and _test_army_b.is_ready_for_battle()
	return _test_army_a != null and _test_army_a.is_ready_for_battle() and _test_army_b != null and _test_army_b.is_ready_for_battle()


func _on_iniciar_prova_pressed() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if not _configuration_is_valid(kingdom):
		return

	if _mode == "real":
		_last_army_a = _effective_player_army(kingdom)
		_last_army_b = _test_army_b
	else:
		_last_army_a = _test_army_a
		_last_army_b = _test_army_b

	_last_battlefield = GameDatabase.battlefields[_battlefield_option.selected]
	_last_seed = randi()

	await _run_prova(_last_seed)


func _on_repetir_prova_pressed() -> void:
	await _run_prova(_last_seed)


## Roda a prova com a MESMA seed sempre que "seed_value" é reaproveitado
## por "Repetir esta Prova" (CAMPO_DE_PROVA.md, "Reprodutibilidade") —
## mesmos 2 Exércitos, mesmo Campo de Batalha, mesma Semente.
func _run_prova(seed_value: int) -> void:
	# battlefields como Array de 1 elemento força Battlefield.draw() a
	# sempre escolher exatamente o Campo selecionado pelo jogador — o
	# Campo de Prova reutiliza os Campos oficiais, nunca cria um
	# exclusivo (CAMPO_DE_PROVA.md).
	var battlefields: Array[BattlefieldResource] = [_last_battlefield]

	var state: CombatState = CombatEngine.initialize(
		_last_army_a, _last_army_b, battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value
	)
	var replay_collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	replay_collector.attach(state.event_bus)
	replay_collector.snapshot_initial_board(state)
	CombatEngine.run(state)
	_last_state = state

	var view = load(COMBAT_REPLAY_VIEW_SCENE_PATH).instantiate()
	view.combat_state = state
	view.replay_collector = replay_collector
	view.player_side = 0
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	await view.replay_finished
	call_deferred("_finish_prova_view", view)


## "Object is locked and can't be freed" (ver docstring do topo): o
## await acima retoma DENTRO da própria emissão de replay_finished
## (Button "Continuar" -> _on_continue_pressed -> emit()) — free()/
## _clear_children() imediatos aqui colidiriam com "view" ainda em
## processamento ("locked"). Removido da árvore e liberado (deferred)
## só depois que a pilha de chamada do sinal já desenrolou por completo
## (call_deferred agendado em _run_prova(), nunca chamado direto).
func _finish_prova_view(view: Control) -> void:
	remove_child(view)
	view.queue_free()
	_view_mode = "relatorio"
	refresh()


## --- Relatório: resultado + Repetir (CAMPO_DE_PROVA.md, "Relatório da Prova"). ---
func _build_relatorio_interior(parent: Control) -> void:
	var area := _anchor_new_control(parent, INTERIOR_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	area.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(root_vbox)

	if _last_state == null:
		root_vbox.add_child(_make_centered_label("Nenhuma Prova executada ainda.", FONT_SIZE_STATE, HUD_MUTED_COLOR))
		return

	var result_text: String
	if _last_state.winner_side == 0:
		result_text = "Vitória de %s" % (_last_army_a.commander.commander_name if _last_army_a.commander != null else "Exército A")
	elif _last_state.winner_side == 1:
		result_text = "Vitória de %s" % (_last_army_b.commander.commander_name if _last_army_b.commander != null else "Exército B")
	else:
		result_text = "Empate"

	root_vbox.add_child(_make_centered_label(result_text, FONT_SIZE_TITLE, HUD_ACCENT_SELECTED))
	root_vbox.add_child(_make_centered_label("Turnos: %d | Campo de Batalha: %s" % [_last_state.turn, _last_battlefield.battlefield_name], FONT_SIZE_COMMANDER, HUD_TEXT_COLOR))
	root_vbox.add_child(_make_centered_label(
		"%s vs %s" % [
			_last_army_a.commander.commander_name if _last_army_a.commander != null else "Exército A",
			_last_army_b.commander.commander_name if _last_army_b.commander != null else "Exército B",
		], FONT_SIZE_STATE, HUD_MUTED_COLOR
	))

	# Auditoria FASE 22.1, achado H: CombatState já expõe sobreviventes e
	# baixas por nome ao final de run() (units_of_side()/eliminated_units)
	# — nenhuma mudança em CombatEngine/CombatState foi necessária, só
	# ler o que já existe.
	var survivors_a: int = _last_state.units_of_side(0, true).size()
	var survivors_b: int = _last_state.units_of_side(1, true).size()
	root_vbox.add_child(_make_centered_label(
		"Seus sobreviventes: %d/9 | Sobreviventes do oponente: %d/9" % [survivors_a, survivors_b],
		FONT_SIZE_AUX, HUD_TEXT_COLOR
	))

	var lost_names: Array[String] = []
	for unit: CombatUnit in _last_state.eliminated_units:
		if unit.side == 0 and unit.card != null:
			lost_names.append(unit.card.card_name)
	if not lost_names.is_empty():
		root_vbox.add_child(_make_centered_label(
			"Pelotões seus perdidos: %s" % ", ".join(lost_names),
			FONT_SIZE_AUX, HUD_TEXT_COLOR
		))

	root_vbox.add_child(_make_centered_label(
		"Sessão isolada — nenhum dado dos Exércitos reais foi alterado. Insights táticos ainda não implementados (Log Estruturado pendente, ver CAMPO_DE_PROVA.md).",
		FONT_SIZE_AUX, HUD_MUTED_COLOR
	))

	root_vbox.add_child(_make_separator())

	var actions_row := HBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 16)
	actions_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root_vbox.add_child(actions_row)

	var repetir_button := Button.new()
	repetir_button.text = "Repetir esta Prova"
	repetir_button.custom_minimum_size = Vector2(190, 38)
	_style_office_button(repetir_button)
	repetir_button.pressed.connect(_on_repetir_prova_pressed, CONNECT_DEFERRED)
	actions_row.add_child(repetir_button)

	var nova_config_button := Button.new()
	nova_config_button.text = "Nova Configuração"
	nova_config_button.custom_minimum_size = Vector2(190, 38)
	_style_office_button(nova_config_button)
	nova_config_button.pressed.connect(_on_nova_configuracao_pressed, CONNECT_DEFERRED)
	actions_row.add_child(nova_config_button)


func _on_nova_configuracao_pressed() -> void:
	_view_mode = "config"
	refresh()


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

## Ignora filhos já agendados para deleção (is_queued_for_deletion()) —
## rede de segurança contra qualquer futuro cenário de double-free/
## objeto ainda "locked" chegando aqui (pedido explícito: "impedir
## reentrada"/"callbacks duplicados"). O caso real já conhecido
## (CombatReplayView) é resolvido na origem por _finish_prova_view(),
## que já remove "view" da árvore antes de refresh() rodar — esta
## checagem nunca precisa disparar para esse caso específico, mas
## permanece como proteção geral da função.
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		if child.is_queued_for_deletion():
			continue
		container.remove_child(child)
		child.free()


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


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _make_option_button(values: Array[String]) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(260, 0)
	for value: String in values:
		option.add_item(value)
	option.add_theme_font_override("font", HUD_FONT)
	option.add_theme_font_size_override("font_size", FONT_SIZE_COMMANDER)
	option.add_theme_color_override("font_color", HUD_TEXT_COLOR)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		option.add_theme_stylebox_override(state, style)

	return option


func _style_office_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	button.add_theme_color_override("font_disabled_color", HUD_MUTED_COLOR)
	if not button.has_theme_font_size_override("font_size"):
		button.add_theme_font_size_override("font_size", FONT_SIZE_STATE)

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
