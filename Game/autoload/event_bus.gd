extends Node
## EventBus
##
## Barramento global de sinais utilizado para desacoplar sistemas entre si.
## Nesta Sprint (Bootstrap), expõe apenas os sinais necessários para
## comunicar o progresso da inicialização da engine.
##
## Novos sinais de domínio (combate, economia, progressão, etc.) devem ser
## adicionados aqui somente quando existir uma responsabilidade real
## atribuída durante a Sprint correspondente.

## Os sinais abaixo são emitidos por outros scripts (GameDatabase,
## KingdomState, Bootstrap), não pela própria EventBus — por isso o
## analisador do GDScript os marca como "não usados" localmente. Uso
## legítimo do padrão de barramento de sinais; aviso suprimido de propósito.
@warning_ignore("unused_signal")
signal database_loaded
@warning_ignore("unused_signal")
signal kingdom_initialized
@warning_ignore("unused_signal")
signal engine_ready
