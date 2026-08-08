local addon = TopDps
local BlizzardHighlight = addon:CreateModule("BlizzardHighlight")

BlizzardHighlight.shines = BlizzardHighlight.shines or {}

function BlizzardHighlight:GetShine(button)
    local shine = self.shines[button]
    if shine then
        return shine
    end

    local buttonName = button:GetName()
    local shineName = buttonName and (buttonName .. "TopDpsShine") or nil
    shine = CreateFrame("Frame", shineName, button, "AutoCastShineTemplate")
    shine:SetPoint("CENTER", button, "CENTER", 0, 0)
    shine:SetWidth(36)
    shine:SetHeight(36)
    shine:SetFrameLevel(button:GetFrameLevel() + 10)
    shine:EnableMouse(false)
    shine:Hide()

    self.shines[button] = shine
    return shine
end

function BlizzardHighlight:Show(button)
    local shine = self:GetShine(button)
    shine:Show()

    if AutoCastShine_AutoCastStart then
        AutoCastShine_AutoCastStart(shine)
    end
end

function BlizzardHighlight:Hide(button)
    local shine = self.shines[button]
    if not shine then
        return
    end

    if AutoCastShine_AutoCastStop then
        AutoCastShine_AutoCastStop(shine)
    end

    shine:Hide()
end
