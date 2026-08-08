local addon = RpalTopDps
local Widgets = addon:CreateModule("OptionsWidgets")

-- Blizzard 3.3.5a InterfaceOptionsFrame is 648x520. Its panel container starts
-- at x=213 and ends at x=626, so addon panels have an exact width of 413 and
-- height of 429. Keep all custom content inside this coordinate space.
Widgets.PANEL_WIDTH = 413
Widgets.PANEL_HEIGHT = 429
Widgets.SCROLL_CONTENT_WIDTH = 350
Widgets.TEXT_WIDTH = 326

function Widgets:GetCheckValue(checkButton)
    return checkButton:GetChecked() == 1
end

function Widgets:CreatePanel(name, categoryName, parentCategory)
    local parent = InterfaceOptionsFramePanelContainer or UIParent
    local panel = CreateFrame("Frame", name, parent)
    panel:SetWidth(self.PANEL_WIDTH)
    panel:SetHeight(self.PANEL_HEIGHT)
    panel.name = categoryName
    panel.parent = parentCategory

    return panel
end

function Widgets:CreateScrollArea(panel, name, contentHeight)
    local scrollFrame = CreateFrame("ScrollFrame", name, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 8)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maximum = self:GetVerticalScrollRange() or 0
        local nextValue = current - delta * 42
        nextValue = math.max(0, math.min(maximum, nextValue))
        self:SetVerticalScroll(nextValue)
    end)

    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetWidth(self.SCROLL_CONTENT_WIDTH)
    content:SetHeight(contentHeight)
    content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetScrollChild(content)

    return scrollFrame, content
end

function Widgets:CreateCheckButton(parent, name, x, y, text, width)
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", check, "TOPRIGHT", 4, -4)
    label:SetWidth(width or (self.SCROLL_CONTENT_WIDTH - x - 42))
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)
    check.label = label

    return check
end

function Widgets:CreateSectionHeader(parent, text, y, width)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    label:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.18)
    line:SetPoint("LEFT", label, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "LEFT", width or (self.SCROLL_CONTENT_WIDTH - 8), 0)
    line:SetHeight(1)

    return label
end

function Widgets:CreateText(parent, fontObject, x, y, width, text)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)

    return label
end
