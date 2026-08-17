class_name RewardResolver
extends RefCounted
## RewardResolver
##
## Converte o resultado de uma Fase vencida (PhaseResult) em Fragmentos
## creditados ao Reino (Kingdom.add_fragment), seguindo RESOURCES.md:
## §4.1 (Tabela Oficial de Ligas — Valor-Base por Pelotão Original
## Destruído) e §4.2 (Recompensas PvE: 20% do valor equivalente de PvP,
## para o mesmo resultado e a mesma liga/divisão de calibração).
##
## A Liga/Divisão de calibração é lida de SeasonConfig
## (pve_calibration_league/division) — nunca a Liga real do jogador
## (que ainda não existe no projeto, RANKING.md). Isso mantém a
## economia de PvE desacoplada do Ranking: "o PvE consulta uma
## configuração para determinar a liga de calibração" é a regra; o
## valor padrão ("Bronze"/"VII") é apenas configuração, não regra de
## domínio — Temporadas futuras podem alterá-lo sem mudar esta classe.
##
## Só gera Fragmentos por Pelotões Originais destruídos (nunca
## Conjurados, RESOURCES.md §4) — ver nota em PhaseResult.
## enemy_pelotoes_destroyed sobre por que essa distinção é, por ora,
## automática (nenhuma Habilidade/Característica implementada invoca
## pelotões durante a batalha).

## RESOURCES.md §4.1, Tabela Oficial de Ligas (Valor-Base por Pelotão
## Original Destruído, em Fragmentos, correspondente a uma Vitória).
const LEAGUE_TABLE: Dictionary = {
	"Bronze": {"VII": 10, "VI": 11, "V": 12, "IV": 13, "III": 14, "II": 15, "I": 16},
	"Prata": {"VII": 11, "VI": 12, "V": 14, "IV": 15, "III": 16, "II": 17, "I": 19},
	"Ouro": {"VII": 13, "VI": 15, "V": 16, "IV": 18, "III": 19, "II": 20, "I": 22},
	"Diamante": {"VII": 15, "VI": 17, "V": 19, "IV": 23, "III": 25, "II": 27, "I": 30},
}

## RESOURCES.md §4.1, Etapa 2 — o resultado aplicável aqui é sempre
## "Vitória" (100%): PhaseResult só reporta recompensa quando uma
## tentativa realmente venceu a Fase; tentativas derrotadas durante o
## retry não geram recompensa própria (PvE.md: a Fase só é considerada
## resolvida na vitória).
const RESULT_MODIFIER_VITORIA: float = 1.0

## RESOURCES.md §4.2 — PvE gera 20% do valor equivalente de PvP.
const PVE_MODIFIER: float = 0.20


## Resolve e credita a recompensa de Fragmentos de uma Fase vencida ao
## Reino informado. Retorna a quantidade TOTAL de Fragmentos
## creditados (soma de todas as Facções — 0 se "result" não for
## vitória, ou não houver oponente registrado). RESOURCES.md §4,
## "Correspondência de Facção": cada Pelotão destruído credita
## Fragmentos da SUA PRÓPRIA Facção, nunca a Facção principal do
## oponente como um todo (a composição inimiga mistura Facções).
static func resolve(result: PhaseResult, kingdom: Kingdom, season_config: SeasonConfig) -> int:
	if not result.victory:
		return 0
	if result.opponent_entry == null:
		return 0

	var base_value_per_pelotao: int = _base_value_per_pelotao(season_config)
	var fragments_per_pelotao: float = base_value_per_pelotao * RESULT_MODIFIER_VITORIA * PVE_MODIFIER

	var total: int = 0
	for faction: String in result.enemy_pelotoes_destroyed_by_faction:
		var count: int = result.enemy_pelotoes_destroyed_by_faction[faction]
		var amount: int = int(round(fragments_per_pelotao * count))
		if amount > 0:
			kingdom.add_fragment(faction, amount)
			total += amount
	return total


static func _base_value_per_pelotao(season_config: SeasonConfig) -> int:
	var league: String = season_config.pve_calibration_league
	var division: String = season_config.pve_calibration_division

	assert(LEAGUE_TABLE.has(league),
		"RewardResolver: Liga de calibração desconhecida: '%s'." % league)
	assert(LEAGUE_TABLE[league].has(division),
		"RewardResolver: Divisão de calibração desconhecida: '%s' (Liga %s)." % [division, league])

	return LEAGUE_TABLE[league][division]
