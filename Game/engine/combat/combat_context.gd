class_name CombatContext
extends RefCounted
## CombatContext
##
## Contexto entregue aos ouvintes de um evento de combate (CombatEventBus).
## Contém apenas dados — nenhuma lógica de jogo. Nem todo campo é
## relevante para todo evento; cada evento popula somente os campos
## aplicáveis (ver pontos de emissão em CombatEngine).

var state: CombatState
var turn: int = 0

var attacker: CombatUnit
var target: CombatUnit

var side: int = -1
var position: int = -1

## Ação selecionada na Fase de Seleção (ver CombatEngine._selection_phase),
## relevante para o evento ACTION_SELECTED.
var action: Dictionary = {}

var damage_dealt: int = 0
var damage_absorbed_by_shield: int = 0
var damage_applied_to_hp: int = 0

## Valor de Ataque provisório calculado pelo CombatEngine antes de
## publicar BEFORE_ATTACK. Habilidades Modificadoras (ex: Investida)
## podem alterar este valor; o CombatEngine lê o valor final de volta do
## contexto antes de calcular o dano — nunca recalcula por conta própria
## (convenção definida na Sprint 19, usada pela primeira vez na Sprint 21).
var attack_value: float = 0.0

var heal_amount: int = 0

var battlefield: BattlefieldResource
