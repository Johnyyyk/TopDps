local addon = RpalTopDps
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

function ActionBarService:IsActionInRange(action)
    local inRange = IsActionInRange(action)
    return inRange ~= 0
end

function ActionBarService:IsActionCooldownReady(action)
    local start, duration, enabled = GetActionCooldown(action)
    if enabled == 0 then
        return false
    end

    if not start or start == 0 or not duration or duration == 0 then
        return true
    end

    local remaining = start + duration - GetTime()
    if remaining <= 0.15 then
        return true
    end

    -- The recommendation may be displayed during the global cooldown.
    return duration <= 1.6
end

function ActionBarService:IsEntryInRange(entry, category, provider, context)
    if provider.IsEntryInRange then
        return provider:IsEntryInRange(self, entry, category, context)
    end

    return self:IsActionInRange(entry.action)
end

function ActionBarService:IsActionReady(entry, category, provider, context)
    local usable, notEnoughMana = IsUsableAction(entry.action)
    if not usable then
        if notEnoughMana then
            return false
        end

        if not provider:CanTreatUnusableAsUsable(category, entry, context) then
            return false
        end
    end

    if not self:IsEntryInRange(entry, category, provider, context) then
        return false
    end

    return self:IsActionCooldownReady(entry.action)
end

function ActionBarService:GetDefaultReadyEntries(entries, category, provider, context)
    local readyEntries = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if self:IsActionReady(entry, category, provider, context) then
            table.insert(readyEntries, entry)
        end
    end

    return readyEntries
end

function ActionBarService:GetReadyEntries(entries, category, provider, context)
    if provider.GetReadyEntries then
        return provider:GetReadyEntries(self, entries, category, context)
    end

    return self:GetDefaultReadyEntries(entries, category, provider, context)
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
