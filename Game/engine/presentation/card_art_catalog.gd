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


## ART-006: os 40 PNGs fonte nao tem margem de canvas padronizada - cada
## carta foi exportada com uma quantidade diferente de fundo preto ao
## redor da moldura real (ex: arqueiro_imperial.png tem ~68% da largura
## do canvas ocupada pela carta; lich_rei.png quase 100%). Usar a
## textura crua causaria barras pretas (ou um corte incorreto por
## STRETCH_KEEP_ASPECT_COVERED) inconsistentes carta a carta. Esta
## funcao detecta o retangulo realmente ocupado pela moldura (qualquer
## pixel nao-preto, varredura em grade esparsa - rapido o bastante pra
## rodar uma vez por textura unica, nunca por frame) e devolve uma
## AtlasTexture recortada exatamente nesse retangulo - a arte em si
## nunca e modificada, so a regiao exibida.
static var _used_rect_cache: Dictionary = {}

static func used_rect_for(texture: Texture2D) -> Rect2i:
	if texture == null:
		return Rect2i()
	var cache_key: String = texture.resource_path
	if cache_key != "" and _used_rect_cache.has(cache_key):
		return _used_rect_cache[cache_key]

	var image: Image = texture.get_image()
	var rect: Rect2i = _detect_used_rect(image)
	if cache_key != "":
		_used_rect_cache[cache_key] = rect
	return rect


## Perf (Biblioteca/Bestiário, medido): a versão original usava
## image.get_pixel(x,y) por amostra — 39 texturas do catálogo real
## levavam ~724ms na primeira varredura (cache já elimina chamadas
## repetidas, ver used_rect_for(), mas a primeira ainda pesava).
## Acesso direto ao PackedByteArray (image.get_data()) faz a MESMA
## detecção, com o MESMO limiar e a MESMA grade de amostragem — só
## evita o overhead de uma chamada de método por pixel. Limiar em byte
## (> 5) é exatamente equivalente ao limiar em float original (> 0.02):
## 0.02 * 255 = 5.1, então byte > 5 <=> byte/255.0 > 0.02. Só usa o
## caminho rápido pra RGBA8/RGB8 (formato real de todo o catálogo,
## confirmado — Comum a qualquer import "Lossless" padrão do Godot);
## qualquer outro formato cai no caminho antigo (get_pixel), sem risco
## de detectar diferente.
static func _detect_used_rect(image: Image) -> Rect2i:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var step_x: int = max(1, w / 220)
	var step_y: int = max(1, h / 220)
	var min_x: int = w
	var max_x: int = -1
	var min_y: int = h
	var max_y: int = -1

	var format: Image.Format = image.get_format()
	if format == Image.FORMAT_RGBA8 or format == Image.FORMAT_RGB8:
		var data: PackedByteArray = image.get_data()
		var channels: int = 4 if format == Image.FORMAT_RGBA8 else 3
		for y in range(0, h, step_y):
			var row_base: int = y * w * channels
			for x in range(0, w, step_x):
				var idx: int = row_base + x * channels
				if data[idx] > 5 or data[idx + 1] > 5 or data[idx + 2] > 5:
					min_x = min(min_x, x)
					max_x = max(max_x, x)
					min_y = min(min_y, y)
					max_y = max(max_y, y)
	else:
		for y in range(0, h, step_y):
			for x in range(0, w, step_x):
				var c: Color = image.get_pixel(x, y)
				if c.r > 0.02 or c.g > 0.02 or c.b > 0.02:
					min_x = min(min_x, x)
					max_x = max(max_x, x)
					min_y = min(min_y, y)
					max_y = max(max_y, y)

	if max_x < 0:
		return Rect2i(0, 0, w, h)
	return Rect2i(min_x, min_y, max_x - min_x + step_x, max_y - min_y + step_y).intersection(Rect2i(0, 0, w, h))


## Dispara o carregamento em segundo plano (ResourceLoader threaded)
## das artes de todas as Cartas informadas — "fire and forget": não
## bloqueia quem chama, só aquece o cache de recursos do próprio Godot
## (load() plano continua funcionando exatamente igual em
## texture_for()/cropped_texture_for(), só mais rápido quando o
## carregamento em segundo plano já tiver terminado). Chamado uma vez
## pela Biblioteca (hub) assim que ela abre, pra que as 39 texturas já
## estejam total ou parcialmente carregadas quando o jogador realmente
## clicar em "Bestiário" — medido: ~2051ms era o custo dominante de
## abrir o Bestiário do zero (carregar as 39 texturas do disco pela
## primeira vez), não um laço/loop ineficiente no código.
static func preload_all(cards: Array[CardResource]) -> void:
	for card: CardResource in cards:
		var path: String = texture_path_for(card)
		if path == "" or not ResourceLoader.exists(path):
			continue
		# Erro (ex.: já carregando/já carregado) é esperado e inofensivo
		# — não há nada a fazer com o resultado aqui.
		ResourceLoader.load_threaded_request(path)


## Textura pronta pra exibicao num BattleCardView: ja recortada (ver
## used_rect_for()), sem nenhuma barra preta de canvas. null nos mesmos
## casos que texture_for() (carta nula/sem arte ainda integrada).
static func cropped_texture_for(card: CardResource) -> Texture2D:
	var base: Texture2D = texture_for(card)
	if base == null:
		return null
	var rect: Rect2i = used_rect_for(base)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return base
	var atlas := AtlasTexture.new()
	atlas.atlas = base
	atlas.region = Rect2(rect)
	return atlas
