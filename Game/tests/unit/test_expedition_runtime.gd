class_name TestExpeditionRuntime
extends RefCounted
## TestExpeditionRuntime (F-001, Etapa 4)
##
## Migrado de bootstrap.gd:_validate_expedition_runtime() (Sprint 32).
## Mesmo cenário original — ExpeditionRuntime resolve sozinho o Exército
## inimigo de cada Fase (Trilha + Territory + SeasonCatalog +
## EnemyArmySelector), attempt_current_fase() não recebe o inimigo por
## parâmetro — utilizando CampaignTestFixtures (tests/campaign_test_fixtures.gd,
## já um class_name independente e puro — reutilizado diretamente, sem
## cópia, exatamente como pedido).
##
## O teste original já tinha "(esperado: X)" explícito nos pontos-chave —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra. Prints sem "esperado" explícito (ex.: Fase atual logo após
## vencer a Fase 100, ou o Status/Fase iniciais) permanecem apenas
## informativos, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[ExpeditionRuntime] Validando integração completa (Trilha + Territory + SeasonCatalog + EnemyArmySelector)...")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var territory := Territory.new("Territorio-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 777,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Status inicial: %s | Fase: %d de %d" % [str(expedition.status), expedition.current_fase, trilha.total_fases()])

	# Avança diretamente para a Fase 99 apenas para o teste (evita simular
	# 98 combates triviais) — não é uma funcionalidade de gameplay.
	expedition.current_fase = 99
	expedition.attempt_current_fase()
	print("  Venceu a Fase 99 -> Fase atual: %d (esperado: 100)" % expedition.current_fase)
	ctx.check(expedition.current_fase == 100, "Após vencer a Fase 99, Fase atual deve ser 100 (obtido: %d)" % expedition.current_fase)

	expedition.attempt_current_fase()  # Fase 100: Chefe Normal, e também Acampamento (deslocado)
	print("  Venceu a Fase 100 (Chefe Normal) -> Fase atual: %d" % expedition.current_fase)

	expedition.current_fase = 999
	expedition.attempt_current_fase()
	print("  Venceu a Fase 999 -> Fase atual: %d" % expedition.current_fase)
	print("  Tipo da Fase 1000: %s (esperado: regional)" % expedition.current_fase_type())
	ctx.check(expedition.current_fase_type() == "regional", "Fase 1000 deve ser Chefe Regional (obtido: '%s')" % expedition.current_fase_type())

	expedition.attempt_current_fase()  # Fase 1000: Chefe Regional -> Acampamento automático
	print("  Venceu a Fase 1000 (Chefe Regional) -> Fase atual: %d, Acampamento em: %d (esperado: 1000)" % [
		expedition.current_fase, expedition.last_acampamento_fase
	])
	ctx.check(expedition.last_acampamento_fase == 1000, "Vencer a Fase 1000 (Chefe Regional) deve registrar Acampamento em 1000 (obtido: %d)" % expedition.last_acampamento_fase)

	# Cenário de derrota total -> retorno ao último Acampamento.
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	losing_army.initialize_energy(1)
	var losing_squad := Squad.new([losing_army])
	var expedition_2 := ExpeditionRuntime.new(
		losing_squad, trilha, territory, catalog, registry, 778,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	# F-020: Fase 50 é o 2º Acampamento desta Trilha e, desde a decisão 8
	# (Acampamento comum sem combate), nunca mais dispara uma tentativa
	# real — usar Fase 51 (comum, não-Acampamento) para exercitar a
	# derrota de verdade.
	expedition_2.current_fase = 51
	expedition_2.attempt_current_fase()  # derrota total esperada
	print("  Após derrota total -> Fase atual: %d (esperado: %d, o último Acampamento)" % [
		expedition_2.current_fase, expedition_2.last_acampamento_fase
	])
	ctx.check(expedition_2.current_fase == expedition_2.last_acampamento_fase, "Após derrota total, Fase atual deve retornar ao último Acampamento (Fase: %d, Acampamento: %d)" % [expedition_2.current_fase, expedition_2.last_acampamento_fase])

	expedition_2.end_expedition()
	print("  Status final: %s (esperado: ENCERRADA)" % str(expedition_2.status))
	ctx.check(expedition_2.status == ExpeditionRuntime.Status.ENCERRADA, "Status final deve ser ENCERRADA após end_expedition() (obtido: %s)" % str(expedition_2.status))

	print("  Log completo da Expedição 2:")
	for line: String in expedition_2.history_log:
		print("    " + line)

	return true
