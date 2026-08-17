class_name AcademyMaster
extends RefCounted
## AcademyMaster
##
## Um Mestre da Academia (Artífice ou Metamorfo) e sua fila de tarefas.
## Cada Mestre executa 1 tarefa por vez (a de índice 0 da fila); ao
## concluir, a próxima da fila começa automaticamente. Dado puro — quem
## decide quando iniciar/concluir tarefas é AcademyResolver.

enum Kind { ARTIFICE, METAMORFO }

var kind: Kind
var queue_capacity: int = 1  # ACADEMY.md: fila inicial de todo Mestre = 1 tarefa
var queue: Array[AcademyTask] = []


static func new_artifice() -> AcademyMaster:
	var master := AcademyMaster.new()
	master.kind = Kind.ARTIFICE
	return master


static func new_metamorfo() -> AcademyMaster:
	var master := AcademyMaster.new()
	master.kind = Kind.METAMORFO
	return master


func is_busy() -> bool:
	return not queue.is_empty()


func has_room() -> bool:
	return queue.size() < queue_capacity


func current_task() -> AcademyTask:
	return queue[0] if not queue.is_empty() else null
