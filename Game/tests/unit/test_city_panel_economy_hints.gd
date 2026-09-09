class_name TestCityPanelEconomyHints
extends RefCounted
## TestCityPanelEconomyHints (Auditoria FASE 22.1, achado I)
##
## PG e Fragmentos nunca eram explicados em lugar nenhum — só o número
## nu no HUD da Cidade. _maybe_show_economy_hints()/_show_hint_banner()
## (city_panel.gd) mostram uma dica contextual (TutorialHintBanner, a
## mesma primitiva já usada por _maybe_show_tutorial_hint()) na primeira
## vez que cada recurso passa a existir de verdade (generation_points >
## 0 / algum Fragmento > 0) — cada uma com sua própria progress_flag,
## nunca reaparece depois.
##
## IMPORTANTE: KingdomState.kingdom é o Reino GLOBAL compartilhado por
## toda a suíte (test_main.gd só o inicializa 1x). Este teste salva e
## restaura generation_points/resources/progress_flags exatamente como
## encontrou, para nunca vazar estado para outras suítes.

static func run(ctx: TestRunner.Context) -> bool:
	print("[Auditoria 22.1] Validando dicas contextuais de PG/Fragmentos na Cidade...")

	var kingdom: Kingdom = KingdomState.kingdom
	var original_pg: int = kingdom.generation_points
	var original_resources: Dictionary = kingdom.resources.duplicate(true)
	var original_flags: Dictionary = kingdom.progress_flags.duplicate(true)

	# Estado limpo de propósito, para o teste ser determinístico
	# independente do que rodou antes na mesma suíte.
	kingdom.generation_points = 0
	kingdom.resources.clear()
	kingdom.progress_flags.erase("pg_hint_seen")
	kingdom.progress_flags.erase("fragmentos_hint_seen")

	# Sem anotação de tipo (Variant): city_panel.gd não tem class_name
	# (é anexado à cena via caminho de arquivo, nunca referenciado por
	# identificador global em nenhum outro script) — mesma observação já
	# registrada em pve_panel.gd/army_editor_panel.gd sobre tipos assim.
	var panel = preload("res://scenes/city/city_panel.gd").new()

	panel._maybe_show_economy_hints(kingdom)
	print("  [1] Sem PG e sem Fragmentos, nenhuma dica aparece? %s" % str(panel.get_child_count() == 0))
	ctx.check(panel.get_child_count() == 0, "[1] Com generation_points=0 e nenhum Fragmento, _maybe_show_economy_hints() não deve criar nenhum banner")

	kingdom.generation_points = 3
	panel._maybe_show_economy_hints(kingdom)
	print("  [2] PG > 0 pela 1ª vez -> 1 banner criado e 'pg_hint_seen' marcada? %s / %s" % [str(panel.get_child_count() == 1), str(kingdom.has_progress_flag("pg_hint_seen"))])
	ctx.check(panel.get_child_count() == 1, "[2] generation_points > 0 pela primeira vez deve criar exatamente 1 banner de dica")
	ctx.check(kingdom.has_progress_flag("pg_hint_seen"), "[2] Mostrar a dica de PG deve marcar 'pg_hint_seen' para nunca reaparecer")

	panel._maybe_show_economy_hints(kingdom)
	print("  [3] Chamar de novo com PG ainda > 0 não cria um 2º banner de PG? %s" % str(panel.get_child_count() == 1))
	ctx.check(panel.get_child_count() == 1, "[3] Com 'pg_hint_seen' já marcada, chamadas seguintes não devem criar outro banner de PG")

	kingdom.add_fragment("Império", 5)
	panel._maybe_show_economy_hints(kingdom)
	print("  [4] Fragmento > 0 pela 1ª vez (com PG já dispensado) -> 2º banner criado e 'fragmentos_hint_seen' marcada? %s / %s" % [str(panel.get_child_count() == 2), str(kingdom.has_progress_flag("fragmentos_hint_seen"))])
	ctx.check(panel.get_child_count() == 2, "[4] Um Fragmento > 0 pela primeira vez deve criar o banner de Fragmentos (a dica de PG já foi dispensada, não compete pelo mesmo turno)")
	ctx.check(kingdom.has_progress_flag("fragmentos_hint_seen"), "[4] Mostrar a dica de Fragmentos deve marcar 'fragmentos_hint_seen' para nunca reaparecer")

	panel._maybe_show_economy_hints(kingdom)
	print("  [5] Com as 2 dicas já dispensadas, nenhum banner novo é criado? %s" % str(panel.get_child_count() == 2))
	ctx.check(panel.get_child_count() == 2, "[5] Com ambas as progress_flags já marcadas, nenhuma chamada seguinte deve criar banner novo")

	for child: Node in panel.get_children():
		ctx.check(child is TutorialHintBanner, "[6] Cada dica criada deve ser um TutorialHintBanner real, nunca um Control genérico")

	panel.free()
	kingdom.generation_points = original_pg
	kingdom.resources = original_resources
	kingdom.progress_flags = original_flags

	return true
