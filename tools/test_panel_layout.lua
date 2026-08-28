local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual), 2)
    end
end

local Frame = {}
Frame.__index = Frame

local function NewFrame(width, height)
    return setmetatable({ width = width or 0, height = height or 0, shown = false, scripts = {} }, Frame)
end

function Frame:SetWidth(width) self.width = width end
function Frame:SetHeight(height) self.height = height end
function Frame:SetAlpha(alpha) self.alpha = alpha end
function Frame:Show() self.shown = true end
function Frame:IsShown() return self.shown end
function Frame:SetScript(event, callback) self.scripts[event] = callback end
function Frame:StartMoving() self.moving = true end
function Frame:StopMovingOrSizing() self.moving = false end
function Frame:GetFrameLevel() return 1 end
function Frame:CreateTexture() return NewFrame() end
function Frame:CreateFontString() return NewFrame() end
function Frame:ClearAllPoints() self.point = nil end

function Frame:Hide()
    local wasShown = self.shown
    self.shown = false
    if wasShown and self.scripts.OnHide then
        self.scripts.OnHide(self)
    end
end

for _, method in ipairs({
    "EnableMouse", "SetBackdropColor", "SetBackdropBorderColor", "SetClampedToScreen",
    "SetMovable", "RegisterForDrag", "SetFrameStrata", "SetBackdrop", "SetText", "SetFrameLevel",
    "SetAllPoints", "SetTexture", "SetBlendMode", "SetJustifyH", "SetVertexColor",
    "SetDesaturated", "SetReverse", "SetCooldown",
}) do
    Frame[method] = function() end
end

CreateFrame = function() return NewFrame() end
GetTime = function() return 100 end

function Frame:SetPoint(point, relativeTo, relativePoint, x, y)
    self.point = { point, relativeTo, relativePoint, x, y }
end

function Frame:GetCenter()
    if not self.point then
        return self.width / 2, self.height / 2
    end

    local point, relativeTo, relativePoint, x, y = unpack(self.point)
    local parentX, parentY = relativeTo:GetCenter()
    AssertEqual(point, relativePoint, "test frame uses matching anchors")
    if point == "CENTER" then
        return parentX + x, parentY + y
    end

    AssertEqual(point, "TOPLEFT", "icon anchor")
    return parentX - relativeTo.width / 2 + x + self.width / 2,
        parentY + relativeTo.height / 2 + y - self.height / 2
end

local function Bounds(frame)
    local x, y = frame:GetCenter()
    return { x = x, y = y, width = frame.width, height = frame.height }
end

local function AssertBounds(frame, expected, message)
    local actual = Bounds(frame)
    for _, key in ipairs({ "x", "y", "width", "height" }) do
        AssertEqual(actual[key], expected[key], message .. " " .. key)
    end
end

local function AssertVerticalBounds(frame, expected, message)
    local actual = Bounds(frame)
    AssertEqual(actual.y, expected.y, message .. " y")
    AssertEqual(actual.height, expected.height, message .. " height")
end

TopDps = {}
dofile("Core/Namespace.lua")
dofile("Core/Constants.lua")
dofile("Core/Settings.lua")
dofile("Presentation/CooldownPanel.lua")
dofile("Presentation/CooldownPanelLayout.lua")
dofile("Presentation/CooldownPanelState.lua")

local addon = TopDps
local panel = addon.CooldownPanel
local settings = addon.Settings
local disabledCategories = {}
local iconsPerRow = 7
local buffSide = addon.PANEL_BUFF_SIDE_LEFT
local groupOrder = addon.DEFAULTS.cooldownPanelGroupOrder

UIParent = NewFrame(1920, 1080)
addon.L = { COOLDOWN_PANEL_DRAG_HINT = "Drag panel" }
addon.db = {
    panel = {
        locked = true,
        iconSize = addon.DEFAULTS.cooldownPanelIconSize,
        position = { x = 80, y = -166 },
    },
}
addon.CooldownRegistry = {
    GetPanelPresentation = function(_, entry) return entry.panelCategory, entry.panelBehavior end,
    IsEntryApplicable = function(_, entry) return entry.applicable ~= false end,
}

function settings:IsCooldownPanelCategoryEnabled(category) return not disabledCategories[category] end
function settings:GetCooldownPanelCategoryScale(category) return addon.DEFAULTS.cooldownPanelGroupScale[category] end
function settings:GetCooldownPanelIconsPerRow() return iconsPerRow end
function settings:GetCooldownPanelIconGap() return addon.DEFAULTS.cooldownPanelIconGap end
function settings:GetCooldownPanelGroupGap() return addon.DEFAULTS.cooldownPanelGroupGap end
function settings:GetCooldownPanelBuffSide() return buffSide end
function settings:GetCooldownPanelGroupOrder() return groupOrder end
function settings:EnsureCooldownPanelUxDefaults() end
function settings:AreCooldownPanelTimersShown() return false end

local function SetEntries(entries)
    panel.entries = {}
    panel.icons = {}
    panel.states = {}
    panel.frame = nil
    panel.title = nil
    panel.isDragging = false
    panel:InvalidateLayout()
    panel:Initialize()
    panel:SetEntries(entries)
end

local function Entry(category, behavior)
    return { panelCategory = category, panelBehavior = behavior }
end

local entries = {
    Entry(addon.PANEL_CATEGORY_ABILITIES, addon.PANEL_BEHAVIOR_ALWAYS),
    Entry(addon.PANEL_CATEGORY_PROCS, addon.PANEL_BEHAVIOR_ACTIVE_ONLY),
    Entry(addon.PANEL_CATEGORY_PROCS, addon.PANEL_BEHAVIOR_ACTIVE_ONLY),
    Entry(addon.PANEL_CATEGORY_PROCS, addon.PANEL_BEHAVIOR_ACTIVE_ONLY),
    Entry(addon.PANEL_CATEGORY_BUFFS, addon.PANEL_BEHAVIOR_REQUIRED_BUFF),
    Entry(addon.PANEL_CATEGORY_BUFFS, addon.PANEL_BEHAVIOR_REQUIRED_STATE),
    Entry(addon.PANEL_CATEGORY_BUFFS, addon.PANEL_BEHAVIOR_SELECTABLE_BUFF),
    Entry(addon.PANEL_CATEGORY_BUFFS, addon.PANEL_BEHAVIOR_ACTIVE_ONLY),
    Entry(addon.PANEL_CATEGORY_COOLDOWNS, addon.PANEL_BEHAVIOR_ALWAYS),
}
local active = { state = "ACTIVE" }
local inactive = { state = "INACTIVE" }

local function InitialStates()
    return {
        { state = "READY" }, inactive, inactive, inactive, active, active, active, inactive,
        { state = "COOLDOWN" },
    }
end

local function TestDragging()
    addon.db.panel.locked = false
    SetEntries(entries)
    panel:Update(InitialStates())

    for _, source in ipairs({ panel.frame, panel.icons[1].frame }) do
        local savedX = addon.db.panel.position.x
        local savedY = addon.db.panel.position.y
        local movedX, movedY = savedX + 57, savedY + 31
        source.scripts.OnDragStart(source)
        AssertEqual(panel.frame.moving, true, "frame and icon both start dragging")
        panel.frame:SetPoint("CENTER", UIParent, "CENTER", movedX, movedY)
        local movedBounds = Bounds(panel.frame)

        local changedStates = InitialStates()
        changedStates[5] = inactive
        changedStates[7] = inactive
        panel:Update(changedStates)
        AssertBounds(panel.frame, movedBounds, "updates do not reset geometry during dragging")
        AssertEqual(addon.db.panel.position.x, savedX, "x is not saved before drag stops")
        AssertEqual(addon.db.panel.position.y, savedY, "y is not saved before drag stops")

        source.scripts.OnDragStop(source)
        AssertEqual(panel.frame.moving, false, "drag stops")
        AssertEqual(addon.db.panel.position.x, movedX, "drag saves x")
        AssertEqual(addon.db.panel.position.y, movedY, "drag saves y")
        local parentX, parentY = UIParent:GetCenter()
        local x, y = panel.frame:GetCenter()
        AssertEqual(x, parentX + movedX, "new x survives pending layout changes")
        AssertEqual(y, parentY + movedY, "new y survives pending layout changes")
    end

    panel.frame.scripts.OnDragStart(panel.frame)
    panel.frame:SetPoint("CENTER", UIParent, "CENTER", 137, -211)
    settings:SetCooldownPanelLocked(true)
    AssertEqual(panel.frame.moving, false, "locking stops an active drag")
    AssertEqual(addon.db.panel.position.x, 137, "locking preserves the dragged x")
    AssertEqual(addon.db.panel.position.y, -211, "locking preserves the dragged y")
    panel.frame.scripts.OnDragStart(panel.frame)
    panel.icons[1].frame.scripts.OnDragStart(panel.icons[1].frame)
    AssertEqual(panel.frame.moving, false, "locked frame and icons cannot start dragging")

    settings:SetCooldownPanelLocked(false)
    panel.frame.scripts.OnDragStart(panel.frame)
    panel.frame:SetPoint("CENTER", UIParent, "CENTER", 150, -190)
    panel:Hide()
    AssertEqual(panel.frame.moving, false, "hiding stops an active drag")
    AssertEqual(panel.frame:IsShown(), false, "saving after hide does not show the panel")
    AssertEqual(addon.db.panel.position.x, 150, "hiding preserves the dragged x")
    AssertEqual(addon.db.panel.position.y, -190, "hiding preserves the dragged y")

    local savedPosition = { x = addon.db.panel.position.x, y = addon.db.panel.position.y }
    SetEntries(entries)
    panel:Update(InitialStates())
    local parentX, parentY = UIParent:GetCenter()
    local x, y = panel.frame:GetCenter()
    AssertEqual(x, parentX + savedPosition.x, "recreated panel restores saved x")
    AssertEqual(y, parentY + savedPosition.y, "recreated panel restores saved y")
end

TestDragging()

local function TestDynamicLayout()
    addon.db.panel.locked = true
    SetEntries(entries)
    panel.states = InitialStates()
    AssertEqual(panel:ApplyLayout(), 3, "only persistent entries are visible initially")
    local frameBounds = Bounds(panel.frame)
    local abilityBounds = Bounds(panel.icons[1].frame)
    local cooldownBounds = Bounds(panel.icons[9].frame)

    local function CheckStable(message)
        local count = panel:ApplyLayout()
        AssertVerticalBounds(panel.frame, frameBounds, message .. " container")
        AssertEqual(Bounds(panel.frame).x, frameBounds.x, message .. " container center")
        AssertVerticalBounds(panel.icons[1].frame, abilityBounds, message .. " ability")
        AssertVerticalBounds(panel.icons[9].frame, cooldownBounds, message .. " cooldown")
        return count
    end

    panel.states[4] = active
    AssertEqual(CheckStable("first proc"), 4, "first proc becomes visible")
    local procBounds = Bounds(panel.icons[4].frame)
    AssertEqual(procBounds.x, frameBounds.x, "a single proc is centered without hidden horizontal slots")
    panel.states[2] = active
    panel.states[3] = active
    AssertEqual(CheckStable("several procs"), 6, "all active procs are counted")
    AssertVerticalBounds(panel.icons[4].frame, procBounds, "other procs do not move a visible proc vertically")

    panel.states[5] = inactive
    panel.states[6] = inactive
    AssertEqual(CheckStable("missing requirements"), 8, "missing buff and state become visible")
    AssertEqual(panel.icons[5].frame.shown, true, "missing required buff is shown")
    AssertEqual(panel.icons[6].frame.shown, true, "missing required state is shown")

    panel.states[7] = inactive
    CheckStable("selectable buff becomes a warning")
    AssertEqual(panel.icons[7].frame.shown, true, "selectable warning stays visible")
    panel.states[8] = active
    AssertEqual(CheckStable("optional buff"), 9, "active optional buff becomes visible")

    for _, soundsEnabled in ipairs({ false, true }) do
        addon.db.panel.procSoundsEnabled = soundsEnabled
        panel.states = InitialStates()
        CheckStable("procs and warnings disappear")
        for _, index in ipairs({ 2, 3, 4, 5, 6, 8 }) do
            AssertEqual(panel.icons[index].frame.shown, false, "inactive slot stays hidden")
        end
        panel.states[2] = active
        CheckStable("proc with changed sound setting")
    end

    addon.db.panel.locked = false
    panel:ApplyLockState()
    AssertEqual(CheckStable("unlocked preview"), 9, "preview shows all applicable entries")
    panel.states[5] = inactive
    panel.states[7] = inactive
    CheckStable("requirements change during preview")
    addon.db.panel.locked = true
    panel:ApplyLockState()
    CheckStable("preview is locked again")

    panel.states = {}
    AssertEqual(CheckStable("no tracked states"), 0, "reserved slots are not visible content")
    for index = 1, #entries do
        AssertEqual(panel.icons[index].frame.shown, false, "missing state never leaves a visible icon")
    end
end

local function TestHorizontalPacking()
    iconsPerRow = 7
    addon.db.panel.locked = true
    for _, side in ipairs({ addon.PANEL_BUFF_SIDE_LEFT, addon.PANEL_BUFF_SIDE_RIGHT }) do
        buffSide = side
        SetEntries({ entries[1], entries[1], entries[7], entries[5] })
        panel.states = { { state = "READY" }, { state = "READY" }, inactive, active }
        panel:ApplyLayout()
        local frameX = Bounds(panel.frame).x
        local first = Bounds(panel.icons[1].frame)
        local second = Bounds(panel.icons[2].frame)
        AssertEqual((first.x + second.x) / 2, frameX, "abilities remain centered without a visible seal")
        AssertEqual(Bounds(panel.icons[3].frame).x, frameX, "missing seal warning is centered")
        local previousHeight = panel.frame.height

        panel.states[3] = active
        panel:ApplyLayout()
        first = Bounds(panel.icons[1].frame)
        second = Bounds(panel.icons[2].frame)
        local seal = Bounds(panel.icons[3].frame)
        local actualGap
        if side == addon.PANEL_BUFF_SIDE_LEFT then
            actualGap = first.x - first.width / 2 - (seal.x + seal.width / 2)
        else
            actualGap = seal.x - seal.width / 2 - (second.x + second.width / 2)
        end
        AssertEqual(actualGap, settings:GetCooldownPanelGroupGap(), "only the visible seal takes horizontal space")
        local expectedWidth = first.width + second.width + settings:GetCooldownPanelIconGap()
            + seal.width + settings:GetCooldownPanelGroupGap() + panel.PADDING * 2
        AssertEqual(panel.frame.width, expectedWidth, "hidden required buffs do not widen the container")
        AssertEqual(panel.frame.height, previousHeight, "horizontal packing preserves vertical geometry")

        panel.states[4] = inactive
        panel:ApplyLayout()
        local warning = Bounds(panel.icons[4].frame)
        AssertEqual(warning.x, frameX, "required buff warning is centered without hidden warning slots")
        AssertEqual(warning.width > seal.width, true, "required buff warning remains enlarged")
    end

    local originalScale = settings.GetCooldownPanelCategoryScale
    local originalSize = addon.db.panel.iconSize
    settings.GetCooldownPanelCategoryScale = function() return addon.COOLDOWN_PANEL_GROUP_SCALE_MIN end
    SetEntries({ entries[1] })
    panel.states = { { state = "READY" } }
    local minimumSize = addon.COOLDOWN_PANEL_ICON_SIZE_MIN
    for _, size in ipairs({ minimumSize, minimumSize + addon.COOLDOWN_PANEL_ICON_SIZE_STEP, minimumSize }) do
        settings:SetCooldownPanelIconSize(size)
        AssertEqual(Bounds(panel.icons[1].frame).x, Bounds(panel.frame).x,
            "minimum icon remains centered when the base size changes")
    end
    settings.GetCooldownPanelCategoryScale = originalScale
    settings:SetCooldownPanelIconSize(originalSize)
end

TestHorizontalPacking()

for _, columns in ipairs({ 1, 3, 7 }) do
    iconsPerRow = columns
    for _, side in ipairs({ addon.PANEL_BUFF_SIDE_LEFT, addon.PANEL_BUFF_SIDE_RIGHT }) do
        buffSide = side
        for _, order in ipairs({
            addon.DEFAULTS.cooldownPanelGroupOrder,
            { addon.PANEL_CATEGORY_COOLDOWNS, addon.PANEL_CATEGORY_PROCS, addon.PANEL_CATEGORY_ABILITIES },
        }) do
            groupOrder = order
            TestDynamicLayout()
        end
    end
end

-- Выключенные и неприменимые элементы не должны резервировать место.
SetEntries({ entries[1] })
panel.states = { { state = "READY" } }
panel:ApplyLayout()
local singleAbilityBounds = Bounds(panel.frame)
AssertEqual(Bounds(panel.icons[1].frame).x, singleAbilityBounds.x, "small icon is centered in the minimum container")
local excludedProc = Entry(addon.PANEL_CATEGORY_PROCS, addon.PANEL_BEHAVIOR_ACTIVE_ONLY)
SetEntries({ entries[1], excludedProc })
panel.states = { { state = "READY" }, active }
for _, exclusion in ipairs({ "category", "applicability" }) do
    disabledCategories[addon.PANEL_CATEGORY_PROCS] = exclusion == "category"
    excludedProc.applicable = exclusion ~= "applicability"
    AssertEqual(panel:ApplyLayout(), 1, "excluded proc is not counted")
    AssertBounds(panel.frame, singleAbilityBounds, "excluded proc takes no space")
    AssertEqual(panel.icons[2].frame.shown, false, "excluded proc is hidden")
end
disabledCategories[addon.PANEL_CATEGORY_PROCS] = nil

print("panel layout regression tests passed")
