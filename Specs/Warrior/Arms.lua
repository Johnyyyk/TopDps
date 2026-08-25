local addon = TopDps
local Warrior = addon.Warrior

local Arms = addon.SpecProvider:Create({
    id = "WARRIOR_ARMS",
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.ARMS,
    categories = { "sunderArmor", "rend", "execute", "overpower", "bladestorm", "sweepingStrikes", "thunderClap", "mortalStrike", "slam", "heroicStrike", "cleave" },
    nextSwingCategories = { "heroicStrike", "cleave" },
    abilities = {
        sunderArmor = { spellIds = { Warrior.SPELL_IDS.sunderArmor } },
        rend = {
            spellIds = { Warrior.SPELL_IDS.rend },
            refresh = {
                auraSpellIds = { Warrior.SPELL_IDS.rend }, unit = "target", filter = "HARMFUL", ownOnly = true,
                isRefreshDue = function(_, aura) return aura == nil end,
            },
        },
        execute = { spellIds = { Warrior.SPELL_IDS.execute } },
        overpower = { spellIds = { Warrior.SPELL_IDS.overpower } },
        bladestorm = { spellIds = { Warrior.SPELL_IDS.bladestorm } },
        sweepingStrikes = { spellIds = { Warrior.SPELL_IDS.sweepingStrikes } },
        thunderClap = { spellIds = { Warrior.SPELL_IDS.thunderClap } },
        mortalStrike = { spellIds = { Warrior.SPELL_IDS.mortalStrike } },
        slam = { spellIds = { Warrior.SPELL_IDS.slam } },
        heroicStrike = { spellIds = { Warrior.SPELL_IDS.heroicStrike }, swingReset = "MAIN_HAND" },
        cleave = { spellIds = { Warrior.SPELL_IDS.cleave }, swingReset = "MAIN_HAND" },
    },
    settings = {
        Warrior:CreateSunderArmorSetting(),
    },
})

local PRIORITY_SINGLE = { "sunderArmor", "rend", "execute", "overpower", "bladestorm", "mortalStrike", "slam" }
local PRIORITY_EXECUTE = { "sunderArmor", "execute", "overpower", "rend", "mortalStrike" }
local PRIORITY_AOE = { "sunderArmor", "rend", "sweepingStrikes", "overpower", "bladestorm", "thunderClap", "mortalStrike", "slam" }
local NEXT_SWING_SINGLE = { "heroicStrike" }
local NEXT_SWING_AOE = { "cleave" }

function Arms:IsCategoryAllowed(category, context)
    if category == "sunderArmor" then
        return Warrior:ShouldMaintainSunder(context, self:GetSetting("sunderArmorMode"))
    end

    if category == "execute" then
        return Warrior:IsExecuteRange(context) or Warrior:HasPlayerAura({ Warrior.SPELL_IDS.suddenDeath })
    end

    if category == "overpower" then
        -- Taste for Blood — основной источник окна, но обычный dodge proc также
        -- должен проходить. Реальную доступность проверяет IsUsableAction.
        return true
    end

    if category == "bladestorm" then
        if Warrior:HasPlayerAura({ Warrior.SPELL_IDS.suddenDeath, Warrior.SPELL_IDS.tasteForBlood }) then return false end
        local rend = Warrior:FindTargetAura({ Warrior.SPELL_IDS.rend }, true)
        return Warrior:GetAuraRemaining(rend, context) >= 7
    end

    if category == "sweepingStrikes" or category == "thunderClap" then return Warrior:GetEnemyCount(context) >= 2 end
    if category == "slam" then
        return not (context and context.player and context.player.movement and context.player.movement.moving)
    end
    return true
end

function Arms:GetPriority(context)
    if Warrior:GetEnemyCount(context) >= 3 then return PRIORITY_AOE end
    if Warrior:IsExecuteRange(context) then return PRIORITY_EXECUTE end
    return PRIORITY_SINGLE
end

function Arms:GetNextSwingPriority(context)
    if Warrior:GetEnemyCount(context) >= 2 then
        return NEXT_SWING_AOE
    end

    return NEXT_SWING_SINGLE
end

function Arms:IsNextSwingCategoryAllowed(category, context)
    if category == "heroicStrike" and Warrior:IsExecuteRange(context) then
        return false
    end

    return Warrior:IsNextSwingCategoryAllowed(category, context)
end

addon.SpecRegistry:Register(Arms)
