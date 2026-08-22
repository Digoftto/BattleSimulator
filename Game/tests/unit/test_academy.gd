class_name TestAcademy
extends RefCounted
## TestAcademy (F-001, Etapa 16)
##
## Migrado de bootstrap.gd:_validate_academy(). Mesmo cenário original —
## produção de Carta Comum via Fragmento, fila com capacidade limitada
## (1 Artífice), Produção Automática de cadeia completa (Balista
## Imperial = Arqueiro + Engenheiro + Escudeiro Imperial), reaproveito
## de ingredientes já em mãos, Aprimoramento (3 cópias Tier I -> 1 Tier
## II), e cancelamento de tarefa em execução (deve ser recusado). Usa
## Kingdom.new() local e AcademyResolver/GameRuntime.sync() (confirmado
## na auditoria da Etapa 16: este cenário nunca popula nenhuma Mina —
## kingdom.territory_mines permanece vazio — logo GameRuntime.sync()
## nunca aciona o caminho de WorkerThreadPool/efficiency_permutation_order;
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime,
## direta ou transitiva). Nenhuma seed foi adicionada, nenhum código de
## produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Academia] Validando produção, receita, Aprimoramento e filas...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 1000)
	var now: int = GameClock.now_unix()

	kingdom.sync_academy_masters()
	print("  Nível 1 -> Artífices: %d | Metamorfos: %d (esperado: 1, 1)" % [
		kingdom.academy_artifices.size(), kingdom.academy_metamorfos.size()
	])
	ctx.check(kingdom.academy_artifices.size() == 1, "Nível 1 deve ter 1 Artífice (obtido: %d)" % kingdom.academy_artifices.size())
	ctx.check(kingdom.academy_metamorfos.size() == 1, "Nível 1 deve ter 1 Metamorfo (obtido: %d)" % kingdom.academy_metamorfos.size())

	# Produção de Carta Comum.
	var frags_before: int = kingdom.get_fragment("Império")
	var common_result: Dictionary = AcademyResolver.request_common_production(kingdom, "Legionário Imperial", 1, now)
	print("  Produzir 1 Legionário Imperial -> sucesso? %s | Fragmentos gastos: %d (esperado: true, 50)" % [
		str(common_result["success"]), frags_before - kingdom.get_fragment("Império")
	])
	ctx.check(common_result["success"] == true, "Produzir 1 Legionário Imperial deve ter sucesso")
	ctx.check(frags_before - kingdom.get_fragment("Império") == 50, "Deve gastar 50 Fragmentos (obtido: %d)" % (frags_before - kingdom.get_fragment("Império")))

	# Fila cheia: 2º pedido ao mesmo Artífice (só 1 existe) enfileira, não falha.
	var second_common: Dictionary = AcademyResolver.request_common_production(kingdom, "Escudeiro Imperial", 1, now)
	print("  2º pedido com Artífice ocupado -> sucesso? %s (esperado: false, fila cheia, capacidade 1)" % str(second_common["success"]))
	print("    motivo: %s (esperado: no_artifice_available)" % second_common["reason"])
	ctx.check(second_common["success"] == false, "2º pedido com Artífice ocupado deve falhar")
	ctx.check(second_common["reason"] == "no_artifice_available", "Motivo deve ser no_artifice_available (obtido: %s)" % second_common["reason"])

	# Avança o tempo além da duração (Comum: 120s Nível Base) -> conclui.
	GameRuntime.sync(kingdom, now + 121)
	var legionario_count: int = 0
	for card: CardResource in kingdom.cards:
		if card.card_name == "Legionário Imperial":
			legionario_count += 1
	print("  Após 121s -> Legionário Imperial na coleção? %d (esperado: 1) | XP de Conta: %d (esperado: 3, 1a obtenção)" % [
		legionario_count, kingdom.account_xp
	])
	ctx.check(legionario_count == 1, "Deve haver 1 Legionário Imperial na coleção após 121s (obtido: %d)" % legionario_count)
	ctx.check(kingdom.account_xp == 3, "XP de Conta deve ser 3 na 1ª obtenção (obtido: %d)" % kingdom.account_xp)

	# Produção Automática de cadeia completa: Balista Imperial = Arqueiro
	# + Engenheiro + Escudeiro Imperial, nenhum deles em mãos ainda —
	# a Academia precisa produzir os 3 sozinha antes de montar a Balista.
	var poor_kingdom := Kingdom.new()
	poor_kingdom.add_fragment("Império", 10)  # não cobre nem 1 Comum (50)
	var chain_fail: Dictionary = AcademyResolver.request_production(poor_kingdom, "Balista Imperial", 1, now)
	print("  Pedir Balista Imperial sem Fragmento suficiente pra cadeia inteira -> sucesso? %s | motivo: %s (esperado: false, insufficient_fragments)" % [
		str(chain_fail["success"]), chain_fail["reason"]
	])
	ctx.check(chain_fail["success"] == false, "Pedido sem Fragmento suficiente deve falhar")
	ctx.check(chain_fail["reason"] == "insufficient_fragments", "Motivo deve ser insufficient_fragments (obtido: %s)" % chain_fail["reason"])

	var chain_result: Dictionary = AcademyResolver.request_production(kingdom, "Balista Imperial", 1, now)
	print("  Pedir Balista Imperial (cadeia automática, 0 ingredientes em mãos) -> sucesso? %s (esperado: true)" % str(chain_result["success"]))
	print("  Tarefas pendentes aguardando Mestre/dependência logo após o pedido: %d (esperado: > 0)" % kingdom.academy_pending_chain_tasks.size())
	ctx.check(chain_result["success"] == true, "Pedido de cadeia automática deve ter sucesso")
	ctx.check(kingdom.academy_pending_chain_tasks.size() > 0, "Deve haver tarefas pendentes logo após o pedido (obtido: %d)" % kingdom.academy_pending_chain_tasks.size())

	# Só 1 Artífice (Nível 1): a cadeia inteira roda em sequência.
	# Avança o tempo em vários passos, como um jogador que volta a
	# checar o jogo de tempos em tempos — nunca tudo de uma vez só.
	var t: int = now
	for step in range(20):
		t += 500
		GameRuntime.sync(kingdom, t)

	var has_balista: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Balista Imperial":
			has_balista = true
	print("  Balista Imperial produzida ao final da cadeia automática? %s (esperado: true)" % str(has_balista))
	print("  Fila de pendentes vazia ao final? %s (esperado: true)" % str(kingdom.academy_pending_chain_tasks.is_empty()))
	ctx.check(has_balista == true, "Balista Imperial deve ser produzida ao final da cadeia automática")
	ctx.check(kingdom.academy_pending_chain_tasks.is_empty(), "Fila de pendentes deve estar vazia ao final")

	# Cadeia com 2 dos 3 ingredientes já em mãos (Legionário Imperial
	# sobrou da 1ª produção desta validação; Evocador Imperial acabou
	# de ser adquirido) — reaproveita os dois, produz só o Engenheiro.
	var evocador_template: CardResource = GameDatabase.get_card("Evocador Imperial")
	kingdom.acquire_card_from_catalog(evocador_template)
	var frags_before_capitao: int = kingdom.get_fragment("Império")
	var capitao_result: Dictionary = AcademyResolver.request_production(kingdom, "Capitão Imperial", 1, t)
	print("  Pedir Capitão Imperial com 2/3 ingredientes já em mãos -> sucesso? %s | Fragmentos gastos: %d (esperado: true, 50 = só 1 Comum faltando)" % [
		str(capitao_result["success"]), frags_before_capitao - kingdom.get_fragment("Império")
	])
	ctx.check(capitao_result["success"] == true, "Pedido de Capitão Imperial com 2/3 ingredientes deve ter sucesso")
	ctx.check(frags_before_capitao - kingdom.get_fragment("Império") == 50, "Deve gastar só 50 Fragmentos, 1 Comum faltando (obtido: %d)" % (frags_before_capitao - kingdom.get_fragment("Império")))

	# Aprimoramento: 3 cópias Tier I de Legionário Imperial -> 1 Tier II.
	var legionario_template: CardResource = GameDatabase.get_card("Legionário Imperial")
	kingdom.acquire_card_from_catalog(legionario_template)
	kingdom.acquire_card_from_catalog(legionario_template)
	kingdom.acquire_card_from_catalog(legionario_template)

	var upgrade_insufficient: Dictionary = AcademyResolver.request_upgrade(kingdom, "Legionário Imperial", 1, 5, t)
	print("  Tentar Aprimorar pedindo 5 lotes (15 cópias, só há 3) -> sucesso? %s | motivo: %s (esperado: false, insufficient_copies)" % [
		str(upgrade_insufficient["success"]), upgrade_insufficient["reason"]
	])
	ctx.check(upgrade_insufficient["success"] == false, "Aprimorar pedindo mais lotes do que se tem deve falhar")
	ctx.check(upgrade_insufficient["reason"] == "insufficient_copies", "Motivo deve ser insufficient_copies (obtido: %s)" % upgrade_insufficient["reason"])

	var upgrade_result: Dictionary = AcademyResolver.request_upgrade(kingdom, "Legionário Imperial", 1, 1, t)
	print("  Aprimorar 3x Legionário Imperial (Tier I -> II) -> sucesso? %s (esperado: true)" % str(upgrade_result["success"]))
	ctx.check(upgrade_result["success"] == true, "Aprimorar 3x Legionário Imperial deve ter sucesso")

	var upgrade_duration: int = AcademyEconomy.upgrade_time_seconds(2, "Comum", kingdom.academy_level)
	GameRuntime.sync(kingdom, t + upgrade_duration + 1)
	var has_tier2: bool = false
	for card: CardResource in kingdom.cards:
		if card.card_name == "Legionário Imperial" and card.tier == 2:
			has_tier2 = true
	print("  Legionário Imperial Tier II presente após o Aprimoramento? %s (esperado: true)" % str(has_tier2))
	print("  XP de Conta 'Tier 2 pela 1a vez' concedido? %s (esperado: true, XP total > antes)" % str(kingdom.has_structural_xp("card_tier:Legionário Imperial:2")))
	ctx.check(has_tier2 == true, "Legionário Imperial Tier II deve estar presente após o Aprimoramento")
	ctx.check(kingdom.has_structural_xp("card_tier:Legionário Imperial:2"), "XP de Conta 'Tier 2 pela 1a vez' deve ter sido concedido")

	# Cancelamento antes do início devolve o reservado.
	var cancel_kingdom := Kingdom.new()
	cancel_kingdom.add_fragment("Império", 200)
	cancel_kingdom.sync_academy_masters()
	var cancel_now: int = GameClock.now_unix()
	AcademyResolver.request_common_production(cancel_kingdom, "Legionário Imperial", 1, cancel_now)  # ocupa o único Artífice
	AcademyResolver.request_common_production(cancel_kingdom, "Escudeiro Imperial", 1, cancel_now)  # fila cheia -> falha, nada reservado

	var master: AcademyMaster = cancel_kingdom.academy_artifices[0]
	var running_task: AcademyTask = master.current_task()
	var frags_before_cancel: int = cancel_kingdom.get_fragment("Império")
	var cancel_running: bool = AcademyResolver.cancel_task(cancel_kingdom, master, running_task)
	print("  Cancelar a tarefa que já está em execução -> permitido? %s (esperado: false)" % str(cancel_running))
	print("  Fragmentos inalterados após tentativa inválida de cancelar? %s (esperado: true)" % str(cancel_kingdom.get_fragment("Império") == frags_before_cancel))
	ctx.check(cancel_running == false, "Cancelar uma tarefa já em execução não deve ser permitido")
	ctx.check(cancel_kingdom.get_fragment("Império") == frags_before_cancel, "Fragmentos devem ficar inalterados após tentativa inválida de cancelar")

	return true
