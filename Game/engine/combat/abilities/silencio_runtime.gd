class_name SilencioRuntime
extends RefCounted
## SilencioRuntime
##
## No início do turno, sorteia uma unidade inimiga viva e a silencia por
## 1 turno. "Silenciar" é implementado como um campo em CombatUnit
## (silenced_until_turn), consultado por cada Runtime de Habilidade antes
## de agir — o CombatEventBus/CombatEngine permanecem completamente
## agnósticos dessa regra (decisão já registrada nas Sprints 16/17/19:
## quem verifica Silêncio é cada Habilidade, nunca o barramento).

var _instance: AbilityInstance


func _init(p_instance: AbilityInstance) -> void:
	_instance = p_instance


func get_subscriptions() -> Dictionary:
	return { CombatEventType.Type.TURN_START: _on_turn_start }


func _on_turn_start(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if not _instance.owner_unit.is_alive:
		return

	var enemy_side: int = 1 - _instance.owner_unit.side
	var candidates: Array[CombatUnit] = context.state.units_of_side(enemy_side, true)
	if candidates.is_empty():
		return

	var target: CombatUnit = candidates[context.state.rng.randi() % candidates.size()]
	target.silenced_until_turn = context.turn
	BattleLogger.trace("SilencioRuntime", "%s silencia %s até o final do Turno %d" % [
		_instance.owner_unit.card.card_name, target.card.card_name, context.turn
	])
