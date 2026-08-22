class_name TestExpeditionSessionWaitsForPlayer
extends RefCounted
## TestExpeditionSessionWaitsForPlayer (F-001, Etapa 18)
##
## Migrado de bootstrap.gd:_validate_expedition_session_waits_for_player().
## Mesmo cenário original — ExpeditionSession nunca decide por conta
## própria retomar uma Expedição parada aguardando o jogador (política
## AGUARDAR_ORDEM); ela para e reporta o motivo, sem inventar uma decisão
## que ninguém tomou. Depois de resume_from_acampamento() (decisão
## externa explícita), a Sessão volta a avançar normalmente. Usa
## Territory.new()/Trilha.new()/CampaignTestFixtures locais — nenhuma
## referência a KingdomState.kingdom no texto desta função.
##
## NOTA DE ARQUITETURA (achado do audit de Stage 17/18, não resolvido
## aqui): ExpeditionRuntime.attempt_current_fase() lê/escreve
## KingdomState.kingdom internamente em caso de vitória (fragmentos/XP),
## mesmo sem receber nenhum Kingdom por parâmetro — ExpeditionSession.run()
## chama attempt_current_fase() por baixo dos panos. test_main.gd já
## chama KingdomState.initialize_new_kingdom() antes de rodar qualquer
## suíte exatamente por causa desse acoplamento (ver comentário em
## test_main.gd:_ready()), então essa migração não introduz nenhum
## comportamento novo nem exige nenhuma mudança de infraestrutura — só
## reaproveita a inicialização que já existe para todas as suítes. A
## decisão arquitetural de desacoplar ExpeditionRuntime de
## KingdomState.kingdom continua adiada.
##
## RNG: combate resolvido via PhaseResolver/CombatEngine dentro de
## attempt_current_fase() — RNG estruturalmente inerte (CombatState.rng só
## é consultado pelo sorteio de Campo de Batalha, cujo Efeito não é
## aplicado nesta Sprint; a fixture de CampaignTestFixtures usada aqui não
## inclui cartas com Habilidade). Seed da Expedição (7) preservada exatamente
## como no original. Nenhuma alteração em Game/engine/.
##
## O primeiro "(esperado: X)" do original foi convertido em asserção real.
## O segundo print (Fase/motivo após resume_from_acampamento()) já era
## puramente narrativo no original, sem valor esperado fixo — preservado
## como print, sem inventar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[ExpeditionSession] Validando que a Sessão nunca decide sozinha por 'Aguardar Ordem'...")

	var territory := Territory.new("Territorio-Sessao-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		Squad.new([winning_army]), trilha, territory, catalog, registry, 7,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_ORDEM
	expedition.current_fase = 24  # a Fase 25 é Acampamento (ver Sprint 30)

	var stop_reason: ExpeditionSession.StopReason = ExpeditionSession.run(expedition, 5)
	print("  Sessão parou por: %s (esperado: AGUARDANDO_JOGADOR) | Fase atual: %d" % [
		ExpeditionSession.StopReason.keys()[stop_reason], expedition.current_fase
	])
	ctx.check(stop_reason == ExpeditionSession.StopReason.AGUARDANDO_JOGADOR, "Sessão deve parar por AGUARDANDO_JOGADOR ao chegar num Acampamento com política AGUARDAR_ORDEM (obtido: %s)" % ExpeditionSession.StopReason.keys()[stop_reason])

	expedition.resume_from_acampamento()
	var stop_reason_2: ExpeditionSession.StopReason = ExpeditionSession.run(expedition, 5)
	print("  Após decisão explícita do jogador (resume_from_acampamento) -> Sessão avançou novamente. Motivo: %s | Fase atual: %d" % [
		ExpeditionSession.StopReason.keys()[stop_reason_2], expedition.current_fase
	])

	return true
