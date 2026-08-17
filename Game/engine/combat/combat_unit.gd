class_name CombatUnit
extends RefCounted
## CombatUnit
##
## Representa um pelotão dentro do Combat State (COMBAT_RULES.md). Dado
## runtime puro — toda a lógica de movimento, seleção de alvo e dano fica
## em CombatEngine/CombatBoard, nunca aqui.
##
## Não implementa Buffs, Debuffs, Cooldown, Duração ou qualquer efeito de
## Habilidade — apenas os campos estruturais documentados.

## Carta de origem (atributos base: ATK/HP/ESC/Classe/Facção).
var card: CardResource

## Lado ao qual pertence: 0 ou 1.
var side: int = 0

## Posição atual no tabuleiro (1-9).
var position: int = 0

var current_hp: int = 0
var current_esc: int = 0
var is_alive: bool = true

## Controle da Penalidade de Reorganização (COMBAT_RULES.md 5.2.2):
## true se este pelotão já disparou a penalidade de reorganização em algum
## momento da batalha (incluindo se já iniciou a batalha na posição 5).
var has_triggered_reorganization: bool = false

## true apenas durante o turno em que a Penalidade de Reorganização está
## em vigor para este pelotão (reiniciado a cada turno).
var is_reorganizing_this_turn: bool = false

## Controle do Bônus de Posição da Classe Barreira (+50% Escudo Base na
## Posição 1), aplicado uma única vez por batalha (COMBAT_RULES.md 6.2).
var barreira_position_bonus_applied: bool = false

## Turno até o qual este pelotão está silenciado (Silêncio, Tier V).
## -1 = nunca silenciado. Cada Runtime de Habilidade deve verificar este
## campo antes de agir — o CombatEventBus/CombatEngine permanecem
## agnósticos dessa regra (decisão registrada nas Sprints 16/17/19).
var silenced_until_turn: int = -1


func _init(p_card: CardResource, p_side: int, p_position: int) -> void:
	card = p_card
	side = p_side
	position = p_position
	current_hp = p_card.hp
	current_esc = p_card.esc
