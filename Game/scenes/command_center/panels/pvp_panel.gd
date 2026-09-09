extends Control
## PvPPanel (COMMAND_CENTER_UI.md, "Janela: PvP")
##
## Bronze (informativo — quaisquer Exércitos Ativos, sem registro
## formal) e configuração do Plano de Campanha (mapeamento dos 9
## Campos Especiais, Defesa Preferencial, Ordem de Ataque). Mesmo
## padrão das demais janelas: árvore em código, sem estado próprio,
## reconstruída a cada ação.
##
## F-021.6: "Simular Resultado" (3 botões que injetavam Vitória/
## Derrota/Empate direto no RankingResolver) foi substituído por
## combate real via CombatEngine — mesmo motor do PvE/Campo de Prova,
## nenhum segundo motor. Ver _run_pvp_battle() pro fluxo completo.
##
## F-021.7: identidade visual — este era o único painel de navegação
## fora do padrão HUD do resto do jogo (auditoria da FASE 21). Mesmo
## conjunto de constantes/helpers já usado em exercitos_panel.gd/
## minas_panel.gd/pve_panel.gd (Cinzel-SemiBold, StyleBoxFlat dourado,
## _style_office_button()) — duplicado localmente aqui, mesma convenção
## do projeto (nenhuma classe de estilo compartilhada existe). Nenhuma
## regra de Ranking/Energia/Plano/combate foi tocada nesta fase.
##
## ESCOPO DESTA ENTREGA — ver PlanoCampanhaResolver.gd pro detalhe
## completo: sem Ligas/Divisões/Pontos de Liga, sem Matchmaking. Só a
## criação e configuração do Plano de Campanha, que é tudo que já está
## fechado o suficiente pra implementar sem inventar regra nova.

const COMBAT_REPLAY_VIEW_SCENE_PATH: String = "res://scenes/combat/combat_replay_view.tscn"

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.65, 0.65, 0.62)
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)
const HUD_ERROR_COLOR: Color = Color(0.92, 0.45, 0.40)
const HUD_VICTORY_COLOR: Color = Color(0.5, 0.85, 0.5)
const HUD_WARNING_COLOR: Color = Color(1.0, 0.75, 0.55)

var _root_vbox: VBoxContainer
var _bronze_container: VBoxContainer
var _planos_container: VBoxContainer

var _selected_for_new_plano: Array[Army] = []
var _rng := RandomNumberGenerator.new()

## F-047 (F-019): mensagem visível quando Criar Plano/Sortear Ataque é
## rejeitado — antes só existia um print() no console. refresh() nunca
## destrói este Label (só é criado 1x em _build_static_structure()),
## mesmo padrão de CityPanel._evolve_status_label.
var _action_status_label: Label

## F-021.6: resultado do sorteio de Campo de Batalha de um Plano
## (PlanoCampanhaResolver.select_attack()), retido até o jogador clicar
## "Batalhar" — o mesmo Campo/Exército mostrado na tela é exatamente o
## usado no combate real (nunca sorteado de novo). PlanoCampanha ->
## {"battlefield": BattlefieldResource, "army": Army}.
var _pending_sorteio_by_plano: Dictionary = {}

## F-021.6: overlay de replay + relatório da batalha real (mesmo padrão
## de campo_de_prova_panel.gd) — só existe entre "Batalhar" e o
## jogador fechar o relatório.
var _battle_result_overlay: Control = null


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_static_structure()
	refresh()
	print("[PvPPanel] Pronto. Planos de Campanha: %d" % KingdomState.kingdom.planos_campanha.size())


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.10, 0.10, 0.13)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_style_scrollbar(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(760, 0)
	_root_vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(_root_vbox)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(header_row)

	var back_button := _make_small_button("<- World Map Gate")
	back_button.pressed.connect(_on_back_to_command_center_pressed, CONNECT_DEFERRED)
	header_row.add_child(back_button)

	var title := _make_label("PvP", 24, HUD_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(title)

	var header_spacer := Control.new()
	header_spacer.custom_minimum_size = back_button.custom_minimum_size
	header_row.add_child(header_spacer)

	# F-021.6/21.7: reescrito de novo — "Batalhar" agora roda um combate
	# real (CombatEngine) contra uma IA local, não mais um resultado
	# escolhido pelo jogador ("Simular Resultado", removido).
	var scope_note := _make_centered_label(
		"Prévia do PvP: Ligas, Divisões e Pontos de Liga já funcionam de verdade, e 'Batalhar' resolve um combate real contra uma IA local (mesmo motor do PvE/Campo de Prova). Enfrentar outros jogadores de verdade, via servidor, chega numa atualização futura.",
		12, HUD_MUTED_COLOR, true
	)
	_root_vbox.add_child(scope_note)

	_action_status_label = _make_centered_label("", 12, HUD_WARNING_COLOR, true)
	_root_vbox.add_child(_action_status_label)

	_add_section_title("Liga Bronze", "qualquer Exército Ativo, independente")
	_bronze_container = VBoxContainer.new()
	_bronze_container.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(_bronze_container)

	_add_section_title("Planos de Campanha", "Prata / Ouro / Diamante")
	_planos_container = VBoxContainer.new()
	_planos_container.add_theme_constant_override("separation", 16)
	_root_vbox.add_child(_planos_container)


func _add_section_title(text: String, subtitle: String = "") -> void:
	_root_vbox.add_child(_make_separator())
	var label := _make_label(text.to_upper(), 16, HUD_ACCENT)
	_root_vbox.add_child(label)
	if subtitle != "":
		_root_vbox.add_child(_make_label(subtitle, 11, HUD_MUTED_COLOR))


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	_refresh_bronze(kingdom)
	_refresh_planos(kingdom)


func _active_armies(kingdom: Kingdom) -> Array[Army]:
	var result: Array[Army] = []
	for army: Army in kingdom.armies:
		if army.commander != null and army.commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE:
			result.append(army)
	return result


## F-009: Exércitos sem army_name explícito (ex: formado pelo Kit
## Inicial) nunca devem aparecer como rótulo vazio na tela — "index" é
## a posição do Exército dentro da lista sendo exibida no momento
## (1-based na exibição). Não altera Army.army_name nem o modelo de
## dados — só o texto mostrado.
func _display_army_name(army: Army, index: int) -> String:
	return army.army_name if army.army_name != "" else "Exército %d" % (index + 1)


func _refresh_bronze(kingdom: Kingdom) -> void:
	_clear_children(_bronze_container)

	var bronze_armies: Array[Army] = _active_armies(kingdom)
	for i in range(bronze_armies.size()):
		_bronze_container.add_child(_build_bronze_card(bronze_armies[i], i))

	if _bronze_container.get_child_count() == 0:
		_bronze_container.add_child(_build_empty_state("Nenhum Exército Ativo no momento."))


## Card único por Comandante inscrito/inscritível na Liga Bronze —
## identidade (Exército/Comandante), Divisão/PL como blocos visuais
## (item 3 do pedido) e a ação disponível (Inscrever ou Batalhar, com
## a barra de Energia real quando já inscrito).
func _build_bronze_card(army: Army, index: int) -> Control:
	var commander: CommanderResource = army.commander
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 16)
	vbox.add_child(header_row)

	var identity_box := VBoxContainer.new()
	identity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(identity_box)
	identity_box.add_child(_make_label(_display_army_name(army, index), 15, HUD_TEXT_COLOR))
	identity_box.add_child(_make_label("Comandante: %s" % commander.commander_name, 12, HUD_MUTED_COLOR))

	if commander.bronze_divisao == "":
		header_row.add_child(_make_stat_chip("STATUS", "Não inscrito"))
		vbox.add_child(_make_separator())
		var inscrever_button := _make_primary_button("Inscrever na Liga Bronze")
		inscrever_button.pressed.connect(_on_inscrever_bronze_pressed.bind(commander), CONNECT_DEFERRED)
		vbox.add_child(inscrever_button)
		return card

	header_row.add_child(_make_stat_chip("DIVISÃO", commander.bronze_divisao))
	header_row.add_child(_make_stat_chip("PONTOS DE LIGA", str(commander.bronze_pl)))

	vbox.add_child(_make_separator())
	vbox.add_child(_build_energy_row(army))

	var has_energy: bool = army.has_energy(PlanoCampanhaResolver.ATTACK_ENERGY_COST)
	var battle_button: Button = _make_primary_button("Batalhar (Custo: %d Energia)" % PlanoCampanhaResolver.ATTACK_ENERGY_COST)
	battle_button.disabled = not has_energy or _battle_result_overlay != null
	battle_button.pressed.connect(_on_bronze_battle_pressed.bind(army, commander), CONNECT_DEFERRED)
	vbox.add_child(battle_button)
	if not has_energy:
		vbox.add_child(_make_centered_label("Energia insuficiente para batalhar (%d/%d necessários)." % [army.current_energy, PlanoCampanhaResolver.ATTACK_ENERGY_COST], 11, HUD_WARNING_COLOR))
	elif _battle_result_overlay != null:
		vbox.add_child(_make_centered_label("Feche o relatório da batalha atual antes de batalhar de novo.", 11, HUD_MUTED_COLOR))

	return card


## Barra de fadiga real (ENERGY.md, "Interface") — mesmo componente já
## usado em pve_panel.gd (header da Trilha) e treinamento_panel.gd,
## nunca um valor/estado novo. Cor de aviso quando insuficiente para o
## próprio custo de uma batalha de PvP.
func _build_energy_row(army: Army) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var has_energy: bool = army.has_energy(PlanoCampanhaResolver.ATTACK_ENERGY_COST)
	var caption := _make_label("ENERGIA — %d / %d" % [army.current_energy, army.max_energy], 11, HUD_WARNING_COLOR if not has_energy else HUD_MUTED_COLOR)
	box.add_child(caption)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = clampf(float(army.current_energy) / float(army.max_energy), 0.0, 1.0) if army.max_energy > 0 else 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = HUD_WARNING_COLOR if not has_energy else HUD_ACCENT
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)
	box.add_child(bar)

	return box


func _refresh_planos(kingdom: Kingdom) -> void:
	_clear_children(_planos_container)

	# --- Criar novo Plano ---
	var create_panel := PanelContainer.new()
	create_panel.add_theme_stylebox_override("panel", _card_style())
	_planos_container.add_child(create_panel)
	var create_vbox := VBoxContainer.new()
	create_vbox.add_theme_constant_override("separation", 6)
	create_panel.add_child(create_vbox)
	create_vbox.add_child(_make_label("Criar Plano de Campanha", 14, HUD_ACCENT))
	create_vbox.add_child(_make_label("Escolha até 3 Exércitos Ativos:", 11, HUD_MUTED_COLOR))

	var plano_candidate_armies: Array[Army] = _active_armies(kingdom)
	for i in range(plano_candidate_armies.size()):
		var army: Army = plano_candidate_armies[i]
		var check := CheckBox.new()
		check.text = "%s (%s)" % [_display_army_name(army, i), army.commander.commander_name]
		_style_check_box(check)
		check.button_pressed = _selected_for_new_plano.has(army)
		check.toggled.connect(_on_army_checkbox_toggled.bind(army), CONNECT_DEFERRED)
		create_vbox.add_child(check)

	var create_button := _make_primary_button("Criar Plano de Campanha")
	create_button.pressed.connect(_on_create_plano_pressed, CONNECT_DEFERRED)
	create_vbox.add_child(create_button)

	# --- Planos existentes ---
	for plano: PlanoCampanha in kingdom.planos_campanha:
		_build_plano_panel(plano)


func _build_plano_panel(plano: PlanoCampanha) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_style())
	_planos_container.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var names: Array[String] = []
	for i in range(plano.armies.size()):
		names.append(_display_army_name(plano.armies[i], i))
	vbox.add_child(_make_label("Plano: %s" % ", ".join(names), 15, HUD_TEXT_COLOR))

	# --- Ranking ---
	if plano.liga == "":
		vbox.add_child(_make_separator())
		vbox.add_child(_make_label("Não inscrito em nenhuma Liga.", 12, HUD_MUTED_COLOR))
		var liga_row := HBoxContainer.new()
		liga_row.add_theme_constant_override("separation", 8)
		vbox.add_child(liga_row)
		for liga_name: String in ["Prata", "Ouro", "Diamante"]:
			var inscrever_button := _make_small_button("Inscrever na %s" % liga_name)
			inscrever_button.pressed.connect(_on_inscrever_plano_pressed.bind(plano, liga_name), CONNECT_DEFERRED)
			liga_row.add_child(inscrever_button)
	else:
		var ranking_row := HBoxContainer.new()
		ranking_row.add_theme_constant_override("separation", 16)
		vbox.add_child(ranking_row)
		ranking_row.add_child(_make_stat_chip("LIGA", plano.liga))
		ranking_row.add_child(_make_stat_chip("DIVISÃO", plano.divisao))
		ranking_row.add_child(_make_stat_chip("PONTOS DE LIGA", str(plano.pl)))

		vbox.add_child(_make_separator())
		vbox.add_child(_make_label("PARTIDA", 12, HUD_ACCENT))

		var sortear_button := _make_small_button("Sortear Campo de Batalha (Ataque)")
		sortear_button.disabled = _battle_result_overlay != null
		sortear_button.pressed.connect(_on_sortear_ataque_pressed.bind(plano), CONNECT_DEFERRED)
		vbox.add_child(sortear_button)

		# F-021.6: só aparece depois de um sorteio bem-sucedido — o
		# Campo/Exército mostrados aqui são exatamente os que o combate
		# real vai usar (_pending_sorteio_by_plano), nunca sorteados de
		# novo silenciosamente.
		if _pending_sorteio_by_plano.has(plano):
			var sorteio: Dictionary = _pending_sorteio_by_plano[plano]
			var match_card := PanelContainer.new()
			var match_style := _card_style()
			match_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.12)
			match_style.border_color = HUD_ACCENT_SELECTED
			match_card.add_theme_stylebox_override("panel", match_style)
			vbox.add_child(match_card)
			var match_vbox := VBoxContainer.new()
			match_vbox.add_theme_constant_override("separation", 4)
			match_card.add_child(match_vbox)
			match_vbox.add_child(_make_label("Pronto para atacar", 12, HUD_ACCENT_SELECTED))
			match_vbox.add_child(_make_label("Exército: %s" % sorteio["army"].army_name, 12, HUD_TEXT_COLOR))
			match_vbox.add_child(_make_label("Campo de Batalha: %s" % sorteio["battlefield"].battlefield_name, 12, HUD_TEXT_COLOR))

			var battle_button := _make_primary_button("Batalhar")
			battle_button.disabled = _battle_result_overlay != null
			battle_button.pressed.connect(_on_plano_battle_pressed.bind(plano), CONNECT_DEFERRED)
			match_vbox.add_child(battle_button)

	# Defesa Preferencial (Campo Aberto).
	vbox.add_child(_make_separator())
	vbox.add_child(_make_label("DEFESA", 12, HUD_ACCENT))
	var defesa_row := HBoxContainer.new()
	defesa_row.add_theme_constant_override("separation", 8)
	vbox.add_child(defesa_row)
	defesa_row.add_child(_make_label("Defesa Preferencial (Campo Aberto):", 12, HUD_MUTED_COLOR))
	var defesa_option := OptionButton.new()
	_style_option_button(defesa_option)
	defesa_option.add_item("(nenhum)", -1)
	for i in range(plano.armies.size()):
		defesa_option.add_item(_display_army_name(plano.armies[i], i), i)
	defesa_option.selected = plano.defesa_preferencial_index + 1
	defesa_option.item_selected.connect(_on_defesa_preferencial_selected.bind(plano), CONNECT_DEFERRED)
	defesa_row.add_child(defesa_option)

	# Ordem de Ataque.
	vbox.add_child(_make_separator())
	vbox.add_child(_make_label("ORDEM DE ATAQUE", 12, HUD_ACCENT))
	vbox.add_child(_make_label("Desempate só no Campo Aberto:", 11, HUD_MUTED_COLOR))
	for pos in range(plano.ordem_de_ataque.size()):
		var army_index: int = plano.ordem_de_ataque[pos]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var label := _make_label("%d. %s" % [pos + 1, _display_army_name(plano.armies[army_index], army_index)], 12, HUD_TEXT_COLOR)
		label.custom_minimum_size = Vector2(250, 0)
		row.add_child(label)
		var up_button := _make_small_button("▲")
		up_button.disabled = pos == 0
		up_button.pressed.connect(_on_move_ordem_pressed.bind(plano, pos, -1), CONNECT_DEFERRED)
		row.add_child(up_button)
		var down_button := _make_small_button("▼")
		down_button.disabled = pos == plano.ordem_de_ataque.size() - 1
		down_button.pressed.connect(_on_move_ordem_pressed.bind(plano, pos, 1), CONNECT_DEFERRED)
		row.add_child(down_button)

	# Mapeamento dos 9 Campos Especiais.
	vbox.add_child(_make_separator())
	vbox.add_child(_make_label("CAMPOS ESPECIAIS", 12, HUD_ACCENT))
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category == "Padrão":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var label := _make_label("%s (%s):" % [battlefield.battlefield_name, battlefield.category], 12, HUD_TEXT_COLOR)
		label.custom_minimum_size = Vector2(300, 0)
		row.add_child(label)
		var option := OptionButton.new()
		_style_option_button(option)
		option.add_item("(não mapeado)", -1)
		for i in range(plano.armies.size()):
			option.add_item(_display_army_name(plano.armies[i], i), i)
		var current: int = plano.battlefield_mapping.get(battlefield.battlefield_name, -1)
		option.selected = current + 1
		option.item_selected.connect(_on_battlefield_mapping_selected.bind(plano, battlefield), CONNECT_DEFERRED)
		row.add_child(option)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_army_checkbox_toggled(pressed: bool, army: Army) -> void:
	if pressed:
		if not _selected_for_new_plano.has(army) and _selected_for_new_plano.size() < PlanoCampanhaResolver.MAX_ARMIES:
			_selected_for_new_plano.append(army)
	else:
		_selected_for_new_plano.erase(army)


func _on_create_plano_pressed() -> void:
	if _selected_for_new_plano.is_empty():
		return
	var result: Dictionary = PlanoCampanhaResolver.create(_selected_for_new_plano.duplicate())
	if result["success"]:
		KingdomState.kingdom.planos_campanha.append(result["plano"])
		_selected_for_new_plano.clear()
		_action_status_label.text = ""
	else:
		print("[PvPPanel] Criar Plano de Campanha falhou: %s" % result["reason"])
		_action_status_label.text = "Não foi possível criar o Plano de Campanha: escolha entre 1 e 3 Exércitos."
	refresh()


func _on_defesa_preferencial_selected(index: int, plano: PlanoCampanha) -> void:
	var army_index: int = index - 1
	if army_index < 0:
		plano.defesa_preferencial_index = -1
		return
	PlanoCampanhaResolver.set_defesa_preferencial(plano, army_index)
	refresh()


func _on_move_ordem_pressed(plano: PlanoCampanha, position: int, direction: int) -> void:
	var target: int = position + direction
	if target < 0 or target >= plano.ordem_de_ataque.size():
		return
	var new_order: Array[int] = plano.ordem_de_ataque.duplicate()
	var temp: int = new_order[position]
	new_order[position] = new_order[target]
	new_order[target] = temp
	PlanoCampanhaResolver.set_ordem_de_ataque(plano, new_order)
	refresh()


func _on_battlefield_mapping_selected(index: int, plano: PlanoCampanha, battlefield: BattlefieldResource) -> void:
	var army_index: int = index - 1
	if army_index < 0:
		plano.battlefield_mapping.erase(battlefield.battlefield_name)
		return
	PlanoCampanhaResolver.map_battlefield(plano, battlefield, army_index)
	refresh()


func _on_inscrever_bronze_pressed(commander: CommanderResource) -> void:
	commander.bronze_divisao = RankingResolver.initial_division()
	commander.bronze_pl = 0
	refresh()


## F-021.6: substitui _on_simulate_bronze_result_pressed() — o resultado
## agora vem de um combate real (_run_pvp_battle()), nunca escolhido
## diretamente pelo jogador. Bronze não distingue Ataque/Defesa
## (RANKING.md, "Isenções do Modelo") — usa sempre a tabela de Atacante.
func _on_bronze_battle_pressed(army: Army, commander: CommanderResource) -> void:
	if not army.has_energy(PlanoCampanhaResolver.ATTACK_ENERGY_COST) or _battle_result_overlay != null:
		return
	var battlefields: Array[BattlefieldResource] = GameDatabase.battlefields
	await _run_pvp_battle(army, battlefields, _apply_bronze_ranking_result.bind(commander))


## Extraído como método nomeado (em vez de closure inline) para ser
## testável sem depender do fluxo assíncrono de replay (F-021.6, item 15).
## Bronze não distingue Ataque/Defesa (RANKING.md, "Isenções do
## Modelo") — usa sempre a tabela de Atacante. F-021.7: retorna
## {"pl_before", "pl_after", "division_before", "division_after",
## "promoted", "demoted"} — o relatório usa isto pra mostrar o impacto
## real no Ranking (item 7 do pedido), nunca um valor calculado de novo.
func _apply_bronze_ranking_result(result: RankingResolver.Result, commander: CommanderResource) -> Dictionary:
	var pl_before: int = commander.bronze_pl
	var division_before: String = commander.bronze_divisao
	var outcome: Dictionary = RankingResolver.apply_result(pl_before, division_before, RankingResolver.Role.ATACANTE, result)
	commander.bronze_pl = outcome["pl"]
	commander.bronze_divisao = outcome["division"]
	return {
		"pl_before": pl_before, "pl_after": outcome["pl"],
		"division_before": division_before, "division_after": outcome["division"],
		"promoted": outcome["promoted"], "demoted": outcome["demoted"],
	}


func _on_inscrever_plano_pressed(plano: PlanoCampanha, liga_name: String) -> void:
	plano.liga = liga_name
	plano.divisao = RankingResolver.initial_division()
	plano.pl = 0
	refresh()


## F-021.6: substitui _on_simulate_plano_result_pressed() — dispara o
## combate real usando exatamente o Campo/Exército já sorteados e
## retidos em _pending_sorteio_by_plano (nunca sorteia de novo).
func _on_plano_battle_pressed(plano: PlanoCampanha) -> void:
	if not _pending_sorteio_by_plano.has(plano) or _battle_result_overlay != null:
		return
	var sorteio: Dictionary = _pending_sorteio_by_plano[plano]
	_pending_sorteio_by_plano.erase(plano)
	var battlefields: Array[BattlefieldResource] = [sorteio["battlefield"]]
	await _run_pvp_battle(sorteio["army"], battlefields, _apply_plano_ranking_result.bind(plano))


## Ver docstring de _apply_bronze_ranking_result() — mesmo motivo e mesmo
## formato de retorno.
func _apply_plano_ranking_result(result: RankingResolver.Result, plano: PlanoCampanha) -> Dictionary:
	var pl_before: int = plano.pl
	var division_before: String = plano.divisao
	var outcome: Dictionary = RankingResolver.apply_result(pl_before, division_before, RankingResolver.Role.ATACANTE, result)
	plano.pl = outcome["pl"]
	plano.divisao = outcome["division"]
	return {
		"pl_before": pl_before, "pl_after": outcome["pl"],
		"division_before": division_before, "division_after": outcome["division"],
		"promoted": outcome["promoted"], "demoted": outcome["demoted"],
	}


func _on_sortear_ataque_pressed(plano: PlanoCampanha) -> void:
	var result: Dictionary = PlanoCampanhaResolver.select_attack(plano, GameDatabase.battlefields, _rng)
	if not result["success"]:
		print("[PvPPanel] Sortear Campo falhou: %s" % result["reason"])
		_action_status_label.text = "Não foi possível sortear o Campo de Batalha: nenhum Exército deste Plano tem Energia disponível."
		_pending_sorteio_by_plano.erase(plano)
	else:
		print("[PvPPanel] Campo sorteado: %s | Exército atacante: %s" % [result["battlefield"].battlefield_name, result["army"].army_name])
		_action_status_label.text = "Campo sorteado: %s | Exército atacante: %s — clique 'Batalhar' para lutar." % [result["battlefield"].battlefield_name, result["army"].army_name]
		_pending_sorteio_by_plano[plano] = {"battlefield": result["battlefield"], "army": result["army"]}
	refresh()


# ------------------------------------------------------------------
# F-021.6 — Combate real de PvP
# ------------------------------------------------------------------

## Único ponto que decide QUEM é o defensor da IA local — a "costura"
## exigida pra que, no futuro, um defensor de servidor possa substituir
## isto sem tocar em CombatEngine/_run_pvp_battle() (F-021.6, item 18:
## "a origem desses Exércitos não deve ficar acoplada ao motor de
## combate"). Decisão registrada em FASE_21_CONTROLE_TEMPORARIO.md:
## a IA usa o mesmo teto de Soldo/Patente do próprio atacante — nem
## EnemyArmyGenerator (PvE) nem ArmyRandomComposer têm um conceito de
## "Divisão", e nenhum documento define Divisão -> Tier/Patente; inventar
## essa tabela é exatamente o que CLAUDE.md proíbe. TestArmyFactory
## (já usada pelo Campo de Prova) gera Comandante procedural + 9 Cartas
## reais do catálogo completo + Formação δ, sempre dentro do teto real.
func _generate_ai_defender(attacker: Army) -> Army:
	var patente: String = CommanderCareer.patente_for_xp(attacker.commander.accumulated_xp) if attacker.commander != null else TestArmyFactory.DEFAULT_PATENTE
	return TestArmyFactory.generate_random_army(patente)


## LACUNA REGISTRADA (não inventada): ENERGY.md descreve o PvP como uma
## "série Melhor de 5", mas RANKING.md/MATCHMAKING.md nunca definem como
## essa série funciona (mesma Formação a cada partida? o que decide um
## 2-2?) — decisão do usuário (Fase 21.6): implementar 1 batalha real
## por enquanto (custo de Energia já é fixo "independente da quantidade
## de partidas", compatível com N=1), registrando a série completa como
## pendência de design futura.
##
## Núcleo testável sem SceneTree/replay (mesmo espírito de
## _run_prova() em campo_de_prova_panel.gd, cuja fase de replay também
## nunca é exercitada pela suíte de testes — só CombatEngine, que já é
## real e determinístico): resolve o combate real, consome a Energia
## fixa e devolve {"state": CombatState, "defender": Army, "result":
## RankingResolver.Result}, ou {} se o defensor não pôde ser gerado.
func _resolve_pvp_combat(attacker: Army, battlefields: Array[BattlefieldResource]) -> Dictionary:
	var defender: Army = _generate_ai_defender(attacker)
	if not defender.is_ready_for_battle():
		# Nunca deveria acontecer (catálogo completo sempre cobre o teto
		# de qualquer Patente) — defensivo, nunca uma batalha com dado
		# inventado/incompleto.
		return {}

	var seed_value: int = randi()
	var state: CombatState = CombatEngine.initialize(
		attacker, defender, battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pvp", seed_value
	)
	var replay_collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	replay_collector.attach(state.event_bus)
	replay_collector.snapshot_initial_board(state)
	CombatEngine.run(state)

	attacker.consume_energy(PlanoCampanhaResolver.ATTACK_ENERGY_COST)

	var result: RankingResolver.Result
	if state.winner_side == 0:
		result = RankingResolver.Result.VITORIA
	elif state.winner_side == 1:
		result = RankingResolver.Result.DERROTA
	else:
		result = RankingResolver.Result.EMPATE

	return {"state": state, "defender": defender, "result": result, "replay_collector": replay_collector}


func _run_pvp_battle(attacker: Army, battlefields: Array[BattlefieldResource], apply_ranking: Callable) -> void:
	var combat: Dictionary = _resolve_pvp_combat(attacker, battlefields)
	if combat.is_empty():
		_action_status_label.text = "Não foi possível gerar um adversário válido no momento. Tente novamente."
		refresh()
		return

	var state: CombatState = combat["state"]
	var defender: Army = combat["defender"]
	var replay_collector = combat["replay_collector"]
	var ranking_outcome: Dictionary = apply_ranking.call(combat["result"])

	var view = load(COMBAT_REPLAY_VIEW_SCENE_PATH).instantiate()
	view.combat_state = state
	view.replay_collector = replay_collector
	view.player_side = 0
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	await view.replay_finished
	remove_child(view)
	view.queue_free()

	_battle_result_overlay = _build_battle_result_overlay(attacker, defender, state, ranking_outcome)
	add_child(_battle_result_overlay)


## Relatório real da batalha (F-021.7: janela modal opaca, mesmo padrão
## de pve_panel.gd — Acampamento/Mina — em vez de um PanelContainer
## Godot padrão): vencedor, os dois Exércitos/Comandantes REAIS, Campo
## de Batalha, turnos, e o impacto real no Ranking (item 7 do pedido).
## Nunca "Player Army"/"Enemy Army"/"Formation 1" — sempre os nomes
## reais; nunca um dado inventado quando algo não existir.
func _build_battle_result_overlay(attacker: Army, defender: Army, state: CombatState, ranking_outcome: Dictionary) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.7)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var window := PanelContainer.new()
	window.custom_minimum_size = Vector2(460, 0)
	window.add_theme_stylebox_override("panel", _modal_style())
	center.add_child(window)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	window.add_child(vbox)

	var attacker_name: String = attacker.commander.commander_name if attacker.commander != null else attacker.army_name
	var defender_name: String = defender.commander.commander_name if defender.commander != null else defender.army_name

	var result_text: String
	var result_color: Color
	if state.winner_side == 0:
		result_text = "VITÓRIA"
		result_color = HUD_VICTORY_COLOR
	elif state.winner_side == 1:
		result_text = "DERROTA"
		result_color = HUD_ERROR_COLOR
	else:
		result_text = "EMPATE"
		result_color = HUD_ACCENT

	vbox.add_child(_make_centered_label(result_text, 24, result_color))
	var winner_line: String = "%s venceu" % attacker_name if state.winner_side == 0 else ("%s venceu" % defender_name if state.winner_side == 1 else "Nenhum dos lados venceu")
	vbox.add_child(_make_centered_label(winner_line, 13, HUD_TEXT_COLOR, true))

	vbox.add_child(_make_separator())

	var attacker_army_display: String = attacker.army_name if attacker.army_name != "" else "Seu Exército"
	vbox.add_child(_make_centered_label("Seu Exército: %s (%s)" % [attacker_army_display, attacker_name], 12, HUD_TEXT_COLOR, true))
	vbox.add_child(_make_centered_label("Adversário: %s (%s)" % [defender.army_name, defender_name], 12, HUD_TEXT_COLOR, true))
	vbox.add_child(_make_centered_label("Campo de Batalha: %s | Turnos: %d" % [state.battlefield.battlefield_name, state.turn], 12, HUD_MUTED_COLOR, true))

	vbox.add_child(_make_separator())

	var pl_delta: int = ranking_outcome["pl_after"] - ranking_outcome["pl_before"]
	var delta_text: String = "+%d PL" % pl_delta if pl_delta > 0 else ("%d PL" % pl_delta if pl_delta < 0 else "sem alteração de PL")
	var delta_color: Color = HUD_VICTORY_COLOR if pl_delta > 0 else (HUD_ERROR_COLOR if pl_delta < 0 else HUD_MUTED_COLOR)
	vbox.add_child(_make_label("IMPACTO NO RANKING", 12, HUD_ACCENT))
	vbox.add_child(_make_centered_label("%d -> %d PL (%s)" % [ranking_outcome["pl_before"], ranking_outcome["pl_after"], delta_text], 13, delta_color))
	if ranking_outcome["promoted"]:
		vbox.add_child(_make_centered_label("Promovido: Divisão %s -> Divisão %s" % [ranking_outcome["division_before"], ranking_outcome["division_after"]], 12, HUD_VICTORY_COLOR))
	elif ranking_outcome["demoted"]:
		vbox.add_child(_make_centered_label("Rebaixado: Divisão %s -> Divisão %s" % [ranking_outcome["division_before"], ranking_outcome["division_after"]], 12, HUD_ERROR_COLOR))
	else:
		vbox.add_child(_make_centered_label("Divisão %s" % ranking_outcome["division_after"], 12, HUD_MUTED_COLOR))

	var close_button := _make_primary_button("Fechar")
	close_button.pressed.connect(_on_close_battle_result_pressed, CONNECT_DEFERRED)
	vbox.add_child(close_button)

	return overlay


func _on_close_battle_result_pressed() -> void:
	if _battle_result_overlay != null:
		remove_child(_battle_result_overlay)
		_battle_result_overlay.queue_free()
		_battle_result_overlay = null
	refresh()


func _on_back_to_command_center_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/world_map_gate/world_map_gate_panel.tscn")


# ------------------------------------------------------------------
# F-021.7 — Identidade visual (mesmo padrão de exercitos_panel.gd/
# minas_panel.gd/pve_panel.gd — duplicado localmente, convenção do
# projeto: nenhuma classe de estilo compartilhada existe).
# ------------------------------------------------------------------

func _make_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_centered_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := _make_label(text, font_size, color, wrap)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


## Moldura dourada translúcida — mesmo padrão de pve_panel.gd::_card_style()/
## minas_panel.gd (toda a Cidade/Command Center usa este mesmo StyleBoxFlat).
func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.08)
	style.set_border_width_all(1)
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


## Janela modal opaca — mesmo padrão de pve_panel.gd::_modal_style()
## (Acampamento/Mina): fundo sólido escuro + moldura dourada mais
## grossa, pra nunca deixar o conteúdo por baixo (mapa/lista) sangrar
## através do relatório.
func _modal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.11, 0.98)
	style.set_border_width_all(2)
	style.border_color = HUD_ACCENT
	style.set_corner_radius_all(8)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style


func _make_stat_chip(title_text: String, value_text: String) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	vbox.add_child(_make_centered_label(title_text, 10, HUD_MUTED_COLOR))
	vbox.add_child(_make_centered_label(value_text, 15, HUD_TEXT_COLOR))
	return card


func _build_empty_state(text: String) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	card.add_child(_make_centered_label(text, 13, HUD_MUTED_COLOR))
	return card


func _style_office_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	button.add_theme_color_override("font_disabled_color", HUD_MUTED_COLOR)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	normal_style.set_border_width_all(1)
	normal_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 10.0
	normal_style.content_margin_right = 10.0
	button.add_theme_stylebox_override("normal", normal_style)
	var disabled_style: StyleBoxFlat = normal_style.duplicate()
	disabled_style.bg_color = Color(0.06, 0.07, 0.11, 0.4)
	disabled_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.25)
	button.add_theme_stylebox_override("disabled", disabled_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.22)
	hover_style.border_color = HUD_ACCENT_SELECTED
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


## Ação principal ("Batalhar"/"Inscrever"/"Criar Plano") — borda dourada
## clara acesa, mesmo tratamento de exercitos_panel.gd::_make_primary_button().
func _make_primary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(0, 38)
	_style_office_button(button)

	var accent_style := StyleBoxFlat.new()
	accent_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.20)
	accent_style.set_border_width_all(2)
	accent_style.border_color = HUD_ACCENT_SELECTED
	accent_style.set_corner_radius_all(4)
	accent_style.content_margin_left = 16.0
	accent_style.content_margin_right = 16.0
	button.add_theme_stylebox_override("normal", accent_style)
	var disabled_accent: StyleBoxFlat = accent_style.duplicate()
	disabled_accent.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.06)
	disabled_accent.border_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.3)
	button.add_theme_stylebox_override("disabled", disabled_accent)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size = Vector2(0, 30)
	_style_office_button(button)
	return button


func _style_option_button(option: OptionButton) -> void:
	option.add_theme_font_override("font", HUD_FONT)
	option.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	style.set_border_width_all(1)
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	option.add_theme_stylebox_override("normal", style)


func _style_check_box(check: CheckBox) -> void:
	check.add_theme_font_override("font", HUD_FONT)
	check.add_theme_color_override("font_color", HUD_TEXT_COLOR)


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var v_scroll: VScrollBar = scroll.get_v_scroll_bar()
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	grabber_style.set_corner_radius_all(4)
	v_scroll.add_theme_stylebox_override("grabber", grabber_style)
	var grabber_hover_style: StyleBoxFlat = grabber_style.duplicate()
	grabber_hover_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.9)
	v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover_style)
	v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_hover_style)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	track_style.set_corner_radius_all(4)
	v_scroll.add_theme_stylebox_override("scroll", track_style)
