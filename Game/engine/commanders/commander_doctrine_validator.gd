class_name CommanderDoctrineValidator
extends RefCounted
## CommanderDoctrineValidator (COMMANDER_RESTRICTIONS.md)
##
## "Toda Restrição é verificada antes do início da batalha. Caso uma
## Restrição não seja atendida, o comandante não poderá ser
## utilizado." — este validador implementa essa checagem, e SEMPRE
## retorna uma mensagem clara em português explicando exatamente por
## que o Exército foi bloqueado (nunca só "false").
##
## Duas partes, porque a informação disponível é diferente:
## - check_static(): Facção/Classe/Modo de Jogo — conhecidos ANTES do
##   combate, sem depender de qual Campo de Batalha vai ser sorteado.
##   Usado no Editor de Exército (feedback antes de gastar uma
##   tentativa) e em PhaseResolver/MineConquestResolver (bloqueio real).
## - check_battlefield(): domínio "battlefield" — só pode ser checado
##   DEPOIS que CombatEngine sorteia o Campo (Battlefield.draw()), já
##   que a Restrição não determina qual Campo será usado, só reage a
##   ele. Retorna "" (sem bloqueio) sempre que a Restrição não for
##   desse domínio.
##
## Mapeamento de nomes: os bancos de Restrição/Requisito usam nomes de
## Classe em inglês ("Melee", "Ranged" — CommanderGenerator.CLASSES),
## enquanto CardResource.card_class usa os nomes em português já
## estabelecidos no resto do jogo ("Corpo a Corpo", "À Distância").

const CLASS_NAME_MAP: Dictionary = {
	"Melee": "Corpo a Corpo",
	"Ranged": "À Distância",
	"Mago": "Mago",
	"Suporte": "Suporte",
	"Barreira": "Barreira",
	"Máquina de Guerra": "Máquina de Guerra",
}


## Checa os domínios conhecidos antes do combate (faction/class/game_mode).
## Retorna "" se não há bloqueio, ou uma mensagem clara se há.
static func check_static(commander: CommanderResource, cards: Array[CardResource], game_mode: String) -> String:
	if commander.doctrine == null:
		return ""

	var restriction: CommanderRestrictionResource = commander.doctrine.restriction
	var param: String = commander.doctrine.restriction_param

	match restriction.domain:
		"faction":
			return _check_faction(commander, cards, restriction, param)
		"class":
			return _check_class(commander, cards, restriction, param)
		"game_mode":
			return _check_game_mode(commander, restriction, game_mode)
		_:
			return ""  # "battlefield" e "affinity" não são checados aqui


## Checa o domínio "battlefield" — só chamável DEPOIS do Campo de
## Batalha já ter sido sorteado (CombatEngine._initialize()).
static func check_battlefield(commander: CommanderResource, battlefield: BattlefieldResource) -> String:
	if commander.doctrine == null:
		return ""

	var restriction: CommanderRestrictionResource = commander.doctrine.restriction
	if restriction.domain != "battlefield":
		return ""

	match restriction.operator:
		"only_standard":
			if battlefield.category != "Campo Aberto" and battlefield.battlefield_name != "Campo Aberto":
				return "O Comandante '%s' só pode lutar no Campo Aberto — a batalha caiu em '%s'." % [
					commander.commander_name, battlefield.battlefield_name
				]
		"forbidden":
			if battlefield.battlefield_name == commander.doctrine.restriction_param:
				return "O Comandante '%s' não pode lutar no Campo de Batalha '%s' — foi exatamente o que caiu nesta batalha." % [
					commander.commander_name, battlefield.battlefield_name
				]
	return ""


static func _check_faction(commander: CommanderResource, cards: Array[CardResource], restriction: CommanderRestrictionResource, param: String) -> String:
	var target_faction: String = commander.faction if restriction.scope == "self" else param
	var count: int = 0
	for card: CardResource in cards:
		if card.faction == target_faction:
			count += 1

	match restriction.operator:
		"max":
			if count > restriction.quantity:
				return "O Comandante '%s' exige no máximo %d lacaios da Facção %s, mas o Exército tem %d." % [
					commander.commander_name, restriction.quantity, target_faction, count
				]
		"min":
			if count < restriction.quantity:
				return "O Comandante '%s' exige pelo menos %d lacaios da Facção %s, mas o Exército tem só %d." % [
					commander.commander_name, restriction.quantity, target_faction, count
				]
	return ""


static func _check_class(commander: CommanderResource, cards: Array[CardResource], restriction: CommanderRestrictionResource, param: String) -> String:
	var target_class: String = CLASS_NAME_MAP.get(param, param)
	var count: int = 0
	for card: CardResource in cards:
		if card.card_class == target_class:
			count += 1

	match restriction.operator:
		"max":
			if count > restriction.quantity:
				return "O Comandante '%s' exige no máximo %d lacaios da Classe %s, mas o Exército tem %d." % [
					commander.commander_name, restriction.quantity, target_class, count
				]
		"min":
			if count < restriction.quantity:
				return "O Comandante '%s' exige pelo menos %d lacaios da Classe %s, mas o Exército tem só %d." % [
					commander.commander_name, restriction.quantity, target_class, count
				]
		"required":
			if count < 1:
				return "O Comandante '%s' exige pelo menos 1 lacaio da Classe %s, e o Exército não tem nenhum." % [
					commander.commander_name, target_class
				]
		"forbidden":
			if count > 0:
				return "O Comandante '%s' não aceita lacaios da Classe %s, mas o Exército tem %d." % [
					commander.commander_name, target_class, count
				]
	return ""


static func _check_game_mode(commander: CommanderResource, restriction: CommanderRestrictionResource, game_mode: String) -> String:
	if restriction.operator == "exclusive" and restriction.scope != game_mode:
		var mode_labels: Dictionary = {"pvp": "PvP", "pve": "PvE", "mines": "Minas"}
		return "O Comandante '%s' só pode ser usado em %s — esta batalha é de outro tipo." % [
			commander.commander_name, mode_labels.get(restriction.scope, restriction.scope)
		]
	return ""
