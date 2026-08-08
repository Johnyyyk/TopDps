local addon = TopDps
local DebugOptions = addon:CreateModule("DebugOptions")
local Widgets = addon.OptionsWidgets

function DebugOptions:Create()
    local panel = Widgets:CreatePanel("TopDpsDebugOptionsPanel", addon.L.DEBUG_PAGE, addon.NAME)

    Widgets:CreateText(panel, "GameFontNormalLarge", 16, -16, 365, addon.NAME .. " - " .. addon.L.DEBUG_PAGE)
    Widgets:CreateText(panel, "GameFontHighlightSmall", 16, -48, 365, addon.L.DEBUG_DESCRIPTION)

    local chatCheck = Widgets:CreateCheckButton(
        panel,
        "TopDpsDebugChatCheck",
        14,
        -82,
        addon.L.DEBUG_CHAT_RECOMMENDATIONS,
        340
    )
    chatCheck:SetScript("OnClick", function(self)
        addon.db.debugChatRecommendations = Widgets:GetCheckValue(self)
        addon.RecommendationPresenter:ResetChatSignature()
    end)

    local loggingCheck = Widgets:CreateCheckButton(
        panel,
        "TopDpsDebugLoggingCheck",
        14,
        -118,
        addon.L.DEBUG_LOGGING,
        340
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

    Widgets:CreateSectionHeader(panel, addon.L.DEBUG_LOG_TITLE, -166, 205)

    local refreshButton = CreateFrame("Button", "TopDpsDebugRefreshButton", panel, "UIPanelButtonTemplate")
    refreshButton:SetWidth(84)
    refreshButton:SetHeight(22)
    refreshButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -108, -154)
    refreshButton:SetText(addon.L.DEBUG_REFRESH)
    refreshButton:SetScript("OnClick", function()
        addon.Logger:WriteDiagnosticSnapshot()
        DebugOptions:RefreshLog(true)
    end)

    local clearButton = CreateFrame("Button", "TopDpsDebugClearButton", panel, "UIPanelButtonTemplate")
    clearButton:SetWidth(84)
    clearButton:SetHeight(22)
    clearButton:SetPoint("LEFT", refreshButton, "RIGHT", 6, 0)
    clearButton:SetText(addon.L.DEBUG_CLEAR)
    clearButton:SetScript("OnClick", function()
        addon.Logger:Clear()
    end)

    local logBorder = CreateFrame("Frame", nil, panel)
    logBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -194)
    logBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 48)
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

    local scrollFrame = CreateFrame("ScrollFrame", "TopDpsDebugLogScrollFrame", logBorder, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", logBorder, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", logBorder, "BOTTOMRIGHT", -28, 8)

    local editBox = CreateFrame("EditBox", "TopDpsDebugLogEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(330)
    editBox:SetHeight(180)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self)
        local height = 180
        if self.GetStringHeight then
            height = math.max(height, self:GetStringHeight() + 24)
        end
        self:SetHeight(height)
    end)

    scrollFrame:SetScrollChild(editBox)

    Widgets:CreateText(panel, "GameFontHighlightSmall", 18, -392, 365, addon.L.DEBUG_COPY_HINT)

    panel:SetScript("OnShow", function()
        addon.OptionsController:Refresh()
        DebugOptions:RefreshLog(true)
    end)

    InterfaceOptions_AddCategory(panel)

    self.panel = panel
    self.chatCheck = chatCheck
    self.loggingCheck = loggingCheck
    self.editBox = editBox
end

function DebugOptions:Refresh()
    if not self.panel or not addon.db then
        return
    end

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

    local height = 180
    if self.editBox.GetStringHeight then
        height = math.max(height, self.editBox:GetStringHeight() + 24)
    end
    self.editBox:SetHeight(height)

    addon.Logger.dirty = false
end
