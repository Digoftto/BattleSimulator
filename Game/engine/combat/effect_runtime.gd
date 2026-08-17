class_name EffectRuntime
extends RefCounted
## EffectRuntime
##
## Componente que coordena todo o Runtime de efeitos de uma batalha
## (AbilityRuntime + UnitTraitRuntime). O CombatEngine interage
## exclusivamente com esta fachada — nunca diretamente com os dois
## Runtimes especializados por baixo.
##
## Não implementa nenhuma mecânica de Habilidade ou Característica de
## Unidade. Apenas resolve, instancia e disponibiliza consulta.

var _ability_runtime: AbilityRuntime
var _unit_trait_runtime: UnitTraitRuntime


## Cria e inicializa os Runtimes especializados para todas as CombatUnit
## do state, a partir dos catálogos já carregados por GameDatabase.
func initialize(state: CombatState, abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource]) -> void:
	_ability_runtime = AbilityRuntime.new()
	_ability_runtime.initialize(state, abilities_by_name)

	_unit_trait_runtime = UnitTraitRuntime.new()
	_unit_trait_runtime.initialize(state, unit_traits)


## Libera as referências dos Runtimes especializados. O ciclo de vida
## normal já termina junto ao CombatState (descarte, sem necessidade de
## chamada manual) — este método existe para permitir encerramento
## explícito quando necessário (ex: validação/depuração).
func shutdown() -> void:
	_ability_runtime = null
	_unit_trait_runtime = null


## Retorna a UnitTraitInstance (Tier I) de uma unidade, ou null.
func get_unit_trait(unit: CombatUnit) -> UnitTraitInstance:
	return _unit_trait_runtime.get_instance(unit)


## Retorna as AbilityInstance (Tier III/V) de uma unidade (lista vazia
## se não possuir nenhuma).
func get_abilities(unit: CombatUnit) -> Array[AbilityInstance]:
	return _ability_runtime.get_instances(unit)
