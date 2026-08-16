# REVISÃO — TUTORIAL

> Análise de melhoria do `TUTORIAL.md`. Este documento não altera as decisões
> canônicas do tutorial; registra ajustes recomendados antes de seu congelamento.

## Pontos fortes

- A revelação progressiva respeita o uso real dos sistemas e evita apresentar
  mecânicas antes de o jogador precisar delas.
- As Vozes têm função diegética clara; isso evita um narrador genérico e mantém
  o tutorial dentro da reconstrução do Reino.
- A Etapa 1 ensina posicionamento antes de complexidade, alinhada à prioridade
  `Posicionamento > Classe > Facção > Carta > Habilidade`.
- Gates tardios para Squad, Doutrina, Campos Especiais e Arena protegem o
  jogador de receber sistemas estratégicos cedo demais.

## Melhorias recomendadas

| Prioridade | Ponto | Risco atual | Melhoria sugerida |
|---|---|---|---|
| Alta | Princípios permanentes × critérios de conclusão | “Nenhuma Etapa trava” pode conflitar com etapas que exigem uma ação para concluir. | Definir que a etapa é **apresentada e permanece disponível**, mas seus benefícios, recompensa ou próxima apresentação só são concluídos após o critério; nenhuma tela bloqueia a navegação geral. |
| Alta | Etapa 1 | Quatro vitórias em sequência podem parecer obrigação antes de o jogador ter espaço para experimentar. | Manter os quatro combates como rota guiada, mas permitir retorno à Cidade entre eles e explicitar que os combates não criam regras especiais. Mostrar consumo de Energia antes do primeiro início. |
| Alta | Etapa 3 | “3 Cartas Comuns” pode não ser a quantidade necessária para a receita de Rara vigente. | Substituir o número por “Fragmentos suficientes para a receita Rara vigente” até a receita ser congelada; depois registrar o valor exato em `ACADEMY.md`. |
| Alta | Etapa 9 | A etapa depende de Filtros da Montagem Aleatória ainda não implementados. | Separar “Montagem manual” como Etapa 9 e criar uma subetapa futura para filtros, disparada somente quando a função existir. |
| Média | Etapa 4 | Explica PG de forma abstrata, mas não mostra onde o jogador o consulta. | Acrescentar ação de interface: abrir a visualização de XP/PG e destacar apenas a relação Reino → XP → PG, sem introduzir valores antes da hora. |
| Média | Etapa 6 | O critério é apenas visualizar o Núcleo; a lição é sobre capacidade e recuperação. | Pedir também uma inspeção da barra de Energia de um Exército, com tooltip, para conectar infraestrutura, composição e estado operacional. |
| Média | Etapa 8 | “Mais de uma Formação” precisa depender de capacidade já desbloqueada. | Declarar o gate técnico: a etapa só aparece quando houver duas formações válidas e capacidade de Expedição correspondente. |
| Média | Etapa 14 | Quatro Comandantes Ativos pode atrasar demais o primeiro PvP caso os Cargos Ativos progridam lentamente. | Validar o gate com a curva de PG e aquisição de Comandantes em `BALANCING_SIMULATION.md`; manter a intenção, mas medir tempo esperado até Bronze. |
| Média | Terminologia | “Sistema: Posicionamento”, “Formação”, “Exército”, “Squad” e “Expedição” aparecem próximos e podem se misturar na primeira leitura. | Cada Etapa deve abrir com uma frase curta dizendo qual entidade o jogador está alterando e qual continua inalterada. |
| Baixa | Status | O arquivo declara ser não congelado, mas algumas frases usam “sem alteração” e “já implementado”. | Trocar por “decisão preservada nesta revisão” e separar claramente regra documentada de estado de implementação. |

## Inclusão recomendada: Campo de Prova

Após a Etapa 9, incluir uma apresentação opcional chamada **Campo de Prova**.
Ela deve ser oferecida depois que o jogador monta o primeiro Exército manualmente,
sem virar condição para abrir outras Etapas.

- **Voz:** Comandante do jogador.
- **Lição:** uma formação pode ser observada e comparada sem iniciar uma
  Expedição, sem recompensa e sem consumo de Energia.
- **Ação sugerida:** abrir o Campo de Prova e concluir um Confronto de Prova.
- **Regra:** usa o mesmo combate determinístico, mas não é PvE, PvP, Treinamento
  nem atividade de progressão.

_A definição completa está em `CAMPO_DE_PROVA.md`._

## Decisões que precisam de validação do projeto

1. A receita Rara vigente e a quantidade de Fragmentos da Etapa 3.
2. O gate técnico de múltiplas Formações na Etapa 8.
3. O tempo médio até quatro Comandantes Ativos para a Etapa 14.
4. Se a apresentação opcional do Campo de Prova entra logo após a Etapa 9 ou
   apenas quando o jogador possuir dois Exércitos válidos.
