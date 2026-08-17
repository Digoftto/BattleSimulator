class_name RecruitmentOffer
extends RefCounted
## RecruitmentOffer
##
## Uma oferta de recrutamento pendente: um Comandante Regional que
## aceitou se juntar ao Reino (PvE.md, "Recrutamento de Comandantes de
## Campanha"), aguardando confirmação do jogador.
##
## Prazo de validade: 4 dias / 96 horas (COMMAND_CENTER_RECRUITMENT.md,
## "Painel PvE" → "Permanência e Expiração"), contados a partir de
## created_at_unix. Quem verifica e efetiva a expiração é
## RecruitmentResolver.purge_expired_offers() — esta classe é dado
## puro, nunca lê o relógio nem decide sozinha se já expirou (regra do
## projeto: Resources/dados não têm comportamento).

const VALIDITY_DAYS: int = 4

var commander: CommanderResource

## Instante de criação da oferta, em Unix Timestamp (GameClock.now_unix()),
## fornecido por quem criou a oferta — RecruitmentOffer nunca lê o
## relógio sozinha (classe de dado puro, sem dependência de Autoload).
var created_at_unix: int


func _init(p_commander: CommanderResource, p_created_at_unix: int) -> void:
	commander = p_commander
	created_at_unix = p_created_at_unix
