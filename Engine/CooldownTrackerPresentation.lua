local addon = TopDps
local CooldownTracker = addon.CooldownTracker

local originalGetTrinketState = CooldownTracker.GetTrinketState
function CooldownTracker:GetTrinketState(entry)
    local state = originalGetTrinketState(self, entry)

    if state and state.state == "ACTIVE" then
        state.icon = entry.icon
    end

    return state
end
