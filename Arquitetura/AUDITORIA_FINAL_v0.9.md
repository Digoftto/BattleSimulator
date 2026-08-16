# AUDITORIA FINAL DA ARQUITETURA — v0.9

## Escopo

Auditoria final do conjunto de 49 documentos arquiteturais enviados como o corpus mais atualizado para o MVP.

As pastas de ideias futuras e de implementação/especificações ainda não entram nesta auditoria. Elas serão avaliadas posteriormente, contra esta arquitetura consolidada.

---

# 1. RESULTADO GERAL

A arquitetura atual é utilizável como base do MVP, mas **não deve ser entregue ao agente como um conjunto indiferenciado de 49 arquivos**.

O principal problema remanescente não é falta de sistemas: é governança e roteamento.

Há três classes de documentos:

1. **SSOT de regras** — definem o comportamento.
2. **Catálogos/dados/consultas** — descrevem conteúdo ou apresentam dados sem criar regras.
3. **Governança/interface/análise** — organizam, apresentam ou validam sistemas existentes.

O `PROJECT_INDEX.md` deve fazer essa distinção explicitamente.

---

# 2. DECISÕES DO DONO JÁ CONSOLIDADAS

Estas decisões foram incorporadas à arquitetura:

- Balista: começa obrigatoriamente na posição 9 e depois movimenta-se normalmente segundo a regra geral.
- Tier: mutável, Tier 1 a Tier 5.
- Energia: depende do Tier.
- Soldo: depende exclusivamente da Raridade.
- Afinidade: snapshot entre turnos; bônus congelados durante todo o turno.
- `ABILITIES.md`: fonte oficial das Características de Unidade.
- `UNIT_TRAITS.md`: não existe.
- Limite máximo de combate: 64 turnos.
- `Engenharia Militar II`: é uma evolução da habilidade base; no corpus atual ela está representada como `Comando de Reparos`.
- `Treinamento Arcano`: permanece não resolvido e foi deliberadamente deixado fora da decisão final por depender de documentação histórica ausente.

---

# 3. CONTRADIÇÕES CORRIGIDAS NESTA CONSOLIDAÇÃO

## 3.1 CARD.md

Corrigido:

- Soldo não depende de Tier.
- Tier é estado mutável, não identidade.
- Raridade pertence à identidade.

## 3.2 COMBAT_RULES.md

Corrigido:

- Máquina de Guerra começa na posição 9.
- Não fica permanentemente imóvel.
- Depois do início do combate segue a movimentação geral.

## 3.3 AFFINITY.md

Corrigido:

- removido recálculo dinâmico durante o turno;
- snapshot e bônus ficam congelados durante o turno;
- mudanças passam a valer no próximo turno.

## 3.4 ENERGY_NUCLEUS.md

A tabela existente é compatível com redução de 3 segundos por nível nos níveis 2–30, não 4 segundos nos níveis 2–10. O texto foi alinhado à tabela.

## 3.5 SOLDO.md

Corrigido o exemplo aritmético de composição de 32 Soldo.

---

# 4. CONFLITO AINDA ABERTO — PG

Existe uma divergência que não deve ser resolvida automaticamente.

`XP.md` afirma que PG são utilizados exclusivamente para Minas e Depósitos.

`COMMAND_CENTER_PROGRESS.md` utiliza PG para Expansão Administrativa.

`MINES.md` utiliza PG para evolução das Minas.

`DEPOSITS.md` utiliza PG para evolução dos Depósitos.

`FORMULAS.md` define custos de PG para Minas e Depósitos.

### Situação

A arquitetura atual possui duas interpretações:

A. PG é uma moeda de infraestrutura limitada a Minas/Depósitos.

B. PG é um recurso global de infraestrutura utilizado também para ativação administrativa do Centro de Comando.

### Status

**DECISÃO DO DONO PENDENTE**

Não deve ser resolvida pelo agente.

---

# 5. FORMULAS / BALANCING

`FORMULAS.md` é o SSOT matemático.

Os parâmetros `b` e `x` não estão ausentes: são deliberadamente mantidos em `BALANCING_SIMULATION.md`.

A Simulação 3 está explicitamente marcada como **VIGENTE** e fornece:

| Construção | b | x |
|---|---:|---:|
| Capital | 50 | 300 |
| Centro de Comando | 50 | 225 |
| Academia | 50 | 460 |
| Núcleo de Energia | 50 | 530 |

Portanto, a implementação não deve inventar esses valores.

---

# 6. ACADEMIA

A documentação atual já define:

- criação de Cartas Tier I;
- Aprimoramento;
- Artífices;
- Metamorfos;
- produção paralela;
- fila individual;
- origem de ingredientes;
- estratégia global;
- personalização por ingrediente;
- tempos base;
- redução de tempo;
- fórmula de custo;
- parâmetros vigentes.

A frase "0,5 ponto percentual por nível" deve ser interpretada junto à tabela de marcos e à interpolação linear.

A regra canônica recomendada para o texto futuro é:

> A redução é determinada pelos marcos oficiais e interpolada linearmente entre eles, atingindo 60% no nível 120.

Isso evita uma interpretação literal de `0,5 × (nível - 1)` que produziria 59,5% no nível 120.

---

# 7. HABILIDADES / CATÁLOGO

A verificação automática dos campos Tier III e Tier V do `CARD_CATALOG.md` contra os títulos de `ABILITIES.md` não encontrou habilidades órfãs reais.

A única diferença encontrada foi `Vontade Persistente` com nome narrativo "Trono dos Mortos", que já está explicitamente documentada em `ABILITIES.md`.

`Comando de Reparos` é a forma atual documentada da evolução de Engenharia Militar.

`Treinamento Arcano` não aparece no corpus atual e deve continuar pendente.

---

# 8. COMBATE

`COMBAT_CORE.md` define arquitetura.

`COMBAT_RULES.md` define operação.

`ABILITIES.md`, `AFFINITY.md`, `CARD_CATALOG.md`, `COMMANDERS.md` e `BATTLEFIELDS.md` definem seus respectivos domínios.

Essa divisão é adequada para o MVP.

O fluxo possui:

- inicialização;
- snapshot;
- movimento;
- seleção de alvos;
- execução;
- resolução de mortes;
- verificações de vitória;
- limite de 64 turnos.

---

# 9. OBSERVATÓRIO / BALANCEAMENTO

`OBSERVATORY.md` é ferramenta de análise e não SSOT de regras.

Resultados de simulação devem ser tratados como evidência de balanceamento, não como regra.

`BALANCING_SIMULATION.md` é o proprietário dos parâmetros de `b/x` atualmente vigentes.

---

# 10. DOCUMENTOS QUE NÃO DEVEM SER TRATADOS COMO SSOT DE REGRAS

- `GLOSSARY.md` — terminologia.
- `LIBRARY.md` — interface/consulta.
- `LIBRARY_CONTENT.md` — conteúdo/catalogação.
- `TUTORIAL.md` — experiência de onboarding; ainda não congelado.
- `TUTORIAL_REVIEW.md` — revisão do tutorial.
- `OBSERVATORY.md` — análise.
- `PROJECT_STRUCTURE.md` — governança documental, que precisa ser limpa da versão duplicada interna.
- `DECISOES.md` — governança de desenvolvimento.
- `LORE.md` — universo narrativo.
- `GAME_PHILOSOPHY.md` — princípios filosóficos.

---

# 11. PROBLEMA DO PROJECT_STRUCTURE.md

O arquivo contém duas versões concatenadas.

A primeira versão termina aproximadamente na seção de referências e, depois, começa novamente com `# Organização da Documentação`.

A segunda metade contém nomes de documentos que não fazem parte do corpus atual, como:

- VISION.md
- DESIGN.md
- GAME_LOOP.md
- ROADMAP.md
- TODO.md
- LEGACY.md
- FACTION_IDENTITY.md
- MVP_TEST_PLAN.md
- CHANGELOG.md

### Status

**CORREÇÃO DOCUMENTAL NECESSÁRIA**

O novo `PROJECT_INDEX.md` deve substituir a função de mapa operacional para o agente.

`PROJECT_STRUCTURE.md` deve posteriormente ser reduzido a uma única versão coerente.

---

# 12. REFERÊNCIAS AUSENTES

Algumas referências antigas permanecem:

- `COMBAT.md`
- `UNIT_TRAITS.md`
- `RECRUITMENT.md`
- `CLASSES.md`
- `TURN_SEQUENCE.md`
- `WEATHER.md`
- `PvP.md`
- `CAMPO_DE_PROVA.md`

A maior parte possui proprietário atual identificável:

- `COMBAT.md` → `COMBAT_CORE.md` / `COMBAT_RULES.md`
- `UNIT_TRAITS.md` → `ABILITIES.md`
- `RECRUITMENT.md` → `COMMAND_CENTER_RECRUITMENT.md`
- `TURN_SEQUENCE.md` → `COMBAT_RULES.md`
- `WEATHER.md` → `BATTLEFIELDS.md`

`PvP.md` continua sem um documento-umbrella explícito; para o MVP, seus domínios atuais estão distribuídos entre `MATCHMAKING.md` e `RANKING.md`.

Não criar arquivos fictícios apenas para satisfazer referências antigas.

---

# 13. CONCLUSÃO

A arquitetura pode agora ser transformada em um índice operacional para um agente de IA.

O próximo artefato deve ser `PROJECT_INDEX.md`, contendo:

- mapa dos 49 documentos;
- owner de cada domínio;
- tipo do documento;
- ordem de consulta;
- documentos que nunca devem ser tratados como SSOT;
- referências principais;
- regras críticas já decididas;
- decisões ainda abertas;
- protocolo de alteração documental.

Somente depois desse Index devemos criar `CLAUDE.md` e Skills.
