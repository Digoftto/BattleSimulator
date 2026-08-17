class_name InvestidaRuntime
extends RefCounted
## InvestidaRuntime
##
## Runtime especializado da Habilidade "Investida" (ABILITIES.md, Tier V):
## "Primeiro ataque realizado após entrar na Linha 1" concede +200% de
## Ataque nesse ataque. Ativação única por batalha.
##
## Primeira Habilidade Modificadora implementada no projeto — valida a
## convenção de contexto mutável definida na Sprint 19: o CombatEngine
## calcula um valor provisório de Ataque, publica BEFORE_ATTACK, e este
## Runtime escreve o valor final de volta no CombatContext antes da
## aplicação do dano (que continua sendo responsabilidade exclusiva do
## CombatEngine).
##
## Duas responsabilidades claramente separadas em dois métodos distintos:
## - _on_unit_moved: apenas detecta a entrada na Linha 1.
## - _on_before_attack: apenas verifica a condição, modifica o contexto e
##   consome a habilidade.
##
## Nenhum outro estado além do estritamente necessário. Sem cooldown,
## duração, pilhas ou infraestrutura genérica.

## +200% de Ataque = multiplicador final de 3x sobre o Ataque efetivo.
const ATTACK_MULTIPLIER: float = 3.0

var _instance: AbilityInstance
var _entered_frontline: bool = false
var _consumed: bool = false


func _init(p_instance: AbilityInstance) -> void:
	_instance = p_instance


## Mapa evento -> ouvinte, usado por AbilityRuntime para o registro
## automático no CombatEventBus. Cada evento aponta para um método
## próprio — nenhuma responsabilidade é misturada em um único método.
func get_subscriptions() -> Dictionary:
	return {
		CombatEventType.Type.UNIT_MOVED: _on_unit_moved,
		CombatEventType.Type.BEFORE_ATTACK: _on_before_attack,
	}


## Responsabilidade única: detectar a primeira entrada na Linha 1 do
## pelotão dono desta instância. Nenhuma modificação de contexto aqui.
func _on_unit_moved(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _consumed or _entered_frontline:
		return
	if context.attacker != _instance.owner_unit:
		return
	if not CombatBoard.is_line_1(context.position):
		return

	_entered_frontline = true
	BattleLogger.trace("InvestidaRuntime", "%s entrou na Linha 1 (posição %d)." % [_instance.owner_unit.card.card_name, context.position])


## Responsabilidade única: verificar a condição, modificar o
## CombatContext e consumir a habilidade. Nenhuma detecção de
## posicionamento aqui.
func _on_before_attack(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _consumed or not _entered_frontline:
		return
	if context.attacker != _instance.owner_unit:
		return

	context.attack_value *= ATTACK_MULTIPLIER
	_consumed = true
	BattleLogger.trace("CombatEventBus", "BEFORE_ATTACK -> Investida -> execute() -> +200%% de Ataque (habilidade consumida) | %s" % _instance.owner_unit.card.card_name)


func has_entered_frontline() -> bool:
	return _entered_frontline


func is_consumed() -> bool:
	return _consumed
