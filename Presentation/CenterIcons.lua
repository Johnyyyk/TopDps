local addon = TopDps
local CenterIcons = addon:CreateModule("CenterIcons")

local PRIMARY_FRAME_TEXTURE = "Interface\\AddOns\\TopDps\\Textures\\CenterFrame"
local NEXT_SWING_FRAME_TEXTURE = "Interface\\AddOns\\TopDps\\Textures\\CenterFrameNextSwing"

local function GetEntryTexture(entry)
    if not entry or not GetSpellInfo then
        return nil
    end

    local spell = entry.spellName or entry.spellId
    if not spell then
        return nil
    end

    local _, _, texture = GetSpellInfo(spell)
    return texture
end

local function CreateIconFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    frame.elapsed = 0

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(0, 0, 0, 0.82)
    frame.background = background

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon

    local overlay = frame:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints(frame)
    overlay:SetTexture(PRIMARY_FRAME_TEXTURE)
    overlay:SetBlendMode("ADD")
    frame.overlay = overlay

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local pulse = (math.sin(self.elapsed * 3.2) + 1) * 0.5
        self.overlay:SetAlpha(0.72 + pulse * 0.28)
    end)

    frame:EnableMouse(false)
    frame:Hide()

    return frame
end

function CenterIcons:Initialize()
    self.frames = {
        CreateIconFrame("TopDpsCenterIconLeft"),
        CreateIconFrame("TopDpsCenterIconRight"),
    }

    self:ApplyLayout()
    self:SetOpacity(addon.db.rotation.centerIcons.opacity)
end

function CenterIcons:ApplyLayout()
    if not self.frames then
        return
    end

    local size = tonumber(addon.db.rotation.centerIcons.size) or addon.DEFAULTS.centerIconsSize
    size = math.max(addon.CENTER_ICON_SIZE_MIN, math.min(addon.CENTER_ICON_SIZE_MAX, size))

    local index
    for index = 1, #self.frames do
        local frame = self.frames[index]
        local direction = index == 1 and -1 or 1

        frame:SetWidth(size)
        frame:SetHeight(size)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", direction * addon.CENTER_ICON_OFFSET, 0)

        local inset = math.max(4, math.floor(size * 0.09 + 0.5))
        frame.background:ClearAllPoints()
        frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
        frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        frame.icon:ClearAllPoints()
        frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
        frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    end
end

function CenterIcons:SetOpacity(opacity)
    if not self.frames then
        return
    end

    local index
    for index = 1, #self.frames do
        self.frames[index]:SetAlpha(opacity)
    end
end

local function HideFrames(centerIcons)
    if not centerIcons.frames then
        return
    end

    local index
    for index = 1, #centerIcons.frames do
        centerIcons.frames[index]:Hide()
    end
end

local function ShowFrame(centerIcons, index, texture, frameTexture)
    local frame = centerIcons.frames[index]
    frame.icon:SetTexture(texture)
    frame.overlay:SetTexture(frameTexture)
    frame.elapsed = index == 1 and 0 or 0.65
    frame:SetAlpha(addon.db.rotation.centerIcons.opacity)
    frame:Show()
end

function CenterIcons:Show(primaryEntries, nextSwingEntries)
    self.currentPrimaryEntries = primaryEntries
    self.currentNextSwingEntries = nextSwingEntries
    self:Refresh()
end

function CenterIcons:Hide()
    self.currentPrimaryEntries = nil
    self.currentNextSwingEntries = nil
    HideFrames(self)
end

function CenterIcons:Refresh()
    if not self.frames then
        return
    end

    if not addon.Settings:IsRotationEnabled()
        or not addon.Settings:IsModeActive()
        or not addon.db.rotation.centerIcons.enabled then
        HideFrames(self)
        return
    end

    local primaryTexture = GetEntryTexture(self.currentPrimaryEntries and self.currentPrimaryEntries[1])
    local nextSwingTexture = GetEntryTexture(self.currentNextSwingEntries and self.currentNextSwingEntries[1])

    if nextSwingTexture then
        ShowFrame(self, 1, nextSwingTexture, NEXT_SWING_FRAME_TEXTURE)

        if primaryTexture then
            ShowFrame(self, 2, primaryTexture, PRIMARY_FRAME_TEXTURE)
        else
            self.frames[2]:Hide()
        end
    elseif primaryTexture then
        ShowFrame(self, 1, primaryTexture, PRIMARY_FRAME_TEXTURE)
        ShowFrame(self, 2, primaryTexture, PRIMARY_FRAME_TEXTURE)
    else
        HideFrames(self)
    end
end
