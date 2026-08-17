extends Node
## WorldDatabase
##
## Registro do conteúdo permanente do MUNDO (Temporadas, Territórios,
## Trilhas, Catálogo de Exércitos Inimigos) — deliberadamente separado
## de GameDatabase, que continua responsável por regras e recursos de
## gameplay reutilizáveis (Cartas, Habilidades, Características, Bancos
## de Geração de Comandante).
##
## GameDatabase responde "quais peças o jogo tem para jogar".
## WorldDatabase responde "qual é o mundo desta Temporada".
##
## Diferente de GameDatabase, este autoload NÃO carrega nada
## automaticamente em _ready() — Território/Trilha/Season ainda não são
## Resources persistidos em disco (são objetos de domínio com
## comportamento, não dado puro), e o Catálogo de uma Temporada nunca
## deve ser gerado durante uma partida (PvE.md, Sprint 31: o Pipeline é
## uma ferramenta offline). Uma Temporada é registrada explicitamente —
## por uma ferramenta de build/carregamento futura, ou, nesta Sprint,
## por quem estiver validando o sistema (ver bootstrap.gd).
##
## Trocar de Temporada, no futuro, deve significar apenas registrar uma
## nova Season aqui — Kingdom e o domínio de Combate não precisam saber
## que algo mudou.

var seasons: Dictionary = {}  # season_id -> Season
var current_season_id: String = ""


func register_season(season: Season) -> void:
	seasons[season.season_id] = season


func get_season(season_id: String) -> Season:
	return seasons.get(season_id, null)


## Marca qual Temporada está ativa no momento. Não implica nenhuma
## regra de transição entre Temporadas — apenas qual delas as consultas
## sem season_id explícito devem usar.
func set_current_season(season_id: String) -> void:
	assert(seasons.has(season_id), "WorldDatabase: Temporada '%s' não registrada." % season_id)
	current_season_id = season_id


func get_current_season() -> Season:
	return get_season(current_season_id)
