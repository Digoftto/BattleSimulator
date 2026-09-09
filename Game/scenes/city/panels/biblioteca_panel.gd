extends Control
## BibliotecaPanel (LIBRARY.md)
##
## HUB DE NAVEGAÇÃO da Biblioteca — correção de arquitetura (pedido
## explícito): "A ARTE É A INTERFACE". Library-V1.png preenche a tela
## inteira (mesmo padrão AspectRatioContainer(STRETCH_COVER) já usado
## em CityPanel/CapitalPanel); NENHUMA barra, label ou caixa de filtro
## é desenhada por cima — só hotspots INVISÍVEIS sobre elementos já
## presentes na própria arte (pedido §12: Control transparente, nunca
## um Button visível com texto/fundo).
##
## A grade de Cartas, os filtros e o painel de detalhe (implementados
## numa etapa anterior desta tela) foram REMOVIDOS daqui — essa
## funcionalidade agora vive inteiramente no Bestiário
## (bestiario_panel.gd, tela própria), conforme a correção de
## arquitetura pedida. Nenhum dado/lógica de Carta foi perdido: o
## Bestiário usa exatamente as mesmas fontes (GameDatabase.cards/
## Kingdom.cards).
##
## Hotspot do Bestiário — CORRIGIDO nesta etapa (pedido explícito de
## reavaliação, §6: "manter somente se continuar correspondendo"). A
## mesa/pedestal central usada antes foi reexaminada por zoom e é,
## claramente, uma mesa de CARTOGRAFIA (pergaminho com mapa + esfera
## armilar/globo + compasso) — corresponde ao WORLD ATLAS, não ao
## Bestiário. Nova correspondência encontrada: um dos dois quadros
## emoldurados na estante superior direita (zoom confirmou um esboço de
## uma criatura alada, estilo "estudo naturalista") — o quadro vizinho,
## à direita, mostra uma cena de multidão/batalha, mais compatível com
## LORE ARCHIVE. Ambas são escolhas razoáveis por inspeção visual
## direta, não correspondências confirmadas pela intenção original da
## arte.
##
## World Atlas e Lore Archive — ETAPA 3 (pedido explícito §2): agora
## viram hotspots ATIVOS (Controls invisíveis, mesmo padrão do
## Bestiário), mas nenhuma das duas telas existe no projeto ainda
## (nenhuma cena em res://scenes/, reconfirmado). Pedido explícito:
## "deixar o hotspot preparado... não quebrar a Biblioteca... não
## navegar para uma tela errada" — cada hotspot tem um destino
## constante e claro (WORLD_ATLAS_SCENE_PATH/LORE_ARCHIVE_SCENE_PATH);
## o clique só navega se `ResourceLoader.exists(destino)` for
## verdadeiro. Enquanto a cena não existir, o clique não faz nada (sem
## popup, sem tela errada, sem crash) — só o hover chip aparece,
## confirmando visualmente que o ponto de navegação já está mapeado.
##
## Kingdom Codex: não implementado (pedido explícito §9) — não há
## definição funcional aprovada, e o único candidato visual (os
## gráficos ramificados nos dois atris à esquerda da cena, estilo
## árvore genealógica/tecnológica) é ambíguo demais pra associar sem
## uma decisão de design.
##
## Performance (pedido §8): dispara CardArtCatalog.preload_all() assim
## que a Biblioteca abre — aquece o cache de texturas das 39 Cartas em
## segundo plano (ResourceLoader threaded, nunca bloqueia esta tela)
## enquanto o jogador ainda está aqui decidindo se entra no Bestiário.
## Medido (ver relatório da tarefa): carregar as 39 texturas do disco
## pela primeira vez é o custo dominante (~2s) de abrir o Bestiário do
## zero — não um laço ineficiente no código.

const LIBRARY_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/library_v1.png")
const LIBRARY_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

## Destinos de navegação — mesma convenção de nome de arquivo já usada
## pelo Bestiário (bestiario_panel.tscn). Nenhuma das duas cenas existe
## ainda; ver docstring do topo sobre o comportamento "preparado, mas
## sem destino" enquanto isso não mudar.
const WORLD_ATLAS_SCENE_PATH: String = "res://scenes/city/panels/world_atlas_panel.tscn"
const LORE_ARCHIVE_SCENE_PATH: String = "res://scenes/city/panels/lore_archive_panel.tscn"

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Quadro emoldurado (esboço de criatura alada) na estante superior
## direita — recalibrado por inspeção de pixels (varredura de cor de
## pergaminho isolando os dois quadros da estante, ver relatório da
## tarefa) sobre Library-V1.png (1672x941). Ver docstring do topo sobre
## a incerteza dessa escolha.
const BESTIARIO_HOTSPOT_RECT: Rect2 = Rect2(0.7327, 0.1222, 0.0778, 0.1435)

## World Atlas: mesa central de cartografia (pergaminho-mapa + esfera
## armilar/globo + compasso) — mesma região já identificada numa etapa
## anterior, reconfirmada por inspeção visual.
const WORLD_ATLAS_HOTSPOT_RECT: Rect2 = Rect2(0.30, 0.30, 0.38, 0.38)

## Lore Archive: segundo quadro emoldurado, à direita do quadro do
## Bestiário (cena de multidão/batalha), na mesma estante — recalibrado
## por varredura de pixel (cor de pergaminho isolando os dois quadros,
## ver relatório da tarefa) pra garantir ZERO sobreposição com
## BESTIARIO_HOTSPOT_RECT (que termina em x=0.7327+0.0778=0.8105; este
## começa em x=0.8326 — intervalo de ~2.2% da largura entre os dois).
const LORE_ARCHIVE_HOTSPOT_RECT: Rect2 = Rect2(0.8326, 0.0797, 0.1119, 0.1892)

var _hover_name_container: Control
var _hover_name_label: Label

## FASE 12: node_name (mesma chave já passada a _build_hotspot()) ->
## HotspotGlow — sinal luminoso discreto sobre cada hotspot desta tela
## (mesmo componente já usado na Cidade, ver city_panel.gd).
var _hotspot_glows: Dictionary = {}


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	CardArtCatalog.preload_all(GameDatabase.cards)

	_build_static_structure()
	print("[BibliotecaPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var library_area := Control.new()
	library_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	library_area.clip_contents = true
	add_child(library_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = LIBRARY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	library_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = LIBRARY_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- Hotspots invisíveis de navegação (pedido §2/§12/§13) — arte
	# real, nenhum fundo/borda/texto fixo. Bestiário já existe; World
	# Atlas/Lore Archive ficam preparados com destino claro, só navegam
	# se a cena existir (ver docstring do topo). ---
	_build_hotspot(texture_rect, "Hotspot_Bestiario", BESTIARIO_HOTSPOT_RECT, "Bestiário", "res://scenes/city/panels/bestiario_panel.tscn")
	_build_hotspot(texture_rect, "Hotspot_WorldAtlas", WORLD_ATLAS_HOTSPOT_RECT, "World Atlas", WORLD_ATLAS_SCENE_PATH)
	_build_hotspot(texture_rect, "Hotspot_LoreArchive", LORE_ARCHIVE_HOTSPOT_RECT, "Lore Archive", LORE_ARCHIVE_SCENE_PATH)

	# --- Chip de hover (só aparece ao passar o mouse sobre um hotspot
	# — mesmo padrão Cinzel já usado em Capital/Cidade; nunca um texto
	# fixo sobre a arte). ---
	var hover_chip: Dictionary = _build_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Voltar para a Cidade — mesmo chip/comportamento já usado na
	# Capital (duplicado localmente, nunca importado, mesma regra de
	# sempre deste projeto). ---
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


## Cria um Control invisível sobre `rect` (fração da arte), com hover
## (chip Cinzel já existente) e clique. `scene_path` é o destino
## pretendido — se a cena ainda não existir no projeto, o clique não
## faz nada (nenhuma tela errada, nenhum popup, nenhum crash; pedido
## §2 "deixar o hotspot preparado... não navegar para uma tela
## errada"), mas o hover ainda funciona, confirmando visualmente que o
## ponto de navegação já está mapeado.
func _build_hotspot(parent: Control, node_name: String, rect: Rect2, hover_text: String, scene_path: String) -> void:
	# FASE 12: sinal luminoso discreto sobre o elemento clicável — mesma
	# fábrica reutilizável da Cidade (hotspot_glow.gd), mesma região
	# fracionária já calibrada (rect), nenhuma coordenada nova.
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
			print("[BibliotecaPanel] Hotspot preparado, cena ainda não existe: %s" % scene_path)


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
