local addon = TopDps
local RotationOptions = addon:CreateModule("RotationOptions")
local Widgets = addon.OptionsWidgets

local PROVIDER_VIEW_TOP = 618

local function MakeFrameToken(value)
    return string.gsub(tostring(value or ""), "[^%w]", "")
end

local function GetHighlightStyleText(style)
    return addon.L["HIGHLIGHT_" .. style] or style
end

local function FormatCooldownLookahead(value)
    return string.format(addon.L.COOLDOWN_LOOKAHEAD_FORMAT, value)
end

local function GetSettingLabel(provider, definition)
    if definition.labelKey and addon.L[definition.labelKey] then
        return addon.L[definition.labelKey]
    end

    if definition.label then
        return definition.label
    end

    if definition.category then
        return provider:GetCategoryDisplayName(definition.category)
    end

    return tostring(definition.key or "")
end

local function GetDropdownValueText(definition, value)
    local labels = definition.valueLabels
    local label = labels and labels[value] or nil
    if label and addon.L[label] then
        return addon.L[label]
    end

    return label or tostring(value)
end

local function RoundSliderValue(definition, value)
    local step = definition.step or 1
    if step <= 0 then
        return value
    end

    local base = definition.min or 0
    local rounded = base + math.floor((value - base) / step + 0.5) * step

    if definition.min then
        rounded = math.max(definition.min, rounded)
    end

    if definition.max then
        rounded = math.min(definition.max, rounded)
    end

    return rounded
end

local function FormatSliderText(provider, definition, value)
    if type(definition.format) == "function" then
        return definition.format(value)
    end

    if definition.formatKey and addon.L[definition.formatKey] then
        return string.format(addon.L[definition.formatKey], value)
    end

    return string.format("%s: %s", GetSettingLabel(provider, definition), tostring(value))
end

function RotationOptions:CreateCheckbox(view, provider, definition, index, y)
    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local check = Widgets:CreateCheckButton(view, name, 6, y, GetSettingLabel(provider, definition))

    check:SetScript("OnClick", function(self)
        provider:SetSetting(definition.key, Widgets:GetCheckValue(self))
    end)

    return {
        type = "checkbox",
        definition = definition,
        frame = check,
    }, y - 36
end

function RotationOptions:CreateSlider(view, provider, definition, index, y)
    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local slider = CreateFrame("Slider", name, view, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", view, "TOPLEFT", 20, y)
    slider:SetWidth(300)
    slider:SetMinMaxValues(definition.min, definition.max)
    slider:SetValueStep(definition.step or 1)

    _G[name .. "Low"]:SetText(definition.lowLabel or tostring(definition.min))
    _G[name .. "High"]:SetText(definition.highLabel or tostring(definition.max))

    slider:SetScript("OnValueChanged", function(self, value)
        local rounded = RoundSliderValue(definition, value)
        provider:SetSetting(definition.key, rounded)

        local normalized = provider:GetSetting(definition.key)
        _G[self:GetName() .. "Text"]:SetText(FormatSliderText(provider, definition, normalized))
    end)

    return {
        type = "slider",
        definition = definition,
        frame = slider,
    }, y - 60
end

function RotationOptions:CreateDropdown(view, provider, definition, index, y)
    Widgets:CreateText(view, "GameFontNormal", 8, y, Widgets.TEXT_WIDTH, GetSettingLabel(provider, definition))

    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local dropdown = CreateFrame("Frame", name, view, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", view, "TOPLEFT", -8, y - 16)
    UIDropDownMenu_SetWidth(dropdown, 270)

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        local valueIndex
        for valueIndex = 1, #definition.values do
            local value = definition.values[valueIndex]
            local info = UIDropDownMenu_CreateInfo()
            info.text = GetDropdownValueText(definition, value)
            info.value = value
            info.checked = provider:GetSetting(definition.key) == value
            info.func = function()
                provider:SetSetting(definition.key, value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    return {
        type = "dropdown",
        definition = definition,
        frame = dropdown,
    }, y - 70
end

function RotationOptions:CreateProviderView(content, provider)
    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -PROVIDER_VIEW_TOP)
    view:SetWidth(Widgets.SCROLL_CONTENT_WIDTH)

    local controls = {}
    local definitions = provider:GetSettingsDefinition()
    local y = -2
    local index

    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.type == "header" then
            Widgets:CreateSectionHeader(view, GetSettingLabel(provider, definition), y)
            y = y - 34
        elseif definition.type == "checkbox" then
            local control
            control, y = self:CreateCheckbox(view, provider, definition, index, y)
            table.insert(controls, control)
        elseif definition.type == "slider" then
            local control
            control, y = self:CreateSlider(view, provider, definition, index, y)
            table.insert(controls, control)
        elseif definition.type == "dropdown" then
            local control
            control, y = self:CreateDropdown(view, provider, definition, index, y)
            table.insert(controls, control)
        end
    end

    local viewHeight = math.max(1, -y + 20)
    view:SetHeight(viewHeight)

    return {
        frame = view,
        controls = controls,
    }, viewHeight
end

function RotationOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsRotationOptionsPanel", addon.L.ROTATION_PAGE, addon.NAME)
    local providers = addon.SpecRegistry:GetAll()
    local providerViews = {}
    local _, content = Widgets:CreateScrollArea(
        panel,
        "TopDpsRotationOptionsScrollFrame",
        PROVIDER_VIEW_TOP + 320
    )

    Widgets:CreateText(
        content,
        "GameFontNormalLarge",
        8,
        -8,
        Widgets.TEXT_WIDTH,
        addon.NAME .. " - " .. addon.L.ROTATION_PAGE
    )
    Widgets:CreateText(
        content,
        "GameFontHighlightSmall",
        8,
        -40,
        Widgets.TEXT_WIDTH,
        addon.L.ROTATION_DESCRIPTION
    )

    Widgets:CreateSectionHeader(content, addon.L.GENERAL_SETTINGS, -92)

    local cooldownLookaheadSlider = CreateFrame(
        "Slider",
        "TopDpsOptionsCooldownLookahead",
        content,
        "OptionsSliderTemplate"
    )
    cooldownLookaheadSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -126)
    cooldownLookaheadSlider:SetWidth(300)
    cooldownLookaheadSlider:SetMinMaxValues(addon.COOLDOWN_LOOKAHEAD_MIN, addon.COOLDOWN_LOOKAHEAD_MAX)
    cooldownLookaheadSlider:SetValueStep(addon.COOLDOWN_LOOKAHEAD_STEP)

    _G[cooldownLookaheadSlider:GetName() .. "Low"]:SetText(addon.L.COOLDOWN_LOOKAHEAD_LOW)
    _G[cooldownLookaheadSlider:GetName() .. "High"]:SetText(addon.L.COOLDOWN_LOOKAHEAD_HIGH)

    cooldownLookaheadSlider:SetScript("OnValueChanged", function(self, value)
        local steps = math.floor(value / addon.COOLDOWN_LOOKAHEAD_STEP + 0.5)
        local rounded = steps * addon.COOLDOWN_LOOKAHEAD_STEP
        addon.Settings:SetCooldownLookahead(rounded)
        _G[self:GetName() .. "Text"]:SetText(FormatCooldownLookahead(rounded))
    end)

    Widgets:CreateSectionHeader(content, addon.L.VISUAL_SETTINGS, -184)
    Widgets:CreateText(content, "GameFontNormal", 8, -212, Widgets.TEXT_WIDTH, addon.L.HIGHLIGHT_STYLE)

    local highlightDropdown = CreateFrame("Frame", "TopDpsOptionsHighlightDropDown", content, "UIDropDownMenuTemplate")
    highlightDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -228)
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
        "TopDpsOptionsCenterIcons",
        6,
        -286,
        addon.L.SHOW_CENTER_ICONS
    )
    centerIconsCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCenterIconsEnabled(Widgets:GetCheckValue(self))
    end)

    local opacitySlider = CreateFrame("Slider", "TopDpsOptionsCenterOpacity", content, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -340)
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

    local sizeSlider = CreateFrame("Slider", "TopDpsOptionsCenterSize", content, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -398)
    sizeSlider:SetWidth(300)
    sizeSlider:SetMinMaxValues(addon.CENTER_ICON_SIZE_MIN, addon.CENTER_ICON_SIZE_MAX)
    sizeSlider:SetValueStep(2)

    _G[sizeSlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_SIZE)
    _G[sizeSlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_SIZE_LOW)
    _G[sizeSlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_SIZE_HIGH)

    sizeSlider:SetScript("OnValueChanged", function(_, value)
        addon.Settings:SetCenterIconsSize(math.floor(value / 2 + 0.5) * 2)
    end)

    Widgets:CreateSectionHeader(content, addon.L.ROTATION_SETTINGS, -466)

    local activeSpecText = Widgets:CreateText(content, "GameFontNormal", 8, -498, Widgets.TEXT_WIDTH, "")
    Widgets:CreateText(content, "GameFontNormal", 8, -532, Widgets.TEXT_WIDTH, addon.L.CONFIGURE_SPEC)

    local providerDropdown = CreateFrame(
        "Frame",
        "TopDpsRotationProviderDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    providerDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -548)
    UIDropDownMenu_SetWidth(providerDropdown, 270)

    UIDropDownMenu_Initialize(providerDropdown, function(_, level)
        local index
        for index = 1, #providers do
            local provider = providers[index]
            local info = UIDropDownMenu_CreateInfo()
            info.text = provider:GetDisplayName()
            info.value = provider.id
            info.checked = self.selectedProviderId == provider.id
            info.func = function()
                self.selectedProviderId = provider.id
                self:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local maximumSettingsHeight = 1
    local providerIndex
    for providerIndex = 1, #providers do
        local provider = providers[providerIndex]
        local view, viewHeight = self:CreateProviderView(content, provider)
        view.frame:Hide()
        providerViews[provider.id] = view
        maximumSettingsHeight = math.max(maximumSettingsHeight, viewHeight)
    end

    content:SetHeight(PROVIDER_VIEW_TOP + maximumSettingsHeight + 12)

    panel:SetScript("OnShow", function()
        self:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.providers = providers
    self.providerViews = providerViews
    self.providerDropdown = providerDropdown
    self.activeSpecText = activeSpecText
    self.cooldownLookaheadSlider = cooldownLookaheadSlider
    self.highlightDropdown = highlightDropdown
    self.centerIconsCheck = centerIconsCheck
    self.opacitySlider = opacitySlider
    self.sizeSlider = sizeSlider
end

function RotationOptions:GetSelectedProvider()
    if self.selectedProviderId then
        local provider = addon.SpecRegistry:GetById(self.selectedProviderId)
        if provider then
            return provider
        end
    end

    local activeProvider = addon.SpecManager:GetActive()
    if activeProvider then
        self.selectedProviderId = activeProvider.id
        return activeProvider
    end

    local firstProvider = self.providers and self.providers[1] or nil
    if firstProvider then
        self.selectedProviderId = firstProvider.id
    end

    return firstProvider
end

function RotationOptions:RefreshControl(provider, control)
    local definition = control.definition
    local value = provider:GetSetting(definition.key)

    if control.type == "checkbox" then
        control.frame:SetChecked(value and 1 or nil)
    elseif control.type == "slider" then
        control.frame:SetValue(value)
        _G[control.frame:GetName() .. "Text"]:SetText(FormatSliderText(provider, definition, value))
    elseif control.type == "dropdown" then
        UIDropDownMenu_SetSelectedValue(control.frame, value)
        UIDropDownMenu_SetText(control.frame, GetDropdownValueText(definition, value))
    end
end

function RotationOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self.cooldownLookaheadSlider:SetValue(addon.db.cooldownLookahead)
    _G[self.cooldownLookaheadSlider:GetName() .. "Text"]:SetText(
        FormatCooldownLookahead(addon.db.cooldownLookahead)
    )

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

    local activeProvider = addon.SpecManager:GetActive()
    if activeProvider then
        self.activeSpecText:SetText(string.format(addon.L.DETECTED_SPEC, activeProvider:GetDisplayName()))
    else
        self.activeSpecText:SetText(addon.L.DETECTED_SPEC_UNSUPPORTED)
    end

    local provider = self:GetSelectedProvider()
    if not provider then
        UIDropDownMenu_SetText(self.providerDropdown, addon.L.NO_SUPPORTED_SPECS)
        return
    end

    UIDropDownMenu_SetSelectedValue(self.providerDropdown, provider.id)
    UIDropDownMenu_SetText(self.providerDropdown, provider:GetDisplayName())

    local providerId, view
    for providerId, view in pairs(self.providerViews) do
        if providerId == provider.id then
            view.frame:Show()
        else
            view.frame:Hide()
        end
    end

    view = self.providerViews[provider.id]
    if not view then
        return
    end

    local index
    for index = 1, #view.controls do
        self:RefreshControl(provider, view.controls[index])
    end
end
