class_name EnergyArmy
extends RefCounted
## EnergyArmy
##
## Lógica pura do cálculo de Energia Total de um Exército (ENERGY.md),
## como a soma de 3 fontes independentes: Energia Base (Núcleo de
## Energia), Energia do Comandante (Patente) e Energia das Cartas (Tier).
##
## Puramente determinístico: todas as entradas são recebidas como
## parâmetros (nível do Núcleo, Patente, lista de cartas). Não depende de
## GameDatabase, CommanderResource ou qualquer outro singleton/autoload,
## para facilitar testes, reuso e integração futura com ARMY.md e
## COMBAT_CORE.md.
##
## Não implementa Consumo de Energia por modo de jogo, Recuperação,
## Cidade, Acampamentos, Combate, Exército ou Interface.

## Energia concedida pela Liderança do Comandante, por Patente.
## Grafia de Patente alinhada à SSOT (XP.md): "Lorde-Comandante" (com hífen).
const ENERGY_BY_PATENTE: Dictionary = {
	"Recruta": 20,
	"Capitão": 25,
	"Major": 30,
	"Coronel": 35,
	"General": 40,
	"Marechal": 45,
	"Lorde-Comandante": 50,
}

## Energia concedida pela Resistência das Tropas, por Tier da carta (1-5).
const ENERGY_BY_TIER: Dictionary = {
	1: 10,
	2: 11,
	3: 12,
	4: 13,
	5: 14,
}


## Retorna a Energia concedida pela Liderança de uma Patente de Comandante.
static func commander_energy(patente: String) -> int:
	assert(ENERGY_BY_PATENTE.has(patente), "EnergyArmy: Patente desconhecida: '%s'." % patente)
	return ENERGY_BY_PATENTE[patente]


## Retorna a Energia concedida pela Resistência de uma carta em um Tier.
static func card_energy(tier: int) -> int:
	assert(ENERGY_BY_TIER.has(tier), "EnergyArmy: Tier desconhecido: %d." % tier)
	return ENERGY_BY_TIER[tier]


## Retorna a soma da Energia de Resistência de todas as cartas informadas.
static func total_card_energy(cards: Array[CardResource]) -> int:
	var total: int = 0
	for card: CardResource in cards:
		total += card_energy(card.tier)
	return total


## Retorna a Energia Total do Exército: Energia Base (nível do Núcleo) +
## Energia do Comandante (Patente) + soma da Energia das Cartas (Tiers).
static func total_energy(nucleus_level: int, patente: String, cards: Array[CardResource]) -> int:
	var base: int = EnergyNucleus.energia_base(nucleus_level)
	var commander: int = commander_energy(patente)
	var troops: int = total_card_energy(cards)
	return base + commander + troops


## ENERGY.md, "Penalidade de Composição": tempo (em segundos) que o
## Núcleo de Energia, no nível informado, levaria pra recuperar do
## zero a Energia equivalente a 9 Cartas Tier I — a Janela de
## Reutilização que decide se uma Carta recém-saída de outro Exército
## entra "descansada" ou "recém-usada" num Exército novo.
static func reuse_window_seconds(nucleus_level: int) -> int:
	return 9 * card_energy(1) * EnergyNucleus.recovery_seconds(nucleus_level)
