class_name TestMineEvolutionResolver
extends RefCounted
## TestMineEvolutionResolver (F-020, decisão 16; generalizado em F-021.3.1)
##
## MineEvolutionResolver.evolve() segue exatamente o padrão de
## CityResolver.evolve_deposit(): custo via
## MineEconomy.upgrade_cost_pg()/MineEconomy.region_for_mina(), gasto
## via Kingdom.spend_generation_points(), incremento via
## Mina.increment_structure_level() — nenhuma fórmula nova. Nível
## máximo 4 (MINES.md) é EXCLUSIVO da Mina Inicial; Minas Regionais não
## têm teto documentado (F-021, achado P1: antes evolve_initial_mine()
## rejeitava qualquer Mina Regional com "not_initial_mine", travando a
## economia regional no Nível 1 para sempre — corrigido aqui).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021.3.1] Validando MineEvolutionResolver.evolve() (Mina Inicial e Regional)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var mina: Mina = kingdom.initial_mines[0]
	mina.structure_level = 1

	# Sucesso: PG suficiente para o custo real (Mina Inicial).
	var cost: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.MINA_INICIAL, 2)
	kingdom.generation_points = cost
	var result_success: Dictionary = MineEvolutionResolver.evolve(kingdom, mina)
	print("  Sucesso: nível 1 -> 2, custo %d PG gasto? %s | novo nível: %d | PG restante: %d (esperado: sucesso, nível 2, PG 0)" % [
		cost, str(result_success["success"]), mina.structure_level, kingdom.generation_points
	])
	ctx.check(result_success["success"], "Evolução deve ter sucesso com PG suficiente (motivo: '%s')" % result_success["reason"])
	ctx.check(mina.structure_level == 2, "Nível estrutural deve incrementar para 2 (obtido: %d)" % mina.structure_level)
	ctx.check(kingdom.generation_points == 0, "PG deve ser gasto exatamente no custo calculado (obtido: %d restante)" % kingdom.generation_points)

	# Falha: PG insuficiente.
	var result_insufficient: Dictionary = MineEvolutionResolver.evolve(kingdom, mina)
	print("  Falha esperada (PG insuficiente, 0 disponível): %s ('%s') | nível permanece %d? %s (esperado: false, 'insufficient_pg', true)" % [
		str(result_insufficient["success"]), result_insufficient["reason"], mina.structure_level, str(mina.structure_level == 2)
	])
	ctx.check(not result_insufficient["success"], "Evolução deve falhar sem PG suficiente")
	ctx.check(result_insufficient["reason"] == "insufficient_pg", "Motivo da falha deve ser 'insufficient_pg' (obtido: '%s')" % result_insufficient["reason"])
	ctx.check(mina.structure_level == 2, "Nível não pode mudar numa tentativa rejeitada (obtido: %d)" % mina.structure_level)

	# Falha: nível máximo (4), mesmo com PG de sobra — EXCLUSIVO da Mina Inicial.
	mina.structure_level = 4
	kingdom.generation_points = 999999
	var result_max: Dictionary = MineEvolutionResolver.evolve(kingdom, mina)
	print("  Falha esperada (Mina Inicial, nível máximo 4, mesmo com PG de sobra): %s ('%s') (esperado: false, 'max_level')" % [
		str(result_max["success"]), result_max["reason"]
	])
	ctx.check(not result_max["success"], "Evolução deve falhar no nível máximo, mesmo com PG suficiente")
	ctx.check(result_max["reason"] == "max_level", "Motivo da falha no limite deve ser 'max_level' (obtido: '%s')" % result_max["reason"])
	ctx.check(kingdom.generation_points == 999999, "PG não pode ser gasto numa tentativa rejeitada por limite de nível")

	# Sucesso: Mina Regional (Região 1) evolui de verdade — F-021.3.1,
	# achado P1 corrigido. Custo real da Região 1 (1 PG/nível, FORMULAS.md).
	var regional_mina := Mina.new(1500, "Império")
	regional_mina.region = 1
	regional_mina.structure_level = 1
	var regional_cost: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_1, 2)
	kingdom.generation_points = regional_cost
	var result_regional: Dictionary = MineEvolutionResolver.evolve(kingdom, regional_mina)
	print("  Sucesso (Mina Regional, Região 1): nível 1 -> 2, custo %d PG? %s | novo nível: %d | PG restante: %d" % [
		regional_cost, str(result_regional["success"]), regional_mina.structure_level, kingdom.generation_points
	])
	ctx.check(result_regional["success"], "Evolução de uma Mina Regional deve ter sucesso com PG suficiente (motivo: '%s')" % result_regional["reason"])
	ctx.check(regional_mina.structure_level == 2, "Nível estrutural da Mina Regional deve incrementar para 2 (obtido: %d)" % regional_mina.structure_level)
	ctx.check(kingdom.generation_points == 0, "PG deve ser gasto exatamente no custo real da Região 1 (obtido: %d restante)" % kingdom.generation_points)

	# Minas Regionais não têm teto de nível — evoluir muito além do
	# teto da Mina Inicial (4) deve continuar funcionando.
	regional_mina.structure_level = 27
	var regional_cost_high: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_1, 28)
	kingdom.generation_points = regional_cost_high
	var result_regional_high: Dictionary = MineEvolutionResolver.evolve(kingdom, regional_mina)
	print("  Sucesso (Mina Regional além do teto da Mina Inicial): nível 27 -> 28? %s (obtido nível: %d)" % [
		str(result_regional_high["success"]), regional_mina.structure_level
	])
	ctx.check(result_regional_high["success"], "Mina Regional não deve ter teto de Nível (nenhum documentado em MINES.md/FORMULAS.md)")
	ctx.check(regional_mina.structure_level == 28, "Nível da Mina Regional deve incrementar normalmente além do Nível 4 (obtido: %d)" % regional_mina.structure_level)

	# Custo real por Região difere (FORMULAS.md, "Custos em PG das Minas").
	var regiao_2_cost: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_2, 2)
	var regiao_3_cost: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 2)
	print("  Custo de evolução por Região (nível 2): I=%d, II=%d, III=%d (esperado: 1, 2, 3)" % [regional_cost, regiao_2_cost, regiao_3_cost])
	ctx.check(regional_cost == 1, "Custo da Região 1 nível 2 deve ser 1 PG (FORMULAS.md)")
	ctx.check(regiao_2_cost == 2, "Custo da Região 2 nível 2 deve ser 2 PG (FORMULAS.md)")
	ctx.check(regiao_3_cost == 3, "Custo da Região 3 nível 2 deve ser 3 PG (FORMULAS.md)")

	return true
