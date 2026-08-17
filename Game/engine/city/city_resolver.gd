class_name CityResolver
extends RefCounted
## CityResolver
##
## Executa a evolução do Depósito do Reino (DEPOSITS.md + FORMULAS.md),
## aplicando o teto institucional da Capital (CAPITAL.md, ver
## Capital.can_building_evolve()) e o custo em Pontos de Geração
## (Deposits.upgrade_cost_pg()).
##
## Kingdom nunca decide isso sozinho ("Kingdom possui, referencia,
## persiste — nunca calcula, resolve ou gera") — este resolver verifica
## as condições e efetiva a evolução, no mesmo padrão já usado por
## RecruitmentResolver e MineConquestResolver.
##
## O Depósito é uma única construção (1 nível, armazena os 3 Recursos
## de Construção simultaneamente — DEPOSITS.md, corrigido). A evolução
## de Capital, Centro de Comando, Núcleo de Energia e Academia (Fórmula
## Geral de Construções, pagas em Recursos de Construção) pertence a
## InstitutionalConstructionResolver, não aqui — o Depósito é o único
## que paga exclusivamente em PG.


## Tenta evoluir o Depósito em 1 nível. Retorna um Dictionary:
## {"success": bool, "reason": String}. "reason" é "" em caso de
## sucesso, ou explica o bloqueio:
## - "capital_limit": o Depósito já está no nível da Capital.
## - "insufficient_pg": Pontos de Geração insuficientes para o custo.
static func evolve_deposit(kingdom: Kingdom) -> Dictionary:
	var current_level: int = kingdom.deposito_level

	if not Capital.can_building_evolve(current_level, kingdom.capital_level):
		return {"success": false, "reason": "capital_limit"}

	var cost: int = Deposits.upgrade_cost_pg(current_level + 1)
	if not kingdom.spend_generation_points(cost):
		return {"success": false, "reason": "insufficient_pg"}

	kingdom.increment_deposito_level()
	AccountXPResolver.grant_city_evolution_deposito(kingdom)
	return {"success": true, "reason": ""}
