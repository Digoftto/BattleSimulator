class_name SupplyChainResolver
extends RefCounted
## SupplyChainResolver (DEPOSITS.md, "Reserva Antecipada de Evolução")
##
## Transferência antecipada de Recursos de Construção do Depósito
## (Kingdom.raw_resources) para uma construção elegível
## (Kingdom.building_reserved_resources), sem consumir tempo nem PG —
## realocação direta entre dois Recursos já pertencentes ao jogador.
##
## Construções elegíveis: Capital, Centro de Comando, Academia, Núcleo
## de Energia — as mesmas 4 de InstitutionalConstructionResolver. NUNCA
## Minas ou o próprio Depósito, que evolui exclusivamente com PG
## (DEPOSITS.md).
##
## Separação de responsabilidades (pedido explícito): esta classe só
## decide QUANTO pode ser transferido e executa a transferência; NÃO
## decide nem executa a evolução da construção — isso continua
## exclusivamente em InstitutionalConstructionResolver.evolve(), que
## consome primeiro o que foi reservado aqui antes de tocar em
## raw_resources (ver lá). Nenhum custo/fórmula é duplicado aqui: tudo
## vem de InstitutionalConstructionResolver.cost_breakdown().


## Requisitos completos da PRÓXIMA evolução de "building": custo por
## Recurso (fonte centralizada, nunca duplicado aqui) e quanto já está
## reservado + o que ainda falta.
## Dictionary: {resource: {"required": int, "reserved": int, "missing": int}}
static func requirements(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> Dictionary:
	var current_level: int = InstitutionalConstructionResolver.get_current_level(kingdom, building)
	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(building, current_level + 1)
	var key: String = InstitutionalConstructionResolver.building_key(building)

	var result: Dictionary = {}
	for resource: String in costs:
		var required: int = costs[resource]
		var reserved: int = kingdom.get_building_reserved(key, resource)
		result[resource] = {
			"required": required,
			"reserved": reserved,
			"missing": maxi(0, required - reserved),
		}
	return result


## Máximo transferível de "resource" pra "building" agora: limitado
## simultaneamente pelo saldo disponível no Depósito E pelo que ainda
## falta na construção (DEPOSITS.md: "nunca sobra recurso parado na
## construção além do necessário").
static func get_transferable_amount(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building, resource: String) -> int:
	var reqs: Dictionary = requirements(kingdom, building)
	if not reqs.has(resource):
		return 0
	var missing: int = reqs[resource]["missing"]
	var available: int = kingdom.get_raw_resource(resource)
	return mini(missing, available)


## "TRANSFERIR QUANTIDADE" — transfere exatamente "amount", nunca mais
## do que get_transferable_amount() permitiria. Retorna a quantidade
## efetivamente transferida (0 se amount <= 0 ou nada for transferível).
static func transfer_resource(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building, resource: String, amount: int) -> int:
	if amount <= 0:
		return 0
	var to_transfer: int = mini(amount, get_transferable_amount(kingdom, building, resource))
	if to_transfer <= 0:
		return 0

	kingdom.spend_raw_resource(resource, to_transfer)
	kingdom.add_building_reserved(InstitutionalConstructionResolver.building_key(building), resource, to_transfer)
	return to_transfer


## "COMPLETAR FALTA" — transfere exatamente o que falta daquele
## Recurso, limitado ao que existe no Depósito.
static func complete_missing_resource(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building, resource: String) -> int:
	return transfer_resource(kingdom, building, resource, get_transferable_amount(kingdom, building, resource))


## "TRANSFERIR TUDO" — completa o máximo possível de TODOS os Recursos
## exigidos por "building" de uma vez (cada um limitado ao seu próprio
## máximo, nunca ultrapassando a necessidade individual de nenhum).
## Retorna {resource: quantidade transferida}.
static func transfer_all_possible(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> Dictionary:
	var reqs: Dictionary = requirements(kingdom, building)
	var transferred: Dictionary = {}
	for resource: String in reqs:
		transferred[resource] = complete_missing_resource(kingdom, building, resource)
	return transferred
