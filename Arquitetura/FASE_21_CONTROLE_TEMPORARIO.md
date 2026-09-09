# FASE 21 — Controle Temporário de Execução

> **Este documento NÃO é uma Fonte Única de Verdade.** É um checklist operacional
> temporário para acompanhar a sequência de trabalho até o MVP compartilhável.
> Regras, fórmulas, decisões definitivas e mudanças de arquitetura são
> registradas nos documentos permanentes em `Arquitetura/` — nunca aqui.
> Quando a Fase 21 terminar e o MVP for validado como compartilhável, este
> arquivo é apagado (ver seção final).

## Objetivo geral

Levar o projeto ao estado de **MVP COMPARTILHÁVEL**, a partir dos achados da
auditoria geral (FASE 21 — diagnóstico, sem implementação). O roteiro completo
com achados, causas e propostas está registrado na conversa da auditoria; aqui
fica só o controle de execução.

## Sequência de fases e dependências

```
21.1 Correções estruturais críticas (SEM dependências)
  ↓
21.2 Decisões de produto (bloqueiam 21.3/21.5/21.6)
  ↓
21.3 Balanceamento econômico (depende de 21.2.3)
  ↓
21.4 Refino do PvE (independente — pode rodar em paralelo a 21.3)
  ↓
21.5 Tutorial / Onboarding (depende de 21.2.1)
  ↓
21.6 PvP simulado (depende de 21.2.2)
  ↓
21.7 UI / Responsividade / Identidade visual
  ↓
21.8 Fechamento do MVP (depende de TODAS as anteriores)
```

## Status das etapas

| Etapa | Status | Achado de origem |
|---|---|---|
| 21.1.1 — Corrigir Formação desaparecendo ao editar | ✅ Concluída | `army_editor_panel.gd:214-222`, grade lia `_phase1_slots` (vazio) em vez de `_selected_cards`/`existing_army.cards` |
| 21.1.2 — Teste de regressão | ✅ Concluída | Suíte `army_editor_formation_flow` nunca exercitava `editing_composition=true` |
| 21.1.3 — Rodar regressão | ✅ Concluída | — |
| 21.2.1 — Decisão: escopo do tutorial | ✅ Concluída | Decisão do usuário: onboarding curto (9 prioridades), sistemas avançados via estado vazio/tooltip, não tutorial completo de 15 Etapas |
| 21.2.2 — Decisão: defensor do PvP simulado | ✅ Concluída | Decisão do usuário: IA procedural local, nunca outro Exército real; combate real via `CombatEngine` |
| 21.2.3 — Decisão: evolução de Minas Regionais | ✅ Concluída | Decisão do usuário: generalizar `MineEvolutionResolver`, reaproveitar UI existente de Minas |
| 21.3.1 — Implementar evolução de Minas Regionais | ✅ Concluída | `MineEvolutionResolver.evolve()` generalizado; UI de `minas_panel.gd` estendida às Regionais |
| 21.3.2 — Auditoria econômica completa (PG pool global) | ✅ Concluída | Simulação 4 em `BALANCING_SIMULATION.md`; recalibração numérica ainda pendente de decisão |
| 21.3.3 — Atualizar documentação divergente | ✅ Concluída | `DEPOSITS.md`, `CAMPO_DE_PROVA.md` corrigidos; PG-pool-global documentado (Simulação 4) |
| 21.4.1 — Energia visível durante a Expedição | ✅ Concluída | Dado real existe (`Army.current_energy/max_energy`), agora exibido no header via barra de fadiga (ENERGY.md, "Interface") |
| 21.4.2 — Estado de "Energia esgotada" comunicado | ✅ Concluída | Reaproveita `HUD_WARNING_COLOR`; texto "ESGOTADA" na própria legenda da barra — sem alterar o motor |
| 21.5 — Tutorial / Onboarding | ✅ Concluída | 6 dicas contextuais novas (Formação/Campo de Prova/Energia/Acampamento/Mina/Guarnição), independentes da sequência linear de 4 passos já existente |
| 21.6 — PvP simulado (combate real) | ✅ Concluída | `CombatEngine` real (`game_mode="pvp"`), defensor IA via `TestArmyFactory` espelhando Soldo/Patente do atacante |
| 21.7 — Polimento visual e UX do PvP | ✅ Concluída | `pvp_panel.gd` era o único painel de navegação fora do padrão HUD (auditoria FASE 21, cluster E) |
| 21.7.1 — Estilo visual do `pvp_panel.gd` | ⬜ Pendente | Único painel de navegação fora do padrão HUD (`Cinzel-SemiBold` + `StyleBoxFlat` dourado) |
| 21.7.2 — Legibilidade do Army Editor | ⬜ Pendente | Achado leve (fonte 8px em `army_editor_panel.gd:966`) |
| 21.7.3 — Legibilidade da Formação | ⬜ Pendente | Sem achado grave nas 4 resoluções (análise por código, não screenshot) |
| 21.7.4 — Validação visual do Campo de Prova | ⬜ Pendente | Nunca verificado por screenshot real |
| 21.7.5 — Validação visual de Exércitos | ⬜ Pendente | Nunca verificado por screenshot real |
| 21.7.6 — Auditoria de janelas internas (identidade única) | ⬜ Pendente | — |
| 21.7.7 — Tipografia | ⬜ Pendente | Sem achado grave; `Cinzel-SemiBold` já é universal exceto PvP |
| 21.8 — Fechamento do MVP | ⬜ Pendente | Depende de todas as anteriores |

## Critério de conclusão por etapa

- **21.1**: Formação existente aparece corretamente ao editar; nenhuma carta some; salvar/cancelar corretos; teste novo passando; regressão passando.
- **21.2**: cada decisão registrada nesta tabela com a opção escolhida e justificativa breve, antes de qualquer implementação dependente.
- **21.3**: evolução de Minas Regionais funcionando ponta a ponta (custo → PG → nível → produção → persistência → UI); simulação econômica refeita com pool de PG real; documentações corrigidas.
- **21.4**: Energia visível no header da Trilha sem duplicar estado; motivo de parada claro sem precisar de hover.
- **21.5**: escopo decidido implementado; jogador novo consegue completar o loop principal sem depender do desenvolvedor.
- **21.6**: "Simular Resultado" substituído por combate real via `CombatEngine`; Ranking/Divisão/Promoção continuam corretos; testes dedicados de PvP.
- **21.7**: todos os painéis de navegação seguem o mesmo padrão visual; Campo de Prova e Exércitos validados nas 4 resoluções (1152×648, 1366×768, 1600×900, 1920×1080).
- **21.8**: checklist completo da auditoria final (funcionalidade/UX/UI/economia/técnico) + sessão de uso real como jogador, do zero, registrando e corrigindo problemas encontrados.

## Observações sobre testes/validação

- Cada etapa que altera comportamento precisa de teste de regressão específico antes de ser marcada ✅, seguindo o padrão nativo do projeto (`TestRunner`/`ctx.check()`, sem GUT/gdUnit4).
- Novo `class_name` exige rebuild do cache (`godot --headless --editor --quit-after 1`) antes de rodar testes que o referenciem por nome.
- Antes de declarar o MVP compartilhável (21.8), é obrigatória uma sessão de uso manual real além dos testes automatizados passando.

---

## Registro de execução — 21.1

**21.1.1 — Correção aplicada:** `Game/scenes/army/army_editor_panel.gd`, dentro do
branch `if existing_army != null and editing_composition:` de `_ready()`,
adicionada a linha `_phase1_slots = existing_army.cards.duplicate()` logo após
`_selected_cards = existing_army.cards.duplicate()`. Nenhuma outra linha
alterada. Nenhuma regra de jogo, Formação, Soldo ou persistência tocada.

**21.1.2 — Teste criado:** `Game/tests/unit/test_army_editor_reopen_existing_composition.gd`
(3 casos): grade mostra a Formação real ao abrir (nunca vazia); trocar 2
posições via drag-and-drop real (`_handle_drop_on_slot`) preserva as outras 7;
salvar persiste em `army.cards`, cancelar não altera o Exército. Registrado em
`Game/tests/test_main.gd` como `army_editor_reopen_existing_composition`.

**21.1.3 — Regressão:** suíte completa do projeto (`test_main.tscn`, sem filtro,
94 suítes) — **3436 passou, 0 falhou, 0 erro(s) de execução**. Suíte nova
(`army_editor_reopen_existing_composition`, 13 asserções) e a suíte irmã
já existente (`army_editor_formation_flow`, 11 asserções) verificadas
isoladamente antes da rodada completa, ambas 100% ok.

**Status final da 21.1:** ✅ Concluída.

## Registro de execução — 21.2 (decisões de produto + auditoria técnica)

**Decisões aplicadas pelo usuário (diretriz de produto, não reabertas):**

1. **Tutorial:** onboarding curto cobrindo, em ordem de prioridade: Cidade/navegação → Exército → Formação → Campo de Batalha/Campo de Prova → PvE/Trilha → Energia → Acampamento → Minas Regionais → conceito básico de Guarnição/produção. Doutrina do Comandante, Academia, Depósitos e detalhes avançados de economia ficam de fora do tutorial obrigatório, mas precisam de estado vazio/tooltip/orientação contextual quando relevante. Implementação em **21.5**, ainda não iniciada.
2. **PvP simulado:** atacante = Exército/Plano real do jogador; defensor = IA procedural local (nunca outro Exército real de jogador); combate real via `CombatEngine` (nunca um segundo motor); resultado real alimenta `RankingResolver` já existente; eliminar os 3 botões falsos (Vitória/Derrota/Empate). Implementação em **21.6**, ainda não iniciada.
3. **Minas Regionais:** generalizar `MineEvolutionResolver` reaproveitando `MineEconomy.upgrade_cost_pg()`/`Kingdom.spend_generation_points()`/`Mina.increment_structure_level()`; reaproveitar a UI existente de Minas, sem tela nova. **Implementado em 21.3.1** (abaixo).

**Auditoria técnica realizada (confirma viabilidade, sem implementar 21.5/21.6 ainda):**

- **Tutorial:** mecanismo já existente (`Kingdom.tutorial_step` + `TutorialHintBanner`, `Game/scenes/tutorial/tutorial_hint_banner.gd`) é trivialmente extensível — cada tela já checa seu próprio passo e avança o contador ao clicar "Continuar" (padrão em `city_panel.gd`/`exercitos_panel.gd`/`pve_panel.gd`). Adicionar os passos de Formação/Campo de Prova/Energia/Acampamento/Minas/Guarnição é só mais `TUTORIAL_STEP_*` + mais uma chamada por tela, no mesmo padrão — nenhuma mudança de arquitetura necessária.
- **PvP:** `pvp_panel.gd` já tem, no ponto onde os 3 botões falsos vivem, tudo que uma chamada real precisa (Exército/Plano atacante, Battlefield sorteado via `PlanoCampanhaResolver.select_attack()`). `RankingResolver.apply_result(pl, division, role, result)` recebe primitivos — nenhuma mudança nele. `campo_de_prova_panel.gd` já mostra o padrão exato de chamada (`CombatEngine.initialize()`+`CombatReplayCollector`+`run()`) a reaproveitar. **Achado técnico a registrar para a 21.6:** o motor já tem um `game_mode = "pvp"` de primeira classe (usado por Doutrina do Comandante) — a implementação real DEVE passar `"pvp"`, nunca `"pve"` (Campo de Prova usa `"pve"` só por não existir um modo próprio para ele). **Decisão técnica menor ainda em aberto para a 21.6:** nem `EnemyArmyGenerator` (PvE) nem `ArmyRandomComposer` (Campo de Prova) têm um conceito de "Divisão" — o caminho mais simples é gerar o defensor com o mesmo teto de Soldo/Patente do próprio atacante (espelhamento), em vez de inventar uma tabela Divisão→Tier não documentada. Registrado como abordagem recomendada, a confirmar quando a 21.6 começar.
- **Minas Regionais:** `Mina.region` (1/2/3) e `MineEconomy.upgrade_cost_pg(region, level)`/`base_production_per_hour(region, level)` já eram genéricos — só `MineEvolutionResolver.evolve_initial_mine()` e a UI de "Evoluir" (`minas_panel.gd`) eram exclusivos da Mina Inicial. Nenhum teto de Nível existe para Minas Regionais em `MINES.md`/`FORMULAS.md` (só a Mina Inicial tem, Nível 4) — confirmado, não inventado.

**Nenhuma pendência fora de escopo encontrada nesta auditoria técnica.** Nenhuma dependência nova entre fases foi descoberta — a ordem 21.3 → 21.4 → 21.5 → 21.6 → 21.7 → 21.8 permanece válida.

**Status final da 21.2:** ✅ Concluída.

## Registro de execução — 21.3 (Economia e Balanceamento)

**21.3.1 — Evolução real das Minas Regionais (implementado):**
- `Game/engine/campaign/mine_economy.gd`: extraído `region_for_mina(mina)` (única tradução Mina→Region, antes duplicada inline) — `base_production_for_mina()` passou a usá-la.
- `Game/engine/campaign/mine_evolution_resolver.gd`: `evolve_initial_mine()` substituído por `evolve(kingdom, mina)`, genérico para Mina Inicial ou Regional. Teto de Nível 4 continua exclusivo da Mina Inicial (`MINES.md`); Regionais não têm teto (nenhum documentado).
- `Game/scenes/command_center/panels/minas_panel.gd`: `_build_evoluir_section()` generalizada (mostra Produção Atual, Próxima Produção, Custo em PG, e só mostra "máximo atingido" para a Mina Inicial) e agora também desenhada no card de Mina Regional (`_build_regional_card()`). `_on_evoluir_mina_pressed()`/`_evoluir_failure_message()` atualizados para o novo método.
- Testes: `test_mine_evolution_resolver.gd` reescrito (17 asserções — sucesso/falha da Mina Inicial preservados; nova cobertura de evolução Regional real, sem teto, custo por Região). `test_minas_panel_ui.gd` +3 testes (20/21/22, 12 asserções novas) cobrindo o botão "Evoluir" no card Regional. **Suíte completa do projeto: 3448 passou, 0 falhou, 0 erros** (era 3436 antes da 21.1; a diferença reflete as asserções novas de 21.1 e 21.3.1 somadas).
- Nenhuma fórmula nova, nenhuma segunda fonte de verdade, nenhuma tela nova.

**21.3.2/21.3.3 — Auditoria econômica + documentação (análise apresentada, nenhum valor numérico vigente alterado):**
- Nova seção "Simulação 4 — Correção do Pool Global de PG" em `Arquitetura/BALANCING_SIMULATION.md`: confirma que PG é um pool único do Reino (`GENERATION_POINTS.md`), não 1,3/dia por Trilha como a Simulação 2 assumia (limitação que o próprio documento já sinalizava). Apresenta 3 cenários (Conservador 3 Trilhas simultâneas, Médio 2, Acelerado 1 — igual à premissa antiga) e o impacto direto no payback das 4 Construções Institucionais: sob o cenário mais realista (Conservador), nenhuma delas atinge o Nível 15 dentro de uma Temporada de 180 dias (chega perto do dia 240, não 180).
- `Arquitetura/DEPOSITS.md`: tabela de capacidade corrigida para o valor real (`Deposits.storage_capacity()`, fator 3 geométrico níveis 1-7 + Progressão Aritmética 8+) — a antiga tabela fator-2 (24/48/96) movida para uma seção de registro histórico, nunca mais usada como referência de capacidade real.
- `Arquitetura/CAMPO_DE_PROVA.md`: seção "Estado de Implementação" corrigida — Modo Real/Modo Simulado, tela real, relatório e "Repetir esta Prova" (todos já implementados desde 2026-09-01) removidos da lista "apenas conceitual" e documentados como reais (seção B2 nova). Tensão documental sobre a Missão do Centro de Comando (já resolvida em `PROJECT_INDEX.md`) também atualizada.
- **DECISÃO DO USUÁRIO NECESSÁRIA (não aplicada):** a Simulação 4 apresenta 3 caminhos possíveis diante do payback ~2x mais lento sob o pool global real (aceitar o ritmo mais lento / recalibrar `x` das 4 Construções / revisar a divisão de PG entre Minas e Depósito) — nenhum foi escolhido. Nenhum valor de `b`/`x`/divisão de PG foi alterado nos documentos vigentes.

**Status da 21.3:** 21.3.1 ✅ concluída e testada. 21.3.2/21.3.3 ✅ concluídas como análise/documentação — a recalibração numérica das Construções Institucionais (se o usuário optar pela opção 2 da Simulação 4) fica como pendência futura, não uma sub-etapa em aberto desta fase.

## Registro de execução — 21.4 (Energia visível na Expedição)

**Auditoria antes da alteração:** fonte real confirmada — `expedition.squad.active_army().current_energy`/`.max_energy` (`Game/engine/army/army.gd`). `ENERGY.md`, seção "Interface", já documenta a regra exata a seguir: barra de fadiga sempre visível (`[██████░░░░]`), valor numérico "atual / máximo" só em *hover*. Nenhum componente de barra estilizada compartilhado existe no projeto, mas `treinamento_panel.gd::_make_progress_bar()` já usa o padrão real a reaproveitar (`ProgressBar` + `StyleBoxFlat` para fundo/preenchimento, cores do próprio HUD) — replicado aqui, não inventado.

**Arquivos modificados:**
- `Game/scenes/command_center/panels/pve_panel.gd`: nova linha "ENERGIA" no header do mapa (`_map_header_energy_caption` + `_map_header_energy_bar`), construída em `_build_map_static_structure()` e atualizada em toda passada de `_refresh_trilha_map()` via `_refresh_energy_row()` (nova função) — chamada em TODO refresh, então acompanha tick automático, vitória, derrota, retorno de Acampamento e carregamento de save automaticamente, sem nenhum gatilho adicional. Tooltip nativo (`tooltip_text`) mostra "atual / máximo" em hover, mesmo padrão já usado em `minas_panel.gd`. Cor muda para `HUD_WARNING_COLOR` (já existente, nenhuma cor nova) quando a Energia está esgotada ou abaixo de 20%; legenda identifica Exército/Comandante ativo e acrescenta "ESGOTADA, aguardando decisão no Acampamento" quando `current_energy <= 0` — nenhuma regra nova, só torna visível o que `PhaseResult.DefeatReason.ENERGY_EXHAUSTED` (F-020.2) já registra.
- `Game/tests/test_main.gd`: registro da suíte nova.

**Achado real durante os testes (corrigido):** `Squad.active_army()` retorna `null` num estado transitório real — logo após uma derrota que esgota o Squad inteiro, antes da próxima tentativa reiniciá-lo (mesmo comportamento documentado em `attempt_current_fase()`). Sem tratamento, a barra desaparecia exatamente no momento em que precisava ficar mais clara. Corrigido com um fallback que mostra o último Exército real do Squad nesse estado — nunca um valor inventado, só uma escolha de qual dado real exibir.

**Testes:** `Game/tests/unit/test_pve_panel_energy_header.gd` (novo, 10 asserções): energia correta ao carregar; atualização real após tentativa; estado esgotado; idempotência de refresh(); e o teste mais importante — mutação externa direta em `army.current_energy` (sem nenhum setter do painel) aparece no próximo `refresh()`, provando que não há estado duplicado. **Suíte completa do projeto: 3458 passou, 0 falhou, 0 erros** (era 3448 antes da 21.4).

**Validação visual real:** capturado screenshot (ambiente com GPU real) nas 4 resoluções pedidas (1152×648, 1366×768, 1600×900, 1920×1080), com Energia propositalmente baixa (18%) para verificar a cor de aviso. Confirmado nas 4: a linha de Energia nunca sobrepõe título/setas/status da Fase, o texto não quebra de forma estranha, a barra mostra a cor de aviso corretamente. Scripts de screenshot descartados após uso (nenhum arquivo `_*` residual).

**Não alterado:** custo/recuperação/máximo de Energia, regras de combate, ritmo da Expedição, geração de inimigos, recompensas, Minas, PG, Construções Institucionais, Trilha.

**Status final da 21.4:** ✅ Concluída.

## Registro de execução — 21.5 (Tutorial / Onboarding)

**Decisão aplicada (21.2.1):** onboarding curto — a sequência linear de 4 passos já existente (Cidade → Exército → PvE → Pós-Combate) permanece intocada. Em vez de transformá-la numa sequência longa de 9+ passos obrigatórios, os 6 sistemas restantes da lista de prioridade (Formação, Campo de Batalha/Campo de Prova, Energia, Acampamento, Minas Regionais, Guarnição/produção) ganharam **dicas contextuais independentes** — cada uma dispara sozinha na primeira vez que o jogador realmente encontra aquele sistema, nunca bloqueia navegação, nunca reaparece depois de dispensada (progress_flag própria, nunca a `tutorial_step` linear).

**Arquivos modificados:**
- `Game/scenes/city/panels/exercitos_panel.gd`: dica de Formação, disparada em `_build_detail_pane()` na primeira vez que a grade real de um Exército é exibida — só depois que o Passo 2 linear ("Seu Exército") já não está mais pendente, evitando duas dicas competindo pelo mesmo espaço.
- `Game/scenes/command_center/panels/campo_de_prova_panel.gd`: dica na primeira abertura da tela (`_ready()`).
- `Game/scenes/command_center/panels/pve_panel.gd`: dica de Energia na primeira vez que o mapa de uma Expedição real é visto (`_on_view_expedition_pressed()`); dicas de Acampamento e Mina Regional inseridas DENTRO dos respectivos overlays modais via um novo helper compartilhado `_build_inline_hint()` (bloco simples reaproveitando `_card_style()`/`_style_plain()`/`_style_button()` já existentes — não a moldura ornamentada de `TutorialHintBanner`, que colidia visualmente com a janela centralizada desses overlays em telas baixas, achado real confirmado por screenshot e corrigido nesta mesma etapa).
- `Game/scenes/command_center/panels/minas_panel.gd`: dica de Guarnição em `_refresh_regionais()`, disparada quando existe pelo menos uma Mina Regional conquistada ainda sem Guarnição designada.
- `Game/tests/test_main.gd`: registro da suíte nova.

**Testes:** `Game/tests/unit/test_tutorial_contextual_hints.gd` (novo, 17 asserções) — cada uma das 6 dicas: aparece na primeira ocorrência real, marca sua própria progress_flag ao ser dispensada, nunca reaparece depois. **Suíte completa do projeto: 3475 passou, 0 falhou, 0 erros** (era 3458 antes da 21.5) — inclui reconfirmação de `test_tutorial_flow.gd` (22/22, sequência linear original intacta) e `test_minas_panel_ui.gd` (45/45).

**Validação visual real:** screenshots nas resoluções relevantes confirmaram um problema real (moldura ornamentada sobrepondo a janela do Acampamento/Mina em 1152×648) e a correção aplicada (bloco simples embutido no próprio modal, sem sobreposição).

**Não alterado:** a sequência linear de 4 passos, regras de combate, economia, Minas, PG, Trilha.

**Status final da 21.5:** ✅ Concluída.

## Checkpoint de versionamento — Fases 21.1–21.5 (2026-09-08)

- **Commit:** `41c0c2b6b584ef152df5fef642580f2419d4b164`
- **Branch:** `main`
- **Push:** enviado a `origin/main` (GitHub) — `84cc6e4..41c0c2b main -> main`, confirmado (`git status -sb` mostra `main...origin/main` sem "ahead"/"behind" após o push).
- **Validação antes do commit:** suíte completa do projeto — **3475 passou, 0 falhou, 0 erros**.
- **Escopo do commit:** decisão explícita do usuário foi commitar TODO o trabalho pendente do repositório (402 caminhos antes do commit), não só o que pertence estritamente às Fases 21.1–21.5 — o último commit anterior (`84cc6e4`, TUT-001) era de mais de 2 semanas atrás, e havia trabalho acumulado de várias sessões (integração de arte, novos painéis da Cidade, etc.) misturado no working tree sem checkpoints intermediários. Excluídos deliberadamente por serem artefatos transitórios, não conteúdo real (mantidos como untracked): `.scratch4/` (screenshots de depuração), `crop_data.json` (22 bytes, arquivo truncado), `scratch_history_bottom.png`/`scratch_history_top.png`, `CLAUDE.md.bak`, `Game/tools/tmp_check_*.gd.uid` (órfãos, sem `.gd` correspondente), e o lock-file do Excel `~$LBS-BS_MATRIZ_TRADUCAO_VARIACOES_V1.xlsx`. Um arquivo `.xlsx` real (`LBS-BS_CATALOGO_INIMIGOS_GOBLINS_GOLEMS.xlsx`) apareceu como untracked após o commit — não estava capturado na varredura antes do `git add`, ficou de fora deste checkpoint; o usuário pode commitá-lo separadamente quando confirmar que não está mais sendo editado.
- **Fases incluídas neste checkpoint:** 21.1 (bug de Formação), 21.2 (decisões de produto), 21.3 (evolução de Minas Regionais + auditoria econômica + docs), 21.4 (barra de Energia), 21.5 (dicas contextuais de onboarding) — mais todo o trabalho de sessões anteriores a esta conversa (F-020.x de PvE/Trilha, ART-002 a ART-005, TUT-001, integração de novos painéis da Cidade) que também nunca tinha sido commitado.

## Registro de execução — 21.6 (PvP Simulado com Combate Real + IA local)

**Auditoria antes da implementação:** confirmado que `PlanoCampanhaResolver.select_attack()` já resolve Exército atacante + Campo de Batalha restrito por Energia (`ATTACK_ENERGY_COST=10`, igual ao custo documentado em `ENERGY.md`); `RankingResolver.apply_result()` já trata Empate corretamente (delta 0 de PL, nenhuma regra nova necessária); `campo_de_prova_panel.gd::_run_prova()` é o padrão exato de chamada a `CombatEngine`+`CombatReplayCollector`+`CombatReplayView` a reaproveitar; `TestArmyFactory.generate_random_army(patente)` (já usada pelo Campo de Prova) gera Comandante procedural + 9 Cartas reais do catálogo completo + Formação δ, parametrizado exatamente pelo teto de Soldo/Patente — zero código novo necessário para gerar o defensor.

**LACUNA REGISTRADA (decisão do usuário, não inventada):** `ENERGY.md` ("Consumo de Energia — PvP") documenta que uma partida de PvP é uma "série Melhor de 5", com custo de Energia fixo "independente da quantidade de partidas efetivamente disputadas". Porém `RANKING.md`/`MATCHMAKING.md` (donos reais da regra de PvP) nunca definem como essa série de 5 partidas funciona — mesma Formação a cada partida? o que decide um 2-2? Implementar isso exigiria inventar regras que não existem em documento algum. **Decisão do usuário:** implementar 1 batalha real por partida por enquanto (o custo fixo de 10 Energia já é compatível com N=1); a série de 5 completa fica registrada aqui como pendência de design futura, não implementada.

**Arquitetura adotada (item 18, preparada para o futuro):** `_generate_ai_defender(attacker)` é o único ponto que decide a origem do defensor — retorna um `Army` comum, sem nenhum acoplamento a `CombatEngine` (que só recebe dois `Army` válidos, como sempre). Trocar por um defensor de servidor no futuro significa reescrever só essa função, nunca o motor de combate.

**Arquivos modificados:**
- `Game/scenes/command_center/panels/pvp_panel.gd`: removidos os 3 botões "Simular Resultado" (Bronze e Plano) e seus handlers (`_on_simulate_bronze_result_pressed`/`_on_simulate_plano_result_pressed`). Adicionados: `_generate_ai_defender()`, `_resolve_pvp_combat()` (núcleo síncrono e testável: gera defensor, roda `CombatEngine.initialize()+run()` com `game_mode="pvp"`, anexa `CombatReplayCollector`, consome a Energia real fixa, deriva o resultado real de `state.winner_side`), `_run_pvp_battle()` (chama o núcleo + mostra `CombatReplayView` real + relatório), `_apply_bronze_ranking_result()`/`_apply_plano_ranking_result()` (extraídos como métodos nomeados — nunca duplicam `RankingResolver.apply_result()`), `_build_battle_result_overlay()` (relatório mínimo: vencedor, os dois Exércitos/Comandantes reais, Campo de Batalha, turnos — nunca "Player Army"/"Enemy Army"/placeholder). Bronze usa "Batalhar" gated por Energia real; Plano ganhou um botão "Batalhar" que só aparece após um sorteio bem-sucedido, usando exatamente o Exército/Campo já sorteados (nunca sorteados de novo). Texto de escopo do topo da tela corrigido (citava os botões "Simular Resultado" removidos).
- `Game/tests/test_main.gd`: registro da suíte nova.

**Testes:** `Game/tests/unit/test_pvp_battle.gd` (novo, 19 asserções, itens A-H do pedido): combate real (turnos > 0, finalizado, Energia consumida no custo exato); `game_mode == "pvp"`; defensor válido e completo; Formação do defensor com 9 posições reais e sem repetição; resultado do Ranking deriva exatamente de `state.winner_side`; `_apply_bronze_ranking_result()`/`_apply_plano_ranking_result()` produzem exatamente o que `RankingResolver.apply_result()` produziria; `CombatReplayCollector` real captura tabuleiro inicial e eventos; os handlers antigos de resultado artificial não existem mais. Mesmo padrão de `test_campo_de_prova_lifecycle_and_editing.gd`: a fase de replay (assíncrona, depende de frames reais) não é exercitada — só o núcleo síncrono e determinístico, que é onde toda a lógica real mora. **Suíte completa do projeto: 3494 passou, 0 falhou, 0 erros** (era 3475 antes da 21.6).

**Validação visual real:** screenshot do Bronze mostrando "Batalhar (Custo: 10 Energia)" substituindo os 3 botões antigos; screenshot do relatório pós-batalha mostrando nomes reais (Comandante do jogador, Comandante da IA gerado, Campo de Batalha, turnos). **Achado real corrigido:** o título do relatório ("Derrota — Comandante de Teste (Mortos-Vivos) venceu") vazava pra fora da janela sem quebra de linha — corrigido com `autowrap_mode` (mesmo padrão já usado no resto do relatório).

**Não alterado:** regras de combate/dano/atributos/Formação, Economia, Energia (só consumida, nunca a fórmula), Minas, PvE, Trilha, fórmulas de `RankingResolver`, `PlanoCampanhaResolver` (reaproveitado como estava). Nenhum matchmaking online, nenhum servidor.

**Status final da 21.6:** ✅ Concluída.

## Registro de execução — 21.7 (Polimento Visual e UX do PvP)

**Auditoria antes de alterar:** comparado `pvp_panel.gd` com `exercitos_panel.gd` (fonte real dos helpers portados: `_make_label`/`_make_centered_label`/`_make_separator`/`_make_stat_chip`/`_style_office_button`/`_make_primary_button`/`_make_small_button`/`_style_scrollbar`) e `pve_panel.gd` (fonte real de `_card_style()`/`_modal_style()` e do padrão de barra de Energia). Confirmado: nenhum padrão novo foi inventado — os mesmos `HUD_FONT`/`HUD_ACCENT`/`HUD_ACCENT_SELECTED`/`HUD_TEXT_COLOR`/`HUD_MUTED_COLOR` (mesmos valores exatos) e os mesmos componentes StyleBoxFlat já usados em Exércitos/Comandantes/Campo de Prova/PvE/Minas foram duplicados localmente aqui (convenção já estabelecida no projeto: nenhuma classe de estilo compartilhada existe).

**Arquivos modificados:**
- `Game/scenes/command_center/panels/pvp_panel.gd`: reescrita visual completa, mesma lógica/wiring de sinais preservados 1:1. Cada Exército na Liga Bronze e cada Plano de Campanha agora é um card com moldura dourada (`_card_style()`); Divisão/Pontos de Liga/Liga viram blocos visuais (`_make_stat_chip()`) em vez de uma linha de texto corrida; a barra de Energia real (ENERGY.md, "Interface") aparece em cada card Bronze, com cor de aviso quando insuficiente para o custo da batalha; "Batalhar"/"Inscrever"/"Criar Plano" usam o tratamento de botão principal (`_make_primary_button()`, borda dourada clara); ações secundárias ("Sortear", setas de Ordem de Ataque) usam `_make_small_button()`; seções (Bronze/Planos/Defesa/Ordem de Ataque/Campos Especiais) ganharam títulos e separadores dourados consistentes. O relatório pós-batalha (`_build_battle_result_overlay()`) virou uma janela modal opaca (`_modal_style()`, mesmo padrão dos overlays de Acampamento/Mina em `pve_panel.gd`) com título colorido por resultado (verde/vermelho/dourado) e uma seção nova "IMPACTO NO RANKING" (PL antes -> depois, com sinal, e Divisão, incluindo promoção/rebaixamento quando aplicável) — item 7 do pedido, que a 21.6 ainda não cobria. Texto de escopo do topo revisado de novo (nunca ficou referenciando um componente removido).
- `Game/tests/unit/test_pvp_battle.gd`: `_apply_bronze_ranking_result()`/`_apply_plano_ranking_result()` passaram a retornar `{pl_before, pl_after, division_before, division_after, promoted, demoted}` (antes `void`) — usado pelo novo relatório; teste F estendido com 2 asserções confirmando que o retorno reflete o antes/depois real.
- `Game/tests/test_main.gd`: nenhuma mudança nesta etapa (nenhuma suíte nova — só comportamento verificável já coberto por F foi estendido, conforme item 11 do pedido: "não criar testes artificiais de aparência").

**Arquivos não tocados:** `CombatEngine`, `PhaseResolver`, `EnemyArmyGenerator`, `ArmyRandomComposer`, `RankingResolver`, `PlanoCampanhaResolver`, `TestArmyFactory`, regras de Energia/Divisão/Pontos de Liga/matchmaking/geração do defensor/Formação/combate/persistência — nenhuma regra tocada, só apresentação.

**Testes:** suíte `pvp_battle` re-executada (21 asserções, 2 novas desta etapa) + `ranking_and_battlefield_selector` + **suíte completa do projeto: 3496 passou, 0 falhou, 0 erros** (era 3494 antes da 21.7).

**Validação visual real (as 4 resoluções pedidas):** capturados screenshots reais (ambiente com GPU) da tela principal (Bronze inscrito/não-inscrito, Plano com Liga/Divisão/PL, seção "Criar Plano", Defesa/Ordem de Ataque) em 1152×648, 1366×768, 1600×900 e 1920×1080, e do relatório pós-batalha (Vitória e Derrota) em 1152×648 e 1920×1080. Nenhum texto cortado, nenhum botão fora da tela, nenhuma sobreposição, nenhuma barra de Energia deformada, relatório sempre dentro dos limites da janela em todas as resoluções testadas.

**Problemas encontrados e corrigidos nesta etapa:** nenhum problema visual novo restante — os dois achados reais de responsividade (texto do relatório vazando sem quebra de linha) já tinham sido corrigidos durante a própria 21.6, antes deste passe de identidade visual.

**Pendência conhecida (não corrigida, fora de escopo):** o `OptionButton` nativo do Godot (Defesa Preferencial, Mapeamento dos Campos Especiais) recebeu apenas fonte/cor/StyleBox do estado "normal" — o menu suspenso (popup) continua com a aparência padrão do Godot, já que restilizar totalmente um `OptionButton` exige um `Theme` dedicado, não só overrides pontuais. Não é um controle usado com frequência (configuração do Plano, não a ação principal) — registrado aqui para uma eventual passada futura, não urgente.

**Status final da 21.7:** ✅ Concluída.

## Checklist de saída do MVP compartilhável

- [x] 21.1 — Bug da Formação corrigido e testado
- [x] 21.2 — Todas as decisões de produto registradas
- [x] 21.3 — Economia balanceada e documentação sincronizada (recalibração numérica opcional, pendente de decisão do usuário — ver Simulação 4)
- [x] 21.4 — PvE com feedback de Energia claro
- [x] 21.5 — Tutorial cobrindo o escopo decidido (6 dicas contextuais + sequência linear original)
- [x] 21.6 — PvP simulado com combate real (série "Melhor de 5" registrada como pendência futura — 1 batalha por partida no MVP)
- [x] 21.7 — pvp_panel.gd segue a identidade visual do jogo, validado nas 4 resoluções
- [ ] 21.8 — Auditoria final + sessão de uso real sem problemas bloqueadores

## Encerramento (só ao concluir TODAS as etapas)

1. Confirmar que toda informação permanente (decisões, fórmulas, regras, UI)
   foi transferida para os documentos de `Arquitetura/` pertinentes.
2. Última verificação: nada importante ficou só neste arquivo.
3. Apagar `Arquitetura/FASE_21_CONTROLE_TEMPORARIO.md`.
4. Manter apenas os registros permanentes nos documentos corretos.
