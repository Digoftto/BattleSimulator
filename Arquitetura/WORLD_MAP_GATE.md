# WORLD_MAP_GATE.md

# World Map Gate

## Objetivo

Este documento define o World Map Gate como o ponto de entrada operacional para as atividades diretamente relacionadas ao mapa/mundo do Reino: **PvP**, **PvE** e **Minas** (Minas básicas e Minas do mapa).

## Origem e Reorganização

Até esta reorganização, a navegação para PvP/PvE/Minas ocorria através do Centro de Comando (decisão de hierarquia do MVP então citada como "F-016/F-017" em `CITY.md`/`COMMAND_CENTER_UI.md`), enquanto o World Map Gate permanecia puramente decorativo na arte da Cidade, sem hitbox (`city_panel.gd`).

Por decisão explícita do usuário, essa hierarquia foi revertida em duas etapas:

1. O World Map Gate passou a ser o proprietário documental da organização de acesso a PvP/PvE/Minas; o Centro de Comando deixou de tê-los como janelas próprias — mas, nessa primeira etapa, ainda era alcançado através de um botão dentro do Centro de Comando (localização física provisória, incorreta).
2. **Correção posterior:** o World Map Gate deixou de ser alcançado através do Centro de Comando em qualquer nível. Ele é, ele mesmo, uma localização própria da Cidade (`CITY.md`, grupo "Consulta") — com hitbox direto sobre o portão físico já desenhado em `City.png`, mesmo padrão de Biblioteca/Observatório.

**Nada mudou nas regras, no combate, nas recompensas, na progressão, nos dados, no salvamento ou nos resolvers de PvP/PvE/Minas em nenhuma das duas correções.** As 3 janelas abaixo são o mesmo texto já documentado anteriormente em `COMMAND_CENTER_UI.md`, apenas realocado — nenhuma regra foi reescrita nesta migração. As cenas reaproveitadas continuam sendo exatamente as mesmas (`pve_panel.tscn`, `pvp_panel.tscn`, `minas_panel.tscn`) — nenhum sistema foi duplicado.

## Responsabilidade do Documento

Este documento é a fonte única de verdade (*Single Source of Truth*) para:

* A organização das janelas do World Map Gate (PvP, Minas, PvE);
* O fluxo de navegação entre essas janelas;
* Quais informações cada janela exibe e quais ações o jogador pode tomar nelas.

Este documento **não** define:

* Regras de PvP, Ligas, Divisões ou Plano de Campanha (`RANKING.md`);
* Regras de PvE, Trilhas ou Expedições (`PvE.md`);
* Regras de Minas, Ciclo de Mineração ou Guarnição (`MINES.md`);
* Ordem de ataque, Exército de Defesa ou mapeamento de Campos de Batalha do Plano de Campanha — esses parâmetros continuam geridos administrativamente pelo Centro de Comando (`COMMAND_CENTER.md`, "Plano de Campanha"), mesmo com o acesso operacional à janela de PvP agora vivendo aqui.

Esses domínios pertencem exclusivamente aos seus respectivos documentos de arquitetura. Este documento apenas organiza como o jogador acessa e visualiza esses sistemas — nunca redefine suas regras.

## Acesso Atual

O World Map Gate é alcançado diretamente pela Cidade: um hitbox próprio sobre o portão físico já desenhado em `City.png` (`city_panel.gd`, grupo "Consulta" — mesmo padrão de Biblioteca/Observatório, sem Nível/Evoluir, só Abrir). O Centro de Comando não organiza esse acesso em nenhum nível, direto ou indireto.

A cena reaproveitada é a mesma de sempre (`world_map_gate_panel.gd`/`.tscn`) — só o ponto de partida da navegação mudou (antes um botão dentro do Centro de Comando, agora um hitbox direto da Cidade); o conteúdo da tela (encaminhamento para PvE/PvP/Minas) não foi alterado.

A arte própria do World Map Gate (`WORLD MAP GATE.png`, já existente em `Assets/MVP/Construções/`) ainda não foi integrada — a tela continua no mesmo estilo funcional sem arte (`ColorRect` + Botões nativos) usado em todo o módulo do Centro de Comando. Integração visual fica para uma fase futura de produção de assets.

---

# Princípio Geral: Interface, Não Regra

O World Map Gate é a porta de entrada operacional para a utilização de Comandantes e Exércitos em PvP, PvE e Minas — mas nunca é o dono das regras desses modos. Cada janela abaixo consulta e aciona o sistema correspondente; nenhuma janela decide uma regra que não esteja documentada no sistema dono daquele domínio.

---

# Janela: PvP

Ponto de acesso único às 4 Ligas (Bronze, Prata, Ouro, Diamante — `RANKING.md`).

## Bronze (Modelo Individual)

* O jogador registra de 1 a 3 Comandantes, cada um liderando um Exército **totalmente independente** dos demais — sem vínculo, sem Plano de Campanha.
* Não existe registro de Campos de Batalha customizados: toda partida da Liga Bronze ocorre no Campo Aberto (`RANKING.md`, "Isenções do Modelo").
* A janela exibe, por Comandante: Divisão atual, Pontos de Liga, histórico recente, energia do Exército.

## Prata, Ouro e Diamante (Plano de Campanha)

* O jogador registra até 3 Comandantes vinculados a um único Plano de Campanha por Liga (`RANKING.md`).
* A janela permite configurar, a qualquer momento do ciclo (`COMMAND_CENTER.md`, "Plano de Campanha"):
  * O mapeamento dos 9 Campos de Batalha Especiais entre os 3 Exércitos (0 a 9 por Exército, sem repetição);
  * O Exército de Defesa Preferencial para o Campo Aberto (único Campo compartilhável);
  * A Ordem de Ataque entre os Exércitos elegíveis ao Campo Aberto;
  * A composição de cada Exército (cartas, formações, posicionamento).
* **Ao Atacar:** o Campo de Batalha é sorteado automaticamente (`BATTLEFIELDS.md`), restrito aos Campos cujo Exército mapeado ainda tenha energia suficiente (10 pontos por Ataque — `ENERGY.md`). Se mais de um Exército for elegível (só possível no Campo Aberto), a Ordem de Ataque decide qual é usado. Se nenhum Exército tiver energia suficiente para nenhum Campo, Atacar fica indisponível até a energia recuperar.
* **Ao ser atacado (Defesa):** sempre automática — o Campo sorteado pelo atacante identifica o Exército mapeado (ou o Defensor Preferencial, se o Campo Aberto). A energia do defensor nunca é verificada; a defesa está sempre disponível.
* A janela exibe: Divisão atual, Pontos de Liga, histórico de confrontos recentes (Ataque e Defesa), energia de cada um dos 3 Exércitos, e qual Campo cada um está mapeado a defender.

## Recuperação

Quando um Exército registrado em qualquer Liga não está em combate, ele é considerado posicionado na Cidade para todos os efeitos de recuperação de Energia (`ENERGY.md`) — nenhuma regra nova, apenas a aplicação da regra já existente.

---

# Janela: Minas

Lista todas as Minas já conquistadas pelo jogador (`MINES.md`) — **a conquista de novas Minas não acontece aqui**, é parte do fluxo de PvE (`PvE.md`, "Ramificação"); esta janela só gerencia o que já pertence ao jogador.

Para cada Mina, exibe:

* Localização (Fase/Território, ou "Mina Inicial");
* Nível estrutural atual;
* Se há um Ciclo de Mineração ativo, e quanto tempo falta para ele terminar;
* A Guarnição atualmente designada (Exército e Comandante);
* O modo de Renovação configurado (Automática ou Manual — `MINES.md`, "Renovação").

## Visualização da Mina

Ao entrar em uma Mina específica, o jogador vê o Exército da Guarnição (Defensor) e a Formação de Referência (Atacante) posicionados em alguma formação — **essa visualização é sempre estática e ilustrativa**, nunca reflete literalmente qual das 362.880 combinações está "em disputa" naquele instante. O cálculo em lote (`MINES.md`, "Observação Técnica") é inteiramente invisível ao jogador; não existe tela de carregamento nem prévia de resultado.

## Ações Disponíveis por Mina

* **Designar ou trocar a Guarnição** — só possível quando não há Ciclo ativo (trava anti-exploit já existente, `MINES.md`). Só Exércitos livres (não alocados em outra função) podem ser designados.
* **Escolher o modo de Renovação** (Automática ou Manual) — pode ser alterado a qualquer momento, mesmo com um Ciclo em andamento; o modo escolhido só faz efeito no término do Ciclo atual.
* **Iniciar um novo Ciclo de Mineração**, uma vez a Guarnição designada.

## Sem Previsão de Resultado

Diferente de outras janelas, esta não oferece nenhuma prévia de Eficiência antes de confirmar a Guarnição — o resultado só é conhecido através da produção creditada ao longo do Ciclo.

---

# Janela: PvE

Exibe, por Trilha ativa (`PvE.md`) — o jogador pode ter múltiplas Trilhas em andamento simultaneamente, cada uma com seu próprio Squad:

* O Squad posicionado naquela Trilha (quais Exércitos o compõem, e a Ordem de Substituição entre eles);
* Progresso atual (Fase alcançada, Acampamento mais recente);
* Energia de cada Exército do Squad;
* Se há uma Mina disponível naquele trecho já percorrido (conquistada ou não).

## Montagem e Edição do Squad

* **Montagem inicial:** ao começar uma Expedição (ou um Replay), o jogador monta o Squad com a quantidade de Exércitos exigida pelo estágio da Trilha (`PvE.md`: 1 na Campanha inicial, 2 no 1º Replay, 3 do 2º Replay em diante), usando o Editor de Exército comum para cada um.
* **Travado durante o avanço:** quais Exércitos compõem o Squad, e a Ordem de Substituição entre eles, só podem ser alterados quando o Squad está na Cidade ou parado em um Acampamento — nunca durante o avanço idle ativo entre dois Acampamentos.
* **Edição individual sempre livre:** independente disso, a composição de cada Exército (Comandante, cartas) e suas 5 Formações (α a ε) podem ser editadas a qualquer momento fora de combate — inclusive como a alavanca oficial para destravar um Trecho difícil (`PvE.md`, "Filosofia do Travamento").

## Minas

* Uma Mina fica disponível assim que a Fase adjacente a ela é vencida — não exige presença física naquele ponto da Trilha, nem interrompe a marcha idle enquanto não for acionada.
* Conquistá-la não exige o Exército atualmente liderando o Squad — **qualquer Exército disponível do Reino** pode ser enviado, mesmo que não pertença àquele Squad.
* Gerenciamento contínuo da Mina (Guarnição, Ciclo de Mineração) pertence à Janela de Minas, não a esta.

## Acampamentos

Ao atingir ou recuar para um Acampamento, a janela oferece as duas opções já documentadas (`PvE.md`, "Decisão Estratégica no Acampamento"): continuar imediatamente com energia parcial, ou permanecer em repouso até recuperar mais.

---

# Regra Transversal: Exclusividade de Alocação

Um Comandante ou Exército alocado em uma função (Liga de PvP, Trilha de PvE, Guarnição de Mina, Treinamento) fica **indisponível** para qualquer outra função ao mesmo tempo — a mesma regra de exclusividade já implementada (`Kingdom.is_commander_available()` / `Kingdom.is_card_available()` / `Army.Availability`) e documentada como "Regra Geral de Exclusividade" em `COMMAND_CENTER.md`. Todas as janelas deste documento devem refletir essa indisponibilidade de forma imediata e consistente — nenhuma janela pode permitir que o jogador tente alocar um Comandante ou Exército já ocupado em outro lugar (incluindo Treinamento, que permanece uma responsabilidade do Centro de Comando).

---

# Referências

* **COMMAND_CENTER.md:** Plano de Campanha (ordem de ataque, Exército de Defesa, mapeamento de Campos de Batalha) — parâmetros administrativos que permanecem no CdC.
* **COMMAND_CENTER_UI.md:** Janelas de Treinamento, Legado, Comandantes e Exércitos (permanecem no CdC).
* **RANKING.md:** Ligas, Divisões, Pontos de Liga, inscrição no Plano de Campanha.
* **BATTLEFIELDS.md:** Campos de Batalha, sorteio e seleção automática de Exército.
* **PvE.md:** Trilhas, Expedições, Fases.
* **MINES.md:** Minas, Ciclo de Mineração, Guarnição.
* **ARMY.md:** Formações de Exército.
* **ENERGY.md:** Recuperação de Energia na Cidade.
* **CITY.md:** "Mundo" — relação entre PvE/PvP/Minas e a infraestrutura urbana.
