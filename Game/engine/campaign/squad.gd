class_name Squad
extends RefCounted
## Squad (ARMY.md)
##
## Agrupamento de Exércitos utilizado por um modo de jogo. Não substitui
## o conceito de Exército — apenas os agrupa e respeita a ordem de
## prioridade definida previamente pelo jogador.
##
## Responsabilidade estritamente limitada a armazenar os Exércitos,
## informar qual está ativo e permitir avançar para o próximo quando
## autorizado externamente (ex: por PhaseResolver, ao esgotar todas as
## Formações do Exército ativo). Não conhece Combate, Energia, Minas ou
## Progressão — nenhuma dessas palavras aparece neste arquivo por acaso.

var armies: Array[Army] = []
var active_index: int = 0


func _init(p_armies: Array[Army]) -> void:
	armies = p_armies


## Retorna o Exército atualmente ativo (respeitando a ordem de
## prioridade em que "armies" foi fornecido), ou null se o Squad já
## esgotou todos os seus Exércitos.
func active_army() -> Army:
	if is_exhausted():
		return null
	return armies[active_index]


## Avança para o próximo Exército na ordem de prioridade. Retorna o novo
## Exército ativo, ou null se não houver mais nenhum.
func advance_to_next_army() -> Army:
	active_index += 1
	return active_army()


## True quando todos os Exércitos do Squad já foram utilizados.
func is_exhausted() -> bool:
	return active_index >= armies.size()


## Reinicia o Squad para o primeiro Exército da prioridade (ex: ao
## iniciar uma nova Tentativa de Fase).
func reset() -> void:
	active_index = 0


## Tamanho de Squad exigido para iniciar uma nova Expedição num
## Território, dado quantas vezes aquela Trilha já foi concluída
## inteiramente (PvE.md, "Exigências Estritas de Composição de
## Squad"): 1ª conclusão -> 1; 1º Replay -> 2; 2º Replay em diante -> 3.
static func required_size(completion_count: int) -> int:
	return mini(3, completion_count + 1)
