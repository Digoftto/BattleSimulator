```markdown
# Capital.md

## Objetivo

Este documento define a arquitetura conceitual, a filosofia de design e o funcionamento da Capital dentro do Battle Simulator.

A Capital não é um edifício isolado; ela é a representação institucional, urbana e estrutural do Reino. Seu nível não reflete a altura de uma única torre, mas sim o estágio de desenvolvimento geral da cidade e do Reino como um todo.

O objetivo da Capital é organizar, limitar e sincronizar a evolução urbana do Reino, servindo como o principal indicador do desenvolvimento do Reino.

## Filosofia

A Capital representa o desenvolvimento global do Reino. Como consequência, sua evolução é projetada para ocorrer mais lentamente do que a das demais construções.

Ela atua como um gargalo natural de progressão. A filosofia da Capital não é restringir o acesso a sistemas do jogo, mas sim organizar o ritmo de crescimento da cidade e impedir que as construções urbanas progridam em velocidades excessivamente díspares.

É um princípio inabalável que a Capital **não concede benefícios diretos de combate**. Seu poder deriva de sua capacidade de organizar a infraestrutura do Reino.

### Unidade Arquitetônica

A Capital estabelece a identidade arquitetônica predominante do Reino. Todas as construções urbanas (Academia, Centro de Comando, Depósitos, Núcleo de Energia e futuras estruturas urbanas institucionais) devem evoluir acompanhando o mesmo estilo arquitetônico predominante da Capital.

Isso garante a unidade estética do Reino e reforça a percepção visual de que todas as estruturas formam uma única cidade coesa.

## Objetivos de Design

O sistema da Capital foi projetado para atingir os seguintes objetivos:

*   **Representação Visual:** Fornecer ao jogador uma representação visual clara e contínua do crescimento institucional e urbano do seu Reino.
*   **Controle de Progresso:** Atuar como o principal mecanismo de controle e gargalo da velocidade de desenvolvimento da cidade.
*   **Unidade Estética:** Estabelecer a identidade arquitetônica que todas as construções urbanas devem acompanhar.
*   **Sincronização:** Sincronizar o nível máximo de todas as construções da cidade.

## Definição

Arquiteturalmente, a Capital representa a cidade principal do Reino e simboliza seu estágio de desenvolvimento institucional, urbano e estrutural. Seu nível expressa a maturidade da infraestrutura, da organização e da expansão do Reino como um todo.

Sua principal responsabilidade estratégica é estabelecer os limites operacionais para todas as construções que formam a infraestrutura urbana do Reino.

## Princípios Fundamentais

Todo o funcionamento da Capital obedece aos seguintes princípios conceituais permanentes:

1.  **Representação Urbana:** A Capital é a representação da cidade e do estágio de desenvolvimento do Reino, não um edifício individual.
2.  **Evolução Visual Contínua:** Cada novo nível da Capital deve produzir algum avanço perceptível em sua aparência, preservando continuamente a sensação de crescimento do Reino.
3.  **Unidade Arquitetônica:** Todas as construções urbanas devem acompanhar a identidade arquitetônica predominantemente estabelecida pela Capital.
4.  **Limitador Institucional:** O nível da Capital limita o nível máximo das construções da cidade.
5.  **Progressão Contínua:** A Capital possui progressão contínua, teoricamente ilimitada em número de níveis.
6.  **Benefícios de Combate:** NENHUM benefício direto de combate é concedido pela Capital.
7.  **Gargalo Natural:** A evolução da Capital deve ocorrer mais lentamente do que as das construções da cidade, agindo como um gargalo natural do desenvolvimento.
8.  **Recursos Globais:** Por representar toda a cidade, a Capital utiliza os três recursos do jogo para sua evolução.
9.  **Persistência Visual:** A evolução arquitetônica da Capital é cumulativa. Novos elementos são adicionados à cidade sem descaracterizar sua identidade construída ao longo da progressão; a cidade cresce por expansão e enriquecimento, e não por substituições completas a cada evolução.

## Evolução Visual

A evolução visual da Capital e da cidade é um princípio permanente que formaliza a filosofia de crescimento contínuo do Reino.

Esta evolução ocorre durante toda a progressão da Capital, onde cada novo nível deve produzir alguma evolução perceptível na cidade. O objetivo é garantir que o jogador nunca permaneça por longos períodos sem perceber o crescimento visual e a sensação de progresso contínuo do seu Reino.

A evolução visual é estruturada em dois mecanismos distintos:

### Transformações Arquitetônicas

Em determinados estágios da progressão ocorrem grandes mudanças estruturais que alteram significativamente a aparência da Capital e da cidade. Estas transformações representam novas fases do desenvolvimento urbano do Reino.

Os seguintes estágios representam apenas a filosofia arquitetônica de crescimento conceitual e poderão ser ajustados livremente durante o desenvolvimento e balanceamento do jogo:

```text
Pequena Vila
     ↓
Aldeia Fortificada
     ↓
Vila Murada
     ↓
Pequena Cidade
     ↓
Cidade Fortificada
     ↓
Grande Cidade
     ↓
Fortaleza
     ↓
Capital Imperial

```

### Incrementos Arquitetônicos

Entre uma Transformação Arquitetônica e outra, cada novo nível acrescenta pequenos elementos urbanos que reforçam continuamente a sensação de progresso.

Exemplos conceituais de incrementos:

* **novas casas;**
* **ruas;**
* **muralhas;**
* **torres;**
* **bandeiras;**
* **monumentos;**
* **jardins;**
* **novos bairros;**
* **estradas;**
* **elementos decorativos;**
* **expansão urbana.**

## Estrutura da Capital

O nível da Capital influencia os seguintes componentes urbanos:

```text
Capital (Representação Urbana e Institucional)
│
├── Nível (Maturidade do Reino)
│
├── Evolução Visual
│   ├── Transformações Arquitetônicas
│   └── Incrementos Arquitetônicos
│
├── Unidade Arquitetônica
│
└── Limites Operacionais (Mecanismo de Gargalo)
    ├── Depósitos (Capacidade Máxima)
    ├── Centro de Comando (Acesso a Unidades e Expansão)
    ├── Núcleo de Energia (Capacidade Operacional)
    └── Academia (Tier Máximo e Pesquisa)

```

## Progressão

A Capital é uma construção de progressão contínua. Seu número de níveis é teoricamente ilimitado, permitindo que o Reino cresça ao longo do tempo. Ela representa o gargalo natural do desenvolvimento urbano.

## Custo de Evolução

O custo de evolução da Capital segue a fórmula geral única de construções (definida em FORMULAS.md): C(n) = CEG × (b + n² + xn). Os parâmetros b e x são específicos da Capital e calibrados durante o balanceamento.

## Recursos Utilizados

Como a Capital representa toda a cidade, ela utiliza os três recursos do jogo para evoluir:

* Ferro Negro;
* Cristais Arcanos;
* Essência Vital.

As proporções entre os recursos poderão ser ajustadas para fins de balanceamento, mas nenhum recurso possui prioridade permanente.

## Referência de Balanceamento

As metas de progressão numérica da Capital, incluindo referências para temporadas específicas, são definidas exclusivamente no documento FORMULAS.md. Este documento define apenas a arquitetura e os princípios do sistema.

Os valores **atualmente vigentes** de $b$ e $x$ da Capital são definidos e mantidos em `BALANCING_SIMULATION.md` — múltiplas simulações podem calcular diferentes pares de $b$/$x$ ao longo do tempo, mas apenas um par é o vigente a qualquer momento, sempre marcado explicitamente como tal naquele documento.

## Funcionamento

A Capital atua como o principal limitador institucional da cidade, sincronizando toda a evolução urbana do Reino.

A verificação do nível da Capital é permanente e automática. Nenhuma construção urbana pode possuir nível superior ao da Capital.

## Sincronização de Progresso

A Capital sincroniza a progressão urbana do Reino através de uma verificação obrigatória:

**Toda tentativa de evolução de uma construção urbana verifica previamente o nível atual da Capital.**

Se a construção urbana atingir o nível da Capital, sua evolução é bloqueada até que a própria Capital evolua. Sempre que a Capital evolui, o limite máximo de todas as construções dependentes é aumentado automaticamente.

## Construções Dependentes

As construções urbanas institucionais cujos níveis são limitados pela Capital são:

* Depósitos;
* Centro de Comando;
* Núcleo de Energia;
* Academia.

*Nota: Apenas construções que fazem parte da infraestrutura urbana institucional possuem sua progressão limitada pela Capital. Sistemas independentes ou mecânicas que não representem construções urbanas seguem suas próprias regras de progressão.*

## Estrutura Inicial

A cidade inicia com todas as construções disponíveis no nível 1. Não existem desbloqueios de construções.

## Relação com Outros Sistemas

Este documento estabelece a arquitetura operacional da Capital. Seu funcionamento prático interage diretamente com os seguintes documentos:

* **RESOURCES.md:** Os Depósitos utilizam o limite da Capital para determinar sua capacidade máxima.
* **ACADEMY.md:** A Academia utiliza o limite da Capital para determinar seu Tier Máximo e acesso a pesquisas.
* **COMMAND_CENTER.md:** O Centro de Comando utiliza o limite da Capital para determinar a infraestrutura militar do Reino.
* **FORMULAS.md:** Define a fórmula de custo de evolução e as metas de balanceamento.

## Observações Técnicas

A arquitetura da Capital foi concebida para ser flexível e escalável, suportando o crescimento contínuo do jogo. Ela suporta naturalmente a introdução de novos níveis, novas construções urbanas institucionais, novas Transformações e Incrementos Arquitetônicos, e futuros sistemas urbanos ao longo de múltiplas temporadas, sem exigir alterações em seus princípios fundamentais.