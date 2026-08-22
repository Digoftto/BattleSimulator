class_name TestCommanderDoctrine
extends RefCounted
## TestCommanderDoctrine (F-001, Etapa 19)
##
## Migração PARCIAL de bootstrap.gd:_validate_commander_doctrine() — o
## mesmo padrão de extração já usado nas migrações parciais da Etapa 15
## (_validate_army_formation_archetypes / _validate_commander_battle_history).
##
## Extrai o núcleo determinístico e totalmente local da validação
## original: Restrição estática (CommanderDoctrineValidator.check_static),
## Restrição de Campo de Batalha (check_battlefield), Efeito de Ataque
## aplicado de verdade em combate (CommanderDoctrineRuntime.attack_multiplier
## via CombatEngine.initialize()) e o bloqueio real no PvE sem gastar
## Energia (PhaseResolver.resolve()). Nenhuma referência a
## KingdomState/WorldDatabase/UI/disco/await/WorkerThreadPool.
##
## Deliberadamente NÃO migrados (permanecem em bootstrap.gd,
## _validate_commander_doctrine(), reduzida a essas duas partes):
## - a checagem de que RecruitmentCenterResolver liga a Doutrina de
##   verdade no Comandante gerado (RecruitmentCenterResolver._generate_candidate()
##   usa CommanderGenerator, RNG global sem seed, sem parâmetro de
##   determinismo — mesmo achado de arquitetura já documentado nas
##   auditorias de Stage 17/18, não resolvido aqui);
## - o round-trip de salvar/carregar via KingdomSaveService (mesmo
##   caminho fixo de disco, "user://kingdom_save.json", já documentado
##   como decisão de sandbox adiada).
##
## RNG: CombatEngine.initialize() usa CombatState.rng apenas para o
## sorteio de Campo de Batalha (Efeito não aplicado nesta Sprint) —
## estruturalmente inerte, mesma fixture (CampaignTestFixtures, sem
## cartas com Habilidade) e mesmo raciocínio já estabelecido em
## test_phase_retry.gd/test_mine_conquest.gd. Nenhuma seed foi
## adicionada, nenhum código de produção foi alterado.
##
## _find_by_code_test() copiado de bootstrap.gd (helper de uso único,
## sem outros consumidores fora de _validate_commander_doctrine()) — a
## cópia em bootstrap.gd permanece, pois a parte remanescente da função
## original também precisa dela.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave desta fatia — convertidos abaixo em asserções reais, sem
## reinterpretar nenhuma regra.

static func _find_by_code_test(bank: Array, code: String) -> Variant:
	for entry: Variant in bank:
		if entry.code == code:
			return entry
	return null


static func run(ctx: TestRunner.Context) -> bool:
	print("[Doutrina] Validando Restrição, Efeito de Combate e o bloqueio real no PvE...")

	# --- Restrição estática: construção manual e determinística ---
	var restriction_max_class: CommanderRestrictionResource = _find_by_code_test(GameDatabase.commander_restrictions, "RS020")  # Máximo 2 da Classe
	var requirement_faction: CommanderRequirementResource = _find_by_code_test(GameDatabase.commander_requirements, "R001")  # Pelo menos 2 da Facção
	var target_faction: CommanderTargetResource = _find_by_code_test(GameDatabase.commander_targets, "A001")
	var effect_attack: CommanderEffectResource = _find_by_code_test(GameDatabase.commander_effects, "E001")
	var value_attack: CommanderValueResource = _find_by_code_test(GameDatabase.commander_values, "V003")  # +20%

	var doctrine := CommanderDoctrine.new()
	doctrine.faction = "Império"
	doctrine.restriction = restriction_max_class
	doctrine.restriction_param = "Melee"
	doctrine.requirement = requirement_faction
	doctrine.requirement_param = ""
	doctrine.target = target_faction
	doctrine.effect = effect_attack
	doctrine.value = value_attack
	doctrine.rarity_score = 10

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste da Doutrina"
	commander.faction = "Império"
	commander.doctrine = doctrine

	var valid_cards: Array[CardResource] = []
	for i in range(6):
		var card := CardResource.new()
		card.faction = "Império"
		card.card_class = "À Distância"
		card.rarity = "Comum"
		valid_cards.append(card)
	for i in range(3):
		var card := CardResource.new()
		card.faction = "Natureza"
		card.card_class = "Mago"
		card.rarity = "Comum"
		valid_cards.append(card)

	var valid_composition_ok: bool = CommanderDoctrineValidator.check_static(commander, valid_cards, "pve") == ""
	print("  Composição válida (0 Corpo a Corpo) -> Restrição de Classe não bloqueia? %s (esperado: true, \"\")" % str(valid_composition_ok))
	ctx.check(valid_composition_ok, "Composição válida (0 Corpo a Corpo) não deve ser bloqueada pela Restrição de Classe")

	var invalid_cards: Array[CardResource] = valid_cards.duplicate()
	invalid_cards[0] = CardResource.new()
	invalid_cards[0].faction = "Império"
	invalid_cards[0].card_class = "Corpo a Corpo"
	invalid_cards[0].rarity = "Comum"
	invalid_cards[1] = CardResource.new()
	invalid_cards[1].faction = "Império"
	invalid_cards[1].card_class = "Corpo a Corpo"
	invalid_cards[1].rarity = "Comum"
	invalid_cards[2] = CardResource.new()
	invalid_cards[2].faction = "Império"
	invalid_cards[2].card_class = "Corpo a Corpo"
	invalid_cards[2].rarity = "Comum"
	var block_message: String = CommanderDoctrineValidator.check_static(commander, invalid_cards, "pve")
	print("  Composição com 3 Corpo a Corpo (máximo é 2) -> bloqueada com mensagem clara? %s | Mensagem: \"%s\"" % [
		str(block_message != ""), block_message
	])
	ctx.check(block_message != "", "Composição com 3 Corpo a Corpo (máximo é 2) deve ser bloqueada com mensagem clara")

	# --- Restrição de Campo de Batalha ---
	var battlefield_restriction: CommanderRestrictionResource = _find_by_code_test(GameDatabase.commander_restrictions, "RS030")  # Apenas Campo Aberto
	var battlefield_doctrine := CommanderDoctrine.new()
	battlefield_doctrine.restriction = battlefield_restriction
	battlefield_doctrine.requirement = requirement_faction
	battlefield_doctrine.target = target_faction
	battlefield_doctrine.effect = effect_attack
	battlefield_doctrine.value = value_attack
	var battlefield_commander := CommanderResource.new()
	battlefield_commander.commander_name = "Comandante Só-Campo-Aberto"
	battlefield_commander.doctrine = battlefield_doctrine

	var open_field := BattlefieldResource.new()
	open_field.battlefield_name = "Campo Aberto"
	open_field.category = "Campo Aberto"
	var storm_field := BattlefieldResource.new()
	storm_field.battlefield_name = "Tempestade com Raios"
	storm_field.category = "Especial"

	var open_field_allowed: bool = CommanderDoctrineValidator.check_battlefield(battlefield_commander, open_field) == ""
	var storm_field_blocked: bool = CommanderDoctrineValidator.check_battlefield(battlefield_commander, storm_field) != ""
	print("  Campo Aberto não bloqueia Comandante 'Apenas Campo Aberto'? %s | Campo diferente bloqueia com mensagem clara? %s (esperado: true, true)" % [
		str(open_field_allowed), str(storm_field_blocked)
	])
	ctx.check(open_field_allowed, "Campo Aberto não deve bloquear o Comandante 'Apenas Campo Aberto'")
	ctx.check(storm_field_blocked, "Um Campo diferente de Campo Aberto deve bloquear o Comandante 'Apenas Campo Aberto', com mensagem clara")

	# --- Efeito de Ataque aplicado de verdade em combate ---
	var attack_army := Army.new()
	attack_army.commander = commander
	attack_army.cards = valid_cards
	var attack_state: CombatState = CombatEngine.initialize(
		attack_army, CampaignTestFixtures.build_campaign_enemy_army(), GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)
	var boosted_unit: CombatUnit = attack_state.units[0]  # side 0, Império, dentro do Alvo (Facção) e do Requisito (>= 2 Império)
	var multiplier: float = CommanderDoctrineRuntime.attack_multiplier(boosted_unit, attack_state)
	print("  Efeito de Ataque (+20%%) da Doutrina realmente calculado no combate? %s (%.2fx, esperado: true, 1.20)" % [
		str(abs(multiplier - 1.2) < 0.001), multiplier
	])
	ctx.check(abs(multiplier - 1.2) < 0.001, "Efeito de Ataque (+20%%) da Doutrina deve resultar num multiplicador de 1.20x (obtido: %.4f)" % multiplier)

	# --- Bloqueio real no PvE, sem gastar Energia ---
	var blocking_doctrine := CommanderDoctrine.new()
	blocking_doctrine.restriction = _find_by_code_test(GameDatabase.commander_restrictions, "RS025")  # Não aceita a classe especificada
	blocking_doctrine.restriction_param = "Ranged"
	blocking_doctrine.requirement = requirement_faction
	blocking_doctrine.target = target_faction
	blocking_doctrine.effect = effect_attack
	blocking_doctrine.value = value_attack

	var blocked_commander := CommanderResource.new()
	blocked_commander.commander_name = "Comandante Bloqueado de Propósito"
	blocked_commander.faction = "Império"
	blocked_commander.doctrine = blocking_doctrine

	var blocked_army: Army = CampaignTestFixtures.build_campaign_test_army({})
	blocked_army.commander = blocked_commander
	blocked_army.cards[0].card_class = "À Distância"  # a Restrição proíbe "Ranged" -> mapeado "À Distância"
	blocked_army.initialize_energy(1)
	var energy_before: int = blocked_army.current_energy

	var squad := Squad.new([blocked_army])
	var enemy_entry := EnemyArmyEntry.new()
	enemy_entry.commander = CampaignTestFixtures.build_campaign_enemy_army().commander
	enemy_entry.cards = CampaignTestFixtures.build_campaign_enemy_army().cards
	enemy_entry.faction = "Mortos-Vivos"

	var phase_result: PhaseResult = PhaseResolver.resolve(
		squad, enemy_entry, GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits, "Teste de Bloqueio", "pve"
	)
	var has_block_message: bool = false
	for line: String in phase_result.history_log:
		if line.find("bloqueada") != -1:
			has_block_message = true
	var energy_unchanged: bool = blocked_army.current_energy == energy_before
	print("  PvE bloqueia de verdade uma Formação com Restrição violada -> mensagem no histórico? %s | Energia NÃO foi gasta (%d -> %d)? %s (esperado: true, true)" % [
		str(has_block_message), energy_before, blocked_army.current_energy, str(energy_unchanged)
	])
	ctx.check(has_block_message, "PvE deve bloquear uma Formação com Restrição violada, com mensagem no histórico")
	ctx.check(energy_unchanged, "Energia não deve ser gasta quando o PvE bloqueia por Restrição violada")

	return true
