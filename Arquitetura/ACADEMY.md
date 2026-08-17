# ACADEMY.md


# Academia


Objetivo:

A Academia é a construção responsável pela criação e evolução de Cartas através de dois sistemas independentes: a criação de novas Cartas Tier I realizada pelos Artífices e o Aprimoramento de Cartas existentes realizado pelos Metamorfos. A produção de Cartas Tier I pode utilizar fragmentos, Cartas Tier I existentes ou uma combinação de ambos, dependendo da estratégia de Origem dos Ingredientes definida pelo jogador. A Academia funciona como a interface visual para essas operações e possui progressão própria que afeta o tempo e a capacidade de produção.

Para a obtenção de fragmentos, ver RESOURCES.md.
Para consulta enciclopédica de Cartas e receitas, ver LIBRARY.md.

## Fluxo Geral

Solicitação da Produção

↓

Origem dos Ingredientes

↓

Modo de Produção

↓

Produção Automática

↓

Artífices

↓

Carta Tier I

↓

Metamorfos

↓

Aprimoramento

↓

Carta Tier II

↓

Aprimoramento

↓

Carta Tier III

↓

Aprimoramento

↓

Carta Tier IV

↓

Aprimoramento

↓

Carta Tier V

---

## Princípios da Academia

A progressão da Academia é independente dos demais sistemas do Reino e não duplica os gates existentes (como fragmentos por facção ou Tier máximo por Patente). Ela não determina o que o jogador pode produzir, mas sim a velocidade e a capacidade de produção simultânea.

A Academia nunca impede o acesso a uma Carta por falta de paralelismo. Jogadores com menos Mestres produzem as mesmas Cartas utilizando mais tempo. Jogadores com maior infraestrutura reduzem esse tempo através da produção paralela.

---

## Estrutura e Operação

A Academia é dividida em dois setores independentes, cada um operado por mestres especializados. O termo "slot" refere-se à representação visual de um Mestre disponível para o trabalho.

### Glossário Interno

* **Artífice:** Mestre responsável pela criação de Cartas Tier I.
* **Metamorfo:** Mestre responsável pelos processos de Aprimoramento, elevando Cartas de um Tier ao imediatamente superior.
* **Fila:** Sequência de tarefas programadas para um Mestre específico.
* **Produção Automática:** Sistema que gerencia a cadeia de dependências para a criação de Cartas superiores.

---

## Progressão da Academia

A Academia possui progressão até o **Nível Máximo de 120**.

### Custo de Evolução

O custo de evolução da Academia segue a fórmula geral única de construções (`FORMULAS.md`): C(n) = CEG × (b + n² + xn). Os valores **atualmente vigentes** de $b$ e $x$ são definidos e mantidos em `BALANCING_SIMULATION.md` — múltiplas simulações podem calcular diferentes pares de $b$/$x$ ao longo do tempo, mas apenas um par é o vigente a qualquer momento, sempre marcado explicitamente como tal naquele documento.

### Redução de Tempo (Progressão Vertical)

A redução de tempo afeta tanto a criação de Cartas (Artífices) quanto o Aprimoramento (Metamorfos). A redução é de **0,5 ponto percentual por nível da Academia**, com limite máximo de **60%**.

Tabela de Marcos de Redução de Tempo

| Nível da Academia | Redução de Tempo |
| --- | --- |
| 1 | 0% |
| 20 | 10% |
| 40 | 20% |
| 60 | 30% |
| 80 | 40% |
| 100 | 50% |
| 120 | 60% |

*A progressão é linear entre os marcos.*

### Capacidade de Produção (Progressão Horizontal)

Novos Mestres (Artífices e Metamorfos) tornam-se disponíveis automaticamente quando determinados níveis da Academia são alcançados, aumentando a capacidade de produção paralela.

Desbloqueio de Artífices

| Nível da Academia | Total de Artífices |
| --- | --- |
| 1 | 1 |
| 4 | 2 |
| 8 | 3 |
| 12 | 4 |
| 20 | 5 |
| 28 | 6 |
| 36 | 7 |
| 44 | 8 |
| 52 | 9 |
| 60 | 10 |
| 68 | 11 |
| 76 | 12 |
| 84 | 13 |
| 92 | 14 |
| 100 | 15 |
| 108 | 16 |
| 116 | 17 |

Desbloqueio de Metamorfos

| Nível da Academia | Total de Metamorfos |
| --- | --- |
| 1 | 1 |
| 3 | 2 |
| 6 | 3 |
| 9 | 4 |
| 12 | 5 |
| 18 | 6 |
| 24 | 7 |
| 30 | 8 |
| 36 | 9 |
| 42 | 10 |
| 48 | 11 |
| 54 | 12 |
| 60 | 13 |
| 66 | 14 |
| 72 | 15 |
| 78 | 16 |
| 84 | 17 |
| 90 | 18 |
| 96 | 19 |
| 102 | 20 |
| 108 | 21 |
| 114 | 22 |
| 120 | 23 |

---

## Produção de Cartas

### Salão dos Artífices

Os Artífices são responsáveis pela criação de todas as Cartas Tier I, independentemente de sua raridade. Cartas Comuns, Raras, Épicas e Lendárias, todas no Tier I, são produzidas pelos Artífices (conversão de uma entrada para uma saída).

Fluxo: Ingredientes → Carta Tier I.

Tabela de Tempos de Criação (Nível Base)

| Raridade | Tempo de Criação |
| --- | --- |
| Comum | 2 minutos |
| Rara | 8 minutos |
| Épica | 20 minutos |
| Lendária | 60 minutos |

As receitas de criação podem ser visualizadas na LIBRARY.md.

### Receitas

Cartas superiores (Raras, Épicas e Lendárias) possuem receitas que exigem Cartas de raridades inferiores.

Receitas Oficiais

| Raridade Alvo | Receita |
| --- | --- |
| Rara | 3 Comuns |
| Épica | 2 Comuns + 1 Rara |
| Lendária | 1 Comum + 1 Rara + 1 Épica |

### Produção Automática

A Produção Automática é a mecânica oficial da Academia para a criação de Cartas superiores. O jogador pode solicitar diretamente qualquer Carta superior utilizando fragmentos, Cartas Tier I existentes ou uma combinação de ambos, respeitando a estratégia de Origem dos Ingredientes definida.

O sistema de Produção Automática é responsável por:

* identificar todas as receitas intermediárias;
* montar toda a cadeia de produção;
* reservar os recursos necessários;
* distribuir automaticamente as tarefas entre os Mestres;
* respeitar a estratégia de Origem dos Ingredientes;
* respeitar o Modo de Produção escolhido;
* gerar automaticamente toda a programação necessária até a conclusão da Carta solicitada.

Nenhuma etapa intermediária precisa ser criada manualmente pelo jogador.

**Consumo e Reserva de Recursos:** Os fragmentos e as Cartas Tier I utilizados pela produção são reservados no momento em que cada etapa entra na fila de produção. Enquanto permanecerem reservados, esses recursos não poderão ser utilizados por nenhum outro sistema. Dessa forma, a cadeia de produção não pode ser interrompida posteriormente por falta de recursos.

**Dependências entre Receitas:** Uma etapa somente inicia quando todas as Cartas exigidas pela receita estiverem prontas.

**Exemplo de Dependências:** Produzir uma Épica

1. Produzir 3 Comuns
2. Produzir 1 Rara (após etapa 1)
3. Produzir 2 Comuns (após etapa 1. Pode ocorrer em paralelo com etapa 2, se houver Mestre livre)
4. Produzir Épica (após etapas 2 e 3)

### Origem dos Ingredientes

Ao solicitar uma produção, o jogador escolhe inicialmente uma estratégia global para utilização dos ingredientes da receita. Existem duas estratégias oficiais.

#### Aproveitar Inventário

Sempre que possível, a Academia utiliza Cartas Tier I já existentes no inventário do jogador. As Cartas faltantes são produzidas automaticamente utilizando fragmentos.

#### Preservar Inventário

A Academia ignora as Cartas Tier I existentes e produz toda a receita utilizando fragmentos.

#### Editar Receita

Após selecionar a estratégia global da Origem dos Ingredientes, o jogador pode editar individualmente qualquer ingrediente da receita. Cada ingrediente pode possuir uma origem diferente:

* Utilizar Carta existente; ou
* Produzir utilizando fragmentos.

As alterações realizadas manualmente possuem prioridade sobre a estratégia global escolhida. Enquanto uma personalização existir, mudanças posteriores na estratégia global não alteram aquele ingrediente específico. Sempre que o jogador altera manualmente um ingrediente, a Academia recalcula automaticamente toda a cadeia de produção, os recursos necessários, o tempo estimado, a distribuição entre Mestres e a previsão apresentada ao jogador.

### Modos de Produção

O jogador escolhe apenas o objetivo da produção. A distribuição respeita as dependências entre receitas, a ordem das filas, a Origem dos Ingredientes e o Modo de Produção escolhido. Toda a distribuição é realizada automaticamente pela Academia; o jogador nunca escolhe quais Mestres executarão cada etapa.

#### Modo Conservador

Objetivo: Preservar capacidade produtiva.
A Academia utiliza apenas a quantidade de Mestres necessária para executar a produção, mantendo os demais disponíveis sempre que possível. Ideal quando o jogador pretende realizar várias produções simultaneamente.

#### Modo Prioritário

Objetivo: Concluir a produção no menor tempo possível.
A Academia distribui automaticamente as tarefas entre todos os Mestres disponíveis, otimizando o paralelismo e respeitando o fluxo de dependências. Ideal quando determinada produção possui prioridade.

### Previsão da Produção

Antes da confirmação de uma produção, a Academia apresenta automaticamente uma previsão contendo:

* tempo estimado;
* Modo de Produção;
* estratégia de Origem dos Ingredientes;
* quantidade de Artífices utilizados;
* quantidade de Metamorfos utilizados (quando houver Aprimoramento);
* fragmentos necessários;
* Cartas existentes que serão consumidas;
* Cartas que precisarão ser produzidas;
* resumo completo da cadeia de produção.

Toda essa informação possui finalidade exclusivamente informativa.

---

## Aprimoramento

### Salão dos Metamorfos

Os Metamorfos são responsáveis exclusivamente pelos processos de Aprimoramento, elevando Cartas existentes do Tier I até o Tier V. Nenhuma Carta Tier I é produzida pelos Metamorfos.

Fluxo: Carta Tier I → Aprimoramentos sucessivos → Carta Tier V.

### Tempos de Aprimoramento

Tabela de Tempos de Aprimoramento (Nível Base)

| Tier Alvo | Comum | Rara | Épica | Lendária |
| --- | --- | --- | --- | --- |
| II | 30 min | 1 h | 2 h | 4 h |
| III | 2 h | 4 h | 8 h | 16 h |
| IV | 8 h | 12 h | 24 h | 48 h |
| V | 24 h | 36 h | 60 h | 96 h |

### Regras do Aprimoramento

* O Aprimoramento consome exclusivamente três Cartas idênticas do mesmo Tier para gerar uma única Carta no Tier imediatamente superior.
* Todas as Cartas utilizadas no Aprimoramento permanecem indisponíveis para qualquer outro sistema do jogo até a conclusão do processo.

---

## Gerenciamento da Produção

### Monitoramento da Produção

Durante a execução da produção, a Academia apresenta ao jogador:

* Mestres ocupados;
* tarefa executada por cada Mestre;
* fila individual de cada Mestre;
* tempo restante;
* percentual concluído;
* etapas aguardando dependências.

Essas informações possuem finalidade exclusivamente informativa e não alteram nenhuma regra do sistema.

### Resolução da Produção

Sempre que houver um ou mais Mestres livres, a Academia tenta iniciar automaticamente todas as tarefas aptas à execução. Se existirem várias tarefas disponíveis na Fila daquele Mestre, será respeitada a ordem da fila. Caso uma tarefa possua dependências ainda não concluídas, ela permanece aguardando até que todos os requisitos sejam satisfeitos.

---

## Filas de Produção

Cada Mestre possui sua própria fila, que representa tarefas programadas. O Mestre executa apenas uma tarefa por vez; ao concluir uma tarefa, inicia automaticamente a próxima da fila. A capacidade da fila não altera o número de tarefas simultâneas executadas por um Mestre. As filas não reduzem tempo e não alteram receitas, apenas automatizam a sequência das produções.

Enquanto uma tarefa ainda não iniciou sua execução, é possível alterar sua ordem, removê-la ou cancelar a programação. Após iniciada, passam a valer as regras normais de produção ou Aprimoramento.

### Melhorias das Filas

As melhorias das filas são permanentes e adquiridas individualmente para cada Mestre utilizando Pontos de Geração (PG) — o mesmo recurso global de infraestrutura do Reino usado por Minas, Depósitos e Centro de Comando (ver `GENERATION_POINTS.md`). Cada Mestre possui sua própria fila e sua própria progressão de melhorias. As melhorias de um Mestre nunca afetam outro Mestre, mesmo sendo do mesmo tipo.

Fila inicial para todos os Mestres: 1 tarefa.

#### Filas dos Artífices

Melhorias de Capacidade:

* Capacidade 2 → 2 PG
* Capacidade 3 → 4 PG
* Capacidade 4 → 8 PG
* Capacidade 5 → 16 PG
* Capacidade 6 → 32 PG

#### Filas dos Metamorfos

Melhorias de Capacidade:

* Capacidade 2 → 2 PG
* Capacidade 3 → 8 PG
* Capacidade 4 → 32 PG