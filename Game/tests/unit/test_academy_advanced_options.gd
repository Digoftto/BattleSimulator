class_name TestAcademyAdvancedOptions
extends RefCounted
## TestAcademyAdvancedOptions (F-001, Etapa 15)
##
## Migrado de bootstrap.gd:_validate_academy_advanced_options(). Mesmo
## cenário original — Previsão (sem comprometer nada), Preservar
## Inventário, Editar Receita (forçar existing/produce por ingrediente),
## e Modo Conservador (usa só 1 Mestre por vez). Usa Kingdom.new() local
## e AcademyResolver (confirmado sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou
## transitiva).
##
## O teste original já tinha "(esperado: X)" explícito em cada ponto-chave
## — convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Academia] Validando Previsão, Preservar Inventário, Editar Receita e Modo Conservador...")

	var kingdom := Kingdom.new()
	kingdom.add_fragment("Império", 10000)

	# Previsão: não deve comprometer nada.
	var frags_before_preview: int = kingdom.get_fragment("Império")
	var preview: Dictionary = AcademyResolver.preview_production(kingdom, "Balista Imperial", 1)
	print("  Previsão de Balista Imperial (0 em mãos) -> custo total: %d (esperado: 150 = 3x50) | pagável? %s" % [
		preview["total_fragment_cost"], str(preview["affordable"])
	])
	ctx.check(preview["total_fragment_cost"] == 150, "Custo total da Previsão deve ser 150 = 3x50 (obtido: %d)" % preview["total_fragment_cost"])

	print("  Previsão não gastou nada de verdade? %s (esperado: true)" % str(kingdom.get_fragment("Império") == frags_before_preview))
	ctx.check(kingdom.get_fragment("Império") == frags_before_preview, "Previsão não deve gastar Fragmentos de verdade")

	# Preservar Inventário: ignora cópia já existente, produz do zero mesmo assim.
	var arqueiro_template: CardResource = GameDatabase.get_card("Arqueiro Imperial")
	var owned_arqueiro: CardResource = kingdom.acquire_card_from_catalog(arqueiro_template)
	var frags_before_preserve: int = kingdom.get_fragment("Império")
	AcademyResolver.request_production(kingdom, "Balista Imperial", 1, GameClock.now_unix(), true)
	print("  Preservar Inventário (1 Arqueiro em mãos, ignorado de propósito) -> Fragmentos gastos: %d (esperado: 150, os 3 do zero)" % [
		frags_before_preserve - kingdom.get_fragment("Império")
	])
	ctx.check(frags_before_preserve - kingdom.get_fragment("Império") == 150, "Preservar Inventário deve gastar 150 Fragmentos (produção do zero, obtido: %d)" % (frags_before_preserve - kingdom.get_fragment("Império")))

	print("  O Arqueiro Imperial original continua Livre, intocado? %s (esperado: true)" % str(
		owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	ctx.check(owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE, "Arqueiro Imperial original deve continuar Livre após Preservar Inventário")

	# Editar Receita: força "produce" mesmo tendo cópia, e "existing" pra outro que não existe -> falha.
	var override_fail: Dictionary = AcademyResolver.request_production(
		kingdom, "Balista Imperial", 1, GameClock.now_unix(), false,
		{"Arqueiro Imperial": "produce", "Engenheiro Imperial": "existing"}
	)
	print("  Editar Receita forçando 'existing' num ingrediente sem cópia -> sucesso? %s | motivo: %s | faltando: %s (esperado: false, forced_existing_unavailable, Engenheiro Imperial)" % [
		str(override_fail["success"]), override_fail["reason"], override_fail.get("missing_ingredient", "")
	])
	ctx.check(override_fail["success"] == false, "Editar Receita forçando 'existing' sem cópia disponível deve falhar")
	ctx.check(override_fail["reason"] == "forced_existing_unavailable", "Motivo da falha deve ser forced_existing_unavailable (obtido: %s)" % override_fail["reason"])
	ctx.check(override_fail.get("missing_ingredient", "") == "Engenheiro Imperial", "Ingrediente faltando deve ser Engenheiro Imperial (obtido: %s)" % override_fail.get("missing_ingredient", ""))

	print("  O Arqueiro Imperial original continua intocado após a falha? %s (esperado: true)" % str(
		owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE
	))
	ctx.check(owned_arqueiro.ownership_status == CardResource.OwnershipStatus.LIVRE, "Arqueiro Imperial original deve continuar intocado após a falha de Editar Receita")

	# Modo Conservador: com 2 Artífices livres (Nível 4), usa só 1 por vez.
	var conservative_kingdom := Kingdom.new()
	conservative_kingdom.add_fragment("Império", 10000)
	conservative_kingdom.academy_level = 4
	conservative_kingdom.sync_academy_masters()
	print("  Reino de teste (Nível 4) -> Artífices disponíveis: %d (esperado: 2)" % conservative_kingdom.academy_artifices.size())
	ctx.check(conservative_kingdom.academy_artifices.size() == 2, "Reino de Nível 4 deve ter 2 Artífices disponíveis (obtido: %d)" % conservative_kingdom.academy_artifices.size())

	AcademyResolver.request_production(conservative_kingdom, "Balista Imperial", 1, GameClock.now_unix(), false, {}, "conservador")
	var busy_masters_conservative: int = 0
	for master: AcademyMaster in conservative_kingdom.academy_artifices:
		if master.is_busy():
			busy_masters_conservative += 1
	print("  Modo Conservador (3 Comuns necessários, 2 Artífices livres) -> Artífices ocupados imediatamente: %d (esperado: 1, só o primeiro)" % busy_masters_conservative)
	ctx.check(busy_masters_conservative == 1, "Modo Conservador deve ocupar só 1 Artífice imediatamente (obtido: %d)" % busy_masters_conservative)

	# Comparação: Modo Prioritário usa quantos Mestres livres houver.
	var priority_kingdom := Kingdom.new()
	priority_kingdom.add_fragment("Império", 10000)
	priority_kingdom.academy_level = 4
	priority_kingdom.sync_academy_masters()
	AcademyResolver.request_production(priority_kingdom, "Balista Imperial", 1, GameClock.now_unix(), false, {}, "prioritario")
	var busy_masters_priority: int = 0
	for master: AcademyMaster in priority_kingdom.academy_artifices:
		if master.is_busy():
			busy_masters_priority += 1
	print("  Modo Prioritário (mesmo cenário) -> Artífices ocupados imediatamente: %d (esperado: 2, os dois disponíveis)" % busy_masters_priority)
	ctx.check(busy_masters_priority == 2, "Modo Prioritário deve ocupar os 2 Artífices disponíveis (obtido: %d)" % busy_masters_priority)

	return true
