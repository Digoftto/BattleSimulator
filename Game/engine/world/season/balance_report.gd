class_name BalanceReport
extends RefCounted
## BalanceReport (OBSERVATORY.md)
##
## Resultado agregado de uma rodada de simulação de balanceamento:
## resultado geral (Vitórias A/B/Empates), Win Rate por Carta, Win
## Rate por Posição (1-9) — os mesmos eixos de análise documentados em
## OBSERVATORY.md ("melhores/piores cartas", "desempenho por
## Formação").

var label: String = ""
var generated_at_unix: int = 0
var series_count: int = 0
var seed_value: int = 0

var total_battles: int = 0
var side_a_wins: int = 0
var side_b_wins: int = 0
var draws: int = 0

## card_name -> {"appearances": int, "wins": int}
var card_stats: Dictionary = {}

## posição (1-9) -> {"appearances": int, "wins": int}
var position_stats: Dictionary = {}


func side_a_win_rate() -> float:
	return float(side_a_wins) / float(total_battles) if total_battles > 0 else 0.0


func side_b_win_rate() -> float:
	return float(side_b_wins) / float(total_battles) if total_battles > 0 else 0.0


func card_win_rate(card_name: String) -> float:
	if not card_stats.has(card_name) or card_stats[card_name]["appearances"] == 0:
		return 0.0
	return float(card_stats[card_name]["wins"]) / float(card_stats[card_name]["appearances"])


func position_win_rate(position: int) -> float:
	if not position_stats.has(position) or position_stats[position]["appearances"] == 0:
		return 0.0
	return float(position_stats[position]["wins"]) / float(position_stats[position]["appearances"])


## Cartas ordenadas por Win Rate (maior primeiro) — pra "melhores/
## piores cartas" (OBSERVATORY.md).
func cards_sorted_by_win_rate() -> Array[String]:
	var names: Array[String] = []
	for name: String in card_stats:
		names.append(name)
	names.sort_custom(func(a: String, b: String) -> bool: return card_win_rate(a) > card_win_rate(b))
	return names


func to_dict() -> Dictionary:
	return {
		"label": label,
		"generated_at_unix": generated_at_unix,
		"series_count": series_count,
		"seed_value": seed_value,
		"total_battles": total_battles,
		"side_a_wins": side_a_wins,
		"side_b_wins": side_b_wins,
		"draws": draws,
		"card_stats": card_stats,
		"position_stats": position_stats,
	}


static func from_dict(data: Dictionary) -> BalanceReport:
	var report := BalanceReport.new()
	report.label = data.get("label", "")
	report.generated_at_unix = data.get("generated_at_unix", 0)
	report.series_count = data.get("series_count", 0)
	report.seed_value = data.get("seed_value", 0)
	report.total_battles = data.get("total_battles", 0)
	report.side_a_wins = data.get("side_a_wins", 0)
	report.side_b_wins = data.get("side_b_wins", 0)
	report.draws = data.get("draws", 0)
	report.card_stats = data.get("card_stats", {})
	var position_stats: Dictionary = {}
	for key in data.get("position_stats", {}):
		position_stats[int(key)] = data["position_stats"][key]
	report.position_stats = position_stats
	return report
