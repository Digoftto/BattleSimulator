class_name Battlefield
extends RefCounted
## Battlefield
##
## Lógica pura do sorteio de Campo de Batalha (BATTLEFIELDS.md), ponderado
## pela Frequência oficial de cada Campo. Reutiliza WeightedRandom (já
## implementado na Sprint 5) — não duplica lógica de sorteio.
##
## Não implementa aplicação de modificadores, Plano de Campanha, seleção
## automática de Exército, Combate ou Interface.


## Sorteia um Campo de Batalha entre os candidatos informados, com
## probabilidade proporcional à Frequência oficial de cada um. "rng" é
## opcional — mesmo motivo de WeightedRandom.pick(): use o RNG próprio
## da batalha (CombatState.rng) sempre que rodar de dentro do combate.
static func draw(battlefields: Array[BattlefieldResource], rng: RandomNumberGenerator = null) -> BattlefieldResource:
	return WeightedRandom.pick(battlefields, func(b: BattlefieldResource) -> int:
		return int(b.frequency_percent)
	, rng)
