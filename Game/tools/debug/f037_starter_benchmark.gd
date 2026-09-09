extends Node
## f037_starter_benchmark.gd (F-037)
##
## Benchmark read-only dos 3 Starter Armies REAIS agora que Afinidade
## (F-035/F-036) participa do combate. NÃO altera nenhuma regra de jogo:
## reaproveita StarterKitResolver (roster canônico), CombatEngine.run_battle()
## e EnemyArmyGenerator (Tier I/Comum) exatamente como já existem. Este
## arquivo é só orquestração + coleta de métricas + escrita em disco —
## nenhuma linha aqui participa da resolução de uma batalha.
##
## Uso:
##   godot --headless --path Game res://tools/debug/f037_starter_benchmark.tscn -- --phase=fixed
##   godot --headless --path Game res://tools/debug/f037_starter_benchmark.tscn -- --phase=random_formation
##   godot --headless --path Game res://tools/debug/f037_starter_benchmark.tscn -- --phase=random_enemy
## Cada fase escreve seu próprio JSON em res://reports/ (F-037), com o
## resultado bruto por batalha + um resumo agregado. Fases independentes
## de propósito, para nunca depender de uma execução única de longa
## duração num ambiente sem esse tipo de garantia.

const COMBAT_SEED_BASE: int = 37000
const FORMATION_RNG_SEED: int = 38000
const ENEMY_GENERATION_RNG_SEED: int = 39000
const FORMATIONS_PER_MATCHUP: int = 1000
const ENEMIES_PER_STARTER: int = 1000

var _factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
var _options_by_faction: Dictionary = {}


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "all")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_options_by_faction[option["faction"]] = option

	match phase:
		"fixed":
			_run_phase_fixed_vs_fixed()
		"random_formation":
			_run_phase_random_formation()
		"random_enemy":
			_run_phase_random_enemy()
		_:
			_run_phase_fixed_vs_fixed()
			_run_phase_random_formation()
			_run_phase_random_enemy()

	get_tree().quit()


func _arg_value(prefix: String, default_value: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return default_value


# ---------------------------------------------------------------------------
# Utilidades comuns
# ---------------------------------------------------------------------------

func _army_from_option(option: Dictionary, cards_override: Array[CardResource] = []) -> Army:
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = cards_override if not cards_override.is_empty() else (option["cards"] as Array[CardResource]).duplicate()
	return army


## Fisher-Yates com o RNG do chamador (nunca o RNG global) — determinístico
## e reproduzível a partir de uma única seed, sem depender de Array.shuffle().
func _shuffled_copy(cards: Array[CardResource], rng: RandomNumberGenerator) -> Array[CardResource]:
	var copy: Array[CardResource] = cards.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: CardResource = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy


func _formation_key(cards: Array[CardResource]) -> String:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name)
	return "|".join(names)


## Métricas de UM lado já finalizado (state.units inclui vivos e mortos —
## HP/current_esc dos mortos já é 0/como ficou no momento da morte, então
## soma-se sobre TODAS as unidades do lado, não só as vivas, para obter
## HP restante real do Exército). "starting_position_1" é passado por
## quem chama (capturado ANTES de CombatEngine.run(), nunca lido daqui)
## — ver nota em _run_and_record(): ler a Posição 1 do "state" já
## finalizado reflete quem SOBREVIVEU ali no final, não quem começou a
## batalha ali (a informação que "influência da posição 1" realmente
## precisa).
func _side_metrics(state: CombatState, side: int, faction_label: String, starting_position_1: Dictionary) -> Dictionary:
	var alive: Array[CombatUnit] = state.units_of_side(side, true)
	var all_units: Array[CombatUnit] = []
	for unit: CombatUnit in state.units:
		if unit.side == side:
			all_units.append(unit)

	var hp_remaining: int = 0
	var hp_max: int = 0
	for unit: CombatUnit in all_units:
		hp_remaining += maxi(unit.current_hp, 0)
		hp_max += unit.card.hp

	return {
		"faction": faction_label,
		"survivors": alive.size(),
		"hp_remaining": hp_remaining,
		"hp_max": hp_max,
		"hp_pct_remaining": (float(hp_remaining) / float(hp_max)) if hp_max > 0 else 0.0,
		"affinity_points": state.affinity_points.get(side, {}),
		"affinity_levels": state.affinity_levels.get(side, {}),
		"starting_position_1_card": starting_position_1.get("card_name", ""),
		"starting_position_1_class": starting_position_1.get("card_class", ""),
	}


func _formation_order_names(cards: Array[CardResource]) -> Array[String]:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name)
	return names


## Executa UMA batalha (Inicialização + snapshot da Posição 1 inicial de
## cada lado ANTES de correr o turno 1, depois CombatEngine.run() até o
## fim) e monta o registro completo. Usado pelas 3 fases — nenhuma
## delas chama CombatEngine.run_battle()/initialize() diretamente, para
## garantir que TODAS capturem a Posição 1 real de partida, não a
## sobrevivente no fim (ver _side_metrics()).
##
## "formation_b_order" só preenchido quando o Lado B usa uma formação
## sorteada (fase 2); vazio nas demais (fase 1 usa a formação canônica
## dos dois lados; fase 3 usa a formação normal do EnemyArmyGenerator/
## ArmyPositioningHeuristic).
func _run_and_record(
	army_a: Army, army_b: Army, seed_value: int,
	faction_a: String, faction_b: String,
	formation_b_order: Array[String] = [],
	enemy_composition: Array[Dictionary] = []
) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)

	var starting_p1: Dictionary = {0: {}, 1: {}}
	for side: int in [0, 1]:
		var unit: CombatUnit = state.unit_at(side, 1)
		if unit != null:
			starting_p1[side] = {"card_name": unit.card.card_name, "card_class": unit.card.card_class}

	CombatEngine.run(state)

	var side_a: Dictionary = _side_metrics(state, 0, faction_a, starting_p1[0])
	var side_b: Dictionary = _side_metrics(state, 1, faction_b, starting_p1[1])

	var winner_label: String = "empate"
	if state.winner_side == 0:
		winner_label = "A"
	elif state.winner_side == 1:
		winner_label = "B"

	return {
		"battle_id": state.battle_id,
		"seed": state.seed_value,
		"winner": winner_label,
		"end_reason": state.end_reason,
		"turns": state.turn,
		"battlefield": state.battlefield.battlefield_name if state.battlefield != null else "",
		"side_a": side_a,
		"side_b": side_b,
		"margin_survivors": side_a["survivors"] - side_b["survivors"],
		"margin_hp_pct": side_a["hp_pct_remaining"] - side_b["hp_pct_remaining"],
		"formation_b_order": formation_b_order,
		"enemy_composition": enemy_composition,
	}


func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("  Escrito: %s" % path)


# ---------------------------------------------------------------------------
# Fase 1 — Fixed x Fixed (1 batalha por confronto, referência)
# ---------------------------------------------------------------------------

func _run_phase_fixed_vs_fixed() -> void:
	print("=== F-037 Fase 1: Fixed x Fixed (referência, 1 batalha por confronto) ===")
	var matchups: Array = [["Império", "Natureza"], ["Império", "Mortos-Vivos"], ["Natureza", "Mortos-Vivos"]]
	var records: Array = []

	for i in range(matchups.size()):
		var matchup: Array = matchups[i]
		var army_a: Army = _army_from_option(_options_by_faction[matchup[0]])
		var army_b: Army = _army_from_option(_options_by_faction[matchup[1]])
		var record: Dictionary = _run_and_record(army_a, army_b, COMBAT_SEED_BASE + i, matchup[0], matchup[1])
		records.append(record)
		print("  %s x %s -> vencedor: %s (%s) | turnos: %d | margem sobreviventes: %d | margem HP%%: %.3f" % [
			matchup[0], matchup[1], record["winner"], record["end_reason"], record["turns"], record["margin_survivors"], record["margin_hp_pct"]
		])

	_write_json("res://reports/f037_phase1_fixed_vs_fixed.json", {"phase": "fixed_vs_fixed", "battles": records})


# ---------------------------------------------------------------------------
# Fase 2 — Fixed (canônico) x mesmo Starter oposto com formação aleatória
# (1000 formações únicas por confronto, 6 confrontos: 3 pares x 2 direções)
# ---------------------------------------------------------------------------

func _run_phase_random_formation() -> void:
	print("=== F-037 Fase 2: Fixed x Random-Formation (%d formações únicas x 6 confrontos) ===" % FORMATIONS_PER_MATCHUP)
	var directed_matchups: Array = [
		["Império", "Natureza"], ["Império", "Mortos-Vivos"], ["Natureza", "Mortos-Vivos"],
		["Natureza", "Império"], ["Mortos-Vivos", "Império"], ["Mortos-Vivos", "Natureza"],
	]

	var formation_rng := RandomNumberGenerator.new()
	formation_rng.seed = FORMATION_RNG_SEED
	var battle_seed_counter: int = COMBAT_SEED_BASE + 100

	for matchup: Array in directed_matchups:
		var fixed_faction: String = matchup[0]
		var random_faction: String = matchup[1]
		var fixed_option: Dictionary = _options_by_faction[fixed_faction]
		var random_option: Dictionary = _options_by_faction[random_faction]
		var random_base_cards: Array[CardResource] = random_option["cards"]

		var seen_formations: Dictionary = {}
		var records: Array = []
		var wins_a: int = 0
		var wins_b: int = 0
		var draws: int = 0
		var decided_by_elimination: int = 0
		var decided_by_turn_limit: int = 0
		var best_record: Dictionary = {}
		var worst_record: Dictionary = {}

		var generated: int = 0
		while generated < FORMATIONS_PER_MATCHUP:
			var shuffled: Array[CardResource] = _shuffled_copy(random_base_cards, formation_rng)
			var key: String = _formation_key(shuffled)
			if seen_formations.has(key):
				continue
			seen_formations[key] = true
			generated += 1

			var army_a: Army = _army_from_option(fixed_option)
			var army_b: Army = _army_from_option(random_option, shuffled)
			var record: Dictionary = _run_and_record(army_a, army_b, battle_seed_counter, fixed_faction, random_faction, _formation_order_names(shuffled))
			battle_seed_counter += 1
			records.append(record)

			match record["winner"]:
				"A": wins_a += 1
				"B": wins_b += 1
				_: draws += 1
			if record["end_reason"] == "limite_de_turnos":
				decided_by_turn_limit += 1
			else:
				decided_by_elimination += 1

			# "Melhor"/"pior" formação (para o lado B, o lado aleatorizado):
			# maior/menor margem de HP%% a favor de B — 1 amostra por
			# formação (não repetida), então isto é observacional, não uma
			# média robusta por formação.
			var margin_for_b: float = -record["margin_hp_pct"]
			if best_record.is_empty() or margin_for_b > (-best_record["margin_hp_pct"]):
				best_record = record
			if worst_record.is_empty() or margin_for_b < (-worst_record["margin_hp_pct"]):
				worst_record = record

		var summary: Dictionary = {
			"fixed_faction": fixed_faction,
			"random_faction": random_faction,
			"total_battles": generated,
			"wins_fixed_a": wins_a,
			"wins_random_b": wins_b,
			"draws": draws,
			"decided_by_elimination": decided_by_elimination,
			"decided_by_turn_limit": decided_by_turn_limit,
			"best_formation_for_random_side": best_record,
			"worst_formation_for_random_side": worst_record,
		}
		print("  %s(fixo) x %s(aleatório, %d formações) -> A venceu: %d | B venceu: %d | empates: %d | eliminação: %d | limite de turnos: %d" % [
			fixed_faction, random_faction, generated, wins_a, wins_b, draws, decided_by_elimination, decided_by_turn_limit
		])

		_write_json(
			"res://reports/f037_phase2_%s_fixed_vs_%s_random.json" % [fixed_faction, random_faction],
			{"phase": "random_formation", "summary": summary, "battles": records}
		)


# ---------------------------------------------------------------------------
# Fase 3 — Starter x inimigo Tier I / Comum realmente aleatório
# (1000 por Starter = 3000 batalhas)
# ---------------------------------------------------------------------------

func _run_phase_random_enemy() -> void:
	print("=== F-037 Fase 3: Starter x Inimigo Aleatório (Tier I/Comum, %d por Starter) ===" % ENEMIES_PER_STARTER)
	var enemy_generation_rng := RandomNumberGenerator.new()
	enemy_generation_rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()
	var battle_seed_counter: int = COMBAT_SEED_BASE + 200000

	for starter_faction: String in _factions:
		var starter_option: Dictionary = _options_by_faction[starter_faction]
		var records: Array = []
		var wins_starter: int = 0
		var wins_enemy: int = 0
		var draws: int = 0
		var decided_by_elimination: int = 0
		var decided_by_turn_limit: int = 0

		for i in range(ENEMIES_PER_STARTER):
			# Facção do inimigo também sorteada (geração realmente
			# aleatória) — consumida do MESMO stream do gerador, antes de
			# EnemyArmyGenerator.generate() usar o restante da sequência.
			var enemy_faction: String = _factions[enemy_generation_rng.randi_range(0, _factions.size() - 1)]

			var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
				EnemyArmyEntry.Category.NORMAL, enemy_faction, 1, GameDatabase.cards, season_config,
				GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
				GameDatabase.commander_effects, GameDatabase.commander_values,
				"f037_%s" % starter_faction, i, true, enemy_generation_rng
			)
			var enemy_army := Army.new()
			enemy_army.commander = entry.commander
			enemy_army.cards = entry.cards

			var enemy_composition: Array[Dictionary] = []
			for card: CardResource in entry.cards:
				enemy_composition.append({"card_name": card.card_name, "faction": card.faction, "card_class": card.card_class, "rarity": card.rarity, "tier": card.tier})

			var army_a: Army = _army_from_option(starter_option)
			var record: Dictionary = _run_and_record(army_a, enemy_army, battle_seed_counter, starter_faction, enemy_faction, [], enemy_composition)
			battle_seed_counter += 1
			records.append(record)

			match record["winner"]:
				"A": wins_starter += 1
				"B": wins_enemy += 1
				_: draws += 1
			if record["end_reason"] == "limite_de_turnos":
				decided_by_turn_limit += 1
			else:
				decided_by_elimination += 1

		var summary: Dictionary = {
			"starter_faction": starter_faction,
			"total_battles": ENEMIES_PER_STARTER,
			"wins_starter": wins_starter,
			"wins_enemy": wins_enemy,
			"draws": draws,
			"decided_by_elimination": decided_by_elimination,
			"decided_by_turn_limit": decided_by_turn_limit,
		}
		print("  Starter %s x %d inimigos Tier I/Comum aleatórios -> Starter venceu: %d | Inimigo venceu: %d | empates: %d | eliminação: %d | limite de turnos: %d" % [
			starter_faction, ENEMIES_PER_STARTER, wins_starter, wins_enemy, draws, decided_by_elimination, decided_by_turn_limit
		])

		_write_json(
			"res://reports/f037_phase3_starter_%s_vs_random_enemy.json" % starter_faction,
			{"phase": "random_enemy", "summary": summary, "battles": records}
		)
