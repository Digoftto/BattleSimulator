extends Control
## RegionalChiefGeneratorPanel — ferramenta EXTERNA (tools/), gera
## candidatos das categorias COM Comandante (Chefes Normais, Chefes
## Regionais, Chefe de Mina) pra uma Região/Território específico,
## sempre com a heurística de posicionamento (decisão confirmada — ver
## RegionalCategoryGenerationRunner.gd). Grava em
## res://reports/regional_report_<Território>_regiao_<N>_<categoria>.json
## — nome de arquivo já inclui a categoria, então não sobrescreve o
## relatório de Fases Normais nem o de outra categoria pra mesma
## combinação Território/Região.
##
## ATENÇÃO DE PERFORMANCE: mesmo aviso de sempre — cada candidato roda
## batalhas reais de CombatEngine contra o Benchmark Regional.

var _root_vbox: VBoxContainer
var _status_label: Label

var _category_option: OptionButton
var _territory_option: OptionButton
var _region_option: OptionButton
var _candidate_spin: SpinBox
var _simulations_spin: SpinBox
var _min_rarity_spin: SpinBox
var _seed_spin: SpinBox

const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
const CATEGORIES: Array[EnemyArmyEntry.Category] = [
	EnemyArmyEntry.Category.CHEFE_NORMAL, EnemyArmyEntry.Category.CHEFE_REGIONAL, EnemyArmyEntry.Category.CHEFE_DE_MINA,
]
const CATEGORY_LABELS: Array[String] = ["Chefe Normal", "Chefe Regional", "Chefe de Mina"]


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
	title.text = "Geração de Chefes (Ferramenta Externa)"
	title.add_theme_font_size_override("font_size", 22)
	_root_vbox.add_child(title)

	var warning := Label.new()
	warning.text = "Cada candidato é avaliado com batalhas reais de CombatEngine contra o Benchmark Regional. A janela trava enquanto roda, sem barra de progresso."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(warning)

	_category_option = _add_option_field("Categoria", CATEGORY_LABELS)
	_territory_option = _add_option_field("Território (Trilha)", FACTIONS)
	_region_option = _add_option_field("Região", ["I", "II", "III"])
	_candidate_spin = _add_number_field("Candidatos a gerar", 3000, 100000)
	_simulations_spin = _add_number_field("Simulações por Candidato (contra o Benchmark)", 20, 1000)
	_min_rarity_spin = _add_number_field("Rarity Score mínimo (só Chefe Regional/Mina — 5 a 80)", 40, 80)
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
	label.custom_minimum_size = Vector2(380, 0)
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
	label.custom_minimum_size = Vector2(380, 0)
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = max_value
	spin.value = default_value
	row.add_child(spin)
	return spin


func _on_run_pressed() -> void:
	_status_label.text = "Rodando... (pode demorar bastante em escala real)"

	var category: EnemyArmyEntry.Category = CATEGORIES[_category_option.selected]
	var territory: String = FACTIONS[_territory_option.selected]
	var region: int = _region_option.selected + 1
	var candidate_count: int = int(_candidate_spin.value)
	var simulations: int = int(_simulations_spin.value)
	var seed_value: int = int(_seed_spin.value)

	var config := SeasonConfig.new()
	config.min_rarity_score_exclusive = int(_min_rarity_spin.value)

	var started_at: int = Time.get_ticks_msec()
	var report: RegionalGenerationReport = RegionalCategoryGenerationRunner.run(
		category, territory, region, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values,
		candidate_count, simulations, seed_value,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var elapsed_seconds: float = (Time.get_ticks_msec() - started_at) / 1000.0

	SimulationReportService.save_regional_report(report)
	SimulationReportService.append_generation_log({
		"type": "geracao_chefes",
		"category": CATEGORY_LABELS[_category_option.selected],
		"territory_faction": territory,
		"region": region,
		"timestamp_unix": report.generated_at_unix,
		"elapsed_seconds": elapsed_seconds,
		"config": {
			"candidate_count": candidate_count, "simulations_per_candidate": simulations,
			"seed_value": seed_value, "min_rarity_score_exclusive": config.min_rarity_score_exclusive,
		},
	})

	var win_rates: Array[float] = report.win_rates_for("heuristic")
	_status_label.text = "Concluído em %.1fs.\n%d candidatos avaliados | Mediana de Win Rate: %.1f%%\nGravado em res://reports/regional_report_%s_regiao_%d_%s.json." % [
		elapsed_seconds, win_rates.size(), RegionalGenerationReport.median(win_rates) * 100.0, territory, region, report.category_label
	]
