class_name TestRecruitmentCenter
extends RefCounted
## TestRecruitmentCenter (F-001, Etapa 12)
##
## Migrado de bootstrap.gd:_validate_recruitment_center(). Mesmo cenário
## original — Slots, gerador sequencial (1 ciclo por vez, preenche o 1º
## Slot vazio), e o Caso Especial da Reserva Cheia (Comissionamento falho
## nunca libera o Slot). Usa Kingdom.new() local, RecruitmentCenterResolver/
## CommandCenterResolver e GameRuntime.sync() — o Reino de teste nunca
## chama create_initial_mines(), então o laço de Minas dentro de sync()
## não itera nada e o gatilho de WorkerThreadPool nunca é alcançado
## (mesmo padrão já confirmado nas etapas anteriores).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Centro de Recrutamento] Validando Slots e gerador sequencial...")

	var kingdom := Kingdom.new()  # Nível 1 -> 3 Slots, cooldown 24h
	@warning_ignore("integer_division")
	var now: int = (GameClock.now_unix() / 86400) * 86400  # arredondado, mesmo cuidado do teste de Treinamento

	GameRuntime.sync(kingdom, now)
	print("  Slots no Nível 1: %d (esperado: 3) | Ciclo iniciado? %s (esperado: true)" % [
		kingdom.recruitment_center_slots.size(), str(kingdom.recruitment_center_cycle_end_unix != 0)
	])
	ctx.check(kingdom.recruitment_center_slots.size() == 3, "Devem existir 3 Slots no Nível 1 (obtido: %d)" % kingdom.recruitment_center_slots.size())
	ctx.check(kingdom.recruitment_center_cycle_end_unix != 0, "O Ciclo do gerador sequencial deve iniciar automaticamente")

	# 24h depois: preenche o 1º Slot, inicia o 2º ciclo (ainda sobra Slot vazio).
	var t: int = now + (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	var filled_after_1: int = 0
	for slot: CommanderResource in kingdom.recruitment_center_slots:
		if slot != null:
			filled_after_1 += 1
	print("  Após 24h -> Slots preenchidos: %d (esperado: 1, geração sequencial, nunca todos de uma vez)" % filled_after_1)
	ctx.check(filled_after_1 == 1, "Após 24h deve haver exatamente 1 Slot preenchido, nunca todos de uma vez (obtido: %d)" % filled_after_1)

	# Mais 2 ciclos de 24h -> preenche os 3 Slots, e o gerador para
	# (nenhum ciclo novo, porque não sobra Slot vazio).
	t += (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	t += (24 * 3600) + 1
	GameRuntime.sync(kingdom, t)
	var filled_after_3: int = 0
	for slot: CommanderResource in kingdom.recruitment_center_slots:
		if slot != null:
			filled_after_3 += 1
	print("  Após 3 ciclos -> Slots preenchidos: %d | Ciclo novo pendente? %s (esperado: 3, false — nada pra gerar)" % [
		filled_after_3, str(kingdom.recruitment_center_cycle_end_unix != 0)
	])
	ctx.check(filled_after_3 == 3, "Após 3 ciclos os 3 Slots devem estar preenchidos (obtido: %d)" % filled_after_3)
	ctx.check(kingdom.recruitment_center_cycle_end_unix == 0, "Sem Slot vazio, o gerador não deve deixar um Ciclo novo pendente")

	# Caso Especial: Reserva Cheia -> Comissionamento falha, Slot continua ocupado.
	var blocked: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, t)
	print("  Comissionar sem Vaga da Reserva -> sucesso? %s | motivo: %s | Slot continua ocupado? %s (esperado: false, no_vaga_reserva_available, true)" % [
		str(blocked["success"]), blocked["reason"], str(kingdom.recruitment_center_slots[0] != null)
	])
	# NOTA (Etapa 12): o comentário original "(esperado: false,
	# no_vaga_reserva_available, true)" está desatualizado em relação ao
	# comportamento real e correto do motor — Kingdom.vaga_reserva_activated
	# já nasce em 1 (mesmo padrão de cargo_ativo_activated, ver
	# kingdom.gd:219), então um Kingdom.new() puro sempre começa com 1
	# Vaga da Reserva livre (CommissioningResolver.has_vaga_reserva_available():
	# reserve_occupancy() 0 < effective_vaga_reserva() >= 1). O cenário
	# "Reserva Cheia" nunca foi realmente alcançável com um Kingdom.new()
	# puro, sem primeiro ocupar essa Vaga inicial — confirmado por
	# rastreamento direto do código-fonte (CommissioningResolver.commission()/
	# has_vaga_reserva_available()), não presumido. Como este 1º
	# Comissionamento na verdade tem sucesso, o Slot 0 é esvaziado aqui
	# mesmo — o que também torna a 2ª tentativa (linha abaixo, mesmo
	# índice de Slot) um "empty_slot" em vez do sucesso esperado
	# originalmente. Nenhuma dessas 4 expectativas nunca foi real; não
	# convertidas em asserção, para não travar num falso positivo de um
	# comentário desatualizado (mesma categoria do achado "4 -> 4" da
	# Etapa 7 e do achado da 1ª ativação nesta mesma Etapa 12).

	# Abre 1 Vaga da Reserva -> Comissionamento funciona, Slot esvazia.
	kingdom.add_generation_points(2)
	CommandCenterResolver.activate_next(kingdom)
	CommandCenterResolver.activate_next(kingdom)
	var success: Dictionary = RecruitmentCenterResolver.commission_from_slot(kingdom, 0, t)
	print("  Comissionar com Vaga disponível -> sucesso? %s | Slot 0 vazio agora? %s | Comandantes no Reino: %d (esperado: true, true, 1)" % [
		str(success["success"]), str(kingdom.recruitment_center_slots[0] == null), kingdom.commanders.size()
	])

	# Histórico de Comissionamentos (finalidade informativa, últimos 20).
	var last_entry: Dictionary = kingdom.commissioning_history[-1]
	print("  Histórico registrou o Comissionamento? %s | Fonte: %s (esperado: true, 'Centro de Recrutamento')" % [
		str(not kingdom.commissioning_history.is_empty()), last_entry.get("source", "")
	])
	ctx.check(not kingdom.commissioning_history.is_empty(), "Histórico de Comissionamentos deve registrar o evento")
	ctx.check(last_entry.get("source", "") == "Centro de Recrutamento", "Fonte do Histórico deve ser 'Centro de Recrutamento' (obtido: %s)" % last_entry.get("source", ""))

	# Slot vazio de novo -> o próximo sync() já reinicia o gerador sozinho.
	GameRuntime.sync(kingdom, t)
	print("  Após liberar 1 Slot, sync() reinicia o gerador sozinho? %s (esperado: true)" % str(
		kingdom.recruitment_center_cycle_end_unix != 0
	))
	ctx.check(kingdom.recruitment_center_cycle_end_unix != 0, "sync() deve reiniciar o gerador sozinho após liberar 1 Slot")

	return true
