# FORMULAS.md

# Filosofia

Este documento é a Fonte Única da Verdade (*Single Source of Truth* — SSoT) para todas as fórmulas, curvas de progressão e parâmetros matemáticos compartilhados entre os diferentes sistemas do Battle Simulator.

Seu papel é centralizar as relações matemáticas de forma precisa, modular e escalável. Este documento não descreve mecânicas ou regras operacionais de jogo; os demais documentos do projeto apenas aplicam as relações matemáticas definidas aqui.

Qualquer alteração em fórmulas, custos globais ou curvas de progressão deve ocorrer exclusivamente neste arquivo.

---

# Economia da Cidade

Esta seção centraliza a matemática da economia urbana e das fontes primárias de recursos.

## Custo Geral das Construções

Fórmula oficial aplicada às construções da Cidade:

$$C(n) = \text{CEG} \times (b + n^2 + xn)$$

Onde:

* $n$ = nível da construção
* $\text{CEG}$ = Coeficiente Econômico Global (ajusta toda a economia simultaneamente)
* $b$ = constante base (específica por construção)
* $x$ = coeficiente linear (específico por construção)

A diferenciação de consumo entre as construções ocorre através da combinação destes coeficientes com suas respectivas **Assinaturas Econômicas** (proporção de recursos consumidos em Ferro Negro, Cristais Arcanos e Essência Vital).

*Qual Fundamento é Principal e qual é Secundário para cada construção está definido em `CITY.md` ("Relação entre as Construções e os Fundamentos"). Os parâmetros $b$ e $x$ de cada construção já foram calibrados (ver "Custos Específicos por Construção", abaixo).*

**Proporção Principal/Secundário (Assinatura Econômica):**

* **Capital:** 33% / 33% / 33% (os três Fundamentos igualmente — decisão já registrada, `CITY.md`).
* **Academia, Centro de Comando e Núcleo de Energia:** **70% Fundamento Principal / 30% Fundamento Secundário.**

Exemplo — Academia (Principal: Essência Vital, Secundário: Ferro Negro): de todo Recurso de Construção que a Academia consumir para evoluir, 70% deve vir de Essência Vital e 30% de Ferro Negro.

## Produção das Minas

### Mina Inicial

A produção evolui em progressão geométrica (dobra a cada nível):

$$P(n) = 2^{n-1}$$

### Minas das Regiões

A produção evolui em progressão aritmética. A razão da PA é igual à produção do nível 1 da respectiva região:

$$P(n) = n \times P(1)$$

Exemplos de progressão por nível da região:

* Região 1: $5 \rightarrow 10 \rightarrow 15 \rightarrow 20 \rightarrow 25$
* Região 2: $10 \rightarrow 20 \rightarrow 30 \rightarrow 40 \rightarrow 50$
* Região 3: $20 \rightarrow 40 \rightarrow 60 \rightarrow 80 \rightarrow 100$

## Custos em Pontos de Geração (PG) das Minas

Custo base por região:

* Mina Inicial = $1\text{ PG}$ por nível
* Região 1 = $1\text{ PG}$ por nível
* Região 2 = $2\text{ PG}$ por nível
* Região 3 = $3\text{ PG}$ por nível

### Escalonamento por Bloco de Níveis

A cada bloco de 10 níveis, o custo da mina recebe um multiplicador de $\times 1{,}5$, sempre arredondado para cima:

$$\text{Custo}(n) = \lceil \text{Custo Base} \times 1{,}5^{\lfloor (n-1)/10 \rfloor} \rceil$$

Progressão do multiplicador:

* Níveis 1–10 $\rightarrow \times 1$
* Níveis 11–20 $\rightarrow \times 1{,}5$
* Níveis 21–30 $\rightarrow \times 2{,}25$
* Níveis 31–40 $\rightarrow \times 3{,}375$

---

# Progressão das Construções

Relações matemáticas específicas aplicadas à evolução das estruturas da Cidade.

## Capital

A Capital utiliza a Fórmula Geral das Construções.

Os valores **atualmente vigentes** de $b$ e $x$ da Capital são definidos e mantidos em `BALANCING_SIMULATION.md`, não duplicados aqui — múltiplas simulações podem calcular diferentes pares de $b$/$x$ ao longo do tempo, e apenas o par marcado como vigente naquele documento deve ser considerado válido.

---

## Academia

A Academia utiliza a Fórmula Geral das Construções.

Os valores **atualmente vigentes** de $b$ e $x$ da Academia são definidos e mantidos em `BALANCING_SIMULATION.md`, não duplicados aqui.

---

## Centro de Comando

O Centro de Comando utiliza a Fórmula Geral das Construções.

Os valores **atualmente vigentes** de $b$ e $x$ do Centro de Comando são definidos e mantidos em `BALANCING_SIMULATION.md`, não duplicados aqui.

---

## Núcleo de Energia

O Núcleo de Energia utiliza a Fórmula Geral das Construções, consumindo Recursos de Construção (Ferro Negro, Cristais Arcanos, Essência Vital), assim como Capital, Academia e Centro de Comando — **não** Pontos de Geração.

> **Correção registrada (`BALANCING_SIMULATION.md`, Simulação 1):** esta seção chegou a definir uma fórmula própria em Pontos de Geração, em blocos de 6 níveis. Essa decisão foi revertida pelo dono do projeto — foi um engano identificar o Núcleo como consumidor de PG. Quem não consome Recursos de Construção é o Depósito, não o Núcleo.

Os valores **atualmente vigentes** de $b$ e $x$ do Núcleo de Energia são definidos e mantidos em `BALANCING_SIMULATION.md`, não duplicados aqui.

---

## Depósitos

Os Depósitos evoluem utilizando exclusivamente Pontos de Geração (PG)[cite: 17, 18].

A progressão do custo de evolução segue uma curva linear em blocos de quatro níveis, onde o custo em PG representa o custo para atingir o nível de destino $n$.

Fórmula oficial do custo de evolução para o nível de destino $n$:

$$\text{Custo em PG}(n) = \left\lceil \frac{n}{4} \right\rceil$$

### Tabela de Progressão do Custo de Evolução

| Nível de destino do Depósito ($n$) | Custo da evolução |
| --- | --- |
| Atingir níveis 1 a 4 | $1\text{ PG}$ |
| Atingir níveis 5 a 8 | $2\text{ PG}$ |
| Atingir níveis 9 a 12 | $3\text{ PG}$ |
| Atingir níveis 13 a 16 | $4\text{ PG}$ |
| Atingir níveis 17 a 20 | $5\text{ PG}$ |

# Progressão da Conta

Definições matemáticas da evolução permanente do jogador.

## XP da Conta

$$200\text{ XP} = 1\text{ Nível da Conta} = 1\text{ Ponto de Geração (PG)}$$

* Cada novo nível da Conta exige exatamente **200 XP**.
* A progressão é linear.
* Não existe crescimento do custo de XP entre níveis.
* Cada evolução concede **1 Ponto de Geração (PG)**.

---

# Energia

Definições matemáticas oficiais do Sistema de Energia global do jogador.

## Energia Total do Jogador

A capacidade total de Energia de um jogador é calculada pela soma das seguintes fontes:

$$\text{Energia Total} = \text{Energia Base} + \text{Energia do Comandante} + \sum \text{Energia dos Pelotões}$$

Onde:

* $\text{Energia Base}$: Valor fornecido pelo Núcleo de Energia.
* $\text{Energia do Comandante}$: Bônus numérico fornecido pelo comandante equipado.
* $\sum \text{Energia dos Pelotões}$: Soma das contribuições individuais de energia de todos os pelotões ativos.

---

# Parâmetros de Balanceamento

Esta seção reúne valores de referência, metas e hipóteses temporárias de calibração utilizadas para o balanceamento da Temporada 1.

## Coeficiente Econômico Global (CEG)

* **CEG = 20** (Parâmetro inicial de calibração).

## Hipótese Econômica de Referência (Temporada 1)

* Duração da Temporada: 180 dias.
* Pontos de Geração ($\text{PG}$) totais estimados na temporada: $\approx 240\text{ PG}$.
* Ritmo de ganho de $\text{PG}$: média de $13\text{ PG}$ a cada 10 dias.
* Perfil de referência: Jogador médio com progressão simultânea nas três trilhas.
* Ritmo de conquista regional: aproximadamente 1 nova região conquistada a cada 30 dias.

## Curva de Progressão Esperada das Construções (Temporada 1)

| Nível | Dia Esperado |
| --- | --- |
| 2 | 1 |
| 3 | 3 |
| 4 | 7 |
| 5 | 14 |
| 6 | 25 |
| 7 | 40 |
| 8 | 60 |
| 9 | 85 |
| 10 | 115 |
| 11 | 150 |
| 12 | 180 |

## Metas de Nível por Construção ao Final da Temporada

| Construção | Nível Esperado |
| --- | --- |
| Capital | 9–10 |
| Centro de Comando | 10–12 |
| Academia | 10–12 |
| Núcleo de Energia | 9–10 |
| Depósitos | 5–6 |