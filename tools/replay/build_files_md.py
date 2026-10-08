#!/usr/bin/env python3
"""Собирает docs/replay/03-files.md: полное содержимое всех исходников проекта.
Запуск: make replay (или python3 tools/replay/build_files_md.py)."""
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "replay" / "03-files.md"

INCLUDE = [
    "CLAUDE.md", "Makefile", "project.godot", ".gutconfig.json", ".gitignore",
    "scenes/**/*.tscn", "scripts/**/*.gd", "tests/**/*.gd",
    "tools/blender/**/*.py", "tools/replay/*.py",
    "third_party/.gdignore", "third_party/*/README.md", "third_party/*/LICENSE.md",
    "third_party/unimate_clips/annotation.json",
    "docs/superpowers/specs/*.md", "docs/superpowers/plans/*roadmap.md",
    "docs/superpowers/notes/*.md",
    "export_presets.cfg", "tools/audio/*.py", "assets/ui/*.tres", "assets/shaders/*.gdshader",
    "assets/sfx/README.md", "assets/fonts/OFL.txt",
]
EXCLUDE_DIRS = {"addons", "build", ".godot", ".superpowers"}
# Двоичные файлы (.ttf/.ogg/.wav/.glb) в приложение не входят: откуда их взять, описано в процедуре.
LANG = {".py": "python", ".gd": "gdscript", ".tscn": "", ".json": "json", ".md": "markdown",
        ".godot": "ini", "Makefile": "makefile", ".gitignore": "", ".gdignore": "",
        ".cfg": "ini", ".tres": "", ".gdshader": "glsl", ".txt": ""}


def lang_for(p: pathlib.Path) -> str:
    if p.name == "Makefile":
        return "makefile"
    return LANG.get(p.suffix, "")


def main() -> None:
    files = []
    for pattern in INCLUDE:
        for p in sorted(ROOT.glob(pattern)):
            if p.is_file() and not (set(p.relative_to(ROOT).parts) & EXCLUDE_DIRS):
                files.append(p)
    seen, ordered = set(), []
    for p in files:
        if p not in seen:
            seen.add(p)
            ordered.append(p)
    lines = ["# Приложение: содержимое всех файлов проекта", "",
             "Сгенерировано `make replay` из текущего дерева. Не редактировать руками.",
             "Для каждого файла: путь относительно корня проекта и полное содержимое.",
             "Отступы в GDScript и Makefile — табы; в Python проекта — тоже табы, кроме",
             "`palette.py` и тестов Blender (пробелы). Копировать как есть.", "",
             f"Файлов: {len(ordered)}", ""]
    for p in ordered:
        rel = p.relative_to(ROOT).as_posix()
        text = p.read_text(encoding="utf-8")
        fence = "````" if "```" in text else "```"
        lines += [f"## `{rel}`", "", f"{fence}{lang_for(p)}", text.rstrip("\n"), fence, ""]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(ordered)} файлов, {OUT.stat().st_size // 1024} КБ")


if __name__ == "__main__":
    sys.exit(main())
