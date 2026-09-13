extends Node
## screenshot_city_cdc_real_click.gd (Auditoria pré-pré-alfa — verificação
## definitiva, exigida pelo usuário: clique REAL, não atalho de código)
##
## Diferente da tentativa anterior (que setava _selected_building_key
## diretamente, pulando a detecção de clique de verdade): aqui a Cidade
## real é aberta, a hitbox real "Hitbox_centro_de_comando" é localizada
## na árvore (mesmo Control clicável do jogo real), e um evento de mouse
## de verdade é despachado via Input.parse_input_event() — passa pelo
## pipeline de input real do Godot (hit-testing, mouse_filter, ordem de
## z-index), exatamente como um clique humano faria. Screenshot ANTES e
## DEPOIS do clique, como exigido.

const CityScene: PackedScene = preload("res://scenes/city/city_panel.tscn")

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

	# ACHADO REAL desta auditoria (achado só depois de o find_child()
	# abaixo falhar e o dump da árvore ter revelado "StarterKitPanel" no
	# lugar da Cidade real): um Reino novo (kingdom.starter_kit_used ==
	# false) mostra a tela de escolha do Kit Inicial POR CIMA da Cidade —
	# nenhuma hitbox de construção (incluindo o Centro de Comando) existe
	# antes disso. Minha verificação anterior desta mesma auditoria
	# (screenshot_cdc_evolve_popup.gd) pulava essa etapa inteira,
	# setando _selected_building_key diretamente — nunca comprovava que
	# um jogador novo de verdade chegaria até ali. Corrigido: escolhe um
	# Kit Inicial real primeiro (mesma chamada que o botão real da tela
	# de escolha dispara), só então a Cidade real (com as 8 hitboxes)
	# existe.
	var kingdom: Kingdom = KingdomState.kingdom
	if not kingdom.starter_kit_used:
		var options: Array[Dictionary] = StarterKitResolver.generate_options(GameDatabase.cards)
		StarterKitResolver.choose_option(kingdom, options[0], GameClock.now_unix())
		print("[0] Kit Inicial escolhido (Facção: %s) — starter_kit_used agora: %s" % [options[0]["faction"], kingdom.starter_kit_used])

	await get_tree().process_frame
	var panel: Control = CityScene.instantiate()
	get_tree().root.add_child(panel)
	for i in range(30):
		await get_tree().process_frame

	# --- ANTES do clique ---
	var img_before: Image = get_viewport().get_texture().get_image()
	img_before.save_png("res://../.scratch4/city_cdc_BEFORE_click.png")
	print("[1] Screenshot ANTES do clique salvo.")

	var hitbox: Control = panel.find_child("Hitbox_centro_de_comando", true, false)
	if hitbox == null:
		print("ERRO CRÍTICO: Hitbox_centro_de_comando não encontrada na árvore real da Cidade.")
		print("--- Árvore completa de 'panel' (diagnóstico) ---")
		_print_tree(panel, 0)
		get_tree().quit(1)
		return

	var target_rect: Rect2 = hitbox.get_global_rect()
	var target_point: Vector2 = target_rect.get_center()
	print("[2] Hitbox real encontrada — rect global: %s | centro do clique: %s" % [str(target_rect), str(target_point)])

	# --- Clique REAL, via pipeline de input do Godot (nunca chamada
	# direta de método interno) ---
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

	print("[3] _selected_building_key após o clique real: '%s' (esperado: 'centro_de_comando')" % str(panel.get("_selected_building_key")))

	var img_after: Image = get_viewport().get_texture().get_image()
	img_after.save_png("res://../.scratch4/city_cdc_AFTER_click.png")
	print("[4] Screenshot DEPOIS do clique salvo.")

	# Confirma que um botão "Evoluir" (nunca só o texto de nível) existe
	# de verdade na árvore renderizada, clicável.
	var evolve_button: Button = _find_button_with_text(panel, "Evoluir")
	print("[5] Botão 'Evoluir' encontrado na árvore real após o clique? %s" % str(evolve_button != null))
	if evolve_button != null:
		print("    Botão 'Evoluir': disabled=%s | visible=%s | global_rect=%s" % [
			str(evolve_button.disabled), str(evolve_button.is_visible_in_tree()), str(evolve_button.get_global_rect())
		])

	get_tree().quit()


func _print_tree(node: Node, depth: int) -> void:
	print("%s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()])
	if depth > 6:
		return
	for child: Node in node.get_children():
		_print_tree(child, depth + 1)


func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for child: Node in node.get_children():
		var found: Button = _find_button_with_text(child, text)
		if found != null:
			return found
	return null
