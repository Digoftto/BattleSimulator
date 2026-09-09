extends Node
## f040_imperio_diagnosis.gd (F-040)
##
## Diagnóstico da composição do Starter Império. NÃO altera nenhum card,
## StarterKitResolver, CombatEngine ou AffinityRuntime. Toda instrumentação
## é feita por fora, via CombatEventBus (já público) e leitura de campos já
## calculados (CombatUnit.affinity_incoming_damage_multiplier etc.) — nunca
## escreve em nada que pertença ao motor.
##
## Fases (--phase=):
##   controlled   — Império/Natureza/Mortos-Vivos, formação heuristic,
##                   MESMOS 50 inimigos (reproduzidos com a seed de
##                   F-037/038/039), dano/cura/sobrevivência agregados +
##                   checkpoints de sobreviventes por turno.
##   ablation     — Império: baseline + 5 variantes de troca de 1-3 cartas
##                   (só cartas já existentes no catálogo), mesma
##                   heurística de posicionamento, mesmos 50 inimigos.
##   turnlog      — 9 batalhas totalmente logadas turno-a-turno (3
##                   Facções x 3 inimigos), para leitura qualitativa.
##   formation_tiers — Império em 4 formações (heuristic, top-robusta do
##                   F-039, mediana, ruim) x 30 inimigos cada.

const ENEMY_GENERATION_RNG_SEED: int = 39000  # idêntica a F-037/038/039
const CONTROLLED_SAMPLE_SIZE: int = 50
const ABLATION_SAMPLE_SIZE: int = 50
const FORMATION_TIER_SAMPLE_SIZE: int = 30

var _factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
var _options_by_faction: Dictionary = {}
var _catalog: Dictionary = {}


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "controlled")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_options_by_faction[option["faction"]] = option
	for card: CardResource in GameDatabase.cards:
		_catalog[card.card_name] = card

	match phase:
		"controlled":
			_run_controlled_comparison()
		"ablation":
			_run_ablation()
		"turnlog":
			_run_turnlog()
		"formation_tiers":
			_run_formation_tiers()
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


## Reproduz a MESMA sequência de geração de inimigos de F-037/038/039
## (mesma seed, mesma ordem de chamadas) e devolve os primeiros "count"
## por Starter — usa os índices 210+ (nunca tocados nem pelo sweep
## principal nem pelo held-out do F-039) para esta nova amostra
## controlada, evitando reaproveitar exatamente os mesmos 210 já vistos
## por experimentos anteriores.
func _generate_enemy_pool(per_starter: int, skip: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()

	var pool: Dictionary = {}
	for starter_faction: String in _factions:
		var entries: Array[EnemyArmyEntry] = []
		for i in range(skip + per_starter):
			var enemy_faction: String = _factions[rng.randi_range(0, _factions.size() - 1)]
			var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
				EnemyArmyEntry.Category.NORMAL, enemy_faction, 1, GameDatabase.cards, season_config,
				GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
				GameDatabase.commander_effects, GameDatabase.commander_values,
				"f037_%s" % starter_faction, i, true, rng
			)
			if i >= skip:
				entries.append(entry)
		pool[starter_faction] = entries
	return pool


func _army_from_cards(commander: CommanderResource, cards: Array[CardResource]) -> Army:
	var army := Army.new()
	army.commander = commander
	army.cards = cards.duplicate()
	return army


func _army_from_entry(entry: EnemyArmyEntry) -> Army:
	var commander := CommanderResource.new()
	commander.commander_name = "Enemy"
	commander.faction = entry.commander.faction
	return _army_from_cards(commander, entry.cards)


# ---------------------------------------------------------------------------
# Batalha instrumentada — dano/cura agregados + checkpoints de
# sobreviventes por turno + status de Afinidade II do Império (quando
# aplicável). Tudo lido de eventos já públicos (CombatEventBus) ou campos
# já calculados pelo motor — nenhuma regra tocada.
# ---------------------------------------------------------------------------

func _run_instrumented(army_a: Army, army_b: Army, seed_value: int, track_imperio_side: int = -1) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var collector := BattleEventCollector.new()
	collector.attach(state.event_bus)

	var checkpoints: Dictionary = {"10": null, "20": null, "30": null, "40": null, "50": null, "64": null}
	var l2_counters: Dictionary = {"l2_turns": 0, "total_turns": 0, "protected_unit_turns": 0}

	state.event_bus.subscribe(CombatEventType.Type.TURN_END, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		var t: int = ctx.turn
		var key: String = str(t)
		if checkpoints.has(key):
			checkpoints[key] = {
				"survivors_a": state.units_of_side(0, true).size(),
				"survivors_b": state.units_of_side(1, true).size(),
			}
		if track_imperio_side >= 0:
			l2_counters["total_turns"] += 1
			var protected_count: int = 0
			for unit: CombatUnit in state.units_of_side(track_imperio_side, true):
				if unit.card.faction == "Império" and unit.affinity_incoming_damage_multiplier < 1.0:
					protected_count += 1
			if protected_count > 0:
				l2_counters["l2_turns"] += 1
				l2_counters["protected_unit_turns"] += protected_count
	)

	CombatEngine.run(state)

	var record: Dictionary = {
		"seed": state.seed_value,
		"winner": ("A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")),
		"end_reason": state.end_reason,
		"turns": state.turn,
		"survivors_a": state.units_of_side(0, true).size(),
		"survivors_b": state.units_of_side(1, true).size(),
		"hp_pct_a": _hp_pct(state, 0),
		"hp_pct_b": _hp_pct(state, 1),
		"total_damage_a": collector.total_damage_by_side().get(0, 0),
		"total_damage_b": collector.total_damage_by_side().get(1, 0),
		"total_healing_a": collector.total_healing_by_side().get(0, 0),
		"total_healing_b": collector.total_healing_by_side().get(1, 0),
		"total_shield_absorbed_a": collector.total_shield_absorbed_by_side().get(0, 0),
		"total_shield_absorbed_b": collector.total_shield_absorbed_by_side().get(1, 0),
		"attack_count_a": _count_attacks(collector, 0),
		"attack_count_b": _count_attacks(collector, 1),
		"failed_attack_count_a": _count_failed_attacks(collector, 0),
		"failed_attack_count_b": _count_failed_attacks(collector, 1),
		"first_death_turn_a": _first_death_turn(collector, 0),
		"first_death_turn_b": _first_death_turn(collector, 1),
		"checkpoints": checkpoints,
	}
	record["margin_survivors"] = record["survivors_a"] - record["survivors_b"]
	record["margin_hp_pct"] = record["hp_pct_a"] - record["hp_pct_b"]
	if track_imperio_side >= 0:
		record["imperio_l2_uptime_turns"] = l2_counters["l2_turns"]
		record["imperio_l2_total_turns"] = l2_counters["total_turns"]
		record["imperio_l2_protected_unit_turns"] = l2_counters["protected_unit_turns"]
	return record


func _hp_pct(state: CombatState, side: int) -> float:
	var hp_remaining: int = 0
	var hp_max: int = 0
	for unit: CombatUnit in state.units:
		if unit.side == side:
			hp_remaining += maxi(unit.current_hp, 0)
			hp_max += unit.card.hp
	return (float(hp_remaining) / float(hp_max)) if hp_max > 0 else 0.0


func _count_attacks(collector: BattleEventCollector, side: int) -> int:
	var count: int = 0
	for event: Dictionary in collector.attack_events:
		if event.get("side") == side:
			count += 1
	return count


func _count_failed_attacks(collector: BattleEventCollector, side: int) -> int:
	var count: int = 0
	for event: Dictionary in collector.attack_events:
		if event.get("side") == side and event.get("damage_dealt", 0) == 0:
			count += 1
	return count


func _first_death_turn(collector: BattleEventCollector, side: int) -> Variant:
	for event: Dictionary in collector.death_events:
		if event.get("side") == side:
			return event.get("turn")
	return null


# ---------------------------------------------------------------------------
# FASE controlled — Império/Natureza/Mortos-Vivos, formação heuristic,
# MESMOS 50 inimigos.
# ---------------------------------------------------------------------------

func _run_controlled_comparison() -> void:
	print("=== F-040 controlled: 3 Facções, formação heuristic, mesmos %d inimigos ===" % CONTROLLED_SAMPLE_SIZE)
	var pool: Dictionary = _generate_enemy_pool(CONTROLLED_SAMPLE_SIZE, 210)

	for starter_faction: String in _factions:
		var option: Dictionary = _options_by_faction[starter_faction]
		var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic((option["cards"] as Array).duplicate())
		var track_side: int = 0 if starter_faction == "Império" else -1

		var battles: Array = []
		var entries: Array = pool[starter_faction]
		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var army_a: Army = _army_from_cards(option["commander"], heuristic_cards)
			var army_b: Army = _army_from_entry(entry)
			var record: Dictionary = _run_instrumented(army_a, army_b, 20000000 + _factions.find(starter_faction) * 100000 + i, track_side)
			record["enemy_id"] = i
			record["enemy_faction"] = entry.faction
			battles.append(record)

		print("  %s: %d batalhas controladas completas" % [starter_faction, battles.size()])
		_write_json("res://reports/f040_controlled_%s.json" % starter_faction, {"starter_faction": starter_faction, "heuristic_formation": _order_names(heuristic_cards), "battles": battles})


func _order_names(cards: Array[CardResource]) -> Array[String]:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name)
	return names


# ---------------------------------------------------------------------------
# FASE ablation — Império: baseline + variantes de troca (só cartas já
# existentes no catálogo, nunca inventadas).
# ---------------------------------------------------------------------------

func _run_ablation() -> void:
	print("=== F-040 ablation: Império, baseline + variantes de troca ===")
	var option: Dictionary = _options_by_faction["Império"]
	var base_cards: Array[CardResource] = option["cards"]
	var pool: Dictionary = _generate_enemy_pool(ABLATION_SAMPLE_SIZE, 260)
	var entries: Array = pool["Império"]

	# Variantes — apenas cartas Comuns já existentes no catálogo,
	# preservando a Classe removida sempre que uma substituta com a
	# MESMA classe e Tier I Trait IMPLEMENTADO (UnitTraitRuntime) existir.
	# Registra explicitamente as DUAS mudanças (remove + adiciona) de
	# cada variante — nunca interpretado aqui como "carta X é ruim".
	var variants: Array = [
		{"label": "baseline", "remove": "", "add": "", "note": "Império original, sem troca"},
		{"label": "swap_infante_para_esqueleto_guerreiro", "remove": "Infante Imperial", "add": "Esqueleto Guerreiro", "note": "CQC sem trait -> CQC com Reerguer (trait IMPLEMENTADA)"},
		{"label": "swap_infante_para_abominacao", "remove": "Infante Imperial", "add": "Abominação Putrefata", "note": "CQC sem trait -> CQC com Sacrifício de Carne (trait IMPLEMENTADA)"},
		{"label": "swap_arqueiro_para_arqueiro_esqueletico", "remove": "Arqueiro Imperial", "add": "Arqueiro Esquelético", "note": "À Distância sem trait -> À Distância com Fome Eterna (trait IMPLEMENTADA)"},
		{"label": "swap_evocador_para_liche_controle", "remove": "Evocador Imperial", "add": "Liche Iniciado", "note": "CONTROLE: Mago sem trait -> Mago com trait NÃO implementada (Mestre dos Esqueletos) — isola troca de stats vs. troca de trait funcional"},
		{"label": "swap_triplo_todas_traits_implementadas", "remove": "Infante Imperial,Arqueiro Imperial,Evocador Imperial", "add": "Esqueleto Guerreiro,Arqueiro Esquelético,Liche Iniciado", "note": "as 3 trocas de classe acima combinadas (Mago ainda sem trait implementada disponível no catálogo Comum)"},
	]

	var results: Array = []
	for variant: Dictionary in variants:
		var cards: Array[CardResource] = base_cards.duplicate()
		if variant["remove"] != "":
			var removes: Array = (variant["remove"] as String).split(",")
			var adds: Array = (variant["add"] as String).split(",")
			for j in range(removes.size()):
				var idx: int = -1
				for k in range(cards.size()):
					if cards[k].card_name == removes[j]:
						idx = k
						break
				if idx >= 0:
					cards[idx] = (_catalog[adds[j]] as CardResource).duplicate()

		var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic(cards.duplicate())
		var battles: Array = []
		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var army_a: Army = _army_from_cards(option["commander"], heuristic_cards)
			var army_b: Army = _army_from_entry(entry)
			var record: Dictionary = _run_instrumented(army_a, army_b, 30000000 + variants.find(variant) * 100000 + i, 0)
			record["enemy_id"] = i
			battles.append(record)

		var wins: int = 0
		var margin_sum: float = 0.0
		for b: Dictionary in battles:
			if b["winner"] == "A":
				wins += 1
			margin_sum += b["margin_hp_pct"]
		var summary: Dictionary = {
			"label": variant["label"], "note": variant["note"], "remove": variant["remove"], "add": variant["add"],
			"formation": _order_names(heuristic_cards),
			"wins": wins, "win_rate": float(wins) / battles.size(),
			"avg_margin_hp_pct": margin_sum / battles.size(),
			"n": battles.size(),
		}
		results.append({"summary": summary, "battles": battles})
		print("  %s -> wins=%d/%d (%.1f%%) avg_margin=%+.3f  [%s]" % [variant["label"], wins, battles.size(), summary["win_rate"] * 100.0, summary["avg_margin_hp_pct"], variant["note"]])

	_write_json("res://reports/f040_ablation_Império.json", {"starter_faction": "Império", "variants": results})


# ---------------------------------------------------------------------------
# FASE turnlog — 9 batalhas totalmente logadas turno-a-turno.
# ---------------------------------------------------------------------------

func _run_turnlog() -> void:
	print("=== F-040 turnlog: 3 Facções x 3 inimigos, log completo turno-a-turno ===")
	var pool: Dictionary = _generate_enemy_pool(3, 310)

	var all_logs: Dictionary = {}
	for starter_faction: String in _factions:
		var option: Dictionary = _options_by_faction[starter_faction]
		var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic((option["cards"] as Array).duplicate())
		var entries: Array = pool[starter_faction]
		var faction_logs: Array = []

		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var army_a: Army = _army_from_cards(option["commander"], heuristic_cards)
			var army_b: Army = _army_from_entry(entry)
			faction_logs.append(_run_full_turnlog(army_a, army_b, 40000000 + _factions.find(starter_faction) * 100000 + i, starter_faction == "Império"))

		all_logs[starter_faction] = faction_logs
		print("  %s: %d batalhas com log completo" % [starter_faction, faction_logs.size()])

	_write_json("res://reports/f040_turnlog.json", all_logs)


func _run_full_turnlog(army_a: Army, army_b: Army, seed_value: int, track_imperio: bool) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var turns_log: Array = []

	state.event_bus.subscribe(CombatEventType.Type.TURN_END, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		var l2_protected: int = 0
		if track_imperio:
			for unit: CombatUnit in state.units_of_side(0, true):
				if unit.card.faction == "Império" and unit.affinity_incoming_damage_multiplier < 1.0:
					l2_protected += 1
		turns_log.append({
			"turn": ctx.turn,
			"survivors_a": state.units_of_side(0, true).size(),
			"survivors_b": state.units_of_side(1, true).size(),
			"hp_a": _side_hp_snapshot(state, 0),
			"hp_b": _side_hp_snapshot(state, 1),
			"affinity_levels_a": state.affinity_levels.get(0, {}),
			"affinity_levels_b": state.affinity_levels.get(1, {}),
			"imperio_l2_protected_units": l2_protected if track_imperio else -1,
		})
	)

	CombatEngine.run(state)

	return {
		"seed": state.seed_value,
		"winner": ("A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")),
		"end_reason": state.end_reason,
		"total_turns": state.turn,
		"battlefield": state.battlefield.battlefield_name if state.battlefield != null else "",
		"turns": turns_log,
	}


func _side_hp_snapshot(state: CombatState, side: int) -> Dictionary:
	var hp: int = 0
	var esc: int = 0
	for unit: CombatUnit in state.units_of_side(side, true):
		hp += unit.current_hp
		esc += unit.current_esc
	return {"hp": hp, "esc": esc}


# ---------------------------------------------------------------------------
# FASE formation_tiers — Império em 4 formações (heuristic, top-robusta
# F-039, mediana, ruim) x 30 inimigos cada.
# ---------------------------------------------------------------------------

func _run_formation_tiers() -> void:
	print("=== F-040 formation_tiers: Império em 4 níveis de formação ===")
	var option: Dictionary = _options_by_faction["Império"]
	var base_cards: Array[CardResource] = option["cards"]
	var catalog_by_name: Dictionary = _catalog

	var formations_data: Variant = _read_json("res://reports/f039_formations_Império.json")
	var stats_data: Variant = _read_json("res://reports/f039_formation_stats_Império.json")

	var tiers: Dictionary = {}
	tiers["heuristic"] = _order_names(ArmyPositioningHeuristic.apply_heuristic(base_cards.duplicate()))

	if formations_data != null and stats_data != null:
		var forms_by_id: Dictionary = {}
		for f: Dictionary in formations_data["formations"]:
			forms_by_id[int(f["formation_id"])] = f["order"]
		var stats: Array = stats_data["per_formation_stats"]
		var sorted_stats: Array = stats.duplicate()
		sorted_stats.sort_custom(func(a, b): return a["avg_margin_hp_pct"] > b["avg_margin_hp_pct"])
		tiers["top_robust_fid804"] = forms_by_id.get(804, [])  # rank 3 do F-039, confirmado robusto no held-out
		tiers["median"] = forms_by_id.get(int(sorted_stats[sorted_stats.size() / 2]["formation_id"]), [])
		tiers["bad"] = forms_by_id.get(int(sorted_stats[sorted_stats.size() - 1]["formation_id"]), [])
	else:
		print("  Aviso: f039_formations_Império.json / f039_formation_stats_Império.json não encontrados — rodando apenas 'heuristic'.")

	var pool: Dictionary = _generate_enemy_pool(FORMATION_TIER_SAMPLE_SIZE, 400)
	var entries: Array = pool["Império"]

	var results: Dictionary = {}
	for tier_name: String in tiers:
		var order: Array = tiers[tier_name]
		if order.is_empty():
			continue
		var cards: Array[CardResource] = []
		for name in order:
			cards.append((catalog_by_name[name] as CardResource).duplicate())

		var battles: Array = []
		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var army_a: Army = _army_from_cards(option["commander"], cards)
			var army_b: Army = _army_from_entry(entry)
			var record: Dictionary = _run_instrumented(army_a, army_b, 50000000 + tiers.keys().find(tier_name) * 100000 + i, 0)
			record["enemy_id"] = i
			battles.append(record)

		var wins: int = 0
		var margin_sum: float = 0.0
		for b: Dictionary in battles:
			if b["winner"] == "A":
				wins += 1
			margin_sum += b["margin_hp_pct"]
		results[tier_name] = {"formation": order, "wins": wins, "win_rate": float(wins) / battles.size(), "avg_margin_hp_pct": margin_sum / battles.size(), "battles": battles}
		print("  %s -> wins=%d/%d (%.1f%%) avg_margin=%+.3f" % [tier_name, wins, battles.size(), float(wins) / battles.size() * 100.0, margin_sum / battles.size()])

	_write_json("res://reports/f040_formation_tiers_Império.json", results)
