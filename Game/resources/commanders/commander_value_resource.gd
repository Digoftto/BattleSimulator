class_name CommanderValueResource
extends Resource
## CommanderValueResource
##
## Representa uma entrada do Banco Oficial de Valores (COMMANDER_VALUES.md).
##
## effect_kind: vincula este Valor ao CommanderEffectResource.kind
##              correspondente (cada categoria de Valor possui sua própria
##              escala, conforme o documento).
## amount: intensidade numérica. Para Ataque/HP/Escudo/XP/Fragmentos/Recursos
##         é um percentual (ex: 0.20 = +20%). Para Soldo é um valor absoluto
##         de pontos (ex: 2 = +2). Para Afinidade é uma quantidade de cartas
##         (ex: 1 = +1 carta).
## is_percentage: true quando amount representa um percentual; false quando
##                representa um valor absoluto (Soldo) ou uma contagem
##                (Afinidade) — conforme "Regras Gerais" de COMMANDER_VALUES.md.

@export var code: String = ""
@export var description: String = ""
@export var frequency_label: String = ""

@export var effect_kind: String = ""
@export var amount: float = 0.0
@export var is_percentage: bool = true
