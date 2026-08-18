class_name MiningEfficiencyEstimator
extends RefCounted
## MiningEfficiencyEstimator (MINES.md, "Cálculo Incremental por
## Amostragem")
##
## Roda um lote de permutações da Formação de Referência contra a
## Guarnição, em paralelo (WorkerThreadPool), e devolve a contagem de
## Vitórias/Empates/Derrotas do ponto de vista da Guarnição.
##
## SEMPRE ASSÍNCRONO — nunca bloqueia quem chama. start_batch_async()
## dispara as tarefas e retorna na hora; poll_batch() checa sem
## esperar, retornando null enquanto não tiver terminado (quem chama
## decide quando/quantas vezes perguntar de novo — MiningCycleResolver
## faz isso via GameRuntime.sync(), a cada sincronização).
##
## Seguro pra paralelizar de verdade: nenhuma CardResource é
## modificada durante o combate (só lida — confirmado auditando
## combat_engine.gd/commander_doctrine_runtime.gd), e cada batalha usa
## seu próprio CombatState.rng (nunca o RNG global do Godot, que não é
## seguro entre threads — ver combat_state.gd).
##
## Log de Batalha sempre desligado aqui (enable_battle_log = false) —
## ninguém lê essas linhas numa simulação em massa, e formatar/guardar
## esse texto tem custo real medido (~31% do tempo de uma batalha).


## Versão SÍNCRONA de conveniência — dispara e espera terminar,
## bloqueando quem chama. Só faz sentido em testes/scripts (nunca
## dentro do jogo rodando de verdade, onde start_batch_async()+
## poll_batch() é obrigatório pra nunca travar a tela).
##
## NUNCA chama wait_for_task_completion() diretamente aqui — só via
## poll_batch(), e só uma vez por tarefa. Chamar duas vezes na mesma
## tarefa invalida o ID no WorkerThreadPool (erro real encontrado
## testando: "Invalid Task ID").
static func run_batch(
	guarnicao_commander: CommanderResource,
	guarnicao_cards: Array[CardResource],
	permutations: Array,
	reference_commander: CommanderResource,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	thread_count: int
) -> Dictionary:
	var started: Dictionary = start_batch_async(
		guarnicao_commander, guarnicao_cards, permutations, reference_commander, battlefields, abilities_by_name, unit_traits, thread_count
	)
	var result: Variant = null
	while result == null:
		result = poll_batch(started["task_ids"], started["chunk_results"])
		if result == null:
			OS.delay_msec(1)
	return result


## Divide "permutations" em até "thread_count" fatias e dispara cada
## uma como 1 tarefa do WorkerThreadPool — retorna IMEDIATAMENTE, sem
## esperar nenhuma terminar. Retorna {"task_ids": Array[int],
## "chunk_results": Array} — guarde os dois e passe pra poll_batch()
## depois, quantas vezes for preciso, até ele parar de retornar null.
static func start_batch_async(
	guarnicao_commander: CommanderResource,
	guarnicao_cards: Array[CardResource],
	permutations: Array,
	reference_commander: CommanderResource,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	thread_count: int
) -> Dictionary:
	_warm_up_combat_classes(battlefields, abilities_by_name, unit_traits)

	var effective_threads: int = maxi(1, mini(thread_count, maxi(1, permutations.size())))
	var chunks: Array = _split_into_chunks(permutations, effective_threads)
	var chunk_results: Array = []
	chunk_results.resize(chunks.size())

	var task_ids: Array[int] = []
	for i in range(chunks.size()):
		var task_id: int = WorkerThreadPool.add_task(
			_run_chunk.bind(chunks[i], guarnicao_commander, guarnicao_cards, reference_commander, battlefields, abilities_by_name, unit_traits, chunk_results, i)
		)
		task_ids.append(task_id)

	return {"task_ids": task_ids, "chunk_results": chunk_results}


## Roda 1 batalha síncrona descartável, no thread principal, ANTES de
## disparar qualquer tarefa paralela — peculiaridade real do Godot
## encontrada testando: uma classe (class_name) usada pela primeira
## vez de dentro de uma thread nova pode falhar ao resolver ".new()"
## ("Nonexistent function 'new' in base 'GDScript'") antes de ser
## "vista" pelo menos uma vez no processo principal. Usa um Exército
## sintético próprio (nunca os dados reais do chamador, que podem não
## passar em Army.is_ready_for_battle() em certos contextos de teste)
## — só precisa ser válido o bastante pra exercitar o caminho de
## combate completo (Habilidades, Características de Unidade) uma vez.
static func _warm_up_combat_classes(battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource]) -> void:
	var warm_up_commander := CommanderResource.new()
	warm_up_commander.commander_name = "Aquecimento"
	warm_up_commander.faction = "Império"

	var warm_up_card := CardResource.new()
	warm_up_card.card_name = "Carta de Aquecimento"
	warm_up_card.card_class = "Corpo a Corpo"
	warm_up_card.faction = "Império"
	warm_up_card.rarity = "Comum"
	warm_up_card.atk = 1
	warm_up_card.hp = 1
	warm_up_card.esc = 0

	var cards: Array[CardResource] = []
	for i in range(9):
		cards.append(warm_up_card)

	var army_a := Army.new()
	army_a.commander = warm_up_commander
	army_a.cards = cards
	var army_b := Army.new()
	army_b.commander = warm_up_commander
	army_b.cards = cards

	var state: CombatState = CombatEngine.initialize(army_a, army_b, battlefields, abilities_by_name, unit_traits)
	state.enable_battle_log = false
	CombatEngine.run(state)


## Checagem SEM BLOQUEAR: null se ainda houver alguma tarefa não
## terminada; senão, o resultado agregado {"wins", "ties", "losses"}.
static func poll_batch(task_ids: Array[int], chunk_results: Array) -> Variant:
	for task_id: int in task_ids:
		if not WorkerThreadPool.is_task_completed(task_id):
			return null  # pelo menos 1 tarefa ainda não terminou

	# Todas já terminaram — "colhe" cada uma (instantâneo aqui, já que
	# is_task_completed() confirmou; wait_for_task_completion() ainda
	# é necessário pra liberar os recursos internos da tarefa).
	for task_id: int in task_ids:
		WorkerThreadPool.wait_for_task_completion(task_id)

	var total_wins: int = 0
	var total_ties: int = 0
	var total_losses: int = 0
	var total_valid: int = 0
	for result: Dictionary in chunk_results:
		total_wins += result.get("wins", 0)
		total_ties += result.get("ties", 0)
		total_losses += result.get("losses", 0)
		total_valid += result.get("valid_battles", 0)

	return {"wins": total_wins, "ties": total_ties, "losses": total_losses, "valid_battles": total_valid}


## Executa uma fatia (sequencial, dentro de 1 thread) de permutações —
## a função que cada tarefa do WorkerThreadPool roda.
##
## Cada "permutation" recebida aqui JÁ chegou validada e deduplicada em
## nível de formação efetiva (MiningCycleResolver._build_next_batch(),
## na thread principal, antes do despacho) — nunca checada de novo
## aqui: a filtragem de unicidade/validade da Formação de Referência
## não pode rodar dentro do WorkerThreadPool, que executa em paralelo
## sem estado compartilhado seguro (F-003). Por isso, toda permutação
## deste chunk é sempre simulada — sem "continue" nenhum.
static func _run_chunk(
	chunk: Array,
	guarnicao_commander: CommanderResource,
	guarnicao_cards: Array[CardResource],
	reference_commander: CommanderResource,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	chunk_results: Array,
	chunk_index: int
) -> void:
	var wins: int = 0
	var ties: int = 0
	var losses: int = 0

	var guarnicao_army := Army.new()
	guarnicao_army.commander = guarnicao_commander
	guarnicao_army.cards = guarnicao_cards

	# Checagem defensiva ANTES de entrar no loop de combate: se a
	# Guarnição não está pronta (ex: Soldo além do teto — dado inválido
	# de quem chamou), nunca deixa o assert de CombatEngine derrubar a
	# tarefa inteira no meio da thread — isso corrompia
	# chunk_results[chunk_index] (nunca escrito) e gerava uma cascata
	# de "Invalid Task ID" em QUALQUER outro código que tentasse fazer
	# poll_batch() depois (F-003, causa raiz confirmada). Continua
	# protegendo especificamente a Guarnição — a única entrada aqui que
	# NÃO passa pela filtragem de _build_next_batch(), pois não muda
	# por permutação. Retorna 0/0/0/0 pra este bloco (visível e
	# investigável) em vez de travar todo o resto do sistema.
	if not guarnicao_army.is_ready_for_battle():
		BattleLogger.error("MiningEfficiencyEstimator", "Guarnição inválida pra batalha (Soldo além do teto ou Formação incompleta) — bloco pulado, resultado 0/0/0/0.")
		chunk_results[chunk_index] = {"wins": 0, "ties": 0, "losses": 0, "valid_battles": 0}
		return

	for permutation: Array in chunk:
		var reference_army := Army.new()
		reference_army.commander = reference_commander
		var cards: Array[CardResource] = []
		for card: Variant in permutation:
			cards.append(card as CardResource)
		reference_army.cards = cards

		# Rede de segurança (F-003): toda permutação que chega aqui já
		# deveria ter passado pela validação em
		# MiningCycleResolver._build_next_batch() (thread principal).
		# Esta checagem é redundante NO CAMINHO FELIZ, mas continua
		# aqui de propósito — igual à checagem da Guarnição acima —
		# porque um assert de CombatEngine disparando dentro da
		# WorkerThreadPool corrompe chunk_results[chunk_index] (nunca
		# escrito) e gera a mesma cascata histórica de "Invalid Task
		# ID". Nunca confia cegamente que a pré-filtragem é infalível.
		if not reference_army.is_ready_for_battle():
			BattleLogger.error("MiningEfficiencyEstimator", "Permutação da Formação de Referência chegou inválida a _run_chunk() apesar da pré-filtragem — pulada individualmente, não conta como valid_battle.")
			continue

		var state: CombatState = CombatEngine.initialize(guarnicao_army, reference_army, battlefields, abilities_by_name, unit_traits)
		state.enable_battle_log = false
		CombatEngine.run(state)

		match state.winner_side:
			0:
				wins += 1
			1:
				losses += 1
			_:
				ties += 1

	chunk_results[chunk_index] = {"wins": wins, "ties": ties, "losses": losses, "valid_battles": wins + ties + losses}


static func _split_into_chunks(items: Array, chunk_count: int) -> Array:
	var chunks: Array = []
	for i in range(chunk_count):
		chunks.append([])
	for i in range(items.size()):
		chunks[i % chunk_count].append(items[i])
	return chunks
