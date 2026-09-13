extends Control
## BestiarioPanel (LIBRARY.md — Bestiário, TELA PRÓPRIA)
##
## ETAPA (continuação após crash do processo anterior — nenhum trabalho
## desta etapa existia no arquivo antes desta edição): implementa os 4
## itens que a etapa anterior tinha deixado deliberadamente de fora
## (ver histórico abaixo, pedido §13):
##
## 1. Filtro funcional — mesmo vocabulário/fonte da Academia (Salão dos
##    Artífices, academia_producao_panel.gd): Facção/Tipo/Raridade
##    (valores idênticos, CardResource.faction/card_class/rarity) + busca
##    por nome. Controles reais (LineEdit/OptionButton) na faixa de 6
##    caixas já reservada na própria arte (LIBRARY-Bestiary-windows.png,
##    banda logo abaixo do título "BESTIÁRIO" — varredura de pixel
##    confirmou a banda entre y≈0.145 e y≈0.225; as 6 subdivisões da arte
##    são só decorativas/sem rótulo, então os controles ocupam a faixa
##    inteira como uma barra única, não 6 caixas isoladas).
## 2. Lista sem duplicação — inalterado (GameDatabase.cards já é o
##    catálogo único, 39 Cartas, nenhuma segunda fonte); o filtro só
##    reduz o Array antes de popular a grade, nunca duplica entradas.
## 3. Ficha textual completa da Carta selecionada: Nome, Facção, Classe,
##    Tipo, Raridade, Tier, Atributos (ATK/HP/ESC), Característica de
##    Unidade (Tier I) e Habilidades (Tier III/V) — nome + descrição real
##    via GameDatabase.traits_by_name / GameDatabase.abilities_by_name
##    (os mesmos índices que o motor de Combate usa; nenhum texto novo
##    inventado). "Lore" NÃO é exibido: não existe nenhum campo de lore
##    em CardResource/AbilityResource/UnitTraitResource hoje — inventar
##    esse texto violaria a regra do projeto de nunca inventar dado
##    ausente; fica como decisão de design em aberto, não implementado.
## 4. Receita real: CardResource.recipe_ingredients — o MESMO campo que
##    AcademyResolver lê pra resolver Produção (nenhuma segunda lista de
##    receita, nenhuma fórmula genérica). Cartas Comuns (Array vazio)
##    mostram "produzida direto por Fragmentos", igual à regra documentada
##    no próprio campo.
## 5. Visualização ampliada + "clique fora fecha": portado do MESMO padrão
##    já usado em academia_producao_panel.gd (_build_card_zoom_overlay) —
##    overlay (backdrop + carta centralizada) sobre esta MESMA tela,
##    nunca uma cena nova; clicar no backdrop ou na própria carta ampliada
##    fecha o overlay e volta pro Bestiário (nunca troca de cena).
##
## Histórico da etapa anterior (preservado sem alteração de comportamento):
##
## Asset definitivo: LIBRARY-Bestiary-windows.png (paisagem, 1536x1024).
## Import: compress/mode=0 (Lossless), process/size_limit=0, sem mipmap.
## O título "BESTIÁRIO" já está desenhado na própria arte — nenhum texto
## extra desenhado por cima.
##
## Mesmo padrão arquitetural de sempre (CityPanel/CapitalPanel/
## BibliotecaPanel): imagem de fundo real dentro de um
## AspectRatioContainer preservando a proporção — SEM compartilhar
## código com biblioteca_panel.gd/capital_panel.gd/academia_producao_panel.gd
## (reaproveita o PADRÃO/vocabulário, nunca o código-fonte).
##
## Fonte de dados: EXATAMENTE a mesma da Biblioteca — GameDatabase.cards
## (catálogo, 39 Cartas) + Kingdom.cards (cópias possuídas, campo .tier
## de cada cópia) — nenhuma segunda lista/banco de Cartas, nenhuma
## mecânica de posse nova.
##
## Reaproveita BattleCardView (mesmo componente já usado na Biblioteca e
## no Battlefield) para a arte real de cada Carta.

const BESTIARY_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/library_bestiary_windows.png")
const BESTIARY_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.62, 0.62, 0.60)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 4
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2
const HUD_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_ACCENT_FAVORITE: Color = Color(0.95, 0.80, 0.35)

## Painéis recalibrados por varredura de pixel dourado (bordas dos dois
## painéis) sobre LIBRARY-Bestiary-windows.png (1536x1024).
const GRID_PANEL_RECT: Rect2 = Rect2(0.0892, 0.2646, 0.5332, 0.5879)
const DETAIL_PANEL_RECT: Rect2 = Rect2(0.6556, 0.2646, 0.2611, 0.5879)

## Faixa de 6 caixas reservada na própria arte, logo abaixo do título —
## recalibrada nesta etapa por varredura de pixel (banda clara entre a
## borda dourada inferior do título e a borda dourada superior dos dois
## painéis, ver docstring do topo). Ocupa a mesma largura combinada dos
## dois painéis abaixo (mesmas bordas esquerda/direita do enquadramento).
const FILTER_STRIP_RECT: Rect2 = Rect2(0.0892, 0.1465, 0.8275, 0.0762)

const GRID_CELL_MIN_WIDTH: float = 150.0
const GRID_CELL_SPACING: float = 10.0

## Mesmos valores/vocabulário do filtro de Produção da Academia
## (academia_producao_panel.gd, TIPO_VALUES/RARIDADE_VALUES) — nunca uma
## segunda lista de classificação inventada pro Bestiário.
const FACCAO_VALUES: Array[String] = ["(todas)", "Império", "Natureza", "Mortos-Vivos"]
const TIPO_VALUES: Array[String] = ["(todas)", "Corpo a Corpo", "À Distância", "Mago", "Suporte", "Barreira", "Máquina de Guerra"]
const RARIDADE_VALUES: Array[String] = ["(todas)", "Comum", "Rara", "Épica", "Lendária"]

var _grid_area: Control
var _grid_scroll: ScrollContainer
var _grid: GridContainer
var _selected_card_name: String = ""
var _last_scroll_value: float = 0.0

var _filter_faction: String = "(todas)"
var _filter_class: String = "(todas)"
var _filter_rarity: String = "(todas)"
var _search_text: String = ""
var _filtered_cards: Array[CardResource] = []

## Visão ampliada temporária (overlay sobre a própria tela — nunca uma
## cena nova), mesmo padrão de academia_producao_panel.gd. Fecha ao
## clicar fora (backdrop) ou na própria carta ampliada, voltando pro
## Bestiário (nunca troca de cena).
var _card_zoom_open: bool = false

## Dessaturação real (não um tint por multiplicação) das Cartas ainda não
## possuídas. Um único ShaderMaterial, construído uma vez, reaproveitado
## por todas as células.
var _grayscale_material: ShaderMaterial


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_build_grayscale_material()
	refresh()
	print("[BestiarioPanel] Pronto. Cartas no catálogo: %d" % GameDatabase.cards.size())


func _build_grayscale_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), tex_color.a);
}
"""
	_grayscale_material = ShaderMaterial.new()
	_grayscale_material.shader = shader


func refresh() -> void:
	if _grid_scroll != null:
		_last_scroll_value = _grid_scroll.scroll_vertical
	_refresh_filtered_cards()
	_clear_children(self)
	_build_static_structure()
	_restore_scroll_position.call_deferred()


func _restore_scroll_position() -> void:
	if _grid_scroll != null:
		_grid_scroll.scroll_vertical = _last_scroll_value


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var bestiary_area := Control.new()
	bestiary_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	bestiary_area.clip_contents = true
	add_child(bestiary_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = BESTIARY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	bestiary_area.add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = BESTIARY_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	# --- Título: nenhum label novo — "BESTIARY" já está desenhado na
	# própria arte (ver docstring do topo). ---

	_build_filter_bar(texture_rect)
	_build_grid_area(texture_rect)
	_build_detail_area(texture_rect)

	# --- Voltar para a Biblioteca — mesmo chip Cinzel já usado nas
	# outras telas (duplicado localmente, nunca importado). ---
	var back_chip: Dictionary = _build_chip()
	var back_container: Control = back_chip["container"]
	var back_label: Label = back_chip["label"]
	back_label.text = "Voltar para a Biblioteca"
	back_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_container.position = Vector2(16, 16)
	back_container.size = back_container.get_combined_minimum_size()
	back_container.gui_input.connect(_on_back_chip_gui_input)
	add_child(back_container)

	# --- Visão ampliada (overlay sobre esta mesma tela) — construída por
	# último, sempre por cima de tudo o mais. ---
	if _card_zoom_open and _selected_card_name != "":
		var zoom_template: CardResource = GameDatabase.get_card(_selected_card_name)
		if zoom_template != null:
			var kingdom: Kingdom = KingdomState.kingdom
			var zoom_is_owned: bool = _owned_card_names(kingdom).has(_selected_card_name)
			_build_card_zoom_overlay(zoom_template, zoom_is_owned)


## Filtro funcional (pedido): mesma fonte/vocabulário de classificação
## já usado pela Academia (CardResource.faction/card_class/rarity) —
## nenhuma segunda taxonomia inventada. Recalculado a cada mudança;
## a busca por nome reconstrói só a grade (preserva o foco do LineEdit),
## os outros 3 filtros disparam refresh() completo (mesma solução já
## usada em academia_producao_panel.gd).
func _refresh_filtered_cards() -> void:
	_filtered_cards.clear()
	var search_lower: String = _search_text.to_lower()

	for card: CardResource in GameDatabase.cards:
		if _filter_faction != "(todas)" and card.faction != _filter_faction:
			continue
		if _filter_class != "(todas)" and card.card_class != _filter_class:
			continue
		if _filter_rarity != "(todas)" and card.rarity != _filter_rarity:
			continue
		if search_lower != "" and not card.card_name.to_lower().contains(search_lower):
			continue
		_filtered_cards.append(card)


func _build_filter_bar(texture_rect: TextureRect) -> void:
	var bar_area := Control.new()
	bar_area.anchor_left = FILTER_STRIP_RECT.position.x
	bar_area.anchor_top = FILTER_STRIP_RECT.position.y
	bar_area.anchor_right = FILTER_STRIP_RECT.position.x + FILTER_STRIP_RECT.size.x
	bar_area.anchor_bottom = FILTER_STRIP_RECT.position.y + FILTER_STRIP_RECT.size.y
	bar_area.offset_left = 0.0
	bar_area.offset_top = 0.0
	bar_area.offset_right = 0.0
	bar_area.offset_bottom = 0.0
	texture_rect.add_child(bar_area)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	bar_area.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	margin.add_child(hbox)

	var search := _styled_line_edit("Buscar Carta...")
	search.text = _search_text
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.size_flags_stretch_ratio = 2.0
	search.text_changed.connect(_on_search_text_changed, CONNECT_DEFERRED)
	hbox.add_child(search)

	var faccao_option := _styled_option_button(FACCAO_VALUES, _filter_faction)
	faccao_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	faccao_option.item_selected.connect(_on_faccao_selected, CONNECT_DEFERRED)
	hbox.add_child(faccao_option)

	var tipo_option := _styled_option_button(TIPO_VALUES, _filter_class)
	tipo_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tipo_option.item_selected.connect(_on_tipo_selected, CONNECT_DEFERRED)
	hbox.add_child(tipo_option)

	var raridade_option := _styled_option_button(RARIDADE_VALUES, _filter_rarity)
	raridade_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raridade_option.item_selected.connect(_on_raridade_selected, CONNECT_DEFERRED)
	hbox.add_child(raridade_option)


func _on_search_text_changed(new_text: String) -> void:
	_search_text = new_text
	_refresh_filtered_cards()
	_rebuild_grid_only()


func _on_faccao_selected(index: int) -> void:
	_filter_faction = FACCAO_VALUES[index]
	refresh()


func _on_tipo_selected(index: int) -> void:
	_filter_class = TIPO_VALUES[index]
	refresh()


func _on_raridade_selected(index: int) -> void:
	_filter_rarity = RARIDADE_VALUES[index]
	refresh()


## Grade rolável das Cartas filtradas (pedido §1/§2) — GameDatabase.cards
## continua sendo a única fonte (nenhuma duplicação); o filtro só reduz
## o Array antes de popular.
func _build_grid_area(texture_rect: TextureRect) -> void:
	_grid_area = Control.new()
	_grid_area.anchor_left = GRID_PANEL_RECT.position.x
	_grid_area.anchor_top = GRID_PANEL_RECT.position.y
	_grid_area.anchor_right = GRID_PANEL_RECT.position.x + GRID_PANEL_RECT.size.x
	_grid_area.anchor_bottom = GRID_PANEL_RECT.position.y + GRID_PANEL_RECT.size.y
	_grid_area.offset_left = 0.0
	_grid_area.offset_top = 0.0
	_grid_area.offset_right = 0.0
	_grid_area.offset_bottom = 0.0
	_grid_area.clip_contents = true
	texture_rect.add_child(_grid_area)

	_grid_scroll = ScrollContainer.new()
	_grid_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid_area.add_child(_grid_scroll)
	_style_scrollbar(_grid_scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_grid_scroll.add_child(margin)

	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", GRID_CELL_SPACING)
	_grid.add_theme_constant_override("v_separation", GRID_CELL_SPACING)
	_grid.columns = 4
	margin.add_child(_grid)

	_populate_grid()

	_grid_area.resized.connect(_update_grid_columns)
	_update_grid_columns.call_deferred()


## Separado de _build_grid_area() pra permitir repopular só o conteúdo
## (mudança de busca) sem reconstruir Scroll/GridContainer — mesma
## técnica de academia_producao_panel.gd (_rebuild_lista_cartas_only).
func _populate_grid() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var owned: Dictionary = _owned_card_names(kingdom)
	# Ordem estável: a mesma de GameDatabase.cards (o catálogo real),
	# nunca reordenada — só filtrada.
	for card: CardResource in _filtered_cards:
		_grid.add_child(_build_card_cell(card, owned.has(card.card_name), kingdom))

	if _filtered_cards.is_empty():
		var empty_label := _make_label("Nenhuma carta encontrada.", 13, HUD_MUTED_COLOR)
		_grid.add_child(empty_label)


func _rebuild_grid_only() -> void:
	if _grid == null or not is_instance_valid(_grid):
		return
	_clear_children(_grid)
	_populate_grid()


## Recalculado a cada resize (nunca fixo) — mesma técnica já usada em
## biblioteca_panel.gd.
func _update_grid_columns() -> void:
	if _grid == null or _grid_area == null:
		return
	var available_width: float = _grid_area.size.x - 20.0
	var columns: int = maxi(1, int(available_width / (GRID_CELL_MIN_WIDTH + GRID_CELL_SPACING)))
	_grid.columns = columns


func _build_card_cell(card: CardResource, is_owned: bool, kingdom: Kingdom) -> Control:
	var cell_height: float = GRID_CELL_MIN_WIDTH / BattleCardView.CARD_ASPECT_RATIO
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(GRID_CELL_MIN_WIDTH, 0)
	cell.add_theme_constant_override("separation", 2)

	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(GRID_CELL_MIN_WIDTH, cell_height)
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	card_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_slot.gui_input.connect(_on_card_cell_gui_input.bind(card.card_name), CONNECT_DEFERRED)
	cell.add_child(card_slot)

	var card_view := BattleCardView.new()
	card_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(card_view)
	card_view.set_card(card)
	card_view.set_stats(card.atk, card.hp, card.esc)
	card_view.set_compact(true)

	# CORREÇÃO (clique no catálogo não chegava a card_slot.gui_input):
	# BattleCardView._build() monta internamente um AspectRatioContainer
	# + Control (_card_body) + TextureRect (portrait) — nenhum deles tem
	# mouse_filter definido, então herdam o padrão do Control base
	# (MOUSE_FILTER_STOP; só Label sobrescreve isso pra IGNORE). Colocar
	# card_view.mouse_filter = IGNORE (acima) só afasta o CardView em SI
	# do caminho do evento — não é herdado pelos filhos dele. Como
	# `portrait` cobre quase toda a área visível da carta e é o nó mais
	# profundo sob o cursor, ele intercepta e para a propagação do
	# clique ali mesmo, antes de subir até card_slot (o Control pai que
	# realmente tem o gui_input conectado). Correção localizada (só
	# aqui, nunca em battle_card_view.gd — esse arquivo é compartilhado
	# com Battlefield/Academia/CombatReplayView): força IGNORE
	# recursivamente em toda a árvore interna do card_view construído
	# pra esta célula, garantindo que o clique sempre suba até
	# card_slot, em qualquer ponto da carta.
	_force_ignore_mouse_recursive(card_view)

	# Pedido §5/§6: possuída -> cores normais; não possuída -> escala
	# de cinza real, preservando silhueta/identidade.
	card_view.portrait.material = null if is_owned else _grayscale_material

	if card.card_name == _selected_card_name:
		var highlight := Panel.new()
		highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = HUD_ACCENT_FAVORITE
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		highlight.add_theme_stylebox_override("panel", style)
		card_slot.add_child(highlight)

	# Pedido §7: cópias possuídas por Tier — só exibida quando possuída.
	if is_owned:
		var tier_counts: Dictionary = _tier_counts_for_card(kingdom, card.card_name)
		var tier_label := _make_label(
			"T1:%d T2:%d T3:%d T4:%d T5:%d" % [
				tier_counts[1], tier_counts[2], tier_counts[3], tier_counts[4], tier_counts[5]
			],
			10, HUD_ACCENT
		)
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		cell.add_child(tier_label)

	return cell


## Ver comentário em _build_card_cell(): sem isto, o TextureRect
## `portrait` (e demais Controls internos sem mouse_filter próprio) de
## BattleCardView herdam o padrão MOUSE_FILTER_STOP do Control base e
## capturam o clique antes que ele suba até o Control pai que escuta
## gui_input. Não altera battle_card_view.gd (compartilhado pelo
## Battlefield/Academia/CombatReplayView) — só a árvore já construída
## para esta célula específica do Bestiário.
func _force_ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_force_ignore_mouse_recursive(child)


func _owned_card_names(kingdom: Kingdom) -> Dictionary:
	var owned: Dictionary = {}
	for card: CardResource in kingdom.cards:
		owned[card.card_name] = true
	return owned


## Mesma fonte/lógica já usada pela Biblioteca (Kingdom.cards, campo
## .tier de cada cópia possuída) — nenhuma mecânica de posse nova.
func _tier_counts_for_card(kingdom: Kingdom, card_name: String) -> Dictionary:
	var counts: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for card: CardResource in kingdom.cards:
		if card.card_name == card_name:
			counts[card.tier] = counts.get(card.tier, 0) + 1
	return counts


## Painel de detalhe: ficha textual completa da Carta selecionada
## (pedido §3) + receita real (pedido §4) + clique -> visão ampliada
## (pedido §5). Enquanto nenhuma carta estiver selecionada, o painel
## fica vazio — sem texto de instrução (integrado à arte, que já desenha
## o painel vazio ali).
func _build_detail_area(texture_rect: TextureRect) -> void:
	var detail_area := Control.new()
	detail_area.anchor_left = DETAIL_PANEL_RECT.position.x
	detail_area.anchor_top = DETAIL_PANEL_RECT.position.y
	detail_area.anchor_right = DETAIL_PANEL_RECT.position.x + DETAIL_PANEL_RECT.size.x
	detail_area.anchor_bottom = DETAIL_PANEL_RECT.position.y + DETAIL_PANEL_RECT.size.y
	detail_area.offset_left = 0.0
	detail_area.offset_top = 0.0
	detail_area.offset_right = 0.0
	detail_area.offset_bottom = 0.0
	detail_area.clip_contents = true
	texture_rect.add_child(detail_area)

	if _selected_card_name == "":
		return

	var template: CardResource = GameDatabase.get_card(_selected_card_name)
	if template == null:
		return

	var kingdom: Kingdom = KingdomState.kingdom
	var is_owned: bool = _owned_card_names(kingdom).has(_selected_card_name)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	detail_area.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_style_scrollbar(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)
	# ScrollContainer nunca estica o filho pra sua largura sozinho (mesma
	# causa raiz já documentada em academia_producao_panel.gd) — força a
	# largura mínima do VBoxContainer a acompanhar o scroll real.
	scroll.resized.connect(_on_detail_scroll_resized.bind(scroll, vbox))
	_on_detail_scroll_resized(scroll, vbox)

	var enlarged_width: float = 170.0
	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(enlarged_width, enlarged_width / BattleCardView.CARD_ASPECT_RATIO)
	card_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	card_slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_slot.gui_input.connect(_on_detail_card_gui_input)
	vbox.add_child(card_slot)

	var enlarged_view := BattleCardView.new()
	enlarged_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	enlarged_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(enlarged_view)
	enlarged_view.set_card(template)
	enlarged_view.set_stats(template.atk, template.hp, template.esc)
	enlarged_view.set_compact(false)
	enlarged_view.portrait.material = null if is_owned else _grayscale_material

	vbox.add_child(_make_centered_label(template.card_name, 16, HUD_TEXT_COLOR))

	var identity_text: String = "%s — %s" % [template.faction, template.card_class]
	if template.card_type != "":
		identity_text += " (%s)" % template.card_type
	vbox.add_child(_make_centered_label(identity_text, 12, HUD_ACCENT))
	vbox.add_child(_make_centered_label("%s — Tier %d" % [template.rarity, template.tier], 12, HUD_TEXT_COLOR))
	vbox.add_child(_make_centered_label("ATK %d   HP %d   ESC %d" % [template.atk, template.hp, template.esc], 12, HUD_TEXT_COLOR))

	# Auditoria pré-pré-alfa: Energia/Soldo estavam ausentes do Bestiário
	# (só existiam no Editor de Exército) — mesma fonte de verdade já usada
	# em toda parte (ENERGY.md/SOLDO.md via EnergyArmy.card_energy()/
	# Soldo.cost_for_rarity(), nunca recalculado aqui), mesma linguagem
	# visual desta ficha (linha centralizada, cor de destaque), evitando
	# uma terceira implementação independente.
	vbox.add_child(_make_centered_label(
		"Energia %d   Soldo %d" % [EnergyArmy.card_energy(template.tier), Soldo.cost_for_rarity(template.rarity)],
		12, HUD_ACCENT
	))

	# Característica de Unidade (Tier I) — ABILITIES.md é a autoridade;
	# nome + descrição real via GameDatabase.traits_by_name (mesmo índice
	# usado pelo motor de Combate), nunca texto inventado.
	if template.tier_1_trait_name != "":
		vbox.add_child(_make_separator())
		vbox.add_child(_make_centered_label("Característica: %s" % template.tier_1_trait_name, 12, HUD_ACCENT))
		var trait_entry: UnitTraitResource = GameDatabase.traits_by_name.get(template.tier_1_trait_name)
		if trait_entry != null and trait_entry.base_effect_description != "":
			vbox.add_child(_make_body_label(trait_entry.base_effect_description))

	# Habilidades (Tier III/V) — mesmo índice GameDatabase.abilities_by_name.
	var ability_slots: Array = [
		["Habilidade (Tier III)", template.tier_3_ability_name],
		["Habilidade (Tier V)", template.tier_5_ability_name],
	]
	for slot: Array in ability_slots:
		var slot_label: String = slot[0]
		var ability_name: String = slot[1]
		if ability_name == "":
			continue
		vbox.add_child(_make_separator())
		vbox.add_child(_make_centered_label("%s: %s" % [slot_label, ability_name], 12, HUD_ACCENT))
		var ability: AbilityResource = GameDatabase.abilities_by_name.get(ability_name)
		if ability != null and ability.effect_description != "":
			vbox.add_child(_make_body_label(ability.effect_description))

	vbox.add_child(_make_separator())
	_build_recipe_section(vbox, template, kingdom)


func _on_detail_scroll_resized(scroll: ScrollContainer, vbox: VBoxContainer) -> void:
	if not is_instance_valid(vbox):
		return
	vbox.custom_minimum_size.x = scroll.size.x


## Receita real (pedido §5/§6/§7) — usa AcademyResolver.preview_production()
## diretamente, a MESMA função que academia_producao_panel.gd já chama pra
## prever a Produção: nenhum recálculo manual, nenhuma segunda árvore de
## dependência. "preserve_inventory=true" pede o plano "do zero" (ignora
## o que o Reino já possui) de propósito — RECEITA é a fórmula fixa da
## Carta (ver exemplo estrutural do pedido, "[Carta A]×3"), não um plano
## de compra personalizado pro inventário atual; a chamada é só leitura
## (preview_production nunca reserva Fragmento nem consome carta — ver
## AcademyResolver, _unlock_all sempre desfaz qualquer trava temporária
## antes de retornar), então nada em CardResource/Kingdom/AcademyResolver/
## AcademyEconomy é alterado (pedido §12).
##
## new_cards_to_produce já vem RECURSIVO (achatado por
## AcademyResolver._summarize_plan): pra uma Carta cujo ingrediente
## também tem receita própria (ex.: Águia Dourada -> Leão da Savana, que
## por sua vez tem sua própria receita), a cadeia inteira aparece aqui
## sem precisar andar na árvore manualmente — exatamente "mostrar a
## cadeia de forma clara" (pedido §6) usando só o que o sistema já expõe.
func _build_recipe_section(vbox: VBoxContainer, template: CardResource, kingdom: Kingdom) -> void:
	vbox.add_child(_make_centered_label("Receita", 13, HUD_ACCENT))

	if template.recipe_ingredients.is_empty():
		vbox.add_child(_make_centered_label("Produzida direto por Fragmentos.", 11, HUD_MUTED_COLOR))

	var preview: Dictionary = AcademyResolver.preview_production(kingdom, template.card_name, 1, true)
	if not preview["valid"]:
		return

	var produce_counts: Dictionary = preview["new_cards_to_produce"]
	for ingredient_name: String in produce_counts:
		if ingredient_name == template.card_name:
			continue
		vbox.add_child(_build_ingredient_row(ingredient_name, produce_counts[ingredient_name]))

	if preview["total_fragment_cost"] > 0:
		vbox.add_child(_make_centered_label(
			"Fragmento (%s): × %d" % [preview["faction"], preview["total_fragment_cost"]],
			11, HUD_TEXT_COLOR
		))


## Linha "carta necessária" (pedido §6): mini arte real (mesmo
## BattleCardView/CardArtCatalog de sempre) + nome + quantidade — nunca
## uma segunda forma de carregar arte de Carta.
func _build_ingredient_row(card_name: String, quantity: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var ingredient_template: CardResource = GameDatabase.get_card(card_name)
	if ingredient_template != null:
		var thumb_width: float = 32.0
		var thumb_slot := Control.new()
		thumb_slot.custom_minimum_size = Vector2(thumb_width, thumb_width / BattleCardView.CARD_ASPECT_RATIO)
		row.add_child(thumb_slot)

		var thumb_view := BattleCardView.new()
		thumb_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb_slot.add_child(thumb_view)
		thumb_view.set_card(ingredient_template)
		thumb_view.set_stats(ingredient_template.atk, ingredient_template.hp, ingredient_template.esc)
		thumb_view.set_compact(true)

	var name_label := _make_body_label(card_name)
	row.add_child(name_label)

	var quantity_label := _make_label("× %d" % quantity, 11, HUD_ACCENT)
	quantity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(quantity_label)

	return row


func _on_detail_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = true
		refresh()


## Visão ampliada temporária (overlay sobre a própria tela — nunca uma
## cena nova), portada de academia_producao_panel.gd. Adicionada direto
## em `self` (nunca em texture_rect): cobre a tela inteira mesmo fora da
## área do AspectRatioContainer, garantindo que "clique fora" funcione em
## qualquer resolução/letterbox.
func _build_card_zoom_overlay(card: CardResource, is_owned: bool) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.75)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_card_zoom_backdrop_gui_input)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(center)

	var viewport_size: Vector2 = get_viewport_rect().size
	var enlarged_height: float = viewport_size.y * 0.75
	var enlarged_width: float = enlarged_height * BattleCardView.CARD_ASPECT_RATIO
	if enlarged_width > viewport_size.x * 0.6:
		enlarged_width = viewport_size.x * 0.6
		enlarged_height = enlarged_width / BattleCardView.CARD_ASPECT_RATIO

	var card_slot := Control.new()
	card_slot.custom_minimum_size = Vector2(enlarged_width, enlarged_height)
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	card_slot.gui_input.connect(_on_card_zoom_card_gui_input)
	center.add_child(card_slot)

	var enlarged_view := BattleCardView.new()
	enlarged_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	enlarged_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot.add_child(enlarged_view)
	enlarged_view.set_card(card)
	enlarged_view.set_stats(card.atk, card.hp, card.esc)
	enlarged_view.set_compact(false)
	enlarged_view.portrait.material = null if is_owned else _grayscale_material


## "Clique fora retorna ao Bestiário" (pedido §5): fecha o overlay,
## refresh() reconstrói a MESMA tela do Bestiário por baixo — nunca uma
## troca de cena.
func _on_card_zoom_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = false
		refresh()


## Clicar na própria carta ampliada também fecha (evita o jogador
## precisar "acertar" a borda fina do backdrop).
func _on_card_zoom_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_card_zoom_open = false
		refresh()


## --- Helpers visuais (duplicados localmente, mesmo padrão/valores já
## estabelecidos em capital_panel.gd/biblioteca_panel.gd/
## academia_producao_panel.gd — nenhum código é importado). ---

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)
	return label


func _make_centered_label(text: String, font_size: int, color: Color) -> Label:
	var label := _make_label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## Texto de descrição (Característica/Habilidade/Ingrediente da Receita)
## — alinhado à esquerda, autowrap ligado (herdado de _make_label),
## expandido pra largura real do VBoxContainer (nunca a largura mínima
## do glifo mais estreito — mesma causa raiz do bug de autowrap já
## documentado nesta mesma tela, "Voltar para a Biblioteca").
func _make_body_label(text: String) -> Label:
	var label := _make_label(text, 11, HUD_TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.35)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


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

	var label := _make_label("", 14, HUD_TEXT_COLOR)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.add_child(label)

	return {"container": chip, "label": label}


## Caixa de busca com moldura própria (borda dourada translúcida) — a
## faixa de filtros da arte é decorativa/sem rótulo, então o controle
## dinâmico precisa da própria moldura visível (diferente do dropdown de
## Tipo/Raridade da Academia, que fica transparente porque a moldura já
## está desenhada na arte daquela tela).
func _styled_line_edit(placeholder: String) -> LineEdit:
	var box := LineEdit.new()
	box.placeholder_text = placeholder
	box.add_theme_font_override("font", HUD_FONT)
	box.add_theme_font_size_override("font_size", 13)
	box.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	box.add_theme_color_override("font_placeholder_color", HUD_MUTED_COLOR)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	box.add_theme_stylebox_override("normal", style)
	box.add_theme_stylebox_override("focus", style)

	return box


func _styled_option_button(values: Array[String], current: String) -> OptionButton:
	var option := OptionButton.new()
	for value: String in values:
		option.add_item(value)
	option.selected = values.find(current)
	option.clip_text = true
	option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	option.add_theme_font_override("font", HUD_FONT)
	option.add_theme_font_size_override("font_size", 12)
	option.add_theme_color_override("font_color", HUD_TEXT_COLOR)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HUD_ACCENT.r, HUD_ACCENT.g, HUD_ACCENT.b, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		option.add_theme_stylebox_override(state, style)

	_theme_option_popup(option)
	return option


## Tema do POPUP do dropdown — fundo escuro, borda dourada, fonte Cinzel
## (mesmo padrão de academia_producao_panel.gd, duplicado localmente).
func _theme_option_popup(option: OptionButton) -> void:
	var popup: PopupMenu = option.get_popup()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.08, 0.97)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = HUD_ACCENT
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	popup.add_theme_stylebox_override("panel", panel_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(HUD_ACCENT_FAVORITE.r, HUD_ACCENT_FAVORITE.g, HUD_ACCENT_FAVORITE.b, 0.28)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	popup.add_theme_stylebox_override("hover", hover_style)

	popup.add_theme_font_override("font", HUD_FONT)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	popup.add_theme_color_override("font_hover_color", HUD_ACCENT_FAVORITE)
	popup.add_theme_color_override("font_separator_color", HUD_ACCENT)
	popup.add_theme_constant_override("item_start_padding", 6)
	popup.add_theme_constant_override("item_end_padding", 6)
	popup.add_theme_constant_override("v_separation", 6)


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


func _on_back_chip_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/panels/biblioteca_panel.tscn")


func _on_card_cell_gui_input(event: InputEvent, card_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_card_name = card_name
		_card_zoom_open = false
		refresh()
