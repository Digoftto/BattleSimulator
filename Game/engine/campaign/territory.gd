class_name Territory
extends RefCounted
## Territory (PvE.md, "Hierarquia Territorial da Campanha Militar")
##
## Unidade de mais alto nível da Campanha: cada Território pertence a
## exatamente uma Facção e contém sua Trilha correspondente. A Trilha
## referencia um Território por identificador (territory_id) — nunca
## grava a Facção diretamente — para que propriedades futuras que a
## própria SSOT já atribui ao Território (clima, bioma, música,
## background, Minas, bônus, drops exclusivos) tenham onde morar sem
## exigir mudança de estrutura na Trilha quando forem implementadas.
##
## Escopo desta Sprint: apenas identidade e Facção.

var id: String
var faction: String


func _init(p_id: String, p_faction: String) -> void:
	id = p_id
	faction = p_faction
