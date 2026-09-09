BATTLE SIMULATOR — BATTLE ART — ASSET CONTRACT v1
Documento: Asset Contract
Versão: v1.0
Função: contrato entre Direção Gráfica, produção dos assets e implementação no Godot
Escopo: Battle Arts de unidades do Battlefield
Status: padrão de produção — parâmetros ainda não calibrados permanecem explicitamente marcados como TBD
1. OBJETIVO
[Certo] Este contrato define as condições mínimas que qualquer Battle Art deverá cumprir para ser considerado compatível com o Battle Simulator.
[Certo] O contrato existe para impedir que decisões sejam tomadas novamente a cada personagem.
[Certo] Uma vez validado e congelado, o mesmo contrato deverá ser utilizado para toda a biblioteca.
CARD / CHARACTER IDENTITY
          ↓
    CHARACTER MASTER
          ↓
     BATTLE ART
          ↓
  ASSET CONTRACT
          ↓
       GODOT
          ↓
    BATTLEFIELD
2. PRINCÍPIO FUNDAMENTAL
[Certo] Um Battle Art é um asset de unidade de Battlefield, e não uma ilustração de carta.
[Certo] O asset deverá funcionar independentemente da carta original.
[Certo] A carta fornece identidade visual.
[Certo] O Battle Art fornece a representação espacial da unidade.
3. ESCOPO DO CONTRATO
[Certo] O contrato se aplica a:
- unidades humanoides;
- criaturas;
- estruturas/unidades especiais que utilizem o mesmo sistema visual;
- quatro orientações;
- estados de ação;
- frames de animação;
- assets estáticos;
- assets animados.
[Certo] O contrato também deverá ser aplicável às três principais facções atualmente representadas nas referências:
- Império;
- Mortos-Vivos;
- Natureza.
4. IDENTIFICAÇÃO DO ASSET
[Certo] Todo asset deverá possuir identificação inequívoca.
Estrutura conceitual:
ASSET_ID
CHARACTER_ID
FACTION_ID
STATE
ORIENTATION
FRAME
VERSION
Exemplo
ASSET_ID: IMP_ARCHER_ATTACK_RIGHT_01
CHARACTER_ID: IMP_ARCHER
FACTION_ID: IMP
STATE: ATTACK
ORIENTATION: RIGHT
FRAME: 01
VERSION: 01
[Certo] O objetivo é que o Claude consiga identificar o conteúdo de um arquivo pelo nome e pela estrutura, sem precisar inferir sua função visualmente.
5. NOMENCLATURA OFICIAL
[Certo] O padrão provisório será:
[FACTION]_[CHARACTER]_[STATE]_[ORIENTATION]_[FRAME].png
Exemplos
IMP_ARCHER_IDLE_FRONT_01.png
IMP_ARCHER_IDLE_BACK_01.png
IMP_ARCHER_IDLE_LEFT_01.png
IMP_ARCHER_IDLE_RIGHT_01.png
Para uma animação:
IMP_ARCHER_ATTACK_RIGHT_01.png
IMP_ARCHER_ATTACK_RIGHT_02.png
IMP_ARCHER_ATTACK_RIGHT_03.png
IMP_ARCHER_ATTACK_RIGHT_04.png
[Provável] O formato definitivo dos identificadores será congelado depois do teste com o primeiro personagem.
6. FORMATO DO ARQUIVO
[Certo] O formato de produção será:
PNG
[Certo] O arquivo deverá suportar transparência real.
[Certo] Não deverá existir fundo sólido utilizado apenas para facilitar a geração.
Obrigatório
Alpha channel: YES
Background: TRANSPARENT
[Certo] O arquivo final não deverá conter:
- preto;
- branco;
- cinza;
- gradiente;
- cenário;
- chão;
- moldura.
7. CONTEÚDO VISUAL PERMITIDO
[Certo] O arquivo poderá conter:
- corpo da unidade;
- armadura;
- roupa;
- armas;
- acessórios;
- cabelos;
- capas;
- elementos orgânicos;
- cristais;
- efeitos pertencentes à unidade;
- efeitos específicos de uma ação.
[Certo] Esses elementos deverão pertencer visualmente à unidade.
8. CONTEÚDO PROIBIDO
[Certo] Nunca deverá existir dentro do Battle Art:
- moldura;
- texto;
- nome;
- número;
- HUD;
- HP bar;
- ícone;
- grid;
- quadrado de seleção;
- círculo de seleção;
- cenário;
- piso;
- pedras ambientais;
- grama ambiental;
- árvores;
- construções;
- elementos da carta;
- elementos de interface;
- indicadores de direção.
[Certo] O Battlefield fornece o ambiente.
9. PERSPECTIVA
[Certo] O Battle Art deverá utilizar a linguagem de câmera do Battlefield.
[Certo] A referência é:
3/4 / isométrica / perspectiva espacial compatível com o campo.
[Certo] O asset não deverá ser produzido como:
- retrato frontal de RPG;
- sprite lateral puro;
- vista superior;
- personagem em perspectiva incompatível com o mapa.
[Certo] FRONT, BACK, LEFT e RIGHT deverão pertencer à mesma linguagem de câmera.
10. QUATRO ORIENTAÇÕES
[Certo] Todo personagem-base deverá possuir:
FRONT
BACK
LEFT
RIGHT
[Certo] Essas orientações representam o mesmo personagem.
Não permitido
FRONT → personagem A
BACK  → personagem B
LEFT  → personagem C
RIGHT → personagem D
Obrigatório
             MESMO PERSONAGEM
                    │
       ┌────────────┼────────────┐
       ↓            ↓            ↓
    FRONT         BACK       LEFT / RIGHT
[Certo] Armadura, armas, proporções, materiais e identidade devem permanecer consistentes.
11. ANCORAGEM
[Certo] Todo asset deverá possuir um Ground Anchor.
[Certo] O Ground Anchor representa o ponto em que a unidade entra em contato com o plano do Battlefield.
Conceitualmente:
             unidade
                │
                │
              pés
                ●
────────────────┼────────────────
             GROUND
[Certo] O anchor será especialmente importante para:
- movimentação;
- troca de animação;
- morte;
- ataque;
- defesa;
- escala;
- posicionamento na célula.
[Certo] Uma troca de estado não deverá deslocar arbitrariamente a unidade no Battlefield.
12. CANVAS
[Provável] O tamanho definitivo do canvas não deve ser congelado ainda.
[Certo] A razão é que o tamanho adequado depende da calibração entre:
- asset;
- célula;
- câmera;
- zoom;
- escala;
- profundidade.
Portanto:
CANVAS_SIZE = TBD
[Certo] O princípio já está congelado:
o canvas deve acomodar a unidade sem deformá-la e permitir padronização de posicionamento.

13. BOUNDING BOX
[Certo] O bounding box deverá envolver a área visual necessária para a unidade.
[Certo] Não devemos forçar todas as unidades a uma ocupação quadrada.
[Certo] O sistema deverá preservar:
- proporção;
- silhueta;
- escala relativa;
- anchor.
[Certo] Uma unidade alta e estreita pode ter bounding box alto e estreito.
[Certo] Uma criatura larga pode possuir bounding box mais largo.
14. PADDING
[Provável] O padding exato ainda precisa ser calibrado.
PADDING = TBD
[Certo] Porém, o princípio é:
- suficiente para evitar cortes;
- suficientemente pequeno para não criar espaço artificial excessivo;
- consistente entre frames da mesma animação.
[Certo] O padding não pode fazer a unidade parecer menor simplesmente porque o canvas contém uma área transparente exagerada.
15. ESCALA
[Certo] O asset deverá ser produzido em proporção original.
[Certo] Não será permitido:
- esticar;
- comprimir;
- deformar;
- alterar proporções para preencher a célula.
[Provável] A escala final do personagem no Battlefield será responsabilidade do sistema Godot.
[Certo] Portanto:
ASSET
  ↓
PROPORÇÃO FIXA
  ↓
GODOT
  ↓
ESCALA ESPACIAL
16. PROFUNDIDADE
[Certo] O asset não deverá conter uma escala diferente para cada linha do Battlefield.
[Certo] O mesmo asset deverá funcionar em diferentes profundidades.
BACK
 ↓
MIDDLE
 ↓
CENTER
 ↓
MIDDLE
 ↓
BACK
[Provável] A implementação poderá ajustar a escala de acordo com a posição.
[Certo] Isso deverá acontecer fora do PNG.
17. OCUPAÇÃO DA CÉLULA
[Certo] Cada unidade deverá ser visualmente compatível com uma célula do Battlefield.
[Certo] O asset não deve ocupar sistematicamente a célula vizinha.
[Certo] Elementos naturais da silhueta podem ultrapassar ligeiramente a área central da unidade quando isso for coerente com o design, mas não devem criar confusão sobre qual célula a unidade ocupa.
[Provável] O limite quantitativo dessa ocupação será definido durante o teste do personagem-piloto.
18. IDENTIDADE DO PERSONAGEM
[Certo] Cada personagem deverá possuir um Character Master.
O Master define:
ANATOMIA
ARMADURA
ARMA
MATERIAIS
CORES
ACESSÓRIOS
SILHUETA
CARACTERÍSTICAS EXCLUSIVAS
[Certo] O Character Master será a referência para todos os assets derivados.
19. CHARACTER LOCK
[Certo] Após aprovação do Master:
CHARACTER MASTER
       ↓
     LOCK
       ↓
4 ORIENTAÇÕES
       ↓
AÇÕES
       ↓
FRAMES
[Certo] Nenhuma ação poderá alterar arbitrariamente a identidade do personagem.
[Certo] Se houver necessidade de mudar a armadura, arma ou proporção, a mudança deverá ocorrer primeiro no Master.
20. ESTADOS
[Certo] O sistema deverá aceitar estados extensíveis.
Estados iniciais:
IDLE
MOVE
ATTACK
DEFENSE
HIT
DEATH
HEAL
SPECIAL
[Certo] Novos estados poderão ser adicionados sem alterar a arquitetura básica.
21. FRAME
[Certo] Quando uma ação utilizar múltiplos frames, cada frame será um arquivo independente.
Exemplo:
IMP_ARCHER_ATTACK_RIGHT_01.png
IMP_ARCHER_ATTACK_RIGHT_02.png
IMP_ARCHER_ATTACK_RIGHT_03.png
IMP_ARCHER_ATTACK_RIGHT_04.png
[Certo] Todos os frames deverão:
- possuir o mesmo canvas de referência;
- manter o mesmo anchor;
- preservar a proporção;
- preservar a identidade;
- evitar deslocamento artificial.
22. POSES DE ESTADO
[Certo] Estados simples poderão inicialmente utilizar um único frame.
Exemplo:
IMP_ARCHER_DEFENSE_RIGHT_01.png
[Certo] Isso permite criar estados visuais sem obrigatoriamente gerar uma animação complexa.
[Provável] A quantidade de frames de cada ação será definida individualmente conforme a necessidade de gameplay.
23. MOVIMENTO
[Certo] Movimento deverá preservar:
- identidade;
- direção;
- anchor;
- escala;
- proporção.
[Certo] O movimento não deverá ser representado por uma sequência de personagens visualmente diferentes.
[Certo] A sequência deve parecer uma única unidade animada.
24. ATAQUE
[Certo] O ataque deverá preservar a arma e a identidade do personagem.
[Certo] A ação deverá comunicar:
- preparação;
- execução;
- conclusão,
quando esses frames forem necessários.
[Provável] Nem todos os ataques precisarão possuir a mesma quantidade de frames.
25. DEFESA
[Certo] A defesa deverá alterar principalmente a postura.
[Certo] Armadura e equipamento permanecem os mesmos.
[Certo] O asset não deverá ganhar um escudo inexistente simplesmente para comunicar "defesa", salvo se a própria habilidade envolver esse elemento.
26. HIT / DANO
[Certo] A reação ao dano deverá preservar a identidade.
[Certo] O personagem não deverá perder equipamento ou alterar proporção apenas por estar em estado HIT.
[Provável] Efeitos visuais de impacto poderão ser adicionados posteriormente conforme a linguagem de combate.
27. MORTE
[Certo] A morte deverá ser uma evolução visual do mesmo personagem.
[Certo] Não deverá parecer outro modelo.
[Certo] O anchor deverá ser tratado cuidadosamente porque a unidade pode deixar de estar em pé.
[Provável] A convenção definitiva para o anchor durante DEATH deverá ser validada no piloto.
28. CURA
[Certo] HEAL deverá alterar o estado visual sem destruir a identidade.
[Provável] Efeitos de Essência Vital, energia, luz ou partículas poderão ser utilizados quando compatíveis com a facção e com a habilidade.
[Certo] Esses efeitos não podem virar cenário incorporado.
29. EFEITOS DE FACÇÃO
[Certo] Os efeitos deverão respeitar a identidade visual da facção.
Império
[Provável]
- energia mais física;
- metal;
- luz quente;
- efeitos disciplinados.
Mortos-Vivos
[Certo]
- roxo;
- ametista;
- Essência arcana;
- cristais.
Natureza
[Certo]
- verde;
- dourado-esverdeado;
- folhas;
- energia vital;
- partículas orgânicas.
[Certo] Essas referências vêm diretamente das imagens fornecidas para as facções.
30. SOMBRA
[Certo] Sombra ambiental não deverá ser incorporada ao asset.
[Certo] A unidade deverá funcionar sobre o chão do Battlefield sem depender de uma sombra pintada no PNG.
[Provável] Uma pequena sombra de contato poderá ser avaliada durante o piloto, mas não será parte do contrato v1 como requisito obrigatório.
31. ILUMINAÇÃO
[Certo] A iluminação deverá ser consistente com o universo visual.
[Certo] Entretanto, o asset não deverá carregar iluminação de um cenário específico.
[Certo] O personagem deve poder ser colocado no Battlefield sem parecer que veio de uma cena com iluminação completamente diferente.
[Provável] A direção exata da iluminação será congelada depois do teste visual com o Battlefield.
32. ARQUIVOS INDIVIDUAIS
[Certo] Cada asset deverá ser entregue individualmente.
Não utilizar como arquivo final:
character_all_animations.png
[Certo] Em vez disso:
IDLE
 ├── FRONT
 ├── BACK
 ├── LEFT
 └── RIGHT

ATTACK
 ├── FRONT
 ├── BACK
 ├── LEFT
 └── RIGHT
[Certo] Isso facilita a utilização pelo Claude e a manutenção posterior.
33. ESTRUTURA DE DIRETÓRIO
[Provável] Estrutura inicial:
battle_assets/
│
├── IMP/
│   └── ARCHER/
│       ├── MASTER/
│       ├── IDLE/
│       ├── MOVE/
│       ├── ATTACK/
│       ├── DEFENSE/
│       ├── HIT/
│       ├── DEATH/
│       ├── HEAL/
│       └── SPECIAL/
│
├── UNDEAD/
│
└── NATURE/
[Certo] A estrutura deverá permitir ao Claude localizar assets de maneira previsível.
[Provável] Os nomes exatos dos diretórios poderão ser ajustados antes da implementação final.
34. METADADOS
[Certo] Cada personagem deverá possuir dados suficientes para que o sistema saiba quais assets existem.
Exemplo conceitual:
character_id: IMP_ARCHER
faction: IMP
orientations:
  - FRONT
  - BACK
  - LEFT
  - RIGHT

states:
  - IDLE
  - MOVE
  - ATTACK
  - DEFENSE
  - HIT
  - DEATH
[Certo] O objetivo é evitar que o Claude tenha que adivinhar quais arquivos existem.
35. RELAÇÃO COM O CLAUDE
[Certo] O Claude deverá receber três informações distintas:
1. Asset
A imagem efetiva.
2. Contract
As regras técnicas do asset.
3. Metadata
Como encontrar e interpretar o asset.
ASSET
+
ASSET CONTRACT
+
METADATA
      ↓
    CLAUDE
      ↓
    GODOT
[Certo] Isso reduz drasticamente a necessidade de interpretação manual.
36. O QUE O CLAUDE NÃO DEVE FAZER
[Certo] A implementação não deverá:
- redesenhar o asset;
- alterar a proporção;
- editar a silhueta;
- corrigir visualmente a unidade;
- criar cenário atrás dela;
- adicionar elementos da carta;
- substituir um asset aprovado por uma versão improvisada.
[Certo] Se existir incompatibilidade técnica, o problema deverá ser reportado.
37. O QUE O DIRETOR GRÁFICO NÃO DEVE FAZER
[Certo] O Diretor Gráfico não deverá decidir:
- Nodes;
- scripts;
- lógica de combate;
- hitboxes;
- movimentação;
- sistema de animação do Godot;
- implementação de z-order;
- código de escala.
[Certo] O Diretor Gráfico fornece o asset e o contrato visual.
38. VALIDAÇÃO OBRIGATÓRIA
[Certo] Um asset não será considerado aprovado apenas porque o PNG está bonito.
Deverá passar:
1. PNG TEST
       ↓
2. FOUR-VIEW TEST
       ↓
3. CELL TEST
       ↓
4. DEPTH TEST
       ↓
5. CAMERA TEST
       ↓
6. ACTION TEST
       ↓
7. GODOT TEST
[Certo] Falha em qualquer etapa significa REVISION.
39. STATUS DO ASSET
[Certo] Cada asset deverá possuir um estado de produção:
DRAFT
MASTER_APPROVED
ORIENTATION_APPROVED
ACTION_APPROVED
GODOT_TEST
REVISION
PRODUCTION_READY
LOCKED
[Certo] Apenas:
PRODUCTION_READY
ou
LOCKED
deverão ser considerados assets oficiais.
40. VERSÃO
[Certo] Durante produção:
_v01
_v02
_v03
[Certo] Após aprovação:
IMP_ARCHER_ATTACK_RIGHT_01.png
[Certo] O Godot deverá apontar para o arquivo oficial, não para arquivos experimentais.
41. CHECKLIST VISUAL
Antes da aprovação:
[ ] Fundo transparente
[ ] Sem moldura
[ ] Sem texto
[ ] Sem HUD
[ ] Sem cenário
[ ] Sem chão incorporado
[ ] Silhueta clara
[ ] Identidade preservada
[ ] Equipamento correto
[ ] Materiais corretos
[ ] Perspectiva correta
[ ] Orientação inequívoca
[ ] Anchor correto
[ ] Proporção preservada
42. CHECKLIST DE CONSISTÊNCIA
[ ] FRONT = mesmo personagem
[ ] BACK = mesmo personagem
[ ] LEFT = mesmo personagem
[ ] RIGHT = mesmo personagem

[ ] mesma armadura
[ ] mesma arma
[ ] mesmas proporções
[ ] mesmos materiais
[ ] mesma paleta
[ ] mesma identidade

[ ] IDLE consistente
[ ] ATTACK consistente
[ ] DEFENSE consistente
[ ] HIT consistente
[ ] DEATH consistente
43. CHECKLIST DE BATTLEFIELD
[ ] cabe na célula
[ ] não invade excessivamente a célula vizinha
[ ] não flutua
[ ] anchor correto
[ ] escala adequada
[ ] funciona em primeiro plano
[ ] funciona em fundo
[ ] funciona em quatro orientações
[ ] funciona com profundidade
[ ] funciona na câmera real
44. PARÂMETROS AINDA NÃO CONGELADOS
[Certo] Estes valores não devem ser inventados agora:
Parâmetro	Status
Canvas final	TBD
Padding	TBD
Anchor em pixels	TBD
Escala-base	TBD
Tamanho visual da unidade/célula	TBD
Curva de escala por profundidade	TBD
Parâmetros exatos da câmera	TBD
Convenção final de sorting	TBD
Número de frames por ação	TBD
FPS das animações	TBD


[Certo] Isso não é uma deficiência do contrato.
[Certo] É uma decisão deliberada para não transformar hipóteses em regras antes do teste.
45. PARÂMETROS JÁ CONGELADOS
[Certo] Estes princípios já podem ser tratados como obrigatórios:
Regra	Estado
Battle Art separado da Card Art	LOCKED
Fundo transparente	LOCKED
Sem cenário incorporado	LOCKED
Sem HUD/UI	LOCKED
Quatro orientações	LOCKED
Mesmo personagem nas quatro vistas	LOCKED
Perspectiva compatível com Battlefield	LOCKED
Proporção preservada	LOCKED
Sem deformação	LOCKED
Anchor consistente	LOCKED — valor TBD
Compatibilidade com célula	LOCKED
Profundidade resolvida pela implementação	LOCKED
Arquivos individuais	LOCKED
Character Master	LOCKED
Character Lock	LOCKED
Validação no Battlefield real	LOCKED
Validação no Godot antes da escala	LOCKED


46. REGRA DE MUDANÇA DO CONTRATO
[Certo] Uma regra do contrato não deverá ser alterada silenciosamente.
Se durante o piloto surgir:
"o canvas precisa ser diferente"

ou:
"as quatro orientações precisam de outra convenção"

ou:
"o anchor precisa funcionar de outra forma"

[Certo] a alteração deverá ser registrada como:
ASSET CONTRACT v1.1
ou, caso seja estrutural:
ASSET CONTRACT v2.0
[Certo] Isso evita que personagens antigos sejam produzidos segundo regras diferentes sem percebermos.
47. REGRA DE COMPATIBILIDADE RETROATIVA
[Certo] Uma alteração do contrato deverá responder:
Os assets já produzidos continuam válidos?

Se sim:
MINOR VERSION
Se não:
MAJOR VERSION
[Certo] Isso será particularmente importante quando chegarmos aos 40 personagens.
48. PRIMEIRO TESTE DO CONTRATO
[Certo] O Asset Contract v1 não será considerado definitivamente congelado apenas por estar escrito.
[Certo] Ele será validado através do:
PERSONAGEM PILOTO
O piloto deverá testar:
MASTER
↓
FRONT
BACK
LEFT
RIGHT
↓
IDLE
MOVE
ATTACK
DEFENSE
HIT
DEATH
HEAL
↓
GODOT
↓
BATTLEFIELD
[Certo] O que for descoberto durante esse processo servirá para gerar o Asset Contract v1.1, se necessário.
49. CRITÉRIO FINAL DO CONTRATO
[Certo] Um Battle Art está em conformidade com este contrato somente quando:
o arquivo pode ser entregue ao sistema sem exigir que o Claude descubra, interprete ou corrija decisões gráficas fundamentais.

[Certo] A informação necessária deve estar definida previamente.
IDENTIDADE
ORIENTAÇÃO
AÇÃO
FRAME
ARQUIVO
ANCHOR
METADATA
        ↓
     CLAUDE
        ↓
      GODOT
50. STATUS DO ASSET CONTRACT v1
[Certo] BATTLE ART — ASSET CONTRACT v1 está estabelecido como contrato operacional inicial.
[Certo] Ele já congela a arquitetura de produção, mas não congela artificialmente os parâmetros que só podem ser determinados pelo teste real no Battlefield.
[Certo] Isso é importante porque agora temos uma separação limpa:
PIPELINE v1
    ↓
define COMO produzimos

ASSET CONTRACT v1
    ↓
define O QUE cada arquivo deve cumprir

PERSONAGEM PILOTO
    ↓
descobre os parâmetros TBD

GODOT
    ↓
valida a compatibilidade real

CONTRACT v1.1
    ↓
congela os parâmetros descobertos

PRODUÇÃO EM ESCALA
    ↓
40 PERSONAGENS