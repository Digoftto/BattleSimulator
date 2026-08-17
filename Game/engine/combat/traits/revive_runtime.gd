class_name ReviveRuntime
extends RefCounted
## ReviveRuntime
##
## Runtime de "Reerguer": na primeira vez que o pelotão for destruído
## durante a batalha, retorna ao campo (mesma posição) com uma fração do
## HP Base.
##
## Mecânica genuinamente distinta de ReactiveTraitRuntime: reviver muda
## is_alive e reage a UNIT_DIED (publicado dentro da própria Resolução
## das Mortes, COMBAT_RULES.md) — não é "aplicar dano/cura a um alvo",
## é reverter o próprio evento de morte que acabou de ocorrer.
##
## Observação de implementação (não corrige CombatEngine, apenas
## registra): ao reagir dentro do mesmo laço que já registrou a unidade
## em state.eliminated_units, essa lista mantém um registro cosmético da
## eliminação mesmo após o reerguimento — não afeta condições de vitória
## (que verificam CombatUnit.is_alive, já revertido antes da checagem).

var _instance: UnitTraitInstance
var _hp_fraction: float
var _consumed: bool = false


func _init(p_instance: UnitTraitInstance, p_hp_fraction: float) -> void:
	_instance = p_instance
	_hp_fraction = p_hp_fraction


func get_subscriptions() -> Dictionary:
	return { CombatEventType.Type.UNIT_DIED: _on_unit_died }


func _on_unit_died(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _consumed:
		return
	if context.attacker != _instance.owner_unit:
		return

	var owner: CombatUnit = _instance.owner_unit
	owner.is_alive = true
	owner.current_hp = maxi(int(round(owner.card.hp * _hp_fraction)), 1)
	_consumed = true

	BattleLogger.trace("ReviveRuntime", "%s foi reerguido com %d HP (posição %d)." % [owner.card.card_name, owner.current_hp, owner.position])


func is_consumed() -> bool:
	return _consumed
