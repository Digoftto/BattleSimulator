class_name WeightedRandom
extends RefCounted
## WeightedRandom
##
## Utilitário genérico de sorteio ponderado, usado pelo CommanderGenerator
## para sortear candidatos proporcionalmente ao seu Peso de Frequência
## (ver CommanderFrequency).


## Sorteia um elemento de "candidates" com probabilidade proporcional ao
## peso retornado por "weight_fn" para cada elemento. "candidates" nunca
## deve ser vazio. "rng" é opcional — passe o RNG próprio da batalha
## (CombatState.rng) sempre que rodar de dentro do caminho de combate,
## pra nunca usar o RNG global (não seguro entre threads); nos outros
## usos (fora de combate, sempre em 1 thread só), pode deixar null.
static func pick(candidates: Array, weight_fn: Callable, rng: RandomNumberGenerator = null) -> Variant:
	assert(not candidates.is_empty(), "WeightedRandom: não há candidatos disponíveis para sorteio.")

	var total_weight: int = 0
	for candidate in candidates:
		total_weight += int(weight_fn.call(candidate))

	var roll: int = rng.randi_range(1, total_weight) if rng != null else randi_range(1, total_weight)
	var cumulative: int = 0
	for candidate in candidates:
		cumulative += int(weight_fn.call(candidate))
		if roll <= cumulative:
			return candidate

	return candidates[-1]  # segurança: nunca deve ser alcançado
