class_name TestSwapActiveReserve
extends RefCounted
## TestSwapActiveReserve (F-001, Etapa 13)
##
## Migrado de bootstrap.gd:_validate_swap_active_reserve(). Mesmo cenário
## original — validação FUNCIONAL do bug real relatado: com Cargo Ativo e
## Vaga da Reserva ambos no limite (1/1), o botão "Trocar" (já existente
## na tela, mas chamando uma função que nunca existiu de verdade) não
## fazia nada. Corrigido. Confirmado (Stage 9/11/13) como cenário
## distinto de _validate_active_reserve_swap — não mesclado.
##
## Usa Kingdom.new() local e CommandCenterResolver (confirmado sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva).
##
## O teste original só tinha "(esperado: X)" explícito nos 2 prints
## finais — o print "Estado antes" não tinha marcador de expectativa
## explícito no original e permanece apenas informativo, sem virar
## asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Comandantes] Validando a troca Ativo <-> Reserva no limite (1/1) — bug relatado...")

	var kingdom := Kingdom.new()
	var active_commander := CommanderResource.new()
	active_commander.commander_name = "Comandante Ativo (Teste Troca)"
	active_commander.faction = "Império"
	kingdom.add_commander(active_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated = 1
	CommandCenterResolver.move_to_active(kingdom, active_commander)

	var reserve_commander := CommanderResource.new()
	reserve_commander.commander_name = "Comandante Reserva (Teste Troca)"
	reserve_commander.faction = "Natureza"
	kingdom.add_commander(reserve_commander, GameClock.now_unix())
	kingdom.vaga_reserva_activated = 1

	print("  Estado antes: Ativo=%s | Reserva=%s (esperado: ACTIVE, RESERVE)" % [
		CommanderResource.AdministrativeState.keys()[active_commander.administrative_state],
		CommanderResource.AdministrativeState.keys()[reserve_commander.administrative_state]
	])

	var result: Dictionary = CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	print("  Troca no limite (1/1 dos dois lados) -> sucesso? %s (esperado: true)" % str(result["success"]))
	ctx.check(result["success"] == true, "Troca Ativo/Reserva no limite 1/1 deve ter sucesso")

	print("  Estado depois: antigo Ativo agora é Reserva? %s | antigo Reserva agora é Ativo? %s (esperado: true, true)" % [
		str(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE),
		str(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE)
	])
	ctx.check(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE, "Antigo Ativo deve virar Reserva após a troca")
	ctx.check(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE, "Antigo Reserva deve virar Ativo após a troca")

	return true
