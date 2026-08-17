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
## Duração, Reanimação/Evocação, aplicação de efeitos de Afinidade/Campo
## de Batalha/Doutrina. Onde essas regras se conectariam, há um ponto de
## extensão comentado (ver _environment_update_phase), mas nenhuma lógica
## é implementada.
##
## Puramente determinístico quanto à estrutura: recebe os Exércitos e o
## catálogo de Campos de Batalha por parâmetro. Não depende de
## GameDatabase ou Autoloads.

const MAX_TURNS: int = 64
const STRUCTURAL_HEAL_AMOUNT: int = 20  # Cura Estrutural da Classe Suporte (COMBAT_RULES.md 4.2.3)


## Executa uma batalha completa entre army_a (lado 0) e army_b (lado 1) e
## retorna o Combat State final, já com o Resultado preenchido.
## "game_mode" ("pve" | "pvp" | "mines") é opcional — usado pela
## Doutrina do Comandante (Restrições/Requisitos de domínio "game_mode").
static func run_battle(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve") -> CombatState:
	var state: CombatState = initialize(army_a, army_b, battlefields, abilities_by_name, unit_traits, game_mode)
	run(state)
	return state


## Inicializa o Combat State (Preparação + Turno 1 pronto para começar),
## sem executar nenhum turno. Exposto separadamente de run_battle() para
## permitir registrar ouvintes em state.event_bus antes da execução
## (ver validação em bootstrap.gd).
static func initialize(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve") -> CombatState:
	return _initialize(army_a, army_b, battlefields, abilities_by_name, unit_traits, game_mode)


## Executa o loop de turnos de um Combat State já inicializado, até a
## Conclusão da batalha.
static func run(state: CombatState) -> void:
	while not state.is_finished:
		_run_turn(state)


# ---------------------------------------------------------------------------
# Inicialização (COMBAT_RULES.md, capítulo 2)
# ---------------------------------------------------------------------------

static func _initialize(army_a: Army, army_b: Army, battlefields: Array[BattlefieldResource], abilities_by_name: Dictionary, unit_traits: Array[UnitTraitResource], game_mode: String = "pve") -> CombatState:
	assert(army_a.is_ready_for_battle(), "CombatEngine: Exército A não está pronto para batalha (ver ARMY.md/Army.is_ready_for_battle()).")
	assert(army_b.is_ready_for_battle(), "CombatEngine: Exército B não está pronto para batalha (ver ARMY.md/Army.is_ready_for_battle()).")

	var state := CombatState.new()
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


## Ponto de extensão: Atualização do Combat State (Ambiente) — Efeitos de
## Campo de Batalha, recálculo de Afinidade e aplicação de Buffs/Debuffs
## ativos entrariam aqui (COMBAT_RULES.md 3.2). Nenhuma lógica é
## implementada nesta Sprint.
static func _environment_update_phase(_state: CombatState) -> void:
	pass


## Movimentação (Fase de Avanço, 5.2). Avanço automático por coluna,
## processado do fundo para a frente, respeitando as exceções estruturais
## de Suporte (5.2.3) e Máquina de Guerra (6.6/posição fixa).
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


## Regra geral: avança se a posição à frente estiver livre. Exceções
## estruturais (5.2.3): Máquina de Guerra nunca avança; Suporte só avança
## se não houver aliado atrás, ou se o único aliado atrás for uma Máquina
## de Guerra.
static func _can_advance(state: CombatState, unit: CombatUnit) -> bool:
	match unit.card.card_class:
		"Máquina de Guerra":
			return false
		"Suporte":
			var allies_behind: Array[CombatUnit] = []
			for behind_pos: int in CombatBoard.positions_behind(unit.position):
				var ally: CombatUnit = state.unit_at(unit.side, behind_pos)
				if ally != null:
					allies_behind.append(ally)
			if allies_behind.is_empty():
				return true
			return allies_behind.size() == 1 and allies_behind[0].card.card_class == "Máquina de Guerra"
		_:
			return true


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


static func _most_injured_ally(state: CombatState, side: int, exclude: Array[CombatUnit]) -> CombatUnit:
	var best: CombatUnit = null
	var best_loss: int = 0

	for unit: CombatUnit in state.units_of_side(side):
		if exclude.has(unit):
			continue
		var loss: int = unit.card.hp - unit.current_hp
		if loss <= 0:
			continue
		var is_better: bool = loss > best_loss
		var is_tied_with_priority: bool = loss == best_loss and best != null and \
			CombatBoard.OFFICIAL_RESOLUTION_ORDER.find(unit.position) < CombatBoard.OFFICIAL_RESOLUTION_ORDER.find(best.position)
		if best == null or is_better or is_tied_with_priority:
			best = unit
			best_loss = loss

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
static func _apply_damage_amount(attack_value: float, target: CombatUnit) -> void:
	var damage: int = int(round(attack_value))

	if target.current_esc > 0:
		var absorbed: int = mini(damage, target.current_esc)
		target.current_esc -= absorbed
	else:
		target.current_hp = maxi(target.current_hp - damage, 0)


## Ataque efetivo, considerando o Bônus de Posição estrutural da Classe
## Corpo a Corpo (+50% de Ataque na Posição 1, COMBAT_RULES.md 6.1) e o
## Efeito de Ataque da Doutrina do Comandante, se houver
## (COMMANDER_EFFECTS.md E001).
static func _effective_attack(unit: CombatUnit, state: CombatState) -> float:
	var atk: float = float(unit.card.atk)
	if unit.card.card_class == "Corpo a Corpo" and unit.position == 1:
		atk *= 1.5
	atk *= CommanderDoctrineRuntime.attack_multiplier(unit, state)
	return atk


static func _apply_structural_heal(target: CombatUnit) -> void:
	target.current_hp = mini(target.current_hp + STRUCTURAL_HEAL_AMOUNT, target.card.hp)


## Resolução das Mortes. Verifica HP <= 0, remove simultaneamente do
## Combat State (marcando is_alive = false) e verifica as Condições de
## Encerramento por eliminação (1.3.1/1.3.2).
static func _death_resolution_phase(state: CombatState) -> void:
	for unit: CombatUnit in state.units:
		if unit.is_alive and unit.current_hp <= 0:
			unit.is_alive = false
			state.eliminated_units.append(unit)
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
