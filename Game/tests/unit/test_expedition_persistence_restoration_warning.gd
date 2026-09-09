class_name TestExpeditionPersistenceRestorationWarning
extends RefCounted
## TestExpeditionPersistenceRestorationWarning (Auditoria Final FASE 21.8)
##
## Achado real: ExpeditionPersistenceResolver.hydrate_pending() descartava
## silenciosamente uma Expedição salva cuja Temporada/Território não
## existe mais no Mundo atual (ex.: rotação real de Temporada), sem
## nenhuma comunicação ao jogador. Corrigido preenchendo
## Kingdom.pending_restoration_warnings nesse cenário, exibido uma única
## vez por city_panel.gd. Este teste cobre só a lógica de dados (Kingdom/
## resolver), nunca o AcceptDialog em si — mesma convenção já usada para
## partes assíncronas/de cena (ex.: test_pvp_battle.gd não exercita o
## replay visual).

static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria 21.8] Validando aviso de restauração de Expedição...")

	# Caso 1: season_id referenciado no save não existe mais no Mundo.
	var kingdom_a := Kingdom.new()
	kingdom_a._pending_expedition_saves.append({
		"season_id": "Season-Inexistente-Nesta-Suite",
		"territory_id": "Territorio-Qualquer",
	})
	ExpeditionPersistenceResolver.hydrate_pending(kingdom_a)

	print("  [Temporada ausente] _pending_expedition_saves esvaziado? %s (esperado: true)" % str(kingdom_a._pending_expedition_saves.is_empty()))
	ctx.check(kingdom_a._pending_expedition_saves.is_empty(), "hydrate_pending() deve continuar esvaziando _pending_expedition_saves mesmo quando a hidratação falha (contrato preexistente preservado)")

	print("  [Temporada ausente] active_expeditions continua vazio? %s (esperado: true)" % str(kingdom_a.active_expeditions.is_empty()))
	ctx.check(kingdom_a.active_expeditions.is_empty(), "Uma hidratação que falhou nunca deve produzir uma ExpeditionRuntime")

	print("  [Temporada ausente] pending_restoration_warnings populado com 1 aviso? %s (esperado: true)" % str(kingdom_a.pending_restoration_warnings.size() == 1))
	ctx.check(kingdom_a.pending_restoration_warnings.size() == 1, "Falha de hidratação por Temporada ausente deve registrar exatamente 1 aviso para o jogador (obtido: %d)" % kingdom_a.pending_restoration_warnings.size())
	ctx.check(not kingdom_a.pending_restoration_warnings[0].is_empty(), "O aviso registrado nunca deve ser uma string vazia")

	# Caso 2: Temporada existe, mas o Território/Trilha do save não.
	var season_id: String = "Season-Teste-Aviso-Restauracao"
	var territory := Territory.new("Territorio-Aviso-Restauracao", "Império")
	var trilha := Trilha.new(territory.id)
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	catalog.season_id = season_id
	var season := Season.new(season_id)
	season.add_territory(territory, trilha)
	season.enemy_catalog = catalog
	WorldDatabase.register_season(season)

	var kingdom_b := Kingdom.new()
	kingdom_b._pending_expedition_saves.append({
		"season_id": season_id,
		"territory_id": "Territorio-Que-Nao-Existe-Nesta-Temporada",
	})
	ExpeditionPersistenceResolver.hydrate_pending(kingdom_b)

	print("  [Território ausente] pending_restoration_warnings populado com 1 aviso? %s (esperado: true)" % str(kingdom_b.pending_restoration_warnings.size() == 1))
	ctx.check(kingdom_b.pending_restoration_warnings.size() == 1, "Falha de hidratação por Território/Trilha ausente também deve registrar aviso para o jogador (obtido: %d)" % kingdom_b.pending_restoration_warnings.size())
	ctx.check(kingdom_b.active_expeditions.is_empty(), "Uma hidratação que falhou por Território ausente também nunca deve produzir uma ExpeditionRuntime")

	# Caso 3 (regressão): hidratação bem-sucedida nunca deve gerar aviso.
	var kingdom_c := Kingdom.new()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	kingdom_c.armies.append(winning_army)
	var squad := Squad.new([winning_army])
	var start_result: Dictionary = GameRuntime.start_new_expedition(
		kingdom_c, season_id, territory.id, squad, 904,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	ctx.check(start_result["success"], "Pré-condição do Caso 3: GameRuntime.start_new_expedition() deve ter sucesso (motivo: '%s')" % start_result["reason"])

	KingdomSaveService.save(kingdom_c)
	var loaded_kingdom := Kingdom.new()
	KingdomSaveService.load_into(loaded_kingdom)
	ExpeditionPersistenceResolver.hydrate_pending(loaded_kingdom)

	print("  [Regressão: hidratação ok] active_expeditions tem 1 Expedição real? %s | nenhum aviso gerado? %s (esperado: true, true)" % [
		str(loaded_kingdom.active_expeditions.size() == 1), str(loaded_kingdom.pending_restoration_warnings.is_empty())
	])
	ctx.check(loaded_kingdom.active_expeditions.size() == 1, "Regressão: uma hidratação bem-sucedida continua reconstruindo a ExpeditionRuntime normalmente")
	ctx.check(loaded_kingdom.pending_restoration_warnings.is_empty(), "Regressão: uma hidratação bem-sucedida nunca deve gerar aviso de restauração para o jogador")

	KingdomSaveService.delete_save()
	return true
