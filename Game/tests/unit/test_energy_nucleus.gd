class_name TestEnergyNucleus
extends RefCounted
## TestEnergyNucleus (F-001, Etapa 2)
##
## Migrado de bootstrap.gd:_validate_energy_nucleus() (Sprint 8). Mesma
## Progressão Resumida (marcos oficiais de ENERGY_NUCLEUS.md) e o mesmo
## "Exemplo de interface (Nível 27)" do teste original — 100% lógica
## pura (EnergyNucleus não depende de GameDatabase, Autoloads ou
## qualquer estado global).
##
## Nota de migração: o teste original não tinha "(esperado: X)"
## explícito. Os valores abaixo foram tornados explícitos a partir de
## uma execução real e observada de bootstrap.gd nesta mesma sessão
## (antes desta migração) — nenhum valor foi inventado.

const MILESTONE_LEVELS: Array[int] = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]

## {nível: [Energia Base esperada, Recuperação esperada em segundos]},
## observado em execução real de bootstrap.gd antes da migração.
const EXPECTED_MILESTONES: Dictionary = {
	1: [40, 450],
	5: [41, 434],
	10: [42, 414],
	15: [43, 399],
	20: [44, 384],
	25: [45, 369],
	30: [46, 354],
	35: [47, 344],
	40: [48, 334],
	45: [49, 324],
	50: [50, 314],
	55: [51, 304],
	60: [52, 294],
}


static func run(ctx: TestRunner.Context) -> bool:
	print("[EnergyNucleus] Progressão Resumida (marcos oficiais):")
	for level: int in MILESTONE_LEVELS:
		var base: int = EnergyNucleus.energia_base(level)
		var recovery: int = EnergyNucleus.recovery_seconds(level)
		print("  Nível %2d | Energia Base: %d | Recuperação: %s" % [level, base, EnergyNucleus.format_seconds(recovery)])

		var expected: Array = EXPECTED_MILESTONES[level]
		ctx.check(base == expected[0], "Nível %d: Energia Base deve ser %d (obtido: %d)" % [level, expected[0], base])
		ctx.check(recovery == expected[1], "Nível %d: Recuperação deve ser %ds (obtido: %ds)" % [level, expected[1], recovery])

	print("[EnergyNucleus] Exemplo de interface (Nível 27):")
	var example_base: int = EnergyNucleus.energia_base(27)
	var example_recovery: int = EnergyNucleus.recovery_seconds(27)
	var next_level_recovery: int = EnergyNucleus.recovery_seconds(28)
	print("  Capacidade Logística: %d" % example_base)
	print("  Recuperação: 1 ponto a cada %s" % EnergyNucleus.format_seconds(example_recovery))
	print("  Próximo nível: Recuperação -%ds" % (example_recovery - next_level_recovery))

	ctx.check(example_base == 45, "Nível 27: Energia Base deve ser 45 (obtido: %d)" % example_base)
	ctx.check(example_recovery == 363, "Nível 27: Recuperação deve ser 363s (obtido: %ds)" % example_recovery)
	ctx.check(example_recovery - next_level_recovery == 3, "Nível 27 -> 28: Recuperação deve reduzir 3s (obtido: %ds)" % (example_recovery - next_level_recovery))

	return true
