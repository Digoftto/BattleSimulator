class_name TestSupportOvertake
extends RefCounted
## TestSupportOvertake (FASE 8, 2026-09-04)
##
## Testes de INTEGRAÇÃO diretamente sobre CombatEngine._movement_phase()
## (nunca só _can_advance()/_non_support_advance_target() isoladas) —
## cobre a ULTRAPASSAGEM (COMBAT_RULES.md §6.5, cláusula final: "o
## pelotão bloqueador... pode ultrapassar a posição do bloco de
## Suportes que ele mantém parado"), implementada nesta tarefa como o
## Estágio 1 (não-Suporte, com _non_support_advance_target() pulando
## células de Suporte) sempre antes do Estágio 2 (Suporte, regra
## _support_chain_clear() 100% inalterada) de cada passada.
##
## Casos obrigatórios do pedido: C, H, I, L (Exemplo Oficial completo,
## nas 2 transições), regressão (A/D/E/F/G da matriz da auditoria +
## cascata multi-pass + 9->1), e o teste específico de não-regressão da
## seção 10 (Suporte nunca vira uma "passagem" para OUTRA unidade
## convencional/Barreira/MdG bloqueando o caminho).

static func run(ctx: TestRunner.Context) -> bool:
	print("[Suporte/Ultrapassagem] Validando _movement_phase() com a ultrapassagem de Suporte (COMBAT_RULES.md §6.5)...")
	_test_c_h_convencional_ultrapassa_suporte_com_espaco(ctx)
	_test_i_convencional_nao_ultrapassa_sem_espaco(ctx)
	_test_l_exemplo_oficial_completo(ctx)
	_test_mdg_nao_ultrapassa_suporte(ctx)
	_test_secao10_suporte_nao_vira_passagem_para_outras_classes(ctx)
	_test_regressao_convencional_atras_de_convencional(ctx)
	_test_regressao_suporte_suporte(ctx)
	_test_regressao_suporte_maquina_de_guerra(ctx)
	_test_regressao_multiplos_suportes_em_cadeia(ctx)
	_test_regressao_cascata_multi_pass(ctx)
	_test_regressao_9_ate_1(ctx)
	return true


static func _card(name_suffix: String, card_class: String) -> CardResource:
	return TestMovementRules._build_combat_card("Overtake-%s" % name_suffix, card_class, 50, 50, 10)


## TESTE C/H: Convencional (6) atrás de Suporte (5), espaço vazio à
## frente do Suporte (4). A convencional deve ultrapassar — 1 único
## evento MOVE de 6 direto pra 4 (nunca um "6->5" falso). O Suporte,
## tendo perdido a vaga pra convencional, permanece em 5.
static func _test_c_h_convencional_ultrapassa_suporte_com_espaco(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	# 1/2/3 fixam a frente (nunca vagam) — isola o "espaço à frente do
	# Suporte" exatamente na Posição 4, o alvo real deste teste, em vez
	# de deixar tudo cascatear até a Posição 1.
	var p1 := CombatUnit.new(_card("C-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("C-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("C-P3", "Corpo a Corpo"), 0, 3)
	var conventional := CombatUnit.new(_card("C-Convencional", "À Distância"), 0, 6)
	var support := CombatUnit.new(_card("C-Suporte", "Suporte"), 0, 5)
	state.units = [p1, p2, p3, conventional, support]  # Posição 4 vazia, de propósito

	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	collector.attach(state.event_bus)

	CombatEngine._movement_phase(state)

	print("  [C/H] Convencional (6) ultrapassa o Suporte (5) e ocupa a Posição 4? %s (obtido: %d)" % [str(conventional.position == 4), conventional.position])
	ctx.check(conventional.position == 4, "[C/H] A convencional deve ultrapassar o Suporte e ocupar a Posição 4 (espaço válido além dele)")
	print("  [C/H] Suporte permanece na Posição 5 (perdeu a vaga pra convencional)? %s (obtido: %d)" % [str(support.position == 5), support.position])
	ctx.check(support.position == 5, "[C/H] O Suporte deve permanecer na Posição 5 — a convencional tem prioridade sobre a vaga livre")

	var move_events: Array = collector.replay_events.filter(func(e): return e["kind"] == "move")
	print("  [C/H] Exatamente 1 evento MOVE (nenhum passo intermediário falso por 5)? %d evento(s): %s" % [move_events.size(), str(move_events)])
	ctx.check(move_events.size() == 1, "[C/H] Deve existir exatamente 1 evento MOVE (o salto direto, nunca um evento fantasma parando em 5)")
	if move_events.size() == 1:
		ctx.check(move_events[0]["unit_id"] == conventional.get_instance_id(), "[C/H] O evento MOVE deve pertencer à convencional (por unit_id)")


## TESTE I: Convencional (6) atrás de Suporte (5), SEM espaço válido
## além dele (Posição 4 ocupada por outra convencional, permanentemente
## fixada por 1/2/3 ocupadas). A convencional de trás deve permanecer
## bloqueada — nunca ultrapassa pra dentro de uma célula ocupada.
static func _test_i_convencional_nao_ultrapassa_sem_espaco(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var p1 := CombatUnit.new(_card("I-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("I-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("I-P3", "Corpo a Corpo"), 0, 3)
	var p4 := CombatUnit.new(_card("I-P4", "Corpo a Corpo"), 0, 4)  # permanentemente fixada (1/2/3 ocupadas)
	var support := CombatUnit.new(_card("I-Suporte", "Suporte"), 0, 5)
	var conventional := CombatUnit.new(_card("I-Convencional", "À Distância"), 0, 6)
	state.units = [p1, p2, p3, p4, support, conventional]

	CombatEngine._movement_phase(state)

	print("  [I] Sem espaço válido além do Suporte: convencional permanece bloqueada na Posição 6? %s (obtido: %d)" % [str(conventional.position == 6), conventional.position])
	ctx.check(conventional.position == 6, "[I] A convencional NUNCA deve ultrapassar pra dentro de uma célula ocupada — sem espaço real, permanece bloqueada")
	ctx.check(support.position == 5, "[I] O Suporte também permanece bloqueado (front ocupado por P4)")
	ctx.check(p4.position == 4, "[I] P4 permanece fixada (Posições 1/2/3 ocupadas, sem nenhuma relação com Suporte)")


## TESTE L: Exemplo Oficial completo (relatório da auditoria da Fase 8),
## as DUAS transições, sobre _movement_phase() de verdade — nenhuma
## lógica especial de caso, só a regra geral rodando 2 vezes (a 2ª
## depois de uma "morte" abrindo espaço na Posição 3).
static func _test_l_exemplo_oficial_completo(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var p1 := CombatUnit.new(_card("L-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("L-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("L-P3", "Corpo a Corpo"), 0, 3)
	var support := CombatUnit.new(_card("L-Suporte", "Suporte"), 0, 5)
	var ranged := CombatUnit.new(_card("L-ADistancia", "À Distância"), 0, 7)
	var mdg := CombatUnit.new(_card("L-MdG", "Máquina de Guerra"), 0, 9)
	state.units = [p1, p2, p3, support, ranged, mdg]  # Posições 4, 6, 8 vazias

	CombatEngine._movement_phase(state)

	print("  [L.1] Transição 1 — posições: MdG=%d Suporte=%d ADistancia=%d (esperado: 6, 5, 4)" % [mdg.position, support.position, ranged.position])
	ctx.check(mdg.position == 6, "[L.1] MdG deve ocupar a Posição 6 (cadeia opaca através do Suporte, regra inalterada)")
	ctx.check(support.position == 5, "[L.1] Suporte deve PERMANECER na Posição 5 — a À Distância tem prioridade sobre a vaga livre à frente dele")
	ctx.check(ranged.position == 4, "[L.1] À Distância deve ULTRAPASSAR o Suporte e ocupar a Posição 4")

	# "Depois, quando surge espaço à frente": P3 morre/sai — mesma
	# técnica já usada por test_movement_sequence_compaction.gd (a
	# unidade simplesmente não é incluída em state.units, nunca
	# "removida" de um array; CombatState.unit_at() só enxerga quem
	# está na lista).
	state.units = [p1, p2, support, ranged, mdg]

	CombatEngine._movement_phase(state)

	print("  [L.2] Transição 2 — posições: ADistancia=%d MdG=%d Suporte=%d (esperado: 3, 5, 4)" % [ranged.position, mdg.position, support.position])
	ctx.check(ranged.position == 3, "[L.2] À Distância avança normalmente de 4 para 3 (vaga simples, sem Suporte envolvido)")
	ctx.check(support.position == 4, "[L.2] Suporte avança de 5 para 4 (cadeia: atrás dele agora está o MdG, opaco — regra inalterada)")
	ctx.check(mdg.position == 5, "[L.2] MdG avança de 6 para 5 (vaga simples deixada pelo Suporte, sem ultrapassagem — MdG não ultrapassa)")


## Confirma explicitamente que Máquina de Guerra NUNCA ultrapassa
## Suporte (6.6: "segue normalmente as regras gerais", sem exceção
## equivalente à do Suporte). Nota estrutural: como MdG é opaca à
## própria cadeia do Suporte (6.5), um Suporte com MdG imediatamente
## atrás NUNCA fica permanentemente bloqueado — por isso não é possível
## isolar "MdG parada atrás de um Suporte preso pra sempre" (essa
## combinação não existe pela regra). O teste real e observável aqui é:
## MdG nunca termina à FRENTE de onde o Suporte está, nem pula pra uma
## célula além dele — MdG deve terminar SEMPRE exatamente na posição
## imediatamente atrás do Suporte (nunca ultrapassando, mesmo numa
## cascata livre até a Posição 1/2).
static func _test_mdg_nao_ultrapassa_suporte(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var mdg := CombatUnit.new(_card("MdG-Atras", "Máquina de Guerra"), 0, 6)
	var support := CombatUnit.new(_card("MdG-Suporte", "Suporte"), 0, 5)
	state.units = [mdg, support]  # tabuleiro livre adiante — cascata completa

	CombatEngine._movement_phase(state)

	var expected_mdg_position: int = CombatBoard.support_position_behind(support.position)
	print("  [MdG] MdG termina EXATAMENTE atrás do Suporte, nunca ultrapassando-o? Suporte=%d MdG=%d (esperado MdG=%d)" % [support.position, mdg.position, expected_mdg_position])
	ctx.check(mdg.position == expected_mdg_position, "[MdG] A MdG deve terminar EXATAMENTE na posição imediatamente atrás do Suporte, nunca ultrapassando-o — Suporte=%d, MdG=%d" % [support.position, mdg.position])
	ctx.check(support.position == 1, "[MdG] Sem nada bloqueando, o Suporte deve cascatear livremente até a Posição 1 (MdG sempre opaca à sua cadeia)")


## SEÇÃO 10 do pedido: Suporte NUNCA vira uma "passagem" pra outras
## Classes bloqueando o caminho — testa explicitamente as 5 Classes
## (Corpo a Corpo, Barreira, À Distância, Mago, Máquina de Guerra) como
## bloqueador FIXO na frente de um Suporte, confirmando que uma
## convencional mais atrás NUNCA ultrapassa o Suporte pra colidir com
## essas Classes — só células de Suporte são puláveis, nunca outra
## Classe qualquer.
static func _test_secao10_suporte_nao_vira_passagem_para_outras_classes(ctx: TestRunner.Context) -> void:
	var blocker_classes: Array[String] = ["Corpo a Corpo", "Barreira", "À Distância", "Mago", "Máquina de Guerra"]
	for blocker_class in blocker_classes:
		var state := CombatState.new()
		var p1 := CombatUnit.new(_card("S10-P1-%s" % blocker_class, "Corpo a Corpo"), 0, 1)
		var p2 := CombatUnit.new(_card("S10-P2-%s" % blocker_class, "Corpo a Corpo"), 0, 2)
		var p3 := CombatUnit.new(_card("S10-P3-%s" % blocker_class, "Corpo a Corpo"), 0, 3)
		var front_blocker := CombatUnit.new(_card("S10-Blocker-%s" % blocker_class, blocker_class), 0, 4)
		var support := CombatUnit.new(_card("S10-Suporte-%s" % blocker_class, "Suporte"), 0, 5)
		var conventional := CombatUnit.new(_card("S10-Conv-%s" % blocker_class, "À Distância"), 0, 6)
		state.units = [p1, p2, p3, front_blocker, support, conventional]

		CombatEngine._movement_phase(state)

		print("  [S10] Bloqueador='%s' na Posição 4 — convencional (6) permanece bloqueada atrás do Suporte (5)? %s (obtido: %d)" % [blocker_class, str(conventional.position == 6), conventional.position])
		ctx.check(conventional.position == 6, "[S10] Com '%s' fixo na Posição 4, a convencional atrás do Suporte NUNCA deve ultrapassar (só Suporte é pulável, nunca outra Classe)" % blocker_class)
		ctx.check(support.position == 5, "[S10] O Suporte também permanece bloqueado (front ocupado por '%s')" % blocker_class)
		ctx.check(front_blocker.position == 4, "[S10] O bloqueador '%s' permanece fixo (1/2/3 ocupadas)" % blocker_class)


static func _test_regressao_convencional_atras_de_convencional(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var front := CombatUnit.new(_card("Reg-A-Frente", "Corpo a Corpo"), 0, 1)
	var back := CombatUnit.new(_card("Reg-A-Tras", "Corpo a Corpo"), 0, 2)
	state.units = [back]  # Posição 1 vazia — back deve simplesmente avançar
	CombatEngine._movement_phase(state)
	print("  [Regressão A] Convencional avança normalmente pra célula vazia? %s (obtido: %d)" % [str(back.position == 1), back.position])
	ctx.check(back.position == 1, "[Regressão A] Convencional atrás de convencional (célula vazia) continua avançando normalmente")


static func _test_regressao_suporte_suporte(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var p1 := CombatUnit.new(_card("Reg-D-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("Reg-D-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("Reg-D-P3", "Corpo a Corpo"), 0, 3)
	var support_a := CombatUnit.new(_card("Reg-D-A", "Suporte"), 0, 5)
	var support_b := CombatUnit.new(_card("Reg-D-B", "Suporte"), 0, 6)
	state.units = [p1, p2, p3, support_a, support_b]  # Posição 4 e 7 vazias
	CombatEngine._movement_phase(state)
	print("  [Regressão D] Suporte->Suporte->vazio: ambos avançam? A=%d B=%d (esperado: 4, 5)" % [support_a.position, support_b.position])
	ctx.check(support_a.position == 4, "[Regressão D] Suporte A deve avançar normalmente")
	ctx.check(support_b.position == 5, "[Regressão D] Suporte B deve avançar normalmente atrás de A")


static func _test_regressao_suporte_maquina_de_guerra(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var p1 := CombatUnit.new(_card("Reg-E-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("Reg-E-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("Reg-E-P3", "Corpo a Corpo"), 0, 3)
	var support := CombatUnit.new(_card("Reg-E-Suporte", "Suporte"), 0, 5)
	var mdg := CombatUnit.new(_card("Reg-E-MdG", "Máquina de Guerra"), 0, 6)
	state.units = [p1, p2, p3, support, mdg]  # Posição 4 vazia
	CombatEngine._movement_phase(state)
	print("  [Regressão E] Suporte->MdG (opaca): Suporte avança? %s (obtido: %d)" % [str(support.position == 4), support.position])
	ctx.check(support.position == 4, "[Regressão E] Suporte deve avançar normalmente com MdG imediatamente atrás (opaca à cadeia, regra inalterada)")


static func _test_regressao_multiplos_suportes_em_cadeia(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var p1 := CombatUnit.new(_card("Reg-K-P1", "Corpo a Corpo"), 0, 1)
	var p2 := CombatUnit.new(_card("Reg-K-P2", "Corpo a Corpo"), 0, 2)
	var p3 := CombatUnit.new(_card("Reg-K-P3", "Corpo a Corpo"), 0, 3)
	var s1 := CombatUnit.new(_card("Reg-K-1", "Suporte"), 0, 5)
	var s2 := CombatUnit.new(_card("Reg-K-2", "Suporte"), 0, 6)
	var s3 := CombatUnit.new(_card("Reg-K-3", "Suporte"), 0, 7)
	state.units = [p1, p2, p3, s1, s2, s3]  # Posição 4, 8, 9 vazias
	CombatEngine._movement_phase(state)
	print("  [Regressão K] Cadeia de 3 Suportes avança inteira? %d,%d,%d (esperado: 4,5,6)" % [s1.position, s2.position, s3.position])
	ctx.check(s1.position == 4 and s2.position == 5 and s3.position == 6, "[Regressão K] Cadeia de múltiplos Suportes deve compactar inteira (transparência recursiva inalterada)")


## Mesmo cenário do log fornecido pelo usuário como evidência (Fase 8,
## auditoria): 3 unidades numa fila, uma morte à frente abre espaço, e
## MÚLTIPLOS eventos MOVE pra mesma unidade no mesmo turno continuam
## sendo o comportamento correto (nunca eliminado por esta correção).
static func _test_regressao_cascata_multi_pass(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var u1 := CombatUnit.new(_card("Reg-Cascata-1", "Corpo a Corpo"), 0, 1)
	var u2 := CombatUnit.new(_card("Reg-Cascata-2", "Corpo a Corpo"), 0, 2)
	var u5 := CombatUnit.new(_card("Reg-Cascata-5", "Corpo a Corpo"), 0, 5)
	var u6 := CombatUnit.new(_card("Reg-Cascata-6", "Corpo a Corpo"), 0, 6)
	var u7 := CombatUnit.new(_card("Reg-Cascata-7", "Corpo a Corpo"), 0, 7)
	state.units = [u1, u2, u5, u6, u7]  # Posições 3, 4, 8, 9 vazias

	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()
	collector.attach(state.event_bus)

	CombatEngine._movement_phase(state)

	print("  [Regressão Cascata] Posições finais: u5=%d u6=%d u7=%d (esperado: 3, 4, 5)" % [u5.position, u6.position, u7.position])
	ctx.check(u5.position == 3, "[Regressão Cascata] u5 deve cascatear até a Posição 3 (3 vazia, 4 e a própria 5 livres em sequência)")
	ctx.check(u6.position == 4, "[Regressão Cascata] u6 deve cascatear até a Posição 4")
	ctx.check(u7.position == 5, "[Regressão Cascata] u7 deve cascatear até a Posição 5")

	var move_events_u5: Array = collector.replay_events.filter(func(e): return e["kind"] == "move" and e["unit_id"] == u5.get_instance_id())
	print("  [Regressão Cascata] u5 recebeu múltiplos eventos MOVE no mesmo turno (comportamento preservado)? %d evento(s)" % move_events_u5.size())
	ctx.check(move_events_u5.size() >= 2, "[Regressão Cascata] Uma unidade ainda pode receber múltiplos eventos MOVE na mesma Fase — esta correção não elimina a cascata multi-pass")


static func _test_regressao_9_ate_1(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var mover := CombatUnit.new(_card("Reg-9a1", "Corpo a Corpo"), 0, 9)
	state.units = [mover]  # Tabuleiro vazio, exceto o próprio mover
	CombatEngine._movement_phase(state)
	print("  [Regressão 9->1] Única unidade no tabuleiro chega até a Posição 1? %s (obtido: %d)" % [str(mover.position == 1), mover.position])
	ctx.check(mover.position == 1, "[Regressão 9->1] Com o tabuleiro vazio, a unidade deve atravessar 9->8->...->1 na mesma Fase")
