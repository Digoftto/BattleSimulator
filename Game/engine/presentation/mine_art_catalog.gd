class_name MineArtCatalog
extends RefCounted
## MineArtCatalog (ART-004)
##
## Resolve o caminho da arte de uma Mina — dado puro de apresentação,
## mesmo princípio de CardArtCatalog/BattlefieldArtCatalog/
## CityBuildingArtCatalog/PvEArtCatalog (ART-001/ART-002/ART-003).
##
## Chaves: SEM identificador novo — reaproveita exatamente o que Mina
## já expõe:
##   - MineEconomy.resource_for_faction(mina.faction) ("ferro_negro"/
##     "essencia_vital"/"cristais_arcanos" — já é como minas_panel.gd
##     identifica o recurso de uma Mina hoje);
##   - mina.is_initial_mine() (adjacent_fase == -1);
##   - mina.region (1-3, só relevante pra Minas Regionais).
##
## Minas Regionais (region 1-3) têm arte mapeada aqui só por
## completude de dado (Mina.region já existe no schema hoje,
## independente de haver ou não um caminho de conquista alcançável na
## UI atual — F-022, registrado como futuro) — NENHUMA UI nova, NENHUM
## fluxo de conquista foi criado ou alterado por causa disso. Na
## prática, hoje só as 3 Minas Iniciais aparecem de verdade pro
## jogador (minas_panel.gd só lista Minas com mina.conquered == true,
## e nada na UI atual conquista uma Mina Regional).

const ART_DIR: String = "res://assets/art/pve/minas/"

const VALID_RESOURCES: Array[String] = ["ferro_negro", "essencia_vital", "cristais_arcanos"]


static func texture_path_for_initial_mine(resource_name: String) -> String:
	if not VALID_RESOURCES.has(resource_name):
		return ""
	return ART_DIR + "%s_inicial.png" % resource_name


static func texture_path_for_regional_mine(resource_name: String, region: int) -> String:
	if not VALID_RESOURCES.has(resource_name) or region < 1 or region > 3:
		return ""
	return ART_DIR + "%s_regiao_%d.png" % [resource_name, region]


## API principal: recebe a própria Mina (mesmo padrão de
## fase_category_for_expedition() em PvEArtCatalog — quem chama nunca
## precisa saber a diferença entre Mina Inicial e Regional por conta
## própria, só passa a Mina real).
static func texture_path_for(mina: Mina) -> String:
	if mina == null:
		return ""
	var resource_name: String = MineEconomy.resource_for_faction(mina.faction)
	if mina.is_initial_mine():
		return texture_path_for_initial_mine(resource_name)
	return texture_path_for_regional_mine(resource_name, mina.region)


static func texture_for(mina: Mina) -> Texture2D:
	var path: String = texture_path_for(mina)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
