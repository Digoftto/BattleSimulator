class_name BattleResult
extends RefCounted
## BattleResult (F-028)
##
## Estrutura de dados confiável para representar o resultado de UMA
## batalha, adequada para futura serialização (simulação em massa,
## Campo de Prova, PvE, PvP, analytics) — nunca o battle_log textual
## (CombatState.battle_log, finalidade humana de depuração, não dado
## estruturado).
##
## Construída a partir de um CombatState já finalizado
## (BattleResult.from_state()). Os campos agregados de dano/cura/escudo
## só são preenchidos quando um BattleEventCollector foi anexado à
## batalha (opcional); quando não, permanecem nos valores padrão
## (Dictionary vazio), nunca inventados ou aproximados.
##
## Não persiste nada em disco — nenhum banco de dados, nenhuma
## serialização automática (F-028, escopo aprovado). to_dict() só
## prepara o formato para uma futura etapa decidir onde/como gravar.

var battle_id: String = ""
var seed_value: int = 0
var rules_version: String = ""

var winner_side: int = -1
var end_reason: String = ""
var turn_count: int = 0

var battlefield_name: String = ""
var game_mode: String = "pve"

## F-029: nome do Comandante de cada lado — lido diretamente de
## CombatState.commander_a/commander_b (já disponíveis, nenhum dado
## novo). Usado por SimulationReport para estatísticas por Comandante
## (F-029 §12).
var commander_name_a: String = ""
var commander_name_b: String = ""

## F-029: rótulo de Formação de cada lado (ex: "α", "β"), quando quem
## chama BattleSimulationRunner sabe qual Formação nomeada gerou esta
## composição (Army.formations) — opcional, "" quando não aplicável
## (ex: Exército gerado proceduralmente, sem Formação nomeada). Nunca
## inferido; sempre repassado por quem monta os pares de Exército.
var formation_label_a: String = ""
var formation_label_b: String = ""

## side (0/1) -> Array[String] (nomes das cartas eliminadas daquele
## lado) — dado leve o suficiente pra milhares de batalhas; nunca a
## CombatUnit inteira (que referencia o CardResource completo).
var eliminated_unit_names_by_side: Dictionary = {}

## F-029: side (0/1) -> Array[Dictionary] com um registro por pelotão
## ({"card_name", "position", "card_class", "survived"}) — a Formação
## de PARTIDA de cada lado (posição 1-9 no momento em que a batalha
## começou, capturada por BattleSimulationRunner logo após
## CombatEngine.initialize(), ANTES de CombatEngine.run() — depois
## disso a posição de uma unidade pode mudar por Movimentação,
## COMBAT_RULES.md 5.2, então usar state.units DEPOIS de run() daria a
## posição FINAL, não a Formação original). "survived" vem de
## eliminated_unit_names_by_side, computado depois que a batalha
## termina. Vazio quando quem chama from_state() não fornece
## "starting_roster" (BattleEventCollector continua sendo opcional;
## isto também é — nenhuma mudança de comportamento para quem só quer
## o resultado básico do F-028).
var unit_snapshots_by_side: Dictionary = {}

## Agregados (F-028 §11) — side (0/1) -> int. Só preenchidos quando um
## BattleEventCollector foi fornecido a from_state(); ver
## BattleEventCollector.total_damage_by_side()/total_healing_by_side()/
## total_shield_absorbed_by_side().
var total_damage_by_side: Dictionary = {}
var total_healing_by_side: Dictionary = {}
var total_shield_absorbed_by_side: Dictionary = {}

## F-029: cópia direta de BattleEventCollector.attack_events/heal_events/
## death_events desta batalha — só quando um collector foi fornecido.
## SimulationReport agrega por unidade/Classe/posição a PARTIR destes
## eventos brutos (F-029 §9), em vez de BattleResult tentar prever todo
## agrupamento possível — mantém esta classe um simples carregador de
## dados, e toda lógica de agregação num único lugar (SimulationReport).
## Custo de memória real e proporcional ao número de ações da batalha —
## por isso "collect_events" continua opt-in (F-028), nunca ligado por
## padrão numa simulação em massa.
var raw_attack_events: Array[Dictionary] = []
var raw_heal_events: Array[Dictionary] = []
var raw_death_events: Array[Dictionary] = []


## "state" deve ser um CombatState já finalizado (state.is_finished ==
## true) — normalmente obtido de CombatEngine.run_battle() ou de
## CombatEngine.initialize() + CombatEngine.run(). "collector" é
## opcional: quando fornecido, deve ter sido anexado (attach()) ANTES
## de CombatEngine.run() rodar, para ter capturado os eventos da
## batalha inteira.
## "starting_roster" (F-029): Dictionary {0: Array[Dictionary], 1:
## Array[Dictionary]} no formato produzido por
## BattleSimulationRunner._snapshot_starting_roster() — capturado ANTES
## de run(), nunca calculado aqui (ver unit_snapshots_by_side acima).
static func from_state(
	state: CombatState,
	collector: BattleEventCollector = null,
	starting_roster: Dictionary = {},
	formation_label_a: String = "",
	formation_label_b: String = ""
) -> BattleResult:
	var result := BattleResult.new()
	result.battle_id = state.battle_id
	result.seed_value = state.seed_value
	result.rules_version = state.rules_version
	result.winner_side = state.winner_side
	result.end_reason = state.end_reason
	result.turn_count = state.turn
	result.battlefield_name = state.battlefield.battlefield_name if state.battlefield != null else ""
	result.game_mode = state.game_mode
	result.commander_name_a = state.commander_a.commander_name if state.commander_a != null else ""
	result.commander_name_b = state.commander_b.commander_name if state.commander_b != null else ""
	result.formation_label_a = formation_label_a
	result.formation_label_b = formation_label_b

	var by_side: Dictionary = {0: [], 1: []}
	for unit: CombatUnit in state.eliminated_units:
		if not by_side.has(unit.side):
			by_side[unit.side] = []
		by_side[unit.side].append(unit.card.card_name if unit.card != null else "")
	result.eliminated_unit_names_by_side = by_side

	if collector != null:
		result.total_damage_by_side = collector.total_damage_by_side()
		result.total_healing_by_side = collector.total_healing_by_side()
		result.total_shield_absorbed_by_side = collector.total_shield_absorbed_by_side()
		result.raw_attack_events = collector.attack_events
		result.raw_heal_events = collector.heal_events
		result.raw_death_events = collector.death_events

	if not starting_roster.is_empty():
		var snapshots: Dictionary = {0: [], 1: []}
		for side: int in [0, 1]:
			var eliminated_names: Array = by_side.get(side, [])
			for entry: Dictionary in starting_roster.get(side, []):
				snapshots[side].append({
					"card_name": entry["card_name"],
					"position": entry["position"],
					"card_class": entry["card_class"],
					"survived": not eliminated_names.has(entry["card_name"]),
				})
		result.unit_snapshots_by_side = snapshots

	return result


func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"seed_value": seed_value,
		"rules_version": rules_version,
		"winner_side": winner_side,
		"end_reason": end_reason,
		"turn_count": turn_count,
		"battlefield_name": battlefield_name,
		"game_mode": game_mode,
		"commander_name_a": commander_name_a,
		"commander_name_b": commander_name_b,
		"formation_label_a": formation_label_a,
		"formation_label_b": formation_label_b,
		"eliminated_unit_names_by_side": eliminated_unit_names_by_side,
		"unit_snapshots_by_side": unit_snapshots_by_side,
		"total_damage_by_side": total_damage_by_side,
		"total_healing_by_side": total_healing_by_side,
		"total_shield_absorbed_by_side": total_shield_absorbed_by_side,
	}
