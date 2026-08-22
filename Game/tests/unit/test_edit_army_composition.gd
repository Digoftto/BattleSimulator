class_name TestEditArmyComposition
extends RefCounted
## TestEditArmyComposition (F-001, Etapa 18)
##
## Migrado de bootstrap.gd:_validate_edit_army_composition(). Mesmo
## cenário original — o botão "Editar Exército" troca a composição de
## verdade (Kingdom.re_form_army), libera o Comandante e cartas antigas,
## aloca os novos.
##
## Adaptação MVP (trivial, não muda o objetivo do teste): o original lia
## KingdomState.kingdom (Reino compartilhado do processo de bootstrap);
## aqui usa um Kingdom.new() local, já que nada nesta função depende de
## estado global do Reino além de precisar de UM Kingdom qualquer para
## chamar add_commander()/form_army()/re_form_army() — os mesmos métodos
## de instância, chamados da mesma forma. Nenhuma alteração em
## Game/engine/.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Exércitos] Validando 'Editar Exército' (trocar composição, não só Formações)...")

	var kingdom := Kingdom.new()
	var old_commander := CommanderResource.new()
	old_commander.commander_name = "Comandante Antigo (Editar Composição)"
	old_commander.faction = "Império"
	kingdom.add_commander(old_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, old_commander)
	var old_cards: Array[CardResource] = []
	var template: CardResource = GameDatabase.cards[0]
	for i in range(9):
		old_cards.append(kingdom.acquire_card_from_catalog(template))
	var army: Army = kingdom.form_army(old_commander, old_cards)

	var new_commander := CommanderResource.new()
	new_commander.commander_name = "Comandante Novo (Editar Composição)"
	new_commander.faction = "Império"
	kingdom.add_commander(new_commander, GameClock.now_unix())
	kingdom.cargo_ativo_activated += 1
	CommandCenterResolver.move_to_active(kingdom, new_commander)
	var new_cards: Array[CardResource] = []
	for i in range(9):
		new_cards.append(kingdom.acquire_card_from_catalog(template))

	kingdom.re_form_army(army, new_commander, new_cards)

	var uses_new_commander: bool = army.commander == new_commander
	print("  Exército passou a usar o novo Comandante de verdade? %s (esperado: true)" % str(uses_new_commander))
	ctx.check(uses_new_commander, "Exército deve passar a usar o novo Comandante após re_form_army()")

	var old_commander_freed: bool = old_commander.ownership_status == CommanderResource.OwnershipStatus.LIVRE
	print("  Comandante antigo foi liberado (voltou a poder liderar outro Exército)? %s (esperado: true)" % str(old_commander_freed))
	ctx.check(old_commander_freed, "Comandante antigo deve ser liberado (LIVRE) após re_form_army()")

	var old_cards_freed: bool = old_cards[0].ownership_status == CardResource.OwnershipStatus.LIVRE
	print("  Cartas antigas foram liberadas de verdade? %s (esperado: true)" % str(old_cards_freed))
	ctx.check(old_cards_freed, "Cartas antigas devem ser liberadas (LIVRE) após re_form_army()")

	var formations_regenerated: bool = army.formations["β"].has(new_cards[0]) or army.formations["β"].has(new_cards[1])
	print("  As 5 Formações foram regeneradas com as cartas novas? %s (esperado: true)" % str(formations_regenerated))
	ctx.check(formations_regenerated, "As Formações devem ser regeneradas com as cartas novas após re_form_army()")

	return true
