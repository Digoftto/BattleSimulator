class_name DefensiveModifierRuntime
extends RefCounted
## DefensiveModifierRuntime
##
## Runtime genérico para Habilidades que modificam o dano recebido antes
## de sua aplicação (BEFORE_DAMAGE), escrevendo o novo valor de volta em
## CombatContext.attack_value — a mesma convenção de contexto mutável já
## estabelecida na Sprint 21 (Investida), agora do lado do defensor em
## vez do atacante.
##
## Reutilizado por Campo de Força, Sobrevivência e Perfuração (Sprint 24)
## — as três modificam o dano recebido antes da aplicação; diferem
## apenas na fórmula (anular, limitar a 1 HP, dividir com Escudo) e se
## consomem uma única vez ou não. Diretriz oficial da Sprint 24:
## diferença de nome/fórmula não justifica, sozinha, uma nova classe
## enquanto a estrutura do comportamento for a mesma.

var _instance: AbilityInstance
var _one_shot: bool
var _consumed: bool = false

## func(attack_value: float, owner: CombatUnit) -> Variant
## Retorna o novo valor de "attack_value" (float), ou null se a condição
## não se aplica a este evento. Pode, como efeito colateral, mutar
## diretamente campos de "owner" (ex: Perfuração aplicando dano ao
## Escudo/HP diretamente e devolvendo 0 para zerar o restante).
var _modifier: Callable


func _init(p_instance: AbilityInstance, p_one_shot: bool, p_modifier: Callable) -> void:
	_instance = p_instance
	_one_shot = p_one_shot
	_modifier = p_modifier


func get_subscriptions() -> Dictionary:
	return { CombatEventType.Type.BEFORE_DAMAGE: _on_before_damage }


func _on_before_damage(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _consumed:
		return
	if context.target != _instance.owner_unit:
		return
	if _instance.owner_unit.silenced_until_turn >= context.turn:
		return

	var result: Variant = _modifier.call(context.attack_value, _instance.owner_unit)
	if result == null:
		return

	context.attack_value = float(result)
	if _one_shot:
		_consumed = true

	BattleLogger.trace("DefensiveModifierRuntime", "%s ativa '%s' | novo valor de dano recebido: %s" % [
		_instance.owner_unit.card.card_name, _instance.resource.ability_name, str(result)
	])


func is_consumed() -> bool:
	return _consumed
