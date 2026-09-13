class_name TestAcampamentoDecision
extends RefCounted
## TestAcampamentoDecision (Auditoria pré-pré-alfa — Bloco 1, itens #3/#4)
##
## Cobre a correção definitiva da mecânica do Acampamento (decisão
## explícita do dono do projeto, substituindo o modelo antigo de
## Política pré-configurada por uma escolha real repetida em CADA
## Acampamento — ver ExpeditionRuntime.CampState):
##
## A) Chegada normal apresenta a escolha (AWAITING_DECISION).
## B) CONTINUAR segue com a Energia atual — nunca a recupera.
## C) PARAR mantém a Expedição parada, aguardando Energia real (parcial
##    não libera).
## D) Ao atingir 100% de Energia, a marcha é liberada automaticamente —
##    Energia nunca ultrapassa o máximo; uma 2ª checagem não soma de
##    novo (recuperação não ocorre duas vezes).
## E) A escolha é independente em cada Acampamento (Continuar num,
##    Parar no seguinte).
## F) Derrota (Squad inteiro incapacitado — combate OU Energia esgotada,
##    mesmo branch de código) força parada OBRIGATÓRIA, sem apresentar
##    escolha (Continuar/Parar são no-ops nesse estado) — liberada pelo
##    MESMO mecanismo automático de D.
## G) O estado de decisão (RESTING_UNTIL_FULL e FORCED_UNTIL_FULL)
##    sobrevive a um round-trip real de save/load
##    (KingdomSaveService/ExpeditionPersistenceResolver).
##
## Reaproveita CampaignTestFixtures (mesmo padrão de
## test_acampamento_policies.gd/test_expedition_tick_resolver.gd) — não
## inventa um 2º Exército de teste. Reaproveita EnergyNucleus.recovery_seconds()
## real (nunca uma constante nova) para calcular os tempos exatos de
## recuperação parcial/total usados nas asserções.

const NUCLEUS_LEVEL: int = 1


static func run(ctx: TestRunner.Context) -> bool:
	print("[Acampamento] Validando a decisão Continuar/Parar por Acampamento (auditoria pré-pré-alfa)...")
	_test_a_fresh_arrival_awaits_decision(ctx)
	_test_b_continue_keeps_current_energy(ctx)
	_test_c_stop_waits_for_real_recovery(ctx)
	_test_d_releases_automatically_at_full_energy(ctx)
	_test_e_decision_is_independent_per_acampamento(ctx)
	_test_f_defeat_forces_wait_without_choice(ctx)
	_test_g_camp_state_survives_persistence_roundtrip(ctx)
	return true


static func _build_test_expedition(army: Army) -> ExpeditionRuntime:
	var territory := Territory.new("Territorio-Decisao-Acampamento-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()
	return ExpeditionRuntime.new(
		Squad.new([army]), trilha, territory, catalog, registry, 42,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)


## A: establish_acampamento_and_await_decision() (chamado pelos 2 pontos
## reais de chegada) sempre resulta em AWAITING_DECISION — nunca resolve
## sozinho, não importa a Energia atual.
static func _test_a_fresh_arrival_awaits_decision(ctx: TestRunner.Context) -> void:
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(NUCLEUS_LEVEL)
	var expedition: ExpeditionRuntime = _build_test_expedition(army)

	expedition.establish_acampamento_and_await_decision()
	print("  [A] Chegada normal -> camp_state == AWAITING_DECISION? %s | aguardando? %s (esperado: true, true)" % [
		str(expedition.camp_state == ExpeditionRuntime.CampState.AWAITING_DECISION), str(expedition.is_waiting_at_acampamento)
	])
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.AWAITING_DECISION, "[A] Chegada normal a um Acampamento deve sempre aguardar decisão (AWAITING_DECISION)")
	ctx.check(expedition.is_waiting_at_acampamento, "[A] is_waiting_at_acampamento deve ser true assim que o Acampamento é estabelecido")


## B: CONTINUAR usa a Energia ATUAL, nunca recupera — mesmo com o Squad
## bem abaixo do máximo.
static func _test_b_continue_keeps_current_energy(ctx: TestRunner.Context) -> void:
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(NUCLEUS_LEVEL)
	army.current_energy = 3
	var expedition: ExpeditionRuntime = _build_test_expedition(army)
	expedition.establish_acampamento_and_await_decision()

	expedition.choose_continue_immediately()
	print("  [B] Continuar -> Energia permanece em 3 (nunca recuperada)? %s | camp_state == NONE? %s | aguardando? %s (esperado: true, true, false)" % [
		str(army.current_energy == 3), str(expedition.camp_state == ExpeditionRuntime.CampState.NONE), str(expedition.is_waiting_at_acampamento)
	])
	ctx.check(army.current_energy == 3, "[B] Continuar não pode preencher Energia — deve permanecer no valor atual (obtido: %d)" % army.current_energy)
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.NONE, "[B] Continuar deve encerrar a decisão (camp_state volta a NONE)")
	ctx.check(not expedition.is_waiting_at_acampamento, "[B] Continuar deve liberar a marcha imediatamente")


## C: PARAR nunca libera antes de Energia == máximo, mesmo depois de uma
## recuperação PARCIAL real (Army.sync_energy_recovery(), nunca uma
## fórmula nova).
static func _test_c_stop_waits_for_real_recovery(ctx: TestRunner.Context) -> void:
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(NUCLEUS_LEVEL)
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(NUCLEUS_LEVEL)
	army.current_energy = army.max_energy - 3  # faltam exatamente 3 pontos
	var expedition: ExpeditionRuntime = _build_test_expedition(army)
	expedition.establish_acampamento_and_await_decision()

	expedition.choose_stop_and_rest()
	print("  [C1] Parar -> camp_state == RESTING_UNTIL_FULL? %s | ainda aguardando? %s (esperado: true, true)" % [
		str(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL), str(expedition.is_waiting_at_acampamento)
	])
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL, "[C1] Parar deve transicionar para RESTING_UNTIL_FULL")
	ctx.check(expedition.is_waiting_at_acampamento, "[C1] Parar deve manter a Expedição parada")

	var now: int = 2000000000
	army.last_energy_sync_unix = now
	# Só 1 ponto recuperável (faltam 3) -> não deve liberar.
	var partial_now: int = now + seconds_per_point
	var released_partial: bool = expedition.try_release_camp_wait_if_fully_rested(partial_now, NUCLEUS_LEVEL)
	print("  [C2] Após recuperação PARCIAL (1 de 3 pontos faltantes) -> liberou? %s (esperado: false) | Energia: %d/%d" % [
		str(released_partial), army.current_energy, army.max_energy
	])
	ctx.check(not released_partial, "[C2] Não deve liberar a marcha enquanto Energia < máxima")
	ctx.check(army.current_energy == army.max_energy - 2, "[C2] Deve ter recuperado exatamente 1 ponto real pelo tempo decorrido (obtido: %d, esperado: %d)" % [army.current_energy, army.max_energy - 2])
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL, "[C2] Deve continuar em RESTING_UNTIL_FULL enquanto não estiver plena")


## D: ao atingir Energia == máxima, a marcha é liberada automaticamente
## — nunca ultrapassa o máximo mesmo com tempo excedente — e uma 2ª
## checagem no MESMO instante não soma Energia de novo (idempotência,
## "recuperação não ocorre duas vezes").
static func _test_d_releases_automatically_at_full_energy(ctx: TestRunner.Context) -> void:
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(NUCLEUS_LEVEL)
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(NUCLEUS_LEVEL)
	army.current_energy = army.max_energy - 2
	var expedition: ExpeditionRuntime = _build_test_expedition(army)
	expedition.establish_acampamento_and_await_decision()
	expedition.choose_stop_and_rest()

	var now: int = 3000000000
	army.last_energy_sync_unix = now
	# Tempo EXCEDENTE (10x o necessário) -> nunca deve ultrapassar o máximo.
	var far_future: int = now + (seconds_per_point * 20)
	var released: bool = expedition.try_release_camp_wait_if_fully_rested(far_future, NUCLEUS_LEVEL)
	print("  [D1] Após tempo excedente -> liberou? %s | Energia: %d/%d (nunca > máximo) | camp_state == NONE? %s (esperado: true, ==máximo, true)" % [
		str(released), army.current_energy, army.max_energy, str(expedition.camp_state == ExpeditionRuntime.CampState.NONE)
	])
	ctx.check(released, "[D1] Deve liberar a marcha assim que Energia atinge o máximo")
	ctx.check(army.current_energy == army.max_energy, "[D1] Energia nunca pode ultrapassar o máximo (obtido: %d, máximo: %d)" % [army.current_energy, army.max_energy])
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.NONE, "[D1] Liberação deve encerrar a decisão (camp_state volta a NONE)")
	ctx.check(not expedition.is_waiting_at_acampamento, "[D1] Liberação deve desbloquear a marcha")

	# Uma 2ª chamada (já liberado, camp_state == NONE) é sempre um no-op —
	# nunca reaplica nem soma Energia de novo.
	var energy_before_second_call: int = army.current_energy
	var released_again: bool = expedition.try_release_camp_wait_if_fully_rested(far_future + 999999, NUCLEUS_LEVEL)
	print("  [D2] 2ª checagem (já liberado) -> no-op? %s | Energia inalterada? %s (esperado: false, true)" % [
		str(not released_again), str(army.current_energy == energy_before_second_call)
	])
	ctx.check(not released_again, "[D2] Uma checagem depois de já liberado não deve fazer nada (camp_state já é NONE)")
	ctx.check(army.current_energy == energy_before_second_call, "[D2] Energia não pode ser somada 2 vezes pela mesma janela de tempo")


## E: a escolha é LOCAL a cada Acampamento — Continuar no 1º nunca
## predetermina o 2º, e vice-versa.
static func _test_e_decision_is_independent_per_acampamento(ctx: TestRunner.Context) -> void:
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(NUCLEUS_LEVEL)
	var expedition: ExpeditionRuntime = _build_test_expedition(army)

	# Acampamento 1 -> Continuar.
	expedition.establish_acampamento_and_await_decision()
	expedition.choose_continue_immediately()
	print("  [E1] Acampamento 1 (Continuar) -> camp_state == NONE? %s (esperado: true)" % str(expedition.camp_state == ExpeditionRuntime.CampState.NONE))
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.NONE, "[E1] Após Continuar, a Expedição deve estar livre para o próximo Acampamento")

	# Acampamento 2 (novo, independente) -> Parar.
	expedition.establish_acampamento_and_await_decision()
	print("  [E2] Acampamento 2 (chegada nova) -> apresenta AWAITING_DECISION de novo, mesmo tendo escolhido Continuar no anterior? %s (esperado: true)" % str(expedition.camp_state == ExpeditionRuntime.CampState.AWAITING_DECISION))
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.AWAITING_DECISION, "[E2] Cada novo Acampamento deve apresentar a escolha de novo, independente da anterior")
	expedition.choose_stop_and_rest()
	print("  [E2] Escolheu Parar desta vez -> camp_state == RESTING_UNTIL_FULL? %s (esperado: true)" % str(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL))
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL, "[E2] A escolha de Parar no 2º Acampamento deve ser respeitada mesmo tendo Continuado no 1º")


## F: Squad inteiro incapacitado (derrota em combate OU Energia esgotada
## — mesmo branch de attempt_current_fase(), nunca distinguido aqui)
## força FORCED_UNTIL_FULL sem apresentar escolha — Continuar/Parar são
## no-ops nesse estado, e a liberação automática (mesmo mecanismo de D)
## também se aplica.
static func _test_f_defeat_forces_wait_without_choice(ctx: TestRunner.Context) -> void:
	# Nenhuma Formação configurada -> todas (α..ε) caem no padrão de
	# build_campaign_test_army({}) (Campeão na Posição 9), que perde/empata
	# contra o inimigo fixo de CampaignTestFixtures (comprovado por
	# simulação, ver build_champion_formation()) — Squad inteiro
	# incapacitado após esgotar as 5 tentativas.
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	losing_army.initialize_energy(NUCLEUS_LEVEL)
	var expedition: ExpeditionRuntime = _build_test_expedition(losing_army)

	var result: PhaseResult = expedition.attempt_current_fase()
	print("  [F1] Squad incapacitado -> result.victory == false? %s | camp_state == FORCED_UNTIL_FULL? %s | aguardando? %s (esperado: true, true, true)" % [
		str(not result.victory), str(expedition.camp_state == ExpeditionRuntime.CampState.FORCED_UNTIL_FULL), str(expedition.is_waiting_at_acampamento)
	])
	ctx.check(not result.victory, "[F1] Pré-condição do teste: a Fase deve terminar em derrota")
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.FORCED_UNTIL_FULL, "[F1] Derrota do Squad inteiro deve forçar FORCED_UNTIL_FULL")
	ctx.check(expedition.is_waiting_at_acampamento, "[F1] Derrota do Squad inteiro deve parar a Expedição")

	var energy_before: int = losing_army.current_energy
	expedition.choose_continue_immediately()
	expedition.choose_stop_and_rest()
	print("  [F2] Continuar/Parar chamados numa parada OBRIGATÓRIA -> nenhum efeito (continua FORCED_UNTIL_FULL)? %s | Energia inalterada? %s (esperado: true, true)" % [
		str(expedition.camp_state == ExpeditionRuntime.CampState.FORCED_UNTIL_FULL), str(losing_army.current_energy == energy_before)
	])
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.FORCED_UNTIL_FULL, "[F2] Uma parada OBRIGATÓRIA nunca pode ser resolvida por Continuar/Parar — só por Energia plena")
	ctx.check(losing_army.current_energy == energy_before, "[F2] Nenhuma das duas ações deve mexer na Energia numa parada obrigatória")

	var seconds_per_point: int = EnergyNucleus.recovery_seconds(NUCLEUS_LEVEL)
	var now: int = 4000000000
	losing_army.last_energy_sync_unix = now
	var released: bool = expedition.try_release_camp_wait_if_fully_rested(now + seconds_per_point * losing_army.max_energy, NUCLEUS_LEVEL)
	print("  [F3] Após Energia plena -> FORCED_UNTIL_FULL também é liberado automaticamente? %s (esperado: true)" % str(released))
	ctx.check(released, "[F3] FORCED_UNTIL_FULL deve ser liberado automaticamente pelo mesmo mecanismo de RESTING_UNTIL_FULL, assim que a Energia atingir o máximo")
	ctx.check(losing_army.current_energy == losing_army.max_energy, "[F3] Energia deve estar exatamente no máximo após a liberação (obtido: %d/%d)" % [losing_army.current_energy, losing_army.max_energy])


## G: camp_state sobrevive a um round-trip real de save/load — nunca
## regride para uma escolha CONTINUAR silenciosa (KingdomSaveService/
## ExpeditionPersistenceResolver, mesmo padrão de
## test_kingdom_persistence_expedition_roundtrip.gd).
static func _test_g_camp_state_survives_persistence_roundtrip(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var season_id: String = "Season-Teste-Decisao-Acampamento"
	var territory := Territory.new("Territorio-Decisao-Acampamento-Persistencia", "Império")
	var trilha := Trilha.new(territory.id)
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	catalog.season_id = season_id
	var season := Season.new(season_id)
	season.add_territory(territory, trilha)
	season.enemy_catalog = catalog
	WorldDatabase.register_season(season)

	var kingdom := Kingdom.new()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.army_name = "Exército Decisão Acampamento"
	army.initialize_energy(NUCLEUS_LEVEL)
	kingdom.armies.append(army)
	var squad := Squad.new([army])

	var start_result: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season_id, territory.id, squad, 4242,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	ctx.check(start_result["success"], "[G] Pré-condição: GameRuntime.start_new_expedition() deve ter sucesso (motivo: '%s')" % start_result["reason"])
	var expedition: ExpeditionRuntime = start_result["expedition"]

	# Simula uma parada por escolha (RESTING_UNTIL_FULL) — nunca precisa
	# de um Acampamento real na Trilha pra testar persistência do campo.
	expedition.establish_acampamento_and_await_decision()
	expedition.choose_stop_and_rest()
	ctx.check(expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL, "[G] Pré-condição: deve estar em RESTING_UNTIL_FULL antes de salvar")

	KingdomSaveService.save(kingdom)

	var loaded_kingdom := Kingdom.new()
	var load_ok: bool = KingdomSaveService.load_into(loaded_kingdom)
	ctx.check(load_ok, "[G] load_into() deve retornar sucesso para um save recém-gravado")
	ExpeditionPersistenceResolver.hydrate_pending(loaded_kingdom)
	ctx.check(loaded_kingdom.active_expeditions.size() == 1, "[G] hydrate_pending() deve reconstruir exatamente 1 Expedição real")

	var loaded_expedition: ExpeditionRuntime = loaded_kingdom.active_expeditions[0]
	print("  [G] Após round-trip -> camp_state == RESTING_UNTIL_FULL? %s | ainda aguardando? %s (esperado: true, true — NUNCA vira Continuar sozinho)" % [
		str(loaded_expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL), str(loaded_expedition.is_waiting_at_acampamento)
	])
	ctx.check(loaded_expedition.camp_state == ExpeditionRuntime.CampState.RESTING_UNTIL_FULL, "[G] camp_state == RESTING_UNTIL_FULL deve sobreviver ao save/load (obtido: %s)" % ExpeditionRuntime.CampState.keys()[loaded_expedition.camp_state])
	ctx.check(loaded_expedition.is_waiting_at_acampamento, "[G] is_waiting_at_acampamento deve continuar true após o reload — nunca depende da UI estar aberta")

	KingdomSaveService.delete_save()
