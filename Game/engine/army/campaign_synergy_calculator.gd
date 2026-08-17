class_name CampaignSynergyCalculator
extends RefCounted
## CampaignSynergyCalculator
##
## Calcula quais Sinergias de Campanha (ABILITIES.md, "Sinergia de
## Campanha") estão ativas em um conjunto de cartas.
##
## Pura e determinística — sem qualquer dependência de CombatEngine,
## CombatEventBus, AbilityRuntime, EffectRuntime ou do sistema de
## PvE/Campanha (ainda não implementado). Recebe apenas Array[CardResource]
## (ex: Army.cards), mesmo padrão já usado por Soldo/Affinity.
##
## Sinergia é BINÁRIA (ativa ou não) — não graduada em Níveis. Isso é
## deliberado: Afinidade (AFFINITY.md/Affinity) tem Níveis I/II/III;
## Sinergia de Campanha não. A definição oficial (ABILITIES.md) é:
## "Sinergia representa a interação entre dois ou mais pelotões
## diferentes presentes no mesmo Exército que possuem a mesma Habilidade
## de Campanha." Ou seja: 2+ cartas compartilhando a mesma Habilidade de
## Campanha (tier_3_ability_name) ativam a Sinergia; nada além disso.
##
## Não implementa efeitos, Runtime, registro em evento ou integração com
## Combate/PvE — apenas responde "quais Sinergias este conjunto de
## cartas possui". Ver Sprint 27 para onde essa resposta será consumida.


## Retorna um Dictionary[String, bool]: nome da Habilidade de Campanha
## (tier_3_ability_name) -> Sinergia ativa (true se 2 ou mais cartas do
## conjunto a compartilham). Cartas sem Habilidade de Campanha
## (tier_3_ability_name == "") são ignoradas. Um Exército vazio retorna
## um Dictionary vazio.
static func calculate(cards: Array[CardResource]) -> Dictionary:
	var counts: Dictionary = {}

	for card: CardResource in cards:
		if card.tier_3_ability_name == "":
			continue
		counts[card.tier_3_ability_name] = counts.get(card.tier_3_ability_name, 0) + 1

	var result: Dictionary = {}
	for ability_name: String in counts:
		result[ability_name] = counts[ability_name] >= 2

	return result


## Retorna apenas os nomes das Habilidades de Campanha com Sinergia
## ativa (conveniência sobre calculate()).
static func active_synergies(cards: Array[CardResource]) -> Array[String]:
	var result: Array[String] = []
	var synergies: Dictionary = calculate(cards)

	for ability_name: String in synergies:
		if synergies[ability_name]:
			result.append(ability_name)

	return result
