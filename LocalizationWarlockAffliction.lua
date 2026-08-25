local addon = TopDps
local L = addon.L

if GetLocale() == "ruRU" then
    L.SPEC_WARLOCK_AFFLICTION = "Чернокнижник — Колдовство"

    L.ABILITY_UNSTABLEAFFLICTION = "Нестабильное колдовство"
    L.ABILITY_HAUNT = "Блуждающий дух"
    L.ABILITY_DRAINSOUL = "Похищение души"
    L.ABILITY_SEEDOFCORRUPTION = "Семя порчи"

    L.WARLOCK_FELHUNTER_STATE = "Охотник Скверны"
    L.WARLOCK_AFFLICTION_USE_TARGET_TIME_TO_DIE = "Учитывать время жизни цели для DoT и execute-решений"
else
    L.SPEC_WARLOCK_AFFLICTION = "Warlock — Affliction"

    L.ABILITY_UNSTABLEAFFLICTION = "Unstable Affliction"
    L.ABILITY_HAUNT = "Haunt"
    L.ABILITY_DRAINSOUL = "Drain Soul"
    L.ABILITY_SEEDOFCORRUPTION = "Seed of Corruption"

    L.WARLOCK_FELHUNTER_STATE = "Felhunter"
    L.WARLOCK_AFFLICTION_USE_TARGET_TIME_TO_DIE = "Use target time-to-die for DoT and execute decisions"
end
