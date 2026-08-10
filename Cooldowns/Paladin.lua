local addon = TopDps

addon.CooldownRegistry:Register({
    classToken = addon.Paladin.CLASS_TOKEN,
    entries = {
        {
            id = "avengingWrath",
            type = "spell",
            spellIds = { 31884 },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "divineProtection",
            type = "spell",
            spellIds = { 498 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 10,
        },
        {
            id = "divineShield",
            type = "spell",
            spellIds = { 642 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 20,
        },
        {
            id = "handOfProtection",
            type = "spell",
            spellIds = { 1022, 5599, 10278 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 30,
        },
        {
            id = "handOfSacrifice",
            type = "spell",
            spellIds = { 6940 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 40,
        },
        {
            id = "divineSacrifice",
            type = "spell",
            spellIds = { 64205 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 50,
        },
        {
            id = "layOnHands",
            type = "spell",
            spellIds = { 633, 2800, 10310, 27154, 48788 },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 60,
        },
        {
            id = "divineFavor",
            type = "spell",
            spellIds = { 20216 },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 10,
        },
        {
            id = "divineIllumination",
            type = "spell",
            spellIds = { 31842 },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 20,
        },
        {
            id = "auraMastery",
            type = "spell",
            spellIds = { 31821 },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 30,
        },
        {
            id = "divinePlea",
            type = "spell",
            spellIds = { 54428 },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 40,
        },
    },
})
