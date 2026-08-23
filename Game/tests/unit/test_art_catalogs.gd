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
	print("[ART-001] Validando CardArtCatalog/BattlefieldArtCatalog contra o catálogo real (39 cartas + 10 Campos de Batalha)...")
	_test_every_catalog_card_resolves_real_art(ctx)
	_test_every_catalog_battlefield_resolves_real_art(ctx)
	_test_special_unit_resolves_real_art(ctx)
	_test_card_without_resource_path_does_not_crash(ctx)
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
