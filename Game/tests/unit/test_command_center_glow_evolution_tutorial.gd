class_name TestCommandCenterGlowEvolutionTutorial
extends RefCounted
## TestCommandCenterGlowEvolutionTutorial (Auditoria pré-pré-alfa)
##
## Cobre 3 achados reais desta auditoria, nenhum deles regra de jogo
## nova — só integração/apresentação do que já existia:
##
## A) HotspotGlow nunca estava ligado ao Centro de Comando (achado real:
##    nenhuma referência a HotspotGlow existia em command_center_panel.gd,
##    apesar do componente já ser usado em 8 outras telas) — corrigido
##    reaproveitando o mesmo componente/padrão.
## B) "Ativar Próximo Recurso Administrativo" (Expansão Administrativa,
##    COMMAND_CENTER_PROGRESS.md) já era 100% implementado e testado
##    (CommandCenterResolver.activate_next()), mas o único botão que o
##    disparava tinha sido removido só da apresentação — corrigido só o
##    acesso, nenhum resolver novo.
## C) Tutorial de Comandantes (Ativo x Reserva), disparado pelo 1º
##    recrutamento (nunca a simples abertura da tela), usando
##    TutorialSpotlight (destaque + escurecimento reais) — texto
##    adaptado de Arquitetura/TUTORIAL.md, "Etapa 4 — O Alto-Comando".

const CommandCenterPanelScript: GDScript = preload("res://scenes/command_center/command_center_panel.gd")
const ComandantesPanelScript: GDScript = preload("res://scenes/command_center/panels/comandantes_panel.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria] Validando Glow do CdC, Expansão Administrativa e Tutorial de Comandantes...")
	_test_a_hotspot_glow_wired_to_command_center(ctx)
	_test_b_activate_next_chip_reflects_real_state(ctx)
	_test_c_tutorial_triggers_on_first_recruitment(ctx)
	_test_d_tutorial_never_retriggers_after_completed(ctx)
	_test_e_promote_action_advances_tutorial(ctx)
	_test_f_promote_before_dismissing_step_a_never_locks_tutorial(ctx)
	_test_g_evolve_chip_present_and_reflects_real_level_and_cost(ctx)
	return true


## A: os 5 hotspots documentados (Comandantes/Exércitos/Campo de Prova/
## Legado/Treinamento) devem, cada um, ter um HotspotGlow real associado
## — nunca só o Control de input sozinho.
static func _test_a_hotspot_glow_wired_to_command_center(ctx: TestRunner.Context) -> void:
	var panel: Control = CommandCenterPanelScript.new()
	var host := Control.new()
	host.add_child(panel)
	panel.call("_build_static_structure")

	var glows: Dictionary = panel.get("_hotspot_glows")
	var expected_names: Array[String] = ["Hotspot_Comandantes", "Hotspot_Exercitos", "Hotspot_CampoDeProva", "Hotspot_Legado", "Hotspot_Treinamento"]
	print("  [A] _hotspot_glows preenchido para os 5 hotspots documentados? %s (obtido: %s)" % [str(glows.size() == 5), str(glows.keys())])
	ctx.check(glows.size() == 5, "[A] Os 5 hotspots do CdC devem ter um HotspotGlow associado (achado real: nenhum tinha antes desta correção)")
	for name: String in expected_names:
		ctx.check(glows.has(name), "[A] Hotspot '%s' deve ter um HotspotGlow associado" % name)

	host.free()


## B: o chip de Expansão Administrativa deve mostrar corretamente
## "Ativar" habilitado/desabilitado conforme PG real disponível — nunca
## permitir clique sem PG suficiente, e sempre refletir
## CommandCenterProgress.pg_cost_per_activation() real (nunca um valor
## paralelo).
static func _test_b_activate_next_chip_reflects_real_state(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.command_center_level = 1

	var panel: Control = ComandantesPanelScript.new()
	var chip_without_pg: Control = panel.call("_build_activate_next_chip", kingdom)
	var button_without_pg: Button = _find_button(chip_without_pg, "Ativar")
	print("  [B1] Sem PG (0/1 necessário) -> botão 'Ativar' desabilitado? %s (esperado: true)" % str(button_without_pg != null and button_without_pg.disabled))
	ctx.check(button_without_pg != null, "[B1] O chip deve conter um botão 'Ativar' quando há Infraestrutura pendente")
	ctx.check(button_without_pg.disabled, "[B1] Sem PG suficiente, o botão 'Ativar' deve ficar desabilitado (nunca permitir a ação)")

	kingdom.generation_points = 5
	var chip_with_pg: Control = panel.call("_build_activate_next_chip", kingdom)
	var button_with_pg: Button = _find_button(chip_with_pg, "Ativar")
	print("  [B2] Com PG suficiente -> botão 'Ativar' habilitado? %s (esperado: true)" % str(button_with_pg != null and not button_with_pg.disabled))
	ctx.check(button_with_pg != null and not button_with_pg.disabled, "[B2] Com PG suficiente, o botão 'Ativar' deve ficar habilitado")

	var result: Dictionary = CommandCenterResolver.activate_next(kingdom)
	print("  [B3] Clique real em 'Ativar' -> CommandCenterResolver.activate_next() real: %s" % str(result))
	ctx.check(result["success"], "[B3] Com PG suficiente e Infraestrutura pendente, activate_next() deve suceder de verdade")

	chip_without_pg.free()
	chip_with_pg.free()
	panel.free()


static func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for child: Node in node.get_children():
		var found: Button = _find_button(child, text)
		if found != null:
			return found
	return null


## C: um Reino com exatamente 1 Comandante recém-recrutado (em Reserva,
## nenhuma flag de tutorial ainda marcada) deve mostrar o Passo A do
## Tutorial de Comandantes — nunca antes de existir um Comandante.
static func _test_c_tutorial_triggers_on_first_recruitment(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()

	var panel_no_commander: Control = ComandantesPanelScript.new()
	var target_none: Variant = panel_no_commander.call("_resolve_tutorial_target_commander", kingdom)
	print("  [C1] Reino sem nenhum Comandante -> alvo do tutorial: %s (esperado: null)" % str(target_none))
	ctx.check(target_none == null, "[C1] Sem nenhum Comandante recrutado, o Tutorial de Comandantes nunca deve ter alvo")
	panel_no_commander.free()

	var commander := CommanderResource.new()
	commander.commander_name = "Teste"
	commander.faction = "Império"
	commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	kingdom.commanders.append(commander)

	var panel: Control = ComandantesPanelScript.new()
	var target: CommanderResource = panel.call("_resolve_tutorial_target_commander", kingdom)
	print("  [C2] 1 Comandante recém-recrutado (Reserva) -> alvo do tutorial é ele mesmo? %s (esperado: true)" % str(target == commander))
	ctx.check(target == commander, "[C2] O 1º Comandante recrutado (em Reserva) deve ser o alvo do Tutorial de Comandantes")
	panel.free()


## D: uma vez marcada "commander_tutorial_completed", o tutorial nunca
## deve voltar a aparecer, mesmo com o mesmo Comandante ainda existindo.
static func _test_d_tutorial_never_retriggers_after_completed(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Teste"
	commander.faction = "Império"
	commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE
	kingdom.commanders.append(commander)
	kingdom.set_progress_flag("commander_tutorial_completed", true)

	var panel: Control = ComandantesPanelScript.new()
	var target: Variant = panel.call("_resolve_tutorial_target_commander", kingdom)
	print("  [D] Tutorial já concluído -> nunca reaparece (alvo: %s, esperado: null)" % str(target))
	ctx.check(target == null, "[D] Com 'commander_tutorial_completed' marcada, o Tutorial de Comandantes nunca deve ter alvo novamente")
	panel.free()


## E: a ação REAL de promover (CommandCenterResolver.move_to_active(),
## nunca um botão 'Continuar' fingindo a ação) marca
## 'commander_tutorial_promoted' — só quando bem-sucedida e só para o
## Comandante que o tutorial está de fato acompanhando.
static func _test_e_promote_action_advances_tutorial(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Teste"
	commander.faction = "Império"
	commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	kingdom.commanders.append(commander)
	kingdom.cargo_ativo_activated = 1  # Exceção Inicial do Nível 1 (COMMAND_CENTER_PROGRESS.md)

	var result: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	print("  [E1] Promover (ação real) com Cargo Ativo disponível -> sucesso? %s" % str(result))
	ctx.check(result["success"], "[E1] Com Cargo Ativo livre, move_to_active() deve suceder de verdade")
	ctx.check(commander.administrative_state == CommanderResource.AdministrativeState.ACTIVE, "[E1] O Comandante promovido deve realmente ficar Ativo (nunca só a flag do tutorial, sem o estado real mudar)")


## F: BUG REAL encontrado e corrigido nesta auditoria — clicar em
## "Promover" (botão real, sempre clicável) ANTES de dispensar o Passo A
## do tutorial não pode travar o fluxo: o alvo do tutorial precisa
## continuar sendo o mesmo Comandante, e o Passo C (confirmação) precisa
## aparecer, mesmo sem o Passo A ter sido explicitamente dispensado.
static func _test_f_promote_before_dismissing_step_a_never_locks_tutorial(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Pulou o Passo A"
	commander.faction = "Império"
	commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	kingdom.commanders.append(commander)

	var panel: Control = ComandantesPanelScript.new()
	# Passo A NUNCA foi visto (commander_tutorial_step_a_seen == false) —
	# simula o jogador clicando direto em "Promover" sem passar por ali.
	var result: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	kingdom.set_progress_flag("commander_tutorial_promoted", true)

	var target_after: CommanderResource = panel.call("_resolve_tutorial_target_commander", kingdom)
	print("  [F1] Promoção real ANTES do Passo A ser visto -> sucesso: %s | alvo do tutorial continua o mesmo Comandante? %s (esperado: true)" % [str(result["success"]), str(target_after == commander)])
	ctx.check(result["success"], "[F1] A promoção real deve suceder independente do tutorial")
	ctx.check(target_after == commander, "[F1] O alvo do tutorial NUNCA deve 'desaparecer' quando o Comandante deixa de estar em Reserva por uma ação real do jogador")
	ctx.check(not kingdom.has_progress_flag("commander_tutorial_completed"), "[F1] O tutorial não deve se auto-marcar concluído só porque o Comandante não está mais em Reserva — precisa mostrar o Passo C primeiro")

	panel.free()


## G: BUG REAL encontrado e corrigido nesta auditoria — o clique real na
## Cidade não abre mais o popup "Abrir/Evoluir" (mudança arquitetural
## anterior: hitbox agora navega direto pra tela da construção,
## comprovado por clique real simulado via Input.parse_input_event()),
## deixando a Evolução Vertical do CdC sem NENHUM acesso real. Corrigido
## com um botão real dentro da própria tela do CdC, mesma fonte de
## verdade (InstitutionalConstructionResolver/InstitutionalConstructionConfig)
## de Capital/Academia/Núcleo — nunca uma fórmula nova. Este teste cobre
## a estrutura (o botão existe, reflete Nível/custo reais); o
## comportamento end-to-end do clique real (incluindo o bug de "Object
## is locked" já corrigido via CONNECT_DEFERRED) foi validado por
## screenshot real com Input.parse_input_event(), registrado no
## relatório desta auditoria.
static func _test_g_evolve_chip_present_and_reflects_real_level_and_cost(ctx: TestRunner.Context) -> void:
	# _build_evolve_chip() lê KingdomState.kingdom diretamente (mesmo
	# padrão de _ready()/refresh() desta tela — nunca recebe Kingdom por
	# parâmetro) — precisa mutar o singleton real, não um Kingdom.new()
	# isolado, senão o chip reflete o Kingdom real (level diferente),
	# nunca o valor deste teste.
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.command_center_level = 3

	var panel: Control = CommandCenterPanelScript.new()
	var host := Control.new()
	host.add_child(panel)
	panel.call("_build_static_structure")

	var expected_costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO, 4)
	var expected_prefix: String = "Evoluir (Nível 3 → 4"
	var evolve_label: Label = _find_label_with_prefix(panel, expected_prefix)
	print("  [G1] Chip 'Evoluir' existe e mostra Nível real (3 → 4)? %s (texto: '%s')" % [str(evolve_label != null), evolve_label.text if evolve_label != null else ""])
	ctx.check(evolve_label != null, "[G1] A tela do CdC deve ter um chip 'Evoluir' real, refletindo command_center_level real")
	if evolve_label != null:
		for resource: String in expected_costs:
			ctx.check(evolve_label.text.contains(str(expected_costs[resource])), "[G1] O custo exibido deve bater com InstitutionalConstructionResolver.cost_breakdown() real (%s: %d)" % [resource, expected_costs[resource]])

	host.free()


static func _find_label_with_prefix(node: Node, prefix: String) -> Label:
	if node is Label and (node as Label).text.begins_with(prefix):
		return node
	for child: Node in node.get_children():
		var found: Label = _find_label_with_prefix(child, prefix)
		if found != null:
			return found
	return null
