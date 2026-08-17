class_name CombatState
extends RefCounted
## CombatState
##
## Estado runtime completo de uma batalha (COMBAT_RULES.md, "Combat State
## / Battle Runtime Layer"). Contém apenas dados estruturais — nenhuma
## lógica de turno.
##
## Não armazena Buffs, Debuffs, Cooldowns ou Duração de efeitos — esses
## campos serão adicionados apenas quando Habilidades forem implementadas
## (ponto de extensão, não implementado nesta Sprint).

var units: Array[CombatUnit] = []
var commander_a: CommanderResource
var commander_b: CommanderResource

## Campo de Batalha sorteado. Apenas identificação — seus Efeitos não são
## aplicados nesta Sprint (ver BattlefieldResource/Battlefield, Sprint 11).
var battlefield: BattlefieldResource

## RNG próprio desta batalha — nunca o global (randi()/randf()), que
## não é seguro pra chamar de várias threads ao mesmo tempo. Toda
## aleatoriedade DENTRO de uma batalha (sorteio de Campo de Batalha,
## alvo do Silêncio, etc.) deve usar este RNG, nunca o global — assim
## várias batalhas conseguem rodar em paralelo de verdade (WorkerThreadPool),
## cada uma com sua própria sequência determinística e independente.
## Sem seed explícita (randomize() no _init), a menos que quem chamar
## precise de reprodutibilidade (testes, simulação em massa com seed).
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()

## Modo de Jogo desta batalha ("pve" | "pvp" | "mines") — usado pela
## Doutrina do Comandante pra checar Restrições/Requisitos de domínio
## "game_mode" (COMMANDER_RESTRICTIONS.md/COMMANDER_REQUIREMENTS.md).
var game_mode: String = "pve"

var turn: int = 1
var eliminated_units: Array[CombatUnit] = []

var is_finished: bool = false
## Lado vencedor (0 ou 1), ou -1 em caso de empate.
var winner_side: int = -1
## "eliminacao_total" | "eliminacao_simultanea" | "limite_de_turnos"
var end_reason: String = ""

## Registro textual estrutural dos eventos da batalha (dado, não lógica),
## populado por CombatEngine para permitir validação/depuração externa
## sem que Bootstrap precise acessar o funcionamento interno do motor.
var battle_log: Array[String] = []

## Ligado por padrão (comportamento igual ao de sempre) — desligável
## pra medir o custo real de gerar o Log de Batalha (formatação de
## texto a cada evento) em simulação em massa (Minas, geração de
## inimigos), onde ninguém lê essas linhas. Nunca afeta o resultado do
## combate em si, só o registro em texto.
var enable_battle_log: bool = true

## Barramento de eventos desta batalha (Sprint 16). Cada CombatState
## possui sua própria instância — nunca um Autoload/Singleton global.
var event_bus: CombatEventBus = CombatEventBus.new()

## Fachada do Runtime de Efeitos desta batalha (Sprint 20) — coordena
## AbilityRuntime e UnitTraitRuntime. CombatEngine conhece apenas esta
## referência, nunca os Runtimes especializados diretamente.
var effect_runtime: EffectRuntime


## Retorna as unidades de um lado. Se alive_only, retorna apenas as vivas.
func units_of_side(side: int, alive_only: bool = true) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for unit: CombatUnit in units:
		if unit.side == side and (not alive_only or unit.is_alive):
			result.append(unit)
	return result


## Retorna a unidade viva de um lado ocupando a posição informada, ou null.
func unit_at(side: int, position: int) -> CombatUnit:
	for unit: CombatUnit in units_of_side(side, true):
		if unit.position == position:
			return unit
	return null
