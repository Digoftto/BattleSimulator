# CARD.md

## Objetivo

Este documento define a arquitetura conceitual das Cartas dentro do *Battle Simulator*.

As Cartas representam os Pelotões militares permanentes pertencentes ao Reino. Elas constituem a principal força de combate dos Exércitos e são comandadas pelos oficiais militares do Reino.

Este documento descreve apenas a natureza, estrutura e papéis conceituais das Cartas. As regras de Progressão das Cartas encontram-se em `CARD_PROGRESSION.md`. Habilidades, atributos e o catálogo completo são definidas em documentos próprios.

---

## Filosofia

As Cartas não representam indivíduos nem heróis. Cada Carta constitui um patrimônio militar permanente do Reino, representando um Pelotão militar padronizado composto por soldados especializados em determinada função de combate.

O jogador não recruta soldados individualmente. Ele desenvolve Pelotões militares completos que permanecem disponíveis durante toda a existência do Reino.

Toda Carta pertence permanentemente ao Reino e pode integrar diferentes Exércitos ao longo de sua vida. Ela mantém sua identidade inalterada independentemente das campanhas ou Comandantes aos quais seja vinculada. Os Exércitos apenas utilizam temporariamente as Cartas durante campanhas e combates.

---

## Responsabilidades Arquiteturais

A Carta possui cinco responsabilidades fundamentais dentro da arquitetura do jogo.

### Pelotão Militar

A Carta representa uma unidade organizada do Reino, onde cada Pelotão possui uma função específica dentro do combate. Exemplos incluem Infantaria, Arqueiros, Cavalaria, Engenharia, Magos e Cerco.

### Combate

A Carta serve como o modelo estatístico (*blueprint*) para a criação do Pelotão no Combat State. O Pelotão é a entidade viva em combate responsável por atacar, defender, ocupar posições e aplicar habilidades. As Cartas permanentes do Reino nunca sofrem alterações de atributos durante as batalhas.

### Progressão

As Cartas evoluem exclusivamente através do Aprimoramento, processo que representa o aperfeiçoamento contínuo do Pelotão militar e eleva permanentemente seu Tier. Essa evolução melhora sua eficiência operacional e condição (Estado) sem alterar sua identidade imutável.

### Logística

A Logística engloba os recursos necessários para manter um Pelotão militar operacional ao longo de sua existência no Reino. Toda unidade contribui para a Energia total do Exército e consome Soldo do Reino. A Energia depende exclusivamente do Tier da Carta, enquanto o Soldo depende exclusivamente da Raridade.

### Economia

Sempre que uma nova Carta é criada, ela concede XP ao Reino. As Cartas não possuem XP individual; toda experiência obtida pertence ao Reino e alimenta seus sistemas de progressão.

---

## Estrutura da Carta

Arquiteturalmente, a Carta distingue claramente suas informações permanentes (Identidade) daquelas que evoluem durante o jogo (Estado). A Identidade define aquilo que a Carta é e permanece imutável durante toda sua existência, enquanto o Estado descreve sua evolução e sua condição operacional ao longo da vida do Reino. Essa separação organiza as responsabilidades e reduz o acoplamento entre os diferentes sistemas do jogo.

```text
Carta
│
├── Identidade (Imutável)
│     ├── Nome
│     ├── Facção
│     ├── Classe
│     └── Raridade
│
├── Estado 
│     ├── Progressão
│     │     ├── Tier (Estado da Carta)
│     │     └── Aprimoramento (Processo)
│     │
│     └── Condição Operacional
│           ├── Energia (Contribuição)
│           └── Soldo (Consumo)
│
├── Combate (Atributos e Habilidades)
│     ├── ATK
│     ├── HP
│     ├── ESC
│     ├── Tipo de Ataque
│     └── Habilidade
│
└── Economia
       └── XP concedida ao Reino

```

---

## Identidade

Toda Carta possui uma Identidade permanente que define o Pelotão militar e nunca se altera.

### Nome

Identifica o Pelotão militar. Exemplos: Lanceiros Imperiais, Guardiões do Carvalho, Besteiros Reais.

### Facção

Representa a origem militar do Pelotão. A Facção influencia diversas mecânicas do jogo, principalmente através das Doutrinas dos Comandantes.

### Classe

A Classe define a função tática desempenhada pelo Pelotão militar durante o combate. Ela determina a forma como a unidade atua no campo de batalha, influenciando seu comportamento, posicionamento, habilidades e possíveis Afinidades com as Doutrinas dos Comandantes.

Toda Carta pertence obrigatoriamente a uma única Classe, definida no momento de sua criação e permanente durante toda sua existência. Na Temporada 1 existem seis Classes militares.

* **Corpo a Corpo:** Pelotões especializados em combate direto. Constituem a principal força ofensiva da linha de frente, sendo responsáveis por enfrentar o inimigo em contato direto e proteger os Pelotões posicionados atrás. Exemplos: Espadachins, Lanceiros, Bárbaros.
* **Barreira:** Pelotões especializados em defesa. Sua principal função é absorver dano, proteger aliados e impedir o avanço das tropas inimigas. Exemplos: Escudeiros, Guardiões, Fortificações móveis.
* **À Distância:** Pelotões capazes de atacar à distância. Atuam protegidos pelas linhas frontais, causando dano contínuo sem necessidade de contato direto com o inimigo. Exemplos: Arqueiros, Besteiros, Artilharia leve.
* **Mago:** Pelotões especializados em ataques mágicos ou habilidades especiais. Seu comportamento em combate segue regras próprias definidas pelo Sistema de Combate. Exemplos: Magos, Druidas ofensivos, Invocadores.
* **Suporte:** Pelotões voltados ao fortalecimento do próprio Exército. Suas habilidades priorizam proteção, fortalecimento, recuperação ou controle, contribuindo indiretamente para o desempenho das demais unidades. Exemplos: Curandeiros, Sacerdotes, Bardos, Engenheiros de apoio.
* **Máquina de Guerra:** Pelotões que operam grandes equipamentos bélicos, com mecânicas próprias e especializadas, fora do padrão das demais Classes. Exemplos: Balistas, Catapultas, Torres de cerco móveis.

#### Regras Gerais de Classe

* Toda Carta pertence a exatamente uma Classe.
* A Classe nunca muda após a criação da Carta.
* A Classe determina o papel tático do Pelotão militar.
* A Classe influencia habilidades, posicionamento e comportamento durante o combate.
* As Doutrinas dos Comandantes podem criar requisitos ou bônus específicos para determinadas Classes.

#### Tipo

Algumas Cartas possuem, além da Classe, um Tipo — uma sub-classificação temática opcional (ex: Esqueleto, Aparição, Zumbi), independente da Classe. O Tipo é usado exclusivamente por Características de Unidade que concedem bônus a aliados do mesmo Tipo (ver CARD_CATALOG.md). Nem toda Carta possui um Tipo.

### Tier

O Tier representa o estágio atual de desenvolvimento da Carta. Ele é elevado exclusivamente através do Aprimoramento e influencia diversos sistemas do jogo, como atributos, Energia e Progressão. As regras específicas encontram-se em `CARD_PROGRESSION.md`.

---

## Estado

O Estado engloba a evolução, manutenção e condição operacional da Carta durante sua existência no Reino.

### Progressão

A evolução das Cartas ocorre exclusivamente através do Aprimoramento, processo que eleva o Tier da Carta e representa melhorias contínuas no Pelotão militar (treinamento, equipamentos, organização, disciplina). O Tier representa o estágio atual da Carta. As regras encontram-se em: `CARD_PROGRESSION.md`.

### Condição Operacional (Logística)

Energia e Soldo são manifestações distintas da capacidade logística necessária para manter o Pelotão operacional, possuindo responsabilidades próprias definidas em seus respectivos documentos.

* **Energia:** Representa a contribuição do Pelotão para a resistência operacional do Exército durante campanhas. Seu valor depende exclusivamente do Tier da Carta. As regras encontram-se em: `ENERGY.md`.
* **Soldo:** Representa o consumo de recursos (manutenção) necessário para manter o Pelotão em atividade no Reino. O valor é determinado exclusivamente pela Raridade da Carta e permanece inalterado independentemente do Tier da Carta. As regras encontram-se em: `SOLDO.md`.

---

## Combate

A Carta participa diretamente das batalhas por meio de seus atributos, habilidades e condição operacional. As regras completas encontram-se em: `COMBAT_CORE.md` e `ABILITIES.md`.

---

## Economia

As Cartas não acumulam experiência. Sempre que uma nova unidade é criada, ela concede XP ao Reino, que poderá ser utilizada por outros sistemas de progressão do Reino. As regras encontram-se em: `XP.md`.

---

## Relação com os Comandantes

Os Comandantes não alteram a Identidade das Cartas. Eles apenas potencializam determinados Pelotões através de suas Doutrinas Militares. Essa separação garante que as Cartas representem tropas (patrimônio permanente do Reino) e os Comandantes representem liderança e estratégia.

---

## Ciclo de Vida

Toda Carta percorre o seguinte ciclo conceitual, demonstrando seu papel como patrimônio permanente do Reino alocado temporariamente aos Exércitos:

```text
Criação
  ↓
Integração ao Reino (Patrimônio Permanente)
  ↓
Aprimoramento (Elevação do Tier da Carta)
  ↓
Composição de Exércitos (Alocação Temporária)
  ↓
Campanhas e Combates
  ↓
Retorno ao Reino

```

---

## Relação com Outros Sistemas

Este documento interage diretamente com os seguintes documentos consolidados:

* `ARMY.md`
* `COMMANDERS.md`
* `ACADEMY.md`
* `COMBAT_CORE.md`
* `CARD_PROGRESSION.md`
* `XP.md`
* `SOLDO.md`
* `ENERGY.md`
* `CARD_CATALOG.md`
* `ABILITIES.md`
* `BATTLEFIELDS.md`

Nenhum desses sistemas é definido neste documento.

---

## Princípios Fundamentais

Toda Carta obedece aos seguintes princípios arquiteturais permanentes:

* Representa um Pelotão militar permanente pertencente ao Reino.
* Nunca representa um indivíduo ou herói.
* Constitui patrimônio militar do Reino e permanece disponível durante toda a existência deste.
* Toda Carta pertence permanentemente ao Reino; Exércitos apenas as utilizam temporariamente durante campanhas e combates.
* Possui uma Identidade imutável (Nome, Facção, Classe e Raridade).
* Possui um Estado evolutivo e operacional (Tier, Energia, Soldo).
* Nunca possui XP própria.
* Evolui apenas através do Aprimoramento.
* Participa diretamente dos combates por meio de seus atributos, habilidades e condição operacional.
* Contribui para a Condição Operacional (Energia e Soldo) do Reino e do Exército ao qual está alocada.
* Pertence ao Reino e nunca permanentemente a um Exército; pode integrar diferentes Exércitos ao longo de sua vida.