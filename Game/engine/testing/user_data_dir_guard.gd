class_name UserDataDirGuard
extends RefCounted
## UserDataDirGuard (FASE 23.1 — Infraestrutura de Testes)
##
## Única fonte de verdade que decide se OS.get_user_data_dir() (onde
## "user://" resolve de verdade neste processo) é seguro para tocar o
## save do jogador (KingdomSaveService.save()/load_into()/delete_save()).
## Vive em engine/testing/ (não em tests/ nem em tools/) de propósito:
## é referenciada tanto por infraestrutura de produção (autoload/
## kingdom_state.gd, o único chokepoint real de todo save/autosave) quanto
## por testes (tests/test_main.gd) e ferramentas de depuração
## (tools/debug/*.gd) — nenhum dos dois deveria depender do outro.
##
## Bug real que motivou isto (Auditoria pré-pré-alfa, item #17), DUAS
## tentativas seguidas de isolar "user://", ambas rejeitadas:
## 1ª: "--user-data-dir <caminho POSIX>" (estilo git-bash) — o Godot
##     ignorou a flag malformada e caiu pro user:// real.
## 2ª: "--user-data-dir <caminho Windows válido>" — descoberto que
##     "--user-data-dir" NÃO É UMA FLAG REAL desta build do Godot 4.7.1
##     (confirmado lendo "godot --help" por inteiro); passá-la para o
##     Godot como argumento de ENGINE (antes do separador "--") fez o
##     parser de argumentos se confundir e carregar a cena principal do
##     jogo em vez da cena de teste pedida.
## Mecanismo real (ver Game/scripts/run_tests.ps1): isolamento de
## verdade via sobrescrita da variável de ambiente %APPDATA% SÓ do
## processo filho do Godot (é dali que o Godot resolve "user://" no
## Windows) — nenhuma flag de linha de comando envolvida no isolamento
## em si. "--user-data-dir" volta a aparecer nos argumentos, mas agora
## SÓ depois do separador "--" (onde o Godot GARANTE, pela própria
## documentação de --help, que o conteúdo nunca é interpretado pelo
## engine, só fica disponível via OS.get_cmdline_user_args()) — aqui
## ele NUNCA é uma flag, é só um marcador textual lido por
## should_enforce_from_cmdline().
##
## Duas linhas de defesa, nenhuma delas afeta o jogo real:
## 1) test_main.gd chama abort_if_unsafe() incondicionalmente, ANTES de
##    qualquer suíte rodar — cobre 100% dos testes (todos passam por
##    esse único ponto de entrada).
## 2) KingdomState.initialize_new_kingdom() chama
##    should_enforce_from_cmdline() + abort_if_unsafe() — cobre
##    QUALQUER ferramenta de depuração presente ou futura que instancie
##    uma cena real (a maioria acaba inicializando KingdomState
##    transitivamente, mesmo sem nunca mencionar Kingdom no próprio
##    código). A checagem só é ativada quando "--user-data-dir" está de
##    fato entre os argumentos DE USUÁRIO (depois de "--" —
##    OS.get_cmdline_user_args(), nunca OS.get_cmdline_args()); um
##    jogador real (ou o jogo exportado) NUNCA passa isso, então esta
##    defesa é inerte para qualquer sessão de jogo real; ela só entra
##    em ação exatamente quando run_tests.ps1 (ou algo que o imite)
##    declarou a intenção de rodar isolado.
##
## Convenção obrigatória (ver Arquitetura/TESTING_INFRASTRUCTURE.md):
## todo diretório isolado gerado por Game/scripts/run_tests.ps1 tem
## "test_userdata" como um SEGMENTO completo do caminho (nunca substring
## solta — ver is_safe_user_data_dir()), ex.: build/test_userdata/<uuid>/.
## Um diretório sem esse segmento é tratado como o user:// real/
## desconhecido — nunca seguro, sem exceção e sem flag de bypass.

const REQUIRED_PATH_SEGMENT: String = "test_userdata"


## Função pura (testável sem depender de OS.get_user_data_dir() real) —
## true somente se "test_userdata" aparecer como um segmento inteiro do
## caminho (barra normalizada), nunca uma substring solta como
## "nottest_userdatafake" ou "test_userdatax".
static func is_safe_user_data_dir(path: String) -> bool:
	if path == null or path.strip_edges() == "":
		return false
	var normalized: String = path.replace("\\", "/")
	var segments: PackedStringArray = normalized.split("/", false)
	return segments.has(REQUIRED_PATH_SEGMENT)


## Função pura — true somente quando os argumentos DE USUÁRIO (depois
## do separador "--" — sempre OS.get_cmdline_user_args(), NUNCA
## OS.get_cmdline_args(): este marcador nunca deve ser passado como
## argumento de engine, ver docstring do topo) contêm "--user-data-dir".
## Só Game/scripts/run_tests.ps1 passa esse marcador; um jogador
## real/build exportada nunca o passa. Usada por
## KingdomState.initialize_new_kingdom() para nunca afetar o jogo real.
static func should_enforce_from_cmdline(user_args: PackedStringArray) -> bool:
	return user_args.has("--user-data-dir")


## Chamada real (efeito colateral: aborta o processo). Retorna true se
## abortou — quem chama deve simplesmente "return" na sequência, nunca
## prosseguir. "tree" é passado explicitamente (nunca Engine.get_main_loop()
## por trás das cortinas) para deixar a dependência visível e esta
## função continuar chamável a partir de um script solto (extends Node)
## como os de Game/tools/debug/, ou de um autoload (KingdomState).
static func abort_if_unsafe(tree: SceneTree) -> bool:
	var current: String = OS.get_user_data_dir()
	if is_safe_user_data_dir(current):
		return false

	push_error("ERRO: tentativa de executar testes usando o save real.")
	print("ERRO: tentativa de executar testes usando o save real.")
	print("user:// resolvido para: %s" % current)
	print("Esperado: um diretório isolado contendo o segmento '%s' — use Game/scripts/run_tests.ps1 (ver Arquitetura/TESTING_INFRASTRUCTURE.md), nunca invoque o Godot diretamente para testes/ferramentas de depuração." % REQUIRED_PATH_SEGMENT)
	tree.quit(1)
	return true
