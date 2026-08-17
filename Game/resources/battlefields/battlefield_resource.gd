class_name BattlefieldResource
extends Resource
## BattlefieldResource
##
## Representa um Campo de Batalha (BATTLEFIELDS.md): dados puros, sem
## nenhum comportamento. O texto de "effect" é armazenado exclusivamente
## como dado descritivo — sua interpretação e aplicação em combate são
## responsabilidade futura de COMBAT_CORE.md/COMBAT_RULES.md, fora do
## escopo desta Sprint.

@export var battlefield_name: String = ""

## Categoria documental: "Padrão" | "Climático" | "Geográfico" | "Místico".
@export var category: String = ""

## Conceito narrativo do ambiente.
@export var description: String = ""

## Modificador mecânico do Campo, como texto descritivo (sem comportamento).
@export var effect: String = ""

## Probabilidade de ocorrência, em pontos percentuais inteiros (ex: 64 = 64%).
@export var frequency_percent: float = 0.0
