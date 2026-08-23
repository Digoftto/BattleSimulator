class_name ResourceArtCatalog
extends RefCounted
## ResourceArtCatalog (ART-005)
##
## Resolve o ícone de um recurso bruto — dado puro de apresentação,
## mesmo princípio de CardArtCatalog/BattlefieldArtCatalog/
## CityBuildingArtCatalog/PvEArtCatalog/MineArtCatalog (ART-001..004).
##
## Chave: exatamente o mesmo nome de recurso que o jogo já usa em
## todo lugar — Kingdom.get_raw_resource(resource_name)/
## CityPanel.RAW_RESOURCES ("ferro_negro"/"cristais_arcanos"/
## "essencia_vital") — nenhum identificador novo.

const ART_DIR: String = "res://assets/art/resources/"

const VALID_RESOURCES: Array[String] = ["ferro_negro", "cristais_arcanos", "essencia_vital"]


static func texture_path_for(resource_name: String) -> String:
	if not VALID_RESOURCES.has(resource_name):
		return ""
	return ART_DIR + resource_name + ".png"


static func texture_for(resource_name: String) -> Texture2D:
	var path: String = texture_path_for(resource_name)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
