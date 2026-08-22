class_name TestEnemyEntrySerialization
extends RefCounted
## TestEnemyEntrySerialization (F-006)
##
## Regressão para o achado da F-005: SimulationReportService._enemy_entry_to_dict()
## não preservava commander.accumulated_xp nem commander.doctrine — ao
## recarregar uma Temporada salva em res://reports/season_catalog.json,
## todo Comandante "técnico" de uma Fase Normal (que EnemyArmyGenerator
## deliberadamente cria com XP correspondente à Patente mais alta da
## Região, pra que o teto de Soldo bata com REGION_SOLDO_CAP — ver
## enemy_army_generator.gd) voltava com accumulated_xp=0 (Patente
## "Recruta", teto 18) — bem mais restritivo que o teto pretendido na
## geração (24 pra Região 1). Uma composição legitimamente gerada com
## Soldo entre 19 e 24 passava a reprovar Army.is_ready_for_battle()
## depois do round-trip, mesmo tendo sido válida na criação — a causa
## direta do "CombatEngine: Exército B não está pronto para batalha".
##
## Dois cenários, ambos fazendo o round-trip real via
## SimulationReportService._enemy_entry_to_dict()/_dict_to_enemy_entry()
## (as mesmas funções usadas por save_season()/load_season() — só sem
## tocar em disco, para o teste ficar determinístico e rápido):
##
## 1) Cenário construído à mão, reproduzindo exatamente a assinatura do
##    achado da F-005 (Comandante com XP de "Major", Soldo=20 — válido
##    sob o teto de Major/24, inválido sob o teto de Recruta/18) —
##    determinístico, não depende de nenhuma geração aleatória.
## 2) Um EnemyArmyEntry Chefe Normal de verdade, via
##    EnemyArmyGenerator.generate() (mesmo motor de produção), pra
##    confirmar que a Doutrina sorteada de verdade (Restrição/Requisito/
##    Alvo/Efeito/Valor) sobrevive ao round-trip.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-006] Validando round-trip de EnemyArmyEntry (accumulated_xp e doctrine)...")

	# --- Cenário 1: reproduz exatamente a assinatura do achado da F-005 ---
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante Técnico (Império)"
	commander.faction = "Império"
	commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
		func(e: Dictionary) -> bool: return e["patente"] == "Major"
	)[0]["xp"]

	var cards: Array[CardResource] = []
	# Soldo (SOLDO.md): Comum=1, Rara=2, Épica=4, Lendária=7. Composição de
	# 9 cartas somando exatamente 20: 2 Comuns(2) + 5 Raras(10) + 2 Épicas(8) = 20
	# — válida sob o teto de Major (24), inválida sob o teto de Recruta (18),
	# reproduzindo exatamente a faixa vulnerável identificada na F-005.
	var rarities: Array[String] = ["Comum", "Comum", "Rara", "Rara", "Rara", "Rara", "Rara", "Épica", "Épica"]
	for i in range(9):
		var card := CardResource.new()
		card.card_name = "Carta de Teste %d" % i
		card.faction = "Império"
		card.card_class = "Corpo a Corpo"
		card.rarity = rarities[i]
		card.tier = 1
		cards.append(card)

	var entry := EnemyArmyEntry.new()
	entry.id = "teste_f006_normal"
	entry.faction = "Império"
	entry.category = EnemyArmyEntry.Category.NORMAL
	entry.region_min = 1
	entry.region_max = 1
	entry.army_name = "Império #teste"
	entry.commander = commander
	entry.cards = cards

	var soldo_total: int = Soldo.total_for_composition(cards)
	print("  Cenário 1 (mão): Soldo total da composição = %d (esperado: 20, entre o teto de Recruta/18 e o de Major/24)" % soldo_total)
	ctx.check(soldo_total == 20, "Composição de teste deve somar exatamente 20 de Soldo (obtido: %d)" % soldo_total)

	var probe_before := Army.new()
	probe_before.commander = entry.commander
	probe_before.cards = entry.cards
	var xp_before: int = entry.commander.accumulated_xp
	var patente_before: String = probe_before.commander_patente()
	var cap_before: int = Soldo.cap_for_patente(patente_before)
	var soldo_valid_before: bool = probe_before.is_soldo_within_cap()
	var ready_before: bool = probe_before.is_ready_for_battle()
	print("  ANTES do round-trip -> XP: %d | Patente: %s | Teto: %d | Soldo válido: %s | is_ready_for_battle: %s (esperado: 1200, Major, 24, true, true)" % [
		xp_before, patente_before, cap_before, str(soldo_valid_before), str(ready_before)
	])
	ctx.check(xp_before == 1200, "XP antes do round-trip deve ser 1200 (Major) (obtido: %d)" % xp_before)
	ctx.check(patente_before == "Major", "Patente antes do round-trip deve ser Major (obtido: %s)" % patente_before)
	ctx.check(cap_before == 24, "Teto de Soldo antes do round-trip deve ser 24 (obtido: %d)" % cap_before)
	ctx.check(soldo_valid_before, "Soldo (20) deve estar dentro do teto de Major (24) antes do round-trip")
	ctx.check(ready_before, "Army deve estar pronta para batalha antes do round-trip")

	var as_dict: Dictionary = SimulationReportService._enemy_entry_to_dict(entry)
	# Round-trip real via JSON (não só o dicionário em memória) — a mesma
	# conversão que save_season()/load_season() fazem, sem tocar em disco.
	var json_text: String = JSON.stringify(as_dict)
	var parsed: Dictionary = JSON.parse_string(json_text)
	var reloaded: EnemyArmyEntry = SimulationReportService._dict_to_enemy_entry(parsed)

	var probe_after := Army.new()
	probe_after.commander = reloaded.commander
	probe_after.cards = reloaded.cards
	var xp_after: int = reloaded.commander.accumulated_xp if reloaded.commander != null else -1
	var patente_after: String = probe_after.commander_patente()
	var cap_after: int = Soldo.cap_for_patente(patente_after)
	var soldo_valid_after: bool = probe_after.is_soldo_within_cap()
	var ready_after: bool = probe_after.is_ready_for_battle()
	print("  DEPOIS do round-trip -> XP: %d | Patente: %s | Teto: %d | Soldo válido: %s | is_ready_for_battle: %s (esperado: iguais ao ANTES)" % [
		xp_after, patente_after, cap_after, str(soldo_valid_after), str(ready_after)
	])
	ctx.check(reloaded.commander != null, "Comandante deve continuar existindo depois do round-trip")
	ctx.check(reloaded.commander.commander_name == entry.commander.commander_name, "Nome do Comandante deve ser preservado")
	ctx.check(reloaded.commander.faction == entry.commander.faction, "Facção do Comandante deve ser preservada")
	ctx.check(xp_after == xp_before, "accumulated_xp deve ser idêntico depois do round-trip (antes: %d, depois: %d)" % [xp_before, xp_after])
	ctx.check(patente_after == patente_before, "Patente deve ser idêntica depois do round-trip (antes: %s, depois: %s)" % [patente_before, patente_after])
	ctx.check(cap_after == cap_before, "Teto de Soldo deve ser idêntico depois do round-trip (antes: %d, depois: %d)" % [cap_before, cap_after])
	ctx.check(soldo_valid_after == soldo_valid_before, "Validade de Soldo deve ser idêntica depois do round-trip")
	ctx.check(ready_after == ready_before, "is_ready_for_battle() deve ser idêntico depois do round-trip (antes: %s, depois: %s)" % [str(ready_before), str(ready_after)])
	ctx.check(ready_after, "Army deve continuar pronta para batalha depois do round-trip (era a falha original da F-005)")

	# --- Cenário 2: EnemyArmyEntry Chefe Normal real, via EnemyArmyGenerator, pra verificar a Doutrina ---
	var config := SeasonConfig.new()
	config.seed_value = 1
	var chefe_entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
		EnemyArmyEntry.Category.CHEFE_NORMAL, "Império", 1, GameDatabase.cards, config,
		GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
		GameDatabase.commander_effects, GameDatabase.commander_values, "teste_f006_chefe", 1
	)
	var has_doctrine_before: bool = chefe_entry.commander.doctrine != null
	print("  Cenário 2 (Chefe Normal real): tem Doutrina antes do round-trip? %s (esperado: true)" % str(has_doctrine_before))
	ctx.check(has_doctrine_before, "Chefe Normal gerado de verdade deve ter Doutrina")

	var chefe_dict: Dictionary = SimulationReportService._enemy_entry_to_dict(chefe_entry)
	var chefe_json: String = JSON.stringify(chefe_dict)
	var chefe_parsed: Dictionary = JSON.parse_string(chefe_json)
	var chefe_reloaded: EnemyArmyEntry = SimulationReportService._dict_to_enemy_entry(chefe_parsed)

	var has_doctrine_after: bool = chefe_reloaded.commander != null and chefe_reloaded.commander.doctrine != null
	print("  Tem Doutrina depois do round-trip? %s (esperado: true)" % str(has_doctrine_after))
	ctx.check(has_doctrine_after, "Doutrina deve sobreviver ao round-trip")

	if has_doctrine_before and has_doctrine_after:
		var d_before: CommanderDoctrine = chefe_entry.commander.doctrine
		var d_after: CommanderDoctrine = chefe_reloaded.commander.doctrine
		var doctrine_equivalent: bool = (
			d_before.restriction.code == d_after.restriction.code and
			d_before.requirement.code == d_after.requirement.code and
			d_before.target.code == d_after.target.code and
			d_before.effect.code == d_after.effect.code and
			d_before.value.code == d_after.value.code and
			d_before.rarity_score == d_after.rarity_score
		)
		print("  Doutrina (Restrição/Requisito/Alvo/Efeito/Valor/Rarity Score) equivalente depois do round-trip? %s (esperado: true)" % str(doctrine_equivalent))
		ctx.check(doctrine_equivalent, "Os 5 componentes e o Rarity Score da Doutrina devem ser idênticos depois do round-trip")

	var xp_before_chefe: int = chefe_entry.commander.accumulated_xp
	var xp_after_chefe: int = chefe_reloaded.commander.accumulated_xp if chefe_reloaded.commander != null else -1
	print("  Chefe Normal -> accumulated_xp antes: %d | depois: %d (esperado: iguais)" % [xp_before_chefe, xp_after_chefe])
	ctx.check(xp_after_chefe == xp_before_chefe, "accumulated_xp do Chefe Normal deve ser preservado (antes: %d, depois: %d)" % [xp_before_chefe, xp_after_chefe])

	return true
