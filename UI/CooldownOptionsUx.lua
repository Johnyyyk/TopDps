local addon = TopDps
local CooldownOptions = addon.CooldownOptions
local Widgets = addon.OptionsWidgets
local Layout = addon.OptionsLayout
local Size = Layout.Size

local function GetCategoryLabel(category)
    return addon.L["PANEL_CATEGORY_" .. tostring(category)] or tostring(category)
end

local function GetBuffSideLabel(side)
    return addon.L["COOLDOWN_PANEL_BUFF_SIDE_" .. tostring(side)] or tostring(side)
end

local function GetSelectedProfile()
    return CooldownOptions:GetSelectedProfile()
end

local function SetSliderValue(slider, value)
    slider.suppressChange = true
    slider:SetValue(value)
    slider.suppressChange = false
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

            if addon.Settings:IsPanelEnabled()
                and elementEnabled
                and procsEnabled
                and masterSoundEnabled then
                check.soundCheck:Enable()
            else
                check.soundCheck:Disable()
            end
        end
    end
end

local function ConfigureSlider(slider, minimum, maximum, step, lowText, highText)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    _G[slider:GetName() .. "Low"]:SetText(lowText)
    _G[slider:GetName() .. "High"]:SetText(highText)
end

local function CreateBuffSideDropdown(content, cursor)
    local rowTop = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT, Size.ROW_GAP)
    local label, dropdown = Layout:CreateDropdownField(
        content,
        "TopDpsCooldownPanelBuffSideDropDown",
        rowTop,
        addon.L.COOLDOWN_PANEL_BUFF_SIDE
    )

    UIDropDownMenu_Initialize(dropdown, function(_, level)
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

    return label, dropdown
end

function CooldownOptions:CreateUxControls(content, cursor)
    if self.uxControlsCreated then
        return
    end

    self.uxControlsCreated = true

    if self.resetSpecButton then
        Layout:ApplyButtonTextWidth(self.resetSpecButton, content)
    end

    local visualHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_SPEC_VISUALS, visualHeaderY)

    local showTimersY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local showTimersCheck = Layout:CreateCheckButton(
        content,
        "TopDpsCooldownPanelShowTimers",
        Size.CONTENT_INSET,
        showTimersY,
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
    self:RegisterLayoutControl(
        "checkbox",
        showTimersCheck,
        content,
        Size.CONTENT_INSET
    )

    local iconGapRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
    local iconGapSlider = Layout:CreateSlider(
        content,
        "TopDpsCooldownPanelIconGap",
        iconGapRowTop
    )
    ConfigureSlider(
        iconGapSlider,
        addon.COOLDOWN_PANEL_ICON_GAP_MIN,
        addon.COOLDOWN_PANEL_ICON_GAP_MAX,
        addon.COOLDOWN_PANEL_ICON_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_ICON_GAP_MAX)
    )
    iconGapSlider:SetScript("OnValueChanged", function(self, value)
        if self.suppressChange then
            return
        end

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
        _G[self:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_ICON_GAP,
            rounded
        ))
    end)
    self:RegisterLayoutControl("slider", iconGapSlider, content)

    local groupGapRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.SECTION_GAP)
    local groupGapSlider = Layout:CreateSlider(
        content,
        "TopDpsCooldownPanelGroupGap",
        groupGapRowTop
    )
    ConfigureSlider(
        groupGapSlider,
        addon.COOLDOWN_PANEL_GROUP_GAP_MIN,
        addon.COOLDOWN_PANEL_GROUP_GAP_MAX,
        addon.COOLDOWN_PANEL_GROUP_GAP_STEP,
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MIN),
        tostring(addon.COOLDOWN_PANEL_GROUP_GAP_MAX)
    )
    groupGapSlider:SetScript("OnValueChanged", function(self, value)
        if self.suppressChange then
            return
        end

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
        _G[self:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_GROUP_GAP,
            rounded
        ))
    end)
    self:RegisterLayoutControl("slider", groupGapSlider, content)

    local groupsHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_GROUPS, groupsHeaderY)

    local categoryControls = {}
    local buffSideDropdown
    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        local category = addon.PANEL_CATEGORY_ORDER[index]

        local categoryY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
        local check = Layout:CreateCheckButton(
            content,
            "TopDpsCooldownCategory" .. tostring(category),
            Size.CONTENT_INSET,
            categoryY,
            GetCategoryLabel(category)
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
        self:RegisterLayoutControl("checkbox", check, content, Size.CONTENT_INSET)

        if category == addon.PANEL_CATEGORY_BUFFS then
            local buffSideLabel
            buffSideLabel, buffSideDropdown = CreateBuffSideDropdown(content, cursor)
            self:RegisterLayoutControl(
                "dropdown",
                buffSideDropdown,
                content,
                nil,
                buffSideLabel
            )
        end

        local scaleRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
        local scaleSlider = Layout:CreateSlider(
            content,
            "TopDpsCooldownCategoryScale" .. tostring(category),
            scaleRowTop
        )
        ConfigureSlider(
            scaleSlider,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MIN,
            addon.COOLDOWN_PANEL_GROUP_SCALE_MAX,
            addon.COOLDOWN_PANEL_GROUP_SCALE_STEP,
            "60%",
            "150%"
        )
        scaleSlider.category = category
        scaleSlider:SetScript("OnValueChanged", function(self, value)
            if self.suppressChange then
                return
            end

            local profile = GetSelectedProfile()
            if not profile then
                return
            end

            local steps = math.floor(
                value / addon.COOLDOWN_PANEL_GROUP_SCALE_STEP + 0.5
            )
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
        self:RegisterLayoutControl("slider", scaleSlider, content)

        local control = {
            category = category,
            check = check,
            slider = scaleSlider,
        }
        categoryControls[#categoryControls + 1] = control

        if self.CreateCategoryExtraControls then
            self:CreateCategoryExtraControls(content, cursor, category, control)
        end

        if index < #addon.PANEL_CATEGORY_ORDER then
            Layout:AddGap(cursor, Size.ROW_GAP)
        end
    end

    Layout:AddGap(cursor, Size.SECTION_GAP)

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
    local iconGap = addon.Settings:GetCooldownPanelIconGap(
        profile.classToken,
        profile.talentTab
    )
    local groupGap = addon.Settings:GetCooldownPanelGroupGap(
        profile.classToken,
        profile.talentTab
    )
    local buffSide = addon.Settings:GetCooldownPanelBuffSide(
        profile.classToken,
        profile.talentTab
    )

    self.showTimersCheck:SetChecked(showTimers and 1 or nil)

    SetSliderValue(self.iconGapSlider, iconGap)
    SetSliderValue(self.groupGapSlider, groupGap)

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

    local panelEnabled = addon.Settings:IsPanelEnabled()
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
        SetSliderValue(control.slider, scale)
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

    if self.RefreshCategoryExtraControls then
        self:RefreshCategoryExtraControls(profile, panelEnabled)
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
