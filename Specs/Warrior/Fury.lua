local addon = TopDps
local Warrior = addon.Warrior

local REND_WEAVE_WINDOW = 1.5

local Fury = addon.SpecProvider:Create({
    id = "WARRIOR_FURY",
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.FURY,

    categories = {
        "sunderArmor",
        "bloodthirst",
        "whirlwind",
        "slam",
        "rend",
        "heroicStrike",
        "cleave",
        "execute",
        "thunderClap",
    },

    abilities = {
        sunderArmor = { spellIds = { Warrior.SPELL_IDS.sunderArmor } },
        bloodthirst = { spellIds = { Warrior.SPELL_IDS.bloodthirst } },
        whirlwind = { spellIds = { Warrior.SPELL_IDS.whirlwind } },
        slam = { spellIds = { Warrior.SPELL_IDS.slam } },
        rend = {
            spellIds = { Warrior.SPELL_IDS.rend },
            refresh = {
                auraSpellIds = { Warrior.SPELL_IDS.rend },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                isRefreshDue = function(_, aura)
                    return aura == nil
                end,
            },
        },
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
        {
            type = "checkbox",
            key = "useRendWeaving",
            labelKey = "WARRIOR_FURY_USE_REND_WEAVING",
            default = false,
        },
    },
})

local PRIORITY_SINGLE = {
    "sunderArmor",
    "bloodthirst",
    "whirlwind",
    "slam",
    "rend",
    "heroicStrike",
    "execute",
}

local PRIORITY_AOE = {
    "sunderArmor",
    "whirlwind",
    "thunderClap",
    "bloodthirst",
    "cleave",
    "slam",
    "execute",
}

local function GetCategoryCooldownRemaining(context, category)
    local entries = context and context.actionsByCategory and context.actionsByCategory[category] or nil
    local readiness = context and context.readiness or nil
    if not entries or #entries == 0 or not readiness or not readiness.GetActionCooldownRemaining then
        return 0
    end

    local best = math.huge
    local index
    for index = 1, #entries do
        local remaining, _, enabled = readiness:GetActionCooldownRemaining(entries[index].action)
        if enabled ~= 0 then
            best = math.min(best, math.max(0, tonumber(remaining) or 0))
        end
    end

    if best == math.huge then
        return 0
    end

    return best
end

local function ShouldUseRend(provider, context)
    if provider:GetSetting("useRendWeaving") ~= true then
        return false
    end

    if Warrior:GetEnemyCount(context) >= 2 or Warrior:IsExecuteRange(context) then
        return false
    end

    if Warrior:HasPlayerAura({ Warrior.SPELL_IDS.bloodsurge }) then
        return false
    end

    if Warrior:IsCategoryQueued(context, "heroicStrike") or Warrior:IsCategoryQueued(context, "cleave") then
        return false
    end

    return GetCategoryCooldownRemaining(context, "bloodthirst") > REND_WEAVE_WINDOW
        and GetCategoryCooldownRemaining(context, "whirlwind") > REND_WEAVE_WINDOW
end

function Fury:IsCategoryAllowed(category, context)
    if category == "sunderArmor" then
        return self:GetSetting("maintainSunderArmor") == true and Warrior:ShouldMaintainSunder(context)
    end

    if category == "slam" then
        return Warrior:HasPlayerAura({ Warrior.SPELL_IDS.bloodsurge })
    end

    if category == "rend" then
        return ShouldUseRend(self, context)
    end

    if category == "heroicStrike" then
        return Warrior:GetEnemyCount(context) < 2
            and Warrior:GetRage(context) >= 60
            and not Warrior:IsCategoryQueued(context, category)
    end

    if category == "cleave" then
        return Warrior:GetEnemyCount(context) >= 2
            and Warrior:GetRage(context) >= 50
            and not Warrior:IsCategoryQueued(context, category)
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

addon.SpecRegistry:Register(Fury)
