class_name TestAcademiaFilaCardNameRendering
extends RefCounted
## TestAcademiaFilaCardNameRendering (Auditoria pré-pré-alfa)
##
## Regressão dedicada ao achado real desta auditoria: o nome da Carta na
## Fila de Produção da Academia nunca aparecia (o Label existia com o
## texto certo, mas o VBoxContainer pai (`list`) nunca esticava até a
## largura do ScrollContainer, deixando quase 0px de largura pro
## EXPAND_FILL do nome distribuir — mesma causa-raiz já documentada e
## corrigida em bestiario_panel.gd::_on_detail_scroll_resized).
##
## Duas asserções independentes, cada uma cobrindo uma metade real do
## bug: [A] o MECANISMO da correção (_on_fila_scroll_resized força
## list.custom_minimum_size.x a acompanhar scroll.size.x — testado
## isolado, com scroll.size setado diretamente, nunca dependente de um
## frame real de layout) e [B] o CONTEÚDO de cada linha renderizada
## (nome real da Carta, maiúsculo, e o tempo restante real — MM:SS
## quando já iniciada, "na fila" quando não).

const PANEL_SCRIPT: Script = preload("res://scenes/city/panels/academia_producao_panel.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria] Validando renderização da Fila de Produção da Academia...")
	_test_a_scroll_resize_stretches_list_width(ctx)
	_test_b_fila_rows_show_real_card_name_and_time(ctx)
	return true


## A: reproduz exatamente o mecanismo da correção, isolado de qualquer
## timing de layout/viewport real.
static func _test_a_scroll_resize_stretches_list_width(ctx: TestRunner.Context) -> void:
	var panel: Control = PANEL_SCRIPT.new()

	var scroll := ScrollContainer.new()
	scroll.size = Vector2(340, 120)
	var list := VBoxContainer.new()

	panel.call("_on_fila_scroll_resized", scroll, list)
	print("  [A1] list.custom_minimum_size.x após resize (%.1f) bate com scroll.size.x (%.1f)? %s" % [
		list.custom_minimum_size.x, scroll.size.x, str(is_equal_approx(list.custom_minimum_size.x, scroll.size.x))
	])
	ctx.check(is_equal_approx(list.custom_minimum_size.x, scroll.size.x), "[A1] _on_fila_scroll_resized deve forçar list.custom_minimum_size.x a acompanhar scroll.size.x — sem isso, o nome da Carta não tem espaço pra aparecer")

	scroll.size = Vector2(500, 120)
	panel.call("_on_fila_scroll_resized", scroll, list)
	print("  [A2] Um 2º resize (largura maior) atualiza list.custom_minimum_size.x de novo? %s (obtido: %.1f, esperado: 500.0)" % [
		str(is_equal_approx(list.custom_minimum_size.x, 500.0)), list.custom_minimum_size.x
	])
	ctx.check(is_equal_approx(list.custom_minimum_size.x, 500.0), "[A2] O ajuste deve acompanhar TODA mudança de largura do ScrollContainer, não só a primeira")

	panel.free()


## B: constrói a Fila com 2 tarefas reais (1 "na fila", 1 já iniciada) e
## confirma que cada linha carrega o NOME real da Carta e o tempo
## correto — mesmo padrão de acesso direto ao builder usado em
## test_bestiario_energy_soldo.gd (_build_detail_area), sem precisar da
## árvore de cena completa.
static func _test_b_fila_rows_show_real_card_name_and_time(ctx: TestRunner.Context) -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	var card_name: String = "Lich Rei"
	ctx.check(GameDatabase.get_card(card_name) != null, "[pré-condição] '%s' deve existir no catálogo real (GameDatabase.cards)" % card_name)

	var kingdom := Kingdom.new()
	kingdom.sync_academy_masters()
	ctx.check(not kingdom.academy_artifices.is_empty(), "[pré-condição] sync_academy_masters() deve garantir ao menos 1 Artífice")
	if kingdom.academy_artifices.is_empty():
		return

	var now_unix: int = GameClock.now_unix()

	var queued_task := AcademyTask.new()
	queued_task.target_card_name = card_name
	queued_task.quantity = 1
	# start_unix = 0 -> has_started() == false -> "na fila" (nunca uma
	# contagem regressiva inventada para uma tarefa que ainda não rodou).

	var running_task := AcademyTask.new()
	running_task.target_card_name = card_name
	running_task.quantity = 1
	running_task.start_unix = now_unix - 30
	running_task.end_unix = now_unix + 90  # 90s restantes reais

	kingdom.academy_artifices[0].queue.append(queued_task)
	kingdom.academy_artifices[0].queue.append(running_task)

	var panel: Control = PANEL_SCRIPT.new()
	var host := Control.new()
	panel.call("_build_fila", host, kingdom)

	var list: VBoxContainer = host.get_child(0).get_child(0).get_child(0).get_child(0)
	print("  [B0] Fila renderizou exatamente 2 linhas (1 por tarefa)? %s (obtido: %d)" % [str(list.get_child_count() == 2), list.get_child_count()])
	ctx.check(list.get_child_count() == 2, "[B0] A Fila deve renderizar exatamente 1 linha por AcademyTask real na queue do Artífice")
	if list.get_child_count() != 2:
		host.free()
		panel.free()
		return

	var row_queued: HBoxContainer = list.get_child(0)
	var row_running: HBoxContainer = list.get_child(1)
	var name_queued: Label = row_queued.get_child(0)
	var time_queued: Label = row_queued.get_child(1)
	var name_running: Label = row_running.get_child(0)
	var time_running: Label = row_running.get_child(1)

	print("  [B1] Nome real da 1ª linha (ainda na fila) = '%s' (esperado: '%s')" % [name_queued.text, card_name.to_upper()])
	ctx.check(name_queued.text == card_name.to_upper(), "[B1] O Label de nome deve conter o NOME REAL da Carta em maiúsculo (task.target_card_name.to_upper()) — nunca vazio, nunca um placeholder")
	print("  [B2] Tempo da 1ª linha (ainda não iniciada) = '%s' (esperado: 'na fila')" % time_queued.text)
	ctx.check(time_queued.text == "na fila", "[B2] Uma tarefa que ainda não começou (start_unix == 0) deve mostrar 'na fila', nunca uma contagem regressiva inventada")

	print("  [B3] Nome real da 2ª linha (em andamento) = '%s' (esperado: '%s')" % [name_running.text, card_name.to_upper()])
	ctx.check(name_running.text == card_name.to_upper(), "[B3] O nome deve aparecer igualmente para uma tarefa já iniciada")
	print("  [B4] Tempo da 2ª linha (90s restantes reais) = '%s' (esperado: '01:30')" % time_running.text)
	ctx.check(time_running.text == "01:30", "[B4] Uma tarefa iniciada deve mostrar MM:SS real, calculado de task.end_unix - now_unix (nunca um valor inventado)")

	host.free()
	panel.free()
