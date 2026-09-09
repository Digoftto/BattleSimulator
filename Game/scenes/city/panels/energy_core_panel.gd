extends Control
## EnergyCorePanel (ENERGY_NUCLEUS.md — "Evolução do Núcleo")
##
## Tela própria (nunca popup) — usa EXCLUSIVAMENTE
## energy_core_main.png como referência visual (asset definitivo desta
## etapa; substitui qualquer arte anterior do Núcleo — Energy
## Distribution/Crystal Processing/Power Network NÃO são usadas aqui e
## não têm hotspot nesta etapa, pedido explícito). Todas as regiões
## abaixo foram calibradas por varredura de pixel real sobre o asset
## (ver relatório da tarefa) — nenhuma leitura visual aproximada.
##
## Escopo desta etapa (pedido explícito): só a evolução/informação do
## Núcleo. Navegação: Cidade -> hub do Núcleo (energy_core_hub_panel.gd,
## energy core.png, hotspot único sobre o reator) -> este painel. O
## "X" já desenhado na arte fecha de volta para o hub (nunca direto
## pra Cidade — quem volta à Cidade é o hub, via seu próprio chip
## "Voltar para a Cidade").
##
## ARQUITETURA DE CÓDIGO (pedido explícito, mesmo padrão do Depósito):
## nenhuma regra econômica vive aqui. Fontes reais reaproveitadas sem
## duplicação:
## - EnergyNucleus.energia_base()/recovery_seconds() — Energia Base e
##   Recuperação, por nível.
## - InstitutionalConstructionResolver.cost_breakdown()/evolve()/
##   get_current_level()/building_key() — custo, execução da evolução
##   e nível atual (NUCLEO_DE_ENERGIA já é uma das 4 construções
##   institucionais, mesma arquitetura de Capital/Centro de Comando/
##   Academia).
## - Kingdom.get_raw_resource()/get_building_reserved() — saldo do
##   Depósito e Reserva Antecipada (Supply Chain) já creditada pra este
##   Núcleo especificamente — NUNCA o saldo geral do Depósito confundido
##   com "Já Possui" (são fontes conceitualmente diferentes, pedido
##   explícito §13).
##
## Núcleo de Energia usa SOMENTE Cristais Arcanos (70%) e Essência
## Vital (30%) — NUNCA Ferro Negro (confirmado em
## InstitutionalConstructionResolver._principal_resource()/
## _secondary_resource() — Ferro Negro nunca aparece nesta tela).
##
## ATENÇÃO — DIVERGÊNCIA DOCUMENTADA (pedido explícito §8, NÃO
## corrigida nesta tarefa): EnergyNucleus.recovery_seconds() não bate
## com a tabela "Progressão Resumida" de ENERGY_NUCLEUS.md a partir do
## nível 5 (ex.: nível 60 → código dá 294s, documento tabula 326s). Os
## testes existentes (test_energy_nucleus.gd) validam contra o
## comportamento do próprio código, não contra a tabela do documento —
## ver nota de migração naquele arquivo. Esta tela usa
## EnergyNucleus.recovery_seconds() (a fonte centralizada atual) tal
## como está; se uma correção de fórmula for decidida no futuro, esta
## tela acompanha automaticamente (nenhum valor é copiado/congelado
## aqui).

const ENERGY_CORE_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/energy_core_main.png")
const ENERGY_CORE_IMAGE_ASPECT_RATIO: float = 1199.0 / 1312.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)

## Cor sólida da própria arte no fundo das linhas "+1 Energia Base"/
## "-3s por ponto" (texto de exemplo, fixo na imagem — pedido explícito
## §19: "esses valores... são apenas referência visual do layout").
## Um pequeno retângulo desta MESMA cor (nunca cinza/translúcido
## genérico) cobre exatamente essa linha antes do texto dinâmico real
## ser desenhado por cima — a mesma técnica de "remendo casado com o
## fundo", não um painel novo.
const BACKDROP_PATCH_COLOR: Color = Color(0.004, 0.031, 0.063, 1.0)

## Núcleo de Energia usa a mesma chave já usada pelo Supply Chain
## (InstitutionalConstructionResolver.building_key()).
const BUILDING: InstitutionalConstructionConfig.Building = InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA

## --- Regiões calibradas por varredura de pixel sobre
## energy_core_main.png (1199x1312) — ver relatório da tarefa. ---
const CURRENT_LEVEL_BOX: Rect2 = Rect2(0.241868, 0.234756, 0.136781, 0.041921)
const NEXT_LEVEL_BOX: Rect2 = Rect2(0.622185, 0.234756, 0.135947, 0.041921)
const ENERGY_BASE_CURRENT_BOX: Rect2 = Rect2(0.164304, 0.400152, 0.112594, 0.041921)
const ENERGY_BASE_NEXT_BOX: Rect2 = Rect2(0.346122, 0.400152, 0.111760, 0.041921)
const RECOVERY_CURRENT_BOX: Rect2 = Rect2(0.539616, 0.400152, 0.114262, 0.041921)
const RECOVERY_NEXT_BOX: Rect2 = Rect2(0.723937, 0.400152, 0.112594, 0.041921)
const ENERGY_BASE_DELTA_PATCH: Rect2 = Rect2(0.164304, 0.453506, 0.293578, 0.020579)
const RECOVERY_DELTA_PATCH: Rect2 = Rect2(0.539616, 0.453506, 0.296914, 0.020579)

const RESOURCE_BOXES: Dictionary = {
	"cristais_arcanos": {
		"necessario": Rect2(0.326939, 0.588415, 0.110926, 0.040396),
		"ja_possui": Rect2(0.473728, 0.588415, 0.110092, 0.040396),
		"falta": Rect2(0.613845, 0.588415, 0.110926, 0.040396),
		"disponivel": Rect2(0.754796, 0.588415, 0.111760, 0.040396),
	},
	"essencia_vital": {
		"necessario": Rect2(0.326939, 0.653201, 0.110926, 0.041159),
		"ja_possui": Rect2(0.473728, 0.653201, 0.110092, 0.041159),
		"falta": Rect2(0.613845, 0.653201, 0.110926, 0.041159),
		"disponivel": Rect2(0.754796, 0.653201, 0.111760, 0.041159),
	},
}
## Ordem de exibição (a arte desenha Cristais Arcanos antes de Essência
## Vital) — nunca Ferro Negro.
const RESOURCE_ORDER: Array[String] = ["cristais_arcanos", "essencia_vital"]

const EVOLUTION_COST_BOX: Rect2 = Rect2(0.264387, 0.759909, 0.471226, 0.052591)
const CLOSE_BUTTON: Rect2 = Rect2(0.888240, 0.041921, 0.079233, 0.072409)
const EVOLVE_BUTTON: Rect2 = Rect2(0.115096, 0.830793, 0.768140, 0.086890)

## Fechar (X) e "voltar" retornam ao hub do Núcleo (energy core.png +
## hotspot único), não direto pra Cidade — a navegação agora tem essa
## etapa intermediária (energy_core_hub_panel.gd).
const ENERGY_CORE_HUB_SCENE: String = "res://scenes/city/panels/energy_core_hub_panel.tscn"

var _pending_confirmation: bool = false


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[EnergyCorePanel] Pronto.")


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
	aspect.ratio = ENERGY_CORE_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = ENERGY_CORE_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = InstitutionalConstructionResolver.get_current_level(kingdom, BUILDING)
	var at_max_level: bool = current_level >= EnergyNucleus.MAX_LEVEL
	var next_level: int = mini(current_level + 1, EnergyNucleus.MAX_LEVEL)
	var blocked_by_capital: bool = not at_max_level and not Capital.can_building_evolve(current_level, kingdom.capital_level)

	_value_label(texture_rect, CURRENT_LEVEL_BOX, str(current_level), 16, HUD_TEXT_COLOR)
	_value_label(texture_rect, NEXT_LEVEL_BOX, ("Máximo" if at_max_level else str(next_level)), 16, HUD_TEXT_COLOR if not at_max_level else HUD_MUTED_COLOR)

	_build_effects_section(texture_rect, current_level, next_level, at_max_level)
	_build_resources_section(texture_rect, kingdom, next_level, at_max_level)
	_build_action_area(texture_rect, kingdom, next_level, at_max_level, blocked_by_capital)

	var close_hotspot := _make_hotspot(CLOSE_BUTTON)
	close_hotspot.gui_input.connect(_on_close_gui_input, CONNECT_DEFERRED)
	texture_rect.add_child(close_hotspot)


## --- Efeitos da Evolução (Energia Base / Recuperação) ---
func _build_effects_section(parent: Control, current_level: int, next_level: int, at_max_level: bool) -> void:
	var current_base: int = EnergyNucleus.energia_base(current_level)
	var current_recovery: int = EnergyNucleus.recovery_seconds(current_level)

	_value_label(parent, ENERGY_BASE_CURRENT_BOX, str(current_base), 14, HUD_TEXT_COLOR)
	_value_label(parent, RECOVERY_CURRENT_BOX, EnergyNucleus.format_seconds(current_recovery), 13, HUD_TEXT_COLOR)

	if at_max_level:
		_value_label(parent, ENERGY_BASE_NEXT_BOX, "—", 14, HUD_MUTED_COLOR)
		_value_label(parent, RECOVERY_NEXT_BOX, "—", 13, HUD_MUTED_COLOR)
		_patch_and_label(parent, ENERGY_BASE_DELTA_PATCH, "Nível máximo atingido", 11, HUD_MUTED_COLOR)
		_patch_and_label(parent, RECOVERY_DELTA_PATCH, "Nível máximo atingido", 11, HUD_MUTED_COLOR)
		return

	var next_base: int = EnergyNucleus.energia_base(next_level)
	var next_recovery: int = EnergyNucleus.recovery_seconds(next_level)

	_value_label(parent, ENERGY_BASE_NEXT_BOX, str(next_base), 14, HUD_TEXT_COLOR)
	_value_label(parent, RECOVERY_NEXT_BOX, EnergyNucleus.format_seconds(next_recovery), 13, HUD_TEXT_COLOR)

	var base_delta: int = next_base - current_base
	var base_delta_text: String = ("+%d Energia Base" % base_delta) if base_delta > 0 else "Energia Base inalterada"
	_patch_and_label(parent, ENERGY_BASE_DELTA_PATCH, base_delta_text, 12, HUD_TEXT_COLOR)

	var recovery_delta: int = current_recovery - next_recovery
	var recovery_delta_text: String = ("-%ds por ponto" % recovery_delta) if recovery_delta > 0 else "Recuperação inalterada"
	_patch_and_label(parent, RECOVERY_DELTA_PATCH, recovery_delta_text, 12, HUD_TEXT_COLOR)


## --- Recursos Necessários (Cristais Arcanos / Essência Vital) ---
func _build_resources_section(parent: Control, kingdom: Kingdom, next_level: int, at_max_level: bool) -> void:
	if at_max_level:
		for resource: String in RESOURCE_ORDER:
			var boxes: Dictionary = RESOURCE_BOXES[resource]
			for field: String in boxes:
				_value_label(parent, boxes[field], "—", 12, HUD_MUTED_COLOR)
		return

	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(BUILDING, next_level)
	var key: String = InstitutionalConstructionResolver.building_key(BUILDING)

	for resource: String in RESOURCE_ORDER:
		var boxes: Dictionary = RESOURCE_BOXES[resource]
		var necessario: int = costs.get(resource, 0)
		var ja_possui: int = kingdom.get_building_reserved(key, resource)
		var falta: int = maxi(0, necessario - ja_possui)
		var disponivel: int = kingdom.get_raw_resource(resource)

		_value_label(parent, boxes["necessario"], str(necessario), 12, HUD_TEXT_COLOR)
		_value_label(parent, boxes["ja_possui"], str(ja_possui), 12, HUD_TEXT_COLOR)
		_value_label(parent, boxes["falta"], str(falta), 12, HUD_TEXT_COLOR)
		_value_label(parent, boxes["disponivel"], str(disponivel), 12, HUD_TEXT_COLOR)


## --- Botão Evoluir / Confirmação em 2 etapas ---
##
## A caixa "CUSTO DE EVOLUÇÃO" (EVOLUTION_COST_BOX) nunca recebe texto
## de resumo/resultado/bloqueio em repouso (pedido explícito) — os
## mesmos números já estão na tabela RECURSOS NECESSÁRIOS acima, sem
## duplicação. A ÚNICA exceção é o prompt de confirmação SIM/NÃO
## (pedido explícito §16 da tarefa original, reconfirmado como "não
## alterar" nesta tarefa). O bloqueio pelo nível da Capital continua
## existindo na lógica (hotspot inerte), só sem texto visual sobre o
## botão.
func _build_action_area(parent: Control, kingdom: Kingdom, next_level: int, at_max_level: bool, blocked_by_capital: bool) -> void:
	if at_max_level:
		var maxed_hotspot := _make_hotspot(EVOLVE_BUTTON)
		maxed_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(maxed_hotspot)
		return

	if _pending_confirmation:
		_value_label(parent, EVOLUTION_COST_BOX, "Confirmar evolução do Núcleo?", 13, HUD_ACCENT_SELECTED)
		_build_confirmation_buttons(parent)
		return

	if blocked_by_capital:
		var blocked_hotspot := _make_hotspot(EVOLVE_BUTTON)
		blocked_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(blocked_hotspot)
		return

	var evolve_hotspot := _make_hotspot(EVOLVE_BUTTON)
	evolve_hotspot.gui_input.connect(_on_evolve_gui_input, CONNECT_DEFERRED)
	parent.add_child(evolve_hotspot)
	_value_label(parent, EVOLVE_BUTTON, "EVOLUIR NÚCLEO", 15, HUD_TEXT_COLOR)


## Confirmação DENTRO da própria janela (pedido explícito §16: "Não
## criar uma segunda janela... A confirmação deve acontecer na própria
## janela") — reaproveita a mesma área do botão EVOLUIR NÚCLEO,
## dividida em NÃO (metade esquerda) / SIM (metade direita).
func _build_confirmation_buttons(parent: Control) -> void:
	var half_width: float = EVOLVE_BUTTON.size.x / 2.0
	var no_rect := Rect2(EVOLVE_BUTTON.position.x, EVOLVE_BUTTON.position.y, half_width, EVOLVE_BUTTON.size.y)
	var yes_rect := Rect2(EVOLVE_BUTTON.position.x + half_width, EVOLVE_BUTTON.position.y, half_width, EVOLVE_BUTTON.size.y)

	var no_hotspot := _make_hotspot(no_rect)
	no_hotspot.gui_input.connect(_on_cancel_gui_input, CONNECT_DEFERRED)
	parent.add_child(no_hotspot)
	_value_label(parent, no_rect, "NÃO", 15, HUD_TEXT_COLOR)

	var yes_hotspot := _make_hotspot(yes_rect)
	yes_hotspot.gui_input.connect(_on_confirm_gui_input, CONNECT_DEFERRED)
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


## Guarda contra duplo clique (pedido explícito): limpa
## _pending_confirmation ANTES de chamar o resolver — uma segunda
## chegada do mesmo evento encontraria o estado já normal.
func _on_confirm_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _pending_confirmation:
			return
		_pending_confirmation = false
		var result: Dictionary = InstitutionalConstructionResolver.evolve(KingdomState.kingdom, BUILDING)
		if result["success"]:
			print("[EnergyCorePanel] Núcleo de Energia evoluído com sucesso.")
		else:
			print("[EnergyCorePanel] Evolução bloqueada: %s" % result["reason"])
		refresh()


func _on_close_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred(ENERGY_CORE_HUB_SCENE)


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


## Cobre o texto de exemplo fixo na arte ("+1 Energia Base"/"-3s por
## ponto") com um remendo da MESMA cor do fundo ao redor (nunca
## cinza/translúcido genérico) antes de desenhar o valor dinâmico real
## por cima — pedido explícito §19.
func _patch_and_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var patch := ColorRect.new()
	_anchor_control(patch, rect)
	patch.color = BACKDROP_PATCH_COLOR
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(patch)
	_value_label(parent, rect, text, font_size, color)
