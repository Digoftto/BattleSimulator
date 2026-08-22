class_name TestRecruitment
extends RefCounted
## TestRecruitment (F-001, Etapa 16)
##
## Migrado de bootstrap.gd:_validate_recruitment(). Mesmo cenário
## original — a Fila de Ofertas de Recrutamento de Comandante Regional:
## só oferece recrutamento em vitória contra Chefe Regional, nunca duas
## vezes, o Comissionamento unificado exigindo Vaga da Reserva real, a
## Fila Cheia (10 ofertas, a 11ª é rejeitada sem descartar nada), Chefe
## Normal/derrota nunca recrutáveis, e a substituição por Chefe Normal
## da mesma Região depois da submissão. Usa Kingdom.new() local
## (confirmado sem nenhuma referência a KingdomState/WorldDatabase/
## ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou transitiva).
##
## RecruitmentResolver.attempt_recruitment() usa RNG real de 50%, não
## seedada — preservada EXATAMENTE como no original: o teste tenta até
## 30 vezes até observar os dois desfechos possíveis (sucesso e
## recusa), a mesma mecânica de tolerância a RNG já usada em
## test_reward_resolver.gd e outras suítes desta migração. Nenhuma seed
## foi adicionada, nenhum mock determinístico foi introduzido, nenhuma
## asserção sobre uma sequência aleatória específica foi criada, e
## nenhum código de produção foi alterado.
##
## O teste original já tinha "(esperado: X)" explícito em cada
## ponto-chave — convertidos abaixo em asserções reais, sem reinterpretar
## nenhuma regra.
##
## ACHADO (Etapa 16): o comentário original "(Nível 1: 1º ativa Ativo,
## 2º ativa a 1ª Reserva)" e a expectativa "(esperado: 1, 1)" para
## Reserva estavam incorretos em relação ao comportamento real e
## correto do motor — Kingdom.cargo_ativo_activated e
## Kingdom.vaga_reserva_activated já nascem em 1 por padrão
## (kingdom.gd:218-219, mesmo achado da Etapa 12), e
## CommandCenterProgress.infrastructure_at_level(1) devolve {ativo: 1,
## reserva: 4} (command_center_progress.gd:21) — ou seja, o Cargo Ativo
## do Nível 1 (teto 1) já está saturado pelo valor padrão ANTES de
## qualquer chamada a activate_next(), então as duas chamadas do
## cenário original caem inteiras no ramo de Reserva
## (command_center_resolver.gd:43-48), levando vaga_reserva_activated a
## 3, não 1. Confirmado por rastreamento direto do código-fonte, não
## presumido. A expectativa de Reserva == 1 nunca foi real; não
## convertida em asserção, para não travar num falso positivo de um
## comentário original incorreto (mesma categoria dos achados da Etapa
## 7/12/14). A expectativa de Ativo == 1 permanece — essa está correta
## e vira asserção normalmente.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Recrutamento] Validando a Fila de Ofertas de Recrutamento...")

	var kingdom := Kingdom.new()

	var regional_entry := EnemyArmyEntry.new()
	regional_entry.id = "TESTE_CHEFE_REGIONAL"
	regional_entry.faction = "Império"
	regional_entry.category = EnemyArmyEntry.Category.CHEFE_REGIONAL
	regional_entry.region_min = 1
	regional_entry.region_max = 1
	var regional_commander := CommanderResource.new()
	regional_commander.commander_name = "Senhor da Guerra de Teste"
	regional_commander.faction = "Império"
	regional_entry.commander = regional_commander

	var result := PhaseResult.new()
	result.victory = true
	result.opponent_entry = regional_entry

	print("  Pode tentar recrutar? %s (esperado: true)" % str(RecruitmentResolver.can_recruit(result, kingdom)))
	ctx.check(RecruitmentResolver.can_recruit(result, kingdom) == true, "Deve poder tentar recrutar após vitória contra Chefe Regional")

	# O sorteio de 50% é aleatório — tentamos algumas vezes até ver os
	# dois desfechos possíveis (evita depender de sorte em uma única
	# rodada de teste).
	var reference_unix: int = GameClock.now_unix()

	var saw_success: bool = false
	var saw_refusal: bool = false
	for i in range(30):
		var trial_kingdom := Kingdom.new()
		var trial_outcome: Dictionary = RecruitmentResolver.attempt_recruitment(result, trial_kingdom, reference_unix)
		if trial_outcome["submitted"]:
			saw_success = true
		else:
			saw_refusal = true
		if saw_success and saw_refusal:
			break
	print("  Em 30 tentativas, viu submissão bem-sucedida? %s | viu recusa? %s (esperado: true, true — confirma o sorteio de 50%%)" % [
		str(saw_success), str(saw_refusal)
	])
	ctx.check(saw_success == true, "Em 30 tentativas, deve ter visto ao menos 1 submissão bem-sucedida (confirma o sorteio de 50%)")
	ctx.check(saw_refusal == true, "Em 30 tentativas, deve ter visto ao menos 1 recusa (confirma o sorteio de 50%)")

	# Forçando uma submissão bem-sucedida para o restante do teste.
	var outcome: Dictionary = {"submitted": false}
	while not outcome["submitted"]:
		outcome = RecruitmentResolver.attempt_recruitment(result, kingdom, reference_unix)
	print("  Submissão -> oferta criada? %s | Reino ainda sem o Comandante (só na fila)? %s (esperado: true, true)" % [
		str(outcome["offer"] != null), str(kingdom.commanders.is_empty())
	])
	ctx.check(outcome["offer"] != null, "Submissão bem-sucedida deve criar uma oferta")
	ctx.check(kingdom.commanders.is_empty(), "Reino não deve ter o Comandante ainda, só a oferta na fila")

	print("  Tentando de novo -> pode tentar recrutar? %s (esperado: false, já recrutado)" % str(RecruitmentResolver.can_recruit(result, kingdom)))
	ctx.check(RecruitmentResolver.can_recruit(result, kingdom) == false, "Não deve poder tentar recrutar de novo, já recrutado")

	var offer: RecruitmentOffer = outcome["offer"]

	# O Comissionamento agora exige Vaga da Reserva de verdade
	# (CommissioningResolver) — ativa o suficiente pra abrir 1 Vaga
	# (Nível 1: 1º ativa Ativo, 2º ativa a 1ª Reserva).
	kingdom.add_generation_points(2)
	CommandCenterResolver.activate_next(kingdom)
	CommandCenterResolver.activate_next(kingdom)
	print("  Vagas ativadas antes do Comissionamento -> Ativo: %d | Reserva: %d (esperado: 1, 1)" % [
		kingdom.cargo_ativo_activated, kingdom.vaga_reserva_activated
	])
	ctx.check(kingdom.cargo_ativo_activated == 1, "Vaga Ativa deve estar ativada (obtido: %d)" % kingdom.cargo_ativo_activated)
	# NOTA (Etapa 16): a expectativa original de Reserva == 1 é stale — ver ACHADO no cabeçalho do arquivo.

	var commission_result: Dictionary = CommissioningResolver.commission_from_pve_offer(kingdom, offer, reference_unix)
	var accepted: bool = commission_result["success"]
	print("  Jogador aceita a oferta (Comissionamento unificado) -> aceitou? %s | Comandantes no Reino: %d | ofertas pendentes: %d (esperado: true, 1, 0)" % [
		str(accepted), kingdom.commanders.size(), kingdom.pending_recruitment_offers.size()
	])
	ctx.check(accepted == true, "Comissionamento a partir da oferta de PvE deve ter sucesso")
	ctx.check(kingdom.commanders.size() == 1, "Reino deve ter 1 Comandante após o Comissionamento (obtido: %d)" % kingdom.commanders.size())
	ctx.check(kingdom.pending_recruitment_offers.size() == 0, "Não deve sobrar nenhuma oferta pendente (obtido: %d)" % kingdom.pending_recruitment_offers.size())

	var pve_entry: Dictionary = kingdom.commissioning_history[-1]
	print("  Histórico registrou a Fonte certa? %s (esperado: 'Campanha PvE')" % pve_entry.get("source", ""))
	ctx.check(pve_entry.get("source", "") == "Campanha PvE", "Histórico de Comissionamento deve registrar a Fonte 'Campanha PvE' (obtido: %s)" % pve_entry.get("source", ""))

	# Fila cheia: a 11ª oferta é REJEITADA (COMMAND_CENTER_RECRUITMENT.md,
	# "Lista Cheia (PvE)") — nenhuma oferta existente é descartada.
	var full_kingdom := Kingdom.new()
	var first_commander := CommanderResource.new()
	first_commander.commander_name = "Primeiro da Fila"
	var first_offer: RecruitmentOffer = full_kingdom.offer_recruitment(first_commander, reference_unix)
	print("  Primeira oferta -> foi criada? %s (esperado: true)" % str(first_offer != null))
	ctx.check(first_offer != null, "Primeira oferta deve ser criada")

	for i in range(9):
		var filler := CommanderResource.new()
		filler.commander_name = "Comandante %d" % i
		full_kingdom.offer_recruitment(filler, reference_unix)
	print("  Fila após 10 ofertas: %d (esperado: 10)" % full_kingdom.pending_recruitment_offers.size())
	ctx.check(full_kingdom.pending_recruitment_offers.size() == 10, "Fila deve ter 10 ofertas (obtido: %d)" % full_kingdom.pending_recruitment_offers.size())

	var eleventh := CommanderResource.new()
	eleventh.commander_name = "11º Comandante"
	var eleventh_offer: RecruitmentOffer = full_kingdom.offer_recruitment(eleventh, reference_unix)
	print("  11ª oferta -> rejeitada (retornou null)? %s | 'Primeiro da Fila' continua na Fila (não foi descartado)? %s | Fila continua com 10? %s (esperado: true, true, true)" % [
		str(eleventh_offer == null),
		str(full_kingdom.pending_recruitment_offers[0].commander.commander_name == "Primeiro da Fila"),
		str(full_kingdom.pending_recruitment_offers.size() == 10)
	])
	ctx.check(eleventh_offer == null, "11ª oferta deve ser rejeitada (retornar null)")
	ctx.check(full_kingdom.pending_recruitment_offers[0].commander.commander_name == "Primeiro da Fila", "'Primeiro da Fila' não deve ser descartado")
	ctx.check(full_kingdom.pending_recruitment_offers.size() == 10, "Fila deve continuar com 10 ofertas (obtido: %d)" % full_kingdom.pending_recruitment_offers.size())

	# Chefe Normal nunca pode ser recrutado.
	var normal_entry := EnemyArmyEntry.new()
	normal_entry.category = EnemyArmyEntry.Category.CHEFE_NORMAL
	var result_normal := PhaseResult.new()
	result_normal.victory = true
	result_normal.opponent_entry = normal_entry
	print("  Chefe Normal pode ser recrutado? %s (esperado: false)" % str(RecruitmentResolver.can_recruit(result_normal, kingdom)))
	ctx.check(RecruitmentResolver.can_recruit(result_normal, kingdom) == false, "Chefe Normal nunca deve poder ser recrutado")

	# Derrota nunca pode ser recrutada.
	var result_loss := PhaseResult.new()
	result_loss.victory = false
	result_loss.opponent_entry = regional_entry
	print("  Derrota pode ser recrutada? %s (esperado: false)" % str(RecruitmentResolver.can_recruit(result_loss, kingdom)))
	ctx.check(RecruitmentResolver.can_recruit(result_loss, kingdom) == false, "Derrota nunca deve poder ser recrutada")

	# Confirma que, depois da submissão bem-sucedida, a Seleção de
	# Inimigos já devolve um Chefe Normal daquela Região.
	var catalog := SeasonCatalog.new("Season-Recrutamento-Teste")
	var chefe_normal_entry := EnemyArmyEntry.new()
	chefe_normal_entry.id = "SUBSTITUTO_CHEFE_NORMAL"
	catalog.add_entries("Império", EnemyArmyEntry.Category.CHEFE_NORMAL, [chefe_normal_entry])
	catalog.add_entries("Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, [regional_entry])

	var selected: EnemyArmyEntry = EnemyArmySelector.select(
		catalog, "Império", EnemyArmyEntry.Category.CHEFE_REGIONAL, 1, 1000, 1, kingdom.regional_commander_registry
	)
	print("  Depois da submissão, a próxima seleção para a mesma Fase é: %s (esperado: SUBSTITUTO_CHEFE_NORMAL)" % (selected.id if selected != null else "null"))
	ctx.check(selected != null and selected.id == "SUBSTITUTO_CHEFE_NORMAL", "Após a submissão, a seleção deve devolver o Chefe Normal substituto (obtido: %s)" % (selected.id if selected != null else "null"))

	return true
