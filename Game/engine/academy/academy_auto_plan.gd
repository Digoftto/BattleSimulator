class_name AcademyAutoPlan
extends RefCounted
## AcademyAutoPlan
##
## Estado acumulado enquanto AcademyResolver._plan_card() monta
## recursivamente a árvore de dependências de um pedido de Produção
## Automática. Descartado depois que o plano é confirmado ou rejeitado
## — não é uma estrutura persistente (os AcademyPlanStep resultantes é
## que passam a viver em Kingdom.academy_backlog).

var steps: Array[AcademyPlanStep] = []

## Cartas específicas do inventário já reservadas como ingrediente de
## algum step (nunca as do nível raiz do pedido — essas só reduzem a
## quantidade a produzir, sem serem "consumidas").
var claimed_cards: Array[CardResource] = []

var fragment_cost_by_faction: Dictionary = {}  # faction -> int

var feasible: bool = true
var missing_report: Array = []
