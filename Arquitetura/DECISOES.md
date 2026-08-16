# DECISOES.md

# Decisões Arquiteturais do Projeto

## Objetivo

Este documento é o registro oficial das decisões arquiteturais e políticas permanentes do projeto Battle Simulator.

Seu objetivo é documentar convenções, diretrizes de desenvolvimento, princípios de documentação e regras de manutenção estrutural que governam a construção do projeto.

Este documento **não** registra regras, mecânicas ou parâmetros do jogo, limitando-se exclusivamente às decisões permanentes que afetam o processo de desenvolvimento, a arquitetura de software e a governança da documentação.

---

## Responsabilidade do Documento

Este documento é a Fonte Única de Verdade (*Single Source of Truth*) para:

* Políticas permanentes de desenvolvimento do projeto;
* Convenções arquiteturais e de *ownership*;
* Princípios de documentação e manutenção da arquitetura;
* Regras para atuação de agentes de IA colaboradores;
* Critérios formais para congelamento de documentos.

Este documento **não** define:

* Mecânicas de combate;
* Regras de PvP e PvE;
* Progressões, níveis ou experiência;
* Economia, moedas ou recursos;
* Cartas, afinidades e Tiers;
* Comandantes e patentes;
* Construções e infraestrutura urbana;
* Matchmaking e classificações;
* Qualquer outra regra ou mecânica pertencente ao domínio de um sistema específico.

Essas responsabilidades pertencem exclusivamente aos seus respectivos documentos arquiteturais.

---

## Filosofia Arquitetural

A arquitetura do Battle Simulator é fundamentada nos seguintes princípios universais:

1. **Single Source of Truth (SSOT):** Cada regra, conceito, fórmula ou mecânica possui um único documento responsável. Nenhuma informação deve ser duplicada entre arquivos.
2. **Propriedade Única de Domínio (*Ownership*):** Todo sistema ou subsistema pertence a um único documento. A responsabilidade sobre um domínio nunca é compartilhada.
3. **Baixo Acoplamento e Alta Coesão:** Os documentos interagem via referências cruzadas e delimitações claras de fronteira, garantindo que alterações em um módulo não causem efeitos colaterais na definição de outro.
4. **Descrição de Domínio vs. Implementação:** Os documentos arquiteturais descrevem o *o quê* e o *como* conceitual do domínio, funcionando como especificação técnica, e não como guias de código ou implementação específica.
5. **Simplicidade e Manutenibilidade:** A estrutura documental deve priorizar a clareza visual, a escaneabilidade e a facilidade de manutenção por humanos e agentes de IA.

---

## Fonte da Verdade

* A documentação oficial do repositório é a **única fonte da verdade** para o desenvolvimento do projeto.
* Nenhuma funcionalidade, mecânica ou alteração estrutural deve ser implementada no código sem estar formalmente especificada em seu documento arquitetural correspondente.
* Em caso de divergência entre a implementação (código) e a especificação (documentação), a documentação prevalece e o código deve ser corrigido, a menos que uma revisão arquitetural explícita altere o documento primeiro.

---

## Política de Documentação

Para garantir a integridade do projeto ao longo do tempo, adotam-se as seguintes convenções de documentação:

* **Sincronia Imediata:** Toda alteração ou refinamento arquitetural aprovado deve refletir imediatamente na documentação correspondente.
* **Atribuição de Ownership:** Qualquer novo sistema, mecânica ou subsistema introduzido no projeto deve ter seu documento *dono* definido antes de sua especificação detalhada.
* **Proibição de Duplicação:** Nenhum documento deve reproduzir, resumir ou reinterpretar regras pertencentes a outro módulo.
* **Substituição por Referência:** Sempre que um sistema depender de informações de outro domínio, deve citar o arquivo responsável (ex: `VER FORMULAS.md`) em vez de repetir os dados.

---

## Processo de Desenvolvimento

* **Desenvolvimento Guiado por Arquitetura:** O fluxo de trabalho obedece à ordem rigorosa: *Conceito $\rightarrow$ Revisão Arquitetural (SSOT) $\rightarrow$ Implementação em Código*.
* **Modularidade:** Novas mecânicas devem ser desenhadas como módulos independentes com interfaces de comunicação claras com o restante do sistema.
* **Evolução Gradual:** Decisões de balanceamento numérico e parâmetros operacionais só devem ser fixados após a consolidação da estrutura lógica do módulo.

---

## Integridade entre Cartas e Habilidades

Cada campo de uma Carta deve referenciar exclusivamente Habilidades pertencentes ao mesmo Tier (o campo de Tier III só pode referenciar uma Habilidade catalogada como Tier III; o campo de Tier V só pode referenciar uma Habilidade catalogada como Tier V). Essa restrição é estrutural e validada automaticamente pelo projeto (`bootstrap.gd`, verificação de integridade do catálogo).

Violações dessa correspondência representam **erro de integridade da SSOT**, nunca uma decisão de balanceamento ou uma variação de design válida.

---

## Regras para Agentes de IA

Agentes de Inteligência Artificial atuando como colaboradores na arquitetura ou no código do projeto devem seguir estritamente as diretrizes abaixo:

1. **Respeitar o SSOT:** Identificar o documento *dono* de cada informação antes de propor ou aplicar alterações.
2. **Consultar antes de Alterar:** Verificar os documentos correlatos para garantir que uma modificação não viole as fronteiras de outro sistema.
3. **Preservar a Separação de Conceitos:** Jamais introduzir regras de combate em documentos de economia, regras econômicas em documentos de interface, ou vice-versa.
4. **Manter o Padrão de Formatação:** Utilizar rigorosamente a estrutura visual oficial (cabeçalhos, tabelas, blocos de destaque e referências) padronizada no projeto.
5. **Não Assumir Responsabilidades Omissas:** Se uma regra pertencer a um documento ainda não criado ou pendente, a IA deve apontar a necessidade da criação do documento próprio em vez de alocar a regra em local inadequado.

---

## Critérios para Congelamento de Documentos

Um documento arquitetural é considerado **congelado** (*stabilized/frozen*) quando atinge maturação estrutural completa e não exige revisões conceituais frequentes.

Um documento pode ser congelado quando atender cumulativamente aos seguintes critérios:

* Sua responsabilidade e escopo estiverem claramente delimitados na seção de *Objetivo* e *Responsabilidade do Documento*;
* Possuir *ownership* exclusivo e inequívoco sobre o seu domínio;
* Não contiver duplicidades ou cópias de regras pertencentes a outros arquivos;
* Demonstrar baixo acoplamento, utilizando apenas referências para se conectar aos demais sistemas;
* Atender integralmente ao princípio de *Single Source of Truth* (SSOT);
* Servir exclusivamente como especificação arquitetural do seu domínio.

---

## Pendências Consolidadas (Sprints 24/25)

### Pendências Arquiteturais

* **Ausência de mecanismo de consulta para modificadores permanentes de atributo.** Impede a implementação completa de Habilidades/Características cujo efeito é um bônus permanente de Ataque/HP/Escudo consultado continuamente pelo `CombatEngine` (ex: o bônus de +4% de Ataque de "Colheita de Almas", hoje implementado apenas parcialmente — ver `UnitTraitRuntime`).
* **Fluxo de cura estrutural não é parametrizável.** `CombatEngine._apply_structural_heal()` usa `STRUCTURAL_HEAL_AMOUNT` diretamente, sem ler de volta nenhum valor do `CombatContext` — diferente do fluxo de ataque (que já lê `attack_value` de volta desde a Sprint 21). Bloqueia a implementação completa de "Cura" (Tier I) e de qualquer Habilidade/Característica que module a Cura Estrutural. Permanece válida após a revisão desta Sprint — nenhuma mudança foi feita em `CombatEngine`.

### Pendências de Regras do Jogo

Nenhuma. A definição das Relações Espaciais do Tabuleiro (esquerda/direita/adjacência/mesma linha/mesma coluna) foi consolidada em `COMBAT_RULES.md`, seção 1.1.1.

### Pendências Futuras

* Expor API pública de consultas espaciais no `CombatBoard` (esquerda, direita, adjacência, mesma linha, mesma coluna), substituindo cálculos ad-hoc que Runtimes individuais possam vir a implementar por conta própria.
* Hook de consulta em `CombatEngine` para a seleção de alvo (necessário para "Provocar" e futuras Habilidades de Consulta — ver Sprint 24).

---

## Referências

* **GAME_PHILOSOPHY.md:** Princípios fundamentais e filosofia de design do jogo.
* **PROJECT_STRUCTURE.md:** Mapeamento da árvore de diretórios e organização dos arquivos do repositório (caso aplicável).
* **Demais documentos do diretório `/docs`:** Fontes únicas de verdade de cada módulo específico do sistema.