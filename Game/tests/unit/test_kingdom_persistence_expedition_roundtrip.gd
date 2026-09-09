class_name TestKingdomPersistenceExpeditionRoundtrip
extends RefCounted
## TestKingdomPersistenceExpeditionRoundtrip (F-020, decisão 2)
##
## Primeira persistência real de ExpeditionRuntime: inicia uma
## Expedição de verdade, avança 2 Fases (populando fase_history), salva,
## recarrega num Kingdom novo — kingdom_save_service.gd só empilha o
## dado cru em _pending_expedition_saves (o Mundo precisa estar
## registrado em WorldDatabase ANTES de hydrate_pending() poder
## reconstruir a ExpeditionRuntime de verdade, mesma ordem real de
## KingdomState._load_or_create_kingdom()) — e confirma que
## current_fase/fase_history/Squad sobrevivem por CONTEÚDO, nunca por
## identidade de objeto (mesma convenção de todo teste de persistência
## deste projeto).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-020] Validando round-trip de persistência de Expedição...")

	KingdomSaveService.delete_save()

	var season_id: String = "Season-Teste-Persistencia-Expedicao"
	var territory := Territory.new("Territorio-Persistencia-Expedicao", "Império")
	var trilha := Trilha.new(territory.id)
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	# CampaignTestFixtures.build_test_season_catalog() sempre grava
	# season_id = "Season-Teste" (fixo) — em produção, SeasonCatalog e a
	# Season que o possui sempre compartilham o mesmo season_id
	# (SeasonPipeline/WorldBootstrap, confirmado). Sobrescrito aqui pra
	# que o round-trip use um season_id isolado (nunca colide com outra
	# suíte que registre "Season-Teste" no mesmo WorldDatabase global).
	catalog.season_id = season_id
	var season := Season.new(season_id)
	season.add_territory(territory, trilha)
	season.enemy_catalog = catalog
	WorldDatabase.register_season(season)

	var kingdom := Kingdom.new()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.army_name = "Exército Persistência"
	winning_army.initialize_energy(1)
	kingdom.armies.append(winning_army)
	var squad := Squad.new([winning_army])

	var start_result: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season_id, territory.id, squad, 903,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	ctx.check(start_result["success"], "Pré-condição do teste: GameRuntime.start_new_expedition() deve ter sucesso (motivo: '%s')" % start_result["reason"])
	var expedition: ExpeditionRuntime = start_result["expedition"]

	expedition.attempt_current_fase()
	expedition.attempt_current_fase()
	print("  Antes de salvar -> current_fase: %d | fase_history com 2 entradas? %s (esperado: 3, true)" % [
		expedition.current_fase, str(expedition.fase_history.size() == 2)
	])
	ctx.check(expedition.current_fase == 3, "Pré-condição: 2 vitórias devem levar a current_fase == 3 (obtido: %d)" % expedition.current_fase)
	ctx.check(expedition.fase_history.size() == 2, "Pré-condição: 2 tentativas devem popular fase_history com 2 entradas (obtido: %d)" % expedition.fase_history.size())

	var expected_fase_1_enemy: String = expedition.fase_history[1]["enemy_name"]

	KingdomSaveService.save(kingdom)

	var loaded_kingdom := Kingdom.new()
	var load_ok: bool = KingdomSaveService.load_into(loaded_kingdom)
	ctx.check(load_ok, "load_into() deve retornar sucesso para um save recém-gravado")
	print("  Após load_into() (sem hidratar ainda) -> _pending_expedition_saves tem 1 entrada crua? %s (esperado: true)" % str(loaded_kingdom._pending_expedition_saves.size() == 1))
	ctx.check(loaded_kingdom._pending_expedition_saves.size() == 1, "kingdom_save_service.gd deve empilhar o dado cru da Expedição em _pending_expedition_saves (Mundo ainda não garantido nesse ponto)")

	ExpeditionPersistenceResolver.hydrate_pending(loaded_kingdom)
	print("  Após hydrate_pending() -> active_expeditions tem 1 Expedição real? %s | _pending_expedition_saves esvaziado? %s (esperado: true, true)" % [
		str(loaded_kingdom.active_expeditions.size() == 1), str(loaded_kingdom._pending_expedition_saves.is_empty())
	])
	ctx.check(loaded_kingdom.active_expeditions.size() == 1, "hydrate_pending() deve reconstruir exatamente 1 ExpeditionRuntime real")
	ctx.check(loaded_kingdom._pending_expedition_saves.is_empty(), "hydrate_pending() deve esvaziar _pending_expedition_saves depois de processar")

	var loaded_expedition: ExpeditionRuntime = loaded_kingdom.active_expeditions[0]
	print("  current_fase sobreviveu (%d -> %d)? %s (esperado: true)" % [
		expedition.current_fase, loaded_expedition.current_fase, str(loaded_expedition.current_fase == expedition.current_fase)
	])
	ctx.check(loaded_expedition.current_fase == expedition.current_fase, "current_fase deve sobreviver ao round-trip (obtido: %d, esperado: %d)" % [loaded_expedition.current_fase, expedition.current_fase])
	ctx.check(loaded_expedition.territory.id == territory.id, "territory deve ser reconstruído corretamente (obtido: '%s')" % loaded_expedition.territory.id)
	ctx.check(loaded_expedition.squad.armies.size() == 1, "Squad deve sobreviver com o mesmo número de Exércitos (obtido: %d)" % loaded_expedition.squad.armies.size())
	ctx.check(loaded_expedition.squad.armies[0].army_name == "Exército Persistência", "Squad.armies deve referenciar o Exército correto por conteúdo (obtido: '%s')" % loaded_expedition.squad.armies[0].army_name)
	ctx.check(loaded_expedition.fase_history.size() == 2, "fase_history deve sobreviver com 2 entradas (obtido: %d)" % loaded_expedition.fase_history.size())
	ctx.check(loaded_expedition.fase_history.has(1) and loaded_expedition.fase_history[1]["enemy_name"] == expected_fase_1_enemy, "fase_history deve preservar as chaves como int e o conteúdo de cada entrada")

	KingdomSaveService.delete_save()
	return true
