class_name TestPvePanelSegmentNavigation
extends RefCounted
## TestPvePanelSegmentNavigation (F-021, itens G/17 da auditoria)
##
## Paginação em segmentos fixos, sem duplicar nós, sem exceder o
## limite de virtualização, e centralização real na Fase atual.
## Mesmo padrão de instanciação fora da SceneTree já usado por
## test_minas_panel_ui.gd (_build_static_structure()/refresh() direto,
## nunca _ready()).

const PvEPanelScript = preload("res://scenes/command_center/panels/pve_panel.gd")


static func _build_expedition(seed_value: int) -> ExpeditionRuntime:
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(5)
	var squad := Squad.new([army])
	var territory := Territory.new("Territorio-Teste-Segmento-%d" % seed_value, "Natureza")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()
	return ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, seed_value,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021] Validando paginação por segmentos e virtualização do mapa...")

	var kingdom := Kingdom.new()
	var expedition: ExpeditionRuntime = _build_expedition(960)
	kingdom.active_expeditions.append(expedition)
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var panel = PvEPanelScript.new()
	panel._build_static_structure()
	panel._on_view_expedition_pressed(expedition)

	var node_count: int = panel._map_nodes_container.get_child_count()
	print("  1ª página: nós construídos > 0 e <= 3x SEGMENT_SIZE (%d)? %s (%d)" % [
		PvEPanelScript.SEGMENT_SIZE, str(node_count > 0 and node_count <= PvEPanelScript.SEGMENT_SIZE * 3), node_count
	])
	ctx.check(node_count > 0, "A 1ª página deve construir ao menos 1 nó")
	ctx.check(node_count <= PvEPanelScript.SEGMENT_SIZE * 3, "O mapa nunca deve instanciar muito mais nós que SEGMENT_SIZE por página — virtualização preservada (obtido: %d)" % node_count)

	var segment_before: int = panel._map_segment_start_fase
	panel._on_segment_next_pressed()
	print("  'Avançar' move exatamente SEGMENT_SIZE (%d -> %d, esperado %d)? %s" % [
		segment_before, panel._map_segment_start_fase, segment_before + PvEPanelScript.SEGMENT_SIZE, str(panel._map_segment_start_fase == segment_before + PvEPanelScript.SEGMENT_SIZE)
	])
	ctx.check(panel._map_segment_start_fase == segment_before + PvEPanelScript.SEGMENT_SIZE, "Avançar deve mover exatamente SEGMENT_SIZE Fases (obtido: %d)" % panel._map_segment_start_fase)

	panel._on_segment_prev_pressed()
	ctx.check(panel._map_segment_start_fase == segment_before, "Voltar deve retornar exatamente ao segmento anterior (obtido: %d)" % panel._map_segment_start_fase)

	panel._on_segment_prev_pressed()
	print("  'Voltar' na 1ª página nunca deixa o segmento ir abaixo da Fase 1? %s (obtido: %d)" % [str(panel._map_segment_start_fase == 1), panel._map_segment_start_fase])
	ctx.check(panel._map_segment_start_fase == 1, "O segmento nunca pode começar antes da Fase 1")

	for i in range(30):
		expedition.attempt_current_fase()
	panel._on_center_map_pressed()
	var contains_current: bool = panel._map_segment_start_fase <= expedition.current_fase and expedition.current_fase < panel._map_segment_start_fase + PvEPanelScript.SEGMENT_SIZE
	print("  'Centralizar' após avançar (Fase %d) -> segmento (%d) contém a Fase atual? %s" % [
		expedition.current_fase, panel._map_segment_start_fase, str(contains_current)
	])
	ctx.check(contains_current, "'Centralizar na Fase Atual' deve sempre mostrar um segmento que contém current_fase")

	var count_a: int = panel._map_nodes_container.get_child_count()
	panel.refresh()
	var count_b: int = panel._map_nodes_container.get_child_count()
	print("  Reconstruir a mesma página (refresh 2x) não duplica nós? %s (%d -> %d)" % [str(count_a == count_b), count_a, count_b])
	ctx.check(count_a == count_b, "Chamar refresh() repetidamente na mesma página nunca deve duplicar nós")

	# Estado de nó: current/passed/blocked distintos por Dictionary real.
	var state_current: Dictionary = panel._node_state_for_fase(expedition, expedition.current_fase)
	var state_passed: Dictionary = panel._node_state_for_fase(expedition, 1)
	var state_blocked: Dictionary = panel._node_state_for_fase(expedition, expedition.current_fase + 100)
	ctx.check(state_current["is_current"] and not state_current["is_passed"], "A Fase atual deve ser is_current=true, is_passed=false")
	ctx.check(state_passed["is_passed"] and not state_passed["is_current"], "Uma Fase já vencida deve ser is_passed=true, is_current=false")
	ctx.check(not state_blocked["is_current"] and not state_blocked["is_passed"], "Uma Fase muito à frente deve ser is_current=false, is_passed=false (bloqueada)")

	panel.free()
	KingdomState.kingdom = old_kingdom
	return true
