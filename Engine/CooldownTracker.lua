local addon = TopDps
local CooldownTracker = addon:CreateModule("CooldownTracker")

local GCD_THRESHOLD = 2
local AURA_SCAN_LIMIT = 40
local TRINKET_SLOTS = { 13, 14 }

CooldownTracker.entries = {}
CooldownTracker.availableEntries = {}
CooldownTracker.activeAuras = {}
CooldownTracker.groupAuraEntries = {}
CooldownTracker.groupAuras = {}

local function GetGroupOrder(group)
    return addon.COOLDOWN_GROUP_ORDER[group] or 100
end

local function IsCooldownActive(start, duration)
    if not start or not duration or duration <= GCD_THRESHOLD then
        return false
    end

    return start + duration > GetTime()
end

local function GetKnownSpellNames()
    local names = {}

    if GetNumSpellTabs and GetSpellTabInfo and GetSpellName then
        local tabIndex
        for tabIndex = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tabIndex)
            if offset and count then
                local spellIndex
                for spellIndex = offset + 1, offset + count do
                    local spellName = GetSpellName(spellIndex, BOOKTYPE_SPELL)
                    if spellName then
                        names[spellName] = true
                    end
                end
            end
        end
    end

    return names
end

local function FindKnownSpell(spellIds, knownNames)
    local index
    for index = #spellIds, 1, -1 do
        local spellId = spellIds[index]
        local spellName, _, icon = GetSpellInfo(spellId)
        local known = false

        if IsSpellKnown then
            local ok, result = pcall(IsSpellKnown, spellId)
            known = ok and result == true
        end

        if not known and spellName and knownNames[spellName] then
            known = true
        end

        if known then
            return spellId, spellName, icon
        end
    end

    return nil, nil, nil
end

local function HasTalentSpell(tabIndex, spellIds)
    if not tabIndex or type(spellIds) ~= "table" or #spellIds == 0 then
        return false
    end

    local index
    for index = 1, #spellIds do
        local talentName = GetSpellInfo(spellIds[index])
        if talentName and addon.GameApi:GetTalentRankByName(tabIndex, talentName) > 0 then
            return true
        end
    end

    return false
end

local function GetSpellCooldownSafe(spellId, spellName)
    if not GetSpellCooldown then
        return 0, 0, 0
    end

    if spellId then
        local ok, start, duration, enabled = pcall(GetSpellCooldown, spellId)
        if ok and start ~= nil then
            return start or 0, duration or 0, enabled or 0
        end
    end

    if spellName then
        local ok, start, duration, enabled = pcall(GetSpellCooldown, spellName)
        if ok and start ~= nil then
            return start or 0, duration or 0, enabled or 0
        end
    end

    return 0, 0, 0
end

local function GetDisplaySpellData(definition)
    local displaySpellId = definition.displaySpellId
        or (definition.auraSpellIds and definition.auraSpellIds[1])
        or (definition.spellIds and definition.spellIds[#definition.spellIds])

    if not displaySpellId then
        return nil, nil, nil
    end

    local name, _, icon = GetSpellInfo(displaySpellId)
    return displaySpellId, name, icon
end

local function SortEntries(entries, classToken, talentTab)
    table.sort(entries, function(left, right)
        local leftGroup = GetGroupOrder(left.group)
        local rightGroup = GetGroupOrder(right.group)
        if leftGroup ~= rightGroup then
            return leftGroup < rightGroup
        end

        local leftOrder = addon.Settings:GetCooldownElementOrder(
            left.settingId,
            left.order,
            classToken,
            talentTab
        )
        local rightOrder = addon.Settings:GetCooldownElementOrder(
            right.settingId,
            right.order,
            classToken,
            talentTab
        )
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end

        return left.settingId < right.settingId
    end)
end

local function IsOwnAuraCaster(unitCaster)
    if not unitCaster then
        return false
    end

    if unitCaster == "player" then
        return true
    end

    if UnitIsUnit then
        local ok, sameUnit = pcall(UnitIsUnit, unitCaster, "player")
        return ok and sameUnit == true
    end

    return false
end

local function IsGroupUnit(unit)
    if unit == "player" then
        return true
    end

    if type(unit) ~= "string" then
        return false
    end

    return string.sub(unit, 1, 5) == "party" or string.sub(unit, 1, 4) == "raid"
end

local function GetGroupUnits()
    local units = {}
    local raidCount = GetNumRaidMembers and GetNumRaidMembers() or 0
    local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
    local index

    if raidCount > 0 then
        for index = 1, raidCount do
            units[#units + 1] = "raid" .. tostring(index)
        end
    else
        units[#units + 1] = "player"
        for index = 1, partyCount do
            units[#units + 1] = "party" .. tostring(index)
        end
    end

    return units
end

function CooldownTracker:Initialize()
    self.initialized = true
    self:RefreshConfiguration()
end

function CooldownTracker:GetEntries()
    return self.entries or {}
end

function CooldownTracker:GetConfigurableEntries()
    local classToken = addon.SpecManager and addon.SpecManager.classToken or nil
    local talentTab = addon.SpecManager and addon.SpecManager.talentTab or nil
    return self:GetConfigurableEntriesForProfile(classToken, talentTab)
end

function CooldownTracker:CreateDefinitionEntry(definition, knownNames)
    if definition.requiredTalentSpellIds then
        local talentTab = definition.requiredTalentTab or definition.talentTab
        if not HasTalentSpell(talentTab, definition.requiredTalentSpellIds) then
            return nil
        end
    end

    if definition.requiredSpellIds then
        local requiredSpellId = FindKnownSpell(definition.requiredSpellIds, knownNames)
        if not requiredSpellId then
            return nil
        end
    end

    if definition.type == "spell" then
        local spellId, spellName, icon = FindKnownSpell(definition.spellIds, knownNames)
        if not spellId then
            return nil
        end

        return {
            settingId = definition.settingId,
            type = "spell",
            group = definition.group,
            order = definition.order,
            spellId = spellId,
            displaySpellId = spellId,
            spellName = spellName,
            icon = icon,
            auraSpellIds = definition.auraSpellIds or { spellId },
            blockedByAuraSpellIds = definition.blockedByAuraSpellIds,
            name = spellName or definition.id,
            showStacks = definition.showStacks == true,
            defaultEnabled = definition.defaultEnabled,
        }
    end

    local displaySpellId, displayName, displayIcon = GetDisplaySpellData(definition)

    if definition.type == "aura" then
        return {
            settingId = definition.settingId,
            type = "aura",
            group = definition.group,
            order = definition.order,
            auraSpellIds = definition.auraSpellIds,
            auraUnit = definition.auraUnit or "player",
            auraFilter = definition.auraFilter or "HELPFUL",
            ownOnly = definition.ownOnly == true,
            icon = definition.icon or displayIcon,
            name = definition.name or displayName or definition.id,
            fallbackDuration = definition.fallbackDuration,
            showDuration = definition.showDuration ~= false,
            showStacks = definition.showStacks == true,
            inactiveText = definition.inactiveText,
            activeState = definition.activeState or "ACTIVE",
            inactiveState = definition.inactiveState or "INACTIVE",
            defaultEnabled = definition.defaultEnabled,
            displaySpellId = displaySpellId,
        }
    end

    if definition.type == "counter" then
        return {
            settingId = definition.settingId,
            type = "counter",
            group = definition.group,
            order = definition.order,
            icon = definition.icon or displayIcon,
            name = definition.name or displayName or definition.id,
            getValue = definition.getValue,
            defaultEnabled = definition.defaultEnabled,
            displaySpellId = displaySpellId,
        }
    end

    return nil
end

function CooldownTracker:CreateConfigurableDefinitionEntry(definition)
    local displaySpellId, displayName, displayIcon = GetDisplaySpellData(definition)

    return {
        settingId = definition.settingId,
        type = definition.type,
        group = definition.group,
        order = definition.order,
        spellId = displaySpellId,
        displaySpellId = displaySpellId,
        icon = definition.icon or displayIcon,
        name = definition.name or displayName or definition.id,
        defaultEnabled = definition.defaultEnabled,
    }
end

function CooldownTracker:CreateClassEntries()
    local _, classToken = UnitClass("player")
    if not classToken then
        return {}
    end

    local talentTab = addon.SpecManager and addon.SpecManager.talentTab or nil
    local definitions = addon.CooldownRegistry:GetEntries(classToken, talentTab)
    local knownNames = GetKnownSpellNames()
    local result = {}
    local index

    for index = 1, #definitions do
        local entry = self:CreateDefinitionEntry(definitions[index], knownNames)
        if entry then
            table.insert(result, entry)
        end
    end

    if self.CreateEquipmentProcEntries then
        local equipmentEntries = self:CreateEquipmentProcEntries()
        for index = 1, #equipmentEntries do
            result[#result + 1] = equipmentEntries[index]
        end
    end

    return result
end

function CooldownTracker:CreateTrinketEntry(slot, order)
    local itemId = addon.GameApi:GetInventoryItemId(slot)
    if not itemId then
        return nil
    end

    local procData = addon.TrinketDatabase:Get(itemId)
    local _, _, hasCooldown = GetInventoryItemCooldown("player", slot)
    if not procData and hasCooldown ~= 1 then
        return nil
    end

    local settingId = "TRINKET_SLOT_" .. tostring(slot)
    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    itemTexture = itemTexture or GetInventoryItemTexture("player", slot)

    return {
        settingId = settingId,
        type = "trinket",
        group = addon.COOLDOWN_GROUP_TRINKETS,
        order = order,
        slot = slot,
        itemId = itemId,
        procData = procData,
        icon = itemTexture,
        name = itemName or string.format(addon.L.COOLDOWN_TRINKET_SLOT, slot == 13 and 1 or 2),
        defaultEnabled = true,
    }
end

function CooldownTracker:CreateConfigurableTrinketEntry(slot, order)
    return {
        settingId = "TRINKET_SLOT_" .. tostring(slot),
        type = "trinket",
        group = addon.COOLDOWN_GROUP_TRINKETS,
        order = order,
        slot = slot,
        name = string.format(addon.L.COOLDOWN_TRINKET_SLOT, slot == 13 and 1 or 2),
        defaultEnabled = true,
    }
end

function CooldownTracker:GetConfigurableEntriesForProfile(classToken, talentTab)
    if not classToken or not talentTab then
        return {}
    end

    local definitions = addon.CooldownRegistry:GetEntries(classToken, talentTab)
    local entries = {}
    local index

    for index = 1, #definitions do
        table.insert(entries, self:CreateConfigurableDefinitionEntry(definitions[index]))
    end

    for index = 1, #TRINKET_SLOTS do
        table.insert(entries, self:CreateConfigurableTrinketEntry(TRINKET_SLOTS[index], index * 10))
    end

    if self.CreateConfigurableEquipmentProcEntries then
        local equipmentEntries = self:CreateConfigurableEquipmentProcEntries()
        for index = 1, #equipmentEntries do
            entries[#entries + 1] = equipmentEntries[index]
        end
    end

    SortEntries(entries, classToken, talentTab)
    return entries
end

function CooldownTracker:RefreshConfiguration()
    if not addon.db then
        return
    end

    local classToken = addon.SpecManager and addon.SpecManager.classToken or nil
    local talentTab = addon.SpecManager and addon.SpecManager.talentTab or nil
    local entries = self:CreateClassEntries()
    local index
    for index = 1, #TRINKET_SLOTS do
        local entry = self:CreateTrinketEntry(TRINKET_SLOTS[index], index * 10)
        if entry then
            table.insert(entries, entry)
        end
    end

    SortEntries(entries, classToken, talentTab)
    self.availableEntries = entries

    local visibleEntries = {}
    for index = 1, #entries do
        local entry = entries[index]
        if addon.Settings:IsCooldownElementEnabled(
            entry.settingId,
            entry.defaultEnabled,
            classToken,
            talentTab
        ) then
            table.insert(visibleEntries, entry)
        end
    end

    self.entries = visibleEntries
    self.groupAuraEntries = {}

    for index = 1, #visibleEntries do
        local entry = visibleEntries[index]
        if entry.type == "aura" and entry.auraUnit == "group" then
            table.insert(self.groupAuraEntries, entry)
        end
    end

    self:RefreshGroupAuras()

    if addon.CooldownPanel then
        addon.CooldownPanel:SetEntries(visibleEntries)
    end

    if addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end
end

function CooldownTracker:ReadAura(unit, index, filter)
    local reader = filter == "HARMFUL" and UnitDebuff or UnitBuff
    if not reader then
        return nil
    end

    local name, _, icon, stacks, _, duration, expirationTime, unitCaster, _, _, spellId = reader(unit, index)
    if not name then
        return nil
    end

    return {
        spellId = spellId,
        name = name,
        icon = icon,
        stacks = stacks or 0,
        duration = duration or 0,
        expirationTime = expirationTime or 0,
        unitCaster = unitCaster,
        unit = unit,
    }
end

function CooldownTracker:FindAuraOnUnit(unit, spellIds, filter, ownOnly)
    if not unit or not spellIds or not UnitExists(unit) then
        return nil
    end

    local wanted = {}
    local index
    for index = 1, #spellIds do
        wanted[spellIds[index]] = true
    end

    for index = 1, AURA_SCAN_LIMIT do
        local aura = self:ReadAura(unit, index, filter)
        if not aura then
            break
        end

        if aura.spellId and wanted[aura.spellId]
            and (not ownOnly or IsOwnAuraCaster(aura.unitCaster)) then
            return aura, aura.spellId
        end
    end

    return nil, nil
end

function CooldownTracker:ScanPlayerAuras()
    local activeAuras = {}
    local index

    for index = 1, AURA_SCAN_LIMIT do
        local aura = self:ReadAura("player", index, "HELPFUL")
        if not aura then
            break
        end

        if aura.spellId then
            activeAuras[aura.spellId] = aura
        end
    end

    self.activeAuras = activeAuras
end

function CooldownTracker:FindActiveAura(spellIds)
    if not spellIds then
        return nil
    end

    local index
    for index = 1, #spellIds do
        local aura = self.activeAuras[spellIds[index]]
        if aura then
            return aura, spellIds[index]
        end
    end

    return nil, nil
end

function CooldownTracker:FindGroupAura(entry)
    local units = GetGroupUnits()
    local index

    for index = 1, #units do
        local aura = self:FindAuraOnUnit(
            units[index],
            entry.auraSpellIds,
            entry.auraFilter,
            entry.ownOnly
        )
        if aura then
            return aura
        end
    end

    return nil
end

function CooldownTracker:RefreshGroupAuraEntry(entry)
    self.groupAuras[entry.settingId] = self:FindGroupAura(entry)
end

function CooldownTracker:RefreshGroupAuras()
    self.groupAuras = {}

    local index
    for index = 1, #(self.groupAuraEntries or {}) do
        self:RefreshGroupAuraEntry(self.groupAuraEntries[index])
    end
end

function CooldownTracker:HandleUnitAura(unit)
    if not IsGroupUnit(unit) or #(self.groupAuraEntries or {}) == 0 then
        return
    end

    local index
    for index = 1, #self.groupAuraEntries do
        local entry = self.groupAuraEntries[index]
        local aura = self:FindAuraOnUnit(unit, entry.auraSpellIds, entry.auraFilter, entry.ownOnly)
        if aura then
            self.groupAuras[entry.settingId] = aura
        else
            local current = self.groupAuras[entry.settingId]
            if current and current.unit == unit then
                self:RefreshGroupAuraEntry(entry)
            end
        end
    end
end

function CooldownTracker:HandleGroupChanged()
    self:RefreshGroupAuras()
end

function CooldownTracker:GetActiveState(aura, fallbackDuration, showStacks, showDuration)
    local now = GetTime()
    local duration = tonumber(aura.duration) or 0
    local expirationTime = tonumber(aura.expirationTime) or 0

    if duration <= 0 then
        duration = tonumber(fallbackDuration) or 0
    end

    local start = expirationTime > 0 and expirationTime - duration or now
    local remaining = expirationTime > 0 and math.max(0, expirationTime - now) or duration

    if showDuration == false then
        start = now
        duration = 0
        remaining = 0
    end

    local unitName
    if aura.unit and aura.unit ~= "player" and UnitName then
        unitName = UnitName(aura.unit)
    end

    return {
        state = "ACTIVE",
        start = start,
        duration = duration,
        remaining = remaining,
        stacks = aura.stacks or 0,
        showStacks = showStacks == true,
        icon = aura.icon,
        spellId = aura.spellId,
        unitName = unitName,
    }
end

function CooldownTracker:GetSpellState(entry)
    local aura = self:FindActiveAura(entry.auraSpellIds)
    if aura then
        return self:GetActiveState(aura, nil, entry.showStacks, true)
    end

    local start, duration = GetSpellCooldownSafe(entry.spellId, entry.spellName)
    if IsCooldownActive(start, duration) then
        return {
            state = "COOLDOWN",
            start = start,
            duration = duration,
            remaining = math.max(0, start + duration - GetTime()),
        }
    end

    if entry.blockedByAuraSpellIds then
        local blocker = self:FindAuraOnUnit("player", entry.blockedByAuraSpellIds, "HARMFUL", false)
        if blocker then
            local state = self:GetActiveState(blocker, nil, false, true)
            state.state = "BLOCKED"
            state.spellId = nil
            state.blockerSpellId = blocker.spellId
            return state
        end
    end

    return {
        state = "READY",
        remaining = 0,
    }
end

function CooldownTracker:GetAuraForEntry(entry)
    if entry.auraUnit == "group" then
        return self.groupAuras[entry.settingId]
    end

    if entry.auraUnit == "player" and entry.auraFilter == "HELPFUL" and not entry.ownOnly then
        return self:FindActiveAura(entry.auraSpellIds)
    end

    return self:FindAuraOnUnit(
        entry.auraUnit,
        entry.auraSpellIds,
        entry.auraFilter,
        entry.ownOnly
    )
end

function CooldownTracker:GetAuraState(entry)
    local aura = self:GetAuraForEntry(entry)
    if aura then
        local state = self:GetActiveState(
            aura,
            entry.fallbackDuration,
            entry.showStacks,
            entry.showDuration
        )
        state.state = entry.activeState
        return state
    end

    return {
        state = entry.inactiveState,
        remaining = 0,
        stacks = 0,
        showStacks = entry.showStacks,
        statusText = entry.inactiveText,
    }
end

function CooldownTracker:GetCounterState(entry)
    local ok, value = pcall(entry.getValue)
    if not ok then
        value = 0
    end

    value = tonumber(value) or 0
    if value < 0 then
        value = 0
    end

    return {
        state = value > 0 and "ACTIVE" or "INACTIVE",
        remaining = 0,
        stacks = value,
        showStacks = true,
    }
end

function CooldownTracker:RememberProcCooldown(entry, aura)
    local procData = entry.procData
    if not procData or not procData.internalCooldown or procData.internalCooldown <= 0 then
        return
    end

    local nowEpoch = time()
    local remaining = math.max(0, (aura.expirationTime or 0) - GetTime())
    local duration = aura.duration or procData.durationFallback or 0
    local elapsed = math.max(0, duration - remaining)
    local readyAt = nowEpoch - elapsed + procData.internalCooldown
    local current = addon.db.panel.procReadyAt[entry.itemId]

    if not current or current <= nowEpoch then
        addon.db.panel.procReadyAt[entry.itemId] = readyAt
    end
end

function CooldownTracker:GetRememberedProcState(entry)
    local readyAt = addon.db.panel.procReadyAt[entry.itemId]
    if not readyAt then
        return nil
    end

    local nowEpoch = time()
    local remaining = readyAt - nowEpoch
    if remaining <= 0 then
        addon.db.panel.procReadyAt[entry.itemId] = nil
        return nil
    end

    local internalCooldown = entry.procData and entry.procData.internalCooldown or remaining
    local elapsed = math.max(0, internalCooldown - remaining)

    return {
        state = "COOLDOWN",
        start = GetTime() - elapsed,
        duration = internalCooldown,
        remaining = remaining,
        cooldownId = "PROC:" .. tostring(entry.itemId) .. ":" .. tostring(readyAt),
    }
end

function CooldownTracker:GetTrinketState(entry)
    local procData = entry.procData
    if procData then
        local aura = self:FindActiveAura(procData.procSpellIds)
        if aura then
            self:RememberProcCooldown(entry, aura)
            local state = self:GetActiveState(aura, procData.durationFallback, true, true)
            state.icon = entry.icon
            return state
        end
    end

    local start, duration = GetInventoryItemCooldown("player", entry.slot)
    if IsCooldownActive(start, duration) then
        return {
            state = "COOLDOWN",
            start = start,
            duration = duration,
            remaining = math.max(0, start + duration - GetTime()),
        }
    end

    if procData and procData.internalCooldown and procData.internalCooldown > 0 then
        local remembered = self:GetRememberedProcState(entry)
        if remembered then
            return remembered
        end
    end

    return {
        state = "READY",
        remaining = 0,
    }
end

function CooldownTracker:IsPanelAllowedOutsideCombat()
    return addon.db and addon.db.panel and addon.db.panel.locked == false
end

function CooldownTracker:Update()
    if not addon.CooldownPanel or not addon.db then
        return
    end

    if not addon.Settings:IsPanelEnabled() then
        addon.CooldownPanel:Hide()
        return
    end

    if not addon.Settings:IsModeActive() then
        addon.CooldownPanel:Hide()
        return
    end

    local previewUnlocked = self:IsPanelAllowedOutsideCombat()
    if addon.Settings:IsCooldownPanelCombatOnly() and not UnitAffectingCombat("player") and not previewUnlocked then
        addon.CooldownPanel:Hide()
        return
    end

    if #self.entries == 0 then
        addon.CooldownPanel:Hide()
        return
    end

    self:ScanPlayerAuras()

    local states = {}
    local index
    for index = 1, #self.entries do
        local entry = self.entries[index]
        if entry.type == "spell" then
            states[index] = self:GetSpellState(entry)
        elseif entry.type == "aura" then
            states[index] = self:GetAuraState(entry)
        elseif entry.type == "counter" then
            states[index] = self:GetCounterState(entry)
        elseif entry.type == "trinket" then
            states[index] = self:GetTrinketState(entry)
        elseif entry.type == "equipmentProc" and self.GetEquipmentProcState then
            states[index] = self:GetEquipmentProcState(entry)
        end
    end

    addon.CooldownPanel:Update(states)
end
