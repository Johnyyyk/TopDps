local addon = TopDps
local SpecManager = addon:CreateModule("SpecManager")

SpecManager.activeProvider = nil
SpecManager.classToken = nil
SpecManager.talentTab = nil

local TALENT_TAB_COUNT = 3

function SpecManager:DetectTalentTab()
    local talentGroup = addon.GameApi:GetActiveTalentGroup()
    local pointsByTab = {}
    local totalPoints = 0
    local tabIndex

    for tabIndex = 1, TALENT_TAB_COUNT do
        local points = addon.GameApi:GetTalentPoints(tabIndex, talentGroup)
        if points == nil then
            return nil
        end

        pointsByTab[tabIndex] = points
        totalPoints = totalPoints + points
    end

    if totalPoints <= 0 then
        return nil
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
        return nil
    end

    return selectedTab
end

function SpecManager:ResolveProvider()
    local _, classToken = UnitClass("player")
    if not classToken then
        return nil, nil, nil
    end

    local playerLevel = UnitLevel("player") or 0
    if playerLevel < 10 then
        return nil, classToken, nil
    end

    local talentTab = self:DetectTalentTab()
    if not talentTab then
        return nil, classToken, nil
    end

    return addon.SpecRegistry:Get(classToken, talentTab), classToken, talentTab
end

function SpecManager:Refresh(reason)
    local previousProvider = self.activeProvider
    local provider, classToken, talentTab = self:ResolveProvider()

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

    return changed
end

function SpecManager:Initialize()
    self:Refresh("initialize")
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
