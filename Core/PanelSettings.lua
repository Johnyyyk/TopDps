local addon = TopDps
local Settings = addon.Settings

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function IsPanelCategory(category)
    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        if addon.PANEL_CATEGORY_ORDER[index] == category then
            return true
        end
    end

    return false
end

function Settings:EnsureCooldownPanelUxDefaults()
    if not addon.db then
        return
    end

    if type(addon.db.cooldownPanelShowTimers) ~= "boolean" then
        addon.db.cooldownPanelShowTimers = addon.DEFAULTS.cooldownPanelShowTimers
    end

    local iconGap = tonumber(addon.db.cooldownPanelIconGap) or addon.DEFAULTS.cooldownPanelIconGap
    addon.db.cooldownPanelIconGap = Clamp(
        math.floor(iconGap + 0.5),
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX
    )

    local groupGap = tonumber(addon.db.cooldownPanelGroupGap) or addon.DEFAULTS.cooldownPanelGroupGap
    addon.db.cooldownPanelGroupGap = Clamp(
        math.floor(groupGap + 0.5),
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX
    )

    if type(addon.db.cooldownPanelGroupScale) ~= "table" then
        addon.db.cooldownPanelGroupScale = {}
    end

    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        local category = addon.PANEL_CATEGORY_ORDER[index]
        local defaultScale = addon.DEFAULTS.cooldownPanelGroupScale[category] or 1
        local scale = tonumber(addon.db.cooldownPanelGroupScale[category]) or defaultScale
        addon.db.cooldownPanelGroupScale[category] = Clamp(
            scale,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MAX
        )
    end
end

function Settings:AreCooldownPanelTimersShown()
    self:EnsureCooldownPanelUxDefaults()
    return addon.db and addon.db.cooldownPanelShowTimers ~= false
end

function Settings:SetCooldownPanelShowTimers(enabled)
    self:EnsureCooldownPanelUxDefaults()
    addon.db.cooldownPanelShowTimers = enabled and true or false

    if addon.CooldownPanel then
        addon.CooldownPanel:RefreshVisuals()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:IsCooldownPanelCategoryEnabled(category, classToken, talentTab)
    if not IsPanelCategory(category) then
        return true
    end

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return true
    end

    if type(specSettings.groupEnabled) ~= "table" then
        specSettings.groupEnabled = {}
    end

    local value = specSettings.groupEnabled[category]
    if value == nil then
        return true
    end

    return value == true
end

function Settings:SetCooldownPanelCategoryEnabled(category, enabled, classToken, talentTab)
    if not IsPanelCategory(category) then
        return
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    if type(specSettings.groupEnabled) ~= "table" then
        specSettings.groupEnabled = {}
    end

    specSettings.groupEnabled[category] = enabled and true or false

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:RefreshVisuals()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:SetCooldownPanelIconGap(gap)
    self:EnsureCooldownPanelUxDefaults()
    gap = Clamp(
        math.floor((tonumber(gap) or addon.DEFAULTS.cooldownPanelIconGap) + 0.5),
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX
    )
    addon.db.cooldownPanelIconGap = gap

    if addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end
end

function Settings:SetCooldownPanelGroupGap(gap)
    self:EnsureCooldownPanelUxDefaults()
    gap = Clamp(
        math.floor((tonumber(gap) or addon.DEFAULTS.cooldownPanelGroupGap) + 0.5),
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX
    )
    addon.db.cooldownPanelGroupGap = gap

    if addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end
end

function Settings:GetCooldownPanelCategoryScale(category)
    self:EnsureCooldownPanelUxDefaults()
    local defaultScale = addon.DEFAULTS.cooldownPanelGroupScale[category] or 1
    return addon.db
        and addon.db.cooldownPanelGroupScale
        and tonumber(addon.db.cooldownPanelGroupScale[category])
        or defaultScale
end

function Settings:SetCooldownPanelCategoryScale(category, scale)
    if not IsPanelCategory(category) then
        return
    end

    self:EnsureCooldownPanelUxDefaults()
    scale = Clamp(
        tonumber(scale) or addon.DEFAULTS.cooldownPanelGroupScale[category] or 1,
        addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
        addon.COOLDOWN_PANEL_GROUP_SCALE_MAX
    )
    addon.db.cooldownPanelGroupScale[category] = scale

    if addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end
end

local originalResetCooldownPanelSpecSettings = Settings.ResetCooldownPanelSpecSettings
function Settings:ResetCooldownPanelSpecSettings(classToken, talentTab)
    originalResetCooldownPanelSpecSettings(self, classToken, talentTab)

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if specSettings then
        specSettings.groupEnabled = {}
    end

    if addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:RefreshVisuals()
    end
end
