class_name TestAcademyQueueUpgrade
extends RefCounted
## TestAcademyQueueUpgrade (F-001, Etapa 14)
##
## Migrado de bootstrap.gd:_validate_academy_queue_upgrade(). Mesmo
## cenário original — compra de capacidade de fila (ACADEMY.md,
## "Melhorias das Filas"): custo em PG, teto por tipo de Mestre, e o
## efeito real de destravar uma 2ª tarefa simultânea na fila do mesmo
## Mestre. Usa Kingdom.new() local e AcademyResolver (confirmado sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Academia] Validando compra de capacidade de fila (PG)...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	kingdom.sync_academy_masters()
	var now: int = GameClock.now_unix()

	var artifice: AcademyMaster = kingdom.academy_artifices[0]
	print("  Capacidade inicial do Artífice: %d (esperado: 1)" % artifice.queue_capacity)
	ctx.check(artifice.queue_capacity == 1, "Capacidade inicial do Artífice deve ser 1 (obtido: %d)" % artifice.queue_capacity)

	var no_pg_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, artifice)
	print("  Tentar upar sem PG -> sucesso? %s | motivo: %s (esperado: false, insufficient_pg)" % [
		str(no_pg_result["success"]), no_pg_result["reason"]
	])
	ctx.check(no_pg_result["success"] == false, "Upar sem PG suficiente deve falhar")
	ctx.check(no_pg_result["reason"] == "insufficient_pg", "Motivo da falha deve ser insufficient_pg (obtido: %s)" % no_pg_result["reason"])

	kingdom.add_generation_points(2)
	var upgrade_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, artifice)
	print("  Upar Artífice pra capacidade 2 (custa 2 PG) -> sucesso? %s | Capacidade agora: %d | PG restante: %d (esperado: true, 2, 0)" % [
		str(upgrade_result["success"]), artifice.queue_capacity, kingdom.generation_points
	])
	ctx.check(upgrade_result["success"] == true, "Upar com PG suficiente deve ter sucesso")
	ctx.check(artifice.queue_capacity == 2, "Capacidade do Artífice deve ser 2 após o upgrade (obtido: %d)" % artifice.queue_capacity)
	ctx.check(kingdom.generation_points == 0, "PG deve ser gasto por completo (obtido: %d)" % kingdom.generation_points)

	# Com capacidade 2, agora cabem 2 tarefas na fila do mesmo Artífice ao mesmo tempo.
	AcademyResolver.request_common_production(kingdom, "Legionário Imperial", 1, now)
	var second_fits: Dictionary = AcademyResolver.request_common_production(kingdom, "Escudeiro Imperial", 1, now)
	print("  2ª tarefa no mesmo Artífice, agora com capacidade 2 -> sucesso? %s (esperado: true)" % str(second_fits["success"]))
	ctx.check(second_fits["success"] == true, "2ª tarefa deve caber na fila com capacidade 2")

	# Teto do Metamorfo é 4 (só 3 degraus: 2, 3, 4).
	var metamorfo: AcademyMaster = kingdom.academy_metamorfos[0]
	kingdom.add_generation_points(2 + 8 + 32)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	print("  Metamorfo após 3 upgrades -> Capacidade: %d (esperado: 4, teto)" % metamorfo.queue_capacity)
	ctx.check(metamorfo.queue_capacity == 4, "Metamorfo deve atingir o teto de capacidade 4 após 3 upgrades (obtido: %d)" % metamorfo.queue_capacity)

	var over_cap_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	print("  Tentar upar o Metamorfo além do teto -> sucesso? %s | motivo: %s (esperado: false, max_capacity_reached)" % [
		str(over_cap_result["success"]), over_cap_result["reason"]
	])
	ctx.check(over_cap_result["success"] == false, "Upar além do teto de capacidade deve falhar")
	ctx.check(over_cap_result["reason"] == "max_capacity_reached", "Motivo da falha deve ser max_capacity_reached (obtido: %s)" % over_cap_result["reason"])

	return true
