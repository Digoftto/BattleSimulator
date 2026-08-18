extends Control
## MinasPanel (COMMAND_CENTER_UI.md, "Janela: Minas")
##
## Lista as Minas já conquistadas — não gerencia conquista (isso é
## PvE). Por Mina: localização, Nível estrutural, estado do Ciclo,
## Guarnição, modo de Renovação. Mesmo padrão das demais janelas:
## árvore em código, sem estado próprio, reconstruída a cada ação.
##
## "Iniciar Ciclo" agora é assíncrono de verdade (MINES.md, "Cálculo
## Incremental por Amostragem") — dispara o 1º bloco em segundo plano
## e retorna na hora, nunca trava a tela. O botão mostra "calculando"
## até o 1º bloco terminar; os blocos seguintes continuam sozinhos via
## GameRuntime.sync(), sem interação nenhuma do jogador.

var _root_vbox: VBoxContainer
var _minas_container: VBoxContainer

var _selected_army_by_mina: Dictionary = {}  # mina -> Army


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

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(700, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Minas"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	_minas_container = VBoxContainer.new()
	_minas_container.add_theme_constant_override("separation", 12)
	_root_vbox.add_child(_minas_container)


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())
	var now: int = GameClock.now_unix()

	_clear_children(_minas_container)

	for mina: Mina in kingdom.all_mines():
		if not mina.conquered:
			continue

		var panel := PanelContainer.new()
		_minas_container.add_child(panel)
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)

		var location: String = "Mina Inicial" if mina.is_initial_mine() else "Fase %d (%s, Região %d)" % [mina.adjacent_fase, mina.faction, mina.region]
		var info_label := Label.new()
		info_label.text = "%s | Nível estrutural: %d" % [location, mina.structure_level]
		vbox.add_child(info_label)

		var cycle_label := Label.new()
		if mina.is_cycle_active(now):
			if mina.is_initial_mine():
				# MINES.md, "Mina Inicial (Bootstrap)": produção
				# contínua pra sempre, sem prazo — nunca "faltam Xh".
				# Eficiência sempre 100% (sem Guarnição/simulação) é
				# informação redundante — mostra a geração/hora real
				# em vez disso (FORMULAS.md, "Produção das Minas").
				var resource_name: String = MineEconomy.resource_for_faction(mina.faction)
				var production_per_hour: int = MineEconomy.base_production_for_mina(mina)
				cycle_label.text = "Produzindo continuamente | %d de %s por hora" % [production_per_hour, resource_name]
			else:
				var remaining_hours: float = (mina.cycle_started_unix + Mina.CYCLE_DURATION_SECONDS - now) / 3600.0
				if mina.cycle_efficiency < 0.0:
					cycle_label.text = "Ciclo ativo — faltam ~%.1fh | Eficiência: calculando o primeiro bloco..." % remaining_hours
				elif not MiningCycleResolver.has_high_confidence(mina):
					cycle_label.text = "Ciclo ativo — faltam ~%.1fh | Eficiência: %.1f%% (ainda se ajustando — bloco %d/%d)" % [
						remaining_hours, mina.cycle_efficiency * 100.0, mina.efficiency_blocks_completed, MiningCycleResolver.HIGH_CONFIDENCE_BLOCKS
					]
				else:
					cycle_label.text = "Ciclo ativo — faltam ~%.1fh | Eficiência: %.1f%%" % [remaining_hours, mina.cycle_efficiency * 100.0]
		else:
			cycle_label.text = "Nenhum Ciclo ativo."
		vbox.add_child(cycle_label)

		if not mina.is_initial_mine():
			var guarnicao_label := Label.new()
			if mina.guarnicao_army != null:
				var commander_name: String = mina.guarnicao_army.commander.commander_name if mina.guarnicao_army.commander != null else "sem Comandante"
				guarnicao_label.text = "Guarnição: %s (%s)" % [mina.guarnicao_army.army_name, commander_name]
			else:
				guarnicao_label.text = "Guarnição: nenhuma designada."
			vbox.add_child(guarnicao_label)

		# Renovação Automática não se aplica à Mina Inicial — ela
		# nunca expira, não existe "renovar" nada.
		if not mina.is_initial_mine():
			var renew_row := HBoxContainer.new()
			vbox.add_child(renew_row)
			var renew_check := CheckBox.new()
			renew_check.text = "Renovação Automática"
			renew_check.button_pressed = mina.auto_renew_enabled
			renew_check.toggled.connect(_on_auto_renew_toggled.bind(mina), CONNECT_DEFERRED)
			renew_row.add_child(renew_check)

		if not mina.is_cycle_active(now):
			var action_row := HBoxContainer.new()
			vbox.add_child(action_row)

			if mina.is_initial_mine():
				# MINES.md, "Mina Inicial (Bootstrap)": "Não exige
				# exército defensor ou Guarnição da Mina" — só precisa
				# ser ativada. Sem simulação de 362.880 combinações
				# (não existe Guarnição nem Formação de Referência pra
				# comparar) — sempre 100% de eficiência.
				var activate_button := Button.new()
				activate_button.text = "Ativar"
				activate_button.pressed.connect(_on_activate_initial_mine_pressed.bind(mina), CONNECT_DEFERRED)
				action_row.add_child(activate_button)
			else:
				var available_armies: Array[Army] = []
				for army: Army in kingdom.armies:
					if army.availability == Army.Availability.AVAILABLE:
						available_armies.append(army)

				var army_option := OptionButton.new()
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

	if _minas_container.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Nenhuma Mina conquistada ainda."
		_minas_container.add_child(empty_label)


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


func _on_assign_guarnicao_pressed(mina: Mina) -> void:
	var army: Army = _selected_army_by_mina.get(mina, null)
	if army == null:
		return
	var result: Dictionary = MineGuarnicaoResolver.assign(mina, army, GameClock.now_unix())
	if not result["success"]:
		print("[MinasPanel] Designar Guarnição falhou: %s" % result["reason"])
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


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
