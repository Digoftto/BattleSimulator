class_name CardResource
extends Resource
## CardResource
##
## Representa o schema de dados de uma Carta (Pelotão militar permanente
## do Reino), conforme a arquitetura conceitual definida em CARD.md e a
## ficha técnica padronizada de CARD_CATALOG.md.
##
## Escopo implementado: Identidade e Atributos Base (Sprint 2), Progressão
## por Tier (Sprint 3) e referência à Característica de Unidade de Tier I
## (Sprint 18). Os campos abaixo NÃO incluem o comportamento de Habilidades
## ou Características (AbilityResource/UnitTraitResource — Sprint 18),
## Afinidade (AFFINITY.md), Energia (ENERGY.md) ou Soldo (SOLDO.md) —
## esses pertencem a Sprints próprias.

## --- Identidade (Imutável) ---

## Identificador único desta cópia específica da carta — "o RG dela".
## 0 = carta de catálogo (GameDatabase), nunca possuída por ninguém.
## Toda cópia que o jogador realmente tem (Kingdom.cards) recebe um
## valor > 0, atribuído uma única vez por Kingdom.acquire_card_from_catalog().
## Duas cópias da mesma carta (mesmo card_name) têm instance_id
## diferentes — são objetos distintos, cada um com seu próprio estado
## (decisão do jogador: "várias cópias, cada uma é uma carta diferente").
@export var instance_id: int = 0

## ENERGY.md, "Penalidade de Composição" — Unix da última vez que esta
## Carta saiu de dentro de um Exército (0 = nunca esteve em nenhum, ou
## nunca saiu). Usado só pra decidir se ela entra num Exército novo
## "recém-usada" (dispara a Penalidade de Composição) ou "descansada"
## (sem penalidade nenhuma) — nunca afeta Combate nem nenhuma outra
## mecânica.
var last_removed_from_army_unix: int = 0

## Onde esta cópia específica está agora. Uma carta só pode estar em um
## lugar por vez — nunca em dois Exércitos, nem num Exército e "livre"
## ao mesmo tempo (decisão do jogador). EM_RECEITA (Academia) não existe
## ainda como estado — hoje uma carta usada em Receita é simplesmente
## removida de Kingdom.cards ("ela some, é consumida pela receita"),
## sem precisar de um terceiro status.
enum OwnershipStatus { LIVRE, EM_EXERCITO }
@export var ownership_status: OwnershipStatus = OwnershipStatus.LIVRE

## Nome do Pelotão militar. Ex: "Legionário Imperial".
@export var card_name: String = ""

## Facção de origem do Pelotão. Ex: "Império".
@export var faction: String = ""

## Classe tática do Pelotão (Corpo a Corpo, Barreira, À Distância, Mago, Suporte).
@export var card_class: String = ""

## Sub-classificação temática opcional (ex: Esqueleto, Aparição, Zumbi),
## independente da Classe. Vazio quando a carta não possui Tipo (ver
## CARD.md, seção "Tipo").
@export var card_type: String = ""

## Raridade da Carta, conforme a ficha técnica de CARD_CATALOG.md.
@export var rarity: String = ""

## Tier atual da Carta. Nesta Sprint, representa apenas o valor estático
## de criação da carta (Tier I). Regras de evolução pertencem a
## CARD_PROGRESSION.md.
@export var tier: int = 1

## --- Atributos Base (Combate, Tier I) ---

@export var atk: int = 0
@export var hp: int = 0
@export var esc: int = 0

## Nome da Característica de Unidade (Tier I), conforme CARD_CATALOG.md.
## Referencia um UnitTraitResource — NUNCA um AbilityResource. Características
## de Unidade pertencem exclusivamente à identidade da carta (exclusivas,
## uma por carta); Habilidades (Tier III/V) são compartilhadas entre
## cartas (ver Sprint 18, "Atualização de Arquitetura — Características
## de Unidade"). Vazio quando a carta não possui Característica de
## Unidade (algumas cartas oficiais não possuem, conforme CARD_CATALOG.md).
@export var tier_1_trait_name: String = ""

## --- Progressão (CARD_PROGRESSION.md) ---
##
## Os campos abaixo representam exclusivamente dados de catálogo da carta
## (valores fixos por carta, conforme CARD_CATALOG.md). A regra de como
## aplicá-los pertence a `engine/cards/card_progression.gd`.
##
## Tiers II e IV: incrementos permanentes de atributos.
## Tiers III e V: apenas o NOME da Habilidade desbloqueada (dado de
## catálogo). O comportamento da Habilidade pertence a ABILITIES.md e não
## é implementado nesta Sprint.

@export var tier_2_atk_increment: int = 0
@export var tier_2_hp_increment: int = 0
@export var tier_2_esc_increment: int = 0

@export var tier_3_ability_name: String = ""

@export var tier_4_atk_increment: int = 0
@export var tier_4_hp_increment: int = 0
@export var tier_4_esc_increment: int = 0

@export var tier_5_ability_name: String = ""

## --- Academia (ACADEMY.md + LIBRARY_CONTENT.md) ---

## Nomes das 3 cartas Tier I que, combinadas na Academia, produzem esta
## carta (ver AcademyResolver). Vazio para cartas Comuns — elas nunca
## têm receita, são produzidas direto por Fragmentos.
@export var recipe_ingredients: Array[String] = []
