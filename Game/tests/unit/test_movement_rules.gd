class_name TestMovementRules
extends RefCounted
## TestMovementRules (F-001, Etapa 8)
##
## Migrado de bootstrap.gd:_validate_movement_rules() (COMBAT_RULES.md
## 5.2/6.5/6.6, F-016/F-017 finalizados). Mesmo cenário original — Máquina
## de Guerra tem restrição de posicionamento apenas INICIAL (posição 9) e
## depois avança normalmente; Suporte segue a Cadeia de Bloqueio
## (Suporte/Máquina de Guerra nunca bloqueiam — Máquina de Guerra é opaca
## à cadeia, Suporte é transparente — qualquer outra Classe bloqueia);
## Penalidade de Reorganização (5.2.2) só dispara ao CHEGAR na Posição 5
## via movimento, nunca para quem já inicia ali.
##
## _build_combat_card() é cópia do helper de mesmo nome em bootstrap.gd —
## compartilhado com validações ainda não migradas (_validate_combat_engine,
## _validate_mining_incremental_estimation), portanto NÃO removido de lá.
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Movimento] Validando Máquina de Guerra, Cadeia de Bloqueio do Suporte e Penalidade de Reorganização...")

	# --- A: Máquina de Guerra inicia sempre na Posição 9 (via Army/CombatEngine real) ---
	var commander_a := CommanderResource.new()
	commander_a.commander_name = "Comandante A (Movimento)"
	commander_a.faction = "Império"
	var commander_b := CommanderResource.new()
	commander_b.commander_name = "Comandante B (Movimento)"
	commander_b.faction = "Natureza"

	var army_a := Army.new()
	army_a.commander = commander_a
	army_a.cards = [
		_build_combat_card("A-MdG", "Máquina de Guerra", 100, 100, 20),  # de propósito, não no fim do Array
		_build_combat_card("A-CQC-1", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-CQC-2", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-CQC-3", "Corpo a Corpo", 100, 100, 20),
		_build_combat_card("A-Distancia-1", "À Distância", 80, 70, 10),
		_build_combat_card("A-Distancia-2", "À Distância", 80, 70, 10),
		_build_combat_card("A-Barreira", "Barreira", 50, 120, 60),
		_build_combat_card("A-Mago", "Mago", 90, 60, 0),
		_build_combat_card("A-Suporte", "Suporte", 30, 80, 10),
	]
	var army_b := Army.new()
	army_b.commander = commander_b
	army_b.cards = []
	for i in range(9):
		army_b.cards.append(_build_combat_card("B-Filler-%d" % i, "Corpo a Corpo", 50, 50, 10))

	var init_state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits)
	var unit_at_9: CombatUnit = init_state.unit_at(0, 9)
	print("  A) Máquina de Guerra ocupa a Posição 9 mesmo não sendo a última carta do Array? %s (esperado: true)" % str(
		unit_at_9 != null and unit_at_9.card.card_class == "Máquina de Guerra"
	))
	ctx.check(unit_at_9 != null and unit_at_9.card.card_class == "Máquina de Guerra", "A) Máquina de Guerra deve ocupar a Posição 9 mesmo não sendo a última carta do Array")

	# --- B: Máquina de Guerra pode avançar após o início do combate ---
	# Bloqueador na Posição 3 (frente da Coluna C) de propósito, pra
	# isolar exatamente 1 passo de avanço — sem ele, "avança até a
	# posição livre mais próxima" (5.2.1) levaria a MdG direto até a
	# Posição 3 na mesma Fase, o que também está correto, mas testaria
	# duas coisas ao mesmo tempo.
	var mdg_state := CombatState.new()
	var mdg_card: CardResource = _build_combat_card("Teste-MdG", "Máquina de Guerra", 100, 100, 20)
	var mdg_unit := CombatUnit.new(mdg_card, 0, 9)  # Posição 4 (coluna C) livre de propósito
	var mdg_blocker := CombatUnit.new(_build_combat_card("Teste-Bloqueador", "Barreira", 50, 100, 50), 0, 3)
	mdg_state.units = [mdg_unit, mdg_blocker]
	print("  B) Máquina de Guerra pode avançar (posição 4 livre)? %s (esperado: true)" % str(
		CombatEngine._can_advance(mdg_state, mdg_unit)
	))
	ctx.check(CombatEngine._can_advance(mdg_state, mdg_unit) == true, "B) Máquina de Guerra deve poder avançar com a posição 4 livre")
	CombatEngine._movement_phase(mdg_state)
	print("     Avançou de 9 para 4 de verdade (parou ali por causa do bloqueador na Posição 3)? %s (posição atual: %d, esperado: 4)" % [
		str(mdg_unit.position == 4), mdg_unit.position
	])
	ctx.check(mdg_unit.position == 4, "B) Máquina de Guerra deve avançar de 9 para 4 e parar no bloqueador da Posição 3 (obtido: %d)" % mdg_unit.position)

	# --- C-H: Cadeia de Bloqueio do Suporte (Coluna A: 1 frente, 6 meio, 7 fundo) ---
	var chain_state := CombatState.new()

	var c_support := CombatUnit.new(_build_combat_card("C-Suporte", "Suporte", 30, 80, 10), 0, 6)
	var c_machine := CombatUnit.new(_build_combat_card("C-MdG", "Máquina de Guerra", 100, 100, 20), 0, 7)
	chain_state.units = [c_support, c_machine]
	print("  C) Suporte -> Máquina de Guerra avança normalmente? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, c_support)
	))
	ctx.check(CombatEngine._can_advance(chain_state, c_support) == true, "C) Suporte -> Máquina de Guerra deve avançar normalmente (Máquina de Guerra é opaca à cadeia)")

	var d_support_1 := CombatUnit.new(_build_combat_card("D-Suporte-1", "Suporte", 30, 80, 10), 0, 6)
	var d_support_2 := CombatUnit.new(_build_combat_card("D-Suporte-2", "Suporte", 30, 80, 10), 0, 7)
	chain_state.units = [d_support_1, d_support_2]
	print("  D) Suporte -> Suporte avança normalmente? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, d_support_1)
	))
	ctx.check(CombatEngine._can_advance(chain_state, d_support_1) == true, "D) Suporte -> Suporte deve avançar normalmente")

	var e_support_1 := CombatUnit.new(_build_combat_card("E-Suporte-1", "Suporte", 30, 80, 10), 0, 1)
	var e_support_2 := CombatUnit.new(_build_combat_card("E-Suporte-2", "Suporte", 30, 80, 10), 0, 6)
	var e_machine := CombatUnit.new(_build_combat_card("E-MdG", "Máquina de Guerra", 100, 100, 20), 0, 7)
	chain_state.units = [e_support_1, e_support_2, e_machine]
	print("  E) Suporte -> Suporte -> Máquina de Guerra: todos avançam normalmente? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, e_support_1)
	))
	ctx.check(CombatEngine._can_advance(chain_state, e_support_1) == true, "E) Suporte -> Suporte -> Máquina de Guerra deve avançar normalmente (recursão através do Suporte, terminador opaco na Máquina de Guerra)")

	var f_support_1 := CombatUnit.new(_build_combat_card("F-Suporte-1", "Suporte", 30, 80, 10), 0, 1)
	var f_support_2 := CombatUnit.new(_build_combat_card("F-Suporte-2", "Suporte", 30, 80, 10), 0, 6)
	var f_support_3 := CombatUnit.new(_build_combat_card("F-Suporte-3", "Suporte", 30, 80, 10), 0, 7)
	chain_state.units = [f_support_1, f_support_2, f_support_3]
	print("  F) Suporte -> Suporte -> Suporte: todos avançam normalmente? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, f_support_1)
	))
	ctx.check(CombatEngine._can_advance(chain_state, f_support_1) == true, "F) Suporte -> Suporte -> Suporte deve avançar normalmente")

	var g_support_1 := CombatUnit.new(_build_combat_card("G-Suporte-1", "Suporte", 30, 80, 10), 0, 1)
	var g_support_2 := CombatUnit.new(_build_combat_card("G-Suporte-2", "Suporte", 30, 80, 10), 0, 6)
	var g_ranged := CombatUnit.new(_build_combat_card("G-Distancia", "À Distância", 80, 70, 10), 0, 7)
	chain_state.units = [g_support_1, g_support_2, g_ranged]
	print("  G) Suporte -> Suporte -> À Distância (convencional): ambos os Suportes ficam bloqueados? %s, %s (esperado: false, false)" % [
		str(CombatEngine._can_advance(chain_state, g_support_1)), str(CombatEngine._can_advance(chain_state, g_support_2))
	])
	ctx.check(CombatEngine._can_advance(chain_state, g_support_1) == false, "G) Suporte imediatamente atrás de outro Suporte que bloqueia deve ficar bloqueado (1º Suporte)")
	ctx.check(CombatEngine._can_advance(chain_state, g_support_2) == false, "G) Suporte bloqueado por Classe convencional atrás dele deve ficar bloqueado (2º Suporte)")
	print("     À Distância nunca é bloqueado pela própria regra de Classe (sua elegibilidade não depende do que está atrás dele)? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, g_ranged)
	))
	ctx.check(CombatEngine._can_advance(chain_state, g_ranged) == true, "G) À Distância nunca é bloqueado pela regra de Classe do Suporte")

	var h_support := CombatUnit.new(_build_combat_card("H-Suporte", "Suporte", 30, 80, 10), 0, 1)
	var h_machine := CombatUnit.new(_build_combat_card("H-MdG", "Máquina de Guerra", 100, 100, 20), 0, 6)
	var h_ranged := CombatUnit.new(_build_combat_card("H-Distancia", "À Distância", 80, 70, 10), 0, 7)
	chain_state.units = [h_support, h_machine, h_ranged]
	print("  H) Suporte -> Máquina de Guerra -> À Distância (convencional mais atrás): Suporte avança normalmente mesmo assim? %s (esperado: true)" % str(
		CombatEngine._can_advance(chain_state, h_support)
	))
	ctx.check(CombatEngine._can_advance(chain_state, h_support) == true, "H) Suporte -> Máquina de Guerra deve avançar normalmente independentemente do que está atrás da Máquina de Guerra (opaca à cadeia)")

	# --- I: Suporte não pode iniciar a batalha na Posição 5 (detecção — ver nota em Army.has_support_at_position_5()) ---
	var army_support_at_5 := Army.new()
	army_support_at_5.commander = commander_a
	army_support_at_5.cards = [
		_build_combat_card("I-CQC-1", "Corpo a Corpo", 100, 100, 20),   # índice 0 -> Posição 1
		_build_combat_card("I-CQC-2", "Corpo a Corpo", 100, 100, 20),   # índice 1 -> Posição 2
		_build_combat_card("I-CQC-3", "Corpo a Corpo", 100, 100, 20),   # índice 2 -> Posição 3
		_build_combat_card("I-Distancia-1", "À Distância", 80, 70, 10), # índice 3 -> Posição 4
		_build_combat_card("I-Suporte", "Suporte", 30, 80, 10),         # índice 4 -> Posição 5
		_build_combat_card("I-Distancia-2", "À Distância", 80, 70, 10), # índice 5 -> Posição 6
		_build_combat_card("I-Barreira", "Barreira", 50, 120, 60),      # índice 6 -> Posição 7
		_build_combat_card("I-Mago", "Mago", 90, 60, 0),                # índice 7 -> Posição 8
		_build_combat_card("I-MdG", "Máquina de Guerra", 100, 100, 20), # -> Posição 9 (extraída antes das demais)
	]
	print("  I) has_support_at_position_5() detecta corretamente um Suporte na Posição 5? %s (esperado: true)" % str(
		army_support_at_5.has_support_at_position_5()
	))
	ctx.check(army_support_at_5.has_support_at_position_5() == true, "I) has_support_at_position_5() deve detectar um Suporte na Posição 5")
	print("     (F-018) is_ready_for_battle() ainda NÃO rejeita este caso, de propósito — ver TECHNICAL_BACKLOG.md F-018. Ainda pronto para batalha? %s (esperado: true, propositalmente)" % str(
		army_support_at_5.is_ready_for_battle()
	))
	ctx.check(army_support_at_5.is_ready_for_battle() == true, "I) is_ready_for_battle() ainda não rejeita Suporte na Posição 5, de propósito (F-018 em aberto)")
	print("     Falso positivo: um Exército sem Suporte na Posição 5 retorna false? %s (esperado: false)" % str(
		army_a.has_support_at_position_5()
	))
	ctx.check(army_a.has_support_at_position_5() == false, "I) Exército sem Suporte na Posição 5 não deve gerar falso positivo")

	# --- J: pelotão convencional que CHEGA na Posição 5 via movimento perde a ação ---
	# Bloqueador na Posição 2 (frente da Coluna B) de propósito, pelo
	# mesmo motivo do Teste B — isola a chegada exatamente na Posição 5.
	var j_state := CombatState.new()
	var j_ranged := CombatUnit.new(_build_combat_card("J-Distancia", "À Distância", 80, 70, 10), 0, 8)  # Coluna B: 2,5,8
	var j_blocker := CombatUnit.new(_build_combat_card("J-Bloqueador", "Barreira", 50, 100, 50), 0, 2)
	j_state.units = [j_ranged, j_blocker]
	CombatEngine._movement_phase(j_state)
	print("  J) Pelotão convencional que chega na Posição 5 via movimento entra em Reorganização (perde a ação no turno)? %s (posição: %d, esperado: true, 5)" % [
		str(j_ranged.position == 5 and j_ranged.is_reorganizing_this_turn), j_ranged.position
	])
	ctx.check(j_ranged.position == 5 and j_ranged.is_reorganizing_this_turn, "J) Pelotão que chega na Posição 5 via movimento deve entrar em Reorganização")
	ctx.check(j_ranged.position == 5, "J) Pelotão deve parar exatamente na Posição 5 (obtido: %d)" % j_ranged.position)

	# --- K: pelotão que INICIA a batalha na Posição 5 não recebe a penalidade ---
	var k_unit := CombatUnit.new(_build_combat_card("K-Distancia", "À Distância", 80, 70, 10), 0, 5)
	CombatEngine._apply_initial_position_effects(k_unit)
	print("  K) Pelotão que já inicia na Posição 5 NÃO entra em Reorganização neste turno? %s (esperado: true — has_triggered=true, is_reorganizing=false)" % str(
		k_unit.has_triggered_reorganization and not k_unit.is_reorganizing_this_turn
	))
	ctx.check(k_unit.has_triggered_reorganization == true, "K) Pelotão que inicia na Posição 5 deve marcar has_triggered_reorganization = true")
	ctx.check(k_unit.is_reorganizing_this_turn == false, "K) Pelotão que inicia na Posição 5 não deve entrar em Reorganização neste turno")

	return true


## Cria uma carta transitória (não persistida no catálogo) para validação
## do Motor de Combate, com atributos de combate explícitos. Cópia do
## helper de mesmo nome em bootstrap.gd — compartilhado com validações
## ainda não migradas (_validate_combat_engine, _validate_mining_incremental_estimation),
## portanto NÃO removido de lá.
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
