extends Control
## LichKingMvpPrototype (ART-010)
##
## Protótipo visual ISOLADO — não integrado ao PvE real, não substitui
## CombatReplayView, não referenciado por nenhum sistema de jogo. Não
## toca CombatEngine/CombatState/CombatBoard/PhaseResolver/
## CombatEventBus/cartas oficiais. Geometria do Battlefield vem de
## BattlefieldSlotGeometry (ART-009, intocado — mesmos valores de
## ART-007/ART-008, nunca recalculados). CombatBoard continua sendo a
## única fonte da posição LÓGICA (1-9).
##
## ART-010: primeiro teste com Battle Art PRODUZIDO especificamente
## pra câmera do Battlefield (4 PNGs reais, res://../Assets/MVP/
## Pelotão/Lich_King_MVP/, com alpha real e conteúdo já enquadrado
## pra visão 3/4 do campo — não são mais os renders frontais de
## ART-008/009). Diferença deliberada em relação a ART-009: UMA única
## caixa-alvo de referência (UNIT_BOX_SCALE abaixo), nunca uma tabela
## de 3 Regiões de profundidade — o pedido explícito desta etapa é
## "não resolver definitivamente a perspectiva ainda", só provar que o
## sistema de Battle Art funciona.
##
## ART-011: os 4 PNGs foram substituídos NO MESMO caminho/mesmos nomes
## de arquivo (Assets/MVP/Pelotão/Lich_King_MVP/lich_king_*.png) por
## uma versão corrigida (alpha real do corpo, não só das bordas) — como
## o carregamento aqui sempre lê do disco em tempo real (nunca cacheia
## nada em .tres/.import), a arte nova já é usada automaticamente, ZERO
## mudança nas funções de carregamento/posicionamento/âncora/depth-sort
## abaixo (todas intocadas desde ART-010, conforme pedido). A única
## adição desta etapa é build_orientation_test_layout() — uma
## visualização de depuração separada (cruz FRONT/RIGHT/BACK/LEFT,
## fora da grade de tiles) só pra confirmar visualmente qual arquivo é
## qual; nunca roda durante o preenchimento normal do tabuleiro
## (_rebuild_units(), inalterado) e nunca decide nada sobre a
## apresentação de produção.

## preload() em vez do identificador global "BattlefieldSlotGeometry"
## — mesmo motivo documentado em battle_unit_art_prototype.gd (ART-009):
## class_name novo, cache global de classes não regenerado fora do
## Editor.
const SlotGeometry = preload("res://scenes/prototype/battlefield_slot_geometry.gd")

## ---- ÚNICA caixa-alvo de referência (ART-010 seção 4) ----
## Fração da largura do slot (SlotGeometry.tile_width_px(side)) do
## bloco correspondente — a MESMA caixa pra todas as 9 posições de um
## lado, nunca uma por Região de profundidade (isso fica pro próximo
## estágio, quando houver mais Battle Art pra calibrar). O bloco do
## jogador (mais perto da câmera) ainda sai maior que o do inimigo
## nos pixels finais — não por um multiplicador de Região, mas porque
## o próprio slot do jogador já É maior na arte do Battlefield (ver
## PLAYER_TILE_E2 vs ENEMY_TILE_E2 em battlefield_slot_geometry.gd).
const UNIT_BOX_SCALE: Dictionary = {"max_w_frac": 0.95, "max_h_frac": 1.55}

## Folga vertical entre a base do asset e o centro do slot (fração da
## altura RENDERIZADA do próprio asset) — mesma convenção de ART-009.
const BASE_OFFSET_FRAC: float = 0.10

const ORIENTATION_FRONT: String = "lich_king_front.png"
const ORIENTATION_RIGHT: String = "lich_king_right.png"
const ORIENTATION_BACK: String = "lich_king_back.png"
const ORIENTATION_LEFT: String = "lich_king_left.png"
const ASSET_FILENAMES: Array[String] = [ORIENTATION_FRONT, ORIENTATION_RIGHT, ORIENTATION_BACK, ORIENTATION_LEFT]

var _slots_visible: bool = false
var _battlefield_aspect: AspectRatioContainer
var _slot_debug_layer: Control
var _units_layer: Control
## ART-011: camada só da visualização de depuração de orientação (ver
## show_orientation_test()) — separada de _units_layer/_slot_debug_layer
## pra nunca interferir no preenchimento normal do tabuleiro.
var _orientation_labels_layer: Control
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
	elif key_event.keycode == KEY_O:
		show_orientation_test()
	elif key_event.keycode == KEY_B:
		show_board_formation()


## ---- Carregamento dos assets ----
## Mesmo motivo/técnica de ART-008/ART-009: res://Assets/MVP fica FORA
## do projeto Godot (res://Game), load("res://...") não alcança —
## leitura via caminho absoluto do sistema de arquivos, só protótipo.

func _project_root_dir() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	return game_dir.get_base_dir()


func _load_unit_assets() -> void:
	var pelotao_dir: String = _project_root_dir() + "/Assets/MVP/Pelotão/Lich_King_MVP/"
	for filename: String in ASSET_FILENAMES:
		var image := Image.new()
		var err: Error = image.load(pelotao_dir + filename)
		if err != OK:
			push_warning("[ART-010] Falha ao carregar '%s' (err=%d)." % [filename, err])
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
## CardArtCatalog._detect_used_rect() (ART-006) e dos protótipos de
## ART-008/ART-009.
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
	_slot_debug_layer.visible = _slots_visible
	_battlefield_aspect.add_child(_slot_debug_layer)
	_build_slot_debug_markers()

	_units_layer = Control.new()
	_units_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_units_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battlefield_aspect.add_child(_units_layer)

	_orientation_labels_layer = Control.new()
	_orientation_labels_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_orientation_labels_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battlefield_aspect.add_child(_orientation_labels_layer)

	# ART-010 seção 11: HUD mínimo, fora do tabuleiro — sem log (este
	# protótipo não reproduz uma batalha, não há eventos a mostrar).
	_info_label = Label.new()
	_info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info_label.position = Vector2(8, 8)
	_info_label.add_theme_font_size_override("font_size", 14)
	add_child(_info_label)
	_update_info_label()


func _update_info_label() -> void:
	_info_label.text = "ART-010/011 Lich King MVP — caixa única   [D] slots(%s)   [O] teste de orientação   [B] tabuleiro" % ("on" if _slots_visible else "off")


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


## ---- Caixa-alvo única (ART-010 seção 4) ----

func _unit_box_px(side: int) -> Dictionary:
	var tile_w: float = SlotGeometry.tile_width_px(side)
	return {
		"max_w": tile_w * UNIT_BOX_SCALE["max_w_frac"],
		"max_h": tile_w * UNIT_BOX_SCALE["max_h_frac"],
	}


static func _fit_scale(content_w: float, content_h: float, max_w: float, max_h: float) -> float:
	return min(max_w / content_w, max_h / content_h)


## ---- Orientação (ART-010 seções 3/9) ----
## Regra de teste, deliberadamente simples e explícita (nenhuma lógica
## de "orientação de combate" real existe ainda — não inventamos
## nenhuma): coluna B (centro) de cada lado usa a orientação que faz
## os dois Exércitos se encararem (inimigo -> FRONT, voltado pro
## jogador; jogador -> BACK, voltado pro inimigo — exatamente a regra
## da seção 9). Colunas A/C usam LEFT/RIGHT só pra exercitar as 4
## orientações numa mesma screenshot (seção 9, "precisamos conseguir
## distinguir visualmente as quatro direções") — não representa
## nenhuma regra de flanco real.
func _orientation_for(side: int, position: int) -> String:
	var grid: Vector2i = SlotGeometry.POSITION_GRID[position]
	var column_index: int = grid.y
	match column_index:
		0:
			return ORIENTATION_LEFT
		2:
			return ORIENTATION_RIGHT
		_:
			return ORIENTATION_FRONT if SlotGeometry.is_top_cluster(side) else ORIENTATION_BACK


## ---- Unidades ----

func _rebuild_units() -> void:
	for child in _units_layer.get_children():
		child.queue_free()

	# Depth sorting — idêntico a ART-008/ART-009, não alterado.
	var entries: Array = []
	for side in [0, 1]:
		for position in range(1, 10):
			entries.append({"side": side, "position": position, "y": SlotGeometry.visual_center_frac(side, position).y})
	entries.sort_custom(func(a, b): return a["y"] < b["y"])

	for entry: Dictionary in entries:
		_place_unit(entry["side"], entry["position"])


func _place_unit(side: int, position: int) -> void:
	var filename: String = _orientation_for(side, position)
	if not _unit_assets.has(filename):
		return
	var asset: Dictionary = _unit_assets[filename]
	var texture: AtlasTexture = asset["texture"]

	var box: Dictionary = _unit_box_px(side)
	var content_w_px: float = texture.region.size.x
	var content_h_px: float = texture.region.size.y
	var scale: float = _fit_scale(content_w_px, content_h_px, box["max_w"], box["max_h"])
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

	# ART-010 seção 8: âncora de BASE — a base real do conteúdo (já
	# recortada pro retângulo alpha) fica perto do centro do slot; a
	# unidade cresce só PRA CIMA a partir daí. Nunca o canvas bruto.
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


## ---- ART-011: visualização de depuração de orientação ----
## Mostra as 4 orientações lado a lado, FORA da grade de tiles (nunca
## uma posição real de CombatBoard) — existe só pra confirmar
## visualmente "qual arquivo é qual" (ART-011 seção 5/11). Os rótulos
## de texto abaixo de cada unidade são debug-only: nunca aparecem em
## show_board_formation() nem em qualquer apresentação de produção.

func show_board_formation() -> void:
	for child in _orientation_labels_layer.get_children():
		child.queue_free()
	_rebuild_units()
	_update_info_label()


func show_orientation_test() -> void:
	for child in _units_layer.get_children():
		child.queue_free()
	for child in _orientation_labels_layer.get_children():
		child.queue_free()

	# Referência única de tamanho pro teste: largura do tile do lado do
	# jogador (mesma constante UNIT_BOX_SCALE de sempre) — o teste de
	# orientação não pertence a nenhum lado específico, então usa um
	# único valor fixo pras 4 unidades, nunca 4 escalas diferentes.
	var reference_tile_w: float = SlotGeometry.tile_width_px(0)

	var arrangement: Array[Dictionary] = [
		{"orientation": ORIENTATION_BACK, "x": 0.5, "y": 0.28, "label": "BACK"},
		{"orientation": ORIENTATION_LEFT, "x": 0.32, "y": 0.55, "label": "LEFT"},
		{"orientation": ORIENTATION_RIGHT, "x": 0.68, "y": 0.55, "label": "RIGHT"},
		{"orientation": ORIENTATION_FRONT, "x": 0.5, "y": 0.82, "label": "FRONT"},
	]
	for entry: Dictionary in arrangement:
		_place_orientation_test_unit(entry, reference_tile_w)

	_info_label.text = "ART-011 teste de orientação — FRONT/RIGHT/BACK/LEFT   [B] voltar ao tabuleiro"


func _place_orientation_test_unit(entry: Dictionary, tile_w: float) -> void:
	var filename: String = entry["orientation"]
	if not _unit_assets.has(filename):
		return
	var asset: Dictionary = _unit_assets[filename]
	var texture: AtlasTexture = asset["texture"]

	var box: Dictionary = {
		"max_w": tile_w * UNIT_BOX_SCALE["max_w_frac"],
		"max_h": tile_w * UNIT_BOX_SCALE["max_h_frac"],
	}
	var content_w_px: float = texture.region.size.x
	var content_h_px: float = texture.region.size.y
	var scale: float = _fit_scale(content_w_px, content_h_px, box["max_w"], box["max_h"])
	var render_w_px: float = content_w_px * scale
	var render_h_px: float = content_h_px * scale

	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var half_w_frac: float = (render_w_px / 2.0) / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.x
	var h_frac: float = render_h_px / SlotGeometry.BATTLEFIELD_IMAGE_SIZE.y
	var x_frac: float = entry["x"]
	var base_y_frac: float = float(entry["y"]) + BASE_OFFSET_FRAC * h_frac

	sprite.anchor_left = x_frac - half_w_frac
	sprite.anchor_right = x_frac + half_w_frac
	sprite.anchor_top = base_y_frac - h_frac
	sprite.anchor_bottom = base_y_frac
	sprite.offset_left = 0.0
	sprite.offset_right = 0.0
	sprite.offset_top = 0.0
	sprite.offset_bottom = 0.0
	sprite.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sprite.grow_vertical = Control.GROW_DIRECTION_BOTH
	_orientation_labels_layer.add_child(sprite)

	var label := Label.new()
	label.text = entry["label"]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = x_frac
	label.anchor_right = x_frac
	label.anchor_top = base_y_frac
	label.anchor_bottom = base_y_frac
	label.offset_left = -60.0
	label.offset_right = 60.0
	label.offset_top = 6.0
	label.offset_bottom = 28.0
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_orientation_labels_layer.add_child(label)
