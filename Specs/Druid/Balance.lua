local addon = TopDps
local Druid = addon.Druid

local Balance = addon.SpecProvider:Create({
    id = "DRUID_BALANCE",
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.BALANCE,

    categories = {
        "faerieFire",
        "moonfire",
        "insectSwarm",
        "wrath",
        "starfire",
        "hurricane",
    },

    abilities = {
        faerieFire = {
            spellIds = { Druid.SPELL_IDS.faerieFire },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.faerieFire },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = false,
                lead = 5,
            },
        },
        moonfire = {
            spellIds = { Druid.SPELL_IDS.moonfire },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.moonfire },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        insectSwarm = {
            spellIds = { Druid.SPELL_IDS.insectSwarm },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.insectSwarm },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        wrath = {
            spellIds = { Druid.SPELL_IDS.wrath },
        },
        starfire = {
            spellIds = { Druid.SPELL_IDS.starfire },
        },
        hurricane = {
            spellIds = { Druid.SPELL_IDS.hurricane },
        },
    },
})

local PRIORITY_WRATH = {
    "faerieFire",
    "moonfire",
    "insectSwarm",
    "wrath",
}

local PRIORITY_STARFIRE = {
    "faerieFire",
    "moonfire",
    "insectSwarm",
    "starfire",
}

local PRIORITY_MOVING = {
    "faerieFire",
    "insectSwarm",
    "moonfire",
}

local PRIORITY_AOE = {
    "hurricane",
}

function Balance:GetEclipseState()
    if Druid:HasPlayerAura({ Druid.SPELL_IDS.solarEclipse }) then
        self.lastEclipse = "solar"
        return "solar"
    end

    if Druid:HasPlayerAura({ Druid.SPELL_IDS.lunarEclipse }) then
        self.lastEclipse = "lunar"
        return "lunar"
    end

    return nil
end

function Balance:IsCategoryAllowed(category, context)
    local moving = context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true

    if category == "hurricane" then
        return not moving and Druid:GetEnemyCount(context) >= 4
    end

    if category == "wrath" or category == "starfire" then
        return not moving
    end

    if category == "moonfire" or category == "insectSwarm" then
        if moving then
            return true
        end

        return self:GetEclipseState() == nil
    end

    return true
end

function Balance:GetPriority(context)
    local moving = context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true

    if moving then
        return PRIORITY_MOVING
    end

    if Druid:GetEnemyCount(context) >= 4 then
        return PRIORITY_AOE
    end

    local eclipse = self:GetEclipseState()
    if eclipse == "solar" then
        return PRIORITY_WRATH
    end

    if eclipse == "lunar" then
        return PRIORITY_STARFIRE
    end

    if self.lastEclipse == "lunar" then
        return PRIORITY_STARFIRE
    end

    return PRIORITY_WRATH
end

function Balance:GetDebugState()
    return "Eclipse=" .. tostring(self:GetEclipseState() or self.lastEclipse or "none")
end

addon.SpecRegistry:Register(Balance)
