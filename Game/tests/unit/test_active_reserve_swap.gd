class_name TestActiveReserveSwap
extends RefCounted
## TestActiveReserveSwap (F-001, Etapa 13)
##
## Migrado de bootstrap.gd:_validate_active_reserve_swap(). Mesmo cenário
## original — validação FUNCIONAL da Permuta (COMMAND_CENTER.md, "Permuta
## entre Ativo e Reserva"): resolve o impasse real de Cargo Ativo E Vaga
## da Reserva ambos no limite ao mesmo tempo. Confirmado (Stage 9/11/13)
## como cenário distinto de _validate_swap_active_reserve — este prova
## que a Permuta é NECESSÁRIA (as 2 transições individuais falham
## primeiro), o outro é um teste de regressão mais estreito para um bug
## específico relatado. Não mesclado.
##
## Usa Kingdom.new() local e CommandCenterResolver (confirmado sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva).
##
## kingdom.cargo_ativo_activated = 1 e kingdom.vaga_reserva_activated = 1
## são setup explícito do teste original (redundante com o padrão default
## já confirmado no Stage 12, mas preservado exatamente como estava).
##
## As duas chamadas a move_to_reserve()/move_to_active() do print
## original foram capturadas em variáveis locais antes de montar o
## print/asserção, para preservar exatamente 1 execução de cada (mesma
## semântica do original, que as chamava inline dentro da própria
## string) — sem chamá-las de novo para cada asserção separada.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Comandantes] Validando a Permuta Ativo/Reserva no impasse (Cargo e Vaga ambos 1/1)...")

	var kingdom := Kingdom.new()
	kingdom.cargo_ativo_activated = 1
	kingdom.vaga_reserva_activated = 1

	var active_commander := CommanderResource.new()
	active_commander.commander_name = "Comandante Ativo (Teste Permuta)"
	kingdom.add_commander(active_commander, GameClock.now_unix())
	active_commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE

	var reserve_commander := CommanderResource.new()
	reserve_commander.commander_name = "Comandante Reserva (Teste Permuta)"
	kingdom.add_commander(reserve_commander, GameClock.now_unix())
	reserve_commander.administrative_state = CommanderResource.AdministrativeState.RESERVE

	var reserve_attempt: Dictionary = CommandCenterResolver.move_to_reserve(kingdom, active_commander)
	var active_attempt: Dictionary = CommandCenterResolver.move_to_active(kingdom, reserve_commander)
	print("  Sem Permuta, as 2 transições individuais falham nesse impasse (confirmando que a Permuta é necessária)? %s (esperado: true, true)" % str(
		not reserve_attempt["success"] and not active_attempt["success"]
	))
	ctx.check(reserve_attempt["success"] == false, "move_to_reserve() sozinho deve falhar no impasse 1/1")
	ctx.check(active_attempt["success"] == false, "move_to_active() sozinho deve falhar no impasse 1/1")

	var result: Dictionary = CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	print("  Permuta bem-sucedida? %s | Reserva virou Ativo? %s | Ativo virou Reserva? %s (esperado: true, true, true)" % [
		str(result["success"]),
		str(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE),
		str(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE)
	])
	ctx.check(result["success"] == true, "Permuta Ativo/Reserva deve ter sucesso no impasse")
	ctx.check(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE, "Comandante da Reserva deve virar Ativo após a Permuta")
	ctx.check(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE, "Comandante Ativo deve virar Reserva após a Permuta")

	return true
