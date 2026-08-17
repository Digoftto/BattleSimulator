class_name MineGuarnicaoResolver
extends RefCounted
## MineGuarnicaoResolver
##
## Designa um Exército como Guarnição de uma Mina, aplicando a trava
## anti-exploit (MINES.md, "Trava do Exército (Anti-Exploit)"): um
## Exército só pode ser designado se estiver disponível, e uma Mina só
## aceita nova designação se não houver Ciclo de Mineração ativo.
##
## Kingdom/Mina/Army nunca decidem isso sozinhos — este resolver
## verifica as condições e efetiva a designação, no mesmo padrão já
## usado por RecruitmentResolver, MineConquestResolver e CityResolver.


## Tenta designar "army" como Guarnição de "mina". Retorna
## {"success": bool, "reason": String}. "reason" é "" em caso de
## sucesso, ou explica o bloqueio:
## - "not_conquered": a Mina ainda não foi conquistada.
## - "cycle_active": já existe um Ciclo de Mineração ativo nesta Mina —
##   só é possível redesignar após o ciclo terminar.
## - "army_unavailable": o Exército já está ocupado em outra função
##   (combate, recuperação, ou já é Guarnição de outra Mina).
static func assign(mina: Mina, army: Army, now_unix: int) -> Dictionary:
	if not mina.conquered:
		return {"success": false, "reason": "not_conquered"}

	if mina.is_cycle_active(now_unix):
		return {"success": false, "reason": "cycle_active"}

	if army.availability != Army.Availability.AVAILABLE:
		return {"success": false, "reason": "army_unavailable"}

	# Libera o Exército anteriormente designado (se houver e for
	# diferente do novo) — ele nunca fica travado sem um ciclo ativo
	# usando-o de verdade.
	if mina.guarnicao_army != null and mina.guarnicao_army != army:
		mina.guarnicao_army.availability = Army.Availability.AVAILABLE

	mina.assign_guarnicao(army)
	army.availability = Army.Availability.GUARNICAO_MINA
	return {"success": true, "reason": ""}


## Libera a Guarnição de "mina" de volta para Army.Availability.AVAILABLE
## se o Ciclo de Mineração atual já tiver terminado (ou nunca tiver
## começado). Não faz nada se o ciclo ainda estiver ativo — chamado
## rotineiramente por GameRuntime.sync().
static func release_if_cycle_ended(mina: Mina, now_unix: int) -> void:
	if mina.guarnicao_army == null:
		return
	if mina.is_cycle_active(now_unix):
		return
	if mina.guarnicao_army.availability == Army.Availability.GUARNICAO_MINA:
		mina.guarnicao_army.availability = Army.Availability.AVAILABLE
