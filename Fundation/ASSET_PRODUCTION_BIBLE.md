# ASSET_PRODUCTION_BIBLE.md

**Versão:** 1.0

**Status:** 🟢 Canônico

**Objetivo**

Este documento estabelece os padrões oficiais para criação, organização, nomenclatura, exportação e controle de qualidade de todos os assets do Battle Simulator.

Toda produção artística deve obedecer simultaneamente:

- Art Bible Geral
- Camera Bible
- Battlefield Bible
- Facção correspondente
- Asset Production Bible

Em caso de conflito, prevalece esta ordem.

---

# 1. Filosofia

Todo asset deve ser:

- reutilizável;
- modular;
- consistente;
- legível;
- escalável;
- independente.

Nenhum asset é criado para um único mapa.

Ele deve poder aparecer em dezenas de mapas.

---

# 2. Pipeline Oficial

```
Necessidade

↓

Master Asset List

↓

Asset Specification

↓

Prompt Oficial

↓

Imagem Base

↓

Correções

↓

Aprovação

↓

Remoção de fundo (quando necessário)

↓

Padronização

↓

Exportação

↓

Biblioteca Oficial
```

Nenhum asset pula etapas.

---

# 3. Hierarquia dos Assets

## Categoria A — Gameplay

- Unidades
- Comandantes
- Construções
- Recursos

---

## Categoria B — Cenário

- Rochas
- Árvores
- Pontes
- Cercas
- Ruínas
- Estradas
- Vegetação
- Água

---

## Categoria C — Interface

- Ícones
- Botões
- Molduras
- Fundos
- Símbolos

---

## Categoria D — FX

- Poeira
- Fumaça
- Faíscas
- Névoa
- Raios
- Chuva
- Lava

---

## Categoria E — Decoração

- Barris
- Caixas
- Lanternas
- Bandeiras
- Estátuas
- Ferramentas
- Carroças

---

# 4. Nomenclatura Oficial

Formato:

```
Categoria_Facção_Subcategoria_Número
```

Exemplos:

```
Tree_Nature_001

Rock_Common_012

Barricade_Empire_004

Banner_Undead_002

Commander_Empire_001
```

Nunca utilizar nomes como:

```
tree_final

pedraNova

versao2

novo
```

---

# 5. Resolução Mestre

Toda arte deve ser criada em resolução superior ao necessário para o jogo.

Jamais produzir diretamente na resolução final.

---

# 6. Escala Oficial

Cada asset recebe uma classe de escala:

XS

S

M

L

XL

XXL

A escala é relativa ao grid oficial do combate.

---

# 7. Silhueta

O asset deve ser reconhecido apenas pela silhueta.

Se preenchido totalmente de preto ainda deve ser identificável.

---

# 8. Iluminação

Todos os assets seguem:

- luz principal consistente;
- contraste controlado;
- sombras compatíveis com a Camera Bible.

Nunca criar iluminação específica para um mapa.

---

# 9. Materiais

Cada asset utiliza apenas materiais oficialmente documentados.

Exemplo:

Império

- ferro negro;
- granito;
- couro;
- madeira escura.

Natureza

- madeira viva;
- casca;
- pedra coberta por musgo;
- raízes.

Mortos-Vivos

- osso;
- pedra morta;
- ferro corroído;
- madeira podre.

---

# 10. Paleta

Nenhum artista define cores livremente.

Todas devem respeitar a paleta oficial da facção ou do território.

---

# 11. Modularidade

Sempre perguntar:

> Este asset pode ser reutilizado?

Se a resposta for "não", ele provavelmente está específico demais.

---

# 12. Variações

Todo asset importante possui múltiplas variantes.

Exemplo:

```
Pedra 01

Pedra 02

Pedra 03

Pedra 04
```

Não repetir exatamente o mesmo modelo pelo mapa.

---

# 13. Exportação

Cada asset recebe:

- versão mestre;
- versão otimizada;
- miniatura;
- preview.

---

# 14. Controle de Qualidade

Checklist obrigatório antes da aprovação:

- segue a Art Bible;
- segue a facção correta;
- segue a paleta;
- segue os materiais oficiais;
- silhueta clara;
- escala correta;
- sem elementos proibidos;
- reutilizável;
- sem detalhes desnecessários;
- consistente com o restante da biblioteca.

---

# 15. Estrutura da Biblioteca

```
Assets/

├── Characters/
├── Commanders/
├── Props/
├── Buildings/
├── Resources/
├── Vegetation/
├── Rocks/
├── Terrain/
├── FX/
├── UI/
├── Icons/
├── Portraits/
├── Cards/
├── Environment/
```

---

# 16. Asset Specification (Ficha Obrigatória)

Cada asset terá uma ficha padronizada contendo:

- Nome oficial
- ID
- Categoria
- Facção
- Território
- Battlefield compatível
- Materiais
- Escala
- Função no jogo
- Reutilização permitida
- Variações previstas
- Prompt mestre
- Status (Planejado / Em produção / Aprovado / Implementado)

---

# 17. Fluxo de Aprovação

```
Planejado

↓

Especificado

↓

Gerado

↓

Revisado

↓

Aprovado

↓

Biblioteca Oficial

↓

Godot
```

Nenhum asset entra no projeto sem passar por esse fluxo.