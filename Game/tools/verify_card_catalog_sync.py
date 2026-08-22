#!/usr/bin/env python3
"""verify_card_catalog_sync.py

Ferramenta de verificação (não faz parte do runtime do jogo). Compara o
Tier III (Habilidade de Campanha) de cada carta em CARD_CATALOG.md contra
o campo tier_3_ability_name do CardResource (.tres) correspondente.

Por que este script existe fora do Godot:
CARD_CATALOG.md é um documento de design (SSOT), não um dado de jogo —
o Godot nunca deveria carregar/parsear Markdown em runtime. Esta
verificação é, portanto, uma etapa de build/revisão manual (rodar antes
de aprovar qualquer Sprint que dependa de valores de Tier III), não uma
validação de bootstrap.gd.

Origem: Sprint 26.5 — encontrado que CARD_CATALOG.md e os CardResource
haviam divergido silenciosamente após uma redistribuição de Tier III
(Sprint 24) que só foi aplicada ao documento, nunca aos Resources.

Uso:
    python3 tools/verify_card_catalog_sync.py

Saída esperada quando tudo está sincronizado:
    Cartas verificadas: 39 / 39
    Divergências: 0
"""

import re
import glob
import os
import sys
from pathlib import Path

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = Path(PROJECT_ROOT).parent
CARD_CATALOG_PATH = REPO_ROOT / "Arquitetura" / "CARD_CATALOG.md"
CARDS_GLOB = os.path.join(PROJECT_ROOT, "database", "cards", "*.tres")


# Rótulos de campo da própria "Estrutura da Ficha" (o template no topo
# de CARD_CATALOG.md que descreve quais campos uma carta possui — Nome,
# Facção, Classe... — não uma carta em si). Usados apenas pela rede de
# segurança ao final de extract_canonical_tier3(); nunca coincidem com
# um nome de carta real.
FICHA_LEGEND_FIELDS = {
    "nome", "facção", "classe", "tier", "raridade", "lore",
    "atributos base", "tier i", "tier iii", "tier v",
    "receita de combinação", "observações",
}


def extract_canonical_tier3(catalog_text: str) -> dict:
    """Extrai {nome_da_carta: tier_3_ability_name} de CARD_CATALOG.md.

    Varredura linear (não depende de dividir o documento em blocos por
    cabeçalho "Carta N", que já se mostrou frágil a variações de
    formatação) — associa cada "Tier III" ao "Nome" mais recentemente
    visto antes dele.

    Ignora tudo antes da primeira ocorrência real de "Carta N": a seção
    "Estrutura da Ficha" no início do documento (o template que lista
    os nomes dos campos de uma carta, incluindo linhas "Nome" e
    "Tier III" isoladas) não é uma carta e não pode ser varrida como se
    fosse uma — sem essa guarda, o parser confundia o próprio template
    com uma carta fantasma ("Facção" -> "Tier V", contada como uma 40ª
    carta inexistente; ver TECHNICAL_BACKLOG.md, F-006).
    """
    lines = [l.strip() for l in catalog_text.replace("\r\n", "\n").split("\n")]
    result = {}
    current_name = None
    scanning = False  # só True depois da primeira "Carta N" real — a
    # "Estrutura da Ficha" (topo do documento) nunca contém esse marcador.

    i = 0
    while i < len(lines):
        line = lines[i]

        if not scanning:
            if re.fullmatch(r"(?:Carta|carta) \d+", line):
                scanning = True
            else:
                i += 1
                continue

        if line.lower() == "nome":
            for j in range(i + 1, min(i + 3, len(lines))):
                if lines[j]:
                    current_name = lines[j].replace(" (provisório)", "")
                    break

        elif re.fullmatch(r"(?:Carta|carta) \d+", line):
            # Formato alternativo: algumas cartas não têm um cabeçalho
            # "Nome" explícito — o nome vem diretamente após "Carta N".
            for j in range(i + 1, min(i + 4, len(lines))):
                if not lines[j]:
                    continue
                if lines[j].lower() == "nome":
                    break  # segue o caminho normal (capturado no próximo loop)
                current_name = lines[j].replace(" (provisório)", "")
                break

        elif line == "Tier III" and current_name is not None:
            for j in range(i + 1, min(i + 4, len(lines))):
                cand = lines[j]
                if cand and cand not in ("Habilidade (Exclusiva de PvE)", "Evolução", "Habilidade"):
                    result[current_name] = cand
                    break

        i += 1

    # Rede de segurança (regressão): mesmo com a guarda de "scanning"
    # acima, nenhuma carta real pode ter como nome um dos próprios
    # rótulos de campo da Ficha (Nome, Facção, Classe...). Se isso
    # acontecer de novo — por exemplo, uma nova seção de template
    # adicionada em outro ponto do documento — falha alto e claro em
    # vez de silenciosamente contar uma carta fantasma.
    phantom = FICHA_LEGEND_FIELDS.intersection(name.lower() for name in result)
    assert not phantom, (
        "extract_canonical_tier3: nome(s) de carta suspeito(s) — coincide(m) com "
        f"rótulo(s) de campo da Estrutura da Ficha, provável template sendo lido "
        f"como carta: {sorted(phantom)}"
    )

    return result


def get_field(text: str, field: str) -> str:
    m = re.search(rf'^{field} = "(.*)"$', text, re.MULTILINE)
    return m.group(1) if m else ""


def main() -> int:
    if not CARD_CATALOG_PATH.is_file():
        raise FileNotFoundError(
            f"CARD_CATALOG.md não encontrado em '{CARD_CATALOG_PATH}'. "
            "Verifique se o repositório contém 'Arquitetura/CARD_CATALOG.md' "
            "na raiz, ao lado da pasta 'Game'."
        )

    with open(CARD_CATALOG_PATH, encoding="utf-8") as f:
        canonical = extract_canonical_tier3(f.read())

    divergent = []
    checked = 0
    for path in glob.glob(CARDS_GLOB):
        text = open(path, encoding="utf-8").read()
        name = get_field(text, "card_name")
        current = get_field(text, "tier_3_ability_name")
        expected = canonical.get(name)
        checked += 1
        if expected is None:
            print(f"AVISO: carta '{name}' ({path}) não encontrada em CARD_CATALOG.md.")
            continue
        if current != expected:
            divergent.append((name, path, current, expected))

    print(f"Cartas verificadas: {checked} / {len(canonical)}")
    print(f"Divergências: {len(divergent)}")
    for name, path, current, expected in divergent:
        print(f"  {name} ({os.path.basename(path)}): '{current}' -> esperado '{expected}'")

    return 1 if divergent else 0


if __name__ == "__main__":
    sys.exit(main())
