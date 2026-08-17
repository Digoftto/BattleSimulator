class_name KingdomSaveService
extends RefCounted
## KingdomSaveService
##
## Converte Kingdom <-> um arquivo JSON legível, gravado em user://
## (pasta de save padrão do Godot, separada da pasta do projeto).
##
## Escopo: salva tudo que é permanente do Reino — Comandantes, Cartas,
## Exércitos, Squads, Recursos, Minas, Fila de Recrutamento, Registro de
## Comandantes Regionais, Flags de Progresso. NÃO salva uma Expedição em
## andamento — ela depende de Trilha/Temporada/Catálogo (conteúdo do
## Mundo, não do Reino); retomar de onde parou numa Expedição fica para
## uma Sprint própria.
##
## Simplificação conhecida (v1): Cartas e Comandantes não têm um
## identificador único hoje — cada ocorrência é salva por valor
## (conteúdo), não por referência. Se o mesmo objeto aparecer em dois
## lugares (ex: uma carta tanto em Kingdom.cards quanto dentro de um
## Army), depois de carregar eles voltam como duas cópias de conteúdo
## igual, não a mesma instância. Aceitável para hoje; passaria a
## importar de verdade se algum sistema futuro depender de identidade
## exata (não só conteúdo) de uma Carta/Comandante específico.
##
## Nenhum Resource "se salva sozinho" — Resources continuam dado puro
## (princípio do projeto desde o início). Esta classe é o único lugar
## que sabe traduzir entre o Reino em memória e o arquivo em disco.

const SAVE_PATH: String = "user://kingdom_save.json"


## Salva "kingdom" em disco. Retorna true se salvou com sucesso.
static func save(kingdom: Kingdom) -> bool:
	var data: Dictionary = _kingdom_to_dict(kingdom)
	var json_text: String = JSON.stringify(data, "\t")

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("KingdomSaveService: não foi possível criar o arquivo de save (%s)." % SAVE_PATH)
		return false

	file.store_string(json_text)
	file.close()
	return true


## Carrega o save salvo em disco, escrevendo o resultado dentro de
## "kingdom" (que deve já existir — este método não cria um Kingdom
## novo, só o preenche). Retorna true se carregou com sucesso, false se
## não havia save ou o arquivo estava corrompido.
static func load_into(kingdom: Kingdom) -> bool:
	if not has_save():
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("KingdomSaveService: arquivo de save corrompido ou em formato inesperado.")
		return false

	_dict_to_kingdom(parsed, kingdom)
	# create_initial_mines() já tem guarda de idempotência (não faz
	# nada se já existirem) — chamar de novo aqui só preenche saves
	# gravados antes desta correção existir, que nunca tiveram Minas
	# Iniciais criadas.
	kingdom.create_initial_mines()
	return true


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


# ------------------------------------------------------------------
# Kingdom -> Dictionary
# ------------------------------------------------------------------

static func _kingdom_to_dict(kingdom: Kingdom) -> Dictionary:
	# Pool de tarefas da Academia calculado uma vez, antes do resto —
	# usado tanto pelas filas dos Mestres quanto pela cadeia pendente,
	# porque uma referencia a outra (ver _collect_all_academy_tasks()).
	var academy_all_tasks: Array[AcademyTask] = _collect_all_academy_tasks(kingdom)
	var academy_task_ids: Dictionary = {}
	for i in range(academy_all_tasks.size()):
		academy_task_ids[academy_all_tasks[i]] = i
	var academy_pending_chain_task_ids: Array = []
	for task: AcademyTask in kingdom.academy_pending_chain_tasks:
		academy_pending_chain_task_ids.append(academy_task_ids[task])

	return {
		"energy_nucleus_level": kingdom.energy_nucleus_level,
		"next_card_instance_id": kingdom.next_card_instance_id,
		"next_commander_instance_id": kingdom.next_commander_instance_id,
		"capital_level": kingdom.capital_level,
		"command_center_level": kingdom.command_center_level,
		"cargo_ativo_activated": kingdom.cargo_ativo_activated,
		"vaga_reserva_activated": kingdom.vaga_reserva_activated,
		"daily_combat_xp_log": kingdom.daily_combat_xp_log.duplicate(),
		"training_current_day": kingdom.training_current_day,
		"last_daily_average_xp": kingdom.last_daily_average_xp,
		"recruitment_center_slots": kingdom.recruitment_center_slots.map(_commander_to_dict_or_null),
		"recruitment_center_cycle_end_unix": kingdom.recruitment_center_cycle_end_unix,
		"commissioning_history": kingdom.commissioning_history.duplicate(true),
		"legacy_i_xp_bonus_percent": kingdom.legacy_i_xp_bonus_percent,
		"legacy_administrative_retirees": kingdom.legacy_administrative_retirees,
		"legacy_v_bonus_xp": kingdom.legacy_v_bonus_xp,
		"legacy_v_bonus_resources": kingdom.legacy_v_bonus_resources,
		"legacy_v_bonus_fragments": kingdom.legacy_v_bonus_fragments,
		"military_doctrine": kingdom.military_doctrine.duplicate(true),
		"academy_level": kingdom.academy_level,
		"deposito_level": kingdom.deposito_level,
		"account_xp": kingdom.account_xp,
		"academy_artifices": _academy_masters_to_array(kingdom.academy_artifices, academy_task_ids),
		"academy_metamorfos": _academy_masters_to_array(kingdom.academy_metamorfos, academy_task_ids),
		"academy_task_pool": _academy_task_pool_to_array(kingdom, academy_task_ids),
		"favorite_card_names": kingdom.favorite_card_names.duplicate(),
		"starter_kit_used": kingdom.starter_kit_used,
		"new_card_names": kingdom.new_card_names.duplicate(),
		"academy_pending_chain_task_ids": academy_pending_chain_task_ids,
		"structural_xp_unlocked": kingdom.structural_xp_unlocked.duplicate(),
		"generation_points": kingdom.generation_points,
		"raw_resources": kingdom.raw_resources.duplicate(),
		"commanders": _commanders_to_array(kingdom.commanders),
		"cards": _cards_to_array(kingdom.cards),
		"armies": _armies_to_array(kingdom.armies),
		"squads": _squads_to_array(kingdom.squads, kingdom.armies),
		"resources": kingdom.resources.duplicate(),
		"regional_commander_registry": kingdom.regional_commander_registry.export_data(),
		"pending_recruitment_offers": _offers_to_array(kingdom.pending_recruitment_offers),
		"expired_recruitment_notifications": kingdom.expired_recruitment_notifications.duplicate(),
		"initial_mines": _mines_to_array(kingdom.initial_mines, kingdom.armies),
		"territory_mines": _territory_mines_to_dict(kingdom.territory_mines, kingdom.armies),
		"progress_flags": kingdom.progress_flags.duplicate(),
	}


## Serializa a Doutrina de um Comandante (COMMANDER_GENERATION.md) só
## pelos códigos dos 5 componentes — cada um já mora no GameDatabase
## como Resource carregado do catálogo oficial, sem sentido duplicar
## esse conteúdo no save. {} quando o Comandante não tem Doutrina (ex:
## Kit Inicial — "Comandante em branco").
static func _doctrine_to_dict(doctrine: CommanderDoctrine) -> Dictionary:
	if doctrine == null:
		return {}
	return {
		"faction": doctrine.faction,
		"restriction_code": doctrine.restriction.code,
		"restriction_param": doctrine.restriction_param,
		"requirement_code": doctrine.requirement.code,
		"requirement_param": doctrine.requirement_param,
		"target_code": doctrine.target.code,
		"effect_code": doctrine.effect.code,
		"value_code": doctrine.value.code,
		"rarity_score": doctrine.rarity_score,
	}


## Reconstrói a Doutrina buscando cada componente no GameDatabase pelo
## código salvo. null quando data estiver vazio (sem Doutrina).
static func _dict_to_doctrine(data: Dictionary) -> CommanderDoctrine:
	if data.is_empty():
		return null

	var doctrine := CommanderDoctrine.new()
	doctrine.faction = data.get("faction", "")
	doctrine.restriction = _find_by_code(GameDatabase.commander_restrictions, data.get("restriction_code", ""))
	doctrine.restriction_param = data.get("restriction_param", "")
	doctrine.requirement = _find_by_code(GameDatabase.commander_requirements, data.get("requirement_code", ""))
	doctrine.requirement_param = data.get("requirement_param", "")
	doctrine.target = _find_by_code(GameDatabase.commander_targets, data.get("target_code", ""))
	doctrine.effect = _find_by_code(GameDatabase.commander_effects, data.get("effect_code", ""))
	doctrine.value = _find_by_code(GameDatabase.commander_values, data.get("value_code", ""))
	doctrine.rarity_score = data.get("rarity_score", 0)

	if doctrine.restriction == null or doctrine.requirement == null or doctrine.target == null or doctrine.effect == null or doctrine.value == null:
		# Código salvo não existe mais no catálogo atual (ex: save de uma
		# versão anterior do jogo com bancos diferentes) — mais seguro
		# tratar como "sem Doutrina" do que travar com uma referência nula.
		return null

	return doctrine


static func _find_by_code(bank: Array, code: String) -> Variant:
	for entry: Variant in bank:
		if entry.code == code:
			return entry
	return null


static func _commander_to_dict(commander: CommanderResource) -> Dictionary:
	return {
		"instance_id": commander.instance_id,
		"ownership_status": commander.ownership_status,
		"administrative_state": commander.administrative_state,
		"commander_name": commander.commander_name,
		"epithet": commander.epithet,
		"home_kingdom": commander.home_kingdom,
		"serving_kingdom": commander.serving_kingdom,
		"faction": commander.faction,
		"accumulated_xp": commander.accumulated_xp,
		"training_accumulated_xp": commander.training_accumulated_xp,
		"training_cycle_started_unix": commander.training_cycle_started_unix,
		"commissioned_at_unix": commander.commissioned_at_unix,
		"retired_at_unix": commander.retired_at_unix,
		"retirement_type": commander.retirement_type,
		"retirement_benefit": commander.retirement_benefit,
		"total_battles": commander.total_battles,
		"doctrine": _doctrine_to_dict(commander.doctrine),
		"total_victories": commander.total_victories,
		"total_draws": commander.total_draws,
		"battle_log": commander.battle_log.duplicate(true),
		"honorific_title": commander.honorific_title,
	}


## Mesma coisa que _commander_to_dict(), mas devolve null para Slots
## vazios (commander == null) — usada com Array.map() em
## recruitment_center_slots, onde alguns Slots não têm Candidato
## nenhum ainda. Existe como função nomeada (em vez de lambda inline)
## porque uma lambda multi-linha dentro de um literal de Dictionary
## multi-linha confundia o parser do GDScript quanto ao nível de
## indentação esperado.
static func _commander_to_dict_or_null(commander: CommanderResource) -> Variant:
	if commander != null:
		return _commander_to_dict(commander)
	return null


static func _commanders_to_array(commanders: Array[CommanderResource]) -> Array:
	var result: Array = []
	for commander: CommanderResource in commanders:
		result.append(_commander_to_dict(commander))
	return result


static func _card_to_dict(card: CardResource) -> Dictionary:
	return {
		"instance_id": card.instance_id,
		"ownership_status": card.ownership_status,
		"last_removed_from_army_unix": card.last_removed_from_army_unix,
		"card_name": card.card_name,
		"faction": card.faction,
		"card_class": card.card_class,
		"card_type": card.card_type,
		"rarity": card.rarity,
		"tier": card.tier,
		"atk": card.atk,
		"hp": card.hp,
		"esc": card.esc,
		"tier_1_trait_name": card.tier_1_trait_name,
		"tier_2_atk_increment": card.tier_2_atk_increment,
		"tier_2_hp_increment": card.tier_2_hp_increment,
		"tier_2_esc_increment": card.tier_2_esc_increment,
		"tier_3_ability_name": card.tier_3_ability_name,
		"tier_4_atk_increment": card.tier_4_atk_increment,
		"tier_4_hp_increment": card.tier_4_hp_increment,
		"tier_4_esc_increment": card.tier_4_esc_increment,
		"tier_5_ability_name": card.tier_5_ability_name,
	}


static func _cards_to_array(cards: Array[CardResource]) -> Array:
	var result: Array = []
	for card: CardResource in cards:
		result.append(_card_to_dict(card))
	return result


static func _army_to_dict(army: Army) -> Dictionary:
	var formations_dict: Dictionary = {}
	for formation_name: String in army.formations:
		formations_dict[formation_name] = _cards_to_array(army.formations[formation_name])

	var commander_data: Variant = null
	if army.commander != null:
		commander_data = _commander_to_dict(army.commander)

	return {
		"army_name": army.army_name,
		"commander": commander_data,
		"cards": _cards_to_array(army.cards),
		"formations": formations_dict,
		"formation_priority": army.formation_priority.duplicate(),
		"max_energy": army.max_energy,
		"current_energy": army.current_energy,
		"last_energy_sync_unix": army.last_energy_sync_unix,
	}


static func _armies_to_array(armies: Array[Army]) -> Array:
	var result: Array = []
	for army: Army in armies:
		result.append(_army_to_dict(army))
	return result


## Squads são salvos pela posição do Exército dentro de Kingdom.armies
## (não pelo nome) — o nome do Exército é opcional e pode nem estar
## definido (vários Exércitos sem nome custom colidiriam se o vínculo
## fosse por nome); a posição na lista é sempre única.
static func _squads_to_array(squads: Array[Squad], all_armies: Array[Army]) -> Array:
	var result: Array = []
	for squad: Squad in squads:
		var army_indices: Array = []
		for army: Army in squad.armies:
			army_indices.append(all_armies.find(army))
		result.append({
			"army_indices": army_indices,
			"active_index": squad.active_index,
		})
	return result


static func _offers_to_array(offers: Array[RecruitmentOffer]) -> Array:
	var result: Array = []
	for offer: RecruitmentOffer in offers:
		result.append({
			"commander": _commander_to_dict(offer.commander),
			"created_at_unix": offer.created_at_unix,
		})
	return result


static func _mina_to_dict(mina: Mina, all_armies: Array[Army]) -> Dictionary:
	var reference_commander_dict: Dictionary = {}
	if mina.reference_commander != null:
		reference_commander_dict = {
			"commander_name": mina.reference_commander.commander_name,
			"faction": mina.reference_commander.faction,
		}
	var guarnicao_index: int = -1
	if mina.guarnicao_army != null:
		guarnicao_index = all_armies.find(mina.guarnicao_army)
	return {
		"adjacent_fase": mina.adjacent_fase,
		"faction": mina.faction,
		"conquered": mina.conquered,
		"structure_level": mina.structure_level,
		"region": mina.region,
		"reference_card_names": mina.reference_cards.map(func(c: CardResource) -> String: return c.card_name),
		"reference_commander": reference_commander_dict,
		"cycle_started_unix": mina.cycle_started_unix,
		"cycle_efficiency": mina.cycle_efficiency,
		"auto_renew_enabled": mina.auto_renew_enabled,
		"efficiency_permutation_order": mina.efficiency_permutation_order.duplicate(),
		"efficiency_blocks_completed": mina.efficiency_blocks_completed,
		"efficiency_wins": mina.efficiency_wins,
		"efficiency_ties": mina.efficiency_ties,
		"efficiency_losses": mina.efficiency_losses,
		"guarnicao_army_index": guarnicao_index,
		"last_production_credit_unix": mina.last_production_credit_unix,
	}


static func _mines_to_array(mines: Array[Mina], all_armies: Array[Army]) -> Array:
	var result: Array = []
	for mina: Mina in mines:
		result.append(_mina_to_dict(mina, all_armies))
	return result


static func _territory_mines_to_dict(territory_mines: Dictionary, all_armies: Array[Army]) -> Dictionary:
	var result: Dictionary = {}
	for territory_id: String in territory_mines:
		result[territory_id] = _mines_to_array(territory_mines[territory_id], all_armies)
	return result


# ------------------------------------------------------------------
# Dictionary -> Kingdom
# ------------------------------------------------------------------

static func _dict_to_kingdom(data: Dictionary, kingdom: Kingdom) -> void:
	kingdom.energy_nucleus_level = data.get("energy_nucleus_level", 1)
	kingdom.next_card_instance_id = data.get("next_card_instance_id", 1)
	kingdom.next_commander_instance_id = data.get("next_commander_instance_id", 1)
	kingdom.capital_level = data.get("capital_level", 1)
	kingdom.command_center_level = data.get("command_center_level", 1)
	# maxi(1, ...): garante o mínimo da Exceção Inicial mesmo pra saves
	# gravados antes dessa regra existir (que teriam 0 salvo).
	kingdom.cargo_ativo_activated = maxi(1, data.get("cargo_ativo_activated", 1))
	kingdom.vaga_reserva_activated = maxi(1, data.get("vaga_reserva_activated", 1))
	kingdom.daily_combat_xp_log = data.get("daily_combat_xp_log", {}).duplicate()
	kingdom.training_current_day = data.get("training_current_day", -1)
	kingdom.last_daily_average_xp = data.get("last_daily_average_xp", 0)

	var recruitment_slots: Array[CommanderResource] = []
	for entry in data.get("recruitment_center_slots", []):
		recruitment_slots.append(_dict_to_commander(entry) if entry != null else null)
	kingdom.recruitment_center_slots = recruitment_slots
	kingdom.recruitment_center_cycle_end_unix = data.get("recruitment_center_cycle_end_unix", 0)
	var history: Array[Dictionary] = []
	for entry in data.get("commissioning_history", []):
		history.append(entry as Dictionary)
	kingdom.commissioning_history = history
	kingdom.legacy_i_xp_bonus_percent = data.get("legacy_i_xp_bonus_percent", 0.0)
	kingdom.legacy_administrative_retirees = data.get("legacy_administrative_retirees", 0)
	kingdom.legacy_v_bonus_xp = data.get("legacy_v_bonus_xp", 0.0)
	kingdom.legacy_v_bonus_resources = data.get("legacy_v_bonus_resources", 0.0)
	kingdom.legacy_v_bonus_fragments = data.get("legacy_v_bonus_fragments", 0.0)
	kingdom.military_doctrine = data.get("military_doctrine", {}).duplicate(true)
	kingdom.academy_level = data.get("academy_level", 1)
	# Compatibilidade com saves anteriores a esta correção, em que o
	# Depósito era 3 construções separadas: usa o maior dos 3 níveis
	# antigos como ponto de partida (nunca perde progresso do jogador).
	if data.has("deposito_level"):
		kingdom.deposito_level = data.get("deposito_level", 1)
	else:
		kingdom.deposito_level = max(
			data.get("fundicao_level", 1),
			data.get("camara_arcana_level", 1),
			data.get("santuario_vital_level", 1)
		)
	kingdom.account_xp = data.get("account_xp", 0)
	kingdom.structural_xp_unlocked = data.get("structural_xp_unlocked", {}).duplicate()
	var academy_task_pool: Array[AcademyTask] = _academy_task_pool_from_array(data.get("academy_task_pool", []))
	kingdom.favorite_card_names = data.get("favorite_card_names", {}).duplicate()
	kingdom.starter_kit_used = data.get("starter_kit_used", false)
	kingdom.new_card_names = data.get("new_card_names", {}).duplicate()
	kingdom.academy_artifices = _dict_to_academy_masters(data.get("academy_artifices", []), academy_task_pool)
	kingdom.academy_metamorfos = _dict_to_academy_masters(data.get("academy_metamorfos", []), academy_task_pool)
	var pending_chain_tasks: Array[AcademyTask] = []
	for task_id in data.get("academy_pending_chain_task_ids", []):
		pending_chain_tasks.append(academy_task_pool[task_id])
	kingdom.academy_pending_chain_tasks = pending_chain_tasks
	kingdom.generation_points = data.get("generation_points", 0)
	kingdom.raw_resources = data.get("raw_resources", {}).duplicate()

	kingdom.commanders.clear()
	for entry in data.get("commanders", []):
		kingdom.commanders.append(_dict_to_commander(entry))

	kingdom.cards.clear()
	for entry in data.get("cards", []):
		kingdom.cards.append(_dict_to_card(entry))

	kingdom.armies.clear()
	for entry in data.get("armies", []):
		kingdom.armies.append(_dict_to_army(entry))

	kingdom.squads.clear()
	for entry in data.get("squads", []):
		kingdom.squads.append(_dict_to_squad(entry, kingdom.armies))

	kingdom.resources = data.get("resources", {}).duplicate()
	kingdom.regional_commander_registry.import_data(data.get("regional_commander_registry", {}))

	kingdom.pending_recruitment_offers.clear()
	for entry in data.get("pending_recruitment_offers", []):
		# Compatibilidade com saves anteriores a esta Sprint, em que a
		# oferta era salva apenas como o Comandante (sem timestamp):
		# assume-se created_at_unix = 0, o que a torna imediatamente
		# expirável na próxima purge_expired_offers() — comportamento
		# aceitável, já que esses saves nunca tiveram um relógio real
		# rodando para justificar preservar a oferta.
		var commander_data: Dictionary = entry.get("commander", entry)
		var created_at: int = entry.get("created_at_unix", 0)
		kingdom.pending_recruitment_offers.append(RecruitmentOffer.new(_dict_to_commander(commander_data), created_at))

	kingdom.expired_recruitment_notifications.clear()
	for name: String in data.get("expired_recruitment_notifications", []):
		kingdom.expired_recruitment_notifications.append(name)

	kingdom.initial_mines.clear()
	for entry in data.get("initial_mines", []):
		kingdom.initial_mines.append(_dict_to_mina(entry, kingdom.armies))

	kingdom.territory_mines.clear()
	var territory_mines_data: Dictionary = data.get("territory_mines", {})
	for territory_id: String in territory_mines_data:
		var mines: Array[Mina] = []
		for entry in territory_mines_data[territory_id]:
			mines.append(_dict_to_mina(entry, kingdom.armies))
		kingdom.territory_mines[territory_id] = mines

	kingdom.progress_flags = data.get("progress_flags", {}).duplicate()


static func _dict_to_commander(data: Dictionary) -> CommanderResource:
	var commander := CommanderResource.new()
	commander.instance_id = data.get("instance_id", 0)
	commander.ownership_status = data.get("ownership_status", CommanderResource.OwnershipStatus.LIVRE)
	commander.administrative_state = data.get("administrative_state", CommanderResource.AdministrativeState.RESERVE)
	commander.commander_name = data.get("commander_name", "")
	commander.epithet = data.get("epithet", "")
	commander.home_kingdom = data.get("home_kingdom", "")
	commander.serving_kingdom = data.get("serving_kingdom", "")
	commander.faction = data.get("faction", "")
	commander.accumulated_xp = data.get("accumulated_xp", 0)
	commander.training_accumulated_xp = data.get("training_accumulated_xp", 0)
	commander.training_cycle_started_unix = data.get("training_cycle_started_unix", 0)
	commander.commissioned_at_unix = data.get("commissioned_at_unix", 0)
	commander.retired_at_unix = data.get("retired_at_unix", 0)
	commander.retirement_type = data.get("retirement_type", "")
	commander.retirement_benefit = data.get("retirement_benefit", "")
	commander.total_battles = data.get("total_battles", 0)
	commander.doctrine = _dict_to_doctrine(data.get("doctrine", {}))
	commander.total_victories = data.get("total_victories", 0)
	commander.total_draws = data.get("total_draws", 0)
	var battle_log: Array[Dictionary] = []
	for entry in data.get("battle_log", []):
		battle_log.append(entry as Dictionary)
	commander.battle_log = battle_log
	commander.honorific_title = data.get("honorific_title", "")
	return commander


static func _dict_to_card(data: Dictionary) -> CardResource:
	var card := CardResource.new()
	card.instance_id = data.get("instance_id", 0)
	card.ownership_status = data.get("ownership_status", CardResource.OwnershipStatus.LIVRE)
	card.last_removed_from_army_unix = data.get("last_removed_from_army_unix", 0)
	card.card_name = data.get("card_name", "")
	card.faction = data.get("faction", "")
	card.card_class = data.get("card_class", "")
	card.card_type = data.get("card_type", "")
	card.rarity = data.get("rarity", "")
	card.tier = data.get("tier", 1)
	card.atk = data.get("atk", 0)
	card.hp = data.get("hp", 0)
	card.esc = data.get("esc", 0)
	card.tier_1_trait_name = data.get("tier_1_trait_name", "")
	card.tier_2_atk_increment = data.get("tier_2_atk_increment", 0)
	card.tier_2_hp_increment = data.get("tier_2_hp_increment", 0)
	card.tier_2_esc_increment = data.get("tier_2_esc_increment", 0)
	card.tier_3_ability_name = data.get("tier_3_ability_name", "")
	card.tier_4_atk_increment = data.get("tier_4_atk_increment", 0)
	card.tier_4_hp_increment = data.get("tier_4_hp_increment", 0)
	card.tier_4_esc_increment = data.get("tier_4_esc_increment", 0)
	card.tier_5_ability_name = data.get("tier_5_ability_name", "")
	return card


## Coleta TODAS as AcademyTask alcançáveis do Reino — nas filas dos
## Mestres, em academy_pending_chain_tasks, e (recursivamente) através
## de depends_on/output_target. Uma tarefa "pai" aguardando pode
## referenciar uma tarefa "filha" que não está em NENHUMA fila — só
## existe através desse ponteiro enquanto aguarda ser concluída.
static func _collect_all_academy_tasks(kingdom: Kingdom) -> Array[AcademyTask]:
	var all_tasks: Array[AcademyTask] = []
	var visited: Dictionary = {}

	var to_visit: Array[AcademyTask] = []
	for master: AcademyMaster in kingdom.academy_artifices:
		to_visit.append_array(master.queue)
	for master: AcademyMaster in kingdom.academy_metamorfos:
		to_visit.append_array(master.queue)
	to_visit.append_array(kingdom.academy_pending_chain_tasks)

	while not to_visit.is_empty():
		var task: AcademyTask = to_visit.pop_back()
		if visited.has(task):
			continue
		visited[task] = true
		all_tasks.append(task)
		to_visit.append_array(task.depends_on)
		if task.output_target != null:
			to_visit.append(task.output_target)

	return all_tasks


static func _academy_task_to_dict(task: AcademyTask, task_ids: Dictionary) -> Dictionary:
	var depends_on_ids: Array = []
	for dependency: AcademyTask in task.depends_on:
		depends_on_ids.append(task_ids[dependency])

	return {
		"kind": task.kind,
		"target_card_name": task.target_card_name,
		"target_tier": task.target_tier,
		"faction": task.faction,
		"quantity": task.quantity,
		"duration_seconds": task.duration_seconds,
		"start_unix": task.start_unix,
		"end_unix": task.end_unix,
		"reserved_fragments": task.reserved_fragments,
		"reserved_faction": task.reserved_faction,
		"reserved_cards": task.reserved_cards.map(func(c: CardResource) -> Dictionary: return _card_to_dict(c)),
		"is_done": task.is_done,
		"depends_on_ids": depends_on_ids,
		"output_target_id": task_ids[task.output_target] if task.output_target != null else -1,
	}


## Só os campos escalares — depends_on/output_target são ligados depois,
## por _academy_task_pool_from_array(), quando todas as tarefas do pool
## já existem (não dá pra referenciar uma tarefa que ainda não foi
## criada).
static func _dict_to_academy_task_scalars(data: Dictionary) -> AcademyTask:
	var task := AcademyTask.new()
	task.kind = data.get("kind", AcademyTask.Kind.CREATE_COMMON)
	task.target_card_name = data.get("target_card_name", "")
	task.target_tier = data.get("target_tier", 1)
	task.faction = data.get("faction", "")
	task.quantity = data.get("quantity", 1)
	task.duration_seconds = data.get("duration_seconds", 0)
	task.start_unix = data.get("start_unix", 0)
	task.end_unix = data.get("end_unix", 0)
	task.reserved_fragments = data.get("reserved_fragments", 0)
	task.reserved_faction = data.get("reserved_faction", "")
	var reserved_cards: Array[CardResource] = []
	for card_entry in data.get("reserved_cards", []):
		reserved_cards.append(_dict_to_card(card_entry))
	task.reserved_cards = reserved_cards
	task.is_done = data.get("is_done", false)
	return task


## Serializa o pool de tarefas inteiro do Reino num único array
## indexado (índice = ID temporário, só válido dentro deste save).
static func _academy_task_pool_to_array(kingdom: Kingdom, task_ids: Dictionary) -> Array:
	var all_tasks: Array[AcademyTask] = _collect_all_academy_tasks(kingdom)
	var result: Array = []
	for task: AcademyTask in all_tasks:
		result.append(_academy_task_to_dict(task, task_ids))
	return result


## Reconstrói o pool de tarefas em duas passadas: (1) cria todas as
## tarefas com os campos escalares; (2) liga depends_on/output_target
## usando os IDs salvos, agora que todas já existem. O índice do array
## retornado corresponde exatamente ao ID usado no save.
static func _academy_task_pool_from_array(data: Array) -> Array[AcademyTask]:
	var tasks: Array[AcademyTask] = []
	for entry in data:
		tasks.append(_dict_to_academy_task_scalars(entry))

	for i in range(data.size()):
		var entry: Dictionary = data[i]
		var task: AcademyTask = tasks[i]
		for dependency_id in entry.get("depends_on_ids", []):
			task.depends_on.append(tasks[dependency_id])
		var output_id: int = entry.get("output_target_id", -1)
		if output_id != -1:
			task.output_target = tasks[output_id]

	return tasks


static func _academy_master_to_dict(master: AcademyMaster, task_ids: Dictionary) -> Dictionary:
	var queue_ids: Array = []
	for task: AcademyTask in master.queue:
		queue_ids.append(task_ids[task])

	return {
		"kind": master.kind,
		"queue_capacity": master.queue_capacity,
		"queue_task_ids": queue_ids,
	}


static func _dict_to_academy_master(data: Dictionary, task_pool: Array[AcademyTask]) -> AcademyMaster:
	var master := AcademyMaster.new()
	master.kind = data.get("kind", AcademyMaster.Kind.ARTIFICE)
	master.queue_capacity = data.get("queue_capacity", 1)
	var queue: Array[AcademyTask] = []
	for task_id in data.get("queue_task_ids", []):
		queue.append(task_pool[task_id])
	master.queue = queue
	return master


static func _academy_masters_to_array(masters: Array[AcademyMaster], task_ids: Dictionary) -> Array:
	var result: Array = []
	for master: AcademyMaster in masters:
		result.append(_academy_master_to_dict(master, task_ids))
	return result


static func _dict_to_academy_masters(data: Array, task_pool: Array[AcademyTask]) -> Array[AcademyMaster]:
	var result: Array[AcademyMaster] = []
	for entry in data:
		result.append(_dict_to_academy_master(entry, task_pool))
	return result


static func _dict_to_cards_array(data: Array) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for entry in data:
		result.append(_dict_to_card(entry))
	return result


static func _dict_to_army(data: Dictionary) -> Army:
	var army := Army.new()
	army.army_name = data.get("army_name", "")

	var commander_data: Variant = data.get("commander", null)
	if commander_data != null:
		army.commander = _dict_to_commander(commander_data)

	army.cards = _dict_to_cards_array(data.get("cards", []))

	var formations_data: Dictionary = data.get("formations", {})
	for formation_name: String in formations_data:
		army.formations[formation_name] = _dict_to_cards_array(formations_data[formation_name])

	var priority: Array = data.get("formation_priority", [])
	if not priority.is_empty():
		army.formation_priority.assign(priority)

	army.max_energy = data.get("max_energy", 0)
	army.current_energy = data.get("current_energy", 0)
	army.last_energy_sync_unix = data.get("last_energy_sync_unix", 0)
	return army


static func _dict_to_squad(data: Dictionary, all_armies: Array[Army]) -> Squad:
	var army_indices: Array = data.get("army_indices", [])
	var squad_armies: Array[Army] = []
	for index in army_indices:
		if index >= 0 and index < all_armies.size():
			squad_armies.append(all_armies[index])

	var squad := Squad.new(squad_armies)
	squad.active_index = data.get("active_index", 0)
	return squad


static func _dict_to_mina(data: Dictionary, all_armies: Array[Army]) -> Mina:
	var mina := Mina.new(data.get("adjacent_fase", -1), data.get("faction", ""))
	mina.conquered = data.get("conquered", false)
	mina.structure_level = data.get("structure_level", 1)
	mina.region = data.get("region", 0)

	var card_names: Array = data.get("reference_card_names", [])
	if not card_names.is_empty():
		var cards: Array[CardResource] = []
		for card_name: String in card_names:
			cards.append(GameDatabase.get_card(card_name))
		var commander_data: Dictionary = data.get("reference_commander", {})
		var commander: CommanderResource = null
		if not commander_data.is_empty():
			commander = CommanderResource.new()
			commander.commander_name = commander_data.get("commander_name", "")
			commander.faction = commander_data.get("faction", "")
		mina.freeze_reference_formation(cards, commander)

	mina.cycle_started_unix = data.get("cycle_started_unix", 0)
	mina.cycle_efficiency = data.get("cycle_efficiency", -1.0)
	mina.auto_renew_enabled = data.get("auto_renew_enabled", false)
	var efficiency_permutation_order: Array[int] = []
	for index in data.get("efficiency_permutation_order", []):
		efficiency_permutation_order.append(int(index))
	mina.efficiency_permutation_order = efficiency_permutation_order
	mina.efficiency_blocks_completed = data.get("efficiency_blocks_completed", 0)
	mina.efficiency_wins = data.get("efficiency_wins", 0)
	mina.efficiency_ties = data.get("efficiency_ties", 0)
	mina.efficiency_losses = data.get("efficiency_losses", 0)
	# efficiency_pending_task_ids/chunk_results nunca persistem —
	# tarefas do WorkerThreadPool são estado de memória, não
	# sobrevivem a fechar o jogo. Se havia um bloco em andamento no
	# momento do save, ele simplesmente é reiniciado do zero (mesmo
	# índice de bloco, novo lote de tarefas) na próxima sincronização.
	mina.last_production_credit_unix = data.get("last_production_credit_unix", 0)

	var guarnicao_index: int = data.get("guarnicao_army_index", -1)
	if guarnicao_index >= 0 and guarnicao_index < all_armies.size():
		mina.assign_guarnicao(all_armies[guarnicao_index])

	return mina
