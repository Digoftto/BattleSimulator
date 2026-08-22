class_name TestPhaseRetry
extends RefCounted
## TestPhaseRetry (F-001, Etapa 16)
##
## Migrado de bootstrap.gd:_validate_phase_retry(). Mesmo cenário
## original — os 4 cenários de retry (a-d) usando o Campeão/Dummy/
## Guard/Wall de CampaignTestFixtures, mais o cenário (e) de exaustão
## por Energia insuficiente, e a checagem de identidade de
## opponent_entry. Usa Squad/Army locais e PhaseResolver.resolve()
## diretamente (não ExpeditionRuntime) — confirmado na auditoria da
## Etapa 16: CombatState.rng é estruturalmente inerte neste cenário
## (as fixtures de CampaignTestFixtures nunca definem .doctrine, e
## nenhuma carta transitória usada aqui tem tier_5_ability_name
## definido), mesmo raciocínio já usado em test_reward_resolver.gd e
## test_commander_battle_history.gd. Nenhuma seed foi adicionada,
## nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[PhaseResolver] Validando os 4 cenários de retry (incluindo consumo de Energia)...")

	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.id = "TESTE_RETRY_INIMIGO"
	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	enemy_entry.commander = enemy_army.commander
	enemy_entry.cards = enemy_army.cards

	# a) Vitória na primeira Formação.
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_a.initialize_energy(1)
	var squad_a := Squad.new([army_a])
	var result_a: PhaseResult = PhaseResolver.resolve(
		squad_a, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  a) Vitória na 1ª Formação -> vitória=%s formação=%s tentativas=%d (esperado: true, α, 1) | Energia restante: %d/%d" % [
		str(result_a.victory), result_a.winning_formation, result_a.attempts, army_a.current_energy, army_a.max_energy
	])
	ctx.check(result_a.victory == true, "Cenário a) deve ser vitória")
	ctx.check(result_a.winning_formation == "α", "Cenário a) deve vencer na Formação α (obtido: %s)" % result_a.winning_formation)
	ctx.check(result_a.attempts == 1, "Cenário a) deve vencer na 1ª tentativa (obtido: %d)" % result_a.attempts)

	# b) Vitória na terceira Formação.
	var army_b: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 5, "γ": 1})
	army_b.initialize_energy(1)
	var squad_b := Squad.new([army_b])
	var result_b: PhaseResult = PhaseResolver.resolve(
		squad_b, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  b) Vitória na 3ª Formação -> vitória=%s formação=%s tentativas=%d (esperado: true, γ, 3) | Energia consumida: %d (esperado: 12)" % [
		str(result_b.victory), result_b.winning_formation, result_b.attempts, army_b.max_energy - army_b.current_energy
	])
	ctx.check(result_b.victory == true, "Cenário b) deve ser vitória")
	ctx.check(result_b.winning_formation == "γ", "Cenário b) deve vencer na Formação γ (obtido: %s)" % result_b.winning_formation)
	ctx.check(result_b.attempts == 3, "Cenário b) deve vencer na 3ª tentativa (obtido: %d)" % result_b.attempts)
	ctx.check(army_b.max_energy - army_b.current_energy == 12, "Cenário b) deve consumir 12 de Energia (obtido: %d)" % (army_b.max_energy - army_b.current_energy))

	# c) Vitória utilizando o segundo Exército.
	var army_c1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_c1.initialize_energy(1)
	var army_c2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_c2.initialize_energy(1)
	var squad_c := Squad.new([army_c1, army_c2])
	var result_c: PhaseResult = PhaseResolver.resolve(
		squad_c, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  c) Vitória no 2º Exército -> vitória=%s exército_index=%d tentativas=%d (esperado: true, 1, 6)" % [
		str(result_c.victory), result_c.winning_army_index, result_c.attempts
	])
	ctx.check(result_c.victory == true, "Cenário c) deve ser vitória")
	ctx.check(result_c.winning_army_index == 1, "Cenário c) deve vencer com o 2º Exército, índice 1 (obtido: %d)" % result_c.winning_army_index)
	ctx.check(result_c.attempts == 6, "Cenário c) deve vencer na 6ª tentativa total (obtido: %d)" % result_c.attempts)

	# d) Derrota após todas as Formações de todos os Exércitos.
	var army_d1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_d1.initialize_energy(1)
	var army_d2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 5, "β": 5, "γ": 5, "δ": 5, "ε": 5})
	army_d2.initialize_energy(1)
	var squad_d := Squad.new([army_d1, army_d2])
	var result_d: PhaseResult = PhaseResolver.resolve(
		squad_d, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  d) Derrota total -> vitória=%s tentativas=%d (esperado: false, 10)" % [
		str(result_d.victory), result_d.attempts
	])
	ctx.check(result_d.victory == false, "Cenário d) deve ser derrota total")
	ctx.check(result_d.attempts == 10, "Cenário d) deve esgotar as 10 tentativas (obtido: %d)" % result_d.attempts)

	# e) Exaustão por Energia (não por Formação): Energia insuficiente
	# para sequer 1 tentativa faz o Exército ser considerado esgotado
	# imediatamente, mesmo com todas as 5 Formações disponíveis.
	var army_e: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_e.max_energy = 3  # menor que o custo de 1 tentativa (4)
	army_e.current_energy = 3
	var squad_e := Squad.new([army_e])
	var result_e: PhaseResult = PhaseResolver.resolve(
		squad_e, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  e) Exaustão por Energia insuficiente -> vitória=%s tentativas=%d (esperado: false, 0 — nenhuma tentativa chegou a ocorrer)" % [
		str(result_e.victory), result_e.attempts
	])
	ctx.check(result_e.victory == false, "Cenário e) deve ser derrota por exaustão de Energia")
	ctx.check(result_e.attempts == 0, "Cenário e) não deve registrar nenhuma tentativa (obtido: %d)" % result_e.attempts)

	print("  opponent_entry preservado no resultado? %s (esperado: true, id=%s)" % [
		str(result_a.opponent_entry == enemy_entry), result_a.opponent_entry.id
	])
	ctx.check(result_a.opponent_entry == enemy_entry, "opponent_entry do resultado deve ser o mesmo objeto enemy_entry")

	return true
