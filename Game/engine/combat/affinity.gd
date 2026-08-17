class_name Affinity
extends RefCounted
## Affinity
##
## Lógica pura do Sistema de Afinidade (AFFINITY.md) — cálculo de Pontos de
## Afinidade, determinação dos Níveis ativos (cumulativos) e
## disponibilização dos efeitos correspondentes.
##
## Puramente determinístico: todas as entradas são recebidas por
## parâmetro. Não depende de GameDatabase, Autoloads ou qualquer estado
## global.
##
## Não implementa Combate, Combat Core, Combat Rules, Habilidades,
## aplicação prática dos efeitos em batalha, Interface, IA, PvP, PvE,
## Ranking ou Matchmaking. Os efeitos de Nível II e III (e, futuramente,
## os Valores Aprimorados de Nível III) permanecem como dado descritivo,
## sem comportamento.

## Requisito de Pontos de Afinidade por Nível — regra única, compartilhada
## por todas as Facções (AFFINITY.md, "Níveis de Afinidade").
const POINTS_BY_LEVEL: Dictionary = {
	1: 2,
	2: 4,
	3: 7,
}


## Calcula os Pontos de Afinidade de uma Facção em campo: 1 ponto por
## pelotão original da Facção, +1 ponto se o Comandante pertencer à mesma
## Facção. Unidades Evocadas/Reanimadas seguem a mesma regra de 1 ponto
## cada, e podem ser incluídas em "cards" pelo chamador quando existirem
## (fora de escopo nesta Sprint, pois dependem de Combate).
##
## Os Pontos de Afinidade nunca são negativos (AFFINITY.md, "Valor Mínimo").
static func calculate_points(faction: String, cards: Array[CardResource], commander: CommanderResource) -> int:
	var points: int = 0

	for card: CardResource in cards:
		if card.faction == faction:
			points += 1

	if commander != null and commander.faction == faction:
		points += 1

	return maxi(points, 0)


## Retorna todos os Níveis de Afinidade ativos (cumulativos) para uma
## quantidade de Pontos — ex: 5 pontos ativa os Níveis [1, 2].
static func active_levels(points: int) -> Array[int]:
	var levels: Array[int] = []
	for level: int in POINTS_BY_LEVEL:
		if points >= POINTS_BY_LEVEL[level]:
			levels.append(level)
	levels.sort()
	return levels


## Retorna o Nível de Afinidade mais alto ativo para uma quantidade de
## Pontos, ou 0 caso nenhum Nível esteja ativo.
static func highest_active_level(points: int) -> int:
	var levels: Array[int] = active_levels(points)
	if levels.is_empty():
		return 0
	return levels[-1]


## Retorna os efeitos (dado descritivo) de todos os Níveis atualmente
## ativos de uma Facção, a partir do catálogo informado.
static func active_effects(faction: String, points: int, catalog: Array[AffinityLevelResource]) -> Array[AffinityLevelResource]:
	var levels: Array[int] = active_levels(points)
	return catalog.filter(func(entry: AffinityLevelResource) -> bool:
		return entry.faction == faction and levels.has(entry.level)
	)
