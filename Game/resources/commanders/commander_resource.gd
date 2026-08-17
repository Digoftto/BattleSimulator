class_name CommanderResource
extends Resource
## CommanderResource
##
## Representa o schema de dados da Identidade do Comandante, conforme
## COMMANDERS.md.
##
## Escopo implementado: Identidade — permanente e imutável (Sprint 4) e XP
## acumulado de Carreira Militar (Sprint 6, ver seção abaixo). Os campos
## desta classe NÃO incluem Doutrina Militar (Motor de Geração, tratada
## separadamente em CommanderDoctrine), nem Patente/Autoridade
## Militar/Histórico Militar/Estatísticas Históricas — esses pertencem a
## documentos e Sprints próprias (COMMAND_CENTER.md e derivados).

## --- Identidade (Permanente e Imutável) ---

## Identificador único deste Comandante específico — "o RG dele". 0 =
## ainda não pertence a nenhum Reino (ex: Comandante procedural gerado
## para um Exército inimigo, que nunca passa por Kingdom). Atribuído
## uma única vez por Kingdom.add_commander(), quando o Comandante
## realmente ingressa no Reino de um jogador (recrutamento, hoje).
@export var instance_id: int = 0

## Onde este Comandante está agora. Um Comandante só pode liderar um
## Exército por vez — nunca dois ao mesmo tempo (mesma regra já
## aplicada às Cartas).
enum OwnershipStatus { LIVRE, EM_EXERCITO }
@export var ownership_status: OwnershipStatus = OwnershipStatus.LIVRE

## Estado Administrativo (COMMAND_CENTER.md) — ciclo de vida do
## Comandante dentro do Reino. "Candidate" (pré-Reino) não é um valor
## deste enum: um Comandante só ganha um CommanderResource dentro de
## Kingdom.commanders quando já foi Comissionado (Kingdom.add_commander()),
## e nesse momento já entra direto em RESERVE — nunca existe uma
## instância "Candidate" real, esse estágio é representado inteiramente
## por RecruitmentOffer.commander, antes do Comissionamento.
## Transições só acontecem via CommandCenterResolver — nunca escritas
## diretamente aqui.
enum AdministrativeState { RESERVE, TRAINING, ACTIVE, RETIRED }
@export var administrative_state: AdministrativeState = AdministrativeState.RESERVE

## Nome próprio do comandante.
@export var commander_name: String = ""

## Expressão narrativa que individualiza o comandante. Finalidade
## exclusivamente narrativa.
@export var epithet: String = ""

## Reino ao qual o comandante foi originalmente vinculado. Registro
## permanente e histórico; nunca é alterado.
@export var home_kingdom: String = ""

## Reino pelo qual o comandante atualmente presta serviço.
@export var serving_kingdom: String = ""

## Facção de origem do comandante. Permanente; nunca alterada após a geração.
@export var faction: String = ""

## Doutrina Militar (COMMANDER_GENERATION.md) — Restrição, Requisito,
## Alvo, Efeito e Valor sorteados para este Comandante. null quando o
## Comandante não tem Doutrina nenhuma (ex: Kit Inicial do Reino,
## COMMAND_CENTER_RECRUITMENT.md — "Comandante em branco"). Não é
## @export porque CommanderDoctrine é RefCounted, não Resource — a
## persistência (save/load) reconstrói a partir dos códigos salvos
## (ver kingdom_save_service.gd).
var doctrine: CommanderDoctrine = null

## --- Carreira Militar (Progressiva) ---
##
## Escopo implementado (Sprint 6): apenas XP acumulado. A Patente é sempre
## derivada do XP através de CommanderCareer.patente_for_xp() — nunca
## armazenada separadamente, para impedir que fique dessincronizada do XP.
## As regras de obtenção e a tabela de progressão por Patente são definidas
## exclusivamente em XP.md (fonte única de verdade).
##
## Autoridade Militar e Histórico Militar (também parte da Carreira Militar
## em COMMANDERS.md) não são implementados nesta Sprint.

## XP acumulado permanentemente na carreira do comandante. Nunca é perdido.
@export var accumulated_xp: int = 0

## --- Treinamento (COMMAND_CENTER_TRAINING.md) ---

## XP acumulada no Ciclo de Treinamento ATUAL — ainda não incorporada
## à carreira (accumulated_xp). Só existe enquanto administrative_state
## == TRAINING. Descartada sem incorporar se o treinamento for
## cancelado antes do fim do Ciclo (10 dias); incorporada
## automaticamente ao final do Ciclo.
@export var training_accumulated_xp: int = 0

## Instante (Unix Timestamp) de início do Ciclo de Treinamento atual.
## 0 = não está em um Ciclo (fora do Estado TRAINING).
@export var training_cycle_started_unix: int = 0

## --- Ranking (RANKING.md) ---

## Liga Bronze (Modelo Individual): o próprio Comandante é o
## participante competitivo, com progressão própria — nunca
## compartilhada com outros Comandantes (RANKING.md, "Titularidade
## Competitiva"). "" = nunca se inscreveu na Liga Bronze.
@export var bronze_pl: int = 0
@export var bronze_divisao: String = ""

## --- Legado (COMMAND_CENTER_LEGACY.md) ---

## 0 = nunca foi registrado (não deveria acontecer para um Comandante
## dentro de Kingdom.commanders — só fica 0 em testes que não passam
## "now_unix" para Kingdom.add_commander()).
@export var commissioned_at_unix: int = 0

## 0 = ainda em serviço. Definido no momento da aposentadoria (Legado
## Administrativo ou Grande Legado Militar).
@export var retired_at_unix: int = 0

## "" = ainda em serviço. "Legado Administrativo" ou "Grande Legado
## Militar" — define o Tipo de Aposentadoria no Hall dos Comandantes.
@export var retirement_type: String = ""

## Descrição legível do benefício concedido ao se aposentar (ex: "+1
## Vaga de Treinamento (Legado II)", "+1 Atributo Vida para Natureza").
## "" se nenhum benefício foi concedido (Patente abaixo do mínimo de
## qualquer Legado, ou limite da Doutrina já atingido).
@export var retirement_benefit: String = ""

## Estatísticas de carreira, exibidas no Hall (COMMAND_CENTER_LEGACY.md,
## "Informações Registradas"). Nunca populadas automaticamente ainda —
## isso exige instrumentar CombatEngine/PhaseResolver para chamar
## record_battle_result(), o que pertence a uma integração futura com o
## fluxo real de jogo (mesma pendência já registrada para
## CommanderTrainingResolver.record_combat_xp()).
@export var total_battles: int = 0
@export var total_victories: int = 0
@export var total_draws: int = 0

## Últimas 20 batalhas (mais recente primeiro) — COMMANDERS.md,
## "Estatísticas Históricas". Cada entrada: {"opponent_name": String,
## "context": String (ex: "PvE — Fase 42", "Mina", "PvP"), "result":
## String ("Vitória"/"Derrota"/"Empate"), "timestamp_unix": int}.
const BATTLE_LOG_LIMIT: int = 20
@export var battle_log: Array[Dictionary] = []


## Registra o resultado de uma batalha nas Estatísticas do Comandante
## (resumo agregado + entrada no Histórico, FIFO de 20). Chamado por
## quem orquestra o combate (ex: PhaseResolver no PvE) — o Comandante
## nunca decide sozinho que uma batalha aconteceu.
## Guarda também as duas Formações (Posições 1-9, nomes das cartas)
## no momento da batalha — pra exibir o confronto 3x3 vs 3x3 no
## Histórico depois, não só o resultado em texto.
func record_battle(opponent_name: String, context: String, result: String, now_unix: int, own_formation: Array[CardResource] = [], enemy_formation: Array[CardResource] = []) -> void:
	total_battles += 1
	match result:
		"Vitória":
			total_victories += 1
		"Empate":
			total_draws += 1

	var own_card_names: Array[String] = []
	for card: CardResource in own_formation:
		own_card_names.append(card.card_name if card != null else "")
	var enemy_card_names: Array[String] = []
	for card: CardResource in enemy_formation:
		enemy_card_names.append(card.card_name if card != null else "")

	battle_log.push_front({
		"opponent_name": opponent_name,
		"context": context,
		"result": result,
		"timestamp_unix": now_unix,
		"own_formation": own_card_names,
		"enemy_formation": enemy_card_names,
	})
	if battle_log.size() > BATTLE_LOG_LIMIT:
		battle_log.resize(BATTLE_LOG_LIMIT)


func total_defeats() -> int:
	return total_battles - total_victories - total_draws

## Título honorífico opcional, sem efeito mecânico (lore). Nunca gerado
## automaticamente — fica disponível para quando houver conteúdo
## narrativo definindo os títulos.
@export var honorific_title: String = ""


func win_rate() -> float:
	if total_battles <= 0:
		return 0.0
	return float(total_victories) / float(total_battles)
