# COMMAND_CENTER_UI.md

# Interface do Centro de Comando

## Objetivo

Este documento define todas as telas, janelas, indicadores e fluxos de interface relacionados ao Centro de Comando (CdC) — o arquivo referenciado pela estrutura de documentação do CdC (`COMMAND_CENTER.md`, "Organização da Documentação") e que ainda não havia sido escrito.

## Responsabilidade do Documento

Este documento é a fonte única de verdade (*Single Source of Truth*) para:

* A organização das janelas do CdC (Treinamento, Legado, Comandantes, Exércitos);
* O fluxo de navegação entre essas janelas;
* Quais informações cada janela exibe e quais ações o jogador pode tomar nelas.

> **REORGANIZAÇÃO:** as janelas de PvP, Minas e PvE deixaram de pertencer ao CdC — mudaram de proprietário documental para `WORLD_MAP_GATE.md` (decisão explícita do usuário, revertendo a hierarquia anterior "F-016/F-017" que fazia do CdC a porta de entrada única desses 3 sistemas; ver `WORLD_MAP_GATE.md` para o texto integral das 3 janelas, preservado sem alteração de regra). **Correção posterior:** o World Map Gate também deixou de ser alcançado a partir do CdC — é uma localização própria da Cidade (`CITY.md`), com hitbox direto sobre a arte (`city_panel.gd`). O CdC não organiza esse acesso em nenhum nível.

Este documento **não** define:

* Regras de PvP, Ligas, Divisões ou Plano de Campanha (`RANKING.md`);
* Regras de PvE, Trilhas ou Expedições (`PvE.md`);
* Regras de Minas, Ciclo de Mineração ou Guarnição (`MINES.md`);
* Regras de Formações de Exército (`ARMY.md`);
* Estados administrativos, recrutamento, treinamento ou legado de Comandantes (`COMMAND_CENTER.md` e demais documentos do módulo `command_center`);
* Ordem de ataque, Exército de Defesa ou mapeamento de Campos de Batalha do Plano de Campanha (`COMMAND_CENTER.md`, "Plano de Campanha") — este último permanece descrito aqui como configuração operacional do CdC (o Plano de Campanha em si é acionado pela janela de PvP, hoje em `WORLD_MAP_GATE.md`, mas seus parâmetros de mapeamento continuam sendo geridos administrativamente pelo CdC, ver `COMMAND_CENTER.md`).

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura. Este documento apenas organiza como o jogador acessa e visualiza esses sistemas — nunca redefine suas regras.

---

# Princípio Geral: Interface, Não Regra

O CdC é a porta de entrada operacional para a utilização de Comandantes e Exércitos em Treinamento e Legado — mas nunca é o dono das regras desses modos (`COMMAND_CENTER.md`, "O que o CdC NÃO faz"). Cada janela descrita abaixo consulta e aciona o sistema correspondente; nenhuma janela decide uma regra que não esteja documentada no sistema dono daquele domínio. PvP, PvE e Minas seguem o mesmo princípio, agora sob `WORLD_MAP_GATE.md`.

---

# Janela: Treinamento

Ponto de acesso ao Sistema de Treinamento de Comandantes (`COMMAND_CENTER_TRAINING.md`). Todas as regras de duração, cálculo de XP, cancelamento e promoção automática pertencem exclusivamente àquele documento — esta janela apenas as exibe e aciona.

## Resumo (topo da janela)

* Vagas de Treinamento utilizadas / disponíveis (`COMMAND_CENTER_PROGRESS.md`, "Vagas de Treinamento" — 1 no desbloqueio, Nível 3 do CdC, +1 a cada 4 níveis, mais eventuais vagas extras do Legado II);
* Média Diária de XP (base do cálculo de todos os Comandantes em treinamento no momento);
* Bônus percentual concedido pelo Legado I, se houver.

## Lista de Comandantes em Treinamento

Para cada Comandante ocupando uma Vaga de Treinamento, exibe:

* Nome e Patente atual;
* Tempo restante para o término do Ciclo de Treinamento atual (10 dias por ciclo);
* XP Acumulada no ciclo atual (ainda não incorporada ao Comandante);
* XP total já incorporada, e progresso até a próxima Promoção.

## Ações

* **Enviar para Treinamento:** disponível para qualquer Comandante em Estado `Reserve`, enquanto houver Vaga de Treinamento livre. Ele permanece contando normalmente como ocupante de sua Vaga da Reserva (`COMMAND_CENTER_TRAINING.md`) — não libera nem consome uma vaga adicional além da de Treinamento.
* **Cancelar Treinamento:** pode ser feito a qualquer momento; descarta toda a XP Acumulada não incorporada do ciclo atual e retorna o Comandante ao Estado `Reserve` imediatamente.
* **Permanecer em Treinamento:** ao término de um Ciclo, se o jogador não cancelar, um novo Ciclo começa automaticamente com o mesmo Comandante, sem exigir nenhuma ação.

## Exclusividade

Um Comandante em Treinamento não pode ser alocado em PvP, PvE ou Minas ao mesmo tempo — a mesma Regra Transversal de Exclusividade desta interface (ver abaixo).

# Janela: Legado

Ponto de acesso ao Sistema de Legado (`COMMAND_CENTER_LEGACY.md`). Todas as regras de aposentadoria, bônus e critérios de elegibilidade pertencem exclusivamente àquele documento — esta janela apenas as exibe e aciona. Dividida em 3 painéis.

## Resumo Administrativo

* Total de Comandantes aposentados via Legado Administrativo;
* Benefícios acumulados: bônus de XP de Treinamento (Legado I), Vagas de Treinamento extras (Legado II), Vagas da Reserva extras (Legado III), Cargos de Comando Ativo extras (Legado IV), bônus percentual escolhido (Legado V);
* Progresso até a próxima recompensa cumulativa de cada Legado (ex: "14/20 para o próximo +1 Vaga de Treinamento").

## Aposentar um Comandante (Legado Administrativo)

* Lista Comandantes elegíveis — qualquer Comandante `Active` ou `Reserve` (nunca `Training`; precisa sair do Treinamento primeiro) cuja Patente atenda ao mínimo do maior Legado desbloqueado no CdC atual (`COMMAND_CENTER_LEGACY.md`, "Patentes Mínimas" — ex: Legado III precisa de Coronel, exige CdC Nível 8).
* Ao confirmar: aviso de que a ação é **irreversível** (o Comandante nunca retorna ao serviço), aplica os benefícios de todos os Legados que a Patente dele alcança simultaneamente (cumulativo — um Marechal concede I, II, III, IV e V ao mesmo tempo), e registra o Comandante no Hall.
* Se o Legado V estiver desbloqueado (CdC Nível 10), a confirmação também pede a escolha do destino do bônus percentual daquele Comandante: XP, Recursos ou Fragmentos.

## Grande Legado Militar

* Desbloqueado apenas no CdC Nível 100 — painel inteiro oculto/desabilitado antes disso.
* Mostra, por Facção, a Doutrina Militar atual (bônus de atributo já concedidos) e o progresso até os limites (+5/+2/+1 — `COMMAND_CENTER_LEGACY.md`, "Limites por Facção").
* Interface de criação só fica ativa quando um Exército do jogador atende **todos** os requisitos simultaneamente (Comandante Marechal, Ativo, Soldo totalmente utilizado; 9 cartas Tier V, mesma Facção do Comandante) — ver `COMMANDERS.md`/`SOLDO.md` para os requisitos completos.
* Se a Facção selecionada já atingiu todos os limites, exibe o aviso já definido no documento: a criação continua funcionando (registra no Hall), mas não concede mais nenhum atributo.
* Ao confirmar: aviso de consumo definitivo (Comandante **e** as 9 cartas são removidos permanentemente da coleção — não é o mesmo aviso do Legado Administrativo, este é ainda mais destrutivo), depois o jogador escolhe em qual dos 3 atributos da Doutrina daquela Facção aplicar o ponto (entre os que ainda não atingiram o limite).

## Hall dos Comandantes

* Lista todos os Comandantes aposentados (as duas categorias), com busca e filtro por Tipo de Aposentadoria.
* Por Comandante: ID, Nome, Facção, Patente Final, datas de recrutamento/aposentadoria, estatísticas de carreira, Tipo de Aposentadoria, benefício concedido, título honorífico (se houver).
* Os 9 pelotões consumidos num Grande Legado Militar **não** aparecem aqui — só o Comandante veterano é imortalizado.

---

# Janela: Exércitos

Ponto de acesso à lista de Exércitos do Reino (`ARMY.md`) — decisão de hierarquia do MVP (F-016/F-017): reaproveita a tela já existente, sem nenhuma alteração de regra de composição, Formação ou disband. O CdC apenas organiza o acesso a essa tela; `ARMY.md` continua sendo o único dono das regras de Exército.

---

# Janela: Comandantes (Candidatos, Reserva e Ativos)

Exibe todos os Comandantes do Reino, organizados pelo Estado Administrativo atual (`COMMAND_CENTER.md`, "Estados Administrativos"): `Candidate`, `Reserve`, `Training`, `Active`. Comandantes `Retired` pertencem ao Hall, exibido na Janela de Legado — não aparecem aqui.

## Candidatos

Lista as Ofertas de Recrutamento pendentes (`COMMAND_CENTER_RECRUITMENT.md`) — Comandante oferecido, prazo até a expiração (4 dias). Ações: **Aceitar** (Comissiona o Candidato, que entra direto em `Reserve`) ou **Recusar**.

## Reserva

Lista Comandantes em `Reserve`: Nome, Patente, Facção. Ação: **Promover a Ativo** — exige um Cargo de Comando Ativo disponível (`CommandCenterResolver.move_to_active()`); se não houver nenhum ativado, a ação fica desabilitada com a mensagem "Nenhum Cargo de Comando Ativo disponível" (ver Resumo, abaixo).

## Ativos

Lista Comandantes em `Active`: Nome, Patente, Facção, e **em qual função específica** está alocado no momento — PvP (Liga e, se aplicável, papel de Ataque/Defesa), PvE (Trilha), Minas (qual Mina), ou nenhuma (Ativo, mas ocioso). Consultado ao vivo em cada sistema, nunca armazenado de forma duplicada aqui. Ação: **Voltar à Reserva** — exige uma Vaga da Reserva disponível (`CommandCenterResolver.move_to_reserve()`); se o Comandante estiver liderando um Exército no momento, precisa primeiro ser desalocado de lá.

## Resumo (topo da janela)

* Cargos de Comando Ativo: ocupados / ativados (`kingdom.cargo_ativo_activated`);
* Vagas da Reserva: ocupadas / ativadas (`kingdom.vaga_reserva_activated`);
* Botão **Ativar Próximo Recurso Administrativo** — gasta PG para ativar o próximo Cargo Ativo ou Vaga da Reserva disponível na Infraestrutura do Nível do CdC (`CommandCenterResolver.activate_next()` — a ordem entre Ativo e Reserva é sempre automática, nunca uma escolha do jogador).

---

# Regra Transversal: Exclusividade de Alocação

Um Comandante ou Exército alocado em uma função (Liga de PvP, Trilha de PvE, Guarnição de Mina, Treinamento) fica **indisponível** para qualquer outra função ao mesmo tempo — a mesma regra de exclusividade já implementada (`Kingdom.is_commander_available()` / `Kingdom.is_card_available()` / `Army.Availability`) e documentada como "Regra Geral de Exclusividade" em `COMMAND_CENTER.md`. Todas as janelas deste documento devem refletir essa indisponibilidade de forma imediata e consistente — nenhuma janela pode permitir que o jogador tente alocar um Comandante ou Exército já ocupado em outro lugar.

---

# Referências

* **COMMAND_CENTER.md:** Arquitetura geral, Estados Administrativos, Plano de Campanha (ordem de ataque, Exército de Defesa, mapeamento de Campos de Batalha).
* **COMMAND_CENTER_RECRUITMENT.md:** Regras de recrutamento (janela própria, já documentada).
* **COMMAND_CENTER_TRAINING.md:** Regras de Treinamento.
* **COMMAND_CENTER_LEGACY.md:** Regras de Legado e Hall dos Comandantes.
* **WORLD_MAP_GATE.md:** Janelas de PvP, PvE e Minas (movidas para lá nesta reorganização).
* **ARMY.md:** Formações de Exército.
* **COMMANDERS.md:** Patentes, Autoridade Militar, Pontos de Soldo.
* **SOLDO.md:** Requisitos de Soldo para o Grande Legado Militar.
