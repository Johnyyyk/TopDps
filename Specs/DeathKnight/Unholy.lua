local addon = TopDps
local DeathKnight = addon.DeathKnight

local DESOLATION_REFRESH_LEAD = 3

local Unholy = addon.SpecProvider:Create({
    id = "DEATHKNIGHT_UNHOLY",
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.UNHOLY,

    categories = {
        "deathAndDecay",
        "icyTouch",
        "plagueStrike",
        "pestilence",
        "scourgeStrike",
        "bloodStrike",
        "deathCoil",
        "bloodBoil",
    },

    abilities = {
        deathAndDecay = { spellIds = { DeathKnight.SPELL_IDS.deathAndDecay } },
        icyTouch = {
            spellIds = { DeathKnight.SPELL_IDS.icyTouch },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.frostFever },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        plagueStrike = {
            spellIds = { DeathKnight.SPELL_IDS.plagueStrike },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.bloodPlague },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        pestilence = { spellIds = { DeathKnight.SPELL_IDS.pestilence } },
        scourgeStrike = { spellIds = { DeathKnight.SPELL_IDS.scourgeStrike } },
        bloodStrike = { spellIds = { DeathKnight.SPELL_IDS.bloodStrike } },
        deathCoil = { spellIds = { DeathKnight.SPELL_IDS.deathCoil } },
        bloodBoil = { spellIds = { DeathKnight.SPELL_IDS.bloodBoil } },
    },
})

local PRIORITY_SINGLE_TARGET = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "scourgeStrike",
    "bloodStrike",
    "deathCoil",
}

local PRIORITY_SINGLE_TARGET_DESOLATION = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodStrike",
    "scourgeStrike",
    "deathCoil",
}

local PRIORITY_AOE = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "deathCoil",
    "scourgeStrike",
    "bloodStrike",
}

local PRIORITY_AOE_DESOLATION = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodStrike",
    "bloodBoil",
    "deathCoil",
    "scourgeStrike",
}

local function UsesScourgeStrike(context)
    local entries = context and context.abilitiesByCategory and context.abilitiesByCategory.scourgeStrike or nil
    return type(entries) == "table" and #entries > 0
end

function Unholy:OnSpellCatalogBuilt()
    local talentName = GetSpellInfo(DeathKnight.SPELL_IDS.desolationTalent)
    self.desolationTalentRank = talentName
        and addon.GameApi:GetTalentRankByName(DeathKnight.TALENT_TABS.UNHOLY, talentName)
        or 0
end

function Unholy:ShouldMaintainDesolation(context)
    if (tonumber(self.desolationTalentRank) or 0) <= 0 then
        return false
    end

    local aura = DeathKnight:FindPlayerAura(DeathKnight.DESOLATION_AURA_IDS)
    if not aura then
        return true
    end

    return DeathKnight:GetAuraRemaining(aura, context) <= DESOLATION_REFRESH_LEAD
end

function Unholy:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "deathAndDecay" then
        return enemyCount >= 2 or not UsesScourgeStrike(context)
    end

    if category == "pestilence" then
        return DeathKnight:ShouldUsePestilence(context)
    end

    if category == "bloodBoil" then
        return enemyCount >= 2
    end

    return true
end

function Unholy:GetPriority(context)
    local maintainDesolation = self:ShouldMaintainDesolation(context)

    if DeathKnight:GetEnemyCount(context) >= 2 then
        return maintainDesolation and PRIORITY_AOE_DESOLATION or PRIORITY_AOE
    end

    return maintainDesolation and PRIORITY_SINGLE_TARGET_DESOLATION or PRIORITY_SINGLE_TARGET
end

addon.SpecRegistry:Register(Unholy)
