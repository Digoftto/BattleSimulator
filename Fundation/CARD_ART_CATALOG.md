# CARD_ART_CATALOG.md

> **Status:** CANÔNICO — PRODUÇÃO
>
> **Escopo:** catálogo oficial de todos os assets gráficos necessários para compor qualquer carta do Battle Simulator.
>
> **Dependências:**
>
> - CARD_LAYOUT_BIBLE.md
> - CARD_ICONOGRAPHY.md
> - ICON_CATALOG.md
> - ART_BIBLE_IMPERIO.md
> - ART_BIBLE_NATUREZA.md
> - ART_BIBLE_MORTOS_VIVOS.md
>
> **Objetivo:**
>
> Organizar toda a produção artística das cartas.
>
> Nenhum asset poderá entrar em produção sem estar registrado neste catálogo.

---

# 1. Filosofia

Este documento não define identidade visual.

Essa responsabilidade pertence à CARD_LAYOUT_BIBLE.

Este catálogo existe para organizar a produção dos arquivos gráficos que compõem uma carta.

Cada asset representa uma peça reutilizável.

Sempre que possível, um mesmo asset deverá ser utilizado em centenas ou milhares de cartas.

A reutilização possui prioridade sobre a criação de elementos exclusivos.

---

# 2. Organização

Os assets são divididos em nove grandes grupos.

I. Estrutura Base

II. Molduras

III. Sistema de Tier

IV. Sistema de Raridade

V. Ornamentação

VI. Banners

VII. Atributos

VIII. Ícones

IX. Efeitos

---

# 3. Status dos Assets

Todo asset pertence obrigatoriamente a um destes estados.

Planejado

↓

Em produção

↓

Em revisão

↓

Aprovado

↓

Congelado

---

# 4. Convenção de Nome

Todos os arquivos seguem o padrão.

```
CATEGORY_FACTION_ELEMENT_VARIATION
```

Exemplos:

```
FRAME_EMPIRE_COMMON

FRAME_NATURE_EPIC

FRAME_UNDEAD_LEGENDARY

BANNER_CLASS

ICON_ATTACK

ORNAMENT_TIER_IV
```

Nunca utilizar nomes genéricos.

Nunca utilizar espaços.

---

# 5. Estrutura de Produção

Cada asset será registrado utilizando a seguinte ficha.

| Campo | Descrição |
|--------|-----------|
| Nome | Nome oficial |
| Código | Identificador |
| Categoria | Família |
| Utilização | Onde aparece |
| Dependências | Assets relacionados |
| Status | Produção |
| Observações | Informações adicionais |

---

# 6. Catálogo Oficial

As próximas seções representam a lista oficial de assets necessários para o sistema de cartas.

Cada item será produzido individualmente.

# I. Estrutura Base
Asset	Código	Status
Estrutura oficial da carta	CARD_BASE	Planejado
Grid interno	CARD_GRID	Planejado
Área da Arte	CARD_ART_AREA	Planejado
Área de Texto	CARD_TEXT_AREA	Planejado
Barra Inferior	CARD_BOTTOM_BAR	Planejado
Área do Nome	CARD_NAME_AREA	Planejado
Área de Classe	CARD_CLASS_AREA	Planejado
Área de Tipo	CARD_TYPE_AREA	Planejado
Área de Energia	CARD_ENERGY_SLOT	Planejado
Área de Soldo	CARD_SALARY_SLOT	Planejado

# II. Molduras
Império
Asset	Código
Moldura Comum	FRAME_EMPIRE_COMMON
Moldura Rara	FRAME_EMPIRE_RARE
Moldura Épica	FRAME_EMPIRE_EPIC
Moldura Lendária	FRAME_EMPIRE_LEGENDARY

Natureza
Asset	Código
Moldura Comum	FRAME_NATURE_COMMON
Moldura Rara	FRAME_NATURE_RARE
Moldura Épica	FRAME_NATURE_EPIC
Moldura Lendária	FRAME_NATURE_LEGENDARY

Mortos-Vivos
Asset	Código
Moldura Comum	FRAME_UNDEAD_COMMON
Moldura Rara	FRAME_UNDEAD_RARE
Moldura Épica	FRAME_UNDEAD_EPIC
Moldura Lendária	FRAME_UNDEAD_LEGENDARY

# III. Sistema de Tier
Asset	Código
Indicador Tier I	TIER_01
Indicador Tier II	TIER_02
Indicador Tier III	TIER_03
Indicador Tier IV	TIER_04
Indicador Tier V	TIER_05

# IV. Sistema de Raridade

| Asset | Código |
|---------|---------|
| Comum | RARITY_COMMON |
| Rara | RARITY_RARE |
| Épica | RARITY_EPIC |
| Lendária | RARITY_LEGENDARY |

# V. Ornamentação
Império
Ornamento Superior
Ornamento Inferior
Ornamento Lateral
Cantos
Centro Superior

Natureza
Ornamento Superior
Ornamento Inferior
Ornamento Lateral
Cantos
Centro Superior

Mortos-Vivos
Ornamento Superior
Ornamento Inferior
Ornamento Lateral
Cantos
Centro Superior

# VI. Banners
| Asset |
|---------|
| Banner Nome |
| Banner Classe |
| Banner Tipo |
| Banner Texto |

# VII. Sistema de Atributos
| Asset |
|---------|
| Container Ataque |
| Container Escudo |
| Container HP |

# VIII. Ícones
Todos os ícones são herdados do ICON_CATALOG.md.
Este documento não duplica essa informação.

# IX. Efeitos Visuais
| Asset |
|---------|
| Seleção |
| Hover |
| Carta Ativa |
| Evolução de Tier |
| Destaque de Raridade |
| Carta Desabilitada |
| Carta Bloqueada |

Status

Data

Autor

Versão

Prompt utilizado

Arquivo fonte

Arquivo final

Observações

Produção
Cada asset produzido deverá receber:
Status

Data

Autor

Versão

Prompt utilizado

Arquivo fonte

Arquivo final

Observações

Acho que podemos melhorar ainda mais
[Certo] Eu faria uma mudança em relação à forma tradicional de produzir assets.
Eu não produziria as molduras completas primeiro.
Produziria primeiro um documento chamado CARD_ATLAS.md (não agora, depois deste catálogo).
Nele, dividiríamos a moldura em peças reutilizáveis:

Topo

Base

Lateral Esquerda

Lateral Direita

Canto Superior Esquerdo

Canto Superior Direito

Canto Inferior Esquerdo

Canto Inferior Direito

Centro Superior

Centro Inferior