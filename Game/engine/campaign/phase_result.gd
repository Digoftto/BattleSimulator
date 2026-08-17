class_name PhaseResult
extends RefCounted
## PhaseResult
##
## Resultado de uma Tentativa de Fase (PvE.md): o conjunto completo de
## combates realizados ao tentar vencer uma única Fase, percorrendo os
## Exércitos do Squad e as Formações de cada um conforme a prioridade
## configurada. Apenas dado — nenhuma lógica.

var victory: bool = false

## Índice (em squad.armies) do Exército que obteve a vitória, ou -1 se
## nenhum venceu.
var winning_army_index: int = -1

## Nome da Formação vencedora ("α".."ε"), ou "" se nenhuma venceu.
var winning_formation: String = ""

## O EnemyArmyEntry contra o qual esta Fase foi disputada — presente
## independentemente do resultado (vitória ou derrota). Necessário para
## que sistemas futuros (Recompensa, Recrutamento) saibam quem foi
## enfrentado/derrotado sem precisar reconstruir esse contexto.
##
## Princípio desta classe: PhaseResult deve conter todas as informações
## necessárias para resolver as consequências da batalha — mas nunca
## referências a Kingdom, ExpeditionRuntime ou qualquer outro sistema
## que não seja o próprio resultado do combate. Ele permanece um
## resultado puro.
var opponent_entry: EnemyArmyEntry

## Quantidade total de combates (tentativas de Formação) realizados
## nesta Tentativa de Fase, somando todos os Exércitos percorridos.
var attempts: int = 0

## Quantidade de Pelotões inimigos destruídos na tentativa vencedora
## (RESOURCES.md §4: só Pelotões Originais geram Fragmentos, nunca
## Conjurados — hoje nenhuma Habilidade/Característica implementada
## invoca pelotões durante a batalha, então todo eliminado do lado
## inimigo é, por ora, Pelotão Original). Necessário para RewardResolver
## calcular a recompensa sem reconstruir o contexto do combate.
var enemy_pelotoes_destroyed: int = 0

## Mesma contagem acima, mas separada por Facção do Pelotão destruído
## (RESOURCES.md §4: "Correspondência de Facção: o fragmento gerado
## pertence sempre à mesma facção do pelotão destruído" — nunca a
## Facção principal do oponente como um todo, já que a composição
## inimiga mistura Facções, PvE.md). {Facção: quantidade}.
var enemy_pelotoes_destroyed_by_faction: Dictionary = {}

## Registro textual estrutural (mesma convenção de CombatState.battle_log).
var history_log: Array[String] = []
