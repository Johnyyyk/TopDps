local addon = TopDps
local RecommendationPresenter = addon:CreateModule("RecommendationPresenter")

local function GetHighlightEntries(provider, category, entries)
    return addon.ActionBarService:FindVisibleActions(provider, category, entries)
end

local function RefreshCenterIcons(presenter)
    local nextSwingEntries
    if presenter.nextSwingProvider
        and presenter.nextSwingEntries
        and presenter.nextSwingProvider:IsNextSwingCenterEnabled() then
        nextSwingEntries = presenter.nextSwingEntries
    end

    if presenter.entries or nextSwingEntries then
        addon.CenterIcons:Show(presenter.entries, nextSwingEntries)
    else
        addon.CenterIcons:Hide()
    end
end

function RecommendationPresenter:Set(provider, category, entries)
    self.provider = provider
    self.category = category
    self.entries = entries

    addon.HighlightManager:SetEntries(
        addon.HIGHLIGHT_CHANNEL_PRIMARY,
        GetHighlightEntries(provider, category, entries)
    )
    RefreshCenterIcons(self)

    local recommendationName = provider:GetRecommendationName(category, entries)
    local signature = recommendationName or "NONE"
    if self.lastSignature == signature then
        return
    end

    self.lastSignature = signature
    addon.Logger:Info("Recommendation: %s", tostring(recommendationName))

    if recommendationName and addon.db.debug.chatRecommendations and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("|cffffd200%s:|r %s", addon.NAME, string.format(addon.L.NEXT_CAST, recommendationName))
        )
    end
end

function RecommendationPresenter:SetNextSwing(provider, category, entries)
    self.nextSwingProvider = provider
    self.nextSwingCategory = category
    self.nextSwingEntries = entries

    addon.HighlightManager:SetEntries(
        addon.HIGHLIGHT_CHANNEL_NEXT_SWING,
        GetHighlightEntries(provider, category, entries)
    )
    RefreshCenterIcons(self)

    local recommendationName = provider:GetRecommendationName(category, entries)
    local signature = recommendationName or "NONE"
    if self.lastNextSwingSignature == signature then
        return
    end

    self.lastNextSwingSignature = signature
    addon.Logger:Info("Next-swing recommendation: %s", tostring(recommendationName))
end

function RecommendationPresenter:ClearPrimary()
    self.provider = nil
    self.category = nil
    self.entries = nil

    addon.HighlightManager:SetEntries(addon.HIGHLIGHT_CHANNEL_PRIMARY, nil)
    RefreshCenterIcons(self)

    if self.lastSignature == "NONE" then
        return
    end

    self.lastSignature = "NONE"
    addon.Logger:Info("Recommendation cleared")
end

function RecommendationPresenter:ClearNextSwing()
    self.nextSwingProvider = nil
    self.nextSwingCategory = nil
    self.nextSwingEntries = nil

    addon.HighlightManager:SetEntries(addon.HIGHLIGHT_CHANNEL_NEXT_SWING, nil)
    RefreshCenterIcons(self)

    if self.lastNextSwingSignature == "NONE" then
        return
    end

    self.lastNextSwingSignature = "NONE"
    addon.Logger:Info("Next-swing recommendation cleared")
end

function RecommendationPresenter:Clear()
    self:ClearPrimary()
    self:ClearNextSwing()
end

function RecommendationPresenter:RefreshHighlights()
    if self.provider and self.entries then
        addon.HighlightManager:SetEntries(
            addon.HIGHLIGHT_CHANNEL_PRIMARY,
            GetHighlightEntries(self.provider, self.category, self.entries)
        )
    end

    if self.nextSwingProvider and self.nextSwingEntries then
        addon.HighlightManager:SetEntries(
            addon.HIGHLIGHT_CHANNEL_NEXT_SWING,
            GetHighlightEntries(self.nextSwingProvider, self.nextSwingCategory, self.nextSwingEntries)
        )
    end
end

function RecommendationPresenter:ResetChatSignature()
    self.lastSignature = nil
    self.lastNextSwingSignature = nil
end
