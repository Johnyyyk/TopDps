local addon = TopDps
local Database = addon:CreateModule("Database")

local SCHEMA_VERSION = 3

local function IsValueInList(value, list)
    local index
    for index = 1, #list do
        if value == list[index] then
            return true
        end
    end

    return false
end

local function CopyTable(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end

    local key, value
    for key, value in pairs(source) do
        result[key] = value
    end

    return result
end

local function NormalizeCooldownSpecSettings(settings, template)
    if type(settings.combatOnly) ~= "boolean" then
        if type(template.combatOnly) == "boolean" then
            settings.combatOnly = template.combatOnly
        else
            settings.combatOnly = addon.DEFAULTS.cooldownPanelCombatOnly
        end
    end

    if type(settings.elementEnabled) ~= "table" then
        settings.elementEnabled = CopyTable(template.elementEnabled)
    end

    if type(settings.elementOrder) ~= "table" then
        settings.elementOrder = CopyTable(template.elementOrder)
    end
end

local function ApplyGlobalDefaults(db)
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

    if type(db.cooldownLookahead) ~= "number" then
        db.cooldownLookahead = addon.DEFAULTS.cooldownLookahead
    end
    db.cooldownLookahead = math.max(
        addon.COOLDOWN_LOOKAHEAD_MIN,
        math.min(addon.COOLDOWN_LOOKAHEAD_MAX, db.cooldownLookahead)
    )

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

    if type(db.showCooldownPanel) ~= "boolean" then
        db.showCooldownPanel = addon.DEFAULTS.showCooldownPanel
    end

    if type(db.cooldownPanelLocked) ~= "boolean" then
        db.cooldownPanelLocked = addon.DEFAULTS.cooldownPanelLocked
    end

    if type(db.cooldownPanelX) ~= "number" then
        db.cooldownPanelX = addon.DEFAULTS.cooldownPanelX
    end

    if type(db.cooldownPanelY) ~= "number" then
        db.cooldownPanelY = addon.DEFAULTS.cooldownPanelY
    end

    if type(db.cooldownPanelIconSize) ~= "number" then
        db.cooldownPanelIconSize = addon.DEFAULTS.cooldownPanelIconSize
    end
    db.cooldownPanelIconSize = math.max(
        addon.COOLDOWN_PANEL_ICON_SIZE_MIN,
        math.min(addon.COOLDOWN_PANEL_ICON_SIZE_MAX, db.cooldownPanelIconSize)
    )

    if type(db.cooldownPanelOpacity) ~= "number" then
        db.cooldownPanelOpacity = addon.DEFAULTS.cooldownPanelOpacity
    end
    db.cooldownPanelOpacity = math.max(
        addon.COOLDOWN_PANEL_OPACITY_MIN,
        math.min(addon.COOLDOWN_PANEL_OPACITY_MAX, db.cooldownPanelOpacity)
    )

    if type(db.cooldownProcReadyAt) ~= "table" then
        db.cooldownProcReadyAt = {}
    end

    if type(db.debugChatRecommendations) ~= "boolean" then
        db.debugChatRecommendations = addon.DEFAULTS.debugChatRecommendations
    end

    if type(db.debugLogging) ~= "boolean" then
        db.debugLogging = addon.DEFAULTS.debugLogging
    end

    if type(db.debugLog) ~= "table" then
        db.debugLog = {}
    end
end

function Database:NormalizeSpecSetting(definition, value)
    if definition.type == "checkbox" then
        if type(value) ~= "boolean" then
            return definition.default and true or false
        end

        return value
    end

    if definition.type == "slider" then
        value = tonumber(value)
        if not value then
            value = definition.default
        end

        if definition.min then
            value = math.max(definition.min, value)
        end

        if definition.max then
            value = math.min(definition.max, value)
        end

        local step = definition.step
        if step and step > 0 then
            local base = definition.min or 0
            value = base + math.floor((value - base) / step + 0.5) * step

            if definition.min then
                value = math.max(definition.min, value)
            end

            if definition.max then
                value = math.min(definition.max, value)
            end
        end

        return value
    end

    if definition.type == "dropdown" then
        if not IsValueInList(value, definition.values or {}) then
            return definition.default
        end

        return value
    end

    if value == nil then
        return definition.default
    end

    return value
end

function Database:ApplyProviderDefaults(provider)
    if not provider or not addon.specDb then
        return nil
    end

    local specDb = addon.specDb[provider.id]
    if type(specDb) ~= "table" then
        specDb = {}
        addon.specDb[provider.id] = specDb
    end

    local definitions = provider:GetSettingsDefinition()
    local index
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.key then
            specDb[definition.key] = self:NormalizeSpecSetting(definition, specDb[definition.key])
        end
    end

    return specDb
end

function Database:GetSpecSettings(provider)
    if not provider or not addon.specDb then
        return nil
    end

    local specDb = addon.specDb[provider.id]
    if type(specDb) ~= "table" then
        return self:ApplyProviderDefaults(provider)
    end

    return specDb
end

function Database:GetCooldownSpecKey(classToken, talentTab)
    if not classToken then
        return nil
    end

    return tostring(classToken) .. ":" .. tostring(tonumber(talentTab) or 0)
end

function Database:GetCooldownSpecSettings(classToken, talentTab)
    if not addon.cooldownSpecDb then
        return nil
    end

    local key = self:GetCooldownSpecKey(classToken, talentTab)
    if not key then
        return nil
    end

    local settings = addon.cooldownSpecDb[key]
    if type(settings) ~= "table" then
        local template = addon.cooldownSpecTemplate or {}
        settings = {
            combatOnly = type(template.combatOnly) == "boolean"
                and template.combatOnly
                or addon.DEFAULTS.cooldownPanelCombatOnly,
            elementEnabled = CopyTable(template.elementEnabled),
            elementOrder = CopyTable(template.elementOrder),
        }
        addon.cooldownSpecDb[key] = settings
    end

    NormalizeCooldownSpecSettings(settings, addon.cooldownSpecTemplate or {})
    return settings, key
end

function Database:ApplyDefaults()
    local persisted = TopDpsDB

    if type(persisted) ~= "table" then
        -- Старое имя SavedVariables оставляем только для однократной миграции настроек.
        if type(RpalTopDpsDB) == "table" then
            persisted = RpalTopDpsDB
        else
            persisted = {}
        end
    end

    local root
    if type(persisted.global) == "table" or type(persisted.specs) == "table" then
        root = persisted
    else
        -- До schema v2 все глобальные настройки хранились непосредственно в TopDpsDB.
        root = {
            global = persisted,
            specs = {},
        }
    end

    if type(root.global) ~= "table" then
        root.global = {}
    end

    if type(root.specs) ~= "table" then
        root.specs = {}
    end

    if type(root.cooldownSpecs) ~= "table" then
        root.cooldownSpecs = {}
    end

    local previousSchemaVersion = tonumber(root.schemaVersion) or 1
    if previousSchemaVersion < 3 then
        root.cooldownSpecTemplate = {
            combatOnly = type(root.global.cooldownPanelCombatOnly) == "boolean"
                and root.global.cooldownPanelCombatOnly
                or addon.DEFAULTS.cooldownPanelCombatOnly,
            elementEnabled = CopyTable(root.global.cooldownElementEnabled),
            elementOrder = CopyTable(root.global.cooldownElementOrder),
        }

        root.global.cooldownPanelCombatOnly = nil
        root.global.cooldownElementEnabled = nil
        root.global.cooldownElementOrder = nil
    elseif type(root.cooldownSpecTemplate) ~= "table" then
        root.cooldownSpecTemplate = {}
    end

    NormalizeCooldownSpecSettings(root.cooldownSpecTemplate, {})
    root.schemaVersion = SCHEMA_VERSION

    TopDpsDB = root
    addon.savedVariables = root
    addon.db = root.global
    addon.specDb = root.specs
    addon.cooldownSpecDb = root.cooldownSpecs
    addon.cooldownSpecTemplate = root.cooldownSpecTemplate

    ApplyGlobalDefaults(addon.db)

    if addon.SpecRegistry then
        local providers = addon.SpecRegistry:GetAll()
        local index
        for index = 1, #providers do
            self:ApplyProviderDefaults(providers[index])
        end
    end

    return addon.db
end
