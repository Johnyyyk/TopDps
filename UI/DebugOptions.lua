local addon = TopDps
local DebugOptions = addon:CreateModule("DebugOptions")
local Widgets = addon.OptionsWidgets
local Layout = addon.OptionsLayout
local Size = Layout.Size

local LOG_BORDER_INSET = 8
local LOG_SCROLL_RIGHT_INSET = 28
local LOG_EDIT_HORIZONTAL_INSET = 8
local LOG_EDIT_MIN_HEIGHT = 180
local LOG_BOTTOM_INSET = 34
local COPY_HINT_BOTTOM_INSET = 8

function DebugOptions:ApplyLayout()
    if not self.panel or not self.content then
        return
    end

    Layout:ApplyPanelContent(self.content, self.panel)
    Layout:ApplyTextWidth(self.title, self.content, Size.CONTENT_INSET)
    Layout:ApplyTextWidth(self.description, self.content, Size.CONTENT_INSET)
    Layout:ApplyTextWidth(self.copyHint, self.content, Size.CONTENT_INSET)
    Layout:ApplyCheckLabelWidth(self.chatCheck, self.content, 6)
    Layout:ApplyCheckLabelWidth(self.loggingCheck, self.content, 6)

    local scrollWidth = Layout:GetFrameWidth(self.logScrollFrame)
    if scrollWidth then
        self.editBox:SetWidth(math.max(1, scrollWidth - LOG_EDIT_HORIZONTAL_INSET))
    end
end

function DebugOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsDebugOptionsPanel", addon.L.DEBUG_PAGE, addon.NAME)
    local content = Layout:CreatePanelContent(panel)
    local cursor = Layout:CreateCursor(-8)

    local titleY = Layout:TakeRow(cursor, Size.TITLE_ROW_HEIGHT)
    local title = Layout:CreateText(
        content,
        "GameFontNormalLarge",
        Size.CONTENT_INSET,
        titleY,
        addon.NAME .. " - " .. addon.L.DEBUG_PAGE
    )

    local descriptionY = Layout:TakeRow(cursor, Size.DESCRIPTION_ROW_HEIGHT, Size.SECTION_GAP)
    local description = Layout:CreateText(
        content,
        "GameFontHighlightSmall",
        Size.CONTENT_INSET,
        descriptionY,
        addon.L.DEBUG_DESCRIPTION
    )

    local chatCheckY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.ROW_GAP)
    local chatCheck = Layout:CreateCheckButton(
        content,
        "TopDpsDebugChatCheck",
        6,
        chatCheckY,
        addon.L.DEBUG_CHAT_RECOMMENDATIONS
    )
    chatCheck:SetScript("OnClick", function(self)
        addon.db.debugChatRecommendations = Widgets:GetCheckValue(self)
        addon.RecommendationPresenter:ResetChatSignature()
    end)

    local loggingCheckY = Layout:TakeRow(cursor, Size.CHECKBOX_ROW_HEIGHT, Size.SECTION_GAP)
    local loggingCheck = Layout:CreateCheckButton(
        content,
        "TopDpsDebugLoggingCheck",
        6,
        loggingCheckY,
        addon.L.DEBUG_LOGGING
    )
    loggingCheck:SetScript("OnClick", function(self)
        local enabled = Widgets:GetCheckValue(self)
        addon.db.debugLogging = enabled
        addon.Logger:Add("INFO", enabled and addon.L.DEBUG_LOG_ENABLED or addon.L.DEBUG_LOG_DISABLED, true)

        if enabled then
            addon.Logger:WriteDiagnosticSnapshot()
        end

        DebugOptions:RefreshLog(true)
    end)

    local logHeaderY = Layout:TakeRow(cursor, Size.SECTION_ROW_HEIGHT, Size.ROW_GAP)
    Layout:CreateSectionHeader(content, addon.L.DEBUG_LOG_TITLE, logHeaderY)

    local buttonRowY = Layout:TakeRow(cursor, Size.BUTTON_HEIGHT, Size.SECTION_GAP)

    local clearButton = Layout:CreateButton(content, "TopDpsDebugClearButton", addon.L.DEBUG_CLEAR)
    clearButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", -Size.CONTENT_INSET, buttonRowY)
    clearButton:SetScript("OnClick", function()
        addon.Logger:Clear()
    end)

    local refreshButton = Layout:CreateButton(content, "TopDpsDebugRefreshButton", addon.L.DEBUG_REFRESH)
    refreshButton:SetPoint("RIGHT", clearButton, "LEFT", -Size.BUTTON_GAP, 0)
    refreshButton:SetScript("OnClick", function()
        addon.Logger:WriteDiagnosticSnapshot()
        DebugOptions:RefreshLog(true)
    end)

    local logBorder = CreateFrame("Frame", nil, content)
    logBorder:SetPoint("TOPLEFT", content, "TOPLEFT", Size.CONTENT_INSET, cursor.y)
    logBorder:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -Size.CONTENT_INSET, LOG_BOTTOM_INSET)
    logBorder:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    logBorder:SetBackdropColor(0, 0, 0, 0.72)
    logBorder:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local logScrollFrame = CreateFrame(
        "ScrollFrame",
        "TopDpsDebugLogScrollFrame",
        logBorder,
        "UIPanelScrollFrameTemplate"
    )
    logScrollFrame:SetPoint("TOPLEFT", logBorder, "TOPLEFT", LOG_BORDER_INSET, -LOG_BORDER_INSET)
    logScrollFrame:SetPoint(
        "BOTTOMRIGHT",
        logBorder,
        "BOTTOMRIGHT",
        -LOG_SCROLL_RIGHT_INSET,
        LOG_BORDER_INSET
    )

    local editBox = CreateFrame("EditBox", "TopDpsDebugLogEditBox", logScrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(1)
    editBox:SetHeight(LOG_EDIT_MIN_HEIGHT)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self)
        local height = LOG_EDIT_MIN_HEIGHT
        if self.GetStringHeight then
            height = math.max(height, self:GetStringHeight() + 24)
        end
        self:SetHeight(height)
    end)

    logScrollFrame:SetScrollChild(editBox)

    local copyHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        Size.CONTENT_INSET,
        COPY_HINT_BOTTOM_INSET
    )
    copyHint:SetJustifyH("LEFT")
    copyHint:SetJustifyV("BOTTOM")
    copyHint:SetText(addon.L.DEBUG_COPY_HINT)

    self.panel = panel
    self.content = content
    self.title = title
    self.description = description
    self.chatCheck = chatCheck
    self.loggingCheck = loggingCheck
    self.logScrollFrame = logScrollFrame
    self.editBox = editBox
    self.copyHint = copyHint

    panel:SetScript("OnSizeChanged", function()
        self:ApplyLayout()
    end)
    logScrollFrame:SetScript("OnSizeChanged", function()
        self:ApplyLayout()
    end)
    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
        DebugOptions:RefreshLog(true)
        Layout:RequestNextFrame(panel, function()
            self:ApplyLayout()
        end)
    end)

    InterfaceOptions_AddCategory(panel)
end

function DebugOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

    self:ApplyLayout()
    self.chatCheck:SetChecked(addon.db.debugChatRecommendations and 1 or nil)
    self.loggingCheck:SetChecked(addon.db.debugLogging and 1 or nil)
end

function DebugOptions:RefreshLog(force)
    if not self.editBox or not addon.Logger then
        return
    end

    if not force and not addon.Logger.dirty then
        return
    end

    if not self.panel or not self.panel:IsShown() then
        return
    end

    self.editBox:SetText(addon.Logger:GetText())

    local height = LOG_EDIT_MIN_HEIGHT
    if self.editBox.GetStringHeight then
        height = math.max(height, self.editBox:GetStringHeight() + 24)
    end
    self.editBox:SetHeight(height)

    addon.Logger.dirty = false
end
