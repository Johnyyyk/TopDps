local addon = TopDps
local Settings = addon.Settings

addon.COOLDOWN_PANEL_ICONS_PER_ROW_MIN = 1
addon.COOLDOWN_PANEL_ICONS_PER_ROW_MAX = 20
addon.COOLDOWN_PANEL_ICONS_PER_ROW_STEP = 1
addon.DEFAULTS.cooldownPanelIconsPerRow = addon.DEFAULTS.cooldownPanelIconsPerRow or {
    [addon.PANEL_CATEGORY_BUFFS] = 7,
    [addon.PANEL_CATEGORY_PROCS] = 7,
    [addon.PANEL_CATEGORY_ABILITIES] = 7,
    [addon.PANEL_CATEGORY_COOLDOWNS] = 7,
}

local function IsPanelCategory(category)
    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        if addon.PANEL_CATEGORY_ORDER[index] == category then
            return true
        end
    end

    return false
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function GetProfile(classToken, talentTab)
    if not addon.CooldownRegistry then
        return nil
    end

    return addon.CooldownRegistry:GetProfile(classToken, talentTab)
end

local function GetDefaultIconsPerRow(profile, category)
    local panelDefaults = profile and profile.panelDefaults or nil
    local iconsPerRow = panelDefaults and panelDefaults.iconsPerRow or nil
    if iconsPerRow and iconsPerRow[category] ~= nil then
        return iconsPerRow[category]
    end

    return addon.DEFAULTS.cooldownPanelIconsPerRow[category] or 7
end

function Settings:GetCooldownPanelIconsPerRow(category, classToken, talentTab)
    if not IsPanelCategory(category) then
        return 7
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    local profile = GetProfile(classToken, talentTab)
    local defaultValue = GetDefaultIconsPerRow(profile, category)

    if not specSettings then
        return defaultValue
    end

    if type(specSettings.iconsPerRow) ~= "table" then
        specSettings.iconsPerRow = {}
    end

    local value = tonumber(specSettings.iconsPerRow[category]) or defaultValue
    value = Clamp(
        math.floor(value + 0.5),
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MIN,
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MAX
    )
    specSettings.iconsPerRow[category] = value

    return value
end

function Settings:SetCooldownPanelIconsPerRow(category, value, classToken, talentTab)
    if not IsPanelCategory(category) then
        return
    end

    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return
    end

    if type(specSettings.iconsPerRow) ~= "table" then
        specSettings.iconsPerRow = {}
    end

    local profile = GetProfile(classToken, talentTab)
    local defaultValue = GetDefaultIconsPerRow(profile, category)
    specSettings.iconsPerRow[category] = Clamp(
        math.floor((tonumber(value) or defaultValue) + 0.5),
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MIN,
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MAX
    )

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end
end

local originalResetCooldownPanelSpecSettings = Settings.ResetCooldownPanelSpecSettings
function Settings:ResetCooldownPanelSpecSettings(classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    originalResetCooldownPanelSpecSettings(self, classToken, talentTab)

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if specSettings then
        specSettings.iconsPerRow = nil
    end

    if self:IsCurrentCooldownPanelSpec(classToken, talentTab) and addon.CooldownPanel then
        addon.CooldownPanel:InvalidateLayout()
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end
