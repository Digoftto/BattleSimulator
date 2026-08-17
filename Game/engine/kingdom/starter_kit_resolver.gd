class_name StarterKitResolver
extends RefCounted
## StarterKitResolver (COMMAND_CENTER_RECRUITMENT.md, "Kit Inicial do
## Reino")
##
## Diferente de toda Fonte de Recrutamento (COMMAND_CENTER_RECRUITMENT.md):
## não passa pelo Motor de Geração (CommanderGenerator) nem pelo
## processo unificado de Comissionamento — é uma concessão
## administrativa direta, exclusiva do momento de criação do Reino,
## existindo uma única vez.
##
## Sobre o nome do Comandante: não existe nenhum gerador de nomes de
## personagem no projeto ainda (o único nome pronto no banco,
## "Marcus Valerius", é conteúdo de exemplo, não um sistema
## procedural) — mesma categoria de lacuna já registrada pra Lore na
## Biblioteca. Uso um identificador funcional ("Comandante Recruta")
## em vez de inventar um nome de personagem, que seria conteúdo
## narrativo fora do meu papel de engenheiro.

const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
const CARDS_FROM_OTHER_FACTIONS: int = 3


## Gera as 3 opções (uma por Facção) — não altera o Reino ainda, só
## monta os dados para exibição/escolha. Cada opção: {"faction":
## String, "commander": CommanderResource, "cards": Array[CardResource]}.
static func generate_options(all_cards: Array[CardResource]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for faction: String in FACTIONS:
		var commander := CommanderResource.new()
		commander.commander_name = "Comandante Recruta"
		commander.faction = faction
		# Sem Doutrina nenhuma — Restrição/Requisito/Alvo/Efeito/Valor
		# ficam nos valores padrão (vazios) do CommanderResource, de
		# propósito ("Comandante em branco — nenhum bônus nem penalidade").

		options.append({
			"faction": faction,
			"commander": commander,
			"cards": _build_starter_composition(faction, all_cards),
		})
	return options


## 9 cartas Comuns, Tier I, todas diferentes entre si — 6 da Facção
## (todas as Comuns disponíveis dela) + 3 misturadas entre as outras
## duas Facções.
static func _build_starter_composition(faction: String, all_cards: Array[CardResource]) -> Array[CardResource]:
	var faction_commons: Array[CardResource] = all_cards.filter(
		func(c: CardResource) -> bool: return c.faction == faction and c.rarity == "Comum"
	)
	var other_commons: Array[CardResource] = all_cards.filter(
		func(c: CardResource) -> bool: return c.faction != faction and c.rarity == "Comum"
	)
	other_commons.shuffle()

	var chosen: Array[CardResource] = []
	chosen.append_array(faction_commons)
	for i in range(mini(CARDS_FROM_OTHER_FACTIONS, other_commons.size())):
		chosen.append(other_commons[i])

	var result: Array[CardResource] = []
	for template: CardResource in chosen:
		var copy: CardResource = template.duplicate()
		copy.tier = 1
		result.append(copy)
	return result


## Efetiva a escolha do jogador — só pode acontecer uma vez por Reino
## (COMMAND_CENTER_RECRUITMENT.md). O Comandante nasce no Estado
## Ativo diretamente (exceção estrutural documentada: não passa pelo
## limite normal de Cargo Ativo, já que um Reino novo começa com 0
## Cargos disponíveis) e o Exército já nasce formado.
## Retorna {"success": bool, "reason": String}. "reason": "already_used".
static func choose_option(kingdom: Kingdom, option: Dictionary, now_unix: int) -> Dictionary:
	if kingdom.starter_kit_used:
		return {"success": false, "reason": "already_used"}

	var commander: CommanderResource = option["commander"]
	kingdom.add_commander(commander, now_unix)
	commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE

	var owned_cards: Array[CardResource] = []
	for card: CardResource in option["cards"]:
		card.instance_id = kingdom.next_card_instance_id
		kingdom.next_card_instance_id += 1
		card.ownership_status = CardResource.OwnershipStatus.LIVRE
		kingdom.cards.append(card)
		owned_cards.append(card)

	kingdom.form_army(commander, owned_cards)
	kingdom.starter_kit_used = true

	return {"success": true, "reason": ""}
