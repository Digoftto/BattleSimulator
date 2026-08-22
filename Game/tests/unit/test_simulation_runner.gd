class_name TestSimulationRunner
extends RefCounted
## TestSimulationRunner (F-029)
##
## Valida a camada de simulação em massa construída sobre a fundação
## determinística do F-028: SimulationConfig, os 3 construtores de
## "army_pairs" (Fixed vs Fixed / Fixed vs Random / Random vs Random),
## BattleSimulationRunner.run_series(), e SimulationReport.
##
## Testes A/B (100/1.000 batalhas): reprodução determinística de uma
## série inteira, Fixed vs Fixed (a modalidade mais rápida de resolver,
## Campeão na Posição 1 — ver CampaignTestFixtures — evita o pior caso
## de 64 turnos por batalha, que tornaria 1.000 batalhas × 2 execuções
## lento demais para um teste de regressão).
## Teste C: Fixed vs Fixed. Teste D: Fixed vs Random. Teste E: Random
## vs Random — cada um confirma que a modalidade produz pares de
## Exército válidos e um SimulationReport coerente.
## Teste F: mesma seed -> mesmo SimulationReport (dobra a checagem do
## Teste A no nível do relatório agregado, não só da lista de
## resultados brutos).
## Teste G: seeds diferentes -> RNG efetivamente diferente (na geração
## de Exército, mesmo padrão do F-028 Teste B).
## Teste H: coletar eventos não altera o resultado da batalha.
## Teste I (multithread) NÃO existe — BattleSimulationRunner não
## implementa multithreading nesta etapa (F-029 §21, ver relatório
## final: contador estático CombatState._battle_id_counter não é
## thread-safe sem lock, risco real de battle_id duplicado/corrompido
## sob WorkerThreadPool sem tocar em combat_state.gd de novo).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-029] Validando BattleSimulationRunner/SimulationReport (Config, 3 modalidades, determinismo, insights)...")

	_test_a_100_battles_reproducible(ctx)
	_test_b_1000_battles_reproducible(ctx)
	_test_c_fixed_vs_fixed(ctx)
	_test_d_fixed_vs_random(ctx)
	_test_e_random_vs_random(ctx)
	_test_f_same_seed_same_report(ctx)
	_test_g_different_seeds_differ(ctx)
	_test_h_event_collection_does_not_alter_result(ctx)
	_test_insights_respect_minimum_sample_size(ctx)

	return true


## Formação do Campeão na Posição 1 -> vence rápido (poucos turnos,
## comentário original de CampaignTestFixtures.build_champion_formation()),
## evitando o pior caso de 64 turnos/batalha em séries de centenas/
## milhares de batalhas.
static func _fast_army_a() -> Army:
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (F-029)"
	commander.faction = "Império"
	var army := Army.new()
	army.commander = commander
	army.cards = CampaignTestFixtures.build_champion_formation(1)
	return army


static func _fast_army_b() -> Army:
	return CampaignTestFixtures.build_campaign_enemy_army()


static func _run_fixed_series(count: int, base_seed_value: int, collect_events: bool = false) -> Array[BattleResult]:
	var config := SimulationConfig.new()
	config.simulation_count = count
	config.base_seed_value = base_seed_value
	config.collect_events = collect_events

	var pairs: Array = BattleSimulationRunner.build_fixed_vs_fixed_pairs(_fast_army_a(), _fast_army_b(), count)
	return BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)


static func _results_signature(results: Array[BattleResult]) -> Array:
	var signature: Array = []
	for r: BattleResult in results:
		signature.append([r.winner_side, r.end_reason, r.turn_count, r.battlefield_name])
	return signature


static func _test_a_100_battles_reproducible(ctx: TestRunner.Context) -> void:
	var results1: Array[BattleResult] = _run_fixed_series(100, 5000)
	var results2: Array[BattleResult] = _run_fixed_series(100, 5000)

	var same_count: bool = results1.size() == 100 and results2.size() == 100
	var same_signature: bool = _results_signature(results1) == _results_signature(results2)
	var all_ids_unique: bool = _all_battle_ids_unique(results1) and _all_battle_ids_unique(results2)

	print("  [A] 100 batalhas (Fixed vs Fixed, base_seed=5000) reproduzidas duas vezes -> mesma contagem: %s | mesma sequência (vencedor/motivo/turnos/campo): %s | battle_ids únicos: %s (esperado: true em todos)" % [
		str(same_count), str(same_signature), str(all_ids_unique)
	])
	ctx.check(same_count, "[A] Duas execuções devem produzir exatamente 100 resultados cada")
	ctx.check(same_signature, "[A] Mesma seed-base deve reproduzir a mesma sequência de 100 resultados")
	ctx.check(all_ids_unique, "[A] Todo battle_id dentro de uma série de 100 batalhas deve ser único")


static func _test_b_1000_battles_reproducible(ctx: TestRunner.Context) -> void:
	var results1: Array[BattleResult] = _run_fixed_series(1000, 7000)
	var results2: Array[BattleResult] = _run_fixed_series(1000, 7000)

	var same_count: bool = results1.size() == 1000 and results2.size() == 1000
	var same_signature: bool = _results_signature(results1) == _results_signature(results2)

	print("  [B] 1.000 batalhas (Fixed vs Fixed, base_seed=7000) reproduzidas duas vezes -> mesma contagem: %s | mesma sequência: %s (esperado: true, true)" % [
		str(same_count), str(same_signature)
	])
	ctx.check(same_count, "[B] Duas execuções devem produzir exatamente 1.000 resultados cada")
	ctx.check(same_signature, "[B] Mesma seed-base deve reproduzir a mesma sequência de 1.000 resultados")


static func _all_battle_ids_unique(results: Array[BattleResult]) -> bool:
	var seen: Dictionary = {}
	for r: BattleResult in results:
		if seen.has(r.battle_id):
			return false
		seen[r.battle_id] = true
	return true


static func _test_c_fixed_vs_fixed(ctx: TestRunner.Context) -> void:
	var army_a: Army = _fast_army_a()
	var army_b: Army = _fast_army_b()
	var pairs: Array = BattleSimulationRunner.build_fixed_vs_fixed_pairs(army_a, army_b, 20)

	var all_same_armies: bool = true
	for pair: Dictionary in pairs:
		if pair["army_a"] != army_a or pair["army_b"] != army_b:
			all_same_armies = false

	var config := SimulationConfig.new()
	config.simulation_count = 20
	config.base_seed_value = 1000
	var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	var report: SimulationReport = SimulationReport.build(results)

	print("  [C] Fixed vs Fixed (20 batalhas) -> todos os pares usam os MESMOS 2 Exércitos: %s | SimulationReport.total_battles == 20: %s (esperado: true, true)" % [
		str(all_same_armies), str(report.total_battles == 20)
	])
	ctx.check(all_same_armies, "[C] Fixed vs Fixed deve repetir os mesmos dois Exércitos em todos os pares")
	ctx.check(report.total_battles == 20, "[C] SimulationReport deve contar as 20 batalhas rodadas")


static func _test_d_fixed_vs_random(ctx: TestRunner.Context) -> void:
	var player_army: Army = _fast_army_a()
	var season_config := SeasonConfig.new()

	var pairs: Array = BattleSimulationRunner.build_fixed_vs_random_pairs(
		player_army, 15, 2000,
		EnemyArmyEntry.Category.NORMAL, "Mortos-Vivos", 1, GameDatabase.cards, season_config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f029_d"
	)

	var side_a_always_player: bool = true
	var generated_names: Array = []
	for pair: Dictionary in pairs:
		if pair["army_a"] != player_army:
			side_a_always_player = false
		generated_names.append(pair["army_b"].commander.commander_name)

	var config := SimulationConfig.new()
	config.simulation_count = 15
	config.base_seed_value = 3000
	var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	var report: SimulationReport = SimulationReport.build(results)

	print("  [D] Fixed vs Random (15 batalhas) -> lado A é sempre o Exército fixo: %s | lado B foi gerado (Comandante técnico presente em todas as 15 entradas): %s | SimulationReport.total_battles == 15: %s (esperado: true em todos)" % [
		str(side_a_always_player), str(generated_names.size() == 15), str(report.total_battles == 15)
	])
	ctx.check(side_a_always_player, "[D] Fixed vs Random deve manter o Exército fixo sempre do lado A")
	ctx.check(generated_names.size() == 15, "[D] Fixed vs Random deve gerar um Exército B por batalha")
	ctx.check(report.total_battles == 15, "[D] SimulationReport deve contar as 15 batalhas rodadas")


static func _test_e_random_vs_random(ctx: TestRunner.Context) -> void:
	var season_config := SeasonConfig.new()

	var pairs: Array = BattleSimulationRunner.build_random_vs_random_pairs(
		15, 4000,
		EnemyArmyEntry.Category.NORMAL, "Império", "Natureza", 1, GameDatabase.cards, season_config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f029_e"
	)

	var both_sides_generated: bool = true
	for pair: Dictionary in pairs:
		if pair["army_a"].cards.is_empty() or pair["army_b"].cards.is_empty():
			both_sides_generated = false

	var config := SimulationConfig.new()
	config.simulation_count = 15
	config.base_seed_value = 6000
	var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	var report: SimulationReport = SimulationReport.build(results)

	print("  [E] Random vs Random (15 batalhas) -> ambos os lados foram gerados (Formação de 9 cartas em cada): %s | SimulationReport.total_battles == 15: %s (esperado: true, true)" % [
		str(both_sides_generated), str(report.total_battles == 15)
	])
	ctx.check(both_sides_generated, "[E] Random vs Random deve gerar composições válidas dos dois lados")
	ctx.check(report.total_battles == 15, "[E] SimulationReport deve contar as 15 batalhas rodadas")


static func _test_f_same_seed_same_report(ctx: TestRunner.Context) -> void:
	var results1: Array[BattleResult] = _run_fixed_series(50, 8000)
	var results2: Array[BattleResult] = _run_fixed_series(50, 8000)
	var report1: SimulationReport = SimulationReport.build(results1)
	var report2: SimulationReport = SimulationReport.build(results2)

	var dict1: Dictionary = report1.to_dict()
	var dict2: Dictionary = report2.to_dict()
	dict1.erase("generated_at_unix")
	dict2.erase("generated_at_unix")
	var same_report: bool = dict1 == dict2

	print("  [F] Mesma seed-base (8000, 50 batalhas) -> SimulationReport.to_dict() idêntico (exceto timestamp)? %s (esperado: true)" % str(same_report))
	ctx.check(same_report, "[F] Mesma seed-base deve produzir o mesmo SimulationReport agregado (exceto o timestamp de geração)")


static func _test_g_different_seeds_differ(ctx: TestRunner.Context) -> void:
	var season_config := SeasonConfig.new()

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 111
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 222

	var entry_a: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, season_config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f029_g", 1, false, rng_a
	)
	var entry_b: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, season_config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f029_g", 1, false, rng_b
	)

	var names_a: Array = entry_a.cards.map(func(c: CardResource) -> String: return c.card_name)
	var names_b: Array = entry_b.cards.map(func(c: CardResource) -> String: return c.card_name)
	var different_composition: bool = names_a != names_b

	print("  [G] Seeds diferentes (111, 222) na geração de Exército -> composições diferentes? %s (esperado: true — sem presumir vencedores diferentes)" % str(different_composition))
	ctx.check(different_composition, "[G] Seeds diferentes devem produzir composições de Exército diferentes (a seed realmente controla o RNG de geração)")


static func _test_h_event_collection_does_not_alter_result(ctx: TestRunner.Context) -> void:
	var results_without_events: Array[BattleResult] = _run_fixed_series(30, 9000, false)
	var results_with_events: Array[BattleResult] = _run_fixed_series(30, 9000, true)

	var same_signature: bool = _results_signature(results_without_events) == _results_signature(results_with_events)
	var events_present: bool = true
	for r: BattleResult in results_with_events:
		if r.raw_attack_events.is_empty() and r.raw_heal_events.is_empty() and r.raw_death_events.is_empty():
			# Aceitável só se a batalha realmente não teve nenhum ataque/cura/morte
			# (não deveria acontecer nesta Formação, mas não presumido às cegas).
			events_present = false

	print("  [H] Coletar eventos (collect_events=true) -> mesma sequência de resultados que sem coletar: %s | eventos brutos presentes quando coletados: %s (esperado: true, true)" % [
		str(same_signature), str(events_present)
	])
	ctx.check(same_signature, "[H] Ligar collect_events não deve alterar winner_side/end_reason/turn_count/battlefield de nenhuma batalha")
	ctx.check(events_present, "[H] Quando collect_events=true, BattleResult deve trazer os eventos brutos da batalha")


static func _test_insights_respect_minimum_sample_size(ctx: TestRunner.Context) -> void:
	var results: Array[BattleResult] = _run_fixed_series(50, 10000, true)
	var report: SimulationReport = SimulationReport.build(results)

	var insight_high_threshold: Dictionary = SimulationInsights.highest_win_rate_card(report, 1000)
	var insight_low_threshold: Dictionary = SimulationInsights.highest_win_rate_card(report, 10)

	var respects_minimum: bool = insight_high_threshold.is_empty()
	var finds_with_lower_minimum: bool = not insight_low_threshold.is_empty()
	var carries_sample_size: bool = finds_with_lower_minimum and insight_low_threshold.has("sample_size") and insight_low_threshold["sample_size"] >= 10

	print("  [Insights] minimum_sample_size=1000 (maior que os dados existentes) -> retorna vazio: %s | minimum_sample_size=10 -> encontra candidato com sample_size >= 10: %s (esperado: true, true)" % [
		str(respects_minimum), str(carries_sample_size)
	])
	ctx.check(respects_minimum, "[Insights] Um piso de amostra maior que os dados existentes nunca deve declarar um 'melhor' forçado")
	ctx.check(finds_with_lower_minimum, "[Insights] Um piso de amostra atingível deve encontrar um candidato")
	ctx.check(carries_sample_size, "[Insights] Todo insight retornado deve carregar seu sample_size, nunca só o valor")
