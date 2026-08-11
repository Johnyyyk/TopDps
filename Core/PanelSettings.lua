local addon = TopDps
local Settings = addon.Settings

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function Contains(list, value)
    local index
    for index = 1, #list do
        if list[index] == value then
            return true
        end
    end

    return false
end

local function CopyArray(source)
    local result = {}
    local index
    for index = 1, #(source or {}) do
        result[index] = source[index]
    end

    return result
end

local function IsPanelCategory(category)
    return Contains(addon.PANEL_CATEGORY_ORDER, category)
end

local function IsMainPanelCategory(category)
    return Contains(addon.PANEL_MAIN_CATEGORY_ORDER, category)
end

local function IsBuffSide(side)
    return Contains(addon.PANEL_BUFF_SIDE_ORDER, side)
end

local function GetProfile(classToken, talentTab)
    if not addon.CooldownRegistry then
        return nil
    end

    return addon.CooldownRegistry:GetProfile(classToken, talentTab)
end

local function GetProfilePanelDefault(profile, key, fallback)
    local defaults = profile and profile.panelDefaults or nil
    if defaults and defaults[key] ~= nil then
        return defaults[key]
    end

    return fallback
end

local function GetDefaultGroupScale(profile, category)
    local profileDefaults = profile and profile.panelDefaults or nil
    local scales = profileDefaults and profileDefaults.groupScale or nil
    if scales and scales[category] ~= nil then
        return scales[category]
    end

    return addon.DEFAULTS.cooldownPanelGroupScale[category] or 1
end

local function NormalizeGroupOrder(order, profile)
    local defaults = GetProfilePanelDefault(
        profile,
        "groupOrder",
        addon.DEFAULTS.cooldownPanelGroupOrder or addon.PANEL_MAIN_CATEGORY_ORDER
    )
    local result = {}
    local used = {}
    local index

    if type(order) == "table" then
        for index = 1, #order do
            local category = order[index]
            if IsMainPanelCategory(category) and not used[category] then
                result[#result + 1] = category
                used[category] = true
            end
        end
    end

    for index = 1, #defaults do
        local category = defaults[index]
        if IsMainPanelCategory(category) and not used[category] then
            result[#result + 1] = category
            used[category] = true
        end
    end

    for index = 1, #addon.PANEL_MAIN_CATEGORY_ORDER do
        local category = addon.PANEL_MAIN_CATEGORY_ORDER[index]
        if not used[category] then
            result[#result + 1] = category
            used[category] = true
        end
    end

    return result
end

local function RefreshPanelForSpec(classToken, talentTab, refreshVisuals)
    if not Settings:IsCurrentCooldownPanelSpec(classToken, talentTab) or not addon.CooldownPanel then
        return
    end

    addon.CooldownPanel:InvalidateLayout()
    if refreshVisuals then
        addon.CooldownPanel:RefreshVisuals()
    else
        addon.CooldownPanel:ApplyLayout(addon.CooldownPanel.states)
    end
end

function Settings:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if not specSettings then
        return nil
    end

    local profile = GetProfile(classToken, talentTab)

    if type(specSettings.showTimers) ~= "boolean" then
        specSettings.showTimers = GetProfilePanelDefault(
            profile,
            "showTimers",
            addon.DEFAULTS.cooldownPanelShowTimers
        ) ~= false
    end

    local iconGap = tonumber(specSettings.iconGap)
        or GetProfilePanelDefault(profile, "iconGap", addon.DEFAULTS.cooldownPanelIconGap)
    specSettings.iconGap = Clamp(
        math.floor(iconGap + 0.5),
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX
    )

    local groupGap = tonumber(specSettings.groupGap)
        or GetProfilePanelDefault(profile, "groupGap", addon.DEFAULTS.cooldownPanelGroupGap)
    specSettings.groupGap = Clamp(
        math.floor(groupGap + 0.5),
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX
    )

    if type(specSettings.groupScale) ~= "table" then
        specSettings.groupScale = {}
    end

    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        local category = addon.PANEL_CATEGORY_ORDER[index]
        local defaultScale = GetDefaultGroupScale(profile, category)
        local scale = tonumber(specSettings.groupScale[category]) or defaultScale
        specSettings.groupScale[category] = Clamp(
            scale,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MAX
        )
    end

    if not IsBuffSide(specSettings.buffSide) then
        specSettings.buffSide = GetProfilePanelDefault(
            profile,
            "buffSide",
            addon.DEFAULTS.cooldownPanelBuffSide
        )
    end
    if not IsBuffSide(specSettings.buffSide) then
        specSettings.buffSide = addon.PANEL_BUFF_SIDE_LEFT
    end

    specSettings.groupOrder = NormalizeGroupOrder(specSettings.groupOrder, profile)

    if type(specSettings.groupEnabled) ~= "table" then
        specSettings.groupEnabled = {}
    end

    return specSettings, classToken, talentTab, profile
end

function Settings:AreCooldownPanelTimersShown(classToken, talentTab)
    local specSettings = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return addon.DEFAULTS.cooldownPanelShowTimers ~= false
    end

    return specSettings.showTimers ~= false
end

function Settings:SetCooldownPanelShowTimers(enabled, classToken, talentTab)
    local specSettings, resolvedClass, resolvedTalent = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.showTimers = enabled and true or false
    RefreshPanelForSpec(resolvedClass, resolvedTalent, true)

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:IsCooldownPanelCategoryEnabled(category, classToken, talentTab)
    if not IsPanelCategory(category) then
        return true
    end

    local specSettings, resolvedClass, resolvedTalent, profile = self:EnsureCooldownPanelUxDefaults(
        classToken,
        talentTab
    )
    if not specSettings then
        return true
    end

    local value = specSettings.groupEnabled[category]
    if value ~= nil then
        return value == true
    end

    local defaults = profile and profile.panelDefaults and profile.panelDefaults.groupEnabled or nil
    if defaults and defaults[category] ~= nil then
        return defaults[category] == true
    end

    return true
end

function Settings:SetCooldownPanelCategoryEnabled(category, enabled, classToken, talentTab)
    if not IsPanelCategory(category) then
        return
    end

    local specSettings, resolvedClass, resolvedTalent = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.groupEnabled[category] = enabled and true or false
    RefreshPanelForSpec(resolvedClass, resolvedTalent, true)

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:GetCooldownPanelIconGap(classToken, talentTab)
    local specSettings = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    return specSettings and specSettings.iconGap or addon.DEFAULTS.cooldownPanelIconGap
end

function Settings:SetCooldownPanelIconGap(gap, classToken, talentTab)
    local specSettings, resolvedClass, resolvedTalent = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.iconGap = Clamp(
        math.floor((tonumber(gap) or addon.DEFAULTS.cooldownPanelIconGap) + 0.5),
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX
    )
    RefreshPanelForSpec(resolvedClass, resolvedTalent, false)
end

function Settings:GetCooldownPanelGroupGap(classToken, talentTab)
    local specSettings = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    return specSettings and specSettings.groupGap or addon.DEFAULTS.cooldownPanelGroupGap
end

function Settings:SetCooldownPanelGroupGap(gap, classToken, talentTab)
    local specSettings, resolvedClass, resolvedTalent = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.groupGap = Clamp(
        math.floor((tonumber(gap) or addon.DEFAULTS.cooldownPanelGroupGap) + 0.5),
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX
    )
    RefreshPanelForSpec(resolvedClass, resolvedTalent, false)
end

function Settings:GetCooldownPanelCategoryScale(category, classToken, talentTab)
    local specSettings, _, _, profile = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not IsPanelCategory(category) then
        return 1
    end

    if specSettings and specSettings.groupScale then
        return tonumber(specSettings.groupScale[category]) or GetDefaultGroupScale(profile, category)
    end

    return GetDefaultGroupScale(profile, category)
end

function Settings:SetCooldownPanelCategoryScale(category, scale, classToken, talentTab)
    if not IsPanelCategory(category) then
        return
    end

    local specSettings, resolvedClass, resolvedTalent, profile = self:EnsureCooldownPanelUxDefaults(
        classToken,
        talentTab
    )
    if not specSettings then
        return
    end

    specSettings.groupScale[category] = Clamp(
        tonumber(scale) or GetDefaultGroupScale(profile, category),
        addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
        addon.COOLDOWN_PANEL_GROUP_SCALE_MAX
    )
    RefreshPanelForSpec(resolvedClass, resolvedTalent, false)
end

function Settings:GetCooldownPanelBuffSide(classToken, talentTab)
    local specSettings = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    return specSettings and specSettings.buffSide or addon.DEFAULTS.cooldownPanelBuffSide
end

function Settings:SetCooldownPanelBuffSide(side, classToken, talentTab)
    if not IsBuffSide(side) then
        return
    end

    local specSettings, resolvedClass, resolvedTalent = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return
    end

    specSettings.buffSide = side
    RefreshPanelForSpec(resolvedClass, resolvedTalent, false)

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

function Settings:GetCooldownPanelGroupOrder(classToken, talentTab)
    local specSettings = self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    if not specSettings then
        return CopyArray(addon.DEFAULTS.cooldownPanelGroupOrder)
    end

    return CopyArray(specSettings.groupOrder)
end

function Settings:SetCooldownPanelGroupOrder(order, classToken, talentTab)
    local specSettings, resolvedClass, resolvedTalent, profile = self:EnsureCooldownPanelUxDefaults(
        classToken,
        talentTab
    )
    if not specSettings then
        return
    end

    specSettings.groupOrder = NormalizeGroupOrder(order, profile)
    RefreshPanelForSpec(resolvedClass, resolvedTalent, false)

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end
end

local originalIsCooldownElementEnabled = Settings.IsCooldownElementEnabled
function Settings:IsCooldownElementEnabled(settingId, defaultEnabled, classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if specSettings and type(specSettings.elementEnabled) == "table" then
        local value = specSettings.elementEnabled[settingId]
        if value ~= nil then
            return value == true
        end
    end

    local profile = GetProfile(classToken, talentTab)
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

    return originalIsCooldownElementEnabled(self, settingId, defaultEnabled, classToken, talentTab)
end

local originalResetCooldownPanelSpecSettings = Settings.ResetCooldownPanelSpecSettings
function Settings:ResetCooldownPanelSpecSettings(classToken, talentTab)
    classToken, talentTab = self:ResolveCooldownPanelSpec(classToken, talentTab)
    originalResetCooldownPanelSpecSettings(self, classToken, talentTab)

    local specSettings = self:GetCooldownPanelSpecSettings(classToken, talentTab)
    if specSettings then
        specSettings.groupEnabled = {}
        specSettings.showTimers = nil
        specSettings.iconGap = nil
        specSettings.groupGap = nil
        specSettings.groupScale = nil
        specSettings.buffSide = nil
        specSettings.groupOrder = nil
        self:EnsureCooldownPanelUxDefaults(classToken, talentTab)
    end

    RefreshPanelForSpec(classToken, talentTab, true)
end
