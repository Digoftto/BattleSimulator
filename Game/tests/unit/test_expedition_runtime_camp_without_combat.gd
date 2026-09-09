class_name TestExpeditionRuntimeCampWithoutCombat
extends RefCounted
## TestExpeditionRuntimeCampWithoutCombat (F-020, decisão 8)
##
## Um Acampamento comum (não coincidente com Chefe Regional) se
## estabelece sem exigir combate — nenhuma Energia consumida, nenhum
## PhaseResult produzido. Um Acampamento que coincide com Chefe
## Regional (Fase 1000, 2000, ...) continua exigindo a vitória do
## Chefe normalmente — comportamento pré-existente, inalterado.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-020] Validando Acampamento sem combate (decisão 8)...")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(1)
	var squad := Squad.new([army])

	var territory := Territory.new("Territorio-Teste-Acampamento", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 901,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	# Fase 25: 1º Acampamento de Região I nesta Trilha, não coincide com
	# nenhum Chefe (Trilha._generate_acampamentos() nunca deixa um
	# Acampamento comum colidir com um Chefe Normal/Regional).
	ctx.check(trilha.is_acampamento(25) and trilha.chefe_type(25) == "", "Pré-condição do teste: Fase 25 deve ser Acampamento comum (não-Chefe) nesta Trilha")

	expedition.current_fase = 25
	var energy_before: int = army.current_energy
	var result: PhaseResult = expedition.attempt_current_fase()

	print("  Acampamento comum (Fase 25) -> retorno null (sem combate)? %s | Fase avançou pra 26? %s | Energia inalterada (%d -> %d)? %s (esperado: true, true, true)" % [
		str(result == null), str(expedition.current_fase == 26), energy_before, army.current_energy, str(army.current_energy == energy_before)
	])
	ctx.check(result == null, "Acampamento comum não deve produzir PhaseResult (nenhum combate ocorre)")
	ctx.check(expedition.current_fase == 26, "Acampamento comum deve avançar current_fase sem exigir combate (obtido: %d)" % expedition.current_fase)
	ctx.check(expedition.last_acampamento_fase == 25, "Acampamento comum deve registrar last_acampamento_fase (obtido: %d)" % expedition.last_acampamento_fase)
	ctx.check(army.current_energy == energy_before, "Acampamento comum não pode consumir Energia (nenhum combate real ocorre)")
	var log_mentions_no_combat: bool = false
	for line: String in expedition.history_log:
		if line.contains("sem combate"):
			log_mentions_no_combat = true
	ctx.check(log_mentions_no_combat, "O log deve registrar explicitamente que o Acampamento foi estabelecido sem combate (log completo: %s)" % str(expedition.history_log))

	# Fase 1000: Chefe Regional, também Acampamento — continua exigindo
	# vitória real (comportamento pré-existente, inalterado).
	expedition.current_fase = 999
	expedition.attempt_current_fase()  # vence a Fase 999 (comum)
	ctx.check(expedition.current_fase == 1000, "Pré-condição: vencer a Fase 999 deve levar à Fase 1000 (obtido: %d)" % expedition.current_fase)

	var energy_before_chefe: int = army.current_energy
	var result_chefe: PhaseResult = expedition.attempt_current_fase()
	print("  Acampamento coincidente com Chefe Regional (Fase 1000) -> exige combate real (PhaseResult != null)? %s | Energia consumida (%d -> %d)? %s (esperado: true, true)" % [
		str(result_chefe != null), energy_before_chefe, army.current_energy, str(army.current_energy != energy_before_chefe)
	])
	ctx.check(result_chefe != null, "Acampamento coincidente com Chefe Regional deve exigir combate real (PhaseResult não-nulo)")
	ctx.check(army.current_energy != energy_before_chefe, "Vencer o Chefe Regional na Fase 1000 deve consumir Energia de verdade")
	ctx.check(expedition.last_acampamento_fase == 1000, "Vencer o Chefe Regional na Fase 1000 deve estabelecer Acampamento ali (obtido: %d)" % expedition.last_acampamento_fase)

	return true
