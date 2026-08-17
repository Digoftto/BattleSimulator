class_name CardProgression
extends RefCounted
## CardProgression
##
## Lógica pura do Aprimoramento de Cartas, conforme CARD_PROGRESSION.md.
##
## Responsabilidades desta classe:
## - Aplicar os incrementos de atributos dos Tiers II e IV.
## - Reconhecer o nome da Habilidade desbloqueada nos Tiers III e V,
##   como dado de catálogo — sem implementar qualquer comportamento
##   dessa Habilidade (ver ABILITIES.md, fora de escopo).
##
## Esta classe não conhece Inventário, Consumo de Cartas, Energia, Soldo,
## Afinidade, Combate, Exército, Comandantes ou Interface.


## Retorna uma nova instância da Carta avançada para o Tier imediatamente
## superior. A Identidade da Carta (nome, facção, classe, raridade) nunca é
## alterada. A instância original permanece intacta (operação pura).
static func advance_tier(card: CardResource) -> CardResource:
	assert(card != null, "CardProgression: a carta fornecida é nula.")
	assert(card.tier >= 1 and card.tier <= 4,
		"CardProgression: Aprimoramento inválido a partir do Tier %d." % card.tier)

	var advanced: CardResource = card.duplicate()
	advanced.tier = card.tier + 1

	match advanced.tier:
		2:
			advanced.atk += card.tier_2_atk_increment
			advanced.hp += card.tier_2_hp_increment
			advanced.esc += card.tier_2_esc_increment
		4:
			advanced.atk += card.tier_4_atk_increment
			advanced.hp += card.tier_4_hp_increment
			advanced.esc += card.tier_4_esc_increment
		3, 5:
			pass  # Tiers III e V não alteram atributos; apenas desbloqueiam Habilidade (dado de catálogo).

	return advanced


## Retorna o nome da Habilidade desbloqueada no Tier atual da carta (Tiers
## III e V), ou string vazia caso o Tier não desbloqueie nenhuma. Apenas
## expõe o dado de catálogo; não executa nenhum efeito.
static func unlocked_ability_name(card: CardResource) -> String:
	match card.tier:
		3:
			return card.tier_3_ability_name
		5:
			return card.tier_5_ability_name
		_:
			return ""
