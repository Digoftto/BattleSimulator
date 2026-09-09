class_name BattleUnitArtLayer
extends Control
## BattleUnitArtLayer (Battle Art MVP — Piloto, 2026-09-02)
##
## Camada visual ADITIVA de Battle Art — decisão de arquitetura desta
## tarefa (opção C do relatório: componente visual separado, nunca
## substituindo BattleCardView). Para qualquer card_name SEM Battle Art
## registrada em BattleUnitArtCatalog, esta camada não cria nada —
## BattleCardView continua sendo 100% da representação visual dessa
## unidade, exatamente como antes desta tarefa (nenhuma migração em
## massa, só o piloto).
##
## Identidade EXCLUSIVAMENTE por unit_id (CombatUnit.get_instance_id(),
## mesma correção de replay visual da tarefa anterior) — nunca por
## card_name, mesmo quando duas unidades compartilham o Nome (ver
## _test_two_units_same_card_name_are_independent em
## test_battle_unit_art_pilot.gd).
##
## Quem instancia (CombatReplayView) insere esta camada como filho de
## "battlefield_aspect" ANTES de "_board_layer" — desenha ATRÁS da carta
## compacta de cada posição, nunca por cima, pra não alterar a leitura
## visual já aprovada do Battlefield em produção.

## preload() em vez dos identificadores globais "BattleUnitArtCatalog"/
## "BattleUnitArtGeometry" — mesmo motivo já documentado em vários
## lugares do projeto (ex: combat_replay_view.gd, combat_replay_collector.gd):
## class_name novo nesta sessão, cache global de classes do Godot só é
## regenerado por uma varredura do Editor, que nunca roda numa execução
## --headless.
const ArtCatalog = preload("res://engine/presentation/battle_unit_art_catalog.gd")
const ArtGeometry = preload("res://engine/presentation/battle_unit_art_geometry.gd")

## unit_id -> {"sprite": TextureRect, "y": float (fração vertical do
## centro do slot, usada só pra reordenar profundidade)}
var _units: Dictionary = {}

## FASE 7 (2026-09-04) — MOVIMENTAÇÃO: diagnóstico desta tarefa
## encontrou a causa real da "imprecisão" reportada (nunca a lógica de
## CombatEngine/CombatBoard, que já é simétrica e correta pros 2 lados,
## nem a geometria de BattleUnitArtGeometry, que é um lookup direto por
## side/position sem ambiguidade): register_or_update() reposicionava o
## sprite INSTANTANEAMENTE (salto rígido) a cada passo de um avanço
## multi-passo (9->8->7->...), sem nenhuma interpolação — o mesmo evento
## real, sem nenhuma mudança de posição, mas agora com um "glide" visual
## entre a posição antiga e a nova. Efeito mais perceptível no Lado do
## Inimigo por causa da escala menor (Side 1 = 0.10 contra Side 0 =
## 0.14): o mesmo salto de célula cobre uma fração MAIOR do próprio
## tamanho do sprite, lendo como "teleporte" em vez de "passo".
##
## "animate_movement" (default false) é o mesmo padrão já usado por
## CombatReplayView.DELAY_BETWEEN_EVENTS_SECONDS (testes automatizados
## zeram/nunca ligam esse tipo de flag pra reproduzir eventos
## instantaneamente, sem depender de tempo real de parede/frames de
## SceneTree): esta camada nunca chama _ready() sozinha durante os
## testes existentes (eles chamam _build_static_structure() direto, sem
## entrar na árvore) — só CombatReplayView._ready() (caminho real de
## jogo, nunca exercitado pelos testes síncronos) liga animate_movement
## e sincroniza move_animation_duration_seconds com o ritmo de
## reprodução. Isso preserva 100% das asserções de posição já existentes
## (elas checam anchors imediatamente após _apply_replay_event(), sem
## await — um Tween em andamento nunca teria avançado nenhum frame nesse
## cenário) sem exigir editar nenhum arquivo de teste.
var animate_movement: bool = false
var move_animation_duration_seconds: float = 0.35

const _ATTACK_FLASH_COLOR: Color = Color(1.0, 0.95, 0.6, 1.0)
const _DAMAGE_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3, 1.0)
const _HEAL_FLASH_COLOR: Color = Color(0.55, 1.0, 0.6, 1.0)
const _RANGED_PROJECTILE_COLOR: Color = Color(1.0, 0.85, 0.35, 0.95)
const _MAGIC_PROJECTILE_COLOR: Color = Color(0.55, 0.65, 1.0, 0.95)
const _HEAL_BEAM_COLOR: Color = Color(0.45, 1.0, 0.65, 0.9)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Cria (1a vez) ou reposiciona (unidade já existente) o sprite de
## Battle Art da unidade "unit_id" — não faz nada se card_name não tiver
## Battle Art registrada (ver BattleUnitArtCatalog.has_art_for()).
## "side"/"position" são a posição LÓGICA real (CombatBoard) — a
## resolução de CELL_CENTER/FOOT_CENTER/escala é responsabilidade
## exclusiva de BattleUnitArtGeometry (Teste Visual 08: esta camada
## nunca guarda nem deriva geometria própria, só chama
## ArtGeometry.placement_for() com o que CombatReplayView já sabe de
## verdade — identidade/eventos/side/position).
func register_or_update(unit_id: int, side: int, position: int, card_name: String, orientation: String = "FRONT") -> void:
	if not ArtCatalog.has_art_for(card_name):
		return

	var texture: Texture2D = ArtCatalog.cropped_texture_for(card_name, orientation)
	if texture == null:
		return

	var sprite: TextureRect
	var is_new: bool = not _units.has(unit_id)
	if not is_new:
		sprite = _units[unit_id]["sprite"]
	else:
		sprite = TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sprite.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(sprite)

	sprite.texture = texture
	var content_size: Vector2 = texture.get_size()
	var placement: Dictionary = ArtGeometry.placement_for(side, position, card_name, content_size.x, content_size.y)

	# FASE 7: só anima quando é de fato um reposicionamento (sprite já
	# existia — primeira colocação continua instantânea, nunca "desliza
	# a partir do nada") E animate_movement está ligado (produção real,
	# nunca os testes síncronos existentes — ver comentário acima).
	var is_reposition: bool = not is_new and (
		not is_equal_approx(sprite.anchor_left, placement["anchor_left"]) or
		not is_equal_approx(sprite.anchor_right, placement["anchor_right"]) or
		not is_equal_approx(sprite.anchor_top, placement["anchor_top"]) or
		not is_equal_approx(sprite.anchor_bottom, placement["anchor_bottom"])
	)

	if is_reposition and animate_movement and move_animation_duration_seconds > 0.0:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "anchor_left", placement["anchor_left"], move_animation_duration_seconds)
		tween.parallel().tween_property(sprite, "anchor_right", placement["anchor_right"], move_animation_duration_seconds)
		tween.parallel().tween_property(sprite, "anchor_top", placement["anchor_top"], move_animation_duration_seconds)
		tween.parallel().tween_property(sprite, "anchor_bottom", placement["anchor_bottom"], move_animation_duration_seconds)
	else:
		sprite.anchor_left = placement["anchor_left"]
		sprite.anchor_right = placement["anchor_right"]
		sprite.anchor_top = placement["anchor_top"]
		sprite.anchor_bottom = placement["anchor_bottom"]

	sprite.offset_left = 0.0
	sprite.offset_right = 0.0
	sprite.offset_top = 0.0
	sprite.offset_bottom = 0.0

	_units[unit_id] = {"sprite": sprite, "y": ArtGeometry.cell_center_frac(side, position).y}
	_resort_z_order()


## Centro na tela (fração 0..1 do próprio _unit_art_layer, mesmo espaço
## de ArtGeometry.cell_center_frac()) do sprite ATUAL de "unit_id" — usado
## só pelos efeitos de projétil/feixe abaixo, nunca por
## register_or_update() (que sempre lê a posição de ArtGeometry
## diretamente, nunca deriva nada daqui).
func _sprite_center_frac(sprite: TextureRect) -> Vector2:
	return Vector2(
		(sprite.anchor_left + sprite.anchor_right) / 2.0,
		(sprite.anchor_top + sprite.anchor_bottom) / 2.0,
	)


## ---- FASE 7 — feedback visual de ataque/dano/cura/morte ----
## Sempre por unit_id (nunca card_name) — quem chama (CombatReplayView)
## resolve a identidade real a partir do evento/_live_board, esta camada
## só aplica o efeito ao sprite já registrado. Puramente cosmético:
## nenhuma destas funções altera _units/unit_count() ou atrasa
## remove_unit() — a garantia "sem fantasma" já validada continua
## exclusivamente sobre esse dicionário.

## Pulso de cor breve — "esta unidade agiu" (ataque corpo a corpo, à
## distância ou mágico; a diferenciação por tipo de ataque é o projétil
## abaixo, chamado à parte por quem sabe a Classe da carta). Nunca cria
## nó novo (só tween de "modulate" do sprite já existente) — seguro
## mesmo fora do modo de animação, por isso não é bloqueado por
## animate_movement.
func flash_attack(unit_id: int) -> void:
	_flash(unit_id, _ATTACK_FLASH_COLOR)


## Flash vermelho + pequeno "kick" — feedback de dano recebido.
func flash_damage(unit_id: int) -> void:
	_flash(unit_id, _DAMAGE_FLASH_COLOR)
	_kick(unit_id)


## Flash verde — "esta unidade foi curada" (efeito de chegada, além do
## feixe direcional de spawn_heal_beam()).
func flash_heal(unit_id: int) -> void:
	_flash(unit_id, _HEAL_FLASH_COLOR)


func _flash(unit_id: int, color: Color) -> void:
	if not _units.has(unit_id):
		return
	var sprite: TextureRect = _units[unit_id]["sprite"]
	var base_tint: Color = sprite.modulate
	sprite.modulate = color
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", base_tint, 0.25)


## Pequeno deslocamento horizontal de ida-e-volta (nunca muda a
## dimensão do sprite, só offset_left/right em conjunto) — reação curta
## ao receber dano. register_or_update() já reseta offset_*=0.0 a cada
## atualização, então um "kick" interrompido por um movimento
## subsequente nunca deixa resíduo.
func _kick(unit_id: int) -> void:
	if not _units.has(unit_id):
		return
	var sprite: TextureRect = _units[unit_id]["sprite"]
	var kick_px: float = 5.0
	var tween := create_tween()
	tween.tween_property(sprite, "offset_left", kick_px, 0.045)
	tween.parallel().tween_property(sprite, "offset_right", kick_px, 0.045)
	tween.tween_property(sprite, "offset_left", 0.0, 0.13)
	tween.parallel().tween_property(sprite, "offset_right", 0.0, 0.13)


## Efeito de projétil (ataque À Distância/Mago) — um pequeno ponto que
## viaja da posição atual do atacante até a do alvo, na cor pedida por
## quem chama (CombatReplayView decide a cor pela Classe da carta — ver
## _RANGED_PROJECTILE_COLOR/_MAGIC_PROJECTILE_COLOR). Nó TEMPORÁRIO e
## independente, nunca registrado em _units — bloqueado por
## animate_movement (cria um filho novo, só seguro fora dos testes
## síncronos existentes, que sempre checam get_child_count() com
## animate_movement=false).
func spawn_projectile(from_unit_id: int, to_unit_id: int, color: Color, duration: float = 0.26) -> void:
	if not animate_movement:
		return
	if not _units.has(from_unit_id) or not _units.has(to_unit_id):
		return
	_spawn_traveling_dot(_sprite_center_frac(_units[from_unit_id]["sprite"]), _sprite_center_frac(_units[to_unit_id]["sprite"]), color, duration, 8.0)


## Wrappers com a cor certa já embutida — quem chama (CombatReplayView)
## só precisa saber a Classe da carta, nunca a paleta interna desta
## camada.
func spawn_ranged_projectile(from_unit_id: int, to_unit_id: int) -> void:
	spawn_projectile(from_unit_id, to_unit_id, _RANGED_PROJECTILE_COLOR)


func spawn_magic_projectile(from_unit_id: int, to_unit_id: int) -> void:
	spawn_projectile(from_unit_id, to_unit_id, _MAGIC_PROJECTILE_COLOR)


## Feixe de cura FONTE -> ALVO — 3 pontos pequenos em sucessão rápida
## (trilha de energia direcional, cor distinta do projétil de ataque),
## deixando claro visualmente quem cura quem. Mesma restrição de
## animate_movement do projétil de ataque (cria nós novos).
func spawn_heal_beam(from_unit_id: int, to_unit_id: int, duration: float = 0.32) -> void:
	if not animate_movement:
		return
	if not _units.has(from_unit_id) or not _units.has(to_unit_id):
		return
	var from_frac: Vector2 = _sprite_center_frac(_units[from_unit_id]["sprite"])
	var to_frac: Vector2 = _sprite_center_frac(_units[to_unit_id]["sprite"])
	# FASE 7: atraso via Tween (tween_interval/tween_callback), NUNCA
	# get_tree().create_timer() — esta camada pode ser chamada antes de
	# estar de fato dentro de uma SceneTree viva (ex: cenário de teste
	# síncrono que liga animate_movement manualmente pra inspecionar o
	# efeito, sem nunca dar add_child() na view dentro da árvore real),
	# e get_tree() retorna null nesse caso (SCRIPT ERROR: "Cannot call
	# method 'create_timer' on a null value" — encontrado exatamente por
	# um teste desta tarefa). create_tween() não tem essa mesma
	# exigência.
	for i in range(3):
		var delay: float = i * 0.07
		if delay <= 0.0:
			_spawn_traveling_dot(from_frac, to_frac, _HEAL_BEAM_COLOR, duration, 7.0)
		else:
			var delay_tween := create_tween()
			delay_tween.tween_interval(delay)
			delay_tween.tween_callback(_spawn_traveling_dot.bind(from_frac, to_frac, _HEAL_BEAM_COLOR, duration, 7.0))


func _spawn_traveling_dot(from_frac: Vector2, to_frac: Vector2, color: Color, duration: float, size_px: float) -> void:
	var dot := ColorRect.new()
	dot.color = color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)
	move_child(dot, get_child_count() - 1)

	dot.anchor_left = from_frac.x
	dot.anchor_right = from_frac.x
	dot.anchor_top = from_frac.y
	dot.anchor_bottom = from_frac.y
	var half: float = size_px / 2.0
	dot.offset_left = -half
	dot.offset_right = half
	dot.offset_top = -half
	dot.offset_bottom = half

	var tween := create_tween()
	tween.tween_property(dot, "anchor_left", to_frac.x, duration)
	tween.parallel().tween_property(dot, "anchor_right", to_frac.x, duration)
	tween.parallel().tween_property(dot, "anchor_top", to_frac.y, duration)
	tween.parallel().tween_property(dot, "anchor_bottom", to_frac.y, duration)
	tween.tween_callback(dot.queue_free)


## Efeito cosmético de morte — duplica a aparência atual do sprite (
## textura + retângulo de tela) num nó TEMPORÁRIO e independente, que
## escurece/desvanece e se libera sozinho. NUNCA atrasa remove_unit()
## nem altera _units/unit_count() — a remoção real (chamada
## separadamente por quem orquestra, ver CombatReplayView) continua
## instantânea, mesma garantia "sem fantasma" de sempre. Bloqueado por
## animate_movement pelo mesmo motivo dos projéteis (cria um filho
## novo).
func spawn_death_fade(unit_id: int, duration: float = 0.3) -> void:
	if not animate_movement:
		return
	if not _units.has(unit_id):
		return
	var sprite: TextureRect = _units[unit_id]["sprite"]
	var fading := TextureRect.new()
	fading.texture = sprite.texture
	fading.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fading.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	fading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fading.anchor_left = sprite.anchor_left
	fading.anchor_right = sprite.anchor_right
	fading.anchor_top = sprite.anchor_top
	fading.anchor_bottom = sprite.anchor_bottom
	fading.modulate = Color(0.45, 0.12, 0.12, 1.0)
	add_child(fading)
	move_child(fading, get_child_count() - 1)

	var tween := create_tween()
	tween.tween_property(fading, "modulate:a", 0.0, duration)
	tween.tween_callback(fading.queue_free)


## Remove visualmente a unidade "unit_id" (morte) — nenhum sprite
## fantasma permanece (mesmo princípio da correção de
## CombatReplayView._apply_death_event(): remover, nunca só esconder/
## escurecer). Não faz nada se a unidade nunca teve Battle Art (ex:
## nenhuma das outras 39 Cartas nesta etapa).
func remove_unit(unit_id: int) -> void:
	if not _units.has(unit_id):
		return
	var sprite: TextureRect = _units[unit_id]["sprite"]
	_units.erase(unit_id)
	remove_child(sprite)
	sprite.queue_free()


func has_unit(unit_id: int) -> bool:
	return _units.has(unit_id)


func sprite_for(unit_id: int) -> TextureRect:
	return _units[unit_id]["sprite"] if _units.has(unit_id) else null


func unit_count() -> int:
	return _units.size()


## Profundidade visual: quem está mais perto da câmera (maior fração y
## de centro do slot) desenha por cima — mesma técnica já usada em
## produção por CombatReplayView._build_all_position_widgets() para as
## 18 cartas (sort by y + ordem de inserção), nunca z_index bruto (a
## posição lógica não equivale à profundidade visual — ver seção 15 do
## pedido desta tarefa).
func _resort_z_order() -> void:
	var entries: Array = []
	for unit_id: int in _units.keys():
		entries.append({"unit_id": unit_id, "y": _units[unit_id]["y"]})
	entries.sort_custom(func(a, b): return a["y"] < b["y"])
	for entry: Dictionary in entries:
		move_child(_units[entry["unit_id"]]["sprite"], get_child_count() - 1)
