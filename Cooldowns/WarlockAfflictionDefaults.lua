local addon = TopDps
local Warlock = addon.Warlock

local profile = addon.CooldownRegistry:GetProfile(Warlock.CLASS_TOKEN, Warlock.TALENT_TABS.AFFLICTION)
if profile then
    profile.defaultElementEnabled = {
        __allowlist = true,
        felArmor = true,
        glyphLifeTap = true,
        correctPet = true,
        weaponStone = true,
        shadowTrance = true,
    }
end
