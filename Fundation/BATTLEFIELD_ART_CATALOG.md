# BATTLEFIELD_ART_CATALOG.md

> **Status:** CANÔNICO — PRODUÇÃO
>
> **Escopo:** catálogo oficial de todos os assets gráficos necessários para construir qualquer Battlefield do Battle Simulator.
>
> **Dependências:**
>
> - BATTLEFIELD_ART_BIBLE.md
> - DL_BATTLEFIELDS.md
> - WORLD_FOUNDATION.md
> - UI_ART_BIBLE.md
>
> **Objetivo:**
>
> Organizar toda a produção artística relacionada aos Battlefields.
>
> Este documento não produz Territórios.
>
> Os Territórios possuem catálogo próprio.

---

# 1. Filosofia

Este documento não define identidade artística.

Essa responsabilidade pertence ao **BATTLEFIELD_ART_BIBLE.md**.

Este catálogo existe para organizar toda a produção dos assets necessários para representar qualquer Battlefield do jogo.

Os assets aqui descritos representam sistemas reutilizáveis.

Sempre que possível, um único asset deverá ser utilizado em dezenas de Battlefields diferentes.

A reutilização possui prioridade absoluta sobre a produção de elementos exclusivos.

O artista nunca produz mapas.

O artista produz componentes.

O jogo monta os Battlefields.

---

# 2. Arquitetura

Todo Battlefield é construído pela combinação de módulos independentes.

Cada módulo possui responsabilidade única.

Nenhum módulo conhece os demais.

Essa arquitetura permite:

- reutilização;
- consistência visual;
- produção escalável;
- manutenção simplificada;
- expansão futura.

---

# 3. Relação com os Territórios

O Battlefield nunca substitui o Território.

O Território representa o ambiente permanente do mundo.

O Battlefield representa apenas as condições temporárias presentes durante aquele combate.

Ambos são renderizados simultaneamente.

O jogador jamais deve perceber a existência de dois sistemas distintos.

A composição final deve transmitir a sensação de um único cenário contínuo.

---

# 4. Organização dos Assets

Todos os assets pertencem obrigatoriamente a uma das seguintes categorias.

I. Base Terrain

II. Terrain Overlay

III. Lighting

IV. Weather

V. Environment

VI. Grid

VII. Battlefield FX

VIII. Battlefield Packages

---

# 5. Status dos Assets

Todo asset pertence obrigatoriamente a um dos estados abaixo.

Planejado

↓

Em Produção

↓

Em Revisão

↓

Aprovado

↓

Congelado

---

# 6. Prioridade

Todo asset recebe uma prioridade.

P0

Essencial para qualquer Battlefield.

P1

Necessário para identidade visual.

P2

Acabamento.

P3

Expansões futuras.

---

# 7. Tipos de Asset

Todo asset pertence obrigatoriamente a um destes grupos.

## STATIC

Assets permanentes.

Nunca possuem animação.

Exemplos:

- pedra;
- solo;
- texturas;
- decalques.

---

## ANIMATED

Assets animados.

Exemplos:

- chuva;
- água;
- folhas;
- fumaça;
- bandeiras.

---

## PROCEDURAL

Produzidos pela engine.

Exemplos:

- shaders;
- iluminação dinâmica;
- névoa;
- pós-processamento;
- reflexos.

---

## PACKAGE

Não possuem arte própria.

Representam apenas uma combinação de outros assets.

Exemplo:

Battlefield "Lua Cheia".

↓

Lighting_Moon

+

Fog_01

+

Moon_Shadow

+

Particles_03

---

# 8. Convenção de Nome

Todos os arquivos seguem obrigatoriamente o padrão.

CATEGORY_ELEMENT_VARIATION

Exemplos

BASE_TERRAIN_GRASS_01

WEATHER_RAIN_LIGHT

GRID_DEFAULT

LIGHTING_FULL_MOON

PACKAGE_OPEN_FIELD

Nunca utilizar:

- espaços;
- acentos;
- nomes genéricos.

---

# 9. Estrutura de Produção

Cada asset será registrado utilizando a seguinte ficha.

| Campo | Descrição |
|--------|-----------|
| Nome | Nome oficial |
| Código | Identificador único |
| Categoria | Família |
| Tipo | STATIC / ANIMATED / PROCEDURAL / PACKAGE |
| Prioridade | P0–P3 |
| Reutilização | Onde pode ser utilizado |
| Dependências | Assets relacionados |
| Status | Produção |
| Observações | Informações adicionais |

---

# 10. Pipeline de Renderização

Todo Battlefield é composto pelas seguintes camadas.

Layer 01

Sky

---

Layer 02

Far Background

---

Layer 03

Horizon

---

Layer 04

Territory

---

Layer 05

Battlefield

---

Layer 06

Grid

---

Layer 07

Platoons

---

Layer 08

Battlefield FX

---

Layer 09

UI

Cada layer possui responsabilidade única.

Nenhuma camada pode substituir outra.

A composição final deve transmitir um ambiente único e contínuo.

---

# 11. Modularidade

Todo asset produzido deve ser reutilizável.

Nenhum asset pode ser criado para um único mapa específico.

Sempre que possível:

um asset

↓

múltiplos Battlefields

↓

múltiplos Territórios

↓

múltiplos modos de jogo.

Essa filosofia orienta toda a produção artística do Battle Simulator.

---

# 12. Catálogo Oficial

As próximas seções representam a lista oficial de todos os assets necessários para produzir qualquer Battlefield do jogo.

Cada asset será produzido individualmente.

Nenhum Battlefield poderá utilizar elementos que não estejam previamente registrados neste catálogo.

# 13. Base Terrain

Representa o solo imediatamente abaixo do grid.

Todo Battlefield utiliza exatamente um Base Terrain principal.

O Base Terrain define a identidade física do local do combate.

Não inclui clima, iluminação ou efeitos temporários.

---

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Grama 01 | BASE_GRASS_01 | STATIC | P0 | Planejado |
| Grama 02 | BASE_GRASS_02 | STATIC | P0 | Planejado |
| Terra Compactada 01 | BASE_DIRT_01 | STATIC | P0 | Planejado |
| Terra Compactada 02 | BASE_DIRT_02 | STATIC | P0 | Planejado |
| Pedra 01 | BASE_STONE_01 | STATIC | P0 | Planejado |
| Pedra 02 | BASE_STONE_02 | STATIC | P0 | Planejado |
| Lama | BASE_MUD_01 | STATIC | P1 | Planejado |
| Areia | BASE_SAND_01 | STATIC | P1 | Planejado |
| Musgo | BASE_MOSS_01 | STATIC | P1 | Planejado |
| Cinzas Vulcânicas | BASE_ASH_01 | STATIC | P1 | Planejado |

---

# 14. Lighting

Define toda a iluminação local do Battlefield.

A iluminação nunca altera a identidade do Território.

Ela apenas modifica a percepção do ambiente.

---

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Luz Diurna | LIGHT_DAY | PROCEDURAL | P0 | Planejado |
| Amanhecer | LIGHT_DAWN | PROCEDURAL | P1 | Planejado |
| Entardecer | LIGHT_DUSK | PROCEDURAL | P1 | Planejado |
| Lua Cheia | LIGHT_FULL_MOON | PROCEDURAL | P1 | Planejado |
| Tempestade | LIGHT_STORM | PROCEDURAL | P1 | Planejado |
| Céu Nublado | LIGHT_OVERCAST | PROCEDURAL | P1 | Planejado |

---

# 15. Weather

Representa apenas fenômenos climáticos.

Nunca cria elementos permanentes do cenário.

---

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Sem Clima | WEATHER_CLEAR | PACKAGE | P0 | Planejado |
| Chuva Fraca | WEATHER_LIGHT_RAIN | ANIMATED | P0 | Planejado |
| Tempestade | WEATHER_STORM | ANIMATED | P0 | Planejado |
| Ventania | WEATHER_STRONG_WIND | ANIMATED | P0 | Planejado |

---

# 16. Environment

Assets vivos que enriquecem o ambiente.

Todos devem ser reutilizáveis.

Nenhum pertence exclusivamente a um único Battlefield.

---

## Água

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Água Corrente | ENV_WATER_FLOW | ANIMATED | P2 | Planejado |
| Água Parada | ENV_WATER_STILL | STATIC | P2 | Planejado |
| Reflexo | ENV_REFLECTION | PROCEDURAL | P2 | Planejado |

---

## Vegetação Dinâmica

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Capim Oscilando | ENV_GRASS_WIND | ANIMATED | P1 | Planejado |
| Folhas ao Vento | ENV_LEAVES_WIND | ANIMATED | P1 | Planejado |
| Pequenos Galhos | ENV_BRANCHES | ANIMATED | P2 | Planejado |

---

## Atmosfera

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Névoa Baixa | ENV_FOG_LOW | PROCEDURAL | P1 | Planejado |
| Névoa Densa | ENV_FOG_DENSE | PROCEDURAL | P1 | Planejado |
| Poeira | ENV_DUST | PROCEDURAL | P2 | Planejado |
| Cinzas | ENV_ASH | PROCEDURAL | P2 | Planejado |
| Partículas Arcanas | ENV_ARCANE | PROCEDURAL | P2 | Planejado |

---

# 17. Grid

O Grid representa exclusivamente o sistema tático.

Ele nunca pertence ao Território.

Ele nunca pertence ao Battlefield.

É uma camada lógica sobreposta ao terreno.

---

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Grid Base | GRID_DEFAULT | PROCEDURAL | P0 | Planejado |
| Hover | GRID_HOVER | PROCEDURAL | P0 | Planejado |
| Seleção | GRID_SELECTED | PROCEDURAL | P0 | Planejado |
| Alvo | GRID_TARGET | PROCEDURAL | P0 | Planejado |
| Alcance | GRID_RANGE | PROCEDURAL | P1 | Planejado |
| Área de Efeito | GRID_AREA | PROCEDURAL | P1 | Planejado |

---

# 18. Battlefield FX

Representam exclusivamente eventos do combate.

Nunca pertencem ao Território.

---

| Asset | Código | Tipo | Prioridade | Status |
|--------|---------|------|------------|--------|
| Impacto Pequeno | FX_HIT_SMALL | ANIMATED | P0 | Planejado |
| Impacto Médio | FX_HIT_MEDIUM | ANIMATED | P0 | Planejado |
| Impacto Grande | FX_HIT_LARGE | ANIMATED | P1 | Planejado |
| Crítico | FX_CRITICAL | ANIMATED | P1 | Planejado |
| Cura | FX_HEAL | ANIMATED | P1 | Planejado |
| Escudo | FX_SHIELD | ANIMATED | P1 | Planejado |
| Buff | FX_BUFF | ANIMATED | P1 | Planejado |
| Debuff | FX_DEBUFF | ANIMATED | P1 | Planejado |
| Invocação | FX_SUMMON | ANIMATED | P2 | Planejado |
| Eliminação | FX_DEATH | ANIMATED | P1 | Planejado |

---

# 19. Battlefield Packages

Os Packages não possuem arte própria.

Cada Package representa apenas uma composição oficial de assets previamente produzidos.

---

## Campo Aberto

Composição mínima:

- Base Terrain
- Luz Diurna
- Weather Clear
- Atmosfera mínima

---

## Ventania

Composição mínima:

- Base Terrain
- Strong Wind
- Folhas ao Vento
- Poeira

---

## Chuva Fraca

Composição mínima:

- Base Terrain
- Light Rain
- Reflexos
- Solo Úmido

---

## Tempestade

Composição mínima:

- Base Terrain
- Storm
- Raios
- Iluminação Tempestade
- Vento Forte

---

## Pântano

Composição mínima:

- Lama
- Água Parada
- Névoa Baixa

---

## Floresta

Composição mínima:

- Base Terrain
- Sombras Naturais
- Vegetação Dinâmica

---

## Vale

Composição mínima:

- Base Terrain
- Correntes de Vento
- Luz Natural

---

## Lua Cheia

Composição mínima:

- Luz Lua Cheia
- Sombras Longas
- Névoa Leve

---

## Terreno Vulcânico

Composição mínima:

- Cinzas
- Brilho Magmático
- Partículas Quentes

---

## Nevoeiro Arcano

Composição mínima:

- Névoa Densa
- Partículas Arcanas
- Luz Difusa

# 20. Dependências de Produção

A produção dos assets deverá obedecer obrigatoriamente à seguinte sequência.

Base Terrain

↓

Lighting

↓

Weather

↓

Environment

↓

Grid

↓

Battlefield FX

↓

Battlefield Packages

Nenhuma etapa posterior deverá iniciar antes da aprovação da anterior.

Essa sequência reduz retrabalho e garante consistência entre todos os Battlefields.

---

# 21. Pipeline de Produção

Todo Battlefield deverá ser desenvolvido seguindo o mesmo pipeline.

## Etapa 1

Produção dos assets base.

Exemplos:

- Base Terrain;
- iluminação;
- clima;
- atmosfera;
- grid.

---

## Etapa 2

Validação individual.

Cada asset deverá ser aprovado isoladamente antes de integrar qualquer Battlefield.

---

## Etapa 3

Integração.

Os assets aprovados passam a compor os Battlefield Packages.

Nenhum asset novo deve ser criado nesta etapa.

A integração utiliza exclusivamente assets previamente aprovados.

---

## Etapa 4

Validação do Package.

Verificar:

- consistência visual;
- integração com o Território;
- legibilidade;
- performance;
- clareza do combate.

---

## Etapa 5

Congelamento.

Após aprovado, o Package passa para o estado:

CONGELADO

Nenhuma alteração poderá ocorrer sem revisão documental.

---

# 22. Regras Gerais

Todo asset produzido deverá obedecer aos seguintes princípios.

## Modularidade

Cada asset deve ser reutilizável.

Nunca produzir arte destinada exclusivamente a um único Battlefield.

---

## Independência

Os assets nunca conhecem o Battlefield onde serão utilizados.

Eles representam apenas um componente reutilizável.

---

## Continuidade

Todo asset deve integrar-se naturalmente ao Território.

Nenhum elemento pode parecer artificialmente inserido.

---

## Escalabilidade

Novos Battlefields devem ser criados reutilizando os assets existentes.

A criação de novos assets ocorre apenas quando absolutamente necessária.

---

## Neutralidade

Os assets deste catálogo nunca pertencem a uma facção.

Toda identidade territorial pertence ao:

TERRITORY_ART_CATALOG.md

---

# 23. Estrutura dos Battlefield Packages

Cada Battlefield deverá possuir uma ficha própria.

---

## Template

| Campo | Conteúdo |
|--------|----------|
| Nome | Nome oficial |
| Categoria | Padrão, Climático, Geográfico ou Místico |
| Descrição | Conceito artístico |
| Assets Utilizados | Lista completa |
| Lighting | Asset utilizado |
| Weather | Asset utilizado |
| Environment | Assets utilizados |
| Battlefield FX | Assets utilizados |
| Observações | Informações adicionais |
| Status | Produção |

---

# 24. Checklist de Aprovação

Antes de aprovar qualquer Battlefield verificar.

## Integração

- [ ] O Battlefield integra-se naturalmente ao Território.
- [ ] Não existe quebra visual entre Battlefield e Território.
- [ ] O cenário transmite continuidade.

---

## Clareza

- [ ] O grid permanece claramente identificável.
- [ ] Os pelotões permanecem protagonistas.
- [ ] A leitura do combate permanece imediata.

---

## Consistência

- [ ] Todos os assets pertencem ao catálogo oficial.
- [ ] Nenhum asset exclusivo foi criado sem documentação.
- [ ] O Battlefield respeita a BATTLEFIELD_ART_BIBLE.

---

## Performance

- [ ] Quantidade de partículas adequada.
- [ ] Quantidade de animações adequada.
- [ ] Quantidade de shaders adequada.
- [ ] Sem sobreposição visual excessiva.

---

## Produção

- [ ] Todos os assets utilizados estão aprovados.
- [ ] O Package foi documentado.
- [ ] O Package foi congelado.

---

# 25. Convenções de Produção

Todo asset deverá possuir obrigatoriamente.

- Nome oficial;
- Código;
- Categoria;
- Tipo;
- Prioridade;
- Status;
- Autor;
- Data;
- Versão;
- Prompt utilizado;
- Arquivo fonte;
- Arquivo final.

---

# 26. Estrutura de Pastas

Sugestão oficial de organização.

```text
ART/

└── Battlefield/

      ├── BaseTerrain/

      ├── Lighting/

      ├── Weather/

      ├── Environment/

      ├── Grid/

      ├── BattlefieldFX/

      ├── Packages/

      └── References/
```

---

# 27. Relação com Outros Catálogos

Este documento produz exclusivamente os assets relacionados ao Battlefield.

Não produz:

- Territórios;
- Interface;
- Cartas;
- Pelotões;
- Comandantes;
- Construções.

Esses elementos pertencem aos seus respectivos catálogos.

---

# 28. Regra Final

O Battle Simulator nunca produz mapas individuais.

Ele produz sistemas reutilizáveis.

Cada Battlefield é uma composição de assets previamente aprovados.

Essa arquitetura garante:

- reutilização;
- consistência artística;
- facilidade de manutenção;
- expansão contínua do jogo.

Todo novo Battlefield deverá surgir da combinação dos sistemas existentes sempre que possível.

A criação de novos assets é exceção.

A reutilização é a regra.