# Campos de Batalha

## Objetivo

Este documento define a arquitetura conceitual e o funcionamento do sistema de Campos de Batalha dentro do Battle Simulator.

Os Campos de Batalha representam as condições ambientais presentes durante um combate. Seu objetivo é aumentar a diversidade estratégica das partidas, incentivando o planejamento e a adaptação, sem alterar permanentemente o balanceamento das cartas, comandantes ou exércitos.

Este sistema é aplicado universalmente a todos os modos de jogo, incluindo PvE e PvP.

## Filosofia

Os Campos de Batalha não foram concebidos para tornar partidas injustas ou punitivas aleatoriamente. Seu propósito fundamental é incentivar o planejamento estratégico e a preparação militar prévia.

O sistema baseia-se na premissa de que não existe um "melhor exército" universal. Em vez disso, existe um Exército mais adequado para cada ambiente estratégico. O sistema favorece formações especializadas em detrimento de composições genéricas, forçando o jogador a adaptar sua estratégia ao ambiente antes que a batalha ocorra.

## Objetivos de Design

O sistema de Campos de Batalha foi projetado para atingir os seguintes objetivos:

*   **Diversidade:** Aumentar a variedade e a imprevisibilidade estratégica das partidas.
*   **Valorização da Coleção:** Incentivar a utilização de múltiplos exércitos e diferentes comandantes.
*   **Estratégia:** Criar novas possibilidades táticas sem a necessidade de alterar os atributos ou habilidades das cartas.
*   **Equilíbrio Dinâmico:** Evitar a consolidação de uma única composição de exército dominante para todas as situações de jogo.
*   **Preparação Estratégica:** Incentivar o planejamento prévio dos exércitos por meio do Plano de Campanha, reforçando que a adaptação ocorre antes do combate.

## Definição

Arquiteturalmente, um Campo de Batalha representa uma camada de modificadores temporários aplicados exclusivamente durante uma batalha específica. Ele constitui um componente fundamental do sistema de combate, simulando as condições ambientais, geográficas ou mágicas do local do confronto.

Sua aplicação modifica o ambiente operacional do combate, alterando regras, atributos ou o comportamento de classes e habilidades de forma passageira, não gerando qualquer efeito permanente nos recursos militares do Reino.

## Princípios Fundamentais

Todo o funcionamento dos Campos de Batalha obedece aos seguintes princípios permanentes:

1.  **Experiência Padrão:** O Campo Aberto representa a experiência padrão e equilibrada do jogo, sem modificadores ambientais.
2.  **Variação Estratégica:** Os demais Campos de Batalha funcionam como variações estratégicas que alteram significativamente o ambiente de combate.
3.  **Fomento à Especialização:** Cada Campo de Batalha deve favorecer determinadas composições e estratégias enquanto dificulta outras, forçando o jogador a especializar seus exércitos.
4.  **Preparação Estratégica:** O planejamento militar antecede o combate. A resposta ao ambiente é dada através da configuração prévia dos exércitos.
5.  **Simetria:** Os efeitos do Campo de Batalha aplicam-se igualmente a ambos os exércitos em campo (jogador vs jogador ou jogador vs ambiente).

## Frequência

A ocorrência dos Campos de Batalha é determinada pela seguinte distribuição percentual:

| Categoria | Campo de Batalha | Frequência |
|:---|:---|-----------:|
| **Padrão** | Campo Aberto | **64%** |
| **Climático** | Ventania | **4%** |
| | Chuva Fraca | **4%** |
| | Tempestade com Raios | **4%** |
| **Geográfico** | Pântano | **4%** |
| | Floresta | **4%** |
| | Vale | **4%** |
| **Místico** | Lua Cheia | **4%** |
| | Terreno Vulcânico | **4%** |
| | Nevoeiro Arcano | **4%** |

## Estrutura do Sistema

A representação estrutural abaixo descreve a arquitetura do sistema de Campos de Batalha:

Cada Campo de Batalha é documentado seguindo a estrutura padrão abaixo, garantindo a consistência das informações:

Nome do Campo: Identificação única do ambiente.

Categoria: Classificação documental (Padrão, Climático, Geográfico, Místico).

Descrição: Conceito narrativo do ambiente.

Efeito: Modificador mecânico aplicado ao combate.

Frequência: Probabilidade de ocorrência.

Campos de Batalha
Abaixo estão listados todos os Campos de Batalha implementados no jogo.

# Campo Aberto
Categoria: Padrão

Descrição: Uma planície vasta e desimpedida, sob condições climáticas ideais.

Efeito: Representa o ambiente padrão. Nenhuma regra normal do jogo é alterada ou adicionada.

Frequência: 64%

# Ventania
Categoria: Climático

Descrição: Ventos fortes e rajadas imprevisíveis que dificultam a mira e a trajetória de projéteis.

Efeito: Unidades cà distância causam 50% menos dano.

Frequência: 4%

# Chuva Fraca
Categoria: Climático

Descrição: Uma precipitação constante que umedece o campo e interfere na concentração de conjuradores posicionados na retaguarda.

Efeito: Unidades Mago posicionadas nas casas 7, 8 e 9 não realizam ataques.

Frequência: 4%

# Tempestade com Raios
Categoria: Climático

Descrição: Uma tempestade violenta com relâmpagos constantes, forçando as tropas a se concentrarem na linha de frente para evitar os raios.

Efeito: Apenas unidades posicionadas nas casas 1, 2 e 3 podem atacar, se forem aptas a atacar dessas posições.

Frequência: 4%

# Pântano
Categoria: Geográfico

Descrição: Um terreno lamacento e traiçoeiro que dificulta a movimentação e o avanço das tropas.

Efeito: Sempre que uma unidade for derrotada, a unidade imediatamente atrás deve aguardar 1 turno adicional antes de realizar seu primeiro avanço. Durante essa espera, todas as unidades posicionadas atrás permanecem bloqueadas pela própria formação, seguindo as regras normais de movimentação do jogo. Após esse primeiro deslocamento, a movimentação da coluna volta a ocorrer normalmente até que uma nova derrota provoque outro atraso.

Frequência: 4%

# Floresta
Categoria: Geográfico

Descrição: Uma vegetação densa que oferece proteção natural e amplifica a eficácia de defesas estáticas.

Efeito: Unidades recebem 50% mais Escudo Base.

Frequência: 4%

# Vale
Categoria: Geográfico

Descrição: Um terreno em depressão onde as correntes de ar e a acústica favorecem os ataques à distância.

Efeito: Unidades com a à distância recebem 50% mais Ataque Base.

Frequência: 4%

# Lua Cheia
Categoria: Místico

Descrição: A luz intensa e a influência mágica da lua cheia amplificam os poderes dos conjuradores de arcano.

Efeito: Unidades Mago recebem 50% mais Ataque Base.

Frequência: 4%

# Terreno Vulcânico
Categoria: Místico

Descrição: Um solo instável e quente, infundido com energia elemental do fogo que intensifica a violência e dificulta a cura.

Efeito: Todo dano causado recebe 25% de aumento. Toda cura recebe 50% de redução.

Frequência: 4%

# Nevoeiro Arcano
Categoria: Místico

Descrição: Um nevoeiro denso e carregado de magia instável que anula e impede a formação de proteções mágicas ou físicas.

Efeito: Todo Escudo existente é removido no início da batalha. Enquanto este Campo de Batalha permanecer ativo, nenhuma unidade pode possuir Escudo. Todo Escudo criado durante o combate é imediatamente dissipado.

Frequência: 4%

Funcionamento
O sistema de Campos de Batalha opera em conjunto com o Plano de Campanha, garantindo a seleção automática do exército mais adequado para o ambiente sorteado.

Fluxo da Batalha (PvP e PvE)
Antes de cada confronto, o fluxo completo do sistema é executado automaticamente:

Sorteio: O Campo de Batalha é sorteado aleatoriamente, respeitando as frequências definidas.

Identificação: O sistema identifica qual exército o jogador associou àquele Campo de Batalha em seu Plano de Campanha (ver COMMAND_CENTER.md).

Seleção: O exército correspondente é selecionado automaticamente para o jogador. No caso de PvP, este processo ocorre simultaneamente para ambos os jogadores.

Início: O combate inicia utilizando os exércitos selecionados sob as condições do Campo de Batalha sorteado.

Regras Gerais
Independência: Um novo Campo de Batalha é sorteado para cada batalha. O sorteio é independente e não leva em consideração batalhas anteriores.

Informação: Em modos PvE, a fase informa previamente qual Campo de Batalha será utilizado. No PvP, a informação é revelada após o matchmaking e sorteio.

Imutabilidade: O jogador não pode alterar seu exército, comandante ou o Plano de Campanha após conhecer o Campo de Batalha sorteado para o confronto iminente.

Relação com Outros Sistemas
O Sistema de Campos de Batalha integra-se com os seguintes documentos fundamentais:

COMBAT_CORE.md: Os Campos de Batalha aplicam modificadores diretamente nas regras de combate, atributos e mecânicas de classes.

COMMAND_CENTER.md: Define o Plano de Campanha, sistema responsável por mapear e selecionar automaticamente qual exército será utilizado em cada campo.

ARMY.md: O exército selecionado para combater no ambiente sorteado segue as diretrizes conceituais e operacionais deste documento.

COMMANDERS.md: As Doutrinas Militares dos comandantes devem ser planejadas considerando os possíveis Campos de Batalha onde atuarão.

Observações Técnicas
A arquitetura do Sistema de Campos de Batalha foi projetada para ser flexível e escalável, permitindo futuras expansões sem a necessidade de alterações estruturais nos princípios fundamentais definidos neste documento.

O sistema suporta naturalmente a introdução de:

Sistema de Campos de Batalha
│
├── Frequência
│
├── Categorias
│   ├── Padrão
│   ├── Climático
│   ├── Geográfico
│   └── Místico
│
├── Campos de Batalha
│
├── Sorteio 
│
├── Aplicação dos Modificadores 
│
└── Integração com Plano de Campanha 