class_name TestUserDataDirGuard
extends RefCounted
## TestUserDataDirGuard (FASE 23.1 — Infraestrutura de Testes)
##
## Cobre a função pura UserDataDirGuard.is_safe_user_data_dir() (nunca
## a chamada real abort_if_unsafe(), que teria efeito colateral de
## encerrar o próprio processo de teste) e
## should_enforce_from_cmdline() — as duas funções que decidem se um
## diretório/uma execução é segura o bastante para tocar
## KingdomSaveService. Ver engine/testing/user_data_dir_guard.gd para o
## incidente real que motivou esta suíte.

const GuardScript = preload("res://engine/testing/user_data_dir_guard.gd")


static func run(ctx: TestRunner.Context) -> bool:
	print("[UserDataDirGuard] Validando a guarda de isolamento de user://...")

	# --- Caminhos seguros: "test_userdata" como segmento completo ---
	var safe_1: bool = GuardScript.is_safe_user_data_dir("F:/DigoFtto/Desktop/Battle_Simulator/Game/build/test_userdata/abc-123/Godot/app_userdata/Battle Simulator")
	print("  [A1] Caminho real de run_tests.ps1 (Windows/forward-slash) é seguro? %s (esperado: true)" % str(safe_1))
	ctx.check(safe_1, "[A1] Um caminho com 'test_userdata' como segmento completo deve ser seguro")

	var safe_2: bool = GuardScript.is_safe_user_data_dir("F:\\DigoFtto\\Desktop\\Battle_Simulator\\Game\\build\\test_userdata\\abc-123\\Godot\\app_userdata\\Battle Simulator")
	print("  [A2] Mesmo caminho com barra invertida (Windows nativo) é seguro? %s (esperado: true)" % str(safe_2))
	ctx.check(safe_2, "[A2] Barras invertidas devem ser normalizadas antes de checar o segmento")

	# --- Caminhos INSEGUROS: o incidente real e variações ---
	var real_path: bool = GuardScript.is_safe_user_data_dir("C:/Users/engfa/AppData/Roaming/Godot/app_userdata/Battle Simulator")
	print("  [B1] O user:// real (o do incidente) é seguro? %s (esperado: false)" % str(real_path))
	ctx.check(not real_path, "[B1] O diretório real do jogador NUNCA pode ser considerado seguro")

	var empty_path: bool = GuardScript.is_safe_user_data_dir("")
	print("  [B2] Caminho vazio é seguro? %s (esperado: false)" % str(empty_path))
	ctx.check(not empty_path, "[B2] Um caminho vazio nunca é seguro (nunca um 'true' por omissão)")

	# --- Substring solta NUNCA conta como segmento — só o segmento
	# inteiro "test_userdata" é aceito, exatamente como documentado. ---
	var fake_substring_1: bool = GuardScript.is_safe_user_data_dir("C:/Users/engfa/nottest_userdatafake/Godot/app_userdata/Battle Simulator")
	print("  [C1] 'nottest_userdatafake' (substring solta, não segmento) é seguro? %s (esperado: false)" % str(fake_substring_1))
	ctx.check(not fake_substring_1, "[C1] Uma substring solta nunca deve satisfazer a checagem — só um segmento de caminho inteiro")

	var fake_substring_2: bool = GuardScript.is_safe_user_data_dir("C:/test_userdataXYZ/Godot/app_userdata/Battle Simulator")
	print("  [C2] 'test_userdataXYZ' (segmento com sufixo extra) é seguro? %s (esperado: false)" % str(fake_substring_2))
	ctx.check(not fake_substring_2, "[C2] O segmento precisa ser EXATAMENTE 'test_userdata', nunca um prefixo de um segmento maior")

	# --- should_enforce_from_cmdline(): só true quando o marcador está
	# nos argumentos DE USUÁRIO (nunca nos argumentos de engine). ---
	var enforce_true: bool = GuardScript.should_enforce_from_cmdline(PackedStringArray(["--user-data-dir", "--suite=battle_replay_persistence"]))
	print("  [D1] Argumentos de usuário com '--user-data-dir' presente -> enforce? %s (esperado: true)" % str(enforce_true))
	ctx.check(enforce_true, "[D1] should_enforce_from_cmdline() deve reconhecer o marcador quando presente")

	var enforce_false: bool = GuardScript.should_enforce_from_cmdline(PackedStringArray(["--suite=battle_replay_persistence"]))
	print("  [D2] Argumentos de usuário SEM o marcador -> enforce? %s (esperado: false — jogo real nunca deve ser afetado)" % str(enforce_false))
	ctx.check(not enforce_false, "[D2] Sem o marcador (caso do jogador real/build exportada), a checagem nunca deve ser ativada")

	var enforce_empty: bool = GuardScript.should_enforce_from_cmdline(PackedStringArray([]))
	print("  [D3] Nenhum argumento de usuário -> enforce? %s (esperado: false)" % str(enforce_empty))
	ctx.check(not enforce_empty, "[D3] Uma lista vazia de argumentos (jogo real de verdade) nunca deve ativar a checagem")

	return true
