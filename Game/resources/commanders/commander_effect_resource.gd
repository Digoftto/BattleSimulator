class_name CommanderEffectResource
extends Resource
## CommanderEffectResource
##
## Representa uma entrada do Banco Oficial de Efeitos (COMMANDER_EFFECTS.md).
##
## category: "combat" | "progression" | "structural"
## kind: identifica o tipo específico de efeito, usado para selecionar o
##       sub-conjunto correspondente de CommanderValueResource na Etapa 7:
##       "attack" | "hp" | "shield" | "xp" | "fragments" | "resources" |
##       "soldo" | "affinity"

@export var code: String = ""
@export var description: String = ""
@export var frequency_label: String = ""

@export var category: String = ""
@export var kind: String = ""
