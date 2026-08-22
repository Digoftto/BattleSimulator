class_name SimulationInsights
extends RefCounted
## SimulationInsights (F-029 §15-17)
##
## Camada de leitura ESTATÍSTICA simples sobre um SimulationReport já
## construído — nenhuma IA, nenhuma linguagem de consulta (§17): cada
## função responde exatamente a UMA pergunta já antecipada pela
## especificação (§15), sempre exigindo uma amostra mínima
## ("minimum_sample_size") antes de declarar qualquer "melhor"/"pior" —
## nunca deixa uma unidade com poucas batalhas parecer "a melhor" só
## por, digamos, 2 batalhas e 100% de Win Rate (§16).
##
## Toda função retorna um Dictionary {"key", "value", "sample_size"}
## (ou os campos equivalentes ao eixo perguntado) — nunca um número
## solto (§16: "nunca retornar apenas win_rate = 73% sem informar
## sample_size"). Retorna {} quando nenhum candidato atinge a amostra
## mínima — nunca um "melhor" forçado.
##
## "Best battlefield"/"Worst battlefield" (§15) são do ponto de vista
## do Lado A (wins_side_a / battles) — convenção documentada aqui, não
## um conceito absoluto: qual Campo de Batalha é "melhor" depende de
## qual Exército está de que lado (§13); esta função só ordena pela
## métrica mais simples e direta possível, sem inventar uma noção mais
## sofisticada de "vantagem".

const DEFAULT_MINIMUM_SAMPLE_SIZE: int = 100


static func highest_win_rate_card(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.unit_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins"]) / float(s["appearances"])
	, true)


static func lowest_win_rate_card(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.unit_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins"]) / float(s["appearances"])
	, false)


## Sem piso de amostra mínima — "mais usada" é a própria contagem de
## amostra, exigir um mínimo aqui não faz sentido.
static func most_used_card(report: SimulationReport) -> Dictionary:
	return _extreme_by(report.unit_stats, "appearances", 0, func(s: Dictionary) -> float:
		return float(s["appearances"])
	, true)


## Requer eventos coletados (SimulationReport.events_collected) — "kills"
## só existe quando a série foi rodada com collect_events=true.
static func most_lethal_card(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	if not report.events_collected:
		return {}
	return _extreme_by(report.unit_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["kills"])
	, true)


static func highest_damage_card(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	if not report.events_collected:
		return {}
	var merged: Dictionary = {}
	for card_name: String in report.unit_stats:
		var appearances: int = report.unit_stats[card_name]["appearances"]
		var damage: int = report.unit_damage_stats.get(card_name, {}).get("damage_dealt", 0)
		merged[card_name] = {"appearances": appearances, "damage_dealt": damage}
	return _extreme_by(merged, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["damage_dealt"])
	, true)


static func highest_death_rate_card(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.unit_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["deaths"]) / float(s["appearances"])
	, true)


static func best_position(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.position_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins"]) / float(s["appearances"])
	, true)


static func worst_position(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.position_stats, "appearances", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins"]) / float(s["appearances"])
	, false)


static func best_battlefield(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.battlefield_stats, "battles", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins_side_a"]) / float(s["battles"])
	, true)


static func worst_battlefield(report: SimulationReport, minimum_sample_size: int = DEFAULT_MINIMUM_SAMPLE_SIZE) -> Dictionary:
	return _extreme_by(report.battlefield_stats, "battles", minimum_sample_size, func(s: Dictionary) -> float:
		return float(s["wins_side_a"]) / float(s["battles"])
	, false)


## Percorre "stats" (Dictionary chave -> Dictionary de contadores),
## descarta entradas com contador "sample_field" abaixo de
## "minimum_sample_size", e retorna a chave com o maior (want_max=true)
## ou menor (false) valor de "value_fn(entry)" entre as restantes.
## {} quando nenhuma entrada atinge a amostra mínima.
static func _extreme_by(stats: Dictionary, sample_field: String, minimum_sample_size: int, value_fn: Callable, want_max: bool) -> Dictionary:
	var best_key: Variant = null
	var best_value: float = 0.0
	var best_sample: int = 0

	for key: Variant in stats:
		var entry: Dictionary = stats[key]
		var sample_size: int = int(entry.get(sample_field, 0))
		if sample_size < minimum_sample_size:
			continue
		var value: float = value_fn.call(entry)
		if best_key == null or (want_max and value > best_value) or (not want_max and value < best_value):
			best_key = key
			best_value = value
			best_sample = sample_size

	if best_key == null:
		return {}
	return {"key": best_key, "value": best_value, "sample_size": best_sample}
