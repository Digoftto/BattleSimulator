class_name EnemyArmyEntry
extends RefCounted
## EnemyArmyEntry
##
## Um Exército Inimigo gerado pelo Pipeline, com seu WR já calculado
## (ou ainda não, durante a etapa de geração). Apenas dado — nenhuma
## lógica.

enum Category { NORMAL, CHEFE_NORMAL, CHEFE_REGIONAL, CHEFE_DE_MINA }

var id: String = ""
var army_name: String = ""
var faction: String = ""
var category: Category = Category.NORMAL

## Região mínima/máxima (1, 2 ou 3 — Região I/II/III da Trilha) em que
## este Exército pode ser utilizado.
var region_min: int = 1
var region_max: int = 1

var cards: Array[CardResource] = []

## Sempre presente, mesmo para a categoria Normal — necessário para que
## CombatEngine valide Soldo/Patente (Army.is_ready_for_battle()). Isso
## é uma exigência técnica do motor, não contradiz PvE.md: "Normal: sem
## Comandante" refere-se à ausência de um líder nomeado/Doutrina
## aplicada, não à ausência do objeto técnico exigido pelo Combate.
var commander: CommanderResource

## Taxa de vitória (WR) contra o benchmark da Temporada, 0.0 a 1.0.
## -1.0 = ainda não calculada.
var win_rate: float = -1.0

## Marca entradas geradas especificamente para as 10 primeiras Fases
## de qualquer Trilha (PvE.md, "Exceção das Primeiras Fases") — só
## Comuns, só Tier I. Nunca sorteada fora das Fases 1-10; nunca junto
## de entradas normais na mesma seleção (EnemyArmySelector as separa).
var is_beginner_fase: bool = false
