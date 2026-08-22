class_name TestAccountXp
extends RefCounted
## TestAccountXp (F-001, Etapa 7)
##
## Migrado de bootstrap.gd:_validate_account_xp(). Mesmo cenário
## original (AccountXPResolver — XP.md): cruzamento de Nível de Conta
## gerando PG automaticamente, e conquistas estruturais nunca concedidas
## duas vezes para a mesma chave — usando um Kingdom.new() local e
## AccountXPResolver (lógica pura, opera só sobre o "kingdom" recebido
## por parâmetro; confirmado sem nenhuma referência a KingdomState/
## WorldDatabase/ExpeditionRuntime/GameRuntime/WorldBootstrap, direta ou
## transitiva).
##
## O teste original já tinha "(esperado: X)" explícito em cada print —
## convertidos abaixo em asserções reais, sem reinterpretar nenhuma regra.

static func run(ctx: TestRunner.Context) -> bool:
	print("[XP de Conta] Validando AccountXPResolver...")

	var kingdom := Kingdom.new()
	print("  Nível de Conta inicial: %d (esperado: 1) | XP: %d (esperado: 0)" % [kingdom.account_level(), kingdom.account_xp])
	ctx.check(kingdom.account_level() == 1, "Nível de Conta inicial deve ser 1 (obtido: %d)" % kingdom.account_level())
	ctx.check(kingdom.account_xp == 0, "XP de Conta inicial deve ser 0 (obtido: %d)" % kingdom.account_xp)

	# XP Operacional (sem unique_key): concedido toda vez.
	AccountXPResolver.grant_pve_fase_comum(kingdom)
	AccountXPResolver.grant_pve_fase_comum(kingdom)
	print("  2x 'Concluir fase comum' (1 XP cada) -> XP total: %d (esperado: 2)" % kingdom.account_xp)
	ctx.check(kingdom.account_xp == 2, "2x 'Concluir fase comum' deve conceder 2 XP no total (obtido: %d)" % kingdom.account_xp)

	# Cruzar 200 XP concede exatamente 1 PG por Nível cruzado.
	var pg_before: int = kingdom.generation_points
	AccountXPResolver.grant_pve_chefe_regional(kingdom)  # 30 XP, repetido 8x no total
	for i in range(7):
		AccountXPResolver.grant_pve_chefe_regional(kingdom)
	print("  XP total: %d | Nível de Conta: %d (esperado: >= 2) | PG ganho no processo: %d (esperado: >= 1)" % [
		kingdom.account_xp, kingdom.account_level(), kingdom.generation_points - pg_before
	])
	ctx.check(kingdom.account_level() >= 2, "Cruzar 200 XP deve elevar o Nível de Conta para >= 2 (obtido: %d)" % kingdom.account_level())
	ctx.check(kingdom.generation_points - pg_before >= 1, "Cruzar Nível de Conta deve conceder >= 1 PG (obtido: %d)" % (kingdom.generation_points - pg_before))

	# XP Estrutural (com unique_key): primeira vez concede, segunda não.
	var xp_before_structural: int = kingdom.account_xp
	var first: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "500:Império")
	var xp_after_first: int = kingdom.account_xp
	var second: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "500:Império")
	print("  'Liberar Mina 500:Império' 1a vez -> concedido? %s (esperado: true) | XP ganho: %d (esperado: 20)" % [
		str(first["granted"]), xp_after_first - xp_before_structural
	])
	ctx.check(first["granted"] == true, "1a concessão de XP Estrutural com unique_key nova deve ser concedida")
	ctx.check(xp_after_first - xp_before_structural == 20, "'Liberar Mina' deve conceder exatamente 20 XP (obtido: %d)" % (xp_after_first - xp_before_structural))

	print("  'Liberar Mina 500:Império' 2a vez (mesma chave) -> concedido? %s | XP mudou? %s (esperado: false, false)" % [
		str(second["granted"]), str(kingdom.account_xp != xp_after_first)
	])
	ctx.check(second["granted"] == false, "2a concessão com a mesma unique_key não deve ser concedida")
	ctx.check(kingdom.account_xp == xp_after_first, "XP não deve mudar ao repetir a mesma unique_key")

	# Mina diferente (chave diferente) concede normalmente.
	var different_mina: Dictionary = AccountXPResolver.grant_mina_liberada(kingdom, "2000:Império")
	print("  'Liberar Mina 2000:Império' (chave diferente) -> concedido? %s (esperado: true)" % str(different_mina["granted"]))
	ctx.check(different_mina["granted"] == true, "unique_key diferente deve conceder XP normalmente")

	# Conquistas estruturais de carta seguem o mesmo padrão (chave por carta+raridade / carta+Tier).
	var card_first: Dictionary = AccountXPResolver.grant_card_obtained(kingdom, "Lanceiro Imperial", "Comum")
	var card_second: Dictionary = AccountXPResolver.grant_card_obtained(kingdom, "Lanceiro Imperial", "Comum")
	print("  Obter 'Lanceiro Imperial' (Comum) 2x -> 1a concedida? %s | 2a concedida? %s (esperado: true, false)" % [
		str(card_first["granted"]), str(card_second["granted"])
	])
	ctx.check(card_first["granted"] == true, "1a obtenção estrutural de carta deve ser concedida")
	ctx.check(card_second["granted"] == false, "2a obtenção da mesma carta/raridade não deve ser concedida de novo")

	return true
