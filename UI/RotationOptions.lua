local addon = TopDps
local RotationOptions = addon:CreateModule("RotationOptions")
local Widgets = addon.OptionsWidgets
local Layout = addon.OptionsLayout
local Size = Layout.Size

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

function RotationOptions:CreateCheckbox(view, provider, definition, index, rowTop)
    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local check = Layout:CreateCheckButton(view, name, 6, rowTop, GetSettingLabel(provider, definition))

    check:SetScript("OnClick", function(self)
        provider:SetSetting(definition.key, Widgets:GetCheckValue(self))
    end)

    return {
        type = "checkbox",
        definition = definition,
        frame = check,
        layoutParent = view,
        x = 6,
    }
end

function RotationOptions:CreateSlider(view, provider, definition, index, rowTop)
    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local slider = Layout:CreateSlider(view, name, rowTop)
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
        layoutParent = view,
    }
end

function RotationOptions:CreateDropdown(view, provider, definition, index, rowTop)
    local name = "TopDpsRotation"
        .. MakeFrameToken(provider.id)
        .. MakeFrameToken(definition.key)
        .. tostring(index)
    local label, dropdown = Layout:CreateDropdownField(
        view,
        name,
        rowTop,
        GetSettingLabel(provider, definition)
    )

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
        label = label,
        layoutParent = view,
        labelX = Size.CONTENT_INSET,
    }
end

function RotationOptions:CreateProviderView(content, provider, top)
    local view = CreateFrame("Frame", nil, content)
    view:SetPoint("TOPLEFT", content, "TOPLEFT", 0, top)
    Layout:ApplyFrameWidth(view, content, 0, 0, Size.FALLBACK_CONTENT_WIDTH)

    local controls = {}
    local definitions = provider:GetSettingsDefinition()
    local cursor = Layout:CreateCursor(-2)
    local index

    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.type == "header" then
            local headerY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
            Layout:CreateSectionHeader(view, GetSettingLabel(provider, definition), headerY)
        elseif definition.type == "checkbox" then
            local rowTop = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
            table.insert(controls, self:CreateCheckbox(view, provider, definition, index, rowTop))
        elseif definition.type == "slider" then
            local rowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
            table.insert(controls, self:CreateSlider(view, provider, definition, index, rowTop))
        elseif definition.type == "dropdown" then
            local rowTop = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT, Size.ROW_GAP)
            table.insert(controls, self:CreateDropdown(view, provider, definition, index, rowTop))
        end
    end

    local viewHeight = Layout:GetRequiredHeight(cursor)
    view:SetHeight(viewHeight)

    return {
        frame = view,
        controls = controls,
    }, viewHeight
end

function RotationOptions:ApplyControlLayout(control)
    if control.type == "checkbox" then
        Layout:ApplyCheckLabelWidth(control.frame, control.layoutParent, control.x)
    elseif control.type == "slider" then
        Layout:ApplySliderWidth(control.frame, control.layoutParent)
    elseif control.type == "dropdown" then
        Layout:ApplyTextWidth(control.label, control.layoutParent, control.labelX)
        Layout:ApplyDropdownWidth(control.frame, control.layoutParent)
    end
end

function RotationOptions:ApplyLayout()
    if not self.scrollFrame or not self.content then
        return
    end

    Layout:ApplyScrollContentWidth(self.content, self.scrollFrame)

    local scrollHeight = self.scrollFrame:GetHeight() or 0
    self.content:SetHeight(math.max(scrollHeight, self.requiredContentHeight or 1))

    local index
    for index = 1, #self.layoutTexts do
        local entry = self.layoutTexts[index]
        Layout:ApplyTextWidth(entry.frame, entry.parent, entry.x)
    end

    Layout:ApplyCheckLabelWidth(self.characterEnabledCheck, self.content, Size.CONTENT_INSET)
    Layout:ApplySliderWidth(self.cooldownLookaheadSlider, self.content)
    Layout:ApplyDropdownWidth(self.highlightDropdown, self.content)
    Layout:ApplyCheckLabelWidth(self.centerIconsCheck, self.content, 6)
    Layout:ApplySliderWidth(self.opacitySlider, self.content)
    Layout:ApplySliderWidth(self.sizeSlider, self.content)
    Layout:ApplyDropdownWidth(self.providerDropdown, self.content)

    local _, view
    for _, view in pairs(self.providerViews) do
        Layout:ApplyFrameWidth(view.frame, self.content, 0, 0, Size.FALLBACK_CONTENT_WIDTH)

        for index = 1, #view.controls do
            self:ApplyControlLayout(view.controls[index])
        end
    end
end

function RotationOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsRotationOptionsPanel", addon.L.ROTATION_PAGE, addon.NAME)
    local providers = addon.SpecRegistry:GetAll()
    local providerViews = {}
    local scrollFrame, content = Layout:CreateScrollArea(panel, "TopDpsRotationOptionsScrollFrame", 1)
    local cursor = Layout:CreateCursor(-8)

    local titleY = Layout:TakeRow(cursor, Size.TITLE_ROW_HEIGHT)
    local title = Layout:CreateText(
        content,
        "GameFontNormalLarge",
        Size.CONTENT_INSET,
        titleY,
        addon.NAME .. " - " .. addon.L.ROTATION_PAGE
    )

    local descriptionY = Layout:TakeRow(cursor, Size.DESCRIPTION_ROW_HEIGHT, Size.SECTION_GAP)
    local description = Layout:CreateText(
        content,
        "GameFontHighlightSmall",
        Size.CONTENT_INSET,
        descriptionY,
        addon.L.ROTATION_DESCRIPTION
    )

    local generalHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.ROTATION_GENERAL_SETTINGS, generalHeaderY)

    local enabledY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local characterEnabledCheck = Layout:CreateCheckButton(
        content,
        "TopDpsRotationCharacterEnabled",
        Size.CONTENT_INSET,
        enabledY,
        addon.L.ROTATION_ENABLED
    )
    characterEnabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetRotationEnabled(Widgets:GetCheckValue(self))
    end)

    local cooldownRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.SECTION_GAP)
    local cooldownLookaheadSlider = Layout:CreateSlider(
        content,
        "TopDpsOptionsCooldownLookahead",
        cooldownRowTop
    )
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

    local visualHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.VISUAL_SETTINGS, visualHeaderY)

    local highlightRowTop = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT, Size.ROW_GAP)
    local highlightLabel, highlightDropdown = Layout:CreateDropdownField(
        content,
        "TopDpsOptionsHighlightDropDown",
        highlightRowTop,
        addon.L.HIGHLIGHT_STYLE
    )

    UIDropDownMenu_Initialize(highlightDropdown, function(_, level)
        local styleIndex
        for styleIndex = 1, #addon.HIGHLIGHT_STYLE_ORDER do
            local style = addon.HIGHLIGHT_STYLE_ORDER[styleIndex]
            local info = UIDropDownMenu_CreateInfo()
            info.text = GetHighlightStyleText(style)
            info.value = style
            info.checked = addon.db.rotation.highlightStyle == style
            info.func = function()
                addon.Settings:SetHighlightStyle(style)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local centerIconsY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local centerIconsCheck = Layout:CreateCheckButton(
        content,
        "TopDpsOptionsCenterIcons",
        6,
        centerIconsY,
        addon.L.SHOW_CENTER_ICONS
    )
    centerIconsCheck:SetScript("OnClick", function(self)
        addon.Settings:SetCenterIconsEnabled(Widgets:GetCheckValue(self))
    end)

    local opacityRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.ROW_GAP)
    local opacitySlider = Layout:CreateSlider(content, "TopDpsOptionsCenterOpacity", opacityRowTop)
    opacitySlider:SetMinMaxValues(0.2, 1)
    opacitySlider:SetValueStep(0.05)

    _G[opacitySlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_OPACITY)
    _G[opacitySlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_LOW)
    _G[opacitySlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_HIGH)

    opacitySlider:SetScript("OnValueChanged", function(_, value)
        local rounded = math.floor(value * 20 + 0.5) / 20
        addon.Settings:SetCenterIconsOpacity(rounded)
    end)

    local sizeRowTop = Layout:TakeRow(cursor, Size.SLIDER_ROW_HEIGHT, Size.SECTION_GAP)
    local sizeSlider = Layout:CreateSlider(content, "TopDpsOptionsCenterSize", sizeRowTop)
    sizeSlider:SetMinMaxValues(addon.CENTER_ICON_SIZE_MIN, addon.CENTER_ICON_SIZE_MAX)
    sizeSlider:SetValueStep(2)

    _G[sizeSlider:GetName() .. "Text"]:SetText(addon.L.CENTER_ICONS_SIZE)
    _G[sizeSlider:GetName() .. "Low"]:SetText(addon.L.CENTER_ICONS_SIZE_LOW)
    _G[sizeSlider:GetName() .. "High"]:SetText(addon.L.CENTER_ICONS_SIZE_HIGH)

    sizeSlider:SetScript("OnValueChanged", function(_, value)
        addon.Settings:SetCenterIconsSize(math.floor(value / 2 + 0.5) * 2)
    end)

    local rotationHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.ROTATION_SETTINGS, rotationHeaderY)

    local activeSpecY = Layout:TakeRow(cursor, Size.TEXT_ROW_HEIGHT, Size.ROW_GAP)
    local activeSpecText = Layout:CreateText(content, "GameFontNormal", Size.CONTENT_INSET, activeSpecY, "")

    local providerRowTop = Layout:TakeRow(cursor, Size.DROPDOWN_ROW_HEIGHT, Size.ROW_GAP)
    local configureSpecText, providerDropdown = Layout:CreateDropdownField(
        content,
        "TopDpsRotationProviderDropDown",
        providerRowTop,
        addon.L.CONFIGURE_SPEC
    )

    UIDropDownMenu_Initialize(providerDropdown, function(_, level)
        local providerIndex
        for providerIndex = 1, #providers do
            local provider = providers[providerIndex]
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

    local providerViewTop = cursor.y
    local maximumSettingsHeight = 1
    local providerIndex
    for providerIndex = 1, #providers do
        local provider = providers[providerIndex]
        local view, viewHeight = self:CreateProviderView(content, provider, providerViewTop)
        view.frame:Hide()
        providerViews[provider.id] = view
        maximumSettingsHeight = math.max(maximumSettingsHeight, viewHeight)
    end

    local requiredContentHeight = -providerViewTop + maximumSettingsHeight + Size.BOTTOM_INSET
    content:SetHeight(math.max(scrollFrame:GetHeight() or 0, requiredContentHeight))

    self.panel = panel
    self.scrollFrame = scrollFrame
    self.content = content
    self.requiredContentHeight = requiredContentHeight
    self.providers = providers
    self.providerViews = providerViews
    self.providerDropdown = providerDropdown
    self.activeSpecText = activeSpecText
    self.characterEnabledCheck = characterEnabledCheck
    self.cooldownLookaheadSlider = cooldownLookaheadSlider
    self.highlightDropdown = highlightDropdown
    self.centerIconsCheck = centerIconsCheck
    self.opacitySlider = opacitySlider
    self.sizeSlider = sizeSlider
    self.layoutTexts = {
        { frame = title, parent = content, x = Size.CONTENT_INSET },
        { frame = description, parent = content, x = Size.CONTENT_INSET },
        { frame = highlightLabel, parent = content, x = Size.CONTENT_INSET },
        { frame = activeSpecText, parent = content, x = Size.CONTENT_INSET },
        { frame = configureSpecText, parent = content, x = Size.CONTENT_INSET },
    }

    scrollFrame:SetScript("OnSizeChanged", function()
        self:ApplyLayout()
    end)
    panel:SetScript("OnShow", function()
        self:Refresh()
        Layout:RequestNextFrame(panel, function()
            self:ApplyLayout()
        end)
    end)

    InterfaceOptions_AddCategory(panel)
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

    self:ApplyLayout()

    self.characterEnabledCheck:SetChecked(addon.Settings:IsRotationEnabled() and 1 or nil)

    self.cooldownLookaheadSlider:SetValue(addon.db.rotation.cooldownLookahead)
    _G[self.cooldownLookaheadSlider:GetName() .. "Text"]:SetText(
        FormatCooldownLookahead(addon.db.rotation.cooldownLookahead)
    )

    UIDropDownMenu_SetSelectedValue(self.highlightDropdown, addon.db.rotation.highlightStyle)
    UIDropDownMenu_SetText(self.highlightDropdown, GetHighlightStyleText(addon.db.rotation.highlightStyle))

    self.centerIconsCheck:SetChecked(addon.db.rotation.centerIcons.enabled and 1 or nil)
    self.opacitySlider:SetValue(addon.db.rotation.centerIcons.opacity)
    self.sizeSlider:SetValue(addon.db.rotation.centerIcons.size)

    if addon.db.rotation.centerIcons.enabled then
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
