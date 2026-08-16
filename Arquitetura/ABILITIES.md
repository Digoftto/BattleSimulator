# Catálogo Oficial de Habilidades

Este documento constitui o registro e a definição técnica de todas as habilidades operacionais em Battle Simulator.
As regras gerais de resolução das habilidades encontram-se definidas em COMBAT_RULES.md.

Este documento define apenas o comportamento individual de cada habilidade.

**Integridade de Tier:** uma Carta nunca referencia uma Habilidade de Tier diferente do seu próprio campo (Tier III só referencia Habilidade de Tier III; Tier V só referencia Tier V). Regra estrutural da arquitetura — ver `DECISOES.md`, "Integridade entre Cartas e Habilidades".

**Nomenclatura:** o nome de uma Habilidade deve descrever a técnica, poder ou doutrina utilizada — nunca ser específico demais de uma única carta — para permanecer reutilizável por futuras cartas do mesmo arquétipo mecânico.

---

# Habilidades de Campanha (Tier III)

As Habilidades de Campanha produzem efeitos exclusivamente durante campanhas PvE e não possuem funcionalidade em modos PvP. Elas são ativadas apenas quando o pelotão pertence ao exército alocado na trilha correspondente.

### Sinergia de Campanha

Sinergia representa a interação entre dois ou mais pelotões diferentes presentes no mesmo Exército que possuem a mesma Habilidade de Campanha. Cada habilidade informa individualmente na seção "Valores" quais bônus sua Sinergia concede quando ativa.

## Extração de Ferro

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Exército alocado em uma Mina de Ferro conquistada.
*   **Alvo:** A produção da referida Mina.
*   **Efeito:** Aumenta a eficiência da extração de Ferro.
*   **Valores:**
    Bônus (Individual):
    +0%F
    Bônus (Sinergia):
    +25%
*   **Observações:** O bônus incide apenas sobre a produção da Mina protegida por aquele Exército.

## Extração de Cristais

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Exército alocado em uma Mina de Cristais conquistada.
*   **Alvo:** A produção da referida Mina.
*   **Efeito:** Aumenta a eficiência da extração de Cristais Arcanos.
*   **Valores:**
    Bônus (Individual):
    +0%
    Bônus (Sinergia):
    +25%
*   **Observações:** O bônus incide apenas sobre a produção da Mina protegida por aquele Exército.

## Extração de Essência

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Exército alocado em uma Mina de Essência conquistada.
*   **Alvo:** A produção da referida Mina.
*   **Efeito:** Aumenta a eficiência da extração de Essência Vital.
*   **Valores:**
    Bônus (Individual):
    +0%
    Bônus (Sinergia):
    +25%
*   **Observações:** O bônus incide apenas sobre a produção da Mina protegida por aquele Exército.

## Extração de Fragmentos

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Sinergia ativa.
*   **Alvo:** A produção de Fragmentos do referido exército alocado.
*   **Efeito:** Aumenta a produção de Fragmentos.
*   **Valores:**
    Bônus (Sinergia):
    +15%
*   **Observações:** O bônus incide apenas sobre os Fragmentos produzidos pelo Exército que está alocado. Não afeta recompensas de eventos, chefes ou missões.

## Treinamento de Comandantes

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Sinergia ativa e término de batalha PvE vencida.
*   **Alvo:** O Comandante responsável pelo referido Exército.
*   **Efeito:** Concede experiência (XP) adicional ao Comandante.
*   **Valores:**
    Bônus (Sinergia):
    +15% de XP
*   **Observações:** Não altera XP dos Pelotões ou da Conta. O bônus é aplicado apenas ao Comandante do Exército onde a sinergia está ativa.

## Suprimentos de Campanha

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Descanso em um Acampamento durante campanha PvE.
*   **Alvo:** O Exército onde o pelotão está presente.
*   **Efeito:** Aumenta a recuperação de Energia.
*   **Valores:**
    Bônus (Individual):
    +10% de recuperação
*   **Observações:** Múltiplos pelotões com esta habilidade não acumulam efeitos.

## Expansão do Acampamento

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Permanência na Trilha PvE.
*   **Alvo:** O Exército onde o pelotão está presente.
*   **Efeito:** Aumenta a Energia Máxima disponível.
*   **Valores:**
    Bônus (Individual):
    +1 Energia Máxima
*   **Observações:** Esta habilidade é acumulativa (+1 Energia Máxima por pelotão adicional com esta habilidade).

## Treinamento Ofensivo

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Permanência na Trilha PvE.
*   **Alvo:** Todas as unidades do Exército onde o pelotão está presente.
*   **Efeito:** Aumenta o Ataque de todas as unidades.
*   **Valores:**
    Bônus (Individual):
    +10% de Ataque
*   **Observações:** Múltiplos pelotões com esta habilidade não acumulam efeitos.

## Treinamento Defensivo

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Permanência na Trilha PvE.
*   **Alvo:** Todas as unidades do Exército onde o pelotão está presente.
*   **Efeito:** Aumenta o HP de todas as unidades.
*   **Valores:**
    Bônus (Individual):
    +10% de HP
*   **Observações:** Múltiplos pelotões com esta habilidade não acumulam efeitos.

## Fortificações de Campanha

*   **Categoria:** Habilidade de Campanha
*   **Tier:** III
*   **Gatilho:** Permanência na Trilha PvE.
*   **Alvo:** Todas as unidades do Exército onde o pelotão está presente.
*   **Efeito:** Aumenta o Escudo de todas as unidades.
*   **Valores:**
    Bônus (Individual):
    +10% de Escudo
*   **Observações:** Múltiplos pelotões com esta habilidade não acumulam efeitos.

---
# Característica de Unidade e Habilidade Avançada (Tier I e V)

Habilidades operacionais em combate (PvP e PvE). Característica de Unidade (Tier I) representam características inerentes, enquanto Habilidade Avançada (Tier V) representam maestria técnica.

## Voar

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Pelotão posicionado nas posições 2 a 9.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Torna o pelotão imune a alvos de ataques Corpo a Corpo.
*   **Observações:** Continua vulnerável a À Distância, Mago e dano por habilidades sem alvo direto (ex: Explosão). Ao alcançar a Posição 1, perde a proteção.

## Veneno

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Realização de ataque bem-sucedido.
*   **Alvo:** Pelotão atingido pelo ataque.
*   **Efeito:** Aplica 1 carga de Veneno. Novos ataques renovam a duração. Não possui acúmulo de cargas.
*   **Valores:**
    Dano:
    5 direta ao HP por turno
    Duração:
    3 turnos
*   **Observações:** Dano direto aplicado ao final do turno da unidade envenenada. Eliminação pelo Veneno conta para o pelotão que aplicou o efeito pela última vez.

## Regeneração

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Final do próprio turno.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recupera HP, respeitando o HP máximo..
*   **Valores:**
    Recuperação:
    20 HP
*   **Observações:** O efeito ocorre independentemente de o pelotão ter atacado. Não recupera Escudo.

## Resiliência

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Recebimento de dano de qualquer fonte.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Reduz o dano recebido.
*   **Valores:**
    Bônus:
    15% de redução de dano
*   **Observações:** A redução é aplicada antes da subtração do Escudo ou HP.

## Florescimento

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Realização de ação de cura.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Os bônus concedidos por Essência Vital tornam-se permanentes durante toda a batalha.
*   **Observações:** O efeito é cumulativo. Cada evento de cura concede apenas uma aplicação.

## Fonte da Vida

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Recuperação efetiva de HP.
*   **Alvo:** Pelotões aliados imediatamente à esquerda e à direita.
*   **Efeito:** Restaura HP aos alvos, respeitando o HP máximo.
*   **Valores:**
    Recuperação:
    10 HP
*   **Observações:** Caso exista apenas um pelotão adjacente, apenas ele será curado.

## Revitalização

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Recuperação efetiva de HP por pelotão aliado imediatamente à esquerda.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recupera HP, respeitando o HP máximo.
*   **Valores:**
    Recuperação:
    10 HP

## Compartilhar Dor

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Recebimento de dano.
*   **Alvo:** Pelotão aliado imediatamente atrás na mesma coluna.
*   **Efeito:** Transfere 50% do dano recebido para o alvo.
*   **Observações:** A divisão ocorre antes da aplicação ao Escudo/HP de ambas unidades. Mantém o tipo de dano original (físico/mágico). Caso não exista um pelotão atrás, o dano é aplicado integralmente ao alvo original.

## Cura

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Este pelotão executa a Cura Estrutural da Classe Suporte (ver COMBAT_RULES.md, seção 4.2.3).
*   **Alvo:** O mesmo aliado alvo da Cura Estrutural (aliado do próprio Exército com maior quantidade de HP perdido).
*   **Efeito:** Modificador da Carta sobre a Cura Estrutural (Hierarquia Oficial de Modificadores de Cura, COMBAT_RULES.md 4.2.3, nível 2). Não cria uma nova cura — soma-se ao valor base de 20 HP.
*   **Valores:**
    Bônus (adicional à Cura Estrutural):
    +20 HP
*   **Observações:** O total curado por este pelotão passa a ser 40 HP (20 HP da Regra Estrutural da Classe + 20 HP deste modificador). Afeta apenas aliados do próprio Exército. A própria unidade pode ser alvo. Se nenhum aliado estiver ferido, não produz efeito.

## Blindagem Inicial

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Início da batalha.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Gera Escudo adicional, somado ao ESC Base.
*   **Valores:**
    Escudo:
    +20 ESC
*   **Observações:** Caso o Escudo seja destruído, a habilidade não é ativada novamente. O bônus é concedido apenas uma vez por batalha. O Escudo concedido segue normalmente todas as regras gerais de Escudo.

## Berserk

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** HP atual ≤ 50% do HP máximo (verificado no início do turno).
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Aumenta o Ataque.
*   **Valores:**
    Ativação:
    HP ≤ 50%
    Bônus:
    +50% de Ataque
*   **Observações:** Se o HP for curado acima de 50%, Berserk é desativado no início do próximo turno.

## Reerguer

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Derrota do pelotão pela primeira vez na batalha.
*   **Alvo:** Próprio pelotão na mesma posição.
*   **Efeito:** Retorna imediatamente ao campo com 30% do HP Base.
*   **Observações:** Pode ser ativada apenas uma vez por batalha. A reanimação ocorre durante a etapa de Resolução das Mortes, conforme a ordem oficial definida em COMBAT_RULES.

## Dreno de Vida

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Realização de ataque que causa dano diretamente ao HP de um inimigo.
*   **Alvo:** Mesmo alvo do ataque e próprio pelotão.
*   **Efeito:** Causa dano adicional diretamente ao HP do mesmo alvo e recupera HP do próprio pelotão.
*   **Valores:**
    Dano:
    10 direta ao HP (adicional)
    Recuperação:
    10 HP
*   **Observações:** Caso o ataque não cause dano ao HP (apenas ao Escudo), Dreno de Vida não é ativado. A recuperação respeita o HP máximo.

## Camuflagem

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Primeira entrada na Linha 1.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Torna o pelotão invisível, impedindo que seja alvo de ataques diretos até o final daquele turno.
*   **Observações:** Ativada uma vez por batalha. Não impede dano causado por habilidades sem alvo direto.

## Explosão

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Derrota do pelotão.
*   **Alvo:** Unidade inimiga imediatamente à frente.
*   **Efeito:** Causa dano imediatamente antes da remoção do campo.
*   **Valores:**
    Dano:
    50
*   **Observações:** Dano pode ser absorvido por Escudo. Caso não exista unidade inimiga à frente, não produz efeito. Ativada apenas uma vez.

## Sacrifício

*   **Categoria:** Característica de Unidade
*   **Tier:** I
*   **Gatilho:** Derrota do pelotão.
*   **Alvo:** Todas as unidades aliadas vivas do mesmo Exército.
*   **Efeito:** Concede bônus temporário de Ataque.
*   **Valores:**
    Bônus:
    +20% de Ataque
    Duração:
    2 turnos
*   **Observações:** Efeitos de múltiplas unidades com Sacrifício no mesmo turno não acumulam; considera-se a maior duração.

## Ataque Duplo

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque.
*   **Alvo:** Mesmo alvo do ataque principal.
*   **Efeito:** Executa imediatamente um segundo ataque completo.
*   **Valores:**
    Dano (Segundo ataque):
    100% do Ataque
*   **Observações:** Se o primeiro ataque eliminar o alvo, o segundo atinge a unidade que ocupar a posição. Ambos ataques podem ativar outras habilidades. Não realiza ataques se estiver incapacitada.

## Ataque em Área

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque.
*   **Alvo:** Todos os inimigos da mesma Linha do alvo principal.
*   **Efeito:** Unidade na mesma coluna recebe ataque principal; demais na Linha recebem dano reduzido.
*   **Valores:**
    Dano (Alvo principal):
    100% do Ataque
    Dano (Demais unidades):
    50% do Ataque
*   **Observações:** Dano calculado individualmente. Habilidades ofensivas (ex: Veneno) aplicadas individualmente a cada atingido. Se existir apenas um inimigo na Linha, funciona como ataque normal.

## Provocar

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Permanência passiva em combate.
*   **Alvo:** Pelotões inimigos que ataquem a Linha ocupada por este pelotão.
*   **Efeito:** Torna este pelotão o alvo obrigatório de todos os ataques direcionados à linha que ocupa.
*   **Observações:** Sobrescreve a seleção padrão de alvo da coluna do atacante. Funciona desde que os atacantes sejam capazes de atacá-lo pelas regras de classe/habilidade e estejam atacando a mesma Linha.

## Perfuração

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque contra alvo com Escudo.
*   **Alvo:** Alvo principal.
*   **Efeito:** Divide o dano entre Escudo e HP.
*   **Valores:**
    Dano (Escudo):
    50% do Ataque (aplicado inicialmente)
    Dano (HP):
    50% do Ataque (aplicado diretamente)
*   **Observações:** Dano direto ao HP ignora o Escudo. Excedente destinado ao Escudo transfere para o HP se Escudo for destruído. Dano direto ao HP pode ativar habilidades como Dreno de Vida.

## Investida

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Primeiro ataque realizado após entrar na Linha 1.
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Concede bônus massivo de Ataque.
*   **Valores:**
    Bônus (Primeiro ataque):
    +200% de Ataque
*   **Observações:** Ativada uma vez por batalha. Se entrar na Linha 1 e não atacar no turno, a habilidade permanece disponível até o primeiro ataque.

## Contra-ataque

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de ataque corpo a corpo.
*   **Alvo:** Unidade agressora.
*   **Efeito:** Realiza imediatamente um ataque completo contra o agressor.
*   **Valores:**
    Dano (Contra-ataque):
    100% do Ataque
*   **Observações:** Pode ativar outras habilidades ofensivas. Não gera novo Contra-ataque. Não ativa se o pelotão for derrotado pelo ataque.

## Silêncio

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Início do turno.
*   **Alvo:** Uma unidade inimiga viva aleatória.
*   **Efeito:** Desativa todas as habilidades ativas e passivas do alvo.
*   **Valores:**
    Duração:
    1 turno
*   **Observações:** Não altera atributos básicos nem remove efeitos já aplicados.

## Atordoamento
*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque (respeitando tempo de recarga).
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Impede o alvo de atacar no turno seguinte à aplicação.
*   **Valores:**
    Duração:
    Até o próximo ataque do alvo
    Recarga:
    3 turnos
*   **Observações:** Impede apenas o ataque da unidade. Efeito não cumulativo.

## Cegueira

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque (respeitando tempo de recarga).
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Aplica chance de erro aos ataques do alvo.
*   **Valores:**
    Bônus (Chance de erro):
    50%
    Duração:
    2 turnos
    Recarga:
    3 turnos
*   **Observações:** Chance verificada individualmente por ataque. Se ataque falhar por Cegueira, dano e efeitos secundários (Veneno, etc.) não são aplicados. Habilidades de Precisão podem anular Cegueira. Efeito não cumulativo.

## Desarme

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque (respeitando tempo de recarga).
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Reduz temporariamente o atributo Ataque do alvo.
*   **Valores:**
    Bônus (Redução de Ataque):
    50%
    Duração:
    2 turnos
    Recarga:
    3 turnos
*   **Observações:** Redução aplicada antes de outros modificadores. Novas aplicações apenas renovam a duração. Efeito não cumulativo.

## Precisão

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ataque contra alvo com habilidades de evasão/ocultação compatíveis.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Ignora efeitos defensivos baseados em evasão ou ocultação, garantindo que o ataque atinja o alvo.
*   **Observações:** Ignora Camuflagem. Não altera o dano causado.

## Refletir Dano

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de dano de um ataque direto.
*   **Alvo:** Unidade atacante.
*   **Efeito:** Devolve parcela do dano efetivamente recebido imediatamente após a resolução do ataque.
*   **Valores:**
    Bônus (Reflexo):
    Reflete 30% do dano recebido
*   **Observações:** Ignora distância. Dano refletido absorvido por Escudo/HP e não ativa habilidades secundárias. Ataques sem dano não geram reflexão.

## Sobrevivência

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de dano letal pela primeira vez na batalha.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Anula a morte e define o HP atual para 1.
*   **Valores:**
    Ativação:
    1 vez por batalha
    HP restante:
    1 HP
*   **Observações:** Habilidade consome-se após o uso. Não recupera Escudo.

## Inspiração

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Início do turno.
*   **Alvo:** Pelotão aliado ocupando a Posição 3 do mesmo Exército.
*   **Efeito:** Concede bônus temporário de Ataque.
*   **Valores:**
    Bônus:
    +20% de Ataque
    Duração:
    1 turno
*   **Observações:** Determinado pela ocupação no início do turno. Não afeta a própria unidade, exceto se ocupar a posição 3. Efeito não cumulativo.

## Proteção

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de dano de ataque direto por aliado imediatamente à frente.
*   **Alvo:** Aliado à frente e próprio pelotão.
*   **Efeito:** Redireciona parte do dano recebido pelo aliado para si.
*   **Valores:**
    Dano (Redirecionado):
    50% para a unidade com Proteção
    Dano (Restante):
    50% no alvo original
*   **Observações:** Divisão ocorre antes da aplicação ao Escudo/HP de cada unidade. Afeta apenas ataques diretos. Cessa se protetor for derrotado. Múltiplas Proteções não acumulam no mesmo alvo.

## Execução

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ataque contra unidade com HP atual ≤ 30% do HP máximo (verificado no início do turno).
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Recebe bônus de dano no ataque.
*   **Valores:**
    Ativação:
    HP ≤ 30%
    Bônus:
    +50% de Ataque

## Fúria

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Derrota de unidade inimiga da mesma coluna por qualquer fonte.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recebe bônus temporário de Ataque.
*   **Valores:**
    Bônus:
    +20% de Ataque
    Duração:
    2 turnos
*   **Observações:** Novas ativações apenas renovam duração. Não necessita que eliminação tenha sido pelo pelotão com Fúria. Efeito não cumulativo.

## Corrente Elétrica

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de um ataque.
*   **Alvo:** Alvo principal e unidades inimigas atrás dele na mesma coluna.
*   **Efeito:** Alvo principal recebe ataque normal. Descarga propaga-se pela coluna atingindo unidades atrás com dano reduzido progressivamente.
*   **Valores:**
    Dano (Primeiro alvo):
    100% do Ataque
    Dano (Segundo alvo):
    50% do Ataque
    Dano (Terceiro alvo):
    25% do Ataque
*   **Observações:** Apenas alvo principal ativa habilidades ofensivas secundárias; secundários recebem apenas dano elétrico.

## Campo de Força

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento do primeiro ataque durante a batalha.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Anula completamente o primeiro ataque recebido.
*   **Valores:**
    Ativação:
    1 vez por batalha
    Ataques anulados:
    1
*   **Observações:** Habilidade destrói-se após o uso. Não bloqueia dano ao Escudo/HP após consumo.

## Trespassar

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Eliminação de um alvo durante o ataque do pelotão.
*   **Alvo:** Próximo alvo válido da mesma linha.
*   **Efeito:** Realiza imediatamente um novo ataque completo.
*   **Observações:** Prioridade de seleção de alvo na linha segue direção da linha de frente para retaguarda conforme definido em COMBAT_RULES.

## Perfurante

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização do ataque contra alvo que possua Escudo.
*   **Alvo:** Alvo do ataque.
*   **Efeito:** Causa dano adicional.
*   **Valores:**
    Bônus:
    +20% de dano
*  **Observações:** O segundo ataque do Trespassar é enfileirado e executado imediatamente após a resolução da ação principal dentro da Fase de Execução, reavaliando a ordem de prioridade de alvos vivos na mesma linha no Combat State.

## Concentração

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Permanência passiva em combate sem ter sofrido dano desde o início da batalha.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recebe bônus de Ataque Base.
*   **Valores:**
    Bônus:
    +15% do Ataque Base
*   **Observações:** O bônus é perdido imediatamente após o pelotão sofrer dano pela primeira vez.

## Comando Tático

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Avanço de aliado para a Posição 5 enquanto este pelotão permanece vivo.
*   **Alvo:** Pelotões aliados.
*   **Efeito:** Pelotões alvos não perdem sua ação no turno em que avançam para a Posição 5.
*   **Observações:** Múltiplos pelotões com Comando Tático não acumulam efeitos.

## Tiro de Flanco

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ataque após ter mudado de linha no turno anterior.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recebe bônus de Ataque Base durante este ataque.
*   **Valores:**
    Bônus:
    +40% do Ataque Base

## Engenharia Militar

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ação de cura.
*   **Alvo:** Pelotão aliado com maior dano absoluto no Escudo.
*   **Efeito:** As ações de cura restauram Escudo em vez de HP.
*   **Observações:** Utiliza o mesmo critério de seleção de alvo da habilidade Cura (maior dano absoluto). Múltiplos pelotões com Engenharia Militar não acumulam efeitos.

## Vontade Persistente

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Derrota de qualquer pelotão aliado.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recupera HP.
*   **Valores:**
    Recuperação:
    10 HP
*   **Observações:** Nome mecânico genérico e reutilizável. Algumas cartas podem se referir a esta Habilidade por um nome narrativo próprio (ex: "Trono dos Mortos", no Lich Rei) — o efeito mecânico é sempre este, sem duplicidade de definição.

## Comando de Reparos

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ação de cura.
*   **Alvo:** 3 pelotões aliados com maior dano absoluto no Escudo.
*   **Efeito:** As ações de cura restauram Escudo em vez de HP, distribuído entre os alvos.
*   **Observações:** Versão avançada de Engenharia Militar, nomeada para comunicar liderança/suporte em vez de soar como uma sequência numerada da Habilidade original. Afinidade III: a restauração ocorre em 4 pelotões. Valores extraídos diretamente da ficha de Capitão Imperial (CARD_CATALOG.md), sem alteração de balanceamento.

## Sede de Sangue

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ataque que causa dano diretamente ao HP de um inimigo.
*   **Alvo:** Mesmo alvo do ataque e próprio pelotão.
*   **Efeito:** Causa dano adicional diretamente ao HP do mesmo alvo e recupera HP do próprio pelotão.
*   **Valores:**
    Dano:
    10 direto ao HP (adicional)
    Recuperação:
    10 HP
*   **Observações:** Versão de Tier V com os mesmos valores de Dreno de Vida (Tier I). Criada para corrigir a referência quebrada "Drenar Vida" (Esqueleto Guerreiro, Abominação Putrefata).

## Vigor Perene

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Final do próprio turno.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recupera HP, respeitando o HP máximo.
*   **Valores:**
    Recuperação:
    20 HP
*   **Observações:** Versão de Tier V com os mesmos valores de Regeneração (Tier I). Criada para corrigir a referência quebrada "Regeneração" (Árvore Ancestral).

## Casca Resiliente

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de dano de qualquer fonte.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Reduz o dano recebido.
*   **Valores:**
    Bônus:
    15% de redução de dano
*   **Observações:** Versão de Tier V com os mesmos valores de Resiliência (Tier I). Criada para corrigir a referência quebrada "ResiliênciaS" (Carvalho Milenar).

## Bênção Vital

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recuperação efetiva de HP por pelotão aliado imediatamente à esquerda.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Recupera HP, respeitando o HP máximo.
*   **Valores:**
    Recuperação:
    10 HP
*   **Observações:** Versão de Tier V com os mesmos valores de Revitalização (Tier I). Criada para corrigir a referência quebrada "Revitalização" (Salgueiro Ancião, Unicórnio Ancestral). Nomeada para expressar uma dádiva mágica de vida, evitando ser apenas um sinônimo de Revitalização.

## Floração Eterna

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Realização de ação de cura.
*   **Alvo:** Próprio pelotão.
*   **Efeito:** Os bônus concedidos por Essência Vital tornam-se permanentes durante toda a batalha.
*   **Observações:** Versão de Tier V com o mesmo efeito de Florescimento (Tier I). Criada para corrigir a referência quebrada "Florescimento" (Coração da Floresta).

## Ressurreição Espectral

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Derrota do pelotão pela primeira vez na batalha.
*   **Alvo:** Próprio pelotão na mesma posição.
*   **Efeito:** Retorna imediatamente ao campo com 30% do HP Base.
*   **Observações:** Versão de Tier V com o mesmo efeito de Reerguer (Tier I). Criada para corrigir a referência quebrada "Reerguer" (Arqueira Espectral).

## Vínculo Cadavérico

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Recebimento de dano.
*   **Alvo:** Pelotão aliado imediatamente atrás na mesma coluna.
*   **Efeito:** Transfere 50% do dano recebido para o alvo.
*   **Observações:** Versão de Tier V com o mesmo efeito de Compartilhar Dor (Tier I). Criada para corrigir a referência quebrada "Compartilhar Dor" (Ceifador Cadavérico). Nome escolhido para descrever a técnica (um vínculo que compartilha dano), não a anatomia de uma carta específica — reutilizável por qualquer futura unidade com o mesmo arquétipo mecânico.

## Detonação Ritual

*   **Categoria:** Habilidade Avançada
*   **Tier:** V
*   **Gatilho:** Derrota do pelotão.
*   **Alvo:** Unidade inimiga imediatamente à frente.
*   **Efeito:** Causa dano imediatamente antes da remoção do campo.
*   **Valores:**
    Dano:
    50
*   **Observações:** Versão de Tier V com os mesmos valores de Explosão (Tier I). Criada para corrigir a referência quebrada "Explosão" (Altar da Reanimação).

# Habilidades de Fortalecimento (Reservadas)

*   **Categoria:** Habilidade Avançada
*   **Descrição:** Reservada para futuras habilidades de fortalecimento. Nenhuma habilidade desta categoria integra a versão atual do jogo.