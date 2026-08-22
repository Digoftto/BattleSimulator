class_name TestMineReferenceFormation
extends RefCounted
## TestMineReferenceFormation (F-001, Etapa 17)
##
## Migrado de bootstrap.gd:_validate_mine_reference_formation(). Mesmo
## cenário original — o Chefe de Mina: EnemyArmySelector embaralha a
## posição das cartas (deixando de ser "a mais eficiente" do Chefe
## Regional original), de forma determinística, e
## MineConquestResolver/Mina.freeze_reference_formation() congela essa
## formação embaralhada permanentemente na Mina, no momento exato da
## conquista. Usa CampaignTestFixtures e Mina.new() locais — sem nenhuma
## referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva.
##
## RNG: EnemyArmySelector.select() recebe a seed explícita 42 em cada
## chamada (mesmo valor do original, preservado sem alteração) — a
## semente é combinada deterministicamente com Fase/Categoria
## (_combine_seed() em enemy_army_selector.gd) para o índice de seleção
## e para o embaralhamento Fisher-Yates das posições. O próprio
## embaralhamento determinístico é a funcionalidade sob teste (não é um
## RNG incidental a ser tolerado — é o comportamento validado pelas
## asserções de "mesma seed produz o mesmo resultado" abaixo). Nenhuma
## seed foi adicionada, nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando embaralhamento do Chefe de Mina e congelamento da formação de referência...")

	var enemy_army: Army = CampaignTestFixtures.build_campaign_enemy_army()
	var original_order: Array[String] = []
	original_order.assign(enemy_army.cards.map(func(c: CardResource) -> String: return c.card_name))
	var catalog: SeasonCatalog = CampaignTestFixtures.build_test_season_catalog("Natureza", enemy_army)

	# Chefe Regional (mesma composição): mantém a posição original.
	var regional: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 42, null
	)
	var regional_order: Array[String] = []
	regional_order.assign(regional.cards.map(func(c: CardResource) -> String: return c.card_name))
	var regional_preserves_order: bool = regional_order == original_order
	print("  Chefe Regional preserva a posição original? %s (esperado: true)" % str(regional_preserves_order))
	ctx.check(regional_preserves_order, "Chefe Regional deve preservar a posição original das cartas")

	# Chefe de Mina (mesma composição, mesma seed/fase): posição embaralhada.
	var mina_entry: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_DE_MINA, 1, 500, 42, null
	)
	var mina_order: Array[String] = []
	mina_order.assign(mina_entry.cards.map(func(c: CardResource) -> String: return c.card_name))
	var mina_shuffled: bool = mina_order != original_order
	print("  Chefe de Mina embaralhou a posição? %s (esperado: true, mesmas 9 cartas)" % str(mina_shuffled))
	ctx.check(mina_shuffled, "Chefe de Mina deve embaralhar a posição das cartas em relação à ordem original")

	var mina_sorted: Array[String] = mina_order.duplicate()
	mina_sorted.sort()
	var original_sorted: Array[String] = original_order.duplicate()
	original_sorted.sort()
	var same_counts: bool = mina_sorted == original_sorted
	print("  Continuam sendo exatamente as mesmas 9 cartas (só a ordem muda)? %s (esperado: true)" % str(same_counts))
	ctx.check(same_counts, "O embaralhamento deve preservar exatamente as mesmas 9 cartas, só mudando a ordem")

	# Determinismo: mesma Facção/Categoria/Região/Fase/Seed -> mesmo embaralhamento sempre.
	var mina_entry_again: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Natureza", EnemyArmyEntry.Category.CHEFE_DE_MINA, 1, 500, 42, null
	)
	var mina_order_again: Array[String] = []
	mina_order_again.assign(mina_entry_again.cards.map(func(c: CardResource) -> String: return c.card_name))
	var same_shuffle: bool = mina_order == mina_order_again
	print("  Repetir a mesma seleção produz o mesmo embaralhamento? %s (esperado: true)" % str(same_shuffle))
	ctx.check(same_shuffle, "A mesma seed/Fase/Categoria deve produzir sempre o mesmo embaralhamento")

	# Congelamento na conquista: valida Mina.freeze_reference_formation()
	# diretamente com o resultado real do EnemyArmySelector (o mesmo
	# dado que MineConquestResolver usa internamente ao vencer).
	var mina := Mina.new(500, "Natureza")
	var has_reference_before: bool = mina.has_reference_formation()
	print("  Antes da conquista -> tem formação de referência? %s (esperado: false)" % str(has_reference_before))
	ctx.check(has_reference_before == false, "Mina não deve ter formação de referência antes da conquista")

	mina.conquer()
	mina.freeze_reference_formation(mina_entry.cards, mina_entry.commander)
	var has_reference_after: bool = mina.has_reference_formation()
	print("  Após conquista -> tem formação de referência? %s (esperado: true)" % str(has_reference_after))
	ctx.check(has_reference_after == true, "Mina deve ter formação de referência após o congelamento na conquista")

	var frozen_matches_shuffle: bool = mina.reference_cards.map(func(c: CardResource) -> String: return c.card_name) == mina_order
	print("  Formação congelada tem 9 cartas, na mesma ordem embaralhada? %s (esperado: true)" % str(frozen_matches_shuffle))
	ctx.check(frozen_matches_shuffle, "A formação congelada deve ter as 9 cartas na mesma ordem embaralhada do Chefe de Mina")

	return true
