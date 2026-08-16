# XP.md

# Sistema de Experiência (XP)

## Objetivo

Este documento define onde existe XP no jogo, como é obtido, sua progressão e para que serve.

Ele estabelece a fonte única de verdade (*Single Source of Truth*) para:

* O XP do Comandante e sua progressão por Patentes;
* O XP da Conta (Reino) e suas fontes Estruturais e Operacionais;
* A diferenciação e regras permanentes do sistema de Experiência.

## Responsabilidade do Documento

Este documento é responsável por definir:

* Tabelas formais de XP acumulado por Patente do Comandante;
* Quantidade de XP concedido por vitória por Liga no PvP e a relação proporcional com o PvE;
* Ações, valores e regras de concessão de XP de Conta (Reino);
* O conceito e fundamentação de XP Estrutural e XP Operacional;
* Regras permanentes e limitações do uso de XP no jogo.

Este documento **não** define:

* Regras de Matchmaking (`MATCHMAKING.md`);
* Patentes, permissões e mecânicas de Comandantes (`COMMANDERS.md`, `SOLDO.md`);
* Economia e construções da Cidade (`CITY.md`, `CAPITAL.md`, `DEPOSITS.md`);
* Regras e mecânicas das Campanhas (`PvE.md`);
* Regras do sistema de aprimoramento (`CARD_PROGRESSION.md`).

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura.

---

# Sistemas Que Não Progridem Por XP

Para evitar ambiguidades, fica estabelecido que os seguintes sistemas **não progridem por XP**, mesmo que a conclusão de suas ações possa conceder XP de Conta/Reino:

* **Cidade:** evolui através de recursos de construção (Ferro Negro, Cristais Arcanos, Essência Vital), não XP.
* **Cartas:** evoluem através de aprimoramento (consumo de cópias), não XP.
* **Trilhas do PvE:** avançam por vencer fases, não por acumular XP.
* **Passe de Temporada:** possui progressão própria (pontos de passe), tratada em documento específico.

Apenas dois elementos do jogo possuem barra própria de XP: o **Comandante** e a **Conta (Reino)**.

---

# XP do Comandante

Cada Comandante possui sua própria barra de XP, de forma independente dos demais Comandantes pertencentes ao jogador.

## Obtenção

* XP do Comandante é obtido **apenas em vitórias**. Derrotas e empates não concedem XP.
* O PvP concede XP determinado exclusivamente pela Liga em que a partida foi disputada.
* O PvE concede ao Comandante **30% do XP** concedido por uma vitória na Liga Bronze do PvP. Essa proporção torna a Liga Bronze a referência oficial do balanceamento (alterações futuras no XP da Liga Bronze refletem automaticamente no PvE).

### XP por Vitória

| Modo / Liga | XP por Vitória |
| --- | --- |
| **PvP — Liga Bronze** | 10 |
| **PvP — Liga Prata** | 12 |
| **PvP — Liga Ouro** | 14 |
| **PvP — Liga Diamante** | 16 |
| **PvE (Qualquer vitória)** | 30% do XP da vitória na Liga Bronze |

## Progressão por Patente

O XP do Comandante é acumulado permanentemente ao longo de sua carreira militar.
Cada Patente exige uma quantidade fixa de XP acumulado. O XP nunca é perdido.

### Tabela Oficial de Progressão por Patente

| Patente | XP Acumulado |
| --- | --- |
| **Recruta** | 0 |
| **Capitão** | 400 |
| **Major** | 1.200 |
| **Coronel** | 2.640 |
| **General** | 4.880 |
| **Marechal** | 8.080 |
| **Lorde-Comandante** | 12.480 |

> **Nota:** Os valores acima representam XP acumulado na carreira do Comandante, e não a diferença de XP necessária entre uma patente e outra.

## Para Que Serve

O XP do Comandante é o combustível por trás da Patente militar.
A interface prioriza apresentar ao jogador a Patente (Recruta, Capitão, Major, Coronel, General, Marechal, Lorde-Comandante), com a barra de XP servindo como progresso visual até a patente seguinte.

A Patente desbloqueia:

* Tier máximo de carta utilizável no Exército;
* Teto de Soldo disponível para composição do exército (`SOLDO.md`);
* Acesso a conteúdo de PvE mais avançado (`PvE.md`);
* Acesso a ligas e torneios superiores no PvP.

---

# XP de Conta (Reino)

O XP da Conta representa o desenvolvimento global e a evolução histórica do Reino ao longo das temporadas. É uma barra de XP separada e independente do XP individual dos Comandantes.

## Obtenção e Diretrizes

* O XP de Conta mede o desenvolvimento geral do Reino e não apenas desempenho tático em combate.
* É concedido imediatamente após a conclusão de uma ação elegível (construção, vitória, recrutamento, etc.), **nunca durante sua execução**.
* Toda ação que representa crescimento, expansão ou atividade militar do Reino concede XP.
* Ações de manutenção recorrentes não concedem XP.

## Conceito e Fundamentação do XP Estrutural e Operacional

### XP Estrutural

O **XP Estrutural** recompensa exclusivamente conquistas permanentes do Reino.

* **Princípio Arquitetural:** Cada conquista estrutural concede XP apenas na **primeira vez** em que ocorre. Repetições da mesma conquista **nunca** concedem XP adicional.
* Esse princípio fundamenta todas as regras referentes à coleção, Tier, construções, Minas e demais progressões permanentes do jogo.
* *Nota:* As evoluções de nível das construções da Cidade concedem XP a cada nível subido, pois cada novo nível representa uma conquista estrutural nova e permanente do Reino.

### XP Operacional

O **XP Operacional** representa atividade militar recorrente.

* Recompensa combates e ações contínuas no PvP e PvE.
* Concede menor quantidade de XP por ação, porém pode ser repetido continuamente.

---

# Ações Que Concedem XP de Conta (Valores Oficiais)

## 1. Cidade (Estrutural)

| Ação | Categoria | XP |
| --- | --- | --- |
| Evoluir Capital | Estrutural | 20 |
| Evoluir Centro de Comando | Estrutural | 20 |
| Evoluir Academia | Estrutural | 15 |
| Evoluir Núcleo de Energia | Estrutural | 15 |
| Evoluir Depósitos | Estrutural | 10 |

## 2. Coleção (Estrutural)

Cada carta diferente da coleção concede XP estrutural apenas na primeira vez em que é obtida ou em que alcança um novo nível de Tier.

| Ação | Categoria | XP |
| --- | --- | --- |
| Primeira obtenção de uma carta Comum | Estrutural | 3 |
| Primeira obtenção de uma carta Rara | Estrutural | 6 |
| Primeira obtenção de uma carta Épica | Estrutural | 12 |
| Primeira obtenção de uma carta Lendária | Estrutural | 24 |
| Primeira vez que uma carta atinge Tier 2 | Estrutural | 2 |
| Primeira vez que uma carta atinge Tier 3 | Estrutural | 4 |
| Primeira vez que uma carta atinge Tier 4 | Estrutural | 8 |
| Primeira vez que uma carta atinge Tier 5 | Estrutural | 12 |

## 3. PvP (Operacional)

| Resultado | Categoria | XP |
| --- | --- | --- |
| Vitória | Operacional | 3 |
| Empate | Operacional | 2 |
| Derrota | Operacional | 1 |

## 4. PvE (Operacional e Estrutural)

| Ação | Categoria | XP |
| --- | --- | --- |
| Concluir fase comum | Operacional | 1 |
| Derrotar Chefe | Operacional | 10 |
| Derrotar Chefe Regional | Operacional | 30 |
| Liberar Mina (Primeira vez) | Estrutural | 20 |
| Concluir Região (Primeira vez) | Estrutural | 40 |

## 5. Comandantes (Estrutural)

| Ação | Categoria | XP |
| --- | --- | --- |
| Recrutamento de novo Comandante (Primeira vez) | Estrutural | 20 |
| Promoção de patente do Comandante | Estrutural | 15 |

---

# Ações Que NÃO Concedem XP de Conta

* Produzir repetidamente a mesma carta sem avanço de Tier;
* Repetir a mesma receita já descoberta na Academia;
* Coletar recursos passivos das Minas;
* Tempo passivo decorrido sem ação;
* Obter duplicatas de cartas que já pertencem à coleção (sem realizar Tier inédito).

---

# Para Que Serve o XP de Conta

O XP e nível da Conta possuem função social, cosmética e geram capacidade estrutural para o Reino:

* Destaque social (exibição do nível do Reino);
* Desbloqueio de cosméticos e títulos;
* Geração de **Pontos de Geração**.

## Regra de Nível e Pontos de Geração

* O Reino inicia no **Nível 1**.
* Cada nível exige exatamente **200 XP** de Conta.
* Não existe curva crescente de XP por nível de Conta.

$$\text{Sempre: } 200 \text{ XP} \longrightarrow 1 \text{ Nível de Conta} \longrightarrow 1 \text{ Ponto de Geração}$$

Os **Pontos de Geração** são recursos destinados à infraestrutura do Reino e são utilizados exclusivamente para evoluir Minas (`MINES.md`) e Depósitos (`DEPOSITS.md`).

---

# Regras Permanentes do Módulo

* XP é exclusivo do Comandante e da Conta. Nenhum outro elemento do jogo possui barra de XP.
* O XP do Comandante é obtido exclusivamente por vitória.
* O XP concedido ao Comandante no PvE corresponde a 30% do XP concedido por uma vitória na Liga Bronze do PvP.
* O XP Estrutural recompensa exclusivamente conquistas permanentes do Reino. Cada conquista estrutural concede XP apenas na primeira vez em que ocorre; repetições nunca concedem XP adicional.
* O XP de Conta é concedido apenas após a conclusão definitiva de uma ação, nunca durante sua execução.
* Ações de manutenção não concedem XP.
* O Reino evolui de nível a cada 200 XP de forma linear.
* O XP de Conta **nunca** é utilizado para decisões ou cálculos de Matchmaking no PvP (`MATCHMAKING.md`).

---

# Referências

* **COMMANDERS.md:** Patentes, permissões e recrutamento de Comandantes.
* **SOLDO.md:** Tetos de Soldo desbloqueados pelas Patentes do Comandante.
* **MATCHMAKING.md:** Regras formais e critérios de pareamento de partidas.
* **PvE.md:** Estrutura de Campanhas, Fases, Chefes e Chefes Regionais.
* **CARD_PROGRESSION.md:** Regras formais do sistema de Tier de cartas.
* **MINES.md & DEPOSITS.md:** Aplicação dos Pontos de Geração e evolução de infraestrutura.