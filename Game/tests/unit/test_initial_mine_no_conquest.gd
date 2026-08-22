class_name TestInitialMineNoConquest
extends RefCounted
## TestInitialMineNoConquest (F-001, Etapa 10)
##
## Migrado de bootstrap.gd:_validate_initial_mine_no_conquest(). Mesmo
## cenário original — validação FUNCIONAL da Mina Inicial (MINES.md,
## "Mina Inicial (Bootstrap)"): já nasce conquistada de verdade, sem
## exigir combate. Usa um Kingdom.new() local — confirmado sem nenhuma
## referência a KingdomState/WorldDatabase/ExpeditionRuntime/GameRuntime/
## WorldBootstrap, direta ou transitiva.
##
## Resolução de duplicata (Etapa 10, auditoria READ-ONLY do Stage 9):
## _validate_kingdom_state_creates_initial_mines() verificava exatamente
## o mesmo fato (3 Minas Iniciais, todas conquistadas) — comparação
## direta dos dois corpos confirmou zero comportamento distinto entre
## elas, apenas texto de cabeçalho e estilo de laço (.all() com lambda vs.
## laço manual) diferentes. Esta validação foi escolhida como a canônica
## por estar explicitamente ancorada ao nome e à regra de MINES.md
## ("Mina Inicial (Bootstrap)") no próprio comentário de documentação,
## em vez de descrita apenas como cobertura incidental de bug relatado.
## _validate_kingdom_state_creates_initial_mines() foi removida de
## bootstrap.gd nesta mesma etapa — confirmado por busca repo-wide que
## não tinha nenhum outro chamador além do seu único call site em
## _ready().
##
## O teste original já tinha "(esperado: X)" explícito — convertido
## abaixo em asserção real, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando Mina Inicial (não exige conquista, MINES.md)...")

	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()

	var all_conquered: bool = true
	for mina: Mina in kingdom.initial_mines:
		if not mina.conquered:
			all_conquered = false

	print("  As 3 Minas Iniciais já nascem conquistadas, sem combate nenhum? %s (esperado: true)" % str(
		all_conquered and kingdom.initial_mines.size() == 3
	))
	ctx.check(
		all_conquered and kingdom.initial_mines.size() == 3,
		"As 3 Minas Iniciais devem nascer já conquistadas, sem exigir combate (MINES.md)"
	)

	return true
