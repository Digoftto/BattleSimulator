class_name LegacyResolver
extends RefCounted
## LegacyResolver (COMMAND_CENTER_LEGACY.md)
##
## Efetiva a aposentadoria de Comandantes — Legado Administrativo (I a
## V, cumulativo pela Patente) e Grande Legado Militar (consumo
## definitivo de Comandante + 9 pelotões, Doutrina Militar por Facção).
## Kingdom nunca decide isso sozinho — este resolver verifica
## elegibilidade, aplica os benefícios e efetiva a transição de Estado
## (reaproveitando CommandCenterResolver.retire(), nunca duplicando essa
## lógica).
##
## Correção registrada: COMMAND_CENTER_LEGACY.md exigia "Patente máxima
## (Marechal)" para o Grande Legado Militar — desatualizado, escrito
## antes de Lorde-Comandante existir na hierarquia de Patentes
## (CommanderCareer.PATENTE_THRESHOLDS, já testada, com Lorde-Comandante
## acima de Marechal). Corrigido: a exigência agora é Lorde-Comandante,
## a Patente máxima real — decisão confirmada com o dono do projeto,
## documento já atualizado.

## --- Legado Administrativo: desbloqueio por Nível do CdC ---
const CDC_LEVEL_LEGADO_I: int = 5
const CDC_LEVEL_LEGADO_II: int = 7
const CDC_LEVEL_LEGADO_III: int = 8
const CDC_LEVEL_LEGADO_IV: int = 9
const CDC_LEVEL_LEGADO_V: int = 10

## --- Legado Administrativo: Patente mínima por nível ---
const PATENTE_MIN_LEGADO_I: String = "Capitão"
const PATENTE_MIN_LEGADO_II: String = "Major"
const PATENTE_MIN_LEGADO_III: String = "Coronel"
const PATENTE_MIN_LEGADO_IV: String = "General"
const PATENTE_MIN_LEGADO_V: String = "Marechal"

## --- Legado I: bônus de XP de Treinamento ---
const LEGADO_I_PERCENT_PER_RETIREE: float = 0.1

## --- Legado V: bônus percentual por destino escolhido ---
const LEGADO_V_PERCENT_PER_RETIREE: float = 0.05
const LEGADO_V_VALID_DESTINOS: Array[String] = ["xp", "resources", "fragments"]

## --- Grande Legado Militar ---
const GRANDE_LEGADO_CDC_LEVEL: int = 100
const GRANDE_LEGADO_MIN_PATENTE: String = "Lorde-Comandante"  # Corrigido — ver nota no topo do arquivo.
const GRANDE_LEGADO_MAX_TIER: int = 5
const GRANDE_LEGADO_REQUIRED_CARD_COUNT: int = 9

const DOCTRINE_LIMITS: Dictionary = {
	"Império": {"principal": "escudo", "secundario": "vida", "terciario": "ataque", "escudo": 5, "vida": 2, "ataque": 1},
	"Natureza": {"principal": "vida", "secundario": "ataque", "terciario": "escudo", "vida": 5, "ataque": 2, "escudo": 1},
	"Mortos-Vivos": {"principal": "ataque", "secundario": "escudo", "terciario": "vida", "ataque": 5, "escudo": 2, "vida": 1},
}


## Aposenta "commander" via Legado Administrativo. Exige Patente mínima
## Capitão (Legado I) — abaixo disso, a aposentadoria simplesmente não
## é aceita por este caminho (não existe "aposentar sem benefício
## nenhum" no Legado Administrativo). Aplica cumulativamente os
## benefícios de TODOS os Legados que a Patente do Comandante alcança
## E que o Nível do CdC já desbloqueou (COMMAND_CENTER_LEGACY.md,
## "Acúmulo de Benefícios") — os dois requisitos precisam valer ao
## mesmo tempo para cada nível individual.
##
## "legado_v_destino" ("xp", "resources" ou "fragments") só é exigido
## se o Comandante qualificar pro Legado V (Patente Marechal+ E CdC
## Nível 10+) — ignorado nos demais casos.
##
## Retorna {"success": bool, "reason": String, "benefits": Array[String]}.
## "reason": "invalid_state" (não está em Reserve/Active — Training
## precisa sair do Treinamento primeiro), "below_minimum_patente" (nem
## Legado I), "missing_legado_v_destino", "army_still_assigned" (Active
## e ainda liderando um Exército — precisa ser desalocado antes).
static func retire_administrative(kingdom: Kingdom, commander: CommanderResource, now_unix: int, legado_v_destino: String = "") -> Dictionary:
	var state: CommanderResource.AdministrativeState = commander.administrative_state
	if state != CommanderResource.AdministrativeState.RESERVE and state != CommanderResource.AdministrativeState.ACTIVE:
		return {"success": false, "reason": "invalid_state", "benefits": []}

	if commander.ownership_status == CommanderResource.OwnershipStatus.EM_EXERCITO:
		return {"success": false, "reason": "army_still_assigned", "benefits": []}

	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	if not meets_patente(patente, PATENTE_MIN_LEGADO_I):
		return {"success": false, "reason": "below_minimum_patente", "benefits": []}

	var qualifies_for_v: bool = meets_patente(patente, PATENTE_MIN_LEGADO_V) and kingdom.command_center_level >= CDC_LEVEL_LEGADO_V
	if qualifies_for_v and not LEGADO_V_VALID_DESTINOS.has(legado_v_destino):
		return {"success": false, "reason": "missing_legado_v_destino", "benefits": []}

	# Efetiva a transição de Estado — reaproveita CommandCenterResolver,
	# nunca escreve administrative_state diretamente aqui.
	CommandCenterResolver.retire(kingdom, commander)

	var benefits: Array[String] = []
	kingdom.increment_legacy_administrative_retirees()

	if kingdom.command_center_level >= CDC_LEVEL_LEGADO_I:
		kingdom.add_legacy_i_xp_bonus(LEGADO_I_PERCENT_PER_RETIREE)
		benefits.append("Legado I: +%.1f pp de XP de Treinamento (total acumulado: %.1f pp)" % [
			LEGADO_I_PERCENT_PER_RETIREE, kingdom.legacy_i_xp_bonus_percent
		])

	if meets_patente(patente, PATENTE_MIN_LEGADO_II) and kingdom.command_center_level >= CDC_LEVEL_LEGADO_II:
		benefits.append("Legado II: contribui para +1 Vaga de Treinamento a cada 20 aposentados (total: %d)" % kingdom.legacy_administrative_retirees)

	if meets_patente(patente, PATENTE_MIN_LEGADO_III) and kingdom.command_center_level >= CDC_LEVEL_LEGADO_III:
		benefits.append("Legado III: contribui para +1 Vaga da Reserva a cada 25 aposentados (total: %d)" % kingdom.legacy_administrative_retirees)

	if meets_patente(patente, PATENTE_MIN_LEGADO_IV) and kingdom.command_center_level >= CDC_LEVEL_LEGADO_IV:
		benefits.append("Legado IV: contribui para +1 Cargo de Comando Ativo a cada 100 aposentados (total: %d)" % kingdom.legacy_administrative_retirees)

	if qualifies_for_v:
		kingdom.add_legacy_v_bonus(legado_v_destino, LEGADO_V_PERCENT_PER_RETIREE)
		benefits.append("Legado V: +%.2f%% de bônus permanente em %s" % [LEGADO_V_PERCENT_PER_RETIREE, legado_v_destino])

	commander.retired_at_unix = now_unix
	commander.retirement_type = "Legado Administrativo"
	commander.retirement_benefit = "; ".join(benefits)

	return {"success": true, "reason": "", "benefits": benefits}


## Cria um Grande Legado Militar: consome definitivamente "commander" e
## as 9 cartas de "army" (removidas do plantel do Reino — nunca
## registradas no Hall, só o Comandante). Exige TODOS os requisitos
## simultaneamente (COMMAND_CENTER_LEGACY.md, "Requisitos Obrigatórios").
## "attribute_choice" ("escudo"/"vida"/"ataque" — nomes em minúsculo)
## só é aplicado se aquele atributo ainda não tiver atingido o limite
## da Doutrina Militar da Facção; se todos os 3 já estiverem no limite,
## o Legado ainda é criado e registrado (Regra de Excesso), só não
## concede nenhum ponto novo.
##
## Retorna {"success": bool, "reason": String, "attribute_applied": String}.
## "reason": "cdc_level_too_low", "invalid_state" (Comandante não está
## Active), "below_max_patente", "not_eligible_for_retirement" (mesma
## checagem de invalid_state, mantida separada por clareza de leitura),
## "soldo_not_fully_used", "army_incomplete" (não são 9 cartas),
## "cards_not_max_tier", "faction_mismatch" (cartas ou Comandante fora
## da mesma Facção), "invalid_attribute_choice".
static func create_grande_legado_militar(kingdom: Kingdom, commander: CommanderResource, army: Army, now_unix: int, attribute_choice: String) -> Dictionary:
	if kingdom.command_center_level < GRANDE_LEGADO_CDC_LEVEL:
		return {"success": false, "reason": "cdc_level_too_low", "attribute_applied": ""}

	if commander.administrative_state != CommanderResource.AdministrativeState.ACTIVE:
		return {"success": false, "reason": "invalid_state", "attribute_applied": ""}

	var patente: String = CommanderCareer.patente_for_xp(commander.accumulated_xp)
	if patente != GRANDE_LEGADO_MIN_PATENTE:
		return {"success": false, "reason": "below_max_patente", "attribute_applied": ""}

	if not army.is_soldo_within_cap() or army.soldo_total() != Soldo.cap_for_patente(patente):
		return {"success": false, "reason": "soldo_not_fully_used", "attribute_applied": ""}

	if army.cards.size() != GRANDE_LEGADO_REQUIRED_CARD_COUNT:
		return {"success": false, "reason": "army_incomplete", "attribute_applied": ""}

	for card: CardResource in army.cards:
		if card.tier != GRANDE_LEGADO_MAX_TIER:
			return {"success": false, "reason": "cards_not_max_tier", "attribute_applied": ""}
		if card.faction != commander.faction:
			return {"success": false, "reason": "faction_mismatch", "attribute_applied": ""}

	if not DOCTRINE_LIMITS.has(commander.faction):
		return {"success": false, "reason": "faction_mismatch", "attribute_applied": ""}

	if attribute_choice != "escudo" and attribute_choice != "vida" and attribute_choice != "ataque":
		return {"success": false, "reason": "invalid_attribute_choice", "attribute_applied": ""}

	kingdom.ensure_military_doctrine(commander.faction)
	var doctrine: Dictionary = kingdom.military_doctrine[commander.faction]
	doctrine["grandes_legados"] += 1

	var limit: int = DOCTRINE_LIMITS[commander.faction][attribute_choice]
	var attribute_applied: String = ""
	if doctrine[attribute_choice] < limit:
		doctrine[attribute_choice] += 1
		attribute_applied = attribute_choice

	kingdom.military_doctrine[commander.faction] = doctrine

	# Consumo definitivo: as 9 cartas somem do plantel (nunca vão pro
	# Hall); o Comandante vira Retired e É registrado no Hall.
	for card: CardResource in army.cards.duplicate():
		kingdom.remove_card(card)

	CommandCenterResolver.retire(kingdom, commander)
	commander.retired_at_unix = now_unix
	commander.retirement_type = "Grande Legado Militar"
	if attribute_applied != "":
		commander.retirement_benefit = "+1 Atributo %s para %s" % [attribute_applied.capitalize(), commander.faction]
	else:
		commander.retirement_benefit = "Limites da Doutrina de %s já atingidos — nenhum atributo concedido (Regra de Excesso)" % commander.faction

	return {"success": true, "reason": "", "attribute_applied": attribute_applied}


static func patente_rank(patente: String) -> int:
	for i in range(CommanderCareer.PATENTE_THRESHOLDS.size()):
		if CommanderCareer.PATENTE_THRESHOLDS[i]["patente"] == patente:
			return i
	return -1


static func meets_patente(commander_patente: String, minimum_patente: String) -> bool:
	return patente_rank(commander_patente) >= patente_rank(minimum_patente)
