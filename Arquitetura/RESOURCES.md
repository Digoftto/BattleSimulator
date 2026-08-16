# RESOURCES.md

# Recursos do Jogo

Este documento define a arquitetura econômica do Battle Simulator, estabelecendo os recursos, suas funções, métodos de obtenção e os valores de referência que regem a economia do jogo.

Este documento serve como a referência econômica oficial para todos os demais sistemas do jogo. Qualquer documento futuro que trate de transações, recompensas ou custos deve utilizar as definições aqui estabelecidas.

---

# 1. Objetivo do Documento

Definir e padronizar a economia do Battle Simulator, estabelecendo o Valor de Referência de Produção (VRP) e o Valor de Referência de Ganho (VRG) como pilares determinísticos para custos e recompensas, garantindo consistência e escalabilidade para futuras expansões.

---

# 2. Economia Fundamental

A economia do Battle Simulator é regida por dois valores de referência distintos e independentes. Esta separação permite o balanceamento isolado dos custos de produção e da distribuição de recompensas sem desestabilizar o sistema econômico como um todo.

## 2.1. VRP (Valor de Referência de Produção)

O VRP representa exclusivamente a economia de produção do jogo. Ele é o valor econômico base utilizado pela Academia para calcular os custos de produção de novas unidades. Seus valores derivam diretamente das receitas oficiais e não representam preços de mercado, valores de troca entre jogadores ou recompensas de batalha.

### Valores Oficiais de VRP

| Raridade da Carta | VRP (em Fragmentos) |
| :--- | :--- |
| Comum | 50 |
| Rara | 150 |
| Épica | 200 |
| Lendária | 400 |

## 2.2. VRG (Valor de Referência de Ganho)

O VRG é a unidade de calibração econômica utilizada para determinar a distribuição de recompensas em todas as atividades do jogo. Toda recompensa econômica do Battle Simulator deriva diretamente deste valor de referência.

### Valor Oficial de VRG

$$ VRG = 10 \text{ Fragmentos} $$

*Observação: O VRG representa apenas o ponto de calibração da economia de recompensas. Os Fragmentos efetivamente recebidos pelos jogadores podem variar conforme Liga, Divisão, modo de jogo e modificadores aplicáveis.*

## 2.3. Relação entre VRP e VRG

A arquitetura econômica separa claramente as esferas de atuação:

*   **VRP:** Controla exclusivamente a economia de produção (Custos).
*   **VRG:** Controla exclusivamente a economia de distribuição de recompensas (Ganhos).

**Esquema de Atuação Econômica:**

*   **VRP:** Produção de Unidades, Academia, Receitas.
*   **VRG:** PvP, PvE, Missões, Eventos, Passe de Batalha, Demais Recompensas.

---

# 3. Fragmentos de Cartas

Fragmentos são o principal recurso econômico utilizado na produção de novas unidades. Eles constituem a base da economia de produção.

*   **Independência Econômica por Facção:** Cada facção possui seu próprio tipo de Fragmento e uma economia independente de Fragmentos. Fragmentos de uma facção não podem ser utilizados para produzir unidades de outra facção.

*Observação: O sistema de Aprimoramento (evolução de unidades existentes) consome apenas cartas, não utilizando Fragmentos em sua mecânica (ver ACADEMY.md).*

---

# 4. Obtenção de Fragmentos

Fragmentos são obtidos exclusivamente através do combate, ao destruir pelotões inimigos.

*   **Pelotão Original:** São os pelotões que compõem o exército inicial do jogador (o deck). A destruição de um Pelotão Original inimigo gera fragmentos para o atacante.
*   **Pelotão Conjurado:** São unidades criadas em batalha por habilidades de outras cartas. A destruição de pelotões conjurados **NUNCA** gera fragmentos.
*   **Correspondência de Facção:** O fragmento gerado pertence sempre à mesma facção do pelotão destruído.

## 4.1. Recompensas PvP (Fonte Principal)

O PvP é a principal fonte de fragmentos do jogo. O cálculo da recompensa final de Fragmentos de uma partida PvP ocorre em duas etapas distintas para eliminar ambiguidades:

### Etapa 1: Determinar o Valor-Base por Pelotão

Primeiro, determina-se o valor-base de Fragmentos obtidos por cada **Pelotão Original destruído**, conforme a Liga e Divisão do jogador.

**Tabela Oficial de Ligas (Valor-Base por Pelotão Original Destruído)**

*Estes valores representam a recompensa integral (100%), correspondente a uma Vitória.*

| Liga | VII | VI | V | IV | III | II | I |
| :--- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| **Bronze** | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
| **Prata** | 11 | 12 | 14 | 15 | 16 | 17 | 19 |
| **Ouro** | 13 | 15 | 16 | 18 | 19 | 20 | 22 |
| **Diamante** | 15 | 17 | 19 | 23 | 25 | 27 | 30 |

### Etapa 2: Aplicar o Modificador de Resultado

A tabela de Ligas **não representa a recompensa final** por pelotão; ela representa apenas o valor-base. A recompensa final depende obrigatoriamente do resultado da partida. Aplica-se o modificador correspondente sobre o valor total acumulado na Etapa 1.

**Tabela de Modificadores de Resultado**

| Resultado | Multiplicador |
| :--- | :--- |
| Vitória | 100% |
| Empate | 80% |
| Derrota | 50% |

**Exemplo de Cálculo:**

1.  Um jogador na Liga **Ouro III** destrói um Pelotão Original.
2.  Conforme a tabela de Ligas, o **valor-base** é 19 Fragmentos.
3.  Se o jogador **vencer** a partida, recebe 19 Fragmentos ($19 \times 100\%$).
4.  Se o jogador **empatar** a partida, recebe 15,2 Fragmentos ($19 \times 80\%$).
5.  Se o jogador **perder** a partida, recebe 9,5 Fragmentos ($19 \times 50\%$).

---

## 4.2. Recompensas PvE (Fonte Complementar)

O PvE serve como fonte complementar de fragmentos, gerando-os a uma taxa reduzida e consistente com a filosofia definida em PvE.md. A economia do PvE é uma derivação econômica do PvP.

O PvE gera **20% do valor equivalente obtido no PvP** para o mesmo resultado e a mesma liga/divisão de calibração.

O cálculo aplica primeiro o modificador de resultado do PvP (100%, 80% ou 50% sobre o valor-base da Liga) e, posteriormente, o modificador PvE de 20% sobre esse valor resultante.

| Resultado no PvE | Cálculo PvE |
| :--- | :--- |
| Vitória | 20% de 100% do valor da Liga PvP |
| Empate | 20% de 80% do valor da Liga PvP |
| Derrota | 20% de 50% do valor da Liga PvP |

*Observação: Estes percentuais são aplicados sobre o valor que a mesma destruição de pelotões geraria no PvP na liga correspondente.*

---

# 5. Recursos de Construção

Recursos de Construção (Ferro Negro, Cristais Arcanos, Essência Vital) são utilizados para a evolução da infraestrutura da cidade do jogador.

## 5.1. Obtenção Primária

As Minas (ver MINES.md e DEPOSITS.md) são a fonte primária e contínua de recursos de construção.

---

# 6. Utilização dos Fragmentos

Atualmente, os Fragmentos são utilizados na Academia para a produção de unidades (ver ACADEMY.md), baseando-se no **VRP (Capítulo 2.1)**:

*   Criar cartas Comuns diretamente.
*   Criar cartas Raras, Épicas e Lendárias através de receitas (criação direta via fragmentos).

Novas aplicações poderão ser adicionadas futuramente, respeitando a arquitetura econômica definida neste documento.

---

# 7. Regras Permanentes

*   A economia de ganhos (VRG) e a economia de custos (VRP) são independentes para fins de balanceamento.
*   O PvP é a principal fonte de fragmentos; o PvE é complementar e derivado economicamente do PvP.
*   Fragmentos são sempre específicos por facção e possuem economias independentes.
*   A destruição de pelotões conjurados nunca gera fragmentos.
*   As regras de uso dos fragmentos (receitas, criação, Tier) pertencem a ACADEMY.md, não a este documento.

---

# Referências

*   **ACADEMY.md** — Produção de unidades, receitas e Tier.
*   **DEPOSITS.md** — Recursos de construção e depósitos.
*   **PvE.md** — Regras específicas do modo PvE.
*   **PvP.md** — Regras específicas do modo PvP.