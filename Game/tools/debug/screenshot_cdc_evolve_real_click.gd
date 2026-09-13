extends Node
## screenshot_cdc_evolve_real_click.gd (Auditoria pré-pré-alfa — verificação
## definitiva do NOVO botão "Evoluir" dentro do próprio Centro de
## Comando). Clique REAL via Input.parse_input_event() (nunca chamada
## direta de handler), screenshots ANTES/DEPOIS.

const CommandCenterScene: PackedScene = preload("res://scenes/command_center/command_center_panel.tscn")

## FASE 23.1 (Infraestrutura de Testes): ver engine/testing/user_data_dir_guard.gd
## — checagem obrigatória ANTES de KingdomSaveService.delete_save()
## abaixo, que é destrutivo e roda ANTES da 2ª linha de defesa em
## KingdomState.initialize_new_kingdom().
const UserDataDirGuardScript = preload("res://engine/testing/user_data_dir_guard.gd")

func _ready() -> void:
	if UserDataDirGuardScript.abort_if_unsafe(get_tree()):
		return
	KingdomSaveService.delete_save()
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	var kingdom: Kingdom = KingdomState.kingdom
	# Recursos suficientes pro custo do Nível 1->2 (mesmo padrão de
	# outros debug tools — nunca um valor mágico: generoso o bastante
	# pra qualquer custo real, a checagem de affordability real é o que
	# está sendo testado, não o valor exato do custo).
	for resource_name: String in ["ferro_negro", "cristais_arcanos", "essencia_vital"]:
		kingdom.raw_resources[resource_name] = 1000000
	kingdom.capital_level = 20  # bem acima do necessário pro Capital Limit não bloquear

	await get_tree().process_frame
	var panel: Control = CommandCenterScene.instantiate()
	get_tree().root.add_child(panel)
	for i in range(30):
		await get_tree().process_frame

	print("[0] Nível do CdC ANTES: %d" % kingdom.command_center_level)
	var img_before: Image = get_viewport().get_texture().get_image()
	img_before.save_png("res://../.scratch4/cdc_evolve_BEFORE.png")
	print("[1] Screenshot ANTES salvo.")

	var evolve_chip: Control = _find_control_with_text_prefix(panel, "Evoluir (Nível")
	if evolve_chip == null:
		print("ERRO CRÍTICO: chip 'Evoluir' não encontrado na árvore real do CdC.")
		get_tree().quit(1)
		return

	var target_point: Vector2 = evolve_chip.get_global_rect().get_center()
	print("[2] Chip 'Evoluir' encontrado — centro do clique: %s" % str(target_point))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = target_point
	press.global_position = target_point
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = target_point
	release.global_position = target_point
	Input.parse_input_event(release)

	for i in range(20):
		await get_tree().process_frame

	print("[3] Nível do CdC DEPOIS do clique real: %d (esperado: %d)" % [kingdom.command_center_level, 2])
	var img_after: Image = get_viewport().get_texture().get_image()
	img_after.save_png("res://../.scratch4/cdc_evolve_AFTER.png")
	print("[4] Screenshot DEPOIS salvo.")

	get_tree().quit()


func _find_control_with_text_prefix(node: Node, prefix: String) -> Control:
	if node is Label and (node as Label).text.begins_with(prefix):
		return node.get_parent() as Control
	for child: Node in node.get_children():
		var found: Control = _find_control_with_text_prefix(child, prefix)
		if found != null:
			return found
	return null
