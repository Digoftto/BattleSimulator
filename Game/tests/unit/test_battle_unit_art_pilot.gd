extends RefCounted
## TestBattleUnitArtPilot (Battle Art MVP — Piloto, 2026-09-02; geometria
## de produção substituída no Teste Visual 08, 2026-09-02)
##
## Cobre a infraestrutura do piloto de Battle Art (BattleUnitArtCatalog/
## BattleUnitArtGeometry/BattleUnitArtLayer + a integração aditiva em
## CombatReplayView) com testes de PROPRIEDADE — cada asserção compara
## contra um valor DERIVADO das mesmas funções de geometria já usadas
## em produção (nunca uma coordenada "que parece bonita").
##
## TESTE VISUAL 08: a geometria de produção mudou (CELL_CENTER calibrado
## + FOOT_CENTER + escala FIXA por lado, via
## BattleUnitArtGeometry.placement_for(side, position, card_name, ...) —
## nunca mais DEPTH_REGION_SCALE/region_box_px()/fit_scale(), que saíram
## do caminho de produção). Os testes que dependiam do comportamento
## antigo (escala variando por profundidade) foram REESCRITOS pra
## verificar a nova especificação (escala CONSTANTE por lado); os testes
## de identidade/movimento/morte/independência continuam válidos e só
## tiveram a chamada a placement_for() atualizada pra nova assinatura.
##
## TESTE LÓGICO apenas — nenhum destes testes prova que o resultado
## FICA BOM visualmente (ver relatório da tarefa: viewport não
## observável neste ambiente). Provam exclusivamente que a
## infraestrutura de anchor/escala/z-order/identidade/movimento/morte se
## comporta como especificado. Todos instanciam a CombatReplayView REAL
## (mesma classe de produção, sem nenhum override/flag de depuração do
## inspector) — o caminho exercitado aqui é o MESMO de uma batalha real.
##
## Não altera CombatEngine/CombatState/regras de combate — usa o mesmo
## padrão já estabelecido em test_replay_visual_identity.gd (CombatState
## montado à mão, CombatEngine._movement_phase() chamado diretamente,
## UNIT_DIED publicado manualmente com o mesmo formato exato do motor).

const ReplayCollectorScript = preload("res://engine/combat/combat_replay_collector.gd")
const ReplayViewScript = preload("res://scenes/combat/combat_replay_view.gd")
const ArtCatalog = preload("res://engine/presentation/battle_unit_art_catalog.gd")
const ArtGeometry = preload("res://engine/presentation/battle_unit_art_geometry.gd")

const PILOT_NAME: String = "Arqueiro Imperial"

## PILOTOS 02/03 (2026-09-02) — teste de generalização da arquitetura
## com dois casos estruturalmente diferentes do Arqueiro (humanoide):
## uma Máquina de Guerra estática (sem pernas) e um quadrúpede (postura
## de empinar, só 3 dos 4 cascos no chão). Ver derivação completa do
## ground contact de cada um em battle_unit_art_geometry.gd
## (CARD_NAME_TO_FOOT_CENTER_FRAC) e no relatório desta tarefa.
const MACHINE_PILOT_NAME: String = "Altar da Reanimação"
const MACHINE_PILOT_DIMENSIONS: Vector2 = Vector2(1536, 1024)
const QUADRUPED_PILOT_NAME: String = "Unicórnio Ancestral"
const QUADRUPED_PILOT_DIMENSIONS: Vector2 = Vector2(1208, 1302)

## FASE 2 — SEGUNDA BATERIA (2026-09-02): 5 pilotos adicionais,
## escolhidos pela auditoria completa do catálogo (categoria B — prontos
## pra integração, só precisando de ground contact medido) pra validar
## mais 5 casos estruturais: estrutura orgânica humanoide, veículo com
## rodas, estrutura com múltiplas raízes, bípede/golem robusto, bípede
## convencional adicional. Ver derivação do ground contact de cada um em
## battle_unit_art_geometry.gd (CARD_NAME_TO_FOOT_CENTER_FRAC).
const ENT_PILOT_NAME: String = "Ent Jovem"
const ENT_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CATAPULT_PILOT_NAME: String = "Balista Imperial"
const CATAPULT_PILOT_DIMENSIONS: Vector2 = Vector2(1536, 1024)
const OAK_PILOT_NAME: String = "Carvalho Ancião"
const OAK_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const BONE_WALL_PILOT_NAME: String = "Muralha de Ossos"
const BONE_WALL_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CAPTAIN_PILOT_NAME: String = "Capitão Imperial"
const CAPTAIN_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)

## FASE 3 (2026-09-03): lote seguinte de migração controlada — 22 novos
## card_name (10 Império, 10 Morto-Vivo, 2 Natureza). Mesma suíte
## genérica já usada nas Fases 1/2, sem nenhuma lógica de teste nova.
## Dimensões medidas diretamente do PNG fonte (mesma técnica das fases
## anteriores). Ver derivação do ground contact de cada um em
## battle_unit_art_geometry.gd (CARD_NAME_TO_FOOT_CENTER_FRAC) e no
## relatório desta tarefa.
const CENTURION_PILOT_NAME: String = "Centurião Imperial"
const CENTURION_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CHAMPION_PILOT_NAME: String = "Campeão Imperial"
const CHAMPION_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CROSSBOWMAN_PILOT_NAME: String = "Besteiro Imperial"
const CROSSBOWMAN_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const ENGINEER_PILOT_NAME: String = "Engenheiro Imperial"
const ENGINEER_PILOT_DIMENSIONS: Vector2 = Vector2(1536, 1024)
const GUARDIAN_PILOT_NAME: String = "Guardião Imperial"
const GUARDIAN_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const INFANTRY_PILOT_NAME: String = "Infante Imperial"
const INFANTRY_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const LEGIONARY_PILOT_NAME: String = "Legionário Imperial"
const LEGIONARY_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const MARSHAL_PILOT_NAME: String = "Marechal Imperial"
const MARSHAL_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const SQUIRE_PILOT_NAME: String = "Escudeiro Imperial"
const SQUIRE_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const SUMMONER_PILOT_NAME: String = "Evocador Imperial"
const SUMMONER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const SPECTRAL_REAPER_PILOT_NAME: String = "Ceifadora Espectral"
const SPECTRAL_REAPER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const SPECTRAL_ARCHER_PILOT_NAME: String = "Arqueira Espectral"
const SPECTRAL_ARCHER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const SKELETON_WARRIOR_PILOT_NAME: String = "Esqueleto Guerreiro"
const SKELETON_WARRIOR_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const PUTRID_ABOMINATION_PILOT_NAME: String = "Abominação Putrefata"
const PUTRID_ABOMINATION_PILOT_DIMENSIONS: Vector2 = Vector2(1224, 1285)
const PROFANE_PRIEST_PILOT_NAME: String = "Sacerdote Profano"
const PROFANE_PRIEST_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const LICH_KING_PILOT_NAME: String = "Lich Rei"
const LICH_KING_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const INITIATE_LICH_PILOT_NAME: String = "Liche Iniciado"
const INITIATE_LICH_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CULTIST_PILOT_NAME: String = "Cultista da Putrefação"
const CULTIST_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const CADAVEROUS_REAPER_PILOT_NAME: String = "Ceifador Cadavérico"
const CADAVEROUS_REAPER_PILOT_DIMENSIONS: Vector2 = Vector2(1145, 1374)
const BANSHEE_PILOT_NAME: String = "Banshee"
const BANSHEE_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const MILLENNIAL_OAK_PILOT_NAME: String = "Carvalho Milenar"
const MILLENNIAL_OAK_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const GOLDEN_EAGLE_PILOT_NAME: String = "Águia Dourada"
const GOLDEN_EAGLE_PILOT_DIMENSIONS: Vector2 = Vector2(1536, 1024)

## FASE 5 (2026-09-03): os 2 card_names antes bloqueados por
## "ambiguidade" (nunca uma ambiguidade real — ver
## BattleUnitArtCatalog.CARD_NAME_TO_PATH). Dimensões medidas
## diretamente do PNG fonte, mesma técnica das fases anteriores.
const SKELETON_ARCHER_PILOT_NAME: String = "Arqueiro Esquelético"
const SKELETON_ARCHER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const REANIMATED_SKELETON_ARCHER_PILOT_NAME: String = "Arqueiro Esquelético Reanimado"
const REANIMATED_SKELETON_ARCHER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)

## FASE 6 (2026-09-04): últimos 8 pelotões do MVP, integrados COMO
## ESTÃO (fringing/conteúdo conhecidos, não corrigidos — ver relatório
## desta tarefa). Dimensões medidas diretamente do PNG fonte.
const PORCUPINE_PILOT_NAME: String = "Porco-Espinho Ancestral"
const PORCUPINE_PILOT_DIMENSIONS: Vector2 = Vector2(1230, 1278)
const ANCESTRAL_TREE_PILOT_NAME: String = "Árvore Ancestral"
const ANCESTRAL_TREE_PILOT_DIMENSIONS: Vector2 = Vector2(1156, 1361)
const ANCIENT_BEAR_PILOT_NAME: String = "Urso Ancestral"
const ANCIENT_BEAR_PILOT_DIMENSIONS: Vector2 = Vector2(1207, 1303)
const ANCIENT_WILLOW_PILOT_NAME: String = "Salgueiro Ancião"
const ANCIENT_WILLOW_PILOT_DIMENSIONS: Vector2 = Vector2(1173, 1341)
const FLOWER_OF_DAWN_PILOT_NAME: String = "Flor da Aurora"
const FLOWER_OF_DAWN_PILOT_DIMENSIONS: Vector2 = Vector2(1225, 1284)
const LION_PILOT_NAME: String = "Leão da Savana"
const LION_PILOT_DIMENSIONS: Vector2 = Vector2(1239, 1269)
const CLIMBER_PILOT_NAME: String = "Trepadeira Ancestral"
const CLIMBER_PILOT_DIMENSIONS: Vector2 = Vector2(1024, 1536)
const HEART_OF_FOREST_PILOT_NAME: String = "Coração da Floresta"
const HEART_OF_FOREST_PILOT_DIMENSIONS: Vector2 = Vector2(1230, 1278)


static func run(ctx: TestRunner.Context) -> bool:
	print("[Battle Art Piloto] Validando asset/alpha/anchor/escala/z-order/movimento/morte/identidade do piloto (%s)..." % PILOT_NAME)
	_test_1_asset_is_loaded(ctx)
	_test_2_asset_has_real_alpha_margin(ctx)
	_test_3_4_5_anchor_positions_1_and_9(ctx)
	_test_6_scale_constant_across_positions_per_side(ctx)
	_test_7_aspect_ratio_preserved(ctx)
	_test_8_9_both_sides_use_different_geometry(ctx)
	_test_10_11_unit_moved_uses_unit_id_multi_step(ctx)
	_test_12_13_unit_died_removes_without_ghost(ctx)
	_test_14_two_units_same_card_name_are_independent(ctx)
	_test_15_foot_center_matches_cell_center_key_positions(ctx)
	_test_16_all_18_positions_foot_center_matches_cell_center(ctx)
	_test_17_battle_card_view_hidden_when_battle_art_present(ctx)
	print("[Battle Art Piloto 02] Validando generalização para Máquina de Guerra (%s)..." % MACHINE_PILOT_NAME)
	_run_generic_pilot_suite(ctx, MACHINE_PILOT_NAME, MACHINE_PILOT_DIMENSIONS, "P02")
	print("[Battle Art Piloto 03] Validando generalização para quadrúpede (%s)..." % QUADRUPED_PILOT_NAME)
	_run_generic_pilot_suite(ctx, QUADRUPED_PILOT_NAME, QUADRUPED_PILOT_DIMENSIONS, "P03")
	print("[Battle Art Fase 2] Validando generalização para estrutura orgânica humanoide (%s)..." % ENT_PILOT_NAME)
	_run_generic_pilot_suite(ctx, ENT_PILOT_NAME, ENT_PILOT_DIMENSIONS, "P04")
	print("[Battle Art Fase 2] Validando generalização para veículo com rodas (%s)..." % CATAPULT_PILOT_NAME)
	_run_generic_pilot_suite(ctx, CATAPULT_PILOT_NAME, CATAPULT_PILOT_DIMENSIONS, "P05")
	print("[Battle Art Fase 2] Validando generalização para estrutura com múltiplas raízes (%s)..." % OAK_PILOT_NAME)
	_run_generic_pilot_suite(ctx, OAK_PILOT_NAME, OAK_PILOT_DIMENSIONS, "P06")
	print("[Battle Art Fase 2] Validando generalização para bípede/golem robusto (%s)..." % BONE_WALL_PILOT_NAME)
	_run_generic_pilot_suite(ctx, BONE_WALL_PILOT_NAME, BONE_WALL_PILOT_DIMENSIONS, "P07")
	print("[Battle Art Fase 2] Validando generalização para bípede convencional adicional (%s)..." % CAPTAIN_PILOT_NAME)
	_run_generic_pilot_suite(ctx, CAPTAIN_PILOT_NAME, CAPTAIN_PILOT_DIMENSIONS, "P08")
	print("[Battle Art Fase 3] Validando lote seguinte (10 Império, 10 Morto-Vivo, 2 Natureza)...")
	_run_generic_pilot_suite(ctx, CENTURION_PILOT_NAME, CENTURION_PILOT_DIMENSIONS, "P09")
	_run_generic_pilot_suite(ctx, CHAMPION_PILOT_NAME, CHAMPION_PILOT_DIMENSIONS, "P10")
	_run_generic_pilot_suite(ctx, CROSSBOWMAN_PILOT_NAME, CROSSBOWMAN_PILOT_DIMENSIONS, "P11")
	_run_generic_pilot_suite(ctx, ENGINEER_PILOT_NAME, ENGINEER_PILOT_DIMENSIONS, "P12")
	_run_generic_pilot_suite(ctx, GUARDIAN_PILOT_NAME, GUARDIAN_PILOT_DIMENSIONS, "P13")
	_run_generic_pilot_suite(ctx, INFANTRY_PILOT_NAME, INFANTRY_PILOT_DIMENSIONS, "P14")
	_run_generic_pilot_suite(ctx, LEGIONARY_PILOT_NAME, LEGIONARY_PILOT_DIMENSIONS, "P15")
	_run_generic_pilot_suite(ctx, MARSHAL_PILOT_NAME, MARSHAL_PILOT_DIMENSIONS, "P16")
	_run_generic_pilot_suite(ctx, SQUIRE_PILOT_NAME, SQUIRE_PILOT_DIMENSIONS, "P17")
	_run_generic_pilot_suite(ctx, SUMMONER_PILOT_NAME, SUMMONER_PILOT_DIMENSIONS, "P18")
	_run_generic_pilot_suite(ctx, SPECTRAL_REAPER_PILOT_NAME, SPECTRAL_REAPER_PILOT_DIMENSIONS, "P19")
	_run_generic_pilot_suite(ctx, SPECTRAL_ARCHER_PILOT_NAME, SPECTRAL_ARCHER_PILOT_DIMENSIONS, "P20")
	_run_generic_pilot_suite(ctx, SKELETON_WARRIOR_PILOT_NAME, SKELETON_WARRIOR_PILOT_DIMENSIONS, "P21")
	_run_generic_pilot_suite(ctx, PUTRID_ABOMINATION_PILOT_NAME, PUTRID_ABOMINATION_PILOT_DIMENSIONS, "P22")
	_run_generic_pilot_suite(ctx, PROFANE_PRIEST_PILOT_NAME, PROFANE_PRIEST_PILOT_DIMENSIONS, "P23")
	_run_generic_pilot_suite(ctx, LICH_KING_PILOT_NAME, LICH_KING_PILOT_DIMENSIONS, "P24")
	_run_generic_pilot_suite(ctx, INITIATE_LICH_PILOT_NAME, INITIATE_LICH_PILOT_DIMENSIONS, "P25")
	_run_generic_pilot_suite(ctx, CULTIST_PILOT_NAME, CULTIST_PILOT_DIMENSIONS, "P26")
	_run_generic_pilot_suite(ctx, CADAVEROUS_REAPER_PILOT_NAME, CADAVEROUS_REAPER_PILOT_DIMENSIONS, "P27")
	_run_generic_pilot_suite(ctx, BANSHEE_PILOT_NAME, BANSHEE_PILOT_DIMENSIONS, "P28")
	_run_generic_pilot_suite(ctx, MILLENNIAL_OAK_PILOT_NAME, MILLENNIAL_OAK_PILOT_DIMENSIONS, "P29")
	_run_generic_pilot_suite(ctx, GOLDEN_EAGLE_PILOT_NAME, GOLDEN_EAGLE_PILOT_DIMENSIONS, "P30")
	print("[Battle Art Fase 5] Validando os 2 card_names antes bloqueados por ambiguidade (%s / %s)..." % [SKELETON_ARCHER_PILOT_NAME, REANIMATED_SKELETON_ARCHER_PILOT_NAME])
	_run_generic_pilot_suite(ctx, SKELETON_ARCHER_PILOT_NAME, SKELETON_ARCHER_PILOT_DIMENSIONS, "P31")
	_run_generic_pilot_suite(ctx, REANIMATED_SKELETON_ARCHER_PILOT_NAME, REANIMATED_SKELETON_ARCHER_PILOT_DIMENSIONS, "P32")
	print("[Battle Art Fase 6] Validando os últimos 8 pelotões do MVP (integrados como estão — fringing/conteúdo pendentes de refinamento visual)...")
	_run_generic_pilot_suite(ctx, PORCUPINE_PILOT_NAME, PORCUPINE_PILOT_DIMENSIONS, "P33")
	_run_generic_pilot_suite(ctx, ANCESTRAL_TREE_PILOT_NAME, ANCESTRAL_TREE_PILOT_DIMENSIONS, "P34")
	_run_generic_pilot_suite(ctx, ANCIENT_BEAR_PILOT_NAME, ANCIENT_BEAR_PILOT_DIMENSIONS, "P35")
	_run_generic_pilot_suite(ctx, ANCIENT_WILLOW_PILOT_NAME, ANCIENT_WILLOW_PILOT_DIMENSIONS, "P36")
	_run_generic_pilot_suite(ctx, FLOWER_OF_DAWN_PILOT_NAME, FLOWER_OF_DAWN_PILOT_DIMENSIONS, "P37")
	_run_generic_pilot_suite(ctx, LION_PILOT_NAME, LION_PILOT_DIMENSIONS, "P38")
	_run_generic_pilot_suite(ctx, CLIMBER_PILOT_NAME, CLIMBER_PILOT_DIMENSIONS, "P39")
	_run_generic_pilot_suite(ctx, HEART_OF_FOREST_PILOT_NAME, HEART_OF_FOREST_PILOT_DIMENSIONS, "P40")
	return true


static func _card(name_value: String) -> CardResource:
	return TestMovementRules._build_combat_card(name_value, "Corpo a Corpo", 50, 50, 10)


static func _new_view():
	var view = ReplayViewScript.new()
	view._build_static_structure()
	return view


## TESTE 1: o PNG do piloto carrega de verdade (fora de res://, mesma
## técnica do protótipo ART-009) e tem o tamanho de canvas confirmado
## pela auditoria anterior (1024x1536).
static func _test_1_asset_is_loaded(ctx: TestRunner.Context) -> void:
	var texture: Texture2D = ArtCatalog.raw_texture_for(PILOT_NAME)
	print("  [1] Asset do piloto carregado? %s (tamanho: %s, esperado: (1024, 1536))" % [str(texture != null), str(texture.get_size()) if texture != null else "<null>"])
	ctx.check(texture != null, "[1] BattleUnitArtCatalog.raw_texture_for() deve carregar o PNG real do piloto ('%s')" % PILOT_NAME)
	if texture != null:
		ctx.check(texture.get_size() == Vector2(1024, 1536), "[1] Canvas do piloto deve bater com o confirmado na auditoria anterior (1024x1536), obtido: %s" % str(texture.get_size()))


## TESTE 2: o retângulo alfa real detectado é menor que o canvas inteiro
## (prova de que existe margem transparente real sendo respeitada, não
## o canvas bruto) e cobre a maior parte do personagem (não é um
## fragmento degenerado). NÃO comparado pixel a pixel contra a
## auditoria anterior em Python: aquela usava PIL Image.getbbox(), que
## conta QUALQUER alfa > 0 (mesmo 1/255) — este asset tem uma faixa
## larga de alfa muito baixo (halo/vinheta suave, ~3% "semi-transparente"
## já registrado na auditoria original) bem além da silhueta
## visualmente sólida. O limiar usado aqui (> 5/255, ~2%) é o MESMO já
## usado em produção por CardArtCatalog._detect_used_rect() — encontra
## a silhueta real, deliberadamente ignorando esse halo quase invisível
## (glow ao redor do personagem, que atravessa quase todo o canvas na
## imagem crua). Os dois números diferem por DESIGN, não por erro.
static func _test_2_asset_has_real_alpha_margin(ctx: TestRunner.Context) -> void:
	var rect: Rect2i = ArtCatalog.content_alpha_rect_for(PILOT_NAME)
	print("  [2] Retângulo alfa detectado: %s (canvas: 1024x1536)" % str(rect))
	ctx.check(rect.size.x > 0 and rect.size.y > 0, "[2] O retângulo alfa detectado deve ter área positiva")
	ctx.check(rect.size.x < 1024 or rect.size.y < 1536, "[2] O retângulo alfa deve ser MENOR que o canvas bruto (prova de margem transparente real detectada, não o canvas inteiro por fallback)")
	ctx.check(rect.size.x > 1024 * 0.3 and rect.size.y > 1536 * 0.3, "[2] O retângulo detectado deve cobrir uma porção substancial do canvas (não um fragmento degenerado)")


## TESTES 3/4/5: unidades nas Posições 1 e 9 (Side 0/Side 1) recebem
## anchor — comparado contra o valor DERIVADO da MESMA
## BattleUnitArtGeometry.placement_for(side, position, card_name, ...)
## já usada em produção, nunca um número fixo.
static func _test_3_4_5_anchor_positions_1_and_9(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var pilot_at_1 := CombatUnit.new(_card(PILOT_NAME), 0, 1)
	var filler_positions: Array[int] = [2, 3, 4, 5, 6, 7, 8]
	state.units = [pilot_at_1]
	for i in range(filler_positions.size()):
		state.units.append(CombatUnit.new(_card("Filler-%d" % i), 0, filler_positions[i]))
	var pilot_at_9 := CombatUnit.new(_card(PILOT_NAME), 1, 9)
	state.units.append(pilot_at_9)

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	print("  [3] Unidade-piloto na Posição 1 (Side 0) recebeu Battle Art registrada? %s" % str(view._unit_art_layer.has_unit(pilot_at_1.get_instance_id())))
	ctx.check(view._unit_art_layer.has_unit(pilot_at_1.get_instance_id()), "[3] Unidade com card_name do piloto deve receber um sprite de Battle Art")

	var sprite_1: TextureRect = view._unit_art_layer.sprite_for(pilot_at_1.get_instance_id())
	var content_size: Vector2 = ArtCatalog.cropped_texture_for(PILOT_NAME).get_size()
	var expected_1: Dictionary = ArtGeometry.placement_for(0, 1, PILOT_NAME, content_size.x, content_size.y)
	print("  [4] Anchor da Posição 1 bate com o valor derivado da geometria (bottom=%.4f, esperado=%.4f)?" % [sprite_1.anchor_bottom, expected_1["anchor_bottom"]])
	ctx.check(is_equal_approx(sprite_1.anchor_bottom, expected_1["anchor_bottom"]), "[4] anchor_bottom da Posição 1 deve bater com BattleUnitArtGeometry.placement_for() usando a MESMA geometria de produção")
	ctx.check(is_equal_approx(sprite_1.anchor_left, expected_1["anchor_left"]), "[4] anchor_left da Posição 1 deve bater com o valor derivado")

	var sprite_9: TextureRect = view._unit_art_layer.sprite_for(pilot_at_9.get_instance_id())
	var expected_9: Dictionary = ArtGeometry.placement_for(1, 9, PILOT_NAME, content_size.x, content_size.y)
	print("  [5] Anchor da Posição 9 (Side 1) bate com o valor derivado da geometria (bottom=%.4f, esperado=%.4f)?" % [sprite_9.anchor_bottom, expected_9["anchor_bottom"]])
	ctx.check(is_equal_approx(sprite_9.anchor_bottom, expected_9["anchor_bottom"]), "[5] anchor_bottom da Posição 9 (Side 1) deve bater com o valor derivado")
	ctx.check(not is_equal_approx(sprite_1.anchor_bottom, sprite_9.anchor_bottom), "[5] Posição 1 (Side 0) e Posição 9 (Side 1) devem ter anchors DIFERENTES (CELL_CENTER/escala diferentes, nunca o mesmo offset)")

	view.free()


## TESTE 6 (reescrito no Teste Visual 08): a NOVA especificação é escala
## CONSTANTE por lado (nunca por profundidade/posição) — Side 0 P1/P5/P9
## devem produzir exatamente o MESMO tamanho renderizado entre si; o
## mesmo para Side 1; e Side 0 != Side 1 (0.14 vs 0.10, ver seção 16 do
## pedido desta tarefa). Substitui o teste antigo (que esperava o
## OPOSTO: escala crescendo com a profundidade via DEPTH_REGION_SCALE,
## comportamento agora removido do caminho de produção).
static func _test_6_scale_constant_across_positions_per_side(ctx: TestRunner.Context) -> void:
	var content_size: Vector2 = ArtCatalog.cropped_texture_for(PILOT_NAME).get_size()

	var side0_widths: Array[float] = []
	for position in [1, 5, 9]:
		var placement: Dictionary = ArtGeometry.placement_for(0, position, PILOT_NAME, content_size.x, content_size.y)
		side0_widths.append(placement["anchor_right"] - placement["anchor_left"])

	var side1_widths: Array[float] = []
	for position in [1, 5, 9]:
		var placement: Dictionary = ArtGeometry.placement_for(1, position, PILOT_NAME, content_size.x, content_size.y)
		side1_widths.append(placement["anchor_right"] - placement["anchor_left"])

	print("  [6] Side 0 larguras renderizadas (P1/P5/P9): %s" % str(side0_widths))
	ctx.check(is_equal_approx(side0_widths[0], side0_widths[1]) and is_equal_approx(side0_widths[1], side0_widths[2]), "[6] Side 0: P1, P5 e P9 devem ter EXATAMENTE o mesmo tamanho renderizado (escala fixa por lado, nunca por profundidade)")

	print("  [6] Side 1 larguras renderizadas (P1/P5/P9): %s" % str(side1_widths))
	ctx.check(is_equal_approx(side1_widths[0], side1_widths[1]) and is_equal_approx(side1_widths[1], side1_widths[2]), "[6] Side 1: P1, P5 e P9 devem ter EXATAMENTE o mesmo tamanho renderizado (escala fixa por lado, nunca por profundidade)")

	print("  [6] Side 0 (%.5f) != Side 1 (%.5f)?" % [side0_widths[0], side1_widths[0]])
	ctx.check(not is_equal_approx(side0_widths[0], side1_widths[0]), "[6] Side 0 (escala 0.14) deve produzir um tamanho DIFERENTE de Side 1 (escala 0.10)")
	ctx.check(is_equal_approx(ArtGeometry.scale_factor_for_side(0), 0.14), "[6] ArtGeometry.scale_factor_for_side(0) deve ser 0.14 (valor aprovado, nunca recalculado)")
	ctx.check(is_equal_approx(ArtGeometry.scale_factor_for_side(1), 0.10), "[6] ArtGeometry.scale_factor_for_side(1) deve ser 0.10 (valor aprovado, nunca recalculado)")


## TESTE 7: a escala resolvida nunca deforma — largura/altura
## renderizadas (em PIXELS REAIS, não em frações brutas) preservam
## exatamente a proporção do conteúdo real (bounding box alfa), nas 18
## posições. IMPORTANTE: anchor_right-anchor_left é fração de
## BATTLEFIELD_IMAGE_SIZE.x (1536) e anchor_bottom-anchor_top é fração
## de BATTLEFIELD_IMAGE_SIZE.y (1024) — comparar as duas frações
## diretamente (sem reconverter pra pixels) compara unidades diferentes
## e sempre erra por um fator de 1536/1024 = 1.5. É por isso que este
## teste reconverte cada fração pra pixels reais ANTES de comparar.
static func _test_7_aspect_ratio_preserved(ctx: TestRunner.Context) -> void:
	var content_size: Vector2 = ArtCatalog.cropped_texture_for(PILOT_NAME).get_size()
	var content_aspect: float = content_size.x / content_size.y
	for side in [0, 1]:
		for position in range(1, 10):
			var placement: Dictionary = ArtGeometry.placement_for(side, position, PILOT_NAME, content_size.x, content_size.y)
			var render_w_px: float = (placement["anchor_right"] - placement["anchor_left"]) * ArtGeometry.BATTLEFIELD_IMAGE_SIZE.x
			var render_h_px: float = (placement["anchor_bottom"] - placement["anchor_top"]) * ArtGeometry.BATTLEFIELD_IMAGE_SIZE.y
			var render_aspect: float = render_w_px / render_h_px
			ctx.check(is_equal_approx(render_aspect, content_aspect), "[7] A proporção renderizada (Side %d Posição %d) deve ser idêntica à proporção do conteúdo real, nunca deformada" % [side, position])
	print("  [7] Proporção preservada nas 18 posições (aspect esperado: %.4f)?" % content_aspect)


## TESTES 8/9: Side 0 e Side 1 funcionam e usam geometrias DIFERENTES
## (nunca um offset reaproveitado cegamente do outro lado) — mesma
## Posição lógica (5), lados diferentes.
static func _test_8_9_both_sides_use_different_geometry(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var pilot_side_0 := CombatUnit.new(_card(PILOT_NAME), 0, 5)
	var pilot_side_1 := CombatUnit.new(_card(PILOT_NAME), 1, 5)
	state.units = [pilot_side_0, pilot_side_1]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	print("  [8] Side 0 recebeu Battle Art na Posição 5? %s" % str(view._unit_art_layer.has_unit(pilot_side_0.get_instance_id())))
	ctx.check(view._unit_art_layer.has_unit(pilot_side_0.get_instance_id()), "[8] Side 0 deve funcionar (unidade recebe Battle Art)")
	print("  [9] Side 1 recebeu Battle Art na Posição 5? %s" % str(view._unit_art_layer.has_unit(pilot_side_1.get_instance_id())))
	ctx.check(view._unit_art_layer.has_unit(pilot_side_1.get_instance_id()), "[9] Side 1 deve funcionar (unidade recebe Battle Art)")

	var sprite_0: TextureRect = view._unit_art_layer.sprite_for(pilot_side_0.get_instance_id())
	var sprite_1: TextureRect = view._unit_art_layer.sprite_for(pilot_side_1.get_instance_id())
	print("     Mesma Posição lógica (5), Sides diferentes -> anchors diferentes (Side0 top=%.4f, Side1 top=%.4f)?" % [sprite_0.anchor_top, sprite_1.anchor_top])
	ctx.check(not is_equal_approx(sprite_0.anchor_top, sprite_1.anchor_top), "[9] A mesma Posição lógica nos dois lados deve produzir anchors diferentes (CELL_CENTER/escala distintos) — nunca reaproveitar cegamente o offset de um lado no outro")

	view.free()


## TESTES 10/11: UNIT_MOVED localizado por unit_id (nunca card_name);
## movimento multi-passo (9 -> ... -> 3) preserva a MESMA instância de
## sprite, atualizando o anchor a cada passo (pro CELL_CENTER da nova
## posição), sem sprite duplicado.
static func _test_10_11_unit_moved_uses_unit_id_multi_step(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var fix_1 := CombatUnit.new(_card("Fix-1"), 0, 1)
	var fix_2 := CombatUnit.new(_card("Fix-2"), 0, 2)
	var mover := CombatUnit.new(_card(PILOT_NAME), 0, 9)
	state.units = [fix_1, fix_2, mover]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var sprite_before: TextureRect = view._unit_art_layer.sprite_for(mover.get_instance_id())
	ctx.check(sprite_before != null, "[10] Unidade-piloto deve receber Battle Art antes de se mover")

	CombatEngine._movement_phase(state)
	print("  [10/11] Mover-piloto atravessou 9 -> %d numa única Fase (esperado: 3)" % mover.position)
	ctx.check(mover.position == 3, "[11] Mover-piloto deve avançar de 9 até 3 (bloqueado por Fix-2 na Posição 2)")

	for event: Dictionary in collector.replay_events:
		if event["kind"] == "move":
			view._apply_replay_event(event)

	var move_events: Array = collector.replay_events.filter(func(e): return e["kind"] == "move")
	print("     %d eventos UNIT_MOVED aplicados, todos com o unit_id do piloto" % move_events.size())
	ctx.check(move_events.size() == 6, "[11] Devem existir 6 eventos UNIT_MOVED (9->8->7->6->5->4->3)")
	ctx.check(move_events.all(func(e): return e["unit_id"] == mover.get_instance_id()), "[10] Todo evento UNIT_MOVED do piloto deve carregar o MESMO unit_id")

	var sprite_after: TextureRect = view._unit_art_layer.sprite_for(mover.get_instance_id())
	print("  [10] A MESMA instância de sprite foi reaproveitada através dos 6 passos (nunca recriada)? %s" % str(sprite_before == sprite_after))
	ctx.check(sprite_before == sprite_after, "[10] O sprite de Battle Art deve ser a MESMA instância antes/depois do movimento multi-passo (reposicionado, nunca recriado)")
	ctx.check(view._unit_art_layer.unit_count() == 1, "[11] Deve existir exatamente 1 sprite de Battle Art para o piloto após o movimento multi-passo (sem duplicação)")

	var content_size: Vector2 = ArtCatalog.cropped_texture_for(PILOT_NAME).get_size()
	var expected_final: Dictionary = ArtGeometry.placement_for(0, 3, PILOT_NAME, content_size.x, content_size.y)
	ctx.check(is_equal_approx(sprite_after.anchor_bottom, expected_final["anchor_bottom"]), "[11] O anchor final deve corresponder ao CELL_CENTER da Posição 3 (destino real do movimento multi-passo)")

	view.free()


## TESTES 12/13: UNIT_DIED remove o sprite (nenhum "fantasma" — mesmo
## princípio da correção de _apply_death_event() em CombatReplayView).
static func _test_12_13_unit_died_removes_without_ghost(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var victim := CombatUnit.new(_card(PILOT_NAME), 0, 4)
	state.units = [victim]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()
	ctx.check(view._unit_art_layer.has_unit(victim.get_instance_id()), "[12] Vítima deve ter Battle Art registrada antes de morrer")

	victim.is_alive = false
	victim.current_hp = 0
	var death_ctx := CombatContext.new()
	death_ctx.state = state
	death_ctx.turn = state.turn
	death_ctx.attacker = victim
	death_ctx.side = victim.side
	death_ctx.position = victim.position
	state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)
	view._apply_replay_event(collector.replay_events[collector.replay_events.size() - 1])

	print("  [12] Unidade morta removida visualmente (Battle Art)? %s" % str(not view._unit_art_layer.has_unit(victim.get_instance_id())))
	ctx.check(not view._unit_art_layer.has_unit(victim.get_instance_id()), "[12] UNIT_DIED deve remover o sprite de Battle Art da unidade")
	print("  [13] Nenhum sprite fantasma restante na camada (filhos: %d)?" % view._unit_art_layer.get_child_count())
	ctx.check(view._unit_art_layer.get_child_count() == 0, "[13] Nenhum nó de sprite deve permanecer na árvore depois da morte (sem fantasma)")
	ctx.check(view._unit_art_layer.unit_count() == 0, "[13] O registro interno de unidades deve ficar vazio depois da morte")

	view.free()


## TESTE 14: duas unidades com o MESMO card_name (do piloto) no MESMO
## lado permanecem INDEPENDENTES — mover uma nunca afeta a outra, e
## ambas mantêm seu próprio sprite (mesma garantia já validada para
## BattleCardView em test_replay_visual_identity.gd, agora também pra
## Battle Art).
static func _test_14_two_units_same_card_name_are_independent(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var blocker := CombatUnit.new(_card("Bloqueador"), 0, 1)
	var unit_a := CombatUnit.new(_card(PILOT_NAME), 0, 2)
	var unit_b := CombatUnit.new(_card(PILOT_NAME), 0, 4)
	state.units = [blocker, unit_a, unit_b]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var sprite_a_before: TextureRect = view._unit_art_layer.sprite_for(unit_a.get_instance_id())
	var sprite_b_before: TextureRect = view._unit_art_layer.sprite_for(unit_b.get_instance_id())
	ctx.check(sprite_a_before != sprite_b_before, "[14] Duas unidades com o mesmo card_name devem ter sprites de Battle Art DISTINTOS desde o início")
	ctx.check(view._unit_art_layer.unit_count() == 2, "[14] Devem existir exatamente 2 sprites de Battle Art (um por unit_id, mesmo com card_name igual)")

	CombatEngine._movement_phase(state)
	for event: Dictionary in collector.replay_events:
		if event["kind"] == "move":
			view._apply_replay_event(event)

	print("  [14] unit_a (bloqueada) permaneceu na Posição 2, unit_b avançou pra 3 (esperado: 2, 3)? obtido: %d, %d" % [unit_a.position, unit_b.position])
	ctx.check(unit_a.position == 2, "[14] unit_a deve permanecer bloqueada na Posição 2")
	ctx.check(unit_b.position == 3, "[14] unit_b deve avançar para a Posição 3")

	var sprite_a_after: TextureRect = view._unit_art_layer.sprite_for(unit_a.get_instance_id())
	var sprite_b_after: TextureRect = view._unit_art_layer.sprite_for(unit_b.get_instance_id())
	ctx.check(sprite_a_after == sprite_a_before, "[14] O sprite de unit_a não deve ser recriado nem afetado pelo movimento de unit_b")
	ctx.check(sprite_a_after.anchor_bottom == sprite_a_before.anchor_bottom, "[14] O anchor de unit_a deve permanecer exatamente o mesmo (ela não se moveu)")

	var content_size: Vector2 = ArtCatalog.cropped_texture_for(PILOT_NAME).get_size()
	var expected_b: Dictionary = ArtGeometry.placement_for(0, 3, PILOT_NAME, content_size.x, content_size.y)
	ctx.check(is_equal_approx(sprite_b_after.anchor_bottom, expected_b["anchor_bottom"]), "[14] O anchor de unit_b deve refletir o CELL_CENTER da nova Posição 3, de forma independente de unit_a")
	ctx.check(view._unit_art_layer.unit_count() == 2, "[14] Ainda devem existir exatamente 2 sprites depois do movimento (nenhuma unidade duplicada ou perdida)")

	view.free()


## Ponto FOOT_CENTER real de um sprite já posicionado (anchor_left/top +
## fração do tamanho renderizado) — usado pelos Testes 15/16 pra
## verificar, a partir do resultado REAL desenhado pela produção, que o
## FOOT_CENTER coincide com o CELL_CENTER calibrado (nunca comparando
## anchors brutos, que dependem também da largura/altura renderizadas).
static func _actual_foot_center_screen_frac(sprite: TextureRect, card_name: String = PILOT_NAME) -> Vector2:
	var w: float = sprite.anchor_right - sprite.anchor_left
	var h: float = sprite.anchor_bottom - sprite.anchor_top
	var foot_center_frac_in_content: Vector2 = ArtGeometry.foot_center_frac_for(card_name)
	return Vector2(
		sprite.anchor_left + foot_center_frac_in_content.x * w,
		sprite.anchor_top + foot_center_frac_in_content.y * h,
	)


## TESTE 15 (seção 15 do pedido — casos A-F): pra Side 0 P1/P5/P9 e Side
## 1 P1/P5/P9, o FOOT_CENTER real do sprite (calculado a partir do
## anchor que a produção de verdade aplicou, via CombatReplayView real —
## nenhum override) deve coincidir EXATAMENTE com
## ArtGeometry.cell_center_frac(side, position).
static func _test_15_foot_center_matches_cell_center_key_positions(ctx: TestRunner.Context) -> void:
	var cases: Array = [[0, 1], [0, 5], [0, 9], [1, 1], [1, 5], [1, 9]]
	var labels: Array = ["A", "B", "C", "D", "E", "F"]
	for i in range(cases.size()):
		var side: int = cases[i][0]
		var position: int = cases[i][1]
		var state := CombatState.new()
		var unit := CombatUnit.new(_card(PILOT_NAME), side, position)
		state.units = [unit]

		var collector = ReplayCollectorScript.new()
		collector.attach(state.event_bus)
		collector.snapshot_initial_board(state)

		var view = _new_view()
		view.replay_collector = collector
		view._apply_initial_board()

		var sprite: TextureRect = view._unit_art_layer.sprite_for(unit.get_instance_id())
		var actual_foot_center: Vector2 = _actual_foot_center_screen_frac(sprite)
		var expected_cell_center: Vector2 = ArtGeometry.cell_center_frac(side, position)
		print("  [15%s] Side %d P%d: FOOT_CENTER real=%s, CELL_CENTER esperado=%s" % [labels[i], side, position, str(actual_foot_center), str(expected_cell_center)])
		ctx.check(actual_foot_center.is_equal_approx(expected_cell_center), "[15%s] FOOT_CENTER real do Battle Art (Side %d, Posição %d) deve coincidir EXATAMENTE com CELL_CENTER[%d][%d]" % [labels[i], side, position, side, position])

		view.free()


## TESTE 16 (seção 15 do pedido — "e também verificar todas as 18
## combinações"): mesma verificação do Teste 15, agora para as 18
## posições reais (2 lados x 9 posições cada), num único tabuleiro
## completo — a mesma configuração que uma batalha real de verdade usa.
static func _test_16_all_18_positions_foot_center_matches_cell_center(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var units_by_key: Dictionary = {}
	for side in [0, 1]:
		for position in range(1, 10):
			var unit := CombatUnit.new(_card(PILOT_NAME), side, position)
			state.units.append(unit)
			units_by_key[side * 10 + position] = unit

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var all_matched: bool = true
	for side in [0, 1]:
		for position in range(1, 10):
			var unit: CombatUnit = units_by_key[side * 10 + position]
			var sprite: TextureRect = view._unit_art_layer.sprite_for(unit.get_instance_id())
			var actual_foot_center: Vector2 = _actual_foot_center_screen_frac(sprite)
			var expected_cell_center: Vector2 = ArtGeometry.cell_center_frac(side, position)
			if not actual_foot_center.is_equal_approx(expected_cell_center):
				all_matched = false
			ctx.check(actual_foot_center.is_equal_approx(expected_cell_center), "[16] FOOT_CENTER real (Side %d, Posição %d) deve coincidir com CELL_CENTER calibrado" % [side, position])

	print("  [16] As 18 posições (2 lados x 9) têm FOOT_CENTER == CELL_CENTER calibrado? %s" % str(all_matched))
	view.free()


## TESTE 17 (Teste Visual 08, seção 6/11): quando a unidade tem Battle
## Art registrada, a carta compacta (BattleCardView) fica com alpha 0
## (não desenha, mas continua "visible"/mouse-interativa — ver
## combat_replay_view.gd, _refresh_position_widget()); uma unidade SEM
## Battle Art continua com a carta 100% opaca, exatamente como antes
## desta tarefa.
static func _test_17_battle_card_view_hidden_when_battle_art_present(ctx: TestRunner.Context) -> void:
	var state := CombatState.new()
	var pilot := CombatUnit.new(_card(PILOT_NAME), 0, 1)
	var regular := CombatUnit.new(_card("Sem Battle Art"), 0, 2)
	state.units = [pilot, regular]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var pilot_card_view = view._position_widgets[0 * 10 + 1]["view"]
	var regular_card_view = view._position_widgets[0 * 10 + 2]["view"]

	print("  [17] Carta do piloto (tem Battle Art) com alpha 0? %s (alpha=%.2f)" % [str(is_equal_approx(pilot_card_view.modulate.a, 0.0)), pilot_card_view.modulate.a])
	ctx.check(is_equal_approx(pilot_card_view.modulate.a, 0.0), "[17] A carta compacta de uma unidade com Battle Art deve ficar com alpha 0 (Battle Art é a representação visual principal)")
	ctx.check(pilot_card_view.visible, "[17] A carta compacta deve continuar 'visible' (nunca visible=false) para preservar o popup de hover — só o alpha muda")
	ctx.check(pilot_card_view.mouse_filter == Control.MOUSE_FILTER_STOP, "[17] A carta compacta deve continuar recebendo mouse_entered/exited (infraestrutura de hover preservada)")

	print("  [17] Carta da unidade SEM Battle Art com alpha 1? %s (alpha=%.2f)" % [str(is_equal_approx(regular_card_view.modulate.a, 1.0)), regular_card_view.modulate.a])
	ctx.check(is_equal_approx(regular_card_view.modulate.a, 1.0), "[17] A carta compacta de uma unidade SEM Battle Art deve continuar 100% opaca")

	view.free()


## PILOTOS 02/03 — SUÍTE GENÉRICA (2026-09-02)
##
## Cobre, pra QUALQUER card_name com Battle Art registrada, os mesmos 15
## itens pedidos nesta tarefa (asset/alpha/ground contact/CELL_CENTER/
## Side 0/Side 1/9 posições/escala constante/proporção/unit_id/
## UNIT_MOVED/movimento 9->3/UNIT_DIED/sem fantasma/carta oculta) — a
## MESMA lógica já provada pros Testes 1-17 acima (Arqueiro), agora
## parametrizada por card_name/dimensão esperada, sem duplicar código
## por piloto. Não repete os testes de INDEPENDÊNCIA entre unidades de
## mesmo nome (Teste 14) nem os de anchor absoluto em px (Testes 3/4/5)
## — já cobertos estruturalmente pelo Teste 16 (as 18 posições reais,
## que é estritamente mais forte: cobre P1/P9 E as outras 16).
static func _run_generic_pilot_suite(ctx: TestRunner.Context, card_name: String, expected_dimensions: Vector2, tag: String) -> void:
	_generic_test_asset_and_alpha(ctx, card_name, expected_dimensions, tag)
	_generic_test_18_positions_ground_contact_matches_cell_center(ctx, card_name, tag)
	_generic_test_scale_constant_per_side(ctx, card_name, tag)
	_generic_test_aspect_ratio_preserved(ctx, card_name, tag)
	_generic_test_movement_and_death(ctx, card_name, tag)
	_generic_test_card_view_hidden(ctx, card_name, tag)


## ITENS 1/2/3 (asset correto / alpha / ground contact existe e é
## plausível — 0..1 nos dois eixos, nunca fora do próprio conteúdo).
static func _generic_test_asset_and_alpha(ctx: TestRunner.Context, card_name: String, expected_dimensions: Vector2, tag: String) -> void:
	var texture: Texture2D = ArtCatalog.raw_texture_for(card_name)
	print("  [%s.1] Asset '%s' carregado? %s (tamanho: %s, esperado: %s)" % [tag, card_name, str(texture != null), str(texture.get_size()) if texture != null else "<null>", str(expected_dimensions)])
	ctx.check(texture != null, "[%s.1] BattleUnitArtCatalog.raw_texture_for() deve carregar o PNG real de '%s'" % [tag, card_name])
	if texture != null:
		ctx.check(texture.get_size() == expected_dimensions, "[%s.1] Canvas de '%s' deve bater com a dimensão real medida na auditoria desta tarefa, obtido: %s" % [tag, card_name, str(texture.get_size())])

	var rect: Rect2i = ArtCatalog.content_alpha_rect_for(card_name)
	print("  [%s.2] Retângulo alfa detectado pra '%s': %s" % [tag, card_name, str(rect)])
	ctx.check(rect.size.x > 0 and rect.size.y > 0, "[%s.2] O retângulo alfa detectado deve ter área positiva" % tag)
	ctx.check(rect.size.x <= expected_dimensions.x and rect.size.y <= expected_dimensions.y, "[%s.2] O retângulo alfa nunca pode exceder o canvas bruto" % tag)

	var ground_contact: Vector2 = ArtGeometry.foot_center_frac_for(card_name)
	print("  [%s.3] Ground contact de '%s': %s" % [tag, card_name, str(ground_contact)])
	ctx.check(ground_contact.x >= 0.0 and ground_contact.x <= 1.0 and ground_contact.y >= 0.0 and ground_contact.y <= 1.0, "[%s.3] O ground contact medido deve estar dentro do próprio conteúdo (fração 0..1), nunca fora dele" % tag)


## ITENS 4/5/6/7 (CELL_CENTER nas 18 posições, Side 0, Side 1, "todas as
## 9 posições") — mesma técnica do Teste 16 (Arqueiro), parametrizada.
static func _generic_test_18_positions_ground_contact_matches_cell_center(ctx: TestRunner.Context, card_name: String, tag: String) -> void:
	var state := CombatState.new()
	var units_by_key: Dictionary = {}
	for side in [0, 1]:
		for position in range(1, 10):
			var unit := CombatUnit.new(_card(card_name), side, position)
			state.units.append(unit)
			units_by_key[side * 10 + position] = unit

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var all_matched: bool = true
	for side in [0, 1]:
		ctx.check(view._unit_art_layer.has_unit(units_by_key[side * 10 + 1].get_instance_id()), "[%s.%d] Side %d deve funcionar (unidade recebe Battle Art)" % [tag, 5 if side == 0 else 6, side])
		for position in range(1, 10):
			var unit: CombatUnit = units_by_key[side * 10 + position]
			var sprite: TextureRect = view._unit_art_layer.sprite_for(unit.get_instance_id())
			var actual: Vector2 = _actual_foot_center_screen_frac(sprite, card_name)
			var expected: Vector2 = ArtGeometry.cell_center_frac(side, position)
			if not actual.is_equal_approx(expected):
				all_matched = false
			ctx.check(actual.is_equal_approx(expected), "[%s.4] Ground contact real (Side %d, Posição %d) de '%s' deve coincidir com CELL_CENTER calibrado" % [tag, side, position, card_name])

	print("  [%s.4] As 18 posições (2 lados x 9) de '%s' têm ground contact == CELL_CENTER calibrado? %s" % [tag, card_name, str(all_matched)])
	view.free()


## ITEM 8 (escala constante por lado, nunca por posição/profundidade) —
## mesma técnica do Teste 6 (Arqueiro), parametrizada.
static func _generic_test_scale_constant_per_side(ctx: TestRunner.Context, card_name: String, tag: String) -> void:
	var content_size: Vector2 = ArtCatalog.cropped_texture_for(card_name).get_size()
	for side in [0, 1]:
		var widths: Array[float] = []
		for position in [1, 5, 9]:
			var placement: Dictionary = ArtGeometry.placement_for(side, position, card_name, content_size.x, content_size.y)
			widths.append(placement["anchor_right"] - placement["anchor_left"])
		print("  [%s.8] '%s' Side %d larguras renderizadas (P1/P5/P9): %s" % [tag, card_name, side, str(widths)])
		ctx.check(is_equal_approx(widths[0], widths[1]) and is_equal_approx(widths[1], widths[2]), "[%s.8] '%s' Side %d: P1, P5 e P9 devem ter EXATAMENTE o mesmo tamanho renderizado" % [tag, card_name, side])


## ITEM 9 (proporção preservada, nas 18 posições).
static func _generic_test_aspect_ratio_preserved(ctx: TestRunner.Context, card_name: String, tag: String) -> void:
	var content_size: Vector2 = ArtCatalog.cropped_texture_for(card_name).get_size()
	var content_aspect: float = content_size.x / content_size.y
	for side in [0, 1]:
		for position in range(1, 10):
			var placement: Dictionary = ArtGeometry.placement_for(side, position, card_name, content_size.x, content_size.y)
			var render_w_px: float = (placement["anchor_right"] - placement["anchor_left"]) * ArtGeometry.BATTLEFIELD_IMAGE_SIZE.x
			var render_h_px: float = (placement["anchor_bottom"] - placement["anchor_top"]) * ArtGeometry.BATTLEFIELD_IMAGE_SIZE.y
			ctx.check(is_equal_approx(render_w_px / render_h_px, content_aspect), "[%s.9] '%s' (Side %d Posição %d): proporção renderizada deve ser idêntica à do conteúdo real" % [tag, card_name, side, position])
	print("  [%s.9] Proporção de '%s' preservada nas 18 posições (aspect esperado: %.4f)?" % [tag, card_name, content_aspect])


## ITENS 10/11/12/13/14 (unit_id, UNIT_MOVED, movimento 9->3, UNIT_DIED,
## sem sprite fantasma) — mesma técnica dos Testes 10/11/12/13
## (Arqueiro), parametrizada.
static func _generic_test_movement_and_death(ctx: TestRunner.Context, card_name: String, tag: String) -> void:
	var state := CombatState.new()
	var fix_1 := CombatUnit.new(_card("Fix-1-%s" % tag), 0, 1)
	var fix_2 := CombatUnit.new(_card("Fix-2-%s" % tag), 0, 2)
	var mover := CombatUnit.new(_card(card_name), 0, 9)
	state.units = [fix_1, fix_2, mover]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var sprite_before: TextureRect = view._unit_art_layer.sprite_for(mover.get_instance_id())
	ctx.check(sprite_before != null, "[%s.10] '%s' deve receber Battle Art antes de se mover" % [tag, card_name])

	CombatEngine._movement_phase(state)
	print("  [%s.12] '%s' atravessou 9 -> %d numa única Fase (esperado: 3)" % [tag, card_name, mover.position])
	ctx.check(mover.position == 3, "[%s.12] '%s' deve avançar de 9 até 3 (bloqueado por Fix-2 na Posição 2)" % [tag, card_name])

	for event: Dictionary in collector.replay_events:
		if event["kind"] == "move":
			view._apply_replay_event(event)

	var move_events: Array = collector.replay_events.filter(func(e): return e["kind"] == "move")
	ctx.check(move_events.size() == 6, "[%s.11] Devem existir 6 eventos UNIT_MOVED (9->8->7->6->5->4->3) pra '%s'" % [tag, card_name])
	ctx.check(move_events.all(func(e): return e["unit_id"] == mover.get_instance_id()), "[%s.10] Todo evento UNIT_MOVED de '%s' deve carregar o MESMO unit_id" % [tag, card_name])

	var sprite_after: TextureRect = view._unit_art_layer.sprite_for(mover.get_instance_id())
	ctx.check(sprite_before == sprite_after, "[%s.10] O sprite de Battle Art de '%s' deve ser a MESMA instância antes/depois do movimento (reposicionado, nunca recriado)" % [tag, card_name])
	ctx.check(view._unit_art_layer.unit_count() == 1, "[%s.11] Deve existir exatamente 1 sprite de Battle Art pra '%s' após o movimento (sem duplicação)" % [tag, card_name])

	var content_size: Vector2 = ArtCatalog.cropped_texture_for(card_name).get_size()
	var expected_final: Dictionary = ArtGeometry.placement_for(0, 3, card_name, content_size.x, content_size.y)
	ctx.check(is_equal_approx(sprite_after.anchor_bottom, expected_final["anchor_bottom"]), "[%s.12] O anchor final de '%s' deve corresponder ao CELL_CENTER da Posição 3" % [tag, card_name])

	# Morte: reaproveita a MESMA unidade já parada na Posição 3.
	mover.is_alive = false
	mover.current_hp = 0
	var death_ctx := CombatContext.new()
	death_ctx.state = state
	death_ctx.turn = state.turn
	death_ctx.attacker = mover
	death_ctx.side = mover.side
	death_ctx.position = mover.position
	state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)
	view._apply_replay_event(collector.replay_events[collector.replay_events.size() - 1])

	print("  [%s.13] '%s' morto removido visualmente (Battle Art)? %s" % [tag, card_name, str(not view._unit_art_layer.has_unit(mover.get_instance_id()))])
	ctx.check(not view._unit_art_layer.has_unit(mover.get_instance_id()), "[%s.13] UNIT_DIED deve remover o sprite de Battle Art de '%s'" % [tag, card_name])
	ctx.check(view._unit_art_layer.unit_count() == 0, "[%s.14] Nenhum sprite de Battle Art (nem fantasma) deve restar depois da morte de '%s'" % [tag, card_name])

	view.free()


## ITEM 15 (BattleCardView oculta quando há Battle Art).
static func _generic_test_card_view_hidden(ctx: TestRunner.Context, card_name: String, tag: String) -> void:
	var state := CombatState.new()
	var pilot := CombatUnit.new(_card(card_name), 0, 1)
	state.units = [pilot]

	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = _new_view()
	view.replay_collector = collector
	view._apply_initial_board()

	var pilot_card_view = view._position_widgets[0 * 10 + 1]["view"]
	print("  [%s.15] Carta de '%s' (tem Battle Art) com alpha 0? %s (alpha=%.2f)" % [tag, card_name, str(is_equal_approx(pilot_card_view.modulate.a, 0.0)), pilot_card_view.modulate.a])
	ctx.check(is_equal_approx(pilot_card_view.modulate.a, 0.0), "[%s.15] A carta compacta de '%s' deve ficar com alpha 0 (Battle Art é a representação visual principal)" % [tag, card_name])
	ctx.check(pilot_card_view.visible, "[%s.15] A carta compacta de '%s' deve continuar 'visible' (popup de hover preservado)" % [tag, card_name])

	view.free()
