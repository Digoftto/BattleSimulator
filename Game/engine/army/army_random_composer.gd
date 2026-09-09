class_name ArmyRandomComposer
extends RefCounted
## ArmyRandomComposer
##
## Heurística de composição aleatória de Exército — extraída de
## army_editor_panel.gd::_random_valid_composition() (mesmo corpo, byte-a-
## byte) para ser reaproveitada também pelo Campo de Prova
## (CAMPO_DE_PROVA.md), sem duplicar a lógica. Mesma técnica de
## EnemyArmyGenerator.build_composition()/_pick_unique_by_name():
## embaralha, preenche respeitando Unicidade de Nome (ARMY.md), testa o
## Soldo total contra o teto, tenta de novo com outro embaralhamento se
## estourar.
##
## Não decide DE ONDE vem "pool" (Kingdom.cards, GameDatabase.cards ou
## qualquer outro conjunto de CardResource) — quem chama decide a origem;
## esta função só resolve "9 Cartas de Nomes distintos dentro do teto de
## Soldo", a mesma regra em qualquer contexto.

const MAX_ATTEMPTS: int = 300


## Retorna [] se nenhuma tentativa couber no teto — nunca uma composição
## parcial/inválida.
static func random_valid_composition(pool: Array[CardResource], soldo_cap: int) -> Array[CardResource]:
	var attempts: int = 0
	while attempts < MAX_ATTEMPTS:
		var shuffled: Array[CardResource] = pool.duplicate()
		shuffled.shuffle()

		var chosen: Array[CardResource] = []
		var used_names: Array[String] = []
		for card: CardResource in shuffled:
			if chosen.size() >= 9:
				break
			if used_names.has(card.card_name):
				continue
			chosen.append(card)
			used_names.append(card.card_name)

		if chosen.size() == 9 and Soldo.total_for_composition(chosen) <= soldo_cap:
			return chosen
		attempts += 1
	return []
