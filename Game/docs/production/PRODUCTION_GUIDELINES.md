# PRODUCTION_GUIDELINES

> A "constituição" do banco de produção. Responde a perguntas operacionais do dia a dia. Não redefine estrutura — ver `PRODUCTION_INDEX.md` para isso.

## Como criar um novo asset?

1. Confirme que o asset já existe **oficialmente na SSOT** (`.md` do projeto) ou nos `Resources` do Godot (`CardResource`, `AbilityResource`, `UnitTraitResource`, `BattlefieldResource`). Se não existir, ele precisa ser criado ali primeiro — o banco de produção nunca é o lugar onde uma entidade nasce.
2. Gere o ID seguindo a convenção já fixada (`CARD_<slug>`, `ABL_<slug>`, etc. — ver `PRODUCTION_INDEX.md`), usando o **nome oficial** já existente.
3. Crie a ficha na subpasta correspondente de `ASSET_DATABASE/` (domínio `GAME/`, `UI/`, `AUDIO/` ou `VISUAL/`).
4. Atualize a linha correspondente em `ASSET_DATABASE/ASSET_REGISTRY.md` (nova entrada, contagem "Total" +1).

## Quando um asset deve ganhar uma ficha?

Assim que tiver um **nome oficial fechado** na SSOT/Resources — não antes. Não crie fichas especulativas para conteúdo ainda em discussão de design (por isso `LORE/`, `VFX/` e as subpastas de `COMMANDERS/PATENTS/PORTRAITS` hoje só têm README, sem fichas).

## Quem pode criar novos documentos?

Qualquer pessoa da equipe pode preencher fichas e pipelines já existentes. Criar uma **pasta nova** ou reorganizar a árvore exige aprovação explícita do Diretor Técnico do projeto — a estrutura está congelada (ver `PRODUCTION_INDEX.md`) e só deve mudar diante de uma necessidade concreta, nunca antecipadamente.

## Como evitar duplicatas?

- Antes de criar uma ficha, procore pelo nome oficial em `ASSET_DATABASE/` — se um ID já existe, edite-o em vez de criar um novo.
- Nomes duplicados na própria SSOT (ex: a duplicidade documental conhecida de "Engenharia Militar" entre duas cartas) já são resolvidos no nome do arquivo de origem (`ex: engenharia_militar_capitao_imperial`) — o banco de produção **reusa esse mesmo nome de arquivo**, nunca inventa um novo.
- Uma Habilidade e uma Característica podem compartilhar o mesmo nome-base (ex: "Cura" existe nos dois catálogos) — o prefixo do ID (`ABL_` vs. `TRAIT_`) já evita colisão.

## Como manter a sincronização com a SSOT?

- O banco de produção **nunca é fonte de verdade de regra de jogo** — apenas de arte/áudio/interface. Se um nome mudar na SSOT (como já ocorreu nas Sprints 22–24 com renomeações de Habilidade), a ficha correspondente deve ser renomeada junto, no mesmo commit/revisão.
- Antes de cada grande marco de produção, faça uma varredura comparando os nomes em `ASSET_DATABASE/` contra os `Resources` atuais do Godot — o mesmo tipo de verificação já usada em `bootstrap.gd` para validar `CardResource`/`AbilityResource`/`UnitTraitResource`.

## Quando um asset está pronto para integração?

Quando passar pelas três colunas de `ASSET_REGISTRY.md`, em ordem:
1. **Produzido** — existe uma versão final do asset.
2. **Revisado** — passou pela checklist correspondente em `CHECKLISTS/` (consistência visual, nomenclatura, formato de exportação).
3. **Implementado** — já foi integrado ao projeto Godot pela Sprint correspondente.

Nenhum asset deve pular direto de "Produzido" para "Implementado" sem passar pela Revisão.

## Lembrete de escopo

Este banco existe para **acelerar** a produção, não para competir com ela em tempo e atenção. Se uma decisão de organização estiver consumindo mais tempo do que produzir o próprio asset, a resposta correta é a mais simples possível — nunca a mais elaborada.
