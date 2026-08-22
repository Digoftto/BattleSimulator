class_name TestCommanderTrainingXp
extends RefCounted
## TestCommanderTrainingXp (F-001, Etapa 12)
##
## Migrado de bootstrap.gd:_validate_commander_training_xp(). Mesmo
## cenário original — acúmulo de XP de Treinamento
## (COMMAND_CENTER_TRAINING.md): Média Diária calculada corretamente, 20%
## creditado por dia fechado, Ciclo de 10 dias incorporando à carreira, e
## cancelamento descartando a XP Acumulada não incorporada. Usa
## Kingdom.new() local, CommanderTrainingResolver/CommandCenterResolver e
## GameRuntime.sync() — o Reino de teste nunca chama create_initial_mines(),
## então o laço de Minas dentro de sync() não itera nada e o gatilho de
## WorkerThreadPool nunca é alcançado (mesmo padrão já confirmado nas
## etapas anteriores).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Treinamento] Validando Média Diária de XP e Ciclo de 10 dias...")

	var kingdom := Kingdom.new()
	kingdom.command_center_level = 3  # desbloqueia Treinamento
	# Arredonda pro início exato de um dia (Unix) — evita que o teste
	# feche 1 ou 2 dias dependendo da hora real em que ele rodar.
	@warning_ignore("integer_division")
	var now: int = (GameClock.now_unix() / CommanderTrainingResolver.SECONDS_PER_DAY) * CommanderTrainingResolver.SECONDS_PER_DAY

	var active_commander_a := CommanderResource.new()
	active_commander_a.commander_name = "Ativo A"
	kingdom.add_commander(active_commander_a)
	var active_commander_b := CommanderResource.new()
	active_commander_b.commander_name = "Ativo B"
	kingdom.add_commander(active_commander_b)

	var trainee := CommanderResource.new()
	trainee.commander_name = "Em Treinamento"
	kingdom.add_commander(trainee)
	kingdom.add_generation_points(5)
	CommandCenterResolver.activate_next(kingdom)  # 1 Cargo Ativo, pra caber no cenário se precisar
	CommandCenterResolver.move_to_training(kingdom, trainee, now)

	# Dia 1: dois Comandantes Ativos ganham 10 e 20 de XP em combate real.
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, now)
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, now)
	print("  Ativo A XP: %d | Ativo B XP: %d (esperado: 10, 20 — concedido de verdade, não só logado)" % [
		active_commander_a.accumulated_xp, active_commander_b.accumulated_xp
	])
	ctx.check(active_commander_a.accumulated_xp == 10, "Ativo A deve ter 10 XP concedidos de verdade (obtido: %d)" % active_commander_a.accumulated_xp)
	ctx.check(active_commander_b.accumulated_xp == 20, "Ativo B deve ter 20 XP concedidos de verdade (obtido: %d)" % active_commander_b.accumulated_xp)

	var day_1: int = now + CommanderTrainingResolver.SECONDS_PER_DAY + 1
	GameRuntime.sync(kingdom, day_1)
	print("  Média Diária do Dia 1: %d (esperado: 15 = (10+20)/2) | XP Acumulada do Treinando: %d (esperado: 3 = 20%% de 15)" % [
		kingdom.last_daily_average_xp, trainee.training_accumulated_xp
	])
	ctx.check(kingdom.last_daily_average_xp == 15, "Média Diária do Dia 1 deve ser 15 (obtido: %d)" % kingdom.last_daily_average_xp)
	ctx.check(trainee.training_accumulated_xp == 3, "XP Acumulada do Treinando deve ser 3 = 20%% de 15 (obtido: %d)" % trainee.training_accumulated_xp)

	# Mais 9 dias iguais -> completa o Ciclo de 10 dias, incorpora à carreira.
	var t: int = day_1
	for day in range(2, 11):
		CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, t)
		CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, t)
		t += CommanderTrainingResolver.SECONDS_PER_DAY
		GameRuntime.sync(kingdom, t)

	print("  Após 10 dias -> XP de carreira incorporada: %d (esperado: 30 = 3 x 10 dias) | Acumulador do ciclo zerado: %d (esperado: 0)" % [
		trainee.accumulated_xp, trainee.training_accumulated_xp
	])
	ctx.check(trainee.accumulated_xp == 30, "XP de carreira incorporada deve ser 30 = 3 x 10 dias (obtido: %d)" % trainee.accumulated_xp)
	ctx.check(trainee.training_accumulated_xp == 0, "Acumulador do ciclo deve zerar após incorporação (obtido: %d)" % trainee.training_accumulated_xp)

	# Cancelamento mid-ciclo: descarta a XP Acumulada não incorporada.
	# Precisa de uma 2ª vaga de Treinamento — a 1ª já está ocupada pelo
	# "trainee" original, que nunca saiu do Treinamento.
	kingdom.command_center_level = 7  # training_slots(7) = 2
	var canceled_trainee := CommanderResource.new()
	canceled_trainee.commander_name = "Cancelado"
	kingdom.add_commander(canceled_trainee)
	var move_result: Dictionary = CommandCenterResolver.move_to_training(kingdom, canceled_trainee, t)
	print("  2ª vaga de Treinamento (CdC Nível 7) -> designação bem-sucedida? %s (esperado: true)" % str(move_result["success"]))
	ctx.check(move_result["success"] == true, "Designar a 2ª vaga de Treinamento deve ter sucesso")

	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_a, 10, t)
	CommanderTrainingResolver.record_combat_xp(kingdom, active_commander_b, 20, t)
	GameRuntime.sync(kingdom, t + CommanderTrainingResolver.SECONDS_PER_DAY + 1)
	print("  Antes de cancelar -> XP Acumulada do ciclo: %d (esperado: 3, > 0)" % canceled_trainee.training_accumulated_xp)
	ctx.check(canceled_trainee.training_accumulated_xp == 3, "XP Acumulada do ciclo antes de cancelar deve ser 3 (obtido: %d)" % canceled_trainee.training_accumulated_xp)

	CommandCenterResolver.move_to_reserve(kingdom, canceled_trainee)
	print("  Após cancelar -> XP Acumulada descartada: %d | XP de carreira (nunca chegou a ser incorporada): %d (esperado: 0, 0)" % [
		canceled_trainee.training_accumulated_xp, canceled_trainee.accumulated_xp
	])
	ctx.check(canceled_trainee.training_accumulated_xp == 0, "XP Acumulada deve ser descartada ao cancelar (obtido: %d)" % canceled_trainee.training_accumulated_xp)
	ctx.check(canceled_trainee.accumulated_xp == 0, "XP de carreira não deve ser incorporada ao cancelar (obtido: %d)" % canceled_trainee.accumulated_xp)

	return true
