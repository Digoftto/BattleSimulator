class_name TestPvpBattle
extends RefCounted
## TestPvpBattle (F-021.6)
##
## PvP deixou de injetar Vitória/Derrota/Empate direto no
## RankingResolver via 3 botões artificiais — agora usa combate real
## (CombatEngine, game_mode="pvp"). Mesmo padrão de
## test_campo_de_prova_lifecycle_and_editing.gd: a fase de replay
## (CombatReplayView, assíncrona, depende de frames reais da SceneTree)
## nunca é exercitada aqui — testamos _resolve_pvp_combat() (núcleo
## síncrono e determinístico, extraído de _run_pvp_battle() exatamente
## para ser testável) e os aplicadores de Ranking nomeados
## (_apply_bronze_ranking_result()/_apply_plano_ranking_result()),
## nunca a UI de replay em si (já coberta por
## test_combat_replay_view.gd/test_replay_visual_identity.gd).

const PvPPanelScript = preload("res://scenes/command_center/panels/pvp_panel.gd")


static func _build_attacker_army() -> Army:
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	army.army_name = "Exército Teste PvP"
	army.initialize_energy(1)
	return army


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021.6] Validando PvP com combate real (CombatEngine, game_mode='pvp')...")
	_test_a_combate_real(ctx)
	_test_b_game_mode(ctx)
	_test_c_defensor_valido(ctx)
	_test_d_formacao_do_defensor(ctx)
	_test_e_resultado_deriva_do_combate(ctx)
	_test_f_ranking_bronze_e_plano(ctx)
	_test_g_replay_collector_real(ctx)
	_test_h_sem_resultado_artificial(ctx)
	return true


## A: _resolve_pvp_combat() executa uma batalha real de verdade (não um
## resultado fabricado) — turnos > 0, is_finished == true, Energia real
## consumida exatamente no custo documentado (ENERGY.md, PvP).
static func _test_a_combate_real(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var energy_before: int = attacker.current_energy

	var combat: Dictionary = panel._resolve_pvp_combat(attacker, GameDatabase.battlefields)

	print("  [A] Combate real produzido (não vazio)? %s | turnos > 0? %s | finalizado? %s" % [
		str(not combat.is_empty()), str(combat.get("state", null) != null and combat["state"].turn > 0), str(combat.get("state", null) != null and combat["state"].is_finished)
	])
	ctx.check(not combat.is_empty(), "[A] _resolve_pvp_combat deve produzir um resultado real")
	var state: CombatState = combat["state"]
	ctx.check(state.turn > 0, "[A] Uma batalha real de CombatEngine sempre avança pelo menos 1 turno")
	ctx.check(state.is_finished, "[A] CombatEngine.run() deve deixar a batalha concluída")
	ctx.check(attacker.current_energy == energy_before - PlanoCampanhaResolver.ATTACK_ENERGY_COST, "[A] A Energia real do atacante deve ser consumida exatamente no custo fixo documentado (ENERGY.md, PvP)")
	panel.free()


## B: game_mode == "pvp" — NUNCA "pve" (achado da auditoria F-021.2:
## Doutrina do Comandante pode ter regras específicas de PvP).
static func _test_b_game_mode(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var combat: Dictionary = panel._resolve_pvp_combat(attacker, GameDatabase.battlefields)

	print("  [B] game_mode do combate real == 'pvp'? %s (obtido: '%s')" % [str(combat["state"].game_mode == "pvp"), combat["state"].game_mode])
	ctx.check(combat["state"].game_mode == "pvp", "[B] O combate de PvP deve usar game_mode='pvp', nunca 'pve'")
	panel.free()


## C: o defensor IA é um Exército real e completo — Comandante real,
## pronto para batalha (Army.is_ready_for_battle()).
static func _test_c_defensor_valido(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var defender: Army = panel._generate_ai_defender(attacker)

	print("  [C] Defensor IA pronto para batalha? %s | tem Comandante real? %s" % [
		str(defender.is_ready_for_battle()), str(defender.commander != null and defender.commander.commander_name != "")
	])
	ctx.check(defender.is_ready_for_battle(), "[C] O defensor IA deve ser um Exército completo e válido (Army.is_ready_for_battle())")
	ctx.check(defender.commander != null and defender.commander.commander_name != "", "[C] O defensor IA deve ter um Comandante real (procedural, mas real — nunca null/vazio)")
	panel.free()


## D: a Formação do defensor tem 9 posições reais do catálogo — nenhum
## placeholder, nenhuma carta repetida (ARMY.md, "Unicidade de Composição").
static func _test_d_formacao_do_defensor(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var defender: Army = panel._generate_ai_defender(attacker)

	var names: Array[String] = []
	var all_real: bool = true
	for card: CardResource in defender.cards:
		if card == null or card.card_name == "":
			all_real = false
		else:
			names.append(card.card_name)

	var unique_names: Dictionary = {}
	for card_name: String in names:
		unique_names[card_name] = true

	print("  [D] Defensor tem 9 posições? %s | todas reais (nenhum placeholder)? %s | nomes distintos (%d únicos de %d)? %s" % [
		str(defender.cards.size() == 9), str(all_real), unique_names.size(), names.size(), str(unique_names.size() == names.size())
	])
	ctx.check(defender.cards.size() == 9, "[D] A Formação do defensor deve ter exatamente 9 posições")
	ctx.check(all_real, "[D] Nenhuma posição do defensor pode ser um placeholder/carta vazia")
	ctx.check(unique_names.size() == names.size(), "[D] A Formação do defensor não pode ter cartas com o mesmo Nome repetido (ARMY.md)")
	panel.free()


## E: o resultado usado pelo Ranking deriva exatamente de
## state.winner_side — nunca escolhido/inventado pela UI.
static func _test_e_resultado_deriva_do_combate(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var combat: Dictionary = panel._resolve_pvp_combat(attacker, GameDatabase.battlefields)

	var expected_result: RankingResolver.Result
	if combat["state"].winner_side == 0:
		expected_result = RankingResolver.Result.VITORIA
	elif combat["state"].winner_side == 1:
		expected_result = RankingResolver.Result.DERROTA
	else:
		expected_result = RankingResolver.Result.EMPATE

	print("  [E] winner_side (%d) -> resultado real usado (%d) bate com o esperado (%d)? %s" % [
		combat["state"].winner_side, combat["result"], expected_result, str(combat["result"] == expected_result)
	])
	ctx.check(combat["result"] == expected_result, "[E] O resultado usado pelo Ranking deve derivar exatamente de state.winner_side")
	panel.free()


## F: os aplicadores de Ranking (Bronze e Plano) usam exatamente
## RankingResolver.apply_result() — nenhum cálculo duplicado.
static func _test_f_ranking_bronze_e_plano(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Teste Ranking"
	commander.bronze_divisao = RankingResolver.initial_division()
	commander.bronze_pl = 0
	var expected_bronze: Dictionary = RankingResolver.apply_result(0, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.VITORIA)
	var returned_bronze: Dictionary = panel._apply_bronze_ranking_result(RankingResolver.Result.VITORIA, commander)
	print("  [F] Bronze: PL real (%d) e Divisão real ('%s') batem com RankingResolver.apply_result()? %s, %s" % [
		commander.bronze_pl, commander.bronze_divisao, str(commander.bronze_pl == expected_bronze["pl"]), str(commander.bronze_divisao == expected_bronze["division"])
	])
	ctx.check(commander.bronze_pl == expected_bronze["pl"], "[F] _apply_bronze_ranking_result deve produzir exatamente o PL de RankingResolver.apply_result()")
	ctx.check(commander.bronze_divisao == expected_bronze["division"], "[F] _apply_bronze_ranking_result deve produzir exatamente a Divisão de RankingResolver.apply_result()")
	# F-021.7: o retorno usado pelo relatório de "impacto no Ranking" tem
	# que refletir exatamente o antes/depois real, nunca um valor à parte.
	ctx.check(returned_bronze["pl_before"] == 0 and returned_bronze["pl_after"] == expected_bronze["pl"], "[F] O retorno de _apply_bronze_ranking_result deve trazer o PL antes/depois reais (para o relatório de impacto no Ranking)")

	var plano := PlanoCampanha.new([_build_attacker_army()])
	plano.liga = "Prata"
	plano.divisao = RankingResolver.initial_division()
	plano.pl = 0
	var expected_plano: Dictionary = RankingResolver.apply_result(0, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	var returned_plano: Dictionary = panel._apply_plano_ranking_result(RankingResolver.Result.DERROTA, plano)
	print("  [F] Plano: PL real (%d) e Divisão real ('%s') batem com RankingResolver.apply_result()? %s, %s" % [
		plano.pl, plano.divisao, str(plano.pl == expected_plano["pl"]), str(plano.divisao == expected_plano["division"])
	])
	ctx.check(plano.pl == expected_plano["pl"], "[F] _apply_plano_ranking_result deve produzir exatamente o PL de RankingResolver.apply_result()")
	ctx.check(plano.divisao == expected_plano["division"], "[F] _apply_plano_ranking_result deve produzir exatamente a Divisão de RankingResolver.apply_result()")
	ctx.check(returned_plano["pl_before"] == 0 and returned_plano["pl_after"] == expected_plano["pl"], "[F] O retorno de _apply_plano_ranking_result deve trazer o PL antes/depois reais")
	panel.free()


## G: o CombatReplayCollector real anexado ao combate registrou dados
## reais (tabuleiro inicial + eventos) — pronto para alimentar
## CombatReplayView sem nenhuma segunda implementação de replay.
static func _test_g_replay_collector_real(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var attacker: Army = _build_attacker_army()
	var combat: Dictionary = panel._resolve_pvp_combat(attacker, GameDatabase.battlefields)
	var collector = combat["replay_collector"]

	print("  [G] Replay real: tabuleiro inicial capturado (%d entradas)? %s | eventos registrados (%d)? %s" % [
		collector.initial_board.size(), str(collector.initial_board.size() > 0), collector.replay_events.size(), str(collector.replay_events.size() > 0)
	])
	ctx.check(collector.initial_board.size() > 0, "[G] O CombatReplayCollector deve capturar o tabuleiro inicial real (18 unidades — 9 por lado)")
	ctx.check(collector.replay_events.size() > 0, "[G] O CombatReplayCollector deve registrar eventos reais do combate (nunca vazio numa batalha com >=1 turno)")
	panel.free()


## H: os antigos botões artificiais de resultado não existem mais no
## painel — não é possível produzir um resultado de Ranking sem passar
## por um combate real.
static func _test_h_sem_resultado_artificial(ctx: TestRunner.Context) -> void:
	var panel = PvPPanelScript.new()
	var has_old_bronze_handler: bool = panel.has_method("_on_simulate_bronze_result_pressed")
	var has_old_plano_handler: bool = panel.has_method("_on_simulate_plano_result_pressed")
	print("  [H] Handlers antigos de resultado artificial removidos? Bronze: %s | Plano: %s" % [str(not has_old_bronze_handler), str(not has_old_plano_handler)])
	ctx.check(not has_old_bronze_handler, "[H] _on_simulate_bronze_result_pressed (resultado artificial) não deve mais existir")
	ctx.check(not has_old_plano_handler, "[H] _on_simulate_plano_result_pressed (resultado artificial) não deve mais existir")
	panel.free()
