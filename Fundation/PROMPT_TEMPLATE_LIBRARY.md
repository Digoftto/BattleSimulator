# PROMPT TEMPLATE LIBRARY

> Status: canônico para geração por IA. Esta biblioteca organiza a aplicação das
> Bíblias; não cria estilo, assets, facções ou materiais novos.

## 1. Filosofia

Todo prompt deve gerar algo que pareça consequência do mesmo mundo antigo,
físico e verossímil. Função, leitura, silhueta, materiais, Fundamentos e facção
vêm antes de ornamento ou cor. A biblioteca liga `Prompt_ID` a templates e
variáveis da base de produção, sem substituir as fontes canônicas.

| Regra consolidada | Origem |
|---|---|
| Função antes de ornamento; identidade antes de quantidade. | ART_BIBLE; ILLUSTRATION STYLE GUIDE |
| Asset legível por silhueta, modular, reutilizável e escalável. | ASSET_PRODUCTION_BIBLE |
| Ferro Negro = Estrutura; Cristais Arcanos = Ordem; Essência Vital = Fluxo. | ART_BIBLE |
| Evolução acrescenta refinamento, nunca troca identidade. | ART_BIBLE; CARD_ART_BIBLE; CARD_LAYOUT_BIBLE |
| Cenário e interface contextualizam; não competem com leitura. | BATTLEFIELD_ART_BIBLE; CARD_LAYOUT_BIBLE |

## 2. Fluxo oficial

```text
Necessidade → Asset Production Database → Asset Specification
→ Prompt Template + variáveis → Prompt Final → Imagem → Revisão
→ Biblioteca Oficial
```

`Asset_ID` é permanente. `Prompt_ID` aponta para um template e pode ser
compartilhado. As variáveis só podem ser preenchidas com dados da ficha e dos
documentos em `Reference_Document`. _Fonte: ASSET_PRODUCTION_BIBLE._

## 3. Hierarquia documental

| Escopo | Documento controlador | Uso desta biblioteca |
|---|---|---|
| Mundo, Fundamentos, facções e evolução | `ART_BIBLE.md` | Herdar linguagem global. |
| Câmera | `CAMERA_ART_BIBLE.md` | Preencher `{CAMERA}`. |
| Battlefield | `BATTLEFIELD_ART_BIBLE.md` | Separar território e condição temporária. |
| Arte de carta | `CARD_ART_BIBLE.md` | Preencher a ilustração. |
| Layout da carta | `CARD_LAYOUT_BIBLE.md` | Preencher moldura e interface. |
| Ilustração | `ILLUSTRATION STYLE GUIDE.MD` | Aplicar luz, material, paleta e composição. |
| Produção e QA | `ASSET_PRODUCTION_BIBLE.md` | Garantir escala, modularidade, variantes e aprovação. |

Em conflito, vale a precedência registrada em `ASSET_PRODUCTION_BIBLE.md`:
Art Bible Geral → Camera Bible → Battlefield Bible → Bíblia da facção → Asset
Production Bible. Em cartas, o Layout controla apresentação; a Card Art Bible
controla ilustração; ambas preservam as regras da facção.

## 4. Estrutura universal

```text
SUBJECT: {SUBJECT}
FUNCTION: {FUNCTION}
STYLE: {STYLE}
FACTION: {FACTION_RULE}
FOUNDATION: {FOUNDATION_RULE}
MATERIALS: {MATERIALS}
CAMERA: {CAMERA}
COMPOSITION: {COMPOSITION}
LIGHTING: {LIGHTING}
PALETTE: {PALETTE}
ATMOSPHERE: {ATMOSPHERE}
DETAIL_LEVEL: {DETAIL_LEVEL}
PRODUCTION: {PRODUCTION_REQUIREMENTS}
OUTPUT: {OUTPUT_FORMAT}
RESTRICTIONS: {GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}
```

`SUBJECT` identifica; `FUNCTION` justifica; `FACTION` e `FOUNDATION` definem a
interpretação; `CAMERA` e `COMPOSITION` protegem leitura; `PRODUCTION` preserva
reuso. _Fontes: ART_BIBLE, CAMERA_ART_BIBLE, ILLUSTRATION STYLE GUIDE e
ASSET_PRODUCTION_BIBLE._

## 5. Biblioteca de variáveis

| Variável | Uso canônico |
|---|---|
| `{ASSET_ID}`, `{PROMPT_ID}`, `{CATEGORY}`, `{SUBCATEGORY}` | Identificação e rastreabilidade no banco. |
| `{SUBJECT}`, `{FUNCTION}`, `{SCALE}`, `{VARIATIONS}`, `{OUTPUT_FORMAT}` | Ficha de produção; escala XS–XXL é relativa ao grid. |
| `{FACTION}`, `{FACTION_RULE}` | Império: Ferro → Essência → Cristais; Mortos-Vivos: Cristais → Ferro → Essência; Natureza: Essência → Cristais → Ferro. |
| `{FOUNDATION}`, `{FOUNDATION_RULE}` | Estrutura, Ordem ou Fluxo; comunicar comportamento, não apenas cor. |
| `{MATERIALS}`, `{MATERIAL_BEHAVIOR}` | Apenas materiais documentados para facção, território e função. |
| `{TERRITORY}` | Ambiente permanente: arquitetura, vegetação, geologia, horizonte e cultura. |
| `{BATTLEFIELD}` | Condição temporária: terreno, clima, luz, atmosfera e partículas. |
| `{CAMERA}` | Batalha: perspectiva isométrica, rotação próxima de 45°, inclinação de 35°–45° e enquadramento fixo. |
| `{COMPOSITION}`, `{SILHOUETTE_RULE}` | Foco claro, espaço negativo funcional e reconhecimento em silhueta. |
| `{LIGHTING}`, `{PALETTE}`, `{ATMOSPHERE}` | Luz controlada e paleta oficial de facção/território. |
| `{UNIT_TYPE}`, `{UNIT_CLASS}`, `{RARITY}`, `{TIER}` | Sistemas distintos da carta; Tier e raridade não alteram geometria. |
| `{CARD_ART_RULE}`, `{CARD_FRAME_RULE}`, `{UI_HIERARCHY}` | Arte em corpo inteiro, sem montaria; moldura: material → facção → raridade → Tier; arte comunica, ícones identificam, texto explica. |

## 6. Prompt negativo global

```text
cartoon, anime, sci-fi, neon, plastic rendering, excessive cinematic bloom,
excessive HDR, mirrored armor, exaggerated heroic pose, empty background,
floating objects without in-world explanation, exaggerated visible magic,
artificial arena, fragmented environment, disconnected scenery, flat top-down
camera, cinematic action camera, MOBA camera, RTS camera, extreme perspective,
uncontrolled ornamentation, visual clutter, generic imported-game aesthetic,
materials without physical behavior, faction identity dependent only on color
```

_Fontes: ILLUSTRATION STYLE GUIDE, CAMERA_ART_BIBLE, BATTLEFIELD_ART_BIBLE,
CARD_ART_BIBLE, CARD_LAYOUT_BIBLE e ART_BIBLE._

## 7. Templates universais

Preencher apenas variáveis aplicáveis. Campo sem fonte é removido; nunca recebe
texto inventado.

```text
CHARACTER_TEMPLATE / COMMANDER_TEMPLATE / PORTRAIT_TEMPLATE
{SUBJECT}; function: {FUNCTION}; {FACTION_RULE}; materials: {MATERIALS};
camera: {CAMERA}; composition: {COMPOSITION}; lighting: {LIGHTING}; palette:
{PALETTE}; silhouette: {SILHOUETTE_RULE}; output: {OUTPUT_FORMAT};
{GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

CREATURE_TEMPLATE
{SUBJECT}; ecological function: {FUNCTION}; territory: {TERRITORY}; natural
anatomy; readable silhouette; camera: {CAMERA}; scale: {SCALE}; output:
{OUTPUT_FORMAT}; {GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

BUILDING_TEMPLATE / PROP_TEMPLATE / ROAD_TEMPLATE / BRIDGE_TEMPLATE
{SUBJECT}; function visibly expressed: {FUNCTION}; {FACTION_RULE}; foundation:
{FOUNDATION_RULE}; materials: {MATERIALS}; territory: {TERRITORY}; camera:
{CAMERA}; modular and reusable; scale: {SCALE}; output: {OUTPUT_FORMAT};
{GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

RESOURCE_TEMPLATE / TREE_TEMPLATE / ROCK_TEMPLATE / VEGETATION_TEMPLATE
{SUBJECT}; world or ecological function: {FUNCTION}; territory: {TERRITORY};
foundation/material behavior: {MATERIAL_BEHAVIOR}; variations: {VARIATIONS};
output: {OUTPUT_FORMAT}; {GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

WEAPON_TEMPLATE / ARMOR_TEMPLATE / SHIELD_TEMPLATE / TOOL_TEMPLATE
{SUBJECT}; gameplay function: {FUNCTION}; {FACTION_RULE}; materials:
{MATERIALS}; scale: {SCALE}; readable silhouette; output: {OUTPUT_FORMAT};
{GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

FX_TEMPLATE / VFX_TEMPLATE
{SUBJECT}; gameplay function: {FUNCTION}; territory: {TERRITORY}; battlefield:
{BATTLEFIELD}; must preserve strategic readability; output: {OUTPUT_FORMAT};
{GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

ICON_TEMPLATE / UI_TEMPLATE
{SUBJECT}; single function: {FUNCTION}; {UI_HIERARCHY}; readable at target scale;
faction-neutral when shared; output: {OUTPUT_FORMAT}; {GLOBAL_NEGATIVE_PROMPT}
{CONTEXT_NEGATIVE_PROMPT}

CARD_ART_TEMPLATE
{SUBJECT}; type: {UNIT_TYPE}; class: {UNIT_CLASS}; {FACTION_RULE}; full body,
weapon visible when possible, origin background defocused, no mount; frontal,
slightly above eye line, half profile, about 20° lateral rotation; output:
{OUTPUT_FORMAT}; {GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

CARD_FRAME_TEMPLATE
{SUBJECT}; {CARD_FRAME_RULE}; rarity: {RARITY}; tier: {TIER}; preserve fixed
geometry, 60–65% art priority and readable indicators; output: {OUTPUT_FORMAT};
{GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}

BATTLEFIELD_TEMPLATE / ENVIRONMENT_TEMPLATE
{SUBJECT}; permanent territory: {TERRITORY}; temporary condition: {BATTLEFIELD};
materials and horizon continue beyond camera; camera: {CAMERA}; hierarchy:
cards, commanders, interface, battlefield, territory, horizon; output:
{OUTPUT_FORMAT}; {GLOBAL_NEGATIVE_PROMPT} {CONTEXT_NEGATIVE_PROMPT}
```

## 8. Regras de composição

- Ordem do prompt: função → identidade → materiais → câmera → composição → luz
  → atmosfera → produção.
- Batalha: cartas → comandantes → interface → Battlefield → território →
  horizonte. _Fonte: BATTLEFIELD_ART_BIBLE._
- Carta: facção → arte → tipo → Tier → raridade → atributos → nome → texto;
  layout é fixo e a arte ocupa 60–65%. _Fonte: CARD_LAYOUT_BIBLE._
- Não misturar `CARD_ART_TEMPLATE` com moldura/UI; um controla ilustração e o
  outro controla apresentação. _Fonte: CARD_ART_BIBLE; CARD_LAYOUT_BIBLE._

## 9. Regras de produção

1. Criar/localizar `Asset_ID` no banco de produção.
2. Preencher ficha, fontes, tipo, escala, materiais e dependências conhecidos.
3. Escolher `Prompt_ID` e o template correspondente.
4. Registrar o prompt mestre em `02_PROMPTS`; não duplicar prompt equivalente.
5. Gerar acima da resolução final, revisar, versionar, exportar e só então
   aprovar para Biblioteca Oficial/Godot.

_Fonte: ASSET_PRODUCTION_BIBLE._

## 10. Exemplos estruturais

```text
TREE_TEMPLATE + {SUBJECT} + {TERRITORY} + {MATERIALS} + {VARIATIONS}
→ prompt final preenchido apenas pela ficha aprovada.

CARD_FRAME_TEMPLATE + {FACTION_RULE} + {RARITY} + {TIER}
→ prompt final preserva geometria e muda somente indicadores permitidos.

BATTLEFIELD_TEMPLATE + {TERRITORY} + {BATTLEFIELD} + {LIGHTING}
→ prompt final preserva território e aplica somente condição temporária.
```

## 11. Checklist

- [ ] Há fonte canônica para asset e variáveis?
- [ ] Segue Art Bible, Camera Bible e Asset Production Bible?
- [ ] Battlefield preserva território e leitura estratégica?
- [ ] Carta segue Card Art Bible e Card Layout Bible no escopo correto?
- [ ] Silhueta, materiais, paleta e função estão claros?
- [ ] O resultado é modular, reutilizável e escalável quando aplicável?
- [ ] Prompt negativo global e restrições de contexto foram aplicados?
- [ ] Não há facção, material, asset ou detalhe inventado?

## Regra final

Se uma variável não possui base canônica, ela não entra no prompt. O asset volta
para especificação; não se improvisa conteúdo para gerar uma imagem.
