class_name TestCommandCenterTrainingSlots
extends RefCounted
## TestCommandCenterTrainingSlots (F-001, Etapa 4)
##
## Migrado de bootstrap.gd:_validate_command_center_training_slots().
## Mesmo cenário original (Vagas de Treinamento por Nível, conforme
## COMMAND_CENTER_PROGRESS.md: 0 antes do Nível 3, 1 no desbloqueio, +1
## a cada 4 níveis depois) — utilizando exclusivamente
## CommandCenterProgress (lógica pura, tabela de consulta).
##
## O teste original já tinha "(esperado: X)" explícito por caso — cada
## um convertido abaixo em uma asserção real, sem reinterpretar a regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Centro de Comando] Validando Vagas de Treinamento por Nível...")

	var cases: Dictionary = {
		1: 0, 2: 0, 3: 1, 6: 1, 7: 2, 10: 2, 11: 3, 14: 3, 15: 4, 18: 4, 19: 5, 22: 5,
	}
	for level: int in cases:
		var expected: int = cases[level]
		var actual: int = CommandCenterProgress.training_slots(level)
		print("  Nível %d -> Vagas: %d (esperado: %d) %s" % [
			level, actual, expected, "OK" if actual == expected else "FALHOU"
		])
		ctx.check(actual == expected, "Nível %d deve ter %d Vagas de Treinamento (obtido: %d)" % [level, expected, actual])

	return true
