# SEASONS.md

# Objetivo

Este documento define a filosofia, estrutura e funcionamento das Temporadas.

As Temporadas representam a evolução contínua do mundo de Battle Simulator.

Seu objetivo não é substituir conteúdo existente, mas expandir permanentemente o universo do jogo.

---

# Conceito Arquitetural

> Uma **Temporada** é um ciclo temporal global do Battle Simulator responsável por sincronizar a expansão permanente do mundo e o início de um novo ciclo competitivo, sem reiniciar a progressão permanente dos jogadores.

---

# Responsabilidade do Documento

Este documento é a fonte única de verdade (*Single Source of Truth*) para:

* O conceito e a estrutura de uma Temporada;
* A duração das Temporadas;
* A relação entre o Tempo do Mundo e o Tempo do Jogador;
* A expansão permanente do mundo;
* A sincronização global dos sistemas.

Este documento **não** define:

* Conteúdo e estrutura detalhada do PvE (`PvE.md`);
* Funcionamento e regras das Campanhas (`PvE.md`);
* Regras do Ranking e Matchmaking (`RANKING.md`);
* Funcionamento da Academia (`ACADEMY.md`);
* Funcionamento e regras das Minas (`MINES.md`);
* Economia e tabela de Recursos (`RESOURCES.md`);
* Atributos e progressão de Comandantes (`COMMANDERS.md`).

Esses domínios pertencem estritamente aos seus respectivos documentos de arquitetura.

---

# Filosofia

Uma Temporada representa um marco histórico na reconstrução do Reino.

Enquanto o jogador explora e reunifica territórios já conhecidos, os Grandes Magos continuam pesquisando formas de estabilizar novos Portais para terras ainda desconhecidas.

Ao final de cada Temporada, um novo Portal é estabilizado.

Um novo Território torna-se acessível.

O mundo cresce.

Nunca reinicia.

---

# O Tempo do Mundo

As Temporadas pertencem ao mundo.

Não pertencem ao jogador.

Sua duração é fixa.

Referência atual:

**6 meses.**

Independentemente do progresso individual dos jogadores, o mundo continua evoluindo.

Ao término desse período, uma nova Temporada sempre começa.

---

# O Tempo do Jogador

Cada jogador progride em seu próprio ritmo.

A conclusão de uma campanha não possui qualquer relação com o encerramento da Temporada.

Da mesma forma, o encerramento da Temporada não impede a continuidade de campanhas anteriores.

O jogador pode concluir qualquer campanha quando desejar.

---

# Os Portais

Desde a descoberta dos Portais pelos Grandes Magos, o Reino investe continuamente recursos para estabilizar novas passagens.

Durante toda a Temporada, pesquisas e experimentos aproximam o Reino da abertura de um novo Território do continente.

Esse processo ocorre independentemente das ações individuais dos jogadores.

Ao final da Temporada, o Portal torna-se estável e um novo Território é descoberto.

---

# Eventos Narrativos

Ao longo da Temporada, o jogo pode apresentar acontecimentos relacionados ao progresso das pesquisas dos Magos.

Exemplos:

* Novas descobertas;
* Avanços na estabilização do Portal;
* Registros de criaturas desconhecidas;
* Mensagens dos exploradores;
* Relatos sobre o novo Território.

Esses eventos possuem função narrativa e aumentam a expectativa para a próxima Expedição.

---

# Estrutura e Expansão do Mundo

Cada Temporada introduz novos conteúdos permanentes ao ecossistema do jogo. A natureza e a implementação detalhada desses conteúdos são definidas pelos documentos responsáveis por cada sistema.

De forma geral, a chegada de uma nova Temporada expande o mundo introduzindo um novo Território com sua respectiva Trilha e desdobramentos em cartas, Comandantes, pesquisas e estruturas econômicas.

---

# Crescimento Permanente

O mapa do mundo nunca diminui.

Nenhum Território é removido.

Nenhuma campanha desaparece.

Nenhuma facção deixa de existir.

Cada Temporada amplia o mundo conhecido.

---

# Campanhas Permanentes

Cada Território corresponde a uma campanha permanente (`PvE.md`).

Após seu lançamento, ela permanece disponível para todos os jogadores.

As campanhas podem ser concluídas em qualquer momento.

Não existe limite de tempo para finalizar um Território.

---

# Progressão Não Linear

O jogador nunca é obrigado a concluir campanhas anteriores para acessar um novo Território.

Sempre que um novo Portal é estabilizado:

Todos os jogadores recebem acesso imediato ao novo Território.

Isso inclui:

* Jogadores veteranos;
* Jogadores casuais;
* Jogadores recém-chegados.

---

# Jogadores Novos

Um jogador pode iniciar sua jornada diretamente na Temporada atual.

As campanhas anteriores permanecem disponíveis para exploração posterior.

Essa decisão impede que novos jogadores fiquem permanentemente atrasados em relação aos veteranos.

---

# Conquista de Territórios

A conquista completa de um Território depende exclusivamente do progresso do jogador.

Ela não depende do calendário das Temporadas.

Ao concluir a campanha de um Território, o Reino passa a contar com o apoio permanente daquele povo. Os bônus obtidos por essa conquista são permanentes e independentes do calendário das Temporadas (`PvE.md`).

---

# Relação com o Lore

Os novos Territórios representam regiões que permaneceram isoladas desde o Grande Cataclismo.

Cada Portal estabilizado revela:

* Novos povos;
* Novas culturas;
* Novas tecnologias;
* Novos recursos;
* Novas formas de magia.

Essas descobertas expandem continuamente o conhecimento do Reino.

---

# Relação com Outros Sistemas

* **Academia:** Novas Temporadas podem disponibilizar novos conteúdos e receitas para a Academia, conforme definido em `ACADEMY.md`.
* **PvP:** O encerramento de uma Temporada inicia um novo ciclo competitivo, conforme definido em `RANKING.md`.
* **Campanha (PvE):** Novas Temporadas introduzem novos Territórios com suas respectivas Trilhas, conforme definido em `PvE.md`.

---

# Diretriz de Preservação de Progressão

O encerramento de uma Temporada não redefine sistemas de progressão permanente. Apenas sistemas explicitamente definidos pelos seus respectivos documentos (como o ciclo competitivo no PvP) podem iniciar um novo ciclo.

Todos os elementos do Reino, Cidade, edifícios, coleções, Comandantes, recursos e conquistas são preservados integralmente entre Temporadas.

---

# Princípios Permanentes

Toda nova Temporada deverá respeitar rigorosamente os seguintes princípios:

* As Temporadas expandem o mundo sem substituir ou remover conteúdos anteriores;
* Toda expansão do mundo é permanente;
* Novos Territórios preservam integralmente a arquitetura existente;
* A progressão permanente do jogador nunca é reiniciada por uma Temporada;
* O tempo do mundo é compartilhado globalmente por todos os jogadores;
* O tempo individual do jogador permanece independente;
* Novas facções ampliam possibilidades, nunca substituem facções existentes;
* Todo jogador pode acessar imediatamente o Território mais recente;
* A narrativa do mundo evolui independentemente do progresso individual dos jogadores.

---

# Perspectiva Futura

Enquanto existirem Territórios desconhecidos além dos Portais, o Reino continuará expandindo seus horizontes.

Cada nova Expedição representa mais um passo na reconstrução da antiga aliança entre os povos do continente.

A história do Reino nunca recomeça.

Ela apenas continua.

---

# Referências

* **PvE.md:** Estrutura territorial (Territórios, Trilhas, Regiões), mecânicas de Expedição e campanhas.
* **RANKING.md:** Regras do ecossistema PvP, resets de ciclo competitivo e ligas.
* **ACADEMY.md:** Desbloqueio de receitas, pesquisas e afinidades entre facções.
* **COMMANDERS.md:** Coleção, XP e patentes dos Comandantes.
* **MINES.md:** Sistema de conquista e operação econômica de minas.
* **RESOURCES.md:** Economia global e categorias de recursos.