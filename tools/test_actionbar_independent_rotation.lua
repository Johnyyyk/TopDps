local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        error(
            (message or "values differ")
                .. ": expected=" .. tostring(expected)
                .. ", actual=" .. tostring(actual),
            2
        )
    end
end

local function NewAddon()
    local addon = { Modules = {} }

    function addon:CreateModule(name)
        local module = self.Modules[name]
        if module then
            return module
        end

        module = {}
        self.Modules[name] = module
        self[name] = module
        return module
    end

    return addon
end

local function TestSpellCatalogUsesWotlkApiAndLearnedRank()
    TopDps = NewAddon()

    GetSpellInfo = function(spell)
        if spell == 7386 or spell == 47467 or spell == "Sunder Armor" then return "Sunder Armor" end
        if spell == 23881 or spell == 30335 or spell == "Bloodthirst" then return "Bloodthirst" end
        return nil
    end
    GetSpellLink = function(spell)
        if spell == "Sunder Armor" then
            return "|cff71d5ff|Hspell:47467:0|h[Sunder Armor]|h|r"
        end
        if spell == "Bloodthirst" then
            return "|cff71d5ff|Hspell:30335:0|h[Bloodthirst]|h|r"
        end
        return nil
    end
    IsSpellKnown = function() return false end
    GetSpellBookItemInfo = nil

    dofile("Engine/AbilityService.lua")

    local provider = {
        categories = { "sunderArmor", "bloodthirst" },
        abilities = {
            sunderArmor = { spellIds = { 7386 } },
            bloodthirst = { spellIds = { 23881 } },
        },
    }

    local abilities = TopDps.AbilityService:GetAbilities(provider)
    AssertEqual(#abilities.sunderArmor, 1, "Sunder is discovered without Cataclysm spellbook API")
    AssertEqual(abilities.sunderArmor[1].spellId, 47467, "learned Sunder rank is resolved from spell link")
    AssertEqual(abilities.bloodthirst[1].spellId, 30335, "learned Bloodthirst rank is resolved from spell link")
end

local function TestSpellReadinessDoesNotNeedActionSlot()
    TopDps = NewAddon()
    TopDps.DEFAULTS = { cooldownLookahead = 0.15 }
    TopDps.db = { rotation = { cooldownLookahead = 0.15 } }

    GetTime = function() return 100 end
    IsUsableSpell = function(spell) return spell == "Sunder Armor", false end
    IsSpellInRange = function(spell, unit)
        if spell == "Sunder Armor" and unit == "target" then return 1 end
        return nil
    end
    GetSpellCooldown = function() return 0, 0, 1 end

    dofile("Engine/ReadinessService.lua")

    AssertEqual(TopDps.ReadinessService.IsActionReady, nil, "readiness has no action compatibility proxy")
    AssertEqual(TopDps.ReadinessService.IsActionInRange, nil, "readiness has no action range fallback")
    AssertEqual(TopDps.ReadinessService.IsActionCooldownReady, nil, "readiness has no action cooldown fallback")

    local provider = {}
    function provider:CanTreatUnusableAsUsable() return false end
    function provider:IsEntryInRange(readiness, entry)
        return readiness:IsSpellInRange(entry)
    end

    local entry = { spellId = 47467, spellName = "Sunder Armor" }
    local ready = TopDps.ReadinessService:GetDefaultReadyEntries(
        { entry },
        "sunderArmor",
        provider,
        {}
    )
    AssertEqual(#ready, 1, "spell is ready without action field")

    IsUsableSpell = function() return false, false end
    ready = TopDps.ReadinessService:GetDefaultReadyEntries(
        { entry },
        "sunderArmor",
        provider,
        {}
    )
    AssertEqual(#ready, 0, "stance-unusable spell stays unavailable")
end

local function TestPrioritySelectionIgnoresVisibleButtons()
    TopDps = NewAddon()
    TopDps.RefreshService = { IsCategoryRefreshDue = function() return true end }
    TopDps.ReadinessService = { GetReadyEntries = function(_, entries) return entries end }

    dofile("Engine/RotationEngine.lua")

    local provider = { IsCategoryEnabled = function() return true end }
    local abilities = {
        sunderArmor = { { spellId = 47467, spellName = "Sunder Armor" } },
        bloodthirst = { { spellId = 30335, spellName = "Bloodthirst" } },
    }

    local category = TopDps.RotationEngine:GetReadyRecommendation(
        provider,
        { "sunderArmor", "bloodthirst" },
        abilities,
        {},
        function() return true end
    )
    AssertEqual(category, "sunderArmor", "missing button cannot lower priority")
end

local function TestPresentationSeparatesRecommendationFromHighlight()
    TopDps = NewAddon()
    TopDps.HIGHLIGHT_CHANNEL_PRIMARY = "PRIMARY"
    TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING = "NEXT_SWING"
    TopDps.db = { debug = { chatRecommendations = false } }
    TopDps.NAME = "TopDps"
    TopDps.L = { NEXT_CAST = "%s" }
    DEFAULT_CHAT_FRAME = nil

    local highlighted
    local centered
    TopDps.HighlightManager = {
        SetEntries = function(_, _, entries) highlighted = entries end,
    }
    TopDps.CenterIcons = {
        Show = function(_, entries) centered = entries end,
        Hide = function() end,
    }
    TopDps.Logger = { Info = function() end }
    TopDps.ActionBarService = { FindVisibleActions = function() return {} end }

    dofile("Presentation/RecommendationPresenter.lua")

    local provider = {
        GetRecommendationName = function(_, _, entries) return entries[1].spellName end,
    }
    local recommendation = { { spellId = 47467, spellName = "Sunder Armor" } }

    TopDps.RecommendationPresenter:Set(provider, "sunderArmor", recommendation)
    AssertEqual(#highlighted, 0, "no button means no highlight only")
    AssertEqual(centered, recommendation, "center recommendation survives without button")

    local button = {}
    TopDps.ActionBarService.FindVisibleActions = function()
        return { { button = button, action = 5, spellId = 47467, spellName = "Sunder Armor" } }
    end

    TopDps.RecommendationPresenter:Set(provider, "sunderArmor", recommendation)
    AssertEqual(highlighted[1].button, button, "matching visible button is highlighted")
end

local function TestCenterIconUsesSpellTexture()
    TopDps = NewAddon()
    TopDps.db = {
        rotation = {
            centerIcons = { enabled = true, opacity = 0.8 },
        },
    }
    TopDps.Settings = {
        IsRotationEnabled = function() return true end,
        IsModeActive = function() return true end,
    }
    GetSpellInfo = function(spell)
        if spell == 47467 or spell == "Sunder Armor" then
            return "Sunder Armor", nil, "sunder-texture"
        end
        return nil
    end

    dofile("Presentation/CenterIcons.lua")

    local textures = {}
    local function NewFrame(index)
        return {
            icon = { SetTexture = function(_, texture) textures[index] = texture end },
            SetAlpha = function() end,
            Show = function() end,
            Hide = function() end,
        }
    end

    TopDps.CenterIcons.frames = { NewFrame(1), NewFrame(2) }
    TopDps.CenterIcons:Show({ { spellId = 47467, spellName = "Sunder Armor" } })
    AssertEqual(textures[1], "sunder-texture", "center icon does not require action texture")
    AssertEqual(textures[2], "sunder-texture", "both center icons use spell texture")
end

local function TestHiddenNextSwingSlotStillTracksQueue()
    TopDps = NewAddon()
    TopDps.ACTION_BUTTON_PREFIXES = {}
    TopDps.GameApi = {
        GetActionSpellData = function(_, action)
            if action == 97 then return 47450, "Heroic Strike" end
            return nil, nil
        end,
    }

    local provider = {}
    function provider:GetSpellCategory(spellId, spellName)
        if spellId == 47450 or spellName == "Heroic Strike" then return "heroicStrike" end
        return nil
    end
    function provider:GetNextSwingCategories() return { "heroicStrike" } end

    TopDps.SpecManager = { GetActive = function() return provider end }
    HasAction = function(action) return action == 97 end
    IsCurrentAction = function(action) return action == 97 and 1 or 0 end

    dofile("Engine/ActionBarService.lua")
    dofile("Engine/SwingService.lua")

    TopDps.ActionBarService:CollectActionSlots(provider)
    AssertEqual(
        TopDps.SwingService:GetQueuedNextSwingCategory(provider),
        "heroicStrike",
        "queued next-swing is found outside visible buttons"
    )
end

TestSpellCatalogUsesWotlkApiAndLearnedRank()
TestSpellReadinessDoesNotNeedActionSlot()
TestPrioritySelectionIgnoresVisibleButtons()
TestPresentationSeparatesRecommendationFromHighlight()
TestCenterIconUsesSpellTexture()
TestHiddenNextSwingSlotStillTracksQueue()

print("actionbar-independent rotation regression tests passed")
