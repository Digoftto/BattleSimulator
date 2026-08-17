class_name CombatBoard
extends RefCounted
## CombatBoard
##
## Constantes estruturais do tabuleiro de combate (COMBAT_RULES.md, seção
## 1.1 e capítulo 6). Nenhuma lógica de turno aqui — apenas os dados
## geométricos e as ordens oficiais fixas do documento.

const LINE_1: Array[int] = [1, 2, 3]
const LINE_2: Array[int] = [4, 5, 6]
const LINE_3: Array[int] = [7, 8, 9]

## Colunas, ordenadas da frente para o fundo (COMBAT_RULES.md 1.1).
const COLUMN_A: Array[int] = [1, 6, 7]
const COLUMN_B: Array[int] = [2, 5, 8]
const COLUMN_C: Array[int] = [3, 4, 9]
const COLUMNS: Array = [COLUMN_A, COLUMN_B, COLUMN_C]

## Fluxo de Avanço oficial (5.2.1).
const ADVANCE_ORDER: Array[int] = [9, 8, 7, 6, 5, 4, 3, 2, 1]

## Ordem Oficial de Resolução, usada como fallback de desempate (6.1).
const OFFICIAL_RESOLUTION_ORDER: Array[int] = [1, 2, 3, 6, 5, 4, 7, 8, 9]

## Mapa de ataque da Classe À Distância (6.3), incluindo a exceção
## estrutural deliberada da posição 3 (ataca 9, counter contra Máquinas de
## Guerra) e a ausência de entrada para a posição 2 (não ataca).
const RANGED_TARGET_MAP: Dictionary = {
	7: 6, 8: 5, 9: 4,
	6: 1, 5: 2, 4: 3,
	3: 9,
	1: 1,
}


static func is_line_1(position: int) -> bool:
	return LINE_1.has(position)


## Retorna a coluna (Array[int], frente->fundo) à qual a posição pertence.
static func column_of(position: int) -> Array:
	for column: Array in COLUMNS:
		if column.has(position):
			return column
	return []


## Retorna a posição imediatamente à frente, na mesma coluna, ou -1 caso a
## posição já esteja na Linha 1 (sem posição à frente).
static func front_neighbor(position: int) -> int:
	var column: Array = column_of(position)
	var index: int = column.find(position)
	if index <= 0:
		return -1
	return column[index - 1]


## Retorna as posições "atrás" (mais ao fundo) da posição informada, na
## mesma coluna — usado pela exceção de movimento da Classe Suporte (5.2.3).
static func positions_behind(position: int) -> Array[int]:
	var column: Array = column_of(position)
	var index: int = column.find(position)
	var behind: Array[int] = []
	for i in range(index + 1, column.size()):
		behind.append(column[i])
	return behind
