# PROJECT_STRUCTURE.md

# Estrutura do Projeto

## Objetivo

Este documento define a organização oficial da documentação de Battle Simulator.

Seu objetivo é:

- organizar toda a documentação do projeto;
- definir responsabilidades entre os documentos;
- evitar duplicação de informações;
- estabelecer um padrão para criação de novos documentos;
- facilitar futuras expansões do jogo.

Este documento não define mecânicas de jogo.

Sua função é exclusivamente organizar e padronizar toda a documentação do projeto.

---

# Filosofia da Documentação

A documentação de Battle Simulator segue os mesmos princípios utilizados no desenvolvimento do jogo:

- simplicidade na leitura;
- profundidade na implementação;
- modularidade;
- reutilização de informações;
- facilidade de manutenção.

Sempre que possível, cada sistema deve possuir um único documento responsável.

Novas funcionalAqui está a revisão final do documento `PROJECT_STRUCTURE.md`, com as correções de nomenclatura, ajustes de *ownership* e atualização da sequência de leitura aplicados rigorosamente, sem alterar a estrutura geral ou a finalidade do arquivo.

---

# PROJECT_STRUCTURE.md

# Estrutura e Organização da Documentação

## Objetivo

Este documento define a organização oficial, a taxonomia e a estrutura de diretórios de toda a documentação técnica do projeto Battle Simulator.

Seu objetivo é servir como o mapa arquitetural da documentação, garantindo que cada sistema, mecânica ou diretriz possua uma localização única, delimitada e identificável (*Single Source of Truth*).

Este documento **não** define regras de jogo, fórmulas, parâmetros econômicos ou mecânicas de combate.

---

## Responsabilidade do Documento

Este documento é a Fonte Única de Verdade (*Single Source of Truth*) para:

* A árvore oficial de documentos do projeto;
* A categorização e agrupamento conceitual dos arquivos `/docs`;
* As convenções de nomenclatura e padrão de estrutura dos arquivos de documentação;
* A ordem recomendada de leitura e dependência arquitetural;
* Os princípios de modularidade, escopo e governança documental.

Este documento **não** define:

* Decisões formais de desenvolvimento e regras de agentes (`DECISOES.md`);
* Glossário e termos oficiais do projeto (`GLOSSARY.md`);
* Regras, balanceamento ou funcionamento interno de qualquer sistema de jogo.

---

## Filosofia da Estrutura

A documentação do Battle Simulator é projetada sob os seguintes pilares:

1. **Modularidade:** Cada subsistema do jogo é documentado em um arquivo próprio e independente.
2. **Ownership Único:** Cada domínio de conhecimento possui exatamente um documento responsável.
3. **Baixo Acoplamento:** Módulos se conectam via referências formais, sem duplicar conceitos entre arquivos.
4. **Escalabilidade:** A inclusão de novas mecânicas ou modos de jogo ocorre pela adição de novos documentos, sem a necessidade de reestruturar os arquivos existentes.

---

## Estrutura Oficial da Documentação

Os documentos do projeto estão organizados rigorosamente nos seguintes grupos conceituais:

### 1. Governança Arquitetural

Documentos institucionais que estabelecem as regras de desenvolvimento, documentação e manutenção do projeto (não definem mecânicas de jogo).

* `PROJECT_STRUCTURE.md` — Mapa oficial e diretrizes da documentação.
* `DECISOES.md` — Registro oficial de decisões arquiteturais (*ADR*), políticas e convenções de desenvolvimento.

### 2. Visão e Filosofia

Documentos de fundamentação conceitual, direção de design e linguagem oficial.

* `GAME_PHILOSOPHY.md` — Filosofia de design, pilares de balanceamento e diretrizes de experiência do jogador.
* `GLOSSARY.md` — Dicionário técnico e convenções linguísticas oficiais do projeto.
* `DESIGN.md` — Diretrizes de design de interface e experiência visual/conceitual.
* `LORE.md` — Contexto narrativo, temática e universo do jogo.

### 3. Sistemas Centrais e Combate

Módulos que especificam o funcionamento do motor de simulação e regras de batalha.

* `COMBAT_CORE.md` — Especificação do motor e matemática base de combate.
* `COMBAT_RULES.md` — Regras de engajamento, alvos e cálculo de dano.
* `ABILITIES.md` — Mecânicas, gatilhos e catálogo de habilidades.

### 4. Coleção e Progressão de Cartas

Módulos dedicados às entidades colecionáveis e sua evolução.

* `CARD.md` — Estrutura e propriedades formais das cartas.
* `CARD_PROGRESSION.md` — Sistema de evolução e fusão de cópias de cartas.
* `AFFINITY.md` — Regras de sinergia e afinidades táticas.

### 5. Comandantes e Administração Militar

Módulos dedicados à liderança, recrutamento e teto de exércitos.

* `COMMANDERS.md` — Regras formais, recrutamento, restrições e vantagens dos Comandantes.
* `SOLDO.md` — Regras de Soldo, composição de Exércitos e limites de Soldo.

### 6. Infraestrutura do Reino (Cidade)

Módulos dedicados à progressão urbana e capacidade permanente do Reino.

* `CITY.md` — Organização arquitetural e conceitual da Cidade.
* `CAPITAL.md` — Regras e limites de expansão da Capital.
* `COMMAND_CENTER.md` — Limites estruturais da administração militar e reserva.
* `ACADEMY.md` — Pesquisa tecnológica e desenvolvimento do Reino.
* `ENERGY_NUCLEUS.md` — Gerenciamento e capacidade do sistema de energia.
* `DEPOSITS.md` — Armazenamento e proteção dos recursos de construção.

### 7. Economia e Progressão Global

Módulos que regem a matemática financeira, recursos e níveis da conta.

* `RESOURCES.md` — Tipos, origens e utilidade dos recursos do jogo.
* `XP.md` — Sistema de experiência do Comandante e do Reino (Estrutural e Operacional).
* `FORMULAS.md` — Curvas matemáticas, fórmulas de custo e Coeficiente Econômico Global (CEG).

### 8. Modos de Jogo e Competição

Módulos que especificam as interfaces de jogo e regras de partida.

* `PvE.md` — Estrutura de campanhas, trilhas, fases e chefes.
* `MATCHMAKING.md` — Algoritmo e regras de pareamento de partidas PvP.
* `RANKING.md` — Ligas, divisões e pontuação competitiva.
* `MINES.md` — Conquista territorial e extração de recursos no mapa.
* `SEASONS.md` — Ciclos temporais de temporada e expansão permanente do mundo.

---

## Convenções da Documentação

Todo documento técnico de sistema deve adotar a seguinte estrutura padronizada de seções:

1. **Título do Documento:** Nome oficial do módulo/sistema.
2. **Objetivo:** Declaração sucinta do propósito do documento no jogo.
3. **Responsabilidade do Documento:** Lista explícita do que o documento especifica (SSOT) e do que ele **não** define (com redirecionamentos).
4. **Funcionamento:** Explica o funcionamento conceitual do sistema e suas relações principais com os demais módulos do jogo (sem implementação de código).
5. **Regras:** Definições formais, invariantes e limitações do sistema.
6. **Regras Permanentes:** Diretrizes arquiteturais imutáveis que regem o módulo.
7. **Referências:** Lista de links para os documentos correlatos.

---

## Ordem Recomendada de Leitura

Para compreender a arquitetura completa do Battle Simulator de forma lógica e incremental, recomenda-se a seguinte sequência de leitura:

```
[1. Governança & Fundamentos]
   ├── PROJECT_STRUCTURE.md
   ├── DECISOES.md
   ├── GLOSSARY.md
   └── GAME_PHILOSOPHY.md

[2. Motor de Combate (Núcleo)]
   ├── COMBAT_CORE.md
   ├── COMBAT_RULES.md
   └── ABILITIES.md

[3. Coleção & Liderança]
   ├── CARD.md
   ├── CARD_PROGRESSION.md
   ├── COMMANDERS.md
   └── SOLDO.md

[4. Infraestrutura & Economia]
   ├── RESOURCES.md
   ├── FORMULAS.md
   ├── CITY.md
   └── XP.md

[5. Modos de Jogo & Competição]
   ├── PvE.md
   ├── MATCHMAKING.md
   ├── MINES.md
   └── SEASONS.md

```

---

## Princípios de Manutenção

* **Inexistência de Duplicidade:** Se uma regra já estiver definida em seu documento proprietário, nenhum outro arquivo deve repeti-la; deve-se utilizar apenas uma referência formal (ex: `Ver: SOLDO.md`).
* **Expansão sem Quebra:** Novos sistemas devem ser adicionados através de novos arquivos Markdown, registrando-os neste documento sem alterar a estrutura dos arquivos existentes.
* **Consistência Atemporal:** Alterações nas regras do jogo atualizam o documento proprietário da mecânica, mantendo a estrutura deste guia de organização estável e atemporal.

---

## Referências

* **DECISOES.md:** Políticas de desenvolvimento, regras de agentes de IA e congelamento de documentos.
* **GLOSSARY.md:** Definições conceituais da terminologia oficial do projeto.
* **GAME_PHILOSOPHY.md:** Princípios gerais de design e experiência do jogo.idades devem reutilizar sistemas existentes antes de criar novas regras.

---

# Organização da Documentação

A documentação está organizada por sistemas independentes.

Cada sistema possui um documento principal responsável por definir suas regras.

## 1. Visão do Projeto

Define a identidade do jogo.

Documentos:

- VISION.md
- DESIGN.md
- LORE.md
- GLOSSARY.md

---

## 2. Mecânicas Centrais

Responsáveis pelas regras fundamentais do jogo.

Documentos:

- COMBAT_CORE.md
- COMBAT_RULES.md
- ABILITIES.md
- ENERGY.md
- ENERGY_NUCLEUS.md
- FORMULAS.md
- XP.md

---

## 3. Cartas

Responsáveis pelas unidades do jogo.

Documentos:

- CARD.md
- CARD_CATALOG.md
- CARD_PROGRESSION.md
- FACTION_IDENTITY.md
- FACTION_DESIGN.md

---

## 4. Comandantes

Responsáveis pelo sistema completo de comandantes.

Documentos:

- COMMANDERS.md
- COMMAND_CENTER.md
- COMMAND_CENTER_TRAINING.md
- ACADEMY.md
- LEGACY.md
- SOLDO.md

---

## 5. Cidade

Responsáveis pela progressão permanente do Reino.

Documentos:

- CITY.md
- CAPITAL.md
- MINES.md
- DEPOSITS.md
- OBSERVATORY.md
- RESOURCES.md

---

## 6. Modos de Jogo

Documentos responsáveis pelos diferentes modos disponíveis.

Documentos:

- GAME_LOOP.md
- PvE.md
- MATCHMAKING.md
- BATTLEFIELDS.md
- SEASONS.md

---

## 7. Desenvolvimento

Documentação utilizada durante o desenvolvimento do projeto.

Documentos:

- ROADMAP.md
- IMPLEMENTATION_ROADMAP.md
- MVP_TEST_PLAN.md
- CHANGELOG.md
- TODO.md
- RELATORIO_DE_BALANCEAMENTO.md

---

# Princípios da Documentação

## 1. Fonte Única da Verdade

Cada sistema possui exatamente um documento responsável por definir suas regras.

Todos os demais documentos devem apenas referenciar esse documento.

Exemplo:

As regras de Tier pertencem exclusivamente ao CARD_PROGRESSION.md.

Nenhum outro documento deve redefinir essas regras.

---

## 2. Um Sistema, Um Documento

Cada documento deve possuir uma responsabilidade clara.

Sempre que possível, um documento deve responder apenas por um único sistema.

---

## 3. Catálogos não criam regras

Catálogos descrevem conteúdo.

Nunca definem mecânicas.

Exemplo:

CARD_CATALOG.md descreve cartas.

As regras pertencem a CARD.md.

---

## 4. O Glossário é a referência oficial

Todos os termos utilizados na documentação devem seguir as definições presentes em GLOSSARY.md.

Novas definições devem ser adicionadas exclusivamente ao Glossário.

---

## 5. Referenciar é melhor do que repetir

Sempre que uma informação já estiver documentada em outro arquivo, deve-se utilizar uma referência ao documento oficial.

Evitar copiar regras entre documentos.

---

## 6. Inconsistências devem ser corrigidas

Caso duas definições diferentes sejam encontradas para o mesmo sistema, considera-se que a documentação está inconsistente.

A inconsistência deve ser corrigida.

Nunca deve existir mais de uma definição válida para uma mesma regra.

---

## 7. Documentos devem evoluir de forma independente

Sempre que um sistema puder evoluir independentemente dos demais, ele deve possuir documentação própria.

Isso reduz retrabalho e facilita futuras expansões.

---

# Critérios para Criação de Novos Documentos

Um novo documento deve ser criado quando:

- o sistema possuir regras próprias;
- puder evoluir independentemente;
- for utilizado por vários outros sistemas;
- tornar um documento existente excessivamente grande.

Não criar documentos apenas para separar conteúdo visualmente.

Criar documentos apenas quando existir ganho real de organização.

---

# Convenções da Documentação

Todos os documentos devem seguir, sempre que possível, a estrutura abaixo.

## Objetivo

Explica por que aquele sistema existe.

---

## Funcionamento

Explica como o sistema funciona.

---

## Regras

Define todas as regras oficiais do sistema.

---

## Observações

Informações complementares.

Utilizar apenas quando necessário.

---

## Referências

Sempre que um sistema depender de outro documento, a referência deve ser feita ao documento oficial.

---

# Processo de Manutenção da Documentação

Sempre que uma regra for alterada, deve-se seguir obrigatoriamente o processo abaixo.

## 1.

Alterar o documento responsável pela regra.

---

## 2.

Identificar todos os documentos que fazem referência a essa regra.

---

## 3.

Revisar esses documentos.

---

## 4.

Corrigir eventuais inconsistências.

---

## 5.

Atualizar exemplos, quando necessário.

---

## 6.

Caso a alteração torne um documento excessivamente grande ou gere um novo sistema independente, avaliar a criação de um novo documento.

---

# Estrutura Atual do Projeto

## Visão

- VISION.md
- DESIGN.md
- LORE.md
- GLOSSARY.md

---

## Mecânicas

- COMBAT_CORE.md
- COMBAT_RULES.md
- ABILITIES.md
- ENERGY.md
- FORMULAS.md
- XP.md

---

## Cartas

- CARD.md
- CARD_CATALOG.md
- CARD_PROGRESSION.md
- FACTION_IDENTITY.md

---

## Comandantes

- COMMANDERS.md
- COMMAND_CENTER.md
- ACADEMY.md
- LEGACY.md
- SOLDO.md

---

## Cidade

- CITY.md
- CAPITAL.md
- MINES.md
- DEPOSITS.md
- OBSERVATORY.md
- RESOURCES.md

---

## Modos de Jogo

- GAME_LOOP.md
- PvE.md
- MATCHMAKING.md
- BATTLEFIELDS.md
- SEASONS.md

---

## Desenvolvimento

- ROADMAP.md
- IMPLEMENTATION_ROADMAP.md
- MVP_TEST_PLAN.md
- CHANGELOG.md
- TODO.md
- RELATORIO_DE_BALANCEAMENTO.md

---

# Ordem Recomendada de Leitura

Para compreender completamente Battle Simulator, recomenda-se a seguinte sequência:

## Etapa 1 — Visão Geral

1. VISION.md
2. GLOSSARY.md
3. DESIGN.md
4. LORE.md

---

## Etapa 2 — Mecânicas Centrais

5. ENERGY_NUCLEUS.md
6. COMBAT_CORE.md
7. COMBAT_RULES.md
8. ABILITIES.md
9. ENERGY.md
10. FORMULAS.md
11. XP.md

---

## Etapa 3 — Cartas

13. CARD.md
14. CARD_CATALOG.md
15. CARD_PROGRESSION.md
16. FACTION_IDENTITY.md

---

## Etapa 4 — Comandantes

17. COMMANDERS.md
18. COMMAND_CENTER.md
19. ACADEMY.md
20. LEGACY.md
21. SOLDO.md

---

## Etapa 5 — Cidade

22. CITY.md
23. CAPITAL.md
24. MINES.md
25. DEPOSITS.md
26. OBSERVATORY.md
27. RESOURCES.md

---

## Etapa 6 — Modos de Jogo

28. PvE.md
29. MATCHMAKING.md
30. BATTLEFIELDS.md
31. SEASONS.md

---

# Filosofia Final

Battle Simulator foi concebido para ser um jogo de alta profundidade estratégica com regras simples de compreender.

A documentação segue exatamente a mesma filosofia.

Cada documento deve possuir um propósito claro.

Cada sistema deve possuir uma única fonte oficial.

Sempre que possível, sistemas devem ser reutilizados em vez de duplicados.

Uma documentação bem organizada reduz inconsistências, facilita a implementação, simplifica o balanceamento e permite que novas temporadas sejam adicionadas sem necessidade de reestruturar o projeto.