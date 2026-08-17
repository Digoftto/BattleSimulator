class_name CommandCenterProgress
extends RefCounted
## CommandCenterProgress (COMMAND_CENTER_PROGRESS.md)
##
## Lógica pura de progressão do Centro de Comando: Vagas de
## Treinamento (concedidas diretamente pelo Nível, sem custo em PG) e
## Infraestrutura Administrativa (Cargos de Comando Ativo / Vagas da
## Reserva — potencial bruto por Nível, que precisa ser ativado em PG
## via CommandCenterResolver.activate_next() antes de virar Recurso
## Administrativo usável).

const TRAINING_UNLOCK_LEVEL: int = 3
const TRAINING_SLOTS_PER_MILESTONE: int = 4

## Nova Infraestrutura Administrativa gerada POR nível (não cumulativa
## ainda — ver infrastructure_at_level() para o total acumulado),
## [ativo, reserva] (COMMAND_CENTER_PROGRESS.md, "Distribuição Oficial
## de Infraestrutura Administrativa"). Nível 8 em diante repete o
## padrão do Nível 8: +2 Ativos +3 Reserva.
const INFRASTRUCTURE_PER_LEVEL: Dictionary = {
	1: [1, 4], 2: [1, 4], 3: [2, 3], 4: [2, 3], 5: [2, 4], 6: [2, 4], 7: [2, 5],
}
const INFRASTRUCTURE_LEVEL_8_PLUS: Array = [2, 3]


## Vagas de Treinamento concedidas pelo Nível do Centro de Comando —
## 0 antes do desbloqueio (Nível 3); 1 vaga no desbloqueio, +1 a cada
## 4 níveis depois disso. NÃO inclui vagas extras do Legado II
## (`COMMAND_CENTER_LEGACY.md`) — essas se somam a este valor,
## calculadas à parte por quem for implementar o Legado.
static func training_slots(command_center_level: int) -> int:
	if command_center_level < TRAINING_UNLOCK_LEVEL:
		return 0

	@warning_ignore("integer_division")
	return 1 + (command_center_level - TRAINING_UNLOCK_LEVEL) / TRAINING_SLOTS_PER_MILESTONE


## Infraestrutura Administrativa TOTAL acumulada do Nível 1 até
## "command_center_level" (o potencial bruto, ainda não ativado — ver
## CommandCenterResolver.activate_next() para a ativação em PG).
## Retorna {"ativo": int, "reserva": int}.
static func infrastructure_at_level(command_center_level: int) -> Dictionary:
	var total_ativo: int = 0
	var total_reserva: int = 0
	for level in range(1, command_center_level + 1):
		var pair: Array = INFRASTRUCTURE_PER_LEVEL.get(level, INFRASTRUCTURE_LEVEL_8_PLUS)
		total_ativo += pair[0]
		total_reserva += pair[1]
	return {"ativo": total_ativo, "reserva": total_reserva}


## Custo em PG para ativar 1 unidade de Recurso Administrativo (Cargo
## Ativo ou Vaga da Reserva — mesmo custo para os dois), pela faixa de
## Nível do CdC (COMMAND_CENTER_PROGRESS.md, "Aplicação de Custos em PG":
## 1 PG a cada 10 níveis, começando em 1).
static func pg_cost_per_activation(command_center_level: int) -> int:
	@warning_ignore("integer_division")
	return 1 + (command_center_level - 1) / 10


## --- Centro de Recrutamento (COMMAND_CENTER_RECRUITMENT.md) ---

## Capacidade de Slots do Centro de Recrutamento (COMMAND_CENTER_RECRUITMENT.md,
## "Capacidade e Progressão de Slots"): 3 iniciais, +1 a cada 10 níveis do CdC.
const RECRUITMENT_CENTER_INITIAL_SLOTS: int = 3
const RECRUITMENT_CENTER_SLOTS_PER_MILESTONE: int = 10

static func recruitment_center_slots(command_center_level: int) -> int:
	@warning_ignore("integer_division")
	return RECRUITMENT_CENTER_INITIAL_SLOTS + command_center_level / RECRUITMENT_CENTER_SLOTS_PER_MILESTONE


## Cooldown do gerador do Centro de Recrutamento, em segundos
## (COMMAND_CENTER_RECRUITMENT.md, "Sistema de Geração e Cooldown"):
## 24h iniciais, -1h a cada 15 níveis do CdC, piso de 12h.
const RECRUITMENT_CENTER_INITIAL_COOLDOWN_HOURS: int = 24
const RECRUITMENT_CENTER_COOLDOWN_REDUCTION_PER_LEVELS: int = 15
const RECRUITMENT_CENTER_MIN_COOLDOWN_HOURS: int = 12

static func recruitment_center_cooldown_seconds(command_center_level: int) -> int:
	@warning_ignore("integer_division")
	var reduction: int = command_center_level / RECRUITMENT_CENTER_COOLDOWN_REDUCTION_PER_LEVELS
	var hours: int = maxi(RECRUITMENT_CENTER_MIN_COOLDOWN_HOURS, RECRUITMENT_CENTER_INITIAL_COOLDOWN_HOURS - reduction)
	return hours * 3600


## --- Capacidades Efetivas (Nível do CdC + bônus do Legado) ---
##
## Sempre usar estas em vez de training_slots()/infrastructure_at_level()
## puros para checar capacidade de verdade — a capacidade real do
## Reino é sempre o Nível do CdC MAIS o que o Legado Administrativo já
## concedeu (COMMAND_CENTER_LEGACY.md, Legado II/III/IV).

const LEGACY_II_RETIREES_PER_SLOT: int = 20
const LEGACY_II_MAX_EXTRA_SLOTS: int = 25
const LEGACY_III_RETIREES_PER_VAGA: int = 25
const LEGACY_IV_RETIREES_PER_CARGO: int = 100


## Vagas de Treinamento efetivas: fórmula do Nível do CdC + Legado II
## (+1 a cada 20 aposentados via Legado Administrativo, teto de +25).
static func effective_training_slots(kingdom: Kingdom) -> int:
	@warning_ignore("integer_division")
	var legacy_bonus: int = mini(LEGACY_II_MAX_EXTRA_SLOTS, kingdom.legacy_administrative_retirees / LEGACY_II_RETIREES_PER_SLOT)
	return training_slots(kingdom.command_center_level) + legacy_bonus


## Vagas da Reserva ativadas + Legado III (+1 a cada 25 aposentados via
## Legado Administrativo, sem teto documentado).
static func effective_vaga_reserva(kingdom: Kingdom) -> int:
	@warning_ignore("integer_division")
	var legacy_bonus: int = kingdom.legacy_administrative_retirees / LEGACY_III_RETIREES_PER_VAGA
	return kingdom.vaga_reserva_activated + legacy_bonus


## Cargos de Comando Ativo ativados + Legado IV (+1 a cada 100
## aposentados via Legado Administrativo, sem teto documentado).
static func effective_cargo_ativo(kingdom: Kingdom) -> int:
	@warning_ignore("integer_division")
	var legacy_bonus: int = kingdom.legacy_administrative_retirees / LEGACY_IV_RETIREES_PER_CARGO
	return kingdom.cargo_ativo_activated + legacy_bonus
