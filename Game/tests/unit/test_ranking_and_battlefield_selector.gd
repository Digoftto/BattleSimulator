class_name TestRankingAndBattlefieldSelector
extends RefCounted
## TestRankingAndBattlefieldSelector (F-001, Etapa 10)
##
## Migrado de bootstrap.gd:_validate_ranking_and_battlefield_selector().
## Mesmo cenário original — validação pura de RankingResolver (RANKING.md)
## e BattlefieldSelector (BATTLEFIELDS.md), sem UI, sem renderização, sem
## Kingdom. BattlefieldSelector.select() usa RNG determinística por seed
## explícita fornecida pelo chamador (seed=777, preservada exatamente
## como estava — nenhuma seed nova, nenhuma seed removida).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Ranking] Validando RankingResolver e BattlefieldSelector...")

	# Atacante, Divisões VII-III: Vitória +100, Derrota -75.
	var win: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.VITORIA)
	print("  Atacante, Divisão VII, Vitória: 500 -> %d PL (esperado: 600)" % win["pl"])
	ctx.check(win["pl"] == 600, "Atacante Vitória (Divisão VII) deve render 500 -> 600 PL (obtido: %d)" % win["pl"])

	var loss: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  Atacante, Divisão VII, Derrota: 500 -> %d PL (esperado: 425 = 500-75)" % loss["pl"])
	ctx.check(loss["pl"] == 425, "Atacante Derrota (Divisão VII) deve render 500 -> 425 PL (obtido: %d)" % loss["pl"])

	# Atacante, Divisões II-I: Derrota -100 (não -75).
	var loss_top: Dictionary = RankingResolver.apply_result(5500, "II", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  Atacante, Divisão II, Derrota: 5500 -> %d PL (esperado: 5400 = 5500-100, não -75)" % loss_top["pl"])
	ctx.check(loss_top["pl"] == 5400, "Atacante Derrota (Divisão II) deve render 5500 -> 5400 PL, penalidade -100 (obtido: %d)" % loss_top["pl"])

	# Defensor: sempre +20/-20, em qualquer Divisão.
	var def_win: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.DEFENSOR, RankingResolver.Result.VITORIA)
	var def_loss: Dictionary = RankingResolver.apply_result(5500, "II", RankingResolver.Role.DEFENSOR, RankingResolver.Result.DERROTA)
	print("  Defensor Vitória (Divisão VII): 500 -> %d PL (esperado: 520) | Defensor Derrota (Divisão II): 5500 -> %d PL (esperado: 5480)" % [
		def_win["pl"], def_loss["pl"]
	])
	ctx.check(def_win["pl"] == 520, "Defensor Vitória deve render 500 -> 520 PL (obtido: %d)" % def_win["pl"])
	ctx.check(def_loss["pl"] == 5480, "Defensor Derrota deve render 5500 -> 5480 PL (obtido: %d)" % def_loss["pl"])

	# Empate nunca altera PL, em nenhum papel.
	var draw: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.EMPATE)
	print("  Empate nunca altera PL: 500 -> %d PL (esperado: 500)" % draw["pl"])
	ctx.check(draw["pl"] == 500, "Empate nunca deve alterar PL (obtido: %d)" % draw["pl"])

	# Promoção automática ao cruzar o teto da Divisão.
	var promotion: Dictionary = RankingResolver.apply_result(950, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.VITORIA)
	print("  950 PL + Vitória (+100) cruza pra Divisão VI -> Divisão: %s | Promovido? %s (esperado: VI, true)" % [
		promotion["division"], str(promotion["promoted"])
	])
	ctx.check(promotion["division"] == "VI", "Cruzar o teto deve promover para Divisão VI (obtido: %s)" % promotion["division"])
	ctx.check(promotion["promoted"] == true, "Cruzar o teto deve marcar promoted = true")

	# Nunca rebaixa abaixo da Divisão VII.
	var floor_result: Dictionary = RankingResolver.apply_result(10, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  10 PL + Derrota (-75) não fica negativo nem sai da Divisão VII -> PL: %d | Divisão: %s (esperado: 0, VII)" % [
		floor_result["pl"], floor_result["division"]
	])
	ctx.check(floor_result["pl"] == 0, "PL nunca deve ficar negativo (obtido: %d)" % floor_result["pl"])
	ctx.check(floor_result["division"] == "VII", "Nunca deve rebaixar abaixo da Divisão VII (obtido: %s)" % floor_result["division"])

	# Reentrada: 2 Divisões abaixo da final anterior, com o PL mínimo exato.
	var reentry_div: String = RankingResolver.reentry_division("IV")
	print("  Reentrada vindo da Divisão IV -> Divisão: %s | PL: %d (esperado: VI, 1000)" % [
		reentry_div, RankingResolver.reentry_pl(reentry_div)
	])
	ctx.check(reentry_div == "VI", "Reentrada da Divisão IV deve cair na Divisão VI (obtido: %s)" % reentry_div)
	ctx.check(RankingResolver.reentry_pl(reentry_div) == 1000, "PL de reentrada deve ser 1000 (obtido: %d)" % RankingResolver.reentry_pl(reentry_div))

	# BattlefieldSelector: determinístico com a mesma seed, e sempre
	# dentro do subconjunto fornecido (mesmo restrito).
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var result_a: BattlefieldResource = BattlefieldSelector.select(GameDatabase.battlefields, rng_a)
	var result_b: BattlefieldResource = BattlefieldSelector.select(GameDatabase.battlefields, rng_b)
	print("  Mesma seed gera o mesmo Campo sorteado? %s (esperado: true)" % str(result_a == result_b))
	ctx.check(result_a == result_b, "A mesma seed deve gerar o mesmo Campo de Batalha sorteado")

	var only_padrao: Array[BattlefieldResource] = []
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category == "Padrão":
			only_padrao.append(battlefield)
	var restricted_result: BattlefieldResource = BattlefieldSelector.select(only_padrao, rng_a)
	print("  Sorteio restrito a um subconjunto de 1 Campo sempre retorna esse Campo? %s (esperado: true)" % str(
		restricted_result.category == "Padrão"
	))
	ctx.check(restricted_result.category == "Padrão", "Sorteio restrito a um subconjunto deve sempre retornar um Campo desse subconjunto")

	return true
