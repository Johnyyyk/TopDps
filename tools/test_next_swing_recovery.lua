local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

TopDps = {
    Modules = {},
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

TopDps.Settings = {
    IsRotationEnabled = function() return true end,
    IsModeActive = function() return true end,
}

UnitIsDeadOrGhost = function() return false end
UnitHasVehicleUI = function() return false end
UnitExists = function() return true end
UnitIsDead = function() return false end
UnitCanAttack = function() return true end

local provider = {
    GetAvailability = function() return true end,
    GetPriority = function() return {} end,
    GetNextSwingPriority = function() return { "heroicStrike" } end,
    IsCategoryEnabled = function() return true end,
    IsCategoryAllowed = function() return true end,
    IsNextSwingCategoryAllowed = function() return true end,
}

TopDps.SpecManager = {
    GetActive = function() return provider end,
}

local heroicStrikeEntry = { spellId = 47450, spellName = "Heroic Strike" }
local abilities = {
    heroicStrike = { heroicStrikeEntry },
}

TopDps.AbilityService = {
    GetAbilities = function() return abilities end,
    BuildAbilitySummary = function() return "heroicStrike=1" end,
}

TopDps.ContextBuilder = {
    Build = function()
        return { enemyCount = 1 }
    end,
}

TopDps.RefreshService = {
    IsCategoryRefreshDue = function() return true end,
}

TopDps.ReadinessService = {
    GetReadyEntries = function(_, entries) return entries end,
}

local queuedCategory = "heroicStrike"
TopDps.SwingService = {
    GetQueuedNextSwingCategory = function() return queuedCategory end,
}

local nextSwingCall
TopDps.RecommendationPresenter = {
    Set = function() end,
    ClearPrimary = function() end,
    SetNextSwing = function(_, _, category)
        nextSwingCall = "set:" .. category
    end,
    ClearNextSwing = function()
        nextSwingCall = "clear"
    end,
    Clear = function() end,
}

TopDps.Logger = {
    SetRotationState = function() end,
}

dofile("Engine/RotationEngine.lua")

TopDps.RotationEngine:UpdateRecommendation()
AssertEqual(nextSwingCall, "clear", "queued Heroic Strike hides the next-swing recommendation")

queuedCategory = nil
nextSwingCall = nil
TopDps.RotationEngine:UpdateRecommendation()
AssertEqual(nextSwingCall, "set:heroicStrike", "Heroic Strike is recommended again after the queue is released")

print("next-swing queue recovery test passed")
