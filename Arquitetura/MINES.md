# MINES.md

# Minas

## Propósito do Sistema

As Minas constituem a principal fonte passiva de recursos de construção da Cidade (Ferro Negro, Cristais Arcanos e Essência Vital).

Elas atuam como a ponte estratégica entre o PvE, a Cidade e a Economia global:

* **Conexão com o PvE:** Conquistadas exclusivamente ao derrotar formações defensoras nas trilhas regionais.
* **Conexão com a Cidade:** Alimentam diretamente a evolução das estruturas urbanas.
* **Conexão com a Economia:** Transformam permanentemente a eficiência dos exércitos do jogador em produção contínua e previsível de recursos.

As Minas operam uma economia paralela e independente da economia de fragmentos:

* **Fragmentos de cartas:** Obtidos em combate (PvP e PvE), utilizados na Academia.
* **Recursos de construção:** Obtidos nas Minas, utilizados na Cidade.

---

# Estrutura Permanente das Trilhas

Cada temporada possui 3 trilhas regionais de PvE. Existe uma associação fixa, permanente e imutável entre a trilha, a facção temática e o recurso produzido:

| Trilha | Facção | Recurso |
| --- | --- | --- |
| **Trilha 1** | Império | Ferro Negro |
| **Trilha 2** | Natureza | Essência Vital |
| **Trilha 3** | Mortos-Vivos | Cristais Arcanos |

Essa correspondência de recursos independe da temporada ou do conteúdo adicionado. Temporadas futuras podem expandir o número de regiões ou fases, mas a relação entre a trilha/facção e seu respectivo recurso de construção permanece inalterada.

---

# Distribuição das Minas

### Minas Regionais (Trilhas)

Cada uma das 3 trilhas contém **5 minas regionais**, distribuídas entre as suas 3 regiões:

* **Região I:** 2 minas
* **Região II:** 1 mina
* **Região III:** 2 minas

*(Totalizando 15 minas regionais no mapa global da temporada)*

### Mina Inicial (Bootstrap)

Existe exatamente **1 Mina Inicial para cada tipo de recurso**, integrando a arquitetura permanente do jogo e estando disponível desde o início da conta:

* **Propósito:** Introduzir o Sistema de Minas e fornecer a base econômica inicial do jogador.
* **Requisito:** Não exige exército defensor ou Guarnição da Mina.
* **Evolução:** Possui regras próprias de evolução, com nível máximo 4.
* **Progressão:** Geométrica (dobra a produção por nível: 1, 2, 4, 8 por hora).

A arquitetura permite que temporadas futuras adicionem novas regiões e minas sem modificar as regras gerais do sistema.

---

# Posicionamento, Localização e Propriedade

* **Posicionamento Lateral:** As minas ficam posicionadas lateralmente à trilha principal de PvE. Elas não bloqueiam nem interferem na progressão automática (idle) da trilha principal, exigindo deslocamento ativo do jogador para interagir com elas.
* **Determinação Procedural:** As posições exatas das minas no mapa são geradas proceduralmente para cada jogador. Cada conta possui uma distribuição geográfica própria que varia a cada temporada.
* **Uniformidade de Recurso:** A localização não altera a natureza do recurso. O recurso é determinado exclusivamente pela trilha à qual a mina pertence. Todas as minas de uma mesma trilha produzem exatamente o mesmo recurso.
* **Sem Raridades:** Não existem minas raras, especiais ou com propriedades exclusivas dentro de uma mesma trilha.
* **Propriedade Permanente:** Uma vez conquistada, uma mina passa a pertencer permanentemente ao jogador. Ela nunca retorna ao controle da IA, nunca precisa ser reconquistada e permanece disponível durante toda a vida da conta. Ao término de um Ciclo de Mineração, apenas sua produção é interrompida, sem qualquer perda de propriedade.

---

# Exército Defensor Inicial (IA)

Ao acessar uma mina pela primeira vez na trilha PvE:

1. O sistema gera automaticamente uma formação defensiva de IA.
2. Essa formação representa uma configuração intermediária de desafio para a região atual. Ela não corresponde necessariamente à combinação mais forte possível do exército defensor.
3. A formação defensiva gerada permanece fixa e inalterada até que o jogador a derrote e conquiste a mina.

---

# Fluxo do Ciclo de Mineração

O ciclo operacional completo de uma mina segue as seguintes etapas:

1. **Encontrar a mina:** Localizar a nó de mina lateral na trilha regional.
2. **Derrotar a formação defensora:** Vencer o combate inicial contra a IA.
3. **Conquistar a mina:** Garantir a posse permanente da estrutura.
4. **Escolher a Guarnição da Mina:** Selecionar o exército de guarnição da sua coleção.
5. **Iniciar o Ciclo de Mineração:** Ativar o ciclo operacional de 100 horas.
6. **Estimar a Eficiência da Guarnição:** O sistema amostra até $18.144$ batalhas ÚNICAS e VÁLIDAS, dentro do universo bruto de $362.880$ permutações possíveis, de forma incremental em 5 blocos (ver "Cálculo Incremental por Amostragem" abaixo) — nunca todas de uma vez, nunca instantâneo — convertendo o resultado acumulado (vitórias/empates/derrotas) na porcentagem de rendimento.
8. **Distribuir automaticamente os recursos:** Entregar a produção em parcelas diretas no Depósito ao longo de aproximadamente 100 horas.
9. **Encerrar o ciclo:** Interromper a produção ao atingir o tempo limite.
10. **Permitir nova ativação:** Liberar a mina para reinício com a mesma ou uma nova guarnição.

---

# Escolha da Guarnição da Mina e Congelamento de Estado

Após derrotar a formação defensiva da IA:

1. A mina é considerada **conquistada**.
2. O jogador deve obrigatoriamente designar uma **Guarnição da Mina** de sua própria coleção para ocupar a estrutura e iniciar a produção.
3. **Congelamento do Estado do Ciclo:** Quando um Ciclo de Mineração é iniciado, é criado um estado fixo imutável para aquele ciclo. Esse estado congela a Guarnição da Mina, o nível estrutural da mina e a produção base — a Eficiência, diferente dos demais, converge progressivamente ao longo das primeiras horas (ver "Cálculo Incremental por Amostragem"), nunca reajustada retroativamente depois de uma parcela horária já paga.
4. **Independência de Alterações:** A Guarnição da Mina permanece alocada e fixa durante todo o ciclo — **nunca pode ser trocada enquanto o ciclo estiver ativo**. Alterações posteriores na conta do jogador (melhorias de nível da estrutura ou modificações na coleção) não alteram um ciclo em andamento. Quaisquer evoluções somente produzem efeitos em ciclos iniciados posteriormente.
5. **Renovação:** Ao término do ciclo — nunca antes —, o jogador pode manter a mesma Guarnição da Mina ou selecionar uma nova composição:
   * **Renovação Automática (opcional):** se ativada, um novo Ciclo começa sozinho com a mesma Guarnição, sem exigir nenhuma ação do jogador.
   * **Renovação Manual (padrão):** o Ciclo termina e aguarda o jogador iniciar o próximo manualmente — nesse momento ele pode manter a mesma Guarnição ou escolher outra.
6. **Reaproveitamento de Eficiência:** Se a Guarnição selecionada para o novo Ciclo tem exatamente a mesma configuração relevante para o resultado de combate (mesmo Comandante com o mesmo XP acumulado, e as mesmas 9 cartas, na mesma ordem, com o mesmo Tier/atributos) que a Guarnição do Ciclo anterior, a Eficiência já calculada é reaproveitada diretamente — o sistema nunca recalcula as $18.144$ batalhas à toa só porque um novo Ciclo começou. Qualquer mudança relevante (Tier de uma carta, XP do Comandante, troca de carta/Comandante) invalida o reaproveitamento e força um novo cálculo.

---

# Ciclo de Mineração

O **Ciclo de Mineração** é a unidade operacional que rege o funcionamento de uma mina.

* **Combinações Simuladas:** O universo bruto de posicionamento possível entre a Guarnição da Mina do jogador e a Formação de Referência é de $9! = 362.880$ permutações. O Ciclo não simula todas elas — amostra até $18.144$ batalhas ÚNICAS e VÁLIDAS desse universo (ver "Cálculo Incremental por Amostragem"). "Única" nunca significa "permutação bruta única": a Máquina de Guerra sempre ocupa a Posição 9 na formação final de combate (seção 6.6, `COMBAT_RULES.md`), então múltiplas permutações brutas diferentes podem corresponder à mesma formação de combate efetiva — essas nunca contam duas vezes. "Válida" exclui qualquer formação em que um Suporte ocupe a Posição 5 (`COMBAT_RULES.md` 6.5, "Restrição de Posicionamento Inicial") — formações assim nunca entram na amostra.
* **Taxa de Execução Real:** As batalhas virtuais não seguem mais uma taxa conceitual fixa — a velocidade real depende de otimizações de engenharia (paralelização, geração de Log de Batalha desativada para simulação em massa) que evoluem ao longo do desenvolvimento. Ver "Cálculo Incremental por Amostragem" para o modelo atual.
* **Duração do Ciclo:** O ciclo possui uma duração de aproximadamente **100 horas** ($\approx 4{,}2$ dias).
* **Interrupção e Reinício:** Ao término das 100 horas, a produção da mina é interrompida. O jogador deve reativar o ciclo manualmente (individualmente ou em lote) para que a mina volte a produzir.

---

# Cálculo e Distribuição da Produção

## 1. Cálculo Incremental por Amostragem

Rodar as 362.880 permutações brutas de uma só vez, de verdade, levaria horas — inviável em tempo real. Em vez de calcular tudo de uma vez, o sistema amostra até **18.144 batalhas ÚNICAS e VÁLIDAS**, distribuídas em **exatamente 5 blocos** — nunca mais que isso, nunca rumo a um "bloco 6" ou a cobrir as 362.880 permutações brutas inteiras.

**"Única e válida", não "permutação bruta":** o alvo de 18.144 conta batalhas contra formações de combate efetivamente distintas e legais — nunca permutações brutas repetidas, nunca a mesma formação de combate duas vezes (a normalização da Máquina de Guerra para a Posição 9 pode fazer várias permutações brutas colapsarem na mesma formação final), e nunca uma formação com Suporte na Posição 5 (inválida, excluída antes de contar). Um bloco só se fecha depois de reunir sua cota de batalhas únicas e válidas — se o caminho até lá exigir examinar mais permutações brutas por causa de duplicatas/formações inválidas descartadas, o sistema continua buscando até atingir a cota (ou esgotar o universo bruto — ver abaixo).

**Distribuição exata dos 5 blocos:** $18.144 \div 5$ não é inteiro, então os blocos não são todos do mesmo tamanho — a divisão usa a mesma técnica de fronteiras por arredondamento em todo o projeto, resultando em **3.628, 3.629, 3.629, 3.629, 3.629** (soma exata: 18.144).

**Universo válido menor que o alvo:** se a Formação de Referência tiver, no total, menos de 18.144 formações efetivas únicas e válidas possíveis (ex: composições com muitos Suportes, que excluem uma fração maior das permutações), o sistema simula exatamente todas as que existem e para — nunca repete uma formação artificialmente só para tentar alcançar 18.144.

**Primeiro bloco (1ª hora) — velocidade alta, disfarçado na narrativa:** No instante em que o combate de conquista termina (o resultado já é conhecido), o sistema dispara o cálculo do 1º bloco usando mais poder de processamento (várias tarefas em paralelo). Esse tempo é coberto pela cena de conquista já prevista (vitória, mensagem do inimigo derrotado recusando-se a desistir) — o jogador nunca vê uma tela de carregamento genérica; o botão para prosseguir só aparece quando a cena **e** o cálculo do 1º bloco tiverem terminado, o que demorar mais.

**Blocos seguintes — em segundo plano, enquanto o jogador já está jogando:** o cálculo continua com menos poder de processamento (pra não pesar a máquina), somando amostra a cada bloco. Ao final do 5º bloco (ou antes, se o universo válido se esgotar primeiro), a amostra atinge alta confiança estatística (99% de confiança, margem de erro menor que 1%) e a **Eficiência é congelada para o resto do Ciclo** — nenhum bloco adicional é calculado depois disso.

**Pagamento nunca é reajustado retroativamente:** cada parcela horária é paga com a melhor estimativa de Eficiência disponível *naquele momento*. Enquanto a Eficiência ainda não é conhecida (janela entre o início do Ciclo e a conclusão do 1º bloco), a produção dessa janela fica pendente — nunca é paga com um valor desconhecido nem perdida — e é cobrada de uma vez assim que a primeira estimativa existir. Se uma estimativa inicial diferir ligeiramente do valor final mais preciso, essa diferença não é cobrada nem compensada depois.

## 2. Eficiência da Guarnição

O resultado do cálculo em lote determina a **Eficiência da Guarnição**:

| Resultado | Eficiência |
| --- | --- |
| **Vitória** | 100% |
| **Empate** | 50% |
| **Derrota** | 20% |

## 3. Produção Final

A produção por hora de uma mina é o produto de dois fatores independentes:

$$\text{Produção por Hora} = \text{Produção Base do Nível da Mina} \times \text{Eficiência da Guarnição}$$

A Produção Base depende exclusivamente da região da mina e do nível estrutural da mina. Esses valores permanecem centralizados em `FORMULAS.md`.

## 4. Distribuição Horária Automática

* A produção total calculada para o ciclo de 100 horas é dividida e entregue linearmente em parcelas a cada hora.
* A cada hora, aproximadamente **1% da produção total do ciclo** é creditada de forma automática e direta no Depósito correspondente da Cidade.
* **Sem Coleta Manual:** O jogador não precisa acessar a mina para recolher recursos acumulados; a transferência para o Depósito é passiva e automática até o término do ciclo.

---

# Gerenciamento de Múltiplas Minas

Conforme avança pelas trilhas, o jogador acumula diversas minas ativas simultaneamente. O gerenciamento pode ser feito de duas formas na interface:

* **Gerenciamento Individual:** Permite inspecionar uma mina específica, avaliar o tempo restante do ciclo, verificar o histórico do cálculo das até 18.144 batalhas únicas e válidas (vitórias/empates/derrotas) e trocar a Guarnição da Mina para o próximo ciclo.
* **Gerenciamento em Lote:** Facilidade que permite reativar simultaneamente todas as minas cujos ciclos tenham expirado, mantendo as Guarnições da Mina anteriormente designadas, sem a necessidade de acessar cada nó individualmente.

---

# Evolução da Estrutura das Minas

* **Recurso de Evolução:** As minas evoluem de nível de estrutura utilizando exclusivamente **Pontos de Geração (PG)**, um recurso global da conta (ver `FORMULAS.md`).


* **Sem Custo de Material:** A evolução do nível da mina **nunca consome** Ferro Negro, Cristais Arcanos ou Essência Vital.
* **Custos de Elevação:** As regras de custo em PG por nível e o escalonamento por regiões estão centralizados em `FORMULAS.md`.



---

# Integrações com Outros Sistemas

Para manter a separação de responsabilidades (SSoT), este documento rege estritamente a mecânica e operação do Sistema de Minas. Módulos correlatos devem ser consultados em seus respectivos documentos oficiais:

* **Regras de Combate e Formações:** `PVE.md` / `COMBAT.md`
* **Fórmulas Matemáticas, Produção Base e Custo em PG:** `FORMULAS.md`

* **Capacidade de Armazenamento e Recebimento:** `DEPOSITS.md`
* **Consumo e Aplicação dos Recursos:** `CITY.md`

---

# Regras Permanentes

* Minas **nunca consomem energia**.
* Minas **não bloqueiam** a progressão automática (idle) da trilha principal de PvE.
* A associação **Trilha/Facção $\rightarrow$ Recurso de Construção** é fixa e imutável em todas as temporadas.
* A propriedade de uma mina conquistada é permanente e nunca é perdida.
* A produção é o resultado da multiplicação de dois fatores independentes: **Nível da Mina $\times$ Eficiência da Guarnição**.
* O cálculo da Eficiência começa no início do Ciclo de Mineração e **converge de forma incremental**, em exatamente 5 blocos (até 18.144 batalhas únicas e válidas — ver "Cálculo Incremental por Amostragem") — o estado de produção congela progressivamente, não instantaneamente, mas nunca é reajustado retroativamente depois de uma parcela horária já ter sido paga.
* A Guarnição da Mina **nunca pode ser trocada durante um Ciclo ativo** — só entre Ciclos. Uma Eficiência já calculada é **reaproveitada** (sem novo cálculo) se a mesma configuração de Guarnição for usada de novo.
* A entrega dos recursos é **passiva e enviada de hora em hora** para o Depósito correspondente.
* A evolução da estrutura física da mina consome **exclusivamente Pontos de Geração**.