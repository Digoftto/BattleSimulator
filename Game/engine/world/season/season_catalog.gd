class_name SeasonCatalog
extends RefCounted
## SeasonCatalog
##
## Catálogo Oficial da Temporada — resultado persistente do Pipeline de
## Geração (PvE.md). Organizado por Facção (Trilha) e Categoria; dentro
## de cada categoria, os Exércitos já chegam ordenados por WR e
## distribuídos em faixas (Região). Apenas dado — nenhuma lógica de
## seleção (isso é responsabilidade de EnemyArmySelector).

var season_id: String = ""

## Dictionary[String Facção][EnemyArmyEntry.Category] -> Array[EnemyArmyEntry]
var _entries: Dictionary = {}


func _init(p_season_id: String) -> void:
	season_id = p_season_id


func add_entries(faction: String, category: EnemyArmyEntry.Category, entries: Array[EnemyArmyEntry]) -> void:
	if not _entries.has(faction):
		_entries[faction] = {}
	_entries[faction][category] = entries


func get_entries(faction: String, category: EnemyArmyEntry.Category) -> Array[EnemyArmyEntry]:
	if not _entries.has(faction) or not _entries[faction].has(category):
		return []
	return _entries[faction][category]


## Retorna as entradas de uma Facção/Categoria cuja faixa de Região
## inclui a Região informada (1, 2 ou 3).
func get_entries_for_region(faction: String, category: EnemyArmyEntry.Category, region: int) -> Array[EnemyArmyEntry]:
	var all_entries: Array[EnemyArmyEntry] = get_entries(faction, category)
	var result: Array[EnemyArmyEntry] = []
	for entry: EnemyArmyEntry in all_entries:
		if region >= entry.region_min and region <= entry.region_max:
			result.append(entry)
	return result
