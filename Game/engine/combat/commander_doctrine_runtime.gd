class_name CommanderDoctrineRuntime
extends RefCounted
## CommanderDoctrineRuntime (COMMANDER_EFFECTS.md, Categoria 1 — Combate)
##
## Aplica os 3 Efeitos de Combate possíveis (Ataque/HP/Escudo — os de
## Frequência "Alta", a maioria dos casos) durante a batalha, combinando
## Alvo (quem) e Requisito (quando) da Doutrina do Comandante.
##
## LIMITAÇÃO DOCUMENTADA: bônus de HP/Escudo só são aplicados UMA VEZ,
## no início da batalha (mesmo padrão do bônus estrutural de posição
## da Barreira) — porque HP/Escudo são valores "máximos" que fariam
## pouco sentido reavaliar turno a turno (não há como "sumir" HP já
## concedido sem curar/matar artificialmente). Isso significa: se o
## Requisito da Doutrina for do tipo "unit_state" (HP ≤ X%, Escudo = 0
## — dinâmico, por unidade), ele nunca estará satisfeito no instante
## exato do início da batalha (toda unidade começa com HP/Escudo
## cheios) — nessa combinação específica, o bônus de HP/Escudo nunca
## dispara na prática. Ataque não tem essa limitação: é recalculado a
## cada ataque (_effective_attack), suportando Requisitos dinâmicos
## corretamente.
##
## Efeitos de Progressão (XP/Fragmentos/Recursos/Soldo) e Estrutural
## (Afinidade) NÃO são tratados aqui — pertencem a outros sistemas
## (recompensas pós-batalha, validação de Soldo, cálculo de Afinidade).


## Multiplicador de Ataque a aplicar (1.0 = sem bônus) — chamado a
## cada ataque (CombatEngine._effective_attack), suporta Requisitos
## dinâmicos corretamente.
static func attack_multiplier(unit: CombatUnit, state: CombatState) -> float:
	var commander: CommanderResource = state.commander_a if unit.side == 0 else state.commander_b
	if not _effect_applies(unit, commander, state, "attack"):
		return 1.0
	var value: CommanderValueResource = commander.doctrine.value
	if value.is_percentage:
		return 1.0 + value.amount
	return 1.0


## Bônus de HP máximo (valor absoluto já convertido do percentual) —
## avaliado uma vez, no início da batalha (ver limitação documentada
## acima). Nunca aplicado à Linha 2/3 (COMMANDER_GENERATION.md).
static func hp_bonus(unit: CombatUnit, state: CombatState) -> int:
	if unit.position > 3:
		return 0
	var commander: CommanderResource = state.commander_a if unit.side == 0 else state.commander_b
	if not _effect_applies(unit, commander, state, "hp"):
		return 0
	var value: CommanderValueResource = commander.doctrine.value
	if value.is_percentage:
		return int(round(unit.card.hp * value.amount))
	return 0


## Bônus de Escudo máximo — mesma regra da Linha 1 apenas.
static func shield_bonus(unit: CombatUnit, state: CombatState) -> int:
	if unit.position > 3:
		return 0
	var commander: CommanderResource = state.commander_a if unit.side == 0 else state.commander_b
	if not _effect_applies(unit, commander, state, "shield"):
		return 0
	var value: CommanderValueResource = commander.doctrine.value
	if value.is_percentage:
		return int(round(unit.card.esc * value.amount))
	return 0


static func _effect_applies(unit: CombatUnit, commander: CommanderResource, state: CombatState, effect_kind: String) -> bool:
	if commander == null or commander.doctrine == null:
		return false
	if commander.doctrine.effect.kind != effect_kind:
		return false
	if not _target_matches(unit, commander):
		return false
	return _requirement_met(unit, commander, state)


static func _target_matches(unit: CombatUnit, commander: CommanderResource) -> bool:
	var target: CommanderTargetResource = commander.doctrine.target
	match target.category:
		"faction":
			return unit.card.faction == commander.faction
		"class":
			var mapped: String = CommanderDoctrineValidator.CLASS_NAME_MAP.get(target.value, target.value)
			return unit.card.card_class == mapped
		"formation":
			var line: int = 1 if unit.position <= 3 else (2 if unit.position <= 6 else 3)
			var target_line: int = {"Linha 1": 1, "Linha 2": 2, "Linha 3": 3}.get(target.value, 0)
			return line == target_line
	return false


static func _requirement_met(unit: CombatUnit, commander: CommanderResource, state: CombatState) -> bool:
	var requirement: CommanderRequirementResource = commander.doctrine.requirement
	var param: String = commander.doctrine.requirement_param

	var allies: Array[CombatUnit] = []
	for u: CombatUnit in state.units:
		if u.side == unit.side and u.is_alive:
			allies.append(u)

	match requirement.domain:
		"faction":
			var count: int = 0
			for ally: CombatUnit in allies:
				if ally.card.faction == commander.faction:
					count += 1
			return count >= requirement.quantity
		"class":
			var mapped: String = CommanderDoctrineValidator.CLASS_NAME_MAP.get(param, param)
			var count: int = 0
			for ally: CombatUnit in allies:
				if ally.card.card_class == mapped:
					count += 1
			return count >= requirement.quantity
		"battlefield":
			return state.battlefield != null and state.battlefield.battlefield_name == param
		"unit_state":
			match requirement.operator:
				"state_hp_leq":
					return unit.card.hp > 0 and (float(unit.current_hp) / float(unit.card.hp)) * 100.0 <= requirement.quantity
				"state_shield_eq":
					return unit.current_esc == requirement.quantity
			return false
		"army_state":
			return allies.size() <= requirement.quantity
		"game_mode":
			return state.game_mode == requirement.scope
	return false
