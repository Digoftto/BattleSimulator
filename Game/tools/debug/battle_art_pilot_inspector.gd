extends Control
## BattleArtPilotInspector — FERRAMENTA TEMPORÁRIA DE INSPEÇÃO VISUAL
## (Battle Art MVP — Piloto, 2026-09-02)
##
## NÃO faz parte da arquitetura definitiva do jogo. Não é referenciada
## por nenhuma cena/script de produção, não é autoload, não é acessada
## por nenhum fluxo real do jogador. Existe SÓ para o usuário abrir esta
## cena no Godot Editor (F6, "Executar Cena Atual") e inspecionar
## visualmente o piloto de Battle Art já implementado — pode ser
## apagada a qualquer momento sem afetar o jogo.
##
## Reutiliza EXATAMENTE os sistemas já validados, sem recriar nenhuma
## lógica de posicionamento:
##   - CombatReplayView real (mesma cena de produção);
##   - BattleUnitArtLayer/BattleUnitArtCatalog/BattleUnitArtGeometry
##     (via CombatReplayView, nunca instanciados/chamados em paralelo);
##   - CombatEngine._movement_phase() real, para o Move Test;
##   - o mesmo formato de evento UNIT_DIED que CombatEngine publica de
##     verdade, para o Death Test (mesma técnica já usada pelos testes
##     automatizados desta mesma etapa).
##
## Os labels de diagnóstico (SIDE/POSITION/DEPTH REGION/UNIT_ID e as
## etiquetas "S{side} P{position}" sobre cada slot) são adicionados
## como filhos de CombatReplayView._board_layer — a MESMA camada onde
## BattleCardView e os rótulos de lado já vivem em produção — para usar
## exatamente as mesmas frações de posição já calculadas por
## CombatReplayView, nunca uma segunda conta de geometria. São
## OVERLAY DE DEBUG DESTA FERRAMENTA, nunca incorporados a nenhum asset.
##
## TESTE VISUAL 02/03 (2026-09-02) — "sem cartas" + "tamanho/centralização
## padrão": NENHUM arquivo de produção foi alterado pra isso
## (CombatReplayView/BattleUnitArtLayer/BattleUnitArtGeometry/
## BattleCardView continuam byte-a-byte iguais). Os efeitos são
## aplicados INTEIRAMENTE aqui, de fora, depois que a produção já fez o
## que sempre faz:
##   - "sem cartas": _hide_all_cards() só chama view.visible = false
##     em cada BattleCardView já criada por CombatReplayView (via
##     _position_widgets, já público-de-fato/lido por outras
##     ferramentas/testes) — nunca reposiciona nada, nunca remove nada
##     da árvore, nunca toca CombatReplayView/BattleCardView;
##   - "tamanho/centralização padrão" (Teste Visual 03): sobrescreve SÓ
##     os anchors do TextureRect que BattleUnitArtLayer já criou (via
##     BattleUnitArtLayer.sprite_for(), já um accessor público existente
##     desde o piloto) com: (X) o centro do BOUNDING BOX ALFA REAL
##     (BattleUnitArtCatalog.content_alpha_rect_for(), nunca o canvas
##     bruto do PNG) alinhado ao centro visual REAL da célula
##     (CombatReplayView._visual_center_frac(), nunca recalculado);
##     (Y) a mesma convenção de base/anchor já validada no piloto
##     (BASE_OFFSET_FRAC, base do conteúdo perto do centro do slot,
##     cresce só pra cima — nunca centralização vertical do bbox
##     inteiro); (tamanho) UM fator fixo, igual pra todas as 9 posições
##     e os 2 lados. NUNCA chama nem duplica BattleUnitArtGeometry.
##     region_box_px()/fit_scale()/DEPTH_REGION_SCALE (que continuam
##     intocados e em uso normal quando esse modo está desligado).
##     Reaproveita ArtGeometry.BATTLEFIELD_IMAGE_SIZE/BASE_OFFSET_FRAC
##     (as MESMAS constantes reais). SUPERADO pelo Teste Visual 04
##     abaixo (flag renomeada pra USE_FOOT_CENTER_ALIGNMENT, ponto de
##     referência corrigido pra centro real da célula, escala por lado
##     em vez de global) — descrição mantida aqui só como histórico.
## Como CombatReplayView já reexecuta _refresh_position_widget()/
## _refresh_unit_art() a cada evento (movimento/morte), os efeitos
## precisam ser reaplicados depois de CADA evento (ver _rebuild_board(),
## o loop do Move Test e _on_death_test_pressed()) — nunca uma vez só.
##
## TESTE VISUAL 04 (2026-09-02) — "ponto central da célula" real +
## escala por lado: antes de confiar em
## CombatReplayView._visual_center_frac(), investiguei se ele realmente
## devolve o CENTRO geométrico de cada célula isométrica (pedido
## explícito desta tarefa — nunca assumir). Método: script headless
## isolado (apagado ao final, nunca parte da entrega) que desenhou, por
## cima do PNG real do Battlefield (res://assets/art/battlefields/
## campo_aberto.png), um marcador vermelho em CADA
## "ORIGIN + r*E1 + c*E2" (r,c em 0..2, os dois blocos) e um marcador
## azul em "ORIGIN + r*E1 + c*E2 + 0.5*E1 + 0.5*E2" — e comparei
## visualmente contra as molduras de pedra desenhadas na arte. Achado:
## os marcadores VERMELHOS caem sistematicamente perto de um CANTO de
## cada quadrado (nunca do centro); os AZUIS (com a correção de meio
## passo) caem consistentemente perto do centro visual real, nas 9
## células dos dois blocos. Conclusão: "_visual_center_frac()" (e a
## constante ORIGIN de onde ele deriva) representa o CANTO de cada
## célula dentro da grade afim local, não seu centro — um detalhe de
## calibração da geometria de produção que nunca foi percebida antes,
## porque o único uso existente (a cartinha compacta de BattleCardView,
## a 0.92x a largura do slot) só precisa de "estar dentro do quadrado" —
## uma carta pequena cumpre isso mesmo ancorada perto de um canto,
## nunca exigindo precisão de centro geométrico. Não alterei
## BattlefieldSlotGeometry/CombatReplayView por
## causa disso (fora do escopo desta tarefa, exige aprovação); apenas
## LEIO as constantes públicas já existentes (CombatReplayView.
## PLAYER_TILE_E1/E2, ENEMY_TILE_E1/E2) e aplico a correção de meio
## passo SÓ aqui, em _true_cell_center_frac() — nunca uma segunda grade,
## só a leitura correta da mesma grade real.
##
## TESTE VISUAL 05 (2026-09-02) — CORREÇÃO DE UM ACHADO DO TESTE 04 +
## FOOT CENTER real (entre os dois pés, não um dos pés):
##
## 1) A correção de "meio passo" do Teste 04 (+0,5·E1+0,5·E2) estava
##    ERRADA — não foi validada com rigor suficiente na ocasião (só
##    inspeção visual de uma imagem pequena). Nesta etapa, medi
##    precisamente com um script Python isolado (apagado ao final,
##    nunca parte da entrega): sobre o PNG real do Battlefield, detectei
##    algoritmicamente o INTERIOR de várias células reais (limiar de
##    brilho HSV V>170 isola a moldura de pedra; o interior — grama — é
##    o "buraco" escuro dentro dela; scipy.ndimage rotulou os
##    componentes conectados) e calculei o centro geométrico real de
##    cada célula como a média dos 4 pontos extremos (topo/base/
##    esquerda/direita) do interior — exatamente o método pedido nesta
##    tarefa (seção 4, "center = (P1+P2+P3+P4)/4").
##    Resultado: no Lado 0 (Jogador), a célula da Posição 1 (r=0,c=0 —
##    coincide com a própria constante PLAYER_TILE_ORIGIN) tem centro
##    real medido em ~(496,592)px — a apenas ~2,7px de
##    "_visual_center_frac()" SEM NENHUMA correção. Testei outras 5
##    células (passos de 1-2 unidades em E1/E2 a partir da origem): em
##    TODAS elas, o ponto SEM correção (hipótese A) ficou mais perto do
##    centro real medido do que o ponto COM a correção de meio passo do
##    Teste 04 (hipótese B) — a correção do Teste 04 tornava o erro
##    MAIOR, não menor. Porém o erro de A também CRESCE com a distância
##    do ponto de calibração (de ~3px na própria origem até ~45px em
##    células 1-2 passos de distância) — consistente com E1/E2 sendo
##    vetores de passo MÉDIOS/aproximados de uma projeção isométrica com
##    curvatura de perspectiva real (não perfeitamente afim), não vetores
##    exatos aresta-a-aresta de cada célula. CONCLUSÃO: não existe uma
##    ÚNICA correção constante (nem "+0", nem "+meio passo") que acerte
##    as 9 células com precisão — uma correção definitiva exigiria
##    remedir os 4 vértices reais das 9×2 células e ajustar
##    BattlefieldSlotGeometry/CombatReplayView (fora do escopo desta
##    tarefa, decisão de produção separada). Decisão para ESTA
##    ferramenta: revertido pra usar "_visual_center_frac()" SEM
##    correção (a aproximação mais precisa disponível sem uma tabela por
##    posição, proibida) — _true_cell_center_frac() abaixo agora só
##    repassa o valor bruto, mantido como função nomeada por clareza/
##    documentação, não por ter uma correção real aplicada.
##
## 2) FOOT CENTER: o "bottom do bounding box alfa" usado nos Testes
##    02-04 corresponde ao ponto mais baixo de QUALQUER pixel do
##    personagem — que, pela pose assimétrica do Arqueiro (as pernas
##    abertas, um pé bem à frente/baixo, outro mais atrás/alto na
##    projeção), coincide com A SOLA DE UM PÉ SÓ (o mais próximo da
##    câmera), nunca com o ponto médio entre os dois. Medido com script
##    Python isolado (apagado ao final): varri a coluna de alfa>5 mais
##    baixa por coluna X do PNG fonte (Assets/MVP/Pelotão/Império/
##    Arqueiro Imperial.png, nunca editado), identifiquei dois "morros"
##    separados no perfil (dois pontos de contato reais, cada um a
##    largura de uma sola) e uma composição visual (recorte com grade de
##    coordenadas, sobre fundo verde sólido pra contraste) confirmou
##    visualmente as duas botas:
##      LEFT_FOOT_CONTACT  ≈ (256, 1288)  no canvas 1024×1536
##      RIGHT_FOOT_CONTACT ≈ (683, 1479)  no canvas 1024×1536
##      FOOT_CENTER = ponto médio           ≈ (469.5, 1383.5)
##    Convertidos pra fração do retângulo alfa recortado (o mesmo que
##    BattleUnitArtCatalog.content_alpha_rect_for() já usa em produção,
##    aqui medido como [P:(188,78) S:(740,1404)]):
##      LEFT_FOOT_FRAC_IN_CONTENT  ≈ (0.092, 0.862)
##      RIGHT_FOOT_FRAC_IN_CONTENT ≈ (0.669, 0.998)
##      FOOT_CENTER_FRAC_IN_CONTENT ≈ (0.380, 0.930)
##    Note que FOOT_CENTER NÃO fica no centro horizontal do bbox (0.5) —
##    o bbox inclui o arco/flechas, que puxam o "centro do retângulo"
##    pra longe do centro real entre os pés — nem na base exata do bbox
##    (1.0) — só o pé direito (mais perto da câmera) toca ali; o pé
##    esquerdo, mais atrás na pose, fica ~14% acima disso. Estes três
##    valores são constantes MEDIDAS específicas do Arqueiro Imperial
##    (nunca vão servir pra outro personagem sem nova medição) — nunca
##    inventadas, ver derivação completa no relatório desta tarefa.
##
## CALIBRAÇÃO DAS 18 CÉLULAS (2026-09-02) — investigação separada do
## Battle Art (nenhum dado desta seção é usado pra posicionar o
## Arqueiro nesta tarefa). Método reproduzível, sem nenhuma coordenada
## escolhida "a olho" (script Python isolado, apagado ao final, nunca
## parte da entrega):
##   1. Limiar de brilho HSV (V>170) isola a moldura de pedra clara
##      contra o fundo mais escuro no PNG real do Battlefield
##      (res://assets/art/battlefields/campo_aberto.png).
##   2. O INVERSO desse limiar (V<=170) marca o interior de cada
##      célula (grama) como um "buraco" fechado pela moldura;
##      scipy.ndimage.label() separa cada buraco em um componente
##      conectado — um blob por célula.
##   3. Pra cada blob: os 4 pontos extremos (topo/base/esquerda/
##      direita, em pixels REAIS) definem os "4 vértices" pedidos na
##      seção 3; CENTER = média desses 4 pontos (mesma fórmula pedida:
##      "(P_TOP+P_RIGHT+P_BOTTOM+P_LEFT)/4"). Conferido contra o
##      centroide de TODOS os pixels do interior (não só os 4 extremos)
##      — os dois métodos bateram dentro de ~3px em todas as células
##      checadas, confirmando que a média dos 4 vértices é uma
##      aproximação válida aqui.
##   4. Correspondência blob -> (Side, Posição): 1 blob "estranho"
##      (claramente fora da grade oficial 3x3 — provavelmente um
##      ladrilho extra pintado além da grade usada, coerente com a
##      filosofia "o mundo continua além da câmera" de
##      BATTLEFIELD_ART_BIBLE.md) foi descartado por estar a >200px de
##      qualquer hipótese, muito acima do pior caso legítimo (~157px).
##      Os 9 blobs restantes de cada lado foram associados às 9
##      Posições via atribuição ÓTIMA (scipy.optimize.
##      linear_sum_assignment, minimiza a soma total das distâncias)
##      contra as hipóteses A conhecidas — nunca associação gulosa/na
##      ordem de leitura, que se mostrou instável quando o erro de A é
##      grande o bastante pra confundir posições vizinhas.
## RESULTADO (ver relatório desta tarefa pra tabela completa das 18
## células): a hipótese A (_visual_center_frac() sem correção)
## continua sendo mais precisa que a hipótese B (+0,5·E1+0,5·E2) na
## média dos dois lados. O Lado 1 (Inimigo) tem erro pequeno e
## consistente nas 9 posições (13-75px). O Lado 0 (Jogador) tem erro
## pequeno nas Posições 1/2/5/6/7/8, mas GRANDE nas Posições 3/4/9 — as
## três da COLUNA C (COMBAT_RULES.md, "posições [3,4,9]") — chegando a
## 105-157px. Isso é consistente com o Lado 0 (bloco mais perto da
## câmera) sofrendo mais distorção de perspectiva por passo de grade do
## que o Lado 1 (mais longe) — a aproximação afim (E1/E2 constantes)
## degrada mais rápido no bloco próximo.
##
## TESTE VISUAL 06 (2026-09-02) — REFINAMENTO METODOLÓGICO + achado
## adicional: o Teste 05 usava os 4 extremos do INTERIOR (grama) do
## blob como "os 4 vértices" — uma aproximação, não necessariamente o
## centro real da ESPESSURA da moldura de pedra. Corrigido aqui: pra
## cada um dos 4 extremos já detectados, escaneei um perfil de brilho
## (V) pra FORA da célula (mesmo eixo do extremo — vertical pro
## topo/base, horizontal pra esquerda/direita) até o valor "assentar"
## numa faixa estável (variação <8 entre 4 amostras seguidas) — isso
## mede a espessura LOCAL da moldura (realce claro + sombra de contato
## imediatamente adjacente, ambos parte do mesmo elemento visual de
## borda) naquele ponto; o vértice corrigido fica na METADE dessa
## espessura, pra fora do extremo original (aproxima o centro da
## própria borda, como pedido, não só sua borda interna). RESULTADO:
## em todas as 18 células, essa correção moveu o centro calculado em
## só 0,2 a 2,5px — desprezível comparado aos 12-157px de erro contra
## a geometria afim atual. Ou seja: o método do Teste 05 já era preciso
## o bastante pra achar o centro (a crítica metodológica era válida em
## princípio, mas não muda a conclusão) — os números abaixo são os
## REFINADOS (Teste 06), usados como valor final.
##
## Verificação de coerência espacial (pedida explicitamente nesta
## tarefa): para as 6 sequências (P1→P2→P3, P6→P5→P4, P7→P8→P9,
## P1→P6→P7, P2→P5→P8, P3→P4→P9) dos dois lados, os deltas entre
## células consecutivas têm SEMPRE o mesmo sinal e crescem suavemente
## de magnitude (nunca invertem direção, nunca saltam de ordem de
## grandeza) — coerente com uma câmera isométrica real, onde passos de
## grade mais perto da câmera cobrem mais pixels que passos mais longe.
## Isso é adicionalmente FORTE evidência de que a aproximação afim (E1/
## E2 CONSTANTES) é a causa raiz do erro: a câmera real não tem passo
## constante, o afim assume que tem.
##
## ACHADO QUE EXIGIU INVESTIGAÇÃO ADICIONAL (nunca resolvido por
## adivinhação): Posições 3, 4 e 9 do LADO 0 continuam com erro grande
## MESMO após o refinamento de espessura (a correção de espessura não
## muda a causa, só a precisão da medição em si — ver acima). Inspeção
## visual direta do diagnóstico (18 cruzes sobre a arte real) mostra
## que, pra essas 3 células especificamente, a cruz cai numa área sem
## uma moldura de pedra tão nítida/fechada quanto as outras 15 — pode
## ser uma limitação real da própria arte (borda menos definida nessa
## região do Battlefield) ou uma dificuldade genuína de detecção
## automática ali. Marcadas como BAIXA CONFIANÇA (LOW_CONFIDENCE_CELLS
## abaixo) — precisam de confirmação visual humana antes de qualquer
## uso futuro, nunca just "corrigidas a olho" aqui.
##
## Os centros MEDIDOS (18 células, dois lados) foram exibidos aqui só no
## modo "CALIBRATION" (ver _on_calibration_pressed()), como FRAÇÃO (0..1)
## da imagem do Battlefield (1536×1024) — nunca uma segunda grade
## paralela à de produção, só o resultado de uma medição direta da arte
## real. Nomeada deliberadamente MEASURED_CELL_CENTER_FRAC (nunca
## "offset" nem "correção de posição") — representa
## CELL_CENTER[side][position] conceitualmente, não um ajuste aplicado a
## nada. TESTE VISUAL 08: a tabela em si foi MOVIDA (não duplicada) para
## ArtGeometry.MEASURED_CELL_CENTER_FRAC — única fonte de verdade agora
## que produção também a consome; esta ferramenta só a lê de lá.
##
## TESTE VISUAL 07: a inspeção visual humana do Teste 06 (mesmas 3
## células, Lado 0 Posições 3/4/9, então marcadas como baixa confiança)
## concluiu que os 18 CELL_CENTER estão "suficientemente centralizados
## visualmente" — aprovação explícita do usuário. A distinção visual de
## baixa confiança (cor vermelha no modo Calibration) foi removida por
## estar resolvida; a tabela acima é usada como está, sem exceção por
## posição.
##
## TESTE VISUAL 08 (2026-09-02) — CONSOLIDAÇÃO/LIMPEZA: a fórmula
## calibrada (CELL_CENTER + FOOT_CENTER + escala fixa por lado), até
## aqui aplicada SÓ como override de depuração desta ferramenta (função
## _apply_foot_center_alignment_override(), agora removida), foi PORTADA
## para produção (BattleUnitArtGeometry.placement_for(), chamada de
## verdade por BattleUnitArtLayer/CombatReplayView — nenhuma outra
## alteração de posicionamento nesta tarefa, só a MUDANÇA DE DONO: onde
## antes só esta ferramenta calculava a posição aprovada, agora
## CombatReplayView já entrega o Battle Art corretamente posicionado por
## si só, como qualquer outra unidade real do jogo). Esta ferramenta
## NUNCA mais duplica a tabela de CELL_CENTER/FOOT_CENTER/escala — lê
## tudo de ArtGeometry (única fonte de verdade), tanto pra decidir onde
## desenhar os overlays de debug quanto pra saber o que já está correto
## por produção. Os overlays de debug (labels "S P"/"FOOT CENTER",
## cruzes, pontos de pé, modo Calibração) continuam existindo só aqui,
## nunca em CombatReplayView/BattleUnitArtLayer/BattleUnitArtGeometry/
## BattleUnitArtCatalog (auditoria desta tarefa: nenhuma dessas 4 classes
## de produção cria Label/cruz/marcador — confirmado por leitura direta
## de cada arquivo, ver relatório).

## PILOTOS 02/03 (2026-09-02): a ferramenta agora permite alternar entre
## os 3 pilotos com Battle Art registrada — nunca mais um único
## PILOT_NAME fixo. card_class/faction abaixo só documentam o card_name
## real de GameDatabase (arqueiro_imperial.tres/altar_da_reanimacao.tres/
## unicornio_ancestral.tres) — a resolução de Battle Art em si nunca
## depende desses campos (só de card_name, ver BattleUnitArtCatalog).
const PILOT_NAME: String = "Arqueiro Imperial"
const MACHINE_PILOT_NAME: String = "Altar da Reanimação"
const QUADRUPED_PILOT_NAME: String = "Unicórnio Ancestral"
## FASE 2 — SEGUNDA BATERIA (2026-09-02): 5 pilotos adicionais.
const ENT_PILOT_NAME: String = "Ent Jovem"
const CATAPULT_PILOT_NAME: String = "Balista Imperial"
const OAK_PILOT_NAME: String = "Carvalho Ancião"
const BONE_WALL_PILOT_NAME: String = "Muralha de Ossos"
const CAPTAIN_PILOT_NAME: String = "Capitão Imperial"

## FASE 3.1 (2026-09-03) — os 4 casos marcados VISUAL CALIBRATION na
## migração da Fase 3 (ver battle_unit_art_geometry.gd,
## CARD_NAME_TO_FOOT_CENTER_FRAC): nenhum tem contato físico totalmente
## inequívoco com o chão (2 etéreos sem pernas, 1 parcialmente ambíguo
## por causa da saia/névoa, 1 em pose de voo/mergulho sem pouso). Os
## valores de GROUND_CONTACT já cadastrados NÃO são alterados por esta
## ferramenta — só ficam mais fáceis de inspecionar visualmente, com o
## mesmo overlay (cruz CELL_CENTER + ponto branco GROUND_CONTACT) já
## usado pelos 8 pilotos anteriores, reaproveitado sem nenhuma mudança
## de lógica.
const SPECTRAL_REAPER_PILOT_NAME: String = "Ceifadora Espectral"
const BANSHEE_PILOT_NAME: String = "Banshee"
const SPECTRAL_ARCHER_PILOT_NAME: String = "Arqueira Espectral"
const GOLDEN_EAGLE_PILOT_NAME: String = "Águia Dourada"

const PILOT_DEFINITIONS: Dictionary = {
	"Arqueiro Imperial": {"card_class": "À Distância", "faction": "Império"},
	"Altar da Reanimação": {"card_class": "Máquina de Guerra", "faction": "Mortos-Vivos"},
	"Unicórnio Ancestral": {"card_class": "Mago", "faction": "Natureza"},
	"Ent Jovem": {"card_class": "Mago", "faction": "Natureza"},
	"Balista Imperial": {"card_class": "Máquina de Guerra", "faction": "Império"},
	"Carvalho Ancião": {"card_class": "Barreira", "faction": "Natureza"},
	"Muralha de Ossos": {"card_class": "Barreira", "faction": "Mortos-Vivos"},
	"Capitão Imperial": {"card_class": "Suporte", "faction": "Império"},

	"Ceifadora Espectral": {"card_class": "À Distância", "faction": "Mortos-Vivos"},
	"Banshee": {"card_class": "Mago", "faction": "Mortos-Vivos"},
	"Arqueira Espectral": {"card_class": "À Distância", "faction": "Mortos-Vivos"},
	"Águia Dourada": {"card_class": "À Distância", "faction": "Natureza"},
}
var _active_pilot_name: String = PILOT_NAME
const ReplayCollectorScript = preload("res://engine/combat/combat_replay_collector.gd")
const ReplayViewScript = preload("res://scenes/combat/combat_replay_view.gd")
const ArtCatalog = preload("res://engine/presentation/battle_unit_art_catalog.gd")
const ArtGeometry = preload("res://engine/presentation/battle_unit_art_geometry.gd")

## FASE 4.1 (2026-09-03) — COMPARAÇÃO A/B das 6 versões harmonizadas do
## experimento da Fase 4 (relatório da tarefa anterior). Nenhuma entrada
## de BattleUnitArtCatalog.CARD_NAME_TO_PATH é alterada — os PNGs
## experimentais em Assets/MVP/Pelotão/_Harmonizado_EXPERIMENTAL/ são
## carregados SÓ por esta ferramenta, SÓ nesta seção, nunca pelo
## caminho de produção.
##
## TÉCNICA: a produção (BattleUnitArtLayer.register_or_update(), via
## _rebuild_board() normal desta ferramenta) já resolve corretamente o
## sprite ORIGINAL — anchor/escala/CELL_CENTER/GROUND_CONTACT todos
## calculados por ArtGeometry.placement_for() com as dimensões do
## retângulo alfa do PNG ORIGINAL. Como harmonize.py (Fase 4) GARANTIU
## por assert que a máscara alfa da versão harmonizada é PIXEL-IDÊNTICA
## à original (nunca altera silhueta/canvas, só RGB), o retângulo alfa
## já calculado pela produção — ArtCatalog.content_alpha_rect_for(card_name),
## método PÚBLICO, nunca duplicado aqui — serve OS DOIS PNGs sem
## nenhuma diferença. Por isso o modo "B — Harmonizado" nunca recalcula
## geometria: só troca sprite.texture (TextureRect já público via
## BattleUnitArtLayer.sprite_for(), accessor já existente) depois que a
## produção posicionou tudo — nenhuma segunda fórmula de posicionamento
## existe nesta ferramenta.
const AB_HARMONIZED_RELATIVE_PATH: Dictionary = {
	"Engenheiro Imperial": "_Harmonizado_EXPERIMENTAL/Império/IMPERIAL ENGINEER.png",
	"Besteiro Imperial": "_Harmonizado_EXPERIMENTAL/Império/BESTEIRO IMPERIAL.png",
	"Ceifadora Espectral": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/SPECTRAL REAPER.png",
	"Abominação Putrefata": "_Harmonizado_EXPERIMENTAL/Morto-Vivo/putrid abomination.png",
	"Carvalho Milenar": "_Harmonizado_EXPERIMENTAL/Natureza/Millennial Oak.png",
	"Águia Dourada": "_Harmonizado_EXPERIMENTAL/Natureza/GOLDEN EAGLE.png",
}

## FASE 4.2/4.3 (2026-09-03) — versão C, "HARMONIZAÇÃO CONSERVADORA"
## (curva de highlight linear + knee alto, sem midtone_lift — prioriza
## preservar nitidez/microcontraste, ver relatório da Fase 4.2). Só
## existe pros 4 assets que mostraram perda de nitidez perceptível na
## versão B (Engenheiro/Besteiro Imperial nunca tiveram esse problema —
## nenhuma versão C foi produzida pra eles, de propósito).
const AB_HARMONIZED_C_RELATIVE_PATH: Dictionary = {
	"Ceifadora Espectral": "_Harmonizado_EXPERIMENTAL_C/Morto-Vivo/SPECTRAL REAPER.png",
	"Abominação Putrefata": "_Harmonizado_EXPERIMENTAL_C/Morto-Vivo/putrid abomination.png",
	"Carvalho Milenar": "_Harmonizado_EXPERIMENTAL_C/Natureza/Millennial Oak.png",
	"Águia Dourada": "_Harmonizado_EXPERIMENTAL_C/Natureza/GOLDEN EAGLE.png",
}

## "original" | "harmonized" | "conservative_c" | "side_by_side" |
## "side_by_side_abc" — nunca persistido, reseta pra "original" a cada
## troca de piloto (Reset/_on_pilot_pressed()), pra nunca deixar a
## comparação "vazada" pra outro card_name.
var _ab_mode: String = "original"
var _ab_label: Label
static var _harmonized_texture_cache: Dictionary = {}
static var _harmonized_c_texture_cache: Dictionary = {}

## Mesma técnica de leitura fora de res:// já documentada e usada por
## BattleUnitArtCatalog._project_root_dir() (nunca chamada daqui —
## função privada de outra classe; um join de caminho de uma linha não
## justifica acoplamento entre classes, então é repetido aqui, não
## "duplicação de lógica de posicionamento" nenhuma).
static func _harmonized_project_root_dir() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://").trim_suffix("/")
	return game_dir.get_base_dir()


## Textura já recortada (AtlasTexture) de uma variante experimental
## (B ou C) de "card_name" — null se este card_name não fizer parte
## dessa variante do experimento. Usa
## ArtCatalog.content_alpha_rect_for(card_name) (PÚBLICO, calculado
## sobre o PNG ORIGINAL) como retângulo de recorte — válido pras 3
## versões (A/B/C) porque a máscara alfa é idêntica nas 3 (garantida
## por assert em harmonize.py/harmonize_v2_conservative.py). Parametrizada
## por dicionário de caminhos + cache (nunca duas cópias desta função —
## B e C reaproveitam exatamente a mesma lógica).
static func _harmonized_variant_texture_for(card_name: String, relative_paths: Dictionary, cache: Dictionary) -> Texture2D:
	if not relative_paths.has(card_name):
		return null
	if cache.has(card_name):
		return cache[card_name]

	var abs_path: String = _harmonized_project_root_dir() + "/Assets/MVP/Pelotão/" + relative_paths[card_name]
	var image := Image.new()
	if image.load(abs_path) != OK:
		return null

	var raw_texture: Texture2D = ImageTexture.create_from_image(image)
	var rect: Rect2i = ArtCatalog.content_alpha_rect_for(card_name)
	var atlas := AtlasTexture.new()
	atlas.atlas = raw_texture
	atlas.region = Rect2(rect)
	cache[card_name] = atlas
	return atlas


static func _harmonized_cropped_texture_for(card_name: String) -> Texture2D:
	return _harmonized_variant_texture_for(card_name, AB_HARMONIZED_RELATIVE_PATH, _harmonized_texture_cache)


static func _harmonized_c_cropped_texture_for(card_name: String) -> Texture2D:
	return _harmonized_variant_texture_for(card_name, AB_HARMONIZED_C_RELATIVE_PATH, _harmonized_c_texture_cache)


## Aplicada depois de QUALQUER rebuild de tabuleiro (mesmo padrão de
## _apply_visual_test_overrides()) — troca só sprite.texture das
## unidades ativas pra B ou C quando _ab_mode pede, nunca toca
## anchor/escala (já corretos, calculados pela produção real com o PNG
## original). No-op silencioso pra qualquer card_name fora da variante
## pedida — nenhum comportamento diferente pros outros pilotos.
func _apply_ab_compare_mode() -> void:
	if _current_view == null:
		return
	var texture: Texture2D = null
	if _ab_mode == "harmonized":
		texture = _harmonized_cropped_texture_for(_active_pilot_name)
	elif _ab_mode == "conservative_c":
		texture = _harmonized_c_cropped_texture_for(_active_pilot_name)
	else:
		return
	if texture == null:
		return
	for unit_id: int in _unit_diagnostics.keys():
		var sprite: TextureRect = _current_view._unit_art_layer.sprite_for(unit_id)
		if sprite != null:
			sprite.texture = texture

## Teste Visual 08: única flag restante desta ferramenta. A produção
## (CombatReplayView) já esconde sozinha a carta compacta de qualquer
## unidade com Battle Art (ver combat_replay_view.gd,
## _refresh_position_widget()) — então, pro próprio piloto, esta flag já
## não muda nada. Ela continua útil aqui só pra também esconder as
## cartas dos blocos SEM Battle Art usados pelo Move Test (Fix-1/Fix-2,
## que nunca têm Battle Art, então a produção nunca os esconderia
## sozinha), permitindo uma inspeção 100% livre de cartas quando
## necessário.
const HIDE_CARDS_FOR_VISUAL_TEST: bool = true

## TESTE VISUAL 05 — pontos de contato dos pés do Arqueiro Imperial,
## medidos diretamente no PNG fonte, como FRAÇÃO (0..1) do retângulo
## alfa recortado (BattleUnitArtCatalog.content_alpha_rect_for()).
## Usados SÓ pelos marcadores de debug desta ferramenta (comparar contra
## a cruz do CELL CENTER) — o ponto médio entre os dois
## (FOOT_CENTER_FRAC_IN_CONTENT) é o mesmo já portado para produção em
## ArtGeometry.CARD_NAME_TO_FOOT_CENTER_FRAC (única fonte de verdade,
## nunca duplicada aqui).
const LEFT_FOOT_FRAC_IN_CONTENT: Vector2 = Vector2(0.092, 0.862)
const RIGHT_FOOT_FRAC_IN_CONTENT: Vector2 = Vector2(0.669, 0.998)

var _side_mode: String = "both"  # "0" | "1" | "both"
var _position_mode: int = -1     # 1-9, ou -1 = Todas as Posições

var _current_view: Control = null
var _current_state: CombatState = null
var _current_collector = null

## unit_id -> {"side": int, "position": int} — só para o overlay de
## diagnóstico desta ferramenta, nunca lido por nenhum sistema real.
var _unit_diagnostics: Dictionary = {}
var _active_unit_id: int = -1  # alvo de Move Test / Death Test

var _battlefield_area: Control
var _status_label: Label
var _diagnostics_label: Label
var _pilot_label: Label
var _move_test_running: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1400, 900)
	_build_ui()
	_rebuild_board()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.08, 0.09)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_hbox := HBoxContainer.new()
	root_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_hbox)

	_battlefield_area = Control.new()
	_battlefield_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battlefield_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_hbox.add_child(_battlefield_area)

	var panel := _build_control_panel()
	panel.custom_minimum_size = Vector2(300, 0)
	root_hbox.add_child(panel)


func _build_control_panel() -> Control:
	var scroll := ScrollContainer.new()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	vbox.add_child(_make_label("BATTLE ART — INSPEÇÃO DO PILOTO", 16))
	vbox.add_child(_make_label("Ferramenta temporária (não é o jogo).", 11))

	vbox.add_child(_make_label("— PILOTO —", 13))
	var pilot_row := VBoxContainer.new()
	pilot_row.add_child(_make_button("01 — Arqueiro Imperial (humanoide)", _on_pilot_pressed.bind(PILOT_NAME)))
	pilot_row.add_child(_make_button("02 — Altar da Reanimação (Máquina de Guerra)", _on_pilot_pressed.bind(MACHINE_PILOT_NAME)))
	pilot_row.add_child(_make_button("03 — Unicórnio Ancestral (quadrúpede)", _on_pilot_pressed.bind(QUADRUPED_PILOT_NAME)))
	pilot_row.add_child(_make_button("04 — Ent Jovem (estrutura orgânica bípede)", _on_pilot_pressed.bind(ENT_PILOT_NAME)))
	pilot_row.add_child(_make_button("05 — Balista Imperial (veículo com rodas)", _on_pilot_pressed.bind(CATAPULT_PILOT_NAME)))
	pilot_row.add_child(_make_button("06 — Carvalho Ancião (múltiplas raízes)", _on_pilot_pressed.bind(OAK_PILOT_NAME)))
	pilot_row.add_child(_make_button("07 — Muralha de Ossos (bípede/golem)", _on_pilot_pressed.bind(BONE_WALL_PILOT_NAME)))
	pilot_row.add_child(_make_button("08 — Capitão Imperial (bípede)", _on_pilot_pressed.bind(CAPTAIN_PILOT_NAME)))
	vbox.add_child(pilot_row)

	vbox.add_child(_make_label("— VISUAL CALIBRATION (FASE 3.1) —", 13))
	vbox.add_child(_make_label("4 casos sem contato físico inequívoco — inspecionar antes de aprovar.", 10))
	var calibration_row := VBoxContainer.new()
	calibration_row.add_child(_make_button("09 — Ceifadora Espectral (etérea, sem pés)", _on_pilot_pressed.bind(SPECTRAL_REAPER_PILOT_NAME)))
	calibration_row.add_child(_make_button("10 — Banshee (etérea, base larga/irregular)", _on_pilot_pressed.bind(BANSHEE_PILOT_NAME)))
	calibration_row.add_child(_make_button("11 — Arqueira Espectral (botas parcialmente ambíguas)", _on_pilot_pressed.bind(SPECTRAL_ARCHER_PILOT_NAME)))
	calibration_row.add_child(_make_button("12 — Águia Dourada (voo/mergulho, sem pouso)", _on_pilot_pressed.bind(GOLDEN_EAGLE_PILOT_NAME)))
	vbox.add_child(calibration_row)
	_pilot_label = _make_label("Piloto ativo: %s" % _active_pilot_name, 11)
	vbox.add_child(_pilot_label)

	vbox.add_child(_make_label("— SIDE —", 13))
	var side_row := HBoxContainer.new()
	side_row.add_child(_make_button("Side 0", _on_side_pressed.bind("0")))
	side_row.add_child(_make_button("Side 1", _on_side_pressed.bind("1")))
	side_row.add_child(_make_button("Ambos", _on_side_pressed.bind("both")))
	vbox.add_child(side_row)

	vbox.add_child(_make_label("— POSIÇÃO (formação real, não índice de array) —", 13))
	var grid := GridContainer.new()
	grid.columns = 3
	# Disposição visual real: 1 2 3 / 6 5 4 / 7 8 9 — nunca a ordem 1..9
	# de um array.
	for position in [1, 2, 3, 6, 5, 4, 7, 8, 9]:
		grid.add_child(_make_button(str(position), _on_position_pressed.bind(position)))
	vbox.add_child(grid)
	vbox.add_child(_make_button("Todas as Posições", _on_position_pressed.bind(-1)))

	vbox.add_child(_make_label("— TESTES DINÂMICOS —", 13))
	vbox.add_child(_make_button("Move Test (9 → ... → 3)", _on_move_test_pressed))
	vbox.add_child(_make_button("Death Test (unidade ativa)", _on_death_test_pressed))
	vbox.add_child(_make_button("Reset", _on_reset_pressed))

	vbox.add_child(_make_label("— CALIBRAÇÃO DO CAMPO —", 13))
	vbox.add_child(_make_label("Mostra os centros REAIS medidos das 18 células (nunca a hipótese A/B da geometria afim) — sem Battle Art, só Battlefield + cruzes.", 10))
	vbox.add_child(_make_button("Calibration: Mostrar Centros Reais", _on_calibration_pressed))

	vbox.add_child(_make_label("— A/B/C HARMONIZAÇÃO (FASE 4.1/4.2/4.3) —", 13))
	vbox.add_child(_make_label("B (Fase 4) e C (Fase 4.2, conservadora) — só o PNG muda; mesmo Side/Posição/escala/CELL_CENTER/GROUND_CONTACT, sempre calculados pela produção real.", 10))
	vbox.add_child(_make_button("A — Original", _on_ab_mode_pressed.bind("original")))
	vbox.add_child(_make_button("B — Harmonizado", _on_ab_mode_pressed.bind("harmonized")))
	vbox.add_child(_make_button("C — Harmonizado Conservador", _on_ab_mode_pressed.bind("conservative_c")))
	vbox.add_child(_make_button("A+B Lado a Lado (mesmo Side)", _on_ab_mode_pressed.bind("side_by_side")))
	vbox.add_child(_make_button("A+B+C Lado a Lado (mesmo Side)", _on_ab_mode_pressed.bind("side_by_side_abc")))
	_ab_label = _make_label("", 11)
	vbox.add_child(_ab_label)

	vbox.add_child(_make_label("— STATUS —", 13))
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_status_label)

	_diagnostics_label = Label.new()
	_diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_diagnostics_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	vbox.add_child(_diagnostics_label)

	_update_ab_label()
	return scroll


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callable, CONNECT_DEFERRED)
	return button


## PILOTOS 02/03: troca o card_name ativo (Arqueiro/Altar/Unicórnio) e
## reconstrói o tabuleiro do zero — nunca mistura pilotos diferentes na
## mesma inspeção (cada troca é uma nova seleção "Ambos + Todas as
## Posições", igual ao Reset).
func _on_pilot_pressed(pilot_name: String) -> void:
	_active_pilot_name = pilot_name
	_pilot_label.text = "Piloto ativo: %s" % _active_pilot_name
	_side_mode = "both"
	_position_mode = -1
	_ab_mode = "original"
	_update_ab_label()
	_rebuild_board()


func _on_side_pressed(mode: String) -> void:
	_side_mode = mode
	_rebuild_board()


func _on_position_pressed(position: int) -> void:
	_position_mode = position
	_rebuild_board()


func _on_reset_pressed() -> void:
	_side_mode = "both"
	_position_mode = -1
	_ab_mode = "original"
	_update_ab_label()
	_rebuild_board()


## FASE 4.1 — botões A/Original / B/Harmonizado. Só reaplica o overlay
## de textura (_apply_ab_compare_mode()) sobre o tabuleiro JÁ montado —
## nunca reconstrói do zero (evita perder a seleção de Side/Posição
## atual). No-op visual (mensagem de status) se o piloto ativo não fizer
## parte do experimento da Fase 4.
func _on_ab_mode_pressed(mode: String) -> void:
	var needs_c: bool = mode == "conservative_c" or mode == "side_by_side_abc"
	if needs_c and not AB_HARMONIZED_C_RELATIVE_PATH.has(_active_pilot_name):
		_update_status("Este piloto ('%s') não tem versão C (Harmonização Conservadora, Fase 4.2) — só Ceifadora Espectral, Águia Dourada, Abominação Putrefata e Carvalho Milenar têm C." % _active_pilot_name)
		return
	if not needs_c and not AB_HARMONIZED_RELATIVE_PATH.has(_active_pilot_name):
		_update_status("Este piloto ('%s') não faz parte do experimento de harmonização da Fase 4 — sem versão B disponível." % _active_pilot_name)
		return
	_ab_mode = mode
	_update_ab_label()
	if mode == "side_by_side":
		_rebuild_board_side_by_side()
	elif mode == "side_by_side_abc":
		_rebuild_board_side_by_side_abc()
	else:
		_rebuild_board()


func _update_ab_label() -> void:
	if _ab_label == null:
		return
	var supports_b: bool = AB_HARMONIZED_RELATIVE_PATH.has(_active_pilot_name)
	var supports_c: bool = AB_HARMONIZED_C_RELATIVE_PATH.has(_active_pilot_name)
	var mode_desc: String = {
		"original": "A — ORIGINAL",
		"harmonized": "B — HARMONIZADO",
		"conservative_c": "C — HARMONIZADO CONSERVADOR",
		"side_by_side": "A+B LADO A LADO",
		"side_by_side_abc": "A+B+C LADO A LADO",
	}.get(_ab_mode, _ab_mode)
	_ab_label.text = "Comparação: %s\nPiloto tem B? %s | tem C? %s" % [mode_desc, "SIM" if supports_b else "não", "SIM" if supports_c else "não"]


## Tabuleiro dedicado de comparação lado a lado: MESMO Side, MESMA
## escala (Side 0 = 0.14, ambos) — só a Posição difere (4 vs 6,
## flanqueando a 5), porque duas texturas não podem ocupar o mesmo
## slot ao mesmo tempo. "A" (Posição 4) usa o caminho de produção 100%
## normal (original); "B" (Posição 6) tem sprite.texture trocado pra
## harmonizada depois, exatamente como o modo "harmonized" comum — só
## aplicado numa unidade só, não em todo _unit_diagnostics.
func _rebuild_board_side_by_side() -> void:
	_move_test_running = false
	_teardown_current_view()

	var side: int = 1 if _side_mode == "1" else 0
	var state := CombatState.new()
	var unit_a := CombatUnit.new(_pilot_card(), side, 4)
	var unit_b := CombatUnit.new(_pilot_card(), side, 6)
	state.units = [unit_a, unit_b]
	state.battlefield = _reference_battlefield()

	_unit_diagnostics = {
		unit_a.get_instance_id(): {"side": side, "position": 4},
		unit_b.get_instance_id(): {"side": side, "position": 6},
	}
	_active_unit_id = unit_a.get_instance_id()

	_spawn_view(state)
	_apply_visual_test_overrides()

	var harmonized: Texture2D = _harmonized_cropped_texture_for(_active_pilot_name)
	var sprite_b: TextureRect = _current_view._unit_art_layer.sprite_for(unit_b.get_instance_id())
	if sprite_b != null and harmonized != null:
		sprite_b.texture = harmonized

	_update_status("Lado a lado (Side %d): Posição 4 = A ORIGINAL | Posição 6 = B HARMONIZADO. Mesma escala/lado; só a posição difere (2 sprites não cabem no mesmo slot)." % side)
	_add_diagnostic_overlays()
	_add_ab_side_by_side_labels(side, [[4, "A — ORIGINAL"], [6, "B — HARMONIZADO"]])


## FASE 4.3 — mesmo princípio do lado a lado A/B (mesmo Side/escala, só
## a Posição muda porque 3 texturas não cabem no mesmo slot), agora com
## 3 unidades: Posição 7 = A (original, caminho de produção normal),
## Posição 5 = B (sprite.texture trocado pra harmonizada), Posição 3 =
## C (sprite.texture trocado pra conservadora). Só chamada quando
## AB_HARMONIZED_C_RELATIVE_PATH.has(_active_pilot_name) já foi
## validado em _on_ab_mode_pressed().
func _rebuild_board_side_by_side_abc() -> void:
	_move_test_running = false
	_teardown_current_view()

	var side: int = 1 if _side_mode == "1" else 0
	var state := CombatState.new()
	var unit_a := CombatUnit.new(_pilot_card(), side, 7)
	var unit_b := CombatUnit.new(_pilot_card(), side, 5)
	var unit_c := CombatUnit.new(_pilot_card(), side, 3)
	state.units = [unit_a, unit_b, unit_c]
	state.battlefield = _reference_battlefield()

	_unit_diagnostics = {
		unit_a.get_instance_id(): {"side": side, "position": 7},
		unit_b.get_instance_id(): {"side": side, "position": 5},
		unit_c.get_instance_id(): {"side": side, "position": 3},
	}
	_active_unit_id = unit_a.get_instance_id()

	_spawn_view(state)
	_apply_visual_test_overrides()

	var harmonized_b: Texture2D = _harmonized_cropped_texture_for(_active_pilot_name)
	var harmonized_c: Texture2D = _harmonized_c_cropped_texture_for(_active_pilot_name)
	var sprite_b: TextureRect = _current_view._unit_art_layer.sprite_for(unit_b.get_instance_id())
	var sprite_c: TextureRect = _current_view._unit_art_layer.sprite_for(unit_c.get_instance_id())
	if sprite_b != null and harmonized_b != null:
		sprite_b.texture = harmonized_b
	if sprite_c != null and harmonized_c != null:
		sprite_c.texture = harmonized_c

	_update_status("Lado a lado A+B+C (Side %d): Posição 7 = A ORIGINAL | Posição 5 = B HARMONIZADO | Posição 3 = C CONSERVADOR. Mesmo Side/escala; só a posição difere (3 sprites não cabem no mesmo slot)." % side)
	_add_diagnostic_overlays()
	_add_ab_side_by_side_labels(side, [[7, "A — ORIGINAL"], [5, "B — HARMONIZADO"], [3, "C — CONSERVADOR"]])


func _add_ab_side_by_side_labels(side: int, entries: Array) -> void:
	if _current_view == null:
		return
	for entry: Array in entries:
		var position: int = entry[0]
		var text: String = entry[1]
		var center_frac: Vector2 = ArtGeometry.cell_center_frac(side, position)
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_left = center_frac.x
		label.anchor_right = center_frac.x
		label.anchor_top = center_frac.y
		label.anchor_bottom = center_frac.y
		label.offset_left = -60.0
		label.offset_right = 60.0
		label.offset_top = -90.0
		label.offset_bottom = -70.0
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		_current_view._board_layer.add_child(label)


## Modo CALIBRAÇÃO (seção 11 do pedido): mostra as 18 cruzes nos
## centros REAIS medidos das células (MEASURED_CELL_CENTER_FRAC, ver
## auditoria no topo do arquivo) — NUNCA a geometria afim atual
## (_visual_center_frac()) nem a hipótese de meio passo. De propósito,
## NENHUMA unidade/Battle Art é criada neste modo (seção 8: "não
## posicionar o Arqueiro usando esses dados ainda") — só Battlefield +
## células + as 18 cruzes + rótulos.
func _on_calibration_pressed() -> void:
	_move_test_running = false
	_teardown_current_view()

	var state := CombatState.new()
	state.units = []
	state.battlefield = _reference_battlefield()

	_unit_diagnostics.clear()
	_active_unit_id = -1

	_spawn_view(state)
	_hide_all_cards()
	_show_measured_cell_center_crosses()
	_update_status("Modo CALIBRAÇÃO: 18 cruzes nos centros REAIS medidos (script de visão computacional isolado — ver comentário no topo do arquivo), não a geometria afim atual.")


## Desenha as 18 cruzes + rótulos "S{side} P{position} (REAL)" nos
## pontos de MEASURED_CELL_CENTER_FRAC — mesma camada/técnica visual já
## usada pelos outros overlays de diagnóstico desta ferramenta
## (CombatReplayView._board_layer), puramente debug, nunca parte de
## nenhum asset. Sem distinção de confiança por célula (ver Teste
## Visual 07: aprovação visual humana já cobriu as 18).
func _show_measured_cell_center_crosses() -> void:
	if _current_view == null:
		return
	for side: int in ArtGeometry.MEASURED_CELL_CENTER_FRAC.keys():
		for position: int in ArtGeometry.MEASURED_CELL_CENTER_FRAC[side].keys():
			var center_frac: Vector2 = ArtGeometry.MEASURED_CELL_CENTER_FRAC[side][position]
			_current_view._board_layer.add_child(_make_cross_marker(center_frac))

			var label := Label.new()
			label.text = "S%d P%d\n(REAL)" % [side, position]
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
			label.add_theme_constant_override("outline_size", 4)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.anchor_left = center_frac.x
			label.anchor_right = center_frac.x
			label.anchor_top = center_frac.y
			label.anchor_bottom = center_frac.y
			label.offset_left = -40.0
			label.offset_right = 40.0
			label.offset_top = -50.0
			label.offset_bottom = -30.0
			label.grow_horizontal = Control.GROW_DIRECTION_BOTH
			label.grow_vertical = Control.GROW_DIRECTION_BOTH
			_current_view._board_layer.add_child(label)


func _sides_for_mode() -> Array:
	match _side_mode:
		"0":
			return [0]
		"1":
			return [1]
		_:
			return [0, 1]


## Constrói um CombatState novo (nunca reaproveita o anterior) com o
## piloto nas posições/lados selecionados, e substitui a CombatReplayView
## atual por uma nova — a MESMA cena/lógica de produção, só re-
## instanciada com um tabuleiro diferente a cada seleção.
func _rebuild_board() -> void:
	_move_test_running = false
	_teardown_current_view()

	var state := CombatState.new()
	var sides: Array = _sides_for_mode()
	_unit_diagnostics.clear()
	var units: Array[CombatUnit] = []

	if _position_mode == -1:
		for side in sides:
			for position in range(1, 10):
				var unit := CombatUnit.new(_pilot_card(), side, position)
				units.append(unit)
				_unit_diagnostics[unit.get_instance_id()] = {"side": side, "position": position}
	else:
		for side in sides:
			var unit := CombatUnit.new(_pilot_card(), side, _position_mode)
			units.append(unit)
			_unit_diagnostics[unit.get_instance_id()] = {"side": side, "position": _position_mode}

	state.units = units
	state.battlefield = _reference_battlefield()

	_spawn_view(state)
	_active_unit_id = units[0].get_instance_id() if not units.is_empty() else -1

	_apply_visual_test_overrides()
	_apply_ab_compare_mode()
	_update_status("Configuração aplicada.")
	_add_diagnostic_overlays()


func _teardown_current_view() -> void:
	if _current_view != null and is_instance_valid(_current_view):
		_battlefield_area.remove_child(_current_view)
		_current_view.queue_free()
	_current_view = null
	_current_state = null
	_current_collector = null


func _spawn_view(state: CombatState) -> void:
	var collector = ReplayCollectorScript.new()
	collector.attach(state.event_bus)
	collector.snapshot_initial_board(state)

	var view = ReplayViewScript.new()
	view.combat_state = state
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.replay_collector = collector
	_battlefield_area.add_child(view)

	_current_view = view
	_current_state = state
	_current_collector = collector


func _pilot_card() -> CardResource:
	var definition: Dictionary = PILOT_DEFINITIONS[_active_pilot_name]
	var card := CardResource.new()
	card.card_name = _active_pilot_name
	card.card_class = definition["card_class"]
	card.faction = definition["faction"]
	card.rarity = "Comum"
	card.tier = 1
	card.atk = 50
	card.hp = 50
	card.esc = 10
	return card


func _named_card(name_value: String) -> CardResource:
	var card: CardResource = _pilot_card()
	card.card_name = name_value
	return card


## Mesmo Battlefield já usado pelas suítes de teste reais (ex:
## test_combat_replay_view.gd) — "Campo Aberto", a mesma imagem de
## referência usada durante toda esta auditoria/implementação. Nunca
## inventa um Battlefield próprio; cai no primeiro disponível só se o
## catálogo mudar de nome no futuro.
func _reference_battlefield() -> BattlefieldResource:
	for bf: BattlefieldResource in GameDatabase.battlefields:
		if bf.battlefield_name == "Campo Aberto":
			return bf
	return GameDatabase.battlefields[0] if not GameDatabase.battlefields.is_empty() else null


func _update_status(extra: String = "") -> void:
	var mode_desc: String = "Todas" if _position_mode == -1 else str(_position_mode)
	var flags_desc: String = "[Sem cartas (debug): %s | Geometria de PRODUÇÃO (ArtGeometry): CELL_CENTER + FOOT_CENTER + escala fixa (Side0=%.2f Side1=%.2f) — sempre ativa, não é mais um override desta ferramenta]" % [
		"ON" if HIDE_CARDS_FOR_VISUAL_TEST else "off",
		ArtGeometry.STANDARD_SCALE_FACTOR_SIDE_0, ArtGeometry.STANDARD_SCALE_FACTOR_SIDE_1
	]
	_status_label.text = "Side: %s | Posição: %s | Unidades no tabuleiro: %d\n%s\n%s" % [_side_mode, mode_desc, _unit_diagnostics.size(), flags_desc, extra]
	_update_diagnostics_label()


func _scale_factor_for_side(side: int) -> float:
	return ArtGeometry.scale_factor_for_side(side)


## TESTE VISUAL 08: esta função só REPASSA ArtGeometry.cell_center_frac()
## — única fonte de verdade agora que produção também consome a mesma
## tabela (ArtGeometry.MEASURED_CELL_CENTER_FRAC). Mantida como função
## nomeada só por clareza/histórico de chamadas já existentes nesta
## ferramenta (overlays de debug, painel de diagnóstico), nunca por ter
## lógica própria.
func _true_cell_center_frac(side: int, position: int) -> Vector2:
	return ArtGeometry.cell_center_frac(side, position)


## Teste Visual 02 — REGRA 1: esconde toda BattleCardView já criada por
## CombatReplayView (view.visible = false, nunca reposiciona nada, nunca
## remove nada da árvore) — nenhuma alteração em CombatReplayView/
## BattleCardView, só leitura/escrita de uma propriedade de instância já
## pública de fato (_position_widgets, mesmo padrão de acesso já usado
## por esta ferramenta pra _board_layer/_visual_center_frac()).
func _hide_all_cards() -> void:
	if _current_view == null:
		return
	for widgets: Dictionary in _current_view._position_widgets.values():
		var card_view = widgets.get("view")
		if card_view != null:
			card_view.visible = false


## TESTE VISUAL 08: a função que existia aqui
## (_apply_foot_center_alignment_override(), Teste Visual 05) foi
## REMOVIDA — a fórmula que ela aplicava (CELL_CENTER + FOOT_CENTER +
## escala fixa por lado) agora é a colocação REAL de produção
## (BattleUnitArtLayer.register_or_update() -> BattleUnitArtGeometry.
## placement_for(), chamada de verdade por CombatReplayView), então o
## sprite que _spawn_view()/_rebuild_board() já criam através da
## CombatReplayView real já chega posicionado corretamente, sem
## nenhum ajuste desta ferramenta por cima.
##
## Ponto único que aplica o único flag restante desta ferramenta (Teste
## Visual 02/08: esconder cartas SEM Battle Art, como Fix-1/Fix-2 do
## Move Test — a carta do próprio piloto já é escondida sozinha pela
## produção, ver combat_replay_view.gd _refresh_position_widget()) —
## chamado depois de toda operação que faz CombatReplayView reprocessar
## widgets, nunca uma vez só (mesmo padrão de sempre).
func _apply_visual_test_overrides() -> void:
	if HIDE_CARDS_FOR_VISUAL_TEST:
		_hide_all_cards()


func _update_diagnostics_label() -> void:
	if _active_unit_id == -1 or not _unit_diagnostics.has(_active_unit_id) or _current_view == null:
		_diagnostics_label.text = "UNIT_ID ativo (Move/Death Test): <nenhum>"
		return
	var info: Dictionary = _unit_diagnostics[_active_unit_id]
	var depth_index: int = _current_view._depth_index_for(info["side"], info["position"])
	var foot_center: Vector2 = _true_cell_center_frac(info["side"], info["position"])
	_diagnostics_label.text = "ATIVO (Move/Death Test):\nSIDE: %d\nPOSITION: %d\nDEPTH REGION: %d\nUNIT_ID: %d\nFOOT CENTER (fração): (%.4f, %.4f)\nESCALA DO LADO: %.2f" % [
		info["side"], info["position"], depth_index, _active_unit_id, foot_center.x, foot_center.y, _scale_factor_for_side(info["side"])
	]


## Etiquetas de diagnóstico ("S{side} P{position} / FOOT CENTER") +
## marcador em cruz no CELL CENTER (_true_cell_center_frac(), hoje
## "_visual_center_frac()" sem correção — ver achado do Teste 05) +
## marcadores de ponto no pé esquerdo/direito/FOOT CENTER do próprio
## personagem (Teste Visual 05, requisito obrigatório da seção 10) —
## sempre FORA da área do personagem (a cruz/etiqueta) ou sobre ela (os
## 3 pontos de pé, propositalmente, pra comparar contra a cruz).
## Adicionados como filhos de CombatReplayView._board_layer, a MESMA
## camada onde BattleCardView e os rótulos de lado já vivem em
## produção. Puramente DEBUG desta ferramenta, nunca incorporado a
## nenhum asset.
func _add_diagnostic_overlays() -> void:
	if _current_view == null:
		return
	for unit_id: int in _unit_diagnostics.keys():
		var info: Dictionary = _unit_diagnostics[unit_id]
		var foot_center_frac: Vector2 = _true_cell_center_frac(info["side"], info["position"])

		var label := Label.new()
		label.text = "S%d P%d\nFOOT CENTER" % [info["side"], info["position"]]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_left = foot_center_frac.x
		label.anchor_right = foot_center_frac.x
		label.anchor_top = foot_center_frac.y
		label.anchor_bottom = foot_center_frac.y
		label.offset_left = -34.0
		label.offset_right = 34.0
		label.offset_top = -58.0
		label.offset_bottom = -30.0
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		_current_view._board_layer.add_child(label)

		_current_view._board_layer.add_child(_make_cross_marker(foot_center_frac))

		# Teste Visual 05/08 — debug visual do(s) ponto(s) de contato:
		# marcador em BRANCO no ground contact real do personagem
		# (qualquer piloto), calculado a partir do anchor ATUAL do sprite
		# — já posicionado pela PRODUÇÃO de verdade (BattleUnitArtLayer/
		# BattleUnitArtGeometry, nenhum override desta ferramenta) —
		# nunca uma nova geometria, só a leitura de
		# ArtGeometry.foot_center_frac_for() (única fonte de verdade)
		# reaplicada sobre o retângulo já calculado. Esse ponto deve
		# coincidir exatamente com a cruz magenta acima — essa
		# coincidência É o teste visual.
		#
		# PILOTOS 02/03: os marcadores CIANO/LARANJA (pé esquerdo/pé
		# direito, LEFT_FOOT_FRAC_IN_CONTENT/RIGHT_FOOT_FRAC_IN_CONTENT)
		# são medidas ESPECÍFICAS do Arqueiro Imperial (Teste Visual 05,
		# midpoint entre 2 pés) — não fazem sentido pra uma estrutura sem
		# pernas (Altar) nem pra um quadrúpede com 3 pontos de apoio
		# (Unicórnio), então só são desenhados quando o piloto ativo é o
		# Arqueiro. Generalizar esses dois marcadores exigiria uma tabela
		# por piloto só pra depuração, sem nenhum ganho de cobertura real
		# (o marcador BRANCO já prova a coincidência nos 3 pilotos) — não
		# fiz isso por não ser necessário, não por limitação técnica.
		var sprite: TextureRect = _current_view._unit_art_layer.sprite_for(unit_id)
		if sprite != null:
			var w: float = sprite.anchor_right - sprite.anchor_left
			var h: float = sprite.anchor_bottom - sprite.anchor_top
			var foot_center_frac_in_content: Vector2 = ArtGeometry.foot_center_frac_for(_active_pilot_name)
			var foot_center_screen := Vector2(sprite.anchor_left + foot_center_frac_in_content.x * w, sprite.anchor_top + foot_center_frac_in_content.y * h)
			_current_view._board_layer.add_child(_make_dot_marker(foot_center_screen, Color(1.0, 1.0, 1.0, 0.95)))
			if _active_pilot_name == PILOT_NAME:
				var left_foot_screen := Vector2(sprite.anchor_left + LEFT_FOOT_FRAC_IN_CONTENT.x * w, sprite.anchor_top + LEFT_FOOT_FRAC_IN_CONTENT.y * h)
				var right_foot_screen := Vector2(sprite.anchor_left + RIGHT_FOOT_FRAC_IN_CONTENT.x * w, sprite.anchor_top + RIGHT_FOOT_FRAC_IN_CONTENT.y * h)
				_current_view._board_layer.add_child(_make_dot_marker(left_foot_screen, Color(0.1, 0.9, 1.0, 0.95)))
				_current_view._board_layer.add_child(_make_dot_marker(right_foot_screen, Color(1.0, 0.55, 0.1, 0.95)))


## Marcador de debug: um pequeno ponto quadrado colorido numa fração
## exata da tela — usado pelos 3 marcadores de pé do Teste Visual 05
## (esquerdo/direito/centro). Puramente visual/diagnóstico, nunca parte
## do Battle Art.
func _make_dot_marker(frac: Vector2, color: Color) -> Control:
	var dot := ColorRect.new()
	dot.name = "FootMarkerDot"
	dot.color = color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.anchor_left = frac.x
	dot.anchor_right = frac.x
	dot.anchor_top = frac.y
	dot.anchor_bottom = frac.y
	dot.offset_left = -5.0
	dot.offset_right = 5.0
	dot.offset_top = -5.0
	dot.offset_bottom = 5.0
	return dot


## Marcador de debug OBRIGATÓRIO do Teste Visual 04 — uma pequena cruz
## magenta exatamente em "center_frac" (CELL CENTER / FOOT CENTER),
## puramente visual/diagnóstico, nunca parte do Battle Art. Duas
## ColorRect finas (uma horizontal, uma vertical) formando um "+" —
## mais simples que um Control com _draw() customizado pra uma
## ferramenta temporária.
func _make_cross_marker(center_frac: Vector2, color: Color = Color(1.0, 0.0, 1.0, 0.95)) -> Control:
	var marker := Control.new()
	marker.name = "CellCenterMarker"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.anchor_left = center_frac.x
	marker.anchor_right = center_frac.x
	marker.anchor_top = center_frac.y
	marker.anchor_bottom = center_frac.y
	marker.offset_left = -10.0
	marker.offset_right = 10.0
	marker.offset_top = -10.0
	marker.offset_bottom = 10.0

	var horizontal_bar := ColorRect.new()
	horizontal_bar.color = color
	horizontal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	horizontal_bar.offset_top = 8.5
	horizontal_bar.offset_bottom = -8.5
	marker.add_child(horizontal_bar)

	var vertical_bar := ColorRect.new()
	vertical_bar.color = color
	vertical_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	vertical_bar.offset_left = 8.5
	vertical_bar.offset_right = -8.5
	marker.add_child(vertical_bar)

	return marker


## Cenário DEDICADO (nunca reaproveita a visualização estática atual):
## 1 Mover na Posição 9 + 2 bloqueadores fixos nas Posições 1/2 — mesma
## técnica já validada em test_battle_unit_art_pilot.gd — pra garantir
## um percurso 9 -> 8 -> ... -> 3 sempre reprodutível. Aplica cada
## UNIT_MOVED real (CombatEngine._movement_phase(), nunca uma segunda
## lógica de movimento) com uma pausa real entre passos, pra dar tempo
## de observar visualmente.
func _on_move_test_pressed() -> void:
	if _move_test_running:
		return
	_move_test_running = true

	var side: int = 1 if _side_mode == "1" else 0

	_teardown_current_view()

	var state := CombatState.new()
	var fix_1 := CombatUnit.new(_named_card("Fix-1"), side, 1)
	var fix_2 := CombatUnit.new(_named_card("Fix-2"), side, 2)
	var mover := CombatUnit.new(_pilot_card(), side, 9)
	state.units = [fix_1, fix_2, mover]
	state.battlefield = _reference_battlefield()

	_unit_diagnostics = {mover.get_instance_id(): {"side": side, "position": 9}}
	_active_unit_id = mover.get_instance_id()

	_spawn_view(state)
	_apply_visual_test_overrides()
	_apply_ab_compare_mode()
	_update_status("Move Test iniciado (Side %d): 9 -> 8 -> 7 -> 6 -> 5 -> 4 -> 3." % side)
	_add_diagnostic_overlays()

	CombatEngine._movement_phase(state)
	var move_events: Array = _current_collector.replay_events.filter(func(e): return e["kind"] == "move")

	for event: Dictionary in move_events:
		if not is_instance_valid(_current_view):
			break
		_current_view._apply_replay_event(event)
		_unit_diagnostics[mover.get_instance_id()] = {"side": side, "position": event["to_position"]}
		_apply_visual_test_overrides()
		_apply_ab_compare_mode()
		_teardown_diagnostic_overlays_only()
		_add_diagnostic_overlays()
		_update_status("Move Test em andamento: avançou para a Posição %d." % event["to_position"])
		await get_tree().create_timer(0.6).timeout

	if is_instance_valid(self):
		_update_status("Move Test concluído (parou na Posição %d)." % mover.position)
	_move_test_running = false


## Remove só os overlays de diagnóstico já adicionados (etiquetas "S P"
## + marcadores CellCenterMarker/FootMarkerDot — filhas extras de
## _board_layer além dos widgets de BattleCardView/BattleUnitArtLayer,
## que continuam intocados) — usado só pelo Move Test/Death Test, pra
## reposicionar o overlay a cada passo sem recriar a CombatReplayView
## inteira.
func _teardown_diagnostic_overlays_only() -> void:
	if _current_view == null:
		return
	for child in _current_view._board_layer.get_children():
		var is_diagnostic_label: bool = child is Label and (child as Label).text.begins_with("S")
		var is_marker: bool = child.name == "CellCenterMarker" or child.name == "FootMarkerDot"
		if is_diagnostic_label or is_marker:
			_current_view._board_layer.remove_child(child)
			child.queue_free()


## Publica UNIT_DIED pra unidade ATIVA (_active_unit_id), com o MESMO
## formato de evento que CombatEngine._death_resolution_phase() publica
## de verdade — nunca uma segunda lógica de morte. Aplica o evento via
## CombatReplayView._apply_replay_event(), a mesma função real de
## produção.
func _on_death_test_pressed() -> void:
	if _current_state == null or _active_unit_id == -1:
		_update_status("Death Test: nenhuma unidade ativa (aplique uma configuração primeiro).")
		return

	var victim: CombatUnit = null
	for unit: CombatUnit in _current_state.units:
		if unit.get_instance_id() == _active_unit_id and unit.is_alive:
			victim = unit
			break
	if victim == null:
		_update_status("Death Test: unidade ativa não encontrada ou já morta.")
		return

	victim.is_alive = false
	victim.current_hp = 0
	var death_ctx := CombatContext.new()
	death_ctx.state = _current_state
	death_ctx.turn = _current_state.turn
	death_ctx.attacker = victim
	death_ctx.side = victim.side
	death_ctx.position = victim.position
	_current_state.event_bus.publish(CombatEventType.Type.UNIT_DIED, death_ctx)
	_current_view._apply_replay_event(_current_collector.replay_events[_current_collector.replay_events.size() - 1])

	_unit_diagnostics.erase(_active_unit_id)
	_apply_visual_test_overrides()
	_teardown_diagnostic_overlays_only()
	_add_diagnostic_overlays()
	_update_status("Death Test aplicado: unit_id %d (Side %d, Posição %d) foi removido." % [_active_unit_id, victim.side, victim.position])
