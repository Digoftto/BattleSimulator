#!/usr/bin/env python3
"""
build_project.py

Monta a Estrutura Oficial (congelada) do projeto Battle Simulator (Godot 4.7).

Regras de execução:
- Idempotente: pode ser executado quantas vezes for necessário.
- Nunca sobrescreve arquivos existentes.
- Nunca apaga arquivos ou pastas existentes.
- Cria apenas o que ainda não existir.
- Não cria nenhum arquivo "placeholder" além dos mínimos necessários
  para o projeto Godot abrir corretamente:
    - project.godot
    - icon.svg
    - scenes/main/main.tscn

Este script reflete exclusivamente a árvore de diretórios aprovada.
Qualquer alteração estrutural futura deve ser aprovada antes de ser
refletida aqui.
"""

from __future__ import annotations

import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Raiz do projeto: diretório onde este script está localizado.
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent


# ---------------------------------------------------------------------------
# Estrutura oficial de diretórios (relativa à raiz do projeto).
# ---------------------------------------------------------------------------
DIRECTORIES: list[str] = [
    # autoload
    "autoload",

    # resources (schemas de dados)
    "resources/cards",
    "resources/commanders",
    "resources/battlefields",
    "resources/library",

    # database (banco de dados estático do jogo)
    "database/cards",
    "database/abilities",
    "database/commanders_pool",
    "database/battlefields",
    "database/library_content",

    # engine (lógica de domínio)
    "engine/combat",
    "engine/cards",
    "engine/army",
    "engine/commanders",
    "engine/command_center",
    "engine/city",
    "engine/economy",
    "engine/modes",
    "engine/persistence",
    "engine/services",

    # scenes (composição visual)
    "scenes/main",
    "scenes/bootstrap",
    "scenes/shared",
    "scenes/combat/battlefield",
    "scenes/army",
    "scenes/commanders",
    "scenes/city",
    "scenes/modes",
    "scenes/library",
    "scenes/observatory",

    # ui
    "ui/components",
    "ui/themes",
    "ui/fonts",
    "ui/icons",
    "ui/animations",

    # assets
    "assets/art",
    "assets/audio",
    "assets/music",
    "assets/sfx",
    "assets/shaders",
    "assets/fonts",
    "assets/icons",

    # tools
    "tools/project_builder",
    "tools/database_builder",
    "tools/importers",
    "tools/exporters",
    "tools/debug",

    # tests
    "tests",

    # user
    "user",
]


# ---------------------------------------------------------------------------
# Arquivos mínimos necessários para o projeto abrir corretamente no Godot 4.7.
# Nenhum arquivo além destes é criado nesta etapa.
# ---------------------------------------------------------------------------

PROJECT_GODOT_CONTENT = """; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes to [section] group in the Project Settings.
;   param=value ; assign values to parameters.

config_version=5

[application]

config/name="Battle Simulator"
config/features=PackedStringArray("4.7")
config/icon="res://icon.svg"
run/main_scene="res://scenes/main/main.tscn"
"""

ICON_SVG_CONTENT = """<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="16" fill="#1b1e26"/>
  <rect x="24" y="24" width="80" height="80" rx="8" fill="#3a4a63"/>
</svg>
"""

MAIN_SCENE_CONTENT = """[gd_scene format=3]

[node name="Main" type="Node"]
"""

# Mapa: caminho relativo -> conteúdo do arquivo.
FILES: dict[str, str] = {
    "project.godot": PROJECT_GODOT_CONTENT,
    "icon.svg": ICON_SVG_CONTENT,
    "scenes/main/main.tscn": MAIN_SCENE_CONTENT,
}


# ---------------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------------

def ensure_directories(root: Path, directories: list[str]) -> tuple[int, int]:
    """Cria diretórios que ainda não existem. Retorna (criados, já existentes)."""
    created = 0
    skipped = 0
    for rel_dir in directories:
        target = root / rel_dir
        if target.exists():
            skipped += 1
            continue
        target.mkdir(parents=True, exist_ok=True)
        created += 1
        print(f"[dir ]  criado   -> {rel_dir}")
    return created, skipped


def ensure_files(root: Path, files: dict[str, str]) -> tuple[int, int]:
    """Cria arquivos que ainda não existem. Nunca sobrescreve. Retorna (criados, já existentes)."""
    created = 0
    skipped = 0
    for rel_path, content in files.items():
        target = root / rel_path
        if target.exists():
            skipped += 1
            print(f"[file]  existente (mantido) -> {rel_path}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8", newline="\n")
        created += 1
        print(f"[file]  criado   -> {rel_path}")
    return created, skipped


def main() -> int:
    print(f"Battle Simulator — build_project.py")
    print(f"Raiz do projeto: {PROJECT_ROOT}")
    print("-" * 60)

    dirs_created, dirs_skipped = ensure_directories(PROJECT_ROOT, DIRECTORIES)
    print("-" * 60)
    files_created, files_skipped = ensure_files(PROJECT_ROOT, FILES)

    print("-" * 60)
    print(f"Diretórios: {dirs_created} criados, {dirs_skipped} já existentes.")
    print(f"Arquivos:   {files_created} criados, {files_skipped} já existentes.")
    print("Estrutura oficial do Battle Simulator verificada/montada com sucesso.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
