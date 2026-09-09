class_name TestMovementSequenceCompaction
extends RefCounted
## TestMovementSequenceCompaction
##
## Auditoria de movimentação (2026-09-01) encontrou que _movement_phase()
## tratava a formação como 3 colunas independentes (CombatBoard.COLUMNS),
## quando COMBAT_RULES.md 5.2.1 define UMA ÚNICA sequência espacial oficial
## ("Fluxo de Avanço: 9→8→7→6→5→4→3→2→1", "preservando a ordem original
## do exército") — já existente e correta em CombatBoard.ADVANCE_ORDER,
## simplesmente nunca conectada à Fase de Movimento. Esta suíte valida a
## correção: a formação inteira compacta como uma fila única, uma morte
## pode liberar mais de uma posição na mesma Fase, e a ordem relativa dos
## sobreviventes (na sequência 9→1) nunca é violada.
##
## Todos os cenários usam Classe "Corpo a Corpo" (regra geral de avanço,
## sem exceção de Classe) exceto o Teste 8 (Máquina de Guerra) — a Cadeia
## de Bloqueio do Suporte (6.5) não muda nesta correção e continua coberta
## por test_movement_rules.gd (Testes C-H), que não dependem de COLUMNS
## para a geometria de avanço em si.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Movimento/Sequência] Validando compactação como fila espacial única (9→8→7→6→5→4→3→2→1)...")

	_test_1_exemplo_obrigatorio_1(ctx)
	_test_2_exemplo_obrigatorio_2(ctx)
	_test_3_morte_na_posicao_1_compacta_tudo(ctx)
	_test_4_morte_no_meio_so_afeta_quem_esta_atras(ctx)
	_test_5_mortes_multiplas_no_mesmo_evento(ctx)
	_test_6_ordem_relativa_nunca_e_violada(ctx)
	_test_7_ambos_os_lados(ctx)
	_test_8_maquina_de_guerra_atravessa_colunas_antigas(ctx)

	return true


static func _unit(name_suffix: String, side: int, position: int) -> CombatUnit:
	return CombatUnit.new(TestMovementRules._build_combat_card("Seq-%s" % name_suffix, "Corpo a Corpo", 50, 50, 10), side, position)


## TESTE 1 (Exemplo Obrigatório 1 do pedido): 1=A,2=B,3=C,6=F,5=E,4=D,7=G,
## 8=H,9=I — B morre. Resultado obrigatório: 1=A,2=C,3=D,6=G,5=F,4=E,7=H,
## 8=I,9=vazio.
static func _test_1_exemplo_obrigatorio_1(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var a := _unit("A", 0, 1)
	var c := _unit("C", 0, 3)
	var d := _unit("D", 0, 4)
	var e := _unit("E", 0, 5)
	var f := _unit("F", 0, 6)
	var g := _unit("G", 0, 7)
	var h := _unit("H", 0, 8)
	var i := _unit("I", 0, 9)
	state.units = [a, c, d, e, f, g, h, i]  # B (posição 2) morto, de propósito não incluído

	CombatEngine._movement_phase(state)

	print("  [1] A=%d C=%d D=%d E=%d F=%d G=%d H=%d I=%d (esperado: 1,2,3,4,5,6,7,8)" % [a.position, c.position, d.position, e.position, f.position, g.position, h.position, i.position])
	ctx.check(a.position == 1, "[1] A deve permanecer na Posição 1")
	ctx.check(c.position == 2, "[1] C deve avançar da Posição 3 para a Posição 2 (obtido: %d)" % c.position)
	ctx.check(d.position == 3, "[1] D deve avançar da Posição 4 para a Posição 3 (obtido: %d)" % d.position)
	ctx.check(e.position == 4, "[1] E deve avançar da Posição 5 para a Posição 4 (obtido: %d)" % e.position)
	ctx.check(f.position == 5, "[1] F deve avançar da Posição 6 para a Posição 5 (obtido: %d)" % f.position)
	ctx.check(g.position == 6, "[1] G deve avançar da Posição 7 para a Posição 6 (obtido: %d)" % g.position)
	ctx.check(h.position == 7, "[1] H deve avançar da Posição 8 para a Posição 7 (obtido: %d)" % h.position)
	ctx.check(i.position == 8, "[1] I deve avançar da Posição 9 para a Posição 8 (obtido: %d)" % i.position)
	ctx.check(state.unit_at(0, 9) == null, "[1] Posição 9 deve ficar vazia (única baixa da fila)")


## TESTE 2 (Exemplo Obrigatório 2): estado pós-Teste 1 (1=A,2=C,3=D,4=E,
## 5=F,6=G,7=H,8=I,9=vazio) — F (posição 5) e D (posição 3) morrem juntos,
## na mesma resolução. Resultado obrigatório: 1=A,2=C,3=E,6=I,5=H,4=G,
## 7=vazio,8=vazio,9=vazio.
static func _test_2_exemplo_obrigatorio_2(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var a := _unit("A", 0, 1)
	var c := _unit("C", 0, 2)
	var e := _unit("E", 0, 4)
	var g := _unit("G", 0, 6)
	var h := _unit("H", 0, 7)
	var i := _unit("I", 0, 8)
	state.units = [a, c, e, g, h, i]  # D (posição 3) e F (posição 5) mortos juntos

	CombatEngine._movement_phase(state)

	print("  [2] A=%d C=%d E=%d G=%d H=%d I=%d (esperado: 1,2,3,4,5,6)" % [a.position, c.position, e.position, g.position, h.position, i.position])
	ctx.check(a.position == 1, "[2] A deve permanecer na Posição 1")
	ctx.check(c.position == 2, "[2] C deve permanecer na Posição 2")
	ctx.check(e.position == 3, "[2] E deve avançar da Posição 4 para a Posição 3 (obtido: %d)" % e.position)
	ctx.check(g.position == 4, "[2] G deve avançar da Posição 6 para a Posição 4 (obtido: %d)" % g.position)
	ctx.check(h.position == 5, "[2] H deve avançar da Posição 7 para a Posição 5 (obtido: %d)" % h.position)
	ctx.check(i.position == 6, "[2] I deve avançar da Posição 8 para a Posição 6 (obtido: %d)" % i.position)
	ctx.check(state.unit_at(0, 7) == null and state.unit_at(0, 8) == null and state.unit_at(0, 9) == null, "[2] Posições 7, 8 e 9 devem ficar vazias")


## TESTE 3: tabuleiro cheio (9 unidades), morre a Posição 1 — o caso de
## cascata máxima: as 8 sobreviventes devem avançar exatamente 1 posição
## cada, preservando ordem, e a Posição 9 fica vazia.
static func _test_3_morte_na_posicao_1_compacta_tudo(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units: Array[CombatUnit] = []
	for position in range(2, 10):  # 2..9 — Posição 1 morta, de propósito não incluída
		units.append(_unit(str(position), 0, position))
	state.units = units

	CombatEngine._movement_phase(state)

	var all_shifted_by_one: bool = true
	for unit: CombatUnit in units:
		var original_position: int = int(unit.card.card_name.trim_prefix("Seq-"))
		if unit.position != original_position - 1:
			all_shifted_by_one = false
			print("  [3] MISMATCH: unidade original da Posição %d está na Posição %d (esperado: %d)" % [original_position, unit.position, original_position - 1])
	print("  [3] Todas as 8 sobreviventes avançaram exatamente 1 posição (cascata máxima)? %s" % str(all_shifted_by_one))
	ctx.check(all_shifted_by_one, "[3] Matar a Posição 1 com tabuleiro cheio deve deslocar as 8 sobreviventes, cada uma exatamente 1 posição à frente, preservando ordem")
	ctx.check(state.unit_at(0, 9) == null, "[3] Posição 9 deve ficar vazia após a cascata máxima")


## TESTE 4: tabuleiro cheio, morre a Posição 5 (meio da sequência) — só
## quem está ATRÁS dela na sequência espacial (6, 7, 8, 9) deve avançar;
## quem está À FRENTE (1, 2, 3, 4) permanece parado (nada se abriu à
## frente deles).
static func _test_4_morte_no_meio_so_afeta_quem_esta_atras(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units_by_position: Dictionary = {}
	var units: Array[CombatUnit] = []
	for position in range(1, 10):
		if position == 5:
			continue  # Posição 5 morta, de propósito não incluída
		var unit := _unit(str(position), 0, position)
		units_by_position[position] = unit
		units.append(unit)
	state.units = units

	CombatEngine._movement_phase(state)

	var front_untouched: bool = true
	for position in [1, 2, 3, 4]:
		var unit: CombatUnit = units_by_position[position]
		if unit.position != position:
			front_untouched = false
	var behind_advanced: bool = (
		units_by_position[6].position == 5
		and units_by_position[7].position == 6
		and units_by_position[8].position == 7
		and units_by_position[9].position == 8
	)
	print("  [4] Morte no meio da sequência (Posição 5): frente intocada=%s, quem estava atrás avançou=%s" % [str(front_untouched), str(behind_advanced)])
	for position in [1, 2, 3, 4]:
		ctx.check(units_by_position[position].position == position, "[4] Posição %d não deve se mover (nada se abriu à frente dela)" % position)
	ctx.check(units_by_position[6].position == 5, "[4] Posição 6 deve avançar para a Posição 5 (obtido: %d)" % units_by_position[6].position)
	ctx.check(units_by_position[7].position == 6, "[4] Posição 7 deve avançar para a Posição 6 (obtido: %d)" % units_by_position[7].position)
	ctx.check(units_by_position[8].position == 7, "[4] Posição 8 deve avançar para a Posição 7 (obtido: %d)" % units_by_position[8].position)
	ctx.check(units_by_position[9].position == 8, "[4] Posição 9 deve avançar para a Posição 8 (obtido: %d)" % units_by_position[9].position)
	ctx.check(state.unit_at(0, 9) == null, "[4] Posição 9 deve ficar vazia")


## TESTE 5: tabuleiro cheio, mortes simultâneas em 3 posições distintas
## (2, 5, 8) — compactação completa numa ÚNICA resolução de movimento
## (uma só chamada de _movement_phase()).
static func _test_5_mortes_multiplas_no_mesmo_evento(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units_by_position: Dictionary = {}
	var units: Array[CombatUnit] = []
	for position in range(1, 10):
		if position in [2, 5, 8]:
			continue  # mortas juntas, de propósito não incluídas
		var unit := _unit(str(position), 0, position)
		units_by_position[position] = unit
		units.append(unit)
	state.units = units

	CombatEngine._movement_phase(state)

	# Sobreviventes na ordem espacial (9→1): 9,7,6,4,3,1 -> compactam para
	# as 6 posições mais avançadas (6,5,4,3,2,1), preservando essa ordem.
	var expected: Dictionary = {9: 6, 7: 5, 6: 4, 4: 3, 3: 2, 1: 1}
	var all_correct: bool = true
	for original_position: int in expected:
		var unit: CombatUnit = units_by_position[original_position]
		if unit.position != expected[original_position]:
			all_correct = false
			print("  [5] MISMATCH: original da Posição %d está em %d (esperado: %d)" % [original_position, unit.position, expected[original_position]])
	print("  [5] 3 mortes simultâneas (posições 2, 5, 8) compactam por completo numa única Fase? %s" % str(all_correct))
	ctx.check(all_correct, "[5] Mortes múltiplas antes da movimentação devem compactar por completo numa única resolução")
	for position in [7, 8, 9]:
		ctx.check(state.unit_at(0, position) == null, "[5] Posição %d deve ficar vazia (sobra da compactação de 6 sobreviventes)" % position)


## TESTE 6: nenhuma unidade ultrapassa outra — a ordem relativa das
## sobreviventes na sequência espacial (9→1) antes da morte deve ser
## idêntica à ordem relativa delas depois da compactação. Reaproveita o
## cenário do Teste 5 (o mais exigente: 3 mortes espalhadas) em vez de
## reimplementar a checagem de posição a posição.
static func _test_6_ordem_relativa_nunca_e_violada(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var original_order: Array[int] = [9, 7, 6, 4, 3, 1]  # já na ordem espacial 9->1, sem os mortos (2,5,8)
	var units: Array[CombatUnit] = []
	for position: int in original_order:
		units.append(_unit(str(position), 0, position))
	state.units = units

	CombatEngine._movement_phase(state)

	var order_preserved: bool = true
	for a_index in range(units.size()):
		for b_index in range(a_index + 1, units.size()):
			# units[a_index] estava mais atrás (ou igual) na sequência 9->1
			# do que units[b_index] antes da morte (array já construído
			# nessa ordem) — depois de compactar, essa relação nunca pode
			# se inverter (unidade mais atrás nunca ultrapassa a mais à frente).
			var a_seq_index_after: int = CombatBoard.ADVANCE_ORDER.find(units[a_index].position)
			var b_seq_index_after: int = CombatBoard.ADVANCE_ORDER.find(units[b_index].position)
			if a_seq_index_after > b_seq_index_after:
				order_preserved = false
	print("  [6] Ordem relativa das sobreviventes preservada (nenhuma ultrapassagem)? %s" % str(order_preserved))
	ctx.check(order_preserved, "[6] Nenhuma unidade deve ultrapassar outra que estava à sua frente na sequência espacial antes da morte")


## TESTE 7: mesma lógica nos dois lados, de forma independente — cada
## lado avança rumo à SUA própria Posição 1 (que enfrenta o lado oposto).
static func _test_7_ambos_os_lados(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var side0_a := _unit("Lado0-A", 0, 1)
	var side0_c := _unit("Lado0-C", 0, 3)  # Posição 2 do Lado 0 morta
	var side1_a := _unit("Lado1-A", 1, 1)
	var side1_i := _unit("Lado1-I", 1, 9)  # Posições 2-8 do Lado 1 mortas
	state.units = [side0_a, side0_c, side1_a, side1_i]

	CombatEngine._movement_phase(state)

	print("  [7] Lado 0: A=%d C=%d | Lado 1: A=%d I=%d (esperado: 1,2 | 1,2)" % [side0_a.position, side0_c.position, side1_a.position, side1_i.position])
	ctx.check(side0_a.position == 1, "[7] Lado 0: A deve permanecer na Posição 1")
	ctx.check(side0_c.position == 2, "[7] Lado 0: C deve avançar da Posição 3 para a Posição 2")
	ctx.check(side1_a.position == 1, "[7] Lado 1: A deve permanecer na Posição 1 (não deve ser afetado pelo Lado 0)")
	ctx.check(side1_i.position == 2, "[7] Lado 1: I deve avançar da Posição 9 direto para a Posição 2 (tabuleiro do Lado 1 quase vazio)")


## TESTE 8: Máquina de Guerra na Posição 9 (posicionamento inicial
## obrigatório, 6.6) participa normalmente da sequência depois disso —
## sem exceção própria de movimento (5.2.3) — e pode atravessar o que
## antes eram fronteiras de coluna (9 era Coluna C, termina na Posição 2,
## Coluna B) numa única Fase de Movimento.
static func _test_8_maquina_de_guerra_atravessa_colunas_antigas(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var mdg := CombatUnit.new(TestMovementRules._build_combat_card("Seq-MdG", "Máquina de Guerra", 100, 100, 20), 0, 9)
	var blocker := CombatUnit.new(TestMovementRules._build_combat_card("Seq-Bloqueador", "Barreira", 50, 100, 50), 0, 1)
	state.units = [mdg, blocker]

	CombatEngine._movement_phase(state)

	print("  [8] Máquina de Guerra termina na Posição 2, logo atrás do bloqueador fixo na Posição 1? %s (posição obtida: %d)" % [str(mdg.position == 2), mdg.position])
	ctx.check(blocker.position == 1, "[8] Bloqueador já estava na Posição 1 (nada à frente dela) e deve permanecer ali")
	ctx.check(mdg.position == 2, "[8] Máquina de Guerra deve atravessar toda a fila (Posição 9 até a Posição 2) numa única Fase, sem se restringir à antiga Coluna C (obtido: %d)" % mdg.position)
