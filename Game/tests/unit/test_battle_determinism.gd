class_name TestBattleDeterminism
extends RefCounted
## TestBattleDeterminism (F-028)
##
## Valida a fundação de determinismo introduzida no F-028: seed opcional em
## CombatState/CombatEngine, RNG opcional em EnemyArmyGenerator/
## CommanderGenerator, Battle ID único por execução, Rules Version e o
## evento BATTLE_FINISHED — sem alterar nenhuma regra de combate.
##
## Teste A: mesma seed duas vezes -> resultado idêntico (vencedor, motivo,
## turnos, Campo de Batalha, eliminados, sequência de eventos).
## Teste B: seeds diferentes -> confirma que a seed realmente controla o
## RNG (sequências diferentes), sem presumir que vencedores diferentes.
## Teste C: mesma seed -> geração de Exército (Comandante/Cartas/Formação)
## reproduzida.
## Teste D (o mais importante): uma única seed controlando toda a cadeia
## (geração dos dois Exércitos + CombatEngine) produz resultado idêntico
## entre duas execuções independentes.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-028] Validando determinismo de batalha e geração de Exército...")

	_test_a_same_seed_reproducible(ctx)
	_test_b_different_seeds_control_rng(ctx)
	_test_c_army_generation_reproducible(ctx)
	_test_d_full_chain_reproducible(ctx)
	_test_e_battle_finished_event(ctx)

	return true


static func _eliminated_names_by_side(state: CombatState) -> Dictionary:
	var by_side: Dictionary = {0: [], 1: []}
	for unit: CombatUnit in state.eliminated_units:
		by_side[unit.side].append(unit.card.card_name if unit.card != null else "")
	return by_side


static func _test_a_same_seed_reproducible(ctx: TestRunner.Context) -> void:
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({})
	var army_b: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var seed_value: int = 12345

	var state1: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var collector1 := BattleEventCollector.new()
	collector1.attach(state1.event_bus)
	CombatEngine.run(state1)

	var state2: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var collector2 := BattleEventCollector.new()
	collector2.attach(state2.event_bus)
	CombatEngine.run(state2)

	var same_winner: bool = state1.winner_side == state2.winner_side
	var same_end_reason: bool = state1.end_reason == state2.end_reason
	var same_turn_count: bool = state1.turn == state2.turn
	var same_battlefield: bool = state1.battlefield.battlefield_name == state2.battlefield.battlefield_name
	var same_eliminated: bool = _eliminated_names_by_side(state1) == _eliminated_names_by_side(state2)
	var same_attack_events: bool = collector1.attack_events == collector2.attack_events
	var same_heal_events: bool = collector1.heal_events == collector2.heal_events
	var same_death_events: bool = collector1.death_events == collector2.death_events
	var different_battle_id: bool = state1.battle_id != state2.battle_id
	var seed_recorded: bool = state1.seed_value == seed_value and state2.seed_value == seed_value
	var rules_version_recorded: bool = state1.rules_version == CombatEngine.RULES_VERSION and state2.rules_version == CombatEngine.RULES_VERSION

	print("  [A] Mesma seed (%d) duas vezes -> vencedor: %s | motivo: %s | turnos: %s | Campo de Batalha: %s | eliminados: %s | eventos (ataque/cura/morte): %s/%s/%s | battle_id diferente: %s (esperado: true em todos)" % [
		seed_value, str(same_winner), str(same_end_reason), str(same_turn_count), str(same_battlefield), str(same_eliminated),
		str(same_attack_events), str(same_heal_events), str(same_death_events), str(different_battle_id)
	])
	ctx.check(same_winner, "[A] Mesma seed deve produzir o mesmo vencedor")
	ctx.check(same_end_reason, "[A] Mesma seed deve produzir o mesmo motivo de fim de batalha")
	ctx.check(same_turn_count, "[A] Mesma seed deve produzir o mesmo número de turnos")
	ctx.check(same_battlefield, "[A] Mesma seed deve sortear o mesmo Campo de Batalha")
	ctx.check(same_eliminated, "[A] Mesma seed deve eliminar exatamente as mesmas unidades, na mesma ordem por lado")
	ctx.check(same_attack_events, "[A] Mesma seed deve produzir a mesma sequência de eventos de ataque")
	ctx.check(same_heal_events, "[A] Mesma seed deve produzir a mesma sequência de eventos de cura")
	ctx.check(same_death_events, "[A] Mesma seed deve produzir a mesma sequência de eventos de morte")
	ctx.check(different_battle_id, "[A] battle_id deve ser único por execução, mesmo com a mesma seed e o mesmo resultado")
	ctx.check(seed_recorded, "[A] CombatState.seed_value deve refletir a seed fornecida em ambas as execuções")
	ctx.check(rules_version_recorded, "[A] CombatState.rules_version deve refletir CombatEngine.RULES_VERSION em ambas as execuções")


static func _test_b_different_seeds_control_rng(ctx: TestRunner.Context) -> void:
	var state1 := CombatState.new(111)
	var state2 := CombatState.new(222)

	var seed_recorded: bool = state1.seed_value == 111 and state2.seed_value == 222
	var roll1: int = state1.rng.randi()
	var roll2: int = state2.rng.randi()
	var different_rng_stream: bool = roll1 != roll2

	print("  [B] Seeds diferentes (111, 222) -> seed_value registrada corretamente: %s | primeira chamada de rng.randi() diferente: %s (esperado: true, true)" % [
		str(seed_recorded), str(different_rng_stream)
	])
	ctx.check(seed_recorded, "[B] CombatState.seed_value deve refletir exatamente a seed fornecida a cada instância")
	ctx.check(different_rng_stream, "[B] Seeds diferentes devem produzir sequências de RNG diferentes (a seed realmente controla o RNG)")


static func _test_c_army_generation_reproducible(ctx: TestRunner.Context) -> void:
	var config := SeasonConfig.new()
	config.seed_value = 999

	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 999
	var entry1: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 1, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f028_c", 1, false, rng1
	)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 999
	var entry2: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 1, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f028_c", 1, false, rng2
	)

	var d1: CommanderDoctrine = entry1.commander.doctrine
	var d2: CommanderDoctrine = entry2.commander.doctrine
	var same_doctrine: bool = (
		d1.restriction.code == d2.restriction.code and d1.restriction_param == d2.restriction_param and
		d1.requirement.code == d2.requirement.code and d1.requirement_param == d2.requirement_param and
		d1.target.code == d2.target.code and
		d1.effect.code == d2.effect.code and
		d1.value.code == d2.value.code and
		d1.rarity_score == d2.rarity_score
	)
	var same_xp: bool = entry1.commander.accumulated_xp == entry2.commander.accumulated_xp

	var names1: Array = entry1.cards.map(func(c: CardResource) -> String: return c.card_name)
	var names2: Array = entry2.cards.map(func(c: CardResource) -> String: return c.card_name)
	var tiers1: Array = entry1.cards.map(func(c: CardResource) -> int: return c.tier)
	var tiers2: Array = entry2.cards.map(func(c: CardResource) -> int: return c.tier)
	var same_formation_names: bool = names1 == names2
	var same_formation_tiers: bool = tiers1 == tiers2

	print("  [C] Mesma seed (999) na geração de Exército -> Doutrina idêntica: %s | XP idêntico: %s | nomes da Formação idênticos (mesma ordem): %s | Tiers idênticos: %s (esperado: true em todos)" % [
		str(same_doctrine), str(same_xp), str(same_formation_names), str(same_formation_tiers)
	])
	ctx.check(same_doctrine, "[C] Mesma seed deve reproduzir a mesma Doutrina (Restrição/Requisito/Alvo/Efeito/Valor/Rarity Score)")
	ctx.check(same_xp, "[C] Mesma seed deve reproduzir a mesma Patente/XP do Comandante gerado")
	ctx.check(same_formation_names, "[C] Mesma seed deve reproduzir a mesma composição de cartas, na mesma ordem de Formação")
	ctx.check(same_formation_tiers, "[C] Mesma seed deve reproduzir os mesmos Tiers sorteados para cada carta")


## Gera os dois Exércitos de uma cadeia completa a partir de uma única
## seed — mesmo RNG consumido sequencialmente pelas duas chamadas de
## generate() (Exército A, depois Exército B), reproduzível desde que a
## sequência de chamadas seja idêntica entre execuções (garantido aqui:
## sempre A antes de B, com os mesmos argumentos).
static func _build_chain_armies(master_seed: int) -> Dictionary:
	var config := SeasonConfig.new()
	config.seed_value = master_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = master_seed

	var entry_a: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 1, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f028_d_a", 1, false, rng
	)
	var entry_b: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Mortos-Vivos", 1, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f028_d_b", 1, false, rng
	)

	var army_a := Army.new()
	army_a.commander = entry_a.commander
	army_a.cards = entry_a.cards

	var army_b := Army.new()
	army_b.commander = entry_b.commander
	army_b.cards = entry_b.cards

	return {"army_a": army_a, "army_b": army_b}


static func _test_d_full_chain_reproducible(ctx: TestRunner.Context) -> void:
	var master_seed: int = 424242

	var armies1: Dictionary = _build_chain_armies(master_seed)
	var state1: CombatState = CombatEngine.run_battle(
		armies1["army_a"], armies1["army_b"], GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", master_seed
	)
	var result1 := BattleResult.from_state(state1)

	var armies2: Dictionary = _build_chain_armies(master_seed)
	var state2: CombatState = CombatEngine.run_battle(
		armies2["army_a"], armies2["army_b"], GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", master_seed
	)
	var result2 := BattleResult.from_state(state2)

	var dict1: Dictionary = result1.to_dict()
	var dict2: Dictionary = result2.to_dict()
	# battle_id é deliberadamente único por execução (F-028) — nunca deve
	# ser comparado entre duas execuções independentes da mesma cadeia.
	dict1.erase("battle_id")
	dict2.erase("battle_id")

	var same_result: bool = dict1 == dict2

	print("  [D] Uma única seed (%d) controlando geração dos 2 Exércitos + CombatEngine -> resultado estruturado idêntico (exceto battle_id): %s (esperado: true)" % [
		master_seed, str(same_result)
	])
	if not same_result:
		print("      Resultado 1: %s" % str(dict1))
		print("      Resultado 2: %s" % str(dict2))
	ctx.check(same_result, "[D] Uma única seed controlando toda a cadeia (geração dos Exércitos + CombatEngine) deve produzir um Resultado de Batalha estruturado idêntico entre duas execuções independentes")


static func _find_restriction_by_code(code: String) -> CommanderRestrictionResource:
	for entry: CommanderRestrictionResource in GameDatabase.commander_restrictions:
		if entry.code == code:
			return entry
	return null


## BATTLE_FINISHED (F-028) precisa ser publicado exatamente uma vez tanto
## no caminho normal (loop de turnos até o fim) quanto no caminho de saída
## antecipada (Restrição de Campo de Batalha bloqueia dentro de
## _initialize(), antes de qualquer turno rodar — is_finished já true
## quando initialize() retorna). CombatEngine.run() publica DEPOIS do
## while-loop, então cobre os dois casos (ver CombatEngine._publish_battle_finished()).
static func _test_e_battle_finished_event(ctx: TestRunner.Context) -> void:
	# --- Caminho normal ---
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({})
	var army_b: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var state_normal: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 555)

	# Array de 1 elemento: lambdas do GDScript capturam variáveis locais
	# por VALOR (uma cópia no momento da criação), não por referência —
	# um Array/Dictionary (tipos por referência) é o jeito padrão de
	# mutar um contador/estado de dentro de um Callable.
	var finished_calls_normal: Array = []
	state_normal.event_bus.subscribe(CombatEventType.Type.BATTLE_FINISHED, func(_type: CombatEventType.Type, context: CombatContext) -> void:
		finished_calls_normal.append(context)
	)
	CombatEngine.run(state_normal)

	var fired_once_normal: bool = finished_calls_normal.size() == 1
	var last_context_normal: CombatContext = finished_calls_normal[0] if not finished_calls_normal.is_empty() else null
	var context_matches_normal: bool = last_context_normal != null and last_context_normal.state == state_normal and last_context_normal.turn == state_normal.turn

	print("  [E1] BATTLE_FINISHED publicado exatamente 1 vez no caminho normal (loop de turnos)? %s | contexto reflete o estado final? %s (esperado: true, true)" % [
		str(fired_once_normal), str(context_matches_normal)
	])
	ctx.check(fired_once_normal, "[E1] BATTLE_FINISHED deve ser publicado exatamente uma vez no caminho normal")
	ctx.check(context_matches_normal, "[E1] O contexto de BATTLE_FINISHED deve referenciar o CombatState final, no turno em que a batalha terminou")

	# --- Caminho de saída antecipada: Restrição de Campo de Batalha
	# bloqueia ANTES de qualquer turno rodar ---
	var restriction: CommanderRestrictionResource = _find_restriction_by_code("RS030")  # Apenas Campo Aberto
	var doctrine := CommanderDoctrine.new()
	doctrine.restriction = restriction
	var blocked_commander := CommanderResource.new()
	blocked_commander.commander_name = "Comandante Só-Campo-Aberto (Teste F-028)"
	blocked_commander.doctrine = doctrine

	var blocked_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	blocked_army.commander = blocked_commander

	var storm_field := BattlefieldResource.new()
	storm_field.battlefield_name = "Tempestade com Raios"
	storm_field.category = "Especial"
	var single_battlefield: Array[BattlefieldResource] = [storm_field]

	var state_blocked: CombatState = CombatEngine.initialize(blocked_army, army_b, single_battlefield, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 777)
	var finished_calls_blocked: Array = []
	state_blocked.event_bus.subscribe(CombatEventType.Type.BATTLE_FINISHED, func(_type: CombatEventType.Type, context: CombatContext) -> void:
		finished_calls_blocked.append(context)
	)

	var already_finished_before_run: bool = state_blocked.is_finished
	CombatEngine.run(state_blocked)
	var fired_once_blocked: bool = finished_calls_blocked.size() == 1

	print("  [E2] Saída antecipada (Restrição de Campo de Batalha, nenhum turno rodou) -> já estava finalizada antes de run(): %s | BATTLE_FINISHED publicado exatamente 1 vez mesmo assim: %s (esperado: true, true)" % [
		str(already_finished_before_run), str(fired_once_blocked)
	])
	ctx.check(already_finished_before_run, "[E2] A batalha bloqueada por Restrição de Campo de Batalha deve terminar dentro de initialize(), antes de qualquer turno")
	ctx.check(fired_once_blocked, "[E2] BATTLE_FINISHED deve ser publicado exatamente uma vez mesmo quando a batalha termina em initialize(), sem nenhum turno rodado")
