local addon = TopDps
local EquipmentProcDatabase = addon:CreateModule("EquipmentProcDatabase")

local ITEM_PROCS = {
    [37574] = { procSpellIds = { 48835 }, durationFallback = 5 },
    [40706] = { procSpellIds = { 60819 }, durationFallback = 10 },
    [40707] = { procSpellIds = { 60794 }, durationFallback = 10 },
    [42611] = { procSpellIds = { 60577 }, durationFallback = 6 },
    [42851] = { procSpellIds = { 60632 }, durationFallback = 6 },
    [42852] = { procSpellIds = { 60633 }, durationFallback = 10 },
    [42853] = { procSpellIds = { 60634 }, durationFallback = 10 },
    [42854] = { procSpellIds = { 60635 }, durationFallback = 10 },
    [45145] = { procSpellIds = { 65182 }, durationFallback = 20 },
    [47661] = { procSpellIds = { 67365 }, durationFallback = 15, internalCooldown = 8 },
    [50455] = { procSpellIds = { 71187 }, durationFallback = 15, showStacks = true },
    [51478] = { procSpellIds = { 60636 }, durationFallback = 10 },
}

local ENCHANT_PROCS = {
    [2673] = { procSpellIds = { 28093 }, durationFallback = 15 },
    [3225] = { procSpellIds = { 42976 }, durationFallback = 15 },
    [3722] = { procSpellIds = { 55637 }, durationFallback = 15, internalCooldown = 60 },
    [3728] = { triggerSpellIds = { 55767 }, internalCooldown = 45 },
    [3730] = { procSpellIds = { 55775 }, durationFallback = 15, internalCooldown = 55 },
    [3789] = { procSpellIds = { 59620 }, durationFallback = 15 },
    [3790] = { procSpellIds = { 59626 }, durationFallback = 10, internalCooldown = 35 },
    [3869] = { procSpellIds = { 64440 }, durationFallback = 10, showStacks = true },
    [3870] = { procSpellIds = { 64568 }, durationFallback = 20, showStacks = true },
}

local function CopyProcData(data)
    if not data then
        return nil
    end

    local result = {}
    local key, value
    for key, value in pairs(data) do
        if type(value) == "table" then
            local copy = {}
            local index
            for index = 1, #value do
                copy[index] = value[index]
            end
            result[key] = copy
        else
            result[key] = value
        end
    end

    return result
end

function EquipmentProcDatabase:GetItem(itemId)
    return CopyProcData(ITEM_PROCS[tonumber(itemId)])
end

function EquipmentProcDatabase:GetEnchant(enchantId)
    return CopyProcData(ENCHANT_PROCS[tonumber(enchantId)])
end

function EquipmentProcDatabase:GetEnchantId(slot)
    if not GetInventoryItemLink then
        return nil
    end

    local link = GetInventoryItemLink("player", slot)
    if not link then
        return nil
    end

    local itemString = string.match(link, "|Hitem:([^|]+)|h")
        or string.match(link, "item:([^|]+)")
    if not itemString then
        return nil
    end

    local _, enchantId = string.match(itemString, "^(%-?%d+):(%-?%d+)")
    return tonumber(enchantId)
end
