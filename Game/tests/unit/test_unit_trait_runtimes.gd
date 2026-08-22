class_name TestUnitTraitRuntimes
extends RefCounted
## TestUnitTraitRuntimes (F-001, Etapa 8)
##
## Migrado de bootstrap.gd:_validate_unit_trait_runtimes() (Sprint 25).
## Mesmo cenário original — monta um cenário usando exclusivamente cartas
## reais do catálogo, cada uma portando uma das 4 Características de
## Unidade implementadas (Reerguer, Fome Eterna, Sacrifício de Carne,
## Colheita de Almas), executa uma batalha completa e imprime o
## history_log. Cada Runtime imprime sua própria ativação — a evidência
## de "cenário reproduzível" é o próprio history_log.
##
## _build_combat_card() é cópia do helper de mesmo nome em bootstrap.gd —
## compartilhado com validações ainda não migradas (_validate_combat_engine,
## _validate_mining_incremental_estimation), portanto NÃO removido de lá.
##
## O teste original não tinha "(esperado: X)" explícito — é inteiramente
## narrativo (o próprio history_log é a evidência, lido por um humano).
## Nenhuma asserção nova foi adicionada; os logs informativos originais
## são preservados exatamente como estavam.

static func run(ctx: TestRunner.Context) -> bool:
	print("[UnitTraitRuntime] Validando Características de Unidade (Sprint 25)...")

	var real_esqueleto: CardResource = GameDatabase.get_card("Esqueleto Guerreiro")     # Reerguer
	var real_abominacao: CardResource = GameDatabase.get_card("Abominação Putrefata")    # Sacrifício de Carne
	var real_arqueiro: CardResource = GameDatabase.get_card("Arqueiro Esquelético")      # Fome Eterna
	var real_ceifadora: CardResource = GameDatabase.get_card("Ceifadora Espectral")      # Colheita de Almas (parcial)

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Características de Unidade)"
	commander_a.faction = "Mortos-Vivos"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Características de Unidade)"
	commander_b.faction = "Império"

	# Posição 4 é o aliado "atrás" de Abominação Putrefata (posição 3,
	# mesma coluna C) — necessário para demonstrar Sacrifício de Carne.
	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		real_esqueleto,
		_build_combat_card("A-Filler-2", "Corpo a Corpo", 60, 90, 10),
		real_abominacao,
		_build_combat_card("A-Filler-4", "Corpo a Corpo", 1, 150, 0),
		real_arqueiro,
		_build_combat_card("A-Filler-6", "Corpo a Corpo", 60, 90, 10),
		real_ceifadora,
		_build_combat_card("A-Filler-8", "Corpo a Corpo", 60, 90, 10),
		_build_combat_card("A-Filler-9", "Corpo a Corpo", 60, 90, 10),
	]

	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-CQC-1", "Corpo a Corpo", 110, 90, 0),
		_build_combat_card("B-CQC-2", "Corpo a Corpo", 90, 90, 0),
		_build_combat_card("B-CQC-3", "Corpo a Corpo", 110, 90, 0),
		_build_combat_card("B-Filler-4", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Distancia-1", "À Distância", 90, 70, 10),
		_build_combat_card("B-Filler-6", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-7", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-8", "Corpo a Corpo", 60, 90, 0),
		_build_combat_card("B-Filler-9", "Corpo a Corpo", 60, 90, 0),
	]

	print("  Exército A pronto: %s | Exército B pronto: %s" % [
		"sim" if army_a.is_ready_for_battle() else "não",
		"sim" if army_b.is_ready_for_battle() else "não"
	])

	var state: CombatState = CombatEngine.run_battle(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	for line: String in state.battle_log:
		print("  " + line)

	print("[UnitTraitRuntime] Batalha concluída em %d turno(s). Motivo: %s. Vencedor: %s" % [
		state.turn, state.end_reason, ("empate" if state.winner_side == -1 else "Lado %d" % state.winner_side)
	])
	print("[UnitTraitRuntime] Verifique acima as linhas [ReviveRuntime] e [ReactiveTraitRuntime] —")
	print("  cada uma confirma a ativação da Característica correspondente (Reerguer, Fome Eterna,")
	print("  Sacrifício de Carne, Colheita de Almas — esta última apenas com a cura, sem o bônus permanente).")
	print("[UnitTraitRuntime] 'Fonte da Vida' não foi implementada nesta Sprint — ver limitação encontrada na entrega.")

	return true


## Cria uma carta transitória (não persistida no catálogo) para validação
## do Motor de Combate, com atributos de combate explícitos. Cópia do
## helper de mesmo nome em bootstrap.gd — compartilhado com validações
## ainda não migradas, portanto NÃO removido de lá.
static func _build_combat_card(card_name_value: String, card_class: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.card_class = card_class
	card.faction = "Império"
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card
