class_name PhaseResolver
extends RefCounted
## PhaseResolver
##
## Resolve uma Fase completa (PvE.md, "Retry de uma Fase"): percorre os
## Exércitos do Squad na ordem de prioridade e, para cada um, suas
## Formações na ordem de prioridade configurada no próprio Exército
## (ARMY.md), chamando CombatEngine para cada tentativa, até obter
## vitória ou esgotar tudo.
##
## Cada tentativa de Formação consome Energia do Exército ativo
## (ENERGY.md: 4 pontos por tentativa de combate em PvE). Um Exército é
## considerado esgotado quando suas cinco Formações forem derrotadas
## OU sua Energia se esgotar antes disso — o que ocorrer primeiro — e
## o próximo Exército do Squad assume a partir de sua primeira
## Formação. A Energia nunca é recuperada durante a resolução (só em
## Acampamento, fora do escopo desta classe).
##
## Toda a lógica de retry fica concentrada aqui. CombatEngine é tratado
## como caixa-preta — utiliza exclusivamente a API pública já existente
## (CombatEngine.run_battle), sem nenhuma alteração nele, em CombatState,
## EffectRuntime, AbilityRuntime ou UnitTraitRuntime.

const ENERGY_COST_PER_ATTEMPT: int = 4


## Resolve a Fase contra o EnemyArmyEntry informado. "squad" é
## reiniciado (reset) no início da resolução, para garantir que a
## Tentativa de Fase sempre começa pelo primeiro Exército da prioridade.
## "context_label" identifica a origem do combate para o Histórico de
## Batalhas do Comandante (COMMANDERS.md, "Estatísticas Históricas") —
## quem chama sabe melhor o que está acontecendo (ExpeditionRuntime
## sabe a Fase; MineConquestResolver sabe que é uma conquista de Mina).
static func resolve(
	squad: Squad,
	enemy_entry: EnemyArmyEntry,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	context_label: String = "Combate",
	game_mode: String = "pve"
) -> PhaseResult:
	var result := PhaseResult.new()
	result.opponent_entry = enemy_entry
	squad.reset()

	var enemy_army := Army.new()
	enemy_army.commander = enemy_entry.commander
	enemy_army.cards = enemy_entry.cards

	while not squad.is_exhausted():
		var army: Army = squad.active_army()
		var army_index: int = squad.active_index

		for formation_name: String in army.formation_priority:
			var attempt_army: Army = _build_attempt_army(army, formation_name)

			# Restrição da Doutrina do Comandante (COMMANDER_RESTRICTIONS.md):
			# checada ANTES de gastar Energia, pra dar um aviso claro sem
			# desperdiçar a tentativa numa configuração que nunca poderia
			# funcionar.
			var restriction_block: String = CommanderDoctrineValidator.check_static(attempt_army.commander, attempt_army.cards, game_mode)
			if restriction_block != "":
				result.history_log.append("Formação %s bloqueada: %s" % [formation_name, restriction_block])
				continue

			if not army.has_energy(ENERGY_COST_PER_ATTEMPT):
				result.history_log.append("Exército %d sem Energia suficiente para a Formação %s — considerado esgotado." % [
					army_index + 1, formation_name
				])
				break

			result.attempts += 1
			army.consume_energy(ENERGY_COST_PER_ATTEMPT)

			var state: CombatState = CombatEngine.run_battle(
				attempt_army, enemy_army, battlefields, abilities_by_name, unit_traits, game_mode
			)

			var result_text: String = "Vitória" if state.winner_side == 0 else ("Derrota" if state.winner_side == 1 else "Empate")
			result.history_log.append("Tentativa %d: Exército %d, Formação %s -> %s (Turno %d) | Energia restante: %d/%d" % [
				result.attempts, army_index + 1, formation_name,
				result_text, state.turn, army.current_energy, army.max_energy
			])

			if army.commander != null:
				var opponent_name: String = enemy_army.commander.commander_name if enemy_army.commander != null else "Guarnição de %s" % enemy_entry.faction
				army.commander.record_battle(opponent_name, context_label, result_text, GameClock.now_unix(), attempt_army.cards, enemy_army.cards)

			if state.winner_side == 0:
				result.victory = true
				result.winning_army_index = army_index
				result.winning_formation = formation_name
				var eliminated_by_faction: Dictionary = _count_enemy_eliminated_by_faction(state)
				result.enemy_pelotoes_destroyed_by_faction = eliminated_by_faction
				result.enemy_pelotoes_destroyed = _sum_dictionary_values(eliminated_by_faction)
				return result

		squad.advance_to_next_army()

	result.victory = false
	result.history_log.append("Todos os Exércitos do Squad esgotaram todas as Formações ou sua Energia. Fase não conquistada.")
	return result


## Constrói um Exército transitório (mesmo Comandante do Exército real,
## cartas na ordem da Formação escolhida) para uma única tentativa —
## nunca muta o Exército real, preservando seu estado (inclusive
## Energia) entre tentativas.
static func _build_attempt_army(army: Army, formation_name: String) -> Army:
	var attempt := Army.new()
	attempt.commander = army.commander
	attempt.cards = army.get_formation(formation_name)
	return attempt


## Conta quantos pelotões do lado inimigo (side == 1) foram eliminados
## na batalha — usado por RewardResolver (RESOURCES.md §4).
## RESOURCES.md §4: "Correspondência de Facção: o fragmento gerado
## pertence sempre à mesma facção do pelotão destruído" — nunca a
## Facção principal do oponente como um todo, já que a composição
## inimiga mistura Facções (PvE.md, "6 da Facção principal + 3
## secundárias"). Retorna {Facção: quantidade}.
static func _count_enemy_eliminated_by_faction(state: CombatState) -> Dictionary:
	var counts: Dictionary = {}
	for unit: CombatUnit in state.eliminated_units:
		if unit.side == 1 and unit.card != null:
			counts[unit.card.faction] = counts.get(unit.card.faction, 0) + 1
	return counts


static func _sum_dictionary_values(values: Dictionary) -> int:
	var total: int = 0
	for key: Variant in values:
		total += values[key]
	return total
