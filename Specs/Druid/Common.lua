local addon = TopDps
local Druid = addon:CreateModule("Druid")

Druid.CLASS_TOKEN = "DRUID"
Druid.TALENT_TABS = {
    BALANCE = 1,
    FERAL = 2,
    RESTORATION = 3,
}

Druid.SPELL_IDS = {
    faerieFire = 770,
    moonfire = 8921,
    insectSwarm = 5570,
    wrath = 5176,
    starfire = 2912,
    hurricane = 16914,
    starfall = 48505,
    forceOfNature = 33831,
    moonkinForm = 24858,
    solarEclipse = 48517,
    lunarEclipse = 48518,

    catForm = 768,
    mangleCat = 33876,
    rake = 1822,
    rip = 1079,
    savageRoar = 52610,
    shred = 5221,
    ferociousBite = 22568,
    swipeCat = 62078,
    tigersFury = 5217,
    berserk = 50334,
    clearcasting = 16870,

    barkskin = 22812,
    survivalInstincts = 61336,
    frenziedRegeneration = 22842,
    dash = 1850,
    innervate = 29166,
    rebirth = 20484,

    treeOfLife = 33891,
    naturesSwiftness = 17116,
    swiftmend = 18562,
    wildGrowth = 48438,
    tranquility = 740,
}

function Druid:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Druid:FindTargetAura(spellIds, ownOnly)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", ownOnly == true)
end

function Druid:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Druid:IsCatForm()
    return self:HasPlayerAura({ self.SPELL_IDS.catForm })
end

function Druid:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Druid:GetAuraRemaining(aura, context)
    if not aura then
        return 0
    end

    local expirationTime = tonumber(aura.expirationTime) or 0
    if expirationTime <= 0 then
        return math.huge
    end

    local now = context and tonumber(context.now) or GetTime()
    return math.max(0, expirationTime - now)
end
