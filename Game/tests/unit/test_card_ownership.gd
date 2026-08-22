class_name TestCardOwnership
extends RefCounted
## TestCardOwnership (F-001, Etapa 7)
##
## Migrado de bootstrap.gd:_validate_card_ownership(). Mesmo cenário
## original — regra "uma carta, um lugar": adquirir cópias do catálogo
## dá RG único a cada uma; formar um Exército aloca as cartas (viram
## indisponíveis); tentar reutilizar uma carta já alocada é barrado;
## desfazer o Exército libera as cartas de volta — usando um Kingdom.new()
## local e CommandCenterResolver (confirmado sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap,
## direta ou transitiva).
##
## O teste original já tinha "(esperado: X)" explícito nos pontos-chave —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra. O print "RGs diferentes?" não tinha "(esperado: ...)" explícito
## no original e permanece apenas informativo, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Posse de Cartas] Validando RG único e a regra 'uma carta, um lugar'...")

	var kingdom := Kingdom.new()
	var catalog_card: CardResource = GameDatabase.get_card("Legionário Imperial")

	var copy_1: CardResource = kingdom.acquire_card_from_catalog(catalog_card)
	var copy_2: CardResource = kingdom.acquire_card_from_catalog(catalog_card)
	print("  Duas cópias adquiridas -> RGs diferentes? %s (RG 1: %d, RG 2: %d)" % [
		str(copy_1.instance_id != copy_2.instance_id), copy_1.instance_id, copy_2.instance_id
	])
	print("  Ambas Livres? %s (esperado: true)" % str(
		copy_1.ownership_status == CardResource.OwnershipStatus.LIVRE and
		copy_2.ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	ctx.check(
		copy_1.ownership_status == CardResource.OwnershipStatus.LIVRE and copy_2.ownership_status == CardResource.OwnershipStatus.LIVRE,
		"Ambas as cópias recém-adquiridas devem estar Livres"
	)

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Posse)"
	commander.faction = "Império"
	kingdom.add_commander(commander)
	print("  Comandante registrado no Reino -> RG: %d | Estado: %s | Disponível pra liderar Exército? %s (esperado: > 0, RESERVE, false — ainda não é Ativo)" % [
		commander.instance_id, CommanderResource.AdministrativeState.keys()[commander.administrative_state], str(kingdom.is_commander_available(commander))
	])
	ctx.check(commander.instance_id > 0, "Comandante registrado deve receber um RG > 0 (obtido: %d)" % commander.instance_id)
	ctx.check(commander.administrative_state == CommanderResource.AdministrativeState.RESERVE, "Comandante recém-registrado deve começar em RESERVE")
	ctx.check(kingdom.is_commander_available(commander) == false, "Comandante em RESERVE ainda não deve estar disponível para liderar Exército")

	# Precisa de um Cargo de Comando Ativo ativado (Expansão Administrativa)
	# antes de poder promover o Comandante a Ativo.
	kingdom.add_generation_points(10)
	CommandCenterResolver.activate_next(kingdom)  # ativa o 1º Cargo de Comando Ativo disponível no Nível 1
	var promote_result: Dictionary = CommandCenterResolver.move_to_active(kingdom, commander)
	print("  Promover a Ativo (com Cargo disponível) -> sucesso? %s | Disponível agora? %s (esperado: true, true)" % [
		str(promote_result["success"]), str(kingdom.is_commander_available(commander))
	])
	ctx.check(promote_result["success"] == true, "Promoção a Ativo deve ter sucesso com Cargo disponível")
	ctx.check(kingdom.is_commander_available(commander) == true, "Comandante Ativo deve estar disponível para liderar Exército")

	var nine_cards: Array[CardResource] = [copy_1, copy_2]
	for i in range(7):
		nine_cards.append(kingdom.acquire_card_from_catalog(catalog_card))

	var army: Army = kingdom.form_army(commander, nine_cards)
	print("  Exército formado com 9 cartas da coleção -> Exércitos no Reino: %d (esperado: 1)" % kingdom.armies.size())
	ctx.check(kingdom.armies.size() == 1, "Reino deve ter 1 Exército após form_army() (obtido: %d)" % kingdom.armies.size())

	print("  Cópia 1 agora está Livre? %s (esperado: false — está no Exército)" % str(
		copy_1.ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	ctx.check(copy_1.ownership_status != CardResource.OwnershipStatus.LIVRE, "Cópia alocada no Exército não deve mais estar Livre")

	print("  kingdom.is_card_available(copy_1)? %s (esperado: false)" % str(kingdom.is_card_available(copy_1)))
	ctx.check(kingdom.is_card_available(copy_1) == false, "Carta alocada no Exército não deve estar disponível")

	print("  Comandante ainda disponível para outro Exército? %s (esperado: false — já está liderando este)" % str(
		kingdom.is_commander_available(commander)
	))
	ctx.check(kingdom.is_commander_available(commander) == false, "Comandante liderando um Exército não deve estar disponível para outro")

	kingdom.disband_army(army)
	print("  Após desfazer o Exército -> copy_1 disponível de novo? %s | Comandante disponível de novo? %s | Exércitos no Reino: %d (esperado: true, true, 0)" % [
		str(kingdom.is_card_available(copy_1)), str(kingdom.is_commander_available(commander)), kingdom.armies.size()
	])
	ctx.check(kingdom.is_card_available(copy_1) == true, "copy_1 deve voltar a estar disponível após desfazer o Exército")
	ctx.check(kingdom.is_commander_available(commander) == true, "Comandante deve voltar a estar disponível após desfazer o Exército")
	ctx.check(kingdom.armies.size() == 0, "Reino não deve ter Exércitos após disband_army() (obtido: %d)" % kingdom.armies.size())

	return true
