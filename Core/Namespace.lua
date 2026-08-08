RpalTopDps = RpalTopDps or {}

local addon = RpalTopDps

addon.NAME = "RpalTopDps"
addon.VERSION = "2.0.1"

-- Set to false to completely hide the debug page from Interface Options.
addon.SHOW_DEBUG_OPTIONS = true

addon.Modules = addon.Modules or {}

function addon:CreateModule(name)
    local module = self.Modules[name]
    if module then
        return module
    end

    module = {}
    self.Modules[name] = module
    self[name] = module

    return module
end
