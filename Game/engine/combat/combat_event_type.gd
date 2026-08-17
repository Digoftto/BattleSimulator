class_name CombatEventType
extends RefCounted
## CombatEventType
##
## Enumeração tipada de todos os eventos oficiais do Motor de Combate.
## Nenhum evento é representado por String — apenas por este tipo, para
## evitar erros de digitação e acoplamento por texto entre CombatEngine e
## futuros ouvintes (Habilidades).

enum Type {
	BATTLE_START,
	TURN_START,
	TURN_END,
	ACTION_SELECTED,
	UNIT_MOVED,
	BEFORE_ATTACK,
	AFTER_ATTACK,
	BEFORE_DAMAGE,
	AFTER_DAMAGE_DEALT,
	AFTER_DAMAGE_TAKEN,
	BEFORE_HEAL,
	AFTER_HEAL_PERFORMED,
	AFTER_HEAL_RECEIVED,
	UNIT_DIED,
}
