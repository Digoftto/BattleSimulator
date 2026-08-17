class_name AcademyTask
extends RefCounted
## AcademyTask
##
## Uma tarefa programada na fila de um Mestre (Artífice ou Metamorfo).
## Dado puro — quem decide o que fazer com ela é AcademyResolver.

enum Kind { CREATE_COMMON, CREATE_RECIPE, UPGRADE }

var kind: Kind
var target_card_name: String = ""
var target_tier: int = 1  # relevante só para UPGRADE (Tier de destino)
var faction: String = ""
var quantity: int = 1

## Duração total da tarefa (já multiplicada pela quantidade, já com a
## redução de tempo da Academia aplicada). Definida no momento em que
## entra na fila; o instante real de início/fim só é conhecido quando
## a tarefa efetivamente começa (ver AcademyResolver._start_task()).
var duration_seconds: int = 0

## 0 = ainda não começou (está esperando a vez na fila).
var start_unix: int = 0
var end_unix: int = 0

## O que foi reservado no momento em que a tarefa entrou na fila —
## necessário para devolver em caso de cancelamento antes do início.
var reserved_fragments: int = 0
var reserved_faction: String = ""
var reserved_cards: Array[CardResource] = []

## --- Produção Automática (cadeia de dependências, ACADEMY.md) ---

## Tarefas das quais esta depende — só pode ser agendada em um Mestre
## depois que TODAS estiverem concluídas (is_done). Vazio = pronta para
## agendar assim que houver um Mestre livre.
var depends_on: Array[AcademyTask] = []

## Se != null, o resultado desta tarefa NUNCA vai para o inventário
## público do Reino — vira, automaticamente, um ingrediente reservado
## de "output_target" (AcademyResolver._complete_task()). Usado pelas
## etapas intermediárias de uma cadeia (ex: as 3 Comuns que uma Rara
## precisa) para que ninguém mais consiga usá-las no meio do caminho.
var output_target: AcademyTask

## True quando a tarefa já foi concluída — usado por outras tarefas
## para saber se suas dependências já estão prontas.
var is_done: bool = false


## Preenchido apenas quando esta tarefa faz parte de um plano de
## Produção Automática (AcademyResolver.request_auto_production()) —
## null para pedidos manuais diretos (request_common_production(),
## request_recipe_production(), request_upgrade()). É por aqui que
## AcademyResolver sabe, ao concluir, se o resultado deve alimentar um
## step-pai em vez de ir direto para a coleção do jogador.
var plan_step: AcademyPlanStep = null

func has_started() -> bool:
	return start_unix != 0


func is_complete(now_unix: int) -> bool:
	return has_started() and now_unix >= end_unix
