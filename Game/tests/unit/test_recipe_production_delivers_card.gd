class_name TestRecipeProductionDeliversCard
extends RefCounted
## TestRecipeProductionDeliversCard (F-001, Etapa 7)
##
## Migrado de bootstrap.gd:_validate_recipe_production_delivers_card().
## Mesmo cenário original — validação FUNCIONAL do bug real relatado:
## produzir a Balista Imperial (Rara, Receita de 3 ingredientes) consumia
## Fragmentos mas a carta nunca aparecia em kingdom.cards — cobrindo os 2
## cenários originais (cadeia automática completa; e ingredientes já
## possuídos no inventário) usando um Kingdom.new() local e
## AcademyResolver (lógica pura, opera só sobre o "kingdom" recebido por
## parâmetro; confirmado sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou
## transitiva).
##
## O teste original só tinha "(esperado: X)" explícito nos pontos-chave
## de cada cenário — convertidos abaixo em asserções reais, sem
## reinterpretar nenhuma regra. Prints sem "esperado" explícito (ex.:
## Fragmentos gastos, filas dos Mestres) permanecem apenas informativos.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Academia] Validando produção real da Balista Imperial (Receita de 3 ingredientes)...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	kingdom.sync_academy_masters()

	var cards_before: int = kingdom.cards.size()
	var fragments_before: int = kingdom.get_fragment("Império")

	var result: Dictionary = AcademyResolver.request_production(kingdom, "Balista Imperial", 1, GameClock.now_unix())
	print("  Solicitação aceita? %s (esperado: true) | Fragmentos gastos na hora: %d" % [
		str(result["success"]), fragments_before - kingdom.get_fragment("Império")
	])
	ctx.check(result["success"] == true, "Solicitação de produção da Balista Imperial deve ser aceita")

	# Avança o tempo em blocos e sincroniza repetidamente — exatamente
	# como um jogador real veria ao longo de várias sessões, nunca uma
	# chamada só.
	var now: int = GameClock.now_unix()
	for i in range(20):
		now += 3600  # +1h por vez
		AcademyResolver.sync(kingdom, now)

	var balista_found: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Balista Imperial":
			balista_found = true
	print("  Depois da cadeia inteira terminar, a Balista Imperial está em kingdom.cards de verdade? %s (%d -> %d cartas, esperado: true)" % [
		str(balista_found), cards_before, kingdom.cards.size()
	])
	ctx.check(balista_found == true, "Balista Imperial deve aparecer de verdade em kingdom.cards ao final da cadeia automática")
	print("  Filas dos Mestres, pra depurar: %s" % str(
		[kingdom.academy_artifices[0].queue.size() if not kingdom.academy_artifices.is_empty() else -1,
		kingdom.academy_pending_chain_tasks.size()]
	))

	# --- Cenário 2: os 3 ingredientes JÁ EXISTEM no inventário (não
	# precisam ser produzidos) — caminho de código diferente
	# (ready_now = true, task agenda direto, sem cadeia). ---
	var kingdom_2 := Kingdom.new()
	kingdom_2.add_fragment("Império", 1000)
	kingdom_2.sync_academy_masters()

	var arqueiro: CardResource = GameDatabase.get_card("Arqueiro Imperial")
	var engenheiro: CardResource = GameDatabase.get_card("Engenheiro Imperial")
	var escudeiro: CardResource = GameDatabase.get_card("Escudeiro Imperial")
	kingdom_2.acquire_card_from_catalog(arqueiro)
	kingdom_2.acquire_card_from_catalog(engenheiro)
	kingdom_2.acquire_card_from_catalog(escudeiro)

	var cards_before_2: int = kingdom_2.cards.size()
	var fragments_before_2: int = kingdom_2.get_fragment("Império")
	var result_2: Dictionary = AcademyResolver.request_production(kingdom_2, "Balista Imperial", 1, GameClock.now_unix())
	print("  [Cenário 2: ingredientes já possuídos] Solicitação aceita? %s | Fragmentos gastos: %d" % [
		str(result_2["success"]), fragments_before_2 - kingdom_2.get_fragment("Império")
	])

	var now_2: int = GameClock.now_unix()
	for i in range(20):
		now_2 += 3600
		AcademyResolver.sync(kingdom_2, now_2)

	var balista_found_2: bool = false
	for card: CardResource in kingdom_2.cards:
		if card.card_name == "Balista Imperial":
			balista_found_2 = true
	print("  [Cenário 2] Balista Imperial apareceu de verdade? %s (%d -> %d cartas, esperado: true, 4 -> 4 já q 3 ingredientes foram consumidos)" % [
		str(balista_found_2), cards_before_2, kingdom_2.cards.size()
	])
	ctx.check(balista_found_2 == true, "Balista Imperial deve aparecer de verdade em kingdom_2.cards quando os ingredientes já estavam no inventário")

	return true
