#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "TopDps.toc"
COOLDOWNS = ROOT / "Cooldowns"

DPS_PROVIDERS = (
    "Specs/DeathKnight/Blood.lua",
    "Specs/DeathKnight/Frost.lua",
    "Specs/DeathKnight/Unholy.lua",
    "Specs/Druid/Balance.lua",
    "Specs/Druid/Feral.lua",
    "Specs/Hunter/BeastMastery.lua",
    "Specs/Hunter/Marksmanship.lua",
    "Specs/Hunter/Survival.lua",
    "Specs/Mage/Arcane.lua",
    "Specs/Mage/Fire.lua",
    "Specs/Mage/Frost.lua",
    "Specs/Paladin/Retribution.lua",
    "Specs/Priest/Shadow.lua",
    "Specs/Rogue/Assassination.lua",
    "Specs/Rogue/Combat.lua",
    "Specs/Rogue/Subtlety.lua",
    "Specs/Shaman/Elemental.lua",
    "Specs/Shaman/Enhancement.lua",
    "Specs/Warlock/Affliction.lua",
    "Specs/Warlock/Demonology.lua",
    "Specs/Warlock/Destruction.lua",
    "Specs/Warrior/Arms.lua",
    "Specs/Warrior/Fury.lua",
)

PANEL_ONLY_PROVIDER_PATHS = (
    "Specs/Druid/Restoration.lua",
    "Specs/Paladin/Holy.lua",
    "Specs/Paladin/Protection.lua",
    "Specs/Priest/Discipline.lua",
    "Specs/Priest/Holy.lua",
    "Specs/Shaman/Restoration.lua",
    "Specs/Warrior/Protection.lua",
)

EXPECTED_PANELS = {
    ("DeathKnight", "BLOOD"),
    ("DeathKnight", "FROST"),
    ("DeathKnight", "UNHOLY"),
    ("Druid", "BALANCE"),
    ("Druid", "FERAL"),
    ("Druid", "RESTORATION"),
    ("Hunter", "BEAST_MASTERY"),
    ("Hunter", "MARKSMANSHIP"),
    ("Hunter", "SURVIVAL"),
    ("Mage", "ARCANE"),
    ("Mage", "FIRE"),
    ("Mage", "FROST"),
    ("Paladin", "HOLY"),
    ("Paladin", "PROTECTION"),
    ("Paladin", "RETRIBUTION"),
    ("Priest", "DISCIPLINE"),
    ("Priest", "HOLY"),
    ("Priest", "SHADOW"),
    ("Rogue", "ASSASSINATION"),
    ("Rogue", "COMBAT"),
    ("Rogue", "SUBTLETY"),
    ("Shaman", "ELEMENTAL"),
    ("Shaman", "ENHANCEMENT"),
    ("Shaman", "RESTORATION"),
    ("Warlock", "AFFLICTION"),
    ("Warlock", "DEMONOLOGY"),
    ("Warlock", "DESTRUCTION"),
    ("Warrior", "ARMS"),
    ("Warrior", "FURY"),
    ("Warrior", "PROTECTION"),
}

CLASSES = (
    "DeathKnight",
    "Druid",
    "Hunter",
    "Mage",
    "Paladin",
    "Priest",
    "Rogue",
    "Shaman",
    "Warlock",
    "Warrior",
)


def fail(message: str) -> None:
    raise SystemExit(f"class coverage check failed: {message}")


def check_rotation_coverage() -> None:
    toc = TOC.read_text(encoding="utf-8").replace("\\", "/")

    for relative in DPS_PROVIDERS:
        if not (ROOT / relative).is_file():
            fail(f"missing DPS provider: {relative}")
        if relative not in toc:
            fail(f"DPS provider is not loaded by TOC: {relative}")

    for relative in PANEL_ONLY_PROVIDER_PATHS:
        if (ROOT / relative).exists() or relative in toc:
            fail(f"panel-only specialization unexpectedly has rotation provider: {relative}")

    if len(DPS_PROVIDERS) != 23:
        fail(f"expected 23 DPS providers, got {len(DPS_PROVIDERS)}")


def check_panel_coverage() -> None:
    profile_pattern = re.compile(r"RegisterProfile\s*\(\s*\{(.*?)\}\s*\)", re.DOTALL)
    talent_pattern = re.compile(
        r"talentTab\s*=\s*(?:addon\.)?([A-Za-z]+)\.TALENT_TABS\.([A-Z_]+)"
    )
    found: set[tuple[str, str]] = set()

    for path in COOLDOWNS.glob("*.lua"):
        if path.name.endswith("Defaults.lua"):
            continue
        text = path.read_text(encoding="utf-8")
        for block in profile_pattern.findall(text):
            match = talent_pattern.search(block)
            if match:
                found.add((match.group(1), match.group(2)))

    missing = sorted(EXPECTED_PANELS - found)
    unexpected = sorted(found - EXPECTED_PANELS)
    if missing:
        fail(f"missing panel profiles: {missing}")
    if unexpected:
        fail(f"unexpected panel profiles: {unexpected}")
    if len(found) != 30:
        fail(f"expected 30 panel profiles, got {len(found)}")


def class_for_defaults(path: Path) -> str:
    for class_name in CLASSES:
        if path.name.startswith(class_name):
            return class_name
    fail(f"cannot resolve class for defaults file: {path.name}")
    raise AssertionError("unreachable")


def check_default_allowlists() -> None:
    entry_pattern = re.compile(r'\bid\s*=\s*"([A-Za-z][A-Za-z0-9_]*)"')
    string_pattern = re.compile(r'"([A-Za-z][A-Za-z0-9_]*)"')

    available_by_class: dict[str, set[str]] = {}
    for class_name in CLASSES:
        available: set[str] = set()
        for path in COOLDOWNS.glob(f"{class_name}*.lua"):
            if path.name.endswith("Defaults.lua"):
                continue
            available.update(entry_pattern.findall(path.read_text(encoding="utf-8")))
        available_by_class[class_name] = available

    for path in COOLDOWNS.glob("*Defaults.lua"):
        class_name = class_for_defaults(path)
        strings = set(string_pattern.findall(path.read_text(encoding="utf-8")))
        unknown = sorted(strings - available_by_class[class_name])
        if unknown:
            fail(f"{path.name} references unknown panel ids: {unknown}")


def main() -> None:
    check_rotation_coverage()
    check_panel_coverage()
    check_default_allowlists()
    print("class coverage check passed: 23 DPS rotations, 30 panel profiles")


if __name__ == "__main__":
    main()
