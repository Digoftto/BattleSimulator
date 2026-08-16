# DL_BATTLEFIELDS.md

> **Status:** CANÔNICO — CONGELADO PARA PRODUÇÃO
>
> **Escopo:** identidade visual, organização espacial, composição, leitura, atmosfera, integração da interface e princípios de produção de todos os campos de batalha do Battle Simulator.
>
> **Regra de precedência:** este documento define exclusivamente o campo de batalha. A aparência das unidades continua sendo responsabilidade das respectivas Art Bibles das facções. A interface segue o UI Design System.

---

# 1. Propósito

Esta documentação estabelece a linguagem visual oficial dos campos de batalha do Battle Simulator.

Seu objetivo é garantir que todos os mapas, independentemente da região, campanha ou modo de jogo, compartilhem a mesma organização espacial, leitura visual e identidade.

O campo nunca deve competir com as cartas.

Ele existe para valorizá-las.

Ao iniciar uma batalha, o jogador deve compreender imediatamente:

- onde cada exército está;
- quais são as posições disponíveis;
- onde estão os comandantes;
- qual é o sentido do combate.

O cenário complementa a batalha.

Nunca a domina.

---

# 2. Declaração Central

O campo de batalha representa o local onde dois exércitos se enfrentam.

Ele não representa uma cidade, um mapa explorável ou um ambiente aberto.

Seu propósito é fornecer clareza tática.

Toda decisão artística deve preservar essa função.

O jogador nunca deve procurar onde posicionar uma unidade.

A organização do espaço deve ser imediatamente compreendida.

---

## Impressões obrigatórias

Todo campo deve transmitir:

- organização;
- clareza;
- profundidade;
- escala;
- estabilidade;
- leitura imediata.

Jamais:

- poluição visual;
- excesso de elementos decorativos;
- obstáculos artificiais;
- confusão espacial;
- competição visual com as cartas.

---

# DNA VISUAL DOS CAMPOS

Antes de produzir qualquer campo aplicar cinco princípios.

## 1.

As cartas são protagonistas.

---

## 2.

O cenário apoia a batalha.

Nunca disputa atenção.

---

## 3.

Toda posição deve ser imediatamente reconhecida.

---

## 4.

A leitura do campo deve permanecer clara mesmo durante efeitos visuais intensos.

---

## 5.

Toda decisão estética deve favorecer a compreensão tática.

---

# 3. Pilares Visuais

| Pilar | Aplicação |
|--------|-----------|
| Clareza | leitura imediata do grid |
| Hierarquia | cartas acima do cenário |
| Profundidade | sensação de espaço sem prejudicar a leitura |
| Consistência | mesma organização em todos os mapas |
| Neutralidade | terreno não favorece visualmente nenhuma facção |

---

# 4. Estrutura Geral

Todo campo utiliza exatamente a mesma arquitetura.

Mudam apenas:

- bioma;
- iluminação;
- clima;
- materiais;
- elementos decorativos.

Nunca muda:

- posição do grid;
- posição dos comandantes;
- perspectiva;
- proporções gerais.

---

# 5. Área Jogável

O combate acontece exclusivamente dentro de dois grids de **3 × 3 posições**.

Cada exército possui um grid próprio.

As unidades nunca ocupam posições fora dessa área.

---

## Grid Canônico

A numeração oficial das posições é:

```text
EXÉRCITO INIMIGO

7   8   9
6   5   4
1   2   3

────────────────────────────

1   2   3
6   5   4
7   8   9

EXÉRCITO DO JOGADOR
```

Esta numeração constitui referência canônica para:

- combate;
- documentação;
- animações;
- IA;
- efeitos;
- programação;
- ferramentas internas.

Nenhuma documentação poderá utilizar outra orientação.

---

## Leitura Espacial

O jogador observa ambos os grids simultaneamente.

As duas formações devem ser percebidas como um único campo de batalha.

A separação visual existe apenas para facilitar a leitura.

Ela não representa distância física significativa.

---

# 6. Comandantes

Os comandantes não pertencem ao grid.

Eles nunca ocupam uma posição de batalha.

Sua função é representar o líder estratégico do exército.

---

## Localização

O comandante inimigo permanece no:

**canto superior esquerdo**.

O comandante do jogador permanece no:

**canto inferior direito**.

Essas posições são permanentes.

Nenhum modo de jogo altera essa organização.

---

## Representação

Os comandantes não são retratos.

Eles são representados como personagens completos, utilizando exatamente a mesma linguagem artística dos pelotões.

A visualização permanece isométrica.

Isso preserva a unidade visual entre todas as entidades presentes no combate.

---

## Animal de Guerra

Cada comandante aparece acompanhado do grande herbívoro característico de sua facção.

Esse animal representa:

- autoridade;
- tradição;
- identidade da facção.

Ele não ocupa posições do grid.

Também não participa diretamente do combate.

Sua presença é simbólica e visual.

---

## Interface do Comandante

O comandante não possui:

- Ataque;
- Vida;
- Escudo;
- atributos de combate.

Junto ao comandante aparece apenas:

- Afinidade atual do exército.

Toda informação referente ao estado estratégico do exército permanece associada ao comandante.

Informações das unidades permanecem associadas às cartas.

Essa separação nunca deve ser quebrada.

---

# 7. Hierarquia Visual

A ordem de importância visual durante uma batalha é:

1. Cartas.
2. Comandantes.
3. Interface.
4. Campo.
5. Horizonte.

Nenhum elemento inferior pode competir visualmente com um superior.

---

# 8. Proporções

Como referência geral:

| Elemento | Área aproximada |
|-----------|----------------:|
| Cartas | 60% |
| Campo | 20% |
| Interface | 15% |
| Horizonte | 5% |

Esses valores servem como referência de equilíbrio.

Não representam medidas absolutas.

---

# 9. Regras Fundamentais

1. O grid constitui o centro visual da batalha.
2. Nenhuma unidade pode existir fora do grid.
3. Comandantes nunca ocupam posições do campo.
4. O comandante representa o exército; as cartas representam as unidades.
5. A Afinidade pertence ao exército e é exibida junto ao comandante.
6. A organização espacial permanece idêntica em todos os campos do jogo.

# DL_BATTLEFIELDS.md

> **Status:** CANÔNICO — CONGELADO PARA PRODUÇÃO
>
> **Escopo:** identidade visual, organização espacial, composição, leitura, atmosfera, integração da interface e princípios de produção de todos os campos de batalha do Battle Simulator.
>
> **Regra de precedência:** este documento define exclusivamente o campo de batalha. A aparência das unidades continua sendo responsabilidade das respectivas Art Bibles das facções. A interface segue o UI Design System.

---

# 1. Propósito

Esta documentação estabelece a linguagem visual oficial dos campos de batalha do Battle Simulator.

Seu objetivo é garantir que todos os mapas, independentemente da região, campanha ou modo de jogo, compartilhem a mesma organização espacial, leitura visual e identidade.

O campo nunca deve competir com as cartas.

Ele existe para valorizá-las.

Ao iniciar uma batalha, o jogador deve compreender imediatamente:

- onde cada exército está;
- quais são as posições disponíveis;
- onde estão os comandantes;
- qual é o sentido do combate.

O cenário complementa a batalha.

Nunca a domina.

---

# 2. Declaração Central

O campo de batalha representa o local onde dois exércitos se enfrentam.

Ele não representa uma cidade, um mapa explorável ou um ambiente aberto.

Seu propósito é fornecer clareza tática.

Toda decisão artística deve preservar essa função.

O jogador nunca deve procurar onde posicionar uma unidade.

A organização do espaço deve ser imediatamente compreendida.

---

## Impressões obrigatórias

Todo campo deve transmitir:

- organização;
- clareza;
- profundidade;
- escala;
- estabilidade;
- leitura imediata.

Jamais:

- poluição visual;
- excesso de elementos decorativos;
- obstáculos artificiais;
- confusão espacial;
- competição visual com as cartas.

---

# DNA VISUAL DOS CAMPOS

Antes de produzir qualquer campo aplicar cinco princípios.

## 1.

As cartas são protagonistas.

---

## 2.

O cenário apoia a batalha.

Nunca disputa atenção.

---

## 3.

Toda posição deve ser imediatamente reconhecida.

---

## 4.

A leitura do campo deve permanecer clara mesmo durante efeitos visuais intensos.

---

## 5.

Toda decisão estética deve favorecer a compreensão tática.

---

# 3. Pilares Visuais

| Pilar | Aplicação |
|--------|-----------|
| Clareza | leitura imediata do grid |
| Hierarquia | cartas acima do cenário |
| Profundidade | sensação de espaço sem prejudicar a leitura |
| Consistência | mesma organização em todos os mapas |
| Neutralidade | terreno não favorece visualmente nenhuma facção |

---

# 4. Estrutura Geral

Todo campo utiliza exatamente a mesma arquitetura.

Mudam apenas:

- bioma;
- iluminação;
- clima;
- materiais;
- elementos decorativos.

Nunca muda:

- posição do grid;
- posição dos comandantes;
- perspectiva;
- proporções gerais.

---

# 5. Área Jogável

O combate acontece exclusivamente dentro de dois grids de **3 × 3 posições**.

Cada exército possui um grid próprio.

As unidades nunca ocupam posições fora dessa área.

---

## Grid Canônico

A numeração oficial das posições é:

```text
EXÉRCITO INIMIGO

7   8   9
6   5   4
1   2   3

────────────────────────────

1   2   3
6   5   4
7   8   9

EXÉRCITO DO JOGADOR
```

Esta numeração constitui referência canônica para:

- combate;
- documentação;
- animações;
- IA;
- efeitos;
- programação;
- ferramentas internas.

Nenhuma documentação poderá utilizar outra orientação.

---

## Leitura Espacial

O jogador observa ambos os grids simultaneamente.

As duas formações devem ser percebidas como um único campo de batalha.

A separação visual existe apenas para facilitar a leitura.

Ela não representa distância física significativa.

---

# 6. Comandantes

Os comandantes não pertencem ao grid.

Eles nunca ocupam uma posição de batalha.

Sua função é representar o líder estratégico do exército.

---

## Localização

O comandante inimigo permanece no:

**canto superior esquerdo**.

O comandante do jogador permanece no:

**canto inferior direito**.

Essas posições são permanentes.

Nenhum modo de jogo altera essa organização.

---

## Representação

Os comandantes não são retratos.

Eles são representados como personagens completos, utilizando exatamente a mesma linguagem artística dos pelotões.

A visualização permanece isométrica.

Isso preserva a unidade visual entre todas as entidades presentes no combate.

---

## Animal de Guerra

Cada comandante aparece acompanhado do grande herbívoro característico de sua facção.

Esse animal representa:

- autoridade;
- tradição;
- identidade da facção.

Ele não ocupa posições do grid.

Também não participa diretamente do combate.

Sua presença é simbólica e visual.

---

## Interface do Comandante

O comandante não possui:

- Ataque;
- Vida;
- Escudo;
- atributos de combate.

Junto ao comandante aparece apenas:

- Afinidade atual do exército.

Toda informação referente ao estado estratégico do exército permanece associada ao comandante.

Informações das unidades permanecem associadas às cartas.

Essa separação nunca deve ser quebrada.

---

# 7. Hierarquia Visual

A ordem de importância visual durante uma batalha é:

1. Cartas.
2. Comandantes.
3. Interface.
4. Campo.
5. Horizonte.

Nenhum elemento inferior pode competir visualmente com um superior.

---

# 8. Proporções

Como referência geral:

| Elemento | Área aproximada |
|-----------|----------------:|
| Cartas | 60% |
| Campo | 20% |
| Interface | 15% |
| Horizonte | 5% |

Esses valores servem como referência de equilíbrio.

Não representam medidas absolutas.

---

# 9. Regras Fundamentais

1. O grid constitui o centro visual da batalha.
2. Nenhuma unidade pode existir fora do grid.
3. Comandantes nunca ocupam posições do campo.
4. O comandante representa o exército; as cartas representam as unidades.
5. A Afinidade pertence ao exército e é exibida junto ao comandante.
6. A organização espacial permanece idêntica em todos os campos do jogo.

# 10. Biomas Oficiais

Os biomas representam as grandes regiões do mundo.

Na Campanha PvE, o bioma utilizado deve corresponder ao território da facção defendida.

No PvP, qualquer bioma oficial pode ser selecionado, independentemente das facções presentes na batalha.

Todos compartilham exatamente a mesma estrutura espacial.

## Filosofia

Os campos de batalha representam regiões reais do mundo.

Sua identidade territorial depende do contexto da batalha.

### Campanha PvE

Durante a campanha, cada batalha acontece em uma região pertencente à facção que está sendo enfrentada.

O cenário reflete o território que essa civilização controla.

Exemplos:

- enfrentar o Império leva o jogador aos territórios imperiais;
- enfrentar a Natureza leva o jogador às regiões naturais;
- enfrentar os Mortos-Vivos leva o jogador aos seus antigos domínios.

O ambiente reforça a identidade narrativa da campanha e da progressão pelo mapa.

### PvP

No PvP, o campo de batalha não pertence a nenhuma das facções participantes.

O cenário é escolhido independentemente dos exércitos e representa uma região qualquer do mundo.

Isso aumenta a variedade visual das partidas sem alterar a identidade das facções.

### Regra Geral

As facções pertencem às unidades.

Os territórios pertencem ao mundo.

A única exceção é a Campanha PvE, na qual o território representa a região defendida pela facção enfrentada.

# 11. Perspectiva, Câmera e Escala

## Princípio

O Battle Simulator utiliza uma perspectiva isométrica fixa.

Essa perspectiva constitui parte permanente da identidade visual do jogo.

Ela não muda entre modos de jogo, campanhas ou mapas.

A câmera existe para favorecer a leitura estratégica.

Nunca para criar espetáculo cinematográfico.

---

## Perspectiva

Todo campo utiliza a mesma projeção isométrica.

As cartas, comandantes, estruturas e elementos do cenário compartilham exatamente o mesmo ponto de vista.

Nenhum elemento pode utilizar perspectiva diferente.

---

## Câmera

A câmera permanece fixa durante toda a batalha.

Não existem rotações.

Não existem mudanças de ângulo.

Podem ocorrer apenas movimentos discretos para reforçar eventos importantes.

Exemplos:

- início da batalha;
- vitória;
- derrota;
- habilidades de grande impacto.

Esses movimentos nunca comprometem a leitura do campo.

---

## Zoom

O jogador poderá aproximar ou afastar a câmera apenas dentro de limites definidos.

Em qualquer nível de zoom deve permanecer possível identificar:

- posições do grid;
- cartas;
- comandantes;
- principais efeitos.

Nenhuma informação crítica pode desaparecer.

---

## Escala

Todos os elementos seguem uma escala única.

A ordem visual é:

Cartas

↓

Comandantes

↓

Terreno

↓

Horizonte

Os comandantes possuem escala semelhante à de um pelotão.

Seu objetivo é representar a presença do líder sem competir visualmente com as cartas.

---

# 12. Interface Integrada

## Princípio

O campo de batalha e a interface formam um único sistema.

A interface não cobre o campo.

Ela o complementa.

Toda informação aparece próxima do elemento ao qual pertence.

---

## Cartas

As cartas exibem exclusivamente informações permanentes da unidade.

Exemplos:

- arte;
- atributos;
- habilidades;
- classe;
- tipo;
- raridade;
- tier.

Nenhuma informação dinâmica do combate pertence à carta.

---

## Comandantes

Os comandantes representam exclusivamente o estado estratégico do exército.

Junto a eles aparecem:

- Afinidade atual.

Nenhuma outra informação permanente de combate é exibida nessa região.

---

## Informações Dinâmicas

Informações temporárias pertencem exclusivamente ao campo de batalha.

Exemplos:

- alvo atual;
- seleção;
- buffs temporários;
- debuffs;
- efeitos ativos;
- alcance de habilidades;
- animações de combate.

Esses elementos nunca alteram a estrutura permanente da carta.

---

# 13. Feedback Visual

## Princípio

Todo feedback existe para comunicar uma informação.

Nunca apenas para produzir impacto visual.

---

## Seleção

Ao selecionar uma carta o jogador deve perceber imediatamente:

- qual unidade foi escolhida;
- sua posição;
- suas possibilidades de ação.

---

## Alvo

Toda unidade alvo de uma habilidade deve possuir identificação clara.

Nunca ambígua.

---

## Ataques

Os ataques devem possuir leitura rápida.

A animação reforça a ação.

Nunca a substitui.

---

## Dano

O dano deve ser percebido imediatamente.

O jogador nunca deve procurar qual unidade foi atingida.

---

## Derrota

Quando uma unidade é destruída:

- sua remoção deve ser clara;
- a reorganização do pelotão deve permanecer legível;
- nenhuma animação pode ocultar a movimentação subsequente.

---

## Invocações

Unidades invocadas surgem diretamente na posição correspondente.

Nunca deslocam visualmente outras cartas antes da reorganização oficial do sistema de combate.

---

# 14. Efeitos Visuais

## Filosofia

Os efeitos reforçam mecânicas.

Nunca substituem informação.

O jogador deve compreender o resultado mesmo que ignore completamente os efeitos especiais.

---

## Intensidade

Os efeitos utilizam intensidade proporcional ao evento.

Pequenas ações:

efeitos discretos.

Grandes habilidades:

efeitos mais elaborados.

Mesmo assim, as cartas permanecem protagonistas.

---

## Sobreposição

Nunca podem existir tantos efeitos simultâneos que impeçam identificar:

- unidades;
- posições;
- comandante;
- direção do combate.

---

# 15. Performance Visual

Todo campo deve permanecer visualmente estável.

Mesmo durante batalhas com muitos efeitos simultâneos.

A legibilidade possui prioridade absoluta sobre quantidade de partículas ou animações.

---

# 16. Consistência

Independentemente do modo de jogo, todo campo compartilha:

- mesma perspectiva;
- mesma escala;
- mesma organização espacial;
- mesma posição dos comandantes;
- mesmo grid;
- mesma linguagem visual.

O jogador muda de cenário.

Nunca muda a forma de compreender o combate.

---

# 17. Checklist de Aprovação

Antes de aprovar um novo campo verificar:

- [ ] O grid segue o padrão canônico 3×3.
- [ ] A numeração oficial das posições foi respeitada.
- [ ] Os comandantes permanecem fora do grid.
- [ ] O comandante inimigo ocupa o canto superior esquerdo.
- [ ] O comandante do jogador ocupa o canto inferior direito.
- [ ] Ambos utilizam representação isométrica completa.
- [ ] O grande herbívoro da facção acompanha o comandante.
- [ ] Apenas a Afinidade é exibida junto ao comandante.
- [ ] O cenário não compete visualmente com as cartas.
- [ ] O horizonte apenas amplia a sensação de escala.
- [ ] A perspectiva isométrica permanece consistente.
- [ ] Todos os elementos seguem a mesma escala visual.
- [ ] O campo continua legível durante efeitos intensos.
- [ ] O bioma corresponde corretamente ao contexto da batalha (Campanha PvE ou PvP).
- [ ] A estrutura geral permanece consistente com todos os demais campos do jogo.

---

# 18. Template para Geração de Campo por IA

Este template só pode ser utilizado quando todos os parâmetros já estiverem definidos em documentação canônica.

```text
Campo de batalha oficial do Battle Simulator.

Perspectiva isométrica fixa.

Grid tático 3×3 para cada exército.

Cartas constituem o elemento visual principal.

Comandante inimigo localizado no canto superior esquerdo, fora do grid.

Comandante do jogador localizado no canto inferior direito, fora do grid.

Cada comandante representado como personagem completo acompanhado do grande herbívoro característico de sua facção.

Exibir apenas o indicador de Afinidade junto aos comandantes.

O terreno corresponde ao bioma oficial definido para a batalha.

O cenário reforça profundidade, materialidade e atmosfera sem competir com as cartas.

Utilizar iluminação natural coerente com o bioma.

Evitar elementos excessivos, obstáculos visuais, construções dominantes, efeitos exagerados ou qualquer elemento que reduza a legibilidade do combate.

Toda a composição deve priorizar clareza estratégica, consistência visual e leitura imediata.
```

---

# Regra Final

O campo de batalha é o palco do combate.

Ele existe para valorizar as unidades, facilitar decisões estratégicas e reforçar a identidade do mundo.

Quando um jogador observar qualquer batalha do Battle Simulator, deverá reconhecer imediatamente a organização espacial, a perspectiva, a posição dos comandantes e a clareza do sistema, independentemente do bioma, da campanha ou das facções presentes.