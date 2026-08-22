class_name TestEnergyRecoversOverRealTime
extends RefCounted
## TestEnergyRecoversOverRealTime (F-001, Etapa 13)
##
## Migrado de bootstrap.gd:_validate_energy_recovers_over_real_time().
## Mesmo cenário original — validação FUNCIONAL do bug real relatado: um
## Exército sem Energia deve recuperar com o tempo (ENERGY.md,
## "Recuperação de Energia" — na Cidade ou em Acampamento). Testa o
## mecanismo de verdade (Army.sync_energy_recovery via GameRuntime.sync),
## com o tempo avançando de verdade, não instantâneo. Usa Kingdom.new()
## local e CommandCenterResolver/GameRuntime.sync() (confirmado sem
## nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## WorldBootstrap, direta ou transitiva; GameRuntime.sync() na forma já
## confirmada limpa em etapas anteriores).
##
## SETUP PRESERVADO EXATAMENTE COMO ESTAVA (Etapa 13, per instrução
## explícita): "kingdom.cargo_ativo_activated += 1" muda o valor default
## (1, ver kingdom.gd:218) para 2, acima do teto de Infraestrutura do
## Nível 1 (1 Ativo). Nenhuma correção foi aplicada — nem aqui, nem em
## produção. Comportamento observado durante o gate de teste individual:
## ver bloco de comentário abaixo, preenchido após a execução real.
##
## O teste original só tinha "(esperado: X)" explícito nos prints
## posteriores ao esgotamento — o print de "Energia inicial" não tinha
## marcador de expectativa explícito no original e permanece apenas
## informativo, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Energia] Validando que um Exército sem Energia recupera de verdade com o tempo (bug relatado)...")

	var kingdom := Kingdom.new()
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Energia)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	print("  Energia inicial: %d/%d" % [army.current_energy, army.max_energy])
	army.consume_energy(army.current_energy)  # zera de propósito, simulando "sem Energia"
	print("  Energia depois de esgotar: %d/%d (esperado: 0)" % [army.current_energy, army.max_energy])
	ctx.check(army.current_energy == 0, "Energia deve ser 0 após esgotar de propósito (obtido: %d)" % army.current_energy)

	var now: int = GameClock.now_unix()
	GameRuntime.sync(kingdom, now)  # 1ª chamada só estabelece a referência de tempo (documentado, sem recuperação retroativa)
	print("  Logo após esgotar (1ª sincronização, sem tempo real decorrido ainda): %d/%d (esperado: 0, sem recuperação retroativa)" % [
		army.current_energy, army.max_energy
	])
	ctx.check(army.current_energy == 0, "1ª sincronização não deve conceder recuperação retroativa (obtido: %d)" % army.current_energy)

	now += 3600 * 24  # +24h reais
	GameRuntime.sync(kingdom, now)
	print("  24h reais depois -> Energia recuperou de verdade? %s (%d/%d, esperado: > 0)" % [
		str(army.current_energy > 0), army.current_energy, army.max_energy
	])
	ctx.check(army.current_energy > 0, "Energia deve recuperar de verdade após 24h reais (obtido: %d)" % army.current_energy)

	now += 3600 * 24 * 30  # +30 dias reais — tempo de sobra pra qualquer Núcleo de Energia recuperar 100%
	GameRuntime.sync(kingdom, now)
	print("  30 dias reais depois -> Energia totalmente recuperada? %s (%d/%d, esperado: true)" % [
		str(army.current_energy == army.max_energy), army.current_energy, army.max_energy
	])
	ctx.check(army.current_energy == army.max_energy, "Energia deve estar totalmente recuperada após 30 dias reais (obtido: %d/%d)" % [army.current_energy, army.max_energy])

	return true
