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

addon.DEFAULTS = {
    enabled = true,
    showMinimap = true,
    minimapAngle = 135,
    mode = addon.MODE_EVERYWHERE,
    highlightStyle = addon.HIGHLIGHT_BLIZZARD,
    showCenterIcons = false,
    centerIconsOpacity = 0.85,
    centerIconsSize = 58,
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
