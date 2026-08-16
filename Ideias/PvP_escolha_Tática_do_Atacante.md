# IDEIA — PvP com Escolha Tática do Atacante

> **Status:** Ideia para avaliação futura. Não altera `RANKING.md`,
> `COMMAND_CENTER.md`, `MATCHMAKING.md` ou as regras atuais de combate.

## Intenção

Adicionar uma opção de PvP que devolve ao atacante uma decisão tática imediata,
sem eliminar o fluxo automático existente. O combate continua determinístico,
mas o jogador passa a escolher Exército e posicionamento depois de observar a
ameaça adversária disponível.

## Dois modos de entrada do atacante

| Modo | Decisão do atacante | Estado atual que permanece |
| --- | --- | --- |
| **Automático** | Mantém formação padrão e Ordem de Ataque previamente definida. | Preserva o mapeamento e a Ordem de Ataque atuais. |
| **Escolha Tática** | Escolhe Exército elegível e define posições para aquele confronto. | Mantém regras, Campos e condições normais de PvP. |

O modo Automático continua sendo a opção rápida. A Escolha Tática é opcional em
cada confronto e não substitui a estratégia persistente do Plano de Campanha.

## Escolha Tática — Ligas Prata, Ouro e Diamante

Antes de uma batalha, o atacante:

1. Vê os três Exércitos adversários disponíveis.
2. Não sabe qual dos três será o oponente daquele confronto.
3. Escolhe qual dos seus três Exércitos elegíveis usará.
4. Define a posição das nove Cartas desse Exército.
5. Confirma a escolha em até **20 segundos**.

Após a confirmação ou o fim do tempo, o sistema revela o Exército adversário
selecionado e inicia a batalha normalmente.

### Limites permanentes

* O jogador só pode usar as nove Cartas que já pertencem ao Exército escolhido.
* Não é permitido transferir Pelotões entre Exércitos durante a Escolha Tática.
* Não é permitido trocar Comandante, Doutrina, Campo de Batalha, Tier, Patente,
habilidades ou qualquer elemento fora do posicionamento.
* A alteração de posições vale exclusivamente para aquela batalha.
* Ao terminar o confronto, o Exército retorna à formação padrão definida pelo
jogador; a escolha temporária nunca é salva.
* A batalha, a Energia, o Ranking e todas as regras de resolução permanecem
inalterados.

## Liga Bronze

A Liga Bronze permanece no Modelo Individual de `RANKING.md`:

* o confronto é **1 contra 1**;
* o atacante vê o único Exército adversário disponível;
* não escolhe entre Exércitos próprios para o confronto;
* sua única decisão tática é reposicionar as nove Cartas do Exército inscrito;
* a mudança é temporária e a formação padrão retorna após a batalha;
* não há transferência de Pelotões entre Exércitos.

## Tempo e ausência de decisão

O relógio de 20 segundos preserva o ritmo do PvP e impede uma pausa indefinida.

A definição futura precisa escolher um comportamento único para expiração do
tempo. Alternativas válidas para avaliação:

1. usar a formação padrão do Exército selecionado automaticamente pelo modelo
atual; ou
2. confirmar a última escolha válida de Exército e posições feita pelo jogador.

Até essa decisão ser tomada, nenhuma implementação deve presumir uma das duas.

## Relação com a arquitetura atual

O modelo atual determina o Exército por Campo de Batalha e pelo mapeamento do
Plano de Campanha; no Campo Aberto, a Ordem de Ataque resolve empates de
elegibilidade. A Escolha Tática introduz uma exceção temporária a essa seleção
automática para o atacante.

Antes de virar regra canônica, esta ideia precisa definir:

| Questão | Decisão necessária |
| --- | --- |
| Campo de Batalha | É definido e revelado antes da escolha de Exército e posição. |
| Elegibilidade | Apenas os Exércitos elegíveis para o Campo sorteado podem ser escolhidos. |
| Oponente oculto | O defensor define previamente o exército no plano de batalha. O mecanismo seleciona esse exército de defesa previamente definido pelo adversário. |
| Defesa | O atacante joga contra um exército offline pré-definido pelo adversário (sua formação permanece fixa). O atacante vê a posição real dos 3 exércitos inimigos disponíveis. |
| Expiração | O sistema confirma a última escolha/formação válida do jogador; se não houver nenhuma alteração válida feita na janela, escolhe a posição padrão. |
| Energia | Validada e consumida de acordo com o Exército final escolhido na janela tática ou pela seleção padrão em caso de expiração. |
| Registro | É gerado um *snapshot* das posições antes da batalha exclusivamente para o confronto, sendo utilizado para sobrescrever/restaurar a formação padrão após o término da luta. |

## Princípios de avaliação

* A escolha precisa criar contrajogo real por composição e posicionamento.
* O jogador nunca pode montar um novo Exército dentro da janela de 20 segundos.
* A opção manual não pode tornar inútil o Plano de Campanha, o mapeamento de
Campos ou a Ordem de Ataque; ela deve ser uma camada de decisão, não uma forma
de contornar toda a preparação estratégica.
* A versão automática continua viável para quem prefere ritmo rápido ou não
deseja decidir manualmente em cada batalha.
* O relatório pós-batalha deve manter decisão de posicionamento, Campo e
composição auditáveis.