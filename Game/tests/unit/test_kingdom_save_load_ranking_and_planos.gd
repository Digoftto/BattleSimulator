class_name TestKingdomSaveLoadRankingAndPlanos
extends RefCounted
## TestKingdomSaveLoadRankingAndPlanos (F-013)
##
## Regressão para as duas lacunas de serialização confirmadas na F-012:
## CommanderResource.bronze_pl/bronze_divisao (Liga Bronze) e
## Kingdom.planos_campanha (Ligas Prata/Ouro/Diamante) nunca
## sobreviviam a um round-trip de KingdomSaveService — os campos
## simplesmente não existiam em nenhuma das duas direções da
## serialização. A F-013 corrigiu isso reaproveitando exatamente os
## mesmos padrões já usados por Commander (campos escalares extras) e
## por Squad.armies (referência por índice) — nenhum mecanismo novo.
##
## Usa user://kingdom_save.json de verdade (o único caminho que
## KingdomSaveService conhece) — limpa o save antes E depois de cada
## cenário pra não vazar estado pra outros testes desta suíte nem pra
## uma execução real de bootstrap.tscn/main.tscn depois.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-013] Validando round-trip de bronze_pl/bronze_divisao e PlanoCampanha...")

	KingdomSaveService.delete_save()

	# --- Cenário: Comandante inscrito na Liga Bronze + Plano de Campanha completo ---
	var original := Kingdom.new()

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Ranking)"
	commander.faction = "Império"
	commander.bronze_pl = 340
	commander.bronze_divisao = "IV"
	original.add_commander(commander)

	var army_a := CampaignTestFixtures.build_campaign_test_army({})
	army_a.army_name = "Exército A do Plano"
	var army_b := CampaignTestFixtures.build_campaign_test_army({})
	army_b.army_name = "Exército B do Plano"
	original.add_army(army_a)
	original.add_army(army_b)

	var plano_armies: Array[Army] = [army_a, army_b]
	var plano := PlanoCampanha.new(plano_armies)
	plano.battlefield_mapping = {"Campo Especial 1": 0, "Campo Especial 2": 1}
	plano.defesa_preferencial_index = 1
	plano.ordem_de_ataque = [1, 0]
	plano.liga = "Prata"
	plano.pl = 275
	plano.divisao = "II"
	original.planos_campanha.append(plano)

	var saved: bool = KingdomSaveService.save(original)
	print("  Salvou com sucesso? %s (esperado: true)" % str(saved))
	ctx.check(saved, "KingdomSaveService.save() deve ter sucesso com Comandante+Plano de Campanha presentes")

	var loaded := Kingdom.new()
	var loaded_ok: bool = KingdomSaveService.load_into(loaded)
	print("  Carregou com sucesso? %s (esperado: true)" % str(loaded_ok))
	ctx.check(loaded_ok, "KingdomSaveService.load_into() deve ter sucesso lendo o save recém-gravado")

	# --- bronze_pl / bronze_divisao ---
	var loaded_commander: CommanderResource = loaded.commanders[0]
	print("  bronze_pl sobreviveu? %d (esperado: 340)" % loaded_commander.bronze_pl)
	ctx.check(loaded_commander.bronze_pl == 340, "CommanderResource.bronze_pl deve sobreviver ao round-trip")
	print("  bronze_divisao sobreviveu? '%s' (esperado: 'IV')" % loaded_commander.bronze_divisao)
	ctx.check(loaded_commander.bronze_divisao == "IV", "CommanderResource.bronze_divisao deve sobreviver ao round-trip")

	# --- PlanoCampanha ---
	print("  Quantidade de Planos de Campanha carregados: %d (esperado: 1)" % loaded.planos_campanha.size())
	ctx.check(loaded.planos_campanha.size() == 1, "Kingdom.planos_campanha deve sobreviver ao round-trip")

	if not loaded.planos_campanha.is_empty():
		var loaded_plano: PlanoCampanha = loaded.planos_campanha[0]

		print("  battlefield_mapping preservado? %s (esperado: true)" % str(
			loaded_plano.battlefield_mapping.get("Campo Especial 1", -1) == 0 and
			loaded_plano.battlefield_mapping.get("Campo Especial 2", -1) == 1
		))
		ctx.check(
			loaded_plano.battlefield_mapping.get("Campo Especial 1", -1) == 0 and
			loaded_plano.battlefield_mapping.get("Campo Especial 2", -1) == 1,
			"battlefield_mapping deve sobreviver ao round-trip"
		)

		print("  defesa_preferencial_index preservado? %d (esperado: 1)" % loaded_plano.defesa_preferencial_index)
		ctx.check(loaded_plano.defesa_preferencial_index == 1, "defesa_preferencial_index deve sobreviver ao round-trip")

		print("  ordem_de_ataque preservada? %s (esperado: [1, 0])" % str(loaded_plano.ordem_de_ataque))
		ctx.check(loaded_plano.ordem_de_ataque == [1, 0], "ordem_de_ataque deve sobreviver ao round-trip")

		print("  liga/pl/divisao preservados? %s | %d | %s (esperado: Prata | 275 | II)" % [
			loaded_plano.liga, loaded_plano.pl, loaded_plano.divisao
		])
		ctx.check(
			loaded_plano.liga == "Prata" and loaded_plano.pl == 275 and loaded_plano.divisao == "II",
			"liga/pl/divisao devem sobreviver ao round-trip"
		)

		# --- Identidade das referências de Exército (mesmo padrão já
		# provado para Squad.armies em _validate_kingdom_save_load()) ---
		print("  Plano ainda referencia os MESMOS Exércitos carregados (não cópias soltas)? %s (esperado: true)" % str(
			loaded_plano.armies.size() == 2 and
			loaded_plano.armies[0] == loaded.armies[0] and
			loaded_plano.armies[1] == loaded.armies[1]
		))
		ctx.check(
			loaded_plano.armies.size() == 2 and
			loaded_plano.armies[0] == loaded.armies[0] and
			loaded_plano.armies[1] == loaded.armies[1],
			"PlanoCampanha.armies deve apontar exatamente para as instâncias de Army carregadas em Kingdom.armies"
		)
		print("  Nomes dos Exércitos do Plano, na ordem certa: '%s', '%s' (esperado: 'Exército A do Plano', 'Exército B do Plano')" % [
			loaded_plano.armies[0].army_name, loaded_plano.armies[1].army_name
		])
		ctx.check(
			loaded_plano.armies[0].army_name == "Exército A do Plano" and loaded_plano.armies[1].army_name == "Exército B do Plano",
			"A ordem dos Exércitos dentro do Plano deve ser preservada"
		)

	KingdomSaveService.delete_save()
	return true
