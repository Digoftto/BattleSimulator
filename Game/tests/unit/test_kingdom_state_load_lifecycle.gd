class_name TestKingdomStateLoadLifecycle
extends RefCounted
## TestKingdomStateLoadLifecycle (F-013)
##
## Regressão para o ciclo de vida de persistência real conectado nesta
## Sprint: KingdomState._load_or_create_kingdom() decide entre
## carregar um save existente ou inicializar um Reino novo do zero —
## exatamente a mesma lógica que roda de verdade em
## KingdomState.initialize_new_kingdom() (chamada por
## city_panel.gd._ready(), ANTES da checagem que decide se o Kit
## Inicial deve aparecer). Chamamos o método diretamente (não
## initialize_new_kingdom()) porque este é um autoload singleton com
## guarda de idempotência (is_initialized) já disparada uma vez por
## test_main.gd — _load_or_create_kingdom() não toca nesse estado do
## singleton, só recebe/devolve um Kingdom, por isso é seguro chamar
## isoladamente aqui sem interferir no resto da suíte.
##
## Também cobre o disparo real de save (autosave e fechamento de
## janela) chamando KingdomState._process()/notification() diretamente
## — sem esperar 60s de verdade nem fechar uma janela de verdade.
##
## Usa user://kingdom_save.json de verdade — limpa antes E depois de
## cada cenário pra não vazar estado entre cenários nem pra fora desta
## suíte (bootstrap.tscn/main.tscn rodados depois no mesmo processo).

static func run(ctx: TestRunner.Context) -> bool:
	print("[F-013] Validando o ciclo de vida de Load/Save de KingdomState...")

	_check_no_save_creates_fresh_kingdom(ctx)
	_check_existing_save_loads_previous_kingdom(ctx)
	_check_corrupted_save_does_not_crash(ctx)
	_check_close_request_saves_the_live_kingdom(ctx)
	_check_autosave_timer_saves_the_live_kingdom(ctx)

	return true


## "Um jogo sem save continua iniciando normalmente."
static func _check_no_save_creates_fresh_kingdom(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var candidate: Kingdom = KingdomState._load_or_create_kingdom()

	print("  [Sem save] Kit Inicial ainda não usado? %s (esperado: true)" % str(not candidate.starter_kit_used))
	ctx.check(not candidate.starter_kit_used, "Sem save em disco, o Reino novo deve começar com starter_kit_used = false, como sempre")

	print("  [Sem save] 3 Minas Iniciais criadas? %d (esperado: 3)" % candidate.initial_mines.size())
	ctx.check(candidate.initial_mines.size() == 3, "Sem save em disco, a inicialização de Reino novo deve criar as 3 Minas Iniciais, como sempre")

	print("  [Sem save] Exceção Inicial do Centro de Recrutamento aplicada (ciclo já não está zerado)? %s (esperado: true)" % str(
		candidate.recruitment_center_cycle_end_unix > 0
	))
	ctx.check(candidate.recruitment_center_cycle_end_unix > 0, "Sem save em disco, a Exceção Inicial do Centro de Recrutamento deve continuar sendo aplicada, como sempre")

	KingdomSaveService.delete_save()


## "Um jogo com save existente carrega o Kingdom anterior em vez de
## criar outro." — usa um recruitment_center_cycle_end_unix propositalmente
## MUITO diferente de GameClock.now_unix() como prova de que o Reino
## carregado NÃO passou por _initialize_fresh_kingdom() (que o teria
## sobrescrito para "agora").
static func _check_existing_save_loads_previous_kingdom(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var original := Kingdom.new()
	original.starter_kit_used = true
	original.add_fragment("Império", 555)
	original.recruitment_center_cycle_end_unix = 123456789
	KingdomSaveService.save(original)

	var candidate: Kingdom = KingdomState._load_or_create_kingdom()

	print("  [Com save] Kit Inicial preservado como já usado? %s (esperado: true)" % str(candidate.starter_kit_used))
	ctx.check(candidate.starter_kit_used, "Com save em disco marcando starter_kit_used = true, o Reino carregado deve preservar isso")

	print("  [Com save] Fragmentos preservados? %d (esperado: 555)" % candidate.get_fragment("Império"))
	ctx.check(candidate.get_fragment("Império") == 555, "Com save em disco, os Fragmentos salvos devem ser recuperados, não reiniciados")

	print("  [Com save] Ciclo do Centro de Recrutamento NÃO foi reinicializado (continua o valor salvo)? %d (esperado: 123456789)" % candidate.recruitment_center_cycle_end_unix)
	ctx.check(
		candidate.recruitment_center_cycle_end_unix == 123456789,
		"Um Reino carregado nunca deve passar por _initialize_fresh_kingdom() de novo — o valor salvo deve sobreviver intacto, não ser sobrescrito para 'agora'"
	)

	KingdomSaveService.delete_save()


## "Verifique também que um save inválido/corrompido não provoca crash no boot."
static func _check_corrupted_save_does_not_crash(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var file: FileAccess = FileAccess.open(KingdomSaveService.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ isto não é um JSON válido de Reino ]]][[[")
	file.close()

	var candidate: Kingdom = KingdomState._load_or_create_kingdom()

	print("  [Save corrompido] Retornou um Reino utilizável sem travar? %s (esperado: true)" % str(candidate != null))
	ctx.check(candidate != null, "Um save corrompido nunca deve travar o boot — deve cair de volta para um Reino novo")

	print("  [Save corrompido] Reino resultante equivale a um Reino novo (Kit Inicial não usado, 3 Minas)? %s (esperado: true)" % str(
		not candidate.starter_kit_used and candidate.initial_mines.size() == 3
	))
	ctx.check(
		not candidate.starter_kit_used and candidate.initial_mines.size() == 3,
		"Um save corrompido deve produzir exatamente o mesmo resultado que 'nenhum save' — Reino novo inicializado normalmente"
	)

	KingdomSaveService.delete_save()


## Save no fechamento normal do jogo — dispara NOTIFICATION_WM_CLOSE_REQUEST
## diretamente (sem fechar uma janela de verdade) no KingdomState real
## (já inicializado por test_main.gd._ready()), e confirma que o
## Reino EM MEMÓRIA de verdade foi salvo em disco.
static func _check_close_request_saves_the_live_kingdom(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()

	var before: int = KingdomState.kingdom.get_fragment("Mortos-Vivos")
	KingdomState.kingdom.add_fragment("Mortos-Vivos", 999)

	KingdomState.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)

	print("  [Fechar janela] Save apareceu em disco após NOTIFICATION_WM_CLOSE_REQUEST? %s (esperado: true)" % str(KingdomSaveService.has_save()))
	ctx.check(KingdomSaveService.has_save(), "NOTIFICATION_WM_CLOSE_REQUEST deve salvar o Reino real em disco")

	var loaded := Kingdom.new()
	KingdomSaveService.load_into(loaded)
	print("  [Fechar janela] Fragmentos do Reino real de verdade foram persistidos? %d (esperado: %d)" % [
		loaded.get_fragment("Mortos-Vivos"), before + 999
	])
	ctx.check(loaded.get_fragment("Mortos-Vivos") == before + 999, "O save disparado pelo fechamento da janela deve refletir o Reino real em memória, não um Reino de teste isolado")

	KingdomSaveService.delete_save()


## Autosave periódico — chama KingdomState._process() diretamente com
## um delta sintético maior que AUTOSAVE_INTERVAL_SECONDS, em vez de
## esperar 60s de verdade.
static func _check_autosave_timer_saves_the_live_kingdom(ctx: TestRunner.Context) -> void:
	KingdomSaveService.delete_save()
	KingdomState._autosave_accumulator = 0.0

	var before: int = KingdomState.kingdom.get_fragment("Natureza")
	KingdomState.kingdom.add_fragment("Natureza", 111)

	KingdomState._process(KingdomState.AUTOSAVE_INTERVAL_SECONDS + 1.0)

	print("  [Autosave] Save apareceu em disco após o intervalo do autosave? %s (esperado: true)" % str(KingdomSaveService.has_save()))
	ctx.check(KingdomSaveService.has_save(), "O acumulador de autosave deve disparar save() ao ultrapassar AUTOSAVE_INTERVAL_SECONDS")

	var loaded := Kingdom.new()
	KingdomSaveService.load_into(loaded)
	print("  [Autosave] Fragmentos do Reino real de verdade foram persistidos? %d (esperado: %d)" % [
		loaded.get_fragment("Natureza"), before + 111
	])
	ctx.check(loaded.get_fragment("Natureza") == before + 111, "O autosave deve refletir o Reino real em memória")

	KingdomState._autosave_accumulator = 0.0
	KingdomSaveService.delete_save()
