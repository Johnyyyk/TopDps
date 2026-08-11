local addon = TopDps
local Settings = addon.Settings
local Database = addon.Database

local originalApplyDefaults = Database.ApplyDefaults

local function GetPersistedGlobalEnabled()
    local persisted = TopDpsDB
    if type(persisted) ~= "table" then
        persisted = RpalTopDpsDB
    end

    if type(persisted) ~= "table" then
        return nil
    end

    local global = type(persisted.global) == "table" and persisted.global or persisted
    if type(global.enabled) ~= "boolean" then
        return nil
    end

    return global.enabled
end

function Database:ApplyDefaults()
    local hadRotationEnabled = type(TopDpsCharDB) == "table"
        and type(TopDpsCharDB.rotationEnabled) == "boolean"
    local hadPanelEnabled = type(TopDpsCharDB) == "table"
        and type(TopDpsCharDB.panelEnabled) == "boolean"
    local legacyGlobalEnabled = GetPersistedGlobalEnabled()

    local db = originalApplyDefaults(self)

    if addon.globalDb then
        addon.globalDb.enabled = nil
    end

    if legacyGlobalEnabled == false and addon.charDb then
        if not hadRotationEnabled then
            addon.charDb.rotationEnabled = false
        end

        if not hadPanelEnabled then
            addon.charDb.panelEnabled = false
        end
    end

    return db
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

function Settings:IsModeActive()
    if not addon.db then
        return false
    end

    local mode = addon.db.mode
    if mode == addon.MODE_DISABLED then
        return false
    end

    if mode == addon.MODE_EVERYWHERE then
        return true
    end

    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end

    if mode == addon.MODE_INSTANCES then
        return instanceType == "party" or instanceType == "raid"
    end

    if mode == addon.MODE_RAIDS then
        return instanceType == "raid"
    end

    return false
end

Settings.SetEnabled = nil
Settings.IsSpecEnabled = nil

function Settings:IsRotationEnabled()
    local provider = addon.SpecManager and addon.SpecManager:GetActive() or nil
    return addon.Database:EnsureCharacterRotationDefault(provider) ~= false
end

function Settings:SetRotationEnabled(enabled)
    if not addon.charDb then
        return
    end

    addon.charDb.rotationEnabled = enabled and true or false

    if not addon.charDb.rotationEnabled and addon.RecommendationPresenter then
        addon.RecommendationPresenter:Clear()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    if addon.MinimapButton then
        addon.MinimapButton:Refresh()
    end

    addon.Logger:Info("Rotation enabled for character: %s", tostring(addon.charDb.rotationEnabled))
end

function Settings:IsPanelEnabled()
    if not addon.charDb then
        return addon.DEFAULTS.showCooldownPanel
    end

    return addon.charDb.panelEnabled ~= false
end

function Settings:SetCooldownPanelEnabled(enabled)
    if not addon.charDb then
        return
    end

    addon.charDb.panelEnabled = enabled and true or false

    if not addon.charDb.panelEnabled and addon.CooldownPanel then
        addon.CooldownPanel:Hide()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    if addon.MinimapButton then
        addon.MinimapButton:Refresh()
    end

    addon.Logger:Info("Panel enabled for character: %s", tostring(addon.charDb.panelEnabled))
end
