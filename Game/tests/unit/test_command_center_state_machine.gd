class_name TestCommandCenterStateMachine
extends RefCounted
## TestCommandCenterStateMachine (F-001, Etapa 12)
##
## Migrado de bootstrap.gd:_validate_command_center_state_machine(). Mesmo
## cenário original — máquina de estados administrativos do Comandante
## (COMMAND_CENTER.md) e Expansão Administrativa em PG
## (COMMAND_CENTER_PROGRESS.md). Usa Kingdom.new() local e
## CommandCenterResolver/CommandCenterProgress (confirmados sem nenhuma
## referência a KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/
## WorldBootstrap, direta ou transitiva).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra. A estrutura exata do Dicionário retornado por
## infrastructure_at_level() ({"ativo": ..., "reserva": ...}) foi
## confirmada lendo o código-fonte de CommandCenterProgress antes de
## escrever a asserção — não inferida do texto do print original.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Centro de Comando] Validando máquina de estados e Expansão Administrativa...")

	var kingdom := Kingdom.new()  # Nível 1 -> Infraestrutura: 1 Ativo, 4 Reserva
	print("  Infraestrutura no Nível 1: %s (esperado: {ativo:1, reserva:4})" % str(
		CommandCenterProgress.infrastructure_at_level(1)
	))
	ctx.check(
		CommandCenterProgress.infrastructure_at_level(1) == {"ativo": 1, "reserva": 4},
		"Infraestrutura no Nível 1 deve ser {ativo: 1, reserva: 4} (obtido: %s)" % str(CommandCenterProgress.infrastructure_at_level(1))
	)

	# Ativação: sempre Ativo primeiro, depois Reserva.
	kingdom.add_generation_points(1)
	var activation_1: Dictionary = CommandCenterResolver.activate_next(kingdom)
	print("  1ª ativação -> tipo: %s | Cargo Ativo ativado: %d (esperado: ativo, 1)" % [
		activation_1["type"], kingdom.cargo_ativo_activated
	])
	# NOTA (Etapa 12): o comentário original "(esperado: ativo, 1)" está
	# desatualizado em relação ao comportamento real e correto do motor —
	# Kingdom.cargo_ativo_activated já nasce em 1 (o Cargo Ativo inicial
	# do Nível 1 já vem pré-ativado, ver kingdom.gd:218), então
	# infrastructure_at_level(1)["ativo"] (1) - cargo_ativo_activated (1)
	# = 0 pendentes -> activate_next() corretamente cai para "reserva" já
	# na 1ª chamada. Confirmado por rastreamento direto do código-fonte
	# (CommandCenterResolver.activate_next()), não presumido. A
	# expectativa de tipo "ativo" nunca foi real; não convertida em
	# asserção, para não travar num falso positivo de um comentário
	# desatualizado (mesma categoria do achado "4 -> 4" da Etapa 7).
	ctx.check(kingdom.cargo_ativo_activated == 1, "Cargo Ativo ativado deve ser 1 (obtido: %d)" % kingdom.cargo_ativo_activated)

	kingdom.add_generation_points(1)
	var activation_2: Dictionary = CommandCenterResolver.activate_next(kingdom)
	print("  2ª ativação (Ativo do Nível 1 já esgotado) -> tipo: %s (esperado: reserva)" % activation_2["type"])
	ctx.check(activation_2["type"] == "reserva", "2ª ativação deve ser do tipo 'reserva' (obtido: %s)" % activation_2["type"])

	# Comandante novo: entra em Reserve, não pode liderar Exército ainda.
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Teste (Estados)"
	commander.faction = "Império"
	kingdom.add_commander(commander)
	print("  Estado inicial: %s (esperado: RESERVE)" % CommanderResource.AdministrativeState.keys()[commander.administrative_state])
	ctx.check(commander.administrative_state == CommanderResource.AdministrativeState.RESERVE, "Comandante recém-registrado deve começar em RESERVE")

	var promote: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	print("  Promover a Ativo (1 Cargo já ativado) -> sucesso? %s (esperado: true)" % str(promote["success"]))
	ctx.check(promote["success"] == true, "Promover a Ativo com Cargo disponível deve ter sucesso")

	var second_commander := CommanderResource.new()
	second_commander.commander_name = "2º Comandante (sem Cargo livre)"
	second_commander.faction = "Império"
	kingdom.add_commander(second_commander)
	var promote_fail: Dictionary = CommandCenterResolver.move_to_active(kingdom, second_commander)
	print("  Promover um 2º Comandante (só 1 Cargo Ativo ativado, já ocupado) -> sucesso? %s | motivo: %s (esperado: false, no_cargo_ativo_available)" % [
		str(promote_fail["success"]), promote_fail["reason"]
	])
	ctx.check(promote_fail["success"] == false, "Promover sem Cargo Ativo disponível deve falhar")
	ctx.check(promote_fail["reason"] == "no_cargo_ativo_available", "Motivo da falha deve ser no_cargo_ativo_available (obtido: %s)" % promote_fail["reason"])

	# Treinamento: Nível 1 do CdC ainda não desbloqueou (precisa Nível 3).
	var now_for_training: int = GameClock.now_unix()
	var train_blocked: Dictionary = CommandCenterResolver.move_to_training(kingdom, second_commander, now_for_training)
	print("  Mandar pro Treinamento sem vagas (CdC Nível 1, desbloqueia no 3) -> sucesso? %s | motivo: %s (esperado: false, no_training_slot_available)" % [
		str(train_blocked["success"]), train_blocked["reason"]
	])
	ctx.check(train_blocked["success"] == false, "Mandar para Treinamento sem vaga desbloqueada deve falhar")
	ctx.check(train_blocked["reason"] == "no_training_slot_available", "Motivo da falha deve ser no_training_slot_available (obtido: %s)" % train_blocked["reason"])

	kingdom.command_center_level = 3
	var train_success: Dictionary = CommandCenterResolver.move_to_training(kingdom, second_commander, now_for_training)
	print("  Mandar pro Treinamento (CdC Nível 3, 1 vaga) -> sucesso? %s (esperado: true)" % str(train_success["success"]))
	ctx.check(train_success["success"] == true, "Mandar para Treinamento com vaga disponível deve ter sucesso")

	# Comandante em Treinamento nunca pode liderar Exército (não é Ativo).
	print("  Comandante em Treinamento disponível pra liderar Exército? %s (esperado: false)" % str(
		kingdom.is_commander_available(second_commander)
	))
	ctx.check(kingdom.is_commander_available(second_commander) == false, "Comandante em Treinamento não deve estar disponível para liderar Exército")

	var back_to_reserve: Dictionary = CommandCenterResolver.move_to_reserve(kingdom, second_commander)
	print("  Voltar do Treinamento pra Reserve -> sucesso? %s | Estado: %s (esperado: true, RESERVE)" % [
		str(back_to_reserve["success"]), CommanderResource.AdministrativeState.keys()[second_commander.administrative_state]
	])
	ctx.check(back_to_reserve["success"] == true, "Voltar do Treinamento para Reserve deve ter sucesso")
	ctx.check(second_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE, "Estado deve voltar para RESERVE")

	# Aposentadoria.
	var retire_result: Dictionary = CommandCenterResolver.retire(kingdom, commander)
	print("  Aposentar o 1º Comandante -> sucesso? %s | Estado: %s (esperado: true, RETIRED)" % [
		str(retire_result["success"]), CommanderResource.AdministrativeState.keys()[commander.administrative_state]
	])
	ctx.check(retire_result["success"] == true, "Aposentar um Comandante Ativo deve ter sucesso")
	ctx.check(commander.administrative_state == CommanderResource.AdministrativeState.RETIRED, "Estado deve ser RETIRED após aposentadoria")

	var retire_again: Dictionary = CommandCenterResolver.retire(kingdom, commander)
	print("  Aposentar de novo o mesmo Comandante -> sucesso? %s | motivo: %s (esperado: false, already_retired)" % [
		str(retire_again["success"]), retire_again["reason"]
	])
	ctx.check(retire_again["success"] == false, "Aposentar um Comandante já aposentado deve falhar")
	ctx.check(retire_again["reason"] == "already_retired", "Motivo da falha deve ser already_retired (obtido: %s)" % retire_again["reason"])

	return true
