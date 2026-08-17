class_name EnemyArmySelector
extends RefCounted
## EnemyArmySelector
##
## Consulta o SeasonCatalog (já pronto, gerado offline pelo
## SeasonPipeline) para selecionar deterministicamente o Exército
## Inimigo de uma Fase, usando a semente (seed) da Expedição. Nunca
## gera Exércitos — apenas consulta e sorteia dentro da faixa correta.


static func select(
	catalog: SeasonCatalog,
	faction: String,
	category: EnemyArmyEntry.Category,
	region: int,
	fase: int,
	expedition_seed: int,
	regional_commander_registry: RegionalCommanderRegistry
) -> EnemyArmyEntry:
	var effective_category: EnemyArmyEntry.Category = category

	# Comandante Regional Recrutado (PvE.md): se o Chefe Regional daquela
	# Região já pertence ao Reino do jogador, a Fase passa a usar um
	# Exército da categoria Chefe Normal da mesma Região — mesma Fase,
	# mesma marcação de Fase Especial, categoria diferente.
	if category == EnemyArmyEntry.Category.CHEFE_REGIONAL and regional_commander_registry != null:
		if regional_commander_registry.is_recruited(faction, region):
			effective_category = EnemyArmyEntry.Category.CHEFE_NORMAL

	var candidates: Array[EnemyArmyEntry] = catalog.get_entries_for_region(faction, effective_category, region)

	# Exceção das Primeiras Fases (PvE.md): Fases 1-10 de qualquer
	# Trilha sorteiam exclusivamente do lote Iniciante (Comum/Tier I);
	# qualquer outra Fase nunca sorteia dele, mesmo que exista.
	if fase <= 10:
		var beginner_candidates: Array[EnemyArmyEntry] = candidates.filter(func(e: EnemyArmyEntry) -> bool: return e.is_beginner_fase)
		if not beginner_candidates.is_empty():
			candidates = beginner_candidates
	else:
		candidates = candidates.filter(func(e: EnemyArmyEntry) -> bool: return not e.is_beginner_fase)

	if candidates.is_empty():
		return null

	var rng := RandomNumberGenerator.new()
	rng.seed = _combine_seed(expedition_seed, fase, effective_category)
	var index: int = rng.randi() % candidates.size()
	var selected: EnemyArmyEntry = candidates[index]

	# Chefe de Mina (PvE.md/MINES.md): reaproveita a mesma composição de
	# cartas de um Chefe Regional (mesmo catálogo, mesma banda de
	# força), mas nunca a posição. Embaralhar a ordem das 9 cartas faz
	# a formação deixar de ser "a mais eficiente" possível para aquela
	# composição — continua forte (mesmas cartas), mas mal posicionada.
	# Isso só importa para a batalha única de conquista da Mina: uma
	# vez conquistada, o Ciclo de Mineração testa todas as 362.880
	# posições possíveis da Formação de Referência (não apenas esta),
	# então a posição embaralhada aqui deixa de ter efeito a partir daí
	# (MINES.md, "Formação de Referência"). Reaproveita o mesmo "rng"
	# já semeado por _combine_seed() acima: determinístico (mesma seed
	# = mesmo embaralhamento sempre), sem precisar de uma segunda semente.
	if effective_category == EnemyArmyEntry.Category.CHEFE_DE_MINA:
		selected = _with_shuffled_positions(selected, rng)

	return selected


## Retorna uma cópia de "entry" com as 9 cartas em ordem embaralhada
## (Fisher-Yates), preservando identidade, Facção, Comandante e WR
## originais — só a posição no tabuleiro muda.
static func _with_shuffled_positions(entry: EnemyArmyEntry, rng: RandomNumberGenerator) -> EnemyArmyEntry:
	var shuffled := EnemyArmyEntry.new()
	shuffled.id = entry.id
	shuffled.army_name = entry.army_name
	shuffled.faction = entry.faction
	shuffled.category = entry.category
	shuffled.region_min = entry.region_min
	shuffled.region_max = entry.region_max
	shuffled.commander = entry.commander
	shuffled.win_rate = entry.win_rate
	shuffled.cards = entry.cards.duplicate()
	_fisher_yates_shuffle(shuffled.cards, rng)
	return shuffled


static func _fisher_yates_shuffle(cards: Array[CardResource], rng: RandomNumberGenerator) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: CardResource = cards[i]
		cards[i] = cards[j]
		cards[j] = tmp


## Combina semente da Expedição + Fase + Categoria em uma única semente
## determinística: mesma Trilha + mesma Seed + mesma Fase sempre produz
## o mesmo Exército; seeds diferentes podem produzir Exércitos
## diferentes.
static func _combine_seed(expedition_seed: int, fase: int, category: EnemyArmyEntry.Category) -> int:
	return expedition_seed * 1000003 + fase * 97 + int(category)
