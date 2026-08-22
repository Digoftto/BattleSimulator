class_name TestCommanderBattleHistory
extends RefCounted
## TestCommanderBattleHistory (F-001, Etapa 15 — migração PARCIAL)
##
## Migrado de bootstrap.gd:_validate_commander_battle_history(), Partes
## 1 e 2 apenas:
##   Parte 1 ("Motor puro"): CommanderResource.record_battle() agregando
##   V/E/D e mantendo só as últimas 20 batalhas (FIFO).
##   Parte 2 ("Wiring real"): uma batalha de PvE de verdade via
##   PhaseResolver.resolve() credita o Comandante vencedor automaticamente
##   e registra o contexto certo no Histórico. Mesma prova de RNG inerte
##   já usada em test_reward_resolver.gd (CampaignTestFixtures nunca
##   define .doctrine, cartas transitórias sem tier_5_ability_name).
##
## A Parte 3 do original ("--- A tela ---": KingdomState.kingdom,
## comandantes_panel.tscn, _panel_contains_text()) foi DELIBERADAMENTE
## excluída desta migração — depende de KingdomState.kingdom (estado
## global) e de instanciação de cena/UI, fora do escopo desta etapa.
## Permanece em bootstrap.gd, intocada. O Comandante e seu histórico de
## 26 batalhas usados pela Parte 3 (checks "V:13" e "Empatador") também
## permanecem construídos lá, já que a Parte 3 depende diretamente desse
## mesmo objeto — apenas as duas asserções da Parte 1 (já migradas aqui)
## foram removidas de bootstrap.gd, não a construção do Comandante em si.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Comandantes] Validando Histórico de Batalhas (motor puro + wiring real)...")

	# --- Motor puro: agregado + FIFO de 20 ---
	var commander := CommanderResource.new()
	commander.commander_name = "UI Histórico Comandante 111000"
	for i in range(25):
		var result: String = "Vitória" if i % 2 == 0 else "Derrota"
		commander.record_battle("Inimigo %d" % i, "PvE — Fase %d" % i, result, GameClock.now_unix())
	commander.record_battle("Empatador", "PvE — Fase 99", "Empate", GameClock.now_unix())

	print("  Após 26 batalhas (13V, 12D, 1E) -> Total: %d | V: %d | E: %d | D: %d | WR: %.1f%% (esperado: 26, 13, 1, 12, 50.0)" % [
		commander.total_battles, commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0
	])
	ctx.check(commander.total_battles == 26, "Total de batalhas deve ser 26 (obtido: %d)" % commander.total_battles)
	ctx.check(commander.total_victories == 13, "Total de vitórias deve ser 13 (obtido: %d)" % commander.total_victories)
	ctx.check(commander.total_draws == 1, "Total de empates deve ser 1 (obtido: %d)" % commander.total_draws)
	ctx.check(commander.total_defeats() == 12, "Total de derrotas deve ser 12 (obtido: %d)" % commander.total_defeats())
	ctx.check(commander.win_rate() * 100.0 == 50.0, "Taxa de vitória deve ser 50.0%% (obtido: %.1f%%)" % (commander.win_rate() * 100.0))

	print("  Histórico guarda só as últimas 20 (FIFO)? %s | Mais recente é a última registrada (Empatador)? %s (esperado: true, true)" % [
		str(commander.battle_log.size() == 20), str(commander.battle_log[0]["opponent_name"] == "Empatador")
	])
	ctx.check(commander.battle_log.size() == 20, "Histórico deve guardar só as últimas 20 batalhas (obtido: %d)" % commander.battle_log.size())
	ctx.check(commander.battle_log[0]["opponent_name"] == "Empatador", "Batalha mais recente do Histórico deve ser contra o Empatador (obtido: %s)" % commander.battle_log[0]["opponent_name"])

	# --- Wiring real: uma batalha de PvE de verdade credita o Comandante ---
	var winner_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	winner_army.initialize_energy(1)
	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var squad := Squad.new([winner_army])
	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.commander = enemy_army.commander
	enemy_entry.cards = enemy_army.cards
	enemy_entry.faction = "Mortos-Vivos"

	var phase_result: PhaseResult = PhaseResolver.resolve(
		squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "PvE — Fase 1 (Teste)"
	)
	print("  Uma batalha de PvE de verdade credita o Comandante vencedor automaticamente? %s | Histórico registrou o contexto certo? %s (esperado: true, true)" % [
		str(winner_army.commander.total_battles > 0), str(winner_army.commander.battle_log[0]["context"] == "PvE — Fase 1 (Teste)")
	])
	ctx.check(winner_army.commander.total_battles > 0, "Comandante vencedor deve ser creditado automaticamente após a batalha")
	ctx.check(winner_army.commander.battle_log[0]["context"] == "PvE — Fase 1 (Teste)", "Histórico do Comandante vencedor deve registrar o contexto certo (obtido: %s)" % winner_army.commander.battle_log[0]["context"])

	return true
