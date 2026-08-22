class_name TestRecruitmentOfferExpiration
extends RefCounted
## TestRecruitmentOfferExpiration (F-001, Etapa 7)
##
## Migrado de bootstrap.gd:_validate_recruitment_offer_expiration().
## Mesmo cenário original — expiração de Ofertas de Recrutamento (4 dias
## / 96h, COMMAND_CENTER_RECRUITMENT.md → "Painel PvE" → "Permanência e
## Expiração"): uma oferta criada há mais de 4 dias é purgada sem
## recompensa e gera um aviso para o jogador; uma oferta ainda dentro do
## prazo permanece intocada — usando timestamps simulados (passado),
## exatamente como o original, e um Kingdom.new() local. RecruitmentOffer/
## RecruitmentResolver confirmados sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou
## transitiva.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Recrutamento] Validando expiração de Ofertas (4 dias / 96h)...")

	var now: int = GameClock.now_unix()
	var four_days_seconds: int = RecruitmentOffer.VALIDITY_DAYS * 24 * 60 * 60

	var kingdom := Kingdom.new()

	# Oferta "antiga": criada há mais de 4 dias (simulado) -> deve expirar.
	var expired_commander := CommanderResource.new()
	expired_commander.commander_name = "Comandante Expirado"
	kingdom.offer_recruitment(expired_commander, now - four_days_seconds - 10)

	# Oferta "recente": criada há 1 dia (simulado) -> não deve expirar.
	var recent_commander := CommanderResource.new()
	recent_commander.commander_name = "Comandante Recente"
	kingdom.offer_recruitment(recent_commander, now - 86400)

	print("  Ofertas pendentes antes da purga: %d (esperado: 2)" % kingdom.pending_recruitment_offers.size())
	ctx.check(kingdom.pending_recruitment_offers.size() == 2, "Devem existir 2 Ofertas pendentes antes da purga (obtido: %d)" % kingdom.pending_recruitment_offers.size())

	var purged: Array[RecruitmentOffer] = RecruitmentResolver.purge_expired_offers(kingdom, now)

	print("  Ofertas purgadas: %d (esperado: 1, 'Comandante Expirado')" % purged.size())
	ctx.check(purged.size() == 1, "Exatamente 1 Oferta deve ser purgada (obtido: %d)" % purged.size())
	if not purged.is_empty():
		print("    Nome: %s" % purged[0].commander.commander_name)
		ctx.check(purged[0].commander.commander_name == "Comandante Expirado", "A Oferta purgada deve ser a do Comandante Expirado (obtido: %s)" % purged[0].commander.commander_name)

	print("  Ofertas pendentes após a purga: %d (esperado: 1, só 'Comandante Recente' resta)" % kingdom.pending_recruitment_offers.size())
	ctx.check(kingdom.pending_recruitment_offers.size() == 1, "Deve restar 1 Oferta pendente após a purga (obtido: %d)" % kingdom.pending_recruitment_offers.size())

	print("  Reino recebeu algum Comandante pela expiração? %s (esperado: false — sem recompensa)" % str(
		not kingdom.commanders.is_empty()
	))
	ctx.check(kingdom.commanders.is_empty() == true, "Expiração de Oferta não deve conceder nenhum Comandante ao Reino")

	var notifications: Array[String] = kingdom.consume_expired_recruitment_notifications()
	print("  Aviso pendente para o jogador: %s (esperado: ['Comandante Expirado'])" % str(notifications))
	ctx.check(notifications == ["Comandante Expirado"], "Deve haver exatamente 1 aviso, para o Comandante Expirado (obtido: %s)" % str(notifications))

	var notifications_again: Array[String] = kingdom.consume_expired_recruitment_notifications()
	print("  Consumir de novo -> fila de avisos já vazia? %s (esperado: true)" % str(notifications_again.is_empty()))
	ctx.check(notifications_again.is_empty() == true, "Consumir os avisos de novo deve retornar fila vazia")

	# purge_expired_offers é idempotente: chamar de novo sem tempo adicional não expira a que restou.
	var purged_again: Array[RecruitmentOffer] = RecruitmentResolver.purge_expired_offers(kingdom, now)
	print("  Nova purga imediata -> purgou mais alguma? %s (esperado: false, 'Comandante Recente' ainda dentro do prazo)" % str(
		not purged_again.is_empty()
	))
	ctx.check(purged_again.is_empty() == true, "Purga repetida sem tempo adicional não deve expirar a Oferta restante")

	return true
