class_name EnemyArmyGenerator
extends RefCounted
## EnemyArmyGenerator
##
## Gera proceduralmente um EnemyArmyEntry válido, respeitando:
## - Composição (PvE.md): 6 cartas da Facção do Território + 3 cartas
##   das Facções Secundárias, podendo vir de uma só ou misturadas
##   entre as duas;
## - Restrição de Patente/Tier/Soldo por Região (PvE.md, "Hierarquia e
##   Composição dos Combates", item 3): cada Região tem sua própria
##   faixa de Patente permitida, faixa de Tier (misturado livremente
##   entre as cartas do mesmo Exército) e teto de Soldo.
##
## "Comandante Exclusivo de Campanha" (Chefes Regionais e de Mina) é
## uma especialização da própria Geração Padrão com Rarity Score
## mínimo configurável — não uma ferramenta própria de "Senhor da
## Guerra" (ver nota em PvE.md). Esse eixo (Rarity Score/Doutrina) é
## independente do eixo de Patente por Região — os dois convivem sem
## conflito, um vem do XP do Comandante, o outro da sua Doutrina.
##
## Posicionamento: generate() sempre aplica ArmyPositioningHeuristic
## (decisão confirmada — sem repetir o experimento heurística-vs-
## aleatório pra cada categoria; a conclusão de Fases Normais vale
## pra todas). O modo aleatório só existe em RegionalGenerationRunner,
## de propósito, pra esse experimento específico.

const MAX_RARITY_ATTEMPTS: int = 200
const MAX_COMPOSITION_ATTEMPTS: int = 300

## Faixa de Tier permitida por Região (PvE.md, "Estrutura das Regiões
## da Campanha") — misturada livremente entre as 9 cartas do Exército.
const REGION_TIER_RANGE: Dictionary = {
	1: [1, 2],
	2: [3, 4],
	3: [5, 5],
}

## Patentes elegíveis por Região (PvE.md, item 3) — sorteio uniforme
## entre as opções quando a categoria possui Comandante.
const REGION_PATENTE_OPTIONS: Dictionary = {
	1: ["Recruta", "Capitão", "Major"],
	2: ["Coronel", "General"],
	3: ["Marechal", "Lorde-Comandante"],
}

## Teto de Soldo da Região (PvE.md, item 3) — usado diretamente quando
## a categoria não tem Comandante (Fases Normais). Quando há
## Comandante, o teto real da Patente sorteada prevalece (ver
## _soldo_cap_for_entry()) — sempre igual ou mais restritivo, nunca
## excede o teto da Região.
const REGION_SOLDO_CAP: Dictionary = {
	1: 24,
	2: 28,
	3: 32,
}


static func generate(
	category: EnemyArmyEntry.Category,
	territory_faction: String,
	region: int,
	all_cards: Array[CardResource],
	config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	id_prefix: String,
	index: int,
	force_comum_tier1: bool = false
) -> EnemyArmyEntry:
	var entry := EnemyArmyEntry.new()
	entry.id = "%s_%05d" % [id_prefix, index]
	entry.faction = territory_faction
	entry.category = category
	entry.region_min = region
	entry.region_max = region
	entry.army_name = "%s #%d" % [territory_faction, index]
	entry.is_beginner_fase = force_comum_tier1

	entry.commander = _build_commander(
		category, territory_faction, region, config,
		commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values
	)

	var soldo_cap: int = _soldo_cap_for_entry(category, entry.commander, region)
	var composition: Array[CardResource] = build_composition(territory_faction, all_cards, region, soldo_cap, force_comum_tier1)
	entry.cards = ArmyPositioningHeuristic.apply_heuristic(composition)
	return entry


## Teto de Soldo efetivo desta entrada — o da Região quando não há
## Comandante narrativo (Fases Normais, PvE.md), ou o real da Patente
## sorteada quando há.
static func _soldo_cap_for_entry(category: EnemyArmyEntry.Category, commander: CommanderResource, region: int) -> int:
	if category == EnemyArmyEntry.Category.NORMAL:
		return REGION_SOLDO_CAP[region]
	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	return Soldo.cap_for_patente(patente)


## Composição oficial (PvE.md): 6 cartas da Facção do Território + 3
## das Facções Secundárias (uma só ou misturadas). Respeita o teto de
## Soldo por retry, e distribui o Tier de cada carta escolhida
## livremente dentro da faixa da Região (Soldo nunca muda com Tier —
## só com Raridade, SOLDO.md — então o Tier é sorteado DEPOIS de achar
## uma composição de Raridades válida, sem afetar essa validação).
static func build_composition(territory_faction: String, all_cards: Array[CardResource], region: int, soldo_cap: int, force_comum_tier1: bool = false) -> Array[CardResource]:
	var territory_cards: Array[CardResource] = all_cards.filter(func(c: CardResource) -> bool: return c.faction == territory_faction)
	var secondary_cards: Array[CardResource] = all_cards.filter(func(c: CardResource) -> bool: return c.faction != territory_faction)

	# Exceção das Primeiras Fases (PvE.md): Fases 1-10 de qualquer
	# Trilha usam só Cartas Comuns — nesse momento o jogador não tem
	# nenhuma outra forma de conseguir Recursos além das Fases do PvE.
	if force_comum_tier1:
		territory_cards = territory_cards.filter(func(c: CardResource) -> bool: return c.rarity == "Comum")
		secondary_cards = secondary_cards.filter(func(c: CardResource) -> bool: return c.rarity == "Comum")

	var tier_range: Array = [1, 1] if force_comum_tier1 else REGION_TIER_RANGE[region]

	var attempts: int = 0
	while attempts < MAX_COMPOSITION_ATTEMPTS:
		# ARMY.md, "Unicidade de Composição": nunca duas Cartas com o
		# mesmo Nome, independente do Tier — sorteio sem reposição.
		var chosen: Array[CardResource] = _pick_unique_by_name(territory_cards, 6, [])
		var chosen_names: Array[String] = []
		for card: CardResource in chosen:
			chosen_names.append(card.card_name)
		chosen.append_array(_pick_unique_by_name(secondary_cards, 3, chosen_names))

		if chosen.size() == 9 and Soldo.total_for_composition(chosen) <= soldo_cap:
			return apply_random_tiers(chosen, tier_range)

		attempts += 1

	# Extremamente improvável dado o catálogo atual, mas nunca deve
	# travar: cai para a composição mais barata disponível, sempre
	# válida — ainda respeitando a Unicidade de Composição.
	return apply_random_tiers(_cheapest_composition(territory_cards, secondary_cards), tier_range)


## Sorteia até "count" Cartas de "pool", sem repetir Nome entre si nem
## com "excluded_names" — sorteio sem reposição (embaralha e consome).
## Pode retornar menos que "count" se o pool não tiver Nomes distintos
## suficientes; quem chama já trata esse caso (chosen.size() != 9).
static func _pick_unique_by_name(pool: Array[CardResource], count: int, excluded_names: Array[String]) -> Array[CardResource]:
	var shuffled: Array[CardResource] = pool.duplicate()
	shuffled.shuffle()

	var result: Array[CardResource] = []
	var used_names: Array[String] = excluded_names.duplicate()
	for card: CardResource in shuffled:
		if result.size() >= count:
			break
		if used_names.has(card.card_name):
			continue
		result.append(card)
		used_names.append(card.card_name)
	return result


## Duplica cada carta escolhida (nunca modifica o template do
## catálogo) e sorteia seu Tier dentro da faixa da Região,
## independentemente por carta — mistura livre, PvE.md item 3.
static func apply_random_tiers(cards: Array[CardResource], tier_range: Array) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for template: CardResource in cards:
		var copy: CardResource = template.duplicate()
		copy.tier = tier_range[0] if tier_range[0] == tier_range[1] else (tier_range[0] + (randi() % (tier_range[1] - tier_range[0] + 1)))
		result.append(copy)
	return result


static func _cheapest_composition(territory_cards: Array[CardResource], secondary_cards: Array[CardResource]) -> Array[CardResource]:
	var sorted_territory: Array[CardResource] = territory_cards.duplicate()
	sorted_territory.sort_custom(func(a: CardResource, b: CardResource) -> bool: return Soldo.cost_for_rarity(a.rarity) < Soldo.cost_for_rarity(b.rarity))
	var sorted_secondary: Array[CardResource] = secondary_cards.duplicate()
	sorted_secondary.sort_custom(func(a: CardResource, b: CardResource) -> bool: return Soldo.cost_for_rarity(a.rarity) < Soldo.cost_for_rarity(b.rarity))

	# ARMY.md, "Unicidade de Composição": nunca repete Nome, mesmo
	# aqui no fallback — pega as mais baratas, mas nunca via módulo
	# (que repetiria Nome se o pool tivesse menos de 6/3 entradas).
	var chosen: Array[CardResource] = []
	var used_names: Array[String] = []
	for card: CardResource in sorted_territory:
		if chosen.size() >= 6:
			break
		if used_names.has(card.card_name):
			continue
		chosen.append(card)
		used_names.append(card.card_name)
	for card: CardResource in sorted_secondary:
		if chosen.size() >= 9:
			break
		if used_names.has(card.card_name):
			continue
		chosen.append(card)
		used_names.append(card.card_name)
	return chosen


## Constrói o Comandante da entrada. Para Fases Normais (PvE.md: "Possui
## Comandante? Não"), ainda cria um CommanderResource TÉCNICO — sem
## Doutrina nenhuma (nunca aplica Restrição/Requisito/Alvo/Efeito/Valor),
## servindo só pra satisfazer a exigência estrutural de ARMY.md ("um
## exército sempre possui exatamente um Comandante") e pra dar à
## validação de Soldo uma Patente da qual derivar o teto — nunca
## exibido ao jogador como um Comandante de verdade.
static func _build_commander(
	category: EnemyArmyEntry.Category,
	faction: String,
	region: int,
	config: SeasonConfig,
	restrictions: Array[CommanderRestrictionResource],
	requirements: Array[CommanderRequirementResource],
	targets: Array[CommanderTargetResource],
	effects: Array[CommanderEffectResource],
	values: Array[CommanderValueResource]
) -> CommanderResource:
	var patente_options: Array = REGION_PATENTE_OPTIONS[region]

	if category == EnemyArmyEntry.Category.NORMAL:
		# Sem Doutrina — Patente sempre a mais alta da faixa da Região,
		# cujo teto de Soldo bate exatamente com REGION_SOLDO_CAP (ver
		# _soldo_cap_for_entry(), que usa REGION_SOLDO_CAP diretamente
		# pra esta categoria — o valor do XP aqui não afeta a validação,
		# só existe pra Army.commander_patente() nunca falhar).
		var commander := CommanderResource.new()
		# Nome vazio ("") antes — fazia o Histórico de Batalhas do
		# Comandante do jogador mostrar "contra: " em branco pra
		# TODA Fase Normal, a categoria mais comum do jogo.
		commander.commander_name = "Comandante Técnico (%s)" % faction
		commander.faction = faction
		commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
			func(entry: Dictionary) -> bool: return entry["patente"] == patente_options[-1]
		)[0]["xp"]
		return commander

	var min_rarity: int = 0
	if category == EnemyArmyEntry.Category.CHEFE_REGIONAL or category == EnemyArmyEntry.Category.CHEFE_DE_MINA:
		min_rarity = config.min_rarity_score_exclusive

	var doctrine: CommanderDoctrine
	var attempts: int = 0
	while attempts < MAX_RARITY_ATTEMPTS:
		doctrine = CommanderGenerator.generate(restrictions, requirements, targets, effects, values)
		if doctrine.rarity_score >= min_rarity:
			break
		attempts += 1

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Gerado (%s)" % faction
	commander.faction = faction
	commander.doctrine = doctrine

	var chosen_patente: String = patente_options[randi() % patente_options.size()]
	commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
		func(entry: Dictionary) -> bool: return entry["patente"] == chosen_patente
	)[0]["xp"]

	return commander
