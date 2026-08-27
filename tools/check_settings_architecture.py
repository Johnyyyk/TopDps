from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]

RETIRED_FILES = (
    "Core/DatabaseSchema.lua",
    "Core/FeatureSettings.lua",
    "Engine/RotationSettings.lua",
    "Engine/CooldownTrackerSettings.lua",
    "Engine/CooldownTrackerPresentation.lua",
    "Specs/SpecSettings.lua",
    "Presentation/CooldownPanelUxFixes.lua",
    "UI/MinimapControls.lua",
)

FORBIDDEN_PATTERNS = {
    r"\baddon\.db\.enabled\b": "глобальный enabled удалён",
    r"\baddon\.db\.showMinimap\b": "используйте addon.db.minimap.show",
    r"\baddon\.db\.minimapAngle\b": "используйте addon.db.minimap.angle",
    r"\baddon\.db\.highlightStyle\b": "используйте addon.db.rotation.highlightStyle",
    r"\baddon\.db\.cooldownLookahead\b": "используйте addon.db.rotation.cooldownLookahead",
    r"\baddon\.db\.showCenterIcons\b": "используйте addon.db.rotation.centerIcons.enabled",
    r"\baddon\.db\.centerIconsOpacity\b": "используйте addon.db.rotation.centerIcons.opacity",
    r"\baddon\.db\.centerIconsSize\b": "используйте addon.db.rotation.centerIcons.size",
    r"\baddon\.db\.showCooldownPanel\b": "используйте Settings:IsPanelEnabled()",
    r"\baddon\.db\.cooldownProcSoundsEnabled\b": "используйте addon.db.panel.procSoundsEnabled",
    r"\baddon\.db\.cooldownPanelLocked\b": "используйте addon.db.panel.locked",
    r"\baddon\.db\.cooldownPanelX\b": "используйте addon.db.panel.position.x",
    r"\baddon\.db\.cooldownPanelY\b": "используйте addon.db.panel.position.y",
    r"\baddon\.db\.cooldownPanelIconSize\b": "используйте addon.db.panel.iconSize",
    r"\baddon\.db\.cooldownPanelOpacity\b": "используйте addon.db.panel.opacity",
    r"\baddon\.db\.cooldownProcReadyAt\b": "используйте addon.db.panel.procReadyAt",
    r"\baddon\.db\.debugChatRecommendations\b": "используйте addon.db.debug.chatRecommendations",
    r"\baddon\.db\.debugLogging\b": "используйте addon.db.debug.logging",
    r"\baddon\.db\.debugLog\b": "используйте addon.db.debug.log",
    r"\.combatOnly\b": "legacy combatOnly удалён; используйте panel.visibility",
    r"\bcooldownPanelCombatOnly\b": "legacy cooldownPanelCombatOnly удалён; используйте cooldownPanelVisibility",
    r"\bRpalTopDpsDB\b": "legacy SavedVariables больше не поддерживается",
    r"\bCreateDbCompatibilityProxy\b": "compatibility proxy удалён",
    r"\bMigrate(?:GlobalSettings|SpecSettings|CooldownSettings)\b": "миграции старой БД удалены",
    r"\bSettings(?:\.|:)(?:SetEnabled|IsSpecEnabled)\b": "legacy API enabled удалён",
}


def iter_source_files():
    for path in ROOT.rglob("*.lua"):
        if ".git" not in path.parts:
            yield path

    yield ROOT / "TopDps.toc"


def main():
    errors = []

    for relative_path in RETIRED_FILES:
        path = ROOT / relative_path
        if path.exists():
            errors.append(f"Удалённый override-файл снова появился: {relative_path}")

    for path in iter_source_files():
        if not path.exists():
            continue

        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(ROOT)

        for pattern, message in FORBIDDEN_PATTERNS.items():
            for match in re.finditer(pattern, text):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{relative_path}:{line}: {message}")

    if errors:
        raise SystemExit("\n".join(errors))

    print("Архитектура настроек не содержит legacy-обращений")


if __name__ == "__main__":
    main()
