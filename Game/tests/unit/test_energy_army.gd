class_name TestEnergyArmy
extends RefCounted
## TestEnergyArmy (F-001, Etapa 3)
##
## Migrado de bootstrap.gd:_validate_energy_army() (Sprint 9). Mesmo
## "Exército de Referência" do teste original (Núcleo de Energia nível
## 1, Comandante Recruta, 9 cartas Tier I) — utilizando exclusivamente
## EnergyNucleus/EnergyArmy (lógica pura, já provadas puras na Etapa 2).
##
## _build_transient_cards_by_tier() é cópia do helper de mesmo nome em
## bootstrap.gd — único chamador original confirmado antes da migração,
## removido de lá junto com a validação.
##
## Nota de migração: o teste original não tinha "(esperado: X)"
## explícito. Os valores abaixo vêm diretamente das fórmulas de
## ENERGY_NUCLEUS.md/ENERGY.md, já conferidos contra uma execução real
## desta mesma sessão (mesmo Exército de Referência migrado em TestArmy,
## Etapa 2: Energia Total 150). Nenhum valor foi inventado.

static func run(ctx: TestRunner.Context) -> bool:
	print("[EnergyArmy] Validando Exército de Referência (ENERGY.md)...")

	var nucleus_level: int = 1
	var patente: String = "Recruta"
	var cards: Array[CardResource] = _build_transient_cards_by_tier(1, 9)

	var base: int = EnergyNucleus.energia_base(nucleus_level)
	var commander: int = EnergyArmy.commander_energy(patente)
	var troops: int = EnergyArmy.total_card_energy(cards)
	var total: int = EnergyArmy.total_energy(nucleus_level, patente, cards)

	print("  Energia Base (Núcleo Nv. %d): %d" % [nucleus_level, base])
	print("  Energia do Comandante (%s): %d" % [patente, commander])
	print("  Energia das Cartas (9x Tier I): %d" % troops)
	print("  Energia Total: %d" % total)

	ctx.check(base == 40, "Energia Base do Núcleo Nv. 1 deve ser 40 (obtido: %d)" % base)
	ctx.check(commander == 20, "Energia do Comandante Recruta deve ser 20 (obtido: %d)" % commander)
	ctx.check(troops == 90, "Energia de 9 cartas Tier I deve ser 90 (obtido: %d)" % troops)
	ctx.check(total == 150, "Energia Total do Exército de Referência deve ser 150 (obtido: %d)" % total)

	return true


## Cria "count" instâncias transitórias de CardResource em um Tier fixo,
## suficiente para o cálculo de Energia (não persistidas no catálogo).
## Cópia do helper de mesmo nome em bootstrap.gd, removido de lá após
## esta migração (único chamador).
static func _build_transient_cards_by_tier(tier: int, count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.tier = tier
		cards.append(card)
	return cards
