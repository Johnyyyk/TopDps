local addon = TopDps
local Priest = addon:CreateModule("Priest")

Priest.CLASS_TOKEN = "PRIEST"
Priest.TALENT_TABS = {
    DISCIPLINE = 1,
    HOLY = 2,
    SHADOW = 3,
}

Priest.SPELL_IDS = {
    vampiricTouch = 34914,
    devouringPlague = 2944,
    shadowWordPain = 589,
    mindBlast = 8092,
    mindFlay = 15407,
    mindSear = 48045,
    shadowWordDeath = 32379,
    shadowWeaving = 15258,

    innerFire = 588,
    shadowform = 15473,
    vampiricEmbrace = 15286,
    dispersion = 47585,
    silence = 15487,

    powerInfusion = 10060,
    painSuppression = 33206,
    penance = 47540,
    innerFocus = 14751,
    guardianSpirit = 47788,
    circleOfHealing = 34861,
    prayerOfMending = 33076,
    shadowfiend = 34433,
    hymnOfHope = 64901,
    divineHymn = 64843,
}

function Priest:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Priest:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function Priest:GetShadowWeavingStacks()
    local aura = self:FindPlayerAura({ self.SPELL_IDS.shadowWeaving })
    return math.max(0, tonumber(aura and aura.stacks) or 0)
end

function Priest:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Priest:IsMoving(context)
    return context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
        or false
end

function Priest:HasEnoughTimeToBenefit(context, seconds)
    local timeToDie = context and context.target and tonumber(context.target.timeToDie) or nil
    return timeToDie == nil or timeToDie > seconds
end
