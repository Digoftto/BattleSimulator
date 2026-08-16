Markdown
# COMBAT_RULES.md

## Objetivo

Este documento define **todas as regras operacionais** do Sistema de Combate do Battle Simulator. Ele serve como o manual técnico definitivo para a implementação da engine de combate, descrevendo o funcionamento de cada mecânica, fase e entidade durante uma batalha.

Para a arquitetura conceitual, responsabilidades do sistema e fluxo macro, consulte o documento `COMBAT_CORE.md`.

## Filosofia Operacional e Combat State

O Sistema de Combate é o módulo responsável por resolver os confrontos entre exércitos. Ele opera como uma engine determinística e automática.

### Fonte Única da Verdade (SSoT)

A engine de combate opera estritamente sob o princípio da orquestração. Ela é proprietária do fluxo da batalha, mas nunca das regras específicas das entidades. Toda lógica individual de cartas, definições de habilidades, bônus de afinidade, efeitos de comandantes ou mecânicas de campos de batalha permanecem exclusivamente em seus documentos proprietários (`CARD_CATALOG.md`, `ABILITIES.md`, `AFFINITY.md`, `COMMANDERS.md`, `BATTLEFIELDS.md`). A engine apenas consulta esses documentos para obter definições e aplica seus resultados ao estado do combate.

### Combat State (Battle Runtime Layer)

Durante a execução de uma batalha, a engine mantém uma camada arquitetural mutável denominada **Combat State** (ou Battle Runtime). Este estado representa os dados temporários e dinâmicos existentes exclusivamente durante a execução da batalha.

A engine **NÃO** modifica os documentos de definição do projeto. Ela consulta os documentos especializados para obter as regras e constrói o Combat State inicial. Durante o combate, ela atualiza apenas este estado interno.

O Combat State armazena, entre outras, as seguintes informações necessárias para executar a batalha:

*   HP atual de cada Pelotão.
*   Escudo atual de cada Pelotão.
*   Posições atuais dos Pelotões no campo.
*   Modificadores ativos (Buffs e Debuffs).
*   Duração restante de efeitos temporários.
*   Recargas (Cooldowns) de habilidades.
*   Campo de Batalha ativo e seus efeitos.
*   Níveis atuais de Afinidade e bônus aplicados.
*   Contador de Turnos.

Esta camada de dados temporários é reiniciada a cada nova batalha.

## 1. Estrutura da Batalha

### 1.1. Campo de Batalha

Cada exército é composto por nove pelotões posicionados em um campo próprio, seguindo o diagrama oficial:

```text
Linha 1 (Frente): [1] [2] [3]
Linha 2 (Meio):   [6] [5] [4]
Linha 3 (Fundo):  [7] [8] [9]
Cada posição representa um momento diferente da batalha. Pelotões posicionados na frente entram em combate primeiro; pelotões na retaguarda entram gradualmente conforme o avanço do combate.

1.2. Pré-condições de Formação (ARMY.md SSoT)
Antes do início da batalha, a engine valida a formação do exército conforme as regras definidas em ARMY.md. Batalhas não podem ser iniciadas se as pré-condições não forem satisfeitas.

1.3. Condições de Encerramento e Vitória
Uma batalha termina imediatamente quando ocorrer uma das seguintes situações:

1.3.1. Eliminação Total
Um jogador vence quando todos os pelotões adversários forem destruídos.

1.3.2. Eliminação Simultânea
Caso o último pelotão de ambos os jogadores seja destruído durante o mesmo turno (durante a fase de Resolução das Mortes), o resultado é considerado empate.

1.3.3. Limite de Turnos
A batalha possui duração máxima de 64 Turnos. Ao término do turno 64:

Vence o jogador que possuir maior número de pelotões vivos no Combat State.

Caso ambos possuam a mesma quantidade de pelotões vivos, a batalha termina empatada.

2. Inicialização da Batalha
Esta etapa representa a preparação completa da engine antes do início do primeiro Turno. Ela ocorre apenas uma vez por batalha.

2.1. Fluxo de Inicialização
Nesta etapa, a engine orquestra sequencialmente:

Validação Final: Confirmação da integridade dos dados do Exército conforme ARMY.md.

Configuração do Combat State Inicial: A engine consulta os documentos de definição (CARD_CATALOG.md, COMMANDERS.md, BATTLEFIELDS.md, AFFINITY.md) para criar os dados de runtime.

Identificação do Campo sorteado e aplicação de seus efeitos iniciais conforme BATTLEFIELDS.md.

Registro dos modificadores do Campo de Batalha que permanecerão ativos por toda a batalha (BATTLEFIELDS.md).

Cálculo inicial e snapshot dos níveis de Afinidade (AFFINITY.md).

Inicialização de Atributos: Definição dos atributos atuais (HP, Escudo) baseados nos valores base da carta (CARD_CATALOG.md).

Modificadores Passivos: Aplicação de modificadores passivos de Comandantes (COMMANDERS.md), Características (Tier I - ABILITIES.md) e bônus de Afinidade ao Combat State.

Gatilhos de "Início da Batalha": Executa efeitos cujo gatilho seja "Início da Batalha".

Construção do Estado Inicial: Consolidação do Combat State completo para o Turno 1.

3. Fluxo Oficial do Turno
Todo turno segue rigorosamente a sequência de Fases descrita abaixo. A ordem de resolução é fixa e simultânea para ambos os exércitos em cada fase. A engine utiliza a Ordem Oficial de Resolução (ver seção 6.1) para desempatar eventos simultâneos quando necessário.

3.1. Princípios do Fluxo e Snapshot de Fases
As ações dentro de uma mesma fase são consideradas simultâneas no Combat State. Informações calculadas ou estados definidos durante uma fase do turno permanecem congelados e são considerados a verdade absoluta para todas as resoluções daquela fase, até que o fluxo do turno ou uma regra específica determine sua atualização.

3.2. Sequência Geral do Turno
Cada turno segue rigorosamente a sequência abaixo:

Início do Turno: Processamento de gatilhos de "Início de Turno" e verificações iniciais da engine.

Atualização do Combat State (Ambiente):

Consulta e atualização de sistemas do Campo de Batalha conforme BATTLEFIELDS.md.

Recálculo e snapshot dos níveis de Afinidade no Combat State conforme AFFINITY.md.

Aplicação de Efeitos Passivos e Buffs: Efeitos passivos e modificadores ativos (Buffs/Debuffs) de Campo, Afinidade, Comandantes e Habilidades entram em vigor e são aplicados aos Pelotões no Combat State.

Movimentação (Fase de Avanço): Pelotões movem-se simultaneamente conforme regras de Movimento (seção 5.2) e Classes (capítulo 6).

Seleção de Alvos: Alvos são definidos e congelados (Snapshot no Combat State) conforme regras de Alvos (seção 5.3) e Classes (capítulo 6).

Execução das Ações: Fase principal de resolução de combate. A engine orquestra a execução orquestrada de todos os efeitos acionados ou programados para esta fase, respeitando gatilhos, Hierarquia das Regras (capítulo 7) e Ordem Oficial de Resolução (seção 6.1). Isso inclui:

Características da Carta (Tier I - ABILITIES.md).

Habilidades do Comandante (COMMANDERS.md).

Ataques Básicos (determinados pela Classe).

Habilidades da Carta (Tier V - ABILITIES.md).

Processamento de efeitos produzidos durante essas ações.

Resolução das Mortes: Verificação de HP zero, processamento de gatilhos "Ao Morrer", remoção simultânea de Pelotões destruídos do Combat State e aplicação de efeitos relacionados (ex: Agrupamento Mortos-Vivos).

Orquestração de Reanimações e Evocações: Mecânicas que criam novas unidades (Evocação) ou retornam unidades destruídas (Reanimação) são resolvidas nesta fase, conforme os gatilhos e regras individuais definidos em CARD_CATALOG.md e ABILITIES.md. A engine utiliza a Ordem Oficial de Resolução (seção 6.1) para determinar a prioridade de posicionamento caso múltiplas unidades tentem ocupar o mesmo espaço simultaneamente no Combat State.

Avanço de Turno: Processamento de gatilhos de "Fim de Turno", verificação de condições de vitória (ver seções 1.3.1 e 1.3.2) e incremento do contador de turnos no Combat State.

Caso nenhuma condição de vitória seja satisfeita, um novo turno é iniciado.

4. Mecânicas Gerais da Engine (Combat State)
Estas regras definem como a engine processa estados e interações básicos aplicáveis a qualquer Pelotão, independentemente de sua Classe.

4.1. Vida (HP) e Escudo (ESC)
A Vida (HP) representa a integridade operacional do pelotão no Combat State. Quando o HP de um pelotão atinge zero no Combat State, ele é considerado destruído. O Escudo absorve dano antes da Vida. Enquanto existir Escudo no Combat State, nenhum dano é aplicado à Vida (salvo habilidades com penetração, definidas em ABILITIES.md). O Escudo nunca ultrapassa seu valor máximo definido na carta.

A engine verifica Pelotões com HP zero no Combat State na Fase de Resolução das Mortes. Todas as mortes são resolvidas simultaneamente. Um pelotão destruído durante o turno executa normalmente a ação que iniciou naquele turno (Ataque, Habilidade ou Suporte) antes de ser removido.

4.2. Dano, Cura e Recuperação
4.2.1 Dano e Redução de HP
Dano reduz ESC/HP no Combat State. A resolução de dano e a morte de Pelotões seguem as regras de Simultaneidade e Snapshot de Fases (ver seção 3.1).

4.2.2 Definição de Cura e Recuperação
Considera-se que um pelotão foi curado apenas quando uma ação estrutural, habilidade ou efeito recuperar pelo menos 1 ponto de HP no Combat State. Caso uma cura seja aplicada a um pelotão que já esteja com seu HP máximo no Combat State, nenhuma recuperação ocorre e o pelotão não é considerado como tendo sido curado.

Prioridade de Cura: Quando houver uma ação de cura (estrutural ou por Habilidade), o alvo priorizado é sempre o pelotão aliado no Combat State que perdeu a maior quantidade de HP em valor absoluto.

4.2.3 Cura Estrutural da Classe Suporte
Todo pelotão da Classe Suporte possui, por definição estrutural do Motor de Combate — e não como Habilidade —, uma ação de Cura ao aliado vivo com maior quantidade de HP perdido (ver Prioridade de Cura, seção 4.2.2).

Valor Base: 20 HP.

Este valor pertence exclusivamente ao Motor de Combate e existe independentemente de qualquer Habilidade, Carta, Facção, Comandante, Afinidade ou Campo de Batalha. Nenhum desses sistemas cria uma nova cura — todos apenas modificam este valor base, segundo a Hierarquia Oficial de Modificadores de Cura:

1. Regra Estrutural da Classe (20 HP).
2. Modificadores da Carta (Características e Habilidades).
3. Modificadores de Facção.
4. Modificadores de Comandante.
5. Modificadores de Afinidade.
6. Modificadores de Campo de Batalha.
7. Outros modificadores futuros.

4.3. Agrupamentos de Facção (AFFINITY.md SSoT)
O bônus de Agrupamento representa a força da presença de uma Facção no campo. O cálculo ocorre no início de cada turno e permanece válido durante todo aquele turno (Snapshot no Combat State). Os bônus concedidos aplicam-se exclusivamente às unidades pertencentes àquela Facção.

Contam para o Agrupamento:

Todas as cartas vivas daquela Facção no Combat State;

O Comandante (sempre conta como uma unidade adicional da própria Facção);

Habilidades que alterem explicitamente o cálculo do Agrupamento.

Regra de Imutabilidade do Agrupamento: Mesmo que unidades sejam destruídas durante o turno, o nível de Agrupamento no Combat State permanece inalterado até o início do turno seguinte.

5. Mecânicas Gerais de Movimento e Alvos (Engine Flow)
5.1. Modelo de Construção do Comportamento do Pelotão
A engine constrói o comportamento operacional final de um Pelotão no runtime através da sobreposição e interação dos seguintes sistemas:

Classe: Define o comportamento base de movimento, alcance e alvo.

Características da Carta (Tier I): Adiciona comportamentos passivos ou gatilhos (ABILITIES.md).

Afinidade: Aplica modificadores baseados nas Facções (AFFINITY.md).

Campo de Batalha: Aplica modificadores zonais ou globais do cenário (BATTLEFIELDS.md).

Comandante: Aplica modificadores passivos globais (COMMANDERS.md).

Habilidades (Tier V): Adiciona ações ativas ou modificadores complexos (ABILITIES.md).

Modificadores Temporários (Buffs/Debuffs): Efeitos aplicados durante o combate ao Combat State.

Em caso de conflito, aplica-se a Hierarquia das Regras (capítulo 7).

5.2. Movimento (Fase de Avanço - Fase 4)
5.2.1 Avanço Automático
Após a resolução das mortes no turno anterior, cada pelotão avança automaticamente até ocupar a posição livre mais próxima da linha de frente adversária, preservando a ordem original do exército.

Fluxo de Avanço: 9 → 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1

5.2.2 Penalidade de Reorganização
Quando um pelotão chega pela primeira vez à posição 5 via avanço automático (não se aplica se iniciar a batalha nela), ela entra em reorganização. Na Fase de Execução das Ações do turno atual, ela não pode atacar, utilizar habilidades ou realizar qualquer ação. Age normalmente no turno seguinte.

5.2.3 Exceções de Movimentação de Classe
A regra geral de avanço automático (5.2.1) é obrigatoriamente sobrescrita pelas regras de movimento específicas da Classe Suporte (seção 6.5). A Máquina de Guerra possui apenas uma restrição de posicionamento inicial: deve começar na posição 9; após o início do combate, sua movimentação segue normalmente a regra geral.

5.3. Alvos (Fase de Seleção - Fase 5)
5.3.1 Regra Geral de Seleção
Todo pelotão ataca a unidade localizada na mesma coluna da Linha 1 adversária. Prioridades específicas de cada Classe (capítulo 6) podem substituir esta regra.

5.3.2 Imutabilidade de Alvo (Snapshot)
Após definidos na Fase de Seleção de Alvos, os alvos permanecem inalterados no Combat State durante todo o turno. Caso o alvo seja destruído antes da execução da ação (devido a ações simultâneas na Fase de Execução), a ação ofensiva falha, mas o alvo não é redefinido.

5.3.3 Exceções de Habilidades ao Snapshot
O Snapshot de alvos permanece como regra padrão para todos os ataques e ações comuns durante a batalha.

Entretanto, habilidades que possuam em sua própria definição técnica (definida em ABILITIES.md) uma regra explícita de nova seleção de alvo ou de encadeamento de ataques (ex: Ataque Duplo, Trespassar) realizam uma nova resolução de alvo exclusivamente durante a execução da referida habilidade.

Esta exceção de runtime obedece estritamente às seguintes restrições:
* Não altera nem cancela o Snapshot geral do turno para as demais unidades;
* Não permite que ataques comuns redefinam seus alvos caso o alvo original seja destruído;
* Aplica-se exclusivamente às habilidades que declararem essa exceção em ABILITIES.md;
* Mantém o determinismo da batalha aplicando a Ordem Oficial de Resolução (seção 6.1) em caso de desempate ou múltiplas opções válidas de alvo.

5.4. Ataque e Ação (Fase de Execução - Fase 6)
Todo pelotão que puder agir durante o turno realiza exatamente uma ação na Fase de Execução. O comportamento é determinado pela Classe e pelas habilidades individuais ( Tier V SSoT ABILITIES.md). Uma ação pode consistir em ataque básico, habilidade ativa, efeito de suporte ou efeito específico da carta.

6. Classes
Cada pelotão pertence obrigatoriamente a uma das seguintes classes. As classes determinam o comportamento básico dos pelotões, especialmente Movimento, Posição de Ataque e Seleção de Alvo.

6.1. Corpo a Corpo (CQC)
São a principal força ofensiva do início da batalha.

Ataque e Alvo: Somente realiza ações ofensivas quando ocupa uma posição da Linha 1 (posições 1, 2 ou 3). Segue a regra geral de alvo.

Bônus de Posição: Quando estiver na posição 1, recebe +50% de Ataque.

6.2. Barreira
Especialistas em absorver dano e manter a linha de frente ocupada.

Ataque e Alvo: Somente realiza ações ofensivas quando ocupa uma posição da Linha 1 (posições 1, 2 ou 3). Segue a regra geral de alvo.

Bônus de Posição: Quando estiver na posição 1, recebe +50% de Escudo base da carta (não do escudo atual).

6.3. À Distância
Fornecem apoio ofensivo às tropas da linha de frente.

Movimento: Segue normalmente as regras gerais de movimentação.

Ataque e Alvo: Atacam de acordo com a posição atualmente ocupada no tabuleiro:

7 ataca 6 inimiga.

8 ataca 5 inimiga.

9 ataca 4 inimiga.

6 ataca 1 inimiga.

5 ataca 2 inimiga.

4 ataca 3 inimiga.

3 ataca 9 inimiga.

1 ataca 1 inimiga.

Observações: Não realiza ação ofensiva na posição 2, pois nessa posição a Classe não possui nem a regra universal de ataque da Linha 1 nem nenhuma exceção estrutural própria.

Exceção Estrutural da Classe (Posição 3): A entrada "3 ataca 9 inimiga" é uma exceção deliberada de design, e não um erro de simetria com as demais posições (que seguem o padrão de atacar a linha imediatamente à frente na mesma coluna, e cuja Posição 1 segue a regra universal de ataque da Linha 1). Essa exceção existe propositalmente para permitir que a Classe À Distância funcione como um counter estrutural contra Máquinas de Guerra, que ocupam obrigatoriamente a Posição 9 (ver seção 6.6). Não deve ser "corrigida" para "3 ataca 3" em futuras revisões desta documentação ou de sua implementação.

6.4. Mago
Atingem alvos específicos e distribuem pressão.

Ataque e Alvo: O Mago sempre ataca exclusivamente a posição espelhada do tabuleiro adversário (ex: 5 ataca 5 inimiga, 9 ataca 9 inimiga).

Resolução de Alvo Vazio: Caso a posição espelhada esteja vazia no Combat State na Fase de Seleção de Alvos, o ataque é perdido. O Mago não procura outro alvo naquele turno.

6.5. Suporte
Fortalecer e sustentar o exército, priorizando cura sobre dano.

Movimento (Regra Própria Exclusiva): Um pelotão Suporte somente avança (Fase de Avanço) quando:

Não existir nenhum pelotão aliado atrás dele; OU

O único pelotão aliado atrás dele for uma Máquina de Guerra.
Caso contrário, permanece em sua posição atual.

Ação (Ataque vs. Cura): O comportamento na Fase de Execução depende da posição:

Posição 1: Realiza ataque normal (segue regra geral de coluna).

Posições 2 a 9: Não realiza ataques básicos. Em vez disso, executa a Cura Estrutural da Classe no aliado mais ferido (ver seção 4.2.3). Múltiplos suportes curam alvos diferentes, respeitando a ordem de prioridade.

6.6. Máquina de Guerra
Equipamentos militares com comportamento único definido individualmente.

Posicionamento Inicial Obrigatório: Toda Máquina de Guerra deve iniciar obrigatoriamente na posição 9. Essa regra não torna a Máquina de Guerra permanentemente imóvel; após o início do combate, sua movimentação segue normalmente as regras gerais.

Ação: Cada Máquina de Guerra constitui uma carta única, possuindo comportamento próprio definido no CARD_CATALOG.md. Respeita as Regras Estruturais da Engine.

7. Hierarquia das Regras e Resolução de Conflitos
O Sistema de Combate é determinístico. Quando múltiplas regras, habilidades ou modificadores se aplicam à mesma situação, utiliza-se obrigatoriamente a seguinte ordem de prioridade (do maior para o menor) para construir o comportamento final no Combat State:

Regras Estruturais da Engine. (Capítulos 1, 3, 4, 5, 6, 7). Nenhuma habilidade, comandante ou Campo pode contrariar estas regras. Inclui: Sequência oficial do turno, Duração e Condições de Vitória, Resolução simultânea de ações, Snapshot e Imutabilidade no Turno, Gatilhos padronizados.

Campos de Batalha (BATTLEFIELDS.md SSoT). (Modificadores Permanentes).

Habilidades dos Comandantes (COMMANDERS.md SSoT). (Modificadores globais passivos).

Habilidades das Cartas (Tier V) e Características (Tier I). (ABILITIES.md e CARD_CATALOG.md SSoT).

Afinidade (AFFINITY.md SSoT). (Bônus de Agrupamento e Afinidade de Comandante).

Regras da Classe. (Definições operacionais contidas no capítulo 6).

Modificadores Temporários (Buffs/Debuffs). (Efeitos aplicados durante o combate no Combat State).

Uma regra de nível inferior jamais poderá contrariar uma regra situada acima dela. Em caso de conflito no mesmo nível de hierarquia, utiliza-se a Ordem Oficial de Resolução (ver seção 6.1).

6. Regras Estruturais da Engine
6.1. Ordem Oficial de Resolução (Fall-back)
A engine utiliza a ordem oficial das posições do campo como regra padrão (fall-back) para desempatar qualquer evento simultâneo ou determinar prioridades cuja regra específica não esteja definida.

Ordem Oficial: 1 → 2 → 3 → 6 → 5 → 4 → 7 → 8 → 9

Esta ordem é utilizada como padrão da engine para:

Identificar o Pelotão responsável por uma eliminação (primeiro dano que reduziu HP a zero na ordem).

Prioridade de alvos para Cura (em caso de empate no valor de HP perdido).

Prioridade de ativação de efeitos simulâneos.

Ordenação de Evocações e Reanimações.

8. Casos Especiais Transversais e Definições da Engine
Este capítulo define resoluções para situações operacionais específicas que não pertencem naturalmente a um único capítulo de Mecânica ou Classe.

8.1. Simultaneidade e Snapshot (Combat State Flow)
Todas as ações dentro de uma fase são consideradas simultâneas no Combat State. Isso significa que:

Um pelotão destruído durante o turno ainda executa normalmente a ação que iniciou naquele turno.

Mortes somente produzem efeitos e avanço durante as fases correspondentes (ver capítulo 3).

Alvos e bônus não mudam após congelados na fase (Snapshot).

8.2. Ordem de Provocar
Caso mais de um pelotão aliado com a habilidade Provocar, localizado na mesma linha no Combat State, seja um alvo válido para um ataque, a seleção do alvo seguirá a seguinte ordem:

O atacante seleciona o pelotão com Provocar cuja coluna esteja mais próxima da sua.

Em caso de empate de distância de coluna, seleciona o da coluna de menor número.

8.3. Perspectiva de Direção (Esquerda e Direita)
Sempre que uma característica ou habilidade fizer referência aos pelotões à esquerda ou à direita, considera-se a perspectiva do próprio jogador, observando seu Exército na tela de preparação e batalha.

8.4. Encadeamento de Habilidades (Restrição de Ativação)
Um efeito produzido por uma habilidade pode afetar normalmente qualquer pelotão válido. Entretanto, os efeitos produzidos por uma habilidade nunca podem ativar outras habilidades que dependam daquele mesmo efeito (ex: Cura gerada por uma habilidade não ativa passivas de "ao receber cura"). Apenas o evento original é capaz de ativar habilidades. Esta restrição impede apenas novas ativações de habilidades, não os efeitos da habilidade original.

8.4.1 Resolução de Efeitos Imediatos vs. Fase de Mortes
Habilidades que previnem a morte no momento do impacto (ex: Sobrevivência, Campo de Força) resolvem seus efeitos instantaneamente durante a Fase de Execução das Ações, alterando o Combat State antes de qualquer ataque subsequente na mesma fase. Habilidades acionadas "Ao Morrer" (ex: Sacrifício, Explosão, Reerguer) registram o gatilho no momento do dano fatal, mas resolvem a remoção, reanimação e concessão de buffs exclusivamente na Fase de Resolução das Mortes (Fase 8).

8.5. Definição de Modificadores (Buffs/Debuffs)
Modificadores são efeitos temporários ou permanentes aplicados ao Combat State que alteram atributos ou comportamentos de Pelotões. Buffs são positivos (aumentam poder, resistência), Debuffs são negativos.

Este documento é a especificação operacional definitiva do motor de combate do Battle Simulator. Toda alteração de mecânicas de jogo deve ser refletida aqui.