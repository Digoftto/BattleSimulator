class_name SimulationConfig
extends RefCounted
## SimulationConfig (F-029)
##
## Configuração mínima de UMA rodada de simulação — só os campos que o
## §3 do F-029 pede e que nenhuma classe existente já cobre (SeasonConfig
## é sobre geração de Temporada, não sobre "como rodar esta série de
## batalhas"; BalanceSimulationConfig é específico do BalanceSimulator,
## sem seed_mode nem collect_events). Não é um objeto de geração de
## Exército — isso continua sendo trabalho de EnemyArmyGenerator/
## CommanderGenerator, referenciados a partir daqui só pelos parâmetros
## que BattleSimulationRunner precisa repassar a eles.

enum SeedMode {
	## seed da batalha N = base_seed_value + N (F-028, mesma convenção
	## já usada em BattleSimulationRunner.run_batch()) — cada batalha
	## reproduzível individualmente, e a série inteira reproduzível a
	## partir de uma única seed-base.
	SEQUENTIAL,
	## toda batalha da série usa a MESMA seed — só faz sentido quando os
	## dois lados também mudam a cada batalha (ex: Random vs Random),
	## para isolar "o que varia é só a composição sorteada, não o RNG
	## de combate" — uso avançado, não o padrão.
	FIXED,
}

var simulation_count: int = 100
var base_seed_value: int = 0
var seed_mode: SeedMode = SeedMode.SEQUENTIAL
var game_mode: String = "pve"
var collect_events: bool = false


## Seed efetiva da batalha de índice "i" (0-based) desta série, segundo
## "seed_mode" — única função que decide isso, para nunca duplicar essa
## lógica entre BattleSimulationRunner e os testes de determinismo.
func seed_for_battle(i: int) -> int:
	match seed_mode:
		SeedMode.FIXED:
			return base_seed_value
		_:
			return base_seed_value + i
