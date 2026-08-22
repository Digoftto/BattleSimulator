class_name SimulationReport
extends RefCounted
## SimulationReport (F-029)
##
## Agregação estatística de uma série de batalhas já executadas
## (Array[BattleResult], normalmente produzido por
## BattleSimulationRunner.run_batch()/run_series()). Construído uma
## única vez (build()), como BalanceReport (F-0XX) — nunca recalculado
## incrementalmente, nunca guarda os BattleResult originais (só os
## totais já agregados), para não duplicar memória numa simulação de
## milhares de batalhas.
##
## Eixos de agregação (F-029 §7-14): resultado geral, por Carta, por
## posição de partida, por Carta+posição, por Classe, por Comandante,
## por Campo de Batalha, por Formação (quando rotulada) — e, quando
## "collect_events" foi usado ao gerar os BattleResult (F-028/F-029
## §9), dano/cura/escudo agregados pelos mesmos eixos.
##
## "kills" por unidade é uma HEURÍSTICA, documentada — não um dado
## direto do motor de combate: UNIT_DIED identifica apenas quem morreu,
## nunca quem desferiu o golpe fatal (ver
## BattleEventCollector._on_unit_died()). A heurística usada aqui: para
## cada morte no turno T, o "matador" é o autor do ÚLTIMO evento de
## ataque do mesmo turno cujo alvo é exatamente aquela unidade e que
## aplicou dano > 0 à Vida. Isso é exato no caso comum (1 atacante por
## alvo por turno); no caso raro de dois ataques ao MESMO alvo no MESMO
## turno (ambos após o Escudo já ter zerado), o crédito vai para o
## último a agir na Ordem Oficial de Resolução — uma escolha razoável,
## nunca inventada, mas não garantida como "a real causa da morte" nesse
## caso específico. Só calculado quando eventos foram coletados.

var generated_at_unix: int = 0
var total_battles: int = 0
var wins_side_a: int = 0
var wins_side_b: int = 0
var draws: int = 0

var _turn_counts: Array[int] = []

## card_name -> {"appearances", "wins", "losses", "kills", "deaths"}
var unit_stats: Dictionary = {}
## posição de partida (1-9) -> {"appearances", "wins", "losses"}
var position_stats: Dictionary = {}
## card_name -> {posição (1-9) -> {"appearances", "wins"}}
var unit_position_stats: Dictionary = {}
## card_class -> {"appearances", "wins", "losses", "kills", "deaths"}
var class_stats: Dictionary = {}
## commander_name -> {"battles", "wins", "losses"}
var commander_stats: Dictionary = {}
## battlefield_name -> {"battles", "wins_side_a", "wins_side_b", "draws"} (+ "_turn_sum" interno, para average_turns)
var battlefield_stats: Dictionary = {}
## formation_label -> {"battles", "wins"} — só rótulos não-vazios (ver BattleResult.formation_label_a/b)
var formation_stats: Dictionary = {}

## card_name -> {"damage_dealt", "damage_received", "shield_absorbed_dealt", "healing_done"}
var unit_damage_stats: Dictionary = {}
## card_class -> {"damage_dealt", "damage_received", "shield_absorbed_dealt", "healing_done"}
var class_damage_stats: Dictionary = {}
## posição (1-9) -> {"damage_dealt", "damage_received"}
var position_damage_stats: Dictionary = {}
## side (0/1) -> int
var damage_dealt_by_side: Dictionary = {0: 0, 1: 0}
var damage_received_by_side: Dictionary = {0: 0, 1: 0}
var healing_by_side: Dictionary = {0: 0, 1: 0}
var shield_absorbed_by_side: Dictionary = {0: 0, 1: 0}

## true quando ao menos um BattleResult desta série trouxe eventos
## coletados (raw_attack_events/raw_heal_events/raw_death_events não
## vazios) — os campos *_damage_stats/kills só são confiáveis quando
## isto é true; caso contrário permanecem nos valores padrão (0/vazio),
## nunca aproximados.
var events_collected: bool = false


static func build(results: Array[BattleResult]) -> SimulationReport:
	var report := SimulationReport.new()
	report.generated_at_unix = GameClock.now_unix()
	report.total_battles = results.size()

	for result: BattleResult in results:
		report._turn_counts.append(result.turn_count)

		match result.winner_side:
			0:
				report.wins_side_a += 1
			1:
				report.wins_side_b += 1
			_:
				report.draws += 1

		report._tally_battlefield(result)
		report._tally_commander(result)
		report._tally_units_and_formations(result)

		if not result.raw_attack_events.is_empty() or not result.raw_heal_events.is_empty() or not result.raw_death_events.is_empty():
			report.events_collected = true
			report._tally_damage_and_kills(result)

	return report


# ---------------------------------------------------------------------------
# Resultado geral (F-029 §7)
# ---------------------------------------------------------------------------

func win_rate_a() -> float:
	return float(wins_side_a) / float(total_battles) if total_battles > 0 else 0.0


func win_rate_b() -> float:
	return float(wins_side_b) / float(total_battles) if total_battles > 0 else 0.0


func draw_rate() -> float:
	return float(draws) / float(total_battles) if total_battles > 0 else 0.0


func average_turns() -> float:
	if _turn_counts.is_empty():
		return 0.0
	var sum: int = 0
	for t: int in _turn_counts:
		sum += t
	return float(sum) / float(_turn_counts.size())


func median_turns() -> float:
	return _median(_turn_counts)


func min_turns() -> int:
	return _turn_counts.min() if not _turn_counts.is_empty() else 0


func max_turns() -> int:
	return _turn_counts.max() if not _turn_counts.is_empty() else 0


static func _median(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[int] = values.duplicate()
	sorted_values.sort()
	var n: int = sorted_values.size()
	if n % 2 == 1:
		return float(sorted_values[n / 2])
	return (float(sorted_values[n / 2 - 1]) + float(sorted_values[n / 2])) / 2.0


# ---------------------------------------------------------------------------
# Tally por batalha
# ---------------------------------------------------------------------------

func _tally_battlefield(result: BattleResult) -> void:
	var name: String = result.battlefield_name
	if name == "":
		return
	if not battlefield_stats.has(name):
		battlefield_stats[name] = {"battles": 0, "wins_side_a": 0, "wins_side_b": 0, "draws": 0, "_turn_sum": 0}
	var entry: Dictionary = battlefield_stats[name]
	entry["battles"] += 1
	entry["_turn_sum"] += result.turn_count
	match result.winner_side:
		0:
			entry["wins_side_a"] += 1
		1:
			entry["wins_side_b"] += 1
		_:
			entry["draws"] += 1


## Win rate médio de um Campo de Batalha do ponto de vista do lado A
## (F-029 §13) — exposto como função, não campo, porque depende de
## battles/wins_side_a já tabulados.
func battlefield_average_turns(battlefield_name: String) -> float:
	if not battlefield_stats.has(battlefield_name) or battlefield_stats[battlefield_name]["battles"] == 0:
		return 0.0
	return float(battlefield_stats[battlefield_name]["_turn_sum"]) / float(battlefield_stats[battlefield_name]["battles"])


func _tally_commander(result: BattleResult) -> void:
	for entry: Dictionary in [
		{"name": result.commander_name_a, "won": result.winner_side == 0},
		{"name": result.commander_name_b, "won": result.winner_side == 1},
	]:
		var name: String = entry["name"]
		if name == "":
			continue
		if not commander_stats.has(name):
			commander_stats[name] = {"battles": 0, "wins": 0, "losses": 0}
		commander_stats[name]["battles"] += 1
		if entry["won"]:
			commander_stats[name]["wins"] += 1
		elif result.winner_side != -1:
			commander_stats[name]["losses"] += 1


func _tally_units_and_formations(result: BattleResult) -> void:
	for side: int in [0, 1]:
		var won: bool = result.winner_side == side
		var lost: bool = result.winner_side != -1 and result.winner_side != side

		var formation_label: String = result.formation_label_a if side == 0 else result.formation_label_b
		if formation_label != "":
			if not formation_stats.has(formation_label):
				formation_stats[formation_label] = {"battles": 0, "wins": 0}
			formation_stats[formation_label]["battles"] += 1
			if won:
				formation_stats[formation_label]["wins"] += 1

		for snapshot: Dictionary in result.unit_snapshots_by_side.get(side, []):
			var card_name: String = snapshot["card_name"]
			var position: int = snapshot["position"]
			var card_class: String = snapshot["card_class"]
			var survived: bool = snapshot["survived"]

			if not unit_stats.has(card_name):
				unit_stats[card_name] = {"appearances": 0, "wins": 0, "losses": 0, "kills": 0, "deaths": 0}
			unit_stats[card_name]["appearances"] += 1
			if won:
				unit_stats[card_name]["wins"] += 1
			elif lost:
				unit_stats[card_name]["losses"] += 1
			if not survived:
				unit_stats[card_name]["deaths"] += 1

			if not position_stats.has(position):
				position_stats[position] = {"appearances": 0, "wins": 0, "losses": 0}
			position_stats[position]["appearances"] += 1
			if won:
				position_stats[position]["wins"] += 1
			elif lost:
				position_stats[position]["losses"] += 1

			if not unit_position_stats.has(card_name):
				unit_position_stats[card_name] = {}
			if not unit_position_stats[card_name].has(position):
				unit_position_stats[card_name][position] = {"appearances": 0, "wins": 0}
			unit_position_stats[card_name][position]["appearances"] += 1
			if won:
				unit_position_stats[card_name][position]["wins"] += 1

			if card_class != "":
				if not class_stats.has(card_class):
					class_stats[card_class] = {"appearances": 0, "wins": 0, "losses": 0, "kills": 0, "deaths": 0}
				class_stats[card_class]["appearances"] += 1
				if won:
					class_stats[card_class]["wins"] += 1
				elif lost:
					class_stats[card_class]["losses"] += 1
				if not survived:
					class_stats[card_class]["deaths"] += 1


func _tally_damage_and_kills(result: BattleResult) -> void:
	for event: Dictionary in result.raw_attack_events:
		var side: int = event["side"]
		var attacker_name: String = event["attacker_card_name"]
		var attacker_class: String = event["attacker_class"]
		var attacker_position: int = event["attacker_position"]
		var target_side: int = event.get("target_side", -1)
		var damage: int = int(event["damage_dealt"])
		var shield_absorbed: int = int(event["damage_absorbed_by_shield"])

		damage_dealt_by_side[side] = damage_dealt_by_side.get(side, 0) + damage
		if target_side != -1:
			damage_received_by_side[target_side] = damage_received_by_side.get(target_side, 0) + damage
		shield_absorbed_by_side[side] = shield_absorbed_by_side.get(side, 0) + shield_absorbed

		_bump_damage(unit_damage_stats, attacker_name, "damage_dealt", damage)
		_bump_damage(unit_damage_stats, attacker_name, "shield_absorbed_dealt", shield_absorbed)
		if attacker_class != "":
			_bump_damage(class_damage_stats, attacker_class, "damage_dealt", damage)
		if attacker_position != -1:
			_bump_position_damage(attacker_position, "damage_dealt", damage)

		var target_name: String = event.get("target_card_name", "")
		var target_class: String = event.get("target_class", "")
		var target_position: int = event.get("target_position", -1)
		if target_name != "":
			_bump_damage(unit_damage_stats, target_name, "damage_received", damage)
		if target_class != "":
			_bump_damage(class_damage_stats, target_class, "damage_received", damage)
		if target_position != -1:
			_bump_position_damage(target_position, "damage_received", damage)

	for event: Dictionary in result.raw_heal_events:
		var side: int = event["side"]
		var healer_name: String = event["healer_card_name"]
		var healer_class: String = event.get("healer_class", "")
		var amount: int = int(event["heal_amount"])

		healing_by_side[side] = healing_by_side.get(side, 0) + amount
		_bump_damage(unit_damage_stats, healer_name, "healing_done", amount)
		if healer_class != "":
			_bump_damage(class_damage_stats, healer_class, "healing_done", amount)

	# Deaths por unidade/Classe já foram contadas em
	# _tally_units_and_formations() via unit_snapshots_by_side/survived
	# — aqui só falta atribuir o "kill" correspondente (heurística).
	var killers: Array[Dictionary] = _attribute_kills(result.raw_death_events, result.raw_attack_events)
	for killer: Dictionary in killers:
		var killer_name: String = killer["name"]
		var killer_class: String = killer["card_class"]
		if killer_name != "" and unit_stats.has(killer_name):
			unit_stats[killer_name]["kills"] += 1
		if killer_class != "" and class_stats.has(killer_class):
			class_stats[killer_class]["kills"] += 1


## Heurística de atribuição de kill — ver docstring da classe. Retorna
## um Array (mesmo tamanho de "death_events") de {"name", "card_class"}
## de quem desferiu o golpe fatal ("" quando nenhum evento de ataque
## correspondente foi encontrado).
static func _attribute_kills(death_events: Array[Dictionary], attack_events: Array[Dictionary]) -> Array[Dictionary]:
	var killers: Array[Dictionary] = []
	for death: Dictionary in death_events:
		var killer_name: String = ""
		var killer_class: String = ""
		for attack: Dictionary in attack_events:
			var same_turn: bool = attack["turn"] == death["turn"]
			var same_target: bool = attack.get("target_card_name", "") == death["card_name"] and attack.get("target_side", -1) == death["side"]
			var dealt_hp_damage: bool = int(attack.get("damage_applied_to_hp", 0)) > 0
			if same_turn and same_target and dealt_hp_damage:
				killer_name = attack["attacker_card_name"]  # última correspondência no turno vence
				killer_class = attack.get("attacker_class", "")
		killers.append({"name": killer_name, "card_class": killer_class})
	return killers


static func _bump_damage(stats: Dictionary, key: String, field: String, amount: int) -> void:
	if key == "":
		return
	if not stats.has(key):
		stats[key] = {"damage_dealt": 0, "damage_received": 0, "shield_absorbed_dealt": 0, "healing_done": 0}
	stats[key][field] = stats[key].get(field, 0) + amount


func _bump_position_damage(position: int, field: String, amount: int) -> void:
	if not position_damage_stats.has(position):
		position_damage_stats[position] = {"damage_dealt": 0, "damage_received": 0}
	position_damage_stats[position][field] = position_damage_stats[position].get(field, 0) + amount


func to_dict() -> Dictionary:
	return {
		"generated_at_unix": generated_at_unix,
		"total_battles": total_battles,
		"wins_side_a": wins_side_a,
		"wins_side_b": wins_side_b,
		"draws": draws,
		"win_rate_a": win_rate_a(),
		"win_rate_b": win_rate_b(),
		"draw_rate": draw_rate(),
		"average_turns": average_turns(),
		"median_turns": median_turns(),
		"min_turns": min_turns(),
		"max_turns": max_turns(),
		"unit_stats": unit_stats,
		"position_stats": position_stats,
		"unit_position_stats": unit_position_stats,
		"class_stats": class_stats,
		"commander_stats": commander_stats,
		"battlefield_stats": battlefield_stats,
		"formation_stats": formation_stats,
		"events_collected": events_collected,
		"unit_damage_stats": unit_damage_stats,
		"class_damage_stats": class_damage_stats,
		"position_damage_stats": position_damage_stats,
		"damage_dealt_by_side": damage_dealt_by_side,
		"damage_received_by_side": damage_received_by_side,
		"healing_by_side": healing_by_side,
		"shield_absorbed_by_side": shield_absorbed_by_side,
	}
