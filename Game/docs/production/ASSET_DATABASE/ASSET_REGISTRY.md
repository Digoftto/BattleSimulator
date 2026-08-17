# ASSET_REGISTRY

> Painel central de status de produção. Responde "quantos assets existem, quantos já foram produzidos, revisados e implementados" sem precisar abrir cada ficha individual em `ASSET_DATABASE/`. Atualizado manualmente conforme o trabalho avança — não é gerado automaticamente.

**Total de fichas com contagem fechada: 228** (não conta READMEs nem este próprio registro).

| Domínio | Categoria | Total | Produzido | Revisado | Implementado |
|---|---|---|---|---|---|
| GAME | CARDS | 39 | 0 | 0 | 0 |
| GAME | ABILITIES | 61 | 0 | 0 | 0 |
| GAME | TRAITS | 34 | 0 | 0 | 0 |
| GAME | BUILDINGS | 5 | 0 | 0 | 0 |
| GAME | COMMANDERS/ARCHETYPES | 3 | 0 | 0 | 0 |
| GAME | FACTIONS | 3 | 0 | 0 | 0 |
| GAME | ENVIRONMENTS | 3 | 0 | 0 | 0 |
| GAME | BATTLEFIELDS | 10 | 0 | 0 | 0 |
| GAME | RESOURCES | 6 | 0 | 0 | 0 |
| UI | HUD | 1 | 0 | 0 | 0 |
| UI | MENUS | 1 | 0 | 0 | 0 |
| UI | WINDOWS | 8 | 0 | 0 | 0 |
| UI | ICONS (Classes/Facções/Recursos/Tipos) | 18 | 0 | 0 | 0 |
| AUDIO | SFX | 10 | 0 | 0 | 0 |
| AUDIO | MUSIC | 10 | 0 | 0 | 0 |
| VISUAL | FX | 9 | 0 | 0 | 0 |
| VISUAL | ANIMATIONS | 7 | 0 | 0 | 0 |
| **TOTAL** | | **228** | **0** | **0** | **0** |

## Definição das colunas

- **Produzido:** o asset final existe (imagem, som ou animação entregue), ainda que sem revisão.
- **Revisado:** o asset passou pela checklist correspondente (ver `CHECKLISTS/`) e foi aprovado.
- **Implementado:** o asset já foi integrado ao projeto Godot.

## Categorias sem contagem fixa (não entram no total acima)

- `GAME/LORE/` — depende de curadoria narrativa, sem lista fechada.
- `VISUAL/VFX/` — reservada, sem lista fechada ainda (ver distinção pendente com `VISUAL/FX/`).
- `GAME/COMMANDERS/PATENTS/` e `GAME/COMMANDERS/PORTRAITS/` — dependem da decisão de granularidade registrada em `GAME/COMMANDERS/README.md`.
