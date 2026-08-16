# COMMANDERS.md

# Comandantes

## Objetivo

Este documento define a arquitetura conceitual e a estrutura oficial da carreira militar dos Comandantes dentro do Battle Simulator.

O comandante é a principal entidade estratégica do jogo. Ele representa um oficial militar único, detentor de autoridade institucional, responsável por liderar exércitos, esponsável por liderar exércitos, desenvolver sua carreira militar ao longo da vida em serviço e construir um legado.

O comandante atua como a interface entre o jogador e o exército, conectando os sistemas de progressão, produção, combate e legado através de sua carreira militar.

Este documento estabelece as diretrizes de identidade, hierarquia e responsabilidade estratégica dos comandantes. Sistemas específicos de gameplay relacionados a eles possuem documentação própria.

---

# Filosofia

Os comandantes não são heróis.

Não são unidades de combate.

Não possuem atributos ofensivos nem defensivos de combate.

Seu papel consiste em liderar tropas através de uma doutrina militar específica e de sua autoridade conquistada.

O poder de um comandante nunca deriva de atributos próprios de combate, mas da autoridade militar conquistada ao longo de sua carreira.

Cada comandante representa um indivíduo único dentro do mundo do jogo. Mesmo comandantes com características mecânicas idênticas continuam sendo indivíduos diferentes, com histórias, carreiras e registros próprios.

O jogador não coleciona apenas habilidades. Ele coleciona oficiais militares.

---

# Princípios Fundamentais

Todo comandante obedece aos seguintes princípios:

* **Unicidade:** Todo comandante é um indivíduo único e insubstituível.
* **Identidade Permanente:** Nome, epíteto, facção e origem são imutáveis.
* **Imutabilidade Doutrinária:** A Doutrina Militar nunca muda após a geração.
* **Carreira Permanente:** A carreira militar pertence ao comandante e acompanha toda sua vida em serviço, independentemente dos Reinos aos quais venha a servir.
* **Autoridade vs Poder:** A patente representa autoridade administrativa e limites estratégicos, nunca poder direto de combate.
* **Independência de Progressão:** A progressão de carreira nunca altera a Doutrina Militar.
* **Liderança Estratégica:** O comandante lidera o exército; nunca substitui uma unidade em combate.
* **Separação de Sistemas:** Patentes militares (permanentes) não possuem relação com Ligas competitivas PvP (temporárias).
* **Continuidade Institucional:** Mudanças de Reino em Serviço nunca alteram a identidade, origem, facção, carreira ou histórico permanente do comandante.
* **Legado:** Todo comandante pode construir um Legado permanente.
* **Registro Perpétuo:** Todo comandante permanece registrado historicamente após sua aposentadoria.

---

# Responsabilidades Estratégicas

A existência de um comandante determina oficialmente:

## Identidade Narrativa

Define quem o comandante é no universo do jogo e sua origem histórica.

---

## Doutrina Militar

Define como o comandante lidera seu exército em batalha através de modificadores táticos.

---

## Autoridade Militar

Define os limites administrativos e estratégicos associados à carreira do comandante.

---

## Valor Colecionável

Representa o valor histórico e colecionável do comandante como indivíduo único.

---

## Registro Histórico

Registro permanente da carreira militar do comandante.

---

# Estrutura do Comandante

```text
Comandante
│
├── Identidade
│   ├── Nome
│   ├── Epíteto
│   ├── Reino de Origem
│   ├── Reino em Serviço
│   └── Facção
│
├── Doutrina Militar (Imutável)
│   ├── Restrição
│   ├── Requisito
│   ├── Alvo
│   ├── Efeito
│   └── Valor
│
├── Carreira Militar (Progressiva)
│   ├── XP
│   ├── Patente
│   ├── Autoridade Militar
│   └── Histórico Militar
│
├── Valor Colecionável
│
└── Estatísticas Históricas

```

---

# Identidade

Todo comandante recebe uma identidade permanente no momento de sua geração.

## Nome

Nome próprio do comandante.

---

## Epíteto

Expressão narrativa que individualiza o comandante e reflete sua personalidade ou feitos. O epíteto possui finalidade exclusivamente narrativa.

---

## Reino de Origem

Representa o Reino ao qual o comandante foi originalmente vinculado quando ingressou no jogo. É um registro permanente e histórico. Nunca é alterado.

---

## Reino em Serviço

Representa o Reino pelo qual o comandante atualmente presta serviço. Este vínculo representa apenas o vínculo institucional atual, podendo ser alterado por sistemas específicos definidos em documentação própria, sem nunca alterar a identidade, origem ou histórico militar.

---

## Facção

A facção representa a origem militar do comandante. Ela faz parte permanente da identidade do comandante, influenciando a composição de sua Doutrina Militar e sua estética visual, e nunca pode ser alterada após sua geração.

---

# Doutrina Militar

A Doutrina Militar define a influência tática que o comandante exerce sobre o exército em combate. Ela é imutável após a geração do comandante. Sua composição e funcionamento são definidos em documentação específica do Motor de Geração.

---

# Carreira Militar

A Carreira Militar representa o desenvolvimento profissional e a progressão hierárquica do comandante. Ela pertence ao comandante e acompanha toda sua vida em serviço, independentemente do Reino pelo qual esteja servindo.

Sua arquitetura é projetada para suportar futuras expansões (como condecorações, medalhas e registros de campanhas) sem alterar a estrutura principal.

O acúmulo de XP (Experiência) permite promoções, que por sua vez determinam a Patente. A Patente determina o nível de Autoridade Militar. Todo esse processo é registrado permanentemente no Histórico Militar.

## XP (Experiência)

Representa o acúmulo de conhecimento prático e teórico. A XP é obtida através de atividades militares oficiais. As regras de obtenção e tabelas de XP encontram-se em `XP.md`.

---

## Patente

Representa o posto hierárquico atualmente ocupado pelo comandante. É conquistada exclusivamente através da Carreira Militar e determina o nível de Autoridade Militar. As regras de promoção pertencem à documentação de `XP.md`.

---

## Histórico Militar

Registra permanentemente todos os eventos significativos da carreira do comandante.

---

## Autoridade Militar

A Autoridade Militar representa o grau de autoridade institucional conquistado pelo comandante e nunca concede atributos de combate (ATK, ESC ou HP) ao comandante ou às unidades. Ela determina apenas limites administrativos e estratégicos associados ao posto hierárquico.

A Autoridade Militar determina oficialmente:

* Nível de autoridade institucional;
* Tier Máximo permitido para as unidades sob seu comando;
* Soldo Máximo que pode receber;
* Elegibilidade para o sistema de Legado.

---

# Hierarquia Militar

A hierarquia militar representa a estrutura oficial de comando. Toda promoção representa um reconhecimento institucional da carreira militar do comandante. Cada novo posto amplia sua Autoridade Militar sem alterar sua Doutrina Militar.

## Tabela Oficial de Patentes

| Patente | Tier Máximo | Descrição (Narrativa) |
| --- | --- | --- |
| **Recruta** | Tier I | Oficial recém-comissionado |
| **Capitão** | Tier II | Comanda pequenas companhias |
| **Major** | Tier II | Oficial superior responsável por formações maiores |
| **Coronel** | Tier III | Comandante de regimentos |
| **General** | Tier IV | Comandante de grandes exércitos |
| **Marechal** | Tier V | Membro do Alto Comando |
| **Lorde-Comandante** | Tier V | Maior autoridade militar do Reino |

*A coluna "Descrição" possui finalidade exclusivamente narrativa.*

### Observação: Patente vs Liga competitiva

As Patentes pertencem exclusivamente à carreira permanente e individual do comandante. As Ligas competitivas (Bronze, Prata, Ouro, Diamante) pertencem exclusivamente ao sistema sazonal de PvP do jogador. Não existe relação direta, mecânica ou de balanceamento entre a Patente do comandante e a Liga competitiva do jogador.

---

# Progressão e Ciclo de Vida

## Progressão

A progressão do comandante modifica exclusivamente sua carreira institucional. A Doutrina Militar permanece imutável durante toda sua existência.

---

## Ciclo de Vida

Todo comandante percorre o seguinte ciclo institucional:

```text
Motor de Geração
↓
Candidato
↓
Comissionamento
↓
Serviço Ativo
↓
Aposentadoria
↓
Hall dos Comandantes

```

As regras específicas de cada etapa encontram-se na documentação do Centro de Comando (`COMMAND_CENTER.md` e derivados).

---

# Estatísticas Históricas

Cada comandante mantém estatísticas permanentes de sua atuação.

Exemplos:

* Batalhas disputadas;
* Vitórias;
* Derrotas;
* Empates;
* Maior sequência de vitórias;
* Taxa de vitórias;
* Data de comissionamento;
* Promoções (datas e patentes atingidas);
* Tempo de serviço ativo;
* Reinos servidos;
* Campanhas militares participadas;
* Futuras condecorações e medalhas.

As estatísticas possuem finalidade exclusivamente histórica e colecionável. Não alteram diretamente a jogabilidade ou o balanceamento.

---

# Relação com Outros Sistemas

Este documento estabelece a arquitetura conceitual e hierárquica. Seu funcionamento prático interage com:

* **ACADEMY.md**: Utiliza a Patente do comandante para determinar o Tier máximo permitido para as unidades que ele lidera.
* **COMMAND_CENTER.md** (e documentos derivados): Define as mecânicas, fórmulas e tabelas que operam o ciclo de vida e a carreira descritos aqui.
* **COMBAT.md**: Utiliza a Doutrina Militar do comandante para aplicar modificadores táticos ao exército durante a batalha.
* **GLOSSARY.md**: Define os termos técnicos utilizados.

---

# Observações Técnicas

Os comandantes constituem o principal elemento estratégico e narrativo de longo prazo do Battle Simulator. Sua arquitetura foi projetada para acomodar naturalmente sistemas futuros (como transferências, vendas, campanhas e condecorações) sem alterar sua estrutura principal, garantindo a consistência e escalabilidade do documento.