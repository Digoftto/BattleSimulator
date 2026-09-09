class_name TestArmyFactory
extends RefCounted
## TestArmyFactory (CAMPO_DE_PROVA.md)
##
## Constrói um Army de TESTE — temporário, nunca ligado a Kingdom.armies/
## Kingdom.cards/Kingdom.commanders, nunca passado por Kingdom.form_army()
## — para o Campo de Prova (Modo Real: lado "Exército de Teste"; Modo
## Simulado: os dois lados, CAMPO_DE_PROVA.md/pedido "Reestruturação do
## Campo de Prova"). Reaproveita exatamente as peças que o resto do
## projeto já usa pra gerar conteúdo procedural, nunca uma segunda
## heurística:
##
##   - CommanderGenerator.generate() — mesmo gerador de Doutrina usado por
##     EnemyArmyGenerator._build_commander() — para o Comandante;
##   - ArmyRandomComposer.random_valid_composition() (extraída de
##     army_editor_panel.gd nesta etapa, mesmo corpo) — para a composição
##     de 9 Cartas dentro do teto de Soldo;
##   - ArmyFormationArchetypes.generate_all() — mesma heurística de
##     posicionamento já usada por Kingdom.form_army() e pelo botão
##     "Criar Exército Aleatório" do Editor de Exército — para a
##     Formação (δ/Equilibrada), já preservando Suporte-nunca-Posição-5 e
##     Máquina de Guerra-sempre-Posição-9 (correções desta mesma sessão).
##
## Cartas e Comandante são SEMPRE .duplicate() a partir do catálogo
## (GameDatabase.cards/GameDatabase.commanders não são usados como
## objetos-fonte diretamente — commander_generator.gd já cria um
## CommanderResource novo; cartas são copiadas de GameDatabase.cards) —
## nunca objetos de Kingdom.cards/Kingdom.commanders, nunca o mesmo
## objeto entre dois Army de teste diferentes. Isso garante, por
## construção, que nenhum Army de teste possa afetar o inventário real
## do jogador (CAMPO_DE_PROVA.md, "Regras Permanentes": "não altera os
## Exércitos persistentes").

## Patente padrão do Comandante de teste — a mais alta (Soldo máximo),
## para permitir montar/testar contra qualquer conteúdo do catálogo sem
## um teto artificialmente baixo. Decisão de implementação desta etapa
## (não uma regra documental de CAMPO_DE_PROVA.md, que não define Patente
## para o Exército de Teste) — registrada no relatório final, não
## inventada como se fosse uma regra existente.
const DEFAULT_PATENTE: String = "Lorde-Comandante"


## Gera um Army de teste completo (Comandante procedural + 9 Cartas do
## catálogo completo do jogo dentro do teto de Soldo da Patente escolhida
## + Formação δ) — nunca a partir de Kingdom.cards/Kingdom.commanders.
## Retorna um Army com cards vazio (formação incompleta,
## is_ready_for_battle() == false) se o catálogo não permitir nenhuma
## composição dentro do teto — nunca uma composição parcial/inválida
## disfarçada de completa.
static func generate_random_army(patente: String = DEFAULT_PATENTE) -> Army:
	var commander: CommanderResource = generate_commander(patente)
	var soldo_cap: int = Soldo.cap_for_patente(patente)

	var pool: Array[CardResource] = []
	for template: CardResource in GameDatabase.cards:
		pool.append(template.duplicate())

	var composition: Array[CardResource] = ArmyRandomComposer.random_valid_composition(pool, soldo_cap)

	var army := Army.new()
	army.commander = commander
	army.army_name = "Exército de Teste"
	if composition.is_empty():
		return army

	var archetypes: Dictionary = ArmyFormationArchetypes.generate_all(composition)
	army.cards = archetypes.get("δ", composition)
	return army


## Comandante procedural — mesma técnica de
## EnemyArmyGenerator._build_commander() (ramo com Doutrina), sem os
## parâmetros PvE-específicos de Território/Região/Categoria que não se
## aplicam ao Campo de Prova. Sempre Ativo, nunca registrado em
## Kingdom.commanders — "administrative_state"/"ownership_status" aqui só
## precisam satisfazer as checagens JÁ existentes de elegibilidade que
## outras telas reaproveitam (nenhuma delas é consultada por
## CombatEngine/Army.is_ready_for_battle(), que nunca checam esses
## campos — confirmado por auditoria de código nesta sessão).
static func generate_commander(patente: String = DEFAULT_PATENTE) -> CommanderResource:
	var doctrine: CommanderDoctrine = CommanderGenerator.generate(
		GameDatabase.commander_restrictions,
		GameDatabase.commander_requirements,
		GameDatabase.commander_targets,
		GameDatabase.commander_effects,
		GameDatabase.commander_values,
	)

	var commander := CommanderResource.new()
	commander.commander_name = "Comandante de Teste (%s)" % doctrine.faction
	commander.faction = doctrine.faction
	commander.doctrine = doctrine
	commander.administrative_state = CommanderResource.AdministrativeState.ACTIVE
	commander.accumulated_xp = CommanderCareer.PATENTE_THRESHOLDS.filter(
		func(entry: Dictionary) -> bool: return entry["patente"] == patente
	)[0]["xp"]
	return commander
