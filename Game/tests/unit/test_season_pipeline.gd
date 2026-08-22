class_name TestSeasonPipeline
extends RefCounted
## TestSeasonPipeline (F-001, Etapa 16)
##
## Migrado de bootstrap.gd:_validate_season_pipeline(). Mesmo cenário
## original — o Pipeline de ponta a ponta em escala reduzida de
## desenvolvimento, e EnemyArmySelector (seleção por Região/Categoria,
## determinismo por seed, e a substituição por Comandante Regional
## Recrutado). Usa SeasonPipeline.run() e EnemyArmySelector.select()
## diretamente (confirmado na auditoria da Etapa 16: season_pipeline.gd
## não tem nenhuma referência a KingdomState/WorldDatabase/
## WorldBootstrap/ExpeditionRuntime/GameRuntime/WorkerThreadPool, direta
## ou transitiva).
##
## EnemyArmyGenerator.generate() (usado internamente por
## SeasonPipeline.run()) usa RNG real não seedada — mas nenhuma
## asserção aqui depende do conteúdo aleatório gerado: a checagem de
## Ordenação por WR é estrutural (sempre crescente, qualquer que seja o
## conteúdo), e a checagem de Determinismo usa EnemyArmySelector.select()
## com seed explícita (999), preservada exatamente como no original. A
## seed 999 do teste de determinismo e a seed 42 de SeasonConfig não
## foram alteradas. Nenhum mock determinístico foi introduzido no lugar
## da RNG real do gerador, nenhuma asserção estatística nova foi
## adicionada sobre a distribuição de Facção gerada, e nenhum código de
## produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra. A comparação "Diversidade" (seeds 999 vs 111) nunca
## teve um "(esperado: X)" real no original ("podem ou não diferir") —
## permanece só narração, sem asserção inventada.

static func run(ctx: TestRunner.Context) -> bool:
	print("[SeasonPipeline] Validando o Pipeline de ponta a ponta (escala reduzida de desenvolvimento — números oficiais ficam em SeasonConfig como padrão)...")

	var config := SeasonConfig.new()
	config.season_id = "Season01-Dev"
	config.seed_value = 42
	config.normal_army_count = 3
	config.chefe_normal_count = 2
	config.chefe_regional_mina_generated_count = 4
	config.chefe_regional_mina_kept_count = 3
	config.simulations_per_army = 3
	config.benchmark_size = 2
	config.min_rarity_score_exclusive = 10  # reduzido só para o teste; oficial fica em SeasonConfig

	var catalog: SeasonCatalog = SeasonPipeline.run(
		config, GameDatabase.cards,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	print("  Pipeline concluído para a Temporada '%s'." % catalog.season_id)

	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var normal: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.NORMAL)
		var chefe_normal: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_NORMAL)
		var regional: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_REGIONAL)
		var mina: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_DE_MINA)
		print("  %s -> Normal: %d | Chefe Normal: %d | Chefe Regional: %d | Chefe de Mina: %d" % [
			faction, normal.size(), chefe_normal.size(), regional.size(), mina.size()
		])

	# Ordenação crescente de WR.
	var sample: Array[EnemyArmyEntry] = catalog.get_entries("Império", EnemyArmyEntry.Category.NORMAL)
	var sorted_correctly: bool = true
	for i in range(1, sample.size()):
		if sample[i].win_rate < sample[i - 1].win_rate:
			sorted_correctly = false
	print("  Ordenação por WR crescente (Império/Normal): %s (esperado: true)" % str(sorted_correctly))
	ctx.check(sorted_correctly == true, "Entradas Normal/Império devem estar ordenadas por WR crescente")

	# Determinismo: mesma Trilha + mesma Seed + mesma Fase -> mesmo Exército.
	var registry := RegionalCommanderRegistry.new()
	var pick_a: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 999, registry)
	var pick_b: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 999, registry)
	print("  Determinismo (mesma seed) -> mesmo Exército? %s (esperado: true) | id=%s" % [
		str(pick_a != null and pick_b != null and pick_a.id == pick_b.id),
		(pick_a.id if pick_a != null else "null")
	])
	ctx.check(pick_a != null and pick_b != null and pick_a.id == pick_b.id, "Mesma seed deve selecionar o mesmo Exército")

	# Diversidade: seeds diferentes podem produzir Exércitos diferentes.
	var pick_c: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 111, registry)
	print("  Seeds diferentes (999 vs 111) -> ids: %s vs %s (podem ou não diferir)" % [
		(pick_a.id if pick_a != null else "null"), (pick_c.id if pick_c != null else "null")
	])

	# Comandante Regional Recrutado -> substitui por Chefe Normal da mesma Região.
	var before_recruit: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 5, registry)
	print("  Antes do recrutamento -> categoria selecionada: Chefe Regional (id=%s)" % (before_recruit.id if before_recruit != null else "null"))

	registry.recruit("Império", 1)
	var after_recruit: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 5, registry)
	var after_is_chefe_normal: bool = after_recruit != null and after_recruit.category == EnemyArmyEntry.Category.CHEFE_NORMAL
	print("  Após recrutar o Comandante Regional -> Exército selecionado passa a ser Chefe Normal? %s (esperado: true)" % str(after_is_chefe_normal))
	ctx.check(after_is_chefe_normal == true, "Após recrutar o Comandante Regional, a seleção deve passar a ser Chefe Normal")

	# Ausência de seleção inválida: categoria sem nenhuma entrada correspondente retorna null, nunca inventa.
	var empty_catalog := SeasonCatalog.new("Vazio")
	var invalid_pick: EnemyArmyEntry = EnemyArmySelector.select(empty_catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 1, 1, null)
	print("  Catálogo vazio -> seleção retorna null (nunca inventa)? %s (esperado: true)" % str(invalid_pick == null))
	ctx.check(invalid_pick == null, "Catálogo vazio deve fazer a seleção retornar null, nunca inventar")

	return true
