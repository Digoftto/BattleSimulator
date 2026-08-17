class_name MiningPermutations
extends RefCounted
## MiningPermutations
##
## Gera todas as permutações possíveis de um array, via Algoritmo de
## Heap (O(n!), sem alocação repetida de arrays intermediários).
##
## Uso principal: as 9! = 362.880 posições possíveis da Guarnição da
## Mina no Ciclo de Mineração (MINES.md). Implementado genérico para
## qualquer tamanho de array — não hard-coded para 9 cartas — para que
## possa ser testado com arrays pequenos sem custo computacional real.


## Retorna todas as permutações de "items" (n! arrays, cada um com n
## elementos). Não modifica "items".
static func generate_all(items: Array) -> Array:
	var result: Array = []
	var arr: Array = items.duplicate()
	_heap_permute(arr.size(), arr, result)
	return result


static func _heap_permute(k: int, arr: Array, result: Array) -> void:
	if k == 1:
		result.append(arr.duplicate())
		return

	for i in range(k):
		_heap_permute(k - 1, arr, result)
		if k % 2 == 0:
			_swap(arr, i, k - 1)
		else:
			_swap(arr, 0, k - 1)


static func _swap(arr: Array, i: int, j: int) -> void:
	var tmp = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
