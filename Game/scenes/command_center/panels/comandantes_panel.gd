extends Control
## ComandantesPanel (COMMAND_CENTER_UI.md, "Janela: Comandantes")
##
## Candidatos (Centro de Recrutamento + Painel PvE), Reserva e Ativos —
## tudo ligado direto ao Kingdom real via KingdomState, sem estado
## próprio (exceto qual aba/Comandante está selecionado/expandido na
## tela). Reconstrói a árvore de UI inteira a cada ação — nenhuma regra
## de Comandante/Recrutamento foi alterada nesta etapa, só a
## apresentação.
##
## ETAPA 3 DE INTEGRAÇÃO VISUAL (direção de layout aprovada): 2 colunas
## — Candidatos (esquerda) e Reserva/Ativos por aba (direita) — em vez
## das 3 colunas simultâneas da etapa anterior. Histórico/Doutrina
## deixam de ser uma 3ª coluna sempre visível e viram um ACCORDION:
## clicar em "Histórico"/"Doutrina" numa linha expande o detalhe
## embutido logo abaixo daquele Comandante (empurrando as linhas
## seguintes), sem precisar de espaço reservado permanentemente quando
## nada está selecionado (o estado mais comum). Clicar de novo na
## mesma aba já expandida recolhe.
##
## Retratos: Assets/MVP/Comandantes/Card-*.png (variante "Card", rosto
## bem enquadrado) — copiados para Game/assets/art/commanders/. Como
## Comandantes são gerados proceduralmente (COMMANDER_GENERATION.md) e
## não existe nenhum campo de "retrato" em CommanderResource/
## COMMANDERS.md, o retrato é tratado como ELEMENTO COSMÉTICO
## DETERMINÍSTICO (hash do nome decide qual dos 2 retratos da Facção
## usar) — nunca dado de jogo, nunca modifica identidade/estado do
## Comandante (autorização explícita do pedido desta etapa).

const FRAME_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/command_center_window_frame.png")
const FRAME_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const TITLE_RECT: Rect2 = Rect2(0.27, 0.14, 0.46, 0.06)
const CLOSE_BUTTON_RECT: Rect2 = Rect2(0.85, 0.12, 0.08, 0.12)
const INTERIOR_RECT: Rect2 = Rect2(0.095, 0.242, 0.809, 0.586)

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 3
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)

const PORTRAIT_IMPERIO_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_1.png")
const PORTRAIT_IMPERIO_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_imperio_2.png")
const PORTRAIT_NATUREZA_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_1.png")
const PORTRAIT_NATUREZA_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_natureza_2.png")
const PORTRAIT_MORTOS_VIVOS_1: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_1.png")
const PORTRAIT_MORTOS_VIVOS_2: Texture2D = preload("res://assets/art/commanders/commander_portrait_mortos_vivos_2.png")

const CommandCenterProgressScript = preload("res://engine/command_center/command_center_progress.gd")

var _candidatos_container: VBoxContainer
var _roster_container: VBoxContainer

var _expanded_commander: CommanderResource = null
var _expanded_detail_tab: String = "historico"  # "historico" | "doutrina"


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[ComandantesPanel] Pronto.")


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())
	_clear_children(self)
	_build_static_structure(kingdom)


func _build_static_structure(kingdom: Kingdom) -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var window_area := Control.new()
	window_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	window_area.clip_contents = true
	add_child(window_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = FRAME_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	window_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = FRAME_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_title(texture_rect, "COMANDANTES")
	_build_close_button(texture_rect)
	_build_interior(texture_rect, kingdom)


func _build_title(parent: Control, text: String) -> void:
	var area := _anchor_new_control(parent, TITLE_RECT)
	var label := _make_centered_label(text, 20, HUD_ACCENT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	area.add_child(label)


func _build_close_button(parent: Control) -> void:
	var hotspot := _anchor_new_control(parent, CLOSE_BUTTON_RECT)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.gui_input.connect(_on_close_button_gui_input)


func _on_close_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/command_center/command_center_panel.tscn")


func _build_interior(parent: Control, kingdom: Kingdom) -> void:
	var area := _anchor_new_control(parent, INTERIOR_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	area.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	_build_resumo_bar(root_vbox, kingdom)
	root_vbox.add_child(_make_separator())

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	_build_candidatos_column(columns, kingdom)
	columns.add_child(_make_vertical_separator())
	_build_roster_column(columns, kingdom)


## Só os 2 indicadores reais de Vagas (Cargo Ativo / Vaga Reserva) —
## menor prioridade de informação desta janela (Comandantes > Candidatos
## > Vagas), por isso ficam pequenos e sem nenhum botão disputando
## destaque nesta faixa. "[DEBUG] Gerar Candidato" e "Ativar Próximo
## Recurso Administrativo" foram removidos SÓ da apresentação — as
## funções (_on_debug_generate_candidate_pressed/_on_activate_next_pressed)
## continuam existindo e conectadas a suas regras reais
## (RecruitmentCenterResolver.sync/CommandCenterResolver.activate_next),
## só não têm mais controle visual nesta tela.
##
## CenterContainer (nunca HBoxContainer.alignment = ALIGNMENT_CENTER)
## envolve o par — é a mesma causa raiz do bug de texto verticalizado
## já corrigido em exercitos_panel.gd: BoxContainer com alignment
## CENTER + Label com autowrap força os Labels a negociar largura antes
## do Container pai ter resolvido a própria. CenterContainer não tem
## esse problema porque não redistribui largura entre filhos.
func _build_resumo_bar(parent: Control, kingdom: Kingdom) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	center.add_child(hbox)

	var cargo_ativo_cap: int = CommandCenterProgressScript.effective_cargo_ativo(kingdom)
	var cargo_ativo_used: int = _count_by_state(kingdom, CommanderResource.AdministrativeState.ACTIVE)
	var vaga_reserva_cap: int = CommandCenterProgressScript.effective_vaga_reserva(kingdom)
	var vaga_reserva_used: int = kingdom.reserve_occupancy()

	hbox.add_child(_make_stat_chip("Cargo Ativo", "%d / %d" % [cargo_ativo_used, cargo_ativo_cap]))
	hbox.add_child(_make_stat_chip("Vaga Reserva", "%d / %d" % [vaga_reserva_used, vaga_reserva_cap]))


## --- Coluna esquerda: Candidatos. ---
func _build_candidatos_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.40
	parent.add_child(vbox)

	vbox.add_child(_make_label("Candidatos a Recrutar", 15, HUD_ACCENT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_candidatos_container = VBoxContainer.new()
	_candidatos_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_candidatos_container)

	_refresh_candidatos(kingdom)


func _refresh_candidatos(kingdom: Kingdom) -> void:
	_clear_children(_candidatos_container)

	kingdom.sync_recruitment_center_slots()
	var cooldown_seconds: int = CommandCenterProgressScript.recruitment_center_cooldown_seconds(kingdom.command_center_level)
	var empty_slot_rank: int = 0  # ordem fixa (COMMAND_CENTER_RECRUITMENT.md, "Geração Sequencial")

	for i in range(kingdom.recruitment_center_slots.size()):
		var candidate: CommanderResource = kingdom.recruitment_center_slots[i]
		var card := _make_card_panel()
		_candidatos_container.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		row.add_child(_make_avatar(candidate, 40.0))

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)

		if candidate != null:
			column.add_child(_make_body_label("[Centro de Recrutamento]"))
			column.add_child(_make_label(candidate.commander_name, 12, HUD_TEXT_COLOR))
			var actions_row := HBoxContainer.new()
			column.add_child(actions_row)

			var button := _make_small_button("Comissionar")
			button.disabled = i != _first_occupied_recruitment_slot(kingdom)
			button.pressed.connect(_on_commission_from_slot_pressed.bind(i), CONNECT_DEFERRED)
			actions_row.add_child(button)

			var doctrine_button := _make_small_button("Doutrina")
			doctrine_button.pressed.connect(_on_view_doctrine_pressed.bind(candidate), CONNECT_DEFERRED)
			actions_row.add_child(doctrine_button)
		else:
			var current_cycle_remaining: int = maxi(0, kingdom.recruitment_center_cycle_end_unix - GameClock.now_unix())
			var remaining: int = current_cycle_remaining + empty_slot_rank * cooldown_seconds
			column.add_child(_make_body_label("[Centro de Recrutamento]"))
			column.add_child(_make_body_label("Slot %d vazio (próximo em ~%ds)" % [i + 1, remaining]))
			empty_slot_rank += 1

	for offer: RecruitmentOffer in kingdom.pending_recruitment_offers:
		var card := _make_card_panel()
		_candidatos_container.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		row.add_child(_make_avatar(offer.commander, 40.0))

		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(_make_body_label("[Campanha PvE]"))
		column.add_child(_make_label("%s (%s)" % [offer.commander.commander_name, offer.commander.faction], 12, HUD_TEXT_COLOR))

		var actions_row := HBoxContainer.new()
		column.add_child(actions_row)

		var accept_button := _make_small_button("Aceitar")
		accept_button.pressed.connect(_on_accept_offer_pressed.bind(offer), CONNECT_DEFERRED)
		actions_row.add_child(accept_button)

		var decline_button := _make_small_button("Recusar")
		decline_button.pressed.connect(_on_decline_offer_pressed.bind(offer), CONNECT_DEFERRED)
		actions_row.add_child(decline_button)

	if _candidatos_container.get_child_count() == 0:
		_candidatos_container.add_child(_make_body_label("Nenhum Candidato no momento."))


## --- Coluna direita: Reserva e Ativos, ambas SEMPRE visíveis (não é
## aba/toggle — as duas listas continuam lado a lado, uma embaixo da
## outra, como no comportamento já existente; só o detalhe de
## Histórico/Doutrina virou accordion). ---
func _build_roster_column(parent: Control, kingdom: Kingdom) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.60
	parent.add_child(vbox)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_style_scrollbar(scroll)

	_roster_container = VBoxContainer.new()
	_roster_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_roster_container)

	_refresh_roster(kingdom)


func _refresh_roster(kingdom: Kingdom) -> void:
	_clear_children(_roster_container)

	_roster_container.add_child(_make_label("Reserva", 15, HUD_ACCENT))
	var reserva_count_before: int = _roster_container.get_child_count()
	_refresh_reserva(kingdom)
	if _roster_container.get_child_count() == reserva_count_before:
		_roster_container.add_child(_make_body_label("Nenhum Comandante na Reserva."))

	_roster_container.add_child(_make_separator())

	_roster_container.add_child(_make_label("Ativos", 15, HUD_ACCENT))
	var ativos_count_before: int = _roster_container.get_child_count()
	_refresh_ativos(kingdom)
	if _roster_container.get_child_count() == ativos_count_before:
		_roster_container.add_child(_make_body_label("Nenhum Comandante Ativo."))


func _refresh_reserva(kingdom: Kingdom) -> void:
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
			continue

		var card := _make_card_panel()
		_roster_container.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 8)
		column.add_child(header_row)
		header_row.add_child(_make_avatar(commander, 50.0))

		var info_column := VBoxContainer.new()
		info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(info_column)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		info_column.add_child(_make_label("%s | %s | %s" % [commander.commander_name, patente, commander.faction], 12, HUD_TEXT_COLOR))
		info_column.add_child(_make_body_label("V:%d E:%d D:%d | WR: %.0f%% | %s" % [
			commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0,
			CommanderCareer.xp_progress_text(commander.accumulated_xp)
		]))

		var actions_row := HBoxContainer.new()
		actions_row.add_theme_constant_override("separation", 4)
		column.add_child(actions_row)

		var promote_button := _make_small_button("Promover")
		promote_button.pressed.connect(_on_promote_pressed.bind(commander), CONNECT_DEFERRED)
		actions_row.add_child(promote_button)

		var active_commanders: Array[CommanderResource] = []
		for c: CommanderResource in kingdom.commanders:
			if c.administrative_state == CommanderResource.AdministrativeState.ACTIVE:
				active_commanders.append(c)
		if not active_commanders.is_empty():
			var swap_option := OptionButton.new()
			swap_option.add_theme_font_size_override("font_size", 11)
			for active_commander: CommanderResource in active_commanders:
				swap_option.add_item(active_commander.commander_name)
			actions_row.add_child(swap_option)

			var swap_button := _make_small_button("Trocar")
			swap_button.pressed.connect(_on_swap_pressed.bind(commander, active_commanders, swap_option), CONNECT_DEFERRED)
			actions_row.add_child(swap_button)

		_add_detail_toggle_buttons(actions_row, commander)
		_maybe_add_expanded_detail(column, commander)


func _refresh_ativos(kingdom: Kingdom) -> void:
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
			continue

		var card := _make_card_panel()
		_roster_container.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 8)
		column.add_child(header_row)
		header_row.add_child(_make_avatar(commander, 50.0))

		var info_column := VBoxContainer.new()
		info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(info_column)

		var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
		var function_text: String = "Ocioso" if commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE else "Liderando Exército"
		info_column.add_child(_make_label("%s | %s | %s | %s" % [commander.commander_name, patente, commander.faction, function_text], 12, HUD_TEXT_COLOR))
		info_column.add_child(_make_body_label("V:%d E:%d D:%d | WR: %.0f%% | %s" % [
			commander.total_victories, commander.total_draws, commander.total_defeats(), commander.win_rate() * 100.0,
			CommanderCareer.xp_progress_text(commander.accumulated_xp)
		]))

		var actions_row := HBoxContainer.new()
		actions_row.add_theme_constant_override("separation", 4)
		column.add_child(actions_row)

		var return_button := _make_small_button("Voltar à Reserva")
		return_button.disabled = commander.ownership_status == CommanderResource.OwnershipStatus.EM_EXERCITO
		return_button.pressed.connect(_on_return_to_reserve_pressed.bind(commander), CONNECT_DEFERRED)
		actions_row.add_child(return_button)

		_add_detail_toggle_buttons(actions_row, commander)
		_maybe_add_expanded_detail(column, commander)


## Botões "Histórico"/"Doutrina" — clicar expande o accordion embutido
## logo abaixo desta linha; clicar de novo na mesma aba já expandida
## recolhe (nunca uma 3ª coluna fixa, ver docstring do topo).
func _add_detail_toggle_buttons(parent: Control, commander: CommanderResource) -> void:
	var history_button := _make_small_button("Histórico")
	history_button.pressed.connect(_on_toggle_detail_pressed.bind(commander, "historico"), CONNECT_DEFERRED)
	parent.add_child(history_button)

	var doctrine_button := _make_small_button("Doutrina")
	doctrine_button.pressed.connect(_on_toggle_detail_pressed.bind(commander, "doutrina"), CONNECT_DEFERRED)
	parent.add_child(doctrine_button)


func _on_toggle_detail_pressed(commander: CommanderResource, tab_id: String) -> void:
	if _expanded_commander == commander and _expanded_detail_tab == tab_id:
		_expanded_commander = null
	else:
		_expanded_commander = commander
		_expanded_detail_tab = tab_id
	refresh()


func _maybe_add_expanded_detail(parent: Control, commander: CommanderResource) -> void:
	if _expanded_commander != commander:
		return

	parent.add_child(_make_separator())

	var detail_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	detail_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 4)
	detail_panel.add_child(detail_vbox)

	if _expanded_detail_tab == "historico":
		_build_historico_content(detail_vbox, commander)
	else:
		_build_doutrina_content(detail_vbox, commander)


func _build_historico_content(parent: Control, commander: CommanderResource) -> void:
	if commander.battle_log.is_empty():
		parent.add_child(_make_body_label("Nenhuma batalha registrada ainda."))
		return

	for entry: Dictionary in commander.battle_log:
		parent.add_child(_make_body_label("%s | contra: %s | %s" % [entry.get("context", ""), entry.get("opponent_name", ""), entry.get("result", "")]))

		var own_formation: Array = entry.get("own_formation", [])
		var enemy_formation: Array = entry.get("enemy_formation", [])
		if not own_formation.is_empty() and not enemy_formation.is_empty():
			var grids_row := HBoxContainer.new()
			grids_row.add_theme_constant_override("separation", 16)
			parent.add_child(grids_row)
			grids_row.add_child(_build_formation_grid_display("Seu Exército", own_formation))
			grids_row.add_child(_build_formation_grid_display("Inimigo", enemy_formation))


func _build_doutrina_content(parent: Control, commander: CommanderResource) -> void:
	var doctrine: CommanderDoctrine = commander.doctrine
	if doctrine == null:
		parent.add_child(_make_body_label("Este Comandante não tem Doutrina (ex: Comandante do Kit Inicial)."))
		return

	parent.add_child(_make_body_label("Restrição: %s" % doctrine.restriction_description()))
	parent.add_child(_make_body_label("Requisito: %s" % doctrine.requirement_description()))

	var target_text: String = doctrine.target.description
	if doctrine.target.value != "":
		target_text += " (%s)" % doctrine.target.value
	parent.add_child(_make_body_label("Alvo: %s" % target_text))

	parent.add_child(_make_body_label("Efeito: %s" % doctrine.effect.description))
	parent.add_child(_make_body_label("Valor: %s" % doctrine.value_description()))


func _build_formation_grid_display(title_text: String, formation: Array) -> Control:
	var container := VBoxContainer.new()
	container.add_child(_make_label(title_text, 10, HUD_TEXT_COLOR))

	var grid := GridContainer.new()
	grid.columns = 3
	container.add_child(grid)

	# Mesma ordem visual (posição 1-9) do grid 3x3 de army_editor_panel.gd
	# (POSITION_LAYOUT), convertida para índice 0-based.
	var visual_order: Array[int] = [0, 1, 2, 5, 4, 3, 6, 7, 8]
	for index: int in visual_order:
		var cell := _make_label(str(formation[index]) if index < formation.size() and formation[index] != "" else "—", 9, HUD_TEXT_COLOR)
		cell.custom_minimum_size = Vector2(85, 0)
		grid.add_child(cell)

	return container


func _count_by_state(kingdom: Kingdom, state: CommanderResource.AdministrativeState) -> int:
	var count: int = 0
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state == state:
			count += 1
	return count


func _first_occupied_recruitment_slot(kingdom: Kingdom) -> int:
	for i in range(kingdom.recruitment_center_slots.size()):
		if kingdom.recruitment_center_slots[i] != null:
			return i
	return -1


func _on_activate_next_pressed() -> void:
	CommandCenterResolver.activate_next(KingdomState.kingdom)
	refresh()


func _on_debug_generate_candidate_pressed() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(kingdom, GameClock.now_unix())
	refresh()


func _on_commission_from_slot_pressed(slot_index: int) -> void:
	RecruitmentCenterResolver.commission_from_slot(KingdomState.kingdom, slot_index, GameClock.now_unix())
	refresh()


func _on_accept_offer_pressed(offer: RecruitmentOffer) -> void:
	CommissioningResolver.commission_from_pve_offer(KingdomState.kingdom, offer, GameClock.now_unix())
	refresh()


func _on_decline_offer_pressed(offer: RecruitmentOffer) -> void:
	KingdomState.kingdom.decline_recruitment_offer(offer)
	refresh()


func _on_promote_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_active(KingdomState.kingdom, commander)
	refresh()


func _on_swap_pressed(reserve_commander: CommanderResource, active_commanders: Array[CommanderResource], option: OptionButton) -> void:
	var active_commander: CommanderResource = active_commanders[option.selected]
	CommandCenterResolver.swap_active_reserve(active_commander, reserve_commander)
	refresh()


func _on_return_to_reserve_pressed(commander: CommanderResource) -> void:
	CommandCenterResolver.move_to_reserve(KingdomState.kingdom, commander)
	refresh()


## Mantidos para compatibilidade com validações existentes que acionam
## Histórico/Doutrina diretamente (equivalente a clicar e expandir).
func _on_view_doctrine_pressed(commander: CommanderResource) -> void:
	_expanded_commander = commander
	_expanded_detail_tab = "doutrina"
	refresh()


func _on_view_history_pressed(commander: CommanderResource) -> void:
	_expanded_commander = commander
	_expanded_detail_tab = "historico"
	refresh()


## --- Retratos (cosméticos, determinísticos — ver docstring do topo). ---

func _portrait_for(commander: CommanderResource) -> Texture2D:
	if commander == null:
		return null
	var variant: int = absi(commander.commander_name.hash()) % 2
	match commander.faction:
		"Império":
			return PORTRAIT_IMPERIO_1 if variant == 0 else PORTRAIT_IMPERIO_2
		"Natureza":
			return PORTRAIT_NATUREZA_1 if variant == 0 else PORTRAIT_NATUREZA_2
		"Mortos-Vivos":
			return PORTRAIT_MORTOS_VIVOS_1 if variant == 0 else PORTRAIT_MORTOS_VIVOS_2
		_:
			return null


func _make_avatar(commander: CommanderResource, size: float) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(size, size)
	slot.clip_contents = true

	var texture: Texture2D = _portrait_for(commander)
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(rect)

	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 1
	border_style.border_width_right = 1
	border_style.border_width_top = 1
	border_style.border_width_bottom = 1
	border_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.7)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border)

	return slot


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _anchor_new_control(parent: Control, rect: Rect2) -> Control:
	var control := Control.new()
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	control.clip_contents = true
	parent.add_child(control)
	return control


## "wrap" é false por padrão: título/rótulo/valor curto nunca deve
## quebrar linha (bug clássico do Godot — um Label com
## AUTOWRAP_WORD_SMART dentro de um Container ainda sem largura
## resolvida na primeira passada de layout quebra letra-por-letra).
## Só texto realmente longo (Histórico, Doutrina, via _make_body_label)
## deve passar wrap=true.
func _make_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := _make_label(text, font_size, color, wrap)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_body_label(text: String) -> Label:
	var label := _make_label(text, 11, HUD_TEXT_COLOR, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _make_vertical_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(1, 0)
	return sep


func _make_card_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.08)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_stat_chip(title_text: String, value_text: String) -> Control:
	var card := _make_card_panel()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.add_child(_make_centered_label(title_text, 10, HUD_MUTED_COLOR))
	vbox.add_child(_make_centered_label(value_text, 14, HUD_TEXT_COLOR))
	return card


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 11)
	_style_office_button(button)
	return button


func _style_office_button(button: Button) -> void:
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HUD_ACCENT_SELECTED)
	button.add_theme_color_override("font_disabled_color", HUD_MUTED_COLOR)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.07, 0.11, 0.85)
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 6.0
	normal_style.content_margin_right = 6.0
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = Color(HUD_ACCENT_SELECTED.r, HUD_ACCENT_SELECTED.g, HUD_ACCENT_SELECTED.b, 0.22)
	hover_style.border_color = HUD_ACCENT_SELECTED
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var v_scroll: VScrollBar = scroll.get_v_scroll_bar()
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.65)
	grabber_style.corner_radius_top_left = 4
	grabber_style.corner_radius_top_right = 4
	grabber_style.corner_radius_bottom_left = 4
	grabber_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("grabber", grabber_style)
	var grabber_hover_style: StyleBoxFlat = grabber_style.duplicate()
	grabber_hover_style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.9)
	v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover_style)
	v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_hover_style)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	track_style.corner_radius_top_left = 4
	track_style.corner_radius_top_right = 4
	track_style.corner_radius_bottom_left = 4
	track_style.corner_radius_bottom_right = 4
	v_scroll.add_theme_stylebox_override("scroll", track_style)
