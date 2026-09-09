class_name CombatReplayView
extends Control
## CombatReplayView (F-046, reconstruído em ART-006, corrigido em ART-007)
##
## Infraestrutura de apresentação visual do combate (F-044/F-046,
## "Combate Visual"). Representa — nunca decide — o que CombatEngine já
## resolveu: recebe um CombatState FINAL e um CombatReplayCollector
## (attach()ado ao event_bus ANTES de CombatEngine.run(), snapshot_initial_board()
## chamado logo após CombatEngine.initialize()) já preenchidos por quem
## orquestrou a batalha, e percorre replay_events em ordem cronológica,
## num ritmo legível por humano (await entre eventos), atualizando um
## Battlefield real com 18 posições (9 por lado, ver CombatBoard) e um
## feed textual das ações. CombatEngine roda do jeito que sempre rodou —
## instantâneo, síncrono, sem nenhuma alteração — a "pausa" pertence
## inteiramente a esta camada.
##
## ART-007: a verificação visual de ART-006 mostrou que um GridContainer
## genérico (mesmo com a proporção certa por carta) NÃO corresponde aos
## slots isométricos desenhados de verdade nos 10 assets de Battlefield
## (res://assets/art/battlefields/*.png) — cada arte tem dois blocos 3x3
## de "moldura de pedra" pintados em perspectiva isométrica leve, com a
## MESMA posição de pixel nos 10 assets (confirmado por inspeção direta
## de campo_aberto.png, floresta.png e terreno_vulcanico.png — mesma
## câmera, só Território/clima mudam). As constantes _TILE_* abaixo
## foram medidas manualmente sobre esses pixels (ver processo na sessão:
## amostragem dos 4 cantos de cada bloco 3x3, resolvendo os dois vetores
## de passo do grid isométrico). CombatBoard continua sendo a ÚNICA
## fonte da posição LÓGICA (1-9) — o que muda aqui é exclusivamente a
## conversão dessa posição lógica pra um ponto visual real sobre a arte,
## via AspectRatioContainer travando a proporção nativa da imagem
## (1536:1024) pra que os slots medidos em pixels da imagem-fonte
## continuem batendo com o slot desenhado em QUALQUER tamanho de janela
## (sem inventar resolução fixa — a imagem letterboxa dentro do espaço
## disponível, nunca é cortada de um jeito que desalinha a arte da
## posição das cartas).
##
## Configuração (setar ANTES de _ready(), mesmo padrão de ArmyEditorPanel):
##   view.combat_state = <CombatState final, retornado por CombatEngine.run_battle()>
##   view.replay_collector = <CombatReplayCollector já attach()ado e com snapshot_initial_board() chamado>
##
## Emite "replay_finished" quando a reprodução termina e o banner de
## Resultado (Vitória/Derrota/Empate) já está visível — quem instanciar
## esta cena decide o que fazer depois (Recompensa, retorno à Cidade,
## etc.), esta cena não decide navegação sozinha.

signal replay_finished

## var (não const): testes automatizados (ver bootstrap.gd,
## _validate_pve_panel_ui()) zeram este valor ANTES de add_child(view)
## pra reproduzir todos os eventos instantaneamente, sem depender de
## tempo real de parede — o padrão humano (0.6s) continua sendo o
## default real, nunca alterado em jogo de verdade.
var DELAY_BETWEEN_EVENTS_SECONDS: float = 0.6

## Controle de velocidade de REPRODUÇÃO (Campo de Prova e qualquer outro
## consumidor desta cena) — NUNCA altera CombatEngine/a simulação em si
## (já resolvida por inteiro antes desta cena existir); só multiplica a
## pausa entre eventos já lida a cada iteração de _play_replay(), então
## uma mudança de velocidade no meio da reprodução passa a valer a
## partir do PRÓXIMO evento, sem reiniciar nada e sem pular nenhum
## evento (_apply_replay_event() continua rodando pra todos, na mesma
## ordem). BASE_DELAY_BETWEEN_EVENTS_SECONDS preserva o valor "1x"
## original mesmo depois de multiplicado.
const BASE_DELAY_BETWEEN_EVENTS_SECONDS: float = 0.6
const REPLAY_SPEED_MULTIPLIERS: Array[float] = [1.0, 2.0, 4.0]
var _replay_speed_index: int = 0
var _speed_button: Button

## F-047: quando true, pula a espera pelo clique real de "Continuar" e
## emite replay_finished sozinho assim que o banner de Resultado
## aparece — usado só por validação automatizada (bootstrap.gd), que
## não tem um jogador de verdade pra clicar. No jogo real este campo
## nunca é setado (permanece false): o jogador sempre vê o banner e
## decide quando prosseguir.
var auto_continue_when_finished: bool = false

## F-048: qual "side" (0 ou 1) do CombatState corresponde ao Exército
## do PRÓPRIO jogador — usado só pra rotular o tabuleiro/Resultado em
## linguagem que o jogador entende ("Seu Exército"/"Inimigo",
## "Vitória!"/"Derrota.") em vez do termo interno do motor ("Lado 0"/
## "Lado 1"), que não significa nada pra quem não leu o código. Default
## 0 porque o único chamador real hoje (PhaseResolver.resolve(), via
## pve_panel.gd — PvE e conquista de Mina) sempre monta o Exército do
## jogador como side 0 (CombatEngine.initialize(attempt_army, enemy_army, ...)).
## Configurável (não hardcoded) pra um futuro chamador com um mapeamento
## diferente (ex: uma tela de PvP real) poder setar o valor certo.
var player_side: int = 0

var combat_state: CombatState = null
## Tipo real: CombatReplayCollector — sem anotação explícita de
## propósito (F-046): esse class_name é novo nesta sessão e o cache
## global de classes do Godot (.godot/global_script_class_cache.cfg)
## só é regenerado por uma varredura do Editor, que nunca roda numa
## execução --headless. Uma anotação ": CombatReplayCollector" aqui
## falharia ao resolver esse tipo (SCRIPT ERROR: Parse Error) até essa
## regeneração acontecer. Quem atribui este campo já usa
## preload("res://engine/combat/combat_replay_collector.gd").new(),
## então a ausência de anotação estática não perde segurança de tipo
## nenhuma verificação nova nesta sessão.
var replay_collector = null

## ART-007: dimensão real (px) dos 10 PNGs de Battlefield — todos
## exportados no mesmo canvas 1536x1024 (confirmado por inspeção). A
## proporção 1536/1024 = 1.5 trava o AspectRatioContainer que envolve
## a arte + o Board/Slot Layer, garantindo que ambos escalem juntos.
const BATTLEFIELD_IMAGE_SIZE: Vector2 = Vector2(1536.0, 1024.0)

## Teste Visual 08: única consulta feita aqui a
## BattleUnitArtCatalog — exclusivamente para saber se card_name tem
## Battle Art registrada (has_art_for()), e então esconder a carta
## compacta dessa posição (ver _refresh_position_widget()). Nunca lê
## textura/retângulo alfa/geometria — essas continuam responsabilidade
## de BattleUnitArtLayer/BattleUnitArtGeometry.
const ArtCatalog = preload("res://engine/presentation/battle_unit_art_catalog.gd")

## ART-007: os dois blocos 3x3 isométricos medidos em pixels da imagem-
## fonte, como um grid afim local (válido dentro de cada bloco de 3x3
## — a curvatura de perspectiva real ao longo de 2 passos é pequena o
## bastante pra não ser perceptível com o card ocupando o slot):
##   tile_center(r, c) = ORIGIN + r*E1 + c*E2,  r,c em {0,1,2}
## ORIGIN é sempre o canto (r=0,c=0) do bloco (não o centro) — mais
## fácil de fixar visualmente num vértice único da moldura isométrica
## do que estimar o centro geométrico de um paralelogramo rodado.
## Bloco de cima (mais longe da câmera, mais alto na tela).
const ENEMY_TILE_ORIGIN: Vector2 = Vector2(863.0, 330.0)
const ENEMY_TILE_E1: Vector2 = Vector2(-65.0, 22.0)
const ENEMY_TILE_E2: Vector2 = Vector2(95.0, 22.0)
## Bloco de baixo (mais perto da câmera, mais baixo na tela — por isso
## maior: a perspectiva do asset aproxima as coisas mais pertas).
const PLAYER_TILE_ORIGIN: Vector2 = Vector2(497.5, 594.0)
const PLAYER_TILE_E1: Vector2 = Vector2(-105.0, 65.0)
const PLAYER_TILE_E2: Vector2 = Vector2(100.0, 37.0)

## ART-007-v2: a tentativa anterior aumentava a carta além do slot pra
## caber o texto dinâmico (Tier/Tipo/Classe/ATK/ESC/HP) legível — isso
## empilhava cartas de linhas adjacentes num "leque" (1.55x) ou ainda
## sobrepunha bastante mesmo com a carta "de pé" sobre a base do slot
## (1.05x). Decisão do usuário após ver o resultado: a carta do
## tabuleiro fica DENTRO do próprio quadrado, pequena o bastante pra
## nem sempre dar pra ler o texto — a leitura completa migrou pro
## popup de hover (ver _show_hover_preview()). 0.92x é só uma folga
## pequena sobre a largura do slot, a carta nunca deixa de ser
## reconhecida como "sobre aquele quadrado".
const CARD_SIZE_MULTIPLIER: float = 0.92

## ART-007-v2: tamanho fixo (px) do popup de hover — grande o bastante
## pra reaproveitar a calibração de posição dos textos dinâmicos de
## BattleCardView (medida sobre cartas de ~176-280px de largura em
## ART-006/ART-007), sem depender do tamanho minúsculo da carta no
## tabuleiro.
## FASE 12: reduzido de 240 para 180 (exatamente 75% — pedido explícito
## do usuário após validar a Fase 11 visualmente: "a carta está um
## pouco grande demais... aproximadamente 75% do tamanho atual"), uma
## única constante, então altura/AspectRatioContainer/margem continuam
## escalando PROPORCIONALMENTE sem nenhuma mudança de fórmula — nunca
## deforma a carta, nunca toca fonte/box individual de battle_card_view.gd.
## 180px continua DENTRO da faixa já calibrada acima (176-280px), então
## a legibilidade dos textos dinâmicos permanece garantida sem precisar
## de nenhuma escala adicional (Control.scale) nem retocar
## battle_card_view.gd.
const HOVER_PREVIEW_WIDTH_PX: float = 180.0

## FASE 11: margem (px reais de tela, mesma convenção de
## _anchor_side_label — nunca fração da imagem-fonte) entre a borda da
## tela e o popup de hover, agora fixado no canto superior esquerdo
## (pedido explícito: "não deve mais acompanhar a posição do pelotão").
## Era a distância slot<->popup nas Fases 9/10 (posicionamento por
## quadrante, removido nesta tarefa) — renomeada por continuidade do
## mesmo conceito ("respiro visual"), nunca um valor novo inventado.
const HOVER_PREVIEW_MARGIN_PX: float = 24.0

## ART-007: conversão POSIÇÃO LÓGICA (CombatBoard, 1-9) -> (linha de
## profundidade 0-2, coluna 0-2) — única fonte de verdade continua
## sendo CombatBoard.COLUMN_A/B/C (frente->fundo), nunca recalculada:
## Coluna A = [1,6,7] -> profundidade 0,1,2 | Coluna B = [2,5,8] |
## Coluna C = [3,4,9]. índice de coluna (0/1/2) = A/B/C, só pra
## escolher a posição horizontal no grid isométrico (esquerda/direita
## na tela) — nenhuma regra de combate depende dessa escolha.
const POSITION_GRID: Dictionary = {
	1: Vector2i(0, 0), 6: Vector2i(1, 0), 7: Vector2i(2, 0),
	2: Vector2i(0, 1), 5: Vector2i(1, 1), 8: Vector2i(2, 1),
	3: Vector2i(0, 2), 4: Vector2i(1, 2), 9: Vector2i(2, 2),
}

var _turn_label: Label
var _log_label: Label
var _log_drawer: Control
var _log_drawer_label: Label
var _log_toggle_button: Button
var _result_label: Label
var _continue_button: Button
var _skip_button: Button
var _battlefield_texture_rect: TextureRect
var _board_layer: Control
## Battle Art MVP — Piloto (2026-09-02): camada ADITIVA, inserida ANTES
## de _board_layer (desenha atrás das cartas compactas — nunca altera a
## leitura visual já aprovada). Tipo real: BattleUnitArtLayer — sem
## anotação explícita (mesmo motivo já documentado pra replay_collector
## acima: class_name novo nesta sessão). Só desenha algo pra unidades
## cujo card_name tenha Battle Art registrada em BattleUnitArtCatalog
## (hoje: só o piloto) — qualquer outra unidade continua 100%
## representada por BattleCardView, sem nenhuma mudança.
var _unit_art_layer = null
var _hover_preview: Control
var _hover_preview_wrapper: Control
var _hover_key: int = -1

## side*10 + position -> {"card_name", "card_class", "hp", "max_hp", "esc", "max_esc", "alive", "card"}
var _live_board: Dictionary = {}

## unit_id (CombatUnit.get_instance_id(), ver combat_replay_collector.gd)
## -> side*10+position ATUAL da unidade — correção de replay visual
## (2026-09-02): antes, _apply_move_event() localizava a posição de
## ORIGEM buscando por "card_name" dentro de _live_board, ambíguo
## quando duas unidades do mesmo lado compartilham o mesmo card_name
## (comum em Exércitos gerados, especialmente do lado inimigo). Este
## índice é a única fonte usada para localizar "onde a unidade X está
## agora" — nunca o nome da carta. Mantido em sincronia por
## _apply_initial_board() (estado inicial) e _apply_move_event() (a
## cada passo de avanço); uma unidade morta é removida daqui por
## _apply_death_event().
var _unit_id_to_slot: Dictionary = {}
## side*10 + position -> {"view": BattleCardView, "portrait": TextureRect}
## "portrait" aponta pro TextureRect interno do BattleCardView — mantido
## como chave própria (em vez de só "view") porque test_combat_replay_view.gd
## (F-046) lê widgets["portrait"].texture diretamente; preservar esse
## contrato evita reescrever um teste que já prova a garantia central
## (replay bate exatamente com o CombatState real).
var _position_widgets: Dictionary = {}

var _log_lines: Array[String] = []

## FASE 7 (2026-09-04) — log COPIÁVEL/ESTRUTURADO: além do feed
## narrativo em português já existente (_log_lines, "Turno %d: X ataca
## Y..."), mantido sem nenhuma mudança, este é um segundo log, sempre em
## paralelo, no formato campo=valor pedido nesta tarefa (TURN/MOVE/
## ATTACK/DAMAGE/DEATH/HEAL com SIDE/UNIT_ID/CARD/posições) —
## reconstruível por um humano ou por outro sistema sem depender do
## texto narrativo. Nunca substitui _log_lines (aditivo).
var _structured_log_lines: Array[String] = []
var _copy_log_button: Button

var _skip_requested: bool = false
var _is_playing: bool = false
var _log_drawer_open: bool = false


func _ready() -> void:
	_build_static_structure()
	# FASE 7: liga a animação de movimento/ataque/dano/cura SÓ no caminho
	# real de jogo (nó entrando na árvore via _ready()) — os 3 arquivos de
	# teste existentes (test_battle_unit_art_pilot.gd/test_combat_replay_view.gd/
	# test_replay_visual_identity.gd) chamam _build_static_structure()
	# diretamente e NUNCA _ready(), então nunca ligam isso — preserva 100%
	# das asserções de posição síncronas já existentes sem editar nenhum
	# teste (ver comentário completo em battle_unit_art_layer.gd).
	if _unit_art_layer != null:
		_unit_art_layer.animate_movement = true
		_unit_art_layer.move_animation_duration_seconds = min(0.35, DELAY_BETWEEN_EVENTS_SECONDS * 0.8)
	_apply_initial_board()
	if not _is_playing:
		_play_replay()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 4)
	add_child(root_vbox)

	root_vbox.add_child(_build_header_bar())
	root_vbox.add_child(_build_battlefield_area())
	root_vbox.add_child(_build_footer_bar())

	# ART-007 secao 10: o log completo mora num drawer que SOBREPÕE a
	# parte de baixo do Battlefield quando aberto (nunca empurra o
	# layout) — por isso é filho direto da raiz (fora do root_vbox),
	# adicionado por último pra desenhar por cima de tudo.
	_log_drawer = _build_log_drawer()
	add_child(_log_drawer)

	_apply_side_labels()
	_append_structured_header()


func _build_header_bar() -> Control:
	# ART-007 secao 12: cabeçalho compacto — uma única linha, nunca uma
	# área grande. O Battlefield é quem domina o espaço vertical.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	header.custom_minimum_size = Vector2(0, 28)

	var title := Label.new()
	title.text = "COMBATE"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_turn_label = Label.new()
	_turn_label.text = "Turno 1"
	_turn_label.add_theme_font_size_override("font_size", 16)
	header.add_child(_turn_label)

	return header


## ART-007 secao 3/6/9: Battlefield -> Board/Slot Layer, os dois dentro
## de um AspectRatioContainer travado na proporção NATIVA da imagem-
## fonte (1536:1024) — garante que a posição medida em pixels da
## imagem-fonte (ENEMY_TILE_*/PLAYER_TILE_*) continue batendo com o
## slot desenhado de verdade, em qualquer tamanho de janela (a imagem
## letterboxa dentro do espaço disponível em vez de ser cortada de um
## jeito que desalinharia arte e cartas).
func _build_battlefield_area() -> Control:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var battlefield_aspect := AspectRatioContainer.new()
	battlefield_aspect.ratio = BATTLEFIELD_IMAGE_SIZE.x / BATTLEFIELD_IMAGE_SIZE.y
	battlefield_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	battlefield_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.add_child(battlefield_aspect)

	_battlefield_texture_rect = TextureRect.new()
	_battlefield_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_battlefield_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_battlefield_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_battlefield_texture_rect.texture = preload("res://engine/presentation/battlefield_art_catalog.gd").texture_for(combat_state.battlefield if combat_state != null else null)
	_battlefield_texture_rect.visible = _battlefield_texture_rect.texture != null
	battlefield_aspect.add_child(_battlefield_texture_rect)

	# Battle Art MVP — Piloto: adicionada ANTES de _board_layer de
	# propósito (ordem de filhos = ordem de desenho no Godot) — o
	# Battle Art do piloto fica ATRÁS da carta compacta de cada
	# posição, nunca por cima.
	_unit_art_layer = preload("res://engine/presentation/battle_unit_art_layer.gd").new()
	battlefield_aspect.add_child(_unit_art_layer)

	_board_layer = Control.new()
	_board_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_aspect.add_child(_board_layer)

	_build_all_position_widgets()

	# Banner de Resultado — sobrepõe o Battlefield (nunca reserva
	# espaço fixo, permanece invisível/sem-tamanho até a batalha
	# terminar).
	var result_overlay := CenterContainer.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(result_overlay)

	var result_vbox := VBoxContainer.new()
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 10)
	result_overlay.add_child(result_vbox)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 28)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.visible = false
	result_vbox.add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = "Continuar"
	_continue_button.visible = false
	_continue_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_continue_button.pressed.connect(_on_continue_pressed, CONNECT_DEFERRED)
	result_vbox.add_child(_continue_button)

	_build_hover_preview(area)

	return area


## ART-007-v2/FASE 9: popup de hover — uma única BattleCardView COMPLETA
## (set_compact(false), texto legível) reaproveitada pra qualquer
## posição sobre a qual o cursor passar, em vez de tentar caber Tier/
## Tipo/Classe/ATK/ESC/HP dentro da carta minúscula do tabuleiro.
## FASE 9: filho de _board_layer (nunca de "area") de propósito — é o
## MESMO Control que hospeda os 18 BattleCardView compactos e os
## rótulos de lado (_apply_side_labels()), então uma âncora fracionária
## (center_frac, ver _visual_center_frac()) cai exatamente sobre o
## slot visual real, em qualquer tamanho de janela, sem recalcular
## letterbox nenhum. Adicionado DEPOIS de _build_all_position_widgets()
## (ver ordem de chamada em _build_battlefield_area()), então desenha
## por cima de todas as cartas compactas — nunca atrás.
## FASE 10 — CAUSA RAIZ do popup não aparecer no teste manual: o
## wrapper (PanelContainer) já tinha mouse_filter = IGNORE, mas
## BattleCardView (Control puro, "_hover_preview") NUNCA definia o
## próprio mouse_filter — o padrão do Godot para Control é STOP, não
## IGNORE. Como o wrapper (com o popup dentro) é adicionado a
## _board_layer DEPOIS de todos os 18 slots (ver ordem de chamada em
## _build_battlefield_area()), ele fica por CIMA deles no Z/prioridade
## de input; assim que ficava visível, o próprio _hover_preview (STOP,
## nunca configurado) passava a interceptar o mouse na área onde foi
## desenhado — inclusive sobre o slot que o abriu. Resultado real: o
## popup, quando finalmente aparecia, imediatamente "roubava" o hover
## de volta do slot que o mostrou, disparando mouse_exited nele e
## escondendo o próprio popup — quase instantâneo, por isso "não
## aparece" ao testar manualmente. Nenhum teste headless da Fase 9
## pegou isso porque nenhum deles usa o pipeline real do Viewport (só
## chamam _on_card_mouse_entered() como função direta).
##
## FASE 11 — pedido explícito do usuário após validar a Fase 10 no
## Campo de Prova real: o popup NÃO deve mais acompanhar o pelotão
## (nem em quadrantes ao redor do slot, como nas Fases 9/10) — passa a
## ficar numa posição FIXA (canto superior esquerdo da tela, com
## margem confortável), a MESMA pra qualquer side/position, decidida
## UMA ÚNICA VEZ aqui (nunca mais recalculada por _visual_center_frac()
## a cada hover — ver _show_hover_preview(), que não reposiciona mais).
func _build_hover_preview(_area: Control) -> void:
	var wrapper := PanelContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.visible = false
	var popup_size := Vector2(HOVER_PREVIEW_WIDTH_PX, HOVER_PREVIEW_WIDTH_PX / preload("res://engine/presentation/battle_card_view.gd").CARD_ASPECT_RATIO)
	wrapper.custom_minimum_size = popup_size
	# FASE 11: canto superior esquerdo, fixo — anchors todos em 0.0 (topo
	# esquerdo de _board_layer, o mesmo espaço de coordenadas real de
	# tela dos 18 slots) com uma margem confortável (nunca encostando na
	# borda) e o tamanho real do popup, garantindo que ele sempre caiba
	# inteiro dentro da viewport disponível.
	wrapper.anchor_left = 0.0
	wrapper.anchor_top = 0.0
	wrapper.anchor_right = 0.0
	wrapper.anchor_bottom = 0.0
	wrapper.offset_left = HOVER_PREVIEW_MARGIN_PX
	wrapper.offset_top = HOVER_PREVIEW_MARGIN_PX
	wrapper.offset_right = HOVER_PREVIEW_MARGIN_PX + popup_size.x
	wrapper.offset_bottom = HOVER_PREVIEW_MARGIN_PX + popup_size.y
	_board_layer.add_child(wrapper)

	_hover_preview = preload("res://engine/presentation/battle_card_view.gd").new()
	_hover_preview.set_compact(false)
	# FASE 10: o popup é PURAMENTE visual — nunca deve competir por
	# input com o hotspot que o exibe (ver docstring acima).
	_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(_hover_preview)

	_hover_preview_wrapper = wrapper


## ART-007 secao 9/11: faixa compacta única — último evento + Log +
## Pular na MESMA linha, nunca 10+ linhas permanentes sobre o
## Battlefield.
func _build_footer_bar() -> Control:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.custom_minimum_size = Vector2(0, 30)

	_log_label = Label.new()
	_log_label.text = "Combate iniciado."
	_log_label.clip_text = true
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_log_label)

	_log_toggle_button = Button.new()
	_log_toggle_button.text = "Log"
	_log_toggle_button.toggle_mode = true
	_log_toggle_button.pressed.connect(_on_log_toggle_pressed, CONNECT_DEFERRED)
	footer.add_child(_log_toggle_button)

	# FASE 7: ação claramente acessível na mesma barra do Log — copia o
	# log ESTRUTURADO completo (nunca só as últimas linhas) pro
	# clipboard real do sistema operacional via DisplayServer.
	_copy_log_button = Button.new()
	_copy_log_button.text = "Copiar Log"
	_copy_log_button.tooltip_text = "Copia o log completo da batalha (estruturado) para a área de transferência."
	_copy_log_button.pressed.connect(_on_copy_log_pressed, CONNECT_DEFERRED)
	footer.add_child(_copy_log_button)

	_skip_button = Button.new()
	_skip_button.text = "Pular"
	_skip_button.pressed.connect(_on_skip_pressed, CONNECT_DEFERRED)
	footer.add_child(_skip_button)

	_speed_button = Button.new()
	_speed_button.text = "%dx" % int(REPLAY_SPEED_MULTIPLIERS[_replay_speed_index])
	_speed_button.pressed.connect(_on_speed_button_pressed, CONNECT_DEFERRED)
	footer.add_child(_speed_button)

	return footer


## ART-007 secao 10: painel expansível com o histórico completo —
## FECHADO não ocupa nenhum espaço (visible=false), ABERTO sobrepõe a
## parte de baixo do Battlefield sem empurrar o resto do layout.
func _build_log_drawer() -> Control:
	var drawer := PanelContainer.new()
	drawer.anchor_left = 0.0
	drawer.anchor_right = 1.0
	drawer.anchor_top = 1.0
	drawer.anchor_bottom = 1.0
	drawer.offset_bottom = -36.0
	drawer.offset_top = -260.0
	drawer.visible = false

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	drawer.add_child(scroll)

	_log_drawer_label = Label.new()
	_log_drawer_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_drawer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_log_drawer_label)

	return drawer


## ART-007 secao 13: identidade dos lados sem depender só de texto — os
## rótulos ficam ANCORADOS sobre a própria região de cada bloco 3x3 no
## Battlefield (o de cima sempre rotula o bloco de cima, o de baixo
## sempre o de baixo), reforçando a composição espacial já existente
## (Inimigo em cima/mais longe, jogador embaixo/mais perto) em vez de
## introduzir cor arbitrária.
func _apply_side_labels() -> void:
	var enemy_title: String = "INIMIGO" if player_side == 0 else "SEU EXÉRCITO"
	var player_title: String = "SEU EXÉRCITO" if player_side == 0 else "INIMIGO"

	var enemy_label := _make_side_label(enemy_title)
	var enemy_anchor_y: float = (ENEMY_TILE_ORIGIN.y - 55.0) / BATTLEFIELD_IMAGE_SIZE.y
	_anchor_side_label(enemy_label, ENEMY_TILE_ORIGIN.x / BATTLEFIELD_IMAGE_SIZE.x, enemy_anchor_y)
	_board_layer.add_child(enemy_label)

	# ART-007: ancorado abaixo do ponto de MAIOR y do bloco do jogador
	# (tile r=2,c=2 — a carta mais perto da câmera nunca desce abaixo
	# da própria base, ver _build_position_widget), nunca no canto
	# r=2,c=0 (que ficava perto demais da carta da coluna esquerda,
	# sobrepondo o rótulo).
	var player_bottom_corner: Vector2 = PLAYER_TILE_ORIGIN + 2.0 * PLAYER_TILE_E1 + 2.0 * PLAYER_TILE_E2
	var player_center_x: Vector2 = PLAYER_TILE_ORIGIN + PLAYER_TILE_E1 + PLAYER_TILE_E2
	var player_label := _make_side_label(player_title)
	var player_anchor_y: float = (player_bottom_corner.y + 55.0) / BATTLEFIELD_IMAGE_SIZE.y
	_anchor_side_label(player_label, player_center_x.x / BATTLEFIELD_IMAGE_SIZE.x, player_anchor_y)
	_board_layer.add_child(player_label)


func _make_side_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _anchor_side_label(label: Label, x_frac: float, y_frac: float) -> void:
	label.anchor_left = x_frac
	label.anchor_right = x_frac
	label.anchor_top = y_frac
	label.anchor_bottom = y_frac
	label.offset_left = -90.0
	label.offset_right = 90.0
	label.offset_top = -12.0
	label.offset_bottom = 12.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH


## Centro visual (fração 0..1 da imagem-fonte do Battlefield) da
## posição lógica (side, position) — ver POSITION_GRID e os comentários
## de ENEMY_TILE_*/PLAYER_TILE_* no topo do arquivo. player_side decide
## qual side desenha no bloco de cima (Inimigo) vs. embaixo (jogador).
func _visual_center_frac(side: int, position: int) -> Vector2:
	var grid: Vector2i = POSITION_GRID[position]
	var depth_index: int = grid.x
	var column_index: int = grid.y
	var is_top_cluster: bool = side == (1 - player_side)

	var origin: Vector2
	var e1: Vector2
	var e2: Vector2
	var r: int

	if is_top_cluster:
		origin = ENEMY_TILE_ORIGIN
		e1 = ENEMY_TILE_E1
		e2 = ENEMY_TILE_E2
		# ART-007: no bloco de cima, a Linha 1 (frente, mais perto do
		# inimigo = mais perto do CENTRO da tela) fica no lado do bloco
		# com MAIOR y medido — por isso a profundidade lógica é
		# invertida aqui (index 0 -> r=2), nunca no bloco de baixo.
		r = 2 - depth_index
	else:
		origin = PLAYER_TILE_ORIGIN
		e1 = PLAYER_TILE_E1
		e2 = PLAYER_TILE_E2
		r = depth_index

	var center_px: Vector2 = origin + float(r) * e1 + float(column_index) * e2
	return Vector2(center_px.x / BATTLEFIELD_IMAGE_SIZE.x, center_px.y / BATTLEFIELD_IMAGE_SIZE.y)


## Largura de referência (px da imagem-fonte) de UM slot do bloco —
## usada só pra dimensionar a carta (CARD_SIZE_MULTIPLIER), nunca pra
## decidir posição.
func _tile_width_px(side: int) -> float:
	var is_top_cluster: bool = side == (1 - player_side)
	return (ENEMY_TILE_E2 if is_top_cluster else PLAYER_TILE_E2).length()


## Índice de profundidade VISUAL (0 = fileira mais LONGE da câmera
## dentro do próprio bloco, 2 = mais PERTO). Teste Visual 08: não é mais
## consumido pela colocação de Battle Art (BattleUnitArtGeometry agora
## resolve tudo a partir de side/position via CELL_CENTER calibrado,
## nunca por Região de profundidade) — mantido por continuar
## correto/útil para o painel de diagnóstico do inspector
## (battle_art_pilot_inspector.gd). Mesma conta já inline em
## _visual_center_frac() (variável "r"), só exposta aqui como valor
## nomeado e reutilizável — nunca recalculada de outra forma.
## Deliberadamente NÃO reaproveita
## BattlefieldSlotGeometry.visual_depth_index() (scenes/prototype/
## battlefield_slot_geometry.gd): aquela função assume side==1 é sempre
## o cluster de cima (simplificação documentada do protótipo isolado,
## "equivalente a player_side=0 sempre") — esta view já resolve
## is_top_cluster corretamente considerando player_side, então deriva o
## índice a partir da MESMA lógica já correta, nunca da simplificação.
func _depth_index_for(side: int, position: int) -> int:
	var grid: Vector2i = POSITION_GRID[position]
	var logical_depth: int = grid.x
	var is_top_cluster: bool = side == (1 - player_side)
	return (2 - logical_depth) if is_top_cluster else logical_depth


## ART-007: cria as 18 BattleCardView já nos slots visuais corretos,
## adicionadas ao _board_layer em ordem de profundidade (mais longe
## primeiro) — assim, quando duas cartas adjacentes se sobrepõem
## visualmente (natural num grid isométrico com cartas maiores que o
## slot), a mais perto da câmera desenha por cima, reforçando "quem
## está na frente" em vez de confundir a leitura.
func _build_all_position_widgets() -> void:
	var entries: Array = []
	for side in [0, 1]:
		for position in range(1, 10):
			var center_frac: Vector2 = _visual_center_frac(side, position)
			entries.append({"side": side, "position": position, "y": center_frac.y})

	entries.sort_custom(func(a, b): return a["y"] < b["y"])

	for entry: Dictionary in entries:
		_build_position_widget(entry["side"], entry["position"])


## Cria o BattleCardView de UMA posição real do tabuleiro (ART-006/
## ART-007) — nunca um retângulo genérico: usa a identidade visual
## completa da carta oficial (ver battle_card_view.gd), posicionada
## exatamente sobre o slot visual medido no Battlefield, e registra o
## widget em _position_widgets pra _refresh_position_widget() poder
## atualizá-lo depois, sem recriar nada.
func _build_position_widget(side: int, position: int) -> Control:
	# F-046: preload() em vez do identificador global "BattleCardView"
	# — mesmo motivo já documentado pra CombatReplayCollector acima:
	# class_name novo nesta sessão, cache global de classes não
	# regenerado em execução --headless.
	var view = preload("res://engine/presentation/battle_card_view.gd").new()

	# ART-007-v2: carta minúscula CENTRALIZADA sobre o próprio quadrado
	# do slot (nunca "de pé" saindo dele) — modo compacto, só a arte,
	# ver BattleCardView.set_compact(). A leitura completa e legível
	# vive no popup de hover (_show_hover_preview()), nunca aqui.
	view.set_compact(true)

	var center_frac: Vector2 = _visual_center_frac(side, position)
	var card_w_px: float = _tile_width_px(side) * CARD_SIZE_MULTIPLIER
	var card_h_px: float = card_w_px / preload("res://engine/presentation/battle_card_view.gd").CARD_ASPECT_RATIO
	var half_w_frac: float = (card_w_px / 2.0) / BATTLEFIELD_IMAGE_SIZE.x
	var half_h_frac: float = (card_h_px / 2.0) / BATTLEFIELD_IMAGE_SIZE.y

	# FASE 12 — REMOÇÃO EXPLÍCITA: o Battlefield NUNCA teve o brilho
	# realmente pedido pelo usuário nas Fases 10/11 — reescopo explícito
	# desta tarefa: "sinais luminosos nos hotspots" sempre se referia à
	# CIDADE/interior das construções, nunca ao Battlefield. O halo
	# (battle_hotspot_glow.gd, agora hotspot_glow.gd) foi removido daqui
	# por completo — o hotspot de MOUSE (view, logo abaixo) continua
	# 100% intacto (hover/popup/unit_id/dados dinâmicos inalterados).
	view.anchor_left = center_frac.x - half_w_frac
	view.anchor_right = center_frac.x + half_w_frac
	view.anchor_top = center_frac.y - half_h_frac
	view.anchor_bottom = center_frac.y + half_h_frac
	view.offset_left = 0.0
	view.offset_right = 0.0
	view.offset_top = 0.0
	view.offset_bottom = 0.0
	view.grow_horizontal = Control.GROW_DIRECTION_BOTH
	view.grow_vertical = Control.GROW_DIRECTION_BOTH
	# STOP (não PASS): quando cartas vizinhas se sobrepõem levemente,
	# só a de cima (mais perto da câmera, desenhada por último) deve
	# responder ao hover — nunca as duas ao mesmo tempo.
	view.mouse_filter = Control.MOUSE_FILTER_STOP

	var key: int = side * 10 + position
	view.mouse_entered.connect(_on_card_mouse_entered.bind(key))
	view.mouse_exited.connect(_on_card_mouse_exited.bind(key))

	_board_layer.add_child(view)

	_position_widgets[side * 10 + position] = {
		"view": view,
		"portrait": view.portrait if view.portrait != null else null,
	}
	return view


func _apply_initial_board() -> void:
	if replay_collector == null:
		return
	for entry: Dictionary in replay_collector.initial_board:
		var key: int = entry["side"] * 10 + entry["position"]
		_live_board[key] = {
			"card_name": entry["card_name"],
			"card_class": entry["card_class"],
			"hp": entry["hp"],
			"max_hp": entry["max_hp"],
			"esc": entry["esc"],
			"max_esc": entry["max_esc"],
			"alive": true,
			"card": entry.get("card"),
			"unit_id": entry.get("unit_id"),
		}
		_unit_id_to_slot[entry["unit_id"]] = key
		_refresh_position_widget(key)
		_refresh_unit_art(entry["unit_id"], entry["side"], entry["position"], entry["card_name"])


func _refresh_position_widget(key: int) -> void:
	if not _position_widgets.has(key):
		return
	var widgets: Dictionary = _position_widgets[key]
	var view = widgets["view"]

	if not _live_board.has(key):
		view.clear()
		view.modulate.a = 1.0
		if key == _hover_key:
			_on_card_mouse_exited(key)
		return

	var unit: Dictionary = _live_board[key]
	var card: CardResource = unit.get("card")
	if card != null:
		view.set_card(card)
		view.set_stats(card.atk, unit["hp"], unit["esc"])
	view.set_alive(unit["alive"])

	# Teste Visual 08 — seção 6/11: quando a unidade tem Battle Art
	# registrada, a carta compacta some da leitura visual do Battlefield
	# (Battle Art passa a ser a representação principal), mas continua
	# existindo/funcionando de verdade (nunca visible=false, que
	# desligaria mouse_entered/mouse_exited): alpha 0 mantém o popup de
	# hover funcionando normalmente (ele fica ancorado num canto fixo,
	# nunca sobre o personagem — ver _build_hover_preview()), só a
	# miniatura sobre o slot deixa de ser desenhada. Reaplicado a cada
	# refresh (nunca uma vez só), porque widgets são reaproveitados por
	# unidades diferentes ao longo de uma batalha (ver unidade morta ->
	# nova unidade na mesma posição).
	view.modulate.a = 0.0 if ArtCatalog.has_art_for(unit.get("card_name", "")) else 1.0

	# widgets["portrait"] só existe depois que set_card() construiu o
	# BattleCardView internamente (ver battle_card_view.gd, _build()) —
	# preenchido de forma preguiçosa aqui pra test_combat_replay_view.gd
	# (F-046) continuar lendo widgets["portrait"].texture sem depender
	# de timing de _ready().
	if widgets["portrait"] == null:
		widgets["portrait"] = view.portrait

	# ART-007-v2: se a posição atualizada é a que está sob o popup de
	# hover agora (ex: um ataque muda HP/ESC enquanto o cursor
	# continua parado sobre a carta), o popup precisa refletir o valor
	# novo — nunca ficar com um número congelado enquanto visível.
	if key == _hover_key:
		_show_hover_preview(key)


## ART-007-v2/FASE 9: preenche e mostra o popup de hover (BattleCardView
## completa, ver _build_hover_preview()) com os dados REAIS da posição
## — os mesmos já em _live_board, nunca inventados. Não faz nada se a
## posição estiver vazia (nenhuma unidade viva ali pra inspecionar).
## FASE 11: NÃO reposiciona mais o popup a cada chamada — a posição é
## FIXA (canto superior esquerdo, decidida uma única vez em
## _build_hover_preview()), nunca dependente de side/position/
## _visual_center_frac(). Só os DADOS (carta/stats) mudam aqui.
func _show_hover_preview(key: int) -> void:
	if not _live_board.has(key):
		return
	var unit: Dictionary = _live_board[key]
	var card: CardResource = unit.get("card")
	if card == null:
		return
	_hover_key = key
	_hover_preview.set_card(card)
	_hover_preview.set_stats(card.atk, unit["hp"], unit["esc"])
	_hover_preview.set_alive(unit["alive"])
	_hover_preview_wrapper.visible = true


func _on_card_mouse_entered(key: int) -> void:
	_show_hover_preview(key)


func _on_card_mouse_exited(key: int) -> void:
	if _hover_key != key:
		return
	_hover_key = -1
	_hover_preview_wrapper.visible = false


func _append_log(line: String) -> void:
	_log_lines.append(line)
	_log_label.text = line
	_log_drawer_label.text = "\n".join(_log_lines)


## FASE 7 — bloco inicial do log estruturado: metadados da batalha que
## não pertencem a nenhum evento específico (seed/battle_id/regras/
## Campo de Batalha), sempre a primeira coisa no log copiado. "Se
## disponível" (pedido explícito): combat_state pode ser null (nenhum
## chamador real hoje deixa de setá-lo, mas esta view nunca assume) —
## nesse caso o bloco é escrito com os campos ausentes, nunca inventados.
func _append_structured_header() -> void:
	_structured_log_lines.append("BATTLE")
	if combat_state != null:
		_structured_log_lines.append("SEED=%s" % str(combat_state.seed_value))
		_structured_log_lines.append("BATTLE_ID=%s" % combat_state.battle_id)
		_structured_log_lines.append("RULES_VERSION=%s" % combat_state.rules_version)
		_structured_log_lines.append("BATTLEFIELD=%s" % (combat_state.battlefield.battlefield_name if combat_state.battlefield != null else ""))
	else:
		_structured_log_lines.append("SEED=(indisponível)")
	_structured_log_lines.append("")


func _append_structured(turn: int, kind: String, fields: Dictionary) -> void:
	_structured_log_lines.append("TURN %02d" % turn)
	_structured_log_lines.append(kind)
	for key: String in fields:
		_structured_log_lines.append("%s=%s" % [key, str(fields[key])])
	_structured_log_lines.append("")


func _full_structured_log_text() -> String:
	return "\n".join(_structured_log_lines)


## FASE 7 — botão "Copiar Log": copia o log ESTRUTURADO completo (nunca
## só as últimas linhas) pra área de transferência real do sistema
## operacional, via DisplayServer (funciona de verdade em Godot, não é
## só visual). O texto colado é o mesmo _full_structured_log_text() que
## os testes desta tarefa também verificam.
func _on_copy_log_pressed() -> void:
	DisplayServer.clipboard_set(_full_structured_log_text())
	_append_log("Log completo copiado para a área de transferência (%d linhas)." % _structured_log_lines.size())


func _on_skip_pressed() -> void:
	_skip_requested = true


## Botão cíclico 1x -> 2x -> 4x -> 1x — só reescreve
## DELAY_BETWEEN_EVENTS_SECONDS (já lido a cada iteração de
## _play_replay()), nunca toca CombatEngine/o resultado já resolvido.
func _on_speed_button_pressed() -> void:
	_replay_speed_index = (_replay_speed_index + 1) % REPLAY_SPEED_MULTIPLIERS.size()
	var multiplier: float = REPLAY_SPEED_MULTIPLIERS[_replay_speed_index]
	DELAY_BETWEEN_EVENTS_SECONDS = BASE_DELAY_BETWEEN_EVENTS_SECONDS / multiplier
	_speed_button.text = "%dx" % int(multiplier)
	# FASE 7: a animação de movimento nunca pode ser mais longa que o
	# próprio intervalo entre eventos (senão o próximo evento chegaria
	# com o "glide" anterior ainda em andamento) — reduzida junto com a
	# velocidade de reprodução, nunca hardcoded.
	if _unit_art_layer != null:
		_unit_art_layer.move_animation_duration_seconds = min(0.35, DELAY_BETWEEN_EVENTS_SECONDS * 0.8)


func _on_log_toggle_pressed() -> void:
	_log_drawer_open = not _log_drawer_open
	_log_drawer.visible = _log_drawer_open


func _on_continue_pressed() -> void:
	replay_finished.emit()


## Percorre replay_events em ordem cronológica real (a mesma ordem em
## que CombatEngine publicou), atualizando o tabuleiro em memória e o
## feed de log a cada passo, com uma pausa entre eventos pra ritmo
## legível — nunca reinterpreta ou reordena o que o motor produziu.
func _play_replay() -> void:
	_is_playing = true
	if replay_collector != null:
		for event: Dictionary in replay_collector.replay_events:
			_apply_replay_event(event)
			if not _skip_requested:
				await get_tree().create_timer(DELAY_BETWEEN_EVENTS_SECONDS).timeout

	_show_result()
	_is_playing = false


func _apply_replay_event(event: Dictionary) -> void:
	match event["kind"]:
		"turn_start":
			_turn_label.text = "Turno %d" % event["turn"]
			_append_structured(event["turn"], "TURN_START", {})
		"turn_end":
			_append_structured(event["turn"], "TURN_END", {})
		"move":
			_apply_move_event(event)
		"attack":
			_apply_attack_event(event)
		"heal":
			_apply_heal_event(event)
		"death":
			_apply_death_event(event)
		_:
			pass


func _view_at(key: int):
	if not _position_widgets.has(key):
		return null
	return _position_widgets[key]["view"]


## Battle Art MVP — Piloto (repassada ao Teste Visual 08): repassa
## side/position/card_name — a posição LÓGICA real (CombatBoard) e a
## identidade da carta — pra _unit_art_layer. Esta view NUNCA guarda
## nem deriva CELL_CENTER/FOOT_CENTER/escala (responsabilidade exclusiva
## de BattleUnitArtGeometry, ver Teste Visual 08) — só fornece
## side/position/identidade/eventos, como qualquer outro consumidor da
## camada de Battle Art. _unit_art_layer decide sozinha se card_name tem
## Battle Art registrada (hoje: só o piloto).
func _refresh_unit_art(unit_id: int, side: int, position: int, card_name: String) -> void:
	if _unit_art_layer == null:
		return
	_unit_art_layer.register_or_update(unit_id, side, position, card_name)


## Correção de replay visual (2026-09-02): a origem do movimento é
## localizada exclusivamente por unit_id (_unit_id_to_slot), nunca mais
## por card_name — duas unidades do mesmo lado podem compartilhar o
## mesmo nome de carta (ver comentário de _unit_id_to_slot acima).
func _apply_move_event(event: Dictionary) -> void:
	var side: int = event["side"]
	var unit_id = event["unit_id"]
	var to_key: int = side * 10 + event["to_position"]
	var from_key: int = _unit_id_to_slot.get(unit_id, -1)

	if from_key != -1 and from_key != to_key:
		var from_position: int = from_key % 10
		_live_board[to_key] = _live_board[from_key]
		_live_board.erase(from_key)
		_unit_id_to_slot[unit_id] = to_key
		_refresh_position_widget(from_key)
		_refresh_position_widget(to_key)
		_refresh_unit_art(unit_id, side, event["to_position"], event["card_name"])
		_append_structured(event["turn"], "MOVE", {
			"SIDE": side, "UNIT_ID": unit_id,
			"CARD": "\"%s\"" % event["card_name"],
			"FROM": from_position, "TO": event["to_position"],
		})
	_append_log("Turno %d: %s avança para a Posição %d." % [event["turn"], event["card_name"], event["to_position"]])


## FASE 7: attacker_unit_id/target_unit_id vêm preferencialmente dos
## campos novos e aditivos do próprio evento (ver
## combat_replay_collector.gd, "attacker_unit_id"/"target_unit_id") —
## fallback pra _live_board (mesma fonte já usada por toda esta view,
## também indexada por unit_id real) só protege um evento antigo, sem
## os campos novos. As animações abaixo NUNCA usam card_name pra
## localizar o sprite — só unit_id, repassado direto a
## BattleUnitArtLayer.
func _apply_attack_event(event: Dictionary) -> void:
	var attacker_key: int = event["side"] * 10 + event["attacker_position"]
	var target_key: int = event["target_side"] * 10 + event["target_position"]
	if _live_board.has(target_key):
		_live_board[target_key]["hp"] = event["target_hp_after"]
		_live_board[target_key]["esc"] = event["target_esc_after"]
		_refresh_position_widget(target_key)

	var attacker_unit_id = event.get("attacker_unit_id", _live_board.get(attacker_key, {}).get("unit_id", -1))
	var target_unit_id = event.get("target_unit_id", _live_board.get(target_key, {}).get("unit_id", -1))
	var attacker_card_class: String = event.get("attacker_card_class", _live_board.get(attacker_key, {}).get("card_class", ""))

	# FASE 7 — animação real sobre o Battle Art (a carta compacta fica
	# invisível pros 40 pelotões atuais, ver _refresh_position_widget()):
	# flash em quem atacou/quem sofreu dano sempre; projétil adicional
	# só pra À Distância/Mago (Corpo a Corpo/Suporte atacam adjacente,
	# sem projétil — o flash já basta).
	if _unit_art_layer != null:
		_unit_art_layer.flash_attack(attacker_unit_id)
		_unit_art_layer.flash_damage(target_unit_id)
		match attacker_card_class:
			"À Distância":
				_unit_art_layer.spawn_ranged_projectile(attacker_unit_id, target_unit_id)
			"Mago":
				_unit_art_layer.spawn_magic_projectile(attacker_unit_id, target_unit_id)

	# ART-006: flash na carta compacta preservado por compatibilidade —
	# nunca visível hoje (Battle Art cobre os 40 pelotões), mas continua
	# correto se um card_name futuro ainda não tiver Battle Art.
	var attacker_view = _view_at(attacker_key)
	if attacker_view != null:
		attacker_view.flash_attack()
	var target_view = _view_at(target_key)
	if target_view != null:
		target_view.flash_damage()

	_append_structured(event["turn"], "ATTACK", {
		"SOURCE_SIDE": event["side"], "SOURCE_UNIT_ID": attacker_unit_id,
		"SOURCE_CARD": "\"%s\"" % event["attacker_card_name"], "SOURCE_POS": event["attacker_position"],
		"TARGET_SIDE": event["target_side"], "TARGET_UNIT_ID": target_unit_id,
		"TARGET_CARD": "\"%s\"" % event["target_card_name"], "TARGET_POS": event["target_position"],
	})
	_append_structured(event["turn"], "DAMAGE", {
		"SOURCE_UNIT_ID": attacker_unit_id, "TARGET_UNIT_ID": target_unit_id,
		"TARGET_POS": event["target_position"], "AMOUNT": event["damage_applied_to_hp"],
	})

	_append_log("Turno %d: %s ataca %s — %d de dano (ESC absorveu %d)." % [
		event["turn"], event["attacker_card_name"], event["target_card_name"],
		event["damage_dealt"], event["damage_absorbed_by_shield"]
	])


## FASE 7: healer_unit_id/healer_position/target_unit_id vêm dos campos
## novos e aditivos de combat_replay_collector.gd ("healer_unit_id"/
## "healer_position"/"target_unit_id") — sem eles não era possível
## desenhar o feixe FONTE->ALVO nem preencher SOURCE_POS no log (o
## evento antigo só tinha "side", nunca a posição de quem curou).
## Fallback pra _live_board só protege um evento antigo sem os campos
## novos (SOURCE_POS fica -1 nesse caso raro, nunca inventado).
func _apply_heal_event(event: Dictionary) -> void:
	var target_key: int = event["target_side"] * 10 + event["target_position"]
	if _live_board.has(target_key):
		_live_board[target_key]["hp"] = event["target_hp_after"]
		_refresh_position_widget(target_key)

	var healer_unit_id = event.get("healer_unit_id", -1)
	var healer_position = event.get("healer_position", -1)
	var target_unit_id = event.get("target_unit_id", _live_board.get(target_key, {}).get("unit_id", -1))

	# FASE 7 — feixe direcional FONTE -> ALVO (cor distinta do dano/
	# ataque, ver spawn_heal_beam()) + flash de "chegada" no alvo, ambos
	# só por unit_id.
	if _unit_art_layer != null:
		_unit_art_layer.spawn_heal_beam(healer_unit_id, target_unit_id)
		_unit_art_layer.flash_heal(target_unit_id)

	var target_view = _view_at(target_key)
	if target_view != null:
		target_view.flash_heal()

	_append_structured(event["turn"], "HEAL", {
		"SOURCE_UNIT_ID": healer_unit_id, "SOURCE_CARD": "\"%s\"" % event["healer_card_name"], "SOURCE_POS": healer_position,
		"TARGET_UNIT_ID": target_unit_id, "TARGET_CARD": "\"%s\"" % event["target_card_name"], "TARGET_POS": event["target_position"],
		"AMOUNT": event["heal_amount"],
	})

	_append_log("Turno %d: %s cura %s em %d." % [event["turn"], event["healer_card_name"], event["target_card_name"], event["heal_amount"]])


## Correção de replay visual (2026-09-02): antes, esta função só marcava
## "alive=false" no live_board sem NUNCA remover a entrada — o widget
## nunca recaía no ramo "vazio" de _refresh_position_widget() (que já
## existia e já chama view.clear()), então a unidade morta ficava pra
## sempre ocupando o slot, só escurecida ("carta fantasma"). A partir de
## agora a entrada é removida (mesma técnica já usada por
## _apply_move_event() para a posição de origem), deixando o slot
## visualmente disponível. play_death() é chamado ANTES da remoção —
## reservado para um efeito/animação de morte temporizado real (Battle
## Art, fora do escopo desta correção); hoje ele só aplica um tingimento
## instantâneo, então na prática o slot já aparece vazio no mesmo frame.
func _apply_death_event(event: Dictionary) -> void:
	var unit_id = event["unit_id"]
	var key: int = _unit_id_to_slot.get(unit_id, event["side"] * 10 + event["position"])

	var view = _view_at(key)
	if view != null:
		view.play_death()

	if _live_board.has(key):
		_live_board.erase(key)
	_unit_id_to_slot.erase(unit_id)
	_refresh_position_widget(key)
	if _unit_art_layer != null:
		# FASE 7: o efeito cosmético é disparado ANTES de remove_unit()
		# (precisa do sprite/posição ainda registrados em _units), mas
		# nunca atrasa a remoção real — spawn_death_fade() nunca toca
		# _units/unit_count(), a garantia "sem fantasma" continua
		# exclusivamente sobre remove_unit() logo abaixo.
		_unit_art_layer.spawn_death_fade(unit_id)
		_unit_art_layer.remove_unit(unit_id)

	_append_structured(event["turn"], "DEATH", {
		"UNIT_ID": unit_id, "SIDE": event["side"],
		"CARD": "\"%s\"" % event["card_name"], "POSITION": event["position"],
	})
	_append_log("Turno %d: %s foi derrotado." % [event["turn"], event["card_name"]])


func _show_result() -> void:
	if combat_state == null:
		return
	var result_text: String = "Empate."
	if combat_state.winner_side == player_side:
		result_text = "Vitória!"
	elif combat_state.winner_side != -1:
		result_text = "Derrota."
	_result_label.text = "%s (Turno %d)" % [result_text, combat_state.turn]
	_result_label.visible = true
	_skip_button.visible = false
	_continue_button.visible = true

	if auto_continue_when_finished:
		_on_continue_pressed()
