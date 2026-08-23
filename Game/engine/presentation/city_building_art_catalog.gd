class_name CityBuildingArtCatalog
extends RefCounted
## CityBuildingArtCatalog (ART-002)
##
## Resolve o caminho da ilustração de detalhe de um prédio da Cidade —
## dado puro de apresentação, mesmo princípio de CardArtCatalog/
## BattlefieldArtCatalog (ART-001).
##
## Chave: o identificador de prédio que JÁ EXISTE e já é estável em
## city_panel.gd (CityPanel.BUILDING_REGIONS.keys() / _selected_building_key
## — "capital", "biblioteca", "observatorio", "academia",
## "centro_de_comando", "depositos", "nucleo_de_energia") — reaproveitado
## aqui sem nenhum identificador novo, per ART-002 §4.
##
## Cada prédio tem várias ilustrações candidatas em Assets/MVP/Construções/
## (ex: Capital.png, Capital-V2.png, "CAPITAL-Kindon overview.png",
## "CAPITAL-Kingdom Statistics Popup.png"...) — sem uma variante por
## ESTADO de jogo real (Nível, bloqueado/desbloqueado) modelada em
## nenhum lugar do jogo hoje, ART-002 usa deliberadamente só a
## ilustração "principal" de cada prédio (o arquivo cujo nome
## corresponde diretamente ao prédio, sem sufixo de variante) — as
## demais ficam registradas como candidatas futuras (TECHNICAL_BACKLOG.md),
## nunca usadas pra inventar um estado de UI que não existe no jogo.

const ART_DIR: String = "res://assets/art/city_buildings/"

## Mesmas 7 chaves de CityPanel.BUILDING_REGIONS — nenhuma chave nova.
const BUILDING_KEYS_WITH_ART: Array[String] = [
	"capital", "biblioteca", "observatorio", "academia",
	"centro_de_comando", "depositos", "nucleo_de_energia",
]


static func texture_path_for(building_key: String) -> String:
	if building_key == "" or not BUILDING_KEYS_WITH_ART.has(building_key):
		return ""
	return ART_DIR + building_key + ".png"


static func texture_for(building_key: String) -> Texture2D:
	var path: String = texture_path_for(building_key)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
