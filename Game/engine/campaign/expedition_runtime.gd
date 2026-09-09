class_name ExpeditionRuntime
extends RefCounted
## ExpeditionRuntime
##
## Controla uma Expedição ativa (PvE.md): mantém a Fase atual, o último
## Acampamento e o Squad. A partir da Sprint 32, resolve sozinho quem é
## o Exército inimigo de cada Fase — consultando Trilha (tipo de Fase,
## Região), Territory (Facção) e SeasonCatalog/EnemyArmySelector
## (Exército concreto) — sem que quem chama attempt_current_fase()
## precise saber quem é o inimigo. Não contém nenhuma lógica de
## Combate — delega inteiramente a PhaseResolver.

enum Status { EM_ANDAMENTO, CONCLUIDA, ENCERRADA }

## Política de Acampamento (PvE.md, "Política de Acampamento") —
## configurada previamente pelo jogador, define o comportamento da
## Expedição ao alcançar um Acampamento.
enum AcampamentoPolicy {
	AGUARDAR_ORDEM,               # a marcha para até decisão manual do jogador
	SEGUIR_AUTOMATICO,             # continua imediatamente, independente da Energia
	AGUARDAR_RECUPERACAO_TOTAL,    # sempre recupera 100% da Energia antes de continuar
	AGUARDAR_LIMITE,               # continua se acima do limite; senão, recupera 100%
}

var squad: Squad
var trilha: Trilha
var territory: Territory
var season_catalog: SeasonCatalog
var regional_commander_registry: RegionalCommanderRegistry
var expedition_seed: int

var current_fase: int = 1
var last_acampamento_fase: int = 1
var status: Status = Status.EM_ANDAMENTO

## Política de Acampamento ativa e, quando aplicável (AGUARDAR_LIMITE),
## o limite percentual configurado pelo jogador (0.0 a 1.0).
var acampamento_policy: AcampamentoPolicy = AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL
var energy_recovery_threshold_percent: float = 0.4

## True quando a Expedição está parada em um Acampamento aguardando
## decisão manual do jogador (política AGUARDAR_ORDEM). Nenhuma outra
## política deixa a Expedição neste estado — todas as demais se
## resolvem sozinhas no momento em que o Acampamento é estabelecido.
var is_waiting_at_acampamento: bool = false

var _battlefields: Array[BattlefieldResource]
var _abilities_by_name: Dictionary
var _unit_traits: Array[UnitTraitResource]

## Registro textual estrutural (mesma convenção de CombatState.battle_log).
var history_log: Array[String] = []

## Instante Unix da última tentativa automática desta Expedição (F-020,
## Ritmo da Expedição). 0 = nunca tentou automaticamente ainda — a
## primeira sincronização tenta imediatamente. Lido/escrito
## exclusivamente por ExpeditionTickResolver.sync().
var last_tick_unix: int = 0

## Histórico persistente por Fase (F-020, Parte 5/14; F-021 acrescenta
## formação real): Fase (int) -> {"enemy_id", "enemy_name",
## "enemy_faction", "commander_name", "category", "victory",
## "defeat_reason", "attempts", "enemy_commander_faction",
## "enemy_formation_card_names" (Array[String], 9 posições, "" onde
## vazio), "player_army_name", "player_formation_name",
## "player_formation_card_names" (Array[String], 9 posições — só
## presente em vitória, já que só há uma única Formação vencedora por
## Tentativa)}. Dado extraído e plano — nomes de carta (String), nunca
## referências a CardResource/EnemyArmyEntry/PhaseResult — sobrevive a
## save/load e permite reconstruir a UI (hover sobre Fase já disputada,
## incluindo a composição real de quem lutou) sem depender do log
## textual. Sobrescrito a cada nova tentativa da mesma Fase (sempre
## reflete o resultado mais recente).
var fase_history: Dictionary = {}


func _init(
	p_squad: Squad,
	p_trilha: Trilha,
	p_territory: Territory,
	p_season_catalog: SeasonCatalog,
	p_regional_commander_registry: RegionalCommanderRegistry,
	p_expedition_seed: int,
	p_battlefields: Array[BattlefieldResource],
	p_abilities_by_name: Dictionary,
	p_unit_traits: Array[UnitTraitResource]
) -> void:
	squad = p_squad
	trilha = p_trilha
	territory = p_territory
	season_catalog = p_season_catalog
	regional_commander_registry = p_regional_commander_registry
	expedition_seed = p_expedition_seed
	_battlefields = p_battlefields
	_abilities_by_name = p_abilities_by_name
	_unit_traits = p_unit_traits
	history_log.append("Expedição iniciada. Fase 1 de %d. Território: %s (%s)." % [
		trilha.total_fases(), territory.id, territory.faction
	])


## Tipo da Fase atual: "regional", "normal" ou "comum". Já reflete a
## Prioridade entre Chefes definida em PvE.md (Trilha.chefe_type).
func current_fase_type() -> String:
	var chefe: String = trilha.chefe_type(current_fase)
	if chefe != "":
		return chefe
	return "comum"


## True se a Fase atual é um Acampamento oficial (já gerado pela Trilha,
## respeitando prioridade e reinício de contagem).
func current_fase_is_acampamento() -> bool:
	return trilha.is_acampamento(current_fase)


## Resolve automaticamente o Exército inimigo da Fase atual (via
## Trilha + Territory + EnemyArmySelector/SeasonCatalog) e tenta a
## Fase. Estabelece Acampamento automaticamente quando a Fase
## conquistada for uma; avança para a próxima Fase em caso de vitória;
## retorna ao último Acampamento em caso de derrota total do Squad.
## Retorna o PhaseResult da tentativa, ou null se: a Expedição não
## estiver em andamento; estiver aguardando ordem no Acampamento; a Fase
## atual for um Acampamento comum resolvido sem combate (decisão 8); ou
## não houver Exército compatível no Catálogo.
func attempt_current_fase() -> PhaseResult:
	if status != Status.EM_ANDAMENTO:
		return null

	if is_waiting_at_acampamento:
		history_log.append("Expedição aguardando ordem do jogador no Acampamento (Fase %d) — nenhuma tentativa realizada." % current_fase)
		return null

	# F-020, decisão 8: Acampamento comum é parada pura — não exige
	# combate para se estabelecer. Um Acampamento que coincide com um
	# Chefe Regional (chefe_type != "") NUNCA cai aqui: continua exigindo
	# a vitória do Chefe, e estabelecer o Acampamento ali é efeito
	# colateral dessa vitória (was_acampamento -> establish_acampamento(),
	# abaixo, inalterado).
	if current_fase_is_acampamento() and trilha.chefe_type(current_fase) == "":
		return _arrive_at_camp_without_combat()

	var category: EnemyArmyEntry.Category = _entry_category_for_current_fase()
	var region: int = trilha.region_for_fase(current_fase)

	var entry: EnemyArmyEntry = EnemyArmySelector.select(
		season_catalog, territory.faction, category, region,
		current_fase, expedition_seed, regional_commander_registry
	)

	if entry == null:
		history_log.append("Fase %d: nenhum Exército inimigo compatível no Catálogo (Facção %s, Categoria %s, Região %d)." % [
			current_fase, territory.faction, EnemyArmyEntry.Category.keys()[category], region
		])
		return null

	var result: PhaseResult = PhaseResolver.resolve(
		squad, entry, _battlefields, _abilities_by_name, _unit_traits, "PvE — Fase %d (%s)" % [current_fase, territory.id], "pve"
	)

	_record_fase_history(current_fase, entry, result)

	if result.victory:
		var fase_type: String = current_fase_type()
		var was_acampamento: bool = current_fase_is_acampamento()
		var kingdom: Kingdom = KingdomState.kingdom

		# RESOURCES.md §4 / RewardResolver: credita Fragmentos de
		# verdade ao Reino por cada Pelotão Original inimigo destruído
		# na Fase vencida — RewardResolver já existia, testado,
		# correto, mas nunca era chamado fora dos meus testes.
		var fragments_earned: int = RewardResolver.resolve(result, kingdom, SeasonConfig.new())

		# FORMULAS.md ("XP da Conta") / AccountXPResolver: nenhuma das
		# duas nunca era chamada fora dos meus testes — vitória de PvE
		# nunca dava XP de Conta de verdade.
		if fase_type == "comum":
			AccountXPResolver.grant_pve_fase_comum(kingdom)
		else:
			AccountXPResolver.grant_pve_chefe(kingdom)

		# XP.md / CommanderCareer.xp_for_pve_victory() +
		# CommanderTrainingResolver.record_combat_xp(): o próprio
		# comentário do resolver já avisava que isso nunca tinha sido
		# ligado dentro de ExpeditionRuntime.
		var winning_army: Army = squad.armies[result.winning_army_index]
		if winning_army.commander != null:
			CommanderTrainingResolver.record_combat_xp(
				kingdom, winning_army.commander, CommanderCareer.xp_for_pve_victory(), GameClock.now_unix()
			)

		if fragments_earned > 0:
			var breakdown_parts: Array[String] = []
			for faction: String in result.enemy_pelotoes_destroyed_by_faction:
				breakdown_parts.append("%d de %s" % [result.enemy_pelotoes_destroyed_by_faction[faction], faction])
			history_log.append("Fase %d (%s) vencida contra %s (Exército %d, Formação %s, %d tentativa(s)) — %d Fragmentos creditados (%s Pelotões destruídos)." % [
				current_fase, fase_type, entry.id, result.winning_army_index + 1, result.winning_formation, result.attempts, fragments_earned, ", ".join(breakdown_parts)
			])
		else:
			history_log.append("Fase %d (%s) vencida contra %s (Exército %d, Formação %s, %d tentativa(s))." % [
				current_fase, fase_type, entry.id, result.winning_army_index + 1, result.winning_formation, result.attempts
			])

		if was_acampamento:
			establish_acampamento()

		current_fase += 1
		if current_fase > trilha.total_fases():
			status = Status.CONCLUIDA
			history_log.append("Trilha concluída na Fase %d." % (current_fase - 1))
	else:
		history_log.append("Fase %d não conquistada contra %s (%d tentativas) — retornando ao Acampamento (Fase %d)." % [
			current_fase, entry.id, result.attempts, last_acampamento_fase
		])
		current_fase = last_acampamento_fase
		# Bug real relatado: sem isso, o Exército ficava "travado" (Em
		# Expedição, sem editar nem recuperar Energia) mesmo já tendo
		# "voltado" pro Acampamento (ou Cidade, se nenhum Acampamento
		# real tivesse sido alcançado ainda — last_acampamento_fase
		# começa em 1, equivalente à Cidade). Kingdom.is_army_locked_for_editing()
		# e o recálculo de Energia (Army.sync_energy_recovery) dependem
		# desta flag pra saber que o Exército está seguro.
		is_waiting_at_acampamento = true
		# Nenhum estado de "Formação esgotada" persiste entre Tentativas de
		# Fase (PhaseResolver.resolve sempre reinicia o Squad do zero) —
		# a restauração de todas as Formações já ocorre naturalmente.

	return result


## Estabelece um Acampamento comum (não coincidente com Chefe Regional)
## sem exigir combate — F-020, decisão 8. Espelha deliberadamente o
## idioma já usado no ramo de vitória logo acima (establish_acampamento()
## seguido de incremento incondicional de current_fase), para que
## resume_from_acampamento() nunca reencontre esta mesma Fase depois de
## "Continuar" (current_fase já avançou antes do jogador ver a parada).
func _arrive_at_camp_without_combat() -> PhaseResult:
	history_log.append("Fase %d: Acampamento — estabelecido sem combate." % current_fase)
	establish_acampamento()
	current_fase += 1
	if current_fase > trilha.total_fases():
		status = Status.CONCLUIDA
		history_log.append("Trilha concluída na Fase %d." % (current_fase - 1))
	return null


## Grava um registro plano (nunca referências a objetos) do resultado
## desta tentativa em fase_history, para vitória E derrota — F-020,
## Parte 5/14 (hover sobre Fase já disputada). F-021: também captura a
## composição real das duas Formações no INSTANTE da vitória (nomes de
## carta, nunca referência) — squad.armies[i].get_formation() é mutável
## depois (o jogador pode reeditar a Formação no Acampamento), então
## precisa ser fotografado agora, não recalculado depois. Sobrescreve
## qualquer registro anterior da mesma Fase.
func _record_fase_history(fase: int, entry: EnemyArmyEntry, result: PhaseResult) -> void:
	var data: Dictionary = {
		"enemy_id": entry.id,
		"enemy_name": entry.army_name,
		"enemy_faction": entry.faction,
		"commander_name": entry.commander.commander_name if entry.commander != null else "",
		"enemy_commander_faction": entry.commander.faction if entry.commander != null else "",
		"category": EnemyArmyEntry.Category.keys()[entry.category],
		"victory": result.victory,
		"defeat_reason": PhaseResult.DefeatReason.keys()[result.defeat_reason],
		"attempts": result.attempts,
		"enemy_formation_card_names": _card_names_for(entry.cards),
	}

	if result.victory:
		var winning_army: Army = squad.armies[result.winning_army_index]
		data["player_army_name"] = winning_army.army_name
		data["player_formation_name"] = result.winning_formation
		data["player_formation_card_names"] = _card_names_for(winning_army.get_formation(result.winning_formation))

	fase_history[fase] = data


## Nomes reais das cartas de uma Formação, na mesma ordem posicional
## (índice 0 = Posição 1 .. índice 8 = Posição 9, COMBAT_RULES.md) —
## "" para uma posição sem carta (nunca inventado).
func _card_names_for(cards: Array[CardResource]) -> Array[String]:
	var names: Array[String] = []
	for card: CardResource in cards:
		names.append(card.card_name if card != null else "")
	return names


## Categoria de Exército Inimigo correspondente ao tipo da Fase atual
## (Prioridade entre Chefes já resolvida por Trilha.chefe_type).
func _entry_category_for_current_fase() -> EnemyArmyEntry.Category:
	match trilha.chefe_type(current_fase):
		"regional":
			return EnemyArmyEntry.Category.CHEFE_REGIONAL
		"normal":
			return EnemyArmyEntry.Category.CHEFE_NORMAL
		_:
			return EnemyArmyEntry.Category.NORMAL


## Estabelece a Fase atual como um novo Acampamento (checkpoint
## permanente) e aplica a Política de Acampamento configurada.
func establish_acampamento() -> void:
	last_acampamento_fase = current_fase
	history_log.append("Acampamento estabelecido na Fase %d." % current_fase)
	_apply_acampamento_policy()


## Aplica a Política de Acampamento ativa (PvE.md). Apenas
## AGUARDAR_ORDEM deixa a Expedição parada — as demais se resolvem
## imediatamente (recuperando ou não a Energia, conforme a política),
## já que a simulação de passagem real de tempo pertence a uma Sprint
## própria (Ritmo/Tempo da Expedição), fora de escopo aqui.
func _apply_acampamento_policy() -> void:
	match acampamento_policy:
		AcampamentoPolicy.SEGUIR_AUTOMATICO:
			history_log.append("Política 'Seguir Automaticamente' — a marcha continua sem recuperar Energia.")

		AcampamentoPolicy.AGUARDAR_ORDEM:
			is_waiting_at_acampamento = true
			history_log.append("Política 'Aguardar Ordem' — Expedição parada até decisão manual do jogador.")

		AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL:
			_recover_squad_energy()
			history_log.append("Política 'Aguardar Recuperação Total' — todos os Exércitos do Squad recuperaram 100%% de Energia.")

		AcampamentoPolicy.AGUARDAR_LIMITE:
			if _squad_all_above_threshold(energy_recovery_threshold_percent):
				history_log.append("Política 'Aguardar Limite' — Energia acima do limite configurado (%d%%); a marcha continua sem recuperar." % int(energy_recovery_threshold_percent * 100))
			else:
				_recover_squad_energy()
				history_log.append("Política 'Aguardar Limite' — Energia abaixo do limite configurado (%d%%); recuperação total realizada." % int(energy_recovery_threshold_percent * 100))


## Ordem manual do jogador para continuar a partir de um Acampamento
## onde a Expedição estava parada (política AGUARDAR_ORDEM). Recupera
## a Energia do Squad antes de liberar a marcha — o repouso que
## justificava a espera já aconteceu.
func resume_from_acampamento() -> void:
	if not is_waiting_at_acampamento:
		return
	_recover_squad_energy()
	is_waiting_at_acampamento = false
	history_log.append("Jogador ordenou a continuação a partir do Acampamento (Fase %d) — Energia recuperada." % current_fase)


func _recover_squad_energy() -> void:
	for army: Army in squad.armies:
		army.recover_energy_full()


## True se todos os Exércitos do Squad estão com Energia acima (ou
## igual) ao limite percentual informado (0.0 a 1.0).
func _squad_all_above_threshold(threshold_percent: float) -> bool:
	for army: Army in squad.armies:
		if army.max_energy <= 0:
			continue
		var ratio: float = float(army.current_energy) / float(army.max_energy)
		if ratio < threshold_percent:
			return false
	return true


## Encerra a Expedição por decisão do jogador (uma das 4 formas de
## encerramento previstas em PvE.md).
func end_expedition() -> void:
	status = Status.ENCERRADA
	history_log.append("Expedição encerrada por decisão do jogador na Fase %d." % current_fase)
