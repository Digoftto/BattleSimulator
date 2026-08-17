class_name MinaPlacementGenerator
extends RefCounted
## MinaPlacementGenerator
##
## Gera as posições das 5 Minas Regionais de uma Trilha (MINES.md: 2 na
## Região I, 1 na Região II, 2 na Região III). Determinístico por
## semente — mesma seed sempre produz as mesmas posições, mas cada
## jogador tem a sua própria (MINES.md, "Determinação Procedural: as
## posições exatas das minas no mapa são geradas proceduralmente para
## cada jogador... distribuição geográfica própria").
##
## Regra adicional (decisão do jogador, não estava na SSOT original):
## uma das 2 Minas da Região III é sempre fixa na Fase 9000 — a última
## Fase da Trilha, ao lado do Chefe Regional final. A outra é sorteada
## livremente dentro da Região III.
##
## As posições nunca coincidem com uma Fase que já seja Chefe ou
## Acampamento (interpretação própria, para não sobrepor duas
## encontros diferentes na mesma Fase — a SSOT não define isso
## explicitamente).
##
## A Mina Inicial (1 por tipo de recurso, sem Fase) NÃO é gerada aqui —
## pertence à Cidade/Reino desde o início da conta (ver Mina.gd e
## Kingdom.create_initial_mines()).

const MINES_PER_REGION: Dictionary = {1: 2, 2: 1, 3: 2}
const FIXED_MINE_FASE: int = 9000  # sempre na Região III
const MAX_PLACEMENT_ATTEMPTS: int = 200


## Gera as 5 Minas Regionais de uma Trilha/Território, para a Facção
## informada. "trilha" é usada só para consultar quais Fases já são
## Chefe/Acampamento (nunca modificada).
static func generate(faction: String, trilha: Trilha, seed_value: int) -> Array[Mina]:
	seed(seed_value)

	var mines: Array[Mina] = []
	var used_fases: Array[int] = []

	for region: int in MINES_PER_REGION.keys():
		var count: int = MINES_PER_REGION[region]
		var bounds: Array[int] = _region_bounds(region)

		for i in range(count):
			var fase: int
			if region == 3 and i == 0:
				fase = FIXED_MINE_FASE
			else:
				fase = _pick_free_fase(bounds[0], bounds[1], used_fases, trilha)

			used_fases.append(fase)
			var mina := Mina.new(fase, faction)
			mina.region = region
			mines.append(mina)

	return mines


static func _region_bounds(region: int) -> Array[int]:
	match region:
		1:
			return [1, 3000]
		2:
			return [3001, 6000]
		_:
			return [6001, 9000]


## Sorteia uma Fase dentro do intervalo que ainda não está em uso e que
## não coincide com Chefe/Acampamento. Cai para a primeira Fase livre
## do intervalo em caso de esgotar as tentativas (nunca deveria
## acontecer dado o tamanho dos intervalos frente a 2-5 Minas).
static func _pick_free_fase(min_fase: int, max_fase: int, used_fases: Array[int], trilha: Trilha) -> int:
	var attempts: int = 0
	while attempts < MAX_PLACEMENT_ATTEMPTS:
		var candidate: int = min_fase + (randi() % (max_fase - min_fase + 1))
		if _is_valid_fase(candidate, used_fases, trilha):
			return candidate
		attempts += 1

	for fase in range(min_fase, max_fase + 1):
		if _is_valid_fase(fase, used_fases, trilha):
			return fase

	return min_fase


static func _is_valid_fase(fase: int, used_fases: Array[int], trilha: Trilha) -> bool:
	if fase in used_fases:
		return false
	if trilha.is_acampamento(fase):
		return false
	if trilha.chefe_type(fase) != "":
		return false
	return true
