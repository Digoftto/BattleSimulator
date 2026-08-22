class_name TestMineGuarnicaoAndProduction
extends RefCounted
## TestMineGuarnicaoAndProduction (F-001, Etapa 17)
##
## Migrado de bootstrap.gd:_validate_mine_guarnicao_and_production().
## Mesmo cenário original — trava anti-exploit da Guarnição
## (MineGuarnicaoResolver) e produção horária creditada no Depósito via
## GameRuntime.sync() (MiningProductionResolver). Usa Kingdom.new() e
## Mina.new() locais — sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/WorldBootstrap, direta ou transitiva.
## GameRuntime.sync() recebe o Kingdom local explicitamente como
## parâmetro (não lê nenhum singleton). Nenhuma RNG envolvida — nenhum
## dos resolvers usados (MineGuarnicaoResolver, MiningProductionResolver)
## referencia RandomNumberGenerator/randi/randf em sua fonte. Nenhuma
## seed foi adicionada, nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando trava da Guarnição e produção creditada via GameRuntime.sync()...")

	var kingdom := Kingdom.new()
	kingdom.deposito_level = 1

	var mina := Mina.new(1500, "Império")  # Região I -> recurso Ferro Negro
	mina.region = 1
	mina.structure_level = 1  # Produção Base Região 1 Nível 1 = 5/hora
	kingdom.territory_mines["Território de Teste"] = [mina]

	var army: Army = CampaignTestFixtures.build_campaign_test_army({})
	var now: int = GameClock.now_unix()

	# Bloqueio: Mina ainda não conquistada.
	var blocked_result: Dictionary = MineGuarnicaoResolver.assign(mina, army, now)
	print("  Designar Guarnição antes da conquista -> sucesso? %s | motivo: %s (esperado: false, not_conquered)" % [
		str(blocked_result["success"]), blocked_result["reason"]
	])
	ctx.check(blocked_result["success"] == false, "Designar Guarnição antes da conquista deve falhar")
	ctx.check(blocked_result["reason"] == "not_conquered", "Motivo da falha deve ser 'not_conquered' (obtido: %s)" % blocked_result["reason"])

	mina.conquer()
	var success_result: Dictionary = MineGuarnicaoResolver.assign(mina, army, now)
	print("  Designar Guarnição após a conquista -> sucesso? %s | Exército travado? %s (esperado: true, true)" % [
		str(success_result["success"]), str(army.availability == Army.Availability.GUARNICAO_MINA)
	])
	ctx.check(success_result["success"] == true, "Designar Guarnição após a conquista deve ter sucesso")
	ctx.check(army.availability == Army.Availability.GUARNICAO_MINA, "Exército designado deve ficar travado como GUARNICAO_MINA")

	# F-045: minas_panel.gd._on_assign_guarnicao_pressed() chama
	# refresh() -> GameRuntime.sync() imediatamente após uma designação
	# bem-sucedida, ANTES de o jogador clicar em "Iniciar Ciclo"
	# (passos 4 e 5 separados de MINES.md, botões distintos no painel
	# real). Antes desta correção, MineGuarnicaoResolver.release_if_cycle_ended()
	# tratava "Ciclo nunca iniciado" igual a "Ciclo já terminado" e
	# liberava a Guarnição de volta pra AVAILABLE nesse mesmo sync — sem
	# nenhuma ação do jogador, violando a trava anti-exploit documentada
	# (COMMAND_CENTER_UI.md: "Só Exércitos livres... podem ser
	# designados").
	GameRuntime.sync(kingdom, now)
	print("  Após designar (sync antes de Iniciar Ciclo, como o painel real faz via refresh()) -> Exército continua travado? %s (esperado: true)" % str(
		army.availability == Army.Availability.GUARNICAO_MINA
	))
	ctx.check(army.availability == Army.Availability.GUARNICAO_MINA, "GameRuntime.sync() chamado antes de Iniciar Ciclo NUNCA deve liberar uma Guarnição recém-designada")

	var other_army: Army = CampaignTestFixtures.build_campaign_test_army({})

	mina.start_cycle(now, 1.0)  # Eficiência 100%
	var cycle_active_result: Dictionary = MineGuarnicaoResolver.assign(mina, other_army, now)
	print("  Tentar redesignar com Ciclo ativo -> sucesso? %s | motivo: %s (esperado: false, cycle_active)" % [
		str(cycle_active_result["success"]), cycle_active_result["reason"]
	])
	ctx.check(cycle_active_result["success"] == false, "Redesignar Guarnição com Ciclo ativo deve falhar")
	ctx.check(cycle_active_result["reason"] == "cycle_active", "Motivo da falha deve ser 'cycle_active' (obtido: %s)" % cycle_active_result["reason"])

	# Produção creditada via GameRuntime.sync(): 3 horas decorridas,
	# Produção Base 5/hora × Eficiência 100% = 5/hora -> 15 ao todo.
	var three_hours_later: int = now + (3 * 3600)
	MiningProductionResolver.credit(mina, kingdom, three_hours_later)
	var ferro_after_3h: int = kingdom.get_raw_resource("ferro_negro")
	print("  Após 3h de Ciclo ativo (5/hora x 100%%) -> Ferro Negro no Reino: %d (esperado: 15)" % ferro_after_3h)
	ctx.check(ferro_after_3h == 15, "Ferro Negro após 3h de Ciclo ativo deve ser 15 (obtido: %d)" % ferro_after_3h)

	# Capacidade do Depósito no Nível 1 (24) é bem menor que a produção
	# do ciclo inteiro (500) — o teto entra em ação de verdade aqui.
	var end_of_cycle: int = now + Mina.CYCLE_DURATION_SECONDS + 10  # além do fim do ciclo
	MiningProductionResolver.credit(mina, kingdom, end_of_cycle)
	var ferro_after_full_cycle: int = kingdom.get_raw_resource("ferro_negro")
	print("  Produção total do ciclo (100h x 5/hora = 500) limitada pela capacidade do Depósito -> Ferro Negro: %d (esperado: 24, nunca ultrapassa)" % ferro_after_full_cycle)
	ctx.check(ferro_after_full_cycle == 24, "Ferro Negro creditado nunca deve ultrapassar a capacidade do Depósito (esperado: 24, obtido: %d)" % ferro_after_full_cycle)

	# GameRuntime.sync() libera a Guarnição automaticamente quando o
	# Ciclo termina — sem precisar de nenhuma chamada manual extra.
	GameRuntime.sync(kingdom, end_of_cycle)
	var released: bool = army.availability == Army.Availability.AVAILABLE
	print("  Após GameRuntime.sync() com o Ciclo já encerrado -> Exército da Guarnição liberado? %s (esperado: true)" % str(released))
	ctx.check(released, "GameRuntime.sync() deve liberar automaticamente a Guarnição quando o Ciclo termina")

	return true
