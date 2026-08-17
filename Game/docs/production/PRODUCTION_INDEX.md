# PRODUCTION_INDEX

> Índice mestre do banco de produção de assets do Battle Simulator. Ponto de entrada único para toda a documentação de produção. Estrutura revisada e congelada nesta versão — ver `PRODUCTION_GUIDELINES.md` para as regras operacionais do dia a dia.

Este banco é **totalmente independente da implementação em Godot**. A implementação continua nas Sprints normais.

Total de arquivos: **336** (335 templates/README + este índice).

---

## Estrutura de Alto Nível

```text
production/
├── PRODUCTION_INDEX.md
├── PRODUCTION_GUIDELINES.md
├── ART_DIRECTION/        (como o jogo deve parecer — visão macro)
├── ART_BIBLE/            (como desenhar cada elemento — guias específicos)
├── DESIGN_LANGUAGE/      (interpretação de elementos recorrentes: pedra, ferro, magia, etc.)
├── CONSISTENCY/          (regras negativas/positivas — o que nunca fazer)
├── STYLE_GUIDES/         (guia de estilo por categoria de asset)
├── REFERENCES/           (referências visuais externas + moodboards)
├── ASSET_DATABASE/       (fichas de produção, organizadas por domínio)
├── PIPELINES/            (fluxo de produção por tipo de asset)
├── PROMPTS/              (biblioteca de prompts, por elemento e depois por modelo)
├── CHECKLISTS/           (critérios de conclusão)
├── EXPORT/               (especificações de exportação final)
└── WORKFLOW/             (processos operacionais do banco)
```

---

## 1. `ART_DIRECTION/` (4 arquivos)

Responde **"como o jogo deve parecer"** — filosofia visual, linguagem de cor, iluminação (nível macro/atmosfera).

`00_VISUAL_PHILOSOPHY.md`, `01_COLOR_LANGUAGE.md`, `03_LIGHTING.md`, `README.md`.

## 2. `ART_BIBLE/` (9 arquivos)

Responde **"como desenhar cada elemento"** — guias técnicos específicos.

`02_MATERIALS.md`, `04_ARCHITECTURE.md`, `05_CHARACTER_DESIGN.md`, `06_ENVIRONMENTS.md`, `07_UI_LANGUAGE.md`, `08_CARD_ART.md`, `09_EFFECTS.md`, `10_ANIMATION.md`, `README.md`.

## 3. `DESIGN_LANGUAGE/` (12 arquivos)

Como interpretar elementos visuais recorrentes, para evitar divergência entre diferentes produtores/IAs: `DL_predio`, `DL_pedra`, `DL_couro`, `DL_ferro`, `DL_espada`, `DL_bandeira`, `DL_arvore`, `DL_montanha`, `DL_magia`, `DL_fumaca`, `DL_iluminacao`, `README.md`.

## 4. `CONSISTENCY/` (5 arquivos)

Regras de consistência visual/narrativa: `DO_NOT_DO.md`, `VISUAL_RULES.md`, `WORLD_RULES.md`, `COMMON_MISTAKES.md`, `README.md`.

## 5. `STYLE_GUIDES/` (7 arquivos)

Subpastas: `FACTIONS/`, `CARDS/`, `UI/`, `ICONS/`, `BUILDINGS/`, `COMMANDERS/` (cada uma com `README.md`) + `README.md` geral.

## 6. `REFERENCES/` (8 arquivos)

Subpastas: `CARDS/`, `BUILDINGS/`, `FACTIONS/`, `ENVIRONMENTS/`, `UI/`, `FX/`, `MOODBOARDS/` (cada uma com `README.md`) + `README.md` geral.

## 7. `ASSET_DATABASE/` (247 arquivos, incluindo `ASSET_REGISTRY.md`)

Reorganizada por **domínio** — Cartas pertencem ao jogo, janelas pertencem à interface, efeitos pertencem ao visual:

```text
ASSET_DATABASE/
├── README.md
├── ASSET_REGISTRY.md        (painel de status — ver contagens ali, não repetidas aqui)
├── GAME/
│   ├── CARDS/ (39)           ABILITIES/ (61)        TRAITS/ (34)
│   ├── BUILDINGS/ (5)        COMMANDERS/
│   │                           ├── ARCHETYPES/ (3)  ├── PATENTS/ (reservada)
│   │                           └── PORTRAITS/ (reservada)
│   ├── FACTIONS/ (3)         ENVIRONMENTS/ (3)      BATTLEFIELDS/ (10)
│   └── RESOURCES/ (6)        LORE/ (reservada)
├── UI/
│   ├── HUD/ (1)              MENUS/ (1)
│   ├── WINDOWS/ (8)          ICONS/ (18, em CLASSES/FACCOES/RECURSOS/TIPOS)
├── AUDIO/
│   ├── SFX/ (10)             MUSIC/ (10)
└── VISUAL/
    ├── FX/ (9)               VFX/ (reservada)       ANIMATIONS/ (7)
```

Consulte `ASSET_DATABASE/ASSET_REGISTRY.md` para o total consolidado e o status de cada categoria.

## 8. `PIPELINES/` (9 arquivos)

`CARD_PIPELINE.md`, `BUILDING_PIPELINE.md`, `ICON_PIPELINE.md`, `UI_PIPELINE.md`, `AUDIO_PIPELINE.md`, `MUSIC_PIPELINE.md`, `ANIMATION_PIPELINE.md`, `FX_PIPELINE.md`, `README.md`.

## 9. `PROMPTS/` (12 arquivos)

Organizada primeiro por **elemento**, depois por **modelo** — o prompt pertence ao asset, não à ferramenta:

```text
PROMPTS/
├── BASE_PROMPTS/  GAME_ELEMENTS/  CHARACTERS/  BUILDINGS/
├── CARDS/         UI/             ICONS/       FX/
└── MODELS/
    ├── GPT_IMAGE/  FLUX/  MJ/
```

## 10. `CHECKLISTS/` (6 arquivos)

`ART_CHECKLIST.md`, `UI_CHECKLIST.md`, `AUDIO_CHECKLIST.md`, `ANIMATION_CHECKLIST.md`, `IMPLEMENTATION_SYNC.md`, `README.md`.

## 11. `EXPORT/` (1 arquivo)

`README.md` — especificações de exportação a definir.

## 12. `WORKFLOW/` (6 arquivos)

`PRODUCTION_FLOW.md`, `NAMING_CONVENTIONS.md`, `FOLDER_CONVENTIONS.md`, `VERSIONING.md`, `REVIEW_PROCESS.md`, `README.md`.

---

## Convenção de IDs (inalterada)

```
CARD_<slug>  ABL_<slug>  TRAIT_<slug>  BLD_<slug>  CMD_<faccao>
FCT_<slug>   ENV_regiao_<faccao>  BFD_<slug>  ICO_<categoria>_<slug>
UI_<slug>    FX_<slug>   SFX_<slug>   MUS_<slug>   ANIM_<slug>  RES_<slug>
```

`<slug>` sempre em minúsculas, sem acentos. O nome-fonte é sempre o nome oficial já existente na SSOT/Resource correspondente.

---

## Estrutura congelada

Esta é a versão definitiva da estrutura de pastas. Novas pastas ou reorganizações só devem ocorrer diante de uma necessidade concreta identificada durante a produção — não antecipadamente. Ver `PRODUCTION_GUIDELINES.md` para o processo de solicitar uma exceção.
