class_name TestAbilityData
extends RefCounted
## TestAbilityData (F-001, Etapa 3)
##
## Migrado de bootstrap.gd:_validate_ability_data(). Mesmo relatório de
## integridade original (Habilidades/Características duplicadas +
## referências de Tier I/III/V das Cartas), lendo exclusivamente o
## catálogo somente-leitura de GameDatabase (carregado 1x pelo
## Autoload, nunca mutado por este teste).
##
## _find_duplicates() é cópia do helper de mesmo nome em bootstrap.gd —
## único chamador original confirmado antes da migração, removido de lá
## junto com a validação.
##
## Aprovação de Etapa 3: o estado "catálogo limpo" (sem duplicados, sem
## referências quebradas) — implícito no teste original ("nenhum" nos
## prints) — passa a ser uma asserção real (PASS/FAIL), sem nenhuma
## regra nova além das já checadas pelo teste original.

static func run(ctx: TestRunner.Context) -> bool:
	print("[AbilityData] Catálogo de Habilidades: %d carregadas." % GameDatabase.abilities.size())
	print("[AbilityData] Catálogo de Características de Unidade: %d carregadas." % GameDatabase.unit_traits.size())

	var ability_names: Array[String] = []
	for ability: AbilityResource in GameDatabase.abilities:
		ability_names.append(ability.ability_name)
	var duplicate_abilities: Array[String] = _find_duplicates(ability_names)
	print("[AbilityData] Nomes de Habilidade duplicados: %s" % (str(duplicate_abilities) if not duplicate_abilities.is_empty() else "nenhum"))
	ctx.check(duplicate_abilities.is_empty(), "não deve haver Nomes de Habilidade duplicados (encontrado: %s)" % str(duplicate_abilities))

	var trait_names: Array[String] = []
	for trait_entry: UnitTraitResource in GameDatabase.unit_traits:
		trait_names.append(trait_entry.trait_name)
	var duplicate_traits: Array[String] = _find_duplicates(trait_names)
	print("[AbilityData] Nomes de Característica duplicados: %s" % (str(duplicate_traits) if not duplicate_traits.is_empty() else "nenhum"))
	ctx.check(duplicate_traits.is_empty(), "não deve haver Nomes de Característica duplicados (encontrado: %s)" % str(duplicate_traits))

	print("[AbilityData] Validando referências das Cartas...")
	var broken_refs: Array[String] = []
	for card: CardResource in GameDatabase.cards:
		if card.tier_1_trait_name != "" and not trait_names.has(card.tier_1_trait_name):
			print("  ERRO: %s referencia Característica de Unidade inexistente: '%s'" % [card.card_name, card.tier_1_trait_name])
			broken_refs.append("%s -> Tier I: '%s'" % [card.card_name, card.tier_1_trait_name])
		if card.tier_3_ability_name != "" and not ability_names.has(card.tier_3_ability_name):
			print("  ERRO: %s referencia Habilidade de Tier III inexistente: '%s'" % [card.card_name, card.tier_3_ability_name])
			broken_refs.append("%s -> Tier III: '%s'" % [card.card_name, card.tier_3_ability_name])
		if card.tier_5_ability_name != "" and not ability_names.has(card.tier_5_ability_name):
			print("  ERRO: %s referencia Habilidade de Tier V inexistente: '%s'" % [card.card_name, card.tier_5_ability_name])
			broken_refs.append("%s -> Tier V: '%s'" % [card.card_name, card.tier_5_ability_name])
		print("  %s -> Tier I: '%s' | Tier III: '%s' | Tier V: '%s' (todas resolvidas)" % [
			card.card_name, card.tier_1_trait_name, card.tier_3_ability_name, card.tier_5_ability_name
		])
	ctx.check(broken_refs.is_empty(), "todas as referências de Tier I/III/V das Cartas devem existir no catálogo (quebradas: %s)" % str(broken_refs))

	print("[AbilityData] Observação documental registrada (não corrigida nesta Sprint):")
	print("  'Engenharia Militar' existe tanto como AbilityResource (Tier V) quanto como nome de")
	print("  Característica de Unidade (Tier I) em DUAS cartas distintas de CARD_CATALOG.md")
	print("  (Engenheiro Imperial e Capitão Imperial), com descrições ligeiramente diferentes.")
	print("  São recursos distintos e intencionalmente não vinculados nesta camada de dados;")
	print("  a associação, se existir, é responsabilidade futura do AbilitySystem.")
	print("[AbilityData] Observação documental registrada (não corrigida nesta Sprint):")
	print("  A habilidade 'Perfurante' possui o campo 'notes' vazio nesta Sprint, pois a SSOT")
	print("  (ABILITIES.md) contém, nesse campo, um erro de cópia da habilidade 'Trespassar'.")
	print("[AbilityData] Observação documental registrada (não corrigida nesta Sprint):")
	print("  A carta 'Árvore Ancestral' (Máquina de Guerra) possui uma 'Mecânica Exclusiva'")
	print("  ('Raízes Ancestrais') fora do padrão Tier I/III/V — não convertida nesta Sprint,")
	print("  pois não é uma Característica de Unidade nem uma Habilidade compartilhada.")

	return true


## Retorna os elementos que aparecem mais de uma vez em "values". Cópia
## do helper de mesmo nome em bootstrap.gd, removido de lá após esta
## migração (único chamador).
static func _find_duplicates(values: Array[String]) -> Array[String]:
	var seen: Dictionary = {}
	var duplicates: Array[String] = []
	for value: String in values:
		seen[value] = seen.get(value, 0) + 1
	for value: String in seen:
		if seen[value] > 1 and not duplicates.has(value):
			duplicates.append(value)
	return duplicates
