class_name TestStarterKitFactionComposition
extends RefCounted
## TestStarterKitFactionComposition (F-009, atualizado no F-030)
##
## Regra explícita do dono do produto: o Kit Inicial sempre tem 9
## cartas — exatamente 6 da Facção do Comandante + exatamente 3 de UMA
## ÚNICA Facção secundária (nunca uma mistura das outras duas).
##
## F-030: StarterKitResolver.generate_options() deixou de sortear a
## Facção secundária e suas 3 cartas (Array.shuffle(), sem seed) — o
## roster de cada Facção agora é FIXO, exatamente o de
## INICIALIZAÇÃO.png (MVP aprovado, StarterKitResolver.STARTER_ROSTER_CARD_NAMES).
## Este teste deixou de tolerar aleatoriedade (30 rodadas checando só
## invariantes estruturais) — agora valida o roster EXATO de cada
## Facção, em uma única rodada, já que o resultado deve ser idêntico
## toda vez.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-009/F-030] Validando o roster EXATO e determinístico do Kit Inicial (INICIALIZAÇÃO.png)...")

	var expected: Dictionary = {
		"Império": [
			"Arqueiro Imperial", "Engenheiro Imperial", "Escudeiro Imperial",
			"Evocador Imperial", "Infante Imperial", "Legionário Imperial",
			"Carvalho Ancião", "Trepadeira Ancestral", "Flor da Aurora",
		],
		"Natureza": [
			"Carvalho Ancião", "Ent Jovem", "Flor da Aurora",
			"Porco-Espinho Ancestral", "Trepadeira Ancestral", "Urso Ancestral",
			"Liche Iniciado", "Abominação Putrefata", "Sacerdote Profano",
		],
		"Mortos-Vivos": [
			"Abominação Putrefata", "Arqueiro Esquelético", "Banshee",
			"Esqueleto Guerreiro", "Liche Iniciado", "Sacerdote Profano",
			"Ent Jovem", "Urso Ancestral", "Flor da Aurora",
		],
	}

	# Duas rodadas independentes — confirma que o resultado é o MESMO
	# (determinístico), não só que bate com o esperado uma vez por sorte.
	var options1: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	var options2: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)

	var all_match_expected: bool = true
	var all_reproducible: bool = true
	var all_comum_tier1: bool = true
	var all_distinct: bool = true

	for i in range(options1.size()):
		var option1: Dictionary = options1[i]
		var option2: Dictionary = options2[i]
		var faction: String = option1["faction"]

		var names1: Array[String] = []
		for card: CardResource in option1["cards"]:
			if card.rarity != "Comum" or card.tier != 1:
				all_comum_tier1 = false
			names1.append(card.card_name)

		var seen: Dictionary = {}
		for n: String in names1:
			if seen.has(n):
				all_distinct = false
			seen[n] = true

		var names2: Array[String] = []
		for card: CardResource in option2["cards"]:
			names2.append(card.card_name)

		if names1 != expected[faction]:
			all_match_expected = false
			print("  [%s] esperado: %s | obtido: %s" % [faction, str(expected[faction]), str(names1)])
		if names1 != names2:
			all_reproducible = false

	print("  Roster de cada Facção bate exatamente com INICIALIZAÇÃO.png (ordem incluída)? %s (esperado: true)" % str(all_match_expected))
	ctx.check(all_match_expected, "O roster de cada Facção deve bater exatamente com INICIALIZAÇÃO.png (MVP aprovado)")

	print("  Duas chamadas de generate_options() produzem o mesmo roster (determinístico, sem sorteio)? %s (esperado: true)" % str(all_reproducible))
	ctx.check(all_reproducible, "generate_options() não deve mais sortear nada — o mesmo roster sempre, toda vez")

	print("  Sempre todas Comuns, Tier I? %s (esperado: true)" % str(all_comum_tier1))
	ctx.check(all_comum_tier1, "Toda carta do Kit Inicial deve ser Comum, Tier I")

	print("  Sempre as 9 cartas distintas entre si? %s (esperado: true)" % str(all_distinct))
	ctx.check(all_distinct, "As 9 cartas do Kit Inicial devem ser distintas entre si")

	return true
