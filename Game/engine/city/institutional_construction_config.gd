class_name InstitutionalConstructionConfig
extends RefCounted
## InstitutionalConstructionConfig
##
## Valores de "b" e "x" ATUALMENTE VIGENTES da Fórmula Geral de
## Construções (GeneralConstructionFormula), para Capital, Centro de
## Comando, Academia e Núcleo de Energia.
##
## Espelha exatamente `BALANCING_SIMULATION.md`, Simulação 3 — seção
## marcada como "✅ VALORES VIGENTES" naquele documento. Múltiplas
## simulações podem calcular outros pares de b/x ao longo do tempo,
## mas só o par marcado como vigente lá deve estar aqui. Sempre que o
## dono do projeto marcar uma nova simulação como vigente, este arquivo
## precisa ser atualizado para os mesmos valores — nunca deixar código
## e documentação divergirem sobre qual é o par válido.

enum Building { CAPITAL, CENTRO_DE_COMANDO, ACADEMIA, NUCLEO_DE_ENERGIA }


static func b(_building: Building) -> float:
	# As 4 construções usam b=50 atualmente (BALANCING_SIMULATION.md, Simulação 3).
	return 50.0


static func x(building: Building) -> float:
	match building:
		Building.CAPITAL:
			return 300.0
		Building.CENTRO_DE_COMANDO:
			return 225.0
		Building.ACADEMIA:
			return 460.0
		Building.NUCLEO_DE_ENERGIA:
			return 530.0
	return 0.0
