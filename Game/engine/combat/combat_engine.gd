class_name CombatEngine
extends RefCounted
## CombatEngine
##
## Orquestra uma batalha completa entre dois Exércitos, implementando
## exclusivamente as regras estruturais de COMBAT_CORE.md/COMBAT_RULES.md:
## Inicialização, Sequência Geral do Turno, comportamento estrutural de
## Classe, cálculo de dano/cura e Condições de Encerramento.
##
## Não implementa Habilidades (Tier I/III/V), Buffs, Debuffs, Cooldown,
## Duração, Reanimação/Evocação, aplicação de efeitos de Campo de
## Batalha/Doutrina (além dos já cobertos por CommanderDoctrineRuntime).
## Onde essas regras se conectariam, há um ponto de extensão comentado
## (ver _environment_update_phase), mas nenhuma lógica é implementada.
##
## F-035: Afinidade (AFFINITY.md) passou a ser aplicada — ver
## AffinityRuntime. Nível III ("Valores Aprimorados") permanece
## bloqueado por ausência de valores numéricos em CARD_CATALOG.md; ver
## AffinityRuntime para o detalhamento completo do que está e do que
## não está implementado.
##
## Puramente determinístico quanto à estrutura: recebe os Exércitos e o
## catálogo de Campos de Batalha por parâmetro. Não depende de
## GameDatabase ou Autoloads.

const MAX_TURNS: int = 64
const STRUCTURAL_HEAL_AMOUNT: int = 20  # Cura Estrutural da Classe Suporte (COMBAT_RULES.md 4.2.3)

## F-028: versão das regras de combate estruturais implementadas por
## esta classe (COMBAT_CORE.md/COMBAT_RULES.md) — copiada em
## CombatState.rules_version no momento da criação de cada batalha, pra
## que um resultado antigo permaneça interpretável mesmo depois que
## este valor mudar. Sistema deliberadamente simples (F-028, escopo
## aprovado): apenas uma String comparável, sem parsing semântico
## (major/minor), sem migração — só o suficiente pra nunca misturar
## dados estatísticos de regras diferentes.
const RULES_VERSION: String = "1.0"


## Executa uma batalha completa entre army_a (lado 0) e army_b (lado 1) e
## retorna o Combat State final, já com o Resultado preenchido.
## "game_mode" ("pve" | "pvp" | "mines") é opcional — usado pela
## Doutrina do Comandante (Restrições/Requisitos de domínio "game_mode").
## "seed_value" é opcional (F-028): omitido (ou negativo), o
## comportamento é idêntico ao de antes — RNG verdadeiramente aleatório.
## Fornecido (>= 0), a batalha inteira (Campo de Batalha, Habilidades
## dependentes de RNG) se torna reproduzível — ver CombatState._init().
static func run_battle(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve", seed_value: int = -1) -> CombatState:
	var state: CombatState = initialize(army_a, army_b, battlefields, abilities_by_name, unit_traits, game_mode, seed_value)
	run(state)
	return state


## Inicializa o Combat State (Preparação + Turno 1 pronto para começar),
## sem executar nenhum turno. Exposto separadamente de run_battle() para
## permitir registrar ouvintes em state.event_bus antes da execução
## (ver validação em bootstrap.gd). "seed_value": ver run_battle().
static func initialize(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve", seed_value: int = -1) -> CombatState:
	return _initialize(army_a, army_b, battlefields, abilities_by_name, unit_traits, game_mode, seed_value)


## Executa o loop de turnos de um Combat State já inicializado, até a
## Conclusão da batalha, publicando BATTLE_FINISHED exatamente uma vez
## ao final (F-028) — cobre tanto o caminho normal (fim por eliminação/
## limite de turnos, decidido dentro de _run_turn) quanto o caminho de
## bloqueio por Restrição de Campo de Batalha, que já chega aqui com
## is_finished = true vindo de _initialize() (loop roda zero vezes).
## Chamadas que só usam initialize() sem nunca chamar run() (alguns
## testes, deliberadamente) nunca publicam este evento — consistente
## com o fato de que, do ponto de vista de quem chama, a batalha nunca
## foi de fato executada.
static func run(state: CombatState) -> void:
	while not state.is_finished:
		_run_turn(state)
	_publish_battle_finished(state)


static func _publish_battle_finished(state: CombatState) -> void:
	var finished_ctx := CombatContext.new()
	finished_ctx.state = state
	finished_ctx.turn = state.turn
	state.event_bus.publish(CombatEventType.Type.BATTLE_FINISHED, finished_ctx)


# ---------------------------------------------------------------------------
# Inicialização (COMBAT_RULES.md, capítulo 2)
# ---------------------------------------------------------------------------

static func _initialize(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve", seed_value: int = -1) -> CombatState:
	assert(army_a.is_ready_for_battle(), "CombatEngine: Exército A não está pronto para batalha (ver ARMY.md/Army.is_ready_for_battle()).")
	assert(army_b.is_ready_for_battle(), "CombatEngine: Exército B não está pronto para batalha (ver ARMY.md/Army.is_ready_for_battle()).")

	# F-028: a seed precisa existir ANTES do primeiro consumo de RNG
	# desta batalha — o sorteio do Campo de Batalha, logo abaixo, é
	# exatamente esse primeiro consumo. CombatState._init() já aplica a
	# seed (ou randomiza, se omitida) antes de devolver a instância —
	# nenhum RNG é consumido entre a criação do CombatState e este ponto.
	var state := CombatState.new(seed_value)
	state.game_mode = game_mode
	state.commander_a = army_a.commander
	state.commander_b = army_b.commander
	state.battlefield = Battlefield.draw(battlefields, state.rng)  # apenas identificação; Efeito não é aplicado nesta Sprint
	if state.enable_battle_log:
		state.battle_log.append("Campo de Batalha sorteado: %s (%s)" % [state.battlefield.battlefield_name, state.battlefield.category])

	# Restrição de Campo de Batalha (COMMANDER_RESTRICTIONS.md): só dá
	# pra checar DEPOIS do sorteio acima, já que a Restrição reage ao
	# Campo, nunca o escolhe. Se bloqueado, a mensagem clara fica
	# registrada no Battle Log — quem chama decide como lidar com isso
	# (ver CommanderDoctrineValidator.check_battlefield()).
	var battlefield_block_a: String = CommanderDoctrineValidator.check_battlefield(state.commander_a, state.battlefield)
	if battlefield_block_a != "":
		if state.enable_battle_log:
			state.battle_log.append("BLOQUEADO: %s" % battlefield_block_a)
		state.is_finished = true
		state.winner_side = 1
		state.end_reason = battlefield_block_a
		return state
	var battlefield_block_b: String = CommanderDoctrineValidator.check_battlefield(state.commander_b, state.battlefield)
	if battlefield_block_b != "":
		if state.enable_battle_log:
			state.battle_log.append("BLOQUEADO: %s" % battlefield_block_b)
		state.is_finished = true
		state.winner_side = 0
		state.end_reason = battlefield_block_b
		return state

	state.units.append_array(_place_army(army_a.cards, 0))
	state.units.append_array(_place_army(army_b.cards, 1))

	for unit: CombatUnit in state.units:
		_apply_initial_position_effects(unit)
		_apply_doctrine_hp_shield_bonus(unit, state)

	# F-035 (COMBAT_RULES.md 2.1, itens 5 e 7): snapshot inicial de
	# Afinidade, seguido da aplicação dos bônus de Nível I de atributo
	# "Base" (ESC do Império / HP da Natureza) — ver AffinityRuntime.
	AffinityRuntime.snapshot_turn(state)
	AffinityRuntime.apply_initial_stat_bonuses(state)

	state.effect_runtime = EffectRuntime.new()
	state.effect_runtime.initialize(state, abilities_by_name, unit_traits)

	var battle_start_ctx := CombatContext.new()
	battle_start_ctx.state = state
	battle_start_ctx.turn = state.turn
	battle_start_ctx.battlefield = state.battlefield
	state.event_bus.publish(CombatEventType.Type.BATTLE_START, battle_start_ctx)

	return state


## Posiciona as 9 cartas de um Exército: Máquina de Guerra sempre na
## Posição 9 (obrigatória, COMBAT_RULES.md 6.6); as demais ocupam as
## posições restantes em ordem (1 a 8), preservando a ordem original do
## Exército.
static func _place_army(cards: Array[CardResource], side: int) -> Array[CombatUnit]:
	var remaining_positions: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	var machine_card: CardResource = null
	var other_cards: Array[CardResource] = []

	for card: CardResource in cards:
		if card.card_class == "Máquina de Guerra" and machine_card == null:
			machine_card = card
		else:
			other_cards.append(card)

	var placed: Array[CombatUnit] = []
	if machine_card != null:
		placed.append(CombatUnit.new(machine_card, side, 9))
		remaining_positions.erase(9)

	for i in range(other_cards.size()):
		placed.append(CombatUnit.new(other_cards[i], side, remaining_positions[i]))

	return placed


## Aplica os efeitos estruturais dependentes de posição no momento da
## montagem inicial do Exército (antes do Turno 1).
static func _apply_initial_position_effects(unit: CombatUnit) -> void:
	_apply_barreira_position_bonus(unit)
	if unit.position == 5:
		# "não se aplica se iniciar a batalha nela" (5.2.2): marca como já
		# disparada, sem ativar a penalidade de reorganização neste turno.
		unit.has_triggered_reorganization = true


# ---------------------------------------------------------------------------
# Sequência Geral do Turno (COMBAT_RULES.md, capítulo 3)
# ---------------------------------------------------------------------------

static func _run_turn(state: CombatState) -> void:
	if state.enable_battle_log:
		state.battle_log.append("--- Turno %d ---" % state.turn)
	_log_board_snapshot(state)

	var turn_ctx := CombatContext.new()
	turn_ctx.state = state
	turn_ctx.turn = state.turn
	state.event_bus.publish(CombatEventType.Type.TURN_START, turn_ctx)

	for unit: CombatUnit in state.units:
		unit.is_reorganizing_this_turn = false

	_environment_update_phase(state)
	_movement_phase(state)

	var actions: Dictionary = _selection_phase(state)
	_execution_phase(state, actions)
	_death_resolution_phase(state)

	state.event_bus.publish(CombatEventType.Type.TURN_END, turn_ctx)

	if state.is_finished:
		return

	if state.turn >= MAX_TURNS:
		_resolve_turn_limit(state)
	else:
		state.turn += 1


## Registra no log um retrato do tabuleiro (Linha 1/2/3, por Lado) no
## início do turno — apenas para depuração; não é lógica de combate.
static func _log_board_snapshot(state: CombatState) -> void:
	for side in [0, 1]:
		if state.enable_battle_log:
			state.battle_log.append("  Lado %d | Linha 1: %s | Linha 2: %s | Linha 3: %s" % [
				side,
				_format_line_snapshot(state, side, CombatBoard.LINE_1),
				_format_line_snapshot(state, side, CombatBoard.LINE_2),
				_format_line_snapshot(state, side, CombatBoard.LINE_3),
			])


static func _format_line_snapshot(state: CombatState, side: int, positions: Array[int]) -> String:
	var parts: Array[String] = []
	for position: int in positions:
		var unit: CombatUnit = state.unit_at(side, position)
		if unit == null:
			parts.append("[%d: vazio]" % position)
		else:
			parts.append("[%d: %s HP %d/%d ESC %d]" % [position, unit.card.card_name, unit.current_hp, unit.card.hp, unit.current_esc])
	return " ".join(parts)


## Atualização do Combat State (Ambiente) — COMBAT_RULES.md 3.2, item 2.
## F-035: recálculo e snapshot dos Níveis de Afinidade (AffinityRuntime).
## Efeitos de Campo de Batalha e Buffs/Debuffs ativos permanecem como
## ponto de extensão — nenhuma lógica adicional é implementada aqui.
static func _environment_update_phase(state: CombatState) -> void:
	AffinityRuntime.snapshot_turn(state)


## Movimentação (Fase de Avanço, 5.2). Avanço automático por coluna,
## processado do fundo para a frente, respeitando a exceção estrutural de
## Suporte (5.2.3/6.5). A Máquina de Guerra só tem restrição de
## posicionamento INICIAL (6.6, posição 9 obrigatória) — depois de
## iniciado o combate, segue a regra geral de avanço como qualquer outra
## Classe (não é uma exceção de movimento).
static func _movement_phase(state: CombatState) -> void:
	for side in [0, 1]:
		for column: Array in CombatBoard.COLUMNS:
			for i in range(column.size() - 1, 0, -1):
				var pos: int = column[i]
				var front_pos: int = column[i - 1]
				var unit: CombatUnit = state.unit_at(side, pos)
				if unit == null:
					continue
				if state.unit_at(side, front_pos) != null:
					continue
				if not _can_advance(state, unit):
					continue

				unit.position = front_pos
				_apply_arrival_position_effects(unit)
				var reorg_note: String = " (entra em Reorganização)" if unit.is_reorganizing_this_turn else ""
				if state.enable_battle_log:
					state.battle_log.append("Lado %d: %s avança de %d para %d%s" % [side, unit.card.card_name, pos, front_pos, reorg_note])

				var move_ctx := CombatContext.new()
				move_ctx.state = state
				move_ctx.turn = state.turn
				move_ctx.attacker = unit
				move_ctx.side = side
				move_ctx.position = front_pos
				state.event_bus.publish(CombatEventType.Type.UNIT_MOVED, move_ctx)


## Regra geral: avança se a posição à frente estiver livre. Exceção
## estrutural (5.2.3): apenas a Classe Suporte tem regra de movimento
## própria (6.5, Cadeia de Bloqueio) — Máquina de Guerra segue a regra
## geral como qualquer outra Classe (sua única restrição é de
## posicionamento INICIAL, 6.6, aplicada em _place_army(), nunca aqui).
static func _can_advance(state: CombatState, unit: CombatUnit) -> bool:
	match unit.card.card_class:
		"Suporte":
			return _support_chain_clear(state, unit)
		_:
			return true


## Cadeia de Bloqueio do Suporte (COMBAT_RULES.md 6.5). Verifica apenas a
## posição IMEDIATAMENTE atrás de "unit":
## - Vazia, ou ocupada por Máquina de Guerra: nunca bloqueia — a cadeia
##   termina aqui, o que estiver mais atrás (mesmo um pelotão
##   convencional) é irrelevante (Máquina de Guerra é opaca à cadeia).
## - Ocupada por outro Suporte: a mesma verificação se aplica
##   recursivamente a esse Suporte (Suporte é transparente à cadeia — é
##   preciso checar o que está atrás DELE também).
## - Ocupada por qualquer outra Classe (Corpo a Corpo, Barreira, À
##   Distância ou Mago): bloqueia o avanço de toda a cadeia de Suportes
##   à sua frente.
static func _support_chain_clear(state: CombatState, unit: CombatUnit) -> bool:
	var behind_positions: Array[int] = CombatBoard.positions_behind(unit.position)
	if behind_positions.is_empty():
		return true

	var ally: CombatUnit = state.unit_at(unit.side, behind_positions[0])
	if ally == null or ally.card.card_class == "Máquina de Guerra":
		return true
	if ally.card.card_class == "Suporte":
		return _support_chain_clear(state, ally)
	return false


static func _apply_arrival_position_effects(unit: CombatUnit) -> void:
	_apply_barreira_position_bonus(unit)
	if unit.position == 5 and not unit.has_triggered_reorganization:
		unit.has_triggered_reorganization = true
		unit.is_reorganizing_this_turn = true


static func _apply_barreira_position_bonus(unit: CombatUnit) -> void:
	if unit.card.card_class == "Barreira" and unit.position == 1 and not unit.barreira_position_bonus_applied:
		unit.current_esc += int(round(unit.card.esc * 0.5))
		unit.barreira_position_bonus_applied = true


## Aplica, uma única vez (início da batalha), o bônus de HP/Escudo da
## Doutrina do Comandante desta unidade (COMMANDER_EFFECTS.md E002/E003).
## Nunca aplicado à Linha 2/3 (COMMANDER_GENERATION.md, "Formação").
static func _apply_doctrine_hp_shield_bonus(unit: CombatUnit, state: CombatState) -> void:
	var hp_bonus: int = CommanderDoctrineRuntime.hp_bonus(unit, state)
	if hp_bonus > 0:
		unit.current_hp += hp_bonus
	var shield_bonus: int = CommanderDoctrineRuntime.shield_bonus(unit, state)
	if shield_bonus > 0:
		unit.current_esc += shield_bonus


## Seleção de Alvos (Fase de Seleção, 5.3). Determina, para cada pelotão
## vivo e apto a agir, sua ação (ataque ou cura) e alvo — congelados
## (Snapshot) para a Fase de Execução seguinte.
static func _selection_phase(state: CombatState) -> Dictionary:
	var actions: Dictionary = {}

	for side in [0, 1]:
		var enemy_side: int = 1 - side
		var support_healers: Array[CombatUnit] = []

		for unit: CombatUnit in state.units_of_side(side):
			if unit.is_reorganizing_this_turn:
				actions[unit] = {"type": "none"}
				continue

			match unit.card.card_class:
				"Corpo a Corpo", "Barreira":
					actions[unit] = _select_line_1_attack(state, unit, enemy_side)
				"À Distância":
					actions[unit] = _select_ranged_attack(state, unit, enemy_side)
				"Mago":
					actions[unit] = _select_mirror_attack(state, unit, enemy_side)
				"Suporte":
					if unit.position == 1:
						actions[unit] = _select_mirror_attack(state, unit, enemy_side)
					else:
						support_healers.append(unit)
						actions[unit] = {"type": "none"}  # definido abaixo, após ordenar os curandeiros
				"Máquina de Guerra":
					actions[unit] = {"type": "none"}
				_:
					actions[unit] = {"type": "none"}

		_assign_heal_actions(state, side, support_healers, actions)

	for unit: CombatUnit in actions:
		var selected_ctx := CombatContext.new()
		selected_ctx.state = state
		selected_ctx.turn = state.turn
		selected_ctx.attacker = unit
		selected_ctx.target = actions[unit].get("target")
		selected_ctx.side = unit.side
		selected_ctx.position = unit.position
		selected_ctx.action = actions[unit]
		state.event_bus.publish(CombatEventType.Type.ACTION_SELECTED, selected_ctx)

	return actions


static func _select_line_1_attack(state: CombatState, unit: CombatUnit, enemy_side: int) -> Dictionary:
	if not CombatBoard.is_line_1(unit.position):
		return {"type": "none"}
	var target: CombatUnit = state.unit_at(enemy_side, unit.position)
	return {"type": "attack", "target": target} if target != null else {"type": "none"}


static func _select_mirror_attack(state: CombatState, unit: CombatUnit, enemy_side: int) -> Dictionary:
	var target: CombatUnit = state.unit_at(enemy_side, unit.position)
	return {"type": "attack", "target": target} if target != null else {"type": "none"}


static func _select_ranged_attack(state: CombatState, unit: CombatUnit, enemy_side: int) -> Dictionary:
	if not CombatBoard.RANGED_TARGET_MAP.has(unit.position):
		return {"type": "none"}
	var target_position: int = CombatBoard.RANGED_TARGET_MAP[unit.position]
	var target: CombatUnit = state.unit_at(enemy_side, target_position)
	return {"type": "attack", "target": target} if target != null else {"type": "none"}


## Atribui alvos de Cura Estrutural aos pelotões Suporte (posições 2-9),
## garantindo alvos diferentes entre múltiplos curandeiros do mesmo
## Exército, com prioridade pela Ordem Oficial de Resolução (6.1).
static func _assign_heal_actions(state: CombatState, side: int, healers: Array[CombatUnit], actions: Dictionary) -> void:
	healers.sort_custom(func(a: CombatUnit, b: CombatUnit) -> bool:
		return CombatBoard.OFFICIAL_RESOLUTION_ORDER.find(a.position) < CombatBoard.OFFICIAL_RESOLUTION_ORDER.find(b.position)
	)

	var claimed: Array[CombatUnit] = []
	for healer: CombatUnit in healers:
		var target: CombatUnit = _most_injured_ally(state, side, claimed)
		if target != null:
			actions[healer] = {"type": "heal", "target": target}
			claimed.append(target)
		else:
			actions[healer] = {"type": "none"}


## F-033: prioriza o menor PERCENTUAL de HP restante (current_hp /
## card.hp), não o maior déficit ABSOLUTO — antes desta mudança, uma
## unidade de HP máximo alto podia monopolizar a cura mesmo estando
## proporcionalmente menos ferida que uma unidade de HP máximo baixo
## (ex: 400/1000 = 40% perdia pra 250/500 = 50% no critério antigo,
## mesmo a segunda estando mais ferida na proporção). Desempate: menor
## número de posição (mais perto da Posição 1) — decisão explícita do
## proprietário, não uma noção geométrica nova (a numeração de posições
## já existente é usada diretamente, nunca OFFICIAL_RESOLUTION_ORDER,
## que é uma ordem de RESOLUÇÃO de ações simultâneas, não de
## PROXIMIDADE à Posição 1).
static func _most_injured_ally(state: CombatState, side: int, exclude: Array[CombatUnit]) -> CombatUnit:
	var best: CombatUnit = null
	var best_hp_ratio: float = 1.0

	for unit: CombatUnit in state.units_of_side(side):
		if exclude.has(unit):
			continue
		if unit.current_hp >= unit.card.hp:
			continue
		var hp_ratio: float = float(unit.current_hp) / float(unit.card.hp)
		var is_better: bool = hp_ratio < best_hp_ratio
		var is_tied_with_priority: bool = hp_ratio == best_hp_ratio and best != null and unit.position < best.position
		if best == null or is_better or is_tied_with_priority:
			best = unit
			best_hp_ratio = hp_ratio

	return best


## Execução das Ações (Fase de Execução, 5.4). Processa as ações
## congeladas posição por posição, seguindo a Ordem Oficial de Resolução
## (6.1) — executando ambos os lados em cada posição antes de avançar
## para a próxima, para não conceder vantagem estrutural a nenhum dos
## lados (em vez de resolver um Exército inteiro antes do outro). Um
## ataque cujo alvo já esteja destruído (HP <= 0) nesta mesma fase falha,
## sem redefinir o alvo (5.3.2).
static func _execution_phase(state: CombatState, actions: Dictionary) -> void:
	for position: int in CombatBoard.OFFICIAL_RESOLUTION_ORDER:
		for side in [0, 1]:
			var unit: CombatUnit = state.unit_at(side, position)
			if unit == null or not actions.has(unit):
				continue
			_execute_action(state, unit, actions[unit])


static func _execute_action(state: CombatState, unit: CombatUnit, action: Dictionary) -> void:
	if action["type"] == "attack":
		var target: CombatUnit = action.get("target")

		var attack_ctx := CombatContext.new()
		attack_ctx.state = state
		attack_ctx.turn = state.turn
		attack_ctx.attacker = unit
		attack_ctx.target = target
		attack_ctx.side = unit.side
		attack_ctx.position = unit.position
		attack_ctx.attack_value = _effective_attack(unit, state)
		state.event_bus.publish(CombatEventType.Type.BEFORE_ATTACK, attack_ctx)

		if target == null or target.current_hp <= 0:
			if state.enable_battle_log:
				state.battle_log.append("Lado %d: %s (pos %d) ataca, mas o alvo já foi destruído nesta fase — ação falha." % [unit.side, unit.card.card_name, unit.position])
			state.event_bus.publish(CombatEventType.Type.AFTER_ATTACK, attack_ctx)
			return

		state.event_bus.publish(CombatEventType.Type.BEFORE_DAMAGE, attack_ctx)

		var esc_before: int = target.current_esc
		var hp_before: int = target.current_hp
		_apply_damage_amount(attack_ctx.attack_value, target)
		if state.enable_battle_log:
			state.battle_log.append("Lado %d: %s (pos %d) ataca Lado %d: %s (pos %d) | ESC %d->%d | HP %d->%d" % [
				unit.side, unit.card.card_name, unit.position, target.side, target.card.card_name, target.position,
				esc_before, target.current_esc, hp_before, target.current_hp
			])

		attack_ctx.damage_absorbed_by_shield = esc_before - target.current_esc
		attack_ctx.damage_applied_to_hp = hp_before - target.current_hp
		attack_ctx.damage_dealt = attack_ctx.damage_absorbed_by_shield + attack_ctx.damage_applied_to_hp

		state.event_bus.publish(CombatEventType.Type.AFTER_DAMAGE_DEALT, attack_ctx)
		state.event_bus.publish(CombatEventType.Type.AFTER_DAMAGE_TAKEN, attack_ctx)
		state.event_bus.publish(CombatEventType.Type.AFTER_ATTACK, attack_ctx)

	elif action["type"] == "heal":
		var target: CombatUnit = action.get("target")

		var heal_ctx := CombatContext.new()
		heal_ctx.state = state
		heal_ctx.turn = state.turn
		heal_ctx.attacker = unit
		heal_ctx.target = target
		heal_ctx.side = unit.side
		heal_ctx.position = unit.position

		if target == null or not target.is_alive:
			return

		state.event_bus.publish(CombatEventType.Type.BEFORE_HEAL, heal_ctx)

		var hp_before: int = target.current_hp
		_apply_structural_heal(target)
		if state.enable_battle_log:
			state.battle_log.append("Lado %d: %s (pos %d) executa Cura Estrutural em %s (pos %d) | HP %d->%d" % [
				unit.side, unit.card.card_name, unit.position, target.card.card_name, target.position, hp_before, target.current_hp
			])

		heal_ctx.heal_amount = target.current_hp - hp_before
		state.event_bus.publish(CombatEventType.Type.AFTER_HEAL_PERFORMED, heal_ctx)
		state.event_bus.publish(CombatEventType.Type.AFTER_HEAL_RECEIVED, heal_ctx)


## Ataque Básico (determinado pela Classe, e possivelmente modificado por
## uma Habilidade via CombatContext.attack_value — ver _execute_action).
## Redução de Escudo antes da Vida; enquanto existir Escudo, nenhum dano
## é aplicado à Vida nesta mesma ação (4.1) — sem penetração estrutural
## (fora de escopo, pertence a Habilidades como Perfuração/Perfurante).
## F-035: aplica o multiplicador de dano recebido da Afinidade II do
## Império (target.affinity_incoming_damage_multiplier, congelado por
## AffinityRuntime no snapshot do turno — nunca recalculado aqui).
static func _apply_damage_amount(attack_value: float, target: CombatUnit) -> void:
	var damage: int = int(round(attack_value * target.affinity_incoming_damage_multiplier))

	if target.current_esc > 0:
		var absorbed: int = mini(damage, target.current_esc)
		target.current_esc -= absorbed
	else:
		target.current_hp = maxi(target.current_hp - damage, 0)


## Ataque efetivo, considerando o Bônus de Posição estrutural da Classe
## Corpo a Corpo (+50% de Ataque na Posição 1, COMBAT_RULES.md 6.1), a
## Afinidade dos Mortos-Vivos (F-035: Nível I "+8 ATK Base" e Nível II
## "+5%% do Ataque Base" após a primeira morte da Facção no turno
## anterior — ambos somados ao ATK Base, antes dos multiplicadores de
## Posição/Comandante, já que AFFINITY.md descreve os dois como bônus de
## "Ataque Base") e o Efeito de Ataque da Doutrina do Comandante, se
## houver (COMMANDER_EFFECTS.md E001).
static func _effective_attack(unit: CombatUnit, state: CombatState) -> float:
	var atk: float = float(unit.card.atk)
	if unit.card.faction == "Mortos-Vivos":
		var undead_level: int = AffinityRuntime.level_for(state, unit.side, "Mortos-Vivos")
		if undead_level >= 1:
			atk += 8.0
		if undead_level >= 2 and state.undead_affinity_death_bonus_active.get(unit.side, false):
			atk += 0.05 * float(unit.card.atk)
	if unit.card.card_class == "Corpo a Corpo" and unit.position == 1:
		atk *= 1.5
	atk *= CommanderDoctrineRuntime.attack_multiplier(unit, state)
	return atk


## F-035: aplica a Afinidade II da Natureza sobre o valor BASE da Cura
## Estrutural (COMBAT_RULES.md 4.2.3, Hierarquia Oficial de Modificadores
## de Cura, item 5) — "+10 HP adicionais" na primeira cura recebida por
## este pelotão no turno, consumindo a flag congelada por AffinityRuntime
## (nunca decide o ALVO da cura — isso continua em _most_injured_ally/
## F-033, intocado).
static func _apply_structural_heal(target: CombatUnit) -> void:
	var heal_amount: int = STRUCTURAL_HEAL_AMOUNT
	if target.affinity_first_heal_bonus_available:
		heal_amount += 10
		target.affinity_first_heal_bonus_available = false
	target.current_hp = mini(target.current_hp + heal_amount, target.card.hp)


## Resolução das Mortes. Verifica HP <= 0, remove simultaneamente do
## Combat State (marcando is_alive = false) e verifica as Condições de
## Encerramento por eliminação (1.3.1/1.3.2).
static func _death_resolution_phase(state: CombatState) -> void:
	for unit: CombatUnit in state.units:
		if unit.is_alive and unit.current_hp <= 0:
			unit.is_alive = false
			state.eliminated_units.append(unit)
			# F-035 (AFFINITY.md, Afinidade II dos Mortos-Vivos): registra a
			# morte como PENDENTE para o próximo snapshot de turno — nunca
			# ativa o bônus no turno corrente (ver CombatState.
			# undead_affinity_death_bonus_pending/_active).
			if unit.card.faction == "Mortos-Vivos":
				state.undead_affinity_death_bonus_pending[unit.side] = true
			if state.enable_battle_log:
				state.battle_log.append("Lado %d: %s (pos %d) foi destruído no Turno %d." % [unit.side, unit.card.card_name, unit.position, state.turn])

			var death_ctx := CombatContext.new()
			death_ctx.state = state
			death_ctx.turn = state.turn
			death_ctx.attacker = unit
			death_ctx.side = unit.side
			death_ctx.position = unit.position
			state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)

	_check_elimination_victory(state)


static func _check_elimination_victory(state: CombatState) -> void:
	var alive_0: int = state.units_of_side(0).size()
	var alive_1: int = state.units_of_side(1).size()

	if alive_0 == 0 and alive_1 == 0:
		state.is_finished = true
		state.winner_side = -1
		state.end_reason = "eliminacao_simultanea"
		if state.enable_battle_log:
			state.battle_log.append("Resultado: empate por eliminação simultânea (Turno %d)." % state.turn)
	elif alive_0 == 0:
		state.is_finished = true
		state.winner_side = 1
		state.end_reason = "eliminacao_total"
		if state.enable_battle_log:
			state.battle_log.append("Resultado: Lado 1 vence por eliminação total (Turno %d)." % state.turn)
	elif alive_1 == 0:
		state.is_finished = true
		state.winner_side = 0
		state.end_reason = "eliminacao_total"
		if state.enable_battle_log:
			state.battle_log.append("Resultado: Lado 0 vence por eliminação total (Turno %d)." % state.turn)


## Limite de Turnos (1.3.3): vence quem possuir mais pelotões vivos;
## empate em caso de igualdade.
static func _resolve_turn_limit(state: CombatState) -> void:
	var alive_0: int = state.units_of_side(0).size()
	var alive_1: int = state.units_of_side(1).size()

	state.is_finished = true
	state.end_reason = "limite_de_turnos"

	if alive_0 > alive_1:
		state.winner_side = 0
	elif alive_1 > alive_0:
		state.winner_side = 1
	else:
		state.winner_side = -1

	var winner_text: String = "empate" if state.winner_side == -1 else "Lado %d vence" % state.winner_side
	if state.enable_battle_log:
		state.battle_log.append("Resultado: %s por limite de turnos (%d vivos vs %d vivos, Turno %d)." % [winner_text, alive_0, alive_1, state.turn])
