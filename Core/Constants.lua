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

addon.HIGHLIGHT_CHANNEL_PRIMARY = "PRIMARY"
addon.HIGHLIGHT_CHANNEL_NEXT_SWING = "NEXT_SWING"
addon.HIGHLIGHT_CHANNEL_ORDER = {
    addon.HIGHLIGHT_CHANNEL_PRIMARY,
    addon.HIGHLIGHT_CHANNEL_NEXT_SWING,
}
addon.HIGHLIGHT_CHANNEL_APPEARANCE = {
    [addon.HIGHLIGHT_CHANNEL_PRIMARY] = {
        key = addon.HIGHLIGHT_CHANNEL_PRIMARY,
    },
    [addon.HIGHLIGHT_CHANNEL_NEXT_SWING] = {
        key = addon.HIGHLIGHT_CHANNEL_NEXT_SWING,
        color = { r = 0.06, g = 0.50, b = 1.00 },
    },
}

addon.PANEL_CATEGORY_BUFFS = "BUFFS"
addon.PANEL_CATEGORY_PROCS = "PROCS"
addon.PANEL_CATEGORY_ABILITIES = "ABILITIES"
addon.PANEL_CATEGORY_COOLDOWNS = "COOLDOWNS"

addon.PANEL_CATEGORY_ORDER = {
    addon.PANEL_CATEGORY_BUFFS,
    addon.PANEL_CATEGORY_PROCS,
    addon.PANEL_CATEGORY_ABILITIES,
    addon.PANEL_CATEGORY_COOLDOWNS,
}

addon.PANEL_MAIN_CATEGORY_ORDER = {
    addon.PANEL_CATEGORY_PROCS,
    addon.PANEL_CATEGORY_ABILITIES,
    addon.PANEL_CATEGORY_COOLDOWNS,
}

addon.PANEL_BUFF_SIDE_LEFT = "LEFT"
addon.PANEL_BUFF_SIDE_RIGHT = "RIGHT"
addon.PANEL_BUFF_SIDE_ORDER = {
    addon.PANEL_BUFF_SIDE_LEFT,
    addon.PANEL_BUFF_SIDE_RIGHT,
}

addon.PANEL_VISIBILITY_ALWAYS = "ALWAYS"
addon.PANEL_VISIBILITY_COMBAT_ONLY = "COMBAT_ONLY"
addon.PANEL_VISIBILITY_ORDER = {
    addon.PANEL_VISIBILITY_ALWAYS,
    addon.PANEL_VISIBILITY_COMBAT_ONLY,
}

addon.PANEL_VISIBILITY_CONTEXT_WORLD = "world"
addon.PANEL_VISIBILITY_CONTEXT_PVE_INSTANCE = "pveInstance"
addon.PANEL_VISIBILITY_CONTEXT_ORDER = {
    addon.PANEL_VISIBILITY_CONTEXT_WORLD,
    addon.PANEL_VISIBILITY_CONTEXT_PVE_INSTANCE,
}

addon.PANEL_BEHAVIOR_ALWAYS = "ALWAYS"
addon.PANEL_BEHAVIOR_ACTIVE_ONLY = "ACTIVE_ONLY"
addon.PANEL_BEHAVIOR_REQUIRED_BUFF = "REQUIRED_BUFF"
addon.PANEL_BEHAVIOR_SELECTABLE_BUFF = "SELECTABLE_BUFF"
addon.PANEL_BEHAVIOR_REQUIRED_STATE = "REQUIRED_STATE"

addon.REFRESH_LEAD_CAST_TIME = "CAST_TIME"

addon.COOLDOWN_LOOKAHEAD_MIN = 0
addon.COOLDOWN_LOOKAHEAD_MAX = 0.75
addon.COOLDOWN_LOOKAHEAD_STEP = 0.05

addon.COOLDOWN_PANEL_ICON_SIZE_MIN = 28
addon.COOLDOWN_PANEL_ICON_SIZE_MAX = 64
addon.COOLDOWN_PANEL_ICON_SIZE_STEP = 2
addon.COOLDOWN_PANEL_OPACITY_MIN = 0.3
addon.COOLDOWN_PANEL_OPACITY_MAX = 1
addon.COOLDOWN_PANEL_OPACITY_STEP = 0.05
addon.COOLDOWN_PANEL_GROUP_SCALE_MIN = 0.6
addon.COOLDOWN_PANEL_GROUP_SCALE_MAX = 1.5
addon.COOLDOWN_PANEL_GROUP_SCALE_STEP = 0.05
addon.COOLDOWN_PANEL_ICON_GAP_MIN = 0
addon.COOLDOWN_PANEL_ICON_GAP_MAX = 12
addon.COOLDOWN_PANEL_ICON_GAP_STEP = 1
addon.COOLDOWN_PANEL_GROUP_GAP_MIN = 2
addon.COOLDOWN_PANEL_GROUP_GAP_MAX = 28
addon.COOLDOWN_PANEL_GROUP_GAP_STEP = 1
addon.COOLDOWN_PANEL_WARNING_SCALE = 1.7

addon.DEFAULTS = {
    showMinimap = true,
    minimapAngle = 135,
    mode = addon.MODE_EVERYWHERE,
    highlightStyle = addon.HIGHLIGHT_BLIZZARD,
    cooldownLookahead = 0.5,
    showCenterIcons = false,
    centerIconsOpacity = 0.85,
    centerIconsSize = 58,
    showCooldownPanel = true,
    cooldownProcSoundsEnabled = true,
    cooldownPanelShowTimers = true,
    cooldownPanelVisibility = {
        [addon.PANEL_VISIBILITY_CONTEXT_WORLD] = addon.PANEL_VISIBILITY_COMBAT_ONLY,
        [addon.PANEL_VISIBILITY_CONTEXT_PVE_INSTANCE] = addon.PANEL_VISIBILITY_ALWAYS,
    },
    cooldownPanelLocked = true,
    cooldownPanelX = 0,
    cooldownPanelY = -115,
    cooldownPanelIconSize = 36,
    cooldownPanelOpacity = 0.90,
    cooldownPanelIconGap = 3,
    cooldownPanelGroupGap = 12,
    cooldownPanelBuffSide = addon.PANEL_BUFF_SIDE_LEFT,
    cooldownPanelGroupOrder = {
        addon.PANEL_CATEGORY_PROCS,
        addon.PANEL_CATEGORY_ABILITIES,
        addon.PANEL_CATEGORY_COOLDOWNS,
    },
    cooldownPanelGroupScale = {
        [addon.PANEL_CATEGORY_BUFFS] = 1.00,
        [addon.PANEL_CATEGORY_PROCS] = 1.20,
        [addon.PANEL_CATEGORY_ABILITIES] = 0.80,
        [addon.PANEL_CATEGORY_COOLDOWNS] = 1.10,
    },
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
    "BonusActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
}
