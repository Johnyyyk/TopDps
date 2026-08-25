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
    AuraService = {},
    SwingService = {},
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
    definition.testSettings = { maintainSunderArmor = false }
    function definition:GetSetting(key)
        return self.testSettings[key]
    end
    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

TopDps.AuraService.FindAura = function()
    return nil
end
TopDps.SwingService.IsActionQueued = function()
    return false
end

GetSpellInfo = function(id)
    return tostring(id)
end
GetTime = function()
    return 100
end

dofile("Specs/Warrior/Common.lua")
dofile("Specs/Warrior/Arms.lua")
dofile("Specs/Warrior/Fury.lua")

local Warrior = TopDps.Warrior
local Arms = TopDps.SpecRegistry.providers.WARRIOR_ARMS
local Fury = TopDps.SpecRegistry.providers.WARRIOR_FURY

local context = {
    activeEnemyCount = 1,
    player = {
        power = { current = 80 },
        movement = { moving = false },
    },
    target = {
        health = { maximum = 100, fraction = 0.50 },
    },
    actionsByCategory = {},
}

local activeAuras = {}
Warrior.HasPlayerAura = function(_, ids)
    return activeAuras[ids[1]] == true
end

AssertEqual(Arms:GetPriority(context)[2], "rend", "arms prioritizes Rend after optional Sunder")
AssertEqual(Arms:IsCategoryAllowed("execute", context), false, "arms execute gated above 20 percent")
activeAuras[Warrior.SPELL_IDS.suddenDeath] = true
AssertEqual(Arms:IsCategoryAllowed("execute", context), true, "sudden death enables execute")
activeAuras[Warrior.SPELL_IDS.suddenDeath] = nil
activeAuras[Warrior.SPELL_IDS.tasteForBlood] = true
AssertEqual(Arms:IsCategoryAllowed("overpower", context), true, "taste for blood enables overpower")

AssertEqual(Fury:GetPriority(context)[2], "bloodthirst", "fury single target starts with Bloodthirst after optional Sunder")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = false
AssertEqual(Fury:IsCategoryAllowed("slam", context), false, "fury slam requires Bloodsurge")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = true
AssertEqual(Fury:IsCategoryAllowed("slam", context), true, "bloodsurge enables slam")
AssertEqual(Fury:IsCategoryAllowed("heroicStrike", context), true, "heroic strike is excess rage dump")

context.activeEnemyCount = 3
AssertEqual(Fury:GetPriority(context)[2], "whirlwind", "fury AoE prioritizes Whirlwind after optional Sunder")
AssertEqual(Fury:IsCategoryAllowed("cleave", context), true, "cleave enabled for AoE rage dump")

context.target.health.fraction = 0.15
context.player.power.current = 60
AssertEqual(Fury:IsCategoryAllowed("execute", context), true, "fury execute requires execute range and excess rage")

AssertEqual(Warrior.TALENT_TABS.PROTECTION, 3, "protection remains panel-only talent tab")

print("warrior smoke tests passed")
