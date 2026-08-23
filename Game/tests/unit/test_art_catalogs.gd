class_name TestArtCatalogs
extends RefCounted
## TestArtCatalogs (ART-001)
##
## Valida CardArtCatalog/BattlefieldArtCatalog contra o catálogo REAL
## carregado por GameDatabase — nenhuma carta/Campo de Batalha
## inventado, nenhuma amostra: percorre GameDatabase.cards (39) e
## GameDatabase.battlefields (10) inteiros. Confirma:
##   (A) toda carta oficial resolve um caminho de arte que EXISTE de
##       verdade em disco (ResourceLoader.exists()), nunca uma
##       referência quebrada;
##   (B) o mesmo pra todo Campo de Batalha oficial;
##   (C) a unidade especial "Arqueiro Esquelético Reanimado" (não é
##       uma CardResource de GameDatabase.cards — R-007 — construída
##       manualmente aqui só pra provar que a exceção documentada
##       funciona) também resolve;
##   (D) uma carta sem resource_path (ex: recém-criada via
##       CardResource.new(), nunca carregada de um .tres) não quebra —
##       texture_path_for() devolve "" em vez de travar.

static func run(ctx: TestRunner.Context) -> bool:
	print("[ART-001/ART-002] Validando CardArtCatalog/BattlefieldArtCatalog/CityBuildingArtCatalog contra o catálogo real...")
	_test_every_catalog_card_resolves_real_art(ctx)
	_test_every_catalog_battlefield_resolves_real_art(ctx)
	_test_special_unit_resolves_real_art(ctx)
	_test_card_without_resource_path_does_not_crash(ctx)
	_test_every_city_building_key_resolves_real_art(ctx)
	_test_unknown_building_key_does_not_crash(ctx)
	print("[ART-003] Validando PvEArtCatalog (Trilhas + ícones de Fase) contra Facções/Regiões/categorias reais...")
	_test_every_trilha_faction_region_resolves_real_art(ctx)
	_test_every_fase_icon_faction_category_resolves_real_art(ctx)
	_test_fase_category_matches_real_expedition_state(ctx)
	return true


static func _test_every_catalog_card_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/card_art_catalog.gd")
	var missing: Array[String] = []
	for card: CardResource in GameDatabase.cards:
		var path: String = catalog_module.texture_path_for(card)
		if path == "" or not ResourceLoader.exists(path):
			missing.append("%s (caminho: '%s')" % [card.card_name, path])

	print("  [A] Todas as %d cartas do catálogo resolvem arte real em disco? %s (%d sem arte: %s)" % [
		GameDatabase.cards.size(), str(missing.is_empty()), missing.size(), str(missing)
	])
	ctx.check(GameDatabase.cards.size() == 39, "[A] Pré-condição: o catálogo real deve ter exatamente 39 cartas (mesma contagem já confirmada em R-007)")
	ctx.check(missing.is_empty(), "[A] Toda carta oficial do catálogo deve resolver um caminho de arte que existe de verdade em disco — nenhuma referência quebrada")


static func _test_every_catalog_battlefield_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/battlefield_art_catalog.gd")
	var missing: Array[String] = []
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		var path: String = catalog_module.texture_path_for(battlefield)
		if path == "" or not ResourceLoader.exists(path):
			missing.append("%s (caminho: '%s')" % [battlefield.battlefield_name, path])

	print("  [B] Todos os %d Campos de Batalha do catálogo resolvem arte real em disco? %s (%d sem arte: %s)" % [
		GameDatabase.battlefields.size(), str(missing.is_empty()), missing.size(), str(missing)
	])
	ctx.check(GameDatabase.battlefields.size() == 10, "[B] Pré-condição: o catálogo real deve ter exatamente 10 Campos de Batalha")
	ctx.check(missing.is_empty(), "[B] Todo Campo de Batalha oficial deve resolver um caminho de arte que existe de verdade em disco — nenhuma referência quebrada")


static func _test_special_unit_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/card_art_catalog.gd")
	var special := CardResource.new()
	special.card_name = "Arqueiro Esquelético Reanimado"
	# Deliberadamente SEM resource_path (nunca vem de um .tres — R-007) —
	# é exatamente esse o cenário que a exceção manual precisa cobrir.

	var path: String = catalog_module.texture_path_for(special)
	print("  [C] A unidade especial 'Arqueiro Esquelético Reanimado' (sem resource_path) resolve arte real mesmo assim? %s (caminho: '%s')" % [
		str(path != "" and ResourceLoader.exists(path)), path
	])
	ctx.check(path != "" and ResourceLoader.exists(path), "[C] A exceção manual da unidade especial deve resolver um caminho de arte real, mesmo sem resource_path")


static func _test_card_without_resource_path_does_not_crash(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/card_art_catalog.gd")
	var fresh := CardResource.new()
	fresh.card_name = "Carta de Teste Nunca Catalogada"

	var path: String = catalog_module.texture_path_for(fresh)
	var texture: Variant = catalog_module.texture_for(fresh)
	print("  [D] Uma carta sem resource_path e fora do catálogo não quebra (devolve '' / null)? %s (caminho: '%s')" % [
		str(path == "" and texture == null), path
	])
	ctx.check(path == "", "[D] texture_path_for() deve devolver '' pra uma carta sem resource_path e sem exceção manual, nunca travar")
	ctx.check(texture == null, "[D] texture_for() deve devolver null no mesmo caso, pra quem chama decidir o fallback (hoje: continuar mostrando texto)")


## ART-002: mesmas 7 chaves de CityPanel.BUILDING_REGIONS — reaproveitadas
## aqui como literais em vez de referenciar CityPanel.BUILDING_REGIONS.keys()
## de propósito (city_panel.gd é uma cena Control real; instanciar só
## pra ler uma constante seria acoplamento desnecessário) — se as duas
## listas algum dia divergirem, é exatamente esse tipo de teste que
## precisa pegar isso.
static func _test_every_city_building_key_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/city_building_art_catalog.gd")
	var building_keys: Array[String] = [
		"capital", "biblioteca", "observatorio", "academia",
		"centro_de_comando", "depositos", "nucleo_de_energia",
	]
	var missing: Array[String] = []
	for key: String in building_keys:
		var path: String = catalog_module.texture_path_for(key)
		if path == "" or not ResourceLoader.exists(path):
			missing.append("%s (caminho: '%s')" % [key, path])

	print("  [G] Todos os 7 prédios da Cidade (mesmas chaves de CityPanel.BUILDING_REGIONS) resolvem arte real em disco? %s (%d sem arte: %s)" % [
		str(missing.is_empty()), missing.size(), str(missing)
	])
	ctx.check(missing.is_empty(), "[G] Todo prédio da Cidade com BUILDING_REGIONS deve resolver um caminho de arte que existe de verdade em disco — nenhuma referência quebrada")


static func _test_unknown_building_key_does_not_crash(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/city_building_art_catalog.gd")
	var path: String = catalog_module.texture_path_for("prédio_que_não_existe")
	var texture: Variant = catalog_module.texture_for("")
	print("  [H] Uma chave de prédio desconhecida/vazia não quebra (devolve '' / null)? %s" % str(path == "" and texture == null))
	ctx.check(path == "", "[H] texture_path_for() deve devolver '' pra uma chave de prédio desconhecida, nunca travar")
	ctx.check(texture == null, "[H] texture_for() deve devolver null pra uma chave vazia, pra quem chama decidir o fallback")


static func _test_every_trilha_faction_region_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/pve_art_catalog.gd")
	var factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
	var missing: Array[String] = []
	for faction: String in factions:
		for region in [1, 2, 3]:
			var path: String = catalog_module.trilha_texture_path_for(faction, region)
			if path == "" or not ResourceLoader.exists(path):
				missing.append("%s Região %d (caminho: '%s')" % [faction, region, path])

	print("  [I] As 9 combinações Facção x Região de Trilha resolvem arte real em disco? %s (%d sem arte: %s)" % [
		str(missing.is_empty()), missing.size(), str(missing)
	])
	ctx.check(missing.is_empty(), "[I] Toda combinação real de Facção x Região deve resolver uma arte de Trilha que existe de verdade em disco")


static func _test_every_fase_icon_faction_category_resolves_real_art(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/pve_art_catalog.gd")
	var factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
	var categories: Array[String] = ["acampamento", "chefe_regional", "chefe_normal", "comum"]
	var missing: Array[String] = []
	for faction: String in factions:
		for category: String in categories:
			var path: String = catalog_module.fase_icon_texture_path_for(faction, category)
			if path == "" or not ResourceLoader.exists(path):
				missing.append("%s/%s (caminho: '%s')" % [faction, category, path])

	print("  [J] As 12 combinações Facção x categoria de Fase resolvem arte real em disco? %s (%d sem arte: %s)" % [
		str(missing.is_empty()), missing.size(), str(missing)
	])
	ctx.check(missing.is_empty(), "[J] Toda combinação real de Facção x categoria de Fase deve resolver um ícone que existe de verdade em disco")


## Constrói uma ExpeditionRuntime real (mesmo padrão de
## test_expedition_runtime.gd, via CampaignTestFixtures) e confirma que
## fase_category_for_expedition() deriva a categoria certa em 4
## cenários reais — o mais importante sendo o (b): a Fase 100 é Chefe
## Normal E Trilha.is_acampamento(100) == true AO MESMO TEMPO ("Fase
## 100: Chefe Normal, e também Acampamento (deslocado)", já documentado
## em test_expedition_runtime.gd) — a categoria correta aqui precisa
## ser "chefe_normal", nunca "acampamento", porque
## is_waiting_at_acampamento (o ESTADO real da Expedição) só fica true
## depois de vencer essa Fase, não antes.
static func _test_fase_category_matches_real_expedition_state(ctx: TestRunner.Context) -> void:
	var catalog_module = preload("res://engine/presentation/pve_art_catalog.gd")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(1)
	var squad := Squad.new([army])
	var territory := Territory.new("Território-Teste-ART-003", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()
	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 555,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	# a) Fase comum (1).
	expedition.current_fase = 1
	print("  [K-a] Fase 1 (comum, ainda não em Acampamento) -> categoria: %s (esperado: comum)" % catalog_module.fase_category_for_expedition(expedition))
	ctx.check(catalog_module.fase_category_for_expedition(expedition) == "comum", "[K-a] Fase comum sem Acampamento ativo deve resolver categoria 'comum'")

	# b) Fase 100: Chefe Normal E Trilha.is_acampamento(100) == true ao
	# mesmo tempo (o caso que motivou usar is_waiting_at_acampamento em
	# vez de current_fase_is_acampamento()).
	expedition.current_fase = 100
	print("  [K-b] Fase 100 (Chefe Normal, Trilha.is_acampamento(100)=%s, mas is_waiting_at_acampamento ainda false) -> categoria: %s (esperado: chefe_normal, NUNCA acampamento)" % [
		str(trilha.is_acampamento(100)), catalog_module.fase_category_for_expedition(expedition)
	])
	ctx.check(catalog_module.fase_category_for_expedition(expedition) == "chefe_normal", "[K-b] Fase 100 (Chefe Normal, mesmo sendo tecnicamente uma Fase de Acampamento) deve mostrar o ícone de Chefe Normal, não o de Acampamento pacífico, enquanto o jogador ainda não venceu")

	# c) Fase 1000: Chefe Regional (prevalece sobre Normal, se coincidisse).
	expedition.current_fase = 1000
	print("  [K-c] Fase 1000 (Chefe Regional) -> categoria: %s (esperado: chefe_regional)" % catalog_module.fase_category_for_expedition(expedition))
	ctx.check(catalog_module.fase_category_for_expedition(expedition) == "chefe_regional", "[K-c] Fase 1000 (Chefe Regional) deve resolver categoria 'chefe_regional'")

	# d) Estado REAL de Acampamento (is_waiting_at_acampamento == true) —
	# deve prevalecer sobre qualquer current_fase_type(), inclusive se a
	# Fase atual também for tecnicamente um Chefe.
	expedition.is_waiting_at_acampamento = true
	print("  [K-d] is_waiting_at_acampamento == true (mesmo na Fase 1000, Chefe Regional) -> categoria: %s (esperado: acampamento)" % catalog_module.fase_category_for_expedition(expedition))
	ctx.check(catalog_module.fase_category_for_expedition(expedition) == "acampamento", "[K-d] Quando a Expedição está de fato esperando no Acampamento (is_waiting_at_acampamento), a categoria deve ser 'acampamento', prevalecendo sobre o tipo da Fase")
