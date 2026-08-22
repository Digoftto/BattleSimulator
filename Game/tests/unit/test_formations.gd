class_name TestFormations
extends RefCounted
## TestFormations (F-001, Etapa 3)
##
## Migrado de bootstrap.gd:_validate_formations() (Sprint 29). Mesmo
## cenário original (Exército com apenas a Formação "β" configurada) —
## utilizando exclusivamente Army (lógica pura, já provada pura na
## Etapa 2) e CampaignTestFixtures (reutilizado diretamente, sem cópia,
## mesmo motivo de TestSquad).
##
## Nota de migração: o teste original só tinha "(esperado: X)" explícito
## nos dois primeiros prints. Os dois seguintes ("cai para 'cards'
## padrão?" e "Campeão na posição 1?") já eram, na prática, a própria
## asserção sendo impressa como booleano — convertidos abaixo em
## ctx.check() sem mudar a condição verificada.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Formações] Validando prioridade e as cinco Formações...")

	var army: Army = CampaignTestFixtures.build_campaign_test_army({"β": 1})  # só "β" configurada

	print("  Prioridade padrão: %s (esperado: [α, β, γ, δ, ε])" % str(army.formation_priority))
	ctx.check(army.formation_priority == ["α", "β", "γ", "δ", "ε"], "Prioridade padrão deve ser [α, β, γ, δ, ε] (obtido: %s)" % str(army.formation_priority))

	var alpha: Array[CardResource] = army.get_formation("α")
	var beta: Array[CardResource] = army.get_formation("β")
	print("  Formação α não configurada -> cai para 'cards' padrão? %s" % str(alpha == army.cards))
	ctx.check(alpha == army.cards, "Formação 'α' não configurada deve cair para a disposição padrão ('cards')")

	print("  Formação β configurada -> Campeão na posição 1? %s" % str(beta[0].card_name == "Campeão"))
	ctx.check(beta[0].card_name == "Campeão", "Formação 'β' configurada deve ter o Campeão na Posição 1 (obtido: %s)" % beta[0].card_name)

	army.formation_priority = ["β", "α", "δ", "γ", "ε"]
	print("  Prioridade customizada aplicada: %s" % str(army.formation_priority))
	ctx.check(army.formation_priority == ["β", "α", "δ", "γ", "ε"], "Prioridade customizada deve persistir após a atribuição (obtido: %s)" % str(army.formation_priority))

	return true
