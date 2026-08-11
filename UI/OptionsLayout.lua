local addon = TopDps
local Layout = addon:CreateModule("OptionsLayout")

-- Правила разработки страниц настроек: docs/UI_GUIDELINES.md.
-- Единые размеры и интервалы для страниц настроек TopDps.
-- Значения шаблонов соответствуют FrameXML WoW 3.3.5a:
-- OptionsCheckButtonTemplate = 26x26.
-- UIDropDownMenuTemplate визуально состоит из Left(25) + Middle + Right(25).
-- UIDropDownMenu_SetWidth задаёт ширину Middle и добавляет 25 px к ширине самого frame.
Layout.Size = {
    CONTENT_INSET = 8,
    FALLBACK_CONTENT_WIDTH = 350,
    SCROLL_RIGHT_INSET = 28,
    SCROLL_WHEEL_STEP = 42,

    TITLE_ROW_HEIGHT = 30,
    DESCRIPTION_ROW_HEIGHT = 40,
    SECTION_ROW_HEIGHT = 24,
    TEXT_ROW_HEIGHT = 24,
    ROW_GAP = 4,
    SECTION_GAP = 12,
    BOTTOM_INSET = 12,

    CHECKBOX_SIZE = 26,
    CHECKBOX_LABEL_GAP = 0,
    CHECKBOX_ROW_HEIGHT = 30,

    SLIDER_LEFT_INSET = 12,
    SLIDER_RIGHT_INSET = 12,
    SLIDER_BAR_TOP_OFFSET = 16,
    SLIDER_ROW_HEIGHT = 46,

    DROPDOWN_LEFT_OFFSET = -8,
    DROPDOWN_RIGHT_OFFSET = 8,
    DROPDOWN_LABEL_TO_FRAME = 16,
    DROPDOWN_VISIBLE_CHROME_WIDTH = 50,
    DROPDOWN_ROW_HEIGHT = 48,

    BUTTON_WIDTH = 84,
    BUTTON_HEIGHT = 22,
    BUTTON_GAP = 6,
}

function Layout:GetFrameWidth(frame)
    local width = frame and frame:GetWidth() or nil
    if not width or width <= 0 then
        return nil
    end

    return width
end

function Layout:CreateCursor(top)
    return {
        y = top or -self.Size.CONTENT_INSET,
    }
end

function Layout:TakeRow(cursor, height, gap)
    local y = cursor.y
    cursor.y = cursor.y - height - (gap or 0)

    return y
end

function Layout:AddGap(cursor, gap)
    cursor.y = cursor.y - gap
end

function Layout:GetRequiredHeight(cursor)
    return math.max(1, -cursor.y + self.Size.BOTTOM_INSET)
end

function Layout:ApplyFrameWidth(frame, parent, leftInset, rightInset, fallbackWidth)
    local width = self:GetFrameWidth(parent) or fallbackWidth
    if not width then
        return
    end

    frame:SetWidth(math.max(1, width - (leftInset or 0) - (rightInset or 0)))
end

function Layout:ApplyTextWidth(label, parent, x)
    local width = self:GetFrameWidth(parent)
    if not width then
        return
    end

    label:SetWidth(math.max(1, width - x - self.Size.CONTENT_INSET))
end

function Layout:CreateText(parent, fontObject, x, y, text)
    local label = parent:CreateFontString(nil, "ARTWORK", fontObject)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)
    self:ApplyTextWidth(label, parent, x)

    return label
end

function Layout:CreateSectionHeader(parent, text, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", self.Size.CONTENT_INSET, y)
    label:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.18)
    line:SetPoint("LEFT", label, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -self.Size.CONTENT_INSET, 0)
    line:SetHeight(1)

    return label, line
end

function Layout:ApplyCheckLabelWidth(check, parent, x)
    local width = self:GetFrameWidth(parent)
    if not width then
        return
    end

    local labelOffset = x + self.Size.CHECKBOX_SIZE + self.Size.CHECKBOX_LABEL_GAP
    local labelWidth = math.max(1, width - labelOffset - self.Size.CONTENT_INSET)
    check.label:SetWidth(labelWidth)
    check:SetHitRectInsets(0, -(labelWidth + self.Size.CHECKBOX_LABEL_GAP), 0, 0)
end

function Layout:CreateCheckButton(parent, name, x, y, text)
    local check = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetWidth(self.Size.CHECKBOX_SIZE)
    check:SetHeight(self.Size.CHECKBOX_SIZE)

    local label = _G[name .. "Text"]
    if not label then
        label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    end

    label:ClearAllPoints()
    label:SetPoint("LEFT", check, "RIGHT", self.Size.CHECKBOX_LABEL_GAP, 0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetText(text)
    check.label = label

    self:ApplyCheckLabelWidth(check, parent, x)

    return check
end

function Layout:ApplySliderWidth(slider, parent)
    local width = self:GetFrameWidth(parent)
    if not width then
        return
    end

    slider:SetWidth(math.max(1, width - self.Size.SLIDER_LEFT_INSET - self.Size.SLIDER_RIGHT_INSET))
end

function Layout:CreateSlider(parent, name, rowTop)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        self.Size.SLIDER_LEFT_INSET,
        rowTop - self.Size.SLIDER_BAR_TOP_OFFSET
    )
    self:ApplySliderWidth(slider, parent)

    return slider
end

function Layout:ApplyDropdownWidth(dropdown, parent)
    local parentWidth = self:GetFrameWidth(parent)
    if not parentWidth then
        return
    end

    local visibleWidth = parentWidth
        - self.Size.DROPDOWN_LEFT_OFFSET
        + self.Size.DROPDOWN_RIGHT_OFFSET
    local menuWidth = visibleWidth - self.Size.DROPDOWN_VISIBLE_CHROME_WIDTH
    UIDropDownMenu_SetWidth(dropdown, math.max(1, menuWidth))
end

function Layout:CreateDropdown(parent, name, rowTop)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        self.Size.DROPDOWN_LEFT_OFFSET,
        rowTop - self.Size.DROPDOWN_LABEL_TO_FRAME
    )
    self:ApplyDropdownWidth(dropdown, parent)

    return dropdown
end

function Layout:CreateDropdownField(parent, name, rowTop, labelText)
    local label = self:CreateText(parent, "GameFontNormal", self.Size.CONTENT_INSET, rowTop, labelText)
    local dropdown = self:CreateDropdown(parent, name, rowTop)

    return label, dropdown
end

function Layout:CreateButton(parent, name, text)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetWidth(self.Size.BUTTON_WIDTH)
    button:SetHeight(self.Size.BUTTON_HEIGHT)
    button:SetText(text)

    return button
end

function Layout:CreatePanelContent(panel)
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", self.Size.CONTENT_INSET, -self.Size.CONTENT_INSET)
    self:ApplyPanelContent(content, panel)

    return content
end

function Layout:ApplyPanelContent(content, panel)
    local width = self:GetFrameWidth(panel)
    local height = panel and panel:GetHeight() or nil
    if not width or not height or height <= 0 then
        return
    end

    content:SetWidth(math.max(1, width - self.Size.CONTENT_INSET * 2))
    content:SetHeight(math.max(1, height - self.Size.CONTENT_INSET * 2))
end

function Layout:CreateScrollArea(panel, name, contentHeight)
    local scrollFrame = CreateFrame("ScrollFrame", name, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", self.Size.CONTENT_INSET, -self.Size.CONTENT_INSET)
    scrollFrame:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -self.Size.SCROLL_RIGHT_INSET,
        self.Size.CONTENT_INSET
    )
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maximum = self:GetVerticalScrollRange() or 0
        local nextValue = current - delta * Layout.Size.SCROLL_WHEEL_STEP
        nextValue = math.max(0, math.min(maximum, nextValue))
        self:SetVerticalScroll(nextValue)
    end)

    local content = CreateFrame("Frame", name .. "Content", scrollFrame)
    content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    content:SetWidth(self.Size.FALLBACK_CONTENT_WIDTH)
    content:SetHeight(math.max(1, contentHeight or 1))
    scrollFrame:SetScrollChild(content)

    self:ApplyScrollContentWidth(content, scrollFrame)

    return scrollFrame, content
end

function Layout:ApplyScrollContentWidth(content, scrollFrame)
    self:ApplyFrameWidth(content, scrollFrame, 0, 0, self.Size.FALLBACK_CONTENT_WIDTH)
end

function Layout:RequestNextFrame(frame, callback)
    frame._topDpsDeferredLayout = callback
    frame:SetScript("OnUpdate", function(self)
        local deferred = self._topDpsDeferredLayout
        self._topDpsDeferredLayout = nil
        self:SetScript("OnUpdate", nil)

        if deferred then
            deferred()
        end
    end)
end
