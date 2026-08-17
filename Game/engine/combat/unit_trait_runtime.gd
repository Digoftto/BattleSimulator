class_name UnitTraitRuntime
extends RefCounted
## UnitTraitRuntime
##
## Runtime responsável exclusivamente pelas Características de Unidade
## (Tier I): resolve tier_1_trait_name e instancia um UnitTraitInstance
## por referência resolvida.
##
## Consulta GameDatabase.traits_by_name — o índice único por nome,
## construído uma única vez na carga do banco de dados. Antes desta
## Sprint, este Runtime reconstruía seu próprio índice a cada batalha
## (era necessário enquanto a duplicidade "Engenharia Militar" existia,
## sem um lugar seguro para viver de forma permanente); com a
## duplicidade resolvida, mover o índice para GameDatabase elimina essa
## reconstrução redundante, no mesmo padrão já usado por
## abilities_by_name.
##
## Sprint 25: quando uma Característica possui Runtime implementado,
## este componente o instancia e registra automaticamente seus eventos
## no CombatEventBus, a partir do que o próprio Runtime informa via
## get_subscriptions(). Características sem Runtime permanecem inertes.

var _instances_by_unit: Dictionary = {}  # CombatUnit -> UnitTraitInstance


## "unit_traits" permanece na assinatura por compatibilidade com quem
## já chama este método (EffectRuntime) — o corpo não usa mais esse
## parâmetro diretamente, já que a resolução agora vem de
## GameDatabase.traits_by_name. Não cascateei essa limpeza para
## EffectRuntime/CombatEngine nesta Sprint, para manter a mudança
## pequena e de baixo risco.
func initialize(state: CombatState, _unit_traits: Array[UnitTraitResource]) -> void:
	for unit: CombatUnit in state.units:
		var resolved: UnitTraitResource = _resolve(unit.card.tier_1_trait_name)
		if resolved != null:
			var instance := UnitTraitInstance.new(resolved, unit, state)
			_attach_specialized_runtime(instance, state)
			_instances_by_unit[unit] = instance


func _resolve(trait_name: String) -> UnitTraitResource:
	if trait_name == "":
		return null
	return GameDatabase.traits_by_name.get(trait_name, null)


## Instancia o Runtime desta Característica (se existir) e registra
## automaticamente seus eventos no CombatEventBus. Características sem
## Runtime implementado permanecem inertes — nenhuma inscrição é feita,
## sem exceção espalhada pelo projeto.
func _attach_specialized_runtime(instance: UnitTraitInstance, state: CombatState) -> void:
	var runtime: RefCounted = _build_specialized_runtime(instance)
	if runtime == null:
		return

	instance.specialized_runtime = runtime
	BattleLogger.trace("UnitTraitRuntime", "Registrando Runtime: %s" % instance.resource.trait_name)

	var subscriptions: Dictionary = runtime.get_subscriptions()
	for event_type: CombatEventType.Type in subscriptions:
		state.event_bus.subscribe(event_type, subscriptions[event_type])


## Único ponto do projeto que associa o nome de uma Característica ao
## seu Runtime (genérico parametrizado ou especializado). Nenhuma outra
## parte do projeto deve conter lógica condicional por nome de
## Característica.
##
## Sprint 25: sempre que possível, reaproveita ReactiveTraitRuntime em
## vez de criar uma classe exclusiva — diferença de nome/gatilho não
## justifica, sozinha, uma nova classe. ReviveRuntime é especializado
## porque reviver muda is_alive (mecânica genuinamente distinta de
## "aplicar dano/cura a um alvo").
##
## Características sem entrada aqui permanecem sem comportamento —
## ver limitações arquiteturais registradas na entrega da Sprint 25
## (consulta de modificadores permanentes; fluxo de cura sem
## parametrização — inclusive "Manutenção de Campo"/"Manutenção
## Especializada", que dependem exatamente desse fluxo de cura
## parametrizável ainda não implementado).
func _build_specialized_runtime(instance: UnitTraitInstance) -> RefCounted:
	match instance.resource.trait_name:
		"Reerguer":
			return ReviveRuntime.new(instance, 0.3)

		"Fome Eterna":
			# Dreno de Vida: ao causar dano direto ao HP do alvo, soma +10
			# de dano diretamente ao HP (ignora Escudo, por definição da
			# própria Habilidade) e recupera 10 HP para o próprio pelotão.
			return ReactiveTraitRuntime.new(instance, CombatEventType.Type.AFTER_DAMAGE_DEALT,
				func(context: CombatContext, owner: CombatUnit) -> void:
					if context.attacker != owner:
						return
					if context.damage_applied_to_hp <= 0:
						return
					context.target.current_hp = maxi(context.target.current_hp - 10, 0)
					owner.current_hp = mini(owner.current_hp + 10, owner.card.hp)
					BattleLogger.trace("ReactiveTraitRuntime", "%s ativa 'Fome Eterna' contra %s | +10 dano direto ao HP, +10 HP próprio" % [owner.card.card_name, context.target.card.card_name])
			)

		"Sacrifício de Carne":
			# Ao atacar, o aliado imediatamente atrás (mesma coluna) perde
			# 10 HP, ignorando Escudo.
			return ReactiveTraitRuntime.new(instance, CombatEventType.Type.AFTER_ATTACK,
				func(context: CombatContext, owner: CombatUnit) -> void:
					if context.attacker != owner:
						return
					var behind_positions: Array[int] = CombatBoard.positions_behind(owner.position)
					if behind_positions.is_empty():
						return
					var ally: CombatUnit = context.state.unit_at(owner.side, behind_positions[0])
					if ally == null or not ally.is_alive:
						return
					ally.current_hp = maxi(ally.current_hp - 10, 0)
					BattleLogger.trace("ReactiveTraitRuntime", "%s ativa 'Sacrifício de Carne' | %s perde 10 HP" % [owner.card.card_name, ally.card.card_name])
			)

		"Colheita de Almas":
			# Implementação parcial (Sprint 25): apenas a recuperação de
			# 5 HP. O bônus permanente de +4% do Ataque Base NÃO é
			# aplicado — depende de um mecanismo de consulta de
			# modificadores permanentes que ainda não existe (ver
			# limitação arquitetural registrada na entrega da Sprint 25).
			return ReactiveTraitRuntime.new(instance, CombatEventType.Type.UNIT_DIED,
				func(_context: CombatContext, owner: CombatUnit) -> void:
					if not owner.is_alive:
						return
					owner.current_hp = mini(owner.current_hp + 5, owner.card.hp)
					BattleLogger.trace("ReactiveTraitRuntime", "%s ativa 'Colheita de Almas' (parcial: só a cura) | +5 HP | bônus permanente de Ataque NÃO aplicado (limitação arquitetural)" % owner.card.card_name)
			)

		_:
			return null


## Retorna a UnitTraitInstance de uma unidade, ou null caso não possua.
func get_instance(unit: CombatUnit) -> UnitTraitInstance:
	return _instances_by_unit.get(unit, null)
