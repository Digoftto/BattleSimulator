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

# Referências

* **ENERGY.md / ENERGY_NUCLEUS.md:** Energia, consumo, recuperação, Núcleo.
* **PvE.md:** Estrutura de Trechos, Acampamentos, Regiões.
* **XP.md:** XP de Comandante, Patentes, XP de Conta.
* **RESOURCES.md:** Fragmentos, VRP, VRG.
* **CARD_PROGRESSION.md:** Mecânica de Aprimoramento (Tier).
* **FORMULAS.md:** Fórmula oficial de custo do Núcleo de Energia (Resultado desta simulação).
* **MINES.md / DEPOSITS.md:** Produção das Minas, capacidade de armazenamento.
* **CITY.md:** Fundamentos por construção.
