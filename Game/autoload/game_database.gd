extends Node
## GameDatabase
##
## Responsável por carregar o banco de dados estático do jogo (res://database/),
## contendo os catálogos definidos pela documentação (Cartas, Habilidades,
## Comandantes, Campos de Batalha, Biblioteca).
##
## Sprint 2: catálogo de Cartas (res://database/cards/).
## Sprint 4: catálogo de Identidade de Comandantes (res://database/commanders_pool/).
## Sprint 5: os 5 Bancos Oficiais do Motor de Geração de Comandantes
## (res://database/commander_generation/). Os demais catálogos (abilities,
## battlefields, library_content) permanecem vazios e serão implementados
## em Sprints próprias.

const CARDS_PATH: String = "res://database/cards/"
const COMMANDERS_PATH: String = "res://database/commanders_pool/"
const RESTRICTIONS_PATH: String = "res://database/commander_generation/restrictions/"
const REQUIREMENTS_PATH: String = "res://database/commander_generation/requirements/"
const TARGETS_PATH: String = "res://database/commander_generation/targets/"
const EFFECTS_PATH: String = "res://database/commander_generation/effects/"
const VALUES_PATH: String = "res://database/commander_generation/values/"
const BATTLEFIELDS_PATH: String = "res://database/battlefields/"
const AFFINITY_PATH: String = "res://database/affinity/"
const ABILITIES_PATH: String = "res://database/abilities/"
const UNIT_TRAITS_PATH: String = "res://database/unit_traits/"

var is_loaded: bool = false
var cards: Array[CardResource] = []
var commanders: Array[CommanderResource] = []
var commander_restrictions: Array[CommanderRestrictionResource] = []
var commander_requirements: Array[CommanderRequirementResource] = []
var commander_targets: Array[CommanderTargetResource] = []
var commander_effects: Array[CommanderEffectResource] = []
var commander_values: Array[CommanderValueResource] = []
var battlefields: Array[BattlefieldResource] = []
var affinity_levels: Array[AffinityLevelResource] = []
var abilities: Array[AbilityResource] = []
## Índice rígido nome -> AbilityResource. Construído uma única vez, na
## carga do banco de dados (Sprint 20) — nenhum outro sistema deve
## reconstruir este índice. Nomes duplicados são erro de integridade do
## catálogo e interrompem a inicialização (o catálogo de Habilidades não
## possui nenhuma duplicidade conhecida, diferente de unit_traits).
var abilities_by_name: Dictionary = {}
var unit_traits: Array[UnitTraitResource] = []
## Índice único nome -> UnitTraitResource. Construído uma única vez, na
## carga do banco de dados — nenhum outro sistema deve reconstruir este
## índice (antes, UnitTraitRuntime reconstruía o seu próprio a cada
## batalha; unificado aqui após a duplicidade "Engenharia Militar" ter
## sido resolvida na SSOT).
var traits_by_name: Dictionary = {}


## Autoload — carrega o banco de dados sozinho assim que o jogo abre,
## não importa qual seja a cena de entrada (main.tscn, bootstrap.tscn,
## ou qualquer painel rodado isolado via F6). Antes, só bootstrap.gd
## chamava load_database() explicitamente — CityPanel/PvEPanel
## chamando WorldBootstrap.ensure_world_loaded() sem isso encontrava
## GameDatabase.cards vazio (achado com execução real no Editor:
## "Modulo by zero" em EnemyArmyGenerator, cartas do Território
## vazias). load_database() já é idempotente (if is_loaded: return),
## então chamar de novo em bootstrap.gd continua seguro.
func _ready() -> void:
	load_database()


func load_database() -> void:
	if is_loaded:
		return

	_load_cards()
	_load_commanders()
	_load_commander_generation_banks()
	_load_all(BATTLEFIELDS_PATH, battlefields)
	_load_all(AFFINITY_PATH, affinity_levels)
	_load_all(ABILITIES_PATH, abilities)
	_build_abilities_index()
	_load_all(UNIT_TRAITS_PATH, unit_traits)
	_build_traits_index()

	is_loaded = true
	print("[GameDatabase] Banco de dados carregado. Cartas: %d. Comandantes: %d. Restrições: %d. Requisitos: %d. Alvos: %d. Efeitos: %d. Valores: %d. Campos de Batalha: %d. Afinidade: %d. Habilidades: %d. Características de Unidade: %d." % [
		cards.size(), commanders.size(), commander_restrictions.size(), commander_requirements.size(),
		commander_targets.size(), commander_effects.size(), commander_values.size(), battlefields.size(),
		affinity_levels.size(), abilities.size(), unit_traits.size()
	])
	EventBus.database_loaded.emit()


## Constrói o índice rígido de Habilidades por nome. Uma chave duplicada
## é um erro de integridade do catálogo (não conhecido hoje) e interrompe
## a inicialização — diferente de unit_traits, que não possui índice por
## nome nesta Sprint (ver UnitTraitRuntime).
func _build_abilities_index() -> void:
	for ability: AbilityResource in abilities:
		assert(not abilities_by_name.has(ability.ability_name),
			"GameDatabase: nome de Habilidade duplicado no catálogo: '%s'." % ability.ability_name)
		abilities_by_name[ability.ability_name] = ability


## Constrói o índice único de Características por nome. Uma chave
## duplicada interrompe a inicialização (Sprint 24.5: a duplicidade
## "Engenharia Militar" já foi resolvida na SSOT — as duas
## UnitTraitResource que compartilhavam esse nome viraram "Manutenção
## de Campo" e "Manutenção Especializada").
func _build_traits_index() -> void:
	for entry: UnitTraitResource in unit_traits:
		assert(not traits_by_name.has(entry.trait_name),
			"GameDatabase: nome de Característica duplicado no catálogo: '%s'." % entry.trait_name)
		traits_by_name[entry.trait_name] = entry


## --- Consultas ao catálogo de Cartas (Sprint 23) ---
## Apenas leitura sobre "cards", já carregado por load_database(). Nenhuma
## lógica de gameplay — puramente consulta.

func get_card(card_name: String) -> CardResource:
	for card: CardResource in cards:
		if card.card_name == card_name:
			return card
	return null


func get_cards_by_faction(faction: String) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in cards:
		if card.faction == faction:
			result.append(card)
	return result


func get_cards_by_class(card_class: String) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in cards:
		if card.card_class == card_class:
			result.append(card)
	return result


func get_cards_by_type(card_type: String) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in cards:
		if card.card_type == card_type:
			result.append(card)
	return result


func get_cards_by_rarity(rarity: String) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card: CardResource in cards:
		if card.rarity == rarity:
			result.append(card)
	return result


func _load_cards() -> void:
	var dir: DirAccess = DirAccess.open(CARDS_PATH)
	if dir == null:
		push_warning("[GameDatabase] Diretório de cartas não encontrado: %s" % CARDS_PATH)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var card: CardResource = load(CARDS_PATH + file_name)
			if card != null:
				cards.append(card)
				print("[GameDatabase] Carta carregada: %s | Facção: %s | Classe: %s | Raridade: %s | Tier: %d | ATK: %d HP: %d ESC: %d" % [
					card.card_name, card.faction, card.card_class, card.rarity, card.tier, card.atk, card.hp, card.esc
				])
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_commanders() -> void:
	var dir: DirAccess = DirAccess.open(COMMANDERS_PATH)
	if dir == null:
		push_warning("[GameDatabase] Diretório de comandantes não encontrado: %s" % COMMANDERS_PATH)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var commander: CommanderResource = load(COMMANDERS_PATH + file_name)
			if commander != null:
				commanders.append(commander)
				print("[GameDatabase] Comandante carregado: %s \"%s\" | Facção: %s | Reino de Origem: %s | Reino em Serviço: %s" % [
					commander.commander_name, commander.epithet, commander.faction, commander.home_kingdom, commander.serving_kingdom
				])
		file_name = dir.get_next()
	dir.list_dir_end()


## Carrega genericamente todos os arquivos .tres de um diretório para um Array tipado.
func _load_all(path: String, out_array: Array) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_warning("[GameDatabase] Diretório não encontrado: %s" % path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = load(path + file_name)
			if resource != null:
				out_array.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_commander_generation_banks() -> void:
	_load_all(RESTRICTIONS_PATH, commander_restrictions)
	_load_all(REQUIREMENTS_PATH, commander_requirements)
	_load_all(TARGETS_PATH, commander_targets)
	_load_all(EFFECTS_PATH, commander_effects)
	_load_all(VALUES_PATH, commander_values)
