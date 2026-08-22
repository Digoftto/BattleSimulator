class_name TestKingdom
extends RefCounted
## TestKingdom (F-001, Etapa 4)
##
## Migrado de bootstrap.gd:_validate_kingdom() (Sprint 32 — Consolidação
## do Estado Persistente do Reino). Mesmo cenário original (criação do
## Kingdom, posse correta de cada componente antes órfão, consulta ao
## Registro de Comandantes Regionais através do Reino, e acesso às
## Expedições ativas) — utilizando um Kingdom.new() local (não
## KingdomState.kingdom, que é a instância global compartilhada) e
## CampaignTestFixtures (tests/campaign_test_fixtures.gd, já um
## class_name independente e puro — reutilizado diretamente, sem cópia).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Kingdom] Validando posse do estado persistente do Reino...")

	var kingdom := Kingdom.new()
	print("  Reino criado. Nível do Núcleo de Energia: %d (esperado: 1)" % kingdom.energy_nucleus_level)
	ctx.check(kingdom.energy_nucleus_level == 1, "Núcleo de Energia deve começar no Nível 1 (obtido: %d)" % kingdom.energy_nucleus_level)

	print("  Comandantes: %d | Cartas: %d | Exércitos: %d | Squads: %d | Expedições ativas: %d (todos esperados: 0)" % [
		kingdom.commanders.size(), kingdom.cards.size(), kingdom.armies.size(), kingdom.squads.size(), kingdom.active_expeditions.size()
	])
	ctx.check(kingdom.commanders.size() == 0, "Reino recém-criado deve começar sem Comandantes")
	ctx.check(kingdom.cards.size() == 0, "Reino recém-criado deve começar sem Cartas")
	ctx.check(kingdom.armies.size() == 0, "Reino recém-criado deve começar sem Exércitos")
	ctx.check(kingdom.squads.size() == 0, "Reino recém-criado deve começar sem Squads")
	ctx.check(kingdom.active_expeditions.size() == 0, "Reino recém-criado deve começar sem Expedições ativas")

	# Posse de Comandantes e Cartas (antes órfãos — nada os possuía).
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante do Reino (Teste)"
	commander.faction = "Império"
	kingdom.add_commander(commander)

	var real_card: CardResource = GameDatabase.get_card("Legionário Imperial")
	kingdom.add_card(real_card)
	print("  Após adicionar 1 Comandante e 1 Carta -> Comandantes: %d, Cartas: %d (esperado: 1, 1)" % [
		kingdom.commanders.size(), kingdom.cards.size()
	])
	ctx.check(kingdom.commanders.size() == 1, "Após add_commander(), Reino deve ter 1 Comandante (obtido: %d)" % kingdom.commanders.size())
	ctx.check(kingdom.cards.size() == 1, "Após add_card(), Reino deve ter 1 Carta (obtido: %d)" % kingdom.cards.size())

	# Posse de Exércitos e Squads.
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	kingdom.add_army(army)
	var squad := Squad.new([army])
	kingdom.add_squad(squad)
	print("  Após formar 1 Exército e 1 Squad -> Exércitos: %d, Squads: %d (esperado: 1, 1)" % [
		kingdom.armies.size(), kingdom.squads.size()
	])
	ctx.check(kingdom.armies.size() == 1, "Após add_army(), Reino deve ter 1 Exército (obtido: %d)" % kingdom.armies.size())
	ctx.check(kingdom.squads.size() == 1, "Após add_squad(), Reino deve ter 1 Squad (obtido: %d)" % kingdom.squads.size())

	# Registro de Comandantes Regionais agora pertence ao Reino, não mais
	# instanciado solto — consulta feita através de kingdom.
	print("  Comandante Regional do Império/Região 1 recrutado? %s (esperado: false)" % str(
		kingdom.regional_commander_registry.is_recruited("Império", 1)
	))
	ctx.check(kingdom.regional_commander_registry.is_recruited("Império", 1) == false, "Comandante Regional não deve estar recrutado antes de recruit()")

	kingdom.regional_commander_registry.recruit("Império", 1)
	print("  Após recrutar via kingdom.regional_commander_registry -> recrutado? %s (esperado: true)" % str(
		kingdom.regional_commander_registry.is_recruited("Império", 1)
	))
	ctx.check(kingdom.regional_commander_registry.is_recruited("Império", 1) == true, "Comandante Regional deve estar recrutado após recruit()")

	# Flags de progresso persistentes.
	print("  Flag 'tutorial_concluido' antes de definida: %s (esperado: false)" % str(kingdom.has_progress_flag("tutorial_concluido")))
	ctx.check(kingdom.has_progress_flag("tutorial_concluido") == false, "Flag de progresso não deve existir antes de ser definida")

	kingdom.set_progress_flag("tutorial_concluido")
	print("  Flag 'tutorial_concluido' após definida: %s (esperado: true)" % str(kingdom.has_progress_flag("tutorial_concluido")))
	ctx.check(kingdom.has_progress_flag("tutorial_concluido") == true, "Flag de progresso deve existir após set_progress_flag()")

	# Expedições ativas — Kingdom apenas referencia; toda a lógica de
	# Fase/Retry continua em ExpeditionRuntime/PhaseResolver.
	var territory := Territory.new("Territorio-Reino-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, kingdom.regional_commander_registry, 555,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	kingdom.start_expedition(expedition)
	print("  Expedições ativas após iniciar 1: %d (esperado: 1)" % kingdom.active_expeditions.size())
	ctx.check(kingdom.active_expeditions.size() == 1, "Reino deve ter 1 Expedição ativa após start_expedition() (obtido: %d)" % kingdom.active_expeditions.size())

	print("  A Expedição referenciada é a mesma instância? %s (esperado: true)" % str(kingdom.active_expeditions[0] == expedition))
	ctx.check(kingdom.active_expeditions[0] == expedition, "Expedição registrada deve ser a mesma instância passada a start_expedition()")

	print("  Nenhum método de Kingdom calcula, resolve ou gera — todos apenas armazenam (append/dict-set), conforme a regra estrutural da classe.")

	return true
