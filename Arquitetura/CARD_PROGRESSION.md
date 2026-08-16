# CARD_PROGRESSION.md

## Objetivo

O documento de Progressão de Cartas define a evolução individual e permanente de todas as Cartas em *Battle Simulator*.

Seu objetivo é estabelecer a arquitetura conceitual e operacional para o desenvolvimento de longo prazo de cada unidade do jogo, permitindo que o jogador fortaleça suas Cartas sem alterar sua identidade fundamental.

A progressão representa a jornada de desenvolvimento do Pelotão ao longo da sua vida útil. Ela é composta por cinco **Tiers**, sendo o **Aprimoramento** o processo mecânico utilizado pelo jogador para avançar uma Carta de um Tier para o outro, representando o desenvolvimento operacional do Pelotão nela representado.

A progressão nunca cria novas Cartas, novas facções ou novas classes. A criação de novas Cartas é tratada exclusivamente pelo sistema de Combinação (ver `CARD.md`).
Este documento não define atributos, raridades, custos, habilidades ou efeitos de combate das Cartas. Esses elementos são especificados em seus respectivos módulos.

---

## Princípios da Progressão

A Progressão de Cartas é regida pelos seguintes princípios fundamentais:

* Toda Carta possui exatamente cinco Tiers.
* Todo Aprimoramento é totalmente determinístico.
* A identidade da Carta nunca é alterada durante sua progressão.
* A progressão alterna ganhos permanentes de atributos e desbloqueios permanentes de habilidades.
* O Tier representa exclusivamente o estágio de desenvolvimento operacional do Pelotão representado pela Carta.

---

## Filosofia

A filosofia da progressão de Cartas baseia-se em cinco pilares fundamentais:

* Servir como um mecanismo permanente de consumo de Cartas duplicadas;
* Criar uma sensação constante e gratificante de avanço;
* Valorizar o acúmulo de Cartas repetidas;
* Desbloquear novas capacidades operacionais ao longo da evolução;
* Manter todas as Cartas relevantes durante toda a vida útil do jogo.

Os Aprimoramentos representam um investimento contínuo e dedicado no treinamento, organização e desenvolvimento operacional dos Pelotões. A evolução ocorre por instrução técnica e experiência prática acumulada em operações, e não por mero envelhecimento das tropas.

Todo Aprimoramento possui resultado determinístico: não existe aleatoriedade. O jogador sempre sabe exatamente quais atributos e capacidades serão alcançados após a conclusão do processo.

A identidade da Carta permanece rigorosamente a mesma durante todo o seu ciclo de vida. O Tier representa apenas o seu estágio de desenvolvimento operacional.

---

## Mecânica de Aprimoramento

O **Aprimoramento** é a ação realizada pelo jogador para elevar permanentemente uma Carta ao Tier imediatamente superior, representando o desenvolvimento operacional do Pelotão nela representado.

Cada Aprimoramento consome três Cartas idênticas do mesmo Tier para gerar uma única Carta no Tier imediatamente superior.

### Fluxo de Progressão

```text
Carta
Tier I — Iniciante
  ↓
Aprimoramento
Treinamento
  ↓
Carta
Tier II — Experiente
  ↓
Aprimoramento
Experiência em Campanha
  ↓
Carta
Tier III — Expedicionário
  ↓
Aprimoramento
Treinamento Avançado
  ↓
Carta
Tier IV — Elite
  ↓
Aprimoramento
Especialização
  ↓
Carta
Tier V — Veterano de Guerra

```

### Exemplo Prático

* **3× Lanceiros Imperiais — Carta Tier I (Iniciante)**
* $\rightarrow$ *Realizar Aprimoramento (Treinamento)* $\rightarrow$


* **1× Lanceiro Imperial — Carta Tier II (Experiente)**
* **3× Lanceiros Imperiais — Carta Tier II (Experiente)**
* $\rightarrow$ *Realizar Aprimoramento (Experiência em Campanha)* $\rightarrow$


* **1× Lanceiro Imperial — Carta Tier III (Expedicionário)**
* **3× Lanceiros Imperiais — Carta Tier III (Expedicionário)**
* $\rightarrow$ *Realizar Aprimoramento (Treinamento Avançado)* $\rightarrow$


* **1× Lanceiro Imperial — Carta Tier IV (Elite)**
* **3× Lanceiros Imperiais — Carta Tier IV (Elite)**
* $\rightarrow$ *Realizar Aprimoramento (Especialização)* $\rightarrow$


* **1× Lanceiro Imperial — Carta Tier V (Veterano de Guerra)**

> **Observação:** Todas as Cartas consumidas devem possuir exatamente o mesmo Tier entre si, correspondente ao Tier imediatamente anterior ao da Carta resultante.
---

## Estrutura de Tiers e Aprimoramentos

A progressão de uma Carta é estruturada em 5 estágios. O **Tier Técnico** é um conceito exclusivamente técnico utilizado para documentação, balanceamento e desenvolvimento, enquanto a **Denominação** é o nome oficial exibido ao jogador na interface do jogo.
Internamente, o sistema representa os Tiers pelos níveis numéricos 1 a 5, utilizados para implementação, persistência de dados e lógica de progressão. A numeração romana é utilizada exclusivamente para fins de documentação.

| Denominação | Tier Técnico | Aprimoramento |
| --- | --- | --- |
| **Iniciante** | Tier I | — |
| **Experiente** | Tier II | *Treinamento* |
| **Expedicionário** | Tier III | *Experiência em Campanha* |
| **Elite** | Tier IV | *Treinamento Avançado* |
| **Veterano de Guerra** | Tier V | *Especialização* |

---

## Preservação e Alterações de Estado

Durante todo o processo de Aprimoramento, **permanecem inalterados**:

* Nome da Carta;
* Classe;
* Facção;
* Raridade;
* Identidade da Carta.

**Alteram-se apenas**:

* Tier atual (e sua denominação correspondente na interface);
* Atributos (quando aplicável);
* Habilidades desbloqueadas.

---

## Detalhamento dos Tiers e Aprimoramentos

### Tier I — Iniciante

* **Descrição:** Representa a Carta base e o Pelotão recém-formado.
* **Efeitos:** Possui os atributos base da Carta e as Características de Unidade (comportamentos, movimentação ou vantagens de combate nativas, quando existirem na Carta).

---

### Aprimoramento: Treinamento

> *O Pelotão passa por uma rotina intensiva de instrução e preparação física, aprimorando seu manuseio de armas e formação.*

### Tier II — Experiente

* **Descrição:** Primeiro avanço no desenvolvimento operacional do Pelotão.
* **Efeitos:** Concede o primeiro aumento permanente nos atributos de combate da Carta (Ataque, Vida e/ou Escudo). **Não desbloqueia habilidades.**

---

### Aprimoramento: Experiência em Campanha

> *O Pelotão é submetido a missões reais, expedições e reconhecimento, refinando sua adaptação ao terreno e sua eficiência de combate em campanha.*

### Tier III — Expedicionário

* **Descrição:** Estágio em que o Pelotão passa a integrar expedições militares e campanhas prolongadas, adquirindo experiência suficiente para executar funções especializadas durante as Campanhas.
* **Efeitos:** **Não recebe aumento de atributos.** Desbloqueia exclusivamente a **Habilidade de Campanha** da Carta (utilizada nas mecânicas de Campanha (PvE)).
* **Exemplos de Habilidades de Campanha:** *Produção de Recursos, Produção de Fragmentos, Treinamento de Comandantes, Logística Militar, Treinamento Ofensivo, Treinamento Defensivo, Fortificação de Campanha* (detalhadas em `ABILITIES.md`).

---

### Aprimoramento: Treinamento Avançado

> *O Pelotão passa por um programa avançado de aperfeiçoamento militar e assimilação de doutrinas superiores, otimizando seu rendimento no campo de batalha.*

### Tier IV — Elite

* **Descrição:** Representa um Pelotão altamente aperfeiçoado, cuja preparação avançada resulta em um novo aumento permanente de sua eficiência em combate.
* **Efeitos:** Concede o segundo aumento permanente nos atributos de combate da Carta (Ataque, Vida e/ou Escudo). **Não desbloqueia habilidades.**

---

### Aprimoramento: Especialização

> *O Pelotão atinge o preparo operacional máximo e o domínio completo de sua disciplina de combate, alcançando o mais elevado nível de excelência militar.*

### Tier V — Veterano de Guerra

* **Descrição:** O ápice do desenvolvimento do Pelotão e estágio máximo de progressão da Carta.
* **Efeitos:** **Não recebe aumento de atributos.** Desbloqueia exclusivamente a **Habilidade Avançada de Combate**.
* **Exemplos de Habilidades Avançadas:** *Veneno, Berserk, Ataque Duplo, Contra-ataque, Perfuração, Campo de Força, Sobrevivência, Corrente Elétrica* (detalhadas em `ABILITIES.md`).

---

## Balanceamento e Previsibilidade

1. **Atributos:** Os incrementos numéricos aplicados nos Tiers II e IV seguem tabelas fixas e totalmente previsíveis por classe e raridade.
2. **Habilidades Determinísticas:** As habilidades desbloqueadas nos Tiers III (Campanha) e V (Avançada) são fixas e imutáveis para cada modelo de Carta.
3. **Determinismo:** Não existe chance de falha, perda de materiais ou variação aleatória de atributos em nenhuma etapa da progressão.
4. **Separação de Funções:** O sistema estabelece que ganhos permanentes de atributos ocorrem exclusivamente nos Tiers II e IV, enquanto desbloqueios permanentes de habilidades ocorrem exclusivamente nos Tiers III e V.

---

## Relação com Outros Módulos

* **`CARD.md`**: Define a estrutura base das Cartas e sua criação inicial através do *Sistema de Combinação*.
* **`ABILITIES.md`**: Detalha o funcionamento, regras e efeitos de todas as Habilidades de Campanha (Tier III) e Habilidades Avançadas (Tier V).
* **`COMMANDERS.md`**: Define como as Doutrinas dos Comandantes interagem com as Cartas em batalha, aplicando bônus temporários sem alterar a progressão permanente da Carta.
* **`GLOSSARY.md`**: Centraliza a terminologia oficial utilizada por todos os documentos do projeto.

---

## Referências

* `CARD.md`
* `ABILITIES.md`
* `COMMANDERS.md`
* `GLOSSARY.md`