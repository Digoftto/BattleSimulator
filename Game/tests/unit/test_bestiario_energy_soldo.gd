class_name TestBestiarioEnergySoldo
extends RefCounted
## TestBestiarioEnergySoldo (Auditoria pré-pré-alfa)
##
## Cobre um achado real desta auditoria: o Bestiário nunca exibia
## Energia/Soldo da Carta selecionada (só o Editor de Exército tinha
## essa informação) — mesmo padrão de teste de
## test_army_editor_ux_audit_findings.gd (chama o builder interno
## diretamente, sem precisar da árvore de cena completa/_ready()).
##
## Verifica que a ficha de detalhe (_build_detail_area) usa exatamente
## EnergyArmy.card_energy()/Soldo.cost_for_rarity() — as MESMAS fontes de
## verdade já usadas em todo o resto do jogo (ENERGY.md/SOLDO.md) — nunca
## um valor paralelo inventado para esta tela.

## BestiarioPanel não declara `class_name` (diferente de ArmyEditorPanel) —
## instanciado via preload() do próprio .gd, nunca por um nome global que
## não existe (causa raiz de um erro de compilação real encontrado ao
## rodar este teste pela 1ª vez: "Identifier 'BestiarioPanel' not
## declared", que quebrava a compilação de TODO o test_main.gd).
const BestiarioPanelScript: GDScript = preload("res://scenes/city/panels/bestiario_panel.gd")

static func _collect_label_texts(node: Node, out: Array[String]) -> void:
	if node is Label:
		out.append((node as Label).text)
	for child: Node in node.get_children():
		_collect_label_texts(child, out)


static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria] Validando Energia/Soldo no Bestiário...")
	_test_a_detail_panel_shows_real_energy_and_soldo(ctx)
	return true


static func _test_a_detail_panel_shows_real_energy_and_soldo(ctx: TestRunner.Context) -> void:
	if not KingdomState.is_initialized:
		KingdomState.initialize_new_kingdom()

	var template: CardResource = GameDatabase.get_card("Lich Rei")
	ctx.check(template != null, "[pré-condição] 'Lich Rei' deve existir no catálogo real (GameDatabase.cards)")
	if template == null:
		return

	var panel: Control = BestiarioPanelScript.new()
	panel.set("_selected_card_name", "Lich Rei")

	var host := TextureRect.new()
	panel.call("_build_detail_area", host)

	var texts: Array[String] = []
	_collect_label_texts(host, texts)
	var combined: String = "\n".join(texts)

	var expected_energy: int = EnergyArmy.card_energy(template.tier)
	var expected_soldo: int = Soldo.cost_for_rarity(template.rarity)
	var expected_line: String = "Energia %d   Soldo %d" % [expected_energy, expected_soldo]

	print("  [A] Ficha de detalhe do Bestiário contém '%s'? %s" % [expected_line, combined.contains(expected_line)])
	ctx.check(combined.contains(expected_line), "[A] A ficha do Bestiário deve mostrar Energia/Soldo reais (EnergyArmy.card_energy()/Soldo.cost_for_rarity()), nunca ausentes")

	host.free()
	panel.free()
