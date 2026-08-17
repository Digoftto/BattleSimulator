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


def extract_canonical_tier3(catalog_text: str) -> dict:
    """Extrai {nome_da_carta: tier_3_ability_name} de CARD_CATALOG.md.

    Varredura linear (não depende de dividir o documento em blocos por
    cabeçalho "Carta N", que já se mostrou frágil a variações de
    formatação) — associa cada "Tier III" ao "Nome" mais recentemente
    visto antes dele.
    """
    lines = [l.strip() for l in catalog_text.replace("\r\n", "\n").split("\n")]
    result = {}
    current_name = None

    i = 0
    while i < len(lines):
        line = lines[i]

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
