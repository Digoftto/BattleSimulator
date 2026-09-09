extends Control
## WarehouseSupplyChainPanel (DEPOSITS.md, "Reserva Antecipada de
## Evolução")
##
## Tela própria (nunca popup) — adaptada nesta etapa ao TEMPLATE VISUAL
## DEFINITIVO fornecido (warehouse_supply_chain.png, 1536x1024,
## substituído no projeto mantendo o mesmo nome de arquivo — a arte
## ANTERIOR, retrato 1024x1536, não representa mais este layout). A
## nova arte já desenha rótulos, ícones, molduras e caixas de valor
## para cada dado — o Godot só precisa preencher essas caixas com os
## valores reais, nunca desenhar um painel genérico por cima
## (pedido explícito desta etapa).
##
## Todas as regiões (Rect2) abaixo foram calibradas por inspeção de
## pixel direta sobre o asset atual (grades de referência + varredura
## de cor das caixas escuras, ver relatório da tarefa) — nenhuma
## reaproveitada cegamente do layout provisório anterior.
##
## ARQUITETURA DE CÓDIGO (pedido explícito, preservada desta etapa):
## nenhuma lógica econômica vive aqui — toda decisão de QUANTO pode ser
## transferido e a execução da transferência em si vivem em
## SupplyChainResolver (engine/city/supply_chain_resolver.gd). Os
## helpers abaixo (_get_transferable_amount/_transfer_resource/
## _complete_missing_resource/_transfer_all_possible/
## _get_building_requirements/_get_building_stored_resources) são
## wrappers finos, idênticos aos da etapa anterior — só a apresentação
## mudou nesta tarefa, nenhuma regra de negócio foi tocada.
##
## Seleção de Recurso (novo nesta etapa — a arte anterior tinha 3
## conjuntos paralelos de controles de transferência, um por Recurso; a
## nova arte tem um único conjunto "Enviar Recursos" compartilhado, com
## os 3 cartões de Recurso funcionando como seletor). "Transferir Tudo"
## continua agindo sobre a CONSTRUÇÃO inteira (os 3 Recursos de uma vez,
## DEPOSITS.md: "tudo que puder ser enviado pra completar a necessidade
## daquela construção") — só "Transferir Quantidade"/"Completar Falta"
## dependem do Recurso selecionado.
##
## CORREÇÃO PÓS-VALIDAÇÃO VISUAL (3 problemas):
## 1. Indicador de seleção deslocado (Academia + Essência Vital) —
##    causa raiz era imprecisão de calibração dos Rect2 de entrada
##    (não um bug no mecanismo de ancoragem, que já era uniforme entre
##    todos os cartões) — recalibrado por detecção real de conteúdo/
##    borda, ver constantes abaixo.
## 2. Recurso transferido não aparecia na tela da construção (Capital)
##    — bug estava em capital_panel.gd, que lia kingdom.get_raw_resource()
##    (saldo do Depósito) em vez de kingdom.get_building_reserved()
##    (onde a transferência realmente é creditada) — corrigido lá,
##    mesma fonte única de verdade (Kingdom.building_reserved_resources).
## 3. Confirmação em 2 etapas: TRANSFERIR QUANTIDADE/TUDO/COMPLETAR
##    FALTA agora só PREPARAM um preview (_pending_transfer) — nenhuma
##    chamada a _transfer_resource()/_transfer_all_possible()/
##    _complete_missing_resource() acontece até CONFIRMAR TRANSFERÊNCIA
##    ser clicado. Ver _prepare_transfer()/_on_confirm_transfer_gui_input().

const SUPPLY_CHAIN_TEXTURE: Texture2D = preload("res://assets/art/city_buildings/warehouse_supply_chain.png")
const SUPPLY_CHAIN_IMAGE_ASPECT_RATIO: float = 1536.0 / 1024.0

const HUD_FONT: Font = preload("res://assets/fonts/Cinzel-SemiBold.ttf")
const HUD_TEXT_COLOR: Color = Color(0.93, 0.93, 0.90)
const HUD_MUTED_COLOR: Color = Color(0.70, 0.70, 0.68)
const HUD_OUTLINE_COLOR: Color = Color(0.02, 0.02, 0.02, 0.95)
const HUD_ACCENT_SELECTED: Color = Color(0.95, 0.80, 0.35)

const RAW_RESOURCES: Array[String] = ["ferro_negro", "cristais_arcanos", "essencia_vital"]

const ELIGIBLE_BUILDINGS: Array[InstitutionalConstructionConfig.Building] = [
	InstitutionalConstructionConfig.Building.CAPITAL,
	InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO,
	InstitutionalConstructionConfig.Building.ACADEMIA,
	InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA,
]

## Descrições curtas já documentadas em CITY.md (§"Estrutura Geral e
## Construções") — reaproveitadas verbatim, nunca inventadas, pro
## campo "DESCRIÇÃO" da arte (pedido explícito: usar dados reais; o
## projeto não tem um campo de descrição dedicado em código, então a
## fonte real mais próxima é a própria arquitetura documentada).
const BUILDING_DESCRIPTIONS: Dictionary = {
	InstitutionalConstructionConfig.Building.CAPITAL: "A Capital é a construção central da Cidade. É responsável por ditar o teto de expansão urbana e liberar o avanço dos demais edifícios do Reino.",
	InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO: "Define a capacidade operacional do Reino para manter simultaneamente Comandantes e Exércitos, estabelecendo os limites estruturais da administração militar.",
	InstitutionalConstructionConfig.Building.ACADEMIA: "Responsável pelos sistemas de pesquisa e desenvolvimento tecnológico do Reino.",
	InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA: "Responsável pelo gerenciamento, capacidade máxima e fluxo de regeneração do sistema de energia do Reino.",
}

## Nomes de exibição — a arte nunca precisou disso antes (nomes das
## construções já vêm desenhados nos cartões), mas o preview de
## confirmação (pedido §"PREVIEW") precisa citar a construção/Recurso
## por nome em texto dinâmico. Mesmos nomes já usados em
## warehouse_kingdom_inventory_panel.gd/city_panel.gd.
const BUILDING_LABELS: Dictionary = {
	InstitutionalConstructionConfig.Building.CAPITAL: "Capital",
	InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO: "Centro de Comando",
	InstitutionalConstructionConfig.Building.ACADEMIA: "Academia",
	InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA: "Núcleo de Energia",
}
const RAW_RESOURCE_LABELS: Dictionary = {
	"ferro_negro": "Ferro Negro", "cristais_arcanos": "Cristais Arcanos", "essencia_vital": "Essência Vital",
}

## --- Regiões calibradas sobre warehouse_supply_chain.png (1536x1024) ---

## CORRIGIDO (pedido explícito, "indicador deslocado"): a arte não
## desenha uma borda visível ao redor de cada cartão de construção (ao
## contrário dos cartões de Recurso, que têm moldura própria) — a
## calibração original tentou estimar visualmente o contorno de
## ícone+nome numa grade de referência de 100px, o que é impreciso o
## bastante pra gerar um deslocamento visível (confirmado: a Academia
## media ~200px de largura na calibração antiga contra ~196px reais, e
## começava ~12px à esquerda do conteúdo real). Recalibrado por
## detecção de conteúdo real (varredura de pixel: qualquer pixel
## claramente mais claro que o fundo escuro uniforme entre os
## cartões, nunca uma medição visual aproximada — ver relatório da
## tarefa). O mecanismo de ancoragem em si (_anchor_control(),
## anchors fracionários 0..1 relativos ao mesmo texture_rect pai,
## idêntico pra hotspot e para a borda de seleção) já estava correto
## e uniforme entre os 4 cartões — o problema era exclusivamente a
## precisão dos 4 Rect2 de entrada, nunca o código de ancoragem.
const CAPITAL_CARD: Rect2 = Rect2(0.2415, 0.1484, 0.1159, 0.1328)
const COMMAND_CENTER_CARD: Rect2 = Rect2(0.3646, 0.1484, 0.1276, 0.1328)
const ACADEMY_CARD: Rect2 = Rect2(0.4993, 0.1484, 0.1276, 0.1328)
const ENERGY_NUCLEUS_CARD: Rect2 = Rect2(0.6335, 0.1484, 0.1243, 0.1328)
const BUILDING_CARD_RECTS: Dictionary = {
	InstitutionalConstructionConfig.Building.CAPITAL: CAPITAL_CARD,
	InstitutionalConstructionConfig.Building.CENTRO_DE_COMANDO: COMMAND_CENTER_CARD,
	InstitutionalConstructionConfig.Building.ACADEMIA: ACADEMY_CARD,
	InstitutionalConstructionConfig.Building.NUCLEO_DE_ENERGIA: ENERGY_NUCLEUS_CARD,
}

const CURRENT_LEVEL_BOX: Rect2 = Rect2(0.2507, 0.3760, 0.0944, 0.0391)
const NEXT_LEVEL_BOX: Rect2 = Rect2(0.3678, 0.3760, 0.1400, 0.0391)
const DESCRIPTION_BOX: Rect2 = Rect2(0.5306, 0.3467, 0.2246, 0.0830)

## 4 caixas por Recurso (Necessário/Já Possui/Falta/Disponível no
## Depósito) x 3 Recursos — mesma ordem de linha nas 3 colunas.
## "card" (moldura ao redor do ícone+nome+valores, usada como área do
## indicador de seleção) recalibrado com precisão total de casas
## decimais (a versão anterior arredondava a 4 casas, gerando um erro
## de ~3px na borda direita da caixa de Essência Vital — pequeno, mas
## real; corrigido junto com a Academia pra eliminar QUALQUER imprecisão
## de calibração nos 3 Recursos, não só o mais visível).
## "ja_possui"/"falta" recalibrados (pedido explícito, microcalibração
## final): detecção de pixel real mostrou que as duas caixas ficavam
## ~7.5px e ~16.5px mais alto do que a caixa real desenhada na arte
## (única causa — o valor já usava HORIZONTAL_ALIGNMENT_CENTER e
## VERTICAL_ALIGNMENT_CENTER desde a etapa anterior; o problema era
## puramente a posição Y do Rect2 de entrada, nunca o alinhamento).
## "necessario"/"disponivel" NÃO foram tocados (pedido explícito — já
## estavam corretos, confirmado pela mesma varredura de pixel).
const RESOURCE_ROW_BOXES: Dictionary = {
	"ferro_negro": {
		"necessario": Rect2(0.3451, 0.5352, 0.0488, 0.0234),
		"ja_possui": Rect2(0.345052, 0.566406, 0.048828, 0.023438),
		"falta": Rect2(0.345052, 0.599609, 0.048828, 0.023438),
		"disponivel": Rect2(0.3451, 0.6328, 0.0488, 0.0234),
		"card": Rect2(0.237630, 0.483398, 0.164063, 0.184570),
	},
	"cristais_arcanos": {
		"necessario": Rect2(0.5241, 0.5352, 0.0488, 0.0234),
		"ja_possui": Rect2(0.524089, 0.566406, 0.048828, 0.023438),
		"falta": Rect2(0.524089, 0.599609, 0.048828, 0.023438),
		"disponivel": Rect2(0.5241, 0.6328, 0.0488, 0.0234),
		"card": Rect2(0.416016, 0.483398, 0.166016, 0.184570),
	},
	"essencia_vital": {
		"necessario": Rect2(0.7031, 0.5352, 0.0488, 0.0234),
		"ja_possui": Rect2(0.703125, 0.566406, 0.048828, 0.023438),
		"falta": Rect2(0.703125, 0.599609, 0.048828, 0.023438),
		"disponivel": Rect2(0.7031, 0.6328, 0.0488, 0.0234),
		"card": Rect2(0.596354, 0.483398, 0.167969, 0.184570),
	},
}

const QUANTITY_INPUT_BOX: Rect2 = Rect2(0.2441, 0.7441, 0.1042, 0.0303)
const QUANTITY_SPIN_UP: Rect2 = Rect2(0.3516, 0.7441, 0.0163, 0.0146)
const QUANTITY_SPIN_DOWN: Rect2 = Rect2(0.3516, 0.7598, 0.0163, 0.0146)
## CORRIGIDO (pedido explícito, "Máx. Permitido deslocado pra
## esquerda"): a caixa antiga (x 0.2311) caía sobre o próprio texto do
## rótulo "MÁX. PERMITIDO:" — o campo vazio real desenhado na arte fica
## bem à direita do texto (detectado por varredura de pixel: x515-558,
## nunca uma leitura visual aproximada). Bug de posição, não de
## alinhamento (o Label já usava CENTER).
const MAX_ALLOWED_BOX: Rect2 = Rect2(0.335286, 0.810547, 0.027995, 0.023438)
const TRANSFER_QUANTITY_BUTTON: Rect2 = Rect2(0.3887, 0.7354, 0.1159, 0.0830)
const TRANSFER_ALL_BUTTON: Rect2 = Rect2(0.5163, 0.7354, 0.1185, 0.0830)
const COMPLETE_MISSING_BUTTON: Rect2 = Rect2(0.6445, 0.7354, 0.1172, 0.0830)

## Recalibrado (pedido explícito, microcalibração final): a versão
## anterior era uma leitura visual aproximada numa grade de 100px
## (mesma classe de imprecisão já corrigida nos cartões de construção
## numa etapa anterior) — cada caixa tinha a largura ~2x maior que a
## real e o centro vertical de "capacidade" ficava sistematicamente
## acima do centro real da caixa (Ferro ~5px, Cristais ~15.5px,
## Essência ~8.5px), exatamente o sintoma reportado. Recalibrado por
## varredura de pixel real (nenhuma leitura visual aproximada).
const DEPOSITO_BOXES: Dictionary = {
	"ferro_negro": {"disponivel": Rect2(0.115234, 0.231445, 0.066406, 0.028320), "capacidade": Rect2(0.115234, 0.290039, 0.066406, 0.026367)},
	"cristais_arcanos": {"disponivel": Rect2(0.115234, 0.439453, 0.066406, 0.027344), "capacidade": Rect2(0.115234, 0.497070, 0.066406, 0.027344)},
	"essencia_vital": {"disponivel": Rect2(0.115234, 0.651367, 0.066406, 0.027344), "capacidade": Rect2(0.115234, 0.709961, 0.066406, 0.027344)},
}

## Recalibrado (pedido explícito): a versão anterior usava x=0.8073
## (1240px) — a caixa real desenhada na arte começa em x≈1340px, ~100px
## mais à direita (a antiga caía sobre o ícone do Recurso, não sobre o
## campo vazio). Recalibrado por varredura de pixel real.
const RESERVADO_BOXES: Dictionary = {
	"ferro_negro": Rect2(0.872396, 0.256836, 0.064453, 0.037109),
	"cristais_arcanos": Rect2(0.872396, 0.434570, 0.064453, 0.037109),
	"essencia_vital": Rect2(0.872396, 0.625977, 0.064453, 0.037109),
}
## Já estava próximo do correto, mas ~11px alto demais — recalibrado
## junto por consistência (mesmo método, mesma varredura de pixel).
const RESERVADO_TOTAL_BOX: Rect2 = Rect2(0.813802, 0.751953, 0.123698, 0.037109)

const BACK_BUTTON: Rect2 = Rect2(0.3548, 0.8789, 0.2962, 0.0635)

var _selected_building: InstitutionalConstructionConfig.Building = InstitutionalConstructionConfig.Building.CAPITAL
var _selected_resource: String = "ferro_negro"
var _quantity_edit: LineEdit

## Confirmação em 2 etapas (pedido explícito, correção pós-validação
## visual): {} = ESTADO NORMAL (os 3 botões de transferência calculam/
## preparam, nunca efetivam). Quando não-vazio = ESTADO DE CONFIRMAÇÃO:
## {"building": InstitutionalConstructionConfig.Building, "amounts":
## {resource: int}} — o preview exato do que "CONFIRMAR TRANSFERÊNCIA"
## vai efetivar. NENHUM estado econômico (Kingdom.raw_resources/
## building_reserved_resources) muda enquanto isto estiver preenchido —
## os valores em "amounts" já são o resultado FINAL de
## get_transferable_amount() (a mesma função pura/sem efeito colateral
## que os 3 botões sempre usaram), só ainda não aplicado. Limpo antes
## de executar a transferência real (guarda contra duplo clique — ver
## _on_confirm_transfer_gui_input()) e ao cancelar.
var _pending_transfer: Dictionary = {}


func _ready() -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()
	refresh()
	print("[WarehouseSupplyChainPanel] Pronto.")


func refresh() -> void:
	_clear_children(self)
	_build_structure()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()


func _build_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.03, 0.03, 0.05)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var aspect := AspectRatioContainer.new()
	aspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.ratio = SUPPLY_CHAIN_IMAGE_ASPECT_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	add_child(aspect)

	var texture_rect := TextureRect.new()
	texture_rect.texture = SUPPLY_CHAIN_TEXTURE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	aspect.add_child(texture_rect)

	_build_building_selector(texture_rect)
	_build_evolution_section(texture_rect)
	_build_resource_section(texture_rect)
	_build_send_resources_section(texture_rect)
	_build_deposito_column(texture_rect)
	_build_reservado_column(texture_rect)
	_build_back_hotspot(texture_rect)


## --- 1. Seleção de Construção (pedido §1) — os 4 cartões já têm ícone
## e nome desenhados na arte; só o hotspot invisível + destaque discreto
## (borda fina) no selecionado são adicionados. Bloqueado durante o
## ESTADO DE CONFIRMAÇÃO (pedido: não trocar de contexto com uma
## transferência pendente). ---
func _build_building_selector(parent: Control) -> void:
	for building: InstitutionalConstructionConfig.Building in ELIGIBLE_BUILDINGS:
		var rect: Rect2 = BUILDING_CARD_RECTS[building]
		var hotspot := _make_hotspot(rect)
		if _pending_transfer.is_empty():
			hotspot.gui_input.connect(_on_building_card_gui_input.bind(building), CONNECT_DEFERRED)
		else:
			hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(hotspot)

		if building == _selected_building:
			hotspot.add_child(_make_selection_border())


func _on_building_card_gui_input(event: InputEvent, building: InstitutionalConstructionConfig.Building) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_building = building
		refresh()


## --- 2/3. Próxima Evolução + Descrição (pedido §2/§3/§4) ---
## Durante o ESTADO DE CONFIRMAÇÃO, a caixa de Descrição é reaproveitada
## pra mostrar o PREVIEW da transferência pendente (pedido explícito
## "PREVIEW" — nenhuma área nova desenhada; a Descrição já é o único
## espaço de texto livre grande o bastante nesta arte).
func _build_evolution_section(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var current_level: int = InstitutionalConstructionResolver.get_current_level(kingdom, _selected_building)

	_value_label(parent, CURRENT_LEVEL_BOX, str(current_level), 16, HUD_TEXT_COLOR, false)
	_value_label(parent, NEXT_LEVEL_BOX, str(current_level + 1), 16, HUD_TEXT_COLOR, false)

	if _pending_transfer.is_empty():
		var description: String = BUILDING_DESCRIPTIONS.get(_selected_building, "")
		_value_label(parent, DESCRIPTION_BOX, description, 12, HUD_TEXT_COLOR, true, VERTICAL_ALIGNMENT_TOP)
	else:
		_value_label(parent, DESCRIPTION_BOX, _pending_transfer_preview_text(), 9, HUD_ACCENT_SELECTED, true, VERTICAL_ALIGNMENT_TOP)


## Preview PURO (só leitura do estado atual + aritmética de exibição —
## nenhuma chamada ao resolver, nenhum valor inventado): "amounts" já é
## o resultado final de get_transferable_amount(), calculado no momento
## em que o jogador clicou em Transferir Quantidade/Tudo/Completar
## Falta (ver _prepare_transfer()). Antes/depois aqui são exatamente o
## que CONFIRMAR TRANSFERÊNCIA vai produzir, nunca um valor recalculado
## de outra forma.
func _pending_transfer_preview_text() -> String:
	var building: InstitutionalConstructionConfig.Building = _pending_transfer["building"]
	var amounts: Dictionary = _pending_transfer["amounts"]
	var kingdom: Kingdom = KingdomState.kingdom
	var key: String = InstitutionalConstructionResolver.building_key(building)

	var lines: Array[String] = ["TRANSFERÊNCIA PENDENTE", BUILDING_LABELS.get(building, "")]
	for resource: String in amounts:
		var amount: int = amounts[resource]
		var deposit_before: int = kingdom.get_raw_resource(resource)
		var deposit_after: int = deposit_before - amount
		var reserved_before: int = kingdom.get_building_reserved(key, resource)
		var reserved_after: int = reserved_before + amount
		lines.append("%s: %d | Dep %d→%d | %s %d→%d" % [
			RAW_RESOURCE_LABELS.get(resource, resource), amount,
			deposit_before, deposit_after,
			BUILDING_LABELS.get(building, ""), reserved_before, reserved_after
		])
	return "\n".join(lines)


## --- 5. Recursos Necessários (pedido §5) ---
func _build_resource_section(parent: Control) -> void:
	var reqs: Dictionary = _get_building_requirements(_selected_building)
	var kingdom: Kingdom = KingdomState.kingdom

	for resource: String in RAW_RESOURCES:
		var boxes: Dictionary = RESOURCE_ROW_BOXES[resource]
		var hotspot := _make_hotspot(boxes["card"])
		if _pending_transfer.is_empty():
			hotspot.gui_input.connect(_on_resource_card_gui_input.bind(resource), CONNECT_DEFERRED)
		else:
			hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(hotspot)
		if resource == _selected_resource:
			hotspot.add_child(_make_selection_border())

		if not reqs.has(resource):
			# Construção não consome este Recurso (ex.: Capital nunca
			# usa um 4º Recurso) — caixas ficam vazias, nunca "0"
			# fabricado onde a construção simplesmente não usa o
			# Recurso. Mas as 4 construções elegíveis usam os 3
			# Recursos (Capital 33/33/33; as demais 70/30 entre dois +
			# a fórmula ainda cobre o 3º com 0) — na prática sempre
			# presente, este ramo é só uma salvaguarda.
			continue

		var req: Dictionary = reqs[resource]
		_value_label(parent, boxes["necessario"], str(req["required"]), 12, HUD_TEXT_COLOR, false)
		_value_label(parent, boxes["ja_possui"], str(req["reserved"]), 12, HUD_TEXT_COLOR, false)
		_value_label(parent, boxes["falta"], str(req["missing"]), 12, HUD_TEXT_COLOR, false)
		_value_label(parent, boxes["disponivel"], str(kingdom.get_raw_resource(resource)), 12, HUD_TEXT_COLOR, false)


func _on_resource_card_gui_input(event: InputEvent, resource: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_resource = resource
		refresh()


## --- 8/9/10. Enviar Recursos (pedido §8/§9/§10) ---
## CORRIGIDO (pedido explícito, "confirmação em duas etapas"): os 3
## botões NUNCA mais efetivam a transferência no clique — eles só
## calculam a quantidade (usando exatamente as mesmas funções puras de
## sempre, _get_transferable_amount()) e chamam _prepare_transfer(),
## que entra em ESTADO DE CONFIRMAÇÃO (_pending_transfer preenchido).
## Nesse estado, esta função desenha CONFIRMAR/CANCELAR no lugar dos 3
## botões normais (_build_confirmation_buttons()) — nenhuma transferência
## real acontece até _on_confirm_transfer_gui_input().
func _build_send_resources_section(parent: Control) -> void:
	var max_transferable: int = _get_transferable_amount(_selected_building, _selected_resource)
	var pending_amount_for_selected: int = _pending_transfer.get("amounts", {}).get(_selected_resource, 0)

	_quantity_edit = LineEdit.new()
	_quantity_edit.text = str(pending_amount_for_selected) if not _pending_transfer.is_empty() else "0"
	_quantity_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quantity_edit.add_theme_font_override("font", HUD_FONT)
	_quantity_edit.add_theme_font_size_override("font_size", 14)
	_quantity_edit.add_theme_color_override("font_color", HUD_TEXT_COLOR)
	var transparent_style := StyleBoxEmpty.new()
	_quantity_edit.add_theme_stylebox_override("normal", transparent_style)
	_quantity_edit.add_theme_stylebox_override("focus", transparent_style)
	_quantity_edit.editable = max_transferable > 0 and _pending_transfer.is_empty()
	_quantity_edit.text_changed.connect(_on_quantity_text_changed, CONNECT_DEFERRED)
	_anchor_control(_quantity_edit, QUANTITY_INPUT_BOX)
	parent.add_child(_quantity_edit)

	var spin_up := _make_hotspot(QUANTITY_SPIN_UP)
	var spin_down := _make_hotspot(QUANTITY_SPIN_DOWN)
	if _pending_transfer.is_empty():
		spin_up.gui_input.connect(_on_quantity_step_gui_input.bind(1), CONNECT_DEFERRED)
		spin_down.gui_input.connect(_on_quantity_step_gui_input.bind(-1), CONNECT_DEFERRED)
	else:
		spin_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spin_down.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spin_up)
	parent.add_child(spin_down)

	_value_label(parent, MAX_ALLOWED_BOX, str(max_transferable), 12, HUD_TEXT_COLOR, false)

	if not _pending_transfer.is_empty():
		_build_confirmation_buttons(parent)
		return

	var transfer_quantity_hotspot := _make_hotspot(TRANSFER_QUANTITY_BUTTON)
	if max_transferable > 0:
		transfer_quantity_hotspot.gui_input.connect(_on_transfer_quantity_gui_input, CONNECT_DEFERRED)
	else:
		transfer_quantity_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(transfer_quantity_hotspot)

	var reqs: Dictionary = _get_building_requirements(_selected_building)
	var any_missing: bool = false
	for resource: String in reqs:
		if reqs[resource]["missing"] > 0:
			any_missing = true

	var transfer_all_hotspot := _make_hotspot(TRANSFER_ALL_BUTTON)
	if any_missing:
		transfer_all_hotspot.gui_input.connect(_on_transfer_all_gui_input, CONNECT_DEFERRED)
	else:
		transfer_all_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(transfer_all_hotspot)

	var complete_missing_hotspot := _make_hotspot(COMPLETE_MISSING_BUTTON)
	var selected_missing: int = reqs.get(_selected_resource, {}).get("missing", 0)
	if selected_missing > 0:
		complete_missing_hotspot.gui_input.connect(_on_complete_missing_gui_input, CONNECT_DEFERRED)
	else:
		complete_missing_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(complete_missing_hotspot)


## ESTADO DE CONFIRMAÇÃO — reaproveita as MESMAS áreas já desenhadas
## dos 3 botões normais (nenhuma arte nova): CONFIRMAR TRANSFERÊNCIA
## ocupa a união de TRANSFER_QUANTITY_BUTTON+TRANSFER_ALL_BUTTON (ação
## primária, mais larga), CANCELAR ocupa COMPLETE_MISSING_BUTTON.
func _build_confirmation_buttons(parent: Control) -> void:
	var confirm_rect: Rect2 = TRANSFER_QUANTITY_BUTTON.merge(TRANSFER_ALL_BUTTON)
	var confirm_hotspot := _make_hotspot(confirm_rect)
	confirm_hotspot.gui_input.connect(_on_confirm_transfer_gui_input, CONNECT_DEFERRED)
	parent.add_child(confirm_hotspot)
	_value_label(parent, confirm_rect, "CONFIRMAR TRANSFERÊNCIA", 13, HUD_ACCENT_SELECTED, false)

	var cancel_hotspot := _make_hotspot(COMPLETE_MISSING_BUTTON)
	cancel_hotspot.gui_input.connect(_on_cancel_transfer_gui_input, CONNECT_DEFERRED)
	parent.add_child(cancel_hotspot)
	_value_label(parent, COMPLETE_MISSING_BUTTON, "CANCELAR", 13, HUD_TEXT_COLOR, false)


func _on_quantity_text_changed(new_text: String) -> void:
	# Só filtra dígitos — não recalcula/transfere nada aqui (pedido:
	# "Não permitir valores inválidos", nunca lógica econômica na UI).
	var filtered: String = ""
	for c in new_text:
		if c.is_valid_int():
			filtered += c
	if filtered != new_text:
		_quantity_edit.text = filtered
		_quantity_edit.caret_column = filtered.length()


func _on_quantity_step_gui_input(event: InputEvent, delta: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var max_transferable: int = _get_transferable_amount(_selected_building, _selected_resource)
		var current: int = int(_quantity_edit.text) if _quantity_edit.text.is_valid_int() else 0
		var new_value: int = clampi(current + delta, 0, max_transferable)
		_quantity_edit.text = str(new_value)


## --- ETAPA 1 (pedido explícito): estes 3 handlers NUNCA chamam
## _transfer_resource()/_transfer_all_possible()/_complete_missing_resource()
## diretamente — só _get_transferable_amount() (puro, sem efeito
## colateral) pra calcular o preview e preparar a confirmação. ---

func _on_transfer_quantity_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var requested: int = int(_quantity_edit.text) if _quantity_edit.text.is_valid_int() else 0
		var max_transferable: int = _get_transferable_amount(_selected_building, _selected_resource)
		var amount: int = mini(requested, max_transferable)
		if amount > 0:
			_prepare_transfer(_selected_building, {_selected_resource: amount})


func _on_transfer_all_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var reqs: Dictionary = _get_building_requirements(_selected_building)
		var amounts: Dictionary = {}
		for resource: String in reqs:
			var amount: int = _get_transferable_amount(_selected_building, resource)
			if amount > 0:
				amounts[resource] = amount
		if not amounts.is_empty():
			_prepare_transfer(_selected_building, amounts)


func _on_complete_missing_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var amount: int = _get_transferable_amount(_selected_building, _selected_resource)
		if amount > 0:
			_prepare_transfer(_selected_building, {_selected_resource: amount})


## Entra no ESTADO DE CONFIRMAÇÃO — nenhum estado econômico é alterado
## aqui, só a UI (pedido: "Antes da confirmação: NENHUM estado
## econômico pode mudar").
func _prepare_transfer(building: InstitutionalConstructionConfig.Building, amounts: Dictionary) -> void:
	_pending_transfer = {"building": building, "amounts": amounts.duplicate()}
	refresh()


## --- ETAPA 2 (pedido explícito) ---

## Efetiva a transferência preparada — chama SOMENTE _transfer_resource()
## (já existente, nunca duplicada) pra cada Recurso/quantidade já
## calculados na Etapa 1. _pending_transfer é limpo ANTES de chamar o
## resolver (guarda contra duplo clique — pedido "bloquear temporariamente
## novas confirmações": se dois eventos de clique chegassem antes do
## refresh() reconstruir a árvore e remover este hotspot, o segundo
## encontraria _pending_transfer já vazio e sairia sem efeito).
func _on_confirm_transfer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pending_transfer.is_empty():
			return
		var building: InstitutionalConstructionConfig.Building = _pending_transfer["building"]
		var amounts: Dictionary = _pending_transfer["amounts"]
		_pending_transfer = {}
		for resource: String in amounts:
			_transfer_resource(building, resource, amounts[resource])
		refresh()


## Cancelar: só limpa o estado pendente da UI — nenhum recurso, reserva
## ou construção é tocado (pedido explícito "CANCELAR").
func _on_cancel_transfer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_transfer = {}
		refresh()


## --- 6. Depósito (pedido §6) — sempre kingdom-wide, independente da
## construção selecionada. ---
func _build_deposito_column(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var capacity: int = Deposits.storage_capacity(kingdom.deposito_level)

	for resource: String in RAW_RESOURCES:
		var boxes: Dictionary = DEPOSITO_BOXES[resource]
		_value_label(parent, boxes["disponivel"], str(kingdom.get_raw_resource(resource)), 12, HUD_TEXT_COLOR, false)
		_value_label(parent, boxes["capacidade"], str(capacity), 12, HUD_TEXT_COLOR, false)


## --- 7. Reservado em Construções (pedido §7) — soma kingdom-wide das
## 4 construções elegíveis (building_reserved_resources), independente
## da construção selecionada (mesmo escopo global de Kingdom Inventory,
## nunca uma segunda fonte). ---
func _build_reservado_column(parent: Control) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var total_all: int = 0

	for resource: String in RAW_RESOURCES:
		var total_resource: int = _total_reserved(kingdom, resource)
		_value_label(parent, RESERVADO_BOXES[resource], str(total_resource), 12, HUD_TEXT_COLOR, false)
		total_all += total_resource

	_value_label(parent, RESERVADO_TOTAL_BOX, str(total_all), 13, HUD_TEXT_COLOR, false)


func _total_reserved(kingdom: Kingdom, resource: String) -> int:
	var total: int = 0
	for building: InstitutionalConstructionConfig.Building in ELIGIBLE_BUILDINGS:
		var key: String = InstitutionalConstructionResolver.building_key(building)
		total += kingdom.get_building_reserved(key, resource)
	return total


func _build_back_hotspot(parent: Control) -> void:
	var hotspot := _make_hotspot(BACK_BUTTON)
	hotspot.gui_input.connect(_on_back_gui_input, CONNECT_DEFERRED)
	parent.add_child(hotspot)


func _on_back_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file.call_deferred("res://scenes/city/panels/deposito_panel.tscn")


## --- Helpers (pedido explícito — separação entre apresentação e
## lógica econômica; a lógica real vive em SupplyChainResolver, nunca
## duplicada aqui). ---

func _get_building_requirements(building: InstitutionalConstructionConfig.Building) -> Dictionary:
	return SupplyChainResolver.requirements(KingdomState.kingdom, building)


func _get_building_stored_resources(building: InstitutionalConstructionConfig.Building) -> Dictionary:
	var key: String = InstitutionalConstructionResolver.building_key(building)
	var result: Dictionary = {}
	for resource: String in _get_building_requirements(building):
		result[resource] = KingdomState.kingdom.get_building_reserved(key, resource)
	return result


func _get_transferable_amount(building: InstitutionalConstructionConfig.Building, resource: String) -> int:
	return SupplyChainResolver.get_transferable_amount(KingdomState.kingdom, building, resource)


func _transfer_resource(building: InstitutionalConstructionConfig.Building, resource: String, amount: int) -> int:
	return SupplyChainResolver.transfer_resource(KingdomState.kingdom, building, resource, amount)


func _complete_missing_resource(building: InstitutionalConstructionConfig.Building, resource: String) -> int:
	return SupplyChainResolver.complete_missing_resource(KingdomState.kingdom, building, resource)


func _transfer_all_possible(building: InstitutionalConstructionConfig.Building) -> Dictionary:
	return SupplyChainResolver.transfer_all_possible(KingdomState.kingdom, building)


## --- Helpers visuais (duplicados localmente, mesmo padrão de sempre). ---

## Control invisível (sem fundo/borda/texto) sobre `rect` (fração da
## arte) — mesmo padrão de hotspot já usado na Biblioteca/Observatório/
## Depósito, aqui reaproveitado também pros botões já desenhados na
## arte (o visual do botão já existe; só a área de clique é nova).
func _make_hotspot(rect: Rect2) -> Control:
	var hotspot := Control.new()
	_anchor_control(hotspot, rect)
	hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return hotspot


## Destaque de seleção discreto (pedido §1: "sem destruir a composição
## visual") — só uma borda fina, sem fundo, nunca um brilho/aura.
func _make_selection_border() -> Control:
	var highlight := Panel.new()
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = HUD_ACCENT_SELECTED
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	highlight.add_theme_stylebox_override("panel", style)
	return highlight


func _anchor_control(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


## Label de valor dinâmico encaixado numa caixa já desenhada na arte —
## título OFF (caixas de valor nunca têm mais de uma linha curta;
## títulos "quebrando caractere por caractere" era exatamente o bug da
## etapa anterior). Descrição (multiline=true) usa autowrap ON e
## alinhamento no topo, sempre contida na moldura, nunca scrollbar.
func _value_label(parent: Control, rect: Rect2, text: String, font_size: int, color: Color, multiline: bool, valign: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER) -> void:
	var label := Label.new()
	label.text = text
	_anchor_control(label, rect)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = valign
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if multiline else TextServer.AUTOWRAP_OFF
	label.clip_text = not multiline
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", HUD_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
