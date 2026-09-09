class_name BattlefieldSlotGeometry
extends RefCounted
## BattlefieldSlotGeometry (ART-009)
##
## Geometria dos slots isométricos reais do Battlefield (mesmos 10 PNGs
## de res://assets/art/battlefields/*.png, mesma câmera, ver ART-007) —
## EXTRAÍDA aqui pra ser compartilhada só entre os protótipos isolados
## (isometric_battlefield_prototype.gd de ART-008 continua com sua
## própria cópia, intocada — este arquivo é usado só pelo NOVO
## battle_unit_art_prototype.gd de ART-009, nenhum código de produção
## foi tocado). Os valores de ORIGIN/E1/E2 são os mesmos já medidos e
## validados visualmente em ART-007/ART-008, nunca recalculados aqui.
##
## CombatBoard.COLUMN_A/B/C continua sendo a ÚNICA fonte da posição
## LÓGICA (1-9) — este arquivo só converte essa posição lógica pra um
## ponto visual em pixels da imagem-fonte do Battlefield.

const BATTLEFIELD_IMAGE_SIZE: Vector2 = Vector2(1536.0, 1024.0)

const ENEMY_TILE_ORIGIN: Vector2 = Vector2(863.0, 330.0)
const ENEMY_TILE_E1: Vector2 = Vector2(-65.0, 22.0)
const ENEMY_TILE_E2: Vector2 = Vector2(95.0, 22.0)
const PLAYER_TILE_ORIGIN: Vector2 = Vector2(497.5, 594.0)
const PLAYER_TILE_E1: Vector2 = Vector2(-105.0, 65.0)
const PLAYER_TILE_E2: Vector2 = Vector2(100.0, 37.0)

## CombatBoard posição (1-9) -> (índice de profundidade 0-2, índice de
## coluna 0-2). Coluna A=[1,6,7] (frente->fundo), B=[2,5,8], C=[3,4,9]
## — mesma fonte que CombatBoard.COLUMN_A/B/C, nunca recalculada.
const POSITION_GRID: Dictionary = {
	1: Vector2i(0, 0), 6: Vector2i(1, 0), 7: Vector2i(2, 0),
	2: Vector2i(0, 1), 5: Vector2i(1, 1), 8: Vector2i(2, 1),
	3: Vector2i(0, 2), 4: Vector2i(1, 2), 9: Vector2i(2, 2),
}


## side 0 = jogador (bloco de baixo, mais perto da câmera); side 1 =
## inimigo (bloco de cima, mais longe). Fixo neste protótipo isolado
## (sem CombatState real) — equivalente a player_side=0 sempre.
static func is_top_cluster(side: int) -> bool:
	return side == 1


## Índice de profundidade VISUAL (0 = fileira mais longe da câmera
## DENTRO do próprio bloco, 2 = fileira mais perto da câmera DENTRO do
## próprio bloco) — não confundir com o índice de profundidade LÓGICO
## de CombatBoard (Linha 1 = frente de combate, mais perto do
## INIMIGO). Os dois só coincidem no bloco do jogador; no bloco
## inimigo são invertidos (a Linha 1 do inimigo, mais perto do
## jogador, cai na fileira MAIS PERTO da câmera dentro do bloco
## inimigo — ver _visual_center_frac). Esta distinção é o que decide
## qual fileira recebe a caixa-alvo maior (ver DEPTH_REGION_SCALE em
## battle_unit_art_prototype.gd): tamanho segue distância REAL da
## câmera, não o rótulo de Linha do CombatBoard.
static func visual_depth_index(side: int, position: int) -> int:
	var grid: Vector2i = POSITION_GRID[position]
	var logical_depth: int = grid.x
	if is_top_cluster(side):
		return 2 - logical_depth
	return logical_depth


static func _cluster_geometry(side: int) -> Dictionary:
	if is_top_cluster(side):
		return {"origin": ENEMY_TILE_ORIGIN, "e1": ENEMY_TILE_E1, "e2": ENEMY_TILE_E2}
	return {"origin": PLAYER_TILE_ORIGIN, "e1": PLAYER_TILE_E1, "e2": PLAYER_TILE_E2}


## Centro visual do slot (fração 0..1 da imagem-fonte do Battlefield).
static func visual_center_frac(side: int, position: int) -> Vector2:
	var grid: Vector2i = POSITION_GRID[position]
	var column_index: int = grid.y
	var r: int = visual_depth_index(side, position)
	var geo: Dictionary = _cluster_geometry(side)
	var center_px: Vector2 = geo["origin"] + float(r) * geo["e1"] + float(column_index) * geo["e2"]
	return Vector2(center_px.x / BATTLEFIELD_IMAGE_SIZE.x, center_px.y / BATTLEFIELD_IMAGE_SIZE.y)


## Largura de referência (px da imagem-fonte) de UM slot do bloco —
## único número usado pra converter as caixas-alvo (frações) de cada
## Região em pixels reais, nunca pra decidir posição.
static func tile_width_px(side: int) -> float:
	var geo: Dictionary = _cluster_geometry(side)
	return (geo["e2"] as Vector2).length()
