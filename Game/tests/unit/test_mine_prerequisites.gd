class_name TestMinePrerequisites
extends RefCounted
## TestMinePrerequisites (F-001, Etapa 17)
##
## Migrado de bootstrap.gd:_validate_mine_prerequisites(). Mesmo cenário
## original — pré-requisitos de Minas (produção base, custo em PG,
## capacidade dos Depósitos, armazenamento de recursos brutos no Reino).
## NÃO valida o Ciclo de Mineração, a Guarnição da Mina nem a simulação
## das 9! combinações — todos bloqueados por decisões de design ainda
## pendentes (mesma nota do original). Usa Kingdom.new() local — sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva. Nenhuma RNG
## envolvida (MineEconomy/Deposits são fórmulas puras). Nenhuma seed foi
## adicionada, nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra. Os dois loops de Produção Base (Mina Inicial e Região 1)
## eram puramente narrativos no original (sem "(esperado: X)") — preservados
## como print, sem inventar asserção nova só para aumentar a contagem.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando pré-requisitos: produção, custo em PG, capacidade dos Depósitos...")

	# Produção Base — Mina Inicial (geométrica: 5, 10, 20, 40/hora).
	var initial_mine_level_1: int = MineEconomy.base_production_per_hour(MineEconomy.Region.MINA_INICIAL, 1)
	print("  Mina Inicial Nível 1 -> Produção Base: %d/hora (esperado: 5)" % initial_mine_level_1)
	ctx.check(initial_mine_level_1 == 5, "Mina Inicial Nível 1 deve produzir 5 Recursos/hora (FORMULAS.md, obtido: %d)" % initial_mine_level_1)
	for level in range(1, 5):
		print("  Mina Inicial Nível %d -> Produção Base: %d/hora" % [
			level, MineEconomy.base_production_per_hour(MineEconomy.Region.MINA_INICIAL, level)
		])

	# Nenhuma Mina Regional foi alterada por esta mudança (Região 1
	# continua 5/10/15/20/25, Região 2 continua 10/20/30/40/50).
	ctx.check(MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_1, 1) == 5, "Região 1 Nível 1 não deve ter sido alterada (esperado: 5)")
	ctx.check(MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_2, 1) == 10, "Região 2 Nível 1 não deve ter sido alterada (esperado: 10)")
	ctx.check(MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_3, 1) == 20, "Região 3 Nível 1 não deve ter sido alterada (esperado: 20)")

	# Produção Base — Região 1 (aritmética: 5, 10, 15, 20, 25/hora).
	for level in range(1, 6):
		print("  Região 1 Nível %d -> Produção Base: %d/hora" % [
			level, MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_1, level)
		])

	# Eficiência da Guarnição aplicada à Produção Base.
	var base: int = MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_2, 3)  # 30/hora
	var effective_production: int = MineEconomy.hourly_production(base, 0.5)
	print("  Região 2 Nível 3 (Base 30/hora) com Empate (50%%) -> Produção Efetiva: %d/hora (esperado: 15)" % effective_production)
	ctx.check(effective_production == 15, "Produção Efetiva com Empate (50%%) deve ser 15/hora (obtido: %d)" % effective_production)

	# Custo em PG com escalonamento por bloco de 10 níveis.
	var cost_5: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 5)
	print("  Custo Região 3 até Nível 5 (bloco 1x): %d PG (esperado: 3)" % cost_5)
	ctx.check(cost_5 == 3, "Custo Região 3 até Nível 5 deve ser 3 PG (obtido: %d)" % cost_5)

	var cost_15: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 15)
	print("  Custo Região 3 até Nível 15 (bloco 1,5x): %d PG (esperado: ceil(3×1,5)=5)" % cost_15)
	ctx.check(cost_15 == 5, "Custo Região 3 até Nível 15 deve ser 5 PG (obtido: %d)" % cost_15)

	var cost_25: int = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 25)
	print("  Custo Região 3 até Nível 25 (bloco 2,25x): %d PG (esperado: ceil(3×2,25)=7)" % cost_25)
	ctx.check(cost_25 == 7, "Custo Região 3 até Nível 25 deve ser 7 PG (obtido: %d)" % cost_25)

	# Capacidade do Depósito (130% do custo por Recurso que a Capital
	# precisa para o próximo nível).
	for level in range(1, 4):
		print("  Depósito Nível %d -> Capacidade: %d" % [
			level, Deposits.storage_capacity(level)
		])
	var capacity_curve_ok: bool = (
		Deposits.storage_capacity(1) == 24 and Deposits.storage_capacity(7) == 17496 and Deposits.storage_capacity(8) == 29160
	)
	print("  Nível 1 = 24, Nível 7 = 17.496 (fim da geométrica x3), Nível 8 = 29.160 (início da PA)? %s (esperado: true)" % str(capacity_curve_ok))
	ctx.check(capacity_curve_ok, "Capacidade do Depósito deve seguir a curva Nível 1=24, Nível 7=17496, Nível 8=29160")

	# Armazenamento de recursos brutos no Reino, respeitando a
	# capacidade do Depósito (nunca ultrapassa, sobra é reportada).
	var kingdom := Kingdom.new()
	var capacity: int = Deposits.storage_capacity(1)
	var overflow: int = kingdom.credit_raw_resource("ferro_negro", capacity + 500, capacity)
	var stored: int = kingdom.get_raw_resource("ferro_negro")
	print("  Creditar além da capacidade (%d) -> Armazenado: %d | Perdido: %d (esperado: %d, 500)" % [
		capacity + 500, stored, overflow, capacity
	])
	ctx.check(stored == capacity, "Armazenado não deve ultrapassar a capacidade do Depósito (esperado: %d, obtido: %d)" % [capacity, stored])
	ctx.check(overflow == 500, "Perdido por overflow deve ser exatamente 500 (obtido: %d)" % overflow)

	return true
