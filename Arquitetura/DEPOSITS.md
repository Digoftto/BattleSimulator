# DEPOSITS

Objetivo:

Os depósitos são responsáveis pelo armazenamento dos recursos de construção da Cidade.

Além do armazenamento, os depósitos atuam como limitadores naturais da progressão da cidade.

---

# Recursos

Existem três recursos de construção.

## Ferro Negro

Representa:

* metal;
* ferramentas;
* armas;
* estruturas.

Depósito correspondente:

* Fundição.

---

## Cristais Arcanos

Representam:

* magia;
* energia;
* conhecimento;
* aprimoramentos.

Depósito correspondente:

* Câmara Arcana.

---

## Essência Vital

Representa:

* vida;
* crescimento;
* biomassa;
* materiais orgânicos.

Depósito correspondente:

* Santuário Vital.

---

# O Depósito

O Depósito é **um único sistema de armazenamento**, não três construções independentes. Ele possui um único nível (`deposito_level`) e uma única progressão de evolução, pagas exclusivamente em Pontos de Geração (PG) — ver `GENERATION_POINTS.md` e `FORMULAS.md`.

**Cada evolução do Depósito aumenta simultaneamente a capacidade de armazenamento dos três recursos.** Não existe evolução parcial nem custo isolado por recurso.

Internamente, o Depósito é dividido em três áreas temáticas de armazenamento, cada uma associada a um Recurso de Construção:

* **Fundição** — armazena Ferro Negro.
* **Câmara Arcana** — armazena Cristais Arcanos.
* **Santuário Vital** — armazena Essência Vital.

Essas áreas são identidade visual/temática (ver `Fundation/Depósitos.md`), não construções separadas com níveis ou custos próprios.

---

# Filosofia dos Depósitos

O Depósito evolui exclusivamente através de Pontos de Geração (PG), que representam um recurso estratégico global do Reino (ver `GENERATION_POINTS.md`). Ele nunca consome Ferro Negro, Cristais Arcanos ou Essência Vital para evoluir.

Dessa forma, elimina-se a interdependência cruzada entre os armazenamentos: evoluir o Depósito nunca depende de acumular os próprios recursos que ele guarda. Como sistema único, o Depósito compete com as demais construções da Cidade (Centro de Comando, Academia) apenas pelo orçamento disponível de PG — não compete internamente consigo mesmo, pois não há níveis independentes por recurso.

---

# Reserva Antecipada de Evolução

Os Depósitos também atuam como um limitador natural de ausência do jogador (`GAME_PHILOSOPHY.md`, "Filosofia do Idle": "a ausência temporária do jogador nunca deve gerar perdas destrutivas") — evoluir um Depósito aumenta sua capacidade de armazenamento, permitindo que o jogador fique mais tempo fora do jogo sem que a produção das Minas ultrapasse o limite e seja desperdiçada.

A Reserva Antecipada de Evolução é o mecanismo complementar a essa filosofia: o jogador pode transferir Recursos de Construção (Ferro Negro, Cristais Arcanos, Essência Vital) diretamente de um Depósito para qualquer outra construção da Cidade que os utilize em sua evolução (Capital, Centro de Comando, Academia, Núcleo de Energia — nunca as Minas ou os próprios Depósitos, que evoluem exclusivamente com Pontos de Geração), desafogando o Depósito antes que ele atinja sua capacidade máxima.

## Regras da Transferência

* O total transferido para uma construção nunca pode exceder o exato valor exigido pela sua próxima evolução — nunca sobra recurso parado na construção além do necessário.
* Uma vez transferido, o recurso fica **preso** naquela construção especificamente. Não retorna ao Depósito, nem pode ser redirecionado para outra construção.
* A evolução da construção só é executada quando **todos** os Recursos de Construção exigidos estiverem completos ali — nunca parcialmente. A transferência antecipada só adianta o acúmulo; não permite evolução incompleta.
* A transferência não consome tempo nem Pontos de Geração — é uma realocação direta entre dois Recursos já pertencentes ao jogador.

---

# Progressão

O Depósito possui:

* um único nível;
* um único custo de evolução por nível (em Pontos de Geração — PG);
* um único limite de armazenamento, aplicado simultaneamente aos três Recursos de Construção.

O Depósito nunca pode ultrapassar o nível da Capital.

---

# Tabelas de Evolução

## Referência: Fase Reino Jovem (Níveis 1-3)

A tabela abaixo representa apenas uma referência de calibração da Temporada 1, não substituindo as fórmulas oficiais nem representando uma regra permanente de balanceamento.

Nos primeiros 3 níveis, a capacidade de armazenamento de cada Depósito é calibrada para acompanhar exatamente a produção diária das Minas Básicas correspondentes (ver MINES.md, "Mina Inicial") — ou seja, a capacidade nestes níveis representa aproximadamente 1 dia de produção máxima da mina básica daquele recurso.

| Nível | Produção/Hora da Mina Básica | Produção/Dia | Armazenamento (referência) |
| --- | --- | --- | --- |
| 1 | 1 | 24 | 24 |
| 2 | 2 | 48 | 48 |
| 3 | 4 | 96 | 96 |

Esta relação é **proposital**: a capacidade do Depósito nesta fase inicial não é definida de forma independente — ela acompanha deliberadamente a produção da mina básica, para que o jogador raramente perca recursos por excesso de armazenamento nos primeiros dias de jogo (ver COMMAND_CENTER.md, "Economia I — Reino Jovem").

A partir do nível 4 (quando as minas básicas já atingiram seu teto e a economia passa a depender das minas das trilhas de PvE — "Economia II — Reino em Expansão"), a capacidade dos Depósitos deixa de seguir essa relação fixa e passa a ser calibrada de forma independente, conforme a produção das minas regionais (ver MINES.md).

Os custos oficiais de evolução encontram-se centralizados em `FORMULAS.md`.

## Armazenamento por Nível

A tabela abaixo é única para o Depósito — o valor de Armazenamento aplica-se simultaneamente aos três recursos (Ferro Negro, Cristais Arcanos, Essência Vital).

| Nível | Armazenamento (cada um dos 3 recursos) |
| --- | --- |
| 1 | 24 |
| 2 | 48 |
| 3 | 96 |
| 4+ | ? |

---

# Regra Permanente

Os valores numéricos poderão ser alterados para fins de balanceamento.

A evolução do Depósito ocorre exclusivamente através de Pontos de Geração (ver `GENERATION_POINTS.md` e `FORMULAS.md`) e nunca consome Ferro Negro, Cristais Arcanos ou Essência Vital.

Cada evolução do Depósito aumenta simultaneamente a capacidade de armazenamento dos três recursos — não existe evolução ou custo isolado por recurso.

A Reserva Antecipada de Evolução nunca ultrapassa o exigido pela construção de destino, nunca retorna ao Depósito de origem, e nunca permite evolução com Recursos incompletos.