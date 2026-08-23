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
## World Map Gate / League Hall (F-016: não canônicos) permanecem
## puramente decorativos na arte — nenhuma hitbox.
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

## City.png é 1536x1024 (F-021/F-022). F-025: cópia byte-idêntica
## trazida para dentro da árvore do projeto (Game/assets/art/City.png,
## MD5 confirmado idêntico ao original em Assets/MVP/Construções/, que
## permanece intocado) — carregada normalmente via res://, sem
## depender de nenhum caminho absoluto do sistema de arquivos, pra
## funcionar também numa build exportada.
const CITY_TEXTURE: Texture2D = preload("res://assets/art/City.png")
const CITY_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

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
}

var _resumo_label: Label
## ART-005: ícones construídos 1x (nunca mudam) — só o texto de cada
## Label é atualizado a cada refresh(), mesmo padrão já usado por
## _resumo_label/_fragmentos_label neste arquivo (diferente de outros
## painéis do projeto, refresh() aqui NUNCA reconstrói a árvore).
var _recursos_amount_labels: Dictionary = {}  # resource_name -> Label
var _fragmentos_label: Label
## F-009: mensagem visível quando "Evoluir" é rejeitado (ex: recursos
## insuficientes) — antes só existia um print() no console, que o
## jogador nunca vê; o clique parecia não fazer nada.
var _evolve_status_label: Label

var _city_texture_rect: TextureRect
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
	print("[CityPanel] Pronto. Nível de Conta: %d" % KingdomState.kingdom.account_level())


func _show_starter_kit() -> void:
	var kit_panel: StarterKitPanel = load("res://scenes/city/panels/starter_kit_panel.tscn").instantiate()
	kit_panel.kit_chosen.connect(_on_starter_kit_chosen.bind(kit_panel))
	add_child(kit_panel)


func _on_starter_kit_chosen(kit_panel: StarterKitPanel) -> void:
	kit_panel.queue_free()
	_build_static_structure()
	refresh()
	print("[CityPanel] Pronto (após Kit Inicial). Nível de Conta: %d" % KingdomState.kingdom.account_level())


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
	background.color = Color(0.12, 0.12, 0.16)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# --- Barra de status compacta (F-023: substitui as antigas seções
	# de texto empilhadas verticalmente — mesmos valores, mesma fonte
	# de dados, só reorganizados numa faixa horizontal compacta no
	# topo, secundária à Cidade). ---
	var status_bar := PanelContainer.new()
	root.add_child(status_bar)
	var status_hbox := HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 24)
	status_bar.add_child(status_hbox)

	var title := Label.new()
	title.text = "Cidade"
	title.add_theme_font_size_override("font_size", 20)
	status_hbox.add_child(title)

	# F-025: clip_text = true impede que o texto (longo, uma linha só)
	# force a largura mínima de root (VBoxContainer) a ultrapassar a
	# janela — sem isso, em janelas estreitas o próprio City.png ficava
	# forçado pra fora do viewport como efeito colateral, mesmo depois
	# da correção de escala. SIZE_EXPAND_FILL garante que, havendo
	# espaço de sobra (janelas normais/largas), o texto ainda usa esse
	# espaço e aparece por inteiro — sem os dois juntos, clip_text
	# sozinho faz a label colapsar pra largura ~0 mesmo com espaço de
	# sobra disponível.
	_resumo_label = Label.new()
	_resumo_label.clip_text = true
	_resumo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_hbox.add_child(_resumo_label)
	# ART-005: ícone real por recurso (RAW_RESOURCES/RESOURCE_ARCANE_CRYSTAL
	# etc., F-049) em vez de um único Label de texto concatenado —
	# construído 1x aqui, texto de cada quantidade atualizado em
	# refresh(). Some sozinho (sem quebrar o texto) se um recurso
	# específico não tiver ícone integrado.
	var recursos_hbox := HBoxContainer.new()
	recursos_hbox.add_theme_constant_override("separation", 4)
	recursos_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_hbox.add_child(recursos_hbox)
	for resource: String in RAW_RESOURCES:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = preload("res://engine/presentation/resource_art_catalog.gd").texture_for(resource)
		icon.visible = icon.texture != null
		recursos_hbox.add_child(icon)

		var amount_label := Label.new()
		amount_label.clip_text = true
		recursos_hbox.add_child(amount_label)
		_recursos_amount_labels[resource] = amount_label
	_fragmentos_label = Label.new()
	_fragmentos_label.clip_text = true
	_fragmentos_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_hbox.add_child(_fragmentos_label)

	_evolve_status_label = Label.new()
	root.add_child(_evolve_status_label)

	# --- Área da Cidade: preenche o espaço restante, preservando a
	# proporção 1536x1024 da imagem (AspectRatioContainer nativo do
	# Godot — sem stretch independente em X/Y, sem matemática de
	# letterbox manual). ---
	var city_area := Control.new()
	city_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(city_area)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = CITY_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	city_area.add_child(aspect)

	_city_texture_rect = TextureRect.new()
	_city_texture_rect.texture = CITY_TEXTURE
	_city_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	# F-025 (causa raiz do bug de escala do F-024): expand_mode por
	# padrão é EXPAND_KEEP_SIZE, que faz get_minimum_size() retornar o
	# tamanho NATIVO da textura (1536x1024) — um Container nunca
	# encolhe um filho abaixo do seu tamanho mínimo, então isso forçava
	# o próprio AspectRatioContainer a ficar preso em 1536x1024,
	# ignorando o espaço disponível de verdade (confirmado por medição
	# direta antes desta correção: AspectRatioContainer.size ==
	# (1536.0, 1024.0) mesmo numa janela 1280x800). EXPAND_IGNORE_SIZE
	# zera o tamanho mínimo, deixando o AspectRatioContainer calcular o
	# retângulo com base no espaço real disponível.
	_city_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_city_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(_city_texture_rect)

	# --- Regiões clicáveis: filhas do TextureRect, ancoradas por
	# fração (0.0-1.0) do seu próprio retângulo — acompanham a imagem
	# automaticamente em qualquer redimensionamento, sem coordenadas
	# absolutas de tela. ---
	for key: String in BUILDING_REGIONS:
		_city_texture_rect.add_child(_build_hitbox(key))

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
	hitbox.tooltip_text = region["label"]
	hitbox.gui_input.connect(_on_hitbox_gui_input.bind(key))
	return hitbox


func _on_hitbox_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_building_key = key
		_update_contextual_panel()


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

	_resumo_label.text = "Nível de Conta: %d | XP: %d | PG: %d" % [
		kingdom.account_level(), kingdom.account_xp, kingdom.generation_points
	]

	var capacity: int = Deposits.storage_capacity(kingdom.deposito_level)
	for resource: String in RAW_RESOURCES:
		_recursos_amount_labels[resource].text = "%s: %d/%d " % [RAW_RESOURCE_LABELS[resource], kingdom.get_raw_resource(resource), capacity]

	var fragment_lines: Array[String] = []
	for faction: String in FACTIONS:
		fragment_lines.append("%s: %d" % [faction, kingdom.get_fragment(faction)])
	_fragmentos_label.text = " | ".join(fragment_lines)

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
