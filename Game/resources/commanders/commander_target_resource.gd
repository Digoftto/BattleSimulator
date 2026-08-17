class_name CommanderTargetResource
extends Resource
## CommanderTargetResource
##
## Representa uma entrada do Banco Oficial de Alvos (COMMANDER_TARGETS.md).
##
## group: "permanent" | "dynamic" (conforme a própria divisão do documento)
## category: "faction" | "class" | "formation"
## value: valor específico do alvo dentro da categoria (ex: "Melee", "Linha 2").
##        Vazio para a categoria "faction", que sempre se refere à mesma
##        Facção do comandante (nunca especificada diretamente).

@export var code: String = ""
@export var description: String = ""
@export var frequency_label: String = ""

@export var group: String = ""
@export var category: String = ""
@export var value: String = ""
