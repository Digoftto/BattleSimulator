class_name GeneralConstructionFormula
extends RefCounted
## GeneralConstructionFormula (FORMULAS.md, "Fórmula Geral das Construções")
##
## C(n) = CEG × (b + n² + xn) — custo de evolução até o nível de
## destino "n", em Recursos de Construção. Usada por Capital, Academia,
## Centro de Comando e Núcleo de Energia (nunca pelo Depósito, que paga
## exclusivamente em PG — ver Deposits.upgrade_cost_pg()).
##
## "b" e "x" não são constantes fixas deste arquivo: variam por
## construção e mudam conforme o balanceamento evolui. Os valores
## atualmente vigentes vivem em InstitutionalConstructionConfig,
## espelhando `BALANCING_SIMULATION.md` ("VALORES VIGENTES") — nunca
## hard-code um valor de b/x fora desse arquivo central.

const CEG: int = 20


## Custo, em Recursos de Construção, para evoluir até o nível de
## destino "target_level", dado b e x da construção.
static func upgrade_cost(target_level: int, b: float, x: float) -> int:
	assert(target_level >= 1, "GeneralConstructionFormula: nível de destino deve ser >= 1.")
	var raw_cost: float = CEG * (b + target_level * target_level + x * target_level)
	return int(round(raw_cost))
