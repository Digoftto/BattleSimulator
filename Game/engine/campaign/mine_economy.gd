class_name MineEconomy
extends RefCounted
## MineEconomy (MINES.md + FORMULAS.md, "Produção das Minas" e "Custos em PG das Minas")
##
## Lógica pura: produção base por nível/região e custo de evolução
## estrutural em Pontos de Geração (PG). Não decide Eficiência da
## Guarnição (isso depende do resultado do cálculo em lote das 9!
## combinações — motor ainda não implementado, ver Region.
##
## NÃO implementa: o Ciclo de Mineração, a simulação das 362.880
## combinações, a Guarnição da Mina, nem a "formação de referência" —
## todos pendentes de decisão de design antes de codar.

enum Region { MINA_INICIAL, REGIAO_1, REGIAO_2, REGIAO_3 }


## Recurso de Construção produzido pela Facção (MINES.md, "Estrutura
## Permanente das Trilhas" — associação fixa, permanente e imutável).
## Chaves usadas em Kingdom.raw_resources: "ferro_negro",
## "essencia_vital", "cristais_arcanos".
static func resource_for_faction(faction: String) -> String:
	match faction:
		"Império":
			return "ferro_negro"
		"Natureza":
			return "essencia_vital"
		"Mortos-Vivos":
			return "cristais_arcanos"
	return ""


## Nível do Depósito responsável por armazenar "resource" (DEPOSITS.md:
## Fundição/Ferro Negro, Câmara Arcana/Cristais Arcanos, Santuário
## Vital/Essência Vital).
## Nível do Depósito responsável por armazenar "resource" (DEPOSITS.md:
## construção única — todos os 3 recursos compartilham o mesmo nível).
## O parâmetro "resource" é mantido na assinatura por clareza de
## chamada (deixa explícito qual recurso está sendo verificado), mas
## não influencia o resultado — sempre retorna kingdom.deposito_level.
static func deposit_level_for_resource(kingdom: Kingdom, resource: String) -> int:
	match resource:
		"ferro_negro", "cristais_arcanos", "essencia_vital":
			return kingdom.deposito_level
	return 0


## Produção Base por hora de "mina", já resolvendo Mina Inicial vs.
## Regional a partir dos próprios dados da Mina (region == 0 = Inicial).
static func base_production_for_mina(mina: Mina) -> int:
	if mina.is_initial_mine():
		return base_production_per_hour(Region.MINA_INICIAL, mina.structure_level)
	var region: Region = [Region.REGIAO_1, Region.REGIAO_2, Region.REGIAO_3][mina.region - 1]
	return base_production_per_hour(region, mina.structure_level)
## (FORMULAS.md, "Produção das Minas"):
## - Mina Inicial: progressão geométrica P(n) = 2^(n-1), nível máximo 4
##   (MINES.md, "Mina Inicial").
## - Minas Regionais: progressão aritmética P(n) = n × P(1), onde P(1)
##   é 5/10/20 conforme a Região.
static func base_production_per_hour(region: Region, level: int) -> int:
	assert(level >= 1, "MineEconomy: nível deve ser >= 1.")
	match region:
		Region.MINA_INICIAL:
			assert(level <= 4, "MineEconomy: Mina Inicial tem nível máximo 4 (MINES.md).")
			return int(pow(2, level - 1))
		Region.REGIAO_1:
			return level * 5
		Region.REGIAO_2:
			return level * 10
		Region.REGIAO_3:
			return level * 20
	return 0


## Produção efetiva por hora, já aplicando a Eficiência da Guarnição
## (MINES.md, "Produção Final"): Produção Base × Eficiência. Eficiência
## é 1.0 (Vitória), 0.5 (Empate) ou 0.2 (Derrota) — fornecida pelo
## motor de simulação (ainda não implementado), nunca calculada aqui.
## Arredondamento: para baixo (nenhuma fração de recurso é gerada) —
## assunção técnica, não uma regra documentada; sinalizar se precisar
## de outro comportamento.
static func hourly_production(base_production: int, efficiency: float) -> int:
	return int(floor(base_production * efficiency))


## Custo base em PG por nível, antes do escalonamento por bloco de 10
## níveis (FORMULAS.md, "Custos em Pontos de Geração (PG) das Minas").
static func _base_cost_pg(region: Region) -> int:
	match region:
		Region.MINA_INICIAL:
			return 1
		Region.REGIAO_1:
			return 1
		Region.REGIAO_2:
			return 2
		Region.REGIAO_3:
			return 3
	return 0


## Custo em PG para evoluir a estrutura da mina até o nível de destino
## "target_level", já com o escalonamento de ×1,5 a cada bloco de 10
## níveis, sempre arredondado para cima (FORMULAS.md):
## Custo(n) = ceil(Custo Base × 1,5^floor((n-1)/10))
static func upgrade_cost_pg(region: Region, target_level: int) -> int:
	assert(target_level >= 1, "MineEconomy: nível de destino deve ser >= 1.")
	var base_cost: int = _base_cost_pg(region)
	@warning_ignore("integer_division")  # Divisão inteira intencional: implementa floor((n-1)/10).
	var block: int = (target_level - 1) / 10
	var multiplier: float = pow(1.5, block)
	return int(ceil(base_cost * multiplier))
