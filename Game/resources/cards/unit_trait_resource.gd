class_name UnitTraitResource
extends Resource
## UnitTraitResource
##
## Representa uma Característica de Unidade (Tier I), conforme
## CARD_CATALOG.md. Exclusiva da identidade de cada carta — nunca
## compartilhada entre cartas (diferente de AbilityResource, usado por
## Tier III/V, que É compartilhado).
##
## Uma Característica pode reaproveitar, na sua descrição, o mesmo nome
## e/ou mecânica de uma Ability já catalogada (ex: "Cura"), mas isso não
## as torna o mesmo recurso — permanecem dois catálogos independentes.
## Nenhuma referência entre os dois catálogos é modelada aqui: essa
## associação, quando existir, é responsabilidade futura do AbilitySystem
## (camada de runtime), não desta camada de dados.
##
## Apenas dados — nenhuma lógica.

@export var trait_name: String = ""

## Efeito base (Tier I), texto descritivo conforme CARD_CATALOG.md.
@export var base_effect_description: String = ""

## Efeito aprimorado quando a Afinidade III da Facção da carta está ativa
## ("Valores Aprimorados", ver AFFINITY.md Nível III). Vazio quando a
## carta/documentação não define uma variante aprimorada.
@export var enhanced_effect_description: String = ""
