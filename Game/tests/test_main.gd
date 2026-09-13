extends Node
## TestMain (F-001, Etapa 0/1) — ponto de entrada headless da nova
## suíte de testes nativa.
##
## Uso:
##   godot --headless --path Game res://tests/test_main.tscn
##   godot --headless --path Game res://tests/test_main.tscn -- --suite=soldo
##   godot --headless --path Game res://tests/test_main.tscn -- --test=validate_soldo
##
## Produz exit code 0 se todas as asserções passaram e nenhum teste
## selecionado teve erro de execução; 1 caso contrário (assert falhou,
## erro de execução, ou nenhum teste correspondeu ao filtro). Mesmo
## mecanismo de filtro por linha de comando (OS.get_cmdline_user_args())
## já validado no F-003 (--mining-estimation).
##
## Escopo desta etapa: suítes "soldo" (Etapa 1); "affinity", "army" e
## "energy_nucleus" (Etapa 2); "energy_army", "squad", "formations",
## "ability_data" e "card_catalog_integrity" (Etapa 3); "trilha",
## "command_center_training_slots", "card_progression", "kingdom" e
## "expedition_runtime" (Etapa 4/5); "recipe_production_delivers_card",
## "account_xp", "recruitment_offer_expiration", "card_ownership" e
## "energy_time_recovery" (Etapa 7); "movement_rules",
## "unit_trait_runtimes", "investida" e "effect_runtime" (Etapa 8);
## "ranking_and_battlefield_selector", "first_candidate_available_immediately",
## "fragments_credited_per_unit_faction", "game_runtime_sync" e
## "initial_mine_no_conquest" (Etapa 10); "city_deposits",
## "institutional_constructions", "command_center_state_machine",
## "commander_training_xp" e "recruitment_center" (Etapa 12);
## "initial_mine_never_expires", "sequential_commissioning_order",
## "active_reserve_swap", "swap_active_reserve" e
## "energy_recovers_over_real_time" (Etapa 13); "army_edit_lock",
## "academy_queue_upgrade", "energy_recalculates_on_composition_change",
## "campaign_synergy" e "reward_resolver" (Etapa 14); "academy_advanced_options",
## "legacy", "energy_composition_penalty", "commander_battle_history" e
## "army_formation_archetypes" (Etapa 15) estão registradas — as demais
## validações de bootstrap.gd permanecem lá, ainda não migradas.
## "commander_battle_history" e "army_formation_archetypes" são migrações
## PARCIAIS (Etapa 15): a Parte 3 (tela) de
## _validate_commander_battle_history() e a segunda metade
## (Kingdom.form_army() via KingdomState.kingdom) de
## _validate_army_formation_archetypes() permanecem em bootstrap.gd,
## deliberadamente não migradas por dependerem de KingdomState.kingdom
## e/ou instanciação de cena. "phase_retry", "academy",
## "acampamento_policies", "recruitment" e "season_pipeline" (Etapa 16)
## estão registradas — migrações completas, nenhuma parcial.
## _validate_advanced_abilities() permanece deliberadamente pendente
## (Etapa 8): SilencioRuntime usa CombatState.rng.randi() para seleção de
## alvo, produzindo resultado de batalha não determinístico — nenhuma
## decisão de seed/redesign foi tomada. _validate_kingdom_state_creates_initial_mines()
## foi identificada como duplicata comportamental exata de
## _validate_initial_mine_no_conquest() (Etapa 10) e removida — apenas a
## segunda foi migrada, como canônica (ver test_initial_mine_no_conquest.gd).

func _ready() -> void:
	# Mesma inicialização que bootstrap.gd sempre fez incondicionalmente
	# antes de qualquer validação (Sprint 1) — necessária porque alguns
	# fluxos de engine (ex.: ExpeditionRuntime.attempt_current_fase(),
	# que concede recompensas via KingdomState.kingdom internamente,
	# apesar de nenhum parâmetro de Kingdom em sua própria assinatura)
	# leem o Autoload global diretamente, não apenas os testes que o
	# referenciam pelo nome. Sem isso, KingdomState.kingdom fica null e
	# esses fluxos falham silenciosamente (SCRIPT ERROR recuperado pelo
	# GDScript, não propagado, mas divergente do comportamento original).
	# F-013: KingdomState.initialize_new_kingdom() agora carrega um save
	# real de user://kingdom_save.json se existir. Sem esta limpeza, um
	# save deixado por uma execução anterior (deste runner ou de
	# bootstrap.tscn) faria KingdomState.kingdom começar como um Reino
	# antigo em vez do Reino novo e vazio que toda a suíte pressupõe.
	KingdomSaveService.delete_save()
	KingdomState.initialize_new_kingdom()

	var runner := TestRunner.new()
	runner.register("soldo", "validate_soldo", TestSoldo.run)
	runner.register("affinity", "validate_affinity", TestAffinity.run)
	runner.register("army", "validate_army", TestArmy.run)
	runner.register("energy_nucleus", "validate_energy_nucleus", TestEnergyNucleus.run)
	runner.register("energy_army", "validate_energy_army", TestEnergyArmy.run)
	runner.register("squad", "validate_squad", TestSquad.run)
	runner.register("formations", "validate_formations", TestFormations.run)
	runner.register("ability_data", "validate_ability_data", TestAbilityData.run)
	runner.register("card_catalog_integrity", "validate_card_catalog_integrity", TestCardCatalogIntegrity.run)
	runner.register("trilha", "validate_trilha", TestTrilha.run)
	runner.register("command_center_training_slots", "validate_command_center_training_slots", TestCommandCenterTrainingSlots.run)
	runner.register("card_progression", "validate_card_progression", TestCardProgression.run)
	runner.register("kingdom", "validate_kingdom", TestKingdom.run)
	runner.register("expedition_runtime", "validate_expedition_runtime", TestExpeditionRuntime.run)
	runner.register("recipe_production_delivers_card", "validate_recipe_production_delivers_card", TestRecipeProductionDeliversCard.run)
	runner.register("account_xp", "validate_account_xp", TestAccountXp.run)
	runner.register("recruitment_offer_expiration", "validate_recruitment_offer_expiration", TestRecruitmentOfferExpiration.run)
	runner.register("card_ownership", "validate_card_ownership", TestCardOwnership.run)
	runner.register("energy_time_recovery", "validate_energy_time_recovery", TestEnergyTimeRecovery.run)
	runner.register("movement_rules", "validate_movement_rules", TestMovementRules.run)
	runner.register("movement_sequence_compaction", "validate_movement_sequence_compaction", TestMovementSequenceCompaction.run)
	runner.register("support_chain_advance_order", "validate_support_chain_advance_order", TestSupportChainAdvanceOrder.run)
	runner.register("campo_de_prova_army_sources", "validate_campo_de_prova_army_sources", TestCampoDeProvaArmySources.run)
	runner.register("campo_de_prova_lifecycle_and_editing", "validate_campo_de_prova_lifecycle_and_editing", TestCampoDeProvaLifecycleAndEditing.run)
	runner.register("unit_trait_runtimes", "validate_unit_trait_runtimes", TestUnitTraitRuntimes.run)
	runner.register("investida", "validate_investida", TestInvestida.run)
	runner.register("effect_runtime", "validate_effect_runtime", TestEffectRuntime.run)
	runner.register("ranking_and_battlefield_selector", "validate_ranking_and_battlefield_selector", TestRankingAndBattlefieldSelector.run)
	runner.register("first_candidate_available_immediately", "validate_first_candidate_available_immediately", TestFirstCandidateAvailableImmediately.run)
	runner.register("fragments_credited_per_unit_faction", "validate_fragments_credited_per_unit_faction", TestFragmentsCreditedPerUnitFaction.run)
	runner.register("game_runtime_sync", "validate_game_runtime_sync", TestGameRuntimeSync.run)
	runner.register("initial_mine_no_conquest", "validate_initial_mine_no_conquest", TestInitialMineNoConquest.run)
	runner.register("city_deposits", "validate_city_deposits", TestCityDeposits.run)
	runner.register("institutional_constructions", "validate_institutional_constructions", TestInstitutionalConstructions.run)
	runner.register("institutional_construction_entry_curve", "validate_institutional_construction_entry_curve", TestInstitutionalConstructionEntryCurve.run)
	runner.register("command_center_state_machine", "validate_command_center_state_machine", TestCommandCenterStateMachine.run)
	runner.register("commander_training_xp", "validate_commander_training_xp", TestCommanderTrainingXp.run)
	runner.register("recruitment_center", "validate_recruitment_center", TestRecruitmentCenter.run)
	runner.register("initial_mine_never_expires", "validate_initial_mine_never_expires", TestInitialMineNeverExpires.run)
	runner.register("sequential_commissioning_order", "validate_sequential_commissioning_order", TestSequentialCommissioningOrder.run)
	runner.register("active_reserve_swap", "validate_active_reserve_swap", TestActiveReserveSwap.run)
	runner.register("swap_active_reserve", "validate_swap_active_reserve", TestSwapActiveReserve.run)
	runner.register("energy_recovers_over_real_time", "validate_energy_recovers_over_real_time", TestEnergyRecoversOverRealTime.run)
	runner.register("army_edit_lock", "validate_army_edit_lock", TestArmyEditLock.run)
	runner.register("academy_queue_upgrade", "validate_academy_queue_upgrade", TestAcademyQueueUpgrade.run)
	runner.register("energy_recalculates_on_composition_change", "validate_energy_recalculates_on_composition_change", TestEnergyRecalculatesOnCompositionChange.run)
	runner.register("campaign_synergy", "validate_campaign_synergy", TestCampaignSynergy.run)
	runner.register("reward_resolver", "validate_reward_resolver", TestRewardResolver.run)
	runner.register("academy_advanced_options", "validate_academy_advanced_options", TestAcademyAdvancedOptions.run)
	runner.register("legacy", "validate_legacy", TestLegacy.run)
	runner.register("energy_composition_penalty", "validate_energy_composition_penalty", TestEnergyCompositionPenalty.run)
	runner.register("commander_battle_history", "validate_commander_battle_history", TestCommanderBattleHistory.run)
	runner.register("army_formation_archetypes", "validate_army_formation_archetypes", TestArmyFormationArchetypes.run)
	runner.register("phase_retry", "validate_phase_retry", TestPhaseRetry.run)
	runner.register("academy", "validate_academy", TestAcademy.run)
	runner.register("acampamento_policies", "validate_acampamento_policies", TestAcampamentoPolicies.run)
	runner.register("recruitment", "validate_recruitment", TestRecruitment.run)
	runner.register("season_pipeline", "validate_season_pipeline", TestSeasonPipeline.run)
	runner.register("mine_prerequisites", "validate_mine_prerequisites", TestMinePrerequisites.run)
	runner.register("mine_guarnicao_and_production", "validate_mine_guarnicao_and_production", TestMineGuarnicaoAndProduction.run)
	runner.register("mina_placement", "validate_mina_placement", TestMinaPlacement.run)
	runner.register("mine_conquest", "validate_mine_conquest", TestMineConquest.run)
	runner.register("mine_reference_formation", "validate_mine_reference_formation", TestMineReferenceFormation.run)
	runner.register("enemy_composition_has_no_duplicate_names", "validate_enemy_composition_has_no_duplicate_names", TestEnemyCompositionHasNoDuplicateNames.run)
	runner.register("edit_army_composition", "validate_edit_army_composition", TestEditArmyComposition.run)
	runner.register("expedition_session_waits_for_player", "validate_expedition_session_waits_for_player", TestExpeditionSessionWaitsForPlayer.run)
	runner.register("commander_doctrine", "validate_commander_doctrine", TestCommanderDoctrine.run)
	runner.register("enemy_entry_serialization", "validate_enemy_entry_serialization", TestEnemyEntrySerialization.run)
	runner.register("starter_kit_faction_composition", "validate_starter_kit_faction_composition", TestStarterKitFactionComposition.run)
	runner.register("world_bootstrap_catalog_validity", "validate_world_bootstrap_catalog_validity", TestWorldBootstrapCatalogValidity.run)
	runner.register("kingdom_save_load_ranking_and_planos", "validate_kingdom_save_load_ranking_and_planos", TestKingdomSaveLoadRankingAndPlanos.run)
	runner.register("kingdom_state_load_lifecycle", "validate_kingdom_state_load_lifecycle", TestKingdomStateLoadLifecycle.run)
	runner.register("battle_determinism", "validate_battle_determinism", TestBattleDeterminism.run)
	runner.register("simulation_runner", "validate_simulation_runner", TestSimulationRunner.run)
	runner.register("starter_kit_army_integration", "validate_starter_kit_army_integration", TestStarterKitArmyIntegration.run)
	runner.register("heal_target_selection", "validate_heal_target_selection", TestHealTargetSelection.run)
	runner.register("affinity_combat", "validate_affinity_combat", TestAffinityCombat.run)
	runner.register("army_editor_formation_flow", "validate_army_editor_formation_flow", preload("res://tests/unit/test_army_editor_formation_flow.gd").run)
	runner.register("army_editor_reopen_existing_composition", "validate_army_editor_reopen_existing_composition", preload("res://tests/unit/test_army_editor_reopen_existing_composition.gd").run)
	runner.register("kingdom_persistence_roundtrip", "validate_kingdom_persistence_roundtrip", preload("res://tests/unit/test_kingdom_persistence_roundtrip.gd").run)
	runner.register("combat_replay_view", "validate_combat_replay_view", preload("res://tests/unit/test_combat_replay_view.gd").run)
	runner.register("replay_visual_identity", "validate_replay_visual_identity", preload("res://tests/unit/test_replay_visual_identity.gd").run)
	runner.register("battle_unit_art_pilot", "validate_battle_unit_art_pilot", preload("res://tests/unit/test_battle_unit_art_pilot.gd").run)
	runner.register("art_catalogs", "validate_art_catalogs", preload("res://tests/unit/test_art_catalogs.gd").run)
	runner.register("tutorial_flow", "validate_tutorial_flow", preload("res://tests/unit/test_tutorial_flow.gd").run)
	runner.register("academia_producao_panel_lifecycle", "validate_academia_producao_panel_lifecycle", preload("res://tests/unit/test_academia_producao_panel_lifecycle.gd").run)
	runner.register("combat_replay_animations", "validate_combat_replay_animations", preload("res://tests/unit/test_combat_replay_animations.gd").run)
	runner.register("support_overtake", "validate_support_overtake", preload("res://tests/unit/test_support_overtake.gd").run)
	runner.register("battle_hover_preview", "validate_battle_hover_preview", preload("res://tests/unit/test_battle_hover_preview.gd").run)
	runner.register("battlefield_hover", "validate_battlefield_hover", preload("res://tests/unit/test_battlefield_hover.gd").run)
	runner.register("city_hotspot_glow", "validate_city_hotspot_glow", preload("res://tests/unit/test_city_hotspot_glow.gd").run)
	runner.register("minas_panel_ui", "validate_minas_panel_ui", preload("res://tests/unit/test_minas_panel_ui.gd").run)
	runner.register("phase_resolver_defeat_reason", "validate_phase_resolver_defeat_reason", preload("res://tests/unit/test_phase_resolver_defeat_reason.gd").run)
	runner.register("expedition_runtime_camp_without_combat", "validate_expedition_runtime_camp_without_combat", preload("res://tests/unit/test_expedition_runtime_camp_without_combat.gd").run)
	runner.register("expedition_tick_resolver", "validate_expedition_tick_resolver", preload("res://tests/unit/test_expedition_tick_resolver.gd").run)
	runner.register("kingdom_persistence_expedition_roundtrip", "validate_kingdom_persistence_expedition_roundtrip", preload("res://tests/unit/test_kingdom_persistence_expedition_roundtrip.gd").run)
	runner.register("mine_evolution_resolver", "validate_mine_evolution_resolver", preload("res://tests/unit/test_mine_evolution_resolver.gd").run)
	runner.register("kingdom_generate_territory_mines_via_expedition_start", "validate_kingdom_generate_territory_mines_via_expedition_start", preload("res://tests/unit/test_kingdom_generate_territory_mines_via_expedition_start.gd").run)
	runner.register("trilha_path_layout", "validate_trilha_path_layout", preload("res://tests/unit/test_trilha_path_layout.gd").run)
	runner.register("fase_history_formation_data", "validate_fase_history_formation_data", preload("res://tests/unit/test_fase_history_formation_data.gd").run)
	runner.register("pve_panel_segment_navigation", "validate_pve_panel_segment_navigation", preload("res://tests/unit/test_pve_panel_segment_navigation.gd").run)
	runner.register("pve_panel_energy_header", "validate_pve_panel_energy_header", preload("res://tests/unit/test_pve_panel_energy_header.gd").run)
	runner.register("tutorial_contextual_hints", "validate_tutorial_contextual_hints", preload("res://tests/unit/test_tutorial_contextual_hints.gd").run)
	runner.register("pvp_battle", "validate_pvp_battle", preload("res://tests/unit/test_pvp_battle.gd").run)
	runner.register("expedition_persistence_restoration_warning", "validate_expedition_persistence_restoration_warning", preload("res://tests/unit/test_expedition_persistence_restoration_warning.gd").run)
	runner.register("army_editor_ux_audit_findings", "validate_army_editor_ux_audit_findings", preload("res://tests/unit/test_army_editor_ux_audit_findings.gd").run)
	runner.register("campo_de_prova_relatorio_baixas", "validate_campo_de_prova_relatorio_baixas", preload("res://tests/unit/test_campo_de_prova_relatorio_baixas.gd").run)
	runner.register("city_panel_economy_hints", "validate_city_panel_economy_hints", preload("res://tests/unit/test_city_panel_economy_hints.gd").run)
	runner.register("bestiario_energy_soldo", "validate_bestiario_energy_soldo", preload("res://tests/unit/test_bestiario_energy_soldo.gd").run)
	runner.register("command_center_glow_evolution_tutorial", "validate_command_center_glow_evolution_tutorial", preload("res://tests/unit/test_command_center_glow_evolution_tutorial.gd").run)
	runner.register("academia_fila_card_name_rendering", "validate_academia_fila_card_name_rendering", preload("res://tests/unit/test_academia_fila_card_name_rendering.gd").run)

	var suite_filter: String = _arg_value("--suite=")
	var test_filter: String = _arg_value("--test=")

	var ok: bool = runner.run(suite_filter, test_filter)
	get_tree().quit(0 if ok else 1)


func _arg_value(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())
	return ""
