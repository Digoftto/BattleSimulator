# CAMPO DE PROVA

## Objetivo

O Campo de Prova é uma ferramenta de preparação tática onde o jogador observa o
comportamento de um Exército sem iniciar uma atividade de campanha, ranqueamento
ou progressão.

Ele existe para responder perguntas de composição, posicionamento, Doutrina,
Afinidade e Campo de Batalha antes de o jogador comprometer a capacidade
operacional de um Exército em PvE ou PvP.

O Campo de Prova não é Treinamento: não melhora Cartas, Pelotões, Comandantes ou
habilidades. Também não é uma atividade de recompensa, produção ou progressão.

## Identidade

O nome **Campo de Prova** descreve um espaço do Reino reservado à confirmação de
uma estratégia. O jogador não envia um Exército para campanha; ele apresenta uma
formação em um confronto sem consequência operacional.

| O Campo de Prova é | O Campo de Prova não é |
|---|---|
| Ferramenta tática de preparação. | Treinamento de Cartas ou Comandantes. |
| Confronto determinístico sem consequência persistente. | PvE, PvP, Mina ou Arena. |
| Leitura prática de composição e posicionamento. | Fonte de recompensas, XP, Fragmentos ou Ranking. |
| Acesso a partir da montagem do Exército. | Substituto da Expedição ou da competição. |

## Princípio central

O Campo de Prova usa as mesmas regras de resolução do combate real. A exceção é
somente operacional: ele não valida nem consome Energia e não envia resultado
para progressão, economia, ranking ou histórico competitivo.

Assim, a ferramenta não altera o significado da Energia: Energia continua sendo
a capacidade de um Exército permanecer em campanha. O Campo de Prova não é uma
campanha.

## Acesso e elegibilidade

- O acesso fica disponível a partir do Editor de Exército.
- O jogador escolhe um Exército válido como formação principal.
- O confronto só começa depois da validação normal de composição e formação.
- Energia Atual, Energia Máxima e regras de recuperação não são pré-condições
  para iniciar o Campo de Prova.
- Soldo, restrições de Comandante, requisitos de Carta e regras estruturais de
  formação continuam sendo validados normalmente.

## Formas de confronto

### Oposição Configurada

O jogador define um **Perfil de Oposição** e o sistema seleciona aleatoriamente
um Exército elegível dentro desse perfil. A aleatoriedade existe somente na
seleção anterior ao combate: depois de escolhido, o oponente é congelado e a
batalha usa as regras determinísticas normais.

O Perfil de Oposição pode filtrar:

| Filtro | Regra |
|---|---|
| Facção | Uma, várias ou qualquer facção permitida. |
| Cartas obrigatórias | Oponente precisa conter todas as Cartas selecionadas. |
| Cartas proibidas | Oponente não pode conter nenhuma Carta selecionada. |
| Tier | Faixa permitida para as Cartas do oponente. |
| Patente | Faixa permitida para o Comandante do oponente. |
| Campo de Batalha | Campo oficial que será aplicado à sessão. |

Filtros futuros só podem ser adicionados se tiverem uma fonte canônica própria.
O perfil não altera atributos, habilidades, Doutrina, regras de formação ou o
Campo de Batalha; ele apenas delimita quais Exércitos podem ser sorteados.

Cada seleção registra uma **Semente de Oposição** e a configuração completa do
perfil. Isso permite repetir exatamente a mesma prova, compartilhar o cenário e
comparar mudanças de posicionamento contra o mesmo oponente.

### Confronto entre Exércitos

O jogador seleciona dois Exércitos válidos próprios: um como formação principal e
outro como oposição. A ferramenta captura os estados iniciais e não altera os
Exércitos reais após a conclusão.

### Catálogo de Oposições

O perfil seleciona apenas Exércitos que existam em um Catálogo de Oposições
autorizado. O catálogo pode incluir configurações canônicas futuras, mas não cria
Cartas, Comandantes ou formações informais. Se nenhum Exército satisfizer o
perfil, o sistema informa o conflito de filtros e não inicia a sessão.

## Configuração da sessão

Antes do confronto, o jogador define:

| Elemento | Regra |
|---|---|
| Formação principal | Exército válido escolhido no Editor. |
| Oposição | Perfil de Oposição Configurada ou outro Exército próprio válido. |
| Posicionamento | Configurado normalmente conforme `ARMY.md` e `COMBAT_RULES.md`. |
| Campo de Batalha | Campo disponível e compatível; seus efeitos reais são aplicados. |
| Semente de Oposição | Registrada para repetir o mesmo oponente sorteado. |
| Resultado | Apenas relatório local da sessão. |

O Campo de Prova não cria um Campo de Batalha exclusivo. Ele reutiliza os Campos
oficiais para que a leitura tática permaneça fiel ao restante do jogo.

## Regras de combate

Durante o confronto, aplicar sem alteração:

- validação de formação;
- Doutrinas de Comandante;
- Afinidade;
- habilidades, características e efeitos;
- Campo de Batalha e seus modificadores;
- ordem de turnos, simultaneidade e limite de 64 turnos;
- condições usuais de vitória, derrota e empate.

Cada sessão cria um Combat State independente e o reinicia ao terminar. HP,
Escudo, posições, buffs, debuffs, recargas, mortes, invocações e demais dados da
sessão nunca retornam aos Exércitos reais.

## Apresentação da batalha

Toda sessão do Campo de Prova é mostrada em tela por padrão, com a mesma leitura
visual de uma batalha normal. O jogador pode acelerar a reprodução ou pular para
o resultado final, usando os controles comuns de batalha.

Se o jogador não fizer nenhuma ação, a batalha continua visível e é resolvida em
tempo normal. O Campo de Prova nunca é executado silenciosamente por padrão.

## Leitura tática

### Objetivo

Ao terminar uma prova, o jogo deve explicar os fatores observáveis que mais
contribuíram para o resultado. O objetivo não é declarar uma causa absoluta para
uma batalha complexa, mas apontar decisões verificáveis que o jogador pode mudar
— principalmente posicionamento, composição e escolha de Cartas de nível
equivalente.

### Fonte dos insights

O analisador lê o Log Estruturado do Combat State. Para cada Pelotão e turno, a
engine precisa registrar pelo menos:

- posição inicial e posição após avanço;
- possibilidade de agir, ação realizada e motivo de não agir;
- alvo selecionado, alvo inválido ou alvo vazio;
- dano causado, dano recebido, cura, Escudo e eliminação;
- habilidades, características, Doutrinas e modificadores acionados;
- nível de Afinidade e toda alteração de pontos;
- efeito ativo de Campo de Batalha;
- turno e evento que alteraram a vantagem material.

O log pertence à sessão e não altera regras ou entidades persistentes. Essa
instrumentação é uma extensão de observabilidade do Combat State, não uma nova
mecânica de combate.

### Critérios para uma mensagem

Nenhum insight pode ser gerado apenas porque o resultado foi vitória ou derrota.
Cada mensagem deve indicar: fato observado, impacto mensurável, turno/período e
regra que o explica. Quando não houver confiança suficiente, o relatório mostra
os dados brutos, sem inventar uma explicação.

| Classe de insight | Evidência mínima | Exemplo de mensagem baseada em fatos |
|---|---|---|
| Afinidade perdida | Queda de nível de Afinidade seguida por mudança mensurável de sobrevivência, dano, cura ou modificador. | “A Afinidade da Natureza caiu no turno {TURN}; após isso, {IMPACT}.” |
| Inatividade | Pelotão elegível permaneceu por `{TURN_COUNT}` turnos sem ação ofensiva, cura ou habilidade; o motivo consta no log. | “{UNIT} ficou {TURN_COUNT} turnos sem agir porque {REASON}.” |
| Posição incompatível | Regra de Classe ou Campo impediu ações ou reduziu repetidamente o alcance/efeito previsto. | “{UNIT} na posição {POSITION} perdeu {OPPORTUNITIES} oportunidades por {RULE_SOURCE}.” |
| Valor de posicionamento | Posição permitiu ação, bônus ou alvo que não existiria em alternativa documentada. | “A posição {POSITION} permitiu que {UNIT} aplicasse {EFFECT} em {TURN_RANGE}.” |
| Campo de Batalha | Efeito oficial do Campo incidiu em ação, bloqueio ou modificador relevante. | “{BATTLEFIELD} afetou {UNIT} conforme {RULE_SOURCE}, alterando {IMPACT}.” |
| Janela decisiva | Sequência de eventos alterou a diferença de Pelotões vivos, HP, Escudo ou pressão de dano de modo mensurável. | “A vantagem mudou entre os turnos {TURN_START}–{TURN_END} após {EVENT_SEQUENCE}.” |

`{IMPACT}`, `{REASON}`, `{RULE_SOURCE}` e demais campos são preenchidos pelo
log e pela regra consultada; não por texto pré-escrito que presuma uma causa.

### Priorização e linguagem

- Mostrar no máximo três insights principais por sessão: um de causa provável,
  um de oportunidade e, quando houver, um de acerto tático.
- Separar claramente **observação** (“ocorreu”) de **sugestão** (“experimente”).
- Uma sugestão só é permitida quando existir alternativa legal e rastreável, como
  outra posição válida, uma Carta disponível de mesmo escopo ou um Campo já
  acessível ao jogador.
- Não afirmar que uma única mudança “garantiria” vitória; combate permanece uma
  interação de múltiplas regras, mesmo sendo determinístico.
- Não recomendar alterar Tier, Patente ou gastar recursos como solução padrão.

### Repetição comparável

O relatório oferece **Repetir esta Prova**. A repetição mantém Perfil de Oposição,
Semente, Campo de Batalha e oposição inicial. O jogador pode então mudar apenas
a formação, posições ou Cartas e comparar os dois relatórios lado a lado.

Esse fluxo torna visível o valor central da ferramenta: aprender por decisões
táticas controladas, não por tentativa opaca.

## Consequências proibidas

Uma sessão do Campo de Prova nunca:

- consome ou recupera Energia;
- consome Soldo, recursos, Fragmentos ou Pontos de Geração;
- concede XP, recompensas, Cartas ou materiais;
- altera Patente, Tier, habilidades, Afinidade permanente ou Doutrina;
- conta para Fases de PvE, Minas, Arena, Liga, ranking ou missões;
- bloqueia edição futura por janela de reutilização;
- cria registro competitivo ou histórico permanente de resultado.

## Relatório de Prova

Ao fim da sessão, apresentar um relatório local contendo:

- vencedor, derrotado ou empate;
- quantidade de turnos;
- Pelotões sobreviventes e posições finais;
- eventos relevantes, habilidades acionadas e mudanças de Afinidade;
- Campo de Batalha usado;
- configuração inicial dos dois lados.
- Semente de Oposição e Perfil de Oposição, quando aplicáveis;
- até três insights táticos fundamentados no Log Estruturado.

O relatório serve para comparação imediata. Ele pode ser enviado manualmente ao
Observatório como consulta, mas não deve entrar em estatísticas de desempenho,
balanceamento de conta ou histórico competitivo sem uma regra futura específica.

## Interface

O botão **Campo de Prova** aparece no Editor de Exército depois que a formação
estiver válida. Antes do início, a interface deve exibir de forma explícita:

> Sem consumo de Energia. Sem recompensas. Sem alteração permanente.

O resultado deve manter a mesma leitura visual de uma batalha real, mas ter um
marcador permanente de contexto: **Campo de Prova**. Esse marcador evita que o
jogador confunda a sessão com PvE, PvP ou Arena.

## Integrações

| Sistema | Integração |
|---|---|
| `ARMY.md` | Fonte de validação da composição e formação. |
| `COMMANDERS.md` | Doutrina e liderança do Comandante escolhido. |
| `CARD.md` / `CARD_CATALOG.md` | Pelotões, atributos e identidade das Cartas. |
| `COMBAT_CORE.md` | Estados, execução e resultado estruturado. |
| `COMBAT_RULES.md` | Regras operacionais, turnos e encerramento. |
| Motor de combate / Log Estruturado | Fonte de eventos e métricas para os insights táticos; detalhamento técnico a documentar. |
| `AFFINITY.md` | Cálculo temporário de Afinidade. |
| `BATTLEFIELDS.md` | Campo disponível e modificadores ambientais. |
| `ENERGY.md` | Define por que não há consumo: Campo de Prova não é campanha. |
| `OBSERVATORY.md` | Consumidor opcional de relatório local, sem estatística permanente. |

## Princípios permanentes

- O Campo de Prova mede uma decisão; não altera o poder do jogador.
- A ausência de custo nunca pode produzir vantagem econômica ou competitiva.
- O resultado precisa ser reproduzível com as mesmas condições iniciais.
- A ferramenta deve aproximar o jogador da decisão de campanha, não substituí-la.
- Nenhuma regra de combate é simplificada para tornar o confronto mais fácil.
- Nenhuma entidade persistente é criada ou modificada durante a sessão.
