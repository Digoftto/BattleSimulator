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

## Registro histórico (superado — ver "Armazenamento por Nível (vigente)" abaixo)

As duas referências abaixo (fator 2, calibrada pela produção da Mina Básica; e uma tentativa intermediária vinculada ao custo da Capital) foram **substituídas** pela decisão do dono do projeto registrada em `Deposits.storage_capacity()` (fator 3 geométrico, níveis 1-7, seguido de Progressão Aritmética a partir do nível 8). Mantidas aqui só como registro histórico — nunca usar estes números para calcular capacidade real.

### Referência histórica 1: Fase Reino Jovem (fator 2, Níveis 1-3)

| Nível | Produção/Hora da Mina Básica | Produção/Dia | Armazenamento (referência histórica) |
| --- | --- | --- | --- |
| 1 | 1 | 24 | 24 |
| 2 | 2 | 48 | 48 |
| 3 | 4 | 96 | 96 |

### Referência histórica 2: vinculada ao custo da Capital

130% do custo por Recurso de Construção que a Capital precisa para evoluir do nível "level" para "level + 1" (Capital divide seu custo igualmente entre os 3 Recursos — CITY.md/FORMULAS.md). Ex.: Capital exigindo 300 no total (100 de cada recurso) para o Nível N ⇒ Depósito no Nível N-1 armazenaria 130 de cada recurso.

Os custos oficiais de evolução encontram-se centralizados em `FORMULAS.md`.

## Armazenamento por Nível (vigente)

A tabela abaixo é única para o Depósito — o valor de Armazenamento aplica-se simultaneamente aos três recursos (Ferro Negro, Cristais Arcanos, Essência Vital). Fonte real: `Deposits.storage_capacity()` — progressão geométrica de fator 3 nos Níveis 1-7 (começando em 24), seguida de Progressão Aritmética a partir do Nível 8 (mesmo incremento do último salto geométrico, 11.664, evitando crescimento descontrolado).

| Nível | Armazenamento (cada um dos 3 recursos) |
| --- | --- |
| 1 | 24 |
| 2 | 72 |
| 3 | 216 |
| 4 | 648 |
| 5 | 1.944 |
| 6 | 5.832 |
| 7 | 17.496 |
| 8 | 29.160 |
| 9 | 40.824 |
| 10 | 52.488 |
| 11+ | +11.664 por nível (Progressão Aritmética) |

---

# Regra Permanente

Os valores numéricos poderão ser alterados para fins de balanceamento.

A evolução do Depósito ocorre exclusivamente através de Pontos de Geração (ver `GENERATION_POINTS.md` e `FORMULAS.md`) e nunca consome Ferro Negro, Cristais Arcanos ou Essência Vital.

Cada evolução do Depósito aumenta simultaneamente a capacidade de armazenamento dos três recursos — não existe evolução ou custo isolado por recurso.

A Reserva Antecipada de Evolução nunca ultrapassa o exigido pela construção de destino, nunca retorna ao Depósito de origem, e nunca permite evolução com Recursos incompletos.