local addon = TopDps

local Retribution = addon.SpecProvider:Create({
    id = "PALADIN_RETRIBUTION",
    classToken = addon.Paladin.CLASS_TOKEN,
    talentTab = addon.Paladin.TALENT_TABS.RETRIBUTION,
    defaultForClass = true,

    categories = {
        "judgement",
        "hammerOfWrath",
        "crusaderStrike",
        "divineStorm",
        "consecration",
        "exorcism",
        "holyWrath",
    },

    abilities = {
        judgement = {
            spellIds = {
                20271, -- Judgement of Light
                53408, -- Judgement of Wisdom
                53407, -- Judgement of Justice
            },
        },
        hammerOfWrath = {
            spellIds = { 24275, 24274, 24239, 27180, 48805, 48806 },
        },
        crusaderStrike = {
            spellIds = { 35395 },
        },
        divineStorm = {
            spellIds = { 53385 },
        },
        consecration = {
            spellIds = { 26573, 20116, 20922, 20923, 20924, 27173, 48818, 48819 },
        },
        exorcism = {
            spellIds = { 879, 5614, 5615, 10312, 10313, 10314, 27138, 48800, 48801 },
        },
        holyWrath = {
            spellIds = { 2812, 10318, 27139, 48816, 48817 },
        },
    },
})

Retribution.debugCategories = Retribution.categories

local SPELL_IDS = {
    artOfWarAura = 59578,
}

local T9_ITEMS = {
    [48602] = true, [48603] = true, [48604] = true, [48605] = true, [48606] = true,
    [48607] = true, [48608] = true, [48609] = true, [48610] = true, [48611] = true,
    [48612] = true, [48613] = true, [48614] = true, [48615] = true, [48616] = true,
    [48617] = true, [48618] = true, [48619] = true, [48620] = true, [48621] = true,
    [48622] = true, [48623] = true, [48624] = true, [48625] = true, [48626] = true,
    [48627] = true, [48628] = true, [48629] = true, [48630] = true, [48631] = true,
}

local T10_ITEMS = {
    [50324] = true, [50325] = true, [50326] = true, [50327] = true, [50328] = true,
    [51160] = true, [51161] = true, [51162] = true, [51163] = true, [51164] = true,
    [51275] = true, [51276] = true, [51277] = true, [51278] = true, [51279] = true,
}

local TIER_SLOTS = {
    1,
    3,
    5,
    7,
    10,
}

-- Таблицы ниже — основное место для ручного изменения порядка способностей.
local PRIORITY = {
    level1To19 = {
        "judgement",
    },
    level20To43 = {
        "judgement",
        "consecration",
        "exorcism",
    },
    level44To49 = {
        "hammerOfWrath",
        "judgement",
        "exorcism",
        "consecration",
    },
    level50To59Short = {
        "hammerOfWrath",
        "judgement",
        "crusaderStrike",
        "exorcism",
        "consecration",
    },
    level50To59Long = {
        "crusaderStrike",
        "hammerOfWrath",
        "judgement",
        "exorcism",
        "consecration",
    },
    level60To79Short = {
        "hammerOfWrath",
        "divineStorm",
        "judgement",
        "crusaderStrike",
        "exorcism",
        "consecration",
        "holyWrath",
    },
    level60To79Long = {
        "crusaderStrike",
        "hammerOfWrath",
        "judgement",
        "divineStorm",
        "exorcism",
        "consecration",
        "holyWrath",
    },
    levelingAoe = {
        "hammerOfWrath",
        "divineStorm",
        "judgement",
        "crusaderStrike",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    preT9 = {
        "crusaderStrike",
        "hammerOfWrath",
        "judgement",
        "divineStorm",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    t9 = {
        "judgement",
        "hammerOfWrath",
        "crusaderStrike",
        "divineStorm",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    level80Aoe = {
        "judgement",
        "hammerOfWrath",
        "divineStorm",
        "crusaderStrike",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    t10TwoPiece = {
        "divineStorm",
        "judgement",
        "crusaderStrike",
        "hammerOfWrath",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    t9T10Mixed = {
        "judgement",
        "divineStorm",
        "hammerOfWrath",
        "crusaderStrike",
        "consecration",
        "exorcism",
        "holyWrath",
    },
    t10FourPiece = {
        "judgement",
        "divineStorm",
        "crusaderStrike",
        "hammerOfWrath",
        "consecration",
        "exorcism",
        "holyWrath",
    },
}

function Retribution:OnSpellCatalogBuilt()
    self.artOfWarAuraName = GetSpellInfo(SPELL_IDS.artOfWarAura)
end

function Retribution:OnEquipmentChanged()
    local t9Count = 0
    local t10Count = 0
    local index

    for index = 1, #TIER_SLOTS do
        local itemId = addon.GameApi:GetInventoryItemId(TIER_SLOTS[index])
        if itemId then
            if T9_ITEMS[itemId] then
                t9Count = t9Count + 1
            end

            if T10_ITEMS[itemId] then
                t10Count = t10Count + 1
            end
        end
    end

    self.t9Count = t9Count
    self.t10Count = t10Count
end

function Retribution:GetDebugState()
    return "T9=" .. tostring(self.t9Count or 0) .. ", T10=" .. tostring(self.t10Count or 0)
end

function Retribution:CanTreatUnusableAsUsable(category, entry, context)
    if category == "hammerOfWrath" then
        return self:IsTargetBelowExecuteRange()
    end

    if category == "divineStorm" then
        return self:IsTargetInMelee(context)
    end

    if category == "exorcism" then
        return not self:IsTargetInMelee(context) or self:HasArtOfWarAura()
    end

    return false
end

function Retribution:GetReadyEntries(readiness, entries, category, context)
    if category ~= "judgement" then
        return readiness:GetDefaultReadyEntries(entries, category, self, context)
    end

    local readyEntries = {}
    local anyReady = false
    local index

    for index = 1, #entries do
        if readiness:IsActionReady(entries[index], category, self, context) then
            anyReady = true
            break
        end
    end

    if not anyReady then
        return readyEntries
    end

    for index = 1, #entries do
        local entry = entries[index]
        if readiness:IsEntryInRange(entry, category, self, context)
            and readiness:IsActionCooldownReady(entry.action) then
            table.insert(readyEntries, entry)
        end
    end

    return readyEntries
end

function Retribution:HasArtOfWarAura()
    local index
    for index = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", index)
        if not name then
            break
        end

        if spellId == SPELL_IDS.artOfWarAura
            or (self.artOfWarAuraName and name == self.artOfWarAuraName) then
            return true
        end
    end

    return false
end

function Retribution:IsTargetInMelee(context)
    local crusaderActions = context.actionsByCategory.crusaderStrike
    local sawDefiniteOutOfRange = false

    if crusaderActions then
        local index
        for index = 1, #crusaderActions do
            local range = IsActionInRange(crusaderActions[index].action)
            if range == 1 then
                return true
            end

            if range == 0 then
                sawDefiniteOutOfRange = true
            end
        end
    end

    local crusaderName = self.spellNameByCategory.crusaderStrike
    if crusaderName and IsSpellInRange then
        local range = IsSpellInRange(crusaderName, "target")
        if range == 1 then
            return true
        end

        if range == 0 then
            sawDefiniteOutOfRange = true
        end
    end

    if sawDefiniteOutOfRange then
        return false
    end

    if CheckInteractDistance then
        return CheckInteractDistance("target", 3) == 1
    end

    return true
end

function Retribution:IsEntryInRange(readiness, entry, category, context)
    if category == "crusaderStrike" or category == "divineStorm" then
        return self:IsTargetInMelee(context)
    end

    if category == "consecration" or category == "holyWrath" then
        return true
    end

    return readiness:IsActionInRange(entry.action)
end

function Retribution:IsUndeadOrDemon()
    local creatureType = UnitCreatureType("target")
    if not creatureType then
        return false
    end

    local undead = CREATURE_TYPE_UNDEAD or addon.L.CREATURE_UNDEAD
    local demon = CREATURE_TYPE_DEMON or addon.L.CREATURE_DEMON

    return creatureType == undead
        or creatureType == demon
        or creatureType == "Undead"
        or creatureType == "Demon"
        or creatureType == "Нежить"
        or creatureType == "Демон"
end

function Retribution:IsTargetBelowExecuteRange()
    local maximum = UnitHealthMax("target")
    if not maximum or maximum <= 0 then
        return false
    end

    return UnitHealth("target") / maximum <= 0.20
end

function Retribution:IsLongLivedTarget(enemyCount)
    if enemyCount >= 2 then
        return true
    end

    if UnitLevel("target") == -1 then
        return true
    end

    local classification = UnitClassification("target")
    if classification == "elite"
        or classification == "rareelite"
        or classification == "worldboss" then
        return true
    end

    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "raid"
end

function Retribution:IsCategoryAllowed(category, context)
    if category == "hammerOfWrath" then
        return self:IsTargetBelowExecuteRange()
    end

    if category == "crusaderStrike" or category == "divineStorm" then
        return self:IsTargetInMelee(context)
    end

    if category == "exorcism" then
        return not self:IsTargetInMelee(context) or self:HasArtOfWarAura()
    end

    if category == "consecration" then
        if not UnitAffectingCombat("player") then
            return false
        end

        if not self:IsTargetInMelee(context) then
            return false
        end

        if context.enemyCount < 2 then
            local inInstance, instanceType = IsInInstance()
            local isPvEInstance = inInstance and (instanceType == "party" or instanceType == "raid")
            if not isPvEInstance or not self:IsLongLivedTarget(context.enemyCount) then
                return false
            end
        end

        return true
    end

    if category == "holyWrath" then
        return self:IsUndeadOrDemon()
    end

    return true
end

function Retribution:GetPriority(context)
    local level = context.playerLevel
    local enemyCount = context.enemyCount

    if level < 20 then
        return PRIORITY.level1To19
    end

    if level < 44 then
        return PRIORITY.level20To43
    end

    if level < 50 then
        return PRIORITY.level44To49
    end

    if level < 60 then
        if self:IsLongLivedTarget(enemyCount) then
            return PRIORITY.level50To59Long
        end

        return PRIORITY.level50To59Short
    end

    if level < 80 then
        if enemyCount >= 2 then
            return PRIORITY.levelingAoe
        end

        if self:IsLongLivedTarget(enemyCount) then
            return PRIORITY.level60To79Long
        end

        return PRIORITY.level60To79Short
    end

    if self.t10Count >= 4 then
        return PRIORITY.t10FourPiece
    end

    if self.t10Count >= 2 and self.t9Count >= 2 then
        return PRIORITY.t9T10Mixed
    end

    if self.t10Count >= 2 then
        return PRIORITY.t10TwoPiece
    end

    if enemyCount >= 2 then
        return PRIORITY.level80Aoe
    end

    if self.t9Count >= 2 then
        return PRIORITY.t9
    end

    return PRIORITY.preT9
end

addon.SpecRegistry:Register(Retribution)
