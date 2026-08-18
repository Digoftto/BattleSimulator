class_name Mina
extends RefCounted
## Mina (PvE.md / MINES.md)
##
## Ramificação econômica lateral e opcional, associada a uma Fase
## adjacente da Trilha principal — nunca faz parte das 9.000 Fases e
## nunca altera a progressão principal.
##
## adjacent_fase = -1 representa a Mina Inicial (MINES.md, "Mina
## Inicial (Bootstrap)") — pertence à Cidade/Reino desde o início da
## conta, sem nenhuma Fase associada (decisão do jogador: "é como se
## ela fosse da Cidade, mas fica visualmente no exterior da cidade
## antes das trilhas").
##
## Escopo atual: representa "esta Mina existe, está vinculada a esta
## Fase (ou à Cidade), e ainda não foi conquistada". Produção contínua
## (Ciclo de Mineração) e Guarnição pertencem a MINES.md e a uma Sprint
## futura.

var adjacent_fase: int
var faction: String
var conquered: bool = false

## Região (1, 2 ou 3 — Região I/II/III da Trilha) em que esta Mina está
## localizada (MinaPlacementGenerator define no momento da geração).
## 0 = não aplicável (Mina Inicial, que não usa banda de Região —
## MINES.md, "Mina Inicial", progressão geométrica própria).
var region: int = 0

## Exército designado como Guarnição da Mina (MINES.md, "Escolha da
## Guarnição da Mina"). null = nenhum designado ainda. Enquanto
## designado E o Ciclo estiver ativo, este Exército fica travado
## (Army.Availability.GUARNICAO_MINA) — ver MineGuarnicaoResolver.
var guarnicao_army: Army

## Instante (Unix Timestamp) do último crédito de produção horária ao
## Depósito (GameRuntime.sync()). 0 = nunca creditado ainda neste
## ciclo. Mesmo padrão de referência incremental já usado por
## Army.last_energy_sync_unix — preserva progresso parcial de hora,
## nunca creditando duas vezes o mesmo intervalo.
var last_production_credit_unix: int = 0

## Nível estrutural da Mina (MINES.md, "Evolução da Estrutura das
## Minas") — evolui exclusivamente via Pontos de Geração, nunca com
## Ferro Negro/Cristais Arcanos/Essência Vital. Determina, junto da
## Eficiência da Guarnição (ainda não implementada), a Produção Base
## por hora (ver MineEconomy.base_production_per_hour()).
var structure_level: int = 1

## Formação de Referência do Ciclo de Mineração (MINES.md): congelada
## no momento da conquista, a partir do mesmo Chefe de Mina que o
## jogador derrotou (EnemyArmySelector já entrega a versão com posição
## embaralhada). Permanece fixa para sempre — é contra ela que a
## Guarnição da Mina disputa as 362.880 combinações em todo Ciclo de
## Mineração futuro, nunca sorteada de novo.
var reference_cards: Array[CardResource] = []
var reference_commander: CommanderResource


func has_reference_formation() -> bool:
	return not reference_cards.is_empty()


## Congela a formação de referência. Só deve ser chamado uma vez, no
## momento exato da conquista (MineConquestResolver) — chamar de novo
## substituiria uma referência já fixada, o que MINES.md não prevê.
func freeze_reference_formation(cards: Array[CardResource], commander: CommanderResource) -> void:
	reference_cards = cards.duplicate()
	reference_commander = commander


## Duração do Ciclo de Mineração (MINES.md: "aproximadamente 100 horas
## (≈4,2 dias)" — 362.880 combinações à razão conceitual de 1/segundo).
const CYCLE_DURATION_SECONDS: int = 100 * 60 * 60

## Instante (Unix Timestamp) de início do Ciclo de Mineração atual.
## 0 = nenhum ciclo ativo (mina conquistada mas produção nunca
## iniciada, ou ciclo anterior expirado e ainda não reativado).
var cycle_started_unix: int = 0

## Eficiência da Guarnição calculada para o ciclo atual/mais recente
## (MiningCycleResolver.simulate_efficiency()) — congelada junto do
## início do ciclo, nunca recalculada até a próxima ativação
## (MINES.md, "Congelamento do Estado do Ciclo"). -1.0 = nenhum
## resultado calculado ainda.
var cycle_efficiency: float = -1.0

## Modo de Renovação (MINES.md, "Renovação") — false (padrão) = Manual:
## ao fim do Ciclo, a Guarnição é liberada e aguarda decisão do
## jogador. true = Automática: um novo Ciclo começa sozinho ao fim do
## anterior, reaproveitando a mesma Eficiência já calculada (nunca
## recalcula as 362.880 combinações de novo, já que nem a Guarnição
## nem a Formação de Referência mudam).
var auto_renew_enabled: bool = false

## --- Estimativa Incremental de Eficiência (MINES.md, "Cálculo
## Incremental por Amostragem") — modelo final: até 18.144 BATALHAS
## ÚNICAS E VÁLIDAS (formação efetiva, nunca permutação bruta), em
## exatamente 5 blocos, nunca 100. ---

## Ordem embaralhada dos índices das 362.880 permutações brutas —
## gerada uma única vez, no início da estimativa (nunca de novo, senão
## formações já examinadas poderiam repetir). O cursor abaixo avança
## por ela sequencialmente, nunca sorteada de novo.
var efficiency_permutation_order: Array[int] = []

## Quantas permutações BRUTAS já foram examinadas (válidas, inválidas
## ou duplicadas — todas contam aqui) desde o início da estimativa.
## Monotônico, nunca retrocede, nunca reexamina o mesmo índice bruto
## duas vezes. Teto: MiningCycleResolver.TOTAL_PERMUTATIONS (362.880).
var efficiency_permutation_cursor: int = 0

## Quantas BATALHAS ÚNICAS E VÁLIDAS o bloco atual (efficiency_blocks_
## completed) já acumulou. Zerado sempre que um bloco se encerra.
var efficiency_current_block_valid_count: int = 0

## Quantos dos 5 blocos já foram concluídos e agregados.
var efficiency_blocks_completed: int = 0

var efficiency_wins: int = 0
var efficiency_ties: int = 0
var efficiency_losses: int = 0

## Chaves das formações EFETIVAS (não das permutações brutas — ver
## MiningCycleResolver._effective_formation_key()) já selecionadas para
## simulação nesta estimativa — nunca a mesma formação de combate duas
## vezes, mesmo que múltiplas permutações brutas colapsem nela (Máquina
## de Guerra sempre na Posição 9, CombatEngine._place_army()). Uma
## chave só entra aqui quando a formação é válida E de fato selecionada
## pro lote a ser simulado — nunca por ter sido apenas inspecionada.
var efficiency_seen_formation_keys: Dictionary = {}

## IDs de tarefa do WorkerThreadPool de um bloco em andamento — vazio
## quando nenhum bloco está sendo calculado no momento. Nunca
## persistido em save/load (tarefas em memória não sobrevivem a
## fechar o jogo) — ao carregar, um bloco "em andamento" é
## simplesmente reiniciado do zero na próxima sincronização.
var efficiency_pending_task_ids: Array[int] = []
var efficiency_pending_chunk_results: Array = []

## --- Assinatura da Guarnição associada à Eficiência congelada acima
## (MINES.md, "Reaproveitamento de Eficiência") — permite decidir se um
## novo Ciclo com a mesma Guarnição pode reaproveitar cycle_efficiency
## em vez de recalcular. Ver MiningCycleResolver.garrison_signature*().
## -1 = nenhuma assinatura registrada ainda (nunca reaproveitável). ---
var efficiency_source_commander_id: int = -1
var efficiency_source_commander_xp: int = -1
var efficiency_source_card_signature: Array = []


## True se a Mina está ativamente produzindo, em relação a "now_unix"
## (GameClock.now_unix(), fornecido por quem chama — Mina nunca lê o
## relógio sozinha, mesma regra de todo o projeto).
##
## MINES.md diferencia claramente os dois modelos: Mina Inicial
## ("Progressão: Geométrica... por hora") produz CONTINUAMENTE pra
## sempre, uma vez ativada — nunca expira, nunca tem Ciclo de 100h.
## Só as Minas de Trilha (Regionais) têm o Ciclo de Mineração de
## ~100h descrito na seção própria do documento.
func is_cycle_active(now_unix: int) -> bool:
	if cycle_started_unix == 0:
		return false
	if is_initial_mine():
		return true  # produção contínua, sem prazo — nunca expira
	return (now_unix - cycle_started_unix) < CYCLE_DURATION_SECONDS


## Inicia um novo Ciclo de Mineração com a Eficiência já calculada
## externamente (MiningCycleResolver.simulate_efficiency()) — o cálculo
## em si nunca é responsabilidade de Mina, só o armazenamento do
## resultado e da referência de tempo (MINES.md, "Congelamento do
## Estado do Ciclo": Guarnição, nível estrutural, produção base e
## eficiência ficam fixos durante todo o ciclo).
func start_cycle(now_unix: int, efficiency: float) -> void:
	cycle_started_unix = now_unix
	cycle_efficiency = efficiency


func _init(p_adjacent_fase: int, p_faction: String) -> void:
	adjacent_fase = p_adjacent_fase
	faction = p_faction


func is_initial_mine() -> bool:
	return adjacent_fase == -1


func conquer() -> void:
	conquered = true


func increment_structure_level() -> void:
	structure_level += 1


func assign_guarnicao(army: Army) -> void:
	guarnicao_army = army


func clear_guarnicao() -> void:
	guarnicao_army = null


func mark_production_credited(now_unix: int) -> void:
	last_production_credit_unix = now_unix
