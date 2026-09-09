class_name TestCampoDeProvaRelatorioBaixas
extends RefCounted
## TestCampoDeProvaRelatorioBaixas (Auditoria FASE 22.1, achado H)
##
## O relatório do Campo de Prova (_build_relatorio_interior) só mostrava
## vencedor/turnos/Campo de Batalha/nomes de Comandante — nunca lia
## CombatState.units_of_side()/eliminated_units, que já existiam prontos
## ao final de CombatEngine.run(). Este teste roda uma batalha real
## ponta a ponta e confirma que o relatório passa a exibir sobreviventes
## por lado e os nomes reais dos Pelotões perdidos pelo jogador —
## sempre lidos de CombatState, nunca recalculados/inventados aqui.

static func _collect_label_texts(node: Node, out: Array[String]) -> void:
	if node is Label:
		out.append((node as Label).text)
	for child: Node in node.get_children():
		_collect_label_texts(child, out)


static func run(ctx: TestRunner.Context) -> bool:
	print("[Campo de Prova] Validando relatório com sobreviventes/baixas reais...")

	var panel := CampoDeProvaPanel.new()
	var army_a: Army = TestArmyFactory.generate_random_army()
	var army_b: Army = TestArmyFactory.generate_random_army()

	var state: CombatState = CombatEngine.initialize(army_a, army_b, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "pve", 777)
	CombatEngine.run(state)

	panel._last_state = state
	panel._last_army_a = army_a
	panel._last_army_b = army_b
	panel._last_battlefield = GameDatabase.battlefields[0]

	var container := Control.new()
	panel._build_relatorio_interior(container)

	var texts: Array[String] = []
	_collect_label_texts(container, texts)
	var full_text: String = "\n".join(texts)

	var survivors_a: int = state.units_of_side(0, true).size()
	var survivors_b: int = state.units_of_side(1, true).size()
	var expected_survivors_line: String = "Seus sobreviventes: %d/9 | Sobreviventes do oponente: %d/9" % [survivors_a, survivors_b]

	print("  [1] Relatório contém a linha real de sobreviventes ('%s')? %s" % [expected_survivors_line, str(texts.has(expected_survivors_line))])
	ctx.check(texts.has(expected_survivors_line), "[1] O relatório deve mostrar sobreviventes por lado, lidos de CombatState.units_of_side(), nunca um valor inventado")

	var lost_names: Array[String] = []
	for unit: CombatUnit in state.eliminated_units:
		if unit.side == 0 and unit.card != null:
			lost_names.append(unit.card.card_name)

	if lost_names.is_empty():
		print("  [2] Nenhum Pelotão do jogador morreu nesta batalha (seed 777) — linha de baixas corretamente omitida? %s" % str(not full_text.contains("Pelotões seus perdidos")))
		ctx.check(not full_text.contains("Pelotões seus perdidos"), "[2] Sem baixas do lado do jogador, o relatório não deve mostrar uma linha de baixas vazia")
	else:
		var expected_lost_line: String = "Pelotões seus perdidos: %s" % ", ".join(lost_names)
		print("  [2] Relatório contém a linha real de baixas ('%s')? %s" % [expected_lost_line, str(texts.has(expected_lost_line))])
		ctx.check(texts.has(expected_lost_line), "[2] O relatório deve nomear exatamente os Pelotões do jogador eliminados em CombatState.eliminated_units, nunca uma lista genérica")

	# NUNCA "sobreviventes + perdidos == 9": eliminated_units também
	# conta Pelotões Conjurados/Reanimados em combate (RESOURCES.md,
	# "Pelotão Conjurado" — existem de verdade, podem morrer, mas nunca
	# fizeram parte dos 9 slots originais). O roster original em si
	# (units_of_side(alive_only=false)) é que é sempre fixo em 9.
	var roster_size_a: int = state.units_of_side(0, false).size()
	print("  [3] Roster original do lado do jogador continua com 9 unidades (vivas+mortas, sem contar Conjuradas)? %d" % roster_size_a)
	ctx.check(roster_size_a == 9, "[3] units_of_side(0, false) deve sempre refletir as 9 posições originais do Exército, independente de quantos Pelotões Conjurados também tenham morrido")
	ctx.check(survivors_a <= roster_size_a, "[4] O número de sobreviventes nunca pode exceder o tamanho do roster original")

	panel.free()
	container.free()
	return true
