# ENERGY.md

# Sistema de Energia

## Objetivo

O Sistema de Energia representa a capacidade operacional de um exército de permanecer em campanha.

Ela limita a quantidade de atividades consecutivas que um exército pode realizar e incentiva o jogador a administrar diferentes forças militares ao longo do jogo.

A energia pertence ao exército. Nunca ao Reino.

---

# Filosofia

A energia representa o estado operacional de um exército.

Ela não simboliza apenas resistência física, mas a combinação entre:

* Logística


* Suprimentos


* Moral


* Liderança


* Fadiga


* Organização militar



Quanto maior a energia disponível, maior a capacidade daquele exército de continuar realizando campanhas.

Visualmente, a energia é apresentada ao jogador como uma barra de fadiga operacional. O valor numérico permanece oculto durante a navegação normal, sendo exibido apenas ao posicionar o cursor sobre a barra.

---

# Fontes de Energia

A Energia Total de um exército é formada pela soma de contribuições independentes provenientes de três fontes distintas:

### 1. Infraestrutura do Reino (Energia Base)

Representa a capacidade logística fornecida pelas estruturas do Reino (alimentos, suprimentos, transporte, equipamentos e organização). A Energia Base é fornecida e determinada exclusivamente pelo **Núcleo de Energia** (ver `ENERGY_NUCLEUS.md`).

### 2. Liderança do Comandante

Representa a capacidade do comandante de manter seu exército organizado, disciplinado e motivado durante longas campanhas. Quanto maior a patente do comandante equipado, maior sua contribuição energética.

### 3. Resistência das Tropas (Energia das Cartas)

Representa a capacidade de sustentação das unidades em combate. Essa contribuição depende exclusivamente do nível de Tier das cartas utilizadas no exército.

---

# Energia Total

A Energia Total de um exército é calculada pela soma:

$$\text{Energia Total} = \text{Energia Base} + \text{Energia do Comandante} + \sum \text{Energia das Cartas}$$

Sempre que a composição do exército for alterada (troca de comandante, substituição de cartas ou alteração do nível de Tier), a energia máxima será recalculada automaticamente.

---

# Referências de Balanceamento

## Energia do Comandante

A contribuição energética fornecida pela liderança do Comandante é determinada pela sua Patente oficial (ver `COMMANDERS.md`):

| Patente | Energia |
| --- | --- |
| Recruta | 20 |
| Capitão | 25 |
| Major | 30 |
| Coronel | 35 |
| General | 40 |
| Marechal | 45 |
| Lorde Comandante | 50 |

---

## Energia das Cartas

| Tier | Energia por Carta |
| --- | --- |
| I | 10 |
| II | 11 |
| III | 12 |
| IV | 13 |
| V | 14 |

---

## Exército de Referência (Demonstração Ilustrativa)

A composição a seguir existe com finalidade puramente ilustrativa, servindo para demonstrar o cálculo da Energia Total de uma formação inicial:

* **Energia Base:** Valor fornecido pelo Núcleo de Energia no nível 1 (definido em `ENERGY_NUCLEUS.md`)
* **Comandante:** Recruta (+20)
* **Tropas:** 9 cartas Tier I ($9 \times 10 = +90$)

$$\text{Energia Total} = \text{Energia Base (Núcleo Nv. 1)} + 20 + 90$$

---

# Recuperação de Energia

A energia de um exército recupera automaticamente enquanto ele não estiver em combate.

A velocidade e a taxa de recuperação do sistema são determinadas exclusivamente pelo **Núcleo de Energia** (ver `ENERGY_NUCLEUS.md`).

---

# Locais de Recuperação

A energia recupera normalmente enquanto o exército estiver posicionado na:

* Cidade
* Acampamentos

A energia **nunca** recupera:

* Durante batalhas
* Enquanto o exército estiver em combate ativo

---

# Consumo de Energia

## PvP

Cada série Melhor de 5 consome **10 pontos de energia**.

O consumo ocorre de forma fixa, independentemente da quantidade de partidas efetivamente disputadas dentro da série.

---

## PvE

Cada tentativa de combate consome **4 pontos de energia**.

O consumo total por fase depende da formação utilizada para conquistar a vitória:

| Vitória na Formação | Tentativas | Consumo Total de Energia |
| --- | --- | --- |
| $\alpha$ | 1 | 4 |
| $\beta$ | 2 | 8 |
| $\gamma$ | 3 | 12 |
| $\delta$ | 4 | 16 |
| $\epsilon$ | 5 | 20 |

Isso recompensa exércitos mais eficientes e formações mais ajustadas.

---

## Minas

Minas **nunca** consomem energia. A operação das minas é autônoma em relação ao estado de energia dos exércitos.

---

# Recuperação em Acampamentos

O comportamento operacional de recuperação de um exército em Acampamentos pode ser configurado pelo jogador de duas formas:

* **Recuperar abaixo de um limite:** O jogador define um percentual mínimo (ex.: 40%). Sempre que a energia do exército atingir um valor inferior a esse limite, o exército aguardará a recuperação antes de realizar novas ações.
* **Recuperação Completa:** O exército permanece em repouso até recuperar 100% da sua Energia Total calculada.

---

# Interface

A energia é apresentada ao jogador como uma barra de fadiga operacional:

`[██████████░░░░░░]`

O valor numérico absoluto permanece oculto na navegação normal, sendo exibido em *hover* (ao posicionar o cursor sobre a barra):

`132 / 150`

---

# Regras Gerais

* A energia pertence ao exército, nunca ao Reino.


* Cada exército possui e gerencia sua própria reserva de energia.


* A energia máxima é dinâmica e depende diretamente da composição do exército.


* Minas nunca consomem energia.


* PvP consome 10 pontos de energia por série.


* PvE consome 4 pontos de energia por tentativa.


* A velocidade e as regras de progressão do Núcleo dependem exclusivamente do documento `ENERGY_NUCLEUS.md`.

---

# Penalidade de Composição

A Energia Máxima é recalculada automaticamente sempre que a composição do Exército muda (ARMY.md) — mas o recálculo nunca aumenta a Energia Atual, apenas o teto. Sem uma regra adicional, isso permitiria um exploit real: esvaziar a Energia de um Exército forte lutando, depois transferir seus componentes (Comandante e/ou Cartas) para um Exército fraco com Energia cheia, herdando batalhas "grátis". As regras abaixo fecham esse exploit sem punir reorganizações legítimas de coleção.

## Troca de Comandante

Trocar o Comandante de um Exército **sempre** remove da Energia Atual a porção correspondente à Energia de Comandante do Comandante **anterior** (nunca abaixo de zero) — independente de há quanto tempo aquele Comandante estava parado. Isso é justo porque, na prática, o jogador só pode trocar de Comandante depois de esgotar as 5 Formações de um Exército (ARMY.md, "Trava de Edição por Modo de Jogo") — quando isso acontece, Energia real já foi gasta chegando até ali; a perda residual é sempre pequena.

## Troca de Cartas

Trocar Cartas de um Exército **não tem penalidade** se as Cartas recebidas não estiverem em uso recente em nenhum outro Exército — reorganizar a coleção livremente, com Cartas paradas no inventário, nunca é punido.

A penalidade só existe quando pelo menos uma das Cartas recebidas foi removida de outro Exército dentro da **Janela de Reutilização** (definida abaixo). Nesse caso, a Energia Atual perde inteiramente a porção correspondente à Energia de Cartas do Exército que está recebendo — não apenas a fatia da carta específica reaproveitada, já que a Energia é um valor único e agregado, nunca dividido em 9 parcelas independentes por carta.

### Janela de Reutilização

A Janela de Reutilização é o tempo que uma Carta precisa ficar fora de qualquer Exército antes de poder entrar em outro sem penalidade. Ela é calculada dinamicamente, escalando com o Nível do Núcleo de Energia do Reino (jogadores mais avançados têm janelas mais curtas):

$$\text{Janela de Reutilização} = 9 \times \text{Energia por Carta (Tier I)} \times \text{Tempo de Recuperação por Ponto (Nível atual do Núcleo)}$$

Ou seja: o tempo que o Núcleo de Energia do Reino levaria para recuperar, do zero, a Energia equivalente a 9 Cartas Tier I (a mesma composição de referência já usada em `ARMY.md`) — nunca um valor fixo, sempre proporcional à progressão real do jogador.

| Nível do Núcleo | Janela de Reutilização (aproximada) |
| --- | --- |
| 1 | ~11h15min |
| 10 | ~10h21min |
| 30 | ~8h51min |
| 60 (máximo) | ~7h21min |

---

# Integrações com Outros Sistemas

Este documento interage diretamente com:

* `ENERGY_NUCLEUS.md` — Infraestrutura, valores da Energia Base e taxa de recuperação
* `COMMANDERS.md` — Atribuição de patentes e bônus de comandantes


* `COMMAND_CENTER.md` — Organização de exércitos e acampamentos


* `CARD.md` / `CARD_PROGRESSION.md` — Atributos e níveis de fusão das cartas