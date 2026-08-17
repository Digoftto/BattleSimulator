# TUTORIAL

# Objetivo

Este documento define a experiência de introdução ao jogo — a sequência de Etapas pela qual todo novo jogador passa, o que cada uma ensina, quem a apresenta (a Voz responsável) e qual Recompensa a conclui.

Não é um manual de interface. É a primeira Expedição do jogador dentro da própria história do Reino — cada Etapa é um passo real da Reconstrução, nunca uma interrupção artificial dela.

**Status deste documento:** referência de trabalho, não congelada. Serve pra consolidar decisões enquanto elas ainda estão sendo tomadas — não é a versão final. Quando o conjunto de Etapas estiver estável, o documento congela e passa a seguir o mesmo processo de qualquer outro: contradição futura = questionar antes de implementar, nunca assumir.

---

# Filosofia do Tutorial

## Revelação Progressiva, não um Manual Único

Cada sistema se apresenta no momento exato em que passa a ser possível usá-lo — nunca antes, nunca como uma lista de recursos que o jogador ainda não tem motivo pra usar. Não existe uma única "tela de tutorial"; existe uma sequência de Etapas, cada uma desencadeada pelo progresso real do jogador.

## Posicionamento Primeiro, Sempre

`GAME_PHILOSOPHY.md` já estabelece a hierarquia: Posicionamento > Classe > Facção > Carta > Habilidade. O tutorial de Combate segue essa mesma ordem — e por isso não é uma única batalha, é uma sequência de 4 (ver Etapa 1).

## Sem Rede de Segurança Artificial

O tutorial nunca trapaceia a favor do jogador. As regras de Combate, Energia e Soldo são sempre as mesmas, do primeiro combate ao centésimo.

## Cada Voz Pertence ao que Ensina

Nenhum narrador único, nenhuma "IA do sistema". Cada Etapa é apresentada por quem, dentro do próprio universo do jogo, faria esse chamado.

---

# As Vozes

| Voz | Quem é | Etapas em que fala |
|---|---|---|
| **O Reino** | Narração impessoal — usada apenas na abertura. | Etapa 0 |
| **O Comandante do jogador** | O Comandante escolhido no Kit Inicial — o tom reflete sua Facção. | Etapa 1 |
| **Um Engenheiro do Reino** | Voz funcional, responsável por operações de Mina. | Etapa 2 |
| **Um Mestre da Academia** | Um Artífice ou Metamorfo (`ACADEMY.md`). | Etapa 3 |
| **O Alto-Comando** | Voz administrativa impessoal do Centro de Comando. | Etapa 4, Etapa 4b |
| **Um Arquiteto do Reino** | Voz responsável pela Cidade e suas construções — Capital, Núcleo de Energia, Depósitos. | Etapa 5, 6, 7 |
| **O Comandante do jogador** (retorno) | Volta a falar nas Etapas sobre Exército, Formações, Doutrina e Squad — quem lidera fala de tática, não o Alto-Comando. | Etapa 8, 9, 11, 12, 13 |
| **Os Sábios** | Os estudiosos que descobriram os Portais (`LORE.md`). | Etapa 10 (Biblioteca) |
| **Um Arauto Rival** | Voz de fora do Reino, primeiro contato de igual pra igual. | Etapa 14 (Arena) |

---

# Etapa 0 — A Escolha

**Voz:** O Reino. **Sistema:** Kit Inicial (`COMMAND_CENTER_RECRUITMENT.md`).

Sem alteração — o sistema já implementado cumpre essa função. Recompensa: o próprio Comandante e Exército iniciais.

---

# Etapa 1 — A Primeira Marcha (4 combates)

**Voz:** O Comandante do jogador. **Sistema:** Posicionamento (`COMBAT_RULES.md`) e Trilha de PvE (`PvE.md`).

Divida em 4 combates sequenciais, cada um isolando uma lição — nunca todas de uma vez.

### Combate 1 — Linha de Frente
Ensina: Posicionamento básico, Classe Corpo a Corpo (só age na Linha 1, bônus na Posição 1) e Classe Barreira (mesma regra, bônus de Escudo na Posição 1).

### Combate 2 — Retaguarda
Ensina: Classe Mago e Classe Suporte — o motivo de ficarem protegidas atrás, não na linha de frente.

### Combate 3 — Artilharia
Ensina: Classe Máquina de Guerra — posição fixa e obrigatória (Posição 9, regra estrutural do motor, nunca escolha do jogador).

### Combate 4 — O Tabuleiro Inteiro
Ensina: as posições espaciais 1, 5 e 9 especificamente — o porquê de cada uma ser estrategicamente diferente (Posição 1: linha de frente, bônus de Classe; Posição 5: centro, alcance equilibrado; Posição 9: retaguarda absoluta, onde a Máquina de Guerra sempre fica).

**Recompensa:** a recompensa oficial de cada Fase (`PvE.md`) — sem bônus extra por Combate individual.

**Critério de conclusão:** os 4 combates vencidos, na ordem.

---

# Etapa 2 — As Veias da Terra

**Voz:** Um Engenheiro do Reino. **Sistema:** Minas Iniciais (`MINES.md`).

Ativar as 3 Minas Iniciais. Uma menção de que existem outras Minas nas Trilhas — sem explicar o funcionamento delas ainda (isso fica pra quando o jogador realmente encontrar a primeira, dentro da própria Trilha, ver Etapa 2b).

**Recompensa:** nenhuma extra — a produção já em andamento é a recompensa.

**Critério de conclusão:** as 3 Minas Iniciais ativadas.

## Etapa 2b — A Primeira Mina de Trilha (adiada)

Desencadeada só quando o jogador realmente encontra a primeira Mina Regional numa Trilha — explica Guarnição, Formação de Referência e Eficiência (`MINES.md`) nesse momento, não antes.

---

# Etapa 3 — O Chamado dos Sábios

**Voz:** Um Mestre da Academia. **Sistema:** Academia (`ACADEMY.md`), conceito de Raridade.

Ensina os dois caminhos de produção: Carta Comum direto por Fragmentos, e Carta Rara+ por combinação de outras Cartas (receita). Introduz o conceito de Raridade nesse momento — não antes, porque só faz sentido depois que o jogador já viu os dois caminhos de produção lado a lado.

**Recompensa:** Fragmentos suficientes pra produzir 3 Cartas Comuns — o bastante pra também testar a combinação em 1 Rara (`ACADEMY.md`: Rara é feita a partir de Comuns), sem depender de mais Fases de PvE antes de conseguir tentar os dois fluxos.

**Critério de conclusão:** 1 Carta produzida por Fragmentos E 1 Carta produzida por combinação.

---

# Etapa 4 — O Alto-Comando

**Voz:** O Alto-Comando. **Sistema:** Recrutamento, Reserva/Ativo (`COMMAND_CENTER_RECRUITMENT.md`, `COMMAND_CENTER_PROGRESS.md`).

Ensina: recrutar um Candidato, o Estado Reserva, e como conseguir mais Cargos Ativos/Vagas de Reserva (Expansão Administrativa, PG). Quando falar de PG, explicar de onde ele vem (XP de Conta) sem citar números exatos — só a relação: o Reino cresce, ganha XP, o XP vira PG.

**Recompensa:** nenhuma extra — a capacidade administrativa em si é a recompensa.

**Critério de conclusão:** 1 Comandante recrutado e movido pra Reserva.

## Etapa 4b — Treinamento (adiada)

Desencadeada quando o jogador alcança o Nível 3 do Centro de Comando (onde Vagas de Treinamento existem pela primeira vez, `COMMAND_CENTER_TRAINING.md`). Voz: Alto-Comando, de novo.

---

# Etapa 5 — Arquitetos do Reino

**Voz:** Um Arquiteto do Reino. **Sistema:** Evolução da Cidade (Capital, e as demais construções).

Explica pra que serve cada construção da Cidade, acompanhando o jogador enquanto ele evolui a Capital pela primeira vez. Recompensa: Recursos de construção suficientes pra realizar a primeira evolução de verdade durante a própria Etapa (não só assistir).

**Critério de conclusão:** primeira evolução de qualquer construção realizada.

---

# Etapa 6 — O Fôlego do Reino

**Voz:** Um Arquiteto do Reino. **Sistema:** Energia (`FORMULAS.md`, "Energia") e Núcleo de Energia.

Explica como a Energia Total é calculada (Base + Comandante + Pelotões), como evoluir o Núcleo de Energia pra aumentar a Base, e que a recuperação de Energia acontece na Cidade/Acampamento (não em qualquer lugar).

**Critério de conclusão:** visualizar a tela do Núcleo de Energia.

---

# Etapa 7 — Os Cofres do Reino

**Voz:** Um Arquiteto do Reino. **Sistema:** Depósitos e Reserva Antecipada de Evolução (`DEPOSITS.md`).

Explica os 3 Depósitos, sua relação com os 3 recursos de construção, e por que evoluir um Depósito é uma forma real de qualidade de vida (menos risco de perder produção das Minas por excesso de armazenamento enquanto o jogador está fora).

Ensina a Reserva Antecipada de Evolução: o jogador pode adiantar Recursos direto do Depósito pra qualquer construção em evolução, desafogando o Depósito — mas esse Recurso fica preso naquela construção especificamente (nunca volta, nunca é redirecionado), e a evolução só executa quando todos os Recursos exigidos estiverem completos ali.

**Critério de conclusão:** 1 transferência de Reserva Antecipada realizada.

---

# Etapa 8 — Formações

**Voz:** O Comandante do jogador. **Sistema:** Formações múltiplas no PvE (`PvE.md`).

Ensina que uma Expedição pode usar mais de 1 Exército/Formação simultaneamente, além da Formação-padrão já usada na Etapa 1.

**Critério de conclusão:** primeira Expedição com mais de 1 Formação.

---

# Etapa 9 — Montando o Exército

**Voz:** O Comandante do jogador. **Sistema:** Editor de Exército, conceito de Soldo (`SOLDO.md`), Filtros de Montagem Aleatória.

Ensina a criar um Exército do zero, o que é o teto de Soldo (ligado à Patente do Comandante), e como usar os Filtros da Montagem Aleatória (Facção principal/secundária, 2 ou 3 Facções, perfil ofensivo/defensivo — quando esse sistema estiver implementado).

**Critério de conclusão:** 1 Exército novo montado manualmente.

---

# Etapa 10 — A Biblioteca

**Voz:** Os Sábios. **Sistema:** Biblioteca (`LIBRARY.md`).

Sem alteração da versão anterior — desencadeada quando o jogador possui Cartas suficientes pra uma comparação fazer sentido.

---

# Etapa 11 — Squad

**Voz:** O Comandante do jogador. **Sistema:** Squad (múltiplos Exércitos coordenados).

Desencadeada ao concluir a primeira Trilha inteira (não a primeira Fase) — nesse ponto o jogador já viveu Formações (Etapa 8) o bastante pra entender o conceito mais amplo de Squad em retrospecto.

---

# Etapa 12 — A Doutrina do Comandante

**Voz:** O Comandante do jogador. **Sistema:** Restrição, Requisito, Alvo, Efeito e Valor (`COMMANDER_GENERATION.md` e correlatos).

Ensina que cada Comandante tem uma Doutrina própria — o que ele exige do Exército (Restrição), quando o bônus ativa (Requisito) e o que ele concede (Efeito/Valor). Também o momento certo de introduzir Patentes do Comandante e Tier das Cartas, já que ambos os conceitos se relacionam diretamente com o que o Exército pode ou não fazer.

**Critério de conclusão:** visualizar a Doutrina do próprio Comandante pelo menos uma vez.

---

# Etapa 13 — Território Além da Trilha (gates por Liga/Região)

**Voz:** O Comandante do jogador.

Duas sub-etapas, cada uma com seu próprio gate — nenhuma antes da hora:

## Plano de Campanha
Desencadeada ao alcançar a Liga Prata (`RANKING.md`). Explica como distribuir Exércitos entre os Campos Especiais.

## Campos de Batalha
Desencadeada ao alcançar a Região II OU a Liga Prata (o que vier primeiro). Explica como os Campos de Batalha influenciam o combate.

---

# Etapa 14 — A Arena

**Voz:** Um Arauto Rival. **Sistema:** PvP e Ligas (`RANKING.md`).

**Gate revisado:** não é mais "primeiro Exército competitivo qualquer" — agora exige que o jogador tenha **3 Comandantes Ativos, um dedicado a cada Trilha**, mais **um 4º Comandante Ativo livre**, pronto pra Liga Bronze. A ideia por trás: o jogador só encontra o PvP depois de já ter uma base real de domínio do jogo — Trilhas, Exércitos, Doutrina — não como primeiro contato com competição de verdade.

**Recompensa:** entrada na Liga Bronze (já documentada em `RANKING.md`).

**Critério de conclusão:** primeira Batalha de PvP disputada.

---

# Observações — Pendências que dependem de decisão do dono do projeto

* **Etapa 9:** depende da Montagem Aleatória com Filtros estar implementada — hoje ainda não está.
* Quantidade exata de Recursos/Fragmentos concedidos nas Etapas 3 e 5 — proponho valores pequenos, calibração final é do dono do projeto.

---

# Princípios Permanentes

* Nenhuma Etapa trava o jogador — todas apresentam, nenhuma obriga conclusão imediata.
* Nenhuma Etapa altera regras de jogo em favor do jogador.
* Toda Voz pertence à ficção já estabelecida — nenhum personagem novo é nomeado neste documento.
* Toda Etapa é desencadeada por progresso real do jogador, nunca por tempo decorrido.
* Etapas com gate de Liga/Região (13, 14) nunca disparam antes do gate ser atingido, mesmo que o jogador já tenha visitado a tela relevante.
