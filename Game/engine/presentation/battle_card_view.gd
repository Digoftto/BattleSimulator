class_name BattleCardView
extends Control
## BattleCardView (ART-006)
##
## Representa UMA unidade num slot real do Battlefield, usando a
## identidade visual completa da carta oficial (moldura, ilustracao,
## nome, raridade e texto de habilidade - tudo ja desenhado dentro do
## PNG da carta, ver CARD_LAYOUT_BIBLE.md e os assets em
## res://assets/art/cards/) como base, com apenas os campos que a arte
## estatica NAO consegue expressar desenhados por cima:
##
##   - Tier (mutavel por copia, Tier I-V - a arte e uma so por carta,
##     nunca varia por Tier, ver CARD_PROGRESSION.md);
##   - Tipo + Classe (CARD_LAYOUT_BIBLE.md secao III/IV - "Classe
##     permanece abaixo de Tipo");
##   - ATK/Escudo/Vida ATUAIS (a arte ja desenha os icones de
##     Ataque/Escudo/Vida vazios - os numeros mudam durante o combate,
##     entao precisam ser desenhados pelo Godot, nunca a arte).
##
## Nome, Facção, Raridade e o texto de habilidade NÃO são redesenhados
## aqui - já estão na própria arte (CardArtCatalog.cropped_texture_for()),
## conforme confirmado por inspeção direta dos assets oficiais. Energia
## e Soldo (CARD_LAYOUT_BIBLE.md secao VII, "Informacoes Contextuais")
## permanecem ocultos durante o combate - este componente nunca os
## desenha; quem quiser reusar BattleCardView numa tela de montagem de
## Exercito precisaria de uma variante separada, fora do escopo aqui.
##
## Preparado para animação futura (sem inventar nenhuma): flash_attack(),
## flash_damage(), flash_heal() e play_death() são os únicos pontos de
## entrada que uma camada de replay deve chamar em resposta a eventos
## REAIS do CombatEventBus (via CombatReplayCollector) - hoje cada um
## só produz um flash de cor simples (nenhuma regra de combate nova,
## nenhuma interpretação além do que o evento já diz: "houve ataque",
## "houve dano", "houve cura", "a unidade morreu").

## Razao Largura/Altura do slot (nao da carta crua - os 40 PNGs fonte
## tem proporcoes de canvas ligeiramente diferentes entre si, ver
## CardArtCatalog.used_rect_for()). ~0,65 fica dentro da faixa real
## observada (0,58-0,71) para as cartas oficiais existentes - um slot
## uniforme para as 18 posicoes, com STRETCH_KEEP_ASPECT_COVERED
## absorvendo a pequena variacao entre cartas (mesmo principio de
## qualquer grid de cartas de tamanho fixo).
const CARD_ASPECT_RATIO: float = 0.65

var portrait: TextureRect
var _tier_label: Label
var _type_class_label: Label
var _atk_label: Label
var _esc_label: Label
var _hp_label: Label
var _card_body: Control

var _card: CardResource = null
var _is_alive: bool = true
## ART-007-v2: no tabuleiro isométrico, o slot desenhado no Battlefield
## é pequeno demais pra Tier/Tipo/Classe/ATK/ESC/HP caberem sem virar
## ruído sobreposto (labels de tamanho fixo em pixels, calibradas pra
## legibilidade, não pra encolher). Em vez de forçar a carta a crescer
## além do próprio slot (tentativa anterior, gerava sobreposição entre
## linhas), o modo compacto mostra só a arte (ainda reconhecível em
## miniatura, ver CARD_LAYOUT_BIBLE.md "Teste de Miniatura") e omite os
## textos dinâmicos — a leitura completa e legível vive no popup de
## hover (CombatReplayView._show_hover_preview()), que reusa este
## mesmo componente em modo completo.
var _compact: bool = false


func _ready() -> void:
	if _card_body == null:
		_build()


func _build() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var aspect := AspectRatioContainer.new()
	aspect.ratio = CARD_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# FASE 10: causa raiz do popup de hover "roubando" o próprio hover de
	# volta do slot que o abriu (ver docstring de
	# combat_replay_view.gd::_build_hover_preview()) — nenhum destes
	# elementos internos puramente decorativos tinha mouse_filter
	# explícito, então caíam no padrão do Godot (STOP para a maioria dos
	# Control), competindo por mouse_entered/exited com o Control EXTERNO
	# (este, "self") que é quem de fato recebe as conexões de sinal (ver
	# combat_replay_view.gd, "view.mouse_filter = STOP" + ".connect()").
	# IGNORE aqui garante que só o Control externo de BattleCardView
	# decide se recebe mouse — tanto nos 18 slots do tabuleiro quanto no
	# popup de hover (que usa IGNORE no externo também, sendo puramente
	# visual).
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aspect)

	_card_body = Control.new()
	_card_body.clip_contents = true
	_card_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(_card_body)

	portrait = TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Perf/qualidade (Biblioteca/Bestiário): a arte fonte da Carta é
	# grande (~1100-1500px) e é exibida bem menor numa grade — sem
	# mipmaps, essa minificação forte tende a "chiar"/perder nitidez.
	# As texturas em res://assets/art/cards/ já têm mipmaps/generate=true
	# no import; isto só diz ao TextureRect pra usá-los. Nunca afeta a
	# arte de origem (nenhum pixel é alterado), só a filtragem de
	# exibição — e não atrapalha a carta ampliada (mipmaps só entram
	# quando a exibição é MENOR que a textura, nunca ao ampliar).
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_card_body.add_child(portrait)

	# ART-006: banda "Tipo/Classe" (CARD_LAYOUT_BIBLE.md III/IV) - a
	# unica regiao textual que a arte estatica nao reserva hoje (Nome,
	# Raridade e a Descricao/Habilidade ja vem desenhados no PNG). Sem
	# caixa solida atras: so um leve contorno escuro na fonte, pra nao
	# recriar a "caixa preta generica" que este trabalho existe pra
	# remover.
	_type_class_label = _make_label(11, Color(0.92, 0.90, 0.82))
	_anchor_point(_type_class_label, 0.5, 0.635, 200, 34)
	_type_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_class_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_class_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_style_outline(_type_class_label)
	_card_body.add_child(_type_class_label)

	# ART-006: selo de Tier - a arte reserva um medalhao superior
	# esquerdo (vazio em todas as 40 cartas oficiais inspecionadas),
	# nunca preenchido porque Tier e mutavel por copia e a arte e uma
	# unica por carta (CARD_PROGRESSION.md). So o numero e desenhado
	# aqui; o medalhao em si ja existe na propria moldura.
	_tier_label = _make_label(14, Color(0.95, 0.86, 0.55))
	_anchor_point(_tier_label, 0.155, 0.085, 40, 32)
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_outline(_tier_label)
	_card_body.add_child(_tier_label)

	# ART-006: os 3 valores dinamicos, ancorados exatamente sobre os
	# icones de Ataque/Escudo/Vida ja desenhados (vazios) na barra
	# inferior da propria carta (CARD_LAYOUT_BIBLE.md VI/VIII) -
	# posicao medida por amostragem de pixel nos PNGs oficiais
	# (arqueiro_imperial/lich_rei/coracao_da_floresta), nunca um
	# palpite.
	_atk_label = _make_label(15, Color(0.95, 0.92, 0.85))
	_anchor_point(_atk_label, 0.205, 0.895, 60, 30)
	_atk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_atk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_outline(_atk_label)
	_card_body.add_child(_atk_label)

	_esc_label = _make_label(15, Color(0.80, 0.90, 1.0))
	_anchor_point(_esc_label, 0.5, 0.895, 60, 30)
	_esc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_esc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_outline(_esc_label)
	_card_body.add_child(_esc_label)

	_hp_label = _make_label(15, Color(1.0, 0.82, 0.82))
	_anchor_point(_hp_label, 0.795, 0.895, 60, 30)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_outline(_hp_label)
	_card_body.add_child(_hp_label)

	clear()


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# FASE 10: ver comentário em _build() — puramente decorativo, nunca
	# deve competir por mouse com o Control externo de BattleCardView.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Rotula de forma legivel sobre qualquer fundo da ilustracao sem uma
## caixa solida - contorno escuro (outline) em vez de background,
## unico jeito de manter texto dinamico legivel sem "tapar" a arte com
## um retangulo generico (a proibicao central deste trabalho).
func _style_outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 5)


## Ancora um Control num ponto fracionario fixo do card_body (0..1 em
## cada eixo), com uma caixa de tamanho fixo em pixels centrada nesse
## ponto - a posicao escala com o tamanho real do slot (fracionaria),
## o tamanho do texto permanece estavel e legivel.
func _anchor_point(control: Control, x_frac: float, y_frac: float, box_w: float, box_h: float) -> void:
	control.anchor_left = x_frac
	control.anchor_right = x_frac
	control.anchor_top = y_frac
	control.anchor_bottom = y_frac
	control.offset_left = -box_w / 2.0
	control.offset_right = box_w / 2.0
	control.offset_top = -box_h / 2.0
	control.offset_bottom = box_h / 2.0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


## Define a identidade PERMANENTE da unidade (arte, Tier, Tipo, Classe)
## - chamado uma vez por unidade, nunca precisa ser refeito so porque
## HP/ESC mudaram (ver set_stats()).
func set_card(card: CardResource) -> void:
	if _card_body == null:
		_build()
	_card = card
	visible = card != null
	if card == null:
		return

	portrait.texture = CardArtCatalog.cropped_texture_for(card)
	set_tier(card.tier)

	var type_and_class: String = card.card_class
	if card.card_type != "":
		type_and_class = card.card_type + "\n" + card.card_class
	_type_class_label.text = type_and_class


func set_tier(tier: int) -> void:
	_tier_label.text = "T%d" % tier


## ART-007-v2: alterna entre a representação pequena de tabuleiro (só
## arte, sem texto dinâmico sobreposto — ver comentário de _compact) e
## a representação completa (usada no popup de hover). Chamado a
## qualquer momento, antes ou depois de set_card()/set_stats(); nunca
## precisa ser refeito a cada refresh de combate.
func set_compact(compact: bool) -> void:
	_compact = compact
	if _card_body == null:
		_build()
	_tier_label.visible = not compact
	_type_class_label.visible = not compact
	_atk_label.visible = not compact
	_esc_label.visible = not compact
	_hp_label.visible = not compact


## Valores ATUAIS de combate - chamado a cada refresh (ataque/cura/
## morte), nunca recarrega o retrato (ART-001: a arte so precisa
## carregar uma vez por unidade).
func set_stats(atk: int, hp: int, esc: int) -> void:
	_atk_label.text = str(atk)
	_hp_label.text = str(hp)
	_esc_label.text = str(esc)


func set_alive(alive: bool) -> void:
	_is_alive = alive
	var tint: Color = Color.WHITE if alive else Color(0.42, 0.30, 0.30)
	portrait.modulate = tint
	var text_tint: Color = Color.WHITE if alive else Color(0.6, 0.55, 0.55)
	_atk_label.modulate = text_tint
	_esc_label.modulate = text_tint
	_hp_label.modulate = text_tint
	_type_class_label.modulate = text_tint


## Estado "posicao vazia" (nenhuma unidade viva ali) - nunca mostra
## texto de apoio nem retrato, o slot so fica visualmente inerte
## (bg do Battlefield aparece por baixo).
func clear() -> void:
	_card = null
	visible = false


## ---- Pontos de entrada para animacao futura (ART-006 secao 9) ----
## Cada um representa exclusivamente um evento REAL ja publicado pelo
## CombatEventBus (via CombatReplayCollector.replay_events) - nenhuma
## interpretacao nova. Hoje cada um so da um flash de cor breve; uma
## Sprint futura pode trocar o corpo por um Tween real sem mudar esta
## assinatura nem quem chama.

func flash_attack() -> void:
	_flash(Color(1.0, 0.95, 0.6))


func flash_damage() -> void:
	_flash(Color(1.0, 0.35, 0.35))


func flash_heal() -> void:
	_flash(Color(0.5, 1.0, 0.55))


func play_death() -> void:
	set_alive(false)


func _flash(color: Color) -> void:
	if portrait == null:
		return
	var tween := create_tween()
	var base_tint: Color = portrait.modulate
	portrait.modulate = color
	tween.tween_property(portrait, "modulate", base_tint, 0.25)
