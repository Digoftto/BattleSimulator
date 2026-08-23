class_name CombatReplayView
extends Control
## CombatReplayView (F-046)
##
## Infraestrutura mínima de apresentação visual do combate (F-044/F-046,
## "Combate Visual"). Representa — nunca decide — o que CombatEngine já
## resolveu: recebe um CombatState FINAL e um CombatReplayCollector
## (attach()ado ao event_bus ANTES de CombatEngine.run(), snapshot_initial_board()
## chamado logo após CombatEngine.initialize()) já preenchidos por quem
## orquestrou a batalha, e percorre replay_events em ordem cronológica,
## num ritmo legível por humano (await entre eventos), atualizando um
## tabuleiro 3x3 por lado (posição, nome da carta, Classe, HP, ESC) e um
## feed textual das ações. CombatEngine roda do jeito que sempre rodou —
## instantâneo, síncrono, sem nenhuma alteração — a "pausa" pertence
## inteiramente a esta camada.
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

var _turn_label: Label
var _log_label: Label
var _result_label: Label
var _continue_button: Button
var _skip_button: Button
var _battlefield_texture_rect: TextureRect

## side*10 + position -> {"card_name", "card_class", "hp", "max_hp", "esc", "max_esc", "alive", "card"}
var _live_board: Dictionary = {}
## side*10 + position -> {"panel", "portrait", "overlay_vbox", "name_label", "class_label", "hp_label", "esc_label"}
var _position_widgets: Dictionary = {}

var _log_lines: Array[String] = []
const MAX_LOG_LINES: int = 8

var _skip_requested: bool = false
var _is_playing: bool = false


func _ready() -> void:
	_build_static_structure()
	_apply_initial_board()
	if not _is_playing:
		_play_replay()


func _build_static_structure() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.08, 0.10)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# ART-001: fundo do Campo de Batalha real da batalha, atrás de tudo
	# (o próprio ColorRect acima continua existindo por baixo — cobre o
	# caso, hoje raro mas possível, de combat_state.battlefield vir nulo
	# ou sem arte integrada ainda, ver BattlefieldArtCatalog). STRETCH_KEEP_ASPECT_COVERED
	# preenche a área sem deformar a imagem original (corta o excesso,
	# nunca estica). A UI do replay continua inteira por cima
	# (root_vbox abaixo é adicionado DEPOIS, então desenha na frente).
	_battlefield_texture_rect = TextureRect.new()
	_battlefield_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_battlefield_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_battlefield_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_battlefield_texture_rect.texture = preload("res://engine/presentation/battlefield_art_catalog.gd").texture_for(combat_state.battlefield if combat_state != null else null)
	_battlefield_texture_rect.visible = _battlefield_texture_rect.texture != null
	add_child(_battlefield_texture_rect)

	# Painel semi-transparente entre o Battlefield e o conteúdo — sem
	# isso, o texto/tabuleiro perderia legibilidade sobre uma imagem de
	# fundo cheia de detalhe (restrição explícita de ART-001 §1: a arte
	# nunca pode prejudicar a leitura das unidades).
	var content_backing := ColorRect.new()
	content_backing.color = Color(0.06, 0.06, 0.08, 0.72)
	content_backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_backing.visible = _battlefield_texture_rect.visible
	add_child(content_backing)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	var title := Label.new()
	title.text = "Combate"
	title.add_theme_font_size_override("font_size", 22)
	root_vbox.add_child(title)

	_turn_label = Label.new()
	_turn_label.text = "Turno 1"
	root_vbox.add_child(_turn_label)

	var boards_hbox := HBoxContainer.new()
	boards_hbox.add_theme_constant_override("separation", 24)
	root_vbox.add_child(boards_hbox)

	boards_hbox.add_child(_build_side_board(0, "Seu Exército" if player_side == 0 else "Inimigo"))
	boards_hbox.add_child(_build_side_board(1, "Inimigo" if player_side == 0 else "Seu Exército"))

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_label.custom_minimum_size = Vector2(0, 140)
	root_vbox.add_child(_log_label)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 20)
	_result_label.visible = false
	root_vbox.add_child(_result_label)

	var buttons_hbox := HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(buttons_hbox)

	_skip_button = Button.new()
	_skip_button.text = "Pular"
	_skip_button.pressed.connect(_on_skip_pressed, CONNECT_DEFERRED)
	buttons_hbox.add_child(_skip_button)

	_continue_button = Button.new()
	_continue_button.text = "Continuar"
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed, CONNECT_DEFERRED)
	buttons_hbox.add_child(_continue_button)


func _build_side_board(side: int, side_title: String) -> Control:
	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 6)

	var side_label := Label.new()
	side_label.text = side_title
	side_vbox.add_child(side_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	side_vbox.add_child(grid)

	for line: Array in [CombatBoard.LINE_1, CombatBoard.LINE_2, CombatBoard.LINE_3]:
		for position: int in line:
			grid.add_child(_build_position_widget(side, position))

	return side_vbox


## ART-001: o retrato da carta agora é a representação PRINCIPAL da
## posição (texto vira apoio, nunca a informação primária) — painel
## maior (~0,72:1, perto da proporção real dos retratos integrados,
## ver CardArtCatalog) com o TextureRect preenchendo tudo por baixo
## (STRETCH_KEEP_ASPECT_COVERED corta o excesso em vez de deformar) e
## uma faixa semi-transparente ancorada embaixo com
## Posição/Nome/Classe/HP/ESC — sempre legível por cima de qualquer
## arte, nunca clipada.
func _build_position_widget(side: int, position: int) -> Control:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(118, 164)
	panel.clip_contents = true

	var background := ColorRect.new()
	background.color = Color(0.18, 0.18, 0.22)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)

	var portrait := TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel.add_child(portrait)

	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.04, 0.05, 0.78)
	overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	overlay.offset_top = -62
	panel.add_child(overlay)

	var overlay_vbox := VBoxContainer.new()
	overlay_vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	overlay_vbox.offset_top = -62
	overlay_vbox.offset_left = 4
	overlay_vbox.offset_right = -4
	overlay_vbox.add_theme_constant_override("separation", 0)
	panel.add_child(overlay_vbox)

	var position_label := Label.new()
	position_label.text = "Posição %d" % position
	position_label.add_theme_font_size_override("font_size", 10)
	overlay_vbox.add_child(position_label)

	var name_label := Label.new()
	name_label.text = "(vazio)"
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.clip_text = true
	overlay_vbox.add_child(name_label)

	var class_label := Label.new()
	class_label.add_theme_font_size_override("font_size", 10)
	overlay_vbox.add_child(class_label)

	var hp_label := Label.new()
	hp_label.add_theme_font_size_override("font_size", 11)
	overlay_vbox.add_child(hp_label)

	var esc_label := Label.new()
	esc_label.add_theme_font_size_override("font_size", 11)
	overlay_vbox.add_child(esc_label)

	_position_widgets[side * 10 + position] = {
		"panel": background,
		"portrait": portrait,
		"name_label": name_label,
		"class_label": class_label,
		"hp_label": hp_label,
		"esc_label": esc_label,
	}
	return panel


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
		}
		_refresh_position_widget(key)


func _refresh_position_widget(key: int) -> void:
	if not _position_widgets.has(key):
		return
	var widgets: Dictionary = _position_widgets[key]
	if not _live_board.has(key):
		widgets["name_label"].text = "(vazio)"
		widgets["class_label"].text = ""
		widgets["hp_label"].text = ""
		widgets["esc_label"].text = ""
		widgets["panel"].color = Color(0.18, 0.18, 0.22)
		widgets["portrait"].texture = null
		widgets["portrait"].modulate = Color.WHITE
		return

	var unit: Dictionary = _live_board[key]
	widgets["name_label"].text = unit["card_name"]
	widgets["class_label"].text = unit["card_class"]
	widgets["hp_label"].text = "HP: %d/%d" % [unit["hp"], unit["max_hp"]]
	widgets["esc_label"].text = "ESC: %d/%d" % [unit["esc"], unit["max_esc"]]
	widgets["panel"].color = Color(0.18, 0.18, 0.22) if unit["alive"] else Color(0.30, 0.10, 0.10)

	# ART-001: o retrato só precisa ser CARREGADO uma vez por unidade
	# (nunca muda enquanto ela existir) — recarregar a cada refresh
	# (chamado a cada ataque/cura) seria desperdício. "morte/remoção
	# visual" (ART-001 §5) usa modulate escurecido sobre o mesmo
	# retrato, nunca troca de imagem nem o remove — a carta morta
	# continua identificável, só visivelmente fora de combate.
	if widgets["portrait"].texture == null and unit.get("card") != null:
		widgets["portrait"].texture = preload("res://engine/presentation/card_art_catalog.gd").texture_for(unit["card"])
	widgets["portrait"].modulate = Color.WHITE if unit["alive"] else Color(0.42, 0.30, 0.30)


func _append_log(line: String) -> void:
	_log_lines.append(line)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)
	_log_label.text = "\n".join(_log_lines)


func _on_skip_pressed() -> void:
	_skip_requested = true


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


func _apply_move_event(event: Dictionary) -> void:
	var side: int = event["side"]
	var to_key: int = side * 10 + event["to_position"]
	var from_key: int = -1
	for key: int in _live_board.keys():
		if key / 10 == side and _live_board[key]["card_name"] == event["card_name"] and key != to_key:
			from_key = key
			break

	if from_key != -1:
		_live_board[to_key] = _live_board[from_key]
		_live_board.erase(from_key)
		_refresh_position_widget(from_key)
		_refresh_position_widget(to_key)
	_append_log("Turno %d: %s avança para a Posição %d." % [event["turn"], event["card_name"], event["to_position"]])


func _apply_attack_event(event: Dictionary) -> void:
	var target_key: int = event["target_side"] * 10 + event["target_position"]
	if _live_board.has(target_key):
		_live_board[target_key]["hp"] = event["target_hp_after"]
		_live_board[target_key]["esc"] = event["target_esc_after"]
		_refresh_position_widget(target_key)
	_append_log("Turno %d: %s ataca %s — %d de dano (ESC absorveu %d)." % [
		event["turn"], event["attacker_card_name"], event["target_card_name"],
		event["damage_dealt"], event["damage_absorbed_by_shield"]
	])


func _apply_heal_event(event: Dictionary) -> void:
	var target_key: int = event["target_side"] * 10 + event["target_position"]
	if _live_board.has(target_key):
		_live_board[target_key]["hp"] = event["target_hp_after"]
		_refresh_position_widget(target_key)
	_append_log("Turno %d: %s cura %s em %d." % [event["turn"], event["healer_card_name"], event["target_card_name"], event["heal_amount"]])


func _apply_death_event(event: Dictionary) -> void:
	var key: int = event["side"] * 10 + event["position"]
	if _live_board.has(key):
		_live_board[key]["alive"] = false
		_live_board[key]["hp"] = 0
		_refresh_position_widget(key)
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
