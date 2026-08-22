class_name TestEnergyTimeRecovery
extends RefCounted
## TestEnergyTimeRecovery (F-001, Etapa 7)
##
## Migrado de bootstrap.gd:_validate_energy_time_recovery(). Mesmo
## cenário original — recuperação de Energia por tempo real (pontos
## completos recuperados de acordo com o tempo decorrido e o Nível do
## Núcleo, resto de segundos preservado entre sincronizações, teto na
## Energia Máxima, e recover_energy_full() zerando a referência de sync)
## — usando timestamps simulados (passado), exatamente como o original,
## e CampaignTestFixtures (já um class_name independente e puro —
## reutilizado diretamente, sem cópia).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Energia] Validando recuperação de Energia por tempo real...")

	var nucleus_level: int = 1
	var seconds_per_point: int = EnergyNucleus.recovery_seconds(nucleus_level)  # 450s (7m30s) no Nível 1
	var now: int = GameClock.now_unix()

	var army: Army = CampaignTestFixtures.build_campaign_test_army({"α": 1})
	army.initialize_energy(nucleus_level)
	army.consume_energy(10)
	print("  Energia após consumir 10: %d/%d" % [army.current_energy, army.max_energy])

	# Primeira sincronização (last_energy_sync_unix == 0): só estabelece
	# a referência, não concede recuperação retroativa.
	army.sync_energy_recovery(now, nucleus_level)
	print("  Primeira sincronização -> Energia inalterada? %s (esperado: true) | referência estabelecida? %s (esperado: true)" % [
		str(army.current_energy == army.max_energy - 10), str(army.last_energy_sync_unix == now)
	])
	ctx.check(army.current_energy == army.max_energy - 10, "Primeira sincronização não deve conceder recuperação retroativa")
	ctx.check(army.last_energy_sync_unix == now, "Primeira sincronização deve estabelecer a referência de tempo")

	# Passam 2 pontos e meio de tempo -> recupera exatamente 2 pontos,
	# preservando o meio ponto restante para a próxima sincronização.
	var elapsed_for_two_points: int = int(seconds_per_point * 2.5)
	army.sync_energy_recovery(now + elapsed_for_two_points, nucleus_level)
	print("  Após %d segundos (2,5 pontos) -> Energia: %d/%d (esperado: %d, +2 pontos)" % [
		elapsed_for_two_points, army.current_energy, army.max_energy, army.max_energy - 10 + 2
	])
	ctx.check(army.current_energy == army.max_energy - 10 + 2, "2,5 pontos de tempo devem recuperar exatamente 2 pontos completos (obtido: %d)" % army.current_energy)

	# O meio ponto restante + mais meio ponto completam o 3º ponto.
	var remaining_for_third_point: int = int(seconds_per_point * 0.5)
	army.sync_energy_recovery(now + elapsed_for_two_points + remaining_for_third_point, nucleus_level)
	print("  Meio ponto restante preservado corretamente -> Energia: %d/%d (esperado: %d, +3 pontos no total)" % [
		army.current_energy, army.max_energy, army.max_energy - 10 + 3
	])
	ctx.check(army.current_energy == army.max_energy - 10 + 3, "Meio ponto restante deve ser preservado e completar o 3º ponto (obtido: %d)" % army.current_energy)

	# Recuperação nunca ultrapassa a Energia Máxima, mesmo com tempo excessivo.
	army.sync_energy_recovery(now + elapsed_for_two_points + remaining_for_third_point + (seconds_per_point * 1000), nucleus_level)
	print("  Tempo excessivo -> Energia parou no máximo? %s (esperado: true, %d/%d)" % [
		str(army.current_energy == army.max_energy), army.current_energy, army.max_energy
	])
	ctx.check(army.current_energy == army.max_energy, "Recuperação nunca deve ultrapassar a Energia Máxima")

	# recover_energy_full() (Acampamento) zera a referência de sync, para
	# que a próxima sincronização gradual não trate o salto como recuperação.
	army.consume_energy(50)
	army.recover_energy_full()
	print("  Após recover_energy_full() -> Energia: %d/%d | referência de sync zerada? %s (esperado: true)" % [
		army.current_energy, army.max_energy, str(army.last_energy_sync_unix == 0)
	])
	ctx.check(army.last_energy_sync_unix == 0, "recover_energy_full() deve zerar a referência de sincronização")

	return true
