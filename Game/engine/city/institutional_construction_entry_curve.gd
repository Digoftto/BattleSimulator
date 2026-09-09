class_name InstitutionalConstructionEntryCurve
extends RefCounted
## InstitutionalConstructionEntryCurve (FASE 22, Simulação 5 —
## BALANCING_SIMULATION.md, "Curva de Entrada das Construções
## Institucionais" — Cenário B, aprovado após validação agregada)
##
## Existe exclusivamente para suavizar a progressão INICIAL de Capital,
## Centro de Comando, Academia e Núcleo de Energia: alcançar os Níveis
## 2 e 3 custa 5% do valor calculado pela Fórmula Geral de Construções
## (GeneralConstructionFormula); a partir do Nível 4 a curva volta a
## ser 100% do valor vigente, sem nenhuma exceção.
##
## Esta é a ÚNICA fonte desse desconto — nunca duplicar o percentual em
## outro lugar (UI, testes ou outro resolver). NÃO altera "b"/"x"
## (InstitutionalConstructionConfig) nem a fórmula em si
## (GeneralConstructionFormula): aplica um desconto por CIMA do custo
## real já calculado. InstitutionalConstructionResolver.cost_breakdown()
## é o único chamador — todo o resto do jogo (painéis de Capital,
## Academia, Centro de Comando, Núcleo de Energia, Supply Chain) já lê o
## custo através dele, então nunca deve chamar
## GeneralConstructionFormula.upgrade_cost() diretamente para estas 4
## construções.

const ENTRY_LEVEL_DISCOUNT: Dictionary = {
	2: 0.95,
	3: 0.95,
}


## Custo real (Recursos de Construção) para evoluir "building" até
## "target_level", já com o desconto de entrada aplicado quando
## "target_level" for 2 ou 3.
static func total_cost(building: InstitutionalConstructionConfig.Building, target_level: int) -> int:
	var real_cost: int = GeneralConstructionFormula.upgrade_cost(
		target_level,
		InstitutionalConstructionConfig.b(building),
		InstitutionalConstructionConfig.x(building)
	)
	if ENTRY_LEVEL_DISCOUNT.has(target_level):
		var discount: float = ENTRY_LEVEL_DISCOUNT[target_level]
		return int(round(real_cost * (1.0 - discount)))
	return real_cost
