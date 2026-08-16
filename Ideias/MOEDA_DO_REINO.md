# BATTLE SIMULATOR — DOCUMENTO DE DESIGN ECONÔMICO
## MOEDA DO REINO — ECONOMIC SYSTEM

**Status:** Fonte da Verdade (v0.9 Draft)  
**Projeto:** Battle Simulator  
**Objetivo:** Arquitetura & Implementação Futura  

---

### DIRETRIZ EDITORIAL DE IMPLEMENTAÇÃO
Este documento é a **Fonte da Verdade** para a arquitetura económica do jogo. Todos os componentes estão explicitamente categorizados por 4 status:
- `REGRA DEFINIDA`
- `PARÂMETRO PROVISÓRIO`
- `LACUNA A DEFINIR`
- `PRINCÍPIO DE BALANCEAMENTO`

---

## 1. OBJETIVO DA MOEDA DO REINO (`PRINCÍPIO DE BALANCEAMENTO`)

A Moeda do Reino (MR) é o principal recurso econômico estrutural do Reino, conectando gameplay, habilidade, progressão, produção de cartas, monetização e sinks permanentes de endgame.

A economia é construída sobre dois gargalos complementares:

### Moeda do Reino (MR)

- Principal gargalo econômico pretendido do jogador **Competitivo**.
- Obtida principalmente através do PvP competitivo, além de ranking, progressão e futuros mecanismos controlados.
- Utilizada na produção/fusão de cartas.
- Utilizada para liberar vagas de utilização dos sistemas de Legado no Centro de Comando.
- Possui múltiplos sinks permanentes e progressivos de endgame.

### Fragmentos

- Principal gargalo econômico pretendido do jogador **Hardcore**.
- Obtidos através de PvP e PvE.
- São específicos por facção.
- Necessários para a produção de cartas.
- Podem existir em volume superior à capacidade de conversão do jogador Competitivo.

### Perfis economicamente complementares

O objetivo arquitetural NÃO é fazer com que todos os jogadores tenham exatamente a mesma limitação econômica.

**Competitivo:**
- Referência de aproximadamente 25.000 MR gerados em uma temporada PvP de 4 semanas.
- Objetivo econômico de aproximadamente 30.000 MR de consumo em produção de cartas.
- Tende a possuir Fragmentos suficientes para sua capacidade de produção.
- Seu gargalo econômico pretendido é MR.

**Hardcore:**
- Referência de aproximadamente 50.000 MR gerados em uma temporada PvP de 4 semanas, distribuídos aproximadamente em:
  - 40.000 MR provenientes de vitórias;
  - 8.000 MR provenientes de posição;
  - 2.000 MR provenientes de melhoria de ranking.
- Jogadores excepcionais podem atingir aproximadamente 60.000 MR em temporadas muito fortes.
- Objetivo de aproximadamente 40.000 MR de consumo em produção de cartas.
- O consumo econômico total de referência é de aproximadamente 62.500 MR por temporada de 4 semanas.
- A diferença entre o consumo em cartas e o consumo econômico total deverá ser absorvida pelos demais sinks permanentes e progressivos da economia.
- Seu gargalo econômico pretendido é Fragmentos.
- Sua geração de MR não deve ser artificialmente reduzida apenas para impedir acúmulo de saldo.
- O excesso de MR deve ser absorvido por sinks profundos de endgame.

**Casual:**
- Possui menor volume de gameplay, geração e consumo.
- Deve sofrer menor pressão econômica estrutural.

### Princípio de complementaridade

A economia deve permitir que diferentes perfis produzam excedentes diferentes.

O Competitivo pode possuir excesso de Fragmentos e necessidade de MR.

O Hardcore pode possuir excesso de MR e necessidade de Fragmentos.

O futuro Marketplace poderá redistribuir esses excedentes entre jogadores.

O objetivo é criar especialização econômica e demanda real pelos dois recursos, e não tornar MR e Fragmentos igualmente limitantes para todos.

---

## 2. UNIDADE MONETÁRIA E ESCALA DA MR (`REGRA DEFINIDA`)

A taxa de conversão base da Moeda do Reino em relação ao Dólar Americano é fixa:

$$
\text{1 USD} = 1.000\text{ MR}
\quad\Big|\quad
\text{1 MR} = \text{US\$ 0,001}
$$

| QUANTIDADE DE MR | VALOR EM USD |
| :--- | :--- |
| **1 MR** | US$ 0,001 |
| **100 MR** | US$ 0,10 |
| **1.000 MR** | US$ 1,00 |
| **10.000 MR** | US$ 10,00 |

### Diretrizes de emissão

A emissão de MR não possui teto individual rígido.

A economia trabalha com faixas e valores médios calibráveis conforme população, desempenho e demanda econômica.

### Referências econômicas atuais (`PARÂMETRO DE BALANCEAMENTO`)

Para uma temporada PvP de 4 semanas:

**Hardcore:**
- aproximadamente 40.000 MR por vitórias;
- aproximadamente 8.000 MR por posição;
- aproximadamente 2.000 MR por melhoria de ranking;
- aproximadamente 50.000 MR no cenário de referência;
- aproximadamente 40.000 MR de consumo em produção de cartas;
- aproximadamente 62.500 MR de consumo econômico total no cenário central.

**Competitivo:**
- aproximadamente 25.000 MR no cenário de referência;
- aproximadamente 30.000 MR de consumo em produção de cartas.

Esses valores representam referências econômicas para balanceamento e não constituem teto rígido de emissão.

O cenário central de monetização atualmente adota, como hipótese de balanceamento, aproximadamente 80% de geração econômica através de gameplay e 20% de complementação através de compra.

Para o Hardcore de referência:

$$
50.000 / 0,80 = 62.500\ MR
$$

Assim, o cenário central considera aproximadamente 62.500 MR de consumo econômico total para um jogador que gere 50.000 MR através de gameplay.

Desse consumo total, aproximadamente 40.000 MR são destinados ao consumo de cartas. O restante deverá ser absorvido pelos demais sinks econômicos definidos no sistema.

A relação de 80% gameplay / 20% compra é uma hipótese de balanceamento atualmente adotada. Posteriormente poderão ser estudadas formas de reduzir a necessidade de complementação por compra sem comprometer os sinks necessários à economia.

### Regra de Conversão Unidirecional (`REGRA DEFINIDA`)

O fluxo de capital é estritamente:

$$
USD \rightarrow MR
$$

O jogo não realiza recompra de MR por moeda fiduciária.

---

## 3. RELAÇÃO COM DIAMANTES (`REGRA DEFINIDA`)

A MR não substitui e nem concorre diretamente com os Diamantes:
* **Diamantes:** Moeda de conveniência, aceleração e adiantamento de tempo (speed-ups, refills).
* **Moeda do Reino (MR):** Recurso econômico estrutural de alto valor ligado a cartas, PvP competitivo, torneios, progressão de endgame e ao marketplace.

---

## 4. MR COMO RECURSO ESTRUTURAL DE ENDGAME (`REGRA DEFINIDA`)

A MR não possui apenas função monetária ou de crafting.

Ela também funciona como recurso econômico de progressão e desbloqueio de capacidade permanente dentro do Reino.

No Centro de Comando, a MR será utilizada atualmente exclusivamente para liberar vagas de utilização dos sistemas de Legado.

A MR não é utilizada para evoluir o nível do Centro de Comando, ativar Cargos de Comando Ativo, ativar Vagas da Reserva ou adquirir outros Recursos Administrativos.

A Progressão Vertical e a Expansão Administrativa continuam utilizando os recursos definidos em `COMMAND_CENTER_PROGRESS.md`.

Outros sinks estruturais poderão ser adicionados futuramente sem alterar a separação entre MR e PG.

---

## 5. FONTES (FAUCETS) E CONSUMO (SINKS) DE MR (`REGRA DEFINIDA`)

| Fontes de Emissão (Faucets) | Fontes de Destruição (Sinks) |
| :--- | :--- |
| **Compra Direta:** USD → MR. | **Crafting:** custos de produção/fusão de cartas conforme Raridade + Tier. |
| **PvP Competitivo:** recompensas por vitórias. | **Cadeia Lendária:** MR em toda a cadeia conforme regra da temporada. |
| **Ranking:** recompensas de posição. | **Envelhecimento de Coleções:** expansão progressiva da cobrança de MR. |
| **Progressão / Atividade:** bônus econômicos controlados. | **Vagas de Legado:** pagamento de MR para liberar cada utilização de um sistema de Legado. |
| **Torneios Gratuitos:** mecanismo futuro de emissão controlada. | **Torneios Pagos:** queima de parte da taxa de inscrição. |
| **Outros eventos controlados:** conforme futura definição. | **Marketplace:** taxa de transação e queima. |

A MR utilizada para liberar uma vaga de Legado é permanentemente destruída da economia.

O objetivo é criar múltiplas camadas de consumo sem depender exclusivamente do aumento do custo individual das cartas.

---

## 6. SISTEMA DE CARTAS E MATRIZ DE CUSTOS DE CRAFTING (`REGRA DEFINIDA / PARÂMETRO DE BALANCEAMENTO`)

A fusão de cartas exige 3 cópias idênticas do Tier anterior para gerar 1 carta do Tier seguinte.

$$
3\text{ T1} \rightarrow 1\text{ T2}
\quad|\quad
3\text{ T2} \rightarrow 1\text{ T3}
\quad|\quad
3\text{ T3} \rightarrow 1\text{ T4}
\quad|\quad
3\text{ T4} \rightarrow 1\text{ T5}
$$

Para produzir 1 carta T5 são necessárias:

$$
81\text{ T1}
\rightarrow
27\text{ T2}
\rightarrow
9\text{ T3}
\rightarrow
3\text{ T4}
\rightarrow
1\text{ T5}
$$

### Matriz vigente de custos

Os valores abaixo representam o custo de MR de cada fusão individual naquele Tier.

| RARIDADE | TIER 1 | TIER 2 | TIER 3 | TIER 4 | TIER 5 |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Comum** | 1 MR | 3 MR | 10 MR | 30 MR | 100 MR |
| **Rara** | 3 MR | 8 MR | 25 MR | 80 MR | 250 MR |
| **Épica** | 6 MR | 15 MR | 60 MR | 200 MR | 600 MR |
| **Lendária** | 15 MR | 40 MR | 150 MR | 500 MR | 1.800 MR |

### Custo completo da cadeia T5

Quando toda a cadeia utiliza MR:

$$
Custo\ T5 =
81(T1) + 27(T2) + 9(T3) + 3(T4) + T5
$$

Aplicando a matriz vigente:

| RARIDADE | CUSTO COMPLETO DA CADEIA T5 |
| :--- | :---: |
| **Comum** | **442 MR** |
| **Rara** | **1.174 MR** |
| **Épica** | **2.631 MR** |
| **Lendária** | **6.945 MR** |

Esses valores são derivados matematicamente da matriz e não representam uma segunda matriz de preços.

### Regra de aplicação na temporada atual

Na primeira temporada em que uma facção/coleção estiver vigente:

- T5 de todas as raridades utiliza MR na fusão final.
- Lendárias utilizam MR em toda a cadeia, do T1 ao T5.
- Comuns, Raras e Épicas utilizam apenas Fragmentos nos Tiers T1 a T4.

### Meta econômica da Lendária T5

O custo completo da Lendária T5 deve permanecer aproximadamente na faixa:

**6.000–10.000 MR**

A matriz vigente representa a referência atual para simulação e poderá sofrer recalibração numérica durante o balanceamento.

---

## 7. REGRAS DE APLICAÇÃO DE MR E TEMPORADAS (`REGRA DEFINIDA`)

### Primeira temporada da coleção/facção

Na primeira temporada em que uma coleção/facção estiver disponível:

- T5 de Comum, Rara, Épica e Lendária consome MR;
- Lendária consome MR em toda a cadeia;
- Comum, Rara e Épica não consomem MR nos Tiers T1 a T4.

### Envelhecimento das coleções

A cobrança de MR se expande progressivamente para coleções antigas ao longo dos ciclos PvE.

A arquitetura de expansão permanece:

- Temporada N: T5 de Comum/Rara/Épica + cadeia completa Lendária;
- Temporada N+1: expansão da cobrança para a cadeia Épica da coleção passada;
- Temporada N+2: expansão para a cadeia Rara;
- Temporada N+3: expansão para a cadeia Comum.

### Inflação Sazonal (`REGRA DEFINIDA`)

Cartas que já estejam submetidas à cobrança de MR sofrem inflação composta de aproximadamente **5% por temporada**, com arredondamento para números inteiros.

Cartas que ainda não estejam submetidas à cobrança de MR não sofrem essa inflação.

---

## 8. MR E SISTEMA DE LEGADO — VAGAS DE UTILIZAÇÃO (`REGRA DEFINIDA`)

A MR é utilizada para liberar vagas de utilização dos sistemas de Legado do Centro de Comando.

O Centro de Comando determina quais tipos de Legado ficam disponíveis conforme os níveis e requisitos definidos em sua arquitetura própria.

A MR não desbloqueia os tipos de Legado.

A MR desbloqueia a **vaga necessária para colocar um Comandante em um Legado que já esteja disponível e para o qual o jogador possua os requisitos necessários**.

### Funcionamento

Quando o jogador possuir:

1. o tipo de Legado liberado pelo Centro de Comando;
2. os requisitos necessários para aquele Legado;
3. um Comandante elegível;

ele poderá abrir uma Vaga de Legado mediante pagamento em MR.

Depois de aberta a vaga, o jogador pode utilizar aquela vaga para qualquer tipo de Legado para o qual já esteja elegível.

A vaga não fica vinculada permanentemente ao tipo de Legado escolhido.

A próxima vaga de Legado terá custo superior à anterior, independentemente do tipo de Legado que será colocado nela.

Portanto:

$$
Custo(Vaga\ #1)
<
Custo(Vaga\ #2)
<
Custo(Vaga\ #3)
<
\dots
$$

A sequência econômica pertence à **ordem de abertura das vagas**, e não ao nível, tipo ou categoria do Legado.

### Liberdade estratégica

O jogador não é obrigado a utilizar uma vaga assim que se torna elegível para determinado Legado.

Ele pode:

- guardar MR;
- manter o Comandante elegível;
- acumular os recursos necessários;
- esperar;
- escolher posteriormente qual Legado utilizar em uma nova vaga.

Não existe desconto artificial por esperar.

O jogador simplesmente não abre a vaga enquanto não desejar realizar o investimento.

### Custo

Os valores nominais das vagas e a curva exata de crescimento ainda são parâmetros de balanceamento.

Não existe fórmula definida neste momento.

Os valores deverão ser determinados posteriormente com base nas simulações econômicas integradas.

### Limite de Grandes Legados Militares

Cada facção possui um limite de **8 Grandes Legados Militares** por jogador.

Portanto:

$$
8 \times \text{número de facções}
$$

define o número máximo de Grandes Legados Militares que um jogador pode realizar.

Com 3 facções:

$$
3 \times 8 = 24
$$

Grandes Legados Militares máximos.

Caso uma nova facção seja adicionada ao jogo, o limite total aumenta proporcionalmente em mais 8 Grandes Legados Militares.

O limite é, portanto, vinculado à quantidade de facções existentes, e não a um número universal fixo.

### Separação entre tipos de Legado e vagas

O número da vaga não representa o tipo do Legado.

Exemplo:

- Vaga #1 pode receber qualquer Legado para o qual o jogador já tenha os requisitos.
- Vaga #2 pode receber outro tipo de Legado.
- Vaga #3 pode receber qualquer outro Legado elegível.

A sequência de custo é sempre:

**Vaga #1 → Vaga #2 → Vaga #3 → ...**

e não:

**Legado I → Legado II → Legado III → ...**

A MR paga para abrir a vaga é permanentemente queimada.

---

## 9. MARKETPLACE E REDISTRIBUIÇÃO ECONÔMICA (`PRINCÍPIO DE BALANCEAMENTO`)

O Marketplace Futuro permitirá a redistribuição dos excedentes econômicos entre jogadores.

Poderão ser negociados, conforme as regras específicas que serão desenvolvidas posteriormente:

- Moeda do Reino (MR);
- Fragmentos;
- Cartas;
- Comandantes;
- outros recursos elegíveis.

### Função econômica

O Marketplace deve permitir que perfis economicamente complementares troquem seus excedentes.

**Competitivo:**
- tende a possuir excesso de Fragmentos;
- pode utilizar o Marketplace para obter MR.

**Hardcore:**
- tende a possuir excesso de MR;
- pode utilizar o Marketplace para obter Fragmentos.

O Marketplace não deve transformar MR e Fragmentos em recursos perfeitamente intercambiáveis por uma taxa fixa.

A relação entre oferta e demanda deverá determinar os valores de mercado.

### Taxa

A hipótese atual é aproximadamente **20% de taxa/queima**, mantida como parâmetro provisório.

Posteriormente poderão ser estudadas formas de reduzir essa taxa sem comprometer os sinks necessários à economia.

### Segurança

As regras técnicas contra:

- bots;
- multi-contas;
- transferências artificiais;
- manipulação de preços;
- farming;
- abuso de mercado;

serão definidas em especificação própria.

---

## 10. APLICAÇÕES DE ENDGAME: TORNEIOS E MARKETPLACE (`REGRA DEFINIDA`)

* **Torneios Pagos:** Entrada cobrada em MR. Do arrecadado, **~20% é queimado** definitivamente e 80% vai para o Prize Pool.
* **Marketplace Futuro:** Troca de cartas entre jogadores utilizando MR com **taxa de transação de ~20%** destinada à queima.

---

## 11. CHECKLIST DE BALANCEAMENTO E CALIBRAÇÃO

A arquitetura econômica está consolidada.

Os itens abaixo não representam novas decisões conceituais. São parâmetros que podem ser calibrados através de simulações sem alterar a arquitetura do sistema.

### Crafting

- [ ] Validar a matriz vigente de custos de crafting através das simulações.
- [ ] Validar o custo efetivo da Lendária T5.
- [ ] Validar o impacto da inflação sazonal de 5%.

### MR

- [ ] Validar a emissão média de aproximadamente 25k MR do Competitivo.
- [ ] Validar a referência de aproximadamente 40k MR por vitórias do Hardcore.
- [ ] Validar aproximadamente 8k por posição.
- [ ] Validar aproximadamente 2k por melhoria de ranking.
- [ ] Validar cenários Hardcore de 50k–60k MR.
- [ ] Validar o cenário de consumo de aproximadamente 30k MR em cartas para o Competitivo.
- [ ] Validar o cenário de consumo de aproximadamente 62,5k MR em cartas para o Hardcore.
- [ ] Validar a relação econômica aproximada de 80% gameplay / 20% compra.

### PvP

- [ ] Definir as faixas probabilísticas finais das recompensas por vitória.
- [ ] Validar as médias atuais:
  - Bronze D2 = 13 MR
  - Bronze D1 = 47 MR
  - Prata D2 = 23 MR
  - Prata D1 = 63 MR
  - Ouro D2 = 37 MR
  - Ouro D1 = 83 MR
  - Diamante D2 = 53 MR
  - Diamante D1 = 107 MR.
- [ ] Validar distribuição de MR entre vitórias, posição e melhoria de ranking.
- [ ] Validar critérios de elegibilidade e consistência.

### PvE e Fragmentos

- [ ] Validar volume real de partidas PvE.
- [ ] Validar recompensa PvE equivalente a aproximadamente 20% da recompensa PvP por partida.
- [ ] Validar a hipótese de simulação PvP + PvE ≈ 2,5 × Fragmentos PvP.
- [ ] Validar distribuição de Fragmentos por facção.
- [ ] Validar geração de Fragmentos por perfil.

### Legado

- [ ] Definir custo da Vaga de Legado #1.
- [ ] Definir custo da Vaga de Legado #2.
- [ ] Definir custos das vagas seguintes.
- [ ] Definir curva de crescimento das vagas.
- [ ] Validar impacto econômico das vagas de Legado sobre o consumo total de MR.
- [ ] Validar impacto econômico do limite de 8 Grandes Legados por facção.

### Marketplace

- [ ] Definir taxa definitiva de transação/queima.
- [ ] Definir mecanismos de proteção contra exploits.
- [ ] Definir regras de negociação de MR, Fragmentos, cartas e Comandantes.

### Torneios

- [ ] Definir calendário e emissão de Torneios Gratuitos.
- [ ] Validar taxa de queima dos Torneios Pagos.

### Monitoramento

- [ ] Monitorar MR emitida.
- [ ] Monitorar MR consumida.
- [ ] Monitorar MR queimada.
- [ ] Monitorar MR mantida em saldo.
- [ ] Monitorar Fragmentos por facção.
- [ ] Monitorar produção de cartas.
- [ ] Monitorar comportamento dos perfis Casual, Competitivo e Hardcore.

---

## 12. ROTEIRO DE PRÓXIMAS ETAPAS (`PRÓXIMA FASE`)

Com a arquitetura 90% consolidada, o trabalho sequencial de calibração deve seguir a ordem:

1. Definir a matriz definitiva de custos das cartas e simular a cadeia T1 $
ightarrow$ T5.
2. Ajustar o custo-alvo da Lendária T5 (faixa de ~7.500–8.000 MR).
3. Calibrar as recompensas PvP e simular o rendimento para 3 Comandantes ao longo de 4 semanas.
4. Simular perfis de jogadores (Casual, Competitivo Intermediário, Hardcore).
5. Modelar os pools de ranking por volume populacional e regras de elegibilidade.
6. Executar o modelo integrado de Emissão vs. Consumo (Faucets vs. Sinks).
7. Ajustar parâmetros finais e convertê-los em regras técnicas de implementação no código.
