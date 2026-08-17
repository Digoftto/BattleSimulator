class_name AbilityRuntime
extends RefCounted
## AbilityRuntime
##
## Runtime responsável exclusivamente pelas Habilidades (Tier III/V):
## resolve tier_3_ability_name/tier_5_ability_name contra o índice já
## construído por GameDatabase (abilities_by_name — rígido, sem
## duplicados) e instancia um AbilityInstance por referência resolvida.
##
## Quando uma Habilidade possui Runtime implementado (ver
## _build_specialized_runtime), este componente o instancia e registra
## automaticamente seus eventos no CombatEventBus, a partir do que o
## próprio Runtime informa via get_subscriptions() — nunca a partir de
## uma tabela de tradução entre texto de Gatilho e evento. Habilidades
## sem Runtime permanecem inertes (nenhuma inscrição, nenhum
## comportamento).

var _instances_by_unit: Dictionary = {}  # CombatUnit -> Array[AbilityInstance]


## Resolve e instancia as Habilidades de todas as CombatUnit do state.
## "abilities_by_name" é o índice rígido já construído por GameDatabase —
## este Runtime não reconstrói nem mantém sua própria cópia.
func initialize(state: CombatState, abilities_by_name: Dictionary) -> void:
	for unit: CombatUnit in state.units:
		var instances: Array[AbilityInstance] = []

		var tier_3: AbilityResource = _resolve(unit.card.tier_3_ability_name, abilities_by_name)
		if tier_3 != null:
			var instance := AbilityInstance.new(tier_3, unit, state)
			_attach_specialized_runtime(instance, state)
			instances.append(instance)

		var tier_5: AbilityResource = _resolve(unit.card.tier_5_ability_name, abilities_by_name)
		if tier_5 != null:
			var instance := AbilityInstance.new(tier_5, unit, state)
			_attach_specialized_runtime(instance, state)
			instances.append(instance)

		_instances_by_unit[unit] = instances


func _resolve(ability_name: String, abilities_by_name: Dictionary) -> AbilityResource:
	if ability_name == "":
		return null
	assert(abilities_by_name.has(ability_name),
		"AbilityRuntime: referência a Habilidade inexistente no catálogo: '%s'." % ability_name)
	return abilities_by_name[ability_name]


## Instancia o Runtime desta Habilidade (se existir) e registra
## automaticamente seus eventos no CombatEventBus. Habilidades sem
## Runtime implementado permanecem inertes — nenhuma inscrição é feita,
## sem exceção espalhada pelo projeto.
func _attach_specialized_runtime(instance: AbilityInstance, state: CombatState) -> void:
	var runtime: RefCounted = _build_specialized_runtime(instance)
	if runtime == null:
		return

	instance.specialized_runtime = runtime
	BattleLogger.trace("AbilityRuntime", "Registrando Runtime: %s" % instance.resource.ability_name)

	var subscriptions: Dictionary = runtime.get_subscriptions()
	for event_type: CombatEventType.Type in subscriptions:
		state.event_bus.subscribe(event_type, subscriptions[event_type])


## Único ponto do projeto que associa o nome de uma Habilidade ao seu
## Runtime (genérico parametrizado ou especializado). Nenhuma outra parte
## do projeto deve conter lógica condicional por nome de Habilidade.
##
## Sprint 24: sempre que possível, reaproveita um Runtime genérico já
## existente (BonusAttackRuntime, DefensiveModifierRuntime) em vez de
## criar uma classe exclusiva — diferença de nome, sozinha, nunca
## justifica uma nova classe. AreaAttackRuntime e SilencioRuntime são
## especializados porque sua mecânica é genuinamente distinta (múltiplos
## alvos simultâneos; aplicação de estado consultado por terceiros).
##
## Habilidades sem entrada aqui (ex: Provocar) permanecem sem
## comportamento — ver observação de limitação arquitetural na entrega
## da Sprint 24.
func _build_specialized_runtime(instance: AbilityInstance) -> RefCounted:
	match instance.resource.ability_name:
		"Investida":
			return InvestidaRuntime.new(instance)

		"Ataque Duplo":
			return BonusAttackRuntime.new(instance, CombatEventType.Type.AFTER_ATTACK, 1.0,
				func(context: CombatContext, owner: CombatUnit) -> CombatUnit:
					if context.attacker != owner:
						return null
					return context.state.unit_at(context.target.side, context.target.position)
			)

		"Contra-ataque":
			return BonusAttackRuntime.new(instance, CombatEventType.Type.AFTER_DAMAGE_TAKEN, 1.0,
				func(context: CombatContext, owner: CombatUnit) -> CombatUnit:
					if context.target != owner:
						return null
					if context.attacker == null or context.attacker.card.card_class != "Corpo a Corpo":
						return null
					return context.attacker
			)

		"Campo de Força":
			return DefensiveModifierRuntime.new(instance, true,
				func(_attack_value: float, _owner: CombatUnit) -> Variant:
					return 0.0
			)

		"Sobrevivência":
			return DefensiveModifierRuntime.new(instance, true,
				func(attack_value: float, owner: CombatUnit) -> Variant:
					if owner.current_esc == 0 and attack_value >= owner.current_hp:
						return float(owner.current_hp - 1)
					return null
			)

		"Perfuração":
			return DefensiveModifierRuntime.new(instance, false,
				func(attack_value: float, owner: CombatUnit) -> Variant:
					if owner.current_esc <= 0:
						return null
					var half: int = int(round(attack_value * 0.5))
					var esc_absorbed: int = mini(half, owner.current_esc)
					owner.current_esc -= esc_absorbed
					owner.current_hp = maxi(owner.current_hp - half, 0)
					return 0.0
			)

		"Ataque em Área":
			return AreaAttackRuntime.new(instance, 0.5)

		"Silêncio":
			return SilencioRuntime.new(instance)

		_:
			return null


## Retorna as AbilityInstance (Tier III e/ou V) de uma unidade, ou uma
## lista vazia caso não possua nenhuma.
func get_instances(unit: CombatUnit) -> Array[AbilityInstance]:
	return _instances_by_unit.get(unit, [])
