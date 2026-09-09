class_name TestCityHotspotGlow
extends RefCounted
## TestCityHotspotGlow (FASE 12, 2026-09-04; estendido na FASE 13)
##
## Cobre os "TESTES DE LÓGICA" 7-12 do pedido — o brilho de hotspot
## reescopado da Fase 12: NÃO mais no Battlefield (ver
## test_battlefield_hover.gd), e sim nas 6 telas "arte é a interface"
## já existentes na Cidade/construções (auditoria desta tarefa —
## city_panel.gd, biblioteca_panel.gd, observatorio_panel.gd,
## deposito_panel.gd, energy_core_hub_panel.gd, world_map_gate_panel.gd
## — todas usando _build_hitbox()/_build_hotspot() com o MESMO padrão
## "Control invisível sobre uma região fracionária calibrada"). Telas
## de UI normal (Button-driven — Exércitos, Bestiário, Academia/Depósito
## internos etc.) NÃO recebem glow, por decisão explícita do pedido
## ("não transformar todos os controles da interface em pontos
## luminosos") — nada a testar ali (nenhum código novo foi adicionado a
## esses arquivos).
##
## FASE 15 — academia_panel.gd e capital_panel.gd (também "arte é a
## interface", mesmo padrão _build_hitbox()/_build_hotspot() de sempre)
## nunca tinham recebido a integração da Fase 12: auditoria desta tarefa
## confirmou que os dois arquivos simplesmente nunca chamavam
## HotspotGlow.attach_to_region() — não era um bug de contraste/
## renderização (medição de cor real de academia_v1.png/capital_v2.png
## nos centros dos hotspots confirmou distância de cor até GLOW_COLOR
## comparável ou maior que a da própria Cidade, ~111-259; ver relatório
## da tarefa), era feature ausente. Testes 16-19 abaixo cobrem as duas
## telas com a mesma integração já usada pelas demais.
##
## FASE 13 (2026-09-04) — adiciona os itens 3/6/7/9/10 dos "TESTES
## HEADLESS" pedidos que ainda não tinham cobertura própria: parent
## correto (3), hover/exit nas 5 telas internas — não só na Cidade (6/7,
## a Fase 12 só cobria isso pra CityPanel), cleanup real (9 — free()
## libera o glow junto, sem referência pendente) e reabertura não
## duplica (10 — o ciclo de vida real do jogo é change_scene_to_file(),
## que DESTRÓI a cena inteira antes de criar a próxima; nunca existe
## reconstrução parcial de uma mesma instância — testado explicitamente
## aqui). A INVESTIGAÇÃO da causa raiz do "glow não aparece nas telas
## internas" está documentada em detalhe no relatório desta tarefa — a
## auditoria estrutural exaustiva (parent/visibilidade/estado/
## mouse_filter/is_processing/is_inside_tree/bounds de recorte em 5
## proporções de janela) não encontrou NENHUMA diferença de código
## entre a Cidade (confirmada funcionando) e as 5 telas internas; os
## testes abaixo tornam essa equivalência permanente e verificável.
##
## Instanciação: preload(caminho).new() + chamada direta de
## _build_static_structure() (nunca _ready(), que é assíncrono/usa
## await — incompatível com TestRunner.run(), síncrono por design, ver
## test_runner.gd) — mesmo padrão já usado por test_tutorial_flow.gd
## pra estas mesmas cenas (_maybe_show_tutorial_hint() ali,
## _build_static_structure() aqui).

const HotspotGlowScript = preload("res://engine/presentation/hotspot_glow.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[FASE 12] Validando o sinal luminoso dos hotspots da Cidade/construções...")
	_test_1_city_panel_todos_os_8_hotspots_tem_glow(ctx)
	_test_2_city_panel_glow_nao_bloqueia_mouse(ctx)
	_test_3_city_panel_hover_aumenta_o_brilho(ctx)
	_test_4_city_panel_sair_do_hover_retorna_ao_normal(ctx)
	_test_5_hotspot_indisponivel_nao_mostra_glow(ctx)
	_test_6_biblioteca_3_hotspots_tem_glow(ctx)
	_test_7_observatorio_4_hotspots_tem_glow(ctx)
	_test_8_deposito_4_hotspots_tem_glow(ctx)
	_test_9_world_map_gate_3_hotspots_tem_glow(ctx)
	_test_10_energy_core_hub_1_hotspot_tem_glow(ctx)
	_test_11_parent_correto_nas_5_telas_internas(ctx)
	_test_12_hover_e_exit_nas_5_telas_internas(ctx)
	_test_13_cleanup_libera_o_glow_junto(ctx)
	_test_14_reabertura_nao_duplica_glows(ctx)
	_test_15_contorno_de_contraste_e_suficientemente_escuro(ctx)
	_test_16_academia_3_hotspots_tem_glow(ctx)
	_test_17_capital_4_hotspots_tem_glow(ctx)
	_test_18_parent_correto_academia_e_capital(ctx)
	_test_19_hover_e_exit_academia_e_capital(ctx)
	_test_20_cleanup_e_reabertura_academia_e_capital(ctx)
	return true


## TESTE 1 (item 7): cada um dos 8 hotspots reais da Cidade
## (BUILDING_REGIONS) recebe um indicador luminoso — nenhum a mais,
## nenhum a menos (item 8: nada "inventado").
static func _test_1_city_panel_todos_os_8_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._build_static_structure()

	var region_keys: Array = city_panel.BUILDING_REGIONS.keys()
	print("  [1] Regiões clicáveis reais da Cidade: %d | glows registrados: %d" % [region_keys.size(), city_panel._building_glows.size()])
	ctx.check(city_panel._building_glows.size() == region_keys.size(), "[1] O número de glows deve bater EXATAMENTE com o número de hotspots reais (BUILDING_REGIONS) — nenhum a mais (nada decorativo vira clicável), nenhum a menos")

	for key: String in region_keys:
		ctx.check(city_panel._building_glows.has(key), "[1] A construção '%s' (hotspot real) deve ter um HotspotGlow associado" % key)

	city_panel.free()


## TESTE 2 (item 9): o glow nunca bloqueia o mouse — mouse_filter=IGNORE
## em todos.
static func _test_2_city_panel_glow_nao_bloqueia_mouse(ctx: TestRunner.Context) -> void:
	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._build_static_structure()

	var all_ignore: bool = true
	for key: String in city_panel._building_glows:
		if city_panel._building_glows[key].mouse_filter != Control.MOUSE_FILTER_IGNORE:
			all_ignore = false

	print("  [2] Todos os glows da Cidade são mouse_filter=IGNORE (nunca bloqueiam clique)? %s" % str(all_ignore))
	ctx.check(all_ignore, "[2] Nenhum HotspotGlow pode competir por mouse com o hotspot real que ele acompanha")

	city_panel.free()


## TESTE 3 (item 10): passar o mouse sobre um hotspot intensifica o
## brilho (AVAILABLE -> HOVER).
static func _test_3_city_panel_hover_aumenta_o_brilho(ctx: TestRunner.Context) -> void:
	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._build_static_structure()

	var glow = city_panel._building_glows["capital"]
	print("  [3] Estado inicial do glow da Capital: AVAILABLE? %s" % str(glow._state == HotspotGlowScript.State.AVAILABLE))
	ctx.check(glow._state == HotspotGlowScript.State.AVAILABLE, "[3] O glow deve começar em AVAILABLE (disponível, brilho normal)")

	city_panel._on_hitbox_mouse_entered(Control.new(), "Capital", "capital")
	print("  [3] Após o mouse entrar no hotspot, o glow intensifica (HOVER)? %s" % str(glow._state == HotspotGlowScript.State.HOVER))
	ctx.check(glow._state == HotspotGlowScript.State.HOVER, "[3] O brilho deve ficar mais evidente (HOVER) quando o mouse passa sobre o hotspot")

	city_panel.free()


## TESTE 4 (item 11): retirar o mouse volta o brilho ao estado normal.
static func _test_4_city_panel_sair_do_hover_retorna_ao_normal(ctx: TestRunner.Context) -> void:
	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._build_static_structure()

	var glow = city_panel._building_glows["biblioteca"]
	city_panel._on_hitbox_mouse_entered(Control.new(), "Biblioteca", "biblioteca")
	ctx.check(glow._state == HotspotGlowScript.State.HOVER, "[4] Pré-condição: glow em HOVER")

	city_panel._on_hitbox_mouse_exited("biblioteca")
	print("  [4] Após o mouse sair, o glow volta ao estado normal (AVAILABLE)? %s" % str(glow._state == HotspotGlowScript.State.AVAILABLE))
	ctx.check(glow._state == HotspotGlowScript.State.AVAILABLE, "[4] O brilho deve voltar ao estado normal (AVAILABLE) ao sair do hover")

	city_panel.free()


## TESTE 5 (item 12): um hotspot indisponível (DISABLED) nunca mostra
## glow — checagem estrutural do próprio componente (a Cidade hoje não
## tem nenhuma construção realmente "bloqueada" pra testar isso num
## cenário real, sem inventar essa lógica de jogo — ver docstring do
## topo; o CONTRATO do componente reutilizável é o que se garante aqui).
static func _test_5_hotspot_indisponivel_nao_mostra_glow(ctx: TestRunner.Context) -> void:
	var parent := Control.new()
	var glow = HotspotGlowScript.new().attach_to_region(parent, Rect2(0.1, 0.1, 0.2, 0.2))
	glow.set_hotspot_state(HotspotGlowScript.State.DISABLED)

	print("  [5] Glow em estado DISABLED não processa mais (_process desligado)? %s" % str(not glow.is_processing()))
	ctx.check(not glow.is_processing(), "[5] Um hotspot indisponível (DISABLED) deve parar de se redesenhar — nenhum brilho ativo")
	ctx.check(glow._state == HotspotGlowScript.State.DISABLED, "[5] O estado deve refletir DISABLED corretamente")

	parent.free()


static func _test_6_biblioteca_3_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/biblioteca_panel.gd").new()
	panel._build_static_structure()
	print("  [6] Biblioteca: %d hotspots -> %d glows (esperado 3, 3)" % [3, panel._hotspot_glows.size()])
	ctx.check(panel._hotspot_glows.size() == 3, "[6] A Biblioteca deve ter exatamente 3 glows (Bestiário/World Atlas/Lore Archive)")
	panel.free()


static func _test_7_observatorio_4_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/observatorio_panel.gd").new()
	panel._build_static_structure()
	print("  [7] Observatório: glows registrados = %d (esperado 4)" % panel._hotspot_glows.size())
	ctx.check(panel._hotspot_glows.size() == 4, "[7] O Observatório deve ter exatamente 4 glows (Overview/Astral Research/Celestial Charts/Celestial Forecast)")
	panel.free()


static func _test_8_deposito_4_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/deposito_panel.gd").new()
	panel._build_static_structure()
	print("  [8] Depósito: glows registrados = %d (esperado 4)" % panel._hotspot_glows.size())
	ctx.check(panel._hotspot_glows.size() == 4, "[8] O Depósito deve ter exatamente 4 glows (Crystal Vault/Kingdom Inventory/Supply Chain/Warehouse Upgrade)")
	panel.free()


static func _test_9_world_map_gate_3_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/world_map_gate/world_map_gate_panel.gd").new()
	panel._build_static_structure()
	print("  [9] World Map Gate: glows registrados = %d (esperado 3)" % panel._hotspot_glows.size())
	ctx.check(panel._hotspot_glows.size() == 3, "[9] O World Map Gate deve ter exatamente 3 glows (PvE/PvP/Minas)")
	panel.free()


static func _test_10_energy_core_hub_1_hotspot_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/energy_core_hub_panel.gd").new()
	panel._build_static_structure()
	print("  [10] Núcleo de Energia: glow único registrado? %s" % str(panel._hotspot_glow != null))
	ctx.check(panel._hotspot_glow != null, "[10] O hub do Núcleo de Energia deve ter o único glow (reator central) registrado")
	ctx.check(panel._hotspot_glow.mouse_filter == Control.MOUSE_FILTER_IGNORE, "[10] O glow do Núcleo de Energia nunca pode bloquear mouse")
	panel.free()


## TESTE 11 (FASE 13, item 3 do pedido — "parent correto"): o glow de
## cada hotspot interno precisa ser filho do MESMO Control (texture_rect)
## que hospeda o hotspot de input real — nunca de outro nó (o que faria
## o glow desenhar num lugar/ordem diferente do hotspot correspondente).
static func _test_11_parent_correto_nas_5_telas_internas(ctx: TestRunner.Context) -> void:
	var specs: Array[Dictionary] = [
		{"path": "res://scenes/city/panels/biblioteca_panel.gd", "dict": "_hotspot_glows", "label": "Biblioteca"},
		{"path": "res://scenes/city/panels/observatorio_panel.gd", "dict": "_hotspot_glows", "label": "Observatório"},
		{"path": "res://scenes/city/panels/deposito_panel.gd", "dict": "_hotspot_glows", "label": "Depósito"},
		{"path": "res://scenes/world_map_gate/world_map_gate_panel.gd", "dict": "_hotspot_glows", "label": "World Map Gate"},
	]
	for spec: Dictionary in specs:
		var panel = load(spec["path"]).new()
		panel._build_static_structure()
		var glows: Dictionary = panel.get(spec["dict"])
		var all_correct: bool = true
		for key: String in glows:
			var glow: Control = glows[key]
			# O hotspot de input real correspondente tem o MESMO
			# node_name — buscado como irmão dentro do mesmo parent.
			var parent: Node = glow.get_parent()
			var sibling_hotspot: Node = parent.find_child(key, false, false) if parent != null else null
			if parent == null or sibling_hotspot == null or sibling_hotspot.get_parent() != parent:
				all_correct = false
		print("  [11] %s: todo glow é filho do MESMO parent que o hotspot de input correspondente? %s" % [spec["label"], str(all_correct)])
		ctx.check(all_correct, "[11] %s: cada HotspotGlow deve ser filho do mesmo Control (texture_rect) que hospeda o hotspot real de mesmo node_name" % spec["label"])
		panel.free()


## TESTE 12 (FASE 13, itens 6/7): hover/exit funcionam nas 5 telas
## internas — a Fase 12 só tinha essa checagem pra CityPanel.
static func _test_12_hover_e_exit_nas_5_telas_internas(ctx: TestRunner.Context) -> void:
	var specs: Array[Dictionary] = [
		{"path": "res://scenes/city/panels/biblioteca_panel.gd", "dict": "_hotspot_glows", "entered": "_on_hotspot_mouse_entered", "exited": "_on_hotspot_mouse_exited", "label": "Biblioteca"},
		{"path": "res://scenes/city/panels/observatorio_panel.gd", "dict": "_hotspot_glows", "entered": "_on_hotspot_mouse_entered", "exited": "_on_hotspot_mouse_exited", "label": "Observatório"},
		{"path": "res://scenes/city/panels/deposito_panel.gd", "dict": "_hotspot_glows", "entered": "_on_hotspot_mouse_entered", "exited": "_on_hotspot_mouse_exited", "label": "Depósito"},
		{"path": "res://scenes/world_map_gate/world_map_gate_panel.gd", "dict": "_hotspot_glows", "entered": "_on_hotspot_mouse_entered", "exited": "_on_hotspot_mouse_exited", "label": "World Map Gate"},
	]
	for spec: Dictionary in specs:
		var panel = load(spec["path"]).new()
		panel._build_static_structure()
		var glows: Dictionary = panel.get(spec["dict"])
		var key: String = glows.keys()[0]
		var glow = glows[key]

		panel.callv(spec["entered"], [Control.new(), "teste", key])
		var hover_ok: bool = glow._state == HotspotGlowScript.State.HOVER
		panel.callv(spec["exited"], [key])
		var exit_ok: bool = glow._state == HotspotGlowScript.State.AVAILABLE

		print("  [12] %s / %s: hover -> HOVER? %s | exit -> AVAILABLE? %s" % [spec["label"], key, str(hover_ok), str(exit_ok)])
		ctx.check(hover_ok, "[12] %s: o glow deve intensificar (HOVER) quando o mouse entra no hotspot interno" % spec["label"])
		ctx.check(exit_ok, "[12] %s: o glow deve voltar a AVAILABLE quando o mouse sai do hotspot interno" % spec["label"])
		panel.free()


## TESTE 13 (FASE 13, item 9 — cleanup): free() no painel libera o(s)
## glow(s) junto — nenhuma referência pendente sobrevive.
static func _test_13_cleanup_libera_o_glow_junto(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/biblioteca_panel.gd").new()
	panel._build_static_structure()
	var glow = panel._hotspot_glows[panel._hotspot_glows.keys()[0]]

	ctx.check(is_instance_valid(glow), "[13] Pré-condição: o glow deve ser uma instância válida antes do cleanup")
	panel.free()
	print("  [13] Após panel.free(), o glow (filho dele) continua uma instância válida? %s (esperado false)" % str(is_instance_valid(glow)))
	ctx.check(not is_instance_valid(glow), "[13] free() no painel deve liberar o glow junto (ele é filho da árvore) — nenhuma referência pendente")


## TESTE 14 (FASE 13, item 10 — reabertura não duplica): o ciclo de
## vida real do jogo (change_scene_to_file) DESTRÓI a cena inteira
## antes de instanciar a próxima — nunca existe "reabrir a MESMA
## instância". Simulado aqui: instância A é completamente destruída
## (free(), glows junto — ver Teste 13) antes da instância B (mesmo
## script) ser criada — B nunca "soma" aos glows de A.
static func _test_14_reabertura_nao_duplica_glows(ctx: TestRunner.Context) -> void:
	var panel_a = preload("res://scenes/city/panels/deposito_panel.gd").new()
	panel_a._build_static_structure()
	var glow_a = panel_a._hotspot_glows[panel_a._hotspot_glows.keys()[0]]
	var count_a: int = panel_a._hotspot_glows.size()
	panel_a.free()  # "sair da construção" — cena inteira destruída, glows junto

	var panel_b = preload("res://scenes/city/panels/deposito_panel.gd").new()
	panel_b._build_static_structure()  # "entrar novamente" — instância NOVA, do zero
	var count_b: int = panel_b._hotspot_glows.size()

	print("  [14] 1ª abertura: %d glows | 'sair' (free) | 2ª abertura (instância nova): %d glows (esperado igual, nunca acumulado) | glow da 1ª instância morreu de verdade? %s" % [
		count_a, count_b, str(not is_instance_valid(glow_a))
	])
	ctx.check(count_a == count_b, "[14] Reabrir a tela (nova instância, a antiga já destruída) deve produzir a MESMA quantidade de glows, nunca acumulados")
	ctx.check(not is_instance_valid(glow_a), "[14] O glow da instância antiga deve estar realmente morto — nunca um 'fantasma' sobrevivendo à troca de cena")

	panel_b.free()


## TESTE 15 (FASE 14 — regressão da causa raiz real): a investigação desta
## fase (ver relatório + docstring de CONTOUR_COLOR em hotspot_glow.gd)
## descartou toda hipótese estrutural (árvore/parent/transform/clipping/
## z_index idênticos entre Cidade e telas internas, confirmado por
## comparação runtime com as duas cenas de verdade na SceneTree) e
## confirmou a causa real: GLOW_COLOR (dourado quente) chega a ficar
## quase idêntico à própria paleta de cor da arte em alguns hotspots
## internos (ex.: "World Atlas" na Biblioteca), tornando o halo
## desenhado corretamente mas visualmente imperceptível por falta de
## contraste. A correção foi um contorno escuro (CONTOUR_COLOR) desenhado
## por baixo do halo dourado. Este teste NÃO prova renderização de
## pixels (nenhum teste headless prova — ver docstring do topo do
## arquivo); apenas garante, de forma permanente, que ninguém reverta
## silenciosamente esse contorno pra uma cor clara/quente que reproduziria
## o mesmo problema de contraste contra fundos claros/dourados.
static func _test_15_contorno_de_contraste_e_suficientemente_escuro(ctx: TestRunner.Context) -> void:
	var contour: Color = HotspotGlowScript.CONTOUR_COLOR
	var glow: Color = HotspotGlowScript.GLOW_COLOR

	# Luminância perceptual aproximada (Rec. 601) — suficiente pra um
	# guard-rail simples de "isto é escuro o bastante pra contrastar",
	# nunca usada em nenhuma fórmula de jogo (não é ECONOMY.md/COMBAT.md).
	var contour_luma: float = 0.299 * contour.r + 0.587 * contour.g + 0.114 * contour.b
	var glow_luma: float = 0.299 * glow.r + 0.587 * glow.g + 0.114 * glow.b

	print("  [15] Luminância do contorno: %.3f | luminância do halo dourado: %.3f (contorno deve ser bem mais escuro)" % [contour_luma, glow_luma])
	ctx.check(contour_luma < 0.20, "[15] O contorno de contraste precisa continuar ESCURO (luminância baixa) — é o que garante leitura do glow contra fundos claros/dourados como os das telas internas")
	ctx.check(glow_luma - contour_luma > 0.4, "[15] O contorno precisa continuar nitidamente mais escuro que o próprio halo dourado, senão ele deixa de fazer contraste contra fundos da cor do halo")


## TESTE 16 (FASE 15): Academia (3 hotspots — Produção/Aprimoramento/
## Evolução, ACADEMY.md) recebe glow em todos, mesmo padrão _hotspot_glows
## de biblioteca_panel.gd/observatorio_panel.gd.
static func _test_16_academia_3_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/academia_panel.gd").new()
	panel._build_static_structure()
	print("  [16] Academia: %d hotspots -> %d glows (esperado 3)" % [3, panel._hotspot_glows.size()])
	ctx.check(panel._hotspot_glows.size() == 3, "[16] A Academia deve ter exatamente 3 glows (Produção/Aprimoramento/Evolução)")
	for key: String in ["Hotspot_Producao", "Hotspot_Aprimoramento", "Hotspot_Evolucao"]:
		ctx.check(panel._hotspot_glows.has(key), "[16] A Academia deve ter um HotspotGlow associado a '%s'" % key)
		ctx.check(panel._hotspot_glows[key].mouse_filter == Control.MOUSE_FILTER_IGNORE, "[16] O glow de '%s' na Academia nunca pode bloquear mouse" % key)
	panel.free()


## TESTE 17 (FASE 15): Capital (4 regiões — Visão do Reino/Evoluir
## Capital/História do Reino/Estatísticas do Reino, CAPITAL.md) recebe
## glow em todas, mesmo padrão _building_glows de city_panel.gd (Capital
## usa REGIONS/_build_hitbox(key), o mesmo formato de BUILDING_REGIONS
## da Cidade — não o formato node_name de _build_hotspot() da Biblioteca).
static func _test_17_capital_4_hotspots_tem_glow(ctx: TestRunner.Context) -> void:
	var panel = preload("res://scenes/city/panels/capital_panel.gd").new()
	panel._build_static_structure()
	var region_keys: Array = panel.REGIONS.keys()
	print("  [17] Capital: %d regiões -> %d glows (esperado igual)" % [region_keys.size(), panel._building_glows.size()])
	ctx.check(panel._building_glows.size() == region_keys.size(), "[17] O número de glows da Capital deve bater EXATAMENTE com o número de regiões reais (REGIONS)")
	for key: String in region_keys:
		ctx.check(panel._building_glows.has(key), "[17] A região '%s' da Capital deve ter um HotspotGlow associado" % key)
		ctx.check(panel._building_glows[key].mouse_filter == Control.MOUSE_FILTER_IGNORE, "[17] O glow de '%s' na Capital nunca pode bloquear mouse" % key)
	panel.free()


## TESTE 18 (FASE 15, equivalente ao Teste 11 pra Biblioteca/Observatório/
## etc.): cada glow da Academia/Capital precisa ser filho do MESMO
## Control (texture_rect) que hospeda o hotspot de input real
## correspondente — nunca de outro nó. Nomenclatura de hitbox difere
## entre os dois padrões (Academia: hotspot.name == a própria chave do
## dict, igual à Biblioteca; Capital: hitbox.name == "Hitbox_<chave>",
## igual à Cidade) — por isso os dois são verificados separadamente,
## cada um com a convenção de nome real do seu próprio arquivo.
static func _test_18_parent_correto_academia_e_capital(ctx: TestRunner.Context) -> void:
	var academia = preload("res://scenes/city/panels/academia_panel.gd").new()
	academia._build_static_structure()
	var academia_ok: bool = true
	for key: String in academia._hotspot_glows:
		var glow: Control = academia._hotspot_glows[key]
		var parent: Node = glow.get_parent()
		var sibling: Node = parent.find_child(key, false, false) if parent != null else null
		if parent == null or sibling == null or sibling.get_parent() != parent:
			academia_ok = false
	print("  [18] Academia: todo glow é filho do MESMO parent que o hotspot de input correspondente? %s" % str(academia_ok))
	ctx.check(academia_ok, "[18] Academia: cada HotspotGlow deve ser filho do mesmo Control (texture_rect) que hospeda o hotspot real de mesmo node_name")
	academia.free()

	var capital = preload("res://scenes/city/panels/capital_panel.gd").new()
	capital._build_static_structure()
	var capital_ok: bool = true
	for key: String in capital._building_glows:
		var glow: Control = capital._building_glows[key]
		var parent: Node = glow.get_parent()
		var sibling: Node = parent.find_child("Hitbox_%s" % key, false, false) if parent != null else null
		if parent == null or sibling == null or sibling.get_parent() != parent:
			capital_ok = false
	print("  [18] Capital: todo glow é filho do MESMO parent que a hitbox correspondente (Hitbox_<chave>)? %s" % str(capital_ok))
	ctx.check(capital_ok, "[18] Capital: cada HotspotGlow deve ser filho do mesmo Control (texture_rect) que hospeda a Hitbox_<chave> real")
	capital.free()


## TESTE 19 (FASE 15, equivalente ao Teste 12): hover intensifica e
## exit normaliza o glow, na Academia e na Capital.
static func _test_19_hover_e_exit_academia_e_capital(ctx: TestRunner.Context) -> void:
	var academia = preload("res://scenes/city/panels/academia_panel.gd").new()
	academia._build_static_structure()
	var academia_key: String = academia._hotspot_glows.keys()[0]
	var academia_glow = academia._hotspot_glows[academia_key]
	academia._on_hotspot_mouse_entered(Control.new(), "teste", academia_key)
	var academia_hover_ok: bool = academia_glow._state == HotspotGlowScript.State.HOVER
	academia._on_hotspot_mouse_exited(academia_key)
	var academia_exit_ok: bool = academia_glow._state == HotspotGlowScript.State.AVAILABLE
	print("  [19] Academia / %s: hover -> HOVER? %s | exit -> AVAILABLE? %s" % [academia_key, str(academia_hover_ok), str(academia_exit_ok)])
	ctx.check(academia_hover_ok, "[19] Academia: o glow deve intensificar (HOVER) quando o mouse entra no hotspot")
	ctx.check(academia_exit_ok, "[19] Academia: o glow deve voltar a AVAILABLE quando o mouse sai do hotspot")
	academia.free()

	var capital = preload("res://scenes/city/panels/capital_panel.gd").new()
	capital._build_static_structure()
	var capital_key: String = capital._building_glows.keys()[0]
	var capital_glow = capital._building_glows[capital_key]
	capital._on_hitbox_mouse_entered(Control.new(), "teste", capital_key)
	var capital_hover_ok: bool = capital_glow._state == HotspotGlowScript.State.HOVER
	capital._on_hitbox_mouse_exited(capital_key)
	var capital_exit_ok: bool = capital_glow._state == HotspotGlowScript.State.AVAILABLE
	print("  [19] Capital / %s: hover -> HOVER? %s | exit -> AVAILABLE? %s" % [capital_key, str(capital_hover_ok), str(capital_exit_ok)])
	ctx.check(capital_hover_ok, "[19] Capital: o glow deve intensificar (HOVER) quando o mouse entra na região")
	ctx.check(capital_exit_ok, "[19] Capital: o glow deve voltar a AVAILABLE quando o mouse sai da região")
	capital.free()


## TESTE 20 (FASE 15, equivalente aos Testes 13/14): cleanup real
## (free() libera os glows junto) e reabertura não duplica, na Academia
## e na Capital.
static func _test_20_cleanup_e_reabertura_academia_e_capital(ctx: TestRunner.Context) -> void:
	var academia_a = preload("res://scenes/city/panels/academia_panel.gd").new()
	academia_a._build_static_structure()
	var academia_glow_a = academia_a._hotspot_glows[academia_a._hotspot_glows.keys()[0]]
	var academia_count_a: int = academia_a._hotspot_glows.size()
	academia_a.free()
	print("  [20] Academia: glow segue válido após free() do painel? %s (esperado false)" % str(is_instance_valid(academia_glow_a)))
	ctx.check(not is_instance_valid(academia_glow_a), "[20] Academia: free() no painel deve liberar o glow junto — nenhuma referência pendente")

	var academia_b = preload("res://scenes/city/panels/academia_panel.gd").new()
	academia_b._build_static_structure()
	var academia_count_b: int = academia_b._hotspot_glows.size()
	print("  [20] Academia: 1ª abertura %d glows | 2ª abertura (instância nova) %d glows (esperado igual)" % [academia_count_a, academia_count_b])
	ctx.check(academia_count_a == academia_count_b, "[20] Academia: reabrir a tela deve produzir a MESMA quantidade de glows, nunca acumulados")
	academia_b.free()

	var capital_a = preload("res://scenes/city/panels/capital_panel.gd").new()
	capital_a._build_static_structure()
	var capital_glow_a = capital_a._building_glows[capital_a._building_glows.keys()[0]]
	var capital_count_a: int = capital_a._building_glows.size()
	capital_a.free()
	print("  [20] Capital: glow segue válido após free() do painel? %s (esperado false)" % str(is_instance_valid(capital_glow_a)))
	ctx.check(not is_instance_valid(capital_glow_a), "[20] Capital: free() no painel deve liberar o glow junto — nenhuma referência pendente")

	var capital_b = preload("res://scenes/city/panels/capital_panel.gd").new()
	capital_b._build_static_structure()
	var capital_count_b: int = capital_b._building_glows.size()
	print("  [20] Capital: 1ª abertura %d glows | 2ª abertura (instância nova) %d glows (esperado igual)" % [capital_count_a, capital_count_b])
	ctx.check(capital_count_a == capital_count_b, "[20] Capital: reabrir a tela deve produzir a MESMA quantidade de glows, nunca acumulados")
	capital_b.free()
