class_name ExpeditionTickResolver
extends RefCounted
## ExpeditionTickResolver
##
## Camada de orquestração do Ritmo da Expedição (F-020, decisão 9): a
## cada GameRuntime.sync(kingdom, now_unix), dispara uma tentativa
## automática (ExpeditionRuntime.attempt_current_fase()) por Expedição
## ativa a cada TICK_INTERVAL_SECONDS efetivamente decorrido. A Energia
## continua sendo o único recurso que limita a progressão (ENERGY.md) —
## este intervalo apenas decide QUANDO uma tentativa acontece, nunca SE
## ela pode acontecer.
##
## Progressão offline com catch-up (auditoria pré-pré-alfa, decisão
## explícita do dono do projeto revertendo F-020/decisão 10): a versão
## anterior disparava no máximo 1 tentativa por chamada de sync(), MESMO
## após uma lacuna de horas com o jogo fechado — o relógio (last_tick_unix)
## pulava direto para "now", descartando o tempo restante em vez de
## processá-lo. Resultado observado: um Exército fechado por ~2h avançava
## só ~7 Fases (uma por tela visitada ao reabrir), quando o Ritmo real
## (1 tentativa/60s, Energia permitindo) previa muito mais. Corrigido para
## processar em loop, avançando last_tick_unix em passos de exatos
## TICK_INTERVAL_SECONDS por tentativa (nunca pulando pro "now" de uma vez)
## — mesmo padrão de catch-up já usado por MiningProductionResolver (Ciclo
## de Minas)/RecruitmentCenterResolver. Nenhuma lógica de combate/Fase é
## duplicada aqui — apenas chama repetidamente o mesmo motor síncrono já
## existente (ExpeditionRuntime.attempt_current_fase()), que já é quem
## decide sozinho quando parar: Energia esgotada (PhaseResolver,
## ENERGY_EXHAUSTED -> is_waiting_at_acampamento = true), Trilha concluída
## (status = CONCLUIDA) ou Acampamento aguardando ordem manual
## (AcampamentoPolicy.AGUARDAR_ORDEM) — todas essas condições já existiam
## e agora simplesmente interrompem o loop no mesmo lugar em que já
## interrompiam uma única tentativa.

const TICK_INTERVAL_SECONDS: int = 60

## Salvaguarda puramente defensiva contra um loop descontrolado (nunca
## deveria ser atingida em uso real — as condições de parada acima do
## motor já limitam o número de tentativas muito antes disso: Energia é
## finita e a Trilha tem um número finito de Fases). Não é uma regra de
## jogo, só um teto técnico.
const MAX_CATCHUP_ATTEMPTS_PER_SYNC: int = 10000


static func sync(kingdom: Kingdom, now_unix: int) -> void:
	for expedition: ExpeditionRuntime in kingdom.active_expeditions:
		_tick_one(expedition, kingdom, now_unix)


static func _tick_one(expedition: ExpeditionRuntime, kingdom: Kingdom, now_unix: int) -> void:
	if expedition.status != ExpeditionRuntime.Status.EM_ANDAMENTO:
		return

	if expedition.is_waiting_at_acampamento:
		# Auditoria pré-pré-alfa: antes de aceitar a parada, tenta
		# liberar RESTING_UNTIL_FULL/FORCED_UNTIL_FULL automaticamente
		# assim que a Energia real (Army.sync_energy_recovery(), nunca
		# uma fórmula nova) atingir o máximo — AWAITING_DECISION nunca é
		# afetado (guardado dentro do próprio método: exige sempre uma
		# ação explícita do jogador, não importa quanta Energia haja).
		# Se liberar agora, cai direto no resto desta função na MESMA
		# passagem de sync(), sem esperar a chamada seguinte.
		if not expedition.try_release_camp_wait_if_fully_rested(now_unix, kingdom.energy_nucleus_level):
			# Evita uma rajada de tentativas no instante em que a marcha
			# é liberada depois de ficar parada por muito tempo — o
			# relógio da Expedição só volta a contar a partir de agora.
			expedition.last_tick_unix = now_unix
			return

	# BUG REAL encontrado e corrigido durante este teste (achado real, não
	# hipotético): last_tick_unix == 0 é o sentinela "nunca tentou
	# automaticamente ainda" (ver docstring do campo em
	# expedition_runtime.gd — "a 1ª sincronização tenta imediatamente"),
	# nunca uma lacuna real de tempo. Sem este caso especial, o primeiro
	# sync() de uma Expedição recém-criada calcularia
	# "now_unix - 0" (dezenas de anos, o valor absoluto do relógio Unix)
	# como se fosse tempo offline a recuperar, dececadeando milhares de
	# tentativas de combate reais de uma vez só. Mantém a mesma semântica
	# original (1 tentativa imediata) só para este caso; qualquer sync()
	# SEGUINTE já tem um last_tick_unix real e cai no catch-up normal
	# abaixo.
	if expedition.last_tick_unix == 0:
		expedition.attempt_current_fase()
		expedition.last_tick_unix = now_unix
		return

	var attempts: int = 0
	while now_unix - expedition.last_tick_unix >= TICK_INTERVAL_SECONDS and attempts < MAX_CATCHUP_ATTEMPTS_PER_SYNC:
		expedition.attempt_current_fase()
		expedition.last_tick_unix += TICK_INTERVAL_SECONDS
		attempts += 1
		if expedition.status != ExpeditionRuntime.Status.EM_ANDAMENTO or expedition.is_waiting_at_acampamento:
			return
