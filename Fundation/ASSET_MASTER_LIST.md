# ASSET MASTER LIST

> Inventário mestre inicial do Battle Simulator. Esta versão registra o que já
> existe no acervo e organiza a auditoria futura; ela **não cria assets novos
> por suposição**.

## Como usar este arquivo

- Um asset só entra como **Confirmado** depois de ser encontrado em uma imagem,
  documento ou arquivo do jogo.
- Todo item confirmado deve apontar sua origem na coluna `Fontes`.
- Use `A extrair` quando o grupo já é conhecido, mas seus itens ainda precisam
  ser lidos nos documentos ou conferidos visualmente.
- Use `Candidato` apenas para itens levantados na auditoria; ele não entra em
  produção antes de ser fundamentado.

| Status | Significado |
|---|---|
| Confirmado | Existe no acervo ou foi especificado explicitamente. |
| A extrair | Há fontes disponíveis, mas os assets individuais ainda não foram catalogados. |
| Em produção | Brief aprovado; ainda precisa ser produzido ou finalizado. |
| Pronto | Asset final disponível para o jogo. |
| Candidato | Possível lacuna; aguarda comprovação em uma fonte. |

## Fontes já mapeadas (sem análise de conteúdo)

### Acervo visual

O diretório `Imagens/` contém, nesta primeira contagem, **166 arquivos** em 15
coleções. A contagem é um retrato do acervo atual, não uma meta de produção.

| Coleção | Arquivos | Papel inicial |
|---|---:|---|
| Atmosféra | 2 | Referências de clima, luz e atmosfera. |
| Botânica | 22 | Vegetação e biomas. |
| Campos de batalha | 16 | Terreno e composição de campos de batalha. |
| Canônicos | 30 | Referências visuais canônicas do projeto. |
| Facções | 13 | Linguagem visual geral das facções. |
| Fauna | 3 | Criaturas e fauna ambiental. |
| Guia de ilustraçao | 13 | Direção e padrão de ilustração. |
| Império | 13 | Referências específicas do Império. |
| Mapa | 2 | Mapa e visão de mundo. |
| Materiais resistentes | 10 | Materiais e superfícies. |
| Moldura das cartas | 7 | Molduras e componentes de cartas. |
| Morto vivo | 13 | Referências específicas dos Mortos-Vivos. |
| Natureza | 14 | Referências específicas da facção Natureza. |
| Reino | 4 | Reino, cidades ou visão macro. |
| UI | 17 | Interface e componentes visuais. |

### Documentação de arte e produção

`ART_BIBLE.MD`, `ASSET_PRODUCTION_BIBLE.md`, `BATTLEFIELD_ART_BIBLE.md`,
`BATTLEFIELD_ART_CATALOG.md`, `CAMERA_ART_BIBLE.md`, `CARD_ART_BIBLE.md`,
`CARD_ART_CATALOG.md`, `CARD_ICONOGRAPHY.md`, `CARD_LAYOUT_BIBLE.md`,
`ICON_CATALOG.md`, `UI_ART_BIBLE.md` e `WORLD FOUNDATION (DRAFT).md`.

### Documentação de design que fundamenta assets

Inclui fundações, facções, regiões, campos de batalha, cartas, comandantes,
capital, academia, centro de comando, depósitos, minas, núcleo de energia,
navegação e mapas, além da documentação de arquitetura do jogo.

## Estrutura mestre

| ID | Bloco | Estado | Fontes iniciais |
|---|---|---|---|
| 01 | Gameplay | A extrair | FOUNDATIONS, regras de combate, habilidades, unidades. |
| 02 | Mundo | A extrair | WORLD FOUNDATION, regiões, mapa, battlefields. |
| 03 | Facções | A extrair | FACTION_*, Facções, Império, Morto vivo, Natureza. |
| 04 | Construções | A extrair | capital, Centro de comando, Depósitos, Minas, Núcleo de energia. |
| 05 | Recursos | A extrair | FUNDAMENTO I–III, recursos, depósitos e minas. |
| 06 | Vegetação | A extrair | Botânica, Natureza, regiões e battlefields. |
| 07 | Geologia | A extrair | Materiais resistentes, minas, recursos e battlefields. |
| 08 | Estradas | A extrair | Mundo, regiões, capital, navegação e mapas. |
| 09 | Cenários | A extrair | Campos de batalha, regiões, atmosfera e mundo. |
| 10 | Props | A extrair | Construções, regiões, recursos e campos de batalha. |
| 11 | FX | A extrair | Direção de arte, combate, habilidades e recursos. |
| 12 | UI | A extrair | UI_ART_BIBLE, DL_NAVIGATION, DL_MINES e Centro de comando. |
| 13 | Cartas | A extrair | CARD_*, DL_CARDS_FOUNDATION e catalogo de cartas. |
| 14 | Ícones | A extrair | ICON_CATALOG e CARD_ICONOGRAPHY. |
| 15 | Retratos | A extrair | COMMANDERS, facções e guias de ilustração. |
| 16 | Áudio | A extrair | Documentação de design; ainda sem coleção visual correspondente. |
| 17 | VFX | A extrair | Combate, habilidades, recursos e direção de arte. |
| 18 | Animações | A extrair | Unidades, comandantes, combate e interface. |

## Registro de assets

Os registros individuais serão inseridos aqui por lote. Formato padrão:

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| Ex.: `UI-ICO-001` | Ícone de ferro negro | Ícones | 2D | Global | Confirmado | ICON_CATALOG; FUNDAMENTO I | Nome final e variantes a definir. |

## Lote 01 — Mundo, terreno e campo de batalha

Este lote foi extraído da lista oficial de `BATTLEFIELD_ART_CATALOG.md` e dos
três documentos regionais. `Confirmado` significa que a necessidade foi
especificada; todos os itens abaixo continuam **planejados para produção** até
que um arquivo final seja associado a eles.

### Terreno, luz e clima

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| TER-BASE-001 | Grama 01 | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_GRASS_01`, P0. |
| TER-BASE-002 | Grama 02 | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_GRASS_02`, P0. |
| TER-BASE-003 | Terra compactada 01 | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_DIRT_01`, P0. |
| TER-BASE-004 | Terra compactada 02 | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_DIRT_02`, P0. |
| TER-BASE-005 | Pedra 01 | Geologia | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_STONE_01`, P0. |
| TER-BASE-006 | Pedra 02 | Geologia | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_STONE_02`, P0. |
| TER-BASE-007 | Lama | Cenários | Static | Pântano | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_MUD_01`, P1. |
| TER-BASE-008 | Areia | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_SAND_01`, P1. |
| TER-BASE-009 | Musgo de solo | Vegetação | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_MOSS_01`, P1. |
| TER-BASE-010 | Cinzas vulcânicas | Geologia | Static | Vulcânico | Confirmado | BATTLEFIELD_ART_CATALOG | `BASE_ASH_01`, P1. |
| ATM-LGT-001 | Luz diurna | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_DAY`, P0. |
| ATM-LGT-002 | Amanhecer | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_DAWN`, P1. |
| ATM-LGT-003 | Entardecer | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_DUSK`, P1. |
| ATM-LGT-004 | Luz de lua cheia | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_FULL_MOON`, P1. |
| ATM-LGT-005 | Iluminação de tempestade | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_STORM`, P1. |
| ATM-LGT-006 | Céu nublado | Cenários | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `LIGHT_OVERCAST`, P1. |
| ATM-WTH-001 | Sem clima | Cenários | Package | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `WEATHER_CLEAR`, P0. |
| ATM-WTH-002 | Chuva fraca | FX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `WEATHER_LIGHT_RAIN`, P0. |
| ATM-WTH-003 | Tempestade | FX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `WEATHER_STORM`, P0. |
| ATM-WTH-004 | Ventania | FX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `WEATHER_STRONG_WIND`, P0. |

### Ambiente vivo e atmosfera

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| ENV-WAT-001 | Água corrente | Cenários | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_WATER_FLOW`, P2. |
| ENV-WAT-002 | Água parada | Cenários | Static | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_WATER_STILL`, P2. |
| ENV-WAT-003 | Reflexo na água | FX | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_REFLECTION`, P2. |
| VEG-DYN-001 | Capim oscilando | Vegetação | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_GRASS_WIND`, P1. |
| VEG-DYN-002 | Folhas ao vento | Vegetação | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_LEAVES_WIND`, P1. |
| VEG-DYN-003 | Pequenos galhos ao vento | Vegetação | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_BRANCHES`, P2. |
| ATM-FX-001 | Névoa baixa | FX | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_FOG_LOW`, P1. |
| ATM-FX-002 | Névoa densa | FX | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_FOG_DENSE`, P1. |
| ATM-FX-003 | Poeira | FX | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_DUST`, P2. |
| ATM-FX-004 | Cinzas no ar | FX | Procedural | Vulcânico | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_ASH`, P2. |
| ATM-FX-005 | Partículas arcanas | FX | Procedural | Mortos-Vivos | Confirmado | BATTLEFIELD_ART_CATALOG | `ENV_ARCANE`, P2. |

### Camadas táticas e efeitos de combate

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| UI-GRID-001 | Grid base | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG; DL_BATTLEFIELDS | `GRID_DEFAULT`, P0; grade canônica 3×3. |
| UI-GRID-002 | Estado hover do grid | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `GRID_HOVER`, P0. |
| UI-GRID-003 | Estado selecionado do grid | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `GRID_SELECTED`, P0. |
| UI-GRID-004 | Estado alvo do grid | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `GRID_TARGET`, P0. |
| UI-GRID-005 | Indicador de alcance | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `GRID_RANGE`, P1. |
| UI-GRID-006 | Indicador de área de efeito | UI | Procedural | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `GRID_AREA`, P1. |
| VFX-BTL-001 | Impacto pequeno | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_HIT_SMALL`, P0. |
| VFX-BTL-002 | Impacto médio | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_HIT_MEDIUM`, P0. |
| VFX-BTL-003 | Impacto grande | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_HIT_LARGE`, P1. |
| VFX-BTL-004 | Crítico | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_CRITICAL`, P1. |
| VFX-BTL-005 | Cura | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_HEAL`, P1. |
| VFX-BTL-006 | Escudo | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_SHIELD`, P1. |
| VFX-BTL-007 | Buff | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_BUFF`, P1. |
| VFX-BTL-008 | Debuff | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_DEBUFF`, P1. |
| VFX-BTL-009 | Invocação | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_SUMMON`, P2. |
| VFX-BTL-010 | Eliminação | VFX | Animated | Global | Confirmado | BATTLEFIELD_ART_CATALOG | `FX_DEATH`, P1. |

### Elementos regionais confirmados

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| IMP-HYD-001 | Aqueduto | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Infraestrutura hidráulica regional. |
| IMP-HYD-002 | Canal construído | Cenários | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Água conduzida. |
| IMP-HYD-003 | Reservatório | Construções | 3D | Império | Confirmado | REGIÃO IMPÉRIO | Infraestrutura regional. |
| IMP-HYD-004 | Pequena barragem | Construções | 3D | Império | Confirmado | REGIÃO IMPÉRIO | Infraestrutura regional. |
| IMP-VEG-001 | Jardim geométrico | Vegetação | Kit 3D | Império | Confirmado | REGIÃO IMPÉRIO | Vegetação organizada. |
| IMP-VEG-002 | Bosque planejado | Vegetação | Kit 3D | Império | Confirmado | REGIÃO IMPÉRIO | Árvores espaçadas. |
| IMP-ARC-001 | Posto imperial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Arquitetura regional. |
| IMP-ARC-002 | Fazenda imperial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Associada a campos agrícolas. |
| IMP-ARC-003 | Oficina imperial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Variante regional e de acampamento. |
| IMP-ARC-004 | Ponte imperial | Estradas | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Arquitetura regional. |
| IMP-ARC-005 | Torre imperial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Arquitetura regional e acampamento. |
| IMP-ARC-006 | Muralha imperial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Variante parcial para acampamento. |
| IMP-CMP-001 | Portão de acampamento | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Acampamento imperial. |
| IMP-CMP-002 | Paliçada parcial | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Acampamento imperial. |
| IMP-CMP-003 | Quartel temporário | Construções | Modular 3D | Império | Confirmado | REGIÃO IMPÉRIO | Acampamento imperial. |
| IMP-PRP-001 | Carroça de materiais | Props | 3D | Império | Confirmado | REGIÃO IMPÉRIO | Atividade regional. |
| UND-ARC-001 | Observatório | Construções | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-ARC-002 | Biblioteca | Construções | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-ARC-003 | Pequeno santuário | Construções | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-ARC-004 | Torre de estudo | Construções | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-ARC-005 | Ponte de pedra | Estradas | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-ARC-006 | Plataforma de observação | Construções | Modular 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Arquitetura regional. |
| UND-GEO-001 | Formação cristalina natural | Geologia | 3D | Mortos-Vivos | Confirmado | REGIÃO MORTOS-VIVOS | Cristais Arcanos no ambiente. |
| NAT-VEG-001 | Árvore antiga com raízes expostas | Vegetação | 3D | Natureza | Confirmado | REGIÃO NATUREZA | Elemento principal de silhueta. |
| NAT-VEG-002 | Arbusto | Vegetação | 3D | Natureza | Confirmado | REGIÃO NATUREZA | Kit de vegetação. |
| NAT-VEG-003 | Samambaia | Vegetação | 3D | Natureza | Confirmado | REGIÃO NATUREZA | Kit de vegetação. |
| NAT-VEG-004 | Flor discreta | Vegetação | 3D | Natureza | Confirmado | REGIÃO NATUREZA | Kit de vegetação; sem excesso de cor. |
| NAT-ARC-001 | Casa integrada à árvore | Construções | Modular 3D | Natureza | Confirmado | REGIÃO NATUREZA | Arquitetura regional. |
| NAT-ARC-002 | Plataforma sobre raízes | Construções | Modular 3D | Natureza | Confirmado | REGIÃO NATUREZA | Arquitetura regional. |
| NAT-ARC-003 | Passarela de madeira | Estradas | Modular 3D | Natureza | Confirmado | REGIÃO NATUREZA | Arquitetura regional. |
| NAT-ARC-004 | Ponte leve de madeira | Estradas | Modular 3D | Natureza | Confirmado | REGIÃO NATUREZA | Trilhas e acampamento. |
| NAT-ARC-005 | Jardim funcional / horta | Vegetação | Kit 3D | Natureza | Confirmado | REGIÃO NATUREZA | Região e acampamento. |
| NAT-RES-001 | Canal natural de Essência Vital | Cenários | Animated / VFX | Natureza | Confirmado | REGIÃO NATUREZA | Fluxo contínuo, não deve parecer magia excessiva. |
| NAT-CMP-001 | Cozinha aberta | Construções | Modular 3D | Natureza | Confirmado | REGIÃO NATUREZA | Acampamento da Natureza. |
| NAT-CMP-002 | Reservatório pequeno de Essência Vital | Construções | 3D | Natureza | Confirmado | REGIÃO NATUREZA | Acampamento da Natureza. |

## Lote 02 — Construções, recursos e infraestrutura

Este lote provém de documentos congelados de construções, das diretrizes de
minas e dos três Fundamentos. Como no lote anterior, os registros são
necessidades confirmadas, mas não atestam que a arte final já exista.

### Construções do Reino

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| CAP-BLD-001 | Capital do Reino | Construções | Kit modular 3D | Reino | Confirmado | capital | Construção única que integra os três Fundamentos; crescimento lateral por adição. |
| CAP-STR-001 | Fundação de Ferro Negro | Construções | Modular 3D | Reino | Confirmado | capital; FUNDAMENTO I FERRO NEGRO | Componente estrutural da Capital. |
| CAP-STR-002 | Coluna de Ferro Negro | Construções | Modular 3D | Reino | Confirmado | capital | Componente estrutural da Capital. |
| CAP-STR-003 | Muralha de Ferro Negro | Construções | Modular 3D | Reino | Confirmado | capital | Variante estrutural da Capital. |
| CAP-STR-004 | Portão de Ferro Negro | Construções | Modular 3D | Reino | Confirmado | capital | Variante estrutural da Capital. |
| CAP-STR-005 | Torre de Ferro Negro | Construções | Modular 3D | Reino | Confirmado | capital | Variante estrutural da Capital. |
| CAP-ENE-001 | Iluminação por Cristais Arcanos | FX | 3D / Procedural | Reino | Confirmado | capital | Uso discreto; não deve parecer excessivo. |
| CAP-ENE-002 | Mecanismo energético arcano | Construções | 3D / Procedural | Reino | Confirmado | capital | Estrutura tecnológica da Capital. |
| CAP-VIT-001 | Fonte com Essência Vital | Cenários | 3D / Animated | Reino | Confirmado | capital | Água/Essência integrada às praças. |
| CAP-VIT-002 | Curso de Essência Vital | Cenários | 3D / Animated | Reino | Confirmado | capital | Vegetação integrada à Capital. |
| CMD-BLD-001 | Centro de Comando | Construções | Kit modular 3D | Reino | Confirmado | Centro de comando | Estrutura principal de coordenação; expande por novas alas e pátios. |
| CMD-INT-001 | Salão dos Comandantes | Construções | Interior 3D | Reino | Confirmado | Centro de comando | Espaço do Legado. |
| CMD-PRP-001 | Bandeira histórica | Props | 3D / 2D | Reino | Confirmado | Centro de comando | Parte do Legado. |
| CMD-PRP-002 | Brasão do Reino | Props | 2D / 3D | Reino | Confirmado | Centro de comando | Parte do Legado. |
| CMD-PRP-003 | Mapa antigo | Props | 2D / 3D | Reino | Confirmado | Centro de comando | Parte do Legado. |
| CMD-PRP-004 | Arma preservada | Props | 3D | Reino | Confirmado | Centro de comando | Parte do Legado. |
| CMD-PRP-005 | Escudo preservado | Props | 3D | Reino | Confirmado | Centro de comando | Parte do Legado. |
| CMD-INT-002 | Mesa de planejamento | Props | 3D | Reino | Confirmado | Centro de comando | Coordenação e estratégia. |
| CMD-INT-003 | Sala de estratégia | Construções | Interior 3D | Reino | Confirmado | Centro de comando | Coordenação e estratégia. |
| CMD-EXT-001 | Pátio central | Construções | Kit modular 3D | Reino | Confirmado | Centro de comando | Operações, treino e expedições. |
| CMD-EXT-002 | Área de montarias | Construções | Kit modular 3D | Reino | Confirmado | Centro de comando | Abriga montarias quando não acompanham comandantes. |
| DEP-BLD-001 | Complexo de depósitos | Construções | Kit modular 3D | Reino | Confirmado | Depósitos | Crescimento horizontal; materiais comuns, não Fundamentos na estrutura. |
| DEP-BLD-002 | Galpão de armazenamento | Construções | Modular 3D | Reino | Confirmado | Depósitos | Expansão logística. |
| DEP-BLD-003 | Silo | Construções | Modular 3D | Reino | Confirmado | Depósitos | Expansão logística. |
| DEP-BLD-004 | Pátio de carga e descarga | Construções | Kit modular 3D | Reino | Confirmado | Depósitos | Área operacional. |
| DEP-PRP-001 | Pilha de caixas | Props | 3D | Reino | Confirmado | Depósitos; DL_MINES | Prop logístico reutilizável. |
| DEP-PRP-002 | Madeira organizada | Props | 3D | Reino | Confirmado | Depósitos | Material comum em estoque. |
| DEP-PRP-003 | Pedra preparada | Props | 3D | Reino | Confirmado | Depósitos | Material comum em estoque. |
| DEP-RES-001 | Carga de Ferro Negro | Recursos | 3D | Reino | Confirmado | Depósitos | Armazenado e transportado; não decorativo. |
| DEP-RES-002 | Recipiente de Cristais Arcanos | Recursos | 3D | Reino | Confirmado | Depósitos | Contenção e armazenamento especializado. |
| DEP-RES-003 | Reservatório de Essência Vital | Recursos | 3D / Animated | Reino | Confirmado | Depósitos | Deve preservar o movimento da Essência. |
| NRG-BLD-001 | Núcleo de Energia | Construções | Kit modular 3D | Reino | Confirmado | Núcleo de energia | Edifício construído ao redor do Núcleo; evolução por refinamento. |
| NRG-RES-001 | Cristal Arcano estabilizado central | Recursos | 3D / Procedural | Reino | Confirmado | Núcleo de energia; FUNDAMENTO II CRISTAIS ARCANOS | Centro energético da construção. |
| NRG-FX-001 | Névoa arcana constante | VFX | Procedural | Reino | Confirmado | Núcleo de energia; FUNDAMENTO II CRISTAIS ARCANOS | Emana do cristal e nunca é consumida. |
| NRG-FX-002 | Padrão geométrico efêmero na névoa | VFX | Procedural | Reino | Confirmado | Núcleo de energia; FUNDAMENTO II CRISTAIS ARCANOS | Não usar letras, palavras ou runas legíveis. |
| NRG-RES-002 | Canal integrado de Essência Vital | Cenários | 3D / Animated | Reino | Confirmado | Núcleo de energia; FUNDAMENTO III ESSÊNCIA VITAL | Fluxo contínuo que equilibra o Núcleo. |

### Recursos e Fontes Primordiais

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| RES-IRN-001 | Fonte Primordial de Ferro Negro exposta | Recursos | Cenário 3D | Império | Confirmado | FUNDAMENTO I FERRO NEGRO | Estrutura do planeta acessível; não é uma jazida convencional. |
| RES-IRN-002 | Ferro Negro incorporado | Recursos | Material / 3D | Império | Confirmado | FUNDAMENTO I FERRO NEGRO | Preto, fosco, liso, pesado e não corrosivo; uso estrutural. |
| RES-IRN-003 | Superfície de Ferro Negro sob luz direta | Materiais | Shader / Material | Império | Confirmado | FUNDAMENTO I FERRO NEGRO | Enquanto ligado ao planeta, revela profundidade em camadas; não deve parecer brilhante. |
| RES-ARC-001 | Par de Fontes Primordiais de névoa | Recursos | Cenário 3D / VFX | Mortos-Vivos | Confirmado | FUNDAMENTO II CRISTAIS ARCANOS | As duas fontes devem coexistir para a cristalização. |
| RES-ARC-002 | Cristal Arcano instável | Recursos | 3D / VFX | Mortos-Vivos | Confirmado | FUNDAMENTO II CRISTAIS ARCANOS | Estrutura temporária gerada na névoa sob Luz. |
| RES-ARC-003 | Cristal Arcano estabilizado | Recursos | 3D / VFX | Mortos-Vivos | Confirmado | FUNDAMENTO II CRISTAIS ARCANOS | Transparência parcial, interior em movimento e emissão contínua de névoa. |
| RES-ARC-004 | Névoa Arcana organizada | VFX | Procedural | Mortos-Vivos | Confirmado | FUNDAMENTO II CRISTAIS ARCANOS | Padrões geométricos complexos, sem linguagem legível. |
| RES-VIT-001 | Fonte Primordial de Essência Vital | Recursos | Cenário 3D / Animated | Natureza | Confirmado | FUNDAMENTO III ESSÊNCIA VITAL | Surge entre grandes formações rochosas e parece uma nascente. |
| RES-VIT-002 | Fluxo de Essência Vital | Recursos | 3D / Animated | Natureza | Confirmado | FUNDAMENTO III ESSÊNCIA VITAL | Líquido prateado translúcido; nunca imóvel. |
| RES-VIT-003 | Condutor de Essência Vital | Construções | Modular 3D | Natureza | Confirmado | FUNDAMENTO III ESSÊNCIA VITAL | Deve acompanhar o fluxo natural, não o forçar. |
| RES-VIT-004 | Reservatório vivo de Essência Vital | Construções | 3D / Animated | Natureza | Confirmado | FUNDAMENTO III ESSÊNCIA VITAL | A Essência continua fluindo dentro do recipiente. |

### Minas e operação logística

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| MIN-IRN-001 | Mina principal de Ferro Negro | Construções | Kit modular 3D | Império | Confirmado | DL_MINES; FUNDAMENTO I FERRO NEGRO | Grande corte aberto na paisagem; sem túneis profundos. |
| MIN-IRN-002 | Plataforma de mineração pesada | Construções | Modular 3D | Império | Confirmado | DL_MINES | Kit da mina de Ferro Negro. |
| MIN-IRN-003 | Elevador de mina | Construções | Modular 3D | Império | Confirmado | DL_MINES | Kit da mina de Ferro Negro. |
| MIN-IRN-004 | Guindaste de mina | Construções | Modular 3D | Império | Confirmado | DL_MINES | Kit da mina de Ferro Negro. |
| MIN-IRN-005 | Escada industrial | Construções | Modular 3D | Império | Confirmado | DL_MINES | Kit da mina de Ferro Negro. |
| MIN-ARC-001 | Mina principal de Cristais Arcanos | Construções | Kit modular 3D | Mortos-Vivos | Confirmado | DL_MINES | Estruturas discretas de estudo e contenção. |
| MIN-ARC-002 | Laboratório de estabilização | Construções | Modular 3D | Mortos-Vivos | Confirmado | DL_MINES; FUNDAMENTO II CRISTAIS ARCANOS | Pesquisa e aquecimento controlado. |
| MIN-ARC-003 | Estrutura de contenção arcana | Construções | Modular 3D | Mortos-Vivos | Confirmado | DL_MINES | Kit da mina de Cristais Arcanos. |
| MIN-ARC-004 | Equipamento de pesquisa arcana | Props | 3D | Mortos-Vivos | Confirmado | DL_MINES | Kit da mina de Cristais Arcanos. |
| MIN-VIT-001 | Fonte principal de Essência Vital | Construções | Kit modular 3D | Natureza | Confirmado | DL_MINES; FUNDAMENTO III ESSÊNCIA VITAL | Área de coleta ao redor da Fonte; não é mineração. |
| MIN-VIT-002 | Área de coleta de Essência Vital | Construções | Kit modular 3D | Natureza | Confirmado | DL_MINES | Infraestrutura adaptada ao fluxo. |
| MIN-REG-001 | Kit modular de mina regional | Construções | Kit modular 3D | Global | Confirmado | DL_MINES | Base para evolução por adição, preservando a identidade regional. |
| MIN-REG-002 | Caixa de operação | Props | 3D | Global | Confirmado | DL_MINES | Prop operacional reutilizável. |
| MIN-REG-003 | Ferramentas de operação | Props | 3D | Global | Confirmado | DL_MINES | Prop operacional; variantes por fundação podem ser definidas depois. |
| MIN-REG-004 | Iluminação operacional de mina | FX | 3D / Procedural | Global | Confirmado | DL_MINES | Componente modular de evolução. |

### Ponto de decisão registrado

`Núcleo de energia.md` descreve a formação ocasional de “runas” na névoa,
enquanto `FUNDAMENTO II CRISTAIS ARCANOS.md` proíbe letras, palavras e linguagem,
definindo esses sinais como padrões geométricos sem significado linguístico.
O registro `NRG-FX-002` segue a regra mais específica do Fundamento: padrões
efêmeros e não legíveis. Se “runas” for um termo visual desejado, a documentação
do Núcleo deve ser ajustada antes da produção.

## Lote 03 — Facções, comandantes e pelotões

Este lote registra kits reutilizáveis. Os documentos definem claramente a
linguagem visual por facção, mas ainda não estabelecem uma lista de armas,
classes de unidade ou espécies de montaria individuais. Esses detalhes ficam
deliberadamente como itens a extrair em um catálogo posterior.

### Kits visuais das facções

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| IMP-ID-001 | Bandeira imperial | Props | 2D / 3D Animated | Império | Confirmado | FACTION_IMPÉRIO | Grande, pesada, com poucos símbolos e leitura a distância. |
| IMP-ID-002 | Kit de armadura imperial | Gameplay | Kit 3D | Império | Confirmado | FACTION_IMPÉRIO; BATTLE PLATOONS | Espessa, com Ferro Negro e poucas partes móveis. |
| IMP-ID-003 | Kit de armas imperiais | Gameplay | Kit 3D | Império | Confirmado | FACTION_IMPÉRIO; BATTLE PLATOONS | Confiável e equilibrado; modelos específicos pendentes. |
| IMP-ID-004 | Kit de escudos imperiais | Gameplay | Kit 3D | Império | Confirmado | FACTION_IMPÉRIO; BATTLE PLATOONS | Grandes, retangulares ou levemente arredondados. |
| IMP-ID-005 | Kit de ferramentas imperiais | Props | Kit 3D | Império | Confirmado | FACTION_IMPÉRIO | Projetado para longa durabilidade. |
| IMP-ID-006 | Carruagem robusta | Props | 3D | Império | Confirmado | FACTION_IMPÉRIO | Alta capacidade, baixa velocidade. |
| IMP-ID-007 | Animal de carga imperial | Fauna | 3D / Animated | Império | A extrair | FACTION_IMPÉRIO | Necessário para o transporte; espécie e aparência não definidas. |
| IMP-ID-008 | Kit de estrada imperial | Estradas | Kit modular 3D | Império | Confirmado | FACTION_IMPÉRIO | Grandes blocos, traçado reto, drenagem planejada e pequenas pontes. |
| UND-ID-001 | Bandeira dos Mortos-Vivos | Props | 2D / 3D Animated | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS | Tecido leve, pouco movimento, símbolos simples e alto contraste. |
| UND-ID-002 | Kit de armadura dos Mortos-Vivos | Gameplay | Kit 3D | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS; BATTLE PLATOONS | Elegante, precisa e sem elementos supérfluos. |
| UND-ID-003 | Kit de armas dos Mortos-Vivos | Gameplay | Kit 3D | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS; BATTLE PLATOONS | Precisão e aperfeiçoamento acima de força bruta. |
| UND-ID-004 | Kit de escudos dos Mortos-Vivos | Gameplay | Kit 3D | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS; BATTLE PLATOONS | Compacto e funcional. |
| UND-ID-005 | Kit de ferramentas especializadas | Props | Kit 3D | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS | Uma finalidade clara por ferramenta. |
| UND-ID-006 | Transporte dos Mortos-Vivos | Props | Kit 3D / Animated | Mortos-Vivos | A extrair | FACTION_MORTOS_VIVOS | Deve comunicar eficiência silenciosa; veículo e criatura não definidos. |
| UND-ID-007 | Kit de estrada dos Mortos-Vivos | Estradas | Kit modular 3D | Mortos-Vivos | Confirmado | FACTION_MORTOS_VIVOS | Cascalho compacto e lajes reaproveitadas, com traçado funcional. |
| NAT-ID-001 | Bandeira da Natureza | Props | 2D / 3D Animated | Natureza | Confirmado | FACTION_NATUREZA | Tecido leve em movimento, símbolos inspirados na natureza. |
| NAT-ID-002 | Kit de armadura da Natureza | Gameplay | Kit 3D | Natureza | Confirmado | FACTION_NATUREZA; BATTLE PLATOONS | Leve e móvel, com proteção suficiente. |
| NAT-ID-003 | Kit de armas da Natureza | Gameplay | Kit 3D | Natureza | Confirmado | FACTION_NATUREZA; BATTLE PLATOONS | Elegante, preciso, pouco material e eficiente. |
| NAT-ID-004 | Kit de escudos da Natureza | Gameplay | Kit 3D | Natureza | Confirmado | FACTION_NATUREZA; BATTLE PLATOONS | Pequeno e leve; redireciona impactos. |
| NAT-ID-005 | Kit de ferramentas versáteis | Props | Kit 3D | Natureza | Confirmado | FACTION_NATUREZA | Uma ferramenta pode atender a várias funções. |
| NAT-ID-006 | Pequena embarcação natural | Props | 3D | Natureza | Confirmado | FACTION_NATUREZA | Transporte regional; detalhes de design a extrair. |
| NAT-ID-007 | Animal ágil de transporte | Fauna | 3D / Animated | Natureza | A extrair | FACTION_NATUREZA | Espécie e aparência não definidas. |
| NAT-ID-008 | Kit de estrada da Natureza | Estradas | Kit modular 3D | Natureza | Confirmado | FACTION_NATUREZA | Terra batida, pedras naturais, raízes, curvas suaves e desvios por árvores antigas. |

### Comandantes e retratos procedurais

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| CMD-GEN-001 | Malha-base de comandante | Retratos | Personagem 3D | Global | Confirmado | COMMANDERS | Base do gerador procedural; deve preservar coerência biológica. |
| CMD-GEN-002 | Presets de rosto | Retratos | Kit 3D / 2D | Global | Confirmado | COMMANDERS | Formato do rosto, olhos, nariz, boca e mandíbula. |
| CMD-GEN-003 | Presets de tom de pele | Retratos | Material | Global | Confirmado | COMMANDERS | Camada biológica. |
| CMD-GEN-004 | Kit de cabelo e sobrancelhas | Retratos | Kit 3D / 2D | Global | Confirmado | COMMANDERS | Camada biológica. |
| CMD-GEN-005 | Kit de barba | Retratos | Kit 3D / 2D | Global | Confirmado | COMMANDERS | Aplicável apenas a personagens masculinos, conforme documento. |
| CMD-GEN-006 | Kit de cicatrizes | Retratos | Decal / Material | Global | Confirmado | COMMANDERS | Personalização individual. |
| CMD-GEN-007 | Kit de acessórios pessoais | Props | Kit 3D | Global | Confirmado | COMMANDERS | Bolsas, cintos, luvas, mantos, broches e ferramentas. |
| CMD-GEN-008 | Kit de postura e expressão | Animações | Rig / Animation | Global | Confirmado | COMMANDERS | Individualidade sem alterar a identidade cultural. |
| CMD-GEN-009 | Retrato de comandante | Retratos | Ilustração 2D | Global | Confirmado | COMMANDERS | Deve manter a mesma identidade do modelo de batalha. |
| CMD-GEN-010 | Modelo isométrico de comandante | Gameplay | Personagem 3D / Animated | Global | Confirmado | COMMANDERS; DL_BATTLEFIELDS | Fica fora do grid e não compete com o pelotão. |
| CMD-GEN-011 | Kit cultural de comandante | Gameplay | Kit 3D | Por facção | Confirmado | COMMANDERS | Armadura, roupa, tecido, símbolo, arma, escudo, montaria e acessórios da facção. |
| CMD-GEN-012 | Kit de evolução de comandante | Gameplay | Variantes 3D | Global | Confirmado | COMMANDERS | Materiais e equipamentos mais refinados; mesma identidade. |
| CMD-MNT-001 | Montaria de comandante por facção | Fauna | 3D / Animated | Por facção | A extrair | COMMANDERS | Confirmada como sistema, mas requer documento específico para espécies e kits. |

### Pelotões e animação de combate

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| PLT-SYS-001 | Modelo-base de soldado | Gameplay | Personagem 3D | Global | Confirmado | BATTLE PLATOONS | Base para kits de unidade e facção. |
| PLT-SYS-002 | Kit visual de pelotão por carta | Gameplay | Kit 3D | Global | Confirmado | BATTLE PLATOONS | Cada carta é representada por exatamente um pelotão. |
| PLT-SYS-003 | Variantes de Tier e raridade | Gameplay | Variantes 3D | Global | Confirmado | BATTLE PLATOONS | Quantidade de soldados e equipamento comunicam Tier e raridade. |
| PLT-SYS-004 | Formação isométrica de pelotão | Gameplay | Setup 3D | Global | Confirmado | BATTLE PLATOONS | Unidade visual única, organizada e legível. |
| PLT-ANM-001 | Animação de espera organizada | Animações | Animation | Global | Confirmado | BATTLE PLATOONS | Soldados não devem parecer aleatórios. |
| PLT-ANM-002 | Animação de ataque coordenado | Animações | Animation | Global | Confirmado | BATTLE PLATOONS | O pelotão se comporta como uma unidade única. |
| PLT-ANM-003 | Animação de movimentação em formação | Animações | Animation | Global | Confirmado | BATTLE PLATOONS | Postura e movimentação variam conforme facção. |
| PLT-ANM-004 | Animação de derrota / remoção | Animações | Animation | Global | Confirmado | BATTLE PLATOONS; DL_BATTLEFIELDS | Deve preservar a leitura da reorganização posterior. |

## Lote 04 — Cartas, ícones e interface

Os componentes abaixo são os assets oficiais do sistema de cartas. A estrutura
permanece igual para todas as facções; apenas molduras, materiais e ornamentação
variam. Ícones são compartilhados por cartas, HUD, campo de batalha, biblioteca,
deck builder, academia, cidade, menus e tooltips.

### Estrutura, molduras e estados de cartas

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| CRD-BAS-001 | Estrutura oficial da carta | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_BASE`; geometria única para todas as cartas. |
| CRD-BAS-002 | Grid interno da carta | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_GRID`; posições canônicas. |
| CRD-BAS-003 | Área da arte | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_ART_AREA`; arte ocupa cerca de 60–65% da carta. |
| CRD-BAS-004 | Área de texto | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_TEXT_AREA`; habilidades e características. |
| CRD-BAS-005 | Barra inferior | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_BOTTOM_BAR`; atributos de combate. |
| CRD-BAS-006 | Área do nome | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | `CARD_NAME_AREA`. |
| CRD-BAS-007 | Área de classe | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_CLASS_AREA`; posição fixa. |
| CRD-BAS-008 | Área de tipo | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_TYPE_AREA`; posição fixa. |
| CRD-BAS-009 | Espaço de energia | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_ENERGY_SLOT`; oculto em combate. |
| CRD-BAS-010 | Espaço de soldo | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | `CARD_SALARY_SLOT`; oculto em combate. |
| CRD-FRM-001 | Moldura comum do Império | Cartas | UI 2D | Império | Confirmado | CARD_ART_CATALOG | `FRAME_EMPIRE_COMMON`. |
| CRD-FRM-002 | Moldura rara do Império | Cartas | UI 2D | Império | Confirmado | CARD_ART_CATALOG | `FRAME_EMPIRE_RARE`. |
| CRD-FRM-003 | Moldura épica do Império | Cartas | UI 2D | Império | Confirmado | CARD_ART_CATALOG | `FRAME_EMPIRE_EPIC`. |
| CRD-FRM-004 | Moldura lendária do Império | Cartas | UI 2D | Império | Confirmado | CARD_ART_CATALOG | `FRAME_EMPIRE_LEGENDARY`. |
| CRD-FRM-005 | Moldura comum da Natureza | Cartas | UI 2D | Natureza | Confirmado | CARD_ART_CATALOG | `FRAME_NATURE_COMMON`. |
| CRD-FRM-006 | Moldura rara da Natureza | Cartas | UI 2D | Natureza | Confirmado | CARD_ART_CATALOG | `FRAME_NATURE_RARE`. |
| CRD-FRM-007 | Moldura épica da Natureza | Cartas | UI 2D | Natureza | Confirmado | CARD_ART_CATALOG | `FRAME_NATURE_EPIC`. |
| CRD-FRM-008 | Moldura lendária da Natureza | Cartas | UI 2D | Natureza | Confirmado | CARD_ART_CATALOG | `FRAME_NATURE_LEGENDARY`. |
| CRD-FRM-009 | Moldura comum dos Mortos-Vivos | Cartas | UI 2D | Mortos-Vivos | Confirmado | CARD_ART_CATALOG | `FRAME_UNDEAD_COMMON`. |
| CRD-FRM-010 | Moldura rara dos Mortos-Vivos | Cartas | UI 2D | Mortos-Vivos | Confirmado | CARD_ART_CATALOG | `FRAME_UNDEAD_RARE`. |
| CRD-FRM-011 | Moldura épica dos Mortos-Vivos | Cartas | UI 2D | Mortos-Vivos | Confirmado | CARD_ART_CATALOG | `FRAME_UNDEAD_EPIC`. |
| CRD-FRM-012 | Moldura lendária dos Mortos-Vivos | Cartas | UI 2D | Mortos-Vivos | Confirmado | CARD_ART_CATALOG | `FRAME_UNDEAD_LEGENDARY`. |
| CRD-TIR-001 | Indicadores de Tier I–V | Cartas | Kit UI 2D | Global | Confirmado | CARD_ART_CATALOG; ICON_CATALOG | `TIER_01`–`TIER_05`; variantes de código `TIER_I`–`TIER_V` precisam ser unificadas. |
| CRD-RAR-001 | Indicadores de raridade | Cartas | Kit UI 2D | Global | Confirmado | CARD_ART_CATALOG; ICON_CATALOG | Comum, rara, épica e lendária. |
| CRD-ORN-001 | Kit de ornamentação imperial | Cartas | Kit UI 2D | Império | Confirmado | CARD_ART_CATALOG | Ornamentos superior, inferior, lateral, cantos e centro superior. |
| CRD-ORN-002 | Kit de ornamentação da Natureza | Cartas | Kit UI 2D | Natureza | Confirmado | CARD_ART_CATALOG | Ornamentos superior, inferior, lateral, cantos e centro superior. |
| CRD-ORN-003 | Kit de ornamentação dos Mortos-Vivos | Cartas | Kit UI 2D | Mortos-Vivos | Confirmado | CARD_ART_CATALOG | Ornamentos superior, inferior, lateral, cantos e centro superior. |
| CRD-TXT-001 | Banner de nome | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Informação de identificação. |
| CRD-TXT-002 | Banner de classe | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Informação de identificação. |
| CRD-TXT-003 | Banner de tipo | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Informação de identificação. |
| CRD-TXT-004 | Banner de texto | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Área de habilidades e características. |
| CRD-ATR-001 | Container de ataque | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Atributo no canto inferior esquerdo. |
| CRD-ATR-002 | Container de escudo | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Atributo inferior direito superior. |
| CRD-ATR-003 | Container de vida | Cartas | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Atributo no canto inferior direito. |
| CRD-FX-001 | Estado de seleção de carta | UI | UI 2D / VFX | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | Não pode ocultar informação essencial. |
| CRD-FX-002 | Estado hover de carta | UI | UI 2D / VFX | Global | Confirmado | CARD_ART_CATALOG | Feedback de interação. |
| CRD-FX-003 | Estado de carta ativa | UI | UI 2D / VFX | Global | Confirmado | CARD_ART_CATALOG | Feedback de interação. |
| CRD-FX-004 | Efeito de evolução de Tier | UI | UI 2D / VFX | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | Área de animação reservada. |
| CRD-FX-005 | Destaque de raridade | UI | UI 2D / VFX | Global | Confirmado | CARD_ART_CATALOG; CARD_LAYOUT_BIBLE | Área de animação reservada. |
| CRD-FX-006 | Estado de carta desabilitada | UI | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Feedback de disponibilidade. |
| CRD-FX-007 | Estado de carta bloqueada | UI | UI 2D | Global | Confirmado | CARD_ART_CATALOG | Feedback de progressão. |
| CRD-ART-001 | Template de ilustração de unidade imperial | Cartas | Ilustração 2D | Império | Confirmado | CARD_ART_BIBLE | Corpo inteiro, fundo imperial e enquadramento padronizado. |
| CRD-ART-002 | Template de ilustração de unidade da Natureza | Cartas | Ilustração 2D | Natureza | Confirmado | CARD_ART_BIBLE | Corpo inteiro, fundo natural e enquadramento padronizado. |
| CRD-ART-003 | Template de ilustração de unidade dos Mortos-Vivos | Cartas | Ilustração 2D | Mortos-Vivos | Confirmado | CARD_ART_BIBLE | Corpo inteiro, fundo de planaltos/cristais e enquadramento padronizado. |

### Biblioteca oficial de ícones

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| ICO-ATR-001 | Ícones de atributos | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Ataque `ICON_ATTACK`, Vida `ICON_HP`, Escudo `ICON_SHIELD`. |
| ICO-CLS-001 | Ícones de classes | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Corpo a Corpo, Barreira, À Distância, Mago, Suporte e Máquina de Guerra. |
| ICO-RAR-001 | Ícones de raridade | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Comum, Rara, Épica e Lendária. |
| ICO-TIR-001 | Ícones de Tier | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Tier I–V. |
| ICO-FAC-001 | Emblemas de facção | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | Império `FACTION_EMPIRE`, Natureza `FACTION_NATURE`, Mortos-Vivos `FACTION_UNDEAD`. |
| ICO-ABL-001 | Ícones de habilidades recorrentes | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Provocar, Investida, Perfurante, Concentração e 10 habilidades de treinamento/campanha. |
| ICO-TRT-001 | Ícones de características | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Disciplina Imperial e Muralha de Escudos; expansão por cartas congeladas. |
| ICO-AFF-001 | Ícones de Afinidade I–III | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | `AFFINITY_I`–`AFFINITY_III`. |
| ICO-RES-001 | Ícones de recursos | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG; CARD_ICONOGRAPHY | Fragmentos, Ferro Negro, Cristais Arcanos e Essência Vital. |
| ICO-ENG-001 | Ícones de energia | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | Energia e Recuperação. |
| ICO-SLD-001 | Ícone de soldo | Ícones | UI 2D | Global | Confirmado | ICON_CATALOG | `SOLDO`. |
| ICO-XP-001 | Ícones de experiência | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | XP do Comandante e XP do Reino. |
| ICO-LIB-001 | Ícones de biblioteca | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | Pesquisa, filtro, ordenação, favorito, comparar, lore, evolução e receita. |
| ICO-UI-001 | Ícones globais de interface | Ícones | Kit UI 2D | Global | Confirmado | ICON_CATALOG | Confirmar, cancelar, voltar, fechar, expandir, recolher, informação, aviso e erro. |

## Lote 05 — Fauna, ambientação viva e áudio

As espécies colossais são fauna ambiental rara, não montarias. A documentação
determina que o mundo use poucas espécies reconhecíveis e comportamento natural.
Os elementos de áudio abaixo são loops e camadas de ambiente; trilhas musicais
não estão especificadas nestas fontes.

### Fauna e vida ambiental

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| FAU-COL-001 | Cervo Colossal | Fauna | Personagem 3D / Animated | Florestas antigas | Confirmado | WORLD FOUNDATION (DRAFT) | Guardião das florestas; chifres ramificados de até 4 m; não domesticado. |
| FAU-COL-002 | Bisão Titânico | Fauna | Personagem 3D / Animated | Planícies / Império | Confirmado | WORLD FOUNDATION (DRAFT) | Grande herbívoro de planícies; deve parecer um bisão real levado ao limite. |
| FAU-COL-003 | Cabra Colossal | Fauna | Personagem 3D / Animated | Montanhas / penhascos | Confirmado | WORLD FOUNDATION (DRAFT) | Herbívoro de escarpas, com cascos aderentes e pelagem espessa. |
| FAU-AMB-001 | Kit de aves ambientais | Fauna | Kit 3D / Animated | Global | A extrair | WORLD FOUNDATION (DRAFT); REGIÃO NATUREZA | Categoria confirmada; espécies ainda não definidas. |
| FAU-AMB-002 | Kit de pequenos mamíferos | Fauna | Kit 3D / Animated | Global | A extrair | WORLD FOUNDATION (DRAFT) | Categoria confirmada; espécies ainda não definidas. |
| FAU-AMB-003 | Kit de insetos | Fauna | Kit 3D / VFX | Global | A extrair | WORLD FOUNDATION (DRAFT); REGIÃO NATUREZA | Categoria confirmada; espécies ainda não definidas. |
| FAU-AMB-004 | Kit de répteis e anfíbios | Fauna | Kit 3D / Animated | Global | A extrair | WORLD FOUNDATION (DRAFT) | Categoria confirmada; espécies ainda não definidas. |
| FAU-AMB-005 | Kit de fauna de médio porte | Fauna | Kit 3D / Animated | Global | A extrair | WORLD FOUNDATION (DRAFT) | Categoria confirmada; espécies ainda não definidas. |
| AMB-WLD-001 | Céu antigo com nuvens lentas | Cenários | Sky / Procedural | Mundo | Confirmado | WORLD FOUNDATION (DRAFT) | Nunca totalmente limpo ou vibrante; não muda com a progressão. |
| AMB-WLD-002 | Cicatriz atmosférica do Cataclisma | FX | Shader / Overlay / Partículas | Mundo | Confirmado | WORLD FOUNDATION (DRAFT) | Transparência evolui com a Capital; não criar imagens substitutas. |
| AMB-WLD-003 | Kit de árvores continentais | Vegetação | Kit 3D | Global | Confirmado | WORLD FOUNDATION (DRAFT) | Troncos largos, casca espessa, galhos robustos e poucas espécies. |
| AMB-WLD-004 | Movimento de folhas ao vento | Animações | Animation / Shader | Global | Confirmado | DL_NAVIGATION; REGIÃO NATUREZA | Camada de vida ambiental. |
| AMB-WLD-005 | Fluxo de água ambiental | Animações | Animation / Shader | Global | Confirmado | DL_NAVIGATION; regiões | Rios, cachoeiras e canais devem manter leitura de fluxo. |
| AMB-WLD-006 | Trânsito ambiental de trabalhadores | Animações | Loop de personagens | Reino / Regiões | Confirmado | DL_NAVIGATION; regiões | Pequenos detalhes em níveis de zoom próximos. |

### Paisagem sonora de navegação

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| AUD-WLD-001 | Loop de vento do mundo | Áudio | Loop ambiente | Mundo | Confirmado | DL_NAVIGATION | Camada de áudio do nível Mundo. |
| AUD-WLD-002 | Loop de fauna do mundo | Áudio | Loop ambiente | Mundo | Confirmado | DL_NAVIGATION | Deve acompanhar a fauna definida por bioma. |
| AUD-WLD-003 | Loop de ambiente geral do mundo | Áudio | Loop ambiente | Mundo | Confirmado | DL_NAVIGATION | Base sonora do nível Mundo. |
| AUD-KNG-001 | Loop de vida urbana do Reino | Áudio | Loop ambiente | Reino | Confirmado | DL_NAVIGATION | Camada de áudio do nível Reino. |
| AUD-KNG-002 | Loop de ferramentas e movimento urbano | Áudio | Loop ambiente | Reino | Confirmado | DL_NAVIGATION | Complementa a vida urbana. |
| AUD-CMD-001 | Loop de ordens e passos | Áudio | Loop ambiente | Centro de Comando | Confirmado | DL_NAVIGATION | Construção: Centro de Comando. |
| AUD-CMD-002 | Loop de montarias e treinos | Áudio | Loop ambiente | Centro de Comando | Confirmado | DL_NAVIGATION | Construção: Centro de Comando. |
| AUD-ACA-001 | Loop de ferramentas e água | Áudio | Loop ambiente | Academia | Confirmado | DL_NAVIGATION | Construção: Academia. |
| AUD-ACA-002 | Loop de estudos e forjas | Áudio | Loop ambiente | Academia | Confirmado | DL_NAVIGATION | Construção: Academia. |
| AUD-NRG-001 | Loop do fluxo de Essência Vital | Áudio | Loop ambiente | Núcleo de Energia | Confirmado | DL_NAVIGATION; FUNDAMENTO III ESSÊNCIA VITAL | Suave e contínuo, semelhante a riacho distante. |
| AUD-NRG-002 | Loop de Cristais Arcanos | Áudio | Loop ambiente | Núcleo de Energia | Confirmado | DL_NAVIGATION; FUNDAMENTO II CRISTAIS ARCANOS | Harmônico leve e constante. |
| AUD-NRG-003 | Loop de névoa e ambiente sereno | Áudio | Loop ambiente | Núcleo de Energia | Confirmado | DL_NAVIGATION | Sem sensação de poder bruto. |
| AUD-DEP-001 | Loop de carroças e cordas | Áudio | Loop ambiente | Depósito | Confirmado | DL_NAVIGATION | Construção: Depósito. |
| AUD-DEP-002 | Loop de madeira e materiais organizados | Áudio | Loop ambiente | Depósito | Confirmado | DL_NAVIGATION | Construção: Depósito. |

## Lote 06 — Cruzamento reverso: referências visuais do acervo

As imagens deste lote foram conferidas por nome e por amostragem visual. Elas são
pranchas de conceito, catálogo ou especificação; por isso, **não** mudam nenhum
item para `Pronto`. Seu papel é fundamentar o brief e dar cobertura à produção.

### Botânica identificada no acervo

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| VEG-PRI-001 | Primeva Ancestral | Vegetação | Árvore 3D | Florestas antigas | Confirmado | `Imagens/Botânica/Primeva_Ancestral.png` | Prancha com ciclo de vida e variações de broto a monumental. |
| VEG-PRI-002 | Primeva da Natureza | Vegetação | Árvore 3D | Natureza | Confirmado | `Imagens/Botânica/Primeva_da_natureza.png` | Referência visual disponível. |
| VEG-PRI-003 | Primeva Imperial | Vegetação | Árvore 3D | Império | Confirmado | `Imagens/Botânica/Primeva_Imperial.png` | Referência visual disponível. |
| VEG-PRI-004 | Primeva Ribeirinha | Vegetação | Árvore 3D | Ribeirinho | Confirmado | `Imagens/Botânica/Primeva_Ribeirinha.png` | Referência visual disponível. |
| VEG-PRI-005 | Primeva Rochosa | Vegetação | Árvore 3D | Rochoso | Confirmado | `Imagens/Botânica/Primeva_Rochosa.png` | Referência visual disponível. |
| VEG-PRI-006 | Primeva Montanhosa | Vegetação | Árvore 3D | Montanhoso | Confirmado | `Imagens/Botânica/Primeva_Montanhosa.png` | Referência visual disponível. |
| VEG-PRI-007 | Vitória Primeva | Vegetação | Planta 3D | Global | Confirmado | `Imagens/Botânica/Vitória Primeva.png` | Referência visual disponível. |
| VEG-SHR-001 | Arbusto verde | Vegetação | Arbusto 3D | Global | Confirmado | `Imagens/Botânica/Arbusto_verde.png` | Variante de arbusto. |
| VEG-SHR-002 | Arbusto rubro | Vegetação | Arbusto 3D | Global | Confirmado | `Imagens/Botânica/Arbusto_rubro.png` | Variante de arbusto. |
| VEG-SHR-003 | Arbusto dourado | Vegetação | Arbusto 3D | Global | Confirmado | `Imagens/Botânica/Arbusto_dourado.png` | Variante de arbusto. |
| VEG-SHR-004 | Arbusto azul | Vegetação | Arbusto 3D | Global | Confirmado | `Imagens/Botânica/Arbusto_azul.png` | Variante de arbusto. |
| VEG-SHR-005 | Arbusto anão | Vegetação | Arbusto 3D | Rochoso / montanhoso | Confirmado | `Imagens/Botânica/Arbusto_anão.png` | Variante de arbusto. |
| VEG-MOS-001 | Musgo ribeirinho | Vegetação | Material / Decal | Ribeirinho | Confirmado | `Imagens/Botânica/Musgo_ribeirinho.png` | Variante de musgo. |
| VEG-MOS-002 | Musgo florestal | Vegetação | Material / Decal | Florestas antigas | Confirmado | `Imagens/Botânica/Musgo_florestal.png` | Variante de musgo. |
| VEG-MOS-003 | Musgo de rocha | Vegetação | Material / Decal | Rochoso / montanhoso | Confirmado | `Imagens/Botânica/Musgo_de_rocha.png` | Variante de musgo. |
| VEG-VIN-001 | Trepadeira comum | Vegetação | Planta 3D | Global | Confirmado | `Imagens/Botânica/Trepadeira comum.png` | Referência visual disponível. |
| VEG-VIN-002 | Trepadeira ribeirinha | Vegetação | Planta 3D | Ribeirinho | Confirmado | `Imagens/Botânica/Trepadeira_ribeirinha.png` | Referência visual disponível. |
| VEG-GRD-001 | Campo aberto | Vegetação | Kit de solo 3D | Planícies | Confirmado | `Imagens/Botânica/campo_aberto.png` | Referência para gramíneas e composição. |
| VEG-GRD-002 | Campo rochoso | Vegetação | Kit de solo 3D | Rochoso | Confirmado | `Imagens/Botânica/campo_rochoso.png` | Referência para gramíneas e pedra. |
| VEG-GRD-003 | Campo úmido | Vegetação | Kit de solo 3D | Ribeirinho / pântano | Confirmado | `Imagens/Botânica/campo_úmido.png` | Referência para vegetação de solo úmido. |

### Cobertura visual de Battlefields, materiais e atmosfera

| Grupo de referências | Arquivos | IDs cobertos | Uso |
|---|---|---|---|
| Cenários oficiais de território | `Imagens/Campos de batalha/Cenários/Cenários oficiais.png`, `Império.png`, `Natureza.png`, `Morto-Vivo.png`, `Montanha.png`, `Pantano.png` | TER-BASE-*, ENV-*, IMP-*, UND-*, NAT-* | Direção de composição e continuidade entre território e grid. |
| Pacotes de Battlefield | `Campo aberto.png`, `Ventania.png`, `Chuva fraca.png`, `Tempestade com raio.png`, `Lua cheia.png`, `Nevoeiro arcano.png`, `Pantano.png`, `Floresta.png`, `Vale.png`, `Vulcão.png` | ATM-LGT-*, ATM-WTH-*, ATM-FX-*, ENV-*, TER-BASE-* | Referências dos packages oficiais, não assets finais individuais. |
| Catálogos de madeira e pedra | `Imagens/Materiais resistentes/Catálogo.png`, `Catálogo_de _pedras.png`, `Pedras.txt`, `Madeira.txt` | TER-BASE-005, TER-BASE-006, CAP-STR-*, DEP-PRP-002 | Base de materiais para arquitetura e geologia. |
| Madeiras Primevas | `Madeira Primeva ancestral.png`, `imperial.png`, `da natureza.png`, `Ribeirinha.png`, `Montanhosa.png`, `rochosa.png` | VEG-PRI-001–006, AMB-WLD-003 | Direção de material para cada família de árvore. |
| Atmosfera | `Imagens/Atmosféra/Atmosfera.png`, `Atmosfera2.png` | AMB-WLD-001, ATM-FX-001, ATM-FX-002 | Referência de céu, profundidade e névoa. |

## Lote 07 — Cruzamento reverso: facções, cartas e UI

As coleções desta fase também são pranchas de referência. Foram criados registros
novos somente quando uma prancha apresenta um componente ainda ausente da lista;
os demais arquivos foram vinculados aos kits já existentes.

### Componentes de interface identificados visualmente

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| UI-CMP-001 | Lista padronizada | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Lista reutilizável de itens, cartas, missões e registros. |
| UI-CMP-002 | Grade de itens | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Grid para itens, cartas e unidades. |
| UI-CMP-003 | Painel de inventário | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Organização por filtros e categorias. |
| UI-CMP-004 | Slot padrão de item | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Estados vazio, ocupado, bloqueado, selecionado, indisponível e desabilitado. |
| UI-CMP-005 | Barra de progresso | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Pesquisas, construções, missões e eventos. |
| UI-CMP-006 | Timeline / linha do tempo | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Sequência de eventos, campanhas e ações. |
| UI-CMP-007 | Árvore tecnológica | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Tecnologias, dependências e bloqueios. |
| UI-CMP-008 | Fila de construção e pesquisa | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Fila, progresso e ação de acelerar. |
| UI-CMP-009 | Lista de missões | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Missões principais, secundárias e diárias. |
| UI-CMP-010 | Filtros avançados | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Facção, tipo, elemento, corpo, raridade e nível. |
| UI-CMP-011 | Painel expansível | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Informação que pode ser expandida ou recolhida. |
| UI-CMP-012 | Seleção múltipla | UI | Componente UI 2D | Global | Confirmado | `Imagens/UI/Componentes complexos.png` | Ações em lote sobre itens selecionados. |

### Cobertura visual por coleção

| Grupo de referências | Arquivos | IDs cobertos | Uso |
|---|---|---|---|
| Império | `Imagens/Império/Armaduras.png`, `Armas.png`, `escudos.png`, `capacetes.png`, `Brazão.png`, `Formasio.png`, `Arquitetura.png`, `Materiais.png`, `Paleta.png`, `Tecidos.png`, `Território.png`, `Escala de qualidade.png`, `Excluidos.png` | IMP-ID-001–008, CRD-ART-001, CMD-GEN-011 | Referências para os kits imperiais e suas variações. |
| Mortos-Vivos | `Imagens/Morto vivo/Armas e ferramentas.png`, `Brasões.png`, `Criaturas.png`, `personagens.png`, `Siluetas.png`, `Arquiterura.png`, `Materiais.png`, `atmosfera.png`, `Acampamento.png`, `Trabalhadores.png`, `detalhes.png`, `Catálogo.png`, `Filosofia.png` | UND-ID-001–007, CRD-ART-003, CMD-GEN-011 | Referências para identidade, personagens, ambiente e kits da facção. |
| Natureza | `Imagens/Natureza/Arquitetura.png`, `Brasão.png`, `Ferramentas.png`, `Personagens.png`, `Siluetas.png`, `Essência Vital.png`, `Materiais.png`, `atmosfera.png`, `Acampamento.png`, `Trabalhadores.png`, `Guardiões.png`, `Detalhes.png`, `Guia visual.png`, `Filosofia.png` | NAT-ID-001–008, NAT-*, RES-VIT-*, CRD-ART-002, CMD-GEN-011 | Referências para identidade, ambiente e elementos de Essência Vital. |
| Molduras de cartas | `Imagens/Moldura das cartas/Elementos das cartas1.png`, `1A.png`, `1D.png`, `1E.png`, `Elementos das império.png`, `Elementos da natureza.png`, `Elementos do morto-vivo.png` | CRD-BAS-*, CRD-FRM-*, CRD-ORN-* | Referências para estrutura, molduras e ornamentação. |
| Guias de ilustração | `Imagens/Guia de ilustraçao/Guia de ilustração.png`, `Composição.png`, `Camera.png`, `Luz.png`, `Paleta.png`, `Materiais.png`, `retarato da unidade.png`, `retarato de comandante.png`, `Construções.png`, `Recursos.png`, `Eventos.png`, `Prompts.png` | CRD-ART-*, CMD-GEN-009, CAP-*, RES-*, NRG-* | Guia de linguagem visual e composição; o nome de arquivo “retarato” parece conter um erro de digitação. |
| UI | `Imagens/UI/UI.png`, `UI-0.png`, `telas.png`, `Janelas.png`, `Componentes.png`, `Componentes complexos.png`, `Botões.png`, `Indicadores.png`, `Icones.png`, `Feedback.png`, `Deck Builder.png`, `Cards de interface.png`, `Batalha.png`, `Campanha.png`, `Reino.png`, `Motion.png`, `Sound.png` | ICO-*, CRD-*, UI-CMP-001–012, UI-GRID-* | Referências para estados, telas e componentes de interface. |
| Fauna canônica | `Imagens/Canônicos/Montarias.png` | FAU-COL-001–003 | A imagem representa Cervo, Bisão e Cabra Colossais; não usar como fonte de montarias de comandante. |

## Lote 08 — Cruzamento reverso: Reino, mapa e fauna

Este lote conclui o cruzamento inicial de todas as coleções visuais de
`Imagens/`. As novas entradas abaixo existem como composição, navegação e
camadas de mapa; continuam sendo referências de produção, não arquivos finais
implementados no jogo.

| ID | Asset | Bloco | Tipo | Facção/Bioma | Status | Fontes | Observações |
|---|---|---|---|---|---|---|---|
| MAP-WLD-001 | Mapa continental do Battle Simulator | Mapa | Ilustração 2D / UI | Mundo | Confirmado | `Imagens/Mapa/Mapa2.png`; WORLD FOUNDATION (DRAFT) | Mapa mestre com Capital, três territórios e muralha do Cataclisma. |
| MAP-WLD-002 | Camadas de trilhas da campanha | Mapa | UI 2D | Mundo | Confirmado | `Imagens/Mapa/Mapa2.png`; DL_NAVIGATION | Uma trilha por facção, com regiões e fases. |
| MAP-WLD-003 | Muralha / cordilheira do Cataclisma | Mapa | Ilustração 2D / Cenário 3D | Mundo | Confirmado | `Imagens/Mapa/Mapa2.png`; WORLD FOUNDATION (DRAFT) | Barreira natural que encerra os territórios conhecidos. |
| MAP-WLD-004 | Montanha dos Ciclos | Mapa | Ilustração 2D / Cenário 3D | Mundo | Confirmado | `Imagens/Mapa/Mapa2.png`; WORLD FOUNDATION (DRAFT) | Marco externo ao continente; ciclo de Luz ocorre a cada 16 anos. |

| Grupo de referências | Arquivos | IDs cobertos | Uso |
|---|---|---|---|
| Reino | `Imagens/Reino/Reino1.png`, `Reino2.png`, `Reino3.png`, `Reino4-ok.png` | AMB-WLD-001, AMB-WLD-003, CAP-BLD-001, MAP-WLD-* | Céu antigo, perspectiva aérea, luz suave e famílias de árvores continentais. |
| Mapa | `Imagens/Mapa/Mapa2.png`, `Sem título.png` | MAP-WLD-001–004, DL_NAVIGATION | Hierarquia territorial e composição da navegação macro. |
| Fauna | `Imagens/Fauna/Montarias.png`, `Fauna.txt`, `Grandes Herbívoros.txt` | FAU-COL-001–003, FAU-AMB-* | A prancha visual confirma as espécies colossais; textos sustentam o catálogo de fauna. |

## Ordem de catalogação recomendada

1. **Fundação visual do mundo:** Mundo, Cenários, Vegetação, Geologia e Props.
2. **Identidade do jogo:** Facções, Construções, Recursos, Cartas, Ícones e Retratos.
3. **Camadas de uso:** Gameplay, UI, FX, VFX, Áudio e Animações.

## Próxima fase: auditoria de produção e priorização

Com o acervo visual inicial já cruzado, separar os registros por prioridade de
produção, dependências e evidência visual. A primeira saída será uma lista P0
prática: o menor conjunto de assets necessários para uma primeira batalha, uma
primeira tela de Reino e a leitura completa de uma carta.
