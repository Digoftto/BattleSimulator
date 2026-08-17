class_name RecruitmentCenterResolver
extends RefCounted
## RecruitmentCenterResolver (COMMAND_CENTER_RECRUITMENT.md, "1. Centro de Recrutamento")
##
## Slots + gerador centralizado com cooldown sequencial: no máximo 1
## ciclo de geração roda por vez, mesmo com vários Slots vazios ao
## mesmo tempo. Ao vencer, preenche o primeiro Slot vazio (ordem
## fixa) e, se ainda sobrar Slot vazio, inicia um novo ciclo
## imediatamente. Kingdom nunca decide isso sozinho.
##
## Candidatos aqui nunca expiram (diferente do Painel PvE) — só saem
## do Slot por Comissionamento bem-sucedido (CommissioningResolver +
## commission_from_slot() abaixo, que já implementa o "Caso Especial:
## Reserva Cheia" — falha em comissionar nunca libera o Slot).


## Avança o gerador: conclui quantos ciclos já venceram desde a última
## sincronização (o jogador pode ter ficado offline por vários ciclos
## seguidos), preenchendo um Slot por ciclo concluído, e garante que
## exista um ciclo em andamento sempre que houver Slot vazio e nenhum
## ciclo já rodando. Chamado por GameRuntime.sync().
static func sync(kingdom: Kingdom, now_unix: int) -> void:
	kingdom.sync_recruitment_center_slots()

	while kingdom.recruitment_center_cycle_end_unix != 0 and now_unix >= kingdom.recruitment_center_cycle_end_unix:
		var finished_at: int = kingdom.recruitment_center_cycle_end_unix
		_fill_first_empty_slot(kingdom)
		kingdom.recruitment_center_cycle_end_unix = 0
		_maybe_start_cycle(kingdom, finished_at)

	if kingdom.recruitment_center_cycle_end_unix == 0:
		_maybe_start_cycle(kingdom, now_unix)


## Tenta comissionar o Candidato do Slot "slot_index". Em caso de
## sucesso, o Slot fica vazio (e o próximo sync() já cuida de iniciar
## um novo ciclo de geração para ele, se for o caso). Em caso de falha
## por "Reserva Cheia", o Candidato permanece exatamente onde estava —
## nunca é descartado nem some do Slot (COMMAND_CENTER_RECRUITMENT.md,
## "Caso Especial: Reserva Cheia"). Retorna
## {"success": bool, "reason": String}. "reason": "invalid_slot",
## "empty_slot", "no_vaga_reserva_available".
## Comissiona o Candidato de "slot_index" — só é permitido comissionar
## o PRIMEIRO Slot ocupado (ordem de chegada), nunca escolher um Slot
## posterior antes dos anteriores. Retorna {"success": bool, "reason":
## String}. "reason": "not_first_occupied_slot" quando o jogador tenta
## pular a ordem.
static func commission_from_slot(kingdom: Kingdom, slot_index: int, now_unix: int) -> Dictionary:
	if slot_index < 0 or slot_index >= kingdom.recruitment_center_slots.size():
		return {"success": false, "reason": "invalid_slot"}

	var candidate: CommanderResource = kingdom.recruitment_center_slots[slot_index]
	if candidate == null:
		return {"success": false, "reason": "empty_slot"}

	if slot_index != _first_occupied_slot_index(kingdom):
		return {"success": false, "reason": "not_first_occupied_slot"}

	var result: Dictionary = CommissioningResolver.commission(kingdom, candidate, now_unix)
	if result["success"]:
		kingdom.recruitment_center_slots[slot_index] = null

	return result


static func _first_occupied_slot_index(kingdom: Kingdom) -> int:
	for i in range(kingdom.recruitment_center_slots.size()):
		if kingdom.recruitment_center_slots[i] != null:
			return i
	return -1


static func _maybe_start_cycle(kingdom: Kingdom, start_unix: int) -> void:
	if _first_empty_slot_index(kingdom) == -1:
		return  # nenhum Slot vazio — nada a gerar agora.

	var cooldown: int = CommandCenterProgress.recruitment_center_cooldown_seconds(kingdom.command_center_level)
	kingdom.recruitment_center_cycle_end_unix = start_unix + cooldown


static func _fill_first_empty_slot(kingdom: Kingdom) -> void:
	var index: int = _first_empty_slot_index(kingdom)
	if index == -1:
		return
	kingdom.recruitment_center_slots[index] = _generate_candidate()


static func _first_empty_slot_index(kingdom: Kingdom) -> int:
	for i in range(kingdom.recruitment_center_slots.size()):
		if kingdom.recruitment_center_slots[i] == null:
			return i
	return -1


## Gera 1 Candidato "Comandante Comum" (Geração Padrão, sem filtro de
## Raridade — diferente de Chefe Regional/Chefe de Mina). Mesmo padrão
## já usado por EnemyArmyGenerator._build_commander(): a Doutrina
## gerada define a Facção; o nome ainda não tem um banco de nomes
## real, mesmo placeholder já usado em produção em outro lugar do
## projeto.
static func _generate_candidate() -> CommanderResource:
	var doctrine: CommanderDoctrine = CommanderGenerator.generate(
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements,
		GameDatabase.commander_targets, GameDatabase.commander_effects, GameDatabase.commander_values
	)
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Gerado (%s)" % doctrine.faction
	commander.faction = doctrine.faction
	commander.doctrine = doctrine
	return commander
