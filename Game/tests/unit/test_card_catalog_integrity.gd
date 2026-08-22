class_name TestCardCatalogIntegrity
extends RefCounted
## TestCardCatalogIntegrity (F-001, Etapa 3)
##
## Migrado de bootstrap.gd:_validate_card_catalog_integrity() (Sprint
## 23). Mesmo relatório de integridade original (nomes duplicados,
## campos obrigatórios ausentes, Classe/Facção inexistente, referências
## de Habilidade/Característica quebradas), lendo exclusivamente o
## catálogo somente-leitura de GameDatabase. Nenhum helper próprio —
## totalmente autocontido, igual ao original.
##
## Aprovação de Etapa 3: o estado "catálogo limpo" — implícito no teste
## original ("nenhum"/"nenhuma" nos prints) — passa a ser uma asserção
## real (PASS/FAIL) para cada uma das condições já checadas pelo teste
## original (duplicados, campos ausentes, Classe/Facção inválida,
## referências de Habilidade/Característica quebradas). "Tipos em uso"
## permanece apenas informativo — o teste original nunca definiu uma
## lista fechada de Tipos válidos, então nenhuma regra nova foi inventada
## para essa parte.

static func run(ctx: TestRunner.Context) -> bool:
	print("[CardCatalog] Relatório de integridade (%d cartas)..." % GameDatabase.cards.size())

	var valid_classes: Array[String] = ["Corpo a Corpo", "Barreira", "À Distância", "Mago", "Suporte", "Máquina de Guerra"]
	var valid_factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

	var trait_names: Array[String] = []
	for trait_entry: UnitTraitResource in GameDatabase.unit_traits:
		trait_names.append(trait_entry.trait_name)

	var seen_card_names: Dictionary = {}
	var duplicate_names: Array[String] = []
	var missing_fields: Array[String] = []
	var invalid_class_refs: Array[String] = []
	var invalid_faction_refs: Array[String] = []
	var broken_ability_refs: Array[String] = []
	var broken_trait_refs: Array[String] = []
	var types_found: Dictionary = {}

	for card: CardResource in GameDatabase.cards:
		if seen_card_names.has(card.card_name):
			duplicate_names.append(card.card_name)
		seen_card_names[card.card_name] = true

		if card.card_name == "" or card.faction == "" or card.card_class == "" or card.rarity == "":
			missing_fields.append(card.card_name if card.card_name != "" else "<carta sem nome>")

		if not valid_classes.has(card.card_class):
			invalid_class_refs.append("%s -> '%s'" % [card.card_name, card.card_class])

		if not valid_factions.has(card.faction):
			invalid_faction_refs.append("%s -> '%s'" % [card.card_name, card.faction])

		if card.card_type != "":
			types_found[card.card_type] = types_found.get(card.card_type, 0) + 1

		if card.tier_1_trait_name != "" and not trait_names.has(card.tier_1_trait_name):
			broken_trait_refs.append("%s -> Tier I: '%s'" % [card.card_name, card.tier_1_trait_name])

		if card.tier_3_ability_name != "":
			var ability_3: AbilityResource = GameDatabase.abilities_by_name.get(card.tier_3_ability_name)
			if ability_3 == null:
				broken_ability_refs.append("%s -> Tier III: '%s' (não existe no catálogo)" % [card.card_name, card.tier_3_ability_name])
			elif ability_3.tier != 3:
				broken_ability_refs.append("%s -> Tier III: '%s' (existe, porém catalogada como Tier %d)" % [card.card_name, card.tier_3_ability_name, ability_3.tier])

		if card.tier_5_ability_name != "":
			var ability_5: AbilityResource = GameDatabase.abilities_by_name.get(card.tier_5_ability_name)
			if ability_5 == null:
				broken_ability_refs.append("%s -> Tier V: '%s' (não existe no catálogo)" % [card.card_name, card.tier_5_ability_name])
			elif ability_5.tier != 5:
				broken_ability_refs.append("%s -> Tier V: '%s' (existe, porém catalogada como Tier %d)" % [card.card_name, card.tier_5_ability_name, ability_5.tier])

	print("  Nomes de carta duplicados: %s" % (str(duplicate_names) if not duplicate_names.is_empty() else "nenhum"))
	ctx.check(duplicate_names.is_empty(), "não deve haver Nomes de carta duplicados (encontrado: %s)" % str(duplicate_names))

	print("  Campos obrigatórios ausentes: %s" % (str(missing_fields) if not missing_fields.is_empty() else "nenhum"))
	ctx.check(missing_fields.is_empty(), "não deve haver Campos obrigatórios ausentes (encontrado: %s)" % str(missing_fields))

	print("  Classe inexistente: %s" % (str(invalid_class_refs) if not invalid_class_refs.is_empty() else "nenhuma"))
	ctx.check(invalid_class_refs.is_empty(), "não deve haver Classe inexistente (encontrado: %s)" % str(invalid_class_refs))

	print("  Facção inexistente: %s" % (str(invalid_faction_refs) if not invalid_faction_refs.is_empty() else "nenhuma"))
	ctx.check(invalid_faction_refs.is_empty(), "não deve haver Facção inexistente (encontrado: %s)" % str(invalid_faction_refs))

	print("  Tipos em uso (informativo — não há lista fechada definida na documentação): %s" % str(types_found))

	print("  Referências de Habilidade (Tier III/V) quebradas: %d" % broken_ability_refs.size())
	for entry: String in broken_ability_refs:
		print("    - " + entry)
	ctx.check(broken_ability_refs.is_empty(), "não deve haver Referências de Habilidade (Tier III/V) quebradas (encontrado: %s)" % str(broken_ability_refs))

	print("  Referências de Característica (Tier I) quebradas: %d" % broken_trait_refs.size())
	for entry: String in broken_trait_refs:
		print("    - " + entry)
	ctx.check(broken_trait_refs.is_empty(), "não deve haver Referências de Característica (Tier I) quebradas (encontrado: %s)" % str(broken_trait_refs))

	print("  Nenhuma inconsistência documental foi corrigida automaticamente (política oficial do projeto).")

	return true
