extends Control
## IsometricBattlefieldPrototype (ART-008)
##
## Protótipo visual ISOLADO — não faz parte do fluxo real de combate,
## não é referenciado por CombatReplayView nem por nenhum outro sistema
## de jogo. Existe só pra responder uma pergunta: "os únicos assets de
## unidade em perspectiva isométrica que existem hoje no projeto fazem
## as unidades parecerem posicionadas de verdade no Battlefield?".
##
## NUNCA toca CombatEngine/CombatState/CombatBoard/PhaseResolver/
## CombatEventBus — a geometria do tabuleiro (POSITION_GRID/
## ENEMY_TILE_*/PLAYER_TILE_*) é a MESMA já validada visualmente em
## combat_replay_view.gd (ART-007), duplicada aqui de propósito (não
## importada) porque este é um experimento descartável, isolado do
## código de produção — nenhuma posição lógica nova foi inventada,
## CombatBoard.COLUMN_A/B/C continua sendo a única fonte da posição
## lógica (1-9); o que este arquivo duplica é só a MEDIÇÃO EM PIXELS
## de onde cada posição cai visualmente sobre o PNG do Battlefield.
##
## Assets usados (ver inventário completo no relatório da sessão):
## os 6 únicos PNGs com fundo transparente real (alpha) encontrados no
## projeto pra unidades de Mortos-Vivos, soltos na raiz de
## res://../Assets/MVP/ (fora da pasta Cartas/ — não são as cartas
## oficiais, são renders separados, provavelmente material de
## referência de produção): "LICH KING.png", "ANSHEE.png",
## "CEIFADOR CADAVÉRICO.png", "CULTIST OF PUTREFACTION.png",
## "LICHE INICIADO.png", "ALTAR DA EANIMAÇÃO.png". Nenhum é gerado ou
## alterado aqui — só lidos via caminho absoluto (ficam FORA de
## res://Game, o projeto Godot, então não podem ser carregados por
## load("res://...")) e recortados (AtlasTexture) pro retângulo real
## de conteúdo (alpha > 0), nunca redesenhados.

const BATTLEFIELD_IMAGE_SIZE: Vector2 = Vector2(1536.0, 1024.0)

## ART-007 (combat_replay_view.gd) — mesmos valores, nunca recalculados.
const ENEMY_TILE_ORIGIN: Vector2 = Vector2(863.0, 330.0)
const ENEMY_TILE_E1: Vector2 = Vector2(-65.0, 22.0)
const ENEMY_TILE_E2: Vector2 = Vector2(95.0, 22.0)
const PLAYER_TILE_ORIGIN: Vector2 = Vector2(497.5, 594.0)
const PLAYER_TILE_E1: Vector2 = Vector2(-105.0, 65.0)
const PLAYER_TILE_E2: Vector2 = Vector2(100.0, 37.0)

const POSITION_GRID: Dictionary = {
	1: Vector2i(0, 0), 6: Vector2i(1, 0), 7: Vector2i(2, 0),
	2: Vector2i(0, 1), 5: Vector2i(1, 1), 8: Vector2i(2, 1),
	3: Vector2i(0, 2), 4: Vector2i(1, 2), 9: Vector2i(2, 2),
}

## side*10+position -> index em ASSET_FILENAMES (ciclo simples, ver
## ART-008 secao 5 — "reutilize os mesmos assets").
const ASSET_FILENAMES: Array[String] = [
	"LICH KING.png",
	"ANSHEE.png",
	"CEIFADOR CADAVÉRICO.png",
	"CULTIST OF PUTREFACTION.png",
	"LICHE INICIADO.png",
	"ALTAR DA EANIMAÇÃO.png",
]

## Larguras testadas (A/B/C, seção 7 do pedido) — fração da largura do
## slot isométrico. Trocadas em tempo real com as teclas 1/2/3.
const SCALE_SMALL: float = 0.55
const SCALE_MEDIUM: float = 0.95
const SCALE_LARGE: float = 1.5

var _current_scale: float = SCALE_MEDIUM
var _current_scale_label: String = "B (média)"
var _slots_visible: bool = true

var _battlefield_aspect: AspectRatioContainer
var _slot_debug_layer: Control
var _units_layer: Control
var _info_label: Label

## side*10+position -> textura já recortada pro conteúdo real (alpha).
var _unit_textures: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_unit_textures()
	_build_scene()
	_rebuild_units()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key_event: InputEventKey = event
	match key_event.keycode:
		KEY_1:
			_current_scale = SCALE_SMALL
			_current_scale_label = "A (pequena)"
			_rebuild_units()
		KEY_2:
			_current_scale = SCALE_MEDIUM
			_current_scale_label = "B (média)"
			_rebuild_units()
		KEY_3:
			_current_scale = SCALE_LARGE
			_current_scale_label = "C (grande)"
			_rebuild_units()
		KEY_D:
			_slots_visible = not _slots_visible
			_slot_debug_layer.visible = _slots_visible
			_update_info_label()


## ---- Carregamento dos assets (ART-008 secao 1) ----

## res://Assets/MVP fica FORA do projeto Godot (res://Game) — os PNGs
## nunca passaram pelo pipeline de import do Godot. load("res://...")
## não alcança esse caminho; por isso o carregamento aqui é via
## caminho absoluto do sistema de arquivos (Image.load()), só pra este
## protótipo — nunca o padrão usado em código de produção
## (CardArtCatalog/BattlefieldArtCatalog carregam de dentro de
## res://Game/assets, sempre importado).
func _project_root_dir() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	return game_dir.get_base_dir()


func _load_unit_textures() -> void:
	var mvp_dir: String = _project_root_dir() + "/Assets/MVP/"
	for filename: String in ASSET_FILENAMES:
		if _unit_textures.has(filename):
			continue
		var image := Image.new()
		var err: Error = image.load(mvp_dir + filename)
		if err != OK:
			push_warning("[ART-008] Falha ao carregar '%s' (err=%d) — posição ficará vazia." % [filename, err])
			continue
		var base_texture := ImageTexture.create_from_image(image)
		var content_rect: Rect2i = _detect_alpha_rect(image)
		var atlas := AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = Rect2(content_rect)
		_unit_textures[filename] = atlas


## Retângulo real de conteúdo (alpha > 0), varredura esparsa — o
## mesmo princípio de CardArtCatalog._detect_used_rect() (ART-006),
## mas por ALPHA (estes PNGs têm transparência real), não por brilho.
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


## ---- Estrutura estática (Battlefield real + camadas) ----

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# ART-008: mesmo Battlefield real usado em combate (ART-007) —
	# carregado direto do catálogo importado do projeto (dentro de
	# res://Game), sem depender de nenhum CombatState/batalha real.
	_battlefield_aspect = AspectRatioContainer.new()
	_battlefield_aspect.ratio = BATTLEFIELD_IMAGE_SIZE.x / BATTLEFIELD_IMAGE_SIZE.y
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

	# ART-008 secao 6: identificador de debug FORA do tabuleiro (nunca
	# sobre as unidades) — só instruções de teclado e a escala atual.
	_info_label = Label.new()
	_info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info_label.position = Vector2(8, 8)
	_info_label.add_theme_font_size_override("font_size", 14)
	add_child(_info_label)
	_update_info_label()


func _update_info_label() -> void:
	_info_label.text = "ART-008 prototype — Escala: %s   [1]pequena [2]média [3]grande [D]slots(%s)" % [
		_current_scale_label, "on" if _slots_visible else "off"
	]


## Marcadores de debug de CADA um dos 9 slots visuais por lado — só um
## retângulo fino, nunca compete com as unidades (some com a tecla D).
func _build_slot_debug_markers() -> void:
	for side in [0, 1]:
		for position in range(1, 10):
			var center_frac: Vector2 = _visual_center_frac(side, position)
			var marker := ColorRect.new()
			marker.color = Color(1.0, 0.9, 0.2, 0.35)
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var half: float = 0.012
			marker.anchor_left = center_frac.x - half
			marker.anchor_right = center_frac.x + half
			marker.anchor_top = center_frac.y - half
			marker.anchor_bottom = center_frac.y + half
			_slot_debug_layer.add_child(marker)


## ---- Geometria (idêntica a combat_replay_view.gd ART-007) ----

func _visual_center_frac(side: int, position: int) -> Vector2:
	var grid: Vector2i = POSITION_GRID[position]
	var depth_index: int = grid.x
	var column_index: int = grid.y
	var is_top_cluster: bool = side == 1

	var origin: Vector2
	var e1: Vector2
	var e2: Vector2
	var r: int

	if is_top_cluster:
		origin = ENEMY_TILE_ORIGIN
		e1 = ENEMY_TILE_E1
		e2 = ENEMY_TILE_E2
		r = 2 - depth_index
	else:
		origin = PLAYER_TILE_ORIGIN
		e1 = PLAYER_TILE_E1
		e2 = PLAYER_TILE_E2
		r = depth_index

	var center_px: Vector2 = origin + float(r) * e1 + float(column_index) * e2
	return Vector2(center_px.x / BATTLEFIELD_IMAGE_SIZE.x, center_px.y / BATTLEFIELD_IMAGE_SIZE.y)


func _tile_width_px(side: int) -> float:
	var is_top_cluster: bool = side == 1
	return (ENEMY_TILE_E2 if is_top_cluster else PLAYER_TILE_E2).length()


## ---- Unidades (ART-008 secoes 5/7/8/9) ----

## Reconstrói as 18 unidades do zero (chamado a cada troca de escala —
## simples e barato o bastante pra um protótipo, sem nenhuma lógica de
## "reaproveitar nó" que só importaria numa tela real de jogo).
func _rebuild_units() -> void:
	for child in _units_layer.get_children():
		child.queue_free()

	# ART-008 secao 8: ordem de profundidade — mais longe (menor y)
	# primeiro, mais perto (maior y) por último, pra quem está na
	# frente desenhar por cima de quem está atrás. Nunca a ordem crua
	# de posição lógica.
	var entries: Array = []
	for side in [0, 1]:
		for position in range(1, 10):
			entries.append({"side": side, "position": position, "y": _visual_center_frac(side, position).y})
	entries.sort_custom(func(a, b): return a["y"] < b["y"])

	for entry: Dictionary in entries:
		_place_unit(entry["side"], entry["position"])


func _place_unit(side: int, position: int) -> void:
	var asset_index: int = (side * 9 + position - 1) % ASSET_FILENAMES.size()
	var filename: String = ASSET_FILENAMES[asset_index]
	if not _unit_textures.has(filename):
		return
	var texture: AtlasTexture = _unit_textures[filename]

	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var content_aspect: float = texture.region.size.x / texture.region.size.y

	var center_frac: Vector2 = _visual_center_frac(side, position)
	var sprite_w_px: float = _tile_width_px(side) * _current_scale
	var sprite_h_px: float = sprite_w_px / content_aspect
	var half_w_frac: float = (sprite_w_px / 2.0) / BATTLEFIELD_IMAGE_SIZE.x
	var h_frac: float = sprite_h_px / BATTLEFIELD_IMAGE_SIZE.y

	# ART-008 secao 9: âncora de BASE — o pé real da unidade (já
	# recortado pro retângulo de conteúdo alpha, ver
	# _detect_alpha_rect()) fica sobre o centro do slot, a unidade
	# cresce só PRA CIMA a partir daí. Nunca centraliza pelo retângulo
	# bruto do PNG (que teria espaço vazio acima da cabeça
	# determinando a posição, exatamente o que a seção 9 pede pra
	# evitar).
	var base_y_frac: float = center_frac.y + (0.12 * h_frac)

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
