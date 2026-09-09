BATTLE SIMULATOR — BATTLE ART PRODUCTION PIPELINE v1
Status: Versão inicial de produção
Escopo: Battle Arts e seus estados visuais
Destino: Battlefield do Battle Simulator
Produção inicial: 40 personagens
Orientações-base: FRONT / BACK / LEFT / RIGHT
Princípio: identidade visual consistente + produção replicável + integração previsível no Godot
1. OBJETIVO
[Certo] O objetivo deste pipeline é criar uma linha de produção capaz de produzir os Battle Arts dos 40 personagens do Battle Simulator sem que cada personagem precise ser tratado como um projeto gráfico independente.
[Certo] O pipeline deverá permitir produzir:
- quatro orientações-base;
- poses de movimento;
- ataque;
- defesa;
- dano/hit;
- morte;
- cura;
- habilidades especiais;
- outras ações futuras.
[Certo] O pipeline deverá preservar simultaneamente:
- identidade individual;
- identidade da facção;
- identidade do universo;
- perspectiva do Battlefield;
- proporções;
- escala relativa;
- ponto de apoio;
- leitura em escala reduzida;
- consistência entre estados.
[Certo] O resultado final deverá ser utilizável pelo Claude durante a implementação no Godot sem depender de redesenho artístico para corrigir problemas que deveriam ter sido resolvidos no pipeline.
2. PRINCÍPIO CENTRAL
[Certo] O Battle Art não é uma ilustração isolada.
[Certo] Ele é uma unidade visual de Battlefield.
[Certo] Portanto, a qualidade de um asset será determinada não apenas pela beleza da imagem, mas por sua capacidade de funcionar:
dentro de uma célula → dentro da formação → dentro da câmera → em diferentes profundidades → em quatro orientações → durante diferentes estados de ação.

[Certo] Uma imagem bonita que falha nesses critérios será considerada asset reprovado.
3. ARQUITETURA DO PIPELINE
[Certo] A produção será organizada em sete etapas principais:
IDENTIDADE
    ↓
MASTER
    ↓
4 ORIENTAÇÕES
    ↓
ESTADOS / AÇÕES
    ↓
EXPORTAÇÃO
    ↓
VALIDAÇÃO GODOT
    ↓
APROVAÇÃO
[Certo] Nenhum estágio deverá ser usado para compensar uma falha estrutural do estágio anterior.
[Certo] Por exemplo:
problema de proporção
        ↓
não corrigir no Godot
        ↓
corrigir no MASTER
[Certo] Da mesma forma:
problema de orientação
        ↓
não criar uma nova interpretação
        ↓
corrigir a orientação mantendo o MASTER
4. FASE 0 — PADRÃO DO BATTLEFIELD
[Certo] Antes da produção em escala, o Battlefield real deverá fornecer os parâmetros espaciais usados como referência.
[Certo] A imagem fornecida do Battlefield estabelece visualmente:
- câmera 3/4;
- campo com profundidade;
- duas formações 3×3;
- linhas com posições espaciais distintas;
- necessidade de orientação;
- necessidade de leitura em profundidade.
[Certo] A imagem desenhada sobre o Battlefield é uma referência espacial, não um elemento gráfico dos assets.
Parâmetros que deverão ser congelados
[Provável] A implementação deverá determinar e documentar:
- tipo de câmera;
- zoom;
- resolução de referência;
- tamanho aparente de uma célula;
- escala inicial de uma unidade;
- relação entre distância e escala;
- posição do ponto de apoio;
- regra de ordenação visual;
- comportamento de sobreposição.
[Certo] Esses parâmetros pertencem à integração Godot, mas precisam ser conhecidos pelo Diretor Gráfico porque determinam como o asset será produzido.
[Certo] O Godot possui mecanismos próprios de ordenação de CanvasItem, incluindo z_index e y_sort_enabled; portanto, a ordem visual não deve ser artificialmente simulada dentro das imagens. Godot Engine documentation
5. FASE 1 — CHARACTER MASTER
[Certo] Cada personagem deverá possuir um Character Master antes da produção das animações.
[Certo] O Character Master será a fonte visual de verdade daquele personagem.
Character Master deverá definir
[Certo]
- identidade;
- anatomia;
- proporções;
- cabeça;
- rosto;
- cabelo;
- armadura;
- roupa;
- arma;
- acessórios;
- materiais;
- cores;
- detalhes característicos;
- silhueta;
- nível de poder;
- características da facção.
[Certo] O Master não será necessariamente um asset final de Battlefield.
[Certo] Ele será principalmente uma referência de consistência.
6. HIERARQUIA VISUAL
[Certo] A produção deverá obedecer à seguinte hierarquia:
UNIVERSO
   ↓
FACÇÃO
   ↓
PERSONAGEM
   ↓
ORIENTAÇÃO
   ↓
AÇÃO
   ↓
FRAME
[Certo] Quanto mais abaixo na hierarquia, menos liberdade artística deverá existir.
Universo
[Certo] Define a linguagem geral do Battle Simulator.
Facção
[Certo] Define materiais, cores, formas e filosofia visual.
Personagem
[Certo] Define identidade individual.
Orientação
[Certo] Define de qual direção a unidade é observada.
Ação
[Certo] Modifica postura e comportamento.
Frame
[Certo] Representa apenas uma etapa temporal da ação.
7. IDENTIDADE DAS FACÇÕES
[Certo] As referências fornecidas estabelecem três linguagens visuais muito claras.
IMPÉRIO
[Certo]
- ferro negro;
- bronze envelhecido;
- couro escuro;
- dourado;
- vermelho secundário;
- construção modular;
- formas funcionais;
- equipamento militar;
- disciplina;
- padronização.
MORTOS-VIVOS
[Certo]
- ferro escuro;
- pedra;
- roxo;
- ametista;
- cristais arcanos;
- estruturas austeras;
- formas ameaçadoras;
- sensação de permanência;
- precisão;
- ordem.
NATUREZA
[Certo]
- madeira;
- casca;
- fibras;
- folhas;
- verdes;
- dourado-esverdeado;
- Essência Vital;
- formas orgânicas;
- crescimento;
- integração com a vida.
[Certo] Essas características deverão permanecer reconhecíveis nos Battle Arts mesmo sem qualquer cenário ou moldura.
8. CARTA → BATTLE ART
[Certo] A carta será utilizada como fonte de identidade.
[Certo] Ela poderá fornecer:
- equipamento;
- arma;
- materiais;
- cores;
- aparência;
- silhueta;
- nível de poder;
- elementos exclusivos.
[Certo] Entretanto, a composição da carta não será reproduzida automaticamente.
[Certo] O processo será:
CARD ART
   ↓
ANÁLISE DE IDENTIDADE
   ↓
CHARACTER MASTER
   ↓
BATTLEFIELD COMPOSITION
   ↓
BATTLE ART
[Certo] Cenário, moldura, texto, HUD e composição narrativa da carta nunca deverão migrar para o Battle Art.
9. FASE 2 — AS QUATRO ORIENTAÇÕES
[Certo] Todo personagem deverá primeiro possuir quatro orientações estruturais:
FRONT
BACK
LEFT
RIGHT
[Certo] Essas quatro imagens representam o mesmo personagem.
[Certo] Não serão quatro interpretações.
[Certo] Não serão quatro poses independentes.
[Certo] Não serão quatro versões estilizadas.
[Certo] A regra é:
mesmo personagem + mesma construção + câmera coerente + orientação diferente.

10. CONSISTÊNCIA ENTRE VISTAS
[Certo] Entre FRONT, BACK, LEFT e RIGHT deverão permanecer constantes:
- altura;
- largura estrutural;
- proporções;
- arma;
- armadura;
- materiais;
- cores;
- acessórios;
- nível de detalhe;
- identidade;
- estilo de iluminação.
[Certo] A diferença deverá ser causada principalmente pela rotação/orientação.
[Certo] Uma arma não poderá mudar de design entre LEFT e RIGHT simplesmente porque o modelo foi regenerado.
[Certo] Uma armadura não poderá ganhar ou perder componentes dependendo da vista.
11. PERSPECTIVA
[Certo] Todas as vistas deverão pertencer à mesma linguagem de câmera do Battlefield.
[Certo] Não será permitido produzir:
FRONT = personagem frontal de RPG
LEFT  = personagem totalmente lateral
BACK  = vista traseira plana
RIGHT = perspectiva diferente
[Certo] A orientação muda, mas a linguagem espacial permanece.
[Certo] A referência principal continua sendo a perspectiva 3/4/isométrica percebida no Battlefield.
12. ANCORAGEM
[Certo] O ponto mais importante da geometria do asset será o ponto de contato com o Battlefield.
[Certo] Os pés, pernas, base corporal ou equivalente deverão estabelecer claramente onde a unidade está apoiada.
[Certo] O asset não deverá parecer flutuar.
[Certo] A referência espacial deverá ser conceitualmente:
       UNIDADE
          │
          │
        pés
─────────●─────────
       ANCHOR
[Certo] O ponto ● deverá permanecer consistente entre os estados.
[Certo] Uma animação de ataque não poderá fazer o personagem saltar vários pixels para cima ou para baixo sem que isso seja uma decisão deliberada da animação.
13. CANVAS E BOUNDING BOX
[Certo] Não será estabelecido um quadrado universal para todas as unidades.
[Certo] Um gigante, um soldado e uma criatura pequena não possuem a mesma proporção visual.
[Certo] O princípio será:
área máxima de ocupação + proporção preservada.

[Certo] Não será permitido:
- esticar;
- comprimir;
- deformar;
- preencher artificialmente um quadrado;
- alterar a proporção corporal para caber no canvas.
[Provável] O tamanho exato do canvas será definido durante a calibração do personagem-piloto.
14. TRANSPARÊNCIA
[Certo] Todo Battle Art final deverá possuir fundo realmente transparente.
[Certo] Não deverá existir:
- céu;
- chão;
- parede;
- ambiente;
- gradiente de cenário;
- halo retangular;
- fundo preto;
- fundo branco.
[Certo] Efeitos pertencentes à própria unidade podem existir quando fizerem parte da identidade ou da ação, mas não poderão criar a aparência de cenário incorporado.
15. SOMBRAS
[Certo] O asset não deverá carregar uma sombra de cenário.
[Provável] Uma sombra de contato extremamente controlada poderá ser considerada posteriormente se a direção de arte e a implementação demonstrarem necessidade, mas isso será tratado como uma decisão de pipeline, não como padrão automático.
[Certo] A implementação deverá ser capaz de controlar a relação visual da unidade com o chão sem depender de uma sombra desenhada dentro do PNG.
16. ESTADOS DE ANIMAÇÃO
[Certo] Depois das quatro orientações-base, entram os estados.
A biblioteca será estruturada conceitualmente como:
IDLE
MOVE
ATTACK
DEFENSE
HIT
DEATH
HEAL
SPECIAL
[Certo] Essa lista é extensível.
[Certo] Novas ações não deverão exigir uma mudança estrutural no pipeline.
17. POSE ≠ ANIMAÇÃO COMPLETA
[Certo] Nem toda ação precisa inicialmente de vários frames.
[Certo] Devemos distinguir:
Estado/pose
Exemplo:
DEFENSE
HIT
HEAL
READY
[Certo] Pode ser representado inicialmente por um único asset.
Animação
Exemplo:
MOVE
ATTACK
DEATH
[Certo] Pode exigir múltiplos frames.
[Provável] Essa distinção será fundamental para evitar uma explosão desnecessária do número de arquivos.
18. ESTRATÉGIA DE ESCALABILIDADE
[Certo] O número de arquivos pode crescer rapidamente.
Se tivermos:
40 personagens
× 4 orientações
× 8 estados
[Certo] já teremos 1.280 combinações de assets antes de considerar múltiplos frames por animação.
[Certo] Portanto, o pipeline precisa minimizar retrabalho.
[Certo] O objetivo não é produzir menos conteúdo sacrificando qualidade.
[Certo] O objetivo é produzir cada elemento uma vez e reutilizar sua especificação como referência para os elementos seguintes.
19. ASSET PACKAGE
[Certo] Cada personagem deverá possuir um pacote próprio.
Estrutura conceitual:
ART-001_NOME_PERSONAGEM/

├── MASTER/
│
├── FRONT/
├── BACK/
├── LEFT/
├── RIGHT/
│
├── MOVE/
├── ATTACK/
├── DEFENSE/
├── HIT/
├── DEATH/
├── HEAL/
└── SPECIAL/
[Certo] Entretanto, a organização final de pastas poderá ser refinada após o piloto.
[Certo] A regra que já está definida é:
cada asset final deverá existir como arquivo individual.

[Certo] Não devemos depender de uma única imagem contendo todas as poses para a implementação final.
20. NOMENCLATURA
[Certo] A nomenclatura deverá ser mecânica e previsível.
Modelo:
[FACÇÃO]_[PERSONAGEM]_[AÇÃO]_[ORIENTAÇÃO]_[FRAME]
Exemplo conceitual:
IMP_ARCHER_IDLE_FRONT_01.png
IMP_ARCHER_IDLE_BACK_01.png
IMP_ARCHER_ATTACK_RIGHT_01.png
IMP_ARCHER_ATTACK_RIGHT_02.png
[Certo] O nome deverá permitir ao Claude identificar o asset sem precisar interpretar visualmente o arquivo.
[Provável] O padrão definitivo de IDs será congelado no Asset Contract depois da validação do piloto.
21. ASSET CONTRACT PARA GODOT
[Certo] Cada asset deverá obedecer a um contrato técnico.
O contrato deverá informar:
asset_id
character_id
faction
state
orientation
frame
canvas
anchor
base_scale
transparent_background
[Certo] O contrato também deverá indicar quais estados estão disponíveis.
Exemplo:
character: IMP_ARCHER
directions:
  FRONT
  BACK
  LEFT
  RIGHT

states:
  IDLE
  MOVE
  ATTACK
  HIT
  DEATH
[Certo] Isso permite que o Claude implemente a unidade de maneira sistemática.
22. RELAÇÃO COM O GODOT
[Certo] O asset deverá ser produzido para ser usado pelo sistema do jogo, não para ser corrigido manualmente depois da importação.
[Certo] O Godot possui propriedades de CanvasItem para texture_filter, y_sort_enabled e z_index, entre outras, que permitem controlar renderização e ordenação sem colocar essas soluções dentro da própria arte. Godot Engine documentation
[Certo] Para os nossos assets não pixelados, a documentação do Godot indica que filtros com mipmaps podem ser apropriados quando a textura é vista em escala reduzida; a decisão exata de importação, porém, pertence à implementação. Godot Engine documentation
[Certo] Portanto, não vamos embutir soluções técnicas de Godot dentro do PNG.
23. CAMERA CONTRACT
[Certo] O Battle Art deverá ser validado contra a câmera real do Battlefield.
[Certo] Não será suficiente validar o PNG isoladamente.
O teste deverá ser:
ASSET
  ↓
GODOT
  ↓
BATTLEFIELD
  ↓
CAMERA
  ↓
GRID
  ↓
ESCALA
  ↓
PROFUNDIDADE
[Certo] A imagem de referência que você enviou será usada como referência visual para essa calibração.
[Certo] Não devemos tentar inferir apenas da imagem todos os parâmetros técnicos da câmera.
24. TESTE DE CÉLULA
[Certo] Cada asset deverá passar pelo teste de célula.
Perguntas:
- a unidade cabe?
- invade a célula vizinha?
- parece apoiada?
- está visualmente centrada em sua posição?
- a arma ultrapassa excessivamente o espaço?
- a silhueta continua reconhecível?
- há colisão visual com outra unidade?
- funciona em primeiro plano?
- funciona no fundo?
[Certo] Uma unidade que só funciona em uma posição será reprovada.
25. TESTE DE PROFUNDIDADE
[Certo] O mesmo asset deverá ser testado em:
BACK DO EXÉRCITO
       ↓
LINHA INTERMEDIÁRIA
       ↓
CENTRO
       ↓
LINHA INTERMEDIÁRIA
       ↓
BACK DO ADVERSÁRIO
[Certo] A implementação poderá alterar sua escala conforme a profundidade.
[Certo] O asset não deverá conter uma escala gráfica diferente para cada linha.
26. TESTE DE ORIENTAÇÃO
[Certo] Cada unidade deverá ser testada nas quatro direções:
        BACK
          ↑
          │
LEFT ← UNIDADE → RIGHT
          │
          ↓
        FRONT
[Certo] A orientação deverá ser visualmente inequívoca.
[Certo] Isso é especialmente importante porque a direção de movimento não é determinada simplesmente pela facção.
27. TESTE DE SILHUETA
[Certo] O asset deverá ser reduzido até aproximadamente o tamanho de sua utilização real no Battlefield.
[Certo] Devemos avaliar:
- cabeça;
- arma;
- ombros;
- corpo;
- pernas;
- elementos únicos;
- forma geral.
[Certo] Se a unidade perde sua identidade quando reduzida, o problema deverá ser tratado no design do Battle Art, não apenas aumentado artificialmente.
28. TESTE DE CONSISTÊNCIA
[Certo] As quatro vistas serão comparadas simultaneamente.
FRONT | BACK | LEFT | RIGHT
[Certo] Depois as ações serão comparadas:
IDLE
ATTACK
DEFENSE
HIT
DEATH
[Certo] Devemos procurar:
- mudanças de proporção;
- mudanças de equipamento;
- mudança de escala;
- armas diferentes;
- materiais diferentes;
- detalhes que desaparecem;
- detalhes que aparecem sem justificativa;
- alteração de identidade.
29. CHARACTER LOCK
[Certo] Depois que o Character Master for aprovado, ele entra em Character Lock.
[Certo] Isso significa que as características fundamentais não poderão ser alteradas durante a produção das ações sem uma decisão explícita.
Exemplo:
MASTER
  ↓
APROVADO
  ↓
LOCK
  ↓
FRONT
BACK
LEFT
RIGHT
  ↓
AÇÕES
[Certo] Se durante uma ação descobrirmos que a armadura precisa ser alterada, não devemos simplesmente alterar aquele frame.
[Certo] A alteração deverá retornar ao Master e então propagar-se para os assets derivados.
30. FACÇÃO PILOTO
[Certo] Depois de validarmos o personagem-piloto, escolheremos uma facção completa.
[Certo] Essa facção será a primeira linha de produção real.
[Certo] O objetivo será descobrir se o pipeline continua funcionando quando há:
- humano;
- criatura;
- unidade pequena;
- unidade grande;
- corpo largo;
- corpo estreito;
- armas diferentes;
- silhuetas diferentes.
[Certo] Isso é mais importante do que simplesmente produzir 10 personagens visualmente parecidos.
31. NÃO PRODUZIR TUDO DE UMA VEZ
[Certo] A sequência de produção será:
1 PERSONAGEM
      ↓
4 ORIENTAÇÕES
      ↓
GODOT
      ↓
VALIDAÇÃO
      ↓
AÇÕES
      ↓
GODOT
      ↓
VALIDAÇÃO
      ↓
FACÇÃO COMPLETA
      ↓
OUTRAS FACÇÕES
[Certo] Esse processo evita que um erro estrutural seja multiplicado por 40.
32. CRITÉRIOS DE APROVAÇÃO
[Certo] Um personagem somente será considerado PRODUCTION READY quando cumprir todos os grupos abaixo.
Visual
[Certo]
- identidade preservada;
- facção reconhecível;
- materiais corretos;
- silhueta forte;
- acabamento compatível com o universo.
Espacial
[Certo]
- perspectiva correta;
- escala adequada;
- base correta;
- ocupação compatível com a célula;
- funcionamento em profundidade.
Orientação
[Certo]
- FRONT;
- BACK;
- LEFT;
- RIGHT;
- consistência entre as quatro.
Ações
[Certo]
- poses coerentes;
- identidade preservada;
- anchor preservado;
- transições possíveis.
Técnico
[Certo]
- transparência;
- nomenclatura;
- arquivo individual;
- estrutura de diretórios;
- compatibilidade com importação;
- identificação inequívoca pelo Claude.
33. ESTADOS DE PRODUÇÃO
[Certo] Cada asset deverá possuir um status.
CONCEPT
↓
MASTER
↓
ORIENTATION
↓
ACTION
↓
EXPORT
↓
GODOT TEST
↓
REVISION
↓
APPROVED
↓
LOCKED
[Certo] Isso evita que um arquivo experimental seja confundido com o arquivo oficial.
34. SISTEMA DE VERSIONAMENTO
[Certo] Alterações importantes deverão gerar versões.
Exemplo:
IMP_ARCHER_ATTACK_RIGHT_01_v01.png
IMP_ARCHER_ATTACK_RIGHT_01_v02.png
[Certo] Entretanto, depois da aprovação, o arquivo oficial deverá possuir um nome limpo, sem necessidade de versão no nome utilizado pelo jogo.
Exemplo:
IMP_ARCHER_ATTACK_RIGHT_01.png
[Certo] O histórico de versões ficará separado do asset de produção.
35. PROMPT MASTER
[Certo] A partir deste pipeline, cada personagem deverá possuir um Prompt Master.
Ele não será simplesmente um prompt de imagem.
Ele conterá:
IDENTIDADE
+
FACÇÃO
+
MATERIAIS
+
EQUIPAMENTO
+
SILHUETA
+
PERSPECTIVA
+
GEOMETRIA
+
ORIENTAÇÃO
+
AÇÃO
+
RESTRIÇÕES
[Certo] Os prompts das quatro vistas e das ações serão derivados dessa mesma especificação.
[Certo] Isso é o mecanismo que permitirá escalar a produção sem transformar cada geração em uma interpretação independente.
36. PROMPT DE AÇÃO
[Certo] O prompt de ação deverá modificar o comportamento, não reinventar a unidade.
Exemplo conceitual:
CHARACTER MASTER
        +
ORIENTATION
        +
ACTION
        ↓
FINAL ASSET
[Certo] Não:
novo prompt
      ↓
novo personagem parecido
37. CONTROLE DE QUALIDADE VISUAL
[Certo] A revisão deverá ocorrer em três níveis.
Nível 1 — Isolado
[Certo] O PNG é analisado sozinho.
Nível 2 — Comparativo
[Certo] As quatro orientações são colocadas lado a lado.
Nível 3 — Battlefield
[Certo] O asset é colocado no Battlefield real.
[Certo] O terceiro nível é o decisivo.
38. REGRA DE OURO
[Certo] Esta frase passa a ser o teste definitivo do pipeline:
“Esse asset continua funcionando quando colocado no Battlefield real, em uma célula da grade, em qualquer uma das quatro orientações, em diferentes profundidades e durante suas ações?”

[Certo] Se a resposta for não, o asset não está pronto.
39. PRIMEIRO CICLO DE IMPLEMENTAÇÃO
[Certo] O primeiro ciclo será:
BATTLE ART PIPELINE v1
        ↓
CAMERA CONTRACT
        ↓
ASSET CONTRACT
        ↓
CHARACTER MASTER
        ↓
4 ORIENTAÇÕES
        ↓
GODOT
        ↓
CALIBRAÇÃO
        ↓
AÇÕES
        ↓
GODOT
        ↓
APROVAÇÃO DO PIPELINE
[Certo] Somente depois disso:
FACÇÃO PILOTO
        ↓
TODOS OS PERSONAGENS
        ↓
OUTRAS FACÇÕES
        ↓
BIBLIOTECA COMPLETA
40. DEFINIÇÃO DO V1
[Certo] O BATTLE SIMULATOR — BATTLE ART PRODUCTION PIPELINE v1 fica definido como um pipeline de produção orientado por Master, com quatro orientações-base, estados de ação derivados, arquivos individuais, transparência real, anchor consistente, validação espacial no Battlefield e integração obrigatória com o Godot antes da produção em escala.