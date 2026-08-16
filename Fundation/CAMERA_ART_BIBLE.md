[Certo] Acho que isso merece um documento próprio. A câmera é um dos pilares da identidade visual do jogo, no mesmo nível de iluminação, materiais e composição. Hoje ela aparece diluída em alguns documentos, mas não existe uma especificação completa e congelada.

A imagem que você enviou tem exatamente o tipo de leitura estratégica que buscamos. Não pelos personagens, UI ou cenário, mas pela forma como a câmera organiza o espaço.

Eu criaria o seguinte documento canônico:

# CAMERA_ART_BIBLE.md
**Status:** 🟢 CANÔNICO — CONGELADO PARA PRODUÇÃO

---

# 1. Filosofia

A câmera existe para servir à gameplay.

Ela nunca existe para impressionar.

Ela nunca muda para favorecer um efeito cinematográfico.

Seu objetivo é fazer o jogador compreender instantaneamente:

- posição dos pelotões;
- linhas de combate;
- profundidade;
- distância;
- direção dos ataques;
- estado da batalha.

A clareza estratégica possui prioridade absoluta.

---

# 2. Identidade Visual

A câmera deve transmitir:

- jogo de miniaturas;
- batalha tática;
- profundidade;
- escala;
- organização;
- estabilidade.

Nunca deve transmitir:

- ação cinematográfica;
- câmera de RPG;
- câmera de MOBA;
- câmera aérea totalmente vertical;
- câmera de RTS clássico.

---

# 3. Tipo de câmera

**Isométrica Perspectiva**

Não ortográfica.

Perspectiva discreta.

As linhas convergem suavemente.

Isso faz o campo parecer físico.

---

# 4. Inclinação Vertical

A câmera observa o campo entre

**35° e 45°**

Nunca muito alta.

Nunca muito baixa.

A imagem enviada é praticamente essa faixa.

---

# 5. Rotação Horizontal

Rotação fixa.

Sempre aproximadamente

**45°**

Os dois exércitos permanecem em diagonais opostas.

Nunca frontal.

Nunca lateral.

---

# 6. Distância

A câmera nunca aproxima durante a batalha.

O enquadramento permanece fixo.

Zoom apenas:

- aproximação inicial;
- tutorial;
- replay.

Jamais durante o combate normal.

---

# 7. Altura

O jogador enxerga:

- os dois grids completos;
- os dois comandantes;
- parte do terreno ao redor.

Sem necessidade de mover câmera.

---

# 8. Campo Visível

A câmera sempre mostra:

✓ Grid aliado

✓ Grid inimigo

✓ Separação central

✓ Comandantes

✓ Parte do território

✓ Horizonte

Nunca corta qualquer desses elementos.

---

# 9. Profundidade

A perspectiva deve criar sensação de volume.

Os blocos do terreno possuem espessura.

As cartas parecem realmente estar apoiadas sobre um campo físico.

Nunca sobre uma textura plana.

A referência enviada faz isso muito bem.

---

# 10. Horizonte

O horizonte permanece alto.

Entre

65–75%

da altura da imagem.

Isso permite:

- mostrar o território;
- transmitir escala;
- não roubar espaço do combate.

---

# 11. Regra de Ouro

Se removermos toda a interface,

o jogador ainda deve reconhecer imediatamente:

- onde começa a batalha;
- onde termina;
- quem enfrenta quem.

A câmera deve comunicar isso sozinha.

---

# 12. O que NUNCA fazer

❌ câmera totalmente superior (90°)

❌ câmera cinematográfica

❌ câmera muito próxima

❌ câmera muito distante

❌ mudar rotação conforme mapa

❌ mudar inclinação conforme terreno

❌ mover câmera durante ataques

❌ zoom constante

❌ tremores exagerados

❌ perspectiva extrema

---

# 13. Referência Oficial

A imagem enviada deve servir como **referência exclusiva da linguagem da câmera**, considerando apenas:

- ângulo da câmera;
- altura;
- distância;
- perspectiva;
- enquadramento;
- leitura espacial;
- profundidade.

**Não utilizar como referência para:**

- personagens;
- interface;
- arquitetura;
- iluminação;
- efeitos;
- materiais;
- estilo artístico;
- grid;
- cartas.

---

Eu acrescentaria ainda uma **Prancha Visual da Câmera**, semelhante às que fizemos para as facções, contendo:

- câmera oficial (hero image);
- diagrama com ângulo horizontal (45°);
- diagrama com inclinação vertical (35°–45°);
- área segura da interface;
- área ocupada pelo grid;
- posição fixa dos comandantes;
- posição do horizonte;
- exemplos de enquadramentos corretos e incorretos.

Esse documento passa a ser a referência única para qualquer render, conceito, splash art ou cena de batalha do Battle Simulator, garantindo que todas as imagens mantenham exatamente a mesma linguagem de câmera.