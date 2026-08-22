class_name TestInitialMineNeverExpires
extends RefCounted
## TestInitialMineNeverExpires (F-001, Etapa 13)
##
## Migrado de bootstrap.gd:_validate_initial_mine_never_expires(). Mesmo
## cenário original — validação FUNCIONAL do bug real relatado: Mina
## Inicial nunca deve "expirar" mostrando um Ciclo de 100h (MINES.md,
## "Mina Inicial (Bootstrap)": produção contínua, sem prazo). Testado bem
## além das 100h pra confirmar que continua ativa. Usa Kingdom.new()
## local, Mina/MiningProductionResolver/MineEconomy — confirmados sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando que a Mina Inicial nunca expira (bug relatado: mostrava Ciclo de 100h)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var mina: Mina = kingdom.initial_mines[0]
	var start: int = GameClock.now_unix()
	mina.start_cycle(start, 1.0)

	var far_future: int = start + (200 * 3600)  # 200h no futuro — bem além das 100h de um Ciclo normal
	print("  Mina Inicial continua ativa 200h depois (Minas de Trilha teriam expirado em 100h)? %s (esperado: true)" % str(
		mina.is_cycle_active(far_future)
	))
	ctx.check(mina.is_cycle_active(far_future) == true, "Mina Inicial deve continuar ativa 200h depois, sem expirar")

	MiningProductionResolver.credit(mina, kingdom, far_future)
	var resource_name: String = MineEconomy.resource_for_faction(mina.faction)
	print("  Produção creditada de verdade além das 100h, sem travar num teto? %s (%d %s, esperado: true, > 0)" % [
		str(kingdom.get_raw_resource(resource_name) > 0), kingdom.get_raw_resource(resource_name), resource_name
	])
	ctx.check(kingdom.get_raw_resource(resource_name) > 0, "Produção deve ser creditada além das 100h, sem travar num teto (obtido: %d)" % kingdom.get_raw_resource(resource_name))

	return true
