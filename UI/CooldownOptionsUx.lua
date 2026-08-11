local addon = TopDps
local CooldownOptions = addon.CooldownOptions
local Widgets = addon.OptionsWidgets

local SCROLL_HEIGHT = 2350
local VISUAL_HEADER_Y = -658
local SHOW_TIMERS_Y = -684
local ICON_GAP_Y = -742
local GROUP_GAP_Y = -806
local BUFF_SIDE_LABEL_Y = -864
local BUFF_SIDE_DROPDOWN_Y = -880
local GROUPS_HEADER_Y = -946
local GROUPS_START_Y = -980
local ELEMENTS_HEADER_Y = -1248
local ELEMENTS_VIEW_Y = -1286

local function GetCategoryLabel(category)
    return addon.L["PANEL_CATEGORY_" .. tostring(category)] or tostring(category)
end

local function GetBuffSideLabel(side)
    return addon.L["COOLDOWN_PANEL_BUFF_SIDE_" .. tostring(side)] or tostring(side)
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

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_SPEC_VISUALS, VISUAL_HEADER_Y)

    local showTimersCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelShowTimers",
        6,
        SHOW_TIMERS_Y,
        addon.L.COOLDOWN_PANEL_SHOW_TIMERS
    )
    showTimersCheck:SetScript("OnClick", function(self)
        local profile = GetSelectedProfile()
        if not profile then
            return
        end

        addon.Settings:SetCooldownPanelShowTimers(
            Widgets:GetCheckValue(self),
            profile.classToken,
            profile.talentTab
        )
    end)

    local iconGapSlider = CreateSlider(
        content,
        "TopDpsCooldownPanelIconGap",
        20,
        ICON_GAP_Y,
        300,
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX,
        addon.COOLDOWN_PANEL_ICON_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MAX)
    )
    iconGapSlider:SetScript("OnValueChanged", function(self, value)
        local profile = GetSelectedProfile()
        if not profile then
            return
        end

        local rounded = math.floor(value + 0.5)
        addon.Settings:SetCooldownPanelIconGap(
            rounded,
            profile.classToken,
            profile.talentTab
        )
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_ICON_GAP, rounded))
    end)

    local groupGapSlider = CreateSlider(
        content,
        "TopDpsCooldownPanelGroupGap",
        20,
        GROUP_GAP_Y,
        300,
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX,
        addon.COOLDOWN_PANEL_GROUP_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MAX)
    )
    groupGapSlider:SetScript("OnValueChanged", function(self, value)
        local profile = GetSelectedProfile()
        if not profile then
            return
        end

        local rounded = math.floor(value + 0.5)
        addon.Settings:SetCooldownPanelGroupGap(
            rounded,
            profile.classToken,
            profile.talentTab
        )
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_GROUP_GAP, rounded))
    end)

    Widgets:CreateText(
        content,
        "GameFontNormal",
        8,
        BUFF_SIDE_LABEL_Y,
        Widgets.TEXT_WIDTH,
        addon.L.COOLDOWN_PANEL_BUFF_SIDE
    )

    local buffSideDropdown = CreateFrame(
        "Frame",
        "TopDpsCooldownPanelBuffSideDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    buffSideDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, BUFF_SIDE_DROPDOWN_Y)
    UIDropDownMenu_SetWidth(buffSideDropdown, 270)
    UIDropDownMenu_Initialize(buffSideDropdown, function(_, level)
        local profile = GetSelectedProfile()
        if not profile then
            return
        end

        local selectedSide = addon.Settings:GetCooldownPanelBuffSide(
            profile.classToken,
            profile.talentTab
        )
        local index
        for index = 1, #addon.PANEL_BUFF_SIDE_ORDER do
            local side = addon.PANEL_BUFF_SIDE_ORDER[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = GetBuffSideLabel(side)
            info.value = side
            info.checked = selectedSide == side
            info.func = function()
                addon.Settings:SetCooldownPanelBuffSide(
                    side,
                    profile.classToken,
                    profile.talentTab
                )
            end
            UIDropDownMenu_AddButton(info, level)
        end
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
            local profile = GetSelectedProfile()
            if not profile then
                return
            end

            local steps = math.floor(value / addon.COOLDOWN_PANEL_GROUP_SCALE_STEP + 0.5)
            local rounded = steps * addon.COOLDOWN_PANEL_GROUP_SCALE_STEP
            addon.Settings:SetCooldownPanelCategoryScale(
                self.category,
                rounded,
                profile.classToken,
                profile.talentTab
            )
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
    self.buffSideDropdown = buffSideDropdown
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

    addon.Settings:EnsureCooldownPanelUxDefaults(profile.classToken, profile.talentTab)

    local showTimers = addon.Settings:AreCooldownPanelTimersShown(
        profile.classToken,
        profile.talentTab
    )
    local iconGap = addon.Settings:GetCooldownPanelIconGap(profile.classToken, profile.talentTab)
    local groupGap = addon.Settings:GetCooldownPanelGroupGap(profile.classToken, profile.talentTab)
    local buffSide = addon.Settings:GetCooldownPanelBuffSide(profile.classToken, profile.talentTab)

    self.showTimersCheck:SetChecked(showTimers and 1 or nil)
    self.iconGapSlider:SetValue(iconGap)
    self.groupGapSlider:SetValue(groupGap)
    _G[self.iconGapSlider:GetName() .. "Text"]:SetText(string.format(
        addon.L.COOLDOWN_PANEL_ICON_GAP,
        iconGap
    ))
    _G[self.groupGapSlider:GetName() .. "Text"]:SetText(string.format(
        addon.L.COOLDOWN_PANEL_GROUP_GAP,
        groupGap
    ))
    UIDropDownMenu_SetSelectedValue(self.buffSideDropdown, buffSide)
    UIDropDownMenu_SetText(self.buffSideDropdown, GetBuffSideLabel(buffSide))

    local panelEnabled = addon.db.showCooldownPanel == true
    local index
    for index = 1, #(self.categoryControls or {}) do
        local control = self.categoryControls[index]
        local enabled = addon.Settings:IsCooldownPanelCategoryEnabled(
            control.category,
            profile.classToken,
            profile.talentTab
        )
        local scale = addon.Settings:GetCooldownPanelCategoryScale(
            control.category,
            profile.classToken,
            profile.talentTab
        )

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
        UIDropDownMenu_EnableDropDown(self.buffSideDropdown)
    else
        self.showTimersCheck:Disable()
        self.iconGapSlider:Disable()
        self.groupGapSlider:Disable()
        UIDropDownMenu_DisableDropDown(self.buffSideDropdown)
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
