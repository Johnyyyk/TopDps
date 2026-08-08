local addon = TopDps
local Database = addon:CreateModule("Database")

local function IsValueInList(value, list)
    local index
    for index = 1, #list do
        if value == list[index] then
            return true
        end
    end

    return false
end

function Database:ApplyDefaults()
    if type(TopDpsDB) ~= "table" then
        -- Старое имя SavedVariables оставляем только для однократной миграции настроек.
        if type(RpalTopDpsDB) == "table" then
            TopDpsDB = RpalTopDpsDB
        else
            TopDpsDB = {}
        end
    end

    local db = TopDpsDB

    if type(db.enabled) ~= "boolean" then
        db.enabled = addon.DEFAULTS.enabled
    end

    if type(db.showMinimap) ~= "boolean" then
        db.showMinimap = addon.DEFAULTS.showMinimap
    end

    if type(db.minimapAngle) ~= "number" then
        db.minimapAngle = addon.DEFAULTS.minimapAngle
    end

    if not IsValueInList(db.mode, addon.MODE_ORDER) then
        db.mode = addon.DEFAULTS.mode
    end

    if not IsValueInList(db.highlightStyle, addon.HIGHLIGHT_STYLE_ORDER) then
        db.highlightStyle = addon.DEFAULTS.highlightStyle
    end

    if type(db.showCenterIcons) ~= "boolean" then
        db.showCenterIcons = addon.DEFAULTS.showCenterIcons
    end

    if type(db.centerIconsOpacity) ~= "number" then
        db.centerIconsOpacity = addon.DEFAULTS.centerIconsOpacity
    end
    db.centerIconsOpacity = math.max(0.2, math.min(1, db.centerIconsOpacity))

    if type(db.centerIconsSize) ~= "number" then
        db.centerIconsSize = addon.DEFAULTS.centerIconsSize
    end
    db.centerIconsSize = math.max(
        addon.CENTER_ICON_SIZE_MIN,
        math.min(addon.CENTER_ICON_SIZE_MAX, db.centerIconsSize)
    )

    if type(db.debugChatRecommendations) ~= "boolean" then
        db.debugChatRecommendations = addon.DEFAULTS.debugChatRecommendations
    end

    if type(db.debugLogging) ~= "boolean" then
        db.debugLogging = addon.DEFAULTS.debugLogging
    end

    if type(db.debugLog) ~= "table" then
        db.debugLog = {}
    end

    addon.db = db
    return db
end
