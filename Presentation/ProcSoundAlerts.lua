local addon = TopDps
local ProcSoundAlerts = addon:CreateModule("ProcSoundAlerts")

local PROC_SOUND_PATH = "Sound\\Spells\\ShaysBell.wav"

ProcSoundAlerts.activeStates = {}

local function IsProcEntry(entry)
    return entry and entry.group == addon.COOLDOWN_GROUP_PROCS
end

local function IsPanelRuntimeEnabled()
    return addon.db
        and addon.Settings:IsPanelEnabled()
        and addon.Settings:IsModeActive()
end

local function GetEntryState(entry)
    local tracker = addon.CooldownTracker
    if not tracker then
        return nil
    end

    if entry.type == "spell" then
        return tracker:GetSpellState(entry)
    elseif entry.type == "aura" then
        return tracker:GetAuraState(entry)
    elseif entry.type == "counter" then
        return tracker:GetCounterState(entry)
    elseif entry.type == "state" then
        return tracker:GetCustomState(entry)
    elseif entry.type == "trinket" then
        return tracker:GetTrinketState(entry)
    elseif entry.type == "equipmentProc" and tracker.GetEquipmentProcState then
        return tracker:GetEquipmentProcState(entry)
    end

    return nil
end

function ProcSoundAlerts:Reset()
    self.activeStates = {}
end

function ProcSoundAlerts:UpdateEntry(entry, state, soundsEnabled)
    if not IsProcEntry(entry) then
        return false
    end

    local applicable = not addon.CooldownRegistry
        or addon.CooldownRegistry:IsEntryApplicable(entry)

    if not applicable then
        self.activeStates[entry.settingId] = nil
        return false
    end

    local isActive = state and state.state == "ACTIVE" or false
    local previous = self.activeStates[entry.settingId]
    local category = addon.PANEL_CATEGORY_PROCS
    if addon.CooldownRegistry then
        category = addon.CooldownRegistry:GetPanelPresentation(entry)
    end

    local categoryEnabled = addon.Settings:IsCooldownPanelCategoryEnabled(category)
    self.activeStates[entry.settingId] = isActive

    return soundsEnabled
        and categoryEnabled
        and previous ~= nil
        and previous == false
        and isActive
        and addon.Settings:IsCooldownProcSoundEnabled(entry.settingId, true)
end

function ProcSoundAlerts:Play()
    if PlaySoundFile then
        pcall(PlaySoundFile, PROC_SOUND_PATH)
    end
end

function ProcSoundAlerts:Update(entries, states)
    if type(entries) ~= "table" or type(states) ~= "table" then
        return
    end

    local soundsEnabled = addon.Settings:AreCooldownProcSoundsEnabled()
    local shouldPlay = false
    local index

    for index = 1, #entries do
        if self:UpdateEntry(entries[index], states[index], soundsEnabled) then
            shouldPlay = true
        end
    end

    if shouldPlay then
        self:Play()
    end
end

function ProcSoundAlerts:ShouldUpdateWhilePanelHidden()
    if not addon.Settings:IsCooldownPanelCombatOnly() or UnitAffectingCombat("player") then
        return false
    end

    local tracker = addon.CooldownTracker
    return tracker and not tracker:IsPanelAllowedOutsideCombat()
end

function ProcSoundAlerts:UpdateWhilePanelHidden()
    if not IsPanelRuntimeEnabled() then
        self:Reset()
        return
    end

    if not self:ShouldUpdateWhilePanelHidden() then
        return
    end

    local tracker = addon.CooldownTracker
    local entries = tracker:GetEntries()
    if type(entries) ~= "table" or #entries == 0 then
        return
    end

    local hasProc = false
    local index
    for index = 1, #entries do
        if IsProcEntry(entries[index]) then
            hasProc = true
            break
        end
    end

    if not hasProc then
        return
    end

    tracker:ScanPlayerAuras()

    local soundsEnabled = addon.Settings:AreCooldownProcSoundsEnabled()
    local shouldPlay = false

    for index = 1, #entries do
        local entry = entries[index]
        if IsProcEntry(entry) then
            local state = GetEntryState(entry)
            if self:UpdateEntry(entry, state, soundsEnabled) then
                shouldPlay = true
            end
        end
    end

    if shouldPlay then
        self:Play()
    end
end
