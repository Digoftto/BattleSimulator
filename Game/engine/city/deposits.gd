class_name Deposits
extends RefCounted
## Deposits (DEPOSITS.md + FORMULAS.md, "Depósitos")
##
## Lógica pura do custo de evolução do Depósito (única construção,
## armazena os 3 Recursos de Construção simultaneamente — Ferro Negro,
## Cristais Arcanos, Essência Vital) — paga exclusivamente em Pontos de
## Geração (PG), nunca em Recursos de Construção (DEPOSITS.md,
## "Filosofia do Depósito").
##
## Capacidade de armazenamento (storage_capacity()): progressão
## geométrica de fator 3 nos primeiros 7 níveis (começando em 24),
## seguida de Progressão Aritmética a partir do Nível 8 (mesmo passo
## do último salto geométrico) — decisão do dono do projeto,
## substitui tanto a antiga referência da Temporada 1 (vinculada à
## produção da Mina Básica) quanto a tentativa intermediária vinculada
## ao custo da Capital (as duas mantidas em DEPOSITS.md só como
## registro histórico). Ainda sujeita a balanceamento futuro.


## Custo em Pontos de Geração (PG) para evoluir um Depósito até o nível
## de destino "target_level" (FORMULAS.md, "Depósitos": ceil(n / 4)).
static func upgrade_cost_pg(target_level: int) -> int:
	assert(target_level >= 1, "Deposits: nível de destino deve ser >= 1.")
	@warning_ignore("integer_division")  # Divisão inteira intencional: implementa ceil(n/4) sem depender de funções float.
	return (target_level + 3) / 4


## Capacidade de armazenamento do Depósito no nível "level" (decisão
## do dono do projeto, substitui a antiga referência da Temporada 1
## vinculada à produção da Mina Básica): 130% do custo por Recurso de
## Construção que a Capital precisa para evoluir do nível "level" para
## "level + 1". Como a Capital divide seu custo igualmente entre os 3
## Recursos (33/33/33 — CITY.md/FORMULAS.md), o "custo por Recurso" é
## simplesmente o custo total de evolução da Capital dividido por 3.
##
## Exemplo: se a Capital precisa de 300 no total (100 de cada recurso)
## para ir ao Nível N, o Depósito no Nível N-1 armazena 130 de cada
## recurso (100 × 1,3).
## Capacidade de armazenamento do Depósito no nível "level" (decisão
## do dono do projeto, ainda sujeita a balanceamento):
## - Níveis 1 a 7: progressão geométrica de fator 3, começando em 24
##   (24, 72, 216, 648, 1.944, 5.832, 17.496).
## - Nível 8 em diante: Progressão Aritmética, somando sempre o mesmo
##   incremento do último salto geométrico (Nível 6 -> 7 = 11.664),
##   em vez de continuar multiplicando — evita que a capacidade
##   exploda descontroladamente nos níveis altos.
const CAPACITY_GEOMETRIC_BASE: int = 24
const CAPACITY_GEOMETRIC_FACTOR: int = 3
const CAPACITY_GEOMETRIC_LEVELS: int = 7  # níveis 1 a 7 usam a progressão geométrica


static func storage_capacity(level: int) -> int:
	assert(level >= 1, "Deposits: nível deve ser >= 1.")

	if level <= CAPACITY_GEOMETRIC_LEVELS:
		return CAPACITY_GEOMETRIC_BASE * int(pow(CAPACITY_GEOMETRIC_FACTOR, level - 1))

	var value_at_geometric_cap: int = CAPACITY_GEOMETRIC_BASE * int(pow(CAPACITY_GEOMETRIC_FACTOR, CAPACITY_GEOMETRIC_LEVELS - 1))
	var value_at_previous_level: int = CAPACITY_GEOMETRIC_BASE * int(pow(CAPACITY_GEOMETRIC_FACTOR, CAPACITY_GEOMETRIC_LEVELS - 2))
	var increment: int = value_at_geometric_cap - value_at_previous_level

	return value_at_geometric_cap + (level - CAPACITY_GEOMETRIC_LEVELS) * increment
