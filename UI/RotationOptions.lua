local addon = TopDps
local RotationOptions = addon:CreateModule("RotationOptions")
local Widgets = addon.OptionsWidgets

local PROVIDER_VIEW_TOP = 618
local CONTENT_INSET = 8
local SLIDER_LEFT_INSET = 20
local SLIDER_RIGHT_INSET = 12
local DROPDOWN_CHROME_WIDTH = 32

local function MakeFrameToken(value)
    return string.gsub(tostring(value or ""), "[^%w]", "")
end

local function GetHighlightStyleText(style)
    return addon.L["HIGHLIGHT_" .. style] or style
end

local function FormatCooldownLookahead(value)
    return string.format(addon.L.COOLDOWN_LOOKAHEAD_FORMAT, value)
end

local function CreateText(parent, fontObject, x, y, text)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -CONTENT_INSET, y)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)

    return label
end

local function CreateSectionHeader(parent, text, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_INSET, y)
    label:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.18)
    line:SetPoint("LEFT", label, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_INSET, 0)
    line:SetHeight(1)

    return label
end

local function CreateCheckButton(parent, name, x, y, text)
    local check = Widgets:CreateCheckButton(parent, name, x, y, text)
    check.label:ClearAllPoints()
    check.label:SetPoint("TOPLEFT", check, "TOPRIGHT", 4, -4)
    check.label:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -CONTENT_INSET, y - 4)

    return check
end

local function AnchorSlider(slider, parent, y)
    slider:ClearAllPoints()
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", SLIDER_LEFT_INSET, y)
    slider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -SLIDER_RIGHT_INSET, y)
end

local function ApplyDropdownWidth(dropdown, parent)
    local width = parent:GetWidth()
    if not width or width <= DROPDOWN_CHROME_WIDTH then
        return
    end

    UIDropDownMenu_SetWidth(dropdown, width - DROPDOWN_CHROME_WIDTH)
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
    local check = CreateCheckButton(view, name, 6, y, GetSettingLabel(provider, definition))

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
    AnchorSlider(slider, view, y)
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
    CreateText(view, "GameFontNormal", CONTENT_INSET, y, GetSettingLabel(provider, definition))

    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local dropdown = CreateFrame("Frame", name, view, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", view, "TOPLEFT", -8, y - 16)

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
        layoutParent = view,
    }, y - 70
end

function RotationOptions:CreateProviderView(content, provider)
    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -PROVIDER_VIEW_TOP)
    view:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -PROVIDER_VIEW_TOP)

    local controls = {}
    local definitions = provider:GetSettingsDefinition()
    local y = -2
    local index

    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.type == "header" then
            CreateSectionHeader(view, GetSettingLabel(provider, definition), y)
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
    local scrollFrame, content = Widgets:CreateScrollArea(
        panel,
        "TopDpsRotationOptionsScrollFrame",
        PROVIDER_VIEW_TOP + 320
    )

    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)

    CreateText(content, "GameFontNormalLarge", CONTENT_INSET, -8, addon.NAME .. " - " .. addon.L.ROTATION_PAGE)
    CreateText(content, "GameFontHighlightSmall", CONTENT_INSET, -40, addon.L.ROTATION_DESCRIPTION)

    CreateSectionHeader(content, addon.L.GENERAL_SETTINGS, -92)

    local cooldownLookaheadSlider = CreateFrame(
        "Slider",
        "TopDpsOptionsCooldownLookahead",
        content,
        "OptionsSliderTemplate"
    )
    AnchorSlider(cooldownLookaheadSlider, content, -126)
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

    CreateSectionHeader(content, addon.L.VISUAL_SETTINGS, -184)
    CreateText(content, "GameFontNormal", CONTENT_INSET, -212, addon.L.HIGHLIGHT_STYLE)

    local highlightDropdown = CreateFrame("Frame", "TopDpsOptionsHighlightDropDown", content, "UIDropDownMenuTemplate")
    highlightDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -228)

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

    local centerIconsCheck = CreateCheckButton(
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
    AnchorSlider(opacitySlider, content, -340)
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
    AnchorSlider(sizeSlider, content, -398)
    sizeSlider:SetMinMaxValues(addon.CENTER_ICON_SIZE_MIN, addon.CENTER_ICON_SIZE_MAX)
    sizeSlider:SetValueStep(2)

    _G[sizeSlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_SIZE)
    _G[sizeSlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_SIZE_LOW)
    _G[sizeSlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_SIZE_HIGH)

    sizeSlider:SetScript("OnValueChanged", function(_, value)
        addon.Settings:SetCenterIconsSize(math.floor(value / 2 + 0.5) * 2)
    end)

    CreateSectionHeader(content, addon.L.ROTATION_SETTINGS, -466)

    local activeSpecText = CreateText(content, "GameFontNormal", CONTENT_INSET, -498, "")
    CreateText(content, "GameFontNormal", CONTENT_INSET, -532, addon.L.CONFIGURE_SPEC)

    local providerDropdown = CreateFrame(
        "Frame",
        "TopDpsRotationProviderDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    providerDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -548)

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

    content:SetHeight(math.max(scrollFrame:GetHeight(), PROVIDER_VIEW_TOP + maximumSettingsHeight + 12))

    panel:SetScript("OnShow", function()
        self:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.scrollFrame = scrollFrame
    self.content = content
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
        ApplyDropdownWidth(control.frame, control.layoutParent)
        UIDropDownMenu_SetSelectedValue(control.frame, value)
        UIDropDownMenu_SetText(control.frame, GetDropdownValueText(definition, value))
    end
end

function RotationOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    ApplyDropdownWidth(self.highlightDropdown, self.content)
    ApplyDropdownWidth(self.providerDropdown, self.content)

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
