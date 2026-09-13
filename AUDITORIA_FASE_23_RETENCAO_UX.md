# AUDITORIA FASE 23 — Retenção / UX / Balanceamento / Feel

> **Documento TEMPORÁRIO de controle desta etapa de auditoria.**
> Não é uma SSoT de arquitetura (essas continuam em `Arquitetura/`) nem substitui `TECHNICAL_BACKLOG.md` (o backlog técnico permanente). Este arquivo deve ser removido/arquivado quando a Fase 23 for encerrada — o que sobreviver como decisão de arquitetura deve ser migrado para o `Arquitetura/` correspondente; o que sobreviver como item técnico recorrente deve ser migrado para `TECHNICAL_BACKLOG.md`.
>
> Critério de execução desta fase: **primeiro pouco esforço + grande impacto, depois itens maiores.** Nenhuma implementação foi feita ainda além do que já existia (ver Bloco 0). Nenhum commit/push foi feito nesta etapa.

---

## BLOCO 0 — Trabalho já existente, não commitado (descoberto durante a auditoria)

Antes de diagnosticar os 13 itens do zero, a auditoria encontrou mudanças reais **não commitadas** de uma sessão anterior, já testadas pela suíte completa (3601 passou / 0 falhou), que resolvem uma fatia real do item #1 e infraestrutura do item #6. Recomendação: revisar e commitar isso **primeiro**, antes de qualquer item novo — é impacto já pago, custo zero adicional.

| ID | O que é | Resolve | Status |
|---|---|---|---|
| WIP-1 | `expedition_tick_resolver.gd` — corrige catch-up: antes só 1 tentativa automática por sync() mesmo após horas fechado; agora processa em loop de 60s por tentativa (com salvaguarda de 10000 tentativas/sync) | #1 (progressão/offline) | Pronto, testado |
| WIP-2 | `mine_economy.gd` + `MINES.md` + `FORMULAS.md` — Mina Inicial: produção base 1→5/hora (progressão 5/10/20/40, era 1/2/4/8) | #1 (progressão inicial) | Pronto, testado, docs sincronizados |
| WIP-3 | `command_center_panel.gd` — Glow nos 5 hotspots do CdC (nenhum tinha); **bug real corrigido**: evolução vertical do CdC ("Evoluir") era inacessível por qualquer fluxo real de jogador — chip novo adicionado, reusa `InstitutionalConstructionResolver` | #1 (progressão — building morto) | Pronto, testado (`test_command_center_glow_evolution_tutorial.gd`) |
| WIP-4 | `comandantes_panel.gd` — **bug real corrigido**: botão de "Ativar Próximo Recurso Administrativo" (`CommandCenterResolver.activate_next()`) tinha sido removido da UI, travando a Expansão Administrativa além do Nível 1 grátis; restaurado. Também constrói o 1º tutorial real com `TutorialSpotlight` (Ativo × Reserva) | #1 (progressão) + infra de #6 | Pronto, testado |
| WIP-5 | `Game/scenes/tutorial/tutorial_spotlight.gd` + `tutorial_spotlight_ring.gd` (novos) — componente genérico e reutilizável de tutorial contextual (dimming + spotlight real sobre um Control + texto), usado pelo WIP-4 | Infra para #6 | Pronto, validado em uso real |
| WIP-6 | `academia_producao_panel.gd` — 4 correções: anel de seleção de filtro desalinhado; texto de preview truncando no meio da palavra; custo de fragmento simplificado; **bug real corrigido**: nomes das cartas na fila de produção nunca apareciam (bug de `ScrollContainer` não esticando o filho) — fila agora mostra nome + contagem MM:SS ao vivo | Adjacente a #1 (fila de produção invisível = "não tenho o que fazer") | Pronto; sem teste de regressão dedicado para o bug de renderização — recomendo 1 teste antes do commit |
| WIP-7 | `bestiario_panel.gd` + `army_editor_panel.gd` — Energia/Soldo agora visível no Bestiário (antes só no Army Editor); Army Editor: cartão de Formação redimensionado (bug real: rodapé de Energia/Soldo cortado em 1152×648) + fonte maior | Adjacente a #5 | Pronto, testado |
| WIP-8 | `Game/tools/debug/*` (14 arquivos), `.scratch4/`, `crop_data.json`, `scratch_history_*.png`, `CLAUDE.md.bak` | Ferramentas de investigação descartáveis da sessão anterior | **Não commitar** — excluir ou deixar fora do controle de versão |

**Ação recomendada para o Bloco 0:** revisar diffs, adicionar 1 teste de regressão para WIP-6 (fila de produção), e commitar como um ou dois commits coerentes — SEM os arquivos do WIP-8. Isso não é um item novo de trabalho, é destravar valor já produzido.

---

## BACKLOG PRIORIZADO (ITENS 1–13 + NOVOS)

Ordenado por Bloco de execução recomendado (dentro de cada bloco, ordem sugerida de execução).

### BLOCO 1 — Pouco esforço, grande impacto (fazer primeiro, depois do Bloco 0)

| ID | Item | Impacto | Esforço | Depende de |
|---|---|---|---|---|
| F23-04 | Recuperação de Energia real no Acampamento (não 100% instantâneo) | Alto | Baixo | — |
| F23-03 | UI de escolha de política de Acampamento (Continuar/Parar) ANTES da chegada | Alto | Baixo–Médio | F23-04 (mesmo fluxo/arquivos) |
| F23-05 | Mostrar Tier Máximo do Pelotão (Army Editor + Bestiário) | Médio–Alto | Baixo | — |
| F23-08 | Legibilidade de Kingdom Inventory / Crystal Vault (hierarquia tipográfica) | Médio | Baixo–Médio | — |
| F23-12a | Juice barato: hit-flash/scale-punch/shake em ataque e morte | Médio | Baixo | — |
| F23-14 | Corrigir `SeasonPipeline` região hardcoded (bug real, não afeta catálogo ativo hoje) | Baixo hoje / Alto se a ferramenta for usada para o catálogo real | Baixo | — |

### BLOCO 2 — Esforço médio

| ID | Item | Impacto | Esforço | Depende de |
|---|---|---|---|---|
| F23-06 | Conteúdo real do tutorial "Patentes e Tiers" (Etapa 12 de `TUTORIAL.md`, já especificada, nunca implementada) | Alto (retenção/clareza) | Médio | F23-05 (o spotlight deveria apontar para o indicador de Tier Máximo) |
| F23-02 | Rever batalha PvE já finalizada (não só ao vivo) | Médio–Alto | Médio | Decisão de design: estratégia de persistência (log completo vs. re-simulação — combate não é 100% determinístico, ver Silêncio) |
| F23-07 | Tela "PvE — Escolha sua Expedição": auditoria visual confirmada como placeholder na tela de Seleção (fundo chapado, slot "placeholder" literal no código) | Alto (1ª impressão do loop PvE) | Médio | Precisa de 1 asset de fundo ilustrado (bs-visual) |
| F23-09b | Investigar liveness/corrigir dados se o catálogo real (30k) já tiver sido gerado com o bug F23-14 | Alto (se aplicável) | Médio | F23-14 |
| F23-01b | Diagnóstico de "atividades significativas" além dos bugs já corrigidos no Bloco 0 (ver seção própria abaixo) | Alto | Médio | Depende de decisão do dono sobre quais dos 3 vetores (Academia, CdC, Comandantes) priorizar em conteúdo novo |

### BLOCO 3 — Esforço alto / requer decisão de design ou produção de assets

| ID | Item | Impacto | Esforço | Depende de |
|---|---|---|---|---|
| F23-10 | Som nas ações de batalha | Médio–Alto | Alto (gargalo é asset de áudio, não engenharia) | Produção/curadoria de assets sonoros |
| F23-15 | Decisão: aplicar teto de Tier por Patente no Exército do JOGADOR (hoje só é aplicado ao inimigo PvE) | Alto se aprovado | Alto (pode invalidar Exércitos existentes acima do teto) | Decisão explícita do dono do projeto |
| F23-09 | Auditoria de balanceamento PvE completa (além do bug F23-14): dificuldade plana dentro de uma Região é decisão de design, não bug | Médio | Alto | F23-14, F23-09b |
| F23-13 | Pesquisa de jogos semelhantes (ver seção própria) | Informativo | Alto (pesquisa, não código) | — |

### JÁ RECLASSIFICADO (não é mais "a fazer" como pedido originalmente)

| ID | Item original | Nova classificação |
|---|---|---|
| #11 | Movimentação dos pelotões | **Já implementado** (movimento, ataque, cura, morte, projéteis — tudo já animado via `CombatReplayView`/`BattleUnitArtLayer`, testado). Dobrado no F23-12a como polimento incremental, não construção do zero. |

---

## DIAGNÓSTICO DETALHADO POR ITEM

### F23-01 — Progressão inicial lenta
**Diagnóstico:** o problema não era (só) velocidade de fórmula — eram **bugs reais de acesso**: evolução do Centro de Comando inacessível por qualquer botão real (WIP-3), Expansão Administrativa travada por um botão removido (WIP-4), fila de produção da Academia invisível por um bug de layout (WIP-6), e progressão offline que só processava 1 ciclo por sessão em vez do tempo real decorrido (WIP-1), além da Mina Inicial produzindo 5× menos do que o documentado originalmente pretendia (WIP-2). **Boa notícia:** isso já está corrigido e testado, só não commitado. **O que ainda falta diagnosticar** (não resolvido pelo Bloco 0): se, mesmo com esses bugs corrigidos, ainda existem "períodos mortos" reais nos primeiros minutos — isso só pode ser avaliado jogando a build corrigida (Bloco 0 commitado) do zero. Recomendo tratar isso como validação pós-Bloco-0, não um novo item de código.
**Arquivos:** ver Bloco 0.
**Critério de aceite:** após commit do Bloco 0, um playtest de "primeiros 15 minutos" não deve encontrar nenhum sistema P0 (CdC, Comandantes, Academia) sem ponto de entrada funcional.

### F23-02 — Replay de batalha PvE
**Diagnóstico:** infraestrutura (`CombatReplayCollector`/`CombatReplayView`) já existe e roda ao vivo durante a tentativa (`pve_panel.gd`). O que falta é **persistência**: `battle_replays` é descartado após a exibição; só sobrevive um resumo textual em `fase_history`. Reaproveitar o sistema é viável, mas **decisão de design necessária antes de implementar**: persistir o log completo por Fase (custo de armazenamento) vs. re-simular a partir da Formação salva (risco: pelo menos 1 habilidade — Silêncio — usa RNG não seedado, então re-simular pode não reproduzir a mesma batalha).
**Arquivos:** `Game/engine/combat/combat_replay_collector.gd`, `Game/scenes/combat/combat_replay_view.gd`, `Game/scenes/command_center/panels/pve_panel.gd`, `Game/engine/campaign/phase_resolver.gd`.
**Critério de aceite (após decisão):** jogador consegue reabrir a última batalha de uma Fase já concluída e ver a mesma reprodução visual, a partir de um ponto de acesso na UI (a decidir: overlay de Acampamento existente, ou botão pós-resultado).
**Bloqueio:** decisão de design (estratégia de persistência) antes de codar.

### F23-03 — Decisão Continuar/Parar antes do Acampamento
**Diagnóstico:** o motor já tem 4 políticas (`AcampamentoPolicy`), incluindo `AGUARDAR_ORDEM` — exatamente o comportamento pedido — totalmente implementada e testada (`test_acampamento_policies.gd`). O problema é 100% de UI: a única ocorrência de `acampamento_policy` fora de testes é uma ferramenta de dev (`bootstrap.gd`). O jogador nunca vê nem escolhe essa política; a produção usa o default `AGUARDAR_RECUPERACAO_TOTAL`, que resolve sozinho.
**Arquivos:** `Game/engine/campaign/expedition_runtime.gd` (motor, sem mudança de regra necessária), `Game/scenes/command_center/panels/pve_panel.gd` (novo seletor de UI).
**Critério de aceite:** jogador escolhe a política de Acampamento antes de a Expedição chegar lá (ou ao menos antes da resolução automática), com `AGUARDAR_ORDEM` disponível como opção real.
**Decisão de design pendente:** a escolha é fixada no início da Expedição ou reconfigurável a qualquer momento?

### F23-04 — Recuperação de Energia real no Acampamento
**Diagnóstico: bug confirmado, não hipotético.** As 3 chamadas de recuperação em Acampamento (`expedition_runtime.gd`, `_apply_acampamento_policy()` e `resume_from_acampamento()`) usam `army.recover_energy_full()` — enchimento instantâneo — em vez de `Army.sync_energy_recovery(now_unix, energy_nucleus_level)`, a função real, determinística e já usada em outros lugares (baseada em `last_energy_sync_unix` e na taxa do Núcleo de Energia). O próprio comentário do código admite ser um placeholder ("fora de escopo aqui").
**Arquivos:** `Game/engine/army/army.gd` (função reutilizável já existe), `Game/engine/campaign/expedition_runtime.gd` (3 call sites a trocar).
**Critério de aceite:** chegar a um Acampamento recupera Energia proporcional ao tempo real decorrido (mesma fórmula de `ENERGY.md`), nunca 100% instantâneo — validado por teste comparando energia recuperada com o tempo simulado.
**Decisão de design pequena:** o "tempo passando" no Acampamento é medido pelo mesmo relógio de tick do `ExpeditionTickResolver`, para não duplicar lógica de tempo (recomendado).

### F23-05 — Mostrar Tier Máximo dos Pelotões
**Diagnóstico:** a regra existe e está documentada (`COMMANDERS.md`, Tabela Oficial de Patentes: Recruta→I, Capitão/Major→II, Coronel→III, General→IV, Marechal/Lorde-Comandante→V). Hoje é aplicada à geração de inimigos PvE, mas **nunca exibida** nem **aplicada** ao Exército do próprio jogador (ver F23-15, achado adicional). Army Editor já mostra "Patente: %s" e um tooltip de teto de Soldo — falta o equivalente para Tier Máximo, no mesmo padrão.
**Arquivos:** `Game/scenes/army/army_editor_panel.gd`, `Game/scenes/city/panels/bestiario_panel.gd`.
**Critério de aceite:** Army Editor e Bestiário mostram claramente o Tier Máximo permitido pela Patente atual, sem duplicar a régua em mais de 2 lugares.

### F23-06 — Explicar Patentes e Tiers
**Diagnóstico:** a própria SSoT de tutorial (`Game/TUTORIAL.md`, "Etapa 12 — A Doutrina do Comandante") já especifica exatamente este conteúdo — e confirma-se, por busca no código, que nunca foi implementado. A infraestrutura para implementá-lo sem duplicar nada **acabou de ser construída** no Bloco 0 (`TutorialSpotlight`, já provada em uso real com Ativo/Reserva). Falta só autorar o conteúdo específico de Patente/Tier e decidir o gatilho (1ª vez que o jogador vê um limite? Após a 1ª promoção?).
**Arquivos:** `Game/scenes/tutorial/tutorial_spotlight.gd` (reusar), `Game/TUTORIAL.md` (Etapa 12), painel-alvo a decidir (provavelmente Army Editor, apontando para o indicador do F23-05).
**Critério de aceite:** na primeira oportunidade relevante, o jogador vê uma explicação contextual real (não um texto genérico) de Patente → Tier Máximo, nunca reaparecendo após vista.
**Dependência:** F23-05 (o spotlight precisa de um alvo visual real para apontar).

### F23-07 — Tela "PvE — Escolha sua Expedição"
**Diagnóstico confirmado, não impressão:** a tela de Seleção (`pve_panel.gd`) usa `ColorRect` chapado como fundo (diferente de Bestiário/Army Editor/Depósitos, que têm arte ilustrada de tela cheia); um slot vazio de Squad é literalmente uma variável chamada `placeholder`. A tela de Mapa da Trilha (estado diferente do mesmo arquivo) já usa arte de fundo real — o problema é específico da tela de Seleção. Arquitetura de informação já está presente (território/facção, expedição ativa, Squad, botão Iniciar, hint de tutorial) — é um problema de composição visual, não de dados/lógica faltando.
**Arquivos:** `Game/scenes/command_center/panels/pve_panel.gd` (código, sem `.tscn` estático).
**Critério de aceite:** tela de Seleção com identidade visual coerente com Bestiário/Army Editor/Depósitos — fundo ilustrado real, sem placeholders literais no código.
**Dependência:** 1 asset de fundo ilustrado novo (carregar Skill `bs-visual` antes de editar, per CLAUDE.md §10).

### F23-08 — Kingdom Inventory / Crystal Vault pouco legíveis
**Diagnóstico confirmado:** ambos os painéis usam fonte 11pt para texto de 2 linhas em caixas de ~9% da largura da tela, sem hierarquia entre rótulo e valor, com `autowrap_mode = AUTOWRAP_OFF` + `clip_text = true` — risco real de corte de texto. Isso é o mesmo problema já corrigido no Army Editor (WIP-7: número 8pt→10pt, rótulo menor). Asset de fundo não é a causa raiz confirmada — não trocar sem testar a hierarquia tipográfica primeiro (como o próprio pedido do usuário instrui).
**Arquivos:** `warehouse_kingdom_inventory_panel.gd`, `warehouse_crystal_vault_panel.gd`.
**Critério de aceite:** valores numéricos legíveis a distância de jogo real, sem corte de texto, reaproveitando o mesmo padrão de hierarquia já validado no Army Editor.

### F23-09 — Auditoria dos inimigos PvE
**Diagnóstico:** `EnemyArmyGenerator` implementa corretamente as regras de `PvE.md` (Tier/Soldo/Patente por Região) e é usado corretamente pelo caminho real que um jogador percorre hoje (`WorldBootstrap._generate_dev_scale_world()`). **Achado novo, ver F23-14.** Dentro de uma única Região, não há escalonamento por número de Fase — a dificuldade progressiva vem inteiramente da ordenação por win-rate, não de stats crescentes; isso é consistente com a "Filosofia do Travamento" documentada em `PvE.md` (combate determinístico, sem rampa artificial), então **não é um bug**, mas é uma alavanca de design que vale confirmar com o dono do projeto.
**Não alterado nenhum inimigo, per instrução explícita.**

### F23-10, F23-11, F23-12 — Feel da batalha
**Achado arquitetural chave (vale para os 3):** a apresentação visual já é 100% desacoplada do `CombatEngine` — o motor resolve a batalha inteira primeiro, o Collector grava os eventos, a View reproduz depois. Qualquer novo som/efeito pode usar exatamente esse mesmo ponto de gancho, sem risco de tocar a lógica de combate.
- **#11 (movimento):** já implementado — movimento entre posições, ataque com projétil (à distância/mago), cura com feixe visual, morte com fade sequenciado, tudo testado. Reclassificado como polimento (F23-12a), não construção nova.
- **#10 (som):** não existe NENHUMA infraestrutura de áudio no projeto hoje (zero `AudioStreamPlayer`, zero assets `.ogg`/`.wav`). Gargalo real é produção/curadoria de assets sonoros, não o gancho técnico (que é barato, mesmo padrão do Collector).
- **#12 (juice barato):** hit-flash mais intenso, scale-punch, leve shake em morte/dano pesado — tudo reaproveitando os mesmos tweens existentes, sem asset novo. Efeitos com partícula (`GPUParticles2D`) exigiriam textura nova — mais caro.

### F23-13 — Pesquisa de jogos semelhantes
Ver seção dedicada abaixo.

---

## NOVOS ITENS ENCONTRADOS NESTA AUDITORIA

### F23-14 — `SeasonPipeline.run()` ignora a Região ao gerar exércitos inimigos (bug de código confirmado)
- **Diagnóstico:** `season_pipeline.gd` chama `EnemyArmyGenerator.generate(category, territory, 1, ...)` com a Região **fixa em `1`** para Fases/Chefes Normais, independentemente da Região-alvo real — a Região só é atribuída DEPOIS, por percentil de win-rate, sem regenerar o exército com o teto de Tier/Soldo da Região certa. O gerador irmão (`RegionalCategoryGenerationRunner`) faz isso corretamente — o bug é específico do `SeasonPipeline`.
- **Verificado nesta sessão:** o catálogo atualmente carregado pelo jogo real (`Game/reports/season_catalog.json`, confirmado pelo `season_id` bater com o log de boot) é o catálogo pequeno de desenvolvimento (~19 exércitos/facção) — consistente com ter sido gerado pelo caminho correto (`WorldBootstrap`/dev-scale), não pelo `SeasonPipeline`. **O bug existe no código mas não está confirmado como afetando a experiência atual do jogador.**
- **Prioridade:** corrigir o código é barato e deve ser feito antes que a ferramenta de escala real (30k candidatos) seja usada para gerar o catálogo de produção — senão Regiões II/III podem sair com exércitos de Tier I-II mascarados.
- **Arquivos:** `Game/engine/world/season/season_pipeline.gd`.
- **Critério de aceite:** `SeasonPipeline` passa a Região real (não hardcoded) para `EnemyArmyGenerator.generate()`, mesmo padrão já usado em `RegionalCategoryGenerationRunner`.
- **Status:** aberto, não corrigido.

### F23-15 — Teto de Tier por Patente nunca é aplicado ao Exército do próprio jogador
- **Diagnóstico:** `Army.is_ready_for_battle()` verifica Formação completa + teto de Soldo, mas **nunca** verifica Tier máximo por Patente — `card_progression.gd` não tem nenhuma referência a "patente". Um Recruta (teto Tier I) pode hoje montar um Exército com cartas Tier V sem nenhum aviso ou bloqueio. A regra existe e é aplicada à IA inimiga (`EnemyArmyGenerator`), mas não ao jogador.
- **Risco:** implementar a aplicação retroativa pode invalidar Exércitos/Formações já salvos que hoje estão "acima do teto" sem terem sido bloqueados por isso.
- **Prioridade:** requer decisão explícita do dono do projeto — não é uma correção óbvia, é uma mudança de regra de jogo com efeito colateral em saves existentes.
- **Arquivos:** `Game/engine/army/army.gd`, `Game/engine/cards/card_progression.gd`.
- **Status:** aberto, aguardando decisão de design. NÃO implementar sem aprovação explícita.

---

## PESQUISA — F23-13: mecanismos de retenção/progressão de jogos semelhantes

Metodologia pedida: A) mecanismo observado, B) problema que resolve, C) aplicação possível no LBS-BS, D) custo, E) risco para economia/identidade. Nenhuma implementação recomendada nesta etapa — só mapeamento.

| # | A) Mecanismo (gênero de referência) | B) Problema que resolve | C) Aplicação possível no LBS-BS | D) Custo | E) Risco |
|---|---|---|---|---|---|
| 1 | "Catch-up" de progresso offline claramente comunicado ao reabrir ("Enquanto você esteve fora...") — comum em jogos de base-building/idle | Jogador não percebe o que já foi corrigido em WIP-1; sensação de progresso invisível | Uma tela/banner simples ao reabrir resumindo Fases avançadas, Recursos produzidos, Energia recuperada desde a última sessão | Baixo (dados já existem, é só exibição) | Baixo — não muda economia, só comunica o que já acontece |
| 2 | Baú/recompensa com "quase lá" visível (barra de progresso próxima ao próximo marco) — Clash Royale, Raid: Shadow Legends | Sensação de "nada para fazer" quando o próximo objetivo está invisível | Trilha já tem estrutura de Fases — mostrar explicitamente "faltam N Fases para o próximo Marco/Recompensa" na tela de Seleção (F23-07) | Baixo–Médio (é composição de dados já existentes) | Baixo |
| 3 | Objetivos diários/semanais curtos e opcionais (não gacha, não P2W) — Hearthstone, AFK Arena | Falta de motivo para abrir o jogo TODO dia, além da Energia acumulando | Um pequeno conjunto de metas diárias ("vença 1 Fase", "recrute 1 Comandante") dando Fragmentos/PG | Médio (novo sistema de tracking + UI) | Médio — precisa não competir com a Energia como único limitador; decisão de design sobre recompensas |
| 4 | "Um empurrãozinho" antes do próximo Acampamento — prévia da recompensa da próxima Fase antes de decidir Continuar/Parar (relevante direto para F23-03) | Decisão de Continuar/Parar sem informação suficiente | Ao implementar F23-03, mostrar uma prévia (dificuldade estimada, recompensa) da próxima Fase antes do jogador decidir | Baixo (mesmo trabalho de F23-03, é só UI adicional) | Baixo |
| 5 | Auto-batalha/pular repetição para conteúdo já dominado — AFK Arena, mobile idle RPGs em geral | Fadiga em Fases já fáceis/repetidas numa Região | Permitir pular a reprodução visual (não a resolução) de Fases já vencidas facilmente, mantendo o replay disponível (liga com F23-02) | Baixo–Médio | Baixo — é só UX, o motor já resolve instantaneamente por trás |
| 6 | Marcos de médio prazo com identidade narrativa (não só número) — Trilhas de batalha em jogos de cartas | Falta de "história" no meio da progressão puramente numérica | Nomear/tematizar marcos da Trilha por Região (já parcialmente coberto por Território/Facção) | Médio (conteúdo narrativo, não sistema novo) | Baixo — não mexe em economia |

**Observação importante:** vários desses mecanismos (1, 2, 4) são essencialmente **camadas de comunicação sobre sistemas que já existem ou estão no Bloco 1/2** — não pedem economia nova. Os únicos com custo de sistema novo real são #3 (objetivos diários) e #6 (conteúdo narrativo), e ambos precisam de decisão do dono antes de qualquer implementação.

---

## DEPENDÊNCIAS (RESUMO)

```text
Bloco 0 (commit do WIP) ──> validação de F23-01 (playtest pós-fix)
F23-04 (energia real) ──> F23-03 (UI de política) [mesmo fluxo/arquivo]
F23-05 (mostrar Tier Máx) ──> F23-06 (tutorial Patente/Tier aponta pro indicador)
F23-14 (fix SeasonPipeline) ──> F23-09b (validar catálogo real) ──> F23-09 (auditoria de balanceamento completa)
F23-02 (replay pós-batalha) ──> BLOQUEADO por decisão de design (persistência) antes de codar
F23-15 (teto de Tier no jogador) ──> BLOQUEADO por decisão explícita do dono (efeito colateral em saves)
F23-07 (tela PvE) ──> precisa de 1 asset de fundo (bs-visual) antes do layout final
F23-10 (som) ──> gargalo é asset de áudio, não arquitetura
```

---

## STATUS GERAL (nesta etapa)

| Bloco | Itens | Status |
|---|---|---|
| Bloco 0 | WIP-1 a WIP-7 | **Commitado** (`a4908deb0a1d7d0524df7678f2865f1b026796a0`) |
| Bloco 1 | F23-03 + F23-04 (decisão Continuar/Parar + Energia real no Acampamento) | **Implementado e testado** (32 novas asserções, suíte completa 3643 passou/0 falhou) — commit desta etapa |
| Bloco 1 (restante) | F23-05, F23-08, F23-12a, F23-14 | Diagnosticado, não implementado — aguardando aprovação |
| Bloco 2 | F23-06, F23-02, F23-07, F23-09b, F23-01b | Diagnosticado, parcialmente bloqueado por decisões de design |
| Bloco 3 | F23-10, F23-15, F23-09, F23-13 | Diagnosticado/pesquisado, requer decisão do dono e/ou produção de assets |
| Auditoria (fora do backlog priorizado) | Minas de Fase (Regionais) | **Auditado** — mecânica já implementada, conectada e testada de ponta a ponta (achado: `TECHNICAL_BACKLOG.md` F-022 está desatualizado). 2 achados P2 registrados, sem ação necessária no Bloco 1. |
| Novo (requisitos futuros, adenda) | F23-16, F23-17, F23-18 | **Auditados nesta etapa, NÃO implementados** — ver seção dedicada abaixo |

---

## F23-03 + F23-04 — Acampamento: implementado (registro para a Fase 23)

Implementação completa entregue nesta etapa (detalhes completos já reportados na conversa; resumo para o registro da Fase):

- **Arquivos:** `expedition_runtime.gd` (novo `CampState` enum: `AWAITING_DECISION`/`RESTING_UNTIL_FULL`/`FORCED_UNTIL_FULL`/`NONE`; `establish_acampamento_and_await_decision()`, `choose_continue_immediately()`, `choose_stop_and_rest()`, `try_release_camp_wait_if_fully_rested()`), `expedition_tick_resolver.gd` (libera automaticamente ao atingir Energia plena), `kingdom_save_service.gd`/`expedition_persistence_resolver.gd` (persistência de `camp_state`, com fallback seguro para saves antigos), `pve_panel.gd` (UI: Energia + Continuar/Parar, ou mensagem sem botões quando a parada é obrigatória/já escolhida).
- **Mecanismo antigo preservado intacto:** `AcampamentoPolicy`/`_apply_acampamento_policy()`/`establish_acampamento()`/`resume_from_acampamento()` continuam existindo e testados isoladamente (`test_acampamento_policies.gd`, `test_expedition_session_waits_for_player.gd`) — só deixaram de ser chamados pelo fluxo real.
- **Testes:** `test_acampamento_decision.gd` (novo, 32 asserções) + 1 correção necessária em `test_expedition_runtime_camp_without_combat.gd` (dependia do antigo auto-continue silencioso).
- **Suíte completa:** 3643 passou, 0 falhou, 0 erros — confirmado 2× (validação final desta etapa incluída).
- **Status:** pronto para commit nesta etapa.

---

## AUDITORIA — Minas de Fase (registro para a Fase 23)

Resumo (relatório completo já entregue na conversa): a mecânica de Minas Regionais/de Fase está **IMPLEMENTADA E FUNCIONAL** de ponta a ponta — marcador no mapa (`pve_panel.gd::_build_mine_slot`), overlay com botão "Conquistar" gateado por `current_fase >= mina.adjacent_fase`, combate real (`MineConquestResolver.attempt_conquest()`), recompensas reais (Fragmentos, XP de Conta, XP de Comandante), persistência completa (`conquered`, `structure_level`, ciclo, Guarnição). **Achado principal:** `TECHNICAL_BACKLOG.md` F-022 ("nunca chamado por nenhum painel real") está **desatualizado** — foi corrigido em uma sessão posterior (comentários "F-020, decisão 11/12/13" no próprio código). Conquista é 100% manual/desacoplada do tick automático — nenhuma interação problemática com o novo Acampamento (`camp_state` não é verificado antes de permitir "Conquistar", registrado como achado P2, não bloqueia nada). **Nenhuma ação necessária no Bloco 1.**

---

## ADENDO — Requisitos Futuros #16, #17, #18 (auditados nesta etapa, NÃO implementados)

> **Não implementado nesta etapa.** As três seções abaixo são diagnóstico puro — nenhuma linha de código de produção foi alterada para produzi-las. Todas as citações são de código/documentação já existentes, nunca inferidas.

### F23-16 — Suspender uma Trilha no Acampamento e retomar posteriormente

**Problema:** hoje só existem 2 destinos a partir de `AWAITING_DECISION`: Continuar (segue com a Energia atual) ou Parar (`RESTING_UNTIL_FULL`, aguarda Energia plena, Exército permanece vinculado à Expedição). Falta uma 3ª opção: suspender a Trilha ali, liberando o Exército para outra atividade, retomando depois exatamente do mesmo ponto.

**Comportamento desejado:** `Acampamento → "Parar esta trilha" → Expedição persiste exatamente ali → Exército livre para outra atividade → retomada posterior → continua de onde parou.`

**Estado atual (auditado, com evidência):**
- `kingdom.active_expeditions` **já é um Array**, salvo/restaurado por inteiro (`kingdom_save_service.gd`/`expedition_persistence_resolver.gd`) — não há cap técnico de 1 expedição ativa; `Kingdom.start_expedition()` só rejeita se algum Exército do Squad já estiver `is_army_locked_for_editing()`, nunca por território ou quantidade.
- `pve_panel.gd::_refresh_selection()` **já lista todas** as expedições ativas (território, Fase, status) — a "tela de encontrar uma Trilha pausada depois" já existe estruturalmente, não precisa ser construída do zero.
- `Kingdom.is_army_locked_for_editing()` já libera o Exército (`locked=false`) sempre que `is_waiting_at_acampamento == true` — ou seja, um Exército parado em QUALQUER `camp_state` de espera (incluindo os recém-implementados) **já fica tecnicamente livre para outras atividades hoje**, de graça, sem nenhuma mudança.
- Energia continua recuperando durante a espera pelo mesmo mecanismo já existente (`GameRuntime.sync()` → `Army.sync_energy_recovery()`), independente de "Parar" ou "Suspender".

**Achado crítico (a lacuna real):** **"Parar e aguardar Energia" e "Suspender" são, hoje, o MESMO estado técnico** (`is_waiting_at_acampamento = true`, Squad continua apontando para os mesmos Exércitos). Não existe nenhum campo ou UI que diferencie "estou esperando Energia aqui, ainda quero voltar logo" de "abandonei isso por ora, quero usar o Exército em outro lugar". Implementar #16 provavelmente exige desacoplar o Squad/Army da Expedição enquanto suspensa (hoje o Squad é uma referência direta e fixa aos mesmos objetos `Army`).

**Infraestrutura existente reaproveitável:** array de expedições, persistência completa, `is_army_locked_for_editing()`, lista de expedições na UI, recuperação de Energia contínua.

**Infraestrutura faltante:** um estado/flag que distinga "suspensa" de "aguardando energia"; um mecanismo real de desvinculação Army↔Expedição enquanto suspensa (para permitir uso simultâneo genuinamente seguro, ex.: o mesmo Exército não pode virar Guarnição de Mina E continuar "reservado" por uma Trilha suspensa ao mesmo tempo sem uma regra explícita); nenhum teste cobre hoje "Exército em pausa + designado a outra atividade simultaneamente" — risco não verificado.

**Arquivos/sistemas relevantes:** `Game/engine/kingdom/kingdom.gd` (`is_army_locked_for_editing`, `start_expedition`, `active_expeditions`), `Game/engine/campaign/expedition_runtime.gd`, `Game/engine/kingdom/kingdom_save_service.gd`, `Game/engine/campaign/expedition_persistence_resolver.gd`, `Game/scenes/command_center/panels/pve_panel.gd` (`_refresh_selection`), `Arquitetura/ARMY.md` ("Trava de Edição por Modo de Jogo").

**Dependências:** nenhuma bloqueante em relação a F23-03/F23-04 (não os altera) — mas depende de uma decisão de design antes de qualquer código.

**Decisões de design pendentes (não resolvidas por código/doc algum, registrar, não inventar):**
- Pode haver múltiplas trilhas pausadas simultaneamente, ou só 1? (código já suportaria N sem mudança, mas nunca foi uma decisão deliberada)
- Uma trilha pausada consome algum recurso? (não documentado)
- A Energia continua regenerando durante a pausa? (tecnicamente sim, de graça, hoje — mas nunca foi decidido como regra de "pausa" propriamente dita)
- O Exército pode ser usado em TODAS as outras atividades enquanto a trilha está suspensa, ou só algumas? (não documentado — risco de uso simultâneo incompatível não coberto por nenhum teste)
- Existe limite de trilhas pausadas por jogador? (não documentado)

**Prioridade:** P1 — mecânica existe parcialmente (persistência e desbloqueio já funcionam de graça), mas falta a peça central (distinguir suspensão de espera) e decisões de design.
**Esforço:** Médio (a infraestrutura de persistência/listagem já existe; o esforço real está na distinção de estado + regra de exclusividade do Exército, mais qualquer UI nova para "suspender"/escolher entre trilhas pausadas).
**Critério de aceite futuro:** "Cheguei ao Acampamento 3, suspendi essa trilha, usei meu Exército em outra atividade e no dia seguinte voltei exatamente para o Acampamento 3" — sem duplicar, perder ou travar incorretamente o Exército em nenhum momento do meio.

---

### F23-17 — Replay de todas as Fases PvE (vitória E derrota)

**Problema:** o replay de uma batalha PvE hoje só existe ao vivo, uma vez, no instante da tentativa — descartado logo em seguida. O jogador não consegue rever depois, nem vitórias nem derrotas.

**Estado atual (auditado, com evidência):**
- `CombatReplayCollector` grava `replay_events` (Array de Dictionaries — tipos primitivos: kind/turn/side/posições/hp/esc/dano) e `initial_board` — **tudo serializável**, com uma única exceção: `initial_board` guarda `"card": unit.card` (referência viva a `CardResource`, não o nome) — precisa virar `card_name` + `GameDatabase.get_card()` na reconstrução (mesmo padrão já usado em outras telas deste projeto).
- `CombatReplayView` não é hoje um "player" puro de dados — seu `setup()` também recebe o `CombatState` final ao vivo, mas TUDO que ele efetivamente lê de lá (`battlefield`, `seed_value`, `battle_id`, `rules_version`, `winner_side`, `turn`) já são primitivos/nomes de recurso trivialmente serializáveis — só a FORMA da API precisaria mudar (aceitar campos escalares reconstruídos em vez do objeto `CombatState` ao vivo).
- **Vitória e derrota são gravadas de forma idêntica**: `PhaseResolver.resolve()` anexa o Collector a `battle_replays` incondicionalmente, antes mesmo do texto de resultado ser calculado — confirmado, sem gap para derrota.
- **Determinismo:** confirmado — só a habilidade Silêncio (`silencio_runtime.gd`) usa RNG não-seedado (`context.state.rng.randi()`). Reconstruir por RE-SIMULAÇÃO a partir das Formações salvas **não é confiável** sempre que Silêncio estiver em jogo — a única estratégia sólida é persistir o LOG DE EVENTOS gravado, nunca re-simular.
- **Escala:** cada evento é um Dictionary pequeno (~6-12 campos primitivos); uma batalha típica gera dezenas a poucas centenas de eventos — trivial por batalha, mas uma Trilha tem até 9000 Fases (`PvE.md`) — armazenar o replay de TODAS para sempre é uma incompatibilidade de escala real, precisa de limite.
- **Ponto de acesso na UI:** `pve_panel.gd::_on_fase_node_mouse_entered` (hover sobre um nó de Fase já disputada) já mostra vitória/derrota + as duas Formações a partir de `fase_history` — um botão "REVER BATALHA" caberia naturalmente ali, mas é um popup de HOVER (não clique) — ajuste de UX necessário para acomodar um botão clicável de forma confiável.

**Infraestrutura existente reaproveitável:** `CombatReplayCollector` (gravação, já cobre vitória e derrota) e `CombatReplayView` (reprodução) — **nenhum segundo sistema de replay precisa ser criado**.

**Infraestrutura faltante:** (a) uma camada de persistência real (nada guarda `replay_events` hoje além do instante em que são produzidos); (b) um esquema de chave ligando um replay salvo a uma Fase específica (naturalmente encaixaria em `fase_history`, que hoje não tem nenhum campo de replay); (c) uma política de limite de armazenamento dado o teto de 9000 Fases; (d) pequeno ajuste de API do `CombatReplayView` para consumir dados reconstruídos; (e) resolver a referência viva de `CardResource` em `initial_board` para nome.

**Arquivos/sistemas relevantes:** `Game/engine/combat/combat_replay_collector.gd`, `Game/scenes/combat/combat_replay_view.gd`, `Game/engine/campaign/phase_resolver.gd` (`PhaseResult.battle_replays`), `Game/engine/campaign/expedition_runtime.gd` (`_record_fase_history`/`fase_history`), `Game/scenes/command_center/panels/pve_panel.gd` (`_on_fase_node_mouse_entered`), `Game/engine/combat/abilities/silencio_runtime.gd` (caveat de determinismo).

**Dependências:** nenhuma com F23-03/F23-04. Compartilha o mesmo sistema de replay que #17 do backlog original (F23-02) — este item efetivamente SUBSTITUI/AMPLIA F23-02 (adiciona explicitamente o caso de derrota).

**Decisões de design pendentes:**
- Armazenar TODOS os replays ou só os últimos N (ou 1 por Fase, sobrescrevendo)? Sem precedente claro no projeto — `fase_history` em si já cresce sem limite hoje (1 entrada por Fase já tentada), então esse padrão de "sem limite" já existe, mas nunca foi avaliado para o volume MUITO maior de um replay completo.
- Onde armazenar: estender `fase_history` in-place vs. uma estrutura separada no `Kingdom`? Ambos arquiteturalmente viáveis, nenhum decidido.
- Regra de limite/expurgo dado o teto de 9000 Fases/Trilha: não definida.

**Prioridade:** P1 — sistemas de gravação/reprodução prontos e corretos, falta só a camada de persistência.
**Esforço:** Médio (sem novo sistema de combate/replay, mas exige decisão de armazenamento + serialização + ajuste de API do View + UX do ponto de acesso).
**Critério de aceite futuro:** jogador seleciona qualquer Fase já concluída (vitória ou derrota) no histórico de PvE e consegue clicar "REVER BATALHA", vendo a reprodução visual real, idêntica à que ocorreu.

**STATUS: IMPLEMENTADO (Item #17, revisão final aprovada).** Decisões
de design que estavam pendentes acima, agora resolvidas:

> **POLÍTICA MVP:**
> 15 replays globais mais recentes.

Armazenamento **global** (`Kingdom.battle_replays`, não por
Expedição/Trilha), limite `Kingdom.MAX_STORED_BATTLE_REPLAYS = 15`,
expurgo FIFO determinístico (o mais antigo cai primeiro). Medido em
produção: ~226 KB por replay no pior caso (64 turnos) — ≈3,4 MB
adicionais no save no pior caso com os 15 replays cheios. Nunca
re-simula (persiste o log de eventos gravado por
`CombatReplayCollector`, exatamente como o item de "Decisões de design
pendentes" acima já apontava como a única estratégia confiável).
Vitória e derrota são gravadas de forma idêntica, nunca filtradas.
Reidentificação por `replay_id` (contador monotônico do Kingdom) —
nunca reaproveita `CombatState.battle_id`, que não é seguro entre
sessões. Acesso pela UI: clique real no nó de Fase em `pve_panel.gd`
(quando `fase_history[fase]` tem `replay_id`) abre a mesma
`CombatReplayView` já existente — nunca um segundo visualizador.

> **DECISÃO FUTURA:**
> reavaliar retenção por Expedição/Trilha caso o histórico PvE evolua.

Se o histórico de PvE crescer em importância (ex.: múltiplas
Expedições simultâneas de fato competindo pelo mesmo teto de 15
replays globais), reavaliar limite por Expedição/Trilha em vez de
global. Não implementado agora — fora do escopo desta revisão.

---

### F23-18 — Affinity visível em tempo real durante a batalha

**Problema:** o jogador não vê, durante o combate, quais bônus de Affinity estão ativos nem seus valores — só pode inferir pelo resultado.

**Estado atual (auditado, com evidência):**
- `Affinity.calculate_points()`/`active_levels()` (`Game/engine/combat/affinity.gd`) calculam Pontos/Níveis reais (1/2/3 pelotões da Facção + Comandante); `active_effects(faction, points, catalog)` **já existe** exatamente como a sugestão do pedido descreve, retornando dados descritivos a partir de um catálogo real (`AffinityLevelResource`), nunca um número inventado aqui.
- Valores numéricos reais aplicados (`AffinityRuntime`, `Game/engine/combat/affinity_runtime.gd`): Império Nível I = +25 ESC fixo (uma vez, início da batalha); Natureza Nível I = +20 HP fixo; Império Nível II = -20% dano recebido (linha/coluna 100% Império); Natureza Nível II = bônus na 1ª cura; Mortos-Vivos Nível II = bônus de morte pendente→ativo. Nível III não tem valores implementados (documentado como não especificado). Mortos-Vivos Nível I (ATK) é a ÚNICA exceção: recalculado ao vivo no momento do ataque (`CombatEngine._effective_attack()`), não fica pré-gravado no snapshot do turno.
- **Snapshot já existe e já é a fonte única de verdade:** `AffinityRuntime.snapshot_turn(state)` roda no início da batalha e a cada turno (`combat_engine.gd`), escrevendo em campos públicos de `CombatState` (`affinity_points`, `affinity_levels`, flags por unidade) — **nenhuma UI precisaria calcular nada de novo**, só ler esses campos + `level_for()` (acessor já existente) + `active_effects()`.
- **Snapshot == valor aplicado**, confirmado, para Império/Natureza/Mortos-Vivos Nível II (mesma escrita, mesma leitura) — a única ressalva é o ATK de Mortos-Vivos Nível I, que a UI precisaria buscar separadamente via `level_for()` para não omitir silenciosamente esse bônus.
- **Gancho para a UI: não existe ainda.** `CombatEventBus` não tem nenhum evento de Affinity; `CombatReplayCollector`/`CombatReplayView` têm zero referências a Affinity hoje — precisaria de um evento novo (mesmo padrão de `TURN_START` etc.) ou leitura direta do `CombatState` pela View nas fronteiras de turno.
- **Canto inferior direito da batalha:** confirmado vazio hoje — o cabeçalho (turno) e o rodapé (botão de Log + velocidade) não ocupam esse canto; a única sobreposição possível é a gaveta de Log (`_build_log_drawer`), que é full-width e fica oculta por padrão, sobrepondo só quando aberta manualmente — um painel de Affinity ali só entraria em conflito visual nesse momento específico (Log aberto), não permanentemente.

**Infraestrutura existente reaproveitável:** `Affinity.active_effects()`, `AffinityRuntime.level_for()`, os campos já públicos em `CombatState` — a camada de DADOS já está pronta, é puramente leitura, nunca uma fórmula nova.

**Infraestrutura faltante:** um evento no `CombatEventBus` (ou leitura direta pela View) para entregar o snapshot a cada turno à camada visual; o próprio painel de UI (canto inferior direito); tratamento explícito do caso especial do ATK de Mortos-Vivos (não vem pré-computado no snapshot).

**Arquivos/sistemas relevantes:** `Game/engine/combat/affinity.gd`, `Game/engine/combat/affinity_runtime.gd`, `Game/engine/combat/combat_engine.gd` (`_environment_update_phase`), `Game/engine/combat/combat_state.gd`, `Game/scenes/combat/combat_replay_view.gd`, `combat_event_bus.gd`.

**Dependências:** nenhuma com F23-03/F23-04. Toca o mesmo `CombatReplayView` que F23-11/F23-12 (juice) já tocam — coordenar se implementados na mesma janela de trabalho, para não duplicar mexidas no mesmo arquivo.

**Decisões de design pendentes:**
- Nenhuma decisão de REGRA pendente (os valores já são 100% reais e documentados) — só decisões de APRESENTAÇÃO: exibir também Nível III (sem valores implementados, mostraria vazio) ou omitir até existir; exibir o caso especial do ATK de Mortos-Vivos de forma clara.
- Confirmar se o canto inferior direito é aceitável definitivamente ou se a gaveta de Log (quando aberta) exige um ajuste de posição/z-order — não foi peido "decidir agora", só registrar que é o único conflito real encontrado.

**Prioridade:** P1 — dados prontos, é majoritariamente um trabalho de plumbing + UI.
**Esforço:** Baixo/Médio (confirmado pela auditoria: não precisa de fórmula nova, só um evento novo + painel novo).
**Critério de aceite futuro:** durante uma batalha real, um painel no canto inferior direito mostra exatamente os bônus de Affinity ativos (Nível e efeito) para o snapshot do turno corrente, nunca divergindo do que `CombatEngine` de fato aplicou.

Nenhum código de gameplay novo foi alterado nesta etapa (além da investigação read-only). Nenhum commit/push foi feito.
