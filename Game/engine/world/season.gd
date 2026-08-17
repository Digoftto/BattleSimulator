class_name Season
extends RefCounted
## Season
##
## Unidade fechada de conteúdo do mundo para uma Temporada (WorldDatabase).
## Agrupa Territórios, Trilhas e o Catálogo de Exércitos Inimigos —
## exatamente os dados que uma nova Temporada precisa trocar como um
## todo, sem que Kingdom ou o domínio de Combate precisem saber que
## algo mudou.
##
## "reward_tables" é apenas a estrutura reservada (Dictionary vazio) —
## nenhuma implementação de Recompensa nesta Sprint (isso é a Sprint
## seguinte, RewardResolver).

var season_id: String

## territory_id -> Territory
var territories: Dictionary = {}

## territory_id -> Trilha (relação 1:1 por Território, hoje)
var trilhas: Dictionary = {}

## Catálogo de Exércitos Inimigos desta Temporada (Sprint 31), produzido
## offline por SeasonPipeline — nunca gerado durante uma partida.
var enemy_catalog: SeasonCatalog

## Estrutura reservada para Tabelas de Recompensa por Temporada. Vazio
## nesta Sprint — apenas o lugar onde elas vão morar quando existirem.
var reward_tables: Dictionary = {}


func _init(p_season_id: String) -> void:
	season_id = p_season_id


func add_territory(territory: Territory, trilha: Trilha) -> void:
	territories[territory.id] = territory
	trilhas[territory.id] = trilha


func get_territory(territory_id: String) -> Territory:
	return territories.get(territory_id, null)


func get_trilha(territory_id: String) -> Trilha:
	return trilhas.get(territory_id, null)


## Retorna o Território cuja Facção corresponde à informada, ou null.
## Conveniência para quando quem chama sabe a Facção mas não o
## identificador exato do Território.
func get_territory_by_faction(faction: String) -> Territory:
	for territory: Territory in territories.values():
		if territory.faction == faction:
			return territory
	return null
