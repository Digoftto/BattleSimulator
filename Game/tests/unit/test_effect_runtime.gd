class_name TestEffectRuntime
extends RefCounted
## TestEffectRuntime (F-001, Etapa 8)
##
## Migrado de bootstrap.gd:_validate_effect_runtime() (Sprint 20). Mesmo
## cenário original — confirma que o EffectRuntime resolve corretamente
## as referências de uma carta real do catálogo (Tier I, III e V
## preenchidos) e que uma carta sem nenhuma referência não gera nenhuma
## instância — apenas leitura/validação estrutural, nenhuma Habilidade/
## Característica é executada, e nenhum listener é registrado no
## CombatEventBus.
##
## IMPORTANTE: esta validação NÃO executa uma batalha — CombatEngine.run()
## nunca é chamado aqui, só CombatEngine.initialize(). Preservado
## exatamente assim: nenhuma execução de Habilidade/Característica foi
## introduzida que não existia no original.
##
## _build_combat_card() e _build_transient_cards() são cópias dos helpers
## de mesmo nome em bootstrap.gd. _build_combat_card() é compartilhado
## com validações ainda não migradas (_validate_combat_engine,
## _validate_mining_incremental_estimation), portanto NÃO removido de lá.
## _build_transient_cards() era exclusivo desta validação (único chamador
## confirmado por busca repo-wide antes da migração) — removido de
## bootstrap.gd junto com ela.
##
## O teste original não tinha "(esperado: X)" explícito — é inteiramente
## narrativo/estrutural (leitura humana). Nenhuma asserção nova foi
## adicionada.

static func run(ctx: TestRunner.Context) -> bool:
	print("[EffectRuntime] Validando resolução de Runtime (EffectRuntime/AbilityRuntime/UnitTraitRuntime)...")

	var real_card: CardResource = null
	for c: CardResource in GameDatabase.cards:
		if c.card_name == "Legionário Imperial":
			real_card = c
			break

	if real_card == null:
		push_warning("[Bootstrap] Carta real para validação do EffectRuntime não foi encontrada no GameDatabase.")
		return true

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Validação (EffectRuntime)"
	commander.faction = "Império"

	var army_a := Army.new()
	army_a.commander = commander
	army_a.cards = []
	for i in range(9):
		army_a.cards.append(real_card)

	var army_b := Army.new()
	army_b.commander = commander
	army_b.cards = _build_transient_cards("Comum", 1, 9)  # sem Tier I/III/V preenchidos

	var state: CombatState = CombatEngine.initialize(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	print("  EffectRuntime criado: %s" % ("sim" if state.effect_runtime != null else "não"))

	var sample_unit: CombatUnit = state.units_of_side(0)[0]
	var trait_instance: UnitTraitInstance = state.effect_runtime.get_unit_trait(sample_unit)
	var ability_instances: Array[AbilityInstance] = state.effect_runtime.get_abilities(sample_unit)

	var ability_names: Array[String] = []
	for instance: AbilityInstance in ability_instances:
		ability_names.append(instance.resource.ability_name)

	print("  %s (carta real, Tier I/III/V preenchidos):" % sample_unit.card.card_name)
	print("    Característica de Unidade resolvida: %s" % (trait_instance.resource.trait_name if trait_instance != null else "nenhuma"))
	print("    Habilidades resolvidas: %d (%s)" % [ability_instances.size(), ", ".join(ability_names)])

	var empty_unit: CombatUnit = state.units_of_side(1)[0]
	var empty_trait: UnitTraitInstance = state.effect_runtime.get_unit_trait(empty_unit)
	var empty_abilities: Array[AbilityInstance] = state.effect_runtime.get_abilities(empty_unit)

	print("  Carta transitória sem referências preenchidas:")
	print("    Característica de Unidade resolvida: %s" % ("nenhuma" if empty_trait == null else empty_trait.resource.trait_name))
	print("    Habilidades resolvidas: %d" % empty_abilities.size())

	print("  Listeners registrados no CombatEventBus nesta Sprint: 0 (ponto de extensão preparado para Sprint 21+).")

	state.effect_runtime.shutdown()
	print("[EffectRuntime] shutdown() executado com sucesso.")

	return true


## Cópia do helper de mesmo nome em bootstrap.gd — compartilhado com
## validações ainda não migradas, portanto NÃO removido de lá.
static func _build_combat_card(card_name_value: String, card_class: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.card_class = card_class
	card.faction = "Império"
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card


## Cria "count" cartas transitórias com Raridade/Tier definidos, mas sem
## nenhuma referência de Tier I/III/V preenchida. Cópia do helper de mesmo
## nome em bootstrap.gd — único chamador original confirmado antes da
## migração, removido de lá junto com esta validação.
static func _build_transient_cards(rarity: String, tier: int, count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.rarity = rarity
		card.tier = tier
		cards.append(card)
	return cards
