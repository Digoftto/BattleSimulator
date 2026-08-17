class_name Kingdom
extends RefCounted
## Kingdom ("Reino" — GLOSSARY.md, CITY.md)
##
## "Identidade permanente do jogador, compreendendo toda a sua
## infraestrutura, acervo e progressão." (GLOSSARY.md, verbete Reino).
##
## Kingdom é o proprietário único de todo o estado persistente do
## jogador que hoje existe disperso. Regra estrutural desta classe:
##
##   Kingdom possui, referencia, persiste.
##   Kingdom NUNCA calcula, resolve ou gera.
##
## Toda lógica de negócio continua exclusivamente nos sistemas já
## especializados (CombatEngine, CampaignSynergyCalculator,
## PhaseResolver, SeasonPipeline, CommanderCareer, Soldo,
## EnergyNucleus...). Kingdom não reimplementa nada disso — apenas
## guarda o dado sobre o qual esses sistemas operam.
##
## Nota de implementação importante: Soldo e EnergyNucleus são
## bibliotecas de fórmulas puramente estáticas (SOLDO.md,
## ENERGY_NUCLEUS.md) — não possuem estado de instância para "migrar
## posse" (não há um objeto Soldo/EnergyNucleus para o Reino guardar).
## O que o Reino de fato possui é o DADO que essas fórmulas consomem:
## o nível do Núcleo de Energia (energy_nucleus_level, usado como
## EnergyNucleus.energia_base(nivel)/recovery_seconds(nivel)) e a
## Patente de cada Comandante (já em CommanderResource.accumulated_xp,
## consultada via CommanderCareer.patente_for_xp() quando necessário).
## Nenhuma cópia paralela desses valores foi criada.
##
## Sistemas que continuam INDEPENDENTES do Reino (compartilhados entre
## todos os jogadores, ou pertencentes a outro domínio): GameDatabase
## (catálogo do jogo, não patrimônio de ninguém), SeasonCatalog/
## SeasonPipeline/EnemyArmySelector (dados/serviços de Temporada),
## CombatEngine e todo o domínio de Combate.

## Nível do Núcleo de Energia do Reino (ENERGY_NUCLEUS.md) — consultado
## via EnergyNucleus.energia_base(energy_nucleus_level) /
## EnergyNucleus.recovery_seconds(energy_nucleus_level) quando necessário.
var energy_nucleus_level: int = 1


func increment_energy_nucleus_level() -> void:
	energy_nucleus_level += 1


## XP de Conta (Reino) — XP.md: "200 XP = 1 Nível de Conta = 1 Ponto
## de Geração". Nunca decrementa. A conversão em PG ao cruzar um novo
## Nível é responsabilidade de AccountXPResolver, nunca de Kingdom.
var account_xp: int = 0


func add_account_xp(amount: int) -> void:
	account_xp += amount


## Nível de Conta atual (XP.md: linear, 200 XP por nível, sem curva
## crescente). O Reino inicia no Nível 1 (0 XP).
func account_level() -> int:
	@warning_ignore("integer_division")
	return 1 + (account_xp / 200)


## Registro de conquistas estruturais de XP de Conta já concedidas
## (XP.md: "cada conquista estrutural concede XP apenas na primeira
## vez"). Chave livre por conquista, ex: "card_obtained:Lanceiro
## Imperial", "mina_liberada:500:Império". Kingdom só guarda; quem
## decide o formato da chave e verifica antes de conceder é
## AccountXPResolver.
var structural_xp_unlocked: Dictionary = {}


func has_structural_xp(key: String) -> bool:
	return structural_xp_unlocked.has(key)


func mark_structural_xp(key: String) -> void:
	structural_xp_unlocked[key] = true

## Comandantes que o jogador possui — distinto de GameDatabase.commanders
## (catálogo de arquétipos usado pela geração procedural), que nunca é
## o inventário de ninguém.
var commanders: Array[CommanderResource] = []

## Cartas que o jogador possui — distinto de GameDatabase.cards
## (catálogo do jogo).
var cards: Array[CardResource] = []

## --- Biblioteca (LIBRARY.md) ---

## card_name -> true. Marcação pessoal do jogador, puramente
## organizacional (LIBRARY.md, "Favoritos") — nunca afeta nenhuma
## regra de jogo.
var favorite_card_names: Dictionary = {}

## card_name -> true. Marca cartas cujo NOME (não cópia individual)
## foi obtido pela primeira vez e ainda não foi visto na Biblioteca
## (LIBRARY.md, "Nova... limpa após visualização"). Setado em
## acquire_card_from_catalog() na primeira cópia daquele nome.
var new_card_names: Dictionary = {}


func toggle_favorite_card(card_name: String) -> void:
	if favorite_card_names.has(card_name):
		favorite_card_names.erase(card_name)
	else:
		favorite_card_names[card_name] = true


func is_favorite_card(card_name: String) -> bool:
	return favorite_card_names.has(card_name)


## Limpa a marcação "Nova" de uma carta — chamado ao visualizar sua
## página na Biblioteca.
func clear_new_card_flag(card_name: String) -> void:
	new_card_names.erase(card_name)


func is_new_card(card_name: String) -> bool:
	return new_card_names.has(card_name)

## Exércitos formados pelo jogador (ARMY.md) — cada um já carrega suas
## próprias Formações (Army.formations/formation_priority).
var armies: Array[Army] = []

## Squads do jogador, um por modo de jogo quando aplicável (ARMY.md:
## "O jogador poderá possuir diferentes Squads para diferentes modos").
var squads: Array[Squad] = []

## Expedições ativas do jogador (PvE.md).
var active_expeditions: Array[ExpeditionRuntime] = []

## territory_id -> quantas vezes a Trilha daquele Território já foi
## concluída inteiramente (PvE.md, "Exigências Estritas de Composição
## de Squad": 1ª conclusão exige Squad de 1 Exército, 1º Replay exige
## 2, 2º Replay em diante exige 3). NUNCA incrementado ainda — a
## detecção de "Trilha concluída" (derrotar o último Chefe Regional)
## pertence a uma peça futura, fora do escopo desta entrega. Por
## enquanto, toda Expedição nova pede Squad de 1 Exército (correto
## para o único caso hoje possível: a primeira vez em cada Território).
var territory_completion_count: Dictionary = {}


func get_territory_completion_count(territory_id: String) -> int:
	return territory_completion_count.get(territory_id, 0)

## Registro de Comandantes Regionais recrutados (PvE.md, "Comandante
## Regional Recrutado") — pertence ao Reino, que é quem recruta; a
## Expedição apenas consulta.
var regional_commander_registry: RegionalCommanderRegistry = RegionalCommanderRegistry.new()

## Flags de progresso persistentes (ex: Mina conquistada, Região
## liberada, Comandante Regional recrutado, tutorial concluído).
## Dado simples — uma Sprint futura pode formalizar um tipo dedicado
## se a quantidade/complexidade de flags justificar.
var progress_flags: Dictionary = {}

## Fragmentos possuídos pelo jogador, por Facção (RESOURCES.md §3:
## "cada Facção possui seu próprio tipo de Fragmento e uma economia
## independente"). Nasce nesta Sprint porque RewardResolver é seu
## primeiro consumidor real — nenhum outro campo especulativo
## (Buildings, Technologies, Inventory, Statistics) foi adicionado, por
## não terem consumidor hoje.
var resources: Dictionary = {}  # faction -> int (Fragmentos)


func add_fragment(faction: String, amount: int) -> void:
	resources[faction] = get_fragment(faction) + amount


func get_fragment(faction: String) -> int:
	return resources.get(faction, 0)


## Gasta "amount" de Fragmentos da "faction" se houver saldo
## suficiente. Retorna false sem alterar nada se insuficiente — mesmo
## padrão de spend_generation_points()/spend_raw_resource().
func spend_fragment(faction: String, amount: int) -> bool:
	if get_fragment(faction) < amount:
		return false
	resources[faction] = get_fragment(faction) - amount
	return true


## --- Cidade (CITY.md) ---

## Nível da Capital (CAPITAL.md) — limita o nível máximo de todas as
## construções urbanas institucionais (Depósitos, Centro de Comando,
## Núcleo de Energia, Academia — ver Capital.can_building_evolve()).
## "A cidade inicia com todas as construções disponíveis no nível 1"
## (CAPITAL.md, "Estrutura Inicial"). Custo de evolução da própria
## Capital ainda não implementado: seus parâmetros (b, x) da Fórmula
## Geral de Construções estão pendentes de calibração em FORMULAS.md.
var capital_level: int = 1

## Centro de Comando e Academia: nível rastreado desde já (mesma regra
## de início no nível 1), mas sem lógica de evolução própria ainda —
## seus parâmetros de custo (Fórmula Geral de Construções) também
## seguem pendentes de calibração em FORMULAS.md.
var command_center_level: int = 1

## Recursos Administrativos já ativados (COMMAND_CENTER_PROGRESS.md,
## "Expansão Administrativa") — a parte USÁVEL da Infraestrutura
## Administrativa gerada pelo Nível do CdC. Só cresce via
## CommandCenterResolver.activate_next() (gasta PG); nunca calculado
## aqui, Kingdom só guarda o total já ativado.
## Exceção Inicial (COMMAND_CENTER_PROGRESS.md, "Exceção Inicial —
## Recursos Administrativos Gratuitos"): 1 Cargo Ativo + 1 Vaga da
## Reserva já nascem ativados, sem custo em PG — a única exceção à
## regra geral de Expansão Administrativa em todo o sistema, só pra
## garantir que um Reino novo já consiga alocar 1 Comandante Ativo e 1
## na Reserva sem depender de PG que o jogador ainda não teve chance
## de acumular.
var cargo_ativo_activated: int = 1
var vaga_reserva_activated: int = 1


func increment_cargo_ativo_activated() -> void:
	cargo_ativo_activated += 1


func increment_vaga_reserva_activated() -> void:
	vaga_reserva_activated += 1


## Quantos Comandantes ocupam uma Vaga da Reserva agora — Reserve e
## Training juntos (Training continua contando como ocupante da
## Reserva, COMMAND_CENTER_TRAINING.md). Consulta pura, nunca decide nada.
func reserve_occupancy() -> int:
	var count: int = 0
	for commander: CommanderResource in commanders:
		if commander.administrative_state == CommanderResource.AdministrativeState.RESERVE \
			or commander.administrative_state == CommanderResource.AdministrativeState.TRAINING:
			count += 1
	return count


## XP de combate ganho HOJE por cada Comandante Ativo que efetivamente
## lutou (chave: str(commander.instance_id) -> int) — usado só para
## calcular a Média Diária de XP do dia atual, em construção. Zerado a
## cada virada de dia por CommanderTrainingResolver.
var daily_combat_xp_log: Dictionary = {}

## Qual "dia" (Unix Timestamp / 86400) o daily_combat_xp_log
## representa. -1 = ainda não inicializado.
var training_current_day: int = -1

## Média Diária de XP do último dia já fechado — o número que
## alimenta a XP de Treinamento (COMMAND_CENTER_TRAINING.md) e que a
## UI exibe no Resumo do Centro de Treinamento.
var last_daily_average_xp: int = 0


## Histórico de Comissionamentos (COMMAND_CENTER_RECRUITMENT.md,
## "Histórico de Comissionamentos") — finalidade exclusivamente
## informativa. Cada entrada: {"commander_name": String, "source":
## String, "commissioned_at_unix": int}. Mantém só os 20 mais
## recentes; o mais antigo sai quando um novo ultrapassa o limite.
const COMMISSIONING_HISTORY_LIMIT: int = 20
var commissioning_history: Array[Dictionary] = []


func record_commissioning(commander_name: String, source: String, now_unix: int) -> void:
	commissioning_history.append({
		"commander_name": commander_name,
		"source": source,
		"commissioned_at_unix": now_unix,
	})
	while commissioning_history.size() > COMMISSIONING_HISTORY_LIMIT:
		commissioning_history.pop_front()


## --- Centro de Recrutamento (COMMAND_CENTER_RECRUITMENT.md) ---

## Slots do Centro de Recrutamento — Fonte de Recrutamento distinta do
## Painel PvE (pending_recruitment_offers). null = Slot vazio.
## Candidatos aqui nunca expiram — só saem por Comissionamento.
var recruitment_center_slots: Array[CommanderResource] = []

## Instante (Unix Timestamp) em que o ciclo de geração atual termina.
## 0 = nenhum ciclo em andamento (todos os Slots ocupados, ou nunca
## precisou gerar ainda).
var recruitment_center_cycle_end_unix: int = 0


## Garante que a quantidade de Slots bate com o Nível atual do CdC
## (CommandCenterProgress.recruitment_center_slots()) — só adiciona
## Slots novos (vazios), nunca remove um já existente, mesmo que
## ocupado. Idempotente.
func sync_recruitment_center_slots() -> void:
	var target: int = CommandCenterProgress.recruitment_center_slots(command_center_level)
	while recruitment_center_slots.size() < target:
		recruitment_center_slots.append(null)


## --- Legado (COMMAND_CENTER_LEGACY.md) ---

## Bônus percentual acumulado do Legado I, em pontos percentuais
## (COMMAND_CENTER_LEGACY.md: +0,1pp por Comandante aposentado com
## Patente >= Capitão, limite de +30pp) — soma-se aos 20% base da
## Média Diária de XP do Treinamento (CommanderTrainingResolver).
var legacy_i_xp_bonus_percent: float = 0.0

## Total de Comandantes aposentados via Legado Administrativo (conta
## pros marcos cumulativos de Legado II/III/IV — NÃO inclui
## aposentados via Grande Legado Militar, que tem sua própria
## contagem por Facção em military_doctrine).
var legacy_administrative_retirees: int = 0

## Bônus percentual acumulado do Legado V (COMMAND_CENTER_LEGACY.md:
## +0,05% por Comandante, jogador escolhe o destino no momento da
## aposentadoria) — 3 acumuladores independentes, um por destino.
var legacy_v_bonus_xp: float = 0.0
var legacy_v_bonus_resources: float = 0.0
var legacy_v_bonus_fragments: float = 0.0

## Doutrina Militar por Facção (Grande Legado Militar) — Dictionary de
## Dictionary: {"Império": {"escudo": 0, "vida": 0, "ataque": 0, "grandes_legados": 0}, ...}.
## "grandes_legados" conta TODOS os Grandes Legados daquela Facção,
## mesmo depois dos limites de atributo serem atingidos (Regra de
## Excesso — COMMAND_CENTER_LEGACY.md).
var military_doctrine: Dictionary = {}

## Kit Inicial do Reino (COMMAND_CENTER_RECRUITMENT.md, "Kit Inicial
## do Reino") — true depois que o jogador escolhe uma das 3 opções.
## Existe uma única vez por Reino; nunca reaparece depois, mesmo que
## o Comandante inicial seja posteriormente aposentado ou perdido.
var starter_kit_used: bool = false

## Planos de Campanha do jogador (COMMAND_CENTER.md/RANKING.md, Ligas
## Prata/Ouro/Diamante) — cada um até 3 Exércitos. Sem vínculo com
## Liga/Divisão/Temporada ainda (essa parte de RANKING.md não está
## implementada — ver PlanoCampanhaResolver, "ESCOPO DESTA ENTREGA").
var planos_campanha: Array[PlanoCampanha] = []


func increment_legacy_administrative_retirees() -> void:
	legacy_administrative_retirees += 1


func add_legacy_i_xp_bonus(percent: float) -> void:
	legacy_i_xp_bonus_percent = min(legacy_i_xp_bonus_percent + percent, 30.0)


func add_legacy_v_bonus(destino: String, amount: float) -> void:
	match destino:
		"xp":
			legacy_v_bonus_xp += amount
		"resources":
			legacy_v_bonus_resources += amount
		"fragments":
			legacy_v_bonus_fragments += amount


## Garante que a Facção já tem uma entrada em military_doctrine —
## idempotente, chamado antes de ler ou escrever qualquer atributo dela.
func ensure_military_doctrine(faction: String) -> void:
	if not military_doctrine.has(faction):
		military_doctrine[faction] = {"escudo": 0, "vida": 0, "ataque": 0, "grandes_legados": 0}


## Hall dos Comandantes (COMMAND_CENTER_LEGACY.md) — consulta pura,
## nunca um array separado: um Comandante aposentado (qualquer Tipo)
## continua em kingdom.commanders, só muda para AdministrativeState.RETIRED.
func commander_hall() -> Array[CommanderResource]:
	var hall: Array[CommanderResource] = []
	for commander: CommanderResource in commanders:
		if commander.administrative_state == CommanderResource.AdministrativeState.RETIRED:
			hall.append(commander)
	return hall


var academy_level: int = 1

## Depósito (DEPOSITS.md) — construção única: 1 nível, armazena os 3
## Recursos de Construção simultaneamente (Ferro Negro, Cristais
## Arcanos, Essência Vital). Não são 3 construções separadas — essa
## era uma implementação anterior, corrigida.
var deposito_level: int = 1

## Pontos de Geração (PG) — recurso estratégico global do Reino
## (FORMULAS.md: 200 XP de Conta = 1 Nível de Conta = 1 PG). O sistema
## de XP de Conta que os gera (XP.md) ainda não está implementado nesta
## Sprint; por isso hoje não existe nenhuma fonte automática de PG —
## apenas a capacidade de armazenar e gastar, para que os Depósitos já
## possam consumi-los assim que uma fonte real existir.
var generation_points: int = 0


func add_generation_points(amount: int) -> void:
	generation_points += amount


## Gasta "amount" PG se houver saldo suficiente. Retorna false sem
## alterar nada se o saldo for insuficiente — nunca deixa o saldo
## negativo.
func spend_generation_points(amount: int) -> bool:
	if generation_points < amount:
		return false
	generation_points -= amount
	return true


func increment_deposito_level() -> void:
	deposito_level += 1


func increment_capital_level() -> void:
	capital_level += 1


func increment_command_center_level() -> void:
	command_center_level += 1


func increment_academy_level() -> void:
	academy_level += 1


## Mestres da Academia (ACADEMY.md) — únicos do Reino (não por
## Facção). A quantidade correta por Nível é garantida por
## sync_academy_masters(), nunca calculada aqui.
var academy_artifices: Array[AcademyMaster] = []
var academy_metamorfos: Array[AcademyMaster] = []

## Tarefas de uma cadeia automática (Produção Automática, ACADEMY.md)
## que ainda não foram agendadas em nenhum Mestre — porque dependem de
## outra tarefa ainda não concluída, ou porque não havia Mestre livre
## no momento. AcademyResolver.sync() tenta agendá-las a cada chamada.
var academy_pending_chain_tasks: Array[AcademyTask] = []


## Garante que a quantidade de Mestres bate com o Nível atual da
## Academia (AcademyEconomy.artifice_count()/metamorfo_count()) — só
## adiciona Mestres novos, nunca remove (um Mestre nunca desaparece,
## mesmo que a Academia hipoteticamente regredisse). Idempotente:
## chamar várias vezes sem o Nível ter mudado não faz nada.
func sync_academy_masters() -> void:
	var target_artifices: int = AcademyEconomy.artifice_count(academy_level)
	while academy_artifices.size() < target_artifices:
		academy_artifices.append(AcademyMaster.new_artifice())

	var target_metamorfos: int = AcademyEconomy.metamorfo_count(academy_level)
	while academy_metamorfos.size() < target_metamorfos:
		academy_metamorfos.append(AcademyMaster.new_metamorfo())


## Recursos de Construção (DEPOSITS.md): Ferro Negro, Cristais Arcanos,
## Essência Vital — moeda diferente dos Fragmentos ("resources" acima).
## Produzidos pelas Minas, limitados pela capacidade do Depósito
## correspondente. Nomes de chave: "ferro_negro", "cristais_arcanos",
## "essencia_vital".
var raw_resources: Dictionary = {}  # nome do recurso -> int


func get_raw_resource(resource: String) -> int:
	return raw_resources.get(resource, 0)


## Gasta "amount" de "resource" se houver saldo suficiente. Retorna
## false sem alterar nada se o saldo for insuficiente — mesmo padrão
## de spend_generation_points(), nunca deixa o saldo negativo.
func spend_raw_resource(resource: String, amount: int) -> bool:
	if get_raw_resource(resource) < amount:
		return false
	raw_resources[resource] = get_raw_resource(resource) - amount
	return true


## Credita "amount" do recurso, nunca ultrapassando "capacity" (a
## capacidade atual do Depósito correspondente — DEPOSITS.md, "os
## depósitos atuam como limitadores naturais da progressão"). Retorna
## o excedente perdido por falta de espaço (0 se tudo coube). Este é o
## mesmo tipo de garantia estrutural que spend_generation_points() já
## aplica ao PG (nunca deixar o valor sair dos limites físicos do
## armazenamento) — não é uma decisão de regra de jogo, é a física do
## próprio armazenamento.
func credit_raw_resource(resource: String, amount: int, capacity: int) -> int:
	var current: int = get_raw_resource(resource)
	var new_total: int = mini(current + amount, capacity)
	raw_resources[resource] = new_total
	return (current + amount) - new_total


## Fila de Ofertas de Recrutamento pendentes (PvE.md, "Recrutamento de
## Comandantes de Campanha" + COMMAND_CENTER_RECRUITMENT.md, "Painel
## PvE"). Máximo 10 simultâneas — se uma nova oferta surgir com a fila
## cheia, ela **não é adicionada** (COMMAND_CENTER_RECRUITMENT.md,
## "Lista Cheia (PvE): novos candidatos (...) não poderão ser
## adicionados até que uma vaga seja liberada"). O Chefe Regional
## correspondente já foi marcado como recrutado por quem chamou
## offer_recruitment() antes de perceber que não havia vaga — narrativa
## e mecanicamente, essa submissão se perde (nunca é reofertada
## automaticamente).
const MAX_PENDING_RECRUITMENT_OFFERS: int = 10
var pending_recruitment_offers: Array[RecruitmentOffer] = []

## Nomes dos Comandantes cujas Ofertas expiraram (RecruitmentOffer,
## VALIDITY_DAYS) sem que o jogador tivesse aberto o Painel PvE a
## tempo. Fila de avisos pendente de exibição — a UI (Sprint futura)
## deve consumi-la com consume_expired_recruitment_notifications() na
## primeira vez que o Painel for aberto.
var expired_recruitment_notifications: Array[String] = []


## Cria e enfileira uma nova Oferta de Recrutamento, carimbada com o
## instante de criação (GameClock.now_unix(), fornecido por quem chamou
## — Kingdom nunca lê o relógio sozinho). Retorna a oferta criada, ou
## null se a fila já estava cheia (oferta perdida, conforme
## COMMAND_CENTER_RECRUITMENT.md).
func offer_recruitment(commander: CommanderResource, created_at_unix: int) -> RecruitmentOffer:
	if pending_recruitment_offers.size() >= MAX_PENDING_RECRUITMENT_OFFERS:
		return null

	var offer := RecruitmentOffer.new(commander, created_at_unix)
	pending_recruitment_offers.append(offer)
	return offer


## O jogador aceita uma Oferta pendente: o Comandante ingressa de fato
## no Reino, e a oferta sai da fila. Retorna false se a oferta já não
## estava mais na fila (expirada/já respondida). Primitivo de baixo
## nível — não checa Vaga da Reserva sozinho; a entrada segura é
## CommissioningResolver.commission_from_pve_offer(), que faz essa
## checagem antes de chamar isto.
func accept_recruitment_offer(offer: RecruitmentOffer, now_unix: int = 0) -> bool:
	if not pending_recruitment_offers.has(offer):
		return false
	pending_recruitment_offers.erase(offer)
	add_commander(offer.commander, now_unix)
	return true


## O jogador recusa explicitamente uma Oferta pendente: sai da fila sem
## o Comandante ingressar no Reino. Não gera aviso de expiração — é uma
## decisão consciente do jogador, diferente de expirar sozinha.
func decline_recruitment_offer(offer: RecruitmentOffer) -> void:
	pending_recruitment_offers.erase(offer)


## Remove uma Oferta por expiração (prazo de RecruitmentOffer.VALIDITY_DAYS
## vencido) e registra o aviso para o jogador ver na próxima vez que
## abrir o Painel. Chamado por RecruitmentResolver.purge_expired_offers()
## — Kingdom só guarda o resultado, nunca decide sozinho quem expirou.
func expire_recruitment_offer(offer: RecruitmentOffer) -> void:
	pending_recruitment_offers.erase(offer)
	expired_recruitment_notifications.append(offer.commander.commander_name)


## Consome (lê e limpa) a fila de avisos de expiração pendentes — a UI
## chama isso ao abrir o Painel PvE para exibir os avisos uma única vez.
func consume_expired_recruitment_notifications() -> Array[String]:
	var result: Array[String] = expired_recruitment_notifications.duplicate()
	expired_recruitment_notifications.clear()
	return result


## Minas Iniciais (MINES.md, "Mina Inicial (Bootstrap)") — 1 por tipo
## de recurso, sem Fase associada, disponíveis desde o início da conta
## (decisão do jogador: "como se fosse da Cidade"). Nunca geradas por
## MinaPlacementGenerator — são fixas, não procedurais.
var initial_mines: Array[Mina] = []

## Minas Regionais (MINES.md: 5 por Trilha), por Território — geradas
## sob demanda (a posição é procedural e determinística por jogador,
## nunca recalculada depois de gerada uma vez).
var territory_mines: Dictionary = {}  # territory_id -> Array[Mina]


## Cria as 3 Minas Iniciais (Ferro Negro, Cristais Arcanos, Essência
## Vital), uma por Facção/recurso. Não faz nada se já tiverem sido
## criadas (chamado uma única vez, ao formar o Reino).
func create_initial_mines() -> void:
	if not initial_mines.is_empty():
		return
	for faction in ["Império", "Natureza", "Mortos-Vivos"]:
		var mina := Mina.new(-1, faction)
		# MINES.md, "Mina Inicial (Bootstrap)": "Requisito: Não exige
		# exército defensor ou Guarnição da Mina" — está disponível
		# desde o início da conta, nunca precisa de combate. Sem isso,
		# o código tratava a Mina Inicial igual às Regionais, exigindo
		# conquista via combate antes de poder escolher a Guarnição.
		mina.conquer()
		initial_mines.append(mina)


## Gera (uma única vez) as 5 Minas Regionais de um Território, e as
## guarda associadas a ele. Chamadas seguintes para o mesmo
## territory_id retornam a mesma lista, sem regenerar.
func generate_territory_mines(territory_id: String, faction: String, trilha: Trilha, seed_value: int) -> Array[Mina]:
	if territory_mines.has(territory_id):
		return territory_mines[territory_id]

	var mines: Array[Mina] = MinaPlacementGenerator.generate(faction, trilha, seed_value)
	territory_mines[territory_id] = mines
	return mines


## Todas as Minas do Reino (Iniciais + Regionais de todos os
## Territórios já gerados), para sistemas que precisam processar todas
## de uma vez (ex: GameRuntime.sync()).
func all_mines() -> Array[Mina]:
	var result: Array[Mina] = []
	result.append_array(initial_mines)
	for territory_id: String in territory_mines:
		result.append_array(territory_mines[territory_id])
	return result


## Contador para atribuir instance_id ao Comandante — nunca reaproveitado.
var next_commander_instance_id: int = 1


## Registra um Comandante que ingressou no Reino (hoje: só via
## Recrutamento). Dá a ele um RG único, marca como Livre, e entra
## diretamente no Estado Administrativo Reserva
## (COMMAND_CENTER_RECRUITMENT.md, "Efeitos do Comissionamento").
## "now_unix" (opcional, default 0) registra a Data de Comissionamento
## para o Hall dos Comandantes (COMMAND_CENTER_LEGACY.md) — default 0
## preserva o comportamento anterior para chamadores que não têm
## acesso a GameClock.now_unix() (a maioria dos testes). Nunca chamado
## durante o carregamento de um save, que já restaura RG e status
## salvos diretamente.
func add_commander(commander: CommanderResource, now_unix: int = 0) -> void:
	commander.instance_id = next_commander_instance_id
	next_commander_instance_id += 1
	commander.ownership_status = CommanderResource.OwnershipStatus.LIVRE
	commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	commander.commissioned_at_unix = now_unix
	commanders.append(commander)


func add_card(card: CardResource) -> void:
	cards.append(card)


## Remove definitivamente uma cópia da coleção do Reino — usado quando
## a Academia consome uma carta como ingrediente (Aprimoramento ou
## receita). Nunca chamado para cartas ainda em uso (EM_EXERCITO); quem
## decide se a carta pode ser consumida é AcademyResolver.
func remove_card(card: CardResource) -> void:
	cards.erase(card)


## Contador para atribuir instance_id (o "RG" da carta) — nunca reaproveitado.
var next_card_instance_id: int = 1


## Adquire uma cópia nova de uma carta de catálogo (GameDatabase): faz
## uma cópia independente (nunca a carta original do catálogo, que
## precisa continuar intacta para todos os jogadores), dá um RG único a
## ela, marca como Livre, e a adiciona à coleção do Reino.
func acquire_card_from_catalog(catalog_card: CardResource) -> CardResource:
	var owned_copy: CardResource = catalog_card.duplicate()
	owned_copy.instance_id = next_card_instance_id
	owned_copy.ownership_status = CardResource.OwnershipStatus.LIVRE
	next_card_instance_id += 1

	# "Nova" (LIBRARY.md) — só na primeira cópia de um nome nunca visto
	# antes, não a cada cópia adicional.
	var already_owned: bool = false
	for card: CardResource in cards:
		if card.card_name == catalog_card.card_name:
			already_owned = true
			break
	if not already_owned:
		new_card_names[catalog_card.card_name] = true

	cards.append(owned_copy)
	return owned_copy


## Consulta segura (sem disparar nenhum assert): true se a carta
## pertence a este Reino e está Livre para ser alocada.
func is_card_available(card: CardResource) -> bool:
	return cards.has(card) and card.ownership_status == CardResource.OwnershipStatus.LIVRE


## Consulta segura: true se o Comandante pertence a este Reino, está
## Livre e está no Estado Administrativo Ativo — os 3 requisitos pra
## liderar um novo Exército (COMMAND_CENTER.md: só Comandantes Ativos
## podem liderar Exércitos em combate).
func is_commander_available(commander: CommanderResource) -> bool:
	return commanders.has(commander) \
		and commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE \
		and commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE


## Forma um novo Exército usando um Comandante e Cartas que o jogador já
## possui (nunca cria carta/comandante novo). Falha explicitamente
## (assert) se o Comandante ou qualquer carta não pertencerem ao Reino
## ou já não estiverem Livres — nunca aloca a mesma carta/Comandante em
## dois lugares. Comandante e cartas usados passam a EM_EXERCITO; o
## próprio Exército referencia essas mesmas cópias, nunca duplicatas.
func form_army(commander: CommanderResource, selected_cards: Array[CardResource]) -> Army:
	assert(commanders.has(commander), "Kingdom.form_army: o Comandante '%s' (RG %d) não pertence a este Reino." % [commander.commander_name, commander.instance_id])
	assert(commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE,
		"Kingdom.form_army: o Comandante '%s' (RG %d) já lidera outro Exército." % [commander.commander_name, commander.instance_id])
	assert(commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE,
		"Kingdom.form_army: o Comandante '%s' (RG %d) precisa estar no Estado Ativo para liderar um Exército (hoje: %s)." % [
			commander.commander_name, commander.instance_id, CommanderResource.AdministrativeState.keys()[commander.administrative_state]
		])

	for card: CardResource in selected_cards:
		assert(cards.has(card), "Kingdom.form_army: a carta '%s' (RG %d) não pertence a este Reino." % [card.card_name, card.instance_id])
		assert(card.ownership_status == CardResource.OwnershipStatus.LIVRE,
			"Kingdom.form_army: a carta '%s' (RG %d) já está em uso e não pode ser alocada de novo." % [card.card_name, card.instance_id])

	commander.ownership_status = CommanderResource.OwnershipStatus.EM_EXERCITO
	for card: CardResource in selected_cards:
		card.ownership_status = CardResource.OwnershipStatus.EM_EXERCITO

	var army := Army.new()
	army.commander = commander
	army.cards = selected_cards
	# Sem isso, TODO Exército recém-formado nascia com 0/0 de Energia
	# (Army.new() nunca inicializa sozinho) — incapaz de tentar
	# qualquer Fase de PvE, em qualquer lugar que formasse um Exército
	# (Kit Inicial, Editor de Exército).
	army.initialize_energy(energy_nucleus_level)
	# ARMY.md, "Arquétipos de Formação (β, γ, δ, ε)": todo Exército já
	# nasce com as 5 Formações — α é a composição escolhida pelo
	# jogador (selected_cards, acima); β-ε são geradas automaticamente
	# aqui, sempre, mesmo que o jogador nunca abra o Editor de
	# Formações — nunca idênticas entre si, nunca aleatórias.
	var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(selected_cards)
	for formation_name: String in archetypes:
		army.formations[formation_name] = archetypes[formation_name]

	armies.append(army)
	return army


## Reconfigura um Exército JÁ EXISTENTE com um novo Comandante e/ou
## novas Cartas (ARMY.md — usado pelo botão "Editar Exército"). Libera
## o Comandante e as Cartas antigas de volta pro Reino (Comandante
## volta a ficar Ativo/livre pra outro Exército; Cartas voltam a
## LIVRE) antes de alocar os novos, e regenera as 5 Formações do
## zero — as antigas referenciavam Cartas que talvez nem façam mais
## parte do Exército.
func re_form_army(army: Army, new_commander: CommanderResource, new_selected_cards: Array[CardResource]) -> void:
	assert(armies.has(army), "Kingdom.re_form_army: este Exército não pertence a este Reino.")

	var lock: Dictionary = is_army_locked_for_editing(army)
	assert(not lock["locked"], "Kingdom.re_form_army: %s" % lock["reason"])

	var old_commander: CommanderResource = army.commander
	var old_cards: Array[CardResource] = army.cards.duplicate()
	var now: int = GameClock.now_unix()

	if old_commander != null and old_commander != new_commander:
		old_commander.ownership_status = CommanderResource.OwnershipStatus.LIVRE
	for old_card: CardResource in old_cards:
		if not new_selected_cards.has(old_card):
			old_card.ownership_status = CardResource.OwnershipStatus.LIVRE
			old_card.last_removed_from_army_unix = now  # ENERGY.md, "Penalidade de Composição"

	assert(new_commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE or new_commander == old_commander,
		"Kingdom.re_form_army: o Comandante '%s' (RG %d) já lidera outro Exército." % [new_commander.commander_name, new_commander.instance_id])
	for card: CardResource in new_selected_cards:
		assert(card.ownership_status == CardResource.OwnershipStatus.LIVRE or old_cards.has(card),
			"Kingdom.re_form_army: a carta '%s' (RG %d) já está em uso e não pode ser alocada de novo." % [card.card_name, card.instance_id])

	# ENERGY.md, "Penalidade de Composição" — calculada ANTES de
	# sobrescrever army.commander/cards, enquanto "old_commander" e
	# "old_cards" ainda refletem a composição anterior.
	var commander_changed: bool = old_commander != new_commander
	var reuse_window: int = EnergyArmy.reuse_window_seconds(energy_nucleus_level)
	var any_recently_used_card: bool = false
	for card: CardResource in new_selected_cards:
		if old_cards.has(card):
			continue  # já estava neste Exército, não é "entrada" nenhuma
		if card.last_removed_from_army_unix != 0 and (now - card.last_removed_from_army_unix) < reuse_window:
			any_recently_used_card = true
			break

	if commander_changed and old_commander != null:
		army.current_energy = maxi(0, army.current_energy - EnergyArmy.commander_energy(CommanderCareer.patente_for_xp(old_commander.accumulated_xp)))
	if any_recently_used_card:
		var base: int = EnergyNucleus.energia_base(energy_nucleus_level)
		var commander_energy_now: int = EnergyArmy.commander_energy(CommanderCareer.patente_for_xp(new_commander.accumulated_xp))
		army.current_energy = mini(army.current_energy, base + commander_energy_now)

	new_commander.ownership_status = CommanderResource.OwnershipStatus.EM_EXERCITO
	for card: CardResource in new_selected_cards:
		card.ownership_status = CardResource.OwnershipStatus.EM_EXERCITO

	army.commander = new_commander
	army.cards = new_selected_cards
	# ARMY.md: recalcula a Energia Máxima de verdade sempre que a
	# composição muda — sem isso, o teto ficava travado no valor da
	# criação original do Exército, ignorando o novo Comandante/Cartas.
	army.recalculate_max_energy(energy_nucleus_level)

	# ARMY.md: as 5 Formações são regeneradas do zero — as antigas
	# podiam referenciar Cartas que não fazem mais parte do Exército.
	army.formations.clear()
	var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(new_selected_cards)
	for formation_name: String in archetypes:
		army.formations[formation_name] = archetypes[formation_name]


## Desfaz um Exército: libera o Comandante e todas as cartas (voltam a
## Livre) e o remove de Kingdom.armies. Não remove o Exército de nenhum
## ARMY.md, "Trava de Edição por Modo de Jogo": um Exército nunca pode
## ser editado (Comandante ou Cartas) enquanto está comprometido numa
## atividade em andamento — calculado sob demanda a partir do estado
## real (Expedições ativas, Minas), nunca cacheado num campo próprio,
## pra nunca ficar dessincronizado. Retorna {"locked": bool, "reason": String}.
func is_army_locked_for_editing(army: Army) -> Dictionary:
	for expedition: ExpeditionRuntime in active_expeditions:
		if expedition.squad.armies.has(army) and not expedition.is_waiting_at_acampamento and expedition.status == ExpeditionRuntime.Status.EM_ANDAMENTO:
			return {"locked": true, "reason": "Em Expedição — só pode ser editado no Acampamento ou de volta na Cidade."}

	for mina: Mina in all_mines():
		if mina.guarnicao_army == army and mina.is_cycle_active(GameClock.now_unix()):
			return {"locked": true, "reason": "Guarnição de Mina com Ciclo em andamento — só pode ser editado quando o Ciclo terminar."}

	return {"locked": false, "reason": ""}


## Squad que ainda o referencie — quem desfizer o Exército é
## responsável por também atualizar os Squads correspondentes.
func disband_army(army: Army) -> void:
	var lock: Dictionary = is_army_locked_for_editing(army)
	assert(not lock["locked"], "Kingdom.disband_army: %s" % lock["reason"])

	var now: int = GameClock.now_unix()
	if army.commander != null:
		army.commander.ownership_status = CommanderResource.OwnershipStatus.LIVRE
	for card: CardResource in army.cards:
		card.ownership_status = CardResource.OwnershipStatus.LIVRE
		# ENERGY.md, "Penalidade de Composição": sem isso, desfazer o
		# Exército em vez de editá-lo contornaria a Penalidade inteira
		# (as Cartas nunca ficariam marcadas como "recém-usadas").
		card.last_removed_from_army_unix = now
	armies.erase(army)


func add_army(army: Army) -> void:
	armies.append(army)


func add_squad(squad: Squad) -> void:
	squads.append(squad)


## Registra "expedition" como ativa. ARMY.md, "Trava de Edição por Modo
## de Jogo": um Exército já comprometido em outra Expedição em
## andamento (is_army_locked_for_editing()) nunca pode ser designado a
## uma segunda Expedição ao mesmo tempo — mesmo predicado usado por
## re_form_army()/disband_army(), nenhuma regra nova. Ponto central de
## entrada: quem inicia uma Expedição (painel de UI, GameRuntime, etc.)
## deve sempre passar por aqui, nunca alterar active_expeditions direto.
## Retorna {"success": bool, "reason": String} em vez de assert — ao
## contrário de re_form_army()/disband_army() (edição de um Exército já
## em jogo, erro de programação se a UI deixar passar), aqui a rejeição
## é um desfecho normal e esperável de uma ação do jogador (montar um
## Squad novo com um Exército já comprometido), então precisa de um
## retorno inspecionável — nunca derrubar a chamada.
func start_expedition(expedition: ExpeditionRuntime) -> Dictionary:
	for army: Army in expedition.squad.armies:
		var lock: Dictionary = is_army_locked_for_editing(army)
		if lock["locked"]:
			return {"success": false, "reason": lock["reason"]}

	active_expeditions.append(expedition)
	return {"success": true, "reason": ""}


func set_progress_flag(flag_name: String, value: bool = true) -> void:
	progress_flags[flag_name] = value


func has_progress_flag(flag_name: String) -> bool:
	return progress_flags.get(flag_name, false)
