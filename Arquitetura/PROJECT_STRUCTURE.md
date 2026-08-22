# PROJECT_STRUCTURE.md

# Estrutura e Organização da Documentação

## Objetivo

Este documento define a organização oficial, a taxonomia e a estrutura de diretórios da documentação técnica de arquitetura do Battle Simulator (`Arquitetura/`).

Seu objetivo é servir como o mapa da documentação de regras de jogo, garantindo que cada sistema, mecânica ou diretriz possua uma localização única, delimitada e identificável (*Single Source of Truth*).

Este documento **não** define regras de jogo, fórmulas, parâmetros econômicos ou mecânicas de combate.

---

## Responsabilidade do Documento

Este documento é a Fonte Única de Verdade (*Single Source of Truth*) para:

* A árvore oficial de documentos de `Arquitetura/`;
* A categorização e agrupamento conceitual desses arquivos;
* As convenções de nomenclatura e padrão de estrutura de cada documento;
* A ordem recomendada de leitura e dependência arquitetural dentro de `Arquitetura/`.

Este documento **não** define:

* Decisões formais de desenvolvimento e regras de agentes (`DECISOES.md`);
* Glossário e termos oficiais do projeto (`GLOSSARY.md`);
* Regras, balanceamento ou funcionamento interno de qualquer sistema de jogo;
* A relação entre `Arquitetura/` e as demais áreas do repositório (`PROJECT_INDEX.md`, na raiz do projeto, é a fonte única de verdade para isso — ver "Relação com as Demais Áreas do Repositório" abaixo, que apenas resume, sem substituir, o que `PROJECT_INDEX.md` já estabelece).

---

## Filosofia da Estrutura

A documentação do Battle Simulator é projetada sob os seguintes pilares:

1. **Modularidade:** Cada subsistema do jogo é documentado em um arquivo próprio e independente.
2. **Ownership Único:** Cada domínio de conhecimento possui exatamente um documento responsável.
3. **Baixo Acoplamento:** Módulos se conectam via referências formais, sem duplicar conceitos entre arquivos.
4. **Escalabilidade:** A inclusão de novas mecânicas ou modos de jogo ocorre pela adição de novos documentos, sem a necessidade de reestruturar os arquivos existentes.

---

## Estrutura Oficial de `Arquitetura/`

Os documentos abaixo refletem os arquivos que atualmente existem em `Arquitetura/`, organizados por grupo conceitual.

### 1. Governança e Auditoria

Documentos institucionais que estabelecem as regras de desenvolvimento, documentação e manutenção do projeto, e registros de auditoria histórica (não definem mecânicas de jogo).

* `PROJECT_STRUCTURE.md` — Este documento: mapa e diretrizes da documentação de `Arquitetura/`.
* `DECISOES.md` — Registro oficial de decisões arquiteturais, políticas e convenções de desenvolvimento; regras para agentes de IA.
* `AUDITORIA_FINAL_v0.9.md` — Registro histórico de uma auditoria de consistência da arquitetura. Evidência histórica, não autoridade de regra corrente (`PROJECT_INDEX.md`, "Legacy and audit files").

### 2. Visão, Filosofia e Facções

Fundamentação conceitual, direção de design e linguagem oficial.

* `GAME_PHILOSOPHY.md` — Filosofia de design e pilares de balanceamento.
* `GLOSSARY.md` — Dicionário técnico e convenções linguísticas oficiais.
* `LORE.md` — Contexto narrativo e universo do jogo.
* `FACTION_DESIGN.md` — Identidade e design das Facções (Império, Natureza, Mortos-Vivos).

### 3. Motor de Combate e Habilidades

Módulos que especificam o funcionamento do motor de simulação e regras de batalha.

* `COMBAT_CORE.md` — Especificação do motor e matemática base de combate.
* `COMBAT_RULES.md` — Regras de engajamento, alvos e cálculo de dano.
* `ABILITIES.md` — Mecânicas, gatilhos e catálogo de Habilidades.
* `AFFINITY.md` — Regras de afinidade tática entre cartas de uma mesma Facção.
* `BATTLEFIELDS.md` — Campos de Batalha e seus efeitos.

### 4. Cartas e Progressão

Módulos dedicados às entidades colecionáveis e sua evolução.

* `CARD.md` — Estrutura e propriedades formais das cartas.
* `CARD_CATALOG.md` — Catálogo de conteúdo: a ficha de cada carta existente. Descreve conteúdo, não cria regras (as regras pertencem a `CARD.md`/`CARD_PROGRESSION.md`).
* `CARD_PROGRESSION.md` — Sistema de evolução de Tier e fusão de cópias.
* `LIBRARY.md` — Biblioteca de coleção do jogador (interface conceitual).
* `LIBRARY_CONTENT.md` — Conteúdo/receitas de referência da Biblioteca.

### 5. Comandantes, Exércitos e Centro de Comando

Módulos dedicados à liderança, geração procedural de Comandantes, recrutamento e organização militar.

* `COMMANDERS.md` — Regras formais, patentes e coleção de Comandantes.
* `COMMANDER_GENERATION.md` — Fluxo oficial de geração procedural de Comandantes.
* `COMMANDER_RESTRICTIONS.md`, `COMMANDER_REQUIREMENTS.md`, `COMMANDER_TARGETS.md`, `COMMANDER_EFFECTS.md`, `COMMANDER_VALUES.md` — Os 5 Bancos Oficiais consumidos pelo motor de geração descrito em `COMMANDER_GENERATION.md`.
* `ARMY.md` — Estrutura do Exército, Formações e Trava de Edição por Modo de Jogo.
* `SOLDO.md` — Regras de Soldo e limites de composição de Exércitos.
* `COMMAND_CENTER.md` — Estados administrativos e organização do Centro de Comando.
* `COMMAND_CENTER_PROGRESS.md` — Progressão estrutural do Centro de Comando (Infraestrutura/Recursos Administrativos).
* `COMMAND_CENTER_RECRUITMENT.md` — Recrutamento de Comandantes.
* `COMMAND_CENTER_TRAINING.md` — Treinamento de Comandantes.
* `COMMAND_CENTER_LEGACY.md` — Aposentadoria: Legado Administrativo e Grande Legado Militar.
* `COMMAND_CENTER_UI.md` — Especificação das janelas de interface do Centro de Comando (PvP, Minas, PvE, Treinamento, Legado, Comandantes).

### 6. Infraestrutura do Reino (Cidade)

Módulos dedicados à progressão urbana e capacidade permanente do Reino.

* `CITY.md` — Organização arquitetural e conceitual da Cidade.
* `CAPITAL.md` — Regras e limites de expansão da Capital.
* `ACADEMY.md` — Produção e Aprimoramento de cartas.
* `ENERGY_NUCLEUS.md` — Capacidade e taxa de recuperação de Energia.
* `ENERGY.md` — Sistema de Energia dos Exércitos (consumo, fontes, recuperação).
* `DEPOSITS.md` — Armazenamento dos Recursos de Construção (Depósito único, três recursos).
* `MINES.md` — Conquista territorial e extração de Recursos de Construção.
* `OBSERVATORY.md` — Observatório da Cidade.

### 7. Economia e Progressão Global

Módulos que regem a matemática financeira, recursos e progressão permanente da Conta.

* `RESOURCES.md` — Tipos, origens e utilidade dos recursos do jogo (Fragmentos, VRP/VRG).
* `GENERATION_POINTS.md` — Pontos de Geração (PG): recurso global de infraestrutura, fonte (XP → PG) e sistemas consumidores.
* `XP.md` — Sistema de Experiência do Comandante e da Conta (Reino).
* `FORMULAS.md` — Curvas matemáticas, fórmulas de custo e Coeficiente Econômico Global (CEG).
* `BALANCING_SIMULATION.md` — Simulações de calibração de balanceamento; registra os parâmetros `b`/`x` atualmente vigentes por construção.

### 8. Modos de Jogo e Competição

Módulos que especificam as regras de partida e progressão pelos modos de jogo.

* `PvE.md` — Estrutura de Campanha: Territórios, Trilhas, Fases, Acampamentos, Chefes.
* `MATCHMAKING.md` — Algoritmo e regras de pareamento de partidas PvP.
* `RANKING.md` — Ligas, Divisões e pontuação competitiva.
* `SEASONS.md` — Ciclos temporais de Temporada e expansão permanente do mundo.

### 9. Onboarding

* `TUTORIAL.md` — Especificação do fluxo de tutorial do jogador.
* `TUTORIAL_REVIEW.md` — Revisão/apontamentos sobre o tutorial. Documento de revisão, não redefine regras já estabelecidas em `TUTORIAL.md`.

---

## Relação com as Demais Áreas do Repositório

Esta seção apenas resume — não substitui — a hierarquia de autoridade oficial definida em `PROJECT_INDEX.md` (raiz do projeto).

* **`Arquitetura/`** (este diretório): fonte única de verdade das regras de jogo atuais. É o único diretório que este documento organiza em detalhe.
* **`Fundation/`**: diretrizes de produção e arte (bíblias visuais, layouts de interação, catálogos de arte). Explica *como construir/apresentar* um sistema — nunca sobrepõe silenciosamente uma regra de jogo definida em `Arquitetura/`.
* **`Game/`**: implementação em Godot/GDScript das regras definidas em `Arquitetura/`. Código é evidência do estado atual da implementação, nunca autoridade sobre a regra documentada.
* **`Assets/`**: arquivos de arte e recursos de produção atualmente entregues.
* **`Ideias/`**: propostas futuras, não-canônicas. Sem autoridade sobre o jogo atual até promoção explícita.

Em caso de dúvida sobre qual diretório é autoritativo para uma dada pergunta, `PROJECT_INDEX.md` prevalece sobre este resumo.

---

## Convenções da Documentação

Todo documento técnico de sistema deve adotar a seguinte estrutura padronizada de seções:

1. **Título do Documento:** Nome oficial do módulo/sistema.
2. **Objetivo:** Declaração sucinta do propósito do documento no jogo.
3. **Responsabilidade do Documento:** Lista explícita do que o documento especifica (SSOT) e do que ele **não** define (com redirecionamentos).
4. **Funcionamento/Filosofia:** Explica o funcionamento conceitual do sistema e suas relações principais com os demais módulos do jogo (sem implementação de código).
5. **Regras:** Definições formais, invariantes e limitações do sistema.
6. **Regras Permanentes:** Diretrizes arquiteturais imutáveis que regem o módulo.
7. **Referências:** Lista de links para os documentos correlatos.

---

## Princípios de Manutenção

* **Inexistência de Duplicidade:** Se uma regra já estiver definida em seu documento proprietário, nenhum outro arquivo deve repeti-la; deve-se utilizar apenas uma referência formal (ex: `Ver: SOLDO.md`).
* **Expansão sem Quebra:** Novos sistemas devem ser adicionados através de novos arquivos Markdown, registrando-os neste documento sem alterar a estrutura dos arquivos existentes.
* **Consistência Atemporal:** Alterações nas regras do jogo atualizam o documento proprietário da mecânica, mantendo a estrutura deste guia de organização estável e atemporal.
* **Este documento reflete o repositório real:** nenhuma entrada aqui deve referenciar um arquivo que não existe em `Arquitetura/`. Ao criar um novo documento de arquitetura, adicione-o aqui na mesma alteração.

---

## Referências

* **PROJECT_INDEX.md** (raiz do projeto) — Mapa de roteamento canônico entre todas as áreas do repositório e hierarquia de autoridade.
* **DECISOES.md** — Políticas de desenvolvimento, regras de agentes de IA e convenções de congelamento de documentos.
* **GLOSSARY.md** — Definições conceituais da terminologia oficial do projeto.
* **GAME_PHILOSOPHY.md** — Princípios gerais de design e experiência do jogo.
