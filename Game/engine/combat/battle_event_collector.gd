class_name BattleEventCollector
extends RefCounted
## BattleEventCollector (F-028)
##
## Assinante OPCIONAL do CombatEventBus de uma batalha — transforma os
## eventos já publicados por CombatEngine (ver CombatEventType) em
## dados estruturados, sem que CombatEngine precise saber que este
## coletor existe. CombatEngine nunca cria, anexa ou consulta um
## BattleEventCollector — é sempre quem chama (PhaseResolver, um futuro
## BattleSimulationRunner, etc.) que decide anexar um, chamando attach()
## ANTES de CombatEngine.run().
##
## RefCounted puro — sem Node, sem cena, sem UI. Seguro para milhares
## de batalhas headless: nenhum listener é registrado no
## CombatEventBus (e portanto nenhum custo é pago) quando nenhum
## BattleEventCollector é criado — o battle_log textual continua
## podendo ser desligado independentemente (CombatState.enable_battle_log).

var attack_events: Array[Dictionary] = []
var heal_events: Array[Dictionary] = []
var death_events: Array[Dictionary] = []


func attach(event_bus: CombatEventBus) -> void:
	event_bus.subscribe(CombatEventType.Type.AFTER_ATTACK, _on_after_attack)
	event_bus.subscribe(CombatEventType.Type.AFTER_HEAL_PERFORMED, _on_after_heal)
	event_bus.subscribe(CombatEventType.Type.UNIT_DIED, _on_unit_died)


func _on_after_attack(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	if context.attacker == null:
		return
	attack_events.append({
		"turn": context.turn,
		"side": context.side,
		"attacker_card_name": context.attacker.card.card_name if context.attacker.card != null else "",
		"attacker_position": context.attacker.position,
		"attacker_class": context.attacker.card.card_class if context.attacker.card != null else "",
		"target_card_name": context.target.card.card_name if context.target != null and context.target.card != null else "",
		"target_position": context.target.position if context.target != null else -1,
		"target_class": context.target.card.card_class if context.target != null and context.target.card != null else "",
		"target_side": context.target.side if context.target != null else -1,
		"damage_dealt": context.damage_dealt,
		"damage_absorbed_by_shield": context.damage_absorbed_by_shield,
		"damage_applied_to_hp": context.damage_applied_to_hp,
	})


func _on_after_heal(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	heal_events.append({
		"turn": context.turn,
		"side": context.side,
		"healer_card_name": context.attacker.card.card_name if context.attacker != null and context.attacker.card != null else "",
		"healer_position": context.attacker.position if context.attacker != null else -1,
		"healer_class": context.attacker.card.card_class if context.attacker != null and context.attacker.card != null else "",
		"target_card_name": context.target.card.card_name if context.target != null and context.target.card != null else "",
		"heal_amount": context.heal_amount,
	})


## F-029: "attacker_card_name"/"attacker_position"/"attacker_class" no
## nome dos campos (não "victim_*") por consistência com attack_events/
## heal_events acima — em todo evento deste coletor, o campo prefixado
## "attacker_"/"healer_" identifica de quem partiu o evento; aqui, quem
## "sofreu" o evento (morreu) É o próprio "attacker" do CombatContext
## (ver CombatEngine._death_resolution_phase(), que reaproveita o campo
## "attacker" para apontar a unidade morta — nunca quem a matou; ver
## SimulationReport para a heurística de atribuição de "kill").
func _on_unit_died(_event_type: CombatEventType.Type, context: CombatContext) -> void:
	death_events.append({
		"turn": context.turn,
		"side": context.side,
		"card_name": context.attacker.card.card_name if context.attacker != null and context.attacker.card != null else "",
		"position": context.attacker.position if context.attacker != null else -1,
		"card_class": context.attacker.card.card_class if context.attacker != null and context.attacker.card != null else "",
	})


## side (0/1) -> soma de damage_dealt causado por unidades daquele lado.
func total_damage_by_side() -> Dictionary:
	var totals: Dictionary = {0: 0, 1: 0}
	for event: Dictionary in attack_events:
		totals[event["side"]] = totals.get(event["side"], 0) + int(event["damage_dealt"])
	return totals


## side (0/1) -> soma de heal_amount curado por unidades daquele lado.
func total_healing_by_side() -> Dictionary:
	var totals: Dictionary = {0: 0, 1: 0}
	for event: Dictionary in heal_events:
		totals[event["side"]] = totals.get(event["side"], 0) + int(event["heal_amount"])
	return totals


## side (0/1) -> soma de dano absorvido por Escudo em ataques causados
## por unidades daquele lado (ou seja: quanto o lado ADVERSÁRIO
## absorveu com Escudo ao ser atacado por este lado).
func total_shield_absorbed_by_side() -> Dictionary:
	var totals: Dictionary = {0: 0, 1: 0}
	for event: Dictionary in attack_events:
		totals[event["side"]] = totals.get(event["side"], 0) + int(event["damage_absorbed_by_shield"])
	return totals
