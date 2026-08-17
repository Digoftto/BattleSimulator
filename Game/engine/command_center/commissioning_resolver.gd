class_name CommissioningResolver
extends RefCounted
## CommissioningResolver (COMMAND_CENTER_RECRUITMENT.md, "Processo Unificado de Comissionamento")
##
## Comissiona um Candidato — de QUALQUER Fonte de Recrutamento (Painel
## PvE, Centro de Recrutamento, ou futuras fontes) — através de um
## único processo unificado: exige uma Vaga da Reserva disponível antes
## de efetivar a entrada no Reino. Nenhuma Fonte pode pular ou alterar
## este processo (regra explícita do documento).
##
## Correção registrada: antes desta entrega, Kingdom.accept_recruitment_offer()
## comissionava sem checar Vaga da Reserva nenhuma — um comandante
## sempre entrava, não importa a capacidade. Esse comportamento estava
## incorreto frente ao documento; agora só é usado como o "commit" de
## baixo nível, sempre precedido pela checagem deste resolver.


## Checagem pura: existe uma Vaga da Reserva disponível agora?
static func has_vaga_reserva_available(kingdom: Kingdom) -> bool:
	return kingdom.reserve_occupancy() < CommandCenterProgress.effective_vaga_reserva(kingdom)


## Comissiona "commander" diretamente — usado pelo Centro de
## Recrutamento, que não tem uma fila própria de onde remover o
## Candidato (quem chama isso é responsável por limpar o Slot de
## origem, e só em caso de sucesso — ver RecruitmentCenterResolver,
## "Caso Especial: Reserva Cheia"). Retorna
## {"success": bool, "reason": String}. "reason": "no_vaga_reserva_available".
static func commission(kingdom: Kingdom, commander: CommanderResource, now_unix: int, source: String = "Centro de Recrutamento") -> Dictionary:
	if not has_vaga_reserva_available(kingdom):
		return {"success": false, "reason": "no_vaga_reserva_available"}

	kingdom.add_commander(commander, now_unix)
	kingdom.record_commissioning(commander.commander_name, source, now_unix)
	return {"success": true, "reason": ""}


## Comissiona a partir de uma Oferta pendente do Painel PvE — exige
## Vaga da Reserva antes de sequer tirar a oferta da fila: "Reserva
## Cheia" significa a oferta continua pendente, nunca é descartada.
## Retorna {"success": bool, "reason": String}. "reason":
## "offer_not_found", "no_vaga_reserva_available".
static func commission_from_pve_offer(kingdom: Kingdom, offer: RecruitmentOffer, now_unix: int) -> Dictionary:
	if not kingdom.pending_recruitment_offers.has(offer):
		return {"success": false, "reason": "offer_not_found"}

	if not has_vaga_reserva_available(kingdom):
		return {"success": false, "reason": "no_vaga_reserva_available"}

	var commander_name: String = offer.commander.commander_name
	kingdom.accept_recruitment_offer(offer, now_unix)
	kingdom.record_commissioning(commander_name, "Campanha PvE", now_unix)
	return {"success": true, "reason": ""}
