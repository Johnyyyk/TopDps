local function Fail(message)
    error(message, 2)
end
local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end
local function IndexOf(values, expected)
    local index
    for index = 1, #values do
        if values[index] == expected then
            return index
        end
    end
    return nil
end

TopDps = { Modules = {}, SpecProvider = {}, SpecRegistry = { providers = {} } }
function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end
function TopDps.SpecProvider:Create(definition)
    definition.testSettings = { fillerMode = "fireball" }
    function definition:GetSetting(key)
        return self.testSettings[key]
    end
    return definition
end
function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

TopDps.AuraService = { helpful = {}, harmful = {} }
function TopDps.AuraService:FindAura(_, spellIds, filter)
    local source = filter == "HARMFUL" and self.harmful or self.helpful
    local index
    for index = 1, #spellIds do
        local aura = source[spellIds[index]]
        if aura then
            return aura
        end
    end
    return nil
end

dofile("Specs/Mage/Common.lua")
dofile("Specs/Mage/Arcane.lua")
dofile("Specs/Mage/Fire.lua")
dofile("Specs/Mage/Frost.lua")

local Mage = TopDps.Mage
local Arcane = TopDps.SpecRegistry.providers.MAGE_ARCANE
local Fire = TopDps.SpecRegistry.providers.MAGE_FIRE
local Frost = TopDps.SpecRegistry.providers.MAGE_FROST

local function Context(enemies, moving, mana)
    return {
        activeEnemyCount = enemies or 1,
        enemyCount = enemies or 1,
        player = {
            movement = { moving = moving == true },
            power = { fraction = mana or 1 },
        },
    }
end

TopDps.AuraService.harmful[Mage.SPELL_IDS.arcaneBlastStack] = { stacks = 4 }
AssertEqual(Arcane:IsCategoryAllowed("arcaneMissiles", Context()), true, "AB4 uses missiles")
TopDps.AuraService.harmful = {}
AssertEqual(Arcane:IsCategoryAllowed("arcaneMissiles", Context()), false, "no AB stacks")
AssertEqual(IndexOf(Arcane:GetPriority(Context(4, true)), "arcaneExplosion") ~= nil, true, "moving Arcane AoE")

TopDps.AuraService.helpful[Mage.SPELL_IDS.hotStreak] = { stacks = 1 }
AssertEqual(Fire:IsCategoryAllowed("pyroblast", Context()), true, "Hot Streak Pyro")
Fire.testSettings.fillerMode = "frostfire"
AssertEqual(Fire:IsCategoryAllowed("fireball", Context()), false, "Fireball mode disabled")
AssertEqual(Fire:IsCategoryAllowed("frostfireBolt", Context()), true, "Frostfire mode enabled")
TopDps.AuraService.helpful = {}

TopDps.AuraService.helpful[Mage.SPELL_IDS.fingersOfFrost] = { stacks = 2 }
AssertEqual(Frost:IsCategoryAllowed("deepFreeze", Context()), true, "FoF Deep Freeze")
TopDps.AuraService.helpful = { [Mage.SPELL_IDS.brainFreeze] = { stacks = 1 } }
AssertEqual(Frost:IsCategoryAllowed("frostfireBolt", Context()), true, "Brain Freeze FFB")
AssertEqual(IndexOf(Frost:GetPriority(Context(4, false)), "blizzard") ~= nil, true, "Frost AoE")

print("mage smoke tests passed")
