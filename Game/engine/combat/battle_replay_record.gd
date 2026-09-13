class_name BattleReplayRecord
extends RefCounted
## BattleReplayRecord (Auditoria pré-pré-alfa — item #17, Replay
## persistido de Fases PvE, vitória e derrota)
##
## Camada pura de conversão entre um item real de PhaseResult.
## battle_replays ({"state": CombatState, "collector":
## CombatReplayCollector}, produzido por PhaseResolver.resolve()) e um
## Dictionary JSON-safe pronto para o save do Reino (KingdomSaveService).
## NUNCA re-simula a batalha — replay = reprodução do evento REAL já
## gravado por CombatReplayCollector, nunca "guardar seed e rodar
## CombatEngine de novo" (RNG não-seedado existe, ex.: Silêncio,
## silencio_runtime.gd — re-simular não é confiável).
##
## Única referência viva a resolver (confirmado por auditoria):
## initial_board[i]["card"] (CardResource) — descartada em
## to_persistable_dict(), reconstruída por NOME (GameDatabase.get_card(),
## mesmo padrão já usado em todo o projeto) em from_persisted_dict().
## Nenhum outro campo de CombatReplayCollector precisa de tratamento —
## replay_events já é 100% primitivos/Strings/ints (confirmado por
## leitura direta de combat_replay_collector.gd).
##
## CombatReplayView só lê 6 campos escalares de "combat_state"
## (confirmado por grep exaustivo): battlefield, seed_value, battle_id,
## rules_version, winner_side, turn — from_persisted_dict() reconstrói
## um CombatState "stub" só com esses 6 campos, nunca uma batalha viva.
## Nenhuma alteração foi feita em CombatReplayView/CombatReplayCollector/
## CombatEngine para isso — a API pública já existente (view.combat_state,
## view.replay_collector, view.player_side) já aceita exatamente isso.


## Constrói o Dictionary persistível. "metadata" é fornecido por quem
## chama (ExpeditionRuntime._record_fase_history()): replay_id (já
## gerado por Kingdom.record_battle_replay()), fase, territory_id,
## victory, created_unix, player_side.
static func to_persistable_dict(battle_replay: Dictionary, metadata: Dictionary) -> Dictionary:
	var state: CombatState = battle_replay["state"]
	var collector = battle_replay["collector"]

	var initial_board_safe: Array = []
	for entry: Dictionary in collector.initial_board:
		var copy: Dictionary = entry.duplicate()
		copy.erase("card")
		initial_board_safe.append(copy)

	var replay_events_safe: Array = []
	for event: Dictionary in collector.replay_events:
		replay_events_safe.append(event.duplicate(true))

	return {
		"replay_id": metadata.get("replay_id", ""),
		"fase": metadata.get("fase", -1),
		"territory_id": metadata.get("territory_id", ""),
		"victory": metadata.get("victory", false),
		"created_unix": metadata.get("created_unix", 0),
		"player_side": metadata.get("player_side", 0),
		"battlefield_name": state.battlefield.battlefield_name if state.battlefield != null else "",
		"seed_value": state.seed_value,
		"battle_id": state.battle_id,
		"rules_version": state.rules_version,
		"winner_side": state.winner_side,
		"turn": state.turn,
		"initial_board": initial_board_safe,
		"replay_events": replay_events_safe,
	}


## Reconstrói {"state": CombatState, "collector": CombatReplayCollector,
## "player_side": int} a partir de um Dictionary persistido — pronto
## para alimentar CombatReplayView (view.combat_state/replay_collector/
## player_side) exatamente como uma batalha recém-disputada faria.
## Degrada graciosamente (nunca inventa dado) se battlefield_name/
## card_name não resolverem mais no catálogo atual (ex: conteúdo
## removido em uma atualização futura) — resultam em null, o mesmo
## comportamento que CombatReplayView já trata hoje pra um Campo de
## Batalha/carta ausente.
static func from_persisted_dict(record: Dictionary) -> Dictionary:
	var state := CombatState.new()
	state.battlefield = GameDatabase.get_battlefield(record.get("battlefield_name", ""))
	state.seed_value = record.get("seed_value", 0)
	state.battle_id = record.get("battle_id", "")
	state.rules_version = record.get("rules_version", "")
	state.winner_side = record.get("winner_side", -1)
	state.turn = record.get("turn", 1)

	var collector = preload("res://engine/combat/combat_replay_collector.gd").new()

	var initial_board: Array[Dictionary] = []
	for entry: Variant in record.get("initial_board", []):
		var copy: Dictionary = (entry as Dictionary).duplicate()
		copy["card"] = GameDatabase.get_card(copy.get("card_name", ""))
		initial_board.append(copy)
	collector.initial_board = initial_board

	var replay_events: Array[Dictionary] = []
	for event: Variant in record.get("replay_events", []):
		replay_events.append(event as Dictionary)
	collector.replay_events = replay_events

	return {"state": state, "collector": collector, "player_side": record.get("player_side", 0)}
