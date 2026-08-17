class_name BattlefieldSelector
extends RefCounted
## BattlefieldSelector (BATTLEFIELDS.md, "Sorteio")
##
## Sorteia um Campo de Batalha respeitando as frequências definidas
## (64% Campo Aberto, 4% cada um dos 9 Especiais). "Independência: Um
## novo Campo de Batalha é sorteado para cada batalha. O sorteio é
## independente e não leva em consideração batalhas anteriores" — por
## isso esta função é sem estado, cada chamada é um sorteio novo.
##
## Determinística com RandomNumberGenerator + seed explícita (mesmo
## padrão do resto do projeto) — a mesma seed sempre produz o mesmo
## resultado, útil pra testes e replays.


## Sorteia 1 Campo de Batalha entre "battlefields", ponderado por
## frequency_percent. Soma os pesos dos itens recebidos (não assume
## 100 fixo) — assim funciona tanto para a lista completa (que soma
## 100, BATTLEFIELDS.md) quanto para um subconjunto restrito (ex:
## Campos cujo Exército mapeado ainda tem energia — COMMAND_CENTER.md,
## "Ataque: Restrito pela Energia Disponível").
static func select(battlefields: Array[BattlefieldResource], rng: RandomNumberGenerator) -> BattlefieldResource:
	assert(not battlefields.is_empty(), "BattlefieldSelector: lista de Campos de Batalha vazia.")

	var total: float = 0.0
	for battlefield: BattlefieldResource in battlefields:
		total += battlefield.frequency_percent

	var roll: float = rng.randf() * total
	var cumulative: float = 0.0
	for battlefield: BattlefieldResource in battlefields:
		cumulative += battlefield.frequency_percent
		if roll < cumulative:
			return battlefield

	return battlefields[-1]  # segurança contra erro de arredondamento de ponto flutuante
