# SOLDO.md

## Objetivo

Este documento define o Sistema de Soldo do Battle Simulator.

Ele estabelece a fonte única de verdade (*Single Source of Truth*) para:

* O custo de Soldo das cartas;
* O teto de Soldo por Patente;
* As restrições de composição dos Exércitos;
* Os princípios permanentes do sistema.

## Responsabilidade do Documento

Este documento é responsável por definir:

* O custo de Soldo por raridade;
* O teto de Soldo disponível por Patente;
* As regras de validação da composição dos Exércitos;
* Os princípios permanentes do Sistema de Soldo.

Este documento não define:

* Energia (`ENERGY.md`);
* Raridade das cartas (`LIBRARY.md`);
* Níveis de Tier (`CARD_PROGRESSION.md`);
* Experiência (`XP.md`);
* Patentes (`COMMANDERS.md`);
* Regras de combate.

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura.

---

## Conceito

O Soldo é o orçamento de manutenção do exército. Ele regula a composição de cartas por raridade, evitando que cartas de raridade mais alta sejam estritamente superiores às de raridade mais baixa sem nenhum custo de oportunidade.

Este sistema é independente da Energia (`ENERGY.md`). O Soldo regula a composição do Exército (quais cartas cabem), enquanto a Energia pertence ao seu próprio domínio de regras. Os dois sistemas não se cruzam.

---

## Filosofia

Sem um freio de composição, a estratégia ótima seria sempre usar a maior raridade disponível em todos os 9 slots, esvaziando o propósito de cartas Comuns e Raras no jogo competitivo e invertendo a hierarquia de profundidade do jogo (Posicionamento > Classe > Facção > Carta > Habilidade).

O Soldo resolve isso ao impor um orçamento total por exército. Cartas mais fortes custam mais Soldo. O Comandante possui um teto de Soldo que cresce com sua Patente — mas mesmo no teto máximo, não é possível preencher os 9 slots inteiramente com as cartas de maior raridade.

O resultado pretendido: jogadores de Patente alta enfrentam uma escolha real entre quantidade de cartas fortes e diversidade/equilíbrio de composição, em vez de uma resposta óbvia única.

---

## Custo de Soldo por Raridade

| Raridade | Soldo |
| --- | --- |
| Comum | 1 |
| Rara | 2 |
| Épica | 4 |
| Lendária | 7 |

Esses valores aplicam-se à carta no seu nível base (antes de qualquer Tier). O Soldo não muda com o nível de Tier da carta — apenas com sua raridade.

---

## Teto de Soldo por Patente

O teto de Soldo disponível ao Comandante cresce conforme sua Patente avança.

| Patente | Teto de Soldo |
| --- | --- |
| Recruta | 18 |
| Capitão | 21 |
| Major | 24 |
| Coronel | 26 |
| General | 28 |
| Marechal | 30 |
| Lorde Comandante | 32 |

O Soldo total do exército (soma do custo de Soldo das 9 cartas) nunca pode exceder o teto da Patente atual do Comandante.

---

## Composições de Referência (Teto Máximo: 32)

As composições abaixo ilustram o comportamento do sistema no teto máximo (Lorde-Comandante, 32 de Soldo) e servem como exemplos oficiais de calibração do sistema, demonstrando as propriedades que devem ser preservadas em futuros rebalanceamentos:

### 2 Lendárias + 2 Épicas + 2 Raras + 3 Comuns

* **Custo:** (2×7) + (2×4) + (2×2) + (3×1) = 14 + 8 + 4 + 3 = **29** (sobra 3).


* Composição equilibrada e eficiente em uso de Soldo — a referência de "build rica e balanceada".



### 3 Lendárias 

* **Custo base:** 3×7 = 21. Restam 11 de Soldo para os 6 slots restantes.


* Isso permite, por exemplo, 1 Épica + algumas Raras/Comuns (ex: 3L + 1E + 3R + 2C = 32), mas **não permite uma segunda Épica** dentro do teto. Uma build *all-in* em Lendárias sacrifica a profundidade das Épicas.



### 1 Lendária + 4 Épicas + completar

* **Custo base:** 7 + (4×4) = 23. Restam 9 de Soldo para os 4 slots restantes — o suficiente para completar com Raras (ex: 1L+4E+4R = 31).



---

## Relação com Outros Sistemas

* **Energia (`ENERGY.md`):** Sistema independente. Cartas com níveis de Tier mais elevados fornecem maior capacidade de Energia ao Exército. O Sistema de Soldo permanece completamente independente desse cálculo e regula exclusivamente a composição do Exército.
* **Patente (`COMMANDERS.md`):** O teto de Soldo é uma das progressões desbloqueadas pela Patente, junto ao nível de Tier máximo permitido para as unidades do Exército.

* **XP de Comandante (`XP.md`):** O XP alimenta a Patente, que por sua vez determina o teto de Soldo. Não há relação direta entre XP e Soldo — a relação é sempre mediada pela Patente.



---

## Regras Permanentes

* O Sistema de Soldo é validado exclusivamente durante a montagem do Exército. Após a validação da composição, o Soldo não participa de nenhuma mecânica de combate.
* O Soldo é determinado exclusivamente pela raridade da carta, não pelo nível de Tier.


* O Soldo total do exército nunca pode exceder o teto da Patente atual do Comandante.


* Soldo e Energia são sistemas independentes e não devem ser combinados ou confundidos em nenhum documento.


* Os valores de Soldo por raridade e o teto por Patente foram calibrados para que as composições de referência (acima) representem os limites práticos do sistema — qualquer rebalanceamento futuro deve preservar essa propriedade.