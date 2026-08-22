class_name TestArmy
extends RefCounted
## TestArmy (F-001, Etapa 2)
##
## Migrado de bootstrap.gd:_validate_army() (Sprint 10). Mesmo Exército
## de exemplo do teste original (Comandante Recruta do Império + 9
## pelotões Comum Tier I) — utilizando exclusivamente Army/Soldo/
## EnergyArmy/CommanderCareer (lógica pura).
##
## _build_transient_cards() é uma cópia do helper equivalente ainda em
## uso por outra validação não migrada de bootstrap.gd (linha 465) —
## permanece lá, não foi removido.
##
## Nota de migração: o teste original não tinha "(esperado: X)"
## explícito. Os valores abaixo (Patente, Soldo, Energia, Disponibilidade,
## Pronto para batalha) foram tornados explícitos a partir da definição
## documentada (ARMY.md/SOLDO.md/ENERGY.md) e conferidos contra uma
## execução real desta mesma sessão — nenhum valor foi inventado.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Army] Validando composição de Exército de exemplo...")

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Validação"
	commander.faction = "Império"
	commander.accumulated_xp = 0  # Recruta

	var army := Army.new()
	army.kingdom_owner = "Reino de Validação"
	army.commander = commander
	army.cards = _build_transient_cards("Comum", 1, 9)

	var nucleus_level: int = 1
	var patente: String = army.commander_patente()

	print("  Comandante: %s | Patente: %s" % [commander.commander_name, patente])
	print("  Formação completa (9 pelotões): %s" % ("sim" if army.is_formation_complete() else "não"))
	print("  Soldo Total: %d / %d (%s)" % [
		army.soldo_total(), Soldo.cap_for_patente(patente),
		"dentro do teto" if army.is_soldo_within_cap() else "excede o teto"
	])
	print("  Energia Total (Núcleo Nv. %d): %d" % [nucleus_level, army.energy_total(nucleus_level)])
	print("  Disponibilidade: %s" % Army.Availability.keys()[army.availability])
	print("  Pronto para batalha: %s" % ("sim" if army.is_ready_for_battle() else "não"))

	ctx.check(patente == "Recruta", "0 XP acumulado deve resultar em Patente Recruta (obtido: %s)" % patente)
	ctx.check(army.is_formation_complete(), "9 pelotões alocados deve completar a Formação")
	ctx.check(army.soldo_total() == 9, "9 cartas Comuns devem somar Soldo Total 9 (obtido: %d)" % army.soldo_total())
	ctx.check(Soldo.cap_for_patente(patente) == 18, "Teto de Soldo do Recruta deve ser 18 (obtido: %d)" % Soldo.cap_for_patente(patente))
	ctx.check(army.is_soldo_within_cap(), "Soldo Total 9 deve estar dentro do teto de 18")
	ctx.check(army.energy_total(nucleus_level) == 150, "Energia Total (Núcleo Nv. 1, Recruta, 9x Tier I) deve ser 150 (obtido: %d)" % army.energy_total(nucleus_level))
	ctx.check(Army.Availability.keys()[army.availability] == "AVAILABLE", "Disponibilidade padrão deve ser AVAILABLE (obtido: %s)" % Army.Availability.keys()[army.availability])
	ctx.check(army.is_ready_for_battle(), "Formação completa + Soldo dentro do teto deve estar Pronto para batalha")

	return true


## Cria "count" instâncias transitórias de CardResource com Raridade e
## Tier fixos, suficiente para os cálculos de Soldo e Energia (não
## persistidas no catálogo). Cópia do helper de mesmo nome em
## bootstrap.gd, ainda em uso por validações não migradas.
static func _build_transient_cards(rarity: String, tier: int, count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.rarity = rarity
		card.tier = tier
		cards.append(card)
	return cards
