class_name SeasonConfig
extends RefCounted
## SeasonConfig
##
## Configuração de uma Temporada — o dado de entrada do Pipeline de
## Geração (PvE.md). A Temporada nunca é um resultado fixo: a mesma
## ferramenta roda de novo para a Temporada 2 apenas trocando esta
## configuração.
##
## Os valores abaixo são os oficiais (Sprint 31), mas permanecem
## parâmetros — nunca hard-coded dentro do Pipeline em si.

var season_id: String = "Season01"
var seed_value: int = 1

var normal_army_count: int = 100000
var chefe_normal_count: int = 3000
var chefe_regional_mina_generated_count: int = 5000
var chefe_regional_mina_kept_count: int = 3000  # melhores por WR, após geração

var simulations_per_army: int = 100000
var benchmark_size: int = 20

## Rarity Score mínimo para "Comandante Exclusivo de Campanha" (Sprint
## 31: especialização temporária da Geração Padrão, até existir uma
## ferramenta própria de "Senhor da Guerra"). Rarity Score varia de 5
## (todos os pesos mínimos) a 80 (todos os pesos máximos) — ver
## CommanderGenerator/CommanderFrequency.
var min_rarity_score_exclusive: int = 40

## Liga e Divisão de calibração usadas para computar a recompensa de
## Fragmentos em PvE (RESOURCES.md §4.2: "mesma liga/divisão de
## calibração"). Regra de domínio: "o PvE consulta uma configuração
## para determinar a liga de calibração" — o valor abaixo é apenas o
## padrão desta configuração, nunca a Liga real do jogador (que ainda
## não existe, RANKING.md). Pertence à Temporada (afeta todos os
## jogadores dela igualmente), nunca ao Reino individual — por isso
## mora aqui, não em Kingdom.
var pve_calibration_league: String = "Bronze"
var pve_calibration_division: String = "VII"
