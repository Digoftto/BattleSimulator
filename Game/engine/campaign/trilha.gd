class_name Trilha
extends RefCounted
## Trilha (PvE.md)
##
## Representa o conteúdo permanente e compartilhado de uma Trilha:
## quantidade de Fases, posição dos Chefes Normais/Regionais e posição
## dos Acampamentos. Não armazena progresso do jogador — isso pertence
## exclusivamente à Expedição (ExpeditionRuntime).
##
## Escopo desta Sprint: implementa fielmente a estrutura territorial já
## definida em PvE.md (3 Regiões, 9.000 Fases, 9 Chefes Regionais, Chefes
## Normais a cada 100 Fases, intervalos crescentes de Acampamento por
## Região, com prioridade entre Chefes e reinício de contagem). Território,
## Facção da Trilha e recompensas ficam para Sprints futuras.

const TOTAL_FASES: int = 9000
const CHEFE_NORMAL_INTERVALO: int = 100
const CHEFE_REGIONAL_POSITIONS: Array[int] = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]

## Identificador do Território ao qual esta Trilha pertence (Territory).
## A Trilha nunca grava a Facção diretamente — ela vem do Território,
## preservando a hierarquia Território -> Facção -> Região -> Trilha
## (PvE.md) para que propriedades futuras do Território não exijam
## mudança de estrutura aqui.
var territory_id: String = ""

## Posições de Acampamento, geradas uma única vez na construção (ordem
## crescente). Inclui obrigatoriamente as 9 Fases de Chefe Regional.
var acampamento_positions: Array[int] = []


func _init(p_territory_id: String = "") -> void:
	territory_id = p_territory_id
	acampamento_positions = _generate_acampamentos()


func total_fases() -> int:
	return TOTAL_FASES


func is_chefe_regional(fase: int) -> bool:
	return CHEFE_REGIONAL_POSITIONS.has(fase)


func is_chefe_normal(fase: int) -> bool:
	return fase >= 1 and fase <= TOTAL_FASES and fase % CHEFE_NORMAL_INTERVALO == 0


## Prioridade entre Chefes (PvE.md): Chefe Regional sempre prevalece
## sobre Chefe Normal na mesma Fase — o Chefe Normal simplesmente não
## ocorre naquele ciclo (não é reagendado).
## Retorna "regional", "normal" ou "" (Fase comum).
func chefe_type(fase: int) -> String:
	if is_chefe_regional(fase):
		return "regional"
	if is_chefe_normal(fase):
		return "normal"
	return ""


func is_acampamento(fase: int) -> bool:
	return acampamento_positions.has(fase)


## Retorna a Região (1, 2 ou 3 — Região I/II/III) à qual a Fase
## pertence, conforme a Hierarquia Territorial (PvE.md).
func region_for_fase(fase: int) -> int:
	if fase <= 3000:
		return 1
	if fase <= 6000:
		return 2
	return 3


func _is_chefe_fase(fase: int) -> bool:
	return is_chefe_regional(fase) or is_chefe_normal(fase)


## Intervalo oficial de Acampamento vigente para uma Fase (PvE.md,
## "Distância entre Acampamentos").
func _interval_for_fase(fase: int) -> int:
	if fase <= 1500:
		return 25
	if fase <= 3000:
		return 30
	if fase <= 4500:
		return 35
	if fase <= 6000:
		return 40
	if fase <= 7500:
		return 45
	return 50


## Gera sequencialmente as posições de Acampamento, respeitando:
## - Chefes Regionais sempre estabelecem Acampamento imediato (PvE.md,
##   "Reinício de Contagem");
## - Acampamentos por intervalo nunca coincidem com nenhum Chefe
##   (Normal ou Regional) — deslocados 1 Fase à frente quando colidem
##   (PvE.md, "Prioridade do Acampamento");
## - a distância é sempre contada a partir do último Acampamento
##   efetivamente colocado, nunca da posição teórica (PvE.md, "Reinício
##   da Contagem").
func _generate_acampamentos() -> Array[int]:
	var positions: Array[int] = []
	var last_position: int = 0
	var next_regional_index: int = 0

	while last_position < TOTAL_FASES:
		var interval: int = _interval_for_fase(last_position + 1)
		var candidate: int = last_position + interval

		if next_regional_index < CHEFE_REGIONAL_POSITIONS.size() and candidate >= CHEFE_REGIONAL_POSITIONS[next_regional_index]:
			candidate = CHEFE_REGIONAL_POSITIONS[next_regional_index]
			next_regional_index += 1
		else:
			while _is_chefe_fase(candidate) and candidate <= TOTAL_FASES:
				candidate += 1

		if candidate > TOTAL_FASES:
			break

		positions.append(candidate)
		last_position = candidate

	return positions
