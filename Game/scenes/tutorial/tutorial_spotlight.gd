class_name TutorialSpotlight
extends Control
## TutorialSpotlight (Auditoria pré-pré-alfa — Tutorial de Comandantes)
##
## Componente reutilizável NOVO (auditado antes de criar: nenhum sistema
## de destaque/escurecimento existia no projeto — grep por "highlight/
## destaque/escurec/spotlight/dim" em Game/ não encontrou nada; só
## existia TutorialHintBanner, uma caixa NÃO-bloqueante sem destaque de
## elemento nem escurecimento de fundo). Reaproveita a mesma linguagem
## visual já estabelecida (HotspotGlow.GLOW_COLOR dourado pulsante,
## HUD_FONT Cinzel-SemiBold, mesmo estilo de painel/borda usado em
## `_make_card_panel()` por todo o projeto) — nunca uma identidade nova.
##
## Escurece toda a tela exceto um recorte retangular ao redor de um
## Control-alvo real (nunca coordenadas fixas — segue o Control de
## verdade, então continua correto em qualquer resolução), desenha um
## contorno pulsante ao redor do recorte, e mostra um pequeno texto
## (título + corpo) próximo ao alvo. Opcionalmente espera uma AÇÃO REAL
## do jogador em vez de um botão "Continuar" — quem instancia decide,
## controlando quando chamar queue_free()/reconstruir o próximo passo.
##
## Árvore em código, sem cena própria — mesmo padrão de todo o projeto.
## Puramente aditivo: nunca bloqueia clique sobre o próprio Control-alvo
## (o recorte central tem mouse_filter IGNORE; só as 4 tarjas escuras ao
## redor capturam clique, para impedir interação com o resto da tela
## enquanto o passo está ativo — pedido explícito "escurecer o
## restante").

signal continue_pressed

const DIM_COLOR: Color = Color(0.0, 0.0, 0.0, 0.72)
const GLOW_COLOR: Color = Color(0.86, 0.74, 0.42)  # mesmo tom de HotspotGlow.GLOW_COLOR
const RING_MARGIN: float = 6.0  # folga entre o alvo e o contorno

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)

var _target_rect: Rect2 = Rect2()
var _ring_control: Control


## `target`: Control real já na árvore (usa seu get_global_rect(), nunca
## uma coordenada fixa). `title`/`body`: texto curto. `show_continue`:
## true mostra um botão "Continuar" (emite `continue_pressed`); false
## não mostra nenhum botão — quem instancia decide quando o passo real
## foi concluído (ex.: clique real em "Promover") e troca o passo.
func setup(target: Control, title: String, body: String, show_continue: bool = true) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().process_frame  # garante get_global_rect() já resolvido no layout atual
	_target_rect = target.get_global_rect().grow(RING_MARGIN)

	_build_dim_strips()
	_build_ring()
	_build_text_box(title, body, show_continue)


## 4 tarjas escuras (cima/baixo/esquerda/direita) ao redor de
## `_target_rect` — nunca uma única ColorRect cobrindo tudo (isso
## esconderia o próprio alvo). Cada tarja intercepta clique
## (mouse_filter STOP), forçando a atenção no elemento em destaque.
func _build_dim_strips() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()

	_add_dim_strip(Rect2(0, 0, viewport_rect.size.x, _target_rect.position.y))
	_add_dim_strip(Rect2(0, _target_rect.end.y, viewport_rect.size.x, viewport_rect.size.y - _target_rect.end.y))
	_add_dim_strip(Rect2(0, _target_rect.position.y, _target_rect.position.x, _target_rect.size.y))
	_add_dim_strip(Rect2(_target_rect.end.x, _target_rect.position.y, viewport_rect.size.x - _target_rect.end.x, _target_rect.size.y))


func _add_dim_strip(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var strip := ColorRect.new()
	strip.color = DIM_COLOR
	strip.position = rect.position
	strip.size = rect.size
	strip.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(strip)


func _build_ring() -> void:
	_ring_control = Control.new()
	_ring_control.position = _target_rect.position
	_ring_control.size = _target_rect.size
	_ring_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_control.set_script(preload("res://scenes/tutorial/tutorial_spotlight_ring.gd"))
	add_child(_ring_control)


func _build_text_box(title: String, body: String, show_continue: bool) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.08, 0.97)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = GLOW_COLOR
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(280, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	vbox.add_child(_make_label(title, 15, GLOW_COLOR))
	var body_label := _make_label(body, 12, HUD_TEXT_COLOR)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_label.custom_minimum_size.x = 260
	vbox.add_child(body_label)

	if show_continue:
		var button_row := HBoxContainer.new()
		button_row.alignment = BoxContainer.ALIGNMENT_END
		vbox.add_child(button_row)
		var continue_button := Button.new()
		continue_button.text = "Continuar"
		continue_button.pressed.connect(func() -> void: continue_pressed.emit())
		button_row.add_child(continue_button)
	else:
		vbox.add_child(_make_label("Aguardando sua ação...", 11, Color(HUD_TEXT_COLOR.r, HUD_TEXT_COLOR.g, HUD_TEXT_COLOR.b, 0.65)))

	add_child(panel)

	# Posiciona a caixa abaixo do alvo por padrão; se não houver espaço
	# (alvo perto do fim da tela), posiciona acima — nunca cobrindo o
	# próprio alvo em destaque.
	await get_tree().process_frame
	var box_size: Vector2 = panel.get_combined_minimum_size()
	var viewport_rect: Rect2 = get_viewport_rect()
	var box_x: float = clampf(_target_rect.position.x, 8.0, viewport_rect.size.x - box_size.x - 8.0)
	var box_y: float = _target_rect.end.y + 10.0
	if box_y + box_size.y > viewport_rect.size.y - 8.0:
		box_y = _target_rect.position.y - box_size.y - 10.0
	panel.position = Vector2(box_x, maxf(box_y, 8.0))


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 3)
	return label
