extends Control
## CapitalPanel (CAPITAL.md)
##
## Tela interna da Capital — primeira versão, exclusivamente estrutural/
## visual (esta etapa). Reutiliza o PADRÃO ARQUITETURAL já validado em
## CityPanel (scenes/city/city_panel.gd): imagem de fundo real dentro
## de um AspectRatioContainer(STRETCH_COVER) + safe zone que trava a
## proporção efetiva de corte pra nunca alcançar uma região clicável +
## hitboxes fracionárias filhas do TextureRect + chip de hover com a
## fonte Cinzel — mas SEM compartilhar código com city_panel.gd (a
## tarefa proíbe tocar na tela/mapa/hitboxes/HUD da Cidade; reaproveitar
## a implementação por cópia local do mesmo padrão evita esse risco).
##
## Os 4 pop-ups (Visão do Reino/Evoluir Capital/História/Estatísticas)
## abrem como uma camada modal sobre a própria Capital (_popup_layer,
## ver _open_capital_popup()) — nunca troca de cena. Escopo desta etapa
## (deliberado): só composição visual/navegacional; nenhum dado
## dinâmico, botão com lógica de jogo ou sistema novo dentro dos
## pop-ups ainda.

const CAPITAL_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/capital_v2.png")
const CAPITAL_IMAGE_SIZE: Vector2 = Vector2(1672.0, 941.0)
const CAPITAL_IMAGE_ASPECT_RATIO: float = 1672.0 / 941.0

## Regiões clicáveis (frações 0.0-1.0 da imagem Capital-V2.png),
## convertidas diretamente das coordenadas de referência em pixels
## (imagem original 1672x941) fornecidas pelo pedido — pontos de
## partida, não exigência de precisão pixel a pixel (ver docstring do
## pedido, "prioridade é a hitbox corresponder visualmente ao objeto").
## AJUSTE: as coordenadas originais (visao_reino y 390-650 x evoluir_capital
## y 180-430, x 700-1050 em ambas) se sobrepunham numa faixa real de
## 350x40px (confirmado via Rect2.intersects() nos testes) — limite
## comum ajustado pra y=410 (a escadaria/portal termina em 410, a mesa
## do mapa começa em 410), eliminando a sobreposição sem mudar
## visualmente qual objeto cada hitbox cobre.
const REGIONS: Dictionary = {
	"visao_reino": {
		"rect": Rect2(540.0 / 1672.0, 410.0 / 941.0, (1050.0 - 540.0) / 1672.0, (650.0 - 410.0) / 941.0),
		"label": "Visão do Reino",
	},
	"evoluir_capital": {
		"rect": Rect2(700.0 / 1672.0, 180.0 / 941.0, (1050.0 - 700.0) / 1672.0, (410.0 - 180.0) / 941.0),
		"label": "Evoluir Capital",
	},
	"historia_reino": {
		"rect": Rect2(40.0 / 1672.0, 700.0 / 941.0, (430.0 - 40.0) / 1672.0, (900.0 - 700.0) / 941.0),
		"label": "História do Reino",
	},
	"estatisticas_reino": {
		"rect": Rect2(1230.0 / 1672.0, 650.0 / 941.0, (1600.0 - 1230.0) / 1672.0, (900.0 - 650.0) / 941.0),
		"label": "Estatísticas do Reino",
	},
}

## Faixa de proporção de JANELA dentro da qual STRETCH_COVER corta a
## imagem sem alcançar nenhuma região de REGIONS — mesmo princípio de
## CityPanel.SAFE_WINDOW_ASPECT_MIN/MAX, recalculado aqui a partir das
## margens reais destas 4 regiões até a borda da imagem:
##   vertical: topo 19,1% (evoluir_capital, y=180/941) / baixo 4,4%
##     (história/estatísticas, y=900/941) -> margem de baixo é a mais
##     apertada, então o corte vertical usa ALIGNMENT_END (protege
##     embaixo, corta só em cima, consumindo a folga de 19,1%).
##   horizontal: esquerda 2,4% (história, x=40/1672) / direita 4,3%
##     (estatísticas, x=1600/1672) -> margem da esquerda é a mais
##     apertada, então o corte horizontal usa ALIGNMENT_BEGIN (protege
##     a esquerda, corta só à direita).
const SAFE_WINDOW_ASPECT_MIN: float = 1.65
const SAFE_WINDOW_ASPECT_MAX: float = 2.15

## Mesmo arquivo de fonte já incorporado ao projeto por CityPanel
## (Game/assets/fonts/Cinzel-SemiBold.ttf) — referenciado aqui de forma
## independente (nenhum código da Cidade é importado/alterado), único
## ponto a trocar dentro deste arquivo se a fonte mudar no futuro.
const HOVER_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HOVER_FONT_SIZE: int = 15
const HOVER_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HOVER_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HOVER_OUTLINE_SIZE: int = 5
const HOVER_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const HOVER_SHADOW_OFFSET: int = 2
const HOVER_ACCENT: Color = Color(0.75, 0.65, 0.45)

## Assets dos 4 pop-ups — cópias byte-idênticas de
## Assets/MVP/Construções/{CAPITAL-Kindon overview-V2, Capital Upgrade,
## CAPITAL-kingdom History Popup, CAPITAL-Kingdom Statistics Popup}.png
## (mesmo procedimento de CAPITAL_TEXTURE acima). A própria arte É o
## layout visual do pop-up — nenhum painel é desenhado por cima, só a
## imagem centralizada + o botão de fechar (ver _open_capital_popup()).
const POPUP_ASSETS: Dictionary = {
	"visao_reino": {
		"texture": preload("res://assets/art/city_buildings/capital_popup_visao_reino.png"),
		"aspect_ratio": 1254.0 / 1254.0,
	},
	"evoluir_capital": {
		"texture": preload("res://assets/art/city_buildings/capital_popup_evoluir_capital.png"),
		"aspect_ratio": 1536.0 / 1024.0,
	},
	"historia_reino": {
		"texture": preload("res://assets/art/city_buildings/capital_popup_historia_reino.png"),
		"aspect_ratio": 1536.0 / 1024.0,
	},
	"estatisticas_reino": {
		"texture": preload("res://assets/art/city_buildings/capital_popup_estatisticas_reino.png"),
		"aspect_ratio": 1536.0 / 1024.0,
	},
}

## Fração do menor lado da tela ocupada pelo pop-up — mesma ideia de
## responsividade de CAPITAL_IMAGE_ASPECT_RATIO acima: só limita o
## tamanho máximo, o AspectRatioContainer(STRETCH_FIT) garante que a
## arte nunca é esticada/deformada.
const POPUP_MAX_SIZE_FRACTION: float = 0.86

## Mesmos nomes/valores de RAW_RESOURCES/RAW_RESOURCE_LABELS de
## CityPanel (scenes/city/city_panel.gd) — duplicados aqui de propósito
## (nenhum código da Cidade é importado, ver docstring do topo do
## arquivo), única fonte real dos valores continua sendo Kingdom
## (kingdom.get_raw_resource()) via InstitutionalConstructionResolver.
const RAW_RESOURCES: Array[String] = ["ferro_negro", "cristais_arcanos", "essencia_vital"]
const RAW_RESOURCE_LABELS: Dictionary = {
	"ferro_negro": "Ferro Negro", "cristais_arcanos": "Cristais Arcanos", "essencia_vital": "Essência Vital",
}

## Áreas em branco já desenhadas em capital_popup_evoluir_capital.png
## (Assets/MVP/Construções/Capital Upgrade.png), calibradas por
## detecção de componentes conectados (mesmo método já usado pra
## CHOICE_BUTTON_REGIONS em starter_kit_panel.gd) sobre a imagem
## original 1536x1024 — nenhuma caixa nova é desenhada, o texto ocupa
## as molduras que a própria arte já reserva pra conteúdo (pedido §1:
## "área visualmente apropriada do próprio popup, sem criar uma caixa
## externa"). Barra única no topo -> título; 3 pares de caixas
## esquerda/direita -> um par por Recurso de Construção (RAW_RESOURCES,
## na mesma ordem); 2 das 3 caixas inferiores -> Nível atual/próximo;
## barra única embaixo -> botão Evoluir.
const EVOLUIR_TITLE_RECT: Rect2 = Rect2(0.3503, 0.1133, 0.2988, 0.0576)
const EVOLUIR_RESOURCE_ROWS: Array[Dictionary] = [
	{"resource": "ferro_negro", "left": Rect2(0.1055, 0.2549, 0.1823, 0.0762), "right": Rect2(0.7116, 0.2549, 0.1823, 0.0762)},
	{"resource": "cristais_arcanos", "left": Rect2(0.1068, 0.3740, 0.1803, 0.0801), "right": Rect2(0.7109, 0.3740, 0.1823, 0.0811)},
	{"resource": "essencia_vital", "left": Rect2(0.1061, 0.5020, 0.1817, 0.0811), "right": Rect2(0.7116, 0.5020, 0.1810, 0.0811)},
]
const EVOLUIR_LEVEL_CURRENT_RECT: Rect2 = Rect2(0.1419, 0.6602, 0.1979, 0.1025)
const EVOLUIR_LEVEL_NEXT_RECT: Rect2 = Rect2(0.3893, 0.6592, 0.2207, 0.1045)
const EVOLUIR_BUTTON_RECT: Rect2 = Rect2(0.3014, 0.8223, 0.3965, 0.0830)

## Mesmo método de calibração de EVOLUIR_* acima, aplicado sobre
## capital_popup_visao_reino.png (Assets/MVP/Construções/
## CAPITAL-Kindon overview-V2.png, 1254x1254 — mesmo molde visual de
## Capital Upgrade.png: 1 barra no topo, 3 pares de caixas
## esquerda/direita, um brasão central decorativo, 3 caixas inferiores,
## 1 barra inferior). Título -> barra do topo; até 3 Territórios reais
## (VISAO_TERRITORY_ROWS, um par de caixas por Território — nunca
## assume 3 só porque existem 3 Facções, ver _refresh_visao_reino_popup())
## nos 3 pares laterais; os 3 contadores agregados nas caixas inferiores
## (VISAO_COUNTER_RECTS); barra inferior deliberadamente sem texto
## (pedido: "não colocar texto artificial apenas para preencher").
const VISAO_TITLE_RECT: Rect2 = Rect2(0.3214, 0.1196, 0.3580, 0.0526)
const VISAO_TERRITORY_ROWS: Array[Dictionary] = [
	{"left": Rect2(0.1148, 0.2273, 0.1818, 0.0694), "right": Rect2(0.7033, 0.2273, 0.1818, 0.0694)},
	{"left": Rect2(0.1148, 0.3301, 0.1818, 0.0694), "right": Rect2(0.7033, 0.3301, 0.1818, 0.0694)},
	{"left": Rect2(0.1156, 0.4322, 0.1810, 0.0686), "right": Rect2(0.7033, 0.4322, 0.1818, 0.0686)},
]
const VISAO_COUNTER_RECTS: Array[Rect2] = [
	Rect2(0.1037, 0.5710, 0.2065, 0.1691),
	Rect2(0.3724, 0.5710, 0.2528, 0.1691),
	Rect2(0.6874, 0.5710, 0.2089, 0.1691),
]

## Margem interna (fração da imagem), aplicada a toda caixa lateral/
## inferior antes de nela ancorar uma pilha de linhas (_make_popup_stack())
## — nenhuma informação fica "grudada" na moldura, sem alterar as
## próprias molduras já calibradas acima.
const VISAO_BOX_INSET_X: float = 0.010
const VISAO_BOX_INSET_Y: float = 0.008

## Hierarquia tipográfica do pop-up "Visão do Reino" — refinamento
## puramente visual (mesma Cinzel, HOVER_TEXT_COLOR/contorno/sombra de
## sempre): título maior; nome do Território em destaque próprio;
## status em destaque primário (tamanho inalterado desde a rodada
## anterior); Fase/Região em rótulo secundário menor; nas caixas
## inferiores, o rótulo do contador tem a MESMA presença visual do
## nome do Território (pedido: "presença visual semelhante aos textos
## das caixas territoriais") e o valor numérico mantém exatamente o
## tamanho já aprovado (pedido: "NÃO aumentar nem diminuir os
## números" — nunca tocado nesta rodada).
const VISAO_TITLE_FONT_SIZE: int = HOVER_FONT_SIZE + 6
const VISAO_TERRITORY_NAME_FONT_SIZE: int = HOVER_FONT_SIZE + 1
const VISAO_STATUS_FONT_SIZE: int = HOVER_FONT_SIZE - 1
const VISAO_SECONDARY_FONT_SIZE: int = HOVER_FONT_SIZE - 5
const VISAO_COUNTER_LABEL_FONT_SIZE: int = VISAO_TERRITORY_NAME_FONT_SIZE
const VISAO_COUNTER_VALUE_FONT_SIZE: int = HOVER_FONT_SIZE + 5
const VISAO_STACK_LINE_SEPARATION: int = 1

## Este pop-up especificamente precisa de um pouco mais de espaço do
## que POPUP_MAX_SIZE_FRACTION (compartilhado com os outros 3 pop-ups,
## nunca alterado) pra caber Nome do Território + Fase/Região com a
## hierarquia tipográfica acima sem espremer a fonte — prioridade
## seguida: 1) controlar quebras de linha, 2) tamanhos de fonte por
## categoria, 3) só então (aqui) uma folga discreta a mais de tela pra
## este pop-up específico. Não distorce a arte (STRETCH_FIT preserva a
## proporção 1:1 de qualquer forma) nem afeta os outros 3 pop-ups (ver
## _update_popup_margin(), que só usa esta constante quando
## _current_popup_key == "visao_reino").
const VISAO_POPUP_MAX_SIZE_FRACTION: float = 0.94

## Mesmo método de calibração de EVOLUIR_*/VISAO_* acima, aplicado
## sobre capital_popup_historia_reino.png (Assets/MVP/Construções/
## CAPITAL-kingdom History Popup.png, 1536x1024 — mesmo molde visual
## dos outros 3: barra no topo, área central decorativa (biblioteca
## ilustrada), 3 caixas maiores embaixo, barra inferior — mas com 4
## pares de caixas laterais em vez de 3). Título -> barra do topo; até
## 8 eventos reais de Kingdom.commissioning_history (um por caixa
## pequena, ver _refresh_historia_reino_popup()) — nenhum dado
## inventado se houver menos de 8; as 3 caixas inferiores e a barra
## inferior ficam deliberadamente vazias nesta versão (pedido: "prefiro
## espaços vazios a conteúdo artificial").
const HISTORIA_TITLE_RECT: Rect2 = Rect2(0.3451, 0.1123, 0.3105, 0.0605)

## Ordem de leitura escolhida pra um feed cronológico de 2 colunas
## (o pedido não define isso — decisão de implementação registrada no
## relatório final): coluna esquerda inteira de cima pra baixo (slots
## 0-3, os 4 eventos mais recentes), depois a coluna direita de cima
## pra baixo (slots 4-7). O mais recente sempre ocupa o slot 0.
const HISTORIA_EVENT_SLOTS: Array[Rect2] = [
	Rect2(0.1061, 0.2002, 0.1289, 0.0654),
	Rect2(0.1061, 0.2949, 0.1289, 0.0674),
	Rect2(0.1061, 0.3926, 0.1289, 0.0645),
	Rect2(0.1061, 0.4883, 0.1289, 0.0674),
	Rect2(0.7656, 0.2002, 0.1283, 0.0654),
	Rect2(0.7656, 0.2949, 0.1283, 0.0674),
	Rect2(0.7656, 0.3926, 0.1276, 0.0645),
	Rect2(0.7656, 0.4883, 0.1283, 0.0674),
]

## Mesma hierarquia de duas camadas já usada em Visão do Reino (nome
## em destaque, dado secundário menor) — nome do Comandante em
## destaque; origem + data em rótulo secundário.
const HISTORIA_TITLE_FONT_SIZE: int = HOVER_FONT_SIZE + 6
const HISTORIA_NAME_FONT_SIZE: int = HOVER_FONT_SIZE - 1
const HISTORIA_META_FONT_SIZE: int = HOVER_FONT_SIZE - 5

## Mesmo método de calibração de EVOLUIR_*/VISAO_*/HISTORIA_* acima,
## aplicado sobre capital_popup_estatisticas_reino.png (Assets/MVP/
## Construções/CAPITAL-Kingdom Statistics Popup.png, 1536x1024 — mesmo
## molde visual de "Evoluir Capital"/"Visão do Reino": barra no topo, 3
## pares de caixas laterais, área central decorativa (observatório
## ilustrado), 3 caixas maiores embaixo, barra inferior). Título -> barra
## do topo; as 6 caixas laterais (ESTATISTICAS_SIDE_SLOTS) e só a
## PRIMEIRA caixa inferior (ESTATISTICAS_BOTTOM_RECT) recebem
## rótulo+valor — as outras 2 caixas inferiores, a área central e a
## barra inferior ficam deliberadamente sem nenhum Control (pedido §4/
## §5/§6, "deixar completamente vazia... não criar Label sobre ela").
const ESTATISTICAS_TITLE_RECT: Rect2 = Rect2(0.3470, 0.1182, 0.3053, 0.0537)
const ESTATISTICAS_SIDE_SLOTS: Array[Rect2] = [
	Rect2(0.1035, 0.2012, 0.1419, 0.0498),
	Rect2(0.1035, 0.2773, 0.1413, 0.0498),
	Rect2(0.1035, 0.3555, 0.1419, 0.0498),
	Rect2(0.7552, 0.2012, 0.1419, 0.0498),
	Rect2(0.7552, 0.2773, 0.1413, 0.0498),
	Rect2(0.7552, 0.3545, 0.1413, 0.0508),
]
const ESTATISTICAS_BOTTOM_RECT: Rect2 = Rect2(0.0944, 0.6387, 0.2305, 0.1055)

## Mesma hierarquia (rótulo menor, valor com maior presença visual) já
## aprovada em Visão do Reino — tamanhos absolutos ajustados à altura
## bem menor destas 6 caixas laterais (~0.05 de fração da imagem,
## contra ~0.17 dos contadores de Visão do Reino) pra caber com folga
## até 3 linhas de rótulo (pedido §7, exemplo "NÍVEL DO/CENTRO DE/
## COMANDO") mais a linha do valor, sem espremer a fonte.
const ESTATISTICAS_TITLE_FONT_SIZE: int = HOVER_FONT_SIZE + 6
const ESTATISTICAS_LABEL_FONT_SIZE: int = HOVER_FONT_SIZE - 5
const ESTATISTICAS_VALUE_FONT_SIZE: int = HOVER_FONT_SIZE + 1

var _capital_area: Control
var _capital_safe_zone: Control
var _capital_texture_rect: TextureRect
var _hover_name_container: Control
var _hover_name_label: Label

## FASE 15: key (mesma chave de REGIONS) -> HotspotGlow — CapitalPanel
## nunca recebeu o sinal luminoso da Fase 12 (auditoria desta tarefa:
## _build_hitbox() abaixo nunca chamou HotspotGlow.attach_to_region(),
## ao contrário de city_panel.gd/biblioteca_panel.gd/etc., que já usam o
## mesmo componente desde a Fase 12/13). Mesmo padrão de
## city_panel.gd::_building_glows (REGIONS aqui é o equivalente local de
## BUILDING_REGIONS) — reconstruído a cada _build_static_structure(),
## nunca persistido entre reconstruções.
var _building_glows: Dictionary = {}

var _popup_layer: Control
var _popup_aspect: AspectRatioContainer
var _popup_texture_rect: TextureRect
var _popup_close_container: Control

var _evoluir_capital_overlay: Control
var _evoluir_level_current_label: Label
var _evoluir_level_next_label: Label
var _evoluir_resource_labels: Dictionary = {}
var _evoluir_missing_labels: Dictionary = {}
var _evoluir_button: Button

var _visao_reino_overlay: Control

## Um Dictionary por linha territorial (VISAO_TERRITORY_ROWS), com as
## Labels dinâmicas daquela linha: "name_line1"/"name_line2" (nome do
## Território, quebra controlada — ver _split_territory_name()),
## "fase_line"/"regiao_line" (só visíveis quando há expedição real) e
## "status_line1"/"status_line2" (status, quebra controlada — ver
## _split_status_lines()).
var _visao_territory_stacks: Array[Dictionary] = []

## Só o valor numérico de cada contador (VISAO_COUNTER_RECTS) — o
## rótulo de cada contador é texto fixo, escrito uma única vez em
## _build_visao_reino_overlay().
var _visao_counter_value_labels: Array[Label] = []

## Chave do pop-up atualmente aberto ("" quando nenhum) — usada só por
## _update_popup_margin() pra decidir entre POPUP_MAX_SIZE_FRACTION
## (padrão, os outros 3 pop-ups) e VISAO_POPUP_MAX_SIZE_FRACTION
## (somente "visao_reino").
var _current_popup_key: String = ""

var _historia_reino_overlay: Control

## Um Dictionary por slot (HISTORIA_EVENT_SLOTS, 8 entradas), com as 3
## Labels dinâmicas daquele slot: "name_line" (nome do Comandante,
## autowrap controlado — ver _build_historia_reino_overlay()),
## "origin_line" e "date_line".
var _historia_event_stacks: Array[Dictionary] = []

var _estatisticas_reino_overlay: Control

## Só os 7 Labels de VALOR (6 caixas laterais + a 1ª caixa inferior,
## nesta ordem — Academia/CdC/Núcleo/Depósitos/Comandantes/Exércitos/
## Squads) — os rótulos são texto fixo, escritos uma única vez em
## _build_estatisticas_reino_overlay().
var _estatisticas_value_labels: Array[Label] = []


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	# Mesma chamada idempotente já usada por CityPanel/PvEPanel (ver
	# docstring de WorldBootstrap.ensure_world_loaded()) — garante que
	# WorldDatabase.get_current_season() tem Território/Trilha reais
	# disponíveis pro pop-up "Visão do Reino", mesmo se a Capital for
	# aberta antes da Cidade ter chamado isso (ex.: testes isolados).
	WorldBootstrap.ensure_world_loaded()

	_build_static_structure()
	print("[CapitalPanel] Pronto.")


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_capital_area = Control.new()
	_capital_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capital_area.clip_contents = true
	add_child(_capital_area)

	_capital_safe_zone = Control.new()
	_capital_safe_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	_capital_area.add_child(_capital_safe_zone)
	_capital_area.resized.connect(_update_capital_safe_zone)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = CAPITAL_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_BEGIN
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_END
	_capital_safe_zone.add_child(aspect)

	_capital_texture_rect = TextureRect.new()
	_capital_texture_rect.texture = CAPITAL_TEXTURE
	_capital_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_capital_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_capital_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(_capital_texture_rect)

	for key: String in REGIONS:
		_capital_texture_rect.add_child(_build_hitbox(key))

	_update_capital_safe_zone.call_deferred()

	# --- Chip de hover — MESMO estilo visual dos chips de identificação
	# já usados na Cidade (fundo quase transparente + borda fina no
	# acento + Cinzel + contorno/sombra), implementado localmente aqui
	# (ver docstring do topo do arquivo). ---
	var hover_chip: Dictionary = _build_hover_chip()
	_hover_name_container = hover_chip["container"]
	_hover_name_label = hover_chip["label"]
	_hover_name_container.visible = false
	_hover_name_container.anchor_left = 0.0
	_hover_name_container.anchor_top = 0.0
	_hover_name_container.anchor_right = 0.0
	_hover_name_container.anchor_bottom = 0.0
	_hover_name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hover_name_container)

	# --- Botão "Voltar para a Cidade" — MESMO estilo visual dos rótulos
	# de hover das regiões (ex.: "História do Reino"), reutilizando
	# diretamente _build_hover_chip() em vez de aproximar manualmente o
	# visual. Diferença: fica sempre visível (não é hover) e captura
	# clique (mouse_filter STOP no container). ---
	var back_chip: Dictionary = _build_hover_chip()
	var back_button_container: Control = back_chip["container"]
	var back_button_label: Label = back_chip["label"]
	back_button_label.text = "Voltar para a Cidade"
	back_button_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_button_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_button_container.position = Vector2(12, 12)
	back_button_container.size = back_button_container.get_combined_minimum_size()
	back_button_container.gui_input.connect(_on_back_button_gui_input)
	add_child(back_button_container)

	_build_popup_layer()


## Camada modal única, reaproveitada pelos 4 pop-ups (visao_reino,
## evoluir_capital, historia_reino, estatisticas_reino) — evita 4
## sistemas independentes (ver pedido §7). Fica por último na árvore
## (acima de tudo), começa invisível/sem bloquear mouse, e só passa a
## bloquear input do fundo (STOP) enquanto um pop-up está aberto.
func _build_popup_layer() -> void:
	_popup_layer = Control.new()
	_popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_layer.visible = false
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_popup_layer)

	var scrim := ColorRect.new()
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_layer.add_child(scrim)

	_popup_aspect = AspectRatioContainer.new()
	_popup_aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_popup_aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	_popup_aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	_popup_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_layer.add_child(_popup_aspect)

	# Margem ao redor do AspectRatioContainer pra limitar seu tamanho
	# máximo a POPUP_MAX_SIZE_FRACTION do menor lado da tela — recalculado
	# a cada resize (ver _update_popup_margin()).
	_popup_layer.resized.connect(_update_popup_margin)

	_popup_texture_rect = TextureRect.new()
	_popup_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_popup_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_popup_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_aspect.add_child(_popup_texture_rect)

	# --- Botão de fechar — nenhum dos 4 assets tem uma área de
	# fechamento própria (ver inspeção visual no pedido), então uso o
	# MESMO chip (_build_hover_chip()) do resto da tela, em vez de
	# inventar um estilo novo. Fica ancorado no canto superior direito
	# do próprio TextureRect do pop-up (acompanha o tamanho responsivo
	# da arte, nunca a tela inteira). ---
	var close_chip: Dictionary = _build_hover_chip()
	_popup_close_container = close_chip["container"]
	var close_label: Label = close_chip["label"]
	close_label.text = "Fechar"
	_popup_close_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_close_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_popup_close_container.anchor_left = 1.0
	_popup_close_container.anchor_right = 1.0
	_popup_close_container.anchor_top = 0.0
	_popup_close_container.anchor_bottom = 0.0
	_popup_close_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_popup_close_container.offset_top = 10.0
	_popup_close_container.offset_right = -10.0
	_popup_close_container.gui_input.connect(_on_popup_close_gui_input)

	_build_evoluir_capital_overlay()
	_build_visao_reino_overlay()
	_build_historia_reino_overlay()
	_build_estatisticas_reino_overlay()

	# Botão de fechar por cima do conteúdo dinâmico dos pop-ups (ordem
	# de adição = ordem de desenho/entrega de input em Godot).
	_popup_texture_rect.add_child(_popup_close_container)

	_update_popup_margin()


## Conteúdo dinâmico do pop-up "Evoluir Capital" — único dos 4 com
## dados reais (pedido atual). Fica escondido por padrão; só aparece
## quando POPUP_ASSETS[key] == "evoluir_capital" (ver
## _open_capital_popup()). Nenhuma caixa/painel novo é desenhado: os
## Labels ficam diretamente sobre as molduras já existentes na arte
## (EVOLUIR_*_RECT), sem StyleBox de fundo.
func _build_evoluir_capital_overlay() -> void:
	_evoluir_capital_overlay = Control.new()
	_evoluir_capital_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_evoluir_capital_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_evoluir_capital_overlay.visible = false
	_popup_texture_rect.add_child(_evoluir_capital_overlay)

	var title_label := _make_popup_label(EVOLUIR_TITLE_RECT, HOVER_FONT_SIZE + 5)
	title_label.text = "CAPITAL"
	_evoluir_capital_overlay.add_child(title_label)

	_evoluir_level_current_label = _make_popup_label(EVOLUIR_LEVEL_CURRENT_RECT, HOVER_FONT_SIZE)
	_evoluir_capital_overlay.add_child(_evoluir_level_current_label)

	_evoluir_level_next_label = _make_popup_label(EVOLUIR_LEVEL_NEXT_RECT, HOVER_FONT_SIZE)
	_evoluir_capital_overlay.add_child(_evoluir_level_next_label)

	for row: Dictionary in EVOLUIR_RESOURCE_ROWS:
		var resource: String = row["resource"]

		var name_label: Label = _make_popup_label(row["left"], HOVER_FONT_SIZE)
		_evoluir_capital_overlay.add_child(name_label)
		_evoluir_resource_labels[resource] = name_label

		var missing_label: Label = _make_popup_label(row["right"], HOVER_FONT_SIZE)
		_evoluir_capital_overlay.add_child(missing_label)
		_evoluir_missing_labels[resource] = missing_label

	# Botão "Evoluir" — MESMO padrão visual já usado por CityPanel
	# (_add_evolve_button(): Button.new() puro, tema global do projeto,
	# habilitado/desabilitado via ".disabled") — nenhum estilo novo.
	_evoluir_button = Button.new()
	_evoluir_button.text = "Evoluir"
	_evoluir_button.anchor_left = EVOLUIR_BUTTON_RECT.position.x
	_evoluir_button.anchor_top = EVOLUIR_BUTTON_RECT.position.y
	_evoluir_button.anchor_right = EVOLUIR_BUTTON_RECT.position.x + EVOLUIR_BUTTON_RECT.size.x
	_evoluir_button.anchor_bottom = EVOLUIR_BUTTON_RECT.position.y + EVOLUIR_BUTTON_RECT.size.y
	_evoluir_button.offset_left = 0.0
	_evoluir_button.offset_top = 0.0
	_evoluir_button.offset_right = 0.0
	_evoluir_button.offset_bottom = 0.0
	_evoluir_button.pressed.connect(_on_evolve_capital_pressed, CONNECT_DEFERRED)
	_evoluir_capital_overlay.add_child(_evoluir_button)


## Label sem fundo (nenhuma caixa nova, ver docstring de
## _build_evoluir_capital_overlay()), mesma tipografia/legibilidade dos
## outros textos desta tela (HOVER_FONT/HOVER_TEXT_COLOR/contorno/
## sombra), posicionado por fração sobre uma das molduras já existentes
## na arte do pop-up.
func _make_popup_label(rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.anchor_left = rect.position.x
	label.anchor_top = rect.position.y
	label.anchor_right = rect.position.x + rect.size.x
	label.anchor_bottom = rect.position.y + rect.size.y
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HOVER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", HOVER_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HOVER_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HOVER_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HOVER_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HOVER_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HOVER_SHADOW_OFFSET)
	return label


## Fonte de verdade: Kingdom.capital_level (nível atual) +
## InstitutionalConstructionResolver.cost_breakdown() (custo/recursos
## necessários pro próximo nível, já dividido 33/33/33 entre os 3
## Recursos de Construção — ver docstring do próprio resolver) +
## Kingdom.get_building_reserved()/get_raw_resource() (Reserva
## Antecipada de Evolução + saldo do Depósito). Nenhum valor é
## inventado aqui; chamada de novo depois de cada Evoluir bem-sucedido
## (pedido §6, "atualização dinâmica sem sair/entrar de novo").
##
## CORRIGIDO (bug reportado: "Já Possui: 6" na Supply Chain, mas a
## Capital mostrava "0 / 4360"): "have" lia só kingdom.get_raw_resource()
## — o saldo COMPARTILHADO do Depósito — nunca
## kingdom.get_building_reserved(), que é onde a Supply Chain
## (SupplyChainResolver.transfer_resource()) efetivamente credita o
## que já foi transferido pra esta construção especificamente. Fonte
## única de verdade: Kingdom.building_reserved_resources (mesmo campo,
## mesmos getters get_building_reserved()/add_building_reserved()/
## spend_building_reserved() já usados pela Supply Chain e por
## InstitutionalConstructionResolver.evolve() — nenhum estado novo,
## nenhum cache paralelo). O valor exibido na fração "X / Y" agora é
## exatamente "reserved" (idêntico ao "Já Possui" da Supply Chain,
## mesma fonte); a checagem de "Completo"/botão habilitado usa
## reserved + saldo do Depósito (o mesmo total que
## InstitutionalConstructionResolver.evolve() verifica internamente),
## preservando o comportamento de sempre pra quem nunca usou a Supply
## Chain (reserved=0 → total = só o Depósito, igual a antes desta
## correção).
func _refresh_evoluir_capital_popup() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = kingdom.capital_level
	var next_level: int = current_level + 1

	_evoluir_level_current_label.text = "Nível atual: %d" % current_level
	_evoluir_level_next_label.text = "Próximo nível: %d" % next_level

	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(
		InstitutionalConstructionConfig.Building.CAPITAL, next_level
	)
	var capital_key: String = InstitutionalConstructionResolver.building_key(
		InstitutionalConstructionConfig.Building.CAPITAL
	)

	var all_requirements_met := true
	for resource: String in RAW_RESOURCES:
		var needed: int = costs.get(resource, 0)
		var reserved: int = kingdom.get_building_reserved(capital_key, resource)
		var deposit_available: int = kingdom.get_raw_resource(resource)
		var total_available: int = reserved + deposit_available

		_evoluir_resource_labels[resource].text = "%s\n%d / %d" % [
			RAW_RESOURCE_LABELS[resource].to_upper(), reserved, needed
		]

		var missing_label: Label = _evoluir_missing_labels[resource]
		if total_available >= needed:
			missing_label.text = "Completo"
			missing_label.add_theme_color_override("font_color", HOVER_ACCENT)
		else:
			all_requirements_met = false
			missing_label.text = "Faltam %d" % (needed - total_available)
			missing_label.add_theme_color_override("font_color", HOVER_TEXT_COLOR)

	_evoluir_button.disabled = not all_requirements_met


## Reutiliza a MESMA lógica de evolução institucional de CityPanel
## (InstitutionalConstructionResolver.evolve() — nunca uma segunda
## implementação, ver pedido §5/§7). A Capital não tem teto de nível
## (Capital.can_building_evolve() só se aplica às construções
## dependentes dela), então o único motivo de falha aqui é
## "insufficient_resources" — o botão já fica desabilitado antes disso
## acontecer (ver _refresh_evoluir_capital_popup()), mas o resolver é
## chamado do mesmo jeito (nunca assume sucesso sem checar o retorno).
func _on_evolve_capital_pressed() -> void:
	var result: Dictionary = InstitutionalConstructionResolver.evolve(
		KingdomState.kingdom, InstitutionalConstructionConfig.Building.CAPITAL
	)
	if not result["success"]:
		print("[CapitalPanel] Evoluir Capital falhou: %s" % result["reason"])
	_refresh_evoluir_capital_popup()


## Conteúdo dinâmico do pop-up "Visão do Reino" — segue exatamente o
## levantamento aprovado na tarefa anterior: até 3 Territórios reais
## (nunca assumidos, sempre lidos de WorldDatabase.get_current_season().
## territories — pode haver menos de 3, ver _refresh_visao_reino_popup()),
## Fase/Região/Status de cada expedição real, e 3 contadores agregados.
## Escondido por padrão; só aparece quando POPUP_ASSETS[key] ==
## "visao_reino" (ver _open_capital_popup()). Mesma técnica de
## _build_evoluir_capital_overlay(): Labels sem fundo, direto sobre as
## molduras já existentes na arte.
func _build_visao_reino_overlay() -> void:
	_visao_reino_overlay = Control.new()
	_visao_reino_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_visao_reino_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visao_reino_overlay.visible = false
	_popup_texture_rect.add_child(_visao_reino_overlay)

	var title_label := _make_popup_label(VISAO_TITLE_RECT, VISAO_TITLE_FONT_SIZE)
	title_label.text = "VISÃO DO REINO"
	_visao_reino_overlay.add_child(title_label)

	_visao_territory_stacks.clear()
	for row: Dictionary in VISAO_TERRITORY_ROWS:
		var left_stack: VBoxContainer = _make_popup_stack(row["left"])
		_visao_reino_overlay.add_child(left_stack)
		var name_line1: Label = _make_popup_text_line("", VISAO_TERRITORY_NAME_FONT_SIZE)
		var name_line2: Label = _make_popup_text_line("", VISAO_TERRITORY_NAME_FONT_SIZE)
		# 3ª linha do nome — só usada quando o nome tem uma palavra
		# composta com hífen longa demais pra caber ao lado de "DE X"
		# numa única linha (ex.: "Mortos-Vivos" -> "DE MORTOS-" / "VIVOS",
		# ver _split_territory_name()). Mesmo tamanho de fonte das outras
		# 2 linhas do nome — nunca reduzido, pra ter a mesma presença
		# visual dos demais Territórios.
		var name_line3: Label = _make_popup_text_line("", VISAO_TERRITORY_NAME_FONT_SIZE)
		var fase_line: Label = _make_popup_text_line("", VISAO_SECONDARY_FONT_SIZE)
		var regiao_line: Label = _make_popup_text_line("", VISAO_SECONDARY_FONT_SIZE)
		left_stack.add_child(name_line1)
		left_stack.add_child(name_line2)
		left_stack.add_child(name_line3)
		left_stack.add_child(fase_line)
		left_stack.add_child(regiao_line)

		var right_stack: VBoxContainer = _make_popup_stack(row["right"])
		_visao_reino_overlay.add_child(right_stack)
		var status_line1: Label = _make_popup_text_line("", VISAO_STATUS_FONT_SIZE)
		var status_line2: Label = _make_popup_text_line("", VISAO_STATUS_FONT_SIZE)
		right_stack.add_child(status_line1)
		right_stack.add_child(status_line2)

		_visao_territory_stacks.append({
			"name_line1": name_line1, "name_line2": name_line2, "name_line3": name_line3,
			"fase_line": fase_line, "regiao_line": regiao_line,
			"status_line1": status_line1, "status_line2": status_line2,
		})

	# Rótulo de cada contador é texto FIXO (escrito uma única vez aqui,
	# nunca recalculado) — só o valor numérico é dinâmico (pedido: "o
	# valor numérico deve possuir hierarquia visual própria... título
	# menor; valor maior").
	const COUNTER_TITLES: Array[Array] = [
		["TERRITÓRIOS", "CONQUISTADOS"], ["MINAS", "CONQUISTADAS"], ["COMANDANTES", "REGIONAIS"],
	]
	_visao_counter_value_labels.clear()
	for i in range(VISAO_COUNTER_RECTS.size()):
		var stack: VBoxContainer = _make_popup_stack(VISAO_COUNTER_RECTS[i])
		_visao_reino_overlay.add_child(stack)
		stack.add_child(_make_popup_text_line(COUNTER_TITLES[i][0], VISAO_COUNTER_LABEL_FONT_SIZE))
		stack.add_child(_make_popup_text_line(COUNTER_TITLES[i][1], VISAO_COUNTER_LABEL_FONT_SIZE))
		var value_line: Label = _make_popup_text_line("", VISAO_COUNTER_VALUE_FONT_SIZE)
		stack.add_child(value_line)
		_visao_counter_value_labels.append(value_line)

	# Barra inferior: deliberadamente sem nenhum Label/texto (pedido:
	# "não colocar texto artificial apenas para preencher a barra").


## Pilha vertical centralizada (horizontal + vertical) de Labels dentro
## de "rect" (fração da imagem, com margem interna VISAO_BOX_INSET_X/Y
## — pedido §2: "margem interna adequada... nenhuma informação
## grudada"). Uma Label filha vazia/oculta (visible=false) não ocupa
## espaço na pilha — é assim que uma linha de Fase/Região ausente não
## deixa vão nem desalinha o resto verticalmente.
func _make_popup_stack(rect: Rect2) -> VBoxContainer:
	var inset: Rect2 = Rect2(
		rect.position.x + VISAO_BOX_INSET_X, rect.position.y + VISAO_BOX_INSET_Y,
		maxf(rect.size.x - VISAO_BOX_INSET_X * 2.0, 0.0), maxf(rect.size.y - VISAO_BOX_INSET_Y * 2.0, 0.0)
	)
	var stack := VBoxContainer.new()
	stack.anchor_left = inset.position.x
	stack.anchor_top = inset.position.y
	stack.anchor_right = inset.position.x + inset.size.x
	stack.anchor_bottom = inset.position.y + inset.size.y
	stack.offset_left = 0.0
	stack.offset_top = 0.0
	stack.offset_right = 0.0
	stack.offset_bottom = 0.0
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", VISAO_STACK_LINE_SEPARATION)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stack


## Uma única linha de texto dentro de uma pilha (_make_popup_stack()) —
## mesma tipografia/legibilidade Cinzel de sempre (HOVER_FONT/
## HOVER_TEXT_COLOR/contorno/sombra), só o tamanho de fonte muda por
## categoria (VISAO_*_FONT_SIZE).
func _make_popup_text_line(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HOVER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", HOVER_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HOVER_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HOVER_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HOVER_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HOVER_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HOVER_SHADOW_OFFSET)
	return label


## Fonte de verdade: WorldDatabase.get_current_season() (Território/
## Trilha reais — Season.territories, nunca assumido "sempre 3" — ver
## docstring de _build_visao_reino_overlay()) + Kingdom.active_expeditions
## (Fase/Região/Status de cada expedição real, casada por
## territory.id) + Kingdom.territory_completion_count + Kingdom.all_mines()
## + Kingdom.regional_commander_registry. Nenhum valor é inventado: uma
## caixa territorial sem expedição correspondente mostra "NÃO INICIADA"
## sem Fase/Região; se a Temporada ainda não carregou, os contadores
## mostram "—" em vez de 0 (0 significaria "Reino sem nenhum progresso",
## o que não é o mesmo que "dado indisponível").
func _refresh_visao_reino_popup() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var season: Season = WorldDatabase.get_current_season()

	var territories: Array = season.territories.values() if season != null else []

	for i in range(VISAO_TERRITORY_ROWS.size()):
		var stack: Dictionary = _visao_territory_stacks[i]

		if i >= territories.size():
			stack["name_line1"].text = ""
			stack["name_line2"].text = ""
			stack["name_line2"].visible = false
			stack["name_line3"].text = ""
			stack["name_line3"].visible = false
			stack["fase_line"].text = ""
			stack["fase_line"].visible = false
			stack["regiao_line"].text = ""
			stack["regiao_line"].visible = false
			stack["status_line1"].text = ""
			stack["status_line2"].text = ""
			stack["status_line2"].visible = false
			continue

		var territory: Territory = territories[i]
		var progress: Dictionary = _territory_progress(kingdom, territory)

		var name_lines: Array = _split_territory_name(territory.id)
		stack["name_line1"].text = name_lines[0]
		stack["name_line2"].text = name_lines[1]
		stack["name_line2"].visible = name_lines[1] != ""
		stack["name_line3"].text = name_lines[2]
		stack["name_line3"].visible = name_lines[2] != ""

		if progress["has_expedition"]:
			stack["fase_line"].text = "FASE %d / %d" % [progress["fase"], progress["total_fases"]]
			stack["regiao_line"].text = "REGIÃO %d" % progress["region"]
			stack["fase_line"].visible = true
			stack["regiao_line"].visible = true
		else:
			stack["fase_line"].text = ""
			stack["fase_line"].visible = false
			stack["regiao_line"].text = ""
			stack["regiao_line"].visible = false

		var status_lines: Array = _split_status_lines(progress["status_text"])
		stack["status_line1"].text = status_lines[0]
		if status_lines.size() > 1:
			stack["status_line2"].text = status_lines[1]
			stack["status_line2"].visible = true
		else:
			stack["status_line2"].text = ""
			stack["status_line2"].visible = false

	if season == null:
		_visao_counter_value_labels[0].text = "—"
		_visao_counter_value_labels[1].text = "—"
		_visao_counter_value_labels[2].text = "—"
		return

	var territories_completed := 0
	for territory: Territory in territories:
		if kingdom.get_territory_completion_count(territory.id) > 0:
			territories_completed += 1
	_visao_counter_value_labels[0].text = "%d / %d" % [territories_completed, territories.size()]

	var all_mines: Array = kingdom.all_mines()
	var mines_conquered := 0
	for mina: Mina in all_mines:
		if mina.conquered:
			mines_conquered += 1
	_visao_counter_value_labels[1].text = "%d / %d" % [mines_conquered, all_mines.size()]

	var recruited_count: int = kingdom.regional_commander_registry.export_data().size()
	_visao_counter_value_labels[2].text = "%d" % recruited_count


## Quebra controlada do nome do Território, sempre em até 3 linhas —
## nunca reformata/traduz o nome real (pedido §11 da tarefa anterior:
## "não hardcodar nomes de territórios"; esta rodada só refina COMO o
## texto já existente é dividido em linhas).
## - Sem hífen na 2ª parte (ex.: "Território de Império" ->
##   ["TERRITÓRIO", "DE IMPÉRIO", ""]): 2 linhas, como já aprovado.
## - Com hífen na 2ª parte (ex.: "Território de Mortos-Vivos" ->
##   ["TERRITÓRIO", "DE MORTOS-", "VIVOS"]): quebra deliberada no ÚLTIMO
##   hífen (convenção tipográfica padrão — o hífen fica no fim da linha
##   anterior), em vez de comprimir "DE MORTOS-VIVOS" inteiro numa só
##   linha. Regra genérica por conteúdo (qualquer nome composto com
##   hífen recebe o mesmo tratamento), não um caso especial só pra
##   "Mortos-Vivos".
func _split_territory_name(territory_name: String) -> Array:
	var first_space: int = territory_name.find(" ")
	if first_space == -1:
		return [territory_name.to_upper(), "", ""]

	var first_word: String = territory_name.substr(0, first_space).to_upper()
	var rest: String = territory_name.substr(first_space + 1).to_upper()

	var last_hyphen: int = rest.rfind("-")
	if last_hyphen != -1:
		return [first_word, rest.substr(0, last_hyphen + 1), rest.substr(last_hyphen + 1)]

	return [first_word, rest, ""]


## Quebra controlada dos 4 estados possíveis (mais "CONCLUÍDA"/
## "ENCERRADA", que já cabem numa linha só) — puramente uma decisão de
## apresentação sobre o texto que _territory_progress() já produz;
## nenhum estado novo é criado aqui.
func _split_status_lines(status_text: String) -> Array:
	match status_text:
		"NÃO INICIADA":
			return ["NÃO", "INICIADA"]
		"EM ANDAMENTO":
			return ["EM", "ANDAMENTO"]
		"AGUARDANDO NO ACAMPAMENTO":
			return ["AGUARDANDO", "NO ACAMPAMENTO"]
		_:
			return [status_text]


## Casa "territory" com a Expedição real mais recente de
## Kingdom.active_expeditions (por territory.id, nunca por igualdade de
## referência — ver docstring de _refresh_visao_reino_popup()). Mapeia
## ExpeditionRuntime.status/is_waiting_at_acampamento para os 4 estados
## do pedido; ENCERRADA não está entre os 4 estados previstos no pedido
## — mostrado como "ENCERRADA" (dado real, não inventado) e sinalizado
## no relatório final como caso não coberto pela lista original.
func _territory_progress(kingdom: Kingdom, territory: Territory) -> Dictionary:
	var latest: ExpeditionRuntime = null
	for expedition: ExpeditionRuntime in kingdom.active_expeditions:
		if expedition.territory.id == territory.id:
			latest = expedition

	if latest == null:
		return {"has_expedition": false, "status_text": "NÃO INICIADA"}

	var status_text: String
	match latest.status:
		ExpeditionRuntime.Status.EM_ANDAMENTO:
			status_text = "AGUARDANDO NO ACAMPAMENTO" if latest.is_waiting_at_acampamento else "EM ANDAMENTO"
		ExpeditionRuntime.Status.CONCLUIDA:
			status_text = "CONCLUÍDA"
		ExpeditionRuntime.Status.ENCERRADA:
			status_text = "ENCERRADA"
		_:
			status_text = "NÃO INICIADA"

	return {
		"has_expedition": true,
		"status_text": status_text,
		"fase": latest.current_fase,
		"total_fases": latest.trilha.total_fases(),
		"region": latest.trilha.region_for_fase(latest.current_fase),
	}


## Conteúdo dinâmico do pop-up "História do Reino" — única fonte de
## dados aprovada nesta etapa: Kingdom.commissioning_history (lida
## diretamente do estado persistido, nunca copiada pra um novo sistema
## — ver _refresh_historia_reino_popup()). Escondido por padrão; só
## aparece quando POPUP_ASSETS[key] == "historia_reino" (ver
## _open_capital_popup()). Mesma técnica de _build_visao_reino_overlay():
## pilhas de Labels sem fundo, direto sobre as molduras já existentes
## na arte — área central e as 3 caixas inferiores permanecem
## puramente decorativas, nenhum Control é criado sobre elas.
func _build_historia_reino_overlay() -> void:
	_historia_reino_overlay = Control.new()
	_historia_reino_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_historia_reino_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_historia_reino_overlay.visible = false
	_popup_texture_rect.add_child(_historia_reino_overlay)

	var title_label := _make_popup_label(HISTORIA_TITLE_RECT, HISTORIA_TITLE_FONT_SIZE)
	title_label.text = "HISTÓRIA DO REINO"
	_historia_reino_overlay.add_child(title_label)

	_historia_event_stacks.clear()
	for slot_rect: Rect2 in HISTORIA_EVENT_SLOTS:
		var stack: VBoxContainer = _make_popup_stack(slot_rect)
		_historia_reino_overlay.add_child(stack)

		# Nome do Comandante: única string desta tela sem tamanho
		# previsível (não é um rótulo fixo do jogo, como "Território de
		# X") — autowrap controlado (até 2 linhas, sempre centralizado)
		# em vez de truncar com "..." (pedido: "ajuste a apresentação
		# para caber... não truncar sem necessidade").
		var name_line: Label = _make_popup_text_line("", HISTORIA_NAME_FONT_SIZE)
		name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var origin_line: Label = _make_popup_text_line("", HISTORIA_META_FONT_SIZE)
		var date_line: Label = _make_popup_text_line("", HISTORIA_META_FONT_SIZE)
		stack.add_child(name_line)
		stack.add_child(origin_line)
		stack.add_child(date_line)

		_historia_event_stacks.append({"name_line": name_line, "origin_line": origin_line, "date_line": date_line})

	# Área central (biblioteca ilustrada) e as 3 caixas maiores
	# inferiores: nenhum Control criado — permanecem exatamente como a
	# arte já as desenha (pedido: "permanece puramente decorativa").


## Fonte de verdade única desta etapa: Kingdom.commissioning_history
## (engine/kingdom/kingdom.gd — {"commander_name", "source",
## "commissioned_at_unix"}, já persistido por kingdom_save_service.gd,
## mantido pelo próprio Kingdom com no máximo 20 entradas). Lido
## diretamente do estado do Reino a cada abertura do pop-up — nenhuma
## cópia local persistente é criada; "events" abaixo é só uma variável
## de função (existe só durante esta chamada) usada pra ordenar por
## commissioned_at_unix sem alterar a ordem do array real do Kingdom.
func _refresh_historia_reino_popup() -> void:
	var kingdom: Kingdom = KingdomState.kingdom

	var events: Array = kingdom.commissioning_history.duplicate()
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["commissioned_at_unix"] > b["commissioned_at_unix"])

	for i in range(HISTORIA_EVENT_SLOTS.size()):
		var stack: Dictionary = _historia_event_stacks[i]

		if i >= events.size():
			stack["name_line"].text = ""
			stack["origin_line"].text = ""
			stack["date_line"].text = ""
			continue

		var event: Dictionary = events[i]
		stack["name_line"].text = String(event["commander_name"])
		stack["origin_line"].text = String(event["source"])
		stack["date_line"].text = _format_commissioned_date(int(event["commissioned_at_unix"]))


## Formato curto e consistente pedido (DD/MM/AAAA) — nenhum utilitário
## de formatação de data já existia no projeto pra reaproveitar
## (verificado antes de escrever isto).
func _format_commissioned_date(unix_time: int) -> String:
	var parts: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d" % [parts["day"], parts["month"], parts["year"]]


## Conteúdo dinâmico do pop-up "Estatísticas do Reino" — 6 caixas
## laterais + a 1ª caixa inferior, cada uma com um rótulo FIXO (texto
## estático desta tela, nunca dado de jogo) + 1 valor dinâmico lido
## direto do Kingdom (ver _refresh_estatisticas_reino_popup()).
## Escondido por padrão; só aparece quando POPUP_ASSETS[key] ==
## "estatisticas_reino" (ver _open_capital_popup()). Mesma técnica de
## _build_visao_reino_overlay()/_build_historia_reino_overlay(): pilhas
## de Labels sem fundo, direto sobre as molduras já existentes na arte
## — a área central, as 2 caixas inferiores restantes e a barra
## inferior permanecem sem nenhum Control (pedido §4/§5/§6).
##
## Composição de cada caixa (refinamento visual — pedido "valor na
## frente do rótulo"): quando o rótulo precisa de mais de uma linha, as
## linhas anteriores à última ficam sozinhas (só quebra do próprio
## rótulo); a ÚLTIMA linha do rótulo entra numa HBoxContainer junto com
## o valor — nunca o valor isolado numa linha própria. O bloco inteiro
## (linhas de quebra + a linha final rótulo+valor) continua sendo um
## único VBoxContainer(ALIGNMENT_CENTER), então o CONJUNTO é
## centralizado como uma unidade só, nunca rótulo e valor centralizados
## independentemente um do outro.
func _build_estatisticas_reino_overlay() -> void:
	_estatisticas_reino_overlay = Control.new()
	_estatisticas_reino_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_estatisticas_reino_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_estatisticas_reino_overlay.visible = false
	_popup_texture_rect.add_child(_estatisticas_reino_overlay)

	var title_label := _make_popup_label(ESTATISTICAS_TITLE_RECT, ESTATISTICAS_TITLE_FONT_SIZE)
	title_label.text = "ESTATÍSTICAS DO REINO"
	_estatisticas_reino_overlay.add_child(title_label)

	# Linhas de cada rótulo (texto fixo, nunca dado de jogo), na MESMA
	# ordem exigida pelo pedido (Caixa 1-6) — casa 1:1 com a ordem de
	# leitura de valores em _refresh_estatisticas_reino_popup(). A
	# ÚLTIMA string de cada Array é sempre a que recebe o valor ao lado
	# (ver _add_label_value_stack() abaixo).
	const SIDE_LABELS: Array[Array] = [
		["NÍVEL DA ACADEMIA"],
		["NÍVEL DO CENTRO", "DE COMANDO"],
		["NÍVEL DO NÚCLEO", "DE ENERGIA"],
		["NÍVEL DOS DEPÓSITOS"],
		["COMANDANTES", "POSSUÍDOS"],
		["EXÉRCITOS FORMADOS"],
	]
	_estatisticas_value_labels.clear()
	for i in range(ESTATISTICAS_SIDE_SLOTS.size()):
		_estatisticas_value_labels.append(_add_label_value_stack(ESTATISTICAS_SIDE_SLOTS[i], SIDE_LABELS[i]))

	# Caixa inferior 1: "Squads Formados" — mesmo padrão rótulo+valor.
	_estatisticas_value_labels.append(_add_label_value_stack(ESTATISTICAS_BOTTOM_RECT, ["SQUADS FORMADOS"]))

	# Caixas inferiores 2 e 3, área central e barra inferior:
	# deliberadamente sem nenhum Control (pedido §4/§5/§6).


## Monta uma caixa "rótulo (com quebra controlada) + valor associado
## na mesma linha final" dentro de "rect", e a adiciona a
## _estatisticas_reino_overlay. Retorna o Label do valor (vazio —
## quem chama preenche depois em _refresh_estatisticas_reino_popup()).
func _add_label_value_stack(rect: Rect2, label_lines: Array) -> Label:
	var stack: VBoxContainer = _make_popup_stack(rect)
	_estatisticas_reino_overlay.add_child(stack)

	for i in range(label_lines.size() - 1):
		stack.add_child(_make_popup_text_line(label_lines[i], ESTATISTICAS_LABEL_FONT_SIZE))

	var final_row := HBoxContainer.new()
	final_row.alignment = BoxContainer.ALIGNMENT_CENTER
	final_row.add_theme_constant_override("separation", 8)
	final_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(final_row)

	final_row.add_child(_make_popup_text_line(label_lines[label_lines.size() - 1], ESTATISTICAS_LABEL_FONT_SIZE))
	var value_label: Label = _make_popup_text_line("", ESTATISTICAS_VALUE_FONT_SIZE)
	final_row.add_child(value_label)

	return value_label


## Lê diretamente do Kingdom atual, sem cópia local persistente —
## chamado de novo a cada abertura do pop-up (pedido §8: "a tela deve
## atualizar seus valores quando for aberta novamente"). Ordem dos 7
## valores casa 1:1 com _estatisticas_value_labels (preenchida na mesma
## ordem em _build_estatisticas_reino_overlay()).
func _refresh_estatisticas_reino_popup() -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var values: Array[int] = [
		kingdom.academy_level,
		kingdom.command_center_level,
		kingdom.energy_nucleus_level,
		kingdom.deposito_level,
		kingdom.commanders.size(),
		kingdom.armies.size(),
		kingdom.squads.size(),
	]
	for i in range(values.size()):
		_estatisticas_value_labels[i].text = str(values[i])


## Mantém o AspectRatioContainer do pop-up dentro de
## POPUP_MAX_SIZE_FRACTION do menor lado da tela, centralizado —
## responsivo sem nunca esticar a arte (o STRETCH_FIT do próprio
## AspectRatioContainer já cuida da proporção interna).
func _update_popup_margin() -> void:
	if _popup_aspect == null or _popup_layer == null:
		return
	var full: Vector2 = _popup_layer.size
	if full.x <= 0.0 or full.y <= 0.0:
		return
	var max_size_fraction: float = VISAO_POPUP_MAX_SIZE_FRACTION if _current_popup_key == "visao_reino" else POPUP_MAX_SIZE_FRACTION
	var margin_fraction: float = (1.0 - max_size_fraction) / 2.0
	var margin_x: float = full.x * margin_fraction
	var margin_y: float = full.y * margin_fraction
	_popup_aspect.offset_left = margin_x
	_popup_aspect.offset_right = -margin_x
	_popup_aspect.offset_top = margin_y
	_popup_aspect.offset_bottom = -margin_y


## Handler genérico dos 4 pop-ups — nenhuma cena é trocada, a Capital
## continua sendo a cena atual (ver pedido §3).
func _open_capital_popup(key: String) -> void:
	if not POPUP_ASSETS.has(key):
		return
	var asset: Dictionary = POPUP_ASSETS[key]
	_popup_texture_rect.texture = asset["texture"]
	_popup_aspect.ratio = asset["aspect_ratio"]
	_hover_name_container.visible = false
	_current_popup_key = key
	_update_popup_margin()

	_evoluir_capital_overlay.visible = (key == "evoluir_capital")
	if key == "evoluir_capital":
		_refresh_evoluir_capital_popup()

	_visao_reino_overlay.visible = (key == "visao_reino")
	if key == "visao_reino":
		_refresh_visao_reino_popup()

	_historia_reino_overlay.visible = (key == "historia_reino")
	if key == "historia_reino":
		_refresh_historia_reino_popup()

	_estatisticas_reino_overlay.visible = (key == "estatisticas_reino")
	if key == "estatisticas_reino":
		_refresh_estatisticas_reino_popup()

	_popup_layer.visible = true
	print("[CapitalPanel] Pop-up aberto: %s" % key)


func _close_capital_popup() -> void:
	_popup_layer.visible = false


func _on_popup_close_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_capital_popup()


## Trava a proporção efetiva disponível pro corte de STRETCH_COVER
## dentro de [SAFE_WINDOW_ASPECT_MIN, SAFE_WINDOW_ASPECT_MAX] — mesma
## técnica de CityPanel._update_city_safe_zone(), recalculada com as
## constantes/margens próprias desta tela (ver comentário de
## SAFE_WINDOW_ASPECT_MIN/MAX acima). Fora dessa faixa sobra uma barra
## residual pequena em vez de cortar uma região.
func _update_capital_safe_zone() -> void:
	if _capital_safe_zone == null or _capital_area == null:
		return
	var full: Vector2 = _capital_area.size
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

	# ALIGNMENT_BEGIN horizontal (protege a esquerda, ver História) +
	# ALIGNMENT_END vertical (protege embaixo, ver História/Estatísticas)
	# — a folga residual (só existe fora da faixa segura) fica à
	# direita e em cima, nunca nas margens apertadas.
	_capital_safe_zone.anchor_left = 0.0
	_capital_safe_zone.anchor_right = 0.0
	_capital_safe_zone.anchor_top = 0.0
	_capital_safe_zone.anchor_bottom = 0.0
	_capital_safe_zone.offset_left = 0.0
	_capital_safe_zone.offset_right = w
	_capital_safe_zone.offset_top = full.y - h
	_capital_safe_zone.offset_bottom = full.y
	_capital_safe_zone.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_capital_safe_zone.grow_vertical = Control.GROW_DIRECTION_BOTH


func _build_hitbox(key: String) -> Control:
	var region: Dictionary = REGIONS[key]
	var rect: Rect2 = region["rect"]

	# FASE 15: sinal luminoso — mesma fábrica reutilizável já usada em
	# city_panel.gd/biblioteca_panel.gd/etc. (hotspot_glow.gd), mesma
	# região fracionária já calibrada (rect), nenhuma coordenada nova.
	# Adicionado ANTES da hitbox de propósito (desenha atrás dela; a
	# hitbox em si nunca desenha nada).
	var glow = preload("res://engine/presentation/hotspot_glow.gd").new().attach_to_region(_capital_texture_rect, rect)
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
	hitbox.gui_input.connect(_on_hitbox_gui_input.bind(key))
	hitbox.mouse_entered.connect(_on_hitbox_mouse_entered.bind(hitbox, region["label"], key))
	hitbox.mouse_exited.connect(_on_hitbox_mouse_exited.bind(key))
	return hitbox


func _build_hover_chip() -> Dictionary:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(HOVER_ACCENT.r, HOVER_ACCENT.g, HOVER_ACCENT.b, 0.10)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(HOVER_ACCENT.r, HOVER_ACCENT.g, HOVER_ACCENT.b, 0.55)
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
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HOVER_FONT)
	label.add_theme_font_size_override("font_size", HOVER_FONT_SIZE)
	label.add_theme_color_override("font_color", HOVER_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", HOVER_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", HOVER_OUTLINE_SIZE)
	label.add_theme_color_override("font_shadow_color", HOVER_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", HOVER_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", HOVER_SHADOW_OFFSET)
	chip.add_child(label)

	return {"container": chip, "label": label}


func _on_hitbox_mouse_entered(hitbox: Control, region_label: String, key: String = "") -> void:
	if _building_glows.has(key):
		_building_glows[key].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.HOVER)
	_hover_name_label.text = region_label
	var chip_size: Vector2 = _hover_name_container.get_combined_minimum_size()
	_hover_name_container.size = chip_size

	var hitbox_rect: Rect2 = hitbox.get_global_rect()
	var x: float = hitbox_rect.position.x + hitbox_rect.size.x / 2.0 - chip_size.x / 2.0
	var y: float = hitbox_rect.position.y - chip_size.y - 6.0
	y = max(y, 4.0)

	_hover_name_container.global_position = Vector2(x, y)
	_hover_name_container.visible = true


func _on_hitbox_mouse_exited(key: String = "") -> void:
	if _building_glows.has(key):
		_building_glows[key].set_hotspot_state(preload("res://engine/presentation/hotspot_glow.gd").State.AVAILABLE)
	_hover_name_container.visible = false


## Clique = ação de entrada direta (nunca um painel intermediário, ver
## pedido). Nesta etapa cada região só loga qual foi acionada — pronta
## pra receber a ação real (abrir "Visão do Reino"/"Evoluir Capital"/
## "História do Reino"/"Estatísticas do Reino") numa tarefa futura, sem
## nenhuma tela fictícia criada agora.
func _on_hitbox_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match key:
			"visao_reino":
				_on_visao_reino_clicked()
			"evoluir_capital":
				_on_evoluir_capital_clicked()
			"historia_reino":
				_on_historia_reino_clicked()
			"estatisticas_reino":
				_on_estatisticas_reino_clicked()


## Abre o pop-up "Visão do Reino" (asset: Assets/MVP/Construções/
## CAPITAL-Kindon overview-V2.png). Conteúdo dinâmico (dados/lógica)
## fora de escopo nesta etapa — só a composição visual do pop-up.
func _on_visao_reino_clicked() -> void:
	_open_capital_popup("visao_reino")


## Asset: Assets/MVP/Construções/Capital Upgrade.png.
func _on_evoluir_capital_clicked() -> void:
	_open_capital_popup("evoluir_capital")


## Asset: Assets/MVP/Construções/CAPITAL-kingdom History Popup.png.
func _on_historia_reino_clicked() -> void:
	_open_capital_popup("historia_reino")


## Asset: Assets/MVP/Construções/CAPITAL-Kingdom Statistics Popup.png.
func _on_estatisticas_reino_clicked() -> void:
	_open_capital_popup("estatisticas_reino")


func _on_back_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_back_to_city_pressed()


func _on_back_to_city_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/city/city_panel.tscn")
