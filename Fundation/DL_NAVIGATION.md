# DL_NAVIGATION.md

Status: 🟢 Congelado

---

# Objetivo

Definir como o jogador navega entre os diferentes níveis do jogo, mantendo a sensação de continuidade entre mundo, Reino e sistemas.

O jogador nunca deve sentir que saiu do mundo para abrir um menu. Toda navegação representa apenas uma mudança de escala da câmera.

---

# Filosofia

O jogador sempre permanece dentro do mesmo mundo.

A interface aproxima ou afasta sua perspectiva, mas nunca o transporta para uma tela desconectada.

A câmera acompanha a mudança de papel do jogador:

Mundo → Governante

Reino → Administrador

Construção → Especialista

Essa transição deve ocorrer naturalmente.

---

# Nível 1 — Mundo

É a principal tela do jogo.

Representa todo o continente conhecido.

Elementos visíveis:

- Reino do jogador
- Três trilhas do PvE
- Minas descobertas
- Portal de Travessia (quando desbloqueado)
- Atmosfera
- Céu
- Pequenos elementos vivos

Nesta camada o jogador enxerga o panorama geral do progresso.

Pergunta respondida:

> "Como está meu Reino dentro do continente?"

---

# Transição

Ao selecionar o Reino, a câmera realiza um movimento contínuo de aproximação.

Não existe troca de tela.

Não existe sensação de carregar um novo ambiente.

---

# Nível 2 — Reino

Representa a cidade completa.

Todos os edifícios coexistem no mesmo espaço.

Elementos principais:

- Capital
- Centro de Comando
- Academia
- Núcleo de Energia
- Depósito

Cada construção evolui visualmente conforme seu nível.

O jogador observa o crescimento do Reino como um organismo único.

Pergunta respondida:

> "Como está organizado meu Reino?"

---

# Capital

A Capital permanece integrada ao Reino.

Não funciona como um menu separado.

Sua evolução ocorre diretamente sobre a própria construção.

Ela representa o centro físico e simbólico da cidade.

---

# Transição

Ao selecionar qualquer construção, a câmera aproxima novamente.

A construção permanece visível durante toda a navegação.

A interface aparece integrada ao ambiente.

---

# Nível 3 — Construções

Cada construção possui sua própria identidade visual.

O jogador continua enxergando o edifício enquanto utiliza seu sistema.

Exemplos:

Centro de Comando

- Comandantes
- Montarias
- Oficiais
- Pátios
- Salão do Legado

Academia

- Câmara de Convergência
- Oficinas
- Jardins
- Forjas
- Bibliotecas

Núcleo de Energia

- Núcleo Central
- Cristais Arcanos
- Névoa
- Canais de Essência Vital

Depósito

- Galpões
- Silos
- Pátios
- Trabalhadores
- Materiais armazenados

A interface complementa o ambiente, nunca o substitui.

Pergunta respondida:

> "Como utilizo este sistema?"

---

# Princípios de Navegação

O jogador nunca abandona o mundo.

A câmera apenas muda de escala.

Cada aproximação revela mais detalhes.

Cada afastamento amplia a visão estratégica.

---

# Progressão Visual

Mundo

↓

Reino

↓

Construção

↓

Sistema

Essa progressão acompanha naturalmente a forma como o jogador pensa durante a partida.

Governar.

↓

Administrar.

↓

Especializar.

---

# Direção de Arte

Cada nível de aproximação acrescenta informação visual.

Mundo

- Silhuetas.
- Atmosfera.
- Grandes estruturas.

Reino

- Arquitetura.
- Expansões.
- Movimento urbano.

Construções

- Pessoas.
- Equipamentos.
- Animações.
- Pequenos detalhes.

O jogador percebe que está observando o mesmo lugar sob diferentes escalas.

---

# Áudio

Cada nível acrescenta novas camadas sonoras.

Mundo

- Vento.
- Fauna.
- Ambiente geral.

Reino

- Vida urbana.
- Ferramentas.
- Movimento.

Construções

Cada edifício possui identidade sonora própria:

Centro de Comando

- Ordens.
- Passos.
- Montarias.
- Treinos.

Academia

- Ferramentas.
- Água.
- Estudos.
- Forjas.

Núcleo de Energia

- Fluxo da Essência Vital.
- Cristais.
- Névoa.
- Ambiente sereno.

Depósito

- Carroças.
- Cordas.
- Madeira.
- Materiais sendo organizados.

---

# Objetivo Final

Toda a navegação deve transmitir a sensação de que o jogador nunca saiu do Reino.

Ele apenas mudou sua perspectiva sobre o mesmo mundo.

A interface deve desaparecer diante da arquitetura, permitindo que cada sistema seja reconhecido primeiro pelo ambiente e somente depois por seus elementos de gameplay.