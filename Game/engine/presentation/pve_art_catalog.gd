class_name PvEArtCatalog
extends RefCounted
## PvEArtCatalog (ART-003)
##
## Resolve o caminho da arte de Trilha (por Facção + Região) e do
## ícone de Fase (por Facção + categoria da Fase) — dado puro de
## apresentação, mesmo princípio de CardArtCatalog/BattlefieldArtCatalog/
## CityBuildingArtCatalog (ART-001/ART-002).
##
## Chaves: SEM identificador novo — reaproveita exatamente o que o
## jogo já usa:
##   - Territory.faction ("Império"/"Natureza"/"Mortos-Vivos");
##   - Trilha.region_for_fase(fase) (1/2/3);
##   - ExpeditionRuntime.current_fase_type() ("regional"/"normal"/"comum")
##     + ExpeditionRuntime.current_fase_is_acampamento() (bool) —
##     combinados aqui em "fase_category" (ver _fase_category_for()).

const TRILHA_ART_DIR: String = "res://assets/art/pve/trilhas/"
const FASE_ICON_ART_DIR: String = "res://assets/art/pve/fase_icones/"

const FACTION_SLUGS: Dictionary = {
	"Império": "imperio",
	"Natureza": "natureza",
	"Mortos-Vivos": "mortos_vivos",
}

const VALID_FASE_CATEGORIES: Array[String] = ["acampamento", "chefe_regional", "chefe_normal", "comum"]


static func trilha_texture_path_for(faction: String, region: int) -> String:
	if not FACTION_SLUGS.has(faction) or region < 1 or region > 3:
		return ""
	return TRILHA_ART_DIR + "%s_regiao_%d.png" % [FACTION_SLUGS[faction], region]


static func trilha_texture_for(faction: String, region: int) -> Texture2D:
	var path: String = trilha_texture_path_for(faction, region)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


## "fase_category" já resolvida (ver _fase_category_for() abaixo pra
## derivar a partir de ExpeditionRuntime) — separado em duas funções
## pra CityBuildingArtCatalog-style catalog nunca precisar conhecer
## ExpeditionRuntime, só strings.
static func fase_icon_texture_path_for(faction: String, fase_category: String) -> String:
	if not FACTION_SLUGS.has(faction) or not VALID_FASE_CATEGORIES.has(fase_category):
		return ""
	return FASE_ICON_ART_DIR + "%s_%s.png" % [FACTION_SLUGS[faction], fase_category]


static func fase_icon_texture_for(faction: String, fase_category: String) -> Texture2D:
	var path: String = fase_icon_texture_path_for(faction, fase_category)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


## Deriva "fase_category" (uma das 4 chaves de arte) a partir do estado
## REAL de uma ExpeditionRuntime — nunca inventa uma 5ª categoria.
##
## "acampamento" usa expedition.is_waiting_at_acampamento (o ESTADO —
## a Expedição está de fato parada, aguardando decisão do jogador,
## mesmo sinal que pve_panel.gd já usa pra trocar "Tentar Fase Atual"
## por "Continuar"), NUNCA Trilha.is_acampamento(current_fase) direto
## (que é só uma propriedade do NÚMERO da Fase, e pode ser true pra
## uma Fase que é, ao mesmo tempo, um Chefe Normal — "Fase 100: Chefe
## Normal, e também Acampamento (deslocado)", ver test_expedition_runtime.gd —
## usar isso mostraria o ícone de Acampamento pacífico bem na hora de
## uma luta contra Chefe, o oposto do que a arte deveria comunicar).
## Chefe Regional prevalece sobre Chefe Normal na mesma Fase (PvE.md —
## mesma prioridade que Trilha.chefe_type() já aplica).
static func fase_category_for_expedition(expedition: ExpeditionRuntime) -> String:
	if expedition.is_waiting_at_acampamento:
		return "acampamento"
	match expedition.current_fase_type():
		"regional":
			return "chefe_regional"
		"normal":
			return "chefe_normal"
		_:
			return "comum"


## Deriva "fase_category" para uma Fase QUALQUER da Trilha (não só a
## atual de uma Expedição) — necessário pro Mapa de Trilha (F-020), que
## mostra uma janela de Fases ao redor da atual, não só ela. Ao
## contrário de fase_category_for_expedition() (que usa o ESTADO
## is_waiting_at_acampamento), aqui não existe "estado" pra uma Fase que
## não é a atual — usa diretamente Trilha.chefe_type()/is_acampamento(),
## com a mesma prioridade: Chefe (Normal ou Regional) sempre prevalece
## sobre Acampamento na mesma Fase (PvE.md — mesma prioridade que
## Trilha.chefe_type() já aplica entre si).
static func fase_category_for_fase_number(trilha: Trilha, fase: int) -> String:
	match trilha.chefe_type(fase):
		"regional":
			return "chefe_regional"
		"normal":
			return "chefe_normal"
	if trilha.is_acampamento(fase):
		return "acampamento"
	return "comum"
