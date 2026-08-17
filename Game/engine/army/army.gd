class_name Army
extends RefCounted
## Army
##
## Representa a entidade Exército (ARMY.md): Identidade, Composição
## (1 Comandante + 9 Cartas) e Logística (Soldo e Energia, calculados por
## Soldo e EnergyArmy — lógica pura já implementada em Sprints anteriores).
##
## Escopo desta Sprint: Identidade, Composição, Logística, Validação da
## Formação e Disponibilidade. Não implementa Organização (posicionamento
## tático, pertence ao Sistema de Combate), Combate (aplicação da Doutrina
## Militar em batalha) ou Histórico (registro operacional — sem nenhum
## sistema ainda capaz de gerar esses eventos, permanece fora de escopo
## até a Sprint de Combate/Centro de Comando).

## Estados operacionais oficiais de Disponibilidade (ARMY.md).
## Disponibilidade do Exército para novas designações (Expedição, PvP,
## Guarnição de Mina). GUARNICAO_MINA (MINES.md, "Trava do Exército
## (Anti-Exploit)"): travado enquanto servir de Guarnição de um Ciclo
## de Mineração ativo — impede o exploit de trocar por uma composição
## mais eficiente no meio do ciclo.
enum Availability { AVAILABLE, IN_COMBAT, RECOVERING, GUARNICAO_MINA }

## Quantidade fixa de Pelotões Militares por Exército (Composição Fixa).
const REQUIRED_CARD_COUNT: int = 9

## --- Identidade ---
var kingdom_owner: String = ""  # Reino (Proprietário)
var army_name: String = ""      # Nome (Narrativo - Opcional)
var commander: CommanderResource

## --- Composição ---
var cards: Array[CardResource] = []

## Formações permanentes (ARMY.md): cada uma é uma disposição alternativa
## das MESMAS 9 cartas de "cards" — nenhuma carta nova, nenhum atributo
## alterado, apenas o posicionamento. Chave: nome da Formação ("α", "β",
## "γ", "δ", "ε"). Formações não configuradas usam "cards" como padrão
## (permite que um Exército funcione mesmo sem UI de configuração).
var formations: Dictionary = {}  # String -> Array[CardResource]

## Ordem de prioridade de uso das Formações, definida pelo jogador.
## Pertence ao Exército — nunca a uma Expedição ou Squad (ARMY.md).
var formation_priority: Array[String] = ["α", "β", "γ", "δ", "ε"]

## --- Disponibilidade ---
var availability: Availability = Availability.AVAILABLE

## --- Energia (ENERGY.md) ---
## "A energia pertence ao exército, nunca ao Reino." Máxima calculada
## por EnergyArmy.total_energy() a partir do nível do Núcleo de Energia
## do Reino (dado externo, nunca consultado diretamente por Army) e da
## própria composição/Comandante — por isso initialize_energy() recebe
## esses valores como parâmetro, em vez de buscá-los sozinho.
var max_energy: int = 0
var current_energy: int = 0

## Instante (Unix Timestamp) da última sincronização de recuperação de
## Energia por tempo real (ENERGY_NUCLEUS.md, "Eficiência Logística" +
## ENERGY.md, "Recuperação de Energia" — recupera na Cidade e em
## Acampamentos, nunca durante batalhas). 0 = nunca sincronizado; a
## primeira chamada de sync_energy_recovery() apenas estabelece essa
## referência, sem conceder recuperação retroativa por um período que
## este Exército não estava sendo rastreado pelo Relógio.
var last_energy_sync_unix: int = 0


## Calcula e define a Energia Total (máxima) deste Exército, e a
## define como Energia atual — chamado ao formar/campo o Exército,
## nunca durante uma batalha ("a energia nunca recupera durante
## batalhas", ENERGY.md). Reaproveita energy_total()/commander_patente()
## (já existentes nesta classe) em vez de recalcular a Patente.
func initialize_energy(energy_nucleus_level: int) -> void:
	max_energy = energy_total(energy_nucleus_level)
	current_energy = max_energy


## ARMY.md: "Sempre que a composição do exército for alterada (troca
## de comandante, substituição de cartas ou alteração do nível de
## Tier), a energia máxima será recalculada automaticamente." —
## diferente de initialize_energy(), NUNCA reseta a Energia atual pra
## cheia; só recalcula o teto e limita a atual pra baixo se ela agora
## ultrapassar o novo teto (nunca aumenta a atual só porque o teto subiu).
func recalculate_max_energy(energy_nucleus_level: int) -> void:
	max_energy = energy_total(energy_nucleus_level)
	current_energy = mini(current_energy, max_energy)


## True se o Exército possui Energia suficiente para mais uma tentativa.
func has_energy(amount: int) -> bool:
	return current_energy >= amount


## Consome Energia do Exército (nunca abaixo de zero).
func consume_energy(amount: int) -> void:
	current_energy = maxi(current_energy - amount, 0)


## Recupera a Energia do Exército para 100% da sua Energia Máxima
## (ENERGY.md, "Recuperação em Acampamentos"). Nunca ocorre durante uma
## batalha — só é chamado por ExpeditionRuntime ao aplicar a Política
## de Acampamento.
func recover_energy_full() -> void:
	current_energy = max_energy
	last_energy_sync_unix = 0  # próxima sync não deve tratar este salto como recuperação gradual


## Sincroniza a recuperação de Energia por tempo real decorrido, desde
## a última sincronização, à taxa definida pelo Núcleo de Energia
## (ENERGY_NUCLEUS.md, "Eficiência Logística": 1 ponto a cada N
## segundos, conforme o nível do Núcleo).
##
## Pura e determinística: recebe "now_unix" (GameClock.now_unix(),
## fornecido por quem chama — Army nunca lê o relógio sozinho) e o
## nível do Núcleo (mesmo padrão já usado por energy_total()).
##
## Preserva progresso parcial: se o tempo decorrido não completa nem 1
## ponto de recuperação, nenhum ponto é concedido e o "resto" de
## segundos não é perdido — permanece contando para a próxima chamada.
##
## Responsabilidade de QUANDO chamar (Cidade vs. Acampamento vs. nunca
## durante combate) pertence a quem orquestra o Exército — esta função
## apenas calcula, nunca decide se é o momento certo de recuperar.
func sync_energy_recovery(now_unix: int, energy_nucleus_level: int) -> void:
	if last_energy_sync_unix == 0:
		last_energy_sync_unix = now_unix
		return

	if current_energy >= max_energy:
		last_energy_sync_unix = now_unix
		return

	var elapsed_seconds: int = now_unix - last_energy_sync_unix
	if elapsed_seconds <= 0:
		return

	var seconds_per_point: int = EnergyNucleus.recovery_seconds(energy_nucleus_level)
	@warning_ignore("integer_division")  # Divisão inteira intencional: só pontos completos recuperam.
	var points_recovered: int = elapsed_seconds / seconds_per_point
	if points_recovered <= 0:
		return

	current_energy = mini(current_energy + points_recovered, max_energy)

	if current_energy >= max_energy:
		last_energy_sync_unix = now_unix
	else:
		last_energy_sync_unix += points_recovered * seconds_per_point


## Retorna a disposição de cartas da Formação solicitada. Cai de volta
## para "cards" (a disposição padrão) se a Formação não foi configurada.
func get_formation(formation_name: String) -> Array[CardResource]:
	if formations.has(formation_name):
		return formations[formation_name]
	return cards


## Retorna a Patente atual do comandante designado, derivada do seu XP
## acumulado (CommanderCareer é a SSOT de Patente).
func commander_patente() -> String:
	assert(commander != null, "Army: nenhum Comandante designado.")
	return CommanderCareer.patente_for_xp(commander.accumulated_xp)


## Validação da Formação: um Exército possui exatamente 9 Pelotões alocados.
func is_formation_complete() -> bool:
	return cards.size() == REQUIRED_CARD_COUNT


## Soldo Total do Exército: soma do custo de Soldo das 9 cartas alocadas
## (SOLDO.md — SSOT). O Comandante não possui custo próprio de Soldo.
func soldo_total() -> int:
	return Soldo.total_for_composition(cards)


## Retorna true se o Soldo Total não excede o teto da Patente do
## comandante — ou o teto de "Recruta" (18, o mais baixo) se o
## Exército não tem Comandante, caso válido para "Fases Normais"
## (PvE.md, "Hierarquia e Composição dos Combates": "Possui
## Comandante? Não") — a mesma convenção que EnemyArmyGenerator já
## usa ao MONTAR essas composições, antes mesmo de existir um
## Comandante pra consultar.
func is_soldo_within_cap() -> bool:
	var patente: String = commander_patente() if commander != null else "Recruta"
	return Soldo.is_composition_within_cap(cards, patente)


## Energia Total do Exército (ENERGY.md), a partir do nível do Núcleo de
## Energia do Reino, da Patente do comandante e do Tier das cartas.
func energy_total(nucleus_level: int) -> int:
	return EnergyArmy.total_energy(nucleus_level, commander_patente(), cards)


## Um Exército está pronto para batalha quando a Formação está completa e
## o Soldo Total está dentro do teto da Patente do comandante.
func is_ready_for_battle() -> bool:
	return is_formation_complete() and is_soldo_within_cap()
