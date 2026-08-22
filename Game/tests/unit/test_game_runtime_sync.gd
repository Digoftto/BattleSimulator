class_name TestGameRuntimeSync
extends RefCounted
## TestGameRuntimeSync (F-001, Etapa 10)
##
## Migrado de bootstrap.gd:_validate_game_runtime_sync(). Mesmo cenário
## original — o coordenador único de tempo real: uma única chamada a
## GameRuntime.sync() deve, ao mesmo tempo, purgar uma Oferta de
## Recrutamento vencida E recuperar Energia de um Exército do Reino, sem
## que a tela precise conhecer ou chamar cada sistema separadamente. Usa
## timestamps simulados (passado), mesmo padrão de outras validações de
## tempo já migradas.
##
## GameRuntime.sync(kingdom, now_unix) opera exclusivamente sobre o
## "kingdom" recebido por parâmetro — confirmado sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/WorldBootstrap. O Reino
## de teste é um Kingdom.new() local, sem Minas (nenhuma chamada a
## create_initial_mines()), portanto o laço de Minas dentro de sync()
## não itera nada e o gatilho de WorkerThreadPool (Estimativa Incremental
## de Eficiência) nunca é alcançado — preservado exatamente como no
## cenário original, sem alterar a API de produção.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[GameRuntime] Validando sync() como coordenador único de tempo real...")

	var nucleus_level: int = 1
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(nucleus_level)
	var now: int = GameClock.now_unix()

	var kingdom := Kingdom.new()
	kingdom.energy_nucleus_level = nucleus_level

	# Exército do Reino com Energia parcial e sincronização "no passado"
	# — deve recuperar pontos ao sincronizar.
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(nucleus_level)
	army.consume_energy(10)
	army.last_energy_sync_unix = now - (seconds_per_point * 3)  # 3 pontos de atraso
	kingdom.add_army(army)

	# Oferta de Recrutamento vencida há mais de 4 dias.
	var expired_commander := CommanderResource.new()
	expired_commander.commander_name = "Comandante Expirado (Sync)"
	var four_days_seconds: int = RecruitmentOffer.VALIDITY_DAYS * 24 * 60 * 60
	kingdom.offer_recruitment(expired_commander, now - four_days_seconds - 10)

	print("  Antes do sync -> Energia: %d/%d | Ofertas pendentes: %d" % [
		army.current_energy, army.max_energy, kingdom.pending_recruitment_offers.size()
	])

	GameRuntime.sync(kingdom, now)

	print("  Após 1 chamada a GameRuntime.sync() -> Energia: %d/%d (esperado: +3 pontos) | Ofertas pendentes: %d (esperado: 0, purgada)" % [
		army.current_energy, army.max_energy, kingdom.pending_recruitment_offers.size()
	])
	ctx.check(army.current_energy == army.max_energy - 10 + 3, "GameRuntime.sync() deve recuperar exatamente os 3 pontos de atraso (obtido: %d, esperado: %d)" % [army.current_energy, army.max_energy - 10 + 3])
	ctx.check(kingdom.pending_recruitment_offers.size() == 0, "GameRuntime.sync() deve purgar a Oferta vencida (obtido: %d Ofertas pendentes)" % kingdom.pending_recruitment_offers.size())

	print("  Aviso de expiração registrado no Reino? %s (esperado: true)" % str(
		not kingdom.expired_recruitment_notifications.is_empty()
	))
	ctx.check(not kingdom.expired_recruitment_notifications.is_empty(), "GameRuntime.sync() deve registrar o aviso de expiração no Reino")

	return true
