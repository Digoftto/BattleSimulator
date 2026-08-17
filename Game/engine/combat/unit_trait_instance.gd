class_name UnitTraitInstance
extends RefCounted
## UnitTraitInstance
##
## Estrutura de runtime de uma Característica de Unidade (Tier I) durante
## uma batalha. Apenas referências — nenhuma lógica nesta Sprint.
##
## Ponto de extensão (Sprint futura): a maioria das Características de
## Unidade é de Consulta (condição contínua/posicional), não Reativa —
## ver análise da Sprint 19. O método de consulta (ex: query()) será
## adicionado quando a primeira Característica real for implementada,
## nunca antecipado aqui como interface vazia.

var resource: UnitTraitResource
var owner_unit: CombatUnit
var state: CombatState

## Referência ao Runtime desta Característica (ex: ReactiveTraitRuntime,
## ReviveRuntime), quando existir. Null enquanto a Característica
## permanecer sem comportamento implementado (ver UnitTraitRuntime).
## Tipo genérico (RefCounted): sem interface comum imposta entre
## Runtimes (mesma decisão já tomada para AbilityInstance, Sprint 19/20).
var specialized_runtime: RefCounted = null


func _init(p_resource: UnitTraitResource, p_owner_unit: CombatUnit, p_state: CombatState) -> void:
	resource = p_resource
	owner_unit = p_owner_unit
	state = p_state
