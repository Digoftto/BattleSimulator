class_name TestCardProgression
extends RefCounted
## TestCardProgression (F-001, Etapa 4)
##
## Migrado de bootstrap.gd:_validate_card_progression() (Sprint 3). Mesmo
## cenário original (progride uma carta real do catálogo, "Legionário
## Imperial", do Tier I ao Tier V) — utilizando exclusivamente
## CardProgression (lógica pura) e o catálogo somente-leitura de
## GameDatabase (carregado 1x pelo Autoload, nunca mutado por este
## teste).
##
## O teste original não tinha "(esperado: X)" explícito por passo — só
## imprimia ATK/HP/ESC de cada Tier para leitura humana. As únicas
## expectativas já implícitas no próprio controle de fluxo original são
## preservadas como asserções reais, sem inventar nenhuma regra nova:
## (1) a carta de teste deve existir no catálogo (o original tinha um
## push_warning + return antecipado caso contrário); (2) advance_tier()
## avança exatamente 1 Tier por chamada, já assumido pelo laço original
## ("while current.tier < 5") para garantir que ele termina.
##
## _print_progression_step() é cópia do helper de mesmo nome em
## bootstrap.gd — único chamador original confirmado antes da migração,
## removido de lá junto com a validação.

static func run(ctx: TestRunner.Context) -> bool:
	var base_card: CardResource = null
	for card: CardResource in GameDatabase.cards:
		if card.card_name == "Legionário Imperial":
			base_card = card
			break

	ctx.check(base_card != null, "Carta de validação da Progressão ('Legionário Imperial') deve existir no GameDatabase")
	if base_card == null:
		return true

	print("[CardProgression] Validando progressão de '%s'..." % base_card.card_name)

	var current: CardResource = base_card
	_print_progression_step(current)
	ctx.check(current.tier == 1, "Carta base deve começar no Tier 1 (obtido: %d)" % current.tier)

	var previous_tier: int = current.tier
	while current.tier < 5:
		current = CardProgression.advance_tier(current)
		_print_progression_step(current)
		ctx.check(current.tier == previous_tier + 1, "advance_tier() deve avançar exatamente 1 Tier por chamada (de %d para %d, obtido: %d)" % [previous_tier, previous_tier + 1, current.tier])
		previous_tier = current.tier

	ctx.check(current.tier == 5, "Progressão completa deve terminar no Tier 5 (obtido: %d)" % current.tier)

	return true


static func _print_progression_step(card: CardResource) -> void:
	var ability: String = CardProgression.unlocked_ability_name(card)
	var ability_text: String = ""
	if ability != "":
		ability_text = " | Habilidade desbloqueada (dado de catálogo): %s" % ability

	print("[CardProgression] Tier %d | ATK: %d HP: %d ESC: %d%s" % [
		card.tier, card.atk, card.hp, card.esc, ability_text
	])
