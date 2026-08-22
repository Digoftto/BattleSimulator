class_name TestKingdomPersistenceRoundtrip
extends RefCounted
## TestKingdomPersistenceRoundtrip (F-045)
##
## Round-trip real de persistência (criar/obter estado válido ->
## modificar -> salvar -> recarregar -> verificar preservação) cobrindo,
## numa única passada save/load, os domínios de dado pedidos pelo
## F-045: Army/Formação (múltiplas Formações nomeadas, não só a
## Formação ativa), Recursos/Recompensas (raw_resources), XP
## (account_xp), estado necessário da Cidade (capital_level/
## academy_level) e Comandante/Mina (progresso PvE persistido — a
## Expedição em si não é salva por design, ver cabeçalho de
## KingdomSaveService, mas o estado de conquista/nível de uma Mina é).
##
## O ciclo de vida do próprio MECANISMO de save/load (Reino novo sem
## save, save corrompido não trava o boot, autosave periódico,
## fechamento de janela) já é coberto por
## TestKingdomStateLoadLifecycle (F-013) usando Fragmentos como prova —
## este teste não duplica aquilo, cobre os DADOS que aquele teste não
## tocava.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-045] Validando round-trip real de persistência (Army/Formação, Recursos, XP, Cidade, Comandante, Mina)...")
	_check_full_roundtrip_preserves_all_relevant_domains(ctx)
	return true


static func _check_full_roundtrip_preserves_all_relevant_domains(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()

	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	var beta_formation: Array[CardResource] = army.cards.duplicate()
	beta_formation.reverse()
	army.formations["β"] = beta_formation
	kingdom.armies.append(army)

	kingdom.capital_level = 3
	kingdom.academy_level = 2

	kingdom.raw_resources["Madeira"] = 4200

	kingdom.account_xp = 15000

	army.commander.accumulated_xp = 777
	army.commander.total_battles = 12
	kingdom.commanders.append(army.commander)

	ctx.check(kingdom.initial_mines.size() > 0, "[Pré-condição] create_initial_mines() deve produzir ao menos 1 Mina para este teste poder validar seu round-trip")
	var mine: Mina = kingdom.initial_mines[0]
	mine.conquered = true
	mine.structure_level = 4

	KingdomSaveService.save(kingdom)

	var loaded := Kingdom.new()
	KingdomSaveService.load_into(loaded)

	ctx.check(loaded.armies.size() > 0, "[Army] Ao menos 1 Exército deve sobreviver ao round-trip")
	if loaded.armies.size() > 0:
		var loaded_army: Army = loaded.armies[0]

		var original_alpha_names: Array[String] = []
		for c: CardResource in army.cards:
			original_alpha_names.append(c.card_name)
		var loaded_alpha_names: Array[String] = []
		for c: CardResource in loaded_army.cards:
			loaded_alpha_names.append(c.card_name)
		print("  [Army] Formação α preservada posição-por-posição? %s" % str(loaded_alpha_names == original_alpha_names))
		ctx.check(loaded_alpha_names == original_alpha_names, "[Army] A Formação α (army.cards) deve sobreviver ao round-trip exatamente na mesma ordem")

		var original_beta_names: Array[String] = []
		for c: CardResource in beta_formation:
			original_beta_names.append(c.card_name)
		ctx.check(loaded_army.formations.has("β"), "[Army] A Formação nomeada 'β' deve sobreviver ao round-trip, não só a α")
		if loaded_army.formations.has("β"):
			var loaded_beta_names: Array[String] = []
			for c: CardResource in loaded_army.formations["β"]:
				loaded_beta_names.append(c.card_name)
			print("  [Army] Formação β preservada posição-por-posição? %s" % str(loaded_beta_names == original_beta_names))
			ctx.check(loaded_beta_names == original_beta_names, "[Army] A Formação nomeada 'β' deve sobreviver ao round-trip exatamente na mesma ordem")

	print("  [Cidade] capital_level=%d (esperado 3) | academy_level=%d (esperado 2)" % [loaded.capital_level, loaded.academy_level])
	ctx.check(loaded.capital_level == 3, "[Cidade] capital_level deve sobreviver ao round-trip")
	ctx.check(loaded.academy_level == 2, "[Cidade] academy_level deve sobreviver ao round-trip")

	print("  [Recursos] raw_resources['Madeira']=%d (esperado 4200)" % int(loaded.raw_resources.get("Madeira", -1)))
	ctx.check(int(loaded.raw_resources.get("Madeira", -1)) == 4200, "[Recursos] raw_resources (pool de recompensas) deve sobreviver ao round-trip")

	print("  [XP] account_xp=%d (esperado 15000)" % loaded.account_xp)
	ctx.check(loaded.account_xp == 15000, "[XP] account_xp (Conta) deve sobreviver ao round-trip")

	ctx.check(loaded.commanders.size() > 0, "[Comandante] Ao menos 1 Comandante deve sobreviver ao round-trip")
	if loaded.commanders.size() > 0:
		var loaded_commander: CommanderResource = loaded.commanders[0]
		print("  [Comandante] accumulated_xp=%d (esperado 777) | total_battles=%d (esperado 12)" % [loaded_commander.accumulated_xp, loaded_commander.total_battles])
		ctx.check(loaded_commander.accumulated_xp == 777, "[Comandante] accumulated_xp deve sobreviver ao round-trip")
		ctx.check(loaded_commander.total_battles == 12, "[Comandante] total_battles deve sobreviver ao round-trip")

	ctx.check(loaded.initial_mines.size() > 0, "[Mina] Ao menos 1 Mina Inicial deve sobreviver ao round-trip")
	if loaded.initial_mines.size() > 0:
		var loaded_mine: Mina = loaded.initial_mines[0]
		print("  [Mina] conquered=%s (esperado true) | structure_level=%d (esperado 4)" % [str(loaded_mine.conquered), loaded_mine.structure_level])
		ctx.check(loaded_mine.conquered == true, "[Mina] O estado de conquista de uma Mina (progresso PvE persistido) deve sobreviver ao round-trip")
		ctx.check(loaded_mine.structure_level == 4, "[Mina] O nível de estrutura de uma Mina deve sobreviver ao round-trip")

	KingdomSaveService.delete_save()
