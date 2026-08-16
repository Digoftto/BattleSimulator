# BACKLOG DE PRODUÇÃO P0

> Recorte mínimo para apresentar o Battle Simulator com uma batalha legível,
> uma tela de Reino e uma carta completa. Este documento não substitui o
> `ASSET_MASTER_LIST.md`: ele apenas ordena o que deve ser produzido primeiro.

## Regra de prioridade

- **P0**: bloqueia a primeira experiência jogável/visual.
- **P1**: melhora a experiência, mas não bloqueia a demonstração.
- Uma prancha existente é uma referência; não conta como asset pronto no jogo.

## Objetivo de entrega

Ao finalizar todos os P0, o projeto deve permitir:

1. Abrir a tela do Reino e reconhecer Capital, construções principais e recursos.
2. Abrir uma carta de unidade com arte, atributos, classe, tipo, raridade e Tier.
3. Iniciar uma batalha em um campo claro, selecionar uma posição e ler o ataque.

## P0-A — Batalha mínima

| Ordem | ID mestre | Entrega | Tipo | Dependência |
|---:|---|---|---|---|
| 1 | TER-BASE-001 | Terreno de grama base | Material / cenário | Nenhuma |
| 2 | ATM-LGT-001 | Iluminação diurna | Procedural | Terreno base |
| 3 | ATM-WTH-001 | Estado sem clima | Package | Terreno e luz |
| 4 | UI-GRID-001 | Grid tático 3×3 | UI / Procedural | Terreno base |
| 5 | UI-GRID-002 | Estado hover do grid | UI / Procedural | Grid tático |
| 6 | UI-GRID-003 | Estado selecionado do grid | UI / Procedural | Grid tático |
| 7 | UI-GRID-004 | Estado alvo do grid | UI / Procedural | Grid tático |
| 8 | PLT-SYS-001 | Modelo-base de soldado | Personagem 3D | Nenhuma |
| 9 | IMP-ID-002 | Kit de armadura imperial | Kit 3D | Modelo-base de soldado |
| 10 | PLT-SYS-004 | Formação isométrica de pelotão | Setup 3D | Soldado e kit imperial |
| 11 | PLT-ANM-001 | Animação de espera organizada | Animação | Formação de pelotão |
| 12 | PLT-ANM-002 | Animação de ataque coordenado | Animação | Formação de pelotão |
| 13 | VFX-BTL-001 | Impacto pequeno | VFX | Ataque coordenado |
| 14 | VFX-BTL-010 | Eliminação | VFX | Ataque coordenado |
| 15 | CMD-GEN-010 | Modelo isométrico de comandante | Personagem 3D | Nenhuma |

**Fora do P0 da batalha:** clima, variações de terreno, montarias, outras
facções, efeitos de cura/escudo/buff/debuff e cenários regionais.

## P0-B — Carta completa

| Ordem | ID mestre | Entrega | Tipo | Dependência |
|---:|---|---|---|---|
| 1 | CRD-BAS-001 | Estrutura oficial da carta | UI 2D | Nenhuma |
| 2 | CRD-BAS-003 | Área da arte | UI 2D | Estrutura da carta |
| 3 | CRD-BAS-005 | Barra inferior | UI 2D | Estrutura da carta |
| 4 | CRD-BAS-006 | Área do nome | UI 2D | Estrutura da carta |
| 5 | CRD-BAS-007 | Área de classe | UI 2D | Estrutura da carta |
| 6 | CRD-BAS-008 | Área de tipo | UI 2D | Estrutura da carta |
| 7 | CRD-FRM-001 | Moldura comum do Império | UI 2D | Estrutura da carta |
| 8 | CRD-ART-001 | Ilustração de uma unidade imperial | Ilustração 2D | Kit visual imperial |
| 9 | ICO-ATR-001 | Ícones de Ataque, Vida e Escudo | Kit UI 2D | Barra inferior |
| 10 | ICO-CLS-001 | Ícones de classes | Kit UI 2D | Área de classe |
| 11 | ICO-FAC-001 | Emblemas de facção | Kit UI 2D | Estrutura da carta |
| 12 | CRD-TIR-001 | Indicadores de Tier I–V | Kit UI 2D | Estrutura da carta |
| 13 | CRD-RAR-001 | Indicadores de raridade | Kit UI 2D | Estrutura da carta |

**Escopo mínimo:** uma carta imperial Comum, Tier I, com uma única ilustração e
uma habilidade. Todas as demais variações continuam no master list.

## P0-C — Tela do Reino

| Ordem | ID mestre | Entrega | Tipo | Dependência |
|---:|---|---|---|---|
| 1 | AMB-WLD-001 | Céu antigo com nuvens lentas | Cenário / procedural | Nenhuma |
| 2 | AMB-WLD-003 | Kit de árvores continentais | Kit 3D | Nenhuma |
| 3 | CAP-BLD-001 | Capital do Reino — versão inicial | Kit 3D | Céu e terreno |
| 4 | CMD-BLD-001 | Centro de Comando — versão inicial | Kit 3D | Tela do Reino |
| 5 | DEP-BLD-001 | Complexo de depósitos — versão inicial | Kit 3D | Tela do Reino |
| 6 | NRG-BLD-001 | Núcleo de Energia — versão inicial | Kit 3D | Tela do Reino |
| 7 | RES-IRN-002 | Ferro Negro incorporado | Material / 3D | Capital e Centro de Comando |
| 8 | NRG-RES-001 | Cristal Arcano estabilizado | 3D / procedural | Núcleo de Energia |
| 9 | NRG-RES-002 | Canal de Essência Vital | 3D / animação | Núcleo de Energia |
| 10 | UI-CMP-001 | Lista padronizada | Componente UI 2D | Nenhuma |
| 11 | ICO-RES-001 | Ícones de recursos | Kit UI 2D | Interface do Reino |
| 12 | AUD-KNG-001 | Loop de vida urbana do Reino | Áudio | Tela do Reino |

**Versão inicial:** os edifícios precisam ser reconhecíveis por silhueta e
função; expansões, trabalhadores e detalhes logísticos entram depois.

## Sequência recomendada

1. Produzir a **carta P0**, porque ela valida identidade, iconografia e a
   primeira unidade.
2. Produzir a **batalha P0**, reutilizando a mesma unidade em 3D.
3. Produzir a **tela do Reino P0**, usando os materiais e a linguagem visual já
   validados.

## Critério de saída

A etapa P0 estará concluída quando os três fluxos puderem ser demonstrados
sem placeholders visíveis e mantendo a mesma identidade entre carta, campo de
batalha e Reino.
