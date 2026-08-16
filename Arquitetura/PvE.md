# PvE.md

# Sistema de Campanha Militar (PvE)

## Objetivo do Documento

Este documento define a arquitetura oficial e permanente do modo **PvE (Player vs Environment)** do Battle Simulator.

Ele estabelece a autoridade e a fonte única de verdade (*Single Source of Truth*) para:

* Estrutura e hierarquia territorial da Campanha Militar (Territórios, Trilhas, Regiões, Trechos, Fases e Batalhas);
* Fluxo operacional, natureza idle e sequência completa de uma Expedição;
* Conceito de Trechos de Expedição, funcionamento dos Squads e substituição automática de Exércitos;
* Hierarquia formal, filosofias de limitação e composição dos confrontos da Campanha;
* Estabelecimento, operação e regras de retomada em Acampamentos Avançados;
* Arquitetura de ramificação de Minas em territórios de conquista;
* Mecânica de progressão e enfrentamento de Chefes e Chefes Regionais;
* Sistema de submissão e Recrutamento de Comandantes de Campanha;
* Regras de Replay, recompensas em re-expedições e modelo de expansão permanente por Temporadas.

Este documento **não** define regras de Ranking PvP, limites de Tier, taxas de produção das minas, tabelas de experiência ou fórmulas de combate. Esses domínios pertencem estritamente aos seus respectivos documentos de arquitetura.

---

# Filosofia e Papel na Arquitetura

O modo PvE é estruturado como uma **Campanha Militar de Longo Prazo**. A fantasia central do sistema é a de um Reino expandindo suas fronteiras: conquistando Territórios hostis, estabelecendo Acampamentos avançados, assegurando fontes de recursos e submetendo Comandantes inimigos ao seu domínio.

## Princípios Fundamentais

* **Atividade Complementar:** O modo PvP (`RANKING.md`) permanece como a atividade principal e o motor central da evolução do Reino. O PvE atua como um suporte estratégico de longo prazo, fornecendo recursos e expansão.
* **Maratona Logística:** O avanço na Campanha não é apenas uma questão de poder bruto, mas de gestão de suprimentos (Energia) e organização de múltiplos Exércitos (Squads).
* **Travamento Intencional como Alavanca:** Por possuir combate determinístico, o travamento em uma Fase indica que a formação atingiu seu limite atual. A solução para o travamento exige refinar táticas, desenvolver Comandantes, evoluir cartas ou evoluir a economia do Reino através do ecossistema geral do jogo.

## Filosofia do Travamento

O combate do PvE é inteiramente determinístico. Se o jogador tentar avançar repetidamente sem alterar nada em sua formação ou força, obterá exatamente o mesmo resultado e permanecerá travado no mesmo ponto do Trecho de Expedição. Esse travamento é **proposital** e representa o limite atual da força militar do Reino.

O PvE não reduz a dificuldade, não rebaixa níveis nem cria mecanismos artificiais para superar o travamento. Em vez disso, o travamento direciona o jogador para as alavancas centrais do ecossistema do jogo:

* **Reorganização das formações:** Ajustar o posicionamento de unidades nas formações $\alpha, \beta, \gamma, \delta, \varepsilon$.
* **Utilização de outro Exército:** Trocar o Exército ativo ou liderar o Squad com outro Comandante que possua melhor sinergia contra as forças inimigas.
* **Evolução da coleção de cartas:** Obter e evoluir cartas através do ecossistema geral (especialmente via PvP).
* **Fortalecimento dos Comandantes:** Desenvolver e promover os Comandantes do Reino.
* **Investimento na Cidade:** Desenvolver construções e tecnologias que concedam bônus operacionais aos Exércitos.
* **Progressão em outras Trilhas:** Avançar em Trilhas paralelas enquanto a coleção do Reino se fortalece para superar o ponto de travamento.

## Exceção das Primeiras Fases

As **Fases 1 a 10 de toda Trilha** são a única exceção à Filosofia do Travamento: usam exclusivamente cartas de raridade **Comum**, sempre **Tier I**, para os inimigos das Fases Normais — nunca a faixa completa de Tier/Raridade da Região I aplicada ao restante da Região.

Essa exceção existe porque, nesse ponto inicial da jornada, o jogador ainda não tem nenhuma outra forma de conseguir Recursos além das próprias Fases do PvE — travar cedo demais, antes de qualquer alavanca do ecossistema estar acessível, não ensina nada, só frustra. A partir da Fase 11 de cada Trilha, a Filosofia do Travamento volta a valer integralmente, sem nenhuma outra exceção.

---

# Fluxo e Natureza da Expedição

A experiência operacional do PvE segue uma sequência clara e integrada que conecta a preparação na Cidade até a conclusão e re-exploração do território:

$$\text{Cidade} \longrightarrow \text{Montagem do Squad} \longrightarrow \text{Escolha do Território / Trilha} \longrightarrow \text{Início da Expedição} \longrightarrow \text{Combates Normais}$$

$$\downarrow$$

$$\text{Minas (Opcional)} \longrightarrow \text{Acampamentos} \longrightarrow \text{Chefes Normais} \longrightarrow \text{Chefe Regional} \longrightarrow \text{Novo Acampamento}$$

$$\downarrow$$

$$\text{Continuação da Campanha} \longrightarrow \text{Conclusão da Trilha} \longrightarrow \text{Replay}$$

1. **Cidade:** O jogador planeja suas forças, desenvolve construções e prepara seus Exércitos no Reino.
2. **Montagem do Squad:** Agrupamento dos Exércitos necessários para a Expedição conforme as exigências do estágio atual da Trilha (Campanha inicial ou Replay).
3. **Escolha do Território / Trilha:** Seleção da Trilha ativa no Território desejado para a marcha na Campanha.
4. **Início da Expedição:** Definição da marcha autônoma e avanço da força expedicionária.
5. **Combates Normais:** Sequência de confrontos determinísticos contra guarnições militares ao longo das Fases.
6. **Minas (Opcional):** Ramificações econômicas secundárias para onde o Squad pode desviar a fim de assegurar recursos.
7. **Acampamentos:** Consolidação de postos avançados que registram checkpoints permanentes e oferecem repouso logístico.
8. **Chefes Normais:** Confrontos táticos periódicos a cada 100 Fases contra Comandantes comuns.
9. **Chefe Regional:** Batalhas decisivas nas marcas de 1000, 2000 e 3000 Fases de cada Região contra Comandantes exclusivos.
10. **Novo Acampamento:** Consolidação do domínio sobre a província conquistada e reinício imediato do intervalo de marcha.
11. **Continuação da Campanha:** Progresso contínuo rumo às Fases, províncias e Regiões seguintes.
12. **Conclusão da Trilha:** Derrota do último Chefe Regional da Trilha, encerrando a Expedição principal do Território.
13. **Replay:** Re-expedição da Trilha com exigências ampliadas de composição do Squad para consolidar a soberania do Reino.

## Natureza Idle da Expedição

Após o jogador iniciar a Expedição, a marcha do Squad ocorre automaticamente. A força expedicionária progride pelas Fases da Trilha de forma totalmente autônoma. A marcha autônoma é interrompida exclusivamente por quatro eventos:

1. **Derrota:** Quando todas as formações de todos os Exércitos do Squad forem derrotadas.
2. **Esgotamento de Energia:** Quando a Energia de todos os Exércitos do Squad for totalmente consumida.
3. **Conclusão da Trilha:** Ao derrotar o último Chefe Regional da Trilha.
4. **Decisão do Jogador:** Interrupção voluntária ordenada pelo jogador no Reino.

## Diretrizes de Tempo de Simulação e Energia

* **Filosofia da Energia:** O verdadeiro limitador da velocidade de progressão da Campanha é a disponibilidade e gestão de Energia dos Exércitos (`ENERGY.md`), e não o tempo cronológico de execução das Fases.
* **Tempo de Simulação (Referência de Design):** Cada Fase possui uma referência visual de aproximadamente um minuto de simulação determinística. Esse valor serve apenas para dar uma percepção de marcha física e avanço da Expedição, não constituindo um mecanismo ou trava de progressão do jogo.

---

# Hierarquia Territorial da Campanha Militar

A Campanha é organizada em uma estrutura territorial rigorosa e de expansão horizontal permanente:

$$\text{Campanha} \longrightarrow \text{Territórios} \longrightarrow \text{Trilhas} \longrightarrow \text{Regiões} \longrightarrow \text{Trechos de Expedição} \longrightarrow \text{Fases} \longrightarrow \text{Confrontos}$$

## Diagrama da Hierarquia Territorial

```
Campanha
│
├── Território Império
│      └── Trilha (Império)
│             ├── Região I
│             ├── Região II
│             └── Região III
│
├── Território Natureza
│      └── Trilha (Natureza)
│             ├── Região I
│             ├── Região II
│             └── Região III
│
└── Território Mortos-Vivos
       └── Trilha (Mortos-Vivos)
              ├── Região I
              ├── Região II
              └── Região III

```

> **Nota de Expansão:** Temporadas futuras expandem a Campanha adicionando novos Territórios (e suas respectivas Trilhas), preservando integralmente essa estrutura.

## Definições Arquiteturais dos Níveis Territoriais

### 1. Território

Um **Território** representa uma grande frente militar pertencente a uma Facção específica no continente do jogo.

* Cada Território possui uma única Trilha associada.
* Os Territórios iniciais são **Império**, **Natureza** e **Mortos-Vivos**.
* Em temporadas futuras, novos Territórios serão adicionados à Campanha (crescimento horizontal), sem jamais substituir ou remover os Territórios existentes.

### 2. Trilha

A **Trilha** é a expressão operacional de um Território. Ela representa a campanha militar completa do Reino para subjugar a Facção daquele Território.

* Cada Trilha pertence a um único Território.
* Cada Trilha atravessa integralmente e sucessivamente todas as Regiões da Campanha.
* É composta por Fases, segmentada por Trechos de Expedição e contém Minas e Chefes.
* A conclusão de uma Trilha ocorre estritamente após a derrota de todos os Chefes Regionais existentes nela.

### 3. Região

A **Região** é um estágio geográfico de progressão comum a todas as Trilhas da Campanha.

* As Regiões não pertencem a um Território específico; todas as Trilhas atravessam as mesmas Regiões (Região I, Região II, Região III, etc.).
* Cada Região estabelece um patamar de dificuldade, nível de Tier dos inimigos e raridade das recompensas concedidas.
* O acesso à Região seguinte exige que o jogador conclua a Região atual em todas as Trilhas ativas.

### 4. Trecho de Expedição

Um **Trecho de Expedição** é o segmento de Fases compreendido entre dois Acampamentos consecutivos em uma Trilha.

---

# Estrutura das Regiões da Campanha

A progressão ao longo de qualquer Trilha atravessa Regiões bem delimitadas, escalando em desafio, complexidade e raridade de recompensas:

## Região I (Fases 1 a 3000 de cada Trilha)

* **Nível de Inimigos:** Formações inimigas utilizam níveis iniciais de Tier (referência: **Tier I** e **Tier II**).
* **Recompensas de Chefes:** A vitória sobre Chefes Normais concede cartas de raridade **Comum** pertencentes à Facção da Trilha.
* **Chefes Regionais:** Localizados nas Fases 1000, 2000 e 3000 da Trilha.

## Região II (Fases 3001 a 6000 de cada Trilha)

* **Nível de Inimigos:** Formações inimigas utilizam níveis intermediários de Tier (referência: **Tier III**, **Tier IV** e **Tier V**).
* **Recompensas de Chefes:** A vitória sobre Chefes Normais concede cartas de raridade **Rara** pertencentes à Facção da Trilha.
* **Chefes Regionais:** Localizados nas Fases 4000, 5000 e 6000 da Trilha (Fases 1000, 2000 e 3000 da Região II).

## Região III (Fases 6001 a 9000 de cada Trilha)

* **Nível de Inimigos:** Formações inimigas utilizam os níveis mais elevados de Tier disponíveis no sistema.
* **Recompensas de Chefes:** A vitória sobre Chefes Normais concede cartas de raridade **Épica** ou **Lendária** pertencentes à Facção da Trilha.
* **Chefes Regionais:** Localizados nas Fases 7000, 8000 e 9000 da Trilha (Fases 1000, 2000 e 3000 da Região III).

---

# Hierarquia e Composição dos Combates

## 1. Categorização dos Confrontos

Para garantir clareza arquitetural, todos os combates da Campanha enquadram-se estritamente em uma das quatro categorias abaixo:

| Categoria de Combate | Possui Comandante? | Origem do Comandante | Função e Características | Recompensas Especiais |
| --- | --- | --- | --- | --- |
| **Fases Normais** | Não | N/A | Guarnições militares regulares da província | Recursos e avanço na Trilha |
| **Minas** | Sim | Comandante Comum (Geração Padrão) | Guarnição de defesa do recurso econômico | Domínio sobre a Mina de recurso |
| **Chefes Normais** | Sim | Comandante Comum (Geração Padrão) | Encontros táticos sem mecânicas exclusivas | Cartas de Facção conforme a Região |
| **Chefes Regionais** | Sim | Comandante Exclusivo de Campanha | Personagem único e Senhor da Guerra da província | Novo Acampamento e Chance de Recrutamento |

## 2. Composição dos Exércitos Inimigos

As formações inimigas em todas as Trilhas da Campanha seguem uma regra estrutural de composição:

$$\text{Exército Inimigo} = 6 \text{ cartas da Facção do Território} + 3 \text{ cartas de uma Facção Secundária}$$

### Exemplos Ilustrativos de Composição:

* **Território do Império (Trilha Império):** 6 cartas do Império + 3 cartas da Natureza (ou 3 de Mortos-Vivos).
* **Território da Natureza (Trilha Natureza):** 6 cartas da Natureza + 3 cartas do Império (ou 3 de Mortos-Vivos).
* **Território dos Mortos-Vivos (Trilha Mortos-Vivos):** 6 cartas dos Mortos-Vivos + 3 cartas do Império (ou 3 da Natureza).

Essa regra garante consistência temática à Trilha, ao mesmo tempo que introduz variedade tática através do suporte da Facção secundária.

---

# Squads e Substituição de Exércitos

Para enfrentar as exigências de uma Expedição, o Reino mobiliza uma força organizada denominada **Squad**.

## Definições Estruturais

* **Exército:** Unidade tática fundamental liderada por 1 Comandante e composta por 9 cartas com suas 5 formações ($\alpha, \beta, \gamma, \delta, \varepsilon$).
* **Squad:** O agrupamento operacional de Exércitos alocado para marchar em uma Trilha. O Squad é formado pela quantidade de Exércitos exigida pelo estágio atual da Trilha (Campanha inicial ou Replay).
* **Propriedade da Energia:** A Energia pertence estritamente ao **Exército** e seus componentes (`ENERGY.md`), nunca ao Squad. O Squad funciona puramente como a estrutura organizacional da Expedição.

## Substituição Automática

A progressão do Squad pelo Trecho de Expedição ocorre autônoma e continuamente:

1. O primeiro Exército do Squad lidera a marcha e executa os confrontos.
2. Cada tentativa de formação ($\alpha$ a $\varepsilon$) consome Energia do Exército ativo (`ENERGY.md`).
3. Se um Exército tiver sua Energia esgotada **ou** se suas 5 formações forem derrotadas em uma mesma Fase, ele é considerado incapacitado.
4. O próximo Exército do Squad assume **imediatamente** e retoma a liderança na mesma Fase, sem perda de progresso.
5. Se todos os Exércitos do Squad forem incapacitados, a Expedição recua para o último **Acampamento**.

---

# Conceito de Trecho de Expedição e Acampamentos

## Trecho de Expedição

Um **Trecho de Expedição** é formalmente definido como a sequência de Fases compreendida entre dois Acampamentos consecutivos.

```
[ ACAMPAMENTO N ] ─── ( Trecho de Expedição: Progresso Temporário ) ───► [ ACAMPAMENTO N+1 ]

```

* **Progresso Temporário:** O avanço conquistado em Fases dentro de um Trecho é temporário até que o próximo Acampamento seja alcançado.
* **Progresso Permanente:** A chegada a um Acampamento consolida permanentemente o progresso do Reino até aquele ponto.
* **Isolamento por Derrota:** A falha do Squad reinicia apenas o Trecho de Expedição atual, recuando as forças para a base militar imediatamente anterior.

## Regras de Conquista e Retomada

1. **Bloqueio de Fases Conquistadas:** Quando um Acampamento é estabelecido, o Trecho de Expedição anterior é considerado definitivamente conquistado. Fases anteriores não podem ser revisitadas durante aquela Expedição, sendo proibido ao jogador retornar voluntariamente a Fases anteriores ao último Acampamento.
2. **Retomada por Derrota:** Caso todo o Squad seja incapacitado, ele recua para o Acampamento que inicia o Trecho atual. O Squad deve percorrer novamente todas as Fases do Trecho até a posição onde havia sido derrotado.

## Recompensas em Retomadas

> **Regra Permanente de Re-tentativas:** Quando um Squad refaz Fases de um Trecho de Expedição após recuar por incapacitação, nenhuma recompensa já obtida é concedida novamente. Isso aplica-se a Fases comuns, Minas já conquistadas e Chefes já derrotados. Essas batalhas servem exclusivamente para recuperar o progresso perdido da Expedição. Novas recompensas somente serão obtidas ao alcançar Fases inéditas ou ao iniciar um Replay completo da Trilha.

## Decisão Estratégica no Acampamento

Ao atingir ou recuar para um Acampamento, o jogador pode:

* **Continuar Imediatamente:** Retomar a marcha do Squad mesmo com Energia parcial dos Exércitos.
* **Permanecer em Repouso:** Aguardar a recuperação passiva de Energia antes de reordenar o avanço.

O sistema jamais obriga a recuperação completa de Energia para retomar a Expedição; a decisão de descanso é estritamente estratégica.

## Distância entre Acampamentos

A distância dos Trechos de Expedição aumenta conforme a penetração em territórios mais profundos:

* **Região I:**
* Fases 1 a 1500: Intervalos de **25 fases**.
* Fases 1501 a 3000: Intervalos de **30 fases**.


* **Região II:**
* Fases 3001 a 4500: Intervalos de **35 fases**.
* Fases 4501 a 6000: Intervalos de **40 fases**.


* **Região III:**
* Fases 6001 a 7500: Intervalos de **45 fases**.
* Fases 7501 a 9000: Intervalos de **50 fases**.



*Reinício de Contagem:* A derrota de um Chefe Regional estabelece um Acampamento imediato e reinicia a contagem de intervalo para o próximo Trecho.

---

# Minas (Ramificações Econômicas)

As Minas situam-se exclusivamente em caminhos secundários (ramificações laterais) e não fazem parte da sequência direta da Trilha.

$$\begin{array}{rcccl} \text{Trilha Principal:} & \text{Fase } N & \longrightarrow & \text{Fase } N+1 & \longrightarrow \text{Fase } N+2 \\ & & \searrow & & \\ \text{Ramificação Lateral:} & & & \text{[ MINA ]} & \end{array}$$

* **Avanço Livre:** A presença de uma Mina nunca bloqueia a Trilha principal; o jogador pode ignorá-la e continuar a marcha.
* **Conquista Opcional:** Caso desvie o Squad para a ramificação, o jogador enfrenta um Comandante comum e sua guarnição para assegurar a posse do local para o Reino.
* As regras de produção, guardas e evolução pertencem a `MINES.md`.

---

# Chefes e Chefes Regionais

## 1. Chefes Normais

Surgem a cada 100 Fases da Trilha. Utilizam Comandantes comuns e servem como testes táticos contínuos. A vitória concede cartas da Facção da Trilha de acordo com a raridade definida para aquela Região.

## 2. Chefes Regionais

Os Chefes Regionais são os governadores militares e Senhores da Guerra de províncias específicas.

### Distribuição na Campanha

Cada Região possui exatamente 3 Chefes Regionais em cada Trilha, posicionados nas Fases **1000, 2000 e 3000 da respectiva Região**. Assim, **cada Trilha possui exatamente 9 Chefes Regionais** distribuídos ao longo das três Regiões da Campanha:

* **Região I:** Fases 1000, 2000 e 3000 da Trilha.
* **Região II:** Fases 4000, 5000 e 6000 da Trilha.
* **Região III:** Fases 7000, 8000 e 9000 da Trilha.

### Impacto da Vitória

Os Chefes Regionais possuem Comandantes exclusivos e exércitos otimizados. A derrota de um Chefe Regional representa a conquista definitiva daquela província. O novo Acampamento criado imediatamente após a vitória simboliza a consolidação do domínio do Reino naquele território e marca o início da próxima ofensiva militar.

---

# Recrutamento de Comandantes de Campanha

Ao ser derrotado em uma marca de província (Fases 1000, 2000 ou 3000 de cada Região), ocorre o processo de submissão do Chefe Regional:

1. **Chance de Submissão:** O Chefe Regional possui **50% de chance** de reconhecer a superioridade militar do Reino e se oferecer para integrar as forças do jogador.
2. **Sucesso no Recrutamento:** O Comandante ingressa permanentemente na coleção de Comandantes do Reino (categoria PvE).
3. **Substituição pós-Recrutamento:** Uma vez recrutado, esse Comandante deixa de aparecer naquela Fase em futuros Replays. Ele é substituído permanentemente por um **Chefe Regional Genérico** de poder equivalente, garantindo a manutenção do desafio tático sem duplicar a entidade narrativa.
4. **Recusa:** Caso recuse (50%), o Comandante permanece defendendo a província até que uma nova vitória no Replay ative uma nova tentativa de recrutamento.

---

# Regras de Replay e Re-expedição

Concluída uma Trilha inteira (todas as suas Regiões), o Reino pode reiniciar a marchar por aquele Território através do sistema de **Replay**.

## Exigências Estritas de Composição de Squad

A quantidade de Exércitos exigida no Squad é fixa e não possui exceções:

* **Primeira Conclusão (Campanha Inicial):** Exige **obrigatoriamente 1 Exército** no Squad.
* **Primeiro Replay (Segundo Ciclo):** Exige **obrigatoriamente 2 Exércitos** no Squad.
* **Segundo Replay em Diante (Ciclos Avançados):** Exige **obrigatoriamente 3 Exércitos** no Squad.

---

# Parametrização e Expansão Futura

## Parametrização Permanente da Estrutura

Os seguintes elementos constituem a **arquitetura permanente do modo PvE**:

* **Regra de Território x Trilha:** Cada Território possui exatamente uma Trilha associada.
* **Atravessamento Regional:** Cada Trilha atravessa integralmente todas as Regiões da Campanha.
* **Consistência de Região:** Cada Região mantém sua organização interna, patamares de Tier e regras de recompensa em todas as Trilhas.
* **Composição Inimiga:** 6 cartas da Facção do Território + 3 cartas de Facção secundária.
* **Regra de Squad no Replay:** 1 Exército (Inicial) $\rightarrow$ 2 Exércitos (Replay 1) $\rightarrow$ 3 Exércitos (Replay 2+).

## Modelo de Expansão por Temporadas

A Campanha do Battle Simulator expande-se exclusivamente através do crescimento horizontal:

* As Trilhas e Territórios iniciais (**Império**, **Natureza** e **Mortos-Vivos**) permanecem permanentemente disponíveis no jogo;
* Novas temporadas adicionam **novos Territórios** e suas respectivas **Trilhas**;
* Não há substituição ou remoção de Territórios;
* Todas as futuras expansões e novas Trilhas seguem rigorosamente exatamente a mesma arquitetura territorial, mecânicas de Expedição, regras de Replay e estrutura de Regiões aqui estabelecidas.

---

# Regras Permanentes do Módulo

* O combate no PvE é determinístico; falhas consecutivas com a mesma composição gerarão os mesmos resultados até que haja mudança tática.
* O PvP permanece como o motor primário para aquisição de cartas e avanço competitivo.
* Minas situam-se em ramificações laterais e nunca interrompem a marcha principal.
* Fases Normais não possuem Comandantes; Minas e Chefes Normais utilizam Comandantes comuns; Chefes Regionais utilizam Comandantes exclusivos de Campanha.
* A Energia pertence ao Exército (`ENERGY.md`), não ao Squad.
* A retomada de marcha em um Acampamento não exige carga total de Energia dos Exércitos.
* Fases repetidas dentro de um mesmo Trecho de Expedição por incapacitação não concedem recompensas duplicadas.
* O recrutamento de Chefes Regionais possui 50% de chance por vitória e substitui o personagem por um genérico após recrutado.
* O dimensionamento do Squad no Replay é estrito: 1, 2 ou 3 Exércitos conforme o ciclo de conclusão da Trilha.

---

# Referências

* **RANKING.md:** Estrutura do ecossistema PvP e diretrizes competitivas.
* **ENERGY.md:** Regras de capacidade, consumo e taxas de recuperação de Energia dos Exércitos e Comandantes.
* **COMMANDERS.md:** Atributos, patentes e coleção de Comandantes.
* **COMMAND_CENTER.md:** Definição de Exércitos, Decks e gerenciamento de Squads.
* **MINES.md:** Regras de conquista, upgrade e produção passiva das Minas.
* **RESOURCES.md:** Tabela de conversão e taxas de obtenção de fragmentos e materiais.