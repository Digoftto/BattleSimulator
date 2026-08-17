class_name RankingResolver
extends RefCounted
## RankingResolver (RANKING.md)
##
## Divisões, faixas de Pontos de Liga (PL), ganho/perda por resultado
## (Atacante/Defensor, por faixa de Divisão), promoção e rebaixamento
## automáticos, e as regras de entrada/reentrada num novo ciclo. Pura
## lógica — nunca decide sozinho quem é o participante (Comandante na
## Bronze, PlanoCampanha nas demais); quem chama isso decide onde
## guardar o resultado.
##
## ESCOPO DESTA ENTREGA — ver também PlanoCampanhaResolver.gd:
## - A Divisão I (Topo Competitivo) usa uma regra diferente das
##   demais: "5% melhores ativos da Liga", recalculada semanalmente,
##   contra TODA a população de participantes daquela Liga. Isso não
##   é calculável localmente (não existe um "servidor" com a lista de
##   todos os jogadores neste projeto ainda) — aqui, alcançar 6.000 PL
##   promove para a Divisão I de forma simplificada (sem o corte dos
##   5%); o corte real fica pendente de uma futura infraestrutura de
##   backend/servidor.
## - Matchmaking real (localizar um adversário de verdade) também
##   depende dessa mesma infraestrutura ausente — ver MATCHMAKING.md.
##   Esta entrega cobre a MECÂNICA de pontuação em si, aplicável assim
##   que um resultado de partida (de qualquer origem) for informado.

enum Role { ATACANTE, DEFENSOR }
enum Result { VITORIA, DERROTA, EMPATE }

const DIVISION_ORDER: Array[String] = ["VII", "VI", "V", "IV", "III", "II", "I"]

## Faixa mínima de PL de cada Divisão regular (Divisão I não tem teto
## e usa a regra simplificada documentada acima).
const DIVISION_MIN_PL: Dictionary = {
	"VII": 0, "VI": 1000, "V": 2000, "IV": 3000, "III": 4000, "II": 5000, "I": 6000,
}


## Aplica o resultado de uma partida — retorna o novo PL e a nova
## Divisão (já promovendo/rebaixando automaticamente se necessário).
## "division" é a Divisão ATUAL antes do resultado. Retorna
## {"pl": int, "division": String, "promoted": bool, "demoted": bool}.
static func apply_result(pl: int, division: String, role: Role, result: Result) -> Dictionary:
	var delta: int = _points_delta(division, role, result)
	var new_pl: int = maxi(0, pl + delta)
	var new_division: String = _division_for_pl(new_pl)

	# Nunca rebaixa abaixo da Divisão VII (RANKING.md, "Nenhum
	# participante pode ser rebaixado abaixo da Divisão VII").
	if DIVISION_ORDER.find(new_division) < DIVISION_ORDER.find("VII"):
		new_division = "VII"
		new_pl = maxi(new_pl, DIVISION_MIN_PL["VII"])

	var old_index: int = DIVISION_ORDER.find(division)
	var new_index: int = DIVISION_ORDER.find(new_division)

	return {
		"pl": new_pl,
		"division": new_division,
		"promoted": new_index > old_index,
		"demoted": new_index < old_index,
	}


## Ganho/perda de PL por resultado (RANKING.md, "Regras de Ganho e
## Perda de Pontos") — Atacante: +100/-75 (Divisões VII a III) ou
## +100/-100 (Divisões II e I); Defensor: +20/-20 em qualquer Divisão.
## Empate nunca altera PL, em nenhum papel.
static func _points_delta(division: String, role: Role, result: Result) -> int:
	if result == Result.EMPATE:
		return 0

	if role == Role.DEFENSOR:
		return 20 if result == Result.VITORIA else -20

	# Atacante.
	var is_top_tier: bool = division == "II" or division == "I"
	if result == Result.VITORIA:
		return 100
	return -100 if is_top_tier else -75


static func _division_for_pl(pl: int) -> String:
	var current: String = "VII"
	for division: String in DIVISION_ORDER:
		if DIVISION_MIN_PL[division] <= pl:
			current = division
	return current


## Divisão inicial ao ingressar numa Liga pela primeira vez
## (RANKING.md, "Ingressando em uma Liga"): sempre Divisão VII.
static func initial_division() -> String:
	return "VII"


## Divisão de reentrada num novo ciclo, para quem já tem histórico
## naquela Liga: duas posições abaixo da Divisão final da temporada
## anterior, nunca abaixo da Divisão VII.
static func reentry_division(previous_final_division: String) -> String:
	var index: int = DIVISION_ORDER.find(previous_final_division)
	var new_index: int = maxi(0, index - 2)
	return DIVISION_ORDER[new_index]


## PL de reentrada: o valor mínimo exato da Divisão de reentrada
## (RANKING.md: "iniciando o novo ciclo com o valor exato de
## pontuação mínima dessa nova Divisão").
static func reentry_pl(reentry_division_value: String) -> int:
	return DIVISION_MIN_PL[reentry_division_value]
