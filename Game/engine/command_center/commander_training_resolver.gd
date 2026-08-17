class_name CommanderTrainingResolver
extends RefCounted
## CommanderTrainingResolver (COMMAND_CENTER_TRAINING.md)
##
## Acúmulo diário de XP de Treinamento (20% da Média Diária de XP dos
## Comandantes Ativos que efetivamente ganharam XP em combate naquele
## dia) e conclusão automática de Ciclos de Treinamento de 10 dias.
## Kingdom nunca decide isso sozinho — este resolver calcula e efetiva,
## no mesmo padrão de todos os outros resolvers do projeto.
##
## Escopo desta entrega: o cálculo em si, já com o bônus do Legado I
## (LegacyResolver.gd) e as Vagas de Treinamento extras do Legado II
## (CommandCenterProgress.effective_training_slots()). NÃO incluído ainda:
## - Wiring automático dentro de ExpeditionRuntime/PvP: record_combat_xp()
##   precisa ser chamado explicitamente por quem orquestra o combate
##   (ex: depois de ExpeditionRuntime.attempt_current_fase() retornar
##   vitória) — ExpeditionRuntime continua sem nenhuma dependência de
##   Kingdom, de propósito (regra do projeto: nenhuma classe de lógica
##   pura depende de Kingdom/Autoload).

const SECONDS_PER_DAY: int = 86400
const TRAINING_CYCLE_DAYS: int = 10
const TRAINING_CYCLE_SECONDS: int = TRAINING_CYCLE_DAYS * SECONDS_PER_DAY
const TRAINING_XP_PERCENT: float = 0.20


## Concede "amount" de XP de carreira a "commander" (CommanderCareer.add_xp())
## e registra no log do dia atual, usado pela Média Diária de XP do
## Treinamento. Só deve ser chamado para Comandantes Ativos que
## efetivamente ganharam XP em combate de verdade (PvP/PvE) — nunca
## para Minas, nunca para XP igual a zero
## (COMMAND_CENTER_TRAINING.md, "Critérios de Cálculo da Média Diária").
static func record_combat_xp(kingdom: Kingdom, commander: CommanderResource, amount: int, now_unix: int) -> void:
	if amount <= 0:
		return

	CommanderCareer.add_xp(commander, amount)

	_ensure_current_day(kingdom, now_unix)
	var key: String = str(commander.instance_id)
	kingdom.daily_combat_xp_log[key] = kingdom.daily_combat_xp_log.get(key, 0) + amount


## Fecha todo dia já concluído desde a última sincronização (recalcula
## a Média Diária e credita a fatia de Treinamento do dia a cada
## Comandante em Treinamento) e conclui Ciclos de Treinamento de 10
## dias já encerrados (incorpora a XP Acumulada à carreira e reinicia
## o Ciclo automaticamente). Chamado por GameRuntime.sync().
static func sync(kingdom: Kingdom, now_unix: int) -> void:
	_close_finished_days(kingdom, now_unix)
	_advance_training_cycles(kingdom, now_unix)


static func _day_number(now_unix: int) -> int:
	@warning_ignore("integer_division")
	return now_unix / SECONDS_PER_DAY


static func _ensure_current_day(kingdom: Kingdom, now_unix: int) -> void:
	if kingdom.training_current_day == -1:
		kingdom.training_current_day = _day_number(now_unix)


## Processa quantos dias já se passaram desde a última sincronização
## (o jogador pode ter ficado offline vários dias) — um de cada vez,
## cada um com sua própria Média Diária e seu próprio crédito de XP.
static func _close_finished_days(kingdom: Kingdom, now_unix: int) -> void:
	_ensure_current_day(kingdom, now_unix)
	var current_day: int = _day_number(now_unix)

	while kingdom.training_current_day < current_day:
		var average: int = _compute_daily_average(kingdom.daily_combat_xp_log)
		kingdom.last_daily_average_xp = average

		var effective_percent: float = TRAINING_XP_PERCENT + (kingdom.legacy_i_xp_bonus_percent / 100.0)
		var training_gain: int = int(floor(average * effective_percent))
		if training_gain > 0:
			for commander: CommanderResource in kingdom.commanders:
				if commander.administrative_state == CommanderResource.AdministrativeState.TRAINING:
					commander.training_accumulated_xp += training_gain

		kingdom.daily_combat_xp_log = {}
		kingdom.training_current_day += 1


## Média Diária de XP (COMMAND_CENTER_TRAINING.md): média simples dos
## valores já registrados no log — a ausência de Comandantes que não
## se qualificaram (não lutaram, foram às Minas, etc.) nunca reduz a
## média, porque eles simplesmente nunca entram no log em primeiro
## lugar (record_combat_xp() só é chamado para quem se qualifica).
static func _compute_daily_average(xp_log: Dictionary) -> int:
	if xp_log.is_empty():
		return 0
	var total: int = 0
	for key: String in xp_log:
		total += xp_log[key]
	@warning_ignore("integer_division")
	return total / xp_log.size()


## Conclui Ciclos de Treinamento de 10 dias já encerrados para cada
## Comandante em Treinamento — pode concluir mais de um Ciclo seguido
## se o jogador ficou offline tempo suficiente.
static func _advance_training_cycles(kingdom: Kingdom, now_unix: int) -> void:
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state != CommanderResource.AdministrativeState.TRAINING:
			continue
		if commander.training_cycle_started_unix == 0:
			commander.training_cycle_started_unix = now_unix
			continue

		while now_unix - commander.training_cycle_started_unix >= TRAINING_CYCLE_SECONDS:
			CommanderCareer.add_xp(commander, commander.training_accumulated_xp)
			commander.training_accumulated_xp = 0
			commander.training_cycle_started_unix += TRAINING_CYCLE_SECONDS
