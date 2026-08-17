class_name SeasonBenchmark
extends RefCounted
## SeasonBenchmark
##
## Conjunto de referência fixo da Temporada (PvE.md, "Banco de
## Exércitos Inimigos"): garante que todo Exército gerado seja avaliado
## exatamente sob as mesmas condições, independente de quando foi
## gerado ou de qual Trilha/Categoria pertence. Gerado uma única vez
## por Temporada, com mistura das 3 Facções.
##
## NOTA: este é o Benchmark GENÉRICO (usado por SeasonPipeline.run(),
## a geração da Temporada completa) — sempre Patente "Recruta", sem a
## Restrição de Patente/Tier/Soldo por Região nem a heurística de
## posicionamento (PvE.md item 3). O Benchmark REGIONAL específico
## (20 por Região, com essas regras e a divisão Máquina de Guerra/sem)
## está em RegionalBenchmark.gd, usado pelo experimento de
## posicionamento e pela geração real por Região.


static func build(config: SeasonConfig, all_cards: Array[CardResource]) -> Array[Army]:
	seed(config.seed_value)

	var factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
	var benchmark: Array[Army] = []

	for i in range(config.benchmark_size):
		var territory: String = factions[i % factions.size()]

		var army := Army.new()
		var commander := CommanderResource.new()
		commander.commander_name = "Benchmark %d" % i
		commander.faction = territory
		army.commander = commander
		army.cards = EnemyArmyGenerator.build_composition(territory, all_cards, 1, Soldo.cap_for_patente("Recruta"))

		benchmark.append(army)

	return benchmark
