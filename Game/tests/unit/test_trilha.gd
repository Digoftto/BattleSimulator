class_name TestTrilha
extends RefCounted
## TestTrilha (F-001, Etapa 4)
##
## Migrado de bootstrap.gd:_validate_trilha() (Sprint 30). Mesmo cenário
## original (geração de Chefes e Acampamentos com os parâmetros oficiais
## de PvE.md) — utilizando exclusivamente Trilha (lógica pura).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.
## Prints sem "esperado" explícito (ex.: total de Acampamentos gerados)
## permanecem apenas informativos, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Trilha] Validando geração de Chefes e Acampamentos (dados reais de PvE.md)...")

	var trilha := Trilha.new()

	print("  Total de Fases: %d (esperado: 9000)" % trilha.total_fases())
	ctx.check(trilha.total_fases() == 9000, "Total de Fases deve ser 9000 (obtido: %d)" % trilha.total_fases())

	print("  Total de Acampamentos gerados: %d" % trilha.acampamento_positions.size())

	print("  Tipo da Fase 1000: '%s' (esperado: regional)" % trilha.chefe_type(1000))
	ctx.check(trilha.chefe_type(1000) == "regional", "Fase 1000 deve ser Chefe Regional (obtido: '%s')" % trilha.chefe_type(1000))

	print("  Tipo da Fase 100: '%s' (esperado: normal)" % trilha.chefe_type(100))
	ctx.check(trilha.chefe_type(100) == "normal", "Fase 100 deve ser Chefe Normal (obtido: '%s')" % trilha.chefe_type(100))

	print("  Tipo da Fase 150: '%s' (esperado: '' — Fase comum)" % trilha.chefe_type(150))
	ctx.check(trilha.chefe_type(150) == "", "Fase 150 deve ser Fase comum (obtido: '%s')" % trilha.chefe_type(150))

	var regional_positions: Array[int] = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]
	var all_regional_are_camps: bool = true
	for position: int in regional_positions:
		if not trilha.is_acampamento(position):
			all_regional_are_camps = false
	print("  Todos os 9 Chefes Regionais são Acampamento? %s (esperado: true)" % str(all_regional_are_camps))
	ctx.check(all_regional_are_camps == true, "Todos os 9 Chefes Regionais devem ser Acampamento")

	print("  Fase 100 é Acampamento? %s (esperado: false — coincide com Chefe Normal, foi deslocada)" % str(trilha.is_acampamento(100)))
	ctx.check(trilha.is_acampamento(100) == false, "Fase 100 não deve ser Acampamento (deslocada)")

	print("  Fase 101 é Acampamento? %s (esperado: true — deslocamento de +1)" % str(trilha.is_acampamento(101)))
	ctx.check(trilha.is_acampamento(101) == true, "Fase 101 deve ser Acampamento (deslocamento de +1)")

	print("  Fase 125 é Acampamento? %s (esperado: false)" % str(trilha.is_acampamento(125)))
	ctx.check(trilha.is_acampamento(125) == false, "Fase 125 não deve ser Acampamento")

	print("  Fase 126 é Acampamento? %s (esperado: true — prova o reinício da contagem a partir de 101, não de 100)" % str(trilha.is_acampamento(126)))
	ctx.check(trilha.is_acampamento(126) == true, "Fase 126 deve ser Acampamento (contagem reinicia a partir de 101)")

	var violation_found: bool = false
	for position: int in trilha.acampamento_positions:
		if trilha.is_chefe_normal(position) and not trilha.is_chefe_regional(position):
			violation_found = true
	print("  Algum Acampamento coincide com Chefe Normal (fora dos Regionais)? %s (esperado: false)" % str(violation_found))
	ctx.check(violation_found == false, "Nenhum Acampamento deve coincidir com Chefe Normal fora dos Regionais")

	return true
