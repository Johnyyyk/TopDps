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
    REFRESH_LEAD_CAST_TIME = "CAST_TIME",
    Settings = {},
    AuraService = {},
    EquipmentService = {},
    SpecProvider = {},
    SpecRegistry = { providers = {} },
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

function TopDps.SpecProvider:Create(definition)
    function definition:GetSetting(key)
        if key == "useMovementPriority" then
            return true
        end
        return nil
    end
    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

TopDps.AuraService.FindAura = function()
    return nil
end

GetSpellInfo = function(id)
    return tostring(id)
end

dofile("Specs/Shaman/Common.lua")
dofile("Specs/Shaman/Elemental.lua")
dofile("Specs/Shaman/Enhancement.lua")

local Shaman = TopDps.Shaman
local Elemental = TopDps.SpecRegistry.providers.SHAMAN_ELEMENTAL
local Enhancement = TopDps.SpecRegistry.providers.SHAMAN_ENHANCEMENT

local auraStacks = 0
local flameShock = false

Shaman.GetAuraStacks = function()
    return auraStacks
end

Shaman.HasOwnTargetAura = function()
    return flameShock
end

local stationary = {
    activeEnemyCount = 1,
    player = { movement = { moving = false } },
}
local moving = {
    activeEnemyCount = 1,
    player = { movement = { moving = true } },
}
local aoe = {
    activeEnemyCount = 4,
    player = { movement = { moving = false } },
}

AssertEqual(Elemental:GetPriority(stationary)[1], "flameShock", "elemental starts with Flame Shock")
AssertEqual(Elemental:GetPriority(moving)[2], "earthShock", "elemental movement uses instant shock")
AssertEqual(Elemental:GetPriority(aoe)[1], "chainLightning", "elemental AoE starts with Chain Lightning")

flameShock = false
AssertEqual(Elemental:IsCategoryAllowed("lavaBurst", stationary), false, "Lava Burst requires Flame Shock")
flameShock = true
AssertEqual(Elemental:IsCategoryAllowed("lavaBurst", stationary), true, "Lava Burst allowed with Flame Shock")

 auraStacks = 4
AssertEqual(Enhancement:IsCategoryAllowed("maelstrom", stationary), false, "maelstrom requires five stacks")
auraStacks = 5
AssertEqual(Enhancement:IsCategoryAllowed("maelstrom", stationary), true, "maelstrom allowed at five stacks")
AssertEqual(Enhancement:GetPriority(aoe)[2], "fireNova", "enhancement AoE prioritizes Fire Nova")

AssertEqual(Shaman.TALENT_TABS.ELEMENTAL, 1, "elemental talent tab")
AssertEqual(Shaman.TALENT_TABS.ENHANCEMENT, 2, "enhancement talent tab")
AssertEqual(Shaman.TALENT_TABS.RESTORATION, 3, "restoration talent tab")

print("shaman smoke tests passed")
