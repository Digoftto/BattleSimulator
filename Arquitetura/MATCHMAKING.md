# MATCHMAKING.md

# Sistema de Matchmaking

## Objetivo do Documento

Este documento define a arquitetura oficial do sistema de Matchmaking do Battle Simulator.

Ele estabelece a autoridade e a fonte única de verdade (*Single Source of Truth*) para:

* Entrada e validações operacionais de acesso ao sistema de matchmaking;
* Critérios e escopo de busca e seleção de participantes adversários;
* Escolha do participante defensor e formação do pareamento;


* Registro formal do confronto, incluindo o identificador único e a geração do Snapshot da batalha;
* Tratamento de concorrência e simultaneidade em combates;
* Reservas estruturais para regras de integridade do sistema.

Este documento **não** define regras de Ranking, Pontos de Liga (PL), Divisões, Patentes de Comandantes, progressão de XP, tabelas de recompensas, Plano de Campanha, regras de combate/execução nem resolução do resultado das batalhas. Esses domínios pertencem estritamente aos seus respectivos documentos de arquitetura.

---

# Filosofia e Escopo do Matchmaking

O Matchmaking atua como o orquestrador técnico de pareamento do Battle Simulator, conectando o ecossistema competitivo (`RANKING.md`) ao ambiente de execução de combate.

Seu único e exclusivo objetivo é:

$$\text{Receber Participante Elegível} \longrightarrow \text{Localizar Participante Defensor} \longrightarrow \text{Solicitar Estrutura Defensiva} \longrightarrow \text{Registrar Pareamento} \longrightarrow \text{Gerar Snapshot} \longrightarrow \text{Entregar ao Combate}$$

## Princípio do Power Score

O poder acumulado das cartas ou a composição do exército (**Power Score**) não é utilizado como critério de pareamento.

> **Regra Permanente:** O Power Score das cartas, unidades e exércitos é terminantemente desconsiderado no pareamento competitivo. O matchmaking baseia-se exclusivamente no posicionamento e elegibilidade do participante na Liga e Divisão vigentes.
> 
> 

---

# Fluxo Operacional de Matchmaking

## 1. Entrada no Matchmaking

A entrada no sistema de busca ocorre quando um participante solicita uma partida ranqueada de ataque.

Antes de iniciar qualquer busca, o sistema de Matchmaking exige que as seguintes validações prévias já tenham sido concluídas e confirmadas pelos módulos responsáveis:

* **Validação de Elegibilidade de Liga:** Confirmação de que o participante cumpre os requisitos de acesso e elegibilidade para a Liga (`COMMANDERS.md` / `RANKING.md`).
* **Validação de Inscrição Ativa:** Confirmação de que a inscrição e configuração do participante estão ativas para a temporada atual (`RANKING.md`).
* **Validação de Recursos Operacionais:** Confirmação de que a conta possui a energia/recursos necessários para a realização do confronto (`ENERGY.md`).

Quando o participante entra na fila de matchmaking, a validação de acesso e elegibilidade já ocorreu.

---

## 2. Busca de Adversários

O sistema de busca opera com base no conceito abstrato de **Participante Elegível**:

* A busca ocorre entre participantes elegíveis conforme os critérios competitivos definidos para aquela Liga.
* A Patente do Comandante **não** participa do cálculo ou da seleção de adversários. Ela determina apenas a elegibilidade de acesso à Liga, que já foi validada previamente.


* O algoritmo específico de expansão da busca poderá evoluir sem alterar a arquitetura deste documento.

---

## 3. Seleção do Defensor

O Matchmaking é responsável por selecionar um participante defensor válido que atenda aos critérios da fila de busca daquela Liga.

* O Matchmaking seleciona apenas um participante defensor válido que esteja elegível na mesma faixa competitiva.
* A estrutura defensiva utilizada na batalha é fornecida pelo módulo responsável pela configuração defensiva (`COMMAND_CENTER.md`).
* O Matchmaking não interpreta nem monta essa estrutura; sua responsabilidade limita-se a requisitá-la ao módulo competente para a geração do Snapshot.

---

## 4. Registro da Partida

Uma vez localizado um defensor válido, o sistema de Matchmaking realiza o registro formal do confronto.

O registro contém obrigatoriamente as seguintes informações:

* **Identificador Único do Confronto:** Identificador exclusivo da partida (Battle ID ou equivalente), servindo como referência permanente do confronto durante toda a sua existência.
* **Identificador do Atacante:** Registro do participante ativo na ação ofensiva.
* **Identificador do Defensor:** Registro do participante selecionado para a defesa.
* **Instante do Pareamento:** Timestamp exato da formação do confronto em horário UTC.
* **Snapshot do Combate:** Estado do jogo e das forças registrado no momento do pareamento.

---

# Snapshot e Concorrência

## 1. Snapshot da Batalha

No momento em que o pareamento é confirmado, o Matchmaking gera um **Snapshot** imutável do confronto.

* O Snapshot registra todas as informações necessárias para permitir a reprodução determinística daquela batalha.
* Quaisquer alterações posteriores realizadas pelos jogadores em suas contas, exércitos, cartas ou composições **não afetam** a partida em andamento.
* O Snapshot é entregue diretamente ao motor de combate para a execução da batalha.

## 2. Concorrência e Simultaneidade

O sistema de Matchmaking suporta a ocorrência de múltiplos confrontos simultâneos envolvendo o mesmo defensor:

* Múltiplos atacantes podem enfrentar simultaneamente o mesmo participante defensor.
* Cada confronto é totalmente isolado e processa seu próprio Snapshot independente.
* As ações de um confronto não interferem nos exércitos ou na execução das batalhas simultâneas de outros atacantes contra o mesmo defensor.

---

# Integridade do Matchmaking

Esta seção é reservada às diretrizes e mecânicas de proteção, estabilidade e integridade da fila de pareamento:

* **Prevenção de Repetição Excessiva:** Mecanismos para evitar que o mesmo atacante seja pareado consecutivamente contra o mesmo defensor em curtos intervalos de tempo.
* **Prevenção de Abuso e Colusão:** Algoritmos para identificar e bloquear tentativas de manipulação da fila por pareamento combinado entre contas.
* **Proteção de Integridade do Sistema:** Salvaguardas contra exploração de desconexões, cancelamentos maliciosos de fila ou manipulação de latência.

*Os algoritmos e limites numéricos específicos destas proteções serão detalhados conforme a demanda técnica de implementação.*

---

# Regras Permanentes do Módulo

* O Matchmaking **nunca** altera Ranking, Divisões ou Pontos de Liga (PL).
* O Matchmaking **nunca** calcula nem distribui recompensas econômicas ou recursos.
* O Matchmaking **nunca** resolve combates nem determina o vencedor de uma batalha.
* O Matchmaking **nunca** altera Patentes ou concede experiência (XP).


* O Matchmaking limita-se estritamente a receber um participante elegível, localizar um participante defensor válido, solicitar a estrutura defensiva ao módulo competente, registrar o pareamento, gerar o Snapshot e entregá-lo ao sistema de combate.
* O Power Score de cartas, unidades ou exércitos **não** é utilizado como critério de pareamento.



---

# Referências

* **RANKING.md:** Autoridade única para temporadas, Pontos de Liga (PL), Divisões, modelos competitivos e progressão no Ranking.
* **COMMANDERS.md:** Autoridade única para Patentes de Comandantes e validações de elegibilidade.


* **RESOURCES.md:** Autoridade única para cálculo e distribuição de recompensas econômicas.
* **ENERGY.md:** Autoridade única para requisitos e consumo de energia operacional.
* **COMMAND_CENTER.md:** Autoridade única para a configuração e fornecimento das estruturas defensivas.
* **SISTEMA DE COMBATE (A ser documentado):** Autoridade única para regras de combate, simulação e resolução do resultado das batalhas.