local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        error(message .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual), 2)
    end
end

local Frame = {}
Frame.__index = Frame

local function NewFrame(width, height)
    return setmetatable({ width = width or 0, height = height or 0, shown = false }, Frame)
end

function Frame:SetWidth(width) self.width = width end
function Frame:SetHeight(height) self.height = height end
function Frame:SetAlpha(alpha) self.alpha = alpha end
function Frame:Show() self.shown = true end
function Frame:Hide() self.shown = false end
function Frame:EnableMouse() end
function Frame:SetBackdropColor() end
function Frame:SetBackdropBorderColor() end
function Frame:ClearAllPoints() self.point = nil end

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

TopDps = {}
dofile("Core/Namespace.lua")
dofile("Core/Constants.lua")
dofile("Core/Settings.lua")
dofile("Presentation/CooldownPanel.lua")
dofile("Presentation/CooldownPanelLayout.lua")

local addon = TopDps
local panel = addon.CooldownPanel
local settings = addon.Settings
local disabledCategories = {}
local iconsPerRow = 7
local buffSide = addon.PANEL_BUFF_SIDE_LEFT
local groupOrder = addon.DEFAULTS.cooldownPanelGroupOrder

UIParent = NewFrame(1920, 1080)
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

local function SetEntries(entries)
    panel.entries = entries
    panel.icons = {}
    panel.frame = NewFrame()
    panel.title = NewFrame()
    panel:InvalidateLayout()
    for index = 1, #entries do
        panel.icons[index] = { frame = NewFrame(), accent = NewFrame() }
    end
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
        AssertBounds(panel.frame, frameBounds, message .. " container")
        AssertBounds(panel.icons[1].frame, abilityBounds, message .. " ability")
        AssertBounds(panel.icons[9].frame, cooldownBounds, message .. " cooldown")
        return count
    end

    panel.states[3] = active
    AssertEqual(CheckStable("first proc"), 4, "first proc becomes visible")
    local procBounds = Bounds(panel.icons[3].frame)
    panel.states[2] = active
    panel.states[4] = active
    AssertEqual(CheckStable("several procs"), 6, "all active procs are counted")
    AssertBounds(panel.icons[3].frame, procBounds, "other procs do not move an already visible proc")

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

-- Сохраняется прежний контракт координат: центр панели относительно центра UIParent.
SetEntries(entries)
panel.states = InitialStates()
addon.db.panel.locked = false
panel:ApplyLayout()
panel.frame:SetPoint("CENTER", UIParent, "CENTER", 137, -211)
panel:SavePosition()
AssertEqual(addon.db.panel.position.x, 137, "drag saves x")
AssertEqual(addon.db.panel.position.y, -211, "drag saves y")
local savedBounds = Bounds(panel.frame)
panel.frame = NewFrame()
panel:InvalidateLayout()
panel:ApplyLayout()
AssertBounds(panel.frame, savedBounds, "recreated container restores the saved position")
addon.db.panel.locked = true
panel:ApplyLockState()
panel:SavePosition()
AssertBounds(panel.frame, savedBounds, "locking and saving do not move the panel")

print("panel layout regression tests passed")
