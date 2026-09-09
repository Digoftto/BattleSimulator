class_name TestMinasPanelUi
extends RefCounted
## TestMinasPanelUi (FASE 17/18/19)
##
## Cobre a reestruturação funcional (Fase 17: Minas Principais x Minas
## Regionais Conquistadas, registro administrativo sem arte, botão "Ir
## para Mina" preparado mas desabilitado), a reformulação visual
## (Fase 18: nenhum dado/regra mudou, só apresentação) e o acabamento da
## Fase 19 (correção da causa raiz do bug "Ferro Negro preto" —
## TextureRect.expand_mode — e o modal de detalhe da Mina Principal) de
## minas_panel.gd. Nenhum teste aqui prova renderização de pixels (mesma
## ressalva de sempre, ver test_city_hotspot_glow.gd) — só
## estrutura/estado real da árvore e as propriedades de configuração que
## efetivamente causaram/corrigem o bug (expand_mode, textura carregada).
##
## Instanciação: preload(caminho).new() + chamada direta de
## _build_static_structure()/refresh() (nunca _ready(), que depende de
## KingdomState.is_initialized já estar resolvido pelo chamador) — mesmo
## padrão já usado por test_city_hotspot_glow.gd. O clique no card
## Principal (Fase 19) é simulado chamando
## panel._on_principal_card_gui_input(event, mina) diretamente com um
## InputEventMouseButton real — os testes existentes já nunca simulam a
## cadeia de sinais do Godot (gui_input/CONNECT_DEFERRED só é
## verdadeiramente assíncrona dentro de uma SceneTree rodando, que não é
## o caso aqui), só a lógica do próprio handler.

const MinasPanelScript = preload("res://scenes/command_center/panels/minas_panel.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[FASE 17/18] Validando o painel de Minas (Principais + Regionais Conquistadas)...")
	_test_1_tres_minas_principais_aparecem(ctx)
	_test_2_arte_real_de_cada_mina_principal(ctx)
	_test_3_dados_reais_exibidos_na_mina_principal(ctx)
	_test_4_mina_regional_nao_conquistada_nao_aparece(ctx)
	_test_5_mina_regional_conquistada_aparece(ctx)
	_test_6_mina_regional_nunca_tem_arte(ctx)
	_test_7_refresh_nunca_gera_minas_regionais(ctx)
	_test_8_botao_ir_para_mina_existe_e_desabilitado(ctx)
	_test_9_callback_ir_para_mina_usa_territory_id_e_mina(ctx)
	_test_10_reabrir_nao_duplica_cards(ctx)
	_test_11_estado_vazio_some_quando_ha_conquistada(ctx)
	_test_12_regional_aparece_automaticamente_apos_conquista(ctx)
	print("[FASE 19] Validando a correção da Mina de Ferro Negro e o modal de detalhe...")
	_test_13_expand_mode_corrige_as_3_artes(ctx)
	_test_14_clique_em_cada_mina_principal_abre_o_modal_correto(ctx)
	_test_15_modal_mostra_nome_e_asset_reais(ctx)
	_test_16_modal_mostra_producao_real_sem_segunda_fonte(ctx)
	_test_17_fechar_modal_nao_altera_a_mina(ctx)
	_test_18_abrir_fechar_repetidamente_nao_duplica_janelas(ctx)
	_test_19_regional_nao_ganha_modal(ctx)
	print("[F-021.3.1] Validando a seção 'Evoluir' também em Minas Regionais...")
	_test_20_regional_tem_secao_evoluir(ctx)
	_test_21_evoluir_regional_gasta_pg_e_incrementa_nivel(ctx)
	_test_22_evoluir_regional_nunca_mostra_nivel_maximo(ctx)
	return true


static func _new_kingdom_with_no_regional_mines() -> Kingdom:
	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	return kingdom


static func _new_panel(kingdom: Kingdom) -> Control:
	var panel = MinasPanelScript.new()
	KingdomState.kingdom = kingdom
	panel._build_static_structure()
	panel.refresh()
	return panel


## TESTE 1: as 3 Minas Básicas (kingdom.initial_mines) sempre aparecem
## como card em MINAS PRINCIPAIS — nenhuma a mais, nenhuma a menos
## (DL_MINES.md: "existe apenas uma de cada Fundamento").
static func _test_1_tres_minas_principais_aparecem(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	print("  [1] Cards em Minas Principais: %d (esperado 3)" % panel._principais_grid.get_child_count())
	ctx.check(panel._principais_grid.get_child_count() == 3, "[1] Devem existir exatamente 3 cards de Minas Principais")
	panel.free()


## TESTE 2 (item 2/3 do pedido): cada card de Mina Principal usa
## exatamente a textura real de MineArtCatalog.texture_for(mina) — nunca
## nula, nunca genérica.
static func _test_2_arte_real_de_cada_mina_principal(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	var all_correct := true
	for i in range(panel._principais_grid.get_child_count()):
		var card: Control = panel._principais_grid.get_child(i)
		var mina: Mina = kingdom.initial_mines[i]
		var expected_texture: Texture2D = preload("res://engine/presentation/mine_art_catalog.gd").texture_for(mina)
		var texture_rect: TextureRect = _find_first_texture_rect(card)
		if texture_rect == null or texture_rect.texture != expected_texture:
			all_correct = false

	print("  [2] Toda Mina Principal usa a textura real de MineArtCatalog? %s" % str(all_correct))
	ctx.check(all_correct, "[2] Cada card de Mina Principal deve usar exatamente MineArtCatalog.texture_for(mina), nunca uma imagem genérica")
	panel.free()


## TESTE 3: os dados reais (nível estrutural, nome real da Mina) batem
## com o objeto Mina — nenhum valor inventado.
static func _test_3_dados_reais_exibidos_na_mina_principal(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina: Mina = kingdom.initial_mines[0]
	mina.structure_level = 3
	var panel := _new_panel(kingdom)

	var card: Control = panel._principais_grid.get_child(0)
	var expected_name: String = MinasPanelScript.INITIAL_MINE_NAMES[mina.faction]
	var has_name: bool = _panel_contains_text(card, expected_name)
	var has_level: bool = _panel_contains_text(card, "3")

	print("  [3] Card mostra o nome real ('%s')? %s | nível estrutural real (3)? %s" % [expected_name, str(has_name), str(has_level)])
	ctx.check(has_name, "[3] O card deve mostrar o nome real da Mina (INITIAL_MINE_NAMES, DL_MINES.md)")
	ctx.check(has_level, "[3] O card deve mostrar o nível estrutural real do objeto Mina")
	panel.free()


## TESTE 4 (item 5): uma Mina Regional gerada mas NÃO conquistada nunca
## aparece no registro — nunca mostrar Fases futuras/não conquistadas.
static func _test_4_mina_regional_nao_conquistada_nao_aparece(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina_nao_conquistada := Mina.new(1500, "Império")
	mina_nao_conquistada.region = 1
	var mines: Array[Mina] = [mina_nao_conquistada]
	kingdom.territory_mines["territorio-teste-nao-conquistada"] = mines

	var panel := _new_panel(kingdom)
	var shows_empty_state: bool = _panel_contains_text(panel._regionais_container, "Nenhuma Mina Regional conquistada")

	print("  [4] Mina Regional NÃO conquistada -> registro fica vazio (estado vazio aparece)? %s" % str(shows_empty_state))
	ctx.check(shows_empty_state, "[4] Uma Mina Regional gerada mas não conquistada nunca deve aparecer como registro — a seção deve mostrar o estado vazio")
	panel.free()


## TESTE 5 (item 6): uma Mina Regional CONQUISTADA aparece no registro,
## com dados reais (Região/Fase/Recurso).
static func _test_5_mina_regional_conquistada_aparece(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(4500, "Natureza")
	mina.conquer()
	mina.region = 2
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-conquistada"] = mines

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)

	print("  [5] Registros em Minas Regionais Conquistadas: %d (esperado 1)" % panel._regionais_container.get_child_count())
	ctx.check(panel._regionais_container.get_child_count() == 1, "[5] Deve existir exatamente 1 registro Regional (1 Mina Regional conquistada)")
	ctx.check(_panel_contains_text(card, "4500"), "[5] O registro deve mostrar a Fase real da Mina (4500)")
	ctx.check(_panel_contains_text(card, "2"), "[5] O registro deve mostrar a Região real da Mina (2)")
	panel.free()


## TESTE 6 (item 7 — decisão explícita da Fase 17/18): NENHUM registro
## Regional pode conter um TextureRect com textura carregada — a arte da
## Mina Regional pertence ao local físico dela no World Map, nunca é
## duplicada na Cidade.
static func _test_6_mina_regional_nunca_tem_arte(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(2200, "Mortos-Vivos")
	mina.conquer()
	mina.region = 1
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-sem-arte"] = mines

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var loaded_textures: int = _count_loaded_textures(card)

	print("  [6] Registro Regional possui alguma textura carregada? %d (esperado 0)" % loaded_textures)
	ctx.check(loaded_textures == 0, "[6] Um registro de Mina Regional nunca deve exibir arte (nem miniatura, nem placeholder) dentro da Cidade")
	panel.free()


## TESTE 7 (item 8): abrir/atualizar a tela NUNCA chama
## Kingdom.generate_territory_mines() nem cria Minas Regionais como
## efeito colateral — kingdom.territory_mines deve permanecer
## EXATAMENTE como estava antes do refresh().
static func _test_7_refresh_nunca_gera_minas_regionais(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var keys_before: Array = kingdom.territory_mines.keys().duplicate()

	var panel := _new_panel(kingdom)
	panel.refresh()  # 2ª chamada de propósito — nem a primeira nem a segunda podem gerar Mina.

	var keys_after: Array = kingdom.territory_mines.keys()
	print("  [7] kingdom.territory_mines antes: %s | depois de 2 refresh(): %s (esperado idêntico)" % [str(keys_before), str(keys_after)])
	ctx.check(keys_before.size() == 0 and keys_after.size() == 0, "[7] refresh() nunca deve popular kingdom.territory_mines — nenhuma Mina Regional pode ser gerada como efeito colateral de abrir a tela")
	panel.free()


## TESTE 8 (itens 9/10): o botão "Ir para Mina" existe em todo registro
## Regional e permanece desabilitado (nenhum destino real ainda).
static func _test_8_botao_ir_para_mina_existe_e_desabilitado(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(3300, "Império")
	mina.conquer()
	mina.region = 3
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-botao"] = mines

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var button: Button = _find_button_by_text(card, "Ir para Mina")

	print("  [8] Botão 'Ir para Mina' existe? %s | está desabilitado? %s (esperado true, true)" % [str(button != null), str(button != null and button.disabled)])
	ctx.check(button != null, "[8] Todo registro de Mina Regional deve ter o botão 'Ir para Mina' na estrutura")
	ctx.check(button != null and button.disabled, "[8] O botão deve permanecer desabilitado — nenhum destino de navegação real existe ainda")
	panel.free()


## TESTE 9 (item 11): o callback conectado ao botão usa exatamente
## (territory_id, mina) como argumentos vinculados — nunca o nome
## textual da Mina como identificador.
static func _test_9_callback_ir_para_mina_usa_territory_id_e_mina(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(5100, "Natureza")
	mina.conquer()
	mina.region = 1
	var mines: Array[Mina] = [mina]
	var territory_id := "territorio-teste-callback"
	kingdom.territory_mines[territory_id] = mines

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var button: Button = _find_button_by_text(card, "Ir para Mina")

	var connections: Array = button.get_signal_connection_list("pressed")
	var bound_correctly := false
	for connection: Dictionary in connections:
		var callable: Callable = connection["callable"]
		var bound_args: Array = callable.get_bound_arguments()
		if bound_args.size() == 2 and bound_args[0] == territory_id and bound_args[1] == mina:
			bound_correctly = true

	print("  [9] Callback de 'Ir para Mina' vinculado a (territory_id, mina)? %s" % str(bound_correctly))
	ctx.check(bound_correctly, "[9] O botão deve estar conectado a _on_ir_para_mina_pressed com (territory_id, mina) — nunca o nome textual da Mina")
	panel.free()


## TESTE 10 (item 12): reabrir a tela (nova instância, a antiga já
## destruída — mesmo ciclo de vida real do jogo, change_scene_to_file())
## produz a MESMA quantidade de cards, nunca acumulados.
static func _test_10_reabrir_nao_duplica_cards(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(6600, "Mortos-Vivos")
	mina.conquer()
	mina.region = 2
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-reabertura"] = mines

	var panel_a := _new_panel(kingdom)
	var count_principais_a: int = panel_a._principais_grid.get_child_count()
	var count_regionais_a: int = panel_a._regionais_container.get_child_count()
	panel_a.free()

	var panel_b := _new_panel(kingdom)
	var count_principais_b: int = panel_b._principais_grid.get_child_count()
	var count_regionais_b: int = panel_b._regionais_container.get_child_count()

	print("  [10] 1ª abertura: %d principais / %d regionais | 2ª abertura: %d principais / %d regionais (esperado igual)" % [
		count_principais_a, count_regionais_a, count_principais_b, count_regionais_b
	])
	ctx.check(count_principais_a == count_principais_b, "[10] Reabrir a tela não deve duplicar os cards de Minas Principais")
	ctx.check(count_regionais_a == count_regionais_b, "[10] Reabrir a tela não deve duplicar os registros de Minas Regionais")
	panel_b.free()


## TESTE 11 (item 13): o estado vazio aparece SOMENTE quando não há
## Mina Regional conquistada — some assim que existe pelo menos uma.
static func _test_11_estado_vazio_some_quando_ha_conquistada(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)
	var empty_before: bool = _panel_contains_text(panel._regionais_container, "Nenhuma Mina Regional conquistada")
	print("  [11] Sem nenhuma Mina Regional -> estado vazio aparece? %s" % str(empty_before))
	ctx.check(empty_before, "[11] Sem nenhuma Mina Regional conquistada, o estado vazio deve aparecer")

	var mina := Mina.new(7700, "Império")
	mina.conquer()
	mina.region = 3
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-vazio-some"] = mines
	panel.refresh()

	var empty_after: bool = _panel_contains_text(panel._regionais_container, "Nenhuma Mina Regional conquistada")
	print("  [11] Após conquistar uma Mina Regional -> estado vazio some? %s (esperado false)" % str(empty_after))
	ctx.check(not empty_after, "[11] Assim que existe uma Mina Regional conquistada, o estado vazio deve desaparecer")
	panel.free()


## TESTE 12 (item 14): o registro Regional aparece AUTOMATICAMENTE
## conforme kingdom.territory_mines muda — sem precisar reconstruir a
## tela manualmente (só chamar refresh(), o mesmo já disparado por toda
## ação real do painel).
static func _test_12_regional_aparece_automaticamente_apos_conquista(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(8800, "Natureza")
	mina.region = 2
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-auto"] = mines

	var panel := _new_panel(kingdom)
	var count_before: int = panel._regionais_container.get_child_count()

	mina.conquer()
	panel.refresh()
	var count_after: int = panel._regionais_container.get_child_count()

	print("  [12] Registros Regionais antes da conquista: %d (estado vazio) | depois: %d (esperado 1)" % [count_before, count_after])
	ctx.check(count_after == 1, "[12] Assim que mina.conquered vira true, o próximo refresh() deve mostrar o registro automaticamente")
	panel.free()


## TESTE 13 (causa raiz do bug "Ferro Negro preto" — FASE 19): a
## TextureRect de CADA Mina Principal (incluindo Ferro Negro, que tem
## canal alpha real) usa expand_mode = EXPAND_IGNORE_SIZE — sem isso,
## Godot trava o tamanho mínimo do Control no tamanho NATIVO da textura
## e STRETCH_KEEP_ASPECT_COVERED nunca chega a rodar de verdade (só o
## canto superior esquerdo da imagem fica visível, que em Ferro Negro
## calha de ser uma região transparente). Guarda de regressão direta
## contra a causa raiz diagnosticada.
static func _test_13_expand_mode_corrige_as_3_artes(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	var all_correct := true
	var all_have_texture := true
	for i in range(panel._principais_grid.get_child_count()):
		var card: Control = panel._principais_grid.get_child(i)
		var texture_rect: TextureRect = _find_first_texture_rect(card)
		if texture_rect == null or texture_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
			all_correct = false
		if texture_rect == null or texture_rect.texture == null:
			all_have_texture = false

	print("  [13] As 3 artes de Minas Principais usam expand_mode = EXPAND_IGNORE_SIZE? %s | todas com textura carregada? %s" % [str(all_correct), str(all_have_texture)])
	ctx.check(all_correct, "[13] Toda TextureRect de Mina Principal (Ferro Negro incluído) deve usar expand_mode = EXPAND_IGNORE_SIZE — sem isso, o Control trava no tamanho nativo da textura e o corte real de STRETCH_KEEP_ASPECT_COVERED nunca acontece")
	ctx.check(all_have_texture, "[13] A correção não pode deixar nenhuma das 3 Minas Principais sem textura carregada")
	panel.free()


## TESTE 14 (itens 1/2/3 do pedido de modal): clicar em cada uma das 3
## Minas Principais abre o modal da Mina CORRETA — nunca o de outra.
static func _test_14_clique_em_cada_mina_principal_abre_o_modal_correto(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	for mina: Mina in kingdom.initial_mines:
		_click_principal_card(panel, mina)
		var opened_correct: bool = panel._mina_detail == mina and panel._mina_detail_overlay != null
		print("  [14] Clique em '%s' abre o modal dessa própria Mina? %s" % [mina.faction, str(opened_correct)])
		ctx.check(opened_correct, "[14] Clicar no card de '%s' deve abrir o modal exatamente dessa Mina" % mina.faction)
		panel._on_mina_detail_close_pressed()

	panel.free()


## TESTE 15 (itens 4/5): o nome exibido no modal é o nome real da Mina
## clicada, e o asset exibido é EXATAMENTE MineArtCatalog.texture_for(mina)
## (mesma textura, não só "não nula") — testado nas 3, Ferro Negro
## incluído (é o caso com transparência real).
static func _test_15_modal_mostra_nome_e_asset_reais(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	for mina: Mina in kingdom.initial_mines:
		_click_principal_card(panel, mina)
		var expected_name: String = MinasPanelScript.INITIAL_MINE_NAMES[mina.faction]
		var expected_texture: Texture2D = preload("res://engine/presentation/mine_art_catalog.gd").texture_for(mina)
		var has_name: bool = _panel_contains_text(panel._mina_detail_overlay, expected_name.to_upper())
		var modal_texture_rect: TextureRect = _find_first_texture_rect(panel._mina_detail_overlay)
		var texture_matches: bool = modal_texture_rect != null and modal_texture_rect.texture == expected_texture

		print("  [15] Modal de '%s' mostra o nome real ('%s')? %s | asset é exatamente MineArtCatalog.texture_for()? %s" % [mina.faction, expected_name, str(has_name), str(texture_matches)])
		ctx.check(has_name, "[15] O modal de '%s' deve mostrar o nome real da Mina" % mina.faction)
		ctx.check(texture_matches, "[15] O modal de '%s' deve mostrar exatamente a textura de MineArtCatalog.texture_for(mina), nunca outra" % mina.faction)

	panel._on_mina_detail_close_pressed()
	panel.free()


## TESTE 16 (itens 6/10): a Produção exibida no modal bate com o cálculo
## REAL de MineEconomy — nunca uma segunda fórmula/fonte de dados.
static func _test_16_modal_mostra_producao_real_sem_segunda_fonte(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)

	for mina: Mina in kingdom.initial_mines:
		_click_principal_card(panel, mina)
		var expected_text: String = "%d de %s por hora" % [
			MineEconomy.base_production_for_mina(mina), MineEconomy.resource_for_faction(mina.faction)
		]
		var shows_real_production: bool = _panel_contains_text(panel._mina_detail_overlay, expected_text)
		print("  [16] Modal de '%s' mostra a Produção real ('%s')? %s" % [mina.faction, expected_text, str(shows_real_production)])
		ctx.check(shows_real_production, "[16] O modal de '%s' deve mostrar exatamente o texto de Produção calculado por MineEconomy — nunca uma segunda fonte/fórmula" % mina.faction)

	panel._on_mina_detail_close_pressed()
	panel.free()


## TESTE 17 (itens 7/8): o modal pode ser fechado, e fechar não altera
## em nada o estado real da Mina (structure_level, ciclo, conquered).
static func _test_17_fechar_modal_nao_altera_a_mina(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina: Mina = kingdom.initial_mines[0]
	var panel := _new_panel(kingdom)

	var structure_before: int = mina.structure_level
	var conquered_before: bool = mina.conquered
	var cycle_active_before: bool = mina.is_cycle_active(GameClock.now_unix())

	_click_principal_card(panel, mina)
	var opened: bool = panel._mina_detail == mina
	panel._on_mina_detail_close_pressed()
	var closed: bool = panel._mina_detail == null and panel._mina_detail_overlay == null

	var structure_after: int = mina.structure_level
	var conquered_after: bool = mina.conquered
	var cycle_active_after: bool = mina.is_cycle_active(GameClock.now_unix())

	print("  [17] Modal abriu (%s) e fechou (%s)? | Mina antes/depois: nível %d/%d, conquistada %s/%s, ciclo ativo %s/%s" % [
		str(opened), str(closed), structure_before, structure_after, str(conquered_before), str(conquered_after), str(cycle_active_before), str(cycle_active_after)
	])
	ctx.check(opened, "[17] O modal deve abrir antes de testar o fechamento")
	ctx.check(closed, "[17] 'Fechar' deve remover o modal da árvore e zerar o estado de detalhe aberto")
	ctx.check(structure_before == structure_after, "[17] Fechar o modal não pode alterar o nível estrutural da Mina")
	ctx.check(conquered_before == conquered_after, "[17] Fechar o modal não pode alterar se a Mina está conquistada")
	ctx.check(cycle_active_before == cycle_active_after, "[17] Fechar o modal não pode ativar/alterar o Ciclo da Mina")
	panel.free()


## TESTE 18 (item 9): abrir/fechar repetidamente (inclusive trocando de
## Mina) nunca acumula mais de 1 overlay de modal na árvore.
static func _test_18_abrir_fechar_repetidamente_nao_duplica_janelas(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var panel := _new_panel(kingdom)
	var baseline_children: int = panel.get_child_count()

	var all_correct := true
	for i in range(3):
		for mina: Mina in kingdom.initial_mines:
			_click_principal_card(panel, mina)
			if panel.get_child_count() != baseline_children + 1:
				all_correct = false
			panel._on_mina_detail_close_pressed()
			if panel.get_child_count() != baseline_children:
				all_correct = false

	print("  [18] Abrir/fechar repetidamente (3 rodadas x 3 Minas) nunca deixou mais de 1 overlay? %s" % str(all_correct))
	ctx.check(all_correct, "[18] Abrir/fechar o modal repetidamente (inclusive trocando de Mina) nunca deve acumular mais de 1 overlay na árvore do painel")
	panel.free()


## TESTE 19: Minas Regionais NUNCA ganham o clique/modal desta fase —
## nenhum card Regional tem gui_input conectado (a Fase 19 só toca Minas
## Principais).
static func _test_19_regional_nao_ganha_modal(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(9900, "Império")
	mina.conquer()
	mina.region = 1
	var mines: Array[Mina] = [mina]
	kingdom.territory_mines["territorio-teste-sem-modal"] = mines

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var connections: Array = card.get_signal_connection_list("gui_input")

	print("  [19] Card Regional tem alguma conexão de gui_input (candidata a abrir modal)? %d (esperado 0)" % connections.size())
	ctx.check(connections.is_empty(), "[19] Um registro de Mina Regional nunca deve ganhar o clique/modal desta fase — só Minas Principais")
	panel.free()


## TESTE 20 (F-021.3.1): o registro de uma Mina Regional conquistada
## agora também desenha a seção "Evoluir" (antes exclusiva das Minas
## Principais) — mesmo botão/texto, reaproveitando _build_evoluir_section().
static func _test_20_regional_tem_secao_evoluir(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(3000, "Mortos-Vivos")
	mina.conquer()
	mina.region = 3
	mina.structure_level = 1
	kingdom.territory_mines["territorio-teste-evoluir"] = [mina]

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var evoluir_button: Button = _find_button_by_text(card, "Evoluir")

	print("  [20] Registro Regional tem botão 'Evoluir'? %s" % str(evoluir_button != null))
	ctx.check(evoluir_button != null, "[20] Uma Mina Regional conquistada deve ter o botão 'Evoluir', igual à Mina Inicial")
	ctx.check(_panel_contains_text(card, "PG"), "[20] O registro Regional deve mostrar o custo real em PG para evoluir")
	panel.free()


## TESTE 21 (F-021.3.1, achado P1 corrigido): clicar em "Evoluir" numa
## Mina Regional real deve gastar o PG real (MineEconomy.upgrade_cost_pg
## com a Região correta) e incrementar o Nível Estrutural — nunca mais
## a rejeição "not_initial_mine" que existia antes desta fase.
static func _test_21_evoluir_regional_gasta_pg_e_incrementa_nivel(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(3000, "Império")
	mina.conquer()
	mina.region = 1
	mina.structure_level = 1
	kingdom.territory_mines["territorio-teste-evoluir-2"] = [mina]
	kingdom.generation_points = MineEconomy.upgrade_cost_pg(MineEconomy.Region.REGIAO_1, 2)

	var panel := _new_panel(kingdom)
	panel._on_evoluir_mina_pressed(mina)

	print("  [21] Após clicar 'Evoluir' numa Mina Regional: nível %d (esperado 2), PG restante %d (esperado 0)" % [
		mina.structure_level, kingdom.generation_points
	])
	ctx.check(mina.structure_level == 2, "[21] O Nível Estrutural da Mina Regional deve incrementar ao clicar 'Evoluir'")
	ctx.check(kingdom.generation_points == 0, "[21] O PG real deve ser gasto (nenhuma segunda fórmula de custo)")
	panel.free()


## TESTE 22 (F-021.3.1): diferente da Mina Inicial (teto Nível 4), uma
## Mina Regional NUNCA deve mostrar "Nível Estrutural máximo atingido"
## — nenhum teto documentado em MINES.md/FORMULAS.md para Regionais.
static func _test_22_evoluir_regional_nunca_mostra_nivel_maximo(ctx: TestRunner.Context) -> void:
	var kingdom := _new_kingdom_with_no_regional_mines()
	var mina := Mina.new(3000, "Natureza")
	mina.conquer()
	mina.region = 2
	mina.structure_level = 50  # bem além do teto de 4 da Mina Inicial
	kingdom.territory_mines["territorio-teste-sem-teto"] = [mina]

	var panel := _new_panel(kingdom)
	var card: Control = panel._regionais_container.get_child(0)
	var evoluir_button: Button = _find_button_by_text(card, "Evoluir")

	print("  [22] Mina Regional Nível 50: botão 'Evoluir' habilitado? %s | mostra 'máximo atingido'? %s (esperado: true, false)" % [
		str(evoluir_button != null and not evoluir_button.disabled), str(_panel_contains_text(card, "máximo atingido"))
	])
	ctx.check(evoluir_button != null and not evoluir_button.disabled, "[22] O botão 'Evoluir' de uma Mina Regional nunca deve ficar desabilitado por teto de Nível")
	ctx.check(not _panel_contains_text(card, "máximo atingido"), "[22] Uma Mina Regional nunca deve exibir 'Nível Estrutural máximo atingido' — teto é exclusivo da Mina Inicial")
	panel.free()


static func _click_principal_card(panel: Control, mina: Mina) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	panel._on_principal_card_gui_input(event, mina)


static func _panel_contains_text(node: Node, text: String) -> bool:
	if node is Label and text in (node as Label).text:
		return true
	if node is Button and text in (node as Button).text:
		return true
	for child in node.get_children():
		if _panel_contains_text(child, text):
			return true
	return false


static func _find_first_texture_rect(node: Node) -> TextureRect:
	if node is TextureRect:
		return node
	for child in node.get_children():
		var found: TextureRect = _find_first_texture_rect(child)
		if found != null:
			return found
	return null


static func _count_loaded_textures(node: Node) -> int:
	var count := 0
	if node is TextureRect and (node as TextureRect).texture != null:
		count += 1
	for child in node.get_children():
		count += _count_loaded_textures(child)
	return count


static func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button_by_text(child, text)
		if found != null:
			return found
	return null
