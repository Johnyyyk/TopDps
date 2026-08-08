local addon = TopDps
local SpecManager = addon:CreateModule("SpecManager")

SpecManager.activeProvider = nil
SpecManager.classToken = nil
SpecManager.talentTab = nil

local TALENT_TAB_COUNT = 3

function SpecManager:DetectTalentTab(classToken)
    local talentGroup = addon.GameApi:GetActiveTalentGroup()
    local pointsByTab = {}
    local maximumPoints = -1
    local tabIndex

    for tabIndex = 1, TALENT_TAB_COUNT do
        local points = addon.GameApi:GetTalentPoints(tabIndex, talentGroup)
        if points == nil then
            return nil
        end

        pointsByTab[tabIndex] = points
        maximumPoints = math.max(maximumPoints, points)
    end

    if maximumPoints <= 0 then
        return nil
    end

    local candidates = {}
    for tabIndex = 1, TALENT_TAB_COUNT do
        if pointsByTab[tabIndex] == maximumPoints then
            table.insert(candidates, tabIndex)
        end
    end

    if #candidates == 1 then
        return candidates[1]
    end

    -- При ничьей не дёргаем активный provider без необходимости.
    if self.activeProvider and self.activeProvider.classToken == classToken then
        local index
        for index = 1, #candidates do
            if candidates[index] == self.activeProvider.talentTab then
                return candidates[index]
            end
        end
    end

    local defaultProvider = addon.SpecRegistry:GetDefaultForClass(classToken)
    if defaultProvider then
        local index
        for index = 1, #candidates do
            if candidates[index] == defaultProvider.talentTab then
                return candidates[index]
            end
        end
    end

    return candidates[1]
end

function SpecManager:ResolveProvider()
    local _, classToken = UnitClass("player")
    if not classToken then
        return nil, nil, nil
    end

    local defaultProvider = addon.SpecRegistry:GetDefaultForClass(classToken)
    local playerLevel = UnitLevel("player") or 0

    if playerLevel < 10 then
        return defaultProvider, classToken, defaultProvider and defaultProvider.talentTab or nil
    end

    local talentTab = self:DetectTalentTab(classToken)
    if not talentTab then
        return defaultProvider, classToken, defaultProvider and defaultProvider.talentTab or nil
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
