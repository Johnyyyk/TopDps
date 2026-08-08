local addon = TopDps
local ActionBarService = addon:CreateModule("ActionBarService")

ActionBarService.buttons = ActionBarService.buttons or {}

function ActionBarService:CollectButtons()
    self.buttons = {}

    local prefixIndex
    local buttonIndex
    for prefixIndex = 1, #addon.ACTION_BUTTON_PREFIXES do
        local prefix = addon.ACTION_BUTTON_PREFIXES[prefixIndex]
        for buttonIndex = 1, 12 do
            local button = _G[prefix .. buttonIndex]
            if button then
                table.insert(self.buttons, button)
            end
        end
    end
end

function ActionBarService:CollectVisibleActions(provider)
    local actionsByCategory = {}
    local index

    for index = 1, #self.buttons do
        local button = self.buttons[index]
        if button and button:IsVisible() then
            local action = addon.GameApi:GetButtonAction(button)
            if action and HasAction(action) then
                local spellId, spellName = addon.GameApi:GetActionSpellData(action)
                local category = provider:GetSpellCategory(spellId, spellName)

                if category then
                    if not actionsByCategory[category] then
                        actionsByCategory[category] = {}
                    end

                    table.insert(actionsByCategory[category], {
                        button = button,
                        action = action,
                        spellId = spellId,
                        spellName = spellName,
                    })
                end
            end
        end
    end

    return actionsByCategory
end

function ActionBarService:BuildActionSummary(provider, actionsByCategory)
    local parts = {}
    local categories = provider.debugCategories or provider.categories or {}
    local index

    for index = 1, #categories do
        local category = categories[index]
        local entries = actionsByCategory[category]
        local count = entries and #entries or 0
        local first = entries and entries[1]
        local suffix = ""
        if first then
            suffix = "(" .. tostring(first.spellId or first.spellName or "?") .. ")"
        end

        table.insert(parts, category .. "=" .. tostring(count) .. suffix)
    end

    return table.concat(parts, ", ")
end
