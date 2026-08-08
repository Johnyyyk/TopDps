local addon = RpalTopDps

local Retribution = {
    id = "PALADIN_RETRIBUTION",
    classToken = "PALADIN",
    talentTabIndex = 3,
}

Retribution.categories = {
    "judgement",
    "hammerOfWrath",
    "crusaderStrike",
    "divineStorm",
    "consecration",
    "exorcism",
    "holyWrath",
}
Retribution.debugCategories = Retribution.categories

local SPELL_IDS = {
    artOfWarAura = 59578,
}

local SPELL_RANK_IDS = {
    judgement = {
        20271, -- Judgement of Light
        53408, -- Judgement of Wisdom
        53407, -- Judgement of Justice
    },
    hammerOfWrath = {
        24275, 24274, 24239, 27180, 48805, 48806,
    },
    crusaderStrike = {
        35395,
    },
    divineStorm = {
        53385,
    },
    consecration = {
        26573, 20116, 20922, 20923, 20924, 27173, 48818, 48819,
    },
    exorcism = {
        879, 5614, 5615, 10312, 10313, 10314, 27138, 48800, 48801,
    },
    holyWrath = {
        2812, 10318, 27139, 48816, 48817,
    },
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
    1,  -- Head
    3,  -- Shoulder
    5,  -- Chest
    7,  -- Legs
    10, -- Hands
}

local LEVEL_1_19_PRIORITY = {
    "judgement",
}

local LEVEL_20_43_PRIORITY = {
    "judgement",
    "consecration",
    "exorcism",
}

local LEVEL_44_49_PRIORITY = {
    "hammerOfWrath",
    "judgement",
    "exorcism",
    "consecration",
}

local LEVEL_50_59_SHORT_PRIORITY = {
    "hammerOfWrath",
    "judgement",
    "crusaderStrike",
    "exorcism",
    "consecration",
}

local LEVEL_50_59_LONG_PRIORITY = {
    "crusaderStrike",
    "hammerOfWrath",
    "judgement",
    "exorcism",
    "consecration",
}

local LEVEL_60_79_SHORT_PRIORITY = {
    "hammerOfWrath",
    "divineStorm",
    "judgement",
    "crusaderStrike",
    "exorcism",
    "consecration",
    "holyWrath",
}

local LEVEL_60_79_LONG_PRIORITY = {
    "crusaderStrike",
    "hammerOfWrath",
    "judgement",
    "divineStorm",
    "exorcism",
    "consecration",
    "holyWrath",
}

local LEVELING_AOE_PRIORITY = {
    "hammerOfWrath",
    "divineStorm",
    "judgement",
    "crusaderStrike",
    "consecration",
    "exorcism",
    "holyWrath",
}

local PRE_T9_PRIORITY = {
    "crusaderStrike",
    "hammerOfWrath",
    "judgement",
    "divineStorm",
    "consecration",
    "exorcism",
    "holyWrath",
}

local T9_PRIORITY = {
    "judgement",
    "hammerOfWrath",
    "crusaderStrike",
    "divineStorm",
    "consecration",
    "exorcism",
    "holyWrath",
}

local LEVEL_80_AOE_PRIORITY = {
    "judgement",
    "hammerOfWrath",
    "divineStorm",
    "crusaderStrike",
    "consecration",
    "exorcism",
    "holyWrath",
}

local T10_2_PRIORITY = {
    "divineStorm",
    "judgement",
    "crusaderStrike",
    "hammerOfWrath",
    "consecration",
    "exorcism",
    "holyWrath",
}

local T9_T10_MIXED_PRIORITY = {
    "judgement",
    "divineStorm",
    "hammerOfWrath",
    "crusaderStrike",
    "consecration",
    "exorcism",
    "holyWrath",
}

local T10_4_PRIORITY = {
    "judgement",
    "divineStorm",
    "crusaderStrike",
    "hammerOfWrath",
    "consecration",
    "exorcism",
    "holyWrath",
}

local function AddSpellCategory(provider, spellId, category)
    provider.spellCategoryById[spellId] = category

    local name = GetSpellInfo(spellId)
    if name then
        provider.spellCategoryByName[name] = category
        provider.spellNameByCategory[category] = provider.spellNameByCategory[category] or name
    end
end

function Retribution:Initialize()
    self:BuildSpellCatalog()
    self:RefreshEquipment()
end

function Retribution:BuildSpellCatalog()
    self.spellCategoryById = {}
    self.spellCategoryByName = {}
    self.spellNameByCategory = {}

    local category
    local spellIds
    local index

    for category, spellIds in pairs(SPELL_RANK_IDS) do
        for index = 1, #spellIds do
            AddSpellCategory(self, spellIds[index], category)
        end
    end

    self.artOfWarAuraName = GetSpellInfo(SPELL_IDS.artOfWarAura)
end

function Retribution:GetSpellCategory(spellId, spellName)
    local category

    if spellId then
        category = self.spellCategoryById[spellId]
    end

    if not category and spellName then
        category = self.spellCategoryByName[spellName]
    end

    return category
end

function Retribution:GetRecommendationName(category, entries)
    if entries and entries[1] and entries[1].spellName then
        return entries[1].spellName
    end

    return self.spellNameByCategory[category] or category
end

function Retribution:RefreshEquipment()
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

function Retribution:IsActive()
    local _, class = UnitClass("player")
    if class ~= self.classToken then
        return false
    end

    if UnitLevel("player") < 10 then
        return true
    end

    local talentGroup = addon.GameApi:GetActiveTalentGroup()
    local holyPoints = addon.GameApi:GetTalentPoints(1, talentGroup)
    local protectionPoints = addon.GameApi:GetTalentPoints(2, talentGroup)
    local retributionPoints = addon.GameApi:GetTalentPoints(3, talentGroup)

    if holyPoints == nil or protectionPoints == nil or retributionPoints == nil then
        return true
    end

    return retributionPoints >= holyPoints and retributionPoints >= protectionPoints
end

function Retribution:CanTreatUnusableAsUsable(category, entry, context)
    -- Some 3.3.5 clients report false from IsUsableAction for conditional
    -- abilities even when their actual condition is already satisfied. Mana is
    -- still checked by ActionBarService before this fallback is called.
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

function Retribution:GetReadyEntries(actionBar, entries, category, context)
    if category ~= "judgement" then
        return actionBar:GetDefaultReadyEntries(entries, category, self, context)
    end

    local readyEntries = {}
    local anyReady = false
    local index

    for index = 1, #entries do
        if actionBar:IsActionReady(entries[index], category, self, context) then
            anyReady = true
            break
        end
    end

    if not anyReady then
        return readyEntries
    end

    -- Judgements share a cooldown. Highlight every visible choice so the
    -- player may choose Light or Wisdom instead of the addon selecting one.
    for index = 1, #entries do
        local entry = entries[index]
        if actionBar:IsEntryInRange(entry, category, self, context)
            and actionBar:IsActionCooldownReady(entry.action) then
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

    -- If this client cannot report range, do not hide melee abilities forever.
    return true
end

function Retribution:IsEntryInRange(actionBar, entry, category, context)
    if category == "crusaderStrike" or category == "divineStorm" then
        return self:IsTargetInMelee(context)
    end

    -- Consecration and Holy Wrath are player-centred effects. Their target
    -- action range is undefined on 3.3.5 and must not be used as a filter.
    if category == "consecration" or category == "holyWrath" then
        return true
    end

    return actionBar:IsActionInRange(entry.action)
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
        -- Outside melee it may be used as a normal ranged cast. In melee it is
        -- recommended only while the actual Art of War proc aura is present.
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
        return LEVEL_1_19_PRIORITY
    end

    if level < 44 then
        return LEVEL_20_43_PRIORITY
    end

    if level < 50 then
        return LEVEL_44_49_PRIORITY
    end

    if level < 60 then
        if self:IsLongLivedTarget(enemyCount) then
            return LEVEL_50_59_LONG_PRIORITY
        end

        return LEVEL_50_59_SHORT_PRIORITY
    end

    if level < 80 then
        if enemyCount >= 2 then
            return LEVELING_AOE_PRIORITY
        end

        if self:IsLongLivedTarget(enemyCount) then
            return LEVEL_60_79_LONG_PRIORITY
        end

        return LEVEL_60_79_SHORT_PRIORITY
    end

    if self.t10Count >= 4 then
        return T10_4_PRIORITY
    end

    if self.t10Count >= 2 and self.t9Count >= 2 then
        return T9_T10_MIXED_PRIORITY
    end

    if self.t10Count >= 2 then
        return T10_2_PRIORITY
    end

    if enemyCount >= 2 then
        return LEVEL_80_AOE_PRIORITY
    end

    if self.t9Count >= 2 then
        return T9_PRIORITY
    end

    return PRE_T9_PRIORITY
end

addon.SpecRegistry:Register(Retribution)
