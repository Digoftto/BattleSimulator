class_name AbilityResource
extends Resource
## AbilityResource
##
## Representa uma Habilidade compartilhada (ABILITIES.md): Habilidade de
## Campanha (Tier III) ou Habilidade Avançada (Tier V). Compartilhada
## entre cartas — várias cartas podem referenciar a mesma Ability pelo
## nome (diferente de UnitTraitResource, exclusiva por carta).
##
## Nota: ABILITIES.md também cataloga 16 entradas rotuladas "Tier: I"
## ("Característica de Unidade") na mesma seção das Habilidades Tier V.
## Essas 16 entradas SÃO representadas como AbilityResource (definições
## de mecânica reutilizável), mas NÃO são o que uma carta referencia em
## CardResource.tier_1_trait_name — esse campo aponta para
## UnitTraitResource. Uma Característica de Unidade pode reaproveitar o
## nome/mecânica de uma dessas Abilities (ex: a Característica "Cura" da
## carta reaproveita a Ability "Cura"), mas os dois catálogos permanecem
## independentes (ver UnitTraitResource).
##
## Apenas dados — nenhuma lógica de execução (AbilitySystem, Sprint futura).

@export var ability_name: String = ""

## "Habilidade de Campanha" | "Característica de Unidade" | "Habilidade Avançada"
## (grafia exata da Categoria conforme ABILITIES.md).
@export var category: String = ""

## Tier ao qual a Habilidade pertence, conforme ABILITIES.md: 1, 3 ou 5.
@export var tier: int = 0

@export var trigger_description: String = ""
@export var target_description: String = ""
@export var effect_description: String = ""

## Bloco "Valores" — texto descritivo (heterogêneo entre habilidades:
## dano, duração, recarga, ativação, bônus, etc., conforme cada entrada
## de ABILITIES.md). Vazio quando a habilidade não possui Valores.
@export var values_description: String = ""

## Bloco "Observações". Vazio quando a habilidade não possui Observações
## ou quando a SSOT contém um erro de documentação não corrigido (ver
## "Perfurante" — Sprint 18: campo deliberadamente deixado vazio).
@export var notes: String = ""
