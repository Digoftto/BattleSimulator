class_name ArmyPositioningHeuristic
extends RefCounted
## ArmyPositioningHeuristic
##
## Posiciona as 9 cartas de um Exército no tabuleiro sem ser IA tática
## de verdade (isso ficou fora de escopo, de propósito — buscar a
## posição ótima exigiria testar até 9! = 362.880 permutações por
## Exército, o mesmo problema de escala já registrado em
## MiningCycleResolver.gd). Isso aqui é só bom senso: Corpo a
## Corpo/Barreira só atacam da Linha 1 (COMBAT_RULES.md, 6.1/6.2) — um
## posicionamento aleatório poderia deixá-los incapazes de agir a
## batalha inteira, medindo sorte de posição, não a força real da
## composição.
##
## Máquina de Guerra NUNCA é escolha de heurística nem de
## aleatoriedade — "Posicionamento Inicial Obrigatório: Toda Máquina
## de Guerra deve iniciar obrigatoriamente na posição 9"
## (COMBAT_RULES.md, 6.6) é Regra Estrutural da Engine, maior
## prioridade do jogo (capítulo 7) — vale nos dois modos abaixo.

const FRONT_LINE_CLASSES: Array[String] = ["Corpo a Corpo", "Barreira"]
const FRONT_LINE_SIZE: int = 3
const MACHINE_CLASS: String = "Máquina de Guerra"
const MACHINE_POSITION_INDEX: int = 8  # posição 9 (índice 0-based)


## Bom senso: Linha 1 prioriza Corpo a Corpo/Barreira; o resto vai pra
## trás. Máquina de Guerra sempre na posição 9.
static func apply_heuristic(cards: Array[CardResource]) -> Array[CardResource]:
	var result: Array[CardResource] = []
	result.resize(9)

	var remaining: Array[CardResource] = _extract_machine_to_fixed_position(cards, result)

	var front_line_cards: Array[CardResource] = []
	var back_line_cards: Array[CardResource] = []
	for card: CardResource in remaining:
		if FRONT_LINE_CLASSES.has(card.card_class):
			front_line_cards.append(card)
		else:
			back_line_cards.append(card)

	var slot_index: int = 0
	while slot_index < FRONT_LINE_SIZE and not front_line_cards.is_empty():
		result[slot_index] = front_line_cards.pop_front()
		slot_index += 1
	while slot_index < FRONT_LINE_SIZE and not back_line_cards.is_empty():
		result[slot_index] = back_line_cards.pop_front()
		slot_index += 1

	var leftovers: Array[CardResource] = []
	leftovers.append_array(front_line_cards)
	leftovers.append_array(back_line_cards)
	for i in range(9):
		if result[i] != null:
			continue
		result[i] = leftovers.pop_front()

	return result


## Aleatório de verdade nas 8 posições livres (posição 9 continua fixa
## pra Máquina de Guerra, se houver — não é escolha, é regra do
## motor). Determinístico via "rng" (mesma seed = mesmo resultado).
static func apply_random(cards: Array[CardResource], rng: RandomNumberGenerator) -> Array[CardResource]:
	var result: Array[CardResource] = []
	result.resize(9)

	var remaining: Array[CardResource] = _extract_machine_to_fixed_position(cards, result)
	_seeded_shuffle(remaining, rng)

	var slot_index: int = 0
	for i in range(9):
		if result[i] != null:
			continue
		result[i] = remaining[slot_index]
		slot_index += 1

	return result


static func _extract_machine_to_fixed_position(cards: Array[CardResource], result: Array[CardResource]) -> Array[CardResource]:
	var remaining: Array[CardResource] = cards.duplicate()
	for i in range(remaining.size()):
		if remaining[i].card_class == MACHINE_CLASS:
			result[MACHINE_POSITION_INDEX] = remaining[i]
			remaining.remove_at(i)
			break
	return remaining


static func _seeded_shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp
