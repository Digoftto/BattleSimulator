class_name CommanderRestrictionResource
extends Resource
## CommanderRestrictionResource
##
## Representa uma entrada do Banco Oficial de Restrições (COMMANDER_RESTRICTIONS.md).
##
## Além do texto de catálogo (code/description/frequency_label), os campos
## estruturados abaixo (domain/operator/quantity/scope) codificam fielmente
## a mesma regra em forma computável, para permitir que CommanderGenerator
## aplique a Regra Oficial de Compatibilidade ("uma Restrição nunca pode
## impedir que seu próprio Requisito seja satisfeito") de forma genérica,
## sem enumerar manualmente cada par Restrição x Requisito.
##
## domain: "faction" | "class" | "battlefield" | "game_mode" | "affinity"
## operator: "max" | "min" | "required" | "forbidden" | "only_standard" | "exclusive" | "extra_cost"
## quantity: limiar numérico (0 quando não se aplica)
## scope: "self" (mesma facção) | "other" (facção especificada, diferente da do comandante) |
##        "specific" (classe ou campo de batalha especificados em tempo de geração) |
##        "pvp" | "pve" | "mines" (modo de jogo fixo) | "" (não se aplica)

@export var code: String = ""
@export var description: String = ""
@export var frequency_label: String = ""

@export var domain: String = ""
@export var operator: String = ""
@export var quantity: int = 0
@export var scope: String = ""
