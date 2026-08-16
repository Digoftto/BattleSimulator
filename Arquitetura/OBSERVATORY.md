# OBSERVATÓRIO

O Observatório é uma ferramenta de consulta e análise.

Ele não é construção da cidade, não possui nível, não consome recursos e não interfere diretamente na economia do Reino.

Sua função é reunir estatísticas, relatórios de desempenho, dados de simulação, análises de cartas, facções, formações, exércitos e minas.

Na organização geral da interface, o Observatório pertence ao grupo Consulta, ao lado da Biblioteca.

---

# VERSÃO BASE (v1.0)

## Configuração
* Meta Aleatório
* 10.000 séries
* Limite de 32 turnos
* Tie-Breaker ativo

## Resultados Gerais
Vitórias A: 50.03% (5.003)
Vitórias B: 49.94% (4.994)
Empates de série: 0.03% (3)
Turnos Médios/Série: 42.01

Distribuição dos placares:
3x0      | 18.3% (1831)
3x1      | 18.0% (1798)
3x2      | 13.7% (1374)
2x3      | 13.9% (1392)
1x3      | 17.5% (1752)
0x3      | 18.5% (1850)
2x1      | 0.0% (1)
1x2      | 0.0% (1)
2x2      | 0.0% (3)
1x1      | 0.0% (1)

## Performance das Formações
* ALPHA: 49.7% / 50.3% / 0.0% (WR A / WR B / WR EMP)
* BETA: 50.7% / 49.3% / 0.0%
* GAMMA: 50.0% / 50.0% / 0.0%
* DELTA: 49.7% / 50.3% / 0.0%
* EPSILON: 49.7% / 50.3% / 0.0%

## Observações
* Ausência de viés estrutural.
* Taxas próximas de 50%.

# VALIDAÇÃO FASE 3B

## Amostragem
* **Séries Simuladas:** 10.000
* **Confrontos Individuais:** 39.208 (Aprox. 3.92 por série)
* **Soma Total de Aparições:** 705.744 (18 × 39.208)

## Integridade Matemática e Global
* **Integridade Individual (W+L+D = App):** OK
* **Consistência Global (Σ App = 18x):** OK (705.744 == 705.744)

## Auditoria de Limites e Extremos
* **Win Rates:** Todos entre 45.2% e 54.1% (Zona de Equilíbrio OK)
* **Presença:** Detectadas variações entre 98.5% e 101.5%.
    * *Nota:* Valores > 100% ocorrem pois a mesma carta pode ser sorteada para ambos os Decks (A e B) simultaneamente no modo META ALEATÓRIO, resultando em 2 aparições no mesmo confronto individual.
* **Alertas de Desequilíbrio:** Nenhum (Nenhuma carta > 65% ou < 35%).

## Top 10 WR
1. Arqueiro Maldito     | 54.1%
2. Arqueira da Floresta | 53.7%
3. Bruxo da Peste       | 53.6%
4. Espírito Ancestral   | 53.1%
5. Cavaleiro Profano    | 52.1%
6. Besteiro Imperial    | 52.0%
7. Cavaleiro Real       | 51.6%
8. Lobo Alfa            | 51.5%
9. Inquisidor           | 51.3%
10. Guardiao do Carvalho | 51.0%

## Bottom 10 WR
1. Torre Escudeira      | 45.2%
2. Engenheiro de Guerra | 45.6%
3. Muralha de Vinhas    | 45.9%
4. Curandeira Selvagem  | 46.3%
5. Muralha de Ossos     | 47.3%
6. Cultista Sombrio     | 47.3%
7. Lanceiro Imperial    | 48.3%
8. Esqueleto Guerreiro  | 49.6%
9. Guardiao do Carvalho | 51.0%
10. Inquisidor           | 51.3%

## Análise das Formações
* Todos os deltas de WR entre as formações (α, β, γ, δ, ε) para cada carta estão abaixo de 15%.
* Estabilidade posicional confirmada.

## Conclusão Geral
O sistema apresenta integridade estatística sólida. O desequilíbrio leve entre Arqueiros (Top WR) e Barreiras (Bottom WR) é esperado pela natureza atual das Afinidades e regras de combate, mas permanece dentro dos limites aceitáveis para o MVP. A infraestrutura de auditoria está pronta para as próximas fases.
