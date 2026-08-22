class_name TestAffinityCombat
extends RefCounted
## TestAffinityCombat (F-035)
##
## Testes COMPORTAMENTAIS de Afinidade em combate — diferente de
## test_affinity.gd (F-001/Sprint 11), que só valida o cálculo puro de
## Pontos/Níveis (Affinity.gd) sem tocar CombatEngine/CombatState. Aqui
## validamos que os efeitos numericamente especificados em AFFINITY.md
## realmente mudam o resultado de dano/cura/atributos dentro do motor de
## combate (AffinityRuntime + CombatEngine), fechando exatamente a lacuna
## identificada pelo F-034: "dado existe + teste unitário existe ≠
## mecânica de combate existe".
##
## Mesmo padrão de test_heal_target_selection.gd/test_movement_rules.gd:
## CombatState/CombatUnit montados à mão para testes isolados, mais
## CombatEngine.initialize()/_run_turn() para os testes de integração
## que precisam do fluxo real de turno.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-035] Validando integração de Afinidade ao CombatEngine (efeitos, snapshot, hierarquia)...")

	_test_a_snapshot_computes_points_and_levels(ctx)
	_test_b_snapshot_freezes_during_turn_updates_next_turn(ctx)
	_test_c_imperio_level1_esc_bonus_applied_once_at_init(ctx)
	_test_d_imperio_level2_damage_reduction(ctx)
	_test_e_natureza_level1_hp_and_level2_heal_bonus(ctx)
	_test_f_mortos_vivos_level1_and_level2_atk_bonus(ctx)
	_test_g_undead_first_death_pending_then_active_next_turn(ctx)
	_test_h_level3_recognized_without_inventing_extra_effect(ctx)
	_test_i_commander_contributes_affinity_point(ctx)
	_test_j_revived_unit_counted_in_next_snapshot(ctx)
	_test_k_no_effect_when_level_inactive(ctx)
	_test_l_on_off_damage_comparison(ctx)

	return true


static func _build_combat_card(card_name_value: String, faction: String, card_class: String, atk: int, hp: int, esc: int) -> CardResource:
	var card := CardResource.new()
	card.card_name = card_name_value
	card.faction = faction
	card.card_class = card_class
	card.rarity = "Comum"
	card.tier = 1
	card.atk = atk
	card.hp = hp
	card.esc = esc
	return card


## A: Pontos/Nível calculados e escritos no CombatState para os dois
## lados (não só devolvidos por Affinity.gd — precisam estar acessíveis
## em CombatState para o resto do motor consultar).
static func _test_a_snapshot_computes_points_and_levels(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units: Array[CombatUnit] = []
	for i in range(7):
		units.append(CombatUnit.new(_build_combat_card("Imp-%d" % i, "Império", "Corpo a Corpo", 50, 100, 10), 0, (i % 9) + 1))
	state.units = units

	AffinityRuntime.snapshot_turn(state)

	var points: int = state.affinity_points[0]["Império"]
	var level: int = state.affinity_levels[0]["Império"]
	print("  [A] 7 pelotões do Império, sem Comandante -> Pontos: %d | Nível: %d (esperado: 7 / 3)" % [points, level])
	ctx.check(points == 7, "[A] snapshot_turn deve gravar 7 Pontos em state.affinity_points[0]['Império']")
	ctx.check(level == 3, "[A] 7 Pontos deve resultar em Nível 3 em state.affinity_levels[0]['Império']")


## B: dentro do MESMO turno (após uma morte já resolvida), o Nível
## permanece o valor congelado no início daquele turno (AFFINITY.md,
## "Aplicação por Snapshot"); só o snapshot do turno SEGUINTE reflete a
## morte. Army A = exatamente 2 pelotões do Império (Nível 1, no limiar
## mínimo) — a morte de um deles deve derrubar para Nível 0 no turno
## seguinte, nunca no turno em que a morte ocorreu.
static func _test_b_snapshot_freezes_during_turn_updates_next_turn(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.faction = "Natureza"  # não-Império: não soma ponto ao Império, mantendo o teste em exatamente 2 pontos
	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = []
	cards_a.append(_build_combat_card("Imp-Fraco", "Império", "Corpo a Corpo", 10, 1, 0))  # HP 1: morre no primeiro golpe
	for i in range(8):
		cards_a.append(_build_combat_card("Imp-%d" % i, "Império", "Corpo a Corpo", 10, 500, 0))
	army_a.cards = cards_a

	var commander_b := CommanderResource.new()
	commander_b.faction = "Natureza"
	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("Nat-%d" % i, "Natureza", "Corpo a Corpo", 999, 500, 0))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 42)
	# Reduz a formação de A a exatamente 2 pelotões do Império vivos: um
	# fadado a morrer no Turno 1 (Posição 1, alvo do espelho de B, Classe
	# Corpo a Corpo só ataca a partir da própria Linha 1) e outro mantido
	# fora do alcance de qualquer ataque nesta configuração (Posição 9 —
	# army_b é inteiramente Corpo a Corpo, que não ataca fora da própria
	# Linha 1; mesmo avançando um passo por Movimentação, não alcançaria
	# a Linha 1 no mesmo turno), para isolar exatamente 1 morte.
	var weak_unit: CombatUnit = null
	var survivor_unit: CombatUnit = null
	for unit: CombatUnit in state.units:
		if unit.side != 0:
			continue
		if unit.card.card_name == "Imp-Fraco":
			weak_unit = unit
		elif unit.card.card_name == "Imp-0":
			survivor_unit = unit
		else:
			unit.is_alive = false
	weak_unit.position = 1
	survivor_unit.position = 9
	# A Inicialização já rodou com os 9 pelotões originais (Nível 3 do
	# Império, 9 Pontos) e aplicou o bônus de Afinidade I (+25 ESC) a
	# weak_unit antes desta redução manual da formação — zera aqui para
	# que o único ataque que weak_unit sofre no Turno 1 atinja o HP
	# (Escudo > 0 absorve o golpe inteiro nesta mesma ação, sem sobra
	# para o HP, COMBAT_RULES.md 4.1) e efetivamente o elimine.
	weak_unit.current_esc = 0

	AffinityRuntime.snapshot_turn(state)  # re-snapshot após reduzir a formação manualmente acima
	var level_before: int = AffinityRuntime.level_for(state, 0, "Império")
	print("  [B] Antes do Turno 1: 2 pelotões do Império vivos -> Nível: %d (esperado: 1)" % level_before)
	ctx.check(level_before == 1, "[B] 2 Pontos deve dar Nível 1 antes de qualquer morte")

	CombatEngine._run_turn(state)

	var level_still_frozen: int = AffinityRuntime.level_for(state, 0, "Império")
	print("  [B] Logo após o Turno 1 (a morte já ocorreu na Resolução das Mortes) -> Nível ainda: %d (esperado: 1, congelado)" % level_still_frozen)
	ctx.check(level_still_frozen == 1, "[B] O Nível não deve mudar DENTRO do turno em que a morte ocorreu (snapshot congelado)")

	CombatEngine._run_turn(state)

	var level_after_next_turn: int = AffinityRuntime.level_for(state, 0, "Império")
	print("  [B] Após o snapshot do Turno seguinte -> Nível: %d (esperado: 0, só restou 1 pelotão)" % level_after_next_turn)
	ctx.check(level_after_next_turn == 0, "[B] Só o snapshot do turno SEGUINTE deve refletir a morte (1 Ponto < limiar de 2)")


## C: Afinidade I do Império (+25 ESC Base) aplicada uma única vez, no
## momento da Inicialização — antes de qualquer turno rodar.
static func _test_c_imperio_level1_esc_bonus_applied_once_at_init(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.faction = "Império"
	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = []
	for i in range(9):
		cards_a.append(_build_combat_card("Imp-%d" % i, "Império", "Corpo a Corpo", 50, 200, 30))
	army_a.cards = cards_a

	var commander_b := CommanderResource.new()
	commander_b.faction = "Natureza"
	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("Nat-%d" % i, "Natureza", "Corpo a Corpo", 50, 200, 30))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 7)
	var sample: CombatUnit = state.unit_at(0, 1)
	print("  [C] ESC de um pelotão do Império após Inicialização: %d (esperado: %d = 30 base + 25 Afinidade I)" % [sample.current_esc, 30 + 25])
	ctx.check(sample.current_esc == 30 + 25, "[C] Afinidade I do Império deve somar +25 ESC uma única vez na Inicialização")


## D: Afinidade II do Império (-20%% de dano) só se aplica a pelotões
## cuja Linha OU Coluna esteja 100%% livre de unidades de outra Facção;
## testa o caso qualificado, o caso desqualificado (uma carta estrangeira
## na mesma linha) e a aplicação real em _apply_damage_amount.
static func _test_d_imperio_level2_damage_reduction(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	# Linha 1 inteira do Império (1,2,3) + 2 pelotões extras fora da
	# Linha/Coluna de P1 (posições 4 e 9), garantindo 5 Pontos (Nível 2,
	# limiar 4) que permanecem >= 4 mesmo depois da troca em D3 abaixo —
	# isolando a lógica de Linha/Coluna sem depender de também derrubar
	# o Nível por perda de Pontos.
	var units: Array[CombatUnit] = []
	units.append(CombatUnit.new(_build_combat_card("Imp-1", "Império", "Corpo a Corpo", 50, 200, 0), 0, 1))
	units.append(CombatUnit.new(_build_combat_card("Imp-2", "Império", "Corpo a Corpo", 50, 200, 0), 0, 2))
	units.append(CombatUnit.new(_build_combat_card("Imp-3", "Império", "Corpo a Corpo", 50, 200, 0), 0, 3))
	units.append(CombatUnit.new(_build_combat_card("Imp-4", "Império", "Corpo a Corpo", 50, 200, 0), 0, 4))
	units.append(CombatUnit.new(_build_combat_card("Imp-5", "Império", "Corpo a Corpo", 50, 200, 0), 0, 9))
	state.units = units

	AffinityRuntime.snapshot_turn(state)
	var qualified: CombatUnit = state.unit_at(0, 1)
	print("  [D1] Linha 1 100%% Império, Nível 2 ativo -> multiplicador de dano recebido em P1: %.2f (esperado: 0.80)" % qualified.affinity_incoming_damage_multiplier)
	ctx.check(is_equal_approx(qualified.affinity_incoming_damage_multiplier, 0.8), "[D1] Linha 100%% Império deve conceder -20%% de dano recebido")

	var damage_before: int = qualified.current_hp
	CombatEngine._apply_damage_amount(100.0, qualified)
	var damage_taken: int = damage_before - qualified.current_hp
	print("  [D2] Dano de 100 aplicado -> dano efetivo: %d (esperado: 80)" % damage_taken)
	ctx.check(damage_taken == 80, "[D2] _apply_damage_amount deve efetivamente reduzir 100 -> 80 de dano")

	# Desqualifica P1 por completo: P1 pertence à Linha 1 ([1,2,3]) E à
	# Coluna A ([1,6,7]) — introduz uma carta da Natureza em AMBOS os
	# grupos (Posição 2 corrompe a Linha; Posição 6 corrompe a Coluna),
	# para que o resultado não dependa da interpretação assumida sobre
	# posições vazias (ver docstring de
	# AffinityRuntime._imperio_line_or_column_qualifies): mesmo sob a
	# leitura mais permissiva, nenhum dos dois grupos de P1 pode mais
	# qualificar depois desta mudança.
	var foreign_in_line := CombatUnit.new(_build_combat_card("Nat-Intruso-Linha", "Natureza", "Corpo a Corpo", 50, 200, 0), 0, 2)
	var foreign_in_column := CombatUnit.new(_build_combat_card("Nat-Intruso-Coluna", "Natureza", "Suporte", 50, 200, 0), 0, 6)
	state.units[1] = foreign_in_line
	state.units.append(foreign_in_column)
	AffinityRuntime.snapshot_turn(state)
	var p1_after_intrusion: CombatUnit = state.unit_at(0, 1)
	print("  [D3] Após corromper a Linha 1 (P2) e a Coluna A (P6) de P1 com cartas da Natureza -> multiplicador em P1: %.2f (esperado: 1.00)" % p1_after_intrusion.affinity_incoming_damage_multiplier)
	ctx.check(is_equal_approx(p1_after_intrusion.affinity_incoming_damage_multiplier, 1.0), "[D3] Sem Linha nem Coluna 100%% Império, a redução de dano de P1 deve deixar de se aplicar")


## E: Afinidade I da Natureza (+20 HP Base, uma vez na Inicialização) e
## Afinidade II (primeira cura do turno +10 HP) — sem alterar a seleção
## de alvo de cura do F-033 (_most_injured_ally intocado).
static func _test_e_natureza_level1_hp_and_level2_heal_bonus(ctx: TestRunner.Context) -> void:
	var commander_a := CommanderResource.new()
	commander_a.faction = "Natureza"
	var army_a := Army.new()
	army_a.commander = commander_a
	var cards_a: Array[CardResource] = []
	for i in range(9):
		cards_a.append(_build_combat_card("Nat-%d" % i, "Natureza", "Corpo a Corpo", 50, 200, 10))
	army_a.cards = cards_a

	var commander_b := CommanderResource.new()
	commander_b.faction = "Império"
	var army_b := Army.new()
	army_b.commander = commander_b
	var cards_b: Array[CardResource] = []
	for i in range(9):
		cards_b.append(_build_combat_card("Imp-%d" % i, "Império", "Corpo a Corpo", 50, 200, 10))
	army_b.cards = cards_b

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 11)
	var sample: CombatUnit = state.unit_at(0, 1)
	print("  [E1] HP de um pelotão da Natureza após Inicialização: %d (esperado: %d = 200 base + 20 Afinidade I)" % [sample.current_hp, 200 + 20])
	ctx.check(sample.current_hp == 200 + 20, "[E1] Afinidade I da Natureza deve somar +20 HP uma única vez na Inicialização")

	# Afinidade II (Nível 2 requer 4 Pontos): 4 pelotões da Natureza, sem
	# Comandante, já bastam.
	var healer_state := CombatState.new()
	var target := CombatUnit.new(_build_combat_card("Nat-Ferido", "Natureza", "Corpo a Corpo", 50, 200, 0), 0, 4)
	target.current_hp = 100
	var other: Array[CombatUnit] = [target]
	for i in range(3):
		other.append(CombatUnit.new(_build_combat_card("Nat-%d" % i, "Natureza", "Corpo a Corpo", 50, 200, 0), 0, i + 5))
	healer_state.units = other
	AffinityRuntime.snapshot_turn(healer_state)
	ctx.check(target.affinity_first_heal_bonus_available, "[E2] Com Afinidade II da Natureza ativa, a flag de bônus da primeira cura deve estar disponível")

	var hp_before: int = target.current_hp
	CombatEngine._apply_structural_heal(target)
	var healed: int = target.current_hp - hp_before
	print("  [E2] Cura Estrutural com Afinidade II ativa: %d HP curados (esperado: %d = 20 base + 10 Afinidade II)" % [healed, CombatEngine.STRUCTURAL_HEAL_AMOUNT + 10])
	ctx.check(healed == CombatEngine.STRUCTURAL_HEAL_AMOUNT + 10, "[E2] A primeira cura do turno deve incluir o bônus de +10 HP da Afinidade II")
	ctx.check(not target.affinity_first_heal_bonus_available, "[E2] O bônus deve ser consumido após a primeira cura do turno")

	var hp_before_second: int = target.current_hp
	CombatEngine._apply_structural_heal(target)
	var healed_second: int = target.current_hp - hp_before_second
	print("  [E3] Segunda cura no MESMO turno (bônus já consumido): %d HP curados (esperado: %d, sem bônus)" % [healed_second, CombatEngine.STRUCTURAL_HEAL_AMOUNT])
	ctx.check(healed_second == CombatEngine.STRUCTURAL_HEAL_AMOUNT, "[E3] Uma segunda cura no mesmo turno não deve repetir o bônus")

	# F-033: a SELEÇÃO de alvo continua por menor %% de HP, intocada pela Afinidade.
	var selection_state := CombatState.new()
	var low_percent := CombatUnit.new(_build_combat_card("Nat-40pct", "Natureza", "Corpo a Corpo", 50, 1000, 0), 0, 2)
	low_percent.current_hp = 400
	var high_percent := CombatUnit.new(_build_combat_card("Nat-50pct", "Natureza", "Corpo a Corpo", 50, 500, 0), 0, 3)
	high_percent.current_hp = 250
	selection_state.units = [low_percent, high_percent]
	var selected: CombatUnit = CombatEngine._most_injured_ally(selection_state, 0, [])
	print("  [E4] Seleção de alvo de cura com Afinidade presente: %s (esperado: Nat-40pct, regra do F-033 inalterada)" % (selected.card.card_name if selected != null else "null"))
	ctx.check(selected == low_percent, "[E4] A regra de seleção de alvo do F-033 (menor %% de HP) não deve ser alterada pela Afinidade")


## F: Afinidade I dos Mortos-Vivos (+8 ATK Base) e Afinidade II
## (+5%% do Ataque Base após a primeira morte da Facção no turno anterior).
static func _test_f_mortos_vivos_level1_and_level2_atk_bonus(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var attacker := CombatUnit.new(_build_combat_card("MV-Atacante", "Mortos-Vivos", "Mago", 100, 200, 0), 0, 5)
	var units: Array[CombatUnit] = [attacker]
	for i in range(3):
		units.append(CombatUnit.new(_build_combat_card("MV-%d" % i, "Mortos-Vivos", "Corpo a Corpo", 100, 200, 0), 0, i + 6))
	state.units = units  # 4 pelotões = 4 Pontos = Nível 2 (limiar mínimo)
	AffinityRuntime.snapshot_turn(state)

	var atk_level1_only: float = CombatEngine._effective_attack(attacker, state)
	print("  [F1] ATK efetivo com Nível 2 ativo mas SEM bônus de morte pendente: %.2f (esperado: %.2f = 100 base + 8 Afinidade I)" % [atk_level1_only, 108.0])
	ctx.check(is_equal_approx(atk_level1_only, 108.0), "[F1] Afinidade I dos Mortos-Vivos deve somar +8 ATK Base, mesmo com Nível 2 já ativo (o bônus de morte exige o gatilho, não só o Nível)")

	state.undead_affinity_death_bonus_active[0] = true
	var atk_level1_and_2: float = CombatEngine._effective_attack(attacker, state)
	print("  [F2] ATK efetivo com Afinidade I + II (bônus de morte ativo): %.2f (esperado: %.2f = 100 + 8 + 5%% de 100)" % [atk_level1_and_2, 113.0])
	ctx.check(is_equal_approx(atk_level1_and_2, 113.0), "[F2] Afinidade II dos Mortos-Vivos deve somar +5%% do ATK Base quando ativa")


## G: a primeira morte dos Mortos-Vivos no turno fica PENDENTE e só passa
## a ATIVA no snapshot do turno seguinte — nunca no mesmo turno em que
## ocorreu (ver justificativa em CombatState.undead_affinity_death_bonus_pending).
static func _test_g_undead_first_death_pending_then_active_next_turn(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var dying := CombatUnit.new(_build_combat_card("MV-Morrendo", "Mortos-Vivos", "Corpo a Corpo", 50, 1, 0), 0, 1)
	dying.current_hp = 0
	state.units = [dying]

	CombatEngine._death_resolution_phase(state)
	print("  [G1] Logo após a Resolução das Mortes -> pending: %s | active: %s (esperado: true / false)" % [state.undead_affinity_death_bonus_pending[0], state.undead_affinity_death_bonus_active[0]])
	ctx.check(state.undead_affinity_death_bonus_pending[0] == true, "[G1] A morte deve marcar 'pending' imediatamente")
	ctx.check(state.undead_affinity_death_bonus_active[0] == false, "[G1] 'active' não deve mudar antes do próximo snapshot")

	AffinityRuntime.snapshot_turn(state)
	print("  [G2] Após o snapshot do turno seguinte -> pending: %s | active: %s (esperado: false / true)" % [state.undead_affinity_death_bonus_pending[0], state.undead_affinity_death_bonus_active[0]])
	ctx.check(state.undead_affinity_death_bonus_active[0] == true, "[G2] O snapshot seguinte deve promover 'pending' -> 'active'")
	ctx.check(state.undead_affinity_death_bonus_pending[0] == false, "[G2] 'pending' deve ser reiniciado após a promoção")

	AffinityRuntime.snapshot_turn(state)
	print("  [G3] Sem nova morte, snapshot seguinte -> active: %s (esperado: false, sem novo disparo)" % state.undead_affinity_death_bonus_active[0])
	ctx.check(state.undead_affinity_death_bonus_active[0] == false, "[G3] Sem nova morte no turno anterior, o bônus não deve permanecer ativo indefinidamente")


## H: Nível III é corretamente RECONHECIDO (Pontos/Nível), mas nenhum
## efeito numérico adicional é inventado além do que já está especificado
## em Nível I/II — confirma que o bloqueio de especificação (Valores
## Aprimorados) está sendo respeitado, não contornado.
static func _test_h_level3_recognized_without_inventing_extra_effect(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units: Array[CombatUnit] = []
	for i in range(9):
		units.append(CombatUnit.new(_build_combat_card("Imp-%d" % i, "Império", "Corpo a Corpo", 50, 200, 30), 0, (i % 9) + 1))
	state.units = units
	AffinityRuntime.snapshot_turn(state)

	var level: int = AffinityRuntime.level_for(state, 0, "Império")
	print("  [H1] 9 pelotões do Império -> Nível: %d (esperado: 3)" % level)
	ctx.check(level == 3, "[H1] 9 Pontos deve reconhecer corretamente o Nível 3")

	AffinityRuntime.apply_initial_stat_bonuses(state)
	var sample: CombatUnit = state.unit_at(0, 1)
	print("  [H2] ESC de um pelotão sob Nível 3: %d (esperado: %d, igual ao de Nível 1 — sem 'Valor Aprimorado' inventado)" % [sample.current_esc, 30 + 25])
	ctx.check(sample.current_esc == 30 + 25, "[H2] Nível 3 não deve aplicar nenhum bônus numérico além do já especificado em Nível I (Valores Aprimorados ficam bloqueados)")


## I: o Comandante da mesma Facção soma +1 Ponto de Afinidade (reutiliza
## Affinity.calculate_points via AffinityRuntime, agora dentro do Combat State).
static func _test_i_commander_contributes_affinity_point(ctx: TestRunner.Context) -> void:
	var state_without_commander := CombatState.new()
	state_without_commander.units = [CombatUnit.new(_build_combat_card("Imp-1", "Império", "Corpo a Corpo", 50, 200, 0), 0, 1)]
	AffinityRuntime.snapshot_turn(state_without_commander)
	var level_without: int = AffinityRuntime.level_for(state_without_commander, 0, "Império")

	var state_with_commander := CombatState.new()
	state_with_commander.units = [CombatUnit.new(_build_combat_card("Imp-1", "Império", "Corpo a Corpo", 50, 200, 0), 0, 1)]
	var commander := CommanderResource.new()
	commander.faction = "Império"
	state_with_commander.commander_a = commander
	AffinityRuntime.snapshot_turn(state_with_commander)
	var level_with: int = AffinityRuntime.level_for(state_with_commander, 0, "Império")

	print("  [I] 1 pelotão do Império sem/com Comandante da mesma Facção -> Nível: %d / %d (esperado: 0 / 1)" % [level_without, level_with])
	ctx.check(level_without == 0, "[I] 1 Ponto (sem Comandante) não deve ativar nenhum Nível")
	ctx.check(level_with == 1, "[I] 1 pelotão + Comandante da mesma Facção (2 Pontos) deve ativar o Nível 1")


## J: um pelotão reerguido (ReviveRuntime reverte is_alive para true no
## MESMO CombatUnit, nunca cria um novo) volta a contar normalmente no
## snapshot seguinte — sem nenhuma lógica especial de "invocação", só
## por consultar state.units_of_side(side, true) a cada snapshot.
static func _test_j_revived_unit_counted_in_next_snapshot(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var revived := CombatUnit.new(_build_combat_card("Imp-Reerguido", "Império", "Corpo a Corpo", 50, 200, 0), 0, 1)
	var other := CombatUnit.new(_build_combat_card("Imp-Outro", "Império", "Corpo a Corpo", 50, 200, 0), 0, 2)
	state.units = [revived, other]

	revived.is_alive = false
	AffinityRuntime.snapshot_turn(state)
	var points_while_dead: int = state.affinity_points[0]["Império"]

	revived.is_alive = true  # equivalente ao que ReviveRuntime._on_unit_died() faz
	AffinityRuntime.snapshot_turn(state)
	var points_after_revive: int = state.affinity_points[0]["Império"]

	print("  [J] Pontos com o pelotão morto: %d | após reerguido: %d (esperado: 1 / 2)" % [points_while_dead, points_after_revive])
	ctx.check(points_while_dead == 1, "[J] Um pelotão morto não deve contar Pontos de Afinidade")
	ctx.check(points_after_revive == 2, "[J] Um pelotão reerguido deve voltar a contar no snapshot seguinte, sem lógica especial")


## K: sem Pontos suficientes, nenhum efeito é aplicado — nem o bônus de
## atributo Base (C/E), nem a redução de dano (D), mesmo que a condição
## geométrica de linha/coluna já fosse satisfeita isoladamente.
static func _test_k_no_effect_when_level_inactive(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	# Um único pelotão do Império, sem Comandante: 1 Ponto, abaixo do
	# limiar de Nível 1 (2) — mesmo sozinho "ocupando" a Linha 1 inteira.
	var lone := CombatUnit.new(_build_combat_card("Imp-Sozinho", "Império", "Corpo a Corpo", 50, 200, 30), 0, 1)
	state.units = [lone]
	AffinityRuntime.snapshot_turn(state)

	print("  [K] 1 pelotão isolado do Império -> multiplicador de dano: %.2f (esperado: 1.00, Nível 0)" % lone.affinity_incoming_damage_multiplier)
	ctx.check(is_equal_approx(lone.affinity_incoming_damage_multiplier, 1.0), "[K] Sem Nível 2 ativo, a redução de dano não deve ser aplicada mesmo com a linha 'exclusivamente Império'")

	AffinityRuntime.apply_initial_stat_bonuses(state)
	print("  [K] ESC após apply_initial_stat_bonuses: %d (esperado: %d, sem bônus)" % [lone.current_esc, 30])
	ctx.check(lone.current_esc == 30, "[K] Sem Nível 1 ativo, o bônus de +25 ESC não deve ser aplicado")


## L: comparação direta ON vs OFF sobre a MESMA função de dano do
## CombatEngine (_apply_damage_amount) — prova que a Afinidade realmente
## muda o resultado do motor, não só o cálculo isolado de Affinity.gd.
static func _test_l_on_off_damage_comparison(ctx: TestRunner.Context) -> void:
	var target_off := CombatUnit.new(_build_combat_card("Alvo-Off", "Império", "Corpo a Corpo", 0, 1000, 0), 0, 1)
	target_off.affinity_incoming_damage_multiplier = 1.0  # Afinidade II OFF (Nível < 2, ou linha/coluna não qualifica)
	CombatEngine._apply_damage_amount(150.0, target_off)

	var target_on := CombatUnit.new(_build_combat_card("Alvo-On", "Império", "Corpo a Corpo", 0, 1000, 0), 0, 1)
	target_on.affinity_incoming_damage_multiplier = 0.8  # Afinidade II ON
	CombatEngine._apply_damage_amount(150.0, target_on)

	var hp_lost_off: int = 1000 - target_off.current_hp
	var hp_lost_on: int = 1000 - target_on.current_hp
	print("  [L] Mesmo ataque (150) -> Afinidade OFF: %d dano | Afinidade ON: %d dano (esperado: 150 / 120)" % [hp_lost_off, hp_lost_on])
	ctx.check(hp_lost_off == 150, "[L] Afinidade OFF não deve alterar o dano")
	ctx.check(hp_lost_on == 120, "[L] Afinidade ON (Nível 2 do Império) deve reduzir o mesmo ataque em 20%%")
	ctx.check(hp_lost_on < hp_lost_off, "[L] A Afinidade deve produzir uma diferença MENSURÁVEL no resultado do combate real (CombatEngine), não só no cálculo isolado de Pontos/Nível")
