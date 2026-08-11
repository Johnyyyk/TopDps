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

    -- Идолы друида. Статические идолы без временного состояния сюда не входят.
    [32257] = { procSpellIds = { 41037 }, durationFallback = 20 }, -- Idol of the White Stag
    [33510] = { procSpellIds = { 43740 }, durationFallback = 10 }, -- Idol of the Unseen Moon
    [42574] = { procSpellIds = { 60693 }, durationFallback = 6 }, -- Savage Gladiator's Idol of Resolve
    [42587] = { procSpellIds = { 60695 }, durationFallback = 6 }, -- Hateful Gladiator's Idol of Resolve
    [42588] = { procSpellIds = { 60696 }, durationFallback = 10 }, -- Deadly Gladiator's Idol of Resolve
    [42589] = { procSpellIds = { 60698 }, durationFallback = 10 }, -- Furious Gladiator's Idol of Resolve
    [42591] = { procSpellIds = { 60700 }, durationFallback = 10 }, -- Relentless Gladiator's Idol of Resolve
    [45509] = { procSpellIds = { 64951 }, durationFallback = 12 }, -- Idol of the Corruptor
    [47668] = {
        procSpellIds = { 67354, 67355 },
        durationFallback = 16,
        internalCooldown = 8,
    }, -- Idol of Mutilation: отдельные Bear/Cat ауры
    [47670] = { procSpellIds = { 67360 }, durationFallback = 12, internalCooldown = 6 }, -- Idol of Lunar Fury
    [47671] = { procSpellIds = { 67358 }, durationFallback = 9, internalCooldown = 5 }, -- Idol of Flaring Growth
    [50454] = { procSpellIds = { 71184 }, durationFallback = 15, showStacks = true }, -- Idol of the Black Willow
    [50456] = { procSpellIds = { 71175 }, durationFallback = 15, showStacks = true }, -- Idol of the Crying Moon
    [50457] = { procSpellIds = { 71177 }, durationFallback = 15, showStacks = true }, -- Idol of the Lunar Eclipse
    [51429] = { procSpellIds = { 60701 }, durationFallback = 10 }, -- Wrathful Gladiator's Idol of Resolve

    -- Тотемы шамана.
    [33506] = { procSpellIds = { 43751 }, durationFallback = 10, internalCooldown = 30 }, -- Skycall Totem
    [33507] = { procSpellIds = { 43749 }, durationFallback = 10, internalCooldown = 10 }, -- Stonebreaker's Totem
    [40708] = { procSpellIds = { 60771 }, durationFallback = 10, internalCooldown = 30 }, -- Totem of the Elemental Plane
    [42594] = { procSpellIds = { 60565 }, durationFallback = 6 }, -- Savage Gladiator's Totem of Survival
    [42601] = { procSpellIds = { 60566 }, durationFallback = 6 }, -- Hateful Gladiator's Totem of Survival
    [42602] = { procSpellIds = { 60567 }, durationFallback = 10 }, -- Deadly Gladiator's Totem of Survival
    [42603] = { procSpellIds = { 60568 }, durationFallback = 10 }, -- Furious Gladiator's Totem of Survival
    [42604] = { procSpellIds = { 60569 }, durationFallback = 10 }, -- Relentless Gladiator's Totem of Survival
    [47665] = { procSpellIds = { 67388 }, durationFallback = 15 }, -- Totem of Calming Tides
    [47666] = { procSpellIds = { 67385 }, durationFallback = 12, internalCooldown = 6 }, -- Totem of Electrifying Wind
    [47667] = { procSpellIds = { 67391 }, durationFallback = 18, internalCooldown = 9 }, -- Totem of Quaking Earth
    [50458] = { procSpellIds = { 71199 }, durationFallback = 30, showStacks = true }, -- Bizuri's Totem of Shattered Ice
    [50463] = { procSpellIds = { 71216 }, durationFallback = 15, showStacks = true }, -- Totem of the Avalanche
    [50464] = { procSpellIds = { 71220 }, durationFallback = 15, showStacks = true }, -- Totem of the Surging Sea
    [51513] = { procSpellIds = { 60570 }, durationFallback = 10 }, -- Wrathful Gladiator's Totem of Survival

    -- Сигилы рыцаря смерти. Постоянные бонусы и Razorice на цели не являются состоянием панели.
    [40714] = { procSpellIds = { 62146 }, durationFallback = 30 }, -- Sigil of the Unfaltering Knight
    [40715] = { procSpellIds = { 60828 }, durationFallback = 10, internalCooldown = 45 }, -- Sigil of Haunted Dreams
    [45144] = { procSpellIds = { 64963 }, durationFallback = 5 }, -- Sigil of Deflection
    [47672] = { procSpellIds = { 67380 }, durationFallback = 20, internalCooldown = 10 }, -- Sigil of Insolence
    [47673] = { procSpellIds = { 67383 }, durationFallback = 20, internalCooldown = 10 }, -- Sigil of Virulence
    [50459] = { procSpellIds = { 71227 }, durationFallback = 15, showStacks = true }, -- Sigil of the Hanged Man
    [50462] = { procSpellIds = { 71229 }, durationFallback = 15, showStacks = true }, -- Sigil of the Bone Gryphon
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
