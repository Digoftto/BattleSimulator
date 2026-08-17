class_name AffinityLevelResource
extends Resource
## AffinityLevelResource
##
## Representa o efeito de um Nível de Afinidade para uma Facção específica
## (AFFINITY.md, "Efeitos Específicos por Facção"). Dado puramente
## descritivo — a aplicação prática desses efeitos durante uma batalha é
## responsabilidade futura de COMBAT_RULES.md, fora do escopo desta Sprint.
##
## O requisito de Pontos de Afinidade para cada Nível (2/4/7) é uma regra
## única e compartilhada por todas as Facções (ver Affinity.POINTS_BY_LEVEL)
## — por isso não é duplicado aqui, para não replicar a mesma regra em
## dois lugares.

@export var faction: String = ""

## Nível de Afinidade: 1, 2 ou 3.
@export var level: int = 0

## Texto descritivo do efeito concedido neste Nível, para esta Facção.
@export var effect_description: String = ""
