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

function Settings:SetEnabled(enabled)
    addon.db.enabled = enabled and true or false

    if not addon.db.enabled and addon.RecommendationPresenter then
        addon.RecommendationPresenter:Clear()
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
