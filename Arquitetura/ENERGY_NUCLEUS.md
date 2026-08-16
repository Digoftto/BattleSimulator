# ENERGY_NUCLEUS.md

# Núcleo de Energia

## Objetivo

O Núcleo de Energia representa toda a infraestrutura logística responsável por sustentar os exércitos do Reino durante suas campanhas.

Sua evolução melhora tanto a capacidade logística disponível quanto a eficiência na recuperação da fadiga operacional dos exércitos.

O Núcleo de Energia não aumenta diretamente o poder das tropas.

Seu papel consiste em ampliar a autonomia operacional do Reino.

---

# Filosofia

Um exército permanece em campanha graças a uma cadeia logística eficiente.

Alimentos, água, munições, transporte, manutenção e organização militar são responsabilidades do Reino.

O Núcleo de Energia representa essa infraestrutura.

À medida que evolui, os exércitos conseguem permanecer mais tempo em atividade e retornam às operações com maior rapidez.

---

# Responsabilidades

O Núcleo de Energia possui duas responsabilidades independentes.

## Capacidade Logística

Aumenta a Energia Base fornecida pelo Reino para todos os exércitos.

Essa energia representa a infraestrutura logística disponível.

---

## Eficiência Logística

Reduz o tempo necessário para recuperar a energia dos exércitos.

Quanto maior o nível do Núcleo, menor o intervalo entre cada ponto recuperado.

---

# Desbloqueio

O Núcleo de Energia está disponível desde o início do jogo.

Sua evolução depende exclusivamente da progressão da Cidade.

---

# Progressão

O Núcleo possui 60 níveis.

Após atingir o nível máximo, nenhuma melhoria adicional poderá ser realizada.

O custo de evolução do Núcleo segue a fórmula geral única de construções (`FORMULAS.md`): C(n) = CEG × (b + n² + xn), consumindo Recursos de Construção — não Pontos de Geração. Os valores **atualmente vigentes** de $b$ e $x$ são definidos e mantidos em `BALANCING_SIMULATION.md` — múltiplas simulações podem calcular diferentes pares de $b$/$x$ ao longo do tempo, mas apenas um par é o vigente a qualquer momento, sempre marcado explicitamente como tal naquele documento.

---

# Capacidade Logística

Valor inicial.

40 pontos.

A cada cinco níveis completos.

↓

+1 Energia Base.

Tabela de referência.

| Nível | Energia Base |
|------:|-------------:|
| 1 | 40 |
| 5 | 41 |
| 10 | 42 |
| 15 | 43 |
| 20 | 44 |
| 25 | 45 |
| 30 | 46 |
| 35 | 47 |
| 40 | 48 |
| 45 | 49 |
| 50 | 50 |
| 55 | 51 |
| 60 | 52 |

Essa energia é concedida automaticamente a todos os exércitos do Reino.

---

# Eficiência Logística

Valor inicial.

1 ponto de energia a cada

7 minutos e 30 segundos.

Entre os níveis múltiplos de cinco, o intervalo é reduzido progressivamente.

## Níveis 2–10

Redução de 3 segundos por nível.

---

## Níveis 11–30

Redução de 3 segundos por nível.

---

## Níveis 31–60

Redução de 2 segundos por nível.

Ao atingir o nível 60.

A recuperação será de aproximadamente

1 ponto a cada 5 minutos e 26 segundos.

---

# Progressão Resumida

| Nível | Energia Base | Recuperação |
|------:|-------------:|------------:|
| 1 | 40 | 7m30s |
| 5 | 41 | 7m18s |
| 10 | 42 | 7m06s |
| 15 | 43 | 6m54s |
| 20 | 44 | 6m42s |
| 25 | 45 | 6m30s |
| 30 | 46 | 6m18s |
| 35 | 47 | 6m10s |
| 40 | 48 | 6m00s |
| 45 | 49 | 5m50s |
| 50 | 50 | 5m40s |
| 55 | 51 | 5m30s |
| 60 | 52 | 5m26s |

---

# Interface

A tela do Núcleo deverá apresentar.

## Informações atuais

- Nível.
- Energia Base.
- Tempo de recuperação.
- Próximo bônus.

---

## Exemplo

```text
Núcleo de Energia

Nível 27

Capacidade Logística

45

Recuperação

1 ponto a cada 6m24s

Próximo nível

Recuperação -3 segundos
```

Quando o próximo nível for múltiplo de cinco.

```text
Próximo nível

+1 Energia Base
```

---

# Regras Gerais

- O Núcleo influencia todos os exércitos do Reino.
- Nunca aumenta o dano das tropas.
- Nunca aumenta atributos das cartas.
- Nunca aumenta atributos dos comandantes.
- Apenas melhora a infraestrutura logística.
- Apenas altera Energia Base e recuperação.
- O nível máximo é 60.

---

# Relação com Outros Sistemas

Este documento interage diretamente com.

- ENERGY.md
- CITY.md
- COMMANDERS.md

As regras desses sistemas não são definidas aqui.

---

# Observações

O Núcleo de Energia representa o crescimento da infraestrutura militar do Reino.

Sua evolução amplia a capacidade de manter campanhas prolongadas sem alterar diretamente o equilíbrio dos combates.

Dessa forma, recompensa o desenvolvimento da Cidade através de maior disponibilidade operacional, preservando a importância da estratégia e da composição dos exércitos.