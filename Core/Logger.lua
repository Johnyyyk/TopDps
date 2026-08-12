local addon = TopDps
local Logger = addon:CreateModule("Logger")
local unpack = unpack

local function GetTimestamp()
    if date then
        return date("%H:%M:%S")
    end

    return string.format("%.1f", GetTime())
end

local function FormatMessage(formatText, ...)
    if select("#", ...) == 0 then
        return tostring(formatText)
    end

    local ok, result = pcall(string.format, tostring(formatText), ...)
    if ok then
        return result
    end

    return tostring(formatText)
end

function Logger:Add(level, formatText, force, ...)
    if not addon.db then
        return
    end

    if not force and not addon.db.debug.logging then
        return
    end

    if type(addon.db.debug.log) ~= "table" then
        addon.db.debug.log = {}
    end

    local message = FormatMessage(formatText, ...)
    local line = string.format("%s [%s] %s", GetTimestamp(), tostring(level), message)
    table.insert(addon.db.debug.log, line)

    while #addon.db.debug.log > addon.DEBUG_LOG_LIMIT do
        table.remove(addon.db.debug.log, 1)
    end

    self.dirty = true
    if addon.DebugOptions then
        addon.DebugOptions:RefreshLog()
    end
end

function Logger:Info(formatText, ...)
    self:Add("INFO", formatText, false, ...)
end

function Logger:Warning(formatText, ...)
    self:Add("WARN", formatText, false, ...)
end

function Logger:Error(formatText, ...)
    self:Add("ERROR", formatText, false, ...)
end

function Logger:SafeCall(context, func, ...)
    local arguments = { ... }

    local function CallFunction()
        return func(unpack(arguments))
    end

    local function ErrorHandler(errorText)
        local message = tostring(errorText)
        if debugstack then
            message = message .. "\n" .. debugstack(2, 12, 12)
        end

        self:Error("%s: %s", tostring(context), message)
        return message
    end

    local ok, result = xpcall(CallFunction, ErrorHandler)
    if not ok and geterrorhandler then
        local handler = geterrorhandler()
        if handler then
            handler(result)
        end
    end

    return ok, result
end

function Logger:GetText()
    if not addon.db or type(addon.db.debug.log) ~= "table" then
        return ""
    end

    return table.concat(addon.db.debug.log, "\n")
end

function Logger:Clear()
    if not addon.db then
        return
    end

    addon.db.debug.log = {}
    self.dirty = true
    self:Add("INFO", addon.L.DEBUG_LOG_CLEARED, true)

    if addon.DebugOptions then
        addon.DebugOptions:RefreshLog(true)
    end
end

function Logger:SetRotationState(state)
    if self.lastRotationState == state then
        return
    end

    self.lastRotationState = state
    self:Info("Rotation state: %s", tostring(state))
end

function Logger:WriteDiagnosticSnapshot()
    if not addon.db or not addon.db.debug.logging then
        return
    end

    local _, class = UnitClass("player")
    local provider = addon.SpecManager and addon.SpecManager:GetActive() or nil
    local providerId = provider and provider.id or "none"
    local buttonCount = addon.ActionBarService and #addon.ActionBarService.buttons or 0

    self:Info(
        "Snapshot: version=%s, locale=%s, class=%s, level=%s, rotation=%s, panel=%s, mode=%s, glow=%s, center=%s, provider=%s, buttons=%s",
        addon.VERSION,
        tostring(GetLocale()),
        tostring(class),
        tostring(UnitLevel("player")),
        tostring(addon.Settings:IsRotationEnabled()),
        tostring(addon.Settings:IsPanelEnabled()),
        tostring(addon.db.mode),
        tostring(addon.db.rotation.highlightStyle),
        tostring(addon.db.rotation.centerIcons.enabled),
        tostring(providerId),
        tostring(buttonCount)
    )

    if provider then
        local providerState = provider:GetDebugState()
        if providerState then
            self:Info("Provider state: %s", tostring(providerState))
        end
    end

    if provider and addon.ActionBarService then
        local actions = addon.ActionBarService:CollectVisibleActions(provider)
        self:Info("Visible actions: %s", addon.ActionBarService:BuildActionSummary(provider, actions))
    end
end
