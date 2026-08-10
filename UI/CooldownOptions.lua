local addon = TopDps
local CooldownOptions = addon:CreateModule("CooldownOptions")
local Widgets = addon.OptionsWidgets

local function GetGroupLabel(group)
    return addon.L["COOLDOWN_GROUP_" .. tostring(group)] or tostring(group)
end

local function BuildEntriesSignature(entries)
    local parts = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        parts[index] = table.concat({
            entry.settingId or "",
            tostring(entry.itemId or entry.spellId or entry.displaySpellId or ""),
            entry.name or "",
        }, ":")
    end

    return table.concat(parts, "|")
end

function CooldownOptions:CreateElementsView(content, entries)
    if self.elementsView then
        self.elementsView:Hide()
    end

    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -456)
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
        check:SetScript("OnClick", function(self)
            addon.Settings:SetCooldownElementEnabled(self.entry.settingId, Widgets:GetCheckValue(self))
        end)

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

function CooldownOptions:EnsureElementsView()
    local entries = addon.CooldownTracker and addon.CooldownTracker:GetConfigurableEntries() or {}
    local signature = BuildEntriesSignature(entries)
    if signature == self.elementsSignature and self.elementsView then
        return entries
    end

    self.elementsRevision = (self.elementsRevision or 0) + 1
    self.elementsSignature = signature
    self:CreateElementsView(self.content, entries)

    return entries
end

function CooldownOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsCooldownOptionsPanel", addon.L.COOLDOWN_PAGE, addon.NAME)
    local _, content = Widgets:CreateScrollArea(panel, "TopDpsCooldownOptionsScrollFrame", 1120)

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

    local combatOnlyCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelCombatOnly",
        6,
        -154,
        addon.L.COOLDOWN_PANEL_COMBAT_ONLY
    )
    combatOnlyCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelCombatOnly(Widgets:GetCheckValue(self))
    end)

    local lockedCheck = Widgets:CreateCheckButton(
        content,
        "TopDpsCooldownPanelLocked",
        6,
        -190,
        addon.L.COOLDOWN_PANEL_LOCKED
    )
    lockedCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCooldownPanelLocked(Widgets:GetCheckValue(self))
    end)

    local resetButton = CreateFrame("Button", "TopDpsCooldownPanelResetPosition", content, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -238)
    resetButton:SetWidth(180)
    resetButton:SetHeight(24)
    resetButton:SetText(addon.L.COOLDOWN_PANEL_RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        addon.CooldownPanel:ResetPosition()
    end)

    local sizeSlider = CreateFrame("Slider", "TopDpsCooldownPanelIconSize", content, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -306)
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
    opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -380)
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

    Widgets:CreateSectionHeader(content, addon.L.COOLDOWN_ELEMENTS, -432)

    panel:SetScript("OnShow", function()
        self:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.content = content
    self.enabledCheck = enabledCheck
    self.combatOnlyCheck = combatOnlyCheck
    self.lockedCheck = lockedCheck
    self.resetButton = resetButton
    self.sizeSlider = sizeSlider
    self.opacitySlider = opacitySlider

    self:EnsureElementsView()
end

function CooldownOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self.enabledCheck:SetChecked(addon.db.showCooldownPanel and 1 or nil)
    self.combatOnlyCheck:SetChecked(addon.db.cooldownPanelCombatOnly and 1 or nil)
    self.lockedCheck:SetChecked(addon.db.cooldownPanelLocked and 1 or nil)
    self.sizeSlider:SetValue(addon.db.cooldownPanelIconSize)
    self.opacitySlider:SetValue(addon.db.cooldownPanelOpacity)

    _G[self.sizeSlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_ICON_SIZE, addon.db.cooldownPanelIconSize)
    )
    _G[self.opacitySlider:GetName() .. "Text"]:SetText(
        string.format(addon.L.COOLDOWN_PANEL_OPACITY, addon.db.cooldownPanelOpacity * 100)
    )

    self:EnsureElementsView()
    local index
    for index = 1, #(self.elementControls or {}) do
        local check = self.elementControls[index]
        local entry = check.entry
        check:SetChecked(addon.Settings:IsCooldownElementEnabled(entry.settingId, entry.defaultEnabled) and 1 or nil)
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
