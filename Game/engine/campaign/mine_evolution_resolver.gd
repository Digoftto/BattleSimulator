class_name MineEvolutionResolver
extends RefCounted
## MineEvolutionResolver (F-020, generalizado em F-021.3.1)
##
## Evolui o Nível Estrutural de QUALQUER Mina — Inicial ou Regional —
## mesmo padrão já usado por CityResolver.evolve_deposit(): verifica o
## limite (só a Mina Inicial tem um documentado), calcula o custo via
## MineEconomy.upgrade_cost_pg() usando a Região real da própria Mina
## (MineEconomy.region_for_mina() — nenhuma fórmula nova, nenhuma
## segunda fonte de verdade), gasta PG via
## Kingdom.spend_generation_points(), e só em caso de sucesso incrementa
## o nível via Mina.increment_structure_level().
##
## F-021 (auditoria) confirmou que esta função só aceitava Minas
## Iniciais (rejeitando Regionais com "not_initial_mine") embora
## MineEconomy.upgrade_cost_pg()/MINES.md/FORMULAS.md já definissem
## custo de evolução para todas as Regiões — travando toda a economia
## de médio/longo prazo do jogo (Minas Regionais) no Nível 1 para
## sempre. F-021.2 confirmou (decisão do usuário) que a correção deve
## reaproveitar exatamente esta infraestrutura, sem UI nova nem segundo
## sistema de evolução.
##
## Limite de Nível 4 é EXCLUSIVO da Mina Inicial (MINES.md, "Mina
## Inicial (Bootstrap)": "Evolução: Possui regras próprias de evolução,
## com nível máximo 4"). Minas Regionais não têm nível máximo
## documentado em MINES.md/FORMULAS.md — nenhum teto foi inventado aqui.

const INITIAL_MINE_MAX_LEVEL: int = 4


## Retorna {"success": bool, "reason": String}. "reason" é "" em caso de
## sucesso, ou explica o bloqueio:
## - "max_level": Mina Inicial já no Nível 4 (único caso com teto).
## - "insufficient_pg": Pontos de Geração insuficientes para o custo.
static func evolve(kingdom: Kingdom, mina: Mina) -> Dictionary:
	if mina.is_initial_mine() and mina.structure_level >= INITIAL_MINE_MAX_LEVEL:
		return {"success": false, "reason": "max_level"}

	var cost: int = MineEconomy.upgrade_cost_pg(MineEconomy.region_for_mina(mina), mina.structure_level + 1)
	if not kingdom.spend_generation_points(cost):
		return {"success": false, "reason": "insufficient_pg"}

	mina.increment_structure_level()
	return {"success": true, "reason": ""}
