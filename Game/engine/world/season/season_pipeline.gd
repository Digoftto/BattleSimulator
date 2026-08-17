class_name SeasonPipeline
extends RefCounted
## SeasonPipeline
##
## Orquestra o Pipeline de Geração da Temporada, 100% offline (PvE.md):
## geração procedural -> cálculo de WR (contra benchmark fixo) ->
## ordenação -> distribuição em faixas -> Catálogo Oficial. O jogo em
## execução nunca invoca este Pipeline durante uma partida — apenas
## consulta o SeasonCatalog já pronto (ver EnemyArmySelector).
##
## A Temporada é o dado de entrada (SeasonConfig), não um resultado
## fixo: rodar este mesmo Pipeline com uma configuração diferente
## produz a Temporada seguinte, sem alterar esta classe.

const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]
const REGION_COUNT: int = 3


static func run(
	config: SeasonConfig,
	all_cards: Array[CardResource],
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource]
) -> SeasonCatalog:
	seed(config.seed_value)

	var benchmark: Array[Army] = SeasonBenchmark.build(config, all_cards)
	var catalog := SeasonCatalog.new(config.season_id)

	for territory: String in FACTIONS:
		var others: Array[String] = FACTIONS.filter(func(f: String) -> bool: return f != territory)

		# --- Fases Normais ---
		var normal_entries: Array[EnemyArmyEntry] = _generate_and_score(
			EnemyArmyEntry.Category.NORMAL, territory, config.normal_army_count,
			all_cards, config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			battlefields, abilities_by_name, unit_traits, benchmark, "%s_normal" % territory
		)
		_sort_by_win_rate(normal_entries)
		_assign_regions_evenly(normal_entries, REGION_COUNT)
		catalog.add_entries(territory, EnemyArmyEntry.Category.NORMAL, normal_entries)

		# --- Chefes Normais ---
		var chefe_normal_entries: Array[EnemyArmyEntry] = _generate_and_score(
			EnemyArmyEntry.Category.CHEFE_NORMAL, territory, config.chefe_normal_count,
			all_cards, config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			battlefields, abilities_by_name, unit_traits, benchmark, "%s_chefe_normal" % territory
		)
		_sort_by_win_rate(chefe_normal_entries)
		_assign_regions_evenly(chefe_normal_entries, REGION_COUNT)
		catalog.add_entries(territory, EnemyArmyEntry.Category.CHEFE_NORMAL, chefe_normal_entries)

		# --- Chefes Regionais / Chefes de Mina ---
		# Gera "chefe_regional_mina_generated_count", mantém apenas os
		# "chefe_regional_mina_kept_count" melhores por WR, e divide
		# igualmente entre as 3 Regiões. Chefe de Mina reutiliza
		# exatamente o mesmo catálogo (PvE.md) — só muda a categoria do
		# encontro.
		var regional_mina_entries: Array[EnemyArmyEntry] = _generate_and_score(
			EnemyArmyEntry.Category.CHEFE_REGIONAL, territory, config.chefe_regional_mina_generated_count,
			all_cards, config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			battlefields, abilities_by_name, unit_traits, benchmark, "%s_regional_mina" % territory
		)
		_sort_by_win_rate(regional_mina_entries)

		var kept: int = mini(config.chefe_regional_mina_kept_count, regional_mina_entries.size())
		var best_entries: Array[EnemyArmyEntry] = regional_mina_entries.slice(
			regional_mina_entries.size() - kept, regional_mina_entries.size()
		)
		_assign_regions_evenly(best_entries, REGION_COUNT)

		catalog.add_entries(territory, EnemyArmyEntry.Category.CHEFE_REGIONAL, best_entries)
		catalog.add_entries(territory, EnemyArmyEntry.Category.CHEFE_DE_MINA, best_entries)

	return catalog


static func _generate_and_score(
	category: EnemyArmyEntry.Category,
	territory: String,
	count: int,
	all_cards: Array[CardResource],
	config: SeasonConfig,
	commander_restrictions: Array[CommanderRestrictionResource],
	commander_requirements: Array[CommanderRequirementResource],
	commander_targets: Array[CommanderTargetResource],
	commander_effects: Array[CommanderEffectResource],
	commander_values: Array[CommanderValueResource],
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	benchmark: Array[Army],
	id_prefix: String
) -> Array[EnemyArmyEntry]:
	var entries: Array[EnemyArmyEntry] = []

	for i in range(count):
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			category, territory, 1, all_cards, config,
			commander_restrictions, commander_requirements, commander_targets, commander_effects, commander_values,
			id_prefix, i
		)
		entry.win_rate = WinRateSimulator.calculate(
			entry, benchmark, config.simulations_per_army, battlefields, abilities_by_name, unit_traits
		)
		entries.append(entry)

	return entries


static func _sort_by_win_rate(entries: Array[EnemyArmyEntry]) -> void:
	entries.sort_custom(func(a: EnemyArmyEntry, b: EnemyArmyEntry) -> bool: return a.win_rate < b.win_rate)


## Divide "entries" (já ordenados por WR) em "region_count" faixas
## contíguas, atribuindo region_min == region_max == número da faixa.
static func _assign_regions_evenly(entries: Array[EnemyArmyEntry], region_count: int) -> void:
	if entries.is_empty():
		return
	var band_size: int = maxi(1, int(entries.size() / float(region_count)))
	for i in range(entries.size()):
		@warning_ignore("integer_division")  # Divisão inteira intencional: região é sempre um índice inteiro.
		var region: int = mini((i / band_size) + 1, region_count)
		entries[i].region_min = region
		entries[i].region_max = region
