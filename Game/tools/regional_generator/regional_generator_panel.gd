extends Control
## RegionalGeneratorPanel — ferramenta EXTERNA (tools/), desvinculada
## do jogo, mesmas regras de Exército/Combate já testadas. Roda o
## experimento acordado: Benchmark Regional (20, metade com Máquina de
## Guerra) + N candidatos de "Fases Normais" contra ele, parte com a
## heurística de posicionamento, parte totalmente aleatório — pra
## comparar as duas distribuições de Win Rate e validar empiricamente
## o quanto posicionamento pesa. Grava em
## res://reports/regional_report_<Território>_regiao_<N>.json, que o
## Observatório só lê.
##
## ATENÇÃO DE PERFORMANCE: em escala real (milhares de candidatos ×
## várias simulações cada) isso é trabalho de verdade de CombatEngine
## — pode demorar muito. A janela trava enquanto roda (GDScript é
## single-threaded) — sem barra de progresso possível nesta versão.

var _root_vbox: VBoxContainer
var _status_label: Label

var _territory_option: OptionButton
var _region_option: OptionButton
var _heuristic_spin: SpinBox
var _random_spin: SpinBox
var _simulations_spin: SpinBox
var _seed_spin: SpinBox

const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]


func _ready() -> void:
	_build_static_structure()


func _build_static_structure() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(650, 0)
	_root_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Geração Regional (Ferramenta Externa)"
	title.add_theme_font_size_override("font_size", 22)
	_root_vbox.add_child(title)

	var warning := Label.new()
	warning.text = "Cada candidato é avaliado com batalhas reais de CombatEngine contra o Benchmark Regional. Em escala real (milhares de candidatos) isso demora bastante — a janela trava enquanto roda, sem barra de progresso."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(warning)

	_territory_option = _add_option_field("Território (Trilha)", FACTIONS)
	_region_option = _add_option_field("Região", ["I", "II", "III"])
	_heuristic_spin = _add_number_field("Candidatos com Heurística de Posicionamento", 20000, 200000)
	_random_spin = _add_number_field("Candidatos com Posicionamento Aleatório", 10000, 200000)
	_simulations_spin = _add_number_field("Simulações por Candidato (contra o Benchmark)", 20, 1000)
	_seed_spin = _add_number_field("Seed", 1, 999999999)

	var run_button := Button.new()
	run_button.text = "Rodar"
	run_button.pressed.connect(_on_run_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(run_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(_status_label)


func _add_option_field(label_text: String, options: Array[String]) -> OptionButton:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(320, 0)
	row.add_child(label)
	var option := OptionButton.new()
	for value: String in options:
		option.add_item(value)
	row.add_child(option)
	return option


func _add_number_field(label_text: String, default_value: int, max_value: int) -> SpinBox:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(320, 0)
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = max_value
	spin.value = default_value
	row.add_child(spin)
	return spin


func _on_run_pressed() -> void:
	_status_label.text = "Rodando... (pode demorar bastante em escala real)"

	var territory: String = FACTIONS[_territory_option.selected]
	var region: int = _region_option.selected + 1  # I=1, II=2, III=3
	var heuristic_count: int = int(_heuristic_spin.value)
	var random_count: int = int(_random_spin.value)
	var simulations: int = int(_simulations_spin.value)
	var seed_value: int = int(_seed_spin.value)

	var started_at: int = Time.get_ticks_msec()
	var report: RegionalGenerationReport = RegionalGenerationRunner.run(
		territory, region, GameDatabase.cards, heuristic_count, random_count, simulations, seed_value,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var elapsed_seconds: float = (Time.get_ticks_msec() - started_at) / 1000.0

	SimulationReportService.save_regional_report(report)
	SimulationReportService.append_generation_log({
		"type": "geracao_regional",
		"territory_faction": territory,
		"region": region,
		"timestamp_unix": report.generated_at_unix,
		"elapsed_seconds": elapsed_seconds,
		"config": {
			"heuristic_count": heuristic_count, "random_count": random_count,
			"simulations_per_candidate": simulations, "seed_value": seed_value,
		},
	})

	var heuristic_wrs: Array[float] = report.win_rates_for("heuristic")
	var random_wrs: Array[float] = report.win_rates_for("random")
	var heuristic_median: float = RegionalGenerationReport.median(heuristic_wrs)

	var above_median: int = 0
	for wr: float in random_wrs:
		if wr > heuristic_median:
			above_median += 1

	_status_label.text = "Concluído em %.1fs.\nMediana WR (heurística): %.1f%%\nMediana WR (aleatório): %.1f%%\nDos %d candidatos aleatórios, %d (%.1f%%) ficaram ACIMA da mediana da heurística, %d abaixo.\nGravado em res://reports/regional_report_%s_regiao_%d_fases_normais.json." % [
		elapsed_seconds, heuristic_median * 100.0, RegionalGenerationReport.median(random_wrs) * 100.0,
		random_wrs.size(), above_median, (float(above_median) / float(random_wrs.size()) * 100.0) if not random_wrs.is_empty() else 0.0,
		random_wrs.size() - above_median, territory, region
	]
