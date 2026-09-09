class_name TestTutorialContextualHints
extends RefCounted
## TestTutorialContextualHints (F-021.5)
##
## FASE 21.2 decidiu um onboarding curto (4 passos lineares, já
## cobertos por test_tutorial_flow.gd) + dicas contextuais
## independentes, disparadas na primeira vez que o jogador realmente
## encontra cada sistema: Formação, Campo de Prova, Energia,
## Acampamento, Mina Regional, Guarnição. Cada uma usa sua própria
## progress_flag (nunca a sequência linear tutorial_step) — mesmo
## padrão de instanciação fora da SceneTree já usado por
## test_tutorial_flow.gd (métodos reais, sem _ready()/get_tree()).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021.5] Validando as dicas contextuais (Formação/Campo de Prova/Energia/Acampamento/Mina/Guarnição)...")
	_test_formacao_hint(ctx)
	_test_campo_de_prova_hint(ctx)
	_test_energia_hint(ctx)
	_test_acampamento_hint(ctx)
	_test_mina_hint(ctx)
	_test_guarnicao_hint(ctx)
	return true


## Formação: só aparece depois que o Passo 2 (linear) já não está mais
## pendente — evita duas dicas competindo pelo mesmo espaço.
static func _test_formacao_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.set_progress_flag("tutorial_concluido")  # tutorial linear já encerrado
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var army := Army.new()
	army.commander = option["commander"]
	army.cards = (option["cards"] as Array[CardResource]).duplicate()
	kingdom.armies.append(army)

	var panel = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	panel._selected_army = army
	panel._build_static_structure()

	var hint_present: bool = _find_hint_banner(panel) != null
	print("  [Formação] Dica aparece ao ver a Formação de um Exército real (tutorial linear já concluído)? %s" % str(hint_present))
	ctx.check(hint_present, "A dica de Formação deve aparecer na primeira vez que a grade real é exibida")

	# Dispensa: encontra o botão "Continuar" real e simula o clique via
	# o handler direto (mesmo padrão de test_tutorial_flow.gd).
	panel._on_formacao_hint_continue(_find_hint_banner(panel))
	print("  [Formação] flag setada após dispensar? %s" % str(kingdom.has_progress_flag("tutorial_hint_formacao_visto")))
	ctx.check(kingdom.has_progress_flag("tutorial_hint_formacao_visto"), "Dispensar a dica deve marcar a progress_flag própria")

	panel.free()

	var panel2 = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	panel2._selected_army = army
	panel2._build_static_structure()
	var hint_present_again: bool = _find_hint_banner(panel2) != null
	print("  [Formação] Não reaparece depois de dispensada? %s" % str(not hint_present_again))
	ctx.check(not hint_present_again, "A dica de Formação não deve reaparecer depois de dispensada")
	panel2.free()

	KingdomState.kingdom = old_kingdom


static func _find_hint_banner(node: Node) -> Control:
	for child in node.get_children():
		if child.get_script() != null and "tutorial_hint_banner" in str(child.get_script().resource_path):
			return child
	return null


## Campo de Prova: aparece na primeira abertura (_ready()), nunca depois.
static func _test_campo_de_prova_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom
	kingdom.armies.clear()

	var panel = preload("res://scenes/command_center/panels/campo_de_prova_panel.gd").new()
	panel._ready()
	var hint: Control = _find_hint_banner(panel)
	print("  [Campo de Prova] Dica aparece na primeira abertura? %s" % str(hint != null))
	ctx.check(hint != null, "A dica do Campo de Prova deve aparecer na primeira vez que a tela abre")

	panel._on_tutorial_hint_continue(hint)
	ctx.check(kingdom.has_progress_flag("tutorial_hint_campo_de_prova_visto"), "Dispensar deve marcar a progress_flag própria")
	panel.free()

	var panel2 = preload("res://scenes/command_center/panels/campo_de_prova_panel.gd").new()
	panel2._ready()
	print("  [Campo de Prova] Não reaparece depois de dispensada? %s" % str(_find_hint_banner(panel2) == null))
	ctx.check(_find_hint_banner(panel2) == null, "A dica do Campo de Prova não deve reaparecer depois de dispensada")
	panel2.free()

	KingdomState.kingdom = old_kingdom


static func _build_test_expedition(seed_value: int) -> ExpeditionRuntime:
	var enemy: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(5)
	var squad := Squad.new([army])
	var territory := Territory.new("Territorio-Teste-Hint-%d" % seed_value, "Natureza")
	var trilha := Trilha.new(territory.id)
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog(territory.faction, enemy)
	var registry := RegionalCommanderRegistry.new()
	return ExpeditionRuntime.new(
		squad, trilha, territory, catalog, registry, seed_value,
		GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)


## Energia: aparece na primeira vez que uma Expedição real é vista.
static func _test_energia_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var expedition: ExpeditionRuntime = _build_test_expedition(920)
	kingdom.active_expeditions.append(expedition)
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	panel._build_static_structure()
	panel._on_view_expedition_pressed(expedition)

	print("  [Energia] Dica aparece ao ver o mapa de uma Expedição real pela 1ª vez? %s" % str(panel._tutorial_banner != null))
	ctx.check(panel._tutorial_banner != null, "A dica de Energia deve aparecer na primeira vez que o mapa da Expedição é visto")

	panel._on_energy_hint_continue()
	print("  [Energia] flag setada e banner liberado? %s, %s" % [
		str(kingdom.has_progress_flag("tutorial_hint_energia_visto")), str(panel._tutorial_banner == null)
	])
	ctx.check(kingdom.has_progress_flag("tutorial_hint_energia_visto"), "Dispensar deve marcar a progress_flag própria")
	ctx.check(panel._tutorial_banner == null, "Dispensar deve liberar a referência do banner")
	panel.free()

	KingdomState.kingdom = old_kingdom


static func _find_inline_hint(node: Node) -> Control:
	return node.find_child("InlineHint", true, false)


## Acampamento: aparece dentro do próprio overlay (bloco simples,
## _build_inline_hint — nunca a moldura ornamentada, que colidia
## visualmente com a janela do Acampamento em telas baixas), some junto
## quando ele fecha.
static func _test_acampamento_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.set_progress_flag("tutorial_hint_energia_visto")  # isola do teste de Energia
	var expedition: ExpeditionRuntime = _build_test_expedition(921)
	kingdom.active_expeditions.append(expedition)
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	panel._build_static_structure()
	panel._on_view_expedition_pressed(expedition)
	panel._open_camp_overlay(expedition)

	var hint: Control = _find_inline_hint(panel._camp_overlay)
	print("  [Acampamento] Dica aparece dentro do overlay na primeira abertura? %s" % str(hint != null))
	ctx.check(hint != null, "A dica de Acampamento deve aparecer dentro do overlay na primeira vez que ele abre")

	panel._on_inline_hint_dismissed("tutorial_hint_acampamento_visto", hint)
	ctx.check(kingdom.has_progress_flag("tutorial_hint_acampamento_visto"), "Dispensar deve marcar a progress_flag própria")
	panel.free()

	KingdomState.kingdom = old_kingdom


## Mina: aparece dentro do overlay de Mina, na primeira vez que ela é encontrada.
static func _test_mina_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.set_progress_flag("tutorial_hint_energia_visto")
	var expedition: ExpeditionRuntime = _build_test_expedition(922)
	kingdom.active_expeditions.append(expedition)
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var mina := Mina.new(1, expedition.territory.faction)
	mina.region = 1

	var panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	panel._build_static_structure()
	panel._on_view_expedition_pressed(expedition)
	panel._on_mine_node_pressed(expedition, mina)

	var hint: Control = _find_inline_hint(panel._mine_overlay)
	print("  [Mina] Dica aparece dentro do overlay na primeira vez que uma Mina é aberta? %s" % str(hint != null))
	ctx.check(hint != null, "A dica de Mina Regional deve aparecer dentro do overlay na primeira vez que uma Mina é aberta")

	panel._on_inline_hint_dismissed("tutorial_hint_mina_visto", hint)
	ctx.check(kingdom.has_progress_flag("tutorial_hint_mina_visto"), "Dispensar deve marcar a progress_flag própria")
	panel.free()

	KingdomState.kingdom = old_kingdom


## Guarnição: aparece em minas_panel.gd quando existe uma Mina Regional
## conquistada sem Guarnição designada — nunca antes disso.
static func _test_guarnicao_hint(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var panel = preload("res://scenes/command_center/panels/minas_panel.gd").new()
	panel._build_static_structure()
	panel.refresh()
	print("  [Guarnição] Sem Mina Regional conquistada, dica não aparece? %s" % str(panel._guarnicao_hint == null))
	ctx.check(panel._guarnicao_hint == null, "A dica de Guarnição não deve aparecer sem nenhuma Mina Regional conquistada")
	panel.free()

	var mina := Mina.new(3500, "Império")
	mina.conquer()
	mina.region = 1
	kingdom.territory_mines["territorio-teste-guarnicao"] = [mina]

	var panel2 = preload("res://scenes/command_center/panels/minas_panel.gd").new()
	panel2._build_static_structure()
	panel2.refresh()
	print("  [Guarnição] Mina Regional conquistada sem Guarnição -> dica aparece? %s" % str(panel2._guarnicao_hint != null))
	ctx.check(panel2._guarnicao_hint != null, "A dica de Guarnição deve aparecer quando existe uma Mina Regional conquistada sem Guarnição")

	panel2._on_guarnicao_hint_continue()
	print("  [Guarnição] flag setada e não reaparece após novo refresh()? %s" % str(kingdom.has_progress_flag("tutorial_hint_guarnicao_visto")))
	ctx.check(kingdom.has_progress_flag("tutorial_hint_guarnicao_visto"), "Dispensar deve marcar a progress_flag própria")
	panel2.refresh()
	ctx.check(panel2._guarnicao_hint == null, "A dica de Guarnição não deve reaparecer depois de dispensada, mesmo com a mesma Mina ainda sem Guarnição")
	panel2.free()

	KingdomState.kingdom = old_kingdom
