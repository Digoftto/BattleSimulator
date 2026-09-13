class_name ExpeditionPersistenceResolver
extends RefCounted
## ExpeditionPersistenceResolver
##
## Segunda metade da persistência de Expedição (F-020): reconstrói
## ExpeditionRuntime a partir do dado cru que KingdomSaveService deixou
## em Kingdom._pending_expedition_saves. Existe como classe separada (em
## vez de fazer isso dentro do próprio KingdomSaveService) porque depende
## de WorldDatabase (Season/Territory/Trilha) já estar carregado — algo
## que KingdomSaveService._dict_to_kingdom() não pode garantir, mas que
## KingdomState._load_or_create_kingdom() garante antes de chamar
## hydrate_pending() (WorldBootstrap.ensure_world_loaded() primeiro).
##
## Chamado exatamente uma vez por carregamento de save, nunca em
## qualquer outro fluxo.


static func hydrate_pending(kingdom: Kingdom) -> void:
	if kingdom._pending_expedition_saves.is_empty():
		return

	for data: Dictionary in kingdom._pending_expedition_saves:
		var expedition: ExpeditionRuntime = _hydrate_one(data, kingdom)
		if expedition != null:
			kingdom.restore_expedition(expedition)

	kingdom._pending_expedition_saves.clear()


static func _hydrate_one(data: Dictionary, kingdom: Kingdom) -> ExpeditionRuntime:
	var season: Season = WorldDatabase.get_season(data.get("season_id", ""))
	if season == null:
		push_error("ExpeditionPersistenceResolver: Temporada '%s' não encontrada — Expedição salva não pôde ser restaurada." % data.get("season_id", ""))
		kingdom.pending_restoration_warnings.append("Uma Expedição salva não pôde ser restaurada porque a Temporada em que ela estava não está mais disponível. Nenhum outro progresso foi afetado — você pode iniciar uma nova Expedição normalmente.")
		return null

	var territory_id: String = data.get("territory_id", "")
	var territory: Territory = season.get_territory(territory_id)
	var trilha: Trilha = season.get_trilha(territory_id)
	if territory == null or trilha == null:
		push_error("ExpeditionPersistenceResolver: Território/Trilha '%s' não encontrado na Temporada '%s' — Expedição salva não pôde ser restaurada." % [territory_id, data.get("season_id", "")])
		kingdom.pending_restoration_warnings.append("Uma Expedição salva não pôde ser restaurada porque o Território em que ela estava não está mais disponível. Nenhum outro progresso foi afetado — você pode iniciar uma nova Expedição normalmente.")
		return null

	var squad_data: Dictionary = data.get("squad", {})
	var armies: Array[Army] = []
	for index: int in squad_data.get("army_indices", []):
		if index >= 0 and index < kingdom.armies.size():
			armies.append(kingdom.armies[index])
	var squad := Squad.new(armies)
	squad.active_index = squad_data.get("active_index", 0)

	var expedition := ExpeditionRuntime.new(
		squad, trilha, territory, season.enemy_catalog, kingdom.regional_commander_registry,
		data.get("expedition_seed", 0), GameDatabase.battlefields, GameDatabase.abilities_by_name, GameDatabase.unit_traits
	)

	expedition.current_fase = data.get("current_fase", 1)
	expedition.last_acampamento_fase = data.get("last_acampamento_fase", 1)
	expedition.status = data.get("status", ExpeditionRuntime.Status.EM_ANDAMENTO) as ExpeditionRuntime.Status
	expedition.acampamento_policy = data.get("acampamento_policy", ExpeditionRuntime.AcampamentoPolicy.AGUARDAR_RECUPERACAO_TOTAL) as ExpeditionRuntime.AcampamentoPolicy
	expedition.energy_recovery_threshold_percent = data.get("energy_recovery_threshold_percent", 0.4)
	expedition.is_waiting_at_acampamento = data.get("is_waiting_at_acampamento", false)
	# Compatibilidade com saves anteriores à auditoria pré-pré-alfa (sem
	# "camp_state" gravado): nunca reconstrói AWAITING_DECISION por
	# padrão (apresentaria uma escolha potencialmente já obsoleta) — se
	# o save antigo já estava parado (is_waiting_at_acampamento true,
	# sempre por derrota/Energia esgotada nesse código antigo, já que a
	# política automática nunca deixava essa flag persistir true),
	# reconstrói como FORCED_UNTIL_FULL (só espera Energia plena, nunca
	# uma escolha inventada); senão, NONE.
	var default_camp_state: int = ExpeditionRuntime.CampState.FORCED_UNTIL_FULL if expedition.is_waiting_at_acampamento else ExpeditionRuntime.CampState.NONE
	expedition.camp_state = data.get("camp_state", default_camp_state) as ExpeditionRuntime.CampState
	expedition.last_tick_unix = data.get("last_tick_unix", 0)

	var history: Array[String] = []
	for line: String in data.get("history_log", []):
		history.append(line)
	# Sobrescreve a linha automática "Expedição iniciada..." gravada por
	# ExpeditionRuntime._init() — o histórico salvo é a fonte de verdade.
	expedition.history_log = history

	var fase_history: Dictionary = {}
	var raw_fase_history: Dictionary = data.get("fase_history", {})
	for key_str: String in raw_fase_history:
		fase_history[int(key_str)] = raw_fase_history[key_str]
	expedition.fase_history = fase_history

	return expedition
