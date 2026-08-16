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

# Fundição

Responsável pelo armazenamento de Ferro Negro.

Sua evolução utiliza exclusivamente **Pontos de Geração** (ver FORMULAS.md).

---

# Câmara Arcana

Responsável pelo armazenamento de Cristais Arcanos.

Sua evolução utiliza exclusivamente **Pontos de Geração** (ver FORMULAS.md).

---

# Santuário Vital

Responsável pelo armazenamento de Essência Vital.

Sua evolução utiliza exclusivamente **Pontos de Geração** (ver FORMULAS.md).

---

# Filosofia dos Depósitos

Os três depósitos evoluem exclusivamente através de Pontos de Geração, que representam um recurso estratégico global da Cidade. Nenhum depósito consome Ferro Negro, Cristais Arcanos ou Essência Vital para evoluir.

Dessa forma, elimina-se a interdependência cruzada entre os armazenamentos. Os depósitos competem entre si e com as demais construções da Cidade apenas pelo orçamento disponível de Pontos de Geração.

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

Todos os depósitos possuem:

* níveis;
* custos de evolução (em Pontos de Geração);
* limite de armazenamento.

Nenhum depósito pode ultrapassar o nível da Capital.

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

## Fundição

| Nível | Armazenamento |
| --- | --- |
| 1 | 24 |
| 2 | 48 |
| 3 | 96 |
| 4+ | ? |

---

## Câmara Arcana

| Nível | Armazenamento |
| --- | --- |
| 1 | 24 |
| 2 | 48 |
| 3 | 96 |
| 4+ | ? |

---

## Santuário Vital

| Nível | Armazenamento |
| --- | --- |
| 1 | 24 |
| 2 | 48 |
| 3 | 96 |
| 4+ | ? |

---

# Regra Permanente

Os valores numéricos poderão ser alterados para fins de balanceamento.

A evolução dos três depósitos ocorre exclusivamente através de Pontos de Geração (ver FORMULAS.md) e nenhum deles consome Ferro Negro, Cristais Arcanos ou Essência Vital.

A Reserva Antecipada de Evolução nunca ultrapassa o exigido pela construção de destino, nunca retorna ao Depósito de origem, e nunca permite evolução com Recursos incompletos.