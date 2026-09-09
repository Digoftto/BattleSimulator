class_name TestInstitutionalConstructionEntryCurve
extends RefCounted
## TestInstitutionalConstructionEntryCurve (FASE 22, Simulação 5 —
## BALANCING_SIMULATION.md, "Curva de Entrada", Cenário B)
##
## Confirma que InstitutionalConstructionEntryCurve:
## - reduz em 95% o custo real (GeneralConstructionFormula.upgrade_cost())
##   para alcançar os Níveis 2 e 3, para as 4 Construções Institucionais;
## - devolve 100% do custo real a partir do Nível 4;
## - InstitutionalConstructionResolver.cost_breakdown() usa exatamente
##   esse valor (nunca uma segunda fonte) — testado indiretamente
##   comparando cost_breakdown() somado contra total_cost().

static func run(ctx: TestRunner.Context) -> bool:
	print("[Economia] Validando Curva de Entrada das Construções Institucionais (FASE 22)...")

	var buildings: Array[InstitutionalConstructionConfig.Building] = [
		InstitutionalConstructionConfig.Building.CAPITAL,
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO,
		InstitutionalConstructionConfig.Building.ACADEMIA,
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA,
	]

	for building: InstitutionalConstructionConfig.Building in buildings:
		var real_level_2: int = GeneralConstructionFormula.upgrade_cost(2, InstitutionalConstructionConfig.b(building), InstitutionalConstructionConfig.x(building))
		var real_level_3: int = GeneralConstructionFormula.upgrade_cost(3, InstitutionalConstructionConfig.b(building), InstitutionalConstructionConfig.x(building))
		var real_level_4: int = GeneralConstructionFormula.upgrade_cost(4, InstitutionalConstructionConfig.b(building), InstitutionalConstructionConfig.x(building))

		var entry_level_2: int = InstitutionalConstructionEntryCurve.total_cost(building, 2)
		var entry_level_3: int = InstitutionalConstructionEntryCurve.total_cost(building, 3)
		var entry_level_4: int = InstitutionalConstructionEntryCurve.total_cost(building, 4)

		var expected_level_2: int = int(round(real_level_2 * 0.05))
		var expected_level_3: int = int(round(real_level_3 * 0.05))

		print("  %s: Nível 2 real=%d curva=%d (esperado %d) | Nível 3 real=%d curva=%d (esperado %d) | Nível 4 real=%d curva=%d (esperado igual)" % [
			InstitutionalConstructionResolver.building_key(building),
			real_level_2, entry_level_2, expected_level_2,
			real_level_3, entry_level_3, expected_level_3,
			real_level_4, entry_level_4,
		])

		ctx.check(entry_level_2 == expected_level_2, "%s: custo do Nível 2 deve ser 5%% do valor real (obtido: %d, esperado: %d)" % [InstitutionalConstructionResolver.building_key(building), entry_level_2, expected_level_2])
		ctx.check(entry_level_3 == expected_level_3, "%s: custo do Nível 3 deve ser 5%% do valor real (obtido: %d, esperado: %d)" % [InstitutionalConstructionResolver.building_key(building), entry_level_3, expected_level_3])
		ctx.check(entry_level_4 == real_level_4, "%s: custo do Nível 4 não deve ter desconto (obtido: %d, esperado: %d)" % [InstitutionalConstructionResolver.building_key(building), entry_level_4, real_level_4])
		ctx.check(entry_level_2 < real_level_2, "%s: custo do Nível 2 com desconto deve ser menor que o real" % InstitutionalConstructionResolver.building_key(building))

	# cost_breakdown() precisa refletir exatamente o mesmo total —
	# nunca uma segunda fórmula/percentual paralelo.
	var capital_breakdown: Dictionary = InstitutionalConstructionResolver.cost_breakdown(InstitutionalConstructionConfig.Building.CAPITAL, 2)
	var capital_breakdown_total: int = capital_breakdown.get("ferro_negro", 0) + capital_breakdown.get("cristais_arcanos", 0) + capital_breakdown.get("essencia_vital", 0)
	var capital_entry_total: int = InstitutionalConstructionEntryCurve.total_cost(InstitutionalConstructionConfig.Building.CAPITAL, 2)
	print("  Capital cost_breakdown() Nível 2 soma=%d vs InstitutionalConstructionEntryCurve.total_cost()=%d (esperado: iguais)" % [capital_breakdown_total, capital_entry_total])
	ctx.check(capital_breakdown_total == capital_entry_total, "cost_breakdown() deve somar exatamente o total de InstitutionalConstructionEntryCurve (obtido: %d, esperado: %d)" % [capital_breakdown_total, capital_entry_total])

	return true
