class_name PlanoCampanhaResolver
extends RefCounted
## PlanoCampanhaResolver (COMMAND_CENTER.md, "Plano de Campanha";
## RANKING.md, Ligas Prata/Ouro/Diamante)
##
## Cria e configura um Plano de Campanha — até 3 Exércitos, mapeamento
## dos 9 Campos de Batalha Especiais (exclusivo), Exército de Defesa
## Preferencial pro Campo Aberto, e Ordem de Ataque. Kingdom/PlanoCampanha
## nunca decidem isso sozinhos — este resolver verifica as condições e
## efetiva, no mesmo padrão de todos os outros resolvers do projeto.
##
## ESCOPO DESTA ENTREGA: criação e configuração do Plano de Campanha,
## MAIS sorteio de Campo de Batalha restrito por energia
## (select_attack()) e resolução de defensor (resolve_defender()).
## NÃO incluído (não existe em nenhum documento com detalhe
## suficiente pra implementar sem inventar regra nova, ou depende de
## infraestrutura de backend/servidor que este projeto ainda não tem):
## - Matchmaking real contra outro jogador (MATCHMAKING.md depende de
##   uma população de participantes/servidor que não existe localmente).
## - Divisão I "5% melhores" de verdade (mesma dependência — ver
##   RankingResolver.gd).
## Pontos de Liga/Divisões/promoção têm resolver próprio
## (RankingResolver.gd) — aplicável assim que um resultado de partida
## (de qualquer origem) for informado.

const MAX_ARMIES: int = 3


## Cria um novo Plano de Campanha com até 3 Exércitos. Retorna
## {"success": bool, "reason": String, "plano": PlanoCampanha}.
## "reason": "invalid_army_count" (0 ou mais de 3).
static func create(armies: Array[Army]) -> Dictionary:
	if armies.is_empty() or armies.size() > MAX_ARMIES:
		return {"success": false, "reason": "invalid_army_count", "plano": null}

	return {"success": true, "reason": "", "plano": PlanoCampanha.new(armies)}


## Associa "battlefield" (deve ser um Campo Especial, nunca o Padrão)
## exclusivamente ao Exército de índice "army_index". Redesignar um
## Campo já mapeado pra outro Exército simplesmente substitui o dono
## anterior — mapear é sempre livre (COMMAND_CENTER.md, "Configurações
## Livres"). Retorna {"success": bool, "reason": String}. "reason":
## "invalid_army_index", "battlefield_not_found", "battlefield_is_padrao".
static func map_battlefield(plano: PlanoCampanha, battlefield: BattlefieldResource, army_index: int) -> Dictionary:
	if army_index < 0 or army_index >= plano.armies.size():
		return {"success": false, "reason": "invalid_army_index"}

	if battlefield == null:
		return {"success": false, "reason": "battlefield_not_found"}

	if battlefield.category == "Padrão":
		return {"success": false, "reason": "battlefield_is_padrao"}

	plano.battlefield_mapping[battlefield.battlefield_name] = army_index
	return {"success": true, "reason": ""}


## Define qual Exército defende o Campo Aberto por padrão. Retorna
## {"success": bool, "reason": String}. "reason": "invalid_army_index".
static func set_defesa_preferencial(plano: PlanoCampanha, army_index: int) -> Dictionary:
	if army_index < 0 or army_index >= plano.armies.size():
		return {"success": false, "reason": "invalid_army_index"}

	plano.defesa_preferencial_index = army_index
	return {"success": true, "reason": ""}


## Define a Ordem de Ataque (array de índices 0/1/2, uma permutação
## completa dos Exércitos do Plano). Retorna {"success": bool, "reason":
## String}. "reason": "invalid_order" (tamanho errado ou índice repetido/fora do intervalo).
static func set_ordem_de_ataque(plano: PlanoCampanha, order: Array[int]) -> Dictionary:
	if order.size() != plano.armies.size():
		return {"success": false, "reason": "invalid_order"}

	var seen: Dictionary = {}
	for index: int in order:
		if index < 0 or index >= plano.armies.size() or seen.has(index):
			return {"success": false, "reason": "invalid_order"}
		seen[index] = true

	plano.ordem_de_ataque = order
	return {"success": true, "reason": ""}


## Qual Exército defende quando "battlefield" é sorteado (consulta
## pura — o sorteio em si não é responsabilidade deste resolver, ver
## ESCOPO no topo do arquivo). Campo Aberto -> Defesa Preferencial (ou
## null se ainda não definida); Campo Especial -> o dono mapeado (ou
## null se nenhum Exército foi designado a ele ainda).
static func resolve_defender(plano: PlanoCampanha, battlefield: BattlefieldResource) -> Army:
	if battlefield.category == "Padrão":
		if plano.defesa_preferencial_index == -1:
			return null
		return plano.armies[plano.defesa_preferencial_index]

	if not plano.battlefield_mapping.has(battlefield.battlefield_name):
		return null
	return plano.armies[plano.battlefield_mapping[battlefield.battlefield_name]]


## Energia gasta por Ataque (ENERGY.md).
const ATTACK_ENERGY_COST: int = 10


## Sorteia o Campo de Batalha do Ataque, restrito aos Campos cujo
## Exército mapeado ainda tem energia suficiente (COMMAND_CENTER.md,
## "Ataque: Restrito pela Energia Disponível") e resolve qual Exército
## ataca — pro Campo Aberto, a Ordem de Ataque desempata entre os
## elegíveis; pros Especiais, é sempre o único mapeado.
## Retorna {"success": bool, "reason": String, "battlefield":
## BattlefieldResource, "army": Army}. "reason": "no_energy_available"
## (nenhum Exército do Plano tem energia suficiente pra nenhum Campo).
static func select_attack(plano: PlanoCampanha, all_battlefields: Array[BattlefieldResource], rng: RandomNumberGenerator) -> Dictionary:
	var eligible: Array[BattlefieldResource] = []
	for battlefield: BattlefieldResource in all_battlefields:
		if _has_eligible_army(plano, battlefield):
			eligible.append(battlefield)

	if eligible.is_empty():
		return {"success": false, "reason": "no_energy_available", "battlefield": null, "army": null}

	var battlefield: BattlefieldResource = BattlefieldSelector.select(eligible, rng)
	var army: Army = _resolve_attacker(plano, battlefield)

	return {"success": true, "reason": "", "battlefield": battlefield, "army": army}


static func _has_eligible_army(plano: PlanoCampanha, battlefield: BattlefieldResource) -> bool:
	return _resolve_attacker(plano, battlefield) != null


## Mesma lógica de resolve_defender(), mas restrita a Exércitos com
## energia — e, pro Campo Aberto, desempatada pela Ordem de Ataque em
## vez da Defesa Preferencial (são escolhas independentes, cada uma só
## relevante pro seu próprio lado — COMMAND_CENTER.md).
static func _resolve_attacker(plano: PlanoCampanha, battlefield: BattlefieldResource) -> Army:
	if battlefield.category != "Padrão":
		if not plano.battlefield_mapping.has(battlefield.battlefield_name):
			return null
		var army_index: int = plano.battlefield_mapping[battlefield.battlefield_name]
		var army: Army = plano.armies[army_index]
		return army if army.current_energy >= ATTACK_ENERGY_COST else null

	for army_index: int in plano.ordem_de_ataque:
		var army: Army = plano.armies[army_index]
		if army.current_energy >= ATTACK_ENERGY_COST:
			return army
	return null
