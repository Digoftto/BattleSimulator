class_name TestBattleReplayPersistence
extends RefCounted
## TestBattleReplayPersistence (Auditoria pré-pré-alfa — item #17,
## Replay persistido de Fases PvE, vitória e derrota)
##
## Cobre o pipeline completo: ExpeditionRuntime._record_fase_history()
## grava um replay real (BattleReplayRecord) para TODA tentativa
## (vitória OU derrota, nunca filtrado), Kingdom.battle_replays
## armazena por replay_id com expurgo por limite, KingdomSaveService
## persiste/restaura tudo, e BattleReplayRecord.from_persisted_dict()
## reconstrói um par {state, collector} que CombatReplayView consome
## sem re-simular nada — mesmo padrão de acesso direto usado em
## test_combat_replay_view.gd (_apply_replay_event() em loop síncrono,
## nunca await).

## preload() por caminho, nunca o identificador global "BattleReplayRecord"
## direto — mesmo motivo já documentado em expedition_runtime.gd: um
## class_name novo só entra no cache global de classes quando o Editor
## do Godot escaneia o projeto, o que nunca acontece numa execução
## --headless.
const BattleReplayRecordScript = preload("res://engine/combat/battle_replay_record.gd")


static func _build_test_expedition(army: Army) -> ExpeditionRuntime:
	var territory := Territory.new("Territorio-Replay-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()
	return ExpeditionRuntime.new(
		Squad.new([army]), trilha, territory, catalog, registry, 4321,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)


static func run(ctx: TestRunner.Context) -> bool:
	print("[Replay] Validando persistência de replay de Fases PvE (vitória e derrota)...")
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_test_a_victory_generates_persistable_replay(ctx)
	_test_b_defeat_generates_persistable_replay(ctx)
	_test_c_saved_replay_survives_reload_and_feeds_view(ctx)
	_test_d_two_battles_same_fase_have_distinct_ids_and_do_not_overwrite(ctx)
	_test_e_old_save_without_replays_still_loads(ctx)
	_test_f_storage_cap_evicts_oldest(ctx)
	_test_g_replays_do_not_contaminate_each_other(ctx)
	return true


## A: vitória grava fase_history["replay_id"] apontando para um
## Dictionary real e completo em kingdom.battle_replays.
static func _test_a_victory_generates_persistable_replay(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	KingdomState.kingdom = kingdom

	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var expedition: ExpeditionRuntime = _build_test_expedition(winning_army)

	var result: PhaseResult = expedition.attempt_current_fase()
	print("  [A1] Vitória real? %s | fase_history tem replay_id? %s" % [str(result.victory), str(expedition.fase_history[1].has("replay_id"))])
	ctx.check(result.victory, "[pré-condição A] Este cenário deve resultar em vitória")
	ctx.check(expedition.fase_history[1].has("replay_id"), "[A1] Uma Fase vencida deve gravar 'replay_id' em fase_history")

	var replay_id: String = expedition.fase_history[1]["replay_id"]
	ctx.check(kingdom.battle_replays.has(replay_id), "[A1] O replay_id gravado deve existir de verdade em kingdom.battle_replays")
	var record: Dictionary = kingdom.battle_replays[replay_id]
	print("  [A2] Record: victory=%s | fase=%d | turn=%d | eventos=%d | initial_board=%d" % [
		str(record["victory"]), record["fase"], record["turn"], record["replay_events"].size(), record["initial_board"].size()
	])
	ctx.check(record["victory"] == true, "[A2] O record persistido deve marcar victory=true para uma Fase vencida")
	ctx.check(record["fase"] == 1, "[A2] O record deve identificar a Fase real (1)")
	ctx.check(not record["replay_events"].is_empty(), "[A2] O record deve conter os eventos reais da batalha, nunca vazio")
	ctx.check(record["initial_board"].size() == 18, "[A2] O record deve conter o tabuleiro inicial completo (9+9)")
	ctx.check(not record["initial_board"][0].has("card"), "[A2] initial_board persistido NUNCA deve carregar a referência viva de CardResource ('card') — só card_name")


## B: derrota grava replay igualmente — "não filtrar por victory == true".
static func _test_b_defeat_generates_persistable_replay(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	KingdomState.kingdom = kingdom

	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({})  # Campeão na Posição 9 -> perde/empata (ver auditoria do Acampamento)
	losing_army.initialize_energy(1)
	var expedition: ExpeditionRuntime = _build_test_expedition(losing_army)

	var result: PhaseResult = expedition.attempt_current_fase()
	print("  [B1] Derrota real? %s | fase_history tem replay_id? %s" % [str(not result.victory), str(expedition.fase_history[1].has("replay_id"))])
	ctx.check(not result.victory, "[pré-condição B] Este cenário deve resultar em derrota")
	ctx.check(expedition.fase_history[1].has("replay_id"), "[B1] Uma Fase PERDIDA também deve gravar 'replay_id' — replay nunca é filtrado por vitória")

	var replay_id: String = expedition.fase_history[1]["replay_id"]
	var record: Dictionary = kingdom.battle_replays[replay_id]
	print("  [B2] Record: victory=%s | winner_side=%d" % [str(record["victory"]), record["winner_side"]])
	ctx.check(record["victory"] == false, "[B2] O record persistido deve marcar victory=false para uma Fase perdida")
	ctx.check(expedition.fase_history[1]["victory"] == false, "[B2] O RESULTADO (fase_history.victory) e o REPLAY são dados distintos, mas ambos devem concordar: derrota continua derrota no histórico")


## C: round-trip real de save/load (KingdomSaveService) — o replay
## sobrevive, e o Dictionary reconstruído alimenta CombatReplayView sem
## nenhuma re-simulação (_apply_replay_event() reproduz os MESMOS
## eventos gravados, nunca um resultado recalculado).
static func _test_c_saved_replay_survives_reload_and_feeds_view(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var kingdom := Kingdom.new()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	kingdom.armies.append(winning_army)
	var expedition: ExpeditionRuntime = _build_test_expedition(winning_army)
	KingdomState.kingdom = kingdom

	var result: PhaseResult = expedition.attempt_current_fase()
	ctx.check(result.victory, "[pré-condição C] Este cenário deve resultar em vitória")
	var replay_id: String = expedition.fase_history[1]["replay_id"]
	var original_event_count: int = kingdom.battle_replays[replay_id]["replay_events"].size()
	var original_turn: int = kingdom.battle_replays[replay_id]["turn"]

	KingdomSaveService.save(kingdom)

	var loaded_kingdom := Kingdom.new()
	var load_ok: bool = KingdomSaveService.load_into(loaded_kingdom)
	ctx.check(load_ok, "[C1] load_into() deve retornar sucesso para um save recém-gravado")
	print("  [C1] Após reload -> battle_replays tem o replay_id salvo? %s" % str(loaded_kingdom.battle_replays.has(replay_id)))
	ctx.check(loaded_kingdom.battle_replays.has(replay_id), "[C1] O replay_id salvo deve sobreviver ao round-trip real de save/load")

	var loaded_record: Dictionary = loaded_kingdom.battle_replays[replay_id]
	print("  [C2] Eventos: antes=%d, depois=%d | Turno: antes=%d, depois=%d" % [
		original_event_count, loaded_record["replay_events"].size(), original_turn, loaded_record["turn"]
	])
	ctx.check(loaded_record["replay_events"].size() == original_event_count, "[C2] O número de eventos gravados deve ser IDÊNTICO após o reload (nunca re-simulado)")
	ctx.check(loaded_record["turn"] == original_turn, "[C2] O Turno final deve ser idêntico após o reload")

	# D: o Dictionary reconstruído alimenta CombatReplayView de verdade.
	var reconstructed: Dictionary = BattleReplayRecordScript.from_persisted_dict(loaded_record)
	var view: Control = preload("res://scenes/combat/combat_replay_view.gd").new()
	view.combat_state = reconstructed["state"]
	view.replay_collector = reconstructed["collector"]
	view.player_side = reconstructed["player_side"]
	view._build_static_structure()
	view._apply_initial_board()

	for event: Dictionary in reconstructed["collector"].replay_events:
		view._apply_replay_event(event)

	var alive_count: int = 0
	for key: int in view._live_board.keys():
		if view._live_board[key]["alive"]:
			alive_count += 1
	print("  [D1] CombatReplayView reconstruído a partir do save processou todos os eventos sem erro? true | unidades vivas ao final: %d" % alive_count)
	ctx.check(alive_count > 0, "[D1] O replay reconstruído deve reproduzir um tabuleiro final coerente (ao menos 1 unidade viva, mesma regra de test_combat_replay_view.gd)")

	view._show_result()
	print("  [D2] Banner de Resultado aparece a partir do replay reconstruído (vitória real)? %s (texto: '%s')" % [str(view._result_label.visible), view._result_label.text])
	ctx.check(view._result_label.visible, "[D2] O banner de Resultado deve funcionar normalmente a partir de um replay reconstruído do save")

	view.free()
	KingdomSaveService.delete_save()


## E/H/O: duas tentativas na MESMA Fase (derrota, depois vitória) geram
## replay_ids DISTINTOS, e o replay da tentativa ANTERIOR (a derrota)
## continua acessível em kingdom.battle_replays mesmo depois que
## fase_history[fase] for sobrescrito pela tentativa seguinte — repetir
## uma Fase nunca apaga silenciosamente o replay anterior.
static func _test_d_two_battles_same_fase_have_distinct_ids_and_do_not_overwrite(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	KingdomState.kingdom = kingdom

	# 1ª tentativa: perde (Campeão na Posição 9).
	var army: Army = CampaignTestFixtures.build_campaign_test_army({})
	army.initialize_energy(1)
	var expedition: ExpeditionRuntime = _build_test_expedition(army)
	var first_result: PhaseResult = expedition.attempt_current_fase()
	ctx.check(not first_result.victory, "[pré-condição D] A 1ª tentativa deve perder")
	var first_replay_id: String = expedition.fase_history[1]["replay_id"]

	# expedition.attempt_current_fase() já recolocou current_fase = last_acampamento_fase
	# (1, sem Acampamento real ainda) e a Expedição ficou aguardando —
	# libera manualmente pra simular o jogador reordenando a Formação e
	# tentando de novo (mesma Fase 1).
	expedition.is_waiting_at_acampamento = false
	army.cards = CampaignTestFixtures.build_champion_formation(1)  # agora vence

	var second_result: PhaseResult = expedition.attempt_current_fase()
	ctx.check(second_result.victory, "[pré-condição D] A 2ª tentativa (mesma Fase 1) deve vencer")
	var second_replay_id: String = expedition.fase_history[1]["replay_id"]

	print("  [E/H] 1ª tentativa replay_id='%s' | 2ª tentativa replay_id='%s' -> distintos? %s" % [
		first_replay_id, second_replay_id, str(first_replay_id != second_replay_id)
	])
	ctx.check(first_replay_id != second_replay_id, "[H] Duas batalhas da mesma Fase devem ter replay_id distintos")

	print("  [O] fase_history[1] aponta pro replay da 2ª tentativa (%s)? %s | replay da 1ª tentativa (%s) continua acessível em battle_replays? %s" % [
		second_replay_id, str(expedition.fase_history[1]["replay_id"] == second_replay_id),
		first_replay_id, str(kingdom.battle_replays.has(first_replay_id))
	])
	ctx.check(expedition.fase_history[1]["replay_id"] == second_replay_id, "[O] fase_history (resumo/histórico) reflete a tentativa mais recente, comportamento já existente e inalterado")
	ctx.check(kingdom.battle_replays.has(first_replay_id), "[O] Repetir uma Fase NUNCA pode apagar silenciosamente o replay de uma tentativa anterior ainda dentro do limite de armazenamento")
	ctx.check(kingdom.battle_replays[first_replay_id]["victory"] == false, "[O] O replay antigo (1ª tentativa) deve continuar íntegro — ainda mostrando a derrota real que aconteceu")


## I: um save gravado ANTES desta funcionalidade existir (sem
## "battle_replays"/"battle_replay_order"/"next_replay_id_counter")
## continua carregando normalmente — escrito no MESMO arquivo/caminho
## real (user://kingdom_save.json) e lido via KingdomSaveService.load_into(),
## nunca reimplementando a leitura do save.
static func _test_e_old_save_without_replays_still_loads(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var old_data: Dictionary = {
		"energy_nucleus_level": 1,
		"next_card_instance_id": 1,
		"next_commander_instance_id": 1,
	}  # deliberadamente incompleto — só o suficiente pra exercitar os 3 campos novos com .get() default
	var file: FileAccess = FileAccess.open(KingdomSaveService.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_data, "\t"))
	file.close()

	var kingdom := Kingdom.new()
	var load_ok: bool = KingdomSaveService.load_into(kingdom)
	print("  [I] load_into() de um save antigo (sem replay) retornou sucesso? %s" % str(load_ok))
	ctx.check(load_ok, "[I] Um save antigo (formato anterior a esta funcionalidade) deve continuar carregando com sucesso")

	print("  [I] Save antigo sem replay -> battle_replays == {}? %s | battle_replay_order == []? %s | next_replay_id_counter == 1? %s" % [
		str(kingdom.battle_replays.is_empty()), str(kingdom.battle_replay_order.is_empty()), str(kingdom.next_replay_id_counter == 1)
	])
	ctx.check(kingdom.battle_replays.is_empty(), "[I] Um save antigo sem 'battle_replays' deve carregar com o Dictionary vazio, nunca um erro")
	ctx.check(kingdom.battle_replay_order.is_empty(), "[I] Idem para 'battle_replay_order'")
	ctx.check(kingdom.next_replay_id_counter == 1, "[I] 'next_replay_id_counter' deve default para 1 (o valor inicial real)")

	KingdomSaveService.delete_save()


## F/M: o limite de armazenamento expurga o replay MAIS ANTIGO ao
## exceder MAX_STORED_BATTLE_REPLAYS.
static func _test_f_storage_cap_evicts_oldest(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var cap: int = Kingdom.MAX_STORED_BATTLE_REPLAYS

	var first_id: String = ""
	for i in range(cap + 5):
		var replay_id: String = kingdom.generate_replay_id()
		if i == 0:
			first_id = replay_id
		kingdom.record_battle_replay({"replay_id": replay_id, "victory": true})

	print("  [F/M] Após registrar %d replays (limite=%d) -> tamanho final: %d (esperado: %d) | o 1º replay ('%s') foi expurgado? %s" % [
		cap + 5, cap, kingdom.battle_replays.size(), cap, first_id, str(not kingdom.battle_replays.has(first_id))
	])
	ctx.check(kingdom.battle_replays.size() == cap, "[M] O número de replays armazenados nunca deve ultrapassar MAX_STORED_BATTLE_REPLAYS (obtido: %d, esperado: %d)" % [kingdom.battle_replays.size(), cap])
	ctx.check(not kingdom.battle_replays.has(first_id), "[F] O replay MAIS ANTIGO deve ser o primeiro a ser expurgado (ordem determinística, nunca aleatória)")
	ctx.check(kingdom.battle_replay_order.size() == cap, "[M] battle_replay_order deve acompanhar exatamente o mesmo tamanho de battle_replays")


## G: dois replays reais e distintos não compartilham/contaminam dados
## um do outro (cada Dictionary é uma cópia independente).
static func _test_g_replays_do_not_contaminate_each_other(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	KingdomState.kingdom = kingdom

	var army_1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_1.initialize_energy(1)
	var expedition_1: ExpeditionRuntime = _build_test_expedition(army_1)
	expedition_1.attempt_current_fase()
	var replay_id_1: String = expedition_1.fase_history[1]["replay_id"]

	var army_2: Army = CampaignTestFixtures.build_campaign_test_army({"β": 1})
	army_2.initialize_energy(1)
	var expedition_2: ExpeditionRuntime = _build_test_expedition(army_2)
	expedition_2.attempt_current_fase()
	var replay_id_2: String = expedition_2.fase_history[1]["replay_id"]

	print("  [G] 2 replays reais e distintos ('%s', '%s') -> IDs diferentes? %s | eventos não são o mesmo Array (identidade)? %s" % [
		replay_id_1, replay_id_2, str(replay_id_1 != replay_id_2),
		str(kingdom.battle_replays[replay_id_1]["replay_events"] != kingdom.battle_replays[replay_id_2]["replay_events"])
	])
	ctx.check(replay_id_1 != replay_id_2, "[G] Duas Expedições/batalhas reais e distintas nunca podem colidir em replay_id")
	kingdom.battle_replays[replay_id_1]["turn"] = 999  # muta uma cópia
	ctx.check(kingdom.battle_replays[replay_id_2]["turn"] != 999, "[G] Mutar o record de um replay não pode vazar para o outro (cópias independentes, nunca a mesma referência)")
