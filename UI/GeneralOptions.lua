local addon = RpalTopDps
local GeneralOptions = addon:CreateModule("GeneralOptions")
local Widgets = addon.OptionsWidgets

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

local function GetHighlightStyleText(style)
    return addon.L["HIGHLIGHT_" .. style] or style
end

function GeneralOptions:Create()
    local panel = Widgets:CreatePanel("RpalTopDpsOptionsPanel", addon.NAME)
    local _, content = Widgets:CreateScrollArea(panel, "RpalTopDpsOptionsScrollFrame", 690)

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

    local enabledCheck = Widgets:CreateCheckButton(
        content,
        "RpalTopDpsOptionsEnabled",
        6,
        -104,
        addon.L.ENABLED
    )
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetEnabled(Widgets:GetCheckValue(self))
    end)

    local showMinimap = Widgets:CreateCheckButton(
        content,
        "RpalTopDpsOptionsShowMinimap",
        6,
        -140,
        addon.L.SHOW_MINIMAP
    )
    showMinimap:SetScript("OnClick", function(self)
        addon.db.showMinimap = Widgets:GetCheckValue(self)
        addon.MinimapButton:Refresh()
    end)

    local modeLabel = Widgets:CreateText(content, "GameFontNormal", 8, -190, Widgets.TEXT_WIDTH, addon.L.MODE)

    local modeDropdown = CreateFrame(
        "Frame",
        "RpalTopDpsOptionsModeDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
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

    Widgets:CreateSectionHeader(content, addon.L.VISUAL_SETTINGS, -274)

    Widgets:CreateText(content, "GameFontNormal", 8, -302, Widgets.TEXT_WIDTH, addon.L.HIGHLIGHT_STYLE)

    local highlightDropdown = CreateFrame(
        "Frame",
        "RpalTopDpsOptionsHighlightDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    highlightDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -318)
    UIDropDownMenu_SetWidth(highlightDropdown, 270)

    UIDropDownMenu_Initialize(highlightDropdown, function(_, level)
        local index
        for index = 1, #addon.HIGHLIGHT_STYLE_ORDER do
            local style = addon.HIGHLIGHT_STYLE_ORDER[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = GetHighlightStyleText(style)
            info.value = style
            info.checked = addon.db.highlightStyle == style
            info.func = function()
                addon.Settings:SetHighlightStyle(style)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local centerIconsCheck = Widgets:CreateCheckButton(
        content,
        "RpalTopDpsOptionsCenterIcons",
        6,
        -378,
        addon.L.SHOW_CENTER_ICONS
    )
    centerIconsCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCenterIconsEnabled(Widgets:GetCheckValue(self))
    end)

    local opacitySlider = CreateFrame(
        "Slider",
        "RpalTopDpsOptionsCenterOpacity",
        content,
        "OptionsSliderTemplate"
    )
    opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -446)
    opacitySlider:SetWidth(300)
    opacitySlider:SetMinMaxValues(0.2, 1)
    opacitySlider:SetValueStep(0.05)

    _G[opacitySlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_OPACITY)
    _G[opacitySlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_LOW)
    _G[opacitySlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_HIGH)

    opacitySlider:SetScript("OnValueChanged", function(_, value)
        local rounded = math.floor(value * 20 + 0.5) / 20
        addon.Settings:SetCenterIconsOpacity(rounded)
    end)

    local sizeSlider = CreateFrame(
        "Slider",
        "RpalTopDpsOptionsCenterSize",
        content,
        "OptionsSliderTemplate"
    )
    sizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -520)
    sizeSlider:SetWidth(300)
    sizeSlider:SetMinMaxValues(addon.CENTER_ICON_SIZE_MIN, addon.CENTER_ICON_SIZE_MAX)
    sizeSlider:SetValueStep(2)

    _G[sizeSlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_SIZE)
    _G[sizeSlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_SIZE_LOW)
    _G[sizeSlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_SIZE_HIGH)

    sizeSlider:SetScript("OnValueChanged", function(_, value)
        addon.Settings:SetCenterIconsSize(math.floor(value / 2 + 0.5) * 2)
    end)

    Widgets:CreateText(
        content,
        "GameFontHighlightSmall",
        8,
        -600,
        Widgets.TEXT_WIDTH,
        addon.L.OPTIONS_HINT
    )

    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.enabledCheck = enabledCheck
    self.showMinimapCheck = showMinimap
    self.modeDropdown = modeDropdown
    self.highlightDropdown = highlightDropdown
    self.centerIconsCheck = centerIconsCheck
    self.opacitySlider = opacitySlider
    self.sizeSlider = sizeSlider
end

function GeneralOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self.enabledCheck:SetChecked(addon.db.enabled and 1 or nil)
    self.showMinimapCheck:SetChecked(addon.db.showMinimap and 1 or nil)

    UIDropDownMenu_SetSelectedValue(self.modeDropdown, addon.db.mode)
    UIDropDownMenu_SetText(self.modeDropdown, GetModeText(addon.db.mode))

    UIDropDownMenu_SetSelectedValue(self.highlightDropdown, addon.db.highlightStyle)
    UIDropDownMenu_SetText(self.highlightDropdown, GetHighlightStyleText(addon.db.highlightStyle))

    self.centerIconsCheck:SetChecked(addon.db.showCenterIcons and 1 or nil)
    self.opacitySlider:SetValue(addon.db.centerIconsOpacity)
    self.sizeSlider:SetValue(addon.db.centerIconsSize)

    if addon.db.showCenterIcons then
        self.opacitySlider:Enable()
        self.sizeSlider:Enable()
    else
        self.opacitySlider:Disable()
        self.sizeSlider:Disable()
    end
end
