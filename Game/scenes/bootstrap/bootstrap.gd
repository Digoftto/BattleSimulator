extends Node
## Bootstrap
##
## Ponto de inicialização da engine. Orquestra, em ordem, o carregamento do
## banco de dados estático e a inicialização do estado do Reino, reportando
## o progresso através do EventBus.
##
## Nesta Sprint, nenhuma regra de jogo, combate ou interface é implementada
## além do necessário para validar que a engine inicializa corretamente.


func _ready() -> void:
	print("[Bootstrap] Iniciando Battle Simulator...")

	# Remove arquivos de relatório de execuções anteriores do Bootstrap
	# (res://reports/*) — persistem entre processos separados (ao
	# contrário de KingdomState, que reseta a cada execução), o que
	# tornava os testes de SimulationReportService/WorldBootstrap
	# dependentes de execuções passadas. Só afeta o resultado dos
	# testes automáticos — nunca dados de save do jogador
	# (kingdom_save.json fica intacto, mora fora de res://reports/).
	#
	# F-040: restrito aos arquivos que SimulationReportService/WorldBootstrap
	# realmente possuem (SEASON_CATALOG_PATH/BALANCE_REPORT_PATH/
	# GENERATION_LOG_PATH/REGIONAL_REPORT_PATH_TEMPLATE). Antes, o loop
	# apagava literalmente TODO arquivo em res://reports/ — destruiu os
	# dados brutos de benchmark salvos por engenheiros externos ao
	# Bootstrap (F-037/038/039, tools/debug/f0*.gd) sempre que
	# bootstrap.tscn rodava depois deles, mesmo esses arquivos não tendo
	# nenhuma relação com o que este bloco precisa garantir "limpo".
	if DirAccess.dir_exists_absolute("res://reports"):
		var reports_dir: DirAccess = DirAccess.open("res://reports")
		if reports_dir != null:
			for file_name: String in reports_dir.get_files():
				if _is_bootstrap_managed_report_file(file_name):
					reports_dir.remove(file_name)

	GameDatabase.load_database()
	# F-013: KingdomState.initialize_new_kingdom() agora carrega um save
	# real de user://kingdom_save.json se existir. Sem esta limpeza, um
	# save deixado por uma execução anterior (deste Bootstrap ou de
	# test_main.tscn) faria KingdomState.kingdom começar como um Reino
	# antigo em vez do Reino novo e vazio que todas as validações abaixo
	# pressupõem.
	KingdomSaveService.delete_save()
	KingdomState.initialize_new_kingdom()

	await _validate_game_clock()
	_validate_commander_generation()
	_validate_commander_career()
	_validate_battlefields()
	_validate_combat_engine()
	_validate_advanced_abilities()
	_validate_full_expedition_run()
	_validate_world_database()
	_validate_game_runtime()
	_validate_comandantes_panel_ui()
	_validate_treinamento_panel_ui()
	_validate_legado_panel_ui()
	_validate_army_formation_archetypes()
	await _validate_army_editor_existing_army_mode()
	_validate_pve_credits_fragments_for_real()
	_validate_debug_generate_candidate_button()
	await _validate_city_panel_syncs_periodically()
	_validate_initial_mine_shows_production_rate()
	_validate_academia_production_filters()
	_validate_recruitment_slots_show_sequential_time()
	_validate_battle_history_shows_formations()
	_validate_battle_history_shows_formation_grids()
	_validate_commander_doctrine_screen()
	_validate_player_editor_prevents_duplicate_names()
	_validate_switching_trilhas_records_correct_territory()
	_validate_pve_credits_account_and_commander_xp()
	_validate_enemy_composition_matches_territory_faction()
	_validate_army_unlocks_after_returning_to_camp()
	await _validate_army_cannot_be_double_booked()
	_validate_energy_frozen_while_marching()
	_validate_minas_panel_ui()
	await _validate_pve_panel_ui()
	_validate_army_editor_panel()
	_validate_world_bootstrap()
	await _validate_pve_panel_start_new_expedition()
	_validate_commander_doctrine()
	await _validate_exercitos_panel()
	await _validate_real_button_clicks_no_crash()
	# F-003: testa o comportamento assíncrono real do cálculo de
	# Eficiência (WorkerThreadPool) — 5 blocos, batalhas únicas e
	# válidas. Demorado (~4 minutos: simula um bloco real de 3.628
	# batalhas duas vezes, além de duas varreduras exaustivas de
	# 362.880 permutações para os testes de exclusão/esgotamento) —
	# opt-in via linha de comando (ver _should_run_mining_estimation_test()),
	# pra não pesar toda execução de bootstrap.tscn quando a mudança
	# sendo validada não tem nada a ver com Minas. Continua totalmente
	# intacta e com as mesmas asserções — só a invocação é opcional
	# (ver relatório final F-003, "heavy regression test placement").
	if _should_run_mining_estimation_test():
		_validate_mining_incremental_estimation()
	else:
		print("[Bootstrap] _validate_mining_incremental_estimation() PULADA (opt-in, ~4min) — rode com `-- --mining-estimation` pra incluí-la.")
	_validate_mine_activation_and_time_sync()
	_validate_army_editor_cancel()
	await _validate_pve_use_existing_army()
	await _validate_starter_kit()
	await _validate_city_panel()
	_validate_pvp_panel_ui()
	_validate_academia_panel()
	_validate_academia_chain_persistence()
	_validate_regional_generation()
	_validate_biblioteca_panel()
	_validate_commander_battle_history()
	_validate_balance_simulator_and_report_service()
	_validate_pve_generator_and_observatorio_panels()
	_validate_mining_cycle_engine()
	_validate_kingdom_save_load()

	# F-014: várias validações acima (_validate_kingdom_save_load(),
	# _validate_commander_doctrine(), _validate_academia_chain_persistence(),
	# a validação de Eficiência de Mineração) chamam
	# KingdomSaveService.save() de verdade, em user://kingdom_save.json —
	# o MESMO arquivo que o jogo real agora carrega ao iniciar (F-013).
	# Sem esta limpeza final, rodar bootstrap.tscn e depois jogar
	# main.tscn de verdade carregaria silenciosamente o último Reino de
	# teste do Bootstrap em vez de começar do zero.
	KingdomSaveService.delete_save()

	EventBus.engine_ready.emit()
	print("[Bootstrap] Engine inicializada com sucesso.")


## F-040: whitelist exata dos arquivos que SimulationReportService/
## WorldBootstrap gravam em res://reports/ (ver
## engine/world/simulation_report_service.gd, constantes
## SEASON_CATALOG_PATH/BALANCE_REPORT_PATH/GENERATION_LOG_PATH/
## REGIONAL_REPORT_PATH_TEMPLATE) — a limpeza no início de _ready() deve
## remover exatamente esses arquivos (pra manter os testes deste
## Bootstrap independentes de execuções anteriores DELES), nunca
## qualquer outro arquivo que outra ferramenta tenha salvo na mesma
## pasta (ex: benchmarks de tools/debug/f0*.gd).
func _is_bootstrap_managed_report_file(file_name: String) -> bool:
	if file_name == "season_catalog.json" or file_name == "balance_report.json" or file_name == "generation_log.json":
		return true
	return file_name.begins_with("regional_report_")


## Validação da Sprint 18: confere o carregamento dos catálogos de
## AbilityResource e UnitTraitResource, ausência de nomes duplicados, e
## que toda Carta referencia corretamente suas Características (Tier I)
## e Habilidades (Tier III/V) — apenas leitura/validação estrutural,
## nenhuma Habilidade é executada.
## Validação da Sprint 15: monta dois Exércitos de exemplo cobrindo todas
## as Classes estruturais (incluindo Máquina de Guerra, para demonstrar o
## counter estrutural da Posição 3 de À Distância) e executa uma batalha
## completa através de CombatEngine (lógica pura, sem Habilidades).
func _validate_combat_engine() -> void:
	print("[CombatEngine] Validando uma batalha completa (apenas regras estruturais)...")

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A"
	commander_a.faction = "Império"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B"
	commander_b.faction = "Natureza"

	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		_build_combat_card("A-CQC-1", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-CQC-2", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-CQC-3", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("A-Distancia-2", "À Distância", 80, 70, 10),
		_build_combat_card("A-Barreira-1", "Barreira", 50, 120, 60),
		_build_combat_card("A-Barreira-2", "Barreira", 50, 120, 60),
		_build_combat_card("A-Mago", "Mago", 90, 60, 0),
		_build_combat_card("A-Suporte", "Suporte", 30, 80, 10),
	]

	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-CQC-1", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("B-CQC-2", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("B-CQC-3", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("B-Barreira", "Barreira", 50, 120, 60),
		_build_combat_card("B-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("B-Distancia-2", "À Distância", 80, 70, 10),
		_build_combat_card("B-Mago", "Mago", 90, 60, 0),
		_build_combat_card("B-Suporte", "Suporte", 30, 80, 10),
		_build_combat_card("B-MdG", "Máquina de Guerra", 150, 200, 50),
	]

	print("  Exército A pronto para batalha: %s" % ("sim" if army_a.is_ready_for_battle() else "não"))
	print("  Exército B pronto para batalha: %s" % ("sim" if army_b.is_ready_for_battle() else "não"))

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)

	_combat_event_counts.clear()
	_combat_context_errors.clear()
	for event_type: CombatEventType.Type in CombatEventType.Type.values():
		state.event_bus.subscribe(event_type, _on_combat_event_test_listener)

	CombatEngine.run(state)

	for line: String in state.battle_log:
		print("  " + line)

	print("[CombatEventBus] Contagem de eventos recebidos pelo ouvinte de teste:")
	for event_type: CombatEventType.Type in CombatEventType.Type.values():
		print("  %s: %d" % [CombatEventType.Type.keys()[event_type], _combat_event_counts.get(event_type, 0)])

	if _combat_context_errors.is_empty():
		print("[CombatEventBus] Todos os CombatContext recebidos continham as informações esperadas.")
	else:
		print("[CombatEventBus] Inconsistências de contexto encontradas:")
		for error: String in _combat_context_errors:
			print("  " + error)

	print("[CombatEngine] Batalha concluída em %d turno(s). Motivo: %s. Vencedor: %s" % [
		state.turn,
		state.end_reason,
		("empate" if state.winner_side == -1 else "Lado %d" % state.winner_side)
	])


## Ouvinte de teste temporário (Sprint 16) — apenas confirma que a
## infraestrutura de eventos funciona. Nenhuma regra de jogo é executada
## aqui: apenas contagem e verificação estrutural do contexto recebido.
var _combat_event_counts: Dictionary = {}
var _combat_context_errors: Array[String] = []


func _on_combat_event_test_listener(event_type: CombatEventType.Type, context: CombatContext) -> void:
	_combat_event_counts[event_type] = _combat_event_counts.get(event_type, 0) + 1

	var type_name: String = CombatEventType.Type.keys()[event_type]
	BattleLogger.trace("Evento", "%s (Turno %d)" % [type_name, context.turn])

	match event_type:
		CombatEventType.Type.BEFORE_ATTACK, CombatEventType.Type.AFTER_ATTACK, \
		CombatEventType.Type.BEFORE_DAMAGE, CombatEventType.Type.AFTER_DAMAGE_DEALT, CombatEventType.Type.AFTER_DAMAGE_TAKEN:
			if context.attacker == null:
				_combat_context_errors.append("%s sem 'attacker' no contexto." % type_name)
		CombatEventType.Type.UNIT_DIED, CombatEventType.Type.UNIT_MOVED:
			if context.attacker == null or context.position == -1:
				_combat_context_errors.append("%s sem 'attacker'/'position' no contexto." % type_name)
		CombatEventType.Type.AFTER_HEAL_PERFORMED, CombatEventType.Type.AFTER_HEAL_RECEIVED:
			if context.target == null:
				_combat_context_errors.append("%s sem 'target' no contexto." % type_name)


## Cria uma carta transitória (não persistida no catálogo) para validação
## do Motor de Combate, com atributos de combate explícitos.
func _build_combat_card(card_name_value: String, card_class: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.card_class = card_class
	card.faction = "Império"
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card


## Validação da Sprint 24: monta um cenário misturando cartas reais do
## catálogo (Ceifadora Espectral -> Ataque em Área; Ent Jovem -> Campo de
## Força; Carvalho Ancião -> Sobrevivência) com cartas transitórias para
## as Habilidades ainda não referenciadas por nenhuma carta real
## (Ataque Duplo, Perfuração, Contra-ataque, Silêncio), executa uma
## batalha completa e imprime o history_log. Cada Runtime imprime sua própria
## ativação — a evidência de "cenário reproduzível" é o próprio history_log.
func _validate_advanced_abilities() -> void:
	print("[AdvancedAbilities] Validando Habilidades Avançadas (Sprint 24)...")

	var real_ceifadora: CardResource = GameDatabase.get_card("Ceifadora Espectral")
	var real_ent_jovem: CardResource = GameDatabase.get_card("Ent Jovem")
	var real_carvalho: CardResource = GameDatabase.get_card("Carvalho Ancião")

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Habilidades Avançadas)"
	commander_a.faction = "Império"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Habilidades Avançadas)"
	commander_b.faction = "Natureza"

	var card_ataque_duplo := _build_combat_card("A-AtaqueDuplo", "Corpo a Corpo", 80, 100, 0)
	card_ataque_duplo.tier_5_ability_name = "Ataque Duplo"

	var card_perfuracao := _build_combat_card("A-Perfuracao", "Barreira", 50, 100, 50)
	card_perfuracao.tier_5_ability_name = "Perfuração"

	var card_contra_ataque := _build_combat_card("A-ContraAtaque", "Corpo a Corpo", 70, 100, 0)
	card_contra_ataque.tier_5_ability_name = "Contra-ataque"

	var card_silencio := _build_combat_card("A-Silencio", "Mago", 60, 80, 0)
	card_silencio.tier_5_ability_name = "Silêncio"

	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		card_ataque_duplo,
		card_perfuracao,
		card_contra_ataque,
		card_silencio,
		real_ceifadora,
		real_ent_jovem,
		real_carvalho,
		_build_combat_card("A-Filler-8", "Corpo a Corpo", 1, 60, 0),
		_build_combat_card("A-Filler-9", "Corpo a Corpo", 1, 60, 0),
	]

	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-CQC-1", "Corpo a Corpo", 90, 100, 0),
		_build_combat_card("B-Barreira-1", "Barreira", 60, 100, 40),
		_build_combat_card("B-CQC-2", "Corpo a Corpo", 90, 100, 0),
		_build_combat_card("B-Mago-1", "Mago", 70, 80, 0),
		_build_combat_card("B-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("B-Mago-2", "Mago", 70, 80, 0),
		_build_combat_card("B-Barreira-2", "Barreira", 60, 100, 40),
		_build_combat_card("B-Filler-8", "Corpo a Corpo", 1, 60, 0),
		_build_combat_card("B-Filler-9", "Corpo a Corpo", 1, 60, 0),
	]

	print("  Exército A pronto: %s | Exército B pronto: %s" % [
		"sim" if army_a.is_ready_for_battle() else "não",
		"sim" if army_b.is_ready_for_battle() else "não"
	])

	var state: CombatState = CombatEngine.run_battle(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	for line: String in state.battle_log:
		print("  " + line)

	print("[AdvancedAbilities] Batalha concluída em %d turno(s). Motivo: %s. Vencedor: %s" % [
		state.turn, state.end_reason, ("empate" if state.winner_side == -1 else "Lado %d" % state.winner_side)
	])
	print("[AdvancedAbilities] Verifique acima as linhas [BonusAttackRuntime], [DefensiveModifierRuntime],")
	print("  [AreaAttackRuntime] e [SilencioRuntime] — cada uma confirma a ativação da Habilidade correspondente.")
	print("[AdvancedAbilities] 'Provocar' não foi implementada nesta Sprint — ver limitação arquitetural na entrega.")


## --- Helpers de teste da Sprint 29 (Campanha PvE — esqueleto) ---
## Agora vivem em tests/campaign_test_fixtures.gd (CampaignTestFixtures).


## Validação da Sprint 29: Squad — prioridade correta e troca de
## Exército, sem nenhuma lógica de combate.


## Validação da Sprint 12: simula um exército do Império acumulando
## pelotões da mesma Facção, imprimindo cada transição de Nível de
## Afinidade e os efeitos ativos no Nível máximo atingido, utilizando
## exclusivamente Affinity (lógica pura).
## Validação da Sprint 11: confere o catálogo de Campos de Batalha
## carregado e a distribuição aproximada do sorteio ponderado (Battlefield),
## comparando com as Frequências oficiais de BATTLEFIELDS.md.
func _validate_battlefields() -> void:
	print("[Battlefield] Catálogo de Campos de Batalha carregado:")
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		print("  %s | Categoria: %s | Frequência: %d%%" % [
			battlefield.battlefield_name, battlefield.category, int(battlefield.frequency_percent)
		])

	const SAMPLE_SIZE: int = 20000
	var occurrences: Dictionary = {}
	for i in range(SAMPLE_SIZE):
		var drawn: BattlefieldResource = Battlefield.draw(GameDatabase.battlefields)
		occurrences[drawn.battlefield_name] = occurrences.get(drawn.battlefield_name, 0) + 1

	print("[Battlefield] Distribuição observada em %d sorteios (esperado vs. observado):" % SAMPLE_SIZE)
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		var observed_percent: float = 100.0 * occurrences.get(battlefield.battlefield_name, 0) / SAMPLE_SIZE
		print("  %s | Esperado: %d%% | Observado: %.1f%%" % [
			battlefield.battlefield_name, int(battlefield.frequency_percent), observed_percent
		])


## Validação da Sprint 6: simula um comandante acumulando XP através de
## vitórias sucessivas no PvP (Liga Ouro) e imprime cada promoção de
## Patente, utilizando exclusivamente CommanderCareer (lógica pura).
func _validate_commander_career() -> void:
	var commander: CommanderResource = null
	for c: CommanderResource in GameDatabase.commanders:
		if c.commander_name == "Marcus Valerius":
			commander = c
			break

	if commander == null:
		push_warning("[Bootstrap] Comandante de validação da Carreira Militar não foi encontrado no GameDatabase.")
		return

	print("[CommanderCareer] Validando progressão de carreira de '%s'..." % commander.commander_name)

	var previous_patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	print("  Patente inicial: %s (XP acumulado: %d)" % [previous_patente, commander.accumulated_xp])

	var victory_xp: int = CommanderCareer.xp_for_pvp_victory("Ouro")
	while previous_patente != "Lorde-Comandante":
		CommanderCareer.add_xp(commander, victory_xp)
		var current_patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		if current_patente != previous_patente:
			print("  Promovido a %s (XP acumulado: %d)" % [current_patente, commander.accumulated_xp])
			previous_patente = current_patente


## Validação da Sprint 5: gera uma Doutrina Militar completa através do
## Fluxo Oficial de Geração (CommanderGenerator) e imprime o resultado.
func _validate_commander_generation() -> void:
	var doctrine: CommanderDoctrine = CommanderGenerator.generate(
		GameDatabase.commander_restrictions,
		GameDatabase.commander_requirements,
		GameDatabase.commander_targets,
		GameDatabase.commander_effects,
		GameDatabase.commander_values,
	)

	print("[CommanderGenerator] Doutrina Militar gerada:")
	print("  Facção: %s" % doctrine.faction)
	print("  Restrição: %s" % doctrine.restriction_description())
	print("  Requisito: %s" % doctrine.requirement_description())
	print("  Alvo: %s" % doctrine.target.description)
	print("  Efeito: %s" % doctrine.effect.description)
	print("  Valor: %s" % doctrine.value_description())
	print("  Rarity Score: %d (métrica interna; conversão em Raridade Final pendente de balanceamento futuro)" % doctrine.rarity_score)


## Validação do Relógio do Jogo: confirma que o autoload está ativo e
## que now_unix() avança de fato com a passagem do tempo real. Nenhuma
## regra de gameplay é validada aqui — apenas a existência e o
## funcionamento do contador em si.
func _validate_game_clock() -> void:
	print("[GameClock] Validando o contador de tempo real...")

	var first_reading: int = GameClock.now_unix()
	print("  Leitura atual (Unix Timestamp): %d" % first_reading)

	await get_tree().create_timer(1.1).timeout

	var second_reading: int = GameClock.now_unix()
	print("  Leitura após ~1s: %d | Avançou? %s (esperado: true)" % [
		second_reading, str(second_reading > first_reading)
	])


## Validação do motor do Ciclo de Mineração: gerador de permutações
## (tamanhos pequenos, rápido), fórmula da Eficiência (média ponderada)
## e o motor real (CombatEngine) com um subconjunto pequeno de
## permutações — nunca as 362.880 completas dentro do boot do jogo.
func _validate_mining_cycle_engine() -> void:
	print("[Minas] Validando motor do Ciclo de Mineração (permutações, eficiência, CombatEngine)...")

	# Gerador de permutações: contagem e unicidade, com tamanhos pequenos.
	var perms_3: Array = MiningPermutations.generate_all([1, 2, 3])
	print("  Permutações de 3 itens: %d (esperado: 6, 3! = 6)" % perms_3.size())

	var perms_4: Array = MiningPermutations.generate_all(["a", "b", "c", "d"])
	var unique_perms_4: Dictionary = {}
	for p: Array in perms_4:
		unique_perms_4[str(p)] = true
	print("  Permutações de 4 itens: %d (esperado: 24) | todas únicas? %s (esperado: true)" % [
		perms_4.size(), str(unique_perms_4.size() == 24)
	])

	# Fórmula da Eficiência: média ponderada (Vitória=100%, Empate=50%, Derrota=20%).
	var eff: float = MiningCycleResolver.weighted_efficiency(70, 20, 10, 100)
	print("  Eficiência (70%% V / 20%% E / 10%% D) = %.2f%% (esperado: 82.00%%)" % (eff * 100.0))

	# Motor real: Guarnição forte, numa formação fixa vencedora (Campeão
	# na Posição 1 — única posição em que esta fixture derrota o
	# adversário de teste), vs. a Formação de Referência variando 3
	# posições de exemplo em vez das 362.880 completas.
	var guarnicao: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	var reference: Army = CampaignTestFixtures.build_campaign_enemy_army()

	var guarnicao_fixed_cards: Array[CardResource] = guarnicao.cards.duplicate()
	guarnicao_fixed_cards.reverse()  # Campeão na Posição 1: formação fixa vencedora da Guarnição

	var reference_sample_permutations: Array = [
		reference.cards, reference.cards.duplicate(), reference.cards.duplicate()
	]

	var batch_result: Dictionary = MiningEfficiencyEstimator.run_batch(
		guarnicao.commander, guarnicao_fixed_cards, reference_sample_permutations, reference.commander,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, 1
	)
	var total_battles: int = batch_result["wins"] + batch_result["ties"] + batch_result["losses"]
	var efficiency: float = MiningCycleResolver.weighted_efficiency(batch_result["wins"], batch_result["ties"], batch_result["losses"], total_battles)
	print("  Guarnição fixa (Campeão na Posição 1) vs. 3 posições da Referência -> V:%d E:%d D:%d | Eficiência: %.0f%% (esperado: 3, 0, 0, 100%%)" % [
		batch_result["wins"], batch_result["ties"], batch_result["losses"], efficiency * 100.0
	])

	# Estado do Ciclo na Mina (início, duração de ~100h, congelamento).
	var mina := Mina.new(500, "Natureza")
	var now: int = GameClock.now_unix()
	print("  Antes de iniciar -> ciclo ativo? %s (esperado: false)" % str(mina.is_cycle_active(now)))

	mina.start_cycle(now, efficiency)
	print("  Logo após iniciar -> ciclo ativo? %s (esperado: true) | Eficiência congelada: %.0f%%" % [
		str(mina.is_cycle_active(now)), mina.cycle_efficiency * 100.0
	])

	var almost_100h_later: int = now + Mina.CYCLE_DURATION_SECONDS - 1
	print("  A 1s do fim das ~100h -> ciclo ainda ativo? %s (esperado: true)" % str(mina.is_cycle_active(almost_100h_later)))

	var past_100h: int = now + Mina.CYCLE_DURATION_SECONDS + 1
	print("  Passadas as ~100h -> ciclo expirou? %s (esperado: true, is_cycle_active=false)" % str(not mina.is_cycle_active(past_100h)))


## Validação FUNCIONAL (não visual — sem tela, roda headless) da
## janela de Comandantes: instancia a cena de verdade, confirma que a
## árvore de UI monta sem erro, reage a uma promoção de verdade, e
## atualiza o texto exibido corretamente. Não substitui abrir no
## Editor gráfico pra conferir o layout — só garante que a lógica por
## trás da tela está correta.
func _validate_comandantes_panel_ui() -> void:
	print("[UI] Validando ComandantesPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom

	var test_commander := CommanderResource.new()
	test_commander.commander_name = "UI Teste RG Único 999888"
	kingdom.add_commander(test_commander, GameClock.now_unix())
	kingdom.add_generation_points(10)

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/comandantes_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)

	var found_in_reserva: bool = _panel_contains_text(panel, "UI Teste RG Único 999888")
	print("  Painel montou e o Comandante de teste aparece na Reserva? %s (esperado: true)" % str(found_in_reserva))

	# F-009: o rótulo do Candidato do Centro de Recrutamento não deve
	# repetir a Facção duas vezes ("Comandante Gerado (Natureza)
	# (Natureza)") — o nome já vem com a Facção embutida
	# (RecruitmentCenterResolver._generate_candidate()).
	var duplicated_faction_label: bool = (
		_panel_contains_text(panel, "(Império) (Império)") or
		_panel_contains_text(panel, "(Natureza) (Natureza)") or
		_panel_contains_text(panel, "(Mortos-Vivos) (Mortos-Vivos)")
	)
	print("  Rótulo do Candidato do Centro de Recrutamento NÃO repete a Facção? %s (esperado: true, F-009)" % str(not duplicated_faction_label))

	# Garante Cargo Ativo disponível de verdade, não importa o que os
	# testes anteriores já deixaram no KingdomState.kingdom compartilhado
	# (ativa repetidamente até sobrar capacidade, ou desistir depois de
	# um limite alto o suficiente pra nunca acontecer de verdade).
	var active_now: int = 0
	for c: CommanderResource in kingdom.commanders:
		if c.administrative_state == CommanderResource.AdministrativeState.ACTIVE:
			active_now += 1
	var attempts: int = 0
	while CommandCenterProgress.effective_cargo_ativo(kingdom) <= active_now and attempts < 50:
		kingdom.add_generation_points(10)
		panel._on_activate_next_pressed()
		attempts += 1

	panel._on_promote_pressed(test_commander)

	var moved_to_ativos: bool = _panel_contains_text(panel, "UI Teste RG Único 999888") and test_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE
	print("  Após promover -> Estado real do Comandante: %s | ainda aparece na tela (agora em Ativos)? %s (esperado: ACTIVE, true)" % [
		CommanderResource.AdministrativeState.keys()[test_commander.administrative_state], str(moved_to_ativos)
	])

	panel.queue_free()


## Busca recursiva por um texto em qualquer Label dentro da árvore do
## painel — forma simples de inspecionar o que "estaria na tela" sem
## renderização de verdade.
func _panel_contains_text(node: Node, text: String) -> bool:
	if node is Label and text in (node as Label).text:
		return true
	if node is Button and text in (node as Button).text:
		return true
	for child in node.get_children():
		if _panel_contains_text(child, text):
			return true
	return false


## Acha o primeiro Button real na árvore cujo texto contém "text" —
## usado pra testes que emitem o sinal "pressed" de verdade (via
## button.emit_signal), não chamando a função do handler direto. Só
## um clique de verdade passa pela máquina de sinais do próprio Godot
## (respeitando CONNECT_DEFERRED) — chamar a função direto nunca
## testou isso de verdade, foi assim que o crash real passou batido.
## Igual _find_button_by_text, mas exige o texto EXATO — necessário
## quando o texto normal e uma variação dele (ex: "Desfazer" vs
## "Desfazer (travado: ...)") podem coexistir na mesma tela.
func _find_button_by_exact_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button_by_exact_text(child, text)
		if found != null:
			return found
	return null


func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and text in (node as Button).text:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button_by_text(child, text)
		if found != null:
			return found
	return null


## Validação FUNCIONAL (sem renderização) da janela de Treinamento:
## envia um Comandante da Reserva, confirma que aparece Em
## Treinamento, avança o tempo em GameRuntime.sync() e confirma que a
## tela reflete a XP acumulada de verdade.
func _validate_treinamento_panel_ui() -> void:
	print("[UI] Validando TreinamentoPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.command_center_level = maxi(kingdom.command_center_level, 3)  # garante ao menos 1 Vaga de Treinamento

	var test_commander := CommanderResource.new()
	test_commander.commander_name = "UI Treinamento Teste RG 777666"
	kingdom.add_commander(test_commander, GameClock.now_unix())

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/treinamento_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)

	var found_in_reserva_list: bool = _panel_contains_text(panel, "UI Treinamento Teste RG 777666")
	print("  Painel montou e o Comandante de teste aparece pra enviar? %s (esperado: true)" % str(found_in_reserva_list))

	panel._on_send_to_training_pressed(test_commander)
	var moved_to_training: bool = test_commander.administrative_state == CommanderResource.AdministrativeState.TRAINING \
		and _panel_contains_text(panel, "UI Treinamento Teste RG 777666")
	print("  Após enviar -> Estado real: %s | aparece Em Treinamento na tela? %s (esperado: TRAINING, true)" % [
		CommanderResource.AdministrativeState.keys()[test_commander.administrative_state], str(moved_to_training)
	])

	# Concede XP de combate real a outro Comandante (Ativo, fora do
	# Treinamento) pra gerar uma Média Diária não-zero, avança 1 dia, e
	# confirma que a tela mostra a XP creditada de verdade.
	var active_commander := CommanderResource.new()
	active_commander.commander_name = "UI Treinamento Ativo Teste"
	kingdom.add_commander(active_commander, GameClock.now_unix())
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander, 20, GameClock.now_unix())

	var day_later: int = GameClock.now_unix() + 86400 + 1
	GameRuntime.sync(kingdom, day_later)
	panel.refresh()
	print("  Após 1 dia com XP de combate real -> XP do ciclo do Comandante em Treinamento: %d (esperado: > 0) | Média Diária exibida: %d" % [
		test_commander.training_accumulated_xp, kingdom.last_daily_average_xp
	])
	print("  Tela mostra a XP do ciclo atualizada? %s (esperado: true)" % str(
		_panel_contains_text(panel, "XP do ciclo: %d" % test_commander.training_accumulated_xp)
	))

	panel.queue_free()


## Validação FUNCIONAL (sem renderização) da janela de Legado: um
## Recruta não aparece na lista de aposentar; um Comandante elegível
## aparece, aposenta de verdade ao "clicar", e some da lista de
## elegíveis e aparece no Hall; a seção de Grande Legado Militar mostra
## a mensagem de bloqueio corretamente com CdC abaixo do Nível 100.
func _validate_legado_panel_ui() -> void:
	print("[UI] Validando LegadoPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.command_center_level = maxi(kingdom.command_center_level, 5)  # desbloqueia Legado I

	var recruit := CommanderResource.new()
	recruit.commander_name = "UI Legado Recruta 777111"
	kingdom.add_commander(recruit, GameClock.now_unix())

	var capitao := CommanderResource.new()
	capitao.commander_name = "UI Legado Capitão 777222"
	capitao.accumulated_xp = 480  # limiar exato de Capitão
	kingdom.add_commander(capitao, GameClock.now_unix())

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/legado_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)

	print("  Recruta (abaixo do mínimo) NÃO aparece na lista de aposentar? %s (esperado: true)" % str(
		not _panel_contains_text(panel, "UI Legado Recruta 777111")
	))
	print("  Capitão (elegível) aparece na lista de aposentar? %s (esperado: true)" % str(
		_panel_contains_text(panel, "UI Legado Capitão 777222")
	))

	if kingdom.command_center_level < LegacyResolver.GRANDE_LEGADO_CDC_LEVEL:
		print("  Grande Legado Militar mostra a mensagem de bloqueio? %s (esperado: true)" % str(
			_panel_contains_text(panel, "Bloqueado")
		))

	panel._on_retire_administrative_pressed(capitao)

	print("  Após aposentar -> Estado real: %s | Sumiu da lista de elegíveis? %s | Apareceu no Hall? %s (esperado: RETIRED, true, true)" % [
		CommanderResource.AdministrativeState.keys()[capitao.administrative_state],
		str(not _panel_contains_text(panel, "UI Legado Capitão 777222 | Capitão")),
		str(_panel_contains_text(panel, "UI Legado Capitão 777222"))
	])

	panel.queue_free()


## Validação FUNCIONAL (sem renderização) da janela de Minas: monta
## Guarnição, inicia um Ciclo (com uma amostra pequena de permutações —
## nunca as 362.880 reais aqui, ver aviso de performance no
## minas_panel.gd) e confirma os dois modos de Renovação usando o
## motor de tempo real (GameRuntime.sync()): Automática reinicia o
## Ciclo sozinha sem liberar a Guarnição; Manual libera normalmente.
## Validação FUNCIONAL do bug real relatado: um Reino novo de verdade
## precisa ter as 3 Minas Iniciais desde o início (agora chamado
## dentro de KingdomState.initialize_new_kingdom() — antes só existia
## nos meus testes, nunca no fluxo real do jogo; jogador real via
## sempre "Nenhuma Mina conquistada ainda.").
## Validação FUNCIONAL de Kingdom.form_army() gerando as 5 Formações
## automaticamente (ARMY.md), mesmo num fluxo de 1 Formação só. A
## computação dos 4 Arquétipos de Formação em si (β, γ, δ, ε, via
## ArmyFormationArchetypes.generate_all()) foi migrada para
## test_army_formation_archetypes.gd (Etapa 15) — as 9 CardResource de
## teste continuam construídas aqui porque este trecho (que lê
## KingdomState.kingdom, estado global, fora do escopo da migração)
## ainda depende delas para montar o Exército de verdade via form_army().
func _validate_army_formation_archetypes() -> void:
	print("[Exército] Validando form_army() gerar as 5 Formações automaticamente...")

	var cards: Array[CardResource] = []
	var cqc_low := CardResource.new()
	cqc_low.card_name = "CQC Fraco"; cqc_low.card_class = "Corpo a Corpo"; cqc_low.faction = "Império"; cqc_low.rarity = "Comum"; cqc_low.tier = 1; cqc_low.atk = 50; cqc_low.hp = 100; cqc_low.esc = 10
	var cqc_high := CardResource.new()
	cqc_high.card_name = "CQC Forte"; cqc_high.card_class = "Corpo a Corpo"; cqc_high.faction = "Império"; cqc_high.rarity = "Comum"; cqc_high.tier = 1; cqc_high.atk = 300; cqc_high.hp = 100; cqc_high.esc = 10
	var barreira_low := CardResource.new()
	barreira_low.card_name = "Barreira Fraca"; barreira_low.card_class = "Barreira"; barreira_low.faction = "Império"; barreira_low.rarity = "Comum"; barreira_low.tier = 1; barreira_low.atk = 40; barreira_low.hp = 100; barreira_low.esc = 50
	var barreira_high := CardResource.new()
	barreira_high.card_name = "Barreira Forte"; barreira_high.card_class = "Barreira"; barreira_high.faction = "Império"; barreira_high.rarity = "Comum"; barreira_high.tier = 1; barreira_high.atk = 40; barreira_high.hp = 100; barreira_high.esc = 200
	var ranged_1 := CardResource.new()
	ranged_1.card_name = "Arqueiro 1"; ranged_1.card_class = "À Distância"; ranged_1.faction = "Império"; ranged_1.rarity = "Comum"; ranged_1.tier = 1; ranged_1.atk = 90; ranged_1.hp = 60; ranged_1.esc = 15
	var ranged_2 := CardResource.new()
	ranged_2.card_name = "Arqueiro 2"; ranged_2.card_class = "À Distância"; ranged_2.faction = "Império"; ranged_2.rarity = "Comum"; ranged_2.tier = 1; ranged_2.atk = 90; ranged_2.hp = 60; ranged_2.esc = 15
	var mago := CardResource.new()
	mago.card_name = "Mago"; mago.card_class = "Mago"; mago.faction = "Império"; mago.rarity = "Comum"; mago.tier = 1; mago.atk = 120; mago.hp = 70; mago.esc = 10
	var suporte := CardResource.new()
	suporte.card_name = "Suporte"; suporte.card_class = "Suporte"; suporte.faction = "Império"; suporte.rarity = "Comum"; suporte.tier = 1; suporte.atk = 60; suporte.hp = 90; suporte.esc = 10
	var maquina := CardResource.new()
	maquina.card_name = "Máquina"; maquina.card_class = "Máquina de Guerra"; maquina.faction = "Império"; maquina.rarity = "Comum"; maquina.tier = 1; maquina.atk = 70; maquina.hp = 80; maquina.esc = 50
	cards = [cqc_low, cqc_high, barreira_low, barreira_high, ranged_1, ranged_2, mago, suporte, maquina]

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Arquétipos)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var owned_cards: Array[CardResource] = []
	for card: CardResource in cards:
		owned_cards.append(kingdom.acquire_card_from_catalog(card))
	var army: Army = kingdom.form_army(commander, owned_cards)
	print("  form_army() já popula β-ε de verdade, sem precisar do Editor de 5 abas? %s (%d Formações extras, esperado: true, 4)" % [
		str(army.formations.size() == 4), army.formations.size()
	])


## Validação FUNCIONAL do modo de edição de Formações de um Exército
## JÁ EXISTENTE (existing_army) — pula a Fase 1, nunca desfaz o
## Exército ao cancelar, edita de verdade.
func _validate_army_editor_existing_army_mode() -> void:
	print("[Exército] Validando o modo de edição de Formações de um Exército já existente...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Editar Formação)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var owned_cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		owned_cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, owned_cards)
	var beta_before: Array = army.formations["β"].duplicate()

	var editor: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	editor.existing_army = army
	add_child(editor)

	print("  Modo de edição pula a Fase 1 (Comandante/Cartas escondidos) e já mostra as Formações? %s (esperado: true)" % str(
		not editor._commander_option.visible and editor._formations_section.visible
	))
	print("  As Formações carregadas batem com as do Exército de verdade (não reinventa nada)? %s (esperado: true)" % str(
		editor._formation_cards["β"] == beta_before
	))

	# Trocar 2 cartas de posição na Formação atual e Confirmar.
	editor._on_slot_card_selected(1, 0)
	editor._on_concluir_pressed()
	print("  Confirmar edição realmente altera a Formação do Exército de verdade? %s (esperado: true)" % str(
		army.cards[0] != owned_cards[0] or army.cards[1] != owned_cards[1]
	))
	print("  O Exército continua existindo (não foi desfeito por engano)? %s (esperado: true)" % str(
		kingdom.armies.has(army)
	))
	editor.queue_free()
	await get_tree().process_frame

	# --- Cancelar no modo de edição NUNCA desfaz o Exército ---
	var editor_2: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	editor_2.existing_army = army
	add_child(editor_2)
	editor_2._on_cancel_pressed()
	print("  Cancelar a edição de Formação NUNCA desfaz o Exército? %s (esperado: true)" % str(
		kingdom.armies.has(army) and commander.ownership_status == CommanderResource.OwnershipStatus.EM_EXERCITO
	))
	editor_2.queue_free()
	await get_tree().process_frame


## Validação FUNCIONAL do bug real relatado: vencer uma Fase de PvE de
## verdade (ExpeditionRuntime, não RewardResolver chamado direto) devia
## creditar Fragmentos — RewardResolver existia, testado, mas nunca
## era chamado fora dos meus testes.
func _validate_pve_credits_fragments_for_real() -> void:
	print("[PvE] Validando que vencer uma Fase de verdade credita Fragmentos (bug relatado)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var fragments_before: int = kingdom.get_fragment("Império")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var territory := Territory.new("Territorio-Teste-Fragmentos", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var runtime := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 778,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	runtime.attempt_current_fase()

	var fragments_after: int = kingdom.get_fragment("Império")
	print("  Vencer uma Fase de verdade (ExpeditionRuntime.attempt_current_fase) credita Fragmentos de verdade? %s (%d -> %d, esperado: aumentou)" % [
		str(fragments_after > fragments_before), fragments_before, fragments_after
	])


## Validação FUNCIONAL do botão [DEBUG] Gerar Candidato Agora — deve
## produzir um Candidato de verdade na hora, sem precisar de 24h reais.
func _validate_debug_generate_candidate_button() -> void:
	print("[Comandantes] Validando o botão [DEBUG] Gerar Candidato Agora...")

	var fresh_kingdom := Kingdom.new()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_kingdom

	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)

	var slot_before: CommanderResource = fresh_kingdom.recruitment_center_slots[0] if not fresh_kingdom.recruitment_center_slots.is_empty() else null
	panel._on_debug_generate_candidate_pressed()
	var slot_after: CommanderResource = fresh_kingdom.recruitment_center_slots[0] if not fresh_kingdom.recruitment_center_slots.is_empty() else null

	print("  Botão gera um Candidato de verdade na hora, sem esperar 24h? %s (esperado: true)" % str(
		slot_after != null and slot_after != slot_before
	))
	print("  O Candidato já tem Doutrina de verdade (Restrição/Requisito/Efeito)? %s (esperado: true)" % str(
		slot_after != null and slot_after.doctrine != null
	))
	panel.queue_free()
	KingdomState.kingdom = old_kingdom


## Validação FUNCIONAL do bug real relatado: um Exército ficou preso
## com pouca Energia por mais de 1h real parado na tela da Cidade,
## sem recuperar — porque CityPanel nunca chamava GameRuntime.sync().
## Agora sincroniza periodicamente via _process(), mesmo sem o
## jogador clicar em nada.
func _validate_city_panel_syncs_periodically() -> void:
	print("[Cidade] Validando que a tela principal sincroniza o tempo real sozinha (bug relatado)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Sync Cidade)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)
	army.consume_energy(army.max_energy - 2)  # deixa só 2, igual ao cenário relatado
	kingdom.starter_kit_used = true  # simula um jogador que já passou do Kit Inicial (tem Exército, está na Cidade normal) — meu _process() de propósito não sincroniza antes disso
	# _process() usa o relógio real de verdade (GameClock.now_unix())
	# pra chamar GameRuntime.sync() — não dá pra simular "1h se
	# passando" só chamando _process() várias vezes rápido (delta não
	# afeta a conta de recuperação, só decide QUANDO sincronizar).
	# Recuo a referência do próprio Exército, igual já fiz no teste de
	# energia isolado — assim, quando _process() sincronizar de
	# verdade com o relógio real atual, o intervalo já vai refletir
	# "mais de 1h se passou".
	army.last_energy_sync_unix = GameClock.now_unix() - 3700

	var panel: Control = load("res://scenes/city/city_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	# Chama _process() com deltas somando mais que o intervalo
	# configurado (5s) — só pra cruzar o limiar que dispara o sync().
	for i in range(3):
		panel._process(2.0)

	print("  Depois de tempo real passando parado na Cidade (sem clicar em nada) -> Energia recuperou de verdade? %s (%d/%d, esperado: > 2)" % [
		str(army.current_energy > 2), army.current_energy, army.max_energy
	])
	panel.queue_free()
	await get_tree().process_frame


## Validação FUNCIONAL: Mina Inicial mostra geração/hora real em vez
## de "Eficiência: 100%%" (informação redundante, sempre a mesma).
func _validate_initial_mine_shows_production_rate() -> void:
	print("[Minas] Validando que a Mina Inicial mostra geração/hora, não Eficiência...")

	var fresh_kingdom := Kingdom.new()
	fresh_kingdom.create_initial_mines()
	var mina: Mina = fresh_kingdom.initial_mines[0]
	mina.start_cycle(GameClock.now_unix(), 1.0)

	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_kingdom
	var panel: Control = load("res://scenes/command_center/panels/minas_panel.tscn").instantiate()
	add_child(panel)

	var expected_rate: int = MineEconomy.base_production_for_mina(mina)
	print("  Mostra '%d por hora' de verdade, sem falar em Eficiência? %s (esperado: true)" % [
		expected_rate, str(_panel_contains_text(panel, "%d de" % expected_rate) and not _panel_contains_text(panel, "Eficiência"))
	])
	panel.queue_free()
	KingdomState.kingdom = old_kingdom


## Validação FUNCIONAL dos filtros de produção na Academia.
func _validate_academia_production_filters() -> void:
	print("[Academia] Validando os filtros de produção (Facção/Classe/Raridade)...")

	var panel: Control = load("res://scenes/city/panels/academia_panel.tscn").instantiate()
	add_child(panel)

	var total_before_filter: int = panel._filtered_produce_cards.size()
	panel._produce_filter_faction = "Império"
	panel._refresh_produce_card_options()
	var all_imperio: bool = true
	for card: CardResource in panel._filtered_produce_cards:
		if card.faction != "Império":
			all_imperio = false
	print("  Filtrar por Facção 'Império' -> só mostra Cartas do Império? %s (%d -> %d cartas, esperado: true, diminuiu)" % [
		str(all_imperio and panel._filtered_produce_cards.size() < total_before_filter), total_before_filter, panel._filtered_produce_cards.size()
	])

	panel._produce_filter_rarity = "Rara"
	panel._refresh_produce_card_options()
	var all_rara: bool = true
	for card: CardResource in panel._filtered_produce_cards:
		if card.rarity != "Rara":
			all_rara = false
	print("  Combinar com Raridade 'Rara' -> só mostra Império + Rara? %s (esperado: true)" % str(all_rara))
	panel.queue_free()


## Validação FUNCIONAL do bug real relatado: os Slots vazios do Centro
## de Recrutamento mostravam o mesmo tempo pra todos, ignorando a
## ordem sequencial (COMMAND_CENTER_RECRUITMENT.md, "Geração Sequencial":
## 24h pro 1º, 48h pro 2º, 72h pro 3º).
func _validate_recruitment_slots_show_sequential_time() -> void:
	print("[Comandantes] Validando que os Slots vazios mostram tempo sequencial (bug relatado)...")

	var fresh_kingdom := Kingdom.new()
	fresh_kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix() + 3600  # 1h restante no ciclo atual
	fresh_kingdom.sync_recruitment_center_slots()  # garante os 3 Slots existentes, todos vazios

	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_kingdom
	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)

	var text_dump: String = _dump_all_labels(panel)
	var slot_1_time: int = _extract_slot_time(text_dump, 1)
	var slot_2_time: int = _extract_slot_time(text_dump, 2)
	var slot_3_time: int = _extract_slot_time(text_dump, 3)
	print("  Slot 1: ~%ds | Slot 2: ~%ds | Slot 3: ~%ds -> cada um maior que o anterior por ~1 Ciclo inteiro? %s (esperado: true)" % [
		slot_1_time, slot_2_time, slot_3_time,
		str(slot_2_time > slot_1_time and slot_3_time > slot_2_time and (slot_2_time - slot_1_time) > 3000)
	])
	panel.queue_free()
	KingdomState.kingdom = old_kingdom


func _dump_all_labels(node: Node) -> String:
	var text: String = ""
	if node is Label:
		text += (node as Label).text + "\n"
	for child in node.get_children():
		text += _dump_all_labels(child)
	return text


func _extract_slot_time(text_dump: String, slot_number: int) -> int:
	var marker: String = "Slot %d vazio (próximo em ~" % slot_number
	var start: int = text_dump.find(marker)
	if start == -1:
		return -1
	start += marker.length()
	var end: int = text_dump.find("s)", start)
	return int(text_dump.substr(start, end - start))


## Validação FUNCIONAL do Histórico de Batalhas mostrando o confronto
## 3x3 vs 3x3 real, não só texto.
func _validate_battle_history_shows_formations() -> void:
	print("[Comandantes] Validando que o Histórico de Batalhas mostra o confronto 3x3 vs 3x3...")

	var own_cards: Array[CardResource] = []
	var enemy_cards: Array[CardResource] = []
	for i in range(9):
		var own_card := CardResource.new()
		own_card.card_name = "Aliado %d" % (i + 1)
		own_cards.append(own_card)
		var enemy_card := CardResource.new()
		enemy_card.card_name = "Inimigo %d" % (i + 1)
		enemy_cards.append(enemy_card)

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Histórico Visual)"
	commander.record_battle("Oponente de Teste", "Teste", "Vitória", GameClock.now_unix(), own_cards, enemy_cards)

	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)
	panel._selected_history_commander = commander
	panel._refresh_historico()

	var text_dump: String = _dump_all_labels(panel)
	print("  Mostra as cartas do próprio Exército (ex: 'Aliado 1')? %s | Mostra as do inimigo (ex: 'Inimigo 1')? %s (esperado: true, true)" % [
		str("Aliado 1" in text_dump), str("Inimigo 1" in text_dump)
	])
	panel.queue_free()


## Validação FUNCIONAL do Histórico de Batalhas mostrando o grid 3x3
## vs 3x3 — já estava implementado, confirmando que funciona de
## verdade com uma batalha real registrada.
func _validate_battle_history_shows_formation_grids() -> void:
	print("[Comandantes] Validando que o Histórico mostra o grid 3x3 vs 3x3 (Seu Exército vs Inimigo)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Histórico Grid)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)

	var own_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	own_army.commander = commander
	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()

	commander.record_battle("Inimigo de Teste", "Teste de Histórico", "Vitória", GameClock.now_unix(), own_army.cards, enemy_army.cards)

	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)
	panel._on_view_history_pressed(commander)

	print("  Mostra os rótulos 'Seu Exército' e 'Inimigo' lado a lado? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Seu Exército") and _panel_contains_text(panel, "Inimigo")
	))
	print("  Mostra o nome de verdade de uma carta da Formação (não só o resumo em texto)? %s (esperado: true)" % str(
		_panel_contains_text(panel, own_army.cards[0].card_name)
	))
	panel.queue_free()


## Validação FUNCIONAL da tela de Doutrina do Comandante — nunca tinha
## existido antes, só a lógica testada internamente. Confirma que
## mostra as 5 peças (Restrição/Requisito/Alvo/Efeito/Valor) de
## verdade, com um Comandante gerado de verdade (não sintético).
func _validate_commander_doctrine_screen() -> void:
	print("[Comandantes] Validando a tela de Doutrina do Comandante (nunca existiu antes)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var generated: CommanderResource = RecruitmentCenterResolver._generate_candidate()
	kingdom.add_commander(generated, GameClock.now_unix())

	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)
	panel._on_view_doctrine_pressed(generated)

	print("  Mostra o nome do Comandante e a Facção? %s (esperado: true)" % str(
		_panel_contains_text(panel, generated.commander_name)
	))
	print("  Mostra a descrição real da Restrição sorteada? %s (esperado: true)" % str(
		_panel_contains_text(panel, generated.doctrine.restriction.description)
	))
	print("  Mostra a descrição real do Requisito sorteado? %s (esperado: true)" % str(
		_panel_contains_text(panel, generated.doctrine.requirement.description)
	))
	print("  Mostra a descrição real do Efeito sorteado? %s (esperado: true)" % str(
		_panel_contains_text(panel, generated.doctrine.effect.description)
	))
	panel.queue_free()


## Validação FUNCIONAL da Unicidade de Composição no Editor de
## Exército do jogador — não deixa marcar 2 cópias do mesmo Nome.
func _validate_player_editor_prevents_duplicate_names() -> void:
	print("[Exército] Validando que o Editor do jogador impede 2 cópias do mesmo Nome...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Unicidade)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)

	var template: CardResource = GameDatabase.get_card("Campeão Imperial")
	var copy_1: CardResource = kingdom.acquire_card_from_catalog(template)
	var copy_2: CardResource = kingdom.acquire_card_from_catalog(template)  # mesmo Nome, cópia diferente

	var editor: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	add_child(editor)
	editor._selected_commander = commander
	editor._on_card_toggled(true, copy_1)
	editor._on_card_toggled(true, copy_2)  # tenta marcar a 2ª cópia do MESMO Nome

	print("  A 2ª cópia do mesmo Nome ('Campeão Imperial') foi rejeitada? %s (%d carta(s) selecionada(s), esperado: true, 1)" % [
		str(not editor._selected_cards.has(copy_2)), editor._selected_cards.size()
	])
	editor.queue_free()


## Validação FUNCIONAL do bug real relatado: trocar entre as 3
## Trilhas e depois olhar o Histórico do Comandante — só aparecia
## batalha de Território Império, mesmo trocando várias vezes.
func _validate_switching_trilhas_records_correct_territory() -> void:
	print("[PvE] Validando que trocar de Trilha registra o Território certo no Histórico (bug relatado)...")

	var kingdom: Kingdom = KingdomState.kingdom
	# Não usa WorldBootstrap.ensure_world_loaded() nem
	# WorldDatabase.get_current_season() aqui — outros testes desta
	# mesma suíte já registraram suas próprias Temporadas isoladas
	# (com menos Territórios, só pra teste), e "current season" pode
	# estar apontando pra uma delas neste ponto da execução. Busca
	# direto pela Temporada real de desenvolvimento, gerando de novo
	# se ainda não existir.
	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	if season == null:
		WorldBootstrap._generate_dev_scale_world()
		season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Trocar Trilha)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)
	army.initialize_energy(kingdom.energy_nucleus_level)

	var territory_ids_fought: Array[String] = []
	for territory: Territory in season.territories.values():
		army.recover_energy_full()
		var squad := Squad.new([army])
		var start_result: Dictionary = GameRuntime.start_new_expedition(
			kingdom, season.season_id, territory.id, squad, randi(),
			GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
		)
		# Este loop reaproveita o mesmo Exército entre Territórios sem
		# nunca encerrar a Expedição anterior — o próprio padrão de
		# double-booking que Kingdom.start_expedition() agora rejeita
		# (auditoria PvE, P0 #1). Tornado visível aqui em vez de
		# silencioso: se o Exército ainda estiver travado na Expedição
		# do Território anterior, o registro deste Território é
		# recusado — mas attempt_current_fase() ainda roda sobre a
		# instância construída (nunca null), preservando o
		# comportamento original de sempre gerar uma entrada no
		# Histórico do Comandante para este Território.
		print("    Território %s -> Expedição registrada em kingdom.active_expeditions? %s%s" % [
			territory.id, str(start_result["success"]),
			"" if start_result["success"] else " (motivo: %s)" % start_result["reason"]
		])
		var expedition: ExpeditionRuntime = start_result["expedition"]
		var result: PhaseResult = expedition.attempt_current_fase()

	for entry: Dictionary in commander.battle_log:
		var context: String = entry.get("context", "")
		if not territory_ids_fought.has(context):
			territory_ids_fought.append(context)

	print("  Lutou nas 3 Trilhas -> o Histórico tem contextos DIFERENTES pra cada uma (não só Império repetido)? %s (%d contextos distintos de %d entradas, esperado: 3, 3)" % [
		str(territory_ids_fought.size() == 3), territory_ids_fought.size(), commander.battle_log.size()
	])
	for context: String in territory_ids_fought:
		print("    - %s" % context)


## Validação FUNCIONAL do bug real relatado: vencer uma Fase de PvE de
## verdade devia creditar XP de Conta e XP de Comandante — os dois
## resolvers já existiam, testados, mas nenhum era chamado fora dos
## meus testes (o próprio CommanderTrainingResolver.gd já avisava
## isso no comentário).
func _validate_pve_credits_account_and_commander_xp() -> void:
	print("[PvE] Validando que vencer uma Fase de verdade credita XP de Conta e XP de Comandante (bug relatado)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var account_xp_before: int = kingdom.account_xp

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (XP)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var commander_xp_before: int = commander.accumulated_xp

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.commander = commander
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var territory := Territory.new("Territorio-Teste-XP", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var runtime := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 779,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	runtime.attempt_current_fase()

	print("  XP de Conta aumentou de verdade? %s (%d -> %d)" % [
		str(kingdom.account_xp > account_xp_before), account_xp_before, kingdom.account_xp
	])
	print("  XP do Comandante vencedor aumentou de verdade? %s (%d -> %d, esperado: aumentou %d)" % [
		str(commander.accumulated_xp > commander_xp_before), commander_xp_before, commander.accumulated_xp, CommanderCareer.xp_for_pve_victory()
	])
	print("  O ganho entrou no log diário de XP de Combate (usado pela Média do Treinamento)? %s (esperado: true)" % str(
		kingdom.daily_combat_xp_log.has(str(commander.instance_id))
	))


## Validação FUNCIONAL do bug relatado: verifica a COMPOSIÇÃO REAL de
## cartas do inimigo em cada Território, não só o nome do Comandante
## (que já tinha sido testado antes, mas pode ter escondido um bug
## de verdade na composição em si).
func _validate_enemy_composition_matches_territory_faction() -> void:
	print("[PvE] Validando que a composição de cartas do inimigo bate com a Facção do Território (bug relatado)...")

	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	if season == null:
		WorldBootstrap._generate_dev_scale_world()
		season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)

	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var entry: EnemyArmyEntry = EnemyArmySelector.select(
			season.enemy_catalog, faction, EnemyArmyEntry.Category.NORMAL, 1, 500, 12345, null
		)
		var same_faction_count: int = 0
		for card: CardResource in entry.cards:
			if card.faction == faction:
				same_faction_count += 1
		print("  Território de %s -> Exército inimigo tem 6 cartas dessa Facção (maioria real)? %s (%d/9, esperado: 6)" % [
			faction, str(same_faction_count == 6), same_faction_count
		])


## Validação FUNCIONAL do bug real relatado: quando o Exército falha
## (Energia esgotada ou perde as 5 Formações) sem nunca ter alcançado
## um Acampamento real, ele "volta" pra Fase 1 (equivalente à Cidade)
## mas ficava travado — sem editar, sem recuperar Energia — porque a
## flag que sinaliza "seguro" nunca era marcada nesse caminho.
func _validate_army_unlocks_after_returning_to_camp() -> void:
	print("[PvE] Validando que o Exército destrava e recupera Energia depois de 'voltar' pro Acampamento/Cidade (bug relatado)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Trava PvE)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)
	army.consume_energy(army.max_energy - 2)  # deixa só 2, igual ao print relatado

	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	if season == null:
		WorldBootstrap._generate_dev_scale_world()
		season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	var territory: Territory = season.get_territory("Território de Império")
	var trilha: Trilha = season.get_trilha(territory.id)
	var squad := Squad.new([army])

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, season.enemy_catalog, kingdom.regional_commander_registry, 12345,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	kingdom.active_expeditions.append(expedition)
	expedition.attempt_current_fase()  # Energia insuficiente pra tentativa nenhuma -> falha, "volta" pra Fase 1

	print("  Depois da falha (sem nunca ter alcançado Acampamento real) -> is_waiting_at_acampamento ficou true? %s (esperado: true)" % str(
		expedition.is_waiting_at_acampamento
	))

	var lock: Dictionary = kingdom.is_army_locked_for_editing(army)
	print("  Exército destravado pra editar de verdade? %s (esperado: false — não deveria estar travado)" % str(lock["locked"])
	)

	var energy_before: int = army.current_energy
	army.last_energy_sync_unix = GameClock.now_unix() - 3700  # simula 1h+ real se passando
	GameRuntime.sync(kingdom, GameClock.now_unix())
	print("  Energia recupera de verdade nesse estado? %s (%d -> %d, esperado: aumentou)" % [
		str(army.current_energy > energy_before), energy_before, army.current_energy
	])


## Validação FUNCIONAL do P0 identificado na auditoria de Expedição: um
## Exército já comprometido numa Expedição em andamento (travado por
## Kingdom.is_army_locked_for_editing()) não pode ser designado a uma
## segunda Expedição — nem via Kingdom.start_expedition() (ponto
## central de entrada), nem via GameRuntime.start_new_expedition() (o
## outro chamador de start_expedition() — precisa propagar a rejeição,
## nunca devolver uma ExpeditionRuntime não registrada como se fosse
## válida, Finding A da revisão da auditoria), nem via PvEPanel (fluxo
## real de "Iniciar Nova Expedição"). Antes da correção, nada impedia o
## mesmo Army (mesma referência) de acabar em dois Squad.armies
## simultâneos.
func _validate_army_cannot_be_double_booked() -> void:
	print("[PvE] Validando que um Exército travado em Expedição não pode ser designado a uma segunda (P0 da auditoria)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Double-Booking)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	if season == null:
		WorldBootstrap._generate_dev_scale_world()
		season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	var territory: Territory = season.get_territory("Território de Império")
	var trilha: Trilha = season.get_trilha(territory.id)

	# --- Camada de domínio: Kingdom.start_expedition() ---
	var squad_a := Squad.new([army])
	var expedition_a := ExpeditionRuntime.new(
		squad_a, trilha, territory, season.enemy_catalog, kingdom.regional_commander_registry, 555001,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var result_a: Dictionary = kingdom.start_expedition(expedition_a)
	print("  1ª Expedição (Exército livre) -> aceita? %s (esperado: true)" % str(result_a["success"]))
	print("  Exército travado depois de entrar em Expedição? %s (esperado: true)" % str(
		kingdom.is_army_locked_for_editing(army)["locked"]
	))

	var squad_b := Squad.new([army])
	var expedition_b := ExpeditionRuntime.new(
		squad_b, trilha, territory, season.enemy_catalog, kingdom.regional_commander_registry, 555002,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var expeditions_before_b: int = kingdom.active_expeditions.size()
	var result_b: Dictionary = kingdom.start_expedition(expedition_b)
	print("  2ª Expedição (mesmo Exército, ainda travado) -> rejeitada, com motivo? %s ('%s') (esperado: true, motivo não-vazio)" % [
		str(not result_b["success"]), result_b["reason"]
	])
	print("  active_expeditions não cresceu com a tentativa rejeitada? %s (%d -> %d, esperado: true)" % [
		str(kingdom.active_expeditions.size() == expeditions_before_b), expeditions_before_b, kingdom.active_expeditions.size()
	])
	print("  Exército permanece exclusivamente designado à 1ª Expedição? %s (esperado: true)" % str(
		expedition_a.squad.armies.has(army) and not kingdom.active_expeditions.has(expedition_b)
	))

	# --- Camada de domínio: GameRuntime.start_new_expedition() ---
	# GameRuntime.start_new_expedition() é outro chamador de
	# Kingdom.start_expedition() (além do PvEPanel) — precisa propagar a
	# rejeição em vez de devolver uma ExpeditionRuntime "de aparência
	# válida" que nunca foi registrada (Finding A da revisão da
	# auditoria). A Energia do Exército também não pode ser inicializada
	# (resetada pra cheia) numa tentativa rejeitada — isso corromperia a
	# Energia real da Expedição que já o possui.
	var energy_before_ga: int = army.current_energy
	var squad_c := Squad.new([army])
	var expeditions_before_ga: int = kingdom.active_expeditions.size()
	var start_result_c: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season.season_id, territory.id, squad_c, 555003,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  GameRuntime.start_new_expedition() (mesmo Exército travado) -> reporta rejeição, sem sucesso? %s ('%s') (esperado: true, motivo não-vazio)" % [
		str(not start_result_c["success"]), start_result_c["reason"]
	])
	print("  A Expedição construída (não-null) não ficou registrada? %s (esperado: true)" % str(
		start_result_c["expedition"] != null and not kingdom.active_expeditions.has(start_result_c["expedition"])
	))
	print("  active_expeditions não cresceu via GameRuntime? %s (%d -> %d, esperado: iguais)" % [
		str(kingdom.active_expeditions.size() == expeditions_before_ga), expeditions_before_ga, kingdom.active_expeditions.size()
	])
	print("  Energia do Exército NÃO foi resetada pela tentativa rejeitada? %s (%d -> %d, esperado: iguais)" % [
		str(army.current_energy == energy_before_ga), energy_before_ga, army.current_energy
	])

	# --- Camada de UI: PvEPanel ("Iniciar Nova Expedição") ---
	var panel: Control = load("res://scenes/command_center/panels/pve_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	panel.refresh()
	var use_button: Button = null
	for row: Node in panel._existing_armies_container.get_children():
		if row is HBoxContainer and row.get_child_count() >= 2:
			var row_label: Label = row.get_child(0) as Label
			if row_label != null and row_label.text.begins_with(commander.commander_name):
				use_button = row.get_child(1) as Button
				break
	print("  UI: botão 'Usar no Squad' aparece desabilitado pro Exército travado, com o motivo? %s ('%s', esperado: true, contém 'Expedição')" % [
		str(use_button != null and use_button.disabled), (use_button.text if use_button != null else "<não encontrado>")
	])

	# Mesmo que a seleção via botão esteja desabilitada, a camada de
	# domínio precisa recusar sozinha (nunca confiar só na UI) — chama o
	# método nomeado diretamente, simulando um clique que a UI real
	# nunca permitiria, exatamente o cenário que a auditoria pediu pra
	# não depender apenas de esconder/desabilitar o botão.
	panel._on_use_existing_army_pressed(army)
	panel._new_expedition_territory = territory
	var expeditions_before_ui: int = kingdom.active_expeditions.size()
	panel._on_start_new_expedition_pressed()
	print("  UI: 'Iniciar Expedição' com o Exército travado -> nenhuma Expedição nova foi registrada? %s (%d -> %d, esperado: iguais)" % [
		str(kingdom.active_expeditions.size() == expeditions_before_ui), expeditions_before_ui, kingdom.active_expeditions.size()
	])

	panel.queue_free()


## Validação FUNCIONAL do P0 identificado na auditoria de Expedição:
## GameRuntime.sync() recuperava Energia incondicionalmente pra todo
## Exército do Reino, mesmo um travado em marcha ativa (ENERGY.md,
## "Locais de Recuperação": só Cidade e Acampamentos, nunca durante o
## avanço idle ativo nem em combate). Mesmo mecanismo de tempo real já
## coberto por _validate_energy_recovers_over_real_time() (que continua
## intocado), agora testado com o Exército preso numa Expedição.
func _validate_energy_frozen_while_marching() -> void:
	print("[Energia] Validando que a Energia NÃO recupera enquanto o Exército está em marcha ativa (P0 da auditoria)...")

	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Energia em Marcha)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	if season == null:
		WorldBootstrap._generate_dev_scale_world()
		season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	var territory: Territory = season.get_territory("Território de Império")
	var trilha: Trilha = season.get_trilha(territory.id)
	var squad := Squad.new([army])
	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, season.enemy_catalog, kingdom.regional_commander_registry, 777001,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var start_result: Dictionary = kingdom.start_expedition(expedition)
	print("  Expedição iniciada de verdade? %s (esperado: true)" % str(start_result["success"]))

	army.consume_energy(army.max_energy - 2)  # baixa, sem esgotar (mesmo padrão de _validate_army_unlocks_after_returning_to_camp)
	print("  Energia baixa antes de qualquer sincronização: %d/%d" % [army.current_energy, army.max_energy])
	print("  Exército travado (marcha ativa, longe de Acampamento)? %s (esperado: true)" % str(
		kingdom.is_army_locked_for_editing(army)["locked"]
	))

	var now: int = GameClock.now_unix()
	GameRuntime.sync(kingdom, now)  # 1ª sincronização, só estabelece a referência

	var energy_before_wait: int = army.current_energy
	now += 3600 * 24 * 30  # 30 dias reais — tempo de sobra pra recuperar 100% se estivesse liberado
	GameRuntime.sync(kingdom, now)
	print("  30 dias reais depois, ainda em marcha -> Energia continua congelada (não recuperou)? %s (%d -> %d, esperado: iguais)" % [
		str(army.current_energy == energy_before_wait), energy_before_wait, army.current_energy
	])

	# "Volta" pro Acampamento/Cidade (mesmo caminho de
	# _validate_army_unlocks_after_returning_to_camp: falha sem nunca
	# ter alcançado Acampamento real -> is_waiting_at_acampamento = true,
	# destrava is_army_locked_for_editing()).
	expedition.attempt_current_fase()
	print("  Depois de 'voltar' (falha, sem Acampamento real) -> destravado? %s (esperado: true)" % str(
		not kingdom.is_army_locked_for_editing(army)["locked"]
	))

	var energy_before_return: int = army.current_energy
	now += 3600 * 24  # +24h reais, já destravado
	GameRuntime.sync(kingdom, now)
	print("  24h reais depois de destravar -> Energia volta a recuperar? %s (%d -> %d, esperado: aumentou)" % [
		str(army.current_energy > energy_before_return), energy_before_return, army.current_energy
	])


func _validate_minas_panel_ui() -> void:
	print("[UI] Validando MinasPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom
	var now: int = GameClock.now_unix()

	var mina := Mina.new(-1, "Império")
	mina.conquer()
	var reference_cards: Array[CardResource] = []
	for card: CardResource in GameDatabase.cards:
		if card.rarity == "Comum" and reference_cards.size() < 9:
			reference_cards.append(card)
	var reference_commander_for_test := CommanderResource.new()
	reference_commander_for_test.commander_name = "Chefe de Mina de Teste"
	mina.freeze_reference_formation(reference_cards, reference_commander_for_test)
	kingdom.initial_mines.append(mina)

	var guarnicao_commander := CommanderResource.new()
	guarnicao_commander.commander_name = "UI Minas Comandante 555444"
	kingdom.add_commander(guarnicao_commander, now)
	CommandCenterResolver.activate_next(kingdom)
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, guarnicao_commander)

	var test_army := Army.new()
	test_army.army_name = "Exército de Teste UI Minas"
	test_army.commander = guarnicao_commander
	test_army.cards = reference_cards.duplicate()
	kingdom.armies.append(test_army)

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/minas_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)

	print("  Painel mostra a Mina conquistada? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Mina Inicial")
	))

	var available_armies_for_test: Array[Army] = [test_army]
	panel._on_army_selected(1, mina, available_armies_for_test)
	panel._on_assign_guarnicao_pressed(mina)
	print("  Após designar -> Guarnição definida? %s | Exército indisponível pra outra função? %s (esperado: true, true)" % [
		str(mina.guarnicao_army == test_army), str(test_army.availability == Army.Availability.GUARNICAO_MINA)
	])

	# Mesma chamada que o botão real faz por baixo dos panos, só com
	# uma amostra pequena em vez das 362.880 combinações completas
	# (motivo: tempo de teste) — 1 thread, síncrono, suficiente aqui.
	var small_sample: Array = [reference_cards, reference_cards.duplicate()]
	var batch_result: Dictionary = MiningEfficiencyEstimator.run_batch(
		test_army.commander, test_army.cards, small_sample, mina.reference_commander,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, 1
	)
	var total_battles: int = batch_result["wins"] + batch_result["ties"] + batch_result["losses"]
	var efficiency: float = MiningCycleResolver.weighted_efficiency(batch_result["wins"], batch_result["ties"], batch_result["losses"], total_battles)
	mina.start_cycle(now, efficiency)
	print("  Ciclo iniciado -> ativo agora? %s | Eficiência calculada: %.2f (esperado: true, entre 0 e 1)" % [
		str(mina.is_cycle_active(now)), efficiency
	])

	# F-045: daqui em diante o teste depende de o Ciclo poder realmente
	# EXPIRAR (Renovação Automática reiniciando sozinho, Modo Manual
	# liberando a Guarnição) — "mina" foi criada com adjacent_fase = -1
	# (Mina Inicial, útil até aqui só pra exercitar o texto "Mina
	# Inicial" e a designação de Guarnição sem precisar montar uma Mina
	# Regional completa), mas Mina.is_cycle_active() nunca expira uma
	# Mina Inicial ("produção contínua, sem prazo" — MINES.md, "Mina
	# Inicial"), então a checagem de "Modo Manual" abaixo nunca poderia
	# passar de verdade enquanto isso. Convertida pra uma Mina Regional
	# a partir daqui (mesmo objeto, só muda de identidade estrutural) —
	# não altera nenhuma checagem já feita acima.
	mina.adjacent_fase = 1500

	# Renovação Automática: avança o tempo além das 100h do Ciclo e
	# sincroniza — o Ciclo deveria reiniciar sozinho, sem liberar a
	# Guarnição.
	mina.auto_renew_enabled = true
	var after_cycle: int = now + Mina.CYCLE_DURATION_SECONDS + 10
	GameRuntime.sync(kingdom, after_cycle)
	print("  Renovação Automática -> Ciclo ainda ativo após o fim do anterior? %s | Guarnição continua designada? %s (esperado: true, true)" % [
		str(mina.is_cycle_active(after_cycle)), str(test_army.availability == Army.Availability.GUARNICAO_MINA)
	])

	# Modo Manual: desliga a Renovação, avança de novo, sincroniza —
	# agora a Guarnição deveria ser liberada.
	mina.auto_renew_enabled = false
	var after_second_cycle: int = after_cycle + Mina.CYCLE_DURATION_SECONDS + 10
	GameRuntime.sync(kingdom, after_second_cycle)
	print("  Modo Manual -> Ciclo terminou e Guarnição foi liberada? %s (esperado: true)" % str(
		test_army.availability == Army.Availability.AVAILABLE
	))

	panel.queue_free()


## Validação FUNCIONAL (sem renderização) da janela de PvE: injeta uma
## Expedição real (mesmo padrão de _validate_expedition_runtime), com
## Squad de 2 Exércitos — confirma que a tela mostra Território/Fase/
## Squad, que "Tentar Fase Atual" avança de verdade, que os botões de
## reordenar a Ordem de Substituição só funcionam quando parado num
## Acampamento, e que "Continuar" retoma a marcha de verdade.
func _validate_pve_panel_ui() -> void:
	print("[UI] Validando PvEPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army_1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_1.army_name = "UI PvE Exército 1"
	army_1.initialize_energy(1)
	var army_2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_2.army_name = "UI PvE Exército 2"
	army_2.initialize_energy(1)
	# F-009: army_name propositalmente NUNCA definido aqui — reproduz o
	# Exército formado pelo Kit Inicial (que também nunca define
	# army_name), pra confirmar que a Fileira do Squad nunca mostra um
	# rótulo vazio.
	var army_3: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_3.initialize_energy(1)
	var squad := Squad.new([army_1, army_2, army_3])

	var territory := Territory.new("UI-PvE-Territorio-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 321,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	kingdom.active_expeditions.append(expedition)

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/pve_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)
	# O indicador de carregamento torna _ready() assíncrono (await) —
	# sem esperar aqui, os métodos abaixo rodariam antes da estrutura
	# da tela existir de verdade (confirmado com execução real: "Cannot
	# call method 'get_children' on a null value").
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("  Painel mostra o Território e os 2 Exércitos do Squad? %s (esperado: true)" % str(
		_panel_contains_text(panel, "UI-PvE-Territorio-Teste") and _panel_contains_text(panel, "UI PvE Exército 1") and _panel_contains_text(panel, "UI PvE Exército 2")
	))
	print("  Exército sem army_name (3º da lista) mostra um rótulo de fallback ('Exército 3'), nunca vazio? %s (esperado: true, F-009)" % str(
		_panel_contains_text(panel, "Exército 3")
	))

	# F-047: _on_attempt_fase_pressed() agora reproduz visualmente cada
	# combate real (CombatReplayView) antes de mostrar o Resultado —
	# precisa de await (senão as checagens abaixo rodariam antes da
	# reprodução terminar, e panel.queue_free() mais abaixo destruiria
	# o painel com a corrotina ainda suspensa). O painel real usa o
	# ritmo humano padrão (0.6s/evento); aqui a validação seta
	# replay_speed_override = 0.0 no próprio painel ANTES de disparar a
	# tentativa, senão esta única validação levaria vários segundos
	# reais de parede.
	panel.replay_speed_override = 0.0
	await panel._on_attempt_fase_pressed(expedition)
	print("  Após 'Tentar Fase Atual' -> Fase avançou de verdade? %s (esperado: true, Fase 2)" % str(expedition.current_fase == 2))
	print("  Após 'Tentar Fase Atual' -> resultado (Vitória/Derrota) aparece de verdade na tela, não só no log? %s (esperado: true, F-003)" % str(
		_panel_contains_text(panel, "Vitória!")
	))

	# Força um Acampamento com Política "Aguardar Ordem", pra testar
	# reordenar o Squad e o botão "Continuar" de forma determinística
	# (sem depender de calcular em qual Fase real cairia um Acampamento).
	expedition.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_ORDEM
	expedition.establish_acampamento()
	panel.refresh()
	print("  No Acampamento -> painel mostra 'Continuar'? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Continuar")
	))

	panel._on_move_army_pressed(expedition, 0, 1)
	print("  Reordenar (só permitido no Acampamento) -> Exército 2 agora é o 1º da lista? %s (esperado: true)" % str(
		expedition.squad.armies[0] == army_2
	))

	panel._on_resume_pressed(expedition)
	print("  Após 'Continuar' -> Expedição não está mais aguardando? %s (esperado: true)" % str(
		not expedition.is_waiting_at_acampamento
	))

	panel.queue_free()


## Validação FUNCIONAL (sem renderização) do Editor de Exército: caso
## simples (1 Formação, PvP/Minas) e caso completo (5 Formações, PvE)
## — monta de verdade via Kingdom.form_army(), testa a troca (swap) de
## posição, e confirma que "army_ready" entrega um Exército pronto pra
## uso, com as Formações extras corretamente preenchidas.
var _test_captured_army: Army = null
var _test_cancelled_fired: bool = false


func _on_test_cancelled() -> void:
	_test_cancelled_fired = true


func _on_test_army_ready(army: Army) -> void:
	_test_captured_army = army


func _validate_army_editor_panel() -> void:
	print("[UI] Validando ArmyEditorPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom

	var commander := CommanderResource.new()
	commander.commander_name = "UI Editor Comandante 333222"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, commander)

	var cheap_cards: Array[CardResource] = []
	for card: CardResource in GameDatabase.cards:
		if card.rarity == "Comum" and cheap_cards.size() < 9:
			var copy: CardResource = kingdom.acquire_card_from_catalog(card)
			cheap_cards.append(copy)

	# --- Caso simples: 1 Formação (PvP/Minas) ---
	var editor_simple: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	editor_simple.formation_count = 1
	add_child(editor_simple)

	editor_simple._selected_commander = commander
	for card: CardResource in cheap_cards:
		editor_simple._on_card_toggled(true, card)

	var simple_result: Army = null
	editor_simple.army_ready.connect(func(army: Army) -> void: simple_result = army)
	_test_captured_army = null
	editor_simple.army_ready.connect(_on_test_army_ready)
	editor_simple._on_montar_pressed()
	print("  Mesmo com 1 só Formação, o grid de posicionamento aparece (Posicionamento é o fator mais importante do jogo)? %s (esperado: true)" % str(
		editor_simple._formations_section.visible
	))

	# Troca (swap) a carta da Posição 1 com a da Posição 5 — confirma
	# que o rearranjo de verdade muda o Exército final, não só a
	# ordem em que as cartas foram marcadas.
	var card_at_position_1_before: CardResource = editor_simple._formation_cards["α"][0]
	var card_at_position_5_before: CardResource = editor_simple._formation_cards["α"][4]
	editor_simple._on_slot_card_selected(4, 0)  # Posição 1 (índice 0) <-> Posição 5 (índice 4)
	editor_simple._on_concluir_pressed()

	print("  Trocar (swap) Posição 1 com Posição 5 -> o Exército final reflete a troca de verdade? %s (esperado: true)" % str(
		_test_captured_army.cards[0] == card_at_position_5_before and _test_captured_army.cards[4] == card_at_position_1_before
	))

	print("  Caso simples -> conectar via lambda (NÃO funciona, confirmado): %s | conectar via método nomeado (funciona): %s (esperado: false, true)" % [
		str(simple_result != null), str(_test_captured_army != null)
	])
	editor_simple.queue_free()

	# --- Caso completo: 5 Formações (PvE) ---
	var commander_2 := CommanderResource.new()
	commander_2.commander_name = "UI Editor Comandante 444333"
	kingdom.add_commander(commander_2, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — o Reino compartilhado já pode ter esgotado o Nível atual do CdC
	CommandCenterResolver.move_to_active(kingdom, commander_2)

	var cheap_cards_2: Array[CardResource] = []
	for card: CardResource in GameDatabase.cards:
		if card.rarity == "Comum":
			var copy: CardResource = kingdom.acquire_card_from_catalog(card)
			cheap_cards_2.append(copy)
			if cheap_cards_2.size() == 9:
				break

	var editor_full: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	editor_full.formation_count = 5
	add_child(editor_full)

	editor_full._selected_commander = commander_2
	for card: CardResource in cheap_cards_2:
		editor_full._on_card_toggled(true, card)
	editor_full._on_montar_pressed()

	print("  Caso completo (5 Formações) -> seção de posicionamento apareceu? %s (esperado: true)" % str(
		editor_full._formations_section.visible
	))

	var beta_cards: Array[CardResource] = editor_full._formation_cards["β"]
	var card_at_position_1: CardResource = beta_cards[0]
	var card_at_position_2: CardResource = beta_cards[1]
	editor_full._current_formation = "β"
	editor_full._on_slot_card_selected(1, 0)  # troca posição 1 com posição 2
	print("  Trocar (swap) Posição 1 com Posição 2 na Formação β -> troca de verdade aconteceu? %s (esperado: true)" % str(
		beta_cards[0] == card_at_position_2 and beta_cards[1] == card_at_position_1
	))

	var full_result: Army = editor_full._army
	editor_full._on_concluir_pressed()

	print("  Concluir -> Exército tem as 4 Formações extras (β a ε) preenchidas? %s | α usa o fallback pra army.cards (base)? %s (esperado: true, true)" % [
		str(full_result.formations.has("β") and full_result.formations.has("γ") and full_result.formations.has("δ") and full_result.formations.has("ε")),
		str(full_result.get_formation("α") == full_result.cards)
	])
	editor_full.queue_free()


## Validação FUNCIONAL (sem renderização) da janela de PvP: 3
## Exércitos Ativos aparecem na Liga Bronze; criar um Plano de
## Campanha com os 3; mapear um Campo Especial; definir Defesa
## Preferencial; reordenar a Ordem de Ataque; confirmar que
## resolve_defender() resolve corretamente os dois casos (Campo Aberto
## via Defesa Preferencial, Campo Especial via mapeamento).
func _validate_pvp_panel_ui() -> void:
	print("[UI] Validando PvPPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom

	var cheap_cards: Array[CardResource] = []
	for card: CardResource in GameDatabase.cards:
		if card.rarity == "Comum" and cheap_cards.size() < 9:
			cheap_cards.append(card)

	var test_armies: Array[Army] = []
	for i in range(3):
		var commander := CommanderResource.new()
		commander.commander_name = "UI PvP Comandante %d" % i
		kingdom.add_commander(commander, GameClock.now_unix())
		kingdom.add_generation_points(10)
		# F-045: activate_next() só ativa Infraestrutura ainda não usada
		# no Nível atual do CdC — o Reino aqui é o COMPARTILHADO de
		# todo o bootstrap.tscn, já esgotado por dezenas de validações
		# anteriores nesta mesma execução, então activate_next()/
		# move_to_active() podiam silenciosamente falhar
		# ("no_cargo_ativo_available") pro 2º/3º Comandante sem nenhum
		# aviso, fazendo só parte dos 3 Exércitos de teste aparecerem
		# como Ativos na Liga Bronze. Mesmo padrão de garantia direta já
		# usado em _validate_ui_minas_panel() (linha ~1574) em vez de
		# depender de capacidade que pode já estar esgotada.
		kingdom.cargo_ativo_activated += 1
		CommandCenterResolver.move_to_active(kingdom, commander)

		var army := Army.new()
		army.army_name = "UI PvP Exército %d" % i
		army.commander = commander
		army.cards = cheap_cards.duplicate()
		kingdom.armies.append(army)
		test_armies.append(army)

	var panel_scene: PackedScene = load("res://scenes/command_center/panels/pvp_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)

	print("  Liga Bronze mostra os 3 Exércitos Ativos? %s (esperado: true)" % str(
		_panel_contains_text(panel, "UI PvP Exército 0") and _panel_contains_text(panel, "UI PvP Exército 1") and _panel_contains_text(panel, "UI PvP Exército 2")
	))

	panel._selected_for_new_plano = test_armies.duplicate()
	panel._on_create_plano_pressed()
	print("  Plano de Campanha criado com os 3 Exércitos? %s (esperado: true, 1)" % str(
		kingdom.planos_campanha.size() == 1
	))
	var plano: PlanoCampanha = kingdom.planos_campanha[0]

	panel._on_defesa_preferencial_selected(1, plano)  # índice 0 (Exército 0)
	var special_battlefield: BattlefieldResource = null
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category != "Padrão":
			special_battlefield = battlefield
			break
	panel._on_battlefield_mapping_selected(2, plano, special_battlefield)  # índice 1 (Exército 1)

	var campo_aberto: BattlefieldResource = null
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category == "Padrão":
			campo_aberto = battlefield
			break

	var defender_padrao: Army = PlanoCampanhaResolver.resolve_defender(plano, campo_aberto)
	var defender_especial: Army = PlanoCampanhaResolver.resolve_defender(plano, special_battlefield)
	print("  Defensor do Campo Aberto = Exército 0 (Defesa Preferencial)? %s | Defensor de '%s' = Exército 1 (mapeado)? %s (esperado: true, true)" % [
		str(defender_padrao == test_armies[0]), special_battlefield.battlefield_name, str(defender_especial == test_armies[1])
	])

	panel._on_move_ordem_pressed(plano, 0, 1)  # troca posição 0 com 1 na Ordem de Ataque
	print("  Reordenar a Ordem de Ataque -> 1ª posição agora é o Exército 1? %s (esperado: true)" % str(
		plano.ordem_de_ataque[0] == 1
	))

	# Ranking via UI: inscrever, simular resultado, sortear Ataque.
	panel._on_inscrever_bronze_pressed(test_armies[0].commander)
	print("  Inscrever Comandante 0 na Liga Bronze -> Divisão inicial: %s (esperado: VII)" % test_armies[0].commander.bronze_divisao)
	panel._on_simulate_bronze_result_pressed(test_armies[0].commander, "Vitória")
	print("  Simular Vitória na Bronze -> PL: %d (esperado: 100)" % test_armies[0].commander.bronze_pl)

	panel._on_inscrever_plano_pressed(plano, "Ouro")
	print("  Inscrever o Plano na Liga Ouro -> Liga: %s | Divisão: %s (esperado: Ouro, VII)" % [plano.liga, plano.divisao])
	panel._on_simulate_plano_result_pressed(plano, "Derrota")
	print("  Simular Derrota como Atacante (Divisão VII) -> PL: %d (esperado: 0, nunca negativo)" % plano.pl)

	# Garante energia nos 3 Exércitos pra confirmar que o sorteio de
	# Ataque via UI encontra um Exército elegível de verdade.
	for army: Army in test_armies:
		army.initialize_energy(1)
	panel._on_sortear_ataque_pressed(plano)
	print("  'Sortear Campo de Batalha (Ataque)' rodou sem erro (ver print acima, começando com '[PvPPanel] Campo sorteado')")

	panel.queue_free()


## Validação FUNCIONAL (sem renderização) da janela de Academia:
## produção Comum (direto por Fragmento), produção com Receita (cadeia
## automática — Balista Imperial precisa de 3 Comuns diferentes),
## Aprimoramento manual (merge de 3 cópias), Melhorar Fila (PG), e
## Cancelar Tarefa. Testa tanto o motor direto quanto os botões da
## tela.
## Avança o tempo em passos, chamando AcademyResolver.sync() a cada
## passo, até que nenhum Mestre da Academia tenha nenhuma tarefa
## pendente — usado nos testes pra garantir que uma etapa realmente
## terminou antes de pedir a próxima (sem isso, um pedido pode falhar
## silenciosamente por "nenhum Mestre livre").
func _sync_all_academy_masters_until_idle(kingdom: Kingdom) -> void:
	var attempts: int = 0
	while attempts < 20:
		var any_busy: bool = false
		var latest_end: int = 0
		for master: AcademyMaster in kingdom.academy_artifices + kingdom.academy_metamorfos:
			var task: AcademyTask = master.current_task()
			if task != null:
				any_busy = true
				if task.has_started():
					latest_end = maxi(latest_end, task.end_unix)
		if not any_busy:
			return
		if latest_end == 0:
			latest_end = GameClock.now_unix() + 1  # tarefa na fila, ainda não iniciada — só mais um sync já resolve
		AcademyResolver.sync(kingdom, latest_end + 1)
		attempts += 1


func _validate_academia_panel() -> void:
	print("[UI] Validando AcademiaPanel (motor + tela)...")

	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.add_fragment("Império", 100000)
	kingdom.add_generation_points(1000)
	var now: int = GameClock.now_unix()

	# --- Produção Comum (direto por Fragmento) ---
	var fragments_before: int = kingdom.get_fragment("Império")
	var common_result: Dictionary = AcademyResolver.request_production(kingdom, "Arqueiro Imperial", 3, now)
	print("  Produzir 3x 'Arqueiro Imperial' (Comum) -> sucesso? %s | Fragmentos gastos: %d (esperado: true, 150 = 3x50)" % [
		str(common_result["success"]), fragments_before - kingdom.get_fragment("Império")
	])

	# Avança o tempo até a tarefa terminar de verdade, e sincroniza.
	var artifice_task: AcademyTask = kingdom.academy_artifices[0].current_task()
	AcademyResolver.sync(kingdom, artifice_task.end_unix + 1)
	var arqueiro_count: int = 0
	for card: CardResource in kingdom.cards:
		if card.card_name == "Arqueiro Imperial" and card.ownership_status == CardResource.OwnershipStatus.LIVRE:
			arqueiro_count += 1
	print("  Após o tempo passar -> as 3 cópias chegaram no inventário de verdade? %s (%d, esperado: true, 3)" % [
		str(arqueiro_count == 3), arqueiro_count
	])

	# --- Produção com Receita (cadeia automática — Balista Imperial) ---
	var preview: Dictionary = AcademyResolver.preview_production(kingdom, "Balista Imperial", 1)
	print("  Previsão de 'Balista Imperial' (Rara, receita de 3 Comuns) -> válida? %s | Reaproveita 'Arqueiro Imperial' do inventário? %s (esperado: true, true)" % [
		str(preview["valid"]), str(preview["existing_cards_to_reuse"].has("Arqueiro Imperial"))
	])

	var recipe_result: Dictionary = AcademyResolver.request_production(kingdom, "Balista Imperial", 1, now)
	print("  Produzir 'Balista Imperial' de verdade -> sucesso? %s (esperado: true)" % str(recipe_result["success"]))

	# --- Aprimoramento Manual (merge de 3 cópias) ---
	# Espera TODOS os Mestres ficarem ociosos antes de pedir mais
	# produção — sem isso, o único Artífice (Nível 1) pode ainda estar
	# ocupado com as etapas da Balista Imperial, e o pedido falharia
	# silenciosamente por falta de Mestre livre.
	_sync_all_academy_masters_until_idle(kingdom)

	var upgrade_result_before: Dictionary = AcademyResolver.request_production(kingdom, "Arqueiro Imperial", 3, now)
	print("  (preparação) Pedido de mais 3x 'Arqueiro Imperial' pro teste de Aprimoramento -> aceito? %s (esperado: true)" % str(upgrade_result_before["success"]))
	_sync_all_academy_masters_until_idle(kingdom)

	var upgrade_result: Dictionary = AcademyResolver.request_upgrade(kingdom, "Arqueiro Imperial", 1, 1, now)
	print("  Aprimorar 3x 'Arqueiro Imperial' Tier 1 -> Tier 2 -> sucesso? %s (esperado: true)" % str(upgrade_result["success"]))

	# --- Melhorar Fila (PG) ---
	var capacity_before: int = kingdom.academy_artifices[0].queue_capacity
	AcademyResolver.upgrade_queue_capacity(kingdom, kingdom.academy_artifices[0])
	print("  Melhorar Fila do Artífice 1 -> capacidade subiu de verdade? %s (%d -> %d, esperado: true)" % [
		str(kingdom.academy_artifices[0].queue_capacity > capacity_before), capacity_before, kingdom.academy_artifices[0].queue_capacity
	])

	# --- Cancelar Tarefa ---
	_sync_all_academy_masters_until_idle(kingdom)
	# Pede 2 de uma vez: a fila do Artífice 1 tem capacidade 2 agora
	# (melhorada acima) — a 1ª começa na hora, a 2ª fica na fila sem
	# iniciar, exatamente o caso que queremos cancelar.
	AcademyResolver.request_production(kingdom, "Arqueiro Imperial", 1, now)
	AcademyResolver.request_production(kingdom, "Arqueiro Imperial", 1, now)
	var master_of_task_to_cancel: AcademyMaster = null
	var task_to_cancel: AcademyTask = null
	for master: AcademyMaster in kingdom.academy_artifices:
		for task: AcademyTask in master.queue:
			if not task.has_started():
				master_of_task_to_cancel = master
				task_to_cancel = task
	if task_to_cancel != null:
		var fragments_before_cancel: int = kingdom.get_fragment("Império")
		AcademyResolver.cancel_task(kingdom, master_of_task_to_cancel, task_to_cancel)
		print("  Cancelar tarefa não iniciada -> Fragmentos devolvidos de verdade? %s (esperado: true)" % str(
			kingdom.get_fragment("Império") > fragments_before_cancel
		))
	else:
		print("  (não achou uma tarefa não iniciada pra cancelar — todos os Mestres já estavam ocupados de novo)")

	# --- A tela em si ---
	var panel: Control = load("res://scenes/city/panels/academia_panel.tscn").instantiate()
	add_child(panel)

	print("  Painel mostra o Nível da Academia e os Fragmentos? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Nível da Academia") and _panel_contains_text(panel, "Fragmentos")
	))

	panel._selected_produce_card = GameDatabase.get_card("Arqueiro Imperial")
	panel._produce_quantity = 2
	panel._on_preview_pressed()
	print("  Botão 'Prever' na tela preenche o resultado de verdade? %s (esperado: true)" % str(
		panel._preview_label.text != ""
	))

	panel.queue_free()


## Validação FUNCIONAL: uma cadeia de Produção Automática de verdade,
## salva e recarregada NO MEIO DO CAMINHO (com tarefas ainda
## aguardando dependências) — a lacuna que fechamos nesta entrega.
## "Campeão Imperial" (Épica) usa "Besteiro Imperial" (Rara) como
## ingrediente, que por sua vez tem sua própria receita — 2 níveis de
## profundidade, garantindo tarefas "pai" apontando pra tarefas
## "filha" no meio da árvore, o caso que mais expõe problema de
## referência cruzada num save ingênuo.
func _validate_academia_chain_persistence() -> void:
	print("[Academia] Validando persistência de cadeia em andamento (save/load no meio do caminho)...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 100000)
	var now: int = GameClock.now_unix()

	# Só 1 Artífice (padrão do Nível 1) -> força várias tarefas
	# ficarem em academy_pending_chain_tasks de verdade, aguardando a
	# vez, exatamente o cenário que queremos testar.
	kingdom.sync_academy_masters()
	AcademyResolver.request_production(kingdom, "Campeão Imperial", 1, now)

	var pending_before: int = kingdom.academy_pending_chain_tasks.size()
	print("  Cadeia de 'Campeão Imperial' (Épica, com Besteiro Imperial de 2º nível) -> tarefas aguardando de verdade? %s (%d, esperado: > 0)" % [
		str(pending_before > 0), pending_before
	])

	KingdomSaveService.save(kingdom)
	var loaded := Kingdom.new()
	KingdomSaveService.load_into(loaded)

	print("  Após salvar e carregar -> mesma quantidade de tarefas aguardando? %s (%d -> %d, esperado: iguais)" % [
		str(loaded.academy_pending_chain_tasks.size() == pending_before), pending_before, loaded.academy_pending_chain_tasks.size()
	])

	# Integridade das referências cruzadas: nenhuma tarefa "pai" (com
	# depends_on preenchido) pode ter perdido a ligação com suas
	# "filhas" no processo de save/load.
	var all_refs_intact: bool = true
	for task: AcademyTask in loaded.academy_pending_chain_tasks:
		for dependency: AcademyTask in task.depends_on:
			if dependency == null:
				all_refs_intact = false
	print("  Referências depends_on (tarefa pai -> filha) sobreviveram intactas? %s (esperado: true)" % str(all_refs_intact))

	# A prova real: a cadeia carregada continua funcionando de verdade
	# até o fim — não só os dados sobreviveram, o COMPORTAMENTO também.
	var attempts: int = 0
	while attempts < 30:
		var still_working: bool = not loaded.academy_pending_chain_tasks.is_empty()
		for master: AcademyMaster in loaded.academy_artifices + loaded.academy_metamorfos:
			if master.current_task() != null:
				still_working = true
		if not still_working:
			break
		AcademyResolver.sync(loaded, now + (attempts + 1) * 200)
		attempts += 1

	var campeao_produced: bool = false
	for card: CardResource in loaded.cards:
		if card.card_name == "Campeão Imperial":
			campeao_produced = true
	print("  Cadeia carregada continua funcionando até o fim -> 'Campeão Imperial' foi produzido de verdade? %s (esperado: true)" % str(campeao_produced))


## Validação FUNCIONAL da nova Restrição de Patente/Tier/Soldo por
## Região (PvE.md item 3): heurística de posicionamento, o gerador com
## e sem Comandante, o Benchmark Regional (metade com Máquina de
## Guerra, metade sem), e o experimento heurística vs. aleatório —
## tudo em escala pequena aqui (a escala real de 20 mil/10 mil
## candidatos pertence à ferramenta externa, nunca ao Bootstrap).
func _validate_regional_generation() -> void:
	print("[PvE Regional] Validando Restrição por Região, heurística de posicionamento e o experimento...")

	# --- Heurística de posicionamento ---
	var cqc := CardResource.new()
	cqc.card_name = "Teste CQC"
	cqc.card_class = "Corpo a Corpo"
	var barreira := CardResource.new()
	barreira.card_name = "Teste Barreira"
	barreira.card_class = "Barreira"
	var machine := CardResource.new()
	machine.card_name = "Teste MdG"
	machine.card_class = "Máquina de Guerra"
	var ranged_cards: Array[CardResource] = []
	for i in range(6):
		var card := CardResource.new()
		card.card_name = "Teste À Distância %d" % i
		card.card_class = "À Distância"
		ranged_cards.append(card)

	var test_set: Array[CardResource] = [cqc, barreira, machine]
	test_set.append_array(ranged_cards)
	var heuristic_result: Array[CardResource] = ArmyPositioningHeuristic.apply_heuristic(test_set)

	print("  Heurística: Máquina de Guerra sempre na posição 9? %s | Corpo a Corpo/Barreira foram pra Linha 1? %s (esperado: true, true)" % [
		str(heuristic_result[8].card_class == "Máquina de Guerra"),
		str(heuristic_result[0].card_class in ["Corpo a Corpo", "Barreira"] and heuristic_result[1].card_class in ["Corpo a Corpo", "Barreira"])
	])

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 555
	var random_result: Array[CardResource] = ArmyPositioningHeuristic.apply_random(test_set, rng_a)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 555
	var random_result_2: Array[CardResource] = ArmyPositioningHeuristic.apply_random(test_set, rng_b)
	print("  Aleatório: Máquina de Guerra continua fixa na posição 9 mesmo aleatorizando o resto? %s | Mesma seed reproduz o mesmo resultado? %s (esperado: true, true)" % [
		str(random_result[8].card_class == "Máquina de Guerra"),
		str(random_result[0] == random_result_2[0] and random_result[3] == random_result_2[3])
	])

	# --- Gerador: Fases Normais (sem Comandante narrativo) ---
	var normal_entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, SeasonConfig.new(),
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_normal", 1
	)
	var tiers_in_range: bool = true
	for card: CardResource in normal_entry.cards:
		if card.tier < 1 or card.tier > 2:
			tiers_in_range = false
	# F-045: EnemyArmyGenerator.generate() (Category.NORMAL) nomeia o
	# Comandante técnico como "Comandante Técnico (Facção)" — nunca
	# string vazia (ver enemy_army_generator.gd, linha ~255). A checagem
	# original comparava contra "" (nunca verdadeiro na implementação
	# real), corrigida para o prefixo real e documentado.
	print("  Fases Normais (Região I) -> Comandante sem nome (técnico)? %s | Soldo <= 24? %s | Todos os Tiers em I-II? %s (esperado: true, true, true)" % [
		str(normal_entry.commander.commander_name.begins_with("Comandante Técnico")), str(Soldo.total_for_composition(normal_entry.cards) <= 24), str(tiers_in_range)
	])

	# --- Gerador: Chefe Normal (com Comandante), Região II ---
	var chefe_entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 2, GameDatabase.cards, SeasonConfig.new(),
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_chefe", 1
	)
	var chefe_patente: String = CommanderCareer.patente_for_xp(chefe_entry.commander.accumulated_xp)
	var chefe_tiers_ok: bool = true
	for card: CardResource in chefe_entry.cards:
		if card.tier < 3 or card.tier > 4:
			chefe_tiers_ok = false
	print("  Chefe Normal (Região II) -> Patente dentro da faixa (Coronel/General)? %s | Soldo respeita o teto da Patente sorteada (%s = %d)? %s | Tiers em III-IV? %s (esperado: true, <=, true, true)" % [
		str(chefe_patente == "Coronel" or chefe_patente == "General"), chefe_patente, Soldo.cap_for_patente(chefe_patente),
		str(Soldo.total_for_composition(chefe_entry.cards) <= Soldo.cap_for_patente(chefe_patente)), str(chefe_tiers_ok)
	])

	# --- Benchmark Regional ---
	var benchmark: Array[Army] = RegionalBenchmark.build("Império", 1, GameDatabase.cards, 777)
	var machine_count: int = 0
	for army: Army in benchmark:
		for card: CardResource in army.cards:
			if card.card_class == "Máquina de Guerra":
				machine_count += 1
				break
	print("  Benchmark Regional -> 20 Exércitos, metade com Máquina de Guerra? %s (%d de 20, esperado: true, 10)" % [
		str(benchmark.size() == 20 and machine_count == 10), machine_count
	])

	# --- Experimento: heurística vs. aleatório, escala pequena ---
	var report: RegionalGenerationReport = RegionalGenerationRunner.run(
		"Império", 1, GameDatabase.cards, 10, 10, 5, 999,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Experimento rodou de verdade -> %d candidatos avaliados (10 heurística + 10 aleatório)? %s (esperado: true, 20)" % [
		report.candidate_results.size(), str(report.candidate_results.size() == 20)
	])

	var heuristic_wrs: Array[float] = report.win_rates_for("heuristic")
	var random_wrs: Array[float] = report.win_rates_for("random")
	print("  Separou corretamente as duas distribuições? %s (%d heurística, %d aleatório, esperado: true, 10, 10)" % [
		str(heuristic_wrs.size() == 10 and random_wrs.size() == 10), heuristic_wrs.size(), random_wrs.size()
	])

	SimulationReportService.save_regional_report(report)
	var loaded_report: RegionalGenerationReport = SimulationReportService.load_regional_report("Império", 1, "fases_normais")
	print("  Round-trip salvar/carregar preserva os resultados? %s (esperado: true)" % str(
		loaded_report != null and loaded_report.candidate_results.size() == report.candidate_results.size()
	))

	# --- Medição real de tempo, pra extrapolar honestamente a escala real ---
	var timing_candidates: int = 100
	var timing_simulations: int = 20
	var timing_started: int = Time.get_ticks_msec()
	RegionalGenerationRunner.run(
		"Império", 1, GameDatabase.cards, timing_candidates, 0, timing_simulations, 12345,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var timing_elapsed_ms: int = Time.get_ticks_msec() - timing_started
	var total_battles: int = timing_candidates * timing_simulations
	var ms_per_battle: float = float(timing_elapsed_ms) / float(total_battles)
	print("  [Medição de tempo real] %d candidatos x %d simulações (%d batalhas) em %.1fs -> %.2fms por batalha em média." % [
		timing_candidates, timing_simulations, total_battles, timing_elapsed_ms / 1000.0, ms_per_battle
	])
	var estimated_full_scale_seconds: float = ms_per_battle * 30000.0 * 20.0 * 3.0 / 1000.0
	print("  Extrapolando pra escala real (30 mil candidatos x 20 simulações x 3 Regiões = 1,8 milhão de batalhas): ~%.0f segundos (~%.1f horas)." % [
		estimated_full_scale_seconds, estimated_full_scale_seconds / 3600.0
	])

	# --- A tela em si ---
	var panel: Control = load("res://tools/regional_generator/regional_generator_panel.tscn").instantiate()
	add_child(panel)
	panel._territory_option.selected = 0  # Império
	panel._region_option.selected = 0  # Região I
	panel._heuristic_spin.value = 5
	panel._random_spin.value = 5
	panel._simulations_spin.value = 3
	panel._seed_spin.value = 42
	panel._on_run_pressed()
	print("  A tela da ferramenta rodou de verdade e mostrou um resumo? %s (esperado: true)" % str(
		panel._status_label.text.find("Concluído") != -1
	))
	panel.queue_free()

	# --- Motor de Chefes (com Comandante), escala pequena ---
	var chefe_report: RegionalGenerationReport = RegionalCategoryGenerationRunner.run(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 2, GameDatabase.cards, SeasonConfig.new(),
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values,
		10, 5, 321, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Motor de Chefes rodou de verdade -> 10 candidatos avaliados, todos marcados 'heuristic' (sem modo aleatório aqui)? %s (esperado: true)" % str(
		chefe_report.candidate_results.size() == 10 and chefe_report.win_rates_for("heuristic").size() == 10 and chefe_report.win_rates_for("random").is_empty()
	))
	SimulationReportService.save_regional_report(chefe_report)
	var chefe_loaded: RegionalGenerationReport = SimulationReportService.load_regional_report("Império", 2, "chefe_normal")
	print("  Arquivo de Chefe Normal não colide com o de Fases Normais (nomes diferentes)? %s (esperado: true)" % str(
		chefe_loaded != null and chefe_loaded.category_label == "chefe_normal"
	))

	# --- A tela de Chefes ---
	var chief_panel: Control = load("res://tools/regional_generator/regional_chief_generator_panel.tscn").instantiate()
	add_child(chief_panel)
	chief_panel._category_option.selected = 0  # Chefe Normal
	chief_panel._territory_option.selected = 0  # Império
	chief_panel._region_option.selected = 1  # Região II
	chief_panel._candidate_spin.value = 5
	chief_panel._simulations_spin.value = 3
	chief_panel._seed_spin.value = 42
	chief_panel._on_run_pressed()
	print("  A tela de Chefes rodou de verdade e mostrou um resumo? %s (esperado: true)" % str(
		chief_panel._status_label.text.find("Concluído") != -1
	))
	chief_panel.queue_free()


## Validação FUNCIONAL (sem renderização) da Biblioteca: Estatísticas
## da Coleção, filtros, marcação "Nova" (limpa ao visualizar),
## Favoritos, e Comparação lado a lado.
func _validate_biblioteca_panel() -> void:
	print("[UI] Validando BibliotecaPanel...")

	var kingdom: Kingdom = KingdomState.kingdom
	var template: CardResource = GameDatabase.get_card("Arqueiro Imperial")
	kingdom.acquire_card_from_catalog(template)
	kingdom.acquire_card_from_catalog(template)

	print("  Ao obter 'Arqueiro Imperial' pela 1ª vez -> marcado como Nova? %s (esperado: true)" % str(
		kingdom.is_new_card("Arqueiro Imperial")
	))

	var panel: Control = load("res://scenes/city/panels/biblioteca_panel.tscn").instantiate()
	add_child(panel)

	print("  Painel mostra as Estatísticas da Coleção? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Coleção:")
	))

	panel._on_card_selected("Arqueiro Imperial")
	print("  Selecionar a carta na tela limpa a marcação Nova? %s (esperado: true)" % str(
		not kingdom.is_new_card("Arqueiro Imperial")
	))

	panel._on_toggle_favorite_pressed()
	print("  Favoritar pela tela -> registrado de verdade no Reino? %s (esperado: true)" % str(
		kingdom.is_favorite_card("Arqueiro Imperial")
	))

	panel._on_set_compare_a_pressed()
	panel._on_card_selected("Balista Imperial")
	panel._on_set_compare_b_pressed()
	print("  Comparação mostra as 2 cartas escolhidas lado a lado? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Arqueiro Imperial") and _panel_contains_text(panel, "Balista Imperial")
	))

	panel.queue_free()


## Validação FUNCIONAL (só a tela) do Histórico de Batalhas
## (COMMANDERS.md, "Estatísticas Históricas"). O motor puro
## (CommanderResource.record_battle(), agregado V/E/D + FIFO de 20) e o
## wiring real em PhaseResolver (uma batalha de PvE de verdade credita o
## Comandante vencedor) foram migrados para
## test_commander_battle_history.gd (Etapa 15) — o Comandante e seu
## histórico de 26 batalhas continuam construídos aqui porque a tela
## (que lê KingdomState.kingdom e instancia comandantes_panel.tscn,
## ambos fora do escopo da migração) depende diretamente desse mesmo
## objeto para os checks de "V:13" e "Empatador" abaixo.
func _validate_commander_battle_history() -> void:
	print("[Comandantes] Validando Histórico de Batalhas...")

	var commander := CommanderResource.new()
	commander.commander_name = "UI Histórico Comandante 111000"
	for i in range(25):
		var result: String = "Vitória" if i % 2 == 0 else "Derrota"
		commander.record_battle("Inimigo %d" % i, "PvE — Fase %d" % i, result, GameClock.now_unix())
	commander.record_battle("Empatador", "PvE — Fase 99", "Empate", GameClock.now_unix())

	# --- A tela ---
	KingdomState.kingdom.add_commander(commander, GameClock.now_unix())
	KingdomState.kingdom.add_generation_points(10)
	CommandCenterResolver.activate_next(KingdomState.kingdom)
	CommandCenterResolver.move_to_active(KingdomState.kingdom, commander)

	var panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(panel)

	print("  Painel mostra o resumo V/E/D/WR do Comandante? %s (esperado: true)" % str(
		_panel_contains_text(panel, "V:13") and _panel_contains_text(panel, "WR:")
	))

	panel._on_view_history_pressed(commander)
	print("  'Ver Histórico' mostra as batalhas de verdade na tela? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Empatador")
	))

	panel.queue_free()


## Validação FUNCIONAL de BalanceSimulator e SimulationReportService:
## roda uma rodada pequena de Meta Aleatório de verdade, confirma a
## tabulação (Cartas/Posições), e testa o round-trip salvar/carregar
## de Season, BalanceReport e do Registro de Simulações — os arquivos
## que a ferramenta externa grava e o jogo só lê.
func _validate_balance_simulator_and_report_service() -> void:
	print("[Observatório] Validando BalanceSimulator e SimulationReportService...")

	var config := BalanceSimulationConfig.new()
	config.series_count = 20
	config.seed_value = 42
	config.label = "Validação Automática"

	var report: BalanceReport = BalanceSimulator.run(
		config, GameDatabase.cards, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Rodou 20 séries de verdade -> Total: %d | A+B+Empates bate com o total? %s (esperado: 20, true)" % [
		report.total_battles, str(report.side_a_wins + report.side_b_wins + report.draws == report.total_battles)
	])
	print("  Tabulou Win Rate por Carta e por Posição de verdade? %s (esperado: true)" % str(
		not report.card_stats.is_empty() and not report.position_stats.is_empty()
	))

	SimulationReportService.save_balance_report(report)
	var loaded_report: BalanceReport = SimulationReportService.load_balance_report()
	print("  Round-trip do Relatório (salvar/carregar) preserva os números? %s (esperado: true)" % str(
		loaded_report != null and loaded_report.total_battles == report.total_battles and loaded_report.label == report.label
	))

	# Season round-trip.
	var season := Season.new("Temporada de Teste do Round-Trip")
	var territory := Territory.new("Território de Teste", "Império")
	var trilha := Trilha.new(territory.id)
	season.add_territory(territory, trilha)
	var test_catalog := SeasonCatalog.new("Temporada de Teste do Round-Trip")
	var test_entries: Array[EnemyArmyEntry] = [EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, SeasonConfig.new(),
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste", 1
	)]
	test_catalog.add_entries("Império", EnemyArmyEntry.Category.NORMAL, test_entries)
	season.enemy_catalog = test_catalog

	SimulationReportService.save_season(season)
	var loaded_season: Season = SimulationReportService.load_season()
	var loaded_entries: Array[EnemyArmyEntry] = loaded_season.enemy_catalog.get_entries("Império", EnemyArmyEntry.Category.NORMAL) if loaded_season != null else []
	print("  Round-trip da Temporada -> Território preservado? %s | Catálogo preservado (%d carta(s) na entrada)? %s (esperado: true, 9, true)" % [
		str(loaded_season != null and loaded_season.get_territory_by_faction("Império") != null),
		loaded_entries[0].cards.size() if not loaded_entries.is_empty() else -1,
		str(not loaded_entries.is_empty() and loaded_entries[0].cards.size() == 9)
	])

	# Registro de Simulações.
	var log_count_before: int = SimulationReportService.read_generation_log().size()
	SimulationReportService.append_generation_log({"type": "teste_validacao", "timestamp_unix": GameClock.now_unix()})
	print("  Registro de Simulações -> nova entrada realmente gravada em disco? %s (%d -> %d, esperado: +1)" % [
		str(SimulationReportService.read_generation_log().size() == log_count_before + 1), log_count_before, SimulationReportService.read_generation_log().size()
	])


## Validação FUNCIONAL das 3 telas: as duas ferramentas externas
## (Gerador de PvE e Balanceamento) rodando de verdade em escala
## pequena e gravando os arquivos reais, e o Observatório (dentro do
## jogo) mostrando o conteúdo desses arquivos.
func _validate_pve_generator_and_observatorio_panels() -> void:
	print("[Observatório] Validando as ferramentas externas e o Observatório...")

	var generator_panel: Control = load("res://tools/pve_generator/pve_generator_panel.tscn").instantiate()
	add_child(generator_panel)
	generator_panel._season_id_edit.text = "Temporada de Teste da Ferramenta"
	generator_panel._normal_army_spin.value = 10
	generator_panel._chefe_normal_spin.value = 3
	generator_panel._chefe_regional_generated_spin.value = 5
	generator_panel._chefe_regional_kept_spin.value = 3
	generator_panel._simulations_spin.value = 10
	generator_panel._benchmark_spin.value = 5
	generator_panel._on_generate_pressed()
	print("  Ferramenta de Gerar Inimigos pro PvE rodou e gravou o arquivo de verdade? %s (esperado: true)" % str(
		FileAccess.file_exists(SimulationReportService.SEASON_CATALOG_PATH)
	))
	generator_panel.queue_free()

	var balance_panel: Control = load("res://tools/balance_report/balance_report_panel.tscn").instantiate()
	add_child(balance_panel)
	balance_panel._series_spin.value = 15
	balance_panel._label_edit.text = "Rodada da Ferramenta (Teste)"
	balance_panel._on_run_pressed()
	print("  Ferramenta de Balanceamento rodou e gravou o arquivo de verdade? %s (esperado: true)" % str(
		FileAccess.file_exists(SimulationReportService.BALANCE_REPORT_PATH)
	))
	balance_panel.queue_free()

	var observatorio_panel: Control = load("res://scenes/city/panels/observatorio_panel.tscn").instantiate()
	add_child(observatorio_panel)
	print("  Observatório mostra o Relatório gerado pela ferramenta (não gera nada sozinho)? %s (esperado: true)" % str(
		_panel_contains_text(observatorio_panel, "Rodada da Ferramenta (Teste)")
	))
	observatorio_panel.queue_free()

	# Confirma a prioridade: com um Catálogo já salvo em disco,
	# WorldBootstrap deve CARREGAR esse arquivo em vez de gerar ao vivo.
	WorldDatabase.current_season_id = ""
	WorldBootstrap.ensure_world_loaded()
	print("  Com um Catálogo já em disco, WorldBootstrap carrega o arquivo em vez de gerar ao vivo? %s (esperado: true, 'Temporada de Teste da Ferramenta')" % str(
		WorldDatabase.get_current_season().season_id == "Temporada de Teste da Ferramenta"
	))


## Validação FUNCIONAL do WorldBootstrap: carrega um Mundo de verdade
## (escala de desenvolvimento, não a oficial), confirma que os 3
## Territórios existem com Trilha própria, que o Catálogo tem conteúdo
## real (não vazio), e que chamar de novo não recria nada (idempotente).
func _validate_world_bootstrap() -> void:
	print("[World] Validando WorldBootstrap...")

	# Reseta a Temporada atual antes de testar — testes anteriores
	# (ex: _validate_world_database()) já registram e ativam a própria
	# Temporada de teste, o que faria o "return" antecipado de
	# ensure_world_loaded() (idempotente de propósito) pular a geração
	# que este teste especificamente quer validar.
	WorldDatabase.current_season_id = ""

	WorldBootstrap.ensure_world_loaded()
	var season: Season = WorldDatabase.get_season(WorldBootstrap.DEV_SEASON_ID)
	print("  Temporada de desenvolvimento carregada? %s (esperado: true)" % str(season != null))
	print("  Território atual é o carregado? %s (esperado: true)" % str(
		WorldDatabase.get_current_season() == season
	))

	var imperio: Territory = season.get_territory_by_faction("Império")
	print("  Território do Império existe, com Trilha própria? %s (esperado: true)" % str(
		imperio != null and season.get_trilha(imperio.id) != null
	))

	var normal_entries: Array[EnemyArmyEntry] = season.enemy_catalog.get_entries("Império", EnemyArmyEntry.Category.NORMAL)
	print("  Catálogo tem Exércitos Normais de verdade pro Império? %s (%d entradas, esperado: true, > 0)" % [
		str(not normal_entries.is_empty()), normal_entries.size()
	])

	var region_2_entries: Array[EnemyArmyEntry] = season.enemy_catalog.get_entries_for_region("Império", EnemyArmyEntry.Category.NORMAL, 2)
	var region_3_entries: Array[EnemyArmyEntry] = season.enemy_catalog.get_entries_for_region("Império", EnemyArmyEntry.Category.NORMAL, 3)
	print("  Região II e Região III também têm conteúdo de verdade (não só Região I)? %s (%d, %d entradas, esperado: true, > 0, > 0)" % [
		str(not region_2_entries.is_empty() and not region_3_entries.is_empty()), region_2_entries.size(), region_3_entries.size()
	])

	# Exceção das Primeiras Fases (PvE.md): Fases 1-10 -> só Comum/Tier
	# I; Fase 11 em diante -> nunca sorteia do lote Iniciante.
	var beginner_entry: EnemyArmyEntry = EnemyArmySelector.select(
		season.enemy_catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 5, 12345, null
	)
	var all_comum_tier1: bool = true
	for card: CardResource in beginner_entry.cards:
		if card.rarity != "Comum" or card.tier != 1:
			all_comum_tier1 = false
	print("  Fase 5 (dentro de 1-10) -> Exército inimigo é só Comum, Tier I? %s (esperado: true)" % str(
		beginner_entry != null and all_comum_tier1
	))

	var normal_fase_entry: EnemyArmyEntry = EnemyArmySelector.select(
		season.enemy_catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 500, 12345, null
	)
	print("  Fase 500 (fora de 1-10) -> nunca sorteia do lote Iniciante? %s (esperado: true)" % str(
		normal_fase_entry != null and not normal_fase_entry.is_beginner_fase
	))

	var season_count_before: int = WorldDatabase.seasons.size()
	WorldBootstrap.ensure_world_loaded()
	print("  Chamar de novo não recria o Mundo (idempotente)? %s (esperado: true)" % str(
		WorldDatabase.seasons.size() == season_count_before
	))


## Validação FUNCIONAL (sem renderização) de "Iniciar Nova Expedição"
## na janela de PvE — o fluxo completo, ponta a ponta: escolher
## Território, abrir o Editor de Exército como overlay (sem trocar de
## cena), montar um Exército de verdade, receber via "army_ready"
## (método nomeado, não lambda — ver aviso em army_editor_panel.gd),
## e iniciar a Expedição de verdade quando o Squad atinge o tamanho
## exigido (1 Exército, único caso possível hoje: primeira vez no
## Território — replay_count nunca incrementado ainda).
func _validate_pve_panel_start_new_expedition() -> void:
	print("[PvE] Validando 'Iniciar Nova Expedição' via UI...")

	var kingdom: Kingdom = KingdomState.kingdom

	var commander := CommanderResource.new()
	commander.commander_name = "UI Nova Expedição Comandante 222111"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, commander)

	var cheap_cards: Array[CardResource] = []
	for card: CardResource in GameDatabase.cards:
		if card.rarity == "Comum" and cheap_cards.size() < 9:
			cheap_cards.append(kingdom.acquire_card_from_catalog(card))

	var panel: Control = load("res://scenes/command_center/panels/pve_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("  Território carregado aparece na tela? %s | Squad exigido para a 1ª vez: %d (esperado: true, 1)" % [
		str(panel._new_expedition_territory != null),
		Squad.required_size(kingdom.get_territory_completion_count(panel._new_expedition_territory.id))
	])

	panel._on_add_army_to_new_expedition_pressed()
	var editor: ArmyEditorPanel = panel._army_editor_overlay
	print("  'Adicionar Exército' abriu o Editor como overlay (mesma cena, sem troca)? %s (esperado: true)" % str(editor != null)
	)

	editor._selected_commander = commander
	for card: CardResource in cheap_cards:
		editor._on_card_toggled(true, card)
	editor._on_montar_pressed()
	editor._on_concluir_pressed()  # formation_count=5 -> precisa concluir pra emitir army_ready
	await get_tree().process_frame  # a limpeza do overlay agora é adiada (call_deferred), precisa de 1 frame

	print("  Após montar o Exército -> Squad pendente recebeu de verdade (via método nomeado)? %s | Overlay fechou sozinho? %s (esperado: true, true)" % [
		str(panel._pending_squad_armies.size() == 1), str(panel._army_editor_overlay == null)
	])

	var expeditions_before: int = kingdom.active_expeditions.size()
	panel._on_start_new_expedition_pressed()
	print("  'Iniciar Expedição' criou uma Expedição real? %s (%d -> %d, esperado: true)" % [
		str(kingdom.active_expeditions.size() > expeditions_before), expeditions_before, kingdom.active_expeditions.size()
	])

	var new_expedition: ExpeditionRuntime = kingdom.active_expeditions[-1]
	var result: PhaseResult = new_expedition.attempt_current_fase()
	print("  A Expedição recém-criada roda um combate real (contra o Catálogo gerado, não mais calibrado pra perder de propósito)? %s | Vitória? %s (esperado: true, indefinido — depende da força real do Exército de teste)" % [
		str(result != null), str(result.victory if result != null else "N/A")
	])

	panel.queue_free()


## Validação FUNCIONAL do Kit Inicial do Reino
## (COMMAND_CENTER_RECRUITMENT.md, "Kit Inicial do Reino"): as 3
## opções (uma por Facção, 9 cartas Comuns Tier I diferentes entre si,
## Comandante sem Doutrina), a escolha efetivando de verdade (nasce
## Ativo, Exército já formado), a trava de uso único, e a tela
## aparecendo primeiro na Cidade — só uma vez.
## Validação FUNCIONAL da Doutrina do Comandante (COMMANDER_GENERATION.md/
## COMMANDER_RESTRICTIONS.md/COMMANDER_EFFECTS.md): Doutrina ligada de
## verdade nos 2 geradores, Restrição bloqueando com mensagem clara
## (estática e de Campo de Batalha), Efeito de Ataque aplicado de
## verdade em combate real, bloqueio real no PvE (sem gastar Energia),
## e round-trip de save/load.
## Validação FUNCIONAL (sem renderização) da tela de Exércitos: lista
## os já formados, "Criar Novo Exército" abre o Editor 3x3 de verdade
## como overlay, e "Desfazer" libera Comandante e cartas de verdade.
## Validação FUNCIONAL do fluxo real "Usar Exército já formado" no
## PvE: sem isso, uma vez que o único Comandante do jogador já lidera
## um Exército (ex: Kit Inicial), não sobrava ninguém livre pra montar
## um novo, e a tela ficava vazia sem explicação nem alternativa.
## Validação FUNCIONAL da Mina Inicial ativando sem Guarnição nenhuma
## (MINES.md) e do GameRuntime.sync() agora sendo chamado de verdade
## pelas telas reais (antes só rodava nos meus testes, nunca no jogo
## de verdade — confirmado pelo próprio comentário de GameRuntime.gd).
## Validação FUNCIONAL do MiningEfficiencyEstimator — roda em paralelo
## de verdade (WorkerThreadPool), confirma que não trava, não perde
## nem duplica permutações, e o resultado bate certinho.
##
## True se o teste pesado de Estimativa Incremental de Eficiência
## (F-003, ~4 minutos) deve rodar nesta execução — opt-in via
## argumento de linha de comando, pra não pesar toda execução normal
## de bootstrap.tscn com um teste específico de Minas. Usa
## OS.get_cmdline_user_args() (argumentos depois de "--", o canal
## reservado do Godot para argumentos do próprio jogo/script — nunca
## interpretado pelo motor) — nenhuma outra checagem de ambiente é
## necessária. Exemplo de uso:
## godot --headless --path Game res://scenes/bootstrap/bootstrap.tscn -- --mining-estimation
func _should_run_mining_estimation_test() -> bool:
	return OS.get_cmdline_user_args().has("--mining-estimation")


## Validação FUNCIONAL da Estimativa Incremental de Eficiência final
## (MINES.md, "Cálculo Incremental por Amostragem", F-003): distribuição
## exata dos 5 blocos somando 18.144, unicidade de FORMAÇÃO EFETIVA
## (nunca de permutação bruta — colapso da Máquina de Guerra), exclusão
## de Suporte-na-Posição-5 antes de contar/registrar, esgotamento do
## universo bruto, reaproveitamento de Eficiência por assinatura da
## Guarnição, correção do crédito de produção com Eficiência
## desconhecida, o fluxo real do botão (assíncrono, nunca trava),
## avanço em segundo plano via GameRuntime.sync() sem tarefas
## pendentes órfãs, e persistência real (save/load). Opt-in — ver
## _should_run_mining_estimation_test(); continua totalmente intacta
## e chamável explicitamente a qualquer momento (diretamente, ou via
## bootstrap.tscn com `-- --mining-estimation`).
func _validate_mining_incremental_estimation() -> void:
	print("[Minas] Validando a Estimativa Incremental final (5 blocos, batalhas únicas e válidas, F-003)...")

	# --- Distribuição exata dos 5 blocos, somando exatamente 18.144 ---
	var block_targets: Array[int] = []
	var block_sum: int = 0
	for i in range(MiningCycleResolver.HIGH_CONFIDENCE_BLOCKS):
		var target: int = MiningCycleResolver._block_target(i)
		block_targets.append(target)
		block_sum += target
	print("  Distribuição exata dos 5 blocos: %s (esperado: [3628, 3629, 3629, 3629, 3629]) | Soma: %d (esperado: 18144)" % [
		str(block_targets), block_sum
	])

	var mina := Mina.new(700, "Império")
	MiningCycleResolver.start_estimation(mina, 42)
	var unique_indices: Dictionary = {}
	for index: int in mina.efficiency_permutation_order:
		unique_indices[index] = true
	print("  Ordem embaralhada tem as 362.880 permutações brutas, cada uma exatamente uma vez? %s (%d únicas, esperado: true, 362880) | Cursor começa em 0? %s" % [
		str(unique_indices.size() == MiningCycleResolver.TOTAL_PERMUTATIONS), unique_indices.size(), str(mina.efficiency_permutation_cursor == 0)
	])

	# --- Colapso da Máquina de Guerra: duas permutações BRUTAS
	# diferentes (Máquina de Guerra em posições diferentes), mesma
	# ordem relativa das demais 8 cartas -> mesma chave EFETIVA ---
	var mdg_reference_cards: Array[CardResource] = [
		_build_combat_card("MdG-Ref", "Máquina de Guerra", 100, 100, 20),
		_build_combat_card("Ref-CQC-1", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("Ref-CQC-2", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("Ref-CQC-3", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("Ref-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("Ref-Distancia-2", "À Distância", 80, 70, 10),
		_build_combat_card("Ref-Barreira", "Barreira", 50, 120, 60),
		_build_combat_card("Ref-Mago", "Mago", 90, 60, 0),
		_build_combat_card("Ref-Suporte", "Suporte", 30, 80, 10),
	]
	var mdg_index_by_card: Dictionary = {}
	for i in range(mdg_reference_cards.size()):
		mdg_index_by_card[mdg_reference_cards[i]] = i

	var perm_a: Array = mdg_reference_cards.duplicate()  # Máquina de Guerra no início (índice 0)
	var perm_b: Array = mdg_reference_cards.slice(1) + [mdg_reference_cards[0]]  # Máquina de Guerra no fim; resto na MESMA ordem relativa
	var key_a: String = MiningCycleResolver._effective_formation_key(perm_a, mdg_index_by_card)
	var key_b: String = MiningCycleResolver._effective_formation_key(perm_b, mdg_index_by_card)
	print("  2 permutações brutas com a Máquina de Guerra em índices diferentes, mesma ordem relativa das demais -> mesma chave efetiva? %s ('%s' == '%s', esperado: true)" % [
		str(key_a == key_b), key_a, key_b
	])

	# --- _build_next_batch(): unicidade real dentro de um lote, e o
	# set de "vistas" cresce exatamente pelo tamanho do lote (só
	# formações SELECIONADAS entram — nunca as apenas inspecionadas) ---
	var mdg_mina := Mina.new(800, "Império")
	mdg_mina.reference_cards = mdg_reference_cards
	var reference_commander_mdg := CommanderResource.new()
	reference_commander_mdg.commander_name = "Chefe de Mina (Teste MdG)"
	mdg_mina.reference_commander = reference_commander_mdg
	MiningCycleResolver.start_estimation(mdg_mina, 999)

	var small_batch: Array = MiningCycleResolver._build_next_batch(mdg_mina, 50)
	var batch_keys: Dictionary = {}
	for permutation: Array in small_batch:
		batch_keys[MiningCycleResolver._effective_formation_key(permutation, mdg_index_by_card)] = true
	print("  Lote de 50 formações únicas e válidas -> nenhuma chave repetida dentro do lote? %s (%d chaves distintas, esperado: true, 50) | Set de vistas da Mina == tamanho do lote? %s (%d, esperado: 50)" % [
		str(batch_keys.size() == small_batch.size()), batch_keys.size(),
		str(mdg_mina.efficiency_seen_formation_keys.size() == small_batch.size()), mdg_mina.efficiency_seen_formation_keys.size()
	])
	print("  Cursor avançou (>= tamanho do lote, pode ser maior por causa de duplicatas/colapso da Máquina de Guerra descartadas)? %s (%d, esperado: >= 50) | Nunca excede o universo bruto? %s" % [
		str(mdg_mina.efficiency_permutation_cursor >= small_batch.size()), mdg_mina.efficiency_permutation_cursor,
		str(mdg_mina.efficiency_permutation_cursor <= MiningCycleResolver.TOTAL_PERMUTATIONS)
	])

	# --- Suporte na Posição 5 + esgotamento do universo bruto: 1
	# Suporte, sem Máquina de Guerra -> exatamente 1/9 das 362.880
	# permutações brutas têm o Suporte na Posição 5 (inválidas);
	# pedir mais que o universo válido força o esgotamento total do
	# cursor, sem fabricar formações extras. ---
	var s5_reference_cards: Array[CardResource] = [
		_build_combat_card("S5-CQC-1", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("S5-CQC-2", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("S5-CQC-3", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("S5-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("S5-Suporte", "Suporte", 30, 80, 10),
		_build_combat_card("S5-Distancia-2", "À Distância", 80, 70, 10),
		_build_combat_card("S5-Barreira", "Barreira", 50, 120, 60),
		_build_combat_card("S5-Mago", "Mago", 90, 60, 0),
		_build_combat_card("S5-Distancia-3", "À Distância", 80, 70, 10),
	]
	var s5_mina := Mina.new(801, "Império")
	s5_mina.reference_cards = s5_reference_cards
	var reference_commander_s5 := CommanderResource.new()
	reference_commander_s5.commander_name = "Chefe de Mina (Teste Suporte@5)"
	s5_mina.reference_commander = reference_commander_s5
	MiningCycleResolver.start_estimation(s5_mina, 1000)

	var s5_batch: Array = MiningCycleResolver._build_next_batch(s5_mina, 400000)  # bem mais que o universo válido inteiro -> força esgotamento
	var expected_valid_no_machine: int = MiningCycleResolver.TOTAL_PERMUTATIONS * 8 / 9  # 1/9 tem o Suporte na Posição 5 (9 cartas, sem Máquina de Guerra, cada uma igualmente provável em cada posição)
	print("  1 Suporte, sem Máquina de Guerra, pedindo mais que o universo inteiro -> cursor esgota exatamente em 362.880? %s (%d) | Formações válidas encontradas == esperado (8/9 do total)? %s (%d, esperado: %d)" % [
		str(s5_mina.efficiency_permutation_cursor == MiningCycleResolver.TOTAL_PERMUTATIONS), s5_mina.efficiency_permutation_cursor,
		str(s5_batch.size() == expected_valid_no_machine), s5_batch.size(), expected_valid_no_machine
	])
	print("  Nenhuma formação fabricada além do universo válido real (lote == set de vistas, sem repetição nem padding)? %s (%d == %d, esperado: true)" % [
		str(s5_batch.size() == s5_mina.efficiency_seen_formation_keys.size()), s5_batch.size(), s5_mina.efficiency_seen_formation_keys.size()
	])

	# --- Universo válido MENOR que o alvo de 18.144: 5 Suportes + 1
	# Máquina de Guerra -> só 8! = 40.320 formações efetivas possíveis
	# (colapso da Máquina de Guerra), das quais 5/8 têm algum Suporte
	# na Posição 5 (inválidas) -> só 40.320 * 3/8 = 15.120 válidas,
	# abaixo do alvo de 18.144. Simula todas, sem repetir nenhuma. ---
	var small_universe_cards: Array[CardResource] = [
		_build_combat_card("SU-MdG", "Máquina de Guerra", 100, 100, 20),
		_build_combat_card("SU-Suporte-1", "Suporte", 30, 80, 10),
		_build_combat_card("SU-Suporte-2", "Suporte", 30, 80, 10),
		_build_combat_card("SU-Suporte-3", "Suporte", 30, 80, 10),
		_build_combat_card("SU-Suporte-4", "Suporte", 30, 80, 10),
		_build_combat_card("SU-Suporte-5", "Suporte", 30, 80, 10),
		_build_combat_card("SU-CQC", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("SU-Barreira", "Barreira", 50, 120, 60),
		_build_combat_card("SU-Distancia", "À Distância", 80, 70, 10),
	]
	var su_mina := Mina.new(802, "Império")
	su_mina.reference_cards = small_universe_cards
	var reference_commander_su := CommanderResource.new()
	reference_commander_su.commander_name = "Chefe de Mina (Teste Universo Pequeno)"
	su_mina.reference_commander = reference_commander_su
	MiningCycleResolver.start_estimation(su_mina, 1001)

	var su_batch: Array = MiningCycleResolver._build_next_batch(su_mina, MiningCycleResolver.TARGET_VALID_BATTLES)  # pede os 18.144 cheios
	var expected_small_universe: int = 15120
	print("  Universo válido MENOR que 18.144 (5 Suportes + 1 Máquina de Guerra) -> simula exatamente o universo disponível, sem repetir? %s (%d encontradas, esperado: %d, < 18144) | Universo esgotado? %s" % [
		str(su_batch.size() == expected_small_universe), su_batch.size(), expected_small_universe,
		str(su_mina.efficiency_permutation_cursor == MiningCycleResolver.TOTAL_PERMUTATIONS)
	])

	# --- Reaproveitamento de Eficiência por assinatura da Guarnição ---
	var signature_commander := CommanderResource.new()
	signature_commander.instance_id = 5001
	signature_commander.accumulated_xp = 100
	var signature_cards: Array[CardResource] = []
	for i in range(9):
		var c := _build_combat_card("Assinatura-%d" % i, "Corpo a Corpo", 100, 100, 20)
		c.instance_id = 6000 + i
		signature_cards.append(c)
	var signature_army := Army.new()
	signature_army.commander = signature_commander
	signature_army.cards = signature_cards

	var signature_mina := Mina.new(803, "Império")
	signature_mina.cycle_efficiency = 0.72
	MiningCycleResolver.capture_garrison_signature(signature_mina, signature_army)
	print("  Assinatura idêntica (mesmo Comandante/XP/cartas/Tier) -> Eficiência reaproveitável? %s (esperado: true)" % str(
		MiningCycleResolver.garrison_signature_matches(signature_mina, signature_army)
	))
	signature_cards[0].tier = 3
	print("  Mudança de Tier numa única carta -> Eficiência NÃO é mais reaproveitável? %s (esperado: true)" % str(
		not MiningCycleResolver.garrison_signature_matches(signature_mina, signature_army)
	))
	signature_cards[0].tier = 1
	signature_commander.accumulated_xp = 500
	print("  Mudança de XP do Comandante -> Eficiência NÃO é mais reaproveitável? %s (esperado: true)" % str(
		not MiningCycleResolver.garrison_signature_matches(signature_mina, signature_army)
	))

	# --- Correção do crédito de produção com Eficiência desconhecida (-1.0) ---
	var credit_kingdom := Kingdom.new()
	credit_kingdom.deposito_level = 1
	var credit_mina := Mina.new(1600, "Império")
	credit_mina.region = 1
	credit_mina.structure_level = 1
	credit_mina.cycle_started_unix = GameClock.now_unix()
	credit_mina.cycle_efficiency = -1.0  # 1º bloco ainda em andamento
	var before_credit_unix: int = credit_mina.last_production_credit_unix
	MiningProductionResolver.credit(credit_mina, credit_kingdom, GameClock.now_unix() + 3600 * 3)
	print("  Crédito de produção com Eficiência desconhecida -> janela NÃO é marcada como creditada (fica pendente, não perdida)? %s (%d -> %d, esperado: iguais)" % [
		str(credit_mina.last_production_credit_unix == before_credit_unix), before_credit_unix, credit_mina.last_production_credit_unix
	])
	credit_mina.cycle_efficiency = 1.0  # Eficiência real chega
	MiningProductionResolver.credit(credit_mina, credit_kingdom, GameClock.now_unix() + 3600 * 3)
	print("  Assim que a Eficiência real existe -> a janela pendente inteira (3h) é cobrada de uma vez, sem perda? %s (%d, esperado: > %d)" % [
		str(credit_mina.last_production_credit_unix > before_credit_unix), credit_mina.last_production_credit_unix, before_credit_unix
	])

	# --- Persistência (save/load) ---
	# IMPORTANTE (F-003, escopo aprovado): KingdomSaveService/
	# kingdom_save_service.gd está FORA do escopo de arquivos aprovado
	# para esta tarefa, e o próprio save/load do jogo não está
	# conectado a nenhum caminho de produção hoje (só testes chamam
	# KingdomSaveService.save()/load_into() em todo o repositório) —
	# ver relatório final F-003, item "save/load". Por isso, os campos
	# NOVOS desta reformulação (efficiency_permutation_cursor,
	# efficiency_current_block_valid_count, efficiency_seen_formation_keys,
	# efficiency_source_*) ainda NÃO são persistidos por
	# kingdom_save_service.gd — só os campos que já existiam antes
	# desta tarefa continuam corretamente persistidos (confirmado
	# abaixo). Corrigir isso pertence a uma tarefa própria, exigida
	# apenas quando save/load for de fato ligado à produção.
	mina.efficiency_blocks_completed = 3
	mina.efficiency_wins = 12000
	mina.efficiency_ties = 2000
	var save_kingdom := Kingdom.new()
	var mina_list: Array[Mina] = [mina]
	save_kingdom.territory_mines["Território de Teste da Estimativa"] = mina_list
	KingdomSaveService.save(save_kingdom)
	var loaded_kingdom := Kingdom.new()
	KingdomSaveService.load_into(loaded_kingdom)
	var loaded_mina: Mina = loaded_kingdom.territory_mines["Território de Teste da Estimativa"][0]
	print("  Round-trip salvar/carregar preserva os campos JÁ existentes antes desta tarefa (blocos, vitórias, ordem embaralhada)? %s (esperado: true)" % str(
		loaded_mina.efficiency_blocks_completed == 3 and loaded_mina.efficiency_wins == 12000 and
		loaded_mina.efficiency_permutation_order.size() == MiningCycleResolver.TOTAL_PERMUTATIONS
	))
	print("  (Nota F-003) Campos novos desta reformulação NÃO são persistidos ainda — save/load não está em nenhum caminho de produção hoje; cursor após carregar: %d (esperado: 0, valor padrão — não é um bug desta tarefa, é escopo aprovado)" % loaded_mina.efficiency_permutation_cursor)

	# --- O fluxo real do botão: nunca trava, avança sozinho em segundo
	# plano, sem tarefas pendentes órfãs ---
	var kingdom: Kingdom = KingdomState.kingdom
	var guarnicao_commander := CommanderResource.new()
	guarnicao_commander.commander_name = "Comandante da Guarnição (Teste)"
	guarnicao_commander.faction = "Império"
	kingdom.add_commander(guarnicao_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, guarnicao_commander)
	# Legionário Imperial (Comum, Soldo 1) — 9 cópias somam 9 de Soldo,
	# dentro do teto até de "Recruta" (18). 9x "Campeão Imperial"
	# (Épica, Soldo 4 cada = 36) excede até o teto máximo de
	# "Lorde-Comandante" (32) — inválida pra batalha em QUALQUER
	# Patente, o que impediria este teste de nunca completar um bloco.
	var legionario_template: CardResource = GameDatabase.get_card("Legionário Imperial")
	var guarnicao_cards: Array[CardResource] = []
	for i in range(9):
		guarnicao_cards.append(kingdom.acquire_card_from_catalog(legionario_template))
	var guarnicao_army: Army = kingdom.form_army(guarnicao_commander, guarnicao_cards)
	print("  (diagnóstico) Guarnição de teste pronta para batalha? %s (esperado: true)" % str(guarnicao_army.is_ready_for_battle()))

	var real_mina := Mina.new(701, "Império")
	real_mina.conquer()
	real_mina.reference_cards = CampaignTestFixtures.build_campaign_enemy_army().cards
	real_mina.reference_commander = CampaignTestFixtures.build_campaign_enemy_army().commander
	real_mina.assign_guarnicao(guarnicao_army)
	kingdom.territory_mines["Território Real de Teste"] = [real_mina]

	# Trava de Ciclo: a Guarnição não pode ser trocada com um Ciclo
	# ativo (ARMY.md, "Trava de Edição por Modo de Jogo").
	var panel: Control = load("res://scenes/command_center/panels/minas_panel.tscn").instantiate()
	add_child(panel)
	panel._on_start_cycle_pressed(real_mina)
	print("  Clicar 'Iniciar Ciclo' retorna NA HORA, sem travar (dispara em segundo plano)? %s | Eficiência ainda desconhecida nesse instante? %s (esperado: true, true)" % [
		str(not real_mina.efficiency_pending_task_ids.is_empty()), str(real_mina.cycle_efficiency < 0.0)
	])
	print("  Ciclo ativo -> Guarnição travada contra edição/reatribuição? %s (esperado: true)" % str(
		kingdom.is_army_locked_for_editing(guarnicao_army)["locked"]
	))

	# Espera de verdade o 1º bloco terminar (produção real, ~3.628
	# combates — pode demorar de fato aqui, sem paralelismo real numa
	# sandbox de 1 núcleo só; numa máquina com vários núcleos de
	# verdade, isso é bem mais rápido, exatamente o ponto de tudo isso).
	var attempts: int = 0
	while real_mina.efficiency_blocks_completed < 1 and attempts < 700:
		GameRuntime.sync(kingdom, GameClock.now_unix())
		OS.delay_msec(250)
		attempts += 1
	print("  O 1º bloco termina de verdade e atualiza a Eficiência real (não mais -1)? %s (%.1f%%, %d bloco(s), esperado: true, 0-100%%, >= 1)" % [
		str(real_mina.cycle_efficiency >= 0.0), real_mina.cycle_efficiency * 100.0, real_mina.efficiency_blocks_completed
	])
	print("  wins + ties + losses acumulados == batalhas válidas do bloco 1 (nunca conta permutação inválida/duplicada)? %s (%d, esperado: %d)" % [
		str(real_mina.efficiency_wins + real_mina.efficiency_ties + real_mina.efficiency_losses == MiningCycleResolver._block_target(0)),
		real_mina.efficiency_wins + real_mina.efficiency_ties + real_mina.efficiency_losses, MiningCycleResolver._block_target(0)
	])

	# GameRuntime.sync() já dispara o bloco 2 sozinho, em segundo
	# plano, na MESMA chamada que fechou o bloco 1 (continuação
	# correta e esperada — não é o bug de "Invalid Task ID"; drenar
	# bloco a bloco até o 5º levaria ~5x mais tempo só para este
	# teste). Em vez disso, trava a estimativa DESTE mina de teste no
	# estado terminal agora (has_high_confidence() -> true), o que faz
	# GameRuntime.sync() parar de agendar trabalho novo pra ela a
	# partir da próxima chamada — e drena o que QUER que já esteja
	# pendente neste exato instante (0 ou 1 lote, nunca mais, já que
	# nenhum lote novo será disparado depois disso), pra não deixar
	# nenhuma tarefa órfã no WorkerThreadPool quando o painel for
	# destruído a seguir (erro de encerramento, não o problema de
	# "Invalid Task ID" já confirmado/corrigido).
	real_mina.efficiency_blocks_completed = MiningCycleResolver.HIGH_CONFIDENCE_BLOCKS
	var drain_attempts: int = 0
	while not real_mina.efficiency_pending_task_ids.is_empty() and drain_attempts < 700:
		MiningCycleResolver.poll_pending_block(real_mina)
		OS.delay_msec(250)
		drain_attempts += 1
	print("  Travar a estimativa em alta confiança impede novos lotes, e o que já estava em voo é drenado sem deixar tarefa órfã? %s (esperado: true — vazio)" % str(
		real_mina.efficiency_pending_task_ids.is_empty()
	))

	panel.queue_free()


func _validate_mine_activation_and_time_sync() -> void:
	print("[Minas/Sync] Validando ativação da Mina Inicial sem Guarnição, e GameRuntime.sync() ligado nas telas...")

	# Reino isolado (fresco) pra este teste — o Reino compartilhado já
	# acumulou Minas de testes anteriores, possivelmente com Ciclo já
	# ativo, o que esconderia o botão "Ativar" sem isso.
	var fresh_mine_kingdom := Kingdom.new()
	fresh_mine_kingdom.create_initial_mines()
	var mina: Mina = fresh_mine_kingdom.initial_mines[0]

	var old_kingdom_for_mine_test: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_mine_kingdom

	var panel: Control = load("res://scenes/command_center/panels/minas_panel.tscn").instantiate()
	add_child(panel)

	print("  Mina Inicial NÃO mostra rótulo de Guarnição (não se aplica)? %s (esperado: true)" % str(
		not _panel_contains_text(panel, "Guarnição: nenhuma designada.")
	))
	print("  Mostra o botão 'Ativar' em vez de exigir Exército/Guarnição? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Ativar")
	))

	panel._on_activate_initial_mine_pressed(mina)
	print("  Ativar de verdade inicia o Ciclo, 100%% de eficiência, sem Guarnição nenhuma? %s (%.1f%%, esperado: true, 100.0)" % [
		str(mina.is_cycle_active(GameClock.now_unix()) and mina.cycle_efficiency == 1.0), mina.cycle_efficiency * 100.0
	])
	panel.queue_free()
	KingdomState.kingdom = old_kingdom_for_mine_test

	# --- GameRuntime.sync() ligado de verdade na tela de Comandantes ---
	# Reino isolado de novo — o compartilhado pode já ter os Slots do
	# Centro de Recrutamento todos cheios de testes anteriores, o que
	# esconderia um Candidato novo aparecendo.
	var fresh_recruitment_kingdom := Kingdom.new()
	fresh_recruitment_kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix() - 10  # já devia ter vencido
	fresh_recruitment_kingdom.sync_recruitment_center_slots()
	var slot_before: CommanderResource = fresh_recruitment_kingdom.recruitment_center_slots[0] if not fresh_recruitment_kingdom.recruitment_center_slots.is_empty() else null

	var old_kingdom_for_recruitment_test: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_recruitment_kingdom

	var comandantes_panel: Control = load("res://scenes/command_center/panels/comandantes_panel.tscn").instantiate()
	add_child(comandantes_panel)
	var slot_after: CommanderResource = fresh_recruitment_kingdom.recruitment_center_slots[0] if not fresh_recruitment_kingdom.recruitment_center_slots.is_empty() else null
	print("  Abrir a tela de Comandantes com o cooldown já vencido -> gera um Candidato de verdade sozinho (sync real)? %s (esperado: true)" % str(
		slot_after != slot_before and slot_after != null
	))
	comandantes_panel.queue_free()
	KingdomState.kingdom = old_kingdom_for_recruitment_test


## Validação FUNCIONAL do botão "Cancelar" do Editor de Exército — sem
## isso, uma vez aberto (ex: "Criar Novo Exército"), não tinha como
## sair sem completar o fluxo inteiro.
func _validate_army_editor_cancel() -> void:
	print("[UI] Validando 'Cancelar' no Editor de Exército...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Cancelar)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, commander)

	var champion_template: CardResource = GameDatabase.get_card("Campeão Imperial")
	var owned_cards: Array[CardResource] = []
	for i in range(9):
		owned_cards.append(kingdom.acquire_card_from_catalog(champion_template))

	var editor: ArmyEditorPanel = load("res://scenes/army/army_editor_panel.tscn").instantiate()
	add_child(editor)
	editor._selected_commander = commander
	editor._selected_cards = owned_cards
	editor._on_montar_pressed()  # já passou da Fase 1 -> form_army() já rodou, Comandante/cartas já EM_EXERCITO

	_test_cancelled_fired = false
	editor.cancelled.connect(_on_test_cancelled)
	editor._on_cancel_pressed()

	print("  Cancelar depois de já ter formado (Fase 2) -> libera o Comandante e as cartas de verdade? %s | Sinal disparou (via método nomeado)? %s (esperado: true, true)" % [
		str(commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE and owned_cards[0].ownership_status == CardResource.OwnershipStatus.LIVRE),
		str(_test_cancelled_fired)
	])
	editor.queue_free()


func _validate_pve_use_existing_army() -> void:
	print("[PvE] Validando 'Usar Exército já formado' (sem precisar criar um novo)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Único de Teste"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, insistir não ajuda se o Reino compartilhado já esgotou o Nível de testes anteriores
	CommandCenterResolver.move_to_active(kingdom, commander)

	var champion_template: CardResource = GameDatabase.get_card("Campeão Imperial")
	var owned_cards: Array[CardResource] = []
	for i in range(9):
		owned_cards.append(kingdom.acquire_card_from_catalog(champion_template))
	var existing_army: Army = kingdom.form_army(commander, owned_cards)
	existing_army.initialize_energy(1)

	# Agora o único Comandante já está EM_EXERCITO — exatamente o
	# cenário que travava antes: nenhum Comandante livre pra montar um
	# Exército novo pelo Editor.
	var panel: Control = load("res://scenes/command_center/panels/pve_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("  O Exército já formado aparece na lista pra usar direto, sem precisar do Editor? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Comandante Único de Teste")
	))

	panel._on_use_existing_army_pressed(existing_army)
	print("  'Usar no Squad' adiciona de verdade ao Squad pendente? %s (esperado: true, 1)" % str(
		panel._pending_squad_armies.size() == 1
	))

	panel.queue_free()


## Validação FUNCIONAL com CLIQUE REAL DE VERDADE (emit_signal, nunca
## chamar a função do handler direto) — os testes anteriores desta
## suíte nunca pegaram o crash relatado justamente porque só chamavam
## as funções direto, o que não passa pela máquina de sinais real do
## Godot (e por isso nunca testou CONNECT_DEFERRED de verdade).
func _validate_real_button_clicks_no_crash() -> void:
	print("[UI] Validando cliques REAIS (emit_signal, não chamada direta) não crasham mais...")

	var kingdom: Kingdom = KingdomState.kingdom

	# --- Exércitos: "Desfazer" clicado de verdade ---
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Clique Real"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	kingdom.form_army(commander, cards)

	var exercitos_panel: Control = load("res://scenes/city/panels/exercitos_panel.tscn").instantiate()
	add_child(exercitos_panel)
	var disband_button: Button = _find_button_by_exact_text(exercitos_panel, "Desfazer")
	var armies_before_click: int = kingdom.armies.size()
	if disband_button != null:
		disband_button.emit_signal("pressed")
		await get_tree().process_frame  # CONNECT_DEFERRED -> o handler só roda no fim do frame
		await get_tree().process_frame
	# O botão em si É liberado de propósito (o "Desfazer" bem-sucedido
	# reconstrói a tela inteira) — não é isso que prova sucesso. O que
	# prova é o Exército ter sumido de verdade, sem nenhum SCRIPT
	# ERROR no meio do caminho (senão o teste inteiro pararia aqui).
	print("  Clique REAL em 'Desfazer' (emit_signal, não chamada direta) -> rodou até o fim, Exército sumiu de verdade, sem crash? %s (esperado: true)" % str(
		kingdom.armies.size() == armies_before_click - 1
	))
	exercitos_panel.queue_free()
	await get_tree().process_frame


func _validate_exercitos_panel() -> void:
	print("[UI] Validando ExercitosPanel...")

	var kingdom: Kingdom = KingdomState.kingdom
	var armies_before: int = kingdom.armies.size()

	var panel: Control = load("res://scenes/city/panels/exercitos_panel.tscn").instantiate()
	add_child(panel)

	panel._on_create_army_pressed()
	print("  'Criar Novo Exército' abriu o Editor 3x3 como overlay? %s (esperado: true)" % str(
		panel._editor_overlay != null
	))

	# Cenário real do crash reportado: clicar "Desfazer" numa fileira
	# JÁ EXISTENTE enquanto o Editor ainda está aberto por cima (o
	# overlay não bloqueia o resto da tela) — refresh() rodava e
	# tentava liberar o Editor no meio da própria execução dele.
	var victim_commander := CommanderResource.new()
	victim_commander.commander_name = "Comandante Vítima do Teste"
	victim_commander.faction = "Império"
	kingdom.add_commander(victim_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, victim_commander)
	var victim_cards: Array[CardResource] = []
	var recruit_template: CardResource = GameDatabase.get_card("Recruta Imperial") if GameDatabase.get_card("Recruta Imperial") != null else GameDatabase.cards[0]
	for i in range(9):
		victim_cards.append(kingdom.acquire_card_from_catalog(recruit_template))
	var victim_army: Army = kingdom.form_army(victim_commander, victim_cards)

	panel._on_disband_pressed(victim_army)
	print("  Clicar 'Desfazer' numa fileira ENQUANTO o Editor está aberto por cima -> não trava o jogo, e o Editor continua vivo? %s (esperado: true)" % str(
		panel._editor_overlay != null
	))

	# Monta um Exército de verdade pelo Editor (mesmo fluxo real).
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Exércitos)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1  # garante capacidade real, direto — activate_next() só ativa Infraestrutura já existente no Nível atual do CdC, que o Reino compartilhado já pode ter esgotado
	CommandCenterResolver.move_to_active(kingdom, commander)

	var champion_template: CardResource = GameDatabase.get_card("Campeão Imperial")
	var owned_cards: Array[CardResource] = []
	for i in range(9):
		owned_cards.append(kingdom.acquire_card_from_catalog(champion_template))

	panel._editor_overlay._selected_commander = commander
	panel._editor_overlay._selected_cards = owned_cards
	panel._editor_overlay._on_montar_pressed()
	panel._editor_overlay._on_concluir_pressed()
	await get_tree().process_frame  # a limpeza do overlay agora é adiada (call_deferred), precisa de 1 frame

	print("  Exército formado de verdade pelo Editor -> apareceu na lista? %s (%d -> %d, esperado: true)" % [
		str(kingdom.armies.size() == armies_before + 1), armies_before, kingdom.armies.size()
	])
	print("  'Criar Novo Exército' fecha o overlay sozinho depois de formar? %s (esperado: true)" % str(
		panel._editor_overlay == null
	))

	var new_army: Army = kingdom.armies[-1]
	panel._on_disband_pressed(new_army)
	print("  'Desfazer' libera o Comandante e as cartas de verdade? %s | Exército some da lista? %s (esperado: true, true)" % [
		str(commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE), str(not kingdom.armies.has(new_army))
	])

	panel.queue_free()


## Migração PARCIAL (Etapa 19): o núcleo determinístico e totalmente
## local desta validação (Restrição estática, Restrição de Campo de
## Batalha, Efeito de Ataque em combate, bloqueio real no PvE) foi
## migrado para test_commander_doctrine.gd — mesmo padrão das migrações
## parciais da Etapa 15. As duas partes abaixo permanecem aqui
## deliberadamente: a checagem de que RecruitmentCenterResolver liga a
## Doutrina de verdade (RNG global sem seed em CommanderGenerator, achado
## de arquitetura ainda não resolvido) e o round-trip de salvar/carregar
## via KingdomSaveService (caminho fixo de disco, decisão de sandbox
## adiada). A construção da Doutrina/Comandante abaixo existe só para
## alimentar esse round-trip.
func _validate_commander_doctrine() -> void:
	print("[Doutrina] Validando Restrição, Efeito de Combate e o bloqueio real no PvE...")

	# --- Doutrina ligada de verdade nos geradores ---
	var recruit: CommanderResource = RecruitmentCenterResolver._generate_candidate()
	print("  RecruitmentCenterResolver liga a Doutrina de verdade no Comandante gerado? %s (esperado: true)" % str(
		recruit.doctrine != null
	))

	# --- Restrição estática: construção manual e determinística ---
	var restriction_max_class: CommanderRestrictionResource = _find_by_code_test(GameDatabase.commander_restrictions, "RS020")  # Máximo 2 da Classe
	var requirement_faction: CommanderRequirementResource = _find_by_code_test(GameDatabase.commander_requirements, "R001")  # Pelo menos 2 da Facção
	var target_faction: CommanderTargetResource = _find_by_code_test(GameDatabase.commander_targets, "A001")
	var effect_attack: CommanderEffectResource = _find_by_code_test(GameDatabase.commander_effects, "E001")
	var value_attack: CommanderValueResource = _find_by_code_test(GameDatabase.commander_values, "V003")  # +20%

	var doctrine := CommanderDoctrine.new()
	doctrine.faction = "Império"
	doctrine.restriction = restriction_max_class
	doctrine.restriction_param = "Melee"
	doctrine.requirement = requirement_faction
	doctrine.requirement_param = ""
	doctrine.target = target_faction
	doctrine.effect = effect_attack
	doctrine.value = value_attack
	doctrine.rarity_score = 10

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste da Doutrina"
	commander.faction = "Império"
	commander.doctrine = doctrine

	# --- Round-trip de save/load ---
	var save_kingdom := Kingdom.new()
	save_kingdom.add_commander(commander, GameClock.now_unix())
	KingdomSaveService.save(save_kingdom)
	var loaded_kingdom := Kingdom.new()
	KingdomSaveService.load_into(loaded_kingdom)
	var loaded_commander: CommanderResource = loaded_kingdom.commanders[0]
	print("  Round-trip salvar/carregar preserva a Doutrina (Restrição, Efeito, Valor)? %s (esperado: true)" % str(
		loaded_commander.doctrine != null and loaded_commander.doctrine.restriction.code == "RS020" and
		loaded_commander.doctrine.effect.code == "E001" and loaded_commander.doctrine.value.code == "V003"
	))


func _find_by_code_test(bank: Array, code: String) -> Variant:
	for entry: Variant in bank:
		if entry.code == code:
			return entry
	return null


func _validate_starter_kit() -> void:
	print("[Kit Inicial] Validando StarterKitResolver e a tela...")

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	print("  3 opções, uma por Facção? %s (esperado: true)" % str(
		options.size() == 3 and options[0]["faction"] != options[1]["faction"] and options[1]["faction"] != options[2]["faction"]
	))

	var first_option: Dictionary = options[0]
	var card_names: Array[String] = []
	for card: CardResource in first_option["cards"]:
		card_names.append(card.card_name)
	var unique_names: Dictionary = {}
	for name: String in card_names:
		unique_names[name] = true
	print("  9 cartas, todas Comuns, Tier I, diferentes entre si? %s (%d únicas de %d, esperado: true, 9, 9)" % [
		str(unique_names.size() == 9 and card_names.size() == 9), unique_names.size(), card_names.size()
	])

	var commander: CommanderResource = first_option["commander"]
	print("  Comandante criado corretamente (Patente Recruta, nome funcional, Facção certa)? %s (esperado: true)" % str(
		commander.accumulated_xp == 0 and commander.commander_name == "Comandante Recruta" and commander.faction == first_option["faction"]
	))

	# --- Escolher de verdade ---
	var kingdom: Kingdom = KingdomState.kingdom
	var was_already_used: bool = kingdom.starter_kit_used
	if not was_already_used:
		var armies_before: int = kingdom.armies.size()
		var result: Dictionary = StarterKitResolver.choose_option(kingdom, first_option, GameClock.now_unix())
		print("  Escolher a opção -> sucesso? %s | Comandante Ativo? %s | Exército formado de verdade? %s (esperado: true, true, true)" % [
			str(result["success"]),
			str(commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE),
			str(kingdom.armies.size() == armies_before + 1)
		])

		var kit_army: Army = kingdom.armies[-1]
		print("  O Exército do Kit Inicial já nasce com Energia de verdade (não 0/0)? %s (%d/%d, esperado: true, > 0)" % [
			str(kit_army.max_energy > 0 and kit_army.current_energy > 0), kit_army.current_energy, kit_army.max_energy
		])

		var second_attempt: Dictionary = StarterKitResolver.choose_option(kingdom, options[1], GameClock.now_unix())
		print("  Tentar escolher de novo (já usado) -> bloqueado corretamente? %s (esperado: true, already_used)" % str(
			not second_attempt["success"] and second_attempt["reason"] == "already_used"
		))
	else:
		print("  (Kingdom compartilhado já tinha usado o Kit Inicial antes deste teste — pulando a parte de escolha, sem problema.)")

	# --- A tela, num Reino separado (fresco, nunca usou o Kit) ---
	var fresh_kingdom := Kingdom.new()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = fresh_kingdom

	var panel: Control = load("res://scenes/city/city_panel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	# F-045: as duas checagens abaixo usavam _panel_contains_text() com
	# textos literais ("Escolha seu Comandante inicial", "Recursos de
	# Construção") que não existem mais em nenhuma tela — StarterKitPanel
	# (F-030) passou a ser composição de imagem (INICIALIZAÇÃO.png) sem
	# nenhum Label dinâmico, e a Cidade normal nunca teve esse texto
	# literal. Corrigido para uma checagem ESTRUTURAL (presença/ausência
	# de um filho StarterKitPanel), mesmo padrão já usado logo abaixo
	# pra achar kit_child — não altera nenhuma tela, só a forma como o
	# teste verifica o que já está na árvore.
	var kit_child: StarterKitPanel = null
	for child in panel.get_children():
		if child is StarterKitPanel:
			kit_child = child

	print("  Reino novo -> a Cidade mostra o Kit Inicial primeiro, antes de qualquer outra coisa? %s (esperado: true)" % str(
		kit_child != null
	))

	# Simula a escolha clicando (via método, mesmo padrão de sempre).
	kit_child._on_choose_pressed(kit_child._options[0])
	await get_tree().process_frame

	var kit_child_after: StarterKitPanel = null
	for child in panel.get_children():
		if child is StarterKitPanel:
			kit_child_after = child

	print("  Após escolher -> a Cidade normal aparece, e não pede o Kit de novo? %s (esperado: true)" % str(
		kit_child_after == null
	))

	panel.queue_free()
	KingdomState.kingdom = old_kingdom


## Validação FUNCIONAL (sem renderização) da Tela da Cidade: monta a
## tela num Reino de teste, confirma os números do Resumo/Recursos, e
## testa "Evoluir" de verdade (Capital, via recursos; Depósito, via PG).
func _validate_city_panel() -> void:
	print("[UI] Validando CityPanel (funcional, sem renderização)...")

	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom

	kingdom.credit_raw_resource("ferro_negro", 100000, 999999999)
	kingdom.credit_raw_resource("cristais_arcanos", 100000, 999999999)
	kingdom.credit_raw_resource("essencia_vital", 100000, 999999999)
	kingdom.add_generation_points(1000)

	var panel_scene: PackedScene = load("res://scenes/city/city_panel.tscn")
	var panel: Control = panel_scene.instantiate()
	add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("  Painel mostra o Nível de Conta e os Recursos? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Nível de Conta") and _panel_contains_text(panel, "Ferro Negro")
	))

	var capital_before: int = kingdom.capital_level
	panel._on_evolve_institutional_pressed(InstitutionalConstructionConfig.Building.CAPITAL)
	print("  Evoluir Capital -> Nível subiu de verdade? %s (%d -> %d, esperado: true)" % [
		str(kingdom.capital_level > capital_before), capital_before, kingdom.capital_level
	])

	var deposito_before: int = kingdom.deposito_level
	panel._on_evolve_deposit_pressed()
	print("  Evoluir Depósito (em PG) -> Nível subiu de verdade? %s (%d -> %d, esperado: true)" % [
		str(kingdom.deposito_level > deposito_before), deposito_before, kingdom.deposito_level
	])

	# ART-002: clicar num prédio (mesmo efeito de _on_hitbox_gui_input —
	# seta _selected_building_key e chama _update_contextual_panel(),
	# igual um clique real faria) continua abrindo o painel contextual
	# com o texto/Nível/botão de sempre, agora com a ilustração real do
	# prédio por cima. Testa os 7 prédios com arte integrada, um a um,
	# confirmando que NENHUM caminho de asset está quebrado e que o
	# texto que já funcionava continua aparecendo.
	var building_keys_and_expected_text: Dictionary = {
		"capital": "Capital",
		"biblioteca": "Biblioteca",
		"observatorio": "Observatório",
		"academia": "Academia",
		"centro_de_comando": "Centro de Comando",
		"depositos": "Depósitos",
		"nucleo_de_energia": "Núcleo de Energia",
	}
	var all_illustrations_ok: bool = true
	var all_text_preserved: bool = true
	for key: String in building_keys_and_expected_text:
		panel._selected_building_key = key
		panel._update_contextual_panel()
		var illustration: TextureRect = null
		for child in panel._contextual_content.get_children():
			if child is TextureRect:
				illustration = child
				break
		if illustration == null or illustration.texture == null or not illustration.visible:
			all_illustrations_ok = false
			print("  ART-002 MISMATCH: prédio '%s' sem ilustração visível/carregada." % key)
		if not _panel_contains_text(panel, building_keys_and_expected_text[key]):
			all_text_preserved = false
			print("  ART-002 MISMATCH: prédio '%s' perdeu o texto '%s' que já aparecia antes." % [key, building_keys_and_expected_text[key]])
	print("  ART-002: os 7 prédios da Cidade mostram a ilustração real (nenhum caminho quebrado)? %s | texto/Nível/botão de sempre continua aparecendo? %s (esperado: true, true)" % [
		str(all_illustrations_ok), str(all_text_preserved)
	])

	panel.queue_free()

	# F-009: "Evoluir" sem recursos suficientes precisa mostrar algo
	# visível pro jogador — antes só existia um print() no console.
	# Reino isolado (fresco, sem recursos nenhum) pra garantir que a
	# rejeição realmente acontece.
	var poor_kingdom := Kingdom.new()
	poor_kingdom.starter_kit_used = true  # pula a tela do Kit Inicial, direto pra Cidade normal
	var old_kingdom_for_evolve_test: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = poor_kingdom
	var poor_panel: Control = panel_scene.instantiate()
	add_child(poor_panel)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var capital_level_before_rejection: int = poor_kingdom.capital_level
	poor_panel._on_evolve_institutional_pressed(InstitutionalConstructionConfig.Building.CAPITAL)
	print("  Evoluir sem recursos suficientes -> Nível NÃO mudou (%d -> %d)? %s | mensagem visível na tela? %s (esperado: true, true, F-009)" % [
		capital_level_before_rejection, poor_kingdom.capital_level, str(poor_kingdom.capital_level == capital_level_before_rejection),
		str(_panel_contains_text(poor_panel, "Não foi possível evoluir"))
	])

	poor_panel.queue_free()
	KingdomState.kingdom = old_kingdom_for_evolve_test


## Validação da Sprint 32.5: executa uma Expedição real de ponta a
## ponta — Cidade -> Trilha -> Fase -> EnemyArmySelector -> Combate ->
## Resultado -> próxima Fase -> ... — sem nenhuma intervenção manual
## além da configuração inicial, atravessando múltiplas Fases, pelo
## menos um Chefe Normal e vários Acampamentos. Gera um history_log completo,
## servindo como teste de integração de alto nível de toda a
## infraestrutura de Campanha construída até aqui.
func _validate_full_expedition_run() -> void:
	print("[Expedição Completa] Executando uma Expedição real de ponta a ponta (Sprint 32.5)...")

	# Catálogo em escala de desenvolvimento (ver Sprint 31) — os números
	# oficiais permanecem em SeasonConfig como padrão.
	var config := SeasonConfig.new()
	config.season_id = "Season01-QA"
	config.seed_value = 2024
	config.normal_army_count = 10
	config.chefe_normal_count = 5
	config.chefe_regional_mina_generated_count = 8
	config.chefe_regional_mina_kept_count = 6
	config.simulations_per_army = 5
	config.benchmark_size = 3
	config.min_rarity_score_exclusive = 10

	var catalog: SeasonCatalog = SeasonPipeline.run(
		config, GameDatabase.cards,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Catálogo da Temporada '%s' pronto." % catalog.season_id)

	var territory := Territory.new("Territorio-Imperio-01", "Império")
	var trilha := Trilha.new(territory.id)
	var registry := RegionalCommanderRegistry.new()

	# Exército do jogador: forte o suficiente para progredir de forma
	# confiável contra o Catálogo em escala de desenvolvimento, permitindo
	# que o teste avance dezenas de Fases em tempo razoável.
	var champion_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1, "β": 1, "γ": 1, "δ": 1, "ε": 1})
	champion_army.initialize_energy(1)
	var squad := Squad.new([champion_army])

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 4242,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	# Sem nenhum artifício de Energia: a política padrão
	# (AGUARDAR_RECUPERACAO_TOTAL) recupera 100% da Energia em cada
	# Acampamento real gerado pela Trilha — o mesmo mecanismo que
	# qualquer Expedição de verdade usaria.

	# O loop manual que existia aqui (while + contador) foi substituído
	# pelo orquestrador real — exatamente para provar que ele é o
	# consumidor correto de ExpeditionRuntime, não apenas mais uma
	# conveniência de teste.
	var stop_reason: ExpeditionSession.StopReason = ExpeditionSession.run(expedition, 150)

	print("  ExpeditionSession parou por: %s. Fase atual: %d. Status: %s." % [
		ExpeditionSession.StopReason.keys()[stop_reason], expedition.current_fase, str(expedition.status)
	])
	print("  --- Log completo da Expedição ---")
	for line: String in expedition.history_log:
		print("    " + line)
	print("  --- Fim do history_log ---")


## Validação da Sprint 33 (World Database): confirma o registro de uma
## Season completa (Território + Trilha + Catálogo de Exércitos) via
## WorldDatabase, e que ExpeditionRuntime pode ser alimentado por
## Território/Trilha vindos do banco em vez de instanciados ad-hoc.
## Também confirma a correção do achado do KingdomState (Kingdom agora
## realmente instanciado pelo autoload reservado desde a Sprint 1).
func _validate_world_database() -> void:
	print("[WorldDatabase] Validando registro de Temporada (Território + Trilha + Catálogo)...")

	# Kingdom agora é de fato instanciado pelo autoload KingdomState
	# (achado corrigido nesta Sprint ao registrar WorldDatabase).
	print("  KingdomState.kingdom instanciado? %s (esperado: true)" % str(KingdomState.kingdom != null))

	# Catálogo em escala de desenvolvimento (mesmo padrão das Sprints 31/32.5).
	var config := SeasonConfig.new()
	config.season_id = "Season01"
	config.seed_value = 99
	config.normal_army_count = 5
	config.chefe_normal_count = 2
	config.chefe_regional_mina_generated_count = 4
	config.chefe_regional_mina_kept_count = 3
	config.simulations_per_army = 3
	config.benchmark_size = 2
	config.min_rarity_score_exclusive = 10

	var enemy_catalog: SeasonCatalog = SeasonPipeline.run(
		config, GameDatabase.cards,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	var season := Season.new("Season01")
	season.enemy_catalog = enemy_catalog

	var territory_imperio := Territory.new("territorio_imperio", "Império")
	season.add_territory(territory_imperio, Trilha.new(territory_imperio.id))

	var territory_natureza := Territory.new("territorio_natureza", "Natureza")
	season.add_territory(territory_natureza, Trilha.new(territory_natureza.id))

	WorldDatabase.register_season(season)
	WorldDatabase.set_current_season("Season01")

	print("  Temporada registrada: %s | Territórios: %d" % [
		WorldDatabase.get_current_season().season_id, WorldDatabase.get_current_season().territories.size()
	])

	var retrieved_territory: Territory = WorldDatabase.get_current_season().get_territory_by_faction("Império")
	print("  Território do Império recuperado por Facção? %s (esperado: true, id=%s)" % [
		str(retrieved_territory != null), (retrieved_territory.id if retrieved_territory else "null")
	])

	# ExpeditionRuntime alimentado por Território/Trilha vindos do banco,
	# não mais instanciados ad-hoc.
	var retrieved_trilha: Trilha = WorldDatabase.get_current_season().get_trilha(retrieved_territory.id)
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, retrieved_trilha, retrieved_territory, WorldDatabase.get_current_season().enemy_catalog,
		registry, 321, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition.attempt_current_fase()
	# Esta fixture (1 Campeão + 8 Dummies de ATK 0) foi calibrada para
	# vencer especificamente build_campaign_enemy_army() (o inimigo fixo
	# fraco usado nos testes de retry) — não para qualquer inimigo real
	# gerado pelo Pipeline. Contra um Exército Normal procedural, o
	# resultado (vitória/derrota) não é garantido, e não é isso que este
	# teste valida: o objetivo aqui é confirmar que Território/Trilha
	# vindos do WorldDatabase alimentam a Expedição corretamente, não o
	# resultado do combate em si.
	print("  Expedição criada a partir do WorldDatabase avançou -> Fase atual: %d (esperado: 1 ou 2, ambos válidos — o que importa é não ter travado)" % expedition.current_fase)


## Validação da Sprint 34 (Game Runtime): primeiro fluxo real e completo
## do jogo — Reino (KingdomState.kingdom, já inicializado) -> Temporada
## registrada no WorldDatabase -> Território/Trilha -> Expedição criada
## e registrada de volta no Reino -> primeira Fase/Combate. Nenhum
## objeto é instanciado ad-hoc fora do Reino/Mundo já existentes.
func _validate_game_runtime() -> void:
	print("[GameRuntime] Validando o primeiro fluxo completo (Reino -> Mundo -> Expedição -> Combate)...")

	var kingdom: Kingdom = KingdomState.kingdom
	print("  Reino em uso: KingdomState.kingdom (%s)" % str(kingdom != null))

	# A Temporada já foi registrada em _validate_world_database(); aqui
	# apenas consultamos a mesma Temporada ativa, sem gerar nada de novo.
	var season: Season = WorldDatabase.get_current_season()
	print("  Temporada ativa consultada: %s" % season.season_id)

	# Forma um Exército e um Squad, e os adiciona ao Reino (Kingdom
	# passa a possuí-los, como já validado na Sprint do Kingdom).
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	kingdom.add_army(army)
	var squad := Squad.new([army])
	kingdom.add_squad(squad)

	var territory: Territory = season.get_territory_by_faction("Império")

	var start_result: Dictionary = GameRuntime.start_new_expedition(
		kingdom, season.season_id, territory.id, squad, 2025,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var expedition: ExpeditionRuntime = start_result["expedition"]

	print("  Expedição criada e registrada no Reino? %s (esperado: true — sucesso reportado E de fato presente em active_expeditions)" % str(
		start_result["success"] and kingdom.active_expeditions.has(expedition)
	))

	var result: PhaseResult = expedition.attempt_current_fase()
	print("  Primeiro combate resolvido -> vitória: %s | Fase atual: %d" % [
		(str(result.victory) if result != null else "null"), expedition.current_fase
	])
	print("  Fluxo completo: Cidade -> Reino -> Temporada -> Território/Trilha -> Expedição -> Fase 1 -> Combate. Concluído sem nenhum objeto ad-hoc fora de Kingdom/WorldDatabase.")


## Validação de Salvar/Carregar o Reino: monta um Reino com Comandante,
## Carta, Exército (com Formação e Energia), Squad, Mina conquistada,
## Recursos, oferta de Recrutamento pendente e Registro de Comandante
## Regional recrutado — salva em disco, carrega num Reino novo, e
## confirma que tudo voltou igual.
func _validate_kingdom_save_load() -> void:
	print("[Save/Load] Validando salvar e carregar o Reino...")

	var original := Kingdom.new()
	original.energy_nucleus_level = 3
	original.add_fragment("Império", 42)
	original.set_progress_flag("tutorial_concluido")

	var commander := CommanderResource.new()
	commander.commander_name = "General de Teste"
	commander.faction = "Império"
	commander.accumulated_xp = 500
	original.add_commander(commander)

	var real_card: CardResource = GameDatabase.get_card("Legionário Imperial")
	original.add_card(real_card)

	var army: Army = CampaignTestFixtures.build_campaign_test_army({"β": 1})
	army.army_name = "Exército Salvo"
	army.initialize_energy(3)
	army.current_energy = 77
	original.add_army(army)

	var squad := Squad.new([army])
	original.add_squad(squad)

	original.regional_commander_registry.recruit("Império", 1)

	var regional_commander := CommanderResource.new()
	regional_commander.commander_name = "Senhor da Guerra Pendente"
	original.offer_recruitment(regional_commander, GameClock.now_unix())

	original.create_initial_mines()
	var trilha := Trilha.new("territorio-save-teste")
	var mines: Array[Mina] = original.generate_territory_mines("territorio-save-teste", "Império", trilha, 55)
	mines[0].conquer()

	var saved: bool = KingdomSaveService.save(original)
	print("  Salvou com sucesso? %s" % str(saved))
	print("  Existe save em disco? %s (esperado: true)" % str(KingdomSaveService.has_save()))

	var loaded := Kingdom.new()
	var loaded_ok: bool = KingdomSaveService.load_into(loaded)
	print("  Carregou com sucesso? %s (esperado: true)" % str(loaded_ok))

	# Ponto real de integração: toda vez que um Reino é carregado, purga
	# Ofertas de Recrutamento vencidas usando o tempo real atual — é
	# assim que uma Oferta expira mesmo que o jogador tenha ficado dias
	# sem abrir o jogo, sem depender de nenhum processo rodando em segundo
	# plano enquanto o jogo estava fechado.
	RecruitmentResolver.purge_expired_offers(loaded, GameClock.now_unix())
	print("  Purga de expiração pós-carregamento executada (oferta recém-salva não deve ter expirado).")

	print("  Nível do Núcleo: %d (esperado: 3) | Fragmentos Império: %d (esperado: 42) | Flag tutorial: %s (esperado: true)" % [
		loaded.energy_nucleus_level, loaded.get_fragment("Império"), str(loaded.has_progress_flag("tutorial_concluido"))
	])
	print("  Comandantes: %d | Cartas: %d | Exércitos: %d | Squads: %d (esperado: 1, 1, 1, 1)" % [
		loaded.commanders.size(), loaded.cards.size(), loaded.armies.size(), loaded.squads.size()
	])
	print("  Comandante recuperado: %s (XP: %d, esperado: 500)" % [
		loaded.commanders[0].commander_name, loaded.commanders[0].accumulated_xp
	])
	print("  Exército recuperado: %s | Energia atual: %d (esperado: Exército Salvo, 77)" % [
		loaded.armies[0].army_name, loaded.armies[0].current_energy
	])
	print("  Formação 'β' preservada (Campeão na posição 1)? %s (esperado: true)" % str(
		loaded.armies[0].formations.has("β") and loaded.armies[0].formations["β"][0].card_name == "Campeão"
	))
	print("  Squad ainda referencia o mesmo Exército carregado (não uma cópia solta)? %s (esperado: true)" % str(
		loaded.squads[0].armies[0] == loaded.armies[0]
	))
	print("  Império/Região 1 continua marcado como recrutado? %s (esperado: true)" % str(
		loaded.regional_commander_registry.is_recruited("Império", 1)
	))
	print("  Oferta de Recrutamento pendente preservada? %s (esperado: true, nome=%s)" % [
		str(loaded.pending_recruitment_offers.size() == 1),
		(loaded.pending_recruitment_offers[0].commander.commander_name if not loaded.pending_recruitment_offers.is_empty() else "nenhuma")
	])
	print("  Minas Iniciais: %d | Minas do Território: %d, primeira conquistada? %s (esperado: 3, 5, true)" % [
		loaded.initial_mines.size(),
		loaded.territory_mines.get("territorio-save-teste", []).size(),
		str(loaded.territory_mines.get("territorio-save-teste", [])[0].conquered if loaded.territory_mines.has("territorio-save-teste") else false)
	])
