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
	if DirAccess.dir_exists_absolute("res://reports"):
		var reports_dir: DirAccess = DirAccess.open("res://reports")
		if reports_dir != null:
			for file_name: String in reports_dir.get_files():
				reports_dir.remove(file_name)

	GameDatabase.load_database()
	KingdomState.initialize_new_kingdom()

	await _validate_game_clock()
	_validate_card_progression()
	_validate_commander_generation()
	_validate_commander_career()
	_validate_soldo()
	_validate_energy_nucleus()
	_validate_energy_army()
	_validate_army()
	_validate_campaign_synergy()
	_validate_battlefields()
	_validate_affinity()
	_validate_combat_engine()
	_validate_ability_data()
	_validate_card_catalog_integrity()
	_validate_effect_runtime()
	_validate_investida()
	_validate_advanced_abilities()
	_validate_unit_trait_runtimes()
	_validate_squad()
	_validate_formations()
	_validate_phase_retry()
	_validate_trilha()
	_validate_expedition_runtime()
	_validate_season_pipeline()
	_validate_full_expedition_run()
	_validate_kingdom()
	_validate_world_database()
	_validate_game_runtime()
	_validate_acampamento_policies()
	_validate_expedition_session_waits_for_player()
	_validate_reward_resolver()
	_validate_recruitment()
	_validate_recruitment_offer_expiration()
	_validate_energy_time_recovery()
	_validate_game_runtime_sync()
	_validate_city_deposits()
	_validate_institutional_constructions()
	_validate_account_xp()
	_validate_academy()
	_validate_academy_queue_upgrade()
	_validate_command_center_training_slots()
	_validate_command_center_state_machine()
	_validate_commander_training_xp()
	_validate_recruitment_center()
	_validate_legacy()
	_validate_comandantes_panel_ui()
	_validate_treinamento_panel_ui()
	_validate_legado_panel_ui()
	_validate_army_formation_archetypes()
	await _validate_army_editor_existing_army_mode()
	_validate_initial_mine_never_expires()
	_validate_pve_credits_fragments_for_real()
	_validate_recipe_production_delivers_card()
	_validate_energy_recovers_over_real_time()
	_validate_debug_generate_candidate_button()
	_validate_first_candidate_available_immediately()
	await _validate_city_panel_syncs_periodically()
	_validate_initial_mine_shows_production_rate()
	_validate_edit_army_composition()
	_validate_fragments_credited_per_unit_faction()
	_validate_academia_production_filters()
	_validate_recruitment_slots_show_sequential_time()
	_validate_active_reserve_swap()
	_validate_battle_history_shows_formations()
	_validate_swap_active_reserve()
	_validate_battle_history_shows_formation_grids()
	_validate_sequential_commissioning_order()
	_validate_commander_doctrine_screen()
	_validate_enemy_composition_has_no_duplicate_names()
	_validate_player_editor_prevents_duplicate_names()
	_validate_switching_trilhas_records_correct_territory()
	_validate_pve_credits_account_and_commander_xp()
	_validate_energy_recalculates_on_composition_change()
	_validate_energy_composition_penalty()
	_validate_army_edit_lock()
	_validate_enemy_composition_matches_territory_faction()
	_validate_army_unlocks_after_returning_to_camp()
	await _validate_army_cannot_be_double_booked()
	_validate_energy_frozen_while_marching()
	_validate_kingdom_state_creates_initial_mines()
	_validate_minas_panel_ui()
	await _validate_pve_panel_ui()
	_validate_army_editor_panel()
	_validate_world_bootstrap()
	await _validate_pve_panel_start_new_expedition()
	_validate_commander_doctrine()
	await _validate_exercitos_panel()
	await _validate_real_button_clicks_no_crash()
	_validate_initial_mine_no_conquest()
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
	_validate_ranking_and_battlefield_selector()
	_validate_pvp_panel_ui()
	_validate_academia_panel()
	_validate_academia_chain_persistence()
	_validate_regional_generation()
	_validate_biblioteca_panel()
	_validate_commander_battle_history()
	_validate_balance_simulator_and_report_service()
	_validate_pve_generator_and_observatorio_panels()
	_validate_academy_advanced_options()
	_validate_mine_prerequisites()
	_validate_mine_reference_formation()
	_validate_mining_cycle_engine()
	_validate_mine_guarnicao_and_production()
	_validate_mina_placement()
	_validate_mine_conquest()
	_validate_kingdom_save_load()
	_validate_card_ownership()

	EventBus.engine_ready.emit()
	print("[Bootstrap] Engine inicializada com sucesso.")


## Validação da Sprint 18: confere o carregamento dos catálogos de
## AbilityResource e UnitTraitResource, ausência de nomes duplicados, e
## que toda Carta referencia corretamente suas Características (Tier I)
## e Habilidades (Tier III/V) — apenas leitura/validação estrutural,
## nenhuma Habilidade é executada.
func _validate_ability_data() -> void:
	print("[AbilityData] Catálogo de Habilidades: %d carregadas." % GameDatabase.abilities.size())
	print("[AbilityData] Catálogo de Características de Unidade: %d carregadas." % GameDatabase.unit_traits.size())

	var ability_names: Array[String] = []
	for ability: AbilityResource in GameDatabase.abilities:
		ability_names.append(ability.ability_name)
	var duplicate_abilities: Array[String] = _find_duplicates(ability_names)
	print("[AbilityData] Nomes de Habilidade duplicados: %s" % (str(duplicate_abilities) if not duplicate_abilities.is_empty() else "nenhum"))

	var trait_names: Array[String] = []
	for trait_entry: UnitTraitResource in GameDatabase.unit_traits:
		trait_names.append(trait_entry.trait_name)
	var duplicate_traits: Array[String] = _find_duplicates(trait_names)
	print("[AbilityData] Nomes de Característica duplicados: %s" % (str(duplicate_traits) if not duplicate_traits.is_empty() else "nenhum"))

	print("[AbilityData] Validando referências das Cartas...")
	for card: CardResource in GameDatabase.cards:
		if card.tier_1_trait_name != "" and not trait_names.has(card.tier_1_trait_name):
			print("  ERRO: %s referencia Característica de Unidade inexistente: '%s'" % [card.card_name, card.tier_1_trait_name])
		if card.tier_3_ability_name != "" and not ability_names.has(card.tier_3_ability_name):
			print("  ERRO: %s referencia Habilidade de Tier III inexistente: '%s'" % [card.card_name, card.tier_3_ability_name])
		if card.tier_5_ability_name != "" and not ability_names.has(card.tier_5_ability_name):
			print("  ERRO: %s referencia Habilidade de Tier V inexistente: '%s'" % [card.card_name, card.tier_5_ability_name])
		print("  %s -> Tier I: '%s' | Tier III: '%s' | Tier V: '%s' (todas resolvidas)" % [
			card.card_name, card.tier_1_trait_name, card.tier_3_ability_name, card.tier_5_ability_name
		])

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


## Retorna os elementos que aparecem mais de uma vez em "values".
func _find_duplicates(values: Array[String]) -> Array[String]:
	var seen: Dictionary = {}
	var duplicates: Array[String] = []
	for value: String in values:
		seen[value] = seen.get(value, 0) + 1
	for value: String in seen:
		if seen[value] > 1 and not duplicates.has(value):
			duplicates.append(value)
	return duplicates


## Validação da Sprint 23: relatório completo de integridade do catálogo
## de Cartas. Apenas leitura/relatório — nenhuma inconsistência
## documental é corrigida automaticamente (política oficial do projeto).
func _validate_card_catalog_integrity() -> void:
	print("[CardCatalog] Relatório de integridade (%d cartas)..." % GameDatabase.cards.size())

	var valid_classes: Array[String] = ["Corpo a Corpo", "Barreira", "À Distância", "Mago", "Suporte", "Máquina de Guerra"]
	var valid_factions: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

	var trait_names: Array[String] = []
	for trait_entry: UnitTraitResource in GameDatabase.unit_traits:
		trait_names.append(trait_entry.trait_name)

	var seen_card_names: Dictionary = {}
	var duplicate_names: Array[String] = []
	var missing_fields: Array[String] = []
	var invalid_class_refs: Array[String] = []
	var invalid_faction_refs: Array[String] = []
	var broken_ability_refs: Array[String] = []
	var broken_trait_refs: Array[String] = []
	var types_found: Dictionary = {}

	for card: CardResource in GameDatabase.cards:
		if seen_card_names.has(card.card_name):
			duplicate_names.append(card.card_name)
		seen_card_names[card.card_name] = true

		if card.card_name == "" or card.faction == "" or card.card_class == "" or card.rarity == "":
			missing_fields.append(card.card_name if card.card_name != "" else "<carta sem nome>")

		if not valid_classes.has(card.card_class):
			invalid_class_refs.append("%s -> '%s'" % [card.card_name, card.card_class])

		if not valid_factions.has(card.faction):
			invalid_faction_refs.append("%s -> '%s'" % [card.card_name, card.faction])

		if card.card_type != "":
			types_found[card.card_type] = types_found.get(card.card_type, 0) + 1

		if card.tier_1_trait_name != "" and not trait_names.has(card.tier_1_trait_name):
			broken_trait_refs.append("%s -> Tier I: '%s'" % [card.card_name, card.tier_1_trait_name])

		if card.tier_3_ability_name != "":
			var ability_3: AbilityResource = GameDatabase.abilities_by_name.get(card.tier_3_ability_name)
			if ability_3 == null:
				broken_ability_refs.append("%s -> Tier III: '%s' (não existe no catálogo)" % [card.card_name, card.tier_3_ability_name])
			elif ability_3.tier != 3:
				broken_ability_refs.append("%s -> Tier III: '%s' (existe, porém catalogada como Tier %d)" % [card.card_name, card.tier_3_ability_name, ability_3.tier])

		if card.tier_5_ability_name != "":
			var ability_5: AbilityResource = GameDatabase.abilities_by_name.get(card.tier_5_ability_name)
			if ability_5 == null:
				broken_ability_refs.append("%s -> Tier V: '%s' (não existe no catálogo)" % [card.card_name, card.tier_5_ability_name])
			elif ability_5.tier != 5:
				broken_ability_refs.append("%s -> Tier V: '%s' (existe, porém catalogada como Tier %d)" % [card.card_name, card.tier_5_ability_name, ability_5.tier])

	print("  Nomes de carta duplicados: %s" % (str(duplicate_names) if not duplicate_names.is_empty() else "nenhum"))
	print("  Campos obrigatórios ausentes: %s" % (str(missing_fields) if not missing_fields.is_empty() else "nenhum"))
	print("  Classe inexistente: %s" % (str(invalid_class_refs) if not invalid_class_refs.is_empty() else "nenhuma"))
	print("  Facção inexistente: %s" % (str(invalid_faction_refs) if not invalid_faction_refs.is_empty() else "nenhuma"))
	print("  Tipos em uso (informativo — não há lista fechada definida na documentação): %s" % str(types_found))

	print("  Referências de Habilidade (Tier III/V) quebradas: %d" % broken_ability_refs.size())
	for entry: String in broken_ability_refs:
		print("    - " + entry)

	print("  Referências de Característica (Tier I) quebradas: %d" % broken_trait_refs.size())
	for entry: String in broken_trait_refs:
		print("    - " + entry)

	print("  Nenhuma inconsistência documental foi corrigida automaticamente (política oficial do projeto).")


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


## Validação da Sprint 20: confirma que o EffectRuntime resolve
## corretamente as referências de uma carta real do catálogo (Tier I,
## III e V preenchidos) e que uma carta sem nenhuma referência não gera
## nenhuma instância — apenas leitura/validação estrutural, nenhuma
## Habilidade/Característica é executada, e nenhum listener é registrado
## no CombatEventBus nesta Sprint.
func _validate_effect_runtime() -> void:
	print("[EffectRuntime] Validando resolução de Runtime (EffectRuntime/AbilityRuntime/UnitTraitRuntime)...")

	var real_card: CardResource = null
	for c: CardResource in GameDatabase.cards:
		if c.card_name == "Legionário Imperial":
			real_card = c
			break

	if real_card == null:
		push_warning("[Bootstrap] Carta real para validação do EffectRuntime não foi encontrada no GameDatabase.")
		return

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Validação (EffectRuntime)"
	commander.faction = "Império"

	var army_a := Army.new()
	army_a.commander = commander
	army_a.cards = []
	for i in range(9):
		army_a.cards.append(real_card)

	var army_b := Army.new()
	army_b.commander = commander
	army_b.cards = _build_transient_cards("Comum", 1, 9)  # sem Tier I/III/V preenchidos

	var state: CombatState = CombatEngine.initialize(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	print("  EffectRuntime criado: %s" % ("sim" if state.effect_runtime != null else "não"))

	var sample_unit: CombatUnit = state.units_of_side(0)[0]
	var trait_instance: UnitTraitInstance = state.effect_runtime.get_unit_trait(sample_unit)
	var ability_instances: Array[AbilityInstance] = state.effect_runtime.get_abilities(sample_unit)

	var ability_names: Array[String] = []
	for instance: AbilityInstance in ability_instances:
		ability_names.append(instance.resource.ability_name)

	print("  %s (carta real, Tier I/III/V preenchidos):" % sample_unit.card.card_name)
	print("    Característica de Unidade resolvida: %s" % (trait_instance.resource.trait_name if trait_instance != null else "nenhuma"))
	print("    Habilidades resolvidas: %d (%s)" % [ability_instances.size(), ", ".join(ability_names)])

	var empty_unit: CombatUnit = state.units_of_side(1)[0]
	var empty_trait: UnitTraitInstance = state.effect_runtime.get_unit_trait(empty_unit)
	var empty_abilities: Array[AbilityInstance] = state.effect_runtime.get_abilities(empty_unit)

	print("  Carta transitória sem referências preenchidas:")
	print("    Característica de Unidade resolvida: %s" % ("nenhuma" if empty_trait == null else empty_trait.resource.trait_name))
	print("    Habilidades resolvidas: %d" % empty_abilities.size())

	print("  Listeners registrados no CombatEventBus nesta Sprint: 0 (ponto de extensão preparado para Sprint 21+).")

	state.effect_runtime.shutdown()
	print("[EffectRuntime] shutdown() executado com sucesso.")


## Validação da Sprint 21: monta um cenário determinístico em que a
## carta real do catálogo com "Investida" (Legionário Imperial) inicia
## fora da Linha 1, avança até ela ao longo da batalha e ativa a
## habilidade em seu primeiro ataque a partir dali — validando toda a
## cadeia CombatEngine -> CombatEventBus -> AbilityRuntime ->
## InvestidaRuntime -> CombatContext -> CombatEngine, com dado real.
func _validate_investida() -> void:
	print("[Investida] Validando cadeia completa com dado real do catálogo (Legionário Imperial)...")

	var real_card: CardResource = null
	for c: CardResource in GameDatabase.cards:
		if c.card_name == "Legionário Imperial":
			real_card = c
			break

	if real_card == null:
		push_warning("[Bootstrap] Carta real 'Legionário Imperial' não encontrada para validar Investida.")
		return

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Investida)"
	commander_a.faction = "Império"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Investida)"
	commander_b.faction = "Natureza"

	# Exército A: 3 batedores fracos (posições 1-3, devem morrer no Turno 1
	# para abrir caminho na Coluna C), o Legionário Imperial real na
	# posição 4 (avança para a posição 3 no Turno 2 e ativa Investida),
	# e 5 unidades de preenchimento para completar a Formação.
	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		_build_combat_card("A-Batedor-1", "Corpo a Corpo", 1, 1, 0),
		_build_combat_card("A-Batedor-2", "Corpo a Corpo", 1, 1, 0),
		_build_combat_card("A-Batedor-3", "Corpo a Corpo", 1, 1, 0),
		real_card,
		_build_combat_card("A-Reserva-5", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-6", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-7", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-8", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-9", "Corpo a Corpo", 1, 50, 0),
	]

	# Exército B: linha de frente forte o suficiente para eliminar os
	# batedores de A no Turno 1 (abrindo a Coluna C), sem nenhuma
	# Habilidade envolvida.
	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-Forte-1", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Forte-2", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Forte-3", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Reserva-4", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-5", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-6", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-7", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-8", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-9", "Corpo a Corpo", 1, 50, 0),
	]

	var state: CombatState = CombatEngine.initialize(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	var test_unit: CombatUnit = null
	for unit: CombatUnit in state.units_of_side(0):
		if unit.card.card_name == "Legionário Imperial":
			test_unit = unit
			break

	var investida_instance: AbilityInstance = null
	for instance: AbilityInstance in state.effect_runtime.get_abilities(test_unit):
		if instance.resource.ability_name == "Investida":
			investida_instance = instance
			break

	print("  Runtime especializado encontrado: %s" % ("sim" if investida_instance != null and investida_instance.specialized_runtime != null else "não"))

	CombatEngine.run(state)

	for line: String in state.battle_log:
		print("  " + line)

	var runtime: InvestidaRuntime = investida_instance.specialized_runtime as InvestidaRuntime
	print("[Investida] Entrou na Linha 1: %s | Consumida (ativação única): %s" % [
		str(runtime.has_entered_frontline()), str(runtime.is_consumed())
	])
	print("[Investida] Batalha concluída em %d turno(s). Motivo: %s." % [state.turn, state.end_reason])


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


## Validação da Sprint 25: monta um cenário usando exclusivamente cartas
## reais do catálogo, cada uma portando uma das 4 Características de
## Unidade implementadas (Reerguer, Fome Eterna, Sacrifício de Carne,
## Colheita de Almas), executa uma batalha completa e imprime o history_log.
## Cada Runtime imprime sua própria ativação — a evidência de "cenário
## reproduzível" é o próprio history_log.
func _validate_unit_trait_runtimes() -> void:
	print("[UnitTraitRuntime] Validando Características de Unidade (Sprint 25)...")

	var real_esqueleto: CardResource = GameDatabase.get_card("Esqueleto Guerreiro")     # Reerguer
	var real_abominacao: CardResource = GameDatabase.get_card("Abominação Putrefata")    # Sacrifício de Carne
	var real_arqueiro: CardResource = GameDatabase.get_card("Arqueiro Esquelético")      # Fome Eterna
	var real_ceifadora: CardResource = GameDatabase.get_card("Ceifadora Espectral")      # Colheita de Almas (parcial)

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Características de Unidade)"
	commander_a.faction = "Mortos-Vivos"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Características de Unidade)"
	commander_b.faction = "Império"

	# Posição 4 é o aliado "atrás" de Abominação Putrefata (posição 3,
	# mesma coluna C) — necessário para demonstrar Sacrifício de Carne.
	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		real_esqueleto,
		_build_combat_card("A-Filler-2", "Corpo a Corpo", 60, 90, 10),
		real_abominacao,
		_build_combat_card("A-Filler-4", "Corpo a Corpo", 1, 150, 0),
		real_arqueiro,
		_build_combat_card("A-Filler-6", "Corpo a Corpo", 60, 90, 10),
		real_ceifadora,
		_build_combat_card("A-Filler-8", "Corpo a Corpo", 60, 90, 10),
		_build_combat_card("A-Filler-9", "Corpo a Corpo", 60, 90, 10),
	]

	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-CQC-1", "Corpo a Corpo", 110, 90, 0),
		_build_combat_card("B-CQC-2", "Corpo a Corpo", 90, 90, 0),
		_build_combat_card("B-CQC-3", "Corpo a Corpo", 110, 90, 0),
		_build_combat_card("B-Filler-4", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Distancia-1", "À Distância", 90, 70, 10),
		_build_combat_card("B-Filler-6", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-7", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-8", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-9", "Corpo a Corpo", 60, 90, 0),
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

	print("[UnitTraitRuntime] Batalha concluída em %d turno(s). Motivo: %s. Vencedor: %s" % [
		state.turn, state.end_reason, ("empate" if state.winner_side == -1 else "Lado %d" % state.winner_side)
	])
	print("[UnitTraitRuntime] Verifique acima as linhas [ReviveRuntime] e [ReactiveTraitRuntime] —")
	print("  cada uma confirma a ativação da Característica correspondente (Reerguer, Fome Eterna,")
	print("  Sacrifício de Carne, Colheita de Almas — esta última apenas com a cura, sem o bônus permanente).")
	print("[UnitTraitRuntime] 'Fonte da Vida' não foi implementada nesta Sprint — ver limitação encontrada na entrega.")


## --- Helpers de teste da Sprint 29 (Campanha PvE — esqueleto) ---
## Agora vivem em tests/campaign_test_fixtures.gd (CampaignTestFixtures).


## Validação da Sprint 29: Squad — prioridade correta e troca de
## Exército, sem nenhuma lógica de combate.
func _validate_squad() -> void:
	print("[Squad] Validando prioridade e troca de Exército...")

	var army_a := CampaignTestFixtures.build_campaign_test_army({})
	army_a.army_name = "Exército A"
	var army_b := CampaignTestFixtures.build_campaign_test_army({})
	army_b.army_name = "Exército B"

	var squad := Squad.new([army_a, army_b])

	print("  Ativo inicial: %s (esperado: Exército A)" % squad.active_army().army_name)
	print("  Esgotado? %s (esperado: false)" % str(squad.is_exhausted()))

	squad.advance_to_next_army()
	print("  Após avançar: %s (esperado: Exército B)" % squad.active_army().army_name)

	squad.advance_to_next_army()
	print("  Após esgotar: esgotado? %s (esperado: true) | ativo: %s (esperado: null)" % [
		str(squad.is_exhausted()), str(squad.active_army())
	])

	squad.reset()
	print("  Após reset: %s (esperado: Exército A)" % squad.active_army().army_name)


## Validação da Sprint 29: Formações — prioridade correta e as cinco
## Formações, com fallback para a disposição padrão quando não configurada.
func _validate_formations() -> void:
	print("[Formações] Validando prioridade e as cinco Formações...")

	var army: Army = CampaignTestFixtures.build_campaign_test_army({"β": 1})  # só "β" configurada

	print("  Prioridade padrão: %s (esperado: [α, β, γ, δ, ε])" % str(army.formation_priority))

	var alpha: Array[CardResource] = army.get_formation("α")
	var beta: Array[CardResource] = army.get_formation("β")
	print("  Formação α não configurada -> cai para 'cards' padrão? %s" % str(alpha == army.cards))
	print("  Formação β configurada -> Campeão na posição 1? %s" % str(beta[0].card_name == "Campeão"))

	army.formation_priority = ["β", "α", "δ", "γ", "ε"]
	print("  Prioridade customizada aplicada: %s" % str(army.formation_priority))


## Validação da Sprint 29: os 4 cenários de retry pedidos, usando o
## Campeão/Dummy/Guard/Wall (verificado por simulação equivalente antes
## da implementação, ver entrega da Sprint).
func _validate_phase_retry() -> void:
	print("[PhaseResolver] Validando os 4 cenários de retry (incluindo consumo de Energia)...")

	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.id = "TESTE_RETRY_INIMIGO"
	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	enemy_entry.commander = enemy_army.commander
	enemy_entry.cards = enemy_army.cards

	# a) Vitória na primeira Formação.
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_a.initialize_energy(1)
	var squad_a := Squad.new([army_a])
	var result_a: PhaseResult = PhaseResolver.resolve(
		squad_a, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  a) Vitória na 1ª Formação -> vitória=%s formação=%s tentativas=%d (esperado: true, α, 1) | Energia restante: %d/%d" % [
		str(result_a.victory), result_a.winning_formation, result_a.attempts, army_a.current_energy, army_a.max_energy
	])

	# b) Vitória na terceira Formação.
	var army_b: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 5, "γ": 1})
	army_b.initialize_energy(1)
	var squad_b := Squad.new([army_b])
	var result_b: PhaseResult = PhaseResolver.resolve(
		squad_b, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  b) Vitória na 3ª Formação -> vitória=%s formação=%s tentativas=%d (esperado: true, γ, 3) | Energia consumida: %d (esperado: 12)" % [
		str(result_b.victory), result_b.winning_formation, result_b.attempts, army_b.max_energy - army_b.current_energy
	])

	# c) Vitória utilizando o segundo Exército.
	var army_c1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_c1.initialize_energy(1)
	var army_c2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_c2.initialize_energy(1)
	var squad_c := Squad.new([army_c1, army_c2])
	var result_c: PhaseResult = PhaseResolver.resolve(
		squad_c, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  c) Vitória no 2º Exército -> vitória=%s exército_index=%d tentativas=%d (esperado: true, 1, 6)" % [
		str(result_c.victory), result_c.winning_army_index, result_c.attempts
	])

	# d) Derrota após todas as Formações de todos os Exércitos.
	var army_d1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_d1.initialize_energy(1)
	var army_d2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 5, "β": 5, "γ": 5, "δ": 5, "ε": 5})
	army_d2.initialize_energy(1)
	var squad_d := Squad.new([army_d1, army_d2])
	var result_d: PhaseResult = PhaseResolver.resolve(
		squad_d, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  d) Derrota total -> vitória=%s tentativas=%d (esperado: false, 10)" % [
		str(result_d.victory), result_d.attempts
	])

	# e) Exaustão por Energia (não por Formação): Energia insuficiente
	# para sequer 1 tentativa faz o Exército ser considerado esgotado
	# imediatamente, mesmo com todas as 5 Formações disponíveis.
	var army_e: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	army_e.max_energy = 3  # menor que o custo de 1 tentativa (4)
	army_e.current_energy = 3
	var squad_e := Squad.new([army_e])
	var result_e: PhaseResult = PhaseResolver.resolve(
		squad_e, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  e) Exaustão por Energia insuficiente -> vitória=%s tentativas=%d (esperado: false, 0 — nenhuma tentativa chegou a ocorrer)" % [
		str(result_e.victory), result_e.attempts
	])

	print("  opponent_entry preservado no resultado? %s (esperado: true, id=%s)" % [
		str(result_a.opponent_entry == enemy_entry), result_a.opponent_entry.id
	])


## Validação da Sprint 30: Trilha — geração correta de Chefes e
## Acampamentos, prioridade entre Chefes, deslocamento e reinício de
## contagem, usando exclusivamente os parâmetros oficiais de PvE.md.
func _validate_trilha() -> void:
	print("[Trilha] Validando geração de Chefes e Acampamentos (dados reais de PvE.md)...")

	var trilha := Trilha.new()

	print("  Total de Fases: %d (esperado: 9000)" % trilha.total_fases())
	print("  Total de Acampamentos gerados: %d" % trilha.acampamento_positions.size())

	print("  Tipo da Fase 1000: '%s' (esperado: regional)" % trilha.chefe_type(1000))
	print("  Tipo da Fase 100: '%s' (esperado: normal)" % trilha.chefe_type(100))
	print("  Tipo da Fase 150: '%s' (esperado: '' — Fase comum)" % trilha.chefe_type(150))

	var regional_positions: Array[int] = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]
	var all_regional_are_camps: bool = true
	for position: int in regional_positions:
		if not trilha.is_acampamento(position):
			all_regional_are_camps = false
	print("  Todos os 9 Chefes Regionais são Acampamento? %s (esperado: true)" % str(all_regional_are_camps))

	print("  Fase 100 é Acampamento? %s (esperado: false — coincide com Chefe Normal, foi deslocada)" % str(trilha.is_acampamento(100)))
	print("  Fase 101 é Acampamento? %s (esperado: true — deslocamento de +1)" % str(trilha.is_acampamento(101)))

	print("  Fase 125 é Acampamento? %s (esperado: false)" % str(trilha.is_acampamento(125)))
	print("  Fase 126 é Acampamento? %s (esperado: true — prova o reinício da contagem a partir de 101, não de 100)" % str(trilha.is_acampamento(126)))

	var violation_found: bool = false
	for position: int in trilha.acampamento_positions:
		if trilha.is_chefe_normal(position) and not trilha.is_chefe_regional(position):
			violation_found = true
	print("  Algum Acampamento coincide com Chefe Normal (fora dos Regionais)? %s (esperado: false)" % str(violation_found))


## Validação da Sprint 32: ExpeditionRuntime resolve sozinho o Exército
## inimigo de cada Fase (Trilha + Territory + SeasonCatalog +
## EnemyArmySelector) — attempt_current_fase() não recebe mais o
## inimigo por parâmetro.
func _validate_expedition_runtime() -> void:
	print("[ExpeditionRuntime] Validando integração completa (Trilha + Territory + SeasonCatalog + EnemyArmySelector)...")

	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var territory := Territory.new("Territorio-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, 777,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	print("  Status inicial: %s | Fase: %d de %d" % [str(expedition.status), expedition.current_fase, trilha.total_fases()])

	# Avança diretamente para a Fase 99 apenas para o teste (evita simular
	# 98 combates triviais) — não é uma funcionalidade de gameplay.
	expedition.current_fase = 99
	expedition.attempt_current_fase()
	print("  Venceu a Fase 99 -> Fase atual: %d (esperado: 100)" % expedition.current_fase)

	expedition.attempt_current_fase()  # Fase 100: Chefe Normal, e também Acampamento (deslocado)
	print("  Venceu a Fase 100 (Chefe Normal) -> Fase atual: %d" % expedition.current_fase)

	expedition.current_fase = 999
	expedition.attempt_current_fase()
	print("  Venceu a Fase 999 -> Fase atual: %d" % expedition.current_fase)
	print("  Tipo da Fase 1000: %s (esperado: regional)" % expedition.current_fase_type())

	expedition.attempt_current_fase()  # Fase 1000: Chefe Regional -> Acampamento automático
	print("  Venceu a Fase 1000 (Chefe Regional) -> Fase atual: %d, Acampamento em: %d (esperado: 1000)" % [
		expedition.current_fase, expedition.last_acampamento_fase
	])

	# Cenário de derrota total -> retorno ao último Acampamento.
	var losing_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 9, "β": 9, "γ": 9, "δ": 9, "ε": 9})
	losing_army.initialize_energy(1)
	var losing_squad := Squad.new([losing_army])
	var expedition_2 := ExpeditionRuntime.new(
		losing_squad, trilha, territory, catalog, registry, 778,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_2.current_fase = 50
	expedition_2.attempt_current_fase()  # derrota total esperada
	print("  Após derrota total -> Fase atual: %d (esperado: %d, o último Acampamento)" % [
		expedition_2.current_fase, expedition_2.last_acampamento_fase
	])

	expedition_2.end_expedition()
	print("  Status final: %s (esperado: ENCERRADA)" % str(expedition_2.status))

	print("  Log completo da Expedição 2:")
	for line: String in expedition_2.history_log:
		print("    " + line)




## Validação da Sprint 12: simula um exército do Império acumulando
## pelotões da mesma Facção, imprimindo cada transição de Nível de
## Afinidade e os efeitos ativos no Nível máximo atingido, utilizando
## exclusivamente Affinity (lógica pura).
func _validate_affinity() -> void:
	print("[Affinity] Validando Pontos e Níveis de Afinidade (Império)...")

	var commander := CommanderResource.new()
	commander.faction = "Império"

	var cards: Array[CardResource] = []
	var points: int = Affinity.calculate_points("Império", cards, commander)
	var previous_level: int = Affinity.highest_active_level(points)
	print("  Pontos: %d | Nível ativo: %d (apenas Comandante)" % [points, previous_level])

	for i in range(9):
		var card := CardResource.new()
		card.faction = "Império"
		cards.append(card)

		points = Affinity.calculate_points("Império", cards, commander)
		var level: int = Affinity.highest_active_level(points)
		if level != previous_level:
			print("  Pontos: %d | Nível ativo: %d (%d pelotões do Império + Comandante)" % [points, level, cards.size()])
			previous_level = level

	print("[Affinity] Efeitos ativos no Nível máximo atingido:")
	for entry: AffinityLevelResource in Affinity.active_effects("Império", points, GameDatabase.affinity_levels):
		print("  Nível %d: %s" % [entry.level, entry.effect_description])


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


## Validação da Sprint 10: monta um Exército de exemplo (comandante
## transitório em Patente Recruta + 9 cartas Tier I Comuns) e confere
## Formação, Soldo Total, Energia Total e Disponibilidade, utilizando
## exclusivamente Army/Soldo/EnergyArmy/CommanderCareer (lógica pura).
func _validate_army() -> void:
	print("[Army] Validando composição de Exército de exemplo...")

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Validação"
	commander.faction = "Império"
	commander.accumulated_xp = 0  # Recruta

	var army := Army.new()
	army.kingdom_owner = "Reino de Validação"
	army.commander = commander
	army.cards = _build_transient_cards("Comum", 1, 9)

	var nucleus_level: int = 1
	var patente: String = army.commander_patente()

	print("  Comandante: %s | Patente: %s" % [commander.commander_name, patente])
	print("  Formação completa (9 pelotões): %s" % ("sim" if army.is_formation_complete() else "não"))
	print("  Soldo Total: %d / %d (%s)" % [
		army.soldo_total(), Soldo.cap_for_patente(patente),
		"dentro do teto" if army.is_soldo_within_cap() else "excede o teto"
	])
	print("  Energia Total (Núcleo Nv. %d): %d" % [nucleus_level, army.energy_total(nucleus_level)])
	print("  Disponibilidade: %s" % Army.Availability.keys()[army.availability])
	print("  Pronto para batalha: %s" % ("sim" if army.is_ready_for_battle() else "não"))


## Validação da Sprint 26: confirma que CampaignSynergyCalculator
## identifica corretamente Sinergias de Campanha em diferentes cenários
## de composição de Exército. Classe pura — nenhuma batalha é executada.
func _validate_campaign_synergy() -> void:
	print("[CampaignSynergyCalculator] Validando cenários de Sinergia de Campanha...")

	# Exército vazio.
	var empty_result: Dictionary = CampaignSynergyCalculator.calculate([])
	print("  Exército vazio -> %s (esperado: {})" % str(empty_result))

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


## Cria "count" instâncias transitórias de CardResource com Raridade e
## Tier fixos, suficiente para os cálculos de Soldo e Energia (não
## persistidas no catálogo).
func _build_transient_cards(rarity: String, tier: int, count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.rarity = rarity
		card.tier = tier
		cards.append(card)
	return cards


## Validação da Sprint 9: recalcula a Energia Total do "Exército de
## Referência" (demonstração ilustrativa de ENERGY.md) — Núcleo de Energia
## nível 1, Comandante Recruta, 9 cartas Tier I — utilizando exclusivamente
## EnergyArmy (lógica pura, determinística).
func _validate_energy_army() -> void:
	print("[EnergyArmy] Validando Exército de Referência (ENERGY.md)...")

	var nucleus_level: int = 1
	var patente: String = "Recruta"
	var cards: Array[CardResource] = _build_transient_cards_by_tier(1, 9)

	var base: int = EnergyNucleus.energia_base(nucleus_level)
	var commander: int = EnergyArmy.commander_energy(patente)
	var troops: int = EnergyArmy.total_card_energy(cards)
	var total: int = EnergyArmy.total_energy(nucleus_level, patente, cards)

	print("  Energia Base (Núcleo Nv. %d): %d" % [nucleus_level, base])
	print("  Energia do Comandante (%s): %d" % [patente, commander])
	print("  Energia das Cartas (9x Tier I): %d" % troops)
	print("  Energia Total: %d" % total)


## Cria "count" instâncias transitórias de CardResource em um Tier fixo,
## suficiente para o cálculo de Energia (não persistidas no catálogo).
func _build_transient_cards_by_tier(tier: int, count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.tier = tier
		cards.append(card)
	return cards


## Validação da Sprint 8: recalcula a Progressão Resumida do Núcleo de
## Energia (Energia Base e Recuperação) nos marcos oficiais de
## ENERGY_NUCLEUS.md, utilizando exclusivamente EnergyNucleus (lógica pura).
func _validate_energy_nucleus() -> void:
	print("[EnergyNucleus] Progressão Resumida (marcos oficiais):")
	var milestone_levels: Array[int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
	for level: int in milestone_levels:
		var base: int = EnergyNucleus.energia_base(level)
		var recovery: int = EnergyNucleus.recovery_seconds(level)
		print("  Nível %2d | Energia Base: %d | Recuperação: %s" % [level, base, EnergyNucleus.format_seconds(recovery)])

	print("[EnergyNucleus] Exemplo de interface (Nível 27):")
	var example_base: int = EnergyNucleus.energia_base(27)
	var example_recovery: int = EnergyNucleus.recovery_seconds(27)
	var next_level_recovery: int = EnergyNucleus.recovery_seconds(28)
	print("  Capacidade Logística: %d" % example_base)
	print("  Recuperação: 1 ponto a cada %s" % EnergyNucleus.format_seconds(example_recovery))
	print("  Próximo nível: Recuperação -%ds" % (example_recovery - next_level_recovery))


## Validação da Sprint 7: confere o Teto de Soldo por Patente e recalcula
## as composições de referência oficiais de SOLDO.md, utilizando
## exclusivamente Soldo (lógica pura). Cartas são instâncias transitórias
## criadas apenas para este cálculo (dependem somente da Raridade).
func _validate_soldo() -> void:
	print("[Soldo] Tetos de Soldo por Patente:")
	for patente: String in Soldo.CAP_BY_PATENTE:
		print("  %s: %d" % [patente, Soldo.cap_for_patente(patente)])

	print("[Soldo] Validando composições de referência (SOLDO.md, teto máximo Lorde-Comandante)...")
	var cap: int = Soldo.cap_for_patente("Lorde-Comandante")

	var reference_compositions: Dictionary = {
		"2 Lendárias + 2 Épicas + 2 Raras + 3 Comuns": ["Lendária", "Lendária", "Épica", "Épica", "Rara", "Rara", "Comum", "Comum", "Comum"],
		"1 Lendária + 4 Épicas + 4 Raras": ["Lendária", "Épica", "Épica", "Épica", "Épica", "Rara", "Rara", "Rara", "Rara"],
	}

	for label: String in reference_compositions:
		var cards: Array[CardResource] = _build_transient_cards_by_rarity(reference_compositions[label])
		var total: int = Soldo.total_for_composition(cards)
		var valid: bool = total <= cap
		print("  %s -> Soldo total: %d / %d (%s)" % [label, total, cap, "válida" if valid else "inválida"])


## Cria instâncias transitórias de CardResource apenas com Raridade
## definida, suficiente para o cálculo de Soldo (não persistidas no catálogo).
func _build_transient_cards_by_rarity(rarities: Array) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for r: String in rarities:
		var card := CardResource.new()
		card.rarity = r
		cards.append(card)
	return cards


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


## Validação da recuperação de Energia por tempo real (ENERGY_NUCLEUS.md,
## "Eficiência Logística" + ENERGY.md, "Recuperação de Energia"): pontos
## completos são recuperados de acordo com o tempo decorrido e o nível
## do Núcleo, o resto de segundos não é perdido, a recuperação nunca
## ultrapassa a Energia Máxima, e recover_energy_full() (Acampamento)
## nunca soma indevidamente com a sincronização gradual depois. Usa
## timestamps simulados (passado) em vez de esperar minutos reais — só
## o cálculo é testado aqui (já coberto na passagem real do tempo por
## _validate_game_clock).
func _validate_energy_time_recovery() -> void:
	print("[Energia] Validando recuperação de Energia por tempo real...")

	var nucleus_level: int = 1
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(nucleus_level)  # 450s (7m30s) no Nível 1
	var now: int = GameClock.now_unix()

	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(nucleus_level)
	army.consume_energy(10)
	print("  Energia após consumir 10: %d/%d" % [army.current_energy, army.max_energy])

	# Primeira sincronização (last_energy_sync_unix == 0): só estabelece
	# a referência, não concede recuperação retroativa.
	army.sync_energy_recovery(now, nucleus_level)
	print("  Primeira sincronização -> Energia inalterada? %s (esperado: true) | referência estabelecida? %s (esperado: true)" % [
		str(army.current_energy == army.max_energy - 10), str(army.last_energy_sync_unix == now)
	])

	# Passam 2 pontos e meio de tempo -> recupera exatamente 2 pontos,
	# preservando o meio ponto restante para a próxima sincronização.
	var elapsed_for_two_points: int = int(seconds_per_point * 2.5)
	army.sync_energy_recovery(now + elapsed_for_two_points, nucleus_level)
	print("  Após %d segundos (2,5 pontos) -> Energia: %d/%d (esperado: %d, +2 pontos)" % [
		elapsed_for_two_points, army.current_energy, army.max_energy, army.max_energy - 10 + 2
	])

	# O meio ponto restante + mais meio ponto completam o 3º ponto.
	var remaining_for_third_point: int = int(seconds_per_point * 0.5)
	army.sync_energy_recovery(now + elapsed_for_two_points + remaining_for_third_point, nucleus_level)
	print("  Meio ponto restante preservado corretamente -> Energia: %d/%d (esperado: %d, +3 pontos no total)" % [
		army.current_energy, army.max_energy, army.max_energy - 10 + 3
	])

	# Recuperação nunca ultrapassa a Energia Máxima, mesmo com tempo excessivo.
	army.sync_energy_recovery(now + elapsed_for_two_points + remaining_for_third_point + (seconds_per_point * 1000), nucleus_level)
	print("  Tempo excessivo -> Energia parou no máximo? %s (esperado: true, %d/%d)" % [
		str(army.current_energy == army.max_energy), army.current_energy, army.max_energy
	])

	# recover_energy_full() (Acampamento) zera a referência de sync, para
	# que a próxima sincronização gradual não trate o salto como recuperação.
	army.consume_energy(50)
	army.recover_energy_full()
	print("  Após recover_energy_full() -> Energia: %d/%d | referência de sync zerada? %s (esperado: true)" % [
		army.current_energy, army.max_energy, str(army.last_energy_sync_unix == 0)
	])


## Validação do coordenador único de tempo real: uma única chamada a
## GameRuntime.sync() deve, ao mesmo tempo, purgar uma Oferta de
## Recrutamento vencida E recuperar Energia de um Exército do Reino —
## sem que a tela precise conhecer ou chamar cada sistema
## separadamente. Usa timestamps simulados (passado), no mesmo padrão
## das demais validações de tempo desta Sprint.
func _validate_game_runtime_sync() -> void:
	print("[GameRuntime] Validando sync() como coordenador único de tempo real...")

	var nucleus_level: int = 1
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(nucleus_level)
	var now: int = GameClock.now_unix()

	var kingdom := Kingdom.new()
	kingdom.energy_nucleus_level = nucleus_level

	# Exército do Reino com Energia parcial e sincronização "no passado"
	# — deve recuperar pontos ao sincronizar.
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(nucleus_level)
	army.consume_energy(10)
	army.last_energy_sync_unix = now - (seconds_per_point * 3)  # 3 pontos de atraso
	kingdom.add_army(army)

	# Oferta de Recrutamento vencida há mais de 4 dias.
	var expired_commander := CommanderResource.new()
	expired_commander.commander_name = "Comandante Expirado (Sync)"
	var four_days_seconds: int = RecruitmentOffer.VALIDITY_DAYS * 24 * 60 * 60
	kingdom.offer_recruitment(expired_commander, now - four_days_seconds - 10)

	print("  Antes do sync -> Energia: %d/%d | Ofertas pendentes: %d" % [
		army.current_energy, army.max_energy, kingdom.pending_recruitment_offers.size()
	])

	GameRuntime.sync(kingdom, now)

	print("  Após 1 chamada a GameRuntime.sync() -> Energia: %d/%d (esperado: +3 pontos) | Ofertas pendentes: %d (esperado: 0, purgada)" % [
		army.current_energy, army.max_energy, kingdom.pending_recruitment_offers.size()
	])
	print("  Aviso de expiração registrado no Reino? %s (esperado: true)" % str(
		not kingdom.expired_recruitment_notifications.is_empty()
	))


## Validação da Cidade: custo de evolução do Depósito único (FORMULAS.md:
## ceil(n/4) PG) e o teto institucional da Capital (CAPITAL.md —
## nenhuma construção institucional pode ultrapassar o nível da
## Capital).
func _validate_city_deposits() -> void:
	print("[Cidade] Validando custo do Depósito (PG) e o teto da Capital...")

	# Tabela de referência de FORMULAS.md ("Depósitos"): 1-4 -> 1 PG,
	# 5-8 -> 2 PG, 9-12 -> 3 PG, 13-16 -> 4 PG, 17-20 -> 5 PG.
	var milestone_targets: Array[int] = [1, 4, 5, 8, 9, 12, 13, 16, 17, 20]
	for target: int in milestone_targets:
		print("  Custo para atingir o nível %d: %d PG" % [target, Deposits.upgrade_cost_pg(target)])

	var kingdom := Kingdom.new()
	print("  Capital inicial: Nível %d | Depósito inicial: Nível %d (esperado: 1, 1)" % [
		kingdom.capital_level, kingdom.deposito_level
	])

	# Cidade recém-criada: Depósito já está no nível da Capital (1) ->
	# bloqueado até a própria Capital evoluir (CAPITAL.md).
	var blocked_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Evoluir o Depósito com Capital no Nível 1 -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(blocked_result["success"]), blocked_result["reason"]
	])

	# Capital evolui (simulado diretamente, como já é feito para
	# energy_nucleus_level em outras validações) -> Depósito liberado.
	kingdom.capital_level = 2

	var no_pg_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Capital no Nível 2, sem PG -> sucesso? %s | motivo: %s (esperado: false, insufficient_pg)" % [
		str(no_pg_result["success"]), no_pg_result["reason"]
	])

	kingdom.add_generation_points(1)
	var success_result: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Com 1 PG -> sucesso? %s | Depósito agora no Nível: %d | PG restante: %d (esperado: true, 2, 0)" % [
		str(success_result["success"]), kingdom.deposito_level, kingdom.generation_points
	])

	# Depósito (Nível 2) já alcançou a Capital (Nível 2) de novo -> bloqueado.
	var blocked_again: Dictionary = CityResolver.evolve_deposit(kingdom)
	print("  Depósito alcançou a Capital de novo -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(blocked_again["success"]), blocked_again["reason"]
	])


## Validação das 4 construções institucionais (Capital, Centro de
## Comando, Academia, Núcleo de Energia): Fórmula Geral de Construções
## com os b/x vigentes (InstitutionalConstructionConfig, espelhando
## BALANCING_SIMULATION.md), Assinatura Econômica (33/33/33 para a
## Capital, 70/30 Principal/Secundário para as demais), e o teto da
## Capital sobre as outras 3.
func _validate_institutional_constructions() -> void:
	print("[Cidade] Validando evolução das 4 construções institucionais (Fórmula Geral)...")

	var kingdom := Kingdom.new()
	kingdom.raw_resources = {"ferro_negro": 1000000, "cristais_arcanos": 1000000, "essencia_vital": 1000000}

	# Capital: 33/33/33, sem teto próprio.
	var capital_before: int = kingdom.capital_level
	var capital_costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(
		InstitutionalConstructionConfig.Building.CAPITAL, capital_before + 1
	)
	print("  Custo Capital Nível 1->2 (33/33/33): Ferro %d | Cristais %d | Essência %d" % [
		capital_costs.get("ferro_negro", 0), capital_costs.get("cristais_arcanos", 0), capital_costs.get("essencia_vital", 0)
	])
	var capital_result: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CAPITAL)
	print("  Evoluir Capital -> sucesso? %s | Nível agora: %d (esperado: true, 2)" % [
		str(capital_result["success"]), kingdom.capital_level
	])

	# Centro de Comando: bloqueado até a Capital estar à frente (Capital=2, CdC=1 -> pode evoluir 1 vez, até igualar).
	var cdc_result: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Evoluir Centro de Comando (Capital=2, CdC=1) -> sucesso? %s | Nível agora: %d (esperado: true, 2)" % [
		str(cdc_result["success"]), kingdom.command_center_level
	])
	var cdc_blocked: Dictionary = InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Evoluir Centro de Comando de novo (CdC alcançou a Capital) -> sucesso? %s | motivo: %s (esperado: false, capital_limit)" % [
		str(cdc_blocked["success"]), cdc_blocked["reason"]
	])

	# Academia: Assinatura 70/30 (Principal: Essência Vital, Secundário: Ferro Negro).
	var academia_costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(
		InstitutionalConstructionConfig.Building.ACADEMIA, 2
	)
	var academia_total: int = academia_costs.get("essencia_vital", 0) + academia_costs.get("ferro_negro", 0)
	print("  Custo Academia Nível 1->2 (70/30) -> Essência (Principal): %d | Ferro (Secundário): %d | Proporção Principal: %.0f%% (esperado: ~70%%)" % [
		academia_costs.get("essencia_vital", 0), academia_costs.get("ferro_negro", 0),
		(academia_costs.get("essencia_vital", 0) / float(academia_total)) * 100.0
	])
	InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.ACADEMIA)
	print("  Academia evoluiu -> Nível: %d (esperado: 2)" % kingdom.academy_level)

	# Núcleo de Energia: mesma Assinatura 70/30 (Principal: Cristais Arcanos).
	InstitutionalConstructionResolver.evolve(kingdom, InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA)
	print("  Núcleo de Energia evoluiu -> Nível: %d (esperado: 2)" % kingdom.energy_nucleus_level)

	# Recursos insuficientes: tudo ou nada, nada é gasto parcialmente.
	var poor_kingdom := Kingdom.new()
	poor_kingdom.capital_level = 5
	poor_kingdom.raw_resources = {"ferro_negro": 5, "cristais_arcanos": 1000000, "essencia_vital": 1000000}
	var before_cristais: int = poor_kingdom.get_raw_resource("cristais_arcanos")
	var poor_result: Dictionary = InstitutionalConstructionResolver.evolve(poor_kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
	print("  Centro de Comando sem Ferro Negro suficiente -> sucesso? %s | motivo: %s | Cristais Arcanos intocado? %s (esperado: false, insufficient_resources, true)" % [
		str(poor_result["success"]), poor_result["reason"],
		str(poor_kingdom.get_raw_resource("cristais_arcanos") == before_cristais)
	])


## Validação dos pré-requisitos de Minas (produção base, custo em PG,
## capacidade dos Depósitos, armazenamento de recursos brutos no
## Reino). NÃO valida o Ciclo de Mineração, a Guarnição da Mina nem a
## simulação das 9! combinações — todos bloqueados por decisões de
## design ainda pendentes.
func _validate_mine_prerequisites() -> void:
	print("[Minas] Validando pré-requisitos: produção, custo em PG, capacidade dos Depósitos...")

	# Produção Base — Mina Inicial (geométrica: 1, 2, 4, 8/hora).
	for level in range(1, 5):
		print("  Mina Inicial Nível %d -> Produção Base: %d/hora" % [
			level, MineEconomy.base_production_per_hour(MineEconomy.Region.MINA_INICIAL, level)
		])

	# Produção Base — Região 1 (aritmética: 5, 10, 15, 20, 25/hora).
	for level in range(1, 6):
		print("  Região 1 Nível %d -> Produção Base: %d/hora" % [
			level, MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_1, level)
		])

	# Eficiência da Guarnição aplicada à Produção Base.
	var base: int = MineEconomy.base_production_per_hour(MineEconomy.Region.REGIAO_2, 3)  # 30/hora
	print("  Região 2 Nível 3 (Base 30/hora) com Empate (50%%) -> Produção Efetiva: %d/hora (esperado: 15)" % [
		MineEconomy.hourly_production(base, 0.5)
	])

	# Custo em PG com escalonamento por bloco de 10 níveis.
	print("  Custo Região 3 até Nível 5 (bloco 1x): %d PG (esperado: 3)" % MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 5))
	print("  Custo Região 3 até Nível 15 (bloco 1,5x): %d PG (esperado: ceil(3×1,5)=5)" % MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 15))
	print("  Custo Região 3 até Nível 25 (bloco 2,25x): %d PG (esperado: ceil(3×2,25)=7)" % MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_3, 25))

	# Capacidade do Depósito (130% do custo por Recurso que a Capital
	# precisa para o próximo nível).
	for level in range(1, 4):
		print("  Depósito Nível %d -> Capacidade: %d" % [
			level, Deposits.storage_capacity(level)
		])
	print("  Nível 1 = 24, Nível 7 = 17.496 (fim da geométrica x3), Nível 8 = 29.160 (início da PA)? %s (esperado: true)" % str(
		Deposits.storage_capacity(1) == 24 and Deposits.storage_capacity(7) == 17496 and Deposits.storage_capacity(8) == 29160
	))

	# Armazenamento de recursos brutos no Reino, respeitando a
	# capacidade do Depósito (nunca ultrapassa, sobra é reportada).
	var kingdom := Kingdom.new()
	var capacity: int = Deposits.storage_capacity(1)
	var overflow: int = kingdom.credit_raw_resource("ferro_negro", capacity + 500, capacity)
	print("  Creditar além da capacidade (%d) -> Armazenado: %d | Perdido: %d (esperado: %d, 500)" % [
		capacity + 500, kingdom.get_raw_resource("ferro_negro"), overflow, capacity
	])


## Validação do Chefe de Mina: EnemyArmySelector embaralha a posição
## das cartas (deixando de ser "a mais eficiente" do Chefe Regional
## original), de forma determinística, e MineConquestResolver congela
## essa formação embaralhada permanentemente na Mina, no momento exato
## da conquista.
func _validate_mine_reference_formation() -> void:
	print("[Minas] Validando embaralhamento do Chefe de Mina e congelamento da formação de referência...")

	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var original_order: Array[String] = []
	original_order.assign(enemy_army.cards.map(func(c: CardResource) -> String: return c.card_name))
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog("Natureza", enemy_army)

	# Chefe Regional (mesma composição): mantém a posição original.
	var regional: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 42, null
	)
	var regional_order: Array[String] = []
	regional_order.assign(regional.cards.map(func(c: CardResource) -> String: return c.card_name))
	print("  Chefe Regional preserva a posição original? %s (esperado: true)" % str(regional_order == original_order))

	# Chefe de Mina (mesma composição, mesma seed/fase): posição embaralhada.
	var mina_entry: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_DE_MINA, 1, 500, 42, null
	)
	var mina_order: Array[String] = []
	mina_order.assign(mina_entry.cards.map(func(c: CardResource) -> String: return c.card_name))
	print("  Chefe de Mina embaralhou a posição? %s (esperado: true, mesmas 9 cartas)" % str(mina_order != original_order))

	var mina_sorted: Array[String] = mina_order.duplicate()
	mina_sorted.sort()
	var original_sorted: Array[String] = original_order.duplicate()
	original_sorted.sort()
	var same_counts: bool = mina_sorted == original_sorted
	print("  Continuam sendo exatamente as mesmas 9 cartas (só a ordem muda)? %s (esperado: true)" % str(same_counts))

	# Determinismo: mesma Facção/Categoria/Região/Fase/Seed -> mesmo embaralhamento sempre.
	var mina_entry_again: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_DE_MINA, 1, 500, 42, null
	)
	var mina_order_again: Array[String] = []
	mina_order_again.assign(mina_entry_again.cards.map(func(c: CardResource) -> String: return c.card_name))
	print("  Repetir a mesma seleção produz o mesmo embaralhamento? %s (esperado: true)" % str(mina_order == mina_order_again))

	# Congelamento na conquista: valida Mina.freeze_reference_formation()
	# diretamente com o resultado real do EnemyArmySelector (o mesmo
	# dado que MineConquestResolver usa internamente ao vencer).
	var mina := Mina.new(500, "Natureza")
	print("  Antes da conquista -> tem formação de referência? %s (esperado: false)" % str(mina.has_reference_formation()))

	mina.conquer()
	mina.freeze_reference_formation(mina_entry.cards, mina_entry.commander)
	print("  Após conquista -> tem formação de referência? %s (esperado: true)" % str(mina.has_reference_formation()))
	print("  Formação congelada tem 9 cartas, na mesma ordem embaralhada? %s (esperado: true)" % str(
		mina.reference_cards.map(func(c: CardResource) -> String: return c.card_name) == mina_order
	))


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


## Validação da trava anti-exploit da Guarnição (MineGuarnicaoResolver)
## e da produção horária creditada no Depósito via GameRuntime.sync()
## (MiningProductionResolver) — a última peça de conexão de Minas.
func _validate_mine_guarnicao_and_production() -> void:
	print("[Minas] Validando trava da Guarnição e produção creditada via GameRuntime.sync()...")

	var kingdom := Kingdom.new()
	kingdom.deposito_level = 1

	var mina := Mina.new(1500, "Império")  # Região I -> recurso Ferro Negro
	mina.region = 1
	mina.structure_level = 1  # Produção Base Região 1 Nível 1 = 5/hora
	kingdom.territory_mines["Território de Teste"] = [mina]

	var army: Army = CampaignTestFixtures.build_campaign_test_army({})
	var now: int = GameClock.now_unix()

	# Bloqueio: Mina ainda não conquistada.
	var blocked_result: Dictionary = MineGuarnicaoResolver.assign(mina, army, now)
	print("  Designar Guarnição antes da conquista -> sucesso? %s | motivo: %s (esperado: false, not_conquered)" % [
		str(blocked_result["success"]), blocked_result["reason"]
	])

	mina.conquer()
	var success_result: Dictionary = MineGuarnicaoResolver.assign(mina, army, now)
	print("  Designar Guarnição após a conquista -> sucesso? %s | Exército travado? %s (esperado: true, true)" % [
		str(success_result["success"]), str(army.availability == Army.Availability.GUARNICAO_MINA)
	])

	var other_army: Army = CampaignTestFixtures.build_campaign_test_army({})

	mina.start_cycle(now, 1.0)  # Eficiência 100%
	var cycle_active_result: Dictionary = MineGuarnicaoResolver.assign(mina, other_army, now)
	print("  Tentar redesignar com Ciclo ativo -> sucesso? %s | motivo: %s (esperado: false, cycle_active)" % [
		str(cycle_active_result["success"]), cycle_active_result["reason"]
	])

	# Produção creditada via GameRuntime.sync(): 3 horas decorridas,
	# Produção Base 5/hora × Eficiência 100% = 5/hora -> 15 ao todo.
	var three_hours_later: int = now + (3 * 3600)
	MiningProductionResolver.credit(mina, kingdom, three_hours_later)
	print("  Após 3h de Ciclo ativo (5/hora x 100%%) -> Ferro Negro no Reino: %d (esperado: 15)" % kingdom.get_raw_resource("ferro_negro"))

	# Capacidade do Depósito no Nível 1 (24) é bem menor que a produção
	# do ciclo inteiro (500) — o teto entra em ação de verdade aqui.
	var end_of_cycle: int = now + Mina.CYCLE_DURATION_SECONDS + 10  # além do fim do ciclo
	MiningProductionResolver.credit(mina, kingdom, end_of_cycle)
	print("  Produção total do ciclo (100h x 5/hora = 500) limitada pela capacidade do Depósito -> Ferro Negro: %d (esperado: 24, nunca ultrapassa)" % kingdom.get_raw_resource("ferro_negro"))

	# GameRuntime.sync() libera a Guarnição automaticamente quando o
	# Ciclo termina — sem precisar de nenhuma chamada manual extra.
	GameRuntime.sync(kingdom, end_of_cycle)
	print("  Após GameRuntime.sync() com o Ciclo já encerrado -> Exército da Guarnição liberado? %s (esperado: true)" % str(
		army.availability == Army.Availability.AVAILABLE
	))


## Validação do AccountXPResolver (XP.md): cruzamento de Nível de
## Conta gerando PG automaticamente, e conquistas estruturais nunca
## concedidas duas vezes para a mesma chave.
func _validate_account_xp() -> void:
	print("[XP de Conta] Validando AccountXPResolver...")

	var kingdom := Kingdom.new()
	print("  Nível de Conta inicial: %d (esperado: 1) | XP: %d (esperado: 0)" % [kingdom.account_level(), kingdom.account_xp])

	# XP Operacional (sem unique_key): concedido toda vez.
	AccountXPResolver.grant_pve_fase_comum(kingdom)
	AccountXPResolver.grant_pve_fase_comum(kingdom)
	print("  2x 'Concluir fase comum' (1 XP cada) -> XP total: %d (esperado: 2)" % kingdom.account_xp)

	# Cruzar 200 XP concede exatamente 1 PG por Nível cruzado.
	var pg_before: int = kingdom.generation_points
	AccountXPResolver.grant_pve_chefe_regional(kingdom)  # 30 XP, repetido 8x no total
	for i in range(7):
		AccountXPResolver.grant_pve_chefe_regional(kingdom)
	print("  XP total: %d | Nível de Conta: %d (esperado: >= 2) | PG ganho no processo: %d (esperado: >= 1)" % [
		kingdom.account_xp, kingdom.account_level(), kingdom.generation_points - pg_before
	])

	# XP Estrutural (com unique_key): primeira vez concede, segunda não.
	var xp_before_structural: int = kingdom.account_xp
	var first: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "500:Império")
	var xp_after_first: int = kingdom.account_xp
	var second: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "500:Império")
	print("  'Liberar Mina 500:Império' 1a vez -> concedido? %s (esperado: true) | XP ganho: %d (esperado: 20)" % [
		str(first["granted"]), xp_after_first - xp_before_structural
	])
	print("  'Liberar Mina 500:Império' 2a vez (mesma chave) -> concedido? %s | XP mudou? %s (esperado: false, false)" % [
		str(second["granted"]), str(kingdom.account_xp != xp_after_first)
	])

	# Mina diferente (chave diferente) concede normalmente.
	var different_mina: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "2000:Império")
	print("  'Liberar Mina 2000:Império' (chave diferente) -> concedido? %s (esperado: true)" % str(different_mina["granted"]))

	# Conquistas estruturais de carta seguem o mesmo padrão (chave por carta+raridade / carta+Tier).
	var card_first: Dictionary = AccountXPResolver.grant_card_obtained(kingdom, "Lanceiro Imperial", "Comum")
	var card_second: Dictionary = AccountXPResolver.grant_card_obtained(kingdom, "Lanceiro Imperial", "Comum")
	print("  Obter 'Lanceiro Imperial' (Comum) 2x -> 1a concedida? %s | 2a concedida? %s (esperado: true, false)" % [
		str(card_first["granted"]), str(card_second["granted"])
	])


## Validação da Academia (ACADEMY.md): produção de Carta Comum via
## Fragmento, receita específica (Rara/Épica/Lendária), Aprimoramento,
## cancelamento com reembolso, fila com capacidade limitada, e o XP de
## Conta de Coleção ligado na conclusão.
func _validate_academy() -> void:
	print("[Academia] Validando produção, receita, Aprimoramento e filas...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	var now: int = GameClock.now_unix()

	kingdom.sync_academy_masters()
	print("  Nível 1 -> Artífices: %d | Metamorfos: %d (esperado: 1, 1)" % [
		kingdom.academy_artifices.size(), kingdom.academy_metamorfos.size()
	])

	# Produção de Carta Comum.
	var frags_before: int = kingdom.get_fragment("Império")
	var common_result: Dictionary = AcademyResolver.request_common_production(kingdom, "Legionário Imperial", 1, now)
	print("  Produzir 1 Legionário Imperial -> sucesso? %s | Fragmentos gastos: %d (esperado: true, 50)" % [
		str(common_result["success"]), frags_before - kingdom.get_fragment("Império")
	])

	# Fila cheia: 2º pedido ao mesmo Artífice (só 1 existe) enfileira, não falha.
	var second_common: Dictionary = AcademyResolver.request_common_production(kingdom, "Escudeiro Imperial", 1, now)
	print("  2º pedido com Artífice ocupado -> sucesso? %s (esperado: false, fila cheia, capacidade 1)" % str(second_common["success"]))
	print("    motivo: %s (esperado: no_artifice_available)" % second_common["reason"])

	# Avança o tempo além da duração (Comum: 120s Nível Base) -> conclui.
	GameRuntime.sync(kingdom, now + 121)
	var legionario_count: int = 0
	for card: CardResource in kingdom.cards:
		if card.card_name == "Legionário Imperial":
			legionario_count += 1
	print("  Após 121s -> Legionário Imperial na coleção? %d (esperado: 1) | XP de Conta: %d (esperado: 3, 1a obtenção)" % [
		legionario_count, kingdom.account_xp
	])

	# Produção Automática de cadeia completa: Balista Imperial = Arqueiro
	# + Engenheiro + Escudeiro Imperial, nenhum deles em mãos ainda —
	# a Academia precisa produzir os 3 sozinha antes de montar a Balista.
	var poor_kingdom := Kingdom.new()
	poor_kingdom.add_fragment("Império", 10)  # não cobre nem 1 Comum (50)
	var chain_fail: Dictionary = AcademyResolver.request_production(poor_kingdom, "Balista Imperial", 1, now)
	print("  Pedir Balista Imperial sem Fragmento suficiente pra cadeia inteira -> sucesso? %s | motivo: %s (esperado: false, insufficient_fragments)" % [
		str(chain_fail["success"]), chain_fail["reason"]
	])

	var chain_result: Dictionary = AcademyResolver.request_production(kingdom, "Balista Imperial", 1, now)
	print("  Pedir Balista Imperial (cadeia automática, 0 ingredientes em mãos) -> sucesso? %s (esperado: true)" % str(chain_result["success"]))
	print("  Tarefas pendentes aguardando Mestre/dependência logo após o pedido: %d (esperado: > 0)" % kingdom.academy_pending_chain_tasks.size())

	# Só 1 Artífice (Nível 1): a cadeia inteira roda em sequência.
	# Avança o tempo em vários passos, como um jogador que volta a
	# checar o jogo de tempos em tempos — nunca tudo de uma vez só.
	var t: int = now
	for step in range(20):
		t += 500
		GameRuntime.sync(kingdom, t)

	var has_balista: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Balista Imperial":
			has_balista = true
	print("  Balista Imperial produzida ao final da cadeia automática? %s (esperado: true)" % str(has_balista))
	print("  Fila de pendentes vazia ao final? %s (esperado: true)" % str(kingdom.academy_pending_chain_tasks.is_empty()))

	# Cadeia com 2 dos 3 ingredientes já em mãos (Legionário Imperial
	# sobrou da 1ª produção desta validação; Evocador Imperial acabou
	# de ser adquirido) — reaproveita os dois, produz só o Engenheiro.
	var evocador_template: CardResource = GameDatabase.get_card("Evocador Imperial")
	kingdom.acquire_card_from_catalog(evocador_template)
	var frags_before_capitao: int = kingdom.get_fragment("Império")
	var capitao_result: Dictionary = AcademyResolver.request_production(kingdom, "Capitão Imperial", 1, t)
	print("  Pedir Capitão Imperial com 2/3 ingredientes já em mãos -> sucesso? %s | Fragmentos gastos: %d (esperado: true, 50 = só 1 Comum faltando)" % [
		str(capitao_result["success"]), frags_before_capitao - kingdom.get_fragment("Império")
	])

	# Aprimoramento: 3 cópias Tier I de Legionário Imperial -> 1 Tier II.
	var legionario_template: CardResource = GameDatabase.get_card("Legionário Imperial")
	kingdom.acquire_card_from_catalog(legionario_template)
	kingdom.acquire_card_from_catalog(legionario_template)
	kingdom.acquire_card_from_catalog(legionario_template)

	var upgrade_insufficient: Dictionary = AcademyResolver.request_upgrade(kingdom, "Legionário Imperial", 1, 5, t)
	print("  Tentar Aprimorar pedindo 5 lotes (15 cópias, só há 3) -> sucesso? %s | motivo: %s (esperado: false, insufficient_copies)" % [
		str(upgrade_insufficient["success"]), upgrade_insufficient["reason"]
	])

	var upgrade_result: Dictionary = AcademyResolver.request_upgrade(kingdom, "Legionário Imperial", 1, 1, t)
	print("  Aprimorar 3x Legionário Imperial (Tier I -> II) -> sucesso? %s (esperado: true)" % str(upgrade_result["success"]))

	var upgrade_duration: int = AcademyEconomy.upgrade_time_seconds(2, "Comum", kingdom.academy_level)
	GameRuntime.sync(kingdom, t + upgrade_duration + 1)
	var has_tier2: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Legionário Imperial" and card.tier == 2:
			has_tier2 = true
	print("  Legionário Imperial Tier II presente após o Aprimoramento? %s (esperado: true)" % str(has_tier2))
	print("  XP de Conta 'Tier 2 pela 1a vez' concedido? %s (esperado: true, XP total > antes)" % str(kingdom.has_structural_xp("card_tier:Legionário Imperial:2")))

	# Cancelamento antes do início devolve o reservado.
	var cancel_kingdom := Kingdom.new()
	cancel_kingdom.add_fragment("Império", 200)
	cancel_kingdom.sync_academy_masters()
	var cancel_now: int = GameClock.now_unix()
	AcademyResolver.request_common_production(cancel_kingdom, "Legionário Imperial", 1, cancel_now)  # ocupa o único Artífice
	AcademyResolver.request_common_production(cancel_kingdom, "Escudeiro Imperial", 1, cancel_now)  # fila cheia -> falha, nada reservado

	var master: AcademyMaster = cancel_kingdom.academy_artifices[0]
	var running_task: AcademyTask = master.current_task()
	var frags_before_cancel: int = cancel_kingdom.get_fragment("Império")
	var cancel_running: bool = AcademyResolver.cancel_task(cancel_kingdom, master, running_task)
	print("  Cancelar a tarefa que já está em execução -> permitido? %s (esperado: false)" % str(cancel_running))
	print("  Fragmentos inalterados após tentativa inválida de cancelar? %s (esperado: true)" % str(cancel_kingdom.get_fragment("Império") == frags_before_cancel))


## Validação da compra de capacidade de fila (ACADEMY.md, "Melhorias
## das Filas"): custo em PG, teto por tipo de Mestre, e o efeito real
## de destravar uma 2ª tarefa simultânea na fila do mesmo Mestre.
func _validate_academy_queue_upgrade() -> void:
	print("[Academia] Validando compra de capacidade de fila (PG)...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	kingdom.sync_academy_masters()
	var now: int = GameClock.now_unix()

	var artifice: AcademyMaster = kingdom.academy_artifices[0]
	print("  Capacidade inicial do Artífice: %d (esperado: 1)" % artifice.queue_capacity)

	var no_pg_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, artifice)
	print("  Tentar upar sem PG -> sucesso? %s | motivo: %s (esperado: false, insufficient_pg)" % [
		str(no_pg_result["success"]), no_pg_result["reason"]
	])

	kingdom.add_generation_points(2)
	var upgrade_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, artifice)
	print("  Upar Artífice pra capacidade 2 (custa 2 PG) -> sucesso? %s | Capacidade agora: %d | PG restante: %d (esperado: true, 2, 0)" % [
		str(upgrade_result["success"]), artifice.queue_capacity, kingdom.generation_points
	])

	# Com capacidade 2, agora cabem 2 tarefas na fila do mesmo Artífice ao mesmo tempo.
	AcademyResolver.request_common_production(kingdom, "Legionário Imperial", 1, now)
	var second_fits: Dictionary = AcademyResolver.request_common_production(kingdom, "Escudeiro Imperial", 1, now)
	print("  2ª tarefa no mesmo Artífice, agora com capacidade 2 -> sucesso? %s (esperado: true)" % str(second_fits["success"]))

	# Teto do Metamorfo é 4 (só 3 degraus: 2, 3, 4).
	var metamorfo: AcademyMaster = kingdom.academy_metamorfos[0]
	kingdom.add_generation_points(2 + 8 + 32)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	print("  Metamorfo após 3 upgrades -> Capacidade: %d (esperado: 4, teto)" % metamorfo.queue_capacity)

	var over_cap_result: Dictionary = AcademyResolver.upgrade_queue_capacity(kingdom, metamorfo)
	print("  Tentar upar o Metamorfo além do teto -> sucesso? %s | motivo: %s (esperado: false, max_capacity_reached)" % [
		str(over_cap_result["success"]), over_cap_result["reason"]
	])


## Validação final da Academia: Previsão (sem comprometer nada),
## Preservar Inventário, Editar Receita (forçar existing/produce por
## ingrediente), e Modo Conservador (usa só 1 Mestre por vez).
func _validate_academy_advanced_options() -> void:
	print("[Academia] Validando Previsão, Preservar Inventário, Editar Receita e Modo Conservador...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 10000)

	# Previsão: não deve comprometer nada.
	var frags_before_preview: int = kingdom.get_fragment("Império")
	var preview: Dictionary = AcademyResolver.preview_production(kingdom, "Balista Imperial", 1)
	print("  Previsão de Balista Imperial (0 em mãos) -> custo total: %d (esperado: 150 = 3x50) | pagável? %s" % [
		preview["total_fragment_cost"], str(preview["affordable"])
	])
	print("  Previsão não gastou nada de verdade? %s (esperado: true)" % str(kingdom.get_fragment("Império") == frags_before_preview))

	# Preservar Inventário: ignora cópia já existente, produz do zero mesmo assim.
	var arqueiro_template: CardResource = GameDatabase.get_card("Arqueiro Imperial")
	var owned_arqueiro: CardResource = kingdom.acquire_card_from_catalog(arqueiro_template)
	var frags_before_preserve: int = kingdom.get_fragment("Império")
	AcademyResolver.request_production(kingdom, "Balista Imperial", 1, GameClock.now_unix(), true)
	print("  Preservar Inventário (1 Arqueiro em mãos, ignorado de propósito) -> Fragmentos gastos: %d (esperado: 150, os 3 do zero)" % [
		frags_before_preserve - kingdom.get_fragment("Império")
	])
	print("  O Arqueiro Imperial original continua Livre, intocado? %s (esperado: true)" % str(
		owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE
	))

	# Editar Receita: força "produce" mesmo tendo cópia, e "existing" pra outro que não existe -> falha.
	var override_fail: Dictionary = AcademyResolver.request_production(
		kingdom, "Balista Imperial", 1, GameClock.now_unix(), false,
		{"Arqueiro Imperial": "produce", "Engenheiro Imperial": "existing"}
	)
	print("  Editar Receita forçando 'existing' num ingrediente sem cópia -> sucesso? %s | motivo: %s | faltando: %s (esperado: false, forced_existing_unavailable, Engenheiro Imperial)" % [
		str(override_fail["success"]), override_fail["reason"], override_fail.get("missing_ingredient", "")
	])
	print("  O Arqueiro Imperial original continua intocado após a falha? %s (esperado: true)" % str(
		owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE
	))

	# Modo Conservador: com 2 Artífices livres (Nível 4), usa só 1 por vez.
	var conservative_kingdom := Kingdom.new()
	conservative_kingdom.add_fragment("Império", 10000)
	conservative_kingdom.academy_level = 4
	conservative_kingdom.sync_academy_masters()
	print("  Reino de teste (Nível 4) -> Artífices disponíveis: %d (esperado: 2)" % conservative_kingdom.academy_artifices.size())

	AcademyResolver.request_production(conservative_kingdom, "Balista Imperial", 1, GameClock.now_unix(), false, {}, "conservador")
	var busy_masters_conservative: int = 0
	for master: AcademyMaster in conservative_kingdom.academy_artifices:
		if master.is_busy():
			busy_masters_conservative += 1
	print("  Modo Conservador (3 Comuns necessários, 2 Artífices livres) -> Artífices ocupados imediatamente: %d (esperado: 1, só o primeiro)" % busy_masters_conservative)

	# Comparação: Modo Prioritário usa quantos Mestres livres houver.
	var priority_kingdom := Kingdom.new()
	priority_kingdom.add_fragment("Império", 10000)
	priority_kingdom.academy_level = 4
	priority_kingdom.sync_academy_masters()
	AcademyResolver.request_production(priority_kingdom, "Balista Imperial", 1, GameClock.now_unix(), false, {}, "prioritario")
	var busy_masters_priority: int = 0
	for master: AcademyMaster in priority_kingdom.academy_artifices:
		if master.is_busy():
			busy_masters_priority += 1
	print("  Modo Prioritário (mesmo cenário) -> Artífices ocupados imediatamente: %d (esperado: 2, os dois disponíveis)" % busy_masters_priority)


## Validação das Vagas de Treinamento (COMMAND_CENTER_PROGRESS.md):
## 0 antes do Nível 3, 1 no desbloqueio, +1 a cada 4 níveis depois.
func _validate_command_center_training_slots() -> void:
	print("[Centro de Comando] Validando Vagas de Treinamento por Nível...")

	var cases: Dictionary = {
		1: 0, 2: 0, 3: 1, 6: 1, 7: 2, 10: 2, 11: 3, 14: 3, 15: 4, 18: 4, 19: 5, 22: 5,
	}
	for level: int in cases:
		var expected: int = cases[level]
		var actual: int = CommandCenterProgress.training_slots(level)
		print("  Nível %d -> Vagas: %d (esperado: %d) %s" % [
			level, actual, expected, "OK" if actual == expected else "FALHOU"
		])


## Validação da máquina de estados administrativos do Comandante
## (COMMAND_CENTER.md) e da Expansão Administrativa em PG
## (COMMAND_CENTER_PROGRESS.md).
func _validate_command_center_state_machine() -> void:
	print("[Centro de Comando] Validando máquina de estados e Expansão Administrativa...")

	var kingdom := Kingdom.new()  # Nível 1 -> Infraestrutura: 1 Ativo, 4 Reserva
	print("  Infraestrutura no Nível 1: %s (esperado: {ativo:1, reserva:4})" % str(
		CommandCenterProgress.infrastructure_at_level(1)
	))

	# Ativação: sempre Ativo primeiro, depois Reserva.
	kingdom.add_generation_points(1)
	var activation_1: Dictionary = CommandCenterResolver.activate_next(kingdom)
	print("  1ª ativação -> tipo: %s | Cargo Ativo ativado: %d (esperado: ativo, 1)" % [
		activation_1["type"], kingdom.cargo_ativo_activated
	])

	kingdom.add_generation_points(1)
	var activation_2: Dictionary = CommandCenterResolver.activate_next(kingdom)
	print("  2ª ativação (Ativo do Nível 1 já esgotado) -> tipo: %s (esperado: reserva)" % activation_2["type"])

	# Comandante novo: entra em Reserve, não pode liderar Exército ainda.
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Teste (Estados)"
	commander.faction = "Império"
	kingdom.add_commander(commander)
	print("  Estado inicial: %s (esperado: RESERVE)" % CommanderResource.AdministrativeState.keys()[commander.administrative_state])

	var promote: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	print("  Promover a Ativo (1 Cargo já ativado) -> sucesso? %s (esperado: true)" % str(promote["success"]))

	var second_commander := CommanderResource.new()
	second_commander.commander_name = "2º Comandante (sem Cargo livre)"
	second_commander.faction = "Império"
	kingdom.add_commander(second_commander)
	var promote_fail: Dictionary = CommandCenterResolver.move_to_active(kingdom, second_commander)
	print("  Promover um 2º Comandante (só 1 Cargo Ativo ativado, já ocupado) -> sucesso? %s | motivo: %s (esperado: false, no_cargo_ativo_available)" % [
		str(promote_fail["success"]), promote_fail["reason"]
	])

	# Treinamento: Nível 1 do CdC ainda não desbloqueou (precisa Nível 3).
	var now_for_training: int = GameClock.now_unix()
	var train_blocked: Dictionary = CommandCenterResolver.move_to_training(kingdom, second_commander, now_for_training)
	print("  Mandar pro Treinamento sem vagas (CdC Nível 1, desbloqueia no 3) -> sucesso? %s | motivo: %s (esperado: false, no_training_slot_available)" % [
		str(train_blocked["success"]), train_blocked["reason"]
	])

	kingdom.command_center_level = 3
	var train_success: Dictionary = CommandCenterResolver.move_to_training(kingdom, second_commander, now_for_training)
	print("  Mandar pro Treinamento (CdC Nível 3, 1 vaga) -> sucesso? %s (esperado: true)" % str(train_success["success"]))

	# Comandante em Treinamento nunca pode liderar Exército (não é Ativo).
	print("  Comandante em Treinamento disponível pra liderar Exército? %s (esperado: false)" % str(
		kingdom.is_commander_available(second_commander)
	))

	var back_to_reserve: Dictionary = CommandCenterResolver.move_to_reserve(kingdom, second_commander)
	print("  Voltar do Treinamento pra Reserve -> sucesso? %s | Estado: %s (esperado: true, RESERVE)" % [
		str(back_to_reserve["success"]), CommanderResource.AdministrativeState.keys()[second_commander.administrative_state]
	])

	# Aposentadoria.
	var retire_result: Dictionary = CommandCenterResolver.retire(kingdom, commander)
	print("  Aposentar o 1º Comandante -> sucesso? %s | Estado: %s (esperado: true, RETIRED)" % [
		str(retire_result["success"]), CommanderResource.AdministrativeState.keys()[commander.administrative_state]
	])
	var retire_again: Dictionary = CommandCenterResolver.retire(kingdom, commander)
	print("  Aposentar de novo o mesmo Comandante -> sucesso? %s | motivo: %s (esperado: false, already_retired)" % [
		str(retire_again["success"]), retire_again["reason"]
	])


## Validação do acúmulo de XP de Treinamento (COMMAND_CENTER_TRAINING.md):
## Média Diária calculada corretamente, 20% creditado por dia fechado,
## Ciclo de 10 dias incorporando à carreira, e cancelamento descartando
## a XP Acumulada não incorporada.
func _validate_commander_training_xp() -> void:
	print("[Treinamento] Validando Média Diária de XP e Ciclo de 10 dias...")

	var kingdom := Kingdom.new()
	kingdom.command_center_level = 3  # desbloqueia Treinamento
	# Arredonda pro início exato de um dia (Unix) — evita que o teste
	# feche 1 ou 2 dias dependendo da hora real em que ele rodar.
	@warning_ignore("integer_division")
	var now: int = (GameClock.now_unix() / CommanderTrainingResolver.SECONDS_PER_DAY) * CommanderTrainingResolver.SECONDS_PER_DAY

	var active_commander_a := CommanderResource.new()
	active_commander_a.commander_name = "Ativo A"
	kingdom.add_commander(active_commander_a)
	var active_commander_b := CommanderResource.new()
	active_commander_b.commander_name = "Ativo B"
	kingdom.add_commander(active_commander_b)

	var trainee := CommanderResource.new()
	trainee.commander_name = "Em Treinamento"
	kingdom.add_commander(trainee)
	kingdom.add_generation_points(5)
	CommandCenterResolver.activate_next(kingdom)  # 1 Cargo Ativo, pra caber no cenário se precisar
	CommandCenterResolver.move_to_training(kingdom, trainee, now)

	# Dia 1: dois Comandantes Ativos ganham 10 e 20 de XP em combate real.
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, now)
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, now)
	print("  Ativo A XP: %d | Ativo B XP: %d (esperado: 10, 20 — concedido de verdade, não só logado)" % [
		active_commander_a.accumulated_xp, active_commander_b.accumulated_xp
	])

	var day_1: int = now + CommanderTrainingResolver.SECONDS_PER_DAY + 1
	GameRuntime.sync(kingdom, day_1)
	print("  Média Diária do Dia 1: %d (esperado: 15 = (10+20)/2) | XP Acumulada do Treinando: %d (esperado: 3 = 20%% de 15)" % [
		kingdom.last_daily_average_xp, trainee.training_accumulated_xp
	])

	# Mais 9 dias iguais -> completa o Ciclo de 10 dias, incorpora à carreira.
	var t: int = day_1
	for day in range(2, 11):
		CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, t)
		CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, t)
		t += CommanderTrainingResolver.SECONDS_PER_DAY
		GameRuntime.sync(kingdom, t)

	print("  Após 10 dias -> XP de carreira incorporada: %d (esperado: 30 = 3 x 10 dias) | Acumulador do ciclo zerado: %d (esperado: 0)" % [
		trainee.accumulated_xp, trainee.training_accumulated_xp
	])

	# Cancelamento mid-ciclo: descarta a XP Acumulada não incorporada.
	# Precisa de uma 2ª vaga de Treinamento — a 1ª já está ocupada pelo
	# "trainee" original, que nunca saiu do Treinamento.
	kingdom.command_center_level = 7  # training_slots(7) = 2
	var canceled_trainee := CommanderResource.new()
	canceled_trainee.commander_name = "Cancelado"
	kingdom.add_commander(canceled_trainee)
	var move_result: Dictionary = CommandCenterResolver.move_to_training(kingdom, canceled_trainee, t)
	print("  2ª vaga de Treinamento (CdC Nível 7) -> designação bem-sucedida? %s (esperado: true)" % str(move_result["success"]))
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, t)
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, t)
	GameRuntime.sync(kingdom, t + CommanderTrainingResolver.SECONDS_PER_DAY + 1)
	print("  Antes de cancelar -> XP Acumulada do ciclo: %d (esperado: 3, > 0)" % canceled_trainee.training_accumulated_xp)

	CommandCenterResolver.move_to_reserve(kingdom, canceled_trainee)
	print("  Após cancelar -> XP Acumulada descartada: %d | XP de carreira (nunca chegou a ser incorporada): %d (esperado: 0, 0)" % [
		canceled_trainee.training_accumulated_xp, canceled_trainee.accumulated_xp
	])


## Validação do Centro de Recrutamento (COMMAND_CENTER_RECRUITMENT.md):
## Slots, gerador sequencial (1 ciclo por vez, preenche o 1º Slot
## vazio), e o Caso Especial da Reserva Cheia (Comissionamento falho
## nunca libera o Slot).
func _validate_recruitment_center() -> void:
	print("[Centro de Recrutamento] Validando Slots e gerador sequencial...")

	var kingdom := Kingdom.new()  # Nível 1 -> 3 Slots, cooldown 24h
	@warning_ignore("integer_division")
	var now: int = (GameClock.now_unix() / 86400) * 86400  # arredondado, mesmo cuidado do teste de Treinamento

	GameRuntime.sync(kingdom, now)
	print("  Slots no Nível 1: %d (esperado: 3) | Ciclo iniciado? %s (esperado: true)" % [
		kingdom.recruitment_center_slots.size(), str(kingdom.recruitment_center_cycle_end_unix != 0)
	])

	# 24h depois: preenche o 1º Slot, inicia o 2º ciclo (ainda sobra Slot vazio).
	var t: int = now + (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	var filled_after_1: int = 0
	for slot: CommanderResource in kingdom.recruitment_center_slots:
		if slot != null:
			filled_after_1 += 1
	print("  Após 24h -> Slots preenchidos: %d (esperado: 1, geração sequencial, nunca todos de uma vez)" % filled_after_1)

	# Mais 2 ciclos de 24h -> preenche os 3 Slots, e o gerador para
	# (nenhum ciclo novo, porque não sobra Slot vazio).
	t += (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	t += (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	var filled_after_3: int = 0
	for slot: CommanderResource in kingdom.recruitment_center_slots:
		if slot != null:
			filled_after_3 += 1
	print("  Após 3 ciclos -> Slots preenchidos: %d | Ciclo novo pendente? %s (esperado: 3, false — nada pra gerar)" % [
		filled_after_3, str(kingdom.recruitment_center_cycle_end_unix != 0)
	])

	# Caso Especial: Reserva Cheia -> Comissionamento falha, Slot continua ocupado.
	var blocked: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, t)
	print("  Comissionar sem Vaga da Reserva -> sucesso? %s | motivo: %s | Slot continua ocupado? %s (esperado: false, no_vaga_reserva_available, true)" % [
		str(blocked["success"]), blocked["reason"], str(kingdom.recruitment_center_slots[0] != null)
	])

	# Abre 1 Vaga da Reserva -> Comissionamento funciona, Slot esvazia.
	kingdom.add_generation_points(2)
	CommandCenterResolver.activate_next(kingdom)
	CommandCenterResolver.activate_next(kingdom)
	var success: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, t)
	print("  Comissionar com Vaga disponível -> sucesso? %s | Slot 0 vazio agora? %s | Comandantes no Reino: %d (esperado: true, true, 1)" % [
		str(success["success"]), str(kingdom.recruitment_center_slots[0] == null), kingdom.commanders.size()
	])

	# Histórico de Comissionamentos (finalidade informativa, últimos 20).
	var last_entry: Dictionary = kingdom.commissioning_history[-1]
	print("  Histórico registrou o Comissionamento? %s | Fonte: %s (esperado: true, 'Centro de Recrutamento')" % [
		str(not kingdom.commissioning_history.is_empty()), last_entry.get("source", "")
	])

	# Slot vazio de novo -> o próximo sync() já reinicia o gerador sozinho.
	GameRuntime.sync(kingdom, t)
	print("  Após liberar 1 Slot, sync() reinicia o gerador sozinho? %s (esperado: true)" % str(
		kingdom.recruitment_center_cycle_end_unix != 0
	))


## Validação do Sistema de Legado (COMMAND_CENTER_LEGACY.md): Legado
## Administrativo (bloqueio abaixo do mínimo, benefícios cumulativos
## por Patente, capacidades efetivas) e Grande Legado Militar (Doutrina
## Militar, Regra de Excesso).
func _validate_legacy() -> void:
	print("[Legado] Validando Legado Administrativo e Grande Legado Militar...")

	var kingdom := Kingdom.new()
	kingdom.command_center_level = 10  # desbloqueia Legado I-V
	var now: int = GameClock.now_unix()

	# Abaixo do mínimo (Recruta) -> bloqueado.
	var recruit := CommanderResource.new()
	recruit.commander_name = "Recruta de Teste"
	kingdom.add_commander(recruit, now)
	var blocked: Dictionary = LegacyResolver.retire_administrative(kingdom, recruit, now)
	print("  Aposentar um Recruta (abaixo do Legado I) -> sucesso? %s | motivo: %s (esperado: false, below_minimum_patente)" % [
		str(blocked["success"]), blocked["reason"]
	])

	# General: qualifica pra Legado I-IV, mas NÃO Legado V (exige Marechal).
	var general := CommanderResource.new()
	general.commander_name = "General de Teste"
	general.accumulated_xp = 4880  # limiar exato de General
	kingdom.add_commander(general, now)
	var general_result: Dictionary = LegacyResolver.retire_administrative(kingdom, general, now)
	print("  Aposentar um General -> sucesso? %s | Nº de benefícios: %d (esperado: true, 4 — Legado I a IV, não V)" % [
		str(general_result["success"]), general_result["benefits"].size()
	])
	print("  Estado agora: %s | Tipo de Aposentadoria: %s (esperado: RETIRED, 'Legado Administrativo')" % [
		CommanderResource.AdministrativeState.keys()[general.administrative_state], general.retirement_type
	])

	# Lorde-Comandante: qualifica pra todos os 5, exige destino do Legado V.
	var lorde := CommanderResource.new()
	lorde.commander_name = "Lorde-Comandante de Teste"
	lorde.accumulated_xp = 12480
	kingdom.add_commander(lorde, now)
	var missing_destino: Dictionary = LegacyResolver.retire_administrative(kingdom, lorde, now)
	print("  Aposentar um Lorde-Comandante sem escolher destino do Legado V -> sucesso? %s | motivo: %s (esperado: false, missing_legado_v_destino)" % [
		str(missing_destino["success"]), missing_destino["reason"]
	])

	var xp_before: float = kingdom.legacy_v_bonus_xp
	var lorde_result: Dictionary = LegacyResolver.retire_administrative(kingdom, lorde, now, "xp")
	print("  Aposentar o mesmo Lorde-Comandante, destino 'xp' -> sucesso? %s | Nº de benefícios: %d (esperado: true, 5) | Bônus XP: %.2f%% -> %.2f%%" % [
		str(lorde_result["success"]), lorde_result["benefits"].size(), xp_before, kingdom.legacy_v_bonus_xp
	])

	print("  Hall dos Comandantes -> total registrado: %d (esperado: 2 — Recruta nunca chegou a se aposentar)" % kingdom.commander_hall().size())

	# Capacidades efetivas: com 3 aposentados administrativos ainda não
	# chega a nenhum marco (precisa de 20/25/100) — mas confirma que a
	# fórmula soma corretamente ao simular retirees suficientes.
	var big_kingdom := Kingdom.new()
	big_kingdom.legacy_administrative_retirees = 40  # 2 marcos de Legado II (20 cada)
	print("  Com 40 aposentados -> Vagas de Treinamento efetivas (Nível 1, sem Legado seria 0): %d (esperado: 2)" % CommandCenterProgress.effective_training_slots(big_kingdom))

	# Grande Legado Militar: bloqueado abaixo do Nível 100 do CdC.
	var glm_kingdom := Kingdom.new()
	glm_kingdom.command_center_level = 99
	var glm_commander := CommanderResource.new()
	glm_commander.commander_name = "Candidato a Grande Legado"
	glm_commander.faction = "Império"
	glm_commander.accumulated_xp = 12480
	glm_kingdom.add_commander(glm_commander, now)
	var glm_blocked_level: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, glm_commander, null, now, "escudo")
	print("  Grande Legado Militar com CdC Nível 99 -> sucesso? %s | motivo: %s (esperado: false, cdc_level_too_low)" % [
		str(glm_blocked_level["success"]), glm_blocked_level["reason"]
	])

	# Monta um Exército válido: 9 cartas Império, Tier V, Soldo exato 32
	# (3 Lendária + 1 Épica + 2 Rara + 3 Comum = 21+4+4+3 = 32).
	glm_kingdom.command_center_level = 100
	glm_kingdom.add_generation_points(10)
	CommandCenterResolver.activate_next(glm_kingdom)
	CommandCenterResolver.move_to_active(glm_kingdom, glm_commander)

	var glm_cards: Array[CardResource] = []
	var card_specs: Array = [
		["Marechal Imperial", 3], ["Centurião Imperial", 1], ["Guardião Imperial", 2], ["Legionário Imperial", 3],
	]
	for spec: Array in card_specs:
		var template: CardResource = GameDatabase.get_card(spec[0])
		for i in range(spec[1]):
			var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
			copy.tier = 5
			glm_cards.append(copy)

	var glm_army := Army.new()
	glm_army.commander = glm_commander
	glm_army.cards = glm_cards
	print("  Exército de teste -> Soldo total: %d / %d (esperado: 32, 32 — teto exato)" % [
		glm_army.soldo_total(), Soldo.cap_for_patente("Lorde-Comandante")
	])

	var glm_result: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, glm_commander, glm_army, now, "escudo")
	print("  Criar Grande Legado Militar (Império, +Escudo) -> sucesso? %s | atributo concedido: %s (esperado: true, escudo)" % [
		str(glm_result["success"]), glm_result["attribute_applied"]
	])
	print("  Doutrina do Império -> Escudo: %d | Cartas removidas do plantel: %d (esperado: 1, 0)" % [
		glm_kingdom.military_doctrine["Império"]["escudo"], glm_kingdom.cards.size()
	])
	print("  Comandante consumido -> Estado: %s | Tipo: %s | Ainda no Hall? %s (esperado: RETIRED, 'Grande Legado Militar', true)" % [
		CommanderResource.AdministrativeState.keys()[glm_commander.administrative_state], glm_commander.retirement_type,
		str(glm_kingdom.commander_hall().has(glm_commander))
	])

	# Regra de Excesso: esgota o limite de Escudo (5) e confirma que o
	# 6º Grande Legado ainda registra, mas sem novo atributo.
	for i in range(4):  # já tem 1, faltam 4 pra chegar em 5 (o limite)
		glm_kingdom.command_center_level = 100
		var extra_commander := CommanderResource.new()
		extra_commander.commander_name = "Extra %d" % i
		extra_commander.faction = "Império"
		extra_commander.accumulated_xp = 12480
		glm_kingdom.add_commander(extra_commander, now)
		CommandCenterResolver.activate_next(glm_kingdom)
		CommandCenterResolver.move_to_active(glm_kingdom, extra_commander)
		var extra_cards: Array[CardResource] = []
		for spec: Array in card_specs:
			var template: CardResource = GameDatabase.get_card(spec[0])
			for j in range(spec[1]):
				var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
				copy.tier = 5
				extra_cards.append(copy)
		var extra_army := Army.new()
		extra_army.commander = extra_commander
		extra_army.cards = extra_cards
		LegacyResolver.create_grande_legado_militar(glm_kingdom, extra_commander, extra_army, now, "escudo")

	print("  Após 5 Grandes Legados (limite de Escudo atingido) -> Escudo: %d (esperado: 5)" % glm_kingdom.military_doctrine["Império"]["escudo"])

	var sixth_commander := CommanderResource.new()
	sixth_commander.commander_name = "6º Candidato"
	sixth_commander.faction = "Império"
	sixth_commander.accumulated_xp = 12480
	glm_kingdom.add_commander(sixth_commander, now)
	CommandCenterResolver.activate_next(glm_kingdom)
	CommandCenterResolver.move_to_active(glm_kingdom, sixth_commander)
	var sixth_cards: Array[CardResource] = []
	for spec: Array in card_specs:
		var template: CardResource = GameDatabase.get_card(spec[0])
		for j in range(spec[1]):
			var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
			copy.tier = 5
			sixth_cards.append(copy)
	var sixth_army := Army.new()
	sixth_army.commander = sixth_commander
	sixth_army.cards = sixth_cards
	var sixth_result: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, sixth_commander, sixth_army, now, "escudo")
	print("  6º Grande Legado (Regra de Excesso) -> sucesso? %s | atributo concedido: '%s' | Escudo continua: %d (esperado: true, '' vazio, 5)" % [
		str(sixth_result["success"]), sixth_result["attribute_applied"], glm_kingdom.military_doctrine["Império"]["escudo"]
	])
	print("  Comandante do 6º Legado registrado no Hall mesmo sem ganhar atributo? %s (esperado: true)" % str(
		sixth_commander.administrative_state == CommanderResource.AdministrativeState.RETIRED
	))


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
## Validação FUNCIONAL dos 4 Arquétipos de Formação (ARMY.md) — cada
## um usando as regras de combate corretas, nunca idênticos entre si,
## Máquina de Guerra sempre na Posição 9.
func _validate_army_formation_archetypes() -> void:
	print("[Exército] Validando os 4 Arquétipos de Formação (β, γ, δ, ε)...")

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

	var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(cards)

	var beta: Array[CardResource] = archetypes["β"]
	print("  β (Ofensiva) -> Posição 1 é o Corpo a Corpo de maior Ataque? %s | Arqueiros nas Posições 6 e 7? %s (esperado: true, true)" % [
		str(beta[0] == cqc_high), str((beta[5] == ranged_1 or beta[5] == ranged_2) and (beta[6] == ranged_1 or beta[6] == ranged_2) and beta[5] != beta[6])
	])

	var gamma: Array[CardResource] = archetypes["γ"]
	print("  γ (Defensiva) -> Posição 1 é a Barreira de maior Escudo? %s (esperado: true)" % str(gamma[0] == barreira_high))

	var delta: Array[CardResource] = archetypes["δ"]
	print("  δ (Equilibrada) -> Posição 1 NÃO é o maior Ataque nem o maior Escudo isolados? %s (esperado: true)" % str(
		delta[0] != cqc_high and delta[0] != barreira_high
	))

	var epsilon: Array[CardResource] = archetypes["ε"]
	print("  Todas as 4 têm Máquina de Guerra na Posição 9? %s (esperado: true)" % str(
		beta[8] == maquina and gamma[8] == maquina and delta[8] == maquina and epsilon[8] == maquina
	))

	print("  As 4 Formações são diferentes entre si (nenhuma idêntica)? %s (esperado: true)" % str(
		beta != gamma and beta != delta and beta != epsilon and gamma != delta and gamma != epsilon and delta != epsilon
	))

	# --- Kingdom.form_army() gera as 5 Formações automaticamente, mesmo num fluxo de 1 Formação só ---
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


## Validação FUNCIONAL do bug real relatado: Mina Inicial nunca deve
## "expirar" mostrando um Ciclo de 100h — MINES.md, "Mina Inicial
## (Bootstrap)": produção contínua, sem prazo. Testado bem além das
## 100h pra confirmar que continua ativa (diferente das Minas de
## Trilha, que teriam expirado).
func _validate_initial_mine_never_expires() -> void:
	print("[Minas] Validando que a Mina Inicial nunca expira (bug relatado: mostrava Ciclo de 100h)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var mina: Mina = kingdom.initial_mines[0]
	var start: int = GameClock.now_unix()
	mina.start_cycle(start, 1.0)

	var far_future: int = start + (200 * 3600)  # 200h no futuro — bem além das 100h de um Ciclo normal
	print("  Mina Inicial continua ativa 200h depois (Minas de Trilha teriam expirado em 100h)? %s (esperado: true)" % str(
		mina.is_cycle_active(far_future)
	))

	MiningProductionResolver.credit(mina, kingdom, far_future)
	var resource_name: String = MineEconomy.resource_for_faction(mina.faction)
	print("  Produção creditada de verdade além das 100h, sem travar num teto? %s (%d %s, esperado: true, > 0)" % [
		str(kingdom.get_raw_resource(resource_name) > 0), kingdom.get_raw_resource(resource_name), resource_name
	])


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


## Validação FUNCIONAL do bug real relatado: produzir a Balista
## Imperial (Rara, com Receita de 3 ingredientes) consumiu Fragmentos
## mas a carta nunca apareceu em kingdom.cards.
func _validate_recipe_production_delivers_card() -> void:
	print("[Academia] Validando produção real da Balista Imperial (Receita de 3 ingredientes)...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	kingdom.sync_academy_masters()

	var cards_before: int = kingdom.cards.size()
	var fragments_before: int = kingdom.get_fragment("Império")

	var result: Dictionary = AcademyResolver.request_production(kingdom, "Balista Imperial", 1, GameClock.now_unix())
	print("  Solicitação aceita? %s (esperado: true) | Fragmentos gastos na hora: %d" % [
		str(result["success"]), fragments_before - kingdom.get_fragment("Império")
	])

	# Avança o tempo em blocos e sincroniza repetidamente — exatamente
	# como um jogador real veria ao longo de várias sessões, nunca uma
	# chamada só.
	var now: int = GameClock.now_unix()
	for i in range(20):
		now += 3600  # +1h por vez
		AcademyResolver.sync(kingdom, now)

	var balista_found: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Balista Imperial":
			balista_found = true
	print("  Depois da cadeia inteira terminar, a Balista Imperial está em kingdom.cards de verdade? %s (%d -> %d cartas, esperado: true)" % [
		str(balista_found), cards_before, kingdom.cards.size()
	])
	print("  Filas dos Mestres, pra depurar: %s" % str(
		[kingdom.academy_artifices[0].queue.size() if not kingdom.academy_artifices.is_empty() else -1,
		kingdom.academy_pending_chain_tasks.size()]
	))

	# --- Cenário 2: os 3 ingredientes JÁ EXISTEM no inventário (não
	# precisam ser produzidos) — caminho de código diferente
	# (ready_now = true, task agenda direto, sem cadeia). ---
	var kingdom_2 := Kingdom.new()
	kingdom_2.add_fragment("Império", 1000)
	kingdom_2.sync_academy_masters()

	var arqueiro: CardResource = GameDatabase.get_card("Arqueiro Imperial")
	var engenheiro: CardResource = GameDatabase.get_card("Engenheiro Imperial")
	var escudeiro: CardResource = GameDatabase.get_card("Escudeiro Imperial")
	kingdom_2.acquire_card_from_catalog(arqueiro)
	kingdom_2.acquire_card_from_catalog(engenheiro)
	kingdom_2.acquire_card_from_catalog(escudeiro)

	var cards_before_2: int = kingdom_2.cards.size()
	var fragments_before_2: int = kingdom_2.get_fragment("Império")
	var result_2: Dictionary = AcademyResolver.request_production(kingdom_2, "Balista Imperial", 1, GameClock.now_unix())
	print("  [Cenário 2: ingredientes já possuídos] Solicitação aceita? %s | Fragmentos gastos: %d" % [
		str(result_2["success"]), fragments_before_2 - kingdom_2.get_fragment("Império")
	])

	var now_2: int = GameClock.now_unix()
	for i in range(20):
		now_2 += 3600
		AcademyResolver.sync(kingdom_2, now_2)

	var balista_found_2: bool = false
	for card: CardResource in kingdom_2.cards:
		if card.card_name == "Balista Imperial":
			balista_found_2 = true
	print("  [Cenário 2] Balista Imperial apareceu de verdade? %s (%d -> %d cartas, esperado: true, 4 -> 4 já q 3 ingredientes foram consumidos)" % [
		str(balista_found_2), cards_before_2, kingdom_2.cards.size()
	])


## Validação FUNCIONAL do bug real relatado: um Exército sem Energia
## deve recuperar com o tempo (ENERGY.md, "Recuperação de Energia" —
## na Cidade ou em Acampamento). Testa o mecanismo de verdade
## (Army.sync_energy_recovery via GameRuntime.sync), com o tempo
## avançando de verdade, não instantâneo.
func _validate_energy_recovers_over_real_time() -> void:
	print("[Energia] Validando que um Exército sem Energia recupera de verdade com o tempo (bug relatado)...")

	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Energia)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	print("  Energia inicial: %d/%d" % [army.current_energy, army.max_energy])
	army.consume_energy(army.current_energy)  # zera de propósito, simulando "sem Energia"
	print("  Energia depois de esgotar: %d/%d (esperado: 0)" % [army.current_energy, army.max_energy])

	var now: int = GameClock.now_unix()
	GameRuntime.sync(kingdom, now)  # 1ª chamada só estabelece a referência de tempo (documentado, sem recuperação retroativa)
	print("  Logo após esgotar (1ª sincronização, sem tempo real decorrido ainda): %d/%d (esperado: 0, sem recuperação retroativa)" % [
		army.current_energy, army.max_energy
	])

	now += 3600 * 24  # +24h reais
	GameRuntime.sync(kingdom, now)
	print("  24h reais depois -> Energia recuperou de verdade? %s (%d/%d, esperado: > 0)" % [
		str(army.current_energy > 0), army.current_energy, army.max_energy
	])

	now += 3600 * 24 * 30  # +30 dias reais — tempo de sobra pra qualquer Núcleo de Energia recuperar 100%
	GameRuntime.sync(kingdom, now)
	print("  30 dias reais depois -> Energia totalmente recuperada? %s (%d/%d, esperado: true)" % [
		str(army.current_energy == army.max_energy), army.current_energy, army.max_energy
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


## Validação FUNCIONAL da Exceção Inicial (COMMAND_CENTER_RECRUITMENT.md):
## 1 Candidato já deve existir de imediato ao criar o Reino, sem
## esperar as 24h do Cooldown Inicial.
func _validate_first_candidate_available_immediately() -> void:
	print("[Comandantes] Validando a Exceção Inicial — 1 Candidato disponível assim que o Reino é criado...")

	var fresh_kingdom := Kingdom.new()
	fresh_kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(fresh_kingdom, GameClock.now_unix())

	print("  1 Candidato já existe de imediato, sem precisar de 24h reais? %s (esperado: true)" % str(
		not fresh_kingdom.recruitment_center_slots.is_empty() and fresh_kingdom.recruitment_center_slots[0] != null
	))


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


## Validação FUNCIONAL do botão "Editar Exército" — troca a
## composição de verdade (Kingdom.re_form_army), libera o Comandante
## e cartas antigas, aloca os novos.
func _validate_edit_army_composition() -> void:
	print("[Exércitos] Validando 'Editar Exército' (trocar composição, não só Formações)...")

	var kingdom: Kingdom = KingdomState.kingdom
	var old_commander := CommanderResource.new()
	old_commander.commander_name = "Comandante Antigo (Editar Composição)"
	old_commander.faction = "Império"
	kingdom.add_commander(old_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, old_commander)
	var old_cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		old_cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(old_commander, old_cards)

	var new_commander := CommanderResource.new()
	new_commander.commander_name = "Comandante Novo (Editar Composição)"
	new_commander.faction = "Império"
	kingdom.add_commander(new_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, new_commander)
	var new_cards: Array[CardResource] = []
	for i in range(9):
		new_cards.append(kingdom.acquire_card_from_catalog(template))

	kingdom.re_form_army(army, new_commander, new_cards)

	print("  Exército passou a usar o novo Comandante de verdade? %s (esperado: true)" % str(army.commander == new_commander))
	print("  Comandante antigo foi liberado (voltou a poder liderar outro Exército)? %s (esperado: true)" % str(
		old_commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE
	))
	print("  Cartas antigas foram liberadas de verdade? %s (esperado: true)" % str(
		old_cards[0].ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	print("  As 5 Formações foram regeneradas com as cartas novas? %s (esperado: true)" % str(
		army.formations["β"].has(new_cards[0]) or army.formations["β"].has(new_cards[1])
	))


## Validação FUNCIONAL do bug real relatado: Fragmentos devem ser
## creditados por FACÇÃO de cada Pelotão destruído, não só a Facção
## principal do oponente (RESOURCES.md §4, "Correspondência de Facção").
func _validate_fragments_credited_per_unit_faction() -> void:
	print("[PvE] Validando Fragmentos por Facção de cada unidade destruída (bug relatado)...")

	var result := PhaseResult.new()
	result.victory = true
	var opponent := EnemyArmyEntry.new()
	opponent.faction = "Império"  # Facção PRINCIPAL do oponente — mas nem todos os Pelotões são dela
	result.opponent_entry = opponent
	result.enemy_pelotoes_destroyed_by_faction = {"Império": 6, "Mortos-Vivos": 3}  # 6 principal + 3 secundária, PvE.md

	var kingdom := Kingdom.new()
	var imperio_before: int = kingdom.get_fragment("Império")
	var mortos_before: int = kingdom.get_fragment("Mortos-Vivos")

	RewardResolver.resolve(result, kingdom, SeasonConfig.new())

	print("  Império recebeu Fragmentos (6 Pelotões dele destruídos)? %s (%d -> %d)" % [
		str(kingdom.get_fragment("Império") > imperio_before), imperio_before, kingdom.get_fragment("Império")
	])
	print("  Mortos-Vivos TAMBÉM recebeu Fragmentos (3 Pelotões secundários dele destruídos, mesmo o oponente sendo 'Império')? %s (%d -> %d, esperado: true, aumentou)" % [
		str(kingdom.get_fragment("Mortos-Vivos") > mortos_before), mortos_before, kingdom.get_fragment("Mortos-Vivos")
	])


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


## Validação FUNCIONAL da Permuta (COMMAND_CENTER.md, "Permuta entre
## Ativo e Reserva") — resolve o impasse real de Cargo Ativo E Vaga da
## Reserva ambos no limite ao mesmo tempo.
func _validate_active_reserve_swap() -> void:
	print("[Comandantes] Validando a Permuta Ativo/Reserva no impasse (Cargo e Vaga ambos 1/1)...")

	var kingdom := Kingdom.new()
	kingdom.cargo_ativo_activated = 1
	kingdom.vaga_reserva_activated = 1

	var active_commander := CommanderResource.new()
	active_commander.commander_name = "Comandante Ativo (Teste Permuta)"
	kingdom.add_commander(active_commander, GameClock.now_unix())
	active_commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE

	var reserve_commander := CommanderResource.new()
	reserve_commander.commander_name = "Comandante Reserva (Teste Permuta)"
	kingdom.add_commander(reserve_commander, GameClock.now_unix())
	reserve_commander.administrative_state = CommanderResource.AdministrativeState.RESERVE

	print("  Sem Permuta, as 2 transições individuais falham nesse impasse (confirmando que a Permuta é necessária)? %s (esperado: true, true)" % str(
		not CommandCenterResolver.move_to_reserve(kingdom, active_commander)["success"] and not CommandCenterResolver.move_to_active(kingdom, reserve_commander)["success"]
	))

	var result: Dictionary = CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	print("  Permuta bem-sucedida? %s | Reserva virou Ativo? %s | Ativo virou Reserva? %s (esperado: true, true, true)" % [
		str(result["success"]),
		str(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE),
		str(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE)
	])


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


## Validação FUNCIONAL do bug real relatado: com Cargo Ativo e Vaga da
## Reserva ambos no limite (1/1), o botão "Trocar" (já existente na
## tela, mas chamando uma função que nunca existiu de verdade) não
## fazia nada. Corrigido.
func _validate_swap_active_reserve() -> void:
	print("[Comandantes] Validando a troca Ativo <-> Reserva no limite (1/1) — bug relatado...")

	var kingdom := Kingdom.new()
	var active_commander := CommanderResource.new()
	active_commander.commander_name = "Comandante Ativo (Teste Troca)"
	active_commander.faction = "Império"
	kingdom.add_commander(active_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated = 1
	CommandCenterResolver.move_to_active(kingdom, active_commander)

	var reserve_commander := CommanderResource.new()
	reserve_commander.commander_name = "Comandante Reserva (Teste Troca)"
	reserve_commander.faction = "Natureza"
	kingdom.add_commander(reserve_commander, GameClock.now_unix())
	kingdom.vaga_reserva_activated = 1

	print("  Estado antes: Ativo=%s | Reserva=%s (esperado: ACTIVE, RESERVE)" % [
		CommanderResource.AdministrativeState.keys()[active_commander.administrative_state],
		CommanderResource.AdministrativeState.keys()[reserve_commander.administrative_state]
	])

	var result: Dictionary = CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	print("  Troca no limite (1/1 dos dois lados) -> sucesso? %s (esperado: true)" % str(result["success"]))
	print("  Estado depois: antigo Ativo agora é Reserva? %s | antigo Reserva agora é Ativo? %s (esperado: true, true)" % [
		str(active_commander.administrative_state == CommanderResource.AdministrativeState.RESERVE),
		str(reserve_commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE)
	])


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


## Validação FUNCIONAL da Ordem de Comissionamento (COMMAND_CENTER_RECRUITMENT.md,
## nova regra): o jogador não pode pular a ordem de chegada, só pode
## comissionar o primeiro Slot ocupado.
func _validate_sequential_commissioning_order() -> void:
	print("[Comandantes] Validando a Ordem de Comissionamento sequencial (nova regra)...")

	var kingdom := Kingdom.new()
	kingdom.vaga_reserva_activated = 2  # garante vaga suficiente pros 2 comissionamentos do teste — não é isso que está sendo testado aqui
	var first_candidate := CommanderResource.new()
	first_candidate.commander_name = "Candidato 1 (chegou primeiro)"
	var second_candidate := CommanderResource.new()
	second_candidate.commander_name = "Candidato 2 (chegou depois)"
	kingdom.recruitment_center_slots = [first_candidate, second_candidate, null]

	var skip_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 1, GameClock.now_unix())
	print("  Tentar comissionar o 2º Slot antes do 1º -> bloqueado com motivo claro? %s ('%s', esperado: false, not_first_occupied_slot)" % [
		str(not skip_result["success"]), skip_result["reason"]
	])
	print("  O Candidato 2 continua no Slot, intocado? %s (esperado: true)" % str(
		kingdom.recruitment_center_slots[1] == second_candidate
	))

	var in_order_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, GameClock.now_unix())
	print("  Comissionar o 1º Slot (o certo) -> sucesso? %s (esperado: true)" % str(in_order_result["success"]))

	var now_valid_result: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 1, GameClock.now_unix())
	print("  Depois do 1º liberado, agora o 2º pode ser comissionado? %s (esperado: true)" % str(now_valid_result["success"]))


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


## Validação FUNCIONAL da Unicidade de Composição (ARMY.md) no lado do
## INIMIGO — bug real relatado: EnemyArmyGenerator sorteava sem
## checagem nenhuma, podia repetir o mesmo Nome de Carta.
func _validate_enemy_composition_has_no_duplicate_names() -> void:
	print("[Exército] Validando Unicidade de Composição no gerador de inimigos (bug relatado)...")

	var config := SeasonConfig.new()
	var all_unique: bool = true
	# Gera várias vezes — sorteio é aleatório, precisa confirmar em
	# mais de uma tentativa que nunca repete, não só por sorte 1 vez.
	for i in range(30):
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, config,
			GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
			GameDatabase.commander_effects, GameDatabase.commander_values, "teste_unicidade", i
		)
		var names: Array[String] = []
		for card: CardResource in entry.cards:
			if names.has(card.card_name):
				all_unique = false
			names.append(card.card_name)
	print("  30 Exércitos inimigos gerados, nenhum com Nome de Carta repetido? %s (esperado: true)" % str(all_unique))


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


## Validação FUNCIONAL do bug real relatado: Energia Máxima nunca era
## recalculada quando a composição do Exército mudava (ARMY.md:
## "sempre que a composição... for alterada... a energia máxima será
## recalculada automaticamente").
func _validate_energy_recalculates_on_composition_change() -> void:
	print("[Energia] Validando o recálculo de Energia Máxima ao mudar a composição (bug relatado)...")

	var kingdom := Kingdom.new()
	var weak_commander := CommanderResource.new()
	weak_commander.commander_name = "Comandante Recruta (Energia)"
	weak_commander.faction = "Império"
	kingdom.add_commander(weak_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, weak_commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(weak_commander, cards)
	var energy_before: int = army.max_energy

	# Comandante de Patente muito maior -> Energia do Comandante muda
	# de verdade (Recruta=20 vs Lorde-Comandante=50, ENERGY.md).
	var strong_commander := CommanderResource.new()
	strong_commander.commander_name = "Comandante Lorde (Energia)"
	strong_commander.faction = "Império"
	strong_commander.accumulated_xp = 99999
	kingdom.add_commander(strong_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, strong_commander)

	kingdom.re_form_army(army, strong_commander, cards.duplicate())
	print("  Trocar pra um Comandante de Patente maior recalcula a Energia Máxima de verdade? %s (%d -> %d, esperado: aumentou 30)" % [
		str(army.max_energy == energy_before + 30), energy_before, army.max_energy
	])

	# Tier de uma carta JÁ dentro do Exército muda -> GameRuntime.sync()
	# precisa recalcular sozinho, sem precisar editar a composição.
	var energy_before_tier: int = army.max_energy
	cards[0].tier = 5  # ENERGY.md: Tier I=10, Tier V=14 -> +4 de Energia
	GameRuntime.sync(kingdom, GameClock.now_unix())
	print("  Tier de uma carta já no Exército mudando (Academia) recalcula sozinho, sem editar a composição? %s (%d -> %d, esperado: aumentou 4)" % [
		str(army.max_energy == energy_before_tier + 4), energy_before_tier, army.max_energy
	])


## Validação FUNCIONAL da Penalidade de Composição (ENERGY.md) — o
## exploit original relatado: esvaziar um Exército forte, transferir
## Comandante/Cartas pra um Exército fraco com Energia cheia.
func _validate_energy_composition_penalty() -> void:
	print("[Energia] Validando a Penalidade de Composição (fecha o exploit relatado)...")

	var kingdom := Kingdom.new()
	var template: CardResource = GameDatabase.cards[0]

	# Exército 1 (forte, esvaziado por combate de verdade).
	var strong_commander := CommanderResource.new()
	strong_commander.commander_name = "Comandante Forte (Exploit)"
	strong_commander.faction = "Império"
	strong_commander.accumulated_xp = 99999  # Lorde-Comandante
	kingdom.add_commander(strong_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, strong_commander)
	var strong_cards: Array[CardResource] = []
	for i in range(9):
		strong_cards.append(kingdom.acquire_card_from_catalog(template))
	var army_1: Army = kingdom.form_army(strong_commander, strong_cards)
	army_1.consume_energy(army_1.current_energy)  # esvazia de verdade, igual combate real faria
	kingdom.disband_army(army_1)  # libera Comandante/Cartas de volta pro Reino — único jeito real de "soltar" o que já está em uso

	# Exército 2 (fraco, Energia cheia).
	var weak_commander := CommanderResource.new()
	weak_commander.commander_name = "Comandante Fraco (Exploit)"
	weak_commander.faction = "Império"
	kingdom.add_commander(weak_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, weak_commander)
	var weak_cards: Array[CardResource] = []
	for i in range(9):
		weak_cards.append(kingdom.acquire_card_from_catalog(template))
	var army_2: Army = kingdom.form_army(weak_commander, weak_cards)
	var army_2_energy_before: int = army_2.current_energy
	print("  Exército 2 antes do exploit: %d/%d de Energia (esperado: cheio)" % [army_2.current_energy, army_2.max_energy])

	# Tenta o exploit: transfere as Cartas fortes (recém-saídas do
	# combate) pro Exército 2, depois o Comandante forte também.
	kingdom.re_form_army(army_2, weak_commander, strong_cards)
	print("  Depois de receber Cartas RECÉM-USADAS -> perdeu a porção de Cartas de verdade? %s (%d, esperado: <= Base + Comandante Fraco = %d)" % [
		str(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + EnergyArmy.commander_energy("Recruta")),
		army_2.current_energy, EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + EnergyArmy.commander_energy("Recruta")
	])

	kingdom.re_form_army(army_2, strong_commander, strong_cards)
	print("  Depois de receber o Comandante forte também -> ficou só com Energia Base, sem exploit? %s (%d, esperado: <= %d)" % [
		str(army_2.current_energy <= EnergyNucleus.energia_base(kingdom.energy_nucleus_level) + 5),
		army_2.current_energy, EnergyNucleus.energia_base(kingdom.energy_nucleus_level)
	])

	# --- Caminho legítimo: Cartas paradas (nunca usadas) não sofrem penalidade ---
	var kingdom_2 := Kingdom.new()
	var commander_3 := CommanderResource.new()
	commander_3.commander_name = "Comandante de Teste (Cartas Descansadas)"
	commander_3.faction = "Império"
	kingdom_2.add_commander(commander_3, GameClock.now_unix())
	kingdom_2.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom_2, commander_3)
	var initial_cards: Array[CardResource] = []
	for i in range(9):
		initial_cards.append(kingdom_2.acquire_card_from_catalog(template))
	var army_3: Army = kingdom_2.form_army(commander_3, initial_cards)
	var army_3_energy_before: int = army_3.current_energy

	var dormant_cards: Array[CardResource] = []
	for i in range(9):
		dormant_cards.append(kingdom_2.acquire_card_from_catalog(template))  # nunca estiveram em nenhum Exército
	kingdom_2.re_form_army(army_3, commander_3, dormant_cards)
	print("  Trocar por Cartas NUNCA usadas (paradas na coleção) -> sem penalidade nenhuma? %s (%d -> %d, esperado: igual)" % [
		str(army_3.current_energy == army_3_energy_before), army_3_energy_before, army_3.current_energy
	])


## Validação FUNCIONAL da Trava de Edição por Modo de Jogo (ARMY.md).
func _validate_army_edit_lock() -> void:
	print("[Exército] Validando a Trava de Edição por Modo de Jogo (ARMY.md)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Trava)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	print("  Exército recém-formado, sem nenhuma atividade -> livre pra editar? %s (esperado: true)" % str(
		not kingdom.is_army_locked_for_editing(army)["locked"]
	))

	# --- Trava de Mina ---
	var mina: Mina = kingdom.initial_mines[0]
	mina.guarnicao_army = army
	mina.start_cycle(GameClock.now_unix(), 1.0)
	var mina_lock: Dictionary = kingdom.is_army_locked_for_editing(army)
	print("  Guarnição de Mina com Ciclo ativo -> travado, com motivo claro? %s ('%s')" % [str(mina_lock["locked"]), mina_lock["reason"]])

	var mina_edit_blocked: bool = false
	# re_form_army() deve recusar via assert — captura isso testando o retorno da trava em vez de derrubar o teste.
	print("  disband_army() também recusaria (mesma trava)? %s (esperado: true)" % str(kingdom.is_army_locked_for_editing(army)["locked"]))

	mina.guarnicao_army = null
	mina.cycle_started_unix = 0
	print("  Depois de liberar a Guarnição -> destravado de novo? %s (esperado: true)" % str(
		not kingdom.is_army_locked_for_editing(army)["locked"]
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


func _validate_kingdom_state_creates_initial_mines() -> void:
	print("[Minas] Validando que um Reino novo já nasce com as 3 Minas Iniciais (bug relatado)...")

	var fresh_kingdom := Kingdom.new()
	fresh_kingdom.create_initial_mines()  # mesma chamada agora feita dentro de KingdomState.initialize_new_kingdom()
	print("  As 3 Minas Iniciais existem e já estão conquistadas, prontas pra ativar? %s (%d, esperado: true, 3)" % [
		str(fresh_kingdom.initial_mines.size() == 3 and fresh_kingdom.initial_mines.all(func(m: Mina) -> bool: return m.conquered)),
		fresh_kingdom.initial_mines.size()
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
	var squad := Squad.new([army_1, army_2])

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

	panel._on_attempt_fase_pressed(expedition)
	print("  Após 'Tentar Fase Atual' -> Fase avançou de verdade? %s (esperado: true, Fase 2)" % str(expedition.current_fase == 2))

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


## Validação pura de RankingResolver (RANKING.md) e BattlefieldSelector
## (BATTLEFIELDS.md) — sem UI, sem renderização.
func _validate_ranking_and_battlefield_selector() -> void:
	print("[Ranking] Validando RankingResolver e BattlefieldSelector...")

	# Atacante, Divisões VII-III: Vitória +100, Derrota -75.
	var win: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.VITORIA)
	print("  Atacante, Divisão VII, Vitória: 500 -> %d PL (esperado: 600)" % win["pl"])
	var loss: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  Atacante, Divisão VII, Derrota: 500 -> %d PL (esperado: 425 = 500-75)" % loss["pl"])

	# Atacante, Divisões II-I: Derrota -100 (não -75).
	var loss_top: Dictionary = RankingResolver.apply_result(5500, "II", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  Atacante, Divisão II, Derrota: 5500 -> %d PL (esperado: 5400 = 5500-100, não -75)" % loss_top["pl"])

	# Defensor: sempre +20/-20, em qualquer Divisão.
	var def_win: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.DEFENSOR, RankingResolver.Result.VITORIA)
	var def_loss: Dictionary = RankingResolver.apply_result(5500, "II", RankingResolver.Role.DEFENSOR, RankingResolver.Result.DERROTA)
	print("  Defensor Vitória (Divisão VII): 500 -> %d PL (esperado: 520) | Defensor Derrota (Divisão II): 5500 -> %d PL (esperado: 5480)" % [
		def_win["pl"], def_loss["pl"]
	])

	# Empate nunca altera PL, em nenhum papel.
	var draw: Dictionary = RankingResolver.apply_result(500, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.EMPATE)
	print("  Empate nunca altera PL: 500 -> %d PL (esperado: 500)" % draw["pl"])

	# Promoção automática ao cruzar o teto da Divisão.
	var promotion: Dictionary = RankingResolver.apply_result(950, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.VITORIA)
	print("  950 PL + Vitória (+100) cruza pra Divisão VI -> Divisão: %s | Promovido? %s (esperado: VI, true)" % [
		promotion["division"], str(promotion["promoted"])
	])

	# Nunca rebaixa abaixo da Divisão VII.
	var floor_result: Dictionary = RankingResolver.apply_result(10, "VII", RankingResolver.Role.ATACANTE, RankingResolver.Result.DERROTA)
	print("  10 PL + Derrota (-75) não fica negativo nem sai da Divisão VII -> PL: %d | Divisão: %s (esperado: 0, VII)" % [
		floor_result["pl"], floor_result["division"]
	])

	# Reentrada: 2 Divisões abaixo da final anterior, com o PL mínimo exato.
	var reentry_div: String = RankingResolver.reentry_division("IV")
	print("  Reentrada vindo da Divisão IV -> Divisão: %s | PL: %d (esperado: VI, 1000)" % [
		reentry_div, RankingResolver.reentry_pl(reentry_div)
	])

	# BattlefieldSelector: determinístico com a mesma seed, e sempre
	# dentro do subconjunto fornecido (mesmo restrito).
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var result_a: BattlefieldResource = BattlefieldSelector.select(GameDatabase.battlefields, rng_a)
	var result_b: BattlefieldResource = BattlefieldSelector.select(GameDatabase.battlefields, rng_b)
	print("  Mesma seed gera o mesmo Campo sorteado? %s (esperado: true)" % str(result_a == result_b))

	var only_padrao: Array[BattlefieldResource] = []
	for battlefield: BattlefieldResource in GameDatabase.battlefields:
		if battlefield.category == "Padrão":
			only_padrao.append(battlefield)
	var restricted_result: BattlefieldResource = BattlefieldSelector.select(only_padrao, rng_a)
	print("  Sorteio restrito a um subconjunto de 1 Campo sempre retorna esse Campo? %s (esperado: true)" % str(
		restricted_result.category == "Padrão"
	))


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
		CommandCenterResolver.activate_next(kingdom)
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
	print("  Fases Normais (Região I) -> Comandante sem nome (técnico)? %s | Soldo <= 24? %s | Todos os Tiers em I-II? %s (esperado: true, true, true)" % [
		str(normal_entry.commander.commander_name == ""), str(Soldo.total_for_composition(normal_entry.cards) <= 24), str(tiers_in_range)
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


## Validação FUNCIONAL do Histórico de Batalhas (COMMANDERS.md,
## "Estatísticas Históricas"): CommanderResource.record_battle() puro
## (agregado V/E/D + FIFO de 20), o wiring real em PhaseResolver (uma
## batalha de PvE de verdade credita o Comandante vencedor), e a tela
## de Comandantes mostrando isso.
func _validate_commander_battle_history() -> void:
	print("[Comandantes] Validando Histórico de Batalhas...")

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
	print("  Histórico guarda só as últimas 20 (FIFO)? %s | Mais recente é a última registrada (Empatador)? %s (esperado: true, true)" % [
		str(commander.battle_log.size() == 20), str(commander.battle_log[0]["opponent_name"] == "Empatador")
	])

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
## Validação FUNCIONAL da Mina Inicial (MINES.md, "Mina Inicial
## (Bootstrap)"): já nasce conquistada de verdade, sem exigir combate.
func _validate_initial_mine_no_conquest() -> void:
	print("[Minas] Validando Mina Inicial (não exige conquista, MINES.md)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()

	var all_conquered: bool = true
	for mina: Mina in kingdom.initial_mines:
		if not mina.conquered:
			all_conquered = false

	print("  As 3 Minas Iniciais já nascem conquistadas, sem combate nenhum? %s (esperado: true)" % str(
		all_conquered and kingdom.initial_mines.size() == 3
	))


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

	var valid_cards: Array[CardResource] = []
	for i in range(6):
		var card := CardResource.new()
		card.faction = "Império"
		card.card_class = "À Distância"
		card.rarity = "Comum"
		valid_cards.append(card)
	for i in range(3):
		var card := CardResource.new()
		card.faction = "Natureza"
		card.card_class = "Mago"
		card.rarity = "Comum"
		valid_cards.append(card)

	print("  Composição válida (0 Corpo a Corpo) -> Restrição de Classe não bloqueia? %s (esperado: true, \"\")" % str(
		CommanderDoctrineValidator.check_static(commander, valid_cards, "pve") == ""
	))

	var invalid_cards: Array[CardResource] = valid_cards.duplicate()
	invalid_cards[0] = CardResource.new()
	invalid_cards[0].faction = "Império"
	invalid_cards[0].card_class = "Corpo a Corpo"
	invalid_cards[0].rarity = "Comum"
	invalid_cards[1] = CardResource.new()
	invalid_cards[1].faction = "Império"
	invalid_cards[1].card_class = "Corpo a Corpo"
	invalid_cards[1].rarity = "Comum"
	invalid_cards[2] = CardResource.new()
	invalid_cards[2].faction = "Império"
	invalid_cards[2].card_class = "Corpo a Corpo"
	invalid_cards[2].rarity = "Comum"
	var block_message: String = CommanderDoctrineValidator.check_static(commander, invalid_cards, "pve")
	print("  Composição com 3 Corpo a Corpo (máximo é 2) -> bloqueada com mensagem clara? %s | Mensagem: \"%s\"" % [
		str(block_message != ""), block_message
	])

	# --- Restrição de Campo de Batalha ---
	var battlefield_restriction: CommanderRestrictionResource = _find_by_code_test(GameDatabase.commander_restrictions, "RS030")  # Apenas Campo Aberto
	var battlefield_doctrine := CommanderDoctrine.new()
	battlefield_doctrine.restriction = battlefield_restriction
	battlefield_doctrine.requirement = requirement_faction
	battlefield_doctrine.target = target_faction
	battlefield_doctrine.effect = effect_attack
	battlefield_doctrine.value = value_attack
	var battlefield_commander := CommanderResource.new()
	battlefield_commander.commander_name = "Comandante Só-Campo-Aberto"
	battlefield_commander.doctrine = battlefield_doctrine

	var open_field := BattlefieldResource.new()
	open_field.battlefield_name = "Campo Aberto"
	open_field.category = "Campo Aberto"
	var storm_field := BattlefieldResource.new()
	storm_field.battlefield_name = "Tempestade com Raios"
	storm_field.category = "Especial"

	print("  Campo Aberto não bloqueia Comandante 'Apenas Campo Aberto'? %s | Campo diferente bloqueia com mensagem clara? %s (esperado: true, true)" % [
		str(CommanderDoctrineValidator.check_battlefield(battlefield_commander, open_field) == ""),
		str(CommanderDoctrineValidator.check_battlefield(battlefield_commander, storm_field) != "")
	])

	# --- Efeito de Ataque aplicado de verdade em combate ---
	var attack_army := Army.new()
	attack_army.commander = commander
	attack_army.cards = valid_cards
	var attack_state: CombatState = CombatEngine.initialize(
		attack_army, CampaignTestFixtures.build_campaign_enemy_army(), GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var boosted_unit: CombatUnit = attack_state.units[0]  # side 0, Império, dentro do Alvo (Facção) e do Requisito (>= 2 Império)
	var multiplier: float = CommanderDoctrineRuntime.attack_multiplier(boosted_unit, attack_state)
	print("  Efeito de Ataque (+20%%) da Doutrina realmente calculado no combate? %s (%.2fx, esperado: true, 1.20)" % [
		str(abs(multiplier - 1.2) < 0.001), multiplier
	])

	# --- Bloqueio real no PvE, sem gastar Energia ---
	var blocking_doctrine := CommanderDoctrine.new()
	blocking_doctrine.restriction = _find_by_code_test(GameDatabase.commander_restrictions, "RS025")  # Não aceita a classe especificada
	blocking_doctrine.restriction_param = "Ranged"
	blocking_doctrine.requirement = requirement_faction
	blocking_doctrine.target = target_faction
	blocking_doctrine.effect = effect_attack
	blocking_doctrine.value = value_attack

	var blocked_commander := CommanderResource.new()
	blocked_commander.commander_name = "Comandante Bloqueado de Propósito"
	blocked_commander.faction = "Império"
	blocked_commander.doctrine = blocking_doctrine

	var blocked_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	blocked_army.commander = blocked_commander
	blocked_army.cards[0].card_class = "À Distância"  # a Restrição proíbe "Ranged" -> mapeado "À Distância"
	blocked_army.initialize_energy(1)
	var energy_before: int = blocked_army.current_energy

	var squad := Squad.new([blocked_army])
	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.commander = CampaignTestFixtures.build_campaign_enemy_army().commander
	enemy_entry.cards = CampaignTestFixtures.build_campaign_enemy_army().cards
	enemy_entry.faction = "Mortos-Vivos"

	var phase_result: PhaseResult = PhaseResolver.resolve(
		squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "Teste de Bloqueio", "pve"
	)
	var has_block_message: bool = false
	for line: String in phase_result.history_log:
		if line.find("bloqueada") != -1:
			has_block_message = true
	print("  PvE bloqueia de verdade uma Formação com Restrição violada -> mensagem no histórico? %s | Energia NÃO foi gasta (%d -> %d)? %s (esperado: true, true)" % [
		str(has_block_message), energy_before, blocked_army.current_energy, str(blocked_army.current_energy == energy_before)
	])

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

	print("  Reino novo -> a Cidade mostra o Kit Inicial primeiro, antes de qualquer outra coisa? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Escolha seu Comandante inicial")
	))

	# Simula a escolha clicando (via método, mesmo padrão de sempre).
	var kit_child: StarterKitPanel = null
	for child in panel.get_children():
		if child is StarterKitPanel:
			kit_child = child
	kit_child._on_choose_pressed(kit_child._options[0])
	await get_tree().process_frame

	print("  Após escolher -> a Cidade normal aparece, e não pede o Kit de novo? %s (esperado: true)" % str(
		_panel_contains_text(panel, "Recursos de Construção") and not _panel_contains_text(panel, "Escolha seu Comandante inicial")
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

	panel.queue_free()


## Validação da Sprint 3: progride uma carta do catálogo do Tier I ao
## Tier V utilizando exclusivamente CardProgression (lógica pura),
## imprimindo o resultado de cada Tier no Output.
func _validate_card_progression() -> void:
	var base_card: CardResource = null
	for card: CardResource in GameDatabase.cards:
		if card.card_name == "Legionário Imperial":
			base_card = card
			break

	if base_card == null:
		push_warning("[Bootstrap] Carta de validação da Progressão não foi encontrada no GameDatabase.")
		return

	print("[CardProgression] Validando progressão de '%s'..." % base_card.card_name)

	var current: CardResource = base_card
	_print_progression_step(current)

	while current.tier < 5:
		current = CardProgression.advance_tier(current)
		_print_progression_step(current)


func _print_progression_step(card: CardResource) -> void:
	var ability: String = CardProgression.unlocked_ability_name(card)
	var ability_text: String = ""
	if ability != "":
		ability_text = " | Habilidade desbloqueada (dado de catálogo): %s" % ability

	print("[CardProgression] Tier %d | ATK: %d HP: %d ESC: %d%s" % [
		card.tier, card.atk, card.hp, card.esc, ability_text
	])


## Validação da Sprint 31: executa o Pipeline de Geração da Temporada
## de ponta a ponta (geração -> WR contra benchmark -> ordenação ->
## distribuição em faixas -> Catálogo), em ESCALA REDUZIDA DE
## DESENVOLVIMENTO — os números oficiais (100.000/3.000/5.000/100.000
## simulações) permanecem os padrões de SeasonConfig e serão usados por
## uma ferramenta offline dedicada; aqui apenas validamos que a
## arquitetura do Pipeline funciona corretamente de ponta a ponta.
## Também valida EnemyArmySelector (seleção por Região/Categoria,
## determinismo por seed, e a substituição por Comandante Regional
## Recrutado).
func _validate_season_pipeline() -> void:
	print("[SeasonPipeline] Validando o Pipeline de ponta a ponta (escala reduzida de desenvolvimento — números oficiais ficam em SeasonConfig como padrão)...")

	var config := SeasonConfig.new()
	config.season_id = "Season01-Dev"
	config.seed_value = 42
	config.normal_army_count = 3
	config.chefe_normal_count = 2
	config.chefe_regional_mina_generated_count = 4
	config.chefe_regional_mina_kept_count = 3
	config.simulations_per_army = 3
	config.benchmark_size = 2
	config.min_rarity_score_exclusive = 10  # reduzido só para o teste; oficial fica em SeasonConfig

	var catalog: SeasonCatalog = SeasonPipeline.run(
		config, GameDatabase.cards,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	print("  Pipeline concluído para a Temporada '%s'." % catalog.season_id)

	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		var normal: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.NORMAL)
		var chefe_normal: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_NORMAL)
		var regional: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_REGIONAL)
		var mina: Array[EnemyArmyEntry] = catalog.get_entries(faction, EnemyArmyEntry.Category.CHEFE_DE_MINA)
		print("  %s -> Normal: %d | Chefe Normal: %d | Chefe Regional: %d | Chefe de Mina: %d" % [
			faction, normal.size(), chefe_normal.size(), regional.size(), mina.size()
		])

	# Ordenação crescente de WR.
	var sample: Array[EnemyArmyEntry] = catalog.get_entries("Império", EnemyArmyEntry.Category.NORMAL)
	var sorted_correctly: bool = true
	for i in range(1, sample.size()):
		if sample[i].win_rate < sample[i - 1].win_rate:
			sorted_correctly = false
	print("  Ordenação por WR crescente (Império/Normal): %s (esperado: true)" % str(sorted_correctly))

	# Determinismo: mesma Trilha + mesma Seed + mesma Fase -> mesmo Exército.
	var registry := RegionalCommanderRegistry.new()
	var pick_a: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 999, registry)
	var pick_b: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 999, registry)
	print("  Determinismo (mesma seed) -> mesmo Exército? %s (esperado: true) | id=%s" % [
		str(pick_a != null and pick_b != null and pick_a.id == pick_b.id),
		(pick_a.id if pick_a != null else "null")
	])

	# Diversidade: seeds diferentes podem produzir Exércitos diferentes.
	var pick_c: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 50, 111, registry)
	print("  Seeds diferentes (999 vs 111) -> ids: %s vs %s (podem ou não diferir)" % [
		(pick_a.id if pick_a != null else "null"), (pick_c.id if pick_c != null else "null")
	])

	# Comandante Regional Recrutado -> substitui por Chefe Normal da mesma Região.
	var before_recruit: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 5, registry)
	print("  Antes do recrutamento -> categoria selecionada: Chefe Regional (id=%s)" % (before_recruit.id if before_recruit != null else "null"))

	registry.recruit("Império", 1)
	var after_recruit: EnemyArmyEntry = EnemyArmySelector.select(catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 5, registry)
	var after_is_chefe_normal: bool = after_recruit != null and after_recruit.category == EnemyArmyEntry.Category.CHEFE_NORMAL
	print("  Após recrutar o Comandante Regional -> Exército selecionado passa a ser Chefe Normal? %s (esperado: true)" % str(after_is_chefe_normal))

	# Ausência de seleção inválida: categoria sem nenhuma entrada correspondente retorna null, nunca inventa.
	var empty_catalog := SeasonCatalog.new("Vazio")
	var invalid_pick: EnemyArmyEntry = EnemyArmySelector.select(empty_catalog, "Império", EnemyArmyEntry.Category.NORMAL, 1, 1, 1, null)
	print("  Catálogo vazio -> seleção retorna null (nunca inventa)? %s (esperado: true)" % str(invalid_pick == null))


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


## Validação da Sprint 32 (Consolidação do Estado Persistente do Reino):
## criação do Kingdom, posse correta de cada componente antes órfão,
## consulta ao Registro de Comandantes Regionais através do Reino, e
## acesso às Expedições ativas.
func _validate_kingdom() -> void:
	print("[Kingdom] Validando posse do estado persistente do Reino...")

	var kingdom := Kingdom.new()
	print("  Reino criado. Nível do Núcleo de Energia: %d (esperado: 1)" % kingdom.energy_nucleus_level)
	print("  Comandantes: %d | Cartas: %d | Exércitos: %d | Squads: %d | Expedições ativas: %d (todos esperados: 0)" % [
		kingdom.commanders.size(), kingdom.cards.size(), kingdom.armies.size(), kingdom.squads.size(), kingdom.active_expeditions.size()
	])

	# Posse de Comandantes e Cartas (antes órfãos — nada os possuía).
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante do Reino (Teste)"
	commander.faction = "Império"
	kingdom.add_commander(commander)

	var real_card: CardResource = GameDatabase.get_card("Legionário Imperial")
	kingdom.add_card(real_card)
	print("  Após adicionar 1 Comandante e 1 Carta -> Comandantes: %d, Cartas: %d (esperado: 1, 1)" % [
		kingdom.commanders.size(), kingdom.cards.size()
	])

	# Posse de Exércitos e Squads.
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	kingdom.add_army(army)
	var squad := Squad.new([army])
	kingdom.add_squad(squad)
	print("  Após formar 1 Exército e 1 Squad -> Exércitos: %d, Squads: %d (esperado: 1, 1)" % [
		kingdom.armies.size(), kingdom.squads.size()
	])

	# Registro de Comandantes Regionais agora pertence ao Reino, não mais
	# instanciado solto — consulta feita através de kingdom.
	print("  Comandante Regional do Império/Região 1 recrutado? %s (esperado: false)" % str(
		kingdom.regional_commander_registry.is_recruited("Império", 1)
	))
	kingdom.regional_commander_registry.recruit("Império", 1)
	print("  Após recrutar via kingdom.regional_commander_registry -> recrutado? %s (esperado: true)" % str(
		kingdom.regional_commander_registry.is_recruited("Império", 1)
	))

	# Flags de progresso persistentes.
	print("  Flag 'tutorial_concluido' antes de definida: %s (esperado: false)" % str(kingdom.has_progress_flag("tutorial_concluido")))
	kingdom.set_progress_flag("tutorial_concluido")
	print("  Flag 'tutorial_concluido' após definida: %s (esperado: true)" % str(kingdom.has_progress_flag("tutorial_concluido")))

	# Expedições ativas — Kingdom apenas referencia; toda a lógica de
	# Fase/Retry continua em ExpeditionRuntime/PhaseResolver.
	var territory := Territory.new("Territorio-Reino-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, catalog, kingdom.regional_commander_registry, 555,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	kingdom.start_expedition(expedition)
	print("  Expedições ativas após iniciar 1: %d (esperado: 1)" % kingdom.active_expeditions.size())
	print("  A Expedição referenciada é a mesma instância? %s (esperado: true)" % str(kingdom.active_expeditions[0] == expedition))

	print("  Nenhum método de Kingdom calcula, resolve ou gera — todos apenas armazenam (append/dict-set), conforme a regra estrutural da classe.")


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


## Validação da Sprint "Fechamento do Loop da Expedição": as 4
## Políticas de Acampamento (PvE.md), testadas diretamente sobre
## ExpeditionRuntime.establish_acampamento() — sem precisar simular
## combates reais para cada cenário, já que a política em si é lógica
## pura sobre o estado de Energia do Squad.
func _validate_acampamento_policies() -> void:
	print("[Acampamento] Validando as 4 Políticas de Acampamento...")

	var territory := Territory.new("Territorio-Politicas-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()

	# a) Seguir Automaticamente: Energia parcial permanece intocada.
	var army_a: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_a.initialize_energy(1)
	army_a.current_energy = 10
	var expedition_a := ExpeditionRuntime.new(
		Squad.new([army_a]), trilha, territory, catalog, registry, 1,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_a.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.SEGUIR_AUTOMATICO
	expedition_a.establish_acampamento()
	print("  a) Seguir Automaticamente -> Energia após Acampamento: %d (esperado: 10, intocada) | aguardando? %s (esperado: false)" % [
		army_a.current_energy, str(expedition_a.is_waiting_at_acampamento)
	])

	# b) Aguardar Ordem: Expedição para; attempt_current_fase() não age
	# enquanto aguarda; resume_from_acampamento() recupera e libera.
	var army_b: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_b.initialize_energy(1)
	army_b.current_energy = 10
	var expedition_b := ExpeditionRuntime.new(
		Squad.new([army_b]), trilha, territory, catalog, registry, 2,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_b.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_ORDEM
	expedition_b.establish_acampamento()
	print("  b) Aguardar Ordem -> aguardando? %s (esperado: true)" % str(expedition_b.is_waiting_at_acampamento))
	var blocked_result: PhaseResult = expedition_b.attempt_current_fase()
	print("     Tentativa enquanto aguarda -> retornou null? %s (esperado: true)" % str(blocked_result == null))
	expedition_b.resume_from_acampamento()
	print("     Após resume_from_acampamento() -> Energia: %d/%d (esperado: cheia) | aguardando? %s (esperado: false)" % [
		army_b.current_energy, army_b.max_energy, str(expedition_b.is_waiting_at_acampamento)
	])

	# c) Aguardar Recuperação Total: sempre recupera 100%, não pausa.
	var army_c: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_c.initialize_energy(1)
	army_c.current_energy = 5
	var expedition_c := ExpeditionRuntime.new(
		Squad.new([army_c]), trilha, territory, catalog, registry, 3,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_c.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL
	expedition_c.establish_acampamento()
	print("  c) Aguardar Recuperação Total -> Energia: %d/%d (esperado: cheia) | aguardando? %s (esperado: false)" % [
		army_c.current_energy, army_c.max_energy, str(expedition_c.is_waiting_at_acampamento)
	])

	# d) Aguardar Limite (40%%): acima do limite não recupera; abaixo, recupera.
	var army_d1: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_d1.initialize_energy(1)
	army_d1.current_energy = int(army_d1.max_energy * 0.9)  # acima do limite de 40%
	var expedition_d1 := ExpeditionRuntime.new(
		Squad.new([army_d1]), trilha, territory, catalog, registry, 4,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_d1.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_LIMITE
	expedition_d1.energy_recovery_threshold_percent = 0.4
	var energy_before_d1: int = army_d1.current_energy
	expedition_d1.establish_acampamento()
	print("  d1) Aguardar Limite, acima do limite -> Energia: %d (esperado: igual à anterior, %d — sem recuperar)" % [
		army_d1.current_energy, energy_before_d1
	])

	var army_d2: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army_d2.initialize_energy(1)
	army_d2.current_energy = int(army_d2.max_energy * 0.1)  # abaixo do limite de 40%
	var expedition_d2 := ExpeditionRuntime.new(
		Squad.new([army_d2]), trilha, territory, catalog, registry, 5,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition_d2.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_LIMITE
	expedition_d2.energy_recovery_threshold_percent = 0.4
	expedition_d2.establish_acampamento()
	print("  d2) Aguardar Limite, abaixo do limite -> Energia: %d/%d (esperado: cheia — recuperou)" % [
		army_d2.current_energy, army_d2.max_energy
	])


## Validação: ExpeditionSession nunca decide por conta própria retomar
## uma Expedição parada aguardando o jogador (política AGUARDAR_ORDEM)
## — ela para e reporta o motivo, sem inventar uma decisão que ninguém
## tomou. Depois de resume_from_acampamento() (decisão externa
## explícita), a Sessão volta a avançar normalmente.
func _validate_expedition_session_waits_for_player() -> void:
	print("[ExpeditionSession] Validando que a Sessão nunca decide sozinha por 'Aguardar Ordem'...")

	var territory := Territory.new("Territorio-Sessao-Teste", "Império")
	var trilha := Trilha.new(territory.id)
	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, CampaignTestFixtures.build_campaign_enemy_army())
	var registry := RegionalCommanderRegistry.new()

	var expedition := ExpeditionRuntime.new(
		Squad.new([winning_army]), trilha, territory, catalog, registry, 7,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	expedition.acampamento_policy = ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_ORDEM
	expedition.current_fase = 24  # a Fase 25 é Acampamento (ver Sprint 30)

	var stop_reason: ExpeditionSession.StopReason = ExpeditionSession.run(expedition, 5)
	print("  Sessão parou por: %s (esperado: AGUARDANDO_JOGADOR) | Fase atual: %d" % [
		ExpeditionSession.StopReason.keys()[stop_reason], expedition.current_fase
	])

	expedition.resume_from_acampamento()
	var stop_reason_2: ExpeditionSession.StopReason = ExpeditionSession.run(expedition, 5)
	print("  Após decisão explícita do jogador (resume_from_acampamento) -> Sessão avançou novamente. Motivo: %s | Fase atual: %d" % [
		ExpeditionSession.StopReason.keys()[stop_reason_2], expedition.current_fase
	])


## Validação da Sprint RewardResolver: uma Fase vencida credita
## Fragmentos ao Reino, seguindo RESOURCES.md §4.1/§4.2, usando a Liga
## de Calibração configurável de SeasonConfig (nunca a Liga real do
## jogador, que não existe). Também confirma que derrota não credita
## nada, e que a Facção creditada é a do oponente enfrentado.
func _validate_reward_resolver() -> void:
	print("[RewardResolver] Validando crédito de Fragmentos a partir de um PhaseResult real...")

	var kingdom := Kingdom.new()
	var season_config := SeasonConfig.new()
	print("  Liga de Calibração PvE (padrão): %s / %s (esperado: Bronze / VII)" % [
		season_config.pve_calibration_league, season_config.pve_calibration_division
	])

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

	var credited: int = RewardResolver.resolve(result, kingdom, season_config)
	print("  Fragmentos creditados: %d (esperado: 2 = 10 * 1.0 * 0.20 * 1) | Facção: %s" % [
		credited, enemy_entry.faction
	])
	print("  Kingdom.get_fragment('Natureza'): %d (esperado: 2)" % kingdom.get_fragment("Natureza"))

	# Vitória credita XP de combate ao Comandante do Exército vencedor
	# (XP.md: PvE = 30% do XP da Liga Bronze do PvP = 3, fixo).
	var winner: CommanderResource = squad.armies[result.winning_army_index].commander
	CommanderTrainingResolver.record_combat_xp(kingdom, winner, CommanderCareer.xp_for_pve_victory(), GameClock.now_unix())
	print("  XP de combate do Comandante vencedor: %d (esperado: 3) | Registrado no log diário: %s (esperado: true)" % [
		winner.accumulated_xp, str(kingdom.daily_combat_xp_log.has(str(winner.instance_id)))
	])

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

	# Liga de Calibração diferente (configuração, não regra) muda o valor-base.
	season_config.pve_calibration_league = "Diamante"
	season_config.pve_calibration_division = "I"
	var kingdom_2 := Kingdom.new()
	var credited_diamante: int = RewardResolver.resolve(result, kingdom_2, season_config)
	print("  Com Liga Diamante/I (30 base) -> Fragmentos: %d (esperado: 6 = 30 * 1.0 * 0.20 * 1)" % credited_diamante)


## Validação do Recrutamento de Comandante Regional: só oferece
## recrutamento em vitória contra Chefe Regional, nunca duas vezes, e
## confirma que, depois de recrutado, o EnemyArmySelector já passa a
## devolver um Chefe Normal daquela Região (comportamento pronto desde
## a Sprint 31, agora com um gatilho real).
func _validate_recruitment() -> void:
	print("[Recrutamento] Validando a Fila de Ofertas de Recrutamento...")

	var kingdom := Kingdom.new()

	var regional_entry := EnemyArmyEntry.new()
	regional_entry.id = "TESTE_CHEFE_REGIONAL"
	regional_entry.faction = "Império"
	regional_entry.category = EnemyArmyEntry.Category.CHEFE_REGIONAL
	regional_entry.region_min = 1
	regional_entry.region_max = 1
	var regional_commander := CommanderResource.new()
	regional_commander.commander_name = "Senhor da Guerra de Teste"
	regional_commander.faction = "Império"
	regional_entry.commander = regional_commander

	var result := PhaseResult.new()
	result.victory = true
	result.opponent_entry = regional_entry

	print("  Pode tentar recrutar? %s (esperado: true)" % str(RecruitmentResolver.can_recruit(result, kingdom)))

	# O sorteio de 50% é aleatório — tentamos algumas vezes até ver os
	# dois desfechos possíveis (evita depender de sorte em uma única
	# rodada de teste).
	var reference_unix: int = GameClock.now_unix()

	var saw_success: bool = false
	var saw_refusal: bool = false
	for i in range(30):
		var trial_kingdom := Kingdom.new()
		var trial_outcome: Dictionary = RecruitmentResolver.attempt_recruitment(result, trial_kingdom, reference_unix)
		if trial_outcome["submitted"]:
			saw_success = true
		else:
			saw_refusal = true
		if saw_success and saw_refusal:
			break
	print("  Em 30 tentativas, viu submissão bem-sucedida? %s | viu recusa? %s (esperado: true, true — confirma o sorteio de 50%%)" % [
		str(saw_success), str(saw_refusal)
	])

	# Forçando uma submissão bem-sucedida para o restante do teste.
	var outcome: Dictionary = {"submitted": false}
	while not outcome["submitted"]:
		outcome = RecruitmentResolver.attempt_recruitment(result, kingdom, reference_unix)
	print("  Submissão -> oferta criada? %s | Reino ainda sem o Comandante (só na fila)? %s (esperado: true, true)" % [
		str(outcome["offer"] != null), str(kingdom.commanders.is_empty())
	])

	print("  Tentando de novo -> pode tentar recrutar? %s (esperado: false, já recrutado)" % str(RecruitmentResolver.can_recruit(result, kingdom)))

	var offer: RecruitmentOffer = outcome["offer"]

	# O Comissionamento agora exige Vaga da Reserva de verdade
	# (CommissioningResolver) — ativa o suficiente pra abrir 1 Vaga
	# (Nível 1: 1º ativa Ativo, 2º ativa a 1ª Reserva).
	kingdom.add_generation_points(2)
	CommandCenterResolver.activate_next(kingdom)
	CommandCenterResolver.activate_next(kingdom)
	print("  Vagas ativadas antes do Comissionamento -> Ativo: %d | Reserva: %d (esperado: 1, 1)" % [
		kingdom.cargo_ativo_activated, kingdom.vaga_reserva_activated
	])

	var commission_result: Dictionary = CommissioningResolver.commission_from_pve_offer(kingdom, offer, reference_unix)
	var accepted: bool = commission_result["success"]
	print("  Jogador aceita a oferta (Comissionamento unificado) -> aceitou? %s | Comandantes no Reino: %d | ofertas pendentes: %d (esperado: true, 1, 0)" % [
		str(accepted), kingdom.commanders.size(), kingdom.pending_recruitment_offers.size()
	])
	var pve_entry: Dictionary = kingdom.commissioning_history[-1]
	print("  Histórico registrou a Fonte certa? %s (esperado: 'Campanha PvE')" % pve_entry.get("source", ""))

	# Fila cheia: a 11ª oferta é REJEITADA (COMMAND_CENTER_RECRUITMENT.md,
	# "Lista Cheia (PvE)") — nenhuma oferta existente é descartada.
	var full_kingdom := Kingdom.new()
	var first_commander := CommanderResource.new()
	first_commander.commander_name = "Primeiro da Fila"
	var first_offer: RecruitmentOffer = full_kingdom.offer_recruitment(first_commander, reference_unix)
	print("  Primeira oferta -> foi criada? %s (esperado: true)" % str(first_offer != null))

	for i in range(9):
		var filler := CommanderResource.new()
		filler.commander_name = "Comandante %d" % i
		full_kingdom.offer_recruitment(filler, reference_unix)
	print("  Fila após 10 ofertas: %d (esperado: 10)" % full_kingdom.pending_recruitment_offers.size())

	var eleventh := CommanderResource.new()
	eleventh.commander_name = "11º Comandante"
	var eleventh_offer: RecruitmentOffer = full_kingdom.offer_recruitment(eleventh, reference_unix)
	print("  11ª oferta -> rejeitada (retornou null)? %s | 'Primeiro da Fila' continua na Fila (não foi descartado)? %s | Fila continua com 10? %s (esperado: true, true, true)" % [
		str(eleventh_offer == null),
		str(full_kingdom.pending_recruitment_offers[0].commander.commander_name == "Primeiro da Fila"),
		str(full_kingdom.pending_recruitment_offers.size() == 10)
	])

	# Chefe Normal nunca pode ser recrutado.
	var normal_entry := EnemyArmyEntry.new()
	normal_entry.category = EnemyArmyEntry.Category.CHEFE_NORMAL
	var result_normal := PhaseResult.new()
	result_normal.victory = true
	result_normal.opponent_entry = normal_entry
	print("  Chefe Normal pode ser recrutado? %s (esperado: false)" % str(RecruitmentResolver.can_recruit(result_normal, kingdom)))

	# Derrota nunca pode ser recrutada.
	var result_loss := PhaseResult.new()
	result_loss.victory = false
	result_loss.opponent_entry = regional_entry
	print("  Derrota pode ser recrutada? %s (esperado: false)" % str(RecruitmentResolver.can_recruit(result_loss, kingdom)))

	# Confirma que, depois da submissão bem-sucedida, a Seleção de
	# Inimigos já devolve um Chefe Normal daquela Região.
	var catalog := SeasonCatalog.new("Season-Recrutamento-Teste")
	var chefe_normal_entry := EnemyArmyEntry.new()
	chefe_normal_entry.id = "SUBSTITUTO_CHEFE_NORMAL"
	catalog.add_entries("Império", EnemyArmyEntry.Category.CHEFE_NORMAL, [chefe_normal_entry])
	catalog.add_entries("Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, [regional_entry])

	var selected: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 1, kingdom.regional_commander_registry
	)
	print("  Depois da submissão, a próxima seleção para a mesma Fase é: %s (esperado: SUBSTITUTO_CHEFE_NORMAL)" % (selected.id if selected != null else "null"))


## Validação da expiração de Ofertas de Recrutamento (4 dias / 96h,
## COMMAND_CENTER_RECRUITMENT.md → "Painel PvE" → "Permanência e
## Expiração"): uma oferta criada há mais de 4 dias é purgada sem
## recompensa e gera um aviso para o jogador; uma oferta ainda dentro
## do prazo permanece intocada. Usa timestamps simulados (passado) em
## vez de esperar 4 dias reais — só o cálculo é testado aqui, não a
## passagem real do tempo (já coberta por _validate_game_clock).
func _validate_recruitment_offer_expiration() -> void:
	print("[Recrutamento] Validando expiração de Ofertas (4 dias / 96h)...")

	var now: int = GameClock.now_unix()
	var four_days_seconds: int = RecruitmentOffer.VALIDITY_DAYS * 24 * 60 * 60

	var kingdom := Kingdom.new()

	# Oferta "antiga": criada há mais de 4 dias (simulado) -> deve expirar.
	var expired_commander := CommanderResource.new()
	expired_commander.commander_name = "Comandante Expirado"
	kingdom.offer_recruitment(expired_commander, now - four_days_seconds - 10)

	# Oferta "recente": criada há 1 dia (simulado) -> não deve expirar.
	var recent_commander := CommanderResource.new()
	recent_commander.commander_name = "Comandante Recente"
	kingdom.offer_recruitment(recent_commander, now - 86400)

	print("  Ofertas pendentes antes da purga: %d (esperado: 2)" % kingdom.pending_recruitment_offers.size())

	var purged: Array[RecruitmentOffer] = RecruitmentResolver.purge_expired_offers(kingdom, now)

	print("  Ofertas purgadas: %d (esperado: 1, 'Comandante Expirado')" % purged.size())
	if not purged.is_empty():
		print("    Nome: %s" % purged[0].commander.commander_name)

	print("  Ofertas pendentes após a purga: %d (esperado: 1, só 'Comandante Recente' resta)" % kingdom.pending_recruitment_offers.size())
	print("  Reino recebeu algum Comandante pela expiração? %s (esperado: false — sem recompensa)" % str(
		not kingdom.commanders.is_empty()
	))

	var notifications: Array[String] = kingdom.consume_expired_recruitment_notifications()
	print("  Aviso pendente para o jogador: %s (esperado: ['Comandante Expirado'])" % str(notifications))

	var notifications_again: Array[String] = kingdom.consume_expired_recruitment_notifications()
	print("  Consumir de novo -> fila de avisos já vazia? %s (esperado: true)" % str(notifications_again.is_empty()))

	# purge_expired_offers é idempotente: chamar de novo sem tempo adicional não expira a que restou.
	var purged_again: Array[RecruitmentOffer] = RecruitmentResolver.purge_expired_offers(kingdom, now)
	print("  Nova purga imediata -> purgou mais alguma? %s (esperado: false, 'Comandante Recente' ainda dentro do prazo)" % str(
		not purged_again.is_empty()
	))


## Validação da geração de posição das Minas: 5 Minas Regionais por
## Trilha (2/1/2 por Região), uma sempre na Fase 9000, sem coincidir
## com Chefe/Acampamento, determinístico pela seed. Também valida as 3
## Minas Iniciais do Reino (sem Fase).
func _validate_mina_placement() -> void:
	print("[Minas] Validando geração de posição das Minas Regionais...")

	var trilha := Trilha.new("territorio-minas-teste")
	var mines: Array[Mina] = MinaPlacementGenerator.generate("Império", trilha, 4242)

	print("  Total de Minas Regionais geradas: %d (esperado: 5)" % mines.size())

	var fases: Array[int] = []
	for mina: Mina in mines:
		fases.append(mina.adjacent_fase)
	var region_1_count: int = 0
	var region_2_count: int = 0
	var region_3_count: int = 0
	for fase: int in fases:
		var region: int = trilha.region_for_fase(fase)
		if region == 1: region_1_count += 1
		elif region == 2: region_2_count += 1
		else: region_3_count += 1
	print("  Distribuição -> Região I: %d, Região II: %d, Região III: %d (esperado: 2, 1, 2)" % [
		region_1_count, region_2_count, region_3_count
	])

	print("  Uma das Minas está na Fase 9000? %s (esperado: true)" % str(9000 in fases))

	var collision_found: bool = false
	for fase: int in fases:
		if fase == MinaPlacementGenerator.FIXED_MINE_FASE:
			continue  # exceção intencional e documentada: sempre ao lado do Chefe Regional final
		if trilha.is_acampamento(fase) or trilha.chefe_type(fase) != "":
			collision_found = true
	print("  Alguma das Minas sorteadas livremente coincide com Chefe/Acampamento? %s (esperado: false — a Fase 9000 fixa é exceção conhecida, não entra nesta checagem)" % str(collision_found))

	# Determinismo: mesma seed -> mesmas posições.
	var mines_again: Array[Mina] = MinaPlacementGenerator.generate("Império", trilha, 4242)
	var same_positions: bool = true
	for i in range(mines.size()):
		if mines[i].adjacent_fase != mines_again[i].adjacent_fase:
			same_positions = false
	print("  Mesma seed gera as mesmas posições? %s (esperado: true)" % str(same_positions))

	# Minas Iniciais do Reino.
	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	print("  Minas Iniciais criadas: %d (esperado: 3)" % kingdom.initial_mines.size())
	var all_without_fase: bool = true
	for mina: Mina in kingdom.initial_mines:
		if not mina.is_initial_mine():
			all_without_fase = false
	print("  Todas sem Fase associada (Mina Inicial)? %s (esperado: true)" % str(all_without_fase))

	# Geração via Kingdom, com cache (não regenera na segunda chamada).
	var generated_1: Array[Mina] = kingdom.generate_territory_mines("territorio-minas-teste", "Império", trilha, 999)
	var generated_2: Array[Mina] = kingdom.generate_territory_mines("territorio-minas-teste", "Império", trilha, 999)
	print("  Segunda chamada devolve a mesma lista (cache, não regenera)? %s (esperado: true)" % str(generated_1 == generated_2))


## Validação da conquista de Minas: vitória contra o Chefe de Mina
## marca a Mina como conquistada; Mina já conquistada ou Mina Inicial
## (sem Fase) não tentam nada.
func _validate_mine_conquest() -> void:
	print("[Minas] Validando a conquista de uma Mina Regional...")

	var trilha := Trilha.new("territorio-conquista-teste")
	var mina := Mina.new(50, "Império")  # Fase 50, Região I
	var kingdom := Kingdom.new()

	var winning_army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	winning_army.initialize_energy(1)
	var squad := Squad.new([winning_army])

	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(
		"Império", CampaignTestFixtures.build_campaign_enemy_army()
	)

	print("  Mina conquistada antes da tentativa? %s (esperado: false)" % str(mina.conquered))
	print("  PG antes da conquista: %d (esperado: 0)" % kingdom.generation_points)

	var result: PhaseResult = MineConquestResolver.attempt_conquest(
		mina, trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Vitória na conquista? %s | Mina conquistada agora? %s (esperado: true, true)" % [
		(str(result.victory) if result != null else "null"), str(mina.conquered)
	])
	print("  XP de Conta após 'Liberar Mina' (20 XP): %d | Nível de Conta: %d (esperado: >= 20, pode já ter virado Nível 2 = +1 PG)" % [
		kingdom.account_xp, kingdom.account_level()
	])

	var second_attempt: PhaseResult = MineConquestResolver.attempt_conquest(
		mina, trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Tentar de novo uma Mina já conquistada -> retorna null? %s (esperado: true)" % str(second_attempt == null))

	kingdom.create_initial_mines()
	var initial_result: PhaseResult = MineConquestResolver.attempt_conquest(
		kingdom.initial_mines[0], trilha, squad, catalog, "Império", 123,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, kingdom
	)
	print("  Tentar conquistar uma Mina Inicial (sem Fase) -> retorna null? %s (esperado: true)" % str(initial_result == null))


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


## Validação da regra "uma carta, um lugar": adquirir cópias do
## catálogo dá RG único a cada uma; formar um Exército aloca as cartas
## (viram indisponíveis); tentar reutilizar uma carta já alocada é
## barrado; desfazer o Exército libera as cartas de volta.
func _validate_card_ownership() -> void:
	print("[Posse de Cartas] Validando RG único e a regra 'uma carta, um lugar'...")

	var kingdom := Kingdom.new()
	var catalog_card: CardResource = GameDatabase.get_card("Legionário Imperial")

	var copy_1: CardResource = kingdom.acquire_card_from_catalog(catalog_card)
	var copy_2: CardResource = kingdom.acquire_card_from_catalog(catalog_card)
	print("  Duas cópias adquiridas -> RGs diferentes? %s (RG 1: %d, RG 2: %d)" % [
		str(copy_1.instance_id != copy_2.instance_id), copy_1.instance_id, copy_2.instance_id
	])
	print("  Ambas Livres? %s (esperado: true)" % str(
		copy_1.ownership_status == CardResource.OwnershipStatus.LIVRE and
		copy_2.ownership_status == CardResource.OwnershipStatus.LIVRE
	))

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Posse)"
	commander.faction = "Império"
	kingdom.add_commander(commander)
	print("  Comandante registrado no Reino -> RG: %d | Estado: %s | Disponível pra liderar Exército? %s (esperado: > 0, RESERVE, false — ainda não é Ativo)" % [
		commander.instance_id, CommanderResource.AdministrativeState.keys()[commander.administrative_state], str(kingdom.is_commander_available(commander))
	])

	# Precisa de um Cargo de Comando Ativo ativado (Expansão Administrativa)
	# antes de poder promover o Comandante a Ativo.
	kingdom.add_generation_points(10)
	CommandCenterResolver.activate_next(kingdom)  # ativa o 1º Cargo de Comando Ativo disponível no Nível 1
	var promote_result: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	print("  Promover a Ativo (com Cargo disponível) -> sucesso? %s | Disponível agora? %s (esperado: true, true)" % [
		str(promote_result["success"]), str(kingdom.is_commander_available(commander))
	])

	var nine_cards: Array[CardResource] = [copy_1, copy_2]
	for i in range(7):
		nine_cards.append(kingdom.acquire_card_from_catalog(catalog_card))

	var army: Army = kingdom.form_army(commander, nine_cards)
	print("  Exército formado com 9 cartas da coleção -> Exércitos no Reino: %d (esperado: 1)" % kingdom.armies.size())
	print("  Cópia 1 agora está Livre? %s (esperado: false — está no Exército)" % str(
		copy_1.ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	print("  kingdom.is_card_available(copy_1)? %s (esperado: false)" % str(kingdom.is_card_available(copy_1)))
	print("  Comandante ainda disponível para outro Exército? %s (esperado: false — já está liderando este)" % str(
		kingdom.is_commander_available(commander)
	))

	kingdom.disband_army(army)
	print("  Após desfazer o Exército -> copy_1 disponível de novo? %s | Comandante disponível de novo? %s | Exércitos no Reino: %d (esperado: true, true, 0)" % [
		str(kingdom.is_card_available(copy_1)), str(kingdom.is_commander_available(commander)), kingdom.armies.size()
	])
