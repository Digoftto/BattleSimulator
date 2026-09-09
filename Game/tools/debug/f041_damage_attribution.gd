extends Node
## f041_damage_attribution.gd (F-041)
##
## Diagnóstico de atribuição de dano para o Império. NÃO altera
## CombatEngine/AffinityRuntime como regra — toda decomposição
## (position_multiplier, commander_multiplier, raw vs. mitigated damage)
## é RECALCULADA por fora chamando as MESMAS funções públicas que o
## motor já chama (CommanderDoctrineRuntime.attack_multiplier,
## AffinityRuntime.level_for) e lendo campos já públicos
## (CombatUnit.affinity_incoming_damage_multiplier, CombatContext.
## damage_dealt/damage_absorbed_by_shield/damage_applied_to_hp) — nunca
## inventando uma fórmula nova. Ver seção "Etapa 2" do relatório F-041
## para o rastreamento textual completo do caminho do dano.
##
## Fases (--phase=):
##   sanity — Etapa 15: casos isolados com Attacker/Target conhecidos.
##   main   — Etapas 3-14: experimento controlado com log de CADA ataque
##            (Império/fid=804, Natureza/heuristic, Mortos-Vivos/heuristic,
##            50 inimigos compartilhados — mesmos parâmetros de geração
##            do F-040 --phase=controlled, para comparabilidade direta).

const ENEMY_GENERATION_RNG_SEED: int = 39000  # idêntica a F-037/038/039/040
const CONTROLLED_SAMPLE_SIZE: int = 50
const ENEMY_SKIP: int = 210  # mesmos inimigos do F-040 --phase=controlled

var _factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
var _options_by_faction: Dictionary = {}
var _catalog: Dictionary = {}


func _ready() -> void:
	var phase: String = _arg_value("--phase=", "main")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_options_by_faction[option["faction"]] = option
	for card: CardResource in GameDatabase.cards:
		_catalog[card.card_name] = card

	match phase:
		"sanity":
			_run_sanity()
		"main":
			_run_main()
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
# FASE sanity (Etapa 15) — casos isolados, ATK/ESC/HP conhecidos.
# ---------------------------------------------------------------------------

func _build_card(name: String, faction: String, card_class: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = name
	card.faction = faction
	card.card_class = card_class
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card


func _run_sanity() -> void:
	print("=== F-041 sanity (Etapa 15): casos isolados de cálculo de dano ===")
	var cases: Array = []

	# A) ESC suficiente para absorver tudo.
	cases.append(_sanity_case("A_esc_suficiente", 100, 0, 50, 200, 0.0, 1.0))
	# B) ESC insuficiente (dano > ESC).
	cases.append(_sanity_case("B_esc_insuficiente", 100, 0, 30, 200, 0.0, 1.0))
	# C) ESC zero.
	cases.append(_sanity_case("C_esc_zero", 100, 0, 0, 200, 0.0, 1.0))
	# D) Mago (mesma fórmula estrutural — sem bônus de posição específico).
	cases.append(_sanity_case("D_mago", 100, 0, 30, 200, 0.0, 1.0, "Mago"))
	# E) Afinidade II ativa (multiplicador 0.8, simulado via campo público).
	cases.append(_sanity_case("E_afinidade_ii_ativa", 100, 0, 30, 200, 0.0, 0.8))
	# F) Afinidade II inativa (multiplicador 1.0, mesmo caso de B para contraste).
	cases.append(_sanity_case("F_afinidade_ii_inativa", 100, 0, 30, 200, 0.0, 1.0))

	_write_json("res://reports/f041_sanity.json", {"cases": cases})


func _sanity_case(label: String, atk: int, position_bonus_unused: int, target_esc: int, target_hp: int, unused: float, affinity_multiplier: float, attacker_class: String = "Corpo a Corpo") -> Dictionary:
	var attacker := CombatUnit.new(_build_card("AttackerTeste", "Império", attacker_class, atk, 999, 0), 0, 5)
	var target := CombatUnit.new(_build_card("TargetTeste", "Natureza", "Barreira", 0, target_hp, target_esc), 1, 5)
	target.affinity_incoming_damage_multiplier = affinity_multiplier

	var esc_before: int = target.current_esc
	var hp_before: int = target.current_hp
	var attack_value: float = float(attacker.card.atk)  # posição 5 não tem bônus estrutural — valor bruto puro
	CombatEngine._apply_damage_amount(attack_value, target)

	var result: Dictionary = {
		"label": label,
		"attacker_atk": attacker.card.atk,
		"attack_value_before_affinity": attack_value,
		"affinity_incoming_multiplier": affinity_multiplier,
		"expected_damage_after_affinity": int(round(attack_value * affinity_multiplier)),
		"target_esc_before": esc_before,
		"target_hp_before": hp_before,
		"target_esc_after": target.current_esc,
		"target_hp_after": target.current_hp,
		"esc_lost": esc_before - target.current_esc,
		"hp_lost": hp_before - target.current_hp,
	}
	print("  [%s] ATK=%d ESCantes=%d HPantes=%d mult=%.2f -> ESCdepois=%d HPdepois=%d (ESC perdido=%d HP perdido=%d)" % [
		label, atk, esc_before, hp_before, affinity_multiplier, target.current_esc, target.current_hp, result["esc_lost"], result["hp_lost"]
	])
	return result


# ---------------------------------------------------------------------------
# Utilidades compartilhadas
# ---------------------------------------------------------------------------

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


func _order_names(cards: Array[CardResource]) -> Array[String]:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name)
	return names


# ---------------------------------------------------------------------------
# FASE main — Etapas 3-14: log de CADA ataque, para os 3 Starters, mesmos
# 50 inimigos (idênticos ao F-040 --phase=controlled).
# ---------------------------------------------------------------------------

func _run_main() -> void:
	print("=== F-041 main: atribuição de dano por evento (3 Facções, %d inimigos compartilhados) ===" % CONTROLLED_SAMPLE_SIZE)
	var pool: Dictionary = _generate_enemy_pool(CONTROLLED_SAMPLE_SIZE, ENEMY_SKIP)

	var formations_data: Variant = _read_json("res://reports/f039_formations_Império.json")
	var fid804_order: Array = []
	if formations_data != null:
		for f: Dictionary in formations_data["formations"]:
			if int(f["formation_id"]) == 804:
				fid804_order = f["order"]
				break
	if fid804_order.is_empty():
		print("  AVISO: f039_formations_Império.json (fid=804) não encontrado — usando heuristic como fallback para Império.")

	var starter_cards: Dictionary = {}
	for starter_faction: String in _factions:
		var option: Dictionary = _options_by_faction[starter_faction]
		if starter_faction == "Império" and not fid804_order.is_empty():
			var cards: Array[CardResource] = []
			for name in fid804_order:
				cards.append((_catalog[name] as CardResource).duplicate())
			starter_cards[starter_faction] = cards
		else:
			starter_cards[starter_faction] = ArmyPositioningHeuristic.apply_heuristic((option["cards"] as Array).duplicate())

	var summary_by_starter: Dictionary = {}

	for starter_faction: String in _factions:
		var option: Dictionary = _options_by_faction[starter_faction]
		var cards: Array[CardResource] = starter_cards[starter_faction]
		var entries: Array = pool[starter_faction]
		var track_side: int = 0 if starter_faction == "Império" else -1

		var all_events: Array = []
		var battle_summaries: Array = []

		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var army_a: Army = _army_from_cards(option["commander"], cards)
			var army_b: Army = _army_from_entry(entry)
			var seed_value: int = 60000000 + _factions.find(starter_faction) * 100000 + i

			var battle_data: Dictionary = _run_instrumented_battle(army_a, army_b, seed_value, i, track_side)
			all_events.append_array(battle_data["events"])
			battle_summaries.append(battle_data["summary"])

		print("  %s: %d batalhas, %d eventos de ataque registrados" % [starter_faction, battle_summaries.size(), all_events.size()])
		_write_json("res://reports/f041_damage_events_%s.json" % starter_faction, {"starter_faction": starter_faction, "formation": _order_names(cards), "events": all_events})
		_write_json("res://reports/f041_battle_summaries_%s.json" % starter_faction, {"starter_faction": starter_faction, "battles": battle_summaries})

		summary_by_starter[starter_faction] = {"formation": _order_names(cards), "n_battles": battle_summaries.size(), "n_attack_events": all_events.size()}

	_write_json("res://reports/f041_run_manifest.json", {"enemy_skip": ENEMY_SKIP, "sample_size": CONTROLLED_SAMPLE_SIZE, "starters": summary_by_starter})


## Roda UMA batalha com log completo de cada AFTER_ATTACK — decompõe
## raw/position/commander/affinity SEM tocar CombatEngine: recalcula
## position_multiplier localmente (mesma regra lida do código-fonte,
## nunca modificada) e chama CommanderDoctrineRuntime.attack_multiplier()/
## AffinityRuntime.level_for() diretamente — as MESMAS funções públicas
## que _effective_attack() já chama internamente.
func _run_instrumented_battle(army_a: Army, army_b: Army, seed_value: int, battle_index: int, track_imperio_side: int) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)
	var events: Array = []

	var last_damage_turn: Dictionary = {"turn": 0}
	var last_death_turn: Dictionary = {"turn": 0}
	var attacks_per_turn: Dictionary = {}  # turn(String) -> int

	state.event_bus.subscribe(CombatEventType.Type.AFTER_ATTACK, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		var tkey: String = str(ctx.turn)
		attacks_per_turn[tkey] = attacks_per_turn.get(tkey, 0) + 1
		if ctx.attacker == null or ctx.target == null:
			return  # ataque sem alvo válido (mago com espelho vazio etc.) — já coberto por wasted_attack em F-040/estatística separada
		if ctx.damage_dealt == 0 and ctx.damage_absorbed_by_shield == 0 and ctx.damage_applied_to_hp == 0:
			# alvo já destruído nesta fase (COMBAT_RULES.md 5.3.2) — sem dano de verdade, não é um evento de dano.
			pass

		var attacker: CombatUnit = ctx.attacker
		var target: CombatUnit = ctx.target

		var position_multiplier: float = 1.5 if (attacker.card.card_class == "Corpo a Corpo" and attacker.position == 1) else 1.0
		var commander_multiplier: float = CommanderDoctrineRuntime.attack_multiplier(attacker, state)
		var undead_level: int = AffinityRuntime.level_for(state, attacker.side, "Mortos-Vivos") if attacker.card.faction == "Mortos-Vivos" else 0
		var incoming_multiplier: float = target.affinity_incoming_damage_multiplier

		# Reprodução EXATA da fórmula de CombatEngine._apply_damage_amount()
		# (linha 562: "damage = int(round(attack_value *
		# target.affinity_incoming_damage_multiplier))") — nunca uma
		# fórmula nova, a mesma leitura do código-fonte atual.
		var raw_damage_pre_affinity: int = int(round(ctx.attack_value))
		var computed_damage_post_affinity: int = int(round(ctx.attack_value * incoming_multiplier))
		var damage_dealt: int = ctx.damage_dealt
		# "wasted": o motor calculou computed_damage_post_affinity, mas só
		# aplicou damage_dealt de fato (ESC absorve até seu valor atual e
		# NUNCA deixa o excedente vazar pro HP na mesma ação — COMBAT_RULES.md
		# 4.1 — e HP nunca vai negativo). Sempre >= 0 por construção.
		var wasted: int = maxi(0, computed_damage_post_affinity - damage_dealt)
		# "mitigação de Afinidade": diferença pura entre o dano bruto e o
		# dano já com o multiplicador de Afinidade aplicado — independe de
		# ESC/HP, mede só o efeito do -20%.
		var affinity_mitigation: int = maxi(0, raw_damage_pre_affinity - computed_damage_post_affinity)

		if ctx.damage_dealt > 0 or ctx.damage_absorbed_by_shield > 0 or ctx.damage_applied_to_hp > 0:
			last_damage_turn["turn"] = ctx.turn

		events.append({
			"battle_index": battle_index,
			"turn": ctx.turn,
			"attacker_side": attacker.side,
			"attacker_position": attacker.position,
			"attacker_card": attacker.card.card_name,
			"attacker_faction": attacker.card.faction,
			"attacker_class": attacker.card.card_class,
			"target_side": target.side,
			"target_position": target.position,
			"target_card": target.card.card_name,
			"target_faction": target.card.faction,
			"target_class": target.card.card_class,
			"target_esc_max_base": target.card.esc,
			"target_hp_max_base": target.card.hp,
			"attacker_atk_base": attacker.card.atk,
			"position_multiplier": position_multiplier,
			"commander_multiplier": commander_multiplier,
			"mortos_vivos_affinity_level": undead_level,
			"attack_value_final": ctx.attack_value,
			"target_affinity_incoming_multiplier": incoming_multiplier,
			"damage_absorbed_by_shield": ctx.damage_absorbed_by_shield,
			"damage_applied_to_hp": ctx.damage_applied_to_hp,
			"damage_dealt": damage_dealt,
			"wasted_overflow_damage": wasted,
			"affinity_mitigation": affinity_mitigation,
			"target_esc_after": target.current_esc,
			"target_hp_after": target.current_hp,
		})
	)

	state.event_bus.subscribe(CombatEventType.Type.UNIT_DIED, func(_type: CombatEventType.Type, ctx: CombatContext) -> void:
		last_death_turn["turn"] = ctx.turn
	)

	CombatEngine.run(state)

	var summary: Dictionary = {
		"seed": state.seed_value,
		"winner": ("A" if state.winner_side == 0 else ("B" if state.winner_side == 1 else "empate")),
		"end_reason": state.end_reason,
		"turns": state.turn,
		"battlefield": state.battlefield.battlefield_name if state.battlefield != null else "",
		"last_damage_turn": last_damage_turn["turn"],
		"last_death_turn": last_death_turn["turn"],
		"attacks_per_turn": attacks_per_turn,
	}
	return {"events": events, "summary": summary}
