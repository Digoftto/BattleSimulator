# GENERATION_POINTS.md

# Sistema de Pontos de Geração (PG)

## Objetivo

Este documento define o recurso **Pontos de Geração (PG)**: o que ele representa, de onde vem, e qual seu escopo de utilização dentro do Reino.

Ele estabelece a fonte única de verdade (*Single Source of Truth*) para:

* O nome e a identidade oficial do recurso;
* Sua fonte de geração;
* O fato de ser um pool único e global, não exclusivo de nenhum sistema;
* A lista de sistemas atualmente consumidores;
* A afirmação explícita de que não existem recursos alternativos ("Prestígio Global", "PdG") — apenas nomenclatura divergente do mesmo recurso, já corrigida.

## Responsabilidade do Documento

Este documento é responsável por definir:

* O nome oficial do recurso: **Pontos de Geração (PG)**;
* O conceito e a natureza do recurso (infraestrutura global do Reino);
* A fonte de geração (XP de Conta → PG);
* O escopo de utilização do recurso (global, não exclusivo);
* A lista de sistemas consumidores atuais, por referência;
* Os princípios permanentes do recurso.

Este documento **não** define:

* A tabela de XP de Conta ou a progressão de Nível de Conta (`XP.md`);
* As fórmulas de custo em PG de cada sistema consumidor (`FORMULAS.md`, e os documentos de cada sistema: `MINES.md`, `DEPOSITS.md`, `COMMAND_CENTER_PROGRESS.md`, `ACADEMY.md`);
* Regras de evolução, capacidade ou mecânica interna de qualquer sistema consumidor;
* Balanceamento numérico de qualquer custo em PG.

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura. Este documento não duplica fórmulas ou tabelas já centralizadas em `FORMULAS.md` ou definidas nos documentos de cada sistema — apenas referencia-as.

---

# Conceito

Pontos de Geração (PG) é um **recurso estratégico global de infraestrutura do Reino**.

Ele não pertence a nenhuma construção, exército ou comandante específico — pertence à Conta (Reino) como um todo, da mesma forma que o XP de Conta (`XP.md`).

PG representa a capacidade administrativa e logística do Reino de expandir sua infraestrutura ao longo do tempo: novos níveis de armazenamento, novos cargos administrativos, nova capacidade operacional. É o "orçamento" que o jogador aloca entre os diferentes sistemas de infraestrutura que competem por ele.

---

# Fonte de Geração

A única fonte de geração de PG atualmente definida é o avanço de Nível de Conta:

$$200\text{ XP de Conta} = 1\text{ Nível de Conta} = 1\text{ Ponto de Geração (PG)}$$

* A fórmula oficial e a progressão de Nível de Conta pertencem a `XP.md` e `FORMULAS.md` — este documento apenas referencia a relação.
* Cada evolução de Nível de Conta concede exatamente 1 PG.
* Não existe, hoje, nenhuma outra fonte de geração de PG documentada.

---

# Pool Único e Global

Existe **um único pool compartilhado de PG** por Reino (conta do jogador).

* PG não é dividido em sub-recursos por sistema, por região ou por tipo de consumo.
* Todo sistema consumidor de PG gasta do mesmo saldo global.
* Um jogador que investe PG em um sistema tem, consequentemente, menos PG disponível para os demais — é uma decisão real de alocação de orçamento, não uma coleção de moedas paralelas.

---

# Sistemas Consumidores Atuais

PG **não é exclusivo** de nenhum sistema. Atualmente, os seguintes sistemas consomem PG:

| Sistema | Uso do PG | Documento dono |
| --- | --- | --- |
| **Minas** | Evolução do nível estrutural de cada mina | `MINES.md` (mecânica), `FORMULAS.md` (fórmula/custo) |
| **Depósitos** | Evolução do nível único do Depósito (aumenta a capacidade dos três recursos simultaneamente) | `DEPOSITS.md` (mecânica), `FORMULAS.md` (fórmula/custo) |
| **Centro de Comando** | Expansão Administrativa (ativação de Cargos de Comando Ativo e Vagas da Reserva) | `COMMAND_CENTER_PROGRESS.md` (mecânica), `FORMULAS.md` (fórmula/custo) |
| **Academia** | Melhorias de capacidade de Fila de cada Mestre (Artífice/Metamorfo) | `ACADEMY.md` (mecânica e tabela de custo) |

Esta lista **pode crescer no futuro**. Novos sistemas podem ser adicionados como consumidores de PG sem exigir a criação de um recurso separado — eles apenas passam a gastar do mesmo pool global descrito aqui.

Este documento não duplica as fórmulas de custo de cada sistema; elas permanecem centralizadas em `FORMULAS.md` (ou, no caso da Academia, na tabela própria de `ACADEMY.md`, que não constitui fórmula matemática compartilhada).

---

# Nomenclatura

O nome oficial e único deste recurso é **Pontos de Geração (PG)**.

* **"Prestígio Global"** não é um recurso diferente. Era uma nomenclatura divergente usada anteriormente em `COMMAND_CENTER_PROGRESS.md` para se referir a este mesmo recurso — já corrigida para "Pontos de Geração (PG)".
* **"PdG"** não é um recurso diferente. Era uma abreviação divergente usada anteriormente em `ACADEMY.md` para se referir a este mesmo recurso — já corrigida para "PG".
* Qualquer referência futura a "Prestígio Global" ou "PdG" no corpus documental deve ser tratada como o mesmo recurso definido aqui, nunca como um recurso paralelo.

---

# Regras Permanentes

* PG é um recurso único, global, pertencente à Conta (Reino) — nunca a uma construção, exército ou comandante isoladamente.
* PG não é exclusivo de nenhum sistema. A lista de sistemas consumidores pode crescer no futuro.
* Não existe divisão do pool de PG em sub-recursos por sistema, região ou nomenclatura.
* A fonte de PG documentada atualmente é exclusivamente XP de Conta → PG (200 XP = 1 Nível = 1 PG).
* As fórmulas e tabelas de custo em PG de cada sistema pertencem aos seus respectivos documentos (`FORMULAS.md` para fórmulas compartilhadas; `ACADEMY.md` para a tabela própria de melhorias de fila) — este documento nunca as duplica.
* "Prestígio Global" e "PdG" não são recursos alternativos a PG.

---

# Referências

* **XP.md:** Fonte de PG (XP de Conta → Nível de Conta → PG).
* **FORMULAS.md:** Fórmulas oficiais de custo em PG (Minas, Depósitos, Centro de Comando).
* **MINES.md:** Aplicação de PG na evolução estrutural das Minas.
* **DEPOSITS.md:** Aplicação de PG na evolução do Depósito único.
* **COMMAND_CENTER_PROGRESS.md:** Aplicação de PG na Expansão Administrativa.
* **ACADEMY.md:** Aplicação de PG nas Melhorias das Filas de Produção.
* **GLOSSARY.md:** Entrada de glossário de PG, apontando para este documento.
