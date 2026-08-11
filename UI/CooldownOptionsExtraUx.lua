local addon = TopDps
local CooldownOptions = addon.CooldownOptions

local ICONS_PER_ROW_X = 182
local ICONS_PER_ROW_WIDTH = 138
local GROUPS_START_Y = -980
local GROUP_ROW_STEP = 64
local ICONS_PER_ROW_OFFSET_Y = -38

local function GetSelectedProfile()
    return CooldownOptions:GetSelectedProfile()
end

local function CreateIconsPerRowSlider(parent, category, index)
    local name = "TopDpsCooldownIconsPerRow" .. tostring(category)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    local y = GROUPS_START_Y - (index - 1) * GROUP_ROW_STEP + ICONS_PER_ROW_OFFSET_Y
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", ICONS_PER_ROW_X, y)
    slider:SetWidth(ICONS_PER_ROW_WIDTH)
    slider:SetMinMaxValues(
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MIN,
        addon.COOLDOWN_PANEL_ICONS_PER_ROW_MAX
    )
    slider:SetValueStep(addon.COOLDOWN_PANEL_ICONS_PER_ROW_STEP)
    _G[name .. "Low"]:SetText(tostring(addon.COOLDOWN_PANEL_ICONS_PER_ROW_MIN))
    _G[name .. "High"]:SetText(tostring(addon.COOLDOWN_PANEL_ICONS_PER_ROW_MAX))
    slider.category = category

    slider:SetScript("OnValueChanged", function(self, value)
        if self.suppressChange then
            return
        end

        local profile = GetSelectedProfile()
        if not profile then
            return
        end

        local rounded = math.floor(value + 0.5)
        addon.Settings:SetCooldownPanelIconsPerRow(
            self.category,
            rounded,
            profile.classToken,
            profile.talentTab
        )
        _G[self:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_ICONS_PER_ROW,
            rounded
        ))
    end)

    return slider
end

local originalCreateUxControls = CooldownOptions.CreateUxControls
function CooldownOptions:CreateUxControls()
    originalCreateUxControls(self)

    if self.iconsPerRowControls or not self.content then
        return
    end

    local controls = {}
    local index
    for index = 1, #(self.categoryControls or {}) do
        local category = self.categoryControls[index].category
        controls[#controls + 1] = {
            category = category,
            slider = CreateIconsPerRowSlider(self.content, category, index),
        }
    end

    self.iconsPerRowControls = controls
end

local originalRefreshUxControls = CooldownOptions.RefreshUxControls
function CooldownOptions:RefreshUxControls()
    originalRefreshUxControls(self)

    local profile = GetSelectedProfile()
    if not profile then
        return
    end

    local panelEnabled = addon.db and addon.db.showCooldownPanel == true
    local index
    for index = 1, #(self.iconsPerRowControls or {}) do
        local control = self.iconsPerRowControls[index]
        local value = addon.Settings:GetCooldownPanelIconsPerRow(
            control.category,
            profile.classToken,
            profile.talentTab
        )

        control.slider.suppressChange = true
        control.slider:SetValue(value)
        control.slider.suppressChange = false
        _G[control.slider:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_ICONS_PER_ROW,
            value
        ))

        if panelEnabled then
            control.slider:Enable()
        else
            control.slider:Disable()
        end
    end
end

function CooldownOptions:SelectDetectedProfile()
    if addon.SpecManager then
        addon.SpecManager:Refresh("options")
    end

    if not addon.CooldownRegistry or not addon.SpecManager then
        return
    end

    local profile = addon.CooldownRegistry:GetProfile(
        addon.SpecManager.classToken,
        addon.SpecManager.talentTab
    )
    if not profile then
        return
    end

    if self.selectedProfileKey ~= profile.key then
        self.selectedProfileKey = profile.key
        self.elementsSignature = nil
    end
end

local originalCreate = CooldownOptions.Create
function CooldownOptions:Create()
    originalCreate(self)

    if not self.panel or self.autoProfileOnShowInstalled then
        return
    end

    self.autoProfileOnShowInstalled = true
    local originalOnShow = self.panel:GetScript("OnShow")
    self.panel:SetScript("OnShow", function(panel)
        CooldownOptions:SelectDetectedProfile()

        if originalOnShow then
            originalOnShow(panel)
        else
            CooldownOptions:Refresh()
        end
    end)
end
