extends Control
## ComandantesPanel (COMMAND_CENTER_UI.md, "Janela: Comandantes")
##
## Candidatos (Centro de Recrutamento + Painel PvE), Reserva e Ativos —
## tudo ligado direto ao Kingdom real via KingdomState, sem estado
## próprio. Reconstrói a árvore de UI inteira a cada ação (padrão
## simples e robusto pra uma tela cujo conteúdo muda a toda hora) —
## trocar por atualização incremental é uma otimização futura, não
## necessária no volume de dados deste jogo.
##
## Toda a árvore é construída em código (não no .tscn) de propósito:
## o conteúdo é 100% dependente de dados em runtime (quantos
## Candidatos, quantos Comandantes na Reserva etc.) — não há nada fixo
## pra desenhar de antemão no Editor.

const CommandCenterProgressScript = preload("res://engine/command_center/command_center_progress.gd")

var _root_vbox: VBoxContainer
var _resumo_label: Label
var _candidatos_container: VBoxContainer
var _reserva_container: VBoxContainer
var _ativos_container: VBoxContainer
var _historico_container: VBoxContainer
var _selected_history_commander: CommanderResource = null

var _doutrina_comandante_container: VBoxContainer
var _selected_doctrine_commander: CommanderResource = null


func _ready() -> void:
	print("[ComandantesPanel] _ready() iniciado.")

	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	print("[ComandantesPanel] Fundo adicionado — se você está vendo essa cor escura, a cena está rodando; se a tela continua cinza padrão, a cena nem chegou a instanciar.")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	print("[ComandantesPanel] KingdomState pronto. Kingdom válido? %s" % str(KingdomState.kingdom != null))

	_build_static_structure()
	print("[ComandantesPanel] Estrutura estática construída. Filhos do painel: %d" % get_child_count())

	refresh()
	print("[ComandantesPanel] refresh() concluído. Filhos da Reserva: %d" % _reserva_container.get_child_count())


## Monta a estrutura fixa da tela (containers, títulos) — só o
## CONTEÚDO de cada seção é reconstruído depois, em refresh().
func _build_static_structure() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(600, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Comandantes"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	# --- Resumo ---
	var resumo_panel := PanelContainer.new()
	_root_vbox.add_child(resumo_panel)
	var resumo_vbox := VBoxContainer.new()
	resumo_panel.add_child(resumo_vbox)
	_resumo_label = Label.new()
	resumo_vbox.add_child(_resumo_label)
	var activate_button := Button.new()
	activate_button.text = "Ativar Próximo Recurso Administrativo"
	activate_button.pressed.connect(_on_activate_next_pressed, CONNECT_DEFERRED)
	resumo_vbox.add_child(activate_button)

	# [DEBUG] Gera um Candidato imediatamente, ignorando o cooldown de
	# 24h — só pra testar a mecânica de Doutrina (Restrição/Requisito/
	# Efeito) sem precisar esperar tempo real de verdade. Nunca deve
	# existir fora do modo de desenvolvimento.
	var debug_button := Button.new()
	debug_button.text = "[DEBUG] Gerar Candidato Agora"
	debug_button.pressed.connect(_on_debug_generate_candidate_pressed, CONNECT_DEFERRED)
	resumo_vbox.add_child(debug_button)

	# --- Candidatos ---
	_add_section_title("Candidatos")
	_candidatos_container = VBoxContainer.new()
	_root_vbox.add_child(_candidatos_container)

	# --- Reserva ---
	_add_section_title("Reserva")
	_reserva_container = VBoxContainer.new()
	_root_vbox.add_child(_reserva_container)

	# --- Ativos ---
	_add_section_title("Ativos")
	_ativos_container = VBoxContainer.new()
	_root_vbox.add_child(_ativos_container)

	_add_section_title("Histórico de Batalhas")
	_historico_container = VBoxContainer.new()
	_root_vbox.add_child(_historico_container)

	_add_section_title("Doutrina do Comandante")
	_doutrina_comandante_container = VBoxContainer.new()
	_root_vbox.add_child(_doutrina_comandante_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


## Reconstrói o conteúdo dinâmico inteiro a partir do estado atual do
## Kingdom — chamado no início e depois de qualquer ação do jogador.
func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	# Sem isso, o Centro de Recrutamento nunca avançava o cooldown nem
	# gerava novos Candidatos de verdade — GameRuntime.sync() nunca
	# era chamado por nenhuma tela real (só nos testes), documentado
	# como obrigatório aqui desde que foi escrito.
	GameRuntime.sync(kingdom, GameClock.now_unix())

	var cargo_ativo_cap: int = CommandCenterProgressScript.effective_cargo_ativo(kingdom)
	var cargo_ativo_used: int = _count_by_state(kingdom, CommanderResource.AdministrativeState.ACTIVE)
	var vaga_reserva_cap: int = CommandCenterProgressScript.effective_vaga_reserva(kingdom)
	var vaga_reserva_used: int = kingdom.reserve_occupancy()
	_resumo_label.text = "Cargos de Comando Ativo: %d / %d    |    Vagas da Reserva: %d / %d" % [
		cargo_ativo_used, cargo_ativo_cap, vaga_reserva_used, vaga_reserva_cap
	]

	_refresh_candidatos(kingdom)
	_refresh_reserva(kingdom)
	_refresh_ativos(kingdom)
	_refresh_historico()
	_refresh_doutrina()


func _refresh_candidatos(kingdom: Kingdom) -> void:
	_clear_children(_candidatos_container)

	kingdom.sync_recruitment_center_slots()
	var cooldown_seconds: int = CommandCenterProgressScript.recruitment_center_cooldown_seconds(kingdom.command_center_level)
	var empty_slot_rank: int = 0  # quantos Slots vazios já vimos até agora, na ordem fixa (COMMAND_CENTER_RECRUITMENT.md, "Geração Sequencial")

	for i in range(kingdom.recruitment_center_slots.size()):
		var candidate: CommanderResource = kingdom.recruitment_center_slots[i]
		var row := HBoxContainer.new()
		_candidatos_container.add_child(row)

		var label := Label.new()
		if candidate != null:
			label.text = "[Centro de Recrutamento] %s (%s)" % [candidate.commander_name, candidate.faction]
		else:
			# O 1º Slot vazio usa o Ciclo já em andamento; cada Slot
			# vazio SEGUINTE soma mais um Ciclo inteiro — nunca todos
			# ao mesmo tempo (bug relatado: os 3 mostravam o mesmo
			# tempo, ignorando a ordem sequencial).
			var current_cycle_remaining: int = maxi(0, kingdom.recruitment_center_cycle_end_unix - GameClock.now_unix())
			var remaining: int = current_cycle_remaining + empty_slot_rank * cooldown_seconds
			label.text = "[Centro de Recrutamento] Slot %d vazio (próximo em ~%ds)" % [i + 1, remaining]
			empty_slot_rank += 1
		label.custom_minimum_size = Vector2(400, 0)
		row.add_child(label)

		if candidate != null:
			var button := Button.new()
			button.text = "Comissionar"
			# Ordem sequencial obrigatória (COMMAND_CENTER_RECRUITMENT.md,
			# "Ordem de Comissionamento") — só o primeiro Slot ocupado
			# pode ser comissionado, nunca pular a ordem de chegada.
			button.disabled = i != _first_occupied_recruitment_slot(kingdom)
			button.pressed.connect(_on_commission_from_slot_pressed.bind(i), CONNECT_DEFERRED)
			row.add_child(button)

			var doctrine_button := Button.new()
			doctrine_button.text = "Ver Doutrina"
			doctrine_button.pressed.connect(_on_view_doctrine_pressed.bind(candidate), CONNECT_DEFERRED)
			row.add_child(doctrine_button)

	for offer: RecruitmentOffer in kingdom.pending_recruitment_offers:
		var row := HBoxContainer.new()
		_candidatos_container.add_child(row)

		var label := Label.new()
		label.text = "[Campanha PvE] %s (%s)" % [offer.commander.commander_name, offer.commander.faction]
		label.custom_minimum_size = Vector2(400, 0)
		row.add_child(label)

		var accept_button := Button.new()
		accept_button.text = "Aceitar"
		accept_button.pressed.connect(_on_accept_offer_pressed.bind(offer), CONNECT_DEFERRED)
		row.add_child(accept_button)

		var decline_button := Button.new()
		decline_button.text = "Recusar"
		decline_button.pressed.connect(_on_decline_offer_pressed.bind(offer), CONNECT_DEFERRED)
		row.add_child(decline_button)

	if _candidatos_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Candidato no momento."
		_candidatos_container.add_child(empty_label)


func _refresh_reserva(kingdom: Kingdom) -> void:
	_clear_children(_reserva_container)

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
			continue

		# Layout em 2 linhas (rótulo em cima, ações embaixo) — uma
		# única fileira horizontal com rótulo + 4 controles (Promover,
		# dropdown de Permuta, Trocar, Ver Histórico) ultrapassava a
		# largura da tela, empurrando a Permuta pra fora da área
		# visível. Bug real relatado: parecia que a Permuta não
		# existia, mas só estava cortada da tela.
		var column := VBoxContainer.new()
		_reserva_container.add_child(column)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var label := Label.new()
		label.text = "%s | %s | %s | V:%d E:%d D:%d | WR: %.1f%% | %s" % [
			commander.commander_name, patente, commander.faction,
			commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0,
			CommanderCareer.xp_progress_text(commander.accumulated_xp)
		]
		column.add_child(label)

		var actions_row := HBoxContainer.new()
		column.add_child(actions_row)

		var button := Button.new()
		button.text = "Promover a Ativo"
		button.pressed.connect(_on_promote_pressed.bind(commander), CONNECT_DEFERRED)
		actions_row.add_child(button)

		# Permuta (COMMAND_CENTER.md, "Permuta entre Ativo e Reserva") —
		# resolve o impasse de Cargo Ativo E Vaga da Reserva ambos no
		# limite ao mesmo tempo, onde nem "Promover" nem "Voltar à
		# Reserva" sozinhos conseguem funcionar.
		var active_commanders: Array[CommanderResource] = []
		for c: CommanderResource in kingdom.commanders:
			if c.administrative_state == CommanderResource.AdministrativeState.ACTIVE:
				active_commanders.append(c)
		if not active_commanders.is_empty():
			var swap_option := OptionButton.new()
			for active_commander: CommanderResource in active_commanders:
				swap_option.add_item(active_commander.commander_name)
			actions_row.add_child(swap_option)

			var swap_button := Button.new()
			swap_button.text = "Trocar"
			swap_button.pressed.connect(_on_swap_pressed.bind(commander, active_commanders, swap_option), CONNECT_DEFERRED)
			actions_row.add_child(swap_button)

		var history_button := Button.new()
		history_button.text = "Ver Histórico"
		history_button.pressed.connect(_on_view_history_pressed.bind(commander), CONNECT_DEFERRED)
		actions_row.add_child(history_button)

		var doctrine_button := Button.new()
		doctrine_button.text = "Ver Doutrina"
		doctrine_button.pressed.connect(_on_view_doctrine_pressed.bind(commander), CONNECT_DEFERRED)
		actions_row.add_child(doctrine_button)

	if _reserva_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante na Reserva."
		_reserva_container.add_child(empty_label)


func _refresh_ativos(kingdom: Kingdom) -> void:
	_clear_children(_ativos_container)

	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
			continue

		var row := HBoxContainer.new()
		_ativos_container.add_child(row)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var function_text: String = "Ocioso" if commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE else "Liderando um Exército"
		var label := Label.new()
		label.text = "%s | %s | %s | %s | V:%d E:%d D:%d | WR: %.1f%% | %s" % [
			commander.commander_name, patente, commander.faction, function_text,
			commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0,
			CommanderCareer.xp_progress_text(commander.accumulated_xp)
		]
		label.custom_minimum_size = Vector2(500, 0)
		row.add_child(label)

		var button := Button.new()
		button.text = "Voltar à Reserva"
		button.disabled = commander.ownership_status == CommanderResource.OwnershipStatus.EM_EXERCITO
		button.pressed.connect(_on_return_to_reserve_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(button)

		var history_button := Button.new()
		history_button.text = "Ver Histórico"
		history_button.pressed.connect(_on_view_history_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(history_button)

		var doctrine_button := Button.new()
		doctrine_button.text = "Ver Doutrina"
		doctrine_button.pressed.connect(_on_view_doctrine_pressed.bind(commander), CONNECT_DEFERRED)
		row.add_child(doctrine_button)

	if _ativos_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhum Comandante Ativo."
		_ativos_container.add_child(empty_label)


func _clear_children(container: Node) -> void:
	# Remoção IMEDIATA (não queue_free): esta tela reconstrói a árvore
	# inteira sincronamente a cada refresh() — queue_free() só remove no
	# fim do frame, o que deixaria nós antigos e novos coexistindo até lá
	# (encontrado num teste que checava se algo tinha sumido da lista).
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _count_by_state(kingdom: Kingdom, state: CommanderResource.AdministrativeState) -> int:
	var count: int = 0
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state == state:
			count += 1
	return count


func _on_activate_next_pressed() -> void:
	CommandCenterResolver.activate_next(KingdomState.kingdom)
	refresh()


## [DEBUG] Força a geração imediata de 1 Candidato, ignorando o
## cooldown real de 24h — só pra testar a Doutrina do Comandante
## (Restrição/Requisito/Efeito) sem precisar esperar tempo de verdade.
func _on_debug_generate_candidate_pressed() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(kingdom, GameClock.now_unix())
	refresh()


func _on_commission_from_slot_pressed(slot_index: int) -> void:
	RecruitmentCenterResolver.commission_from_slot(KingdomState.kingdom, slot_index, GameClock.now_unix())
	refresh()


func _first_occupied_recruitment_slot(kingdom: Kingdom) -> int:
	for i in range(kingdom.recruitment_center_slots.size()):
		if kingdom.recruitment_center_slots[i] != null:
			return i
	return -1


func _on_accept_offer_pressed(offer: RecruitmentOffer) -> void:
	CommissioningResolver.commission_from_pve_offer(KingdomState.kingdom, offer, GameClock.now_unix())
	refresh()


func _on_decline_offer_pressed(offer: RecruitmentOffer) -> void:
	KingdomState.kingdom.decline_recruitment_offer(offer)
	refresh()


func _on_promote_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_active(KingdomState.kingdom, commander)
	refresh()


## Permuta atômica — só faz sentido quando existe pelo menos 1
## Comandante Ativo pra trocar de lugar (o seletor sempre tem
## conteúdo nesse caso, garantido por _refresh_reserva()).
func _on_swap_pressed(reserve_commander: CommanderResource, active_commanders: Array[CommanderResource], option: OptionButton) -> void:
	var active_commander: CommanderResource = active_commanders[option.selected]
	CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	refresh()


func _on_return_to_reserve_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_reserve(KingdomState.kingdom, commander)
	refresh()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")


## Exibe a Doutrina do Comandante selecionado (COMMANDER_GENERATION.md:
## Restrição -> Requisito -> Alvo -> Efeito -> Valor) — nunca tinha
## tela nenhuma antes, só existia como lógica testada internamente.
func _refresh_doutrina() -> void:
	_clear_children(_doutrina_comandante_container)

	if _selected_doctrine_commander == null:
		var empty_label := Label.new()
		empty_label.text = "Clique em \"Ver Doutrina\" num Comandante para ver a Restrição, o Requisito, o Alvo, o Efeito e o Valor da sua vantagem."
		_doutrina_comandante_container.add_child(empty_label)
		return

	var title := Label.new()
	title.text = "Doutrina de %s (%s):" % [_selected_doctrine_commander.commander_name, _selected_doctrine_commander.faction]
	_doutrina_comandante_container.add_child(title)

	var doctrine: CommanderDoctrine = _selected_doctrine_commander.doctrine
	if doctrine == null:
		var no_doctrine_label := Label.new()
		no_doctrine_label.text = "Este Comandante não tem Doutrina (ex: Comandante do Kit Inicial — nasce sem vantagem, sem Restrição)."
		_doutrina_comandante_container.add_child(no_doctrine_label)
		return

	var restriction_text: String = doctrine.restriction.description
	if doctrine.restriction_param != "":
		restriction_text += " (%s)" % doctrine.restriction_param
	_add_doutrina_line("Restrição", restriction_text)

	var requirement_text: String = doctrine.requirement.description
	if doctrine.requirement_param != "":
		requirement_text += " (%s)" % doctrine.requirement_param
	_add_doutrina_line("Requisito", requirement_text)

	var target_text: String = doctrine.target.description
	if doctrine.target.value != "":
		target_text += " (%s)" % doctrine.target.value
	_add_doutrina_line("Alvo", target_text)

	_add_doutrina_line("Efeito", doctrine.effect.description)

	var value_text: String = "%.0f%%" % (doctrine.value.amount * 100.0) if doctrine.value.is_percentage else str(doctrine.value.amount)
	_add_doutrina_line("Valor", value_text)


func _add_doutrina_line(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = "%s: %s" % [label_text, value_text]
	_doutrina_comandante_container.add_child(label)


func _on_view_doctrine_pressed(commander: CommanderResource) -> void:
	_selected_doctrine_commander = commander
	refresh()


func _refresh_historico() -> void:
	_clear_children(_historico_container)

	if _selected_history_commander == null:
		var empty_label := Label.new()
		empty_label.text = "Clique em \"Ver Histórico\" num Comandante para ver suas últimas 20 batalhas."
		_historico_container.add_child(empty_label)
		return

	var title := Label.new()
	title.text = "Últimas batalhas de %s:" % _selected_history_commander.commander_name
	_historico_container.add_child(title)

	for entry: Dictionary in _selected_history_commander.battle_log:
		var separator := HSeparator.new()
		_historico_container.add_child(separator)

		var label := Label.new()
		label.text = "%s | contra: %s | %s" % [entry.get("context", ""), entry.get("opponent_name", ""), entry.get("result", "")]
		_historico_container.add_child(label)

		var own_formation: Array = entry.get("own_formation", [])
		var enemy_formation: Array = entry.get("enemy_formation", [])
		if not own_formation.is_empty() and not enemy_formation.is_empty():
			var grids_row := HBoxContainer.new()
			grids_row.add_theme_constant_override("separation", 24)
			_historico_container.add_child(grids_row)
			grids_row.add_child(_build_formation_grid_display("Seu Exército", own_formation))
			grids_row.add_child(_build_formation_grid_display("Inimigo", enemy_formation))

	if _selected_history_commander.battle_log.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhuma batalha registrada ainda."
		_historico_container.add_child(empty_label)


## Monta o tabuleiro 3x3 visual de 1 Formação — mesma numeração
## oficial usada em toda parte do jogo (ARMY.md):
##   7 8 9   (Linha 3)
##   6 5 4   (Linha 2)
##   1 2 3   (Linha 1, mais perto do adversário)
func _build_formation_grid_display(title_text: String, formation: Array) -> Control:
	var container := VBoxContainer.new()

	var title_label := Label.new()
	title_label.text = title_text
	container.add_child(title_label)

	var grid := GridContainer.new()
	grid.columns = 3
	container.add_child(grid)

	# Índices na ordem visual (0-based: índice 0 = Posição 1, ..., 8 = Posição 9)
	var visual_order: Array[int] = [6, 7, 8, 5, 4, 3, 0, 1, 2]
	for index: int in visual_order:
		var cell := Label.new()
		cell.custom_minimum_size = Vector2(110, 0)
		cell.text = str(formation[index]) if index < formation.size() and formation[index] != "" else "—"
		cell.add_theme_font_size_override("font_size", 12)
		grid.add_child(cell)

	return container


func _on_view_history_pressed(commander: CommanderResource) -> void:
	_selected_history_commander = commander
	refresh()
