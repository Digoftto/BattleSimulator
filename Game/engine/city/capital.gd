class_name Capital
extends RefCounted
## Capital (CAPITAL.md)
##
## Lógica pura do papel da Capital como limitador institucional da
## Cidade: nenhuma construção urbana institucional (Depósitos, Centro
## de Comando, Núcleo de Energia, Academia — CAPITAL.md, "Construções
## Dependentes") pode possuir nível superior ao da Capital.
##
## NÃO implementa o custo de evolução da própria Capital. A Fórmula
## Geral de Construções existe (FORMULAS.md: C(n) = CEG × (b + n² +
## xn)), mas os parâmetros "b" e "x" específicos da Capital são
## "definidos durante o balanceamento econômico" — ainda não calibrados
## em nenhum documento. Calcular esse custo aqui exigiria inventar
## valores que a documentação diz explicitamente ainda não existirem;
## quando forem calibrados, este método ganha um par (a evolução da
## própria Capital segue a mesma Fórmula Geral, só que sem o teto de
## nenhuma construção acima dela).


## True se uma construção urbana institucional pode evoluir do nível
## atual para o próximo, dado o nível atual da Capital (CAPITAL.md,
## "Sincronização de Progresso"): a evolução é bloqueada assim que a
## construção atinge o nível da Capital, e liberada de novo assim que
## a própria Capital evolui.
static func can_building_evolve(building_level: int, capital_level: int) -> bool:
	return building_level < capital_level
