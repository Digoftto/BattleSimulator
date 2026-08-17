class_name CommanderGenerator
extends RefCounted
## CommanderGenerator
##
## Implementa o Fluxo Oficial de Geração descrito em COMMANDER_GENERATION.md,
## combinando os 5 Bancos Oficiais (Restrições, Requisitos, Alvos, Efeitos,
## Valores) em uma Doutrina Militar completa e válida.
##
## Escopo desta Sprint: Etapas 1-8 do fluxo oficial, aplicando exclusivamente
## as Regras Oficiais de Compatibilidade documentadas. Não implementa
## Aparência, Patente, XP, Centro de Comando, Combate, Exército ou Interface.
##
## Fora do escopo desta Sprint (fica pendente conforme a própria
## documentação): conversão do Rarity Score em Raridade Final
## (Comum/Rara/Épica/Lendária) — ver COMMANDER_GENERATION.md, Etapa 8.

## Facções oficiais da Temporada 1 (FACTION_DESIGN.md, "Facções Iniciais").
const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

## Classes oficiais utilizadas pelo Motor de Geração (COMMANDER_RESTRICTIONS.md /
## COMMANDER_REQUIREMENTS.md / COMMANDER_TARGETS.md).
const CLASSES: Array[String] = ["Melee", "Ranged", "Mago", "Suporte", "Barreira", "Máquina de Guerra"]

## Campos de Batalha não-padrão (BATTLEFIELDS.md), excluindo Campo Aberto,
## utilizados como domínio de valores para a categoria Campo de Batalha
## dos bancos de Restrição e Requisito.
const NON_STANDARD_BATTLEFIELDS: Array[String] = [
	"Ventania", "Chuva Fraca", "Tempestade com Raios",
	"Pântano", "Floresta", "Vale",
	"Lua Cheia", "Terreno Vulcânico", "Nevoeiro Arcano",
]


## Executa o Fluxo Oficial de Geração completo (Etapas 1-8) e retorna a
## Doutrina Militar resultante.
static func generate(
	restrictions: Array[CommanderRestrictionResource],
	requirements: Array[CommanderRequirementResource],
	targets: Array[CommanderTargetResource],
	effects: Array[CommanderEffectResource],
	values: Array[CommanderValueResource]
) -> CommanderDoctrine:
	var doctrine := CommanderDoctrine.new()

	# Etapa 1 — Sortear a Facção do comandante.
	doctrine.faction = FACTIONS[randi() % FACTIONS.size()]

	# Etapa 2 — Sortear uma Restrição válida.
	doctrine.restriction = WeightedRandom.pick(restrictions, func(r: CommanderRestrictionResource) -> int:
		return CommanderFrequency.weight_for(r.frequency_label)
	)
	doctrine.restriction_param = _sample_param(doctrine.restriction.domain, doctrine.restriction.operator, doctrine.restriction.scope, doctrine.faction)

	# Etapa 3 — Eliminar todos os Requisitos incompatíveis com a Restrição.
	var candidate_requirements: Array = []
	var candidate_requirement_params: Dictionary = {}
	for requirement: CommanderRequirementResource in requirements:
		var requirement_param: String = _sample_param(requirement.domain, requirement.operator, requirement.scope, doctrine.faction)
		if _is_restriction_requirement_compatible(doctrine.restriction, doctrine.restriction_param, requirement, requirement_param):
			candidate_requirements.append(requirement)
			candidate_requirement_params[requirement] = requirement_param

	assert(not candidate_requirements.is_empty(), "CommanderGenerator: nenhum Requisito compatível com a Restrição sorteada.")

	# Etapa 4 — Sortear um Requisito (entre os válidos).
	doctrine.requirement = WeightedRandom.pick(candidate_requirements, func(r: CommanderRequirementResource) -> int:
		return CommanderFrequency.weight_for(r.frequency_label)
	)
	doctrine.requirement_param = candidate_requirement_params[doctrine.requirement]

	# Etapa 5 — Selecionar um Alvo compatível.
	# Nenhuma Regra Oficial de Compatibilidade documentada relaciona Alvo a
	# Restrição/Requisito diretamente nesta etapa do fluxo; a única
	# compatibilidade documentada envolvendo Alvo (Formação x Efeito) só
	# pode ser avaliada após o Efeito ser conhecido (Etapa 6).
	doctrine.target = WeightedRandom.pick(targets, func(t: CommanderTargetResource) -> int:
		return CommanderFrequency.weight_for(t.frequency_label)
	)

	# Etapa 6 — Selecionar um Efeito compatível.
	var candidate_effects: Array = []
	for effect: CommanderEffectResource in effects:
		if _is_requirement_compatible_with_effect(doctrine.requirement, effect) \
				and _is_target_compatible_with_effect(doctrine.target, effect):
			candidate_effects.append(effect)

	assert(not candidate_effects.is_empty(), "CommanderGenerator: nenhum Efeito compatível com o Requisito/Alvo sorteados.")

	doctrine.effect = WeightedRandom.pick(candidate_effects, func(e: CommanderEffectResource) -> int:
		return CommanderFrequency.weight_for(e.frequency_label)
	)

	# Etapa 7 — Selecionar um Valor compatível (mesma categoria do Efeito).
	var candidate_values: Array = values.filter(func(v: CommanderValueResource) -> bool:
		return v.effect_kind == doctrine.effect.kind
	)

	assert(not candidate_values.is_empty(), "CommanderGenerator: nenhum Valor cadastrado para o Efeito '%s'." % doctrine.effect.kind)

	doctrine.value = WeightedRandom.pick(candidate_values, func(v: CommanderValueResource) -> int:
		return CommanderFrequency.weight_for(v.frequency_label)
	)

	# Etapa 8 — Calcular o Rarity Score (soma dos Pesos de Frequência).
	doctrine.rarity_score = CommanderFrequency.weight_for(doctrine.restriction.frequency_label) \
		+ CommanderFrequency.weight_for(doctrine.requirement.frequency_label) \
		+ CommanderFrequency.weight_for(doctrine.target.frequency_label) \
		+ CommanderFrequency.weight_for(doctrine.effect.frequency_label) \
		+ CommanderFrequency.weight_for(doctrine.value.frequency_label)

	return doctrine


## Sorteia o parâmetro de tempo de geração (quando aplicável) para uma
## entrada de Restrição ou Requisito, conforme seu domínio/operador/escopo.
## Retorna string vazia quando a entrada não é parametrizada.
static func _sample_param(domain: String, operator: String, scope: String, own_faction: String) -> String:
	match domain:
		"class":
			return CLASSES[randi() % CLASSES.size()]
		"battlefield":
			if operator == "forbidden" or operator == "during":
				return NON_STANDARD_BATTLEFIELDS[randi() % NON_STANDARD_BATTLEFIELDS.size()]
			return ""
		"faction":
			if scope == "other":
				var others: Array = FACTIONS.filter(func(f: String) -> bool: return f != own_faction)
				return others[randi() % others.size()]
			return ""
		"game_mode":
			return scope  # já fixo no catálogo ("pvp" / "pve" / "mines")
		_:
			return ""


## Regra Oficial de Compatibilidade: "Uma Restrição nunca pode impedir que
## seu próprio Requisito seja satisfeito" (COMMANDER_GENERATION.md),
## generalizada por domínio a partir dos exemplos oficiais documentados
## (Facção, Classe, Campo de Batalha) em COMMANDER_RESTRICTIONS.md.
static func _is_restriction_requirement_compatible(
	restriction: CommanderRestrictionResource,
	restriction_param: String,
	requirement: CommanderRequirementResource,
	requirement_param: String
) -> bool:
	if restriction.domain != requirement.domain:
		return true  # domínios diferentes: nenhuma regra de conflito documentada

	match restriction.domain:
		"faction":
			# Apenas "Máximo da mesma Facção" (Restrição) pode conflitar com
			# "Pelo menos N da mesma Facção" (Requisito). "Mínimo de outra
			# Facção" (escopo "other") nunca conflita, pois se refere a um
			# conjunto de cartas diferente.
			if restriction.operator == "max" and restriction.scope == "self" and requirement.scope == "self":
				return requirement.quantity <= restriction.quantity
			return true
		"class":
			if restriction_param != requirement_param:
				return true  # classes diferentes: sem conflito
			if restriction.operator == "forbidden":
				return false  # "Não aceita X" x qualquer Requisito de X
			if restriction.operator == "max":
				return requirement.quantity <= restriction.quantity
			return true  # "min"/"required" nunca impedem um Requisito de mínimo
		"battlefield":
			if restriction.operator == "only_standard":
				return false  # exige sempre Campo Aberto; Requisito exige um Campo específico não-padrão
			if restriction.operator == "forbidden":
				return restriction_param != requirement_param
			return true
		"game_mode":
			return restriction_param == requirement_param
		_:
			return true


## Regra Oficial de Compatibilidade: Requisitos dinâmicos (Estado da
## Unidade / Estado do Exército) só podem gerar Efeitos de Combate;
## Requisito de Minas só pode gerar o Efeito Recursos.
static func _is_requirement_compatible_with_effect(requirement: CommanderRequirementResource, effect: CommanderEffectResource) -> bool:
	var is_dynamic: bool = requirement.domain == "unit_state" or requirement.domain == "army_state"
	if is_dynamic:
		return effect.category == "combat"

	var is_mines: bool = requirement.domain == "game_mode" and requirement.scope == "mines"
	if is_mines:
		return effect.kind == "resources"

	return true


## Regra Oficial de Compatibilidade: na Temporada 1, Linha 2 e Linha 3
## nunca recebem bônus de HP ou Escudo.
static func _is_target_compatible_with_effect(target: CommanderTargetResource, effect: CommanderEffectResource) -> bool:
	var is_rear_line: bool = target.category == "formation" and (target.value == "Linha 2" or target.value == "Linha 3")
	if is_rear_line:
		return effect.kind != "hp" and effect.kind != "shield"
	return true
