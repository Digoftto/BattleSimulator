class_name ExpeditionTickResolver
extends RefCounted
## ExpeditionTickResolver
##
## Camada de orquestração do Ritmo da Expedição (F-020, decisão 9): a
## cada GameRuntime.sync(kingdom, now_unix), dispara no máximo UMA
## tentativa automática (ExpeditionRuntime.attempt_current_fase()) por
## Expedição ativa, quando pelo menos TICK_INTERVAL_SECONDS já se
## passaram desde a última tentativa. A Energia continua sendo o único
## recurso que limita a progressão (ENERGY.md) — este intervalo apenas
## decide QUANDO uma tentativa acontece, nunca SE ela pode acontecer.
##
## Deliberadamente SEM catch-up (F-020, decisão 10): ao contrário de
## MiningProductionResolver/RecruitmentCenterResolver (que recuperam
## múltiplos ciclos perdidos), este resolver nunca dispara mais de uma
## tentativa por chamada, mesmo após uma lacuna de horas — a Expedição
## fica pausada enquanto o jogo está fechado, sem acumular tentativas.
## Nenhuma lógica de combate/Fase é duplicada aqui — apenas orquestra o
## motor síncrono já existente (ExpeditionRuntime.attempt_current_fase()).

const TICK_INTERVAL_SECONDS: int = 60


static func sync(kingdom: Kingdom, now_unix: int) -> void:
	for expedition: ExpeditionRuntime in kingdom.active_expeditions:
		_tick_one(expedition, now_unix)


static func _tick_one(expedition: ExpeditionRuntime, now_unix: int) -> void:
	if expedition.status != ExpeditionRuntime.Status.EM_ANDAMENTO:
		return

	if expedition.is_waiting_at_acampamento:
		# Evita uma rajada de tentativas no instante em que o jogador
		# manda "Continuar" depois de ficar parado por muito tempo —
		# o relógio da Expedição só volta a contar a partir de agora.
		expedition.last_tick_unix = now_unix
		return

	if now_unix - expedition.last_tick_unix < TICK_INTERVAL_SECONDS:
		return

	expedition.attempt_current_fase()
	expedition.last_tick_unix = now_unix
