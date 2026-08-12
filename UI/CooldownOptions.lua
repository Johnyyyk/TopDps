local addon = TopDps
local CooldownOptions = addon:CreateModule("CooldownOptions")
local Widgets = addon.OptionsWidgets
local Layout = addon.OptionsLayout
local Size = Layout.Size

local function GetGroupLabel(group)
    return addon.L["COOLDOWN_GROUP_" .. tostring(group)] or tostring(group)
end

local function BuildEntriesSignature(profile, entries)
    local parts = { profile and profile.key or "none" }
    local index

    for index = 1, #entries do
        local entry = entries[index]
        parts[#parts + 1] = table.concat({
            entry.settingId or "",
            tostring(entry.itemId or entry.spellId or entry.displaySpellId or ""),
            entry.name or "",
        }, ":")
    end

    return table.concat(parts, "|")
end

local function SetSliderValue(slider, value)
    slider.suppressChange = true
    slider:SetValue(value)
    slider.suppressChange = false
end

function CooldownOptions:RegisterLayoutControl(controlType, frame, parent, x, label)
    self.layoutControls[#self.layoutControls + 1] = {
        type = controlType,
        frame = frame,
        parent = parent,
        x = x,
        label = label,
    }
end

function CooldownOptions:RegisterElementLayoutControl(controlType, frame, parent, x, label)
    self.elementLayoutControls[#self.elementLayoutControls + 1] = {
        type = controlType,
        frame = frame,
        parent = parent,
        x = x,
        label = label,
    }
end

function CooldownOptions:ApplyRegisteredLayout(controls)
    local index
    for index = 1, #(controls or {}) do
        local control = controls[index]

        if control.type == "text" then
            Layout:ApplyTextWidth(control.frame, control.parent, control.x)
        elseif control.type == "checkbox" then
            Layout:ApplyCheckLabelWidth(control.frame, control.parent, control.x)
        elseif control.type == "slider" then
            Layout:ApplySliderWidth(control.frame, control.parent)
        elseif control.type == "dropdown" then
            if control.label then
                Layout:ApplyTextWidth(control.label, control.parent, Size.CONTENT_INSET)
            end
            Layout:ApplyDropdownWidth(control.frame, control.parent)
        end
    end
end

function CooldownOptions:UpdateRequiredContentHeight()
    if not self.elementsViewTop then
        return
    end

    local viewHeight = self.elementsViewHeight or 1
    self.requiredContentHeight = -self.elementsViewTop + viewHeight + Size.BOTTOM_INSET
end

function CooldownOptions:ApplyLayout()
    if not self.scrollFrame or not self.content then
        return
    end

    Layout:ApplyScrollContentWidth(self.content, self.scrollFrame)

    if self.elementsView then
        Layout:ApplyFrameWidth(
            self.elementsView,
            self.content,
            0,
            0,
            Size.FALLBACK_CONTENT_WIDTH
        )
    end

    self:ApplyRegisteredLayout(self.layoutControls)
    self:ApplyRegisteredLayout(self.elementLayoutControls)

    local scrollHeight = self.scrollFrame:GetHeight() or 0
    self.content:SetHeight(math.max(scrollHeight, self.requiredContentHeight or 1))
end

function CooldownOptions:CreateElementsView(content, profile, entries)
    if self.elementsView then
        self.elementsView:Hide()
    end

    self.elementLayoutControls = {}

    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, self.elementsViewTop or 0)
    Layout:ApplyFrameWidth(view, content, 0, 0, Size.FALLBACK_CONTENT_WIDTH)

    local controls = {}
    local cursor = Layout:CreateCursor(-2)
    local previousGroup
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if entry.group ~= previousGroup then
            local groupHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
            Layout:CreateSectionHeader(view, GetGroupLabel(entry.group), groupHeaderY)
            previousGroup = entry.group
        end

        local rowTop = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
        local check = Layout:CreateCheckButton(
            view,
            "TopDpsCooldownElement" .. tostring(index) .. tostring(self.elementsRevision or 1),
            Size.CONTENT_INSET,
            rowTop,
            entry.name
        )
        check.entry = entry
        check.profileKey = profile.key
        check:SetScript("OnClick", function(self)
            local selectedProfile = addon.CooldownRegistry:GetProfileByKey(self.profileKey)
            if not selectedProfile then
                return
            end

            addon.Settings:SetCooldownElementEnabled(
                self.entry.settingId,
                Widgets:GetCheckValue(self),
                selectedProfile.classToken,
                selectedProfile.talentTab
            )
        end)

        self:RegisterElementLayoutControl(
            "checkbox",
            check,
            view,
            Size.CONTENT_INSET
        )

        if entry.group == addon.COOLDOWN_GROUP_PROCS then
            local soundRowTop = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
            local soundX = Size.CONTENT_INSET + Size.CHECKBOX_SIZE
            local soundCheck = Layout:CreateCheckButton(
                view,
                "TopDpsCooldownProcSound" .. tostring(index) .. tostring(self.elementsRevision or 1),
                soundX,
                soundRowTop,
                addon.L.COOLDOWN_PROC_SOUND
            )
            soundCheck.entry = entry
            soundCheck.profileKey = profile.key
            soundCheck:SetScript("OnClick", function(self)
                local selectedProfile = addon.CooldownRegistry:GetProfileByKey(self.profileKey)
                if not selectedProfile then
                    return
                end

                addon.Settings:SetCooldownProcSoundEnabled(
                    self.entry.settingId,
                    Widgets:GetCheckValue(self),
                    selectedProfile.classToken,
                    selectedProfile.talentTab
                )
            end)
            check.soundCheck = soundCheck

            self:RegisterElementLayoutControl("checkbox", soundCheck, view, soundX)
        end

        controls[#controls + 1] = check
    end

    if #entries == 0 then
        local emptyY = Layout:TakeRow(cursor, Size.TEXT_ROW_HEIGHT, Size.ROW_GAP)
        local emptyText = Layout:CreateText(
            view,
            "GameFontHighlightSmall",
            Size.CONTENT_INSET,
            emptyY,
            addon.L.COOLDOWN_NO_ELEMENTS
        )
        self:RegisterElementLayoutControl(
            "text",
            emptyText,
            view,
            Size.CONTENT_INSET
        )
    end

    local viewHeight = Layout:GetRequiredHeight(cursor)
    view:SetHeight(viewHeight)

    self.elementsView = view
    self.elementsViewHeight = viewHeight
    self.elementControls = controls

    self:UpdateRequiredContentHeight()
    self:ApplyLayout()
end

function CooldownOptions:EnsureElementsView(profile)
    if not profile then
        return {}
    end

    local entries = addon.CooldownTracker:GetConfigurableEntriesForProfile(
        profile.classToken,
        profile.talentTab
    )
    local signature = BuildEntriesSignature(profile, entries)
    if signature == self.elementsSignature and self.elementsView then
        return entries
    end

    self.elementsRevision = (self.elementsRevision or 0) + 1
    self.elementsSignature = signature
    self:CreateElementsView(self.content, profile, entries)

    return entries
end

function CooldownOptions:GetSelectedProfile()
    if self.selectedProfileKey then
        local profile = addon.CooldownRegistry:GetProfileByKey(self.selectedProfileKey)
        if profile then
            return profile
        end
    end

    local activeProfile = addon.CooldownRegistry:GetProfile(
        addon.SpecManager.classToken,
        addon.SpecManager.talentTab
    )
    if activeProfile then
        self.selectedProfileKey = activeProfile.key
        return activeProfile
    end

    local firstProfile = self.profiles and self.profiles[1] or nil
    if firstProfile then
        self.selectedProfileKey = firstProfile.key
    end

    return firstProfile
end

function CooldownOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsCooldownOptionsPanel", addon.L.COOLDOWN_PAGE, addon.NAME)
    local profiles = addon.CooldownRegistry:GetProfiles()
    local scrollFrame, content = Layout:CreateScrollArea(
        panel,
        "TopDpsCooldownOptionsScrollFrame",
        1
    )
    local cursor = Layout:CreateCursor(-8)

    self.layoutControls = {}
    self.elementLayoutControls = {}

    local titleY = Layout:TakeRow(cursor, Size.TITLE_ROW_HEIGHT)
    local title = Layout:CreateText(
        content,
        "GameFontNormalLarge",
        Size.CONTENT_INSET,
        titleY,
        addon.NAME .. " - " .. addon.L.COOLDOWN_PAGE
    )
    self:RegisterLayoutControl("text", title, content, Size.CONTENT_INSET)

    local descriptionY = Layout:TakeRow(cursor, Size.DESCRIPTION_ROW_HEIGHT, Size.SECTION_GAP)
    local description = Layout:CreateText(
        content,
        "GameFontHighlightSmall",
        Size.CONTENT_INSET,
        descriptionY,
        addon.L.COOLDOWN_DESCRIPTION
    )
    self:RegisterLayoutControl("text", description, content, Size.CONTENT_INSET)

    local panelHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_SETTINGS, panelHeaderY)

    local enabledY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local enabledCheck = Layout:CreateCheckButton(
        content,
        "TopDpsCooldownPanelEnabled",
        Size.CONTENT_INSET,
        enabledY,
        addon.L.COOLDOWN_PANEL_ENABLED
    )
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelEnabled(Widgets:GetCheckValue(self))
    end)
    self:RegisterLayoutControl("checkbox", enabledCheck, content, Size.CONTENT_INSET)

    local procSoundsY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local procSoundsEnabledCheck = Layout:CreateCheckButton(
        content,
        "TopDpsCooldownProcSoundsEnabled",
        Size.CONTENT_INSET,
        procSoundsY,
        addon.L.COOLDOWN_PROC_SOUNDS_ENABLED
    )
    procSoundsEnabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownProcSoundsEnabled(Widgets:GetCheckValue(self))
    end)
    self:RegisterLayoutControl(
        "checkbox",
        procSoundsEnabledCheck,
        content,
        Size.CONTENT_INSET
    )

    local lockedY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local lockedCheck = Layout:CreateCheckButton(
        content,
        "TopDpsCooldownPanelLocked",
        Size.CONTENT_INSET,
        lockedY,
        addon.L.COOLDOWN_PANEL_LOCKED
    )
    lockedCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelLocked(Widgets:GetCheckValue(self))
    end)
    self:RegisterLayoutControl("checkbox", lockedCheck, content, Size.CONTENT_INSET)

    local resetPositionY = Layout:TakeRow(
        cursor,
        Size.BUTTON_HEIGHT + Size.ROW_GAP,
        Size.SECTION_GAP
    )
    local resetButton = Layout:CreateButton(
        content,
        "TopDpsCooldownPanelResetPosition",
        addon.L.COOLDOWN_PANEL_RESET_POSITION
    )
    resetButton:SetPoint("TOPLEFT", content, "TOPLEFT", Size.CONTENT_INSET, resetPositionY)
    resetButton:SetWidth(Size.BUTTON_WIDTH * 2 + Size.BUTTON_GAP * 6)
    resetButton:SetScript("OnClick", function()
        addon.CooldownPanel:ResetPosition()
    end)

    local sizeRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
    local sizeSlider = Layout:CreateSlider(content, "TopDpsCooldownPanelIconSize", sizeRowTop)
    sizeSlider:SetMinMaxValues(
        addon.COOLDOWN_PANEL_ICON_SIZE_MIN,
        addon.COOLDOWN_PANEL_ICON_SIZE_MAX
    )
    sizeSlider:SetValueStep(addon.COOLDOWN_PANEL_ICON_SIZE_STEP)
    _G[sizeSlider:GetName() .. "Low"]:SetText(tostring(addon.COOLDOWN_PANEL_ICON_SIZE_MIN))
    _G[sizeSlider:GetName() .. "High"]:SetText(tostring(addon.COOLDOWN_PANEL_ICON_SIZE_MAX))
    sizeSlider:SetScript("OnValueChanged", function(self, value)
        if self.suppressChange then
            return
        end

        local rounded = math.floor(value / addon.COOLDOWN_PANEL_ICON_SIZE_STEP + 0.5)
            * addon.COOLDOWN_PANEL_ICON_SIZE_STEP
        addon.Settings:SetCooldownPanelIconSize(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_ICON_SIZE,
            rounded
        ))
    end)
    self:RegisterLayoutControl("slider", sizeSlider, content)

    local opacityRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.SECTION_GAP)
    local opacitySlider = Layout:CreateSlider(content, "TopDpsCooldownPanelOpacity", opacityRowTop)
    opacitySlider:SetMinMaxValues(
        addon.COOLDOWN_PANEL_OPACITY_MIN,
        addon.COOLDOWN_PANEL_OPACITY_MAX
    )
    opacitySlider:SetValueStep(addon.COOLDOWN_PANEL_OPACITY_STEP)
    _G[opacitySlider:GetName() .. "Low"]:SetText("30%")
    _G[opacitySlider:GetName() .. "High"]:SetText("100%")
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        if self.suppressChange then
            return
        end

        local rounded = math.floor(value * 20 + 0.5) / 20
        addon.Settings:SetCooldownPanelOpacity(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(
            addon.L.COOLDOWN_PANEL_OPACITY,
            rounded * 100
        ))
    end)
    self:RegisterLayoutControl("slider", opacitySlider, content)

    local specHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.COOLDOWN_SPEC_SETTINGS, specHeaderY)

    local activeSpecY = Layout:TakeRow(cursor, Size.TEXT_ROW_HEIGHT, Size.ROW_GAP)
    local activeSpecText = Layout:CreateText(
        content,
        "GameFontNormal",
        Size.CONTENT_INSET,
        activeSpecY,
        ""
    )
    self:RegisterLayoutControl("text", activeSpecText, content, Size.CONTENT_INSET)

    local profileRowTop = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT, Size.ROW_GAP)
    local configureSpecText, profileDropdown = Layout:CreateDropdownField(
        content,
        "TopDpsCooldownProfileDropDown",
        profileRowTop,
        addon.L.CONFIGURE_SPEC
    )
    self:RegisterLayoutControl(
        "dropdown",
        profileDropdown,
        content,
        nil,
        configureSpecText
    )

    UIDropDownMenu_Initialize(profileDropdown, function(_, level)
        local index
        for index = 1, #profiles do
            local profile = profiles[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = addon.CooldownRegistry:GetProfileDisplayName(profile)
            info.value = profile.key
            info.checked = self.selectedProfileKey == profile.key
            info.func = function()
                self.selectedProfileKey = profile.key
                self.elementsSignature = nil
                self:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local resetSpecY = Layout:TakeRow(
        cursor,
        Size.BUTTON_HEIGHT + Size.ROW_GAP,
        Size.ROW_GAP
    )
    local resetSpecButton = Layout:CreateButton(
        content,
        "TopDpsCooldownPanelResetSpec",
        addon.L.COOLDOWN_SPEC_RESET
    )
    resetSpecButton:SetPoint("TOPLEFT", content, "TOPLEFT", Size.CONTENT_INSET, resetSpecY)
    resetSpecButton:SetWidth(Size.BUTTON_WIDTH * 2 + Size.BUTTON_GAP * 6)
    resetSpecButton:SetScript("OnClick", function()
        local profile = CooldownOptions:GetSelectedProfile()
        if not profile then
            return
        end

        addon.Settings:ResetCooldownPanelSpecSettings(profile.classToken, profile.talentTab)
    end)

    local combatOnlyY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.SECTION_GAP)
    local combatOnlyCheck = Layout:CreateCheckButton(
        content,
        "TopDpsCooldownPanelCombatOnly",
        Size.CONTENT_INSET,
        combatOnlyY,
        addon.L.COOLDOWN_PANEL_COMBAT_ONLY
    )
    combatOnlyCheck:SetScript("OnClick", function(self)
        local profile = CooldownOptions:GetSelectedProfile()
        if not profile then
            return
        end

        addon.Settings:SetCooldownPanelCombatOnly(
            Widgets:GetCheckValue(self),
            profile.classToken,
            profile.talentTab
        )
    end)
    self:RegisterLayoutControl("checkbox", combatOnlyCheck, content, Size.CONTENT_INSET)

    self.panel = panel
    self.scrollFrame = scrollFrame
    self.content = content
    self.profiles = profiles
    self.profileDropdown = profileDropdown
    self.activeSpecText = activeSpecText
    self.enabledCheck = enabledCheck
    self.procSoundsEnabledCheck = procSoundsEnabledCheck
    self.combatOnlyCheck = combatOnlyCheck
    self.lockedCheck = lockedCheck
    self.resetButton = resetButton
    self.resetSpecButton = resetSpecButton
    self.sizeSlider = sizeSlider
    self.opacitySlider = opacitySlider

    if self.CreateUxControls then
        self:CreateUxControls(content, cursor)
    end

    local elementsHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.COOLDOWN_ELEMENTS, elementsHeaderY)

    self.elementsViewTop = cursor.y
    self:UpdateRequiredContentHeight()

    local profile = self:GetSelectedProfile()
    if profile then
        self:EnsureElementsView(profile)
    end

    scrollFrame:SetScript("OnSizeChanged", function()
        self:ApplyLayout()
    end)

    panel:SetScript("OnShow", function()
        if self.SelectDetectedProfile then
            self:SelectDetectedProfile()
        end

        self:Refresh()
        Layout:RequestNextFrame(panel, function()
            self:ApplyLayout()
        end)
    end)

    InterfaceOptions_AddCategory(panel)
    self:ApplyLayout()
end

function CooldownOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    local activeProfile = addon.CooldownRegistry:GetProfile(
        addon.SpecManager.classToken,
        addon.SpecManager.talentTab
    )
    if activeProfile then
        self.activeSpecText:SetText(string.format(
            addon.L.DETECTED_SPEC,
            addon.CooldownRegistry:GetProfileDisplayName(activeProfile)
        ))
    else
        self.activeSpecText:SetText(addon.L.DETECTED_SPEC_UNSUPPORTED)
    end

    local profile = self:GetSelectedProfile()
    if not profile then
        UIDropDownMenu_SetText(self.profileDropdown, addon.L.NO_SUPPORTED_SPECS)
        self:ApplyLayout()
        return
    end

    UIDropDownMenu_SetSelectedValue(self.profileDropdown, profile.key)
    UIDropDownMenu_SetText(
        self.profileDropdown,
        addon.CooldownRegistry:GetProfileDisplayName(profile)
    )

    local panelEnabled = addon.Settings:IsPanelEnabled()
    self.enabledCheck:SetChecked(panelEnabled and 1 or nil)
    self.procSoundsEnabledCheck:SetChecked(
        addon.Settings:AreCooldownProcSoundsEnabled() and 1 or nil
    )
    self.combatOnlyCheck:SetChecked(
        addon.Settings:IsCooldownPanelCombatOnly(
            profile.classToken,
            profile.talentTab
        ) and 1 or nil
    )
    self.lockedCheck:SetChecked(addon.db.panel.locked and 1 or nil)

    SetSliderValue(self.sizeSlider, addon.db.panel.iconSize)
    SetSliderValue(self.opacitySlider, addon.db.panel.opacity)

    _G[self.sizeSlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_ICON_SIZE, addon.db.panel.iconSize)
    )
    _G[self.opacitySlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_OPACITY, addon.db.panel.opacity * 100)
    )

    self:EnsureElementsView(profile)

    local index
    for index = 1, #(self.elementControls or {}) do
        local check = self.elementControls[index]
        local entry = check.entry
        local elementEnabled = addon.Settings:IsCooldownElementEnabled(
            entry.settingId,
            entry.defaultEnabled,
            profile.classToken,
            profile.talentTab
        )
        check:SetChecked(elementEnabled and 1 or nil)

        if check.soundCheck then
            check.soundCheck:SetChecked(addon.Settings:IsCooldownProcSoundEnabled(
                entry.settingId,
                true,
                profile.classToken,
                profile.talentTab
            ) and 1 or nil)

            if elementEnabled then
                check.soundCheck:Enable()
            else
                check.soundCheck:Disable()
            end
        end
    end

    if self.RefreshUxControls then
        self:RefreshUxControls()
    end

    if panelEnabled then
        self.procSoundsEnabledCheck:Enable()
        self.combatOnlyCheck:Enable()
        self.lockedCheck:Enable()
        self.resetButton:Enable()
        self.sizeSlider:Enable()
        self.opacitySlider:Enable()
    else
        self.procSoundsEnabledCheck:Disable()
        self.combatOnlyCheck:Disable()
        self.lockedCheck:Disable()
        self.resetButton:Disable()
        self.sizeSlider:Disable()
        self.opacitySlider:Disable()
    end

    self:ApplyLayout()
end
