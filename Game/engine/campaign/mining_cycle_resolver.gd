class_name MiningCycleResolver
extends RefCounted
## MiningCycleResolver
##
## Motor de estimativa incremental da Eficiência da Guarnição
## (MINES.md, "Cálculo Incremental por Amostragem") — modelo final: até
## TARGET_VALID_BATTLES (18.144) BATALHAS ÚNICAS E VÁLIDAS, distribuídas
## em exatamente HIGH_CONFIDENCE_BLOCKS (5) blocos, nunca mais — sem
## infraestrutura de "100 blocos"/362.880 completas, que pertencia ao
## desenho anterior (já obsoleto, removido daqui de propósito).
##
## "Única e válida" nunca significa "permutação bruta única": a Máquina
## de Guerra é sempre normalizada pra Posição 9 por
## CombatEngine._place_army(), então múltiplas permutações brutas das
## 362.880 podem colapsar na mesma formação de combate EFETIVA — ver
## _effective_formation_key(). "Válida" também exclui formações com um
## Suporte na Posição 5 (COMBAT_RULES.md 6.5, "Restrição de
## Posicionamento Inicial"). A filtragem de unicidade e validade
## acontece inteiramente na thread principal, em _build_next_batch() —
## NUNCA dentro de _run_chunk() (WorkerThreadPool executa em paralelo,
## sem estado compartilhado seguro entre tarefas).
##
## Cada bloco roda em segundo plano (WorkerThreadPool, via
## MiningEfficiencyEstimator), sem nunca bloquear quem chama — quem
## quiser saber se um bloco terminou usa poll_pending_block(). No
## máximo 1 lote pendente por Mina a qualquer momento (garantido por
## start_next_block_async() e poll_pending_block() — nunca despacha um
## lote novo sem antes limpar o pendente, mesma invariante que evita a
## cascata histórica de "Invalid Task ID").
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

## Alvo máximo de batalhas ÚNICAS E VÁLIDAS de toda a estimativa —
## nunca permutações brutas examinadas, nunca batalhas repetidas
## (conversa registrada com o dono do projeto). Distribuído em 5 blocos
## via _block_target(), somando exatamente este valor.
const TARGET_VALID_BATTLES: int = 18144

## Quantos blocos compõem a estimativa completa — a partir daqui a
## amostra já atinge alta confiança estatística (99% de confiança,
## margem de erro < 1% — conversa registrada com o dono do projeto) e a
## Eficiência é congelada para o resto do Ciclo. Não existe bloco 6.
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
	mina.efficiency_permutation_cursor = 0
	mina.efficiency_current_block_valid_count = 0
	mina.efficiency_blocks_completed = 0
	mina.efficiency_wins = 0
	mina.efficiency_ties = 0
	mina.efficiency_losses = 0
	mina.efficiency_seen_formation_keys = {}
	mina.efficiency_pending_task_ids = []
	mina.efficiency_pending_chunk_results = []


## True se a estimativa não precisa (nem pode) disparar mais nenhum
## bloco — os 5 blocos já foram concluídos, OU o universo bruto de
## 362.880 permutações já foi inteiramente examinado antes disso (MINES.md,
## "Universo Válido Menor que o Alvo" — só ocorre se a Formação de
## Referência tiver poucas formações efetivas válidas e únicas
## disponíveis). Usada tanto para parar de agendar blocos novos quanto
## para a UI tratar a Eficiência como final.
static func has_high_confidence(mina: Mina) -> bool:
	return mina.efficiency_blocks_completed >= HIGH_CONFIDENCE_BLOCKS \
		or mina.efficiency_permutation_cursor >= TOTAL_PERMUTATIONS


## Quantas batalhas ÚNICAS E VÁLIDAS o bloco de índice "block_index"
## (0-based) precisa acumular — soma exatamente TARGET_VALID_BATTLES
## across os HIGH_CONFIDENCE_BLOCKS blocos, via a mesma técnica de
## fronteiras por arredondamento já usada no projeto (evita ambiguidade
## de divisão: 18.144/5 não é inteiro).
static func _block_target(block_index: int) -> int:
	var start: int = int(float(block_index) * TARGET_VALID_BATTLES / float(HIGH_CONFIDENCE_BLOCKS))
	var end: int = int(float(block_index + 1) * TARGET_VALID_BATTLES / float(HIGH_CONFIDENCE_BLOCKS))
	return end - start


## Dispara o PRÓXIMO bloco em segundo plano, SEM esperar — não faz
## nada se já houver um bloco em andamento (chame poll_pending_block()
## primeiro), se a estimativa já tiver alta confiança (5 blocos ou
## universo esgotado), ou se o universo bruto se esgotar exatamente
## nesta chamada sem produzir nenhuma formação nova (nesse caso
## has_high_confidence() já refletirá isso na próxima checagem, via o
## cursor — não é necessário forçar nenhum estado aqui).
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
		return  # já tem um lote em andamento
	if has_high_confidence(mina):
		return

	var needed: int = _block_target(mina.efficiency_blocks_completed) - mina.efficiency_current_block_valid_count
	if needed <= 0:
		return
	var batch: Array = _build_next_batch(mina, needed)
	if batch.is_empty():
		return  # universo bruto esgotado sem nenhuma formação nova — cursor já reflete isso

	var started: Dictionary = MiningEfficiencyEstimator.start_batch_async(
		guarnicao_commander, guarnicao_cards, batch, reference_commander,
		battlefields, abilities_by_name, unit_traits, thread_count
	)
	mina.efficiency_pending_task_ids = started["task_ids"]
	mina.efficiency_pending_chunk_results = started["chunk_results"]


## Checagem SEM BLOQUEAR do lote em andamento (se houver) — se já
## terminou, agrega o resultado nos contadores acumulados da Mina e no
## contador do bloco atual; encerra o bloco (avança
## efficiency_blocks_completed, zera o contador do bloco) quando o
## bloco atinge sua cota de batalhas válidas OU o universo bruto se
## esgota. Retorna true se um lote foi concluído e agregado nesta
## chamada, false se ainda não havia nada pendente ou o lote pendente
## ainda não tinha terminado.
static func poll_pending_block(mina: Mina) -> bool:
	if mina.efficiency_pending_task_ids.is_empty():
		return false

	var result: Variant = MiningEfficiencyEstimator.poll_batch(mina.efficiency_pending_task_ids, mina.efficiency_pending_chunk_results)
	if result == null:
		return false  # ainda não terminou

	mina.efficiency_wins += result["wins"]
	mina.efficiency_ties += result["ties"]
	mina.efficiency_losses += result["losses"]
	mina.efficiency_current_block_valid_count += result["valid_battles"]
	mina.efficiency_pending_task_ids = []
	mina.efficiency_pending_chunk_results = []

	if mina.efficiency_current_block_valid_count >= _block_target(mina.efficiency_blocks_completed) \
		or mina.efficiency_permutation_cursor >= TOTAL_PERMUTATIONS:
		mina.efficiency_blocks_completed += 1
		mina.efficiency_current_block_valid_count = 0

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


## Constrói o próximo lote de permutações a simular, contendo até
## "needed" formações ÚNICAS E VÁLIDAS — filtragem inteira na THREAD
## PRINCIPAL, antes de qualquer despacho ao WorkerThreadPool (nunca
## dentro de _run_chunk(), que roda em paralelo sem estado compartilhado
## seguro — F-003). Avança mina.efficiency_permutation_cursor por CADA
## permutação bruta examinada (válida, inválida ou duplicada), nunca
## reexamina o mesmo índice bruto duas vezes. Para quando "needed"
## formações tiverem sido selecionadas, ou quando o cursor atingir
## TOTAL_PERMUTATIONS primeiro (universo esgotado — retorna o que tiver
## conseguido reunir até ali, possivelmente menos que "needed", possivelmente
## vazio).
static func _build_next_batch(mina: Mina, needed: int) -> Array:
	var all_permutations: Array = MiningPermutations.generate_all(mina.reference_cards)

	var original_index_by_card: Dictionary = {}
	for i in range(mina.reference_cards.size()):
		original_index_by_card[mina.reference_cards[i]] = i

	var batch: Array = []
	while batch.size() < needed and mina.efficiency_permutation_cursor < TOTAL_PERMUTATIONS:
		var permutation_index: int = mina.efficiency_permutation_order[mina.efficiency_permutation_cursor]
		mina.efficiency_permutation_cursor += 1

		var permutation: Array = all_permutations[permutation_index]
		var key: String = _effective_formation_key(permutation, original_index_by_card)
		if mina.efficiency_seen_formation_keys.has(key):
			continue  # mesma formação efetiva de uma permutação já selecionada antes — descarta

		var candidate_cards: Array[CardResource] = []
		for card: Variant in permutation:
			candidate_cards.append(card as CardResource)
		var candidate_army := Army.new()
		candidate_army.commander = mina.reference_commander
		candidate_army.cards = candidate_cards

		if not candidate_army.is_ready_for_battle() or candidate_army.has_support_at_position_5():
			continue  # inválida — NUNCA registra a chave (só formações selecionadas entram no set)

		mina.efficiency_seen_formation_keys[key] = true
		batch.append(permutation)

	return batch


## Chave canônica da formação de combate EFETIVA de "permutation" —
## espelha exatamente o algoritmo de CombatEngine._place_army(): a
## PRIMEIRA carta de Classe "Máquina de Guerra" encontrada (se houver) é
## removida (ela sempre vai para a Posição 9, não importa onde estava
## na permutação bruta); as demais preservam sua ordem relativa e
## ocupam as posições restantes. A chave é essa ordem relativa,
## representada pelos índices ORIGINAIS (estáveis, em
## mina.reference_cards) de cada carta — nunca o índice da permutação
## bruta, nunca identidade de objeto isolada. Verificado nesta sessão:
## mesma chave <=> mesma formação de combate final (posições 1-9).
static func _effective_formation_key(permutation: Array, original_index_by_card: Dictionary) -> String:
	var machine_found: bool = false
	var key_parts: Array[String] = []
	for card: Variant in permutation:
		var c: CardResource = card as CardResource
		if c.card_class == "Máquina de Guerra" and not machine_found:
			machine_found = true
			continue
		key_parts.append(str(original_index_by_card[c]))
	return ",".join(key_parts)


## Assinatura da configuração da Guarnição relevante para o resultado
## de combate (MINES.md, "Reaproveitamento de Eficiência") — Comandante
## (instance_id + accumulated_xp, que determina a Patente e os efeitos
## de Doutrina lidos em combate) e cada uma das 9 cartas, NA ORDEM
## exata do Exército (a ordem determina a Posição, que afeta o combate
## via bônus estruturais de Posição 1) — instance_id, tier e os
## atributos de combate atuais (atk/hp/esc). Lê os atributos de combate
## diretamente em vez de confiar apenas em Tier como proxy completo.
static func garrison_signature(army: Army) -> Dictionary:
	var commander_id: int = army.commander.instance_id if army.commander != null else -1
	var commander_xp: int = army.commander.accumulated_xp if army.commander != null else -1
	var cards_signature: Array = []
	for card: CardResource in army.cards:
		cards_signature.append([card.instance_id, card.tier, card.atk, card.hp, card.esc])
	return {"commander_id": commander_id, "commander_xp": commander_xp, "cards": cards_signature}


## Registra a assinatura de "army" em "mina" como a configuração à qual
## a Eficiência congelada atual pertence — chamado uma única vez, no
## instante em que a estimativa atinge alta confiança (has_high_confidence()).
static func capture_garrison_signature(mina: Mina, army: Army) -> void:
	var signature: Dictionary = garrison_signature(army)
	mina.efficiency_source_commander_id = signature["commander_id"]
	mina.efficiency_source_commander_xp = signature["commander_xp"]
	mina.efficiency_source_card_signature = signature["cards"]


## True se "army" tem exatamente a mesma configuração relevante para
## combate que a assinatura já registrada em "mina" — só então a
## Eficiência congelada (mina.cycle_efficiency) pode ser reaproveitada
## sem recalcular. Sempre false se nenhuma Eficiência de verdade foi
## calculada ainda (cycle_efficiency < 0.0).
static func garrison_signature_matches(mina: Mina, army: Army) -> bool:
	if mina.cycle_efficiency < 0.0:
		return false
	var current: Dictionary = garrison_signature(army)
	return current["commander_id"] == mina.efficiency_source_commander_id \
		and current["commander_xp"] == mina.efficiency_source_commander_xp \
		and current["cards"] == mina.efficiency_source_card_signature


static func _seeded_shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp
