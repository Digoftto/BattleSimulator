# CAMPO_DE_PROVA.md

# Campo de Prova

## Objetivo

O Campo de Prova é uma ferramenta de preparação tática onde o jogador observa o comportamento de um Exército sem iniciar uma atividade de campanha, ranqueamento ou progressão.

Ele existe para responder perguntas de composição, posicionamento, Doutrina, Afinidade e Campo de Batalha antes de o jogador comprometer a capacidade operacional de um Exército em PvE ou PvP.

O Campo de Prova não é Treinamento (`COMMAND_CENTER_TRAINING.md`): não melhora Cartas, Pelotões, Comandantes ou habilidades. Também não é uma atividade de recompensa, produção ou progressão.

---

## Origem do Documento

Este documento promove `Ideias/CAMPO_DE_PROVA.md` (proposta original, não-canônica) a Single Source of Truth de Arquitetura, incorporando uma decisão de acesso explícita do dono do projeto. `Ideias/CAMPO_DE_PROVA.md` permanece no repositório como registro histórico da concepção original, com uma indicação apontando para este arquivo (ver rodapé daquele documento).

**Nenhuma funcionalidade foi implementada nesta etapa.** Este é um documento de arquitetura — o estado real de implementação de cada elemento é registrado explicitamente na seção "Estado de Implementação", abaixo.

---

## Responsabilidade do Documento

Este documento é a fonte única de verdade (*Single Source of Truth*) para:

* O conceito, o objetivo e as regras permanentes do Campo de Prova;
* Sua relação de acesso com o Centro de Comando e com o fluxo de Exércitos;
* A separação explícita entre o Campo de Prova e o World Map Gate (PvE/PvP/Minas);
* O estado real de implementação de cada elemento do conceito.

Este documento **não** define:

* Regras de Formação, Soldo ou Energia de Exército (`ARMY.md`, `SOLDO.md`, `ENERGY.md`);
* Regras de Comandantes, Patentes ou Doutrina (`COMMANDERS.md`, `COMMAND_CENTER.md`);
* Regras de Cartas (`CARD.md`, `CARD_CATALOG.md`);
* Regras do motor de combate, turnos ou condições de vitória (`COMBAT_CORE.md`, `COMBAT_RULES.md`);
* Regras de Afinidade ou Campos de Batalha (`AFFINITY.md`, `BATTLEFIELDS.md`);
* Telas, hotspots, assets ou fluxo visual — isso pertence a uma etapa futura de UI/produção, explicitamente fora do escopo desta promoção arquitetural.

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura. Este documento organiza a posição do Campo de Prova na arquitetura geral e preserva as regras específicas do próprio Campo de Prova — nunca redefine a regra de outro sistema.

---

## Decisão de Acesso (promovida nesta etapa)

> **O Campo de Prova pertence ao Centro de Comando e faz parte do fluxo de preparação dos Exércitos.**

Fluxo conceitual oficial:

```text
Centro de Comando
        ↓
     Exércitos
        ↓
Selecionar/Montar Exército (Editor de Exército)
        ↓
Exército válido para batalha (Army.is_ready_for_battle())
        ↓
   ┌────────────────┐
   │  Campo de Prova │
   └────────────────┘
        ↓
Configurar oposição
        ↓
Executar prova (Combat State isolado)
        ↓
Replay
        ↓
Relatório
        ↓
Repetir / Ajustar Exército
```

Isso preserva o princípio original de `Ideias/CAMPO_DE_PROVA.md` ("acesso a partir da montagem do Exército") sem contradizê-lo: no projeto real, a montagem/administração de Exércitos já ocorre dentro do fluxo do Centro de Comando — `COMMAND_CENTER_UI.md`, "Janela: Exércitos" já encaminha para `exercitos_panel.tscn`, e o Editor de Exército (`army_editor_panel.tscn`) já é um overlay instanciado a partir dali (`exercitos_panel.gd`), nunca uma cena independente. O Campo de Prova segue o mesmo precedente já estabelecido para "Exércitos" na própria `COMMAND_CENTER_UI.md`: o CdC organiza o acesso, sem ser dono das regras do sistema.

**Não é uma construção independente, nem um prédio separado, nem um destino do World Map Gate.**

### Onde o botão deve aparecer (registro de decisão, não implementação)

* **Cena/painel responsável:** `Game/scenes/city/panels/exercitos_panel.gd` (lista de Exércitos) e/ou o overlay `Game/scenes/army/army_editor_panel.gd` — ambos já acessados via Centro de Comando.
* **Condição de exibição:** o mesmo critério que `Ideias/CAMPO_DE_PROVA.md` já definia — depois que a formação estiver válida. No código, isso corresponde a `Army.is_ready_for_battle()` (`Game/engine/army/army.gd`), que verifica Formação completa + Soldo Total dentro do teto da Patente (`ARMY.md`, "Exército válido para batalha").
* Nenhuma cena, botão ou hotspot foi criado nesta etapa — este é um registro de ONDE ele deve viver quando implementado.

---

## Separação com o World Map Gate (confirmação documental)

| | Centro de Comando | World Map Gate |
|---|---|---|
| Responsabilidade | Comandantes, Exércitos, montagem/preparação, **Campo de Prova** | PvE, PvP, Minas |
| Consequência operacional | Nenhuma (administrativo/preparação) | Real (progressão, recompensa, ranking, produção) |
| Documento dono | `COMMAND_CENTER.md`, `COMMAND_CENTER_UI.md`, este documento | `WORLD_MAP_GATE.md` |

Nenhuma responsabilidade é duplicada entre os dois. O Campo de Prova não conta como PvE, PvP, Mina ou Arena (ver "Regras Permanentes", abaixo) — essa distinção já era exigida por `Ideias/CAMPO_DE_PROVA.md` e se torna ainda mais relevante agora que Campo de Prova e as janelas de Treinamento/Legado/Comandantes/Exércitos são todos irmãos dentro do mesmo CdC.

---

## Regras Permanentes (preservadas de `Ideias/CAMPO_DE_PROVA.md`, sem alteração)

Uma sessão do Campo de Prova:

* usa as mesmas regras do combate real;
* não consome Energia;
* não consome Soldo;
* não consome recursos;
* não consome Fragmentos;
* não consome Pontos de Geração;
* não concede XP;
* não concede recompensas;
* não altera Patente;
* não altera Tier;
* não altera Afinidade permanente;
* não altera Doutrina;
* não gera histórico competitivo;
* não conta como PvE;
* não conta como PvP;
* não conta como Mina;
* não altera os Exércitos persistentes (Combat State isolado, descartado ao final).

A exceção é somente operacional: o Campo de Prova usa as regras de resolução do combate real; a isenção de Energia/Soldo/recursos é exclusivamente sobre o CUSTO de iniciar a prova, nunca sobre as regras aplicadas durante ela.

---

## Formas de Prova (preservadas)

### 1. Oposição Configurada

O jogador define um Perfil de Oposição e o sistema seleciona aleatoriamente um Exército elegível dentro desse perfil, a partir de um Catálogo de Oposições autorizado. Depois de escolhido, o oponente é congelado; a batalha usa as regras determinísticas normais.

| Filtro | Regra |
|---|---|
| Facção | Uma, várias ou qualquer facção permitida. |
| Cartas obrigatórias | Oponente precisa conter todas as Cartas selecionadas. |
| Cartas proibidas | Oponente não pode conter nenhuma Carta selecionada. |
| Tier | Faixa permitida para as Cartas do oponente. |
| Patente | Faixa permitida para o Comandante do oponente. |
| Campo de Batalha | Campo oficial que será aplicado à sessão. |

### 2. Confronto entre Exércitos

O jogador seleciona dois Exércitos válidos próprios: um como formação principal e outro como oposição. Estados isolados; nenhum dos dois Exércitos reais é alterado.

---

## Reprodutibilidade (preservada)

* Semente de Oposição e configuração completa do perfil são registradas por sessão;
* A oposição, uma vez sorteada, fica congelada;
* "Repetir esta Prova" mantém Perfil, Semente, Campo de Batalha e oposição inicial, permitindo comparar mudanças de composição/posicionamento/Cartas contra o mesmo cenário.

---

## Insights Táticos (preservados)

Princípio: **o sistema não pode inventar uma explicação para vitória ou derrota.** Os insights precisam derivar de eventos observáveis do combate, registrados por um Log Estruturado (ver "Estado de Implementação" — hoje **não implementado**, ver distinção abaixo).

Categorias já definidas (preservadas sem alteração): Afinidade perdida, Inatividade, Posição incompatível, Valor de posicionamento, Campo de Batalha, Janela decisiva.

**`battle_log` (`CombatState.battle_log`) não é o Log Estruturado exigido aqui.** `battle_log` é textual, de finalidade humana/depuração (confirmado em `Game/engine/combat/battle_result.gd`, docstring). O Log Estruturado exigido pelos insights (posição antes/depois, ação/motivo de não agir, alvo, dano/cura/Escudo, habilidades acionadas, Afinidade, efeito de Campo de Batalha, turno decisivo) **não existe no código hoje** — é uma instrumentação nova do Combat State, ainda não construída.

---

## Interface (registro de intenção, não implementada)

O botão Campo de Prova deve aparecer no fluxo de Exércitos do Centro de Comando, depois que a formação estiver válida (`Army.is_ready_for_battle()`). Antes do início, a interface deve exibir de forma explícita:

> Sem consumo de Energia. Sem recompensas. Sem alteração permanente.

O resultado deve manter a mesma leitura visual de uma batalha real, com um marcador permanente de contexto ("Campo de Prova") para nunca ser confundido com PvE, PvP ou Arena.

---

## Estado de Implementação

### A. Regras já consolidadas (conceito, preservado do documento original)
Todas as regras em "Regras Permanentes", "Formas de Prova", "Reprodutibilidade" e "Insights Táticos" — nenhuma foi alterada nesta promoção.

### B. Sistemas já implementados (reutilizáveis diretamente)
* `Game/engine/combat/combat_engine.gd` — motor de combate real (turnos, Afinidade, Doutrina, habilidades, Campos de Batalha, condições de vitória, limite de 64 turnos), já roda em Combat State isolado e não-persistente por natureza.
* `Game/engine/combat/battle_result.gd` — estrutura de resultado, já desenhada (docstring própria) para "simulação em massa, Campo de Prova, PvE, PvP, analytics".
* `Game/scenes/combat/combat_replay_view.gd` — apresentação visual de batalha (aceleração, pular para o resultado) já pronta e reaproveitável para a exigência de "Apresentação da Batalha".
* `Game/engine/army/army.gd::is_ready_for_battle()` — critério real de "formação válida".
* Fluxo Centro de Comando → Exércitos → Editor de Exército (`exercitos_panel.gd` + overlay `army_editor_panel.gd`) — já existente, já organizado pelo CdC.

### B2. Tela real do jogador (implementada em 2026-09-01, ausente desta seção até a auditoria da FASE 21 — corrigido aqui)

`Game/scenes/command_center/panels/campo_de_prova_panel.gd` (862 linhas) é uma tela real e jogável, acessível por um hotspot próprio no Centro de Comando (`command_center_panel.gd`, ao lado dos hotspots de Exércitos/Comandantes — **não aninhado dentro do fluxo do Editor de Exército**, diferente do que a versão anterior desta seção presumia). Implementa dois modos, ainda não descritos formalmente no restante deste documento (**documentação pendente de redação, não uma reescrita silenciosa de regra** — o comportamento abaixo é o que o código realmente faz):

* **Modo Real:** um lado é obrigatoriamente um Exército real do jogador (`kingdom.armies`); o outro é um Exército de Teste (não precisa pertencer ao jogador). Editar qualquer um dos lados aqui nunca altera o Exército real salvo.
* **Modo Simulado:** os dois lados são Exércitos de Teste, livres.
* Os dois lados reaproveitam integralmente o Editor de Exército existente (`army_editor_panel.gd`, `sandbox_mode`) — nenhuma segunda implementação de montagem/Formação.
* Motor de combate real: `CombatEngine.initialize()+run()` com `CombatReplayCollector` anexado antes de `run()` — mesmo padrão do PvE. **Nota técnica:** hoje é chamado com `game_mode = "pve"` (nenhum modo `"campo_de_prova"` existe no motor) — isto significa que qualquer regra de Doutrina do Comandante restrita a um `game_mode` específico pode se comportar de forma inesperada aqui; sinalizado, não corrigido nesta auditoria.
* Relatório pós-combate real (`_build_relatorio_interior()`): vencedor, número de turnos, Campo de Batalha sorteado, Exército/Comandante de cada lado — sem inventar dado que o combate não produziu.
* **"Repetir esta Prova"** (botão real, `repetir_button`) reexecuta com a mesma seed (`SimulationConfig`) — a "Reprodutibilidade" da seção acima já é real para uma sessão de tela, ainda sem persistência entre sessões do jogo.

### C. Sistemas parcialmente implementados
* `Game/engine/combat/battle_simulation_runner.gd::simulate_player_army_vs_generated()` — o próprio código já rotula esta função como "coração do futuro Campo de Prova" (comentário F-029 §18): recebe um `Army` real do jogador e simula contra N adversários gerados, com seed reprodutível (`Game/engine/combat/simulation_config.gd`, `SeedMode.FIXED`/`SEQUENTIAL`). Continua sendo infraestrutura de back-end/ferramenta de balanceamento (`bootstrap.gd`) — a tela real do jogador (B2, acima) não passa por esta função; usa `CombatEngine` diretamente, um caminho mais simples.
* Reprodutibilidade por seed entre SESSÕES do jogo (persistir a seed associada a uma Prova specific para retomar depois de fechar o jogo) — dentro de uma mesma sessão de tela já funciona (B2, "Repetir esta Prova").

### D. Sistemas ainda conceituais (não implementados)
* Perfil de Oposição configurável pelo jogador (Facção/Cartas obrigatórias-proibidas/Tier/Patente/Campo de Batalha) — o Modo Real/Simulado (B2) já permite escolher livremente Comandante e Cartas dos dois lados via o Editor de Exército, mas não esse conjunto específico de filtros por atributo.
* Catálogo de Oposições autorizado.
* Log Estruturado (ver acima — distinto de `battle_log`) e o motor de insights táticos e suas 6 categorias — o relatório real (B2) mostra vencedor/turnos/Campo de Batalha/identidade dos dois lados, mas não explica "por quê" venceu.
* Marcador visual permanente "Campo de Prova" no replay (a tela real reaproveita `CombatReplayView` sem essa marca distintiva).
* Isenção de Energia/Soldo/recursos como regra ativa (`ENERGY.md` e demais documentos de recurso ainda não definem essa exceção formalmente — a tela real, na prática, já não consome Energia/Soldo do Reino, mas isso nunca foi declarado como regra permanente nestes documentos).
* Consumo do relatório pelo Observatório (`OBSERVATORY.md` hoje só documenta uma simulação estática de balanceamento v1.0, não um fluxo de relatórios por sessão do jogador).

### E. Dependências existentes
`ARMY.md` (Formação, Soldo, validade), `COMMANDERS.md` (Doutrina, Patente), `CARD.md`/`CARD_CATALOG.md` (Cartas), `COMBAT_CORE.md`/`COMBAT_RULES.md` (motor, turnos, condições), `AFFINITY.md`, `BATTLEFIELDS.md`, `COMMAND_CENTER.md`/`COMMAND_CENTER_UI.md` (organização de acesso), `combat_engine.gd`, `battle_result.gd`, `battle_simulation_runner.gd`, `simulation_config.gd`, `combat_replay_view.gd`, `exercitos_panel.gd`, `army_editor_panel.gd`.

### F. Dependências ainda inexistentes
Log Estruturado por turno/Pelotão no Combat State; API de geração de oposição por Perfil (Facção/Cartas/Tier/Patente) reutilizando `EnemyArmyGenerator`/`Catálogo de Oposições`; regra de isenção de Energia/Soldo em `ENERGY.md`/`SOLDO.md` (a ser adicionada quando o sistema for implementado, nunca inventada agora); mecanismo de relatório consumível pelo Observatório.

### G. Contradições com a Arquitetura canônica
Nenhuma contradição de regra de jogo foi encontrada. A tensão documental sobre a "Missão" de `COMMAND_CENTER.md` não listar Exércitos/Campo de Prova (registrada aqui numa versão anterior desta seção) **já foi resolvida** — `PROJECT_INDEX.md`, "Resolved decision record", confirma que a Missão do Centro de Comando já lista 7 responsabilidades, incluindo "organizar o acesso" a Exércitos e a Campo de Prova. Nenhuma ação pendente aqui.

### H. Decisões de design promovidas para a Arquitetura nesta etapa
1. O Campo de Prova pertence ao Centro de Comando, dentro do fluxo de Exércitos (não é construção independente, não é destino do World Map Gate).
2. O critério de exibição do botão é `Army.is_ready_for_battle()`.
3. `battle_log` é explicitamente declarado incompatível com o Log Estruturado exigido pelos insights — não devem ser confundidos em implementações futuras.

---

## Referências

* **Ideias/CAMPO_DE_PROVA.md:** Concepção original (histórico, não-canônico após esta promoção).
* **ARMY.md:** Formação, Soldo, validade de Exército.
* **COMMANDERS.md:** Doutrina, Patente.
* **COMMAND_CENTER.md / COMMAND_CENTER_UI.md:** Organização de acesso via CdC; janela "Exércitos" (precedente direto).
* **WORLD_MAP_GATE.md:** Separação de responsabilidade com PvE/PvP/Minas.
* **COMBAT_CORE.md / COMBAT_RULES.md:** Motor de combate, turnos, condições de vitória.
* **AFFINITY.md / BATTLEFIELDS.md:** Regras aplicadas durante a prova.
* **ENERGY.md / SOLDO.md:** Sistemas cuja isenção precisa ser formalizada quando o Campo de Prova for implementado.
* **OBSERVATORY.md:** Consumidor futuro opcional do relatório.
