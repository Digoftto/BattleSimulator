# TESTING_INFRASTRUCTURE.md

## Escopo

Este documento é a fonte de verdade (SSoT) para **como rodar** a suíte
de testes headless e as ferramentas de depuração (`Game/tools/debug/`)
deste projeto, e para a regra permanente que motivou sua criação:

> **Nenhum teste, screenshot, ferramenta de depuração ou auditoria pode
> tocar o save real do jogador.**

Isto não é uma preferência de estilo — é uma regra de segurança do
ambiente de desenvolvimento, criada depois de um incidente real (FASE
23.1, ver "Histórico do incidente" abaixo).

## Como executar (SEMPRE via este mecanismo)

Toda execução de teste ou ferramenta de depuração deste projeto **deve**
passar por `Game/scripts/run_tests.ps1`. Nunca invoque o executável do
Godot diretamente para isso.

```powershell
# Suíte completa, headless, isolada
.\Game\scripts\run_tests.ps1

# Só uma suíte específica
.\Game\scripts\run_tests.ps1 -Suite battle_replay_persistence

# Só um teste específico
.\Game\scripts\run_tests.ps1 -Test validate_soldo

# Uma ferramenta de depuração (screenshot/auditoria), com janela real
.\Game\scripts\run_tests.ps1 -Scene "res://tools/debug/minha_ferramenta.tscn" -NoHeadless
```

Parâmetros aceitos: `-Suite`, `-Test`, `-Scene` (default:
`res://tests/test_main.tscn`), `-NoHeadless` (para ferramentas que
precisam de renderização real), `-GodotExe` (override do caminho do
executável), `-KeepTemp` (só para diagnóstico manual — nunca usar em
execução normal, deixa o diretório temporário no disco em vez de
apagá-lo ao final).

## Arquitetura de isolamento

### O mecanismo real: `%APPDATA%` sobrescrito no processo filho

No Windows, o Godot resolve `user://` (onde `KingdomSaveService`
lê/grava `kingdom_save.json`) a partir da variável de ambiente
`%APPDATA%`, montando o caminho
`%APPDATA%\Godot\app_userdata\<nome do projeto>\`. Para este projeto,
isso é `%APPDATA%\Godot\app_userdata\Battle Simulator\`.

`run_tests.ps1`:

1. Gera um diretório temporário **exclusivo desta execução**, sempre em
   formato Windows absoluto (nunca POSIX/estilo git-bash), sob:

   ```
   Game\build\test_userdata\<guid>\
   ```

   Nunca reaproveitado entre execuções — cada chamada gera um GUID novo.

2. **Antes** de sequer criar esse diretório ou abrir o Godot, confere
   (fail-safe) que o caminho calculado:
   - não é vazio;
   - não é igual, nem está contido, nem contém o `user://` real;
   - contém o segmento `test_userdata`.

   Se qualquer checagem falhar, o script aborta imediatamente com a
   mensagem `ERRO: tentativa de executar testes usando o save real.` —
   nada é executado.

3. Sobrescreve `%APPDATA%` **apenas no processo filho do Godot**
   (nunca no ambiente do usuário/sistema, nunca persistente — a
   variável é restaurada no processo do PowerShell logo depois que o
   Godot termina) para apontar para esse diretório temporário. O Godot
   passa a resolver `user://` inteiramente dentro dele.

4. Ao final da execução (sucesso **ou** falha — bloco `finally`),
   remove o diretório temporário por inteiro. Nunca toca em
   `app_userdata\Battle Simulator` (o diretório real).

### Defesa em profundidade: `UserDataDirGuard`

`Game/engine/testing/user_data_dir_guard.gd` é a segunda linha de
defesa, rodando **dentro** do próprio processo do Godot — nunca confia
cegamente que `run_tests.ps1` funcionou:

- **`is_safe_user_data_dir(path)`**: função pura. Só retorna `true` se
  `test_userdata` aparecer como um **segmento completo** do caminho
  (nunca uma substring solta como `nottest_userdatafake` ou
  `test_userdataXYZ`).

- **`abort_if_unsafe(tree)`**: chama `OS.get_user_data_dir()` de
  verdade; se não for seguro, imprime a mensagem obrigatória e chama
  `tree.quit(1)` — aborta **antes** de qualquer
  `KingdomSaveService.save()/load_into()/delete_save()`.

- **`should_enforce_from_cmdline(user_args)`**: função pura. Retorna
  `true` só quando `--user-data-dir` aparece nos **argumentos de
  usuário** (depois do separador `--`, via
  `OS.get_cmdline_user_args()` — nunca `OS.get_cmdline_args()`). Um
  jogador real ou uma build exportada **nunca** passa esse marcador,
  então esta checagem é **inerte para o jogo real**, sem exceção.

Dois pontos de chamada:

1. **`Game/tests/test_main.gd`** — chama `abort_if_unsafe()`
   incondicionalmente, como a primeiríssima coisa em `_ready()`, antes
   de qualquer suíte rodar. Cobre 100% dos testes, porque todos passam
   por este único ponto de entrada.

2. **`Game/autoload/kingdom_state.gd` → `initialize_new_kingdom()`** —
   chama `should_enforce_from_cmdline()` + `abort_if_unsafe()`. Cobre
   **qualquer** ferramenta de depuração presente ou futura que acabe
   inicializando o Reino transitivamente (a grande maioria instancia
   uma cena real de produção, como `city_panel.tscn`, mesmo sem nunca
   mencionar `Kingdom` no próprio código) — sem depender de lembrar de
   repetir a guarda em cada arquivo novo.

3. Adicionalmente, as 3 ferramentas em `Game/tools/debug/` que chamam
   `KingdomSaveService.delete_save()` **antes** de
   `initialize_new_kingdom()` (`screenshot_city_cdc_real_click.gd`,
   `screenshot_cdc_evolve_real_click.gd`,
   `screenshot_commander_full_flow.gd`) chamam `abort_if_unsafe()`
   explicitamente logo no início do próprio `_ready()`, porque aquela
   chamada é destrutiva e roda antes do ponto 2 ter a chance de agir.

### Por que isto nunca afeta o jogo real

- `%APPDATA%` só é sobrescrito no processo filho lançado por
  `run_tests.ps1` — nunca no ambiente real do usuário.
- `should_enforce_from_cmdline()` só ativa a checagem quando o marcador
  `--user-data-dir` está presente nos argumentos de usuário — um
  jogador real (ou a build exportada) nunca passa isso.
- Nenhuma das mudanças em `KingdomState.gd`/`KingdomSaveService.gd`
  altera o formato do save, as regras de autosave, ou qualquer
  comportamento visível para uma sessão de jogo real.

## Regra permanente para ferramentas novas

Toda ferramenta nova em `Game/tools/debug/` que:

- chame `KingdomSaveService.save()`, `load_into()` ou `delete_save()`
  diretamente, **antes** de `KingdomState.initialize_new_kingdom()` ter
  rodado; **ou**
- precise rodar mesmo sem nunca inicializar o Reino,

deve chamar `UserDataDirGuardScript.abort_if_unsafe(get_tree())` como a
primeira linha do próprio `_ready()`, exatamente como as 3 ferramentas
já existentes fazem. Ferramentas que só inicializam o Reino
normalmente (a maioria) já estão cobertas transitivamente pelo ponto 2
acima.

## Histórico do incidente (FASE 23.1)

Durante a validação funcional do Item #17 (Replay das Fases PvE), uma
tentativa de isolar `user://` para uma ferramenta de validação usou
`--user-data-dir <caminho>`. Duas tentativas seguidas falharam:

1. **1ª tentativa**: o caminho foi passado em formato POSIX (estilo
   git-bash, `/c/Users/...`) para o executável nativo do Godot no
   Windows. O Godot não reconheceu o caminho e caiu de volta para o
   `user://` padrão real — um `kingdom_save.json` sintético foi escrito
   em `AppData\Roaming\Godot\app_userdata\Battle Simulator` por engano.

2. **2ª tentativa** (já com o caminho em formato Windows absoluto
   correto): descoberto, ao ler `godot --help` por inteiro, que
   **`--user-data-dir` não é uma flag real desta build do Godot
   4.7.1** — a suposição de que essa flag existia estava simplesmente
   errada. Passá-la como argumento de engine (antes do separador `--`)
   fez o parser de argumentos do Godot se confundir a ponto de carregar
   a cena principal do jogo (`run/main_scene`) em vez da cena de teste
   pedida — e essa execução também escreveu no `user://` real.

Em nenhum dos dois casos havia um save real de jogador com progresso
genuíno de longo prazo no caminho no momento do incidente (confirmado:
o arquivo já estava ausente do disco antes da 1ª tentativa) — mas o
mecanismo de isolamento em si estava genuinamente quebrado, e o risco
para um save real futuro era genuíno.

A correção final (esta documentação + `run_tests.ps1` +
`UserDataDirGuard`) usa a sobrescrita de `%APPDATA%` no processo filho
— o mecanismo real pelo qual o Godot resolve `user://` no Windows —
em vez de qualquer flag de linha de comando, e adiciona checagens
internas ao próprio processo do Godot como defesa em profundidade.

**Prova de que a correção funciona** (reproduzível com os comandos
acima): hash SHA-256 de `kingdom_save.json` real, capturado antes e
depois de uma execução completa da suíte (3699 testes) via
`run_tests.ps1`, permaneceu **idêntico** — o diretório temporário
`Game\build\test_userdata\<guid>\` foi criado, usado (confirmado via
`Godot\app_userdata\Battle Simulator\logs\godot.log` dentro dele) e
removido, sem nenhuma escrita no `user://` real.

## Auditoria de `Input.parse_input_event()`

Ferramentas que despacham cliques reais via `Input.parse_input_event()`
(`screenshot_city_cdc_real_click.gd`,
`screenshot_cdc_evolve_real_click.gd`) foram auditadas e confirmadas
corretas: cada uma instancia explicitamente sua própria cena-alvo
(`CityScene.instantiate()` / `CommandCenterScene.instantiate()`) e a
adiciona diretamente sob `get_tree().root` — nenhuma depende de
`get_tree().current_scene` ou do `run/main_scene` do projeto. A falha
observada durante o incidente (o jogo parecendo abrir a cena principal
em vez da cena de teste) foi inteiramente causada pelo bug de
argumento de linha de comando descrito acima, nunca por uma falha
nestas ferramentas em si.
