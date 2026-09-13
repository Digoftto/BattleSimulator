class_name TestAffinityReplayPanel
extends RefCounted
## TestAffinityReplayPanel (Auditoria pré-pré-alfa — item #18, Affinity
## em tempo real na batalha)
##
## Cobre o painel de Affinity de CombatReplayView — pura representação
## do snapshot já congelado por AffinityRuntime.snapshot_turn(), nunca
## uma 2ª fórmula. Duas categorias de teste:
##
## [A] Integração real de ponta a ponta: uma batalha real (CombatEngine +
##     CombatReplayCollector reais) prova que o painel mostra valores
##     REAIS do catálogo (GameDatabase.affinity_levels via Affinity.
##     active_effects(), nunca texto inventado) e que o caso especial do
##     ATK de Mortos-Vivos Nível I não é omitido.
## [B-G] Testes diretos do painel com eventos "turn_end" forjados à mão
##     (mesmo formato exato que combat_replay_collector.gd::_on_turn_end()
##     produz) — mais rápidos, sem precisar rodar uma batalha completa
##     pra cada caso de borda (snapshot por turno, dois lados, Log,
##     ausência de dado).
##
## Mesmo padrão de test_combat_replay_view.gd: chama _apply_replay_event()/
## _update_affinity_panel() diretamente, em loop síncrono — nunca usa
## await (TestRunner.run() não suporta funções de teste assíncronas).

static func _build_combat_card(card_name_value: String, faction: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.faction = faction
	card.card_class = "Corpo a Corpo"
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card


static func _new_view() -> Control:
	var view: Control = preload("res://scenes/combat/combat_replay_view.gd").new()
	view.combat_state = CombatState.new()
	view._build_static_structure()
	return view


static func run(ctx: TestRunner.Context) -> bool:
	print("[Affinity HUD] Validando o painel de Affinity em tempo real (CombatReplayView)...")
	_test_a_real_battle_shows_real_values_and_undead_atk(ctx)
	_test_b_effects_absent_below_threshold(ctx)
	_test_c_turn_events_are_not_contaminated_by_later_turns(ctx)
	_test_d_turn_change_updates_display(ctx)
	_test_e_sides_do_not_contaminate_each_other(ctx)
	_test_f_log_toggle_does_not_break_panel(ctx)
	_test_g_missing_affinity_data_does_not_error(ctx)
	return true


static func _label_texts(container: Node) -> Array[String]:
	var texts: Array[String] = []
	for child: Node in container.get_children():
		if child is Label:
			texts.append((child as Label).text)
	return texts


## A: batalha real (2 pelotões Mortos-Vivos do lado 0, garantindo
## Afinidade I — 2 pontos) — confirma que o painel usa Affinity.
## active_effects() (dado REAL do catálogo, nunca inventado) e que o
## bônus de ATK dos Mortos-Vivos (recalculado ao vivo em
## CombatEngine._effective_attack(), nunca pré-somado num campo) NÃO é
## omitido — a descrição do catálogo aparece igual à de qualquer outro
## efeito.
static func _test_a_real_battle_shows_real_values_and_undead_atk(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.faction = "Império"  # não Mortos-Vivos: mantém a contagem em exatamente 2 pontos
	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = [
		_build_combat_card("MV-1", "Mortos-Vivos", 50, 200, 10),
		_build_combat_card("MV-2", "Mortos-Vivos", 50, 200, 10),
	]
	for i in range(7):
		cards_a.append(_build_combat_card("Imp-%d" % i, "Império", 10, 200, 10))
	army_a.cards = cards_a

	var commander_b := CommanderResource.new()
	commander_b.faction = "Natureza"
	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("Nat-%d" % i, "Natureza", 5, 100, 5))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 555)
	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)
	CombatEngine._run_turn(state)

	var turn_end_event: Dictionary = {}
	for event: Dictionary in collector.replay_events:
		if event["kind"] == "turn_end":
			turn_end_event = event
			break
	ctx.check(not turn_end_event.is_empty(), "[pré-condição] Um turno real deve produzir exatamente 1 evento 'turn_end'")
	if turn_end_event.is_empty():
		return

	var level: int = turn_end_event["affinity_levels"].get(0, {}).get("Mortos-Vivos", 0)
	print("  [A1] Nível de Afinidade Mortos-Vivos (Lado 0, 2 pontos) capturado no evento real: %d (esperado: 1)" % level)
	ctx.check(level == 1, "[A1] 2 pelotões Mortos-Vivos devem produzir Nível 1 real, capturado no evento 'turn_end'")

	var view: Control = _new_view()
	view.player_side = 0
	view._update_affinity_panel(turn_end_event)

	var player_texts: Array[String] = _label_texts(view._affinity_player_section)
	var combined: String = "\n".join(player_texts)
	print("  [A2] Painel do jogador contém 'Mortos-Vivos'? %s | contém 'ATK' (bônus de Nível I não omitido)? %s" % [
		str(combined.contains("Mortos-Vivos")), str(combined.contains("ATK"))
	])
	ctx.check(combined.contains("Mortos-Vivos"), "[A2] O painel deve mostrar a Facção real com Afinidade ativa (Mortos-Vivos), nunca omitida")
	ctx.check(combined.contains("ATK"), "[A2] O bônus de ATK dos Mortos-Vivos Nível I (recalculado ao vivo em CombatEngine, nunca pré-somado no snapshot) NÃO pode ser omitido pela UI")

	view.free()


## B: uma Facção com Pontos insuficientes (Nível 0) nunca aparece como
## bônus ativo — mostra a mensagem real de ausência, nunca uma linha
## vazia nem um efeito inventado.
static func _test_b_effects_absent_below_threshold(ctx: TestRunner.Context) -> void:
	var view: Control = _new_view()
	var event: Dictionary = {
		"kind": "turn_end", "turn": 1,
		"affinity_points": {0: {"Império": 1}, 1: {}},
		"affinity_levels": {0: {"Império": 0}, 1: {}},
		"undead_affinity_death_bonus_active": {0: false, 1: false},
	}
	view._update_affinity_panel(event)

	var player_texts: Array[String] = _label_texts(view._affinity_player_section)
	print("  [B] 1 ponto (abaixo do limiar de Nível 1) -> nenhum efeito listado, só a mensagem de ausência? %s (textos: %s)" % [
		str(not "\n".join(player_texts).contains("Império —")), str(player_texts)
	])
	ctx.check(not "\n".join(player_texts).contains("Império —"), "[B] Uma Facção com Nível 0 nunca deve aparecer como bloco de efeito ativo")
	ctx.check("\n".join(player_texts).contains("Nenhum bônus ativo"), "[B] Sem nenhuma Facção com Nível > 0, o painel deve mostrar a mensagem real de ausência, nunca uma lista vazia sem explicação")

	view.free()


## C: o evento "turn_end" de um turno ANTERIOR não pode ser contaminado
## pelo snapshot do turno SEGUINTE — prova a cópia profunda
## (duplicate(true)) em combat_replay_collector.gd::_on_turn_end().
## Mesmo cenário de test_affinity_combat.gd (_test_b_snapshot_freezes_...):
## 1 pelotão frágil (HP baixo) garante Nível 1 no Turno 1 e Nível 0 no
## Turno 2, após a morte.
static func _test_c_turn_events_are_not_contaminated_by_later_turns(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.faction = "Natureza"
	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = [_build_combat_card("Imp-Fraco", "Império", 10, 1, 0)]
	for i in range(8):
		cards_a.append(_build_combat_card("Imp-%d" % i, "Império", 10, 500, 0))
	army_a.cards = cards_a

	var commander_b := CommanderResource.new()
	commander_b.faction = "Natureza"
	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("Nat-%d" % i, "Natureza", 999, 500, 0))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 777)

	# Reduz a Formação de A a exatamente 2 pelotões Império vivos, mesma
	# técnica de test_affinity_combat.gd::_test_b_snapshot_freezes_...
	# (initialize() já rodou com os 9 originais — Nível 3 — essa redução
	# manual é o que garante Nível 1 real neste teste): "Imp-Fraco" na
	# Posição 1 (alvo do espelho de B, morre no 1º ataque) e "Imp-0" na
	# Posição 9 (fora do alcance de um inimigo inteiramente Corpo a
	# Corpo), os outros 7 marcados mortos antes de qualquer turno rodar.
	for unit: CombatUnit in state.units:
		if unit.side != 0:
			continue
		if unit.card.card_name == "Imp-Fraco":
			unit.position = 1
			# initialize() já rodou com os 9 pelotões originais (Nível 3)
			# e aplicou o bônus de Afinidade I (+25 ESC) a esta unidade
			# ANTES desta redução manual — zera aqui para que o único
			# ataque sofrido no Turno 1 atinja o HP (Escudo > 0 absorveria
			# o golpe inteiro, COMBAT_RULES.md 4.1) e efetivamente mate.
			unit.current_esc = 0
		elif unit.card.card_name == "Imp-0":
			unit.position = 9
		else:
			unit.is_alive = false

	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	CombatEngine._run_turn(state)  # Turno 1: 2 pelotões Império vivos -> Nível 1
	CombatEngine._run_turn(state)  # Turno 2: "Imp-Fraco" morto no Turno 1 -> só 1 pelotão -> Nível 0

	var turn_end_events: Array[Dictionary] = []
	for event: Dictionary in collector.replay_events:
		if event["kind"] == "turn_end":
			turn_end_events.append(event)
	ctx.check(turn_end_events.size() >= 2, "[pré-condição] 2 chamadas a _run_turn() devem produzir ao menos 2 eventos 'turn_end'")
	if turn_end_events.size() < 2:
		return

	var level_turn_1: int = turn_end_events[0]["affinity_levels"].get(0, {}).get("Império", -1)
	var level_turn_2: int = turn_end_events[1]["affinity_levels"].get(0, {}).get("Império", -1)
	print("  [C] Nível Império (Lado 0) — Turno 1: %d (esperado: 1) | Turno 2 (após morte): %d (esperado: 0) — eventos diferentes, nunca o mesmo valor final repetido" % [level_turn_1, level_turn_2])
	ctx.check(level_turn_1 == 1, "[C] O evento do Turno 1 deve preservar o Nível real DAQUELE turno (1), mesmo depois de turnos posteriores mudarem o valor")
	ctx.check(level_turn_2 == 0, "[C] O evento do Turno 2 deve refletir a queda real de Nível após a morte")
	ctx.check(level_turn_1 != level_turn_2, "[C] Os dois eventos não podem conter o mesmo Dictionary (cópia rasa) — precisam divergir de verdade")


## D: alternar entre dois eventos "turn_end" diferentes atualiza o
## conteúdo exibido — o painel nunca fica travado no 1º snapshot
## mostrado.
static func _test_d_turn_change_updates_display(ctx: TestRunner.Context) -> void:
	var view: Control = _new_view()

	var event_turn_1: Dictionary = {
		"affinity_points": {0: {"Império": 5}, 1: {}},
		"affinity_levels": {0: {"Império": 2}, 1: {}},
		"undead_affinity_death_bonus_active": {0: false, 1: false},
	}
	view._update_affinity_panel(event_turn_1)
	var texts_turn_1: String = "\n".join(_label_texts(view._affinity_player_section))

	var event_turn_2: Dictionary = {
		"affinity_points": {0: {}, 1: {}},
		"affinity_levels": {0: {}, 1: {}},
		"undead_affinity_death_bonus_active": {0: false, 1: false},
	}
	view._update_affinity_panel(event_turn_2)
	var texts_turn_2: String = "\n".join(_label_texts(view._affinity_player_section))

	print("  [D] Turno 1 mostra Império ativo (%s) | Turno 2 (sem Facção nenhuma) atualiza pra 'Nenhum bônus ativo' (%s) -> conteúdo realmente mudou? %s" % [
		str(texts_turn_1.contains("Império —")), str(texts_turn_2.contains("Nenhum bônus ativo")), str(texts_turn_1 != texts_turn_2)
	])
	ctx.check(texts_turn_1.contains("Império —"), "[D] O 1º snapshot deve mostrar a Facção ativa real")
	ctx.check(texts_turn_2.contains("Nenhum bônus ativo"), "[D] O 2º snapshot (Turno seguinte, Facção não mais ativa) deve atualizar a mensagem")
	ctx.check(texts_turn_1 != texts_turn_2, "[D] Trocar de turno deve realmente mudar o conteúdo exibido, nunca ficar travado no 1º valor")

	view.free()


## E: cada lado só mostra sua PRÓPRIA Afinidade — Império do Lado 0
## nunca aparece na seção do Inimigo (Lado 1, com Natureza ativa) e
## vice-versa. Testado também com player_side invertido para confirmar
## que o rótulo (SEU EXÉRCITO/INIMIGO) segue o lado certo, nunca fixo.
static func _test_e_sides_do_not_contaminate_each_other(ctx: TestRunner.Context) -> void:
	var event: Dictionary = {
		"affinity_points": {0: {"Império": 5}, 1: {"Natureza": 4}},
		"affinity_levels": {0: {"Império": 2}, 1: {"Natureza": 1}},
		"undead_affinity_death_bonus_active": {0: false, 1: false},
	}

	var view_a: Control = _new_view()
	view_a.player_side = 0
	view_a._update_affinity_panel(event)
	var player_texts_a: String = "\n".join(_label_texts(view_a._affinity_player_section))
	var enemy_texts_a: String = "\n".join(_label_texts(view_a._affinity_enemy_section))
	print("  [E1] player_side=0 -> Seção do jogador só tem Império (%s) e nunca Natureza (%s) | Seção inimiga só tem Natureza (%s) e nunca Império (%s)" % [
		str(player_texts_a.contains("Império —")), str(not player_texts_a.contains("Natureza —")),
		str(enemy_texts_a.contains("Natureza —")), str(not enemy_texts_a.contains("Império —"))
	])
	ctx.check(player_texts_a.contains("Império —") and not player_texts_a.contains("Natureza —"), "[E1] A seção do jogador (Lado 0) não pode conter a Afinidade do Lado 1")
	ctx.check(enemy_texts_a.contains("Natureza —") and not enemy_texts_a.contains("Império —"), "[E1] A seção do inimigo (Lado 1) não pode conter a Afinidade do Lado 0")
	view_a.free()

	var view_b: Control = _new_view()
	view_b.player_side = 1  # inverte: agora o jogador é o Lado 1 (Natureza)
	view_b._update_affinity_panel(event)
	var player_texts_b: String = "\n".join(_label_texts(view_b._affinity_player_section))
	print("  [E2] player_side=1 -> Seção do jogador agora mostra Natureza (a Afinidade do Lado 1)? %s" % str(player_texts_b.contains("Natureza —")))
	ctx.check(player_texts_b.contains("Natureza —"), "[E2] Com player_side invertido, a seção 'SEU EXÉRCITO' deve seguir o Lado real do jogador, nunca ficar fixa no Lado 0")
	view_b.free()


## F: abrir/fechar o Log não quebra o painel — ele apenas some/reaparece
## (solução mais simples pedida), sem perder o conteúdo já mostrado.
static func _test_f_log_toggle_does_not_break_panel(ctx: TestRunner.Context) -> void:
	var view: Control = _new_view()
	var event: Dictionary = {
		"affinity_points": {0: {"Império": 5}, 1: {}},
		"affinity_levels": {0: {"Império": 2}, 1: {}},
		"undead_affinity_death_bonus_active": {0: false, 1: false},
	}
	view._update_affinity_panel(event)

	var panel: Control = view._affinity_panel
	print("  [F1] Painel visível depois do 1º snapshot? %s (esperado: true)" % str(panel.visible))
	ctx.check(panel.visible, "[F1] Com dado real disponível e Log fechado, o painel deve estar visível")

	view._on_log_toggle_pressed()
	print("  [F2] Log aberto -> painel de Affinity escondido? %s (esperado: true)" % str(not panel.visible))
	ctx.check(not panel.visible, "[F2] Abrir o Log deve esconder o painel de Affinity (nunca sobrepor permanentemente)")

	view._on_log_toggle_pressed()
	var texts_after_reopen: String = "\n".join(_label_texts(view._affinity_player_section))
	print("  [F3] Log fechado de novo -> painel reaparece (%s) com o MESMO conteúdo (%s)?" % [str(panel.visible), str(texts_after_reopen.contains("Império —"))])
	ctx.check(panel.visible, "[F3] Fechar o Log deve mostrar o painel de novo (já havia dado real)")
	ctx.check(texts_after_reopen.contains("Império —"), "[F3] O conteúdo não pode ser perdido ao esconder/reaparecer o painel")

	view.free()


## G: ausência de dado de Affinity no evento (replay sem essa
## informação, ou painel nunca atualizado) nunca gera erro nem inventa
## um valor — degrada para a mensagem real de ausência.
static func _test_g_missing_affinity_data_does_not_error(ctx: TestRunner.Context) -> void:
	var view: Control = _new_view()
	view._update_affinity_panel({"kind": "turn_end", "turn": 1})  # sem nenhum campo de Affinity

	var player_texts: String = "\n".join(_label_texts(view._affinity_player_section))
	var enemy_texts: String = "\n".join(_label_texts(view._affinity_enemy_section))
	print("  [G] Evento 'turn_end' sem dado de Affinity -> nenhum erro, ambas as seções mostram a mensagem real de ausência? %s, %s" % [
		str(player_texts.contains("Nenhum bônus ativo")), str(enemy_texts.contains("Nenhum bônus ativo"))
	])
	ctx.check(player_texts.contains("Nenhum bônus ativo"), "[G] Sem dado de Affinity no evento, a seção do jogador deve degradar para a mensagem real de ausência, nunca inventar um valor")
	ctx.check(enemy_texts.contains("Nenhum bônus ativo"), "[G] Mesma regra para a seção do inimigo")

	view.free()
