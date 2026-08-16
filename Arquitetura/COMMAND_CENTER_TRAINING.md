# COMMAND_CENTER_TRAINING.md

# Sistema de Treinamento

## Objetivo

O Sistema de Treinamento permite que comandantes evoluam passivamente enquanto permanecem dentro do Reino.

Seu objetivo é evitar que comandantes pouco utilizados permaneçam completamente estagnados, ao mesmo tempo em que preserva a superioridade da experiência adquirida em combate.

O treinamento nunca substitui a participação em batalhas.

Ele funciona apenas como uma forma complementar de progressão.

---

# Filosofia

O treinamento representa o aperfeiçoamento militar realizado dentro do Reino.

Enquanto alguns comandantes acumulam experiência diretamente nos campos de batalha, outros permanecem estudando estratégias, logística, liderança e administração militar.

Esse sistema garante que comandantes pouco utilizados continuem evoluindo lentamente sem competir com aqueles que participam ativamente das batalhas.

---

# Conceitos Fundamentais

## Treinamento Passivo

Comandantes em treinamento recebem experiência automaticamente.

Essa experiência é calculada utilizando a média diária de XP obtida pelos comandantes em serviço ativo que efetivamente ganharam experiência em combate naquele dia.

O treinamento nunca gera experiência própria.

Ele apenas replica uma pequena parcela da experiência produzida pelos comandantes ativos.

---

## Comandante em Treinamento

Enquanto permanecer em treinamento, o comandante:

* não pode participar do PvP;
* não pode participar do PvE;
* não pode ser enviado às Minas;
* continua ocupando normalmente sua vaga na Reserva.

---

# Desbloqueio

O Centro de Treinamento é desbloqueado no:

Centro de Comando nível 3.

A quantidade de vagas é definida pelo Nível do Centro de Comando — 1 vaga a cada 4 níveis, começando no desbloqueio (Nível 3). Fórmula e tabela oficiais em `COMMAND_CENTER_PROGRESS.md`, "Vagas de Treinamento".

Novas vagas poderão ser obtidas através do Legado II.

---

# Ganho de Experiência e Cálculo da Média Diária

A experiência recebida durante o treinamento corresponde a:

**20% da média diária de XP obtida pelos comandantes ativos que efetivamente ganharam experiência em combate naquele dia.**

### Critérios de Cálculo da Média Diária de XP

A média diária de XP utilizada pelo treinamento é recalculada diariamente. A cada dia, o sistema identifica todos os comandantes ativos que efetivamente obtiveram experiência em combate durante aquele dia e calcula a média de XP obtida.

Não participam do cálculo:

* comandantes que não participaram de batalhas;
* comandantes ativos que não obtiveram XP;
* comandantes enviados às Minas;
* comandantes inativos.

A ausência desses comandantes no cálculo não reduz a média diária.

---

# Acúmulo e Incorporação da Experiência

A experiência do treinamento segue o seguinte fluxo:

## XP Acumulada

Toda a experiência calculada diariamente é convertida em experiência de treinamento e adicionada ao acumulador do comandante. Esta **XP Acumulada** representa o total temporariamente armazenado durante o Ciclo de Treinamento atual e ainda não pertence ao comandante.

## Incorporação de XP

A experiência não é concedida continuamente; ela é incorporada apenas ao término de ciclos de duração fixa.

### Ciclo de Treinamento

Duração de:

10 dias.

Ao término do Ciclo de Treinamento:

* Toda a XP Acumulada é incorporada definitivamente ao comandante;
* O acumulador de XP Acumulada do comandante é reiniciado.

---

# Cancelamento

O treinamento pode ser interrompido a qualquer momento.

Entretanto:

Caso o treinamento seja interrompido (removido) antes da conclusão do Ciclo de Treinamento atual, toda a XP Acumulada naquele ciclo será descartada e nenhuma experiência será incorporada ao comandante. Apenas Ciclos de Treinamento concluídos incorporam experiência ao comandanteP.

---

# Promoções

A experiência incorporada ao término de um Ciclo de Treinamento pode ser suficiente para promover um comandante.. As regras de promoção são definidas em COMMANDERS.md.

## Ordem de Processamento

Ao término de cada Ciclo de Treinamento, o sistema executa exatamente a seguinte sequência:

1. incorpora toda a XP Acumulada ao comandante;
2. verifica promoção (requisitos definidos em COMMANDERS.md);
3. aplica eventual promoção;
4. inicia automaticamente um novo Ciclo de Treinamento caso o comandante permaneça em treinamento.

---

# Patentes

O treinamento nunca altera diretamente a patente.

Ele apenas incorpora experiência ao comandante.

A promoção ocorre automaticamente seguindo a ordem de processamento quando os requisitos definidos em COMMANDERS.md forem atendidos.

---

# Interface

Cada comandante em treinamento deverá apresentar:

* Nome.
* Patente atual.
* Tempo restante para o próximo ciclo.
* **XP Acumulada no ciclo atual (ainda não incorporada).**
* XP total.
* Progresso para a próxima promoção.

---

# Resumo do Centro de Treinamento

A interface deverá exibir:

* vagas utilizadas;
* vagas disponíveis;
* **Média diária de XP**;
* bônus concedido pelo Legado I.

---

# Fórmula Geral

```text
XP Acumulada Diária

=

20%

×

Média Diária de XP obtida pelos comandantes ativos que ganharam XP em combate

```

A fórmula detalhada encontra-se em:

FORMULAS.md

---

# Relação com Legado

O Sistema de Legado influencia diretamente o treinamento.

## Legado I

Aumenta permanentemente a experiência obtida durante o treinamento (modifica a % da fórmula).

Máximo.

+30 pontos percentuais.

---

## Legado II

Aumenta a quantidade de vagas disponíveis para treinamento.

A cada 20 comandantes enviados ao Legado.

↓

+1 vaga.

---

# Regras Gerais

* O treinamento nunca substitui o combate.
* O treinamento nunca gera XP própria.
* O treinamento nunca concede atributos diretamente.
* O treinamento nunca altera patentes.
* Todo ganho de XP depende do desempenho dos comandantes ativos.
* A experiência é incorporada apenas ao término de cada Ciclo de Treinamento.

---

# Fluxo

```mermaid
graph TD
    A[Reserva] -->|Enviar para Treinamento| B(Comandante em Treinamento);
    B -->|Média Diária Recalculada| B1[Adicionar XP Acumulada];
    B1 --> B_FimDia[Fim do Dia];
    B_FimDia --> B2{Ciclo Concluído (10 dias)?};
    B2 -- Não --> B1;
    B2 -- Sim --> C[Incorporar XP Acumulada ao Comandante];
    C --> D[Verificar e Aplicar Promoção];
    D --> E[Reiniciar Acumulador];
    E --> F{Permanecer em Treinamento?};
    F -- Sim --> B1;
    F -- Não --> H(Retorna à Reserva);
    B -- Cancelar --> I[Descartar XP Acumulada no Ciclo];
    I --> H;

```

---

# Relação com Outros Sistemas

Este documento interage diretamente com.

* COMMANDERS.md
* COMMAND_CENTER_PROGRESS.md
* COMMAND_CENTER_LEGACY.md
* FORMULAS.md

As regras desses sistemas não são definidas neste documento.

---

# Observações

O treinamento foi concebido para reduzir a ociosidade dos comandantes sem eliminar a importância da participação em batalhas.

O combate permanece sendo a principal fonte de evolução militar do jogo.

O treinamento funciona apenas como um mecanismo de desenvolvimento passivo destinado a preservar o valor de comandantes pouco utilizados ao longo da evolução do Reino.

O desempenho do treinamento acompanha diretamente a atividade militar do Reino. Quanto maior a experiência obtida pelos comandantes ativos em combate, maior será a evolução dos comandantes em treinamento.