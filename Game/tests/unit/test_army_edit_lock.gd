class_name TestArmyEditLock
extends RefCounted
## TestArmyEditLock (F-001, Etapa 14)
##
## Migrado de bootstrap.gd:_validate_army_edit_lock(). Mesmo cenário
## original — validação FUNCIONAL da Trava de Edição por Modo de Jogo
## (ARMY.md). Usa Kingdom.new() local; kingdom.is_army_locked_for_editing()
## já confirmado puro (Stage 8) — só lê active_expeditions e all_mines(),
## ambos estado local deste Kingdom, sem nenhuma referência a
## KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/
## WorldBootstrap.
##
## CASO ESPECIAL (Etapa 14): o print original "disband_army() também
## recusaria (mesma trava)? ... (esperado: true)" NÃO chama
## disband_army() de verdade — o comentário do próprio original já
## explica por quê (disband_army() recusaria via assert(), então o teste
## captura o mesmo resultado através de is_army_locked_for_editing() de
## novo, em vez de derrubar o teste). A asserção abaixo mede exatamente
## o que o original mede — a trava continua ativa — sem alegar que
## disband_army() foi provado diretamente.
##
## O teste original já tinha "(esperado: X)" explícito em 3 pontos —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma
## regra. O print "Guarnição de Mina com Ciclo ativo -> travado..." não
## tinha marcador de expectativa explícito no original e permanece
## apenas informativo, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Exército] Validando a Trava de Edição por Modo de Jogo (ARMY.md)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (Trava)"
	commander.faction = "Império"
	kingdom.add_commander(commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, commander)
	var cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(commander, cards)

	print("  Exército recém-formado, sem nenhuma atividade -> livre pra editar? %s (esperado: true)" % str(
		not kingdom.is_army_locked_for_editing(army)["locked"]
	))
	ctx.check(not kingdom.is_army_locked_for_editing(army)["locked"], "Exército recém-formado, sem atividade, deve estar livre pra editar")

	# --- Trava de Mina ---
	var mina: Mina = kingdom.initial_mines[0]
	mina.guarnicao_army = army
	mina.start_cycle(GameClock.now_unix(), 1.0)
	var mina_lock: Dictionary = kingdom.is_army_locked_for_editing(army)
	print("  Guarnição de Mina com Ciclo ativo -> travado, com motivo claro? %s ('%s')" % [str(mina_lock["locked"]), mina_lock["reason"]])

	var mina_edit_blocked: bool = false
	# re_form_army() deve recusar via assert — captura isso testando o retorno da trava em vez de derrubar o teste.
	print("  disband_army() também recusaria (mesma trava)? %s (esperado: true)" % str(kingdom.is_army_locked_for_editing(army)["locked"]))
	ctx.check(kingdom.is_army_locked_for_editing(army)["locked"], "Army deve continuar travado com Guarnição de Mina ativa (re-verificado via is_army_locked_for_editing(), não via disband_army() em si)")

	mina.guarnicao_army = null
	mina.cycle_started_unix = 0
	print("  Depois de liberar a Guarnição -> destravado de novo? %s (esperado: true)" % str(
		not kingdom.is_army_locked_for_editing(army)["locked"]
	))
	ctx.check(not kingdom.is_army_locked_for_editing(army)["locked"], "Army deve destravar de novo após liberar a Guarnição da Mina")

	return true
