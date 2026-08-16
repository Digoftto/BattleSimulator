# COMMANDER_GENERATION.md

# Motor de Geração de Comandantes

## Objetivo

Este documento define o funcionamento do sistema responsável pela geração dos Comandantes.

Seu objetivo é produzir comandantes únicos, equilibrados e coerentes, utilizando os bancos de dados oficiais do jogo.

Este documento não define bônus ou restrições individuais.

Ele define como todos esses elementos são combinados.

---

# Filosofia

Os Comandantes são a principal fonte de diversidade estratégica do jogo.

Eles não são criados manualmente.

Cada comandante é gerado através da combinação de componentes independentes.

Essa abordagem garante:

- grande variedade;
- facilidade de expansão;
- balanceamento consistente;
- baixo custo de criação de novos conteúdos.

---

# Arquitetura

Todo comandante é composto por exatamente:

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

↓

Raridade Final

Cada componente é obtido a partir de seu respectivo banco de dados oficial.

---

# Bancos Oficiais

O motor utiliza os seguintes documentos.

- COMMANDER_RESTRICTIONS.md
- COMMANDER_REQUIREMENTS.md
- COMMANDER_TARGETS.md
- COMMANDER_EFFECTS.md
- COMMANDER_VALUES.md

Cada documento possui responsabilidade única.

O motor apenas realiza a combinação entre eles.

---

# Sistema de Frequência

Cada componente sorteado pelo motor (Restrição, Requisito, Alvo, Efeito, Valor) possui um rótulo de Frequência definido em seu respectivo banco oficial.

O motor converte esse rótulo em um Peso numérico, utilizado tanto para o sorteio ponderado de cada etapa quanto para o cálculo do Rarity Score (ver Etapa 8).

| Rótulo de Frequência | Peso |
| --- | --- |
| Muito Alta / Muito Alto | 16 |
| Alta / Alto | 8 |
| Média / Médio | 4 |
| Baixa / Baixo | 2 |
| Muito Baixa / Muito Baixo | 1 |

Esta tabela é única e compartilhada por todos os bancos oficiais. Nenhum banco define seu próprio Peso — apenas seu rótulo de Frequência.

O sorteio de cada etapa do Fluxo Oficial de Geração é ponderado pelo Peso dos candidatos compatíveis restantes daquela etapa.

Os bancos de Restrição e Requisito também dependem de `BATTLEFIELDS.md` para os valores da categoria Campo de Batalha (ver Categoria 3 de cada banco).

---


# Fluxo Oficial de Geração

## Etapa 1

Sortear a Facção do comandante.

A Facção define sua identidade principal.

---

## Etapa 2

Sortear uma Restrição válida.

A Restrição determina o custo estratégico necessário para utilizar o comandante.

---

## Etapa 3

Eliminar todos os Requisitos incompatíveis com a Restrição.

Somente Requisitos válidos permanecem disponíveis para sorteio.

---

## Etapa 4

Sortear um Requisito.

O Requisito determina quando a vantagem poderá existir.

---

## Etapa 5

Selecionar um Alvo compatível.

O Alvo determina quem poderá receber o benefício.

---

## Etapa 6

Selecionar um Efeito compatível.

O Efeito determina qual benefício será concedido.

---

## Etapa 7

Selecionar um Valor compatível.

O Valor determina a intensidade do benefício.

---

## Etapa 8

Calcular o Rarity Score do comandante.

O Rarity Score é a soma dos Pesos de Frequência (ver "Sistema de Frequência") da Restrição, do Requisito, do Alvo, do Efeito e do Valor sorteados:

Rarity Score = Peso(Restrição) + Peso(Requisito) + Peso(Alvo) + Peso(Efeito) + Peso(Valor)

O Rarity Score é uma métrica interna calculada pelo motor. Sua conversão em Raridade Final (Comum, Rara, Épica, Lendária) não é definida por este documento — depende de faixas de corte que serão estabelecidas em uma etapa futura de balanceamento, com base na distribuição estatística observada nos comandantes efetivamente gerados.

---

# Compatibilidade

O motor nunca deve gerar combinações impossíveis.

Sempre que uma combinação inválida for encontrada, ela deve ser descartada e um novo elemento compatível deve ser sorteado.

---

# Regras Oficiais de Compatibilidade

## Restrições

Uma Restrição nunca pode impedir que seu próprio Requisito seja satisfeito.

Exemplo inválido:

Restrição

Máximo 3 lacaios da Facção do comandante.

+

Requisito

Pelo menos 4 lacaios da mesma Facção.

---

## Progressão

Requisitos dinâmicos nunca podem gerar bônus de Progressão.

São considerados dinâmicos:

- HP;
- Escudo;
- quantidade de lacaios vivos.

---

## Minas

Quando o Requisito for Minas:

o único efeito permitido é Recursos.

---

## Formação

Linha 2 e Linha 3 nunca recebem bônus de:

- HP;
- Escudo.

Na Temporada 1.

---

## Máquina de Guerra

Toda vantagem aplicada à Máquina de Guerra deve reforçar sua identidade estratégica.

Nunca deve modificar sua função principal.

---

## Facção

Os bônus de Facção sempre utilizam:

"Lacaios da mesma Facção do comandante."

Nunca utilizar uma Facção específica como alvo.

---

## Alvos

Nunca utilizar:

Todo o Exército.

Todo comandante deve favorecer apenas um grupo específico de unidades.

---

## Afinidade

Na Temporada 1:

o único efeito estrutural permitido é a flexibilização da Afinidade.

---

# Processo de Descarte

Sempre que uma combinação inválida for encontrada:

Elemento incompatível

↓

Descartado

↓

Novo sorteio

↓

Nova validação

↓

Prossegue a geração

O motor nunca deve adaptar automaticamente uma combinação inválida.

Sempre deve realizar um novo sorteio.

---

# Balanceamento

O objetivo do motor não é produzir comandantes igualmente fortes.

Seu objetivo é produzir comandantes equilibrados.

Comandantes muito fortes devem surgir naturalmente através da combinação de:

- vantagens relevantes;
- restrições leves.

Esses comandantes devem possuir baixa frequência.

Da mesma forma, comandantes mais fracos também devem existir.

Eles aumentam a diversidade do sistema e tornam os comandantes excepcionais mais valiosos.

---

# Princípios Fundamentais

Todo comandante deve:

- possuir identidade clara;
- incentivar um estilo específico de jogo;
- nunca beneficiar todas as estratégias ao mesmo tempo;
- ser facilmente compreendido pelo jogador.

---

# Princípios Proibidos

O motor nunca deve gerar comandantes que:

- criem novas mecânicas de combate;
- substituam Habilidades;
- substituam Tier;
- substituam Máquinas de Guerra;
- substituam Construções;
- utilizem cartas específicas;
- utilizem nomes de cartas.

---

# Expansões Futuras

Novas Temporadas deverão priorizar:

- novos Requisitos;
- novos Alvos;
- novos Efeitos;
- novas Restrições.

Sempre que possível, evitar aumentar os Valores disponíveis.

Essa estratégia aumenta a variedade de comandantes sem provocar inflação de poder.

---

# Observações

Este documento representa a especificação oficial do Motor de Geração de Comandantes.

Os demais documentos da arquitetura funcionam como bancos de dados utilizados por este sistema.

O motor também depende de `BATTLEFIELDS.md` para o domínio de valores da categoria Campo de Batalha, utilizada pelos bancos de Restrição e Requisito.

Toda alteração realizada em qualquer banco de dados deverá manter compatibilidade com as regras descritas neste documento.

# Aparência do Comandante

## Objetivo

A aparência do comandante faz parte do processo de geração e representa exclusivamente sua identidade visual.

Ela não interfere em:

- atributos;
- doutrina militar;
- efeitos;
- requisitos;
- restrições;
- progressão;
- combate;
- qualquer outra mecânica de gameplay.

Seu objetivo é fornecer identidade, variedade visual e personalidade aos comandantes.

---

## Geração

Durante a geração de um comandante, o sistema também deverá gerar sua aparência.

A aparência será composta por um conjunto de características independentes selecionadas a partir de pools configuráveis.

Exemplos de categorias:

- sexo;
- idade aparente;
- tom de pele;
- formato do rosto;
- olhos;
- sobrancelhas;
- nariz;
- boca;
- cabelo;
- barba;
- cicatrizes;
- tatuagens;
- armadura;
- roupas;
- capa;
- elmo;
- acessórios;
- expressão facial;
- pose;
- paleta de cores.

Cada categoria possui seu próprio conjunto de opções.

O sistema combina essas opções para produzir uma grande variedade de comandantes.

---

## Recombinação

Os atributos visuais são independentes.

Dois comandantes podem compartilhar:

- o mesmo cabelo;
- a mesma armadura;
- a mesma barba;
- a mesma expressão.

Sem que isso os torne iguais.

A identidade visual é resultado da combinação de todos os atributos.

---

## Arquitetura

A aparência pertence exclusivamente ao Motor de Geração de Comandantes.

Ela não faz parte da Identidade do Comandante.

Ela não altera qualquer atributo de gameplay.

Ela não participa de cálculos de combate.

Ela não influencia habilidades.

Ela não influencia progressão.

---

## Implementação

A implementação da geração visual ocorrerá em Sprint própria.

Até essa Sprint, a aparência será considerada apenas parte da especificação da arquitetura.