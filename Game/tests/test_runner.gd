class_name TestRunner
extends RefCounted
## TestRunner (F-001, Etapa 0)
##
## Runner mínimo e nativo — sem dependência externa (GUT/gdUnit4 etc.),
## por decisão registrada do F-001: o projeto já tem 114 validações
## seguindo um padrão de asserção textual consistente; um framework
## externo exigiria reescrever a lógica de cada uma. Este runner
## envelopa esse mesmo padrão (print "esperado: X") numa contagem real
## de PASS/FAIL, produzindo um exit code confiável — nenhuma lógica de
## teste migrada é reimplementada, só a "borda" de relato muda.
##
## Convenção obrigatória para toda função de teste registrada: deve
## terminar com "return true" na última linha executada normalmente.
## Isso permite detectar um erro de execução real (GDScript não tem
## try/catch): se um erro de script interromper a função antes desse
## "return true", a chamada via Callable retorna o valor padrão (null)
## em vez de "true" — comportamento confirmado empiricamente nesta
## sessão (F-003): um erro de runtime aborta apenas a função corrente,
## nunca propaga para quem chamou, que continua rodando normalmente.
## O runner usa exatamente esse sinal para marcar "erro de execução",
## distinto de "asserção falhou".


class Result:
	var pass_count: int = 0
	var fail_count: int = 0
	var error_count: int = 0

	func total() -> int:
		return pass_count + fail_count + error_count

	func ok() -> bool:
		return fail_count == 0 and error_count == 0


## Contexto passado para cada função de teste — API mínima de
## asserção. Equivalente ao "(esperado: X)" já usado em bootstrap.gd,
## agora contabilizado de verdade em vez de só impresso pra leitura
## humana.
class Context:
	var _result: Result
	var _test_name: String

	func _init(result: Result, test_name: String) -> void:
		_result = result
		_test_name = test_name

	func check(condition: bool, description: String) -> void:
		if condition:
			_result.pass_count += 1
			print("  [PASS] %s: %s" % [_test_name, description])
		else:
			_result.fail_count += 1
			print("  [FAIL] %s: %s" % [_test_name, description])


## {suite_name: {test_name: Callable}} — Callable deve aceitar um
## único parâmetro Context e retornar true ao terminar normalmente.
var _suites: Dictionary = {}


func register(suite_name: String, test_name: String, test_func: Callable) -> void:
	if not _suites.has(suite_name):
		_suites[suite_name] = {}
	_suites[suite_name][test_name] = test_func


## Roda os testes selecionados por suíte/nome ("" = sem filtro nesse
## eixo). Retorna true somente se todas as asserções passaram E todo
## teste selecionado terminou normalmente (nenhum erro de execução) E
## pelo menos um teste rodou. Nunca lança — cada teste é isolado pela
## convenção de retorno descrita acima, não por try/catch (GDScript
## não tem).
func run(suite_filter: String = "", test_filter: String = "") -> bool:
	var result := Result.new()
	var ran_any: bool = false

	for suite_name: String in _suites:
		if suite_filter != "" and suite_name != suite_filter:
			continue
		for test_name: String in _suites[suite_name]:
			if test_filter != "" and test_name != test_filter:
				continue
			ran_any = true
			_run_one(suite_name, test_name, _suites[suite_name][test_name], result)

	print("")
	if not ran_any:
		print("[TestRunner] Nenhum teste correspondeu ao filtro (suite='%s', test='%s')." % [suite_filter, test_filter])
		return false

	print("[TestRunner] %d passou, %d falhou, %d erro(s) de execução — total %d asserções." % [
		result.pass_count, result.fail_count, result.error_count, result.total()
	])
	return result.ok()


func _run_one(suite_name: String, test_name: String, test_func: Callable, result: Result) -> void:
	print("[TestRunner] Rodando %s/%s..." % [suite_name, test_name])
	var ctx := Context.new(result, test_name)
	var completed: Variant = test_func.call(ctx)
	if completed != true:
		result.error_count += 1
		print("  [ERROR] %s/%s não terminou normalmente (não retornou true — possível erro de execução; ver SCRIPT ERROR acima, se houver)." % [suite_name, test_name])
