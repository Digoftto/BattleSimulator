class_name TestPhaseResolverDefeatReason
extends RefCounted
## TestPhaseResolverDefeatReason (F-020, decisão 7)
##
## PhaseResult.defeat_reason distingue derrota em combate real
## (COMBAT_LOSS) de esgotamento de Energia antes de qualquer combate
## acontecer (ENERGY_EXHAUSTED). Nenhuma regra de combate foi alterada
## para isso — só um campo novo, escrito em PhaseResolver.resolve().

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-020] Validando PhaseResult.defeat_reason (COMBAT_LOSS x ENERGY_EXHAUSTED)...")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.id = "TESTE_DEFEAT_REASON"
	enemy_entry.commander = enemy.commander
	enemy_entry.cards = enemy.cards
	enemy_entry.faction = "Natureza"

	# Energia suficiente, mas todas as 5 Formações empatam (Campeão na
	# posição 9 — mesmo molde de "losing_army" já usado em
	# test_expedition_runtime.gd) -> Squad se esgota tentando de verdade.
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	losing_army.initialize_energy(1)
	var losing_squad := Squad.new([losing_army])

	var result_combat_loss: PhaseResult = PhaseResolver.resolve(
		losing_squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "Teste", "pve"
	)
	print("  Derrota com Energia suficiente -> victory: %s, defeat_reason: %s, attempts: %d (esperado: false, COMBAT_LOSS, > 0)" % [
		str(result_combat_loss.victory), PhaseResult.DefeatReason.keys()[result_combat_loss.defeat_reason], result_combat_loss.attempts
	])
	ctx.check(not result_combat_loss.victory, "Formação sem vitória possível deve resultar em derrota")
	ctx.check(result_combat_loss.defeat_reason == PhaseResult.DefeatReason.COMBAT_LOSS, "Derrota com Energia suficiente deve ser COMBAT_LOSS (obtido: %s)" % PhaseResult.DefeatReason.keys()[result_combat_loss.defeat_reason])
	ctx.check(result_combat_loss.attempts > 0, "Derrota em combate real deve registrar ao menos 1 tentativa (obtido: %d)" % result_combat_loss.attempts)

	# Energia zerada ANTES de qualquer tentativa -> nenhum combate real
	# acontece, o Squad se esgota só por falta de Energia.
	var exhausted_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	exhausted_army.initialize_energy(1)
	exhausted_army.current_energy = 0
	var exhausted_squad := Squad.new([exhausted_army])

	var result_energy: PhaseResult = PhaseResolver.resolve(
		exhausted_squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "Teste", "pve"
	)
	print("  Derrota por Energia esgotada (0 desde o início) -> victory: %s, defeat_reason: %s, attempts: %d (esperado: false, ENERGY_EXHAUSTED, 0)" % [
		str(result_energy.victory), PhaseResult.DefeatReason.keys()[result_energy.defeat_reason], result_energy.attempts
	])
	ctx.check(not result_energy.victory, "Exército sem Energia deve resultar em derrota")
	ctx.check(result_energy.defeat_reason == PhaseResult.DefeatReason.ENERGY_EXHAUSTED, "Derrota sem Energia deve ser ENERGY_EXHAUSTED (obtido: %s)" % PhaseResult.DefeatReason.keys()[result_energy.defeat_reason])
	ctx.check(result_energy.attempts == 0, "Sem Energia desde o início, nenhum combate real deve ser tentado (obtido: %d)" % result_energy.attempts)

	# Vitória -> defeat_reason permanece NONE.
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var winning_squad := Squad.new([winning_army])
	var result_victory: PhaseResult = PhaseResolver.resolve(
		winning_squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "Teste", "pve"
	)
	print("  Vitória -> defeat_reason permanece NONE? %s (esperado: true)" % str(result_victory.defeat_reason == PhaseResult.DefeatReason.NONE))
	ctx.check(result_victory.victory, "Formação vencedora (Campeão posição 1) deve vencer")
	ctx.check(result_victory.defeat_reason == PhaseResult.DefeatReason.NONE, "Vitória nunca deve setar defeat_reason (obtido: %s)" % PhaseResult.DefeatReason.keys()[result_victory.defeat_reason])

	return true
