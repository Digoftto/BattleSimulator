extends Node
## BattleLogger (Autoload)
##
## Controle central de verbosidade do console. Importante porque o
## Battle Simulator roda milhares de simulações de combate em teste
## (Ciclo de Mineração sozinho: até 362.880), e cada uma gera dezenas
## de linhas de log interno (AbilityRuntime, ReactiveTraitRuntime,
## CombatEventBus etc.) — em volume, isso estoura o buffer de Output
## do Editor Godot antes mesmo do resultado das validações aparecer.
##
## Um único ponto controla tudo — nunca "if VERBOSE:" espalhado pelo
## código. Cada chamada recebe uma "source" (o antigo prefixo "[Tag]")
## separada da mensagem, para permitir filtro futuro por sistema
## (Combat, Campaign, Academy...) sem precisar mexer nos call sites de
## novo quando isso for implementado.

enum Level { NONE, ERR, INFO, DEBUG, TRACE }

## Nível atual. TRACE = tudo (combate passo a passo, о mais verboso);
## DEBUG = informação útil de depuração; INFO = resultado das
## validações (esperado: X); ERR = só erros; NONE = silêncio total.
## Padrão: INFO — visível o suficiente pra ver o resultado dos testes,
## sem o ruído de combate turno a turno.
var current_level: Level = Level.INFO


func set_level(level: Level) -> void:
	current_level = level


func error(source: String, message: String) -> void:
	if current_level >= Level.ERR:
		print("[%s] %s" % [source, message])


func info(source: String, message: String) -> void:
	if current_level >= Level.INFO:
		print("[%s] %s" % [source, message])


func debug(source: String, message: String) -> void:
	if current_level >= Level.DEBUG:
		print("[%s] %s" % [source, message])


func trace(source: String, message: String) -> void:
	if current_level >= Level.TRACE:
		print("[%s] %s" % [source, message])
