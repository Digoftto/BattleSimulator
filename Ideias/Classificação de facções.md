# IDEIA — Classificação e Tier de Facções

> **Status:** Ideia para avaliação futura. Define a estrutura de composição de Facções e as restrições de montagem de Exércitos (Decks).

## Intenção

Estabelecer uma hierarquia estrutural para as Facções do jogo, dividindo-as em três níveis de poder e especificidade. Essa classificação define a quantidade e a raridade das cartas disponíveis dentro de cada Facção, além de impor limites de inclusão ao montar um Exército de 9 cartas, garantindo balanceamento e diversidade estratégica.

## Categorias de Facções

As Facções são divididas em três escalões com base na sua natureza, complexidade e potencial de impacto no campo de batalha:

| Categoria | Descrição Temática | Cartas na Facção | Limite por Facção |
| --- | --- | --- | --- |
| **Facções Básicas** | Doutrinas regulares e exércitos terrestres equilibrados. Constituem a espinha dorsal da maior parte das forças. | 6 Comuns<br>

<br>4 Raras<br>

<br>2 Épicas<br>

<br>1 Lendária<br>

<br>*(Total: 13 cartas)* | Até **6 cartas** |
| **Facções Sobrenaturais** | Ordens extraordinárias, forças místicas ou tecnologias avançadas de elite. | 4 Comuns<br>

<br>3 Raras<br>

<br>2 Épicas<br>

<br>1 Lendária<br>

<br>*(Total: 10 cartas)* | Até **4 cartas** |
| **Facções Divinas** | Entidades celestiais, seres ancestrais e trunfos de altíssimo poder. | 3 Raras<br>

<br>2 Épicas<br>

<br>1 Lendária<br>

<br>*(Total: 6 cartas - sem Comuns)* | Até **2 cartas** |

---

## Regras de Montagem de Exército

1. **Tamanho do Exército:** O Exército é composto por exatamente **9 cartas**.
2. **Limite de Facções:** Cada Exército pode conter cartas de no máximo **3 Facções diferentes**.
3. **Limites por Categoria:** Os limites de cartas aplicam-se **por Facção individual** e não pela soma da categoria:
* No máximo **6 cartas** de uma mesma **Facção Básica**.
* No máximo **4 cartas** de uma mesma **Facção Sobrenatural**.
* No máximo **2 cartas** de uma mesma **Facção Divina**.


4. **Mistura Livre:** É permitido misturar diferentes Facções (inclusive da mesma categoria, desde que respeitado o limite total de 3 Facções por Exército).
5. **Comandante:** O Comandante do Exército é livre e pode pertencer a qualquer Facção, independentemente da proporção de cartas no deck.
6. **Escassez do Nível Divino:** Por não possuírem cartas de raridade *Comum*, as Facções Divinas oferecem alta potencia individual, mas cobram um custo elevado de flexibilidade e presença constante no baralho.

---

## Decisões de Arquitetura

| Questão | Decisão Definida |
| --- | --- |
| **Múltiplas Facções** | O limite é por Facção. É permitido misturar Facções da mesma categoria no mesmo Exército, desde que respeitadas as restrições gerais. |
| **Limite de Facções no Deck** | Um Exército pode conter no máximo **3 Facções distintas**. |
| **Tamanho do Exército** | O Exército é formado por exatamente **9 cartas**. |
| **Restrição de Comandante** | O Comandante pode ser de **qualquer Facção**, sem necessidade de vínculo com a maioria de cartas do deck. |

---

## Princípios de Avaliação

* As **Facções Básicas** devem fornecer a consistência e o volume de jogo necessários para sustentar a maior parte da formação de 9 cartas.
* As **Facções Sobrenaturais** devem oferecer versatilidade e mecânicas de suporte avançadas para viradas de jogo.
* As **Facções Divinas** devem funcionar como condições de vitória ou trunfos de alto impacto, sem monopolizar a composição da formação.