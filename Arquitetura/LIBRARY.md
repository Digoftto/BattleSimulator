# LIBRARY.md

# Visão Geral

A Library (Biblioteca) é o módulo enciclopédico central do Battle Simulator. Ela funciona como um repositório unificado de informações, servindo a três propósitos fundamentais:

1. **Enciclopédia do Universo (Lore):** Fonte oficial de narrativas e descrições das unidades, Facções e do mundo do jogo.
2. **Ferramenta de Planejamento de Evolução:** Consulta centralizada de Atributos, Habilidades, Receitas de Aprimoramento e Árvores de Evolução, permitindo ao jogador projetar o crescimento de seu Exército.
3. **Painel de Consulta da Coleção:** Quando integrada ao perfil do jogador, exibe o estado atual de obtenção e evolução de cada Carta na coleção pessoal.

A Library é puramente informativa e não consome recursos, fragmentos ou tempo. Suas informações são baseadas nas definições oficiais contidas em **LIBRARY_CONTENT.md**.

---

# Dependências do Módulo

Este capítulo define as dependências funcionais do módulo Library em relação ao sistema de salvamento (Save) do jogador.

## Funcionalidades Independentes do Save

As seguintes funcionalidades estão disponíveis integralmente, independentemente do estado da coleção do jogador ou da integração com o Save:

* **Pesquisa Textual:** Localização de Cartas por nome, lore, Facção, tipo ou habilidade.
* **Navegação Interna:** Links entre Cartas, habilidades, ingredientes e receitas.
* **Consulta do Catálogo:** Visualização de todas as Cartas existentes no jogo.
* **Lore:** Acesso à descrição narrativa oficial de todas as unidades.
* **Receitas de Aprimoramento:** Visualização dos ingredientes necessários para Cartas Raras, Épicas e Lendárias.
* **Árvore de Evolução Visual:** Exibição da cadeia evolutiva completa relacionada a uma Carta.
* **Modo de Comparação:** Visualização lado a lado de atributos e habilidades de múltiplas Cartas.
* **Consulta de Atributos e Habilidades:** Visualização dos dados técnicos do Tier I de qualquer unidade.

## Funcionalidades Dependentes do Save

As seguintes funcionalidades requerem a integração ativa com o perfil e Save do jogador para exibição de dados personalizados:

* **Estado da Coleção:** Indicador de "Possuída" ou "Não Possuída".
* **Quantidade de Cartas:** Exibição do total de cópias possuídas (global e por Tier).
* **Favoritos:** Capacidade de marcar Cartas e utilizar filtros e ordenações baseados nesta marcação.
* **Estatísticas Gerais:** Painel com percentual de conclusão da coleção e contagem por Facção e Raridade.
* **Tier Máximo Possuído:** Indicador visual do nível mais alto obtido para cada Carta.
* **Indicadores Visuais na Lista:** Marcadores de "Nova", "Favorita" e "Tier Máximo" diretamente na grade de Cartas.

---

# Sistema de Navegação, Pesquisa e Filtros

A Library utiliza um sistema de visualização em grade ou lista, com capacidade de aplicar múltiplos filtros sobrepostos e ordenação para refinar a busca por unidades.

## Pesquisa Textual

A Library possui um campo de pesquisa textual que localiza Cartas instantaneamente. A pesquisa funciona em conjunto com todos os filtros ativos e varre os seguintes campos:

* Nome
* Lore
* Facção
* Tipo de Unidade
* Habilidade

## Filtros Disponíveis

O jogador pode combinar filtros das seguintes categorias:

### 1. Facção

* Todas
* Império
* Natureza
* Mortos-Vivos
* [Futuras Facções]

### 2. Raridade

* Todas
* Comum
* Rara
* Épica
* Lendária

### 3. Tipo de Unidade

* Corpo a Corpo
* À Distância
* Mago
* Suporte
* Barreira
* Máquina de Guerra

### 4. Estado da Coleção

* Todas
* Possuídas
* Não Possuídas

### 5. Tier

* Todos
* Tier I
* Tier II
* Tier III
* Tier IV
* Tier V

### 6. Favoritos

* Favoritas

## Sistema de Ordenação

A lista de unidades resultante pode ser ordenada pelos seguintes critérios:

* **Nome:** Ordem alfabética (A-Z ou Z-A).
* **Facção:** Agrupamento por Facção.
* **Raridade:** Da menor para a maior ou vice-versa.
* **Poder:** Baseado no Poder de Combate (PC) do Tier I.
* **Custo de Soldo:** Baseado no Custo de Soldo do Tier I.
* **Quantidade Possuída:** Do maior para o menor acúmulo de cópias.
* **Tier:** Baseado no maior Tier possuído daquela unidade.
* **Favoritas:** Cartas marcadas como favoritas aparecem primeiro.

## Estado Vazio

Caso a combinação de filtros e pesquisa aplicada não retorne nenhuma Carta, o comportamento da Library será:

1. Nenhuma Carta ou ficha de unidade será exibida na área principal.
2. Uma mensagem informativa e clara será apresentada ao jogador (ex: "Nenhuma carta satisfaz os filtros aplicados.").
3. O painel de filtros e a barra de pesquisa permanecerão ativos e visíveis.
4. Nenhum filtro será removido automaticamente pelo sistema; o jogador deve ajustar os critérios manualmente.

---

# Estrutura da Página da Carta

Cada unidade possui uma página individual detalhada na Library. Todas as referências a outras Cartas, habilidades, ingredientes ou receitas dentro desta página funcionam como links internos, permitindo navegação rápida e fluida.

A página é estruturada obrigatoriamente nos seguintes painéis:

## 1. Cabeçalho

Exibe as informações básicas de identificação:

* **Nome**
* **Facção**
* **Classe**
* **Raridade**
* **Tier**
* **Tipo de Unidade**
* **Custo de Soldo**

## 2. Visualização

Apresenta a **Arte Conceitual** oficial da unidade.

## 3. Lore

Contém a descrição narrativa oficial da unidade, conforme definido em **LIBRARY_CONTENT.md**.

## 4. Informações de Coleção

Painel informativo sobre o estado da Carta no perfil do jogador (exibido apenas quando integrado ao Save):

* **Status:** Possuída ou Não Possuída.
* **Quantidade Total:** Soma de todas as cópias de todos os Tiers.
* **Quantidade por Tier:** Exibe a quantidade no Tier I, Tier II, Tier III, Tier IV e Tier V.
* **Maior Tier Possuído:** Indica o nível mais alto (I a V) que o jogador possui desta unidade.

## 5. Atributos Base

Tabela contendo os atributos numéricos referentes ao **Tier I**:

| Atributo | Valor |
| --- | --- |
| **HP** | [Valor] |
| **Ataque** | [Valor] |
| **Defesa** | [Valor] |
| **Velocidade** | [Valor] |
| **Alcance** | [Valor] |

## 6. Habilidades

Lista de habilidades ativas e passivas da unidade. Cada nome de habilidade possui navegação direta para sua descrição detalhada no documento **ABILITIES.md**.

## 7. Painel de Evolução (Progressão por Tier)

Apresenta todos os estágios de evolução da Carta e detalha o seu desenvolvimento ao longo da progressão.

**Fluxo:** Tier I → Tier II → Tier III → Tier IV → Tier V.

Para cada nível selecionado, o painel exibe:

* Atributos numéricos correspondentes àquele nível.
* Melhorias ou modificações nas habilidades para aquele nível.

## 8. Origem e Receita

Define como a Carta é obtida.

* **Se a Carta for Comum:** Exibe a mensagem: "Produzida diretamente na Academia através de Fragmentos."
* **Se a Carta for Rara, Épica ou Lendária:** Exibe a **Receita Oficial de Aprimoramento**. Cada ingrediente listado possui navegação direta para sua respectiva página na Library.

## 9. Relacionamentos de Receita

Toda Carta possui os seguintes painéis de relacionamento:

### Produzida a partir de

Exibe visualmente a receita de origem da Carta atual (mesma informação do painel Origem e Receita).

### Utilizada nas seguintes Receitas

Lista todas as Cartas superiores cuja receita de Aprimoramento utiliza esta unidade como ingrediente. Cada item da lista possui navegação direta.

### Mesmo Grupo

Listas de navegação rápida para outras Cartas da mesma Facção, mesma Raridade e mesmo Tipo de Unidade.

## 10. Árvore de Evolução Visual

Este painel exibe graficamente toda a cadeia evolutiva relacionada à Carta, permitindo compreender a linhagem completa (ingredientes e evoluções futuras) sem navegar por múltiplas páginas.

---

# Gerenciamento e Funcionalidades Avançadas

## Comparação de Cartas

O Modo de Comparação permite ao jogador selecionar duas ou mais Cartas e visualizá-las lado a lado. A interface de comparação deve exibir HP, Ataque, Defesa, Velocidade, Alcance, Tipo, Facção, Raridade, Habilidades e Receita de Origem para facilitar a análise. Esta funcionalidade é puramente informativa.

## Favoritos

O jogador pode marcar qualquer Carta como favorita através de um ícone na página da Carta ou na grade de visualização. Esta marcação habilita o filtro "Favoritas" e o critério de ordenação "Favoritas primeiro". Esta funcionalidade é exclusivamente informativa e de organização pessoal.

## Estatísticas da Biblioteca

A Library exibe um painel geral de estatísticas da coleção do jogador (requer integração com Save):

* **Coleção:** Total de Cartas existentes no jogo, total desbloqueadas pelo jogador e percentual de conclusão.
* **Facções:** Quantidade de Cartas obtidas agrupadas por Facção.
* **Raridades:** Quantidade de Cartas obtidas agrupadas por Raridade.
* **Tier:** Contagem total de unidades no Tier I, Tier II, Tier III, Tier IV e Tier V na coleção.

## Indicadores Visuais na Grade

A visualização em grade ou lista pode apresentar indicadores rápidos sobre as Cartas:

* **Possuída / Não Possuída**
* **Favorita** (ícone de estrela/coração)
* **Nova** (Carta recém-obtida, limpa após visualização)
* **Utilizada em Receita** (indica se esta Carta é ingrediente para alguma Carta superior da coleção)
* **Tier Máximo** (indica se o jogador possui uma cópia no Tier V)

---

# Especificações Técnicas e Escalabilidade

Este capítulo define diretrizes de engenharia para garantir a estabilidade e a manutenção de longo prazo do módulo Library.

## Navegação Interna Determinística

A implementação técnica da navegação interna entre páginas da Library (Cartas, habilidades, ingredientes, receitas) deve utilizar identificadores únicos internos (IDs) e não os nomes textuais das entidades. Os nomes de Cartas, Facções, habilidades, etc., exibidos na interface devem ser tratados exclusivamente como texto de apresentação (strings de interface). Isso assegura que alterações futuras em nomes de lore ou habilidades não quebrem os links de navegação e as receitas de Aprimoramento.

## Preparação para Localização (i18n)

Todo e qualquer texto apresentado ao jogador na interface da Library deve ser compatível com um sistema de localização (i18n). A implementação não deve depender de textos fixos ("hardcoded strings") para a lógica de filtros, ordenação ou exibição. As strings de Lore, nomes de Cartas e descrições de habilidades devem ser carregadas de tabelas de localização baseadas em IDs determinísticos.

## Escalabilidade do Catálogo

A arquitetura do módulo Library e o formato de dados do catálogo de Cartas foram projetados para suportar a expansão contínua do jogo. A introdução de novas Facções, novas Cartas, novos Tipos de Unidade ou Raridades deve ser realizada através da adição de entradas nas tabelas de dados, seguindo exatamente a estrutura já estabelecida. Novas Facções, por exemplo, devem respeitar a hierarquia de possuir Cartas Comuns, Raras, Épicas e Lendárias para integração imediata nos sistemas de filtros, árvore de evolução e navegação, sem necessidade de reestruturação do código do módulo.

---

# Referências

Este módulo possui integração conceitual com os seguintes documentos:

* **LIBRARY_CONTENT.md**
Responsável pelo catálogo oficial de Cartas, lore, receitas e árvores de evolução.
* **ACADEMY.md**
Responsável pelas regras de produção e Aprimoramento.
* **ABILITIES.md**
Responsável pela definição completa das habilidades.
* **CARD_CATALOG.md**
Responsável pelos atributos oficiais das Cartas.
* **RESOURCES.md**
Responsável pela economia de Fragmentos e demais recursos.

O módulo Library atua exclusivamente como camada de consulta dessas informações, não sendo responsável pela definição das regras nem pelo conteúdo armazenado nos documentos acima.