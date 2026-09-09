class_name BattleUnitArtGeometry
extends RefCounted
## BattleUnitArtGeometry (Battle Art MVP — Piloto, 2026-09-02; geometria
## de produção substituída no Teste Visual 08, 2026-09-02)
##
## Única fonte de verdade da colocação REAL de Battle Art em produção:
## CELL_CENTER[side][position] (centro visual calibrado da célula) +
## FOOT_CENTER (ponto do conteúdo do asset que deve coincidir com esse
## centro) + escala FIXA por lado. NÃO recalcula CombatBoard/ADVANCE_ORDER
## (posição LÓGICA continua vindo só de lá) — só resolve o ponto/tamanho
## VISUAL de onde o Battle Art aparece.
##
## TESTE VISUAL 08 (2026-09-02) — antes desta tarefa, esta função usava
## uma caixa-alvo por Região de profundidade (DEPTH_REGION_SCALE, escala
## VARIÁVEL conforme a posição estivesse mais perto/longe da câmera,
## portada do protótipo isolado ART-009) combinada com o centro de célula
## NÃO calibrado (CombatReplayView._visual_center_frac(), a grade afim
## ORIGIN+r*E1+c*E2 — provada imprecisa em até 157px nas Posições 3/4/9
## do Lado 0 pela investigação de calibração desta mesma sessão). Essa
## combinação nunca foi validada visualmente pelo usuário — só existia
## na produção "de fábrica", nunca inspecionada. O que FOI validado
## visualmente (Teste Visual 06/07) foi uma fórmula diferente, aplicada
## até agora só como OVERRIDE de depuração dentro de
## battle_art_pilot_inspector.gd (nunca antes portada pra cá). Decisão
## explícita do usuário nesta tarefa: a fórmula aprovada passa a ser a
## ÚNICA colocação de produção — DEPTH_REGION_SCALE/region_box_px()/
## fit_scale()/BASE_OFFSET_FRAC saem do caminho de produção (removidos
## deste arquivo; o histórico completo do protótipo ART-009 continua
## preservado, sem duplicação, em
## scenes/prototype/battle_unit_art_prototype.gd, que já mantinha sua
## própria cópia independente dessas mesmas constantes — nenhum valor
## histórico é perdido).
##
## CELL_CENTER (MEASURED_CELL_CENTER_FRAC): medido por script Python
## isolado (visão computacional — limiar HSV + componentes conectados +
## atribuição ótima Hungarian + refinamento de espessura de borda) sobre
## o PNG real do Battlefield (res://assets/art/battlefields/
## campo_aberto.png — mesma posição de pixel confirmada nos 10 assets de
## Battlefield, ver combat_replay_view.gd), aprovado visualmente pelo
## usuário após os Testes Visuais 06 e 07. Valores copiados aqui SEM
## nenhum recálculo — ver o histórico completo (metodologia, achados,
## tabela de erros) preservado nos comentários de
## battle_art_pilot_inspector.gd. NUNCA usar
## CombatReplayView._visual_center_frac() nem "+0,5*(E1+E2)" pra Battle
## Art de produção — as duas hipóteses foram explicitamente descartadas.
const MEASURED_CELL_CENTER_FRAC: Dictionary = {
	0: {
		1: Vector2(0.3215, 0.5765), 2: Vector2(0.4172, 0.6044), 3: Vector2(0.5224, 0.6346),
		6: Vector2(0.2550, 0.6562), 5: Vector2(0.3577, 0.6936), 4: Vector2(0.4699, 0.7336),
		7: Vector2(0.1811, 0.7548), 8: Vector2(0.2893, 0.7992), 9: Vector2(0.4090, 0.8475),
	},
	1: {
		1: Vector2(0.4716, 0.4060), 2: Vector2(0.5542, 0.4247), 3: Vector2(0.6431, 0.4431),
		6: Vector2(0.5151, 0.3534), 5: Vector2(0.5931, 0.3715), 4: Vector2(0.6785, 0.3842),
		7: Vector2(0.5542, 0.3096), 8: Vector2(0.6287, 0.3235), 9: Vector2(0.7056, 0.3369),
	},
}

## Ponto de CONTATO COM O CHÃO de cada personagem-piloto (fração 0..1 do
## retângulo alfa recortado — o mesmo espaço de BattleUnitArtCatalog.
## content_alpha_rect_for()), medido diretamente no PNG fonte. Específico
## de cada card_name — nunca serve de premissa pra outro personagem sem
## nova medição. Um card_name sem entrada aqui nunca chega a chamar
## placement_for() na prática (register_or_update() já retorna cedo
## quando has_art_for() é falso).
##
## O nome do campo/dicionário ("FOOT_CENTER") data do piloto humanoide
## original — mantido aqui por continuidade (ver "GENERALIZAÇÃO" abaixo).
## O que o valor representa, em qualquer caso, é sempre o mesmo conceito
## abstrato: o ponto do CONTEÚDO renderizado que deve ser ancorado
## exatamente sobre CELL_CENTER — nunca assume anatomia humana no código
## (foot_center_frac_for() só faz um lookup por Nome), só na forma como
## cada valor foi originalmente MEDIDO:
##
## - "Arqueiro Imperial" (Teste Visual 05): ponto médio real entre os
##   dois pés (dois pontos de contato de bota, medidos por perfil de
##   alfa por coluna no PNG fonte), nunca a base do bounding box inteiro
##   (que coincidia com só UM pé, por causa da pose assimétrica com arco/
##   aljava puxando o bbox).
##
## - "Altar da Reanimação" (PILOTO 02 — Máquina de Guerra dos Mortos-
##   Vivos, 2026-09-02): estrutura estática sem pernas/rodas — um único
##   "pé" equivalente à base inteira do monumento. Medido por script
##   Python isolado (apagado ao final, ver relatório desta tarefa):
##   varredura coluna-a-coluna do pixel de alfa>128 mais baixo em toda a
##   imagem (1536x1024) — a base plana da escadaria frontal, sem halo/
##   brilho abaixo dela (o "soft" alpha>5 e o "hard" alpha>128 bateram no
##   mesmo Y, a 1px de diferença — nenhuma contaminação de glow). O
##   Ground Contact X é o CENTRO da faixa de colunas cuja base fica a
##   <=8px desse Y mínimo global (a "linha de solo" real, x=[651,845]px
##   de um canvas de 1536px) — não o centro do bounding box alfa inteiro
##   (que difere em só 12.5px, ~0.8% da largura, por causa dos elementos
##   assimétricos no topo — cabeça de serpente à esquerda vs foice à
##   direita — mas o centro da BASE, onde o objeto realmente toca o
##   chão, é a medida fisicamente correta). Verificado visualmente
##   (composição sobre fundo verde): o ponto cai exatamente na base da
##   escadaria central, nunca flutuando nem afundado.
##
## - "Unicórnio Ancestral" (PILOTO 03 — Natureza, 2026-09-02): quadrúpede
##   em pose de empinar — na imagem-fonte (1208x1302), 3 dos 4 cascos
##   tocam o chão (1 perna dianteira está de fato erguida no ar, longe da
##   faixa inferior da imagem), não 2 como no Arqueiro nem 4 como um
##   quadrúpede parado. Detectado por script Python isolado: máscara de
##   alfa>128 na faixa inferior (15% de baixo da imagem) + componentes
##   conectados (scipy.ndimage.label, mesma técnica já usada na
##   calibração das 18 células do Battlefield) — 3 blobs de área
##   relevante (>3000px), cada um com seu próprio ponto de "casco mais
##   baixo" (posição do pixel de maior Y dentro do próprio blob). GROUND
##   CONTACT = CENTROIDE desses 3 pontos (generalização direta do
##   princípio já usado no Arqueiro — "média dos pontos de contato reais
##   com o chão", agora para 3 pontos em vez de 2, nunca 4 porque só 3
##   estão realmente perto do chão na pose renderizada). Verificado
##   visualmente: os 3 pontos batem exatamente nas pontas dos 3 cascos
##   apoiados/com brilho de contato; o centroide cai dentro da área de
##   sustentação real do animal (sob a barriga, entre as patas), nunca
##   fora dela.
##
## GENERALIZAÇÃO AVALIADA (pedido explícito da tarefa dos Pilotos 02/03,
## "não alterar só por estética"): os Pilotos 02/03 provam que a
## ABSTRAÇÃO já comportava um objeto sem pernas e um quadrúpede com
## apoio assimétrico sem NENHUMA mudança de código — só medição + uma
## entrada nova no dicionário. O nome "FOOT_CENTER" ficou estritamente
## mais estreito que o conceito real ("ground contact point", nunca
## necessariamente um pé), mas trocar
## CARD_NAME_TO_FOOT_CENTER_FRAC/foot_center_frac_for() por um nome tipo
## GROUND_CONTACT agora seria só cosmético — não corrige nenhuma
## limitação real encontrada nestes dois pilotos, então NÃO foi feito
## naquela tarefa (recomendação registrada para decisão futura, nunca
## aplicada por conta própria).
##
## FASE 2 — SEGUNDA BATERIA (2026-09-02): mais 5 entradas, cada uma
## medida por um método específico ao asset (nunca "olhando" uma
## coordenada — ver relatório desta tarefa para o script/prints de cada
## medição):
##
## - "Ent Jovem" (treant bípede, Natureza): postura assimétrica igual
##   ao Arqueiro (uma perna-raiz à frente, outra atrás) — mesmo método
##   de midpoint entre 2 pontos de contato, aqui 2 massas de raiz em vez
##   de 2 botas. Detectado por componentes conectados (scipy.ndimage,
##   faixa inferior 15%) — 2 blobs claros, um por perna.
##
## - "Balista Imperial" (veículo com rodas, Império — PRIMEIRO veículo
##   integrado): diferente do Altar (base única sólida), aqui várias
##   rodas existem mas o chassi de madeira as conecta em silhueta
##   única — componentes conectados não separam rodas individuais. Só
##   as 2 rodas mais baixas/mais próximas da câmera ficam claramente no
##   nível do chão no "hero shot" (as demais, mais distantes, ficam mais
##   altas no plano da imagem por perspectiva — mesma limitação de
##   retrato único já documentada para os 40 assets). GROUND CONTACT =
##   centroide dos 2 picos locais (perfil coluna-a-coluna de alfa>128
##   dentro da região das 2 rodas mais baixas) — generalização do
##   princípio de "média dos pontos de contato reais", nunca as rodas
##   mais distantes/ambíguas.
##
## - "Carvalho Ancião" (Natureza, estrutura com múltiplas raízes):
##   2 massas de raiz claramente separadas (uma de cada lado), mesmo
##   método de midpoint do Ent Jovem/Wall of Bones.
##
## - "Muralha de Ossos" (Mortos-Vivos, bípede/golem robusto): 2 pés
##   largos claramente separados, midpoint entre os 2 blobs.
##
## - "Capitão Imperial" (Império, bípede convencional): postura
##   assimétrica (1 bota à frente/baixo, 1 atrás/alta) — o blob da bota
##   de trás só aparece numa faixa mais larga (75% da altura, não 85%
##   como os demais, porque essa bota fica visualmente mais alta que a
##   da frente); ambos os blobs medidos pelo próprio ponto mais baixo
##   (nunca uma faixa uniforme forçada), mesma técnica exata do Arqueiro
##   Imperial original.
## FASE 3 (2026-09-03) — migração controlada do lote seguinte, mesma
## arquitetura, mesmo método (medição por script Python isolado, apagado
## ao final — alfa>128, perfil coluna-a-coluna do pixel mais baixo, e
## detecção de picos locais nesse perfil pra achar os pontos de contato
## reais, generalização direta da técnica já usada no Arqueiro/Capitão —
## nunca "olhando" uma coordenada). Nenhuma linha de código mudou pra
## suportar este lote, só entradas novas aqui e em
## BattleUnitArtCatalog.CARD_NAME_TO_PATH:
##
## BÍPEDES CONVENCIONAIS (Império — Centurião, Campeão, Besteiro,
## Engenheiro, Guardião, Infante, Legionário, Marechal, Escudeiro,
## Evocador; Morto-Vivo — Esqueleto Guerreiro, Ceifador Cadavérico;
## Natureza — nenhum neste grupo): mesmo método do Arqueiro/Capitão —
## midpoint entre os 2 pontos de contato de bota reais (perfil de alfa
## por coluna, pico local mais baixo de cada perna), nunca a base do
## bbox inteiro. "Marechal Imperial" tem uma capa longa que conecta as
## duas botas num único blob de componentes conectados — resolvido
## medindo o perfil coluna-a-coluna (que não depende de blob), não a
## técnica de blob, e confirmado por inspeção visual direta (crop 2x da
## base) que as duas botas são objetos fisicamente separados.
##
## "Abominação Putrefata" (Morto-Vivo): 2 pernas/patas grossas
## claramente separadas na base (uma mais recuada/alta, outra mais
## avançada/baixa) — mesmo método de midpoint entre 2 massas de
## contato, técnica de componentes conectados (a mesma do Unicórnio/Ent
## Jovem), não perfil de coluna (aqui as 2 massas nunca se conectam).
##
## "Carvalho Milenar" (Natureza): mesma estrutura do Carvalho Ancião —
## 2 massas de raiz claramente separadas, midpoint entre as 2 (técnica
## de componentes conectados).
##
## ROBE LONGO / BASE ÚNICA (Morto-Vivo — Sacerdote Profano, Lich Rei,
## Liche Iniciado, Cultista da Putrefação): túnica/manto até o chão sem
## nenhuma bota visível — mesmo método já usado no Altar da Reanimação
## (PILOTO 02): ponto mais baixo real da silhueta (alfa>128) + CENTRO X
## da faixa de colunas cuja base fica a <=8px desse ponto mais baixo
## (a "linha de solo" real da barra da veste, nunca o centro do bbox
## inteiro, que none desses 4 casos coincide com esse ponto — a barra é
## sempre assimétrica por causa da pose/drapeado).
##
## CASOS ETÉREOS (marcados VISUAL CALIBRATION — pedido explícito desta
## tarefa: nenhum destes tem contato físico com o chão realmente
## fotografado no PNG; o valor abaixo é a proposta mais coerente,
## registrada com o método usado, mas requer validação visual direta no
## Battlefield antes de ser considerada definitiva, igual a qualquer
## outra entrada — nenhum tratamento especial de código foi criado só
## por causa disso):
## - "Ceifadora Espectral": figura totalmente etérea, sem pernas/pés —
##   mesmo método de base única do Altar (ponto mais baixo da névoa/
##   vestido + centro da faixa a <=8px dele), aplicado à ponta inferior
##   do vestido dissolvendo em névoa.
## - "Banshee": mesmo caso — totalmente etérea, sem pernas, dissolvendo
##   em névoa numa faixa larga e irregular; método de base única
##   (ponto mais baixo + centro da faixa a <=8px dele).
## - "Arqueira Espectral": CONTATO PARCIALMENTE AMBÍGUO (não totalmente
##   etérea como as duas acima) — as duas botas pontudas SÃO visíveis
##   (confirmado por crop 2x da base), mas parcialmente envoltas em
##   névoa; método de midpoint entre 2 pontos de contato (mesmo dos
##   bípedes convencionais), aplicado às pontas das 2 botas.
##
## "Águia Dourada" (Natureza): NÃO É uma pose parada — é uma águia em
## voo/mergulho de ataque, garras estendidas à frente/abaixo, sem pouso
## nem chão visível na imagem-fonte. Sem contato físico real por
## definição (a criatura está voando). Marcado também como VISUAL
## CALIBRATION: ponto proposto = midpoint entre as 2 garras mais baixas/
## mais próximas da câmera (mesmo princípio de "média dos pontos de
## contato reais" já usado na Balista Imperial pra rodas mais próximas),
## como âncora de posicionamento na célula — não representa um "pouso",
## requer validação visual direta.
const CARD_NAME_TO_FOOT_CENTER_FRAC: Dictionary = {
	"Arqueiro Imperial": Vector2(0.380, 0.930),
	"Altar da Reanimação": Vector2(0.4864, 0.9960),
	"Unicórnio Ancestral": Vector2(0.5254, 0.9659),
	"Ent Jovem": Vector2(0.4370, 0.9772),
	"Balista Imperial": Vector2(0.5398, 0.9755),
	"Carvalho Ancião": Vector2(0.5733, 0.9792),
	"Muralha de Ossos": Vector2(0.4912, 0.9769),
	"Capitão Imperial": Vector2(0.4660, 0.9237),

	"Centurião Imperial": Vector2(0.5597, 0.9398),
	"Campeão Imperial": Vector2(0.5059, 0.9912),
	"Besteiro Imperial": Vector2(0.4043, 0.9506),
	"Engenheiro Imperial": Vector2(0.5184, 0.9409),
	"Guardião Imperial": Vector2(0.4620, 0.9374),
	"Infante Imperial": Vector2(0.4747, 0.9435),
	"Legionário Imperial": Vector2(0.4985, 0.9536),
	"Marechal Imperial": Vector2(0.4603, 0.9710),
	"Escudeiro Imperial": Vector2(0.4770, 0.9678),
	"Evocador Imperial": Vector2(0.3965, 0.9705),
	"Esqueleto Guerreiro": Vector2(0.5551, 0.9812),
	"Abominação Putrefata": Vector2(0.5203, 0.9704),
	"Ceifador Cadavérico": Vector2(0.5207, 0.9799),
	"Carvalho Milenar": Vector2(0.4475, 0.9725),
	"Sacerdote Profano": Vector2(0.4230, 0.9987),
	"Lich Rei": Vector2(0.6531, 0.9987),
	"Liche Iniciado": Vector2(0.7346, 0.9974),
	"Cultista da Putrefação": Vector2(0.7229, 0.9974),

	## VISUAL CALIBRATION — ver nota acima, validar no Battlefield.
	"Ceifadora Espectral": Vector2(0.6295, 0.9928),
	"Banshee": Vector2(0.4568, 0.9961),
	"Arqueira Espectral": Vector2(0.5552, 0.9745),
	"Águia Dourada": Vector2(0.2717, 0.9897),

	## FASE 5 (2026-09-03) — "Arqueiro Esquelético" e "Arqueiro
	## Esquelético Reanimado" (2 card_names distintos, nunca uma
	## ambiguidade — ver BattleUnitArtCatalog.CARD_NAME_TO_PATH): mesmo
	## método do Capitão Imperial/Muralha de Ossos — midpoint entre os 2
	## pontos de contato de bota/mão reais, medidos por componentes
	## conectados na faixa inferior da imagem (scipy.ndimage.label),
	## nunca "olhando" uma coordenada. "Arqueiro Esquelético": 2 botas
	## pontudas com joelheira em caveira, claramente separadas (a capa
	## roxa entre elas confundia um método de perfil por coluna simples —
	## resolvido com componentes conectados). "Arqueiro Esquelético
	## Reanimado": 1 pé ósseo (garras) + 1 manopla, também 2 massas
	## claramente separadas.
	"Arqueiro Esquelético": Vector2(0.4264, 0.9516),
	"Arqueiro Esquelético Reanimado": Vector2(0.4310, 0.9694),

	## FASE 6 (2026-09-04) — últimos 8 pelotões do MVP, integrados COMO
	## ESTÃO (fringing/conteúdo NÃO corrigidos, ver
	## BattleUnitArtCatalog.CARD_NAME_TO_PATH). Método por asset, sempre
	## por componentes conectados (scipy.ndimage.label) na faixa inferior
	## da imagem, nunca "olhando" uma coordenada:
	##
	## - "Porco-Espinho Ancestral" (quadrúpede): midpoint entre a massa de
	##   patas dianteiras e a de patas traseiras (2 massas claramente
	##   separadas).
	## - "Árvore Ancestral" (estrutura ambulante, 2 "mãos-raiz" tocando o
	##   chão): midpoint entre as 2 massas de raiz/garra.
	## - "Urso Ancestral" (quadrúpede): centroide de 3 massas de pata
	##   detectadas (a 4ª provavelmente funde com o corpo/folhagem, mesmo
	##   princípio do Unicórnio Ancestral — só as massas realmente
	##   próximas do chão contam).
	## - "Salgueiro Ancião" (estrutura arbórea, base única): ponto mais
	##   baixo real + centro da faixa de colunas a <=8px dele (método do
	##   Altar da Reanimação).
	## - "Flor da Aurora" (base única, caule/raízes espalhados numa faixa
	##   larga): mesmo método de base única — o pixel mais baixo isolado
	##   NÃO é confiável aqui (planta é uma silhueta conectada larga,
	##   ~750px), por isso o centro da faixa é o correto, não o mínimo
	##   bruto.
	## - "Leão da Savana" (quadrúpede, pose dinâmica de rugido): centroide
	##   das 4 massas de pata/garra detectadas na faixa inferior.
	## - "Trepadeira Ancestral" (silhueta radial sem "baixo" óbvio — a
	##   maioria dos ramos se enrola pra cima/lados; problema de conteúdo
	##   conhecido): dos ramos, só 2 terminam em raízes desfiadas
	##   apontando pra baixo, tocando a borda inferior do canvas —
	##   midpoint entre essas 2 (os únicos candidatos reais de contato,
	##   nunca o centro do bbox inteiro, que ficaria no meio da silhueta
	##   radial, no ar).
	## - "Coração da Floresta" (diorama com múltiplas criaturas — viola
	##   "1 personagem = 1 pelotão visual", problema de conteúdo
	##   conhecido, mantido intencionalmente pra integração "como está"):
	##   nenhum animal individual representa o pelotão inteiro, então o
	##   ground contact usa o método de base única (mesmo princípio do
	##   Altar/Salgueiro) sobre a massa de musgo/raiz que sustenta toda a
	##   cena — "menor região visual que representa o contato com o
	##   terreno", não a pata de um animal específico.
	"Porco-Espinho Ancestral": Vector2(0.3969, 0.9628),
	"Árvore Ancestral": Vector2(0.6374, 0.9599),
	"Urso Ancestral": Vector2(0.5730, 0.9424),
	"Salgueiro Ancião": Vector2(0.2775, 0.9978),
	"Flor da Aurora": Vector2(0.5731, 0.9984),
	"Leão da Savana": Vector2(0.5667, 0.9201),
	"Trepadeira Ancestral": Vector2(0.5397, 0.9635),
	"Coração da Floresta": Vector2(0.5794, 0.9969),
}

## PILOTOS 02/03: testado visualmente (composição direta sobre
## campo_aberto.png, script isolado, 3 candidatos por asset: 0.14/0.10 —
## igual ao Arqueiro —, 0.10/0.071 e 0.08/0.057) se este MESMO par de
## valores (sem override por asset) também produz um resultado
## proporcional para "Altar da Reanimação" e "Unicórnio Ancestral" —
## confirmado que sim para os dois (0.14/0.10 lê bem nas 3 profundidades
## e nos 2 lados, sem parecer nem minúsculo nem estourando o tile;
## 0.08-0.10 deixava os dois visivelmente pequenos demais pra sua
## presença temática). Por isso NENHUM mecanismo de escala por
## card_name foi criado — a arquitetura de escala continua exatamente a
## mesma (global, por lado), sem introduzir uma abstração que os dois
## pilotos não comprovaram ser necessária. Se um FUTURO asset exigir
## escala diferente, esta é a única constante a estender (nunca criar
## escala por posição/profundidade).
##
## Escala FIXA por lado (Teste Visual 04, reafirmada aprovada no Teste
## 07) — nunca por posição, profundidade ou card. Side 0 usa o maior
## tamanho já observado no pipeline original (Região 2/Lado 0,
## fit_scale ≈ 0.1405); Side 1 usa 0.10. De propósito, os dois lados NÃO
## são iguais (decisão explícita do Teste 04).
const STANDARD_SCALE_FACTOR_SIDE_0: float = 0.14
const STANDARD_SCALE_FACTOR_SIDE_1: float = 0.10

## Dimensão (px) dos 10 PNGs de Battlefield — mesma constante já
## duplicada, com o MESMO valor, em CombatReplayView e em
## BattlefieldSlotGeometry (ambas documentam "confirmado por inspeção,
## nunca recalculado"); só usada aqui pra converter px -> fração.
const BATTLEFIELD_IMAGE_SIZE: Vector2 = Vector2(1536.0, 1024.0)


## Centro visual CALIBRADO (fração 0..1 da imagem-fonte do Battlefield)
## da célula (side, position) — única fonte de verdade de "onde fica o
## centro desta célula" pra Battle Art de produção.
static func cell_center_frac(side: int, position: int) -> Vector2:
	return MEASURED_CELL_CENTER_FRAC[side][position]


static func scale_factor_for_side(side: int) -> float:
	return STANDARD_SCALE_FACTOR_SIDE_1 if side == 1 else STANDARD_SCALE_FACTOR_SIDE_0


## FOOT_CENTER do card_name — Vector2(0.5, 1.0) (base do bbox) como
## fallback estrutural, nunca realmente alcançado hoje: só existe
## card_name com Battle Art (has_art_for() == true) se ele também tiver
## uma entrada aqui (o piloto tem as duas). Adicionar um 2º personagem
## de Battle Art no futuro exige medir e registrar seu próprio
## FOOT_CENTER aqui — nunca reaproveitar cegamente o do piloto.
static func foot_center_frac_for(card_name: String) -> Vector2:
	return CARD_NAME_TO_FOOT_CENTER_FRAC.get(card_name, Vector2(0.5, 1.0))


## Colocação completa (frações 0..1 da imagem-fonte do Battlefield) do
## Battle Art de "card_name" na célula (side, position):
## anchor_left/right/top/bottom do TextureRect que exibe o conteúdo já
## recortado pelo retângulo alfa (content_w_px x content_h_px, ver
## BattleUnitArtCatalog.content_alpha_rect_for()). Fórmula (Teste Visual
## 05/07, aprovada visualmente): o ponto FOOT_CENTER_FRAC_IN_CONTENT do
## conteúdo renderizado é ancorado EXATAMENTE em cell_center_frac() —
## nunca o centro do retângulo renderizado, nunca a base do bbox.
static func placement_for(side: int, position: int, card_name: String, content_w_px: float, content_h_px: float) -> Dictionary:
	var cell_center: Vector2 = cell_center_frac(side, position)
	var foot_center_frac_in_content: Vector2 = foot_center_frac_for(card_name)
	var scale: float = scale_factor_for_side(side)

	var render_w_frac: float = (content_w_px * scale) / BATTLEFIELD_IMAGE_SIZE.x
	var render_h_frac: float = (content_h_px * scale) / BATTLEFIELD_IMAGE_SIZE.y

	var left: float = cell_center.x - foot_center_frac_in_content.x * render_w_frac
	var top: float = cell_center.y - foot_center_frac_in_content.y * render_h_frac

	return {
		"anchor_left": left,
		"anchor_right": left + render_w_frac,
		"anchor_top": top,
		"anchor_bottom": top + render_h_frac,
	}
