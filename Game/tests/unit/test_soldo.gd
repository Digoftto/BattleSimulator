class_name TestSoldo
extends RefCounted
## TestSoldo (F-001, Etapa 1 — teste piloto)
##
## Migrado de bootstrap.gd:_validate_soldo() (linhas 1317-1345 na
## versão anterior à migração). Mesma lógica e os mesmos dois casos de
## referência do teste original (SOLDO.md, teto máximo Lorde-
## Comandante) — só a "borda" de relato mudou (print "esperado" ->
## TestRunner.Context.check()). Nenhuma regra de SOLDO.md foi
## reinterpretada.
##
## Nota de migração: o teste original só imprimia "válida"/"inválida"
## sem uma condição "(esperado: X)" explícita — diferente da maioria
## das outras validações do bootstrap.gd. O propósito documentado do
## teste (confirmar que essas composições de referência cabem no teto
## de Lorde-Comandante) foi tornado explícito abaixo como a asserção
## real: as duas composições sempre foram, de fato, válidas sob esse
## teto. Nenhum comportamento novo foi inventado — só tornado
## verificável.

const REFERENCE_COMPOSITIONS: Dictionary = {
	"2 Lendárias + 2 Épicas + 2 Raras + 3 Comuns": ["Lendária", "Lendária", "Épica", "Épica", "Rara", "Rara", "Comum", "Comum", "Comum"],
	"1 Lendária + 4 Épicas + 4 Raras": ["Lendária", "Épica", "Épica", "Épica", "Épica", "Rara", "Rara", "Rara", "Rara"],
}


static func run(ctx: TestRunner.Context) -> bool:
	print("[Soldo] Tetos de Soldo por Patente:")
	for patente: String in Soldo.CAP_BY_PATENTE:
		print("  %s: %d" % [patente, Soldo.cap_for_patente(patente)])

	print("[Soldo] Validando composições de referência (SOLDO.md, teto máximo Lorde-Comandante)...")
	var cap: int = Soldo.cap_for_patente("Lorde-Comandante")

	for label: String in REFERENCE_COMPOSITIONS:
		var cards: Array[CardResource] = _build_transient_cards_by_rarity(REFERENCE_COMPOSITIONS[label])
		var total: int = Soldo.total_for_composition(cards)
		var valid: bool = total <= cap
		print("  %s -> Soldo total: %d / %d (%s)" % [label, total, cap, "válida" if valid else "inválida"])
		ctx.check(valid, "%s deve ser válida sob o teto de Lorde-Comandante (%d/%d)" % [label, total, cap])

	return true


## Cria instâncias transitórias de CardResource apenas com Raridade
## definida, suficiente para o cálculo de Soldo (não persistidas no
## catálogo) — idêntico ao helper original do bootstrap.gd.
static func _build_transient_cards_by_rarity(rarities: Array) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for r: String in rarities:
		var card := CardResource.new()
		card.rarity = r
		cards.append(card)
	return cards
