local function Fail(message) error(message, 2) end
local function AssertEqual(actual, expected, message)
    if actual ~= expected then Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual)) end
end
local function IndexOf(values, expected)
    local index
    for index = 1, #values do if values[index] == expected then return index end end
    return nil
end

GetWeaponEnchantInfo = function() return true, 1000, 0, 1, true, 1000, 0, 2 end
TopDps = { Modules = {}, SpecProvider = {}, SpecRegistry = { providers = {} } }
function TopDps:CreateModule(name) local m = self.Modules[name] or {}; self.Modules[name] = m; self[name] = m; return m end
function TopDps.SpecProvider:Create(definition)
    definition.testSettings = { useExposeArmor = false }
    function definition:GetSetting(key) return self.testSettings[key] end
    return definition
end
function TopDps.SpecRegistry:Register(provider) self.providers[provider.id] = provider end
TopDps.AuraService = { player = {}, target = {} }
function TopDps.AuraService:FindAura(unit, spellIds)
    local source = unit == "player" and self.player or self.target
    local index
    for index = 1, #spellIds do if source[spellIds[index]] then return source[spellIds[index]] end end
    return nil
end

dofile("Specs/Rogue/Common.lua")
dofile("Specs/Rogue/Assassination.lua")
dofile("Specs/Rogue/Combat.lua")
dofile("Specs/Rogue/Subtlety.lua")

local Rogue = TopDps.Rogue
local Assassination = TopDps.SpecRegistry.providers.ROGUE_ASSASSINATION
local Combat = TopDps.SpecRegistry.providers.ROGUE_COMBAT
local Subtlety = TopDps.SpecRegistry.providers.ROGUE_SUBTLETY
local function Context(cp, enemies)
    return { player = { comboPoints = cp or 0 }, activeEnemyCount = enemies or 1, enemyCount = enemies or 1 }
end

AssertEqual(Rogue:GetWeaponPoisonState().active, true, "both weapon poisons")
AssertEqual(Assassination:IsCategoryAllowed("sliceAndDice", Context(1)), true, "Assassination opens SnD")
AssertEqual(Assassination:IsCategoryAllowed("envenom", Context(3)), false, "Envenom waits for four CP")
AssertEqual(Assassination:IsCategoryAllowed("envenom", Context(4)), true, "Envenom at four CP")
TopDps.AuraService.player[Rogue.SPELL_IDS.hungerForBlood] = { spellId = Rogue.SPELL_IDS.hungerForBlood }
AssertEqual(Assassination:IsCategoryAllowed("rupture", Context(5)), false, "no own Rupture while HfB active")
TopDps.AuraService.player = {}
AssertEqual(Assassination:IsCategoryAllowed("rupture", Context(1)), true, "Rupture enables HfB fallback")

AssertEqual(Combat:IsCategoryAllowed("rupture", Context(4)), false, "Combat finisher waits five CP")
AssertEqual(Combat:IsCategoryAllowed("rupture", Context(5)), true, "Combat Rupture at five CP")
AssertEqual(IndexOf(Combat:GetPriority(Context(0, 4)), "fanOfKnives") ~= nil, true, "Combat AoE FoK")

AssertEqual(Subtlety:IsCategoryAllowed("exposeArmor", Context(5)), false, "Expose disabled by default")
Subtlety.testSettings.useExposeArmor = true
AssertEqual(Subtlety:IsCategoryAllowed("exposeArmor", Context(1)), true, "Expose opt-in")
AssertEqual(Subtlety:IsCategoryAllowed("eviscerate", Context(4)), true, "Subtlety finisher at four CP")

print("rogue smoke tests passed")
