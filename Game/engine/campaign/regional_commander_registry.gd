class_name RegionalCommanderRegistry
extends RefCounted
## RegionalCommanderRegistry
##
## Rastreia, para um jogador, quais Comandantes Regionais já ingressaram
## no Reino (PvE.md, "Comandante Regional Recrutado"). Apenas dado —
## nenhuma lógica de recrutamento em si (pertence a uma Sprint futura
## de Centro de Comando/Recrutamento). Afeta apenas a Expedição daquele
## jogador; o Catálogo Oficial da Temporada nunca é alterado.

var _recruited: Dictionary = {}  # "faccao_regiao" -> true


func recruit(faction: String, region: int) -> void:
	_recruited[_key(faction, region)] = true


func is_recruited(faction: String, region: int) -> bool:
	return _recruited.has(_key(faction, region))


func _key(faction: String, region: int) -> String:
	return "%s_%d" % [faction, region]


## Exporta o estado recrutado, para persistência (KingdomSaveService).
## Retorna uma cópia — nunca a referência interna.
func export_data() -> Dictionary:
	return _recruited.duplicate()


## Restaura o estado a partir de dados salvos (KingdomSaveService).
func import_data(data: Dictionary) -> void:
	_recruited = data.duplicate()
