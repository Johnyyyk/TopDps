local addon = TopDps
local Database = addon:CreateModule("Database")

local SCHEMA_VERSION = 5

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

local function GetDefaultCooldownPanelVisibility(context)
    local defaults = addon.DEFAULTS.cooldownPanelVisibility or {}
    local mode = defaults[context]
    if IsValueInList(mode, addon.PANEL_VISIBILITY_ORDER) then
        return mode
    end

    return addon.PANEL_VISIBILITY_COMBAT_ONLY
end

local function NormalizeCooldownSpecSettings(settings, template)
    local visibility = EnsureTable(settings, "visibility")
    local templateVisibility = type(template.visibility) == "table" and template.visibility or {}
    local index

    for index = 1, #addon.PANEL_VISIBILITY_CONTEXT_ORDER do
        local context = addon.PANEL_VISIBILITY_CONTEXT_ORDER[index]
        if not IsValueInList(visibility[context], addon.PANEL_VISIBILITY_ORDER) then
            local templateMode = templateVisibility[context]
            if IsValueInList(templateMode, addon.PANEL_VISIBILITY_ORDER) then
                visibility[context] = templateMode
            else
                visibility[context] = GetDefaultCooldownPanelVisibility(context)
            end
        end
    end

    if type(settings.elementEnabled) ~= "table" then
        settings.elementEnabled = CopyTable(template.elementEnabled)
    end

    if type(settings.elementOrder) ~= "table" then
        settings.elementOrder = CopyTable(template.elementOrder)
    end
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

local function IsCurrentSchema(root)
    return type(root) == "table"
        and tonumber(root.schemaVersion) == SCHEMA_VERSION
        and type(root.global) == "table"
        and type(root.specs) == "table"
        and type(root.cooldownSpecs) == "table"
        and root.migration == nil
end

local function CreateRoot()
    return {
        schemaVersion = SCHEMA_VERSION,
        global = {},
        specs = {},
        cooldownSpecs = {},
        cooldownSpecTemplate = {
            panel = {},
        },
    }
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

    local specRoot = addon.cooldownSpecDb[key]
    if type(specRoot) ~= "table" then
        specRoot = { panel = {} }
        addon.cooldownSpecDb[key] = specRoot
    end

    local settings = EnsureTable(specRoot, "panel")
    NormalizeCooldownSpecSettings(settings, addon.cooldownSpecTemplate or {})

    return settings, key
end

function Database:ApplyDefaults()
    local root = TopDpsDB
    if not IsCurrentSchema(root) then
        root = CreateRoot()
    end

    root.schemaVersion = SCHEMA_VERSION
    root.global = type(root.global) == "table" and root.global or {}
    root.specs = type(root.specs) == "table" and root.specs or {}
    root.cooldownSpecs = type(root.cooldownSpecs) == "table" and root.cooldownSpecs or {}

    local templateRoot = root.cooldownSpecTemplate
    if type(templateRoot) ~= "table" then
        templateRoot = {}
        root.cooldownSpecTemplate = templateRoot
    end

    local template = EnsureTable(templateRoot, "panel")
    NormalizeCooldownSpecSettings(template, {})
    NormalizeGlobalSettings(root.global)

    local character = TopDpsCharDB
    if type(character) ~= "table" then
        character = {}
    end
    if type(character.rotationEnabled) ~= "boolean" then
        character.rotationEnabled = true
    end
    if type(character.panelEnabled) ~= "boolean" then
        character.panelEnabled = addon.DEFAULTS.showCooldownPanel
    end

    TopDpsDB = root
    TopDpsCharDB = character

    addon.savedVariables = root
    addon.db = root.global
    addon.charDb = character
    addon.specDb = root.specs
    addon.cooldownSpecDb = root.cooldownSpecs
    addon.cooldownSpecTemplate = template

    if addon.SpecRegistry then
        local providers = addon.SpecRegistry:GetAll()
        local index
        for index = 1, #providers do
            self:ApplyProviderDefaults(providers[index])
        end
    end

    return addon.db
end