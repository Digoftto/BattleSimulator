class_name TestFragmentsCreditedPerUnitFaction
extends RefCounted
## TestFragmentsCreditedPerUnitFaction (F-001, Etapa 10)
##
## Migrado de bootstrap.gd:_validate_fragments_credited_per_unit_faction().
## Mesmo cenário original — validação FUNCIONAL do bug real relatado:
## Fragmentos devem ser creditados por FACÇÃO de cada Pelotão destruído,
## não só a Facção principal do oponente (RESOURCES.md §4, "Correspondência
## de Facção"). Usa um Kingdom.new() local, PhaseResult (confirmado puro)
## e RewardResolver — confirmado sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou
## transitiva.
##
## O teste original só tinha "(esperado: X)" explícito na segunda
## verificação (Mortos-Vivos) — a primeira (Império) não tinha marcador
## de expectativa explícito no print original e permanece apenas
## informativa, sem virar asserção nova.

static func run(ctx: TestRunner.Context) -> bool:
	print("[PvE] Validando Fragmentos por Facção de cada unidade destruída (bug relatado)...")

	var result := PhaseResult.new()
	result.victory = true
	var opponent := EnemyArmyEntry.new()
	opponent.faction = "Império"  # Facção PRINCIPAL do oponente — mas nem todos os Pelotões são dela
	result.opponent_entry = opponent
	result.enemy_pelotoes_destroyed_by_faction = {"Império": 6, "Mortos-Vivos": 3}  # 6 principal + 3 secundária, PvE.md

	var kingdom := Kingdom.new()
	var imperio_before: int = kingdom.get_fragment("Império")
	var mortos_before: int = kingdom.get_fragment("Mortos-Vivos")

	RewardResolver.resolve(result, kingdom, SeasonConfig.new())

	print("  Império recebeu Fragmentos (6 Pelotões dele destruídos)? %s (%d -> %d)" % [
		str(kingdom.get_fragment("Império") > imperio_before), imperio_before, kingdom.get_fragment("Império")
	])
	print("  Mortos-Vivos TAMBÉM recebeu Fragmentos (3 Pelotões secundários dele destruídos, mesmo o oponente sendo 'Império')? %s (%d -> %d, esperado: true, aumentou)" % [
		str(kingdom.get_fragment("Mortos-Vivos") > mortos_before), mortos_before, kingdom.get_fragment("Mortos-Vivos")
	])
	ctx.check(
		kingdom.get_fragment("Mortos-Vivos") > mortos_before,
		"Mortos-Vivos deve receber Fragmentos pelos Pelotões secundários dele destruídos, mesmo com oponente principal 'Império' (antes: %d, depois: %d)" % [mortos_before, kingdom.get_fragment("Mortos-Vivos")]
	)

	return true
