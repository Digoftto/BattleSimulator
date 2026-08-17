class_name ExpeditionSession
extends RefCounted
## ExpeditionSession
##
## O primeiro consumidor real de ExpeditionRuntime fora de bootstrap.gd:
## executa uma Expedição do início até CONCLUIDA/ENCERRADA, ou até ela
## ficar parada aguardando uma decisão do jogador (Política de
## Acampamento AGUARDAR_ORDEM).
##
## Deliberadamente síncrono — sem Timer, sem execução assíncrona, sem
## "1 minuto por ação" (PvE.md, "Ritmo da Expedição"). Essa é uma
## decisão de escopo, não uma omissão: Tempo Real muda a natureza do
## código do projeto inteiro (de entrada->processamento->resultado para
## espera->evento->concorrência) e só compensa introduzir quando existir
## algo real do outro lado esperando por isso (uma sessão de jogo
## de verdade, não apenas mais um orquestrador síncrono). Até lá,
## ExpeditionSession já resolve o problema de "quem liga os fios" sem
## pagar esse custo.
##
## Responsabilidade única: repetir "tentar a Fase atual" até um de três
## desfechos — a Expedição terminar, ela precisar de uma decisão do
## jogador, ou um limite de segurança ser atingido (proteção contra loop
## infinito por erro de configuração, nunca esperado em uso normal).
## ExpeditionSession nunca decide por conta própria retomar uma
## Expedição parada aguardando o jogador — isso seria inventar uma
## decisão que ninguém tomou.
##
## RewardResolver e Recrutamento, quando existirem, são consumidores
## deste loop (lendo o PhaseResult a cada passo, ou observando o log),
## não responsabilidades desta classe.

enum StopReason { CONCLUIDA, ENCERRADA, AGUARDANDO_JOGADOR, LIMITE_DE_SEGURANCA }

## Bem acima de 9.000 Fases reais de uma Trilha — existe apenas como
## proteção contra loop infinito por erro de configuração, nunca
## esperado em uso normal.
const DEFAULT_SAFETY_LIMIT: int = 20000


## Executa "expedition" até um dos três desfechos possíveis. Retorna o
## motivo da parada.
static func run(expedition: ExpeditionRuntime, safety_limit: int = DEFAULT_SAFETY_LIMIT) -> StopReason:
	var attempts: int = 0

	while attempts < safety_limit:
		if expedition.status == ExpeditionRuntime.Status.CONCLUIDA:
			return StopReason.CONCLUIDA
		if expedition.status == ExpeditionRuntime.Status.ENCERRADA:
			return StopReason.ENCERRADA
		if expedition.is_waiting_at_acampamento:
			return StopReason.AGUARDANDO_JOGADOR

		expedition.attempt_current_fase()
		attempts += 1

	return StopReason.LIMITE_DE_SEGURANCA
