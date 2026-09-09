extends Node
## f042_composition_matrix.gd (F-042)
##
## Matriz de composição das 3 vagas complementares do Império. NÃO altera
## CardResource/StarterKitResolver/CombatEngine/AffinityRuntime — só monta
## Army experimentais em memória, roda pelo CombatEngine público exatamente
## como já existe, e lê campos/eventos já públicos.
##
## METODOLOGIA (desvio documentado do roteiro original): em vez de
## hand-picking ~25 variantes nos Blocos A/B/C/D, o pool elegível
## (cartas Comuns de Natureza/Mortos-Vivos, mesma raridade/tier do
## Starter) tem só 12 cartas — 6 Natureza + 6 Mortos-Vivos — então
## C(12,3) = 220 é o espaço INTEIRO de combinações possíveis, pequeno o
## suficiente para testar exaustivamente. Isso cobre H1/H2/H3 e os
## Blocos A/B/C/D simultaneamente (qualquer variante é classificável
## post-hoc por mix de Facção) sem a arbitrariedade de escolher à mão
## quais ~25 testar. As 6 cartas do Império (Arqueiro/Engenheiro/
## Escudeiro/Evocador/Infante/Legionário Imperial) permanecem fixas em
## TODAS as 220 variantes, nas posições 1/2/3/4/7/9 de fid=804. As 3
## posições restantes (5, 6, 8) recebem o trio candidato, sempre na
## MESMA ordem determinística (ordem alfabética do nome da carta ->
## posição 5, depois 6, depois 8) — nunca escolhida para favorecer uma
## variante, nunca reotimizada por ArmyPositioningHeuristic.
##
## Fases (--phase=):
##   catalog     — dump das 12 cartas elegíveis + baseline (fid=804 real).
##   screening   — as 220 combinações x 100 inimigos compartilhados,
##                 métricas leves (sem decomposição de dano por evento).
##   validate    — top-N candidatos (lidos de f042_top_candidates.json,
##                 produzido por análise externa do screening) x 500
##                 inimigos held-out NOVOS, com decomposição completa de
##                 dano/Afinidade/atribuição por carta (mesmo padrão do F-041).

const ENEMY_GENERATION_RNG_SEED: int = 39000  # idêntica a F-037/038/039/040/041
const SCREENING_SAMPLE_SIZE: int = 100
const SCREENING_ENEMY_SKIP: int = 500  # nunca usado por estágios anteriores
const VALIDATION_SAMPLE_SIZE: int = 500
const VALIDATION_ENEMY_SKIP: int = 1000  # held-out, nunca visto nem no screening

const IMPERIO_FIXED_CARDS: Array[String] = ["Arqueiro Imperial", "Engenheiro Imperial", "Escudeiro Imperial", "Evocador Imperial", "Infante Imperial", "Legionário Imperial"]
# Posições de fid=804 (F-039): Escudeiro=1, Legionário=2, Infante=3, Engenheiro=4, Carvalho=5, Flor=6, Evocador=7, Trepadeira=8, Arqueiro=9.
const IMPERIO_POSITIONS: Dictionary = {"Escudeiro Imperial": 1, "Legionário Imperial": 2, "Infante Imperial": 3, "Engenheiro Imperial": 4, "Evocador Imperial": 7, "Arqueiro Imperial": 9}
const COMPLEMENTARY_POSITIONS: Array[int] = [5, 6, 8]  # ordem fixa: trio ordenado alfabeticamente -> [5,6,8]

const NATUREZA_POOL: Array[String] = ["Carvalho Ancião", "Ent Jovem", "Flor da Aurora", "Porco-Espinho Ancestral", "Trepadeira Ancestral", "Urso Ancestral"]
const MORTOS_VIVOS_POOL: Array[String] = ["Abominação Putrefata", "Arqueiro Esquelético", "Banshee", "Esqueleto Guerreiro", "Liche Iniciado", "Sacerdote Profano"]

var _catalog: Dictionary = {}
var _commander: CommanderResource


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "catalog")
	var chunk_start: int = int(_arg_value("--chunk_start=", "0"))
	var chunk_end: int = int(_arg_value("--chunk_end=", "220"))

	for card: CardResource in GameDatabase.cards:
		_catalog[card.card_name] = card
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		if option["faction"] == "Império":
			_commander = option["commander"]

	match phase:
		"catalog":
			_run_catalog()
		"screening":
			_run_screening(chunk_start, chunk_end)
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
# FASE catalog
# ---------------------------------------------------------------------------

func _card_row(name: String) -> Dictionary:
	var card: CardResource = _catalog[name]
	return {
		"card_name": name, "faction": card.faction, "card_class": card.card_class,
		"atk": card.atk, "hp": card.hp, "esc": card.esc, "hp_plus_esc": card.hp + card.esc,
		"rarity": card.rarity, "tier": card.tier,
		"tier_1_trait_name": card.tier_1_trait_name,
		"trait_implemented": card.tier_1_trait_name in ["Reerguer", "Fome Eterna", "Sacrifício de Carne", "Colheita de Almas"],
	}


func _run_catalog() -> void:
	print("=== F-042 catalog: pool elegível (12 cartas) + baseline fid=804 ===")
	var rows: Array = []
	for name in NATUREZA_POOL:
		rows.append(_card_row(name))
	for name in MORTOS_VIVOS_POOL:
		rows.append(_card_row(name))
	for r: Dictionary in rows:
		print("  %-24s %-13s %-13s ATK=%3d HP=%3d ESC=%3d trait=%s impl=%s" % [r["card_name"], r["faction"], r["card_class"], r["atk"], r["hp"], r["esc"], r["tier_1_trait_name"], r["trait_implemented"]])

	var combos: Array = _all_combinations(NATUREZA_POOL + MORTOS_VIVOS_POOL, 3)
	print("  Total de combinações C(12,3): %d" % combos.size())

	_write_json("res://reports/f042_catalog.json", {
		"eligible_pool": rows,
		"imperio_fixed_cards": IMPERIO_FIXED_CARDS,
		"formation_reference": "fid=804 (F-039)",
		"complementary_positions": COMPLEMENTARY_POSITIONS,
		"total_combinations": combos.size(),
	})
	_write_json("res://reports/f042_manifest.json", {
		"screening_sample_size": SCREENING_SAMPLE_SIZE, "screening_enemy_skip": SCREENING_ENEMY_SKIP,
		"validation_sample_size": VALIDATION_SAMPLE_SIZE, "validation_enemy_skip": VALIDATION_ENEMY_SKIP,
		"enemy_generation_seed": ENEMY_GENERATION_RNG_SEED,
		"methodology_note": "Pool elegivel = 12 cartas Comuns (6 Natureza + 6 Mortos-Vivos, mesma raridade/tier do Starter). C(12,3)=220 combinacoes testadas exaustivamente na triagem, em vez de ~25 variantes hand-picked.",
	})


func _all_combinations(items: Array, k: int) -> Array:
	var result: Array = []
	var n: int = items.size()
	var indices: Array = []
	for i in range(k):
		indices.append(i)
	while true:
		var combo: Array = []
		for idx in indices:
			combo.append(items[idx])
		result.append(combo)
		var i: int = k - 1
		while i >= 0 and indices[i] == i + n - k:
			i -= 1
		if i < 0:
			break
		indices[i] += 1
		for j in range(i + 1, k):
			indices[j] = indices[j - 1] + 1
	return result


# ---------------------------------------------------------------------------
# Utilidades compartilhadas
# ---------------------------------------------------------------------------

func _generate_enemy_pool(count: int, skip: int) -> Array[EnemyArmyEntry]:
	var rng := RandomNumberGenerator.new()
	rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()
	var factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
	var entries: Array[EnemyArmyEntry] = []
	# Consome a MESMA sequência de RNG usada por todos os estágios
	# anteriores (loop "Império" depois "Natureza" depois "Mortos-Vivos",
	# 1000 cada) para preservar bit-a-bit os mesmos inimigos em qualquer
	# offset já usado — aqui usamos só o stream de "Império" (primeiro),
	# nos índices [skip, skip+count).
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


## Monta o Army do Império para um trio candidato: 6 cartas fixas nas
## posições de fid=804 + o trio nas posições [5,6,8], trio ordenado
## alfabeticamente (nunca escolhido para favorecer a variante).
func _build_variant_army(trio: Array) -> Army:
	var sorted_trio: Array = trio.duplicate()
	sorted_trio.sort()

	var cards_by_position: Dictionary = {}
	for name in IMPERIO_FIXED_CARDS:
		cards_by_position[IMPERIO_POSITIONS[name]] = (_catalog[name] as CardResource).duplicate()
	for i in range(3):
		cards_by_position[COMPLEMENTARY_POSITIONS[i]] = (_catalog[sorted_trio[i]] as CardResource).duplicate()

	var ordered_cards: Array[CardResource] = []
	for pos in range(1, 10):
		ordered_cards.append(cards_by_position[pos])

	var army := Army.new()
	army.commander = _commander
	army.cards = ordered_cards
	return army


func _trio_id(trio: Array) -> String:
	var sorted_trio: Array = trio.duplicate()
	sorted_trio.sort()
	return "|".join(sorted_trio)


# ---------------------------------------------------------------------------
# FASE screening — 220 combinações x 100 inimigos compartilhados, métricas
# leves (sem decomposição de dano por evento — ver nota de metodologia).
# ---------------------------------------------------------------------------

func _run_screening(chunk_start: int, chunk_end: int) -> void:
	var combos: Array = _all_combinations(NATUREZA_POOL + MORTOS_VIVOS_POOL, 3)
	chunk_end = mini(chunk_end, combos.size())
	print("=== F-042 screening: combinações [%d, %d) de %d, %d inimigos compartilhados ===" % [chunk_start, chunk_end, combos.size(), SCREENING_SAMPLE_SIZE])

	var enemies: Array[EnemyArmyEntry] = _generate_enemy_pool(SCREENING_SAMPLE_SIZE, SCREENING_ENEMY_SKIP)
	var results: Array = []
	var t_start: int = Time.get_ticks_msec()

	for idx in range(chunk_start, chunk_end):
		var trio: Array = combos[idx]
		var army_a_template: Army = _build_variant_army(trio)

		var wins: int = 0
		var draws: int = 0
		var margins: Array = []
		var survivors_list: Array = []
		var dmg_dealt_total: int = 0
		var dmg_received_total: int = 0

		for i in range(enemies.size()):
			var entry: EnemyArmyEntry = enemies[i]
			var army_a: Army = _army_from_entry_army(army_a_template)
			var army_b: Army = _army_from_entry(entry)
			var collector := BattleEventCollector.new()
			var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 70000000 + idx * 1000 + i)
			collector.attach(state.event_bus)
			CombatEngine.run(state)

			if state.winner_side == 0:
				wins += 1
			elif state.winner_side == -1:
				draws += 1
			var margin: float = _hp_pct(state, 0) - _hp_pct(state, 1)
			margins.append(margin)
			survivors_list.append(state.units_of_side(0, true).size())
			dmg_dealt_total += collector.total_damage_by_side().get(0, 0)
			dmg_received_total += collector.total_damage_by_side().get(1, 0)

		var n: int = enemies.size()
		var avg_margin: float = 0.0
		for m in margins:
			avg_margin += m
		avg_margin /= n
		var avg_survivors: float = 0.0
		for s in survivors_list:
			avg_survivors += s
		avg_survivors /= n

		results.append({
			"trio": trio.duplicate(), "trio_id": _trio_id(trio),
			"wins": wins, "draws": draws, "losses": n - wins - draws,
			"win_rate": float(wins) / n, "avg_margin_hp_pct": avg_margin,
			"avg_survivors": avg_survivors,
			"avg_damage_dealt": float(dmg_dealt_total) / n, "avg_damage_received": float(dmg_received_total) / n,
			"n": n,
		})

		if (idx - chunk_start) % 20 == 0:
			print("  [%d/%d] %.1fs decorridos" % [idx - chunk_start, chunk_end - chunk_start, float(Time.get_ticks_msec() - t_start) / 1000.0])

	print("  Chunk completo: %d combinações em %.1fs" % [results.size(), float(Time.get_ticks_msec() - t_start) / 1000.0])
	_write_json("res://reports/f042_screening_chunk_%d_%d.json" % [chunk_start, chunk_end], {"chunk_start": chunk_start, "chunk_end": chunk_end, "results": results})


func _army_from_entry_army(template: Army) -> Army:
	var army := Army.new()
	army.commander = template.commander
	army.cards = template.cards.duplicate()
	return army


func _hp_pct(state: CombatState, side: int) -> float:
	var hp_remaining: int = 0
	var hp_max: int = 0
	for unit: CombatUnit in state.units:
		if unit.side == side:
			hp_remaining += maxi(unit.current_hp, 0)
			hp_max += unit.card.hp
	return (float(hp_remaining) / float(hp_max)) if hp_max > 0 else 0.0


# ---------------------------------------------------------------------------
# FASE validate — top candidatos x 500 inimigos held-out NOVOS, com
# decomposição completa de dano/Afinidade/atribuição por carta (mesmo
# padrão do F-041 _run_instrumented_battle).
# ---------------------------------------------------------------------------

func _run_validation() -> void:
	var candidates_data: Variant = _read_json("res://reports/f042_top_candidates.json")
	if candidates_data == null:
		print("Rode a análise de ranking do screening primeiro (f042_top_candidates.json não encontrado).")
		return

	print("=== F-042 validate: %d candidatos x %d inimigos held-out ===" % [(candidates_data["candidates"] as Array).size(), VALIDATION_SAMPLE_SIZE])
	var enemies: Array[EnemyArmyEntry] = _generate_enemy_pool(VALIDATION_SAMPLE_SIZE, VALIDATION_ENEMY_SKIP)

	var all_results: Dictionary = {}
	for candidate: Dictionary in candidates_data["candidates"]:
		var trio: Array = candidate["trio"]
		var label: String = candidate.get("label", _trio_id(trio))
		var army_template: Army = _build_variant_army(trio)

		var battle_summaries: Array = []
		var card_attribution: Dictionary = {}
		var affinity_agg: Dictionary = {"l2_attacks": 0, "l2_total_attacks": 0, "l2_mitigation": 0, "l2_raw": 0}

		var t_start: int = Time.get_ticks_msec()
		for i in range(enemies.size()):
			var entry: EnemyArmyEntry = enemies[i]
			var army_a: Army = _army_from_entry_army(army_template)
			var army_b: Army = _army_from_entry(entry)
			var seed_value: int = 80000000 + candidates_data["candidates"].find(candidate) * 1000000 + i
			var result: Dictionary = _run_instrumented_validation_battle(army_a, army_b, seed_value)
			battle_summaries.append(result["summary"])
			for card_name in result["card_stats"]:
				if not card_attribution.has(card_name):
					card_attribution[card_name] = {"attacks_received": 0, "damage_dealt": 0, "damage_esc": 0, "damage_hp": 0, "position": result["card_stats"][card_name]["position"], "class": result["card_stats"][card_name]["class"], "faction": result["card_stats"][card_name]["faction"]}
				card_attribution[card_name]["attacks_received"] += result["card_stats"][card_name]["attacks_received"]
				card_attribution[card_name]["damage_dealt"] += result["card_stats"][card_name]["damage_dealt"]
				card_attribution[card_name]["damage_esc"] += result["card_stats"][card_name]["damage_esc"]
				card_attribution[card_name]["damage_hp"] += result["card_stats"][card_name]["damage_hp"]
			affinity_agg["l2_attacks"] += result["l2_attacks"]
			affinity_agg["l2_total_attacks"] += result["l2_total_attacks"]
			affinity_agg["l2_mitigation"] += result["l2_mitigation"]
			affinity_agg["l2_raw"] += result["l2_raw"]

		var wins: int = 0
		var margin_sum: float = 0.0
		for b: Dictionary in battle_summaries:
			if b["winner"] == "A":
				wins += 1
			margin_sum += b["margin_hp_pct"]

		print("  %s -> wins=%d/%d (%.1f%%) avg_margin=%+.3f (%.1fs)" % [label, wins, enemies.size(), float(wins) / enemies.size() * 100.0, margin_sum / enemies.size(), float(Time.get_ticks_msec() - t_start) / 1000.0])

		all_results[label] = {
			"trio": trio, "wins": wins, "win_rate": float(wins) / enemies.size(),
			"avg_margin_hp_pct": margin_sum / enemies.size(), "n": enemies.size(),
			"card_attribution": card_attribution, "affinity": affinity_agg,
			"battles": battle_summaries,
		}

	_write_json("res://reports/f042_validation.json", {"sample_size": VALIDATION_SAMPLE_SIZE, "results": all_results})

	var card_attribution_by_label: Dictionary = {}
	var affinity_by_label: Dictionary = {}
	for label in all_results:
		card_attribution_by_label[label] = all_results[label]["card_attribution"]
		affinity_by_label[label] = all_results[label]["affinity"]
	_write_json("res://reports/f042_card_attribution.json", card_attribution_by_label)
	_write_json("res://reports/f042_affinity.json", affinity_by_label)


func _run_instrumented_validation_battle(army_a: Army, army_b: Army, seed_value: int) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var card_stats: Dictionary = {}
	var l2: Dictionary = {"attacks": 0, "total_attacks": 0, "mitigation": 0, "raw": 0}

	state.event_bus.subscribe(CombatEventType.Type.AFTER_ATTACK, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		if ctx.attacker == null or ctx.target == null:
			return
		if ctx.target.side == 0:
			var name: String = ctx.target.card.card_name
			if not card_stats.has(name):
				card_stats[name] = {"attacks_received": 0, "damage_dealt": 0, "damage_esc": 0, "damage_hp": 0, "position": ctx.target.position, "class": ctx.target.card.card_class, "faction": ctx.target.card.faction}
			card_stats[name]["attacks_received"] += 1
			card_stats[name]["damage_dealt"] += ctx.damage_dealt
			card_stats[name]["damage_esc"] += ctx.damage_absorbed_by_shield
			card_stats[name]["damage_hp"] += ctx.damage_applied_to_hp

			l2["total_attacks"] += 1
			var mult: float = ctx.target.affinity_incoming_damage_multiplier
			var raw: int = int(round(ctx.attack_value))
			if mult < 1.0:
				l2["attacks"] += 1
				l2["mitigation"] += maxi(0, raw - int(round(ctx.attack_value * mult)))
			l2["raw"] += raw
	)

	CombatEngine.run(state)

	var winner: String = "A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")
	return {
		"summary": {"seed": state.seed_value, "winner": winner, "end_reason": state.end_reason, "turns": state.turn, "margin_hp_pct": _hp_pct(state, 0) - _hp_pct(state, 1), "survivors_a": state.units_of_side(0, true).size()},
		"card_stats": card_stats,
		"l2_attacks": l2["attacks"], "l2_total_attacks": l2["total_attacks"], "l2_mitigation": l2["mitigation"], "l2_raw": l2["raw"],
	}
