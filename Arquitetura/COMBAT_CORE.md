```markdown
# COMBAT_CORE.md

## Objetivo

Este documento define a arquitetura do Sistema de Combate do Battle Simulator.

O combate representa o confronto entre dois exércitos organizados para cumprir um objetivo determinado por um modo de jogo.

Este documento descreve apenas a estrutura geral e as responsabilidades arquiteturais do sistema. As regras operacionais de dano, turnos, habilidades, prioridades e demais mecânicas são definidas exclusivamente no documento `COMBAT_RULES.md`.

## Filosofia

O Sistema de Combate é o módulo responsável por resolver os confrontos entre exércitos.

Ele opera sobre entidades existentes e não é responsável por sua criação ou modificação permanente. O sistema não gera unidades, não altera a identidade dos Comandantes, não modifica permanentemente as Cartas e não determina a progressão do Reino.

Sua única responsabilidade consiste em coordenar a interação entre exércitos durante uma batalha e produzir um resultado válido para os demais sistemas do jogo.

## Arquitetura do Sistema

A representação estrutural abaixo descreve a hierarquia dos grandes conceitos do Sistema de Combate, sem antecipar regras operacionais:

```text
Sistema de Combate
│
├── Batalha (Confronto Específico)
│   ├── Estados (Preparação, Execução, Conclusão)
│   └── Condições de Encerramento
│
├── Turnos (Unidade de Tempo)
│
├── Eventos 
│
└── Resultado (Dados para Terceiros)

```

## Princípios Arquiteturais

Todo o Sistema de Combate obedece aos seguintes princípios arquiteturais permanentes:

* **Separação de Responsabilidades:** O Sistema de Combate coordena a batalha, enquanto as regras operacionais pertencem aos módulos especializados, especialmente ao `COMBAT_RULES.md`.
* **Escopo Definido:** O Sistema de Combate apenas resolve confrontos entre exércitos.
* **Não-Criador:** O sistema não cria Cartas, Comandantes ou Exércitos.
* **Imutabilidade Externa:** O sistema não altera permanentemente Cartas ou Comandantes.
* **Preparação Estratégica:** Todas as decisões estratégicas de composição e posicionamento ocorrem antes do início da batalha.
* **Determinismo:** O combate é determinístico; dadas as mesmas condições iniciais, o resultado é sempre o mesmo.
* **Resultado Consumível:** O sistema entrega um resultado estruturado para consumo pelos demais sistemas.

## Definição de Batalha

Uma batalha representa o confronto entre dois exércitos organizados. Cada exército é composto por:

* Um Comandante;
* Formações Militares (Cartas);
* Energia disponível;
* Uma Doutrina Militar.

Durante a batalha, ambos os exércitos interagem conforme os parâmetros e fluxos definidos pelo sistema.

## Participantes

Toda batalha envolve cinco elementos fundamentais.

### Exército

O Exército constitui a principal entidade de combate. Todas as demais estruturas pertencem a um dos exércitos participantes.

### Comandante

O Comandante lidera o Exército. Sua Doutrina Militar influencia o comportamento das formações durante a batalha. O Comandante nunca participa diretamente do combate.

### Pelotões (Formações Militares)

Os Pelotões são as instâncias operacionais geradas a partir das Cartas que executam todas as ações no Combat State durante a batalha, sendo responsáveis por atacar, defender, utilizar habilidades, ocupar posições e sofrer dano.

### Campo de Batalha

O Campo de Batalha é a entidade que organiza espacialmente as Formações Militares. Sua estrutura define posicionamento, linhas e as relações espaciais entre as unidades.

### Sistema de Combate

Coordena toda a execução da batalha. É responsável por controlar a sequência de turnos, a aplicação das regras operacionais (definidas em `COMBAT_RULES.md`), a resolução de eventos e a verificação das condições de encerramento.

## Fluxo Macro

O fluxo geral abaixo representa a arquitetura da batalha, partindo da entidade principal e detalhando os subprocessos:

```text
Batalha
│
↓
Preparação
│
├── Validação dos Exércitos
│
└── Aplicação das Doutrinas
│
↓
Execução
│
├── Processamento de Turnos
│
├── Resolução de Eventos
│
└── Verificação das Condições de Encerramento
│
↓
Conclusão
│
└── Geração de Dados Estruturados
│
↓
Resultado
│
└── Retorno aos Sistemas Consumidores

```

## Estados da Batalha

Toda batalha transita por três estados:

### Preparação

Etapa anterior ao processamento de turnos. Inclui a validação do Exército, verificação de Energia, posicionamento e validação da formação. Nenhuma regra operacional de combate é aplicada neste estado.

### Execução

Período em que a sequência de turnos e eventos é processada. Todas as ações seguem as regras operacionais definidas no `COMBAT_RULES.md`.

### Conclusão

Após o encerramento da fase de execução. O sistema registra os resultados e devolve as informações estruturadas aos demais módulos do jogo.

## Condições de Encerramento

Uma batalha termina quando uma condição definida pelo modo de jogo é satisfeita.

Exemplos incluem:

* Destruição completa de um Exército;
* Cumprimento de um objetivo de missão;
* Alcance de um limite máximo de turnos;
* Condição especial do cenário.

As condições específicas operacionais pertencem exclusivamente aos respectivos modos de jogo ou regras operacionais.

## Resultado da Batalha

Ao término do combate, o Sistema de Combate gera um relatório estruturado para consumo de outros sistemas. Este relatório contém, entre outras informações:

* Identificação do Vencedor e Derrotado;
* Duração e quantidade de turnos;
* Estatísticas gerais;
* Eventos relevantes.

Estes dados serão utilizados pelos sistemas responsáveis por recompensas, progressão e histórico.

## Integração com Outros Sistemas

Arquiteturalmente, a integração do Sistema de Combate é organizada da seguinte forma:

**Recebe informações de (Dependências de Entrada):**

* `COMMANDERS.md` (Comandantes e Doutrinas)
* `CARD.md` (Formações e Identidades)
* `ENERGY.md` (Energia Operacional)
* `ARMY.md` (Formação e Exército)
* `BATTLEFIELDS.md` (Definição de Cenário)

**Utiliza durante a execução (Regras Operacionais):**

* `COMBAT_RULES.md`
* `ABILITIES.md`
* Modo de Jogo Ativo (PvP/PvE)

**Entrega resultados estruturados para (Sistemas Consumidores):**

* PvP (Sistema de Ranqueamento)
* PvE (Progressão de Campanha)
* Estatísticas (Dados da Conta)
* Histórico (Registro de Batalhas)
* Progressão (Concessão de Recompensas)

## Responsabilidades Arquiteturais

O Sistema de Combate é **responsável arquiteturalmente** por:

* Iniciar e coordenar a execução de batalhas;
* Transitar a batalha entre seus estados (Preparação, Execução, Conclusão);
* Verificar as condições de encerramento;
* Produzir resultados estruturados para terceiros.

O Sistema de Combate **não é responsável arquiteturalmente** por:

* Criar Exércitos, Comandantes ou Cartas;
* Administrar a progressão do Reino;
* Conceder recompensas diretamente;
* Alterar atributos permanentes de Cartas ou Comandantes.

## Observações

O Sistema de Combate constitui o ponto de convergência das principais mecânicas do Battle Simulator.

Sua responsabilidade limita-se à coordenação arquitetural da batalha, preservando a separação entre a estrutura do sistema, as regras operacionais centralizadas no `COMBAT_RULES.md`, e os sistemas de progressão, economia e demais módulos independentes do Reino.

---

*Este documento interage diretamente com `COMMANDERS.md`, `CARD.md`, `ENERGY.md`, `COMBAT_RULES.md`, `ABILITIES.md`, `BATTLEFIELDS.md`, PvP e PvE. As regras operacionais específicas desses sistemas não são definidas neste documento.*