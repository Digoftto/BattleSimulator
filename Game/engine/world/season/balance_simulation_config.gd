class_name BalanceSimulationConfig
extends RefCounted
## BalanceSimulationConfig (OBSERVATORY.md, "Meta Aleatório")
##
## Parâmetros de uma rodada de balanceamento — os mesmos que a
## interface (balance_report_panel.tscn) expõe pro jogador ajustar
## manualmente, ou que o modo automático usa com valores passados
## por fora.

## Quantas batalhas simular (OBSERVATORY.md usa 10.000 como
## referência oficial — sabidamente demorado; escala menor pra testes
## rápidos).
var series_count: int = 1000

## Semente do RNG — mesma seed = mesmo resultado exato (reprodutível).
var seed_value: int = 1

## Rótulo livre pra identificar esta rodada no Registro de Simulações
## (ex: "Validação Fase 3B", "Após nerf da Balista Imperial").
var label: String = "Rodada de Balanceamento"
