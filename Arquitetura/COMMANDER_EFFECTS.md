# COMMANDER_EFFECTS.md

# Efeitos dos Comandantes

## Objetivo

Este documento define todos os efeitos que podem ser concedidos pelas vantagens dos Comandantes.

Os efeitos determinam **qual benefício será concedido** quando o requisito da vantagem for satisfeito.

Os efeitos não determinam:

* quando são ativados;


* quem recebe o benefício;


* qual o valor aplicado.



Esses elementos pertencem aos documentos:

* COMMANDER_REQUIREMENTS.md


* COMMANDER_TARGETS.md


* COMMANDER_VALUES.md



---

# Filosofia

Os efeitos dos Comandantes devem reforçar estilos de jogo já existentes.

Um Comandante nunca deve criar uma nova mecânica de combate.

Seu papel é potencializar estratégias, nunca substituir cartas, habilidades ou sistemas do jogo.

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

O efeito responde apenas uma pergunta:

> **"Qual benefício será concedido?"**
> 

---

## Independência dos Efeitos

Cada efeito responde exclusivamente à pergunta:

> **"Qual benefício será concedido?"**

Especificar que um efeito nunca determina:

* quando será aplicado;
* quem receberá o benefício;
* sua intensidade;
* sua frequência de geração.

Essas responsabilidades pertencem, respectivamente, aos documentos:

* COMMANDER_REQUIREMENTS.md;
* COMMANDER_TARGETS.md;
* COMMANDER_VALUES.md;
* COMMANDER_GENERATION.md.

---

# Categorias de Efeitos

Os efeitos são divididos em três categorias.

* Combate


* Progressão


* Estruturais



---

# Categoria 1 — Combate

São utilizados durante as batalhas.

## Atributos

| Código | Efeito | Frequência |
| --- | --- | --- |
| E001 | Ataque | Alta |
| E002 | HP | Alta |
| E003 | Escudo | Alta |

Esses representam a maior parte das vantagens disponíveis para os comandantes.

---

# Categoria 2 — Progressão

Representam bônus obtidos fora do combate.

## Progressão

| Código | Efeito | Frequência |
| --- | --- | --- |
| E010 | XP | Alta |
| E011 | Fragmentos | Média |
| E012 | Recursos | Média |
| E013 | Soldo | Baixa |

Esses efeitos aceleram o desenvolvimento do Reino sem alterar diretamente o desempenho em combate.

---

# Categoria 3 — Estruturais

Alteram pequenas regras da montagem do Exército.

## Afinidade

| Código | Efeito | Frequência |
| --- | --- | --- |
| E020 | Até 1 carta de outra Facção também conta para a Afinidade | Média |
| E021 | Até 2 cartas de outra Facção também contam para a Afinidade | Baixa |

Na Temporada 1, este é o único efeito estrutural disponível.

---

# Compatibilidade entre Requisitos e Efeitos

Todo efeito deve ser compatível com a Restrição, o Requisito e o Alvo previamente definidos para o comandante.

Caso qualquer incompatibilidade seja identificada durante a geração, o efeito deverá ser descartado e um novo efeito compatível deverá ser selecionado pelo Motor de Geração.

## Requisitos Fixos

Podem gerar:

* bônus de Combate;
* bônus de Progressão.



São considerados requisitos fixos:

* Facção;
* Classe;
* Clima;
* PvP;
* PvE;
* Minas.



---

## Requisitos Dinâmicos

Podem gerar apenas bônus de Combate.

São considerados requisitos dinâmicos:

* HP igual ou inferior a 50%;
* Escudo igual a 0;
* 5 ou menos lacaios vivos;
* 4 ou menos lacaios vivos;
* 3 ou menos lacaios vivos.



Nunca devem gerar bônus de Progressão.

---

## Requisito Minas

Quando o requisito utilizado for Minas, o único efeito permitido é:

* Recursos.



Esse requisito nunca deve gerar:

* Ataque;
* HP;
* Escudo;
* XP;
* Fragmentos;
* Soldo.



Essa limitação preserva a identidade do modo de jogo.

---

# Regras Gerais

## Combate

Os efeitos de combate apenas modificam atributos existentes.

Nunca criam novas mecânicas.

---

## Progressão

Os efeitos de progressão não influenciam diretamente uma batalha.

Seu objetivo é acelerar o desenvolvimento do jogador.

---

## Estruturais

Os efeitos estruturais modificam apenas regras de construção do Exército.

Nunca alteram regras do combate.

---

# Efeitos Proibidos

Os Comandantes não podem conceder efeitos que:

* criem habilidades;
* concedam ataques adicionais;
* curem unidades;
* revivam unidades;
* invoquem unidades;
* apliquem efeitos negativos;
* alterem a ordem do turno;
* ignorem Escudo;
* modifiquem regras fundamentais do combate.



Esses comportamentos pertencem exclusivamente às Cartas e às Habilidades.

---

# Princípio da Neutralidade

Nenhum efeito pode tornar outro sistema do jogo irrelevante.

Os Comandantes existem para potencializar sistemas já existentes.

Eles nunca devem substituir:

* Habilidades;
* Tier;
* Máquinas de Guerra;
* Construções;
* demais sistemas permanentes do jogo.



---

# Escalabilidade

* novos efeitos poderão ser adicionados em futuras temporadas;
* novos efeitos deverão respeitar as categorias existentes ou criar novas categorias quando necessário;
* toda expansão deverá preservar o Princípio da Neutralidade;
* novos efeitos nunca deverão substituir sistemas já existentes do jogo.

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

HP

↓

Valor

20%

---

## Exemplo 2

Requisito

Durante Chuva

↓

Alvo

Magos

↓

Efeito

Ataque

↓

Valor

15%

---

## Exemplo 3

Requisito

Pelo menos 3 Suportes

↓

Alvo

Suportes

↓

Efeito

XP

↓

Valor

20%

---

## Exemplo 4

Requisito

Apenas em Minas

↓

Alvo

Lacaios da mesma Facção

↓

Efeito

Recursos

↓

Valor

25%

---

## Exemplo 5

Requisito

Pelo menos 5 lacaios da mesma Facção do comandante

↓

Alvo

Lacaios da mesma Facção

↓

Efeito

Até 1 carta de outra Facção também conta para a Afinidade

---

# Observações

Este documento define exclusivamente **quais benefícios um Comandante pode conceder**.

Os demais componentes do sistema de geração de comandantes encontram-se documentados em:

* COMMANDER_GENERATION.md
* COMMANDER_REQUIREMENTS.md


* COMMANDER_TARGETS.md


* COMMANDER_VALUES.md


* COMMANDER_RESTRICTIONS.md



Todos esses documentos, em conjunto, formam a arquitetura oficial do sistema de geração de comandantes.