local addon = TopDps
local Shaman = addon.Shaman

local Enhancement = addon.SpecProvider:Create({
    id = "SHAMAN_ENHANCEMENT",
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ENHANCEMENT,

    categories = {
        "maelstrom",
        "stormstrike",
        "flameShock",
        "earthShock",
        "fireNova",
        "lavaLash",
    },

    abilities = {
        maelstrom = {
            spellIds = {
                Shaman.SPELL_IDS.lightningBolt,
                Shaman.SPELL_IDS.chainLightning,
            },
        },
        stormstrike = { spellIds = { Shaman.SPELL_IDS.stormstrike } },
        flameShock = {
            spellIds = { Shaman.SPELL_IDS.flameShock },
            refresh = {
                auraSpellIds = { Shaman.SPELL_IDS.flameShock },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                isRefreshDue = function(_, aura)
                    return aura == nil
                end,
            },
        },
        earthShock = { spellIds = { Shaman.SPELL_IDS.earthShock } },
        fireNova = { spellIds = { Shaman.SPELL_IDS.fireNova } },
        lavaLash = { spellIds = { Shaman.SPELL_IDS.lavaLash } },
    },
})

local PRIORITY_SINGLE = {
    "maelstrom",
    "stormstrike",
    "flameShock",
    "earthShock",
    "fireNova",
    "lavaLash",
}

local PRIORITY_AOE = {
    "maelstrom",
    "fireNova",
    "stormstrike",
    "flameShock",
    "earthShock",
    "lavaLash",
}

function Enhancement:GetReadyEntries(readiness, entries, category, context)
    if category ~= "maelstrom" then
        return readiness:GetDefaultReadyEntries(entries, category, self, context)
    end

    local wantedSpellId = Shaman:GetEnemyCount(context) >= 2
        and Shaman.SPELL_IDS.chainLightning
        or Shaman.SPELL_IDS.lightningBolt
    local wantedName = GetSpellInfo(wantedSpellId)
    local filtered = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if entry.spellId == wantedSpellId or (wantedName and entry.spellName == wantedName) then
            filtered[#filtered + 1] = entry
        end
    end

    return readiness:GetDefaultReadyEntries(filtered, category, self, context)
end

function Enhancement:IsCategoryAllowed(category, context)
    if category == "maelstrom" then
        return Shaman:GetAuraStacks({ Shaman.SPELL_IDS.maelstromWeapon }) >= 5
    end

    if category == "earthShock" then
        return Shaman:HasOwnTargetAura({ Shaman.SPELL_IDS.flameShock })
    end

    if category == "fireNova" then
        return Shaman:GetEnemyCount(context) >= 2
    end

    return true
end

function Enhancement:GetPriority(context)
    if Shaman:GetEnemyCount(context) >= 3 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Enhancement)
