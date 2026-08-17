class_name WorldBootstrap
extends RefCounted
## WorldBootstrap
##
## Ponto único que carrega um Mundo de verdade em WorldDatabase quando
## o jogo abre — sem isso, WorldDatabase começa vazio de propósito
## (autoload/world_database.gd) e a janela de PvE não tem nada pra
## mostrar. Idempotente: chamar de novo não recria o Mundo se ele já
## existe.
##
## PRIORIDADE: primeiro tenta CARREGAR um Catálogo já gerado pela
## ferramenta externa (tools/pve_generator/, tools/regional_generator/
## — grava em res://reports/ via SimulationReportService). Só se
## nenhum arquivo existir, cai para uma geração AO VIVO em escala de
## desenvolvimento (pequena o bastante pra rodar em segundos).
##
## ESCOPO ATUAL DA GERAÇÃO AO VIVO: as 3 Regiões (Fases 1-9000), usando
## EnemyArmyGenerator.generate() de verdade — o mesmo motor com a
## Restrição de Patente/Tier/Soldo por Região, já testado — pra dar um
## ciclo de jogo completo e testável (Cidade -> PvE -> Combate real) em
## qualquer ponto da Trilha, enquanto os arquivos reais das simulações
## em escala (30 mil candidatos/Região) ainda não chegaram. Quando
## chegarem, este método para de ser usado — a PRIORIDADE acima passa
## a carregar o Catálogo real.

const DEV_SEASON_ID: String = "Dev-Season-Local"
const DEV_SCALE_COUNT_PER_CATEGORY: int = 30
const DEV_SCALE_REGIONS: Array[int] = [1, 2, 3]

## Exceção das Primeiras Fases (PvE.md): quantidade de entradas
## "Iniciantes" (Comuns, Tier I) geradas pra Fases 1-10 de cada
## Trilha — pool separado do restante da Região I.
const BEGINNER_ENTRY_COUNT: int = 15


## Garante que existe um Mundo carregado em WorldDatabase. Chamado no
## boot do jogo (CityPanel/PvEPanel), mas seguro de chamar de qualquer
## lugar, quantas vezes for.
static func ensure_world_loaded() -> void:
	if WorldDatabase.get_current_season() != null:
		return

	var loaded_season: Season = SimulationReportService.load_season()
	if loaded_season != null:
		WorldDatabase.register_season(loaded_season)
		WorldDatabase.set_current_season(loaded_season.season_id)
		BattleLogger.info("WorldBootstrap", "Mundo carregado do arquivo gerado pela ferramenta externa: Temporada '%s'." % loaded_season.season_id)
		return

	_generate_dev_scale_world()


static func _generate_dev_scale_world() -> void:
	var config := SeasonConfig.new()
	config.season_id = DEV_SEASON_ID
	config.seed_value = 1

	var catalog := SeasonCatalog.new(DEV_SEASON_ID)
	var season := Season.new(DEV_SEASON_ID)
	season.enemy_catalog = catalog

	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var territory := Territory.new("Território de %s" % faction, faction)
		var trilha := Trilha.new(territory.id)
		season.add_territory(territory, trilha)

		for category in EnemyArmyEntry.Category.values():
			# add_entries() SOBRESCREVE (não soma) — precisa juntar as 3
			# Regiões num array só antes de registrar, senão a última
			# Região chamada apagaria as anteriores.
			var entries: Array[EnemyArmyEntry] = []
			for region: int in DEV_SCALE_REGIONS:
				for i in range(DEV_SCALE_COUNT_PER_CATEGORY):
					entries.append(EnemyArmyGenerator.generate(
						category, faction, region, GameDatabase.cards, config,
						GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
						GameDatabase.commander_effects, GameDatabase.commander_values,
						"%s_dev_%s_r%d" % [faction, EnemyArmyEntry.Category.keys()[category], region], i
					))

			# Exceção das Primeiras Fases (PvE.md): só pra Fases Normais
			# da Região I — lote separado, Comum/Tier I forçado.
			if category == EnemyArmyEntry.Category.NORMAL:
				for i in range(BEGINNER_ENTRY_COUNT):
					entries.append(EnemyArmyGenerator.generate(
						category, faction, 1, GameDatabase.cards, config,
						GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
						GameDatabase.commander_effects, GameDatabase.commander_values,
						"%s_dev_beginner" % faction, i, true
					))

			catalog.add_entries(faction, category, entries)

	WorldDatabase.register_season(season)
	WorldDatabase.set_current_season(DEV_SEASON_ID)

	BattleLogger.info("WorldBootstrap", "Nenhum Catálogo gerado encontrado — Mundo de desenvolvimento gerado ao vivo, 3 Regiões: 3 Territórios, %d candidatos por categoria/Região + %d Iniciantes (Fases 1-10), Temporada '%s'." % [
		DEV_SCALE_COUNT_PER_CATEGORY, BEGINNER_ENTRY_COUNT, DEV_SEASON_ID
	])
