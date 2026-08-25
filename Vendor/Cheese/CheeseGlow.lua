local addon = TopDps
local CheeseHighlight = addon:CreateModule("CheeseHighlight")

CheeseHighlight.unused = CheeseHighlight.unused or {}
CheeseHighlight.active = CheeseHighlight.active or {}
CheeseHighlight.count = CheeseHighlight.count or 0

local function IsAnimPlaying(self)
    return self.isPlaying
end

local function ApplyTextureColor(texture, color)
    if not texture or not texture.SetVertexColor then
        return
    end

    local red = color and tonumber(color.r) or 1
    local green = color and tonumber(color.g) or 1
    local blue = color and tonumber(color.b) or 1
    texture:SetVertexColor(red, green, blue)
end

local function ApplyOverlayColor(overlay, color)
    ApplyTextureColor(overlay.spark, color)
    ApplyTextureColor(overlay.innerGlow, color)
    ApplyTextureColor(overlay.innerGlowOver, color)
    ApplyTextureColor(overlay.outerGlow, color)
    ApplyTextureColor(overlay.outerGlowOver, color)
    ApplyTextureColor(overlay.ants, color)
end

local function ApplySteadyGlow(overlay)
    local frameWidth, frameHeight = overlay:GetSize()

    overlay.spark:SetAlpha(0)
    overlay.spark:SetSize(frameWidth, frameHeight)

    overlay.innerGlow:SetAlpha(0)
    overlay.innerGlow:SetSize(frameWidth, frameHeight)
    overlay.innerGlowOver:SetAlpha(0)
    overlay.innerGlowOver:SetSize(frameWidth, frameHeight)

    overlay.outerGlow:SetAlpha(1)
    overlay.outerGlow:SetSize(frameWidth, frameHeight)
    overlay.outerGlowOver:SetAlpha(0)
    overlay.outerGlowOver:SetSize(frameWidth, frameHeight)

    overlay.ants:SetAlpha(1)
    overlay.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
    overlay:Show()
end

function TopDpsCheese_AnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)
    if not texture.frame then
        texture.frame = 1
        texture.throttle = throttle
        texture.numColumns = math.floor(textureWidth / frameWidth)
        texture.numRows = math.floor(textureHeight / frameHeight)
        texture.columnWidth = frameWidth / textureWidth
        texture.rowHeight = frameHeight / textureHeight
    end

    local frame = texture.frame
    if not texture.throttle or texture.throttle > throttle then
        local framesToAdvance = math.floor(texture.throttle / throttle)
        while frame + framesToAdvance > numFrames do
            frame = frame - numFrames
        end

        frame = frame + framesToAdvance
        texture.throttle = 0

        local left = (frame - 1) % texture.numColumns * texture.columnWidth
        local right = left + texture.columnWidth
        local bottom = math.ceil(frame / texture.numColumns) * texture.rowHeight
        local top = bottom - texture.rowHeight
        texture:SetTexCoord(left, right, top, bottom)
        texture.frame = frame
    else
        texture.throttle = texture.throttle + elapsed
    end
end

function CheeseHighlight:GetOverlay()
    local overlay = table.remove(self.unused)
    if not overlay then
        self.count = self.count + 1
        overlay = CreateFrame(
            "Frame",
            "TopDpsCheeseActionButtonOverlay" .. self.count,
            UIParent,
            "TopDpsCheeseActionBarButtonGlow"
        )
        overlay.animOut.isPlaying = false
        overlay.animOut.IsPlaying = IsAnimPlaying
    end

    return overlay
end

function CheeseHighlight:Show(button, appearance)
    local overlay = button.topDpsCheeseOverlay
    if overlay then
        if overlay.animOut:IsPlaying() then
            overlay.animOut:Stop()
        end

        ApplySteadyGlow(overlay)
        ApplyOverlayColor(overlay, appearance and appearance.color or nil)
        return overlay
    end

    overlay = self:GetOverlay()
    button.topDpsCheeseOverlay = overlay
    self.active[button] = overlay

    local frameWidth, frameHeight = button:GetSize()
    overlay:SetParent(button)
    overlay:SetFrameLevel(button:GetFrameLevel() + 11)
    overlay:ClearAllPoints()
    overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
    overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
    ApplySteadyGlow(overlay)
    ApplyOverlayColor(overlay, appearance and appearance.color or nil)

    return overlay
end

function CheeseHighlight:Hide(button)
    local overlay = button.topDpsCheeseOverlay
    if not overlay then
        return
    end

    if overlay.animIn and overlay.animIn:IsPlaying() then
        overlay.animIn:Stop()
    end

    if button:IsVisible() then
        overlay.animOut:Play()
    else
        TopDpsCheeseGlowAnimOutFinished(overlay.animOut)
    end
end

function TopDpsCheeseGlowAnimOutFinished(animGroup)
    local overlay = animGroup:GetParent()
    local button = overlay:GetParent()

    overlay:Hide()
    button.topDpsCheeseOverlay = nil
    CheeseHighlight.active[button] = nil
    table.insert(CheeseHighlight.unused, overlay)
end
