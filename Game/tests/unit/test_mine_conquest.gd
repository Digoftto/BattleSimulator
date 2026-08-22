class_name TestMineConquest
extends RefCounted
## TestMineConquest (F-001, Etapa 17)
##
## Migrado de bootstrap.gd:_validate_mine_conquest(). Mesmo cenário
## original — vitória contra o Chefe de Mina marca a Mina como
## conquistada; Mina já conquistada ou Mina Inicial (sem Fase) não
## tentam nada (attempt_conquest() retorna null). Usa Trilha.new()/
## Mina.new()/Kingdom.new() locais — sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/
## WorldBootstrap, direta ou transitiva. MineConquestResolver.
## attempt_conquest() recebe o Kingdom local explicitamente como
## parâmetro (não lê nenhum singleton — confirmado por leitura direta de
## mine_conquest_resolver.gd na auditoria de Stage 17).
##
## RNG: attempt_conquest() é chamado com seed explícita 123, e a
## composição de combate usada aqui (CampaignTestFixtures) não inclui
## nenhuma carta com Habilidade — o mesmo raciocínio de "RNG
## estruturalmente inerte" (CombatState.rng só é consultado pelo sorteio
## de Campo de Batalha, cujo Efeito não é aplicado nesta Sprint) já
## estabelecido e documentado em test_phase_retry.gd é preservado aqui
## sem alteração. Nenhuma seed foi adicionada, nenhum código de
## produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra. A checagem de "Nível de Conta" era puramente narrativa
## no original (sem valor esperado fixo, só "pode já ter virado Nível 2")
## — preservada como print, sem inventar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando a conquista de uma Mina Regional...")

	var trilha := Trilha.new("territorio-conquista-teste")
	var mina := Mina.new(50, "Império")  # Fase 50, Região I
	var kingdom := Kingdom.new()

	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(
		"Império", CampaignTestFixtures.build_campaign_enemy_army()
	)

	print("  Mina conquistada antes da tentativa? %s (esperado: false)" % str(mina.conquered))
	ctx.check(mina.conquered == false, "Mina não deve estar conquistada antes da tentativa")

	print("  PG antes da conquista: %d (esperado: 0)" % kingdom.generation_points)
	ctx.check(kingdom.generation_points == 0, "PG antes da conquista deve ser 0 (obtido: %d)" % kingdom.generation_points)

	var result: PhaseResult = MineConquestResolver.attempt_conquest(
		mina, trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Vitória na conquista? %s | Mina conquistada agora? %s (esperado: true, true)" % [
		(str(result.victory) if result != null else "null"), str(mina.conquered)
	])
	ctx.check(result != null and result.victory == true, "A tentativa de conquista deve resultar em vitória")
	ctx.check(mina.conquered == true, "Mina deve estar conquistada após a vitória")

	print("  XP de Conta após 'Liberar Mina' (20 XP): %d | Nível de Conta: %d (esperado: >= 20, pode já ter virado Nível 2 = +1 PG)" % [
		kingdom.account_xp, kingdom.account_level()
	])
	ctx.check(kingdom.account_xp >= 20, "XP de Conta após 'Liberar Mina' deve ser >= 20 (obtido: %d)" % kingdom.account_xp)

	var second_attempt: PhaseResult = MineConquestResolver.attempt_conquest(
		mina, trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Tentar de novo uma Mina já conquistada -> retorna null? %s (esperado: true)" % str(second_attempt == null))
	ctx.check(second_attempt == null, "Tentar conquistar novamente uma Mina já conquistada deve retornar null")

	kingdom.create_initial_mines()
	var initial_result: PhaseResult = MineConquestResolver.attempt_conquest(
		kingdom.initial_mines[0], trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Tentar conquistar uma Mina Inicial (sem Fase) -> retorna null? %s (esperado: true)" % str(initial_result == null))
	ctx.check(initial_result == null, "Tentar conquistar uma Mina Inicial (sem Fase) deve retornar null")

	return true
