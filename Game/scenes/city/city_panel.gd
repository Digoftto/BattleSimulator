extends Control
## CityPanel (CITY.md)
##
## O hub principal do jogo — resumo do Reino (Conta, Recursos de
## Construção, Fragmentos), as 5 construções institucionais com
## evolução real, e navegação pras demais janelas. Mesmo padrão das
## demais telas: árvore em código, sem estado próprio, reconstruída a
## cada ação.
##
## É a primeira tela pensada como PONTO DE ENTRADA de verdade do jogo
## (as outras 6 janelas do Centro de Comando ainda só rodam isoladas,
## uma de cada vez, via F6 — navegar entre elas troca a cena inteira,
## não é uma navegação "dentro" do jogo ainda; isso é uma peça em
## aberto, não desta entrega).

const RAW_RESOURCES: Array[String] = ["ferro_negro", "cristais_arcanos", "essencia_vital"]
const RAW_RESOURCE_LABELS: Dictionary = {
	"ferro_negro": "Ferro Negro", "cristais_arcanos": "Cristais Arcanos", "essencia_vital": "Essência Vital",
}
const FACTIONS: Array[String] = ["Império", "Natureza", "Mortos-Vivos"]

const PANEL_SCENES: Dictionary = {
	"Exércitos": "res://scenes/city/panels/exercitos_panel.tscn",
	"Academia": "res://scenes/city/panels/academia_panel.tscn",
	"Biblioteca": "res://scenes/city/panels/biblioteca_panel.tscn",
	"Observatório": "res://scenes/city/panels/observatorio_panel.tscn",
	"Comandantes": "res://scenes/command_center/panels/comandantes_panel.tscn",
	"Treinamento": "res://scenes/command_center/panels/treinamento_panel.tscn",
	"Legado": "res://scenes/command_center/panels/legado_panel.tscn",
	"Minas": "res://scenes/command_center/panels/minas_panel.tscn",
	"PvE": "res://scenes/command_center/panels/pve_panel.tscn",
	"PvP": "res://scenes/command_center/panels/pvp_panel.tscn",
}

var _root_vbox: VBoxContainer
var _resumo_label: Label
var _recursos_label: Label
var _fragmentos_label: Label
var _construcoes_container: VBoxContainer


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

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.custom_minimum_size = Vector2(700, 0)
	_root_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(_root_vbox)

	var title := Label.new()
	title.text = "Cidade"
	title.add_theme_font_size_override("font_size", 24)
	_root_vbox.add_child(title)

	# --- Navegação ---
	var nav_title := Label.new()
	nav_title.text = "Ir para:"
	_root_vbox.add_child(nav_title)
	var nav_row := HBoxContainer.new()
	_root_vbox.add_child(nav_row)
	for panel_name: String in PANEL_SCENES:
		var button := Button.new()
		button.text = panel_name
		button.pressed.connect(_on_navigate_pressed.bind(panel_name), CONNECT_DEFERRED)
		nav_row.add_child(button)

	_add_section_title("Resumo do Reino")
	_resumo_label = Label.new()
	_root_vbox.add_child(_resumo_label)

	_add_section_title("Recursos de Construção")
	_recursos_label = Label.new()
	_root_vbox.add_child(_recursos_label)

	_add_section_title("Fragmentos")
	_fragmentos_label = Label.new()
	_root_vbox.add_child(_fragmentos_label)

	_add_section_title("Construções")
	_construcoes_container = VBoxContainer.new()
	_construcoes_container.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(_construcoes_container)


func _add_section_title(text: String) -> void:
	var separator := HSeparator.new()
	_root_vbox.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	_root_vbox.add_child(label)


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

	_resumo_label.text = "Nível de Conta: %d | XP de Conta: %d | Pontos de Geração: %d" % [
		kingdom.account_level(), kingdom.account_xp, kingdom.generation_points
	]

	var recursos_lines: Array[String] = []
	var capacity: int = Deposits.storage_capacity(kingdom.deposito_level)
	for resource: String in RAW_RESOURCES:
		recursos_lines.append("%s: %d / %d" % [RAW_RESOURCE_LABELS[resource], kingdom.get_raw_resource(resource), capacity])
	_recursos_label.text = "\n".join(recursos_lines)

	var fragment_lines: Array[String] = []
	for faction: String in FACTIONS:
		fragment_lines.append("%s: %d" % [faction, kingdom.get_fragment(faction)])
	_fragmentos_label.text = " | ".join(fragment_lines)

	_refresh_construcoes(kingdom)


func _refresh_construcoes(kingdom: Kingdom) -> void:
	_clear_children(_construcoes_container)

	_build_institutional_row(kingdom, "Capital", InstitutionalConstructionConfig.Building.CAPITAL, kingdom.capital_level)
	_build_institutional_row(kingdom, "Centro de Comando", InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO, kingdom.command_center_level)
	_build_institutional_row(kingdom, "Academia", InstitutionalConstructionConfig.Building.ACADEMIA, kingdom.academy_level)
	_build_institutional_row(kingdom, "Núcleo de Energia", InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA, kingdom.energy_nucleus_level)
	_build_deposit_row(kingdom)


func _build_institutional_row(kingdom: Kingdom, label_text: String, building: InstitutionalConstructionConfig.Building, current_level: int) -> void:
	var row := HBoxContainer.new()
	_construcoes_container.add_child(row)

	var costs: Dictionary = InstitutionalConstructionResolver.cost_breakdown(building, current_level + 1)
	var cost_text: String = ", ".join(costs.keys().map(func(k: String) -> String: return "%s: %d" % [RAW_RESOURCE_LABELS.get(k, k), costs[k]]))

	var label := Label.new()
	label.text = "%s — Nível %d (próximo: %s)" % [label_text, current_level, cost_text]
	label.custom_minimum_size = Vector2(450, 0)
	row.add_child(label)

	var button := Button.new()
	button.text = "Evoluir"
	button.pressed.connect(_on_evolve_institutional_pressed.bind(building), CONNECT_DEFERRED)
	row.add_child(button)


func _build_deposit_row(kingdom: Kingdom) -> void:
	var row := HBoxContainer.new()
	_construcoes_container.add_child(row)

	var pg_cost: int = Deposits.upgrade_cost_pg(kingdom.deposito_level + 1)
	var label := Label.new()
	label.text = "Depósito — Nível %d (próximo: %d PG, capacidade atual: %d)" % [
		kingdom.deposito_level, pg_cost, Deposits.storage_capacity(kingdom.deposito_level)
	]
	label.custom_minimum_size = Vector2(450, 0)
	row.add_child(label)

	var button := Button.new()
	button.text = "Evoluir"
	button.pressed.connect(_on_evolve_deposit_pressed, CONNECT_DEFERRED)
	row.add_child(button)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _on_evolve_institutional_pressed(building: InstitutionalConstructionConfig.Building) -> void:
	var result: Dictionary = InstitutionalConstructionResolver.evolve(KingdomState.kingdom, building)
	if not result["success"]:
		print("[CityPanel] Evoluir construção falhou: %s" % result["reason"])
	refresh()


func _on_evolve_deposit_pressed() -> void:
	var result: Dictionary = CityResolver.evolve_deposit(KingdomState.kingdom)
	if not result["success"]:
		print("[CityPanel] Evoluir Depósito falhou: %s" % result["reason"])
	refresh()


func _on_navigate_pressed(panel_name: String) -> void:
	get_tree().change_scene_to_file.call_deferred(PANEL_SCENES[panel_name])
