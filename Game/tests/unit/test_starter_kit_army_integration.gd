class_name TestStarterKitArmyIntegration
extends RefCounted
## TestStarterKitArmyIntegration (F-030)
##
## Valida a experiência inicial do jogador de ponta a ponta: escolha
## de Facção -> Commander/Army reais e corretos -> Cidade -> Reino
## persistido -> os MESMOS 3 Exércitos Iniciais consumíveis pelo
## simulador do F-029 sem nenhuma conversão/duplicação conceitual
## (F-030 §23).
##
## Testes A-I (F-030 §19). "Teste I" (multithread) do F-029 não existe
## aqui — não é o escopo deste arquivo.

const OFFICIAL_ROSTERS: Dictionary = {
	"Império": [
		"Arqueiro Imperial", "Engenheiro Imperial", "Escudeiro Imperial",
		"Evocador Imperial", "Infante Imperial", "Legionário Imperial",
		"Carvalho Ancião", "Trepadeira Ancestral", "Flor da Aurora",
	],
	"Natureza": [
		"Carvalho Ancião", "Ent Jovem", "Flor da Aurora",
		"Porco-Espinho Ancestral", "Trepadeira Ancestral", "Urso Ancestral",
		"Liche Iniciado", "Abominação Putrefata", "Sacerdote Profano",
	],
	"Mortos-Vivos": [
		"Abominação Putrefata", "Arqueiro Esquelético", "Banshee",
		"Esqueleto Guerreiro", "Liche Iniciado", "Sacerdote Profano",
		"Ent Jovem", "Urso Ancestral", "Flor da Aurora",
	],
}


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-030] Validando a experiência inicial do jogador e a integração dos Exércitos Iniciais com a simulação...")

	_test_a_b_c_choose_each_faction(ctx)
	_test_d_commander_correct(ctx)
	_test_e_choice_only_once(ctx)
	_test_f_restart_preserves_choice(ctx)
	_test_g_ui_army_equals_simulation_army(ctx)
	_test_h_fixed_vs_fixed_accepts_starter_armies(ctx)
	_test_i_benchmark_deterministic(ctx)

	return true


## Testes A/B/C: escolher cada Facção -> Starter Army com o roster
## oficial EXATO (INICIALIZAÇÃO.png), na ordem certa.
static func _test_a_b_c_choose_each_faction(ctx: TestRunner.Context) -> void:
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var kingdom := Kingdom.new()
		var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
		var option: Dictionary = _find_option(options, faction)

		var result: Dictionary = StarterKitResolver.choose_option(kingdom, option, GameClock.now_unix())
		var army: Army = kingdom.armies[0] if not kingdom.armies.is_empty() else null

		var names: Array[String] = []
		if army != null:
			for card: CardResource in army.cards:
				names.append(card.card_name)

		var matches: bool = names == OFFICIAL_ROSTERS[faction]

		print("  [%s] Escolha bem-sucedida? %s | Exército formado com o roster oficial exato? %s (esperado: true, true)" % [
			faction, str(result["success"]), str(matches)
		])
		ctx.check(result["success"], "[%s] A escolha deve ser bem-sucedida" % faction)
		ctx.check(matches, "[%s] O Starter Army formado deve ter exatamente o roster oficial de INICIALIZAÇÃO.png, na ordem certa (obtido: %s)" % [faction, str(names)])


## Teste D: Commander correto em cada escolha — "Comandante Recruta",
## Facção certa, sem Doutrina, Estado Ativo (imediato, exceção
## estrutural do Kit Inicial).
static func _test_d_commander_correct(ctx: TestRunner.Context) -> void:
	var all_correct: bool = true
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var kingdom := Kingdom.new()
		var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
		var option: Dictionary = _find_option(options, faction)
		StarterKitResolver.choose_option(kingdom, option, GameClock.now_unix())

		var commander: CommanderResource = kingdom.commanders[0] if not kingdom.commanders.is_empty() else null
		if commander == null:
			all_correct = false
			continue
		if commander.commander_name != "Comandante Recruta":
			all_correct = false
		if commander.faction != faction:
			all_correct = false
		if commander.doctrine != null:
			all_correct = false
		if commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
			all_correct = false

	print("  [D] Em todas as 3 escolhas, o Commander é 'Comandante Recruta', Facção correta, sem Doutrina, Estado Ativo? %s (esperado: true)" % str(all_correct))
	ctx.check(all_correct, "[D] O Commander de cada escolha deve ser exatamente 'Comandante Recruta' da Facção certa, sem Doutrina, já Ativo")


## Teste E: a escolha não pode ser feita duas vezes no mesmo Reino.
static func _test_e_choice_only_once(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)

	var first_result: Dictionary = StarterKitResolver.choose_option(kingdom, options[0], GameClock.now_unix())
	var armies_after_first: int = kingdom.armies.size()
	var second_result: Dictionary = StarterKitResolver.choose_option(kingdom, options[1], GameClock.now_unix())
	var armies_after_second: int = kingdom.armies.size()

	print("  [E] Primeira escolha bem-sucedida? %s | Segunda escolha bloqueada (already_used)? %s | Nenhum Exército extra formado? %s (esperado: true, true, true)" % [
		str(first_result["success"]), str(not second_result["success"] and second_result["reason"] == "already_used"),
		str(armies_after_first == armies_after_second)
	])
	ctx.check(first_result["success"], "[E] A primeira escolha deve ser bem-sucedida")
	ctx.check(not second_result["success"] and second_result["reason"] == "already_used", "[E] Uma segunda escolha no mesmo Reino deve ser bloqueada com reason='already_used'")
	ctx.check(armies_after_first == armies_after_second, "[E] Uma segunda escolha bloqueada não deve formar um segundo Exército")


## Teste F: reiniciar (salvar em disco, carregar num Kingdom novo)
## preserva Facção, Commander, Starter Army e starter_kit_used — a
## escolha inicial nunca reaparece para uma conta já inicializada.
static func _test_f_restart_preserves_choice(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var original := Kingdom.new()
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	var option: Dictionary = _find_option(options, "Natureza")
	StarterKitResolver.choose_option(original, option, GameClock.now_unix())
	KingdomSaveService.save(original)

	var reloaded := Kingdom.new()
	KingdomSaveService.load_into(reloaded)

	var commander: CommanderResource = reloaded.commanders[0] if not reloaded.commanders.is_empty() else null
	var army: Army = reloaded.armies[0] if not reloaded.armies.is_empty() else null
	var names: Array[String] = []
	if army != null:
		for card: CardResource in army.cards:
			names.append(card.card_name)

	var faction_preserved: bool = commander != null and commander.faction == "Natureza"
	var army_preserved: bool = names == OFFICIAL_ROSTERS["Natureza"]
	var flag_preserved: bool = reloaded.starter_kit_used

	print("  [F] Reiniciar (salvar/carregar) preserva Facção? %s | Starter Army? %s | starter_kit_used continua true (tela não reaparece)? %s (esperado: true em todos)" % [
		str(faction_preserved), str(army_preserved), str(flag_preserved)
	])
	ctx.check(faction_preserved, "[F] A Facção escolhida deve sobreviver a salvar/carregar")
	ctx.check(army_preserved, "[F] O Starter Army deve sobreviver a salvar/carregar, sem mudar")
	ctx.check(flag_preserved, "[F] starter_kit_used deve continuar true após carregar — a tela de escolha não deve reaparecer")

	KingdomSaveService.delete_save()


## Teste G: o MESMO Army usado pela Cidade (formado via
## StarterKitResolver.choose_option -> Kingdom.form_army()) pode ir
## direto para o BattleSimulationRunner (F-029), sem conversão nem
## segunda cópia conceitual do roster.
static func _test_g_ui_army_equals_simulation_army(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	var option: Dictionary = _find_option(options, "Império")
	StarterKitResolver.choose_option(kingdom, option, GameClock.now_unix())

	var player_army: Army = kingdom.armies[0]
	var opponent: Army = _fresh_starter_army("Mortos-Vivos")

	var pairs: Array = BattleSimulationRunner.build_fixed_vs_fixed_pairs(player_army, opponent, 1)
	var same_object: bool = pairs[0]["army_a"] == player_army

	var config := SimulationConfig.new()
	config.simulation_count = 1
	config.base_seed_value = 20000
	var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	var ran_successfully: bool = results.size() == 1 and results[0].turn_count > 0

	print("  [G] O Army real do Reino (formado pela Cidade) é o MESMO objeto usado pelo par de simulação (sem cópia)? %s | A batalha rodou de verdade com ele? %s (esperado: true, true)" % [
		str(same_object), str(ran_successfully)
	])
	ctx.check(same_object, "[G] BattleSimulationRunner deve consumir o Army real do Reino diretamente, sem duplicar/converter")
	ctx.check(ran_successfully, "[G] A batalha com o Army real do Reino deve rodar normalmente pelo CombatEngine")


## Teste H: Fixed vs Fixed aceita os 3 Starter Armies (Império x
## Natureza, Império x Mortos-Vivos, Natureza x Mortos-Vivos).
static func _test_h_fixed_vs_fixed_accepts_starter_armies(ctx: TestRunner.Context) -> void:
	var imperio: Army = _fresh_starter_army("Império")
	var natureza: Army = _fresh_starter_army("Natureza")
	var mortos_vivos: Army = _fresh_starter_army("Mortos-Vivos")

	var all_ran: bool = true
	for matchup: Array in [[imperio, natureza], [imperio, mortos_vivos], [natureza, mortos_vivos]]:
		var pairs: Array = BattleSimulationRunner.build_fixed_vs_fixed_pairs(matchup[0], matchup[1], 5)
		var config := SimulationConfig.new()
		config.simulation_count = 5
		config.base_seed_value = 30000
		var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
		if results.size() != 5:
			all_ran = false

	print("  [H] Os 3 confrontos Fixed vs Fixed entre os Starter Armies (Império x Natureza, Império x Mortos-Vivos, Natureza x Mortos-Vivos) rodaram normalmente? %s (esperado: true)" % str(all_ran))
	ctx.check(all_ran, "[H] BattleSimulationRunner deve aceitar os 3 Starter Armies em qualquer combinação Fixed vs Fixed")


## Teste I: o benchmark entre Starter Armies é determinístico — mesma
## seed-base -> mesmo SimulationReport (mesmo padrão do F-029 Teste F).
static func _test_i_benchmark_deterministic(ctx: TestRunner.Context) -> void:
	var imperio: Army = _fresh_starter_army("Império")
	var natureza: Army = _fresh_starter_army("Natureza")

	var report1: SimulationReport = _run_benchmark(imperio, natureza, 50, 40000)
	var report2: SimulationReport = _run_benchmark(_fresh_starter_army("Império"), _fresh_starter_army("Natureza"), 50, 40000)

	var dict1: Dictionary = report1.to_dict()
	var dict2: Dictionary = report2.to_dict()
	dict1.erase("generated_at_unix")
	dict2.erase("generated_at_unix")
	var same_report: bool = dict1 == dict2

	print("  [I] Benchmark Império x Natureza (50 batalhas, seed-base 40000) reproduzido duas vezes -> SimulationReport idêntico (exceto timestamp)? %s (esperado: true)" % str(same_report))
	ctx.check(same_report, "[I] O benchmark entre Starter Armies deve ser determinístico — mesma seed-base, mesmo relatório")


static func _run_benchmark(army_a: Army, army_b: Army, count: int, base_seed_value: int) -> SimulationReport:
	var pairs: Array = BattleSimulationRunner.build_fixed_vs_fixed_pairs(army_a, army_b, count)
	var config := SimulationConfig.new()
	config.simulation_count = count
	config.base_seed_value = base_seed_value
	var results: Array[BattleResult] = BattleSimulationRunner.run_series(pairs, config, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	return SimulationReport.build(results)


static func _find_option(options: Array[Dictionary], faction: String) -> Dictionary:
	for option: Dictionary in options:
		if option["faction"] == faction:
			return option
	return {}


## Monta um Army "solto" (fora de qualquer Kingdom) com o roster
## oficial de uma Facção — usado nos Testes G/H/I, que testam o
## consumo pelo simulador, não o fluxo de escolha em si.
static func _fresh_starter_army(faction: String) -> Army:
	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	var option: Dictionary = _find_option(options, faction)
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = option["cards"]
	return army
