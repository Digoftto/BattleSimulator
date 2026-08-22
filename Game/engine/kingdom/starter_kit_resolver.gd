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

## F-030: roster oficial dos 3 Exércitos Iniciais (INICIALIZAÇÃO.png,
## MVP aprovado) — nomes de carta canônicos, validados um a um contra
## res://database/cards/ antes desta mudança (todas as 18 cartas
## referenciadas existem, com Facção/Raridade exatas; nenhum nome
## duplicado dentro de nenhum dos 3 Exércitos; Soldo total 9, bem
## abaixo do teto de Recruta). Único ponto de verdade — a UI
## (StarterKitPanel) e o simulador (F-029) sempre leem daqui, nunca
## replicam este roster.
##
## Substitui o sorteio de Facção secundária + 3 cartas dela que existia
## antes (Array.shuffle(), sem seed, um resultado novo a cada
## carregamento da tela) — a arte oficial exige um roster ESTÁVEL por
## Facção, não uma amostra aleatória. Cada Exército continua 6 cartas
## da própria Facção (todas as Comuns dela, sempre as mesmas 6 no
## catálogo atual) + 3 de uma única Facção secundária FIXA (não
## necessariamente a mesma para as 3 Facções — Império e Mortos-Vivos
## usam Natureza como secundária, Natureza usa Mortos-Vivos — decisão
## de proprietário, não uma fórmula de rotação genérica).
const STARTER_ROSTER_CARD_NAMES: Dictionary = {
	"Império": [
		"Arqueiro Imperial", "Engenheiro Imperial", "Escudeiro Imperial",
		"Evocador Imperial", "Infante Imperial", "Legionário Imperial",
		"Carvalho Ancião", "Trepadeira Ancestral", "Flor da Aurora",
	],
	"Natureza": [
		"Carvalho Ancião", "Ent Jovem", "Flor da Aurora",
		"Porco-Espinho Ancestral", "Trepadeira Ancestral", "Urso Ancestral",
		"Liche Iniciado", "Abominação Putrefata", "Sacerdote Profano",
	],
	"Mortos-Vivos": [
		"Abominação Putrefata", "Arqueiro Esquelético", "Banshee",
		"Esqueleto Guerreiro", "Liche Iniciado", "Sacerdote Profano",
		"Ent Jovem", "Urso Ancestral", "Flor da Aurora",
	],
}


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


## 9 cartas Comuns, Tier I, todas diferentes entre si — exatamente as 9
## cartas do roster oficial desta Facção (STARTER_ROSTER_CARD_NAMES,
## F-030), nunca sorteadas.
static func _build_starter_composition(faction: String, all_cards: Array[CardResource]) -> Array[CardResource]:
	var card_names: Array = STARTER_ROSTER_CARD_NAMES[faction]

	var result: Array[CardResource] = []
	for card_name: String in card_names:
		var template: CardResource = _find_card_by_name(all_cards, card_name)
		assert(template != null, "StarterKitResolver: carta '%s' do roster oficial de %s não foi encontrada no catálogo (res://database/cards/)." % [card_name, faction])
		var copy: CardResource = template.duplicate()
		copy.tier = 1
		result.append(copy)
	return result


static func _find_card_by_name(all_cards: Array[CardResource], card_name: String) -> CardResource:
	for card: CardResource in all_cards:
		if card.card_name == card_name:
			return card
	return null


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
