class_name AcademyPlanStep
extends RefCounted
## AcademyPlanStep
##
## Um passo dentro de um plano de Produção Automática (ACADEMY.md):
## produzir "quantity" cópias de "card_name", via Fragmento
## (PRODUCE_COMMON) ou via combinação de receita (COMBINE_RECIPE).
##
## Um step só está pronto para entrar na fila de um Artífice quando
## "pending_children" chega a 0 — nesse momento, "collected_ingredients"
## (para COMBINE_RECIPE) já tem tudo que precisa para executar, seja
## porque já existia no inventário, seja porque os steps-filho
## terminaram e entregaram o resultado.

enum StepType { PRODUCE_COMMON, COMBINE_RECIPE }

var step_type: StepType
var card_name: String = ""
var quantity: int = 1
var faction: String = ""

## Só PRODUCE_COMMON: já calculado e já cobrado no momento em que o
## plano inteiro foi confirmado (não é cobrado de novo ao executar).
var fragment_cost: int = 0

## Só COMBINE_RECIPE.
var recipe_ingredient_names: Array[String] = []
var collected_ingredients: Array[CardResource] = []

## Quantos steps-filho diretos ainda faltam terminar. 0 = pronto para
## ser posto na fila de um Mestre.
var pending_children: int = 0

## O step que recebe o resultado deste quando ele conclui. null = este
## step é a entrega final do plano (o pedido original do jogador).
var parent: AcademyPlanStep = null

## Preenchido quando o step é efetivamente posto na fila de um Mestre
## (AcademyResolver._advance_backlog()).
var task: AcademyTask = null
