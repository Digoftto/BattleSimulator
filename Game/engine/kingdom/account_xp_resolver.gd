class_name AccountXPResolver
extends RefCounted
## AccountXPResolver
##
## Concede XP de Conta (Reino) — `XP.md`, "Ações Que Concedem XP de
## Conta (Valores Oficiais)" — e converte automaticamente em Pontos de
## Geração ao cruzar um novo Nível de Conta (200 XP = 1 Nível = 1 PG).
##
## Kingdom nunca decide isso sozinho — cada Resolver que já orquestra
## a ação correspondente (CityResolver, InstitutionalConstructionResolver,
## MineConquestResolver, etc.) deve chamar o método correspondente aqui
## logo após a ação ter sucesso.
##
## XP Estrutural (`XP.md`): concedido só na primeira vez que a
## conquista acontece — identificado por "unique_key". Chamar de novo
## com a mesma chave não concede XP outra vez. XP Operacional: sem
## unique_key, concedido toda vez que a ação ocorre.
##
## Escopo desta Sprint: todos os métodos de `XP.md` estão implementados
## abaixo, mas só são chamados de fato onde já existe um Resolver
## orquestrando a ação (Depósito, Capital/CdC/Academia/Núcleo, conquista
## de Mina). PvP, obtenção/Tier de cartas, conclusão de Região e
## recrutamento/promoção de Comandante ainda não têm um ponto de
## chamada real no código (nenhum Resolver orquestra essas ações
## ainda) — os métodos existem, prontos, mas não são invocados até que
## esses sistemas existam.

const XP_PER_LEVEL: int = 200


## Núcleo genérico: concede "amount" de XP, exceto se "unique_key" já
## foi concedida antes (conquista estrutural repetida — "" nunca
## bloqueia, usado para XP Operacional). Retorna
## {"granted": bool, "levels_gained": int, "pg_gained": int}.
static func grant(kingdom: Kingdom, amount: int, unique_key: String = "") -> Dictionary:
	if unique_key != "" and kingdom.has_structural_xp(unique_key):
		return {"granted": false, "levels_gained": 0, "pg_gained": 0}

	if unique_key != "":
		kingdom.mark_structural_xp(unique_key)

	var level_before: int = kingdom.account_level()
	kingdom.add_account_xp(amount)
	var level_after: int = kingdom.account_level()
	var levels_gained: int = level_after - level_before

	if levels_gained > 0:
		kingdom.add_generation_points(levels_gained)

	return {"granted": true, "levels_gained": levels_gained, "pg_gained": levels_gained}


# --- 1. Cidade (Estrutural — concedido a CADA nível subido, não só a
# primeira vez: XP.md, "cada novo nível representa uma conquista
# estrutural nova e permanente do Reino"). Sem unique_key de propósito.

static func grant_city_evolution_capital(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 20)


static func grant_city_evolution_command_center(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 20)


static func grant_city_evolution_academy(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 15)


static func grant_city_evolution_energy_nucleus(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 15)


static func grant_city_evolution_deposito(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 10)


# --- 2. Coleção (Estrutural — primeira vez por carta específica) ---

static func grant_card_obtained(kingdom: Kingdom, card_name: String, rarity: String) -> Dictionary:
	var amount: int = 0
	match rarity:
		"Comum":
			amount = 3
		"Rara":
			amount = 6
		"Épica":
			amount = 12
		"Lendária":
			amount = 24
	return grant(kingdom, amount, "card_obtained:%s" % card_name)


static func grant_card_tier_reached(kingdom: Kingdom, card_name: String, tier: int) -> Dictionary:
	var amount: int = 0
	match tier:
		2:
			amount = 2
		3:
			amount = 4
		4:
			amount = 8
		5:
			amount = 12
	return grant(kingdom, amount, "card_tier:%s:%d" % [card_name, tier])


# --- 3. PvP (Operacional) ---

static func grant_pvp_result(kingdom: Kingdom, result: String) -> Dictionary:
	var amount: int = 0
	match result:
		"vitoria":
			amount = 3
		"empate":
			amount = 2
		"derrota":
			amount = 1
	return grant(kingdom, amount)


# --- 4. PvE (Operacional + Estrutural) ---

static func grant_pve_fase_comum(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 1)


static func grant_pve_chefe(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 10)


static func grant_pve_chefe_regional(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 30)


static func grant_mina_liberada(kingdom: Kingdom, mina_key: String) -> Dictionary:
	return grant(kingdom, 20, "mina_liberada:%s" % mina_key)


static func grant_regiao_concluida(kingdom: Kingdom, regiao_key: String) -> Dictionary:
	return grant(kingdom, 40, "regiao_concluida:%s" % regiao_key)


# --- 5. Comandantes (Estrutural) ---

static func grant_comandante_recrutado(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 20)


static func grant_patente_promovida(kingdom: Kingdom) -> Dictionary:
	return grant(kingdom, 15)
