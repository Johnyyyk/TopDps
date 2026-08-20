local addon = TopDps
local Warlock = addon:CreateModule("Warlock")

Warlock.CLASS_TOKEN = "WARLOCK"
Warlock.TALENT_TABS = {
    AFFLICTION = 1,
    DEMONOLOGY = 2,
    DESTRUCTION = 3,
}

Warlock.CURSE_MODE_AUTO = "auto"
Warlock.CURSE_MODE_ELEMENTS = "elements"
Warlock.CURSE_MODE_DOOM = "doom"
Warlock.CURSE_MODE_AGONY = "agony"
Warlock.CURSE_MODE_NONE = "none"

Warlock.SPELL_IDS = {
    lifeTap = 1454,
    glyphLifeTap = 63320,
    glyphLifeTapBuff = 63321,

    curseElements = 47865,
    curseDoom = 603,
    curseAgony = 980,
    corruption = 172,
    immolate = 348,
    shadowBolt = 686,
    soulFire = 6353,
    incinerate = 29722,
    conflagrate = 17962,
    chaosBolt = 50796,

    felArmor = 28176,
    soulLink = 19028,
    soulLinkAura = 25228,
    metamorphosis = 47241,
    demonicEmpowerment = 47193,

    moltenCoreTalent = 47245,
    moltenCoreProc = 71165,
    decimationTalent = 63156,
    decimationProc = 63167,
    demonicPactTalent = 47236,
    demonicPactProc = 48090,

    backdraftTalent = 47258,
    backdraftProc = 54274,
    empoweredImpTalent = 47220,
    empoweredImpProc = 47283,
    pyroclasmTalent = 18096,
    pyroclasmProc = 18093,

    summonImp = 688,
    summonFelguard = 30146,
    impFirebolt = 3110,
    felguardCleave = 30213,

    grandSpellstone = 55194,
    grandFirestone = 55158,

    earthAndMoon = 60433,
    ebonPlague = 51735,
    shadowMastery = 17800,
    improvedScorch = 22959,
    wintersChill = 12579,
}

Warlock.WEAPON_ENCHANT_SPELL_IDS = {
    spellstone = {
        55171,
        55175,
        55178,
        55188,
        55190,
        55194,
    },
    firestone = {
        54721,
        55152,
        55153,
        55154,
        55155,
        55156,
        55158,
    },
}

local LIFE_TAP_REFRESH_SECONDS = 3
local MAIN_HAND_SLOT = 16
local PET_REQUIREMENT_GRACE_SECONDS = 0.5

Warlock.petRequirementContext = Warlock.petRequirementContext or {}

local function IsAuraFromPlayer(aura)
    if not aura or not aura.unitCaster then
        return false
    end

    if aura.unitCaster == "player" then
        return true
    end

    if UnitIsUnit then
        local ok, sameUnit = pcall(UnitIsUnit, aura.unitCaster, "player")
        return ok and sameUnit == true
    end

    return false
end

function Warlock:CreateCurseSetting()
    return {
        type = "dropdown",
        key = "curseMode",
        labelKey = "WARLOCK_CURSE_MODE",
        default = self.CURSE_MODE_AUTO,
        values = {
            self.CURSE_MODE_AUTO,
            self.CURSE_MODE_ELEMENTS,
            self.CURSE_MODE_DOOM,
            self.CURSE_MODE_AGONY,
            self.CURSE_MODE_NONE,
        },
        valueLabels = {
            [self.CURSE_MODE_AUTO] = "WARLOCK_CURSE_AUTO",
            [self.CURSE_MODE_ELEMENTS] = "WARLOCK_CURSE_ELEMENTS",
            [self.CURSE_MODE_DOOM] = "WARLOCK_CURSE_DOOM",
            [self.CURSE_MODE_AGONY] = "WARLOCK_CURSE_AGONY",
            [self.CURSE_MODE_NONE] = "WARLOCK_CURSE_NONE",
        },
    }
end

function Warlock:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Warlock:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function Warlock:HasPlayerAura(spellIds)
    local aura = self:FindPlayerAura(spellIds)
    return aura ~= nil
end

function Warlock:HasOwnTargetAura(spellIds)
    local aura = self:FindOwnTargetAura(spellIds)
    return aura ~= nil
end

function Warlock:HasExternalMagicVulnerability()
    local aura = addon.AuraService:FindAura(
        "target",
        {
            self.SPELL_IDS.earthAndMoon,
            self.SPELL_IDS.ebonPlague,
        },
        "HARMFUL",
        false
    )
    if aura then
        return true
    end

    local curseOfElements = addon.AuraService:FindAura(
        "target",
        { self.SPELL_IDS.curseElements },
        "HARMFUL",
        false
    )

    return curseOfElements ~= nil and not IsAuraFromPlayer(curseOfElements)
end

function Warlock:HasSpellCritDebuff()
    local aura = addon.AuraService:FindAura(
        "target",
        {
            self.SPELL_IDS.shadowMastery,
            self.SPELL_IDS.improvedScorch,
        },
        "HARMFUL",
        false
    )
    if aura then
        return true
    end

    local wintersChill = addon.AuraService:FindAura(
        "target",
        { self.SPELL_IDS.wintersChill },
        "HARMFUL",
        false
    )

    return wintersChill ~= nil and (tonumber(wintersChill.stacks) or 0) >= 5
end

function Warlock:GetDesiredCurseSpellId(provider)
    local mode = provider:GetSetting("curseMode")

    if mode == self.CURSE_MODE_NONE then
        return nil
    end

    if mode == self.CURSE_MODE_ELEMENTS then
        return self.SPELL_IDS.curseElements
    end

    if mode == self.CURSE_MODE_DOOM then
        return self.SPELL_IDS.curseDoom
    end

    if mode == self.CURSE_MODE_AGONY then
        return self.SPELL_IDS.curseAgony
    end

    if self:HasExternalMagicVulnerability() then
        return self.SPELL_IDS.curseDoom
    end

    return self.SPELL_IDS.curseElements
end

function Warlock:IsDesiredCurseMissing(provider)
    local spellId = self:GetDesiredCurseSpellId(provider)
    if not spellId then
        return false
    end

    return not self:HasOwnTargetAura({ spellId })
end

function Warlock:GetCurseReadyEntries(provider, readiness, entries, category, context)
    local spellId = self:GetDesiredCurseSpellId(provider)
    if not spellId then
        return {}
    end

    local spellName = GetSpellInfo(spellId)
    local filtered = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if entry.spellId == spellId or (spellName and entry.spellName == spellName) then
            filtered[#filtered + 1] = entry
        end
    end

    return readiness:GetDefaultReadyEntries(filtered, category, provider, context)
end

function Warlock:HasGlyphLifeTap()
    return addon.GameApi:HasGlyphSpell({ self.SPELL_IDS.glyphLifeTap })
end

function Warlock:ShouldRefreshGlyphLifeTap()
    if not self:HasGlyphLifeTap() then
        return false
    end

    local aura = self:FindPlayerAura({ self.SPELL_IDS.glyphLifeTapBuff })
    if not aura then
        return true
    end

    local expirationTime = tonumber(aura.expirationTime) or 0
    if expirationTime <= 0 then
        return false
    end

    return expirationTime - GetTime() <= LIFE_TAP_REFRESH_SECONDS
end

function Warlock:GetCommonCategoryAllowed(provider, category)
    if category == "lifeTap" then
        return self:ShouldRefreshGlyphLifeTap()
    end

    if category == "curse" then
        return self:IsDesiredCurseMissing(provider)
    end

    return nil
end

function Warlock:IsMounted()
    if not IsMounted then
        return false
    end

    local ok, mounted = pcall(IsMounted)
    return ok and (mounted == true or mounted == 1)
end

function Warlock:IsPetRequirementApplicable()
    local mounted = self:IsMounted()
    local petExists = UnitExists("pet") and not UnitIsDead("pet") or false
    local soulLinkActive = self:HasPlayerAura({ self.SPELL_IDS.soulLinkAura })
    local currentTime = GetTime()
    local state = self.petRequirementContext

    if state.mounted == nil then
        state.mounted = mounted
        state.petExists = petExists
        state.soulLinkActive = soulLinkActive
        state.graceUntil = 0
    else
        local dismounted = state.mounted and not mounted
        local petDisappeared = state.petExists and not petExists
        local soulLinkDisappeared = state.soulLinkActive and not soulLinkActive

        if dismounted or (not mounted and (petDisappeared or soulLinkDisappeared)) then
            state.graceUntil = currentTime + PET_REQUIREMENT_GRACE_SECONDS
        end

        state.mounted = mounted
        state.petExists = petExists
        state.soulLinkActive = soulLinkActive
    end

    if mounted then
        return false
    end

    return currentTime >= (state.graceUntil or 0)
end

function Warlock:HasPetSpell(spellId)
    if not UnitExists("pet") or UnitIsDead("pet") or not GetSpellName then
        return false
    end

    local expectedName = GetSpellInfo(spellId)
    if not expectedName then
        return false
    end

    local bookType = BOOKTYPE_PET or "pet"
    local spellCount = 20
    if HasPetSpells then
        local count = HasPetSpells()
        if type(count) == "number" and count > 0 then
            spellCount = count
        end
    end

    local index
    for index = 1, spellCount do
        local spellName = GetSpellName(index, bookType)
        if not spellName then
            break
        end

        if spellName == expectedName then
            return true
        end
    end

    return false
end

function Warlock:GetRequiredPetState(petType)
    local petSpellId
    local displaySpellId

    if petType == "felguard" then
        petSpellId = self.SPELL_IDS.felguardCleave
        displaySpellId = self.SPELL_IDS.summonFelguard
    else
        petSpellId = self.SPELL_IDS.impFirebolt
        displaySpellId = self.SPELL_IDS.summonImp
    end

    return {
        active = self:HasPetSpell(petSpellId),
        spellId = displaySpellId,
    }
end

function Warlock:GetWeaponStoneState(spellId, enchantSpellIds)
    if not addon.EquipmentService then
        return {
            active = false,
            spellId = spellId,
            statusText = "?",
        }
    end

    local active, enchant = addon.EquipmentService:MatchesTemporaryEnchantSpellIds(
        MAIN_HAND_SLOT,
        enchantSpellIds
    )

    return {
        active = active,
        spellId = spellId,
        statusText = enchant and enchant.active and not enchant.name and "?" or nil,
    }
end
