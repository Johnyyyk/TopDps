local addon = TopDps
local SpecManager = addon:CreateModule("SpecManager")

SpecManager.activeProvider = nil
SpecManager.classToken = nil
SpecManager.talentTab = nil
SpecManager.RESOLUTION_READY = "ready"
SpecManager.RESOLUTION_NOT_READY = "not_ready"

local TALENT_TAB_COUNT = 3
local TRANSIENT_EMPTY_REASONS = {
    initialize = true,
    PLAYER_ENTERING_WORLD = true,
    ACTIVE_TALENT_GROUP_CHANGED = true,
}

local function IsTransientEmptyReason(reason)
    if TRANSIENT_EMPTY_REASONS[reason] then
        return true
    end

    return string.find(tostring(reason or ""), "^retry:") ~= nil
end

function SpecManager:DetectTalentTab(reason)
    local talentGroup = addon.GameApi:GetActiveTalentGroup()
    local pointsByTab = {}
    local totalPoints = 0
    local tabIndex

    for tabIndex = 1, TALENT_TAB_COUNT do
        local points = addon.GameApi:GetTalentPoints(tabIndex, talentGroup)
        if points == nil then
            return nil, self.RESOLUTION_NOT_READY
        end

        pointsByTab[tabIndex] = points
        totalPoints = totalPoints + points
    end

    if totalPoints <= 0 then
        if IsTransientEmptyReason(reason) then
            return nil, self.RESOLUTION_NOT_READY
        end

        return nil, self.RESOLUTION_READY
    end

    local selectedTab
    local maximumShare = -1
    local hasTie = false

    for tabIndex = 1, TALENT_TAB_COUNT do
        local share = pointsByTab[tabIndex] / totalPoints
        if share > maximumShare then
            selectedTab = tabIndex
            maximumShare = share
            hasTie = false
        elseif share == maximumShare then
            hasTie = true
        end
    end

    if hasTie then
        return nil, self.RESOLUTION_READY
    end

    return selectedTab, self.RESOLUTION_READY
end

function SpecManager:ResolveProvider(reason)
    local _, classToken = UnitClass("player")
    if not classToken then
        return nil, nil, nil, self.RESOLUTION_NOT_READY
    end

    local playerLevel = UnitLevel("player") or 0
    if playerLevel < 10 then
        return nil, classToken, nil, self.RESOLUTION_READY
    end

    local talentTab, resolution = self:DetectTalentTab(reason)
    if resolution == self.RESOLUTION_NOT_READY then
        return nil, classToken, nil, resolution
    end

    return addon.SpecRegistry:Get(classToken, talentTab), classToken, talentTab, self.RESOLUTION_READY
end

function SpecManager:Refresh(reason)
    local previousProvider = self.activeProvider
    local provider, classToken, talentTab, resolution = self:ResolveProvider(reason)

    if resolution == self.RESOLUTION_NOT_READY then
        return false, resolution
    end

    self.activeProvider = provider
    self.classToken = classToken
    self.talentTab = talentTab

    if provider then
        provider:Initialize()

        if provider ~= previousProvider then
            provider:RefreshEquipment()
        end
    end

    local changed = provider ~= previousProvider
    if changed and addon.Logger then
        addon.Logger:Info(
            "Active specialization changed: provider=%s, class=%s, talentTab=%s, reason=%s",
            tostring(provider and provider.id or "none"),
            tostring(classToken or "none"),
            tostring(talentTab or "none"),
            tostring(reason or "unknown")
        )
    end

    return changed, resolution
end

function SpecManager:Initialize()
    return self:Refresh("initialize")
end

function SpecManager:GetActive()
    return self.activeProvider
end

function SpecManager:RefreshSpellData()
    local provider = self.activeProvider
    if provider then
        provider:RefreshSpellData()
    end
end

function SpecManager:RefreshEquipment()
    local provider = self.activeProvider
    if provider then
        provider:RefreshEquipment()
    end
end
