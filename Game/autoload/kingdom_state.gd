extends Node
## KingdomState
##
## Raiz do estado runtime do Reino (jogador). Expõe o ponto de entrada
## oficial de inicialização e a instância de Kingdom (engine/kingdom/
## kingdom.gd) — o agregado que possui Comandantes, Cartas, Exércitos,
## Squads, Expedições ativas, o Registro de Comandantes Regionais e
## Flags de progresso do jogador.
##
## Achado ao registrar o autoload WorldDatabase nesta Sprint: este
## autoload já existia desde a Sprint 1 (Bootstrap) como o ponto de
## entrada reservado para o estado do Reino, mas nunca chegou a
## instanciar Kingdom quando ele foi criado — corrigido agora.
##
## Persistência (F-013): este autoload é o único lugar do jogo real
## que vive por todo o processo (main.tscn -> City -> qualquer painel),
## por isso é também o ponto central de Save/Load — nenhuma chamada de
## KingdomSaveService.save()/load_into() precisa se espalhar pelos
## painéis. Estratégia deliberadamente simples (F-013, escopo
## aprovado): autosave periódico incondicional (sem rastrear o que
## mudou) + save na notificação de fechamento da janela. Sem múltiplos
## slots, sem versionamento, sem infraestrutura de eventos nova.

var kingdom: Kingdom
var is_initialized: bool = false

## Sem cadência estabelecida em nenhum SSoT — valor simples e
## conservador (F-013), fácil de ajustar depois se o dono do produto
## pedir outro.
const AUTOSAVE_INTERVAL_SECONDS: float = 60.0
var _autosave_accumulator: float = 0.0


func initialize_new_kingdom() -> void:
	if is_initialized:
		return

	kingdom = _load_or_create_kingdom()

	is_initialized = true
	print("[KingdomState] Estado do Reino inicializado (Kingdom instanciado).")
	EventBus.kingdom_initialized.emit()


## Carrega o Reino salvo em disco (user://kingdom_save.json) se existir
## e for um save válido; caso contrário (nenhum save, ou save
## corrompido/ilegível), cria e inicializa um Reino novo exatamente
## como antes desta Sprint — nenhum comportamento muda para um
## jogador que está começando de verdade sem save. Um Reino carregado
## NUNCA passa por _initialize_fresh_kingdom(): tudo que essa função
## configuraria (Minas Iniciais, Exceção Inicial do Centro de
## Recrutamento) já está persistido de uma sessão anterior — refazer
## duplicaria ou sobrescreveria progresso real do jogador.
func _load_or_create_kingdom() -> Kingdom:
	var candidate := Kingdom.new()
	if KingdomSaveService.has_save() and KingdomSaveService.load_into(candidate):
		# F-020: Expedições salvas dependem de Trilha/Território/Catálogo
		# (conteúdo do MUNDO, não do Reino) — só podem virar
		# ExpeditionRuntime de verdade depois que o Mundo estiver
		# carregado (KingdomSaveService só grava dado cru — ver seu
		# próprio docstring). Guard de vazio evita o custo de carregar o
		# Mundo neste ponto do boot para o caso comum (save sem
		# Expedição ativa).
		if not candidate._pending_expedition_saves.is_empty():
			WorldBootstrap.ensure_world_loaded()
			ExpeditionPersistenceResolver.hydrate_pending(candidate)
		return candidate
	return _initialize_fresh_kingdom(candidate)


func _initialize_fresh_kingdom(new_kingdom: Kingdom) -> Kingdom:
	# Sem isso, um Reino novo de verdade nunca tinha as 3 Minas
	# Iniciais criadas — só existiam nos meus testes, que chamavam
	# create_initial_mines() manualmente. Jogador real via sempre
	# "Nenhuma Mina conquistada ainda." (MINES.md, "Mina Inicial").
	new_kingdom.create_initial_mines()
	# COMMAND_CENTER_RECRUITMENT.md, "Exceção Inicial": 1 Candidato já
	# nasce disponível de imediato, sem esperar as 24h do Cooldown
	# Inicial — o jogador precisa ter alguém pra recrutar desde o
	# primeiro instante, pra testar a Doutrina do Comandante sem
	# depender de tempo real de espera logo na largada.
	new_kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(new_kingdom, GameClock.now_unix())
	return new_kingdom


## Autosave periódico incondicional — roda pra qualquer painel/cena
## aberta, porque este autoload (ao contrário de qualquer painel) vive
## durante todo o processo. Idêntico em espírito ao acumulador de
## GameRuntime.sync() em city_panel.gd, só que salvando em disco em
## vez de sincronizar tempo real.
func _process(delta: float) -> void:
	if not is_initialized:
		return
	_autosave_accumulator += delta
	if _autosave_accumulator < AUTOSAVE_INTERVAL_SECONDS:
		return
	_autosave_accumulator = 0.0
	KingdomSaveService.save(kingdom)


## "Encerramento normal do jogo" (F-013): hoje a única saída real de
## um jogador é fechar a janela (botão X / Alt+F4) — não existe botão
## de Sair em nenhum painel. NOTIFICATION_WM_CLOSE_REQUEST é entregue
## sincronamente a todos os nós da árvore antes do encerramento
## prosseguir; save() é I/O de arquivo síncrono, então termina antes
## de qualquer teardown.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_initialized:
		KingdomSaveService.save(kingdom)

