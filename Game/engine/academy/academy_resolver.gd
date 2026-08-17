class_name AcademyResolver
extends RefCounted
## AcademyResolver
##
## Orquestra a Academia (ACADEMY.md): Artífices produzem Cartas Tier I
## usando Fragmentos; Metamorfos fazem Aprimoramento (3 cópias do mesmo
## Tier -> 1 do Tier seguinte). Kingdom nunca decide isso sozinho —
## este resolver verifica as condições, reserva os recursos e programa
## a tarefa na fila do Mestre certo.
##
## Escopo implementado (decisões confirmadas com o dono do projeto):
## - Cartas Comuns: produzidas exclusivamente por Fragmentos.
## - Cartas Rara/Épica/Lendária: produzidas por combinação de 3 cartas
##   Tier I específicas e nomeadas (LIBRARY_CONTENT.md via
##   CardResource.recipe_ingredients) — nunca uma fórmula genérica.
## - Produção Automática de cadeia completa (ACADEMY.md): pedir
##   diretamente uma carta superior monta sozinha toda a árvore de
##   dependências — reaproveita cópias Tier I já existentes no
##   inventário, produz o resto com Fragmento, e agenda cada etapa
##   automaticamente, em paralelo quando houver Mestre livre.
## - Origem dos Ingredientes: "Aproveitar Inventário" (padrão — usa o
##   que já existe), "Preservar Inventário" (ignora cópias existentes
##   de propósito, produz tudo do zero) e "Editar Receita" (escolhe a
##   origem de CADA ingrediente individualmente, por nome — tem
##   prioridade sobre a escolha global).
## - Modo de Produção: "prioritario" (usa todos os Mestres livres,
##   termina o mais rápido possível — padrão) e "conservador" (usa só
##   1 Mestre por vez para uma mesma solicitação, deixando os demais
##   livres para outras produções ao mesmo tempo).
## - Previsão da Produção: simula o plano inteiro (custo, o que será
##   produzido, o que será reaproveitado, tempo sequencial estimado)
##   sem comprometer nenhum recurso.
## - Reserva tudo-ou-nada: só compromete Fragmentos/cartas depois de
##   confirmar que o plano inteiro é pagável — nunca deixa uma cadeia
##   pela metade por falta de recurso.
## - Cancelar uma tarefa antes dela começar devolve integralmente o que
##   foi reservado.
## - Pedidos em lote (quantidade > 1) são suportados.
## - A Academia é única do Reino, não por Facção.
##
## NÃO implementado ainda (fora do escopo desta entrega):
## - Pedidos em lote (quantity > 1) para cartas com receita constroem
##   "quantity" árvores de dependência independentes, uma por cópia —
##   não junta irmãos idênticos entre cópias diferentes num único
##   Mestre. Correto, só não é o mais eficiente possível — conferido
##   contra ACADEMY.md: não há nenhuma regra documentada exigindo esse
##   compartilhamento, então este comportamento já está de acordo com
##   a documentação (não é uma lacuna a fechar).
## - "Previsão do tempo real de conclusão" (considerando paralelismo
##   entre Mestres) — o campo "sequential_time_seconds" da previsão é
##   a soma de todas as etapas em sequência (um teto), não o tempo real
##   de parede que o Modo Prioritário conseguiria com vários Mestres
##   livres ao mesmo tempo.


## Solicita a produção de "quantity" cópias de "card_name" — Comum,
## direto por Fragmento; Rara/Épica/Lendária, montando sozinho toda a
## cadeia de dependências necessária.
##
## "preserve_inventory": true = ignora cópias já existentes de
## propósito, produz tudo do zero (padrão false = "Aproveitar Inventário").
## "overrides": Dictionary[String, String] mapeando nome de carta ->
## "existing" (força usar uma cópia já existente; falha se não houver)
## ou "produce" (força produzir mesmo tendo cópia disponível) — tem
## prioridade sobre "preserve_inventory" para aquele ingrediente
## específico. Aplica-se em qualquer profundidade da árvore.
## "mode": "prioritario" (padrão, usa todos os Mestres livres) ou
## "conservador" (usa só 1 Mestre por vez para esta solicitação).
##
## Retorna {"success": bool, "reason": String}. "reason": "invalid_card",
## "insufficient_fragments", "no_artifice_available",
## "forced_existing_unavailable" (um "overrides" pediu "existing" para
## um ingrediente que não existe em nenhuma cópia livre).
static func request_production(
	kingdom: Kingdom,
	card_name: String,
	quantity: int,
	now_unix: int,
	preserve_inventory: bool = false,
	overrides: Dictionary = {},
	mode: String = "prioritario"
) -> Dictionary:
	kingdom.sync_academy_masters()

	var template: CardResource = GameDatabase.get_card(card_name)
	if template == null:
		return {"success": false, "reason": "invalid_card"}

	if template.recipe_ingredients.is_empty():
		return request_common_production(kingdom, card_name, quantity, now_unix)

	# Fase 1 (planejamento, tudo-ou-nada): monta "quantity" árvores de
	# dependência sem comprometer nada ainda.
	var locked: Array[CardResource] = []
	var plans: Array[Dictionary] = []
	var total_fragment_cost: int = 0

	for i in range(quantity):
		var plan: Dictionary = _plan_node(kingdom, card_name, locked, preserve_inventory, overrides)
		plans.append(plan)
		total_fragment_cost += plan["fragment_cost"]

	_unlock_all(locked)

	for plan: Dictionary in plans:
		var missing: String = _find_error(plan)
		if missing != "":
			return {"success": false, "reason": "forced_existing_unavailable", "missing_ingredient": missing}

	if kingdom.get_fragment(template.faction) < total_fragment_cost:
		return {"success": false, "reason": "insufficient_fragments"}

	# Fase 2 (execução): agora sim, compromete Fragmentos e cartas de
	# verdade, e materializa as tarefas.
	kingdom.spend_fragment(template.faction, total_fragment_cost)
	for plan: Dictionary in plans:
		_materialize_plan(kingdom, plan, now_unix, mode)

	return {"success": true, "reason": ""}


## Simula "request_production" sem comprometer nada — nem Fragmentos,
## nem cartas do inventário. Retorna um resumo:
## {"valid": bool, "reason": String (se !valid), "total_fragment_cost": int,
## "affordable": bool, "faction": String, "new_cards_to_produce": Dictionary
## (nome da carta -> quantas cópias novas serão produzidas, incluindo
## etapas intermediárias), "existing_cards_to_reuse": Array[String]
## (nomes das cópias do inventário que seriam consumidas),
## "sequential_time_seconds": int (soma de todas as etapas em
## sequência — um teto, não o tempo real com Mestres em paralelo)}.
static func preview_production(kingdom: Kingdom, card_name: String, quantity: int, preserve_inventory: bool = false, overrides: Dictionary = {}) -> Dictionary:
	kingdom.sync_academy_masters()

	var template: CardResource = GameDatabase.get_card(card_name)
	if template == null:
		return {"valid": false, "reason": "invalid_card"}

	if template.recipe_ingredients.is_empty():
		var cost: int = AcademyEconomy.fragment_cost("Comum") * quantity
		var time: int = AcademyEconomy.creation_time_seconds("Comum", kingdom.academy_level) * quantity
		return {
			"valid": true,
			"reason": "",
			"total_fragment_cost": cost,
			"affordable": kingdom.get_fragment(template.faction) >= cost,
			"faction": template.faction,
			"new_cards_to_produce": {card_name: quantity},
			"existing_cards_to_reuse": [],
			"sequential_time_seconds": time,
		}

	var locked: Array[CardResource] = []
	var plans: Array[Dictionary] = []
	var total_cost: int = 0

	for i in range(quantity):
		var plan: Dictionary = _plan_node(kingdom, card_name, locked, preserve_inventory, overrides)
		plans.append(plan)
		total_cost += plan["fragment_cost"]

	_unlock_all(locked)

	for plan: Dictionary in plans:
		var missing: String = _find_error(plan)
		if missing != "":
			return {"valid": false, "reason": "forced_existing_unavailable", "missing_ingredient": missing}

	var produce_counts: Dictionary = {}
	var reuse_names: Array = []
	var total_time: int = 0
	for plan: Dictionary in plans:
		_summarize_plan(plan, produce_counts, reuse_names)
		total_time += _sequential_time(plan, kingdom.academy_level)

	return {
		"valid": true,
		"reason": "",
		"total_fragment_cost": total_cost,
		"affordable": kingdom.get_fragment(template.faction) >= total_cost,
		"faction": template.faction,
		"new_cards_to_produce": produce_counts,
		"existing_cards_to_reuse": reuse_names,
		"sequential_time_seconds": total_time,
	}


## Solicita a produção de "quantity" cópias de uma Carta Comum
## específica, usando Fragmentos da Facção dela. Retorna
## {"success": bool, "reason": String}. "reason": "invalid_card"
## (não existe/não é Comum), "insufficient_fragments", "no_artifice_available".
static func request_common_production(kingdom: Kingdom, card_name: String, quantity: int, now_unix: int) -> Dictionary:
	kingdom.sync_academy_masters()

	var template: CardResource = GameDatabase.get_card(card_name)
	if template == null or template.rarity != "Comum":
		return {"success": false, "reason": "invalid_card"}

	var cost: int = AcademyEconomy.fragment_cost("Comum") * quantity
	if kingdom.get_fragment(template.faction) < cost:
		return {"success": false, "reason": "insufficient_fragments"}

	var master: AcademyMaster = _find_free_master(kingdom.academy_artifices)
	if master == null:
		return {"success": false, "reason": "no_artifice_available"}

	kingdom.spend_fragment(template.faction, cost)

	var task := AcademyTask.new()
	task.kind = AcademyTask.Kind.CREATE_COMMON
	task.target_card_name = card_name
	task.faction = template.faction
	task.quantity = quantity
	task.reserved_fragments = cost
	task.reserved_faction = template.faction

	var duration: int = AcademyEconomy.creation_time_seconds("Comum", kingdom.academy_level) * quantity
	_enqueue(master, task, duration, now_unix)

	return {"success": true, "reason": ""}


## Solicita o Aprimoramento de "quantity" cópias de "card_name" do
## "current_tier" para o Tier seguinte — consome 3×quantity cópias
## idênticas, Livres, daquele Tier exato. Retorna
## {"success": bool, "reason": String}. "reason": "invalid_tier"
## (current_tier < 1 ou >= 5), "insufficient_copies", "no_metamorfo_available".
static func request_upgrade(kingdom: Kingdom, card_name: String, current_tier: int, quantity: int, now_unix: int) -> Dictionary:
	kingdom.sync_academy_masters()

	if current_tier < 1 or current_tier >= 5:
		return {"success": false, "reason": "invalid_tier"}

	var template: CardResource = GameDatabase.get_card(card_name)
	if template == null:
		return {"success": false, "reason": "invalid_card"}

	var needed: int = 3 * quantity
	var candidates: Array[CardResource] = []
	for card: CardResource in kingdom.cards:
		if card.card_name == card_name and card.tier == current_tier and card.ownership_status == CardResource.OwnershipStatus.LIVRE:
			candidates.append(card)
			if candidates.size() >= needed:
				break

	if candidates.size() < needed:
		return {"success": false, "reason": "insufficient_copies"}

	var master: AcademyMaster = _find_free_master(kingdom.academy_metamorfos)
	if master == null:
		return {"success": false, "reason": "no_metamorfo_available"}

	for card: CardResource in candidates:
		kingdom.remove_card(card)

	var task := AcademyTask.new()
	task.kind = AcademyTask.Kind.UPGRADE
	task.target_card_name = card_name
	task.target_tier = current_tier + 1
	task.faction = template.faction
	task.quantity = quantity
	task.reserved_cards = candidates

	var duration: int = AcademyEconomy.upgrade_time_seconds(current_tier + 1, template.rarity, kingdom.academy_level) * quantity
	_enqueue(master, task, duration, now_unix)

	return {"success": true, "reason": ""}


## Cancela "task" se ela ainda não tiver começado. Devolve
## integralmente o que foi reservado. Procura tanto na fila de
## "master" quanto na lista de tarefas pendentes da cadeia automática
## (nesse caso "master" pode ser null). Retorna false se a tarefa já
## começou ou não foi encontrada em nenhum dos dois lugares.
static func cancel_task(kingdom: Kingdom, master: AcademyMaster, task: AcademyTask) -> bool:
	if task.has_started():
		return false

	var found: bool = false
	if master != null and master.queue.has(task):
		master.queue.erase(task)
		found = true
	elif kingdom.academy_pending_chain_tasks.has(task):
		kingdom.academy_pending_chain_tasks.erase(task)
		found = true

	if not found:
		return false

	if task.reserved_fragments > 0:
		kingdom.add_fragment(task.reserved_faction, task.reserved_fragments)
	for card: CardResource in task.reserved_cards:
		card.ownership_status = CardResource.OwnershipStatus.LIVRE
		kingdom.add_card(card)

	return true


## Avança o tempo de todos os Mestres da Academia: conclui tarefas cujo
## prazo já passou (credita a carta produzida/aprimorada) e inicia a
## próxima da fila automaticamente. Também tenta agendar tarefas
## pendentes da cadeia automática cujas dependências já concluíram.
## Chamado por GameRuntime.sync().
static func sync(kingdom: Kingdom, now_unix: int) -> void:
	for master: AcademyMaster in kingdom.academy_artifices:
		_sync_master(kingdom, master, now_unix)
	for master: AcademyMaster in kingdom.academy_metamorfos:
		_sync_master(kingdom, master, now_unix)
	_advance_pending_chain(kingdom, now_unix)


static func _sync_master(kingdom: Kingdom, master: AcademyMaster, now_unix: int) -> void:
	while not master.queue.is_empty() and master.queue[0].is_complete(now_unix):
		var task: AcademyTask = master.queue.pop_front()
		_complete_task(kingdom, task)

	if not master.queue.is_empty() and not master.queue[0].has_started():
		_start_task(master.queue[0], now_unix)


static func _advance_pending_chain(kingdom: Kingdom, now_unix: int) -> void:
	var still_pending: Array[AcademyTask] = []

	for task: AcademyTask in kingdom.academy_pending_chain_tasks:
		var deps_done: bool = true
		for dependency: AcademyTask in task.depends_on:
			if not dependency.is_done:
				deps_done = false
				break

		if not deps_done:
			still_pending.append(task)
			continue

		var master: AcademyMaster = _find_free_master(kingdom.academy_artifices)
		if master == null:
			still_pending.append(task)
			continue

		_enqueue(master, task, task.duration_seconds, now_unix)

	kingdom.academy_pending_chain_tasks = still_pending


static func _start_task(task: AcademyTask, now_unix: int) -> void:
	task.start_unix = now_unix
	task.end_unix = now_unix + task.duration_seconds


static func _complete_task(kingdom: Kingdom, task: AcademyTask) -> void:
	match task.kind:
		AcademyTask.Kind.CREATE_COMMON, AcademyTask.Kind.CREATE_RECIPE:
			var template: CardResource = GameDatabase.get_card(task.target_card_name)
			if task.output_target != null:
				var copy: CardResource = kingdom.acquire_card_from_catalog(template)
				kingdom.remove_card(copy)
				task.output_target.reserved_cards.append(copy)
			else:
				for i in range(task.quantity):
					kingdom.acquire_card_from_catalog(template)
			AccountXPResolver.grant_card_obtained(kingdom, task.target_card_name, template.rarity)
		AcademyTask.Kind.UPGRADE:
			for i in range(task.quantity):
				var base_card: CardResource = task.reserved_cards[i * 3]
				var upgraded: CardResource = kingdom.acquire_card_from_catalog(base_card)
				upgraded.tier = task.target_tier
			AccountXPResolver.grant_card_tier_reached(kingdom, task.target_card_name, task.target_tier)

	task.is_done = true


static func _enqueue(master: AcademyMaster, task: AcademyTask, duration: int, now_unix: int) -> void:
	task.duration_seconds = duration
	master.queue.append(task)
	if master.queue.size() == 1:
		_start_task(task, now_unix)


static func _find_free_master(masters: Array[AcademyMaster]) -> AcademyMaster:
	for master: AcademyMaster in masters:
		if master.has_room():
			return master
	return null


static func _find_free_tier1_card(kingdom: Kingdom, card_name: String) -> CardResource:
	for card: CardResource in kingdom.cards:
		if card.card_name == card_name and card.tier == 1 and card.ownership_status == CardResource.OwnershipStatus.LIVRE:
			return card
	return null


## --- Produção Automática: planejamento (fase 1, não compromete nada) ---

## Retorna um "plano" para obter 1 cópia Tier I de "card_name":
## - {"type": "existing", "card": CardResource, "fragment_cost": 0}
## - {"type": "produce_common", "template": CardResource, "fragment_cost": int}
## - {"type": "produce_recipe", "template": CardResource, "fragment_cost": int, "children": Array[Dictionary]}
## - {"type": "error", "fragment_cost": 0, "missing": String} — um
##   "overrides" pediu "existing" para "missing", mas não há cópia livre.
static func _plan_node(kingdom: Kingdom, card_name: String, locked: Array[CardResource], preserve_inventory: bool, overrides: Dictionary) -> Dictionary:
	var forced: String = overrides.get(card_name, "")

	if forced != "produce" and not (forced == "" and preserve_inventory):
		var existing: CardResource = _find_free_tier1_card(kingdom, card_name)
		if existing != null:
			existing.ownership_status = CardResource.OwnershipStatus.EM_EXERCITO
			locked.append(existing)
			return {"type": "existing", "card": existing, "fragment_cost": 0}
		elif forced == "existing":
			return {"type": "error", "fragment_cost": 0, "missing": card_name}

	var template: CardResource = GameDatabase.get_card(card_name)
	if template.recipe_ingredients.is_empty():
		return {"type": "produce_common", "template": template, "fragment_cost": AcademyEconomy.fragment_cost(template.rarity)}

	var children: Array[Dictionary] = []
	var cost: int = 0
	for ingredient_name: String in template.recipe_ingredients:
		var child: Dictionary = _plan_node(kingdom, ingredient_name, locked, preserve_inventory, overrides)
		children.append(child)
		cost += child["fragment_cost"]

	return {"type": "produce_recipe", "template": template, "fragment_cost": cost, "children": children}


static func _find_error(plan: Dictionary) -> String:
	if plan["type"] == "error":
		return plan["missing"]
	if plan.has("children"):
		for child: Dictionary in plan["children"]:
			var found: String = _find_error(child)
			if found != "":
				return found
	return ""


static func _summarize_plan(plan: Dictionary, counts: Dictionary, reuse_names: Array) -> void:
	match plan["type"]:
		"existing":
			reuse_names.append(plan["card"].card_name)
		"produce_common", "produce_recipe":
			var name: String = plan["template"].card_name
			counts[name] = counts.get(name, 0) + 1
			if plan.has("children"):
				for child: Dictionary in plan["children"]:
					_summarize_plan(child, counts, reuse_names)


static func _sequential_time(plan: Dictionary, academy_level: int) -> int:
	match plan["type"]:
		"produce_common", "produce_recipe":
			var t: int = AcademyEconomy.creation_time_seconds(plan["template"].rarity, academy_level)
			if plan.has("children"):
				for child: Dictionary in plan["children"]:
					t += _sequential_time(child, academy_level)
			return t
	return 0


static func _unlock_all(locked: Array[CardResource]) -> void:
	for card: CardResource in locked:
		card.ownership_status = CardResource.OwnershipStatus.LIVRE


## --- Produção Automática: materialização (fase 2, compromete de verdade) ---

static func _materialize_plan(kingdom: Kingdom, plan: Dictionary, now_unix: int, mode: String) -> void:
	match plan["type"]:
		"produce_common":
			var task: AcademyTask = _build_task(plan["template"], AcademyTask.Kind.CREATE_COMMON, kingdom.academy_level)
			_schedule_or_queue(kingdom, task, now_unix)
		"produce_recipe":
			var task: AcademyTask = _build_task(plan["template"], AcademyTask.Kind.CREATE_RECIPE, kingdom.academy_level)
			_materialize_children(kingdom, task, plan, now_unix, mode)
		"existing":
			var card: CardResource = plan["card"]
			card.ownership_status = CardResource.OwnershipStatus.LIVRE
			kingdom.remove_card(card)


## Materializa os 3 filhos de uma tarefa CREATE_RECIPE. No Modo
## Prioritário, cada filho sem dependência é agendado imediatamente
## (usa quantos Mestres livres houver). No Modo Conservador, os filhos
## são encadeados entre si (cada um só começa depois do irmão
## anterior terminar) — nunca usa mais de 1 Mestre por vez para esta
## solicitação, mesmo que outros estejam livres.
static func _materialize_children(kingdom: Kingdom, task: AcademyTask, plan: Dictionary, now_unix: int, mode: String) -> void:
	var ready_now: bool = true
	var previous_sibling: AcademyTask = null

	for child_plan: Dictionary in plan["children"]:
		if child_plan["type"] == "existing":
			var card: CardResource = child_plan["card"]
			card.ownership_status = CardResource.OwnershipStatus.LIVRE
			kingdom.remove_card(card)
			task.reserved_cards.append(card)
			continue

		var child_kind: AcademyTask.Kind = AcademyTask.Kind.CREATE_COMMON if child_plan["type"] == "produce_common" else AcademyTask.Kind.CREATE_RECIPE
		var child_task: AcademyTask = _build_task(child_plan["template"], child_kind, kingdom.academy_level)
		child_task.output_target = task
		task.depends_on.append(child_task)
		ready_now = false

		if mode == "conservador" and previous_sibling != null:
			child_task.depends_on.append(previous_sibling)

		if child_plan["type"] == "produce_recipe":
			_materialize_children(kingdom, child_task, child_plan, now_unix, mode)
		else:
			_try_schedule(kingdom, child_task, now_unix)

		previous_sibling = child_task

	if ready_now:
		_schedule_or_queue(kingdom, task, now_unix)
	else:
		kingdom.academy_pending_chain_tasks.append(task)


## Agenda "task" imediatamente se ela não tiver nenhuma dependência
## pendente; caso contrário, guarda em academy_pending_chain_tasks
## para o próximo sync() tentar de novo.
static func _try_schedule(kingdom: Kingdom, task: AcademyTask, now_unix: int) -> void:
	for dependency: AcademyTask in task.depends_on:
		if not dependency.is_done:
			kingdom.academy_pending_chain_tasks.append(task)
			return
	_schedule_or_queue(kingdom, task, now_unix)


static func _build_task(template: CardResource, kind: AcademyTask.Kind, academy_level: int) -> AcademyTask:
	var task := AcademyTask.new()
	task.kind = kind
	task.target_card_name = template.card_name
	task.faction = template.faction
	task.quantity = 1
	task.duration_seconds = AcademyEconomy.creation_time_seconds(template.rarity, academy_level)
	return task


static func _schedule_or_queue(kingdom: Kingdom, task: AcademyTask, now_unix: int) -> void:
	var master: AcademyMaster = _find_free_master(kingdom.academy_artifices)
	if master != null:
		_enqueue(master, task, task.duration_seconds, now_unix)
	else:
		kingdom.academy_pending_chain_tasks.append(task)


## --- Compra de capacidade de fila (ACADEMY.md, "Melhorias das Filas") ---

## Aumenta em 1 a capacidade de fila de "master" (independente dos
## demais Mestres), pagando em PG conforme AcademyEconomy. Retorna
## {"success": bool, "reason": String}. "reason": "max_capacity_reached"
## (Artífice já em 6, ou Metamorfo já em 4 — tetos de ACADEMY.md),
## "insufficient_pg".
static func upgrade_queue_capacity(kingdom: Kingdom, master: AcademyMaster) -> Dictionary:
	var max_capacity: int = 6 if master.kind == AcademyMaster.Kind.ARTIFICE else 4
	var target_capacity: int = master.queue_capacity + 1

	if target_capacity > max_capacity:
		return {"success": false, "reason": "max_capacity_reached"}

	var cost_table: Dictionary = AcademyEconomy.ARTIFICE_QUEUE_UPGRADE_COST_PG if master.kind == AcademyMaster.Kind.ARTIFICE else AcademyEconomy.METAMORFO_QUEUE_UPGRADE_COST_PG
	var cost: int = cost_table.get(target_capacity, 0)

	if not kingdom.spend_generation_points(cost):
		return {"success": false, "reason": "insufficient_pg"}

	master.queue_capacity = target_capacity
	return {"success": true, "reason": ""}
