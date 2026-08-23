class_name TestTutorialFlow
extends RefCounted
## TestTutorialFlow (TUT-001)
##
## Valida o tutorial mínimo do loop principal (Cidade -> Exércitos ->
## PvE -> pós-combate) chamando os MÉTODOS REAIS de cada painel
## diretamente (mesmo padrão já usado em test_army_editor_formation_flow.gd
## — nenhum dos métodos exercitados aqui chama get_tree(), então não
## precisa de SceneTree nem de await). Painéis são scripts sem
## class_name (CityPanel/ExercitosPanel/PvEPanel), por isso instanciados
## via preload(caminho).new() em vez de um identificador bare.
##
## Cobre: A) novo jogador começa no Passo 1, sem a flag de conclusão;
## B) progressão real passo a passo, através das 3 telas reais;
## E) conclusão marca progress_flags["tutorial_concluido"] (mecanismo
## já existente, testado em test_kingdom.gd); F) nenhum painel volta a
## mostrar o banner depois de concluído; D) tutorial_step sobrevive a um
## save/load real; G) reabrir uma tela sem ter avançado (abandono)
## nunca quebra nem duplica o banner — cada instância de painel decide
## isso sozinha, a partir do Kingdom compartilhado, nunca de memória
## própria da tela.

static func run(ctx: TestRunner.Context) -> bool:
	print("[TUT-001] Validando o tutorial mínimo (Cidade/Exércitos/PvE/pós-combate)...")
	_test_a_new_kingdom_starts_at_step_one(ctx)
	_test_b_full_progression_through_real_panels(ctx)
	_test_post_combat_gate_accepts_skipped_step_three(ctx)
	_test_f_never_reappears_after_completion(ctx)
	_test_d_tutorial_step_survives_save_load(ctx)
	_test_g_reopening_screen_without_advancing_is_safe(ctx)
	return true


## A
static func _test_a_new_kingdom_starts_at_step_one(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	print("  [A] Reino novo -> tutorial_step == CIDADE (0)? %s | flag de conclusão ainda não existe? %s (esperado: true, true)" % [
		str(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_CIDADE), str(not kingdom.has_progress_flag("tutorial_concluido"))
	])
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_CIDADE, "[A] Kingdom novo deve começar no Passo 1 (TUTORIAL_STEP_CIDADE)")
	ctx.check(not kingdom.has_progress_flag("tutorial_concluido"), "[A] Kingdom novo nunca deve nascer com o tutorial já concluído")


## B: os 4 passos reais, um após o outro, usando os métodos de verdade
## de CityPanel/ExercitosPanel/PvEPanel — prova que a mesma sequência
## que um jogador real percorre avança o Kingdom corretamente.
static func _test_b_full_progression_through_real_panels(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	# --- Passo 1: Cidade ---
	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._maybe_show_tutorial_hint()
	print("  [B1] CityPanel mostra o banner no Passo 1? %s (esperado: true, 1 filho)" % str(city_panel.get_child_count() == 1))
	ctx.check(city_panel.get_child_count() == 1, "[B1] CityPanel deve mostrar exatamente 1 banner de dica quando tutorial_step == CIDADE")

	city_panel._on_tutorial_hint_continue(city_panel.get_child(0))
	print("  [B1] 'Continuar' avança pro Passo 2 (EXERCITO)? %s (esperado: true)" % str(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_EXERCITO))
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_EXERCITO, "[B1] 'Continuar' na Cidade deve avançar tutorial_step para EXERCITO")
	city_panel.free()

	# --- Passo 2: Exércitos ---
	var exercitos_panel = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	exercitos_panel._maybe_show_tutorial_hint()
	print("  [B2] ExercitosPanel mostra o banner no Passo 2? %s (esperado: true, 1 filho)" % str(exercitos_panel.get_child_count() == 1))
	ctx.check(exercitos_panel.get_child_count() == 1, "[B2] ExercitosPanel deve mostrar exatamente 1 banner de dica quando tutorial_step == EXERCITO")

	exercitos_panel._on_tutorial_hint_continue(exercitos_panel.get_child(0))
	print("  [B2] 'Continuar' avança pro Passo 3 (PVE)? %s (esperado: true)" % str(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_PVE))
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_PVE, "[B2] 'Continuar' em Exércitos deve avançar tutorial_step para PVE")
	exercitos_panel.free()

	# --- Passo 3: PvE ---
	var pve_panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	pve_panel._maybe_show_tutorial_hint()
	print("  [B3] PvEPanel mostra o banner no Passo 3? %s (esperado: true)" % str(pve_panel._tutorial_banner != null))
	ctx.check(pve_panel._tutorial_banner != null, "[B3] PvEPanel deve mostrar o banner de dica quando tutorial_step == PVE")

	pve_panel._on_tutorial_hint_continue()
	print("  [B3] 'Continuar' avança pro Passo 4 (POS_COMBATE) e libera o banner? %s, %s (esperado: true, true)" % [
		str(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_POS_COMBATE), str(pve_panel._tutorial_banner == null)
	])
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_POS_COMBATE, "[B3] 'Continuar' no PvE deve avançar tutorial_step para POS_COMBATE")
	ctx.check(pve_panel._tutorial_banner == null, "[B3] 'Continuar' deve liberar a referência do banner anterior")

	# --- Passo 4: pós-combate (Combate/Resultado/Recompensa) ---
	pve_panel._maybe_show_post_combat_tutorial_hint()
	print("  [B4] PvEPanel mostra o banner pós-combate no Passo 4? %s (esperado: true)" % str(pve_panel._tutorial_banner != null))
	ctx.check(pve_panel._tutorial_banner != null, "[B4] PvEPanel deve mostrar o banner pós-combate quando tutorial_step == POS_COMBATE")

	pve_panel._on_post_combat_tutorial_hint_continue()
	print("  [B4] 'Concluir Tutorial' marca CONCLUIDO + flag de progresso? %s, %s (esperado: true, true)" % [
		str(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_CONCLUIDO), str(kingdom.has_progress_flag("tutorial_concluido"))
	])
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_CONCLUIDO, "[B4] Concluir o banner pós-combate deve avançar tutorial_step para CONCLUIDO")
	ctx.check(kingdom.has_progress_flag("tutorial_concluido"), "[B4] Concluir o banner pós-combate deve marcar progress_flags['tutorial_concluido']")
	pve_panel.free()

	KingdomState.kingdom = old_kingdom


## Um jogador pode clicar "Tentar Fase Atual" sem antes dispensar o
## banner do Passo 3 (o banner nunca bloqueia o resto da tela) —
## tutorial_step continua PVE nesse caso. Sem o gate aceitar PVE além
## de POS_COMBATE, essa primeira batalha real nunca disparia o
## encerramento do tutorial.
static func _test_post_combat_gate_accepts_skipped_step_three(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_PVE  # Passo 3 nunca dispensado
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var pve_panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	pve_panel._maybe_show_post_combat_tutorial_hint()
	print("  [Skip-3] Banner pós-combate aparece mesmo sem 'Continuar' no Passo 3? %s (esperado: true)" % str(pve_panel._tutorial_banner != null))
	ctx.check(pve_panel._tutorial_banner != null, "Pular o 'Continuar' do Passo 3 não pode impedir o banner pós-combate de aparecer depois da primeira batalha real")
	pve_panel.free()

	KingdomState.kingdom = old_kingdom


## F: uma vez concluído, nenhuma das 3 telas volta a mostrar o banner
## — nem a Cidade (tutorial_step já muito além de CIDADE), nem, mais
## importante, se alguém (bug futuro) deixasse tutorial_step decair de
## volta a um passo antigo: a flag de conclusão sozinha já bloqueia tudo.
static func _test_f_never_reappears_after_completion(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_CIDADE  # mesmo que o passo "regredisse"
	kingdom.set_progress_flag("tutorial_concluido")
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var city_panel = preload("res://scenes/city/city_panel.gd").new()
	city_panel._maybe_show_tutorial_hint()
	print("  [F] Concluído -> CityPanel não mostra banner mesmo com tutorial_step == CIDADE? %s (esperado: true, 0 filhos)" % str(city_panel.get_child_count() == 0))
	ctx.check(city_panel.get_child_count() == 0, "[F] Tutorial concluído (progress_flags) deve suprimir o banner independente do valor de tutorial_step")
	city_panel.free()

	var exercitos_panel = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_EXERCITO
	exercitos_panel._maybe_show_tutorial_hint()
	ctx.check(exercitos_panel.get_child_count() == 0, "[F] Tutorial concluído deve suprimir o banner em ExercitosPanel também")
	exercitos_panel.free()

	var pve_panel = preload("res://scenes/command_center/panels/pve_panel.gd").new()
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_PVE
	pve_panel._maybe_show_tutorial_hint()
	pve_panel._maybe_show_post_combat_tutorial_hint()
	print("  [F] Concluído -> PvEPanel não mostra banner nenhum (nem o do Passo 3, nem o pós-combate)? %s (esperado: true)" % str(pve_panel._tutorial_banner == null))
	ctx.check(pve_panel._tutorial_banner == null, "[F] Tutorial concluído deve suprimir os dois banners de PvEPanel também")
	pve_panel.free()

	KingdomState.kingdom = old_kingdom


## D: tutorial_step é dado do Kingdom como qualquer outro — precisa
## sobreviver ao mesmo round-trip real de save/load usado por tudo mais
## (KingdomSaveService), tanto no meio do tutorial quanto já concluído.
static func _test_d_tutorial_step_survives_save_load(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var mid_tutorial := Kingdom.new()
	mid_tutorial.tutorial_step = Kingdom.TUTORIAL_STEP_PVE
	KingdomSaveService.save(mid_tutorial)
	var loaded_mid := Kingdom.new()
	KingdomSaveService.load_into(loaded_mid)
	print("  [D1] tutorial_step no meio do tutorial sobrevive ao save/load? %s (%d, esperado: %d)" % [
		str(loaded_mid.tutorial_step == Kingdom.TUTORIAL_STEP_PVE), loaded_mid.tutorial_step, Kingdom.TUTORIAL_STEP_PVE
	])
	ctx.check(loaded_mid.tutorial_step == Kingdom.TUTORIAL_STEP_PVE, "[D1] tutorial_step no meio do tutorial deve sobreviver a um save/load real")

	var completed := Kingdom.new()
	completed.tutorial_step = Kingdom.TUTORIAL_STEP_CONCLUIDO
	completed.set_progress_flag("tutorial_concluido")
	KingdomSaveService.save(completed)
	var loaded_completed := Kingdom.new()
	KingdomSaveService.load_into(loaded_completed)
	print("  [D2] tutorial CONCLUIDO + flag sobrevivem ao save/load? %s, %s (esperado: true, true)" % [
		str(loaded_completed.tutorial_step == Kingdom.TUTORIAL_STEP_CONCLUIDO), str(loaded_completed.has_progress_flag("tutorial_concluido"))
	])
	ctx.check(loaded_completed.tutorial_step == Kingdom.TUTORIAL_STEP_CONCLUIDO, "[D2] tutorial_step concluído deve sobreviver a um save/load real")
	ctx.check(loaded_completed.has_progress_flag("tutorial_concluido"), "[D2] a flag de conclusão deve sobreviver junto com tutorial_step")

	KingdomSaveService.delete_save()


## G (abandono): "fechar e reabrir" uma tela sem nunca ter avançado o
## passo não é um caso especial — é só uma segunda instância de painel
## consultando o mesmo Kingdom persistido. Confirma que reabrir a MESMA
## tela repetidamente é seguro (nunca duplica nem quebra) e que a tela
## normal continua funcionando por baixo, independente do banner.
static func _test_g_reopening_screen_without_advancing_is_safe(ctx: TestRunner.Context) -> void:
	var kingdom := Kingdom.new()
	kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_EXERCITO
	var old_kingdom: Kingdom = KingdomState.kingdom
	KingdomState.kingdom = kingdom

	var first_visit = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	first_visit._maybe_show_tutorial_hint()
	print("  [G1] 1ª visita (sem avançar) mostra o banner? %s (esperado: true)" % str(first_visit.get_child_count() == 1))
	ctx.check(first_visit.get_child_count() == 1, "[G1] Reabrir a tela sem ter clicado 'Continuar' antes ainda deve mostrar o banner")
	first_visit.free()  # jogador "fecha o jogo" sem clicar Continuar — tutorial_step nunca avançou

	print("  [G2] tutorial_step permanece EXERCITO depois do abandono (nenhum estado corrompido)? %s (esperado: true)" % str(
		kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_EXERCITO
	))
	ctx.check(kingdom.tutorial_step == Kingdom.TUTORIAL_STEP_EXERCITO, "[G2] Abandonar sem clicar 'Continuar' não deve alterar tutorial_step")

	var second_visit = preload("res://scenes/city/panels/exercitos_panel.gd").new()
	second_visit._maybe_show_tutorial_hint()
	print("  [G3] Reabrir de novo (2ª instância da mesma tela) mostra o mesmo banner corretamente, sem duplicar? %s (esperado: true, 1 filho)" % str(
		second_visit.get_child_count() == 1
	))
	ctx.check(second_visit.get_child_count() == 1, "[G3] Reabrir a tela novamente deve mostrar exatamente 1 banner, nunca acumular instâncias antigas")
	second_visit.free()

	KingdomState.kingdom = old_kingdom
