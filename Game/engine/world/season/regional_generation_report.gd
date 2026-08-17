class_name RegionalGenerationReport
extends RefCounted
## RegionalGenerationReport
##
## Resultado de uma rodada de geração/simulação por Região: Win Rate
## de cada candidato contra o Benchmark Regional, marcado por qual
## modo de posicionamento foi usado (heurística ou aleatório) — pra
## comparar as duas distribuições, o experimento pedido explicitamente.

var territory_faction: String = ""
var region: int = 0
var category_label: String = ""  # "fases_normais", "chefe_normal", "chefe_regional", "chefe_de_mina"
var benchmark_size: int = 0
var simulations_per_candidate: int = 0
var generated_at_unix: int = 0
var seed_value: int = 0

## Cada entrada: {"win_rate": float, "positioning": "heuristic"/"random"}
var candidate_results: Array[Dictionary] = []


func win_rates_for(positioning: String) -> Array[float]:
	var result: Array[float] = []
	for entry: Dictionary in candidate_results:
		if entry["positioning"] == positioning:
			result.append(entry["win_rate"])
	return result


static func median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values: Array[float] = values.duplicate()
	sorted_values.sort()
	var mid: int = sorted_values.size() / 2
	if sorted_values.size() % 2 == 0:
		return (sorted_values[mid - 1] + sorted_values[mid]) / 2.0
	return sorted_values[mid]


func to_dict() -> Dictionary:
	return {
		"territory_faction": territory_faction,
		"region": region,
		"category_label": category_label,
		"benchmark_size": benchmark_size,
		"simulations_per_candidate": simulations_per_candidate,
		"generated_at_unix": generated_at_unix,
		"seed_value": seed_value,
		"candidate_results": candidate_results,
	}


static func from_dict(data: Dictionary) -> RegionalGenerationReport:
	var report := RegionalGenerationReport.new()
	report.territory_faction = data.get("territory_faction", "")
	report.region = data.get("region", 0)
	report.category_label = data.get("category_label", "")
	report.benchmark_size = data.get("benchmark_size", 0)
	report.simulations_per_candidate = data.get("simulations_per_candidate", 0)
	report.generated_at_unix = data.get("generated_at_unix", 0)
	report.seed_value = data.get("seed_value", 0)
	var results: Array[Dictionary] = []
	for entry in data.get("candidate_results", []):
		results.append(entry as Dictionary)
	report.candidate_results = results
	return report
