class_name TestTrilhaPathLayout
extends RefCounted
## TestTrilhaPathLayout (F-021)
##
## TrilhaPathLayout distribui nós ao longo de uma curva real extraída
## da arte de Trilha — nunca inventa posições fora do traçado, e nunca
## quebra para as 9 combinações reais de Facção+Região.

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-021] Validando TrilhaPathLayout (curva do caminho real)...")

	var all_ok := true
	for faction: String in ["Império", "Natureza", "Mortos-Vivos"]:
		for region in range(1, 4):
			var waypoints: Array[Vector2] = TrilhaPathLayout.waypoints_for(faction, region)
			if waypoints.size() < 2:
				all_ok = false
				print("  FALTANDO: %s Região %d" % [faction, region])
	print("  As 9 combinações reais (Facção x Região) têm waypoints reais (>= 2 pontos)? %s" % str(all_ok))
	ctx.check(all_ok, "Todas as 9 combinações reais de Facção+Região devem ter waypoints extraídos da arte real")

	var invalid: Array[Vector2] = TrilhaPathLayout.waypoints_for("Facção Inexistente", 1)
	print("  Facção inválida -> array vazio (nunca inventa waypoints)? %s" % str(invalid.is_empty()))
	ctx.check(invalid.is_empty(), "Uma Facção sem asset de Trilha deve retornar array vazio, nunca posições inventadas")

	var invalid_region: Array[Vector2] = TrilhaPathLayout.waypoints_for("Império", 4)
	ctx.check(invalid_region.is_empty(), "Uma Região fora de 1-3 deve retornar array vazio")

	var waypoints: Array[Vector2] = TrilhaPathLayout.waypoints_for("Império", 1)
	var points_25: Array[Vector2] = TrilhaPathLayout.evenly_spaced_points(waypoints, 25)
	print("  25 pontos pedidos -> 25 retornados? %s (%d)" % [str(points_25.size() == 25), points_25.size()])
	ctx.check(points_25.size() == 25, "evenly_spaced_points deve retornar exatamente a quantidade pedida (obtido: %d)" % points_25.size())

	var min_x: float = 999.0
	var max_x: float = -999.0
	var min_y: float = 999.0
	var max_y: float = -999.0
	for point: Vector2 in points_25:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	print("  Todos os pontos dentro da faixa 0.0-1.0 (x: %f-%f, y: %f-%f)? %s" % [
		min_x, max_x, min_y, max_y, str(min_x >= -0.001 and max_x <= 1.001 and min_y >= -0.001 and max_y <= 1.001)
	])
	ctx.check(min_x >= -0.001 and max_x <= 1.001, "Os pontos distribuídos nunca podem sair da faixa 0.0-1.0 (x) da curva real")
	ctx.check(min_y >= -0.001 and max_y <= 1.001, "Os pontos distribuídos nunca podem sair da faixa 0.0-1.0 (y) da curva real")

	var single_point: Array[Vector2] = TrilhaPathLayout.evenly_spaced_points(waypoints, 1)
	ctx.check(single_point.size() == 1, "evenly_spaced_points(waypoints, 1) deve retornar exatamente 1 ponto")

	var points_25_again: Array[Vector2] = TrilhaPathLayout.evenly_spaced_points(waypoints, 25)
	var deterministic := true
	for i in range(25):
		if not points_25[i].is_equal_approx(points_25_again[i]):
			deterministic = false
	print("  Determinístico (mesma entrada -> mesma saída)? %s" % str(deterministic))
	ctx.check(deterministic, "evenly_spaced_points deve ser puramente determinístico para a mesma curva/quantidade")

	var empty_result: Array[Vector2] = TrilhaPathLayout.evenly_spaced_points([], 10)
	ctx.check(empty_result.is_empty(), "Uma curva vazia (Facção/Região inválida) nunca deve gerar pontos inventados")

	return true
