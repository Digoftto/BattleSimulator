class_name AffinityRuntime
extends RefCounted
## AffinityRuntime (F-035, AFFINITY.md/COMBAT_RULES.md 2.1/3.2/4.3)
##
## Integração da Afinidade ao CombatEngine. Separa duas responsabilidades:
##
## 1. CÁLCULO de Pontos/Níveis — inteiramente delegado a `Affinity`
##    (engine/combat/affinity.gd), reaproveitado sem alteração. Este
##    Runtime apenas monta, a cada snapshot, o `Array[CardResource]` das
##    unidades VIVAS de cada lado (o que automaticamente inclui pelotões
##    reerguidos — ReviveRuntime apenas reverte `is_alive`, nunca cria um
##    novo CombatUnit — e incluiria futuras unidades Evocadas, caso esse
##    sistema passe a existir: qualquer CombatUnit adicionado a
##    `state.units` entra na contagem automaticamente).
##
## 2. APLICAÇÃO dos efeitos numericamente especificados em AFFINITY.md,
##    escrevendo apenas em campos já congelados por turno (CombatState/
##    CombatUnit) — nunca decidindo alvo de dano/cura (isso continua
##    sendo responsabilidade exclusiva de CombatEngine/F-033).
##
## Efeitos NÃO implementados aqui (bloqueio de especificação, ver F-035
## §3/§12 do relatório — não inventados):
## - Afinidade III ("Valores Aprimorados"): AFFINITY.md/CARD_CATALOG.md
##   não definem nenhum valor numérico aprimorado; UnitTraitResource.
##   enhanced_effect_description é só texto (ver unit_trait_resource.gd).
## - Efeitos de Doutrina de Comandante ligados à Afinidade (E020/E021/
##   RS050/V070/V071): COMMANDER_EFFECTS.md não especifica a regra de
##   seleção da(s) carta(s) de outra Facção nem a mecânica de "custo
##   extra" o suficiente para runtime determinístico.


## Recalcula e CONGELA, para os dois lados, os Pontos/Nível de Afinidade
## por Facção e os efeitos numéricos dependentes desse snapshot (Afinidade
## II do Império/Natureza, disparo pendente->ativo dos Mortos-Vivos).
## Chamado tanto pela Inicialização (COMBAT_RULES.md 2.1, item 5) quanto
## pela Atualização do Combat State de todo turno, incluindo o Turno 1
## (COMBAT_RULES.md 3.2, item 2) — chamar duas vezes antes de qualquer
## ação de combate ter ocorrido é inofensivo e correto (nada mudou entre
## as duas chamadas).
static func snapshot_turn(state: CombatState) -> void:
	for side: int in [0, 1]:
		var commander: CommanderResource = state.commander_a if side == 0 else state.commander_b
		var alive_units: Array[CombatUnit] = state.units_of_side(side, true)

		var cards: Array[CardResource] = []
		var factions: Array[String] = []
		for unit: CombatUnit in alive_units:
			cards.append(unit.card)
			if not factions.has(unit.card.faction):
				factions.append(unit.card.faction)
		if commander != null and commander.faction != "" and not factions.has(commander.faction):
			factions.append(commander.faction)

		var points_by_faction: Dictionary = {}
		var levels_by_faction: Dictionary = {}
		for faction: String in factions:
			var points: int = Affinity.calculate_points(faction, cards, commander)
			points_by_faction[faction] = points
			levels_by_faction[faction] = Affinity.highest_active_level(points)

		state.affinity_points[side] = points_by_faction
		state.affinity_levels[side] = levels_by_faction

		for unit: CombatUnit in alive_units:
			unit.affinity_incoming_damage_multiplier = 1.0
			unit.affinity_first_heal_bonus_available = false

			var level: int = level_for(state, side, unit.card.faction)
			if unit.card.faction == "Império" and level >= 2:
				if _imperio_line_or_column_qualifies(state, side, unit.position):
					unit.affinity_incoming_damage_multiplier = 0.8
			elif unit.card.faction == "Natureza" and level >= 2:
				unit.affinity_first_heal_bonus_available = true

		state.undead_affinity_death_bonus_active[side] = state.undead_affinity_death_bonus_pending.get(side, false)
		state.undead_affinity_death_bonus_pending[side] = false


## Aplica, uma única vez (Inicialização — COMBAT_RULES.md 2.1, item 7),
## os bônus de Nível I definidos como valores de atributo "Base" (ESC do
## Império / HP da Natureza). Mesma limitação documentada já aceita para
## bônus de Comandante (CommanderDoctrineRuntime): HP/Escudo são valores
## "máximo"-like que não compõem de forma bem definida com um recálculo
## turno a turno sem uma regra adicional que AFFINITY.md não especifica
## — por isso avaliados uma única vez, no estado (Nível) vigente no
## início da batalha, no mesmo padrão de
## CombatEngine._apply_doctrine_hp_shield_bonus() (soma direta a
## current_hp/current_esc, sem novo teto — mesmo comportamento já
## existente para o bônus de HP/Escudo do Comandante).
##
## O bônus de ATK dos Mortos-Vivos (Nível I) NÃO tem esse problema — não
## é um valor "máximo" — por isso é recalculado a cada ataque, dentro de
## CombatEngine._effective_attack(), no mesmo padrão já usado pelo
## multiplicador de ataque do Comandante.
static func apply_initial_stat_bonuses(state: CombatState) -> void:
	for side: int in [0, 1]:
		for unit: CombatUnit in state.units_of_side(side, true):
			var level: int = level_for(state, side, unit.card.faction)
			if level < 1:
				continue
			match unit.card.faction:
				"Império":
					unit.current_esc += 25
				"Natureza":
					unit.current_hp += 20


## Nível de Afinidade ativo (0 = nenhum) de uma Facção, para um lado, no
## snapshot congelado atual.
static func level_for(state: CombatState, side: int, faction: String) -> int:
	var levels_by_faction: Dictionary = state.affinity_levels.get(side, {})
	return levels_by_faction.get(faction, 0)


## Afinidade II do Império (AFFINITY.md): "Enquanto uma linha ou coluna
## for composta exclusivamente por pelotões do Império, todos os
## pelotões dessa formação recebem 20%% menos dano." Verifica a Linha E
## a Coluna da posição informada; basta uma das duas qualificar (não
## empilha caso ambas qualifiquem — a regra concede um único -20%%).
##
## INTERPRETAÇÃO CONFIRMADA (F-036, decisão do proprietário do projeto —
## AFFINITY.md não detalhava o caso de posições vazias, então esta regra
## de contorno foi levada explicitamente para decisão antes de ser
## codificada, em vez de presumida em F-035): ESTRITA — a Linha/Coluna
## só qualifica se as 3 posições estiverem OCUPADAS e todas pertencerem
## ao Império. Qualquer posição vazia (morte, ainda não substituída) já
## desqualifica aquele grupo, mesmo sem nenhum pelotão de outra Facção
## presente.
static func _imperio_line_or_column_qualifies(state: CombatState, side: int, position: int) -> bool:
	var line: Array = CombatBoard.LINE_1 if CombatBoard.LINE_1.has(position) else (CombatBoard.LINE_2 if CombatBoard.LINE_2.has(position) else CombatBoard.LINE_3)
	var column: Array = CombatBoard.column_of(position)
	return _group_exclusively_faction(state, side, "Império", line) or _group_exclusively_faction(state, side, "Império", column)


static func _group_exclusively_faction(state: CombatState, side: int, faction: String, positions: Array) -> bool:
	for pos: int in positions:
		var unit: CombatUnit = state.unit_at(side, pos)
		if unit == null or unit.card.faction != faction:
			return false
	return true
