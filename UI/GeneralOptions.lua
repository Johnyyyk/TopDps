local addon = TopDps
local GeneralOptions = addon:CreateModule("GeneralOptions")
local Widgets = addon.OptionsWidgets

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

function GeneralOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsOptionsPanel", addon.NAME)
    local _, content = Widgets:CreateScrollArea(panel, "TopDpsOptionsScrollFrame", 360)

    local title = Widgets:CreateText(
        content,
        "GameFontNormalLarge",
        8,
        -8,
        Widgets.TEXT_WIDTH,
        addon.NAME .. " " .. addon.VERSION
    )

    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetWidth(Widgets.TEXT_WIDTH)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    description:SetText(addon.L.ADDON_DESCRIPTION)

    Widgets:CreateSectionHeader(content, addon.L.GENERAL_SETTINGS, -82)

    local enabledCheck = Widgets:CreateCheckButton(content, "TopDpsOptionsEnabled", 6, -104, addon.L.ENABLED)
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetEnabled(Widgets:GetCheckValue(self))
    end)

    local showMinimap = Widgets:CreateCheckButton(content, "TopDpsOptionsShowMinimap", 6, -140, addon.L.SHOW_MINIMAP)
    showMinimap:SetScript("OnClick", function(self)
        addon.db.showMinimap = Widgets:GetCheckValue(self)
        addon.MinimapButton:Refresh()
    end)

    Widgets:CreateText(content, "GameFontNormal", 8, -190, Widgets.TEXT_WIDTH, addon.L.MODE)

    local modeDropdown = CreateFrame("Frame", "TopDpsOptionsModeDropDown", content, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -206)
    UIDropDownMenu_SetWidth(modeDropdown, 270)

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

    Widgets:CreateText(content, "GameFontHighlightSmall", 8, -286, Widgets.TEXT_WIDTH, addon.L.OPTIONS_HINT)

    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.enabledCheck = enabledCheck
    self.showMinimapCheck = showMinimap
    self.modeDropdown = modeDropdown
end

function GeneralOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self.enabledCheck:SetChecked(addon.db.enabled and 1 or nil)
    self.showMinimapCheck:SetChecked(addon.db.showMinimap and 1 or nil)

    UIDropDownMenu_SetSelectedValue(self.modeDropdown, addon.db.mode)
    UIDropDownMenu_SetText(self.modeDropdown, GetModeText(addon.db.mode))
end
