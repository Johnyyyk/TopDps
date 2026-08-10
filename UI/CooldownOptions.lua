local addon = TopDps
local CooldownOptions = addon:CreateModule("CooldownOptions")
local Widgets = addon.OptionsWidgets

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

function CooldownOptions:CreateElementsView(content, profile, entries)
    if self.elementsView then
        self.elementsView:Hide()
    end

    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -650)
    view:SetWidth(Widgets.SCROLL_CONTENT_WIDTH)

    local controls = {}
    local y = -2
    local previousGroup
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if entry.group ~= previousGroup then
            Widgets:CreateSectionHeader(view, GetGroupLabel(entry.group), y)
            y = y - 34
            previousGroup = entry.group
        end

        local check = Widgets:CreateCheckButton(
            view,
            "TopDpsCooldownElement" .. tostring(index) .. tostring(self.elementsRevision or 1),
            6,
            y,
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

        if entry.group == addon.COOLDOWN_GROUP_PROCS then
            check.label:SetWidth(180)

            local soundCheck = Widgets:CreateCheckButton(
                view,
                "TopDpsCooldownProcSound" .. tostring(index) .. tostring(self.elementsRevision or 1),
                238,
                y,
                addon.L.COOLDOWN_PROC_SOUND,
                72
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
        end

        table.insert(controls, check)
        y = y - 36
    end

    if #entries == 0 then
        Widgets:CreateText(
            view,
            "GameFontHighlightSmall",
            8,
            y,
            Widgets.TEXT_WIDTH,
            addon.L.COOLDOWN_NO_ELEMENTS
        )
        y = y - 36
    end

    view:SetHeight(math.max(1, -y + 20))
    self.elementsView = view
    self.elementControls = controls
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
    local _, content = Widgets:CreateScrollArea(panel, "TopDpsCooldownOptionsScrollFrame", 1380)

    Widgets:CreateText(
        content,
        "GameFontNormalLarge",
        8,
        -8,
        Widgets.TEXT_WIDTH,
        addon.NAME .. " - " .. addon.L.COOLDOWN_PAGE
    )
    Widgets:CreateText(
        content,
        "GameFontHighlightSmall",
        8,
        -40,
        Widgets.TEXT_WIDTH,
        addon.L.COOLDOWN_DESCRIPTION
    )

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_PANEL_SETTINGS, -92)

    local enabledCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelEnabled",
        6,
        -118,
        addon.L.COOLDOWN_PANEL_ENABLED
    )
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelEnabled(Widgets:GetCheckValue(self))
    end)

    local lockedCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelLocked",
        6,
        -154,
        addon.L.COOLDOWN_PANEL_LOCKED
    )
    lockedCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelLocked(Widgets:GetCheckValue(self))
    end)

    local resetButton = CreateFrame("Button", "TopDpsCooldownPanelResetPosition", content, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -202)
    resetButton:SetWidth(180)
    resetButton:SetHeight(24)
    resetButton:SetText(addon.L.COOLDOWN_PANEL_RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        addon.CooldownPanel:ResetPosition()
    end)

    local sizeSlider = CreateFrame("Slider", "TopDpsCooldownPanelIconSize", content, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -270)
    sizeSlider:SetWidth(300)
    sizeSlider:SetMinMaxValues(addon.COOLDOWN_PANEL_ICON_SIZE_MIN, addon.COOLDOWN_PANEL_ICON_SIZE_MAX)
    sizeSlider:SetValueStep(addon.COOLDOWN_PANEL_ICON_SIZE_STEP)
    _G[sizeSlider:GetName() .. "Low"]:SetText(tostring(addon.COOLDOWN_PANEL_ICON_SIZE_MIN))
    _G[sizeSlider:GetName() .. "High"]:SetText(tostring(addon.COOLDOWN_PANEL_ICON_SIZE_MAX))
    sizeSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value / addon.COOLDOWN_PANEL_ICON_SIZE_STEP + 0.5)
            * addon.COOLDOWN_PANEL_ICON_SIZE_STEP
        addon.Settings:SetCooldownPanelIconSize(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_ICON_SIZE, rounded))
    end)

    local opacitySlider = CreateFrame("Slider", "TopDpsCooldownPanelOpacity", content, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -344)
    opacitySlider:SetWidth(300)
    opacitySlider:SetMinMaxValues(addon.COOLDOWN_PANEL_OPACITY_MIN, addon.COOLDOWN_PANEL_OPACITY_MAX)
    opacitySlider:SetValueStep(addon.COOLDOWN_PANEL_OPACITY_STEP)
    _G[opacitySlider:GetName() .. "Low"]:SetText("30%")
    _G[opacitySlider:GetName() .. "High"]:SetText("100%")
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value * 20 + 0.5) / 20
        addon.Settings:SetCooldownPanelOpacity(rounded)
        _G[self:GetName() .. "Text"]:SetText(string.format(addon.L.COOLDOWN_PANEL_OPACITY, rounded * 100))
    end)

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_SPEC_SETTINGS, -404)

    local activeSpecText = Widgets:CreateText(content, "GameFontNormal", 8, -434, Widgets.TEXT_WIDTH, "")
    Widgets:CreateText(content, "GameFontNormal", 8, -468, Widgets.TEXT_WIDTH, addon.L.CONFIGURE_SPEC)

    local profileDropdown = CreateFrame(
        "Frame",
        "TopDpsCooldownProfileDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    profileDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -484)
    UIDropDownMenu_SetWidth(profileDropdown, 270)

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

    local resetSpecButton = CreateFrame(
        "Button",
        "TopDpsCooldownPanelResetSpec",
        content,
        "UIPanelButtonTemplate"
    )
    resetSpecButton:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -530)
    resetSpecButton:SetWidth(220)
    resetSpecButton:SetHeight(24)
    resetSpecButton:SetText(addon.L.COOLDOWN_SPEC_RESET)
    resetSpecButton:SetScript("OnClick", function()
        local profile = CooldownOptions:GetSelectedProfile()
        if not profile then
            return
        end

        addon.Settings:ResetCooldownPanelSpecSettings(profile.classToken, profile.talentTab)
    end)

    local combatOnlyCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelCombatOnly",
        6,
        -574,
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

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_ELEMENTS, -622)

    panel:SetScript("OnShow", function()
        self:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.content = content
    self.profiles = profiles
    self.profileDropdown = profileDropdown
    self.activeSpecText = activeSpecText
    self.enabledCheck = enabledCheck
    self.combatOnlyCheck = combatOnlyCheck
    self.lockedCheck = lockedCheck
    self.resetButton = resetButton
    self.resetSpecButton = resetSpecButton
    self.sizeSlider = sizeSlider
    self.opacitySlider = opacitySlider

    local profile = self:GetSelectedProfile()
    if profile then
        self:EnsureElementsView(profile)
    end
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
        return
    end

    UIDropDownMenu_SetSelectedValue(self.profileDropdown, profile.key)
    UIDropDownMenu_SetText(self.profileDropdown, addon.CooldownRegistry:GetProfileDisplayName(profile))

    self.enabledCheck:SetChecked(addon.db.showCooldownPanel and 1 or nil)
    self.combatOnlyCheck:SetChecked(
        addon.Settings:IsCooldownPanelCombatOnly(profile.classToken, profile.talentTab) and 1 or nil
    )
    self.lockedCheck:SetChecked(addon.db.cooldownPanelLocked and 1 or nil)
    self.sizeSlider:SetValue(addon.db.cooldownPanelIconSize)
    self.opacitySlider:SetValue(addon.db.cooldownPanelOpacity)

    _G[self.sizeSlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_ICON_SIZE, addon.db.cooldownPanelIconSize)
    )
    _G[self.opacitySlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_OPACITY, addon.db.cooldownPanelOpacity * 100)
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

    if addon.db.showCooldownPanel then
        self.combatOnlyCheck:Enable()
        self.lockedCheck:Enable()
        self.resetButton:Enable()
        self.sizeSlider:Enable()
        self.opacitySlider:Enable()
    else
        self.combatOnlyCheck:Disable()
        self.lockedCheck:Disable()
        self.resetButton:Disable()
        self.sizeSlider:Disable()
        self.opacitySlider:Disable()
    end
end
