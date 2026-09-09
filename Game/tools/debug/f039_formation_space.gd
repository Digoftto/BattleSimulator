extends Node
## f039_formation_space.gd (F-039)
##
## Amostra o ESPAÇO de formações de cada Starter (1.000 formações únicas
## das mesmas 9 cartas, Fisher-Yates com RNG seedado, nunca Array.shuffle()
## global) contra uma amostra fixa de inimigos Tier I/Comum (mesma
## sequência de geração de F-037/F-038 — bit-idênticos). NÃO toca
## StarterKitResolver, CardResource, EnemyArmyGenerator,
## ArmyPositioningHeuristic, CombatEngine ou AffinityRuntime — só chama
## o que já existe, e só LÊ (nunca escreve) o multiplicador de Afinidade
## já calculado por AffinityRuntime via um ouvinte de evento comum
## (CombatEventBus.TURN_START, já público), para medir por quanto tempo
## a Afinidade II do Império permanece geometricamente ativa durante a
## batalha — instrumentação por fora, nenhuma linha de regra tocada.
##
## Fases (via --phase=, sempre reunindo tudo o que já foi salvo antes):
##   setup       — gera as 1.000 formações + a amostra de inimigos por
##                 Starter (idênticos a F-037/038), com checagem de
##                 reprodutibilidade contra o F-038 salvo.
##   sweep       — para um Starter (--starter=), roda as 1.000 formações
##                 x amostra principal de inimigos (10 por formação).
##   robustness  — para um Starter, roda o Top 10 (lido de
##                 f039_top10_<starter>.json, produzido por análise
##                 externa após o sweep) contra 200 inimigos "held-out"
##                 (nunca usados no sweep principal).
##
## Uso:
##   godot --headless --path Game res://tools/debug/f039_formation_space.tscn -- --phase=setup
##   godot --headless --path Game res://tools/debug/f039_formation_space.tscn -- --phase=sweep --starter=Império
##   godot --headless --path Game res://tools/debug/f039_formation_space.tscn -- --phase=robustness --starter=Império

const FORMATION_SPACE_SEED: int = 41000  # documentada — geração das 1.000 formações/Starter
const ENEMY_GENERATION_RNG_SEED: int = 39000  # idêntica a F-037/F-038
const FORMATIONS_PER_STARTER: int = 1000
const MAIN_SAMPLE_SIZE: int = 10  # inimigos por formação no sweep principal — ver justificativa no relatório F-039
const HELD_OUT_SAMPLE_SIZE: int = 200  # inimigos NUNCA usados no sweep, só na robustez (Top 10)
const ENEMY_POOL_SIZE: int = FORMATIONS_PER_STARTER  # gera 1.000 por Starter (mesmo tamanho de F-037/038); main_sample = primeiros 10, held_out = próximos 200

var _factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
var _options_by_faction: Dictionary = {}


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "setup")
	var starter_arg: String = _arg_value("--starter=", "")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_options_by_faction[option["faction"]] = option

	match phase:
		"setup":
			_run_setup()
		"sweep":
			_run_sweep(starter_arg)
		"robustness":
			_run_robustness(starter_arg)
		"heuristic_check":
			_run_heuristic_check(starter_arg)
		_:
			print("Fase desconhecida: %s" % phase)

	get_tree().quit()


func _arg_value(prefix: String, default_value: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return default_value


func _write_json(path: String, data) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("  Escrito: %s" % path)


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	return JSON.parse_string(text)


# ---------------------------------------------------------------------------
# FASE setup — formações + inimigos, uma vez, reaproveitados por todas as
# outras fases.
# ---------------------------------------------------------------------------

func _run_setup() -> void:
	print("=== F-039 setup: 1.000 formações/Starter + amostra de inimigos (idêntica a F-037/038) ===")
	_generate_formations()
	_generate_enemies_and_verify()


func _formation_key(cards: Array[CardResource]) -> String:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name)
	return "|".join(names)


func _shuffled_copy(cards: Array[CardResource], rng: RandomNumberGenerator) -> Array[CardResource]:
	var copy: Array[CardResource] = cards.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: CardResource = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy


## Pontos/Nível de Afinidade não dependem de posição — calculados uma vez
## por Starter (reaproveita Affinity.gd diretamente, sem rodar batalha).
func _initial_affinity(cards: Array[CardResource], commander: CommanderResource) -> Dictionary:
	var factions: Array[String] = []
	for card: CardResource in cards:
		if not factions.has(card.faction):
			factions.append(card.faction)
	if commander != null and not factions.has(commander.faction):
		factions.append(commander.faction)

	var points: Dictionary = {}
	var levels: Dictionary = {}
	for faction: String in factions:
		var p: int = Affinity.calculate_points(faction, cards, commander)
		points[faction] = p
		levels[faction] = Affinity.highest_active_level(p)
	return {"points": points, "levels": levels}


func _generate_formations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = FORMATION_SPACE_SEED

	for starter_faction: String in _factions:
		var option: Dictionary = _options_by_faction[starter_faction]
		var base_cards: Array[CardResource] = option["cards"]
		var commander: CommanderResource = option["commander"]
		var affinity: Dictionary = _initial_affinity(base_cards, commander)

		var seen: Dictionary = {}
		var formations: Array = []
		var generated: int = 0
		while generated < FORMATIONS_PER_STARTER:
			var shuffled: Array[CardResource] = _shuffled_copy(base_cards, rng)
			var key: String = _formation_key(shuffled)
			if seen.has(key):
				continue
			seen[key] = true

			var order: Array[String] = []
			var classes: Array[String] = []
			var factions_per_card: Array[String] = []
			for card: CardResource in shuffled:
				order.append(card.card_name)
				classes.append(card.card_class)
				factions_per_card.append(card.faction)

			formations.append({
				"formation_id": generated,
				"seed": FORMATION_SPACE_SEED,
				"order": order,
				"classes": classes,
				"factions": factions_per_card,
				"position_1_card": order[0],
				"position_1_class": classes[0],
				"affinity_points": affinity["points"],
				"affinity_levels": affinity["levels"],
			})
			generated += 1

		print("  %s: %d formações únicas geradas (seed %d)" % [starter_faction, formations.size(), FORMATION_SPACE_SEED])
		_write_json("res://reports/f039_formations_%s.json" % starter_faction, {"starter_faction": starter_faction, "seed": FORMATION_SPACE_SEED, "formations": formations})


func _generate_enemies_and_verify() -> void:
	var enemy_generation_rng := RandomNumberGenerator.new()
	enemy_generation_rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()

	for starter_faction: String in _factions:
		var entries: Array = []
		for i in range(ENEMY_POOL_SIZE):
			var enemy_faction: String = _factions[enemy_generation_rng.randi_range(0, _factions.size() - 1)]
			var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
				EnemyArmyEntry.Category.NORMAL, enemy_faction, 1, GameDatabase.cards, season_config,
				GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
				GameDatabase.commander_effects, GameDatabase.commander_values,
				"f037_%s" % starter_faction, i, true, enemy_generation_rng
			)
			var composition: Array[Dictionary] = []
			var order: Array[String] = []
			for card: CardResource in entry.cards:
				composition.append({"card_name": card.card_name, "faction": card.faction, "card_class": card.card_class, "rarity": card.rarity, "tier": card.tier})
				order.append(card.card_name)
			entries.append({
				"enemy_id": i,
				"enemy_faction": enemy_faction,
				"commander_faction": entry.commander.faction,
				"order": order,
				"composition": composition,
			})

		# Checagem de reprodutibilidade contra o F-038 salvo (mesma
		# sequência de RNG/gerador) — só compara o primeiro inimigo, que
		# já é suficiente para provar a reprodução bit-a-bit da sequência
		# (RNG determinístico consumido sequencialmente).
		var f038_path: String = "res://reports/f038_starter_%s.json" % starter_faction
		var f038_data: Variant = _read_json(f038_path)
		var reproducibility_note: String = "f038 não encontrado, sem verificação cruzada"
		if f038_data != null:
			var f038_first_enemy: Array = f038_data["battles_a_canonical"][0]["enemy_composition"]
			var f038_first_names: Array[String] = []
			for c: Dictionary in f038_first_enemy:
				f038_first_names.append(c["card_name"])
			var matches: bool = f038_first_names == (entries[0]["order"] as Array)
			reproducibility_note = "primeiro inimigo idêntico ao F-038: %s" % str(matches)
			print("  %s: %s" % [starter_faction, reproducibility_note])

		_write_json(
			"res://reports/f039_enemies_%s.json" % starter_faction,
			{
				"starter_faction": starter_faction,
				"seed": ENEMY_GENERATION_RNG_SEED,
				"reproducibility_check": reproducibility_note,
				"main_sample_ids": range(0, MAIN_SAMPLE_SIZE),
				"held_out_sample_ids": range(MAIN_SAMPLE_SIZE, MAIN_SAMPLE_SIZE + HELD_OUT_SAMPLE_SIZE),
				"entries": entries,
			}
		)


# ---------------------------------------------------------------------------
# Utilidades de batalha compartilhadas entre sweep/robustness
# ---------------------------------------------------------------------------

func _army_from_names(commander: CommanderResource, card_names: Array, catalog_by_name: Dictionary) -> Army:
	var army := Army.new()
	army.commander = commander
	var cards: Array[CardResource] = []
	for name in card_names:
		cards.append((catalog_by_name[name] as CardResource).duplicate())
	army.cards = cards
	return army


func _catalog_by_name() -> Dictionary:
	var by_name: Dictionary = {}
	for card: CardResource in GameDatabase.cards:
		by_name[card.card_name] = card
	return by_name


## Roda uma batalha e devolve um registro COMPACTO (sem duplicar a
## composição/formação completa por linha — essas já vivem nos arquivos
## de formações/inimigos, referenciadas por id). Posição 1 já vem do
## registro de formação/inimigo (array[0]), não precisa reler do state.
## "track_imperio_l2" liga um ouvinte de TURN_START (evento já público,
## nenhuma alteração de CombatEngine/AffinityRuntime) que só LÊ
## CombatUnit.affinity_incoming_damage_multiplier já calculado, para
## medir por quantos turnos a Afinidade II do Império ficou
## geometricamente ativa nesta batalha.
func _run_one(army_a: Army, army_b: Army, seed_value: int, track_imperio_l2_side: int = -1) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)

	# GDScript captura variáveis locais de tipo valor (int/float/bool) POR
	# VALOR dentro de uma lambda — um Dictionary (tipo por referência) é o
	# jeito padrão de mutar um contador de dentro de um Callable (mesmo
	# padrão já documentado em tests/unit/test_battle_determinism.gd).
	# TURN_END (não TURN_START): TURN_START é publicado ANTES de
	# _environment_update_phase() recalcular o snapshot de Afinidade
	# DAQUELE turno (COMBAT_RULES.md 3.2) — ler o multiplicador ali
	# capturaria o valor congelado do turno ANTERIOR. TURN_END é
	# publicado depois de todo o turno (Ambiente + Movimento + Seleção +
	# Execução + Resolução das Mortes) já ter rodado, refletindo
	# corretamente o snapshot QUE VALEU durante aquele turno.
	var l2_counters: Dictionary = {"l2_turns": 0, "total_turns": 0}
	if track_imperio_l2_side >= 0:
		state.event_bus.subscribe(CombatEventType.Type.TURN_END, func(_type: CombatEventType.Type, _ctx: CombatContext) -> void:
			l2_counters["total_turns"] += 1
			for unit: CombatUnit in state.units_of_side(track_imperio_l2_side, true):
				if unit.card.faction == "Império" and unit.affinity_incoming_damage_multiplier < 1.0:
					l2_counters["l2_turns"] += 1
					return
		)

	CombatEngine.run(state)

	var record: Dictionary = {
		"seed": state.seed_value,
		"winner": ("A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")),
		"end_reason": state.end_reason,
		"turns": state.turn,
		"battlefield": state.battlefield.battlefield_name if state.battlefield != null else "",
		"survivors_a": state.units_of_side(0, true).size(),
		"survivors_b": state.units_of_side(1, true).size(),
		"hp_pct_a": _hp_pct(state, 0),
		"hp_pct_b": _hp_pct(state, 1),
		"affinity_points_a_final": state.affinity_points.get(0, {}),
		"affinity_levels_a_final": state.affinity_levels.get(0, {}),
		"affinity_points_b_final": state.affinity_points.get(1, {}),
		"affinity_levels_b_final": state.affinity_levels.get(1, {}),
	}
	record["margin_survivors"] = record["survivors_a"] - record["survivors_b"]
	record["margin_hp_pct"] = record["hp_pct_a"] - record["hp_pct_b"]
	if track_imperio_l2_side >= 0:
		record["imperio_l2_turns"] = l2_counters["l2_turns"]
		record["total_turns_observed"] = l2_counters["total_turns"]
	return record


func _hp_pct(state: CombatState, side: int) -> float:
	var hp_remaining: int = 0
	var hp_max: int = 0
	for unit: CombatUnit in state.units:
		if unit.side == side:
			hp_remaining += maxi(unit.current_hp, 0)
			hp_max += unit.card.hp
	return (float(hp_remaining) / float(hp_max)) if hp_max > 0 else 0.0


# ---------------------------------------------------------------------------
# FASE sweep — 1.000 formações x amostra principal (10 inimigos) por Starter
# ---------------------------------------------------------------------------

func _run_sweep(starter_faction: String) -> void:
	if not _options_by_faction.has(starter_faction):
		print("Starter inválido: '%s' (use Império, Natureza ou Mortos-Vivos)" % starter_faction)
		return

	var formations_data: Dictionary = _read_json("res://reports/f039_formations_%s.json" % starter_faction)
	var enemies_data: Dictionary = _read_json("res://reports/f039_enemies_%s.json" % starter_faction)
	if formations_data == null or enemies_data == null:
		print("Rode a fase 'setup' primeiro (arquivos de formações/inimigos não encontrados).")
		return

	var catalog: Dictionary = _catalog_by_name()
	var commander: CommanderResource = _options_by_faction[starter_faction]["commander"]
	var starter_index: int = _factions.find(starter_faction)
	var seed_base: int = 1000000 * (starter_index + 1)

	var main_sample_ids: Array = enemies_data["main_sample_ids"]
	var enemy_entries: Array = enemies_data["entries"]
	var track_side: int = 0 if starter_faction == "Império" else -1

	var battles: Array = []
	var formations: Array = formations_data["formations"]
	var t_start: int = Time.get_ticks_msec()

	for formation: Dictionary in formations:
		var formation_id: int = formation["formation_id"]
		var army_a: Army = _army_from_names(commander, formation["order"], catalog)

		for enemy_id in main_sample_ids:
			var enemy_entry: Dictionary = enemy_entries[enemy_id]
			var enemy_commander := CommanderResource.new()
			enemy_commander.commander_name = "Enemy"
			enemy_commander.faction = enemy_entry["commander_faction"]
			var army_b: Army = _army_from_names(enemy_commander, enemy_entry["order"], catalog)

			var combat_seed: int = seed_base + formation_id * 1000 + int(enemy_id)
			var record: Dictionary = _run_one(army_a, army_b, combat_seed, track_side)
			record["formation_id"] = formation_id
			record["enemy_id"] = enemy_id
			record["enemy_faction"] = enemy_entry["enemy_faction"]
			battles.append(record)

		if formation_id % 100 == 0:
			var elapsed: float = float(Time.get_ticks_msec() - t_start) / 1000.0
			print("  %s: formação %d/%d (%.1fs decorridos)" % [starter_faction, formation_id, formations.size(), elapsed])

	print("  %s: sweep completo — %d batalhas em %.1fs" % [starter_faction, battles.size(), float(Time.get_ticks_msec() - t_start) / 1000.0])
	_write_json("res://reports/f039_sweep_%s.json" % starter_faction, {"starter_faction": starter_faction, "main_sample_size": MAIN_SAMPLE_SIZE, "battles": battles})


# ---------------------------------------------------------------------------
# FASE robustness — Top 10 (lido de f039_top10_<starter>.json, produzido
# por análise externa do sweep) x 200 inimigos held-out (nunca usados no
# sweep principal).
# ---------------------------------------------------------------------------

func _run_robustness(starter_faction: String) -> void:
	if not _options_by_faction.has(starter_faction):
		print("Starter inválido: '%s'" % starter_faction)
		return

	var top10_data: Dictionary = _read_json("res://reports/f039_top10_%s.json" % starter_faction)
	var enemies_data: Dictionary = _read_json("res://reports/f039_enemies_%s.json" % starter_faction)
	if top10_data == null or enemies_data == null:
		print("Rode 'setup' + 'sweep' + a análise de ranking (f039_top10_%s.json) primeiro." % starter_faction)
		return

	var catalog: Dictionary = _catalog_by_name()
	var commander: CommanderResource = _options_by_faction[starter_faction]["commander"]
	var starter_index: int = _factions.find(starter_faction)
	var seed_base: int = 5000000 * (starter_index + 1)

	var held_out_ids: Array = enemies_data["held_out_sample_ids"]
	var enemy_entries: Array = enemies_data["entries"]
	var track_side: int = 0 if starter_faction == "Império" else -1

	var results_by_formation: Dictionary = {}
	var t_start: int = Time.get_ticks_msec()

	for entry: Dictionary in (top10_data["top_formations"] as Array):
		var formation_id: int = entry["formation_id"]
		var rank: int = entry["rank"]
		var army_a: Army = _army_from_names(commander, entry["order"], catalog)

		var battles: Array = []
		for enemy_id in held_out_ids:
			var enemy_entry: Dictionary = enemy_entries[enemy_id]
			var enemy_commander := CommanderResource.new()
			enemy_commander.commander_name = "Enemy"
			enemy_commander.faction = enemy_entry["commander_faction"]
			var army_b: Army = _army_from_names(enemy_commander, enemy_entry["order"], catalog)

			var combat_seed: int = seed_base + rank * 10000 + int(enemy_id)
			var record: Dictionary = _run_one(army_a, army_b, combat_seed, track_side)
			record["enemy_id"] = enemy_id
			record["enemy_faction"] = enemy_entry["enemy_faction"]
			battles.append(record)

		results_by_formation[str(formation_id)] = {"rank": rank, "formation_id": formation_id, "sweep_summary": entry, "held_out_battles": battles}
		print("  %s: robustez do rank %d (formação %d) — %d batalhas held-out completas (%.1fs decorridos)" % [
			starter_faction, rank, formation_id, battles.size(), float(Time.get_ticks_msec() - t_start) / 1000.0
		])

	_write_json("res://reports/f039_robustness_%s.json" % starter_faction, {"starter_faction": starter_faction, "held_out_sample_size": held_out_ids.size(), "results_by_formation": results_by_formation})


# ---------------------------------------------------------------------------
# FASE heuristic_check — Experimento J: onde a formação de
# ArmyPositioningHeuristic cai dentro da distribuição de 1.000 formações
# aleatórias? Roda a MESMA formação heurística contra (a) a amostra
# principal de 10 inimigos (mesma usada pelo sweep — comparação direta,
# maçãs-com-maçãs dentro da distribuição) e (b) o pool inteiro de 1.000
# inimigos (estimativa de win rate mais precisa, no mesmo espírito do F-038).
# ---------------------------------------------------------------------------

func _run_heuristic_check(starter_faction: String) -> void:
	if not _options_by_faction.has(starter_faction):
		print("Starter inválido: '%s'" % starter_faction)
		return

	var enemies_data: Dictionary = _read_json("res://reports/f039_enemies_%s.json" % starter_faction)
	if enemies_data == null:
		print("Rode 'setup' primeiro.")
		return

	var catalog: Dictionary = _catalog_by_name()
	var option: Dictionary = _options_by_faction[starter_faction]
	var commander: CommanderResource = option["commander"]
	var canonical_cards: Array[CardResource] = option["cards"]
	var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic(canonical_cards.duplicate())
	var heuristic_order: Array[String] = []
	for card: CardResource in heuristic_cards:
		heuristic_order.append(card.card_name)

	var starter_index: int = _factions.find(starter_faction)
	var seed_base: int = 9000000 * (starter_index + 1)
	var track_side: int = 0 if starter_faction == "Império" else -1
	var enemy_entries: Array = enemies_data["entries"]

	var battles_main_sample: Array = []
	for enemy_id in (enemies_data["main_sample_ids"] as Array):
		var enemy_entry: Dictionary = enemy_entries[enemy_id]
		var enemy_commander := CommanderResource.new()
		enemy_commander.commander_name = "Enemy"
		enemy_commander.faction = enemy_entry["commander_faction"]
		var army_a: Army = _army_from_names(commander, heuristic_order, catalog)
		var army_b: Army = _army_from_names(enemy_commander, enemy_entry["order"], catalog)
		var record: Dictionary = _run_one(army_a, army_b, seed_base + int(enemy_id), track_side)
		record["enemy_id"] = enemy_id
		battles_main_sample.append(record)

	var battles_full_pool: Array = []
	for enemy_id in range(enemy_entries.size()):
		var enemy_entry: Dictionary = enemy_entries[enemy_id]
		var enemy_commander := CommanderResource.new()
		enemy_commander.commander_name = "Enemy"
		enemy_commander.faction = enemy_entry["commander_faction"]
		var army_a: Army = _army_from_names(commander, heuristic_order, catalog)
		var army_b: Army = _army_from_names(enemy_commander, enemy_entry["order"], catalog)
		var record: Dictionary = _run_one(army_a, army_b, seed_base + 100000 + enemy_id, -1)
		record["enemy_id"] = enemy_id
		battles_full_pool.append(record)

	print("  %s: heuristic_check — %d (amostra principal) + %d (pool completo) batalhas" % [starter_faction, battles_main_sample.size(), battles_full_pool.size()])
	_write_json(
		"res://reports/f039_heuristic_check_%s.json" % starter_faction,
		{
			"starter_faction": starter_faction,
			"heuristic_order": heuristic_order,
			"battles_main_sample": battles_main_sample,
			"battles_full_pool": battles_full_pool,
		}
	)
