class_name CommanderRequirementResource
extends Resource
## CommanderRequirementResource
##
## Representa uma entrada do Banco Oficial de Requisitos (COMMANDER_REQUIREMENTS.md).
##
## Ver CommanderRestrictionResource para a justificativa dos campos
## estruturados (domain/operator/quantity/scope).
##
## domain: "faction" | "class" | "battlefield" | "unit_state" | "army_state" | "game_mode"
## operator: "min" | "during" | "state_hp_leq" | "state_shield_eq" | "army_size_leq" | "exclusive"
## quantity: limiar numérico (quantidade de lacaios, percentual de HP, ou tamanho de exército; 0 quando não se aplica)
## scope: "self" (mesma facção) | "specific" (classe ou campo de batalha especificados) |
##        "pvp" | "pve" | "mines" (modo de jogo fixo) | "" (não se aplica)

@export var code: String = ""
@export var description: String = ""
@export var frequency_label: String = ""

@export var domain: String = ""
@export var operator: String = ""
@export var quantity: int = 0
@export var scope: String = ""
