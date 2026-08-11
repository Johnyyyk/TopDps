local addon = TopDps
local CooldownOptions = addon.CooldownOptions
local Widgets = addon.OptionsWidgets

local SCROLL_HEIGHT = 2250
local ELEMENTS_HEADER_Y = -1190
local ELEMENTS_VIEW_Y = -1228
local GROUPS_HEADER_Y = -870
local GROUPS_START_Y = -904

local function GetCategoryLabel(category)
    return addon.L["PANEL_CATEGORY_" .. tostring(category)] or tostring(category)
end

local function CreateSlider(parent, name, x, y, width, minimum, maximum, step, lowText, highText)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    _G[name .. "Low"]:SetText(lowText)
    _G[name .. "High"]:SetText(highText)

    return slider
end

local function GetSelectedProfile()
    return CooldownOptions:GetSelectedProfile()
end

local function RefreshProcSoundControls(profile)
    if not profile then
        return
    end

    local procsEnabled = addon.Settings:IsCooldownPanelCategoryEnabled(
        addon.PANEL_CATEGORY_PROCS,
        profile.classToken,
        profile.talentTab
    )
    local masterSoundEnabled = addon.Settings:AreCooldownProcSoundsEnabled()
    local index

    for index = 1, #(CooldownOptions.elementControls or {}) do
        local check = CooldownOptions.elementControls[index]
        if check.soundCheck then
            local entry = check.entry
            local elementEnabled = addon.Settings:IsCooldownElementEnabled(
                entry.settingId,
                entry.defaultEnabled,
                profile.classToken,
                profile.talentTab
            )

            if addon.db.showCooldownPanel and elementEnabled and procsEnabled and masterSoundEnabled then
                check.soundCheck:Enable()
            else
                check.soundCheck:Disable()
            end
        end
    end
end

function CooldownOptions:CreateUxControls()
    if self.uxControlsCreated or not self.content then
        return
    end

    self.uxControlsCreated = true
    local content = self.content

    Widgets:CreateSectionHeader(content, addon.L.VISUAL_SETTINGS, -658)

    local showTimersCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelShowTimers",
        6,
        -684,
        addon.L.COOLDOWN_PANEL_SHOW_TIMERS
    )
    showTimersCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelShowTimers(Widgets:GetCheckValue(self))
    end)

    local iconGapSlider = CreateSlider(
        content,
        "TopDpsCooldownPanelIconGap",
        20,
        -742,
        300,
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX,
        addon.COOLDOWN_PANEL_ICON_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MAX)
    )
    iconGapSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        addon.Settings:SetCooldownPanelIconGap(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_ICON_GAP, rounded))
    end)

    local groupGapSlider = CreateSlider(
        content,
        "TopDpsCooldownPanelGroupGap",
        20,
        -806,
        300,
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX,
        addon.COOLDOWN_PANEL_GROUP_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MAX)
    )
    groupGapSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        addon.Settings:SetCooldownPanelGroupGap(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_GROUP_GAP, rounded))
    end)

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_GROUPS, GROUPS_HEADER_Y)

    local categoryControls = {}
    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        local category = addon.PANEL_CATEGORY_ORDER[index]
        local y = GROUPS_START_Y - (index - 1) * 64
        local check = Widgets:CreateCheckButton(
            content,
            "TopDpsCooldownCategory" .. tostring(category),
            6,
            y,
            GetCategoryLabel(category),
            150
        )
        check.category = category
        check:SetScript("OnClick", function(self)
            local profile = GetSelectedProfile()
            if not profile then
                return
            end

            addon.Settings:SetCooldownPanelCategoryEnabled(
                self.category,
                Widgets:GetCheckValue(self),
                profile.classToken,
                profile.talentTab
            )
        end)

        local scaleSlider = CreateSlider(
            content,
            "TopDpsCooldownCategoryScale" .. tostring(category),
            182,
            y - 8,
            138,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MAX,
            addon.COOLDOWN_PANEL_GROUP_SCALE_STEP,
            "60%",
            "150%"
        )
        scaleSlider.category = category
        scaleSlider:SetScript("OnValueChanged", function(self, value)
            local steps = math.floor(value / addon.COOLDOWN_PANEL_GROUP_SCALE_STEP + 0.5)
            local rounded = steps * addon.COOLDOWN_PANEL_GROUP_SCALE_STEP
            addon.Settings:SetCooldownPanelCategoryScale(self.category, rounded)
            _G[self:GetName() .. "Text"]:SetText(string.format(
                addon.L.COOLDOWN_PANEL_GROUP_SCALE,
                rounded * 100
            ))
        end)

        categoryControls[#categoryControls + 1] = {
            category = category,
            check = check,
            slider = scaleSlider,
        }
    end

    self.showTimersCheck = showTimersCheck
    self.iconGapSlider = iconGapSlider
    self.groupGapSlider = groupGapSlider
    self.categoryControls = categoryControls
end

function CooldownOptions:RefreshUxControls()
    if not self.uxControlsCreated or not addon.db then
        return
    end

    local profile = GetSelectedProfile()
    if not profile then
        return
    end

    addon.Settings:EnsureCooldownPanelUxDefaults()

    self.showTimersCheck:SetChecked(addon.Settings:AreCooldownPanelTimersShown() and 1 or nil)
    self.iconGapSlider:SetValue(addon.db.cooldownPanelIconGap)
    self.groupGapSlider:SetValue(addon.db.cooldownPanelGroupGap)
    _G[self.iconGapSlider:GetName() .. "Text"]:SetText(string.format(
        addon.L.COOLDOWN_PANEL_ICON_GAP,
        addon.db.cooldownPanelIconGap
    ))
    _G[self.groupGapSlider:GetName() .. "Text"]:SetText(string.format(
        addon.L.COOLDOWN_PANEL_GROUP_GAP,
        addon.db.cooldownPanelGroupGap
    ))

    local panelEnabled = addon.db.showCooldownPanel == true
    local index
    for index = 1, #(self.categoryControls or {}) do
        local control = self.categoryControls[index]
        local enabled = addon.Settings:IsCooldownPanelCategoryEnabled(
            control.category,
            profile.classToken,
            profile.talentTab
        )
        local scale = addon.Settings:GetCooldownPanelCategoryScale(control.category)

        control.check:SetChecked(enabled and 1 or nil)
        control.slider:SetValue(scale)
        _G[control.slider:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_GROUP_SCALE,
            scale * 100
        ))

        if panelEnabled then
            control.check:Enable()
            control.slider:Enable()
        else
            control.check:Disable()
            control.slider:Disable()
        end
    end

    if panelEnabled then
        self.showTimersCheck:Enable()
        self.iconGapSlider:Enable()
        self.groupGapSlider:Enable()
    else
        self.showTimersCheck:Disable()
        self.iconGapSlider:Disable()
        self.groupGapSlider:Disable()
    end

    RefreshProcSoundControls(profile)
end

local originalCreateElementsView = CooldownOptions.CreateElementsView
function CooldownOptions:CreateElementsView(content, profile, entries)
    originalCreateElementsView(self, content, profile, entries)

    if self.elementsView then
        self.elementsView:ClearAllPoints()
        self.elementsView:SetPoint("TOPLEFT", content, "TOPLEFT", 0, ELEMENTS_VIEW_Y)
    end
end

local originalCreate = CooldownOptions.Create
function CooldownOptions:Create()
    local originalCreateScrollArea = Widgets.CreateScrollArea
    local originalCreateSectionHeader = Widgets.CreateSectionHeader

    Widgets.CreateScrollArea = function(self, panel, name, contentHeight)
        return originalCreateScrollArea(self, panel, name, math.max(contentHeight or 0, SCROLL_HEIGHT))
    end

    Widgets.CreateSectionHeader = function(self, parent, text, y, width)
        if text == addon.L.COOLDOWN_ELEMENTS then
            y = ELEMENTS_HEADER_Y
        end

        return originalCreateSectionHeader(self, parent, text, y, width)
    end

    originalCreate(self)

    Widgets.CreateScrollArea = originalCreateScrollArea
    Widgets.CreateSectionHeader = originalCreateSectionHeader

    self:CreateUxControls()
    self:RefreshUxControls()
end

local originalRefresh = CooldownOptions.Refresh
function CooldownOptions:Refresh()
    originalRefresh(self)
    self:RefreshUxControls()
end
