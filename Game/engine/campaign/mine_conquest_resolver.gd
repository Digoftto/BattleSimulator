class_name MineConquestResolver
extends RefCounted
## MineConquestResolver
##
## Resolve uma tentativa de conquistar uma Mina: usa Squad/PhaseResolver
## exatamente como uma Fase normal, mas contra um Chefe de Mina
## (EnemyArmyEntry.Category.CHEFE_DE_MINA) — sem fazer parte da
## sequência automática da Trilha (PvE.md: Minas são ramificações
## opcionais, nunca bloqueiam a marcha principal; o jogador precisa se
## deslocar ativamente até elas).
##
## Escopo atual: a conquista em si (vitória -> Mina.conquer()), o
## congelamento permanente da Formação de Referência do Ciclo de
## Mineração (MINES.md) a partir do mesmo Chefe de Mina derrotado, e o
## XP de Conta de "Liberar Mina (Primeira vez)" (XP.md, 20 XP
## Estrutural — nunca concedido de novo para a mesma Mina). Nenhum
## recurso é concedido aqui — a produção de Recursos de Construção
## (MINES.md, "Ciclo de Mineração") é um cálculo em lote ao longo de
## ~100 horas, que depende do motor de simulação das 362.880
## combinações (já implementado em MiningCycleResolver, mas não
## acionado automaticamente aqui — isso pertence à designação da
## Guarnição, não à conquista em si).


## Tenta conquistar "mina". Retorna null sem fazer nada se a Mina já
## estiver conquistada, for uma Mina Inicial (sem Fase, não usa este
## fluxo) ou não houver Chefe de Mina compatível no Catálogo. Caso
## contrário, resolve a batalha e marca a Mina como conquistada em caso
## de vitória.
static func attempt_conquest(
	mina: Mina,
	trilha: Trilha,
	squad: Squad,
	catalog: SeasonCatalog,
	faction: String,
	seed_value: int,
	battlefields: Array[BattlefieldResource],
	abilities_by_name: Dictionary,
	unit_traits: Array[UnitTraitResource],
	kingdom: Kingdom
) -> PhaseResult:
	if mina.conquered or mina.is_initial_mine():
		return null

	var region: int = trilha.region_for_fase(mina.adjacent_fase)
	var entry: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, faction, EnemyArmyEntry.Category.CHEFE_DE_MINA, region, mina.adjacent_fase, seed_value, null
	)
	if entry == null:
		return null

	var result: PhaseResult = PhaseResolver.resolve(squad, entry, battlefields, abilities_by_name, unit_traits, "Conquista de Mina", "mines")
	if result.victory:
		mina.conquer()
		mina.freeze_reference_formation(entry.cards, entry.commander)
		AccountXPResolver.grant_mina_liberada(kingdom, "%d:%s" % [mina.adjacent_fase, mina.faction])
		# RESOURCES.md §4: Conquista de Mina é um combate real, destrói
		# Pelotões reais — concede Fragmentos igual a qualquer outra
		# Fase vencida (RewardResolver já existia, testado, correto,
		# mas nunca era chamado fora dos meus testes).
		RewardResolver.resolve(result, kingdom, SeasonConfig.new())
		# XP.md / CommanderCareer.xp_for_pve_victory(): mesma lacuna do
		# PvE normal — Conquista de Mina também é um combate de
		# verdade, também deveria dar XP ao Comandante vencedor.
		var winning_army: Army = squad.armies[result.winning_army_index]
		if winning_army.commander != null:
			CommanderTrainingResolver.record_combat_xp(
				kingdom, winning_army.commander, CommanderCareer.xp_for_pve_victory(), GameClock.now_unix()
			)
	return result
