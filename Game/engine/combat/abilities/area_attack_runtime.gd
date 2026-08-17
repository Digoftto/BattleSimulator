class_name AreaAttackRuntime
extends RefCounted
## AreaAttackRuntime
##
## Runtime para Habilidades que, ao atacar, atingem também outras
## unidades na mesma Linha do alvo principal, com dano reduzido.
##
## Não reaproveita BonusAttackRuntime porque a mecânica é genuinamente
## diferente: aqui há múltiplos alvos simultâneos determinados pela
## Linha do alvo principal (não um único alvo recalculado), conforme a
## diretriz da Sprint 24 (criar Runtime exclusivo apenas quando houver
## diferença real de comportamento). Parametrizado para permitir reuso
## futuro por Habilidades semelhantes (ex: Corrente Elétrica).

var _instance: AbilityInstance
var _secondary_damage_percentage: float


func _init(p_instance: AbilityInstance, p_secondary_damage_percentage: float) -> void:
	_instance = p_instance
	_secondary_damage_percentage = p_secondary_damage_percentage


func get_subscriptions() -> Dictionary:
	return { CombatEventType.Type.AFTER_ATTACK: _on_after_attack }


func _on_after_attack(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker != _instance.owner_unit:
		return
	if _instance.owner_unit.silenced_until_turn >= context.turn:
		return

	var primary_target: CombatUnit = context.target
	if primary_target == null:
		return

	var line: Array = _line_of(primary_target.position)

	var damage: float = _instance.owner_unit.card.atk * _secondary_damage_percentage

	for position: int in line:
		if position == primary_target.position:
			continue
		var extra_target: CombatUnit = context.state.unit_at(primary_target.side, position)
		if extra_target == null or not extra_target.is_alive:
			continue
		AbilityDamageMath.apply(damage, extra_target)
		BattleLogger.trace("AreaAttackRuntime", "%s ('%s') também atinge %s | dano: %d%% do Ataque" % [
			_instance.owner_unit.card.card_name, _instance.resource.ability_name, extra_target.card.card_name, int(_secondary_damage_percentage * 100)
		])


static func _line_of(position: int) -> Array:
	if CombatBoard.LINE_1.has(position):
		return CombatBoard.LINE_1
	if CombatBoard.LINE_2.has(position):
		return CombatBoard.LINE_2
	return CombatBoard.LINE_3
