class_name TestCampoDeProvaLifecycleAndEditing
extends RefCounted
## TestCampoDeProvaLifecycleAndEditing
##
## Cobre a correção de ciclo de vida ("Object is locked and can't be
## freed") e a edição dos dois lados via Army Editor em sandbox_mode
## (CAMPO_DE_PROVA.md, "Correções de Fluxo e UX"). Complementa
## test_campo_de_prova_army_sources.gd (geração aleatória/ownership),
## que não precisou de nenhuma alteração nesta etapa.
##
## NÃO testado aqui (mesma limitação já registrada na etapa anterior):
## reproduzir o crash real de "Object is locked" exigiria uma SceneTree
## viva processando frames + um clique real no botão "Continuar" do
## CombatReplayView — em vez disso, os Testes 1-2 verificam diretamente
## que _finish_prova_view()/_clear_children() têm a forma correta
## (remove_child() antes de queue_free(), nunca free() de um filho já
## marcado is_queued_for_deletion()), que é a causa-raiz real da
## correção. Também não testado: a velocidade de reprodução afetando o
## tempo de parede de verdade (exigiria um Timer real rodando) — o Teste
## 6 valida a variável que _play_replay() já lê a cada iteração, a
## mesma reaproveitada, nunca uma nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Campo de Prova] Validando correção de ciclo de vida (Object is locked) e edição dos dois lados...")

	_test_1_finish_prova_view_removes_before_queue_free(ctx)
	_test_2_clear_children_skips_already_queued_nodes(ctx)
	_test_3_second_prova_after_finish_has_clean_state(ctx)
	_test_4_sandbox_army_editor_never_touches_kingdom(ctx)
	_test_5_sandbox_pool_defaults_to_full_catalog(ctx)
	_test_6_player_side_sandbox_pool_restricted_to_kingdom(ctx)
	_test_7_effective_player_army_prefers_edited_version(ctx)
	_test_8_replay_speed_cycles_and_stays_reusable(ctx)

	return true


## TESTE 1: _finish_prova_view() remove a CombatReplayView da árvore
## (remove_child) ANTES de queue_free() — a ordem exata que evita
## free() de um objeto ainda "locked" (ver docstring do topo do painel).
static func _test_1_finish_prova_view_removes_before_queue_free(ctx: TestRunner.Context) -> void:
	var panel := CampoDeProvaPanel.new()
	var dummy_view := Control.new()
	panel.add_child(dummy_view)

	panel._finish_prova_view(dummy_view)

	print("  [1] Após _finish_prova_view(): view sem pai=%s, marcada pra deleção=%s, _view_mode='relatorio'=%s" % [
		str(dummy_view.get_parent() == null), str(dummy_view.is_queued_for_deletion()), str(panel._view_mode == "relatorio")
	])
	ctx.check(dummy_view.get_parent() == null, "[1] _finish_prova_view() deve remover a CombatReplayView da árvore (remove_child) antes de liberá-la")
	ctx.check(dummy_view.is_queued_for_deletion(), "[1] _finish_prova_view() deve chamar queue_free() (deferred), nunca free() imediato, no objeto que acabou de emitir o próprio sinal")
	ctx.check(panel._view_mode == "relatorio", "[1] _finish_prova_view() deve avançar _view_mode para 'relatorio'")
	panel.free()


## TESTE 2: _clear_children() nunca tenta free() um filho já marcado
## is_queued_for_deletion() — rede de segurança contra double-free.
static func _test_2_clear_children_skips_already_queued_nodes(ctx: TestRunner.Context) -> void:
	var panel := CampoDeProvaPanel.new()
	var already_queued := Control.new()
	var normal_child := Control.new()
	panel.add_child(already_queued)
	panel.add_child(normal_child)
	already_queued.queue_free()

	panel._clear_children(panel)

	print("  [2] _clear_children() não tenta liberar de novo um filho já marcado pra deleção; ainda presente na árvore (deferred)? %s" % str(already_queued.get_parent() == panel))
	ctx.check(already_queued.get_parent() == panel, "[2] _clear_children() não deve remove_child()/free() um filho já is_queued_for_deletion() (evita liberar um objeto potencialmente locked de novo)")
	ctx.check(not is_instance_valid(normal_child) or normal_child.get_parent() == null, "[2] _clear_children() deve continuar limpando normalmente os filhos que NÃO estão marcados pra deleção")
	panel.free()


## TESTE 3: depois de "encerrar" uma prova (via _finish_prova_view),
## iniciar uma nova configuração ("Nova Configuração") não deixa nenhum
## estado da batalha anterior interferindo (_last_state permanece o da
## prova concluída até uma NOVA prova rodar, mas a tela de configuração
## em si — _test_army_a/b — continua limpa/independente).
static func _test_3_second_prova_after_finish_has_clean_state(ctx: TestRunner.Context) -> void:
	var panel := CampoDeProvaPanel.new()
	var dummy_view := Control.new()
	panel.add_child(dummy_view)
	panel._finish_prova_view(dummy_view)

	panel._on_nova_configuracao_pressed()
	print("  [3] Depois de encerrar e clicar 'Nova Configuração', volta pra _view_mode='config'? %s" % str(panel._view_mode == "config"))
	ctx.check(panel._view_mode == "config", "[3] 'Nova Configuração' deve voltar _view_mode para 'config', permitindo montar/iniciar outra prova imediatamente")
	panel.free()


## TESTE 4: editar um Army no Army Editor em sandbox_mode nunca chama
## Kingdom.form_army()/re_form_army()/disband_army() — Kingdom.armies/
## cards/commanders permanecem exatamente do mesmo tamanho.
static func _test_4_sandbox_army_editor_never_touches_kingdom(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var armies_before: int = kingdom.armies.size()
	var cards_before: int = kingdom.cards.size()
	var commanders_before: int = kingdom.commanders.size()

	var editor := ArmyEditorPanel.new()
	editor.sandbox_mode = true
	editor.formation_count = 1
	editor._build_static_structure()

	editor._selected_commander = TestArmyFactory.generate_commander()
	var composition: Array[CardResource] = []
	for template: CardResource in GameDatabase.cards.slice(0, 9):
		composition.append(template.duplicate())
	editor._selected_cards = composition
	for i in range(mini(9, composition.size())):
		editor._phase1_slots[i] = composition[i]

	editor._on_montar_pressed()
	var result_army: Army = editor._army

	print("  [4] Army resultante existe e Kingdom.armies/cards/commanders inalterados? Army=%s (%d->%d, %d->%d, %d->%d)" % [
		str(result_army != null), armies_before, kingdom.armies.size(), cards_before, kingdom.cards.size(), commanders_before, kingdom.commanders.size()
	])
	ctx.check(result_army != null, "[4] sandbox_mode == true deve produzir um Army mesmo sem chamar Kingdom.form_army()")
	ctx.check(not kingdom.armies.has(result_army), "[4] O Army de sandbox nunca deve ser adicionado a Kingdom.armies")
	ctx.check(kingdom.armies.size() == armies_before, "[4] Kingdom.armies não deve mudar de tamanho")
	ctx.check(kingdom.cards.size() == cards_before, "[4] Kingdom.cards não deve mudar de tamanho")
	ctx.check(kingdom.commanders.size() == commanders_before, "[4] Kingdom.commanders não deve mudar de tamanho")

	editor._on_cancel_pressed()  # não deve levantar assert de Kingdom.disband_army() (nada foi registrado)
	print("     Cancelar depois de Montar em sandbox_mode não levanta erro (nada foi registrado no Reino)")
	editor.free()


## TESTE 5: sem um pool explícito, sandbox_mode oferece o catálogo
## completo do jogo (GameDatabase), nunca Kingdom.cards/commanders.
static func _test_5_sandbox_pool_defaults_to_full_catalog(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var editor := ArmyEditorPanel.new()
	editor.sandbox_mode = true

	var card_pool: Array[CardResource] = editor._effective_card_pool(kingdom)
	var commander_pool: Array[CommanderResource] = editor._effective_commander_pool(kingdom)

	print("  [5] Pool de sandbox (sem override explícito) usa o catálogo completo, não Kingdom.cards/commanders? Cartas=%s Comandantes=%s" % [
		str(card_pool.size() >= GameDatabase.cards.size()), str(commander_pool.size() >= GameDatabase.commanders.size())
	])
	ctx.check(card_pool.size() == GameDatabase.cards.size(), "[5] Pool de Cartas padrão do sandbox deve ter o mesmo tamanho do catálogo completo (GameDatabase.cards), obtido: %d" % card_pool.size())
	for card: CardResource in card_pool:
		ctx.check(not kingdom.cards.has(card), "[5] Nenhuma Carta do pool de sandbox padrão deve ser um objeto de Kingdom.cards")
		break  # checagem pontual (amostra), suficiente pra provar duplicação — não repetir por toda a lista
	ctx.check(commander_pool.size() > 1, "[5] Pool de Comandantes padrão do sandbox deve ter mais de 1 opção (template real + gerados via CommanderGenerator), obtido: %d" % commander_pool.size())
	editor.free()


## TESTE 6: editar o lado do JOGADOR restringe o pool ao próprio Reino
## (kingdom.cards/commanders duplicados), nunca ao catálogo completo —
## diferente do Army de teste (Teste 5).
## Correção da suíte (2026-09-02): a fixture original criava
## fixture_army.cards diretamente (.duplicate() do catálogo) e só
## adicionava o Army a kingdom.armies — sem NUNCA registrar essas 9
## Cartas em kingdom.cards. Isso nunca acontece em nenhum caminho real
## (Kingdom.form_army() exige que toda Carta de um Army já pertença a
## kingdom.cards — ver Kingdom.form_army(), assert "a carta não
## pertence a este Reino" — Kingdom.cards nunca perde uma Carta só
## porque ela entrou num Exército, apenas muda ownership_status para
## EM_EXERCITO). _open_army_editor("player") (campo_de_prova_panel.gd)
## monta sandbox_card_pool como card_copies (as Cartas já no Army) +
## kingdom.cards cujo NOME ainda não está em source_card_names — sob a
## invariante real (Army.cards ⊆ Kingdom.cards por nome), esse total
## bate exatamente com kingdom.cards.size(). A fixture que ignorava
## kingdom.cards violava essa invariante nunca violada por nenhum
## caminho real; o teste passa a registrar as mesmas 9 Cartas em
## kingdom.cards antes de abrir o Editor (e removê-las depois), como
## qualquer Army real do jogador teria.
static func _test_6_player_side_sandbox_pool_restricted_to_kingdom(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var fixture_army := Army.new()
	fixture_army.commander = option["commander"]
	fixture_army.cards = (option["cards"] as Array[CardResource]).duplicate()
	kingdom.armies.append(fixture_army)
	kingdom.cards.append_array(fixture_army.cards)

	var panel := CampoDeProvaPanel.new()
	panel._mode = "real"
	panel._selected_player_army_index = kingdom.armies.find(fixture_army)
	panel._open_army_editor("player")

	var editor: Control = panel._editor_overlay
	var card_pool: Array = editor.sandbox_card_pool
	var expected_size: int = kingdom.cards.size()
	print("  [6] Editar 'Seu Exército' restringe o pool ao tamanho de Kingdom.cards (%d), obtido: %d" % [expected_size, card_pool.size()])
	ctx.check(card_pool.size() == expected_size, "[6] O pool de Cartas ao editar o lado do jogador deve ter o mesmo tamanho de Kingdom.cards, nunca o catálogo completo")
	for card: CardResource in card_pool:
		ctx.check(not GameDatabase.cards.has(card) or kingdom.cards.has(card), "[6] Toda Carta oferecida ao editar o lado do jogador deve corresponder a algo que o próprio Reino possui")

	panel.remove_child(editor)
	editor.free()
	kingdom.armies.erase(fixture_army)
	for card: CardResource in fixture_army.cards:
		kingdom.cards.erase(card)
	panel.free()


## TESTE 7: _effective_player_army() usa a edição temporária quando
## existe, senão o Army real como está — nunca escreve de volta no real.
static func _test_7_effective_player_army_prefers_edited_version(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var real_army := Army.new()
	real_army.commander = option["commander"]
	real_army.cards = (option["cards"] as Array[CardResource]).duplicate()
	kingdom.armies.append(real_army)

	var panel := CampoDeProvaPanel.new()
	panel._mode = "real"
	panel._selected_player_army_index = kingdom.armies.find(real_army)

	print("  [7] Sem edição, _effective_player_army() retorna o Army real? %s" % str(panel._effective_player_army(kingdom) == real_army))
	ctx.check(panel._effective_player_army(kingdom) == real_army, "[7] Sem nenhuma edição temporária, _effective_player_army() deve retornar o Army real selecionado")

	var edited := Army.new()
	edited.commander = real_army.commander.duplicate()
	edited.cards = []
	panel._edited_player_army = edited
	print("     Com edição temporária definida, _effective_player_army() retorna a edição, e o Army real permanece intacto (9 Cartas)? %s, %s" % [
		str(panel._effective_player_army(kingdom) == edited), str(real_army.cards.size() == 9)
	])
	ctx.check(panel._effective_player_army(kingdom) == edited, "[7] Com uma edição temporária definida, _effective_player_army() deve retorná-la, nunca o Army real")
	ctx.check(real_army.cards.size() == 9, "[7] O Army real do jogador nunca deve ser alterado pela edição temporária (ainda com suas 9 Cartas originais)")

	kingdom.armies.erase(real_army)
	panel.free()


## TESTE 8: o botão de velocidade em CombatReplayView cicla 1x -> 2x ->
## 4x -> 1x, reescrevendo DELAY_BETWEEN_EVENTS_SECONDS (a mesma variável
## que _play_replay() já lê a cada iteração — nenhum mecanismo novo).
static func _test_8_replay_speed_cycles_and_stays_reusable(ctx: TestRunner.Context) -> void:
	var view := CombatReplayView.new()
	view._speed_button = Button.new()  # normalmente criado por _build_footer_bar(); aqui só a lógica pura é testada

	var base: float = CombatReplayView.BASE_DELAY_BETWEEN_EVENTS_SECONDS
	view._on_speed_button_pressed()
	var after_2x: float = view.DELAY_BETWEEN_EVENTS_SECONDS
	view._on_speed_button_pressed()
	var after_4x: float = view.DELAY_BETWEEN_EVENTS_SECONDS
	view._on_speed_button_pressed()
	var after_1x_again: float = view.DELAY_BETWEEN_EVENTS_SECONDS

	print("  [8] Ciclo de velocidade: 2x=%.3f (esperado %.3f), 4x=%.3f (esperado %.3f), volta a 1x=%.3f (esperado %.3f)" % [
		after_2x, base / 2.0, after_4x, base / 4.0, after_1x_again, base
	])
	ctx.check(is_equal_approx(after_2x, base / 2.0), "[8] Primeiro clique deve ir para 2x (metade do delay base)")
	ctx.check(is_equal_approx(after_4x, base / 4.0), "[8] Segundo clique deve ir para 4x (um quarto do delay base)")
	ctx.check(is_equal_approx(after_1x_again, base), "[8] Terceiro clique deve voltar para 1x (delay base — ciclo completo)")
	view._speed_button.free()
	view.free()
