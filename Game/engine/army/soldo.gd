class_name Soldo
extends RefCounted
## Soldo
##
## Lógica pura do Sistema de Soldo (SOLDO.md) — fonte única de verdade do
## custo de Soldo por Raridade, do teto de Soldo por Patente do Comandante,
## e da validação de composição do Exército quanto ao orçamento de Soldo.
##
## Este sistema é independente de Energia (ENERGY.md) — os dois nunca são
## combinados. Não implementa Exército, Tier, XP, Combate ou Interface.

## Custo de Soldo por Raridade da carta, no nível base (independe do Tier).
const COST_BY_RARITY: Dictionary = {
	"Comum": 1,
	"Rara": 2,
	"Épica": 4,
	"Lendária": 7,
}

## Teto de Soldo disponível ao Comandante, por Patente.
const CAP_BY_PATENTE: Dictionary = {
	"Recruta": 18,
	"Capitão": 21,
	"Major": 24,
	"Coronel": 26,
	"General": 28,
	"Marechal": 30,
	"Lorde-Comandante": 32,
}


## Retorna o custo de Soldo de uma carta, a partir de sua Raridade.
static func cost_for_rarity(rarity: String) -> int:
	assert(COST_BY_RARITY.has(rarity), "Soldo: Raridade desconhecida: '%s'." % rarity)
	return COST_BY_RARITY[rarity]


## Retorna o teto de Soldo disponível para uma Patente de Comandante.
static func cap_for_patente(patente: String) -> int:
	assert(CAP_BY_PATENTE.has(patente), "Soldo: Patente desconhecida: '%s'." % patente)
	return CAP_BY_PATENTE[patente]


## Retorna o Soldo total de uma composição de cartas (soma do custo de
## Soldo de cada carta pela sua Raridade).
static func total_for_composition(cards: Array[CardResource]) -> int:
	var total: int = 0
	for card: CardResource in cards:
		total += cost_for_rarity(card.rarity)
	return total


## Retorna true se o Soldo total da composição não excede o teto da
## Patente informada.
static func is_composition_within_cap(cards: Array[CardResource], patente: String) -> bool:
	return total_for_composition(cards) <= cap_for_patente(patente)
