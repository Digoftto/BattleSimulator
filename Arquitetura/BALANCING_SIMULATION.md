# BALANCING_SIMULATION

# Objetivo

Este documento reúne simulações de referência usadas para calibrar valores do jogo (parâmetros de fórmulas, ritmo de progressão, viabilidade estrutural de conteúdo) a partir de um jogador hipotético e suas premissas explícitas.

Diferente dos demais documentos de arquitetura, este **não define regras de jogo**. Ele registra:

* O cenário e as premissas assumidas para cada simulação.
* Os cálculos e resultados obtidos.
* As consequências de design que a simulação revelou (o que é possível, o que trava, o que precisa de decisão).

Sempre que uma simulação exigir uma decisão de design (ex: como uma fórmula ainda não calibrada deve funcionar), essa decisão — uma vez tomada — é registrada aqui como premissa, e o valor oficial resultante (quando aplicável) é levado ao documento de regra correspondente (ex: `FORMULAS.md`). Este documento nunca substitui a SSOT de cada sistema — ele apenas simula com base nela.

Novas simulações são adicionadas como novas seções, sem remover as anteriores.

---

# Simulação 1 — Jogador Eficiente (100% de Vitória), 24h/dia de PvE

## Objetivo da Simulação

Calcular o ritmo real de progressão de um jogador hipotético que joga PvE continuamente (24h/dia), sempre vencendo, para:

* Entender a real disponibilidade operacional imposta pela Energia.
* Avaliar se a estrutura de Trechos de Expedição (`PvE.md`) é sempre atravessável.
* Calibrar a fórmula de custo de evolução do Núcleo de Energia (pendente em `FORMULAS.md`).
* Servir de base para futuras simulações (ex: recursos gerados por Trilha).

## Premissas Assumidas

> **⚠️ Correção posterior (ver Simulação 2):** a premissa 6 abaixo e a "Fórmula do Núcleo" logo depois desta lista partiram de um engano — o dono do projeto esclareceu depois que o Núcleo de Energia consome Recursos de Construção (como Capital, Academia e Centro de Comando), não Pontos de Geração. Quem não consome Recursos de Construção é o Depósito, não o Núcleo. Mantido abaixo sem alteração, como registro histórico de como o raciocínio evoluiu — a fórmula oficial vigente do Núcleo está em `FORMULAS.md` e na Simulação 2, não aqui.

Estas premissas foram definidas em conjunto com o dono do projeto especificamente para esta simulação — não são extraídas diretamente de nenhum documento, exceto onde indicado:

1. **Composição inicial do Exército ("energia mínima"):** Comandante Recruta (+20) + 9 cartas Tier I Comuns (+90) + Núcleo de Energia Nível 1 (Energia Base 40) = **150 de Energia Total** (`ENERGY.md`, exemplo ilustrativo).
2. **Vitória:** 100% das batalhas, sempre destruindo os 9 pelotões inimigos originais, sempre na Formação α (1 tentativa, 4 de Energia — `ENERGY.md`).
3. **Minas nunca consomem Energia** (`ENERGY.md`, regra explícita) — nem para atacar (conquistar), nem para defender.
4. **Cadência de jogo:** 1 minuto de simulação por tentativa (`PvE.md`, "Tempo de Simulação (Referência de Design)").
5. **Recuperação de Energia:** ocorre **exclusivamente** enquanto o Exército está parado em um Acampamento ou na Cidade (`ENERGY.md`) — nunca durante a marcha ativa entre Acampamentos. Consequência direta: se a Energia se esgotar no meio de um Trecho, o jogador retorna ao último Acampamento (esta consequência não afeta os cálculos desta simulação, pois o jogador sempre vence e nunca precisa recuar).
6. **Núcleo de Energia:** custo de evolução em blocos de 6 níveis (ver "Fórmula do Núcleo", abaixo) — decisão registrada nesta simulação e oficializada em `FORMULAS.md`.
7. **Pontos de Geração:** 1,3 PG/dia, **100% alocados ao Núcleo de Energia** nesta simulação (nenhum PG dividido com Depósitos, Capital, Centro de Comando ou Academia). Esta é uma simplificação desta simulação, não uma regra de alocação de PG do jogo.
8. **Liga de calibração de Fragmentos:** Bronze VII (`XP.md`, referência oficial de balanceamento).
9. **Raridade das 9 cartas do Exército:** Comum (VRP 50 Fragmentos — `RESOURCES.md`).
10. **Fragmentos utilizáveis para evoluir o Tier do Exército desta Trilha:** apenas os gerados pelos pelotões da Facção do Território (6 dos 9 pelotões inimigos — `RESOURCES.md`, "Independência Econômica por Facção"). Os Fragmentos da Facção secundária (3 dos 9 pelotões) acumulam separadamente, como excedente de outra economia.
11. **Patente e Tier evoluem uniformemente:** assume-se que os 9 slots do Exército evoluem de Tier em conjunto (não modela evoluir uma carta de cada vez).
12. **Condição alternativa de vitória (Turno 64, mais pelotões vivos):** registrada como existente no PvP e a ser adaptada por analogia ao PvE no futuro — **não utilizada nesta simulação**, que assume sempre vitória por eliminação total.

## Fórmula do Núcleo de Energia (decidida nesta simulação)

> **⚠️ Revertido — ver Simulação 2.** Esta subseção documenta uma decisão que foi corrigida depois: o Núcleo não usa PG, usa Recursos de Construção. Mantida como registro histórico.

O Núcleo de Energia usa uma fórmula própria, independente da Fórmula Geral de Construções (Capital/Academia/Centro de Comando) — decisão explícita do dono do projeto: *"Núcleo de energia tem uma fórmula à parte. Não segue as demais construções."*

Custo em PG por degrau de nível, em blocos de 6 (mesmo formato dos Depósitos, com blocos de 6 em vez de 4):

$$\text{Custo em PG}(n) = \left\lceil \frac{n}{6} \right\rceil$$

Custo acumulado do Nível 1 ao 60 (nível máximo, `ENERGY_NUCLEUS.md`): **329 PG**.

> Esta fórmula foi oficializada em `FORMULAS.md`, seção "Núcleo de Energia".

## Resultado 1 — Ritmo de Evolução do Núcleo (a 1,3 PG/dia, dedicação exclusiva)

| Núcleo Nível | PG acumulado | Dia aproximado |
|---:|---:|---:|
| 5 | 4 | 3 |
| 10 | 13 | 10 |
| 15 | 26 | 20 |
| 20 | 43 | 33 |
| 25 | 64 | 49 |
| 30 | 89 | 68 |
| 35 | 119 | 92 |
| 40 | 153 | 118 |
| 45 | 191 | 147 |
| 50 | 233 | 179 |
| 55 | 279 | 215 |
| 60 (máx) | 329 | 253 |

O Núcleo é, de longe, a mais lenta das três progressões simuladas — mais que uma Temporada inteira (180 dias) para o nível máximo.

## Resultado 2 — Fases/dia por Nível do Núcleo (recuperação só em Acampamento)

$$\text{Fases/dia} = \left\lfloor \frac{86400}{4 \times \text{segundos por ponto} + 60} \right\rfloor$$

| Núcleo Nível | Energia Total | Recuperação/ponto | Fases/dia |
|---:|---:|---:|---:|
| 1 | 150 | 450s | 46 |
| 5 | 151 | 438s | 47 |
| 10 | 152 | 426s | 48 |
| 15 | 153 | 414s | 50 |
| 20 | 154 | 402s | 51 |
| 25 | 155 | 390s | 53 |
| 30 | 156 | 378s | 54 |
| 35 | 157 | 370s | 56 |
| 40 | 158 | 360s | 57 |
| 45 | 159 | 350s | 59 |
| 50 | 160 | 340s | 60 |
| 55 | 161 | 330s | 62 |
| 60 | 162 | 326s | 63 |

## Resultado 3 — Progressão de Patente do Comandante

XP de Comandante no PvE = 30% do XP de vitória da Liga Bronze do PvP = 3 XP/vitória, qualquer categoria de combate (`XP.md`).

| Patente | XP necessário | Fases necessárias | Dia aproximado |
|---|---:|---:|---:|
| Capitão | 400 | 133 | 3 |
| Major | 1.200 | 400 | 9 |
| Coronel | 2.640 | 880 | 19 |
| General | 4.880 | 1.627 | 34 |
| Marechal | 8.080 | 2.693 | 54 |
| Lorde-Comandante (máx) | 12.480 | 4.160 | 81 |

## Resultado 4 — Progressão de Tier do Exército (via Fragmentos)

Fragmento por vitória PvE = 20% do valor do PvP, mesma liga/resultado (`RESOURCES.md`). Bronze VII Vitória = 10 Fragmentos/pelotão → PvE = 2 Fragmentos/pelotão.

6 pelotões da Facção do Território destruídos por vitória = **12 Fragmentos/Fase** utilizáveis para o Tier deste Exército.

Custo em cópias Tier I equivalentes por carta (`CARD_PROGRESSION.md`: 3 cópias do Tier anterior → 1 do Tier seguinte): Tier II = 3, III = 9, IV = 27, V = 81. Em Fragmentos (Comum, 50 cada), para as 9 cartas subirem juntas:

| Tier do Exército | Fragmentos totais | Fases necessárias | Dia aproximado |
|---|---:|---:|---:|
| II | 1.350 | 113 | 3 |
| III | 4.050 | 338 | 7 |
| IV | 12.150 | 1.013 | 20 |
| V (máx) | 36.450 | 3.038 | 61 |

Excedente acumulado de Fragmentos da Facção secundária (3 pelotões/vitória, 6 Fragmentos/Fase) no momento do Tier V: **~18.294** — moeda de outra Facção, não utilizável neste Exército.

## Resultado 5 — Viabilidade Estrutural dos Trechos de Expedição

Energia Total = Energia Base (Núcleo) + Energia da Patente + 9 × Energia por Carta (Tier).

Energia por Carta por Tier (`ENERGY.md`): I=10, II=11, III=12, IV=13, V=14.

Energia necessária por tamanho de Trecho (`PvE.md`, "Distância entre Acampamentos"): 4 × número de Fases do Trecho.

| Trecho | Tamanho | Energia necessária | Situação |
|---|---:|---:|---|
| Região I (toda) | 25 / 30 | 100 / 120 | Sempre viável |
| Região II, 1ª metade | 35 | 140 | Sempre viável |
| Região II, 2ª metade | 40 | 160 | Viável a partir de ~Dia 9 (Patente Major já basta, mesmo no Núcleo Nível 1) |
| Região III, 1ª metade (Fases 6001-7500) | 45 | 180 | Viável a partir de ~Dia 52-54 |
| Região III, 2ª metade (Fases 7501-9000) | 50 | 200 | Viável a partir de ~Dia 61 (exige Tier V) |

**Achado crítico:** sem considerar a evolução de Patente e Tier (só o Núcleo), a Região III, 2ª metade, seria **permanentemente inatingível** (o Núcleo sozinho chega no máximo a 192 de Energia Total, contra 200 necessários). A evolução de Patente e, principalmente, Tier (que sozinho leva a Energia por carta de 10 para 14) é o que destrava essa parte do jogo — não o Núcleo.

## Resultado 6 — Dia Aproximado de Chegada a Cada Mina

Usando o ritmo de Fases/dia por faixa de Núcleo (Resultado 2), aplicado ao longo da jornada:

| Mina (Fase) | Dia aproximado |
|---:|---:|
| 500 | 11 |
| 2000 | 41 |
| 4000 | 79 |
| 7000 | 133 |
| 9000 | 167 |

Todas as 5 Minas simuladas caem dentro de uma Temporada de 180 dias.

## Consequências e Observações de Design

* **O Núcleo de Energia não é o gargalo da Campanha.** Apesar de ser a progressão mais lenta em isolado (253 dias até o máximo), Patente e Tier evoluem rápido o bastante para destravar toda a Trilha muito antes disso.
* **A "energia mínima" (Recruta + Tier I) é insuficiente para completar a Trilha por conta própria** — mas não fica presa para sempre: as próprias mecânicas de progressão natural (XP de combate, Fragmentos de combate) resolvem isso organicamente, sem exigir nenhuma decisão extra do jogador além de continuar jogando.
* **O ritmo de PG assumido (1,3/dia) é bem mais lento que o de XP de Comandante e Fragmentos** — motivo pelo qual o Núcleo fica muito para trás das outras duas progressões nesta simulação.
* **Esta simulação assume 100% do PG dedicado ao Núcleo.** Na prática, o PG compete com Depósitos, Capital, Centro de Comando e Academia — o ritmo real do Núcleo tende a ser ainda mais lento que o calculado aqui.

---

# Simulação 2 — Produção de Recursos por Trilha e Calibração de `b`/`x`

## Objetivo da Simulação

Calcular o teto teórico de produção de Recursos de Construção (Ferro Negro/Cristais Arcanos/Essência Vital) por Trilha, a partir das Minas, e usar uma fatia realista desse total para calibrar os parâmetros `b`/`x` da Fórmula Geral de Construções (Capital, Academia, Centro de Comando e — após a correção acima — Núcleo de Energia).

## Etapa 1 — Teto Teórico de Produção por Trilha (180 dias, capacidade de Depósito infinita)

**Premissas desta etapa** (além das herdadas da Simulação 1):

* Alocação de PG entre as Minas de uma Trilha (Inicial + Regionais): **igualitária entre todas as Minas já conquistadas** naquele momento — quando uma nova Mina é conquistada, o PG passa a ser dividido entre mais uma.
* Guarnição da Mina com **100% de Eficiência** (jogador sempre vence as 362.880 combinações — mesmo espírito do "jogador 100% eficiente" da Simulação 1).
* Cada Mina tratada como se já estivesse no nível estrutural final calculado desde o início de sua atividade (não simula a subida gradual nível a nível) — **superestima ligeiramente o total**, de propósito: o objetivo aqui é o teto teórico, não o valor real.
* Capacidade de Depósito tratada como infinita nesta etapa — o resultado é produção bruta, antes de qualquer perda por transbordamento.

## Resultado — Nível Estrutural e Produção por Mina, ao final de 180 dias

| Mina | Região | Ativa desde (Dia) | Nível estrutural atingido | Produção/hora | Produção média/dia | Total bruto no período |
|---|---|---:|---:|---:|---:|---:|
| Inicial | — | 0 | 4 (máx) | 8 | 192 | 34.560 |
| 500 | I | 11 | 27 | 135 | 3.240 | 547.560 |
| 2000 | I | 41 | 22 | 110 | 2.640 | 366.960 |
| 4000 | II | 79 | 11 | 110 | 2.640 | 266.640 |
| 7000 | III | 133 | 4 | 80 | 1.920 | 90.240 |
| 9000 | III | 167 | 1 | 20 | 480 | 6.240 |

**Teto teórico por Trilha (180 dias): ≈ 1.312.200 unidades** do Recurso de Construção da Facção daquela Trilha.

## Etapa 2 — Valores de Referência Adotados pelo Dono do Projeto

O dono do projeto definiu valores de produção diária de referência por Região (mais conservadores que o teto teórico da Etapa 1, incorporando perdas reais de Depósito, ineficiências e tempo de conquista):

| Região | Recursos/dia (1 Trilha) | Recursos/dia (3 Trilhas) |
|---|---:|---:|
| I | 6.000 | 18.000 |
| II | 8.800 | 26.400 |
| III | 11.000 | 33.000 |

**Total de Recursos de Construção gerados por dia (3 Trilhas, 3 Regiões): 77.400/dia.**

## Etapa 3 — Orçamento Disponível para as 4 Construções Institucionais

* **40%** do total diário é destinado às 4 construções institucionais (Capital, Centro de Comando, Academia, Núcleo de Energia): **30.960/dia** (216.720/semana).
* Divisão por construção (decisão do dono do projeto — construções de nível finito recebem orçamento maior):

| Construção | % do orçamento | Recursos/dia | Recursos em 180 dias |
|---|---:|---:|---:|
| Capital | 20% | 6.192 | 1.114.560 |
| Centro de Comando | 15% | 4.644 | 835.920 |
| Academia | 30% | 9.288 | 1.671.840 |
| Núcleo de Energia | 35% | 10.836 | 1.950.480 |

## Etapa 4 — Calibração de `b` e `x` (histórico — superada pela Simulação 3)

> **⚠️ Superada.** Os valores de `x` abaixo foram substituídos por tentativa e erro manual na Simulação 3, logo depois desta. Mantida como registro histórico — **não é mais o par vigente**. O par vigente está sempre na Simulação mais recente marcada como "VIGENTE" neste documento.

**Meta (revisada):** cada uma das 4 construções atinge aproximadamente o **Nível 10** aos **180 dias**, gastando seu orçamento acumulado do período inteiro, com **`b = 50` fixado** para dar peso real ao custo dos primeiros níveis (decisão do dono do projeto — meta original era Nível 18 com `b=0`, revisada nesta simulação).

`b = 50` foi escolhido diretamente pelo dono do projeto, não calculado — só `x` é resolvido a partir do orçamento de 180 dias, dado esse `b`.

Fórmula: $C(n) = 20 \times (50 + n^2 + xn)$. Custo acumulado do Nível 1 (gratuito, ponto de partida) ao Nível 10: $20 \times (9 \times 50 + 384) + 20x \times 54 = 16.680 + 1.080x$.

| Construção | Orçamento em 180 dias | `b` | `x` (histórico, superado) |
|---|---:|---:|---:|
| Capital | 1.114.560 | 50 | ≈ 1.016,6 |
| Centro de Comando | 835.920 | 50 | ≈ 758,6 |
| Academia | 1.671.840 | 50 | ≈ 1.532,6 |
| Núcleo de Energia | 1.950.480 | 50 | ≈ 1.790,6 |

## Consequências e Observações de Design (Simulação 2)

* **A produção real (Etapa 2) é bem menor que o teto teórico (Etapa 1)** — 77.400/dia contra um teto de ~1.312.200/180dias ≈ 7.290/dia só de uma Trilha (~21.870/dia nas 3 Trilhas somadas, considerando as 3 Facções). O valor adotado pelo dono do projeto já incorpora essa margem de segurança conscientemente.
* **Alocação de PG: 80% Minas / 20% Depósito** (decisão do dono do projeto, substituindo a divisão anterior com o Núcleo — já corrigida). As Minas mantêm exatamente os níveis e produção já calculados na Etapa 1 (nenhuma mudança, os 80% são os mesmos). Os 20% restantes (~0,26 PG/dia) vão para o Depósito — **nota de correção:** no momento deste cálculo, o Depósito ainda era modelado como 3 construções separadas (dividiu-se o orçamento em 3); o dono do projeto corrigiu depois que existe apenas 1 Depósito, com 1 nível só, armazenando os 3 recursos simultaneamente (`DEPOSITS.md`). Com essa correção, os ~0,26 PG/dia inteiros vão para esse único nível, sem dividir por 3 — o resultado desta etapa (Nível 9 por Depósito) está desatualizado; o valor correto seria mais alto (~Nível 17, todo o orçamento concentrado). **Bloqueio que continua de pé:** `DEPOSITS.md` só define capacidade de armazenamento até o Nível 3 — não é possível calcular quanto dessa produção fica retida de verdade (vs. perdida por transbordamento) além disso, sem a fórmula de capacidade do Nível 4+.
* **A alocação de PG é tratada aqui como se cada Trilha tivesse seu próprio orçamento de 1,3 PG/dia**, para manter consistência com os valores de produção "por Trilha" já adotados (Etapa 2). Isso é uma simplificação de modelagem: `FORMULAS.md`/`XP.md` descrevem Pontos de Geração como um recurso único e global do Reino, não um orçamento por Trilha. Se as 3 Trilhas competem pelo mesmo 1,3 PG/dia (não 1,3 cada), os níveis calculados nesta simulação ficam otimistas por um fator de até 3x.
* **`b = 50` para as 4 construções foi uma escolha direta do dono do projeto**, para dar peso real ao custo dos primeiros níveis (a versão anterior desta simulação usava `b=0` e meta de Nível 18 — revisado para Nível 10 com este `b`). O custo do primeiro degrau (Nível 1→2) ficou entre 3x e 3,3x mais caro que na versão `b=0`.
* **Ainda pendente:** a proporção exata entre Fundamento Principal/Secundário dentro da Assinatura Econômica de cada construção (`FORMULAS.md`) — sabemos qual recurso é Principal/Secundário (`CITY.md`), mas não a proporção numérica entre eles.

---

# Simulação 3 — Calibração Manual de `b`/`x` por Tentativa e Erro (VIGENTE)

## Objetivo da Simulação

Ajustar manualmente os valores de `x` (com `b=50` fixo, mantido da Simulação 2) para as 4 construções institucionais, e observar o custo acumulado e o dia estimado de cada nível, de 1 a 20 — insumo direto para decidir se a curva "sente" certo, por tentativa e erro.

## Premissas

* Herda o orçamento diário por construção da Simulação 2, Etapa 3 (40% dos Recursos de Construção gerados pelas Minas, dividido 20%/15%/30%/35% entre Capital/Centro de Comando/Academia/Núcleo de Energia): 6.192 / 4.644 / 9.288 / 10.836 por dia, respectivamente.
* `b = 50` para as 4 (mantido da Simulação 2).
* `x` escolhido manualmente pelo dono do projeto (não resolvido a partir de uma meta de nível/dia — o processo é o inverso: escolhe-se `x`, observa-se o resultado, ajusta-se de novo):

| Construção | `b` | `x` |
|---|---:|---:|
| **Capital** | **50** | **300** |
| **Centro de Comando** | **50** | **225** |
| **Academia** | **50** | **460** |
| **Núcleo de Energia** | **50** | **530** |

> ## ✅ VALORES VIGENTES
> Este é o par de `b`/`x` **oficialmente válido no momento**, referenciado por `FORMULAS.md`, `CAPITAL.md`, `ACADEMY.md`, `COMMAND_CENTER_PROGRESS.md` e `ENERGY_NUCLEUS.md`. Toda simulação futura que testar outros valores de `b`/`x` deve ser adicionada como uma nova seção abaixo, preservando esta — e deve marcar explicitamente qual passa a ser o novo vigente, atualizando este aviso.

Fórmula: $C(n) = 20 \times (50 + n^2 + xn)$.

## Resultado — Custo Acumulado e Dia Estimado, Nível 1 a 20

| Nível | Capital (6.192/dia) | Centro de Comando (4.644/dia) | Academia (9.288/dia) | Núcleo de Energia (10.836/dia) |
|---:|---:|---:|---:|---:|
| 2 | 13.080 / dia 2,1 | 10.080 / dia 2,2 | 19.480 / dia 2,1 | 22.280 / dia 2,1 |
| 3 | 32.260 / dia 5,2 | 24.760 / dia 5,3 | 48.260 / dia 5,2 | 55.260 / dia 5,1 |
| 4 | 57.580 / dia 9,3 | 44.080 / dia 9,5 | 86.380 / dia 9,3 | 98.980 / dia 9,1 |
| 5 | 89.080 / dia 14,4 | 68.080 / dia 14,7 | 133.880 / dia 14,4 | 153.480 / dia 14,2 |
| 6 | 126.800 / dia 20,5 | 96.800 / dia 20,8 | 190.800 / dia 20,5 | 218.800 / dia 20,2 |
| 7 | 170.780 / dia 27,6 | 130.280 / dia 28,1 | 257.180 / dia 27,7 | 294.980 / dia 27,2 |
| 8 | 221.060 / dia 35,7 | 168.560 / dia 36,3 | 333.060 / dia 35,9 | 382.060 / dia 35,3 |
| 9 | 277.680 / dia 44,8 | 211.680 / dia 45,6 | 418.480 / dia 45,1 | 480.080 / dia 44,3 |
| 10 | 340.680 / dia 55,0 | 259.680 / dia 55,9 | 513.480 / dia 55,3 | 589.080 / dia 54,4 |
| 11 | 410.100 / dia 66,2 | 312.600 / dia 67,3 | 618.100 / dia 66,5 | 709.100 / dia 65,4 |
| 12 | 485.980 / dia 78,5 | 370.480 / dia 79,8 | 732.380 / dia 78,9 | 840.180 / dia 77,5 |
| 13 | 568.360 / dia 91,8 | 433.360 / dia 93,3 | 856.360 / dia 92,2 | 982.360 / dia 90,7 |
| 14 | 657.280 / dia 106,1 | 501.280 / dia 107,9 | 990.080 / dia 106,6 | 1.135.680 / dia 104,8 |
| 15 | 752.780 / dia 121,6 | 574.280 / dia 123,7 | 1.133.580 / dia 122,0 | 1.300.180 / dia 120,0 |
| 16 | 854.900 / dia 138,1 | 652.400 / dia 140,5 | 1.286.900 / dia 138,6 | 1.475.900 / dia 136,2 |
| 17 | 963.680 / dia 155,6 | 735.680 / dia 158,4 | 1.450.080 / dia 156,1 | 1.662.880 / dia 153,5 |
| 18 | 1.079.160 / dia 174,3 | 824.160 / dia 177,5 | 1.623.160 / dia 174,8 | 1.861.160 / dia 171,8 |
| 19 | 1.201.380 / dia 194,0 | 917.880 / dia 197,6 | 1.806.180 / dia 194,5 | 2.070.780 / dia 191,1 |
| 20 | 1.330.380 / dia 214,9 | 1.016.880 / dia 219,0 | 1.999.180 / dia 215,2 | 2.291.780 / dia 211,5 |

## Consequências e Observações de Design

* As 4 construções chegam ao Nível 20 num intervalo apertado (dia 211 a 219), apesar de orçamentos diários bem diferentes — os `x` escolhidos mantiveram uma proporção parecida com a dos orçamentos.
* Nível 10 (meta anterior da Simulação 2) cai entre os dias 54 e 56 para todas; Nível 18 entre os dias 174 e 178.
* Estes valores não foram resolvidos a partir de uma meta — foram escolhidos diretamente e testados. Ajustes futuros de `x` (ou `b`) devem virar uma nova seção "Simulação 4" (e assim por diante), preservando esta.

---

# Simulação 4 — Correção do Pool Global de PG (FASE 21.3.2)

## Objetivo da Simulação

A Simulação 2 (Etapa 2, "Consequências e Observações de Design") já registrava, como limitação conhecida e não corrigida: *"a alocação de PG é tratada aqui como se cada Trilha tivesse seu próprio orçamento de 1,3 PG/dia... se as 3 Trilhas competem pelo mesmo 1,3 PG/dia (não 1,3 cada), os níveis calculados nesta simulação ficam otimistas por um fator de até 3x."* `GENERATION_POINTS.md` confirma: PG é um único recurso global do Reino, nunca um orçamento por Trilha. A auditoria da FASE 21 (item C.10) reabriu esse ponto explicitamente. Esta simulação refaz a Etapa 1 da Simulação 2 com essa correção, e propaga o impacto para os orçamentos das Construções Institucionais (Simulação 2/3).

Esta correção também é habilitada, pela primeira vez, pela FASE 21.3.1: antes dela, `MineEvolutionResolver` recusava qualquer evolução de Mina Regional — os níveis "atingidos" na Simulação 2/Etapa 1 (Mina 500 no Nível 27, por exemplo) eram, até esta fase, **matematicamente simulados mas impossíveis de alcançar em jogo**. A generalização do resolver torna esses números finalmente reais, o que torna a correção do pool de PG abaixo relevante de verdade (não apenas teórica).

## Método

Reaproveita exatamente o cronograma de conquista de Minas da Simulação 2/Etapa 1 (mesmos dias de conquista, mesma regra "PG dividido igualmente entre as Minas já conquistadas daquela Trilha") e as mesmas fórmulas reais de código (`MineEconomy.upgrade_cost_pg()`/`base_production_per_hour()`), mas com uma simulação dia-a-dia (acúmulo incremental de PG por Mina, evoluindo assim que o custo do próximo nível é atingido) em vez do método de cálculo da Etapa 1 original (não documentado passo-a-passo). **Nota de transparência:** essa diferença de método reproduz a Mina "500" no Nível 31 (não 27) para o cenário "1,3 PG/dia dedicados a 1 Trilha" — uma diferença de ~13% em relação ao número já publicado na Simulação 2, atribuível ao método de acúmulo dia-a-dia aqui usado vs. o método original (não documentado). Não invalida a correção proposta abaixo, que depende das **proporções relativas** entre cenários, não do valor absoluto de um método específico.

Três cenários de alocação do único pool global (1,3 PG/dia, `Arquitetura/FORMULAS.md`, "Progressão da Conta"), refletindo como um jogador real provavelmente distribui PG entre até 3 Trilhas simultâneas:

| Cenário | PG/dia efetivo para ESTA Trilha | Interpretação |
|---|---:|---|
| Conservador | 0,433 (1,3 ÷ 3) | Jogador progride as 3 Trilhas ao mesmo tempo, dividindo igualmente |
| Médio | 0,65 (1,3 ÷ 2) | Jogador foca 2 das 3 Trilhas por vez |
| Acelerado | 1,3 (1,3 ÷ 1) | Jogador foca 1 Trilha por vez (idêntico à premissa original da Simulação 2) |

## Resultado — Produção de Recursos de Construção por Trilha, aos 180 dias

| Cenário | Produção/dia desta Trilha | % do valor assumido pela Simulação 2 |
|---|---:|---:|
| Conservador | 6.312 | 50,8% |
| Médio | 7.992 | 64,3% |
| Acelerado (= premissa original) | 12.432 | 100% |

**Achado central:** mesmo no cenário mais otimista de foco total numa única Trilha por vez ("Acelerado"), o valor bate com a Simulação 2 apenas porque essa é exatamente a mesma premissa (foco exclusivo). Qualquer jogador que realmente progrida em mais de uma Trilha ao mesmo tempo — o comportamento mais provável, já que o World Map Gate expõe as 3 Trilhas desde o início — produz **metade a dois terços** dos Recursos de Construção que a Simulação 2/Etapa 2 assumiu ao derivar o total de 77.400/dia e os orçamentos das 4 Construções Institucionais.

## Impacto no Payback das Construções Institucionais (Simulação 3, valores `b`/`x` VIGENTES)

Como o custo acumulado de cada nível é fixo (`C(n) = 20×(50+n²+xn)`, `b`/`x` inalterados) e o "dia estimado" é `custo acumulado ÷ orçamento diário`, o dia estimado escala linearmente com o inverso da razão de produção acima (Conservador: ×1,969; Médio: ×1,555):

| Nível | Capital (vigente) | Capital (Conservador) | Capital (Médio) | Núcleo de Energia (vigente) | Núcleo (Conservador) | Núcleo (Médio) |
|---:|---:|---:|---:|---:|---:|---:|
| 10 | dia 55,0 | dia 108,3 | dia 85,5 | dia 54,4 | dia 107,1 | dia 84,6 |
| 15 | dia 121,6 | dia 239,4 | dia 189,1 | dia 120,0 | dia 236,3 | dia 186,6 |
| 20 | dia 214,9 | dia 423,1 | dia 334,2 | dia 211,5 | dia 416,4 | dia 328,9 |

(Centro de Comando e Academia escalam pela mesma razão — omitidos por brevidade, mesma conclusão.)

**Consequência:** sob o cenário Conservador (o mais realista para um jogador que já usa o World Map Gate para alternar entre Trilhas, comportamento que o próprio jogo incentiva), nenhuma das 4 Construções Institucionais atinge o Nível 15 dentro de uma única Temporada de 180 dias (MINES.md/SEASONS.md) — o Nível 15 só chega por volta do dia 236-240, quase uma Temporada e meia depois. Mesmo no cenário Médio, o Nível 15 (dia ~187-192) ultrapassa ligeiramente os 180 dias da Temporada.

## Decisão necessária (não aplicada nesta auditoria)

Esta simulação **não altera** `b`/`x` nem qualquer valor vigente — apenas quantifica o efeito de uma premissa que já estava sinalizada como incorreta. Três caminhos possíveis, cada um uma decisão de design genuína (nenhum foi escolhido aqui):

1. **Aceitar o ritmo mais lento** como o real ritmo do MVP (Temporada de 180 dias não é "terminar todas as Construções no Nível 20", e sim "progredir de forma plausível") — nenhuma mudança de valor necessária, só uma expectativa realista a comunicar (ex: tutorial/UI) em vez de mudar números.
2. **Recalibrar `x`** das 4 Construções Institucionais para baixo, usando o orçamento corrigido (Conservador ou Médio) como nova base — impacto direto em `FORMULAS.md`/`CAPITAL.md`/`ACADEMY.md`/`COMMAND_CENTER_PROGRESS.md`/`ENERGY_NUCLEUS.md`, e exigiria uma nova rodada de "tentativa e erro" como a Simulação 3 fez.
3. **Revisar a divisão de PG entre Minas e Depósito** (hoje 80%/20%, Simulação 2) ou entre Trilhas — mudança de comportamento esperado do jogador, não de fórmula.

**DECISÃO DO USUÁRIO NECESSÁRIA** antes de qualquer uma das três. Nenhuma foi aplicada.

---

# Simulação 5 — Curva de Entrada das Construções Institucionais (Níveis 1–3) — FASE 22, ✅ VALORES VIGENTES (Cenário B aprovado e implementado)

## Situação atual

A auditoria da FASE 22 (Editor de Exército + economia inicial) simulou um
jogador NOVO — só as 3 Minas Iniciais (Império/Natureza/Mortos-Vivos),
sem nenhuma Mina Regional — usando exclusivamente código real
(`MineEconomy`, `Deposits`, `GeneralConstructionFormula`,
`InstitutionalConstructionConfig`, nenhuma fórmula reimplementada) e as
mesmas premissas de PG/alocação já registradas nas Simulações 2-4 (PG =
1,3/dia, 80% Minas/20% Depósito, 40% das Minas Iniciais → Construções
Institucionais, 20/15/30/35% entre Capital/Centro de Comando/Academia/
Núcleo de Energia).

**Achado:** com os valores `b`/`x` vigentes (Simulação 3), as 3 Minas
Iniciais maximizam (Nível 4, `MINES.md`) por volta do Dia 14, gerando
~576 Recursos de Construção/dia no total. O orçamento diário resultante
para cada Construção fica entre ~35 e ~81 Recursos/dia — nenhuma das 4
atinge o Nível 2 antes de aproximadamente o **Dia 282-298**. Testar
cortar custo (-20%) ou dobrar a produção da Mina Inicial isoladamente
não muda esse resultado de forma perceptível: o problema não é o valor
de um parâmetro, é uma diferença de escala de ~135-235× entre o
orçamento que uma economia "só Mina Inicial" consegue gerar e o
orçamento (3 Trilhas, Minas Regionais já conquistadas) para o qual
`b`/`x` foram calibrados.

## Problema identificado

Com a curva vigente, um jogador novo nunca vê nenhuma das 4 Construções
Institucionais sair do Nível 1 antes de conquistar Minas Regionais — o
que pode levar semanas. Isso contraria a intenção de design: a Mina
Inicial deveria funcionar como uma "plataforma de progressão inicial",
dando ao jogador uma sensação real de evolução da Cidade enquanto ele
ainda está descobrindo o mapa e buscando as primeiras Regionais.

## Metodologia

Simulação dia-a-dia (script descartável, removido após uso — nenhum
valor oficial foi alterado por ele) testando a hipótese específica
pedida: **custo artificialmente reduzido só para atingir os Níveis 2 e
3; a partir do Nível 4, retorno integral à curva vigente** (nunca uma
segunda fonte de verdade — o Nível 4+ sempre usa
`GeneralConstructionFormula.upgrade_cost()` com o `b`/`x` real de
`InstitutionalConstructionConfig`, sem exceção). Testado para as 4
Construções SEPARADAMENTE (nunca assumindo que uma redução igual produz
o mesmo resultado, já que os orçamentos diferem por até ~2,3× entre
Capital/CdC e Academia/Núcleo).

## Cenários simulados

| Cenário | Desconto no custo do Nível 2 | Desconto no custo do Nível 3 | Nível 4+ |
|---|---|---|---|
| A — Atual | 0% | 0% | curva vigente |
| B — Redução forte | 95% | 95% | curva vigente |
| C — Redução moderada | 85% | 80% | curva vigente |
| D — Redução progressiva | 95% | 85% | 50% só no Nível 4, depois 0% |
| E — Custo fixo absoluto | 400 Recursos (fixo, igual pras 4) | 1.200 Recursos (fixo, igual pras 4) | curva vigente |

## Resultados — dia em que cada Nível é atingido, por Construção

| Construção | A (Nível 2 / 3) | B (Nível 2 / 3) | C (Nível 2 / 3) | D (Nível 2 / 3 / 4) | E (Nível 2 / 3) |
|---|---|---|---|---|---|
| Capital | dia 290 / não atingido | dia 20 / dia 41 | dia 49 / dia 132 | dia 20 / dia 83 / dia 357 | dia 15 / dia 41 |
| Centro de Comando | dia 298 / não atingido | dia 21 / dia 42 | dia 50 / dia 135 | dia 21 / dia 84 / dia 364 | dia 18 / dia 52 |
| Academia | dia 288 / não atingido | dia 20 / dia 41 | dia 48 / dia 132 | dia 20 / dia 83 / dia 358 | dia 12 / dia 29 |
| Núcleo de Energia | dia 282 / não atingido | dia 20 / dia 40 | dia 47 / dia 129 | dia 20 / dia 81 / dia 352 | dia 11 / dia 26 |

("Não atingido" = não chega ao Nível 3 dentro dos 400 dias simulados.)

## Curva recomendada

**Cenário B (redução de 95% no custo para atingir os Níveis 2 e 3,
retorno integral à curva vigente a partir do Nível 4), aplicada
igualmente às 4 Construções.**

Justificativa objetiva:

* **Uniformidade real entre as 4 Construções:** apesar de terem
  orçamentos diários bem diferentes (Núcleo recebe ~2,3× mais que
  Centro de Comando), o Cenário B produz Nível 2 entre os dias 20-21 e
  Nível 3 entre os dias 40-42 para todas — uma diferença de no máximo 1
  dia entre a mais lenta e a mais rápida. Isso acontece porque a
  redução é **percentual sobre o custo real de cada uma** (nunca um
  valor fixo compartilhado) — o Cenário E (custo fixo) foi
  explicitamente testado e descartado por este motivo: produz uma
  dispersão real de até 26 dias entre Construções (Núcleo no dia 26,
  Centro de Comando só no dia 52), porque um valor fixo favorece
  desproporcionalmente quem já tinha o maior orçamento relativo.
* **Sensação de progresso dentro da 1ª quinzena/mês:** Nível 2 em ~3
  semanas e Nível 3 em ~6 semanas — dentro da janela em que um jogador
  plausivelmente ainda não conquistou nenhuma Mina Regional
  (`BALANCING_SIMULATION.md`, Resultado 6 da Simulação 1, cita a 1ª
  mina só por volta do dia 11 num cenário de jogador 100% dedicado;
  um jogador real, menos otimizado, provavelmente demora mais).
* **Nenhum impacto no late game:** a partir do Nível 4, o custo volta a
  ser **exatamente** `GeneralConstructionFormula.upgrade_cost()` com o
  `b`/`x` vigente da Simulação 3 — a mesma tabela de custo acumulado/dia
  já publicada ali para os Níveis 4-20 permanece 100% válida sem
  nenhuma alteração. O Cenário D (que também reduzia parcialmente o
  Nível 4) foi descartado por introduzir uma zona cinzenta desnecessária
  — o "degrau" de volta à curva normal fica mais claro sendo abrupto
  (Nível 3→4) do que gradual.
* **Minas Regionais continuam extremamente relevantes:** mesmo com o
  desconto, o Nível 4 (já na curva cheia — 19.320 a 43.720 Recursos
  conforme a Construção) permanece fora de alcance de uma economia
  "só Mina Inicial" dentro de qualquer horizonte plausível — só uma
  economia com Minas Regionais sustenta esse próximo salto.

## Impacto no early game

Nível 2 (evidência de que "algo mudou na Cidade") passa de
impraticável (~dia 290) para ~3 semanas. Nível 3 (uma "primeira pequena
conquista", nas palavras do pedido) passa de impraticável para ~6
semanas — ainda exige jogo real e paciência, nunca instantâneo.

## Impacto no mid/late game

**Nenhum.** O Cenário B não toca nenhum valor a partir do Nível 4 — a
tabela de custo acumulado/dia da Simulação 3 (Níveis 4-20) permanece
inalterada, assim como a conclusão da Simulação 4 sobre o Nível 15 não
ser alcançável dentro de uma Temporada de 180 dias no cenário
Conservador (esse achado continua de pé, sem relação com este).

## Riscos

* Um desconto de 95% é, por definição, uma redução muito acentuada —
  se aplicado incorretamente (ex.: esquecido de reverter no Nível 4),
  poderia mascarar a curva de custo real. A implementação recomendada
  restringe o desconto explicitamente aos graus até o Nível 3, nunca
  como uma mudança permanente de `b`/`x`.
* Esta simulação assume a mesma eficiência/ritmo de conquista de PG já
  usada nas Simulações 1-4 (1,3 PG/dia, alocação 80/20) — se essas
  premissas mudarem (ex.: decisão futura da Simulação 4 sobre dividir
  PG por Trilha), os dias exatos mudam, mas a CONCLUSÃO relativa entre
  cenários (B uniforme, E desigual) deve se manter.

## Validação Agregada (FASE 22 — antes de oficializar o Cenário B)

A avaliação acima testou cada Construção **isoladamente**, com uma
fatia fixa (20/15/30/35%) do orçamento diário. Isso prova que a curva é
uniforme entre Construções, mas não prova que as 4 Construções
competindo pelo **mesmo banco** de Recursos (sem fatia automática,
decisão real do jogador sobre onde gastar) funcionam sem uma "esvaziar"
as outras ou permitir "comprar tudo". Nova simulação dia-a-dia (180
dias, script descartável, removido após uso, mesmo código real —
`MineEconomy`/`GeneralConstructionFormula`/
`InstitutionalConstructionConfig`), 3 perfis de comportamento:

* **Perfil A — Equilibrado:** a cada dia, investe sempre na Construção
  de MENOR nível atual (empate: ordem fixa Capital → Centro de Comando
  → Academia → Núcleo).
* **Perfil B — Focado:** investe exclusivamente no Núcleo de Energia,
  do início ao fim, ignorando as outras 3.
* **Perfil C — Cíclico:** segue exatamente o padrão de compra pedido —
  Capital → Centro de Comando → Academia → Núcleo → repete.

### Resultados

| Perfil | Recursos produzidos | Recursos gastos | Banco final (não gasto) |
|---|---|---|---|
| A — Equilibrado | 40.205 | 33.347 (83%) | 6.858 (17%) |
| B — Focado (só Núcleo) | 40.205 | 2.763 (7%) | 37.442 (93%) |
| C — Cíclico | 40.205 | 33.347 (83%) | 6.858 (17%) |

| Construção | Perfil A — Nível 2 / 3 / 4 | Perfil B — Nível 2 / 3 / 4 | Perfil C — Nível 2 / 3 / 4 |
|---|---|---|---|
| Capital | dia 9 / dia 24 / dia 151 | nunca sai do Nível 1 | dia 9 / dia 24 / dia 151 |
| Centro de Comando | dia 11 / dia 27 / não atingido | nunca sai do Nível 1 | dia 11 / dia 27 / não atingido |
| Academia | dia 15 / dia 34 / não atingido | nunca sai do Nível 1 | dia 15 / dia 34 / não atingido |
| Núcleo de Energia | dia 20 / dia 41 / não atingido | dia 11 / dia 18 / não atingido | dia 20 / dia 41 / não atingido |

("Não atingido" = não chega àquele Nível dentro dos 180 dias simulados.)

### Leitura dos resultados

* **Perfil A e Perfil C são numericamente idênticos.** A heurística "sempre
  a de menor Nível" e o ciclo fixo Capital→CdC→Academia→Núcleo convergem
  para o mesmo comportamento — não existe um "truque" de ordem de compra
  que renda mais que o outro. O ciclo pedido não cria uma rota
  secretamente ótima nem um jeito errado de jogar.
* **Nenhuma Construção trava as outras.** Em jogo equilibrado/cíclico,
  todas as 4 alcançam o Nível 2 entre os dias 9-20 e o Nível 3 entre os
  dias 24-41 — a mesma janela já vista na avaliação isolada. O banco
  final de 17% não gasto é folga normal (esperando o próximo grau),
  não acúmulo patológico.
* **Focar 100% em uma única Construção NÃO permite "comprar tudo".**
  Sob o Perfil B, o Núcleo de Energia chega ao Nível 3 rapidamente (dia
  18) mas **fica travado ali pelo resto dos 180 dias**: o Nível 4 custa
  43.720 Recursos (curva vigente, sem desconto) — mais do que os 40.205
  produzidos no período inteiro. Isso deixa 93% de toda a produção
  parada no banco, sem uso. Ou seja: o desconto de 95% não abre uma
  rota de progressão infinita nem torna a economia "fácil demais" —
  ele só acelera os Níveis 2-3; o Nível 4 continua exigindo uma
  economia real (Minas Regionais), exatamente como pretendido.
* **Mina Inicial permanece relevante só durante a rampa inicial (~9
  dias)** — tempo para as 3 Minas Iniciais atingirem seu teto (Nível 4,
  `MINES.md`). Depois disso a produção fica fixa (576 Recursos/dia
  brutos, 230,4/dia para as Construções via a fatia de 40%) — ela deixa
  de crescer, mas continua sendo a ÚNICA fonte de Recursos de
  Construção até a conquista de uma Mina Regional.
* **A economia "trava" por volta do dia 24-41** (quando as 4 Construções
  alcançam o Nível 3 em jogo equilibrado): a partir daí, o próximo passo
  de qualquer uma delas é o Nível 4 em curva cheia, e o ritmo de
  progresso cai drasticamente (Capital, a mais barata das 4, ainda leva
  até o dia 151 para chegar lá com produção só de Mina Inicial).
* **O que muda ao conquistar a primeira Mina Regional (raciocínio, não
  simulado aqui — está fora do escopo de "só Mina Inicial"):** mesmo uma
  única Mina Regional em Nível 1 já produz 5/10/20 Recursos/hora
  (Região 1/2/3, `MINES.md`) — uma Região 3 Nível 1 sozinha (480/dia,
  antes de Eficiência) praticamente **iguala a produção bruta das 3
  Minas Iniciais somadas e maximizadas** (576/dia). Isso confirma que o
  "degrau" para o Nível 4 foi projetado corretamente para ser
  Regional-dependente, não Mina-Inicial-dependente — o gargalo do
  Perfil B (banco parado em 93%) é sanado assim que o jogador conquista
  território, não por um ajuste adicional na curva de entrada.

### Teste de sensatez dos 95%

**Classificação: ADEQUADO.** Critérios usados (conforme pedido, sem
reduzir os 95% automaticamente — decisão baseada nos números acima):

* Não é "Muito lento": Nível 2 em 1-3 semanas e Nível 3 em ~1-6 semanas
  em jogo equilibrado/cíclico é uma evolução perceptível dentro do
  período em que um jogador novo plausivelmente ainda não tem Mina
  Regional.
* Não é "Muito rápido": mesmo dedicando 100% da produção a uma única
  Construção (Perfil B, o cenário mais agressivo possível), o jogador
  NÃO consegue "comprar tudo" — trava no Nível 3 daquela Construção e
  deixa 93% dos Recursos parados, porque o Nível 4 nunca recebe
  desconto. Não existe combinação de perfil de gasto que destrave a
  curva cheia (Nível 4+) usando só Mina Inicial.
* **Conclusão: manter os 95% exatamente como testado — Cenário B
  aprovado sem alteração.**

## Curva final aprovada e implementada

**Cenário B, oficializado:** para Capital, Centro de Comando, Academia
e Núcleo de Energia, o custo para alcançar os Níveis 2 e 3 é **5% do
valor calculado por `GeneralConstructionFormula.upgrade_cost()`**
(desconto de 95%); a partir do Nível 4, o custo é **100% da curva
vigente**, sem nenhuma exceção. `b` e `x`
(`InstitutionalConstructionConfig`) e a fórmula geral
(`GeneralConstructionFormula`) permanecem exatamente como estavam — o
desconto é uma camada nova, isolada, aplicada por cima do valor real.

Implementado em `InstitutionalConstructionEntryCurve`
(`Game/engine/city/institutional_construction_entry_curve.gd`) — única
fonte desse percentual — e consumido exclusivamente por
`InstitutionalConstructionResolver.cost_breakdown()`, o único ponto do
jogo onde o custo das 4 Construções Institucionais é calculado
(painéis de Capital/Academia/Centro de Comando/Núcleo de Energia e
`SupplyChainResolver` já leem o custo por esse caminho — nenhum ponto
de código chama `GeneralConstructionFormula.upgrade_cost()` diretamente
para estas 4 Construções). Testes: `test_institutional_construction_entry_curve.gd`.

---

# Referências

* **ENERGY.md / ENERGY_NUCLEUS.md:** Energia, consumo, recuperação, Núcleo.
* **PvE.md:** Estrutura de Trechos, Acampamentos, Regiões.
* **XP.md:** XP de Comandante, Patentes, XP de Conta.
* **RESOURCES.md:** Fragmentos, VRP, VRG.
* **CARD_PROGRESSION.md:** Mecânica de Aprimoramento (Tier).
* **FORMULAS.md:** Fórmula oficial de custo do Núcleo de Energia (Resultado desta simulação).
* **MINES.md / DEPOSITS.md:** Produção das Minas, capacidade de armazenamento.
* **CITY.md:** Fundamentos por construção.
