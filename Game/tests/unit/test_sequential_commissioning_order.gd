class_name TestSequentialCommissioningOrder
extends RefCounted
## TestSequentialCommissioningOrder (F-001, Etapa 13)
##
## Migrado de bootstrap.gd:_validate_sequential_commissioning_order().
## Mesmo cenário original — validação FUNCIONAL da Ordem de
## Comissionamento (COMMAND_CENTER_RECRUITMENT.md, nova regra): o jogador
## não pode pular a ordem de chegada, só pode comissionar o primeiro Slot
## ocupado. Usa Kingdom.new() local e RecruitmentCenterResolver
## (confirmado sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou transitiva).
##
## kingdom.vaga_reserva_activated = 2 é setup explícito do teste original
## (comentário: "garante vaga suficiente pros 2 comissionamentos do
## teste — não é isso que está sendo testado aqui") — preservado
## exatamente como estava.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Comandantes] Validando a Ordem de Comissionamento sequencial (nova regra)...")

	var kingdom := Kingdom.new()
	kingdom.vaga_reserva_activated = 2  # garante vaga suficiente pros 2 comissionamentos do teste — não é isso que está sendo testado aqui
	var first_candidate := CommanderResource.new()
	first_candidate.commander_name = "Candidato 1 (chegou primeiro)"
	var second_candidate := CommanderResource.new()
	second_candidate.commander_name = "Candidato 2 (chegou depois)"
	kingdom.recruitment_center_slots = [first_candidate, second_candidate, null]

	var skip_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 1, GameClock.now_unix())
	print("  Tentar comissionar o 2º Slot antes do 1º -> bloqueado com motivo claro? %s ('%s', esperado: false, not_first_occupied_slot)" % [
		str(not skip_result["success"]), skip_result["reason"]
	])
	ctx.check(skip_result["success"] == false, "Comissionar o 2º Slot antes do 1º deve ser bloqueado")
	ctx.check(skip_result["reason"] == "not_first_occupied_slot", "Motivo do bloqueio deve ser not_first_occupied_slot (obtido: %s)" % skip_result["reason"])

	print("  O Candidato 2 continua no Slot, intocado? %s (esperado: true)" % str(
		kingdom.recruitment_center_slots[1] == second_candidate
	))
	ctx.check(kingdom.recruitment_center_slots[1] == second_candidate, "Candidato 2 deve continuar intocado no Slot após o bloqueio")

	var in_order_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, GameClock.now_unix())
	print("  Comissionar o 1º Slot (o certo) -> sucesso? %s (esperado: true)" % str(in_order_result["success"]))
	ctx.check(in_order_result["success"] == true, "Comissionar o 1º Slot na ordem correta deve ter sucesso")

	var now_valid_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 1, GameClock.now_unix())
	print("  Depois do 1º liberado, agora o 2º pode ser comissionado? %s (esperado: true)" % str(now_valid_result["success"]))
	ctx.check(now_valid_result["success"] == true, "Após o 1º Slot liberado, o 2º deve poder ser comissionado")

	return true
