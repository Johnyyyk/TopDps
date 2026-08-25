local addon = TopDps
local Warrior = addon.Warrior

local Fury = addon.SpecProvider:Create({
    id = "WARRIOR_FURY",
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.FURY,

    categories = {
        "sunderArmor",
        "bloodthirst",
        "whirlwind",
        "slam",
        "heroicStrike",
        "cleave",
        "execute",
        "thunderClap",
    },

    nextSwingCategories = {
        "heroicStrike",
        "cleave",
    },

    abilities = {
        sunderArmor = { spellIds = { Warrior.SPELL_IDS.sunderArmor } },
        bloodthirst = { spellIds = { Warrior.SPELL_IDS.bloodthirst } },
        whirlwind = { spellIds = { Warrior.SPELL_IDS.whirlwind } },
        slam = { spellIds = { Warrior.SPELL_IDS.slam } },
        heroicStrike = {
            spellIds = { Warrior.SPELL_IDS.heroicStrike },
            swingReset = "MAIN_HAND",
        },
        cleave = {
            spellIds = { Warrior.SPELL_IDS.cleave },
            swingReset = "MAIN_HAND",
        },
        execute = { spellIds = { Warrior.SPELL_IDS.execute } },
        thunderClap = { spellIds = { Warrior.SPELL_IDS.thunderClap } },
    },

    settings = {
        {
            type = "checkbox",
            key = "maintainSunderArmor",
            labelKey = "WARRIOR_MAINTAIN_SUNDER_ARMOR",
            default = false,
        },
    },
})

local PRIORITY_SINGLE = {
    "sunderArmor",
    "bloodthirst",
    "whirlwind",
    "slam",
    "execute",
}

local PRIORITY_AOE = {
    "sunderArmor",
    "whirlwind",
    "thunderClap",
    "bloodthirst",
    "slam",
    "execute",
}

local NEXT_SWING_SINGLE = {
    "heroicStrike",
}

local NEXT_SWING_AOE = {
    "cleave",
}

function Fury:IsCategoryAllowed(category, context)
    if category == "sunderArmor" then
        return self:GetSetting("maintainSunderArmor") == true and Warrior:ShouldMaintainSunder(context)
    end

    if category == "slam" then
        return Warrior:HasPlayerAura({ Warrior.SPELL_IDS.bloodsurge })
    end

    if category == "execute" then
        return Warrior:IsExecuteRange(context) and Warrior:GetRage(context) >= 50
    end

    if category == "thunderClap" then
        return Warrior:GetEnemyCount(context) >= 5
    end

    return true
end

function Fury:GetPriority(context)
    if Warrior:GetEnemyCount(context) >= 2 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

function Fury:GetNextSwingPriority(context)
    if Warrior:GetEnemyCount(context) >= 2 then
        return NEXT_SWING_AOE
    end

    return NEXT_SWING_SINGLE
end

function Fury:IsNextSwingCategoryAllowed(category, context)
    return Warrior:IsNextSwingCategoryAllowed(category, context)
end

addon.SpecRegistry:Register(Fury)
