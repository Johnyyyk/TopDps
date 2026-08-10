local addon = TopDps

addon.MODE_DISABLED = "DISABLED"
addon.MODE_EVERYWHERE = "EVERYWHERE"
addon.MODE_INSTANCES = "INSTANCES"
addon.MODE_RAIDS = "RAIDS"

addon.MODE_ORDER = {
    addon.MODE_DISABLED,
    addon.MODE_EVERYWHERE,
    addon.MODE_INSTANCES,
    addon.MODE_RAIDS,
}

addon.HIGHLIGHT_BLIZZARD = "BLIZZARD"
addon.HIGHLIGHT_CHEESE = "CHEESE"

addon.HIGHLIGHT_STYLE_ORDER = {
    addon.HIGHLIGHT_BLIZZARD,
    addon.HIGHLIGHT_CHEESE,
}

addon.COOLDOWN_LOOKAHEAD_MIN = 0
addon.COOLDOWN_LOOKAHEAD_MAX = 0.5
addon.COOLDOWN_LOOKAHEAD_STEP = 0.05

addon.COOLDOWN_PANEL_ICON_SIZE_MIN = 28
addon.COOLDOWN_PANEL_ICON_SIZE_MAX = 64
addon.COOLDOWN_PANEL_ICON_SIZE_STEP = 2
addon.COOLDOWN_PANEL_OPACITY_MIN = 0.3
addon.COOLDOWN_PANEL_OPACITY_MAX = 1
addon.COOLDOWN_PANEL_OPACITY_STEP = 0.05

addon.DEFAULTS = {
    enabled = true,
    showMinimap = true,
    minimapAngle = 135,
    mode = addon.MODE_EVERYWHERE,
    highlightStyle = addon.HIGHLIGHT_BLIZZARD,
    cooldownLookahead = 0.15,
    showCenterIcons = false,
    centerIconsOpacity = 0.85,
    centerIconsSize = 58,
    showCooldownPanel = true,
    cooldownPanelLocked = true,
    cooldownPanelX = 0,
    cooldownPanelY = -150,
    cooldownPanelIconSize = 44,
    cooldownPanelOpacity = 0.90,
    cooldownElementEnabled = {},
    cooldownElementOrder = {},
    cooldownProcReadyAt = {},
    debugChatRecommendations = false,
    debugLogging = false,
    debugLog = {},
}

addon.DEBUG_LOG_LIMIT = 400
addon.MINIMAP_BUTTON_RADIUS = 80
addon.CENTER_ICON_OFFSET = 230
addon.CENTER_ICON_SIZE_MIN = 40
addon.CENTER_ICON_SIZE_MAX = 96

addon.ACTION_BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
}
