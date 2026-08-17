class_name ReactiveTraitRuntime
extends RefCounted
## ReactiveTraitRuntime
##
## Runtime genérico para Características de Unidade (Tier I) cujo efeito
## é uma ação independente (dano ou cura) disparada por um evento de
## combate — mesmo padrão de "Reativa" já usado pelas Habilidades
## (ver análise das Sprints 17/19). A lógica específica de cada
## Característica vive inteiramente no Callable "action" fornecido na
## construção; esta classe apenas garante o registro no evento certo e
## respeita Silêncio.
##
## Reutilizado por Fome Eterna, Sacrifício de Carne e Colheita de Almas
## (parcial) — nenhuma classe exclusiva foi criada para elas, pois todas
## compartilham a mesma estrutura ("ao ocorrer um evento, aplicar um
## efeito independente"). Diferença de nome/gatilho não justifica,
## sozinha, uma nova classe (mesma diretriz da Sprint 24).
##
## Não serve para Reerguer: reviver uma unidade morta muda is_alive e
## depende do próprio ciclo de vida da unidade — mecânica genuinamente
## diferente (ver ReviveRuntime).

var _instance: UnitTraitInstance
var _trigger_event: CombatEventType.Type
var _action: Callable  # func(context: CombatContext, owner: CombatUnit) -> void


func _init(p_instance: UnitTraitInstance, p_trigger_event: CombatEventType.Type, p_action: Callable) -> void:
	_instance = p_instance
	_trigger_event = p_trigger_event
	_action = p_action


func get_subscriptions() -> Dictionary:
	return { _trigger_event: _on_trigger }


func _on_trigger(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if _instance.owner_unit.silenced_until_turn >= context.turn:
		return
	_action.call(context, _instance.owner_unit)
