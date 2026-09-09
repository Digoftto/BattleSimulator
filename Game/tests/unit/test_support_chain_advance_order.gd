class_name TestSupportChainAdvanceOrder
extends RefCounted
## TestSupportChainAdvanceOrder
##
## Auditoria de movimentação do Suporte (2026-09-01) encontrou que
## CombatEngine._support_chain_clear() (COMBAT_RULES.md 6.5, "Cadeia de
## Bloqueio") continuava usando CombatBoard.positions_behind() — geometria
## de COLUNA antiga — mesmo depois de _movement_phase() ter migrado pra
## uma sequência espacial única (CombatBoard.ADVANCE_ORDER, correção
## anterior). Corrigido via CombatBoard.support_position_behind(), que
## calcula "atrás" pela sequência única, sem tocar positions_behind()/
## column_of() (usados por "Sacrifício de Carne", que é explicitamente
## "mesma coluna" por definição própria em ABILITIES.md/CARD_CATALOG.md —
## Teste 7 abaixo é a rede de segurança dessa separação).
##
## Regras que este arquivo NÃO testa (fora de escopo, intocadas por esta
## correção): Restrição de Posicionamento Inicial do Suporte na Posição 5
## (Army/Army Editor — Regra A, ver test_army_formation_archetypes.gd) e
## Penalidade de Reorganização (5.2.2, universal a qualquer Classe — ver
## Testes J/K em test_movement_rules.gd).

static func run(ctx: TestRunner.Context) -> bool:
	print("[Suporte/Cadeia] Validando a Cadeia de Bloqueio (6.5) sob a sequência única de avanço (ADVANCE_ORDER)...")

	_test_1_posicao_5_com_6_vazia_e_8_convencional(ctx)
	_test_2_posicao_5_com_6_convencional_e_8_vazia(ctx)
	_test_3_suporte_suporte_vazio(ctx)
	_test_4_suporte_suporte_convencional(ctx)
	_test_5_suporte_maquina_de_guerra(ctx)
	_test_6_suporte_chega_na_posicao_5_durante_batalha(ctx)
	_test_7_sacrificio_de_carne_continua_por_coluna(ctx)
	_test_8_ambos_os_lados(ctx)

	return true


static func _card(name_suffix: String, card_class: String) -> CardResource:
	return TestMovementRules._build_combat_card("Chain-%s" % name_suffix, card_class, 50, 50, 10)


## TESTE 1 (regressão obrigatória): Suporte na Posição 5, Posição 6 vazia,
## Posição 8 ocupada por Corpo a Corpo. A posição relevante ("atrás" na
## sequência única) é a 6, vazia — o ocupante da 8 é irrelevante pra
## Cadeia. O Suporte DEVE poder avançar.
static func _test_1_posicao_5_com_6_vazia_e_8_convencional(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support := CombatUnit.new(_card("1-Suporte", "Suporte"), 0, 5)
	var conventional_at_8 := CombatUnit.new(_card("1-Convencional-8", "Corpo a Corpo"), 0, 8)
	state.units = [support, conventional_at_8]

	print("  [1] Suporte na Posição 5 (Posição 6 vazia, Posição 8 com Corpo a Corpo) pode avançar? %s (esperado: true)" % str(CombatEngine._can_advance(state, support)))
	ctx.check(CombatEngine._can_advance(state, support) == true, "[1] Suporte deve avançar — a posição relevante (6, na sequência única) está vazia; o ocupante da Posição 8 (coluna antiga) é irrelevante")


## TESTE 2 (regressão obrigatória): Suporte na Posição 5, Posição 6
## ocupada por Corpo a Corpo, Posição 8 vazia. A Posição 6 é imediatamente
## atrás dele na ADVANCE_ORDER — o Suporte DEVE ficar bloqueado.
static func _test_2_posicao_5_com_6_convencional_e_8_vazia(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support := CombatUnit.new(_card("2-Suporte", "Suporte"), 0, 5)
	var conventional_at_6 := CombatUnit.new(_card("2-Convencional-6", "Corpo a Corpo"), 0, 6)
	state.units = [support, conventional_at_6]

	print("  [2] Suporte na Posição 5 (Posição 6 com Corpo a Corpo, Posição 8 vazia) fica bloqueado? %s (esperado: false)" % str(CombatEngine._can_advance(state, support)))
	ctx.check(CombatEngine._can_advance(state, support) == false, "[2] Suporte deve ficar bloqueado — a Posição 6 (imediatamente atrás dele na ADVANCE_ORDER) está ocupada por Classe convencional")


## TESTE 3: Suporte A na Posição 5, Suporte B na Posição 6, Posição 7
## vazia — cadeia transparente através de B, termina em vazio: ambos
## podem avançar.
static func _test_3_suporte_suporte_vazio(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support_a := CombatUnit.new(_card("3-Suporte-A", "Suporte"), 0, 5)
	var support_b := CombatUnit.new(_card("3-Suporte-B", "Suporte"), 0, 6)
	state.units = [support_a, support_b]  # Posição 7 vazia, de propósito

	print("  [3] Suporte A (5) -> Suporte B (6) -> vazio (7): ambos avançam? A=%s B=%s (esperado: true, true)" % [str(CombatEngine._can_advance(state, support_a)), str(CombatEngine._can_advance(state, support_b))])
	ctx.check(CombatEngine._can_advance(state, support_a) == true, "[3] Suporte A deve avançar (cadeia transparente através de B, termina em posição vazia)")
	ctx.check(CombatEngine._can_advance(state, support_b) == true, "[3] Suporte B deve avançar (nada atrás dele)")


## TESTE 4: Suporte A na Posição 5, Suporte B na Posição 6, Corpo a Corpo
## na Posição 7 — cadeia bloqueada: nem A nem B avançam.
static func _test_4_suporte_suporte_convencional(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support_a := CombatUnit.new(_card("4-Suporte-A", "Suporte"), 0, 5)
	var support_b := CombatUnit.new(_card("4-Suporte-B", "Suporte"), 0, 6)
	var conventional_at_7 := CombatUnit.new(_card("4-Convencional-7", "Corpo a Corpo"), 0, 7)
	state.units = [support_a, support_b, conventional_at_7]

	print("  [4] Suporte A (5) -> Suporte B (6) -> Corpo a Corpo (7): ambos bloqueados? A=%s B=%s (esperado: false, false)" % [str(CombatEngine._can_advance(state, support_a)), str(CombatEngine._can_advance(state, support_b))])
	ctx.check(CombatEngine._can_advance(state, support_a) == false, "[4] Suporte A deve ficar bloqueado (cadeia contígua de Suportes bloqueada pela Classe convencional atrás de B)")
	ctx.check(CombatEngine._can_advance(state, support_b) == false, "[4] Suporte B deve ficar bloqueado diretamente pela Classe convencional atrás dele")


## TESTE 5: Suporte na Posição 5, Máquina de Guerra na Posição 6 —
## transparente/opaca à cadeia (nunca bloqueia), independentemente do que
## exista mais atrás.
static func _test_5_suporte_maquina_de_guerra(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support := CombatUnit.new(_card("5-Suporte", "Suporte"), 0, 5)
	var machine := CombatUnit.new(_card("5-MdG", "Máquina de Guerra"), 0, 6)
	state.units = [support, machine]

	print("  [5] Suporte (5) -> Máquina de Guerra (6): avança normalmente? %s (esperado: true)" % str(CombatEngine._can_advance(state, support)))
	ctx.check(CombatEngine._can_advance(state, support) == true, "[5] Suporte não deve ser bloqueado por Máquina de Guerra imediatamente atrás (opaca à Cadeia)")


## TESTE 6: não existe nenhuma regra proibindo o Suporte de OCUPAR a
## Posição 5 durante a batalha (Regra B, distinta da Restrição de
## Posicionamento INICIAL — Regra A, pertence ao Army Editor). Um Suporte
## que inicia a batalha na Posição 6, com a Posição 5 livre, deve avançar
## normalmente até ela via _movement_phase() real. Posições 1-4 preenchidas
## e encadeadas (cada uma bloqueada pela anterior, pinadas na Posição 1)
## só para isolar a chegada exatamente na Posição 5 — sem elas, nada
## impediria o Suporte de continuar até a Posição 1 no mesmo tabuleiro
## praticamente vazio, o que provaria menos (a regra geral de avanço já é
## coberta por test_movement_sequence_compaction.gd; aqui o que importa é
## confirmar que NENHUMA regra especial do Suporte o impede de parar
## exatamente na Posição 5 quando ela é, de fato, a posição livre mais
## próxima disponível).
static func _test_6_suporte_chega_na_posicao_5_durante_batalha(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support := CombatUnit.new(_card("6-Suporte", "Suporte"), 0, 6)
	var front_1 := CombatUnit.new(_card("6-Frente-1", "Corpo a Corpo"), 0, 1)
	var front_2 := CombatUnit.new(_card("6-Frente-2", "Corpo a Corpo"), 0, 2)
	var front_3 := CombatUnit.new(_card("6-Frente-3", "Corpo a Corpo"), 0, 3)
	var front_4 := CombatUnit.new(_card("6-Frente-4", "Corpo a Corpo"), 0, 4)
	state.units = [support, front_1, front_2, front_3, front_4]  # Posição 5 vazia, de propósito

	CombatEngine._movement_phase(state)

	print("  [6] Suporte iniciando na Posição 6 chega à Posição 5 durante a batalha (Posição 5 livre, Posição 4 genuinamente ocupada)? %s (posição obtida: %d, esperado: 5)" % [str(support.position == 5), support.position])
	ctx.check(support.position == 5, "[6] Suporte deve poder ocupar a Posição 5 via movimento normal — não existe restrição de Posição 5 dentro do CombatEngine (obtido: %d)" % support.position)


## TESTE 7 (rede de segurança da separação): "Sacrifício de Carne"
## (ABILITIES.md/CARD_CATALOG.md: "Pelotão aliado imediatamente atrás na
## MESMA COLUNA") usa CombatBoard.positions_behind()/column_of(),
## intencionalmente intocado por esta correção — continua respondendo
## pela geometria de coluna antiga, nunca pela ADVANCE_ORDER.
static func _test_7_sacrificio_de_carne_continua_por_coluna(ctx: TestRunner.Context) -> void:
	# Coluna C = [3, 4, 9] — positions_behind(3) (usada por "Sacrifício de
	# Carne", card real "Abominação Putrefata" nesta mesma Posição 3 em
	# test_unit_trait_runtimes.gd) deve continuar retornando TODAS as
	# posições mais ao fundo na mesma coluna ([4, 9]) — ancorada em
	# column_of(), nunca em ADVANCE_ORDER.
	var behind_by_column: Array[int] = CombatBoard.positions_behind(3)
	print("  [7] positions_behind(3) (Sacrifício de Carne, mesma coluna) ainda retorna [4, 9]? %s (obtido: %s)" % [str(behind_by_column == [4, 9]), str(behind_by_column)])
	ctx.check(behind_by_column == [4, 9], "[7] positions_behind() deve continuar retornando a geometria de COLUNA (Sacrifício de Carne não foi afetado por esta correção) — obtido: %s" % str(behind_by_column))

	# Prova de que as duas funções são realmente independentes: na Posição
	# 1 elas divergem claramente (coluna: atrás = 6; sequência única:
	# atrás = 2) — confirma que a separação das duas geometrias é real,
	# não uma coincidência de uma única posição testada.
	var behind_by_column_at_1: Array[int] = CombatBoard.positions_behind(1)
	var behind_by_sequence_at_1: int = CombatBoard.support_position_behind(1)
	print("     Na Posição 1, positions_behind()=%s (coluna) vs. support_position_behind()=%d (sequência única) — divergem de propósito" % [str(behind_by_column_at_1), behind_by_sequence_at_1])
	ctx.check(behind_by_column_at_1[0] == 6, "[7] positions_behind(1) deve continuar apontando pra Posição 6 (coluna antiga) — obtido: %s" % str(behind_by_column_at_1))
	ctx.check(behind_by_sequence_at_1 == 2, "[7] support_position_behind(1) deve apontar pra Posição 2 (sequência única, ADVANCE_ORDER) — obtido: %d" % behind_by_sequence_at_1)


## TESTE 8: a Cadeia de Bloqueio funciona de forma independente e correta
## nos dois lados — o que bloqueia o Suporte do Lado 0 nunca deve
## interferir no Suporte do Lado 1, e vice-versa.
static func _test_8_ambos_os_lados(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var support_side0 := CombatUnit.new(_card("8-Suporte-Lado0", "Suporte"), 0, 5)
	var blocker_side0 := CombatUnit.new(_card("8-Bloqueador-Lado0", "Corpo a Corpo"), 0, 6)
	var support_side1 := CombatUnit.new(_card("8-Suporte-Lado1", "Suporte"), 1, 5)
	# Lado 1: Posição 6 vazia de propósito — deve avançar livremente,
	# independentemente do Lado 0 estar bloqueado.
	state.units = [support_side0, blocker_side0, support_side1]

	print("  [8] Lado 0 bloqueado, Lado 1 livre — cada lado avalia sua própria Cadeia? Lado0=%s Lado1=%s (esperado: false, true)" % [str(CombatEngine._can_advance(state, support_side0)), str(CombatEngine._can_advance(state, support_side1))])
	ctx.check(CombatEngine._can_advance(state, support_side0) == false, "[8] Suporte do Lado 0 deve ficar bloqueado pelo Corpo a Corpo na Posição 6 do PRÓPRIO lado")
	ctx.check(CombatEngine._can_advance(state, support_side1) == true, "[8] Suporte do Lado 1 deve avançar livremente — a Posição 6 do Lado 1 está vazia, o bloqueio do Lado 0 não deve vazar entre lados")
