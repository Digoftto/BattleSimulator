class_name MiningProductionResolver
extends RefCounted
## MiningProductionResolver
##
## Credita a produção horária de uma Mina com Ciclo de Mineração ativo
## no Depósito correspondente do Reino (MINES.md, "Distribuição
## Horária Automática" + "3. Produção Final"). Pura orquestração:
## Mina/Kingdom nunca decidem isso sozinhos.
##
## Mesmo padrão incremental já usado por Army.sync_energy_recovery():
## preserva progresso parcial de hora entre chamadas, nunca credita
## além do fim do ciclo, e nunca credita duas vezes o mesmo intervalo.


## Credita a produção de "mina" desde o último crédito até "now_unix"
## (ou até o fim do ciclo, o que vier primeiro). Continua creditando o
## tempo pendente mesmo que "now_unix" já esteja além do fim do ciclo
## (o jogador pode voltar ao jogo depois do ciclo ter expirado — o que
## faltava creditar entre a última sincronização e o fim do ciclo
## ainda é devido). Não faz nada se nenhum ciclo jamais foi iniciado.
static func credit(mina: Mina, kingdom: Kingdom, now_unix: int) -> void:
	if mina.cycle_started_unix == 0:
		return  # nunca foi ativada

	# MINES.md: Mina Inicial produz continuamente pra sempre, sem
	# Ciclo de 100h — só as Minas de Trilha (Regionais) têm esse
	# limite. "effective_now" nunca é limitado pro caso da Inicial.
	var cycle_end: int = -1 if mina.is_initial_mine() else mina.cycle_started_unix + Mina.CYCLE_DURATION_SECONDS
	var reference_unix: int = mina.last_production_credit_unix
	if reference_unix == 0:
		reference_unix = mina.cycle_started_unix

	if cycle_end != -1 and reference_unix >= cycle_end:
		return  # já foi creditado tudo que este ciclo tinha para entregar

	# Nunca credita além do fim do ciclo (Minas de Trilha) — mas
	# continua creditando o tempo pendente mesmo que "now_unix" já
	# esteja além dele (o jogador pode voltar ao jogo depois do ciclo
	# ter expirado; o que faltava creditar entre a última
	# sincronização e o fim do ciclo ainda é devido). Mina Inicial
	# nunca tem esse teto — "effective_now" é sempre "now_unix".
	var effective_now: int = now_unix if cycle_end == -1 else mini(now_unix, cycle_end)

	var elapsed_seconds: int = effective_now - reference_unix
	if elapsed_seconds <= 0:
		return

	@warning_ignore("integer_division")  # Divisão inteira intencional: só horas completas creditam.
	var elapsed_hours: int = elapsed_seconds / 3600
	if elapsed_hours <= 0:
		return

	var resource: String = MineEconomy.resource_for_faction(mina.faction)
	var deposit_level: int = MineEconomy.deposit_level_for_resource(kingdom, resource)
	if deposit_level < 1:
		return

	var capacity: int = Deposits.storage_capacity(deposit_level)
	var base: int = MineEconomy.base_production_for_mina(mina)
	var hourly: int = MineEconomy.hourly_production(base, mina.cycle_efficiency)
	var amount: int = hourly * elapsed_hours

	if amount > 0:
		kingdom.credit_raw_resource(resource, amount, capacity)

	mina.mark_production_credited(reference_unix + (elapsed_hours * 3600))
