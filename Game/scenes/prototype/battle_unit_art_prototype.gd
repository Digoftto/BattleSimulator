extends Control
## BattleUnitArtPrototype (ART-009)
##
## Protótipo visual ISOLADO — não integrado ao PvE real, não substitui
## CombatReplayView, não referenciado por nenhum sistema de jogo. Não
## toca CombatEngine/CombatState/CombatBoard/PhaseResolver/
## CombatEventBus/cartas oficiais. Geometria do Battlefield vem de
## BattlefieldSlotGeometry (mesmos valores de ART-007/ART-008, nunca
## recalculados); CombatBoard continua sendo a única fonte da posição
## LÓGICA (1-9).
##
## ART-009: em vez de UM multiplicador fixo por carta (ART-007/ART-008),
## este protótipo define uma CAIXA-ALVO máxima (largura x altura) por
## REGIÃO DE PROFUNDIDADE VISUAL (ver DEPTH_REGION_SCALE abaixo — único
## lugar editável, nenhum número mágico espalhado pelo resto do
## arquivo) e deixa o Godot calcular a escala necessária pra cada asset
## caber dentro dela preservando o aspect ratio (nunca deformando,
## nunca preenchendo 100% se o asset for naturalmente menor/mais
## estreito — ver _fit_scale()).
##
## IMPORTANTE (ver relatório da sessão): os 4 PNGs usados aqui
## ("LICH KING.png", "ANSHEE.png", "LICHE INICIADO.png",
## "CEIFADOR CADAVÉRICO.png", em res://../Assets/MVP/) são os MESMOS
## renders frontais (não câmera-de-Battlefield) já usados como
## placeholder em ART-008 — não são "Battle Art" novo. Esta sessão não
## tinha nenhuma ferramenta de geração de imagem disponível pra
## produzir os 4 personagens pedidos na seção 2 do pedido; o usuário
## optou explicitamente por validar a INFRAESTRUTURA (caixa-alvo por
## região, âncora de base, depth sorting) com esses placeholders agora,
## substituindo os PNGs por Battle Art real depois sem mudar este
## código.

## preload() em vez do identificador global "BattlefieldSlotGeometry"
## — mesmo motivo já documentado em combat_replay_view.gd (F-046):
## class_name novo nesta sessão, cache global de classes do Godot só é
## regenerado por uma varredura do Editor, que nunca roda numa
## execução via linha de comando (headless ou janela real).
const SlotGeometry = preload("res://scenes/prototype/battlefield_slot_geometry.gd")

## ---- ÚNICO LUGAR EDITÁVEL: caixas-alvo por Região de profundidade ----
## Índice = SlotGeometry.visual_depth_index() (0 = fileira
## mais LONGE da câmera dentro do próprio bloco, 2 = mais PERTO —
## tamanho segue distância real da câmera, ver comentário em
## battlefield_slot_geometry.gd). Frações da largura do slot (
## SlotGeometry.tile_width_px(side)) do bloco correspondente
## — assim o mesmo conjunto de frações produz caixas proporcionalmente
## coerentes tanto no bloco do jogador (slots maiores/mais perto)
## quanto no do inimigo (slots menores/mais longe), sem precisar de
## uma tabela separada por lado.
const DEPTH_REGION_SCALE: Array[Dictionary] = [
	{"max_w_frac": 0.60, "max_h_frac": 0.95},  # Região 0 — mais longe da câmera
	{"max_w_frac": 0.85, "max_h_frac": 1.35},  # Região 1 — intermediária
	{"max_w_frac": 1.15, "max_h_frac": 1.85},  # Região 2 — mais perto da câmera
]

## Folga vertical entre a base do asset e o centro do slot (fração da
## altura RENDERIZADA do próprio asset) — mesma ideia de "borda mais
## perto da câmera" já validada em ART-007/ART-008, nunca o centro
## bruto do PNG.
const BASE_OFFSET_FRAC: float = 0.10

const ASSET_FILENAMES: Array[String] = [
	"LICH KING.png",
	"ANSHEE.png",
	"LICHE INICIADO.png",
	"CEIFADOR CADAVÉRICO.png",
]

var _slots_visible: bool = true
var _battlefield_aspect: AspectRatioContainer
var _slot_debug_layer: Control
var _units_layer: Control
var _info_label: Label

## filename -> {"texture": AtlasTexture, "aspect": float (largura/altura do conteúdo real)}
var _unit_assets: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_unit_assets()
	_build_scene()
	_rebuild_units()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key_event: InputEventKey = event
	if key_event.keycode == KEY_D:
		_slots_visible = not _slots_visible
		_slot_debug_layer.visible = _slots_visible
		_update_info_label()


## ---- Carregamento dos assets ----
## Mesmo motivo/técnica de ART-008: res://Assets/MVP fica FORA do
## projeto Godot (res://Game), load("res://...") não alcança — leitura
## via caminho absoluto do sistema de arquivos, só pra protótipo.

func _project_root_dir() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	return game_dir.get_base_dir()


func _load_unit_assets() -> void:
	var mvp_dir: String = _project_root_dir() + "/Assets/MVP/"
	for filename: String in ASSET_FILENAMES:
		var image := Image.new()
		var err: Error = image.load(mvp_dir + filename)
		if err != OK:
			push_warning("[ART-009] Falha ao carregar '%s' (err=%d)." % [filename, err])
			continue
		var base_texture := ImageTexture.create_from_image(image)
		var content_rect: Rect2i = _detect_alpha_rect(image)
		var atlas := AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = Rect2(content_rect)
		_unit_assets[filename] = {
			"texture": atlas,
			"aspect": float(content_rect.size.x) / float(content_rect.size.y),
		}


## Retângulo real de conteúdo (alpha > 0) — mesmo princípio de
## CardArtCatalog._detect_used_rect() (ART-006) e do protótipo de
## ART-008, varredura esparsa por transparência real.
func _detect_alpha_rect(image: Image) -> Rect2i:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var step_x: int = max(1, w / 260)
	var step_y: int = max(1, h / 260)
	var min_x: int = w
	var max_x: int = -1
	var min_y: int = h
	var max_y: int = -1

	for y in range(0, h, step_y):
		for x in range(0, w, step_x):
			if image.get_pixel(x, y).a > 0.05:
				min_x = min(min_x, x)
				max_x = max(max_x, x)
				min_y = min(min_y, y)
				max_y = max(max_y, y)

	if max_x < 0:
		return Rect2i(0, 0, w, h)
	return Rect2i(min_x, min_y, max_x - min_x + step_x, max_y - min_y + step_y).intersection(Rect2i(0, 0, w, h))


## ---- Estrutura estática ----

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_battlefield_aspect = AspectRatioContainer.new()
	_battlefield_aspect.ratio = SlotGeometry.BATTLEFIELD_IMAGE_SIZE.x / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.y
	_battlefield_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_battlefield_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_battlefield_aspect)

	var battlefield_texture_rect := TextureRect.new()
	battlefield_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	battlefield_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	battlefield_texture_rect.texture = load("res://assets/art/battlefields/campo_aberto.png")
	_battlefield_aspect.add_child(battlefield_texture_rect)

	_slot_debug_layer = Control.new()
	_slot_debug_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_debug_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battlefield_aspect.add_child(_slot_debug_layer)
	_build_slot_debug_markers()

	_units_layer = Control.new()
	_units_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_units_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battlefield_aspect.add_child(_units_layer)

	_info_label = Label.new()
	_info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info_label.position = Vector2(8, 8)
	_info_label.add_theme_font_size_override("font_size", 14)
	add_child(_info_label)
	_update_info_label()


func _update_info_label() -> void:
	_info_label.text = "ART-009 prototype — caixa-alvo por Região   [D] slots/caixas(%s)" % ("on" if _slots_visible else "off")


## Marcadores de debug: ponto do slot (amarelo) + contorno da caixa-alvo
## da Região correspondente (ciano) — nunca sobre as unidades quando
## desligado (tecla D).
func _build_slot_debug_markers() -> void:
	for side in [0, 1]:
		for position in range(1, 10):
			var center_frac: Vector2 = SlotGeometry.visual_center_frac(side, position)

			var dot := ColorRect.new()
			dot.color = Color(1.0, 0.9, 0.2, 0.6)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dot_half: float = 0.006
			dot.anchor_left = center_frac.x - dot_half
			dot.anchor_right = center_frac.x + dot_half
			dot.anchor_top = center_frac.y - dot_half
			dot.anchor_bottom = center_frac.y + dot_half
			_slot_debug_layer.add_child(dot)

			var region: Dictionary = _region_box_px(side, position)
			var box_w_frac: float = region["max_w"] / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.x / 2.0
			var box_h_frac: float = region["max_h"] / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.y
			var base_y_frac: float = center_frac.y + BASE_OFFSET_FRAC * (region["max_h"] / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.y)

			var outline := _make_box_outline(Color(0.2, 0.9, 1.0, 0.55))
			outline.anchor_left = center_frac.x - box_w_frac
			outline.anchor_right = center_frac.x + box_w_frac
			outline.anchor_top = base_y_frac - box_h_frac
			outline.anchor_bottom = base_y_frac
			_slot_debug_layer.add_child(outline)


func _make_box_outline(color: Color) -> Control:
	var box := Panel.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	box.add_theme_stylebox_override("panel", style)
	return box


## ---- Caixa-alvo por Região (ART-009 seções 5/6) ----

## Caixa-alvo em PIXELS da imagem-fonte pra esta posição — deriva da
## Região de profundidade VISUAL (ver SlotGeometry.
## visual_depth_index) e da largura do slot do lado correspondente.
## Único ponto que lê DEPTH_REGION_SCALE — trocar a tabela no topo do
## arquivo já propaga pra debug, posicionamento e escala.
func _region_box_px(side: int, position: int) -> Dictionary:
	var r: int = SlotGeometry.visual_depth_index(side, position)
	var scale_entry: Dictionary = DEPTH_REGION_SCALE[r]
	var tile_w: float = SlotGeometry.tile_width_px(side)
	return {
		"max_w": tile_w * scale_entry["max_w_frac"],
		"max_h": tile_w * scale_entry["max_h_frac"],
	}


## Escala necessária pra um conteúdo (content_w x content_h) caber
## inteiro dentro de uma caixa (max_w x max_h) SEM deformar — o menor
## dos dois fatores de ajuste vence (ART-009 seção 7: unidade menor
## naturalmente ocupa menos que 100% da caixa, nunca é esticada pra
## preencher).
static func _fit_scale(content_w: float, content_h: float, max_w: float, max_h: float) -> float:
	return min(max_w / content_w, max_h / content_h)


## ---- Unidades ----

func _rebuild_units() -> void:
	for child in _units_layer.get_children():
		child.queue_free()

	# Depth sorting (ART-009 seção 8): mais longe da câmera primeiro,
	# mais perto por último, pra quem está na frente desenhar por cima.
	var entries: Array = []
	for side in [0, 1]:
		for position in range(1, 10):
			entries.append({"side": side, "position": position, "y": SlotGeometry.visual_center_frac(side, position).y})
	entries.sort_custom(func(a, b): return a["y"] < b["y"])

	for entry: Dictionary in entries:
		_place_unit(entry["side"], entry["position"])


func _place_unit(side: int, position: int) -> void:
	var asset_index: int = (side * 9 + position - 1) % ASSET_FILENAMES.size()
	var filename: String = ASSET_FILENAMES[asset_index]
	if not _unit_assets.has(filename):
		return
	var asset: Dictionary = _unit_assets[filename]
	var texture: AtlasTexture = asset["texture"]
	var content_aspect: float = asset["aspect"]

	var region: Dictionary = _region_box_px(side, position)
	var content_w_px: float = texture.region.size.x
	var content_h_px: float = texture.region.size.y
	var scale: float = _fit_scale(content_w_px, content_h_px, region["max_w"], region["max_h"])
	var render_w_px: float = content_w_px * scale
	var render_h_px: float = content_h_px * scale

	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center_frac: Vector2 = SlotGeometry.visual_center_frac(side, position)
	var half_w_frac: float = (render_w_px / 2.0) / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.x
	var h_frac: float = render_h_px / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.y

	# ART-009 seção 4: âncora de BASE — a base real do conteúdo
	# (já recortada pro retângulo alpha, nunca o canvas bruto do PNG)
	# fica perto do centro do slot; a unidade cresce só PRA CIMA a
	# partir daí.
	var base_y_frac: float = center_frac.y + BASE_OFFSET_FRAC * h_frac

	sprite.anchor_left = center_frac.x - half_w_frac
	sprite.anchor_right = center_frac.x + half_w_frac
	sprite.anchor_top = base_y_frac - h_frac
	sprite.anchor_bottom = base_y_frac
	sprite.offset_left = 0.0
	sprite.offset_right = 0.0
	sprite.offset_top = 0.0
	sprite.offset_bottom = 0.0
	sprite.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sprite.grow_vertical = Control.GROW_DIRECTION_BOTH

	_units_layer.add_child(sprite)
