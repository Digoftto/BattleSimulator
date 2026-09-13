extends Node
## screenshot_commander_full_flow.gd (Auditoria pré-pré-alfa)
##
## Fluxo completo REAL: recruta (CommissioningResolver.commission(), mesmo
## caminho de produção), abre Comandantes (Passo A do tutorial), clica de
## verdade em "Promover" (mesmo handler real _on_promote_pressed — nunca
## setando administrative_state à mão), reabre a tela (Passo C ou
## concluído) — 3 screenshots, um por momento.

const ComandantesScene: PackedScene = preload("res://scenes/command_center/panels/comandantes_panel.tscn")

## FASE 23.1 (Infraestrutura de Testes): ver engine/testing/user_data_dir_guard.gd
## — checagem obrigatória ANTES de KingdomSaveService.delete_save()
## abaixo, que é destrutivo e roda ANTES da 2ª linha de defesa em
## KingdomState.initialize_new_kingdom().
const UserDataDirGuardScript = preload("res://engine/testing/user_data_dir_guard.gd")

func _ready() -> void:
	if UserDataDirGuardScript.abort_if_unsafe(get_tree()):
		return
	# IMPORTANTE (achado real desta auditoria): KingdomState.initialize_new_kingdom()
	# CARREGA um save existente em user://kingdom_save.json se houver —
	# várias ferramentas de debug desta sessão já rodaram e o autosave
	# (KingdomState._process(), 60s) e/ou o encerramento de processos
	# anteriores já gravaram estado acumulado. Sem apagar o save aqui,
	# este teste NÃO representaria um jogador novo de verdade (mesmo
	# padrão que test_main.gd já usa: KingdomSaveService.delete_save()
	# antes de initialize_new_kingdom()).
	KingdomSaveService.delete_save()
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	var kingdom: Kingdom = KingdomState.kingdom
	print("[0] Estado inicial: Cargo Ativo ativado=%d | Vaga Reserva ativada=%d | Comandantes=%d" % [
		kingdom.cargo_ativo_activated, kingdom.vaga_reserva_activated, kingdom.commanders.size()
	])

	var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
	var commander: CommanderResource = options[0]["commander"]
	var result: Dictionary = CommissioningResolver.commission(kingdom, commander, GameClock.now_unix(), "Debug")
	print("[1] Recrutamento real: %s | Estado do Comandante: %s" % [str(result), CommanderResource.AdministrativeState.keys()[commander.administrative_state]])

	await get_tree().process_frame
	var panel: Control = ComandantesScene.instantiate()
	get_tree().root.add_child(panel)
	for i in range(20):
		await get_tree().process_frame

	var img_a: Image = get_viewport().get_texture().get_image()
	img_a.save_png("res://../.scratch4/flow_1_step_a.png")
	print("[2] Screenshot Passo A salvo.")

	# Clique REAL em "Promover" — mesmo handler que o botão real dispara,
	# nunca administrative_state escrito à mão.
	panel.call("_on_promote_pressed", commander)
	for i in range(20):
		await get_tree().process_frame

	print("[3] Após Promover real: Estado do Comandante: %s | commander_tutorial_promoted=%s" % [
		CommanderResource.AdministrativeState.keys()[commander.administrative_state],
		kingdom.has_progress_flag("commander_tutorial_promoted")
	])

	var img_b: Image = get_viewport().get_texture().get_image()
	img_b.save_png("res://../.scratch4/flow_2_step_c.png")
	print("[4] Screenshot Passo C salvo.")

	# Continuar o Passo C (fecha o tutorial) e reabrir a tela do zero,
	# simulando "fechar/reabrir o jogo" — confirma que NADA reaparece.
	panel.call("_on_tutorial_step_c_continue")
	for i in range(20):
		await get_tree().process_frame

	var img_c: Image = get_viewport().get_texture().get_image()
	img_c.save_png("res://../.scratch4/flow_3_after_completed.png")
	print("[5] Screenshot pós-conclusão salvo. commander_tutorial_completed=%s" % kingdom.has_progress_flag("commander_tutorial_completed"))

	get_tree().quit()
