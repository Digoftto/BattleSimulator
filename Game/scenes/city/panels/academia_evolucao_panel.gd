extends Control
## AcademiaEvolucaoPanel (ACADEMY.md, "Progressão da Academia" + CITY.md)
##
## Tela própria (nunca popup) — usa EXCLUSIVAMENTE academia_upgrade.png
## (arte-template oficial, 1224x1285, com molduras/rótulos/caixas vazias
## já desenhadas) como fundo completo, mesmo padrão de
## energy_core_panel.gd. A arte NUNCA é alterada — cada campo dinâmico é
## um Control ancorado por cima da caixa vazia correspondente (Rect2
## calibrado por varredura de grade normalizada sobre o pixel real, ver
## relatório da tarefa). Os números de exemplo que porventura existissem
## na arte são tratados como referência visual apenas — nenhum valor é
## copiado dela; tudo vem de InstitutionalConstructionResolver/
## AcademyEconomy.
##
## ARQUITETURA DE CÓDIGO (mesmo padrão do Núcleo de Energia,
## energy_core_panel.gd): nenhuma regra econômica vive aqui.
## - InstitutionalConstructionResolver.cost_breakdown()/evolve()/
##   get_current_level()/building_key() — custo, execução e nível atual.
## - AcademyEconomy.time_reduction()/artifice_count()/metamorfo_count()/
##   MAX_LEVEL — efeitos da evolução e teto de Nível 120.
## - Kingdom.get_raw_resource()/get_building_reserved("academia", ...) —
##   saldo do Depósito e Reserva Antecipada já creditada pra esta
##   Academia especificamente.
##
## Academia usa Essência Vital (70%, Principal) e Ferro Negro (30%,
## Secundário) — nunca Cristais Arcanos, exatamente como a arte desenha
## (só esses 2 recursos na tabela "Recursos Necessários").
##
## Confirmação de evolução SIM/NÃO na própria tela (nunca uma segunda
## janela) — mesma técnica do Núcleo de Energia: o 1º clique em
## "EVOLUIR ACADEMIA" só prepara a confirmação (nada é gasto/alterado);
## a mesma área do botão vira NÃO/SIM; só SIM executa evolve().

const ACADEMIA_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/academia_upgrade.png")
const ACADEMIA_IMAGE_ASPECT_RATIO: float = 1224.0 / 1285.0
const ACADEMIA_HUB_SCENE: String = "res://scenes/city/panels/academia_panel.tscn"

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)

const BUILDING: InstitutionalConstructionConfig.Building = InstitutionalConstructionConfig.Building.ACADEMIA
const RESOURCE_LABELS: Dictionary = {"essencia_vital": "Essência Vital", "ferro_negro": "Ferro Negro"}
const RESOURCE_ORDER: Array[String] = ["essencia_vital", "ferro_negro"]

## --- Regiões calibradas por varredura de grade normalizada sobre
## academia_upgrade.png (1224x1285) — ver relatório da tarefa. ---
const CLOSE_BUTTON: Rect2 = Rect2(0.895, 0.035, 0.070, 0.065)

const NIVEL_ATUAL_BOX: Rect2 = Rect2(0.245, 0.246, 0.153, 0.030)
const NIVEL_PROXIMO_BOX: Rect2 = Rect2(0.603, 0.246, 0.152, 0.030)

## Linhas "Efeitos da Evolução": Redução de Tempo / Artífices /
## Metamorfos. Recalibrado por varredura fina (passo 0.005, 2x zoom)
## sobre academy_upgrade.png — as caixas "Atual"/"Próximo" e a caixa
## "Efeito"/"Alteração" da MESMA linha NÃO compartilham o mesmo centro
## vertical (a caixa de Efeito começa mais abaixo, por causa do
## cabeçalho "→ EFEITO ←"/"→ ALTERAÇÃO ←" inline acima dela) — por
## isso cada campo tem seu próprio Rect2 completo, nunca derivado de um
## único centro de linha compartilhado (causa raiz do desalinhamento
## anterior).
const REDUCAO_CURRENT_BOX: Rect2 = Rect2(0.358, 0.363, 0.120, 0.045)
const REDUCAO_NEXT_BOX: Rect2 = Rect2(0.522, 0.363, 0.120, 0.045)
const REDUCAO_EFEITO_BOX: Rect2 = Rect2(0.665, 0.378, 0.180, 0.032)

const ARTIFICES_CURRENT_BOX: Rect2 = Rect2(0.358, 0.420, 0.120, 0.043)
const ARTIFICES_NEXT_BOX: Rect2 = Rect2(0.522, 0.420, 0.120, 0.043)
const ARTIFICES_EFEITO_BOX: Rect2 = Rect2(0.665, 0.438, 0.180, 0.032)

const METAMORFOS_CURRENT_BOX: Rect2 = Rect2(0.358, 0.500, 0.120, 0.042)
const METAMORFOS_NEXT_BOX: Rect2 = Rect2(0.522, 0.500, 0.120, 0.042)
const METAMORFOS_EFEITO_BOX: Rect2 = Rect2(0.665, 0.500, 0.180, 0.032)

const RECURSOS_ROW_CENTERS_Y: Array[float] = [0.665, 0.725]
const RECURSOS_NECESSARIO_X: Rect2 = Rect2(0.325, 0.0, 0.112, 0.040)
const RECURSOS_JA_POSSUI_X: Rect2 = Rect2(0.462, 0.0, 0.110, 0.040)
const RECURSOS_FALTA_X: Rect2 = Rect2(0.607, 0.0, 0.093, 0.040)
const RECURSOS_DISPONIVEL_X: Rect2 = Rect2(0.727, 0.0, 0.118, 0.040)

const CUSTO_EVOLUCAO_BOX: Rect2 = Rect2(0.235, 0.798, 0.530, 0.024)
const EVOLVE_BUTTON: Rect2 = Rect2(0.150, 0.897, 0.700, 0.040)

var _pending_confirmation: bool = false


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[AcademiaEvolucaoPanel] Pronto.")


func refresh() -> void:
	_clear_children(self)
	_build_structure()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _build_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = ACADEMIA_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ACADEMIA_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var close_hotspot := _make_hotspot(CLOSE_BUTTON)
	close_hotspot.gui_input.connect(_on_back_gui_input)
	texture_rect.add_child(close_hotspot)

	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = InstitutionalConstructionResolver.get_current_level(kingdom, BUILDING)
	var at_max_level: bool = current_level >= AcademyEconomy.MAX_LEVEL
	var next_level: int = mini(current_level + 1, AcademyEconomy.MAX_LEVEL)
	var blocked_by_capital: bool = not at_max_level and not Capital.can_building_evolve(current_level, kingdom.capital_level)

	_value_label(texture_rect, NIVEL_ATUAL_BOX, str(current_level), 16, HUD_TEXT_COLOR)
	_value_label(texture_rect, NIVEL_PROXIMO_BOX, ("Máximo" if at_max_level else str(next_level)), 16, HUD_TEXT_COLOR if not at_max_level else HUD_MUTED_COLOR)

	_build_effects_section(texture_rect, current_level, next_level, at_max_level)
	_build_resources_section(texture_rect, kingdom, next_level, at_max_level)
	_build_action_area(texture_rect, kingdom, next_level, at_max_level, blocked_by_capital)


## --- Efeitos da Evolução (Redução de Tempo / Artífices / Metamorfos) ---
## Cada campo usa seu próprio Rect2 completo (ver constantes) — a
## caixa "Atual"/"Próximo" e a caixa "Efeito" da mesma linha NÃO
## compartilham centro vertical na arte, então nunca são derivadas uma
## da outra.
func _build_effects_section(parent: Control, current_level: int, next_level: int, at_max_level: bool) -> void:
	var current_reduction: float = AcademyEconomy.time_reduction(current_level) * 100.0
	var current_artifices: int = AcademyEconomy.artifice_count(current_level)
	var current_metamorfos: int = AcademyEconomy.metamorfo_count(current_level)

	_value_label(parent, REDUCAO_CURRENT_BOX, "%.1f%%" % current_reduction, 13, HUD_TEXT_COLOR)
	_value_label(parent, ARTIFICES_CURRENT_BOX, str(current_artifices), 13, HUD_TEXT_COLOR)
	_value_label(parent, METAMORFOS_CURRENT_BOX, str(current_metamorfos), 13, HUD_TEXT_COLOR)

	if at_max_level:
		_value_label(parent, REDUCAO_NEXT_BOX, "—", 13, HUD_MUTED_COLOR)
		_value_label(parent, ARTIFICES_NEXT_BOX, "—", 13, HUD_MUTED_COLOR)
		_value_label(parent, METAMORFOS_NEXT_BOX, "—", 13, HUD_MUTED_COLOR)
		_value_label(parent, REDUCAO_EFEITO_BOX, "Nível máximo atingido", 10, HUD_MUTED_COLOR)
		_value_label(parent, ARTIFICES_EFEITO_BOX, "Nível máximo atingido", 10, HUD_MUTED_COLOR)
		_value_label(parent, METAMORFOS_EFEITO_BOX, "Nível máximo atingido", 10, HUD_MUTED_COLOR)
		return

	var next_reduction: float = AcademyEconomy.time_reduction(next_level) * 100.0
	var next_artifices: int = AcademyEconomy.artifice_count(next_level)
	var next_metamorfos: int = AcademyEconomy.metamorfo_count(next_level)

	_value_label(parent, REDUCAO_NEXT_BOX, "%.1f%%" % next_reduction, 13, HUD_TEXT_COLOR)
	_value_label(parent, ARTIFICES_NEXT_BOX, str(next_artifices), 13, HUD_TEXT_COLOR)
	_value_label(parent, METAMORFOS_NEXT_BOX, str(next_metamorfos), 13, HUD_TEXT_COLOR)

	var reduction_delta: float = next_reduction - current_reduction
	_value_label(parent, REDUCAO_EFEITO_BOX, ("+%.1f pp" % reduction_delta) if reduction_delta > 0 else "Sem alteração", 10, HUD_TEXT_COLOR)

	var artifice_delta: int = next_artifices - current_artifices
	_value_label(parent, ARTIFICES_EFEITO_BOX, ("+%d Artífice(s)" % artifice_delta) if artifice_delta > 0 else "Sem alteração", 10, HUD_TEXT_COLOR)

	var metamorfo_delta: int = next_metamorfos - current_metamorfos
	_value_label(parent, METAMORFOS_EFEITO_BOX, ("+%d Metamorfo(s)" % metamorfo_delta) if metamorfo_delta > 0 else "Sem alteração", 10, HUD_TEXT_COLOR)


## --- Recursos Necessários (Essência Vital / Ferro Negro) ---
func _build_resources_section(parent: Control, kingdom: Kingdom, next_level: int, at_max_level: bool) -> void:
	if at_max_level:
		for row_index in range(RESOURCE_ORDER.size()):
			for x_rect: Rect2 in [RECURSOS_NECESSARIO_X, RECURSOS_JA_POSSUI_X, RECURSOS_FALTA_X, RECURSOS_DISPONIVEL_X]:
				_resource_row_label(parent, row_index, x_rect, "—", HUD_MUTED_COLOR)
		return

	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(BUILDING, next_level)
	var key: String = InstitutionalConstructionResolver.building_key(BUILDING)

	for row_index in range(RESOURCE_ORDER.size()):
		var resource: String = RESOURCE_ORDER[row_index]
		var necessario: int = costs.get(resource, 0)
		var ja_possui: int = kingdom.get_building_reserved(key, resource)
		var falta: int = maxi(0, necessario - ja_possui)
		var disponivel: int = kingdom.get_raw_resource(resource)

		_resource_row_label(parent, row_index, RECURSOS_NECESSARIO_X, str(necessario), HUD_TEXT_COLOR)
		_resource_row_label(parent, row_index, RECURSOS_JA_POSSUI_X, str(ja_possui), HUD_TEXT_COLOR)
		_resource_row_label(parent, row_index, RECURSOS_FALTA_X, str(falta), HUD_TEXT_COLOR)
		_resource_row_label(parent, row_index, RECURSOS_DISPONIVEL_X, str(disponivel), HUD_TEXT_COLOR)

	var cost_summary: String = " | ".join(RESOURCE_ORDER.map(func(r: String) -> String: return "%s: %d" % [RESOURCE_LABELS[r], costs.get(r, 0)]))
	_value_label(parent, CUSTO_EVOLUCAO_BOX, cost_summary, 12, HUD_TEXT_COLOR)


func _resource_row_label(parent: Control, row_index: int, x_rect: Rect2, text: String, color: Color) -> void:
	var rect := Rect2(x_rect.position.x, RECURSOS_ROW_CENTERS_Y[row_index] - x_rect.size.y / 2.0, x_rect.size.x, x_rect.size.y)
	_value_label(parent, rect, text, 12, color)


## --- Botão Evoluir / Confirmação em 2 etapas (mesmo padrão do
## Núcleo de Energia: SIM/NÃO na própria tela, nunca uma segunda
## janela). ---
func _build_action_area(parent: Control, kingdom: Kingdom, next_level: int, at_max_level: bool, blocked_by_capital: bool) -> void:
	if at_max_level:
		return

	if _pending_confirmation:
		_value_label(parent, CUSTO_EVOLUCAO_BOX, "Confirmar evolução da Academia?", 12, HUD_ACCENT_SELECTED)
		_build_confirmation_buttons(parent)
		return

	if blocked_by_capital:
		var blocked_hotspot := _make_hotspot(EVOLVE_BUTTON)
		blocked_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(blocked_hotspot)
		_value_label(parent, CUSTO_EVOLUCAO_BOX, "Bloqueado: a Capital precisa evoluir primeiro.", 11, HUD_MUTED_COLOR)
		return

	var evolve_hotspot := _make_hotspot(EVOLVE_BUTTON)
	evolve_hotspot.gui_input.connect(_on_evolve_gui_input)
	parent.add_child(evolve_hotspot)


func _build_confirmation_buttons(parent: Control) -> void:
	var half_width: float = EVOLVE_BUTTON.size.x / 2.0
	var no_rect := Rect2(EVOLVE_BUTTON.position.x, EVOLVE_BUTTON.position.y, half_width, EVOLVE_BUTTON.size.y)
	var yes_rect := Rect2(EVOLVE_BUTTON.position.x + half_width, EVOLVE_BUTTON.position.y, half_width, EVOLVE_BUTTON.size.y)

	var no_hotspot := _make_hotspot(no_rect)
	no_hotspot.gui_input.connect(_on_cancel_gui_input)
	parent.add_child(no_hotspot)
	_value_label(parent, no_rect, "NÃO", 15, HUD_TEXT_COLOR)

	var yes_hotspot := _make_hotspot(yes_rect)
	yes_hotspot.gui_input.connect(_on_confirm_gui_input)
	parent.add_child(yes_hotspot)
	_value_label(parent, yes_rect, "SIM", 15, HUD_ACCENT_SELECTED)


func _on_evolve_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_confirmation = true
		refresh()


func _on_cancel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_confirmation = false
		refresh()


## Guarda contra duplo clique (mesmo padrão do Núcleo de Energia):
## limpa _pending_confirmation ANTES de chamar o resolver.
func _on_confirm_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _pending_confirmation:
			return
		_pending_confirmation = false
		var result: Dictionary = InstitutionalConstructionResolver.evolve(KingdomState.kingdom, BUILDING)
		if result["success"]:
			print("[AcademiaEvolucaoPanel] Academia evoluída com sucesso.")
		else:
			print("[AcademiaEvolucaoPanel] Evolução bloqueada: %s" % result["reason"])
		refresh()


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(ACADEMIA_HUB_SCENE)


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

func _make_hotspot(rect: Rect2) -> Control:
	var hotspot := Control.new()
	_anchor_control(hotspot, rect)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return hotspot


func _anchor_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _value_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	_anchor_control(label, rect)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
