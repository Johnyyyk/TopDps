local addon = TopDps
local CooldownTracker = addon.CooldownTracker

local GCD_THRESHOLD = 2

local EQUIPMENT_SOURCES = {
    {
        settingId = "EQUIPMENT_HEAD_ENCHANT",
        slot = 1,
        sourceType = "enchant",
        order = 5,
        labelKey = "COOLDOWN_EQUIPMENT_HEAD_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_CLOAK_ENCHANT",
        slot = 15,
        sourceType = "enchant",
        order = 10,
        labelKey = "COOLDOWN_EQUIPMENT_CLOAK_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_HANDS_ENCHANT",
        slot = 10,
        sourceType = "enchant",
        order = 20,
        labelKey = "COOLDOWN_EQUIPMENT_HANDS_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_WAIST_ENCHANT",
        slot = 6,
        sourceType = "enchant",
        order = 30,
        labelKey = "COOLDOWN_EQUIPMENT_WAIST_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_FEET_ENCHANT",
        slot = 8,
        sourceType = "enchant",
        order = 40,
        labelKey = "COOLDOWN_EQUIPMENT_FEET_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_MAINHAND_ENCHANT",
        slot = 16,
        sourceType = "enchant",
        order = 50,
        labelKey = "COOLDOWN_EQUIPMENT_MAINHAND_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_OFFHAND_ENCHANT",
        slot = 17,
        sourceType = "enchant",
        order = 60,
        labelKey = "COOLDOWN_EQUIPMENT_OFFHAND_ENCHANT",
    },
    {
        settingId = "EQUIPMENT_RELIC",
        slot = 18,
        sourceType = "item",
        order = 70,
        labelKey = "COOLDOWN_EQUIPMENT_RELIC",
    },
}

local function GetSourceName(source)
    return addon.L[source.labelKey] or source.settingId
end

local function GetItemData(slot)
    local itemId = addon.GameApi:GetInventoryItemId(slot)
    if not itemId then
        return nil, nil, nil
    end

    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    itemTexture = itemTexture or GetInventoryItemTexture("player", slot)

    return itemId, itemName, itemTexture
end

local function GetInventoryCooldownState(entry)
    if not entry.procData or entry.procData.inventoryCooldown ~= true or not GetInventoryItemCooldown then
        return nil
    end

    local start, duration = GetInventoryItemCooldown("player", entry.slot)
    start = tonumber(start) or 0
    duration = tonumber(duration) or 0

    if duration <= GCD_THRESHOLD or start + duration <= GetTime() then
        return nil
    end

    return {
        state = "COOLDOWN",
        start = start,
        duration = duration,
        remaining = math.max(0, start + duration - GetTime()),
        cooldownId = "EQUIPMENT_USE:" .. tostring(entry.procKey) .. ":" .. tostring(start),
    }
end

function CooldownTracker:CreateEquipmentProcEntry(source)
    if not addon.EquipmentProcDatabase then
        return nil
    end

    local itemId, itemName, itemTexture = GetItemData(source.slot)
    if not itemId then
        return nil
    end

    local procData
    local sourceId
    if source.sourceType == "item" then
        sourceId = itemId
        procData = addon.EquipmentProcDatabase:GetItem(itemId)
    else
        sourceId = addon.EquipmentProcDatabase:GetEnchantId(source.slot)
        procData = addon.EquipmentProcDatabase:GetEnchant(sourceId)
    end

    if not procData or not sourceId then
        return nil
    end

    return {
        settingId = source.settingId,
        type = "equipmentProc",
        group = addon.COOLDOWN_GROUP_ITEMS,
        order = source.order,
        slot = source.slot,
        itemId = itemId,
        sourceId = sourceId,
        procKey = source.settingId .. ":" .. tostring(sourceId),
        procData = procData,
        icon = itemTexture,
        name = itemName or GetSourceName(source),
        defaultEnabled = true,
    }
end

function CooldownTracker:CreateConfigurableEquipmentProcEntry(source)
    return {
        settingId = source.settingId,
        type = "equipmentProc",
        group = addon.COOLDOWN_GROUP_ITEMS,
        order = source.order,
        slot = source.slot,
        name = GetSourceName(source),
        defaultEnabled = true,
    }
end

function CooldownTracker:CreateEquipmentProcEntries()
    local entries = {}
    local index

    for index = 1, #EQUIPMENT_SOURCES do
        local entry = self:CreateEquipmentProcEntry(EQUIPMENT_SOURCES[index])
        if entry then
            entries[#entries + 1] = entry
        end
    end

    return entries
end

function CooldownTracker:CreateConfigurableEquipmentProcEntries()
    local entries = {}
    local index

    for index = 1, #EQUIPMENT_SOURCES do
        entries[#entries + 1] = self:CreateConfigurableEquipmentProcEntry(EQUIPMENT_SOURCES[index])
    end

    return entries
end

function CooldownTracker:RememberEquipmentProcCooldown(entry, aura)
    local procData = entry.procData
    if not procData or not procData.internalCooldown or procData.internalCooldown <= 0 then
        return
    end

    local nowEpoch = time()
    local remaining = math.max(0, (aura.expirationTime or 0) - GetTime())
    local duration = aura.duration or procData.durationFallback or 0
    local elapsed = math.max(0, duration - remaining)
    local readyAt = nowEpoch - elapsed + procData.internalCooldown
    local current = addon.db.panel.procReadyAt[entry.procKey]

    if not current or current <= nowEpoch then
        addon.db.panel.procReadyAt[entry.procKey] = readyAt
    end
end

function CooldownTracker:GetRememberedEquipmentProcState(entry)
    local readyAt = addon.db.panel.procReadyAt[entry.procKey]
    if not readyAt then
        return nil
    end

    local nowEpoch = time()
    local remaining = readyAt - nowEpoch
    if remaining <= 0 then
        addon.db.panel.procReadyAt[entry.procKey] = nil
        return nil
    end

    local internalCooldown = entry.procData and entry.procData.internalCooldown or remaining
    local elapsed = math.max(0, internalCooldown - remaining)

    return {
        state = "COOLDOWN",
        start = GetTime() - elapsed,
        duration = internalCooldown,
        remaining = remaining,
        cooldownId = "EQUIPMENT:" .. tostring(entry.procKey) .. ":" .. tostring(readyAt),
    }
end

function CooldownTracker:GetEquipmentProcState(entry)
    local procData = entry.procData
    local aura = procData and self:FindActiveAura(procData.procSpellIds) or nil
    if aura then
        self:RememberEquipmentProcCooldown(entry, aura)
        local state = self:GetActiveState(
            aura,
            procData.durationFallback,
            procData.showStacks == true,
            true
        )
        state.icon = entry.icon
        return state
    end

    local inventoryCooldown = GetInventoryCooldownState(entry)
    if inventoryCooldown then
        return inventoryCooldown
    end

    local remembered = self:GetRememberedEquipmentProcState(entry)
    if remembered then
        return remembered
    end

    return {
        state = "READY",
        remaining = 0,
    }
end

function CooldownTracker:HandleEquipmentProcCombatLog(...)
    local _, eventType, sourceGuid, _, _, _, _, _, spellId = ...
    if not eventType or not string.find(eventType, "^SPELL_") then
        return
    end

    if sourceGuid ~= UnitGUID("player") then
        return
    end

    spellId = tonumber(spellId)
    if not spellId then
        return
    end

    local index
    for index = 1, #(self.entries or {}) do
        local entry = self.entries[index]
        local procData = entry.type == "equipmentProc" and entry.procData or nil
        local triggerSpellIds = procData and procData.triggerSpellIds or nil
        if triggerSpellIds then
            local triggerIndex
            for triggerIndex = 1, #triggerSpellIds do
                if triggerSpellIds[triggerIndex] == spellId then
                    local internalCooldown = tonumber(procData.internalCooldown) or 0
                    if internalCooldown > 0 then
                        addon.db.panel.procReadyAt[entry.procKey] = time() + internalCooldown
                    end
                    break
                end
            end
        end
    end
end

local equipmentEventFrame = CreateFrame("Frame")
equipmentEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
equipmentEventFrame:SetScript("OnEvent", function(_, _, ...)
    CooldownTracker:HandleEquipmentProcCombatLog(...)
end)
