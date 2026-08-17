class_name ArmyEditorPanel
extends Control
## ArmyEditorPanel (COMMAND_CENTER_UI.md, "motor de geração de exército
## comum")
##
## Componente reutilizável: monta 1 Exército (Comandante + 9 Cartas) e,
## se "formation_count" > 1, edita as Formações extras (posicionamento
## das MESMAS 9 cartas, nunca cartas diferentes). Cada janela que
## precisa montar um Exército (PvE, PvP, Minas) instancia esta cena e
## configura "formation_count" antes de _ready() rodar — 5 para PvE
## (α a ε), 1 para PvP e Minas (só a posição base importa).
##
## Emite "army_ready" quando o Exército está pronto para uso — quem
## instanciou decide o que fazer com ele (adicionar a um Squad, usar
## como Guarnição de Mina etc.). Este Editor nunca decide isso sozinho.
##
## Layout de posição (COMBAT_RULES.md, "Campo de Batalha"):
## Linha 1 (Frente): [1] [2] [3]
## Linha 2 (Meio):   [6] [5] [4]
## Linha 3 (Fundo):  [7] [8] [9]

signal army_ready(army: Army)
signal cancelled

## ATENÇÃO AO CONECTAR "army_ready": lambdas do GDScript capturam
## variáveis locais POR VALOR, não por referência — um padrão como
## `editor.army_ready.connect(func(a): minha_variavel_local = a)`
## NUNCA atualiza "minha_variavel_local" de verdade (confirmado com
## execução real: a conexão existe, o emit() roda, mas a variável
## externa nunca muda). Quem for consumir este sinal deve conectar a
## um MÉTODO nomeado que faça "self.algo = a" (mutação de propriedade
## do próprio objeto funciona normalmente) — nunca uma lambda tentando
## escrever numa variável local externa.

## Configurar ANTES de _ready() rodar (ex: definir logo após
## instanciar a cena, antes de add_child na árvore). 1 = só a posição
## base (PvP, Minas). 5 = PvE (Formações α a ε).
var formation_count: int = 1

const POSITION_LAYOUT: Array[int] = [1, 2, 3, 6, 5, 4, 7, 8, 9]  # ordem visual, valor = nº da posição
const FORMATION_NAMES: Array[String] = ["α", "β", "γ", "δ", "ε"]

var _root_vbox: VBoxContainer
var _commander_option: OptionButton
var _cards_container: VBoxContainer
var _soldo_label: Label
var _montar_button: Button
var _formations_section: VBoxContainer
var _slots_grid: GridContainer
var _formation_tabs_row: HBoxContainer
var _concluir_button: Button

var _eligible_commanders: Array[CommanderResource] = []
var _selected_commander: CommanderResource = null
var _selected_cards: Array[CardResource] = []  # ordem de escolha = posição base 1..9

var _army: Army = null
var _formation_cards: Dictionary = {}  # nome ("α".."ε") -> Array[CardResource] (9 posições)
var _current_formation: String = "α"


## Definido ANTES de add_child() por quem chama, quando o objetivo é
## editar as Formações de um Exército JÁ EXISTENTE (não criar um
## novo). Quando setado, _ready() pula a Fase 1 inteira (Comandante +
## 9 Cartas já estão definidos) e vai direto pras Formações.
var existing_army: Army = null

## Definido junto com "existing_army", ANTES de add_child(), quando o
## objetivo é editar a COMPOSIÇÃO (Comandante e/ou Cartas) de um
## Exército já existente — não só as Formações. Mostra a Fase 1
## (Comandante + 9 Cartas) pré-preenchida com a composição atual.
var editing_composition: bool = false


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	if existing_army != null and editing_composition:
		_selected_commander = existing_army.commander
		_selected_cards = existing_army.cards.duplicate()
		_refresh_choice_phase()
	elif existing_army != null:
		_start_formation_edit_mode()
	else:
		_refresh_choice_phase()


## ARMY.md: todo Exército já existente já tem as 5 Formações (α já é
## army.cards; β-ε já foram geradas por Kingdom.form_army() na
## criação, ou já foram editadas manualmente antes). Aqui só carrega
## esse estado já existente pra edição — nunca gera nada novo.
func _start_formation_edit_mode() -> void:
	_army = existing_army
	_selected_commander = existing_army.commander
	_selected_cards = existing_army.cards.duplicate()
	formation_count = 5  # sempre permite editar as 5, mesmo que o Exército tenha nascido de um fluxo de 1 Formação só

	_commander_option.visible = false
	_cards_container.visible = false
	_soldo_label.visible = false
	_montar_button.visible = false

	_formation_cards["α"] = existing_army.cards.duplicate()
	for i in range(1, formation_count):
		var name: String = FORMATION_NAMES[i]
		_formation_cards[name] = existing_army.formations[name].duplicate() if existing_army.formations.has(name) else existing_army.cards.duplicate()

	_formations_section.visible = true
	_concluir_button.visible = true
	_current_formation = "α"
	_build_formation_tabs()
	_build_slots_grid()


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
	title.text = "Editor de Exército"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var cancel_button := Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(_on_cancel_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(cancel_button)

	# --- Fase 1: Comandante + 9 Cartas ---
	var commander_row := HBoxContainer.new()
	_root_vbox.add_child(commander_row)
	var commander_label := Label.new()
	commander_label.text = "Comandante:"
	commander_row.add_child(commander_label)
	_commander_option = OptionButton.new()
	_commander_option.item_selected.connect(_on_commander_selected, CONNECT_DEFERRED)
	commander_row.add_child(_commander_option)

	var cards_title := Label.new()
	cards_title.text = "Escolha exatamente 9 Cartas:"
	_root_vbox.add_child(cards_title)
	_cards_container = VBoxContainer.new()
	_root_vbox.add_child(_cards_container)

	_soldo_label = Label.new()
	_root_vbox.add_child(_soldo_label)

	_montar_button = Button.new()
	_montar_button.text = "Montar Exército"
	_montar_button.pressed.connect(_on_montar_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(_montar_button)

	# --- Fase 2: Posicionamento (SEMPRE mostrado, mesmo com 1 só
	# Formação — Posicionamento é o fator mais importante do jogo,
	# COMBAT_RULES.md/SOLDO.md: "Posicionamento > Classe > Facção >
	# Carta > Habilidade". O jogador precisa ver e poder ajustar onde
	# cada carta cai, não só a ordem em que marcou os checkboxes.) ---
	_formations_section = VBoxContainer.new()
	_formations_section.visible = false
	_root_vbox.add_child(_formations_section)

	var formations_title := Label.new()
	formations_title.text = "Posicionar Cartas (arraste a força certa pra cada posição):"
	_formations_section.add_child(formations_title)

	_formation_tabs_row = HBoxContainer.new()
	_formations_section.add_child(_formation_tabs_row)

	_slots_grid = GridContainer.new()
	_slots_grid.columns = 3
	_formations_section.add_child(_slots_grid)

	_concluir_button = Button.new()
	_concluir_button.text = "Confirmar Exército"
	_concluir_button.pressed.connect(_on_concluir_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(_concluir_button)
	_concluir_button.visible = false


func _refresh_choice_phase() -> void:
	var kingdom: Kingdom = KingdomState.kingdom

	_eligible_commanders.clear()
	_commander_option.clear()
	for commander: CommanderResource in kingdom.commanders:
		var is_this_armys_own_commander: bool = editing_composition and existing_army != null and commander == existing_army.commander
		if commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE \
			and (commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE or is_this_armys_own_commander):
			_eligible_commanders.append(commander)
			_commander_option.add_item(commander.commander_name)
	if not _eligible_commanders.is_empty() and _selected_commander == null:
		_selected_commander = _eligible_commanders[0]
	if editing_composition and _selected_commander != null and _eligible_commanders.has(_selected_commander):
		_commander_option.selected = _eligible_commanders.find(_selected_commander)

	_clear_children(_cards_container)
	var selected_names: Array[String] = []
	for selected: CardResource in _selected_cards:
		selected_names.append(selected.card_name)
	for card: CardResource in kingdom.cards:
		var is_this_armys_own_card: bool = editing_composition and existing_army != null and existing_army.cards.has(card)
		if card.ownership_status != CardResource.OwnershipStatus.LIVRE and not is_this_armys_own_card:
			continue
		var check := CheckBox.new()
		check.text = "%s (%s, %s)" % [card.card_name, card.rarity, card.faction]
		check.button_pressed = _selected_cards.has(card)
		# ARMY.md, "Unicidade de Composição": desabilita qualquer outra
		# cópia do mesmo Nome já escolhida (nunca a própria, senão o
		# jogador não conseguiria desmarcar a que já marcou).
		check.disabled = not check.button_pressed and selected_names.has(card.card_name)
		check.toggled.connect(_on_card_toggled.bind(card), CONNECT_DEFERRED)
		_cards_container.add_child(check)

	_update_soldo_label()


func _update_soldo_label() -> void:
	var total: int = Soldo.total_for_composition(_selected_cards)
	if _selected_commander == null:
		_soldo_label.text = "Soldo: %d (escolha um Comandante para ver o teto)" % total
		_montar_button.disabled = true
		return

	var patente: String = CommanderCareer.patente_for_xp(_selected_commander.accumulated_xp)
	var cap: int = Soldo.cap_for_patente(patente)
	_soldo_label.text = "Soldo: %d / %d | Cartas escolhidas: %d / 9" % [total, cap, _selected_cards.size()]
	_montar_button.disabled = _selected_cards.size() != 9 or total > cap


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_commander_selected(index: int) -> void:
	_selected_commander = _eligible_commanders[index]
	_update_soldo_label()


## ARMY.md, "Unicidade de Composição": nunca duas Cartas com o mesmo
## Nome no Exército, independente do Tier — rejeita a marcação se já
## existir uma carta diferente com o mesmo Nome selecionada.
func _on_card_toggled(pressed: bool, card: CardResource) -> void:
	if pressed:
		var already_has_same_name: bool = false
		for selected: CardResource in _selected_cards:
			if selected != card and selected.card_name == card.card_name:
				already_has_same_name = true
		if not _selected_cards.has(card) and _selected_cards.size() < 9 and not already_has_same_name:
			_selected_cards.append(card)
	else:
		_selected_cards.erase(card)
	_update_soldo_label()
	_refresh_choice_phase()  # reconstrói pra atualizar quais cópias do mesmo Nome ficam desabilitadas agora


## Cancela o Editor a qualquer momento. Se já tinha passado da Fase 1
## (Exército já formado via form_army(), aguardando posicionamento),
## desfaz de verdade — libera o Comandante e as cartas de volta pro
## Reino, não deixa nada preso.
## Cancela o Editor a qualquer momento. Se já tinha passado da Fase 1
## de uma CRIAÇÃO NOVA (Exército já formado via form_army(), aguardando
## posicionamento), desfaz de verdade — libera o Comandante e as
## cartas de volta pro Reino, não deixa nada preso. Nunca desfaz
## quando o modo é EDIÇÃO de um Exército já existente (existing_army
## != null) — cancelar ali só descarta as edições de Formação não
## salvas, o Exército em si nunca é tocado.
func _on_cancel_pressed() -> void:
	if _army != null and existing_army == null:
		KingdomState.kingdom.disband_army(_army)
	cancelled.emit()


func _on_montar_pressed() -> void:
	if _selected_commander == null or _selected_cards.size() != 9:
		return

	if editing_composition and existing_army != null:
		KingdomState.kingdom.re_form_army(existing_army, _selected_commander, _selected_cards.duplicate())
		_army = existing_army
	else:
		_army = KingdomState.kingdom.form_army(_selected_commander, _selected_cards.duplicate())

	# "α" é sempre a posição base — existe e é editável mesmo com
	# formation_count=1 (antes disso, o Exército de 1 Formação nunca
	# passava pelo posicionamento nenhum, só a ordem de marcação dos
	# checkboxes; agora sempre passa).
	# ARMY.md, "Arquétipos de Formação": form_army() já populou
	# _army.formations com β-ε de verdade (Ofensiva/Defensiva/
	# Equilibrada/Dispersão) — nunca sobrescrever com cópias idênticas
	# de α aqui. "Nunca formações idênticas" é regra do documento.
	_formation_cards["α"] = _selected_cards.duplicate()
	for i in range(1, formation_count):
		var name: String = FORMATION_NAMES[i]
		_formation_cards[name] = _army.formations[name] if _army.formations.has(name) else _selected_cards.duplicate()

	_formations_section.visible = true
	_concluir_button.visible = true
	_current_formation = "α"
	_build_formation_tabs()
	_build_slots_grid()


func _build_formation_tabs() -> void:
	_clear_children(_formation_tabs_row)
	if formation_count <= 1:
		return  # só 1 Formação -> sem abas, só o grid da posição base ("α")
	for i in range(formation_count):
		var formation_name: String = FORMATION_NAMES[i]
		var button := Button.new()
		button.text = ("[%s]" % formation_name) if formation_name == _current_formation else formation_name
		button.disabled = formation_name == _current_formation  # indicador visual claro de qual está selecionada agora
		button.pressed.connect(_on_formation_tab_pressed.bind(formation_name), CONNECT_DEFERRED)
		_formation_tabs_row.add_child(button)


func _on_formation_tab_pressed(formation_name: String) -> void:
	_current_formation = formation_name
	_build_formation_tabs()
	_build_slots_grid()


func _build_slots_grid() -> void:
	_clear_children(_slots_grid)
	var current_cards: Array[CardResource] = _formation_cards[_current_formation]

	for visual_index in range(9):
		var position_number: int = POSITION_LAYOUT[visual_index]
		var slot_index: int = position_number - 1

		var slot_box := VBoxContainer.new()
		_slots_grid.add_child(slot_box)

		var position_label := Label.new()
		var line_number: int = 1 if position_number <= 3 else (2 if position_number <= 6 else 3)
		position_label.text = "Posição %d (Linha %d)" % [position_number, line_number]
		slot_box.add_child(position_label)

		var option := OptionButton.new()
		for i in range(current_cards.size()):
			option.add_item(current_cards[i].card_name, i)
		option.selected = slot_index
		option.item_selected.connect(_on_slot_card_selected.bind(slot_index), CONNECT_DEFERRED)
		slot_box.add_child(option)


## Troca (swap) o conteúdo de "slot_index" com quem estiver atualmente
## na posição escolhida — nunca deixa a Formação num estado inválido
## (sempre uma permutação completa das mesmas 9 cartas).
func _on_slot_card_selected(new_card_index: int, slot_index: int) -> void:
	var current_cards: Array[CardResource] = _formation_cards[_current_formation]
	var temp: CardResource = current_cards[slot_index]
	current_cards[slot_index] = current_cards[new_card_index]
	current_cards[new_card_index] = temp
	_build_slots_grid()


## Aplica a posição base (possivelmente rearranjada pelo jogador no
## grid 3x3) de volta no Exército — antes desta correção, um Exército
## de 1 Formação só nunca mostrava nem deixava ajustar a posição das
## cartas, usando sempre a ordem de marcação dos checkboxes.
func _on_concluir_pressed() -> void:
	_army.cards = _formation_cards["α"]
	for formation_name: String in _formation_cards:
		if formation_name == "α":
			continue
		_army.formations[formation_name] = _formation_cards[formation_name]
	army_ready.emit(_army)
