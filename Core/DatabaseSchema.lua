local addon = TopDps
local Database = addon.Database

local SCHEMA_VERSION = 4

local function IsValueInList(value, list)
    local index
    for index = 1, #list do
        if value == list[index] then
            return true
        end
    end

    return false
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
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

local function EnsureTable(parent, key)
    local value = parent[key]
    if type(value) ~= "table" then
        value = {}
        parent[key] = value
    end

    return value
end

local function MoveValue(source, sourceKey, destination, destinationKey)
    if destination[destinationKey] == nil and source[sourceKey] ~= nil then
        destination[destinationKey] = source[sourceKey]
    end

    source[sourceKey] = nil
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

local function MigrateGlobalSettings(root)
    local global = EnsureTable(root, "global")
    local minimap = EnsureTable(global, "minimap")
    local rotation = EnsureTable(global, "rotation")
    local centerIcons = EnsureTable(rotation, "centerIcons")
    local panel = EnsureTable(global, "panel")
    local position = EnsureTable(panel, "position")
    local debug = EnsureTable(global, "debug")
    local migration = EnsureTable(root, "migration")

    if migration.panelEnabledDefault == nil and type(global.showCooldownPanel) == "boolean" then
        migration.panelEnabledDefault = global.showCooldownPanel
    end

    MoveValue(global, "showMinimap", minimap, "show")
    MoveValue(global, "minimapAngle", minimap, "angle")

    MoveValue(global, "highlightStyle", rotation, "highlightStyle")
    MoveValue(global, "cooldownLookahead", rotation, "cooldownLookahead")
    MoveValue(global, "showCenterIcons", centerIcons, "enabled")
    MoveValue(global, "centerIconsOpacity", centerIcons, "opacity")
    MoveValue(global, "centerIconsSize", centerIcons, "size")

    global.showCooldownPanel = nil
    MoveValue(global, "cooldownProcSoundsEnabled", panel, "procSoundsEnabled")
    MoveValue(global, "cooldownPanelLocked", panel, "locked")
    MoveValue(global, "cooldownPanelX", position, "x")
    MoveValue(global, "cooldownPanelY", position, "y")
    MoveValue(global, "cooldownPanelIconSize", panel, "iconSize")
    MoveValue(global, "cooldownPanelOpacity", panel, "opacity")
    MoveValue(global, "cooldownProcReadyAt", panel, "procReadyAt")

    MoveValue(global, "debugChatRecommendations", debug, "chatRecommendations")
    MoveValue(global, "debugLogging", debug, "logging")
    MoveValue(global, "debugLog", debug, "log")

    return global
end

local function NormalizeGlobalSettings(global)
    if not IsValueInList(global.mode, addon.MODE_ORDER) then
        global.mode = addon.DEFAULTS.mode
    end

    local minimap = EnsureTable(global, "minimap")
    if type(minimap.show) ~= "boolean" then
        minimap.show = addon.DEFAULTS.showMinimap
    end
    if type(minimap.angle) ~= "number" then
        minimap.angle = addon.DEFAULTS.minimapAngle
    end

    local rotation = EnsureTable(global, "rotation")
    if not IsValueInList(rotation.highlightStyle, addon.HIGHLIGHT_STYLE_ORDER) then
        rotation.highlightStyle = addon.DEFAULTS.highlightStyle
    end
    if type(rotation.cooldownLookahead) ~= "number" then
        rotation.cooldownLookahead = addon.DEFAULTS.cooldownLookahead
    end
    rotation.cooldownLookahead = Clamp(
        rotation.cooldownLookahead,
        addon.COOLDOWN_LOOKAHEAD_MIN,
        addon.COOLDOWN_LOOKAHEAD_MAX
    )

    local centerIcons = EnsureTable(rotation, "centerIcons")
    if type(centerIcons.enabled) ~= "boolean" then
        centerIcons.enabled = addon.DEFAULTS.showCenterIcons
    end
    if type(centerIcons.opacity) ~= "number" then
        centerIcons.opacity = addon.DEFAULTS.centerIconsOpacity
    end
    centerIcons.opacity = Clamp(centerIcons.opacity, 0.2, 1)
    if type(centerIcons.size) ~= "number" then
        centerIcons.size = addon.DEFAULTS.centerIconsSize
    end
    centerIcons.size = Clamp(
        centerIcons.size,
        addon.CENTER_ICON_SIZE_MIN,
        addon.CENTER_ICON_SIZE_MAX
    )

    local panel = EnsureTable(global, "panel")
    if type(panel.procSoundsEnabled) ~= "boolean" then
        panel.procSoundsEnabled = addon.DEFAULTS.cooldownProcSoundsEnabled
    end
    if type(panel.locked) ~= "boolean" then
        panel.locked = addon.DEFAULTS.cooldownPanelLocked
    end
    if type(panel.iconSize) ~= "number" then
        panel.iconSize = addon.DEFAULTS.cooldownPanelIconSize
    end
    panel.iconSize = Clamp(
        panel.iconSize,
        addon.COOLDOWN_PANEL_ICON_SIZE_MIN,
        addon.COOLDOWN_PANEL_ICON_SIZE_MAX
    )
    if type(panel.opacity) ~= "number" then
        panel.opacity = addon.DEFAULTS.cooldownPanelOpacity
    end
    panel.opacity = Clamp(
        panel.opacity,
        addon.COOLDOWN_PANEL_OPACITY_MIN,
        addon.COOLDOWN_PANEL_OPACITY_MAX
    )
    if type(panel.procReadyAt) ~= "table" then
        panel.procReadyAt = {}
    end

    local position = EnsureTable(panel, "position")
    if type(position.x) ~= "number" then
        position.x = addon.DEFAULTS.cooldownPanelX
    end
    if type(position.y) ~= "number" then
        position.y = addon.DEFAULTS.cooldownPanelY
    end

    local debug = EnsureTable(global, "debug")
    if type(debug.chatRecommendations) ~= "boolean" then
        debug.chatRecommendations = addon.DEFAULTS.debugChatRecommendations
    end
    if type(debug.logging) ~= "boolean" then
        debug.logging = addon.DEFAULTS.debugLogging
    end
    if type(debug.log) ~= "table" then
        debug.log = {}
    end
end

local function MigrateSpecSettings(root)
    local migration = EnsureTable(root, "migration")
    local legacyRotation = EnsureTable(migration, "rotationEnabledBySpec")
    local providerId, settings

    for providerId, settings in pairs(root.specs) do
        if type(settings) ~= "table" then
            root.specs[providerId] = { rotation = {} }
        elseif type(settings.rotation) ~= "table" then
            local rotation = {}
            local key, value
            for key, value in pairs(settings) do
                if key ~= "enabled" then
                    rotation[key] = value
                end
            end

            if type(settings.enabled) == "boolean" and legacyRotation[providerId] == nil then
                legacyRotation[providerId] = settings.enabled
            end

            root.specs[providerId] = { rotation = rotation }
        else
            if type(settings.enabled) == "boolean" and legacyRotation[providerId] == nil then
                legacyRotation[providerId] = settings.enabled
            end
            if type(settings.rotation.enabled) == "boolean" and legacyRotation[providerId] == nil then
                legacyRotation[providerId] = settings.rotation.enabled
            end

            settings.enabled = nil
            settings.rotation.enabled = nil
        end
    end
end

local function WrapPanelSettings(settings)
    if type(settings) ~= "table" then
        return { panel = {} }
    end

    if type(settings.panel) == "table" then
        return settings
    end

    local panel = {}
    local key, value
    for key, value in pairs(settings) do
        panel[key] = value
    end

    return { panel = panel }
end

local function MigrateCooldownSettings(root)
    local key, settings
    for key, settings in pairs(root.cooldownSpecs) do
        root.cooldownSpecs[key] = WrapPanelSettings(settings)
    end

    root.cooldownSpecTemplate = WrapPanelSettings(root.cooldownSpecTemplate)
end

local function CreateDbCompatibilityProxy(global, character)
    local proxy = {}

    setmetatable(proxy, {
        __index = function(_, key)
            if key == "enabled" then
                return true
            elseif key == "mode" then
                return global.mode
            end

            if key == "showMinimap" then
                return global.minimap.show
            elseif key == "minimapAngle" then
                return global.minimap.angle
            elseif key == "highlightStyle" then
                return global.rotation.highlightStyle
            elseif key == "cooldownLookahead" then
                return global.rotation.cooldownLookahead
            elseif key == "showCenterIcons" then
                return global.rotation.centerIcons.enabled
            elseif key == "centerIconsOpacity" then
                return global.rotation.centerIcons.opacity
            elseif key == "centerIconsSize" then
                return global.rotation.centerIcons.size
            elseif key == "showCooldownPanel" then
                return character.panelEnabled
            elseif key == "cooldownProcSoundsEnabled" then
                return global.panel.procSoundsEnabled
            elseif key == "cooldownPanelLocked" then
                return global.panel.locked
            elseif key == "cooldownPanelX" then
                return global.panel.position.x
            elseif key == "cooldownPanelY" then
                return global.panel.position.y
            elseif key == "cooldownPanelIconSize" then
                return global.panel.iconSize
            elseif key == "cooldownPanelOpacity" then
                return global.panel.opacity
            elseif key == "cooldownProcReadyAt" then
                return global.panel.procReadyAt
            elseif key == "debugChatRecommendations" then
                return global.debug.chatRecommendations
            elseif key == "debugLogging" then
                return global.debug.logging
            elseif key == "debugLog" then
                return global.debug.log
            end

            return global[key]
        end,
        __newindex = function(_, key, value)
            if key == "enabled" then
                return
            elseif key == "mode" then
                global.mode = value
            elseif key == "showMinimap" then
                global.minimap.show = value
            elseif key == "minimapAngle" then
                global.minimap.angle = value
            elseif key == "highlightStyle" then
                global.rotation.highlightStyle = value
            elseif key == "cooldownLookahead" then
                global.rotation.cooldownLookahead = value
            elseif key == "showCenterIcons" then
                global.rotation.centerIcons.enabled = value
            elseif key == "centerIconsOpacity" then
                global.rotation.centerIcons.opacity = value
            elseif key == "centerIconsSize" then
                global.rotation.centerIcons.size = value
            elseif key == "showCooldownPanel" then
                character.panelEnabled = value and true or false
            elseif key == "cooldownProcSoundsEnabled" then
                global.panel.procSoundsEnabled = value
            elseif key == "cooldownPanelLocked" then
                global.panel.locked = value
            elseif key == "cooldownPanelX" then
                global.panel.position.x = value
            elseif key == "cooldownPanelY" then
                global.panel.position.y = value
            elseif key == "cooldownPanelIconSize" then
                global.panel.iconSize = value
            elseif key == "cooldownPanelOpacity" then
                global.panel.opacity = value
            elseif key == "cooldownProcReadyAt" then
                global.panel.procReadyAt = value
            elseif key == "debugChatRecommendations" then
                global.debug.chatRecommendations = value
            elseif key == "debugLogging" then
                global.debug.logging = value
            elseif key == "debugLog" then
                global.debug.log = value
            else
                global[key] = value
            end
        end,
    })

    return proxy
end

function Database:ApplyProviderDefaults(provider)
    if not provider or not addon.specDb then
        return nil
    end

    local specRoot = addon.specDb[provider.id]
    if type(specRoot) ~= "table" then
        specRoot = { rotation = {} }
        addon.specDb[provider.id] = specRoot
    end

    local rotation = EnsureTable(specRoot, "rotation")
    local definitions = provider:GetSettingsDefinition()
    local index
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.key then
            rotation[definition.key] = self:NormalizeSpecSetting(definition, rotation[definition.key])
        end
    end

    return rotation
end

function Database:GetSpecSettings(provider)
    if not provider or not addon.specDb then
        return nil
    end

    local specRoot = addon.specDb[provider.id]
    if type(specRoot) ~= "table" or type(specRoot.rotation) ~= "table" then
        return self:ApplyProviderDefaults(provider)
    end

    return specRoot.rotation
end

function Database:GetCooldownSpecSettings(classToken, talentTab)
    if not addon.cooldownSpecDb then
        return nil
    end

    local key = self:GetCooldownSpecKey(classToken, talentTab)
    if not key then
        return nil
    end

    local specRoot = addon.cooldownSpecDb[key]
    if type(specRoot) ~= "table" then
        specRoot = { panel = {} }
        addon.cooldownSpecDb[key] = specRoot
    end

    local settings = EnsureTable(specRoot, "panel")
    NormalizeCooldownSpecSettings(settings, addon.cooldownSpecTemplate or {})

    return settings, key
end

function Database:EnsureCharacterRotationDefault(provider)
    if not addon.charDb then
        return true
    end

    if type(addon.charDb.rotationEnabled) == "boolean" then
        return addon.charDb.rotationEnabled
    end

    local migration = addon.savedVariables and addon.savedVariables.migration or nil
    local legacyBySpec = migration and migration.rotationEnabledBySpec or nil
    local legacy = provider and legacyBySpec and legacyBySpec[provider.id] or nil

    if type(legacy) == "boolean" then
        addon.charDb.rotationEnabled = legacy
        return legacy
    end

    if provider or type(legacyBySpec) ~= "table" or next(legacyBySpec) == nil then
        addon.charDb.rotationEnabled = true
    end

    return true
end

function Database:ApplyDefaults()
    local persisted = TopDpsDB

    if type(persisted) ~= "table" then
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
        root = {
            global = persisted,
            specs = {},
        }
    end

    root.global = type(root.global) == "table" and root.global or {}
    root.specs = type(root.specs) == "table" and root.specs or {}
    root.cooldownSpecs = type(root.cooldownSpecs) == "table" and root.cooldownSpecs or {}

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
    end

    local global = MigrateGlobalSettings(root)
    MigrateSpecSettings(root)
    MigrateCooldownSettings(root)
    NormalizeGlobalSettings(global)

    local templateRoot = root.cooldownSpecTemplate
    NormalizeCooldownSpecSettings(templateRoot.panel, {})

    local character = TopDpsCharDB
    if type(character) ~= "table" then
        character = {}
    end

    local migration = EnsureTable(root, "migration")
    if type(character.panelEnabled) ~= "boolean" then
        if type(migration.panelEnabledDefault) == "boolean" then
            character.panelEnabled = migration.panelEnabledDefault
        else
            character.panelEnabled = addon.DEFAULTS.showCooldownPanel
        end
    end

    global.enabled = nil
    root.schemaVersion = SCHEMA_VERSION
    TopDpsDB = root
    TopDpsCharDB = character

    addon.savedVariables = root
    addon.globalDb = global
    addon.charDb = character
    addon.specDb = root.specs
    addon.cooldownSpecDb = root.cooldownSpecs
    addon.cooldownSpecTemplate = templateRoot.panel
    addon.db = CreateDbCompatibilityProxy(global, character)

    if addon.SpecRegistry then
        local providers = addon.SpecRegistry:GetAll()
        local index
        for index = 1, #providers do
            self:ApplyProviderDefaults(providers[index])
        end
    end

    return addon.db
end
