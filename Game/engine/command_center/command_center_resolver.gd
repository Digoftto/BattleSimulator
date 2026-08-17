class_name CommandCenterResolver
extends RefCounted
## CommandCenterResolver
##
## Efetiva as transições do Estado Administrativo do Comandante
## (COMMAND_CENTER.md: Reserve → Training → Active → Retired — ver
## CommanderResource.AdministrativeState) e a Expansão Administrativa
## (ativação de Cargo de Comando Ativo / Vaga da Reserva em PG,
## COMMAND_CENTER_PROGRESS.md). CommanderResource nunca decide sozinho
## — este resolver verifica capacidade disponível e efetiva a
## transição, no mesmo padrão de todos os outros resolvers do projeto.
##
## Escopo desta entrega: a máquina de estados e a Expansão
## Administrativa (Cargo Ativo / Vaga Reserva). NÃO incluído ainda:
## - Acúmulo de XP de Treinamento (média diária, Ciclo de 10 dias,
##   promoção automática) — COMMAND_CENTER_TRAINING.md; aqui só a
##   transição de entrar/sair do Estado Training.
## - Legado (aposentadoria com bônus, Hall dos Comandantes) —
##   retire() aqui só marca o Estado como Retired; não consome o
##   Comandante nem aplica nenhum bônus.
## - Vagas de Treinamento extras concedidas pelo Legado II.


## Tenta ativar a próxima unidade de Recurso Administrativo disponível
## na Infraestrutura do Nível atual do CdC — sempre Cargo de Comando
## Ativo primeiro, só depois Vaga da Reserva (COMMAND_CENTER_PROGRESS.md,
## "Ordem das Ativações", que é automática, não uma escolha do
## jogador). Retorna {"success": bool, "reason": String, "type": String}.
## "reason": "nothing_to_activate" (toda a Infraestrutura do Nível já
## foi ativada), "insufficient_pg".
static func activate_next(kingdom: Kingdom) -> Dictionary:
	var infrastructure: Dictionary = CommandCenterProgress.infrastructure_at_level(kingdom.command_center_level)
	var pending_ativo: int = infrastructure["ativo"] - kingdom.cargo_ativo_activated
	var pending_reserva: int = infrastructure["reserva"] - kingdom.vaga_reserva_activated

	if pending_ativo <= 0 and pending_reserva <= 0:
		return {"success": false, "reason": "nothing_to_activate", "type": ""}

	var cost: int = CommandCenterProgress.pg_cost_per_activation(kingdom.command_center_level)
	if not kingdom.spend_generation_points(cost):
		return {"success": false, "reason": "insufficient_pg", "type": ""}

	if pending_ativo > 0:
		kingdom.increment_cargo_ativo_activated()
		return {"success": true, "reason": "", "type": "ativo"}

	kingdom.increment_vaga_reserva_activated()
	return {"success": true, "reason": "", "type": "reserva"}


## Reserve -> Active. Exige um Cargo de Comando Ativo ativado e livre.
## Retorna {"success": bool, "reason": String}. "reason": "invalid_state"
## (não estava em Reserve), "no_cargo_ativo_available".
## Permuta atômica: um Comandante em Reserva assume o Cargo Ativo de
## outro, que assume a Vaga da Reserva liberada, na mesma operação.
##
## Existe porque move_to_active()/move_to_reserve() sozinhos criam um
## impasse real quando Cargos Ativos E Vagas da Reserva estão ambos no
## limite (1/1 e 1/1, por exemplo): "Voltar à Reserva" falha porque a
## Reserva está cheia, "Promover a Ativo" falha porque o Ativo está
## cheio — nenhuma ação individual funciona, mesmo a ocupação TOTAL do
## Reino não mudando (ainda seria 1 Ativo + 1 Reserva depois de
## qualquer uma das duas). A permuta nunca muda a ocupação total,
## então nunca precisa checar capacidade — só valida os Estados.
static func swap_active_reserve(active_commander: CommanderResource, reserve_commander: CommanderResource) -> Dictionary:
	if active_commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
		return {"success": false, "reason": "not_active"}
	if reserve_commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
		return {"success": false, "reason": "not_reserve"}

	active_commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	reserve_commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE
	return {"success": true, "reason": ""}


static func move_to_active(kingdom: Kingdom, commander: CommanderResource) -> Dictionary:
	if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
		return {"success": false, "reason": "invalid_state"}

	if _count_by_state(kingdom, CommanderResource.AdministrativeState.ACTIVE) >= CommandCenterProgress.effective_cargo_ativo(kingdom):
		return {"success": false, "reason": "no_cargo_ativo_available"}

	commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE
	return {"success": true, "reason": ""}


## Active ou Training -> Reserve. Sair de Active exige uma Vaga da
## Reserva ativada e livre (Training já ocupa uma, então sair de
## Training para Reserve nunca precisa dessa checagem — ele já contava
## como ocupante). Sair de Training antes do fim do Ciclo de
## Treinamento descarta a XP Acumulada não incorporada
## (COMMAND_CENTER_TRAINING.md, "Cancelamento") — nunca a XP de
## carreira já incorporada em ciclos anteriores. Retorna
## {"success": bool, "reason": String}. "reason": "invalid_state" (já
## em Reserve, ou Retired), "no_vaga_reserva_available".
static func move_to_reserve(kingdom: Kingdom, commander: CommanderResource) -> Dictionary:
	var state: CommanderResource.AdministrativeState = commander.administrative_state

	if state == CommanderResource.AdministrativeState.RESERVE or state == CommanderResource.AdministrativeState.RETIRED:
		return {"success": false, "reason": "invalid_state"}

	if state == CommanderResource.AdministrativeState.ACTIVE:
		if kingdom.reserve_occupancy() >= CommandCenterProgress.effective_vaga_reserva(kingdom):
			return {"success": false, "reason": "no_vaga_reserva_available"}

	if state == CommanderResource.AdministrativeState.TRAINING:
		commander.training_accumulated_xp = 0
		commander.training_cycle_started_unix = 0

	commander.administrative_state = CommanderResource.AdministrativeState.RESERVE
	return {"success": true, "reason": ""}


## Reserve -> Training. Exige uma Vaga de Treinamento livre
## (CommandCenterProgress.training_slots()) — o Comandante continua
## contando como ocupante de uma Vaga da Reserva enquanto treina
## (COMMAND_CENTER_TRAINING.md), então não precisa nem libera Vaga da
## Reserva nesta transição. Já inicia o Ciclo de Treinamento de 10 dias
## (COMMAND_CENTER_TRAINING.md). Retorna {"success": bool, "reason": String}.
## "reason": "invalid_state", "no_training_slot_available".
static func move_to_training(kingdom: Kingdom, commander: CommanderResource, now_unix: int) -> Dictionary:
	if commander.administrative_state != CommanderResource.AdministrativeState.RESERVE:
		return {"success": false, "reason": "invalid_state"}

	var slots: int = CommandCenterProgress.effective_training_slots(kingdom)
	if _count_by_state(kingdom, CommanderResource.AdministrativeState.TRAINING) >= slots:
		return {"success": false, "reason": "no_training_slot_available"}

	commander.administrative_state = CommanderResource.AdministrativeState.TRAINING
	commander.training_accumulated_xp = 0
	commander.training_cycle_started_unix = now_unix
	return {"success": true, "reason": ""}


## Marca o Comandante como Retired — estado terminal. NÃO remove o
## Comandante de kingdom.commanders nem aplica nenhum bônus de Legado
## (isso pertence a um resolver de Legado ainda não implementado — é
## por isso que "kingdom" não é usado aqui ainda; mantido na
## assinatura por consistência com os demais métodos deste resolver, e
## porque o futuro resolver de Legado provavelmente vai precisar dele).
## Retorna {"success": bool, "reason": String}. "reason": "already_retired".
static func retire(_kingdom: Kingdom, commander: CommanderResource) -> Dictionary:
	if commander.administrative_state == CommanderResource.AdministrativeState.RETIRED:
		return {"success": false, "reason": "already_retired"}

	commander.administrative_state = CommanderResource.AdministrativeState.RETIRED
	return {"success": true, "reason": ""}


static func _count_by_state(kingdom: Kingdom, state: CommanderResource.AdministrativeState) -> int:
	var count: int = 0
	for commander: CommanderResource in kingdom.commanders:
		if commander.administrative_state == state:
			count += 1
	return count
