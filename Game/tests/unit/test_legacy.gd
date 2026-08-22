class_name TestLegacy
extends RefCounted
## TestLegacy (F-001, Etapa 15)
##
## Migrado de bootstrap.gd:_validate_legacy(). Mesmo cenário original —
## Legado Administrativo (Recruta bloqueado, General ganha 4/5
## benefícios — Legado I a IV, não V —, Lorde-Comandante exige
## legado_v_destino), efeito sobre
## CommandCenterProgress.effective_training_slots(), Grande Legado
## Militar (bloqueado abaixo do Nível 100 do CdC, depois um Exército
## Tier V real com Soldo exatamente no teto), e Regra de Excesso do
## Escudo (4 Comandantes extras esgotando o limite de 5, depois um 6º
## confirmando que não há mais bônus, mas ainda entra pro Hall). Usa
## Kingdom.new() local e LegacyResolver/CommandCenterProgress/Soldo
## (confirmado sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou transitiva).
##
## O padrão card_specs repetido (montagem do Exército Tier V de 9 cartas,
## 3 vezes: principal, laço de 4 extras, e 6º Comandante) foi preservado
## exatamente como no original — não é infraestrutura compartilhada de
## outras validações, e refatorá-lo em um helper não foi pedido nesta
## etapa. Os Exércitos de Grande Legado Militar são montados via
## Army.new() com .commander/.cards atribuídos diretamente (não
## kingdom.form_army()), exatamente como no original.
##
## ACHADO DE TRANSCRIÇÃO (Etapa 15, autocorrigido antes da remoção em
## bootstrap.gd): a primeira versão desta migração paraphraseou a chamada
## de LegacyResolver.create_grande_legado_militar() (Comandante/Exército/
## destino errados) e usou "patente" como string diretamente, quando o
## original nunca define esse campo — a qualificação de Patente é via
## accumulated_xp (4880 = limiar de General, 12480 = limiar de
## Lorde-Comandante). Corrigido por transcrição literal do bootstrap.gd
## antes de qualquer remoção — nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Legado] Validando Legado Administrativo e Grande Legado Militar...")

	var kingdom := Kingdom.new()
	kingdom.command_center_level = 10  # desbloqueia Legado I-V
	var now: int = GameClock.now_unix()

	# Abaixo do mínimo (Recruta) -> bloqueado.
	var recruit := CommanderResource.new()
	recruit.commander_name = "Recruta de Teste"
	kingdom.add_commander(recruit, now)
	var blocked: Dictionary = LegacyResolver.retire_administrative(kingdom, recruit, now)
	print("  Aposentar um Recruta (abaixo do Legado I) -> sucesso? %s | motivo: %s (esperado: false, below_minimum_patente)" % [
		str(blocked["success"]), blocked["reason"]
	])
	ctx.check(blocked["success"] == false, "Recruta não deve poder se aposentar via Legado Administrativo")
	ctx.check(blocked["reason"] == "below_minimum_patente", "Motivo do bloqueio deve ser below_minimum_patente (obtido: %s)" % blocked["reason"])

	# General: qualifica pra Legado I-IV, mas NÃO Legado V (exige Marechal).
	var general := CommanderResource.new()
	general.commander_name = "General de Teste"
	general.accumulated_xp = 4880  # limiar exato de General
	kingdom.add_commander(general, now)
	var general_result: Dictionary = LegacyResolver.retire_administrative(kingdom, general, now)
	print("  Aposentar um General -> sucesso? %s | Nº de benefícios: %d (esperado: true, 4 — Legado I a IV, não V)" % [
		str(general_result["success"]), general_result["benefits"].size()
	])
	ctx.check(general_result["success"] == true, "General deve conseguir se aposentar via Legado Administrativo")
	ctx.check(general_result["benefits"].size() == 4, "General deve receber 4 benefícios, Legado I a IV (obtido: %d)" % general_result["benefits"].size())

	print("  Estado agora: %s | Tipo de Aposentadoria: %s (esperado: RETIRED, 'Legado Administrativo')" % [
		CommanderResource.AdministrativeState.keys()[general.administrative_state], general.retirement_type
	])
	ctx.check(general.administrative_state == CommanderResource.AdministrativeState.RETIRED, "Estado administrativo do General deve ser RETIRED")
	ctx.check(general.retirement_type == "Legado Administrativo", "Tipo de aposentadoria do General deve ser 'Legado Administrativo' (obtido: %s)" % general.retirement_type)

	# Lorde-Comandante: qualifica pra todos os 5, exige destino do Legado V.
	var lorde := CommanderResource.new()
	lorde.commander_name = "Lorde-Comandante de Teste"
	lorde.accumulated_xp = 12480
	kingdom.add_commander(lorde, now)
	var missing_destino: Dictionary = LegacyResolver.retire_administrative(kingdom, lorde, now)
	print("  Aposentar um Lorde-Comandante sem escolher destino do Legado V -> sucesso? %s | motivo: %s (esperado: false, missing_legado_v_destino)" % [
		str(missing_destino["success"]), missing_destino["reason"]
	])
	ctx.check(missing_destino["success"] == false, "Lorde-Comandante sem legado_v_destino não deve conseguir se aposentar")
	ctx.check(missing_destino["reason"] == "missing_legado_v_destino", "Motivo deve ser missing_legado_v_destino (obtido: %s)" % missing_destino["reason"])

	var xp_before: float = kingdom.legacy_v_bonus_xp
	var lorde_result: Dictionary = LegacyResolver.retire_administrative(kingdom, lorde, now, "xp")
	print("  Aposentar o mesmo Lorde-Comandante, destino 'xp' -> sucesso? %s | Nº de benefícios: %d (esperado: true, 5) | Bônus XP: %.2f%% -> %.2f%%" % [
		str(lorde_result["success"]), lorde_result["benefits"].size(), xp_before, kingdom.legacy_v_bonus_xp
	])
	ctx.check(lorde_result["success"] == true, "Lorde-Comandante com legado_v_destino deve conseguir se aposentar")
	ctx.check(lorde_result["benefits"].size() == 5, "Lorde-Comandante deve receber 5 benefícios (obtido: %d)" % lorde_result["benefits"].size())

	print("  Hall dos Comandantes -> total registrado: %d (esperado: 2 — Recruta nunca chegou a se aposentar)" % kingdom.commander_hall().size())
	ctx.check(kingdom.commander_hall().size() == 2, "Hall dos Comandantes deve ter 2 aposentados, Recruta nunca se aposentou (obtido: %d)" % kingdom.commander_hall().size())

	# Capacidades efetivas: com 3 aposentados administrativos ainda não
	# chega a nenhum marco (precisa de 20/25/100) — mas confirma que a
	# fórmula soma corretamente ao simular retirees suficientes.
	var big_kingdom := Kingdom.new()
	big_kingdom.legacy_administrative_retirees = 40  # 2 marcos de Legado II (20 cada)
	print("  Com 40 aposentados -> Vagas de Treinamento efetivas (Nível 1, sem Legado seria 0): %d (esperado: 2)" % CommandCenterProgress.effective_training_slots(big_kingdom))
	ctx.check(CommandCenterProgress.effective_training_slots(big_kingdom) == 2, "Vagas efetivas com 40 Legados devem ser 2 (obtido: %d)" % CommandCenterProgress.effective_training_slots(big_kingdom))

	# Grande Legado Militar: bloqueado abaixo do Nível 100 do CdC.
	var glm_kingdom := Kingdom.new()
	glm_kingdom.command_center_level = 99
	var glm_commander := CommanderResource.new()
	glm_commander.commander_name = "Candidato a Grande Legado"
	glm_commander.faction = "Império"
	glm_commander.accumulated_xp = 12480
	glm_kingdom.add_commander(glm_commander, now)
	var glm_blocked_level: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, glm_commander, null, now, "escudo")
	print("  Grande Legado Militar com CdC Nível 99 -> sucesso? %s | motivo: %s (esperado: false, cdc_level_too_low)" % [
		str(glm_blocked_level["success"]), glm_blocked_level["reason"]
	])
	ctx.check(glm_blocked_level["success"] == false, "Grande Legado Militar deve ser bloqueado abaixo do Nível 100 do CdC")
	ctx.check(glm_blocked_level["reason"] == "cdc_level_too_low", "Motivo deve ser cdc_level_too_low (obtido: %s)" % glm_blocked_level["reason"])

	# Monta um Exército válido: 9 cartas Império, Tier V, Soldo exato 32
	# (3 Lendária + 1 Épica + 2 Rara + 3 Comum = 21+4+4+3 = 32).
	glm_kingdom.command_center_level = 100
	glm_kingdom.add_generation_points(10)
	CommandCenterResolver.activate_next(glm_kingdom)
	CommandCenterResolver.move_to_active(glm_kingdom, glm_commander)

	var glm_cards: Array[CardResource] = []
	var card_specs: Array = [
		["Marechal Imperial", 3], ["Centurião Imperial", 1], ["Guardião Imperial", 2], ["Legionário Imperial", 3],
	]
	for spec: Array in card_specs:
		var template: CardResource = GameDatabase.get_card(spec[0])
		for i in range(spec[1]):
			var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
			copy.tier = 5
			glm_cards.append(copy)

	var glm_army := Army.new()
	glm_army.commander = glm_commander
	glm_army.cards = glm_cards
	print("  Exército de teste -> Soldo total: %d / %d (esperado: 32, 32 — teto exato)" % [
		glm_army.soldo_total(), Soldo.cap_for_patente("Lorde-Comandante")
	])
	ctx.check(glm_army.soldo_total() == 32, "Soldo total do Exército Tier V deve ser 32 (obtido: %d)" % glm_army.soldo_total())
	ctx.check(Soldo.cap_for_patente("Lorde-Comandante") == 32, "Teto de Soldo de Lorde-Comandante deve ser 32 (obtido: %d)" % Soldo.cap_for_patente("Lorde-Comandante"))

	var glm_result: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, glm_commander, glm_army, now, "escudo")
	print("  Criar Grande Legado Militar (Império, +Escudo) -> sucesso? %s | atributo concedido: %s (esperado: true, escudo)" % [
		str(glm_result["success"]), glm_result["attribute_applied"]
	])
	ctx.check(glm_result["success"] == true, "Grande Legado Militar com Exército válido deve ter sucesso")
	ctx.check(glm_result["attribute_applied"] == "escudo", "Atributo aplicado deve ser escudo (obtido: %s)" % glm_result["attribute_applied"])

	print("  Doutrina do Império -> Escudo: %d | Cartas removidas do plantel: %d (esperado: 1, 0)" % [
		glm_kingdom.military_doctrine["Império"]["escudo"], glm_kingdom.cards.size()
	])
	ctx.check(glm_kingdom.military_doctrine["Império"]["escudo"] == 1, "Doutrina Militar de escudo deve ser 1 (obtido: %d)" % glm_kingdom.military_doctrine["Império"]["escudo"])
	ctx.check(glm_kingdom.cards.size() == 0, "Reino não deve ter mais nenhuma carta após o Grande Legado Militar (obtido: %d)" % glm_kingdom.cards.size())

	print("  Comandante consumido -> Estado: %s | Tipo: %s | Ainda no Hall? %s (esperado: RETIRED, 'Grande Legado Militar', true)" % [
		CommanderResource.AdministrativeState.keys()[glm_commander.administrative_state], glm_commander.retirement_type,
		str(glm_kingdom.commander_hall().has(glm_commander))
	])
	ctx.check(glm_commander.administrative_state == CommanderResource.AdministrativeState.RETIRED, "Comandante GLM deve ficar RETIRED")
	ctx.check(glm_commander.retirement_type == "Grande Legado Militar", "Tipo de aposentadoria do GLM deve ser 'Grande Legado Militar' (obtido: %s)" % glm_commander.retirement_type)
	ctx.check(glm_kingdom.commander_hall().has(glm_commander), "Comandante GLM deve entrar no Hall")

	# Regra de Excesso: esgota o limite de Escudo (5) e confirma que o
	# 6º Grande Legado ainda registra, mas sem novo atributo.
	for i in range(4):  # já tem 1, faltam 4 pra chegar em 5 (o limite)
		glm_kingdom.command_center_level = 100
		var extra_commander := CommanderResource.new()
		extra_commander.commander_name = "Extra %d" % i
		extra_commander.faction = "Império"
		extra_commander.accumulated_xp = 12480
		glm_kingdom.add_commander(extra_commander, now)
		CommandCenterResolver.activate_next(glm_kingdom)
		CommandCenterResolver.move_to_active(glm_kingdom, extra_commander)
		var extra_cards: Array[CardResource] = []
		for spec: Array in card_specs:
			var template: CardResource = GameDatabase.get_card(spec[0])
			for j in range(spec[1]):
				var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
				copy.tier = 5
				extra_cards.append(copy)
		var extra_army := Army.new()
		extra_army.commander = extra_commander
		extra_army.cards = extra_cards
		LegacyResolver.create_grande_legado_militar(glm_kingdom, extra_commander, extra_army, now, "escudo")

	print("  Após 5 Grandes Legados (limite de Escudo atingido) -> Escudo: %d (esperado: 5)" % glm_kingdom.military_doctrine["Império"]["escudo"])
	ctx.check(glm_kingdom.military_doctrine["Império"]["escudo"] == 5, "Doutrina Militar de escudo deve travar em 5 (obtido: %d)" % glm_kingdom.military_doctrine["Império"]["escudo"])

	var sixth_commander := CommanderResource.new()
	sixth_commander.commander_name = "6º Candidato"
	sixth_commander.faction = "Império"
	sixth_commander.accumulated_xp = 12480
	glm_kingdom.add_commander(sixth_commander, now)
	CommandCenterResolver.activate_next(glm_kingdom)
	CommandCenterResolver.move_to_active(glm_kingdom, sixth_commander)
	var sixth_cards: Array[CardResource] = []
	for spec: Array in card_specs:
		var template: CardResource = GameDatabase.get_card(spec[0])
		for j in range(spec[1]):
			var copy: CardResource = glm_kingdom.acquire_card_from_catalog(template)
			copy.tier = 5
			sixth_cards.append(copy)
	var sixth_army := Army.new()
	sixth_army.commander = sixth_commander
	sixth_army.cards = sixth_cards
	var sixth_result: Dictionary = LegacyResolver.create_grande_legado_militar(glm_kingdom, sixth_commander, sixth_army, now, "escudo")
	print("  6º Grande Legado (Regra de Excesso) -> sucesso? %s | atributo concedido: '%s' | Escudo continua: %d (esperado: true, '' vazio, 5)" % [
		str(sixth_result["success"]), sixth_result["attribute_applied"], glm_kingdom.military_doctrine["Império"]["escudo"]
	])
	ctx.check(sixth_result["success"] == true, "6º Comandante deve conseguir se aposentar mesmo sem mais bônus")
	ctx.check(sixth_result["attribute_applied"] == "", "6º Comandante não deve aplicar nenhum atributo adicional (obtido: %s)" % sixth_result["attribute_applied"])
	ctx.check(glm_kingdom.military_doctrine["Império"]["escudo"] == 5, "Doutrina Militar de escudo deve continuar travada em 5 (obtido: %d)" % glm_kingdom.military_doctrine["Império"]["escudo"])

	print("  Comandante do 6º Legado registrado no Hall mesmo sem ganhar atributo? %s (esperado: true)" % str(
		sixth_commander.administrative_state == CommanderResource.AdministrativeState.RETIRED
	))
	ctx.check(sixth_commander.administrative_state == CommanderResource.AdministrativeState.RETIRED, "6º Comandante deve ficar RETIRED mesmo sem bônus adicional")

	return true
