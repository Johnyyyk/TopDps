local addon = TopDps
local GeneralOptions = addon:CreateModule("GeneralOptions")
local Widgets = addon.OptionsWidgets

local CONTENT_INSET = 8
local DROPDOWN_CHROME_WIDTH = 32

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

local function GetFrameWidth(frame)
    local width = frame and frame:GetWidth() or nil
    if not width or width <= 0 then
        return nil
    end

    return width
end

local function ApplyTextWidth(label, parent, x)
    local width = GetFrameWidth(parent)
    if not width then
        return
    end

    label:SetWidth(math.max(1, width - x - CONTENT_INSET))
end

local function CreateText(parent, fontObject, x, y, text)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)
    ApplyTextWidth(label, parent, x)

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

local function ApplyCheckLabelWidth(check, parent, x)
    local width = GetFrameWidth(parent)
    if not width then
        return
    end

    local checkWidth = check:GetWidth() or 32
    local labelOffset = x + checkWidth + 4
    check.label:SetWidth(math.max(1, width - labelOffset - CONTENT_INSET))
end

local function CreateCheckButton(parent, name, x, y, text)
    local check = Widgets:CreateCheckButton(parent, name, x, y, text)
    check.label:ClearAllPoints()
    check.label:SetPoint("TOPLEFT", check, "TOPRIGHT", 4, -4)
    ApplyCheckLabelWidth(check, parent, x)

    return check
end

local function ApplyDropdownWidth(dropdown, parent)
    local width = GetFrameWidth(parent)
    if not width or width <= DROPDOWN_CHROME_WIDTH then
        return
    end

    UIDropDownMenu_SetWidth(dropdown, width - DROPDOWN_CHROME_WIDTH)
end

function GeneralOptions:ApplyLayout()
    local panelWidth = GetFrameWidth(self.panel)
    local panelHeight = self.panel and self.panel:GetHeight() or nil
    if not panelWidth or not panelHeight or panelHeight <= 0 then
        return
    end

    self.content:SetWidth(math.max(1, panelWidth - CONTENT_INSET * 2))
    self.content:SetHeight(math.max(1, panelHeight - CONTENT_INSET * 2))

    ApplyTextWidth(self.title, self.content, CONTENT_INSET)
    ApplyTextWidth(self.description, self.content, CONTENT_INSET)
    ApplyTextWidth(self.modeLabel, self.content, CONTENT_INSET)
    ApplyCheckLabelWidth(self.enabledCheck, self.content, 6)
    ApplyCheckLabelWidth(self.showMinimapCheck, self.content, 6)
    ApplyDropdownWidth(self.modeDropdown, self.content)
end

function GeneralOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsOptionsPanel", addon.NAME)
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
    content:SetWidth(math.max(1, panel:GetWidth() - CONTENT_INSET * 2))
    content:SetHeight(math.max(1, panel:GetHeight() - CONTENT_INSET * 2))

    local title = CreateText(
        content,
        "GameFontNormalLarge",
        CONTENT_INSET,
        -8,
        addon.NAME .. " " .. addon.VERSION
    )
    local description = CreateText(
        content,
        "GameFontHighlightSmall",
        CONTENT_INSET,
        -40,
        addon.L.ADDON_DESCRIPTION
    )

    CreateSectionHeader(content, addon.L.GENERAL_SETTINGS, -82)

    local enabledCheck = CreateCheckButton(content, "TopDpsOptionsEnabled", 6, -104, addon.L.ENABLED)
    enabledCheck:SetScript("OnClick", function(self)
        addon.Settings:SetEnabled(Widgets:GetCheckValue(self))
    end)

    local showMinimap = CreateCheckButton(content, "TopDpsOptionsShowMinimap", 6, -140, addon.L.SHOW_MINIMAP)
    showMinimap:SetScript("OnClick", function(self)
        addon.db.showMinimap = Widgets:GetCheckValue(self)
        addon.MinimapButton:Refresh()
    end)

    local modeLabel = CreateText(content, "GameFontNormal", CONTENT_INSET, -190, addon.L.MODE)

    local modeDropdown = CreateFrame("Frame", "TopDpsOptionsModeDropDown", content, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -8, -206)

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

    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.content = content
    self.title = title
    self.description = description
    self.modeLabel = modeLabel
    self.enabledCheck = enabledCheck
    self.showMinimapCheck = showMinimap
    self.modeDropdown = modeDropdown
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
