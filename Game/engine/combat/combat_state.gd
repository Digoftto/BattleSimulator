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
var rng := RandomNumberGenerator.new()

## F-028: identificador único desta EXECUÇÃO de batalha — nunca
## derivado do RNG determinístico (senão duas execuções com a mesma
## seed teriam o mesmo battle_id, o que quebraria a distinção entre
## "simulação 1" e "simulação 2" de uma batalha idêntica). Combina um
## contador estático (único dentro do processo) com o relógio de alta
## resolução (Time.get_ticks_usec()) — suficiente para distinguir
## execuções sem exigir uma biblioteca de UUID.
static var _battle_id_counter: int = 0
var battle_id: String = ""

## F-028: seed efetivamente usada para o RNG desta batalha — sempre
## preenchida (mesmo quando ninguém forneceu uma explicitamente, para
## que uma batalha "aleatória" também possa ser inspecionada depois).
## -1 nunca aparece aqui: quando _init() não recebe seed explícita
## (p_seed_value < 0), uma seed própria é sorteada e registrada, nunca
## deixada em branco.
var seed_value: int = 0

## F-028: versão das regras de combate usadas nesta batalha — ver
## CombatEngine.RULES_VERSION (fonte única de verdade do valor atual).
## Nunca calculada aqui; apenas copiada no momento da criação, para
## que resultados de batalha permaneçam interpretáveis mesmo depois
## que RULES_VERSION mudar no futuro.
var rules_version: String = ""


## "p_seed_value" é opcional: se omitido (ou negativo), o comportamento
## é EXATAMENTE o de antes desta Sprint — uma seed aleatória verdadeira
## (randomize()), sem nenhuma mudança de resultado para quem já chamava
## CombatState.new() sem argumentos. Se fornecido (>= 0), o RNG desta
## batalha — e, por extensão, todo o combate que dele depender (sorteio
## de Campo de Batalha, Silêncio, etc.) — se torna reproduzível.
func _init(p_seed_value: int = -1) -> void:
	if p_seed_value >= 0:
		rng.seed = p_seed_value
	else:
		rng.randomize()
	seed_value = rng.seed

	CombatState._battle_id_counter += 1
	battle_id = "battle_%d_%d" % [Time.get_ticks_usec(), CombatState._battle_id_counter]

	rules_version = CombatEngine.RULES_VERSION

## Modo de Jogo desta batalha ("pve" | "pvp" | "mines") — usado pela
## Doutrina do Comandante pra checar Restrições/Requisitos de domínio
## "game_mode" (COMMANDER_RESTRICTIONS.md/COMMANDER_REQUIREMENTS.md).
var game_mode: String = "pve"

var turn: int = 1
var eliminated_units: Array[CombatUnit] = []

## F-035 (AFFINITY.md/AffinityRuntime): Pontos e Nível ativo de Afinidade
## por lado e Facção, recalculados e congelados a cada snapshot de turno
## (Inicialização + Environment Update de cada turno, COMBAT_RULES.md
## 2.1/3.2). Estrutura: {side(int): {faction(String): points/level(int)}}.
## Uma Facção ausente do Dictionary de um lado equivale a 0 pontos/Nível 0
## (nunca esteve ou não está mais presente naquele lado).
var affinity_points: Dictionary = {}
var affinity_levels: Dictionary = {}

## F-035 (AFFINITY.md, Afinidade II dos Mortos-Vivos — "primeira morte da
## Facção no turno concede +5%% ATK Base até o início do próximo turno").
## "pending" é marcado por CombatEngine._death_resolution_phase() no
## instante em que a primeira morte da Facção naquele lado ocorre no
## turno corrente; no snapshot do turno SEGUINTE (AffinityRuntime.
## snapshot_turn), "pending" vira "active" (válido durante todo aquele
## turno) e é reiniciado para false. Isso é o único ponto do fluxo em
## que uma morte deste turno pode influenciar o ATK — mortes só se
## tornam "oficiais" na Fase de Resolução das Mortes (7), que já ocorre
## DEPOIS da Fase de Execução (6) do mesmo turno; logo, um bônus
## originado de uma morte jamais poderia afetar ataques do próprio
## turno em que ela ocorreu, apenas o turno seguinte — consistente com
## a regra geral de recálculo de Afinidade "entre turnos" (AFFINITY.md).
var undead_affinity_death_bonus_pending: Dictionary = {0: false, 1: false}
var undead_affinity_death_bonus_active: Dictionary = {0: false, 1: false}

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
