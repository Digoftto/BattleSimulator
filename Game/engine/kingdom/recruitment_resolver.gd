class_name RecruitmentResolver
extends RefCounted
## RecruitmentResolver
##
## Decide se o Comandante derrotado em uma Fase pode gerar uma Oferta de
## Recrutamento (PvE.md, "Recrutamento de Comandantes de Campanha"), e
## cria essa oferta quando o jogador decide tentar recrutá-lo.
##
## Só se aplica a Chefes Regionais — nunca a Chefes Normais (PvE.md:
## "Comandantes de Chefes Normais nunca podem ser recrutados").
##
## O sucesso aqui não coloca o Comandante direto no Reino — ele entra na
## Fila de Ofertas de Recrutamento de Kingdom (prazo de 4 dias, no
## máximo 10 simultâneas). A confirmação final é sempre uma decisão
## explícita do jogador (Kingdom.accept_recruitment_offer()), nunca
## automática.


## True se este resultado de Fase pode gerar uma tentativa de
## recrutamento: foi vitória, contra um Chefe Regional, ainda não
## recrutado antes.
static func can_recruit(result: PhaseResult, kingdom: Kingdom) -> bool:
	if not result.victory:
		return false
	if result.opponent_entry == null:
		return false
	if result.opponent_entry.category != EnemyArmyEntry.Category.CHEFE_REGIONAL:
		return false

	var faction: String = result.opponent_entry.faction
	var region: int = result.opponent_entry.region_min
	if kingdom.regional_commander_registry.is_recruited(faction, region):
		return false

	return true


## Executa a tentativa de recrutamento: sorteia os 50% de submissão
## (PvE.md) e, em caso de sucesso, cria a Oferta de Recrutamento e marca
## a Região/Facção como recrutada (EnemyArmySelector já sabe substituir
## por Chefe Normal a partir daí, desde a Sprint 31).
##
## Purga ofertas expiradas antes de checar a Fila, para que o limite de
## 10 (COMMAND_CENTER_RECRUITMENT.md) reflita o estado real — uma
## oferta vencida há dias não deve ocupar vaga e barrar uma nova.
##
## Retorna um Dictionary: {"submitted": bool, "offer": RecruitmentOffer
## ou null, "rejected_full_queue": bool}. "submitted" false significa
## que o Chefe recusou (50%) ou que can_recruit() não foi satisfeito.
## "rejected_full_queue" true significa que o Chefe se rendeu, mas a
## Fila já estava cheia (10 ofertas) — a submissão se perde
## permanentemente, sem descartar nenhuma oferta existente
## (COMMAND_CENTER_RECRUITMENT.md, "Lista Cheia (PvE)").
static func attempt_recruitment(result: PhaseResult, kingdom: Kingdom, current_unix: int) -> Dictionary:
	purge_expired_offers(kingdom, current_unix)

	if not can_recruit(result, kingdom):
		return {"submitted": false, "offer": null, "rejected_full_queue": false}

	if randf() >= 0.5:
		return {"submitted": false, "offer": null, "rejected_full_queue": false}

	# A substituição por Chefe Normal acontece já aqui, na submissão —
	# não só quando o jogador confirmar a oferta. Narrativamente, o
	# Chefe já decidiu se render ao aceitar os 50%; se a oferta depois
	# expirar ou for rejeitada por falta de espaço na Fila, ele não
	# volta a defender a província — fica perdido, e a Fase passa a
	# usar um Chefe Normal permanentemente de qualquer forma.
	kingdom.regional_commander_registry.recruit(result.opponent_entry.faction, result.opponent_entry.region_min)

	var new_offer: RecruitmentOffer = kingdom.offer_recruitment(result.opponent_entry.commander, current_unix)
	return {"submitted": true, "offer": new_offer, "rejected_full_queue": new_offer == null}


## Remove da Fila toda Oferta cujo prazo (RecruitmentOffer.VALIDITY_DAYS)
## já tenha vencido em relação a current_unix, e registra o aviso
## correspondente em Kingdom para o jogador ver ao abrir o Painel PvE.
## Sem recompensa, sem regeneração automática (COMMAND_CENTER_RECRUITMENT.md).
##
## Deve ser chamado a partir de qualquer ponto onde o estado do Reino é
## observado após um intervalo de tempo real — hoje: logo após carregar
## um save (KingdomSaveService.load_into) e no início de
## attempt_recruitment() acima. A UI do Painel PvE (Sprint futura) deve
## chamar de novo ao abrir a tela, pelo mesmo motivo.
##
## Retorna as Ofertas removidas por expiração (informativo/teste).
static func purge_expired_offers(kingdom: Kingdom, current_unix: int) -> Array[RecruitmentOffer]:
	var validity_seconds: int = RecruitmentOffer.VALIDITY_DAYS * 24 * 60 * 60
	var expired: Array[RecruitmentOffer] = []

	for offer: RecruitmentOffer in kingdom.pending_recruitment_offers.duplicate():
		if current_unix - offer.created_at_unix >= validity_seconds:
			expired.append(offer)

	for offer: RecruitmentOffer in expired:
		kingdom.expire_recruitment_offer(offer)

	return expired
