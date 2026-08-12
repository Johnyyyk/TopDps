local addon = TopDps
local HighlightManager = addon:CreateModule("HighlightManager")

HighlightManager.active = HighlightManager.active or {}

function HighlightManager:GetRenderer(style)
    if style == addon.HIGHLIGHT_CHEESE then
        return addon.CheeseHighlight
    end

    return addon.BlizzardHighlight
end

function HighlightManager:Start(button)
    local style = addon.db.rotation.highlightStyle
    if self.active[button] == style then
        return
    end

    self:Stop(button)
    self:GetRenderer(style):Show(button)
    self.active[button] = style
end

function HighlightManager:Stop(button)
    local style = self.active[button]
    if not style then
        return
    end

    self:GetRenderer(style):Hide(button)
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

function HighlightManager:SetEntries(entries)
    local desired = {}
    local index

    if entries
        and addon.Settings:IsRotationEnabled()
        and addon.Settings:IsModeActive() then
        for index = 1, #entries do
            desired[entries[index].button] = true
        end
    end

    local buttonsToStop = {}
    local button

    for button in pairs(self.active) do
        if not desired[button] then
            table.insert(buttonsToStop, button)
        end
    end

    for index = 1, #buttonsToStop do
        self:Stop(buttonsToStop[index])
    end

    for button in pairs(desired) do
        self:Start(button)
    end
end
