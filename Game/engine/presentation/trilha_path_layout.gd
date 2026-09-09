class_name TrilhaPathLayout
extends RefCounted
## TrilhaPathLayout (F-021)
##
## Curva de referência do caminho já pintado em cada asset real de
## Trilha (`Game/assets/art/pve/trilhas/{facção}_regiao_{1,2,3}.png`) —
## usada para posicionar os nós de Fase DIRETAMENTE sobre o caminho da
## arte, em vez de numa faixa administrativa separada.
##
## LIMITAÇÃO REAL, DOCUMENTADA (auditoria da Fase 20.3, item H): cada um
## dos 9 assets tem um caminho sinuoso pintado à mão, único, com
## aproximadamente 25 a 33 nós circulares dourados já desenhados —
## cobrindo uma Região inteira (até 3.000 Fases reais). NÃO existe
## metadado no arquivo de imagem ligando esses ~25-33 nós a números de
## Fase específicos, e uma correspondência 1:1 entre eles e as Fases
## reais é impossível sem inventar dados (auditoria da Fase 20.1 já
## havia confirmado que os assets não são tileable/segmentáveis).
##
## Solução adotada: os WAYPOINTS abaixo foram extraídos por INSPEÇÃO
## VISUAL REAL de cada um dos 9 assets (frações relativas 0.0-1.0 de
## largura/altura, aproximadas — não são coordenadas de pixel exatas de
## um arquivo de metadata, que não existe) e servem como um TEMPLATE DE
## CURVA reutilizável: a cada página de Fases exibida (ver
## PvEPanel.SEGMENT_SIZE), os nós daquela página são distribuídos
## igualmente espaçados (por comprimento de arco) ao longo desta MESMA
## curva real — a curva nunca muda de forma, só os nós que a percorrem
## mudam de número de Fase. Isso preserva "os nós ficam sobre o caminho
## real da arte" sem fingir que o nó desenhado nº 14 da imagem
## corresponde literalmente à Fase 1247.

const FASE_ICON_DIR_UNUSED: String = ""  # reservado — sem uso hoje.

## faction_slug + "_regiao_" + region -> Array[Vector2] (frações 0.0-1.0
## de largura/altura da imagem 1536x1024), em ordem da esquerda pra
## direita, seguindo o traçado real do caminho em cada asset.
const WAYPOINTS: Dictionary = {
	"imperio_regiao_1": [
		Vector2(0.00, 0.37), Vector2(0.12, 0.47), Vector2(0.25, 0.33), Vector2(0.37, 0.35),
		Vector2(0.50, 0.47), Vector2(0.62, 0.37), Vector2(0.75, 0.34), Vector2(0.87, 0.47),
		Vector2(1.00, 0.36),
	],
	"imperio_regiao_2": [
		Vector2(0.00, 0.42), Vector2(0.12, 0.30), Vector2(0.25, 0.42), Vector2(0.37, 0.55),
		Vector2(0.50, 0.38), Vector2(0.62, 0.55), Vector2(0.75, 0.32), Vector2(0.87, 0.45),
		Vector2(1.00, 0.32),
	],
	"imperio_regiao_3": [
		Vector2(0.00, 0.44), Vector2(0.12, 0.38), Vector2(0.25, 0.52), Vector2(0.37, 0.42),
		Vector2(0.50, 0.50), Vector2(0.62, 0.40), Vector2(0.75, 0.52), Vector2(0.87, 0.42),
		Vector2(1.00, 0.48),
	],
	"natureza_regiao_1": [
		Vector2(0.00, 0.38), Vector2(0.12, 0.48), Vector2(0.25, 0.36), Vector2(0.37, 0.50),
		Vector2(0.50, 0.42), Vector2(0.62, 0.30), Vector2(0.75, 0.42), Vector2(0.87, 0.52),
		Vector2(1.00, 0.40),
	],
	"natureza_regiao_2": [
		Vector2(0.00, 0.32), Vector2(0.12, 0.44), Vector2(0.25, 0.30), Vector2(0.37, 0.52),
		Vector2(0.50, 0.36), Vector2(0.62, 0.30), Vector2(0.75, 0.46), Vector2(0.87, 0.32),
		Vector2(1.00, 0.48),
	],
	"natureza_regiao_3": [
		Vector2(0.00, 0.40), Vector2(0.12, 0.28), Vector2(0.25, 0.44), Vector2(0.37, 0.36),
		Vector2(0.50, 0.50), Vector2(0.62, 0.34), Vector2(0.75, 0.46), Vector2(0.87, 0.30),
		Vector2(1.00, 0.44),
	],
	"mortos_vivos_regiao_1": [
		Vector2(0.00, 0.40), Vector2(0.12, 0.48), Vector2(0.25, 0.36), Vector2(0.37, 0.44),
		Vector2(0.50, 0.30), Vector2(0.62, 0.42), Vector2(0.75, 0.50), Vector2(0.87, 0.34),
		Vector2(1.00, 0.44),
	],
	"mortos_vivos_regiao_2": [
		Vector2(0.00, 0.34), Vector2(0.12, 0.42), Vector2(0.25, 0.48), Vector2(0.37, 0.32),
		Vector2(0.50, 0.42), Vector2(0.62, 0.50), Vector2(0.75, 0.34), Vector2(0.87, 0.44),
		Vector2(1.00, 0.50),
	],
	"mortos_vivos_regiao_3": [
		Vector2(0.00, 0.42), Vector2(0.12, 0.36), Vector2(0.25, 0.46), Vector2(0.37, 0.38),
		Vector2(0.50, 0.44), Vector2(0.62, 0.36), Vector2(0.75, 0.46), Vector2(0.87, 0.38),
		Vector2(1.00, 0.44),
	],
}


static func waypoints_for(faction: String, region: int) -> Array[Vector2]:
	if not PvEArtCatalog.FACTION_SLUGS.has(faction) or region < 1 or region > 3:
		return []
	var key: String = "%s_regiao_%d" % [PvEArtCatalog.FACTION_SLUGS[faction], region]
	var raw: Array = WAYPOINTS.get(key, [])
	var result: Array[Vector2] = []
	for point: Vector2 in raw:
		result.append(point)
	return result


## Distribui "count" pontos igualmente espaçados por comprimento de arco
## ao longo da polyline definida por "waypoints" (frações 0.0-1.0).
## count == 1 retorna o ponto médio do traçado. Array vazio se
## "waypoints" tiver menos de 2 pontos ou count <= 0.
static func evenly_spaced_points(waypoints: Array[Vector2], count: int) -> Array[Vector2]:
	if waypoints.size() < 2 or count <= 0:
		return []

	var segment_lengths: Array[float] = []
	var total_length: float = 0.0
	for i in range(waypoints.size() - 1):
		var length: float = waypoints[i].distance_to(waypoints[i + 1])
		segment_lengths.append(length)
		total_length += length

	if total_length <= 0.0:
		var flat_result: Array[Vector2] = []
		for i in range(count):
			flat_result.append(waypoints[0])
		return flat_result

	var result: Array[Vector2] = []
	for i in range(count):
		var target: float = total_length if count == 1 else (float(i) / float(count - 1)) * total_length
		result.append(_point_at_arc_length(waypoints, segment_lengths, target))
	return result


static func _point_at_arc_length(waypoints: Array[Vector2], segment_lengths: Array[float], target: float) -> Vector2:
	var traveled: float = 0.0
	for i in range(segment_lengths.size()):
		var length: float = segment_lengths[i]
		if length <= 0.0:
			continue
		if traveled + length >= target or i == segment_lengths.size() - 1:
			var remaining: float = clampf(target - traveled, 0.0, length)
			var ratio: float = remaining / length
			return waypoints[i].lerp(waypoints[i + 1], ratio)
		traveled += length
	return waypoints[-1]
