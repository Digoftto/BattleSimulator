class_name TestEnemyCompositionHasNoDuplicateNames
extends RefCounted
## TestEnemyCompositionHasNoDuplicateNames (F-001, Etapa 18)
##
## Migrado de bootstrap.gd:_validate_enemy_composition_has_no_duplicate_names().
## Mesmo cenário original — Unicidade de Composição (ARMY.md) no lado do
## INIMIGO: EnemyArmyGenerator não pode sortear duas cartas com o mesmo
## Nome na mesma Entrada. Usa SeasonConfig.new() e os catálogos estáticos
## de GameDatabase — sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou transitiva.
##
## RNG: EnemyArmyGenerator.generate() usa randi() global internamente
## quando nenhum RandomNumberGenerator é fornecido (F-028: parâmetro
## "rng" opcional adicionado à assinatura, mas deliberadamente omitido
## aqui — sem nenhuma alteração de comportamento deste teste). O teste
## tolera essa aleatoriedade real gerando 30 vezes e checando apenas a
## propriedade invariável (nenhum Nome repetido dentro de cada Entrada),
## nunca um resultado específico — o mesmo padrão de tolerância a RNG já
## usado em test_recruitment.gd (30 tentativas para o sorteio de 50%).
##
## O teste original já tinha "(esperado: X)" explícito — convertido
## abaixo em asserção real, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Exército] Validando Unicidade de Composição no gerador de inimigos (bug relatado)...")

	var config := SeasonConfig.new()
	var all_unique: bool = true
	# Gera várias vezes — sorteio é aleatório, precisa confirmar em
	# mais de uma tentativa que nunca repete, não só por sorte 1 vez.
	for i in range(30):
		var entry: EnemyArmyEntry = EnemyArmyGenerator.generate(
			EnemyArmyEntry.Category.NORMAL, "Império", 1, GameDatabase.cards, config,
			GameDatabase.commander_restrictions, GameDatabase.commander_requirements, GameDatabase.commander_targets,
			GameDatabase.commander_effects, GameDatabase.commander_values, "teste_unicidade", i
		)
		var names: Array[String] = []
		for card: CardResource in entry.cards:
			if names.has(card.card_name):
				all_unique = false
			names.append(card.card_name)
	print("  30 Exércitos inimigos gerados, nenhum com Nome de Carta repetido? %s (esperado: true)" % str(all_unique))
	ctx.check(all_unique, "Nenhum dos 30 Exércitos inimigos gerados deve ter Nome de Carta repetido")

	return true
