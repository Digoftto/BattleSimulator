extends Control
## PveGeneratorPanel — ferramenta EXTERNA (tools/), desvinculada do
## jogo, mas usando exatamente as mesmas regras de Exército/Combate
## (SeasonPipeline/EnemyArmyGenerator/SeasonBenchmark, as mesmas
## classes já testadas no jogo em si). Gera o Catálogo de Exércitos
## Inimigos pro PvE, grava em res://reports/season_catalog.json (que
## o jogo carrega — ver WorldBootstrap.gd), e registra a rodada no
## Registro de Simulações (parâmetros + resultado + quando rodou),
## pra nunca perder essa informação.
##
## Rodável de duas formas: abrindo esta cena no Editor (F6) — interface
## completa pra ajustar os parâmetros manualmente — ou via linha de
## comando headless, direto pelos parâmetros padrão (SeasonConfig já
## traz os valores oficiais).

var _root_vbox: VBoxContainer
var _status_label: Label

var _season_id_edit: LineEdit
var _seed_spin: SpinBox
var _normal_army_spin: SpinBox
var _chefe_normal_spin: SpinBox
var _chefe_regional_generated_spin: SpinBox
var _chefe_regional_kept_spin: SpinBox
var _simulations_spin: SpinBox
var _benchmark_spin: SpinBox


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
	title.text = "Gerador de Inimigos para o PvE (Ferramenta Externa)"
	title.add_theme_font_size_override("font_size", 22)
	_root_vbox.add_child(title)

	var warning := Label.new()
	warning.text = "Escala oficial (100.000 Exércitos Normais, 100.000 simulações cada) demora bastante de verdade. Ajuste os valores abaixo pra uma escala de teste, se só quiser validar rápido."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(warning)

	_season_id_edit = _add_field("ID da Temporada", "Season01")
	_seed_spin = _add_number_field("Seed", 1, 999999999)
	_normal_army_spin = _add_number_field("Exércitos Normais", 100000, 1000000)
	_chefe_normal_spin = _add_number_field("Chefes Normais", 3000, 100000)
	_chefe_regional_generated_spin = _add_number_field("Chefes Regionais/Mina — Gerados", 5000, 100000)
	_chefe_regional_kept_spin = _add_number_field("Chefes Regionais/Mina — Mantidos (melhor WR)", 3000, 100000)
	_simulations_spin = _add_number_field("Simulações por Exército (Benchmark)", 100000, 1000000)
	_benchmark_spin = _add_number_field("Tamanho do Benchmark", 20, 1000)

	var generate_button := Button.new()
	generate_button.text = "Gerar"
	generate_button.pressed.connect(_on_generate_pressed, CONNECT_DEFERRED)
	_root_vbox.add_child(generate_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root_vbox.add_child(_status_label)


func _add_field(label_text: String, default_value: String) -> LineEdit:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(300, 0)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = default_value
	row.add_child(edit)
	return edit


func _add_number_field(label_text: String, default_value: int, max_value: int) -> SpinBox:
	var row := HBoxContainer.new()
	_root_vbox.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(300, 0)
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = max_value
	spin.value = default_value
	row.add_child(spin)
	return spin


func _on_generate_pressed() -> void:
	_status_label.text = "Gerando... (pode demorar, dependendo da escala escolhida)"

	var config: SeasonConfig = build_config()
	var started_at: int = Time.get_ticks_msec()

	var catalog: SeasonCatalog = SeasonPipeline.run(
		config, GameDatabase.cards, GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	var season := Season.new(config.season_id)
	season.enemy_catalog = catalog
	for faction: String in SeasonPipeline.FACTIONS:
		var territory := Territory.new("Território de %s" % faction, faction)
		var trilha := Trilha.new(territory.id)
		season.add_territory(territory, trilha)

	SimulationReportService.save_season(season)

	var elapsed_seconds: float = (Time.get_ticks_msec() - started_at) / 1000.0
	var counts: Dictionary = _count_entries(catalog)

	SimulationReportService.append_generation_log({
		"type": "gerar_inimigos_pve",
		"season_id": config.season_id,
		"timestamp_unix": GameClock.now_unix(),
		"elapsed_seconds": elapsed_seconds,
		"config": {
			"seed_value": config.seed_value,
			"normal_army_count": config.normal_army_count,
			"chefe_normal_count": config.chefe_normal_count,
			"chefe_regional_mina_generated_count": config.chefe_regional_mina_generated_count,
			"chefe_regional_mina_kept_count": config.chefe_regional_mina_kept_count,
			"simulations_per_army": config.simulations_per_army,
			"benchmark_size": config.benchmark_size,
		},
		"result_counts": counts,
	})

	_status_label.text = "Concluído em %.1fs. Gravado em %s.\nContagens: %s\nRegistrado no Registro de Simulações (%s)." % [
		elapsed_seconds, SimulationReportService.SEASON_CATALOG_PATH, JSON.stringify(counts), SimulationReportService.GENERATION_LOG_PATH
	]


func build_config() -> SeasonConfig:
	var config := SeasonConfig.new()
	config.season_id = _season_id_edit.text
	config.seed_value = int(_seed_spin.value)
	config.normal_army_count = int(_normal_army_spin.value)
	config.chefe_normal_count = int(_chefe_normal_spin.value)
	config.chefe_regional_mina_generated_count = int(_chefe_regional_generated_spin.value)
	config.chefe_regional_mina_kept_count = int(_chefe_regional_kept_spin.value)
	config.simulations_per_army = int(_simulations_spin.value)
	config.benchmark_size = int(_benchmark_spin.value)
	return config


func _count_entries(catalog: SeasonCatalog) -> Dictionary:
	var counts: Dictionary = {}
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var faction_counts: Dictionary = {}
		for category in EnemyArmyEntry.Category.values():
			faction_counts[EnemyArmyEntry.Category.keys()[category]] = catalog.get_entries(faction, category).size()
		counts[faction] = faction_counts
	return counts
