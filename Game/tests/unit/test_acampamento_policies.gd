class_name TestAcampamentoPolicies
extends RefCounted
## TestAcampamentoPolicies (F-001, Etapa 16)
##
## Migrado de bootstrap.gd:_validate_acampamento_policies(). Mesmo
## cenário original — as 4 Políticas de Acampamento (PvE.md) testadas
## diretamente sobre ExpeditionRuntime.establish_acampamento():
##   a) Seguir Automaticamente — Energia parcial permanece intocada.
##   b) Aguardar Ordem — Expedição para; attempt_current_fase() não age
##      enquanto aguarda; resume_from_acampamento() recupera e libera.
##   c) Aguardar Recuperação Total — sempre recupera 100%, não pausa.
##   d) Aguardar Limite (40%) — acima do limite não recupera, abaixo
##      recupera.
##
## Confirmado por rastreamento direto do código-fonte na auditoria da
## Etapa 16 (não presumido): ExpeditionRuntime.establish_acampamento(),
## _apply_acampamento_policy() e resume_from_acampamento() não têm
## nenhuma referência a KingdomState.kingdom — só attempt_current_fase()
## tem, e só dentro do ramo "if result.victory:" (expedition_runtime.gd).
## A única chamada a attempt_current_fase() neste cenário (b) acontece
## enquanto is_waiting_at_acampamento já é true, o que retorna null no
## early-return antes de qualquer combate — nunca alcança o ramo que lê
## KingdomState.kingdom. Nenhuma seed foi adicionada, nenhum código de
## produção (incluindo ExpeditionRuntime) foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Acampamento] Validando as 4 Políticas de Acampamento...")

	var territory := Territory.new("Territorio-Politicas-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()

	# a) Seguir Automaticamente: Energia parcial permanece intocada.
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_a.initialize_energy(1)
	army_a.current_energy = 10
	var expedition_a := ExpeditionRuntime.new(
		Squad.new([army_a]), trilha, territory, catalog, registry, 1,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_a.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.SEGUIR_AUTOMATICO
	expedition_a.establish_acampamento()
	print("  a) Seguir Automaticamente -> Energia após Acampamento: %d (esperado: 10, intocada) | aguardando? %s (esperado: false)" % [
		army_a.current_energy, str(expedition_a.is_waiting_at_acampamento)
	])
	ctx.check(army_a.current_energy == 10, "a) Energia deve permanecer intocada em 10 (obtido: %d)" % army_a.current_energy)
	ctx.check(expedition_a.is_waiting_at_acampamento == false, "a) Não deve ficar aguardando")

	# b) Aguardar Ordem: Expedição para; attempt_current_fase() não age
	# enquanto aguarda; resume_from_acampamento() recupera e libera.
	var army_b: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_b.initialize_energy(1)
	army_b.current_energy = 10
	var expedition_b := ExpeditionRuntime.new(
		Squad.new([army_b]), trilha, territory, catalog, registry, 2,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_b.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_ORDEM
	expedition_b.establish_acampamento()
	print("  b) Aguardar Ordem -> aguardando? %s (esperado: true)" % str(expedition_b.is_waiting_at_acampamento))
	ctx.check(expedition_b.is_waiting_at_acampamento == true, "b) Deve ficar aguardando após establish_acampamento()")

	var blocked_result: PhaseResult = expedition_b.attempt_current_fase()
	print("     Tentativa enquanto aguarda -> retornou null? %s (esperado: true)" % str(blocked_result == null))
	ctx.check(blocked_result == null, "b) attempt_current_fase() deve retornar null enquanto aguarda")

	expedition_b.resume_from_acampamento()
	print("     Após resume_from_acampamento() -> Energia: %d/%d (esperado: cheia) | aguardando? %s (esperado: false)" % [
		army_b.current_energy, army_b.max_energy, str(expedition_b.is_waiting_at_acampamento)
	])
	ctx.check(army_b.current_energy == army_b.max_energy, "b) Energia deve estar cheia após resume_from_acampamento() (obtido: %d/%d)" % [army_b.current_energy, army_b.max_energy])
	ctx.check(expedition_b.is_waiting_at_acampamento == false, "b) Não deve mais estar aguardando após resume_from_acampamento()")

	# c) Aguardar Recuperação Total: sempre recupera 100%, não pausa.
	var army_c: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_c.initialize_energy(1)
	army_c.current_energy = 5
	var expedition_c := ExpeditionRuntime.new(
		Squad.new([army_c]), trilha, territory, catalog, registry, 3,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_c.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL
	expedition_c.establish_acampamento()
	print("  c) Aguardar Recuperação Total -> Energia: %d/%d (esperado: cheia) | aguardando? %s (esperado: false)" % [
		army_c.current_energy, army_c.max_energy, str(expedition_c.is_waiting_at_acampamento)
	])
	ctx.check(army_c.current_energy == army_c.max_energy, "c) Energia deve estar cheia (obtido: %d/%d)" % [army_c.current_energy, army_c.max_energy])
	ctx.check(expedition_c.is_waiting_at_acampamento == false, "c) Não deve ficar aguardando")

	# d) Aguardar Limite (40%%): acima do limite não recupera; abaixo, recupera.
	var army_d1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_d1.initialize_energy(1)
	army_d1.current_energy = int(army_d1.max_energy * 0.9)  # acima do limite de 40%
	var expedition_d1 := ExpeditionRuntime.new(
		Squad.new([army_d1]), trilha, territory, catalog, registry, 4,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_d1.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_LIMITE
	expedition_d1.energy_recovery_threshold_percent = 0.4
	var energy_before_d1: int = army_d1.current_energy
	expedition_d1.establish_acampamento()
	print("  d1) Aguardar Limite, acima do limite -> Energia: %d (esperado: igual à anterior, %d — sem recuperar)" % [
		army_d1.current_energy, energy_before_d1
	])
	ctx.check(army_d1.current_energy == energy_before_d1, "d1) Energia acima do limite não deve recuperar (antes: %d, depois: %d)" % [energy_before_d1, army_d1.current_energy])

	var army_d2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_d2.initialize_energy(1)
	army_d2.current_energy = int(army_d2.max_energy * 0.1)  # abaixo do limite de 40%
	var expedition_d2 := ExpeditionRuntime.new(
		Squad.new([army_d2]), trilha, territory, catalog, registry, 5,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_d2.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_LIMITE
	expedition_d2.energy_recovery_threshold_percent = 0.4
	expedition_d2.establish_acampamento()
	print("  d2) Aguardar Limite, abaixo do limite -> Energia: %d/%d (esperado: cheia — recuperou)" % [
		army_d2.current_energy, army_d2.max_energy
	])
	ctx.check(army_d2.current_energy == army_d2.max_energy, "d2) Energia abaixo do limite deve recuperar totalmente (obtido: %d/%d)" % [army_d2.current_energy, army_d2.max_energy])

	return true
