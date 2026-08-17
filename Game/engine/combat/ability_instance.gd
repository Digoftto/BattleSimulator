class_name AbilityInstance
extends RefCounted
## AbilityInstance
##
## Estrutura de runtime de uma Habilidade (Tier III ou V) durante uma
## batalha. Apenas referências — nenhuma lógica nesta Sprint.
##
## Ponto de extensão (Sprint 21+): cada Habilidade concreta terá seu
## próprio Runtime especializado (ex: RegeneracaoRuntime,
## ContraAtaqueRuntime), responsável por informar subscribed_events(),
## can_trigger() e execute(). Essa informação pertence ao Runtime de cada
## Habilidade, nunca a um catálogo/tabela externa de tradução
## Gatilho->Evento (decisão arquitetural desta Sprint).

var resource: AbilityResource
var owner_unit: CombatUnit
var state: CombatState

## Referência ao Runtime especializado desta Habilidade (ex:
## InvestidaRuntime), quando existir. Null enquanto a Habilidade
## permanecer sem comportamento implementado (ver AbilityRuntime).
## Tipo genérico (RefCounted): AbilityInstance não impõe nenhuma
## interface comum entre Runtimes especializados — cada um tem seu
## próprio contrato (decisão da Sprint 19/20: sem herança artificial).
var specialized_runtime: RefCounted = null


func _init(p_resource: AbilityResource, p_owner_unit: CombatUnit, p_state: CombatState) -> void:
	resource = p_resource
	owner_unit = p_owner_unit
	state = p_state
