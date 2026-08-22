class_name TestInvestida
extends RefCounted
## TestInvestida (F-001, Etapa 8)
##
## Migrado de bootstrap.gd:_validate_investida() (Sprint 21). Mesmo
## cenário original — monta um cenário determinístico em que a carta real
## do catálogo com "Investida" (Legionário Imperial) inicia fora da Linha
## 1, avança até ela ao longo da batalha e ativa a habilidade em seu
## primeiro ataque a partir dali — validando toda a cadeia CombatEngine ->
## CombatEventBus -> AbilityRuntime -> InvestidaRuntime -> CombatContext
## -> CombatEngine, com dado real.
##
## Auditoria de Stage 8 (READ-ONLY) confirmou este cenário determinístico
## na composição atual: nenhum RNG é exercitado por InvestidaRuntime, e o
## único ponto de RNG de CombatEngine (sorteio de Campo de Batalha, em
## CombatState.rng) é inerte aqui porque nenhum dos Comandantes de teste
## define .doctrine (permanece null), então CommanderDoctrineValidator.
## check_battlefield() sempre retorna "" independentemente do Campo
## sorteado. Nenhuma seed foi introduzida — o comportamento original é
## preservado exatamente como estava.
##
## _build_combat_card() é cópia do helper de mesmo nome em bootstrap.gd —
## compartilhado com validações ainda não migradas (_validate_combat_engine,
## _validate_mining_incremental_estimation), portanto NÃO removido de lá.
##
## O teste original não tinha "(esperado: X)" explícito — é inteiramente
## narrativo (o próprio history_log/battle_log é a evidência, lido por um
## humano). Nenhuma asserção nova foi adicionada.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Investida] Validando cadeia completa com dado real do catálogo (Legionário Imperial)...")

	var real_card: CardResource = null
	for c: CardResource in GameDatabase.cards:
		if c.card_name == "Legionário Imperial":
			real_card = c
			break

	if real_card == null:
		push_warning("[Bootstrap] Carta real 'Legionário Imperial' não encontrada para validar Investida.")
		return true

	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Investida)"
	commander_a.faction = "Império"

	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Investida)"
	commander_b.faction = "Natureza"

	# Exército A: 3 batedores fracos (posições 1-3, devem morrer no Turno 1
	# para abrir caminho na Coluna C), o Legionário Imperial real na
	# posição 4 (avança para a posição 3 no Turno 2 e ativa Investida),
	# e 5 unidades de preenchimento para completar a Formação.
	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		_build_combat_card("A-Batedor-1", "Corpo a Corpo", 1, 1, 0),
		_build_combat_card("A-Batedor-2", "Corpo a Corpo", 1, 1, 0),
		_build_combat_card("A-Batedor-3", "Corpo a Corpo", 1, 1, 0),
		real_card,
		_build_combat_card("A-Reserva-5", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-6", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-7", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-8", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("A-Reserva-9", "Corpo a Corpo", 1, 50, 0),
	]

	# Exército B: linha de frente forte o suficiente para eliminar os
	# batedores de A no Turno 1 (abrindo a Coluna C), sem nenhuma
	# Habilidade envolvida.
	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = [
		_build_combat_card("B-Forte-1", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Forte-2", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Forte-3", "Corpo a Corpo", 300, 500, 0),
		_build_combat_card("B-Reserva-4", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-5", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-6", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-7", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-8", "Corpo a Corpo", 1, 50, 0),
		_build_combat_card("B-Reserva-9", "Corpo a Corpo", 1, 50, 0),
	]

	var state: CombatState = CombatEngine.initialize(
		army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	var test_unit: CombatUnit = null
	for unit: CombatUnit in state.units_of_side(0):
		if unit.card.card_name == "Legionário Imperial":
			test_unit = unit
			break

	var investida_instance: AbilityInstance = null
	for instance: AbilityInstance in state.effect_runtime.get_abilities(test_unit):
		if instance.resource.ability_name == "Investida":
			investida_instance = instance
			break

	print("  Runtime especializado encontrado: %s" % ("sim" if investida_instance != null and investida_instance.specialized_runtime != null else "não"))

	CombatEngine.run(state)

	for line: String in state.battle_log:
		print("  " + line)

	var runtime: InvestidaRuntime = investida_instance.specialized_runtime as InvestidaRuntime
	print("[Investida] Entrou na Linha 1: %s | Consumida (ativação única): %s" % [
		str(runtime.has_entered_frontline()), str(runtime.is_consumed())
	])
	print("[Investida] Batalha concluída em %d turno(s). Motivo: %s." % [state.turn, state.end_reason])

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
