local addon = TopDps

if GetLocale() == "ruRU" then
    addon.L.ROTATION_GENERAL_SETTINGS = "Общие настройки ротации"
    addon.L.ROTATION_ENABLED = "Включить ротацию для этого персонажа"
    addon.L.ROTATION_BEHAVIOR_SETTINGS = "Поведение ротации"
    addon.L.ROTATION_USE_MOVEMENT_PRIORITY = "Учитывать движение в ротации"
    addon.L.COOLDOWN_PANEL_ENABLED = "Включить панель для этого персонажа"
    addon.L.MINIMAP_LEFT_CLICK = "ЛКМ: быстрое управление"
else
    addon.L.ROTATION_GENERAL_SETTINGS = "General rotation settings"
    addon.L.ROTATION_ENABLED = "Enable rotation for this character"
    addon.L.ROTATION_BEHAVIOR_SETTINGS = "Rotation behavior"
    addon.L.ROTATION_USE_MOVEMENT_PRIORITY = "Use movement-aware rotation"
    addon.L.COOLDOWN_PANEL_ENABLED = "Enable panel for this character"
    addon.L.MINIMAP_LEFT_CLICK = "Left-click: quick controls"
end
