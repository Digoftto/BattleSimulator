class_name BattlefieldArtCatalog
extends RefCounted
## BattlefieldArtCatalog (ART-001)
##
## Resolve o caminho da arte de fundo de um BattlefieldResource — dado
## puro de apresentação, mesmo princípio de CardArtCatalog: cada Campo
## de Batalha oficial é carregado por GameDatabase a partir de um
## arquivo individual em res://database/battlefields/<slug>.tres (ex:
## "Nevoeiro Arcano" <- nevoeiro_arcano.tres), e a arte foi integrada
## (ART-001) com o mesmo slug como nome de arquivo — o caminho é
## derivado do resource_path real, nunca de uma tradução manual do
## battlefield_name (que nem seria uma tradução mecânica: "Nevoeiro
## Arcano" -> "ARCANE FOG.png" é uma tradução de sentido, não de
## string). Sem exceções conhecidas — os 10 Campos oficiais têm .tres
## próprio, nenhum é gerado dinamicamente como a unidade especial de
## CardArtCatalog.

const ART_DIR: String = "res://assets/art/battlefields/"


static func texture_path_for(battlefield: BattlefieldResource) -> String:
	if battlefield == null or battlefield.resource_path == "":
		return ""
	return ART_DIR + battlefield.resource_path.get_file().get_basename() + ".png"


static func texture_for(battlefield: BattlefieldResource) -> Texture2D:
	var path: String = texture_path_for(battlefield)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
