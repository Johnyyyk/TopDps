from pathlib import Path
import re


def read(path):
    return Path(path).read_text(encoding="utf-8")


def extract(pattern, path, label):
    match = re.search(pattern, read(path), re.MULTILINE)
    if not match:
        raise SystemExit(f"Не удалось определить версию в {label}: {path}")

    return match.group(1).strip()


versions = {
    "TopDps.toc": extract(r"^## Version:\s*(\S+)\s*$", "TopDps.toc", "TOC"),
    "Core/Namespace.lua": extract(
        r'^addon\.VERSION\s*=\s*"([^"]+)"\s*$',
        "Core/Namespace.lua",
        "Namespace",
    ),
    "README.md": extract(
        r"^Текущая версия:\s*\*\*([^*]+)\*\*\s*$",
        "README.md",
        "README",
    ),
}

unique_versions = set(versions.values())
if len(unique_versions) != 1:
    details = ", ".join(f"{path}={version}" for path, version in versions.items())
    raise SystemExit(f"Версии проекта не совпадают: {details}")

print(f"Версия проекта: {next(iter(unique_versions))}")
