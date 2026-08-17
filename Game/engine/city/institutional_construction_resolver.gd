class_name InstitutionalConstructionResolver
extends RefCounted
## InstitutionalConstructionResolver
##
## Executa a evolução de Capital, Centro de Comando, Academia e Núcleo
## de Energia — as 4 construções que usam a Fórmula Geral de
## Construções (GeneralConstructionFormula), pagando em Recursos de
## Construção (Ferro Negro, Cristais Arcanos, Essência Vital), nunca em
## PG (isso é exclusividade do Depósito — ver CityResolver).
##
## Kingdom nunca decide isso sozinho — este resolver verifica as
## condições (teto da Capital, saldo de recursos) e efetiva a
## evolução, no mesmo padrão de CityResolver/RecruitmentResolver.
##
## Assinatura Econômica (CITY.md, "Relação entre as Construções e os
## Fundamentos" + FORMULAS.md): o custo total calculado pela Fórmula
## Geral é dividido entre os Fundamentos de cada construção:
## - Capital: 33% / 33% / 33% entre os três recursos.
## - Academia, Centro de Comando, Núcleo de Energia: 70% do Fundamento
##   Principal, 30% do Secundário.
## A proporção 70/30 é a decisão vigente do dono do projeto — nenhuma
## outra proporção foi definida em nenhum documento.

const SECONDARY_SHARE: float = 0.30


## Retorna o custo total (Recursos de Construção) já dividido pelos
## Fundamentos da construção, para evoluir até "target_level".
## Dictionary: {"ferro_negro": int, "cristais_arcanos": int, "essencia_vital": int}
## (chaves ausentes = 0, a construção não consome aquele recurso).
static func cost_breakdown(building: InstitutionalConstructionConfig.Building, target_level: int) -> Dictionary:
	var total: int = GeneralConstructionFormula.upgrade_cost(
		target_level,
		InstitutionalConstructionConfig.b(building),
		InstitutionalConstructionConfig.x(building)
	)

	if building == InstitutionalConstructionConfig.Building.CAPITAL:
		return _split_three_way(total)

	var principal: String = _principal_resource(building)
	var secundario: String = _secondary_resource(building)
	var secundario_amount: int = int(round(total * SECONDARY_SHARE))
	var principal_amount: int = total - secundario_amount
	return {principal: principal_amount, secundario: secundario_amount}


## Tenta evoluir "building" em 1 nível. Retorna
## {"success": bool, "reason": String}. "reason" é "" em caso de
## sucesso, ou explica o bloqueio:
## - "capital_limit": a construção já está no nível da Capital (não se
##   aplica à própria Capital, que não tem teto).
## - "insufficient_resources": saldo insuficiente de algum dos recursos
##   necessários — nada é gasto (tudo ou nada).
static func evolve(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> Dictionary:
	var current_level: int = _get_level(kingdom, building)

	if building != InstitutionalConstructionConfig.Building.CAPITAL:
		if not Capital.can_building_evolve(current_level, kingdom.capital_level):
			return {"success": false, "reason": "capital_limit"}

	var costs: Dictionary = cost_breakdown(building, current_level + 1)

	for resource: String in costs:
		if kingdom.get_raw_resource(resource) < costs[resource]:
			return {"success": false, "reason": "insufficient_resources"}

	for resource: String in costs:
		kingdom.spend_raw_resource(resource, costs[resource])

	_increment_level(kingdom, building)
	_grant_xp(kingdom, building)
	return {"success": true, "reason": ""}


static func _split_three_way(total: int) -> Dictionary:
	var third: int = int(round(total / 3.0))
	var last: int = total - (third * 2)  # absorve o resto do arredondamento
	return {"ferro_negro": third, "cristais_arcanos": third, "essencia_vital": last}


static func _principal_resource(building: InstitutionalConstructionConfig.Building) -> String:
	match building:
		InstitutionalConstructionConfig.Building.ACADEMIA:
			return "essencia_vital"
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO:
			return "ferro_negro"
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA:
			return "cristais_arcanos"
	return ""


static func _secondary_resource(building: InstitutionalConstructionConfig.Building) -> String:
	match building:
		InstitutionalConstructionConfig.Building.ACADEMIA:
			return "ferro_negro"
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO:
			return "cristais_arcanos"
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA:
			return "essencia_vital"
	return ""


static func _grant_xp(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> void:
	match building:
		InstitutionalConstructionConfig.Building.CAPITAL:
			AccountXPResolver.grant_city_evolution_capital(kingdom)
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO:
			AccountXPResolver.grant_city_evolution_command_center(kingdom)
		InstitutionalConstructionConfig.Building.ACADEMIA:
			AccountXPResolver.grant_city_evolution_academy(kingdom)
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA:
			AccountXPResolver.grant_city_evolution_energy_nucleus(kingdom)


static func _get_level(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> int:
	match building:
		InstitutionalConstructionConfig.Building.CAPITAL:
			return kingdom.capital_level
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO:
			return kingdom.command_center_level
		InstitutionalConstructionConfig.Building.ACADEMIA:
			return kingdom.academy_level
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA:
			return kingdom.energy_nucleus_level
	return 0


static func _increment_level(kingdom: Kingdom, building: InstitutionalConstructionConfig.Building) -> void:
	match building:
		InstitutionalConstructionConfig.Building.CAPITAL:
			kingdom.increment_capital_level()
		InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO:
			kingdom.increment_command_center_level()
		InstitutionalConstructionConfig.Building.ACADEMIA:
			kingdom.increment_academy_level()
		InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA:
			kingdom.increment_energy_nucleus_level()
