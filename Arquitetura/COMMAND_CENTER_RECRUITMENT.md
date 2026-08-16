```markdown
# COMMAND_CENTER_RECRUITMENT.md

# Sistema de Incorporação de Comandantes

## Objetivo

Este documento define todo o ciclo de incorporação dos Comandantes ao Reino. Ele é o Single Source of Truth (SSoT) para o processo que transforma comandantes gerados pelo Motor de Geração em oficiais pertencentes ao Reino do jogador.

O Sistema de Incorporação não cria comandantes; ele administra exclusivamente sua transição de um estado gerado externamente para o Estado Administrativo Reserva do Reino.

---

# Filosofia

O sistema foi projetado para criar decisões estratégicas de gerenciamento de recursos.

O Sistema de Incorporação administra exclusivamente a incorporação de comandantes ao Reino, transformando oportunidades geradas pelo jogo em decisões administrativas do jogador. A Geração de Comandantes continua sendo um evento externo e aleatório (ver `COMMANDER_GENERATION.md`). A escolha do jogador consiste em decidir quais comandantes merecem ocupar as limitadas Vagas da Reserva disponíveis do Reino (ver `COMMAND_CENTER_PROGRESS.md`).

Dessa forma:
- A geração permanece aleatória;
- A administração torna-se estratégica;
- A identidade de cada Reino depende das decisões de gerenciamento do jogador.

---

# Arquitetura do Sistema

O processo de incorporação é estruturado através de Fontes de Recrutamento independentes que convergem para um processo unificado de Comissionamento.

## Fluxo Arquitetural

```text
Motor de Geração (Evento Externo - SSoT: COMMANDER_GENERATION.md)
           ↓
Fontes de Recrutamento (Módulos Independentes)
           ↓
Painéis de Recrutamento (Interface Específica)
           ↓
Comissionamento (Processo Unificado de Incorporação)
           ↓
Estado Administrativo: Reserva (SSoT: COMMAND_CENTER.md)
           ↓
Ocupação de Vagas da Reserva (SSoT: COMMAND_CENTER_PROGRESS.md)

```

---

# Conceitos Fundamentais

## Candidato

Todo comandante gerado externamente torna-se inicialmente um Candidato dentro de uma Fonte de Recrutamento específica.

O Candidato:

* Já existe no sistema;
* Possui todos os atributos definidos;
* Pode ser visualizado pelo jogador;
* Apresenta-se com a patente inicial de Recruta;

Entretanto:

* Ainda não pertence ao Reino;
* Não ocupa Recursos Administrativos (Cargos de Comando Ativo ou Vagas da Reserva);
* Não participa dos demais sistemas (Treinamento, Combate, Legado).

---

## Fontes de Recrutamento

Representam os diferentes sistemas do jogo que podem disponibilizar Candidatos ao jogador. Cada Fonte constitui um módulo autônomo e define exclusivamente como candidatos são disponibilizados, como permanecem disponíveis e quando deixam de estar disponíveis. Nenhuma Fonte pode alterar o processo de Comissionamento unificado, os Recursos Administrativos ou os Estados Administrativos.

## Painéis de Recrutamento

Cada Fonte de Recrutamento possui um Painel próprio na interface do Centro de Comando. O Painel administra exclusivamente os Candidatos pertencentes à sua Fonte. Novos Painéis podem ser adicionados futuramente sem alterar as regras estruturais deste documento.

## Comissionamento

O Comissionamento representa a incorporação oficial do Candidato ao Reino. Este processo unificado verifica a disponibilidade de Vagas da Reserva e efetiva a entrada do comandante no Reino, alterando seu Estado Administrativo para Reserva.

---

# Fontes de Recrutamento e Painéis

Abaixo estão detalhados o funcionamento das Fontes de Recrutamento iniciais e seus respectivos Painéis.

## 1. Centro de Recrutamento (Painel Centro de Recrutamento)

Esta fonte representa candidatos que procuram voluntariamente servir ao Reino através dos canais administrativos padrão. Ela utiliza **Slots de Recrutamento** e um sistema de geração centralizado para gerenciar a disponibilidade.

### Filosofia do Centro de Recrutamento

* Utiliza exclusivamente Recursos Administrativos do Centro de Comando para operar.
* Os candidatos gerados nesta fonte permanecem indefinidamente aguardando decisão do jogador, nunca expirando automaticamente.

### Slots de Recrutamento

Cada Slot representa uma posição de armazenamento independente dentro do Painel Centro de Recrutamento.

* Cada Slot administra exclusivamente um candidato e seu estado (ocupado ou vazio).
* Os Slots não possuem temporizadores ou cooldowns próprios.

### Capacidade e Progressão de Slots

* **Capacidade Inicial:** 3 Slots de Recrutamento.
* **Crescimento:** +1 Slot de Recrutamento a cada 10 níveis do Centro de Comando.

### Sistema de Geração e Cooldown

O Centro de Recrutamento possui um único sistema de geração com um cooldown centralizado. Este sistema produz **exatamente um novo candidato** ao término de cada ciclo de cooldown, ocupando um Slot vazio disponível. O cooldown pertence ao sistema de geração, e não aos Slots individuais.

* **Exceção Inicial:** ao criar o Reino, 1 Candidato já nasce disponível de imediato, ocupando o primeiro Slot — sem esperar o Cooldown Inicial. Única exceção a essa regra em todo este documento; existe pra o jogador ter, desde o primeiro instante, alguém pra recrutar e testar a Doutrina do Comandante (Restrição/Requisito/Efeito), sem depender de 24h reais de espera logo na largada.
* **Cooldown Inicial:** 24 horas (a partir do 2º Candidato em diante).
* **Progressão:** Redução de 1 hora no cooldown a cada 15 níveis do Centro de Comando.
* **Limite Mínimo:** O cooldown nunca será inferior a 12 horas.

### Ordem de Comissionamento

O jogador **não pode escolher livremente** qual Candidato comissionar quando há mais de um Slot ocupado — o Comissionamento segue obrigatoriamente a ordem de chegada (o Slot ocupado há mais tempo, sempre o de menor índice entre os ocupados). Um Slot posterior só pode ser comissionado depois que todos os Slots anteriores a ele já tiverem sido comissionados ou esvaziados.

### Persistência e Reposição Centralizada

Um candidato somente deixa seu Slot quando for Comissionado pelo jogador.

Quando ocorre um Comissionamento:

* O Slot correspondente torna-se vazio.
* O sistema de geração verifica se existe algum Slot vazio.
* Caso exista pelo menos um Slot vazio, inicia um único ciclo de cooldown centralizado.
* Caso o sistema de geração já esteja executando um ciclo de cooldown, nenhum novo ciclo adicional poderá ser iniciado. Novos Slots vazios permanecerão aguardando o término do ciclo em andamento.
* Ao término desse cooldown, apenas um novo candidato é gerado e ocupa o novo candidato ocupa sempre o primeiro Slot vazio conforme a ordem fixa de organização do Painel de Recrutamento..
* Caso ainda existam outros Slots vazios, inicia-se automaticamente um novo ciclo completo de cooldown.

Este processo continua sequencialmente até que todos os Slots estejam novamente ocupados.

**Exemplo de Reposição Sequencial:**

```text
Estado Inicial:
[Slot A: Ocupado (Cand. X)]
[Slot B: Ocupado (Cand. Y)]
[Slot C: Ocupado (Cand. Z)]

Ação: Jogador comissiona o candidato do Slot A e do Slot B. Sistema de Geração detecta Slots vazios e inicia Cooldown (24h).

Estado Intermediário (0h):
[Slot A: Vazio]
[Slot B: Vazio]
[Slot C: Ocupado (Cand. Z)]

Ação: Tempo passa (24h). Cooldown centralizado termina. Um novo candidato é gerado e ocupa o primeiro Slot vazio. Sistema detecta que ainda há Slots vazios e inicia NOVO Cooldown (24h).

Estado Intermediário (24h):
[Slot A: Ocupado (Cand. D)]
[Slot B: Vazio]
[Slot C: Ocupado (Cand. Z)]

Ação: Tempo passa (24h). Cooldown centralizado termina. Um novo candidato é gerado e ocupa o primeiro Slot vazio. Sistema detecta que todos os Slots estão ocupados e encerra o ciclo de geração.

Estado Final (48h):
[Slot A: Ocupado (Cand. D)]
[Slot B: Ocupado (Cand. E)]
[Slot C: Ocupado (Cand. Z)]

```

*Nota: Mesmo existindo múltiplos Slots vazios, apenas um novo candidato é gerado por ciclo de cooldown.*

---

## 2. Campanhas PvE (Painel PvE)

Esta fonte representa comandantes encontrados ou conquistados durante campanhas narrativas e missões PvE.

### Capacidade e Geração

* **Capacidade Máxima:** 10 candidatos simultâneos neste Painel.
* **Geração:** Novos candidatos PvE surgem exclusivamente quando eventos específicos determinados pela engine de PvE ocorrerem (ex: conclusão de missão, drop raro).
* **Reposição:** A existência de vagas livres no Painel PvE nunca gera novos candidatos automaticamente. A expiração ou comissionamento de um candidato PvE nunca gera outro.

### Permanência e Expiração

Ao contrário do Centro de Recrutamento, os candidatos PvE possuem tempo de permanência limitado.

* **Tempo de Permanência:** Cada candidato permanece disponível por **4 dias (96 horas)**.
* **Tempo Individual:** A contagem regressiva é individual para cada candidato.
* **Expiração:** Após este período, o candidato deixa permanentemente o Painel e não poderá mais ser incorporado ao Reino. Narrativamente, considera-se que o comandante seguiu outro caminho.

---

## 3. Eventos Temporários (Painel Eventos)

Eventos especiais podem gerar candidatos exclusivos por tempo limitado. Esta fonte possui regras específicas de geração e disponibilidade definidas pelo evento vigente, respeitando a arquitetura unificada de Comissionamento deste documento.

---

# Processo Unificado de Comissionamento

O Comissionamento é a ação administrativa que efetiva a entrada do Candidato no Reino. Nenhuma Fonte de Recrutamento pode alterar este processo unificado.

## Requisitos

Para que o Comissionamento ocorra, são necessários:

* Um Candidato válido em qualquer Painel de Recrutamento.
* Uma Vaga da Reserva disponível (conforme `COMMAND_CENTER_PROGRESS.md`).

## Efeitos do Comissionamento

Ao ser comissionado, o comandante:

* Deixa o Painel de Recrutamento correspondente (e libera o Slot se originado do Centro de Recrutamento, possivelmente iniciando o sistema de geração);
* Passa a integrar oficialmente o Reino do jogador;
* Ocupa uma Vaga da Reserva disponível;
* Ingressa no **Estado Administrativo Reserva** (conforme `COMMAND_CENTER.md`);
* Mantém sua patente inicial de Recruta.

---

# Patente Inicial

Independentemente da Fonte de Recrutamento (Centro de Recrutamento, PvE, Eventos, Expansões Futuras) ou de recompensas especiais, todo comandante inicia sua carreira no Reino obrigatoriamente como:
**Patente: Recruta**
Sem exceções.

A progressão militar representa exclusivamente a carreira desenvolvida dentro do Reino do jogador. Nenhuma Fonte de Recrutamento ou processo de incorporação pode alterar a patente inicial.

---

# Interface do Sistema de Incorporação

A interface do Centro de Comando é estruturada para refletir as diferentes Fontes de Recrutamento.

## Estrutura da Tela

* **Painel Centro de Recrutamento:** Apresenta o contador global do próximo candidato (tempo de cooldown centralizado), a quantidade de Slots disponíveis e a quantidade de Slots ocupados. Apresenta também a lista de candidatos ocupando os Slots. *A interface nunca deve exibir cooldown individual para cada Slot.*
* **Painel PvE:** Apresenta a lista de candidatos PvE. Para cada candidato, exibe a campanha/missão de origem, o tempo de permanência restante e as informações do comandante.
* **Painel Eventos:** Lista de Candidatos de eventos (quando aplicável), com regras visuais específicas do evento.
* **Indicadores Administrativos:** Exibe a Ocupação/Capacidade total do Reino (Cargos Ativos e Reserva) conforme definido em `COMMAND_CENTER_PROGRESS.md`.
* **Histórico de Comissionamentos:** Lista informativa dos recrutamentos mais recentes, apresentando o nome do comandante e a Fonte de Recrutamento de origem (finalidade exclusivamente informativa).

**Exemplo de Histórico:**

```text
Últimos Comissionamentos

[Marcus] - [Centro de Recrutamento]
----------------------------------
[Edwin] - [Campanha Norte]
----------------------------------
[Viktor] - [Evento Aniversário]

```

---

# Regras Gerais, Responsabilidades e Escalabilidade

## Responsabilidades do Sistema de Incorporação

O Sistema de Incorporação possui responsabilidade exclusiva sobre o processo administrativo de entrada no Reino. Nenhuma Fonte de Recrutamento pode:

* Criar ou modificar Recursos Administrativos (Cargos Ativos ou Vagas da Reserva);
* Alterar atributos ou a patente inicial de Recruta do comandante;
* Alterar o processo de Comissionamento unificado.

## Regras Estruturais Obrigatórias

* Todo comandante gerado passa por uma Fonte de Recrutamento como Candidato.
* Nenhum comandante entra diretamente no Reino sem passar pelo processo de Comissionamento.
* Todo comandante comissionado inicia como Recruta.
* O Comissionamento exige Vagas da Reserva disponíveis.

## Escalabilidade e Futuras Expansões

O sistema é projetado para ser modular. Novas Fontes de Recrutamento (ex: Guildas, Mercado de Mercenários) podem ser adicionadas futuramente como módulos autônomos. O processo de expansão exige apenas a criação de:

* Um novo Painel de interface;
* Suas próprias regras de geração/disponibilização;
* Suas próprias regras de permanência/expiração.

Essas novas fontes **jamais** poderão modificar o processo de Comissionamento unificado, os Recursos Administrativos ou os Estados Administrativos definidos na arquitetura do jogo.

---

# Casos Especiais

## Centro de Recrutamento (Slots e Geração)

* **Reserva Cheia:** Se a Reserva estiver completa (Vagas da Reserva esgotadas), o jogador não poderá realizar o Comissionamento. O candidato permanecerá ocupando o Slot Disponível, aguardando, sem ocupar capacidade do Reino e sem liberar o Slot para o sistema de geração.
* **Geração Sequencial:** Se múltiplos Slots estiverem vazios, a geração ocorre sequencialmente (24h para o primeiro, 24h para o segundo, etc.), gerando apenas um candidato por ciclo.

## PvE

* **Lista Cheia (PvE):** Se o Painel PvE atingir 10 candidatos, novos candidatos gerados pela engine PvE não poderão ser adicionados até que uma vaga seja liberada (por comissionamento ou expiração). A engine PvE deve gerenciar essa limitação (ex: enfileirar recompensas ou descartar se não houver espaço).
* **Expiração:** Ao expirar o tempo de 4 dias, o candidato PvE deixa definitivamente o Painel. Não existe mecanismo de recuperação. A expiração de um candidato nunca gera outro automaticamente.

---

# Relação com Outros Sistemas

Este documento possui dependências arquiteturais com os seguintes arquivos:

* **COMMAND_CENTER.md:** Define o Estado Administrativo Reserva para onde os comandantes ingressam após o Comissionamento.
* **COMMAND_CENTER_PROGRESS.md:** Define e fornece as Vagas da Reserva necessárias para realizar o Comissionamento.
* **COMMAND_CENTER_LEGACY.md:** Impacta indiretamente através de bônus na capacidade administrativa geral.
* **COMMANDER_GENERATION.md:** Fonte externa e aleatória que cria os comandantes (Motor de Geração) antes que se tornem Candidatos.

As regras internas desses sistemas não são definidas neste documento.