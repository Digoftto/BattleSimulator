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
## MESMA COLUNA — geometria própria da habilidade "Sacrifício de Carne"
## (ABILITIES.md/CARD_CATALOG.md: "Pelotão aliado imediatamente atrás na
## mesma coluna"), que define sua Classe de alvo dessa forma
## independentemente de como a Fase de Avanço move as unidades. NÃO usar
## para a Cadeia de Bloqueio do Suporte (6.5) — ver support_position_behind().
static func positions_behind(position: int) -> Array[int]:
	var column: Array = column_of(position)
	var index: int = column.find(position)
	var behind: Array[int] = []
	for i in range(index + 1, column.size()):
		behind.append(column[i])
	return behind


## Retorna a posição imediatamente ATRÁS de "position" na sequência
## espacial única de avanço (ADVANCE_ORDER, COMBAT_RULES.md 5.2.1), ou -1
## se não houver nenhuma (Posição 9 é o fundo absoluto da sequência —
## nada pode estar "atrás" dela). Usada exclusivamente pela Cadeia de
## Bloqueio do Suporte (6.5), que verifica "a posição imediatamente atrás
## dele" dentro da MESMA Fase de Avanço de 5.2.1 (5.2.3: a regra do
## Suporte é uma exceção que sobrescreve a regra geral, nunca um
## mecanismo geométrico independente) — não confundir com
## positions_behind()/column_of() acima, que continuam corretos para
## "Sacrifício de Carne" (regra própria, deliberadamente por coluna).
static func support_position_behind(position: int) -> int:
	var index: int = ADVANCE_ORDER.find(position)
	if index <= 0:
		return -1
	return ADVANCE_ORDER[index - 1]
