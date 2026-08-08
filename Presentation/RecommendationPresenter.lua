local addon = TopDps
local RecommendationPresenter = addon:CreateModule("RecommendationPresenter")

function RecommendationPresenter:Set(provider, category, entries)
    self.provider = provider
    self.category = category
    self.entries = entries

    addon.HighlightManager:SetEntries(entries)
    addon.CenterIcons:Show(entries)

    local recommendationName = provider:GetRecommendationName(category, entries)
    local signature = recommendationName or "NONE"
    if self.lastSignature == signature then
        return
    end

    self.lastSignature = signature
    addon.Logger:Info("Recommendation: %s", tostring(recommendationName))

    if recommendationName and addon.db.debugChatRecommendations and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format("|cffffd200%s:|r %s", addon.NAME, string.format(addon.L.NEXT_CAST, recommendationName))
        )
    end
end

function RecommendationPresenter:Clear()
    self.provider = nil
    self.category = nil
    self.entries = nil

    addon.HighlightManager:SetEntries(nil)
    addon.CenterIcons:Hide()

    if self.lastSignature == "NONE" then
        return
    end

    self.lastSignature = "NONE"
    addon.Logger:Info("Recommendation cleared")
end

function RecommendationPresenter:RefreshHighlights()
    addon.HighlightManager:SetEntries(self.entries)
end

function RecommendationPresenter:ResetChatSignature()
    self.lastSignature = nil
end
