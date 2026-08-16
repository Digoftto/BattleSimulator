# COMMANDER_RESTRICTIONS.md

# Restrições dos Comandantes

## Objetivo

Este documento define todas as restrições que podem ser atribuídas aos Comandantes.

As restrições representam o custo estratégico necessário para utilizar um comandante.

Seu objetivo é equilibrar vantagens poderosas sem impedir a diversidade de construções de Exército.

---

# Filosofia

As Restrições representam um sacrifício.

Elas nunca existem para punir o jogador.

Seu papel é incentivar diferentes formas de construir um Exército.

Toda Restrição é verificada antes do início da batalha.

Caso uma Restrição não seja atendida, o comandante não poderá ser utilizado.

---

# Estrutura

Todo comandante é composto por:

Facção
↓

Restrição
↓

Requisito
↓

Alvo
↓

Efeito
↓

Valor

Cada comandante possui exatamente:

* 1 Facção;
* 1 Restrição;
* 1 Requisito;
* 1 Alvo;
* 1 Efeito;
* 1 Valor.



---

# Banco Oficial de Restrições

## Categoria 1 — Facção

### Máximo de lacaios da Facção do comandante

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS001 | Máximo 2 lacaios da Facção do comandante | Baixa |
| RS002 | Máximo 3 lacaios da Facção do comandante | Média |
| RS003 | Máximo 4 lacaios da Facção do comandante | Alta |

Essas restrições incentivam Exércitos híbridos.

---

### Mínimo de outra Facção

Sempre considera uma Facção diferente da do comandante.

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS010 | Pelo menos 2 lacaios da Facção especificada | Média |
| RS011 | Pelo menos 3 lacaios da Facção especificada | Baixa |

A Facção específica é definida durante a geração do comandante.

---

## Categoria 2 — Classe

As restrições abaixo podem ser aplicadas a qualquer classe existente.

Classes:

* Corpo a Corpo
* À Distância
* Mago
* Suporte
* Barreira
* Máquina de Guerra



### Máximo

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS020 | Máximo 2 lacaios da classe especificada | Alta |
| RS021 | Máximo 3 lacaios da classe especificada | Média |

---

### Mínimo

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS022 | Pelo menos 2 lacaios da classe especificada | Média |
| RS023 | Pelo menos 3 lacaios da classe especificada | Baixa |

---

### Obrigatório

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS024 | Deve possuir pelo menos 1 lacaio da classe especificada | Alta |

---

### Proibido

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS025 | Não aceita a classe especificada | Muito Baixa |

---

## Categoria 3 — Campo de Batalha

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS030 | Apenas Campo Aberto | Média |
| RS031 | Não pode ser utilizado no Campo de Batalha especificado | Baixa |

O Campo de Batalha específico de RS031 é sorteado uniformemente entre os Campos de Batalha oficiais definidos em `BATTLEFIELDS.md`, excluindo o Campo Aberto.

Essas restrições devem ser utilizadas com moderação.

---

## Categoria 4 — Modo de Jogo

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS040 | Exclusivo para PvP | Muito Baixa |
| RS041 | Exclusivo para PvE | Muito Baixa |
| RS042 | Exclusivo para Minas | Muito Baixa |

Essas restrições devem ser extremamente raras.

---

## Categoria 5 — Afinidade

| Código | Restrição | Frequência |
| --- | --- | --- |
| RS050 | A Afinidade exige 1 carta adicional para ser ativada | Baixa |

Essa restrição aumenta o investimento necessário para ativar a Afinidade do Exército.

---

# Compatibilidade

Toda combinação gerada deve ser válida.

Uma Restrição nunca pode impedir que seu próprio Requisito seja satisfeito.

Caso isso ocorra, a combinação deve ser descartada e um novo Requisito deve ser sorteado.

---

## Exemplos inválidos

Restrição

Máximo 3 lacaios da Facção do comandante

Requisito

Pelo menos 4 lacaios da Facção do comandante

---

Restrição

Não aceita Magos

Requisito

Pelo menos 3 Magos

---

Restrição

Apenas Campo Aberto

Requisito

Durante Chuva Fraca (Campo de Batalha)

---

Esses comandantes nunca devem ser gerados.

---

# Regras Gerais

As Restrições:

* são verificadas antes da batalha;
* nunca mudam durante a partida;
* representam limitações de construção do Exército;
* nunca dependem de acontecimentos da batalha.



---

# Restrições Proibidas

Não utilizar restrições baseadas em:

* HP;
* Escudo;
* quantidade de lacaios vivos;
* posição das unidades;
* acontecimentos da batalha;
* cartas específicas;
* habilidades específicas;
* atributos numéricos.



Esses elementos pertencem exclusivamente ao sistema de Requisitos.

---

# Observações

Este documento define exclusivamente as Restrições dos Comandantes.

Em conjunto com:

* COMMANDER_GENERATION.md
* COMMANDER_REQUIREMENTS.md
* COMMANDER_TARGETS.md
* COMMANDER_EFFECTS.md
* COMMANDER_VALUES.md
* BATTLEFIELDS.md

forma a arquitetura oficial do sistema de geração de comandantes.