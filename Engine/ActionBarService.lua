local addon = TopDps
local ActionBarService = addon:CreateModule("ActionBarService")

local ACTION_SLOT_MAX = 120

ActionBarService.buttons = ActionBarService.buttons or {}
ActionBarService.actionSlotsByCategory = ActionBarService.actionSlotsByCategory or {}
ActionBarService.actionSlotsProvider = ActionBarService.actionSlotsProvider or nil

local function AddAction(actionsByCategory, category, button, action, spellId, spellName)
    if not category then
        return
    end

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

    self:RefreshActionSlots()
end

function ActionBarService:CollectVisibleActions(provider)
    local actionsByCategory = {}
    local index

    if not provider then
        return actionsByCategory
    end

    for index = 1, #self.buttons do
        local button = self.buttons[index]
        if button and button:IsVisible() then
            local action = addon.GameApi:GetButtonAction(button)
            if action and HasAction(action) then
                local spellId, spellName = addon.GameApi:GetActionSpellData(action)
                local category = provider:GetSpellCategory(spellId, spellName)
                AddAction(actionsByCategory, category, button, action, spellId, spellName)
            end
        end
    end

    return actionsByCategory
end

function ActionBarService:CollectActionSlots(provider)
    local actionsByCategory = {}

    if not provider or not HasAction then
        self.actionSlotsProvider = provider
        self.actionSlotsByCategory = actionsByCategory
        return actionsByCategory
    end

    local action
    for action = 1, ACTION_SLOT_MAX do
        if HasAction(action) then
            local spellId, spellName = addon.GameApi:GetActionSpellData(action)
            local category = provider:GetSpellCategory(spellId, spellName)
            AddAction(actionsByCategory, category, nil, action, spellId, spellName)
        end
    end

    self.actionSlotsProvider = provider
    self.actionSlotsByCategory = actionsByCategory
    return actionsByCategory
end

function ActionBarService:RefreshActionSlots()
    local provider = addon.SpecManager and addon.SpecManager:GetActive() or nil
    return self:CollectActionSlots(provider)
end

function ActionBarService:GetActionSlots(provider)
    if self.actionSlotsProvider ~= provider or not self.actionSlotsByCategory then
        return self:CollectActionSlots(provider)
    end

    return self.actionSlotsByCategory
end

function ActionBarService:FindVisibleActions(provider, category, recommendedEntries)
    local visibleActions = self:CollectVisibleActions(provider)
    local categoryActions = visibleActions[category] or {}

    if not recommendedEntries or #recommendedEntries == 0 then
        return categoryActions
    end

    local recommendedIds = {}
    local recommendedNames = {}
    local index

    for index = 1, #recommendedEntries do
        local entry = recommendedEntries[index]
        if entry.spellId then
            recommendedIds[entry.spellId] = true
        end
        if entry.spellName then
            recommendedNames[entry.spellName] = true
        end
    end

    local matching = {}
    for index = 1, #categoryActions do
        local entry = categoryActions[index]
        if (entry.spellId and recommendedIds[entry.spellId])
            or (entry.spellName and recommendedNames[entry.spellName]) then
            table.insert(matching, entry)
        end
    end

    return matching
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
