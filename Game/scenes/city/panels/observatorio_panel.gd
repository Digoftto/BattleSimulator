extends Control
## ObservatorioPanel (OBSERVATORY.md)
##
## Só LÊ e mostra o Relatório de Balanceamento — quem GERA é a
## ferramenta externa (tools/balance_report/), nunca este painel (ver
## decisão registrada na conversa: Observatório = relatório de
## balanceamento de Cartas/Formações, não histórico de Comandante nem
## gerador de Exércitos — esses são outras duas peças, já resolvidas
## em outro lugar). Também mostra o Registro de Simulações (histórico
## de rodadas já feitas, incluindo gerações de PvE).

var _root_vbox: VBoxContainer


func _ready() -> void:
	refresh()
	print("[ObservatorioPanel] Pronto.")


func refresh() -> void:
	_clear_children(self)
	_build_structure()


func _build_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(750, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Observatório"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	var back_button := Button.new()
	back_button.text = "<- Voltar para a Cidade"
	back_button.pressed.connect(_on_back_to_city_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(back_button)

	var note := Label.new()
	note.text = "Este painel só mostra o relatório mais recente já gerado — a geração em si acontece na ferramenta externa (tools/balance_report/balance_report_panel.tscn), fora do jogo."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(note)

	_add_section_title("Relatório de Balanceamento")
	_build_report_section()

	_add_section_title("Registro de Simulações")
	_build_generation_log_section()

	var refresh_button := Button.new()
	refresh_button.text = "Recarregar"
	refresh_button.pressed.connect(refresh, CONNECT_DEFERRED)
	_root_vbox.add_child(refresh_button)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


func _build_report_section() -> void:
	var report: BalanceReport = SimulationReportService.load_balance_report()
	if report == null:
		var empty_label := Label.new()
		empty_label.text = "Nenhum relatório gerado ainda. Rode a ferramenta externa de Balanceamento primeiro."
		_root_vbox.add_child(empty_label)
		return

	var header := Label.new()
	header.text = "\"%s\" — %d batalhas (%d séries, seed %d) | Lado A: %.1f%% | Lado B: %.1f%% | Empates: %d" % [
		report.label, report.total_battles, report.series_count, report.seed_value,
		report.side_a_win_rate() * 100.0, report.side_b_win_rate() * 100.0, report.draws
	]
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(header)

	var cards_title := Label.new()
	cards_title.text = "Win Rate por Carta (todas, ordenadas — maior primeiro):"
	_root_vbox.add_child(cards_title)
	for card_name: String in report.cards_sorted_by_win_rate():
		var stats: Dictionary = report.card_stats[card_name]
		var label := Label.new()
		label.text = "%s: %.1f%% (%d aparições)" % [card_name, report.card_win_rate(card_name) * 100.0, stats["appearances"]]
		_root_vbox.add_child(label)

	var position_title := Label.new()
	position_title.text = "Win Rate por Posição (1-9):"
	_root_vbox.add_child(position_title)
	for position in range(1, 10):
		if not report.position_stats.has(position):
			continue
		var stats: Dictionary = report.position_stats[position]
		var label := Label.new()
		label.text = "Posição %d: %.1f%% (%d aparições)" % [position, report.position_win_rate(position) * 100.0, stats["appearances"]]
		_root_vbox.add_child(label)


func _build_generation_log_section() -> void:
	var log: Array = SimulationReportService.read_generation_log()
	if log.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhuma rodada registrada ainda."
		_root_vbox.add_child(empty_label)
		return

	for i in range(log.size() - 1, maxi(-1, log.size() - 11), -1):  # últimas 10, mais recente primeiro
		var entry: Dictionary = log[i]
		var label := Label.new()
		label.text = "[%s] %s" % [entry.get("type", ""), JSON.stringify(entry)]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_root_vbox.add_child(label)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
