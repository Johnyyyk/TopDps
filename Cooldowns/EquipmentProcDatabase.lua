local addon = TopDps
local EquipmentProcDatabase = addon:CreateModule("EquipmentProcDatabase")

local ITEM_PROCS = {
    -- Паладинские реликвии / манускрипты.
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
    -- Старые оружейные чары, которые остаются применимыми в WotLK.
    [1900] = { procSpellIds = { 20007 }, durationFallback = 15 }, -- Crusader
    [2673] = { procSpellIds = { 28093 }, durationFallback = 15 }, -- Mongoose
    [3225] = { procSpellIds = { 42976 }, durationFallback = 15 }, -- Executioner

    -- Руны рыцаря смерти с отслеживаемым состоянием на персонаже.
    [3368] = { procSpellIds = { 53365 }, durationFallback = 15 }, -- Fallen Crusader
    [3369] = { procSpellIds = { 53386 }, durationFallback = 30, showStacks = true }, -- Cinderglacier

    -- Инженерные активные улучшения экипировки. Их реальный КД читается с предмета.
    [3599] = { inventoryCooldown = true }, -- Personal Electromagnetic Pulse Generator
    [3601] = { inventoryCooldown = true }, -- Frag Belt
    [3603] = { inventoryCooldown = true }, -- Hand-Mounted Pyro Rocket
    [3604] = {
        procSpellIds = { 54758 },
        durationFallback = 12,
        inventoryCooldown = true,
    }, -- Hyperspeed Accelerators
    [3605] = { inventoryCooldown = true }, -- Flexweave Underlay
    [3606] = { inventoryCooldown = true }, -- Nitro Boosts
    [3859] = { inventoryCooldown = true }, -- Springy Arachnoweave
    [3878] = { inventoryCooldown = true }, -- Mind Amplification Dish

    -- Портняжные чары плаща.
    [3722] = { procSpellIds = { 55637 }, durationFallback = 15, internalCooldown = 60 },
    [3728] = { triggerSpellIds = { 55767 }, internalCooldown = 45 },
    [3730] = { procSpellIds = { 55775 }, durationFallback = 15, internalCooldown = 55 },

    -- Актуальные оружейные чары WotLK.
    [3789] = { procSpellIds = { 59620 }, durationFallback = 15 }, -- Berserking
    [3790] = { procSpellIds = { 59626 }, durationFallback = 10, internalCooldown = 35 }, -- Black Magic
    [3869] = { procSpellIds = { 64440 }, durationFallback = 10, showStacks = true }, -- Blade Ward
    [3870] = { procSpellIds = { 64568 }, durationFallback = 20, showStacks = true }, -- Blood Draining
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
