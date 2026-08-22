class_name TestEnergyCompositionPenalty
extends RefCounted
## TestEnergyCompositionPenalty (F-001, Etapa 15)
##
## Migrado de bootstrap.gd:_validate_energy_composition_penalty().
## Mesmo cenário original — o exploit relatado: esvaziar um Exército
## forte por combate real, dissolvê-lo, e tentar transferir suas
## Cartas/Comandante recém-usados pra um Exército fraco com Energia
## cheia, pra "herdar" a Energia alta sem pagar o custo. Também o
## caminho legítimo de controle: Cartas nunca usadas (paradas na
## coleção) não sofrem nenhuma penalidade ao trocar de Exército. Usa
## Kingdom.new() local e CommandCenterResolver/EnergyNucleus/EnergyArmy
## (confirmado sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou transitiva).
##
## Os dois primeiros checks são por desigualdade (<=), não por igualdade
## exata — preservados exatamente como no original, que nunca afirmou um
## valor exato pra Energia pós-exploit, só um teto. O terceiro check
## (Cartas nunca usadas) é o único por igualdade exata, também
## preservado como estava.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Energia] Validando a Penalidade de Composição (fecha o exploit relatado)...")

	var kingdom := Kingdom.new()
	var template: CardResource = GameDatabase.cards[0]

	# Exército 1 (forte, esvaziado por combate de verdade).
	var strong_commander := CommanderResource.new()
	strong_commander.commander_name = "Comandante Forte (Exploit)"
	strong_commander.faction = "Império"
	strong_commander.accumulated_xp = 99999  # Lorde-Comandante
	kingdom.add_commander(strong_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, strong_commander)
	var strong_cards: Array[CardResource] = []
	for i in range(9):
		strong_cards.append(kingdom.acquire_card_from_catalog(template))
	var army_1: Army = kingdom.form_army(strong_commander, strong_cards)
	army_1.consume_energy(army_1.current_energy)  # esvazia de verdade, igual combate real faria
	kingdom.disband_army(army_1)  # libera Comandante/Cartas de volta pro Reino — único jeito real de "soltar" o que já está em uso

	# Exército 2 (fraco, Energia cheia).
	var weak_commander := CommanderResource.new()
	weak_commander.commander_name = "Comandante Fraco (Exploit)"
	weak_commander.faction = "Império"
	kingdom.add_commander(weak_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, weak_commander)
	var weak_cards: Array[CardResource] = []
	for i in range(9):
		weak_cards.append(kingdom.acquire_card_from_catalog(template))
	var army_2: Army = kingdom.form_army(weak_commander, weak_cards)
	print("  Exército 2 antes do exploit: %d/%d de Energia (esperado: cheio)" % [army_2.current_energy, army_2.max_energy])
	ctx.check(army_2.current_energy == army_2.max_energy, "Exército 2 deve começar com Energia cheia (obtido: %d/%d)" % [army_2.current_energy, army_2.max_energy])

	# Tenta o exploit: transfere as Cartas fortes (recém-saídas do
	# combate) pro Exército 2, depois o Comandante forte também.
	kingdom.re_form_army(army_2, weak_commander, strong_cards)
	print("  Depois de receber Cartas RECÉM-USADAS -> perdeu a porção de Cartas de verdade? %s (%d, esperado: <= Base + Comandante Fraco = %d)" % [
		str(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + EnergyArmy.commander_energy("Recruta")),
		army_2.current_energy, EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + EnergyArmy.commander_energy("Recruta")
	])
	ctx.check(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + EnergyArmy.commander_energy("Recruta"), "Energia do Exército 2 deve respeitar o teto Base + Comandante Fraco (obtido: %d)" % army_2.current_energy)

	kingdom.re_form_army(army_2, strong_commander, strong_cards)
	print("  Depois de receber o Comandante forte também -> ficou só com Energia Base, sem exploit? %s (%d, esperado: <= %d)" % [
		str(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + 5),
		army_2.current_energy, EnergyNucleus.energia_base(kingdom.energy_nucleus_level)
	])
	ctx.check(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + 5, "Energia do Exército 2 deve continuar sem exploit após herdar o Comandante forte (obtido: %d)" % army_2.current_energy)

	# --- Caminho legítimo: Cartas paradas (nunca usadas) não sofrem penalidade ---
	var kingdom_2 := Kingdom.new()
	var commander_3 := CommanderResource.new()
	commander_3.commander_name = "Comandante de Teste (Cartas Descansadas)"
	commander_3.faction = "Império"
	kingdom_2.add_commander(commander_3, GameClock.now_unix())
	kingdom_2.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom_2, commander_3)
	var initial_cards: Array[CardResource] = []
	for i in range(9):
		initial_cards.append(kingdom_2.acquire_card_from_catalog(template))
	var army_3: Army = kingdom_2.form_army(commander_3, initial_cards)
	var army_3_energy_before: int = army_3.current_energy

	var dormant_cards: Array[CardResource] = []
	for i in range(9):
		dormant_cards.append(kingdom_2.acquire_card_from_catalog(template))  # nunca estiveram em nenhum Exército
	kingdom_2.re_form_army(army_3, commander_3, dormant_cards)
	print("  Trocar por Cartas NUNCA usadas (paradas na coleção) -> sem penalidade nenhuma? %s (%d -> %d, esperado: igual)" % [
		str(army_3.current_energy == army_3_energy_before), army_3_energy_before, army_3.current_energy
	])
	ctx.check(army_3.current_energy == army_3_energy_before, "Cartas nunca usadas não devem causar nenhuma penalidade de Energia (antes: %d, depois: %d)" % [army_3_energy_before, army_3.current_energy])

	return true
