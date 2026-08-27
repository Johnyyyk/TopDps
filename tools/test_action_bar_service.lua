local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = {
        Modules = {},
        ACTION_BUTTON_PREFIXES = {
            "ActionButton",
            "BonusActionButton",
            "MultiBarBottomLeftButton",
            "MultiBarBottomRightButton",
            "MultiBarRightButton",
            "MultiBarLeftButton",
        },
    }

    function addon:CreateModule(name)
        local module = self.Modules[name]
        if module then
            return module
        end

        module = {}
        self.Modules[name] = module
        self[name] = module
        return module
    end

    return addon
end

local function NewButton(name, visible, action)
    return {
        name = name,
        action = action,
        IsVisible = function()
            return visible
        end,
    }
end

TopDps = NewAddon()

dofile("Core/GameApi.lua")
dofile("Engine/ActionBarService.lua")

local mainButton = NewButton("ActionButton1", false, 1)
local bonusButton = NewButton("BonusActionButton1", true, 1)
_G.ActionButton1 = mainButton
_G.BonusActionButton1 = bonusButton

HasAction = function(action)
    return action == 73
end

GetSpellInfo = function(spellId)
    if spellId == 12294 then
        return "Mortal Strike"
    end

    return nil
end

GetActionInfo = function(action)
    if action == 73 then
        return "spell", 12294, nil, 12294
    end

    return nil
end

ActionButton_CalculateAction = function(button)
    if button == bonusButton then
        return 73
    end

    return button.action
end

local provider = {
    GetSpellCategory = function(_, spellId, spellName)
        if spellId == 12294 or spellName == "Mortal Strike" then
            return "mortalStrike"
        end

        return nil
    end,
}

TopDps.ActionBarService:CollectButtons()
local actions = TopDps.ActionBarService:CollectVisibleActions(provider)
AssertEqual(#TopDps.ActionBarService.buttons, 2, "main and bonus buttons are collected")
AssertEqual(actions.mortalStrike ~= nil, true, "visible bonus action is categorized")
AssertEqual(#actions.mortalStrike, 1, "only visible bonus action is collected")
AssertEqual(actions.mortalStrike[1].action, 73, "bonus action uses paged slot")

-- Некоторые 3.3.5 cores не экспортируют ActionButton_CalculateAction.
-- В таком случае paged helper должен иметь приоритет над stale button.action.
ActionButton_CalculateAction = nil
ActionButton_GetPagedID = function(button)
    if button == bonusButton then
        return 73
    end

    return button.action
end

AssertEqual(
    TopDps.GameApi:GetButtonAction(bonusButton),
    73,
    "paged action fallback wins over static button.action"
)

print("action bar service smoke tests passed")
