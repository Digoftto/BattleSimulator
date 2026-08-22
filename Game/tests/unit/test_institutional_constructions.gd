class_name TestInstitutionalConstructions
extends RefCounted
## TestInstitutionalConstructions (F-001, Etapa 12)
##
## Migrado de bootstrap.gd:_validate_institutional_constructions(). Mesmo
## cenário original — evolução das 4 construções institucionais (Capital,
## Centro de Comando, Academia, Núcleo de Energia): Fórmula Geral de
## Construções com os b/x vigentes (InstitutionalConstructionConfig,
## espelhando BALANCING_SIMULATION.md), Assinatura Econômica (33/33/33
## para a Capital, 70/30 Principal/Secundário para as demais), e o teto
## da Capital sobre as outras 3. Usa Kingdom.new() local e
## InstitutionalConstructionResolver (confirmado sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap,
## direta ou transitiva).
##
## O teste original já tinha "(esperado: X)" explícito nos pontos-chave —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.
## A proporção da Academia (70/30) só tinha um "~70%%" aproximado no
## original (sem valor exato definido) e permanece apenas informativa.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Cidade] Validando evolução das 4 construções institucionais (Fórmula Geral)...")

	var kingdom := Kingdom.new()
	kingdom.raw_resources = {"ferro_negro": 1000000, "cristais_arcanos": 1000000, "essencia_vital": 1000000}

	# Capital: 33/33/33, sem teto próprio.
	var capital_before: int = kingdom.capital_level
	var capital_costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(
		InstitutionalConstructionConfig.Building.CAPITAL, capital_before + 1
	)
	print("  Custo Capital Nível 1->2 (33/33/33): Ferro %d | Cristais %d | Essência %d" % [
		capital_costs.get("ferro_negro", 0), capital_costs.get("cristais_arcanos", 0), capital_costs.get("essencia_vital", 0)
	])
	var capital_result: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CAPITAL)
	print("  Evoluir Capital -> sucesso? %s | Nível agora: %d (esperado: true, 2)" % [
		str(capital_result["success"]), kingdom.capital_level
	])
	ctx.check(capital_result["success"] == true, "Evoluir a Capital deve ter sucesso")
	ctx.check(kingdom.capital_level == 2, "Capital deve estar no Nível 2 (obtido: %d)" % kingdom.capital_level)

	# Centro de Comando: bloqueado até a Capital estar à frente (Capital=2, CdC=1 -> pode evoluir 1 vez, até igualar).
	var cdc_result: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Evoluir Centro de Comando (Capital=2, CdC=1) -> sucesso? %s | Nível agora: %d (esperado: true, 2)" % [
		str(cdc_result["success"]), kingdom.command_center_level
	])
	ctx.check(cdc_result["success"] == true, "Evoluir o Centro de Comando dentro do teto da Capital deve ter sucesso")
	ctx.check(kingdom.command_center_level == 2, "Centro de Comando deve estar no Nível 2 (obtido: %d)" % kingdom.command_center_level)

	var cdc_blocked: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Evoluir Centro de Comando de novo (CdC alcançou a Capital) -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(cdc_blocked["success"]), cdc_blocked["reason"]
	])
	ctx.check(cdc_blocked["success"] == false, "Evoluir o Centro de Comando no teto da Capital deve falhar")
	ctx.check(cdc_blocked["reason"] == "capital_limit", "Motivo da falha deve ser capital_limit (obtido: %s)" % cdc_blocked["reason"])

	# Academia: Assinatura 70/30 (Principal: Essência Vital, Secundário: Ferro Negro).
	var academia_costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(
		InstitutionalConstructionConfig.Building.ACADEMIA, 2
	)
	var academia_total: int = academia_costs.get("essencia_vital", 0) + academia_costs.get("ferro_negro", 0)
	print("  Custo Academia Nível 1->2 (70/30) -> Essência (Principal): %d | Ferro (Secundário): %d | Proporção Principal: %.0f%% (esperado: ~70%%)" % [
		academia_costs.get("essencia_vital", 0), academia_costs.get("ferro_negro", 0),
		(academia_costs.get("essencia_vital", 0) / float(academia_total)) * 100.0
	])
	InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.ACADEMIA)
	print("  Academia evoluiu -> Nível: %d (esperado: 2)" % kingdom.academy_level)
	ctx.check(kingdom.academy_level == 2, "Academia deve estar no Nível 2 (obtido: %d)" % kingdom.academy_level)

	# Núcleo de Energia: mesma Assinatura 70/30 (Principal: Cristais Arcanos).
	InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA)
	print("  Núcleo de Energia evoluiu -> Nível: %d (esperado: 2)" % kingdom.energy_nucleus_level)
	ctx.check(kingdom.energy_nucleus_level == 2, "Núcleo de Energia deve estar no Nível 2 (obtido: %d)" % kingdom.energy_nucleus_level)

	# Recursos insuficientes: tudo ou nada, nada é gasto parcialmente.
	var poor_kingdom := Kingdom.new()
	poor_kingdom.capital_level = 5
	poor_kingdom.raw_resources = {"ferro_negro": 5, "cristais_arcanos": 1000000, "essencia_vital": 1000000}
	var before_cristais: int = poor_kingdom.get_raw_resource("cristais_arcanos")
	var poor_result: Dictionary = InstitutionalConstructionResolver.evolve(poor_kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Centro de Comando sem Ferro Negro suficiente -> sucesso? %s | motivo: %s | Cristais Arcanos intocado? %s (esperado: false, insufficient_resources, true)" % [
		str(poor_result["success"]), poor_result["reason"],
		str(poor_kingdom.get_raw_resource("cristais_arcanos") == before_cristais)
	])
	ctx.check(poor_result["success"] == false, "Evoluir sem Ferro Negro suficiente deve falhar")
	ctx.check(poor_result["reason"] == "insufficient_resources", "Motivo da falha deve ser insufficient_resources (obtido: %s)" % poor_result["reason"])
	ctx.check(poor_kingdom.get_raw_resource("cristais_arcanos") == before_cristais, "Recursos não devem ser gastos parcialmente numa falha tudo-ou-nada")

	return true
