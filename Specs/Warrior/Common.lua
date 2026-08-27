local addon = TopDps
local Warrior = addon:CreateModule("Warrior")

Warrior.CLASS_TOKEN = "WARRIOR"
Warrior.TALENT_TABS = {
    ARMS = 1,
    FURY = 2,
    PROTECTION = 3,
}

Warrior.NEXT_SWING_WINDOW = 1.5
Warrior.HEROIC_STRIKE_RAGE_THRESHOLD = 60
Warrior.CLEAVE_RAGE_THRESHOLD = 50

Warrior.SUNDER_MODE_DISABLED = "DISABLED"
Warrior.SUNDER_MODE_BOSSES = "BOSSES"
Warrior.SUNDER_MODE_BOSSES_AND_ELITES = "BOSSES_AND_ELITES"
Warrior.SUNDER_MODE_ALWAYS = "ALWAYS"
Warrior.SUNDER_MODE_ORDER = {
    Warrior.SUNDER_MODE_DISABLED,
    Warrior.SUNDER_MODE_BOSSES,
    Warrior.SUNDER_MODE_BOSSES_AND_ELITES,
    Warrior.SUNDER_MODE_ALWAYS,
}
Warrior.SUNDER_MODE_LABELS = {
    [Warrior.SUNDER_MODE_DISABLED] = "WARRIOR_SUNDER_MODE_DISABLED",
    [Warrior.SUNDER_MODE_BOSSES] = "WARRIOR_SUNDER_MODE_BOSSES",
    [Warrior.SUNDER_MODE_BOSSES_AND_ELITES] = "WARRIOR_SUNDER_MODE_BOSSES_AND_ELITES",
    [Warrior.SUNDER_MODE_ALWAYS] = "WARRIOR_SUNDER_MODE_ALWAYS",
}

Warrior.SPELL_IDS = {
    rend = 772,
    mortalStrike = 12294,
    overpower = 7384,
    execute = 5308,
    slam = 1464,
    bladestorm = 46924,
    sweepingStrikes = 12328,
    heroicStrike = 78,
    cleave = 845,
    sunderArmor = 7386,
    thunderClap = 6343,

    bloodthirst = 23881,
    whirlwind = 1680,
    deathWish = 12292,
    recklessness = 1719,

    tasteForBlood = 60503,
    suddenDeath = 52437,
    bloodsurge = 46916,

    battleShout = 6673,
    commandingShout = 469,
    battleStance = 2457,
    defensiveStance = 71,
    berserkerStance = 2458,

    berserkerRage = 18499,
    enragedRegeneration = 55694,
    shieldWall = 871,
    lastStand = 12975,
    shieldBlock = 2565,
    spellReflection = 23920,
    pummel = 6552,
    shieldBash = 72,
    taunt = 355,
    intervene = 3411,
    challengingShout = 1161,
    shieldSlam = 23922,
    shockwave = 46968,
    swordAndBoard = 50227,
    vigilance = 50720,
}

function Warrior:CreateSunderArmorSetting()
    return {
        type = "dropdown",
        key = "sunderArmorMode",
        labelKey = "WARRIOR_SUNDER_ARMOR_MODE",
        default = self.SUNDER_MODE_BOSSES,
        values = self.SUNDER_MODE_ORDER,
        valueLabels = self.SUNDER_MODE_LABELS,
    }
end

function Warrior:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Warrior:FindTargetAura(spellIds, ownOnly)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", ownOnly == true)
end

function Warrior:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Warrior:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Warrior:GetRage(context)
    return math.max(0, tonumber(context and context.player and context.player.power and context.player.power.current) or 0)
end

function Warrior:IsExecuteRange(context)
    local health = context and context.target and context.target.health or nil
    return health and health.maximum > 0 and health.fraction <= 0.20 or false
end

function Warrior:IsNextSwingWindowOpen(context)
    local mainHand = context and context.swing and context.swing.mainHand or nil
    if not mainHand or mainHand.nextSwingAt == nil then
        return false
    end

    local remaining = tonumber(mainHand.remaining)
    return remaining ~= nil and remaining <= self.NEXT_SWING_WINDOW
end

function Warrior:IsNextSwingCategoryAllowed(category, context)
    if not self:IsNextSwingWindowOpen(context) then
        return false
    end

    if category == "heroicStrike" then
        return self:GetEnemyCount(context) < 2
            and self:GetRage(context) >= self.HEROIC_STRIKE_RAGE_THRESHOLD
    end

    if category == "cleave" then
        return self:GetEnemyCount(context) >= 2
            and self:GetRage(context) >= self.CLEAVE_RAGE_THRESHOLD
    end

    return false
end

function Warrior:GetAuraRemaining(aura, context)
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

function Warrior:IsSunderTargetAllowed(mode, context)
    if mode == self.SUNDER_MODE_ALWAYS then
        return true
    end

    if mode == self.SUNDER_MODE_DISABLED then
        return false
    end

    local target = context and context.target or nil
    if not target then
        return false
    end

    if target.bossLike == true then
        return true
    end

    if mode == self.SUNDER_MODE_BOSSES_AND_ELITES then
        return target.classification == "elite" or target.classification == "rareelite"
    end

    return false
end

function Warrior:ShouldMaintainSunder(context, mode)
    if not self:IsSunderTargetAllowed(mode, context) then
        return false
    end

    if addon.EffectService:HasEffect(
        addon.EFFECT_MAJOR_ARMOR_REDUCTION,
        "target",
        "HARMFUL",
        {
            excludeOwn = true,
            minimumQuality = addon.EFFECT_QUALITY_FULL,
        }
    ) then
        return false
    end

    local sunder = self:FindTargetAura({ self.SPELL_IDS.sunderArmor }, true)
    if not sunder then
        return true
    end

    if (tonumber(sunder.stacks) or 0) < 5 then
        return true
    end

    return self:GetAuraRemaining(sunder, context) <= 5
end

function Warrior:GetRequiredStanceState(spellId)
    local expectedName = GetSpellInfo and GetSpellInfo(spellId) or nil
    if not expectedName or not GetShapeshiftFormInfo then
        return {
            active = false,
            spellId = spellId,
            statusText = "?",
        }
    end

    local index
    for index = 1, 3 do
        local ok, _, name, active = pcall(GetShapeshiftFormInfo, index)
        if ok and name == expectedName then
            return {
                active = active == true or active == 1,
                spellId = spellId,
            }
        end
    end

    return {
        active = false,
        spellId = spellId,
    }
end
