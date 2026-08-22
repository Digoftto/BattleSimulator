class_name TestCampaignSynergy
extends RefCounted
## TestCampaignSynergy (F-001, Etapa 14)
##
## Migrado de bootstrap.gd:_validate_campaign_synergy(). Mesmo cenário
## original — confirma que CampaignSynergyCalculator identifica
## corretamente Sinergias de Campanha em diferentes cenários de
## composição de Exército. Classe pura — nenhuma batalha é executada.
## Usa CampaignTestFixtures (já um class_name independente e puro —
## reutilizado diretamente, sem cópia) e leitura somente-leitura de
## GameDatabase.
##
## O teste original só tinha "(esperado: X)" explícito no 1º cenário
## (Exército vazio) — os demais cenários (sem Sinergia, uma Sinergia,
## múltiplas Sinergias, cartas repetidas) são inteiramente narrativos no
## original, sem marcador de expectativa explícito. Nenhuma asserção
## nova foi inventada para eles — preservados exatamente como prints
## informativos.

static func run(ctx: TestRunner.Context) -> bool:
	print("[CampaignSynergyCalculator] Validando cenários de Sinergia de Campanha...")

	# Exército vazio.
	var empty_result: Dictionary = CampaignSynergyCalculator.calculate([])
	print("  Exército vazio -> %s (esperado: {})" % str(empty_result))
	ctx.check(empty_result == {}, "Exército vazio deve resultar em nenhuma Sinergia (obtido: %s)" % str(empty_result))

	# Nenhuma Sinergia: 3 cartas, cada uma com uma Habilidade de Campanha diferente.
	var no_synergy_cards: Array[CardResource] = [
		CampaignTestFixtures.build_synergy_test_card("Treinamento Ofensivo"),
		CampaignTestFixtures.build_synergy_test_card("Treinamento Defensivo"),
		CampaignTestFixtures.build_synergy_test_card("Suprimentos de Campanha"),
	]
	print("  Sem Sinergia -> %s" % str(CampaignSynergyCalculator.calculate(no_synergy_cards)))

	# Uma Sinergia: 2 cartas compartilham "Extração de Ferro"; 1 carta é única.
	var one_synergy_cards: Array[CardResource] = [
		CampaignTestFixtures.build_synergy_test_card("Extração de Ferro"),
		CampaignTestFixtures.build_synergy_test_card("Extração de Ferro"),
		CampaignTestFixtures.build_synergy_test_card("Treinamento Ofensivo"),
	]
	print("  Uma Sinergia -> %s" % str(CampaignSynergyCalculator.calculate(one_synergy_cards)))

	# Múltiplas Sinergias coexistindo: 2x Extração de Ferro, 3x Treinamento Ofensivo, 1 única.
	var multiple_synergy_cards: Array[CardResource] = [
		CampaignTestFixtures.build_synergy_test_card("Extração de Ferro"),
		CampaignTestFixtures.build_synergy_test_card("Extração de Ferro"),
		CampaignTestFixtures.build_synergy_test_card("Treinamento Ofensivo"),
		CampaignTestFixtures.build_synergy_test_card("Treinamento Ofensivo"),
		CampaignTestFixtures.build_synergy_test_card("Treinamento Ofensivo"),
		CampaignTestFixtures.build_synergy_test_card("Suprimentos de Campanha"),
	]
	print("  Múltiplas Sinergias -> %s" % str(CampaignSynergyCalculator.calculate(multiple_synergy_cards)))
	print("    Ativas: %s" % str(CampaignSynergyCalculator.active_synergies(multiple_synergy_cards)))

	# Cartas repetidas: mesma referência de CardResource usada 9 vezes (ex: Army real com 9 cópias).
	var real_card: CardResource = GameDatabase.get_card("Legionário Imperial")
	if real_card != null:
		var repeated_cards: Array[CardResource] = []
		for i in range(9):
			repeated_cards.append(real_card)
		print("  9 cópias de '%s' (Tier III: '%s') -> %s" % [
			real_card.card_name, real_card.tier_3_ability_name, str(CampaignSynergyCalculator.calculate(repeated_cards))
		])

	return true
