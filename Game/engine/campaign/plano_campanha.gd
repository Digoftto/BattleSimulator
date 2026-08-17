class_name PlanoCampanha
extends RefCounted
## PlanoCampanha (COMMAND_CENTER.md, "Plano de Campanha")
##
## Até 3 Exércitos vinculados, com o mapeamento dos 9 Campos de
## Batalha Especiais (exclusivo, um dono cada), o Exército de Defesa
## Preferencial pro Campo Aberto (único compartilhável) e a Ordem de
## Ataque entre eles (desempate só relevante pro Campo Aberto).
##
## Dados puros — nenhuma validação aqui. PlanoCampanhaResolver decide
## e efetiva; PlanoCampanha só guarda o resultado.

var armies: Array[Army] = []

## battlefield_name (Especial) -> índice do Exército dono (0, 1 ou 2).
## Um Campo Especial nunca tem mais de um dono.
var battlefield_mapping: Dictionary = {}

## Índice do Exército de Defesa Preferencial pro Campo Aberto. -1 =
## ainda não definido.
var defesa_preferencial_index: int = -1

## Ordem em que os Exércitos assumem o Campo Aberto quando mais de um
## está apto ao mesmo tempo (por energia) — array de índices (0/1/2).
var ordem_de_ataque: Array[int] = []

## --- Ranking (RANKING.md) ---

## Nas Ligas Prata/Ouro/Diamante, o Plano de Campanha inteiro (não
## cada Comandante) é o participante competitivo (RANKING.md,
## "Titularidade Competitiva"). "liga" = "Prata"/"Ouro"/"Diamante" —
## "" antes de inscrito.
var liga: String = ""
var pl: int = 0
var divisao: String = ""


func _init(p_armies: Array[Army]) -> void:
	armies = p_armies
	for i in range(armies.size()):
		ordem_de_ataque.append(i)
