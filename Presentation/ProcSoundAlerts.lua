local addon = TopDps
local ProcSoundAlerts = addon:CreateModule("ProcSoundAlerts")

local PROC_SOUND_PATH = "Sound\\Spells\\ShaysBell.wav"

ProcSoundAlerts.activeStates = {}

local function IsProcEntry(entry)
    return entry and entry.group == addon.COOLDOWN_GROUP_PROCS
end

function ProcSoundAlerts:Reset()
    self.activeStates = {}
end

function ProcSoundAlerts:Update(entries, states)
    if type(entries) ~= "table" or type(states) ~= "table" then
        return
    end

    local soundsEnabled = addon.Settings:AreCooldownProcSoundsEnabled()
    local shouldPlay = false
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if IsProcEntry(entry) then
            local state = states[index]
            local isActive = state and state.state == "ACTIVE" or false
            local previous = self.activeStates[entry.settingId]

            if soundsEnabled
                and previous ~= nil
                and previous == false
                and isActive
                and addon.Settings:IsCooldownProcSoundEnabled(entry.settingId, true) then
                shouldPlay = true
            end

            self.activeStates[entry.settingId] = isActive
        end
    end

    if shouldPlay and PlaySoundFile then
        pcall(PlaySoundFile, PROC_SOUND_PATH)
    end
end

local originalSetEntries = addon.CooldownPanel.SetEntries
function addon.CooldownPanel:SetEntries(entries)
    ProcSoundAlerts:Reset()
    return originalSetEntries(self, entries)
end

local originalUpdate = addon.CooldownPanel.Update
function addon.CooldownPanel:Update(states)
    ProcSoundAlerts:Update(self.entries, states)
    return originalUpdate(self, states)
end

local originalHide = addon.CooldownPanel.Hide
function addon.CooldownPanel:Hide()
    ProcSoundAlerts:Reset()
    return originalHide(self)
end
