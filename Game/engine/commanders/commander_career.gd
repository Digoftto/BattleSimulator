class_name CommanderCareer
extends RefCounted
## CommanderCareer
##
## Lógica pura da Carreira Militar do Comandante (XP e Patente), conforme
## XP.md — fonte única de verdade da progressão de XP e das regras de
## promoção de Patente.
##
## Escopo desta Sprint: acúmulo de XP do Comandante e derivação de Patente.
## Não implementa Autoridade Militar, Histórico Militar, XP de Conta
## (Reino), Centro de Comando, Combate, Exército, Soldo ou Interface.

## Tabela Oficial de Progressão por Patente (XP.md). Os valores representam
## XP acumulado total na carreira, não a diferença entre patentes.
const PATENTE_THRESHOLDS: Array[Dictionary] = [
	{"patente": "Recruta", "xp": 0},
	{"patente": "Capitão", "xp": 400},
	{"patente": "Major", "xp": 1200},
	{"patente": "Coronel", "xp": 2640},
	{"patente": "General", "xp": 4880},
	{"patente": "Marechal", "xp": 8080},
	{"patente": "Lorde-Comandante", "xp": 12480},
]

## XP concedido ao Comandante por vitória no PvP, por Liga (XP.md, "XP por Vitória").
const XP_PER_PVP_VICTORY: Dictionary = {
	"Bronze": 10,
	"Prata": 12,
	"Ouro": 14,
	"Diamante": 16,
}

## O PvE concede 30% do XP de uma vitória na Liga Bronze do PvP (XP.md).
const PVE_VICTORY_RATIO: float = 0.30


## Retorna a Patente correspondente a uma quantidade de XP acumulado,
## conforme a Tabela Oficial de Progressão por Patente.
static func patente_for_xp(xp: int) -> String:
	var current: String = PATENTE_THRESHOLDS[0]["patente"]
	for entry: Dictionary in PATENTE_THRESHOLDS:
		if xp >= entry["xp"]:
			current = entry["patente"]
		else:
			break
	return current


## Texto legível de progresso de XP — "XP: 850/1200 até Major" ou
## "XP: 12480 (Patente máxima)" se já for Lorde-Comandante. Usado nas
## telas que mostram Comandantes (antes não existia visualização
## nenhuma de XP/progresso pro jogador).
static func xp_progress_text(xp: int) -> String:
	for i in range(PATENTE_THRESHOLDS.size() - 1):
		if xp < PATENTE_THRESHOLDS[i + 1]["xp"]:
			return "XP: %d/%d até %s" % [xp, PATENTE_THRESHOLDS[i + 1]["xp"], PATENTE_THRESHOLDS[i + 1]["patente"]]
	return "XP: %d (Patente máxima)" % xp


## Retorna o XP concedido por uma vitória no PvP na Liga informada.
static func xp_for_pvp_victory(league: String) -> int:
	assert(XP_PER_PVP_VICTORY.has(league), "CommanderCareer: Liga de PvP desconhecida: '%s'." % league)
	return XP_PER_PVP_VICTORY[league]


## Retorna o XP concedido por qualquer vitória no PvE (30% da Liga Bronze do PvP).
static func xp_for_pve_victory() -> int:
	return int(round(XP_PER_PVP_VICTORY["Bronze"] * PVE_VICTORY_RATIO))


## Incorpora XP ao comandante permanentemente. O XP nunca é perdido, por
## isso "amount" deve ser sempre não-negativo.
static func add_xp(commander: CommanderResource, amount: int) -> void:
	assert(amount >= 0, "CommanderCareer: XP nunca é perdido; amount deve ser não-negativo.")
	commander.accumulated_xp += amount
