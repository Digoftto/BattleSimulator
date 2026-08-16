Exércitos
Objetivo
Este documento define a arquitetura conceitual e a estrutura operacional dos Exércitos dentro do Battle Simulator.

O exército representa a principal força militar organizada pelo Reino para executar campanhas, participar de batalhas e cumprir objetivos definidos pelos diferentes modos de jogo.

Este documento estabelece as diretrizes de composição, organização, logística e identidade das forças militares. As regras específicas de combate, formação de pelotões e funcionamento dos diferentes modos de jogo possuem documentação própria.

O exército atua como a entidade operacional que reúne e organiza os recursos militares (comandante e pelotões) para a execução de estratégias no campo de batalha.

Filosofia
O Reino não combate diretamente; ele organiza seus recursos militares em exércitos.

Cada exército representa uma força militar temporariamente organizada para cumprir uma missão ou campanha específica. Os exércitos pertencem ao Reino, enquanto comandantes e pelotões militares são apenas designados para liderá-los ou integrá-los.

Essa arquitetura de organização temporária permite que os mesmos recursos militares (comandantes e cartas de coleção) sejam redistribuídos livremente entre diferentes exércitos, conforme a estratégia do jogador e as necessidades do Reino.

Um Reino pode organizar simultaneamente múltiplos exércitos, respeitando sempre a disponibilidade de seus recursos militares.

Definição
O Exército é a unidade operacional fundamental utilizada pelo Reino no Battle Simulator. Ele constitui uma estrutura administrativa e tática temporária que reúne um comandante e um conjunto definido de pelotões para a execução de campanhas militares.

Sua função é organizar recursos militares dispersos em uma força coesa e coordenada, administrando sua própria logística (energia e soldo) e servindo como a entidade participante nas batalhas.

A formação de um exército não altera a propriedade permanente dos recursos militares, que continuam pertencendo ao Reino, apenas formaliza sua organização e designação para uma força tarefa específica.

Princípios Fundamentais
Todo exército obedece aos seguintes princípios conceituais e operacionais permanentes:

Propriedade do Reino: Todo exército pertence exclusivamente a um Reino.

Liderança Única: Todo exército possui exatamente um comandante designado.

Composição Fixa: Todo exército é composto por exatamente nove pelotões militares.

Logística Própria: A energia e o soldo total são administrados pelo exército, não pelos seus componentes individualmente.

Designação de Recursos: Comandantes são designados e pelotões militares são alocados aos exércitos; o patrimônio permanente pertence ao Reino.

Flexibilidade Operacional: Os exércitos podem ser reorganizados livremente fora das batalhas.

Participação em Combate: O exército é a entidade que participa das batalhas, aplicando a Doutrina Militar do comandante e executando as ações com seus pelotões.

Registro Histórico: Cada exército mantém seu próprio histórico operacional independente.

Estado Operacional: Todo exército possui um estado de disponibilidade que determina suas ações possíveis.

Componentes Fundamentais
A arquitetura do exército é sustentada pelos seguintes componentes fundamentais, que definem sua existência e operação:

Identidade
Representa a identificação e o vínculo institucional do exército dentro do Reino.

Composição
Define os recursos militares que formam a força de combate do exército.

Organização
Representa a disposição tática e estratégica dos recursos dentro do exército.

Logística
Administra os recursos operacionais necessários para a manutenção e atividade do exército.

Combate
Define o exército como a entidade participante das batalhas.

Histórico
Registra permanentemente a trajetória e o desempenho operacional do exército.

Disponibilidade
Define o estado operacional atual do exército.

Estrutura do Exército
A representação estrutural do Exército reflete integralmente a arquitetura apresentada neste documento:

Plaintext
Exército
│
├── Identidade
│   ├── Reino (Proprietário)
│   ├── Nome (Narrativo - Opcional)
│   └── Comandante Designado
│
├── Composição (Recursos Alocados)
│   ├── 1 Comandante
│   └── 9 Pelotões Militares
│
├── Organização (Tática)
│   ├── Seleção de Pelotões
│   └── Posicionamento Inicial
│
├── Logística (Operacional)
│   ├── Energia (Atual / Máxima)
│   └── Soldo Total (Custo de Manutenção)
│
├── Combate (Entidade Participante)
│   ├── Doutrina Militar Aplicada
│   └── Ações dos Pelotões
│
├── Histórico (Registro Operacional)
│   ├── Batalhas Disputadas
│   ├── Vitórias / Derrotas
│   └── Tempo em Campanha
│
└── Disponibilidade (Estado Atual)
Identidade
Todo exército pertence exclusivamente a um Reino. O comandante atualmente designado responde pela liderança estratégica e tática daquela força militar. O nome do exército é opcional e possui finalidade exclusivamente narrativa, permitindo ao jogador personalizar suas forças tarefas.

Composição
Um exército sempre possui exatamente um comandante e nove pelotões militares. Esta composição é fixa e não pode ser alterada durante campanhas ou batalhas.

Toda alteração na composição do exército fora de combate recalcula automaticamente:

Energia Máxima do exército;

Soldo Total (custo de manutenção);

Efeitos e modificadores das Doutrinas Militares aplicadas.

Organização
Os recursos militares designados ao exército podem ser reorganizados livremente antes do início do combate ou campanhas. Essa organização tática inclui a seleção dos pelotões específicos a serem utilizados, seu posicionamento inicial no campo de batalha, a configuração tática utilizada antes do combate e o comandante responsável por liderá-los.

As regras específicas de posicionamento e formações pertencem ao Sistema de Combate.

Validação da Formação
Um Exército válido para batalha deve possuir todas as 9 posições da Formação preenchidas, correspondentes às posições oficiais de 1 a 9.

Unicidade de Composição
Um Exército nunca pode conter duas Cartas com o mesmo Nome, independentemente do Tier de cada uma — nunca duas cópias de "Campeão Imperial", mesmo que uma esteja no Tier I e outra no Tier III. A restrição é sobre o Nome da Carta (Identidade, CARD.md), nunca sobre a cópia física específica. Essa regra vale igualmente para Exércitos do jogador e para Exércitos inimigos gerados pela Engine (EnemyArmyGenerator) — nenhum dos dois lados tem exceção.

Arquétipos de Formação (β, γ, δ, ε)
Todo Exército, ao ser criado, recebe automaticamente 5 Formações — α, β, γ, δ, ε — nunca apenas uma. A Formação α é a que o jogador efetivamente escolheu (ou a heurística padrão, caso não tenha reorganizado nada). As Formações β, γ, δ e ε são geradas automaticamente a partir das mesmas 9 cartas de α, cada uma seguindo um arquétipo tático fixo e determinístico — nunca aleatório, e nunca idênticas entre si. O jogador pode editar qualquer uma delas livremente depois de criadas.

O tabuleiro segue a numeração oficial (Linha 1 mais próxima do adversário):

```
7 8 9   (Linha 3)
6 5 4   (Linha 2)
1 2 3   (Linha 1)
```

Formação β — Ofensiva (Ruptura): a carta de Classe Corpo a Corpo com maior Ataque ocupa a Posição 1 (recebe o bônus estrutural de +50% de Ataque, COMBAT_RULES.md 6.1). As demais cartas de Corpo a Corpo e Barreira preenchem o restante da Linha 1. As cartas de Classe À Distância ocupam obrigatoriamente as Posições 6 e 7. As cartas restantes preenchem as posições remanescentes.

Formação γ — Defensiva (Muralha): a carta de Classe Barreira com maior Escudo ocupa a Posição 1 (recebe o bônus estrutural de +50% de Escudo Base, COMBAT_RULES.md 6.2). As demais cartas de Corpo a Corpo e Barreira preenchem o restante da Linha 1. Magos e Suportes ocupam as posições mais profundas disponíveis da Linha 3. À Distância ocupa as posições remanescentes mais protegidas.

Formação δ — Equilibrada: nenhum extremo é otimizado. A Linha 1 mistura Ataque e Escudo (nunca a carta de maior Ataque nem a de maior Escudo isoladamente na Posição 1). À Distância e as demais Classes se distribuem sem favorecer nenhuma prioridade tática específica.

Formação ε — Dispersão (Cobertura Total): as cartas de Classe À Distância se distribuem entre posições que atacam colunas diferentes do exército adversário (COMBAT_RULES.md 6.3), evitando concentrar fogo num único alvo — prioriza pressão em múltiplas frentes simultâneas em vez de ruptura concentrada.

A Máquina de Guerra, em qualquer uma das 5 Formações, permanece sempre na Posição 9 — regra estrutural da Engine (COMBAT_RULES.md 6.6), nunca sobrescrita por nenhum arquétipo.

Logística
A Logística administra todos os recursos operacionais do exército, incluindo sua Energia e seu Soldo Total.

Energia
Representa a capacidade operacional do exército de permanecer em campanha e realizar ações militares. A energia pertence ao exército, não ao comandante ou aos pelotões individualmente.

A Energia disponível do Exército segue exclusivamente as regras definidas em ENERGY.md. O ARMY.md apenas utiliza essa informação para validar a preparação do Exército.

Sua capacidade máxima é determinada pela soma da Energia Base fornecida pelo Reino, o bônus de Liderança do comandante designado e a Resistência Operacional dos pelotões militares alocados.

Soldo
Representa o custo operacional necessário para manter o exército em atividade e cobrir os pagamentos de suas tropas. O soldo total do exército corresponde à soma do soldo individual de todos os pelotões militares alocados e do comandante designado.

Funcionamento Logístico e Designação de Recursos
O Reino possui permanentemente comandantes e cartas de coleção. Os exércitos não possuem esses recursos; eles apenas recebem sua designação temporária para compor a força tarefa.

Isso significa que:

Um comandante pode ser transferido de um exército para outro;

Pelotões militares podem ser redistribuídos livremente entre os exércitos disponíveis do Reino;

Reorganizações e transferências nunca alteram o patrimônio permanente do Reino, apenas sua organização operacional.

Combate
O exército constitui a entidade participante das batalhas. Durante o combate, o comandante aplica sua Doutrina Militar e os pelotões militares executam todas as ações táticas e estratégicas. O desempenho em combate é influenciado diretamente pela composição, organização e logística do exército.

Histórico
Cada exército mantém seu próprio histórico operacional independente. Seu histórico registra, por exemplo:

Batalhas disputadas;

Vitórias e derrotas;

Tempo em campanha.

Disponibilidade
A Disponibilidade representa o estado operacional atual do Exército. Cada exército encontra-se sempre em um dos seguintes estados operacionais:

Disponível
O exército está pronto para operação e pode iniciar novas campanhas ou participar de batalhas.

Em Combate
O exército está atualmente participando de uma batalha e não pode realizar outras ações até a conclusão do combate.

Recuperação
O exército está aguardando a recuperação de sua energia operacional e não pode iniciar novas campanhas até que possua energia suficiente.

Ciclo de Vida
Todo exército segue o fluxo institucional abaixo:

Plaintext
Criação/Formação (Nova estrutura operacional)
↓
Organização Inicial (Definição tática)
↓
Designação do Comandante (Atribuição de Liderança)
↓
Alocação dos Pelotões (Composição da força)
↓
Campanhas (Execução de operações militares)
↓
Reorganização (Ajustes pós-campanha ou administrativos)
Os exércitos são estruturas dinâmicas, e sua composição e designação de recursos podem mudar diversas vezes durante a vida do Reino, adaptando-se às necessidades estratégicas.

Trava de Edição por Modo de Jogo
A composição de um Exército (Comandante e/ou Cartas) nunca pode ser editada enquanto ele estiver comprometido em uma atividade em andamento — só fora dela, seguindo a regra específica de cada modo:

PvE (Trilha): o Exército não pode ser editado enquanto a Expedição à qual pertence está em andamento. A edição só é permitida quando o Squad está no Acampamento (COMMAND_CENTER.md) ou de volta na Cidade, entre Expedições.

Minas (MINES.md): o Exército designado como Guarnição de uma Mina não pode ser editado enquanto o Ciclo de Mineração atual estiver ativo. A edição só é permitida depois que o Ciclo termina.

PvP (RANKING.md): ao entrar em uma Liga, o jogador vincula o Exército (Bronze) ou o Plano de Campanha (Prata em diante) que vai representá-lo naquela Temporada. A partir dessa vinculação, o Comandante fica travado para o restante da Temporada — só Cartas/Pelotões continuam editáveis livremente.

Essa trava existe porque a Energia de um Exército carrega uma Penalidade de Composição real (ver ENERGY.md, "Penalidade de Composição") — sem a trava de edição, o jogador poderia trocar a composição no meio de uma atividade em andamento de formas que a Penalidade de Composição não foi desenhada para cobrir.

Relação com Outros Sistemas
Este documento estabelece a arquitetura operacional dos exércitos. Seu funcionamento prático interage diretamente com os seguintes documentos:

COMMANDERS.md: Define a identidade, carreira e Doutrina Militar do comandante designado ao exército.

CARD_CATALOG.md: Define as características e custos dos pelotões militares alocados ao exército.

ENERGY.md: Define as regras de cálculo, consumo e recuperação da energia operacional do exército.

COMBAT_CORE.md: Define as regras de batalha onde o exército participa como a entidade operacional.

COMMAND_CENTER.md: Define as mecânicas de gerenciamento e organização dos exércitos pelo jogador.

Observações Técnicas
O exército representa a unidade operacional fundamental do Battle Simulator. Enquanto o Reino administra recursos permanentes e os comandantes exercem liderança estratégica, o exército reúne esses elementos em uma força organizada, capaz de executar campanhas, participar de batalhas e cumprir os objetivos definidos pelos diferentes modos de jogo.

A arquitetura dos Exércitos foi projetada para ser flexível e escalável. Ela suporta naturalmente futuras expansões, como novos modos de campanha, múltiplos teatros de guerra, novas estruturas militares, novos estados operacionais ou novos sistemas estratégicos relacionados aos Exércitos, sem alterar os princípios fundamentais e a estrutura operacional definidos neste documento.