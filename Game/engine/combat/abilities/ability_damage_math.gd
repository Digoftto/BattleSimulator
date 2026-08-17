class_name AbilityDamageMath
extends RefCounted
## AbilityDamageMath
##
## Réplica mínima e isolada da regra estrutural de aplicação de dano
## (COMBAT_RULES.md 4.1: o Escudo absorve integralmente antes da Vida,
## sem penetração por padrão). Mantida separada de CombatEngine
## deliberadamente — a Sprint 24 proíbe modificar CombatEngine, e
## Runtimes de Habilidade que precisam aplicar dano fora do fluxo padrão
## de ataque (ex: um segundo golpe, dano em área) precisam desta mesma
## regra sem depender dos métodos internos do motor.
##
## Se esta regra mudar em COMBAT_RULES.md no futuro, as duas cópias
## (CombatEngine._apply_damage_amount e esta) devem ser atualizadas juntas.


static func apply(attack_value: float, target: CombatUnit) -> void:
	var damage: int = int(round(attack_value))

	if target.current_esc > 0:
		var absorbed: int = mini(damage, target.current_esc)
		target.current_esc -= absorbed
	else:
		target.current_hp = maxi(target.current_hp - damage, 0)
