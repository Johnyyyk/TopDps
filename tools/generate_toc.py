#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC_PATH = ROOT / "TopDps.toc"
SPECS_PATH = ROOT / "Specs"
START_MARKER = "# TopDps-Specs-Start"
END_MARKER = "# TopDps-Specs-End"


def collect_spec_files() -> list[str]:
    result: list[str] = []

    class_directories = sorted(
        (path for path in SPECS_PATH.iterdir() if path.is_dir()),
        key=lambda path: path.name.lower(),
    )

    for class_directory in class_directories:
        lua_files = sorted(
            class_directory.glob("*.lua"),
            key=lambda path: (path.name != "Common.lua", path.name.lower()),
        )

        for lua_file in lua_files:
            relative = lua_file.relative_to(ROOT)
            result.append(str(relative).replace("/", "\\"))

    return result


def generate_content(original: str) -> str:
    lines = original.splitlines()

    try:
        start = lines.index(START_MARKER)
        end = lines.index(END_MARKER)
    except ValueError as error:
        raise RuntimeError("В TopDps.toc отсутствуют маркеры списка специализаций") from error

    if end <= start:
        raise RuntimeError("Некорректный порядок маркеров списка специализаций")

    generated = [START_MARKER, *collect_spec_files(), END_MARKER]
    result = lines[:start] + generated + lines[end + 1 :]
    return "\n".join(result) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Обновляет список файлов специализаций в TopDps.toc")
    parser.add_argument(
        "--check",
        action="store_true",
        help="не менять файл и завершиться с ошибкой, если TopDps.toc устарел",
    )
    args = parser.parse_args()

    original = TOC_PATH.read_text(encoding="utf-8")
    generated = generate_content(original)

    if args.check:
        if generated != original:
            print("TopDps.toc устарел. Выполните: python3 tools/generate_toc.py")
            return 1
        return 0

    if generated != original:
        TOC_PATH.write_text(generated, encoding="utf-8", newline="\n")
        print("TopDps.toc обновлён")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
