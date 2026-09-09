extends Control
## CityPanel (CITY.md)
##
## O hub principal do jogo — Cidade espacial (F-023): a arte já
## existente City.png (Assets/MVP/Construções/, fora da árvore do
## projeto Godot — ver _load_city_texture()) como composição visual
## única, com 7 regiões clicáveis invisíveis sobre as construções já
## identificadas em F-021/F-022, mais um painel contextual único que
## expõe as mesmas ações/handlers de sempre (Abrir/Evoluir). Nenhuma
## arte nova, nenhuma construção isolada — a mesma imagem completa da
## Cidade inteira, com hitboxes proporcionais por cima.
##
## Grupo "Construções" (Nível + Evoluir, InstitutionalConstructionResolver/
## CityResolver, inalterados): Capital, Centro de Comando, Academia,
## Núcleo de Energia, Depósitos.
## Grupo "Consulta" (sem Nível/Evoluir, só Abrir): Biblioteca,
## Observatório — representadas fisicamente na arte por usabilidade
## (F-022/F-023), sem se tornarem construções canônicas: nenhum Nível,
## custo ou dependência de Capital foi adicionado a elas.
## World Map Gate (WORLD_MAP_GATE.md): mesmo grupo "Consulta" —
## localização própria da Cidade, sem Nível/Evoluir, só Abrir. Hitbox
## sobre o portão físico já desenhado na arte (torres gêmeas + arco na
## base da praça, abaixo da fonte) — decisão revertida explicitamente
## pelo dono do projeto: deixou de ser acessada através do Centro de
## Comando (ver COMMAND_CENTER.md/COMMAND_CENTER_UI.md). Retângulo
## calibrado por inspeção visual direta da imagem (não por varredura de
## cor — o portão é cercado de outros elementos azuis na arte, como
## bandeiras e o próprio domo do Núcleo de Energia, que confundiriam
## uma varredura automática); primeira aproximação, sujeita a ajuste
## após inspeção direta no editor.
## League Hall (F-016: não canônico) permanece puramente decorativo na
## arte — nenhuma hitbox.
##
## Mesmo padrão de sempre: árvore em código, sem estado próprio (exceto
## qual construção está selecionada no painel contextual),
## reconstruída a cada ação relevante.

const RAW_RESOURCES: Array[String] = ["ferro_negro", "cristais_arcanos", "essencia_vital"]
const RAW_RESOURCE_LABELS: Dictionary = {
	"ferro_negro": "Ferro Negro", "cristais_arcanos": "Cristais Arcanos", "essencia_vital": "Essência Vital",
}
const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

const ACADEMIA_SCENE: String = "res://scenes/city/panels/academia_panel.tscn"
const BIBLIOTECA_SCENE: String = "res://scenes/city/panels/biblioteca_panel.tscn"
const OBSERVATORIO_SCENE: String = "res://scenes/city/panels/observatorio_panel.tscn"
const COMMAND_CENTER_SCENE: String = "res://scenes/command_center/command_center_panel.tscn"
## CAPITAL — Implementação inicial da tela: única linha adicionada
## nesta tarefa a city_panel.gd (o mapa/hitboxes/HUD da Cidade em si
## não foram tocados) — sem isso, clicar em "capital" continuaria sem
## efeito mesmo já existindo uma tela própria pra abrir.
const CAPITAL_SCENE: String = "res://scenes/city/panels/capital_panel.tscn"

## DEPOSITO — reestruturação do Depósito (DEPOSITS.md): passou a ter
## tela própria (hub + 4 hotspots + 4 áreas internas), mesmo padrão de
## Biblioteca/Observatório, deixando de ser "só um botão Evoluir" no
## painel contextual legado (ver comentário abaixo).
const DEPOSITO_SCENE: String = "res://scenes/city/panels/deposito_panel.tscn"

## NUCLEO_DE_ENERGIA — hub visual (energy_core_hub_panel.gd,
## energy core.png) com um único hotspot sobre o reator central, que
## abre a tela de "Evolução do Núcleo" (energy_core_panel.gd,
## energy_core-main.png). Clicar na hitbox de Cidade abre o hub
## (Cidade -> Núcleo de Energia -> popup de evolução). Energy
## Distribution/Crystal Processing/Power Network NÃO fazem parte do
## MVP atual — nenhum hotspot foi criado para elas.
const ENERGY_CORE_SCENE: String = "res://scenes/city/panels/energy_core_hub_panel.tscn"

## WORLD_MAP_GATE — deixou de ser acessado através do Centro de Comando
## (WORLD_MAP_GATE.md, "Acesso Atual"): agora é uma localização própria
## da Cidade, mesmo grupo "Consulta" de Biblioteca/Observatório (sem
## Nível/Evoluir, só Abrir). Cena reaproveitada sem alteração —
## `world_map_gate_panel.gd` continua encaminhando para
## PvE/PvP/Minas exatamente como antes.
const WORLD_MAP_GATE_SCENE: String = "res://scenes/world_map_gate/world_map_gate_panel.tscn"

## CityPanel_NAVIGATION: destino de navegação DIRETA por construção —
## clicar na hitbox abre esta cena imediatamente, sem painel
## intermediário (ver _navigate_to_building()). Só as construções que
## já possuem uma tela própria aparecem aqui.
const BUILDING_SCENES: Dictionary = {
	"capital": CAPITAL_SCENE,
	"academia": ACADEMIA_SCENE,
	"biblioteca": BIBLIOTECA_SCENE,
	"observatorio": OBSERVATORIO_SCENE,
	"centro_de_comando": COMMAND_CENTER_SCENE,
	"depositos": DEPOSITO_SCENE,
	"nucleo_de_energia": ENERGY_CORE_SCENE,
	"world_map_gate": WORLD_MAP_GATE_SCENE,
}

## City.png é 1536x1024 (F-021/F-022). F-025: cópia byte-idêntica
## trazida para dentro da árvore do projeto (Game/assets/art/City.png,
## MD5 confirmado idêntico ao original em Assets/MVP/Construções/, que
## permanece intocado) — carregada normalmente via res://, sem
## depender de nenhum caminho absoluto do sistema de arquivos, pra
## funcionar também numa build exportada.
const CITY_TEXTURE: Texture2D = preload("res://assets/art/City.png")
const CITY_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

## Altura fixa (px) da faixa de HUD superior — CityPanel_LAYOUT (esta
## sessão): usada tanto por _build_top_hud() (define offset_bottom da
## faixa) quanto por _maybe_show_tutorial_hint() (posiciona o banner
## logo abaixo dela, nunca sobre ela) — único número, nunca duplicado.
const TOP_HUD_HEIGHT: float = 56.0

## CityPanel_LAYOUT: faixa de proporção de JANELA (não da imagem — essa
## continua fixa em CITY_IMAGE_ASPECT_RATIO, nunca mudada, é o que
## garante zero distorção) dentro da qual STRETCH_COVER pode cortar a
## imagem livremente SEM alcançar nenhuma BUILDING_REGIONS — derivada
## diretamente das margens reais entre cada região e a borda da
## imagem (medição, não palpite):
##   vertical: topo 3% (Capital) / baixo 27% (após Depósitos/Núcleo) ->
##     corte vertical seguro (sempre embaixo, ver ALIGNMENT_BEGIN) até
##     razão de janela ~2.05.
##   horizontal: esquerda 5% (Depósitos) / direita 8% (Núcleo de
##     Energia) -> corte horizontal seguro (simétrico, ver
##     ALIGNMENT_CENTER) até razão de janela ~1.35.
## Fora dessa faixa (janelas muito largas tipo ultrawide, ou muito
## estreitas/quadradas — ver 900x900 no relatório da sessão, onde
## Biblioteca/Depósitos saíam parcialmente da tela) uma pequena barra
## residual aparece em vez de cortar um prédio — sempre MENOR que a
## barra que STRETCH_FIT produziria, nunca maior.
const SAFE_WINDOW_ASPECT_MIN: float = 1.35
const SAFE_WINDOW_ASPECT_MAX: float = 2.05

var _city_area: Control
var _city_safe_zone: Control

## FASE 12: "key" (mesma chave de BUILDING_REGIONS/BUILDING_SCENES) ->
## HotspotGlow — reconstruído a cada _build_static_structure() (mesmo
## ciclo de vida de _building_glows/hitboxes), nunca persistido entre
## reconstruções.
var _building_glows: Dictionary = {}

## Regiões clicáveis (frações 0.0-1.0 da imagem City.png), visualmente
## calibradas em F-022/F-023 por inspeção direta da imagem. Núcleo de
## Energia usa APENAS o domo de cristal azul (F-022 item 6) — nunca a
## estrutura menor adjacente, nunca a região inteira do quadrante
## inferior-direito, deliberadamente sem tocar o Centro de Comando nem
## o League Hall (decorativo, sem hitbox).
const BUILDING_REGIONS: Dictionary = {
	"capital": {"rect": Rect2(0.36, 0.03, 0.25, 0.29), "label": "Capital"},
	"biblioteca": {"rect": Rect2(0.09, 0.14, 0.20, 0.19), "label": "Biblioteca"},
	"observatorio": {"rect": Rect2(0.74, 0.07, 0.16, 0.25), "label": "Observatório"},
	"academia": {"rect": Rect2(0.19, 0.38, 0.20, 0.17), "label": "Academia"},
	"centro_de_comando": {"rect": Rect2(0.63, 0.37, 0.20, 0.18), "label": "Centro de Comando"},
	"depositos": {"rect": Rect2(0.05, 0.58, 0.19, 0.11), "label": "Depósitos"},
	"nucleo_de_energia": {"rect": Rect2(0.77, 0.58, 0.15, 0.15), "label": "Núcleo de Energia"},
	"world_map_gate": {"rect": Rect2(0.41, 0.645, 0.25, 0.31), "label": "World Map Gate"},
}

## CityPanel_HUD_TYPOGRAPHY: "Nível de Conta"/"XP"/"PG" — antes um único
## Label concatenado com " | ", agora 3 caixas independentes (ver
## _build_conta_chip()), cada uma com seu próprio Label num Dictionary
## por chave ("nivel"/"xp"/"pg"), mesmo padrão já usado por
## _recursos_amount_labels/_fragmento_labels neste arquivo.
var _conta_labels: Dictionary = {}  # "nivel"|"xp"|"pg" -> Label
## ART-005: ícones construídos 1x (nunca mudam) — só o texto de cada
## Label é atualizado a cada refresh(), mesmo padrão já usado por
## _conta_labels/_fragmento_labels neste arquivo (diferente de outros
## painéis do projeto, refresh() aqui NUNCA reconstrói a árvore).
var _recursos_amount_labels: Dictionary = {}  # resource_name -> Label
## CityPanel_HUD_TYPOGRAPHY: idem — 3 caixas independentes por Facção
## em vez de um único Label " | "-separado.
var _fragmento_labels: Dictionary = {}  # faction_name -> Label
## F-009: mensagem visível quando "Evoluir" é rejeitado (ex: recursos
## insuficientes) — antes só existia um print() no console, que o
## jogador nunca vê; o clique parecia não fazer nada.
var _evolve_status_label: Label

var _city_texture_rect: TextureRect
var _top_hud: Control
var _bottom_hud: Control
## CityPanel_BUILDING_HOVER: chip único e reaproveitado (mesmo padrão
## de _contextual_panel) — reposicionado/preenchido a cada
## mouse_entered de uma hitbox, escondido a cada mouse_exited. Nunca
## reconstrói a árvore, só troca texto+posição+visibilidade.
var _hover_name_container: Control
var _hover_name_label: Label
var _contextual_panel: PanelContainer
var _contextual_content: VBoxContainer
## Qual construção está aberta no painel contextual no momento ("" =
## nenhuma) — refresh() usa isto pra manter o painel atualizado depois
## de um Evoluir, sem precisar de um novo clique do jogador.
var _selected_building_key: String = ""

var _loading_label: Label = null

## Sincroniza o tempo real periodicamente enquanto o jogador fica
## parado na tela principal — sem isso, a Cidade era a única tela
## importante do jogo que nunca chamava GameRuntime.sync() sozinha,
## então Energia/Minas/Academia/Recrutamento só avançavam quando o
## jogador navegava pra outra tela e voltava. Bug real relatado: um
## Exército ficou preso com pouca Energia por mais de 1h real parado
## aqui, sem recuperar.
var _process_accumulator: float = 0.0
const PROCESS_SYNC_INTERVAL_SECONDS: float = 5.0


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	_show_loading_indicator()
	# Força pelo menos 2 frames renderizarem ANTES do travamento
	# síncrono de WorldBootstrap — sem isso, a janela ficaria
	# completamente parada desde o frame 0, sem nunca mostrar essa
	# mensagem (confirmado: um único frame às vezes não é suficiente
	# pra garantir que o compositor já desenhou algo na tela).
	await get_tree().process_frame
	await get_tree().process_frame

	WorldBootstrap.ensure_world_loaded()
	_hide_loading_indicator()

	if not KingdomState.kingdom.starter_kit_used:
		_show_starter_kit()
		return

	_build_static_structure()
	refresh()
	_maybe_show_tutorial_hint()
	_maybe_show_restoration_warning()
	print("[CityPanel] Pronto. Nível de Conta: %d" % KingdomState.kingdom.account_level())


func _show_starter_kit() -> void:
	var kit_panel: StarterKitPanel = load("res://scenes/city/panels/starter_kit_panel.tscn").instantiate()
	kit_panel.kit_chosen.connect(_on_starter_kit_chosen.bind(kit_panel))
	add_child(kit_panel)


func _on_starter_kit_chosen(kit_panel: StarterKitPanel) -> void:
	kit_panel.queue_free()
	_build_static_structure()
	refresh()
	_maybe_show_tutorial_hint()
	_maybe_show_restoration_warning()
	print("[CityPanel] Pronto (após Kit Inicial). Nível de Conta: %d" % KingdomState.kingdom.account_level())


## Achado da Auditoria Final (FASE 21.8): ExpeditionPersistenceResolver
## descartava Expedições salvas cuja Temporada/Território não existe
## mais no Mundo atual (ex.: rotação real de Temporada) sem nenhuma
## comunicação ao jogador — perda de dado silenciosa. Kingdom.
## pending_restoration_warnings é preenchido só nesse cenário de falha;
## exibido uma única vez por boot, num AcceptDialog nativo (sem inventar
## componente visual novo pra um caso raro), e esvaziado logo em
## seguida — nunca reaparece nem é persistido em disco.
func _maybe_show_restoration_warning() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.pending_restoration_warnings.is_empty():
		return

	var dialog := AcceptDialog.new()
	dialog.dialog_text = "\n\n".join(kingdom.pending_restoration_warnings)
	dialog.title = "Aviso"
	kingdom.pending_restoration_warnings.clear()
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


## TUT-001, Passo 1/4 (Cidade): mostrado uma única vez, na primeira vez
## que o jogador vê a Cidade depois do Kit Inicial — nunca reaparece
## depois (gate duplo: tutorial_step precisa estar exatamente no passo
## da Cidade, E o tutorial como um todo não pode já estar concluído).
func _maybe_show_tutorial_hint() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	if kingdom.has_progress_flag("tutorial_concluido") or kingdom.tutorial_step != Kingdom.TUTORIAL_STEP_CIDADE:
		return

	# Sem anotação de tipo (Variant): TutorialHintBanner é um class_name
	# novo desta sessão, ainda não resolvível como TIPO num identificador
	# bare até uma passada de --import (mesma observação de
	# pve_panel.gd/_play_battle_replays() sobre CombatReplayView).
	var banner = preload("res://scenes/tutorial/tutorial_hint_banner.gd").new()
	banner.setup(
		"Bem-vindo ao seu Reino!",
		"Esta é a sua Cidade. Vá até o Centro de Comando > Exércitos para ver o Exército que você já formou no Kit Inicial.",
		"Passo 1 de 4"
	)
	# CityPanel_LAYOUT: o banner (TutorialHintBanner, compartilhado com
	# outras telas) sempre ancora no topo do próprio pai — desloca-se
	# TOP_HUD_HEIGHT + folga pra nunca sobrepor o novo HUD integrado
	# da Cidade (título/Nível/XP/PG). Ajuste feito aqui, de fora,
	# depois de setup() — nunca dentro do script compartilhado, que
	# continua igual pras outras telas (Exércitos, PvE).
	banner.offset_top = TOP_HUD_HEIGHT + 8.0
	banner.continue_pressed.connect(_on_tutorial_hint_continue.bind(banner), CONNECT_DEFERRED)
	add_child(banner)


func _on_tutorial_hint_continue(banner: Control) -> void:
	KingdomState.kingdom.tutorial_step = Kingdom.TUTORIAL_STEP_EXERCITO
	banner.queue_free()


func _show_loading_indicator() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.name = "LoadingBackground"
	add_child(background)

	_loading_label = Label.new()
	_loading_label.text = "Carregando o Mundo... (só na primeira vez — gera o conteúdo da Temporada)"
	_loading_label.set_anchors_preset(Control.PRESET_CENTER)
	_loading_label.add_theme_font_size_override("font_size", 20)
	add_child(_loading_label)


func _hide_loading_indicator() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_loading_label = null


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# --- CityPanel_LAYOUT (esta sessão, corrige o "mapa pequeno com
	# barras pretas + HUD flutuando por cima"): a Cidade agora ocupa a
	# JANELA INTEIRA — nenhuma VBoxContainer reduzindo a área do mapa
	# pra abrir espaço pra uma barra de status separada. Título/
	# recursos/facções passam a ser um OVERLAY sobre o próprio mapa
	# (adicionados depois, desenham por cima), nunca uma faixa que rouba
	# altura da Cidade.
	#
	# STRETCH_COVER (nunca mais STRETCH_FIT) preenche a janela
	# preservando a proporção 1536x1024 (sem stretch independente em
	# X/Y — AspectRatioContainer nativo, nunca matemática de letterbox
	# manual), cortando o excesso da imagem em vez de sobrar barra
	# preta. alignment_vertical = BEGIN garante que o corte vertical
	# (janela mais larga que 1536:1024, caso comum) aconteça só embaixo:
	# a fileira de cima da Cidade (Capital) fica sempre visível.
	#
	# _city_safe_zone (entre city_area e o AspectRatioContainer): trava
	# a proporção EFETIVA disponível pro corte dentro de
	# [SAFE_WINDOW_ASPECT_MIN, SAFE_WINDOW_ASPECT_MAX] — sem essa trava,
	# uma janela muito larga (ultrawide) ou muito estreita/quadrada
	# faria o corte alcançar Depósitos/Núcleo de Energia ou
	# Biblioteca/Depósitos (medido e confirmado a 900x900 antes desta
	# correção). _update_city_safe_zone() recalcula a cada
	# redimensionamento; fora da faixa segura sobra uma barra pequena
	# (sempre menor que STRETCH_FIT produziria), nunca corta um prédio.
	_city_area = Control.new()
	_city_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_city_area.clip_contents = true
	add_child(_city_area)

	_city_safe_zone = Control.new()
	_city_safe_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	_city_area.add_child(_city_safe_zone)
	_city_area.resized.connect(_update_city_safe_zone)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = CITY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
	_city_safe_zone.add_child(aspect)

	_city_texture_rect = TextureRect.new()
	_city_texture_rect.texture = CITY_TEXTURE
	_city_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	# F-025 (causa raiz do bug de escala do F-024): expand_mode por
	# padrão é EXPAND_KEEP_SIZE, que faz get_minimum_size() retornar o
	# tamanho NATIVO da textura (1536x1024) — um Container nunca
	# encolhe um filho abaixo do seu tamanho mínimo, então isso forçava
	# o próprio AspectRatioContainer a ficar preso em 1536x1024,
	# ignorando o espaço disponível de verdade. EXPAND_IGNORE_SIZE zera
	# o tamanho mínimo, deixando o AspectRatioContainer calcular o
	# retângulo com base no espaço real disponível (continua
	# necessário com STRETCH_COVER pelo mesmo motivo).
	_city_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_city_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(_city_texture_rect)

	# --- Regiões clicáveis: filhas do TextureRect, ancoradas por
	# fração (0.0-1.0) do seu próprio retângulo — acompanham a imagem
	# automaticamente em qualquer redimensionamento OU corte (COVER),
	# porque a âncora fracionária é sempre relativa ao retângulo real
	# do TextureRect, nunca a coordenadas absolutas de tela. Nenhuma
	# mudança nesta parte: o mesmo mecanismo que já sincronizava as
	# hitboxes em STRETCH_FIT continua válido em STRETCH_COVER — o que
	# muda é só quanto do TextureRect fica visível (recortado pelo
	# clip_contents de city_area), nunca a posição relativa da hitbox
	# dentro dele. ---
	for key: String in BUILDING_REGIONS:
		_city_texture_rect.add_child(_build_hitbox(key))

	# Primeiro cálculo — o sinal "resized" só dispara em mudanças
	# FUTURAS de tamanho; sem esta chamada a proporção ficaria "vazia"
	# (Control recém-criado, size (0,0)) até a janela ser redimensionada
	# uma vez. call_deferred: precisa rodar depois que city_area já
	# recebeu seu tamanho real do primeiro layout pass (mesmo motivo já
	# documentado por outras telas do projeto — um Control acabado de
	# entrar na árvore ainda não tem size final no mesmo frame).
	_update_city_safe_zone.call_deferred()

	# --- HUD superior (CIDADE + Nível/XP/PG + recursos brutos) e faixa
	# inferior (Fragmentos por Facção) — overlays SEM área própria no
	# layout (Controls soltos, adicionados depois de city_area pra
	# desenhar por cima do mapa) e sem consumir clique nenhum
	# (mouse_filter=IGNORE em toda a árvore, ver _build_top_hud/
	# _build_bottom_hud) — as hitboxes dos prédios embaixo continuam
	# clicáveis mesmo onde o HUD visualmente sobrepõe o mapa. ---
	_top_hud = _build_top_hud()
	add_child(_top_hud)

	_bottom_hud = _build_bottom_hud()
	add_child(_bottom_hud)

	# --- CityPanel_BUILDING_HOVER: chip do nome da construção sob o
	# cursor — MESMO estilo dos chips do HUD (_build_hud_chip(), nunca
	# duplicado), escondido até o primeiro mouse_entered de uma
	# hitbox. Adicionado depois de top/bottom HUD pra desenhar por
	# cima deles se necessário (ex: prédios perto da borda superior). ---
	var hover_chip: Dictionary = _build_hud_chip(HUD_NEUTRAL_ACCENT)
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	# Fora do fluxo de qualquer Container-pai (posição calculada
	# manualmente por construção em _on_hitbox_mouse_entered) — mesma
	# técnica de _contextual_panel logo abaixo.
	_hover_name_container.anchor_left = 0.0
	_hover_name_container.anchor_top = 0.0
	_hover_name_container.anchor_right = 0.0
	_hover_name_container.anchor_bottom = 0.0
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Painel contextual único (F-023): oculto até o jogador clicar
	# numa construção. Fica por cima de tudo (adicionado por último —
	# Godot desenha filhos depois na frente). ---
	_contextual_panel = PanelContainer.new()
	_contextual_panel.visible = false
	_contextual_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# ART-002: offset_top ficou mais negativo (-160 -> -290) só pra
	# abrir espaço pra ilustração do prédio (~130px de altura) no topo
	# do painel — offset_bottom/left/right (largura e ancoragem)
	# continuam exatamente os mesmos de antes, mesmo mecanismo de
	# layout (PRESET_CENTER_BOTTOM + offsets absolutos) já usado aqui.
	_contextual_panel.offset_top = -290
	_contextual_panel.offset_bottom = -20
	_contextual_panel.offset_left = -220
	_contextual_panel.offset_right = 220
	add_child(_contextual_panel)
	_contextual_content = VBoxContainer.new()
	_contextual_content.add_theme_constant_override("separation", 6)
	_contextual_panel.add_child(_contextual_content)


func _build_hitbox(key: String) -> Control:
	var region: Dictionary = BUILDING_REGIONS[key]
	var rect: Rect2 = region["rect"]

	# FASE 12: sinal luminoso discreto sobre a construção — adicionado
	# ANTES da hitbox de propósito (desenha atrás dela; a hitbox em si
	# nunca desenha nada, então a ordem não afeta a leitura visual, só
	# documenta a convenção). Reaproveita a MESMA região fracionária já
	# calibrada em BUILDING_REGIONS (nenhuma coordenada nova) — a
	# fábrica HotspotGlow.attach_to_region() centraliza um marcador
	# PEQUENO (tamanho fixo, nunca do tamanho da região inteira) nesse
	# retângulo. Guardado em _building_glows pra _on_hitbox_mouse_entered/
	# _exited poderem intensificar/normalizar o brilho.
	# Sem anotação estática de tipo (Variant): HotspotGlow é um
	# class_name novo nesta sessão — o cache global de classes do Godot
	# só é regenerado por uma varredura do Editor, que nunca roda numa
	# execução --headless (mesmo motivo já documentado em
	# combat_replay_view.gd pra CombatReplayCollector/BattleCardView).
	var glow = preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(_city_texture_rect, rect)
	_building_glows[key] = glow

	var hitbox := Control.new()
	hitbox.name = "Hitbox_%s" % key
	hitbox.anchor_left = rect.position.x
	hitbox.anchor_top = rect.position.y
	hitbox.anchor_right = rect.position.x + rect.size.x
	hitbox.anchor_bottom = rect.position.y + rect.size.y
	hitbox.offset_left = 0
	hitbox.offset_top = 0
	hitbox.offset_right = 0
	hitbox.offset_bottom = 0
	hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# CityPanel_BUILDING_HOVER: tooltip NATIVO do Godot removido (era o
	# fundo preto/opaco reportado) — nome da construção agora é um chip
	# próprio, mesma aparência dos painéis do HUD superior, ver
	# _on_hitbox_mouse_entered()/_build_hud_chip().
	hitbox.gui_input.connect(_on_hitbox_gui_input.bind(key))
	hitbox.mouse_entered.connect(_on_hitbox_mouse_entered.bind(hitbox, region["label"], key))
	hitbox.mouse_exited.connect(_on_hitbox_mouse_exited.bind(key))
	return hitbox


## CityPanel_LAYOUT: faixa superior — título "Cidade" + Nível/XP/PG +
## recursos brutos, num painel translúcido que se lê como parte da
## composição da Cidade (fundo com opacidade, nunca texto solto sobre
## o mapa). mouse_filter=IGNORE em toda a árvore (painel + linha +
## labels): é puramente informativo, nunca deve roubar cliques das
## hitboxes dos prédios por baixo, mesmo onde se sobrepõe
## visualmente (ex: topo da Capital).
func _build_top_hud() -> Control:
	# CityPanel_HUD_INTEGRATION: sem fundo/faixa contínua — o mapa
	# continua visível por trás. "Cidade" removido (não substituído por
	# outro título, ver pedido desta etapa). Nível de Conta/XP/PG viram
	# 3 caixas independentes (_build_hud_chip), nunca um Label " | "-
	# concatenado.
	var bar := Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 0.0
	bar.anchor_bottom = 0.0
	bar.offset_top = 0.0
	bar.offset_bottom = TOP_HUD_HEIGHT

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.anchor_right = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 16.0
	row.offset_right = -16.0
	row.offset_top = 8.0
	row.offset_bottom = -8.0
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	var conta_specs: Array[Dictionary] = [
		{"key": "nivel", "label": "Nível de Conta"},
		{"key": "xp", "label": "XP"},
		{"key": "pg", "label": "PG"},
	]
	for spec: Dictionary in conta_specs:
		var chip: Dictionary = _build_hud_chip(HUD_NEUTRAL_ACCENT)
		row.add_child(chip["container"])
		_conta_labels[spec["key"]] = chip["label"]

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	# ART-005: ícone real por recurso (RAW_RESOURCES/RESOURCE_ARCANE_CRYSTAL
	# etc., F-049) em vez de um único Label de texto concatenado —
	# construído 1x aqui, texto de cada quantidade atualizado em
	# refresh(). Some sozinho (sem quebrar o texto) se um recurso
	# específico não tiver ícone integrado.
	var recursos_hbox := HBoxContainer.new()
	recursos_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recursos_hbox.add_theme_constant_override("separation", 4)
	row.add_child(recursos_hbox)
	for resource: String in RAW_RESOURCES:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = preload("res://engine/presentation/resource_art_catalog.gd").texture_for(resource)
		icon.visible = icon.texture != null
		recursos_hbox.add_child(icon)

		var amount_label := Label.new()
		_style_hud_label(amount_label, HUD_INFO_FONT_SIZE, HUD_INFO_COLOR)
		amount_label.clip_text = true
		recursos_hbox.add_child(amount_label)
		_recursos_amount_labels[resource] = amount_label

	_evolve_status_label = Label.new()
	_style_hud_label(_evolve_status_label, HUD_INFO_FONT_SIZE, Color(1.0, 0.75, 0.55))
	row.add_child(_evolve_status_label)

	return bar


## CityPanel_LAYOUT: faixa inferior — Império/Natureza/Mortos-Vivos,
## ancorada embaixo da tela (sobre a margem de ~27% que sobra abaixo do
## último prédio depois do corte COVER, ver _build_static_structure()).
## CityPanel_HUD_TYPOGRAPHY: 3 caixas independentes (_build_hud_chip),
## uma por Facção, cada uma com um acento de cor sutil (HUD_FACTION_ACCENTS)
## — nunca um único Label " | "-concatenado, nunca uma faixa contínua.
func _build_bottom_hud() -> Control:
	var bar := Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -44.0
	bar.offset_bottom = 0.0

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)

	for faction: String in FACTIONS:
		var accent: Color = HUD_FACTION_ACCENTS.get(faction, HUD_NEUTRAL_ACCENT)
		var chip: Dictionary = _build_hud_chip(accent)
		row.add_child(chip["container"])
		_fragmento_labels[faction] = chip["label"]

	return bar


## CityPanel_HUD_TYPOGRAPHY: referência ÚNICA e centralizada de
## tipografia do HUD — Cinzel (Game/assets/fonts/Cinzel-SemiBold.ttf,
## cópia byte-idêntica do arquivo já adicionado pelo usuário em
## Assets/fonts/, mesmo princípio já usado por CITY_TEXTURE/City.png:
## o original fora da árvore do projeto permanece intocado). Nenhuma
## outra tela/sistema referencia esta constante — só o HUD da Cidade.
## Quando a fonte precisar trocar, este é o ÚNICO ponto a editar.
const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")

const HUD_INFO_FONT_SIZE: int = 15
const HUD_FRAGMENTS_FONT_SIZE: int = 14
const HUD_INFO_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_OUTLINE_SIZE: int = 5
const HUD_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HUD_SHADOW_OFFSET: int = 2

## CityPanel_HUD_TYPOGRAPHY seção 4: acento MUITO discreto por Facção —
## usado só na borda/fundo da caixa (ver _build_hud_chip()), nunca uma
## cor "grande"/dominante. Império dourado, Natureza verde, Mortos-Vivos
## roxo, conforme pedido; qualquer chave fora de FACTIONS cai no acento
## neutro (HUD_NEUTRAL_ACCENT) — usado pelas caixas de Nível/XP/PG, que
## não têm diferenciação por facção.
const HUD_NEUTRAL_ACCENT: Color = Color(0.75, 0.65, 0.45)
const HUD_FACTION_ACCENTS: Dictionary = {
	"Império": Color(0.85, 0.70, 0.35),
	"Natureza": Color(0.45, 0.75, 0.40),
	"Mortos-Vivos": Color(0.62, 0.48, 0.85),
}


func _style_hud_label(label: Label, font_size: int, color: Color) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HUD_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HUD_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HUD_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HUD_SHADOW_OFFSET)


## CityPanel_HUD_TYPOGRAPHY: caixa discreta e independente pra UM
## indicador — fundo quase transparente (alpha baixo) + borda fina no
## acento da cor recebida, nunca a faixa escurecida antiga. Retorna o
## Control raiz (pra ser adicionado ao HBoxContainer do chamador) e o
## Label interno (pra refresh() escrever o texto dinâmico depois).
## mouse_filter=IGNORE em toda a árvore, mesmo motivo já documentado no
## HUD inteiro: puramente informativo, nunca bloqueia hitbox por baixo.
func _build_hud_chip(accent: Color) -> Dictionary:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	_style_hud_label(label, HUD_INFO_FONT_SIZE, HUD_INFO_COLOR)
	chip.add_child(label)

	return {"container": chip, "label": label}


## CityPanel_LAYOUT: recalcula o retângulo de _city_safe_zone dentro de
## _city_area sempre que a janela muda de tamanho — trava a proporção
## efetiva usada pelo AspectRatioContainer(COVER) dentro de
## [SAFE_WINDOW_ASPECT_MIN, SAFE_WINDOW_ASPECT_MAX] (ver constantes,
## derivadas das margens reais de BUILDING_REGIONS). Ancorado no topo,
## centralizado horizontalmente — a barra residual (só aparece fora da
## faixa segura) sobra embaixo (protege a fileira de cima, mesmo
## raciocínio de ALIGNMENT_BEGIN) e simetricamente nas laterais.
func _update_city_safe_zone() -> void:
	if _city_safe_zone == null or _city_area == null:
		return
	var full: Vector2 = _city_area.size
	if full.x <= 0.0 or full.y <= 0.0:
		return
	var window_aspect: float = full.x / full.y
	var clamped_aspect: float = clampf(window_aspect, SAFE_WINDOW_ASPECT_MIN, SAFE_WINDOW_ASPECT_MAX)

	var w: float = full.x
	var h: float = full.y
	if clamped_aspect < window_aspect:
		w = h * clamped_aspect
	elif clamped_aspect > window_aspect:
		h = w / clamped_aspect

	_city_safe_zone.anchor_left = 0.0
	_city_safe_zone.anchor_right = 0.0
	_city_safe_zone.anchor_top = 0.0
	_city_safe_zone.anchor_bottom = 0.0
	_city_safe_zone.offset_left = (full.x - w) / 2.0
	_city_safe_zone.offset_right = _city_safe_zone.offset_left + w
	_city_safe_zone.offset_top = 0.0
	_city_safe_zone.offset_bottom = h
	_city_safe_zone.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_city_safe_zone.grow_vertical = Control.GROW_DIRECTION_BOTH


## CityPanel_NAVIGATION: clique na hitbox agora entra DIRETO na tela da
## construção — o painel contextual externo (_update_contextual_panel())
## deixou de fazer parte deste fluxo. A função/estado por trás dele
## (_selected_building_key, _contextual_panel, _update_contextual_panel(),
## _on_evolve_institutional_pressed(), _on_evolve_deposit_pressed())
## continuam existindo, intactos — removê-los não seria seguro: são
## chamados diretamente por validações legadas em
## scenes/bootstrap/bootstrap.gd (linhas ~3465-3533), fora do fluxo de
## clique real. Ver relatório da sessão.
func _on_hitbox_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_navigate_to_building(key)


## Entra diretamente na tela correspondente à construção, reutilizando
## a navegação já existente (_on_navigate_pressed(), mesmo mecanismo já
## usado pelos botões "Abrir" do painel antigo — nunca duplicado).
## Construções sem tela própria ainda (ver BUILDING_SCENES) não fazem
## nada aqui — nenhuma tela provisória/fictícia é criada.
func _navigate_to_building(key: String) -> void:
	if not BUILDING_SCENES.has(key):
		print("[CityPanel] '%s' ainda não possui uma tela de destino própria — clique sem efeito." % key)
		return
	_on_navigate_pressed(BUILDING_SCENES[key])


## CityPanel_BUILDING_HOVER: mostra o chip (texto + posição) centrado
## horizontalmente sobre a hitbox, logo acima dela — nunca coordenada
## fixa de resolução, sempre derivado do retângulo GLOBAL real da
## hitbox no momento do hover (acompanha qualquer redimensionamento/
## corte automaticamente, mesma lógica de responsividade já usada por
## _update_city_safe_zone()).
func _on_hitbox_mouse_entered(hitbox: Control, building_label: String, key: String = "") -> void:
	if _building_glows.has(key):
		_building_glows[key].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.HOVER)
	_hover_name_label.text = building_label
	# get_combined_minimum_size(): tamanho do chip pro texto NOVO,
	# calculado na hora — sem esperar um frame de layout (Container
	# calcula min size de forma síncrona ao trocar o texto do Label
	# filho).
	var chip_size: Vector2 = _hover_name_container.get_combined_minimum_size()
	_hover_name_container.size = chip_size

	var hitbox_rect: Rect2 = hitbox.get_global_rect()
	var x: float = hitbox_rect.position.x + hitbox_rect.size.x / 2.0 - chip_size.x / 2.0
	var y: float = hitbox_rect.position.y - chip_size.y - 6.0
	# Nunca sobrepõe o HUD superior (ex: hitbox da Capital começa perto
	# do topo da tela) — mesma altura fixa já usada por ele
	# (TOP_HUD_HEIGHT), não um número novo.
	y = max(y, TOP_HUD_HEIGHT + 4.0)

	_hover_name_container.global_position = Vector2(x, y)
	_hover_name_container.visible = true


func _on_hitbox_mouse_exited(key: String = "") -> void:
	if _building_glows.has(key):
		_building_glows[key].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.AVAILABLE)
	_hover_name_container.visible = false


## Continua sincronizando o tempo real mesmo sem o jogador clicar em
## nada — evita que a Cidade fique "parada no tempo" enquanto o
## jogador só observa a tela principal.
func _process(delta: float) -> void:
	if is_queued_for_deletion() or not KingdomState.is_initialized or not KingdomState.kingdom.starter_kit_used:
		return

	_process_accumulator += delta
	if _process_accumulator < PROCESS_SYNC_INTERVAL_SECONDS:
		return
	_process_accumulator = 0.0

	GameRuntime.sync(KingdomState.kingdom, GameClock.now_unix())


func refresh() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	GameRuntime.sync(kingdom, GameClock.now_unix())

	# CityPanel_HUD_TYPOGRAPHY: 3 caixas independentes, nunca mais um
	# único texto " | "-concatenado.
	_conta_labels["nivel"].text = "Nível de Conta %d" % kingdom.account_level()
	_conta_labels["xp"].text = "XP: %d" % kingdom.account_xp
	_conta_labels["pg"].text = "PG: %d" % kingdom.generation_points

	var capacity: int = Deposits.storage_capacity(kingdom.deposito_level)
	for resource: String in RAW_RESOURCES:
		_recursos_amount_labels[resource].text = "%s: %d/%d " % [RAW_RESOURCE_LABELS[resource], kingdom.get_raw_resource(resource), capacity]

	for faction: String in FACTIONS:
		_fragmento_labels[faction].text = "%s  %d" % [faction.to_upper(), kingdom.get_fragment(faction)]

	# Mantém o painel contextual coerente após um Evoluir (o Nível/
	# custo mudou) sem exigir um novo clique do jogador na construção.
	if _selected_building_key != "":
		_update_contextual_panel()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


## Reconstrói o conteúdo do painel contextual único pra a construção
## selecionada — mesma lógica de dados/handlers de sempre
## (InstitutionalConstructionResolver, CityResolver, EnergyNucleus,
## troca de cena), só que agora acionada por uma região clicável sobre
## a arte da Cidade em vez de um card fixo. Abrir e Evoluir continuam
## sendo botões SEPARADOS, ligados a handlers separados — nunca o
## mesmo controle.
func _update_contextual_panel() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	_clear_children(_contextual_content)
	_contextual_panel.visible = true

	# ART-002: ilustração real do prédio, quando existir uma
	# (CityBuildingArtCatalog) — reconstruída aqui, não em
	# _build_static_structure(), porque _clear_children(_contextual_content)
	# logo acima já apaga qualquer filho anterior a cada troca de
	# prédio, mesmo padrão já usado por name_label/info_label/buttons_row
	# abaixo. Some (visible=false) sem quebrar nada se o prédio
	# selecionado ainda não tiver arte integrada — nunca inventa uma
	# imagem, só continua mostrando o texto normalmente.
	var illustration := TextureRect.new()
	illustration.texture = preload("res://engine/presentation/city_building_art_catalog.gd").texture_for(_selected_building_key)
	illustration.visible = illustration.texture != null
	illustration.custom_minimum_size = Vector2(0, 130)
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_contextual_content.add_child(illustration)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	_contextual_content.add_child(name_label)

	var info_label := Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contextual_content.add_child(info_label)

	var buttons_row := HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.add_theme_constant_override("separation", 8)
	_contextual_content.add_child(buttons_row)

	match _selected_building_key:
		"capital":
			name_label.text = "Capital"
			info_label.text = _construction_level_text(InstitutionalConstructionConfig.Building.CAPITAL, kingdom.capital_level)
			_add_evolve_button(buttons_row, InstitutionalConstructionConfig.Building.CAPITAL)
		"academia":
			name_label.text = "Academia"
			info_label.text = _construction_level_text(InstitutionalConstructionConfig.Building.ACADEMIA, kingdom.academy_level)
			_add_open_button(buttons_row, "Abrir Academia", ACADEMIA_SCENE)
			_add_evolve_button(buttons_row, InstitutionalConstructionConfig.Building.ACADEMIA)
		"centro_de_comando":
			name_label.text = "Centro de Comando"
			info_label.text = _construction_level_text(InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO, kingdom.command_center_level)
			_add_open_button(buttons_row, "Abrir Centro de Comando", COMMAND_CENTER_SCENE)
			_add_evolve_button(buttons_row, InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO)
		"nucleo_de_energia":
			name_label.text = "Núcleo de Energia"
			var level: int = kingdom.energy_nucleus_level
			info_label.text = "%s\n%s" % [
				_construction_level_text(InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA, level),
				_nucleo_dados_text(level),
			]
			_add_evolve_button(buttons_row, InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA)
		"depositos":
			name_label.text = "Depósitos"
			var pg_cost: int = Deposits.upgrade_cost_pg(kingdom.deposito_level + 1)
			info_label.text = "Nível %d (próximo: %d PG, capacidade atual: %d)" % [
				kingdom.deposito_level, pg_cost, Deposits.storage_capacity(kingdom.deposito_level)
			]
			var evolve_button := Button.new()
			evolve_button.text = "Evoluir"
			evolve_button.pressed.connect(_on_evolve_deposit_pressed, CONNECT_DEFERRED)
			buttons_row.add_child(evolve_button)
		"biblioteca":
			name_label.text = "Biblioteca"
			info_label.text = ""
			_add_open_button(buttons_row, "Abrir", BIBLIOTECA_SCENE)
		"observatorio":
			name_label.text = "Observatório"
			info_label.text = ""
			_add_open_button(buttons_row, "Abrir", OBSERVATORIO_SCENE)

	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.pressed.connect(_on_close_contextual_panel_pressed, CONNECT_DEFERRED)
	_contextual_content.add_child(close_button)


func _construction_level_text(building: InstitutionalConstructionConfig.Building, current_level: int) -> String:
	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(building, current_level + 1)
	var cost_text: String = ", ".join(costs.keys().map(func(k: String) -> String: return "%s: %d" % [RAW_RESOURCE_LABELS.get(k, k), costs[k]]))
	return "Nível %d (próximo: %s)" % [current_level, cost_text]


func _add_open_button(buttons_row: HBoxContainer, text: String, scene_path: String) -> void:
	var open_button := Button.new()
	open_button.text = text
	open_button.pressed.connect(_on_navigate_pressed.bind(scene_path), CONNECT_DEFERRED)
	buttons_row.add_child(open_button)


func _add_evolve_button(buttons_row: HBoxContainer, building: InstitutionalConstructionConfig.Building) -> void:
	var evolve_button := Button.new()
	evolve_button.text = "Evoluir"
	evolve_button.pressed.connect(_on_evolve_institutional_pressed.bind(building), CONNECT_DEFERRED)
	buttons_row.add_child(evolve_button)


## Monta o texto de "Energia Base / Recuperação / Próximo bônus"
## (ENERGY_NUCLEUS.md, "Interface") a partir de EnergyNucleus — nunca
## reimplementa a fórmula aqui.
func _nucleo_dados_text(level: int) -> String:
	var energia_base: int = EnergyNucleus.energia_base(level)
	var recovery_seconds: int = EnergyNucleus.recovery_seconds(level)

	var proximo_bonus_text: String
	if level >= EnergyNucleus.MAX_LEVEL:
		proximo_bonus_text = "Nível Máximo atingido"
	else:
		var next_level: int = level + 1
		if next_level % 5 == 0:
			proximo_bonus_text = "+1 Energia Base"
		else:
			var next_recovery_seconds: int = EnergyNucleus.recovery_seconds(next_level)
			proximo_bonus_text = "Recuperação -%ds" % (recovery_seconds - next_recovery_seconds)

	return "Energia Base: %d | Recuperação: 1 ponto a cada %s | Próximo: %s" % [
		energia_base, EnergyNucleus.format_seconds(recovery_seconds), proximo_bonus_text
	]


func _on_close_contextual_panel_pressed() -> void:
	_selected_building_key = ""
	_contextual_panel.visible = false


func _on_evolve_institutional_pressed(building: InstitutionalConstructionConfig.Building) -> void:
	var result: Dictionary = InstitutionalConstructionResolver.evolve(KingdomState.kingdom, building)
	if not result["success"]:
		print("[CityPanel] Evoluir construção falhou: %s" % result["reason"])
		_evolve_status_label.text = "Não foi possível evoluir: %s" % result["reason"]
	else:
		_evolve_status_label.text = ""
	refresh()


func _on_evolve_deposit_pressed() -> void:
	var result: Dictionary = CityResolver.evolve_deposit(KingdomState.kingdom)
	if not result["success"]:
		print("[CityPanel] Evoluir Depósito falhou: %s" % result["reason"])
		_evolve_status_label.text = "Não foi possível evoluir: %s" % result["reason"]
	else:
		_evolve_status_label.text = ""
	refresh()


func _on_navigate_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene_path)
