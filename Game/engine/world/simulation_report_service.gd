class_name SimulationReportService
extends RefCounted
## SimulationReportService
##
## Converte Season (Catálogo + Territórios) e BalanceReport <-> JSON,
## gravados em user:// — a "ponte" entre a ferramenta externa
## (tools/) e o jogo: a ferramenta gera e grava; o jogo só lê.
##
## Mantém também o Registro de Simulações (generation_log.json) — um
## histórico append-only de toda rodada de geração de Exércitos pra
## PvE (parâmetros usados, contagens resultantes, quando rodou), pra
## nunca perder essa informação, como pedido explicitamente.

const SEASON_CATALOG_PATH: String = "res://reports/season_catalog.json"
const BALANCE_REPORT_PATH: String = "res://reports/balance_report.json"
const GENERATION_LOG_PATH: String = "res://reports/generation_log.json"
const REGIONAL_REPORT_PATH_TEMPLATE: String = "res://reports/regional_report_%s_regiao_%d_%s.json"


static func _ensure_reports_dir() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports")


## --- Temporada / Catálogo ---

static func save_season(season: Season) -> bool:
	_ensure_reports_dir()
	var file: FileAccess = FileAccess.open(SEASON_CATALOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SimulationReportService: não foi possível criar %s." % SEASON_CATALOG_PATH)
		return false
	file.store_string(JSON.stringify(_season_to_dict(season), "\t"))
	file.close()
	return true


static func load_season() -> Season:
	if not FileAccess.file_exists(SEASON_CATALOG_PATH):
		return null
	var file: FileAccess = FileAccess.open(SEASON_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		return null
	return _dict_to_season(parsed)


static func _season_to_dict(season: Season) -> Dictionary:
	var territories: Array = []
	for territory_id: String in season.territories:
		var territory: Territory = season.territories[territory_id]
		territories.append({"id": territory.id, "faction": territory.faction})

	var catalog_entries: Dictionary = {}
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		catalog_entries[faction] = {}
		for category in EnemyArmyEntry.Category.values():
			var entries: Array[EnemyArmyEntry] = season.enemy_catalog.get_entries(faction, category)
			var entries_array: Array = []
			for entry: EnemyArmyEntry in entries:
				entries_array.append(_enemy_entry_to_dict(entry))
			catalog_entries[faction][str(category)] = entries_array

	return {
		"season_id": season.season_id,
		"territories": territories,
		"catalog_entries": catalog_entries,
	}


static func _dict_to_season(data: Dictionary) -> Season:
	var season := Season.new(data.get("season_id", ""))
	season.enemy_catalog = SeasonCatalog.new(season.season_id)

	for territory_entry in data.get("territories", []):
		var territory := Territory.new(territory_entry.get("id", ""), territory_entry.get("faction", ""))
		var trilha := Trilha.new(territory.id)
		season.add_territory(territory, trilha)

	var catalog_entries: Dictionary = data.get("catalog_entries", {})
	for faction: String in catalog_entries:
		for category_key: String in catalog_entries[faction]:
			var category: EnemyArmyEntry.Category = int(category_key) as EnemyArmyEntry.Category
			var entries: Array[EnemyArmyEntry] = []
			for entry_dict in catalog_entries[faction][category_key]:
				entries.append(_dict_to_enemy_entry(entry_dict))
			season.enemy_catalog.add_entries(faction, category, entries)

	return season


static func _enemy_entry_to_dict(entry: EnemyArmyEntry) -> Dictionary:
	return {
		"id": entry.id,
		"army_name": entry.army_name,
		"faction": entry.faction,
		"category": int(entry.category),
		"region_min": entry.region_min,
		"region_max": entry.region_max,
		"win_rate": entry.win_rate,
		"cards": entry.cards.map(func(c: CardResource) -> Dictionary: return card_to_dict(c)),
		"commander_name": entry.commander.commander_name if entry.commander != null else "",
		"commander_faction": entry.commander.faction if entry.commander != null else "",
	}


static func _dict_to_enemy_entry(data: Dictionary) -> EnemyArmyEntry:
	var entry := EnemyArmyEntry.new()
	entry.id = data.get("id", "")
	entry.army_name = data.get("army_name", "")
	entry.faction = data.get("faction", "")
	entry.category = data.get("category", 0) as EnemyArmyEntry.Category
	entry.region_min = data.get("region_min", 1)
	entry.region_max = data.get("region_max", 1)
	entry.win_rate = data.get("win_rate", -1.0)

	var cards: Array[CardResource] = []
	for card_dict in data.get("cards", []):
		cards.append(dict_to_card(card_dict))
	entry.cards = cards

	if data.get("commander_name", "") != "":
		var commander := CommanderResource.new()
		commander.commander_name = data.get("commander_name", "")
		commander.faction = data.get("commander_faction", "")
		entry.commander = commander

	return entry


## Serialização leve de carta — só os campos que definem a carta em si
## (nenhum campo de posse: ownership_status/instance_id não fazem
## sentido pra uma entrada de Catálogo, que nunca pertence a um Reino).
static func card_to_dict(card: CardResource) -> Dictionary:
	return {
		"card_name": card.card_name,
		"faction": card.faction,
		"card_class": card.card_class,
		"card_type": card.card_type,
		"rarity": card.rarity,
		"tier": card.tier,
	}


static func dict_to_card(data: Dictionary) -> CardResource:
	var template: CardResource = GameDatabase.get_card(data.get("card_name", ""))
	if template != null:
		var copy: CardResource = template.duplicate()
		copy.tier = data.get("tier", 1)
		return copy

	# Fallback (carta não encontrada no catálogo atual — versão de
	# jogo diferente da que gerou o arquivo): reconstrói só com o que
	# foi salvo, sem os atributos completos do GameDatabase.
	var card := CardResource.new()
	card.card_name = data.get("card_name", "")
	card.faction = data.get("faction", "")
	card.card_class = data.get("card_class", "")
	card.card_type = data.get("card_type", "")
	card.rarity = data.get("rarity", "")
	card.tier = data.get("tier", 1)
	return card


## --- Relatório de Balanceamento ---

static func save_balance_report(report: BalanceReport) -> bool:
	_ensure_reports_dir()
	var file: FileAccess = FileAccess.open(BALANCE_REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SimulationReportService: não foi possível criar %s." % BALANCE_REPORT_PATH)
		return false
	file.store_string(JSON.stringify(report.to_dict(), "\t"))
	file.close()
	return true


static func load_balance_report() -> BalanceReport:
	if not FileAccess.file_exists(BALANCE_REPORT_PATH):
		return null
	var file: FileAccess = FileAccess.open(BALANCE_REPORT_PATH, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		return null
	return BalanceReport.from_dict(parsed)


## --- Relatório de Geração Regional (experimento heurística vs. aleatório) ---

static func save_regional_report(report: RegionalGenerationReport) -> bool:
	_ensure_reports_dir()
	var path: String = REGIONAL_REPORT_PATH_TEMPLATE % [report.territory_faction, report.region, report.category_label]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SimulationReportService: não foi possível criar %s." % path)
		return false
	file.store_string(JSON.stringify(report.to_dict(), "\t"))
	file.close()
	return true


static func load_regional_report(territory_faction: String, region: int, category_label: String) -> RegionalGenerationReport:
	var path: String = REGIONAL_REPORT_PATH_TEMPLATE % [territory_faction, region, category_label]
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary):
		return null
	return RegionalGenerationReport.from_dict(parsed)


## --- Registro de Simulações (append-only, nunca perde rodada) ---

## Acrescenta uma entrada ao Registro — chamado toda vez que "Gerar
## Inimigos para o PvE" roda (o pedido explícito era documentar
## principalmente essa função), mas serve pra qualquer rodada.
static func append_generation_log(entry: Dictionary) -> void:
	_ensure_reports_dir()
	var log: Array = _read_generation_log()
	log.append(entry)

	var file: FileAccess = FileAccess.open(GENERATION_LOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SimulationReportService: não foi possível gravar %s." % GENERATION_LOG_PATH)
		return
	file.store_string(JSON.stringify(log, "\t"))
	file.close()


static func _read_generation_log() -> Array:
	if not FileAccess.file_exists(GENERATION_LOG_PATH):
		return []
	var file: FileAccess = FileAccess.open(GENERATION_LOG_PATH, FileAccess.READ)
	if file == null:
		return []
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not (parsed is Array):
		return []
	return parsed


static func read_generation_log() -> Array:
	return _read_generation_log()
