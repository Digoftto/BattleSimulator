class_name TestArmyFormationArchetypes
extends RefCounted
## TestArmyFormationArchetypes (F-001, Etapa 15 — migração PARCIAL)
##
## Migrado de bootstrap.gd:_validate_army_formation_archetypes(),
## primeira metade apenas: ArmyFormationArchetypes.generate_all() sobre
## 9 CardResource construídas na mão, validando as 4 Arquétipos de
## Formação (ARMY.md) — β (Ofensiva: maior Ataque na Posição 1, Arqueiros
## nas Posições 6/7), γ (Defensiva: maior Escudo na Posição 1), δ
## (Equilibrada: nem o maior Ataque nem o maior Escudo isolados na
## Posição 1), Máquina de Guerra sempre na Posição 9 nas 4, e as 4
## Formações mutuamente diferentes entre si. Pura — nenhuma referência a
## Kingdom/KingdomState.
##
## A segunda metade do original ("--- Kingdom.form_army() gera as 5
## Formações automaticamente... ---") foi DELIBERADAMENTE excluída desta
## migração — lê KingdomState.kingdom diretamente (estado global), fora
## do escopo desta etapa. Permanece em bootstrap.gd, intocada, ainda
## reaproveitando as mesmas 9 CardResource construídas ali (necessário
## para o form_army() de verdade), agora sem a computação de arquétipos
## que já foi migrada para cá.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Exército] Validando os 4 Arquétipos de Formação (β, γ, δ, ε)...")

	var cards: Array[CardResource] = []
	var cqc_low := CardResource.new()
	cqc_low.card_name = "CQC Fraco"; cqc_low.card_class = "Corpo a Corpo"; cqc_low.faction = "Império"; cqc_low.rarity = "Comum"; cqc_low.tier = 1; cqc_low.atk = 50; cqc_low.hp = 100; cqc_low.esc = 10
	var cqc_high := CardResource.new()
	cqc_high.card_name = "CQC Forte"; cqc_high.card_class = "Corpo a Corpo"; cqc_high.faction = "Império"; cqc_high.rarity = "Comum"; cqc_high.tier = 1; cqc_high.atk = 300; cqc_high.hp = 100; cqc_high.esc = 10
	var barreira_low := CardResource.new()
	barreira_low.card_name = "Barreira Fraca"; barreira_low.card_class = "Barreira"; barreira_low.faction = "Império"; barreira_low.rarity = "Comum"; barreira_low.tier = 1; barreira_low.atk = 40; barreira_low.hp = 100; barreira_low.esc = 50
	var barreira_high := CardResource.new()
	barreira_high.card_name = "Barreira Forte"; barreira_high.card_class = "Barreira"; barreira_high.faction = "Império"; barreira_high.rarity = "Comum"; barreira_high.tier = 1; barreira_high.atk = 40; barreira_high.hp = 100; barreira_high.esc = 200
	var ranged_1 := CardResource.new()
	ranged_1.card_name = "Arqueiro 1"; ranged_1.card_class = "À Distância"; ranged_1.faction = "Império"; ranged_1.rarity = "Comum"; ranged_1.tier = 1; ranged_1.atk = 90; ranged_1.hp = 60; ranged_1.esc = 15
	var ranged_2 := CardResource.new()
	ranged_2.card_name = "Arqueiro 2"; ranged_2.card_class = "À Distância"; ranged_2.faction = "Império"; ranged_2.rarity = "Comum"; ranged_2.tier = 1; ranged_2.atk = 90; ranged_2.hp = 60; ranged_2.esc = 15
	var mago := CardResource.new()
	mago.card_name = "Mago"; mago.card_class = "Mago"; mago.faction = "Império"; mago.rarity = "Comum"; mago.tier = 1; mago.atk = 120; mago.hp = 70; mago.esc = 10
	var suporte := CardResource.new()
	suporte.card_name = "Suporte"; suporte.card_class = "Suporte"; suporte.faction = "Império"; suporte.rarity = "Comum"; suporte.tier = 1; suporte.atk = 60; suporte.hp = 90; suporte.esc = 10
	var maquina := CardResource.new()
	maquina.card_name = "Máquina"; maquina.card_class = "Máquina de Guerra"; maquina.faction = "Império"; maquina.rarity = "Comum"; maquina.tier = 1; maquina.atk = 70; maquina.hp = 80; maquina.esc = 50
	cards = [cqc_low, cqc_high, barreira_low, barreira_high, ranged_1, ranged_2, mago, suporte, maquina]

	var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(cards)

	var beta: Array[CardResource] = archetypes["β"]
	print("  β (Ofensiva) -> Posição 1 é o Corpo a Corpo de maior Ataque? %s | Arqueiros nas Posições 6 e 7? %s (esperado: true, true)" % [
		str(beta[0] == cqc_high), str((beta[5] == ranged_1 or beta[5] == ranged_2) and (beta[6] == ranged_1 or beta[6] == ranged_2) and beta[5] != beta[6])
	])
	ctx.check(beta[0] == cqc_high, "β deve ter o Corpo a Corpo de maior Ataque na Posição 1")
	ctx.check((beta[5] == ranged_1 or beta[5] == ranged_2) and (beta[6] == ranged_1 or beta[6] == ranged_2) and beta[5] != beta[6], "β deve ter os 2 Arqueiros nas Posições 6 e 7")

	var gamma: Array[CardResource] = archetypes["γ"]
	print("  γ (Defensiva) -> Posição 1 é a Barreira de maior Escudo? %s (esperado: true)" % str(gamma[0] == barreira_high))
	ctx.check(gamma[0] == barreira_high, "γ deve ter a Barreira de maior Escudo na Posição 1")

	var delta: Array[CardResource] = archetypes["δ"]
	print("  δ (Equilibrada) -> Posição 1 NÃO é o maior Ataque nem o maior Escudo isolados? %s (esperado: true)" % str(
		delta[0] != cqc_high and delta[0] != barreira_high
	))
	ctx.check(delta[0] != cqc_high and delta[0] != barreira_high, "δ não deve ter na Posição 1 nem o maior Ataque nem o maior Escudo isolados")

	var epsilon: Array[CardResource] = archetypes["ε"]
	print("  Todas as 4 têm Máquina de Guerra na Posição 9? %s (esperado: true)" % str(
		beta[8] == maquina and gamma[8] == maquina and delta[8] == maquina and epsilon[8] == maquina
	))
	ctx.check(beta[8] == maquina and gamma[8] == maquina and delta[8] == maquina and epsilon[8] == maquina, "As 4 Formações devem ter a Máquina de Guerra na Posição 9")

	print("  As 4 Formações são diferentes entre si (nenhuma idêntica)? %s (esperado: true)" % str(
		beta != gamma and beta != delta and beta != epsilon and gamma != delta and gamma != epsilon and delta != epsilon
	))
	ctx.check(beta != gamma and beta != delta and beta != epsilon and gamma != delta and gamma != epsilon and delta != epsilon, "As 4 Formações devem ser mutuamente diferentes")

	return true
