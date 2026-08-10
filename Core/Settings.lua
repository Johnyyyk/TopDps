local addon = TopDps
local Settings = addon:CreateModule("Settings")

local function IsValueInList(value, list)
    local index
    for index = 1, #list do
        if value == list[index] then
            return true
        end
    end

    return false
end

function Settings:IsModeActive()
    if not addon.db or not addon.db.enabled then
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

function Settings:GetSpecSettings(provider)
    if not addon.Database then
        return nil
    end

    return addon.Database:GetSpecSettings(provider)
end

function Settings:GetSpecSetting(provider, key)
    if not provider then
        return nil
    end

    local specDb = self:GetSpecSettings(provider)
    if not specDb then
        return nil
    end

    return specDb[key]
end

function Settings:SetSpecSetting(provider, key, value)
    if not provider then
        return
    end

    local definition = provider:GetSettingDefinition(key)
    if not definition then
        return
    end

    local specDb = self:GetSpecSettings(provider)
    if not specDb then
        return
    end

    local normalized = addon.Database:NormalizeSpecSetting(definition, value)
    if specDb[key] == normalized then
        return
    end

    specDb[key] = normalized

    if addon.RecommendationPresenter then
        addon.RecommendationPresenter:Clear()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    addon.Logger:Info(
        "Specialization setting changed: provider=%s, key=%s, value=%s",
        tostring(provider.id),
        tostring(key),
        tostring(normalized)
    )
end

function Settings:IsSpecEnabled(provider)
    if not provider then
        return false
    end

    local enabled = self:GetSpecSetting(provider, "enabled")
    if enabled == nil then
        return true
    end

    return enabled == true
end

function Settings:ResolveCooldownPanelSpec(classToken, talentTab)
    if not classToken then
        classToken = addon.SpecManager and addon.SpecManager.classToken or nil
        if not classToken then
            local _
            _, classToken = UnitClass("player")
        end
    end

    if talentTab == nil then
        talentTab = addon.SpecManager and addon.SpecManager.talentTab or nil
    end

    return classToken, talentTab
end

function Settings:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not addon.Database then
        return nil
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    return addon.Database:GetCooldownSpecSettings(classToken, talentTab)
end

function Settings:IsCurrentCooldownPanelSpec(classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)

    local currentClass = addon.SpecManager and addon.SpecManager.classToken or nil
    local currentTalentTab = addon.SpecManager and addon.SpecManager.talentTab or nil

    return classToken ~= nil
        and talentTab ~= nil
        and classToken == currentClass
        and talentTab == currentTalentTab
end

function Settings:SetEnabled(enabled)
    addon.db.enabled = enabled and true or false

    if not addon.db.enabled then
        if addon.RecommendationPresenter then
            addon.RecommendationPresenter:Clear()
        end

        if addon.CooldownPanel then
            addon.CooldownPanel:Hide()
        end
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    if addon.MinimapButton then
        addon.MinimapButton:Refresh()
    end

    addon.Logger:Info("Addon enabled: %s", tostring(addon.db.enabled))
end

function Settings:SetMode(mode, silent)
    if not IsValueInList(mode, addon.MODE_ORDER) then
        return
    end

    addon.db.mode = mode

    if addon.RecommendationPresenter then
        addon.RecommendationPresenter:Clear()
    end

    if addon.CooldownPanel and not self:IsModeActive() then
        addon.CooldownPanel:Hide()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    if not silent and DEFAULT_CHAT_FRAME then
        local modeText = addon.L["MODE_" .. mode] or mode
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("|cffffd200%s:|r %s", addon.NAME, string.format(addon.L.MODE_CHANGED, modeText))
        )
    end

    addon.Logger:Info("Mode changed: %s", mode)
end

function Settings:SetHighlightStyle(style)
    if not IsValueInList(style, addon.HIGHLIGHT_STYLE_ORDER) then
        return
    end

    if addon.db.highlightStyle == style then
        return
    end

    if addon.HighlightManager then
        addon.HighlightManager:StopAll()
    end

    addon.db.highlightStyle = style

    if addon.RecommendationPresenter then
        addon.RecommendationPresenter:RefreshHighlights()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    addon.Logger:Info("Highlight style changed: %s", style)
end

function Settings:SetCooldownLookahead(seconds)
    seconds = tonumber(seconds) or addon.DEFAULTS.cooldownLookahead
    seconds = math.max(addon.COOLDOWN_LOOKAHEAD_MIN, math.min(addon.COOLDOWN_LOOKAHEAD_MAX, seconds))
    addon.db.cooldownLookahead = seconds
end

function Settings:SetCenterIconsEnabled(enabled)
    addon.db.showCenterIcons = enabled and true or false

    if addon.CenterIcons then
        addon.CenterIcons:Refresh()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:SetCenterIconsOpacity(opacity)
    opacity = tonumber(opacity) or addon.DEFAULTS.centerIconsOpacity
    opacity = math.max(0.2, math.min(1, opacity))
    addon.db.centerIconsOpacity = opacity

    if addon.CenterIcons then
        addon.CenterIcons:SetOpacity(opacity)
    end
end

function Settings:SetCenterIconsSize(size)
    size = tonumber(size) or addon.DEFAULTS.centerIconsSize
    size = math.floor(size + 0.5)
    size = math.max(addon.CENTER_ICON_SIZE_MIN, math.min(addon.CENTER_ICON_SIZE_MAX, size))
    addon.db.centerIconsSize = size

    if addon.CenterIcons then
        addon.CenterIcons:ApplyLayout()
    end
end

function Settings:SetCooldownPanelEnabled(enabled)
    addon.db.showCooldownPanel = enabled and true or false

    if not addon.db.showCooldownPanel and addon.CooldownPanel then
        addon.CooldownPanel:Hide()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:IsCooldownPanelCombatOnly(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return addon.DEFAULTS.cooldownPanelCombatOnly
    end

    return specSettings.combatOnly == true
end

function Settings:SetCooldownPanelCombatOnly(combatOnly, classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.combatOnly = combatOnly and true or false

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:ResetCooldownPanelSpecSettings(classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.combatOnly = addon.DEFAULTS.cooldownPanelCombatOnly
    specSettings.elementEnabled = {}
    specSettings.elementOrder = {}

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownTracker then
        addon.CooldownTracker:RefreshConfiguration()
    elseif addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end
end

function Settings:SetCooldownPanelLocked(locked)
    addon.db.cooldownPanelLocked = locked and true or false

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLockState()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:SetCooldownPanelPosition(x, y)
    addon.db.cooldownPanelX = tonumber(x) or addon.DEFAULTS.cooldownPanelX
    addon.db.cooldownPanelY = tonumber(y) or addon.DEFAULTS.cooldownPanelY

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLayout()
    end
end

function Settings:SetCooldownPanelIconSize(size)
    size = tonumber(size) or addon.DEFAULTS.cooldownPanelIconSize
    size = math.floor(size + 0.5)
    size = math.max(
        addon.COOLDOWN_PANEL_ICON_SIZE_MIN,
        math.min(addon.COOLDOWN_PANEL_ICON_SIZE_MAX, size)
    )
    addon.db.cooldownPanelIconSize = size

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLayout()
    end
end

function Settings:SetCooldownPanelOpacity(opacity)
    opacity = tonumber(opacity) or addon.DEFAULTS.cooldownPanelOpacity
    opacity = math.max(
        addon.COOLDOWN_PANEL_OPACITY_MIN,
        math.min(addon.COOLDOWN_PANEL_OPACITY_MAX, opacity)
    )
    addon.db.cooldownPanelOpacity = opacity

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLayout()
    end
end

function Settings:IsCooldownElementEnabled(settingId, defaultEnabled, classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings or type(specSettings.elementEnabled) ~= "table" then
        return defaultEnabled ~= false
    end

    local value = specSettings.elementEnabled[settingId]
    if value == nil then
        return defaultEnabled ~= false
    end

    return value == true
end

function Settings:SetCooldownElementEnabled(settingId, enabled, classToken, talentTab)
    if not settingId then
        return
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.elementEnabled[settingId] = enabled and true or false

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownTracker then
        addon.CooldownTracker:RefreshConfiguration()
    elseif addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end
end

function Settings:GetCooldownElementOrder(settingId, defaultOrder, classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings or type(specSettings.elementOrder) ~= "table" then
        return tonumber(defaultOrder) or 100
    end

    return tonumber(specSettings.elementOrder[settingId]) or tonumber(defaultOrder) or 100
end

function Settings:SetCooldownElementOrder(settingId, order, classToken, talentTab)
    if not settingId then
        return
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.elementOrder[settingId] = tonumber(order)

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownTracker then
        addon.CooldownTracker:RefreshConfiguration()
    elseif addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end
end