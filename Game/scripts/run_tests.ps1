<#
.SYNOPSIS
    run_tests.ps1 (FASE 23.1 — Infraestrutura de Testes) — única forma
    sancionada de rodar a suíte de testes headless OU uma ferramenta de
    depuração (Game/tools/debug/*.tscn) neste projeto.

.DESCRIPTION
    Fonte única de verdade (SSoT) para o comando de execução. Existe
    especificamente para fechar um incidente real, em DUAS tentativas:

    1ª tentativa (rejeitada): "--user-data-dir <caminho POSIX>" — falhou
       porque o caminho estava em formato git-bash ("/c/Users/...").
    2ª tentativa (também rejeitada, achado desta correção): mesmo com o
       caminho já em formato Windows absoluto, "--user-data-dir" NÃO É
       UMA FLAG REAL desta build do Godot 4.7.1 — confirmado lendo
       `godot --help` por inteiro (nenhuma menção a "user-data-dir",
       "user-dir" ou qualquer variação). A suposição de que essa flag
       existia estava simplesmente errada.

    Mecanismo real usado agora: no Windows, o Godot resolve "user://"
    a partir da variável de ambiente %APPDATA% (confirmado: o save real
    vive em "%APPDATA%\Godot\app_userdata\Battle Simulator"). Este
    script sobrescreve %APPDATA% APENAS no ambiente do processo filho
    do Godot (nunca no ambiente do usuário/sistema, nunca persistente)
    para um diretório temporário isolado — nenhuma flag de linha de
    comando inexistente envolvida.

    Este script SEMPRE:
      1. Gera um diretório temporário EXCLUSIVO desta execução, em
         formato Windows absoluto (nunca POSIX), sob
         Game\build\test_userdata\<guid>\ — nunca reutilizado entre
         execuções.
      2. Confere (Etapa B, fail-safe) que esse diretório NUNCA coincide
         com nem está contido no user:// real antes de sequer abrir o
         Godot — aborta com a mensagem obrigatória se essa checagem
         falhar.
      3. Lança o Godot com %APPDATA% (só do processo filho) apontando
         pra esse diretório isolado.
      4. Ao final (sucesso OU falha), remove o diretório temporário —
         nunca toca em app_userdata\Battle Simulator.

    Defesa em profundidade (não depende só deste script): mesmo que
    este mecanismo falhe de novo por algum motivo novo e imprevisto,
    UserDataDirGuard (engine/testing/user_data_dir_guard.gd) roda
    DENTRO do próprio processo do Godot — em test_main.gd
    incondicionalmente, e em KingdomState.initialize_new_kingdom()
    sempre que "--user-data-dir" aparecer nos argumentos (aceito ali só
    como MARCADOR de "isto é uma execução controlada", não como flag
    real do Godot) — e aborta ANTES de qualquer
    KingdomSaveService.save()/load_into()/delete_save() se
    OS.get_user_data_dir() não for reconhecidamente isolado.

    Ver Arquitetura/TESTING_INFRASTRUCTURE.md para a documentação
    completa desta arquitetura de isolamento.

.PARAMETER Suite
    Nome de uma suíte específica (equivalente a "-- --suite=<nome>").

.PARAMETER Test
    Nome de um teste específico (equivalente a "-- --test=<nome>").

.PARAMETER Scene
    Cena a rodar. Default: a suíte de testes completa
    (res://tests/test_main.tscn). Para uma ferramenta de depuração,
    passe algo como "res://tools/debug/minha_ferramenta.tscn".

.PARAMETER NoHeadless
    Roda com janela real (necessário para ferramentas de screenshot
    que precisam de renderização de verdade). Default: headless.

.PARAMETER GodotExe
    Caminho do executável do Godot. Default: a instalação 4.7.1 usada
    por este projeto (ver CLAUDE.md / memória do projeto — a 4.7.2 via
    winget existe mas NÃO é usada aqui).

.EXAMPLE
    .\run_tests.ps1
    Roda a suíte completa, headless, isolada.

.EXAMPLE
    .\run_tests.ps1 -Suite battle_replay_persistence
    Roda só essa suíte, headless, isolada.

.EXAMPLE
    .\run_tests.ps1 -Scene "res://tools/debug/minha_ferramenta.tscn" -NoHeadless
    Roda uma ferramenta de depuração com janela real, isolada.
#>

param(
    [string]$Suite = "",
    [string]$Test = "",
    [string]$Scene = "res://tests/test_main.tscn",
    [switch]$NoHeadless,
    [switch]$KeepTemp,
    [string]$GodotExe = "F:\DigoFtto\Documents\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

# --- Caminhos base (sempre Windows absoluto, nunca POSIX) ---
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RealAppData = $env:APPDATA
$RealUserDataDir = Join-Path $RealAppData "Godot\app_userdata\Battle Simulator"

$RunId = [guid]::NewGuid().ToString()
$FakeAppData = Join-Path $ProjectPath "build\test_userdata\$RunId"
# Onde o Godot vai efetivamente resolver user:// (só para exibição/prova
# — nunca usado como argumento, o Godot calcula isto sozinho a partir
# de %APPDATA%).
$ExpectedUserDataDir = Join-Path $FakeAppData "Godot\app_userdata\Battle Simulator"

# --- ETAPA B: fail-safe OBRIGATÓRIO, antes de sequer criar o diretório
# ou abrir o Godot. Nunca prosseguir se isto falhar. ---
$ResolvedFake = [System.IO.Path]::GetFullPath($FakeAppData)
$ResolvedReal = [System.IO.Path]::GetFullPath($RealUserDataDir)

$isUnsafe = [string]::IsNullOrWhiteSpace($ResolvedFake) `
    -or ($ResolvedFake -eq $ResolvedReal) `
    -or $ResolvedFake.StartsWith($ResolvedReal, [StringComparison]::OrdinalIgnoreCase) `
    -or ($ResolvedReal.StartsWith($ResolvedFake, [StringComparison]::OrdinalIgnoreCase)) `
    -or ($ResolvedFake -notmatch "test_userdata")

if ($isUnsafe) {
    Write-Host "ERRO: tentativa de executar testes usando o save real." -ForegroundColor Red
    Write-Host "Diretório calculado (%APPDATA% isolado): $ResolvedFake"
    Write-Host "Diretório real (NUNCA deve ser usado por testes): $ResolvedReal"
    exit 1
}

New-Item -ItemType Directory -Path $FakeAppData -Force | Out-Null

Write-Host "[run_tests] %APPDATA% isolado desta execução: $FakeAppData"
Write-Host "[run_tests] user:// esperado (calculado pelo Godot a partir disso): $ExpectedUserDataDir"
Write-Host "[run_tests] user:// real (protegido, não será tocado): $RealUserDataDir"

# --- Monta os argumentos do Godot ---
# "--user-data-dir" aqui NÃO é uma flag real do Godot (confirmado via
# --help) — é só um MARCADOR nos argumentos de linha de comando que
# UserDataDirGuard.should_enforce_from_cmdline() procura, pra saber que
# esta é uma execução controlada e ativar a 2ª linha de defesa em
# KingdomState.initialize_new_kingdom(). O isolamento real acontece
# via %APPDATA% do processo filho, abaixo. CRÍTICO: "--user-data-dir"
# NUNCA pode ir antes do separador "--" — colocá-lo como argumento de
# ENGINE foi exatamente o que confundiu o parser do Godot na 2ª
# tentativa rejeitada (ver docstring do topo). Depois de "--" o Godot
# GARANTE (por sua própria documentação) que nunca interpreta nada —
# só fica disponível via OS.get_cmdline_user_args().
$GodotArgs = @()
if (-not $NoHeadless) {
    $GodotArgs += "--headless"
}
$GodotArgs += @("--path", $ProjectPath, $Scene)

$UserArgs = @("--user-data-dir")
if ($Suite -ne "") {
    $UserArgs += "--suite=$Suite"
} elseif ($Test -ne "") {
    $UserArgs += "--test=$Test"
}
$GodotArgs += @("--") + $UserArgs

Write-Host "[run_tests] Comando: `"$GodotExe`" $($GodotArgs -join ' ')"
Write-Host "[run_tests] (%APPDATA% sobrescrito só para este processo filho)"

$ExitCode = 0
$OriginalAppData = $env:APPDATA
try {
    $env:APPDATA = $FakeAppData
    & $GodotExe @GodotArgs
    $ExitCode = $LASTEXITCODE
} finally {
    $env:APPDATA = $OriginalAppData
    # --- Limpeza: SEMPRE remove o diretório temporário (sucesso ou
    # falha), NUNCA toca em app_userdata\Battle Simulator. -KeepTemp é
    # só para diagnóstico manual (prova de onde o save isolado foi
    # parar) — nunca usar em execução normal.
    if ($KeepTemp) {
        Write-Host "[run_tests] -KeepTemp: diretório NÃO removido: $FakeAppData"
    } elseif (Test-Path $FakeAppData) {
        Remove-Item -Recurse -Force $FakeAppData -ErrorAction SilentlyContinue
        Write-Host "[run_tests] Diretório temporário removido: $FakeAppData"
    }
}

exit $ExitCode
