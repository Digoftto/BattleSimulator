class_name CommanderDoctrine
extends RefCounted
## CommanderDoctrine
##
## Representa o resultado de uma execução do Fluxo Oficial de Geração
## (COMMANDER_GENERATION.md): a combinação completa de Facção, Restrição,
## Requisito, Alvo, Efeito e Valor sorteados para um comandante, além do
## Rarity Score calculado na Etapa 8.
##
## Este objeto é puramente um resultado de dados — não pertence à
## Identidade do Comandante (CommanderResource) nem participa de gameplay
## nesta Sprint.

var faction: String = ""

var restriction: CommanderRestrictionResource
var restriction_param: String = ""

var requirement: CommanderRequirementResource
var requirement_param: String = ""

var target: CommanderTargetResource

var effect: CommanderEffectResource

var value: CommanderValueResource

## Soma dos Pesos de Frequência dos 5 componentes sorteados (Etapa 8).
## Métrica interna do motor; sua conversão em Raridade Final (Comum, Rara,
## Épica, Lendária) é objeto de balanceamento futuro (ver COMMANDER_GENERATION.md).
var rarity_score: int = 0


## Descrição textual da Restrição, incluindo o parâmetro sorteado (quando houver).
func restriction_description() -> String:
	if restriction_param != "":
		return "%s (%s)" % [restriction.description, restriction_param]
	return restriction.description


## Descrição textual do Requisito, incluindo o parâmetro sorteado (quando houver).
func requirement_description() -> String:
	if requirement_param != "":
		return "%s (%s)" % [requirement.description, requirement_param]
	return requirement.description


## Descrição textual do Valor, formatada conforme percentual ou valor absoluto.
func value_description() -> String:
	if value.is_percentage:
		return "+%d%%" % int(round(value.amount * 100.0))
	return "+%d" % int(value.amount)
