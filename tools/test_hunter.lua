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

UnitExists = function()
    return true
end
UnitIsDead = function()
    return false
end

TopDps = {
    Modules = {},
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
    return definition
end
function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end
TopDps.AuraService = {
    FindAura = function()
        return nil
    end,
}

dofile("Specs/Hunter/Common.lua")
dofile("Specs/Hunter/BeastMastery.lua")
dofile("Specs/Hunter/Marksmanship.lua")
dofile("Specs/Hunter/Survival.lua")

local Hunter = TopDps.Hunter
local BM = TopDps.SpecRegistry.providers.HUNTER_BEAST_MASTERY
local MM = TopDps.SpecRegistry.providers.HUNTER_MARKSMANSHIP
local SV = TopDps.SpecRegistry.providers.HUNTER_SURVIVAL

local function Context(health, enemies, moving)
    return {
        activeEnemyCount = enemies or 1,
        enemyCount = enemies or 1,
        player = { movement = { moving = moving == true } },
        target = { health = { maximum = 100, fraction = health or 1 } },
    }
end

AssertEqual(BM ~= nil and MM ~= nil and SV ~= nil, true, "all Hunter providers")
AssertEqual(BM:IsCategoryAllowed("killShot", Context(0.20)), true, "BM execute")
AssertEqual(BM:IsCategoryAllowed("killShot", Context(0.21)), false, "BM execute threshold")

local mm = MM:GetPriority(Context(1, 1, false))
AssertEqual(IndexOf(mm, "serpentSting") < IndexOf(mm, "chimeraShot"), true, "MM sting before Chimera")
AssertEqual(IndexOf(mm, "chimeraShot") < IndexOf(mm, "aimedShot"), true, "MM Chimera before Aimed")

local sv = SV:GetPriority(Context(1, 1, false))
AssertEqual(IndexOf(sv, "explosiveShot") < IndexOf(sv, "blackArrow"), true, "SV Explosive before Black Arrow")

local moving = SV:GetPriority(Context(1, 1, true))
AssertEqual(IndexOf(moving, "steadyShot"), nil, "moving omits Steady")

local aoe = BM:GetPriority(Context(1, 4, false))
AssertEqual(IndexOf(aoe, "multiShot") < IndexOf(aoe, "volley"), true, "BM AoE starts with Multi-Shot")

print("hunter smoke tests passed")
