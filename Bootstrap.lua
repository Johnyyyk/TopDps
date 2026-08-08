local addon = TopDps

local Bootstrap = addon:CreateModule("Bootstrap")
local eventFrame = CreateFrame("Frame")
Bootstrap.eventFrame = eventFrame
Bootstrap.initialized = false
Bootstrap.updateElapsed = 0

function Bootstrap:RegisterSlashCommands()
    SLASH_TOPDPS1 = "/topdps"
    SLASH_TOPDPS2 = "/td"
    SlashCmdList.TOPDPS = function()
        addon.OptionsController:Open()
    end
end

function Bootstrap:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true

    addon.SpecManager:Initialize()
    addon.ActionBarService:CollectButtons()
    addon.CenterIcons:Initialize()
    addon.MinimapButton:Initialize()
    addon.OptionsController:Initialize()
    self:RegisterSlashCommands()

    addon.Logger:Info("Addon initialized, version %s", addon.VERSION)
    addon.Logger:WriteDiagnosticSnapshot()
end

function Bootstrap:HandleSpecializationChanged(event)
    local changed = addon.SpecManager:Refresh(event)
    addon.SpecManager:RefreshSpellData()

    if changed then
        addon.RecommendationPresenter:Clear()
    end
end

function Bootstrap:HandleEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addon.NAME then
            addon.Database:ApplyDefaults()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if not addon.db then
            addon.Database:ApplyDefaults()
        end

        self:Initialize()
        return
    end

    if not self.initialized then
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        addon.SpecManager:RefreshEquipment()

        local provider = addon.SpecManager:GetActive()
        local providerState = provider and provider:GetDebugState() or nil
        addon.Logger:Info(
            "Equipment state updated: provider=%s%s",
            tostring(provider and provider.id or "none"),
            providerState and ("; " .. tostring(providerState)) or ""
        )
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.CombatTracker:Clear()
        addon.RecommendationPresenter:Clear()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        addon.CombatTracker:RecordCombatEvent(...)
    elseif event == "LEARNED_SPELL_IN_TAB" then
        addon.SpecManager:RefreshSpellData()
        addon.Logger:Info("Specialization spell catalog rebuilt")
    elseif event == "PLAYER_LEVEL_UP"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "CHARACTER_POINTS_CHANGED" then
        self:HandleSpecializationChanged(event)
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:HandleSpecializationChanged(event)
        addon.ActionBarService:CollectButtons()
        addon.Logger:Info("Action buttons collected: %s", #addon.ActionBarService.buttons)
    elseif event == "ACTIONBAR_PAGE_CHANGED"
        or event == "ACTIONBAR_SLOT_CHANGED"
        or event == "UPDATE_BONUS_ACTIONBAR"
        or event == "UPDATE_SHAPESHIFT_FORM" then
        addon.ActionBarService:CollectButtons()
        addon.Logger:Info("Action buttons collected: %s", #addon.ActionBarService.buttons)
    end
end

local EVENTS = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_LEVEL_UP",
    "LEARNED_SPELL_IN_TAB",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_PAGE_CHANGED",
    "ACTIONBAR_UPDATE_USABLE",
    "ACTIONBAR_UPDATE_COOLDOWN",
    "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_SHAPESHIFT_FORM",
    "UNIT_AURA",
    "UNIT_FLAGS",
    "PLAYER_REGEN_ENABLED",
    "COMBAT_LOG_EVENT_UNFILTERED",
}

local index
for index = 1, #EVENTS do
    eventFrame:RegisterEvent(EVENTS[index])
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if addon.db and addon.db.debugLogging then
        addon.Logger:SafeCall("event " .. tostring(event), function(...)
            Bootstrap:HandleEvent(...)
        end, event, ...)
    else
        Bootstrap:HandleEvent(event, ...)
    end
end)

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if not Bootstrap.initialized then
        return
    end

    Bootstrap.updateElapsed = Bootstrap.updateElapsed + elapsed
    if Bootstrap.updateElapsed < 0.08 then
        return
    end

    Bootstrap.updateElapsed = 0

    if addon.db and addon.db.debugLogging then
        addon.Logger:SafeCall("UpdateRecommendation", function()
            addon.RotationEngine:UpdateRecommendation()
        end)
    else
        addon.RotationEngine:UpdateRecommendation()
    end
end)
