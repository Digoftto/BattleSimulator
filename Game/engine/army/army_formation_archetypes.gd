class_name ArmyFormationArchetypes
extends RefCounted
## ArmyFormationArchetypes (ARMY.md, "Arquétipos de Formação (β, γ, δ, ε)")
##
## Gera as Formações β, γ, δ, ε automaticamente a partir das mesmas 9
## cartas de α — cada uma seguindo um arquétipo tático fixo e
## determinístico (nunca aleatório, nunca idênticas entre si). O
## jogador pode editar qualquer uma livremente depois.
##
## Convenção de índice (igual ArmyPositioningHeuristic.gd): índice 0
## do Array = Posição 1, índice 8 = Posição 9. Tabuleiro oficial:
##   7 8 9   (Linha 3)
##   6 5 4   (Linha 2)
##   1 2 3   (Linha 1)
##
## Máquina de Guerra SEMPRE na Posição 9 — Regra Estrutural da Engine
## (COMBAT_RULES.md 6.6), nunca sobrescrita por nenhum arquétipo aqui.

const FRONT_LINE_CLASSES: Array[String] = ["Corpo a Corpo", "Barreira"]
const MACHINE_CLASS: String = "Máquina de Guerra"
const RANGED_CLASS: String = "À Distância"
const CASTER_CLASSES: Array[String] = ["Mago", "Suporte"]


## Gera as 4 Formações a partir da mesma composição base (α) — retorna
## {"β": Array[CardResource], "γ": ..., "δ": ..., "ε": ...}.
static func generate_all(base_cards: Array[CardResource]) -> Dictionary:
	return {
		"β": _offensive(base_cards),
		"γ": _defensive(base_cards),
		"δ": _balanced(base_cards),
		"ε": _dispersion(base_cards),
	}


## Formação β — Ofensiva (Ruptura): maior Ataque na Posição 1
## (bônus estrutural +50%, COMBAT_RULES.md 6.1). À Distância
## obrigatoriamente nas Posições 6 e 7.
static func _offensive(base_cards: Array[CardResource]) -> Array[CardResource]:
	var result: Array[CardResource] = _new_empty_board()
	var remaining: Array[CardResource] = _extract_machine(base_cards, result)

	var front_line: Array[CardResource] = _extract_by_class(remaining, FRONT_LINE_CLASSES)
	front_line.sort_custom(func(a: CardResource, b: CardResource) -> bool: return a.atk > b.atk)
	if not front_line.is_empty():
		result[0] = front_line.pop_front()  # Posição 1: maior Ataque
	_fill_positions(result, [1, 2], front_line)  # Posições 2, 3: resto da Linha 1

	var ranged: Array[CardResource] = _extract_by_class(remaining, [RANGED_CLASS])
	_fill_positions(result, [5, 6], ranged)  # Posições 6, 7 (índices 5, 6)

	var leftovers: Array[CardResource] = []
	leftovers.append_array(front_line)
	leftovers.append_array(ranged)
	leftovers.append_array(remaining)
	_fill_remaining(result, leftovers)
	return result


## Formação γ — Defensiva (Muralha): maior Escudo na Posição 1
## (bônus estrutural +50% do Escudo Base, COMBAT_RULES.md 6.2).
## Magos/Suportes nas posições mais profundas disponíveis.
static func _defensive(base_cards: Array[CardResource]) -> Array[CardResource]:
	var result: Array[CardResource] = _new_empty_board()
	var remaining: Array[CardResource] = _extract_machine(base_cards, result)

	var front_line: Array[CardResource] = _extract_by_class(remaining, FRONT_LINE_CLASSES)
	front_line.sort_custom(func(a: CardResource, b: CardResource) -> bool: return a.esc > b.esc)
	if not front_line.is_empty():
		result[0] = front_line.pop_front()  # Posição 1: maior Escudo
	_fill_positions(result, [1, 2], front_line)  # Posições 2, 3: resto da Linha 1

	var casters: Array[CardResource] = _extract_by_class(remaining, CASTER_CLASSES)
	_fill_positions(result, [7, 6], casters)  # Posições 8, 7 (índices 7, 6) — mais profundas disponíveis (9 é a MdG)

	var leftovers: Array[CardResource] = []
	leftovers.append_array(front_line)
	leftovers.append_array(casters)
	leftovers.append_array(remaining)
	_fill_remaining(result, leftovers)
	return result


## Formação δ — Equilibrada: nenhum extremo otimizado. Posição 1 é a
## carta "do meio" da Linha 1 (nem maior Ataque, nem maior Escudo).
static func _balanced(base_cards: Array[CardResource]) -> Array[CardResource]:
	var result: Array[CardResource] = _new_empty_board()
	var remaining: Array[CardResource] = _extract_machine(base_cards, result)

	var front_line: Array[CardResource] = _extract_by_class(remaining, FRONT_LINE_CLASSES)
	# Ordena por uma pontuação combinada (Ataque + Escudo) e pega a
	# carta do meio — nunca o extremo de nenhum dos dois atributos.
	front_line.sort_custom(func(a: CardResource, b: CardResource) -> bool: return (a.atk + a.esc) > (b.atk + b.esc))
	if not front_line.is_empty():
		var middle_index: int = front_line.size() / 2
		result[0] = front_line[middle_index]
		front_line.remove_at(middle_index)
	_fill_positions(result, [1, 2], front_line)

	var back_line: Array[CardResource] = []
	back_line.append_array(_extract_by_class(remaining, [RANGED_CLASS]))
	back_line.append_array(_extract_by_class(remaining, CASTER_CLASSES))

	var leftovers: Array[CardResource] = []
	leftovers.append_array(front_line)
	leftovers.append_array(back_line)
	leftovers.append_array(remaining)
	_fill_remaining(result, leftovers)
	return result


## Formação ε — Dispersão (Cobertura Total): À Distância se distribui
## entre posições que atacam colunas DIFERENTES do adversário
## (COMBAT_RULES.md 6.3) — nunca concentra fogo num único alvo.
static func _dispersion(base_cards: Array[CardResource]) -> Array[CardResource]:
	var result: Array[CardResource] = _new_empty_board()
	var remaining: Array[CardResource] = _extract_machine(base_cards, result)

	var front_line: Array[CardResource] = _extract_by_class(remaining, FRONT_LINE_CLASSES)
	_fill_positions(result, [0, 1, 2], front_line)  # Linha 1 normal, sem otimização de Posição 1

	# Ordem de posições (índice 0-based) escolhida pra maximizar
	# colunas inimigas diferentes atacadas ao mesmo tempo: 4→col.3,
	# 5→col.2, 6→col.1, 8→col.5 — 4 alvos distintos antes de repetir
	# qualquer coluna (COMBAT_RULES.md 6.3, tabela de alvo).
	var ranged: Array[CardResource] = _extract_by_class(remaining, [RANGED_CLASS])
	_fill_positions(result, [3, 4, 5, 7], ranged)

	var leftovers: Array[CardResource] = []
	leftovers.append_array(front_line)
	leftovers.append_array(ranged)
	leftovers.append_array(remaining)
	_fill_remaining(result, leftovers)
	return result


static func _new_empty_board() -> Array[CardResource]:
	var result: Array[CardResource] = []
	result.resize(9)
	return result


static func _extract_machine(cards: Array[CardResource], result: Array[CardResource]) -> Array[CardResource]:
	var remaining: Array[CardResource] = cards.duplicate()
	for i in range(remaining.size()):
		if remaining[i].card_class == MACHINE_CLASS:
			result[8] = remaining[i]  # Posição 9 — sempre, nunca escolha do arquétipo
			remaining.remove_at(i)
			break
	return remaining


static func _extract_by_class(cards: Array[CardResource], classes: Array[String]) -> Array[CardResource]:
	var matched: Array[CardResource] = []
	var i: int = 0
	while i < cards.size():
		if classes.has(cards[i].card_class):
			matched.append(cards[i])
			cards.remove_at(i)
		else:
			i += 1
	return matched


## Preenche "positions" (índices 0-based) com cartas de "source", na
## ordem em que estão — consome de "source" conforme preenche.
static func _fill_positions(result: Array[CardResource], positions: Array[int], source: Array[CardResource]) -> void:
	for position: int in positions:
		if source.is_empty():
			return
		if result[position] == null:
			result[position] = source.pop_front()


## Preenche todas as posições ainda vazias com o que sobrou, em
## qualquer ordem — garante que as 9 posições nunca fiquem incompletas.
static func _fill_remaining(result: Array[CardResource], leftovers: Array[CardResource]) -> void:
	for i in range(9):
		if result[i] == null and not leftovers.is_empty():
			result[i] = leftovers.pop_front()
