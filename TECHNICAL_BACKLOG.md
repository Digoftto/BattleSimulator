# Battle Simulator — Technical Backlog

## Purpose

This document is the **operational backlog for technical stabilization and completion** of the Battle Simulator project. It tracks what is wrong, incomplete, inconsistent, risky, missing, or technically unfinished in the current implementation, and the order in which it should be addressed.

**This document is NOT a gameplay-rule Single Source of Truth.** It never defines, redefines, or duplicates game rules, formulas, or mechanics. Those remain governed exclusively by the canonical architecture documents in `Arquitetura/`, per `PROJECT_INDEX.md`'s authority hierarchy. When a finding here references a rule, it cites the owning document — it never restates the rule as if this file were authoritative.

This is a **living document**. It is expected to be edited over time as findings are resolved, re-scoped, or superseded, and as new findings are discovered.

---

## Rules for Maintaining This Backlog

- New findings are added only after evidence (file, line, comment, test output, or reproducible behavior) — never speculative claims like "this probably doesn't work."
- Owner/design decisions must be explicitly marked in **DESIGN DECISIONS REQUIRED** and must never be silently resolved by an agent inferring an answer.
- Do not duplicate canonical gameplay rules here — reference the owning `Arquitetura/` document instead.
- Resolved items are **moved** to `RESOLVED — HISTORICAL RECORD` rather than deleted, so the project retains a record of what was fixed and when.
- Every resolved item should record the commit hash when available.
- Before starting a new major system, check `BLOCKED / DEPENDENCIES` and the P0/P1 sections below for open items that system would depend on.
- Periodically re-audit the repository as systems change — this backlog reflects a point-in-time audit and will drift out of date if not refreshed.
- If evidence for a suspected problem is incomplete, mark it as needing validation rather than asserting it as confirmed.

---

## F-046 — Encerramento da Fase de Investigação Técnica/Balanceamento e Estado Atual

### Encerrados

- F-034–F-045: sequência de investigação técnica e de balanceamento (Affinity, Starter, composição, formação, benchmarks de facção) — **encerrada por decisão explícita do dono do projeto**. Não reabrir sem um bug técnico reproduzível; balanceamento propriamente dito é trabalho futuro, fora do escopo do MVP atual.
- Army Editor: cobertura de teste real end-to-end (`test_army_editor_formation_flow.gd`, F-045) — swap, isolamento de Formações, gravação, recuperação, e confirmação de que a Formação salva pelo Editor bate posição-por-posição com o que `CombatEngine.initialize()` usa em combate real.
- Persistência: round-trip real (`test_kingdom_persistence_roundtrip.gd`, F-045) cobrindo Army/Formação, Cidade, Recursos, XP, Comandante, Mina.
- Bug de liberação antecipada da Guarnição de Mina (ver **R-014** abaixo) — corrigido e coberto por regressão.
- `bootstrap.gd`: conflito de limpeza de `res://reports/` (deleção indiscriminada quebrando dados de benchmark) — corrigido com whitelist (F-040).
- Demais P1 identificados nas sessões F-034–F-045 — corrigidos, ver `RESOLVED` abaixo.
- F-046: infraestrutura mínima de Combate Visual construída e validada com batalha real (ver **R-016**).

### Estado atual

- **P0 = 0**
- **P1 = 0**
- `test_main.tscn`: 653+ asserções, 0 falhas, 0 erros de execução (ver seção "Testes" nas entradas RESOLVED mais recentes para o número exato a cada sessão).
- MVP **tecnicamente estável**. Nenhuma falha técnica conhecida bloqueia o MVP.

### Adiados (P4/P5 — balanceamento e design futuro, não reabrir sem decisão explícita do dono)

- Starter balance (composição/formação ideal do Kit Inicial atual — **provisório**, será substituído/ajustado numa fase de balanceamento própria).
- Composição das Facções.
- Formação ideal / sistema de formação livre pelo jogador (jogador deverá eventualmente montar sua própria Formação a partir das cartas disponíveis — F-042/F-043 já mostraram que composição e formação são interdependentes e que a Posição 1 tem requisitos estruturais importantes; conhecimento a ser usado quando o balanceamento for retomado, não implementado agora).
- Affinity Nível III ("Valores Aprimorados") — bloqueado por ausência de valores em `CARD_CATALOG.md`.
- Efeitos de Afinidade de Doutrina de Comandante (E020/E021/RS050/V070/V071) — especificação insuficiente.
- `territory_completion_count` / Replay — detecção de "Trilha concluída" é peça futura (ver nota já existente em `kingdom.gd`).
- Efeitos de gameplay de Campo de Batalha (além do sorteio/apresentação).
- Evocação/Reanimação.
- Migração completa de `bootstrap.gd` (~3700 linhas remanescentes) para a suíte nativa de assertions (F-001, já parcialmente migrada).
- Integração completa da apresentação visual de combate (`CombatReplayView`) nos pontos reais de disparo de batalha (PvE "Tentar Fase Atual", PvP "Sortear Ataque", combate inicial de conquista de Mina) — infraestrutura pronta e validada (R-016), wiring nos call sites é o próximo passo, deliberadamente não feito nesta sessão para não introduzir risco de última hora num escopo já grande.

---

## F-047 — MVP Playable Loop Integration (Combate Visual real no fluxo de PvE)

O objetivo desta etapa era transformar a infraestrutura de Combate Visual (F-046, R-016) num loop jogável de ponta a ponta: Cidade → PvE → Trilha/Fase → Formação → Combate visto pelo jogador → Resultado → Recompensa → Cidade. Resultado:

- **PvE: integrado e validado com execução real headless.** `PhaseResolver.resolve()` agora anexa um `CombatReplayCollector` a cada combate real disputado (`CombatEngine.initialize()` + `run()`, nunca `run_battle()` — mesmo comportamento, só exposto o suficiente pra anexar o Collector) e devolve tudo em `PhaseResult.battle_replays` (1 item por tentativa real, na mesma ordem — pode ser mais de 1 quando uma Formação perde e a próxima é tentada automaticamente). `pve_panel.gd._on_attempt_fase_pressed()` agora reproduz cada item visualmente (`CombatReplayView`, como overlay modal) ANTES de mostrar o texto de Resultado já existente (F-003) — o fluxo textual pré-existente não foi reescrito, só precedido pela apresentação visual. Validado com um teste real em `bootstrap.tscn` (`_validate_pve_panel_ui()`).
- **Minas: infraestrutura pronta automaticamente, mas sem UI real pra acionar.** `MineConquestResolver.attempt_conquest()` também chama `PhaseResolver.resolve()`, então `battle_replays` já vem preenchido ali também, de graça. PORÉM: uma varredura completa do código confirmou que `MineConquestResolver.attempt_conquest()` **nunca é chamado fora de testes** — nenhum painel real (`minas_panel.gd` gerencia só Minas JÁ conquistadas) tem um botão ou fluxo que dispare a conquista de uma Mina Regional via combate. Isso é uma lacuna PRÉ-EXISTENTE (não introduzida nesta sessão), não um bug novo — registrada como **F-022** abaixo. Não foi construída nenhuma UI nova pra isso (fora do escopo desta etapa, per a regra explícita contra "novo projeto de implementação").
- **PvP: sem combate real algum para integrar.** Confirmado por leitura direta: `pvp_panel.gd._on_sortear_ataque_pressed()` só sorteia um Campo de Batalha e um Exército atacante (`PlanoCampanhaResolver.select_attack()`) — nenhum `CombatEngine` é chamado. O resultado (V/D/E) é escolhido manualmente pelo jogador em botões "Simular Resultado", já autodocumentado no próprio `scope_note` da tela ("sem Matchmaking de verdade... os botões de 'Simular Resultado' aplicam a pontuação sem um adversário real"). Não há nada pra "integrar visualmente" — registrado como **F-023** abaixo (construir PvP real é, por definição, um projeto de implementação novo, fora do escopo desta etapa).
- **F-019 resolvido** para Minas/Legado/PvP: mensagens de falha traduzidas (nunca o código técnico cru) substituindo os `print()`-somente antigos.
- **F-020 investigado e corrigido de forma proporcional:** a preocupação original (geração de ~9000 Fases travando a 1ª carga) não se aplica a um jogador real — `WorldBootstrap._generate_dev_scale_world()` (o caminho que um jogador de verdade percorre) é uma escala pequena e limitada; as ~9000 Fases só existem na ferramenta externa de dev. Corrigida só a mensagem do indicador de carregamento (nunca a lógica/timing, pra não arriscar uma corrida de frames já estabilizada).
- **F-021 parcialmente resolvido:** texto cru de enum (`EM_ANDAMENTO`) no cabeçalho do PvE traduzido. Demais itens cosméticos já registrados permanecem em aberto.

### Bug real encontrado e corrigido nesta etapa (não um P0/P1 de gameplay — um hang de infraestrutura de teste, mas com uma implicação de design real)

`CombatReplayView._show_result()` só emitia `replay_finished` dentro de `_on_continue_pressed()` — ou seja, dependia de um clique real do jogador no botão "Continuar". Isso é o comportamento CORRETO pro jogo real (deixa o jogador ver o banner e decidir quando prosseguir), mas torna qualquer execução headless automatizada (`bootstrap.tscn`) travada indefinidamente esperando um clique que nunca vem. Resolvido com um campo `auto_continue_when_finished` (default `false`, nunca setado em jogo real) que `pve_panel.gd` liga automaticamente só quando `replay_speed_override` também está ligado (mesmo sinal já usado pra acelerar o ritmo da reprodução em teste) — nunca altera o comportamento visto pelo jogador.

#### F-022 — Conquista de Mina Regional (combate real) não tem nenhum ponto de entrada de UI
- **Category:** MISSING UI / BACKEND-COMPLETE-FRONTEND-MISSING
- **Priority:** P5 (rebaixado de P2 pra P5 em F-048 — avaliado objetivamente: o fluxo de Minas funciona completamente sem isso, sem nenhum estado quebrado/enganoso na ausência)
- **Status:** Open — reclassificado como FUTURO em F-048, não bloqueia o MVP atual.
- **Problem:** `MineConquestResolver.attempt_conquest()` (lógica completa, testada) nunca é chamado por nenhum painel real — só por `test_mine_conquest.gd`. `minas_panel.gd` só gerencia Minas já `conquered`; não existe tela/botão que dispare o combate contra a guarnição defensora de uma Mina Regional durante uma Expedição.
- **Evidence:** F-047, grep repo-wide por `MineConquestResolver\.` — únicas ocorrências fora do próprio arquivo são em `test_mine_conquest.gd`.
- **Canonical rule/document:** `MINES.md`, "Exército Defensor Inicial (IA)".
- **User-visible consequence:** Um jogador nunca consegue conquistar uma Mina Regional através da UI atual — só as 3 Minas Iniciais (sem combate) e Minas manualmente marcadas como conquistadas por teste/debug funcionam.
- **Recommended action:** Desenhar e implementar o ponto de entrada real (provavelmente dentro do fluxo de PvE, "desviar pra Mina" durante a marcha, per `PvE.md`) — escopo maior que uma correção pontual, própria de uma etapa dedicada.
- **Owner/design approval required:** Provavelmente sim (onde/como o desvio pra Mina se encaixa na UI de PvE é uma decisão de fluxo, não só técnica).
- **Confidence:** High.

#### F-023 — PvP não tem nenhum sistema de combate real (por design desta entrega, autodocumentado)
- **Category:** MISSING FEATURE (escopo já delimitado)
- **Priority:** P4 (não é um bug — é escopo já definido e comunicado ao jogador na própria tela)
- **Status:** Open (aguardando uma entrega futura de PvP completo)
- **Problem:** `pvp_panel.gd` só implementa Ranking (PL/Divisão) e sorteio de Campo — resultados de batalha são escolhidos manualmente pelo jogador ("Simular Resultado"), nunca computados por `CombatEngine`. Já autodocumentado no próprio `scope_note` da tela.
- **Evidence:** F-047, leitura direta de `pvp_panel.gd._on_sortear_ataque_pressed()`/`_on_simulate_*_result_pressed()`.
- **Canonical rule/document:** N/A — escopo, não regra.
- **Recommended action:** Nenhuma nesta etapa — implementar PvP real (matchmaking, adversário real, `CombatEngine` de verdade) é um projeto próprio, explicitamente fora do escopo de F-047.
- **Owner/design approval required:** Yes — quando essa entrega for priorizada.
- **Confidence:** High.

---

## F-048 — MVP Final Player Experience & Release Readiness

**Limitação declarada desta etapa:** este ambiente de execução é headless (sem display) — não foi possível literalmente clicar/assistir o jogo como um jogador humano faria. O substituto mais rigoroso disponível foi aplicado: leitura linha-a-linha da lógica real de renderização de cada tela, cruzada com traces reais de execução headless (`bootstrap.tscn`) que confirmam estado/texto/fluxo de controle — mas NÃO confirmam alinhamento pixel-a-pixel, sobreposição visual real ou legibilidade de fato. Isso é uma limitação de ambiente, não de esforço, e é sinalizada explicitamente em vez de alegar uma verificação visual que não aconteceu.

### Achados reais desta etapa (não capturáveis pelos 660 assertions — nenhum deles testa CONTEÚDO de texto, só estrutura/estado)

1. **`CombatReplayView` vazava terminologia de motor pro jogador — o achado mais importante desta etapa.** O tabuleiro rotulava os dois lados como "Lado 0"/"Lado 1", e — mais grave — o **banner de Resultado** (a informação mais importante de toda a tela) dizia literalmente "Vitória do Lado 0", nunca "Vitória!"/"Derrota.". Um jogador não tem como saber se é o "Lado 0". Corrigido: novo campo `player_side` (default 0, documentado como a suposição válida hoje — `attempt_army` é sempre side 0 em `PhaseResolver.resolve()`) usado pra rotular "Seu Exército"/"Inimigo" e "Vitória!"/"Derrota."/"Empate." em vez do termo interno do motor.
2. **PvP: a comunicação de "funcionalidade não finalizada" existia, mas lia como desculpa técnica.** "Sem Matchmaking de verdade (depende de servidor)" não deixava claro que PvP real é uma entrega futura, não um bug. Reescrita pra "Prévia do PvP... Batalhas contra outros jogadores chegam numa atualização futura."
3. Varredura de assets/preload em `scenes/` confirmou 0 referências de textura/imagem quebradas.
4. Varredura de "[DEBUG]"/placeholders confirmou que o único elemento de debug já encontrado (F-046, R-017 — botão de gerar Candidato) já está corretamente atrás de `OS.is_debug_build()`; nenhum outro elemento de debug novo encontrado.

### Decisão de Release (seção 13 do brief)

- **A) MVP já pode ser considerado jogável?** **SIM**, com as ressalvas explícitas em (C).
- **B) O loop principal está completo?** **SIM** — Cidade → Centro de Comando → Exército/Formação → PvE → Trilha/Fase → Combate (visual, real) → Resultado → Recompensa → Cidade → retry, todos confirmados funcionando via execução real headless (`bootstrap.tscn`, 0 SCRIPT ERROR) e cobertura de asserção dedicada (Army Editor, persistência, Combate Visual, PhaseResolver).
- **C) O que ainda impede uma versão jogável?** Nada de concreto identificado nesta etapa além dos itens já listados como P2/P3/P4/P5 abaixo — nenhum bloqueador novo.
- **D) O que pode ficar para depois:** F-021 (polish cosmético remanescente — ícones de navegação, indicador de aba, empty labels), F-022 (UI de conquista de Mina Regional), F-023 (PvP real).
- **E) PvP deve ficar fora do MVP?** **Sim** — já tratado como Prévia/futuro nesta etapa, comunicação melhorada; nenhuma implementação nova feita, conforme instruído.
- **F) Minas Regionais devem ficar fora do MVP?** **Sim** — o fluxo de Minas funciona completamente sem conquista Regional (as 3 Minas Iniciais cobrem Guarnição/Ciclo/Produção do início ao fim, sem nenhum estado quebrado ou enganoso na ausência de Minas Regionais). Reclassificado de "pendente" para **FUTURO** — só deveria ser implementado se/quando o fluxo de desvio-pra-Mina durante a Expedição for desenhado.

**P0 = 0. P1 = 0.**

---

## F-049 — Visual Asset Integration & Production Pipeline

Inventário completo (não implementação) dos assets visuais do jogo, feito antes da fase de produção/integração de arte. Achados principais:

- **170 arquivos `.png` já existem em `Assets/MVP/`** (40 cartas — 1:1 com o catálogo de 39 jogáveis + 1 unidade especial de batalha, confirmado nome-a-nome; 11 Battlefields — as 10 oficiais + 1 template; 49 imagens de Cidade/Construções; 12 de Minas; 9 de Trilhas; 12 de Ícones de Trilha). **Apenas 2 (`City.png`, `INICIALIZAÇÃO.png`) estão de fato integrados** em `Game/assets/` e carregados pelo jogo — taxa de integração ~1%.
- `CardResource` e `BattlefieldResource` não têm nenhum campo de arte no schema — todo o jogo hoje mostra cartas/Battlefields exclusivamente como texto (nome/Classe/HP/ESC). Não é um bug: é a peça de integração que falta.
- `Game/docs/production/` (592 arquivos: ART_BIBLE, ASSET_DATABASE, STYLE_GUIDES, PROMPTS, PIPELINES, WORKFLOW) é uma árvore de produção bem estruturada, mas **inteiramente placeholder** ("Template de produção. Conteúdo será definido posteriormente.") — nenhuma dimensão/paleta/convenção estava de fato decidida em lugar nenhum do repositório antes desta etapa. Segue útil como checklist de cobertura (1 ficha por carta/Battlefield/prédio real).
- Zero referências de asset quebradas (`preload()` varrido em toda `scenes/`). Dois arquivos fora de lugar (`WhatsApp Installer.exe` ×2 dentro de `Assets/MVP/`) — sinalizados, não removidos.
- Zero componentes de UI reutilizáveis existem — 13 telas reimplementam independentemente os mesmos padrões (botão Voltar, Label de status, estado vazio).
- Prioridade de integração recomendada (P0): retratos de carta + Battlefield dentro de `CombatReplayView` (maior impacto, infraestrutura já pronta). Pipeline completo de 8 passos e tabelas de mapeamento nome-arquivo publicados como artifact de referência.

Nenhuma alteração de código/regra de jogo nesta etapa — inventário puro. Suíte permanece 660/660, 0 falhas, 0 erros (nada mudou desde F-048).

---

## F-050 — Command Center / World Map Gate Architecture Reorganization

Reorganização de responsabilidade/entrada, por decisão explícita do usuário (confirmada após auditoria apontar o conflito com a decisão anterior citada como "F-016/F-017" em `CITY.md`/`COMMAND_CENTER_UI.md`, que fazia do Centro de Comando a porta de entrada única de PvP/PvE/Minas, e marcava o World Map Gate como decorativo/sem hitbox em `city_panel.gd`). Confirmada como reversão deliberada dessa hierarquia, não um bug.

**Auditoria (achados antes de qualquer alteração):**
- "Campo de Testes" (sistema onde o jogador testaria seus Exércitos) **não existe** em nenhum documento (`Arquitetura/`, `Fundation/`) nem no código — nem sob esse nome, nem sob outro. Registrado como lacuna aberta em `COMMAND_CENTER.md`; nenhuma mecânica foi criada nesta etapa.
- PvE, PvP e Minas já viviam fisicamente como sub-cenas do Centro de Comando (`Game/scenes/command_center/panels/{pve,pvp,minas}_panel.tscn`), roteadas por `command_center_panel.gd`.
- World Map Gate não tinha nenhuma cena — apenas uma menção decorativa na arte da Cidade, explicitamente sem hitbox.
- PvE e Minas têm resolvers/engine reais (`CombatEngine`, `expedition_runtime.gd`, `mining_cycle_resolver.gd`). **PvP não tem combate real implementado** (`pvp_panel.gd` só sorteia Campo/Exército; o resultado é escolhido manualmente pelo jogador em "Simular Resultado" — já autodocumentado como F-023, adiado, fora do escopo desta reorganização).

**O que foi feito:**
- Criada `Game/scenes/world_map_gate/world_map_gate_panel.gd` + `.tscn` — mesmo estilo "sem arte" de `command_center_panel.gd` (ColorRect + Botões nativos), encaminhando para as 3 cenas já existentes (`pve_panel.tscn`/`pvp_panel.tscn`/`minas_panel.tscn`, caminho de arquivo inalterado — nenhum sistema duplicado).
- `command_center_panel.gd`: removidas as entradas "PvE"/"PvP"/"Minas" de `PANEL_SCENES`; adicionada uma entrada "World Map Gate" apontando para a nova cena.
- `pve_panel.gd`/`pvp_panel.gd`/`minas_panel.gd`: botão "Voltar" atualizado de "Centro de Comando" para "World Map Gate" (rótulo + cena de destino) — nenhuma outra linha alterada nesses 3 arquivos.
- `exercitos_panel.gd`: texto do tutorial ("Volte ao Centro de Comando e abra o PvE...") atualizado para citar o World Map Gate no meio do caminho.
- Documentação: `CITY.md` ("Mundo", "Interfaces Fora da Cidade"), `COMMAND_CENTER.md` (nota de esclarecimento + "Relação com Outros Sistemas" + lacuna do Campo de Testes registrada), `COMMAND_CENTER_UI.md` (as 3 janelas PvP/Minas/PvE removidas — relocadas, não reescritas), novo `WORLD_MAP_GATE.md` (SSoT das 3 janelas relocadas), `PROJECT_INDEX.md` (nova entrada de ownership + registro da decisão revertida).
- **Não alterado, deliberadamente (fora do escopo desta etapa):** nenhuma arte, nenhum hotspot visual sobre `city_panel.gd` (World Map Gate continua "decorativo, sem hitbox" na Cidade — alcançado por ora só através do botão no Centro de Comando, mesmo padrão já usado para "Exércitos"/`ARMY.md`); nenhuma regra de combate/recompensa/progressão/economia de PvE, PvP ou Minas; nenhum resolver.

**Validação:** suíte nativa (`Game/tests/test_main.gd`) não testa navegação de cena — só lógica (state machines, timers, formação) — não afetada por esta mudança. `bootstrap.gd` instancia `pve_panel.tscn`/`pvp_panel.tscn`/`minas_panel.tscn` diretamente por caminho de arquivo em ~10 validações; caminho de arquivo não mudou, então essas validações permanecem intactas. Não foi possível abrir o editor Godot neste ambiente para um teste de clique real; recomenda-se percorrer manualmente City → Centro de Comando → World Map Gate → PvE/PvP/Minas → Voltar antes de considerar a etapa encerrada.

**Date:** 2026-08-30.

---

## F-051 — World Map Gate: Correção de Localização Física (City, não Command Center)

Correção do F-050: naquela etapa, o World Map Gate ganhou a responsabilidade documental sobre PvE/PvP/Minas, mas sua própria localização física ficou provisoriamente dentro do Centro de Comando (um botão em `command_center_panel.gd`) — decisão explicitamente marcada como incorreta e corrigida agora, por pedido do dono do projeto.

**Decisão corrigida:** o World Map Gate é uma localização própria da Cidade (grupo "Consulta" de `CITY.md`, mesmo padrão de Biblioteca/Observatório — sem Nível/Evoluir, só Abrir), nunca uma janela do Centro de Comando.

**O que foi feito:**
- `city_panel.gd`: adicionada a região `world_map_gate` a `BUILDING_REGIONS`/`BUILDING_SCENES`, com hitbox sobre o portão físico (torres gêmeas + arco) já desenhado em `City.png`, na base da praça central, abaixo da fonte. Retângulo calibrado por inspeção visual direta (a varredura de cor automática não convergiu — o portão está cercado de outros elementos azuis na arte, como bandeiras e o domo do Núcleo de Energia); primeira aproximação, sujeita a ajuste após inspeção no editor.
- `command_center_panel.gd`: removida a entrada "World Map Gate" de `PANEL_SCENES` — o CdC não referencia mais essa cena em nenhum nível.
- `world_map_gate_panel.gd`: botão "Voltar" (rótulo + destino) trocado de "Centro de Comando" para "Voltar para a Cidade" (`city_panel.tscn`).
- `exercitos_panel.gd`: texto do tutorial atualizado ("Volte à Cidade, abra o World Map Gate...").
- Documentação: `CITY.md` (World Map Gate movido de "Mundo" para "Consulta", como destino direto), `COMMAND_CENTER.md` (removido de "Relação com Outros Sistemas", nota de esclarecimento corrigida), `COMMAND_CENTER_UI.md` (nota de reorganização atualizada), `WORLD_MAP_GATE.md` ("Acesso Atual" reescrito), `PROJECT_INDEX.md`.

**Não alterado:** nenhuma cena, regra ou dado de PvE/PvP/Minas; nenhum resolver; a cena `world_map_gate_panel.tscn` em si (só seu ponto de entrada mudou); a arte própria do World Map Gate (`WORLD MAP GATE.png`) continua não integrada — a tela permanece no estilo funcional sem asset.

**Validação:** mesma suíte/mesma ressalva do F-050 — `test_main.gd` não testa navegação de cena; `bootstrap.gd` não referencia `command_center_panel.gd`/`world_map_gate_panel.gd` diretamente (só os 3 painéis internos por caminho de arquivo, inalterado). Não foi possível testar o clique real no hitbox novo neste ambiente — recomenda-se validar no editor que o retângulo cai sobre o portão antes de fechar a etapa.

**Date:** 2026-08-30.

---

## OPEN — Prioritized Work

### P0 — None currently identified

No data-corruption, active-exploit, broken-core-rule, or development-blocking issue was found with concrete evidence during this audit. (See `RESOLVED` for two items that *were* P0-class — Army double-booking across Expeditions and unconditional Energy recovery during active marching — both closed in commit `0efaca0`.)

---

### P1

#### F-001 — Test suite has no automated pass/fail signal
- **Category:** TOOLING GAP
- **Priority:** P1
- **Status:** Open
- **Problem:** The entire regression suite lives inside `Game/scenes/bootstrap/bootstrap.gd` (6,719 lines) as a single `_ready()` function calling ~150 `_validate_*()` functions that `print()` results with embedded "esperado: X" (expected) text. There is no assertion framework, no non-zero exit code on failure, and no machine-readable pass/fail output — verifying the suite requires a human to read the console transcript and manually compare printed values.
- **Evidence:** `Game/scenes/bootstrap/bootstrap.gd` (6,719 lines, single file); `Game/tests/` contains only `campaign_test_fixtures.gd` (a fixture helper, not a test runner); no `.gd` file anywhere uses an `assert()`-based test macro or a framework like GUT/gdUnit.
- **Canonical rule/document:** None — this is process/tooling, not a gameplay rule.
- **Files/functions:** `Game/scenes/bootstrap/bootstrap.gd`.
- **User-visible consequence:** None directly.
- **Technical consequence:** Regressions can silently pass unnoticed unless a human reads the full console log after every change; this materially increases the risk of every other fix in this backlog (including the ones already shipped this session) going unverified in the future. Confirmed firsthand this session: a full headless run of `bootstrap.tscn` took 20+ minutes and had to be worked around with a disposable fast-path scene for the PvE fixes, precisely because the suite has no way to run a subset or fail fast.
- **Recommended action:** Introduce a real assertion-based test framework (e.g., GUT) incrementally, starting with the highest-risk systems (Combat, PvE Expedition, Energy, Kingdom persistence), without necessarily rewriting all ~150 existing validations at once.
- **Owner/design approval required:** No (tooling choice, not a game rule).
- **Suggested validation:** N/A — this item *is* the validation-infrastructure gap.
- **Dependencies/blockers:** None; can start independently.
- **Confidence:** High.

#### F-002 — No CI/CD pipeline
- **Category:** TOOLING GAP
- **Priority:** P1
- **Status:** Open
- **Problem:** There is no continuous-integration configuration in the repository, so `bootstrap.tscn` (or any test) never runs automatically on commit/push/PR.
- **Evidence:** `.github/workflows/` does not exist in the repository.
- **Canonical rule/document:** None.
- **Files/functions:** N/A (absence of configuration).
- **User-visible consequence:** None directly.
- **Technical consequence:** Compounds F-001 — even if a real test framework is introduced, nothing currently runs it automatically; regressions can be merged/pushed without anyone running the suite.
- **Recommended action:** Once F-001 has a machine-checkable exit code, add a CI workflow that runs Godot headless against the test entry point and fails the build on non-zero exit.
- **Owner/design approval required:** No.
- **Suggested validation:** A CI run that intentionally fails should block, and a passing run should succeed, on a throwaway branch.
- **Dependencies/blockers:** Benefits significantly from F-001 landing first (a print-only suite can't fail a CI build).
- **Confidence:** High.

*(F-003 resolved — see `RESOLVED — HISTORICAL RECORD`.)*

#### F-004 — Commander Rarity is never finalized (Rarity Score → Final Rarity conversion missing)
- **Category:** INCOMPLETE IMPLEMENTATION / DESIGN DECISION REQUIRED
- **Priority:** P1
- **Status:** Open
- **Problem:** `COMMANDER_GENERATION.md`'s official flow (Etapa 8) calls for converting a computed Rarity Score into a Final Rarity (Comum/Rara/Épica/Lendária). The generator computes and stores the raw `rarity_score`, but the conversion into an actual Rarity tier is explicitly not implemented — it's described as "objeto de balanceamento futuro."
- **Evidence:** `Game/engine/commanders/commander_generator.gd:13-15` ("Fora do escopo desta Sprint... conversão do Rarity Score em Raridade Final"); `Game/engine/commanders/commander_doctrine.gd:28-31` (`rarity_score: int` field, comment: "sua conversão em Raridade Final... é objeto de balanceamento futuro").
- **Canonical rule/document:** `Arquitetura/COMMANDER_GENERATION.md`, Etapa 8.
- **Files/functions:** `CommanderGenerator`, `CommanderDoctrine.rarity_score`.
- **User-visible consequence:** Procedurally generated Commanders have no Rarity classification at all today.
- **Technical consequence:** Any future system that needs to key off Commander Rarity (rewards, UI badges, recruitment weighting) has nothing to read.
- **Recommended action:** Owner needs to set the score→rarity thresholds; implementation itself is small once thresholds exist.
- **Owner/design approval required:** **Yes** — the thresholds are a balance decision, not inferable from existing docs.
- **Suggested validation:** Once thresholds are set, a test asserting score-boundary → rarity mapping for all four tiers.
- **Dependencies/blockers:** None blocking other systems currently, but should land before any UI/reward work that assumes Commander Rarity exists.
- **Confidence:** High (explicitly self-documented in two files).

#### F-005 — Campaign Synergy is calculated but never applied in gameplay
- **Category:** MISSING FEATURE / INCOMPLETE INTEGRATION
- **Priority:** P1
- **Status:** Open
- **Problem:** `ABILITIES.md`'s "Sinergia de Campanha" (2+ cards sharing the same Tier III ability activate a binary synergy) is fully implemented as a pure calculator, but nothing in Combat, PvE, or Reward resolution ever calls it to apply a bonus. The calculator's own header says the consuming system doesn't exist yet.
- **Evidence:** `Game/engine/army/campaign_synergy_calculator.gd:8-23` ("Não implementa efeitos, Runtime, registro em evento ou integração com Combate/PvE... Ver Sprint 27 para onde essa resposta será consumida"). Repo-wide search found `CampaignSynergyCalculator` referenced only in its own definition, `bootstrap.gd` (isolated test), `campaign_test_fixtures.gd` (test helper), and one class-level doc-comment mention in `kingdom.gd` that is descriptive text, not a call site.
- **Canonical rule/document:** `Arquitetura/ABILITIES.md`, "Sinergia de Campanha".
- **Files/functions:** `CampaignSynergyCalculator`; no consumer in `CombatEngine`, `PhaseResolver`, or `RewardResolver`.
- **User-visible consequence:** A documented card-synergy mechanic has zero effect on actual battles today.
- **Technical consequence:** None until someone assumes it's live and builds on top of it without checking.
- **Recommended action:** Design/implement the consumer (where in combat resolution the synergy bonus applies, and what it does) — likely related to F-009a's "permanent attribute modifier consultation" gap, since applying a synergy bonus is the same class of problem as applying a permanent Trait modifier.
- **Owner/design approval required:** Possibly — depends on whether the effect of an active synergy is already specified in `ABILITIES.md` beyond "it activates," which this audit did not fully re-verify.
- **Suggested validation:** A Combat-level test asserting that an active Campaign Synergy changes a real battle outcome/stat.
- **Dependencies/blockers:** Related to F-009a (attribute modifier consultation mechanism) — likely shares infrastructure.
- **Confidence:** High on "not consumed"; medium on the exact recommended fix shape (would need `ABILITIES.md` re-read to confirm the intended effect).

*(F-006 resolved — see `RESOLVED — HISTORICAL RECORD`.)*

*(F-016 and F-017 resolved — see `RESOLVED — HISTORICAL RECORD`.)*

#### F-018 — Support-at-Position-5 formation validator not enforced: wiring it into `is_ready_for_battle()` would currently crash existing PvE/Mining content
- **Category:** DESIGN DECISION REQUIRED / BLOCKED VALIDATION
- **Priority:** P1
- **Status:** Open
- **Problem:** `COMBAT_RULES.md §6.5`'s "Restrição de Posicionamento Inicial" (canonicalized this session, owner-confirmed) forbids a Support from starting at Position 5. `Army.has_support_at_position_5()` was added as a pure detection helper (mirrors `CombatEngine._place_army()`'s exact position-assignment algorithm), but it is **deliberately not called from `Army.is_ready_for_battle()`** — the only formation validator in the codebase, whose rejection is enforced via a hard `assert()` inside `CombatEngine.initialize()`. Verified during this session: `ArmyPositioningHeuristic.apply_heuristic()` (used by `EnemyArmyGenerator` for every PvE enemy formation *and* every Mine Reference Formation) and 3 of the 4 `ArmyFormationArchetypes` (β Ofensiva, δ Equilibrada, ε Dispersão — γ Defensiva only under specific compositions with 3+ caster-class cards) all place leftover cards — which can include a Support — into any still-empty board index via a generic "fill remaining" fallback that does not avoid index 4 (Position 5). None of these generators currently guarantee a Support never lands there. Wiring the new check into `is_ready_for_battle()` as-is would start hard-crashing (via `CombatEngine`'s assert) any already-generated enemy/Mine formation that happens to have a Support at Position 5 — a regression with a broad, currently-unquantified blast radius across PvE and Mining, not something this session's narrow movement-rules task should introduce.
- **Evidence:** `Game/engine/army/army.gd` (`has_support_at_position_5()`, with its own comment explaining why it's not wired in); `Game/engine/world/season/army_positioning_heuristic.gd:51-57` (`apply_heuristic()`'s leftover-fill loop, no class exclusion for index 4); `Game/engine/army/army_formation_archetypes.gd` (`_offensive()`, `_balanced()`, `_dispersion()`'s `_fill_remaining()` calls, and `_defensive()`'s caster overflow path — none reserve/avoid index 4 for Suporte).
- **Canonical rule/document:** `Arquitetura/COMBAT_RULES.md §6.5`, "Restrição de Posicionamento Inicial".
- **Files/functions:** `Army.is_ready_for_battle()` (not yet calling `has_support_at_position_5()`); `ArmyPositioningHeuristic.apply_heuristic()`/`apply_random()`; `ArmyFormationArchetypes._offensive()`/`_defensive()`/`_balanced()`/`_dispersion()`.
- **User-visible consequence:** None today — the rule exists in documentation and in a tested detection function, but has no enforcement, so a Support at Position 5 remains silently allowed in practice (a latent rule violation, not yet a crash).
- **Technical consequence:** The moment someone wires `has_support_at_position_5()` into `is_ready_for_battle()` without first fixing the generators, previously-working PvE enemy generation and Mine reference-formation freezing can start failing the `CombatEngine.initialize()` assert.
- **Recommended action:** Fix the generators first (make each one deliberately skip/defer index 4 for Suporte-class leftovers, guaranteeing a non-Support card fills Position 5 whenever possible), *then* wire `has_support_at_position_5()` into `Army.is_ready_for_battle()`. Sequencing matters — owner should confirm this order before either half is implemented.
- **Owner/design approval required:** **Yes** — both the generator-fix approach and the sequencing (fix-then-enforce vs. enforce-with-a-soft-reject-elsewhere) are design choices, not purely mechanical fixes.
- **Suggested validation:** Once generators are fixed, a regression test asserting `ArmyPositioningHeuristic`/`ArmyFormationArchetypes` never place a Support at index 4 across a representative sample of compositions (including the γ 3+-caster edge case), then a test confirming `is_ready_for_battle()` correctly rejects a hand-built Support-at-5 Army.
- **Dependencies/blockers:** Should land before `has_support_at_position_5()` is ever called from `is_ready_for_battle()`.
- **Confidence:** High — the reachability of Support-at-Position-5 through `apply_heuristic()` was directly traced and confirmed in this session, not inferred.

---

### P2

*(F-007 and F-008 resolved — see `RESOLVED — HISTORICAL RECORD`.)*

#### F-009 — Two open Combat/Ability architectural gaps (already self-tracked in DECISOES.md)
- **Category:** INCOMPLETE IMPLEMENTATION
- **Priority:** P2
- **Status:** Open (pre-existing, re-surfaced here for visibility)
- **Problem:**
  - (a) No consultation mechanism exists for permanent attribute modifiers queried continuously by `CombatEngine` — blocks full implementation of Habilidades/Características whose effect is a standing bonus (example given: "Colheita de Almas" +4% ATK, today only partially implemented via `UnitTraitRuntime`).
  - (b) `CombatEngine._apply_structural_heal()` uses a hardcoded `STRUCTURAL_HEAL_AMOUNT` constant instead of reading a value back from `CombatContext` (unlike the attack-value flow, which already does this) — blocks full parametrization of "Cura" (Tier I) and any Ability/Trait that would modulate structural healing.
- **Evidence:** `Arquitetura/DECISOES.md`, "Pendências Consolidadas (Sprints 24/25)" → "Pendências Arquiteturais" (both items verbatim).
- **Canonical rule/document:** `Arquitetura/DECISOES.md`; `Arquitetura/ABILITIES.md`; `Arquitetura/COMBAT_CORE.md`.
- **Files/functions:** `CombatEngine`, `UnitTraitRuntime`.
- **User-visible consequence:** Specific Traits/Abilities relying on these mechanisms don't fully work as documented.
- **Technical consequence:** Blocks correctly implementing any *future* Ability/Trait in the same category without first building the missing infrastructure.
- **Recommended action:** No new action recommended by this audit — `DECISOES.md` already owns this; re-surfaced here so the backlog is a complete single list of open technical work.
- **Owner/design approval required:** Not for the infrastructure itself; individual Trait behaviors built on top of it may need design confirmation.
- **Suggested validation:** Already the responsibility of whoever picks this up per `DECISOES.md`.
- **Dependencies/blockers:** F-005 (Campaign Synergy application) likely needs the same kind of modifier-consultation infrastructure as (a).
- **Confidence:** High (verbatim from the project's own architectural decision record).

#### F-010 — Two open content/history gaps (already self-tracked in PROJECT_INDEX.md)
- **Category:** DESIGN DECISION REQUIRED / MISSING CONTENT
- **Priority:** P2
- **Status:** Open (pre-existing, re-surfaced here for visibility)
- **Problem:** `Treinamento Arcano` remains unresolved because its historical definition is missing and has not been recovered; the historical chain of `Engenharia Militar II` must not be reconstructed by inference and remains unresolved for the same reason.
- **Evidence:** `PROJECT_INDEX.md`, "Confirmed MVP invariants" section (verbatim); `Arquitetura/AUDITORIA_FINAL_v0.9.md` §2 confirms the same status.
- **Canonical rule/document:** `PROJECT_INDEX.md`; `Arquitetura/ABILITIES.md` (where these would eventually live).
- **Files/functions:** N/A — missing source material, not code.
- **User-visible consequence:** These two Abilities/mechanics cannot be implemented until source content is recovered or the owner makes a call.
- **Technical consequence:** None beyond the content gap.
- **Recommended action:** No new action — already correctly flagged as blocked-on-recovery in project governance; re-surfaced here for backlog completeness.
- **Owner/design approval required:** **Yes** — either recovered historical material must surface, or the owner must decide to design these fresh.
- **Suggested validation:** N/A until content/decision arrives.
- **Dependencies/blockers:** None on other systems.
- **Confidence:** High (verbatim from project governance docs).

#### F-011 — Academy production-time estimate doesn't reflect real parallel completion time
- **Category:** INCOMPLETE IMPLEMENTATION
- **Priority:** P2
- **Status:** Open
- **Problem:** `AcademyResolver`'s production preview field `sequential_time_seconds` is the sum of every step's duration in sequence (a ceiling), not the real wall-clock time the Modo Prioritário would achieve by using multiple free Masters in parallel.
- **Evidence:** `Game/engine/academy/academy_resolver.gd:49-53` (self-documented).
- **Canonical rule/document:** `Arquitetura/ACADEMY.md`.
- **Files/functions:** `AcademyResolver` production-preview path.
- **User-visible consequence:** The time shown to the player for a production plan may overstate how long it will actually take when multiple Masters are free.
- **Technical consequence:** None beyond the display inaccuracy.
- **Recommended action:** Compute a real parallel-completion estimate, or clearly label the current field as an upper bound in the UI.
- **Owner/design approval required:** No.
- **Suggested validation:** A test comparing `sequential_time_seconds` against actual simulated completion time for a plan with 2+ free Masters.
- **Dependencies/blockers:** None.
- **Confidence:** High (self-documented, low severity).

*(F-015 resolved — see `RESOLVED — HISTORICAL RECORD`.)*

#### F-019 — Ação rejeitada por um Resolver só aparece no console, nunca na tela (padrão repetido em vários painéis)
- **Category:** UX GAP
- **Priority:** P2
- **Status:** **Resolved (F-047, R-021)** — mensagens traduzidas adicionadas em `minas_panel.gd`, `legado_panel.gd`, `pvp_panel.gd`.
- **Problem:** Em `minas_panel.gd` (`_on_assign_guarnicao_pressed`), `legado_panel.gd` (`_on_retire_administrative_pressed`/`_on_create_grande_legado_pressed`), e `pvp_panel.gd` (`_on_create_plano_pressed`/`_on_sortear_ataque_pressed`), quando o Resolver correspondente retorna `{"success": false, "reason": ...}`, o motivo só é escrito via `print()` — o jogador nunca vê nada na tela, o clique parece não fazer nada. `city_panel.gd` (F-009) e `academia_panel.gd` (corrigido nesta sessão, F-046) já resolveram exatamente esse mesmo padrão com um Label de status persistente — a mesma técnica se aplicaria diretamente aqui.
- **Evidence:** F-046, auditoria de produto (3 forks de leitura paralela cobrindo todos os painéis da Cidade/Centro de Comando).
- **Canonical rule/document:** N/A (UX, não regra de jogo).
- **Files/functions:** `minas_panel.gd`, `legado_panel.gd`, `pvp_panel.gd`.
- **User-visible consequence:** Clique em uma ação bloqueada (ex: tentar designar Guarnição com Ciclo já ativo) não dá nenhum feedback visível.
- **Recommended action:** Replicar o padrão `_action_status_text` (persistente entre reconstruções da árvore) já usado em `academia_panel.gd`/`city_panel.gd` nos 3 painéis acima.
- **Owner/design approval required:** No.
- **Confidence:** High (evidência direta de código em 3 arquivos).

#### F-020 — Primeira entrada em PvE pode travar a percepção do jogador sem indicação de progresso
- **Category:** UX GAP / PERCEIVED-HANG RISK
- **Priority:** P2
- **Status:** **Resolved (F-047, R-021), com ressalva** — investigação encontrou que o risco original era menor do que o registrado (a geração real de um jogador é pequena/limitada; ~9000 Fases é exclusivo da ferramenta externa de dev). Corrigida a mensagem do indicador de carregamento; a lógica/timing de carregamento não foi alterada (risco de regredir uma corrida de frames já estabilizada, per bootstrap.gd `_validate_pve_panel_ui()`).
- **Problem:** `pve_panel.gd` (linhas ~44-49) mostra um Label de carregamento, mas só aguarda 2 `await get_tree().process_frame` antes de chamar `WorldBootstrap.ensure_world_loaded()` de forma síncrona — na primeira visita do jogador ao PvE, isso gera a Temporada inteira (~9000 Fases, ver F-039). O Label de loading renderiza por 2 frames e a UI trava sem indicação de progresso até a geração terminar.
- **Evidence:** F-046, auditoria de produto (fork do cluster Army/PvE).
- **Canonical rule/document:** N/A.
- **Files/functions:** `pve_panel.gd`.
- **User-visible consequence:** Primeira visita ao PvE pode parecer um travamento (não é um crash — sempre termina — mas sem feedback de progresso real).
- **Recommended action:** Um mecanismo real de progresso (sinal emitido por `WorldBootstrap` a cada Território/Trilha gerada, consumido pelo Label) ou, no mínimo, uma mensagem explícita "Isso pode levar alguns segundos na primeira vez" antes de travar.
- **Owner/design approval required:** No.
- **Confidence:** Medium — não medido o tempo real de geração nesta sessão, só confirmado o mecanismo síncrono sem progresso.

---

### P3

#### F-012 — Multiple scaffolded engine/scene/UI/tool directories are empty
- **Category:** TECHNICAL DEBT / LOW PRIORITY
- **Priority:** P3
- **Status:** Open
- **Problem:** Several directories exist with zero files, seemingly pre-scaffolded for structure that was later built elsewhere: `Game/scenes/{observatory,library,commanders,modes,shared,combat/battlefield}`, `Game/engine/{economy,modes,persistence,services}`, `Game/ui/{animations,components,fonts,icons,themes}`, `Game/tools/{database_builder,debug,exporters,importers,project_builder}`.
- **Evidence:** Directory listing via `find -type d -empty`. Spot-verified two of the suspected "missing feature" cases directly: Observatory is fully implemented at `Game/scenes/city/panels/observatorio_panel.gd/.tscn` (not the empty `scenes/observatory/`), and Library is implemented at `Game/scenes/city/panels/biblioteca_panel.gd` (not the empty `scenes/library/`) — both scaffolds are superseded, not gaps.
- **Canonical rule/document:** N/A.
- **Files/functions:** The empty directories listed above.
- **User-visible consequence:** None.
- **Technical consequence:** Minor navigation confusion for anyone (human or agent) assuming these directories represent unbuilt features — this audit found the two most doc-suggestive cases (Observatory, Library) are actually implemented elsewhere, so this is very likely pure leftover scaffolding rather than missing work, but this was not exhaustively verified for every directory listed.
- **Recommended action:** A dedicated cleanup pass: for each empty directory, confirm its function lives elsewhere (delete the scaffold) or confirm it's genuinely unbuilt (track separately, upgrade priority if so).
- **Owner/design approval required:** No.
- **Suggested validation:** Per-directory confirmation as described above.
- **Dependencies/blockers:** None.
- **Confidence:** Medium — two of ~20 directories directly verified as superseded; the rest are inferred by the same pattern but not individually checked.

#### F-013 — Duplicate/unused asset-directory scaffold under Game/
- **Category:** TECHNICAL DEBT / LOW PRIORITY
- **Priority:** P3
- **Status:** Open
- **Problem:** `Game/assets/{art,audio,fonts,icons,music,sfx,shaders}` all exist and are empty, while actual game art (card/enemy/UI images) lives in a separate top-level `Assets/` directory outside `Game/` (observed throughout this session, e.g. `Assets/MVP/*.png`).
- **Evidence:** `find Game/assets -type d -empty`; prior-session `git status` output showing real art content under the repo-root `Assets/MVP/` directory.
- **Canonical rule/document:** N/A.
- **Files/functions:** `Game/assets/*`.
- **User-visible consequence:** None.
- **Technical consequence:** Two plausible asset-root locations in the same repository is a real risk for future import-path confusion.
- **Recommended action:** Confirm with the project owner which location is canonical going forward and remove the unused scaffold.
- **Owner/design approval required:** Minor — just confirming intended structure.
- **Suggested validation:** N/A.
- **Dependencies/blockers:** None.
- **Confidence:** Medium (inferred from directory emptiness plus observed asset activity elsewhere; not a deep art-pipeline audit).

#### F-014 — Empty `library_content` database directory is superseded
- **Category:** LOW PRIORITY / COSMETIC
- **Priority:** P3
- **Status:** Open
- **Problem:** `Game/database/library_content/` is empty. `Arquitetura/LIBRARY_CONTENT.md` exists as a doc, but recipe/library data is actually stored directly on `CardResource.recipe_ingredients` per-card, not as separate files in this folder.
- **Evidence:** `find Game/database/library_content -type f` (empty); `recipe_ingredients` field usage confirmed on `Game/resources/cards/card_resource.gd` and consumed directly by `Game/engine/academy/academy_resolver.gd`.
- **Canonical rule/document:** `Arquitetura/LIBRARY_CONTENT.md`.
- **Files/functions:** `Game/database/library_content/` (empty), `CardResource.recipe_ingredients` (actual data location).
- **User-visible consequence:** None — the feature works, just not from this folder.
- **Technical consequence:** None beyond minor housekeeping confusion.
- **Recommended action:** Remove the empty scaffold, or repurpose it if `LIBRARY_CONTENT.md` intends additional data beyond per-card recipes.
- **Owner/design approval required:** No.
- **Suggested validation:** N/A.
- **Dependencies/blockers:** None.
- **Confidence:** High.

#### F-021 — Itens de apresentação/polish encontrados na auditoria de produto F-046 (sem impacto funcional)
- **Category:** LOW PRIORITY / COSMETIC
- **Priority:** P3
- **Status:** Open
- **Problem (lista consolidada, cada item confirmado por leitura direta de código):**
  - Botões de navegação (Centro de Comando, Exércitos) sem ícone/diferenciação visual, só texto puro.
  - `city_panel.gd`: `info_label` fica vazio para Biblioteca/Observatório (todo outro prédio mostra nível/custo ali).
  - `biblioteca_panel.gd`: "Lore não disponível ainda." é mostrado literalmente ao jogador — honesto e já autodocumentado no cabeçalho do arquivo, não escondido, mas ainda é um placeholder cru.
  - `observatorio_panel.gd`: o conteúdo principal (Relatório de Balanceamento) só pode ser populado por uma ferramenta externa fora do jogo (`tools/balance_report/`) — pra qualquer jogador real, esta tela é permanentemente "Nenhum relatório gerado ainda." Não é bug, é uma limitação estrutural do MVP atual.
  - `pve_panel.gd`: `_status_name()` usa `ExpeditionRuntime.Status.keys()[status]` cru (ex: `EM_ANDAMENTO`) direto no Label do cabeçalho, em vez de um texto traduzido/formatado.
  - `army_editor_panel.gd`: sem mensagem de estado vazio se `kingdom.cards`/`kingdom.commanders` resultar em zero opções elegíveis em `_refresh_choice_phase()`; indicador de aba de Formação ativa é só `[texto entre colchetes]`, sem estado visual real.
  - `starter_kit_panel.gd`: feedback de escolha é só a troca de tela (sem confirmação/animação) — aceitável, mas mínimo.
- **Canonical rule/document:** N/A.
- **Recommended action:** Nenhuma ação nesta sessão (F-046 §12, regra contra escopo infinito — "seria melhor se..." sem estar quebrado não vira trabalho automaticamente). Revisar numa fase dedicada de polish visual.
- **Owner/design approval required:** No.
- **Confidence:** High — todos os itens confirmados por leitura direta de código nesta sessão.

---

## DESIGN DECISIONS REQUIRED

These items cannot be safely resolved by implementation work alone — they need an explicit call from the project owner.

| ID | Decision needed |
|---|---|
| F-004 | Score-to-tier thresholds for converting a Commander's Rarity Score into a Final Rarity (Comum/Rara/Épica/Lendária). |
| F-010 | Whether to keep waiting for recovered historical material on `Treinamento Arcano` / `Engenharia Militar II`, or have the owner design them fresh. (Already flagged as blocked in `PROJECT_INDEX.md` — not a new decision surfaced by this audit, just re-listed here for completeness.) |
| F-018 | Approach and sequencing for making `ArmyPositioningHeuristic`/`ArmyFormationArchetypes` never place a Support at Position 5, before `has_support_at_position_5()` can safely be wired into `Army.is_ready_for_battle()`. |

---

## BLOCKED / DEPENDENCIES

- **F-005** (Campaign Synergy has no gameplay effect) is related to **F-009(a)** (no permanent-attribute-modifier consultation mechanism) — both likely need the same combat-side infrastructure. Solving F-009(a) first would make F-005 meaningfully cheaper to close.
- **F-002** (no CI) is far more valuable once **F-001** (no assertion framework) exists — a print-only suite gives CI nothing to gate on. Sequence F-001 before F-002.

No item in this backlog blocks the four systems finalized this session (PG, Deposits, PvE Expedition locking, Energy recovery) — those are closed, see below.

---

## RESOLVED — HISTORICAL RECORD

### R-016 — Combate sem nenhuma representação visual (F-044 finding) — infraestrutura mínima construída e validada com batalha real (F-046)
- **Original problem:** `CombatEngine` resolve uma batalha inteira de forma síncrona e instantânea (`run()`); a única "apresentação" existente era texto (`"Vitória"/"Derrota"` concatenado num histórico). Confirmado por leitura direta de `phase_resolver.gd` e `pve_panel.gd._on_attempt_fase_pressed()` — zero representação de tabuleiro, unidades, turnos ou eventos.
- **Resolution:** Construída infraestrutura mínima de reprodução visual, sem tocar `CombatEngine` nem nenhuma regra de combate: (1) `CombatReplayCollector` (`engine/combat/combat_replay_collector.gd`) — assinante opcional do `CombatEventBus` no mesmo padrão de `BattleEventCollector` (F-028), captura `TURN_START/TURN_END/UNIT_MOVED/AFTER_ATTACK/AFTER_HEAL_PERFORMED/UNIT_DIED` em ordem cronológica (`replay_events`) mais um snapshot do tabuleiro inicial (`snapshot_initial_board()`, chamado logo após `CombatEngine.initialize()`); (2) `CombatReplayView` (`scenes/combat/combat_replay_view.gd` + `.tscn`) — Control construído em código (mesmo padrão de `ArmyEditorPanel`/`AcademiaPanel`), mostra um tabuleiro 3x3 por Lado (nome da carta, Classe, HP, ESC, vivo/morto), um feed de log textual, contador de turno, e percorre `replay_events` com ritmo humano (`await` entre eventos) até mostrar o banner de Resultado (Vitória/Derrota/Empate) e um botão "Continuar" (`replay_finished` signal — quem instancia decide a navegação seguinte, ex: ir pra Recompensa).
- **Validation performed:** `test_combat_replay_view.gd` — batalha real entre 2 Exércitos Starter via `CombatEngine.initialize()`/`run()` (seed fixa), com o Collector attach()ado antes de `run()`. Confirma: (A) snapshot inicial captura as 18 unidades (9+9); (B) uma batalha real produz eventos de replay; (C) — o teste central — o tabuleiro reconstruído pela View, percorrendo `_apply_replay_event()` evento a evento, bate EXATAMENTE (nome/HP/ESC/vivo-ou-morto) com o `CombatState` final real do motor, posição por posição, para as 18 posições; (D) banner de Resultado e botão Continuar aparecem corretamente ao final. 4/4 asserções.
- **Explicitly deferred (documented, not silently dropped):** wiring de `CombatReplayView` nos pontos reais de disparo de batalha (PvE "Tentar Fase Atual", PvP "Sortear Ataque", combate inicial de Mina) — cada um exigiria expor um `CombatReplayCollector` opcional através de `PhaseResolver`/`ExpeditionRuntime`/chamadas diretas de `CombatEngine` nos painéis, span maior que o resto desta sessão comportava com segurança. Ver "F-046 — Adiados" acima.
- **Known limitation (documented in code, not a bug):** `CombatContext` (evento `UNIT_MOVED`) não carrega a posição de ORIGEM do movimento — só a de destino (`unit.position` já é reescrito antes do evento publicar). `CombatReplayView` reconstrói a posição anterior sozinha, mantendo o tabuleiro completo em memória enquanto percorre os eventos — não precisou de nenhuma mudança em `CombatEngine` para isso.
- **Godot tooling note:** ambos os arquivos novos usam `class_name` (`CombatReplayCollector`/`CombatReplayView`) — como o cache global de classes do Godot (`.godot/global_script_class_cache.cfg`) só é regenerado por uma varredura do Editor (nunca por uma execução `--headless`), qualquer referência a esses dois nomes por identificador puro (não `preload()`) noutro arquivo falha com `SCRIPT ERROR: Parse Error` até essa varredura acontecer — inclusive um campo tipado (`var x: CombatReplayCollector`) dentro do PRÓPRIO `combat_replay_view.gd`. Resolvido evitando anotação de tipo estática pra esses dois nomes em todo lugar que os referencia antes da regeneração do cache (mesmo padrão já estabelecido em F-045 pro Army Editor).
- **Date:** 2026-08-22.
- **Commit:** *(pendente — ver commit desta sessão).*

### R-015 — 5 checagens obsoletas em `bootstrap.gd` corrigidas durante a validação de regressão do F-045
- **Original problem:** Durante a investigação de um teste travado (F-045), a regressão bounded de `bootstrap.tscn` revelou 4 checagens cujo resultado impresso não batia com o "esperado" — não por bug de jogo, mas por texto/lógica de teste desatualizados: (1)/(2) duas checagens buscavam o texto literal "Escolha seu Comandante inicial" na tela do Kit Inicial, que desde F-030 é uma composição de imagem sem nenhum Label dinâmico; (3) o teste de UI da Liga Bronze (PvP) não garantia Cargo Ativo disponível pros 3 Comandantes de teste, então `move_to_active()` falhava silenciosamente pro 2º/3º num Reino compartilhado já com capacidade esgotada por validações anteriores na mesma execução; (4) o teste de Geração Normal comparava `commander_name == ""`, mas `EnemyArmyGenerator` sempre nomeia esse Comandante como "Comandante Técnico (Facção)", nunca string vazia. Uma 5ª checagem ("Modo Manual libera Guarnição") ficou estruturalmente impossível de passar depois da correção R-014 abaixo, porque a Mina de teste usava `adjacent_fase = -1` (Mina Inicial — nunca expira por design, `MINES.md`).
- **Resolution:** (1)/(2) trocadas por checagem estrutural (presença/ausência de um filho `StarterKitPanel`, mesmo padrão já usado logo abaixo no mesmo teste). (3) `kingdom.cargo_ativo_activated += 1` direto, mesmo padrão já usado em `_validate_ui_minas_panel()`. (4) checagem trocada para `commander_name.begins_with("Comandante Técnico")`. (5) a Mina de teste é convertida de Mina Inicial pra Mina Regional (`mina.adjacent_fase = 1500`) a partir do ponto em que o teste passa a depender de expiração real — as checagens anteriores (texto "Mina Inicial", designar Guarnição) continuam intactas.
- **Validation performed:** `bootstrap.tscn` rodado 5 vezes ao longo da investigação — 0 SCRIPT ERROR, 0 mismatch não explicado na versão final; `test_main.tscn` 653/653 (0 falhas) confirmado inalterado a cada correção.
- **Date:** 2026-08-22.
- **Commit:** *(pendente — ver commit desta sessão).*

### R-014 — Guarnição de Mina liberada silenciosamente antes do jogador iniciar o Ciclo (violação da trava anti-exploit documentada)
- **Original problem:** `minas_panel.gd._on_assign_guarnicao_pressed()` chama `refresh() -> GameRuntime.sync()` imediatamente após uma designação bem-sucedida, ANTES de o jogador clicar em "Iniciar Ciclo" (passos 4 e 5, separados, de `MINES.md`). `MineGuarnicaoResolver.release_if_cycle_ended()` tratava "Ciclo nunca iniciado" (`cycle_started_unix == 0`) igual a "Ciclo já terminado", liberando a Guarnição de volta pra `AVAILABLE` nesse mesmo sync — sem nenhuma ação do jogador. Consequência: o mesmo Exército podia ser redesignado como Guarnição de uma SEGUNDA Mina antes do 1º Ciclo sequer começar, violando a trava anti-exploit documentada em `COMMAND_CENTER_UI.md` ("Só Exércitos livres... podem ser designados").
- **Resolution:** `MineGuarnicaoResolver.release_if_cycle_ended()` (`engine/campaign/mine_guarnicao_resolver.gd`) ganhou uma guarda `if mina.cycle_started_unix == 0: return` — só libera quando um Ciclo REALMENTE começou e depois terminou, nunca quando ainda não começou.
- **Validation performed:** Regressão nova em `test_mine_guarnicao_and_production.gd` reproduzindo exatamente o cenário real (`GameRuntime.sync()` chamado entre designar e iniciar o Ciclo) — confirma que a Guarnição permanece travada. A checagem pré-existente de liberação real ao fim do Ciclo (`GameRuntime.sync()` depois de `start_cycle()`) continua passando, confirmando que a correção não regrediu o caminho legítimo de liberação.
- **Date:** 2026-08-22.
- **Commit:** *(pendente — ver commit desta sessão).*

### R-021 — Combate Visual integrado no fluxo real de PvE, incluindo o feedback de ações rejeitadas em Minas/Legado/PvP (F-019) e mensagem de carregamento do PvE (F-020)
- **Scope:** F-047 — ver seção "F-047 — MVP Playable Loop Integration" acima pro detalhamento completo. Resumo: `PhaseResolver.resolve()` ganhou `PhaseResult.battle_replays`; `pve_panel.gd` reproduz cada combate real via `CombatReplayView` antes do Resultado textual já existente; corrigido um hang real (`auto_continue_when_finished`) que só se manifestava em execução headless automatizada, nunca no jogo real; F-019 resolvido para Minas/Legado/PvP; F-020 corrigido de forma proporcional (só a mensagem, investigação mostrou que o risco original era menor do que o registrado); F-021 parcialmente resolvido (texto de status do PvE).
- **Validation performed:** `test_phase_retry.gd` (3 novas asserções: battle_replays.size()==attempts, CombatState/Collector válidos, última tentativa == vencedora); `test_main.tscn` completo (660 passou, 0 falhou, 0 erros); `bootstrap.tscn` completo rodado 2x (1x expôs o hang do "Continuar", 1x confirmando a correção — 0 SCRIPT ERROR, fluxo real "Tentar Fase Atual" -> Fase avança -> Resultado aparece na tela, tudo `true`).
- **Date:** 2026-08-22.
- **Commit:** *(pendente — ver commit desta sessão).*

### R-017 — Botão de debug ("[DEBUG] Gerar Candidato Agora") sempre visível, também em builds de produção
- **Original problem:** `comandantes_panel.gd` adicionava incondicionalmente um botão que ignora o cooldown de 24h de geração de Candidato — o próprio comentário do código já dizia "Nunca deve existir fora do modo de desenvolvimento", mas nenhuma checagem impedia isso.
- **Resolution:** Envolvido em `if OS.is_debug_build():` — mecanismo padrão do próprio Godot pra diferenciar Editor/exportação de debug (true) de uma exportação de release (false).
- **Date:** 2026-08-22. **Commit:** *(pendente).*

### R-018 — JSON cru exposto ao jogador no Observatório
- **Original problem:** `observatorio_panel.gd._build_generation_log_section()` renderizava `JSON.stringify(entry)` (sintaxe crua, chaves entre aspas) direto num Label visível ao jogador.
- **Resolution:** Nova função `_format_log_entry()` formata cada entrada como `"chave: valor | chave2: valor2"` — as ferramentas dev que gravam no Registro (`regional_generator_panel`, `regional_chief_generator_panel`, `pve_generator_panel`, `balance_report_panel`) usam conjuntos de chaves diferentes por "type", então este é o formato genérico mais legível sem um template dedicado por tipo (fora do escopo desta correção).
- **Date:** 2026-08-22. **Commit:** *(pendente).*

### R-019 — Texto de instrução do Army Editor descrevia um gesto que não existe
- **Original problem:** `army_editor_panel.gd` instruía o jogador a "arraste a força certa pra cada posição" — o mecanismo real é seleção por menu suspenso (OptionButton), nunca arrastar-e-soltar.
- **Resolution:** Texto corrigido para "escolha a carta certa pra cada posição no menu".
- **Date:** 2026-08-22. **Commit:** *(pendente).*

### R-020 — Academia sem feedback visível quando Produzir/Aprimorar/Melhorar Fila é rejeitado
- **Original problem:** Mesmo padrão já corrigido em `city_panel.gd` (F-009), mas não replicado em `academia_panel.gd`: falha de `AcademyResolver` só ia pro `print()`, nunca pra tela.
- **Resolution:** `_action_status_text` (var persistente da instância, sobrevive à reconstrução completa da árvore que `refresh()` faz aqui — diferente de `city_panel.gd`, que atualiza Labels existentes em vez de reconstruir) exibido como Label logo abaixo do Resumo, preenchido nos 3 handlers (`_on_produce_pressed`/`_on_upgrade_pressed`/`_on_upgrade_master_queue_pressed`).
- **Date:** 2026-08-22. **Commit:** *(pendente).*

### R-011 — Support movement did not implement the canonical blocking-chain rule (F-016)
- **Original problem:** `CombatEngine._can_advance()`'s Suporte branch collected every allied platoon behind a Support and only permitted advance if that list was empty or exactly one War Machine — it did not recurse through a chain, so "Suporte → Suporte → Máquina de Guerra," "Suporte → Suporte → Suporte," and (critically) "Suporte → Máquina de Guerra → convencional" were not all handled correctly. Verifying the owner-supplied examples revealed the correct rule is *asymmetric*: a Máquina de Guerra immediately behind a Suporte is an opaque terminator (whatever is further back is irrelevant), while a Suporte immediately behind is transparent (the check must recurse through it) — the first implementation attempt this session treated both as equally transparent, which fails the "Suporte → Máquina de Guerra → convencional advances normally" case.
- **Resolution:** Rewrote the Suporte branch of `_can_advance()` as `_support_chain_clear()` — checks only the immediate neighbor; stops (non-blocking) on empty or Máquina de Guerra; recurses through Suporte; blocks on any other Class. Corrected the matching `COMBAT_RULES.md §6.5` wording to state the same asymmetry explicitly (the first documentation pass had also incorrectly described symmetric recursion). Added a permanent regression test, `_validate_movement_rules()` (`bootstrap.gd`), covering all 8 authoritative chain/position cases plus War Machine mobility and Position-5 reorganization timing — verified via a disposable diagnostic scene (deleted after use) since the full `bootstrap.tscn` run is currently very slow (see F-001).
- **Date:** 2026-08-18.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** All 11 assertions in `_validate_movement_rules()` pass (cases A-K from the task brief); `_validate_combat_engine()`'s full 64-turn battle smoke-tested afterward with no script errors, confirming the change doesn't break a real end-to-end battle.

### R-012 — War Machine mobility contradicted `COMBAT_RULES.md §6.6` (F-017)
- **Original problem:** `COMBAT_RULES.md §6.6` already stated a War Machine "não torna... permanentemente imóvel; após o início do combate, sua movimentação segue normalmente as regras gerais," but `CombatEngine._can_advance()` hardcoded `"Máquina de Guerra": return false` (with a comment explicitly claiming "Máquina de Guerra nunca avança") — it could never move after being placed at Position 9. Owner confirmed the documentation's version is correct: War Machine's only special rule is the Position-9 starting constraint; it follows the general movement rule afterward.
- **Resolution:** Removed the War Machine special case from `_can_advance()` entirely — it now falls through to the general rule (`_: return true`), identical to any other non-Support Class. `_place_army()` (which forces the Position-9 starting placement) was left untouched — that rule is unaffected and still correct. Updated the adjacent code comments to no longer claim War Machine is a movement exception.
- **Date:** 2026-08-18.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** `_validate_movement_rules()` cases A/B confirm the War Machine starts at Position 9 via a real `Army`/`CombatEngine.initialize()` path and subsequently advances when its front square is free; `_validate_combat_engine()` full-battle smoke test passed with no errors.

### R-013 — Mining Efficiency incremental background calculation was disabled ("Invalid Task ID") — root-caused, redesigned, and re-enabled (F-003)
- **Original problem:** `MINES.md`'s documented "Cálculo Incremental por Amostragem" model (async background sampling via `WorkerThreadPool`) was disabled — the driving code was commented out in `GameRuntime.sync()`, replaced by a fixed 200-sample synchronous fallback in `minas_panel.gd`, due to a historical, unresolved "Invalid Task ID" threading crash that had been leaking into unrelated screens (`GameRuntime.sync()` is called from nearly every panel).
- **Root cause (confirmed experimentally, via a disposable diagnostic scene, not re-explained in full here — see the full investigation trail in this project's session history):** a malformed/unwritten `chunk_results[chunk_index]` entry (e.g. from a worker-thread script error) causes `MiningEfficiencyEstimator.poll_batch()` to return `null` via a recoverable GDScript runtime type-error rather than a caller-visible exception. `MiningCycleResolver.poll_pending_block()` cannot distinguish that from "still running," so it never reaches the line that clears `efficiency_pending_task_ids`. The next poll then calls `WorkerThreadPool.is_task_completed()`/`wait_for_task_completion()` on already-disposed task IDs — the literal, Godot-documented trigger for `ERR_INVALID_PARAMETER` ("Invalid Task ID"). **During this session's implementation**, this exact mechanism was reproduced live: a pre-existing typo, `BattleLogger.err(...)` (no such method exists on the `BattleLogger` autoload — only `.error()`/`.info()`/`.debug()`/`.trace()`) inside `_run_chunk()`'s defensive "invalid Guarnição" branch, had never been exercised inside a real `WorkerThreadPool` task before (the async path was disabled the entire time this typo existed), so it had never been caught. The first genuine live-async run in this session hit it and reproduced the full cascade exactly as predicted, confirming the mechanism end-to-end. Fixed by correcting both occurrences of `.err(` to `.error(` in `mining_efficiency_estimator.gd`.
- **Design changes approved and implemented:** the sampling target was redefined from "as many of the 362,880 raw permutations as reachable in ~100 hours" to a fixed **18,144 unique, valid battles across exactly 5 blocks** (`[3628, 3629, 3629, 3629, 3629]`, via the same integer-boundary technique already used elsewhere in the project — never a flat/hardcoded 3629×5). "Unique" is defined at the *effective combat formation* level (mirroring `CombatEngine._place_army()`'s War-Machine-to-Position-9 normalization — proven this session, by direct code trace, that `same canonical key ⇔ same effective formation`), never the raw permutation index — multiple raw permutations can collapse onto one board via the War Machine, and these are never double-counted. "Valid" excludes any formation with a Support at Position 5 (`COMBAT_RULES.md §6.5`). If a Reference Formation's true valid+unique population is smaller than 18,144 (verified this session with a constructed 5-Suporte + 1-Máquina-de-Guerra fixture: exactly 15,120 available, matching the hand-computed prediction precisely), the system simulates every one of them and stops — never fabricates repeats. The old 100-block/full-362,880-completion model (`TOTAL_BLOCKS`, `is_estimation_complete()`) was removed outright, not left as dead code — an exhaustive repo-wide usage trace confirmed every reference lived only inside the files being rewritten by this change, with no external dependents.
- **Critical thread-safety property preserved/strengthened:** all validity and uniqueness filtering for the Reference Formation now happens on the **main thread**, in a new `MiningCycleResolver._build_next_batch()`, strictly *before* any `WorkerThreadPool.add_task()` dispatch — never inside `_run_chunk()`, which executes concurrently across tasks with no safe shared mutable state. A key is registered into the per-Mine "seen formations" set only at the exact moment a candidate is confirmed both valid and not-yet-seen and has been committed to the batch that will actually be simulated — never for a candidate merely inspected and discarded (duplicate or invalid). `_run_chunk()` additionally keeps a defensive, redundant validity re-check for the Reference Formation (mirroring the pre-existing Guarnição-side guard) as a safety net, per explicit instruction not to trust a single layer of filtering when a worker-thread assert-crash is the failure mode at stake.
- **Also fixed, in the same scope:** `MiningProductionResolver.credit()` previously had no guard for `mina.cycle_efficiency < 0.0` (the "not yet calculated" sentinel) — `MineEconomy.hourly_production()` would silently compute a *negative* amount for that state, `credit()`'s `amount > 0` check would skip crediting, but `mark_production_credited()` still ran unconditionally, permanently losing that production window. Fixed with a minimal early-return guard that defers (never loses) that window until a real Efficiency exists.
- **Garrison-reuse mechanism added:** `Mina` now stores a signature of the Garrison an Efficiency was calculated for (Commander `instance_id` + `accumulated_xp`, and each of the 9 cards' `instance_id`/`tier`/`atk`/`hp`/`esc` in exact order — derived from tracing what `CombatEngine` actually reads, not assumed from `tier` alone). `minas_panel.gd`'s cycle-start path reuses the stored Efficiency without recalculating when the signature matches exactly, and correctly invalidates it on any relevant change (verified: a single card's Tier change, or the Commander's XP change, both correctly force recalculation).
- **Explicitly out of scope, not touched:** F-018 (formation-generator fixes for Support-at-Position-5), the separate "Support→Support→conventional overtake" movement-mechanic question, and `MiningPermutations`/`MineConquestResolver`/`CombatEngine` (per approved file scope).
- **Documentation scope note:** `DECISOES.md` explicitly excludes game mechanics/economy parameters from its own stated scope ("Este documento não registra regras, mecânicas ou parâmetros do jogo... Economia, moedas ou recursos") — discovered while attempting to add a decision record there as originally planned. No entry was added to avoid violating the document's own documented purpose; the full rationale instead lives here and in `MINES.md`.
- **Date:** 2026-08-18.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** Rewrote `_validate_mining_incremental_estimation()` (`bootstrap.gd`) covering: exact block distribution and 18,144 sum; shuffle/cursor uniqueness; War-Machine raw-permutation collapse producing one identical effective key; batch-level uniqueness (50/50 distinct keys, seen-set grows by exactly the batch size); Support-at-5 exclusion with an exact predicted count (322,560 of 362,880 for a 1-Suporte/no-machine fixture — matches `362880 × 8/9` exactly); the smaller-than-target universe case (exactly 15,120, matching the hand-computed prediction); Garrison-signature reuse and invalidation; the production-credit deferral-and-catch-up fix; save/load round-trip for pre-existing fields (new fields are not yet wired into `kingdom_save_service.gd`, out of approved scope — save/load itself has no production call site anywhere in the repo, confirmed by a repo-wide grep, so this is explicitly flagged rather than silently left broken); and the real live async flow end-to-end (dispatch, Garrison lock, exact block-1 completion count of 3628, no orphaned `WorkerThreadPool` tasks after termination) — all verified via a disposable diagnostic scene (deleted after use) before being wired into the permanent suite, per the project's established slow-full-suite workaround (F-001). Full run of the rewritten test: ~227 seconds (two ~362,880-iteration exhaustive scans plus two real ~3,628-battle live blocks) — a real, permanent addition to `bootstrap.tscn`'s already-slow total runtime, noted here for visibility.

### R-001 — PG resource identity conflict
- **Original problem:** "PG" was inconsistently named across documents — `Prestígio Global` in `COMMAND_CENTER_PROGRESS.md`, `PdG` in `ACADEMY.md` — and `XP.md` falsely claimed PG was exclusive to Minas/Depósitos, contradicting its real use by Command Center and Academy. No document owned the PG concept as SSoT.
- **Resolution:** Created `Arquitetura/GENERATION_POINTS.md` as the canonical SSoT for PG (single shared global resource, current consumers: Minas, Depósitos, Centro de Comando, Academia, extensible). Corrected "Prestígio Global"/"PdG" to "Pontos de Geração (PG)" everywhere they appeared. Centralized the Centro de Comando PG-cost formula into `FORMULAS.md`. Removed the false exclusivity claim from `XP.md`. Updated `PROJECT_INDEX.md`, `AUDITORIA_FINAL_v0.9.md` (resolution note appended, original finding preserved), and both `bs-audit`/`bs-economy` skills.
- **Date:** 2026-08-17.
- **Commit:** `a37f234` ("Finalize PG resource architecture").
- **Validation performed:** Repo-wide grep confirming no remaining "Prestígio Global"/"PdG" usage outside explanatory/historical text; manual verification that `FORMULAS.md`'s centralized formula matches the pre-existing `command_center_progress.gd::pg_cost_per_activation()` code exactly.

### R-002 — Deposits modeled as three independent buildings
- **Original problem:** `Arquitetura/DEPOSITS.md` presented Fundição/Câmara Arcana/Santuário Vital as three separate buildings with independent evolution tables, contradicting the actual code (one shared `deposito_level`) and the art bible (`Fundation/Depósitos.md`, which already described one unified complex).
- **Resolution:** Rewrote `DEPOSITS.md` to describe one Deposit system with one shared progression; merged the three duplicate tables into one; added the explicit rule that every Deposit evolution increases storage capacity for all three resources simultaneously.
- **Date:** 2026-08-17.
- **Commit:** `a37f234`.
- **Validation performed:** Cross-checked against existing code (`Deposits.storage_capacity()`, `kingdom.deposito_level`) which already implemented the unified model correctly — no code changes were needed, only documentation.

### R-003 — Army could be assigned to two active Expeditions simultaneously
- **Original problem:** No validation existed anywhere (UI or domain) preventing an Army already committed to an active, non-camping Expedition from being assigned to a second Expedition — the same Army object could end up referenced by two `Squad.armies` arrays at once.
- **Resolution:** `Kingdom.start_expedition()` now validates every Army in the incoming Squad via the existing `is_army_locked_for_editing()` predicate and rejects (returns `{"success": false, "reason": ...}`) if any is locked. `pve_panel.gd` routes expedition creation through this centralized entry point instead of mutating `active_expeditions` directly, and disables the "Usar no Squad" UI action for locked Armies. `GameRuntime.start_new_expedition()` (a second, previously-silent caller of `start_expedition()`) was updated to propagate the rejection instead of returning an unregistered `ExpeditionRuntime` as if it had succeeded, and to skip the Army-energy-reset side effect on rejection.
- **Date:** 2026-08-17.
- **Commit:** `0efaca0` ("Fix PvE expedition army locking and energy recovery").
- **Validation performed:** New regression coverage added to `bootstrap.gd` (`_validate_army_cannot_be_double_booked()`, extended to cover the `GameRuntime` layer) exercising the domain, `GameRuntime`, and UI layers directly. Verified via a fast disposable Godot scene (deleted after use) since the full `bootstrap.tscn` run is currently very slow in this environment — see F-001.

### R-004 — Energy recovered unconditionally, including during active Expedition marching
- **Original problem:** `GameRuntime.sync()` called `Army.sync_energy_recovery()` for every Army in the Kingdom unconditionally, including Armies actively marching in an Expedition (not at a Camp/City) — contradicting `ENERGY.md`'s "Locais de Recuperação" rule and letting players bypass Energy as PvE's core progression limiter for free.
- **Resolution:** `GameRuntime.sync()` now checks `is_army_locked_for_editing()` before calling `sync_energy_recovery()`; while locked, it advances `last_energy_sync_unix` without granting recovery points (preventing retroactive back-payment once unlocked). Recovery resumes normally once the Army returns to an allowed location.
- **Date:** 2026-08-17.
- **Commit:** `0efaca0`.
- **Validation performed:** New regression test `_validate_energy_frozen_while_marching()` confirms Energy stays frozen through 30 simulated days of active marching and resumes correctly after the Army "returns." Confirmed the pre-existing `_validate_energy_recovers_over_real_time()` test was not modified or weakened.

### R-005 — Stale PvE panel text claimed Expedition creation was unimplemented
- **Original problem:** `pve_panel.gd`'s header comment and its empty-state UI label both claimed that starting a new Expedition was out of scope and depended on an Army Editor screen that "doesn't exist yet" — while the same file already fully implemented that flow.
- **Resolution:** Updated both the header comment and the runtime-visible empty-state label to accurately describe the working flow.
- **Date:** 2026-08-17.
- **Commit:** `0efaca0`.
- **Validation performed:** Confirmed the described flow (Território selection → Army Editor overlay → Squad assembly → `Kingdom.start_expedition()`) is exercised end-to-end by `_validate_pve_panel_start_new_expedition()`.

### R-006 — `verify_card_catalog_sync.py` used a hardcoded, non-existent path
- **Original problem:** `CARD_CATALOG_PATH` was hardcoded to `/mnt/project/CARD_CATALOG.md`, which doesn't exist in this repository, making the verification script unusable.
- **Resolution:** Rewrote the path resolution using `pathlib`, deriving the repo root relative to the script's own location and pointing at `Arquitetura/CARD_CATALOG.md`; added a clear `FileNotFoundError` if the catalog still can't be found.
- **Date:** 2026-08-17.
- **Commit:** `acb6821` ("Fix card catalog sync path").
- **Validation performed:** Script re-run successfully, producing real output (`39/40`, `0` divergences) instead of failing.

### R-007 — `verify_card_catalog_sync.py` reported a phantom 40th card (F-006, reframed)
- **Original problem:** The verifier reported `39 / 40` — not because a real card was missing, but because its parser (`extract_canonical_tier3()`) mistook `CARD_CATALOG.md`'s own "Estrutura da Ficha" template/legend (the section at the top of the document listing field names like `Nome`, `Facção`, `Tier III` that every card sheet follows) for an actual card entry. The phantom entry was literally named `"Facção"` (confirmed by directly instrumenting the parser and diffing its output against the real `.tres` `card_name` values).
- **Clarification recorded for the historical record:** The current canonical playable card roster is **exactly 39 cards — 13 Império, 13 Natureza, 13 Mortos-Vivos** — confirmed by manually counting `Carta 01`–`13` in each of the three faction sections of `CARD_CATALOG.md`. This may grow in the future with new factions/cards, but 39 is correct today; no 40th card exists, was created, or should be inferred from this finding. Separately, `CARD_CATALOG.md` also documents **"Arqueiro Esquelético Reanimado"** as a sub-product of Muralha de Ossos's "Legião Infindável" ability — explicitly marked in the catalog as *"não é uma Carta jogável ou recrutável"*, with no Tier progression, no Soldo cost, and no catalog Rarity. It is a battlefield-only unit generated when Muralha de Ossos dies in battle, never a `CardResource`, never collectible/recruitable/craftable, and was confirmed (both by manual trace and by direct post-fix instrumentation) to **not** be the source of the phantom-40 count and **not** to be counted by the fixed parser. It was left completely untouched — no `CardResource` was created for it, its mechanic was not modified.
- **Resolution:** Fixed `Game/tools/verify_card_catalog_sync.py`'s `extract_canonical_tier3()` to ignore everything before the first real `"Carta N"` marker, so the legend section at the top of the document can never be scanned as if it were a card. Added a defensive regression check (`FICHA_LEGEND_FIELDS` + an assertion) that fails loudly if any parsed "card name" ever again matches one of the Ficha's own field labels, instead of silently counting a phantom entry. No changes were made to `CARD_CATALOG.md`, any `CardResource`, or any architecture document — this was purely a parser bug.
- **Date:** 2026-08-17.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** Re-ran the fixed script: `Cartas verificadas: 39 / 39`, `Divergências: 0`, exit code 0. Separately instrumented the parser to confirm: total parsed entries = 39; `"Facção"` no longer present as a key; `"Arqueiro Esquelético Reanimado"` not present as a key; the set of parsed catalog names is exactly equal to the set of `.tres` `card_name` values (no partial overlap, no stragglers on either side).

### R-008 — Stale code comments contradicted working implementations (F-008)
- **Original problem:** Two in-code comments described functionality as "not yet implemented" when it had since been fully implemented and tested elsewhere: (1) `kingdom.gd`'s `capital_level` comment claimed Capital's evolution cost parameters were "pendentes de calibração," though `InstitutionalConstructionResolver` and `BALANCING_SIMULATION.md`'s vigente Simulação 3 (`b=50`) already implement and calibrate it; (2) `command_center_resolver.gd`'s `retire()` comment claimed Legado bonus application "pertence a um resolver de Legado ainda não implementado," though `LegacyResolver.retire_administrative()` already fully implements Legado I–V and calls `retire()` as its low-level state-transition step.
- **Resolution:** Updated both comments to accurately describe the current implementation (Capital's evolution is implemented and calibrated; Legado bonus application belongs to the already-existing `LegacyResolver`, which reuses `retire()` rather than duplicating the state transition). No gameplay code or behavior was changed — comment-only fix.
- **Date:** 2026-08-17.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** Manual review confirming the updated comments match the verified implementations (`institutional_construction_resolver.gd`, `legacy_resolver.gd`); no code logic was touched in either file, only `##` comment lines. Note: while resolving this, a third, closely related stale comment was discovered immediately adjacent to the Capital one (`kingdom.gd`, `command_center_level` comment) — it was intentionally left unmodified, being outside this approved fix's exact scope, and was recorded as a separate finding, **F-015** (subsequently investigated and resolved — see **R-010** below).

### R-009 — PROJECT_STRUCTURE.md was corrupted and stale (F-007)
- **Original problem:** `Arquitetura/PROJECT_STRUCTURE.md` contained duplicated content (two full "Governança"/"Ordem de Leitura"/"Estrutura Atual" sections concatenated back-to-back), a leftover AI-response preamble sentence pasted mid-document, and references to roughly a dozen documents that don't exist in `Arquitetura/`, while omitting several real current documents.
- **Resolution:** Rewrote the document as a single clean structure (Objetivo, Responsabilidade, Filosofia, an accurate "Estrutura Oficial de `Arquitetura/`" organized into 9 conceptual groups covering every real file, a "Relação com as Demais Áreas do Repositório" section explicitly deferring to `PROJECT_INDEX.md` for cross-directory authority, Convenções, Princípios de Manutenção, Referências). No files were invented; no future/planned systems were added; the document was not turned into a second gameplay-rule SSoT.
- **Date:** 2026-08-17.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** Programmatically cross-checked every `` `*.md` `` filename referenced in the rewritten document against the real contents of `Arquitetura/` (51 files): zero referenced-but-nonexistent files (the only non-`Arquitetura/` reference is the intentional, correct cross-link to root-level `PROJECT_INDEX.md`); zero real files left unreferenced — full 1:1 coverage confirmed by set comparison, not just spot-checking.

### R-010 — Stale comment for Centro de Comando / Academia evolution cost (F-015)
- **Original problem:** `Game/engine/kingdom/kingdom.gd:198-201` (the comment attached to `command_center_level`) claimed Centro de Comando and Academia had "sem lógica de evolução própria ainda" (no evolution logic of their own yet) and that their cost parameters "seguem pendentes de calibração" (remain pending calibration) — the same class of staleness as the two comments already fixed under F-008, discovered immediately adjacent to the Capital comment while resolving that item, but left out of F-008's exact approved scope at the time.
- **Why it was incorrect:** A dedicated investigation (requested before implementation) confirmed the claim was fully false: `InstitutionalConstructionResolver.evolve()` already implements evolution for Centro de Comando and Academia through the same code path as Capital and Núcleo de Energia — enforcing the Capital-level ceiling, computing cost via the building's economic signature, spending resources tudo-ou-nada, and incrementing `kingdom.command_center_level`/`kingdom.academy_level` on success. Their `b`/`x` parameters are calibrated and vigente — `InstitutionalConstructionConfig` hardcodes Centro de Comando at `b=50, x=225` and Academia at `b=50, x=460`, mirroring `Arquitetura/BALANCING_SIMULATION.md`'s Simulação 3, explicitly boxed "✅ VALORES VIGENTES" and named as referenced by `FORMULAS.md`, `ACADEMY.md`, and `COMMAND_CENTER_PROGRESS.md`. The behavior is already covered by a passing regression test, `_validate_institutional_constructions()` in `bootstrap.gd`, which exercises both buildings' evolution (including Centro de Comando's Capital-level blocking and Academia's 70/30 cost split) alongside Capital and Núcleo de Energia.
- **Resolution:** Comment-only fix — replaced the stale claim with an accurate statement that evolution is implemented via `InstitutionalConstructionResolver`, with the vigente `b`/`x` values (Centro de Comando 50/225, Academia 50/460) from `BALANCING_SIMULATION.md` Simulação 3. No gameplay behavior changed; no executable code in `kingdom.gd` was touched.
- **Date:** 2026-08-17.
- **Commit:** *(uncommitted at time of writing — pending user approval to commit).*
- **Validation performed:** Manual review confirming the corrected comment no longer claims Centro de Comando/Academia evolution is unimplemented or pending calibration, and that only the `##` comment block changed (no adjacent executable code — including the `var command_center_level: int = 1` declaration itself — was modified).

---

## AUDIT NOTES

- This audit's scope was broad (28 requested areas across architecture, gameplay systems, tooling, and content). Time/effort was allocated toward areas with concrete, verifiable evidence; some areas (full Combat Engine ability-by-ability review, exhaustive art-pipeline completeness against the 700+ files under `Game/docs/production/ASSET_DATABASE/`, and a full per-panel UI audit) were spot-checked rather than exhaustively walked. Where evidence was incomplete, items were either omitted or explicitly marked lower-confidence above rather than asserted as confirmed bugs.
- `Arquitetura/AUDITORIA_FINAL_v0.9.md` is the project's existing point-in-time audit precedent. Its PG section (§4) is now resolved with an appended resolution note (see R-001); the rest of that document was not re-walked in full during this audit and may be worth a fresh pass under the "periodically re-audit" rule above.
- Several early false leads were caught and discarded during this audit before being written up as findings — notably, `Game/database/commander_generation/` initially appeared empty under a shallow directory listing but is fully populated one level deeper (`restrictions/`, `requirements/`, `targets/`, `effects/`, `values/` — 88 files total, matching the boot log exactly). This is recorded here as a reminder that directory-emptiness checks in this codebase need to go at least one level deep before being trusted.
- `Game/database/commanders_pool/` contains exactly one file (`marcus_valerius.tres`, the hand-authored starter Commander). This was *not* written up as a finding because Commanders are generated procedurally via `CommanderGenerator` rather than read from a stored pool, so a single hand-authored starter entry may be entirely correct — this needs owner/design confirmation of what `commanders_pool/` is intended to hold before it's treated as a gap either way.
- Uncommitted, unrelated art-asset churn (deletions/additions under `Assets/MVP/`) was visible in `git status` throughout this session. This is the user's own in-progress work, not a technical-backlog item, and was left untouched.
- `Game/docs/production/` contains an extensive, well-structured art/content production tracking system (per-ability, per-card, per-battlefield, per-building, per-animation Markdown specs with README indexes, ~700+ files). This appears to be a mature process, not a gap — flagged here only as an area a future audit pass should walk more deeply to confirm completeness against the actual card/ability/battlefield counts (39 cards, 64 abilities, 10 battlefields, 34 unit traits per the current database).
- **Canonical card roster clarification (recorded during F-006 resolution):** The current playable card roster is **exactly 39 cards (13 Império / 13 Natureza / 13 Mortos-Vivos)**. This number may grow in the future with new factions or additional cards, but 39 is correct today. **"Arqueiro Esquelético Reanimado"** (documented alongside Muralha de Ossos in `CARD_CATALOG.md`) is **not** a 40th playable card and must never be treated as one — it is a battlefield-only unit generated exclusively when Muralha de Ossos dies in battle (its "Legião Infindável" characteristic), cannot be created, recruited, crafted, or collected as a normal `CardResource`, has no catalog Rarity, no Tier progression, and no Soldo cost. See R-007 for the full investigation. If a future change to `CARD_CATALOG.md`, `verify_card_catalog_sync.py`, or the Muralha de Ossos mechanic is ever proposed, it must respect this distinction.

### Findings summary (at time of this audit)

| | P0 | P1 | P2 | P3 | Total |
|---|---|---|---|---|---|
| Open findings | 0 | 5 | 5 | 4 | 14 |

(P2 count still 5: F-019/F-020 resolved this session, but F-022 — Mine conquest has no UI entry point — was newly found and added, keeping the total the same. F-023 — PvP has no real combat system — is P4, tracked in the F-046/F-047 "Adiados" sections above, not in this P0-P3 table.)

By category: TOOLING GAP (2), INCOMPLETE IMPLEMENTATION (3), MISSING FEATURE (2, F-005 + F-022 new in F-047), DESIGN DECISION REQUIRED (3, overlapping with F-004/F-010/F-018 above), LOW PRIORITY/TECHNICAL DEBT (3), BLOCKED VALIDATION (1, F-018), COSMETIC (1, F-021, new in F-046, partially resolved in F-047).

Resolved 2026-08-17 session: 10 (R-001 through R-010). Resolved 2026-08-18 session: 3 more (R-011, R-012 — Support blocking-chain movement and War Machine mobility, F-016/F-017; R-013 — Mining Efficiency incremental background calculation, F-003). Resolved 2026-08-22 session (F-045/F-046/F-047): 8 more (R-014 — Mine Guarnição anti-exploit lock bug, P1; R-015 — 5 stale bootstrap.gd test checks; R-016 — Combat Visual minimal infrastructure built and validated; R-017 through R-020 — production UX fixes: debug button guard, raw JSON leak, misleading copy, missing action feedback; R-021 — Combat Visual integrated into the real PvE loop, F-019/F-020 fixed, F-021 partially fixed).

**Note on the P1 count above (5):** these are the same 5 items already open before this session (F-001, F-002, F-004, F-005, F-018) — none are new, and none block the current MVP per F-045/F-046's own "Estado atual" section above (P1 = 0 in the sense of "blocks the MVP right now"; these 5 are longer-standing tooling/design-decision items, not fresh regressions). The one genuinely NEW P1 found this session (R-014, Mine Guarnição) was fixed in the same session it was found, so it never accumulates here as "open."
