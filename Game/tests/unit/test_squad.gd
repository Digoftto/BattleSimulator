class_name TestSquad
extends RefCounted
## TestSquad (F-001, Etapa 3)
##
## Migrado de bootstrap.gd:_validate_squad() (Sprint 29). Mesmo cenário
## original (2 Exércitos, prioridade, avanço, esgotamento e reset) —
## utilizando exclusivamente Squad (lógica pura) e CampaignTestFixtures
## (tests/campaign_test_fixtures.gd, já um class_name independente e
## puro — reutilizado diretamente, sem cópia).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Squad] Validando prioridade e troca de Exército...")

	var army_a := CampaignTestFixtures.build_campaign_test_army({})
	army_a.army_name = "Exército A"
	var army_b := CampaignTestFixtures.build_campaign_test_army({})
	army_b.army_name = "Exército B"

	var squad := Squad.new([army_a, army_b])

	print("  Ativo inicial: %s (esperado: Exército A)" % squad.active_army().army_name)
	ctx.check(squad.active_army().army_name == "Exército A", "Ativo inicial deve ser Exército A (obtido: %s)" % squad.active_army().army_name)

	print("  Esgotado? %s (esperado: false)" % str(squad.is_exhausted()))
	ctx.check(squad.is_exhausted() == false, "Squad recém-criado não deve estar esgotado")

	squad.advance_to_next_army()
	print("  Após avançar: %s (esperado: Exército B)" % squad.active_army().army_name)
	ctx.check(squad.active_army().army_name == "Exército B", "Após avançar, ativo deve ser Exército B (obtido: %s)" % squad.active_army().army_name)

	squad.advance_to_next_army()
	print("  Após esgotar: esgotado? %s (esperado: true) | ativo: %s (esperado: null)" % [
		str(squad.is_exhausted()), str(squad.active_army())
	])
	ctx.check(squad.is_exhausted() == true, "Após avançar além do 2º Exército, Squad deve estar esgotado")
	ctx.check(squad.active_army() == null, "Squad esgotado deve retornar null como ativo")

	squad.reset()
	print("  Após reset: %s (esperado: Exército A)" % squad.active_army().army_name)
	ctx.check(squad.active_army().army_name == "Exército A", "Após reset, ativo deve voltar a ser Exército A (obtido: %s)" % squad.active_army().army_name)

	return true
