class_name TestCampoDeProvaArmySources
extends RefCounted
## TestCampoDeProvaArmySources (CAMPO_DE_PROVA.md, "Reestruturação do
## Campo de Prova")
##
## Cobre a parte desta reestruturação que é seguramente testável sem uma
## SceneTree ativa: geração de Army de teste (TestArmyFactory/
## ArmyRandomComposer, sem ownership, sem tocar o Reino) e a lógica de
## validação de configuração do painel (CampoDeProvaPanel).
##
## NÃO testado aqui (mesma limitação de qualquer overlay desta sessão que
## dependa de animação real): _on_iniciar_prova_pressed()/_run_prova(),
## porque aguardam CombatReplayView.replay_finished, que só avança dentro
## de uma SceneTree viva de verdade — chamar isso sem árvore travaria o
## teste esperando um sinal que nunca dispara. CombatEngine.initialize()/
## run() em si já são cobertos por outras suítes (test_movement_rules.gd,
## test_movement_sequence_compaction.gd, etc.) — o Campo de Prova só
## reaproveita esse pipeline sem alterá-lo.
##
## Escopo NÃO implementado nesta etapa (ver relatório da tarefa):
## montagem manual carta-a-carta do Army de teste — só "Formação
## Aleatória" existe hoje, por isso não há teste de "escolher
## manualmente uma Carta não possuída", só de geração aleatória.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Campo de Prova] Validando geração de Army de teste (sem ownership) e a lógica de validação do painel...")

	_test_1_random_army_is_ready_for_battle(ctx)
	_test_2_random_army_never_shares_catalog_objects(ctx)
	_test_3_random_army_never_touches_kingdom(ctx)
	_test_4_random_army_respects_support_and_machine_rules(ctx)
	_test_5_army_random_composer_reused_by_editor_and_factory(ctx)
	_test_6_panel_modo_simulado_does_not_require_ownership(ctx)
	_test_7_panel_modo_real_requires_player_army_and_test_army(ctx)
	_test_8_panel_mode_switch_discards_test_armies(ctx)

	return true


## TESTE 1: Army de teste gerado é estruturalmente válido (Formação
## completa, Soldo dentro do teto da Patente escolhida) — ARMY.md.
static func _test_1_random_army_is_ready_for_battle(ctx: TestRunner.Context) -> void:
	var army: Army = TestArmyFactory.generate_random_army()
	print("  [1] Army de teste gerado está pronto para batalha? %s (Cartas: %d, Comandante: %s)" % [
		str(army.is_ready_for_battle()), army.cards.size(), army.commander.commander_name if army.commander != null else "<nenhum>"
	])
	ctx.check(army.is_ready_for_battle() == true, "[1] TestArmyFactory.generate_random_army() deve produzir um Army estruturalmente válido (9 Cartas, Soldo dentro do teto)")


## TESTE 2: nem o Comandante nem as Cartas do Army de teste são os
## MESMOS objetos do catálogo (GameDatabase) — sempre .duplicate().
static func _test_2_random_army_never_shares_catalog_objects(ctx: TestRunner.Context) -> void:
	var army: Army = TestArmyFactory.generate_random_army()

	var commander_is_template: bool = GameDatabase.commanders.has(army.commander)
	print("  [2] Comandante do Army de teste é um objeto do catálogo (deveria ser um novo, gerado)? %s (esperado: false)" % str(commander_is_template))
	ctx.check(commander_is_template == false, "[2] O Comandante do Army de teste deve ser um CommanderResource novo (procedural), nunca um objeto do catálogo")

	var any_card_is_template: bool = false
	for card: CardResource in army.cards:
		if GameDatabase.cards.has(card):
			any_card_is_template = true
	print("     Alguma Carta do Army de teste é o mesmo objeto-template do catálogo? %s (esperado: false)" % str(any_card_is_template))
	ctx.check(any_card_is_template == false, "[2] Todas as Cartas do Army de teste devem ser cópias (.duplicate()), nunca os objetos-template de GameDatabase.cards")


## TESTE 3: gerar (múltiplos) Army de teste nunca altera Kingdom.armies/
## cards/commanders — nenhum efeito colateral no inventário do jogador
## (CAMPO_DE_PROVA.md, "Regras Permanentes").
static func _test_3_random_army_never_touches_kingdom(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var armies_before: int = kingdom.armies.size()
	var cards_before: int = kingdom.cards.size()
	var commanders_before: int = kingdom.commanders.size()

	for i in range(5):
		TestArmyFactory.generate_random_army()

	print("  [3] Kingdom.armies/cards/commanders inalterados após gerar 5 Army de teste? %s (%d->%d, %d->%d, %d->%d)" % [
		str(kingdom.armies.size() == armies_before and kingdom.cards.size() == cards_before and kingdom.commanders.size() == commanders_before),
		armies_before, kingdom.armies.size(), cards_before, kingdom.cards.size(), commanders_before, kingdom.commanders.size()
	])
	ctx.check(kingdom.armies.size() == armies_before, "[3] Gerar Army de teste não deve adicionar nada a Kingdom.armies")
	ctx.check(kingdom.cards.size() == cards_before, "[3] Gerar Army de teste não deve adicionar nada a Kingdom.cards")
	ctx.check(kingdom.commanders.size() == commanders_before, "[3] Gerar Army de teste não deve adicionar nada a Kingdom.commanders")


## TESTE 4: o Army de teste, gerado várias vezes, nunca viola Suporte-
## nunca-Posição-5 nem Máquina de Guerra-sempre-Posição-9 — reaproveita
## ArmyFormationArchetypes (já corrigido nesta sessão), nunca uma segunda
## regra de posicionamento.
##
## Correção da suíte (auditoria de 2026-09-02, "2 falhas restantes"): a
## asserção original exigia que TODA carta de Classe "Máquina de Guerra"
## estivesse no índice 8 — mas TestArmyFactory sorteia do catálogo
## COMPLETO e multi-facção (GameDatabase.cards, sem restrição de
## facção — ARMY.md não define nenhuma), e o catálogo tem uma Carta de
## Máquina de Guerra POR FACÇÃO (Balista Imperial/Altar da Reanimação/
## Árvore Ancestral) com Nomes distintos — Unicidade de Composição
## (ARMY.md) só proíbe Nome repetido, nunca proíbe duas Classes
## "Máquina de Guerra" de facções diferentes na mesma composição. Uma
## composição assim é estruturalmente válida e, quando sorteada, expõe
## uma regra JÁ estabelecida (não nova) em dois lugares:
## CombatEngine._place_army() e Army.would_have_support_at_position_5()
## — ambos, com o MESMO comentário/padrão, tratam apenas a PRIMEIRA
## Carta de Classe "Máquina de Guerra" (em ordem do Array) como a
## posição-9-obrigatória; qualquer Máquina de Guerra adicional é tratada
## como uma carta comum para fins de posicionamento (não há — nem
## poderia haver, só existe 1 Posição 9 — uma segunda "posição
## garantida" para ela). ArmyFormationArchetypes._extract_machine()
## replica fielmente esse mesmo comportamento (também só extrai a
## primeira). A asserção agora reflete essa regra real e já usada em
## produção, em vez de assumir (incorretamente) que uma composição
## nunca teria mais de uma Máquina de Guerra.
static func _test_4_random_army_respects_support_and_machine_rules(ctx: TestRunner.Context) -> void:
	var all_valid: bool = true
	for i in range(20):
		var army: Army = TestArmyFactory.generate_random_army()
		if not army.is_ready_for_battle():
			continue  # catálogo insuficiente pro teto nesta tentativa — não é o que este teste audita
		if Army.would_have_support_at_position_5(army.cards):
			all_valid = false
			print("  [4] MISMATCH: Army de teste #%d tem Suporte na Posição 5" % i)

		var machine_count: int = 0
		for card: CardResource in army.cards:
			if card.card_class == "Máquina de Guerra":
				machine_count += 1
		# Regra real (CombatEngine._place_army()): SE existe ao menos 1
		# Carta de Máquina de Guerra na composição, a Posição 9 (índice 8)
		# deve ser uma delas — nunca exige que TODAS estejam ali (só há 1
		# Posição 9), nem proíbe uma 2a/3a Máquina de Guerra alhures.
		if machine_count > 0 and army.cards[8].card_class != "Máquina de Guerra":
			all_valid = false
			print("  [4] MISMATCH: Army de teste #%d tem %d Carta(s) de Máquina de Guerra, mas a Posição 9 (índice 8) não é uma delas (é '%s')" % [i, machine_count, army.cards[8].card_class])

	print("  [4] 20 Army de teste gerados respeitam Suporte-fora-da-Posição-5 e Máquina-de-Guerra-na-Posição-9 (quando existir ao menos 1)? %s" % str(all_valid))
	ctx.check(all_valid, "[4] TestArmyFactory nunca deve produzir Suporte na Posição 5, e sempre que a composição contiver ao menos 1 Máquina de Guerra, a Posição 9 deve ser uma delas (herdado de ArmyFormationArchetypes/CombatEngine._place_army(), mesma regra real)")


## TESTE 5: a mesma heurística de composição aleatória (ArmyRandomComposer)
## é reaproveitada tanto pelo Editor de Exército quanto pelo Campo de
## Prova — nunca duas cópias da mesma regra. Valida diretamente a função
## extraída contra um pool pequeno e conhecido.
static func _test_5_army_random_composer_reused_by_editor_and_factory(ctx: TestRunner.Context) -> void:
	var pool: Array[CardResource] = []
	for name_suffix in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]:
		pool.append(TestMovementRules._build_combat_card("Composer-%s" % name_suffix, "Corpo a Corpo", 50, 50, 10))

	var composition: Array[CardResource] = ArmyRandomComposer.random_valid_composition(pool, 999)
	print("  [5] ArmyRandomComposer.random_valid_composition() retorna 9 Cartas de Nomes distintos dentro do teto? %s (obtido: %d)" % [str(composition.size() == 9), composition.size()])
	ctx.check(composition.size() == 9, "[5] ArmyRandomComposer.random_valid_composition() deve retornar exatamente 9 Cartas quando o pool permite (obtido: %d)" % composition.size())

	var names: Array[String] = []
	for card: CardResource in composition:
		names.append(card.card_name)
	var unique_names: Array = []
	for name: String in names:
		if not unique_names.has(name):
			unique_names.append(name)
	ctx.check(unique_names.size() == 9, "[5] ArmyRandomComposer.random_valid_composition() nunca deve repetir Nome (ARMY.md, Unicidade de Composição)")


## TESTE 6: Modo Simulado não exige nenhum Army próprio do jogador —
## ambos os lados vêm de TestArmyFactory.
static func _test_6_panel_modo_simulado_does_not_require_ownership(ctx: TestRunner.Context) -> void:
	var panel := CampoDeProvaPanel.new()
	panel._mode = "simulado"
	var kingdom: Kingdom = KingdomState.kingdom

	print("  [6] Modo Simulado sem nenhum Army de teste gerado ainda é inválido (esperado)? %s (esperado: true)" % str(not panel._configuration_is_valid(kingdom)))
	ctx.check(not panel._configuration_is_valid(kingdom), "[6] Modo Simulado sem nenhum Army de teste gerado deve ser inválido")

	panel._test_army_a = TestArmyFactory.generate_random_army()
	panel._test_army_b = TestArmyFactory.generate_random_army()
	print("     Modo Simulado com os dois lados gerados (nenhum pertencente ao jogador) fica válido? %s (esperado: true)" % str(panel._configuration_is_valid(kingdom)))
	ctx.check(panel._configuration_is_valid(kingdom), "[6] Modo Simulado com os dois lados gerados por TestArmyFactory deve ser válido, sem exigir ownership")
	panel.free()


## TESTE 7: Modo Real exige exatamente um Army real do jogador (lado
## "Seu Exército") + permite o segundo lado sem ownership; rejeita
## configuração em que nenhum lado é Army do jogador (aqui, simulado por
## Kingdom.armies vazio).
static func _test_7_panel_modo_real_requires_player_army_and_test_army(ctx: TestRunner.Context) -> void:
	var kingdom: Kingdom = KingdomState.kingdom
	var option: Dictionary = StarterKitResolver.generate_options(GameDatabase.cards)[0]
	var player_army := Army.new()
	player_army.commander = option["commander"]
	player_army.cards = (option["cards"] as Array[CardResource]).duplicate()

	var panel := CampoDeProvaPanel.new()
	panel._mode = "real"

	print("  [7a] Modo Real rejeita configuração sem nenhum Army do jogador (Kingdom.armies vazio)? %s (esperado: true)" % str(not panel._configuration_is_valid(kingdom)))
	ctx.check(not panel._configuration_is_valid(kingdom), "[7a] Modo Real sem nenhum Army do jogador em Kingdom.armies deve ser inválido")

	kingdom.armies.append(player_army)
	panel._selected_player_army_index = kingdom.armies.find(player_army)

	print("     Modo Real com Army do jogador mas SEM Army de teste ainda é inválido? %s (esperado: true)" % str(not panel._configuration_is_valid(kingdom)))
	ctx.check(not panel._configuration_is_valid(kingdom), "[7b] Modo Real com Army do jogador mas sem Army de teste configurado deve ser inválido")

	panel._test_army_b = TestArmyFactory.generate_random_army()
	print("     Modo Real com Army do jogador + Army de teste (sem ownership) fica válido? %s (esperado: true)" % str(panel._configuration_is_valid(kingdom)))
	ctx.check(panel._configuration_is_valid(kingdom), "[7c] Modo Real com 1 Army do jogador + 1 Army de teste sem ownership deve ser válido — SEGUNDO Army NÃO precisa pertencer ao jogador")

	kingdom.armies.erase(player_army)
	panel.free()


## TESTE 8: trocar de Modo descarta qualquer Army de teste já gerado —
## evita levar por engano uma composição sorteada num Modo pro outro.
static func _test_8_panel_mode_switch_discards_test_armies(ctx: TestRunner.Context) -> void:
	var panel := CampoDeProvaPanel.new()
	panel._mode = "simulado"
	panel._test_army_a = TestArmyFactory.generate_random_army()
	panel._test_army_b = TestArmyFactory.generate_random_army()

	panel._on_mode_selected("real")

	print("  [8] Trocar para Modo Real descarta os Army de teste do Modo Simulado? A=%s B=%s (esperado: null, null)" % [str(panel._test_army_a), str(panel._test_army_b)])
	ctx.check(panel._test_army_a == null, "[8] _test_army_a deve ser descartado ao trocar de Modo")
	ctx.check(panel._test_army_b == null, "[8] _test_army_b deve ser descartado ao trocar de Modo")
	panel.free()
