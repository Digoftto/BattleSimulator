class_name TestEnergyRecalculatesOnCompositionChange
extends RefCounted
## TestEnergyRecalculatesOnCompositionChange (F-001, Etapa 14)
##
## Migrado de bootstrap.gd:_validate_energy_recalculates_on_composition_change().
## Mesmo cenário original — validação FUNCIONAL do bug real relatado:
## Energia Máxima nunca era recalculada quando a composição do Exército
## mudava (ARMY.md: "sempre que a composição... for alterada... a
## energia máxima será recalculada automaticamente"). Usa Kingdom.new()
## local, CommandCenterResolver e GameRuntime.sync() (forma limpa, sem
## Minas criadas — confirmado sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/WorldBootstrap, direta ou
## transitiva).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Energia] Validando o recálculo de Energia Máxima ao mudar a composição (bug relatado)...")

	var kingdom := Kingdom.new()
	var weak_commander := CommanderResource.new()
	weak_commander.commander_name = "Comandante Recruta (Energia)"
	weak_commander.faction = "Império"
	kingdom.add_commander(weak_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, weak_commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(weak_commander, cards)
	var energy_before: int = army.max_energy

	# Comandante de Patente muito maior -> Energia do Comandante muda
	# de verdade (Recruta=20 vs Lorde-Comandante=50, ENERGY.md).
	var strong_commander := CommanderResource.new()
	strong_commander.commander_name = "Comandante Lorde (Energia)"
	strong_commander.faction = "Império"
	strong_commander.accumulated_xp = 99999
	kingdom.add_commander(strong_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, strong_commander)

	kingdom.re_form_army(army, strong_commander, cards.duplicate())
	print("  Trocar pra um Comandante de Patente maior recalcula a Energia Máxima de verdade? %s (%d -> %d, esperado: aumentou 30)" % [
		str(army.max_energy == energy_before + 30), energy_before, army.max_energy
	])
	ctx.check(army.max_energy == energy_before + 30, "Trocar de Comandante deve recalcular a Energia Máxima (+30, obtido: %d -> %d)" % [energy_before, army.max_energy])

	# Tier de uma carta JÁ dentro do Exército muda -> GameRuntime.sync()
	# precisa recalcular sozinho, sem precisar editar a composição.
	var energy_before_tier: int = army.max_energy
	cards[0].tier = 5  # ENERGY.md: Tier I=10, Tier V=14 -> +4 de Energia
	GameRuntime.sync(kingdom, GameClock.now_unix())
	print("  Tier de uma carta já no Exército mudando (Academia) recalcula sozinho, sem editar a composição? %s (%d -> %d, esperado: aumentou 4)" % [
		str(army.max_energy == energy_before_tier + 4), energy_before_tier, army.max_energy
	])
	ctx.check(army.max_energy == energy_before_tier + 4, "Mudar o Tier de uma carta já no Exército deve recalcular a Energia Máxima sozinho via sync() (+4, obtido: %d -> %d)" % [energy_before_tier, army.max_energy])

	return true
