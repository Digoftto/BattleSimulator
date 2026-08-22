class_name TestCityDeposits
extends RefCounted
## TestCityDeposits (F-001, Etapa 12)
##
## Migrado de bootstrap.gd:_validate_city_deposits(). Mesmo cenário
## original — custo de evolução do Depósito único (FORMULAS.md: ceil(n/4)
## PG) e o teto institucional da Capital (CAPITAL.md — nenhuma construção
## institucional pode ultrapassar o nível da Capital). Usa um Kingdom.new()
## local e CityResolver/Deposits (confirmados sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap,
## direta ou transitiva).
##
## O teste original já tinha "(esperado: X)" explícito nos pontos-chave —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.
## A tabela de custos por nível (loop inicial) não tinha "esperado"
## explícito e permanece apenas informativa.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Cidade] Validando custo do Depósito (PG) e o teto da Capital...")

	# Tabela de referência de FORMULAS.md ("Depósitos"): 1-4 -> 1 PG,
	# 5-8 -> 2 PG, 9-12 -> 3 PG, 13-16 -> 4 PG, 17-20 -> 5 PG.
	var milestone_targets: Array[int] = [1, 4, 5, 8, 9, 12, 13, 16, 17, 20]
	for target: int in milestone_targets:
		print("  Custo para atingir o nível %d: %d PG" % [target, Deposits.upgrade_cost_pg(target)])

	var kingdom := Kingdom.new()
	print("  Capital inicial: Nível %d | Depósito inicial: Nível %d (esperado: 1, 1)" % [
		kingdom.capital_level, kingdom.deposito_level
	])
	ctx.check(kingdom.capital_level == 1, "Capital inicial deve ser Nível 1 (obtido: %d)" % kingdom.capital_level)
	ctx.check(kingdom.deposito_level == 1, "Depósito inicial deve ser Nível 1 (obtido: %d)" % kingdom.deposito_level)

	# Cidade recém-criada: Depósito já está no nível da Capital (1) ->
	# bloqueado até a própria Capital evoluir (CAPITAL.md).
	var blocked_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Evoluir o Depósito com Capital no Nível 1 -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(blocked_result["success"]), blocked_result["reason"]
	])
	ctx.check(blocked_result["success"] == false, "Evoluir o Depósito no teto da Capital deve falhar")
	ctx.check(blocked_result["reason"] == "capital_limit", "Motivo da falha deve ser capital_limit (obtido: %s)" % blocked_result["reason"])

	# Capital evolui (simulado diretamente, como já é feito para
	# energy_nucleus_level em outras validações) -> Depósito liberado.
	kingdom.capital_level = 2

	var no_pg_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Capital no Nível 2, sem PG -> sucesso? %s | motivo: %s (esperado: false, insufficient_pg)" % [
		str(no_pg_result["success"]), no_pg_result["reason"]
	])
	ctx.check(no_pg_result["success"] == false, "Evoluir sem PG suficiente deve falhar")
	ctx.check(no_pg_result["reason"] == "insufficient_pg", "Motivo da falha deve ser insufficient_pg (obtido: %s)" % no_pg_result["reason"])

	kingdom.add_generation_points(1)
	var success_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Com 1 PG -> sucesso? %s | Depósito agora no Nível: %d | PG restante: %d (esperado: true, 2, 0)" % [
		str(success_result["success"]), kingdom.deposito_level, kingdom.generation_points
	])
	ctx.check(success_result["success"] == true, "Evoluir com PG suficiente deve ter sucesso")
	ctx.check(kingdom.deposito_level == 2, "Depósito deve estar no Nível 2 (obtido: %d)" % kingdom.deposito_level)
	ctx.check(kingdom.generation_points == 0, "PG deve ser gasto por completo (obtido: %d)" % kingdom.generation_points)

	# Depósito (Nível 2) já alcançou a Capital (Nível 2) de novo -> bloqueado.
	var blocked_again: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Depósito alcançou a Capital de novo -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(blocked_again["success"]), blocked_again["reason"]
	])
	ctx.check(blocked_again["success"] == false, "Depósito no teto da Capital de novo deve falhar")
	ctx.check(blocked_again["reason"] == "capital_limit", "Motivo da falha deve ser capital_limit (obtido: %s)" % blocked_again["reason"])

	return true
