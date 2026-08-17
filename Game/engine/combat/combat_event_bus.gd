class_name CombatEventBus
extends RefCounted
## CombatEventBus
##
## Barramento de eventos pertencente a uma única batalha (nunca Autoload,
## nunca Singleton — cada CombatState possui sua própria instância).
##
## Responsabilidade exclusiva: registrar ouvintes, removê-los, publicar
## eventos e entregar o CombatContext correspondente. Não conhece
## Silêncio, Buffs, Debuffs, Afinidade, Doutrina, Campos de Batalha ou
## qualquer outra regra de negócio — quem decide o que fazer com um
## evento é exclusivamente o ouvinte, nunca o barramento.

var _listeners: Dictionary = {}  # CombatEventType.Type -> Array[Callable]


## Registra um ouvinte para um tipo de evento. O Callable deve aceitar
## exatamente dois parâmetros: (event_type: CombatEventType.Type, context: CombatContext).
func subscribe(event_type: CombatEventType.Type, listener: Callable) -> void:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	_listeners[event_type].append(listener)


## Remove um ouvinte previamente registrado para um tipo de evento.
func unsubscribe(event_type: CombatEventType.Type, listener: Callable) -> void:
	if _listeners.has(event_type):
		_listeners[event_type].erase(listener)


## Publica um evento, entregando o contexto a todos os ouvintes
## registrados para esse tipo, na ordem em que foram registrados.
func publish(event_type: CombatEventType.Type, context: CombatContext) -> void:
	if not _listeners.has(event_type):
		return
	for listener: Callable in _listeners[event_type]:
		listener.call(event_type, context)
