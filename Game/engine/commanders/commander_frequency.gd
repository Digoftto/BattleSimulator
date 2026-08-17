class_name CommanderFrequency
extends RefCounted
## CommanderFrequency
##
## Implementa a tabela de conversão de rótulo de Frequência para Peso
## numérico definida em COMMANDER_GENERATION.md ("Sistema de Frequência").
##
## Esta tabela é única e compartilhada por todos os 5 bancos oficiais.
## Nenhum banco define seu próprio peso — apenas seu rótulo de Frequência.

const WEIGHTS: Dictionary = {
	"Muito Alta": 16,
	"Muito Alto": 16,
	"Alta": 8,
	"Alto": 8,
	"Média": 4,
	"Médio": 4,
	"Baixa": 2,
	"Baixo": 2,
	"Muito Baixa": 1,
	"Muito Baixo": 1,
}


## Retorna o Peso numérico correspondente a um rótulo de Frequência.
static func weight_for(frequency_label: String) -> int:
	assert(WEIGHTS.has(frequency_label),
		"CommanderFrequency: rótulo de Frequência desconhecido: '%s'" % frequency_label)
	return WEIGHTS.get(frequency_label, 1)
