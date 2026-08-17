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

var kingdom: Kingdom
var is_initialized: bool = false


func initialize_new_kingdom() -> void:
	if is_initialized:
		return

	kingdom = Kingdom.new()
	# Sem isso, um Reino novo de verdade nunca tinha as 3 Minas
	# Iniciais criadas — só existiam nos meus testes, que chamavam
	# create_initial_mines() manualmente. Jogador real via sempre
	# "Nenhuma Mina conquistada ainda." (MINES.md, "Mina Inicial").
	kingdom.create_initial_mines()
	# COMMAND_CENTER_RECRUITMENT.md, "Exceção Inicial": 1 Candidato já
	# nasce disponível de imediato, sem esperar as 24h do Cooldown
	# Inicial — o jogador precisa ter alguém pra recrutar desde o
	# primeiro instante, pra testar a Doutrina do Comandante sem
	# depender de tempo real de espera logo na largada.
	kingdom.recruitment_center_cycle_end_unix = GameClock.now_unix()
	RecruitmentCenterResolver.sync(kingdom, GameClock.now_unix())

	is_initialized = true
	print("[KingdomState] Estado do Reino inicializado (Kingdom instanciado).")
	EventBus.kingdom_initialized.emit()

