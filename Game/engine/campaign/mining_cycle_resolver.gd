class_name MiningCycleResolver
extends RefCounted
## MiningCycleResolver
##
## Motor de estimativa incremental da Eficiência da Guarnição
## (MINES.md, "Cálculo Incremental por Amostragem"): em vez de rodar
## as 362.880 permutações de uma vez (inviável — horas de processamento
## real), processa em blocos de 1% (~3.629 cada), embaralhados e nunca
## repetidos, acumulando a amostra ao longo do tempo. Cada bloco roda
## em segundo plano (WorkerThreadPool, via MiningEfficiencyEstimator),
## sem nunca bloquear quem chama — quem quiser saber se um bloco
## terminou usa poll_pending_block().
##
## Correção registrada (herdada do desenho original): a Formação de
## Referência é quem assume todas as posições possíveis; a Guarnição
## luta sempre na mesma formação.
##
## Nunca decide QUANDO rodar um bloco novo nem com quantas threads —
## isso é responsabilidade de quem orquestra tempo real
## (GameRuntime.sync() para os blocos de segundo plano; a tela de
## Conquista para o primeiro bloco, com mais threads).

const EFFICIENCY_VICTORY: float = 1.0
const EFFICIENCY_TIE: float = 0.5
const EFFICIENCY_DEFEAT: float = 0.2
const TOTAL_PERMUTATIONS: int = 362880
const TOTAL_BLOCKS: int = 100

## Blocos acumulados a partir dos quais a amostra já atinge alta
## confiança estatística (99% de confiança, margem de erro < 1% —
## conversa registrada com o dono do projeto). A partir daqui, a
## Eficiência já não muda de forma perceptível, mesmo que o cálculo
## continue até completar os 100 blocos.
const HIGH_CONFIDENCE_BLOCKS: int = 5


## Inicia uma nova estimativa do zero — gera a ordem embaralhada dos
## índices das 362.880 permutações (nunca repete a mesma ordem entre
## Ciclos) e zera os contadores acumulados. Deve ser chamado uma única
## vez, no exato momento em que o Ciclo de Mineração começa.
static func start_estimation(mina: Mina, seed_value: int) -> void:
	var indices: Array[int] = []
	for i in range(TOTAL_PERMUTATIONS):
		indices.append(i)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_seeded_shuffle(indices, rng)

	mina.efficiency_permutation_order = indices
	mina.efficiency_blocks_completed = 0
	mina.efficiency_wins = 0
	mina.efficiency_ties = 0
	mina.efficiency_losses = 0
	mina.efficiency_pending_task_ids = []
	mina.efficiency_pending_chunk_results = []


## True se já não há mais bloco pendente pra iniciar (chegou nos 100
## blocos) OU se a amostra acumulada já atingiu alta confiança
## estatística — nos dois casos, não é mais necessário disparar blocos
## novos (mesmo que o cálculo completo só termine perto do fim das 100
## horas do Ciclo, se quiser deixar rodando).
static func has_high_confidence(mina: Mina) -> bool:
	return mina.efficiency_blocks_completed >= HIGH_CONFIDENCE_BLOCKS


static func is_estimation_complete(mina: Mina) -> bool:
	return mina.efficiency_blocks_completed >= TOTAL_BLOCKS


## Dispara o PRÓXIMO bloco em segundo plano, SEM esperar — não faz
## nada se já houver um bloco em andamento (chame poll_pending_block()
## primeiro) ou se a estimativa já tiver completado os 100 blocos.
static func start_next_block_async(
	mina: Mina,
	guarnicao_commander: CommanderResource,
	guarnicao_cards: Array[CardResource],
	reference_commander: CommanderResource,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	thread_count: int
) -> void:
	if not mina.efficiency_pending_task_ids.is_empty():
		return  # já tem um bloco em andamento
	if is_estimation_complete(mina):
		return

	var block_permutations: Array = _block_permutations(mina, mina.efficiency_blocks_completed)
	var started: Dictionary = MiningEfficiencyEstimator.start_batch_async(
		guarnicao_commander, guarnicao_cards, block_permutations, reference_commander,
		battlefields, abilities_by_name, unit_traits, thread_count
	)
	mina.efficiency_pending_task_ids = started["task_ids"]
	mina.efficiency_pending_chunk_results = started["chunk_results"]


## Checagem SEM BLOQUEAR do bloco em andamento (se houver) — se já
## terminou, agrega o resultado nos contadores acumulados da Mina e
## avança efficiency_blocks_completed. Retorna true se um bloco foi
## concluído e agregado nesta chamada, false se ainda não havia nada
## pendente ou o bloco pendente ainda não tinha terminado.
static func poll_pending_block(mina: Mina) -> bool:
	if mina.efficiency_pending_task_ids.is_empty():
		return false

	var result: Variant = MiningEfficiencyEstimator.poll_batch(mina.efficiency_pending_task_ids, mina.efficiency_pending_chunk_results)
	if result == null:
		return false  # ainda não terminou

	mina.efficiency_wins += result["wins"]
	mina.efficiency_ties += result["ties"]
	mina.efficiency_losses += result["losses"]
	mina.efficiency_blocks_completed += 1
	mina.efficiency_pending_task_ids = []
	mina.efficiency_pending_chunk_results = []
	return true


## Eficiência acumulada até agora (mesma fórmula de sempre — média
## ponderada). -1.0 se nenhum bloco foi processado ainda.
static func current_efficiency(mina: Mina) -> float:
	var total: int = mina.efficiency_wins + mina.efficiency_ties + mina.efficiency_losses
	if total <= 0:
		return -1.0
	return weighted_efficiency(mina.efficiency_wins, mina.efficiency_ties, mina.efficiency_losses, total)


## Eficiência da Guarnição (MINES.md, "Eficiência da Guarnição"): média
## ponderada dos 3 percentuais pelo peso de cada resultado. 0.0 a 1.0.
static func weighted_efficiency(wins: int, ties: int, losses: int, total: int) -> float:
	if total <= 0:
		return 0.0
	return (wins * EFFICIENCY_VICTORY + ties * EFFICIENCY_TIE + losses * EFFICIENCY_DEFEAT) / float(total)


## As permutações de verdade (cartas) do bloco de índice "block_index"
## (0-based) — regenera as 362.880 permutações (rápido, é só
## permutação de array, nenhum combate) e usa a ordem embaralhada já
## guardada pra escolher a fatia certa. O último bloco absorve
## qualquer resto da divisão (362.880 não é múltiplo exato de 100).
static func _block_permutations(mina: Mina, block_index: int) -> Array:
	var all_permutations: Array = MiningPermutations.generate_all(mina.reference_cards)

	var start: int = int(float(block_index) * TOTAL_PERMUTATIONS / float(TOTAL_BLOCKS))
	var end: int = int(float(block_index + 1) * TOTAL_PERMUTATIONS / float(TOTAL_BLOCKS))
	if block_index == TOTAL_BLOCKS - 1:
		end = TOTAL_PERMUTATIONS

	var result: Array = []
	for i in range(start, end):
		var permutation_index: int = mina.efficiency_permutation_order[i]
		result.append(all_permutations[permutation_index])
	return result


static func _seeded_shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp
