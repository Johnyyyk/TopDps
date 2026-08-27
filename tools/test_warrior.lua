local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function Contains(list, expected)
    local index
    for index = 1, #list do
        if list[index] == expected then
            return true
        end
    end

    return false
end

local sunderAura
local exposeAura

TopDps = {
    Modules = {},
    AuraService = {},
    EffectService = {},
    SpecProvider = {},
    SpecRegistry = { providers = {} },
    EFFECT_MAJOR_ARMOR_REDUCTION = "MAJOR_ARMOR_REDUCTION",
    EFFECT_QUALITY_FULL = 2,
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

function TopDps.SpecProvider:Create(definition)
    definition.testSettings = { sunderArmorMode = "BOSSES" }
    function definition:GetSetting(key)
        return self.testSettings[key]
    end
    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

function TopDps.EffectService:HasEffect(effectId, unit, filter, options)
    AssertEqual(effectId, TopDps.EFFECT_MAJOR_ARMOR_REDUCTION, "warrior checks major armor reduction effect")
    AssertEqual(unit, "target", "warrior checks target effect")
    AssertEqual(filter, "HARMFUL", "warrior checks harmful effect")
    AssertEqual(options.excludeOwn, true, "warrior excludes own armor reduction from equivalent check")
    AssertEqual(options.minimumQuality, TopDps.EFFECT_QUALITY_FULL, "warrior requires full armor reduction")
    return exposeAura ~= nil
end

TopDps.AuraService.FindAura = function(_, unit, spellIds)
    if unit ~= "target" or type(spellIds) ~= "table" then
        return nil
    end

    if spellIds[1] == 7386 then
        return sunderAura
    end

    return nil
end
GetSpellInfo = function(id) return tostring(id) end
GetTime = function() return 100 end

dofile("Specs/Warrior/Common.lua")
dofile("Specs/Warrior/Arms.lua")
dofile("Specs/Warrior/Fury.lua")

local Warrior = TopDps.Warrior
local Arms = TopDps.SpecRegistry.providers.WARRIOR_ARMS
local Fury = TopDps.SpecRegistry.providers.WARRIOR_FURY

local context = {
    activeEnemyCount = 1,
    player = { power = { current = 80 }, movement = { moving = false } },
    target = {
        health = { maximum = 100, fraction = 0.50 },
        bossLike = false,
        classification = "normal",
    },
    actionsByCategory = {},
    swing = {
        mainHand = {
            nextSwingAt = 100.75,
            remaining = 0.75,
        },
    },
}

local activeAuras = {}
Warrior.HasPlayerAura = function(_, ids)
    return activeAuras[ids[1]] == true
end

AssertEqual(Arms.settings[1].type, "dropdown", "arms Sunder setting uses target-mode dropdown")
AssertEqual(Arms.settings[1].default, Warrior.SUNDER_MODE_BOSSES, "Sunder defaults to bosses only")
AssertEqual(Fury.settings[1].default, Warrior.SUNDER_MODE_BOSSES, "fury Sunder uses the same default")

AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), false, "default Sunder mode ignores normal mobs")
context.target.bossLike = true
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "default Sunder mode allows bosses")

sunderAura = { stacks = 4, expirationTime = 110 }
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "Sunder continues stacking below five stacks")
sunderAura = { stacks = 5, expirationTime = 110 }
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), false, "fresh five-stack Sunder is not refreshed early")
sunderAura.expirationTime = 104
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "five-stack Sunder is refreshed near expiration")

exposeAura = { stacks = 5, expirationTime = 110 }
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), false, "equivalent major armor reduction suppresses Sunder maintenance")
exposeAura = nil
sunderAura = nil

Arms.testSettings.sunderArmorMode = Warrior.SUNDER_MODE_DISABLED
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), false, "disabled Sunder mode suppresses bosses too")
Arms.testSettings.sunderArmorMode = Warrior.SUNDER_MODE_BOSSES_AND_ELITES
context.target.bossLike = false
context.target.classification = "elite"
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "bosses-and-elites mode allows elite mobs")
context.target.classification = "rareelite"
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "bosses-and-elites mode allows rare elites")
context.target.classification = "normal"
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), false, "bosses-and-elites mode still ignores normal mobs")
Arms.testSettings.sunderArmorMode = Warrior.SUNDER_MODE_ALWAYS
AssertEqual(Arms:IsCategoryAllowed("sunderArmor", context), true, "always mode allows normal mobs")
Arms.testSettings.sunderArmorMode = Warrior.SUNDER_MODE_BOSSES
context.target.bossLike = false

AssertEqual(Arms:GetPriority(context)[2], "rend", "arms prioritizes Rend after optional Sunder")
AssertEqual(Contains(Arms:GetPriority(context), "heroicStrike"), false, "arms primary priority excludes Heroic Strike")
AssertEqual(Contains(Arms:GetPriority(context), "cleave"), false, "arms primary priority excludes Cleave")
AssertEqual(Arms:GetNextSwingPriority(context)[1], "heroicStrike", "arms single-target next-swing uses Heroic Strike")
AssertEqual(Arms:IsNextSwingCategoryAllowed("heroicStrike", context), true, "arms Heroic Strike uses safe rage threshold near swing")
AssertEqual(Arms:IsCategoryAllowed("execute", context), false, "arms execute gated above 20 percent")
activeAuras[Warrior.SPELL_IDS.suddenDeath] = true
AssertEqual(Arms:IsCategoryAllowed("execute", context), true, "sudden death enables execute")
activeAuras[Warrior.SPELL_IDS.suddenDeath] = nil

AssertEqual(Arms:IsCategoryAllowed("overpower", context), true, "dodge Overpower window is not blocked by aura gate")
activeAuras[Warrior.SPELL_IDS.tasteForBlood] = true
AssertEqual(Arms:IsCategoryAllowed("overpower", context), true, "taste for blood also leaves overpower enabled")

AssertEqual(Fury:GetPriority(context)[2], "bloodthirst", "fury single target starts with Bloodthirst after optional Sunder")
AssertEqual(Contains(Fury:GetPriority(context), "heroicStrike"), false, "fury primary priority excludes Heroic Strike")
AssertEqual(Contains(Fury:GetPriority(context), "cleave"), false, "fury primary priority excludes Cleave")
AssertEqual(Fury:GetNextSwingPriority(context)[1], "heroicStrike", "fury single-target next-swing uses Heroic Strike")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = false
AssertEqual(Fury:IsCategoryAllowed("slam", context), false, "fury slam requires Bloodsurge")
activeAuras[Warrior.SPELL_IDS.bloodsurge] = true
AssertEqual(Fury:IsCategoryAllowed("slam", context), true, "bloodsurge enables slam")
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), true, "fury Heroic Strike is available near the main-hand swing")

context.swing.mainHand.nextSwingAt = 101.50
context.swing.mainHand.remaining = 1.50
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), true, "next-swing window includes the 1.5 second boundary")
context.swing.mainHand.nextSwingAt = 101.75
context.swing.mainHand.remaining = 1.75
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), false, "next-swing does not stay highlighted through the full swing interval")
context.swing.mainHand.remaining = 0.75
context.swing.mainHand.nextSwingAt = nil
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), false, "unknown swing timer does not open next-swing window")
context.swing.mainHand.nextSwingAt = 100.75

context.player.power.current = 59
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), false, "fury Heroic Strike requires 60 rage")
context.player.power.current = 80

context.activeEnemyCount = 2
AssertEqual(Fury:GetPriority(context)[2], "whirlwind", "fury AoE prioritizes Whirlwind after optional Sunder")
AssertEqual(Fury:GetNextSwingPriority(context)[1], "cleave", "fury switches next-swing to Cleave at two targets")
AssertEqual(Fury:IsNextSwingCategoryAllowed("cleave", context), true, "fury Cleave is available at two targets")
AssertEqual(Arms:GetNextSwingPriority(context)[1], "cleave", "arms switches next-swing to Cleave at two targets")
AssertEqual(Contains(Arms:GetPriority(context), "sweepingStrikes"), false, "arms main rotation remains single-target at two enemies")
AssertEqual(Arms:IsNextSwingCategoryAllowed("cleave", context), true, "arms Cleave is independent from main AoE threshold")

context.player.power.current = 49
AssertEqual(Fury:IsNextSwingCategoryAllowed("cleave", context), false, "fury Cleave requires 50 rage")
context.player.power.current = 80

context.activeEnemyCount = 3
AssertEqual(Contains(Arms:GetPriority(context), "sweepingStrikes"), true, "arms main AoE priority still starts at three enemies")

context.activeEnemyCount = 1
context.target.health.fraction = 0.15
AssertEqual(Arms:GetNextSwingPriority(context)[1], "heroicStrike", "arms still selects Heroic Strike category in execute for channel evaluation")
AssertEqual(Arms:IsNextSwingCategoryAllowed("heroicStrike", context), false, "arms does not recommend Heroic Strike in execute phase")
context.player.power.current = 60
AssertEqual(Fury:IsCategoryAllowed("execute", context), true, "fury execute requires execute range and excess rage")
AssertEqual(Fury:IsNextSwingCategoryAllowed("heroicStrike", context), true, "fury keeps independent Heroic Strike rule in execute")
AssertEqual(Warrior.TALENT_TABS.PROTECTION, 3, "protection remains panel-only talent tab")

print("warrior smoke tests passed")
