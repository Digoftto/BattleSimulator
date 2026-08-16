# COMMAND_CENTER_PROGRESS.md

# Progressão do Centro de Comando

## Objetivo

Este documento define toda a evolução estrutural e administrativa do Centro de Comando (CdC).

A progressão do CdC determina a Capacidade Administrativa do Reino para criar nova Infraestrutura Administrativa e, posteriormente, ativar os Recursos Administrativos (Cargos de Comando Ativo e Vagas da Reserva) necessários para gerenciar um número crescente de comandantes.

---

# Filosofia

A evolução do Centro de Comando representa exclusivamente a expansão administrativa do Reino.

O Centro de Comando nunca fortalece diretamente os comandantes; seu papel é ampliar a infraestrutura necessária para administrar o contingente militar do Reino ao longo do tempo.

A expansão do Centro de Comando amplia continuamente a Capacidade Administrativa do Reino, mas nunca obriga o jogador a utilizar imediatamente essa capacidade. A decisão de transformar Infraestrutura Administrativa em Recursos Administrativos pertence exclusivamente ao jogador através do investimento de Prestígio Global (PG).

O crescimento ocorre através de dois sistemas complementares:

* **Progressão Vertical:** Expansão do nível do edifício e criação de Infraestrutura Administrativa.
* **Expansão Administrativa:** Ativação operacional de Recursos Administrativos utilizando Prestígio Global (PG).

---

# Conceitos e Recursos Administrativos

Para o correto funcionamento da engine de progressão, é fundamental distinguir os seguintes conceitos:

## Capacidade Administrativa

Representa a capacidade máxima que o Centro de Comando é capaz de sustentar através de sua Infraestrutura Administrativa em um determinado nível. Ela define o potencial administrativo total do Reino. Os Recursos Administrativos representam apenas a parcela já ativada dessa capacidade.

## Infraestrutura Administrativa

Representa toda a capacidade estrutural bruta criada pela **Progressão Vertical**. É o potencial administrativo total disponível num nível do CdC, mas que ainda não pode ser utilizado pelos demais sistemas do jogo.

## Recursos Administrativos

Representam exclusivamente os recursos efetivamente ativados pela **Expansão Administrativa** sobre a Infraestrutura Administrativa existente. Somente Recursos Administrativos podem ser utilizados pelos demais sistemas (Recrutamento, Combate, etc.) para alocar comandantes. São compostos por:

### Cargo de Comando Ativo

Representa uma posição operacional disponível no Reino destinada a um comandante em Estado Administrativo Ativo (conforme definido em COMMAND_CENTER.md). Cargos de Comando Ativo são necessários para que comandantes liderem exércitos em combate.

### Vaga da Reserva

Representa uma posição administrativa destinada a comandantes pertencentes ao Reino que se encontram em Estado Administrativo Reserva (conforme definido em COMMAND_CENTER.md).

## Ocupação

Representa quantos Recursos Administrativos (Cargos de Comando Ativo e Vagas da Reserva) atualmente estão sendo utilizados por comandantes pertencentes ao Reino. É exibida como o valor X em relações X/Y (onde Y é o total de Recursos Administrativos).

---

# Arquitetura da Progressão

## Fluxo Geral de Expansão

A relação entre os sistemas de progressão e a utilização dos recursos segue o fluxo arquitetural abaixo:

```text
Progressão Vertical (Nível do CdC)
           ↓
Nova Infraestrutura Administrativa (Potencial)
           ↓
Expansão Administrativa (Gasto de PG)
           ↓
Recursos Administrativos (Cargos de Comando Ativo / Vagas da Reserva)
           ↓
Sistemas de Recrutamento (SSoT: RECRUITMENT.md)
           ↓
Contratação de Comandantes
           ↓
Alocação conforme Estado Administrativo
(Ativo / Reserva / Treinamento)

```

Cada etapa do fluxo possui responsabilidade exclusiva e depende da conclusão da etapa anterior. Nenhum sistema substitui ou acumula responsabilidades pertencentes aos demais.

## Integração com Recrutamento

A progressão do Centro de Comando não cria comandantes. Ela gera exclusivamente a capacidade administrativa para que futuros comandantes possam ser contratados e alocados através dos sistemas de recrutamento e gerenciamento definidos em `COMMAND_CENTER_RECRUITMENT.md` e `COMMANDERS.md`.

---

# Progressão Vertical

A Progressão Vertical é a única responsável por criar nova Infraestrutura Administrativa e aumentar o nível do edifício do Centro de Comando.

Características:

* Virtualmente infinita.
* Limitada pela evolução da Capital.
* Utiliza Recursos (Ouro, Madeira, etc.).
* Utiliza a fórmula oficial de custo e tempo descrita em `FORMULAS.md`.

Cada novo nível concede:

* Desbloqueio de uma nova árvore de Expansão Administrativa.
* Incremento imediato na capacidade de Infraestrutura Administrativa de Cargos de Comando Ativo e Vagas da Reserva conforme a Tabela de Distribuição Oficial.

A Progressão Vertical jamais utiliza PG ou desbloqueia Recursos Administrativos diretamente. A utilização dessa nova Infraestrutura Administrativa depende posteriormente da Expansão Administrativa.

---

# Expansão Administrativa

A Expansão Administrativa é a única responsável por transformar Infraestrutura Administrativa em Recursos Administrativos utilizáveis.

Características:

* Consome Prestígio Global (PG).
* Ativa Cargos de Comando Ativo e Vagas da Reserva individualmente dentro da Infraestrutura Administrativa do nível atual.

Recursos Administrativos que ainda não foram ativados (permanecendo apenas como Infraestrutura Administrativa) permanecem indisponíveis para utilização pelos demais sistemas do jogo.

A fórmula de custo em PG por ativação pertence exclusivamente ao `FORMULAS.md`, este documento apenas documenta a aplicação dos custos.

## Ordem das Ativações

Para garantir que o crescimento operacional do Reino tenha prioridade, todo nível segue obrigatoriamente a ordem abaixo para a Expansão Administrativa:

1. Ativação de todos os Cargos de Comando Ativo disponíveis na Infraestrutura Administrativa do nível.
2. Ativação de todas as Vagas da Reserva disponíveis na Infraestrutura Administrativa do nível.

---

# Distribuição Oficial de Infraestrutura Administrativa

A tabela abaixo define a distribuição oficial da **Infraestrutura Administrativa** bruta gerada por nível de Progressão Vertical do Centro de Comando. Estes valores representam o potencial a ser ativado pela Expansão Administrativa.

| Nível Vertical (CdC) | Nova Infraestrutura Administrativa Gerada |
| --- | --- |
| 1 | +1 Ativo +4 Reserva |
| 2 | +1 Ativo +4 Reserva |
| 3 | +2 Ativos +3 Reserva |
| 4 | +2 Ativos +3 Reserva |
| 5 | +2 Ativos +4 Reserva |
| 6 | +2 Ativos +4 Reserva |
| 7 | +2 Ativos +5 Reserva |
| 8+ | +2 Ativos +3 Reserva |

*Nota: Os valores de distribuição são cumulativos e não alterados por esta revisão.*

---

# Aplicação de Custos em PG

Tabela referencial de custos em PG para ativação de Recursos Administrativos via Expansão Administrativa. O custo é determinado pela faixa de nível atual do CdC.

| Faixa do CdC (Nível) | PG por Unidade de Recurso (Cargo/Vaga) |
| --- | --- |
| 1 – 10 | 1 |
| 11 – 20 | 2 |
| 21 – 30 | 3 |
| 31 – 40 | 4 |
| 41 – 50 | 5 |

A progressão de custo continua seguindo este padrão (+1 PG a cada 10 níveis). A fórmula matemática oficial encontra-se em `FORMULAS.md`.

---

# Exceção Inicial — Recursos Administrativos Gratuitos

Ao Nível 1, o Reino recebe **automaticamente ativados**, sem custo em PG, o suficiente para o jogador começar a jogar:

* 1 Cargo de Comando Ativo.
* 1 Vaga da Reserva.

Essa é a única exceção à regra geral ("toda Infraestrutura Administrativa precisa ser ativada via Expansão Administrativa") em todo este documento — existe exclusivamente para que um Reino recém-criado tenha, desde o início, capacidade real de alocar ao menos 1 Comandante em Estado Ativo e 1 em Estado Reserva, sem depender de PG que o jogador ainda não teve chance de acumular. A partir daí, toda capacidade adicional (inclusive o restante da própria Infraestrutura do Nível 1: +0 Ativo +3 Reserva remanescentes) volta a seguir a regra normal de Expansão Administrativa via PG.

---

# Regras Gerais

* O Centro de Comando administra os Recursos Administrativos; os comandantes pertencentes ao Reino ocupam estas estruturas conforme seu Estado Administrativo.
* Toda Infraestrutura Administrativa precisa ser ativada via Expansão Administrativa, tornando-se Recursos Administrativos, antes de ser utilizada para alocar um comandante — exceto a Exceção Inicial descrita acima.
* A Progressão Vertical nunca recruta ou cria comandantes.
* A Expansão Administrativa nunca recruta ou cria comandantes.
* Prestígio Global (PG) nunca é utilizado para evoluir o nível vertical (edifício).
* Recursos base (Ouro, Madeira, etc.) nunca são utilizados para ativar Recursos Administrativos na Expansão Administrativa.

---

# Escopo do Documento

Este documento define:

* Progressão Vertical do Centro de Comando.
* Conceitos de Capacidade Administrativa e Infraestrutura Administrativa.
* Expansão Administrativa.
* Conceitos de Recursos Administrativos (Cargos de Comando Ativo e Vagas da Reserva).
* Distribuição oficial de Infraestrutura Administrativa por nível.
* Aplicação dos custos em Prestígio Global (PG).

Este documento **não** define:

* Sistemas de recrutamento de comandantes (ver `COMMAND_CENTER_RECRUITMENT.md`).
* Sistemas de treinamento de comandantes (ver `COMMAND_CENTER_TRAINING.md`).
* Estados administrativos dos comandantes (ver `COMMAND_CENTER.md`).
* Sistemas de aposentadoria e legado (ver `COMMAND_CENTER_LEGACY.md`).
* Fórmulas matemáticas base (ver `FORMULAS.md`).
* Regras de combate ou atributos de comandantes.

---

# Referências

Este documento possui dependências arquiteturais e conceituais com os seguintes arquivos:

* PROJECT_STRUCTURE.md
* GLOSSARY.md
* COMMAND_CENTER.md (Definição de Estados Administrativos e Filosofia do CdC)
* COMMAND_CENTER_RECRUITMENT.md (Utilização dos Recursos Administrativos para contratação)
* COMMAND_CENTER_LEGACY.md (Relação entre bônus permanentes e a Capacidade Administrativa total do Reino)
* FORMULAS.md (Fórmulas de custo e tempo de evolução e custo de PG)