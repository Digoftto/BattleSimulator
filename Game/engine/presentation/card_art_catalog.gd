class_name CardArtCatalog
extends RefCounted
## CardArtCatalog (ART-001)
##
## Resolve o caminho da arte de retrato de uma CardResource — sem
## nenhuma lógica de combate/economia, dado puro de apresentação.
##
## Mapeamento por CARD_NAME, num dicionário único e centralizado
## (nunca duplicado manualmente em vários lugares) — NÃO por
## resource_path, apesar de toda carta oficial ser carregada de um
## arquivo individual em res://database/cards/<slug>.tres com o MESMO
## slug do nome do arquivo de arte (ex: "Arqueiro Imperial" <-
## arqueiro_imperial.tres/.png). resource_path pareceria a fonte de
## verdade óbvia, mas foi DESCARTADA depois de confirmado por execução
## real (teste [F] de test_combat_replay_view.gd falhando) que toda
## carta realmente usada em jogo passa por CardResource.duplicate()
## em algum ponto entre o catálogo e o Exército do jogador (ex:
## StarterKitResolver._build_starter_composition(), "template.duplicate()")
## — e Resource.duplicate() sempre limpa resource_path na cópia
## (é um Resource novo, nunca salvo em disco, dois Resources não podem
## compartilhar o mesmo caminho no cache do Godot). card_name sobrevive
## a qualquer duplicate() normal (é um campo de dado comum, não
## metadado do Resource), por isso é a chave certa aqui.

const ART_DIR: String = "res://assets/art/cards/"

## As 39 cartas oficiais do catálogo (mesmos slugs de res://database/cards/*.tres)
## + a 1 unidade especial "Arqueiro Esquelético Reanimado" (Muralha de
## Ossos, "Legião Infindável" — nunca uma carta jogável/colecionável,
## TECHNICAL_BACKLOG.md R-007), 40 entradas ao todo.
const CARD_NAME_TO_SLUG: Dictionary = {
	# Império
	"Arqueiro Imperial": "arqueiro_imperial",
	"Balista Imperial": "balista_imperial",
	"Besteiro Imperial": "besteiro_imperial",
	"Campeão Imperial": "campeao_imperial",
	"Capitão Imperial": "capitao_imperial",
	"Centurião Imperial": "centuriao_imperial",
	"Engenheiro Imperial": "engenheiro_imperial",
	"Escudeiro Imperial": "escudeiro_imperial",
	"Evocador Imperial": "evocador_imperial",
	"Guardião Imperial": "guardiao_imperial",
	"Infante Imperial": "infante_imperial",
	"Legionário Imperial": "legionario_imperial",
	"Marechal Imperial": "marechal_imperial",
	# Mortos-Vivos
	"Abominação Putrefata": "abominacao_putrefata",
	"Altar da Reanimação": "altar_da_reanimacao",
	"Arqueira Espectral": "arqueira_espectral",
	"Arqueiro Esquelético": "arqueiro_esqueletico",
	"Banshee": "banshee",
	"Ceifador Cadavérico": "ceifador_cadaverico",
	"Ceifadora Espectral": "ceifadora_espectral",
	"Cultista da Putrefação": "cultista_da_putrefacao",
	"Esqueleto Guerreiro": "esqueleto_guerreiro",
	"Lich Rei": "lich_rei",
	"Liche Iniciado": "liche_iniciado",
	"Muralha de Ossos": "muralha_de_ossos",
	"Sacerdote Profano": "sacerdote_profano",
	"Arqueiro Esquelético Reanimado": "arqueiro_esqueletico_reanimado",
	# Natureza
	"Águia Dourada": "aguia_dourada",
	"Árvore Ancestral": "arvore_ancestral",
	"Carvalho Ancião": "carvalho_anciao",
	"Carvalho Milenar": "carvalho_milenar",
	"Coração da Floresta": "coracao_da_floresta",
	"Ent Jovem": "ent_jovem",
	"Flor da Aurora": "flor_da_aurora",
	"Leão da Savana": "leao_da_savana",
	"Porco-Espinho Ancestral": "porco_espinho_ancestral",
	"Salgueiro Ancião": "salgueiro_anciao",
	"Trepadeira Ancestral": "trepadeira_ancestral",
	"Unicórnio Ancestral": "unicornio_ancestral",
	"Urso Ancestral": "urso_ancestral",
}


## Retorna o caminho res:// da arte, ou "" se não houver nenhuma
## correspondência (carta nula, ou uma carta futura ainda sem arte
## integrada — nunca trava, quem chama decide o que fazer com "").
static func texture_path_for(card: CardResource) -> String:
	if card == null or not CARD_NAME_TO_SLUG.has(card.card_name):
		return ""
	return ART_DIR + CARD_NAME_TO_SLUG[card.card_name] + ".png"


## Carrega a textura real (null se o caminho não existir) — nunca
## lança erro, só devolve null pra quem chama decidir o fallback
## (hoje: continuar mostrando texto).
static func texture_for(card: CardResource) -> Texture2D:
	var path: String = texture_path_for(card)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
