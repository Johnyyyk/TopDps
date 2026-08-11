local addon = TopDps
local GeneralOptions = addon:CreateModule("GeneralOptions")
local Widgets = addon.OptionsWidgets
local Layout = addon.OptionsLayout
local Size = Layout.Size

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

function GeneralOptions:ApplyLayout()
    if not self.panel or not self.content then
        return
    end

    Layout:ApplyPanelContent(self.content, self.panel)
    Layout:ApplyTextWidth(self.title, self.content, Size.CONTENT_INSET)
    Layout:ApplyTextWidth(self.description, self.content, Size.CONTENT_INSET)
    Layout:ApplyTextWidth(self.modeLabel, self.content, Size.CONTENT_INSET)
    Layout:ApplyCheckLabelWidth(self.enabledCheck, self.content, 6)
    Layout:ApplyCheckLabelWidth(self.showMinimapCheck, self.content, 6)
    Layout:ApplyDropdownWidth(self.modeDropdown, self.content)
end

function GeneralOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsOptionsPanel", addon.NAME)
    local content = Layout:CreatePanelContent(panel)
    local cursor = Layout:CreateCursor(-8)

    local titleY = Layout:TakeRow(cursor, Size.TITLE_ROW_HEIGHT)
    local title = Layout:CreateText(
        content,
        "GameFontNormalLarge",
        Size.CONTENT_INSET,
        titleY,
        addon.NAME .. " " .. addon.VERSION
    )

    local descriptionY = Layout:TakeRow(cursor, Size.DESCRIPTION_ROW_HEIGHT, Size.SECTION_GAP)
    local description = Layout:CreateText(
        content,
        "GameFontHighlightSmall",
        Size.CONTENT_INSET,
        descriptionY,
        addon.L.ADDON_DESCRIPTION
    )

    local generalHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.GENERAL_SETTINGS, generalHeaderY)

    local enabledY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local enabledCheck = Layout:CreateCheckButton(content, "TopDpsOptionsEnabled", 6, enabledY, addon.L.ENABLED)
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetEnabled(Widgets:GetCheckValue(self))
    end)

    local minimapY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT)
    local showMinimap = Layout:CreateCheckButton(
        content,
        "TopDpsOptionsShowMinimap",
        6,
        minimapY,
        addon.L.SHOW_MINIMAP
    )
    showMinimap:SetScript("OnClick", function(self)
        addon.db.showMinimap = Widgets:GetCheckValue(self)
        addon.MinimapButton:Refresh()
    end)

    Layout:AddGap(cursor, Size.SECTION_GAP)

    local modeY = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT)
    local modeLabel, modeDropdown = Layout:CreateDropdownField(
        content,
        "TopDpsOptionsModeDropDown",
        modeY,
        addon.L.MODE
    )

    UIDropDownMenu_Initialize(modeDropdown, function(_, level)
        local index
        for index = 1, #addon.MODE_ORDER do
            local selectedMode = addon.MODE_ORDER[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = GetModeText(selectedMode)
            info.value = selectedMode
            info.checked = addon.db.mode == selectedMode
            info.func = function()
                addon.Settings:SetMode(selectedMode)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.panel = panel
    self.content = content
    self.title = title
    self.description = description
    self.modeLabel = modeLabel
    self.enabledCheck = enabledCheck
    self.showMinimapCheck = showMinimap
    self.modeDropdown = modeDropdown

    panel:SetScript("OnSizeChanged", function()
        self:ApplyLayout()
    end)
    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
        Layout:RequestNextFrame(panel, function()
            self:ApplyLayout()
        end)
    end)

    InterfaceOptions_AddCategory(panel)
end

function GeneralOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self:ApplyLayout()

    self.enabledCheck:SetChecked(addon.db.enabled and 1 or nil)
    self.showMinimapCheck:SetChecked(addon.db.showMinimap and 1 or nil)

    UIDropDownMenu_SetSelectedValue(self.modeDropdown, addon.db.mode)
    UIDropDownMenu_SetText(self.modeDropdown, GetModeText(addon.db.mode))
end
