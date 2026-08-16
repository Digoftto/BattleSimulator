# COMMANDER_REQUIREMENTS.md

# Requisitos dos Comandantes

## Objetivo

Este documento define todos os requisitos que podem ser utilizados pelas vantagens dos Comandantes.

Os requisitos determinam **quando um bônus pode existir**.

Diferentemente das Restrições, os requisitos não impedem a montagem do Exército.

Eles apenas verificam se determinada condição foi satisfeita para que a vantagem do comandante seja aplicada.

---

# Filosofia

Os requisitos devem ser:

* fáceis de compreender;
* fáceis de identificar durante a partida;
* independentes de cartas específicas;
* independentes de habilidades específicas;
* reutilizáveis por qualquer comandante.



Todo requisito deve responder apenas uma pergunta:

> **"O que precisa acontecer para que esta vantagem exista?"**
> 

---

# Estrutura

Toda vantagem de um comandante é composta por:

Requisito
↓

Alvo
↓

Efeito
↓

Valor

Cada comandante possui exatamente:

* 1 Requisito;
* 1 Alvo;
* 1 Efeito.



Essa estrutura mantém os comandantes simples de compreender e praticamente ilimitados em quantidade de combinações.

---

# Banco Oficial de Requisitos

## Categoria 1 — Facção

Verifica a composição inicial do Exército.

Os valores abaixo consideram apenas cartas da mesma Facção do comandante.

| Código | Requisito | Frequência |
| --- | --- | --- |
| R001 | Pelo menos 2 lacaios da mesma Facção do comandante | Alta |
| R002 | Pelo menos 3 lacaios da mesma Facção do comandante | Alta |
| R003 | Pelo menos 4 lacaios da mesma Facção do comandante | Alta |
| R004 | Pelo menos 5 lacaios da mesma Facção do comandante | Média |

---

## Categoria 2 — Classe

Verifica a composição inicial do Exército.

Aplica-se às seguintes classes:

* Corpo a Corpo
* À Distância
* Mago
* Suporte
* Barreira
* Máquina de Guerra



Para cada classe existem os seguintes requisitos:

| Código | Requisito | Frequência |
| --- | --- | --- |
| R010 | Pelo menos 2 lacaios da classe especificada | Alta |
| R011 | Pelo menos 3 lacaios da classe especificada | Alta |
| R012 | Pelo menos 4 lacaios da classe especificada | Média |

O tipo de classe é definido posteriormente pelo banco de dados do comandante.

---

## Categoria 3 — Campo de Batalha

O requisito é satisfeito apenas quando a batalha ocorre no Campo de Batalha especificado (ver `BATTLEFIELDS.md`).

| Código | Requisito | Frequência |
| --- | --- | --- |
| R020 | Durante o Campo de Batalha especificado | Média |

O Campo de Batalha específico é sorteado uniformemente entre os Campos de Batalha oficiais definidos em `BATTLEFIELDS.md`, excluindo o Campo Aberto, e definido durante a geração do comandante.

---

## Categoria 4 — Estado da Unidade

Verifica o estado atual da Unidade antes da aplicação do bônus.

| Código | Requisito | Frequência |
| --- | --- | --- |
| R030 | Unidade com HP igual ou inferior a 50% | Média |
| R031 | Unidade com Escudo igual a 0 | Média |

---

## Categoria 5 — Estado do Exército

Verifica a quantidade de lacaios vivos do Exército.

| Código | Requisito | Frequência |
| --- | --- | --- |
| R040 | Exército com 5 ou menos lacaios vivos | Média |
| R041 | Exército com 4 ou menos lacaios vivos | Média |
| R042 | Exército com 3 ou menos lacaios vivos | Baixa |

Esses requisitos representam momentos críticos da batalha e incentivam estratégias de recuperação ou resistência.

---

## Categoria 6 — Modo de Jogo

Utilizado apenas em comandantes muito raros.

| Código | Requisito | Frequência |
| --- | --- | --- |
| R050 | Apenas em batalhas PvP | Baixa |
| R051 | Apenas em batalhas PvE | Baixa |
| R052 | Apenas em Minas | Baixa |

Esses requisitos devem ser utilizados com extrema moderação por direcionarem completamente o comandante para um modo específico de jogo.

---

# Regras Gerais

## Requisitos de Facção

São avaliados apenas uma vez, no início da batalha.

Mudanças ocorridas durante o combate não alteram seu resultado.

---

## Requisitos de Classe

Também são avaliados apenas no início da batalha.

---

## Requisitos de Campo de Batalha

São válidos durante toda a batalha.

Caso o Campo de Batalha da partida não corresponda ao especificado pelo requisito, a vantagem permanece inativa.

---

## Estado da Unidade

São avaliados continuamente durante a batalha.

Quando a condição deixa de ser verdadeira, o bônus deixa de existir, salvo quando especificado de outra forma pela vantagem.

---

## Estado do Exército

São atualizados sempre que um lacaio é derrotado.

Quando a quantidade de lacaios vivos atingir o requisito definido, a vantagem passa a ser aplicada.

Caso a quantidade aumente futuramente (por exemplo, através de futuras mecânicas de invocação ou ressurreição), a vantagem deixa de existir, salvo disposição em contrário.

---

## Modo de Jogo

São verificados apenas no início da batalha.

---

# Requisitos Proibidos

Para manter o sistema simples e escalável, não devem ser utilizados requisitos baseados em:

* cartas específicas;
* nomes de cartas;
* habilidades específicas;
* atributos exatos (ATK, HP ou ESC numéricos);
* posições específicas do tabuleiro;
* sequência de eventos ocorridos durante a batalha;
* quantidade de eliminações realizadas.



Caso uma nova mecânica exija um desses comportamentos, recomenda-se expandir o banco de Requisitos apenas após análise de impacto em todo o sistema de comandantes.

---

# Exemplos

## Exemplo 1

Requisito

Pelo menos 4 lacaios da mesma Facção do comandante

↓

Alvo

Lacaios da mesma Facção

↓

Efeito

+20% HP

---

## Exemplo 2

Requisito

Unidade com HP igual ou inferior a 50%

↓

Alvo

Essa Unidade

↓

Efeito

+25% Ataque

---

## Exemplo 3

Requisito

Exército com 3 ou menos lacaios vivos

↓

Alvo

Lacaios da mesma Facção

↓

Efeito

+30% Escudo

---

## Exemplo 4

Requisito

Durante Chuva

↓

Alvo

Magos

↓

Efeito

+15% Ataque

---

# Observações

Este documento define exclusivamente **os requisitos para ativação das vantagens**.

Os demais componentes do sistema de geração de comandantes encontram-se em:

* COMMANDER_RESTRICTIONS.md
* COMMANDER_TARGETS.md
* COMMANDER_EFFECTS.md
* COMMANDER_VALUES.md
* BATTLEFIELDS.md

Todos esses documentos, em conjunto, formam a arquitetura oficial do sistema de geração de comandantes.