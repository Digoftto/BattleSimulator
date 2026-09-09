class_name HotspotGlow
extends Control
## HotspotGlow (Battlefield, Fase 10-11; GENERALIZADO na Fase 12)
##
## Sinal luminoso pra indicar "isto é clicável" — halo pulsante, fino nas
## bordas mas REALMENTE visível. Reusa a cor de destaque já usada em toda
## a UI do projeto (HUD_ACCENT, ver campo_de_prova_panel.gd/city_panel.gd)
## — nenhuma identidade visual nova.
##
## FASE 12 — reescopo explícito do usuário: "sinais luminosos nos
## hotspots" NUNCA se referia ao Battlefield (removido de lá nesta
## tarefa, ver combat_replay_view.gd) — o pedido real sempre foi pelos
## hotspots da CIDADE e do interior das construções (os Control criados
## por _build_hitbox()/_build_hotspot() em city_panel.gd,
## biblioteca_panel.gd, observatorio_panel.gd, energy_core_hub_panel.gd,
## deposito_panel.gd, world_map_gate_panel.gd — todos o MESMO padrão
## "arte é a interface + N hotspots invisíveis sobre elementos já
## desenhados"). O componente em si (este arquivo) já era 100%
## desacoplado do Battlefield — nenhuma referência a side/position/
## CombatUnit/CombatBoard em nenhum momento, sempre só um Control
## puramente visual com 3 estados — por isso reaproveitado tal como
## está, sem duplicar código, apenas renomeado (BattleHotspotGlow ->
## HotspotGlow) por clareza, já que "Battle" deixou de refletir onde é
## usado.
##
## Deliberadamente SEM Tween: a pulsação vem de Time.get_ticks_msec()
## (relógio monotônico global, correto com várias instâncias
## simultâneas) lido dentro de _draw(), redesenhado uma vez por frame
## via _process(). Nenhum nó de animação por instância, nenhum estado
## próprio de tempo — "um componente reutilizável, animação controlada"
## (pedido explícito), sem o custo de dezenas de Tweens permanentes.
##
## Puramente visual: mouse_filter = IGNORE sempre (nunca compete por
## input com o hotspot real que o hospeda).

enum State { AVAILABLE, HOVER, DISABLED }

## Tom dourado já usado no HUD (HUD_ACCENT, ver campo_de_prova_panel.gd/
## city_panel.gd::HUD_NEUTRAL_ACCENT) — reaproveitado aqui, nunca uma
## cor nova.
const GLOW_COLOR: Color = Color(0.86, 0.74, 0.42)

const PULSE_SPEED: float = 2.0
const AVAILABLE_BASE_ALPHA: float = 0.55
const AVAILABLE_PULSE_RANGE: float = 0.20
const HOVER_BASE_ALPHA: float = 0.85
const HOVER_PULSE_RANGE: float = 0.15
const RING_WIDTH: float = 3.0

## FASE 14 — INVESTIGAÇÃO "glow não aparece nas telas internas": comparação
## runtime (Control/CanvasItem: parent, position, size, scale, visible,
## is_visible_in_tree, modulate, self_modulate, z_index, z_as_relative,
## clip_contents, mouse_filter, process_mode, canvas_transform, viewport)
## entre o glow da Cidade e o da Biblioteca, feita com as duas cenas
## REALMENTE dentro da SceneTree (get_tree().root.add_child(), múltiplos
## process_frame — não apenas _build_static_structure() isolado como os
## testes existentes) não encontrou NENHUMA diferença estrutural: árvore,
## parent, transform e estado de visibilidade são idênticos nos dois
## casos. A causa real é de CONTRASTE: GLOW_COLOR (dourado quente) fica
## muito próximo da própria paleta da arte nesses pontos específicos —
## confirmado por amostragem de cor de City.png/library_v1.png/
## observatory_v1.png nos centros dos hotspots (distância RGB até
## GLOW_COLOR: ~150-220 na Cidade contra ~30-190 nas telas internas; o
## pior caso, "World Atlas" na Biblioteca, mede ~32 — quase idêntico ao
## próprio glow). O componente sempre desenhou corretamente; o desenho só
## não se distinguia do fundo. Contorno escuro adicional (sempre desenhado
## primeiro, por baixo de tudo) garante leitura contra qualquer fundo
## claro/quente sem alterar a aparência já aprovada na Cidade (fundo
## escuro ali já dava contraste suficiente, contorno fica praticamente
## imperceptível por cima dele).
const CONTOUR_COLOR: Color = Color(0.05, 0.05, 0.05)
const CONTOUR_ALPHA_FACTOR: float = 0.55
const CONTOUR_WIDTH: float = RING_WIDTH * 1.6

## FASE 12: tamanho FIXO (px reais de tela) do marcador usado por
## attach_to_region() — um "ponto de interesse" pequeno e consistente,
## nunca proporcional ao tamanho do hotspot que o hospeda (as regiões
## da Cidade variam muito de tamanho — de ~0.08 a ~0.38 de fração —
## um halo do tamanho da região inteira pareceria uma "caixa luminosa
## pesada", exatamente o que foi pedido pra evitar).
const DEFAULT_MARKER_SIZE_PX: float = 34.0

var _state: State = State.AVAILABLE


## mouse_filter=IGNORE em _init() (nunca em _ready()) de propósito —
## precisa valer IMEDIATAMENTE após .new(), independente de o nó já
## estar ou não dentro de uma SceneTree ao vivo.
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_process(_state != State.DISABLED)


## Chamado pelo hospedeiro (CombatReplayView, CityPanel, etc.) quando o
## elemento fica disponível/indisponível ou o cursor entra/sai — nunca
## decidido aqui sozinho (este componente só desenha o estado que
## recebe).
func set_hotspot_state(state: State) -> void:
	if _state == state:
		return
	_state = state
	set_process(_state != State.DISABLED)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


## FASE 12: configuração reutilizável — posiciona ESTA instância
## (chamar logo após preload(...).new(), NUNCA como método static via
## preload(...).attach_to_region() diretamente: um GDScript carregado
## por preload() sem passar por class_name global não resolve métodos
## static por fora de uma instância real, confirmado empiricamente
## nesta tarefa — "Invalid call. Nonexistent function 'attach_to_region'
## in base 'GDScript'") PEQUENA e centralizada numa região fracionária
## (0..1, mesmo espaço de coordenadas de anchor_left/top/right/bottom
## já usado por _build_hotspot()/_build_hitbox()) de "parent" (o mesmo
## TextureRect que hospeda o hotspot de input real), com tamanho FIXO
## em px reais — nunca coordenada absoluta de tela (a âncora fracionária
## acompanha qualquer redimensionamento de janela/escala automaticamente,
## mesmo mecanismo responsivo já usado pelos próprios hotspots de
## input). Adiciona a si mesma como filha de "parent" e retorna "self"
## (permite a chamada encadeada preload(...).new().attach_to_region(...)).
## Quem chama continua responsável por criar o hotspot de mouse
## separadamente (este método nunca cria hitbox de input, só o sinal
## visual) e por ligar set_hotspot_state(HOVER/AVAILABLE) aos callbacks
## mouse_entered/mouse_exited já existentes desse hotspot.
func attach_to_region(parent: Control, region_rect: Rect2, marker_size_px: float = DEFAULT_MARKER_SIZE_PX) -> HotspotGlow:
	var center_x: float = region_rect.position.x + region_rect.size.x / 2.0
	var center_y: float = region_rect.position.y + region_rect.size.y / 2.0
	anchor_left = center_x
	anchor_right = center_x
	anchor_top = center_y
	anchor_bottom = center_y
	offset_left = -marker_size_px / 2.0
	offset_right = marker_size_px / 2.0
	offset_top = -marker_size_px / 2.0
	offset_bottom = marker_size_px / 2.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	parent.add_child(self)
	set_hotspot_state(State.AVAILABLE)
	return self


## FASE 12: halo em 3 camadas (anel externo mais largo/fraco -> anel
## interno mais fino/forte), simulando um brilho suave sem precisar de
## shader/blur real — mesmo princípio visual de qualquer "glow" simples
## (várias formas semi-transparentes sobrepostas com raio crescente).
func _draw() -> void:
	if _state == State.DISABLED:
		return

	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * PULSE_SPEED)

	var base_alpha: float = HOVER_BASE_ALPHA if _state == State.HOVER else AVAILABLE_BASE_ALPHA
	var pulse_range: float = HOVER_PULSE_RANGE if _state == State.HOVER else AVAILABLE_PULSE_RANGE
	var alpha: float = base_alpha + pulse_range * pulse

	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0
	if radius <= 0.0:
		return

	# FASE 14: contorno escuro, desenhado ANTES de tudo (fica por baixo do
	# halo dourado) — garante um limite visível do marcador contra
	# qualquer fundo, mesmo um fundo tão quente/dourado quanto o próprio
	# GLOW_COLOR (ver docstring de CONTOUR_COLOR acima).
	draw_arc(center, radius * 1.20, 0.0, TAU, 48, Color(CONTOUR_COLOR.r, CONTOUR_COLOR.g, CONTOUR_COLOR.b, alpha * CONTOUR_ALPHA_FACTOR), CONTOUR_WIDTH, true)

	# Camada externa — mais larga e mais fraca (sugestão de "brilho"
	# irradiando pra fora, nunca uma borda dura).
	draw_arc(center, radius * 1.12, 0.0, TAU, 48, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha * 0.35), RING_WIDTH * 2.2, true)
	# Camada intermediária.
	draw_arc(center, radius * 1.0, 0.0, TAU, 48, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha * 0.7), RING_WIDTH * 1.3, true)
	# Camada interna — o traço mais nítido/fino, o "contorno" do halo.
	draw_arc(center, radius * 0.88, 0.0, TAU, 48, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha), RING_WIDTH, true)
	# Preenchimento MUITO sutil — só o bastante pra sugerir "presença",
	# nunca cobrindo a leitura da arte por baixo.
	draw_circle(center, radius * 0.80, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha * 0.12))
