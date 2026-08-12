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

function Settings:IsRotationEnabled()
    return addon.charDb and addon.charDb.rotationEnabled == true
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
    return addon.charDb and addon.charDb.panelEnabled == true
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

function Settings:AreCooldownProcSoundsEnabled()
    if not addon.db or not addon.db.panel then
        return addon.DEFAULTS.cooldownProcSoundsEnabled
    end

    return addon.db.panel.procSoundsEnabled ~= false
end

function Settings:SetCooldownProcSoundsEnabled(enabled)
    addon.db.panel.procSoundsEnabled = enabled and true or false

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:IsCooldownProcSoundEnabled(settingId, defaultEnabled, classToken, talentTab)
    if not settingId then
        return false
    end

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return defaultEnabled ~= false
    end

    if type(specSettings.procSoundEnabled) ~= "table" then
        specSettings.procSoundEnabled = {}
    end

    local value = specSettings.procSoundEnabled[settingId]
    if value == nil then
        return defaultEnabled ~= false
    end

    return value == true
end

function Settings:SetCooldownProcSoundEnabled(settingId, enabled, classToken, talentTab)
    if not settingId then
        return
    end

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    if type(specSettings.procSoundEnabled) ~= "table" then
        specSettings.procSoundEnabled = {}
    end

    specSettings.procSoundEnabled[settingId] = enabled and true or false

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
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

    if addon.db.rotation.highlightStyle == style then
        return
    end

    if addon.HighlightManager then
        addon.HighlightManager:StopAll()
    end

    addon.db.rotation.highlightStyle = style

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
    addon.db.rotation.cooldownLookahead = seconds
end

function Settings:SetCenterIconsEnabled(enabled)
    addon.db.rotation.centerIcons.enabled = enabled and true or false

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
    addon.db.rotation.centerIcons.opacity = opacity

    if addon.CenterIcons then
        addon.CenterIcons:SetOpacity(opacity)
    end
end

function Settings:SetCenterIconsSize(size)
    size = tonumber(size) or addon.DEFAULTS.centerIconsSize
    size = math.floor(size + 0.5)
    size = math.max(addon.CENTER_ICON_SIZE_MIN, math.min(addon.CENTER_ICON_SIZE_MAX, size))
    addon.db.rotation.centerIcons.size = size

    if addon.CenterIcons then
        addon.CenterIcons:ApplyLayout()
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
    specSettings.procSoundEnabled = {}
    specSettings.groupEnabled = {}
    specSettings.showTimers = nil
    specSettings.iconGap = nil
    specSettings.groupGap = nil
    specSettings.groupScale = nil
    specSettings.buffSide = nil
    specSettings.groupOrder = nil
    specSettings.iconsPerRow = nil

    if self.EnsureCooldownPanelUxDefaults then
        self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    end

    if addon.ProcSoundAlerts then
        addon.ProcSoundAlerts:Reset()
    end

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownTracker then
        addon.CooldownTracker:RefreshConfiguration()
        if addon.CooldownPanel then
            addon.CooldownPanel:InvalidateLayout()
            addon.CooldownPanel:RefreshVisuals()
        end
    elseif addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:SetCooldownPanelLocked(locked)
    addon.db.panel.locked = locked and true or false

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLockState()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:SetCooldownPanelPosition(x, y)
    addon.db.panel.position.x = tonumber(x) or addon.DEFAULTS.cooldownPanelX
    addon.db.panel.position.y = tonumber(y) or addon.DEFAULTS.cooldownPanelY

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
    addon.db.panel.iconSize = size

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
    addon.db.panel.opacity = opacity

    if addon.CooldownPanel then
        addon.CooldownPanel:ApplyLayout()
    end
end

function Settings:IsCooldownElementEnabled(settingId, defaultEnabled, classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if specSettings and type(specSettings.elementEnabled) == "table" then
        local value = specSettings.elementEnabled[settingId]
        if value ~= nil then
            return value == true
        end
    end

    local profile = addon.CooldownRegistry and addon.CooldownRegistry:GetProfile(classToken, talentTab) or nil
    local defaults = profile and profile.defaultElementEnabled or nil
    local definition = addon.CooldownRegistry
        and addon.CooldownRegistry.entriesBySettingId
        and addon.CooldownRegistry.entriesBySettingId[settingId]
        or nil
    local entryId = definition and definition.id or nil

    if defaults and entryId then
        if defaults[entryId] ~= nil then
            return defaults[entryId] == true
        end

        if defaults.__allowlist == true then
            return false
        end
    end

    return defaultEnabled ~= false
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
