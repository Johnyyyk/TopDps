local addon = TopDps
local HighlightManager = addon:CreateModule("HighlightManager")

HighlightManager.active = HighlightManager.active or {}
HighlightManager.channels = HighlightManager.channels or {}

function HighlightManager:GetRenderer(style)
    if style == addon.HIGHLIGHT_CHEESE then
        return addon.CheeseHighlight
    end

    return addon.BlizzardHighlight
end

function HighlightManager:GetAppearance(channel)
    return addon.HIGHLIGHT_CHANNEL_APPEARANCE[channel]
        or addon.HIGHLIGHT_CHANNEL_APPEARANCE[addon.HIGHLIGHT_CHANNEL_PRIMARY]
end

function HighlightManager:Start(button, channel)
    local style = addon.db.rotation.highlightStyle
    local appearance = self:GetAppearance(channel)
    local active = self.active[button]

    if active
        and active.style == style
        and active.appearanceKey == appearance.key then
        return
    end

    self:Stop(button)
    self:GetRenderer(style):Show(button, appearance)
    self.active[button] = {
        style = style,
        appearanceKey = appearance.key,
    }
end

function HighlightManager:Stop(button)
    local active = self.active[button]
    if not active then
        return
    end

    self:GetRenderer(active.style):Hide(button)
    self.active[button] = nil
end

function HighlightManager:StopAll()
    local buttons = {}
    local button
    local index

    for button in pairs(self.active) do
        table.insert(buttons, button)
    end

    for index = 1, #buttons do
        self:Stop(buttons[index])
    end
end

function HighlightManager:BuildDesiredButtons()
    local desired = {}

    if not addon.Settings:IsRotationEnabled() or not addon.Settings:IsModeActive() then
        return desired
    end

    local channelIndex
    for channelIndex = 1, #addon.HIGHLIGHT_CHANNEL_ORDER do
        local channel = addon.HIGHLIGHT_CHANNEL_ORDER[channelIndex]
        local entries = self.channels[channel]
        local entryIndex

        for entryIndex = 1, #(entries or {}) do
            local button = entries[entryIndex].button
            if button then
                -- Более специализированный канал, находящийся позже в порядке,
                -- определяет оформление при редком пересечении одной кнопки.
                desired[button] = channel
            end
        end
    end

    return desired
end

function HighlightManager:Refresh()
    local desired = self:BuildDesiredButtons()
    local buttonsToStop = {}
    local button
    local index

    for button in pairs(self.active) do
        if not desired[button] then
            table.insert(buttonsToStop, button)
        end
    end

    for index = 1, #buttonsToStop do
        self:Stop(buttonsToStop[index])
    end

    for button, channel in pairs(desired) do
        self:Start(button, channel)
    end
end

function HighlightManager:SetEntries(channel, entries)
    if entries and #entries > 0 then
        self.channels[channel] = entries
    else
        self.channels[channel] = nil
    end

    self:Refresh()
end
