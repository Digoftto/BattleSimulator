class_name TestFirstCandidateAvailableImmediately
extends RefCounted
## TestFirstCandidateAvailableImmediately (F-001, Etapa 10)
##
## Migrado de bootstrap.gd:_validate_first_candidate_available_immediately().
## Mesmo cenário original — validação FUNCIONAL da Exceção Inicial
## (COMMAND_CENTER_RECRUITMENT.md): 1 Candidato já deve existir de
## imediato ao criar o Reino, sem esperar as 24h do Cooldown Inicial.
## Usa um Kingdom.new() local — confirmado sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap,
## direta ou transitiva.
##
## O teste original já tinha "(esperado: X)" explícito — convertido
## abaixo em asserção real, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Comandantes] Validando a Exceção Inicial — 1 Candidato disponível assim que o Reino é criado...")

	var fresh_kingdom := Kingdom.new()
	fresh_kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(fresh_kingdom, GameClock.now_unix())

	print("  1 Candidato já existe de imediato, sem precisar de 24h reais? %s (esperado: true)" % str(
		not fresh_kingdom.recruitment_center_slots.is_empty() and fresh_kingdom.recruitment_center_slots[0] != null
	))
	ctx.check(
		not fresh_kingdom.recruitment_center_slots.is_empty() and fresh_kingdom.recruitment_center_slots[0] != null,
		"1 Candidato deve existir imediatamente ao criar o Reino (Exceção Inicial), sem esperar 24h"
	)

	return true
