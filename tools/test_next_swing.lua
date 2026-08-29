local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function AssertTrue(value, message)
    if value ~= true then
        Fail((message or "expected true") .. ": actual=" .. tostring(value))
    end
end

local function AssertNear(actual, expected, epsilon, message)
    if math.abs(actual - expected) > epsilon then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = {
        Modules = {},
    }

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

local function TestSpecProviderContract()
    TopDps = NewAddon()
    TopDps.REFRESH_LEAD_CAST_TIME = "CAST_TIME"
    local settingValues = {
        showNextSwingCenter = true,
    }
    TopDps.Settings = {
        GetSpecSetting = function(_, _, key) return settingValues[key] end,
        SetSpecSetting = function(_, _, key, value) settingValues[key] = value end,
    }
    TopDps.L = {}

    dofile("Specs/SpecProvider.lua")

    local provider = TopDps.SpecProvider:Create({
        id = "TEST",
        categories = { "primary", "queued" },
        nextSwingCategories = { "queued" },
        abilities = {
            primary = { spellIds = { 1 } },
            queued = { spellIds = { 2 } },
        },
    })

    AssertEqual(#provider:GetNextSwingPriority({}), 0, "default next-swing priority is empty")
    AssertEqual(provider:GetNextSwingCategories()[1], "queued", "provider exposes stable next-swing categories")
    AssertEqual(provider:IsNextSwingCategoryAllowed("queued", {}), true, "next-swing allow falls back to normal allow")
    AssertEqual(
        provider:GetSettingDefinition("showNextSwingCenter").default,
        true,
        "next-swing provider exposes center display setting"
    )
    AssertEqual(provider:IsNextSwingCenterEnabled(), true, "next-swing center display defaults to enabled")

    provider:SetSetting("showNextSwingCenter", false)
    AssertEqual(provider:IsNextSwingCenterEnabled(), false, "next-swing center display can be disabled per spec")
end

local function TestHighlightChannels()
    TopDps = NewAddon()
    dofile("Core/Constants.lua")

    TopDps.db = {
        rotation = {
            highlightStyle = TopDps.HIGHLIGHT_BLIZZARD,
        },
    }
    TopDps.Settings = {
        IsRotationEnabled = function() return true end,
        IsModeActive = function() return true end,
    }

    local shows = {}
    local hides = {}
    local function NewRenderer(name)
        return {
            Show = function(_, button, appearance)
                table.insert(shows, {
                    renderer = name,
                    button = button,
                    appearance = appearance,
                })
            end,
            Hide = function(_, button)
                table.insert(hides, {
                    renderer = name,
                    button = button,
                })
            end,
        }
    end

    TopDps.BlizzardHighlight = NewRenderer("BLIZZARD")
    TopDps.CheeseHighlight = NewRenderer("CHEESE")

    dofile("Presentation/HighlightManager.lua")

    local primaryA = {}
    local primaryB = {}
    local nextSwing = {}

    TopDps.HighlightManager:SetEntries(TopDps.HIGHLIGHT_CHANNEL_PRIMARY, { { button = primaryA } })
    TopDps.HighlightManager:SetEntries(TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING, { { button = nextSwing } })

    AssertTrue(TopDps.HighlightManager.active[primaryA] ~= nil, "primary highlight stays active")
    AssertTrue(TopDps.HighlightManager.active[nextSwing] ~= nil, "next-swing highlight is active in parallel")
    AssertEqual(shows[#shows].appearance.key, TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING, "next-swing appearance is semantic")
    AssertNear(shows[#shows].appearance.color.b, 1.0, 0.0001, "next-swing appearance is blue")

    local hideCountBeforePrimaryChange = #hides
    TopDps.HighlightManager:SetEntries(TopDps.HIGHLIGHT_CHANNEL_PRIMARY, { { button = primaryB } })
    AssertTrue(TopDps.HighlightManager.active[primaryB] ~= nil, "new primary is active")
    AssertTrue(TopDps.HighlightManager.active[nextSwing] ~= nil, "primary change does not clear next-swing")
    AssertEqual(#hides, hideCountBeforePrimaryChange + 1, "only previous primary was stopped")
    AssertEqual(hides[#hides].button, primaryA, "old primary was stopped")

    TopDps.HighlightManager:SetEntries(TopDps.HIGHLIGHT_CHANNEL_PRIMARY, nil)
    AssertTrue(TopDps.HighlightManager.active[nextSwing] ~= nil, "clearing primary keeps next-swing")

    TopDps.HighlightManager:StopAll()
    TopDps.db.rotation.highlightStyle = TopDps.HIGHLIGHT_CHEESE
    TopDps.HighlightManager:Refresh()
    AssertEqual(shows[#shows].renderer, "CHEESE", "next-swing uses selected Cheese renderer")
    AssertEqual(shows[#shows].appearance.key, TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING, "Cheese receives next-swing appearance")

    TopDps.HighlightManager:SetEntries(TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING, nil)
    AssertEqual(TopDps.HighlightManager.active[nextSwing], nil, "clearing next-swing removes only its highlight")
end

local function TestBlizzardChannelColor()
    TopDps = NewAddon()

    local startCalls = {}
    local shine = {
        SetPoint = function() end,
        SetWidth = function() end,
        SetHeight = function() end,
        SetFrameLevel = function() end,
        EnableMouse = function() end,
        Hide = function() end,
        Show = function() end,
    }
    local button = {
        GetName = function() return "TestButton" end,
        GetFrameLevel = function() return 1 end,
    }

    CreateFrame = function()
        return shine
    end
    AutoCastShine_AutoCastStart = function(_, red, green, blue)
        table.insert(startCalls, { red, green, blue })
    end
    AutoCastShine_AutoCastStop = function() end

    dofile("Presentation/BlizzardHighlight.lua")

    TopDps.BlizzardHighlight:Show(button, { key = "PRIMARY" })
    AssertEqual(startCalls[1][1], nil, "primary Blizzard highlight keeps client default color")

    TopDps.BlizzardHighlight:Hide(button)
    TopDps.BlizzardHighlight:Show(button, {
        key = "NEXT_SWING",
        color = { r = 0.35, g = 0.80, b = 1.00 },
    })
    AssertNear(startCalls[2][1], 0.35, 0.0001, "Blizzard next-swing red channel")
    AssertNear(startCalls[2][2], 0.80, 0.0001, "Blizzard next-swing green channel")
    AssertNear(startCalls[2][3], 1.00, 0.0001, "Blizzard next-swing blue channel")
end

local function TestCheeseChannelTextures()
    TopDps = NewAddon()
    TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING = "NEXT_SWING"
    UIParent = {}

    local function NewTexture()
        return {
            SetAlpha = function() end,
            SetSize = function() end,
            SetTexture = function(self, texture)
                self.texture = texture
            end,
        }
    end

    local overlay
    CreateFrame = function()
        overlay = {
            spark = NewTexture(),
            innerGlow = NewTexture(),
            innerGlowOver = NewTexture(),
            outerGlow = NewTexture(),
            outerGlowOver = NewTexture(),
            ants = NewTexture(),
            animIn = {
                IsPlaying = function() return false end,
                Stop = function() end,
            },
            animOut = {
                isPlaying = false,
                IsPlaying = function() return false end,
                Stop = function() end,
                Play = function() end,
            },
            GetSize = function() return 48, 48 end,
            SetParent = function() end,
            SetFrameLevel = function() end,
            ClearAllPoints = function() end,
            SetSize = function() end,
            SetPoint = function() end,
            Show = function() end,
            Hide = function() end,
        }
        return overlay
    end

    local button = {
        GetSize = function() return 36, 36 end,
        GetFrameLevel = function() return 1 end,
        IsVisible = function() return true end,
    }

    local baseTexture = "Interface\\AddOns\\TopDps\\Textures\\Cheese\\IconAlert"
    local baseAntsTexture = "Interface\\AddOns\\TopDps\\Textures\\Cheese\\IconAlertAnts"
    local nextSwingTexture = "Interface\\AddOns\\TopDps\\Textures\\Cheese\\IconAlertNextSwing"
    local nextSwingAntsTexture = "Interface\\AddOns\\TopDps\\Textures\\Cheese\\IconAlertAntsNextSwing"

    dofile("Vendor/Cheese/CheeseGlow.lua")

    TopDps.CheeseHighlight:Show(button, { key = "NEXT_SWING" })
    AssertEqual(overlay.spark.texture, nextSwingTexture, "Cheese next-swing uses dedicated spark texture")
    AssertEqual(overlay.innerGlow.texture, nextSwingTexture, "Cheese next-swing uses dedicated inner glow texture")
    AssertEqual(overlay.innerGlowOver.texture, nextSwingTexture, "Cheese next-swing uses dedicated inner glow over texture")
    AssertEqual(overlay.outerGlow.texture, nextSwingTexture, "Cheese next-swing uses dedicated outer glow texture")
    AssertEqual(overlay.outerGlowOver.texture, nextSwingTexture, "Cheese next-swing uses dedicated outer glow over texture")
    AssertEqual(overlay.ants.texture, nextSwingAntsTexture, "Cheese next-swing uses dedicated ants texture")

    TopDps.CheeseHighlight:Show(button, { key = "PRIMARY" })
    AssertEqual(overlay.outerGlow.texture, baseTexture, "Cheese primary restores original glow texture")
    AssertEqual(overlay.ants.texture, baseAntsTexture, "Cheese primary restores original ants texture")
end

local function TestRecommendationPresenterSeparatesCenterChannels()
    TopDps = NewAddon()
    dofile("Core/Constants.lua")

    local highlightCalls = {}
    TopDps.HighlightManager = {
        SetEntries = function(_, channel, entries)
            table.insert(highlightCalls, { channel = channel, entries = entries })
        end,
        Refresh = function() end,
    }
    TopDps.ActionBarService = {
        FindVisibleActions = function(_, _, _, entries)
            return entries
        end,
    }

    local centerStates = {}
    local centerHides = 0
    TopDps.CenterIcons = {
        Show = function(_, primaryEntries, nextSwingEntries)
            table.insert(centerStates, {
                primaryEntries = primaryEntries,
                nextSwingEntries = nextSwingEntries,
            })
        end,
        Hide = function() centerHides = centerHides + 1 end,
    }
    TopDps.Logger = { Info = function() end }
    TopDps.db = { debug = { chatRecommendations = false } }
    TopDps.L = { NEXT_CAST = "%s" }
    TopDps.NAME = "TopDps"
    DEFAULT_CHAT_FRAME = nil

    dofile("Presentation/RecommendationPresenter.lua")

    local showNextSwingCenter = true
    local provider = {
        GetRecommendationName = function(_, category) return category end,
        IsNextSwingCenterEnabled = function() return showNextSwingCenter end,
    }
    local primaryEntries = { { button = {} } }
    local nextSwingEntries = { { button = {} } }

    TopDps.RecommendationPresenter:SetNextSwing(provider, "heroicStrike", nextSwingEntries)
    AssertEqual(centerStates[#centerStates].primaryEntries, nil, "next-swing can be shown without primary")
    AssertEqual(
        centerStates[#centerStates].nextSwingEntries,
        nextSwingEntries,
        "next-swing owns the left center channel"
    )
    AssertEqual(centerHides, 0, "next-swing does not hide center icons")

    TopDps.RecommendationPresenter:Set(provider, "bloodthirst", primaryEntries)
    AssertEqual(centerStates[#centerStates].primaryEntries, primaryEntries, "primary owns the right center channel")
    AssertEqual(
        centerStates[#centerStates].nextSwingEntries,
        nextSwingEntries,
        "primary change keeps the left next-swing channel"
    )

    TopDps.RecommendationPresenter:ClearNextSwing()
    AssertEqual(centerStates[#centerStates].primaryEntries, primaryEntries, "clearing next-swing keeps primary")
    AssertEqual(centerStates[#centerStates].nextSwingEntries, nil, "clearing next-swing restores primary-only layout")
    AssertEqual(centerHides, 0, "clearing next-swing keeps center icons")

    showNextSwingCenter = false
    TopDps.RecommendationPresenter:SetNextSwing(provider, "heroicStrike", nextSwingEntries)
    AssertEqual(
        centerStates[#centerStates].nextSwingEntries,
        nil,
        "per-spec setting hides next-swing only from center icons"
    )
    AssertEqual(
        highlightCalls[#highlightCalls].channel,
        TopDps.HIGHLIGHT_CHANNEL_NEXT_SWING,
        "hidden center next-swing keeps its action-bar channel"
    )

    TopDps.RecommendationPresenter:ClearPrimary()
    AssertEqual(centerHides, 1, "clearing primary hides center icons")
    AssertEqual(highlightCalls[#highlightCalls].channel, TopDps.HIGHLIGHT_CHANNEL_PRIMARY, "primary clear targets primary channel")
end

local function TestCenterIconsUseSeparateFrames()
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
        if spell == "Bloodthirst" then
            return "Bloodthirst", nil, "bloodthirst-texture"
        end

        if spell == "Heroic Strike" then
            return "Heroic Strike", nil, "heroic-strike-texture"
        end

        return nil
    end

    dofile("Presentation/CenterIcons.lua")

    local function NewFrame()
        return {
            icon = {
                SetTexture = function(self, texture) self.texture = texture end,
            },
            overlay = {
                SetTexture = function(self, texture) self.texture = texture end,
            },
            SetAlpha = function() end,
            Show = function(self) self.visible = true end,
            Hide = function(self) self.visible = false end,
        }
    end

    local left = NewFrame()
    local right = NewFrame()
    TopDps.CenterIcons.frames = { left, right }

    local primaryEntries = { { spellName = "Bloodthirst" } }
    local nextSwingEntries = { { spellName = "Heroic Strike" } }
    local primaryFrame = "Interface\\AddOns\\TopDps\\Textures\\CenterFrame"
    local nextSwingFrame = "Interface\\AddOns\\TopDps\\Textures\\CenterFrameNextSwing"

    TopDps.CenterIcons:Show(primaryEntries, nextSwingEntries)
    AssertEqual(left.icon.texture, "heroic-strike-texture", "next-swing is shown on the left")
    AssertEqual(left.overlay.texture, nextSwingFrame, "next-swing uses the blue center frame")
    AssertEqual(right.icon.texture, "bloodthirst-texture", "primary is shown on the right")
    AssertEqual(right.overlay.texture, primaryFrame, "primary keeps the gold center frame")

    TopDps.CenterIcons:Show(primaryEntries, nil)
    AssertEqual(left.icon.texture, "bloodthirst-texture", "primary returns to the left without next-swing")
    AssertEqual(left.overlay.texture, primaryFrame, "left primary restores the gold center frame")
    AssertEqual(right.icon.texture, "bloodthirst-texture", "primary stays duplicated on the right")
    AssertEqual(right.visible, true, "both primary icons stay visible")

    TopDps.CenterIcons:Show(nil, nextSwingEntries)
    AssertEqual(left.icon.texture, "heroic-strike-texture", "standalone next-swing remains on the left")
    AssertEqual(right.visible, false, "right slot is hidden without primary")

    TopDps.CenterIcons:Hide()
    TopDps.CenterIcons:Refresh()
    AssertEqual(left.visible, false, "cleared left slot is not restored by refresh")
    AssertEqual(right.visible, false, "cleared right slot is not restored by refresh")
end

local function TestQueuedNextSwingDetection()
    TopDps = NewAddon()

    UnitAttackSpeed = function() return 3, 0 end
    IsCurrentAction = function(action)
        return action == 11 and 1 or nil
    end

    dofile("Engine/SwingService.lua")

    local enemyCount = 1
    local provider = {
        GetNextSwingCategories = function()
            return { "heroicStrike", "cleave" }
        end,
        GetNextSwingPriority = function()
            if enemyCount >= 2 then
                return { "cleave" }
            end

            return { "heroicStrike" }
        end,
    }
    local actionsByCategory = {
        heroicStrike = { { action = 11 } },
        cleave = { { action = 12 } },
    }

    AssertEqual(
        TopDps.SwingService:GetQueuedNextSwingCategory(provider, actionsByCategory),
        "heroicStrike",
        "queued Heroic Strike is detected across the whole next-swing channel"
    )
    AssertEqual(
        TopDps.SwingService:IsNextSwingQueued(provider, actionsByCategory),
        true,
        "generic queued next-swing state"
    )

    enemyCount = 2
    AssertEqual(provider:GetNextSwingPriority()[1], "cleave", "current next-swing priority follows target count")
    AssertEqual(
        TopDps.SwingService:GetQueuedNextSwingCategory(provider, actionsByCategory),
        "heroicStrike",
        "queued Heroic Strike still owns the channel after a second target appears"
    )

    IsCurrentAction = function(action)
        return action == 12 and 1 or nil
    end
    AssertEqual(
        TopDps.SwingService:GetQueuedNextSwingCategory(provider, actionsByCategory),
        "cleave",
        "queued Cleave is detected"
    )
end

local function TestRotationEngineChannels()
    TopDps = NewAddon()

    local rotationEnabled = true
    TopDps.Settings = {
        IsRotationEnabled = function() return rotationEnabled end,
        IsModeActive = function() return true end,
    }

    UnitIsDeadOrGhost = function() return false end
    UnitHasVehicleUI = function() return false end
    UnitExists = function() return true end
    UnitIsDead = function() return false end
    UnitCanAttack = function() return true end

    local primaryAllowed = true
    local nextSwingAllowed = true
    local primaryPriorityCategory = "primary"
    local disabledCategories = {}
    local provider = {
        GetAvailability = function() return true end,
        GetPriority = function() return { primaryPriorityCategory } end,
        GetNextSwingPriority = function() return { "nextA", "nextB" } end,
        IsCategoryEnabled = function(_, category) return disabledCategories[category] ~= true end,
        IsCategoryAllowed = function() return primaryAllowed end,
        IsNextSwingCategoryAllowed = function() return nextSwingAllowed end,
    }
    TopDps.SpecManager = { GetActive = function() return provider end }

    local primaryEntry = { spellId = 1, spellName = "Primary" }
    local primaryEntry2 = { spellId = 4, spellName = "Primary 2" }
    local nextEntryA = { spellId = 2, spellName = "Next A" }
    local nextEntryB = { spellId = 3, spellName = "Next B" }
    local abilities = {
        primary = { primaryEntry },
        primary2 = { primaryEntry2 },
        nextA = { nextEntryA },
        nextB = { nextEntryB },
    }

    TopDps.AbilityService = {
        GetAbilities = function() return abilities end,
        BuildAbilitySummary = function() return "abilities" end,
    }
    TopDps.ContextBuilder = {
        Build = function()
            return { enemyCount = 1 }
        end,
    }
    TopDps.RefreshService = {
        IsCategoryRefreshDue = function() return true end,
    }
    TopDps.ReadinessService = {
        GetReadyEntries = function(_, entries) return entries end,
    }

    local queuedCategory = nil
    TopDps.SwingService = {
        GetQueuedNextSwingCategory = function() return queuedCategory end,
    }

    local calls = {}
    TopDps.RecommendationPresenter = {
        Set = function(_, _, category)
            calls.primary = "set:" .. category
        end,
        ClearPrimary = function()
            calls.primary = "clear"
        end,
        SetNextSwing = function(_, _, category)
            calls.nextSwing = "set:" .. category
        end,
        ClearNextSwing = function()
            calls.nextSwing = "clear"
        end,
        Clear = function()
            calls.globalClear = true
        end,
    }
    local lastRotationState
    TopDps.Logger = {
        SetRotationState = function(_, state) lastRotationState = state end,
    }

    dofile("Engine/RotationEngine.lua")

    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.primary, "set:primary", "primary recommendation is produced")
    AssertEqual(calls.nextSwing, "set:nextA", "next-swing recommendation is produced in parallel")
    AssertTrue(string.find(lastRotationState, "primary=recommend:primary", 1, true) ~= nil, "debug state includes primary channel")
    AssertTrue(string.find(lastRotationState, "next_swing=recommend:nextA", 1, true) ~= nil, "debug state includes next-swing channel")

    primaryPriorityCategory = "primary2"
    calls.primary = nil
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.primary, "set:primary2", "primary recommendation can change while next-swing stays active")
    AssertEqual(calls.nextSwing, "set:nextA", "primary change does not clear next-swing")
    primaryPriorityCategory = "primary"

    primaryAllowed = false
    calls.primary = nil
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.primary, "clear", "empty primary channel clears only primary")
    AssertEqual(calls.nextSwing, "set:nextA", "empty primary channel keeps next-swing recommendation")

    primaryAllowed = true
    nextSwingAllowed = false
    calls.primary = nil
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.primary, "set:primary", "primary stays active when next-swing is empty")
    AssertEqual(calls.nextSwing, "clear", "empty next-swing channel clears only next-swing")

    nextSwingAllowed = true
    queuedCategory = "nextA"
    calls.primary = nil
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.primary, "set:primary", "queued next-swing does not touch primary")
    AssertEqual(calls.nextSwing, "clear", "queued next-swing hides next-swing recommendation")
    AssertTrue(string.find(lastRotationState, "next_swing=queued:nextA", 1, true) ~= nil, "debug state includes queued next-swing")

    queuedCategory = nil
    disabledCategories.nextA = true
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.nextSwing, "set:nextB", "disabled next-swing category falls through to the next candidate")

    abilities.nextA = nil
    abilities.nextB = nil
    disabledCategories.nextA = nil
    calls.nextSwing = nil
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.nextSwing, "clear", "next-swing requires a learned ability")

    rotationEnabled = false
    calls.globalClear = false
    TopDps.RotationEngine:UpdateRecommendation()
    AssertEqual(calls.globalClear, true, "global block clears both channels")
end

TestSpecProviderContract()
TestHighlightChannels()
TestBlizzardChannelColor()
TestCheeseChannelTextures()
TestRecommendationPresenterSeparatesCenterChannels()
TestCenterIconsUseSeparateFrames()
TestQueuedNextSwingDetection()
TestRotationEngineChannels()

print("next-swing channel smoke tests passed")
