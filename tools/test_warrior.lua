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
    definition.testSettings = {
        maintainSunderArmor = false,
        useRendWeaving = false,
    }
    function definition:GetSetting(key)
        return self.testSettings[key]
    end
    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

TopDps.AuraService.FindAura = function() return nil end
TopDps.SwingService.IsActionQueued = function() return false end
GetSpellInfo = function(id) return tostring(id) end
GetTime = function() return 100 end

dofile("Specs/Warrior/Common.lua")
dofile("Specs/Warrior/Arms.lua")
dofile("Specs/Warrior/Fury.lua")

local Warrior = TopDps.Warrior
local Arms = TopDps.SpecRegistry.providers.WARRIOR_ARMS
local Fury = TopDps.SpecRegistry.providers.WARRIOR_FURY

local cooldownRemaining = {
    [1] = 3,
    [2] = 3,
}

local context = {
    activeEnemyCount = 1,
    player = { power = { current = 80 }, movement = { moving = false } },
    target = { health = { maximum = 100, fraction = 0.50 } },
    actionsByCategory = {
        bloodthirst = { { action = 1 } },
        whirlwind = { { action = 2 } },
        heroicStrike = { { action = 3 } },
        cleave = { { action = 4 } },
    },
    readiness = {
        GetActionCooldownRemaining = function(_, action)
            return cooldownRemaining[action] or 0, 4, 1
        end,
    },
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

AssertEqual(Arms:IsCategoryAllowed("overpower", context), true, "dodge Overpower window is not blocked by aura gate")
activeAuras[Warrior.SPELL_IDS.tasteForBlood] = true
AssertEqual(Arms:IsCategoryAllowed("overpower", context), true, "taste for blood also leaves overpower enabled")
activeAuras[Warrior.SPELL_IDS.tasteForBlood] = nil

AssertEqual(Fury:GetPriority(context)[2], "bloodthirst", "fury single target starts with Bloodthirst after optional Sunder")
AssertEqual(Fury:GetPriority(context)[5], "rend", "fury keeps optional Rend after Bloodsurge Slam")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = false
AssertEqual(Fury:IsCategoryAllowed("slam", context), false, "fury slam requires Bloodsurge")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = true
AssertEqual(Fury:IsCategoryAllowed("slam", context), true, "bloodsurge enables slam")
AssertEqual(Fury:IsCategoryAllowed("heroicStrike", context), true, "heroic strike is excess rage dump")

activeAuras[Warrior.SPELL_IDS.bloodsurge] = nil
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "rend weaving is opt-in")
Fury.testSettings.useRendWeaving = true
AssertEqual(Fury:IsCategoryAllowed("rend", context), true, "rend weaving uses a safe free window")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = true
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "Bloodsurge blocks rend weaving")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = nil
cooldownRemaining[1] = 1
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "Bloodthirst coming ready blocks rend weaving")
cooldownRemaining[1] = 3
cooldownRemaining[2] = 1.5
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "Whirlwind coming ready blocks rend weaving")
cooldownRemaining[2] = 3

context.activeEnemyCount = 2
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "rend weaving is single-target only")
context.activeEnemyCount = 3
AssertEqual(Fury:GetPriority(context)[2], "whirlwind", "fury AoE prioritizes Whirlwind after optional Sunder")
AssertEqual(Fury:IsCategoryAllowed("cleave", context), true, "cleave enabled for AoE rage dump")

context.activeEnemyCount = 1
context.target.health.fraction = 0.15
context.player.power.current = 60
AssertEqual(Fury:IsCategoryAllowed("rend", context), false, "rend weaving is skipped in execute range")
AssertEqual(Fury:IsCategoryAllowed("execute", context), true, "fury execute requires execute range and excess rage")
AssertEqual(Warrior.TALENT_TABS.PROTECTION, 3, "protection remains panel-only talent tab")

print("warrior smoke tests passed")
