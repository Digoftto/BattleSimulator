class_name TestHealTargetSelection
extends RefCounted
## TestHealTargetSelection (F-033)
##
## Valida a nova regra de seleção de alvo de Cura Estrutural
## (CombatEngine._most_injured_ally()): prioriza o MENOR PERCENTUAL de
## HP restante (current_hp / card.hp), não o maior déficit ABSOLUTO —
## substituindo a regra anterior, que podia fazer uma unidade de HP
## máximo alto monopolizar a cura mesmo estando proporcionalmente menos
## ferida. Desempate: menor número de posição (mais perto da Posição
## 1) — decisão explícita do proprietário (F-033 §3), não
## OFFICIAL_RESOLUTION_ORDER (que é uma ordem de resolução de ações
## simultâneas, não de proximidade à Posição 1).
##
## Testa CombatEngine._most_injured_ally() diretamente — mesmo padrão
## já estabelecido em test_movement_rules.gd (CombatEngine._can_advance()/
## _movement_phase() chamados diretamente com um CombatState montado à
## mão).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-033] Validando a nova regra de seleção de alvo de cura (menor % de HP, desempate por posição)...")

	_test_a_percentage_beats_absolute_deficit(ctx)
	_test_b_lowest_percentage_wins(ctx)
	_test_c_tie_breaks_by_position(ctx)
	_test_d_tie_among_three_breaks_by_lowest_position(ctx)
	_test_e_dead_unit_never_selected(ctx)
	_test_f_full_hp_unit_never_selected(ctx)
	_test_g_heal_amount_unchanged(ctx)

	return true


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


## A: 1000 max / 400 current = 40% | B: 500 max / 250 current = 50%
## -> A (menor percentual), apesar do déficit ABSOLUTO de A (600) ser
## maior que o de B (250) — exatamente o caso que a regra antiga
## acertava ao contrário.
static func _test_a_percentage_beats_absolute_deficit(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_a := CombatUnit.new(_build_combat_card("A", "Corpo a Corpo", 100, 1000, 0), 0, 2)
	unit_a.current_hp = 400
	var unit_b := CombatUnit.new(_build_combat_card("B", "Corpo a Corpo", 100, 500, 0), 0, 3)
	unit_b.current_hp = 250
	state.units = [unit_a, unit_b]

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [A] A=400/1000(40%%) B=250/500(50%%) -> alvo escolhido: %s (esperado: A)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == unit_a, "[A] Deve curar A (40%%), não B (50%%), mesmo A tendo déficit ABSOLUTO maior (600 vs 250)")


## A: 1000/300 = 30% | B: 500/200 = 40% -> A
static func _test_b_lowest_percentage_wins(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_a := CombatUnit.new(_build_combat_card("A", "Corpo a Corpo", 100, 1000, 0), 0, 2)
	unit_a.current_hp = 300
	var unit_b := CombatUnit.new(_build_combat_card("B", "Corpo a Corpo", 100, 500, 0), 0, 3)
	unit_b.current_hp = 200
	state.units = [unit_a, unit_b]

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [B] A=300/1000(30%%) B=200/500(40%%) -> alvo escolhido: %s (esperado: A)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == unit_a, "[B] Deve curar A (30%%), o menor percentual")


## P1: 1000/400 = 40% | P2: 500/200 = 40% -> P1 (empate, desempate por posição)
static func _test_c_tie_breaks_by_position(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_p1 := CombatUnit.new(_build_combat_card("EmP1", "Corpo a Corpo", 100, 1000, 0), 0, 1)
	unit_p1.current_hp = 400
	var unit_p2 := CombatUnit.new(_build_combat_card("EmP2", "Corpo a Corpo", 100, 500, 0), 0, 2)
	unit_p2.current_hp = 200
	state.units = [unit_p2, unit_p1]  # ordem proposital: P2 primeiro no Array, pra provar que não é "primeiro do Array"

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [C] P1=400/1000(40%%) P2=200/500(40%%), empate -> alvo escolhido: %s (esperado: EmP1, posição 1)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == unit_p1, "[C] Empate de percentual deve ser desempatado pela menor posição (P1 antes de P2)")


## P2=40% P5=40% P8=40% -> P2 (menor posição entre as 3 empatadas)
static func _test_d_tie_among_three_breaks_by_lowest_position(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_p8 := CombatUnit.new(_build_combat_card("EmP8", "Suporte", 40, 100, 0), 0, 8)
	unit_p8.current_hp = 40
	var unit_p2 := CombatUnit.new(_build_combat_card("EmP2", "Corpo a Corpo", 100, 100, 0), 0, 2)
	unit_p2.current_hp = 40
	var unit_p5 := CombatUnit.new(_build_combat_card("EmP5", "Mago", 100, 100, 0), 0, 5)
	unit_p5.current_hp = 40
	state.units = [unit_p8, unit_p5, unit_p2]  # ordem embaralhada de propósito

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [D] P2=40%% P5=40%% P8=40%%, todos empatados -> alvo escolhido: %s (esperado: EmP2, menor posição)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == unit_p2, "[D] Entre 3 unidades empatadas em percentual, deve escolher a de menor posição (P2)")


## Unidade morta (is_alive = false) nunca pode ser escolhida — já
## garantido estruturalmente por state.units_of_side() (alive_only=true
## por padrão), mas validado explicitamente aqui como regressão.
static func _test_e_dead_unit_never_selected(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_dead := CombatUnit.new(_build_combat_card("Morta", "Corpo a Corpo", 100, 1000, 0), 0, 1)
	unit_dead.current_hp = 0
	unit_dead.is_alive = false
	var unit_alive := CombatUnit.new(_build_combat_card("Viva", "Corpo a Corpo", 100, 500, 0), 0, 5)
	unit_alive.current_hp = 100
	state.units = [unit_dead, unit_alive]

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [E] Uma unidade morta (P1, 0%% HP) e uma viva ferida (P5, 20%% HP) -> alvo escolhido: %s (esperado: Viva, nunca a morta)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == unit_alive, "[E] Uma unidade morta nunca deve ser escolhida como alvo de cura, mesmo tecnicamente tendo 0%% de HP")


## Unidade com HP cheio nunca é selecionada (mesmo sendo a única
## presente) — retorna null quando ninguém precisa de cura.
static func _test_f_full_hp_unit_never_selected(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var unit_full := CombatUnit.new(_build_combat_card("CheioDeHP", "Corpo a Corpo", 100, 500, 0), 0, 1)
	unit_full.current_hp = 500
	state.units = [unit_full]

	var target: CombatUnit = CombatEngine._most_injured_ally(state, 0, [])
	print("  [F] Única unidade presente está com HP cheio -> alvo escolhido: %s (esperado: null, ninguém precisa de cura)" % (target.card.card_name if target != null else "null"))
	ctx.check(target == null, "[F] Uma unidade com HP cheio nunca deve ser selecionada como alvo de cura")


## G: a MUDANÇA é só na seleção do ALVO — a quantidade de Cura
## Estrutural continua exatamente a mesma (STRUCTURAL_HEAL_AMOUNT,
## nunca tocado neste estágio). Roda uma batalha real curta e confirma
## que uma cura observada aplica exatamente o valor de sempre.
##
## O pelotão ferido fica na Posição 4 (Linha 2), nunca na Posição 1 —
## de propósito: army_b é inteiramente Corpo a Corpo, que só ataca via
## espelho quando o PRÓPRIO atacante está na Linha 1 (1-3); um pelotão
## de army_a na Posição 4 nunca é alvo de ataque nesta configuração,
## isolando o efeito da cura sem o confundir com dano recebido no
## mesmo turno.
static func _test_g_heal_amount_unchanged(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Cura)"
	commander_a.faction = "Império"
	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Cura)"
	commander_b.faction = "Natureza"

	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = []
	for i in range(9):
		cards_a.append(_build_combat_card("A-%d" % i, "Corpo a Corpo", 50, 200, 20))
	cards_a[8] = _build_combat_card("A-Suporte", "Suporte", 30, 100, 10)
	army_a.cards = cards_a

	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("B-%d" % i, "Corpo a Corpo", 50, 200, 20))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 1)
	var wounded_unit: CombatUnit = state.unit_at(0, 4)
	wounded_unit.current_hp = 150  # 200 max, deixa espaço pra curar sem estourar o teto

	CombatEngine._run_turn(state)

	var healed_amount: int = wounded_unit.current_hp - 150
	print("  [G] Cura Estrutural aplicada nesta rodada (Posição 4, fora de alcance de ataque nesta configuração): %d HP (esperado: 20, STRUCTURAL_HEAL_AMOUNT inalterado)" % healed_amount)
	ctx.check(healed_amount == CombatEngine.STRUCTURAL_HEAL_AMOUNT, "[G] A quantidade de Cura Estrutural não deve mudar — só a seleção do alvo (obtido: %d, esperado: %d)" % [healed_amount, CombatEngine.STRUCTURAL_HEAL_AMOUNT])
