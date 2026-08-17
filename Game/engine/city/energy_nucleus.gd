class_name EnergyNucleus
extends RefCounted
## EnergyNucleus
##
## Lógica pura do Núcleo de Energia (ENERGY_NUCLEUS.md) — fonte única de
## verdade da Energia Base (Capacidade Logística) e do tempo de
## recuperação de energia (Eficiência Logística) de um Reino, por nível
## do Núcleo.
##
## A fórmula em prosa do documento é a SSOT; a "Progressão Resumida" do
## documento é apenas a representação tabulada dos resultados desta fórmula.
##
## Não implementa Cidade (CITY.md, gatilho de evolução do Núcleo),
## Exército (ENERGY.md consome este valor como uma das 3 fontes de Energia
## Total), Comandantes ou Combate.

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 60

const BASE_ENERGY: int = 40
const BASE_RECOVERY_SECONDS: int = 450  # 7 minutos e 30 segundos


## Retorna a Energia Base (Capacidade Logística) de um Reino em um dado
## nível do Núcleo: valor inicial de 40, +1 a cada cinco níveis completos.
static func energia_base(level: int) -> int:
	_assert_valid_level(level)
	return BASE_ENERGY + int(level / 5.0)


## Retorna o tempo de recuperação (em segundos) de 1 ponto de energia em
## um dado nível do Núcleo (Eficiência Logística), aplicando as reduções
## progressivas por nível definidas no documento:
## níveis 2-10: -4s/nível; níveis 11-30: -3s/nível; níveis 31-60: -2s/nível.
static func recovery_seconds(level: int) -> int:
	_assert_valid_level(level)

	var steps_2_10: int = clampi(mini(level, 10) - 1, 0, 9)
	var steps_11_30: int = clampi(mini(level, 30) - 10, 0, 20)
	var steps_31_60: int = clampi(mini(level, 60) - 30, 0, 30)

	var reduction: int = (steps_2_10 * 4) + (steps_11_30 * 3) + (steps_31_60 * 2)
	return BASE_RECOVERY_SECONDS - reduction


## Formata uma duração em segundos no padrão "XmYYs" utilizado pelo documento.
static func format_seconds(total_seconds: int) -> String:
	@warning_ignore("integer_division")  # Divisão inteira intencional: minutos truncados.
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%dm%02ds" % [minutes, seconds]


static func _assert_valid_level(level: int) -> void:
	assert(level >= MIN_LEVEL and level <= MAX_LEVEL,
		"EnergyNucleus: nível fora do intervalo válido (1-60): %d." % level)
