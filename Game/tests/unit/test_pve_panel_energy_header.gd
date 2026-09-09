class_name TestPvePanelEnergyHeader
extends RefCounted
## TestPvePanelEnergyHeader (F-021.4)
##
## Barra/legenda de Energia do header da Trilha: sempre lê
## expedition.squad.active_army().current_energy/max_energy no momento
## do refresh — nunca um valor copiado/duplicado. Mesmo padrão de
## instanciação fora da SceneTree já usado por
## test_pve_panel_segment_navigation.gd (_build_static_structure() +
## _on_view_expedition_pressed(), nunca _ready()).

const PvEPanelScript = preload("res://scenes/command_center/panels/pve_panel.gd")


static func _build_expedition_with_energy(seed_value: int, energy_nucleus_level: int) -> ExpeditionRuntime:
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.army_name = "Exército Teste Energia"
	army.initialize_energy(energy_nucleus_level)
	var squad := Squad.new([army])
	var territory := Territory.new("Territorio-Teste-Energia-%d" % seed_value, "Natureza")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()
	return ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, seed_value,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)


static func _new_panel_for(expedition: ExpeditionRuntime) -> Control:
	var kingdom := Kingdom.new()
	kingdom.active_expeditions.append(expedition)
	KingdomState.kingdom = kingdom
	var panel = PvEPanelScript.new()
	panel._build_static_structure()
	panel._on_view_expedition_pressed(expedition)
	return panel


static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021.4] Validando a barra de Energia do header da Trilha...")

	_test_1_energia_correta_ao_carregar(ctx)
	_test_2_energia_atualiza_apos_tentativa(ctx)
	_test_3_energia_esgotada_refletida(ctx)
	_test_4_refresh_repetido_mantem_valor_correto(ctx)
	_test_5_nenhum_estado_duplicado(ctx)

	return true


## 1: ao carregar (primeiro refresh real, via _on_view_expedition_pressed),
## a barra/tooltip devem refletir current_energy/max_energy reais do
## Exército ativo — nunca um valor fixo/zerado por padrão.
static func _test_1_energia_correta_ao_carregar(ctx: TestRunner.Context) -> void:
	var expedition: ExpeditionRuntime = _build_expedition_with_energy(910, 1)
	var army: Army = expedition.squad.active_army()
	var panel := _new_panel_for(expedition)

	var expected_ratio: float = float(army.current_energy) / float(army.max_energy)
	print("  [1] Barra reflete ratio real (%d/%d = %.3f)? %s (obtido: %.3f)" % [
		army.current_energy, army.max_energy, expected_ratio, str(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio)), panel._map_header_energy_bar.value
	])
	ctx.check(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio), "[1] O valor da barra deve ser exatamente current_energy/max_energy do Exército ativo real")
	ctx.check(panel._map_header_energy_bar.tooltip_text == "%d / %d" % [army.current_energy, army.max_energy], "[1] O tooltip (hover) deve mostrar 'atual / máximo' reais (ENERGY.md, 'Interface')")
	ctx.check(army.army_name in panel._map_header_energy_caption.text, "[1] A legenda deve identificar o Exército real que está consumindo essa Energia")
	panel.free()


## 2: uma tentativa real (attempt_current_fase()) consome Energia de
## verdade em Army — o próximo refresh() deve mostrar o valor NOVO, sem
## nenhuma chamada adicional além de refresh().
static func _test_2_energia_atualiza_apos_tentativa(ctx: TestRunner.Context) -> void:
	var expedition: ExpeditionRuntime = _build_expedition_with_energy(911, 5)
	var army: Army = expedition.squad.active_army()
	var panel := _new_panel_for(expedition)
	var energy_before: int = army.current_energy

	expedition.attempt_current_fase()
	panel.refresh()

	var energy_after: int = army.current_energy
	var expected_ratio: float = float(energy_after) / float(army.max_energy)
	print("  [2] Energia antes (%d) -> depois de 1 tentativa (%d)? %s | barra atualizou para %.3f (esperado %.3f)? %s" % [
		energy_before, energy_after, str(energy_after < energy_before), panel._map_header_energy_bar.value, expected_ratio, str(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio))
	])
	ctx.check(energy_after < energy_before, "[2] Uma tentativa de Fase deve consumir Energia real do Exército (pré-condição do teste)")
	ctx.check(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio), "[2] refresh() após uma tentativa deve mostrar o novo valor real de Energia, sem cache stale")
	panel.free()


## 3: current_energy <= 0 deve ficar claramente identificável (cor de
## aviso + texto "ESGOTADA") — reaproveitando HUD_WARNING_COLOR já
## usado no resto do painel, nenhuma cor nova.
static func _test_3_energia_esgotada_refletida(ctx: TestRunner.Context) -> void:
	var expedition: ExpeditionRuntime = _build_expedition_with_energy(912, 1)
	var army: Army = expedition.squad.active_army()
	army.current_energy = 0
	var panel := _new_panel_for(expedition)

	print("  [3] Energia 0/%d -> legenda menciona 'ESGOTADA'? %s | barra em 0? %s" % [
		army.max_energy, str("ESGOTADA" in panel._map_header_energy_caption.text), str(is_equal_approx(panel._map_header_energy_bar.value, 0.0))
	])
	ctx.check("ESGOTADA" in panel._map_header_energy_caption.text, "[3] Energia esgotada (current_energy<=0) deve ser comunicada claramente na legenda, sem inventar uma regra nova")
	ctx.check(is_equal_approx(panel._map_header_energy_bar.value, 0.0), "[3] A barra deve mostrar 0 quando a Energia está esgotada")
	ctx.check(panel._map_header_energy_caption.get_theme_color("font_color") == PvEPanelScript.HUD_WARNING_COLOR, "[3] A cor de aviso já usada no resto do painel (HUD_WARNING_COLOR) deve ser reaproveitada, nunca uma cor nova")
	panel.free()


## 4: chamar refresh() repetidamente na mesma Expedição sem nenhuma
## mudança real de estado nunca deve alterar o valor mostrado (idempotência).
static func _test_4_refresh_repetido_mantem_valor_correto(ctx: TestRunner.Context) -> void:
	var expedition: ExpeditionRuntime = _build_expedition_with_energy(913, 3)
	var panel := _new_panel_for(expedition)
	var value_a: float = panel._map_header_energy_bar.value

	panel.refresh()
	panel.refresh()
	var value_b: float = panel._map_header_energy_bar.value

	print("  [4] refresh() repetido sem mudança de estado mantém o mesmo valor (%.3f -> %.3f)? %s" % [value_a, value_b, str(is_equal_approx(value_a, value_b))])
	ctx.check(is_equal_approx(value_a, value_b), "[4] refresh() repetido sem mudança real de Energia nunca deve alterar o valor mostrado")
	panel.free()


## 5 (o mais importante): a UI NUNCA guarda sua própria cópia de
## Energia — mudar army.current_energy por fora (sem passar por nenhum
## método do painel) e chamar refresh() deve refletir a mudança externa
## imediatamente. Se o painel tivesse estado duplicado, isto falharia.
static func _test_5_nenhum_estado_duplicado(ctx: TestRunner.Context) -> void:
	var expedition: ExpeditionRuntime = _build_expedition_with_energy(914, 2)
	var army: Army = expedition.squad.active_army()
	var panel := _new_panel_for(expedition)

	army.current_energy = 1  # mutação externa direta, nunca via método do painel
	panel.refresh()

	var expected_ratio: float = 1.0 / float(army.max_energy)
	print("  [5] Mutação externa direta em army.current_energy (=1) aparece no próximo refresh() sem nenhum setter do painel? %s (obtido %.3f, esperado %.3f)" % [
		str(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio)), panel._map_header_energy_bar.value, expected_ratio
	])
	ctx.check(is_equal_approx(panel._map_header_energy_bar.value, expected_ratio), "[5] A UI deve sempre ler a fonte real (Army) no momento do refresh — nenhum estado de Energia paralelo/duplicado no painel")
	panel.free()
