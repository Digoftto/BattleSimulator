class_name BonusAttackRuntime
extends RefCounted
## BonusAttackRuntime
##
## Runtime genérico para Habilidades que executam um ataque adicional
## completo contra um alvo determinado por um seletor, ao ocorrer um
## evento de combate.
##
## Reutilizado por Ataque Duplo e Contra-ataque (Sprint 24) — nenhuma
## classe exclusiva foi criada para elas, pois ambas compartilham a
## mesma estrutura ("mais um ataque, contra alguém, por X% do Ataque"),
## diferindo apenas em qual evento dispara e quem é o alvo. Diretriz
## oficial da Sprint 24: diferença de nome não justifica nova classe.

var _instance: AbilityInstance
var _trigger_event: CombatEventType.Type
var _damage_percentage: float

## func(context: CombatContext, owner: CombatUnit) -> CombatUnit (ou null
## se este evento não for relevante para esta instância).
var _target_selector: Callable


func _init(p_instance: AbilityInstance, p_trigger_event: CombatEventType.Type, p_damage_percentage: float, p_target_selector: Callable) -> void:
	_instance = p_instance
	_trigger_event = p_trigger_event
	_damage_percentage = p_damage_percentage
	_target_selector = p_target_selector


func get_subscriptions() -> Dictionary:
	return { _trigger_event: _on_trigger }


func _on_trigger(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _instance.owner_unit.silenced_until_turn >= context.turn:
		return

	var target: CombatUnit = _target_selector.call(context, _instance.owner_unit)
	if target == null or not target.is_alive:
		return

	var damage: float = _instance.owner_unit.card.atk * _damage_percentage
	AbilityDamageMath.apply(damage, target)
	BattleLogger.trace("BonusAttackRuntime", "%s ativa '%s' contra %s | dano: %d%% do Ataque" % [
		_instance.owner_unit.card.card_name, _instance.resource.ability_name, target.card.card_name, int(_damage_percentage * 100)
	])
