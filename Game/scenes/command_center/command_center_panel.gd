extends Control
## CommandCenterPanel (F-017, COMMAND_CENTER_UI.md)
##
## HUB VISUAL do Centro de Comando — mesmo princípio arquitetural de
## Academia/Depósito/Biblioteca/Observatório ("A ARTE É A INTERFACE"):
## centro_de_comando.png preenche a tela inteira (AspectRatioContainer
## STRETCH_COVER); nenhuma barra/label/painel permanente por cima — só
## hotspots INVISÍVEIS sobre elementos já presentes na própria arte.
##
## Correspondência visual dos 5 hotspots (inspeção direta de
## centro_de_comando.png, 1672x941 — ver relatório da tarefa):
## - COMANDANTES: bancada/estante superior esquerda (mesa com livros e
##   globo) — Gabinete de Recrutamento + Arquivo Militar (COMMAND_CENTER.md).
## - EXÉRCITOS: mesa circular central com relevo de terreno — elemento
##   mais isolado/dedicado da sala, ecoa a própria arte de
##   "Army Management" (mesa com mapa/miniatura).
## - CAMPO DE PROVA: mesa de trabalho em primeiro plano, canto inferior
##   esquerdo (pergaminhos, velas) — antes sem uso; completa a simetria
##   2x2 com Treinamento (canto inferior direito). Mesa isolada, distinta
##   da mesa central de gestão de forças — combina com "ensaio tático
##   privado" (CAMPO_DE_PROVA.md).
## - LEGADO/HALL: bancada superior direita com mapa de parede emoldurado
##   — ecoa a arte de "Veteran Records" (mesma composição de mesa+mapa).
## - TREINAMENTO: estátuas/bandeiras inferior direita — **hotspot
##   provisório, sem asset dedicado** (auditoria de assets não
##   encontrou nenhuma arte com tema de treino/instrução na pasta
##   Assets/MVP/Construções/). Escolhido por eliminação/simetria com
##   Campo de Prova, não por correspondência temática confirmada — a
##   arte definitiva do Treinamento ainda precisa ser produzida numa
##   etapa futura.
##
## Expansão Administrativa NÃO tem hotspot próprio aqui — a ação
## "Ativar Próximo Recurso Administrativo" vive dentro da tela de
## Comandantes (comandantes_panel.gd).
##
## CORREÇÃO REAL (auditoria pré-pré-alfa): a docstring anterior desta
## seção afirmava que a Progressão Vertical (Nível do prédio) "continua
## usando o popup genérico de Evoluir da própria Cidade... como
## qualquer outra construção" — FALSO, comprovado por clique real
## simulado via Input.parse_input_event() (nunca chamada direta de
## método interno): city_panel.gd::_on_hitbox_gui_input() hoje chama
## _navigate_to_building(), que entra DIRETO nesta tela — o popup
## contextual da Cidade (_update_contextual_panel(), com os botões
## "Abrir"/"Evoluir") está desconectado do clique real desde uma
## mudança arquitetural anterior (só chamado por validações legadas de
## bootstrap.gd, fora do fluxo real do jogador — ver o próprio
## docstring de city_panel.gd::_on_hitbox_gui_input()). Ou seja: a
## Evolução Vertical do CdC era INACESSÍVEL a qualquer jogador real.
## Corrigido com um botão real "Evoluir" nesta própria tela (mesmo
## padrão já usado internamente por capital_panel.gd, "Evoluir
## Capital") — reaproveita EXATAMENTE InstitutionalConstructionResolver.
## evolve()/cost_breakdown() (mesma fonte de verdade de Capital/
## Academia/Núcleo, nenhuma fórmula nova), com HotspotGlow igual aos
## outros 5 hotspots. "Abrir Centro de Comando" (na Cidade) continua
## intocado — os dois caminhos coexistem, nunca um substitui o outro.
##
## Campo de Prova: CORREÇÃO ARQUITETURAL desta etapa — decisão anterior
## (sem hotspot próprio, só um botão futuro na lista de Exércitos) foi
## revertida explicitamente pelo dono do projeto. Ganha hotspot próprio
## no hub, como as demais 4 funções.
##
## World Map Gate NÃO é mais alcançado a partir daqui (correção
## arquitetural: é uma localização própria da Cidade, ver
## WORLD_MAP_GATE.md e city_panel.gd).
##
## Cada tela interna é reaproveitada no MESMO padrão de sempre (nunca
## popup, nunca cena modal) — troca de cena completa via
## change_scene_to_file, com botão "Voltar para o Centro de Comando"
## em cada uma.

const COMMAND_CENTER_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/centro_de_comando.png")
const COMMAND_CENTER_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

const COMANDANTES_SCENE_PATH: String = "res://scenes/command_center/panels/comandantes_panel.tscn"
const EXERCITOS_SCENE_PATH: String = "res://scenes/city/panels/exercitos_panel.tscn"
const CAMPO_DE_PROVA_SCENE_PATH: String = "res://scenes/command_center/panels/campo_de_prova_panel.tscn"
const TREINAMENTO_SCENE_PATH: String = "res://scenes/command_center/panels/treinamento_panel.tscn"
const LEGADO_SCENE_PATH: String = "res://scenes/command_center/panels/legado_panel.tscn"

## Bancada/estante superior esquerda (mesa com livros e globo).
const COMANDANTES_HOTSPOT_RECT: Rect2 = Rect2(0.02, 0.22, 0.27, 0.32)
## Mesa circular central com relevo de terreno.
const EXERCITOS_HOTSPOT_RECT: Rect2 = Rect2(0.34, 0.38, 0.33, 0.44)
## Mesa de trabalho em primeiro plano, canto inferior esquerdo.
const CAMPO_DE_PROVA_HOTSPOT_RECT: Rect2 = Rect2(0.0, 0.60, 0.20, 0.38)
## Bancada superior direita com mapa de parede emoldurado.
const LEGADO_HOTSPOT_RECT: Rect2 = Rect2(0.70, 0.22, 0.28, 0.32)
## Estátuas/bandeiras inferior direita — provisório, ver docstring do topo.
const TREINAMENTO_HOTSPOT_RECT: Rect2 = Rect2(0.76, 0.60, 0.22, 0.38)

var _hover_name_container: Control
var _hover_name_label: Label

## Auditoria pré-pré-alfa: HotspotGlow (engine/presentation/hotspot_glow.gd)
## já é o sinal luminoso reutilizável usado em Cidade/Biblioteca/
## Academia/Capital/Depósito/Núcleo de Energia/Observatório/World Map
## Gate — nunca foi ligado ao Centro de Comando (achado real: nenhuma
## referência a HotspotGlow existia neste arquivo). Corrigido reusando
## exatamente o mesmo componente/padrão (Dictionary node_name -> HotspotGlow,
## attach_to_region() na mesma região fracionária já calibrada dos 5
## hotspots, toggle HOVER/AVAILABLE nos mesmos handlers mouse_entered/
## mouse_exited já existentes) — nenhuma segunda implementação criada.
var _hotspot_glows: Dictionary = {}

## Feedback do botão "Evoluir" (F-019, mesmo padrão já usado em outros
## painéis — nunca só um print() que o jogador nunca vê).
var _evolve_status_text: String = ""


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[CommandCenterPanel] Pronto.")


func refresh() -> void:
	_clear_children(self)
	_build_static_structure()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var command_center_area := Control.new()
	command_center_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	command_center_area.clip_contents = true
	add_child(command_center_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = COMMAND_CENTER_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	command_center_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = COMMAND_CENTER_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- 5 hotspots invisíveis, cada um sobre o elemento visual
	# correspondente já presente na arte (ver docstring do topo). ---
	_build_hotspot(texture_rect, "Hotspot_Comandantes", COMANDANTES_HOTSPOT_RECT, "Comandantes", COMANDANTES_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Exercitos", EXERCITOS_HOTSPOT_RECT, "Exércitos", EXERCITOS_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_CampoDeProva", CAMPO_DE_PROVA_HOTSPOT_RECT, "Campo de Prova", CAMPO_DE_PROVA_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Legado", LEGADO_HOTSPOT_RECT, "Legado / Hall", LEGADO_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_Treinamento", TREINAMENTO_HOTSPOT_RECT, "Treinamento", TREINAMENTO_SCENE_PATH)

	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para a Cidade"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_chip_gui_input)
	add_child(back_container)

	_build_evolve_chip()


## Evolução Vertical do CdC (Progressão do Nível do prédio, custo em
## Recursos) — NUNCA confundir com Expansão Administrativa (Cargo
## Ativo/Vaga Reserva, custo em PG, dentro de Comandantes). Mesma fonte
## de verdade de Capital/Academia/Núcleo: InstitutionalConstructionResolver.
## evolve()/cost_breakdown(), FORMULAS.md — nenhum valor/fórmula nova.
## Canto oposto ao "Voltar para a Cidade", mesmo padrão visual de chip,
## com HotspotGlow (mesmo componente dos outros 5 hotspots desta tela).
func _build_evolve_chip() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = kingdom.command_center_level
	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO, current_level + 1)
	# Mesmo mapeamento de rótulos já usado em city_panel.gd
	# (RAW_RESOURCE_LABELS), duplicado localmente por convenção do
	# projeto — nunca importado entre telas.
	var raw_resource_labels: Dictionary = {"ferro_negro": "Ferro Negro", "cristais_arcanos": "Cristais Arcanos", "essencia_vital": "Essência Vital"}
	var cost_text: String = ", ".join(costs.keys().map(func(k: String) -> String: return "%s: %d" % [raw_resource_labels.get(k, k), costs[k]]))

	var evolve_chip: Dictionary = _build_chip()
	var container: Control = evolve_chip["container"]
	var label: Label = evolve_chip["label"]
	label.text = "Evoluir (Nível %d → %d | %s)" % [current_level, current_level + 1, cost_text]
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.size = container.get_combined_minimum_size()
	container.position = Vector2(-16 - container.size.x, 16)
	container.gui_input.connect(_on_evolve_chip_gui_input, CONNECT_DEFERRED)
	add_child(container)

	# attach_to_region() posiciona relativo ao PARENT informado — usar o
	# próprio chip como parent (região 0..1 = seu próprio retângulo)
	# evita qualquer matemática manual de pixel/viewport (causa raiz já
	# documentada do bug de desalinhamento do aro de seleção da Academia
	# nesta mesma auditoria — nunca repetir esse padrão).
	preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(container, Rect2(0.0, 0.0, 1.0, 1.0), 12.0)

	if _evolve_status_text != "":
		var status_label := Label.new()
		status_label.text = _evolve_status_text
		status_label.add_theme_font_override("font", HUD_FONT)
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.add_theme_color_override("font_color", Color(0.92, 0.45, 0.40))
		status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		status_label.position = Vector2(-16 - status_label.get_combined_minimum_size().x, 16 + container.size.y + 4)
		add_child(status_label)


func _on_evolve_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var result: Dictionary = InstitutionalConstructionResolver.evolve(KingdomState.kingdom, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
		if not result["success"]:
			_evolve_status_text = "Não foi possível evoluir: %s" % result["reason"]
		else:
			_evolve_status_text = ""
		refresh()


func _build_chip() -> Dictionary:
	var chip := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.10)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	chip.add_child(label)

	return {"container": chip, "label": label}


func _build_hotspot(parent: Control, node_name: String, rect: Rect2, hover_text: String, scene_path: String) -> void:
	# Mesma fábrica reutilizável já usada em Cidade/Biblioteca/Academia/
	# Capital/Depósito/Núcleo de Energia/Observatório/World Map Gate —
	# mesma região fracionária (rect) já calibrada para o hotspot real.
	_hotspot_glows[node_name] = preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(parent, rect)

	var hotspot := Control.new()
	hotspot.name = node_name
	hotspot.anchor_left = rect.position.x
	hotspot.anchor_top = rect.position.y
	hotspot.anchor_right = rect.position.x + rect.size.x
	hotspot.anchor_bottom = rect.position.y + rect.size.y
	hotspot.offset_left = 0.0
	hotspot.offset_top = 0.0
	hotspot.offset_right = 0.0
	hotspot.offset_bottom = 0.0
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.gui_input.connect(_on_hotspot_gui_input.bind(scene_path))
	hotspot.mouse_entered.connect(_on_hotspot_mouse_entered.bind(hotspot, hover_text, node_name))
	hotspot.mouse_exited.connect(_on_hotspot_mouse_exited.bind(node_name))
	parent.add_child(hotspot)


func _on_hotspot_gui_input(event: InputEvent, scene_path: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file.call_deferred(scene_path)
		else:
			print("[CommandCenterPanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


func _on_hotspot_mouse_entered(hotspot: Control, hover_text: String, node_name: String = "") -> void:
	if _hotspot_glows.has(node_name):
		_hotspot_glows[node_name].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.HOVER)
	_hover_name_label.text = hover_text
	var chip_size: Vector2 = _hover_name_container.get_combined_minimum_size()
	_hover_name_container.size = chip_size

	var hotspot_rect: Rect2 = hotspot.get_global_rect()
	var x: float = hotspot_rect.position.x + hotspot_rect.size.x / 2.0 - chip_size.x / 2.0
	var y: float = hotspot_rect.position.y + hotspot_rect.size.y / 2.0 - chip_size.y / 2.0

	_hover_name_container.global_position = Vector2(x, y)
	_hover_name_container.visible = true


func _on_hotspot_mouse_exited(node_name: String = "") -> void:
	if _hotspot_glows.has(node_name):
		_hotspot_glows[node_name].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.AVAILABLE)
	_hover_name_container.visible = false


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
