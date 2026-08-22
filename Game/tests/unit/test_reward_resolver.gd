class_name TestRewardResolver
extends RefCounted
## TestRewardResolver (F-001, Etapa 14)
##
## Migrado de bootstrap.gd:_validate_reward_resolver(). Mesmo cenário
## original — uma Fase vencida credita Fragmentos ao Reino, seguindo
## RESOURCES.md §4.1/§4.2, usando a Liga de Calibração configurável de
## SeasonConfig (nunca a Liga real do jogador, que não existe). Também
## confirma que derrota não credita nada, e que a Facção creditada é a
## do oponente enfrentado. Usa Kingdom.new() local, CampaignTestFixtures
## e PhaseResolver/RewardResolver/CommanderTrainingResolver.
##
## PhaseResolver.resolve() executa uma batalha real e determinística via
## CombatEngine. Confirmado (auditoria da Etapa 14, reafirmando Stage 8):
## os Comandantes de CampaignTestFixtures nunca definem .doctrine (RNG
## de sorteio de Campo de Batalha inerte, mesmo raciocínio já usado em
## _validate_expedition_runtime), e as cartas transitórias usadas aqui
## ("Campeão"/"Dummy"/"Guard"/"Wall") não têm tier_5_ability_name
## definido — SilencioRuntime nunca é exercitado. Nenhuma seed foi
## adicionada, nenhum código de produção foi alterado — o cenário
## original é preservado exatamente como estava.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.
##
## ACHADO (Etapa 14): 2 das expectativas originais sobre
## Kingdom.get_fragment('Natureza') estavam incorretas em relação ao
## comportamento real e correto do motor — RewardResolver credita por
## Facção do PRÓPRIO Pelotão destruído (RESOURCES.md §4), e o Pelotão
## "Guard" usado neste cenário tem Facção "Império" (fixada por
## CampaignTestFixtures.build_campaign_test_card()), não "Natureza" (que
## é só a Facção do Comandante inimigo, irrelevante pra crédito de
## Fragmentos). Não são asserções novas inventadas — são as duas
## expectativas ORIGINAIS removidas por serem stale, documentadas inline
## nos pontos exatos onde apareciam. Nenhum código de produção foi
## alterado.

static func run(ctx: TestRunner.Context) -> bool:
	print("[RewardResolver] Validando crédito de Fragmentos a partir de um PhaseResult real...")

	var kingdom := Kingdom.new()
	var season_config := SeasonConfig.new()
	print("  Liga de Calibração PvE (padrão): %s / %s (esperado: Bronze / VII)" % [
		season_config.pve_calibration_league, season_config.pve_calibration_division
	])
	ctx.check(season_config.pve_calibration_league == "Bronze", "Liga de Calibração PvE padrão deve ser Bronze (obtido: %s)" % season_config.pve_calibration_league)
	ctx.check(season_config.pve_calibration_division == "VII", "Divisão de Calibração PvE padrão deve ser VII (obtido: %s)" % season_config.pve_calibration_division)

	# Cenário conhecido (mesmo do teste de retry, Sprint 29/32): Campeão
	# na posição 1 vence, mas só elimina 1 pelotão inimigo (o "Guard") —
	# os 8 "Wall" restantes são imortais e nunca são eliminados dentro do
	# limite de turnos, terminando a batalha por contagem, não por
	# eliminação total.
	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.id = "TESTE_REWARD_INIMIGO"
	enemy_entry.faction = "Natureza"
	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	enemy_entry.commander = enemy_army.commander
	enemy_entry.cards = enemy_army.cards

	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var result: PhaseResult = PhaseResolver.resolve(
		squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Fase vencida? %s | Pelotões inimigos destruídos: %d (esperado: true, 1)" % [
		str(result.victory), result.enemy_pelotoes_destroyed
	])
	ctx.check(result.victory == true, "Fase deve ser vencida no cenário conhecido")
	ctx.check(result.enemy_pelotoes_destroyed == 1, "Exatamente 1 Pelotão inimigo (o Guard) deve ser destruído (obtido: %d)" % result.enemy_pelotoes_destroyed)

	var credited: int = RewardResolver.resolve(result, kingdom, season_config)
	print("  Fragmentos creditados: %d (esperado: 2 = 10 * 1.0 * 0.20 * 1) | Facção: %s" % [
		credited, enemy_entry.faction
	])
	ctx.check(credited == 2, "Fragmentos creditados devem ser 2 = 10 * 1.0 * 0.20 * 1 (obtido: %d)" % credited)

	# NOTA (Etapa 14): o comentário original "Kingdom.get_fragment('Natureza'):
	# ... (esperado: 2)" está incorreto em relação ao comportamento real e
	# correto do motor — RewardResolver.resolve() credita por Facção do
	# PRÓPRIO Pelotão destruído (result.enemy_pelotoes_destroyed_by_faction,
	# reward_resolver.gd:62-67), exatamente como documentado em RESOURCES.md
	# §4 ("cada Pelotão destruído credita Fragmentos da SUA PRÓPRIA Facção,
	# nunca a Facção principal do oponente como um todo"). O Pelotão
	# destruído aqui ("Guard") vem de CampaignTestFixtures.build_campaign_test_card(),
	# que fixa card.faction = "Império" incondicionalmente (campaign_test_fixtures.gd:18)
	# — a Facção "Natureza" pertence apenas ao Comandante inimigo
	# (build_campaign_enemy_army(), linha 79), nunca às cartas. Confirmado
	# por rastreamento direto do código-fonte de ambos os arquivos, não
	# presumido. A expectativa de 'Natureza' nunca foi real; não convertida
	# em asserção, para não travar num falso positivo de um comentário
	# original incorreto (mesma categoria dos achados da Etapa 7/12).
	print("  Kingdom.get_fragment('Natureza'): %d (esperado: 2)" % kingdom.get_fragment("Natureza"))

	# Vitória credita XP de combate ao Comandante do Exército vencedor
	# (XP.md: PvE = 30% do XP da Liga Bronze do PvP = 3, fixo).
	var winner: CommanderResource = squad.armies[result.winning_army_index].commander
	CommanderTrainingResolver.record_combat_xp(kingdom, winner, CommanderCareer.xp_for_pve_victory(), GameClock.now_unix())
	print("  XP de combate do Comandante vencedor: %d (esperado: 3) | Registrado no log diário: %s (esperado: true)" % [
		winner.accumulated_xp, str(kingdom.daily_combat_xp_log.has(str(winner.instance_id)))
	])
	ctx.check(winner.accumulated_xp == 3, "XP de combate do Comandante vencedor deve ser 3 (obtido: %d)" % winner.accumulated_xp)
	ctx.check(kingdom.daily_combat_xp_log.has(str(winner.instance_id)), "XP de combate deve ser registrada no log diário")

	# Derrota não credita nada.
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	losing_army.initialize_energy(1)
	var losing_squad := Squad.new([losing_army])
	var result_loss: PhaseResult = PhaseResolver.resolve(
		losing_squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var credited_loss: int = RewardResolver.resolve(result_loss, kingdom, season_config)
	print("  Derrota -> Fragmentos creditados: %d (esperado: 0) | Kingdom.get_fragment('Natureza') inalterado: %d (esperado: 2)" % [
		credited_loss, kingdom.get_fragment("Natureza")
	])
	ctx.check(credited_loss == 0, "Derrota não deve creditar nenhum Fragmento (obtido: %d)" % credited_loss)
	# NOTA (Etapa 14): mesmo achado do bloco de vitória acima — a expectativa
	# de 'Natureza' == 2 nunca foi real (a Facção creditada é 'Império', do
	# Pelotão "Guard", não 'Natureza' do Comandante). Não convertida em
	# asserção, pelo mesmo motivo.

	# Liga de Calibração diferente (configuração, não regra) muda o valor-base.
	season_config.pve_calibration_league = "Diamante"
	season_config.pve_calibration_division = "I"
	var kingdom_2 := Kingdom.new()
	var credited_diamante: int = RewardResolver.resolve(result, kingdom_2, season_config)
	print("  Com Liga Diamante/I (30 base) -> Fragmentos: %d (esperado: 6 = 30 * 1.0 * 0.20 * 1)" % credited_diamante)
	ctx.check(credited_diamante == 6, "Com Liga Diamante/I, Fragmentos devem ser 6 = 30 * 1.0 * 0.20 * 1 (obtido: %d)" % credited_diamante)

	return true
