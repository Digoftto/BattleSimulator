extends Control
## BalanceReportPanel — ferramenta EXTERNA (tools/), desvinculada do
## jogo, reaproveitando o mesmo gerador de composição de Exército do
## PvE (EnemyArmyGenerator.build_composition()) — ver BalanceSimulator.gd
## pro raciocínio completo. Roda o "Meta Aleatório" (OBSERVATORY.md) e
## grava o relatório em res://reports/balance_report.json, que o
## Observatório (dentro do jogo) só lê.

var _root_vbox: VBoxContainer
var _status_label: Label

var _label_edit: LineEdit
var _series_spin: SpinBox
var _seed_spin: SpinBox


func _ready() -> void:
	_build_static_structure()


func _build_static_structure() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(600, 0)
	_root_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Relatório de Balanceamento (Ferramenta Externa)"
	title.add_theme_font_size_override("font_size", 22)
	_root_vbox.add_child(title)

	var warning := Label.new()
	warning.text = "10.000 séries (referência oficial de OBSERVATORY.md) demora bastante de verdade — cada uma é uma batalha real. Ajuste pra uma escala menor se só quiser testar rápido."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(warning)

	var label_row := HBoxContainer.new()
	_root_vbox.add_child(label_row)
	var label_label := Label.new()
	label_label.text = "Rótulo desta rodada:"
	label_label.custom_minimum_size = Vector2(250, 0)
	label_row.add_child(label_label)
	_label_edit = LineEdit.new()
	_label_edit.text = "Rodada de Balanceamento"
	label_row.add_child(_label_edit)

	var series_row := HBoxContainer.new()
	_root_vbox.add_child(series_row)
	var series_label := Label.new()
	series_label.text = "Número de Séries:"
	series_label.custom_minimum_size = Vector2(250, 0)
	series_row.add_child(series_label)
	_series_spin = SpinBox.new()
	_series_spin.min_value = 1
	_series_spin.max_value = 100000
	_series_spin.value = 1000
	series_row.add_child(_series_spin)

	var seed_row := HBoxContainer.new()
	_root_vbox.add_child(seed_row)
	var seed_label := Label.new()
	seed_label.text = "Seed:"
	seed_label.custom_minimum_size = Vector2(250, 0)
	seed_row.add_child(seed_label)
	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 1
	_seed_spin.max_value = 999999999
	_seed_spin.value = 1
	seed_row.add_child(_seed_spin)

	var run_button := Button.new()
	run_button.text = "Rodar"
	run_button.pressed.connect(_on_run_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(run_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(_status_label)


func _on_run_pressed() -> void:
	_status_label.text = "Rodando... (pode demorar, dependendo do número de séries)"

	var config: BalanceSimulationConfig = build_config()
	var report: BalanceReport = BalanceSimulator.run(
		config, GameDatabase.cards, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	SimulationReportService.save_balance_report(report)
	SimulationReportService.append_generation_log({
		"type": "balanceamento",
		"label": report.label,
		"timestamp_unix": report.generated_at_unix,
		"config": {"series_count": config.series_count, "seed_value": config.seed_value},
		"result_summary": {
			"total_battles": report.total_battles, "side_a_wins": report.side_a_wins,
			"side_b_wins": report.side_b_wins, "draws": report.draws,
		},
	})

	var top_cards: Array[String] = report.cards_sorted_by_win_rate()
	var top_text: String = ""
	var bottom_text: String = ""
	for i in range(mini(5, top_cards.size())):
		top_text += "%s (%.1f%%) " % [top_cards[i], report.card_win_rate(top_cards[i]) * 100.0]
	for i in range(maxi(0, top_cards.size() - 5), top_cards.size()):
		bottom_text += "%s (%.1f%%) " % [top_cards[i], report.card_win_rate(top_cards[i]) * 100.0]

	_status_label.text = "Concluído. %d batalhas | Lado A: %.1f%% | Lado B: %.1f%% | Empates: %d\nMelhores cartas: %s\nPiores cartas: %s\nGravado em %s." % [
		report.total_battles, report.side_a_win_rate() * 100.0, report.side_b_win_rate() * 100.0, report.draws,
		top_text, bottom_text, SimulationReportService.BALANCE_REPORT_PATH
	]


func build_config() -> BalanceSimulationConfig:
	var config := BalanceSimulationConfig.new()
	config.label = _label_edit.text
	config.series_count = int(_series_spin.value)
	config.seed_value = int(_seed_spin.value)
	return config
