extends Node
## f038_formation_isolation.gd (F-038)
##
## Isola a variável "formação do Starter" mantendo tudo o mais possível
## constante: os MESMOS 1.000 inimigos Tier I/Comum por Starter (gerados
## com a mesma sequência de RNG do F-037 — bit-idênticos), a mesma
## Afinidade ativa (F-035/036, intocada), a mesma seed de combate para o
## par canônico/heurístico de cada índice (mesmo Battlefield sorteado
## nos dois lados do par). NÃO altera StarterKitResolver, CardResource,
## EnemyArmyGenerator, ArmyPositioningHeuristic, CombatEngine ou
## AffinityRuntime — só chama o que já existe.
##
## Metodologia (ver relatório F-038 para a leitura completa):
## - Experimento A: Starter CANÔNICO (ordem de STARTER_ROSTER_CARD_NAMES,
##   intocada) x Enemy (já vem heuristicamente posicionado pelo próprio
##   EnemyArmyGenerator — isso é o próprio F-037, reproduzido aqui com
##   inimigos idênticos para permitir comparação pareada).
## - Experimento B: Starter HEURÍSTICO (mesmas 9 cartas, só reordenadas
##   por ArmyPositioningHeuristic.apply_heuristic(), UMA vez por Starter
##   — determinístico, sem RNG) x os MESMOS 1.000 inimigos de A.
## - Experimento C (ver nota de metodologia impressa em runtime): dado
##   que o inimigo já é sempre heurístico em A e B (característica do
##   próprio EnemyArmyGenerator, que este estágio não pode alterar), não
##   existe uma condição "inimigo não-heurístico" acessível sem violar a
##   restrição de não tocar no gerador — "C" é a ANÁLISE de A vs B
##   (mesma leitura que o texto do C define internamente: "A = Starter
##   canônico x inimigo heurístico; B = Starter heurístico x inimigo
##   heurístico"), não uma terceira bateria de batalhas.
##
## Uso:
##   godot --headless --path Game res://tools/debug/f038_formation_isolation.tscn

const ENEMY_GENERATION_RNG_SEED: int = 39000  # idêntica ao F-037 Fase 3
const ENEMIES_PER_STARTER: int = 1000
const COMBAT_SEED_STRIDE: int = 10000  # separa o espaço de seed de combate por Starter

var _factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
var _options_by_faction: Dictionary = {}


func _ready() -> void:
	print("=== F-038: Isolamento de Formação (Starter Canônico vs Heurístico, mesmos inimigos) ===")
	print("NOTA DE METODOLOGIA: EnemyArmyGenerator já aplica ArmyPositioningHeuristic internamente")
	print("  (confirmado no F-037: 100%% dos inimigos com Corpo a Corpo/Barreira na Posição 1).")
	print("  Não existe, sem alterar o gerador, uma condição de 'inimigo não-heurístico'.")
	print("  Por isso 'Experimento C' desta etapa é tratado como a ANÁLISE de A vs B, não uma")
	print("  terceira bateria de batalhas — ver seção 'Experimento C' do texto do F-038, que")
	print("  já define B internamente como 'Starter heurístico x inimigo heurístico', idêntico")
	print("  ao Experimento B descrito separadamente. Registrado aqui para decisão, não decidido")
	print("  silenciosamente.")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	for option: Dictionary in options:
		_options_by_faction[option["faction"]] = option

	var enemies_by_starter: Dictionary = _generate_enemies_identical_to_f037()
	_run_experiments(enemies_by_starter)

	get_tree().quit()


# ---------------------------------------------------------------------------
# Geração de inimigos — sequência IDÊNTICA à Fase 3 do F-037
# (f037_starter_benchmark.gd:_run_phase_random_enemy), para reprodutibilidade
# bit-a-bit dos mesmos 3.000 inimigos.
# ---------------------------------------------------------------------------

func _generate_enemies_identical_to_f037() -> Dictionary:
	var enemy_generation_rng := RandomNumberGenerator.new()
	enemy_generation_rng.seed = ENEMY_GENERATION_RNG_SEED
	var season_config := SeasonConfig.new()

	var enemies_by_starter: Dictionary = {}
	for starter_faction: String in _factions:
		var entries: Array[EnemyArmyEntry] = []
		for i in range(ENEMIES_PER_STARTER):
			var enemy_faction: String = _factions[enemy_generation_rng.randi_range(0, _factions.size() - 1)]
			var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
				EnemyArmyEntry.Category.NORMAL, enemy_faction, 1, GameDatabase.cards, season_config,
				GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
				GameDatabase.commander_effects, GameDatabase.commander_values,
				"f037_%s" % starter_faction, i, true, enemy_generation_rng
			)
			entries.append(entry)
		enemies_by_starter[starter_faction] = entries
	return enemies_by_starter


# ---------------------------------------------------------------------------
# Utilidades (idênticas em espírito às do F-037)
# ---------------------------------------------------------------------------

func _army_from_cards(commander: CommanderResource, cards: Array[CardResource]) -> Army:
	var army := Army.new()
	army.commander = commander
	army.cards = cards.duplicate()
	return army


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
		names.append(card.card_name if card != null else "")
	return names


## Posição 1 capturada LOGO APÓS CombatEngine.initialize(), ANTES de run()
## — mesma correção já aplicada no F-037, nunca lida depois da batalha.
func _run_and_record(army_a: Army, army_b: Army, seed_value: int, faction_a: String, faction_b: String, enemy_composition: Array[Dictionary]) -> Dictionary:
	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", seed_value)

	var starting_p1: Dictionary = {0: {}, 1: {}}
	for side: int in [0, 1]:
		var unit: CombatUnit = state.unit_at(side, 1)
		if unit != null:
			starting_p1[side] = {"card_name": unit.card.card_name, "card_class": unit.card.card_class}
	var starting_formation_a: Array[String] = _formation_order_names(army_a.cards)
	var starting_formation_b: Array[String] = _formation_order_names(army_b.cards)

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
		"starting_formation_a": starting_formation_a,
		"starting_formation_b": starting_formation_b,
		"enemy_composition": enemy_composition,
	}


func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("  Escrito: %s" % path)


func _summarize(records: Array, label: String) -> Dictionary:
	var wins: int = 0
	var losses: int = 0
	var draws: int = 0
	var decided_by_elimination: int = 0
	var decided_by_turn_limit: int = 0
	var turns_sum: int = 0
	var survivors_sum: int = 0
	var hp_pct_sum: float = 0.0
	var hp_remaining_sum: int = 0
	var margin_hp_sum: float = 0.0
	var margin_surv_sum: int = 0
	var best: Dictionary = {}
	var worst: Dictionary = {}

	for record: Dictionary in records:
		if record["winner"] == "A":
			wins += 1
		elif record["winner"] == "B":
			losses += 1
		else:
			draws += 1
		if record["end_reason"] == "limite_de_turnos":
			decided_by_turn_limit += 1
		else:
			decided_by_elimination += 1
		turns_sum += record["turns"]
		survivors_sum += record["side_a"]["survivors"]
		hp_pct_sum += record["side_a"]["hp_pct_remaining"]
		hp_remaining_sum += record["side_a"]["hp_remaining"]
		margin_hp_sum += record["margin_hp_pct"]
		margin_surv_sum += record["margin_survivors"]

		if best.is_empty() or record["margin_hp_pct"] > best["margin_hp_pct"]:
			best = record
		if worst.is_empty() or record["margin_hp_pct"] < worst["margin_hp_pct"]:
			worst = record

	var n: int = records.size()
	return {
		"label": label,
		"total_battles": n,
		"wins": wins, "wins_pct": (float(wins) / n * 100.0) if n > 0 else 0.0,
		"losses": losses, "losses_pct": (float(losses) / n * 100.0) if n > 0 else 0.0,
		"draws": draws, "draws_pct": (float(draws) / n * 100.0) if n > 0 else 0.0,
		"decided_by_elimination": decided_by_elimination,
		"decided_by_turn_limit": decided_by_turn_limit,
		"avg_turns": float(turns_sum) / n if n > 0 else 0.0,
		"avg_survivors": float(survivors_sum) / n if n > 0 else 0.0,
		"avg_hp_pct_remaining": hp_pct_sum / n if n > 0 else 0.0,
		"avg_hp_remaining": float(hp_remaining_sum) / n if n > 0 else 0.0,
		"avg_margin_hp_pct": margin_hp_sum / n if n > 0 else 0.0,
		"avg_margin_survivors": float(margin_surv_sum) / n if n > 0 else 0.0,
		"best_result": best,
		"worst_result": worst,
	}


# ---------------------------------------------------------------------------
# Execução: para cada Starter, roda A (canônico) e B (heurístico) contra
# os MESMOS 1.000 inimigos, com a MESMA seed de combate por índice
# (garante o mesmo Battlefield sorteado nos dois lados do par).
# ---------------------------------------------------------------------------

func _run_experiments(enemies_by_starter: Dictionary) -> void:
	for starter_index in range(_factions.size()):
		var starter_faction: String = _factions[starter_index]
		var option: Dictionary = _options_by_faction[starter_faction]
		var commander: CommanderResource = option["commander"]
		var canonical_cards: Array[CardResource] = option["cards"]
		var heuristic_cards: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic(canonical_cards.duplicate())

		print("\n--- Starter %s ---" % starter_faction)
		print("  Formação canônica: %s" % ", ".join(_formation_order_names(canonical_cards)))
		print("  Formação heurística: %s" % ", ".join(_formation_order_names(heuristic_cards)))

		var entries: Array[EnemyArmyEntry] = enemies_by_starter[starter_faction]
		var records_a: Array = []
		var records_b: Array = []
		var paired: Array = []

		var seed_base: int = starter_index * COMBAT_SEED_STRIDE

		for i in range(entries.size()):
			var entry: EnemyArmyEntry = entries[i]
			var enemy_commander: CommanderResource = entry.commander
			var enemy_composition: Array[Dictionary] = []
			for card: CardResource in entry.cards:
				enemy_composition.append({"card_name": card.card_name, "faction": card.faction, "card_class": card.card_class, "rarity": card.rarity, "tier": card.tier})

			var combat_seed: int = seed_base + i

			var army_a_canonical: Army = _army_from_cards(commander, canonical_cards)
			var enemy_army_for_a: Army = _army_from_cards(enemy_commander, entry.cards)
			var record_a: Dictionary = _run_and_record(army_a_canonical, enemy_army_for_a, combat_seed, starter_faction, entry.faction, enemy_composition)

			var army_a_heuristic: Army = _army_from_cards(commander, heuristic_cards)
			var enemy_army_for_b: Army = _army_from_cards(enemy_commander, entry.cards)
			var record_b: Dictionary = _run_and_record(army_a_heuristic, enemy_army_for_b, combat_seed, starter_faction, entry.faction, enemy_composition)

			records_a.append(record_a)
			records_b.append(record_b)
			paired.append({
				"index": i,
				"combat_seed": combat_seed,
				"enemy_faction": entry.faction,
				"canonical_winner": record_a["winner"],
				"heuristic_winner": record_b["winner"],
				"canonical_margin_hp_pct": record_a["margin_hp_pct"],
				"heuristic_margin_hp_pct": record_b["margin_hp_pct"],
				"flip": record_a["winner"] != record_b["winner"],
			})

		var summary_a: Dictionary = _summarize(records_a, "%s canônico x %s inimigos aleatórios" % [starter_faction, entries.size()])
		var summary_b: Dictionary = _summarize(records_b, "%s heurístico x %s mesmos inimigos" % [starter_faction, entries.size()])

		var flips: int = 0
		for p: Dictionary in paired:
			if p["flip"]:
				flips += 1

		print("  [A] Canônico  -> vitórias: %d (%.1f%%) | derrotas: %d | empates: %d | elim: %d | limite: %d | turnos médios: %.1f | sobreviventes médios: %.2f | HP%% médio restante: %.3f" % [
			summary_a["wins"], summary_a["wins_pct"], summary_a["losses"], summary_a["draws"], summary_a["decided_by_elimination"], summary_a["decided_by_turn_limit"],
			summary_a["avg_turns"], summary_a["avg_survivors"], summary_a["avg_hp_pct_remaining"]
		])
		print("  [B] Heurístico -> vitórias: %d (%.1f%%) | derrotas: %d | empates: %d | elim: %d | limite: %d | turnos médios: %.1f | sobreviventes médios: %.2f | HP%% médio restante: %.3f" % [
			summary_b["wins"], summary_b["wins_pct"], summary_b["losses"], summary_b["draws"], summary_b["decided_by_elimination"], summary_b["decided_by_turn_limit"],
			summary_b["avg_turns"], summary_b["avg_survivors"], summary_b["avg_hp_pct_remaining"]
		])
		print("  Diferença A->B: %+.1f pontos percentuais de vitória | %d de %d batalhas (%.1f%%) mudaram de vencedor" % [
			summary_b["wins_pct"] - summary_a["wins_pct"], flips, entries.size(), float(flips) / entries.size() * 100.0
		])

		_write_json(
			"res://reports/f038_starter_%s.json" % starter_faction,
			{
				"starter_faction": starter_faction,
				"canonical_formation": _formation_order_names(canonical_cards),
				"heuristic_formation": _formation_order_names(heuristic_cards),
				"summary_a_canonical": summary_a,
				"summary_b_heuristic": summary_b,
				"paired_comparison": paired,
				"battles_a_canonical": records_a,
				"battles_b_heuristic": records_b,
			}
		)
