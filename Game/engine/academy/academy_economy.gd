class_name AcademyEconomy
extends RefCounted
## AcademyEconomy (ACADEMY.md + RESOURCES.md)
##
## Lógica pura da Academia: custo em Fragmentos por raridade (VRP),
## tempos de criação/Aprimoramento (Nível Base, reduzidos pelo Nível da
## Academia), contagem de Mestres desbloqueados por Nível, e custo em
## PG para melhorar a capacidade de fila de cada Mestre individual.

## Custo em Fragmentos para produzir 1 carta Tier I de cada raridade
## (RESOURCES.md, VRP — Valor de Referência de Produção).
const FRAGMENT_COST: Dictionary = {
	"Comum": 50,
	"Rara": 150,
	"Épica": 200,
	"Lendária": 400,
}

## Tempo de criação (Artífice), Nível Base, em segundos (ACADEMY.md,
## "Tabela de Tempos de Criação").
const CREATION_TIME_SECONDS: Dictionary = {
	"Comum": 120,
	"Rara": 480,
	"Épica": 1200,
	"Lendária": 3600,
}

## Tempo de Aprimoramento (Metamorfo), Nível Base, em segundos, por
## Tier de destino e raridade (ACADEMY.md, "Tabela de Tempos de
## Aprimoramento").
const UPGRADE_TIME_SECONDS: Dictionary = {
	2: {"Comum": 1800, "Rara": 3600, "Épica": 7200, "Lendária": 14400},
	3: {"Comum": 7200, "Rara": 14400, "Épica": 28800, "Lendária": 57600},
	4: {"Comum": 28800, "Rara": 43200, "Épica": 86400, "Lendária": 172800},
	5: {"Comum": 86400, "Rara": 129600, "Épica": 216000, "Lendária": 345600},
}

## Marcos de desbloqueio de Artífices/Metamorfos por Nível da Academia
## (ACADEMY.md, "Capacidade de Produção"). [nível_mínimo, quantidade].
const ARTIFICE_MILESTONES: Array = [
	[1, 1], [4, 2], [8, 3], [12, 4], [20, 5], [28, 6], [36, 7], [44, 8],
	[52, 9], [60, 10], [68, 11], [76, 12], [84, 13], [92, 14], [100, 15], [108, 16], [116, 17],
]
const METAMORFO_MILESTONES: Array = [
	[1, 1], [3, 2], [6, 3], [9, 4], [12, 5], [18, 6], [24, 7], [30, 8], [36, 9], [42, 10],
	[48, 11], [54, 12], [60, 13], [66, 14], [72, 15], [78, 16], [84, 17], [90, 18],
	[96, 19], [102, 20], [108, 21], [114, 22], [120, 23],
]

## Custo em PG para aumentar a capacidade de fila de UM Mestre
## (ACADEMY.md, "Melhorias das Filas") — independente por Mestre, nunca
## afeta outros. Chave = capacidade de destino.
const ARTIFICE_QUEUE_UPGRADE_COST_PG: Dictionary = {2: 2, 3: 4, 4: 8, 5: 16, 6: 32}
const METAMORFO_QUEUE_UPGRADE_COST_PG: Dictionary = {2: 2, 3: 8, 4: 32}


static func fragment_cost(rarity: String) -> int:
	return FRAGMENT_COST.get(rarity, 0)


## Redução de tempo (ACADEMY.md, "Redução de Tempo"): 0,5 ponto
## percentual por nível, limite de 60% (Nível 120). Retorna a fração
## (0.0 a 0.60), nunca o percentual bruto.
static func time_reduction(academy_level: int) -> float:
	return min(academy_level * 0.005, 0.60)


static func creation_time_seconds(rarity: String, academy_level: int) -> int:
	var base: int = CREATION_TIME_SECONDS.get(rarity, 0)
	return int(round(base * (1.0 - time_reduction(academy_level))))


static func upgrade_time_seconds(target_tier: int, rarity: String, academy_level: int) -> int:
	var base: int = UPGRADE_TIME_SECONDS.get(target_tier, {}).get(rarity, 0)
	return int(round(base * (1.0 - time_reduction(academy_level))))


static func artifice_count(academy_level: int) -> int:
	return _count_from_milestones(academy_level, ARTIFICE_MILESTONES)


static func metamorfo_count(academy_level: int) -> int:
	return _count_from_milestones(academy_level, METAMORFO_MILESTONES)


static func _count_from_milestones(academy_level: int, milestones: Array) -> int:
	var count: int = 0
	for pair: Array in milestones:
		if academy_level >= pair[0]:
			count = pair[1]
		else:
			break
	return count
