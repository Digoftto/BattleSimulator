class_name TestMinaPlacement
extends RefCounted
## TestMinaPlacement (F-001, Etapa 17)
##
## Migrado de bootstrap.gd:_validate_mina_placement(). Mesmo cenário
## original — geração de posição das Minas Regionais (5 por Trilha,
## distribuição 2/1/2 por Região, uma sempre na Fase 9000, sem coincidir
## com Chefe/Acampamento, determinístico pela seed) e as 3 Minas
## Iniciais do Reino (sem Fase). Usa Trilha.new()/Kingdom.new() locais —
## sem nenhuma referência a KingdomState/WorldDatabase/ExpeditionRuntime/
## GameRuntime/WorldBootstrap, direta ou transitiva. Nenhuma seed foi
## adicionada, nenhum código de produção foi alterado.
##
## RNG: MinaPlacementGenerator.generate() usa seed(seed_value) — a
## semente GLOBAL do processo (mina_placement_generator.gd), não uma
## RandomNumberGenerator local — característica CONHECIDA e já existente
## da produção, preservada exatamente como está (auditoria de Stage 17,
## achado de arquitetura: essa reseed global pode, em tese, afetar
## qualquer código que dependa de randi()/randf() globais não-seedados
## chamado depois dela no mesmo processo — não é alterada nem
## "corrigida" nesta migração). O determinismo do próprio resultado
## (seeds 4242 e 999) é o que este teste valida.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Minas] Validando geração de posição das Minas Regionais...")

	var trilha := Trilha.new("territorio-minas-teste")
	var mines: Array[Mina] = MinaPlacementGenerator.generate("Império", trilha, 4242)

	print("  Total de Minas Regionais geradas: %d (esperado: 5)" % mines.size())
	ctx.check(mines.size() == 5, "Total de Minas Regionais geradas deve ser 5 (obtido: %d)" % mines.size())

	var fases: Array[int] = []
	for mina: Mina in mines:
		fases.append(mina.adjacent_fase)
	var region_1_count: int = 0
	var region_2_count: int = 0
	var region_3_count: int = 0
	for fase: int in fases:
		var region: int = trilha.region_for_fase(fase)
		if region == 1: region_1_count += 1
		elif region == 2: region_2_count += 1
		else: region_3_count += 1
	print("  Distribuição -> Região I: %d, Região II: %d, Região III: %d (esperado: 2, 1, 2)" % [
		region_1_count, region_2_count, region_3_count
	])
	ctx.check(region_1_count == 2, "Região I deve ter 2 Minas Regionais (obtido: %d)" % region_1_count)
	ctx.check(region_2_count == 1, "Região II deve ter 1 Mina Regional (obtido: %d)" % region_2_count)
	ctx.check(region_3_count == 2, "Região III deve ter 2 Minas Regionais (obtido: %d)" % region_3_count)

	var has_fase_9000: bool = 9000 in fases
	print("  Uma das Minas está na Fase 9000? %s (esperado: true)" % str(has_fase_9000))
	ctx.check(has_fase_9000, "Uma das Minas Regionais deve estar na Fase 9000")

	var collision_found: bool = false
	for fase: int in fases:
		if fase == MinaPlacementGenerator.FIXED_MINE_FASE:
			continue  # exceção intencional e documentada: sempre ao lado do Chefe Regional final
		if trilha.is_acampamento(fase) or trilha.chefe_type(fase) != "":
			collision_found = true
	print("  Alguma das Minas sorteadas livremente coincide com Chefe/Acampamento? %s (esperado: false — a Fase 9000 fixa é exceção conhecida, não entra nesta checagem)" % str(collision_found))
	ctx.check(collision_found == false, "Nenhuma Mina sorteada livremente deve coincidir com Chefe/Acampamento (exceto a Fase 9000 fixa, já excluída da checagem)")

	# Determinismo: mesma seed -> mesmas posições.
	var mines_again: Array[Mina] = MinaPlacementGenerator.generate("Império", trilha, 4242)
	var same_positions: bool = true
	for i in range(mines.size()):
		if mines[i].adjacent_fase != mines_again[i].adjacent_fase:
			same_positions = false
	print("  Mesma seed gera as mesmas posições? %s (esperado: true)" % str(same_positions))
	ctx.check(same_positions, "A mesma seed deve gerar exatamente as mesmas posições de Mina")

	# Minas Iniciais do Reino.
	var kingdom := Kingdom.new()
	kingdom.create_initial_mines()
	print("  Minas Iniciais criadas: %d (esperado: 3)" % kingdom.initial_mines.size())
	ctx.check(kingdom.initial_mines.size() == 3, "Devem existir 3 Minas Iniciais (obtido: %d)" % kingdom.initial_mines.size())

	var all_without_fase: bool = true
	for mina: Mina in kingdom.initial_mines:
		if not mina.is_initial_mine():
			all_without_fase = false
	print("  Todas sem Fase associada (Mina Inicial)? %s (esperado: true)" % str(all_without_fase))
	ctx.check(all_without_fase, "Todas as Minas Iniciais devem estar sem Fase associada")

	# Geração via Kingdom, com cache (não regenera na segunda chamada).
	var generated_1: Array[Mina] = kingdom.generate_territory_mines("territorio-minas-teste", "Império", trilha, 999)
	var generated_2: Array[Mina] = kingdom.generate_territory_mines("territorio-minas-teste", "Império", trilha, 999)
	var same_list: bool = generated_1 == generated_2
	print("  Segunda chamada devolve a mesma lista (cache, não regenera)? %s (esperado: true)" % str(same_list))
	ctx.check(same_list, "A segunda chamada a generate_territory_mines() deve devolver a mesma lista (cache, sem regenerar)")

	return true
