class_name BattleUnitArtCatalog
extends RefCounted
## BattleUnitArtCatalog (Battle Art MVP — Piloto, 2026-09-02)
##
## Resolve a textura de BATTLE ART (personagem completo de Battlefield —
## nunca o retrato de carta, ver CardArtCatalog) de uma unidade, por
## card_name — mesma convenção/motivo de CardArtCatalog: mapa
## centralizado por Nome, nunca por resource_path (CardResource.duplicate()
## limpa resource_path; card_name sobrevive a qualquer duplicate() normal).
##
## DECISÃO DE DESIGN DO MVP (aprovada, registrada aqui e no relatório
## desta tarefa): 1 PERSONAGEM VISUAL = 1 PELOTÃO VISUAL. Nunca uma
## composição de múltiplos soldados no Battlefield — a contagem lógica
## de soldados (BATTLE_PLATOONS.md) continua existindo nos dados/regras
## do jogo, mas não é representada visualmente aqui.
##
## Escopo original (Battle Art MVP — Piloto): SOMENTE o piloto
## humanoide ("Arqueiro Imperial" — postura vertical, silhueta limpa,
## base identificável, sem fumaça/névoa, validado com transparência real
## por composição sobre fundo magenta na auditoria original).
##
## PILOTOS 02/03 (2026-09-02) — teste de generalização da arquitetura:
## adicionados "Altar da Reanimação" (Máquina de Guerra dos Mortos-Vivos
## — estrutura estática, sem pernas/rodas, um único "pé" = a base do
## monumento) e "Unicórnio Ancestral" (Natureza — quadrúpede, pose de
## empinar, só 3 dos 4 cascos tocam o chão na pose renderizada). Nenhuma
## linha de código deste arquivo, de battle_unit_art_layer.gd ou de
## combat_replay_view.gd precisou mudar para suportá-los — só duas
## entradas novas em CARD_NAME_TO_PATH (aqui) e duas em
## BattleUnitArtGeometry.CARD_NAME_TO_FOOT_CENTER_FRAC (o "ground
## contact" de cada um, com método de medição específico documentado
## lá) — confirmação concreta de que a arquitetura já era genérica, não
## amarrada à anatomia do Arqueiro. Ver relatório desta tarefa para a
## auditoria completa dos dois assets (dimensão/alpha/bbox/pontos de
## contato/orientação).
##
## As demais ~37 Cartas continuam retornando null em has_art_for() —
## BattleCardView continua sendo 100% da representação visual delas,
## sem nenhuma mudança (ver combat_replay_view.gd/battle_unit_art_layer.gd).
## FASE 2 — SEGUNDA BATERIA (2026-09-02): antes de integrar mais
## assets, uma AUDITORIA COMPLETA dos 40 (relatório separado desta
## sessão) classificou cada um em A/B/C/D (pronto / precisa calibração /
## precisa correção visual / precisa refação). Esta tarefa integra 5 dos
## classificados como B (prontos, só precisam de ground contact
## medido), escolhidos para validar mais 5 casos estruturais:
## "Ent Jovem" (estrutura orgânica humanoide — treant bípede),
## "Balista Imperial" (veículo com rodas — subtipo novo),
## "Carvalho Ancião" (estrutura com múltiplos pontos de raiz),
## "Muralha de Ossos" (bípede/golem robusto),
## "Capitão Imperial" (bípede convencional adicional). Os outros 32
## assets (7 categoria C, 2 categoria D, 23 categoria B ainda não
## priorizados) permanecem FORA do catálogo — critério de parada
## explícito desta tarefa, não migrar o resto agora.
##
## Os 40 PNGs fonte em Assets/MVP/Pelotão/ NUNCA são alterados por este
## arquivo (nem por nenhum outro desta tarefa) — apenas lidos.
##
## "orientation" já existe na assinatura de toda função pública (ver
## BATTLE ART — ASSET CONTRACT v1.md §10 / BATTLE ART PRODUCTION
## PIPELINE v1.md §9, FRONT/BACK/LEFT/RIGHT) para que a arquitetura não
## fique amarrada a um único PNG por personagem — hoje NENHUMA das 40
## imagens possui as quatro orientações reais (confirmado na auditoria:
## são retratos únicos estilo "hero shot"), então toda orientação
## resolve para o MESMO arquivo. Quando as orientações reais existirem,
## somente CARD_NAME_TO_PATH/a resolução de caminho precisam mudar —
## nenhum chamador (battle_unit_art_layer.gd/combat_replay_view.gd)
## precisa ser alterado.

## card_name -> caminho RELATIVO dentro de Assets/MVP/Pelotão/ (mesmo
## nome/pasta reais dos 40 assets já auditados — nunca renomeados nem
## movidos por esta tarefa).
const CARD_NAME_TO_PATH: Dictionary = {
	"Arqueiro Imperial": "Império/Arqueiro Imperial.png",
	## FASE 5: migradas pra versão harmonizada — ver bloco "PADRONIZAÇÃO
	## VISUAL B" abaixo (nunca uma segunda entrada; são as MESMAS 2
	## chaves só com o valor atualizado).
	"Altar da Reanimação": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/ALTAR OF REANIMATION.png",
	"Unicórnio Ancestral": "_Harmonizado_EXPERIMENTAL/Natureza/ANCIENT UNICORN.png",
	"Ent Jovem": "Natureza/Young ENT.png",
	"Balista Imperial": "Império/BALISTA IMPERIAL.png",
	"Carvalho Ancião": "Natureza/Ancient Oak.png",
	"Muralha de Ossos": "Morto-Vivo/Wall of Bones.png",
	"Capitão Imperial": "Império/Capitã Imperial-base.png",

	## FASE 3 (2026-09-03) — migração controlada dos assets aprovados
	## para o lote seguinte. Nenhuma mudança de arquitetura: só entradas
	## novas aqui e em BattleUnitArtGeometry.CARD_NAME_TO_FOOT_CENTER_FRAC,
	## exatamente como nas duas fases anteriores.
	"Centurião Imperial": "Império/CENTURIÃO IMPERIAL.png",
	"Campeão Imperial": "Império/CAMPEÃO IMPERIAL.png",
	"Besteiro Imperial": "Império/BESTEIRO IMPERIAL.png",
	"Guardião Imperial": "Império/IMPERIAL GUARDIAN.png",
	"Infante Imperial": "Império/IMPERIAL INFANTRY.png",
	"Legionário Imperial": "Império/IMPERIAL LEGIONARY.png",
	"Esqueleto Guerreiro": "Morto-Vivo/SKELETON WARRIOR.png",
	"Liche Iniciado": "Morto-Vivo/INITIATE LICH.png",
	"Cultista da Putrefação": "Morto-Vivo/CULTIST OF PUTREFACTION.png",

	## FASE 5 (2026-09-03) — PADRONIZAÇÃO VISUAL B: os 13 card_names
	## abaixo (+ "Altar da Reanimação"/"Unicórnio Ancestral", já
	## atualizados acima, no bloco original) passam a apontar pra sua
	## versão HARMONIZADA (receita B,
	## validada visualmente nas Fases 4/4.1/4.3 — decisão do usuário:
	## "a versão B será o padrão visual adotado", C descartada) em vez do
	## PNG original. O PNG original de cada um continua intocado, no
	## mesmo lugar de sempre (Assets/MVP/Pelotão/<Facção>/...) — só a
	## entrada do catálogo passou a apontar pra
	## _Harmonizado_EXPERIMENTAL/<mesma Facção>/<mesmo arquivo>, gerado
	## por processamento de imagem OFFLINE (nunca um filtro em runtime,
	## nunca uma linha nova em BattleUnitArtLayer/CombatReplayView) —
	## alfa/silhueta/dimensões idênticos ao original, verificado por
	## assert automático em cada script de geração (ver relatório desta
	## tarefa). Os outros 15 card_names desta Fase (Centurião/Campeão/
	## Besteiro/Guardião/Infante/Legionário Imperial, Esqueleto Guerreiro/
	## Liche Iniciado/Cultista da Putrefação, Muralha de Ossos/Balista
	## Imperial, Carvalho Ancião/Ent Jovem — ver acima e a Base) já
	## estavam classificados como "A — já integrado visualmente" na
	## auditoria da Fase 4 e permanecem no PNG original, de propósito —
	## padronização não é uniformização, só os que precisavam mudam.
	"Engenheiro Imperial": "_Harmonizado_EXPERIMENTAL/Império/IMPERIAL ENGINEER.png",
	"Marechal Imperial": "_Harmonizado_EXPERIMENTAL/Império/IMPERIAL MARSHAL.png",
	"Escudeiro Imperial": "_Harmonizado_EXPERIMENTAL/Império/IMPERIAL SQUIRE.png",
	"Evocador Imperial": "_Harmonizado_EXPERIMENTAL/Império/IMPERIAL SUMMONER.png",
	"Ceifadora Espectral": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/SPECTRAL REAPER.png",
	"Arqueira Espectral": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/Spectral Archer.png",
	"Abominação Putrefata": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/putrid abomination.png",
	"Sacerdote Profano": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/Profane Priest.png",
	"Lich Rei": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/LICH KING.png",
	"Ceifador Cadavérico": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/Cadaverous Reaper.png",
	"Banshee": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/BANSHEE.png",
	"Carvalho Milenar": "_Harmonizado_EXPERIMENTAL/Natureza/Millennial Oak.png",
	"Águia Dourada": "_Harmonizado_EXPERIMENTAL/Natureza/GOLDEN EAGLE.png",

	## FASE 5 — a dupla antes marcada "ambígua" (SKELETON ARCHER.png vs
	## Reanimated Skeletal Archer.png) NUNCA foi uma ambiguidade real:
	## são 2 card_names DISTINTOS já reconhecidos em outras partes do
	## código-fonte (CardArtCatalog.CARD_NAME_TO_SLUG, test_art_catalogs.gd,
	## legiao_infindavel.tres) — "Arqueiro Esquelético" (Carta 03,
	## jogável) e "Arqueiro Esquelético Reanimado" (sub-produto evocado
	## pela Característica "Legião Infindável" de Muralha de Ossos, R-007,
	## nunca uma carta jogável, mas uma unidade real de combate com esse
	## card_name exato). O nome do arquivo em inglês ("Reanimated Skeletal
	## Archer") já confirma a correspondência. Nenhum PNG escolhido
	## arbitrariamente — os dois entram, cada um com seu próprio nome.
	"Arqueiro Esquelético": "Morto-Vivo/SKELETON ARCHER.png",
	"Arqueiro Esquelético Reanimado": "Morto-Vivo/Reanimated Skeletal Archer.png",

	## FASE 6 (2026-09-04) — os últimos 8 pelotões do MVP (39 Cartas
	## oficiais + "Arqueiro Esquelético Reanimado" = 40 no total, ver
	## relatório desta tarefa), integrados COMO ESTÃO por decisão
	## explícita do usuário — 6 têm fringing de alfa conhecido (halo
	## vermelho/amarelo) e 2 têm problema de conteúdo/composição (silhueta
	## difusa sem "baixo" claro; diorama com múltiplas criaturas). Nenhum
	## PNG foi alterado — os problemas visuais ficam registrados como
	## pendência futura, nunca escondidos por processamento aqui. Ground
	## contact de cada um documentado em
	## BattleUnitArtGeometry.CARD_NAME_TO_FOOT_CENTER_FRAC.
	"Porco-Espinho Ancestral": "Natureza/ANCESTRAL PORCUPINE.png",
	"Árvore Ancestral": "Natureza/ANCESTRAL TREE.png",
	"Urso Ancestral": "Natureza/ANCIENT BEAR.png",
	"Salgueiro Ancião": "Natureza/Ancient Willow.png",
	"Flor da Aurora": "Natureza/Flower of Dawn.png",
	"Leão da Savana": "Natureza/Lion of the Savanna.png",
	"Trepadeira Ancestral": "Natureza/Ancestral Climber.png",
	"Coração da Floresta": "Natureza/Heart of the Forest.png",
}

## filename -> Texture2D (canvas bruto, sem recorte) já carregado nesta
## execução — evita reler o mesmo PNG do disco a cada chamada.
static var _texture_cache: Dictionary = {}
## "card_name|orientation" -> Rect2i (bounding box real do conteúdo alfa)
static var _alpha_rect_cache: Dictionary = {}


static func has_art_for(card_name: String) -> bool:
	return CARD_NAME_TO_PATH.has(card_name)


## Mesma técnica de leitura fora de res:// já usada e documentada pelo
## protótipo ART-009 (scenes/prototype/battle_unit_art_prototype.gd,
## _project_root_dir()): Assets/MVP/ fica FORA do projeto Godot
## (res://Game), load("res://...") não alcança — leitura via caminho
## absoluto do sistema de arquivos.
static func _project_root_dir() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	return game_dir.get_base_dir()


static func _absolute_path_for(card_name: String) -> String:
	if not CARD_NAME_TO_PATH.has(card_name):
		return ""
	return _project_root_dir() + "/Assets/MVP/Pelotão/" + CARD_NAME_TO_PATH[card_name]


## Textura crua (canvas completo, sem recorte) — null se não houver
## Battle Art registrada pra este Nome ainda, ou se o arquivo não puder
## ser lido (nunca trava, quem chama decide o fallback — hoje: nenhum
## Battle Art extra pra essa unidade, ver battle_unit_art_layer.gd).
static func raw_texture_for(card_name: String, _orientation: String = "FRONT") -> Texture2D:
	if not has_art_for(card_name):
		return null
	if _texture_cache.has(card_name):
		return _texture_cache[card_name]

	var image := Image.new()
	if image.load(_absolute_path_for(card_name)) != OK:
		return null

	var texture: Texture2D = ImageTexture.create_from_image(image)
	_texture_cache[card_name] = texture
	return texture


## Retângulo real (px, no espaço do canvas bruto) do conteúdo com alfa
## real (> 0) — nunca o canvas inteiro (ASSET CONTRACT v1 §13,
## "bounding box real"). Mesma técnica de varredura em grade esparsa +
## acesso direto a PackedByteArray já usada em produção por
## CardArtCatalog._detect_used_rect() — a diferença aqui é o CANAL
## testado: CardArtCatalog testa "não-preto" (RGB) porque a Card Art
## usa fundo preto sólido, sem transparência real; os 40 assets de
## Pelotão TÊM alfa real (confirmado por composição sobre fundo
## magenta na auditoria anterior), então o canal correto a testar é o
## ALFA (byte índice+3 em RGBA8), nunca RGB.
static func content_alpha_rect_for(card_name: String, orientation: String = "FRONT") -> Rect2i:
	var cache_key: String = card_name + "|" + orientation
	if _alpha_rect_cache.has(cache_key):
		return _alpha_rect_cache[cache_key]
	if not has_art_for(card_name):
		return Rect2i()

	var image := Image.new()
	if image.load(_absolute_path_for(card_name)) != OK:
		return Rect2i()

	var rect: Rect2i = _detect_alpha_rect(image)
	_alpha_rect_cache[cache_key] = rect
	return rect


static func _detect_alpha_rect(image: Image) -> Rect2i:
	var w: int = image.get_width()
	var h: int = image.get_height()
	var step_x: int = max(1, w / 220)
	var step_y: int = max(1, h / 220)
	var min_x: int = w
	var max_x: int = -1
	var min_y: int = h
	var max_y: int = -1

	if image.get_format() == Image.FORMAT_RGBA8:
		var data: PackedByteArray = image.get_data()
		for y in range(0, h, step_y):
			var row_base: int = y * w * 4
			for x in range(0, w, step_x):
				var idx: int = row_base + x * 4
				if data[idx + 3] > 5:
					min_x = min(min_x, x)
					max_x = max(max_x, x)
					min_y = min(min_y, y)
					max_y = max(max_y, y)
	else:
		for y in range(0, h, step_y):
			for x in range(0, w, step_x):
				if image.get_pixel(x, y).a > 0.02:
					min_x = min(min_x, x)
					max_x = max(max_x, x)
					min_y = min(min_y, y)
					max_y = max(max_y, y)

	if max_x < 0:
		return Rect2i(0, 0, w, h)
	return Rect2i(min_x, min_y, max_x - min_x + step_x, max_y - min_y + step_y).intersection(Rect2i(0, 0, w, h))


## Textura pronta pra exibição — já recortada exatamente no retângulo
## alfa real (AtlasTexture, o PNG fonte nunca é modificado, só a REGIÃO
## exibida em runtime). null nos mesmos casos de raw_texture_for().
static func cropped_texture_for(card_name: String, orientation: String = "FRONT") -> Texture2D:
	var base: Texture2D = raw_texture_for(card_name, orientation)
	if base == null:
		return null
	var rect: Rect2i = content_alpha_rect_for(card_name, orientation)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return base
	var atlas := AtlasTexture.new()
	atlas.atlas = base
	atlas.region = Rect2(rect)
	return atlas
