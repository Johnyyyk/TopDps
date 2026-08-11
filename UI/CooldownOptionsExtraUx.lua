local addon = TopDps
local CooldownOptions = addon.CooldownOptions
local Layout = addon.OptionsLayout
local Size = Layout.Size

local function GetSelectedProfile()
    return CooldownOptions:GetSelectedProfile()
end

function CooldownOptions:CreateCategoryExtraControls(content, cursor, category)
    self.iconsPerRowControls = self.iconsPerRowControls or {}

    local rowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
    local name = "TopDpsCooldownIconsPerRow" .. tostring(category)
    local slider = Layout:CreateSlider(content, name, rowTop)
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

    self:RegisterLayoutControl("slider", slider, content)

    self.iconsPerRowControls[#self.iconsPerRowControls + 1] = {
        category = category,
        slider = slider,
    }
end

function CooldownOptions:RefreshCategoryExtraControls(profile, panelEnabled)
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
