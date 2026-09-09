extends Node
## f043_composition_formation.gd (F-043)
##
## Matriz Composição x Formação para o Starter Império. NÃO altera
## StarterKitResolver/CardResource/CombatEngine/AffinityRuntime/
## ArmyPositioningHeuristic — só monta Army experimentais em memória e
## roda pelo CombatEngine público, exatamente como F-039/040/041/042.
##
## 5 formações (F0-F4): F0=fid=804, F1=ArmyPositioningHeuristic aplicada
## à ordem canônica, F2/F3/F4 = formações REAIS do F-039 (fid=434 rank1,
## fid=125 mediana, fid=736 pior — lidas de f039_formations_Império.json/
## f039_formation_stats_Império.json, nunca inventadas). Para cada
## formação, as 3 "vagas complementares" são onde Carvalho Ancião/
## Trepadeira Ancestral/Flor da Aurora ocupam NAQUELA formação
## específica (posições diferentes em cada uma) — ao trocar a
## composição, o trio candidato (ordenado alfabeticamente, nunca
## escolhido para favorecer) ocupa essas MESMAS posições em ordem
## crescente, nunca reotimizado.
##
## Fases (--phase=):
##   formations — deriva F0-F4 (posições dos 6 fixos + 3 vagas), salva.
##   matrix     — 6 composições x 5 formações x N inimigos, métricas
##                completas (dano/ESC/HP/wasted/heal/Afinidade/atribuição
##                de carta), reaproveitando a decomposição do F-041.
##   validate   — candidatos finais x F0/F1 x 500 inimigos NOVOS held-out.

const ENEMY_GENERATION_RNG_SEED: int = 39000
const MATRIX_SAMPLE_SIZE: int = 200
const MATRIX_ENEMY_SKIP: int = 1500  # novo, nunca usado por estágios anteriores
const VALIDATION_SAMPLE_SIZE: int = 500
const VALIDATION_ENEMY_SKIP: int = 2000  # held-out, novo

const IMPERIO_FIXED_CARDS: Array[String] = ["Arqueiro Imperial", "Engenheiro Imperial", "Escudeiro Imperial", "Evocador Imperial", "Infante Imperial", "Legionário Imperial"]
const CURRENT_COMPLEMENTARY: Array[String] = ["Carvalho Ancião", "Trepadeira Ancestral", "Flor da Aurora"]

const COMPOSITIONS: Dictionary = {
	"C0_baseline": ["Carvalho Ancião", "Trepadeira Ancestral", "Flor da Aurora"],
	"C1_f042_winner": ["Ent Jovem", "Porco-Espinho Ancestral", "Trepadeira Ancestral"],
	"C2_second_best": ["Ent Jovem", "Trepadeira Ancestral", "Liche Iniciado"],
	"C3_third_best": ["Ent Jovem", "Porco-Espinho Ancestral", "Liche Iniciado"],
	"C4_keeps_carvalho": ["Carvalho Ancião", "Ent Jovem", "Porco-Espinho Ancestral"],
	"C5_no_entjovem": ["Porco-Espinho Ancestral", "Trepadeira Ancestral", "Banshee"],
}

var _catalog: Dictionary = {}
var _commander: CommanderResource
var _formations: Dictionary = {}  # name -> {"imperio_positions": {card_name:pos}, "complementary_positions": [p1,p2,p3]}


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "formations")

	for card: CardResource in GameDatabase.cards:
		_catalog[card.card_name] = card
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		if option["faction"] == "Império":
			_commander = option["commander"]

	_derive_formations()

	match phase:
		"formations":
			_write_formations()
		"matrix":
			var comp_filter: String = _arg_value("--composition=", "")
			_run_matrix(comp_filter)
		"validate":
			_run_validation()
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
# Derivação das 5 formações (posições dos 6 fixos + as 3 vagas)
# ---------------------------------------------------------------------------

func _positions_from_order(order: Array) -> Dictionary:
	var by_position: Dictionary = {}
	for i in range(order.size()):
		by_position[order[i]] = i + 1
	return by_position


func _derive_formations() -> void:
	var option_imperio: Dictionary = {}
	for o: Dictionary in StarterKitResolver.generate_options(GameDatabase.cards):
		if o["faction"] == "Império":
			option_imperio = o
	var canonical_cards: Array[CardResource] = option_imperio["cards"]

	# F0 = fid=804 (F-039)
	var fid804_order: Array = ["Escudeiro Imperial", "Legionário Imperial", "Infante Imperial", "Engenheiro Imperial", "Carvalho Ancião", "Flor da Aurora", "Evocador Imperial", "Trepadeira Ancestral", "Arqueiro Imperial"]
	_register_formation("F0_fid804", fid804_order)

	# F1 = ArmyPositioningHeuristic aplicada à ordem canônica
	var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic(canonical_cards.duplicate())
	var heuristic_order: Array = []
	for c: CardResource in heuristic_cards:
		heuristic_order.append(c.card_name)
	_register_formation("F1_heuristic", heuristic_order)

	# F2/F3/F4 = formações REAIS do F-039 (lidas de f043_formations_source.json,
	# já extraído por análise externa de f039_formations_Império.json /
	# f039_formation_stats_Império.json — fid=434 rank1, fid=125 mediana,
	# fid=736 pior).
	var source: Variant = _read_json("res://reports/f043_formations_source.json")
	if source == null:
		print("  AVISO: f043_formations_source.json não encontrado — F2/F3/F4 não serão registradas (limitação, não inventar formação).")
		return
	_register_formation("F2_fid434_near_top", source["F2_fid434"]["order"])
	_register_formation("F3_fid125_median", source["F3_median"]["order"])
	_register_formation("F4_fid736_bad", source["F4_bad"]["order"])


func _register_formation(label: String, order: Array) -> void:
	var by_position: Dictionary = _positions_from_order(order)
	var imperio_positions: Dictionary = {}
	for name in IMPERIO_FIXED_CARDS:
		imperio_positions[name] = by_position[name]
	var complementary_positions: Array = []
	for name in CURRENT_COMPLEMENTARY:
		complementary_positions.append(by_position[name])
	complementary_positions.sort()
	_formations[label] = {"order_reference": order, "imperio_positions": imperio_positions, "complementary_positions": complementary_positions}


func _write_formations() -> void:
	print("=== F-043 formations: F0-F4 derivadas ===")
	for label in _formations:
		print("  %s: vagas complementares em %s" % [label, _formations[label]["complementary_positions"]])
	_write_json("res://reports/f043_manifest.json", {
		"formations": _formations, "compositions": COMPOSITIONS,
		"matrix_sample_size": MATRIX_SAMPLE_SIZE, "matrix_enemy_skip": MATRIX_ENEMY_SKIP,
		"validation_sample_size": VALIDATION_SAMPLE_SIZE, "validation_enemy_skip": VALIDATION_ENEMY_SKIP,
		"methodology_note": "F2/F3/F4 sao formacoes REAIS do F-039 (fid=434/125/736), nunca inventadas. Trio candidato sempre ordenado alfabeticamente e mapeado para as posicoes complementares daquela formacao em ordem crescente — nunca reotimizado por variante.",
	})


# ---------------------------------------------------------------------------
# Utilidades de batalha
# ---------------------------------------------------------------------------

func _generate_enemy_pool(count: int, skip: int) -> Array[EnemyArmyEntry]:
	var rng := RandomNumberGenerator.new()
	rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()
	var factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
	var entries: Array[EnemyArmyEntry] = []
	for i in range(skip + count):
		var enemy_faction: String = factions[rng.randi_range(0, factions.size() - 1)]
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			EnemyArmyEntry.Category.NORMAL, enemy_faction, 1, GameDatabase.cards, season_config,
			GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
			GameDatabase.commander_effects, GameDatabase.commander_values,
			"f037_Império", i, true, rng
		)
		if i >= skip:
			entries.append(entry)
	return entries


func _army_from_entry(entry: EnemyArmyEntry) -> Army:
	var commander := CommanderResource.new()
	commander.commander_name = "Enemy"
	commander.faction = entry.commander.faction
	var army := Army.new()
	army.commander = commander
	army.cards = entry.cards.duplicate()
	return army


func _build_variant_army(formation_label: String, trio: Array) -> Army:
	var f: Dictionary = _formations[formation_label]
	var sorted_trio: Array = trio.duplicate()
	sorted_trio.sort()

	var cards_by_position: Dictionary = {}
	for name in IMPERIO_FIXED_CARDS:
		cards_by_position[f["imperio_positions"][name]] = (_catalog[name] as CardResource).duplicate()
	var slots: Array = f["complementary_positions"]
	for i in range(3):
		cards_by_position[slots[i]] = (_catalog[sorted_trio[i]] as CardResource).duplicate()

	var ordered_cards: Array[CardResource] = []
	for pos in range(1, 10):
		ordered_cards.append(cards_by_position[pos])

	var army := Army.new()
	army.commander = _commander
	army.cards = ordered_cards
	return army


func _hp_pct(state: CombatState, side: int) -> float:
	var hp_remaining: int = 0
	var hp_max: int = 0
	for unit: CombatUnit in state.units:
		if unit.side == side:
			hp_remaining += maxi(unit.current_hp, 0)
			hp_max += unit.card.hp
	return (float(hp_remaining) / float(hp_max)) if hp_max > 0 else 0.0


## Batalha totalmente instrumentada — decomposição de dano idêntica à
## metodologia do F-041 (recalcula position/commander multiplier via
## funções públicas, nunca uma fórmula nova), acumulada diretamente
## (sem guardar todo evento bruto, para manter o volume de dados
## administrável numa matriz de 30 células x 200 inimigos).
func _run_cell_battle(army_a: Army, army_b: Army, seed_value: int) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)

	var agg: Dictionary = {
		"raw_dealt": 0, "dealt": 0, "esc_dealt": 0, "hp_dealt": 0, "wasted_dealt": 0,
		"raw_received": 0, "received": 0, "esc_received": 0, "hp_received": 0, "wasted_received": 0,
		"healing_done": 0, "healing_received": 0,
		"l2_attacks": 0, "l2_total_attacks": 0, "l2_mitigation": 0,
		"last_damage_turn": 0, "last_death_turn": 0, "first_death_turn": -1, "first_death_card": "", "first_death_side": -1,
	}
	var card_stats: Dictionary = {}  # card_name -> {attacks_received, damage_dealt, damage_esc, damage_hp, position, class, faction}

	state.event_bus.subscribe(CombatEventType.Type.AFTER_ATTACK, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		if ctx.attacker == null or ctx.target == null:
			return
		var raw: int = int(round(ctx.attack_value))
		var mult: float = ctx.target.affinity_incoming_damage_multiplier
		var post_affinity: int = int(round(ctx.attack_value * mult))
		var wasted: int = maxi(0, post_affinity - ctx.damage_dealt)
		var mitigation: int = maxi(0, raw - post_affinity)

		if ctx.attacker.side == 0:
			agg["raw_dealt"] += raw
			agg["dealt"] += ctx.damage_dealt
			agg["esc_dealt"] += ctx.damage_absorbed_by_shield
			agg["hp_dealt"] += ctx.damage_applied_to_hp
			agg["wasted_dealt"] += wasted
		if ctx.target.side == 0:
			agg["raw_received"] += raw
			agg["received"] += ctx.damage_dealt
			agg["esc_received"] += ctx.damage_absorbed_by_shield
			agg["hp_received"] += ctx.damage_applied_to_hp
			agg["wasted_received"] += wasted
			agg["l2_total_attacks"] += 1
			if mult < 1.0:
				agg["l2_attacks"] += 1
				agg["l2_mitigation"] += mitigation

			var name: String = ctx.target.card.card_name
			if not card_stats.has(name):
				card_stats[name] = {"attacks_received": 0, "damage_dealt": 0, "damage_esc": 0, "damage_hp": 0, "position": ctx.target.position, "class": ctx.target.card.card_class, "faction": ctx.target.card.faction}
			card_stats[name]["attacks_received"] += 1
			card_stats[name]["damage_dealt"] += ctx.damage_dealt
			card_stats[name]["damage_esc"] += ctx.damage_absorbed_by_shield
			card_stats[name]["damage_hp"] += ctx.damage_applied_to_hp

		if ctx.damage_dealt > 0 or ctx.damage_absorbed_by_shield > 0 or ctx.damage_applied_to_hp > 0:
			agg["last_damage_turn"] = ctx.turn
	)

	state.event_bus.subscribe(CombatEventType.Type.AFTER_HEAL_PERFORMED, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		if ctx.side == 0:
			agg["healing_done"] += ctx.heal_amount
		if ctx.target != null and ctx.target.side == 0:
			agg["healing_received"] += ctx.heal_amount
	)

	state.event_bus.subscribe(CombatEventType.Type.UNIT_DIED, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		agg["last_death_turn"] = ctx.turn
		if agg["first_death_turn"] == -1:
			agg["first_death_turn"] = ctx.turn
			agg["first_death_card"] = ctx.attacker.card.card_name if ctx.attacker != null and ctx.attacker.card != null else ""
			agg["first_death_side"] = ctx.side
	)

	CombatEngine.run(state)

	var winner: String = "A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")
	var summary: Dictionary = {
		"seed": state.seed_value, "winner": winner, "end_reason": state.end_reason, "turns": state.turn,
		"survivors_a": state.units_of_side(0, true).size(), "margin_hp_pct": _hp_pct(state, 0) - _hp_pct(state, 1),
		"affinity_points_a": state.affinity_points.get(0, {}), "affinity_levels_a": state.affinity_levels.get(0, {}),
	}
	for k in agg:
		summary[k] = agg[k]
	return {"summary": summary, "card_stats": card_stats}


# ---------------------------------------------------------------------------
# FASE matrix — 6 composições x 5 formações x N inimigos
# ---------------------------------------------------------------------------

func _run_matrix(comp_filter: String) -> void:
	var enemies: Array[EnemyArmyEntry] = _generate_enemy_pool(MATRIX_SAMPLE_SIZE, MATRIX_ENEMY_SKIP)
	print("=== F-043 matrix: %d inimigos compartilhados, formações: %s ===" % [enemies.size(), _formations.keys()])

	var comp_names: Array = COMPOSITIONS.keys() if comp_filter == "" else [comp_filter]

	for comp_name in comp_names:
		var trio: Array = COMPOSITIONS[comp_name]
		var cell_results: Dictionary = {}
		var t_start: int = Time.get_ticks_msec()

		for formation_label in _formations:
			var battles: Array = []
			var card_attribution: Dictionary = {}
			var army_template: Army = _build_variant_army(formation_label, trio)

			for i in range(enemies.size()):
				var entry: EnemyArmyEntry = enemies[i]
				var army_a := Army.new()
				army_a.commander = army_template.commander
				army_a.cards = army_template.cards.duplicate()
				var army_b: Army = _army_from_entry(entry)
				var seed_value: int = 90000000 + comp_names.find(comp_name) * 10000000 + _formations.keys().find(formation_label) * 100000 + i
				var result: Dictionary = _run_cell_battle(army_a, army_b, seed_value)
				battles.append(result["summary"])
				for name in result["card_stats"]:
					if not card_attribution.has(name):
						card_attribution[name] = {"attacks_received": 0, "damage_dealt": 0, "damage_esc": 0, "damage_hp": 0, "position": result["card_stats"][name]["position"], "class": result["card_stats"][name]["class"], "faction": result["card_stats"][name]["faction"]}
					card_attribution[name]["attacks_received"] += result["card_stats"][name]["attacks_received"]
					card_attribution[name]["damage_dealt"] += result["card_stats"][name]["damage_dealt"]
					card_attribution[name]["damage_esc"] += result["card_stats"][name]["damage_esc"]
					card_attribution[name]["damage_hp"] += result["card_stats"][name]["damage_hp"]

			cell_results[formation_label] = {"battles": battles, "card_attribution": card_attribution}
			var wins: int = 0
			for b: Dictionary in battles:
				if b["winner"] == "A":
					wins += 1
			print("  %s x %s -> wins=%d/%d (%.1f%%) (%.1fs)" % [comp_name, formation_label, wins, battles.size(), float(wins) / battles.size() * 100.0, float(Time.get_ticks_msec() - t_start) / 1000.0])

		_write_json("res://reports/f043_cell_%s.json" % comp_name, {"composition": comp_name, "trio": trio, "results": cell_results})


# ---------------------------------------------------------------------------
# FASE validate
# ---------------------------------------------------------------------------

func _run_validation() -> void:
	var final_candidates: Dictionary = {
		"C0_baseline": COMPOSITIONS["C0_baseline"],
		"C1_f042_winner": COMPOSITIONS["C1_f042_winner"],
		"C4_keeps_carvalho": COMPOSITIONS["C4_keeps_carvalho"],
	}
	var final_formations: Array[String] = ["F0_fid804", "F1_heuristic"]
	var enemies: Array[EnemyArmyEntry] = _generate_enemy_pool(VALIDATION_SAMPLE_SIZE, VALIDATION_ENEMY_SKIP)
	print("=== F-043 validate: %d candidatos x %s x %d inimigos held-out NOVOS ===" % [final_candidates.size(), final_formations, enemies.size()])

	var all_results: Dictionary = {}
	for comp_name in final_candidates:
		var trio: Array = final_candidates[comp_name]
		all_results[comp_name] = {}
		for formation_label in final_formations:
			var army_template: Army = _build_variant_army(formation_label, trio)
			var wins: int = 0
			var margin_sum: float = 0.0
			var t_start: int = Time.get_ticks_msec()
			for i in range(enemies.size()):
				var entry: EnemyArmyEntry = enemies[i]
				var army_a := Army.new()
				army_a.commander = army_template.commander
				army_a.cards = army_template.cards.duplicate()
				var army_b: Army = _army_from_entry(entry)
				var seed_value: int = 95000000 + final_candidates.keys().find(comp_name) * 1000000 + final_formations.find(formation_label) * 500000 + i
				var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
				CombatEngine.run(state)
				if state.winner_side == 0:
					wins += 1
				margin_sum += _hp_pct(state, 0) - _hp_pct(state, 1)
			var wr: float = float(wins) / enemies.size()
			var avg_margin: float = margin_sum / enemies.size()
			print("  %s x %s -> wr=%.1f%% margin=%+.3f (%.1fs)" % [comp_name, formation_label, wr * 100.0, avg_margin, float(Time.get_ticks_msec() - t_start) / 1000.0])
			all_results[comp_name][formation_label] = {"win_rate": wr, "avg_margin_hp_pct": avg_margin, "n": enemies.size()}

	_write_json("res://reports/f043_validation.json", {"sample_size": VALIDATION_SAMPLE_SIZE, "results": all_results})
