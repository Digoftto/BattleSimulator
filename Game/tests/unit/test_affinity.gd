class_name TestAffinity
extends RefCounted
## TestAffinity (F-001, Etapa 2)
##
## Migrado de bootstrap.gd:_validate_affinity() (Sprint 11). Mesma
## simulação original (Comandante do Império sozinho, depois 9
## pelotões do Império adicionados um a um) — utilizando exclusivamente
## Affinity (lógica pura, não depende de GameDatabase/Autoloads) mais
## GameDatabase.affinity_levels apenas como catálogo de leitura (dado
## de referência já carregado automaticamente pelo Autoload, nunca
## mutado por este teste).
##
## Nota de migração: o teste original não tinha "(esperado: X)"
## explícito. Os marcos abaixo vêm diretamente de Affinity.POINTS_BY_LEVEL
## ({1: 2, 2: 4, 3: 7}, affinity.gd) — Comandante sozinho = 1 ponto
## (Nível 0); 9 pelotões + Comandante = 10 pontos (Nível 3, o máximo
## definido). Nenhuma regra de AFFINITY.md foi reinterpretada.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Affinity] Validando Pontos e Níveis de Afinidade (Império)...")

	var commander := CommanderResource.new()
	commander.faction = "Império"

	var cards: Array[CardResource] = []
	var points: int = Affinity.calculate_points("Império", cards, commander)
	var previous_level: int = Affinity.highest_active_level(points)
	print("  Pontos: %d | Nível ativo: %d (apenas Comandante)" % [points, previous_level])
	ctx.check(points == 1 and previous_level == 0, "apenas Comandante deve dar 1 ponto e Nível 0 (obtido: %d ponto(s), Nível %d)" % [points, previous_level])

	for i in range(9):
		var card := CardResource.new()
		card.faction = "Império"
		cards.append(card)

		points = Affinity.calculate_points("Império", cards, commander)
		var level: int = Affinity.highest_active_level(points)
		if level != previous_level:
			print("  Pontos: %d | Nível ativo: %d (%d pelotões do Império + Comandante)" % [points, level, cards.size()])
			previous_level = level

	print("[Affinity] Efeitos ativos no Nível máximo atingido:")
	var active: Array[AffinityLevelResource] = Affinity.active_effects("Império", points, GameDatabase.affinity_levels)
	for entry: AffinityLevelResource in active:
		print("  Nível %d: %s" % [entry.level, entry.effect_description])

	ctx.check(points == 10, "9 pelotões + Comandante do Império deve somar 10 pontos (obtido: %d)" % points)
	ctx.check(previous_level == 3, "10 pontos deve ativar o Nível máximo definido (3) (obtido: %d)" % previous_level)

	var all_match_faction_and_level: bool = true
	for entry: AffinityLevelResource in active:
		if entry.faction != "Império" or not [1, 2, 3].has(entry.level):
			all_match_faction_and_level = false
	ctx.check(not active.is_empty() and all_match_faction_and_level, "efeitos ativos devem pertencer ao Império e a Níveis 1-3 (%d entrada(s))" % active.size())

	return true
