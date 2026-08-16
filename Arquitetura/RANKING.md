# RANKING.md

# Sistema de Ranking Competitivo

## Objetivo do Documento

Este documento define a arquitetura oficial do sistema de Ranking Competitivo do Battle Simulator.

Ele estabelece a autoridade e a fonte única de verdade (*Single Source of Truth*) para:

* Modelos competitivos oficiais (Modelo Individual e Modelo de Campanha);


* Estrutura, limites globais de participação e independência das Ligas;


* Divisões, requisitos mínimos, capacidades independentes e posição relativa;
* Requisitos de acesso por Patente de Comandante;


* Congelamento e processamento de promoção de Patente no modo ranqueado;


* Ciclos competitivos, momentos de promoção e recálculo semanal de D1/D2;


* Funcionamento do Modelo Individual (Liga Bronze);


* Funcionamento do Plano de Campanha, regras de inscrição e registro de Campos de Batalha de defesa (Ligas Prata, Ouro e Diamante);


* Mecânica e tabelas de Pontos de Liga (PL);


* Regras de progressão, limite populacional e rebaixamento por PL ou posição relativa;


* Histórico competitivo permanente.



Este documento **não** define regras de matchmaking, busca ou seleção de adversários, filas, inteligência artificial, regras de combate, consumo de energia ou tabelas econômicas. Esses domínios pertencem estritamente aos seus respectivos documentos de arquitetura.

---

# Filosofia Competitiva e Modelos de Funcionamento

O Ranking do Battle Simulator mede o desempenho do jogador dentro de um ambiente competitivo específico de sua escolha.

Cada Liga opera como um campeonato totalmente independente. Não existe um modelo de progressão contínua unificada ou obrigatória (como Bronze $\rightarrow$ Prata $\rightarrow$ Ouro $\rightarrow$ Diamante). Cada Liga possui sua própria classificação, suas próprias tabelas de líderes e sua própria estrutura de divisões.

O objetivo do sistema é permitir que o jogador dispute a liderança do campeonato da Liga de sua preferência, desde que cumpra os requisitos operacionais de acesso.

## Modelos Competitivos Oficiais

A arquitetura do sistema competitivo é dividida em dois modelos oficiais de funcionamento:

1. **Modelo Individual (Liga Bronze):** focado no aprendizado, desenvolvimento e progressão isolada de Comandantes.


2. **Modelo de Campanha (Ligas Prata, Ouro e Diamante):** focado na gestão estratégica ampla operacionalizada através do Plano de Campanha.



---

# Modelos Competitivos

## Modelo 1 — Liga Bronze (Modelo Individual)

A Liga Bronze é uma **Liga de Desenvolvimento**. Seu objetivo principal é permitir que novos jogadores aprendam o sistema competitivo, experimentem mecânicas de combate e desenvolvam seus Comandantes sem a frustração de gerenciar estruturas complexas prematuramente.

### Características

A Liga Bronze opera de forma simplificada, mas possui todas as estruturas competitivas regulares:

* Ranking


* Pontos de Liga (PL)


* Divisões


* Promoções


* Rebaixamentos


* Temporadas


* Acúmulo de XP


* Congelamento de Patente durante a temporada



**Isenções do Modelo:** A Liga Bronze **não** utiliza Plano de Campanha, Comandante Atacante, Comandante Defensor ou Campos de Batalha registrados.

### Regras de Participação e Carreira Individual

* O jogador pode inscrever 1, 2 ou 3 Comandantes na Liga Bronze.


* Cada Comandante participa de forma estritamente individual. Não existe qualquer vínculo entre eles.


* Cada Comandante possui sua própria carreira competitiva dentro da Liga Bronze, contando com:


* Seu próprio histórico competitivo;


* Sua própria progressão de PL;


* Sua própria posição no Ranking;


* Sua própria Divisão.




* Nenhum desses elementos é compartilhado entre Comandantes. O desempenho de um Comandante não interfere na classificação ou pontuação dos demais.



> **Titularidade Competitiva:** Na Liga Bronze, o participante competitivo e proprietário do Ranking é o próprio Comandante.
> 
> 

---

## Modelo 2 — Ligas Prata, Ouro e Diamante (Modelo de Campanha)

As Ligas Prata, Ouro e Diamante utilizam o **Modelo de Campanha**, voltado para a disputa competitiva avançada de gestão de forças.

### Características e Função do Plano de Campanha

A partir da Liga Prata, passam a ser obrigatórios os seguintes elementos:

* Plano de Campanha;


* Inscrição de até três Comandantes;


* Mapeamento dos 3 Exércitos aos Campos de Batalha (Especiais exclusivos, Aberto com Defesa Preferencial) e Ordem de Ataque;


* Bloqueio da lista de Comandantes durante toda a temporada.



O Plano de Campanha representa a inscrição competitiva da temporada. Sua função é agrupar Comandantes, papéis e Campos de Batalha para operacionalizar a participação no ciclo. Ele não substitui nem altera a identidade individual dos Comandantes.

> **Titularidade Competitiva:** Nas Ligas Prata, Ouro e Diamante, o participante competitivo é a inscrição competitiva da temporada, operacionalizada pelo Plano de Campanha.
> 
> 

---

# Estrutura das Ligas, Limites Globais e Divisões

## 1. Ligas Independentes e Limite de Participação por Conta

O sistema competitivo conta com quatro Ligas oficiais: **Bronze** (Modelo Individual), **Prata**, **Ouro** e **Diamante** (Modelos de Campanha).

### Limites Globais de Inscrição na Temporada:

* **Por Comandante:** Um Comandante individual só pode ser inscrito em **uma única Liga** por temporada.


* **Por Conta / Jogador:** Uma conta (jogador) pode participar de no **máximo duas Ligas simultâneas** durante uma mesma temporada PvP.
* *Exemplo Permitido:* Comandante A na Liga Bronze + Plano de Campanha na Liga Ouro.
* *Exemplo Proibido:* Comandante A na Liga Bronze + Plano de Campanha 1 na Liga Prata + Plano de Campanha 2 na Liga Diamante (3 ligas no mesmo ciclo).



## 2. Nomenclatura e Hierarquia das Divisões

Cada Liga possui sete divisões oficiais. A nomenclatura oficial utiliza exclusivamente o termo **Divisão** seguido de algarismos romanos de I a VII:

* **Divisão I:** mais forte


* **Divisão II:** segunda mais forte


* **Divisão III**

* **Divisão IV**

* **Divisão V**

* **Divisão VI**

* **Divisão VII:** mais fraca



$$\text{Divisão VII} \longrightarrow \text{Divisão VI} \longrightarrow \text{Divisão V} \longrightarrow \text{Divisão IV} \longrightarrow \text{Divisão III} \longrightarrow \text{Divisão II} \longrightarrow \text{Divisão I}$$

---

# Regra Fundamental das Divisões (Elegibilidade x Capacidades Independentes)

As divisões **NÃO** são determinadas exclusivamente pelos Pontos de Liga (PL) acumulados. A divisão de um jogador é regida pela relação entre **Elegibilidade Mínima (PL)** e **Capacidade Máxima Populacional Independentes**:

1. **PL Mínimo (Elegibilidade):** Determina se o jogador possui o requisito necessário para ter direito de ingressar ou permanecer naquela divisão. Jogadores sem o PL mínimo da divisão **nunca** sobem para ela, independentemente de haver vagas sobrando.


2. **Capacidade Máxima Populacional (Limites Independentes):** Define o limite teto absoluto de vagas da divisão (Máximo de 5% dos ativos para Divisão I; Máximo de 15% dos ativos para Divisão II). O percentual é uma **capacidade máxima**, e **NÃO uma obrigação de preenchimento**.

> **Regra de Ouro:**
> * O percentual define a capacidade máxima da divisão; o PL mínimo define quem é elegível para ocupá-la.
> * A Divisão I e a Divisão II possuem **capacidades populacionais INDEPENDENTES**. A capacidade não utilizada da Divisão I **NÃO** é transferida para a Divisão II.
> * A soma D1 + D2 pode ser inferior a 20% da população caso não existam jogadores elegíveis suficientes.
> * **Se houver mais elegíveis que vagas:** Apenas os melhores colocados dentro da capacidade percentual ocupam a divisão superior. Os elegíveis excedentes são alocados nas divisões inferiores.
> 
> 
> * **Se houver menos elegíveis que vagas:** A divisão operará com capacidade reduzida. Jogadores sem o PL mínimo **nunca** preencherão vagas restantes.
> 
> 

---

# Especificações da Divisão I e Divisão II

## 1. Divisão I (Topo Competitivo)

* **PL Mínimo de Entrada:** 6.000 PL.


* **Capacidade Máxima Populacional:** Máximo de **5%** dos jogadores ativos da liga (capacidade própria independente).
* **Regra de Funcionamento:**
* Exige $\ge 6.000\text{ PL}$ **E** ocupar as posições elegíveis até o limite da capacidade (máximo 5%).
* Ocupa os melhores jogadores elegíveis dentro dessa capacidade.
* Se houver menos elegíveis com 6.000+ PL do que o limite de 5%, a Divisão I opera unicamente com os elegíveis existentes. Vagas sobrantes **não** são preenchidas por jogadores com PL inferior.



## 2. Divisão II

* **PL Mínimo de Entrada:** 5.000 PL.


* **Capacidade Máxima Populacional:** Máximo de **15%** dos jogadores ativos da liga (capacidade própria independente).
* **Regra de Funcionamento:**
* Exige $\ge 5.000\text{ PL}$ **E** estar posicionado entre os próximos jogadores elegíveis imediatamente abaixo da Divisão I efetivamente ocupada.
* A capacidade de até 15% da D2 é totalmente independente de quantos jogadores estão ocupando a D1. Vagas não utilizadas da D1 não aumentam o teto da D2.
* Seleciona os próximos jogadores elegíveis com $\ge 5.000\text{ PL}$. Jogadores com PL inferior a 5.000 podem estar intercalados na classificação global e **não ocupam vagas da D2**.
* Se o número de jogadores elegíveis com $\ge 5.000\text{ PL}$ exceder os 15% de capacidade da D2, os elegíveis excedentes serão alocados na Divisão III (mesmo possuindo 5.000+ PL).
* Se não houver jogadores elegíveis suficientes com 5.000+ PL, a D2 operará com capacidade reduzida.



## 3. Divisão III e Lógica de Elegibilidade Excedente

A Divisão III possui requisito mínimo de **4.000 PL** para entrada e progressão regular.

**Importante:** O valor de 4.000 PL **não é um teto rígido de permanência**. A Divisão III pode perfeitamente conter jogadores com $\ge 5.000\text{ PL}$. Isso ocorre quando o jogador possui PL para a Divisão II, mas foi deslocado por posição relativa devido ao limite de 15% de capacidade populacional da D2 estar totalmente preenchido por outros jogadores elegíveis com maior pontuação.

---

# Exemplo Visual e Numérico do Sistema

Considerando uma liga com **100.000 jogadores ativos**:

* **Capacidade Máxima Teórica da Divisão I (5%):** Até 5.000 vagas.
* **Capacidade Máxima Teórica da Divisão II (15%):** Até 15.000 vagas.

### Cenário Exemplo:

1. Apenas **2.000 jogadores** possuem $\ge 6.000\text{ PL}$.
2. Existem **25.000 jogadores adicionais** com $\ge 5.000\text{ PL}$.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 100.000 JOGADORES ATIVOS NA LIGA                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ DIVISÃO I (Capacidade: até 5% = 5.000 vagas)                            │
│ • Ocupação Efetiva: 2.000 jogadores                                     │
│ • Requisito: PL >= 6.000                                                │
│ • Obs: As 3.000 vagas restantes NÃO são preenchidas por jogadores       │
│   abaixo de 6.000 PL.                                                   │
├─────────────────────────────────────────────────────────────────────────┤
│ DIVISÃO II (Capacidade própria: até 15% = 15.000 vagas)                 │
│ • Ocupação Efetiva: 15.000 jogadores elegíveis                          │
│ • Requisito: PL >= 5.000                                                │
│ • Seleciona os próximos jogadores elegíveis imediatamente abaixo da D1  │
│   efetivamente ocupada.                                                 │
│ • Pode haver jogadores com PL < 5.000 intercalados na classificação    │
│   global que não ocupam vagas da D2 (a posição global do último jogador  │
│   da D2 pode ser superior a 17.000).                                    │
│ • A capacidade não utilizada de D1 (3.000 vagas) NÃO é transferida.     │
├─────────────────────────────────────────────────────────────────────────┤
│ DIVISÃO III e DEMAIS DIVISÕES                                           │
│ • Ocupação: Próximos jogadores elegíveis e posições subsequentes       │
│ • Inclui os 10.000 jogadores excedentes com PL >= 5.000 que ficaram     │
│   fora das 15.000 vagas de D2 por posição relativa entre elegíveis.     │
│ • Agrupa demais jogadores conforme regras normais de progressão (4.000+ PL).│
└─────────────────────────────────────────────────────────────────────────┘

```

---

# Dinâmica de Atualização: Promoções Imediatas vs. Recálculo Semanal

Para evitar instabilidade na tabela e oscilações instantâneas de ranking a cada partida individual, o sistema adota regras claras de tempo para atualizações:

1. **Pontuação Individual (PL):** Atualizada de forma **imediata** após o término de cada confronto PvP.


2. **Promoções Regulares (Divisão VII $\rightarrow$ Divisão III):** Ocorrem **imediatamente** no momento em que o jogador atinge o PL mínimo exigido para a divisão, conforme as regras de progressão.
3. **Consolidação Populacional e Fronteiras de D1 e D2:** A composição efetiva e as linhas de corte da Divisão I e Divisão II são **oficialmente consolidadas no Recálculo Semanal** (todas as segundas-feiras, 00:00 UTC).

### Lógica Operacional do Recálculo Semanal:

1. Determinar os jogadores ativos elegíveis para a Divisão I ($\text{PL} \ge 6.000$).


2. Selecionar no máximo 5% dos ativos (os melhores colocados elegíveis) para compor a Divisão I.
3. Determinar os jogadores ativos elegíveis para a Divisão II ($\text{PL} \ge 5.000$) que não estejam alocados na Divisão I.


4. Selecionar no máximo 15% dos ativos entre os próximos jogadores elegíveis para a Divisão II, imediatamente abaixo da Divisão I efetivamente ocupada. Jogadores intercalados com $\text{PL} < 5.000$ são ignorados e não consomem vagas da D2.
5. Jogadores elegíveis excedentes seguem para as divisões inferiores (ex: D3).
6. Jogadores abaixo dos requisitos mínimos permanecem sujeitos às regras normais de progressão/rebaixamento.



---

# Requisitos de Acesso e Regras de Patente

## 1. Requisito de Acesso e Exclusividade

O acesso a uma Liga é determinado unicamente pela **Patente do Comandante**. A Patente atua exclusivamente como requisito de elegibilidade para a inscrição do Comandante no campeonato.

> **Responsabilidade do Módulo:** O sistema de Ranking apenas consulta a Patente do Comandante como requisito de elegibilidade. O Ranking não define evolução de Patentes, requisitos de XP, limites de Tier ou critérios de promoção militar (`COMMANDERS.md`).
> 
> 

## 2. Congelamento e Promoção de Patente no Modo Ranqueado

Durante a realização de partidas ranqueadas no ciclo competitivo:

* **Acúmulo de Experiência:** O Comandante continua acumulando Pontos de Experiência (XP) normalmente ao longo dos confrontos.


* **Congelamento da Patente:** A Patente do Comandante permanece congelada no nível de entrada durante toda a temporada ranqueada. Nenhuma promoção de Patente é concedida durante a vigência do ciclo competitivo no âmbito do Ranking.


* **Processamento de Fim de Ciclo:** Ao término da temporada, todo o XP acumulado nas partidas ranqueadas é processado, aplicando promoções pendentes.



---

# Ingressando em uma Liga

A determinação da Divisão inicial em uma Liga segue regras determinísticas:

* **Primeira Inscrição na Liga:** Se o Comandante (Liga Bronze) ou a inscrição competitiva (Ligas Prata, Ouro e Diamante) jamais participou do ciclo competitivo daquela Liga específica, o posicionamento inicial ocorre obrigatoriamente na **Divisão VII**.


* **Retorno em Ciclos Subsequentes:** Se já houver histórico na Liga, o ingressante no novo ciclo será reposicionado na Divisão correspondente a duas posições abaixo da Divisão final da temporada anterior (respeitando o limite mínimo da Divisão VII).


* **Entrada em Andamento:** É permitido realizar a inscrição de um Comandante (Liga Bronze) ou de um Plano de Campanha (Ligas Prata, Ouro e Diamante) mesmo com o ciclo competitivo já em andamento.



---

# Ciclos Competitivos e Recálculo Semanal

* **Duração da Temporada:** Quatro semanas corridas.


* **Início do Ciclo:** 00:00 UTC de segunda-feira.


* **Término do Ciclo:** 00:00 UTC da segunda-feira subsequente ao término da quarta semana.



## Recálculo Semanal

A composição relativa e os cortes das divisões superiores são consolidados **semanalmente** (todas as segundas-feiras, 00:00 UTC).

O recálculo considera:

* Jogadores ativos (pelo menos um confronto ranqueado no ciclo);


* PL atual acumulado;


* Posição relativa na tabela;


* Aplicação rigorosa das capacidades máximas independentes e requisitos mínimos de PL.

## Regra de Pontos de Liga entre Temporadas

Ao término de um ciclo competitivo:

1. O histórico da temporada é consolidado e registrado permanentemente.


2. É executado o reposicionamento automático para a Divisão equivalente a duas posições abaixo da Divisão de término do ciclo anterior (respeitando o limite mínimo da Divisão VII).


3. O participante inicia o novo ciclo **exatamente na pontuação mínima de entrada da nova Divisão** em que foi reposicionado. Não existe preservação da pontuação anterior e não existe reinicialização para zero.



---

# Plano de Campanha (Ligas Prata, Ouro e Diamante)

O Plano de Campanha é a estrutura operacional que formaliza a inscrição competitiva nas Ligas Prata, Ouro e Diamante para o ciclo vigente.

## 1. Estrutura de Inscrição

Ao criar o Plano de Campanha da temporada, o jogador define:

* **Até 3 Comandantes Inscritos:** Escolhidos entre os Comandantes elegíveis da conta.


* **Mapeamento de Campos de Batalha:** Cada um dos 3 Exércitos é associado aos Campos de Batalha Especiais e ao Defesa Preferencial do Campo Aberto (`COMMAND_CENTER.md`).



## 2. Exclusividade

Cada Comandante pode participar de apenas um Plano de Campanha por temporada. A conta como um todo pode participar de no máximo duas Ligas simultâneas.

## 3. Regras de Bloqueio e Modificação

* **Inscrição de Comandantes (Fixa):** Os três Comandantes selecionados ficam **bloqueados** durante toda a temporada.


* **Mapeamento de Campos e Ordem de Ataque (Livre):** Podem ser alterados livremente a qualquer momento do ciclo.


* **Ajuste de Exércitos (Livre):** Formações e cartas podem ser alteradas livremente.



---

# Pontos de Liga (PL) e Requisitos Mínimos por Divisão

| Divisão | PL Mínimo de Entrada | Capacidade Populacional Máxima |
| --- | --- | --- |
| **Divisão VII** | 0 PL | Sem limite percentual |
| **Divisão VI** | 1.000 PL | Conforme regras de progressão |
| **Divisão V** | 2.000 PL | Conforme regras de progressão |
| **Divisão IV** | 3.000 PL | Conforme regras de progressão |
| **Divisão III** | 4.000 PL | Conforme regras de progressão e classificação |
| **Divisão II** | 5.000 PL | Máximo de 15% dos jogadores ativos |
| **Divisão I** | 6.000 PL | Máximo de 5% dos jogadores ativos |

---

# Regras de Ganho e Perda de Pontos

## 1. Divisões VII a III

* **Atacante:** Vitória +100 PL | Derrota -75 PL | Empate 0 PL


* **Defensor:** Vitória +20 PL | Derrota -20 PL | Empate 0 PL



## 2. Divisões II e I

* **Atacante:** Vitória +100 PL | Derrota -100 PL | Empate 0 PL


* **Defensor:** Vitória +20 PL | Derrota -20 PL | Empate 0 PL



---

# Promoção e Rebaixamento

## 1. Promoção

Ocorre quando o jogador satisfaz os requisitos de PL e vagas populacionais disponíveis na divisão superior, sendo efetivada imediatamente (D7–D3) ou consolidada no recálculo semanal (D2–D1).

## 2. Rebaixamento

O rebaixamento pode ocorrer por **duas razões distintas**:

1. **Perda de PL:** O PL cai abaixo do mínimo exigido pela divisão.


2. **Perda de Posição Relativa:** O jogador mantém seu PL, mas é ultrapassado por outros jogadores elegíveis, ficando fora da capacidade populacional máxima disponível na divisão (ex: caindo além dos 15% de capacidade da D2).



---

# Histórico Competitivo

O sistema armazena permanentemente o histórico de desempenho da conta: temporadas disputadas, maior divisão, recorde de PL, vitórias/derrotas, Planos de Campanha utilizados e recompensas.

---

# Regras Permanentes do Módulo

* O sistema competitivo possui **Modelo Individual** (Bronze) e **Modelo de Campanha** (Prata, Ouro, Diamante).


* **Limite por Conta:** Um jogador/conta pode participar de no **máximo duas Ligas simultâneas** na mesma temporada.
* Cada Comandante só pode participar de uma Liga por temporada.


* As divisões utilizam a nomenclatura **Divisão I a VII** (Divisão I sendo a mais forte).


* **Elegibilidade x Capacidade Independentes:** D1 e D2 possuem limites independentes (máximo 5% e máximo 15%, respectivamente). Vagas não utilizadas da D1 não são transferidas para a D2, e jogadores sem PL mínimo nunca preenchem vagas abertas.
* Jogadores com PL $\ge 5.000$ podem estar alocados na Divisão III caso excedam a capacidade da Divisão II.
* A atualização de PL individual é imediata; a consolidação oficial de vagas e cortes em Divisão I e II ocorre no **recálculo semanal**.


* A Patente do Comandante atua unicamente como consulta de elegibilidade para acesso à Liga.


* Ao final do ciclo de 4 semanas, o reposicionamento ocorre duas Divisões abaixo, iniciando exatamente na pontuação mínima dessa nova divisão.



---

# Referências

* **RESOURCES.md:** Tabela oficial de ganhos, VRG e recompensas por Liga e Divisão.


* **COMMANDERS.md:** Sistema de Patentes, progressão de XP e requisitos militares.


* **COMMAND_CENTER.md:** Configuração de Exércitos de Ataque e Defesa.


* **ENERGY.md:** Consumo de energia por combate.


* **GAME_PHILOSOPHY.md:** Princípios normativos da competição.


* **MATCHMAKING.md:** Algoritmos de busca e regras de fila.