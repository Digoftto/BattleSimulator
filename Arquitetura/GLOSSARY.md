# GLOSSARY.md

# Glossário Técnico Oficial

## Objetivo

Este documento é o dicionário técnico oficial do Battle Simulator.

Seu objetivo é definir a terminologia oficial, nomenclaturas e convenções linguísticas utilizadas em toda a documentação técnica e no desenvolvimento do projeto.

Ele serve exclusivamente para responder o significado conceitual de cada termo, indicando qual documento de arquitetura é o proprietário (*owner*) das regras e mecânicas associadas.

---

## Responsabilidade do Documento

Este documento é a Fonte Única de Verdade (*Single Source of Truth*) para:

* Terminologia e nomenclatura oficiais do projeto;
* Definições conceituais dos termos técnicos;
* Convenções de escrita para documentação e código;
* Mapeamento de termos para seus respectivos documentos responsáveis.

Este documento **não** define:

* Regras, mecânicas e fluxos de jogo;
* Fórmulas matemáticas e tabelas de valores;
* Parâmetros numéricos, balanceamento e estatísticas;
* Funcionamento interno de sistemas;
* Listas oficiais de conteúdo (facções, classes, patentes, etc.).

Esses domínios pertencem exclusivamente aos documentos responsáveis por cada sistema.

---

## Princípio de Definição

Cada verbete deste Glossário deve conter apenas:

* O significado oficial do termo;
* O contexto conceitual mínimo necessário para sua compreensão;
* A referência ao documento proprietário (*owner*) do domínio.

O Glossário não descreve:

* Funcionamento interno;
* Regras;
* Mecânicas;
* Fórmulas;
* Parâmetros;
* Fluxos de execução.

Essas informações pertencem exclusivamente aos documentos responsáveis por cada sistema.

---

## Convenção de Terminologia e Escrita

Para evitar ambiguidades e garantir consistência em toda a documentação técnica, adotam-se as seguintes diretrizes formais:

| Termo / Ação | Nomenclatura Oficial | Termos Proibidos / A Evitar | Contexto / Justificativa |
| --- | --- | --- | --- |
| **Entidade em Combate** | Pelotão / Unidade | Carta | Cartas pertencem à coleção; no combate atuam como Pelotões. |
| **Eliminação em Combate** | Unidade derrotada | Unidade morta / "Morrer" | Termos narrativos ("morte") são restritos ao texto de *Lore*. |
| **Dano SOFRIDO** | Pelotão recebe dano | Carta recebe dano | Cartas da coleção não sofrem alterações durante a batalha. |
| **Movimentação** | Pelotão avança | Carta avança | Apenas entidades em combate se movimentam no tabuleiro. |
| **Aquisição de Coleção** | Obter Carta | Criar Carta | Preserva a diferenciação com invocação de unidades em combate. |
| **Invocação em Combate** | Criar Unidade | Criar Carta | Invocações temporárias no tabuleiro são Unidades, não Cartas. |

---

# Termos Fundamentais

### Carta

Item colecionável permanente pertencente ao acervo do Reino.

* Ver: `ACADEMY.md`, `CARD_PROGRESSION.md`

### Pelotão

Representação militar de uma Carta no campo de batalha.

* Ver: `COMBAT_CORE.md`

### Unidade

Qualquer elemento ativo presente no campo de batalha.

* Ver: `COMBAT_CORE.md`

### Formação

Disposição e organização espacial dos Pelotões no Exército. Cada Exército possui cinco Formações permanentes (α, β, γ, δ, ε), que compartilham exatamente o mesmo Comandante, Pelotões e Cartas — diferem apenas no posicionamento. O jogador define previamente a ordem de prioridade de uso das Formações.

* Ver: `ARMY.md`

### Exército

Conjunto tático composto por um Comandante e seus Pelotões em Formação.

* Ver: `COMMANDERS.md`

### Reino

Identidade permanente do jogador, compreendendo toda a sua infraestrutura, acervo e progressão.

* Ver: `CITY.md`

---

# Construções

### Capital

Construção central e marco de desenvolvimento da Cidade.

* Ver: `CAPITAL.md`

### Centro de Comando (CdC)

Construção responsável pela infraestrutura e administração militar do Reino.

* Ver: `COMMAND_CENTER.md`

### Academia

Construção dedicada ao desenvolvimento tecnológico e de conhecimento do Reino.

* Ver: `ACADEMY.md`

### Depósitos

Estrutura destinada à salvaguarda dos recursos de construção do Reino.

* Ver: `DEPOSITS.md`

### Núcleo de Energia

Construção responsável pela infraestrutura energética do Reino.

* Ver: `ENERGY_NUCLEUS.md`

---

# Recursos e Economia

### Essência Vital

Recurso de construção associado ao desenvolvimento orgânico do Reino.

* Ver: `RESOURCES.md`

### Ferro Negro

Recurso bruto de construção associado à infraestrutura física do Reino.

* Ver: `RESOURCES.md`

### Cristais Arcanos

Recurso de construção associado ao avanço tecnológico e energético do Reino.

* Ver: `RESOURCES.md`

### Fragmentos

Recurso especializado destinado à aquisição de novas Cartas.

* Ver: `RESOURCES.md`

### Soldo

Recurso administrativo destinado à gestão e expansão militar.

* Ver: `SOLDO.md`

### Pontos de Geração (PG)

Recurso global de infraestrutura do Reino, gerado pelo avanço de Nível de Conta (XP → PG). Não é exclusivo de nenhum sistema — atualmente aplica-se a Minas, Depósitos, Centro de Comando e Academia, podendo receber novas aplicações no futuro.

* Ver: `GENERATION_POINTS.md`

### Coeficiente Econômico Global (CEG)

Parâmetro de controle da escala econômica global do jogo.

* Ver: `FORMULAS.md`

---

# Mecânicas de Progressão

### Tier

Sistema de evolução e aprimoramento de Cartas.

* Ver: `CARD_PROGRESSION.md`

### Afinidade

Sistema de agrupamento estratégico por Facção dentro de um Exército, com Pontos e Níveis próprios.

* Ver: `AFFINITY.md`

### Sinergia

Mecânica das Habilidades de Campanha (Tier III): ativa um bônus adicional quando 2 ou mais pelotões do mesmo Exército possuem a mesma Habilidade de Campanha.

* Ver: `ABILITIES.md`

### Patente

Nível hierárquico de progressão de um Comandante.

* Ver: `COMMANDERS.md`, `SOLDO.md`

### XP do Comandante

Indicador de progresso e carreira individual de um Comandante.

* Ver: `XP.md`

### XP de Conta (Reino)

Indicador de progresso e desenvolvimento global do Reino.

* Ver: `XP.md`

### XP Estrutural

Experiência de Conta associada a conquistas e expansões permanentes do Reino.

* Ver: `XP.md`

### XP Operacional

Experiência de Conta associada a atividades e operações recorrentes.

* Ver: `XP.md`

### Temporada

Ciclo temporal de renovação e atualização de conteúdos do jogo.

* Ver: `SEASONS.md`

---

# Combate e Estatísticas

### Batalha

Confronto tático entre Exércitos simulado em ambiente reservado.

* Ver: `COMBAT_CORE.md`

### Campo de Batalha

Espaço delimitado onde se realiza a Batalha.

* Ver: `COMBAT_CORE.md`

### Combat State

Estado temporário de uma Unidade durante uma Batalha.

* Ver: `COMBAT_CORE.md`

### Turno

Unidade de tempo tática que estrutura a sequência de eventos em combate.

* Ver: `TURN_SEQUENCE.md`

### Ataque (ATK)

Atributo que representa o potencial ofensivo de uma Unidade.

* Ver: `COMBAT_RULES.md`

### Escudo (ESC)

Atributo de proteção temporária de uma Unidade.

* Ver: `COMBAT_RULES.md`

### Pontos de Vida (HP)

Atributo que representa a vitalidade de uma Unidade.

* Ver: `COMBAT_RULES.md`

### Linha

Divisão horizontal do Campo de Batalha.

* Ver: `COMBAT_CORE.md`

### Coluna

Divisão vertical do Campo de Batalha.

* Ver: `COMBAT_CORE.md`

### Posição

Identificador de localização na grade de Formação do Exército.

* Ver: `COMBAT_CORE.md`

### Classe

Papel tático desempenhado por uma Carta ou Pelotão.

* Ver: `CLASSES.md`

### Tipo

Sub-classificação temática opcional de uma Carta (ex: Esqueleto, Aparição, Zumbi), usada por Características de Unidade que concedem bônus a aliados do mesmo Tipo. Independente da Classe.

* Ver: `CARD_CATALOG.md`

### Habilidade

Efeito especial ou capacidade tática de uma Carta ou Pelotão.

* Ver: `ABILITIES.md`

### Clima

Condição ambiental temporária incidente no Campo de Batalha.

* Ver: `WEATHER.md`

---

# Comandantes e Administração Militar

### Comandante

Líder tático do Exército e condutor de suas diretrizes estratégicas.

* Ver: `COMMANDERS.md`

### Comandante Base

Comandante nativo do Reino que representa o padrão tático neutro de sua Facção.

* Ver: `COMMANDERS.md`

### Candidato

Comandante em potencial disponível para recrutamento.

* Ver: `COMMANDERS.md`

### Comissionamento

Ato de incorporação formal de um Comandante ao quadro do Reino.

* Ver: `COMMANDERS.md`

### Fonte de Recrutamento

Origem ou meio pelo qual novos Comandantes são apresentados ao Reino.

* Ver: `COMMANDERS.md`

### Doutrina Militar

Conjunto de diretrizes estratégicas impostas por um Comandante ao seu Exército.

* Ver: `COMMANDERS.md`

### Restrição

Condição tática estabelecida pelo Comandante para a composição do Exército.

* Ver: `COMMANDERS.md`

### Vantagem

Benefício tático fornecido pelo Comandante ao seu Exército.

* Ver: `COMMANDERS.md`

---

# Modos de Jogo e Interface

### PvE

Modo de jogo focado em desafios e campanhas contra o ambiente.

* Ver: `PvE.md`

### Squad

Agrupamento de Exércitos utilizado por um modo de jogo específico (ex: PvE, PvP). Não substitui o conceito de Exército — apenas os agrupa e define sua ordem de prioridade de uso. Não controla Combate, Energia, Minas ou Progressão.

* Ver: `ARMY.md`

### Expedição

Tentativa ativa de um jogador de percorrer uma Trilha da Campanha PvE. Distinta da Trilha (conteúdo permanente e compartilhado): a Expedição é o estado daquele jogador — Squad ativo, Trecho/Fase atual, contagem de Replay e política de Acampamento.

* Ver: `PvE.md`

### Replay de Trilha

Nova Expedição iniciada em uma Trilha já concluída integralmente (todos os Chefes Regionais derrotados). Exige uma quantidade crescente de Exércitos no Squad (1 na Campanha inicial, 2 no primeiro Replay, 3 nos seguintes) e reinicia a progressão de Fases da Trilha desde o início.

* Ver: `PvE.md`

### PvP

Modo de jogo focado em confrontos competitivos contra outros Reinos.

* Ver: `MATCHMAKING.md`, `RANKING.md`

### Minas

Modo de jogo voltado à conquista de territórios e extração de recursos.

* Ver: `MINES.md`

### Arsenal

Interface dedicada à gestão e composição militar do Reino.

* Ver: `COMMANDERS.md`

### Biblioteca

Interface dedicada à consulta do acervo e conhecimento do jogo.

* Ver: `LIBRARY.md`

### Observatório

Interface dedicada à análise e estatísticas do Reino.

* Ver: `OBSERVATORY.md`

---

## Referências

* **DECISOES.md:** Diretrizes e convenções arquiteturais do projeto.
* **GAME_PHILOSOPHY.md:** Princípios de design e conceitos fundamentais do jogo.
* **Demais documentos `/docs`:** Fontes Únicas de Verdade dos respectivos domínios técnicos.