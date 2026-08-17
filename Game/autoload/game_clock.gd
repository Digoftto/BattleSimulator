extends Node
## GameClock
##
## Relógio do Jogo: fonte única de referência de tempo real para todos
## os sistemas do Battle Simulator.
##
## Escopo desta entrega: apenas o contador em si, sempre ativo (autoload
## carregado desde o início da execução). Nenhum sistema de gameplay é
## ligado a ele ainda — nem recuperação de Energia (ENERGY_NUCLEUS.md),
## nem Ciclo de Mineração (MINES.md), nem expiração de Ofertas de
## Recrutamento (RecruitmentOffer.VALIDITY_DAYS). Cada uma dessas
## integrações é responsabilidade de uma Sprint própria, quando a regra
## de consumo específica for aprovada.
##
## Uso pelos sistemas (quando precisarem, futuramente):
## Um sistema que precisa medir tempo decorrido guarda o valor de
## GameClock.now_unix() no momento relevante (ex: início de um Ciclo de
## Mineração) e, mais tarde, compara com um novo GameClock.now_unix()
## para calcular quantos segundos se passaram. O Relógio nunca guarda
## esse estado por conta de outro sistema — ele só informa "que horas
## são agora".

## Retorna o instante atual em segundos, no padrão Unix Timestamp (UTC).
## Esta é a única fonte de tempo real que os sistemas do jogo devem
## usar — nunca ler Time.get_unix_time_from_system() diretamente em
## outro lugar, para manter um único ponto de verdade.
func now_unix() -> int:
	return int(Time.get_unix_time_from_system())


func _ready() -> void:
	print("[GameClock] Relógio do Jogo ativo. Referência inicial (Unix Timestamp): %d" % now_unix())
