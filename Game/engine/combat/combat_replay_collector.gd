class_name CombatReplayCollector
extends RefCounted
## CombatReplayCollector (F-046)
##
## Infraestrutura mínima de apresentação visual do combate (F-044/F-046,
## "Combate Visual"): assinante OPCIONAL do CombatEventBus de uma
## batalha, no mesmo padrão de BattleEventCollector (F-028) — transforma
## os eventos já publicados por CombatEngine em dados estruturados, sem
## que CombatEngine precise saber que este coletor existe. CombatEngine
## nunca é modificado, nunca é reescrito, nenhuma regra de combate é
## alterada — este arquivo só OUVE o que já é publicado.
##
## Diferente de BattleEventCollector (que serve a relatórios estatísticos
## agregados), este coletor preserva a ORDEM CRONOLÓGICA COMPLETA de
## tudo que aconteceu (movimento, ataque, cura, morte, limites de turno)
## num único "replay_events" — o formato que uma camada visual (ver
## CombatReplayView) percorre passo a passo pra reconstruir a batalha em
## ritmo humano, mesmo CombatEngine.run() resolvendo tudo instantaneamente
## e de uma vez (CombatEngine nunca "pausa" — a pausa/ritmo pertence
## inteiramente à camada visual, nunca ao motor).
##
## RefCounted puro — sem Node, sem cena, sem UI. Seguro mesmo fora de um
## contexto visual: nenhum listener é registrado no CombatEventBus (e
## portanto nenhum custo é pago) quando nenhum CombatReplayCollector é
## criado, exatamente como BattleEventCollector.

## Cada item: {"kind": String, "turn": int, ...campos específicos do tipo}.
## "kind" ∈ {"move", "attack", "heal", "death", "turn_start", "turn_end"}.
var replay_events: Array[Dictionary] = []

## Snapshot do tabuleiro completo ANTES do 1º turno — capturado por
## quem chama snapshot_initial_board(state), logo após
## CombatEngine.initialize() e ANTES de CombatEngine.run() (mesmo
## ponto já usado por test_army_editor_formation_flow.gd pra ler a
## Formação inicial real). Cada item: {"side", "position", "card_name",
## "card_class", "hp", "max_hp", "esc", "max_esc"}.
var initial_board: Array[Dictionary] = []


func attach(event_bus: CombatEventBus) -> void:
	event_bus.subscribe(CombatEventType.Type.TURN_START, _on_turn_start)
	event_bus.subscribe(CombatEventType.Type.TURN_END, _on_turn_end)
	event_bus.subscribe(CombatEventType.Type.UNIT_MOVED, _on_unit_moved)
	event_bus.subscribe(CombatEventType.Type.AFTER_ATTACK, _on_after_attack)
	event_bus.subscribe(CombatEventType.Type.AFTER_HEAL_PERFORMED, _on_after_heal)
	event_bus.subscribe(CombatEventType.Type.UNIT_DIED, _on_unit_died)


## Chamado UMA VEZ por quem orquestra a batalha, logo após
## CombatEngine.initialize() (nunca depois de run() — nesse ponto a
## Formação já pode ter Pelotões mortos/movidos, deixando de refletir o
## estado inicial real).
func snapshot_initial_board(state: CombatState) -> void:
	initial_board.clear()
	for unit: CombatUnit in state.units:
		initial_board.append({
			"side": unit.side,
			"position": unit.position,
			"card_name": unit.card.card_name,
			"card_class": unit.card.card_class,
			"hp": unit.current_hp,
			"max_hp": unit.card.hp,
			"esc": unit.current_esc,
			"max_esc": unit.card.esc,
		})


func _on_turn_start(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	replay_events.append({"kind": "turn_start", "turn": context.turn})


func _on_turn_end(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	replay_events.append({"kind": "turn_end", "turn": context.turn})


## CombatContext não carrega a posição de ORIGEM do movimento (só
## CombatEngine._movement_phase() sabe disso, numa variável de loop
## local que nunca é publicada) — "unit.position" já foi escrito para o
## valor NOVO antes deste evento disparar. CombatReplayView reconstrói
## a posição anterior sozinha (mantém o tabuleiro completo em memória
## enquanto percorre replay_events em ordem), então só a posição de
## destino precisa ser registrada aqui.
func _on_unit_moved(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker == null:
		return
	replay_events.append({
		"kind": "move",
		"turn": context.turn,
		"side": context.attacker.side,
		"card_name": context.attacker.card.card_name if context.attacker.card != null else "",
		"to_position": context.attacker.position,
	})


func _on_after_attack(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker == null:
		return
	replay_events.append({
		"kind": "attack",
		"turn": context.turn,
		"side": context.side,
		"attacker_card_name": context.attacker.card.card_name if context.attacker.card != null else "",
		"attacker_position": context.attacker.position,
		"target_card_name": context.target.card.card_name if context.target != null and context.target.card != null else "",
		"target_position": context.target.position if context.target != null else -1,
		"target_side": context.target.side if context.target != null else -1,
		"target_hp_after": context.target.current_hp if context.target != null else -1,
		"target_esc_after": context.target.current_esc if context.target != null else -1,
		"damage_dealt": context.damage_dealt,
		"damage_absorbed_by_shield": context.damage_absorbed_by_shield,
		"damage_applied_to_hp": context.damage_applied_to_hp,
	})


func _on_after_heal(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker == null:
		return
	replay_events.append({
		"kind": "heal",
		"turn": context.turn,
		"side": context.side,
		"healer_card_name": context.attacker.card.card_name if context.attacker.card != null else "",
		"target_card_name": context.target.card.card_name if context.target != null and context.target.card != null else "",
		"target_position": context.target.position if context.target != null else -1,
		"target_side": context.target.side if context.target != null else -1,
		"target_hp_after": context.target.current_hp if context.target != null else -1,
		"heal_amount": context.heal_amount,
	})


func _on_unit_died(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker == null:
		return
	replay_events.append({
		"kind": "death",
		"turn": context.turn,
		"side": context.attacker.side,
		"card_name": context.attacker.card.card_name if context.attacker.card != null else "",
		"position": context.attacker.position,
	})
